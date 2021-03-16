/**
 *Submitted for verification at Etherscan.io on 2021-03-16
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

// import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol';

interface Membership {
    
    function memberId(address) external view returns(uint);
    
    function certifierGetter(address) external view returns(bool);
    
    function certifierUpdate(address) external;
    
    function paymentGetter(address) external view returns(bool);
    
    function kycGetter(address) external view returns(bool);
    
}

contract Ballot {
    
    using SafeMath for uint256;
   
    struct Voter {
        // uint id;
        bool voted;  
        address vote; 
        // bool rtv;
    }
    
    struct Candidate{
        bool chk;
        uint voteCount;
    }
    
    // uint public _tokenIds = 1;

    Membership member;
    
    // mapping(string=>uint) public membertokenid;
    // mapping(uint=>address) public candidateadd;
    
    // uint public totalvoter;
    // uint public totalcandidate;
    
    bool voting = false;
    
    uint256 private time;
    
    address private admin;

    mapping(address => Voter) public voter;
    mapping(address => Candidate) public candidate;
    
    address[] private voterList;
    address[] private candidateList;
    address[] private winners;
    
    uint private votes = 0;
    
    constructor(Membership _address) public {
        admin = msg.sender;    
        member = _address;
    }
    
    modifier onlyOwner() {
        require(admin==msg.sender, "Ownable: caller is not the Admin");
        _;
    }
    
    modifier arkMember(address user) {
        require(member.memberId(user)>0,"You are not a member");
        _;
    }
    
    modifier arkVoter(address user) {
        require(member.paymentGetter(user),"You are not Paid");
        require(member.kycGetter(user),"You are not verified");
        _;
    }

    
    // function id(address user) public view returns(uint) {
    //     return member.memberId(user);
    // }
    
    // function checkCertifier(address user) public view returns(bool) {
    //     return member.certifierGetter(user);
    // }
    
    function propose() public arkMember(msg.sender) returns(bool){
        require(member.memberId(msg.sender)>0,"not a member");
        require(!voting,"No proposal during voting");
        require(!candidate[msg.sender].chk,"Already a Candidate");
        require(!member.certifierGetter(msg.sender),"Already a Certifier");
        address to = msg.sender;
        candidate[to].voteCount = 0;
        candidate[to].chk = true;
        // candidateList[to].id = member.memberId(msg.sender);
        // candidateList[to].name = member.nameofmember(msg.sender);
        // candidateadd[member.findId(msg.sender)]=msg.sender;
        // totalcandidate = totalcandidate.add(1);
        candidateList.push(to);
        return true;
    }
    
    
    // function claimtovote() public {
    //     address memberadd = msg.sender;
    //     require(member.memberId(memberadd)>0,"Not a member");
    //     require(!voter[memberadd].rtv,"Already claim");
    //     voter[memberadd].rtv = true;
    //     voter[memberadd].id = member.memberId(memberadd);
    //     totalvoter = totalvoter.add(1);        
    // }
    
    
    function startVoting() public {
        require(admin == msg.sender, "Admin is authorized to start voting");
        time = now;
        voting = true;
        delete winners;
    }
    
    function totalProposals() public view returns (address[] memory) {
        return candidateList;
    }
    
    function winner() public view returns (address[] memory) {
        return winners;
    }
    
    
    function ismember(address _address) public view returns(bool){
        if(member.memberId(_address)>0){
            return true;
        }
        
        return false;
        
    }
    
    function vote(address _proposal) public arkVoter(msg.sender) {
        Voter storage sender = voter[msg.sender];
        // require(voting," Voting has not started yet");
        if (now >= time.add(8 minutes)) voting = false;
        require(voting, "No Voting is going on");
        require(member.memberId(msg.sender)>0,"Not a member");
        // require(sender.rtv,"does not have voting right");
        require(!sender.voted, "Already voted.");
        require(candidate[_proposal].chk,"No such candidate exist");
        
        sender.voted = true;
        sender.vote = _proposal;
        voterList.push(msg.sender);

        candidate[_proposal].voteCount = candidate[_proposal].voteCount.add(1);
        if (candidate[_proposal].voteCount > votes) {
            votes = candidate[_proposal].voteCount;
        }
        
        // _burn(voters[msg.sender].id);
    }


    function winningProposal() public
            returns (address[] memory)
    {
        require(msg.sender == admin, "Only admin can pick the winner");
        
        for (uint i=0; i<candidateList.length; i++) {
            if (candidate[candidateList[i]].voteCount == votes) {
                winners.push(candidateList[i]);
            }
        }
        voting = false;
        
        for (uint i=0; i<winners.length; i++) {
            member.certifierUpdate(winners[i]);
        }
    return winners;
    }

    // function timeLeft() public view returns(uint){
    //     if (time==0) return 0;
    //     return (time+(8 minutes));
    // }

    
    function Refresh() public {
        require(msg.sender == admin, "OnlyAdmin");
        // RefreshVoter();
        for (uint i=0; i<voterList.length; i++) {
            voter[voterList[i]].voted = false;
            voter[voterList[i]].vote = address(0);
        }
        for (uint i=0; i<candidateList.length; i++) {
            candidate[candidateList[i]].chk = false;
            candidate[candidateList[i]].voteCount = 0;
        }
        delete voterList;
        delete candidateList;
    }
    
    // function RefreshVoter() internal {
    //     for (uint i=0; i<voterList.length; i++) {
    //         voter[voterList[i]].voted = false;
    //         voter[voterList[i]].vote = address(0);
    //     }
    //     delete voterList;
    // }
}

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}