//"SPDX-Licence-Identifier: MIT"

pragma solidity ^0.6.0;

import "./101.sol";

contract StorageFactory{
    
    SimpleStorage[] public simpleStorageArray;
    
    function createSimpleStorageContract() public {
        SimpleStorage simpleStorage = new SimpleStorage();
        simpleStorageArray.push(simpleStorage);
    }
    
    function ofStore(uint256 _simpleStorageIndex, uint256 _simpleStorageNumber) public{
        
        SimpleStorage simpleStorage = SimpleStorage(address(simpleStorageArray[_simpleStorageIndex]));
        simpleStorage.store(_simpleStorageNumber);
    }
    
    function getStore(uint256 _simpleStorageIndex) public view returns (uint256) {
        
        SimpleStorage simpleStorage = SimpleStorage(address(simpleStorageArray[_simpleStorageIndex]));
        return simpleStorage.retrieve();
    }
    
    function getAllUsers() public view returns(SimpleStorage[] memory){
        return simpleStorageArray;
    }
}