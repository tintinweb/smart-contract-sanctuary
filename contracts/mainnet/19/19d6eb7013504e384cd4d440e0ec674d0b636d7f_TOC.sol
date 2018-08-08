pragma solidity ^0.4.16;

/*SPEND APPROVAL ALERT INTERFACE*/
interface tokenRecipient { 
function receiveApproval(address _from, uint256 _value, 
address _token, bytes _extraData) external; 
}

contract TOC {
/*tokenchanger.io*/

/*TOC TOKEN*/
string public name;
string public symbol;
uint8 public decimals;
uint256 public totalSupply;

/*user coin balance*/
mapping (address => uint256) public balances;
/*user coin allowances*/
mapping(address => mapping (address => uint256)) public allowed;

/*EVENTS*/		
/*broadcast token transfers on the blockchain*/
event Transfer(address indexed from, address indexed to, uint256 value);
/*broadcast token spend approvals on the blockchain*/
event Approval(address indexed _owner, address indexed _spender, uint _value);

/*MINT TOKEN*/
constructor() public {
name = "TokenChanger";
symbol = "TOC";
decimals = 18;
/*one billion base units*/
totalSupply = 10**27;
balances[msg.sender] = totalSupply; 
}

/*INTERNAL TRANSFER*/
function _transfer(address _from, address _to, uint _value) internal {    
/*prevent transfer to invalid address*/    
if(_to == 0x0) revert();
/*check if the sender has enough value to send*/
if(balances[_from] < _value) revert(); 
/*check for overflows*/
if(balances[_to] + _value < balances[_to]) revert();
/*compute sending and receiving balances before transfer*/
uint PreviousBalances = balances[_from] + balances[_to];
/*substract from sender*/
balances[_from] -= _value;
/*add to the recipient*/
balances[_to] += _value; 
/*check integrity of transfer operation*/
assert(balances[_from] + balances[_to] == PreviousBalances);
/*broadcast transaction*/
emit Transfer(_from, _to, _value); 
}

/*PUBLIC TRANSFERS*/
function transfer(address _to, uint256 _value) external returns (bool){
_transfer(msg.sender, _to, _value);
return true;
}

/*APPROVE THIRD PARTY SPENDING*/
function approve(address _spender, uint256 _value) public returns (bool success){
/*update allowance record*/    
allowed[msg.sender][_spender] = _value;
/*broadcast approval*/
emit Approval(msg.sender, _spender, _value); 
return true;                                        
}

/*THIRD PARTY TRANSFER*/
function transferFrom(address _from, address _to, uint256 _value) 
external returns (bool success) {
/*check if the message sender can spend*/
require(_value <= allowed[_from][msg.sender]); 
/*substract from message sender&#39;s spend allowance*/
allowed[_from][msg.sender] -= _value;
/*transfer tokens*/
_transfer(_from, _to, _value);
return true;
}

/*APPROVE SPEND ALLOWANCE AND CALL SPENDER*/
function approveAndCall(address _spender, uint256 _value, 
 bytes _extraData) external returns (bool success) {
tokenRecipient 
spender = tokenRecipient(_spender);
if(approve(_spender, _value)) {
spender.receiveApproval(msg.sender, _value, this, _extraData);
}
return true;
}

/*INVALID TRANSACTIONS*/
function () payable external{
revert();  
}
}/////////////////////////////////end of toc token contract