/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ILoot {
    function claim(uint256 tokenId) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

contract BatchLoot {
    bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

    function claim(address loot, uint256[] calldata ids) public {
        ILoot l = ILoot(loot);
        for (uint256 i = 0; i < ids.length; i++) {
            l.claim(ids[i]);
            l.transferFrom(address(this), msg.sender, ids[i]);
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) public returns (bytes4) {
        return ERC721_RECEIVED;
    }
}