/**
 *Submitted for verification at Etherscan.io on 2021-09-05
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.12;

interface Votting {
    function vote(uint proposal_id, bool votiing) external;
    
    function getVoteResult(uint proposal_id) external view returns (bool , uint , uint );
}

contract Vote is Votting {
    
    mapping(uint=>mapping(address=>bool)) _exists;
    mapping(uint=>uint[]) _votes;
    
    function vote(uint proposal_id, bool voting) public override {
        require(!_exists[proposal_id][msg.sender], "you already voted.");
        _exists[proposal_id][msg.sender] = true;
        _votes[proposal_id].push(voting ? 1 : 0);
    }
    
    function getVoteResult(uint proposal_id) public override view returns (bool votting_result, uint support_num, uint against_num) {
        uint agrees;
        uint disagrees;
        
        uint[] storage __votes = _votes[proposal_id];
        
        for(uint i=0; i<__votes.length;i++) {
            if(__votes[i]==1) {
                agrees++;
            } else {
                disagrees++;
            }
        }
        
        return(agrees>disagrees, agrees, disagrees);
    }
}