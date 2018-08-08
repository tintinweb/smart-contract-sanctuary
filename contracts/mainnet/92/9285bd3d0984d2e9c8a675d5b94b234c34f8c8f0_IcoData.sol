pragma solidity ^0.4.16;
contract IcoData{
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
bool PrivateSale;
bool PreSale;
bool MainSale; 
bool End;
}

struct Market{
uint256 EtherPrice;    
uint256 TocPrice;    
uint256 Commission;    
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
function GeneralUpdate(uint256 _etherprice, uint256 _tocprice, uint256 _commission) 
external returns(bool){
/*integrity checks*/    
if(admin[msg.sender].Authorised == false) revert();
if(admin[msg.sender].Level < 5 ) revert();
/*update market record*/
market[ContractAddr].EtherPrice = _etherprice; 
market[ContractAddr].TocPrice = _tocprice;
market[ContractAddr].Commission = _commission;
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
/*private sale state*/
if(_state == 1){
state[ContractAddr].PrivateSale = true; 
state[ContractAddr].PreSale = false;
state[ContractAddr].MainSale = false;
state[ContractAddr].End = false;
}
/*presale state*/
if(_state == 2){
state[ContractAddr].PrivateSale = false; 
state[ContractAddr].PreSale = true;
state[ContractAddr].MainSale = false;
state[ContractAddr].End = false;
}
/*main sale state*/
if(_state == 3){
state[ContractAddr].PrivateSale = false; 
state[ContractAddr].PreSale = false;
state[ContractAddr].MainSale = true;
state[ContractAddr].End = false;
}
/*end state*/
if(_state == 4){
state[ContractAddr].PrivateSale = false; 
state[ContractAddr].PreSale = false;
state[ContractAddr].MainSale = false;
state[ContractAddr].End = true;
}
return true;
}

/*GETTERS*/

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
/*get commission*/
function GetCommission() public view returns (uint256){
return market[ContractAddr].Commission;
}

}///////////////////////////////////end of icodata contract



pragma solidity ^0.4.16;
contract IcoDapp{
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

struct Promoters{
bool Registered;    
uint256 TotalCommission; 
}

struct PromoAdmin{
uint256 CurrentNum;
uint256 Max;    
}


/*buyer account*/
mapping (address => Buyer) public buyer;
/*buyer transactions*/
mapping(address => mapping(uint256 => Transaction)) public transaction;
/*order books store*/
mapping (address => OrderBooks) public orderbooks;
/*promoter store*/
mapping (address => Promoters) public promoters;
/*server address book*/
mapping (address => AddressBook) public addressbook;
/*administration of promoters*/
mapping (address => PromoAdmin) public promoadmin;
/*authorised admins*/
mapping (address => Admin) public admin;

struct TA{
uint256 n1;
uint256 n2;
uint256 n3;
uint256 n4;
uint256 n5;
uint256 n6;
uint256 n7;
uint256 n8;
uint256 n9;
uint256 n10;
uint256 n11;
}

struct LA{
bool l1;
bool l2;
bool l3;
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

/*CONFIGURE PROMOTERS*/
function ConfigPromoter(uint256 _max) external returns (bool){
/*integrity checks*/    
if(admin[msg.sender].Authorised == false) revert();
if(admin[msg.sender].Level < 5 ) revert();    
/*create promoter record*/    
promoadmin[ContractAddr].Max = _max; 
return true;
}

/*ADD PROMOTER*/
function AddPromoter(address _addpromoter) external returns (bool){
/*integrity checks*/    
if(admin[msg.sender].Authorised == false) revert();
if(admin[msg.sender].Level < 5 ) revert(); 
/*create promoter records*/    
promoters[_addpromoter].Registered = true;
promoters[_addpromoter].TotalCommission = 0;
promoadmin[ContractAddr].CurrentNum += 1;
return true;
}

/*REGISTER AS A PROMOTER*/
function Register(address _referrer) external returns (bool){
/*integrity checks*/ 
if(promoters[_referrer].Registered == false) revert();
if(promoters[msg.sender].Registered == true) revert();
if(promoadmin[ContractAddr].CurrentNum >= promoadmin[ContractAddr].Max) revert();
/*create promoter records*/    
promoters[msg.sender].Registered = true;
promoters[msg.sender].TotalCommission = 0; 
promoadmin[ContractAddr].CurrentNum += 1;
return true;
}

/*INCREASE PRIVATE SALE SUPPLY*/
function IncPrivateSupply(uint256 _privatesupply) external returns (bool){
/*integrity checks*/    
if(admin[msg.sender].Authorised == false) revert();
if(admin[msg.sender].Level < 5 ) revert();    
/*update private supply record*/    
orderbooks[ContractAddr].PrivateSupply += _privatesupply; 
return true;
}

/*INCREASE PRESALE SUPPLY*/
function IncPreSupply(uint256 _presupply) external returns (bool){
/*integrity checks*/    
if(admin[msg.sender].Authorised == false) revert();
if(admin[msg.sender].Level < 5 ) revert();    
/*update presale supply record*/    
orderbooks[ContractAddr].PreSupply += _presupply;
return true;
}

/*INCREASE MAINSALE SUPPLY*/
function IncMainSupply(uint256 _mainsupply) external returns (bool){
/*integrity checks*/    
if(admin[msg.sender].Authorised == false) revert();
if(admin[msg.sender].Level < 5 ) revert();    
/*update main sale supply record*/    
orderbooks[ContractAddr].MainSupply += _mainsupply;
return true;
}

/*CALCULATE COMMISSION*/
function RefCommission(uint256 _amount, uint256 _com) internal returns (uint256){
ta.n1 = mul(_amount, _com);
ta.n2 = div(ta.n1,Converter);
return ta.n2;
}

/*CALCULATE TOC PURCHASED*/
function CalcToc(uint256 _etherprice, uint256 _tocprice, uint256 _deposit) 
internal returns (uint256){    
ta.n3 = mul(_etherprice, _deposit);
ta.n4 = div(ta.n3,_tocprice);
return ta.n4;
}

/*PRIVATE SALE*/
function PrivateSaleBuy(address _referrer) payable external returns (bool){
/*integrity checks*/    
if(promoters[_referrer].Registered == false) revert();
if(msg.value <= 0) revert();
/*connect to ico data contract*/
IcoData
DataCall = IcoData(addressbook[ContractAddr].DataAddr);
/*get transaction information*/
la.l1 = DataCall.GetEnd();
la.l2 = DataCall.GetPrivateSale();
ta.n5 = DataCall.GetEtherPrice();    
ta.n6 = DataCall.GetTocPrice();    
ta.n7 = DataCall.GetCommission();    
/*intergrity checks*/    
if(la.l1 == true) revert();
if(la.l2 == false) revert();
/*calculate toc purchased & determine supply avaliability*/
ta.n8 = CalcToc(ta.n5, ta.n6, msg.value);
if(ta.n8 > orderbooks[ContractAddr].PrivateSupply) revert();
/*calculate referrer commission*/
ta.n9 = RefCommission(msg.value, ta.n7);
/*calculate net revenue*/
ta.n10 = sub(msg.value, ta.n9);
/*payments and delivery*/
addressbook[ContractAddr].Banker.transfer(ta.n10);
_referrer.transfer(ta.n9);
/*update transaction records*/
orderbooks[ContractAddr].PrivateSupply -= ta.n8;
buyer[msg.sender].TocBalance += ta.n8;
buyer[msg.sender].Num += 1;
ta.n11 = buyer[msg.sender].Num; 
transaction[msg.sender][ta.n11].Amount = ta.n8;
transaction[msg.sender][ta.n11].EtherPrice = ta.n5;
transaction[msg.sender][ta.n11].TocPrice = ta.n6;
transaction[msg.sender][ta.n11].Block = block.number;
promoters[_referrer].TotalCommission += ta.n9;
return true;
}    

/*PRESALE*/
function PreSaleBuy(address _referrer) payable external returns (bool){
/*integrity checks*/    
if(promoters[_referrer].Registered == false) revert();
if(msg.value <= 0) revert();
/*connect to ico data contract*/
IcoData
DataCall = IcoData(addressbook[ContractAddr].DataAddr);
/*get transaction information*/
la.l1 = DataCall.GetEnd();
la.l2 = DataCall.GetPreSale();
ta.n5 = DataCall.GetEtherPrice();    
ta.n6 = DataCall.GetTocPrice();    
ta.n7 = DataCall.GetCommission();    
/*intergrity checks*/    
if(la.l1 == true) revert();
if(la.l2 == false) revert();
/*calculate toc purchased & determine supply avaliability*/
ta.n8 = CalcToc(ta.n5, ta.n6, msg.value);
if(ta.n8 > orderbooks[ContractAddr].PreSupply) revert();
/*calculate referrer commission*/
ta.n9 = RefCommission(msg.value, ta.n7);
/*calculate net revenue*/
ta.n10 = sub(msg.value, ta.n9);
/*payments and delivery*/
addressbook[ContractAddr].Banker.transfer(ta.n10);
_referrer.transfer(ta.n9);
/*update transaction records*/
orderbooks[ContractAddr].PreSupply -= ta.n8;
buyer[msg.sender].TocBalance += ta.n8;
buyer[msg.sender].Num += 1;
ta.n11 = buyer[msg.sender].Num; 
transaction[msg.sender][ta.n11].Amount = ta.n8;
transaction[msg.sender][ta.n11].EtherPrice = ta.n5;
transaction[msg.sender][ta.n11].TocPrice = ta.n6;
transaction[msg.sender][ta.n11].Block = block.number;
promoters[_referrer].TotalCommission += ta.n9;
return true;
}    


/*MAIN SALE*/
function MainSaleBuy() payable external returns (bool){
/*integrity checks*/    
if(msg.value <= 0) revert();
/*connect to ico data contract*/
IcoData
DataCall = IcoData(addressbook[ContractAddr].DataAddr);
/*get transaction information*/
la.l1 = DataCall.GetEnd();
la.l2 = DataCall.GetMainSale();
ta.n5 = DataCall.GetEtherPrice();    
ta.n6 = DataCall.GetTocPrice();    
ta.n7 = DataCall.GetCommission();    
/*intergrity checks*/    
if(la.l1 == true) revert();
if(la.l2 == false) revert();
/*calculate toc purchased & determine supply avaliability*/
ta.n8 = CalcToc(ta.n5, ta.n6, msg.value);
if(ta.n8 > orderbooks[ContractAddr].MainSupply) revert();
/*payments and delivery*/
addressbook[ContractAddr].Banker.transfer(msg.value);
/*update transaction records*/
orderbooks[ContractAddr].MainSupply -= ta.n8;
buyer[msg.sender].TocBalance += ta.n8;
buyer[msg.sender].Num += 1;
ta.n9 = buyer[msg.sender].Num; 
transaction[msg.sender][ta.n9].Amount = ta.n8;
transaction[msg.sender][ta.n11].EtherPrice = ta.n5;
transaction[msg.sender][ta.n11].TocPrice = ta.n6;
transaction[msg.sender][ta.n9].Block = block.number;
return true;
}    

/*WITHDRAW TOC TOKENS*/
function Withdraw() external returns (bool){
/*connect to ico data contract*/
IcoData
DataCall = IcoData(addressbook[ContractAddr].DataAddr);
/*get ico cycle information*/
la.l3 = DataCall.GetEnd();
/*integrity checks*/ 
if(la.l3 == false) revert();
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