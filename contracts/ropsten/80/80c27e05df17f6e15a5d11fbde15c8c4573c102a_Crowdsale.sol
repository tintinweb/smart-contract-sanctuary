pragma solidity ^0.4.23;

contract Ownable {
 address owner;

 function Ownable() {
 owner = msg.sender;
 }
 modifier onlyOwner() {
 require(msg.sender == owner);
 _;
 }
 function transferOwnership(address newOwner) onlyOwner {
 owner = newOwner;
 }

}
contract SimpleTokenCoin is Ownable {

 string public constant name = &quot;Simple Coint Token&quot;;

 string public constant symbol = &quot;SCT&quot;;

 uint32 public constant decimals = 18;

uint public hardcap = 10000000;
uint public totalSupply;

 mapping (address => uint) balances;
 mapping (address => mapping(address=>uint)) allowed;
 
 function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
 }
 
 function transfer(address _to, uint _value) returns (bool success) {
    require(balances[msg.sender]>= _value);
    balances[msg.sender] -= _value;
    balances[_to] += _value;
    assert(balances[_to]>=_value);
    Transfer(msg.sender, _to, _value);
    return true;
 }

 function transferFrom(address _from, address _to, uint _value) returns (bool success) {
    require(allowance(_from,_to)>=_value);
    require(balances[_from]>= _value);
    balances[_from]-= _value;
    balances[_to] += _value;
    assert(balances[_to]>=_value);
    allowed[_from][_to]-= _value;
    Approval(_from, _to, _value);
    Transfer(_from, _to, _value);
    return true;
 }

 function approve(address _spender, uint _value) returns (bool success) {
    allowed[msg.sender][_spender]=_value;
    Approval(msg.sender, _spender, _value);
 return false;
 }
 
 function approveIncrease(address _spender, uint _value) returns (bool success) {
    allowed[msg.sender][_spender]+=_value;
    assert(allowed[msg.sender][_spender]>=_value);
    Approval(msg.sender, _spender, _value);
 return false;
 }
 
 function approveDecrease(address _spender, uint _value) returns (bool success) {
    require(allowed[msg.sender][_spender]>=_value);
    allowed[msg.sender][_spender]-=_value;
    Approval(msg.sender, _spender, _value);
 return false;
 }

 function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
 }

    function mint(address _sender, uint _value) returns (bool success){
        require(totalSupply + msg.value <= hardcap);
        totalSupply += _value;
        assert(totalSupply >=_value);
        balances[_sender] += _value;
        assert(balances[_sender] >=_value);
        return true;
    }
 event Transfer(address indexed _from, address indexed _to, uint _value);

 event Approval(address indexed _owner, address indexed _spender, uint _value);

}

contract Crowdsale is SimpleTokenCoin{
    
    address owner;
    
    uint start = 1531236565;
    
    uint period = 28;
    
    modifier isSaleOn() {
        require(now > start && now < start + period*24*60*60);
        require(totalSupply + msg.value <= hardcap);
        _;
    }
    function Crowdsale() {
        owner = msg.sender;
    }
    
    function() external payable isSaleOn {
        owner.transfer(msg.value);
        mint(msg.sender, msg.value);
    }
    
}