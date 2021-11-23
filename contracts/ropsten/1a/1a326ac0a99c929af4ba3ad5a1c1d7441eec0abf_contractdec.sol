/**
 *Submitted for verification at Etherscan.io on 2021-11-23
*/

pragma solidity ^0.4.17;

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

contract contractdec {
  address tracker_0x_address = 0xf7ad4ed92b06234a1626551bfdb43342bbe5b30e; // ContractA Address
  mapping ( address => uint256 ) public balances;
  
  function deposit(address receiver,uint tokens) public {
        balances[msg.sender]+= tokens;
        ERC20(tracker_0x_address).transferFrom(msg.sender, receiver, tokens);
  }
  
  function returnTokens() public {
    uint256 amount = balances[msg.sender];
    balances[msg.sender] = 0;
    ERC20(tracker_0x_address).transfer(msg.sender, amount);
  }

}