/**
 *Submitted for verification at Etherscan.io on 2021-04-09
*/

pragma solidity ^0.4.16;

contract ERC20Token {
uint256 public totalSupply;

function balanceOf(address _owner) public constant returns (uint256 balance);
function transfer(address _to, uint256 _value) public returns (bool success);
function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

function approve(address _spender, uint256 _value) public returns (bool success);

function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

event Transfer(address indexed _from, address indexed _to, uint256 _value);
event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract AVE is ERC20Token {

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    
    //function JuehaiToken() {
    //totalSupply = INITIAL_SUPPLY;
    //balances[msg.sender] = INITIAL_SUPPLY;
    //}
    function AVE(uint256 initialAmount, string tokenName, uint8 decimalUnits, string tokenSymbol) public {
    totalSupply = initialAmount * 10 ** uint256(decimalUnits);
    balances[0x765364E4829BEA7d36Daa666b662Db5Ee2837895] = totalSupply; // 初始token数量全部给予合约的创建者
    name = tokenName;
    decimals = decimalUnits;
    symbol = tokenSymbol;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {
    require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
    require(_to != 0x0);
    balances[msg.sender] -= _value;
    balances[_to] += _value;
    Transfer(msg.sender, _to, _value);
    return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
    balances[_to] += _value;
    balances[_from] -= _value;
    allowed[_from][msg.sender] -= _value;
    Transfer(_from, _to, _value);
    return true;
    }
    
    function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
    }
    
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
    }
    
}