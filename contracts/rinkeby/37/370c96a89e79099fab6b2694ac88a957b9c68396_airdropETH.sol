/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

// File: airdropETH.sol

pragma solidity 0.8.7;

contract airdropETH {
    constructor() {}
    
    function airdrop(address payable[] memory receivers, uint value) external payable {
        unchecked {
            require(msg.value == receivers.length * value,"Invalid input amount");
            for(uint i = 0;i < receivers.length; i++) {
                receivers[i].call{value:value,gas:0}("");
            }
        }
    }
}