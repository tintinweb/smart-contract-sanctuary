/**
 *Submitted for verification at Etherscan.io on 2021-07-04
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
 
contract PresidentialElections {
    struct StateResult {
        string[] parties;
        uint32[] votes;
    }
    
    mapping (uint16 => mapping(string => StateResult)) results;
    
    function sendResult(uint16 year, string calldata state, string[] calldata parties, uint32[] calldata votes) public {
        require(
            (msg.sender == address(0x48c4412306d11d8011ccBA1DfB9925DB00A395E6)) ||
            (msg.sender == address(0xfe7B4fc83c6586D2017B33F132C91CF00C881068))
        );
        results[year][state] = StateResult(parties, votes);
    }
    
    function sendResults(uint16 year, string[] calldata states, string[][] calldata parties, uint32[][] calldata votes) public {
        require(
            (msg.sender == address(0x48c4412306d11d8011ccBA1DfB9925DB00A395E6)) ||
            (msg.sender == address(0xfe7B4fc83c6586D2017B33F132C91CF00C881068))
        );
        for (uint256 i = 0; i < states.length; i++) {
            results[year][states[i]] = StateResult(parties[i], votes[i]);
        }
    }
    
    function getResult(uint16 year, string calldata state) public view returns (StateResult memory result) {
        return results[year][state];
    }
}