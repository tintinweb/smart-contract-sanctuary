/**
 *Submitted for verification at Etherscan.io on 2021-06-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract PIN_NFT_V001 {

    address public admin;
    address[] public nftContracts;
    mapping(address=>bool) public exists;
    
    mapping(address=>string) public instructions;
    mapping(address=>string) public checksums;

    constructor() {
        admin = msg.sender;
    }
    
    function setInstruction(address nft, string memory instruction, string memory checksum) public {
        require(msg.sender == admin, "Only admin can update instruction set");
        
        if (!exists[nft]) {
            nftContracts.push(nft);
            exists[nft] = true;
        }
        
        instructions[nft] = instruction;
        checksums[nft] = checksum;
        
    }
    
    function setAdmin(address _admin) public {
        require(msg.sender == admin, "Only admin can update admin");
        admin = _admin;
    }

}