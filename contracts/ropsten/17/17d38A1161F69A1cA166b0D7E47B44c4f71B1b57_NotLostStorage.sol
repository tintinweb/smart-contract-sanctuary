/**
 *Submitted for verification at Etherscan.io on 2021-08-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract ProxyStorage {
    address public otherContractAddress;

    function setOtherAddressStorage(address _otherContract) internal {
        otherContractAddress = _otherContract;
    }
}

contract NotLostStorage is ProxyStorage {
    address public myAddress;
    uint public myUint;

    function setAddress(address _address) public {
        myAddress = _address;
    }

    function setMyUint(uint _uint) public {
        myUint = _uint*2;
    }

}