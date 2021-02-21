/**
 *Submitted for verification at Etherscan.io on 2021-02-21
*/

//"SPDX-License-Identifier: UNLICENSED"
pragma solidity >=0.4.22 <0.9.0;

contract sample{
    string public mesg;
    address public owner;
    
    constructor(string memory _mesg){
        owner = msg.sender;
        mesg = _mesg;
    }
    
    function getMesg() public view returns(string memory){
        return mesg;
    }
    
    function getOwner() public view returns(address){
        return owner;
    }
    
    function setMesg(string memory _mesg) public {
        mesg = _mesg;
    }
}