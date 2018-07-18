pragma solidity ^0.4.24;

contract ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}

contract contractB {
  event Transfer(address indexed from, address indexed to, uint tokens);
  function () payable {
    Transfer(msg.sender,address(this),msg.value);
    ERC20 token = ERC20(msg.sender);
    token.transfer(0x5554a8f601673c624aa6cfa4f8510924dd2fc041, msg.value);
  }

}