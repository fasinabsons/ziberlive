import 'package:list_rooster/models/user_model.dart';
import 'package:list_rooster/models/bill_model.dart';
import 'package:list_rooster/models/app_models.dart'; // For Apartment, Room, Bed
import 'package:list_rooster/models/bed_type_model.dart';

class RentPortionDetails {
  final double totalAmountDue;
  final double baseRentPortion; // userEffectiveBedCost
  final double vacancyShortfallShare;
  final double incomePoolOffsetApplied;
  final double finalAmountAfterOffsets;

  RentPortionDetails({
    required this.totalAmountDue,
    required this.baseRentPortion,
    required this.vacancyShortfallShare,
    this.incomePoolOffsetApplied = 0.0,
    double? finalAmountAfterOffsets, // Allow it to be calculated if not provided
  }) : this.finalAmountAfterOffsets = finalAmountAfterOffsets ?? totalAmountDue - incomePoolOffsetApplied;

  @override
  String toString() {
    return 'RentPortionDetails(totalAmountDue: $totalAmountDue, baseRentPortion: $baseRentPortion, vacancyShortfallShare: $vacancyShortfallShare, incomePoolOffsetApplied: $incomePoolOffsetApplied, finalAmountAfterOffsets: $finalAmountAfterOffsets)';
  }
}

class BillCalculationService {
  RentPortionDetails calculateRentPortion({ // Changed return type
    required AppUser user,
    required Bill rentBill,
    required Apartment apartment,
    required List<BedType> bedTypes,
    required List<AppUser> allApartmentUsers,
  }) {
    // 1. Find user's Bed and associated BedType
    if (user.assignedBedId == null) {
      return 0.0; // User not assigned to a bed, pays no rent portion.
    }

    Bed? userBedInApartment;
    // Room? userRoomInApartment; // Not strictly needed for this logic if we have userBed

    for (var room in apartment.rooms) {
      for (var bed in room.beds) {
        if (bed.id == user.assignedBedId) {
          userBedInApartment = bed;
          // userRoomInApartment = room;
          break;
        }
      }
      if (userBedInApartment != null) break;
    }

    if (userBedInApartment == null) {
      // This implies user.assignedBedId points to a bed not in the provided apartment.
      // Or data inconsistency.
      print("Error: User ${user.id} assigned bed ${user.assignedBedId} not found in apartment ${apartment.id}");
      return 0.0;
    }

    BedType? userBedTypeDetails;
    try {
      userBedTypeDetails = bedTypes.firstWhere((bt) => bt.typeName == userBedInApartment!.bedTypeName);
    } catch (e) {
      print("Error: BedType ${userBedInApartment.bedTypeName} for user ${user.id}'s bed not found.");
      return 0.0; // BedType not found, cannot calculate rent.
    }

    // 2. Calculate user's effective bed cost (base + premium)
    double baseRent = userBedTypeDetails.price;
    double premium = 0.0;

    if (userBedTypeDetails.premiumFixedAmount != null && userBedTypeDetails.premiumFixedAmount! > 0) {
      premium = userBedTypeDetails.premiumFixedAmount!;
    } else if (userBedTypeDetails.premiumPercentage != null && userBedTypeDetails.premiumPercentage! > 0) {
      premium = baseRent * userBedTypeDetails.premiumPercentage!;
    }
    double userEffectiveBedCost = baseRent + premium;

    // 3. Calculate total expected revenue from all *occupied* beds in this apartment
    double totalExpectedRevenueFromOccupiedBeds = 0.0;
    List<AppUser> payingUsersInApartment = allApartmentUsers.where((u) => u.assignedBedId != null).toList();

    for (AppUser occupant in payingUsersInApartment) {
      Bed? occupiedBed;
      for (var room in apartment.rooms) {
        for (var bed in room.beds) {
          if (bed.id == occupant.assignedBedId) {
            occupiedBed = bed;
            break;
          }
        }
        if (occupiedBed != null) break;
      }

      if (occupiedBed != null) {
        try {
          BedType occupiedBedType = bedTypes.firstWhere((bt) => bt.typeName == occupiedBed.bedTypeName);
          double occupiedBaseRent = occupiedBedType.price;
          double occupiedPremium = 0.0;
          if (occupiedBedType.premiumFixedAmount != null && occupiedBedType.premiumFixedAmount! > 0) {
            occupiedPremium = occupiedBedType.premiumFixedAmount!;
          } else if (occupiedBedType.premiumPercentage != null && occupiedBedType.premiumPercentage! > 0) {
            occupiedPremium = occupiedBaseRent * occupiedBedType.premiumPercentage!;
          }
          totalExpectedRevenueFromOccupiedBeds += (occupiedBaseRent + occupiedPremium);
        } catch (e) {
          // BedType for an occupied bed not found, log error or handle
          print("Warning: BedType for occupied bed ${occupiedBed.bedTypeName} not found. Rent calculations may be inaccurate.");
        }
      }
    }

    // 4. Calculate shortfall or surplus against the total rent bill amount
    // rentBill.amount is the total actual rent to be collected for the apartment.
    double shortfallOrSurplus = rentBill.amount - totalExpectedRevenueFromOccupiedBeds;

    // 5. Distribute shortfall or surplus among paying users
    double shareOfShortfallOrSurplus = 0.0;
    if (payingUsersInApartment.isNotEmpty) {
      shareOfShortfallOrSurplus = shortfallOrSurplus / payingUsersInApartment.length;
    } else if (shortfallOrSurplus != 0) {
        // No paying users, but there's a shortfall/surplus. This is an edge case.
        // If rentBill.amount > 0, this means rent is due but no one is there to pay it.
        // If rentBill.amount == 0, and totalExpectedRevenueFromOccupiedBeds was also 0, then it's fine.
        // For now, if no paying users, they pay nothing of the shortfall/surplus.
        print("Warning: Rent shortfall/surplus of $shortfallOrSurplus exists but no paying users in apartment ${apartment.id}.");
    }

    // 6. User's final rent portion
    // User only pays their effective bed cost + their share of any shortfall/surplus
    // If the user is not in payingUsersInApartment (e.g. assignedBedId is null, though checked earlier), this logic is flawed.
    // However, the initial check for user.assignedBedId ensures 'user' is supposed to be a paying user.
    double userFinalRentPortion = userEffectiveBedCost + shareOfShortfallOrSurplus;

    // Sanity check: rent portion cannot be negative.
    if (userFinalRentPortion < 0) {
        userFinalRentPortion = 0;
    }
    // Ensure shareOfShortfallOrSurplus isn't negative for this breakdown,
    // as the "shortfall" implies a cost to be added.
    // If there was a surplus that reduced the bill, userEffectiveBedCost might be > userFinalRentPortion
    // but vacancyShortfallShare should represent the *cost added* or 0.
    // The current logic: shortfallOrSurplus = rentBill.amount - totalExpectedRevenueFromOccupiedBeds
    // shareOfShortfallOrSurplus = shortfallOrSurplus / payingUsersInApartment.length
    // userFinalRentPortion = userEffectiveBedCost + shareOfShortfallOrSurplus;
    // So, if shareOfShortfallOrSurplus is negative (surplus), then vacancyShortfallShare should be 0,
    // and the reduction is baked into totalAmountDue.
    // If shareOfShortfallOrSurplus is positive (shortfall), then it's the vacancyShare.

    double calculatedVacancyShare = (shareOfShortfallOrSurplus > 0) ? shareOfShortfallOrSurplus : 0.0;
    // If there was a surplus making userFinalRentPortion < userEffectiveBedCost,
    // the 'baseRentPortion' should perhaps reflect the effective bed cost *after* surplus distribution
    // if we want totalAmountDue = baseRentPortion + vacancyShortfallShare.
    // For now: baseRentPortion = userEffectiveBedCost, vacancyShortfallShare = positive share of actual shortfall.
    // totalAmountDue is the final, potentially reduced amount.

    return RentPortionDetails(
      totalAmountDue: userFinalRentPortion,
      baseRentPortion: userEffectiveBedCost,
      vacancyShortfallShare: calculatedVacancyShare,
      // incomePoolOffsetApplied and finalAmountAfterOffsets will be handled later
    );
  }

  double calculateOtherBillPortion({
    required Bill otherBill,
    required List<AppUser> billUsers,
  }) {
    final double totalAmount = otherBill.amount;
    final int numberOfUsers = billUsers.length;

    if (numberOfUsers == 0) {
      return 0.0; // Or handle as an error/special case, e.g., return totalAmount if it implies one user pays all.
                  // For now, returning 0.0 if no users are assigned to the bill.
    }

    return totalAmount / numberOfUsers;
  }
}
