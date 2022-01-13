/**
 *Submitted for verification at Etherscan.io on 2022-01-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

//VoteData Struct
struct VoteData {
    string title;
    int count;
}

//Create Contract
contract EasyVoting{
    //Create Array of Struct VoteData 
    //private it can use only inside the contract that defines the function
    VoteData [] private votes;

    address  public owner;
    //owner is who deploy this code
    //constructor is run first time when you deploy this smartcontract
    constructor(){
        owner=msg.sender;
    }

    //The first is “storage”, where all the contract state variables reside. Every contract has its own storage and it is persistent between function calls and quite expensive to use.
    //The second is “memory”, this is used to hold temporary values. It is erased between (external) function calls and is cheaper to use.
    //The third one is the stack, which is used to hold small local variables. It is almost free to use, but can only hold a limited amount of values
    //https://docs.soliditylang.org/en/v0.3.3/frequently-asked-questions.html#what-is-the-memory-keyword-what-does-it-do
    //Write Contract
    function CreateTitle(string memory _title)public{
        //create Title Push data to vote with VoteData struct
        votes.push(VoteData(_title,0));
        //or can do this
        // votes.push(VoteData({title:_title,count:0}));
    }
    ///VoteTitleByIndex 
    function VoteTitleByIndex(uint _index)public{
        //getData from votes[_index] to vote
        VoteData storage vote=votes[_index];
        //make vote.count +1 you can also call vote.title too.
        vote.count++;
    }
    //Clear All data Only owner can do
    function ClearData()public{
        require(owner==msg.sender,"You're not the owner");
        uint dataLength=votes.length;
        //Clear All Data using pop data out of array
        for(uint i=0;i<dataLength;i++){
            votes.pop();
        }
    }



    //Read Contract
    //getVotes will return all arrays in votes using returns(VoteData[]memory) VoteData=struct
    function getVotes()public view returns(VoteData[]memory){
        return votes;
    }
    //get data in votes which index = _index(your input) return only VoteData not Arrays
    function getVotesByIndex(uint _index)public view returns(VoteData memory){
        require(votes.length>1,"No Title");
        VoteData storage vote=votes[_index];
        return vote;
    }
    
}