/**
 *Submitted for verification at Etherscan.io on 2021-11-15
*/

//SPDX-License-Identifier:UNLICENSED
pragma solidity >=0.7.6;
interface KeeperCompatibleInterface {
    function checkUpkeep(bytes calldata checkData) external view
        returns (bool upkeepNeeded, bytes memory performData);
    function performUpkeep(bytes calldata performData) external;
}
contract KeeperProxy is KeeperCompatibleInterface {
    KeeperCompatibleInterface public kci;
    uint public count = 0;
    uint public interval = 0;
    uint public lastTimestamp = block.timestamp;
    bool public active = true;
    function activate() external {
        active = true;
    }
    function deactivate() external {
        active = false;
    }
    function setKCI(KeeperCompatibleInterface newKci) external {
        kci = newKci;
    }
    function setInterval(uint updateInterval) external {
        interval = updateInterval;
    }
    function checkUpkeep(bytes calldata checkData) view override external
        returns (bool upkeepNeeded,
                 bytes memory performData) {
        if(address(kci) != address(0) &&
           block.timestamp - lastTimestamp > interval)
            return kci.checkUpkeep(checkData);
    }
    function performUpkeep(bytes calldata performData) external override {
        if(address(kci) != address(0) &&
           block.timestamp - lastTimestamp > interval) {
            ++count;
            lastTimestamp = block.timestamp;
            return kci.performUpkeep(performData);
        }
    }
}