/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface ILootBox {
  function afterHarbergerBuy(uint256 _tokenId, address _newOwner) external;
}

interface BuidlNFT {
  function metadataOf(uint256 _tokenId) external view returns (
    address owner,
    uint256 bid,
    uint256 originalPrice,
    uint256 currentPrice,
    uint256 txs,
    address buidler,
    string memory url,
    address lootBox
  );
}

contract EVOLootBox is ILootBox {
    event EVOHarbergerBuy(address newOwner, uint256 currentPrice, uint256 txs, uint256 receive_land_id);

    address private immutable BUIDL_NFT;
    uint256 private immutable EVO_BUIDL_ID;
    uint256 private immutable RECEIVE_LAND_ID;

    constructor(address _buidl_nft, uint256 _evo_buidl_id, uint256 _receive_land_id) {
        BUIDL_NFT = _buidl_nft;
        EVO_BUIDL_ID = _evo_buidl_id;
        RECEIVE_LAND_ID = _receive_land_id;
    }

    function afterHarbergerBuy(uint256 _tokenId, address _newOwner) override external {
       require(msg.sender == BUIDL_NFT, "!buildl");
       require(_tokenId == EVO_BUIDL_ID, "!evo");
       (,,,uint256 currentPrice,uint256 txs,,,) = BuidlNFT(msg.sender).metadataOf(_tokenId);
       emit EVOHarbergerBuy(_newOwner, currentPrice, txs, RECEIVE_LAND_ID);
    }
}