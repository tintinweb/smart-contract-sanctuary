// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20
pragma solidity ^0.4.8;

 contract T {
     function getHash(uint256 number) view public returns (bytes32) {
         return blockhash(number);
     }
 }