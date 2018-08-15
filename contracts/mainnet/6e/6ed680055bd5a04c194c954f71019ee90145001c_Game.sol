pragma solidity ^0.4.24;
// King of the Crypto Hill contract by Spielley
// P3D contract designed by TEAM JUST and here integrated for dividend payout purpose, not active in testnet version.
// See P3D proof of concept at : https://divgarden.dvx.me/
// Or look at it&#39;s code at: https://etherscan.io/address/0xdaa282aba7f4aa757fac94024dfb89f8654582d3#code
// any derivative of KOTCH is allowed if:
// - 1% additional on payouts happen to original KOTCH contract creator&#39;s eth account: 0x0B0eFad4aE088a88fFDC50BCe5Fb63c6936b9220
// - contracts are not designed or used to scam people or mallpractices
// This game is intended for fun, Spielley is not liable for any bugs the contract may contain. 
// Don&#39;t play with crypto you can&#39;t afford to lose



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
        symbol = "DOTCH";
        name = "Diamond Of The Crypto Hill";
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
    
HourglassInterface constant P3Dcontract_ = HourglassInterface(0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe);    
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

function harvestabledivs()
        view
        public
        returns(uint256)
    {
        return ( P3Dcontract_.dividendsOf(address(this)))  ;
    }

function villageinfo(uint256 lookup)
        view
        public
        returns(address owner, uint256 soldiersdefending,uint256 lastcollect,uint256 beginnersprotection)
    {
        return ( roundownables[round].villages[lookup].owner,roundownables[round].villages[lookup].defending,roundownables[round].villages[lookup].lastcollect,roundownables[round].villages[lookup].beginnerprotection)  ;
    }
function gotchinfo(address lookup)
        view
        public
        returns(uint256 Gold)
    {
        return ( roundownables[round].GOTCH[lookup])  ;
    }
function soldiersinfo(address lookup)
        view
        public
        returns(uint256 soldiers)
    {
        return ( roundownables[round].soldiers[lookup])  ;
    } 
function redeemablevilsinfo(address lookup)
        view
        public
        returns(uint256 redeemedvils)
    {
        return ( roundownables[round].redeemedvils[lookup])  ;
    }
function playerinfo(address lookup)
        view
        public
        returns(uint256 redeemedvils,uint256 redeemablevils , uint256 soldiers, uint256 GOTCH)
    {
        return ( 
            roundownables[round].redeemedvils[lookup],
            Redeemable[lookup],
            roundownables[round].soldiers[lookup],
            roundownables[round].GOTCH[lookup]
            )  ;
    } 
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
       roundvars[round].bpamount = 30000;
       roundownables[round].ERCtradeactive = true;
       roundownables[round].roundlength = 10000000000000000000000;
       divsforall = false;
    }
function hillpayout() internal  {
    require(block.number > roundvars[round].lastblockpayout.add(roundvars[round].blocksbeforenewpay));
    // new payout method
    roundvars[round].lastblockpayout = roundvars[round].lastblockpayout.add(roundvars[round].blocksbeforenewpay);
    ethforp3dbuy = ethforp3dbuy.add((address(this).balance.sub(ethforp3dbuy)).div(100));
    owner.transfer((address(this).balance.sub(ethforp3dbuy)).div(100));
    roundvars[round].ATPO = roundvars[round].ATPO.add((address(this).balance.sub(ethforp3dbuy)).div(2));
    roundownables[round].hillowner.transfer((address(this).balance.sub(ethforp3dbuy)).div(2));

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
    require(roundownables[round].hillowner == msg.sender);
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
function batchcreatevillage(uint256 amt) public  payable  {
    require(msg.value >= 10 finney * amt);
    require(amt >= 1);
    require(amt <= 40);
    if(block.number > roundvars[round].lastblockpayout.add(roundvars[round].blocksbeforenewpay))
    {
    hillpayout();
    }
    for(uint i=0; i< amt; i++)
        {
    roundownables[round].villages[roundvars[round].nextVillageId].owner = msg.sender;
   roundownables[round].villages[roundvars[round].nextVillageId].lastcollect = block.number;
    roundownables[round].villages[roundvars[round].nextVillageId].beginnerprotection = block.number;
    roundvars[round].nextVillageId ++;
   
    roundownables[round].villages[roundvars[round].nextVillageId].defending = roundvars[round].nextVillageId;
        } 
        Redeemable[msg.sender] = Redeemable[msg.sender].add(amt);
        roundownables[round].redeemedvils[msg.sender] = roundownables[round].redeemedvils[msg.sender].add(amt);
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
    require(roundownables[round].villages[village].owner == msg.sender);
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
function batchcollecttaxes(uint256 a, uint256 b , uint256 c , uint256 d , uint256 e , uint256 f , uint256 g, uint256 h, uint256 i, uint256 j) public payable {// payed transaction
    // a
   require(msg.value >= 10 finney);
   require(roundownables[round].villages[a].owner == msg.sender);
   require(roundownables[round].villages[b].owner == msg.sender);
   require(roundownables[round].villages[c].owner == msg.sender);
   require(roundownables[round].villages[d].owner == msg.sender);
   require(roundownables[round].villages[e].owner == msg.sender);
   require(roundownables[round].villages[f].owner == msg.sender);
   require(roundownables[round].villages[g].owner == msg.sender);
   require(roundownables[round].villages[h].owner == msg.sender);
   require(roundownables[round].villages[i].owner == msg.sender);
   require(roundownables[round].villages[j].owner == msg.sender);
    require(block.number >  roundownables[round].villages[a].lastcollect);
    require(block.number >  roundownables[round].villages[b].lastcollect);
    require(block.number >  roundownables[round].villages[c].lastcollect);
    require(block.number >  roundownables[round].villages[d].lastcollect);
    require(block.number >  roundownables[round].villages[e].lastcollect);
    require(block.number >  roundownables[round].villages[f].lastcollect);
    require(block.number >  roundownables[round].villages[g].lastcollect);
    require(block.number >  roundownables[round].villages[h].lastcollect);
    require(block.number >  roundownables[round].villages[i].lastcollect);
    require(block.number >  roundownables[round].villages[j].lastcollect);
    
    uint256 test = (block.number.sub(roundownables[round].villages[a].lastcollect)).mul((roundvars[round].nextVillageId.sub(a)));
    if(roundvars[round].GOTCHatcontract < test ) 
    {
     roundvars[round].GOTCHatcontract =  roundvars[round].GOTCHatcontract.add(test);
     roundvars[round].totalsupplyGOTCH = roundvars[round].totalsupplyGOTCH.add(test);
    }   
   roundownables[round].GOTCH[msg.sender] = roundownables[round].GOTCH[msg.sender].add(test);
    roundvars[round].GOTCHatcontract = roundvars[round].GOTCHatcontract.sub(test);
    
    roundownables[round].villages[a].lastcollect = block.number;
    //b
   
    test = (block.number.sub(roundownables[round].villages[b].lastcollect)).mul((roundvars[round].nextVillageId.sub(b)));
    if(roundvars[round].GOTCHatcontract < test ) 
    {
     roundvars[round].GOTCHatcontract =  roundvars[round].GOTCHatcontract.add(test);
     roundvars[round].totalsupplyGOTCH = roundvars[round].totalsupplyGOTCH.add(test);
    }   
    roundownables[round].GOTCH[msg.sender] = roundownables[round].GOTCH[msg.sender].add(test);
    roundvars[round].GOTCHatcontract = roundvars[round].GOTCHatcontract.sub(test);
    
    roundownables[round].villages[b].lastcollect = block.number;
    //c
   
    test = (block.number.sub(roundownables[round].villages[c].lastcollect)).mul((roundvars[round].nextVillageId.sub(c)));
    if(roundvars[round].GOTCHatcontract < test ) 
    {
     roundvars[round].GOTCHatcontract =  roundvars[round].GOTCHatcontract.add(test);
     roundvars[round].totalsupplyGOTCH = roundvars[round].totalsupplyGOTCH.add(test);
    }   
    roundownables[round].GOTCH[msg.sender] = roundownables[round].GOTCH[msg.sender].add(test);
    roundvars[round].GOTCHatcontract = roundvars[round].GOTCHatcontract.sub(test);
    
    roundownables[round].villages[c].lastcollect = block.number;
    //j
    
    test = (block.number.sub(roundownables[round].villages[j].lastcollect)).mul((roundvars[round].nextVillageId.sub(j)));
    if(roundvars[round].GOTCHatcontract < test ) 
    {
     roundvars[round].GOTCHatcontract =  roundvars[round].GOTCHatcontract.add(test);
     roundvars[round].totalsupplyGOTCH = roundvars[round].totalsupplyGOTCH.add(test);
    }   
    roundownables[round].GOTCH[msg.sender] = roundownables[round].GOTCH[msg.sender].add(test);
    roundvars[round].GOTCHatcontract = roundvars[round].GOTCHatcontract.sub(test);
    
    roundownables[round].villages[j].lastcollect = block.number;
    //d
    
    test = (block.number.sub(roundownables[round].villages[d].lastcollect)).mul((roundvars[round].nextVillageId.sub(d)));
    if(roundvars[round].GOTCHatcontract < test ) 
    {
     roundvars[round].GOTCHatcontract =  roundvars[round].GOTCHatcontract.add(test);
     roundvars[round].totalsupplyGOTCH = roundvars[round].totalsupplyGOTCH.add(test);
    }   
    roundownables[round].GOTCH[msg.sender] = roundownables[round].GOTCH[msg.sender].add(test);
    roundvars[round].GOTCHatcontract = roundvars[round].GOTCHatcontract.sub(test);
    
    roundownables[round].villages[d].lastcollect = block.number;
    //e
   
    test = (block.number.sub(roundownables[round].villages[e].lastcollect)).mul((roundvars[round].nextVillageId.sub(e)));
    if(roundvars[round].GOTCHatcontract < test ) 
    {
     roundvars[round].GOTCHatcontract =  roundvars[round].GOTCHatcontract.add(test);
     roundvars[round].totalsupplyGOTCH = roundvars[round].totalsupplyGOTCH.add(test);
    }   
    roundownables[round].GOTCH[msg.sender] = roundownables[round].GOTCH[msg.sender].add(test);
    roundvars[round].GOTCHatcontract = roundvars[round].GOTCHatcontract.sub(test);
    
    roundownables[round].villages[e].lastcollect = block.number;
    //f
    
    test = (block.number.sub(roundownables[round].villages[f].lastcollect)).mul((roundvars[round].nextVillageId.sub(f)));
    if(roundvars[round].GOTCHatcontract < test ) 
    {
     roundvars[round].GOTCHatcontract =  roundvars[round].GOTCHatcontract.add(test);
     roundvars[round].totalsupplyGOTCH = roundvars[round].totalsupplyGOTCH.add(test);
    }   
    roundownables[round].GOTCH[msg.sender] = roundownables[round].GOTCH[msg.sender].add(test);
    roundvars[round].GOTCHatcontract = roundvars[round].GOTCHatcontract.sub(test);
    
    roundownables[round].villages[f].lastcollect = block.number;
    //g
   
    test = (block.number.sub(roundownables[round].villages[g].lastcollect)).mul((roundvars[round].nextVillageId.sub(g)));
    if(roundvars[round].GOTCHatcontract < test ) 
    {
     roundvars[round].GOTCHatcontract =  roundvars[round].GOTCHatcontract.add(test);
     roundvars[round].totalsupplyGOTCH = roundvars[round].totalsupplyGOTCH.add(test);
    }   
    roundownables[round].GOTCH[msg.sender] = roundownables[round].GOTCH[msg.sender].add(test);
    roundvars[round].GOTCHatcontract = roundvars[round].GOTCHatcontract.sub(test);
    
    roundownables[round].villages[g].lastcollect = block.number;
    //h
    
    test = (block.number.sub(roundownables[round].villages[h].lastcollect)).mul((roundvars[round].nextVillageId.sub(h)));
    if(roundvars[round].GOTCHatcontract < test ) 
    {
     roundvars[round].GOTCHatcontract =  roundvars[round].GOTCHatcontract.add(test);
     roundvars[round].totalsupplyGOTCH = roundvars[round].totalsupplyGOTCH.add(test);
    }   
    roundownables[round].GOTCH[msg.sender] = roundownables[round].GOTCH[msg.sender].add(test);
    roundvars[round].GOTCHatcontract = roundvars[round].GOTCHatcontract.sub(test);
    
    roundownables[round].villages[h].lastcollect = block.number;
    //i
    
    test = (block.number.sub(roundownables[round].villages[i].lastcollect)).mul((roundvars[round].nextVillageId.sub(i)));
    if(roundvars[round].GOTCHatcontract < test ) 
    {
     roundvars[round].GOTCHatcontract =  roundvars[round].GOTCHatcontract.add(test);
     roundvars[round].totalsupplyGOTCH = roundvars[round].totalsupplyGOTCH.add(test);
    }   
    roundownables[round].GOTCH[msg.sender] = roundownables[round].GOTCH[msg.sender].add(test);
    roundvars[round].GOTCHatcontract = roundvars[round].GOTCHatcontract.sub(test);
    
    roundownables[round].villages[i].lastcollect = block.number;

        
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
    uint256 test = (block.number.sub(roundownables[round].villages[village].lastcollect)).mul((roundvars[round].nextVillageId.sub(village)));
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
    roundownables[round].GOTCH[msg.sender] =  roundownables[round].GOTCH[msg.sender].add(amt.mul(10000));
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
  roundownables[round].GOTCH[this] = roundownables[round].GOTCH[this].add(amt.mul(10000));
}
//p3d 

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
       roundvars[round].bpamount = 30000;
    
}

}