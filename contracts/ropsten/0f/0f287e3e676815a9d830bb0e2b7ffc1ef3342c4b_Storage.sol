/**
 *Submitted for verification at Etherscan.io on 2021-10-25
*/

// SPDX-License-Identifier: WTFPL

pragma solidity ^0.8.9;

contract Data {
    uint256 internal storedData;
    
    constructor(uint256 initialData) {
        storedData = initialData;
    }
    
    function get() public view returns(uint256) {
        return storedData;
    }
}

contract Storage {
    
    event DataCreated(address dataContract);
    
    function pushData(uint256 data) public returns(address) {
        Data d = new Data(data);
        emit DataCreated(address(d));
        return address(d);
    }
    
    function getData(address data) public view returns(uint256) {
        Data d = Data(data);
        return d.get();
    }
    
}