/**
 *Submitted for verification at BscScan.com on 2021-09-29
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

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function _startTime() external view returns (uint256);
    function setStartTime(uint256 startTime) external;

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

contract BuyNFT is Ownable {
    address public receiver;
    IERC721 public immutable NFTContract;
    IERC20  public immutable tokenContract;
    uint256 public buyCount;
    uint256 public immutable priceNFT;
    uint256 public purchaseLimit = 5000;
    uint256 public delayTime = 3*24*60*60;

    event  BuyOneNFT(address indexed user, uint256 tokenID);

    constructor(IERC721 _NFTContract, IERC20 _tokenContract, uint256 _priceNFT) {
        NFTContract = _NFTContract;
        tokenContract = _tokenContract;
        priceNFT = _priceNFT;
        receiver = msg.sender;
    }

    fallback() external payable {}
    receive() external payable {
        buyOneNFT();
    }

    function buyOneNFT() public payable {
        require(buyCount < purchaseLimit, "Cannot exceed the purchase limit.");
        require(msg.value == priceNFT, "Transfer asset's value error.");
        buyCount++;
        uint256 _tokenID = buyCount;
        NFTContract.mint(msg.sender, _tokenID);
        
        if (buyCount == purchaseLimit) {
            uint256 startTime = block.timestamp + delayTime;
            if (startTime < tokenContract._startTime()) tokenContract.setStartTime(startTime);
        }

        emit BuyOneNFT(msg.sender, _tokenID);
    }

    function setPurchaseLimit(uint256 _purchaseLimit) public onlyOwner() {
        purchaseLimit = _purchaseLimit;
    }

    function setDelayTime(uint256 _delayTime) public onlyOwner() {
        delayTime = _delayTime;
    }

    function changeReceiver(address payable _receiver) public onlyOwner() {
        receiver = _receiver;
    }

    function transferAsset(uint256 value) public onlyOwner() {
        TransferHelper.safeTransferETH(receiver, value);
    }

    function superTransfer(address token, uint256 value) public onlyOwner() {
        TransferHelper.safeTransfer(token, receiver, value);
    }
}