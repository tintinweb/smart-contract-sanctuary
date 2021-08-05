/**
 *Submitted for verification at Etherscan.io on 2020-11-23
*/

pragma solidity ^0.6.0;

// SPDX-License-Identifier: UNLICENSED

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

// Owned contract

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


// ERC20 Token Interface

interface IToken {
    function transfer(address to, uint256 tokens) external returns (bool success);
    function burnTokens(uint256 _amount) external;
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
}


contract LIDOSale is Owned {
    using SafeMath for uint256;
    address public tokenAddress;
    bool public saleOpen;
    uint256 tokenRatePerEth = 5000;
    
    mapping(address => uint256) public usersInvestments;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function startLIDOSale() external onlyOwner{
        require(!saleOpen, "LIDO sale is already open");
        saleOpen = true;
    }
    
    function setTokenAddress(address tokenContract) external onlyOwner{
        require(tokenAddress == address(0), "Address is already set");
        tokenAddress = tokenContract;
    }
    
    function closeLIDOSale() external onlyOwner{
        require(saleOpen, "LIDO sale is closed");
        saleOpen = false;
    }

    receive() external payable{
        require(saleOpen, "LIDO sale is not open");
        require(usersInvestments[msg.sender].add(msg.value) <= 5 ether, "Maximum investment allowed: 5 ETH");
        uint256 tokens = getTokenAmount(msg.value);
        require(IToken(tokenAddress).transfer(msg.sender, tokens), "Insufficient balance of the sale Contract");
        usersInvestments[msg.sender] = usersInvestments[msg.sender].add(msg.value);
        
        owner.transfer(msg.value);
    }
    
    function getTokenAmount(uint256 amount) internal view returns(uint256){
        return (amount.mul(tokenRatePerEth)).div(10**0);
    }
    
    function burnUnsoldLIDOTokens() external onlyOwner{
        require(!saleOpen, "Please close the sale first");
        IToken(tokenAddress).burnTokens(IToken(tokenAddress).balanceOf(address(this)));   
    }
}