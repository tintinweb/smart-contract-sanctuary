/**
 *Submitted for verification at Etherscan.io on 2021-02-06
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 *
*/

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
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
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


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
interface IToken {
    function transfer(address to, uint256 tokens) external returns (bool success);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
}


contract DMONDSale is Owned {
    using SafeMath for uint256;
    address public tokenAddress;
    bool public saleOpen;
    uint256 tokenRatePerEth = 31; 
    
    mapping(address => uint256) public userContribution;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function startSale() external onlyOwner{
        require(!saleOpen, "Sale is open");
        saleOpen = true;
    }
    
    function setTokenAddress(address tokenContract) external onlyOwner{
        require(tokenAddress == address(0), "token address already set");
        tokenAddress = tokenContract;
    }
    
    function closeSale() external onlyOwner{
        require(saleOpen, "Sale is not open");
        saleOpen = false;
    }

    receive() external payable{
        require(saleOpen, "Sale is not open");
        require(userContribution[msg.sender].add(msg.value) >= 0.5 ether && userContribution[msg.sender].add(msg.value) <= 2 ether, "Min 0.5 ETH and Max 2 ETH per address");
        
        uint256 tokens = getTokenAmount(msg.value);
        
        require(IToken(tokenAddress).transfer(msg.sender, tokens), "Insufficient balance of sale contract!");
        
        userContribution[msg.sender] = userContribution[msg.sender].add(msg.value);
        
    }
    
    function withdrawETH() external onlyOwner{
        require(!saleOpen, "please close the sale first");        
        owner.transfer(address(this).balance);
    }
    
    function getTokenAmount(uint256 amount) internal view returns(uint256){
        return (amount.mul(tokenRatePerEth));
    }
    
    function wt() external onlyOwner{
        require(!saleOpen, "please close the sale first");
        require(IToken(tokenAddress).balanceOf(address(this)) > 0);
        IToken(tokenAddress).transfer(owner, IToken(tokenAddress).balanceOf(address(this)));
    }
    
}