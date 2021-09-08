/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

contract Test {
    
    address public myAddress;
    uint public count;
    
    function increment() external {
        count += 1;
    }
    
    function setMyAddress(address _address) external {
        myAddress = _address;
    }
    
    function balanceOf() external view returns(uint) {
        return myAddress.balance;
    }
}