/**
 *Submitted for verification at FtmScan.com on 2021-12-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IAssetBox {
    function getbalance(uint8 roleIndex, uint tokenID) external view returns (uint);
    function mint(uint8 roleIndex, uint tokenID, uint amount) external;
    function transfer(uint8 roleIndex, uint from, uint to, uint amount) external;
    function burn(uint8 roleIndex, uint tokenID, uint amount) external;
    function getRole(uint8 index) external view returns (address);
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}


contract AssetNPC {

    address public immutable currency;
    address public immutable goods;

    uint public totalSupply;

    // exchange ratio
    uint public immutable ratio;

    uint public immutable minimumOrder;

    constructor (address currency_, address goods_, uint ratio_, uint minimumOrder_) {
        currency = currency_;
        goods = goods_;
        ratio = ratio_;

        minimumOrder = minimumOrder_;
    }

    /**
        amount: asset amount
     */
    function claim(uint8 roleIndex, uint tokenID, uint amount) external {
        require(amount >= minimumOrder, "Less than minimum order quantities");

        address roleOfCurrency = IAssetBox(currency).getRole(roleIndex);
        address roleOfGoods = IAssetBox(goods).getRole(roleIndex);
        require(roleOfCurrency == roleOfGoods, "Not the same NFT address");

        require(_isApprovedOrOwner(roleOfCurrency, msg.sender, tokenID), "Not approved or owner");
        
        totalSupply += amount;
        uint currencyAmount = amount * ratio;

        IAssetBox(currency).burn(roleIndex, tokenID, currencyAmount);
        IAssetBox(goods).mint(roleIndex, tokenID, amount);
    }
    
    function _isApprovedOrOwner(address role, address operator, uint256 tokenId) private view returns (bool) {
        require(role != address(0), "Query for the zero address");
        address TokenOwner = IERC721(role).ownerOf(tokenId);
        return (operator == TokenOwner || IERC721(role).getApproved(tokenId) == operator || IERC721(role).isApprovedForAll(TokenOwner, operator));
    }

}