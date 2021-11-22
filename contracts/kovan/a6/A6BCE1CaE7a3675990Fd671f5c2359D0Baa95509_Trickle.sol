// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
    function checkUpkeep(bytes calldata checkData)
        external
        returns (bool upkeepNeeded, bytes memory performData);

    function performUpkeep(bytes calldata performData) external;
}

contract Trickle is KeeperCompatibleInterface {
    uint256 public counter; // Public counter variable

    // Use an interval in seconds and a timestamp to slow execution of Upkeep
    uint256 public immutable interval;
    uint256 public lastTimeStamp;
    mapping(address => uint256) public user_to_interval;
    mapping(address => uint256) public user_to_amount;
    address[] public allowedTokens;
    mapping(address => mapping(address => uint256)) public stakingBalance;

    constructor(uint256 updateInterval) {
        interval = updateInterval;
        lastTimeStamp = block.timestamp;
        counter = 0;
    }

    // TODO: update conntract ABI
        // address _token_to_buy
    function setDca(
        uint256 _amount,
        uint256 _dca_interval
    ) public {
        require(_amount > 0, "amount cannot be 0");
        user_to_interval[msg.sender] = _dca_interval;
        user_to_amount[msg.sender] = _amount;
    }

    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
        performData = checkData;
    }

    function performUpkeep(bytes calldata performData) external override {
        lastTimeStamp = block.timestamp;
        counter = counter + 1;
        performData;
        // do stuff with user -> interval and user -> amount here
    }
}