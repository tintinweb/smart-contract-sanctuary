/**
 *Submitted for verification at BscScan.com on 2021-12-10
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.7;

contract ownerShip
{
    address public ownerWallet;
    address public newOwner;
    event OwnershipTransferredEv(address indexed previousOwner, address indexed newOwner);

    constructor() 
    {
        ownerWallet = address(msg.sender);
    }

    function transferOwnership(address payable _newOwner) public onlyOwner 
    {
        newOwner = _newOwner;
    }

    function acceptOwnership() public 
    {
        require(msg.sender == newOwner);
        emit OwnershipTransferredEv(ownerWallet, newOwner);
        ownerWallet = newOwner;
        newOwner = address(0);
    }

    modifier onlyOwner() 
    {
        require(msg.sender == ownerWallet);
        _;
    }

}

contract Ballot {
    struct Voter {
        uint weight;
        bool voted;
        address delegate;
    }

    struct Proposal {
        string content;
        uint voteCount;
    }

    mapping(address => Voter) public voters;

    Proposal[] public proposals;
    
    uint256 starttime;
    uint256 endtime;

    constructor(string[] memory contents, uint256 _starttime, uint256 _endtime) {
        for (uint i = 0; i < contents.length; i++) {
            proposals.push(Proposal({
                content: contents[i],
                voteCount: 0
            }));
        }

        starttime = _starttime;
        endtime = _endtime;
    }

    function delegate(address to) public {
        Voter storage sender = voters[msg.sender];

        require(sender.weight == 0, "You already voted.");
        require(to != msg.sender, "Self-delegation is disallowed.");

        sender.voted = true;
        sender.delegate = to;

        Voter storage delegate_ = voters[to];
        
        delegate_.weight += sender.weight;
        delegate_.voted = false;
    }

    function vote(uint proposal, uint count) public {
        Voter storage sender = voters[msg.sender];

        require(!sender.voted, "Already voted.");

        if(sender.weight == 0) {
            sender.weight = 5;
        }

        require(sender.weight > count, "More weight needs.");

        proposals[proposal].voteCount += count;
        sender.weight -= count;

        if(sender.weight == 0)
            sender.voted = true;
    }

    function winningProposal() public view returns (Proposal memory)
    {
        uint winningVoteCount = 0;
        uint winningProposal_;

        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].voteCount > winningVoteCount) {
                winningVoteCount = proposals[p].voteCount;
                winningProposal_ = p;
            }
        }

        return proposals[winningProposal_];
    }
}

contract VoteContract is ownerShip {
    struct Governance {
        uint256 index;
        uint256 starttime;
        uint256 endtime;
        address bcontract;
    }
    
    struct Project {
        string content;
        bool voted;
    }

    Governance[] public governances;
    Project[] public projects;

    constructor(){
    }

    function submitProject(string memory title) public {
        Project memory project = Project (title, false);
        
        projects[projects.length] = project;
    }

    function createGovernance (uint256[] memory projectIds, uint256 starttime, uint256 endtime) onlyOwner public {
        string[] memory contents;

        for(uint256 i = 0; i < projectIds.length; i++) {
            contents[contents.length] = projects[projectIds[i]].content;
        }

        Ballot bcontract = new Ballot(contents, starttime, endtime);

        Governance memory governance = Governance(
            governances.length,
            starttime,
            endtime,
            address(bcontract)
        );

        governances[governances.length] = governance;
    }
}