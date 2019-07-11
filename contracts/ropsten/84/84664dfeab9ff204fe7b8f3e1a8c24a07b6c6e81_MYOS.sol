/**
 *Submitted for verification at Etherscan.io on 2019-07-08
*/

pragma solidity ^0.4.24;

contract ERC20{
function totalsupply() public view returns (uint256);
function balanceof(address _who) public view returns(uint256);
function transfer(address _to, uint256 value)public returns (bool);

function burnToken(uint256 _value) public returns (bool);
}



 contract MYOS is ERC20 {
     
     /*This creates an array with all balances*/
     
     mapping (address => uint256) public balanceofUser;
     
     uint256 totalTokens;
     string public name;
     string public symbol;
     uint public decimals;
     
     constructor(uint256 totaltokensinput,string user,string sym, uint256 unit)public
     {
         totalTokens = totaltokensinput*10**unit;
         name = user;
         sym = symbol;
         decimals = unit;
     }
     
     function transfer(address _to, uint256 value)public returns (bool){
         balanceofUser[msg.sender]=balanceofUser[msg.sender]-value;
         balanceofUser[_to]=balanceofUser[_to]+value;
         
     }
      function totalsupply() public view returns (uint256){
          return totalTokens;
      }
         
       function balanceof(address _who) public view returns(uint256){
           return balanceofUser[_who];
       }     
       function burnToken(uint256 value) public returns (bool){
           require(value>0);
           require(balanceofUser[msg.sender]>=value);
           balanceofUser[msg.sender]=balanceofUser[msg.sender]-value;
           totalTokens = totalTokens-value;
           return true;
           
       }
       
 }