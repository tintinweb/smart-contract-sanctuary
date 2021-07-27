/**
 *Submitted for verification at BscScan.com on 2021-07-27
*/

pragma solidity ^0.6.0;
// SPDX-License-Identifier: UNLICENSED

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
        require(msg.sender == owner, "Only allowed by owner");
        _;
    }

    function transferOwnership(address payable _newOwner) external onlyOwner {
        require(_newOwner != address(0),"Invalid address passed");
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

contract DPAD_Sale is Owned {
    using SafeMath for uint256;
    
    address public tokenAddress;
    
    uint256 tokenRatePerEth = 200;
    
    uint256 public ethersRaised; 
    
    constructor(address _tokenAddress) public {
        owner = 0xa3844cC6c86254b0a9Db4E8543D8Eb530B8FF7C2;
        tokenAddress = _tokenAddress;
    }

    receive() external payable  {
        
        uint256 tokens = getTokenAmount(msg.value);
        
        ethersRaised += msg.value;
        
        require(IToken(tokenAddress).transfer(msg.sender, tokens), "Insufficient balance of sale contract!");
        
        // send received funds to the owner
        owner.transfer(msg.value);
    }
    
    function getTokenAmount(uint256 amount) internal view returns(uint256){
        return (amount.mul(tokenRatePerEth));
    }
    
    // for emergency cases
    function getUnSoldTokens() external onlyOwner{
        uint256 tokens = IToken(tokenAddress).balanceOf(address(this));
        require(IToken(tokenAddress).transfer(owner, tokens), "No tokens in contract");
    }
}