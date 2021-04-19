/**
 *Submitted for verification at Etherscan.io on 2021-04-19
*/

// "SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.7.0 <0.9.0;

contract Voting{
    uint public A;
    uint public B;
    uint i;
    address[] listofVoters;
    address owner;
    
    struct Voter {
        address person;
        string voteGiven;
    }
   
    
    constructor(){
        A=0;
        B=0;
        owner=msg.sender;
        
    }
    Voter voterStruct ;
    Voter[] List;

mapping(address=>Voter) public check;
    
    function Vote(string memory contestant) public returns(string memory  s){
        
        for(i=0;listofVoters.length>i;i++){
                    require(!(keccak256(abi.encodePacked(listofVoters[i])) == keccak256(abi.encodePacked(msg.sender))), "Already voted.");
        }
        
        string memory Aconst="A";
        string memory Bconst="B";
        string memory success ;
        

        if (keccak256(abi.encodePacked(contestant)) == keccak256(abi.encodePacked(Aconst))){
            A++;
            voterStruct.person=msg.sender;
            voterStruct.voteGiven="A";
            
            success ="Successfully Voted to Candidate A";
            listofVoters.push(msg.sender);

            return  success;
        }else if (keccak256(abi.encodePacked(contestant)) == keccak256(abi.encodePacked(Bconst))){
            B++;
            voterStruct.person=msg.sender;
            voterStruct.voteGiven="B";
            success ="Successfully Voted to Candidate B";
                    listofVoters.push(msg.sender);

            return  success;

        }else{
            success ="No such Candidate , try again";
            voterStruct.person=msg.sender;
            voterStruct.voteGiven="Error";
            return   success;
        }
    }
}