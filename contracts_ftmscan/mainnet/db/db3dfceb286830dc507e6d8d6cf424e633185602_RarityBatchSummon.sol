/**
 *Submitted for verification at FtmScan.com on 2021-12-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IRarity {
    function summon(uint _class) external;
    function next_summoner() external view returns(uint);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

contract RarityBatchSummon {
    address owner;
    IRarity constant rarity = IRarity(0xce761D788DF608BD21bdd59d6f4B54b2e27F25Bb);

    function summon(uint8[11] calldata _counts) external {
        uint first = rarity.next_summoner();
        for (uint j = 0; j < _counts[0]; j++) {
            rarity.summon(1);
        }
        for (uint j = 0; j < _counts[1]; j++) {
            rarity.summon(2);
        }
        for (uint j = 0; j < _counts[2]; j++) {
            rarity.summon(3);
        }
        for (uint j = 0; j < _counts[3]; j++) {
            rarity.summon(4);
        }
        for (uint j = 0; j < _counts[4]; j++) {
            rarity.summon(5);
        }
        for (uint j = 0; j < _counts[5]; j++) {
            rarity.summon(6);
        }
        for (uint j = 0; j < _counts[6]; j++) {
            rarity.summon(7);
        }
        for (uint j = 0; j < _counts[7]; j++) {
            rarity.summon(8);
        }
        for (uint j = 0; j < _counts[8]; j++) {
            rarity.summon(9);
        }
        for (uint j = 0; j < _counts[9]; j++) {
            rarity.summon(10);
        }
        for (uint j = 0; j < _counts[10]; j++) {
            rarity.summon(11);
        }
        uint last = rarity.next_summoner();
        for (uint id = first; id < last; id++) {
            rarity.safeTransferFrom(address(this), msg.sender, id);
        }
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) public view returns (bytes4){
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }
}