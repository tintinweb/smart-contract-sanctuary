/**
 *Submitted for verification at Etherscan.io on 2021-09-27
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity >0.8.0;


contract Hello{
    string name="Elvin";
    
    function getName() public view returns(string memory)
    {
        return name;
    }
    
    function setName(string memory _name) public pure returns(string memory) {
        //name=_name;
        //string memory newName=_name;
        //string memory newName2=name;
        //name=_name;
        return _name;
    }
    
    function setName2(string memory _name) pure public returns(string memory){
        return _name;
    }
    
    function a(int32[] memory i) public{
        
    }
    
    function strConcat(string memory _a, string memory _b) internal pure returns (string memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ret = new string(_ba.length + _bb.length);
        bytes memory bret = bytes(ret);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++)bret[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bret[k++] = _bb[i];
        return string(ret);
   }  
}