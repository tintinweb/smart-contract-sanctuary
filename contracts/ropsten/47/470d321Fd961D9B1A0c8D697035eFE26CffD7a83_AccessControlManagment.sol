/**
 *Submitted for verification at Etherscan.io on 2021-10-20
*/

pragma solidity >=0.4.16 <0.7.0;
pragma experimental ABIEncoderV2;
contract AccessControlManagment
{
    string idReq;
    string actionn;
    string idRes;
    struct  right {
       string idRequester;
       string idResource;
       string action;
    }

     function addReq(string memory id) public{
         idReq =id;
   }
    function addRes(string memory id) public{
         idRes =id;
   }
   function addRight(string memory idRequester,string memory idResource, string memory action) public{
         //ajouter droit selon vlan ou attribut/role  
         right memory r = right(idRequester,idResource,action);
         idReq =idRequester;
          idRes =idResource;
         actionn = action;
   }
   function getidReq() public  returns (string memory){
       return idReq;
   }
   function getidRes() public  returns (string memory){
       return idRes;
   }
   function getaction() public returns (string memory)
   {
       return actionn;
   }
   
  function getRight() public  view returns (string memory, string memory,string memory){
       
       return (idReq,idRes,actionn);
       
   }
   }