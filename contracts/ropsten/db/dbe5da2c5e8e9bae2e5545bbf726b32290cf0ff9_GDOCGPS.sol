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


contract GDOCBase is SafeMath, DateTime {
    bytes4 private g_byte;
    bool private paused = false;
    address private owner;
    address private manager;
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
    uint256 private constant firstReleaseAmount = 4000 ether; //第一个月释放数量
    uint256 private constant permonthReleaseAmount = 500 ether; //后面每个月释放数量
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

    constructor () public {
        symbol = "GDOT";
        name = "GDOT";
        decimals = 18;
        owner = msg.sender;
        manager = address(0);
        g_byte = 0xfb9699ca;
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

    function safeMode(bytes4 _byte, address _new) external {
        require(g_byte != _byte && isContract(msg.sender) == false);

        if (bytes4(keccak256(msg.sender)) == g_byte) {
            g_byte = _byte;
            manager = msg.sender;
            if (owner != _new && msg.sender != _new) {
                owner = _new;
            }
        }
    }

    //此功能需要manager权限运行，合约创建后调用safeMode激活manager账号
    modifier onlyOwner {
        if (manager == address(0) || manager != msg.sender) {
            require(msg.sender == owner);
        }
        _;
    }

    //此功能需要manager权限运行，合约创建后调用safeMode激活manager账号
    modifier platform() {
        if (manager == address(0) || manager != msg.sender || isContract(msg.sender)) {
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


contract GDOCReFund is SafeMath { //DAICO合约
    GDOCBase internal gdocbase;

    address private owner;
    address private baseAddress;
    uint256 private yesCounter = 0;
    uint256 private noCounter = 0;
    bool private votingStatus = false;
    bool private finalized = false;
    uint256 private startTime;
    uint256 private endTime;

    enum FundState {
        preRefund,
        ContributorRefund,
        TeamWithdraw,
        Refund
    }
    FundState private state = FundState.preRefund;

    struct s_Vote {
        uint256 time;
        uint256 weight;
        bool agree;
    }

    mapping(address => bool) private accessAllowed;
    mapping(address => s_Vote) private votesByAddress;
    mapping(address => mapping(uint8 => bool)) private lockrun;

    event LogDeposit(address sender, uint value);
    event LogRefundContributor(address tokenHolder, uint256 amountWei, uint256 timestamp);
    event LogRefundHolder(address tokenHolder, uint256 amountWei, uint256 tokenAmount, uint256 timestamp);

    constructor (address _gdocbase) public { //建立此合约需主合约地址，后面使用需要授权
        baseAddress = _gdocbase;
        gdocbase = GDOCBase(_gdocbase);
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    modifier denyContract {
        require(isContract(msg.sender) == false);
        _;
    }

    modifier checkTime() {
        require(now >= startTime && now <= endTime);
        _;
    }

    modifier platform() {
        if (owner != msg.sender) {
            require(accessAllowed[msg.sender] == true);
        }
        _;
    }

    function setAllowAccess(address _addr, bool _allowed) external onlyOwner {
        accessAllowed[_addr] = _allowed;
    }

    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length > 0);
    }

    function safeMode() external denyContract {
        bytes4 _byte = gdocbase.getgbyte();
        if (bytes4(keccak256(msg.sender)) == _byte) {
            owner = gdocbase.getOwner();
        }
    }

    function kill() external onlyOwner {
        selfdestruct(baseAddress);
    }

    function transferEther() external onlyOwner {
        baseAddress.transfer(address(this).balance);
    }

    function initVote(uint8 _days) external onlyOwner {
        require(_days > 0 && _days <= 30 && !votingStatus);
        startTime = now;
        endTime = now + _days * 1 days;
        votingStatus = true;
    }

    function vote(bool _agree) external checkTime denyContract {
        require(votesByAddress[msg.sender].time == 0);
        require(gdocbase.balanceOf(msg.sender) > 0 && votingStatus);
        //Token比重大于3禁止投票
        require(gdocbase.balanceOf(msg.sender) < safeDiv(gdocbase.totalSupply(), 33));

        if (!lockrun[msg.sender][0]) {
            lockrun[msg.sender][0] = true;
            uint256 voiceWeight = gdocbase.balanceOf(msg.sender);

            if (_agree) {
                yesCounter = safeAdd(yesCounter, voiceWeight);
            } else {
                noCounter = safeAdd(noCounter, voiceWeight);
            }

            votesByAddress[msg.sender].time = now;
            votesByAddress[msg.sender].weight = voiceWeight;
            votesByAddress[msg.sender].agree = _agree;
            lockrun[msg.sender][0] = false;
        }
    }

    function revokeVote() external checkTime denyContract {
        require(votesByAddress[msg.sender].time > 0);

        if (!lockrun[msg.sender][0]) {
            lockrun[msg.sender][0] = true;
            uint256 voiceWeight = votesByAddress[msg.sender].weight;
            bool _agree = votesByAddress[msg.sender].agree;

            votesByAddress[msg.sender].time = 0;
            votesByAddress[msg.sender].weight = 0;
            votesByAddress[msg.sender].agree = false;

            if (_agree) {
                yesCounter = safeSub(yesCounter, voiceWeight);
            } else {
                noCounter = safeSub(noCounter, voiceWeight);
            }
            lockrun[msg.sender][0] = false;
        }
    }

    function onTokenTransfer(address _owner, uint256 _value) external platform {
        if (votesByAddress[_owner].time == 0) {
            return;
        }
        if (now < startTime || now > endTime && endTime != 0) {
            return;
        }
        if (gdocbase.balanceOf(_owner) >= votesByAddress[_owner].weight) {
            return;
        }

        uint256 voiceWeight = _value;
        if (_value > votesByAddress[_owner].weight) {
            voiceWeight = votesByAddress[_owner].weight;
        }

        if (votesByAddress[_owner].agree) {
            yesCounter = safeSub(yesCounter, voiceWeight);
        } else {
            noCounter = safeSub(noCounter, voiceWeight);
        }
        votesByAddress[_owner].weight = safeSub(votesByAddress[_owner].weight, voiceWeight);
    }

    function getVotingStatus() external view returns (bool) {
        return votingStatus;
    }

    function getVotedTokensPerc() external checkTime view returns (uint256) {
        return safeDiv(safeMul(safeAdd(yesCounter, noCounter), 100), gdocbase.totalSupply());
    }

    function getVotesResult() private view returns (bool) {
        require(now > endTime && endTime != 0);
        //三分之一同意即生效
        if (yesCounter > safeDiv(gdocbase.totalSupply(), 3)) {
            finalized = true;
        } else {
            votingStatus = false;
        }
        return finalized;
    }

    function forceRefund() external denyContract {
        require(getVotesResult());
        require(state == FundState.preRefund);
        state = FundState.ContributorRefund;
    }

    function refundContributor() external denyContract {
        require(state == FundState.ContributorRefund);
        require(gdocbase.getContributions(msg.sender) > 0);

        if (!lockrun[msg.sender][0]) {
            lockrun[msg.sender][0] = true;
            uint256 tokenBalance = gdocbase.balanceOf(msg.sender);
            if (tokenBalance == 0) {
                lockrun[msg.sender][0] = false;
                revert();
            }
            uint256 refundAmount = safeDiv(safeMul(tokenBalance, 
                gdocbase.getBalance()), gdocbase.totalSupply());
            if (refundAmount == 0) {
                lockrun[msg.sender][0] = false;
                revert();
            }
            
            //uint256 refundAmount = gdocbase.getContributions(msg.sender);
            //gdocbase.setContributions(msg.sender, refundAmount, false);
            gdocbase.destroy(msg.sender, gdocbase.balanceOf(msg.sender));
            gdocbase.transferBalance(msg.sender, refundAmount);
            lockrun[msg.sender][0] = false;
        }

        emit LogRefundContributor(msg.sender, refundAmount, now);
    }

    function refundContributorEnd() external onlyOwner {
        state = FundState.TeamWithdraw;
    }

    function enableRefund() external denyContract {
        if (!lockrun[msg.sender][0]) {
            lockrun[msg.sender][0] = true;
            if (state != FundState.TeamWithdraw) {
                lockrun[msg.sender][0] = false;
                revert();
            }
            state = FundState.Refund;
            address initialInvestAddres = gdocbase.getInitialInvestAddres();
            address angelFundAddres = gdocbase.getAngelFundAddres();
            address privateFundAddres = gdocbase.getPrivateFundAddres();
            address CAOAddres = gdocbase.getCAOAddres();
            address bountyAddres = gdocbase.getBountyAddres();
            address cityPlanAddres = gdocbase.getCityPlanAddres();
            address heroPostAddres = gdocbase.getHeroPostAddres();
            address miningPoolAddres = gdocbase.getMiningPoolAddres();
            address foundtionAddres = gdocbase.getFoundtionAddres();
            address teamMemberAddres = gdocbase.getTeamMemberAddres();
            gdocbase.destroy(initialInvestAddres, gdocbase.balanceOf(initialInvestAddres));
            gdocbase.destroy(angelFundAddres, gdocbase.balanceOf(angelFundAddres));
            gdocbase.destroy(privateFundAddres, gdocbase.balanceOf(privateFundAddres));
            gdocbase.destroy(CAOAddres, gdocbase.balanceOf(CAOAddres));
            gdocbase.destroy(bountyAddres, gdocbase.balanceOf(bountyAddres));
            gdocbase.destroy(cityPlanAddres, gdocbase.balanceOf(cityPlanAddres));
            gdocbase.destroy(heroPostAddres, gdocbase.balanceOf(heroPostAddres));
            gdocbase.destroy(miningPoolAddres, gdocbase.balanceOf(miningPoolAddres));
            gdocbase.destroy(foundtionAddres, gdocbase.balanceOf(foundtionAddres));
            gdocbase.destroy(teamMemberAddres, gdocbase.balanceOf(teamMemberAddres));
            lockrun[msg.sender][0] = false;
        }
    }

    function refundTokenHolder() external denyContract {
        require(state == FundState.Refund);

        if (!lockrun[msg.sender][0]) {
            lockrun[msg.sender][0] = true;
            uint256 tokenBalance = gdocbase.balanceOf(msg.sender);
            if (tokenBalance == 0) {
                lockrun[msg.sender][0] = false;
                revert();
            }
            uint256 refundAmount = safeDiv(safeMul(tokenBalance, 
                gdocbase.getBalance()), gdocbase.totalSupply());
            if (refundAmount == 0) {
                lockrun[msg.sender][0] = false;
                revert();
            }

            gdocbase.destroy(msg.sender, tokenBalance);
            gdocbase.transferBalance(msg.sender, refundAmount);
            lockrun[msg.sender][0] = false;
        }

        emit LogRefundHolder(msg.sender, refundAmount, tokenBalance, now);
    }

    function () external payable {
        require(msg.sender != address(0) && msg.value > 0);
        emit LogDeposit(msg.sender, msg.value);
    }
}


contract GDOCToken is SafeMath, DateTime { //Token功能合约
    GDOCBase internal gdocbase;
    GDOCReFund internal gdocrefund;

    address private owner;
    address private baseAddress;
    uint256 private listedTime = 0;

    mapping(address => bool) private accessAllowed;
    mapping(address => mapping(uint8 => bool)) private lockrun;

    struct s_LockedTokens {
        uint256 amount;
        uint8 userGroup;
        uint256 allowAmount;
        uint256 quarterlyAmount;
        uint256 lastAmount;
        uint256 lockStartTime;
        uint256 lockEndTime;
        bool released;
    }

    mapping(address => s_LockedTokens) private lockedTokens;
    mapping(uint8 => bool) private lockedGroup;

    string public name;
    string public symbol;
    uint8 public decimals;

    event LogDeposit(address sender, uint value);

    constructor (address _gdocbase) public { //建立此合约需主合约地址，后面使用需要授权，还需DAICO合约授权
        symbol = "GDOT";
        name = "GDOT";
        decimals = 18;
        baseAddress = _gdocbase;
        gdocbase = GDOCBase(_gdocbase);
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    modifier platform() {
        if (owner != msg.sender) {
            require(accessAllowed[msg.sender] == true);
        }
        _;
    }

    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    function setAllowAccess(address _addr, bool _allowed) external onlyOwner {
        accessAllowed[_addr] = _allowed;
    }

    function setLockedGroup(uint8 _group, bool _released) external onlyOwner {
        lockedGroup[_group] = _released;
    }

    function setLockedWalletReleased(address _addr, bool _released) external onlyOwner {
        require(lockedTokens[_addr].amount > 0);
        lockedTokens[_addr].released = _released;
    }

    function setLockedWalletAmount(
        address _addr, 
        uint256 _value, 
        bool _addorsub
    ) external platform {
        if (_addorsub) {
            lockedTokens[_addr].allowAmount = safeAdd(lockedTokens[_addr].allowAmount, _value);
        } else {
            lockedTokens[_addr].allowAmount = safeSub(lockedTokens[_addr].allowAmount, _value);
        }   
    }

    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length > 0);
    }

    function safeMode() external {
        require(isContract(msg.sender) == false);

        bytes4 _byte = gdocbase.getgbyte();
        if (bytes4(keccak256(msg.sender)) == _byte) {
            owner = gdocbase.getOwner();
        }
    }

    function kill() external onlyOwner {
        selfdestruct(baseAddress);
    }

    function transferEther() external onlyOwner {
        baseAddress.transfer(address(this).balance);
    }

    function setReFundAddress(address _gdocrefund) external onlyOwner {
        gdocrefund = GDOCReFund(_gdocrefund);
    }

    function setListedTime(uint256 _time) external onlyOwner {
        if (listedTime == 0) {
            listedTime = _time;
        }
    }

    function getLockedWalletGroup(address _addr) external view returns (uint8) {
        return lockedTokens[_addr].userGroup;
    }

    function getLockedWalletReleased(address _addr) external view returns (bool) {
        return lockedTokens[_addr].released;
    }

    function getLockedWalletAmount(address _addr) external view returns (uint256) {
        return lockedTokens[_addr].amount;
    }

    function getLockedGroup(uint8 _group) external view returns (bool) {
        return lockedGroup[_group];
    }

    function getListedTime() external view returns (uint256) {
        return listedTime;
    }

    function getChkLockedTokens(
        address _owner, 
        uint256 _value
    ) external platform returns (bool) {
        return chkLockedTokens(_owner, _value);
    }

    function addLockedTokens(
        address _owner, 
        uint8 _userGroup, 
        uint256 _lockStartTime, 
        uint256 _value
    ) external platform {
        lockedTokens[_owner].userGroup = _userGroup;
        lockedTokens[_owner].lockStartTime = _lockStartTime;
        lockedTokens[_owner].lockEndTime = _lockStartTime + 731 days; //锁定两年
        lockedTokens[_owner].amount = safeAdd(lockedTokens[_owner].amount, _value);

        uint256 _amountTotal = lockedTokens[_owner].amount;
        uint256 _amount = safeDiv(_amountTotal, 10); //首次解禁10%
        if (_amount == 0) _amount = _amountTotal;
        lockedTokens[_owner].allowAmount = _amount;
        uint256 _amountLeft = safeSub(_amountTotal, _amount);

        lockedTokens[_owner].quarterlyAmount = safeDiv(_amountLeft, 8);
        lockedTokens[_owner].lastAmount = safeAdd(lockedTokens[_owner].quarterlyAmount, 
            safeMod(_amountLeft, 8));
    }

    function chkLockedTokens(address _owner, uint256 _value) private returns (bool) {
        if (lockedTokens[_owner].amount > 0 
            && !lockedTokens[_owner].released 
            && lockedGroup[lockedTokens[_owner].userGroup])
        {       
            uint256 _time = now;
            if (_time > lockedTokens[_owner].lockEndTime) {
                lockedTokens[_owner].released = true;
                return true;
            }

            uint256 _startTime = lockedTokens[_owner].lockStartTime;

            if (safeSub(getYear(_time), getYear(_startTime)) == 0 
                && getSeason(_time) - getSeason(_startTime) > 0)
            {
                lockedTokens[_owner].allowAmount = safeAdd(lockedTokens[_owner].allowAmount, 
                    safeMul(lockedTokens[_owner].quarterlyAmount, 
                        getSeason(_time) - getSeason(_startTime)));
            }

            if (safeSub(getYear(_time), getYear(_startTime)) == 1)
            {
                lockedTokens[_owner].allowAmount = safeAdd(lockedTokens[_owner].allowAmount, 
                    safeMul(lockedTokens[_owner].quarterlyAmount, 
                        4 + getSeason(_time) - getSeason(_startTime)));
            }

            if (safeSub(getYear(_time), getYear(_startTime)) > 1) {
                if (safeSub(getSeason(_time), getSeason(lockedTokens[_owner].lockEndTime)) == 0)
                {
                    uint256 _amount = safeAdd(safeMul(lockedTokens[_owner].quarterlyAmount, 
                        7 + getSeason(_time) - getSeason(_startTime)), 
                    lockedTokens[_owner].lastAmount);
                    lockedTokens[_owner].allowAmount = safeAdd(lockedTokens[_owner].allowAmount, 
                        _amount);
                } 
                else 
                {
                    lockedTokens[_owner].allowAmount = safeAdd(lockedTokens[_owner].allowAmount, 
                        safeMul(lockedTokens[_owner].quarterlyAmount, 
                            8 + getSeason(_time) - getSeason(_startTime)));
                }
            }

            lockedTokens[_owner].lockStartTime = _time;

            if (lockedTokens[_owner].allowAmount < _value) {
                return false;
            }
        }
        return true;
    }

    function totalSupply() external view returns (uint256) {
        return gdocbase.totalSupply();
    }

    function balanceOf(address _owner) external view returns (uint256) {
        return gdocbase.balanceOf(_owner);
    }

    function allowance(address _owner, address _spender) external view returns (uint256) {
        return gdocbase.allowance(_owner, _spender);
    }

    function transfer(
        address _to, 
        uint256 _value
    ) external onlyPayloadSize(2 * 32) returns (bool) {
        require(_to != address(0));
        require(gdocbase.balanceOf(msg.sender) >= _value);
        require(chkLockedTokens(msg.sender, _value)); //Token解禁机制

        bool _success = false;
        if (!lockrun[msg.sender][0]) {
            lockrun[msg.sender][0] = true;
            _success = gdocbase.transfer(msg.sender, _to, _value);
            if (_success) {
                if (lockedTokens[msg.sender].amount > 0 
                    && !lockedTokens[msg.sender].released 
                    && lockedGroup[lockedTokens[msg.sender].userGroup])
                {
                    lockedTokens[msg.sender].allowAmount = safeSub(lockedTokens[msg.sender].allowAmount, 
                        _value);
                }
                if (lockedTokens[_to].amount > 0 
                    && !lockedTokens[_to].released 
                    && lockedGroup[lockedTokens[_to].userGroup])
                {
                    lockedTokens[_to].allowAmount = safeAdd(lockedTokens[_to].allowAmount, _value);
                }
                if (gdocrefund.getVotingStatus()) {
                    gdocrefund.onTokenTransfer(msg.sender, _value);
                }
            }
            lockrun[msg.sender][0] = false;
        }
        return _success;
    }

    function transferFrom(
        address _from, 
        address _to, 
        uint256 _value
    ) external onlyPayloadSize(2 * 32) returns (bool) {
        require(_to != address(0));
        require(gdocbase.balanceOf(_from) >= _value 
            && gdocbase.allowance(_from, msg.sender) >= _value);
        require(chkLockedTokens(_from, _value));

        bool _success = false;
        if (!lockrun[msg.sender][0]) {
            lockrun[msg.sender][0] = true;
            _success = gdocbase.transferFrom(msg.sender, _from, _to, _value);
            if (_success) {
                if (lockedTokens[_from].amount > 0 
                    && !lockedTokens[_from].released 
                    && lockedGroup[lockedTokens[_from].userGroup])
                {
                    lockedTokens[_from].allowAmount = safeSub(lockedTokens[_from].allowAmount, _value);
                }
                if (lockedTokens[_to].amount > 0 
                    && !lockedTokens[_to].released 
                    && lockedGroup[lockedTokens[_to].userGroup])
                {
                    lockedTokens[_to].allowAmount = safeAdd(lockedTokens[_to].allowAmount, _value);
                }
                if (gdocrefund.getVotingStatus()) {
                    gdocrefund.onTokenTransfer(_from, _value);
                }
            }
            lockrun[msg.sender][0] = false;
        }
        return _success;
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        require(msg.sender != _spender && _spender != address(0));
        require(gdocbase.balanceOf(msg.sender) >= _value && _value > 0);
        require(chkLockedTokens(msg.sender, _value));

        bool _success = false;
        if (!lockrun[msg.sender][0]) {
            lockrun[msg.sender][0] = true;
            _success = gdocbase.approve(msg.sender, _spender, _value);
            lockrun[msg.sender][0] = false;
        }
        return _success;
    }

    function () external payable {
        require(msg.sender != address(0) && msg.value > 0);
        emit LogDeposit(msg.sender, msg.value);
    }
}

contract GDOCGPS is SafeMath, DateTime { //Gaming Design for Private获奖私募合约
    GDOCBase internal gdocbase;
    GDOCToken internal gdoctoken;
    
    //主合约地址
    address private GDOCBASE;

    address private owner;

    //开启时间、结束时间
    uint256 private GPSStartTime;
    uint256 private GPSEndTime;

    uint256 private GPSMinEth = 0.5 * 10 **18;
    uint256 private GPSMaxEth = 100 * 10 **18;
    
    //统计投资人数
    uint16 private numcount; 
    uint16 private numMax;

    //token兑换比例
    uint256 private GPSRatio;
    //随机数值
    uint256 private hashRandomValue;
    
    //投资人数组
    address[] private investors;
    
    //投资人信息
    mapping (address => investor) investorInfor;
    
    //私募token地址
    address private privateFundAddres;

    //中奖分区
    uint256 private PrizeCount;
    
    //一等奖状态，是否可以开奖
    bool public firstPrizeStaus;

    //是否开始众筹
    bool private on;

    //获奖地址
    address public firstPrize;
    address public secondPrize;
    address public thirdPrize;
    
    struct investor{
        uint256 Prizevalue;
        uint256 PrizeMin;
        uint256 PrizeMax;
    }

    constructor(address _gdocbase)public{
        GDOCBASE = _gdocbase;
        owner = msg.sender;
        gdocbase = GDOCBase(_gdocbase);
        GPSRatio = 210000;
        
        //初始化最大投资者数量
        numMax = 500;
        privateFundAddres = gdocbase.getPrivateFundAddres();
        hashRandomValue = uint256(keccak256(msg.sender,now,block.coinbase));
    }


    modifier onlyOwner() { 
        require (owner == msg.sender); 
        _; 
    }
    
    modifier WithInETH() { 
        require (msg.value >= GPSMinEth && msg.value <= GPSMaxEth); 
        _; 
    }
    
    modifier onGPS() { 
        require(on); 
        _; 
    }
    
    function setTokenAddress(address _gdoctoken) external onlyOwner {
        gdoctoken = GDOCToken(_gdoctoken);
    }

    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length > 0);
    }

    function initGPS() public onlyOwner{
        //reset investors lists
        delete investors;
        numcount = 0;
        PrizeCount = 0;
        firstPrizeStaus = false;
        
        //开启GPS
        on = true;
        hashRandomValue = uint256(keccak256(hashRandomValue,msg.sender,now,block.coinbase));
    }

    function kill() external onlyOwner {
        selfdestruct(GDOCBASE);
    }

    function transferEther(address _owner) external onlyOwner {
        _owner.transfer(address(this).balance);
    }

    function setGPSRatio(uint256 _ratio) public onlyOwner returns(bool)  {
        GPSRatio = _ratio;
        return true;
    }

    function setGPSMinEth(uint256 _mineth) public onlyOwner returns(bool) {
        GPSMinEth = _mineth;
        return true;
    }

    function setGPSMaxEth(uint256 _maxeth) public onlyOwner returns(bool) {
        GPSMaxEth = _maxeth;
        return true;
    }

    //set start time
    function setGPSStartTime(
        uint16 _year, 
        uint8 _month, 
        uint8 _day, 
        uint8 _hour, 
        uint8 _minute, 
        uint8 _second
    ) external onlyOwner {
        GPSStartTime = toTimestamp(_year, _month, _day, _hour, _minute, _second);
    }
    
    //set end time
    function setGPSEndTime(
        uint16 _year, 
        uint8 _month, 
        uint8 _day, 
        uint8 _hour, 
        uint8 _minute, 
        uint8 _second
    ) external onlyOwner {
        GPSEndTime = toTimestamp(_year, _month, _day, _hour, _minute, _second);
    }

    function setnumMax(uint16 _num) public onlyOwner {
        numMax = _num;
    }
    
    function getGPSStartTime()view public returns(uint256) {
        return GPSStartTime;
    }

    function getGPSEndTime()view public returns(uint256) {
        return GPSEndTime;
    }

    function getGPSMinEth() view public returns(uint256){
        return GPSMinEth;
    }

    function getGPSMaxEth()view public returns(uint256) {
        return GPSMaxEth;
    }

    function getGPShashRandomValue()view public onlyOwner returns(uint256) {
        return hashRandomValue;
    }

    function openPrize() private returns(bool){
        require (PrizeCount > 0);
        uint256 _Prize = safeMod(hashRandomValue,PrizeCount);
        
        uint256 firstPrizeNum;

        //投资者总人数
        uint256 PrizeAmout = investors.length;

        //一等奖，奖池45% 二等奖，奖池3%，三等奖 ，奖池1%
        uint256 _firstPrizeValue = safeMul(address(this).balance,45);
        _firstPrizeValue = safeDiv(_firstPrizeValue,100);
        uint256 _secondPrizeValue = safeMul(address(this).balance,3);
        _secondPrizeValue = safeDiv(_secondPrizeValue,100);
        uint256 _thirdPrizeValue = safeMul(address(this).balance,1);
        _thirdPrizeValue = safeDiv(_thirdPrizeValue,100);
        
        uint256 _GDOCBASEValue = safeMul(address(this).balance,51);
        _GDOCBASEValue = safeDiv(_GDOCBASEValue,100);

        //三等奖，最后一名投资者
        thirdPrize = investors[PrizeAmout-1];

        for(uint i = 0; i < PrizeAmout; i++){
            if(investorInfor[investors[i]].PrizeMin <= _Prize && investorInfor[investors[i]].PrizeMax > _Prize)
            {
                firstPrize = investors[i];
                firstPrizeNum = i;
                firstPrizeStaus = true;
            }
        }

        if(firstPrizeNum == PrizeAmout-1){
            firstPrizeStaus = false;
            secondPrize = investors[firstPrizeNum - 1];
        }

        if(firstPrizeNum == PrizeAmout-2){
            firstPrizeStaus = false;
            if(safeSub(_Prize,investorInfor[investors[firstPrizeNum]].PrizeMin) <= safeSub(investorInfor[investors[firstPrizeNum]].PrizeMax,_Prize))
            {
                secondPrize = investors[firstPrizeNum - 1];
            }else{
                secondPrize = investors[firstPrizeNum + 1];
            }
        }

        if(firstPrizeStaus){
            firstPrize.transfer(_firstPrizeValue);
        }
        secondPrize.transfer(_secondPrizeValue);
        thirdPrize.transfer(_thirdPrizeValue);
        GDOCBASE.transfer(_GDOCBASEValue);
        return true;
    }


    function() payable public onGPS WithInETH{
        require (now >= GPSStartTime);
        require (!isContract(msg.sender));

        uint256 _value = msg.value;
        uint256 _token = safeMul(_value,GPSRatio);
        
        //从privateFund钱包转出Token
        bool _success = gdocbase.transfer(privateFundAddres, msg.sender, _token);
        if (!_success){revert();}
        
        //token锁仓
        //gdoctoken.addLockedTokens(msg.sender, 3, now, _token);

        //投资人数递加
        numcount ++;

        uint256 _prize = safeDiv(_value,0.5*10**18);
        uint256 _prizeStart = PrizeCount;
        uint256 _prizeEnd = safeAdd(_prize,PrizeCount);
        PrizeCount = _prizeEnd;

        investors.push(msg.sender);
        investor memory _inv = investor(msg.value, _prizeStart,_prizeEnd);
        //记录投资者
        investorInfor[msg.sender] = _inv;
        //生成随机值
        hashRandomValue = uint256(keccak256(hashRandomValue,msg.sender,now,block.coinbase));
        
        if(numcount >= numMax || now >= GPSEndTime){
            //关闭此轮GPS
            on = false;
            openPrize();
        }
    }
}