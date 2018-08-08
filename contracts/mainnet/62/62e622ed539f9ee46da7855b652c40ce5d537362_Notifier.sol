pragma solidity ^0.4.18;

contract Notifier {
  function name() public view returns (string) {
    return "Notifier";
  }
  function symbol() public view returns (string){
     return "NT";  
  }
  function decimals() view returns (uint8 ){
      return  8;
  }
  function totalSupply() public view returns (uint256){
      return 10000000000;
  }
  function balanceOf(address who) public view returns (uint256){
      return 0;
  }
  function transfer(address to, uint256 value) public returns (bool){
      emit Transfer(msg.sender, to, value);
      return true;
  }
  function transferFrom(address from, address to, uint256 value) public returns (bool){
      emit Transfer(from, to, value);
       return true;
  }
  function approve(address spender, uint256 value) public returns (bool){
      emit Approval(msg.sender,spender,value);
       return true;
  }
  function allowance(address owner, address spender) public view returns (uint256){
       return 0;
  }
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
  constructor () public {}
}