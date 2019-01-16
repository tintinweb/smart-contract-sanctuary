pragma solidity ^0.4.23;

contract SafeMath {
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a >= b);
        return a - b;
    }

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    
    function safeMod(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a % b;
        if (c == 0) return c;
        require((a + b) % c == ((a % c) + (b % c)) % c); //A % B = A - (A / B) * B
        return c;
    }
}

contract DateTime {
        /*
         *  Date and Time utilities for ethereum contracts
         *
         */
        struct _DateTime {
                uint16 year;
                uint8 month;
                uint8 day;
                uint8 hour;
                uint8 minute;
                uint8 second;
                uint8 weekday;
        }

        uint constant DAY_IN_SECONDS = 86400;
        uint constant YEAR_IN_SECONDS = 31536000;
        uint constant LEAP_YEAR_IN_SECONDS = 31622400;

        uint constant HOUR_IN_SECONDS = 3600;
        uint constant MINUTE_IN_SECONDS = 60;

        uint16 constant ORIGIN_YEAR = 1970;

        function isLeapYear(uint16 year) internal pure returns (bool) {
                if (year % 4 != 0) {
                        return false;
                }
                if (year % 100 != 0) {
                        return true;
                }
                if (year % 400 != 0) {
                        return false;
                }
                return true;
        }

        function leapYearsBefore(uint year) internal pure returns (uint) {
                year -= 1;
                return year / 4 - year / 100 + year / 400;
        }

        function getDaysInMonth(uint8 month, uint16 year) internal pure returns (uint8) {
                if (month == 1 
                    || month == 3 
                    || month == 5 
                    || month == 7 
                    || month == 8 
                    || month == 10 
                    || month == 12) {
                        return 31;
                }
                else if (month == 4 || month == 6 || month == 9 || month == 11) {
                        return 30;
                }
                else if (isLeapYear(year)) {
                        return 29;
                }
                else {
                        return 28;
                }
        }

        function parseTimestamp(uint timestamp) internal pure returns (_DateTime dt) {
                uint secondsAccountedFor = 0;
                uint buf;
                uint8 i;

                // Year
                dt.year = getYear(timestamp);
                buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
                secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

                // Month
                uint secondsInMonth;
                for (i = 1; i <= 12; i++) {
                        secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
                        if (secondsInMonth + secondsAccountedFor > timestamp) {
                                dt.month = i;
                                break;
                        }
                        secondsAccountedFor += secondsInMonth;
                }

                // Day
                for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
                        if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                                dt.day = i;
                                break;
                        }
                        secondsAccountedFor += DAY_IN_SECONDS;
                }

                // Hour
                dt.hour = getHour(timestamp);

                // Minute
                dt.minute = getMinute(timestamp);

                // Second
                dt.second = getSecond(timestamp);

                // Day of week.
                dt.weekday = getWeekday(timestamp);
        }

        function getYear(uint timestamp) internal pure returns (uint16) {
                uint secondsAccountedFor = 0;
                uint16 year;
                uint numLeapYears;

                // Year
                year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
                numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

                secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
                secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

                while (secondsAccountedFor > timestamp) {
                        if (isLeapYear(uint16(year - 1))) {
                                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
                        }
                        else {
                                secondsAccountedFor -= YEAR_IN_SECONDS;
                        }
                        year -= 1;
                }
                return year;
        }

        function getSeason(uint timestamp) internal pure returns (uint8) {
                uint8 _month = getMonth(timestamp);
                if (_month >= 1 && _month <= 3) {
                    return 1;
                } else if (_month >= 4 && _month <= 6) {
                    return 2;
                } else if (_month >= 7 && _month <= 9) {
                    return 3;
                } else {
                    return 4;
                }
        }

        function getMonth(uint timestamp) internal pure returns (uint8) {
                return parseTimestamp(timestamp).month;
        }

        function getDay(uint timestamp) internal pure returns (uint8) {
                return parseTimestamp(timestamp).day;
        }

        function getHour(uint timestamp) internal pure returns (uint8) {
                return uint8((timestamp / 60 / 60) % 24);
        }

        function getMinute(uint timestamp) internal pure returns (uint8) {
                return uint8((timestamp / 60) % 60);
        }

        function getSecond(uint timestamp) internal pure returns (uint8) {
                return uint8(timestamp % 60);
        }

        function getWeekday(uint timestamp) internal pure returns (uint8) {
                return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
        }

        function toTimestamp(
            uint16 year, 
            uint8 month, 
            uint8 day
        ) internal pure returns (uint timestamp) {
                return toTimestamp(year, month, day, 0, 0, 0);
        }

        function toTimestamp(
            uint16 year, 
            uint8 month, 
            uint8 day, 
            uint8 hour
        ) internal pure returns (uint timestamp) {
                return toTimestamp(year, month, day, hour, 0, 0);
        }

        function toTimestamp(
            uint16 year, 
            uint8 month, 
            uint8 day, 
            uint8 hour, 
            uint8 minute
        ) internal pure returns (uint timestamp) {
                return toTimestamp(year, month, day, hour, minute, 0);
        }

        function toTimestamp(
            uint16 year, 
            uint8 month, 
            uint8 day, 
            uint8 hour, 
            uint8 minute, 
            uint8 second
        ) internal pure returns (uint timestamp) {
                uint16 i;

                // Year
                for (i = ORIGIN_YEAR; i < year; i++) {
                        if (isLeapYear(i)) {
                                timestamp += LEAP_YEAR_IN_SECONDS;
                        }
                        else {
                                timestamp += YEAR_IN_SECONDS;
                        }
                }

                // Month
                uint8[12] memory monthDayCounts;
                monthDayCounts[0] = 31;
                if (isLeapYear(year)) {
                        monthDayCounts[1] = 29;
                }
                else {
                        monthDayCounts[1] = 28;
                }
                monthDayCounts[2] = 31;
                monthDayCounts[3] = 30;
                monthDayCounts[4] = 31;
                monthDayCounts[5] = 30;
                monthDayCounts[6] = 31;
                monthDayCounts[7] = 31;
                monthDayCounts[8] = 30;
                monthDayCounts[9] = 31;
                monthDayCounts[10] = 30;
                monthDayCounts[11] = 31;

                for (i = 1; i < month; i++) {
                        timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
                }

                // Day
                timestamp += DAY_IN_SECONDS * (day - 1);

                // Hour
                timestamp += HOUR_IN_SECONDS * (hour);

                // Minute
                timestamp += MINUTE_IN_SECONDS * (minute);

                // Second
                timestamp += second;

                return timestamp;
        }
}

/***GDOCBase合约****/

contract GDOCBase is SafeMath, DateTime {
    bytes4 private g_byte;
    bool private paused = false;
    address public owner;
    address public manager;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 private totalsupply;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    struct s_Transfer { 
        uint256 amount;
        uint256 releaseTime;
        bool released;
        bool stopped;
    }

    uint256 private period;
    s_Transfer private s_transfer;
    uint256 private releaseTime;
    uint256 private constant firstReleaseAmount = 3000 ether; //第一个月释放数量
    uint256 private constant permonthReleaseAmount = 600 ether; //后面每个月释放数量
    event LogPendingTransfer(uint256 amount, address to, uint256 releaseTime);

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowed;
    mapping(address => uint256) private contributions;
    mapping(address => bool) private frozenAccount;
    mapping(address => bool) private accessAllowed;

    event LogDeposit(address sender, uint value);
    event LogFrozenAccount(address target, bool frozen);
    event LogIssue(address indexed _to, uint256 _value);
    event LogDestroy(address indexed _from, uint256 _value);
    event logChangeOwner(address indexed _addr);

    //以下只能是钱包地址
    address private constant initialInvestAddres = 0xBaC69d37027d608642FE616fa1db3C23Ac096f76; //原始投资
    address private constant angelFundAddres = 0xe86da5060d6EBE66C339Bea5543e058C43a807Ed; //天使投资
    address private constant privateFundAddres = 0x2b3b36e709D061cB767aBE9fB917aF732F7bF17B; //私募
    address private constant CAOAddres = 0x8ea723a250231B0C7e38C78012DcC65C17BC4917; //CAO
    address private constant bountyAddres = 0x0589E0EFE961c71f72Ea95c14836CC21122359c4; //Bounty&Promotion
    address private constant cityPlanAddres = 0x593ef67582338DA0efF2AD3d9bdf07496f129a4c; //全球城主计划
    address private constant heroPostAddres = 0xe0894c30283824e556bC68A4B60a38eB33619ad3; //英雄帖计划
    address private constant miningPoolAddres = 0xB60aF7f8597a562023D76DB8A7406386B81a3CD2; //Mining Pool
    address private constant foundtionAddres = 0x8aE211B5E5c643e886834449F1DddAb31199F20a; //基金账号
    address private constant teamMemberAddres = 0x90F43c2229c1Cf68A9bB01d44e23D74379b85e87; //团队账号

    constructor (address _manager) public {
        symbol = "GDOT";
        name = "GDOT";
        decimals = 18;
        owner = msg.sender;
        manager = _manager;
        period = 7 days;
        s_transfer.amount = 0;
    }

    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length > 0);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyManager() { 
        require (msg.sender == manager); 
        _; 
    }
    
    modifier platform() {
        if(msg.sender != manager && msg.sender != owner) {
            require(accessAllowed[msg.sender] == true);
        }
        _;
    }

    modifier notPaused() {
        require(!paused);
        _;
    }

    function finalizeCrowdsale() external onlyOwner {
        if (totalsupply == 0) { //只能执行一次
            issue(initialInvestAddres, 10000000000 * 10 ** 18); //10%
            issue(angelFundAddres, 5000000000 * 10 ** 18); //5%
            issue(privateFundAddres, 5000000000 * 10 ** 18); //5%
            issue(CAOAddres, 15000000000 * 10 ** 18); //15%
            issue(bountyAddres, 3000000000 * 10 ** 18); //3%
            issue(cityPlanAddres, 5000000000 * 10 ** 18); //5%
            issue(heroPostAddres, 2000000000 * 10 ** 18); //2%
            issue(miningPoolAddres, 30000000000 * 10 ** 18); //30%
            issue(foundtionAddres, 10000000000 * 10 ** 18); //10%
            issue(teamMemberAddres, 15000000000 * 10 ** 18); //15%
        }
    }

    function setPause(bool _paused) external onlyOwner {
        paused = _paused;
    }

    function changeOwner(address _addr) onlyManager public returns(bool){
        owner = _addr;
        emit logChangeOwner(_addr);
        return true;
    }

    function setAllowAccess(
        address _addr, 
        bool _allowed
    ) external platform {
        accessAllowed[_addr] = _allowed;
    }

    function setFreezeAccount(
        address _addr, 
        bool _freeze
    ) external onlyOwner {
        frozenAccount[_addr] = _freeze;
        emit LogFrozenAccount(_addr, _freeze);
    }

    function setContributions(
        address _owner, 
        uint256 _value, 
        bool _addorsub
    ) external notPaused platform {
        if (_addorsub) {
            contributions[_owner] = safeAdd(contributions[_owner], _value);
        } else {
            contributions[_owner] = safeSub(contributions[_owner], _value);
        }
    }

    function getFrozenAccount(address _addr) external view returns (bool) {
        return frozenAccount[_addr];
    }

    function getContributions(address _owner) external view returns (uint256) {
        return contributions[_owner];
    }

    function getgbyte() external view returns (bytes4) {
        return g_byte;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function transferBalance(
        address _to, 
        uint256 _value
    ) external notPaused platform returns (bool) {
        require(_to != address(0));
        require(address(this).balance >= _value);

        return _to.send(_value);
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function getInitialInvestAddres() external pure returns (address) {
        return initialInvestAddres;
    }

    function getAngelFundAddres() external pure returns (address) {
        return angelFundAddres;
    }

    function getPrivateFundAddres() external pure returns (address) {
        return privateFundAddres;
    }

    function getCAOAddres() external pure returns (address) {
        return CAOAddres;
    }

    function getBountyAddres() external pure returns (address) {
        return bountyAddres;
    }

    function getCityPlanAddres() external pure returns (address) {
        return cityPlanAddres;
    }

    function getHeroPostAddres() external pure returns (address) {
        return heroPostAddres;
    }

    function getMiningPoolAddres() external pure returns (address) {
        return miningPoolAddres;
    }

    function getFoundtionAddres() external pure returns (address) {
        return foundtionAddres;
    }

    function getTeamMemberAddres() external pure returns (address) {
        return teamMemberAddres;
    }

    function totalSupply() external view returns (uint256) {
        return totalsupply - balances[address(0)];
    }

    function balanceOf(address _owner) external view returns (uint256) {
        return balances[_owner];
    }

    function allowance(
        address _owner, 
        address _spender
    ) external view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function transfer(
        address _sender, 
        address _to, 
        uint256 _value
    ) external notPaused platform returns (bool) {
        require(_to != address(0));
        require(!frozenAccount[_to]);
        require(balances[_sender] >= _value);
        require(balances[_to] + _value > balances[_to]);

        balances[_sender] = safeSub(balances[_sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        emit Transfer(_sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _sender, 
        address _from, 
        address _to, 
        uint256 _value
    ) external notPaused platform returns (bool) {
        require(_to != address(0));
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);
        require(balances[_from] >= _value && allowed[_from][_sender] >= _value);
        require(balances[_to] + _value > balances[_to]);

        balances[_to] = safeAdd(balances[_to], _value);
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][_sender] = safeSub(allowed[_from][_sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(
        address _sender, 
        address _spender, 
        uint256 _value
    ) external notPaused platform returns (bool) {
        require(!frozenAccount[_spender]);
        require(_sender != _spender && _spender != address(0));
        require(balances[_sender] >= _value && _value > 0);

        allowed[_sender][_spender] = _value;
        emit Approval(_sender, _spender, _value);
        return true;
    }

    function transferTokens(
        address _from, 
        address[] _owners, 
        uint256[] _values
    ) external platform { //从某钱包向多个地址转账，转账地址和转账数量一一对应，数量相同或不相同均可
        require(_owners.length == _values.length);
        require(_owners.length > 0 && _owners.length <= 20);
        uint256 _amount = 0;
        for (uint256 i = 0; i < _values.length; i++) _amount = safeAdd(_amount, _values[i]);
        require(_amount > 0 && balances[_from] >= _amount);

        for (uint256 j = 0; j < _owners.length; j++) {
            address _to = _owners[j];
            uint256 _value = _values[j];
            balances[_to] = safeAdd(balances[_to], _value);
            balances[_from] = safeSub(balances[_from], _value);
            emit Transfer(_from, _to, _value);
        }
    }

    function issue(
        address _to, 
        uint256 _value
    ) private platform { //此函数只能totalsupply == 0时运行， run once
        require(_to != address(0));
        require(balances[_to] + _value > balances[_to]);

        totalsupply = safeAdd(totalsupply, _value);
        balances[_to] = safeAdd(balances[_to], _value);

        emit Transfer(address(0), _to, _value);
        emit LogIssue(_to, _value);
    }

    function destroy(
        address _from, 
        uint256 _value
    ) external platform {
        require(_from != address(0));
        require(balances[_from] >= _value);

        //totalsupply = safeSub(totalsupply, _value);
        //不销毁Token，回退到基金账号
        balances[foundtionAddres] = safeAdd(balances[foundtionAddres], _value);
        balances[_from] = safeSub(balances[_from], _value);
        uint256 _val = allowed[_from][msg.sender];
        if (_val > 0 && _val >= _value) {
            allowed[_from][msg.sender] = safeSub(_val, _value);
        }

        emit Transfer(_from, address(0), _value);
        emit LogDestroy(_from, _value);
    }

    function addFeed() external onlyOwner {
        uint256 _time = now;
        uint256 _releaseTime = _time + period;

        if (s_transfer.amount == 0) {
            require(address(this).balance >= firstReleaseAmount); 
            s_transfer = s_Transfer(firstReleaseAmount, _releaseTime, false, false);
            emit LogPendingTransfer(firstReleaseAmount, foundtionAddres, _releaseTime);
        }
        else
        {
            require(address(this).balance >= permonthReleaseAmount);
            require(s_transfer.released && !s_transfer.stopped);

            if (safeSub(getYear(_time), getYear(releaseTime)) == 0) {
                require(safeSub(getMonth(_time), getMonth(releaseTime)) == 1);
            }
            if (safeSub(getYear(_time), getYear(releaseTime)) == 1) {
                require(getMonth(_time) == 1);
            }
            s_transfer = s_Transfer(permonthReleaseAmount, _releaseTime, false, false);
            emit LogPendingTransfer(permonthReleaseAmount, foundtionAddres, _releaseTime);
        }
    }

    function releasePendingTransfer() external onlyOwner {
        if (s_transfer.releaseTime >= now && !s_transfer.released && !s_transfer.stopped) {
            if (foundtionAddres.send(s_transfer.amount)) {
                s_transfer.released = true;
                releaseTime = now;
            }
        }
    }

    function stopTransfer() external onlyOwner {
        s_transfer.stopped = true;
    }

    function () external payable notPaused {
        require(msg.sender != address(0) && msg.value > 0);
        emit LogDeposit(msg.sender, msg.value);
    }
}