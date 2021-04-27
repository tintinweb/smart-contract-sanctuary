/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

pragma solidity 0.8.0;

contract Add {
    uint256 a;
    uint256 b;
    
    function add(uint256 a, uint256 b) public view returns(uint256){
        return a+b;
    }
}

 contract Sub {
     uint256 a;
     uint256 b;
     
     function sub(uint256 a, uint256 b) public view returns(uint256){
         return a-b;
          }
 }     
 
 contract Mul {
     uint256 a;
     uint256 b;
     
     function mul(uint256 a, uint256 b) public view returns(uint256){
         return a*b;
     }
 }
     
     contract Div{
         uint256 a;
         uint256 b;
         
         function div(uint256 a, uint256 b) public view returns(uint256){
             return a/b;
         }
     }