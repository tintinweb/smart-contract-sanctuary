/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

//SPDX-License-Identifier:UNLICENSED                                                                                            
pragma solidity >=0.7.0;
interface KeeperCompatibleInterface {
    function checkUpkeep(bytes calldata checkData) external view
        returns (bool upkeepNeeded, bytes memory performData);
    function performUpkeep(bytes calldata performData) external;
}
contract KeeperProxy is KeeperCompatibleInterface {
    KeeperCompatibleInterface _kci;
    uint public interval;
    uint public lastTimeStamp;
    function setKCI(address a) external {
        _kci = KeeperCompatibleInterface(a);
    }
    function setInterval(uint updateInterval) external {
        interval = updateInterval;
    }
    function kci() external view returns(address) {
        return address(_kci);
    }
    function getInterval() external view returns(uint) {
        return interval;
    }
    constructor(uint updateInterval) {
        interval = updateInterval;
        lastTimeStamp = block.timestamp;
    }
    function checkUpkeep(bytes calldata checkData) view override external
        returns (bool upkeepNeeded,
                 bytes memory performData) {
        if(address(_kci) != address(0) &&
           block.timestamp - lastTimeStamp > interval) {
            return _kci.checkUpkeep(checkData);
        }
    }

    function performUpkeep(bytes calldata performData) external override {
        if(address(_kci) != address(0) &&
           block.timestamp - lastTimeStamp > interval) {
            lastTimeStamp = block.timestamp;
            return _kci.performUpkeep(performData);
        }
    }
}