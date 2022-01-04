/**
 *Submitted for verification at Etherscan.io on 2022-01-03
*/

pragma solidity 0.8.0;

contract FDCGov {
  struct userVote {
    uint amount;
    uint startBlock;
    bool forVote;
  }

  struct proposal {
    uint startBlock;
    uint endBlock;
    uint state;//0=n/a,1=open,2=passed,3=executed,4=failed
    string description;
    string title;
    uint totalVotesFor;
    uint totalVotesAgainst;
    mapping (address => userVote) votes;
  }
  mapping (address => proposal) private proposals;
  string private version = "v1";
  address private WFDCContract = 0x311C6769461e1d2173481F8d789AF00B39DF6d75;
  WrappedFreedomDividendCoin private WFDCToken;
  address[] private activeProposals;

  event stateChange (
    uint startBlock,
    uint endBlock,
    uint state,
    string description,
    string title,
    uint totalVotesFor,
    uint totalVotesAgainst
  );

  constructor() {
    WFDCToken = WrappedFreedomDividendCoin(WFDCContract);
  }

  function createProposal(string memory title, string memory description) external returns(bool) {
    require(proposals[msg.sender].state == 0, 'Proposal already open');
    require(WFDCToken.balanceOf(msg.sender) >= 10000000, 'Need 100,000 to create Proposal');
    proposals[msg.sender].startBlock = block.number;
    proposals[msg.sender].endBlock = block.number + 199385;
    proposals[msg.sender].title = title;
    proposals[msg.sender].description = description;
    proposals[msg.sender].state = 1;
    activeProposals.push(msg.sender);
    emit stateChange(
      proposals[msg.sender].startBlock,
      proposals[msg.sender].endBlock,
      proposals[msg.sender].state,
      proposals[msg.sender].description,
      proposals[msg.sender].title,
      proposals[msg.sender].totalVotesFor,
      proposals[msg.sender].totalVotesAgainst
    );
    return true;
  }

  function getStartBlock(address proposalAddress) external view returns(uint) {
    return proposals[proposalAddress].startBlock;
  }

  function getEndBlock(address proposalAddress) external view returns(uint) {
    return proposals[proposalAddress].endBlock;
  }

  function getState(address proposalAddress) external view returns(uint) {
    return proposals[proposalAddress].state;
  }

  function getDescription(address proposalAddress) external view returns(string memory) {
    return proposals[proposalAddress].description;
  }

  function getTitle(address proposalAddress) external view returns(string memory) {
    return proposals[proposalAddress].title;
  }

  function getTotalVotesFor(address proposalAddress) external view returns(uint) {
    return proposals[proposalAddress].totalVotesFor;
  }

  function getTotalVotesAgainst(address proposalAddress) external view returns(uint) {
    return proposals[proposalAddress].totalVotesAgainst;
  }

  function vote(address proposalAddress, bool forVote) external returns(bool) {
    require(proposals[proposalAddress].state == 1, 'Proposal needs to be open');
    require(WFDCToken.balanceOf(msg.sender) > 0, 'Need tokens to vote');
    require(proposals[proposalAddress].votes[msg.sender].startBlock != proposals[proposalAddress].startBlock, 'Can only vote once per proposal');
    if (forVote == true) {
      proposals[proposalAddress].totalVotesFor += WFDCToken.balanceOf(msg.sender);
    } else {
      proposals[proposalAddress].totalVotesAgainst += WFDCToken.balanceOf(msg.sender);
    }
    proposals[proposalAddress].votes[msg.sender].amount += WFDCToken.balanceOf(msg.sender);
    proposals[proposalAddress].votes[msg.sender].forVote = forVote;
    proposals[proposalAddress].votes[msg.sender].startBlock = proposals[proposalAddress].startBlock;
    return true;
  }

  function getVotes(address proposalAddress) external view returns(uint) {
    return proposals[proposalAddress].votes[msg.sender].amount;
  }

  function getVotesStartBlock(address proposalAddress) external view returns(uint) {
    return proposals[proposalAddress].votes[msg.sender].startBlock;
  }

  function getVotesForVote(address proposalAddress) external view returns(bool) {
    return proposals[proposalAddress].votes[msg.sender].forVote;
  }

  function updateProposal(address proposalAddress) external returns(bool) {
    require(WFDCToken.balanceOf(msg.sender) > 0, 'Need tokens to update');
    if (proposals[proposalAddress].state == 1) {
      if (block.number >= proposals[proposalAddress].endBlock) {
        if (proposals[proposalAddress].totalVotesFor > proposals[proposalAddress].totalVotesAgainst) {
          proposals[proposalAddress].state = 2;
          emit stateChange(
            proposals[proposalAddress].startBlock,
            proposals[proposalAddress].endBlock,
            proposals[proposalAddress].state,
            proposals[proposalAddress].description,
            proposals[proposalAddress].title,
            proposals[proposalAddress].totalVotesFor,
            proposals[proposalAddress].totalVotesAgainst
          );
        } else {
          emit stateChange(
            proposals[proposalAddress].startBlock,
            proposals[proposalAddress].endBlock,
            4,
            proposals[proposalAddress].description,
            proposals[proposalAddress].title,
            proposals[proposalAddress].totalVotesFor,
            proposals[proposalAddress].totalVotesAgainst
          );
          resetProposal(proposalAddress);
        }
      }
    } else if (proposals[proposalAddress].state == 2) {
      require(proposalAddress == msg.sender, 'Proposal creator can only set state to executed');
      emit stateChange(
        proposals[proposalAddress].startBlock,
        proposals[proposalAddress].endBlock,
        3,
        proposals[proposalAddress].description,
        proposals[proposalAddress].title,
        proposals[proposalAddress].totalVotesFor,
        proposals[proposalAddress].totalVotesAgainst
      );
      resetProposal(proposalAddress);
    }
  }

  function resetProposal(address proposalAddress) private {
    proposals[proposalAddress].startBlock = 0;
    proposals[proposalAddress].endBlock = 0;
    proposals[proposalAddress].state = 0;
    proposals[proposalAddress].description = "";
    proposals[proposalAddress].title = "";
    proposals[proposalAddress].totalVotesFor = 0;
    proposals[proposalAddress].totalVotesAgainst = 0;

    uint deleteIndex;
    for (uint proposalCount = 0; proposalCount < activeProposals.length; proposalCount++) {
      if (activeProposals[proposalCount] == proposalAddress) {
        deleteIndex = proposalCount;
      }
    }
    activeProposals[deleteIndex] = activeProposals[activeProposals.length - 1];
    activeProposals.pop();
  }

  function getActiveProposal(uint id) external view returns(address) {
    return activeProposals[id];
  }

  function getActiveProposalLength() external view returns(uint) {
    return activeProposals.length;
  }

  function getActiveProposals() external view returns(address[] memory) {
    return activeProposals;
  }

  function getVersion() external view returns(string memory) {
    return version;
  }
}

interface WrappedFreedomDividendCoin {
    function balanceOf(address Address) external view returns (uint);
}