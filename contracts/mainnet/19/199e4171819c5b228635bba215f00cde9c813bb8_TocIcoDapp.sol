pragma solidity ^0.4.16;
contract TocIcoData{
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

struct State{
bool Suspend;    
bool PrivateSale;
bool PreSale;
bool MainSale; 
bool End;
}

struct Market{
uint256 EtherPrice;    
uint256 TocPrice;    
} 

struct Admin{
bool Authorised; 
uint256 Level;
}

/*contract state*/
mapping (address => State) public state;
/*market storage*/
mapping (address => Market) public market;
/*authorised admins*/
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

/*GENERAL PRICE UPDATE*/
function GeneralUpdate(uint256 _etherprice, uint256 _tocprice) external returns(bool){
/*integrity checks*/    
if(admin[msg.sender].Authorised == false) revert();
if(admin[msg.sender].Level < 5 ) revert();
/*update market record*/
market[ContractAddr].EtherPrice = _etherprice; 
market[ContractAddr].TocPrice = _tocprice;
return true;
}

/*UPDATE ETHER PRICE*/
function EtherPriceUpdate(uint256 _etherprice)external returns(bool){
/*integrity checks*/    
if(admin[msg.sender].Authorised == false) revert();
if(admin[msg.sender].Level < 5 ) revert();
/*update market record*/
market[ContractAddr].EtherPrice = _etherprice; 
return true;
}

/*UPDATE STATE*/
function UpdateState(uint256 _state) external returns(bool){
/*integrity checks*/    
if(admin[msg.sender].Authorised == false) revert();
if(admin[msg.sender].Level < 5 ) revert();
/*suspend sale state*/
if(_state == 1){
state[ContractAddr].Suspend = true;     
state[ContractAddr].PrivateSale = false; 
state[ContractAddr].PreSale = false;
state[ContractAddr].MainSale = false;
state[ContractAddr].End = false;
}
/*private sale state*/
if(_state == 2){
state[ContractAddr].Suspend = false;     
state[ContractAddr].PrivateSale = true; 
state[ContractAddr].PreSale = false;
state[ContractAddr].MainSale = false;
state[ContractAddr].End = false;
}
/*presale state*/
if(_state == 3){
state[ContractAddr].Suspend = false;    
state[ContractAddr].PrivateSale = false; 
state[ContractAddr].PreSale = true;
state[ContractAddr].MainSale = false;
state[ContractAddr].End = false;
}
/*main sale state*/
if(_state == 4){
state[ContractAddr].Suspend = false;    
state[ContractAddr].PrivateSale = false; 
state[ContractAddr].PreSale = false;
state[ContractAddr].MainSale = true;
state[ContractAddr].End = false;
}
/*end state*/
if(_state == 5){
state[ContractAddr].Suspend = false;    
state[ContractAddr].PrivateSale = false; 
state[ContractAddr].PreSale = false;
state[ContractAddr].MainSale = false;
state[ContractAddr].End = true;
}
return true;
}

/*GETTERS*/

/*get suspend state*/
function GetSuspend() public view returns (bool){
return state[ContractAddr].Suspend;
}
/*get private sale state*/
function GetPrivateSale() public view returns (bool){
return state[ContractAddr].PrivateSale;
}
/*get pre sale state*/
function GetPreSale() public view returns (bool){
return state[ContractAddr].PreSale;
}
/*get main sale state*/
function GetMainSale() public view returns (bool){
return state[ContractAddr].MainSale;
}
/*get end state*/
function GetEnd() public view returns (bool){
return state[ContractAddr].End;
}
/*get ether price*/
function GetEtherPrice() public view returns (uint256){
return market[ContractAddr].EtherPrice;
}
/*get toc price*/
function GetTocPrice() public view returns (uint256){
return market[ContractAddr].TocPrice;
}

}///////////////////////////////////end of icodata contract


pragma solidity ^0.4.16;
contract TocIcoDapp{
/////////////////////////////////////////////////////////    
///////(c)2017 tokenchanger.io -all rights reserved////// 
 
/*SUPER ADMINS*/
address Mars = 0x1947f347B6ECf1C3D7e1A58E3CDB2A15639D48Be;
address Mercury = 0x00795263bdca13104309Db70c11E8404f81576BE;
address Europa = 0x00e4E3eac5b520BCa1030709a5f6f3dC8B9e1C37;
address Jupiter = 0x2C76F260707672e240DC639e5C9C62efAfB59867;
address Neptune = 0xEB04E1545a488A5018d2b5844F564135211d3696;

/*GLOBAL VARIABLES*/
uint256 Converter = 10000;

/*CONTRACT ADDRESS*/
function GetContractAddr() public constant returns (address){
return this;
}	
address ContractAddr = GetContractAddr();

struct Buyer{
bool Withdrawn;    
uint256 TocBalance;
uint256 WithdrawalBlock;
uint256 Num;
}

struct Transaction{
uint256 Amount;
uint256 EtherPrice;
uint256 TocPrice;
uint256 Block;
}    

struct AddressBook{
address TOCAddr;
address DataAddr;
address Banker;
}

struct Admin{
bool Authorised; 
uint256 Level;
}

struct OrderBooks{
uint256 PrivateSupply;
uint256 PreSupply;
uint256 MainSupply;
}

/*buyer account*/
mapping (address => Buyer) public buyer;
/*buyer transactions*/
mapping(address => mapping(uint256 => Transaction)) public transaction;
/*order books store*/
mapping (address => OrderBooks) public orderbooks;
/*server address book*/
mapping (address => AddressBook) public addressbook;
/*authorised admins*/
mapping (address => Admin) public admin;

struct TA{
uint256 n1;
uint256 n2;
uint256 n3;
uint256 n4;
uint256 n5;
uint256 n6;
}

struct LA{
bool l1;
bool l2;
bool l3;
bool l4;
}

/*initialise process variables*/
TA ta;
LA la;

/*AUTHORISE ADMIN*/
function AuthAdmin(address _admin, bool _authority, uint256 _level) external 
returns(bool) {
if((msg.sender != Mars) && (msg.sender != Mercury) && (msg.sender != Europa)
&& (msg.sender != Jupiter) && (msg.sender != Neptune)) revert();  
admin[_admin].Authorised = _authority; 
admin[_admin].Level = _level;
return true;
} 

/*ADD ADDRESSES TO ADDRESS BOOK*/
function AuthAddr(address _tocaddr, address _dataddr, address _banker) 
external returns(bool){
/*integrity checks*/      
if(admin[msg.sender].Authorised == false) revert();
if(admin[msg.sender].Level < 5 ) revert();
/*update address record*/
addressbook[ContractAddr].TOCAddr = _tocaddr;
addressbook[ContractAddr].DataAddr = _dataddr;
addressbook[ContractAddr].Banker = _banker;
return true;
}

/*TOC SUPPLY OPERATIONS*/
function SupplyOp(uint256 _type, uint256 _stage, uint256 _amount) external returns (bool){
/*integrity checks*/    
if(admin[msg.sender].Authorised == false) revert();
if(admin[msg.sender].Level < 5 ) revert(); 
/*increase private sale supply*/
if((_type == 1) && (_stage == 1)){
orderbooks[ContractAddr].PrivateSupply += _amount; 
}
/*decrease private sale supply*/
if((_type == 0) && (_stage == 1)){
require(orderbooks[ContractAddr].PrivateSupply >= _amount);
orderbooks[ContractAddr].PrivateSupply -= _amount; 
}
/*increase presale supply*/
if((_type == 1) && (_stage == 2)){
orderbooks[ContractAddr].PreSupply += _amount; 
}
/*decrease presale supply*/
if((_type == 0) && (_stage == 2)){
require(orderbooks[ContractAddr].PreSupply >= _amount);    
orderbooks[ContractAddr].PreSupply -= _amount; 
}
/*increase main sale supply*/
if((_type == 1) && (_stage == 3)){
orderbooks[ContractAddr].MainSupply += _amount; 
}
/*decrease main sale supply*/
if((_type == 0) && (_stage == 3)){
require(orderbooks[ContractAddr].MainSupply >= _amount);    
orderbooks[ContractAddr].MainSupply -= _amount; 
}
return true;
}

/*CALCULATE TOC PURCHASED*/
function CalcToc(uint256 _etherprice, uint256 _tocprice, uint256 _deposit) 
internal returns (uint256){    
ta.n1 = mul(_etherprice, _deposit);
ta.n2 = div(ta.n1,_tocprice);
return ta.n2;
}

/*PRIVATE SALE*/
function PrivateSaleBuy() payable external returns (bool){
/*integrity checks*/    
if(msg.value <= 0) revert();
/*connect to ico data contract*/
TocIcoData
DataCall = TocIcoData(addressbook[ContractAddr].DataAddr);
/*get transaction information*/
la.l1 = DataCall.GetEnd();
la.l2 = DataCall.GetPrivateSale();
la.l3 = DataCall.GetSuspend();
ta.n3 = DataCall.GetEtherPrice();    
ta.n4 = DataCall.GetTocPrice();    
/*intergrity checks*/ 
if(la.l1 == true) revert();
if(la.l2 == false) revert();
if(la.l3 == true) revert();
/*calculate toc purchased & determine supply avaliability*/
ta.n5 = CalcToc(ta.n3, ta.n4, msg.value);
if(ta.n5 > orderbooks[ContractAddr].PrivateSupply) revert();
/*payments and delivery*/
addressbook[ContractAddr].Banker.transfer(msg.value);
/*update transaction records*/
orderbooks[ContractAddr].PrivateSupply -= ta.n5;
buyer[msg.sender].TocBalance += ta.n5;
buyer[msg.sender].Num += 1;
ta.n6 = buyer[msg.sender].Num; 
transaction[msg.sender][ta.n6].Amount = ta.n5;
transaction[msg.sender][ta.n6].EtherPrice = ta.n3;
transaction[msg.sender][ta.n6].TocPrice = ta.n4;
transaction[msg.sender][ta.n6].Block = block.number;
return true;
}    

/*PRESALE*/
function PreSaleBuy() payable external returns (bool){
/*integrity checks*/    
if(msg.value <= 0) revert();
/*connect to ico data contract*/
TocIcoData
DataCall = TocIcoData(addressbook[ContractAddr].DataAddr);
/*get transaction information*/
la.l1 = DataCall.GetEnd();
la.l2 = DataCall.GetPreSale();
la.l3 = DataCall.GetSuspend();
ta.n3 = DataCall.GetEtherPrice();    
ta.n4 = DataCall.GetTocPrice();    
/*intergrity checks*/ 
if(la.l1 == true) revert();
if(la.l2 == false) revert();
if(la.l3 == true) revert();
/*calculate toc purchased & determine supply avaliability*/
ta.n5 = CalcToc(ta.n3, ta.n4, msg.value);
if(ta.n5 > orderbooks[ContractAddr].PreSupply) revert();
/*payments and delivery*/
addressbook[ContractAddr].Banker.transfer(msg.value);
/*update transaction records*/
orderbooks[ContractAddr].PreSupply -= ta.n5;
buyer[msg.sender].TocBalance += ta.n5;
buyer[msg.sender].Num += 1;
ta.n6 = buyer[msg.sender].Num; 
transaction[msg.sender][ta.n6].Amount = ta.n5;
transaction[msg.sender][ta.n6].EtherPrice = ta.n3;
transaction[msg.sender][ta.n6].TocPrice = ta.n4;
transaction[msg.sender][ta.n6].Block = block.number;
return true;
}    

/*MAIN SALE*/
function MainSaleBuy() payable external returns (bool){
/*integrity checks*/    
if(msg.value <= 0) revert();
/*connect to ico data contract*/
TocIcoData
DataCall = TocIcoData(addressbook[ContractAddr].DataAddr);
/*get transaction information*/
la.l1 = DataCall.GetEnd();
la.l2 = DataCall.GetMainSale();
la.l3 = DataCall.GetSuspend();
ta.n3 = DataCall.GetEtherPrice();    
ta.n4 = DataCall.GetTocPrice();    
/*intergrity checks*/ 
if(la.l1 == true) revert();
if(la.l2 == false) revert();
if(la.l3 == true) revert();
/*calculate toc purchased & determine supply avaliability*/
ta.n5 = CalcToc(ta.n3, ta.n4, msg.value);
if(ta.n5 > orderbooks[ContractAddr].MainSupply) revert();
/*payments and delivery*/
addressbook[ContractAddr].Banker.transfer(msg.value);
/*update transaction records*/
orderbooks[ContractAddr].MainSupply -= ta.n5;
buyer[msg.sender].TocBalance += ta.n5;
buyer[msg.sender].Num += 1;
ta.n6 = buyer[msg.sender].Num; 
transaction[msg.sender][ta.n6].Amount = ta.n5;
transaction[msg.sender][ta.n6].EtherPrice = ta.n3;
transaction[msg.sender][ta.n6].TocPrice = ta.n4;
transaction[msg.sender][ta.n6].Block = block.number;
return true;
}    

/*WITHDRAW TOC TOKENS*/
function Withdraw() external returns (bool){
/*connect to ico data contract*/
TocIcoData
DataCall = TocIcoData(addressbook[ContractAddr].DataAddr);
/*get ico cycle information*/
la.l4 = DataCall.GetEnd();
/*integrity checks*/ 
if(la.l4 == false) revert();
if(buyer[msg.sender].TocBalance <= 0) revert();
if(buyer[msg.sender].Withdrawn == true) revert();
/*update buyer record*/
buyer[msg.sender].Withdrawn = true;
buyer[msg.sender].WithdrawalBlock = block.number;
/*connect to toc contract*/
TOC
TOCCall = TOC(addressbook[ContractAddr].TOCAddr);
/*check integrity before sending tokens*/
assert(buyer[msg.sender].Withdrawn == true);
/*send toc to message sender*/
TOCCall.transfer(msg.sender,buyer[msg.sender].TocBalance);
/*check integrity after sending tokens*/
assert(buyer[msg.sender].Withdrawn == true);
return true;
}  

/*RECEIVE APPROVAL & WITHDRAW TOC TOKENS*/
function receiveApproval(address _from, uint256 _value, 
address _token, bytes _extraData) external returns(bool){ 
TOC
TOCCall = TOC(_token);
TOCCall.transferFrom(_from,this,_value);
return true;
}

/*INVALID TRANSACTIONS*/
function () payable external{
revert();  
}

/*SAFE MATHS*/
function mul(uint256 a, uint256 b) public pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
function div(uint256 a, uint256 b) public pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }  
function sub(uint256 a, uint256 b) public pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
function add(uint256 a, uint256 b) public pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
 
}///////////////////////////////////end of icodapp contract


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