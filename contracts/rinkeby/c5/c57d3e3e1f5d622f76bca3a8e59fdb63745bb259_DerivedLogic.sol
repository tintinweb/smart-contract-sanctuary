/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

// SPDX-License-Identifier: Unlicensed.
pragma solidity 0.8.7;

contract DerivedLogic {

    address private storageContract;
    uint256 number;

    constructor(address _storageContract) {

        storageContract = _storageContract;
    }

    function setNumber(uint256 _number) external {
        number = _number;
    }

    function getStorageAddress() external view returns(address) {
        return storageContract;
    }


}