/**
 *Submitted for verification at Etherscan.io on 2021-11-03
*/

// SPDX-License-Identifier: MIT
// Programando-ETH.sol
// SmartContract-by-VeroLozano.sol
// Mi-primer-SmartContract.sol
pragma solidity >=0.7.0 <0.8.0;

contract NFTVeloz{
    string TokenId;
    
    function Escribir(string calldata _TokenId) public{
        TokenId = _TokenId;    
    }
    
    function Leer() public view returns(string memory){
        return TokenId;
    }
}