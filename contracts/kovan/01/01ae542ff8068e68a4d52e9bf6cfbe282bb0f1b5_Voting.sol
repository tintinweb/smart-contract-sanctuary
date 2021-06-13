/**
 *Submitted for verification at Etherscan.io on 2021-06-13
*/

// SPDX-License-Identifier: MIT


pragma solidity >=0.4.25 <0.7.0;


// address - содержит в себе 20 byte (размер ETH адреса)
// memory - то что мы храним в памяти (какое-то значение)

contract Voting{

struct vote {
    string VoterAddres;
    bool choice;
}

struct voter{
    string VoterName;
    bool voted;
}

uint private CountResult = 0;
uint public FinalResult = 0;
uint public TotalVoter = 0;
uint public TotalVote = 0;


address public BallotOfficialAddress;
string public BallotOfficialName;
string public proposal;

mapping(uint => vote) private votes;
mapping(address => voter) public VoterRegister;

enum State{
    Created,
    Voting,
    Ended
}
State public state;


//MODIFIERS

modifier condition(bool _condition){
    require(_condition);
    _;
}

modifier onlyOfficial(){
    require(msg.sender == BallotOfficialAddress);
    _;
}

modifier inState(State _state){
    require(state == _state);
    _;
}

//FUNCTIONS

constructor (string memory _BallotOfficialName, string memory _proposal) public{
    BallotOfficialAddress = msg.sender;
    BallotOfficialName = _BallotOfficialName;
    proposal = _proposal;

    state = State.Created;

}

 function addVoter(address _VoterAddres,string memory _VoterName) 
     public 
     inState(State.Created)
     onlyOfficial
 {
     voter memory v;
     v.VoterName = _VoterName;
     v.voted = false;
     VoterRegister[_VoterAddres] = v;
     ++TotalVoter;
 }
 
 function startVote() 
    public 
    inState(State.Created)
    onlyOfficial
 {
     state = State.Voting;
 }
  function doVote(bool _choice)
    public 
    inState(State.Voting)
    returns (bool voted)
  {
      bool found = false;
      if(bytes(VoterRegister[msg.sender].VoterName).length != 0 && !VoterRegister[msg.sender].voted){
          VoterRegister[msg.sender].voted = true;
          vote memory v;
          v.choice = _choice;
          if(_choice){
              ++CountResult;
          }
          votes[TotalVote] = v;
          ++TotalVote;
          found = true;
      }
      return found;
  }

  function endVote()
    public
    inState(State.Voting)
    onlyOfficial
  {
      state = State.Ended;
      FinalResult = CountResult;
  }

}