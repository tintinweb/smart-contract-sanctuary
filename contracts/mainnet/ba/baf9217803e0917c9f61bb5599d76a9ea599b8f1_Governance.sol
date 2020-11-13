// GG-GOV-TITLE: Initial Launch of Giving Governance
/* BEGIN-GG-GOV-DESC  
Proposal:
1. Launch Giving Governance Contract
2. Launch First Pool GiveWell


Description:
Giving Governance aims to redirect some of the excess exuberance in the DeFi sphere into effective giving.
Building off Andre's amazing yyCRV auto-earning ecosystem, and leveraging Uniswap, the contract channels all returns as ETH to GiveWell's donation address. 
The contract considers the initial yCRV you deposit which is wrapped in yyCRV, and returns you the same number of yCRV in yyCRV. 
The contract has a function whereby anyone can call swapDonatedYYCRVForETH, donating gas, and sends the ETH to the designated address.
Withdrawals get hit with a 0.5% fee, all going to charity - this is purely to stop people from gaming the system.
The Giving Goverance token GG has no value, and is used purely for voting new charity addresses in, and acting as a focal point for building a altruistic community to share our GaInZ.
Goverannce discussions will occur on forum.giving.finance, and it is envisioned that every new charity added will have its own pool so that users can choose where to donate their earnings.

Given the initial quorum of 25%, governance will only start from week 1 onwards. Governance can be queued after getting 50% of quorum, then executed after 1 day.
All Governance Proposals are contracts, and should follow this template.
Governance requires 1% of tokens to be proposed. Be careful, once submitted, all your tokens are locked. 
If you vote, all your tokens are locked too. Tokens are released once new governance is executed.


executeGovernanceActions():
None


END-GG-GOV-DESC */ 

pragma solidity ^0.6.0;

contract Governance {
    using SafeMath for uint;

    // Governance Parameters
    
    uint public governanceExpiry      = 7 days;    // Duration for which governance votes can be collected
    uint public governanceSwitchDelay = 1 days;    // Duration before next governance module can be loaded
    uint public voteQuorum            = 25;        // Quorum to approve new governance
    uint public votePass              = 50;        // Percentage required to approve new governance
    uint public minGovToken           = 1;         // Percentage tokens required to create new proposal 
    uint public voteDecimal           = 100;       // Divisor for voteQuorum and votePass
    
    // Address Management
    address public previousGovernance;    // Address of previous governance - a linked list leading back to the genesis
    address public GovernanceTokenAddress = 0x3DA1095F0b571f00B4D9A4B2A78AD8D13416886b;    // GovernanceTokenAddress
    
    function executeGovernanceActions() public {                // Function executed by the predecessor Governance Contract when handing over
        require(msg.sender == previousGovernance, "!PrevGov");  // Governance actions can be executed here, such as mint GG, revoke GG, etc
    }

    // Standard Governance Functions and Parameters

    address public nextGovernance;            // Next governance module
    uint    public nextGovernanceExecution;   // Timestamp before governance module is executed
    address [] public proposedGovernanceList; // List of proposed governance modules
    bool    public GovernanceSwitchExecuted;  // Governance Changed. 
    
    // Voting Storage
    mapping (address => mapping (address => uint)) public voteYes;  // Yes votes collected 
    mapping (address => mapping (address => uint)) public voteNo;   // No votes collected

    mapping (address => uint) public voteYesTotal;     // Total Yes votes collected 
    mapping (address => uint) public voteNoTotal;      // Total No votes collected
    mapping (address => uint) public dateIntroduced;   // Timestamp when contract is proposed
    mapping (address => bool) public tokenLocked;      // Tokens locked

    function proposeNewGovernance(address newGovernanceContract) external {
        require(tokenLocked[msg.sender] == false, "Locked");
        require(GovernanceToken(GovernanceTokenAddress).balanceOf(msg.sender).mul(voteDecimal).div( GovernanceToken(GovernanceTokenAddress).totalSupply() ) > minGovToken, "<InsufGovTok" );
        require(Governance(newGovernanceContract).previousGovernance() == address(this), "WrongGovAddr");
        require(dateIntroduced[newGovernanceContract] == 0, "AlreadyProposed");
        tokenLocked[msg.sender] = true;
        proposedGovernanceList.push(newGovernanceContract);
        dateIntroduced[newGovernanceContract] = now;
    }
    
    function clearExistingVotesForProposal(address newGovernanceContract) internal {
        voteYesTotal[newGovernanceContract] = voteYesTotal[newGovernanceContract].sub( voteYes[newGovernanceContract][msg.sender] );
        voteNoTotal [newGovernanceContract] = voteNoTotal [newGovernanceContract].sub( voteNo [newGovernanceContract][msg.sender] );
        voteYes[newGovernanceContract][msg.sender] = 0;
        voteNo [newGovernanceContract][msg.sender] = 0;
    }
    
    function voteYesForProposal(address newGovernanceContract) external {
        require(dateIntroduced[newGovernanceContract].add(governanceExpiry) > now , "ProposalExpired");
        require( nextGovernance == address(0), "AlreadyQueued");
        tokenLocked[msg.sender] = true;
        clearExistingVotesForProposal(newGovernanceContract);
        voteYes[newGovernanceContract][msg.sender] = GovernanceToken(GovernanceTokenAddress).balanceOf(msg.sender);
        voteYesTotal[newGovernanceContract] = voteYesTotal[newGovernanceContract].add( GovernanceToken(GovernanceTokenAddress).balanceOf(msg.sender) );
    }
    
    function voteNoForProposal(address newGovernanceContract) external {
        require(dateIntroduced[newGovernanceContract].add(governanceExpiry) > now , "ProposalExpired");
        require( nextGovernance == address(0), "AlreadyQueued");
        tokenLocked[msg.sender] = true;
        clearExistingVotesForProposal(newGovernanceContract);
        voteNo[newGovernanceContract][msg.sender] = GovernanceToken(GovernanceTokenAddress).balanceOf(msg.sender);
        voteNoTotal[newGovernanceContract] = voteNoTotal[newGovernanceContract].add( GovernanceToken(GovernanceTokenAddress).balanceOf(msg.sender) );
    }
    
    function queueGovernance(address newGovernanceContract) external {
        require( voteYesTotal[newGovernanceContract].add(voteNoTotal[newGovernanceContract]).mul(voteDecimal).div( GovernanceToken(GovernanceTokenAddress).totalSupply() ) > voteQuorum, "<Quorum" );
        require( voteYesTotal[newGovernanceContract].mul(voteDecimal).div( voteYesTotal[newGovernanceContract].add(voteNoTotal[newGovernanceContract]) ) > votePass, "<Pass" );
        require( nextGovernance == address(0), "AlreadyQueued");
        nextGovernance = newGovernanceContract;
        nextGovernanceExecution = now.add(governanceSwitchDelay);
    }  
    
    function executeGovernance() external {
        require( nextGovernance != address(0) , "!Queued");
        require( now > nextGovernanceExecution, "!NotYet");
        require( GovernanceSwitchExecuted == false, "AlrExec");
        GovernanceToken(GovernanceTokenAddress).setGovernance(nextGovernance);
        Governance(nextGovernance).executeGovernanceActions();
        GovernanceSwitchExecuted = true;
    }
}


library SafeMath {
  function div(uint a, uint b) internal pure returns (uint) {
      require(b > 0, "SafeMath: division by zero");
      return a / b;
  }
  function mul(uint a, uint b) internal pure returns (uint) {
    if (a == 0) return 0;
    uint c = a * b;
    require (c / a == b, "SafeMath: multiplication overflow");
    return c;
  }
  function sub(uint a, uint b) internal pure returns (uint) {
    require(b <= a, "SafeMath: subtraction underflow");
    return a - b;
  }
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }
}

interface GovernanceToken {
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function mint(address tgtAdd, uint amount) external;
    function revoke(address tgtAdd, uint amount) external;
    function setGovernance(address newGovernanceAddress) external;
}

// SPDX-License-Identifier: None