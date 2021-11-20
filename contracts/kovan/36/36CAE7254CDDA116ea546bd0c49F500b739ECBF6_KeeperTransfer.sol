/**
 *Submitted for verification at Etherscan.io on 2021-11-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface KeeperCompatibleInterface {
    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);
    function performUpkeep(bytes calldata performData) external;
}

contract KeeperTransfer is KeeperCompatibleInterface {

    uint public counter;    // Public counter variable

    // Use an interval in seconds and a timestamp to slow execution of Upkeep
    uint public immutable interval;
    uint public lastTimeStamp;    
    
    event Received(address, uint);

    constructor(uint updateInterval) {
      interval = updateInterval;
      lastTimeStamp = block.timestamp;
      counter = 0;
    }
    
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function checkUpkeep(bytes calldata checkData) external view override returns (bool upkeepNeeded, bytes memory performData) {
        address wallet = abi.decode(checkData, (address));
        
        upkeepNeeded = 
        ( (block.timestamp - lastTimeStamp) > interval &&  
        wallet.balance < 100000000 gwei && 
        address(this).balance > 100000000 gwei);
        
        performData = checkData;
        
    }

    function performUpkeep(bytes calldata performData) external override {
        address payable wallet = abi.decode(performData, (address));
        wallet.transfer(10000000 gwei);
        lastTimeStamp = block.timestamp;
    }
    
    
}