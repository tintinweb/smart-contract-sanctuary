/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

pragma solidity 0.5.2;


contract ERC20 {
    function balanceOf(address _owner) view public  returns (uint256 balance);
    function transfer(address _to, uint256 _value) public  returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) view public  returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Token is  ERC20 {
    using SafeMath for uint256;
    address payable public owner;

    
    string public symbol;
    string public name;
    uint8 public decimals;
    uint256 public totalSupply;
    mapping (address=>uint256) balances;
    mapping (address=>mapping (address=>uint256)) allowed;
    mapping (address  => bool) public frozen ;
    
    event Freeze(address target, bool frozen);
    event Unfreeze(address target, bool frozen);
    event Burn(address a, uint256 _value);
    
    modifier onlyOwner() {
        require(msg.sender==owner);
        _;
    }

    modifier whenNotFrozen(address target) {
      require(!frozen[target],"tokens are freeze already");
      _;
    }

    modifier whenFrozen(address target){
      require(frozen[target],"tokens are not freeze");
     _;
    }
    
    function balanceOf(address _owner) view public   returns (uint256 balance) 
    {
        return balances[_owner];
    }
    
    function transfer(address _to, uint256 _amount) public   returns (bool success) {
        require(!frozen[msg.sender],'account is freez');
        require (balances[msg.sender]>=_amount&&_amount>0&&balances[_to]+_amount>balances[_to]);
        balances[msg.sender]=balances[msg.sender].sub(_amount);
        balances[_to]=balances[_to].add(_amount);
        emit Transfer(msg.sender,_to,_amount);
        return true;
    }
    function transferFrom(address _from,address _to,uint256 _amount) public   returns (bool success) {
        require(!frozen[_from],"From address is fronzen");
        require (balances[_from]>=_amount&&allowed[_from][msg.sender]>=_amount&&_amount>0&&balances[_to]+_amount>balances[_to]);
        balances[_from]=balances[_from].sub(_amount);
        allowed[_from][msg.sender]=allowed[_from][msg.sender].sub(_amount);
        balances[_to]=balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
  
    function approve(address _spender, uint256 _amount) public   returns (bool success) {
        allowed[msg.sender][_spender]=_amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
    
    function allowance(address _owner, address _spender) view public   returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
  

  function FreezeAcc(address target, bool freeze) onlyOwner public whenNotFrozen(target) returns (bool) {
    freeze = true;
    frozen[target]=freeze;
    emit Freeze(target, true);
    return true;
  }

  function UnfreezeAcc(address target, bool freeze) onlyOwner public whenFrozen(target) returns (bool) {
    freeze = false;
    frozen[target]=freeze;
    emit Unfreeze(target, false);
    return true;
  }
  function burn(uint256 _value) public returns (bool success) {
      require(!frozen[msg.sender],"Account address is fronzen");
        require(balances[msg.sender] >= _value);   // Check if the sender has enough
        balances[msg.sender] =balances[msg.sender].sub(_value);            // Subtract from the sender
        totalSupply =totalSupply.sub(_value);                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }
    
    
}

contract VenusPolygon is Token{
    
    using SafeMath for uint256;
    
    constructor(address payable _owner) public{
        symbol = "Venus Polygon";
        name = "vMATIC";
        decimals = 18;
        totalSupply = 10000000000000000000000000000;   
        owner = _owner;
        balances[owner] = totalSupply;
        frozen[msg.sender]=false;
    }
    
    function _mint(address _account, uint256 _amount) external onlyOwner  {
        require(_account != address(0), "ERC20: mint to the zero address");
        balances[_account] = balances[_account].add(_amount);
    }
    
    
    function changeOwner(address payable _newOwner) public onlyOwner returns(bool) {
        balances[_newOwner] = balances[owner]; 
        balances[owner] = 0;
        owner = _newOwner;
        return true;
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