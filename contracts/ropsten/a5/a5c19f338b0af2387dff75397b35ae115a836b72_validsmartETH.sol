/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

pragma solidity ^0.4.17;

contract ERC20smartETH{
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract validsmartETH {
  address tracker_0x_address = 0xF7aD4ED92B06234a1626551BFdB43342Bbe5B30e; // ContractA Address
  mapping ( address => uint256 ) public balances;
  
  function deposit(uint tokens) public {

    // add the deposited tokens into existing balance 
    balances[msg.sender]+= tokens;

    // transfer the tokens from the sender to this contract
    ERC20smartETH(tracker_0x_address).transferFrom(msg.sender, address(this), tokens);
  }
  
  function returnTokens() public {
    uint256 amount = balances[msg.sender];
    balances[msg.sender] = 0;
    ERC20smartETH(tracker_0x_address).transfer(msg.sender, amount);
  }

}