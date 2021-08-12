/**
 *Submitted for verification at polygonscan.com on 2021-08-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract tokenTracker {
    mapping(string => uint)[] internal tokenTrack; 
    mapping(address => uint) internal aur;
    uint public tokens;
    address public gov;

    constructor(address _gov){
        gov = _gov;
    }

    //modifiers
    modifier onlyGov{
        require(msg.sender == gov,'Not Authorised');
        _;
    }
    modifier onlyAur{
        require(aur[msg.sender]==1,'Not Authorised');
        _;
    }
    
    //view functions
    function totalSold (string memory refId)external view returns(uint[]memory){
        uint[] memory sold =  new uint[](tokens);
        for(uint i = 0;i<tokens;i++){
            sold[i]=(tokenSold(refId,i));
        }
        return sold;
    }

    function tokenSold(string memory refId,uint index) public view returns(uint sold){
        return(
            tokenTrack[index][refId]
        );
    } 

    // external func
    
    function changeGov(address _newGov) external onlyGov{
        gov=_newGov;
    }

    function addToken() external onlyGov returns (uint){
        tokenTrack.push();
        tokens++;
        return tokenTrack.length;
    }
    
    function addAur(address _aur) external onlyGov {
        aur[_aur]=1;
    }
    function removeAur(address _aur) external onlyGov {
        aur[_aur]=0;
    }

    function increase(uint index,string memory refId,uint amount) external onlyAur {
        tokenTrack[index][refId]+=amount;
    }
}