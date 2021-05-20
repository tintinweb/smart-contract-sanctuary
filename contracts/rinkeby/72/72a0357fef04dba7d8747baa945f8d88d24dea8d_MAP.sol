/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

pragma solidity ^0.4.26;

contract MAP{
    mapping(address => uint256) public DNI;
    
    function asignarDNI(uint256 dni) public {
        DNI[msg.sender] = dni;
    }
    function get_mapping(address dni) public returns (uint256){
       DNI[dni];
    }
}