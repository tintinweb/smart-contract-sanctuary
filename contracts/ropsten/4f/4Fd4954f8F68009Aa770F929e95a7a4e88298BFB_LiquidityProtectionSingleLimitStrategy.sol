/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LosslessController {
    function admin() external returns(address);

    function isAddressProtected(address token, address protectedAddress) external view returns (bool);
}

interface Guardian {
    function protectionAdmin(address token) external returns (address);

    function setProtectedAddress(address token, address guardedAddress) external;

    function removeProtectedAddresses(address token, address protectedAddress) external;
}

abstract contract StrategyBase {
    Guardian public guardian;
    LosslessController public controller;

    // --- EVENTS ---

    event GuardianSet(address indexed newGuardian);
    event Paused(address indexed token, address indexed protectedAddress);
    event Unpaused(address indexed token, address indexed protectedAddress);

    constructor(Guardian _guardian, LosslessController _controller) {
        guardian = _guardian;
        controller = _controller;
    }

    // --- MODIFIERS ---

    modifier onlyProtectionAdmin(address token) {
        require(msg.sender == guardian.protectionAdmin(token), "LOSSLESS: Not protection admin");
        _;
    }

    // --- METHODS ---

    // @dev In case guardian is changed, this allows not to redeploy strategy and just update it.
    function setGuardian(Guardian newGuardian) public {
        require(msg.sender == controller.admin(), "LOSSLESS: Not lossless admin");
        guardian = newGuardian;
        emit GuardianSet(address(newGuardian));
    }
}

contract LiquidityProtectionSingleLimitStrategy is StrategyBase {
    mapping(address => Protection) private protection;

    // @dev using uint32 for gas savings
    struct Limit {
        uint256 periodInSeconds;  
        uint256 lastCheckpointTime; 
        uint256 amountPerPeriod;
        uint256 amountLeftInCurrentPeriod;
    }

    struct Protection {
        mapping(address => Limit) limits;
    }

    constructor(Guardian _guardian, LosslessController _controller) StrategyBase(_guardian, _controller) {}

    // --- VIEWS ---

    function getLimit(address token, address protectedAddress) public view returns(Limit memory) {
        return protection[token].limits[protectedAddress];
    }

    // --- METHODS ---

    // @param token Project token, the protection will be scoped inside of this token's transfers.
    // @param protectedAddress Address to apply the limits to.
    // @param periodInSeconds Limit period in seconds.
    // @param amountPerPeriod Max amount that can be transfered in period.
    // @param startTimestamp Shows when limit should be activated.
    // @dev This method allows setting 1 limit to 0...N addresses.
    function setLimitBatched(
        address token,
        address[] calldata protectedAddresses,
        uint256 periodInSeconds,
        uint256 amountPerPeriod,
        uint256 startTimestamp
    ) public onlyProtectionAdmin(token) {
        for(uint8 i = 0; i < protectedAddresses.length; i++) {
            saveLimit(token, protectedAddresses[i], periodInSeconds, amountPerPeriod, startTimestamp);
            guardian.setProtectedAddress(token, protectedAddresses[i]);
        }
    }

    // @dev params pretty much the same as in batched
    // @dev This method allows setting 1 limit 1 address.
    function setLimit(
        address token,
        address protectedAddress,
        uint256 periodInSeconds,
        uint256 amountPerPeriod,
        uint256 startTimestamp
    ) public onlyProtectionAdmin(token) {
        
        saveLimit(token, protectedAddress, periodInSeconds, amountPerPeriod, startTimestamp);
        guardian.setProtectedAddress(token, protectedAddress);
    }

    function removeLimits(address token, address[] calldata protectedAddresses) public onlyProtectionAdmin(token) {
        for(uint8 i = 0; i < protectedAddresses.length; i++) {
            delete protection[token].limits[protectedAddresses[i]];
            guardian.removeProtectedAddresses(token, protectedAddresses[i]);
        }
    }

    // @dev Pausing is just adding a limit with amount 0.
    // @dev amountLeftInCurrentPeriod never resets because of the lastCheckpointTime
    // @dev This approach uses less gas than having a separate isPaused flag.
    function pause(address token, address protectedAddress) public onlyProtectionAdmin(token) {
        require(controller.isAddressProtected(token, protectedAddress), "LOSSLESS: Address not protected");
        Limit storage limit = protection[token].limits[protectedAddress];
        limit.amountLeftInCurrentPeriod = 0;
        limit.lastCheckpointTime = type(uint256).max - limit.periodInSeconds;
        emit Paused(token, protectedAddress);
    }

    // @dev Limit is reset every period.
    // @dev Every period has it's own amountLeft which gets decreased on every transfer.
    // @dev This method modifies state so should be callable only by the trusted address!
    function isTransferAllowed(address token, address sender, address recipient, uint256 amount) external {
        require(msg.sender == address(controller), "LOSSLESS: LSS Controller only");
        Limit storage limit = protection[token].limits[sender];

        // Is transfer is in the same period ?
        if (limit.lastCheckpointTime + limit.periodInSeconds > block.timestamp) { 
            limit.amountLeftInCurrentPeriod = calculateAmountLeft(amount, limit.amountLeftInCurrentPeriod);
        }
        // New period started, update checkpoint and reset amount
        else {
            limit.lastCheckpointTime = calculateUpdatedCheckpoint(limit.lastCheckpointTime, limit.periodInSeconds);
            limit.amountLeftInCurrentPeriod = calculateAmountLeft(amount, limit.amountPerPeriod);
        }
        
        require(limit.amountLeftInCurrentPeriod > 0, "LOSSLESS: Strategy Limit reached");
    }

    // --- INTERNAL METHODS ---

    function saveLimit(
        address token,
        address protectedAddress,
        uint256 periodInSeconds,
        uint256 amountPerPeriod,
        uint256 startTimestamp
    ) internal {
        Limit storage limit = protection[token].limits[protectedAddress];
        limit.periodInSeconds = periodInSeconds;
        limit.amountPerPeriod = amountPerPeriod;
        limit.lastCheckpointTime = startTimestamp;
        limit.amountLeftInCurrentPeriod = amountPerPeriod;
    }

    function calculateAmountLeft(uint256 amount, uint256 amountLeft) internal pure returns (uint256)  {
        if (amount >= amountLeft) {
            return 0;
        } else {
            return amountLeft - amount;
        }
    }

    function calculateUpdatedCheckpoint(uint256 lastCheckpoint, uint256 periodInSeconds) internal pure returns(uint256) {
        return lastCheckpoint + periodInSeconds;
    }
}