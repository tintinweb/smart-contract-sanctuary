/**
 *Submitted for verification at polygonscan.com on 2022-01-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Recommendation {
   
    // id => Rank
    mapping(uint256 => uint256) public ranks;
    // Rank => id
    mapping(uint256 => uint256) public ids;
    
    // For adding for a single doctor
    function addRank(
        uint256 _id,
        uint256 _rank
      ) public {
      
        // Make sure sender address exists
        require(msg.sender != address(0));
        
        ranks[_id] = _rank;
    }
    
    // For adding for multiple doctors
    function addRanks(
        uint256[] memory _ids,
        uint256[] memory _ranks
      ) public {
      
        // Make sure sender address exists
        require(msg.sender != address(0));
        
        for(uint256 i = 0; i < _ids.length; i++) {
            ranks[_ids[i]] = _ranks[i];
        }
    }

    // Like
    function likeDoctor(
        uint256 _id,
        uint256 _rank
      ) public {
      
        // Make sure sender address exists
        require(msg.sender != address(0));
        
        if(_rank > 1) {
          uint256 id2 = ids[_rank-1];

          ranks[_id] = _rank-1;
          ranks[id2] = _rank;
          ids[_rank] = id2;
          ids[_rank-1] = _id;
        }
    }

    // Dislike
    function dislikeDoctor(
        uint256 _id,
        uint256 _rank
      ) public {
      
        // Make sure sender address exists
        require(msg.sender != address(0));
        
        uint256 id2 = ids[_rank+1];

        ranks[_id] = _rank+1;
        ranks[id2] = _rank;
        ids[_rank] = id2;
        ids[_rank+1] = _id;
    }
}