/**
 *Submitted for verification at BscScan.com on 2021-10-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.5.0;

contract Token{
    
    Storage public storageInterface;
    
    function setStorageInterface(Storage _storageAddress) public{
        storageInterface = _storageAddress;
    }
    
    function getString() public view returns(string memory){
        return storageInterface.store();
    }
}

contract Storage{
    string public store;
    
    function setStorage(string memory _newString) public {

    }
}