pragma solidity ^0.4.24;


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = 0x0B0eFad4aE088a88fFDC50BCe5Fb63c6936b9220;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and a
// fixed supply
// ----------------------------------------------------------------------------
contract FixedSupplyToken is ERC20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = &quot;DOTCH&quot;;
        name = &quot;Diamond Of The Crypto Hill&quot;;
        decimals = 0;
        _totalSupply = 10000000000;
        balances[this] = _totalSupply;
        emit Transfer(address(0),this, _totalSupply);
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }





    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}
interface HourglassInterface  {
    function() payable external;
    function buy(address _playerAddress) payable external returns(uint256);
    function sell(uint256 _amountOfTokens) external;
    function reinvest() external;
    function withdraw() external;
    function exit() external;
    function dividendsOf(address _playerAddress) external view returns(uint256);
    function balanceOf(address _playerAddress) external view returns(uint256);
    function transfer(address _toAddress, uint256 _amountOfTokens) external returns(bool);
    function stakingRequirement() external view returns(uint256);
}
contract Game is FixedSupplyToken {
    
//HourglassInterface constant P3Dcontract_ = HourglassInterface(0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe);    
struct Village {
    address owner;
    uint defending;
    uint lastcollect;
    uint beginnerprotection;
}
struct Variables {
    uint nextVillageId;
    uint bpamount;
    
    uint totalsupplyGOTCH;
    uint GOTCHatcontract;
    uint previousethamount;
    uint solsforhire;
    uint solslastupdate;
    uint soldierreplenishrate;
    uint soldierprice;
    uint lastblockpayout;
    uint blocksbeforenewpay;
    uint ATPO;
    uint nextpayamount;
    uint nextowneramount;
    
    
}
struct Ownables {
    address hillowner;
    uint soldiersdefendinghill; 
    mapping(address => uint256) soldiers;
    mapping(uint256 => Village) villages;
    mapping(address => uint256)  GOTCH;
    mapping(address => uint256)  redeemedvils;
    bool ERCtradeactive;
    uint roundlength;
    
}
struct Marketoffer{
    address placedby;
    uint256 amountdotch;
    uint256 wantsthisamtweiperdotch;
}

/*
uint public nextVillageId;  //next village int
uint public bpamount;       // beginner protection block amount
mapping(uint256 => Village) public villages;    //ownable by players
mapping(address => uint256) public GOTCH;   //convert to ERC at some point
uint public totalsupplyGOTCH; // totalsupplyGOTCH
uint public GOTCHatcontract; // GOTCH owned by the contract
mapping(address => uint256) public soldiers;// amount of soldiers owned
uint public solsforhire; // soldiers available to be bought at contract
uint public solslastupdate; //block number of last soldiers supply update
uint public soldierreplenishrate; //
uint public soldierprice;// price per soldier
uint public lastblockpayout; // block number last king payout happened
uint public blocksbeforenewpay;
uint public ATPO;//all time payout
uint public nextpayamount; // eth amount to be payed next payout
uint nextowneramount; // eth amount to be apyed to contract owner upon payout
uint previousethamount; //previous amount to calculate next payout
bool public ERCtradeactive;
address public hillowner; // adress of the hill owner
uint public soldiersdefendinghill; // number of soldiers defending the hill
*/
event villtakeover(address from, address to, uint villageint);
event hilltakeover(address from, address to);
event battle(address attacker, uint pointsattacker,  address defender, uint pointsdefender);
event dotchsale( address seller,uint price,  address taker , uint256 amount);
uint256 public ethforp3dbuy;
uint256 public round;
uint256 public nextmarketoffer;
uint256 public nextroundlength = 10000000000000000000000;
uint256 public nextroundtotalsupplyGOTCH = 10000;
uint256 public nextroundGOTCHatcontract = 10000;
uint256 public nextroundsolsforhire = 100;
uint256 public nextroundsoldierreplenishrate = 50;
uint256 public nextroundblocksbeforenewpay = 250;
bool public divsforall;
bool public nextroundERCtradeactive = true;
mapping(uint256 => Variables) public roundvars;
mapping(uint256 => Ownables) public roundownables; 
 mapping(address => uint256) public Redeemable;
 mapping(uint256 => Marketoffer) public marketplace;
 /*
function harvestabledivs()
        view
        public
        returns(uint256)
    {
        return ( P3Dcontract_.dividendsOf(address(this)))  ;
    }
*/
uint256 private div;
uint256 private ethtosend; 
 
function () external payable{} // needed to receive p3d divs

constructor () public {
    round++;
    roundvars[round].totalsupplyGOTCH = 10000;
       roundvars[round].GOTCHatcontract = 10000;
       roundvars[round].solsforhire = 100;
       roundvars[round].soldierreplenishrate = 50;
       roundvars[round].solslastupdate = block.number;
       updatesolbuyrate();
       roundvars[round].lastblockpayout = block.number;
       roundownables[round].hillowner = msg.sender;
       roundvars[round].nextpayamount = 0;
       roundvars[round].nextowneramount = 0;
       roundvars[round].previousethamount = 0;
       roundvars[round].blocksbeforenewpay = 250;
       roundownables[round].ERCtradeactive = true;
       roundownables[round].roundlength = 10000000000000000000000;
       divsforall = false;
    }
function hillpayout() internal  {
    require(block.number > roundvars[round].lastblockpayout.add(roundvars[round].blocksbeforenewpay));
    roundvars[round].lastblockpayout = roundvars[round].lastblockpayout.add(roundvars[round].blocksbeforenewpay);
    owner.transfer(roundvars[round].nextowneramount);
    roundownables[round].hillowner.transfer(roundvars[round].nextpayamount);
    roundvars[round].ATPO = roundvars[round].ATPO.add(roundvars[round].nextpayamount);
     
    roundvars[round].nextpayamount = (this.balance.sub(roundvars[round].previousethamount).add(roundvars[round].previousethamount.div(10))).div(2);//
    ethforp3dbuy = ethforp3dbuy.add(roundvars[round].nextpayamount.div(100));
    roundvars[round].nextowneramount = roundvars[round].nextpayamount.div(100);// 
    roundvars[round].previousethamount = this.balance.sub(roundvars[round].nextpayamount).sub(roundvars[round].nextowneramount).sub(ethforp3dbuy);
    
}
function attackhill(uint256 amtsoldiers) public payable returns(bool, uint){
    require(msg.value >= 1 finney);
    if(block.number > roundvars[round].lastblockpayout.add(roundvars[round].blocksbeforenewpay))
    {
    hillpayout();
    }
    
    require(amtsoldiers <= roundownables[round].soldiers[msg.sender]);
    require(amtsoldiers >= 1);
    if(msg.sender == roundownables[round].hillowner)
{
   roundownables[round].soldiersdefendinghill = roundownables[round].soldiersdefendinghill.add(amtsoldiers);
    roundownables[round].soldiers[msg.sender] = roundownables[round].soldiers[msg.sender].sub(amtsoldiers);
    return (false, 0);
}
if(msg.sender != roundownables[round].hillowner)
{
   if(roundownables[round].soldiersdefendinghill < amtsoldiers)
    {
        emit hilltakeover(roundownables[round].hillowner,msg.sender);
        emit battle(msg.sender,roundownables[round].soldiersdefendinghill,roundownables[round].hillowner,roundownables[round].soldiersdefendinghill);
        roundownables[round].hillowner = msg.sender;
        roundownables[round].soldiersdefendinghill = amtsoldiers.sub(roundownables[round].soldiersdefendinghill);
        roundownables[round].soldiers[msg.sender] = roundownables[round].soldiers[msg.sender].sub(amtsoldiers);
        return (true, roundownables[round].soldiersdefendinghill);
    }
    if(roundownables[round].soldiersdefendinghill >= amtsoldiers)
    {
        roundownables[round].soldiersdefendinghill = roundownables[round].soldiersdefendinghill.sub(amtsoldiers);
        roundownables[round].soldiers[msg.sender] = roundownables[round].soldiers[msg.sender].sub(amtsoldiers);
        emit battle(msg.sender,amtsoldiers,roundownables[round].hillowner,amtsoldiers);
        return (false, amtsoldiers);
    }
}

}
function supporthill(uint256 amtsoldiers) public payable {
    require(msg.value >= 1 finney);
    require(amtsoldiers <= roundownables[round].soldiers[msg.sender]);
    require(amtsoldiers >= 1);
   roundownables[round].soldiersdefendinghill = roundownables[round].soldiersdefendinghill.add(amtsoldiers);
   roundownables[round].soldiers[msg.sender] = roundownables[round].soldiers[msg.sender].sub(amtsoldiers);  
}

function changetradestatus(bool active) public onlyOwner  {
   //move all eth from contract to owners address
   roundownables[round].ERCtradeactive = active;
   
}
function setdivsforall(bool active) public onlyOwner  {
   //move all eth from contract to owners address
   divsforall = active;
   
}
function changebeginnerprotection(uint256 blockcount) public onlyOwner  {
   roundvars[round].bpamount = blockcount;
}
function changesoldierreplenishrate(uint256 rate) public onlyOwner  {
   roundvars[round].soldierreplenishrate = rate;
}
function updatesolsforhire() internal  {
   roundvars[round].solsforhire = roundvars[round].solsforhire.add((block.number.sub(roundvars[round].solslastupdate)).mul(roundvars[round].nextVillageId).mul(roundvars[round].soldierreplenishrate));
   roundvars[round].solslastupdate = block.number;
}
function updatesolbuyrate() internal  {
if(roundvars[round].solsforhire > roundvars[round].totalsupplyGOTCH)
   {
        roundvars[round].solsforhire = roundvars[round].totalsupplyGOTCH;
   }
   roundvars[round].soldierprice = roundvars[round].totalsupplyGOTCH.div(roundvars[round].solsforhire);
   if(roundvars[round].soldierprice < 1)
   {
       roundvars[round].soldierprice = 1;
   }
}
function buysoldiers(uint256 amount) public payable {
    require(msg.value >= 1 finney);
   updatesolsforhire();
   updatesolbuyrate() ;
   require(amount <= roundvars[round].solsforhire);
   
   roundownables[round].soldiers[msg.sender] = roundownables[round].soldiers[msg.sender].add(amount);
   roundvars[round].solsforhire = roundvars[round].solsforhire.sub(amount);
   roundownables[round].GOTCH[msg.sender] = roundownables[round].GOTCH[msg.sender].sub( amount.mul(roundvars[round].soldierprice));
   roundvars[round].GOTCHatcontract = roundvars[round].GOTCHatcontract.add(amount.mul(roundvars[round].soldierprice));
   
}
// found new villgage 
function createvillage() public  payable  {
    require(msg.value >= 10 finney);
    if(block.number > roundvars[round].lastblockpayout.add(roundvars[round].blocksbeforenewpay))
    {
    hillpayout();
    }
    
    roundownables[round].villages[roundvars[round].nextVillageId].owner = msg.sender;
    
   roundownables[round].villages[roundvars[round].nextVillageId].lastcollect = block.number;
    roundownables[round].villages[roundvars[round].nextVillageId].beginnerprotection = block.number;
    roundvars[round].nextVillageId ++;
   
    roundownables[round].villages[roundvars[round].nextVillageId].defending = roundvars[round].nextVillageId;
    Redeemable[msg.sender]++;
    roundownables[round].redeemedvils[msg.sender]++;
}
function cheapredeemvillage() public  payable  {
    require(msg.value >= 1 finney);
    require(roundownables[round].redeemedvils[msg.sender] < Redeemable[msg.sender]);
    roundownables[round].villages[roundvars[round].nextVillageId].owner = msg.sender;
    roundownables[round].villages[roundvars[round].nextVillageId].lastcollect = block.number;
    roundownables[round].villages[roundvars[round].nextVillageId].beginnerprotection = block.number;
    roundvars[round].nextVillageId ++;
    roundownables[round].villages[roundvars[round].nextVillageId].defending = roundvars[round].nextVillageId;
    roundownables[round].redeemedvils[msg.sender]++;
}
function preregvills(address reg) public onlyOwner  {

    roundownables[round].villages[roundvars[round].nextVillageId].owner = reg;
    roundownables[round].villages[roundvars[round].nextVillageId].lastcollect = block.number;
    roundownables[round].villages[roundvars[round].nextVillageId].beginnerprotection = block.number;
    roundvars[round].nextVillageId ++;
    roundownables[round].villages[roundvars[round].nextVillageId].defending = roundvars[round].nextVillageId;
}
function attack(uint256 village, uint256 amtsoldiers) public payable returns(bool, uint){
    require(msg.value >= 1 finney);
    if(block.number > roundvars[round].lastblockpayout + roundvars[round].blocksbeforenewpay)
    {
    hillpayout();
    }
   
    uint bpcheck = roundownables[round].villages[village].beginnerprotection.add(roundvars[round].bpamount);
    require(block.number > bpcheck);
    require(roundownables[round].villages[village].owner != 0);// prevent from attacking a non-created village to create a village
    require(amtsoldiers <= roundownables[round].soldiers[msg.sender]);
    require(amtsoldiers >= 1);
    
if(msg.sender == roundownables[round].villages[village].owner)
{
    roundownables[round].villages[village].defending = roundownables[round].villages[village].defending.add(amtsoldiers);
    roundownables[round].soldiers[msg.sender] = roundownables[round].soldiers[msg.sender].sub(amtsoldiers);
    return (false, 0);
}
if(msg.sender != roundownables[round].villages[village].owner)
{
   if(roundownables[round].villages[village].defending < amtsoldiers)
    {
        emit battle(msg.sender,roundownables[round].villages[village].defending,roundownables[round].villages[village].owner,roundownables[round].villages[village].defending);
        emit villtakeover(roundownables[round].villages[village].owner,msg.sender,village);
        roundownables[round].villages[village].owner = msg.sender;
        roundownables[round].villages[village].defending = amtsoldiers.sub(roundownables[round].villages[village].defending);
        roundownables[round].soldiers[msg.sender] = roundownables[round].soldiers[msg.sender].sub(amtsoldiers);
        collecttaxes(village);
        return (true, roundownables[round].villages[village].defending);
        
    }
    if(roundownables[round].villages[village].defending >= amtsoldiers)
    {
        emit battle(msg.sender,amtsoldiers,roundownables[round].villages[village].owner,amtsoldiers);
        roundownables[round].villages[village].defending = roundownables[round].villages[village].defending.sub(amtsoldiers);
        roundownables[round].soldiers[msg.sender] = roundownables[round].soldiers[msg.sender].sub(amtsoldiers);
        return (false, amtsoldiers);
    }
}

}
function support(uint256 village, uint256 amtsoldiers) public payable {
    require(msg.value >= 1 finney);
    require(roundownables[round].villages[village].owner != 0);// prevent from supporting a non-created village to create a village
    require(amtsoldiers <= roundownables[round].soldiers[msg.sender]);
    require(amtsoldiers >= 1);
    roundownables[round].villages[village].defending = roundownables[round].villages[village].defending.add(amtsoldiers);
    roundownables[round].soldiers[msg.sender] = roundownables[round].soldiers[msg.sender].sub(amtsoldiers);  
}
function renewbeginnerprotection(uint256 village) public payable {
    require(msg.value >= (roundvars[round].nextVillageId.sub(village)).mul(1 finney) );//
    roundownables[round].villages[village].beginnerprotection = block.number;
   
}
function collecttaxes(uint256 village) public payable returns (uint){// payed transaction
    // 
   require(msg.value >= 1 finney);
    if(block.number > roundvars[round].lastblockpayout.add(roundvars[round].blocksbeforenewpay))
    {
    hillpayout();
    }
    
    require(roundownables[round].villages[village].owner == msg.sender);
    require(block.number >  roundownables[round].villages[village].lastcollect);
    var test = (block.number.sub(roundownables[round].villages[village].lastcollect)).mul((roundvars[round].nextVillageId.sub(village)));
    if(roundvars[round].GOTCHatcontract < test ) 
    {
     roundvars[round].GOTCHatcontract =  roundvars[round].GOTCHatcontract.add(test);
     roundvars[round].totalsupplyGOTCH = roundvars[round].totalsupplyGOTCH.add(test);
    }   
    roundownables[round].GOTCH[msg.sender] = roundownables[round].GOTCH[msg.sender].add(test);
    roundvars[round].GOTCHatcontract = roundvars[round].GOTCHatcontract.sub(test);
    
    roundownables[round].villages[village].lastcollect = block.number;
    // if contract doesnt have the amount, create new
    return test;
}
function sellDOTCH(uint amt) payable public {
    require(msg.value >= 1 finney);
    require(roundownables[round].ERCtradeactive == true);
    require(roundownables[round].GOTCH[this]>= amt.mul(10000));
    require(balances[msg.sender] >=  amt);
    require(amt >= 1);
    balances[this] = balances[this].add(amt);
    balances[msg.sender] = balances[msg.sender].sub(amt);
    emit Transfer(msg.sender,this, amt);
    roundownables[round].GOTCH[this] =  roundownables[round].GOTCH[this].sub(amt.mul(10000));
}
function buyDOTCH(uint amt) payable public {
    require(msg.value >= 1 finney);
    require(roundownables[round].ERCtradeactive == true);
    require(balances[this]>= amt);
    require(roundownables[round].GOTCH[msg.sender] >= amt.mul(10000));
    require(amt >= 1);
    balances[this] = balances[this].sub(amt);
    balances[msg.sender] = balances[msg.sender].add(amt);
    emit Transfer(this,msg.sender, amt);
   roundownables[round].GOTCH[msg.sender] = roundownables[round].GOTCH[msg.sender].sub(amt.mul(10000));
  
}
//p3d 
/*
function buyp3d(uint256 amt) internal{
P3Dcontract_.buy.value(amt)(this);
}
function claimdivs() internal{
P3Dcontract_.withdraw();
}
event onHarvest(
        address customerAddress,
        uint256 amount
    );

function Divs() public payable{
    
    require(msg.sender == roundownables[round].hillowner);
    require(msg.value >= 1 finney);
    div = harvestabledivs();
    require(div > 0);
    claimdivs();
    msg.sender.transfer(div);
    emit onHarvest(msg.sender,div);
}
function Divsforall() public payable{
    
    require(divsforall = true);
    require(msg.value >= 1 finney);
    div = harvestabledivs();
    require(div > 0);
    claimdivs();
    msg.sender.transfer(div);
    emit onHarvest(msg.sender,div);
}
function Expand() public {
    buyp3d(ethforp3dbuy);
    ethforp3dbuy = 0;
}*/
function launchnewround() public {
    require(roundvars[round].ATPO >= roundownables[round].roundlength);
    round++;
}
//marketplace functions
function placeoffer(uint256 dotchamount, uint256 askingpriceinwei) payable public{
    require(dotchamount > 0);
    require(askingpriceinwei > 0);
    require(balances[msg.sender] >=  dotchamount);
    require(msg.value >= 1 finney);
    balances[msg.sender] = balances[msg.sender].sub(dotchamount);
    balances[this] = balances[this].add(dotchamount);
    emit Transfer(msg.sender,this, dotchamount);
    marketplace[nextmarketoffer].placedby = msg.sender;
     marketplace[nextmarketoffer].amountdotch = dotchamount;
      marketplace[nextmarketoffer].wantsthisamtweiperdotch = askingpriceinwei;
      nextmarketoffer++;
}
function adddotchtooffer(uint256 ordernumber , uint256 dotchamount) public
{
    require(dotchamount > 0);
    require(msg.sender == marketplace[ordernumber].placedby);
    require(balances[msg.sender] >=  dotchamount);
 
    balances[msg.sender] = balances[msg.sender].sub(dotchamount);
    balances[this] = balances[this].add(dotchamount);
    emit Transfer(msg.sender,this, dotchamount);
     marketplace[ordernumber].amountdotch = marketplace[ordernumber].amountdotch.add(dotchamount);
}
function removedotchtooffer(uint256 ordernumber , uint256 dotchamount) public
{
    require(dotchamount > 0);
    require(msg.sender == marketplace[ordernumber].placedby);
    require(balances[this] >=  dotchamount);
 
    balances[msg.sender] = balances[msg.sender].add(dotchamount);
    balances[this] = balances[this].sub(dotchamount);
    emit Transfer(this,msg.sender, dotchamount);
     marketplace[ordernumber].amountdotch = marketplace[ordernumber].amountdotch.sub(dotchamount);
}
function offerchangeprice(uint256 ordernumber ,uint256 price ) public
{
    require(price > 0);
    require(msg.sender == marketplace[ordernumber].placedby);
     marketplace[ordernumber].wantsthisamtweiperdotch = price;
}
function takeoffer(uint256 ordernumber ,uint256 amtdotch ) public payable
{
    require(msg.value >= marketplace[ordernumber].wantsthisamtweiperdotch.mul(amtdotch));
    require(amtdotch > 0);
    require(marketplace[ordernumber].amountdotch >= amtdotch);
    require(msg.sender != marketplace[ordernumber].placedby);
    require(balances[this] >=  amtdotch);
     marketplace[ordernumber].amountdotch = marketplace[ordernumber].amountdotch.sub(amtdotch);
     balances[msg.sender] = balances[msg.sender].add(amtdotch);
    balances[this] = balances[this].sub(amtdotch);
    emit Transfer(this,msg.sender, amtdotch);
    emit dotchsale(marketplace[ordernumber].placedby,marketplace[ordernumber].wantsthisamtweiperdotch, msg.sender, amtdotch);
    marketplace[ordernumber].placedby.transfer(marketplace[ordernumber].wantsthisamtweiperdotch.mul(amtdotch));
}
// new round function
function startnewround() public {
    require(roundvars[round].ATPO > roundownables[round].roundlength);
    round++;
    roundvars[round].totalsupplyGOTCH = nextroundtotalsupplyGOTCH;
       roundvars[round].GOTCHatcontract = nextroundtotalsupplyGOTCH;
       roundvars[round].solsforhire = nextroundsolsforhire;
       roundvars[round].soldierreplenishrate = nextroundsoldierreplenishrate;
       roundvars[round].solslastupdate = block.number;
       updatesolbuyrate();
       roundvars[round].lastblockpayout = block.number;
       roundownables[round].hillowner = msg.sender;
       roundvars[round].nextpayamount = roundvars[round-1].nextpayamount;
       roundvars[round].nextowneramount = roundvars[round-1].nextowneramount;
       roundvars[round].previousethamount = roundvars[round-1].previousethamount;
       roundvars[round].blocksbeforenewpay = nextroundblocksbeforenewpay;
       roundownables[round].ERCtradeactive = nextroundERCtradeactive;
    
}

}