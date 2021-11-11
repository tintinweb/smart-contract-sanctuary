// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './PussyRocket.sol';

contract Crowdsale {
   
    PussyRocket public constant token = PussyRocket(0x263CE9eA0dC46c9A12F3F624396eEe896c270b60);
   
    uint256 public constant icoEndTime      = 1640008800;
    uint256 public constant fundingGoal     = 58e27;
   
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
    
    
    receive() external payable { 
        purchaseTokens(msg.value);
        
    }
    
    function time() public view returns (uint256) {
        return block.timestamp;
    }

    function purchaseTokens(uint256 etherUsedWei) public payable {
    assert(1 ether == 1e18);
        require(!icoCompleted);
        require(block.timestamp < icoEndTime);
    
        uint256 tokensToReiceive;
        
        
        if(tokensRaised < 14.5e27) { // Each tier is 25% of total funding goal
          // Tier 1
            tokensToReiceive = 45e6 * etherUsedWei; // 80% discount
        } else if(tokensRaised <  29e27) {
          // Tier 2
            tokensToReiceive = 22.5e6 * etherUsedWei; // 60% discount
        } else if(tokensRaised < 43.5e27) {
            // Tier 3
            tokensToReiceive = 15e6 * etherUsedWei; // 40% discount
        } else{
            // Tier 4
            tokensToReiceive = 11.25e6 * etherUsedWei; // 20% discount
        }
    
        token.distribute(msg.sender, tokensToReiceive);
        tokensRaised += tokensToReiceive;
        etherRaised += etherUsedWei;
        
        if(tokensRaised >= fundingGoal) {
            icoCompleted = true;
        }
       
    }
   
    function finalizeCrowdsale() public onlyOwner {
        require(!icoCompleted);
        require(icoEndTime < block.timestamp);
        token.burn();
        icoCompleted = true;
    }
    
    function extractEther() public onlyOwner {
        payable(contractOwner).transfer(address(this).balance);
    }
}