/**
 *Submitted for verification at Etherscan.io on 2021-08-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.1;

contract Variables {
    uint public myUint;
    bool public myBool;
    address public myAddress;
    uint8 public myUint8;
    string public myString = "Hello World";

    function setMyUint(uint _myUint) public {
        myUint = _myUint;
    }
    
    function setMyBool(bool _myBool) public {
        myBool = _myBool;
    }
    
    function setMyAddress(address _address) public {
        myAddress = _address;
    }
    
    function getBalanceOfAccount() public view returns(uint) {
        return myAddress.balance;
    }
    
    function decrement() public {
        unchecked{
            myUint8--;
        }
    }
    
    function increment() public {
        unchecked{
            myUint8++;
        }
    }
    
    function setMyString(string memory _myString) public {
        myString = _myString;
    }
}