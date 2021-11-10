/**
 *Submitted for verification at Etherscan.io on 2021-11-10
*/

pragma solidity 0.8.6;

// "SPDX-License-Identifier: MIT"

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) { c = a + b; require(c >= a); }
    function sub(uint a, uint b) internal pure returns (uint c) { require(b <= a); c = a - b; }
    function mul(uint a, uint b) internal pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); }
    function div(uint a, uint b) internal pure returns (uint c) { require(b > 0); c = a / b; }
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address transferOwner) public onlyOwner {
        require(transferOwner != newOwner);
        newOwner = transferOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


abstract contract ERC721Interface {
  function approve(address to, uint256 tokenId) public virtual;
  function safeTransferFrom(address from, address to, uint256 tokenId) public virtual;
}

abstract contract ERC20Interface {
    function approve(address spender, uint tokens) public virtual;
    function transfer(address to, uint tokens) public virtual;
    function transferFrom(address from, address to, uint tokens) public virtual;
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

contract directSale20 is IERC721Receiver, Owned {
    using SafeMath for uint; 
    
    uint256 public sellId;
    uint256 public fee;
    uint256 public feeDenominator;
    address public feeAddr;
    address public contract20Address;
    
    constructor() {
        fee = 3; // 0.3%
        feeDenominator = 1000;
        feeAddr == 0x888888883ca397245A59bEEAb3A1028c55BF39C4;
        contract20Address = 0xBB5a005766C4E5A39a140f2a0AA95af9e0AA11DC;
    }
    
    mapping (uint256 => Sales) sale;
    
    struct Sales {
        address seller;
        address buyer;
        address contr;
        uint256 tokenId;
        uint256 price;
        bool    active;
    }
    
    event Sell(uint256 sellId, address contractAddress, uint256 tokenId, uint256 price);
    event Cancel(uint256 sellId);
    event Buy(uint256 sellId, uint256 price, address buyer);
    
    function sellInfo(uint256 Id) public view returns (address seller, address buyer, address contractAddress, uint256 tokenId, uint256 price, bool active) {
        return (sale[Id].seller, sale[Id].buyer, sale[Id].contr, sale[Id].tokenId, sale[Id].price, sale[Id].active);
    }
    
    function sell(address contractAddress, uint256 tokenId, address from, uint256 amount) public returns (uint256 Id) { 
        ERC721Interface(contractAddress).safeTransferFrom(from, address(this), tokenId);
        require(amount != 0, 'PRICE IS ZERO');
        require(amount >= 1 * 10**18, 'PRICE >= 1 token');
        sale[sellId].seller = msg.sender;
        sale[sellId].buyer = address(0);
        sale[sellId].contr = contractAddress;
        sale[sellId].tokenId = tokenId;
        sale[sellId].price = amount;
        sale[sellId].active = true;
        emit Sell(sellId, contractAddress, tokenId, amount);
        sellId = sellId.add(1);
        return sellId.sub(1);
    }
    
    function cancel(uint256 Id) public {
        require(sale[Id].seller == msg.sender, "YOU ARE NOT A SELLER");
        require(sale[Id].active == true, "SELL IS NOT ACTIVE");
        ERC721Interface(sale[Id].contr).safeTransferFrom(address(this), msg.sender, sale[Id].tokenId);
        sale[Id].active = false;
        emit Cancel(Id);
    }
    
    function buy(uint256 Id) public {
        require(sale[Id].active, "SELL IS NOT ACTIVE");
        pay(sale[sellId].seller, sale[Id].price);
        ERC20Interface(contract20Address).transfer(msg.sender, sale[Id].price);
        ERC721Interface(sale[Id].contr).safeTransferFrom(address(this), msg.sender, sale[Id].tokenId);
        sale[Id].active = false;
        emit Buy(Id, sale[Id].price, msg.sender);
    }
    
    function pay(address seller, uint256 amount) internal {
        ERC20Interface(contract20Address).transfer(seller, amount.div(feeDenominator).mul(uint256(feeDenominator).sub(fee)));
        ERC20Interface(contract20Address).transfer(seller, amount.div(feeDenominator).mul(fee));
    }
    
    function changeFee(uint _fee) public onlyOwner {
        require(_fee <= 10); // 1%
        fee = _fee;
    }
    
    function changeFeeAddr(address _feeAddr) public onlyOwner {
        feeAddr = _feeAddr;
    }
    
    function change20Addr(address _contract20Address) public onlyOwner {
        contract20Address = _contract20Address;
    }
        
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}