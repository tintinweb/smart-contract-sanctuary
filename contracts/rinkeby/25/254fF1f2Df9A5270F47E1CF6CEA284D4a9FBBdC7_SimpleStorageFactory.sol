//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "./SimpleStorage.sol";

contract SimpleStorageFactory {
    
    SimpleStorage[] public SSArray;

    function createSimpleStorageContract() public {
        SimpleStorage createdSS = new SimpleStorage();

        SSArray.push(createdSS);
    }
}