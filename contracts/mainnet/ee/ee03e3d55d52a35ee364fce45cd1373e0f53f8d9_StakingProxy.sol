pragma solidity ^0.5.0;

import "./SwipeRegistry.sol";
import "./StakingEvent.sol";

/// @title Upgradeable Registry Contract
/// @author growlot (@growlot)
contract StakingProxy is SwipeRegistry, StakingEvent {
    /// @notice Contract constructor
    /// @dev Calls SwipeRegistry contract constructor
    constructor() public SwipeRegistry("Swipe Staking Proxy") {}
}
