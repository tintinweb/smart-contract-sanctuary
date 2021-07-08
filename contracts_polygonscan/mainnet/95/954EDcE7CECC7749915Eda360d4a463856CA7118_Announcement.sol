/**
 *Submitted for verification at polygonscan.com on 2021-07-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Announcement
 * @dev Makes an announcement on an EVM blockchain
 */
contract Announcement {

    string public announcement;
    string public ipfs;
    address deployer = msg.sender;

    function setAnnouncement(string memory _announcement) external{
        require(msg.sender == deployer, "Only deployer can set announcement.");
        announcement = _announcement;
    }
    
    function setIPFS(string memory _ipfs) external{
        require(msg.sender == deployer, "Only deployer can set IPFS.");
        ipfs = _ipfs;
    }
    
}