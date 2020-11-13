pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../interfaces/Manager.sol";
import "./StaticV2.sol";
import "../saver/MCDSaverProxy.sol";
import "../../interfaces/Vat.sol";
import "../../interfaces/Spotter.sol";
import "../../auth/AdminAuth.sol";

/// @title Handles subscriptions for automatic monitoring
contract SubscriptionsV2 is AdminAuth, StaticV2 {

    bytes32 internal constant ETH_ILK = 0x4554482d41000000000000000000000000000000000000000000000000000000;
    bytes32 internal constant BAT_ILK = 0x4241542d41000000000000000000000000000000000000000000000000000000;

    address public constant MANAGER_ADDRESS = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;
    address public constant VAT_ADDRESS = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address public constant SPOTTER_ADDRESS = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;

    CdpHolder[] public subscribers;
    mapping (uint => SubPosition) public subscribersPos;

    mapping (bytes32 => uint) public minLimits;

    uint public changeIndex;

    Manager public manager = Manager(MANAGER_ADDRESS);
    Vat public vat = Vat(VAT_ADDRESS);
    Spotter public spotter = Spotter(SPOTTER_ADDRESS);
    MCDSaverProxy public saverProxy;

    event Subscribed(address indexed owner, uint cdpId);
    event Unsubscribed(address indexed owner, uint cdpId);
    event Updated(address indexed owner, uint cdpId);
    event ParamUpdates(address indexed owner, uint cdpId, uint128, uint128, uint128, uint128, bool boostEnabled);

    /// @param _saverProxy Address of the MCDSaverProxy contract
    constructor(address _saverProxy) public {
        saverProxy = MCDSaverProxy(payable(_saverProxy));

        minLimits[ETH_ILK] = 1700000000000000000;
        minLimits[BAT_ILK] = 1700000000000000000;
    }

    /// @dev Called by the DSProxy contract which owns the CDP
    /// @notice Adds the users CDP in the list of subscriptions so it can be monitored
    /// @param _cdpId Id of the CDP
    /// @param _minRatio Minimum ratio below which repay is triggered
    /// @param _maxRatio Maximum ratio after which boost is triggered
    /// @param _optimalBoost Ratio amount which boost should target
    /// @param _optimalRepay Ratio amount which repay should target
    /// @param _boostEnabled Boolean determing if boost is enabled
    /// @param _nextPriceEnabled Boolean determing if we can use nextPrice for this cdp
    function subscribe(uint _cdpId, uint128 _minRatio, uint128 _maxRatio, uint128 _optimalBoost, uint128 _optimalRepay, bool _boostEnabled, bool _nextPriceEnabled) external {
        require(isOwner(msg.sender, _cdpId), "Must be called by Cdp owner");

        // if boost is not enabled, set max ratio to max uint
        uint128 localMaxRatio = _boostEnabled ? _maxRatio : uint128(-1);
        require(checkParams(manager.ilks(_cdpId), _minRatio, localMaxRatio), "Must be correct params");

        SubPosition storage subInfo = subscribersPos[_cdpId];

        CdpHolder memory subscription = CdpHolder({
                minRatio: _minRatio,
                maxRatio: localMaxRatio,
                optimalRatioBoost: _optimalBoost,
                optimalRatioRepay: _optimalRepay,
                owner: msg.sender,
                cdpId: _cdpId,
                boostEnabled: _boostEnabled,
                nextPriceEnabled: _nextPriceEnabled
            });

        changeIndex++;

        if (subInfo.subscribed) {
            subscribers[subInfo.arrPos] = subscription;

            emit Updated(msg.sender, _cdpId);
            emit ParamUpdates(msg.sender, _cdpId, _minRatio, localMaxRatio, _optimalBoost, _optimalRepay, _boostEnabled);
        } else {
            subscribers.push(subscription);

            subInfo.arrPos = subscribers.length - 1;
            subInfo.subscribed = true;

            emit Subscribed(msg.sender, _cdpId);
        }
    }

    /// @notice Called by the users DSProxy
    /// @dev Owner who subscribed cancels his subscription
    function unsubscribe(uint _cdpId) external {
        require(isOwner(msg.sender, _cdpId), "Must be called by Cdp owner");

        _unsubscribe(_cdpId);
    }

    /// @dev Checks if the _owner is the owner of the CDP
    function isOwner(address _owner, uint _cdpId) internal view returns (bool) {
        return getOwner(_cdpId) == _owner;
    }

    /// @dev Checks limit for minimum ratio and if minRatio is bigger than max
    function checkParams(bytes32 _ilk, uint128 _minRatio, uint128 _maxRatio) internal view returns (bool) {
        if (_minRatio < minLimits[_ilk]) {
            return false;
        }

        if (_minRatio > _maxRatio) {
            return false;
        }

        return true;
    }

    /// @dev Internal method to remove a subscriber from the list
    function _unsubscribe(uint _cdpId) internal {
        require(subscribers.length > 0, "Must have subscribers in the list");

        SubPosition storage subInfo = subscribersPos[_cdpId];

        require(subInfo.subscribed, "Must first be subscribed");

        uint lastCdpId = subscribers[subscribers.length - 1].cdpId;

        SubPosition storage subInfo2 = subscribersPos[lastCdpId];
        subInfo2.arrPos = subInfo.arrPos;

        subscribers[subInfo.arrPos] = subscribers[subscribers.length - 1];
        subscribers.pop();

        changeIndex++;
        subInfo.subscribed = false;
        subInfo.arrPos = 0;

        emit Unsubscribed(msg.sender, _cdpId);
    }

    /// @notice Returns an address that owns the CDP
    /// @param _cdpId Id of the CDP
    function getOwner(uint _cdpId) public view returns(address) {
        return manager.owns(_cdpId);
    }

    /// @notice Helper method for the front to get all the info about the subscribed CDP
    function getSubscribedInfo(uint _cdpId) public view returns(bool, uint128, uint128, uint128, uint128, address, uint coll, uint debt) {
        SubPosition memory subInfo = subscribersPos[_cdpId];

        if (!subInfo.subscribed) return (false, 0, 0, 0, 0, address(0), 0, 0);

        (coll, debt) = saverProxy.getCdpInfo(manager, _cdpId, manager.ilks(_cdpId));

        CdpHolder memory subscriber = subscribers[subInfo.arrPos];

        return (
            true,
            subscriber.minRatio,
            subscriber.maxRatio,
            subscriber.optimalRatioRepay,
            subscriber.optimalRatioBoost,
            subscriber.owner,
            coll,
            debt
        );
    }

    function getCdpHolder(uint _cdpId) public view returns (bool subscribed, CdpHolder memory) {
        SubPosition memory subInfo = subscribersPos[_cdpId];

        if (!subInfo.subscribed) return (false, CdpHolder(0, 0, 0, 0, address(0), 0, false, false));

        CdpHolder memory subscriber = subscribers[subInfo.arrPos];

        return (true, subscriber);
    }

    /// @notice Helper method for the front to get the information about the ilk of a CDP
    function getIlkInfo(bytes32 _ilk, uint _cdpId) public view returns(bytes32 ilk, uint art, uint rate, uint spot, uint line, uint dust, uint mat, uint par) {
        // send either ilk or cdpId
        if (_ilk == bytes32(0)) {
            _ilk = manager.ilks(_cdpId);
        }

        ilk = _ilk;
        (,mat) = spotter.ilks(_ilk);
        par = spotter.par();
        (art, rate, spot, line, dust) = vat.ilks(_ilk);
    }

    /// @notice Helper method to return all the subscribed CDPs
    function getSubscribers() public view returns (CdpHolder[] memory) {
        return subscribers;
    }

    /// @notice Helper method to return all the subscribed CDPs
    function getSubscribersByPage(uint _page, uint _perPage) public view returns (CdpHolder[] memory) {
        CdpHolder[] memory holders = new CdpHolder[](_perPage);

        uint start = _page * _perPage;
        uint end = start + _perPage;

        uint count = 0;
        for (uint i=start; i<end; i++) {
            holders[count] = subscribers[i];
            count++;
        }

        return holders;
    }

    ////////////// ADMIN METHODS ///////////////////

    /// @notice Admin function to change a min. limit for an asset
    function changeMinRatios(bytes32 _ilk, uint _newRatio) public onlyOwner {
        minLimits[_ilk] = _newRatio;
    }

    /// @notice Admin function to unsubscribe a CDP
    function unsubscribeByAdmin(uint _cdpId) public onlyOwner {
        SubPosition storage subInfo = subscribersPos[_cdpId];

        if (subInfo.subscribed) {
            _unsubscribe(_cdpId);
        }
    }
}
