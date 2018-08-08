pragma solidity ^0.4.24;

contract ERC20 {
    function totalSupply() constant public returns (uint256 supply);
    function balanceOf(address _owner) constant public returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Token is ERC20 {
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 public totalSupply;
	address public owner;
    mapping (address=>uint256) balances;
    mapping (address=>mapping (address=>uint256)) allowed;
    
    function totalSupply() constant public returns (uint256 supply) {
        supply = totalSupply;
    }
    function balanceOf(address _owner) constant public returns (uint256 balance) {return balances[_owner];}
    
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require (balances[msg.sender]>=_amount&&_amount>0&&balances[_to]+_amount>balances[_to]);
        balances[msg.sender]-=_amount;
        balances[_to]+=_amount;
        emit Transfer(msg.sender,_to,_amount);
        return true;
    }
  
    function transferFrom(address _from,address _to,uint256 _amount) public returns (bool success) {
        require (balances[_from]>=_amount&&allowed[_from][msg.sender]>=_amount&&_amount>0&&balances[_to]+_amount>balances[_to]);
        balances[_from]-=_amount;
        allowed[_from][msg.sender]-=_amount;
        balances[_to]+=_amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }
  
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender]=_amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    function allowance(address _owner, address _spender) public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
}

contract GDC is Token{
    
    constructor() public{
        symbol = "GDC";
        name = "GOLDENCOIN";
        decimals = 4;
        totalSupply = 2000000000000;
        owner = msg.sender;
        balances[owner] = totalSupply;
    }
    
    function () payable public {
        revert();
    }
}