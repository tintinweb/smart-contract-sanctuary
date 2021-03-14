/**
 *Submitted for verification at Etherscan.io on 2021-03-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

contract Box {
    string public message = "";
    uint256 public reservedUntilBlock;
    
    function setMessage(string memory _message) public payable {
        require(block.number > reservedUntilBlock, "El mensaje no se puede cambiar todavia");
        
        uint256 reservedBlocks = msg.value / 0.1 ether;
        
        require(reservedBlocks > 0, "Al menos un bloque debe ser reservado");
        
        reservedUntilBlock = block.number + reservedBlocks;
        message = _message;
    }
}