/**
 *Submitted for verification at Etherscan.io on 2021-06-02
*/

pragma solidity >=0.7.0 <0.9.0;


contract slice111{
    bytes32 private r;
    
    
    function decode (bytes memory signmes) public returns(bytes32 result){
        r = bytesToBytes32(slice(signmes,32,32));
        return result;
    }
    
    function slice (bytes memory signmes,uint start,uint len) public pure returns(bytes memory){
        bytes memory b=new bytes(len);
        for(uint i=0;i<len;i++){
          b[i]=signmes[i+start];
      }
       return b;
    }
    function bytesToBytes32 (bytes memory signmes) private pure returns(bytes32 result1){
        assembly{
          result1 :=mload(add(signmes,32))
      }
    }
}