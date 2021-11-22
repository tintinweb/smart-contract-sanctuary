/**
 *Submitted for verification at BscScan.com on 2021-11-22
*/

/**
 *Submitted for verification at FtmScan.com on 2021-09-26
*/

// File: rarity_crafting_helper.sol

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;


interface rarity_crafting {
	function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function items(uint _id) external pure returns(
        uint8 base_type,
        uint8 item_type,
        uint32 crafted,
        uint256 crafter
    );
}


contract RarityCraftingHelper {
    rarity_crafting constant _rarity_crafting = rarity_crafting(0x04360E6D25D8FE53bE2B65Dde86567d72d1d0142);

    struct Item {
        uint8 base_type;
        uint8 item_type;
        uint256 crafter;
        uint256 item_id;
    }

    function getItemsByAddress(address owner) public view returns (Item[] memory) {
        require(owner != address(0), "cannot retrieve zero address");
        uint256 arrayLength = _rarity_crafting.balanceOf(owner);

        Item[] memory _items = new Item[](arrayLength);
        for (uint256 i = 0; i < arrayLength; i++) {
            uint256 tokenId = _rarity_crafting.tokenOfOwnerByIndex(owner, i);
            (uint8 base_type, uint8 item_type,, uint256 crafter) = _rarity_crafting.items(tokenId);
            _items[i] = Item(base_type, item_type, crafter, tokenId);
        }
        return _items;
    }
}