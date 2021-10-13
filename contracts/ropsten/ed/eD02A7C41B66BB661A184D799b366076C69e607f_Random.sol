/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

// SPDX-License-Identifier: UNLICENSED
pragma  solidity ^0.8.0;
contract Random {
    
    function getRandom() view public returns(uint){
       uint256 num = uint256(keccak256(abi.encodePacked(
           'asdadasdasd',
                    (block.timestamp)+
                    (block.difficulty)+
                    ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp))+
                    (block.gaslimit)+
                    ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp))+
                    (block.number)
                ))) % 10;
      
                return num;
    }
    
}