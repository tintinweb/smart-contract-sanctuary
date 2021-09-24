/**
 *Submitted for verification at BscScan.com on 2021-09-23
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

pragma solidity ^0.5.9;
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

contract Owned {
    modifier onlyOwner() {
        require(msg.sender==owner);
        _;
    }
    
    address payable owner;
    address payable newOwner;
    function changeOwner(address payable _newOwner) public onlyOwner {
        require(_newOwner!=address(0));
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        if (msg.sender==newOwner) {
            owner = newOwner;
        }
    }
}

contract ERC20 {
    uint256 public totalSupply;
    function balanceOf(address _owner) view public  returns (uint256 balance);
    function transfer(address _to, uint256 _value) public  returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) view public  returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract usdt is Owned,  ERC20 {
     using SafeMath for uint256;
    string public symbol;
    string public name;
    uint8 public decimals;
    mapping (address=>uint256) balances;
    mapping (address=>mapping (address=>uint256)) allowed;
    mapping (address  => bool) public frozen ;
    uint256 public taxFee=10;
    uint256 public liquidityFee;
    uint256 public marketeFee;
    uint256 public creatorFee;
    address public creatorWallet;
  
      event Freeze(address target, bool frozen);
      event Unfreeze(address target, bool frozen);
      event Burn(address a, uint256 _value);
      
      constructor() public{
        symbol = "usdt";
        name = "usdt";
        decimals = 6;
        totalSupply = 10000000000e6;   
        owner = msg.sender;
        balances[owner] = totalSupply;
        frozen[msg.sender]=false;
        
    }
    
    function () payable external {
        require(msg.value>0);
        owner.transfer(msg.value);
    }

  modifier whenNotFrozen(address target) {
    require(!frozen[target],"tokens are freeze already");
      _;
    }

  modifier whenFrozen(address target){
    require(frozen[target],"tokens are not freeze");
    _;
  }
  modifier onlyOwner(){
      require(msg.sender==owner,"you are not owner");
      _;
  }
    function balanceOf(address _owner) view public   returns (uint256 balance) {return balances[_owner];}
    
    function transfer(address _to, uint256 _amount) public   returns (bool success) {
        require(!frozen[msg.sender],'account is freez');
        require (balances[msg.sender]>=_amount&&_amount>0&&balances[_to].add(_amount)>balances[_to]);
        balances[msg.sender]=balances[msg.sender].sub(_amount);
        balances[_to]=balances[_to].add(_amount);
        emit Transfer(msg.sender,_to,_amount);
        return true;
    }
    function transferFrom(address _from,address _to,uint256 _amount) public   returns (bool success) {
        require(!frozen[_from],"From address is fronzen");
        require (balances[_from]>=_amount&&allowed[_from][msg.sender]>=_amount&&_amount>0&&balances[_to].add(_amount)>balances[_to]);
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
    
    function _mint(address account, uint256 amount) external onlyOwner  {
        require(account != address(0), "ERC20: mint to the zero address");
        balances[account] = balances[account].add(amount);
    }
    
    function setCreatorFee(uint256 _creatorFee)public onlyOwner returns(bool){
        creatorFee=_creatorFee;
        return true;
    }
    
    function setMarketFee(uint256 _marketFee)public onlyOwner returns(bool){
        marketeFee=_marketFee;
        return true;
    }
    
    function setLiquidityFee(uint256 _liquidityFee)public onlyOwner returns(bool){
        liquidityFee=_liquidityFee;
        return true;
    }
}