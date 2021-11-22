/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.1;

contract PingPong {
    
    address owner;
    uint256 data_creazione;
    
    constructor () payable {
        owner = msg.sender;
        data_creazione = block.timestamp;
    }
    
    function Ping () payable public {
        require(address(this).balance - msg.value > 0.01 ether);
        payable(msg.sender).transfer(msg.value + 0.01 ether);
    }
    
    function withdraw () public {
        require(msg.sender == owner, "Autorizzazione negata!");
        require(block.timestamp > data_creazione + 2 days, "Troppo presto!");
        payable(owner).transfer(address(this).balance);
    }
    
}