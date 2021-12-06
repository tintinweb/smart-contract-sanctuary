// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SimpleStorage.sol";

contract StorageFactory{

    SimpleStorage[] public simpleStorageArray;

    function createSimpleStorageContrct() public{
        SimpleStorage simpleStorage=new SimpleStorage();
        simpleStorageArray.push(simpleStorage);
    }

    function sfStore(uint256 _simpleStorageIndex,uint256 _simpleStorageNum) public{
        SimpleStorage simpleStorage = SimpleStorage(address (simpleStorageArray[_simpleStorageIndex]));
simpleStorage.store(_simpleStorageNum);
    }

    function sfGet(uint256 _simpleStorageIndex) public view returns(uint256){
        return simpleStorageArray[_simpleStorageIndex].getNum();
    }
}