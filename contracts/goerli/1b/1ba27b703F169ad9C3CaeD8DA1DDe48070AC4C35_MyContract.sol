/**
 *Submitted for verification at Etherscan.io on 2021-04-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

contract MyContract {
    string public myString ="Hello World!";
    uint public myUint;
    bool public myBool;
    uint8 public myUint8;
    address public myAddress;
    
    function setMyUint(uint _myUint) public {
        myUint = _myUint;
    }
    
    function setMyBool(bool _myBool) public {
        myBool = _myBool;
    }
    
    function incrementUint() public {
        myUint8++;
    }
    
    function decrementUint() public {
        unchecked { myUint8--; }
    }
    
    function setAddress(address _myAddress) public {
        myAddress = _myAddress;
    }
    
    function getBalance() public view returns(uint) {
        return myAddress.balance;
    }
}