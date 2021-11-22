/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract cidManager{
    string[] lcids;
    string gcid;
    function addLocalCID(string memory _lcid) public{
        if(lcids.length>=3){
            while(lcids.length>0){
                lcids.pop();
            }
        }
        lcids.push(_lcid);
    }
    function addGlobalCID(string memory _gcid) public{
        gcid = _gcid;
    }
    function showLCID() public view returns(string[] memory){
        return lcids;
    }
    function showGCID() public view returns(string memory){
        return gcid;
    }
    
}