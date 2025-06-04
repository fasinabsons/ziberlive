using UnityEngine;

public class AdTester : MonoBehaviour
{
    void Start()
    {
        // Ensure AdsService is in the scene
        if (AdsService.Instance == null)
        {
            Debug.LogError("AdTester: AdsService instance not found. Make sure AdsService is in the scene and initialized before AdTester.");
            return;
        }

        // Subscribe to AdsService events
        AdsService.Instance.OnRewardedAdLoaded += HandleRewardedAdLoaded;
        AdsService.Instance.OnRewardedAdFailedToLoad += HandleRewardedAdFailedToLoad;
        AdsService.Instance.OnRewardedAdSkipped += HandleRewardedAdSkipped;
        AdsService.Instance.OnUserEarnedReward += HandleUserEarnedReward;

        Debug.Log("AdTester: Subscribed to AdsService events.");
    }

    void Update()
    {
        // Example: Request ad on key press (for testing in Unity Editor)
        if (Input.GetKeyDown(KeyCode.S))
        {
            Debug.Log("AdTester: 'S' key pressed. Requesting Rewarded Ad via AdsService.");
            AdsService.Instance.ShowRewardedAd();
        }
        if (Input.GetKeyDown(KeyCode.C))
        {
            Debug.Log($"AdTester: 'C' key pressed. Checking ad readiness: {AdsService.Instance.IsAnyRewardedAdReady()}");
        }
    }

    private void HandleRewardedAdLoaded()
    {
        Debug.Log("AdTester (Event): Rewarded Ad Loaded and ready to show!");
    }

    private void HandleRewardedAdFailedToLoad(string adNetwork)
    {
        Debug.LogWarning($"AdTester (Event): Rewarded Ad from {adNetwork} failed to load.");
    }

    private void HandleRewardedAdSkipped(string adNetwork)
    {
        Debug.LogWarning($"AdTester (Event): Rewarded Ad from {adNetwork} was skipped or closed before completion.");
    }

    private void HandleUserEarnedReward(string adNetwork, int amount)
    {
        Debug.Log($"AdTester (Event): User earned reward! Ad Network: {adNetwork}, Amount: {amount}");
        // Here, you would typically grant the player the reward.
        // For example: PlayerData.Instance.AddCurrency(amount);
    }

    void OnDestroy()
    {
        // Unsubscribe from events to prevent memory leaks
        if (AdsService.Instance != null)
        {
            AdsService.Instance.OnRewardedAdLoaded -= HandleRewardedAdLoaded;
            AdsService.Instance.OnRewardedAdFailedToLoad -= HandleRewardedAdFailedToLoad;
            AdsService.Instance.OnRewardedAdSkipped -= HandleRewardedAdSkipped;
            AdsService.Instance.OnUserEarnedReward -= HandleUserEarnedReward;
            Debug.Log("AdTester: Unsubscribed from AdsService events.");
        }
    }
}
