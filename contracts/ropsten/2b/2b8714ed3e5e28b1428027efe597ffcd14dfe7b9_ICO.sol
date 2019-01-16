pragma solidity ^0.4.24;


// Only Signatures of few methods used in the ERC20Token contract. 
contract OurToken {
   
   function balanceOf(address tokenOwner) public constant returns (uint balance);
   
   // To release tokens to the address that have send ether.
   function releaseTokens(address _receiver, uint _amount) public;
   
   // To take back tokens after refunding ether.
   function refundTokens(address _receiver, uint _amount) public;

}

contract ICO {
    
   uint public icoStart;
   uint public icoEnd;
   uint public tokenRate;
   OurToken public token;   
   uint public fundingGoal;
   uint public tokensRaised;
   uint public etherRaised;
   address public owner;
   address public extractor;
   
   modifier whenIcoCompleted {
      require(now>icoEnd);
      _;
   }
   
   modifier onlyOwner {
      require(msg.sender == owner);
      _;
   }

   modifier onlyExtractor {
      require(msg.sender == extractor || msg.sender == owner);
      _;
   }
   
   constructor(uint256 _icoStart, uint _icoEnd, uint _tokenRate, address _tokenAddress, uint _fundingGoal, address _extractor) public {
       
      require(_icoStart != 0 &&
      _icoEnd != 0 &&
      _icoStart < _icoEnd &&
      _tokenRate != 0 &&
      _tokenAddress != address(0) &&
      _fundingGoal != 0);
      icoStart = _icoStart;
      icoEnd = _icoEnd;
      tokenRate = _tokenRate;
      token = OurToken(_tokenAddress);
      fundingGoal = _fundingGoal;
      owner = msg.sender;
      extractor = _extractor;
      
   }
   
   function () public payable {
      buy();
   }
   
   function buy() public payable {
       
      require(tokensRaised < fundingGoal);
      require(now < icoEnd && now > icoStart);
      uint tokensToBuy;
      uint etherUsed = msg.value;
      tokensToBuy = (etherUsed/ 1 ether) * tokenRate;
      
      if(tokensRaised + tokensToBuy > fundingGoal) {
         uint exceedingTokens = tokensRaised + tokensToBuy - fundingGoal;
         uint exceedingEther;
         
         exceedingEther = (exceedingTokens * 1 ether) / tokenRate;
         msg.sender.transfer(exceedingEther);
         
         tokensToBuy -= exceedingTokens;
         etherUsed -= exceedingEther;
      }
      
      token.releaseTokens(msg.sender, tokensToBuy);
      
      
      tokensRaised += tokensToBuy;
      etherRaised += etherUsed;
   }
   
   function returnEther() public whenIcoCompleted {
       
       require(tokensRaised < fundingGoal);
       uint balance = token.balanceOf(msg.sender);
       uint etherToBeReturned = (balance / tokenRate) * 1 ether;
       msg.sender.transfer(etherToBeReturned);
       token.refundTokens(msg.sender,balance);
       
   }
   
   function extractEther() public whenIcoCompleted onlyExtractor {
      extractor.transfer(address(this).balance);
   }
   
 }