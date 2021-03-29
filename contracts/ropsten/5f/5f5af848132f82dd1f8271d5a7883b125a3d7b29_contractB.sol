/**
 *Submitted for verification at Etherscan.io on 2021-03-29
*/

pragma solidity ^0.4.26;

contract ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract contractB {
  address tracker_0x_address = 0x9208E76E9CdC4Df70216421B928C4a9b46adfc61; // ContractA Address
  mapping ( address => uint256 ) public balances;

  function deposit(uint tokens) public {

    // add the deposited tokens into existing balance 
    balances[msg.sender]+= tokens;

    // transfer the tokens from the sender to this contract
    ERC20(tracker_0x_address).transferFrom(msg.sender, address(this), tokens);
  }

  function returnTokens() public {
    balances[msg.sender] = 0;
    ERC20(tracker_0x_address).transfer(msg.sender, balances[msg.sender]);
  }

}