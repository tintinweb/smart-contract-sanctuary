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
function TOC() public {
name = "Token Changer";
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

pragma solidity ^0.4.22;

contract AirdropDIST {
/*(c)2018 tokenchanger.io -all rights reserved*/

/*SUPER ADMINS*/
address Mars = 0x1947f347B6ECf1C3D7e1A58E3CDB2A15639D48Be;
address Mercury = 0x00795263bdca13104309Db70c11E8404f81576BE;
address Europa = 0x00e4E3eac5b520BCa1030709a5f6f3dC8B9e1C37;
address Jupiter = 0x2C76F260707672e240DC639e5C9C62efAfB59867;
address Neptune = 0xEB04E1545a488A5018d2b5844F564135211d3696;

/*CONTRACT ADDRESS*/
function GetContractAddr() public constant returns (address){
return this;
}	
address ContractAddr = GetContractAddr();


/*AIRDROP RECEPIENTS*/
struct Accounting{
bool Received;    
}

struct Admin{
bool Authorised; 
uint256 Level;
}

struct Config{
uint256 TocAmount;	
address TocAddr;
}

/*DATA STORAGE*/
mapping (address => Accounting) public account;
mapping (address => Config) public config;
mapping (address => Admin) public admin;

/*AUTHORISE ADMIN*/
function AuthAdmin(address _admin, bool _authority, uint256 _level) external 
returns(bool) {
if((msg.sender != Mars) && (msg.sender != Mercury) && (msg.sender != Europa)
&& (msg.sender != Jupiter) && (msg.sender != Neptune)) revert();  
admin[_admin].Authorised = _authority; 
admin[_admin].Level = _level;
return true;
} 

/*CONFIGURATION*/
function SetUp(uint256 _amount, address _tocaddr) external returns(bool){
/*integrity checks*/      
if(admin[msg.sender].Authorised == false) revert();
if(admin[msg.sender].Level < 5 ) revert();
/*update configuration records*/
config[ContractAddr].TocAmount = _amount;
config[ContractAddr].TocAddr = _tocaddr;
return true;
}

/*DEPOSIT TOC*/
function receiveApproval(address _from, uint256 _value, 
address _token, bytes _extraData) external returns(bool){ 
TOC
TOCCall = TOC(_token);
TOCCall.transferFrom(_from,this,_value);
return true;
}

/*WITHDRAW TOC*/
function Withdraw(uint256 _amount) external returns(bool){
/*integrity checks*/      
if(admin[msg.sender].Authorised == false) revert();
if(admin[msg.sender].Level < 5 ) revert();
/*withdraw TOC from this contract*/
TOC
TOCCall = TOC(config[ContractAddr].TocAddr);
TOCCall.transfer(msg.sender, _amount);
return true;
}

/*GET TOC*/
function Get() external returns(bool){
/*integrity check-1*/      
if(account[msg.sender].Received == true) revert();
/*change message sender received status*/
account[msg.sender].Received = true;
/*send TOC to message sender*/
TOC
TOCCall = TOC(config[ContractAddr].TocAddr);
TOCCall.transfer(msg.sender, config[ContractAddr].TocAmount);
/*integrity check-2*/      
assert(account[msg.sender].Received == true);
return true;
}

/*INVALID TRANSACTIONS*/
function () payable external{
revert();  
}

}////////////////////////////////end of AirdropDIST contract