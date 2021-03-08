/**
 *Submitted for verification at Etherscan.io on 2021-03-08
*/

pragma solidity ^0.8.0;

// Author: 0xKiwi.

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
    function changeName(uint256 tokenId, string memory newName) external;
    function tokenNameByIndex(uint256 index) external view returns (string memory);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract NFTAtomicSwap {
    uint256 public constant NAME_COST = 1830 ether;
    IERC721 public constant WAIFUSION = IERC721(0x2216d47494E516d8206B70FCa8585820eD3C4946);
    IERC20 public constant WET = IERC20(0x76280AF9D18a868a0aF3dcA95b57DDE816c1aaf2);

    address owner;
    
    constructor() {
        owner = msg.sender;
        WET.approve(address(WAIFUSION), 2**255);
    }
    
    function atomicNameTransfer(uint256 inNFT, uint256 outNFT, string memory tempName) external {
        WET.transferFrom(msg.sender, address(this), NAME_COST * 2);
        WAIFUSION.transferFrom(msg.sender, address(this), inNFT);
        WAIFUSION.transferFrom(msg.sender, address(this), outNFT);
        string memory oldName = WAIFUSION.tokenNameByIndex(inNFT);
        WAIFUSION.changeName(inNFT, tempName);
        WAIFUSION.changeName(outNFT, oldName);
        WAIFUSION.transferFrom(address(this), msg.sender, inNFT);
        WAIFUSION.transferFrom(address(this), msg.sender, outNFT);
    }
    
    function atomicNameSwap(uint256 inNFT, uint256 outNFT, string memory tempName) external {
        WET.transferFrom(msg.sender, address(this), NAME_COST * 3);
        WAIFUSION.transferFrom(msg.sender, address(this), inNFT);
        WAIFUSION.transferFrom(msg.sender, address(this), outNFT);
        string memory inOldName = WAIFUSION.tokenNameByIndex(inNFT);
        string memory outOldName = WAIFUSION.tokenNameByIndex(outNFT);
        WAIFUSION.changeName(outNFT, tempName);
        WAIFUSION.changeName(inNFT, outOldName);
        WAIFUSION.changeName(outNFT, inOldName);
        WAIFUSION.transferFrom(address(this), msg.sender, inNFT);
        WAIFUSION.transferFrom(address(this), msg.sender, outNFT);
    }
}