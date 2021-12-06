// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;
import './2_Owner.sol';

contract Electioncreation is Owner {
    
    address[] public deployedBallots;
    // List of admin wallet, able to create new election
    mapping (address => bool) public admin;

    function setAdmin(address _wallet) isOwner public {
        admin[_wallet] = true;
    }
    function revokeAdmin(address _wallet) isOwner public {
        admin[_wallet] = false;
    }
    modifier isAdmin() {
        require(admin[msg.sender] == true);
        _;
    }
    function createElection (string memory electionName, string memory description, uint startTime, uint endTime, uint minVote, uint maxVote) isAdmin public returns (address){
        // admin create this election = chairman of this ballot
        Ballot newBallot = new Ballot(electionName, description, startTime, endTime, minVote, maxVote, msg.sender);
        deployedBallots.push(address(newBallot));
        return address(newBallot);
    }

    function getsDeployedBallots() public view returns(address[] memory) {
        return deployedBallots;
    }
}

contract Ballot
{
    // Ung cu vien trong cuoc bau cu
    struct Proposal
    {
        string name;
        string description;
        uint voteCount;
    }
    Proposal[] public proposals;

    string public name; 
    string public description;
    // uint in seconds since 1970, block.timestamp = current time
    uint public startTime;
    uint public endTime;
    // minimum or maximum number of different Proposals someone can vote 
    uint public minVote;
    uint public maxVote;
    address public chairman;

    mapping (address => bool) public rightToVote; 
    // a wallet can vote to a number of Proposals. Example: voters['0x2345'] = ['1', '3'] means they vote to Proposals 1 and 3 
    mapping (address => uint[]) public voters;


    modifier isChairman() {
        require(msg.sender == chairman);
        _;
    }

    modifier haveRightToVote() {
        require(rightToVote[msg.sender] == true, "Please contact chairman to have right to vote in this ballot");
        _;
    }

    modifier isActive() {
        require(block.timestamp >= startTime, "The ballot has not begun yet");
        require(block.timestamp <= endTime, "The ballot has ended");
        _;
    }


    constructor (string memory _name, string memory _description, uint _startTime, uint _endTime, uint _minVote, uint _maxVote, address _chairman)
    {
        name = _name;
        description = _description;
        startTime = _startTime;
        endTime = _endTime;
        minVote = _minVote;
        maxVote = _maxVote;
        chairman = _chairman;
    }
    
    // List of attributes of a ballot, can be edited ONLY BY chairman
    function setName(string memory _name) public isChairman() {
        name = _name;
    }
    function setDescription(string memory _description) public isChairman() {
        description = _description;
    }
    function setStartTime(uint _startTime) public isChairman() {
        startTime = _startTime;
    }
    function setEndTime(uint _endTime) public isChairman() {
        endTime = _endTime;
    }
    function setMinVote(uint _minVote) public isChairman() {
        minVote = _minVote;
    }
    function setMaxVote(uint _maxVote) public isChairman() {
        maxVote = _maxVote;
    }

    function addProposals(string[] memory proposalNames, string[] memory proposalDescriptions) public isChairman() {
        for (uint i = 0; i < proposalNames.length; i++)  {
            proposals.push(Proposal({   
                name: proposalNames[i],
                description: proposalDescriptions[i],
                voteCount: 0
            }));
        }
    }
    function setProposal(uint index, string memory proposalName, string memory proposalDescription) public isChairman() {
        proposals[index].name = proposalName;
        proposals[index].description = proposalDescription;
    }

    // voter = list of wallet can vote in this ballot
    function giveRightToVote(address[] memory voter) public isChairman() {
        for (uint i = 0; i < voter.length; i++) {
            rightToVote[voter[i]] = true;
        }
    }
    function revokeRightToVote(address[] memory voter) public isChairman() {
        for (uint i = 0; i < voter.length; i++) {
            rightToVote[voter[i]] = false;
        }
    }


    function vote(uint[] memory index) public haveRightToVote() isActive() {
        // check list of index is valid, ONLY ALLOW ARRAY WITH index[i + 1] > index[i] for all i
        require(index.length >= minVote && index.length <= maxVote, "Invalid number of proposals");
        for (uint i = 0; i < index.length; i++) {
            if (index[i] < 0 || index[i] >= proposals.length) revert("Invalid proposals index");
            if (i > 0) {
                if (index[i] <= index[i - 1]) revert("Should be unique sorted array");
            }
        }
        // Remove old vote if this address has already voted before
        for (uint i = 0; i < voters[msg.sender].length; i++) {
            // voters[msg.sender][i] = index of the Proposal
            proposals[voters[msg.sender][i]].voteCount -= 1;
        }
        delete voters[msg.sender];
        // update voters[msg.sender]
        for (uint i = 0; i < index.length; i++) {
            // index[] is the array of proposal index that this address vote to
            voters[msg.sender].push(index[i]);
        }
        // update new vote
        for (uint i = 0; i < voters[msg.sender].length; i++) {
            // voters[msg.sender][i] = index of the Proposal
            proposals[voters[msg.sender][i]].voteCount += 1;
        }
    }

    function getWinningProposal() public view returns(uint[] memory) {
        require(block.timestamp >= startTime, "The ballot has not begun yet");
        uint highestVoteCount = 0; 
        uint count = 0;
        for (uint i = 0; i < proposals.length; i++) {
            if  (highestVoteCount < proposals[i].voteCount) {
                highestVoteCount = proposals[i].voteCount;
                count = 1;
            }
            else if (highestVoteCount == proposals[i].voteCount) {
                count += 1;
            }
        }
        // https://stackoverflow.com/questions/68010434/why-cant-i-return-dynamic-array-in-solidity
        uint[] memory winningProposalID = new uint[](count);
        uint j = 0;
        for (uint i = 0; i < proposals.length; i++) {
            if (highestVoteCount == proposals[i].voteCount) {
                winningProposalID[j] = i;
                j += 1;
            } 
        }
        
        return winningProposalID;
    }

}