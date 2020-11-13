pragma solidity ^0.6.0;

import "../../auth/ProxyPermission.sol";
import "../../interfaces/IAaveSubscription.sol";

/// @title SubscriptionsProxy handles authorization and interaction with the Subscriptions contract
contract AaveSubscriptionsProxy is ProxyPermission {

    address public constant AAVE_SUBSCRIPTION_ADDRESS = 0xe08ff7A2BADb634F0b581E675E6B3e583De086FC;
    address public constant AAVE_MONITOR_PROXY = 0xfA560Dba3a8D0B197cA9505A2B98120DD89209AC;

    /// @notice Calls subscription contract and creates a DSGuard if non existent
    /// @param _minRatio Minimum ratio below which repay is triggered
    /// @param _maxRatio Maximum ratio after which boost is triggered
    /// @param _optimalRatioBoost Ratio amount which boost should target
    /// @param _optimalRatioRepay Ratio amount which repay should target
    /// @param _boostEnabled Boolean determing if boost is enabled
    function subscribe(
        uint128 _minRatio,
        uint128 _maxRatio,
        uint128 _optimalRatioBoost,
        uint128 _optimalRatioRepay,
        bool _boostEnabled
    ) public {
        givePermission(AAVE_MONITOR_PROXY);
        IAaveSubscription(AAVE_SUBSCRIPTION_ADDRESS).subscribe(
            _minRatio, _maxRatio, _optimalRatioBoost, _optimalRatioRepay, _boostEnabled);
    }

    /// @notice Calls subscription contract and updated existing parameters
    /// @dev If subscription is non existent this will create one
    /// @param _minRatio Minimum ratio below which repay is triggered
    /// @param _maxRatio Maximum ratio after which boost is triggered
    /// @param _optimalRatioBoost Ratio amount which boost should target
    /// @param _optimalRatioRepay Ratio amount which repay should target
    /// @param _boostEnabled Boolean determing if boost is enabled
    function update(
        uint128 _minRatio,
        uint128 _maxRatio,
        uint128 _optimalRatioBoost,
        uint128 _optimalRatioRepay,
        bool _boostEnabled
    ) public {
        IAaveSubscription(AAVE_SUBSCRIPTION_ADDRESS).subscribe(_minRatio, _maxRatio, _optimalRatioBoost, _optimalRatioRepay, _boostEnabled);
    }

    /// @notice Calls the subscription contract to unsubscribe the caller
    function unsubscribe() public {
        removePermission(AAVE_MONITOR_PROXY);
        IAaveSubscription(AAVE_SUBSCRIPTION_ADDRESS).unsubscribe();
    }
}
