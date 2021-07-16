//SourceUnit: HighCoin (2).sol

pragma solidity ^0.5.10;


contract TRC20 {
    function balanceOf(address _owner) view public  returns (uint256 balance);
    function allowance(address _owner, address _spender) view public  returns (uint256 remaining);
    function transfer(address _to, uint256 _value) public  returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool success);
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Token is  TRC20 {
    
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
        require(msg.sender==owner,"TRC20: Not an owner");
        _;
    }

    modifier whenNotFrozen(address target) {
        require(!frozen[target],"TRC20: account is freeze already");
        _;
    }

    modifier whenFrozen(address target){
        require(frozen[target],"TRC20: account is not freeze");
        _;
    }
    
    function balanceOf(address _owner) view public returns (uint256 balance) 
    {
        return balances[_owner];
    }
    
    function allowance(address _owner, address _spender) view public returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    
    function getTotalSupply() public view returns(uint256){
        return totalSupply;
    }
    
    function transfer(address _to, uint256 _amount) public whenNotFrozen(msg.sender) returns (bool success) {
        require (balances[msg.sender] >= _amount, "TRC20: user balance is insufficient");
        require(_amount > 0, "TRC20: amount can not be zero");
        
        balances[msg.sender]=balances[msg.sender].sub(_amount);
        balances[_to]=balances[_to].add(_amount);
        emit Transfer(msg.sender,_to,_amount);
        return true;
    }
    function transferFrom(address _from,address _to,uint256 _amount) public whenNotFrozen(_from)  returns (bool success) {
        require(_amount > 0, "TRC20: amount can not be zero");
        require (balances[_from] >= _amount ,"TRC20: user balance is insufficient");
        require(allowed[_from][msg.sender] >= _amount, "TRC20: amount not approved");
        
        balances[_from]=balances[_from].sub(_amount);
        allowed[_from][msg.sender]=allowed[_from][msg.sender].sub(_amount);
        balances[_to]=balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
  
    function approve(address _spender, uint256 _amount) public whenNotFrozen(msg.sender) returns (bool success) {
        require(_spender != address(0), "TRC20: address can not be zero");
        require(balances[msg.sender] >= _amount ,"TRC20: user balance is insufficient");
        
        allowed[msg.sender][_spender]=_amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function FreezeAcc(address target) onlyOwner public whenNotFrozen(target) returns (bool) {
        frozen[target]=true;
        emit Freeze(target, true);
        return true;
    }

    function UnfreezeAcc(address target) onlyOwner public whenFrozen(target) returns (bool) {
        frozen[target]=false;
        emit Unfreeze(target, false);
        return true;
    }
    
    function burn(uint256 _value) public whenNotFrozen(msg.sender) returns (bool success) {
        require(balances[msg.sender] >= _value, "TRC20: user balance is insufficient");   
        
        balances[msg.sender] =balances[msg.sender].sub(_value);
        totalSupply =totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }
    
    
}

contract HighLink is Token{
    
    constructor(address payable _owner) public{
        symbol = "HighLink";
        name = "HL";
        decimals = 6;
        totalSupply = 10000000e6;   
        owner = _owner;
        balances[owner] = totalSupply;
        frozen[msg.sender]=false;
    }
    
    function _mint(address _user, uint256 _amount) external onlyOwner returns(bool) {
        require(_user != address(0), "TRC20: address can not be zero");
        
        balances[_user] = balances[_user].add(_amount);
        totalSupply = totalSupply.add(_amount);
        return true;
    }
    
    
    function changeOwner(address payable _newOwner) public onlyOwner returns(bool) {
        require(_newOwner != address(0), "TRC20: address can not be zero");
        balances[_newOwner] = balances[owner]; 
        balances[owner] = 0;
        owner = _newOwner;
        return true;
    }
    
    function changeName(string memory _newName) public onlyOwner returns(bool) {
        name = _newName;
        return true;
    }
    
    function changeSymbol(string memory _newSymbol) public onlyOwner returns(bool) {
        symbol = _newSymbol;
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