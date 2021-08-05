/**
 *Submitted for verification at Etherscan.io on 2020-11-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.3;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {

    address private owner;
    
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    function changeOwner(address newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}

interface Token {
    function tokensSold(address buyer, uint256 amount) external  returns (bool success);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function burn(uint256 _value) external returns (bool success);
}

contract CPTCrowdSale is Ownable{
    
    using SafeMath for uint256;
    
    uint256 public rate;
    uint256 public totalSold;
    address public tokenAddress;

    uint256 internal constant START = 1606154146;
    uint256 internal constant DAYS = 100; 
    
    uint256 public minimumBuyAmount = 10 ** 17;
    address payable public walletAddress;
    event TokensSold(address indexed to, uint256 amount);

    function isActive() internal view returns (bool) {
        return (
            block.timestamp >= START && 
            block.timestamp <= START.add(DAYS * 1 days)
        );
    }
    
    modifier IsSaleActive() {
        assert(isActive());
        _;
    }

    constructor() {
        rate = uint256(20);
        walletAddress = 0x44b3E70145D13a946f9edCFcadBc013864Db8A3f;
        tokenAddress = address(0x0);
    }
    
    receive() external payable {
        buy();
    }
    
    function changeWallet (address payable _walletAddress) onlyOwner public {
        walletAddress = _walletAddress;
    }
    
    function setToken(address _tokenAddress) onlyOwner public {
        tokenAddress = _tokenAddress;
    }
    
    function buy() public payable IsSaleActive{
        uint256 weiValue = msg.value;
        require(weiValue >= minimumBuyAmount);
        uint256 amount = weiValue.mul(rate);
        Token token = Token(tokenAddress);
        require(walletAddress.send(weiValue));
        require(token.tokensSold(msg.sender, amount));
        totalSold += amount;
        emit TokensSold(msg.sender, amount);
    }
    
    function burnUnsold() onlyOwner public {
        Token token = Token(tokenAddress);
        uint256 amount = token.balanceOf(address(this));
        token.burn(amount);
    }
    
}