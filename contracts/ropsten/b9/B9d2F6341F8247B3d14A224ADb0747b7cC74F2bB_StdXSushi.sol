/**
 *Submitted for verification at Etherscan.io on 2022-01-26
*/

// File: contracts/test/STDXSushi.sol

pragma solidity >=0.4.21 <0.6.0;

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}
contract ERC20Basic {
  uint public _totalSupply;
  function totalSupply() public view returns (uint);
  function balanceOf(address who) public view returns (uint);
  function transfer(address to, uint value) public returns(bool);
  event Transfer(address indexed from, address indexed to, uint value);

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint);
  function transferFrom(address from, address to, uint value) public returns(bool);
  function approve(address spender, uint value) public returns(bool);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract StdXSushi is ERC20, SafeMath{
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    address public token_issuer;
    string public announcement;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    constructor() public {
        symbol = "xSushi";
        name = "xSushi";
        decimals = 18;
        _totalSupply = 0;
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public returns(bool){
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns(bool){
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public  returns(bool){
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function issue(address account, uint num) public{
      if(account == address(0)) return ;

      balances[account] = safeAdd(balances[account], num);
      _totalSupply = safeAdd(_totalSupply, num);
      emit Transfer(address(0), account, num);
    }
}