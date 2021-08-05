/**
 *Submitted for verification at Etherscan.io on 2020-12-22
*/

/** 


█▀▄▀█ █▀█ ▀█▀ █░█ █▀▀ █▀█   █▀█ █▀▀   ▄▀█ █░░ █░░   █▀█ █▀█ █▄░█ ▀█ █ █▀
█░▀░█ █▄█ ░█░ █▀█ ██▄ █▀▄   █▄█ █▀░   █▀█ █▄▄ █▄▄   █▀▀ █▄█ █░▀█ █▄ █ ▄█

info: 𝕀𝕋𝕊 𝕁𝕌𝕊𝕋 𝔸 ℙ𝕆ℕℤ𝕀 𝔹ℝ𝕆


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


contract MOAPSale is Owned {
    using SafeMath for uint256;
    address public tokenAddress;
    bool public saleOpen;
    uint256 tokenRatePerEth = 10500; 
    
    mapping(address => uint256) public usersInvestments;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function startSale() external onlyOwner{
        require(!saleOpen, "Sale is open");
        saleOpen = true;
    }
    
    function setTokenAddress(address tokenContract) external onlyOwner{
        require(tokenAddress == address(0), "Token address already set");
        tokenAddress = tokenContract;
    }
    
    function closeSale() external onlyOwner{
        require(saleOpen, "Sale is closed");
        saleOpen = false;
    }

    receive() external payable{
        require(saleOpen, "Sale is closed");
        require(usersInvestments[msg.sender].add(msg.value) <= 2 ether, "Max allocation is 2 ethereum");
        
        uint256 tokens = getTokenAmount(msg.value);
        
        require(IToken(tokenAddress).transfer(msg.sender, tokens), "Sale may be already filled");
        
        usersInvestments[msg.sender] = usersInvestments[msg.sender].add(msg.value);
        
        // send received funds to the owner
        owner.transfer(msg.value);
    }
    
    function getTokenAmount(uint256 amount) internal view returns(uint256){
        return (amount.mul(tokenRatePerEth)).div(10**2);
    }
    
    function burnUnSoldTokens() external onlyOwner{
        require(!saleOpen, "Sale is closed");
        IToken(tokenAddress).burnTokens(IToken(tokenAddress).balanceOf(address(this)));   
    }
}