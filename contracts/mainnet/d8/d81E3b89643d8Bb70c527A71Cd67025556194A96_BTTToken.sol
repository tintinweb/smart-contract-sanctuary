/**
 *Submitted for verification at Etherscan.io on 2021-05-30
*/

pragma solidity ^0.4.24;
 

//Safe Math Interface
 
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
 
 
//ERC Token Standard #20 Interface
 
contract ERC20Interface {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
  function approve(address _spender, uint256 _value) public returns (bool);
  function allowance(address _owner, address _spender) public view returns (uint256);
 
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
 
 
//Contract function to receive approval and execute function in one call
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}
 
//Actual token contract
 
contract BTTToken is ERC20Interface, SafeMath {
    string public symbol = "BTT";
    string public  name = "Bittwit Coin";
    uint8 public decimals = 2;
    uint public _totalSupply = 10000000000;
 
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
 
        constructor() public { 
        symbol = "BTTC";
        name = "Bittwit Coin";
        decimals = 2;
        _totalSupply = 10000000000;
        balances[0x850a4BEeA56CE344bE869fD233AE1e9667237559] = _totalSupply;
        emit Transfer(address(0), 0x850a4BEeA56CE344bE869fD233AE1e9667237559, _totalSupply);
    }
 
    function totalSupply() public constant returns (uint)  {
        return _totalSupply  - balances[address(0)];
    }
 
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }
 
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
 
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
 
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
 
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
 
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
 
    function () public payable {
        revert();
    }
}