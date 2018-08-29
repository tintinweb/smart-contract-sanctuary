pragma solidity ^0.4.24;    
////////////////////////////////////////////////////////////////////////////////
library     SafeMath
{
    //------------------
    function mul(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        if (a == 0)     return 0;
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    //--------------------------------------------------------------------------
    function div(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        return a/b;
    }
    //--------------------------------------------------------------------------
    function sub(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        assert(b <= a);
        return a - b;
    }
    //--------------------------------------------------------------------------
    function add(uint256 a, uint256 b) internal pure returns (uint256) 
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
////////////////////////////////////////////////////////////////////////////////
contract    ERC20 
{
    using SafeMath  for uint256;

    //----- VARIABLES

    address public              owner;          // Owner of this contract
    address public              admin;          // The one who is allowed to do changes 

    mapping(address => uint256)                         balances;       // Maintain balance in a mapping
    mapping(address => mapping (address => uint256))    allowances;     // Allowances index-1 = Owner account   index-2 = spender account

    //------ TOKEN SPECIFICATION

    string  public  constant    name     = "Reger Diamond Security Token";
    string  public  constant    symbol   = "RDS";

    uint256 public  constant    decimals = 18;
    
    uint256 public  constant    initSupply       = 60000000 * 10**decimals;        // 10**18 max
    uint256 public  constant    supplyReserveVal = 37500000 * 10**decimals;          // if quantity => the ##MACRO## addrs "* 10**decimals" 

    //-----

    uint256 public              totalSupply;
    uint256 public              icoSalesSupply   = 0;                   // Needed when burning tokens
    uint256 public              icoReserveSupply = 0;
    uint256 public              softCap =  5000000   * 10**decimals;
    uint256 public              hardCap = 21500000   * 10**decimals;

    //---------------------------------------------------- smartcontract control

    uint256 public              icoDeadLine = 1533513600;     // 2018-08-06 00:00 (GMT+0)   not needed

    bool    public              isIcoPaused            = false; 
    bool    public              isStoppingIcoOnHardCap = true;

    //--------------------------------------------------------------------------

    modifier duringIcoOnlyTheOwner()  // if not during the ico : everyone is allowed at anytime
    { 
        require( now>icoDeadLine || msg.sender==owner );
        _;
    }

    modifier icoFinished()          { require(now > icoDeadLine);           _; }
    modifier icoNotFinished()       { require(now <= icoDeadLine);          _; }
    modifier icoNotPaused()         { require(isIcoPaused==false);          _; }
    modifier icoPaused()            { require(isIcoPaused==true);           _; }
    modifier onlyOwner()            { require(msg.sender==owner);           _; }
    modifier onlyAdmin()            { require(msg.sender==admin);           _; }

    //----- EVENTS

    event Transfer(address indexed fromAddr, address indexed toAddr,   uint256 amount);
    event Approval(address indexed _owner,   address indexed _spender, uint256 amount);

            //---- extra EVENTS

    event onAdminUserChanged(   address oldAdmin,       address newAdmin);
    event onOwnershipTransfered(address oldOwner,       address newOwner);
    event onIcoDeadlineChanged( uint256 oldIcoDeadLine, uint256 newIcoDeadline);
    event onHardcapChanged(     uint256 hardCap,        uint256 newHardCap);
    event icoIsNowPaused(       uint8 newPauseStatus);
    event icoHasRestarted(      uint8 newPauseStatus);

    event log(string key, string value);
    event log(string key, uint   value);

    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    constructor()   public 
    {
        owner       = msg.sender;
        admin       = owner;

        isIcoPaused = false;
        
        //-----

        balances[owner] = initSupply;   // send the tokens to the owner
        totalSupply     = initSupply;
        icoSalesSupply  = totalSupply;   

        //----- Handling if there is a special maximum amount of tokens to spend during the ICO or not

        icoSalesSupply   = totalSupply.sub(supplyReserveVal);
        icoReserveSupply = totalSupply.sub(icoSalesSupply);
    }
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    //----- ERC20 FUNCTIONS
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    function balanceOf(address walletAddress) public constant returns (uint256 balance) 
    {
        return balances[walletAddress];
    }
    //--------------------------------------------------------------------------
    function transfer(address toAddr, uint256 amountInWei)  public   duringIcoOnlyTheOwner   returns (bool)     // don&#39;t icoNotPaused here. It&#39;s a logic issue. 
    {
        require(toAddr!=0x0 && toAddr!=msg.sender && amountInWei>0);     // Prevent transfer to 0x0 address and to self, amount must be >0

        uint256 availableTokens = balances[msg.sender];

        //----- Checking Token reserve first : if during ICO    

        if (msg.sender==owner && now <= icoDeadLine)                    // ICO Reserve Supply checking: Don&#39;t touch the RESERVE of tokens when owner is selling
        {
            assert(amountInWei<=availableTokens);

            uint256 balanceAfterTransfer = availableTokens.sub(amountInWei);      

            assert(balanceAfterTransfer >= icoReserveSupply);           // We try to sell more than allowed during an ICO
        }

        //-----

        balances[msg.sender] = balances[msg.sender].sub(amountInWei);
        balances[toAddr]     = balances[toAddr].add(amountInWei);

        emit Transfer(msg.sender, toAddr, amountInWei);

        return true;
    }
    //--------------------------------------------------------------------------
    function allowance(address walletAddress, address spender) public constant returns (uint remaining)
    {
        return allowances[walletAddress][spender];
    }
    //--------------------------------------------------------------------------
    function transferFrom(address fromAddr, address toAddr, uint256 amountInWei)  public  returns (bool) 
    {
        if (amountInWei <= 0)                                   return false;
        if (allowances[fromAddr][msg.sender] < amountInWei)     return false;
        if (balances[fromAddr] < amountInWei)                   return false;

        balances[fromAddr]               = balances[fromAddr].sub(amountInWei);
        balances[toAddr]                 = balances[toAddr].add(amountInWei);
        allowances[fromAddr][msg.sender] = allowances[fromAddr][msg.sender].sub(amountInWei);

        emit Transfer(fromAddr, toAddr, amountInWei);
        return true;
    }
    //--------------------------------------------------------------------------
    function approve(address spender, uint256 amountInWei) public returns (bool) 
    {
        require((amountInWei == 0) || (allowances[msg.sender][spender] == 0));
        allowances[msg.sender][spender] = amountInWei;
        emit Approval(msg.sender, spender, amountInWei);

        return true;
    }
    //--------------------------------------------------------------------------
    function() public                       
    {
        assert(true == false);      // If Ether is sent to this address, don&#39;t handle it -> send it back.
    }
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    function transferOwnership(address newOwner) public onlyOwner               // @param newOwner The address to transfer ownership to.
    {
        require(newOwner != address(0));

        emit onOwnershipTransfered(owner, newOwner);
        owner = newOwner;
    }
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    function    changeAdminUser(address newAdminAddress) public onlyOwner
    {
        require(newAdminAddress!=0x0);

        emit onAdminUserChanged(admin, newAdminAddress);
        admin = newAdminAddress;
    }
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    function    changeIcoDeadLine(uint256 newIcoDeadline) public onlyAdmin
    {
        require(newIcoDeadline!=0);

        emit onIcoDeadlineChanged(icoDeadLine, newIcoDeadline);
        icoDeadLine = newIcoDeadline;
    }
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    function    changeHardCap(uint256 newHardCap) public onlyAdmin
    {
        require(newHardCap!=0);

        emit onHardcapChanged(hardCap, newHardCap);
        hardCap = newHardCap;
    }
    //--------------------------------------------------------------------------
    function    isHardcapReached()  public view returns(bool)
    {
        return (isStoppingIcoOnHardCap && initSupply-balances[owner] > hardCap);
    }
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    function    pauseICO()  public onlyAdmin
    {
        isIcoPaused = true;
        emit icoIsNowPaused(1);
    }
    //--------------------------------------------------------------------------
    function    unpauseICO()  public onlyAdmin
    {
        isIcoPaused = false;
        emit icoHasRestarted(0);
    }
    //--------------------------------------------------------------------------
    function    isPausedICO() public view     returns(bool)
    {
        return (isIcoPaused) ? true : false;
    }
}
////////////////////////////////////////////////////////////////////////////////
contract    DateTime 
{
    struct TDateTime 
    {
        uint16 year;    uint8 month;    uint8 day;
        uint8 hour;     uint8 minute;   uint8 second;
        uint8 weekday;
    }
    uint8[] totalDays = [ 0,   31,28,31,30,31,30,  31,31,30,31,30,31];
    uint constant DAY_IN_SECONDS       = 86400;
    uint constant YEAR_IN_SECONDS      = 31536000;
    uint constant LEAP_YEAR_IN_SECONDS = 31622400;
    uint constant HOUR_IN_SECONDS      = 3600;
    uint constant MINUTE_IN_SECONDS    = 60;
    uint16 constant ORIGIN_YEAR        = 1970;
    //-------------------------------------------------------------------------
    function isLeapYear(uint16 year) public pure returns (bool) 
    {
        if ((year %   4)!=0)    return false;
        if ( year % 100 !=0)    return true;
        if ( year % 400 !=0)    return false;
        return true;
    }
    //-------------------------------------------------------------------------
    function leapYearsBefore(uint year) public pure returns (uint) 
    {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }
    //-------------------------------------------------------------------------
    function getDaysInMonth(uint8 month, uint16 year) public pure returns (uint8) 
    {
        uint8   nDay = 30;
             if (month==1)          nDay++;
        else if (month==3)          nDay++;
        else if (month==5)          nDay++;
        else if (month==7)          nDay++;
        else if (month==8)          nDay++;
        else if (month==10)         nDay++;
        else if (month==12)         nDay++;
        else if (month==2) 
        {
                                    nDay = 28;
            if (isLeapYear(year))   nDay++;
        }
        return nDay;
    }
    //-------------------------------------------------------------------------
    function parseTimestamp(uint timestamp) internal pure returns (TDateTime dt) 
    {
        uint  secondsAccountedFor = 0;
        uint  buf;
        uint8 i;
        uint  secondsInMonth;
        dt.year = getYear(timestamp);
        buf     = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);
        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
        secondsAccountedFor += YEAR_IN_SECONDS   * (dt.year - ORIGIN_YEAR - buf);
        for (i = 1; i <= 12; i++) 
        {
            secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
            if (secondsInMonth + secondsAccountedFor > timestamp) 
            {
                dt.month = i;
                break;
            }
            secondsAccountedFor += secondsInMonth;
        }
        for (i=1; i<=getDaysInMonth(dt.month, dt.year); i++) 
        {
            if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) 
            {
                dt.day = i;
                break;
            }
            secondsAccountedFor += DAY_IN_SECONDS;
        }
        dt.hour    = getHour(timestamp);
        dt.minute  = getMinute(timestamp);
        dt.second  = getSecond(timestamp);
        dt.weekday = getWeekday(timestamp);
    }
    //-------------------------------------------------------------------------
    function getYear(uint timestamp) public pure returns (uint16) 
    {
        uint secondsAccountedFor = 0;
        uint16 year;
        uint numLeapYears;
        year         = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
        numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);
        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
        secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);
        while (secondsAccountedFor > timestamp) 
        {
            if (isLeapYear(uint16(year - 1)))   secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
            else                                secondsAccountedFor -= YEAR_IN_SECONDS;
            year -= 1;
        }
        return year;
    }
    //-------------------------------------------------------------------------
    function getMonth(uint timestamp) public pure returns (uint8) 
    {
        return parseTimestamp(timestamp).month;
    }
    //-------------------------------------------------------------------------
    function getDay(uint timestamp) public pure returns (uint8) 
    {
        return parseTimestamp(timestamp).day;
    }
    //-------------------------------------------------------------------------
    function getHour(uint timestamp) public pure returns (uint8) 
    {
        return uint8(((timestamp % 86400) / 3600) % 24);
    }
    //-------------------------------------------------------------------------
    function getMinute(uint timestamp) public pure returns (uint8) 
    {
        return uint8((timestamp % 3600) / 60);
    }
    //-------------------------------------------------------------------------
    function getSecond(uint timestamp) public pure returns (uint8) 
    {
        return uint8(timestamp % 60);
    }
    //-------------------------------------------------------------------------
    function getWeekday(uint timestamp) public pure returns (uint8) 
    {
        return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
    }
    //-------------------------------------------------------------------------
    function toTimestamp(uint16 year, uint8 month, uint8 day) public pure returns (uint timestamp) 
    {
        return toTimestamp(year, month, day, 0, 0, 0);
    }
    //-------------------------------------------------------------------------
    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) public pure returns (uint timestamp) 
    {
        return toTimestamp(year, month, day, hour, 0, 0);
    }
    //-------------------------------------------------------------------------
    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) public pure returns (uint timestamp) 
    {
        return toTimestamp(year, month, day, hour, minute, 0);
    }
    //-------------------------------------------------------------------------
    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) public pure returns (uint timestamp) 
    {
        uint16 i;
        for (i = ORIGIN_YEAR; i < year; i++) 
        {
            if (isLeapYear(i))  timestamp += LEAP_YEAR_IN_SECONDS;
            else                timestamp += YEAR_IN_SECONDS;
        }
        uint8[12] memory monthDayCounts;
        monthDayCounts[0]  = 31;
        monthDayCounts[1]  = 28;     if (isLeapYear(year))   monthDayCounts[1] = 29;
        monthDayCounts[2]  = 31;
        monthDayCounts[3]  = 30;
        monthDayCounts[4]  = 31;
        monthDayCounts[5]  = 30;
        monthDayCounts[6]  = 31;
        monthDayCounts[7]  = 31;
        monthDayCounts[8]  = 30;
        monthDayCounts[9]  = 31;
        monthDayCounts[10] = 30;
        monthDayCounts[11] = 31;
        for (i=1; i<month; i++) 
        {
            timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
        }
        timestamp += DAY_IN_SECONDS    * (day - 1);
        timestamp += HOUR_IN_SECONDS   * (hour);
        timestamp += MINUTE_IN_SECONDS * (minute);
        timestamp += second;
        return timestamp;
    }
    //-------------------------------------------------------------------------
    function getYearDay(uint timestamp) public pure returns (uint16)
    {
        TDateTime memory date = parseTimestamp(timestamp);
        uint16 dayCount=0;
        for (uint8 iMonth=1; iMonth<date.month; iMonth++)
        {
            dayCount += getDaysInMonth(iMonth, date.year);
        }
        dayCount += date.day;   
        return dayCount;        // We have now the amount of days since January 1st of that year
    }
    //-------------------------------------------------------------------------
    function getDaysInYear(uint16 year) public pure returns (uint16)
    {
        return (isLeapYear(year)) ? 366:365;
    }
    //-------------------------------------------------------------------------
    function    dateToTimestamp(uint16 iYear, uint8 iMonth, uint8 iDay) public pure returns(uint)
    {
        uint8 monthDayCount = 30;
        if (iMonth==2)
        {
                                    monthDayCount = 28;
            if (isLeapYear(iYear))  monthDayCount++;
        }
        if (iMonth==4 || iMonth==6 || iMonth==9 || iMonth==11)
        {
            monthDayCount = 31;
        }
        if (iDay<1)           
        {
            iDay = 1;
        }
        else if (iDay>monthDayCount)     
        {
            iDay = 1;       // if day is over limit, set the date on the first day of the next month
            iMonth++;
            if (iMonth>12)  
            {
                iMonth=1;
                iYear++;
            }
        }
        return toTimestamp(iYear, iMonth, iDay);
    }
    //-------------------------------------------------------------------------
}
////////////////////////////////////////////////////////////////////////////////
contract    CompoundContract  is  ERC20, DateTime
{
    using SafeMath  for uint256;

        bool private    isLiveTerm = true;

    struct TCompoundItem
    {
        uint        id;                         // an HASH to distinguish each compound in contract
        uint        plan;                       // 1: Sapphire   2: Emerald   3:Ruby   4: Diamond
        address     investor;                   // wallet address of the owner of this compound contract
        uint        tokenCapitalInWei;          // = capital
        uint        tokenEarningsInWei;         // This contract will geneeate this amount of tokens for the investor
        uint        earningPerTermInWei;        // Every "3 months" the investor will receive this amount of money
        uint        currentlyEarnedInWei;       // cumulative amount of tokens already received
        uint        tokenEarnedInWei;           // = totalEarnings
        uint        overallTokensInWei;         // = capital + totalEarnings
        uint        contractMonthCount;         // 12 or 24
        uint        startTimestamp;
        uint        endTimestamp;               // the date when the compound contract will cease
        uint        interestRate;
        uint        percent;
        bool        isAllPaid;                  // if true : all compound earning has been given. Nothing more to do
        uint8       termPaidCount;              //
        uint8       termCount;                  //
        bool        isContractValidated;        // Any compound contract needs to be confirmed otherwise they will be cancelled
        bool        isCancelled;                // The compound contract was not validated and has been set to cancelled!
    }

    mapping(address => uint256)                 lockedCapitals;     // During ICO we block some of the tokens
    mapping(address => uint256)                 lockedEarnings;     // During ICO we block some of the tokens

    mapping(uint256 => bool)         private    activeContractStatues;      // Use when doing a payEarnings to navigate through all contracts
    mapping(uint => TCompoundItem)   private    contracts;
    mapping(uint256 => uint32[12])   private    compoundPayTimes;    
    mapping(uint256 => uint8[12])    private    compoundPayStatus;          // to know if a compound has already been paid or not. So not repaying again    

    event onCompoundContractCompleted(address investor, uint256 compoundId, 
                                                        uint256 capital, 
                                                        uint256 earnedAmount, 
                                                        uint256 total, 
                                                        uint256 timestamp);

    event onCompoundEarnings(address investor,  uint256 compoundId, 
                                                uint256 capital, 
                                                uint256 earnedAmount, 
                                                uint256 earnedSoFarAmount, 
                                                uint32  timestamp,
                                                uint8   paidTermCount,
                                                uint8   totalTermCount);

    event onCompoundContractLocked(address fromAddr, address toAddr, uint256 amountToLockInWei);
    event onPayEarningsDone(uint contractId, uint nPaid, uint paymentCount, uint paidAmountInWei);

    event onCompoundContractCancelled(uint contractId, uint lockedCapital, uint lockedEarnings);
    event onCompoundContractValidated(uint contractId);

    //--------------------------------------------------------------------------
    function    initCompoundContract(address buyerAddress, uint256 amountInWei, uint256 compoundContractId, uint monthCount)  internal onlyOwner  returns(bool)
    {
        TCompoundItem memory    item;
        uint                    overallTokensInWei; 
        uint                    tokenEarningsInWei;
        uint                    earningPerTermInWei; 
        uint                    percentToUse; 
        uint                    interestRate;
        uint                    i;

        if (activeContractStatues[compoundContractId])
        {
            return false;       // the specified contract is already in place. Don&#39;t alter already running contract!!!
        }

        activeContractStatues[compoundContractId] = true;

        //----- Calculate the contract revenue generated for the whole monthPeriod

        (overallTokensInWei, 
         tokenEarningsInWei,
         earningPerTermInWei, 
         percentToUse, 
         interestRate,
         i) = calculateCompoundContract(amountInWei, monthCount);

        item.plan = i;                  // Not enough stack depth. using i here

        //----- Checking if we can apply this compound contract or not

        if (percentToUse==0)        // an error occured
        {
            return false;
        }

        //----- Calculate when to do payments for that contract

        generateCompoundTerms(compoundContractId);

        //-----

        item.id                   = compoundContractId;
        item.startTimestamp       = now;

        item.contractMonthCount   = monthCount;
        item.interestRate         = interestRate;
        item.percent              = percentToUse;
        item.investor             = buyerAddress;
        item.isAllPaid            = false;
        item.termCount            = uint8(monthCount/3);
        item.termPaidCount        = 0;

        item.tokenCapitalInWei    = amountInWei;
        item.currentlyEarnedInWei = 0;
        item.overallTokensInWei   = overallTokensInWei;
        item.tokenEarningsInWei   = tokenEarningsInWei;
        item.earningPerTermInWei  = earningPerTermInWei;

        item.isCancelled          = false;
        item.isContractValidated  = false;                      // any contract must be validated 35 days after its creation.

        //-----

        contracts[compoundContractId] = item;

        return true;
    }
    //--------------------------------------------------------------------------
    function    generateCompoundTerms(uint256 compoundContractId)    private
    {
        uint16 iYear  =  getYear(now);
        uint8  iMonth = getMonth(now);
        uint   i;

        if (isLiveTerm)
        {
            for (i=0; i<8; i++)             // set every pay schedule date (every 3 months)  8 means 2 years payments every 3 months
            {
                iMonth += 3;        // every 3 months
                if (iMonth>12)
                {
                    iYear++;
                    iMonth -= 12;
                }

                compoundPayTimes[compoundContractId][i]  = uint32(dateToTimestamp(iYear, iMonth, getDay(now)));
                compoundPayStatus[compoundContractId][i] = 0;      
            }
        }
        else
        {
            uint timeSum=now;
            for (i=0; i<8; i++)             // set every pay schedule date (every 3 months)  8 means 2 years payments every 3 months
            {
                            uint duration = 4*60;    // set first period longer to allow confirmation of the contract
                if (i>0)         duration = 2*60;

                timeSum += duration;

                compoundPayTimes[compoundContractId][i]  = uint32(timeSum);     // DEBUGING: pay every 3 minutes
                compoundPayStatus[compoundContractId][i] = 0;      
            }
        }
    }
    //--------------------------------------------------------------------------
    function    calculateCompoundContract(uint256 capitalInWei, uint contractMonthCount)   public  constant returns(uint, uint, uint, uint, uint, uint)    // DON&#39;T Set as pure, otherwise it will make investXXMonths function unusable (too much gas) 
    {
        /*  12 months   Sapphire    From     100 to   1,000     12%
                        Emerald     From   1,000 to  10,000     15%
                        Rub         From  10,000 to 100,000     17%
                        Diamond                     100,000+    20%
            24 months   Sapphire    From     100 to   1,000     15%
                        Emerald     From   1,000 to  10,000     17%
                        Rub         From  10,000 to 100,000     20%
                        Diamond                     100,000+    30%        */

        uint    plan          = 0;
        uint256 interestRate  = 0;
        uint256 percentToUse  = 0;

        if (contractMonthCount==12)
        {
                 if (capitalInWei<  1000 * 10**18)      { percentToUse=12;  interestRate=1125509;   plan=1; }   // SAPPHIRE
            else if (capitalInWei< 10000 * 10**18)      { percentToUse=15;  interestRate=1158650;   plan=2; }   // EMERALD
            else if (capitalInWei<100000 * 10**18)      { percentToUse=17;  interestRate=1181148;   plan=3; }   // RUBY
            else                                        { percentToUse=20;  interestRate=1215506;   plan=4; }   // DIAMOND
        }
        else if (contractMonthCount==24)
        {
                 if (capitalInWei<  1000 * 10**18)      { percentToUse=15;  interestRate=1342471;   plan=1; }
            else if (capitalInWei< 10000 * 10**18)      { percentToUse=17;  interestRate=1395110;   plan=2; }
            else if (capitalInWei<100000 * 10**18)      { percentToUse=20;  interestRate=1477455;   plan=3; }
            else                                        { percentToUse=30;  interestRate=1783478;   plan=4; }
        }
        else
        {
            return (0,0,0,0,0,0);                   // only 12 and 24 months are allowed here
        }

        uint256 overallTokensInWei  = (capitalInWei *  interestRate         ) / 1000000;
        uint256 tokenEarningsInWei  = overallTokensInWei - capitalInWei;
        uint256 earningPerTermInWei = tokenEarningsInWei / (contractMonthCount/3);      // 3 is for => Pays a Term of earning every 3 months

        return (overallTokensInWei,tokenEarningsInWei,earningPerTermInWei, percentToUse, interestRate, plan);
    }
    //--------------------------------------------------------------------------
    function    lockMoneyOnCompoundCreation(address toAddr, uint compountContractId)  internal  onlyOwner   returns (bool) 
    {
        require(toAddr!=0x0 && toAddr!=msg.sender);     // Prevent transfer to 0x0 address and to self, amount must be >0

        if (isHardcapReached())                                         
        {
            return false;       // an extra check first, who knows. 
        }

        TCompoundItem memory item = contracts[compountContractId];

        if (item.tokenCapitalInWei==0 || item.tokenEarningsInWei==0)    
        {
            return false;       // don&#39;t valid such invalid contract
        }

        //-----

        uint256 amountToLockInWei = item.tokenCapitalInWei + item.tokenEarningsInWei;
        uint256 availableTokens   = balances[owner];

        if (amountToLockInWei <= availableTokens)
        {
            uint256 balanceAfterTransfer = availableTokens.sub(amountToLockInWei);      

            if (balanceAfterTransfer >= icoReserveSupply)       // don&#39;t sell more than allowed during ICO
            {
                lockMoney(toAddr, item.tokenCapitalInWei, item.tokenEarningsInWei);
                return true;
            }
        }

        //emit log(&#39;Exiting lockMoneyOnCompoundCreation&#39;, &#39;cannot lock money&#39;);
        return false;
    }
    //--------------------------------------------------------------------------
    function    payCompoundTerm(uint contractId, uint8 termId, uint8 isCalledFromOutside)   public onlyOwner returns(int32)        // DON&#39;T SET icoNotPaused here, since a runnnig compound needs to run anyway
    {
        uint                    id;
        address                 investor;
        uint                    paidAmount;
        TCompoundItem   memory  item;

        if (!activeContractStatues[contractId])         
        {
            emit log("payCompoundTerm", "Specified contract is not actived (-1)");
            return -1;
        }

        item = contracts[contractId];

        //----- 
        if (item.isCancelled)   // That contract was never validated!!!
        {
            emit log("payCompoundTerm", "Compound contract already cancelled (-2)");
            return -2;
        }

        //-----

        if (item.isAllPaid)                             
        {
            emit log("payCompoundTerm", "All earnings already paid for this contract (-2)");
            return -4;   // everything was paid already
        }

        id = item.id;

        if (compoundPayStatus[id][termId]!=0)           
        {
            emit log("payCompoundTerm", "Specified contract&#39;s term was already paid (-5)");
            return -5;
        }

        if (now < compoundPayTimes[id][termId])         
        {
            emit log("payCompoundTerm", "It&#39;s too early to pay this term (-6)");
            return -6;
        }

        investor = item.investor;                                   // address of the owner of this compound contract

        //----- It&#39;s time for the payment, but was that contract already validated
        //----- If it was not validated, simply refund tokens to the main wallet

        if (!item.isContractValidated)                          // Compound contract self-destruction since no validation was made of it
        {
            uint    capital  = item.tokenCapitalInWei;
            uint    earnings = item.tokenEarningsInWei;

            contracts[contractId].isCancelled        = true;
            contracts[contractId].tokenCapitalInWei  = 0;       /// make sure nothing residual is left
            contracts[contractId].tokenEarningsInWei = 0;       ///

            //-----

            lockedCapitals[investor] = lockedCapitals[investor].sub(capital);
            lockedEarnings[investor] = lockedEarnings[investor].sub(earnings);

            balances[owner] = balances[owner].add(capital);
            balances[owner] = balances[owner].add(earnings);

            emit onCompoundContractCancelled(contractId, capital, earnings);
            emit log("payCompoundTerm", "Cancelling compound contract (-3)");
            return -3;
        }

        //---- it&#39;s PAY time!!!

        contracts[id].termPaidCount++;
        contracts[id].currentlyEarnedInWei += item.earningPerTermInWei;  

        compoundPayStatus[id][termId] = 1;                          // PAID!!!      meaning not to repay again this revenue term 

        unlockEarnings(investor, item.earningPerTermInWei);

        paidAmount = item.earningPerTermInWei;

        if (contracts[id].termPaidCount>=item.termCount && !contracts[item.id].isAllPaid)   // This is the last payment of all payments for this contract
        {
            contracts[id].isAllPaid = true;

            unlockCapital(investor, item.tokenCapitalInWei);

            paidAmount += item.tokenCapitalInWei;
        }

        //----- let&#39;s tell the blockchain now how many we&#39;ve unlocked.

        if (isCalledFromOutside==0 && paidAmount>0)
        {
            emit Transfer(owner, investor, paidAmount);
        }

        return 1;       // We just paid one earning!!!
                        // 1 IS IMPORTANT FOR THE TOKEN API. don&#39;t change it
    }
    //--------------------------------------------------------------------------
    function    validateCompoundContract(uint contractId) public onlyOwner   returns(uint)
    {
        TCompoundItem memory  item = contracts[contractId];

        if (item.isCancelled==true)
        {
            return 2;       // don&#39;t try to validated an already dead contract
        }

        contracts[contractId].isCancelled         = false;
        contracts[contractId].isContractValidated = true;

        emit onCompoundContractValidated(contractId);

        return 1;
    }
    //--------------------------------------------------------------------------
    //-----
    //----- When an investor (investor) is put money (capital) in a compound investor
    //----- We do calculate all interests (earnings) he will receive for the whole contract duration
    //----- Then we lock the capital and the earnings into special vaults.
    //----- We remove from the main token balance the capital invested and the future earnings
    //----- So there won&#39;t be wrong calculation when people wishes to buy tokens
    //-----
    //----- If you use the standard ERC20 balanceOf to check balance of an investor, you will see
    //----- balance = 0, if he just invested. This is normal, since money is locked in other vaults.
    //----- To check the exact money of the investor, use instead :
    //----- lockedCapitalOf(address investor)  
    //----- to see the amount of money he fully invested and which which is still not available to him
    //----- Use also
    //----- locakedEarningsOf(address investor)
    //----- It will show all the remaining benefit the person will get soon. The amount shown by This
    //----- function will decrease from time to time, while the real balanceOf(address investor)
    //----- will increase
    //-----
    //--------------------------------------------------------------------------
    function    lockMoney(address investor, uint capitalAmountInWei, uint totalEarningsToReceiveInWei) internal onlyOwner
    {
        uint totalAmountToLockInWei = capitalAmountInWei + totalEarningsToReceiveInWei;

        if (totalAmountToLockInWei <= balances[owner])
        {
            balances[owner] = balances[owner].sub(capitalAmountInWei.add(totalEarningsToReceiveInWei));     /// We remove capital & future earning from the Token&#39;s main balance, to put money in safe areas

            lockedCapitals[investor] = lockedCapitals[investor].add(capitalAmountInWei);            /// The capital invested is now locked during the whole contract
            lockedEarnings[investor] = lockedEarnings[investor].add(totalEarningsToReceiveInWei);   /// The whole earnings is full locked also in another vault called lockedEarnings

            emit Transfer(owner, investor, capitalAmountInWei);    // No need to show all locked amounts. Because these locked ones contain capital + future earnings. 
        }                                                            // So we just show the capital. the earnings will appear after each payment.
    }
    //--------------------------------------------------------------------------
    function    unlockCapital(address investor, uint amountToUnlockInWei) internal onlyOwner
    {
        if (amountToUnlockInWei <= lockedCapitals[investor])
        {
            balances[investor]       = balances[investor].add(amountToUnlockInWei);
            lockedCapitals[investor] = lockedCapitals[investor].sub(amountToUnlockInWei);    /// So to make all locked tokens available

            //---- No need of emit Transfer here. It is called from elsewhere
        }
    }
    //--------------------------------------------------------------------------
    function    unlockEarnings(address investor, uint amountToUnlockInWei) internal onlyOwner
    {
        if (amountToUnlockInWei <= lockedEarnings[investor])
        {
            balances[investor]       = balances[investor].add(amountToUnlockInWei);
            lockedEarnings[investor] = lockedEarnings[investor].sub(amountToUnlockInWei);    /// So to make all locked tokens available

            //---- No need of emit Transfer here. It is called from elsewhere
        }
    }
    //--------------------------------------------------------------------------
    function    lockedCapitalOf(address investor) public  constant  returns(uint256)
    {
        return lockedCapitals[investor];
    }
    //--------------------------------------------------------------------------
    function    lockedEarningsOf(address investor) public  constant  returns(uint256)
    {
        return lockedEarnings[investor];
    }  
    //--------------------------------------------------------------------------
    function    lockedBalanceOf(address investor) public  constant  returns(uint256)
    {
        return lockedCapitals[investor] + lockedEarnings[investor];
    }
    //--------------------------------------------------------------------------
    function    geCompoundTimestampsFor12Months(uint contractId) public view  returns(uint256,uint256,uint256,uint256)
    {
        uint32[12] memory t = compoundPayTimes[contractId];

        return(uint256(t[0]),uint256(t[1]),uint256(t[2]),uint256(t[3]));
    }
    //-------------------------------------------------------------------------
    function    geCompoundTimestampsFor24Months(uint contractId) public view  returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)
    {
        uint32[12] memory t = compoundPayTimes[contractId];

        return(uint256(t[0]),uint256(t[1]),uint256(t[2]),uint256(t[3]),uint256(t[4]),uint256(t[5]),uint256(t[6]),uint256(t[7]));
    }
    //-------------------------------------------------------------------------
    function    getCompoundContract(uint contractId) public constant    returns(address investor, 
                                                                        uint capital, 
                                                                        uint profitToGenerate,
                                                                        uint earnedSoFarAmount, 
                                                                        uint percent,
                                                                        uint interestRate,
                                                                        uint paidTermCount,
                                                                        uint isAllPaid,
                                                                        uint monthCount,
                                                                        uint earningPerTerm,
                                                                        uint isCancelled)
    {
        TCompoundItem memory item;

        item = contracts[contractId];

        return
        (
            item.investor,
            item.tokenCapitalInWei,
            item.tokenEarningsInWei,
            item.currentlyEarnedInWei,
            item.percent,
            item.interestRate,
            uint(item.termPaidCount),
            (item.isAllPaid) ? 1:0,
            item.contractMonthCount,
            item.earningPerTermInWei,
            (item.isCancelled) ? 1:0
        );
    }
    //-------------------------------------------------------------------------
    function    getCompoundPlan(uint contractId) public constant  returns(uint plan)
    {
        return contracts[contractId].plan;
    }
}
////////////////////////////////////////////////////////////////////////////////
contract    Token  is  CompoundContract
{
    using SafeMath  for uint256;

    //--------------------------------------------------------------------------
    //----- OVERRIDDEN FUNCTION :  "transfer" function from ERC20
    //----- For this smartcontract we don&#39;t deal with a deaLine date.
    //----- So it&#39;s a normally transfer function with no restriction.
    //----- Restricted tokens are inside the lockedTokens balances, not in ERC20 balances
    //----- That means people after 3 months can start using their earned tokens
    //--------------------------------------------------------------------------
    function transfer(address toAddr, uint256 amountInWei)  public      returns (bool)     // TRANSFER is not restricted during ICO!!!
    {
        require(toAddr!=0x0 && toAddr!=msg.sender && amountInWei>0);    // Prevent transfer to 0x0 address and to self, amount must be >0

        uint256 availableTokens = balances[msg.sender];

        //----- Checking Token reserve first : if during ICO    

        if (msg.sender==owner && !isHardcapReached())              // for RegerDiamond : handle reserved supply while ICO is running
        {
            assert(amountInWei<=availableTokens);

            uint256 balanceAfterTransfer = availableTokens.sub(amountInWei);      

            assert(balanceAfterTransfer >= icoReserveSupply);           // We try to sell more than allowed during an ICO
        }

        //-----

        balances[msg.sender] = balances[msg.sender].sub(amountInWei);
        balances[toAddr]     = balances[toAddr].add(amountInWei);

        emit Transfer(msg.sender, toAddr, amountInWei);

        return true;
    }
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    function    investFor12Months(address buyerAddress, uint256  amountInWei,
                                                          uint256  compoundContractId)
                                                public onlyOwner  
                                                returns(int)
    {

        uint    monthCount=12;

        if (!isHardcapReached())
        {
            if (initCompoundContract(buyerAddress, amountInWei, compoundContractId, monthCount))
            {
                if (!lockMoneyOnCompoundCreation(buyerAddress, compoundContractId))      // Now lock the main capital (amountInWei) until the end of the compound
                {
                    return -1;
                }
            }
            else 
            {
                return -2; 
            }
        }
        else        // ICO is over.  Use the ERC20 transfer now. Compound is now forbidden. Nothing more to lock 
        {
            Token.transfer(buyerAddress, amountInWei);
            return 2;
        }

        return 1;       // -1: could not lock the capital
                        // -2: Compound contract creation error
                        //  2: ICO is over, coumpounds no more allowed. Standard ERC20 transfer only
                        //  1: Compound contract created correctly
    }
    //--------------------------------------------------------------------------
    function    investFor24Months(address buyerAddress, uint256  amountInWei,
                                                        uint256  compoundContractId)
                                                public onlyOwner 
                                                returns(int)
    {

        uint    monthCount=24;

        if (!isHardcapReached())
        {
            if (initCompoundContract(buyerAddress, amountInWei, compoundContractId, monthCount))
            {
                if (!lockMoneyOnCompoundCreation(buyerAddress, compoundContractId))    // Now lock the main capital (amountInWei) until the end of the compound
                {
                    return -1; 
                }
            }
            else { return -2; }
        }
        else        // ICO is over.  Use the ERC20 transfer now. Compound is now forbidden. Nothing more to lock 
        {
            Token.transfer(buyerAddress, amountInWei);
            return 2;
        }

        return 1;       // -1: could not lock the capital
                        // -2: Compound contract creation error
                        //  2: ICO is over, coumpounds no more allowed. Standard ERC20 transfer only
                        //  1: Compound contract created correctly*/
    }
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
}