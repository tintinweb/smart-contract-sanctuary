/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Announcement
 * @dev Makes an announcement on an EVM blockchain
 */
contract Announcement {

    string announcement;
    string ipfs;
    
    function setAnnouncement(string memory _announcement) external{
        announcement = _announcement;
    }
    
    function announce() external view returns(string memory){
        return announcement;
    }
    
    function setIPFS(string memory _ipfs) external{
        ipfs = _ipfs;
    }
    
    function getIPFS() external view returns(string memory){
        return ipfs;
    }
}