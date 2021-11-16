/**
 *Submitted for verification at BscScan.com on 2021-11-16
*/

pragma solidity ^0.8.7;

// SPDX-License-Identifier: UNLICENSED

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
} 

pragma solidity ^0.8.7;

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.7;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract SatoshiDiskCloneTest is Context, Ownable {
    
    IERC20 USDT = IERC20(0x337610d27c682E347C9cD60BD4b3b107C9d34dDd);
    
    struct FileInfo {
        string fileName;
        string fileHash;
        uint256 price;
    }
    
    mapping(address => FileInfo[]) private orderbook;
    
    string private adminEmail;
    uint256 private adminFee;
    
    constructor(string memory email, uint256 fee) {
        adminEmail = email;
        adminFee = fee;
    }
    
    function getFileInfos(address seller) public view returns (FileInfo[] memory) {
        return orderbook[seller];
    }
    
    function getFileInfo(address seller, uint index) public view returns (FileInfo memory) {
        return orderbook[seller][index];
    }
    
    function getFileName(address seller, uint index) public view returns (string memory) {
        return orderbook[seller][index].fileName;
    }
    
    function getFileHash(address seller, uint index) public view returns (string memory) {
        return orderbook[seller][index].fileHash;
    }
    
    function getPrice(address seller, uint index) public view returns (uint256) {
        return orderbook[seller][index].price;
    }
    
    function setAdminEmail(string memory email) external onlyOwner() {
        adminEmail = email;
    }
    
    function setAdminFee(uint256 fee) external onlyOwner() {
        adminFee = fee;
    }
    
    function sellFile(string memory fName, string memory fHash, uint256 fPrice) external {
        orderbook[_msgSender()].push(FileInfo(fName, fHash, fPrice));
    }
    
    function updateFile(uint index, string memory fName, string memory fHash, uint256 fPrice) external {
        orderbook[_msgSender()][index] = (FileInfo(fName, fHash, fPrice));
    }
    
    function approveAmount(address seller, uint index) public { 
        uint256 amountToPay = orderbook[seller][index].price;
        USDT.approve(address(this), amountToPay);
    }
    
    function buyFile(address seller, uint index) payable public {
        uint256 amountToPay = orderbook[seller][index].price;
        
        require(USDT.allowance(_msgSender(), address(this)) >= amountToPay, "Insuficient Allowance");
        require(USDT.transferFrom(_msgSender(), address(this), amountToPay),"Transfer Failed");
        
        // Fees
        uint256 feeForAdmin = amountToPay * adminFee;
        uint256 sellerRevenue = amountToPay - feeForAdmin;
        USDT.transfer(owner(), feeForAdmin);
        USDT.transfer(_msgSender(), sellerRevenue);
        delete orderbook[seller][index];
    }
        
}