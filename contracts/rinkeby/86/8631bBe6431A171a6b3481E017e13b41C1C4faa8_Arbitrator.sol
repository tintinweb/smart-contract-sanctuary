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

    enum disputeStatus {PENDING, CLOSED, VOTING, GUILTY, INNOCENT, APPEAL}

    constructor() public {
        owner = msg.sender;
        }
    
    // file a new dispute
    function openDispute(uint256 _compensationRequested, bytes32 _disputeSummary) 
    public returns(uint256 disputeNumber) {
        // set date info
        uint256 today = 0;
        uint256 deadline = today + 3;
        // create new dispute
        Dispute memory d;
        // set parties
        d.prosecutor = msg.sender;
        d.defendant = msg.sender;
        // add prosecutor's information
        d.amount = _compensationRequested;
        d.prosecutorEvidence = _disputeSummary;
        // set status and voting details
        d.status = disputeStatus.PENDING;
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
    function respondToDispute(uint256 disputeNumber, uint256 _response) public {
        require((msg.sender == disputes[disputeNumber].prosecutor) || (msg.sender == disputes[disputeNumber].defendant));
        disputes[disputeNumber].response = _response;
        // if response == 0
        // settleDispute()
        // elif response == 1
        // counterDispute()
        // else
        // startVote
        disputes[disputeNumber].status = disputeStatus.VOTING;
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

    //Outputs current vote counts
    function getVotes(uint256 disputeNumber) public view returns (uint yesVotes, uint noVotes) {
        return(disputes[disputeNumber].yeeCount, disputes[disputeNumber].nayCount);
    }

    //Lets user know if their vote has been counted
    function haveYouVoted(uint256 disputeNumber) public view returns (bool) {
        return disputes[disputeNumber].voters[msg.sender];
    }
}

