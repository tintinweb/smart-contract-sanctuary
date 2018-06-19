pragma solidity ^0.4.23; 
/*
Author: Vox / 0xPool.io
Description: This smart contract is designed to store mining pool payouts for 
  Ethereum Protocol tokens and allow pool miners to withdraw their earned tokens
  whenever they please. There are several benefits to using a smart contract to
  track mining pool payouts:
    - Increased transparency on behalf of pool owners
    - Allows users more control over the regularity of their mining payouts
    - The pool admin does not need to pay the gas costs of hundreds of 
      micro-transactions every time a block reward is found by the pool.

This contract is the 0xBTC (0xBitcoin) payout account for: http://0xpool.io 

Not heard of 0xBitcoin? Head over to http://0xbitcoin.org

May the Qat be with you. 
*/

contract ERC20Interface {

    function totalSupply() public constant returns (uint);

    function balanceOf(address tokenOwner) public constant returns (uint balance);

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);

    function transfer(address to, uint tokens) public returns (bool success);

    function approve(address spender, uint tokens) public returns (bool success);

    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}


contract _ERC20Pool {
    
  using SafeMath for uint64;

  // 0xB6eD7644C69416d67B522e20bC294A9a9B405B31 is the 0xBitcoin Smart Contract
  ERC20Interface public tokenContract = ERC20Interface(0xB6eD7644C69416d67B522e20bC294A9a9B405B31);
  
  // 0x53CE57325C126145dE454719b4931600a0BD6Fc4 is the wallet for 0xpool.io
  address public owner = 0x53CE57325C126145dE454719b4931600a0BD6Fc4;
  
  uint64 public totalTokenSupply;
  mapping (address => uint64) public minerTokens;
  mapping (address => uint64) public minerTokenPayouts;

  // Modifier for important owner only functions
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  // Require that the caller actually has tokens to withdraw.
  modifier hasTokens() {
    require(minerTokens[msg.sender] > 0);
    _;
  }

  // Pool software updates the contract when it finds a reward
  function addMinerTokens(uint64 totalTokensInBatch, address[] minerAddress, uint64[] minerRewardTokens) public onlyOwner {
    totalTokenSupply += totalTokensInBatch;
    for (uint i = 0; i < minerAddress.length; i ++) {
      minerTokens[minerAddress[i]] = minerTokens[minerAddress[i]].add(minerRewardTokens[i]);
    }
  }
  
  // Allow miners to withdraw their earnings from the contract. Update internal accounting.
  function withdraw() public
    hasTokens
  {
    uint64 amount = minerTokens[msg.sender];
    minerTokens[msg.sender] = 0;
    totalTokenSupply = totalTokenSupply.sub(amount);
    minerTokenPayouts[msg.sender] = minerTokenPayouts[msg.sender].add(amount);
    tokenContract.transfer(msg.sender, amount);
  }
  
  // Fallback function, It&#39;s kind of you to send Ether, but we prefer to handle the true currency of
  // Ethereum here, 0xBitcoin!
  function () public payable {
    revert();
  }
  
  // Allow the owner to retrieve accidentally sent Ethereum
  function withdrawEther(uint64 amount) public onlyOwner {
    owner.transfer(amount);
  }
  
  // Allows the owner to transfer any accidentally sent ERC20 Tokens, excluding 0xBitcoin.
  function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
    if(tokenAddress == 0xB6eD7644C69416d67B522e20bC294A9a9B405B31 ){ 
        revert(); 
    }
    return ERC20Interface(tokenAddress).transfer(owner, tokens);
  }
  
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
     function mul(uint64 a, uint64 b) internal pure returns (uint64) {
     if (a == 0) {
     return 0;
     }
     uint64 c = a * b;
     assert(c / a == b);
     return c;
     }
    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
     function div(uint64 a, uint64 b) internal pure returns (uint64) {
     // assert(b > 0); // Solidity automatically throws when dividing by 0
     uint64 c = a / b;
     // assert(a == b * c + a % b); // There is no case in which this doesn’t hold
     return c;
     }
    /**
     * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
     function sub(uint64 a, uint64 b) internal pure returns (uint64) {
     assert(b <= a);
     uint64 c = a - b;
     return c;
     }
    /**
     * @dev Adds two numbers, throws on overflow.
     */
     function add(uint64 a, uint64 b) internal pure returns (uint64) {
     uint64 c = a + b;
     assert(c >= a);
     return c;
     }
}