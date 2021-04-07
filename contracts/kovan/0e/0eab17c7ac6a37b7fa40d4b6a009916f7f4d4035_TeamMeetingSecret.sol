/**
 *Submitted for verification at Etherscan.io on 2021-04-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title TeamMeetingSecret
 * @dev we will do a team meeting!
 */
contract TeamMeetingSecret {

    string private secret;
    
    address owner;
    
    /// Create a new TeamMeetingSecret
    constructor(string memory _secret) {
        owner = msg.sender;
        secret = _secret;
    }

    /**
     * @dev Return value 
     * @return value of 'secret'
     */
    function getLastThree() public view returns (string memory){
        return secret;
    }
}