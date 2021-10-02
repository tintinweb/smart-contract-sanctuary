/**
 *Submitted for verification at BscScan.com on 2021-10-02
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
    function safeTransferFrom(address from,address to,uint256 tokenId) external;
    function transferFrom(address from,address to,uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from,address to,uint256 tokenId,bytes calldata data) external;
}

interface OneNft is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
    
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
    
    function mint(address to) external;
}

contract OneBuy {
    address private _owner;
    address private usdtContract;
    address private nftContract;
    address private receiveAddr;
    uint256 private usdtAmount;
    
	constructor() {
	    _owner = msg.sender;
	    
	    usdtContract = 0x54383c0008E0C1180a39763b2bd6d91df91Ec1D7;
	    nftContract = 0xCcDC529dc2B43613c8f7071C0694d37Fb1712bc5;
	    receiveAddr = 0xDC909e5Ca6bc3ED09d3164DaA55Ef26e9fd46D26;
	    usdtAmount = 500 * 10 ** 18;
    }
	
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    
	modifier onlyOwner() {
        require(_owner == _msgSender());
        _;
    }
    
    function transferOwner(address newOwner) public onlyOwner {
        _owner = newOwner;
    }
    
	function withdrawErc20(address contractAddr, uint256 amount) onlyOwner public {
        IERC20(contractAddr).transfer(_owner, amount);
	}
	
	function withdrawETH(uint256 amount) onlyOwner public {
		payable(_owner).transfer(amount);
	}

    function buyByErc20() public {
        IERC20(usdtContract).transferFrom(_msgSender(), receiveAddr, usdtAmount);
        
        OneNft(nftContract).mint(_msgSender());
    }
    
    function getMyConfig(address addr) public view returns (address[] memory, uint256[] memory) {
        address[] memory addrs = new address[](3);
        
        addrs[0] = _owner;
        addrs[1] = usdtContract;
        addrs[2] = nftContract;
        
        // usdtBalance usdtAllowance usdtDecimals NftBalance every...
        uint256 nftBalances = OneNft(nftContract).balanceOf(addr);
        
        uint256[] memory nums = new uint256[](4 + nftBalances);
        nums[0] = IERC20(usdtContract).balanceOf(addr);
        nums[1] = IERC20(usdtContract).allowance(addr, address(this));
        nums[2] = 18;
        
        nums[3] = nftBalances;
        for (uint256 i=0; i<nftBalances; i++) {
            nums[4 + i] = OneNft(nftContract).tokenOfOwnerByIndex(addr, i);
        }
        return (addrs, nums);
    }
    
}