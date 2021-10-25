/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

// SPDX-License-Identifier: WTFPL

pragma solidity ^0.8.9;

contract Data {
    bytes32 internal storedData;
    
    constructor(bytes32 initialData) {
        storedData = initialData;
    }
    
    function get() public view returns(bytes32) {
        return storedData;
    }
}

contract Storage {
    
    event DataCreated(Data dataContract, address contractAddr);
    
    function pushData(bytes32 data) public returns(address) {
        Data d = new Data(data);
        emit DataCreated(d, address(d));
        return address(d);
    }
    
    function getData(address data) public view returns(bytes32) {
        Data d = Data(data);
        return d.get();
    }
    
}