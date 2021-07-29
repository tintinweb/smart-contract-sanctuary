/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Armazenar {

    uint256 numero;

    function guardar(uint256 num) public {
        numero = num;
    }

    function ler() public view returns (uint256){
        return numero;
    }
}