/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.16 <0.7.0;
pragma experimental ABIEncoderV2;
contract AccessControlManagment
{
    string idReq;
   // string action;
    string idRes;
    string[] public tabReq;
    string[] public tabRes;
    struct right {
       string idRequester;
       string idResource;
       string action;
    }
   right[] public tabright;
 constructor () public
 {
     tabReq = new string[](100);
     tabRes = new string[](100);
     
 }
     function addReq(string memory id) public{
         idReq =id;
        tabReq.push(id);
   }
    function addRes(string memory id) public{
         tabRes.push(id);
   }
   function addRight(string memory idRequester,string memory idResource, string memory action) public{
         right memory r = right(idRequester,idResource,action);
         tabright.push(r);
   }
   
   function getRight(string memory idRequester,string memory idResource) public view returns (string memory){
       for ( uint i=0; i<tabright.length;i++)
       { if( keccak256(bytes(tabright[i].idRequester))==keccak256(bytes(idRequester)) 
       && keccak256(bytes(tabright[i].idResource))==keccak256(bytes(idResource)) )
       {
       return tabright[i].action;
       }
   }
   }
}