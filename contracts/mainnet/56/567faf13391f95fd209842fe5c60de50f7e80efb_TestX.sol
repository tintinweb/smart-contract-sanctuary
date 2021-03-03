/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

// "SPDX-License-Identifier: UNLICENSED"

pragma solidity 0.7.4;

contract TestX {

using SafeMath for uint256;

string public constant symbol = "TestX";
string public constant name = "Tester X";
uint8 public constant decimals = 16;

uint256 _totalSupply;
address owner;

mapping(address => uint256) balances;
mapping(address => mapping (address => uint256)) allowances;

//Data
    string public companyName;
    uint256 public assetsTransactionCount;

    mapping(uint => _assetsTransaction) public assetsTransaction;

    struct _assetsTransaction {
        uint _id;
        
        string _dateTime;
        string _action;
        string _description;
        string _transactionValue;
        string _newGoodwill;
   }
constructor() {
    
    owner = msg.sender;
    _totalSupply = 1000000000 * 10 ** uint256(decimals);
    balances[owner] = _totalSupply;
    
    companyName = "Test AG";
    assetsTransactionCount = 0;
    assetsTransaction[0] = _assetsTransaction(0, "", "", "", "", "");
    
    emit Transfer(address(0), owner, _totalSupply);
}
function totalSupply() public view returns (uint256) {
   return _totalSupply;
}
function getOwner() public view returns (address) {
   return owner;
}
function balanceOf(address account) public view returns (uint256 balance) {
   return balances[account];
}
function transfer(address _to, uint256 _amount) public returns (bool success) {
    require(msg.sender != address(0), "ERC20: approve from the zero address");
    require(_to != address(0), "ERC20: approve from the zero address");
    require(balances[msg.sender] >= _amount);
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Transfer(msg.sender, _to, _amount);
    return true;
}
function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
    require(_from != address(0), "ERC20: approve from the zero address");
    require(_to != address(0), "ERC20: approve from the zero address");
    require(balances[_from] >= _amount && allowances[_from][msg.sender] >= _amount);
    balances[_from] = balances[_from].sub(_amount);
    allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Transfer(_from, _to, _amount);
    return true;
}
function approve(address spender, uint256 _amount) public returns (bool) {
    _approve(msg.sender, spender, _amount);
    return true;
}
function _approve(address _owner, address _spender, uint256 _amount) internal {
    require(_owner != address(0), "ERC20: approve from the zero address");
    require(_spender != address(0), "ERC20: approve to the zero address");
    allowances[_owner][_spender] = _amount;
    emit Approval(_owner, _spender, _amount);
    }
function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
   return allowances[_owner][_spender];
}

function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(msg.sender, spender, allowances[msg.sender][spender].sub(subtractedValue));
    return true;
}
function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, allowances[msg.sender][spender].add(addedValue));
        return true;
}
function burn(uint256 _amount) public returns (bool success) {
    require(_amount > 0, "ERC20: amount must be greater than zero");
    require(msg.sender == owner, "ERC20: only the owner can mint/generate new tokens");
    require(balances[owner] >= _amount,"ERC20: not enough tokens available");
 
    _totalSupply = _totalSupply.sub(_amount);
    balances[owner] = balances[owner].sub(_amount);

    emit Burned(owner, _amount);
    emit Transfer(owner, address(0), _amount);
   
   return true;
}
function addAssetsTransaction(string calldata _dateTime, string calldata _action,
                              string calldata _description, string calldata _transactionValue,
                              string calldata _newGoodwill) external {
    require(msg.sender == owner, "ERC20: only the owner can add Assets");
    assetsTransactionCount += 1;
    assetsTransaction[assetsTransactionCount] = 
        _assetsTransaction(assetsTransactionCount, _dateTime, _action, _description, _transactionValue, _newGoodwill);
}
function setCompanyName(string calldata _companyName) external {
        require(msg.sender == owner, "ERC20: only the owner can add Assets");
    companyName = _companyName;
}

event Transfer(address indexed _from, address indexed _to, uint256 _value);
event Approval(address indexed _owner, address indexed _spender, uint256 _value);
event Minted(address indexed _owner, uint256 _value);
event Burned(address indexed _owner, uint256 _value);

}

library SafeMath {
    
function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");
    return c;
}
function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;
    return c;
}
}