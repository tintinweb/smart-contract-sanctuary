/**
 *Submitted for verification at BscScan.com on 2021-07-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Emma {
    mapping (address => uint256) cantidad;
    
    function sumar() public {
        cantidad[msg.sender]=cantidad[msg.sender]+1;
    }
    
    function mirar(address _address) public view returns (uint256) {
        return cantidad[_address];
    }
    
    function es_mayor_a_2_veces(address _address) public view returns (bool) {
        if (cantidad[_address] > 2) return true;
        return false;
    }
}