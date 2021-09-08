/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

interface ITest {
    function count() external view returns(uint);
    function increment() external;
    function setMyAddress(address _address) external;
    function balanceOf() external view returns(uint);
    function myAddress() external view returns(address);
}

contract Interaction {
    address testAddr;
    
    function setTestAddr(address _counter) public payable {
        testAddr = _counter;
    }
    
    function getTestAddr() external view returns(address) {
        return ITest(testAddr).myAddress();
    }
    
    function getCount() external view returns(uint) {
        return ITest(testAddr).count();
    }
    
    function getBalance() external view returns(uint) {
        return ITest(testAddr).balanceOf();
    }
}