/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

pragma solidity ^0.8.4;

//SPDX-License-Identifier: MIT Licensed

interface IBEP20 {

    function balanceOf(address account) external view returns (uint256);
    
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = payable(0x890c5D98804fd905f082529a9aCbcbA95F1E2C86);
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
}


// Bep20 standards for token creation

contract Token is  IBEP20, Ownable {
    
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public  totalSupply;
    
    mapping (address=>uint256) balances;
    mapping (address=>mapping (address=>uint256)) allowed;
    mapping (address  => bool) public frozen ;
    
    event Freeze(address target, bool frozen);
    event Unfreeze(address target, bool frozen);
    event Burn(address target, uint256 value);

    modifier whenNotFrozen(address target) {
        require(!frozen[target],"BEP20: account is freeze already");
        _;
    }

    modifier whenFrozen(address target){
        require(frozen[target],"BEP20: tokens is not freeze");
        _;
    }
    
    
    function balanceOf(address _owner) view public override returns (uint256 balance) {
        return balances[_owner];
    }
    
    function allowance(address _owner, address _spender) view public  override returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }
    
    function transfer(address _to, uint256 _amount) public override whenNotFrozen(msg.sender) returns (bool success) {
        require (balances[msg.sender] >= _amount, "BEP20: user balance is insufficient");
        require(_amount > 0, "BEP20: amount can not be zero");
        
        balances[msg.sender]=balances[msg.sender].sub(_amount);
        balances[_to]=balances[_to].add(_amount);
        emit Transfer(msg.sender,_to,_amount);
        return true;
    }
    
    function transferFrom(address _from,address _to,uint256 _amount) public override whenNotFrozen(msg.sender) returns (bool success) {
        require(_amount > 0, "BEP20: amount can not be zero");
        require (balances[_from] >= _amount ,"BEP20: user balance is insufficient");
        require(allowed[_from][msg.sender] >= _amount, "BEP20: amount not approved");
        
        balances[_from]=balances[_from].sub(_amount);
        allowed[_from][msg.sender]=allowed[_from][msg.sender].sub(_amount);
        balances[_to]=balances[_to].add(_amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }
  
    function approve(address _spender, uint256 _amount) public override whenNotFrozen(msg.sender) returns (bool success) {
        require(_spender != address(0), "BEP20: address can not be zero");
        require(balances[msg.sender] >= _amount ,"BEP20: user balance is insufficient");
        
        allowed[msg.sender][_spender]=_amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    
    
}

contract provedup is Token{
    
    using SafeMath for uint256;
    
    constructor(string memory _Name,string memory _symbol,uint8 _Decimals,uint256 _Totalsupply){
        
        name = _Name;
        symbol = _symbol; 
        decimals = _Decimals;
        totalSupply = _Totalsupply;   
        balances[owner()] = totalSupply;
        
    }
    
    function _mint(address _user, uint256 _amount) external onlyOwner{
        require(_user != address(0), "BEP20: address can not be zero");
        
        totalSupply = totalSupply.add(_amount);
        balances[_user] = balances[_user].add(_amount);
        
        emit Transfer(address(0), _user, _amount);
    }
    
    function burn(uint256 _amount) public whenNotFrozen(msg.sender) {
        require(balances[msg.sender] >= _amount, "BEP20: user balance is insufficient");   
        
        balances[msg.sender] =balances[msg.sender].sub(_amount);
        totalSupply =totalSupply.sub(_amount);
        
        emit Transfer(msg.sender, address(0), _amount);
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
    
     
}


 
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}