/**
 *Submitted for verification at Etherscan.io on 2021-06-02
*/

pragma solidity >=0.7.0 <0.9.0;

contract test{
     function slice (bytes memory signmes,uint start,uint len) public pure returns(bytes memory){
        bytes memory b=new bytes(len);
        for(uint i=0;i<len;i++){
          b[i]=signmes[i+start];
      }
       return b;
     }
     function slicer (bytes memory signmes) public pure returns(bytes memory){
         bytes memory rresult=slice(signmes,0,32);
         return rresult;
     }
}