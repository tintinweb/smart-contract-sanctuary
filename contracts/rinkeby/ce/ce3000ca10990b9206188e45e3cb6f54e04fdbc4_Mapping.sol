/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

pragma solidity ^0.6.1;

contract Mapping {
    mapping(address => uint) public dni;
    function AsignarDNI(uint _dni) public {
        dni[msg.sender] = _dni;
    }
    function ObtenerDNI() view public returns (uint) {
        return dni[msg.sender];
    }
    function ObtenerDNI(address _dni) view public returns (uint) {
        return dni[_dni];
    }
}