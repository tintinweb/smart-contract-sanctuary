/**
 *Submitted for verification at polygonscan.com on 2021-11-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract cidManager{
    string[] cids;
    function addCID(string memory cid) public{
        if(cids.length>2){
            cids = [''];
        }
        cids.push(cid);
    }
    function showCID() public view returns(string[] memory){
        return cids;
    }
}