/**
 *Submitted for verification at Etherscan.io on 2021-08-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IUnicFarm {
    function pendingUnic(uint256 _pid, address _user) external view returns (uint256);
    function poolLength() external view returns (uint256);
}

interface IV3 {
    function updatePool(uint256 _pid) external;
}

contract UniclyFarmV3DoHardWorkExecutorV2 {

    address public constant V3 = address(0x07306aCcCB482C8619e7ed119dAA2BDF2b4389D0);
    address public constant UNIC_MASTERCHEF = address(0x4A25E4DF835B605A5848d2DB450fA600d96ee818);

    function doHardWork(string[] memory _pids) public {
        for (uint256 _pid = 0; _pid < _pids.length; _pid++) {
            IV3(V3).updatePool(_pid);
        }
    }

}