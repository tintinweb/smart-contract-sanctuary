/**
 *Submitted for verification at polygonscan.com on 2022-01-18
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <9.0.0;

contract DecentralandMock {
    struct Item {
        string rarity;
        uint maxSupply;
        uint totalSupply;
        uint price;
        address beneficiary;
        string metadata;
        string contentHash;
    }

    Item[] public items;

    constructor () {
        items.push(Item("uncommon", 10000, 0, 0, address(0x0), "1:w:Female Old 80's Cap:Official merch of the \"Old 80's\" NFT collection. :hat:BaseFemale", "QmNmcvh5hNXgGBQ2KJFXsBQsZscDmdAxHdUrLgcLes2MH8"));
        items.push(Item("uncommon", 10000, 0, 0, address(0x0), "1:w:Male Old 80's Cap:Official merch of the \"Old 80's\" NFT collection.:hat:BaseMale", "QmWmJfa3QjcwFaBKeoudoz553d9JTfUDqxdFT3Zte5YVvB"));
        items.push(Item("rare", 5000, 0, 0, address(0x0), "1:w:Female Old 80's Hoodie:Official merch of the \"Old 80's\" NFT collection. :upper_body:BaseFemale", "QmeLcaURB9Dyj1cQDkUgEyCGEEQ25DnQa6SKfCsGfEUtmY"));
        items.push(Item("rare", 5000, 0, 0, address(0x0), "1:w:Male Old 80's Hoodie:Official merch of the \"Old 80's\" NFT collection. :upper_body:BaseMale", "QmcU1kEpJrxN3k9Cx8BrJQB6Y2o6WbLgHhrgHjcnJfKakq"));
    }

    function issueTokens(address[] calldata _beneficiaries, uint[] calldata _itemIds) public {
        require(_beneficiaries.length == _itemIds.length, "issueTokens: LENGTH_MISMATCH");

        for (uint i = 0; i < _itemIds.length; i++) {
            items[_itemIds[i]].totalSupply++;
        }
    }
}