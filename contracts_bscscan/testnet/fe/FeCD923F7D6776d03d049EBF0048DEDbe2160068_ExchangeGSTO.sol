/**
 *Submitted for verification at BscScan.com on 2021-10-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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

contract ExchangeGSTO is IERC721Receiver, Ownable {
    struct Info {
        uint256 price;
        address owner;
    }
    mapping (uint256 => Info) public sellInfo;
    IERC721Enumerable public immutable NFTContract;
    IERC20 public immutable targetToken;
    address public receiver;
    mapping(address => mapping(uint256 => uint256)) public ownedNFT;
    mapping(uint256 => uint256) public ownedNFTIndex;
    mapping(address => uint256) public sellNum;

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'ExchangeGSTO: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor(IERC721Enumerable _NFTContract, IERC20 _targetToken) {
        NFTContract = _NFTContract;
        targetToken = _targetToken;
        receiver = msg.sender;
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function sellNFT(uint256 _tokenID, uint256 _NFTPrice) public {
        require(_NFTPrice > 0, "ExchangeGSTO: NFT price must be positive.");
        NFTContract.safeTransferFrom(msg.sender, address(this), _tokenID);

        _addNFTtoOwnerEnumeration(msg.sender, _tokenID);

        sellInfo[_tokenID].price = _NFTPrice;
        sellInfo[_tokenID].owner = msg.sender;
        sellNum[msg.sender]++;
    }

    function cancelDeal(uint256 _tokenID) lock public {
        require(sellInfo[_tokenID].owner == msg.sender, "ExchangeGSTO: no authority.");
        NFTContract.safeTransferFrom(address(this), msg.sender, _tokenID);
        
        _removeNFTfromOwnerEnumeration(msg.sender, _tokenID);
        
        delete sellInfo[_tokenID];
        sellNum[msg.sender]--;
    }

    function buyNFT(uint256 _tokenID, uint256 _NFTPrice) lock public {
        require(sellInfo[_tokenID].price == _NFTPrice, "ExchangeGSTO: price error.");
        address seller = sellInfo[_tokenID].owner;

        _removeNFTfromOwnerEnumeration(seller, _tokenID);

        delete sellInfo[_tokenID];
        sellNum[seller]--;
        NFTContract.safeTransferFrom(address(this), msg.sender, _tokenID);
        uint256 fee = _NFTPrice * 3 / 100;
        targetToken.transferFrom(msg.sender, receiver, fee);
        targetToken.transferFrom(msg.sender, seller, _NFTPrice - fee);
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

    function changeReceiver(address _receiver) public onlyOwner() {
        receiver = _receiver;
    }
}