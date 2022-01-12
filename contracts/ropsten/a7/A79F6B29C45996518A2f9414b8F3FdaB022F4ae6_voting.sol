/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

struct VoteData {
    string title;
    int count;
}

contract voting{
    VoteData[] private Votes;

    //Create Title Write and check Title if same then do nothing
    function CreateTitle(string memory _title)public{
       
        if(Votes.length==0) Votes.push(VoteData(_title,0));
        else{
            bool AddnewTitle =true;
            for(uint i=0;i<Votes.length;i++){ //loop all data in Votes array
            VoteData storage Vote =Votes[i];
            if(keccak256(bytes(Vote.title))==keccak256(bytes(_title))) AddnewTitle=false; //check string
        }
        if(AddnewTitle==true)   Votes.push(VoteData(_title,0));
        else revert("Already have this title");
        }
        
    }

    //Get Data from VoteData
    function getallvotedata()public view returns(VoteData [] memory ){
        return Votes;
    }
    //get vote from index
    function getvotedatabyindex(uint index)public view returns(string memory title,int count){
        if(index > Votes.length-1) return ("No This title index",0);
        VoteData storage Vote =Votes[index];
        return (Vote.title,Vote.count);
    }
    //get vote from string
    function getvotedatabytext(string memory _title)public view returns(string memory title,int count){
        for(uint i=0;i<Votes.length;i++){ //loop all data in Votes array
            VoteData storage Vote =Votes[i];
            if(keccak256(bytes(Vote.title))==keccak256(bytes(_title))) return (Vote.title,Vote.count); //check string
        }
        return ("No This title ",0);
    }
    function getVoteDataLength()public view returns(uint length){
        return Votes.length;
    }


    //Vote Write
    function Votebyindex(uint index)public{
        if(Votes.length==0) revert("Votedata is nil");
        if(index > Votes.length-1) revert("No this title index");
        else{
            VoteData storage Vote =Votes[index];
            Vote.count+=1;
        }        
    }
    ///Vote by string input
    function Votebystring(string memory _title)public{
        if(Votes.length==0) revert("Votedata is nil");
        bool isVote =false;
         for(uint i=0;i<Votes.length;i++){ //loop all data in Votes array
            VoteData storage Vote =Votes[i];
            if(keccak256(bytes(Vote.title))==keccak256(bytes(_title))) {
                Vote.count++; //check string
                isVote=true;
            }
        }
        if(isVote==false) revert("Not match Title");
    }
    ///Random vote
    function Randomvote()public{

        if(Votes.length!=0)
        {
        uint rand =random();
        uint result=rand%(Votes.length);
        VoteData storage Vote =Votes[result];
        Vote.count++;
        }else revert("Votedata is nil");
        
    }


    //Remove by index Write
    // max l=5(0,1,2,3,4) remove 1 = (1,2) (2,3)(3,4)
    function RemoveVotebyIndex(uint index)public{
        if(Votes.length==0) revert("Votedata is nil");
        if(index>=Votes.length) revert("No this index");
        delete Votes[index];
        for(uint i=index;i<Votes.length-1;i++){
            VoteData storage Vote =Votes[i];
            VoteData storage Vote1 =Votes[i+1];
            Vote.title=Vote1.title;
            Vote.count=Vote1.count;
        }
        Votes.pop();// pop for remove last data
    }


    //Random
    function random() private view returns(uint){
        return uint(keccak256(abi.encode(block.timestamp, block.difficulty)));
    }

}