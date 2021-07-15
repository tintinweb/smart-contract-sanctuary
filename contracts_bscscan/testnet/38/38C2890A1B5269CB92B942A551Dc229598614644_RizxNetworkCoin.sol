/**
 *Submitted for verification at BscScan.com on 2021-07-15
*/

pragma solidity ^0.8.4;

contract RizxNetworkCoin {
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowances;


    uint256 private totalSupply;
    uint8 private decimals;
    string private symbol;
    string private name;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor() {

        name = "RIZX Network";
        symbol = "RXC";
        decimals = 18;
        totalSupply = 100000000 * 10 ** 18;
        balances[msg.sender] = totalSupply;


    }

    function balanceOf(address owner) public view returns (uint) {
        return balances[owner];
    }

    function transfer(address to, uint value) public returns (bool) {
      require(balanceOf(msg.sender) >= value, 'balance too low');
      balances[to] += value;
      balances[msg.sender] -= value;
      emit Transfer(msg.sender, to, value);
      return true;
    }

    function allowance(address owner, address spender) public view returns (uint) {
        return allowances[owner][spender];
    }

    function transferFrom(address from, address to, uint value) public returns(bool) {
      require(balanceOf(from) >= value, 'balance too low');
      require(allowances[from][msg.sender] >= value, 'allowance too low');
      balances[to] += value;
      balances[from] -= value;
      emit Transfer(from, to, value);
      return true;
    }

    function approve(address spender, uint value) public returns(bool) {
      allowances[msg.sender][spender] = value;
      emit Approval(msg.sender, spender, value);
        return true;
    }


}