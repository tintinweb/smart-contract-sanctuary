/**
 *Submitted for verification at BscScan.com on 2021-10-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

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
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface GodNft is IERC721Metadata, IERC721Enumerable {
    function mint(address to) external returns (uint256);
}

contract GodexCreate {
    uint256  private _ethfee;
    GodNft   private _godnft;
    
    mapping(address => bool)      private role;
    mapping(uint256 => string[4]) private info;
    
    event GodNftCreate(address indexed user, string name, string image, string desc, string kind, uint256 nftid);
    
	constructor() {
	    _ethfee = 0;
	    role[_msgSender()] = true;
    }
	
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    
    function hasRole(address addr) public view returns (bool) {
        return role[addr];
    }

    function setEthfee(uint256 ethfee) public {
        require(hasRole(_msgSender()), "must have role");
        _ethfee = ethfee;
    }
    
    function setGodNft(address godnft) public {
        require(hasRole(_msgSender()), "must have role");
        _godnft = GodNft(godnft);
    }
    
    function setRole(address addr, bool val) public {
        require(hasRole(_msgSender()), "must have role");
        role[addr] = val;
    }

	function withdrawErc20(address contractAddr, address toAddr, uint256 amount) public {
	    require(hasRole(_msgSender()), "must have role");
        IERC20(contractAddr).transfer(toAddr, amount);
	}
	
	function withdrawETH(address toAddr, uint256 amount) public {
	    require(hasRole(_msgSender()), "must have role");
		payable(toAddr).transfer(amount);
	}
    
    function getNFT(uint256 nftid) public view returns(string[4] memory) {
        return info[nftid];
    }
    
    function create(string memory name, string memory image, string memory desc, string memory kind) public payable
            returns (uint256) {
        require(msg.value >= _ethfee);
        
        uint256 nftid = _godnft.mint(_msgSender());
        
        emit GodNftCreate(_msgSender(), name, image, desc, kind, nftid);
        info[nftid] = [name, image, desc, kind];
        return (nftid);
    }
}