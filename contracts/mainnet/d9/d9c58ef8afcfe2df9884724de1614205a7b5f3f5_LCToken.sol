pragma solidity ^0.4.11;

contract Token {
    function transfer(address _to, uint256 _value) returns (bool success);
    function balanceOf(address _owner) constant returns (uint256 balance) ;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}


/*  ERC 20 token */
contract StandardToken is Token {


    struct LCBalance{
        uint lcValue;
        uint lockTime;
        uint ethValue;

        uint index;
        bytes32 indexHash;
        uint lotteryNum;
    }

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender].lcValue >= _value && _value > 0&&  balances[msg.sender].lockTime!=0) {       
            balances[msg.sender].lcValue -= _value;
            balances[_to].lcValue += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        }
         else {
            return false;
        }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner].lcValue;
    }

    function balanceOfEth(address _owner) constant returns (uint256 balance) {
        return balances[_owner].ethValue;
    }

    function balanceOfLockTime(address _owner) constant returns (uint256 balance) {
        return balances[_owner].lockTime;
    }

    function balanceOfLotteryNum(address _owner) constant returns (uint256 balance) {
        return balances[_owner].lotteryNum;
    }

    mapping (address => LCBalance) balances;
}

contract LCToken is StandardToken {
    // metadata
    string public constant name = "Bulls and Cows";
    string public constant symbol = "BAC";
    uint256 public constant decimals = 18;
    string public version = "1.0";

    // constant
    uint256 val1 = 1 wei;    // 1
    uint256 val2 = 1 szabo;  // 1 * 10 ** 12
    uint256 val3 = 1 finney; // 1 * 10 ** 15
    uint256 val4 = 1 ether;  // 1 * 10 ** 18

    // contact setting
    address public creator;

    uint256 public constant LOCKPERIOD          = 365 days;
    uint256 public constant ICOPERIOD           = 120 days;
    uint256 public constant SHAREPERIOD         = 30 days;
    uint256 public constant LOCKAMOUNT          = 3000000 * 10**decimals;
    uint256 public constant AMOUNT_ICO          = 5000000 * 10**decimals;
    uint256 public constant AMOUNT_TeamSupport  = 2000000 * 10**decimals;

    uint256 public gcStartTime = 0;     //ico begin time, unix timestamp seconds
    uint256 public gcEndTime = 0;       //ico end time, unix timestamp seconds

    
    // LC: 30% lock , 20% for Team, 50% for ico          
    address account_lock = 0x9AD7aeBe8811b0E3071C627403B38803D91BC1ac;  //30%  lock
    address account_team = 0xc96c3da8bc6381DB296959Ec3e1Fe1e430a4B65B;  //20%  team

    uint256 public gcSupply = 5000000 * 10**decimals;                 // ico 50% (5000000) total LC supply
    uint256 public constant gcExchangeRate=1000;                       // 1000 LC per 1 ETH

    
    // Play
    bytes32[1000]   blockhash;
    uint            firstIndex;
    uint            endIndex;

    uint256 public totalLotteryValue = 0;
    uint256 public currentLotteryValue = 0;
    uint256 public currentProfit = 0;
    uint256 public shareTime = 0;
    uint256 public shareLimit = 10000*val4;


    function buyLottery (uint8 _lotteryNum) payable {
        if ( msg.value >=val3*10 && _lotteryNum>=0 &&  _lotteryNum<=9 )
        {
            bytes32 currentHash=block.blockhash(block.number-1);
            if(blockhash[endIndex]!=currentHash)
            {
                if(endIndex+1==firstIndex)
                {
                    endIndex++;
                    blockhash[endIndex]=currentHash;
                    if(firstIndex<999)
                    {
                        firstIndex++;
                    }
                    else
                    {
                        firstIndex=0;
                    }
                }
                else
                {
                    if(firstIndex==0 && 999==endIndex)
                    {
                        endIndex=0;
                        blockhash[endIndex]=currentHash;
                        firstIndex=1;
                    }
                    else
                    {
                        if(999<=endIndex)
                        {
                            endIndex=0;
                        }
                        else
                        {
                            endIndex++;
                        }
                        blockhash[endIndex]=currentHash;
                    }
                }
            }
            balances[msg.sender].ethValue+=msg.value;
            balances[msg.sender].index=endIndex;
            balances[msg.sender].lotteryNum=_lotteryNum;
            balances[msg.sender].indexHash=currentHash;
            totalLotteryValue+=msg.value;
            currentLotteryValue+=msg.value;
        }
        else
        {
            revert();
        }
    }

    function openLottery () {

        bytes32 currentHash=block.blockhash(block.number-1);
        if(blockhash[endIndex]!=currentHash)
        {
            if(endIndex+1==firstIndex)
            {
                endIndex++;
                blockhash[endIndex]=currentHash;
                if(firstIndex<999)
                {
                    firstIndex++;
                }
                else
                {
                    firstIndex=0;
                }
            }
            else
            {
                if(firstIndex==0 && 999==endIndex)
                {
                    endIndex=0;
                    blockhash[endIndex]=currentHash;
                    firstIndex=1;
                }
                else
                {
                    if(999<=endIndex)
                    {
                        endIndex=0;
                    }
                    else
                    {
                        endIndex++;
                    }
                    blockhash[endIndex]=currentHash;
                }
            }
        }
        if ( balances[msg.sender].ethValue >=val3*10 && balances[msg.sender].indexHash!=currentHash)
        {
            currentLotteryValue-=balances[msg.sender].ethValue;

            uint temuint = balances[msg.sender].index;
            if(balances[msg.sender].lotteryNum>=0 && balances[msg.sender].lotteryNum<=9 && balances[msg.sender].indexHash==blockhash[temuint])
            {
                temuint++;
                if(temuint>999)
                {
                    temuint=0;
                }
                temuint = uint(blockhash[temuint]);
                temuint = temuint%10;
                if(temuint==balances[msg.sender].lotteryNum)
                {
                    uint _tosend=balances[msg.sender].ethValue*90/100;
                    if(_tosend>totalLotteryValue)
                    {
                        _tosend=totalLotteryValue;
                    }
                    totalLotteryValue-=_tosend;
                    balances[msg.sender].ethValue=0;
                    msg.sender.transfer(_tosend);
                }
                else
                {
                    balances[msg.sender].ethValue=0;
                }
                balances[msg.sender].lotteryNum=100+temuint;
            }
            else
            {
                balances[msg.sender].ethValue=0;
                balances[msg.sender].lotteryNum=999;
            }
        }
    }

    function getShare ()  {

        if(shareTime+SHAREPERIOD<now)
        {
            uint _jumpc=(now - shareTime)/SHAREPERIOD;
            shareTime += (_jumpc * SHAREPERIOD);
            
            if(totalLotteryValue>currentLotteryValue)
            {
                currentProfit=totalLotteryValue-currentLotteryValue;
            }
            else
            {
                currentProfit=0;
            }
        }

        if (balances[msg.sender].lockTime!=0 && balances[msg.sender].lockTime+SHAREPERIOD <=shareTime && currentProfit>0 && balances[msg.sender].lcValue >=shareLimit)
        {
            uint _sharevalue=balances[msg.sender].lcValue/val4*currentProfit/1000;
            if(_sharevalue>totalLotteryValue)
            {
                _sharevalue=totalLotteryValue;
            }
            totalLotteryValue-=_sharevalue;
            msg.sender.transfer(_sharevalue);
            balances[msg.sender].lockTime=shareTime;
        }
    }


    function Add_totalLotteryValue () payable {
        if(msg.value>0)
        {
            totalLotteryValue+=msg.value;
        }
    }

    //
    function lockAccount ()  {
        balances[msg.sender].lockTime=now;
    }

    function unlockAccount ()  {
        balances[msg.sender].lockTime=0;
    }

    
    //+ buy lc,1eth=1000lc, 30%eth send to owner, 70% keep in contact
    function buyLC () payable {
        if(now < gcEndTime)
        {
            uint256 lcAmount;
            if ( msg.value >=0){
                lcAmount = msg.value * gcExchangeRate;
                if (gcSupply < lcAmount) revert();
                gcSupply -= lcAmount;          
                balances[msg.sender].lcValue += lcAmount;
            }
            if(!creator.send(msg.value*30/100)) revert();
        }
        else
        {    
            balances[account_team].lcValue += gcSupply;
            account_team.transfer((AMOUNT_ICO-gcSupply)*699/1000/gcExchangeRate);
            gcSupply = 0;     
        }
    }

    // exchange lc to eth, 1000lc =0.7eth, 30% for fee
    function clearLC ()  {
        if(now < gcEndTime)
        {
            uint256 ethAmount;
            if ( balances[msg.sender].lcValue >0 && balances[msg.sender].lockTime==0){
                if(msg.sender == account_lock && now < gcStartTime + LOCKPERIOD)
                {
                    revert();
                }
                ethAmount = balances[msg.sender].lcValue *70/100/ gcExchangeRate;
                gcSupply += balances[msg.sender].lcValue;          
                balances[msg.sender].lcValue = 0;
                msg.sender.transfer(ethAmount);
            }
        }
    }

    //+ transfer
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender].lcValue >= _value && _value > 0 && balances[msg.sender].lockTime==0 ) { 
            if(msg.sender == account_lock ){
                if(now < gcStartTime + LOCKPERIOD){
                    return false;
                }
            }
            else{
                balances[msg.sender].lcValue -= _value;
                if(address(this)==_to)
                {
                    balances[creator].lcValue += _value;
                }
                else
                {
                    balances[_to].lcValue += _value;
                }
                Transfer(msg.sender, _to, _value);
                return true;
            }
        
        } 
        else {
            return false;
        }
    }

    function endThisContact () {
        if(msg.sender==creator && balances[msg.sender].lcValue >=9000000 * val4)
        {
            if(balances[msg.sender].lcValue >=9000000 * val4 || gcSupply >= 4990000 * 10**decimals)
            {
                selfdestruct(creator);
            }
        }
    }

    // constructor
    function LCToken( ) {
        creator = msg.sender;
        balances[account_team].lcValue = AMOUNT_TeamSupport;    //for team
        balances[account_lock].lcValue = LOCKAMOUNT;            //30%   lock 365 days
        gcStartTime = now;
        gcEndTime=now+ICOPERIOD;


        totalLotteryValue=0;

        firstIndex=0;
        endIndex=0;
        blockhash[0] = block.blockhash(block.number-1);

        shareTime=now+SHAREPERIOD;
    }
    

    
    // fallback
    function() payable {
        buyLC();
    }

}