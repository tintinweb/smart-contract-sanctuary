// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../access/Governable.sol";
import "../peripherals/interfaces/ITimelock.sol";

contract RewardManager is Governable {

    bool public isInitialized;

    ITimelock public timelock;
    address public rewardRouter;

    address public plpManager;

    address public stakedPxTracker;
    address public bonusPxTracker;
    address public feePxTracker;

    address public feePlpTracker;
    address public stakedPlpTracker;

    address public stakedPxDistributor;
    address public stakedPlpDistributor;

    address public esPx;
    address public bnPx;

    address public pxVester;
    address public plpVester;

    function initialize(
        ITimelock _timelock,
        address _rewardRouter,
        address _plpManager,
        address _stakedPxTracker,
        address _bonusPxTracker,
        address _feePxTracker,
        address _feePlpTracker,
        address _stakedPlpTracker,
        address _stakedPxDistributor,
        address _stakedPlpDistributor,
        address _esPx,
        address _bnPx,
        address _pxVester,
        address _plpVester
    ) external onlyGov {
        require(!isInitialized, "RewardManager: already initialized");
        isInitialized = true;

        timelock = _timelock;
        rewardRouter = _rewardRouter;

        plpManager = _plpManager;

        stakedPxTracker = _stakedPxTracker;
        bonusPxTracker = _bonusPxTracker;
        feePxTracker = _feePxTracker;

        feePlpTracker = _feePlpTracker;
        stakedPlpTracker = _stakedPlpTracker;

        stakedPxDistributor = _stakedPxDistributor;
        stakedPlpDistributor = _stakedPlpDistributor;

        esPx = _esPx;
        bnPx = _bnPx;

        pxVester = _pxVester;
        plpVester = _plpVester;
    }

    function updateEsPxHandlers() external onlyGov {
        timelock.managedSetHandler(esPx, rewardRouter, true);

        timelock.managedSetHandler(esPx, stakedPxDistributor, true);
        timelock.managedSetHandler(esPx, stakedPlpDistributor, true);

        timelock.managedSetHandler(esPx, stakedPxTracker, true);
        timelock.managedSetHandler(esPx, stakedPlpTracker, true);

        timelock.managedSetHandler(esPx, pxVester, true);
        timelock.managedSetHandler(esPx, plpVester, true);
    }

    function enableRewardRouter() external onlyGov {
        timelock.managedSetHandler(plpManager, rewardRouter, true);

        timelock.managedSetHandler(stakedPxTracker, rewardRouter, true);
        timelock.managedSetHandler(bonusPxTracker, rewardRouter, true);
        timelock.managedSetHandler(feePxTracker, rewardRouter, true);

        timelock.managedSetHandler(feePlpTracker, rewardRouter, true);
        timelock.managedSetHandler(stakedPlpTracker, rewardRouter, true);

        timelock.managedSetHandler(esPx, rewardRouter, true);

        timelock.managedSetMinter(bnPx, rewardRouter, true);

        timelock.managedSetMinter(esPx, pxVester, true);
        timelock.managedSetMinter(esPx, plpVester, true);

        timelock.managedSetHandler(pxVester, rewardRouter, true);
        timelock.managedSetHandler(plpVester, rewardRouter, true);

        timelock.managedSetHandler(feePxTracker, pxVester, true);
        timelock.managedSetHandler(stakedPlpTracker, plpVester, true);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract Governable {
    address public gov;

    constructor() public {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "Governable: forbidden");
        _;
    }

    function setGov(address _gov) external onlyGov {
        gov = _gov;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ITimelock {
    function setAdmin(address _admin) external;
    function managedSetHandler(address _target, address _handler, bool _isActive) external;
    function managedSetMinter(address _target, address _minter, bool _isActive) external;
}