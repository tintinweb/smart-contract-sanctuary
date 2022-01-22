/**
 *Submitted for verification at BscScan.com on 2022-01-22
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
    mapping (uint256 => Info) public sellInfo;
    IERC721Enumerable public immutable NFTContract;
    mapping(address => mapping(uint256 => uint256)) public ownedNFT;
    mapping(uint256 => uint256) public ownedNFTIndex;
    mapping(address => uint256) public sellNum;

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'ExchangeNFT: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor(IERC721Enumerable _NFTContract) {
        NFTContract = _NFTContract;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function sellNFT(uint256 _tokenID, uint256 _NFTPrice) public {
        require(_NFTPrice > 0, "ExchangeNFT: NFT price must be positive.");
        NFTContract.safeTransferFrom(msg.sender, address(this), _tokenID);

        _addNFTtoOwnerEnumeration(msg.sender, _tokenID);

        sellInfo[_tokenID].price = _NFTPrice;
        sellInfo[_tokenID].owner = msg.sender;
        sellNum[msg.sender]++;
    }

    function cancelDeal(uint256 _tokenID) lock public {
        require(sellInfo[_tokenID].owner == msg.sender, "ExchangeNFT: no authority.");
        NFTContract.safeTransferFrom(address(this), msg.sender, _tokenID);
        
        _removeNFTfromOwnerEnumeration(msg.sender, _tokenID);
        
        delete sellInfo[_tokenID];
        sellNum[msg.sender]--;
    }

    function buyNFT(uint256 _tokenID, uint256 _NFTPrice) lock public payable {
        require(sellInfo[_tokenID].price == msg.value, "ExchangeNFT: price error.");
        require(_NFTPrice == msg.value, "ExchangeNFT: verify price error.");
        address seller = sellInfo[_tokenID].owner;
        address payable receiver = payable(seller);

        _removeNFTfromOwnerEnumeration(seller, _tokenID);

        delete sellInfo[_tokenID];
        sellNum[seller]--;
        NFTContract.safeTransferFrom(address(this), msg.sender, _tokenID);
        receiver.transfer(_NFTPrice);
    }

    function _addNFTtoOwnerEnumeration(address to, uint256 tokenID) private {
        uint256 length = sellNum[to];
        ownedNFT[to][length] = tokenID;
        ownedNFTIndex[tokenID] = length;
    }

    function _removeNFTfromOwnerEnumeration(address from, uint256 tokenID) private {
        uint256 lastIndex = sellNum[from] - 1;
        uint256 nftIndex = ownedNFTIndex[tokenID];

        if (nftIndex != lastIndex) {
            uint256 lastNftID = ownedNFT[from][lastIndex];

            ownedNFT[from][nftIndex] = lastNftID;
            ownedNFTIndex[lastNftID] = nftIndex;
        }

        delete ownedNFTIndex[tokenID];
        delete ownedNFT[from][lastIndex];
    }

    function isOnSale(uint256 _tokenID) public view returns (bool) {
        if(sellInfo[_tokenID].price == 0) return false;
        return true;
    }
}