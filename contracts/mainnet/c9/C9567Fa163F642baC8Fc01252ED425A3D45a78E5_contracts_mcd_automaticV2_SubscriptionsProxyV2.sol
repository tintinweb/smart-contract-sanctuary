pragma solidity ^0.6.0;

import "../../DS/DSGuard.sol";
import "../../DS/DSAuth.sol";

contract SubscriptionsInterfaceV2 {
    function subscribe(uint _cdpId, uint128 _minRatio, uint128 _maxRatio, uint128 _optimalBoost, uint128 _optimalRepay, bool _boostEnabled, bool _nextPriceEnabled) external {}
    function unsubscribe(uint _cdpId) external {}
}

/// @title SubscriptionsProxy handles authorization and interaction with the Subscriptions contract
contract SubscriptionsProxyV2 {

    address public constant MONITOR_PROXY_ADDRESS = 0x7456f4218874eAe1aF8B83a64848A1B89fEB7d7C;
    address public constant OLD_SUBSCRIPTION = 0x83152CAA0d344a2Fd428769529e2d490A88f4393;
    address public constant FACTORY_ADDRESS = 0x5a15566417e6C1c9546523066500bDDBc53F88C7;

    function migrate(uint _cdpId, uint128 _minRatio, uint128 _maxRatio, uint128 _optimalRatioBoost, uint128 _optimalRatioRepay, bool _boostEnabled, bool _nextPriceEnabled, address _subscriptions) public {
        SubscriptionsInterfaceV2(OLD_SUBSCRIPTION).unsubscribe(_cdpId);

        subscribe(_cdpId, _minRatio, _maxRatio, _optimalRatioBoost, _optimalRatioRepay, _boostEnabled, _nextPriceEnabled, _subscriptions);
    }

    function subscribe(uint _cdpId, uint128 _minRatio, uint128 _maxRatio, uint128 _optimalRatioBoost, uint128 _optimalRatioRepay, bool _boostEnabled, bool _nextPriceEnabled, address _subscriptions) public {

        address currAuthority = address(DSAuth(address(this)).authority());
        DSGuard guard = DSGuard(currAuthority);

        if (currAuthority == address(0)) {
            guard = DSGuardFactory(FACTORY_ADDRESS).newGuard();
            DSAuth(address(this)).setAuthority(DSAuthority(address(guard)));
        }

        guard.permit(MONITOR_PROXY_ADDRESS, address(this), bytes4(keccak256("execute(address,bytes)")));

        SubscriptionsInterfaceV2(_subscriptions).subscribe(_cdpId, _minRatio, _maxRatio, _optimalRatioBoost, _optimalRatioRepay, _boostEnabled, _nextPriceEnabled);
    }

    function update(uint _cdpId, uint128 _minRatio, uint128 _maxRatio, uint128 _optimalRatioBoost, uint128 _optimalRatioRepay, bool _boostEnabled, bool _nextPriceEnabled, address _subscriptions) public {
        SubscriptionsInterfaceV2(_subscriptions).subscribe(_cdpId, _minRatio, _maxRatio, _optimalRatioBoost, _optimalRatioRepay, _boostEnabled, _nextPriceEnabled);
    }

    function unsubscribe(uint _cdpId, address _subscriptions) public {
        SubscriptionsInterfaceV2(_subscriptions).unsubscribe(_cdpId);
    }
}
