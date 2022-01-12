/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

//VoteData Struct
struct voteData {
    string title;
    int count;
}

//Create Contract
contract EasyVoting{
    //Create Array of Struct voteData 
    //private it can use only inside the contract that defines the function
    voteData [] private votes;

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
        //create Title Push data to vote with voteData struct
        votes.push(voteData(_title,0));
        //or can do this
        // votes.push(voteData({title:_title,count:0}));
    }
    //Remove Title with your input index 
    function RemoveTitleByIndex(uint _index)public{
        //owner can oly use
        //require = if owner!=msg.sender(address of who call this func) will Alert error
        require(owner==msg.sender,"You're not the owner");
        //revert = Alert error Without it own condition like require
        if(_index>votes.length) revert("Don't have this Index");
        //Clear data in votes[_index] title="" count=0
        delete votes[_index];
    }
    ///VoteTitleByIndex 
    function VoteTitleByIndex(uint _index)public{
        //getData from votes[_index] to vote
        voteData storage vote=votes[_index];
        //make vote.count +1 you can also call vote.title too.
        vote.count++;
    }
    //randomvote use abi encode and keccak256 hash
    function RandomVote()public{
        //randnum = hash a data of(block.timestamp, block.difficulty) that always change
        uint randnum =uint(keccak256(abi.encode(block.timestamp, block.difficulty)));
        randnum=randnum%(votes.length-1);
        require(votes.length>1,"No Title");
        voteData storage vote=votes[randnum];
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
    //getVotes will return all arrays in votes using returns(voteData[]memory) voteData=struct
    function getVotes()public view returns(voteData[]memory){
        return votes;
    }
    //get data in votes which index = _index(your input) return only voteData not Arrays
    function getVotesByIndex(uint _index)public view returns(voteData memory){
        require(votes.length>1,"No Title");
        voteData storage vote=votes[_index];
        return vote;
    }
    
}