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
event BroadcastTransfer(address indexed from, address indexed to, uint256 value);
/*broadcast token spend approvals on the blockchain*/
event BroadcastApproval(address indexed _owner, address indexed _spender, uint _value);

/*MINT TOKEN*/
function TOC() public {
name = "TOC";
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
emit BroadcastTransfer(_from, _to, _value); 
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
emit BroadcastApproval(msg.sender, _spender, _value); 
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

}/////////////////////////////////end of toc token contract


pragma solidity ^0.4.16;
contract BlockPoints{
/////////////////////////////////////////////////////////    
///////(c)2017 tokenchanger.io -all rights reserved////// 
 
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

/*TOKEN VARIABLES*/
string public Name;
string public Symbol;
uint8 public Decimals;
uint256 public TotalSupply;

struct Global{
bool Suspend;
uint256 Rate;
}

struct DApps{
bool AuthoriseMint;
bool AuthoriseBurn;
bool AuthoriseRate;
}
 
struct Admin{
bool Authorised; 
uint256 Level;
}

struct Coloured{
uint256 Amount;
uint256 Rate;
}

struct AddressBook{
address TOCAddr;
}

struct Process{
uint256 n1;
uint256 n2;
uint256 n3;
uint256 n4;
uint256 n5;
}

/*INITIALIZE DATA STORES*/
Process pr;

/*global operational record*/
mapping (address => Global) public global;
/*user coin balances*/
mapping (address => uint256) public balances;
/*list of authorised dapps*/
mapping (address => DApps) public dapps;
/*special exchange rates for block points*/
mapping(address => mapping(address => Coloured)) public coloured;
/*list of authorised admins*/
mapping (address => Admin) public admin;
/*comms address book*/
mapping (address => AddressBook) public addressbook;


/*MINT FIRST TOKEN*/
function BlockPoints() public {
Name = &#39;BlockPoints&#39;;
Symbol = &#39;BKP&#39;;
Decimals = 0;
TotalSupply = 1;
balances[msg.sender] = TotalSupply; 
}

/*broadcast minting of tokens*/
event BrodMint(address indexed from, address indexed enduser, uint256 amount);
/*broadcast buring of tokens*/
event BrodBurn(address indexed from, address indexed enduser, uint256 amount);

/*RECEIVE APPROVAL & WITHDRAW TOC TOKENS*/
function receiveApproval(address _from, uint256 _value, 
address _token, bytes _extraData) external returns(bool){ 
TOC
TOCCall = TOC(_token);
TOCCall.transferFrom(_from,this,_value);
return true;
}

/*AUTHORISE ADMINS*/
function AuthAdmin (address _admin, bool _authority, uint256 _level) external 
returns(bool){
if((msg.sender != Mars) && (msg.sender != Mercury) && (msg.sender != Europa) &&
(msg.sender != Jupiter) && (msg.sender != Neptune)) revert();      
admin[_admin].Authorised = _authority;
admin[_admin].Level = _level;
return true;
}

/*ADD ADDRESSES TO ADDRESS BOOK*/
function AuthAddr(address _tocaddr) external returns(bool){
if(admin[msg.sender].Authorised == false) revert();
if(admin[msg.sender].Level < 3 ) revert();
addressbook[ContractAddr].TOCAddr = _tocaddr;
return true;
}

/*AUTHORISE DAPPS*/
function AuthDapps (address _dapp, bool _mint, bool _burn, bool _rate) external 
returns(bool){
if(admin[msg.sender].Authorised == false) revert();
if(admin[msg.sender].Level < 5) revert();
dapps[_dapp].AuthoriseMint = _mint;
dapps[_dapp].AuthoriseBurn = _burn;
dapps[_dapp].AuthoriseRate = _rate;
return true;
}

/*SUSPEND CONVERSIONS*/
function AuthSuspend (bool _suspend) external returns(bool){
if(admin[msg.sender].Authorised == false) revert();
if(admin[msg.sender].Level < 3) revert();
global[ContractAddr].Suspend = _suspend;
return true;
}

/*SET GLOBAL RATE*/
function SetRate (uint256 _globalrate) external returns(bool){
if(admin[msg.sender].Authorised == false) revert();
if(admin[msg.sender].Level < 5) revert();
global[ContractAddr].Rate = _globalrate;
return true;
}

/*LET DAPPS ALLOCATE SPECIAL EXCHANGE RATES*/
function SpecialRate (address _user, address _dapp, uint256 _amount, uint256 _rate) 
external returns(bool){
/*conduct integrity check*/    
if(dapps[msg.sender].AuthoriseRate == false) revert(); 
if(dapps[_dapp].AuthoriseRate == false) revert(); 
coloured[_user][_dapp].Amount += _amount;
coloured[_user][_dapp].Rate = _rate;
return true;
}


/*BLOCK POINTS REWARD*/
function Reward(address r_to, uint256 r_amount) external returns (bool){
/*conduct integrity check*/    
if(dapps[msg.sender].AuthoriseMint == false) revert(); 
/*mint block point for beneficiary*/
balances[r_to] += r_amount;
/*increase total supply*/
TotalSupply += r_amount;
/*broadcast mint*/
emit BrodMint(msg.sender,r_to,r_amount);     
return true;
}

/*GENERIC CONVERSION OF BLOCKPOINTS*/
function ConvertBkp(uint256 b_amount) external returns (bool){
/*conduct integrity check*/
require(global[ContractAddr].Suspend == false);
require(b_amount > 0);
require(global[ContractAddr].Rate > 0);
/*compute expected balance after conversion*/
pr.n1 = sub(balances[msg.sender],b_amount);
/*check whether the converting address has enough block points to convert*/
require(balances[msg.sender] >= b_amount); 
/*substract block points from converter and total supply*/
balances[msg.sender] -= b_amount;
TotalSupply -= b_amount;
/*determine toc liability*/
pr.n2 = mul(b_amount,global[ContractAddr].Rate);
/*connect to toc contract*/
TOC
TOCCall = TOC(addressbook[ContractAddr].TOCAddr);
/*check integrity of conversion operation*/
assert(pr.n1 == balances[msg.sender]);
/*send toc to message sender*/
TOCCall.transfer(msg.sender,pr.n2);
return true;
}

/*CONVERSION OF COLOURED BLOCKPOINTS*/
function ConvertColouredBkp(address _dapp) external returns (bool){
/*conduct integrity check*/
require(global[ContractAddr].Suspend == false);
require(coloured[msg.sender][_dapp].Rate > 0);
/*determine conversion amount*/
uint256 b_amount = coloured[msg.sender][_dapp].Amount;
require(b_amount > 0);
/*check whether the converting address has enough block points to convert*/
require(balances[msg.sender] >= b_amount); 
/*compute expected balance after conversion*/
pr.n3 = sub(coloured[msg.sender][_dapp].Amount,b_amount);
pr.n4 = sub(balances[msg.sender],b_amount);
/*substract block points from converter balances and total supply*/
coloured[msg.sender][_dapp].Amount -= b_amount;
balances[msg.sender] -= b_amount;
TotalSupply -= b_amount;
/*determine toc liability*/
pr.n5 = mul(b_amount,coloured[msg.sender][_dapp].Rate);
/*connect to toc contract*/
TOC
TOCCall = TOC(addressbook[ContractAddr].TOCAddr);
/*check integrity of conversion operation*/
assert(pr.n3 == coloured[msg.sender][_dapp].Amount);
assert(pr.n4 == balances[msg.sender]);
/*send toc to message sender*/
TOCCall.transfer(msg.sender,pr.n5);
return true;
}

/*BURN BLOCK POINTS*/
function Burn(address b_to, uint256 b_amount) external returns (bool){
/*check if dapp can burn blockpoints*/    
if(dapps[msg.sender].AuthoriseBurn == false) revert();    
/*check whether the burning address has enough block points to burn*/
require(balances[b_to] >= b_amount); 
/*substract blockpoints from burning address balance*/
balances[b_to] -= b_amount;
/*substract blockpoints from total supply*/
TotalSupply -= b_amount;
/*broadcast burning*/
emit BrodBurn(msg.sender, b_to,b_amount); 
return true;
}

/*SAFE MATHS*/
function mul(uint256 a, uint256 b) public pure returns (uint256) {
uint256 c = a * b;
assert(a == 0 || c / a == b);
return c;
  }
function sub(uint256 a, uint256 b) public pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }  
  
}///////////////////////////////////end of blockpoints contract