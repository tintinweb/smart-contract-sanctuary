/**
 *Submitted for verification at Etherscan.io on 2021-08-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;



// File: yesOrNoPoll.sol

contract yesOrNoPoll {
    /* string[] ideaList   */

    string[] ideas;

    mapping (bytes => bool) public hasVoted;
    mapping (bytes => bool) notNewIdea;
    mapping (bytes => uint256) public posVote;
    mapping (bytes => uint256) public negVote;



    function getIdeas() public view returns (string[] memory ideasView)  {
        return ideas;
    }
    function addIdea( string memory newIdea) public {
      //msg.sender
      bytes memory encoded = bytes(newIdea);
      require(!notNewIdea[encoded],"idea must be new");
      ideas.push(newIdea);
      notNewIdea[encoded] = true;
    }
    function vote ( string  memory oldIdea, bool  votePolarity ) public  {
      require(notNewIdea[bytes(oldIdea)],"idea must be declared");

      bytes memory  encoded = bytes(oldIdea) ;
      require(hasVoted[encoded]);

      hasVoted[encoded] = true;
      if(votePolarity){
        posVote[encoded] =  posVote[encoded] + 1;
      }
      else{
        negVote[encoded] =  negVote[encoded] + 1;
      }

    }

}