/**
 LIQUIDITY GENERATION EVENT.10,000 Tokens only For LGE.

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
}


contract Distributor is Owned {
    using SafeMath for uint256;
    address public tokenAddress;
    bool public saleOpen;
    uint256 tokenRatePerEth = 10; // 1 ether = 10  tokens approx 35 usd on genesis

    constructor() public {
        owner = msg.sender;
    }
    
    function setTokenAddress(address _tokenAddress) external onlyOwner{
        require(tokenAddress == address(0), "address already set");
        tokenAddress = _tokenAddress;
    }
    
    function startSale() external onlyOwner{
        require(!saleOpen, "Distribution is already open");
        saleOpen = true;
    }
    
    function closeSale() external onlyOwner{
        require(saleOpen, "Distribution is not open");
        saleOpen = false;
    }

    receive() external payable{
        
        require(saleOpen, "Distribution is not open");
        require(msg.value >= 0.1 ether, "Min investment allowed is 0.1 ether");
        
        uint256 tokens = getTokenAmount(msg.value);
        
        require(IToken(tokenAddress).transfer(msg.sender, tokens), "Insufficient balance of Distributor contract!");
        
        // send received funds to the owner
        owner.transfer(msg.value);
    }
    
    function getTokenAmount(uint256 amount) internal view returns(uint256){
        return amount.mul(tokenRatePerEth);
    }
    
    function setTokenRate(uint256 ratePerEth) external onlyOwner{
        require(!saleOpen, "Distribution is open, cannot change now");
        tokenRatePerEth = ratePerEth;
    }

}