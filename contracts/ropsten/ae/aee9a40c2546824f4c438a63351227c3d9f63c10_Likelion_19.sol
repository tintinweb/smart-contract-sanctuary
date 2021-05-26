/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

//Sungrae Park

pragma solidity 0.8.0;

contract Likelion_19 {
    
    address owner;
    uint AllParticipant;
    
    struct Proposal {
        string content;
        uint Participant;
        uint agree;
    }
    
    mapping(address=>mapping(uint => bool)) Votecheck;
    
    Proposal[] Proposals;
    
    function ChangeOwner() public {
        owner == msg.sender;
        AllParticipant++;
    }
    
    function Propose(string memory _content) public {
        Proposals.push(Proposal(_content,0,0));
    }
    
    function Vote(uint n, bool _agree) public {
        Proposals[n].Participant++;
        if(_agree) {
            Proposals[n].agree++;
        }
        Votecheck[msg.sender][n] = true;
    }
    
    function Turnout(uint n) public view returns(uint) {
        return AllParticipant / Proposals[n].Participant;
    }
    
    function AgreeTurnout(uint n) public view returns(uint) {
        return Proposals[n].Participant  / Proposals[n].agree ;
    } 
    
    function getifVote(uint n) public view returns(bool) {
        return Votecheck[msg.sender][n];
    }
    
}