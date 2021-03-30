/**
 *Submitted for verification at Etherscan.io on 2021-03-30
*/

pragma solidity ^0.4.18;


interface ICYL {
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  function mint(address account, uint256 amount) public;
  function burn(address account, uint256 amount) public;
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
    
}

contract Wallet {
   
    uint256 public lockTime = block.timestamp + 30 days ;
    
    address beneficiary = 0x9b11A4946BC00DF178EC49F757DEC3aDA02BD105;
    ICYL token = ICYL(0x59BA6deD7d6BD81F42A6f65694F4B1D89Ea38A80);
    
    function withdrawTokens(uint256 amount) payable public {
       require(now >= lockTime);
       require(beneficiary == msg.sender);
       token.transfer(msg.sender,amount);
      
    }
    
    
    
    
    
    
}