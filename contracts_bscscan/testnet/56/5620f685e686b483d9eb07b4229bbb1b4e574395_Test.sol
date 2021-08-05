/**
 *Submitted for verification at BscScan.com on 2021-08-05
*/

pragma solidity ^0.5.0;

contract Test {
    bool isinitiallize;
    mapping (address => bool) isAdmin;

    constructor() public{

    }

    

    function getIndex (address index) public view returns(bool) {
        return isAdmin[index];
    }

    function addIndex(address index, bool _isAdmin) public {
        isAdmin[index]= _isAdmin;
    }

    function removeIndex(address index) public {
        delete isAdmin[index];
    }

    function init1() public {
        require(!isinitiallize);
        isinitiallize=true;
    }
  
}