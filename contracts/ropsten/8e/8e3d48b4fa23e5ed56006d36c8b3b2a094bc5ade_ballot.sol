pragma solidity ^0.4.25;

contract ballot {
    struct Voter {
        uint weight;
        bool voted;
        uint vote;
        address delegate;
    }

    struct Proposal {
        bytes32 name;
        uint voteCount;
    }
    address chairperson;
    mapping (address=>Voter) voters;

    Proposal[] proposals;

    function BllotPro(bytes32[] proposalNames) public {
        chairperson = msg.sender;
        voters[chairperson].weight = 1;

        for (uint i=0; i<proposalNames.length; i++) {
            proposals.push(Proposal({
                name: proposalNames[i],
                voteCount: 0
            }));
        }
    }

    function giveRightToVote(address voter) public {
      require((msg.sender == chairperson) && !voters[voter].voted && (voters[voter].weight == 0));
      voters[voter].weight = 1;
    }

   //批量添加
   function giveRightToVoteByBatch(address[] batch) public {
       require(msg.sender == chairperson);
       for (uint i=0; i<batch.length; i++) {
           address voter = batch[i];
            require(!voters[voter].voted && (voters[voter].weight == 0));
            voters[voter].weight = 1;

       }
   }
/// 投票人将自己的投票机会授权另外一个地址

  function delegate(address to) public {
      Voter storage sender = voters[msg.sender];
      require((!sender.voted) && (sender.weight != 0));
      require(to != msg.sender);

      while (voters[to].delegate != address(0)) {
          to = voters[to].delegate;
          require(to != msg.sender);
      }

      sender.voted = true;
      sender.delegate = to;
      Voter storage delegate = voters[to];
      if (delegate.voted) {
          proposals[delegate.vote].voteCount +=sender.weight;
      } else {
          delegate.weight +=sender.weight;
      }

  }
  ///根据提案编号投票
  function vote(uint proposal) public {
      require(proposal < proposals.length);
      Voter storage sender = voters[msg.sender];

      require(!sender.voted && (sender.weight != 0));
      sender.voted = true;
      sender.vote = proposal;
      proposals[proposal].voteCount += sender.weight;

  }

  function winningProposal() public constant returns(uint[] winningProposals) {

      uint[] memory tempWinner = new uint[](proposals.length);
      uint winningCount = 0;
      uint winningVoterCount = 0;

      for (uint p = 0; p < proposals.length; p++) {
          if (proposals[p].voteCount > winningVoterCount) {
              winningVoterCount = proposals[p].voteCount;
              tempWinner[0] = p;
              winningCount = 1;
          } else if (proposals[p].voteCount == winningVoterCount) {
              tempWinner[winningCount] = p;
              winningCount ++;
          }
      }

      winningProposals = new uint[](winningCount);

      for (uint q = 0; q <winningCount; q++) {
          winningProposals[q] =tempWinner[q];
      }
      return winningProposals;
  }

  function winnerName() public constant returns(bytes32[] winnerNames) {

      uint[] memory winningProposals = winningProposal();
      winnerNames = new bytes32[](winningProposals.length);
      for (uint p = 0; p < winningProposals.length; p++) {
          winnerNames[p] = proposals[winningProposals[p]].name;
      }

      return winnerNames;

  }



}