// contracts/Arbitrator.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
// openDispute, vote, closeDispute, appealDispute, settleDispute, Deposit?

contract Arbitrator {
    address payable private owner;

    uint256 yeeCount;
    uint256 nayCount;

    struct Dispute {
        // the person opening the dispute
        address prosecutor;
        // the defendant of the dispute
        address defendant;
        // the amount in $$ that the prosecutor is requesting in damages
        uint256 amount;
        // response to dispute
        uint256 response;
        // file hash (stored on ipfs) on prosecutor evidence related to the case
        bytes32 prosecutorEvidence;
        // file hash (stored on ipfs) on defendant evidence related to the case
        bytes32 defendantEvidence;
        // status of the current dispute
        disputeStatus status;
        // status of the current dispute
        disputeRulings ruling;
        // addresses of users that voted
        mapping(address => bool) voters;
        // mapping from address of voters to yes or no
        mapping(address => bool) votedYesOrNo;
        // mapping from voters to hashed vote
        mapping(address => uint256)  votedYesOrNoSecret;
        // number of users that voted yes
        uint yeeCount;
        // number of users that voted no
        uint nayCount;
        // date dispute was opened
        uint256 openDate;
        // deadline to vote
        uint256 voteDeadline;
        // date dispute was closed
        uint256 closeDate;
    }
    Dispute[] public disputes;

    enum disputeStatus {PENDING, CLOSED, VOTING} // to do: APPEAL
    enum disputeRulings {PENDING, NOCONTEST, GUILTY, INNOCENT}

    constructor() public {
        owner = msg.sender;
        }
    
    // file a new dispute
    function openDispute(uint256 _compensationRequested, bytes32 _disputeSummary, address _defendant) 
    public returns(uint256 disputeNumber) {
        // set date info
        uint256 today = 0;
        uint256 deadline = today + 3;
        // create new dispute
        Dispute memory d;
        // set parties
        d.prosecutor = msg.sender;
        d.defendant = _defendant;
        // add prosecutor's information
        d.amount = _compensationRequested;
        d.prosecutorEvidence = _disputeSummary;
        // set status and voting details
        d.status = disputeStatus.PENDING;
        d.ruling = disputeRulings.PENDING;
        d.yeeCount = 0;
        d.nayCount = 0;
        d.openDate = today;
        d.voteDeadline = deadline;
        // add dispute to list of disputes
        disputes.push(d);
        // output this dispute's number for reference
        disputeNumber = disputes.length - 1;
        return disputeNumber;
    }

    // respond to dispute
    // to do: _counterSummary & _comp optional
    function respondToDispute(uint256 disputeNumber, uint256 _response, bytes32 _counterSummary, uint256 _comp)
    public {
        require((msg.sender == disputes[disputeNumber].prosecutor) || (msg.sender == disputes[disputeNumber].defendant));
        disputes[disputeNumber].response = _response;
        if (_response==0 || _response==1) { // plea: 0 = no contest, 1 = guilty
            settleDispute(disputeNumber, _response);
        }
        else if (_response==2) { // plea: counter
            counterDispute(disputeNumber, _counterSummary, _comp);
        }
        // start vote
        else { // plea: innocent / otherwise
            disputes[disputeNumber].status = disputeStatus.VOTING;
        }
    }

    // settle dispute
    function settleDispute(uint256 disputeNumber, uint256 _response) private {
        // to do: transfer funds
        // no contest or guilty ruling
        if (_response==0) {
            disputes[disputeNumber].ruling = disputeRulings.NOCONTEST;
        }
        else {
            disputes[disputeNumber].ruling = disputeRulings.GUILTY;
        }
        // close dispute
        disputes[disputeNumber].status = disputeStatus.CLOSED;
    }

    // counter dispute
    function counterDispute(uint256 disputeNumber, bytes32 _counterSummary, uint256 _comp) private {
        // defense
        disputes[disputeNumber].defendantEvidence = _counterSummary;
        disputes[disputeNumber].amount = _comp;
    }

    // vote yee 1 or nay 0
    function vote(uint256 disputeNumber, bool voteCast) public {
        require(disputes[disputeNumber].status==disputeStatus.VOTING, "voting not live :)");
        require(!disputes[disputeNumber].voters[msg.sender], "already voted :)");
        //if voting is live and address hasn't voted yet, count vote  
        if(voteCast) {disputes[disputeNumber].yeeCount++;}
        if(!voteCast) {disputes[disputeNumber].nayCount++;}
        //address has voted, mark them as such
        disputes[disputeNumber].voters[msg.sender] = true;
    }

    // outputs current vote counts
    function getVotes(uint256 disputeNumber) public view returns (uint yesVotes, uint noVotes) {
        return(disputes[disputeNumber].yeeCount, disputes[disputeNumber].nayCount);
    }

    // // lets user know if their vote has been counted
    // // status: WIP
    // function haveYouVoted(uint256 disputeNumber) public view returns (bool) {
    //     return disputes[disputeNumber].voters[msg.sender];
    // }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}