pragma solidity >0.6.0 <=0.8.10;

import "./SimpleStorage.sol"; 

contract StorageFactory{

    SimpleStorage[] public simpleStorageArray;
    
    function createSimpleStorage() public{
        SimpleStorage simpleStorage = new SimpleStorage();
        simpleStorageArray.push(simpleStorage);
    }
    
    function sfStore(uint256 _simpleStorageIndex, uint256 _simpleStorageNumber) public{
        SimpleStorage(address(simpleStorageArray[_simpleStorageNumber])).store(_simpleStorageNumber);
    }
    
    function getAddress(uint256 _simpleStorageIndex) public returns(address){
        return address(simpleStorageArray[_simpleStorageIndex]);
    }
    
    function sfGet(uint256 _simpleStorageIndex) public returns(uint256){
        uint value = SimpleStorage(address(simpleStorageArray[_simpleStorageIndex])).retrieve();
        return value;
    }
    
}