//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


contract SimpleStorage {
  

    event NewVoteFromUser(address _address, uint _vote);
    event ChangedVoteFromUser(address _address, uint _vote);



    //private storage
    struct User {
    address userAddress;
    uint vote;
    }

   mapping(address => User) internal favoriteNumbers;

    function AddFavoriteNumber(uint voteNumber) public {
        require(voteNumber > 0,"Value cannot be 0");
        require(msg.sender != address(0),"Contract cannot vote itself");
        require(favoriteNumbers[msg.sender].vote == 0, "You cant vote twice" );
        favoriteNumbers[msg.sender]=User(msg.sender,voteNumber);
        emit NewVoteFromUser(msg.sender, voteNumber);
    }

    function ChangeVote(uint newVoteNumber) public {
        require(newVoteNumber > 0,"Value cannot be 0");
        require(msg.sender != address(0),"Contract cannot vote itself");      
        SetVote(newVoteNumber);
    }

    function SetVote(uint voteNumber) private {
        favoriteNumbers[msg.sender].vote=voteNumber;
        emit NewVoteFromUser(msg.sender, voteNumber);  
    }

    function GetVote() public view returns (uint) {
        return  favoriteNumbers[msg.sender].vote ;
    }
}