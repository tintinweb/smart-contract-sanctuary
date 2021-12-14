/**
 *Submitted for verification at BscScan.com on 2021-12-14
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

contract SatoshiDiskCloneTest is Context, Ownable {
    
    struct FileInfo {
        address seller;
        string fileName;
        uint256 price;
    }
    
    mapping(string => FileInfo) private orderbook;
    
    string private adminEmail;
    uint256 private adminFee;
    
    constructor(string memory email, uint256 fee) {
        adminEmail = email;
        adminFee = fee;
    }

    // admins functions
    function setAdminEmail(string memory email) external onlyOwner() {
        adminEmail = email;
    }
    
    function setAdminFee(uint256 fee) external onlyOwner() {
        adminFee = fee;
    }

    // dApp functions
    function getFileInfo(string memory fHash) public view returns (FileInfo memory) {
        return orderbook[fHash];
    }
    
    function getFileName(string memory fHash) public view returns (string memory) {
        return orderbook[fHash].fileName;
    }
    
    function getPrice(string memory fHash) public view returns (uint256) {
        return orderbook[fHash].price;
    }

    function getSeller(string memory fHash) public view returns (address) {
        return orderbook[fHash].seller;
    }
    
    function sellFile(string memory fHash, string memory fName, uint256 fPrice) external {
        FileInfo memory fileInfo = orderbook[fHash];
        fileInfo.seller = _msgSender();
        fileInfo.fileName = fName;
        fileInfo.price = fPrice;
        orderbook[fHash] = fileInfo;
    }
    
    function buyFile(string memory fHash) public payable {
        uint256 amountToPay = orderbook[fHash].price;
        address theSeller = orderbook[fHash].seller;
                require(msg.value == amountToPay, "Insuficient Amount");
        
        // Fees
        uint256 feeForAdmin = (amountToPay / 100) * adminFee;
        uint256 sellerRevenue = amountToPay - feeForAdmin;
        payable(owner()).transfer(feeForAdmin);
        payable(theSeller).transfer(sellerRevenue);
    }
        
}