// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import './PussyRocket.sol';

contract Crowdsale {
   
    PussyRocket public constant token = PussyRocket(0x930932C5318d4CEA2AaEe4B614b26911D2F6a0Cd);
   
    uint256 public constant icoStartTime    = 1632737745;
    uint256 public constant icoEndTime      = 1632738645;
    uint256 public constant fundingGoal     = 58e27;
   
    uint256 public constant rateTierOne     = 45e24;    // 80% discount
    uint256 public constant rateTierTwo     = 22.5e24;  // 60% discount
    uint256 public constant rateTierThree   = 15e24;    // 40% discount
    uint256 public constant rateTierFour    = 11.25e24; // 20% discount
       
    uint256 public constant limitTierOne    = 14.5e27;  // Each tier is 25% of total funding goal
    uint256 public constant limitTierTwo    = 14.5e27;
    uint256 public constant limitTierThree  = 14.5e27;
    uint256 public constant limitTierFour   = 14.5e27;
   
    address public contractOwner;
    uint256 public tokensRaised;
    uint256 public etherRaised;
   
    bool public icoCompleted = false;

    modifier whenIcoCompleted {
        require(icoCompleted);
        _;
    }

    modifier onlyOwner {
        require(msg.sender == contractOwner);
        _;
    }

    constructor() public {
        contractOwner = msg.sender;
    }
   
    function tokenAmountRaised() public view returns (uint256) {
        return tokensRaised;
    }
    
    function etherAmountRaised() public view returns (uint256) {
        return etherRaised;
    }

    function purchaseTokens() public payable {
        require(!icoCompleted);
        require(icoStartTime < block.timestamp);
    
        uint256 tokensToReiceive;
        uint256 etherUsed = msg.value;
    
        // If the tokens raised are less than 25 million with decimals, apply the first rate
        if(tokensRaised < limitTierOne) {
           // Tier 1
            tokensToReiceive = etherUsed * rateTierOne;
        } else if(tokensRaised >= limitTierOne && tokensRaised < limitTierTwo) {
           // Tier 2
            tokensToReiceive = etherUsed * (10 ** token.decimals()) / 1 ether * rateTierTwo;
        } else if(tokensRaised >= limitTierTwo && tokensRaised < limitTierThree) {
            // Tier 3
            tokensToReiceive = etherUsed * (10 ** token.decimals()) / 1 ether * rateTierThree;
        } else if(tokensRaised >= limitTierThree) {
            // Tier 4
            tokensToReiceive = etherUsed * (10 ** token.decimals()) / 1 ether * rateTierFour;
        }
    
        // Check if we have reached and exceeded the funding goal to refund the exceeding tokens and ether
        if(tokensRaised + tokensToReiceive > fundingGoal) {
            uint256 exceedingTokens = tokensRaised + tokensToReiceive - fundingGoal;
            uint256 exceedingEther;
        
            // Convert the exceedingTokens to ether and refund that ether
            exceedingEther = exceedingTokens * 1 ether / rateTierFour / token.decimals();
            payable(msg.sender).transfer(exceedingEther);
        
            tokensToReiceive -= exceedingTokens;
            etherUsed -= exceedingEther;
        }
    
        token.distributeICOTokens(msg.sender, tokensToReiceive);
    
        tokensRaised += tokensToReiceive;
        etherRaised += etherUsed;
       
        checkCompletedCrowdsale();
    }
   
    function checkCompletedCrowdsale() internal {
        require(!icoCompleted);
        require(tokensRaised >= fundingGoal  || block.timestamp >= icoEndTime);
        icoCompleted = true;
        token.burn();
    }
    
    fallback () external payable {
        purchaseTokens();
    }
    
    function extractEther() public onlyOwner {
        payable(contractOwner).transfer(address(this).balance);
    }
}