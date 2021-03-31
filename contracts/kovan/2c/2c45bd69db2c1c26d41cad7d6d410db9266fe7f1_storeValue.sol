/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

pragma solidity >=0.7.0 <0.8.0;

//SPDX-License-Identifier: MIT

interface IstoreValue {
    function setValue(uint) external;
    function readValue() external view returns(uint);
    
}

contract storeValue is IstoreValue {
    uint val;
    constructor() {
        val = 0;
    }
    function setValue(uint v) override external {
        val = v;
    }
    function readValue() override external view returns(uint) {
        return val;
    }
}