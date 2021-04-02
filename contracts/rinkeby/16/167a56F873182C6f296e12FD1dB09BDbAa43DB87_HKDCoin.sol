/**
 *Submitted for verification at Etherscan.io on 2021-04-02
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract HKDCoin is ERC20Interface {

    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it

    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

  constructor() public {
      name = "HKDCoin";
      symbol = "HKD";
      decimals = 18;
      _totalSupply = 100000000000000000000000000;

      balances[msg.sender] = _totalSupply;
      emit Transfer(address(0), msg.sender, _totalSupply);
    }

  function totalSupply() public view returns (uint) {
      return _totalSupply  - balances[address(0)];
    }

  function balanceOf(address tokenOwner) public view returns (uint balance) {
      return balances[tokenOwner];
    }

  function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
      return allowed[tokenOwner][spender];
    }

  function approve(address spender, uint tokens) public returns (bool success) {
      allowed[msg.sender][spender] = tokens;
      emit Approval(msg.sender, spender, tokens);
      return true;
    }

  function transfer(address to, uint tokens) public returns (bool success) {
      emit Transfer(msg.sender, to, tokens);
      return true;
    }

  function transferFrom(address from, address to, uint tokens) public returns (bool success) {
      emit Transfer(from, to, tokens);
      return true;
    }


}