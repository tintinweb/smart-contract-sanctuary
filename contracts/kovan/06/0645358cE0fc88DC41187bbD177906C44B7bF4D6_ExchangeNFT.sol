/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function mint(address to, uint256 tokenId) external;
}

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

contract ExchangeNFT is IERC721Receiver {
    struct Info {
        uint256 price;
        address owner;
    }
    mapping (address => mapping (uint256 => Info)) public sellInfo;

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function sellNFT(address _NFT_Address, uint256 _tokenID, uint256 _NFTPrice) public {
        IERC721Enumerable(_NFT_Address).safeTransferFrom(msg.sender, address(this), _tokenID);
        sellInfo[_NFT_Address][_tokenID].price = _NFTPrice;
        sellInfo[_NFT_Address][_tokenID].owner = msg.sender;
    }

    function cancelDeal(address _NFT_Address, uint256 _tokenID) public {
        require(sellInfo[_NFT_Address][_tokenID].owner == msg.sender, "ExchangeNFT: no authority.");
        IERC721Enumerable(_NFT_Address).safeTransferFrom(address(this), msg.sender, _tokenID);
        delete sellInfo[_NFT_Address][_tokenID];
    }

    function buyNFT(address _NFT_Address, uint256 _tokenID, uint256 _NFTPrice) public payable {
        require(sellInfo[_NFT_Address][_tokenID].price == msg.value, "ExchangeNFT: price error.");
        require(_NFTPrice == msg.value, "ExchangeNFT: verify price error.");
        address payable receiver = payable(sellInfo[_NFT_Address][_tokenID].owner);
        delete sellInfo[_NFT_Address][_tokenID];
        IERC721Enumerable(_NFT_Address).safeTransferFrom(address(this), msg.sender, _tokenID);
        receiver.transfer(_NFTPrice);
    }

    function isOnSale(address _NFT_Address, uint256 _tokenID) public view returns (bool) {
        if(sellInfo[_NFT_Address][_tokenID].owner == address(0)) return false;
        return true;
    }
}