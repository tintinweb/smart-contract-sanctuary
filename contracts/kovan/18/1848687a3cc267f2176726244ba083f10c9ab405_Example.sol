/**
 *Submitted for verification at Etherscan.io on 2021-11-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface KeeperCompatibleInterface {
    function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);
    function performUpkeep(bytes calldata performData) external;
}

contract Example is KeeperCompatibleInterface {

            uint public immutable interval;
            uint public lastTimeStamp;
            uint public number;
            uint public counter;
              

            /// lastTimeStamp is the moment the smart contract is created
            /// interval is defined on the contract deployment and is immutable 
            constructor (uint updateInterval) {
                interval = updateInterval;
                lastTimeStamp = block.timestamp;
                number = 0;
                counter = 0;
            }

            function math() public returns (uint) {
                number = number + 2;
            }           

            function checkUpkeep(bytes calldata checkData) external view override returns (bool upkeepNeeded, bytes memory performData) {
            upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    
            performData = checkData;
            }

            function performUpkeep(bytes calldata performData) external override {
                lastTimeStamp = block.timestamp;
                math();
                counter = counter + 1;

                performData;
            }
        }