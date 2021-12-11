/**
 *Submitted for verification at BscScan.com on 2021-12-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function ceil(uint a, uint m) internal pure returns (uint r) {
    return (a + m - 1) / m * m;
  }
}

contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}


interface IToken {
    function transfer(address to, uint256 tokens) external returns (bool success);
    function burnTokens(uint256 _amount) external;
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
}


contract PreSale is Owned {
    using SafeMath for uint256;
    
    bool public isPresaleOpen;
    
    address public tokenAddress;
    uint256 public tokenDecimals = 18;
    
    uint256 public tokenRatePerEth = 70_00;
    uint256 public rateDecimals = 2;
    
    uint256 public minEthLimit = 100 finney;
    uint256 public maxEthLimit = 2 ether;
    
    mapping(address => uint256) public usersInvestments;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function startPresale() external onlyOwner{
        require(!isPresaleOpen, "Presale is open");
        
        isPresaleOpen = true;
    }
    
    function closePrsale() external onlyOwner{
        require(isPresaleOpen, "Presale is not open yet.");
        
        isPresaleOpen = false;
    }
    
    function setTokenAddress(address token) external onlyOwner {
        require(tokenAddress == address(0), "Token address is already set.");
        require(token != address(0), "Token address zero not allowed.");
        
        tokenAddress = token;
    }
    
    function setTokenDecimals(uint256 decimals) external onlyOwner {
       tokenDecimals = decimals;
    }
    
    function setMinEthLimit(uint256 amount) external onlyOwner {
        minEthLimit = amount;    
    }
    
    function setMaxEthLimit(uint256 amount) external onlyOwner {
        maxEthLimit = amount;    
    }
    
    function setTokenRatePerEth(uint256 rate) external onlyOwner {
        tokenRatePerEth = rate;
    }
    
    function setRateDecimals(uint256 decimals) external onlyOwner {
        rateDecimals = decimals;
    }
    
    receive() external payable{
        require(isPresaleOpen, "Presale is not open.");
        require(
                usersInvestments[msg.sender].add(msg.value) <= maxEthLimit
                && usersInvestments[msg.sender].add(msg.value) >= minEthLimit,
                "Installment Invalid."
            );
        
        uint256 tokenAmount = getTokensPerEth(msg.value);
        
        require(IToken(tokenAddress).transfer(msg.sender, tokenAmount), "Insufficient balance of presale contract!");
        
        usersInvestments[msg.sender] = usersInvestments[msg.sender].add(msg.value);
        
        owner.transfer(msg.value);
    }
    
    function getTokensPerEth(uint256 amount) internal view returns(uint256) {
        return amount.mul(tokenRatePerEth).div(
            10**(uint256(18).sub(tokenDecimals).add(rateDecimals))
            );
    }
    
    function burnUnsoldTokens() external onlyOwner {
        require(!isPresaleOpen, "You cannot burn tokens until the presale is closed.");
        
        IToken(tokenAddress).burnTokens(IToken(tokenAddress).balanceOf(address(this)));   
    }
    
    function getUnsoldTokens() external onlyOwner {
        require(!isPresaleOpen, "You cannot get tokens until the presale is closed.");
        
        IToken(tokenAddress).transfer(owner, IToken(tokenAddress).balanceOf(address(this)) );
    }
}