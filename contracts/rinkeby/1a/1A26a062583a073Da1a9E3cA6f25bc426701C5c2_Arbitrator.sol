// contracts/Arbitrator.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
// openDispute, vote, closeDispute, appealDispute, settleDispute, Deposit?

contract Arbitrator {
    address payable private owner;

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
        address[] voted;
        // mapping from address of voters to yes or no
        mapping(address => bool) votedYesOrNo;
        // mapping from voters to hashed vote
        mapping(address => uint256)  votedYesOrNoSecret;
        // number of users that voted yes
        uint yea;
        // number of users that voted no
        uint nay;
        // date dispute was opened
        uint256 openDate;
        // deadline to vote
        uint256 voteDeadline;
        // date dispute was closed
        uint256 closeDate;
    }
    Dispute[] public disputes;

    enum disputeStatus {PENDING, CLOSED, GUILTY, INNOCENT, APPEAL}

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
        d.yea = 0;
        d.nay = 0;
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
    }
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