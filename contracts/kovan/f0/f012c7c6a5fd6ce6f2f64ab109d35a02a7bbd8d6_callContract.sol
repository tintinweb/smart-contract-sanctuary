/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

pragma solidity >=0.7.0 <0.8.0;

//SPDX-License-Identifier: MIT

interface IstoreValue {
    function setValue(uint) external;
    function readValue() external view returns(uint);
    
}

contract callContract {
    IstoreValue c;
    constructor () {
        c = IstoreValue(0x2c45bD69db2C1C26D41CAd7D6D410Db9266Fe7F1);
    }
    function readV() external view returns(uint) {
        return c.readValue();
    }
    function changeV(uint v) external {
        c.setValue(v);
    } 
}