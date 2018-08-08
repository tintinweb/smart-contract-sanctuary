pragma solidity ^0.4.21;

// File: contracts/DateTime.sol

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

        function isLeapYear(uint16 year) public pure returns (bool) {
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

        function leapYearsBefore(uint year) public pure returns (uint) {
                year -= 1;
                return year / 4 - year / 100 + year / 400;
        }

        function getDaysInMonth(uint8 month, uint16 year) public pure returns (uint8) {
                if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
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

        function getYear(uint timestamp) public pure returns (uint16) {
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

        function getMonth(uint timestamp) public pure returns (uint8) {
                return parseTimestamp(timestamp).month;
        }

        function getDay(uint timestamp) public pure returns (uint8) {
                return parseTimestamp(timestamp).day;
        }

        function getHour(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / 60 / 60) % 24);
        }

        function getMinute(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / 60) % 60);
        }

        function getSecond(uint timestamp) public pure returns (uint8) {
                return uint8(timestamp % 60);
        }

        function getWeekday(uint timestamp) public pure returns (uint8) {
                return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day) public pure returns (uint timestamp) {
                return toTimestamp(year, month, day, 0, 0, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) public pure returns (uint timestamp) {
                return toTimestamp(year, month, day, hour, 0, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) public pure returns (uint timestamp) {
                return toTimestamp(year, month, day, hour, minute, 0);
        }

        function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) public pure returns (uint timestamp) {
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

// File: contracts/ISimpleCrowdsale.sol

interface ISimpleCrowdsale {
    function getSoftCap() external view returns(uint256);
}

// File: contracts/fund/ICrowdsaleFund.sol

/**
 * @title ICrowdsaleFund
 * @dev Fund methods used by crowdsale contract
 */
interface ICrowdsaleFund {
    /**
    * @dev Function accepts user`s contributed ether and logs contribution
    * @param contributor Contributor wallet address.
    */
    function processContribution(address contributor) external payable;
    /**
    * @dev Function is called on the end of successful crowdsale
    */
    function onCrowdsaleEnd() external;
    /**
    * @dev Function is called if crowdsale failed to reach soft cap
    */
    function enableCrowdsaleRefund() external;
}

// File: contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
contract SafeMath {
    /**
    * @dev constructor
    */
    function SafeMath() public {
    }

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(a >= b);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

// File: contracts/ownership/MultiOwnable.sol

/**
 * @title MultiOwnable
 * @dev The MultiOwnable contract has owners addresses and provides basic authorization control
 * functions, this simplifies the implementation of "users permissions".
 */
contract MultiOwnable {
    address public manager; // address used to set owners
    address[] public owners;
    mapping(address => bool) public ownerByAddress;

    event SetOwners(address[] owners);

    modifier onlyOwner() {
        require(ownerByAddress[msg.sender] == true);
        _;
    }

    /**
     * @dev MultiOwnable constructor sets the manager
     */
    function MultiOwnable() public {
        manager = msg.sender;
    }

    /**
     * @dev Function to set owners addresses
     */
    function setOwners(address[] _owners) public {
        require(msg.sender == manager);
        _setOwners(_owners);

    }

    function _setOwners(address[] _owners) internal {
        for(uint256 i = 0; i < owners.length; i++) {
            ownerByAddress[owners[i]] = false;
        }


        for(uint256 j = 0; j < _owners.length; j++) {
            ownerByAddress[_owners[j]] = true;
        }
        owners = _owners;
        SetOwners(_owners);
    }

    function getOwners() public constant returns (address[]) {
        return owners;
    }
}

// File: contracts/token/IERC20Token.sol

/**
 * @title IERC20Token - ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract IERC20Token {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value)  public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value)  public returns (bool success);
    function approve(address _spender, uint256 _value)  public returns (bool success);
    function allowance(address _owner, address _spender)  public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// File: contracts/token/ERC20Token.sol

/**
 * @title ERC20Token - ERC20 base implementation
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Token is IERC20Token, SafeMath {
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(balances[msg.sender] >= _value);

        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);

        balances[_to] = safeAdd(balances[_to], _value);
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256) {
      return allowed[_owner][_spender];
    }
}

// File: contracts/token/ITokenEventListener.sol

/**
 * @title ITokenEventListener
 * @dev Interface which should be implemented by token listener
 */
interface ITokenEventListener {
    /**
     * @dev Function is called after token transfer/transferFrom
     * @param _from Sender address
     * @param _to Receiver address
     * @param _value Amount of tokens
     */
    function onTokenTransfer(address _from, address _to, uint256 _value) external;
}

// File: contracts/token/ManagedToken.sol

/**
 * @title ManagedToken
 * @dev ERC20 compatible token with issue and destroy facilities
 * @dev All transfers can be monitored by token event listener
 */
contract ManagedToken is ERC20Token, MultiOwnable {
    bool public allowTransfers = false;
    bool public issuanceFinished = false;

    ITokenEventListener public eventListener;

    event AllowTransfersChanged(bool _newState);
    event Issue(address indexed _to, uint256 _value);
    event Destroy(address indexed _from, uint256 _value);
    event IssuanceFinished();

    modifier transfersAllowed() {
        require(allowTransfers);
        _;
    }

    modifier canIssue() {
        require(!issuanceFinished);
        _;
    }

    /**
     * @dev ManagedToken constructor
     * @param _listener Token listener(address can be 0x0)
     * @param _owners Owners list
     */
    function ManagedToken(address _listener, address[] _owners) public {
        if(_listener != address(0)) {
            eventListener = ITokenEventListener(_listener);
        }
        _setOwners(_owners);
    }

    /**
     * @dev Enable/disable token transfers. Can be called only by owners
     * @param _allowTransfers True - allow False - disable
     */
    function setAllowTransfers(bool _allowTransfers) external onlyOwner {
        allowTransfers = _allowTransfers;
        AllowTransfersChanged(_allowTransfers);
    }

    /**
     * @dev Set/remove token event listener
     * @param _listener Listener address (Contract must implement ITokenEventListener interface)
     */
    function setListener(address _listener) public onlyOwner {
        if(_listener != address(0)) {
            eventListener = ITokenEventListener(_listener);
        } else {
            delete eventListener;
        }
    }

    function transfer(address _to, uint256 _value) public transfersAllowed returns (bool) {
        bool success = super.transfer(_to, _value);
        if(hasListener() && success) {
            eventListener.onTokenTransfer(msg.sender, _to, _value);
        }
        return success;
    }

    function transferFrom(address _from, address _to, uint256 _value) public transfersAllowed returns (bool) {
        bool success = super.transferFrom(_from, _to, _value);
        if(hasListener() && success) {
            eventListener.onTokenTransfer(_from, _to, _value);
        }
        return success;
    }

    function hasListener() internal view returns(bool) {
        if(eventListener == address(0)) {
            return false;
        }
        return true;
    }

    /**
     * @dev Issue tokens to specified wallet
     * @param _to Wallet address
     * @param _value Amount of tokens
     */
    function issue(address _to, uint256 _value) external onlyOwner canIssue {
        totalSupply = safeAdd(totalSupply, _value);
        balances[_to] = safeAdd(balances[_to], _value);
        Issue(_to, _value);
        Transfer(address(0), _to, _value);
    }

    /**
     * @dev Destroy tokens on specified address (Called by owner or token holder)
     * @dev Fund contract address must be in the list of owners to burn token during refund
     * @param _from Wallet address
     * @param _value Amount of tokens to destroy
     */
    function destroy(address _from, uint256 _value) external {
        require(ownerByAddress[msg.sender] || msg.sender == _from);
        require(balances[_from] >= _value);
        totalSupply = safeSub(totalSupply, _value);
        balances[_from] = safeSub(balances[_from], _value);
        Transfer(_from, address(0), _value);
        Destroy(_from, _value);
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From OpenZeppelin StandardToken.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = safeAdd(allowed[msg.sender][_spender], _addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From OpenZeppelin StandardToken.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = safeSub(oldValue, _subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Finish token issuance
     * @return True if success
     */
    function finishIssuance() public onlyOwner returns (bool) {
        issuanceFinished = true;
        IssuanceFinished();
        return true;
    }
}

// File: contracts/Fund.sol

contract Fund is ICrowdsaleFund, SafeMath, MultiOwnable {
    enum FundState {
        Crowdsale,
        CrowdsaleRefund,
        TeamWithdraw,
        Refund
    }

    FundState public state = FundState.Crowdsale;
    ManagedToken public token;

    uint256 public constant INITIAL_TAP = 192901234567901; // (wei/sec) == 500 ether/month

    address public teamWallet;
    uint256 public crowdsaleEndDate;

    address public mainSaleTokenWallet;
    address public foundationTokenWallet;
    address public marketingTokenWallet;
    address public teamTokenWallet;
    address public advisorTokenWallet;
    address public lockedTokenAddress;
    address public refundManager;

    uint256 public tap;
    uint256 public lastWithdrawTime = 0;
    uint256 public firstWithdrawAmount = 0;

    address public crowdsaleAddress;
    mapping(address => uint256) public contributions;

    event RefundContributor(address tokenHolder, uint256 amountWei, uint256 timestamp);
    event RefundHolder(address tokenHolder, uint256 amountWei, uint256 tokenAmount, uint256 timestamp);
    event Withdraw(uint256 amountWei, uint256 timestamp);
    event RefundEnabled(address initiatorAddress);

    /**
     * @dev Fund constructor
     * @param _teamWallet Withdraw functions transfers ether to this address
     * @param _mainSaleTokenWallet Main sale wallet address
     * @param _teamTokenWallet Team wallet address
     * @param _marketingTokenWallet Bounty wallet address
     * @param _advisorTokenWallet Advisor wallet address
     * @param _owners Contract owners
     */
    function Fund(
        address _teamWallet,
        address _mainSaleTokenWallet,
        address _foundationTokenWallet,
        address _teamTokenWallet,
        address _marketingTokenWallet,
        address _advisorTokenWallet,
        address _refundManager,
        address[] _owners
    ) public
    {
        teamWallet = _teamWallet;
        mainSaleTokenWallet = _mainSaleTokenWallet;
        foundationTokenWallet = _foundationTokenWallet;
        teamTokenWallet = _teamTokenWallet;
        marketingTokenWallet = _marketingTokenWallet;
        advisorTokenWallet = _advisorTokenWallet;
        refundManager = _refundManager;
        _setOwners(_owners);
    }

    modifier withdrawEnabled() {
        require(canWithdraw());
        _;
    }

    modifier onlyCrowdsale() {
        require(msg.sender == crowdsaleAddress);
        _;
    }

    function canWithdraw() public returns(bool);

    function setCrowdsaleAddress(address _crowdsaleAddress) public onlyOwner {
        require(crowdsaleAddress == address(0));
        crowdsaleAddress = _crowdsaleAddress;
    }

    function setTokenAddress(address _tokenAddress) public onlyOwner {
        require(address(token) == address(0));
        token = ManagedToken(_tokenAddress);
    }

    function setLockedTokenAddress(address _lockedTokenAddress) public onlyOwner {
        require(address(lockedTokenAddress) == address(0));
        lockedTokenAddress = _lockedTokenAddress;
    }

    /**
     * @dev Process crowdsale contribution
     */
    function processContribution(address contributor) external payable onlyCrowdsale {
        require(state == FundState.Crowdsale);
        uint256 totalContribution = safeAdd(contributions[contributor], msg.value);
        contributions[contributor] = totalContribution;
    }

    /**
     * @dev Callback is called after crowdsale finalization if soft cap is reached
     */
    function onCrowdsaleEnd() external onlyCrowdsale {
        state = FundState.TeamWithdraw;
        ISimpleCrowdsale crowdsale = ISimpleCrowdsale(crowdsaleAddress);
        firstWithdrawAmount = crowdsale.getSoftCap();
        lastWithdrawTime = now;
        tap = INITIAL_TAP;
        crowdsaleEndDate = now;
    }

    /**
     * @dev Callback is called after crowdsale finalization if soft cap is not reached
     */
    function enableCrowdsaleRefund() external onlyCrowdsale {
        require(state == FundState.Crowdsale);
        state = FundState.CrowdsaleRefund;
    }

    /**
    * @dev Function is called by contributor to refund payments if crowdsale failed to reach soft cap
    */
    function refundCrowdsaleContributor() external {
        require(state == FundState.CrowdsaleRefund);
        require(contributions[msg.sender] > 0);

        uint256 refundAmount = contributions[msg.sender];
        contributions[msg.sender] = 0;
        token.destroy(msg.sender, token.balanceOf(msg.sender));
        msg.sender.transfer(refundAmount);
        RefundContributor(msg.sender, refundAmount, now);
    }

    /**
    * @dev Function is called by owner to refund payments if crowdsale failed to reach soft cap
    */
    function autoRefundCrowdsaleContributor(address contributorAddress) external {
        require(ownerByAddress[msg.sender] == true || msg.sender == refundManager);
        require(state == FundState.CrowdsaleRefund);
        require(contributions[contributorAddress] > 0);

        uint256 refundAmount = contributions[contributorAddress];
        contributions[contributorAddress] = 0;
        token.destroy(contributorAddress, token.balanceOf(contributorAddress));
        contributorAddress.transfer(refundAmount);
        RefundContributor(contributorAddress, refundAmount, now);
    }

    /**
     * @dev Decrease tap amount
     * @param _tap New tap value
     */
    function decTap(uint256 _tap) external onlyOwner {
        require(state == FundState.TeamWithdraw);
        require(_tap < tap);
        tap = _tap;
    }

    function getCurrentTapAmount() public constant returns(uint256) {
        if(state != FundState.TeamWithdraw) {
            return 0;
        }
        return calcTapAmount();
    }

    function calcTapAmount() internal view returns(uint256) {
        uint256 amount = safeMul(safeSub(now, lastWithdrawTime), tap);
        if(address(this).balance < amount) {
            amount = address(this).balance;
        }
        return amount;
    }

    function firstWithdraw() public onlyOwner withdrawEnabled {
        require(firstWithdrawAmount > 0);
        uint256 amount = firstWithdrawAmount;
        firstWithdrawAmount = 0;
        teamWallet.transfer(amount);
        Withdraw(amount, now);
    }

    /**
     * @dev Withdraw tap amount
     */
    function withdraw() public onlyOwner withdrawEnabled {
        require(state == FundState.TeamWithdraw);
        uint256 amount = calcTapAmount();
        lastWithdrawTime = now;
        teamWallet.transfer(amount);
        Withdraw(amount, now);
    }

    // Refund
    /**
     * @dev Called to start refunding
     */
    function enableRefund() internal {
        require(state == FundState.TeamWithdraw);
        state = FundState.Refund;
        token.destroy(lockedTokenAddress, token.balanceOf(lockedTokenAddress));
        token.destroy(teamTokenWallet, token.balanceOf(teamTokenWallet));
        token.destroy(foundationTokenWallet, token.balanceOf(foundationTokenWallet));
        token.destroy(marketingTokenWallet, token.balanceOf(marketingTokenWallet));
        token.destroy(mainSaleTokenWallet, token.balanceOf(mainSaleTokenWallet));
        token.destroy(advisorTokenWallet, token.balanceOf(advisorTokenWallet));
        RefundEnabled(msg.sender);
    }

    /**
    * @dev Function is called by contributor to refund
    * Buy user tokens for refundTokenPrice and destroy them
    */
    function refundTokenHolder() public {
        require(state == FundState.Refund);

        uint256 tokenBalance = token.balanceOf(msg.sender);
        require(tokenBalance > 0);
        uint256 refundAmount = safeDiv(safeMul(tokenBalance, address(this).balance), token.totalSupply());
        require(refundAmount > 0);

        token.destroy(msg.sender, tokenBalance);
        msg.sender.transfer(refundAmount);

        RefundHolder(msg.sender, refundAmount, tokenBalance, now);
    }
}

// File: contracts/fund/IPollManagedFund.sol

/**
 * @title IPollManagedFund
 * @dev Fund callbacks used by polling contracts
 */
interface IPollManagedFund {
    /**
     * @dev TapPoll callback
     * @param agree True if new tap value is accepted by majority of contributors
     * @param _tap New tap value
     */
    function onTapPollFinish(bool agree, uint256 _tap) external;

    /**
     * @dev RefundPoll callback
     * @param agree True if contributors decided to allow refunding
     */
    function onRefundPollFinish(bool agree) external;
}

// File: contracts/poll/BasePoll.sol

/**
 * @title BasePoll
 * @dev Abstract base class for polling contracts
 */
contract BasePoll is SafeMath {
    struct Vote {
        uint256 time;
        uint256 weight;
        bool agree;
    }

    uint256 public constant MAX_TOKENS_WEIGHT_DENOM = 1000;

    IERC20Token public token;
    address public fundAddress;

    uint256 public startTime;
    uint256 public endTime;
    bool checkTransfersAfterEnd;

    uint256 public yesCounter = 0;
    uint256 public noCounter = 0;
    uint256 public totalVoted = 0;

    bool public finalized;
    mapping(address => Vote) public votesByAddress;

    modifier checkTime() {
        require(now >= startTime && now <= endTime);
        _;
    }

    modifier notFinalized() {
        require(!finalized);
        _;
    }

    /**
     * @dev BasePoll constructor
     * @param _tokenAddress ERC20 compatible token contract address
     * @param _fundAddress Fund contract address
     * @param _startTime Poll start time
     * @param _endTime Poll end time
     */
    function BasePoll(address _tokenAddress, address _fundAddress, uint256 _startTime, uint256 _endTime, bool _checkTransfersAfterEnd) public {
        require(_tokenAddress != address(0));
        require(_startTime >= now && _endTime > _startTime);

        token = IERC20Token(_tokenAddress);
        fundAddress = _fundAddress;
        startTime = _startTime;
        endTime = _endTime;
        finalized = false;
        checkTransfersAfterEnd = _checkTransfersAfterEnd;
    }

    /**
     * @dev Process user`s vote
     * @param agree True if user endorses the proposal else False
     */
    function vote(bool agree) public checkTime {
        require(votesByAddress[msg.sender].time == 0);

        uint256 voiceWeight = token.balanceOf(msg.sender);
        uint256 maxVoiceWeight = safeDiv(token.totalSupply(), MAX_TOKENS_WEIGHT_DENOM);
        voiceWeight =  voiceWeight <= maxVoiceWeight ? voiceWeight : maxVoiceWeight;

        if(agree) {
            yesCounter = safeAdd(yesCounter, voiceWeight);
        } else {
            noCounter = safeAdd(noCounter, voiceWeight);

        }

        votesByAddress[msg.sender].time = now;
        votesByAddress[msg.sender].weight = voiceWeight;
        votesByAddress[msg.sender].agree = agree;

        totalVoted = safeAdd(totalVoted, 1);
    }

    /**
     * @dev Revoke user`s vote
     */
    function revokeVote() public checkTime {
        require(votesByAddress[msg.sender].time > 0);

        uint256 voiceWeight = votesByAddress[msg.sender].weight;
        bool agree = votesByAddress[msg.sender].agree;

        votesByAddress[msg.sender].time = 0;
        votesByAddress[msg.sender].weight = 0;
        votesByAddress[msg.sender].agree = false;

        totalVoted = safeSub(totalVoted, 1);
        if(agree) {
            yesCounter = safeSub(yesCounter, voiceWeight);
        } else {
            noCounter = safeSub(noCounter, voiceWeight);
        }
    }

    /**
     * @dev Function is called after token transfer from user`s wallet to check and correct user`s vote
     *
     */
    function onTokenTransfer(address tokenHolder, uint256 amount) public {
        require(msg.sender == fundAddress);
        if(votesByAddress[tokenHolder].time == 0) {
            return;
        }
        if(!checkTransfersAfterEnd) {
             if(finalized || (now < startTime || now > endTime)) {
                 return;
             }
        }

        if(token.balanceOf(tokenHolder) >= votesByAddress[tokenHolder].weight) {
            return;
        }
        uint256 voiceWeight = amount;
        if(amount > votesByAddress[tokenHolder].weight) {
            voiceWeight = votesByAddress[tokenHolder].weight;
        }

        if(votesByAddress[tokenHolder].agree) {
            yesCounter = safeSub(yesCounter, voiceWeight);
        } else {
            noCounter = safeSub(noCounter, voiceWeight);
        }
        votesByAddress[tokenHolder].weight = safeSub(votesByAddress[tokenHolder].weight, voiceWeight);
    }

    /**
     * Finalize poll and call onPollFinish callback with result
     */
    function tryToFinalize() public notFinalized returns(bool) {
        if(now < endTime) {
            return false;
        }
        finalized = true;
        onPollFinish(isSubjectApproved());
        return true;
    }

    function isNowApproved() public view returns(bool) {
        return isSubjectApproved();
    }

    function isSubjectApproved() internal view returns(bool) {
        return yesCounter > noCounter;
    }

    /**
     * @dev callback called after poll finalization
     */
    function onPollFinish(bool agree) internal;
}

// File: contracts/RefundPoll.sol

/**
 * @title RefundPoll
 * @dev Enables fund refund mode
 */
contract RefundPoll is BasePoll {
    uint256 public holdEndTime = 0;

    /**
     * RefundPoll constructor
     * @param _tokenAddress ERC20 compatible token contract address
     * @param _fundAddress Fund contract address
     * @param _startTime Poll start time
     * @param _endTime Poll end time
     */
    function RefundPoll(
        address _tokenAddress,
        address _fundAddress,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _holdEndTime,
        bool _checkTransfersAfterEnd
    ) public
        BasePoll(_tokenAddress, _fundAddress, _startTime, _endTime, _checkTransfersAfterEnd)
    {
        holdEndTime = _holdEndTime;
    }

    function tryToFinalize() public returns(bool) {
        if(holdEndTime > 0 && holdEndTime > endTime) {
            require(now >= holdEndTime);
        } else {
            require(now >= endTime);
        }

        finalized = true;
        onPollFinish(isSubjectApproved());
        return true;
    }

    function isSubjectApproved() internal view returns(bool) {
        return yesCounter > noCounter && yesCounter >= safeDiv(token.totalSupply(), 3);
    }

    function onPollFinish(bool agree) internal {
        IPollManagedFund fund = IPollManagedFund(fundAddress);
        fund.onRefundPollFinish(agree);
    }

}

// File: contracts/TapPoll.sol

/**
 * @title TapPoll
 * @dev Poll to increase tap amount
 */
contract TapPoll is BasePoll {
    uint256 public tap;
    uint256 public minTokensPerc = 0;

    /**
     * TapPoll constructor
     * @param _tap New tap value
     * @param _tokenAddress ERC20 compatible token contract address
     * @param _fundAddress Fund contract address
     * @param _startTime Poll start time
     * @param _endTime Poll end time
     * @param _minTokensPerc - Min percent of tokens from totalSupply where poll is considered to be fulfilled
     */
    function TapPoll(
        uint256 _tap,
        address _tokenAddress,
        address _fundAddress,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _minTokensPerc
    ) public
        BasePoll(_tokenAddress, _fundAddress, _startTime, _endTime, false)
    {
        tap = _tap;
        minTokensPerc = _minTokensPerc;
    }

    function onPollFinish(bool agree) internal {
        IPollManagedFund fund = IPollManagedFund(fundAddress);
        fund.onTapPollFinish(agree, tap);
    }

    function getVotedTokensPerc() public view returns(uint256) {
        return safeDiv(safeMul(safeAdd(yesCounter, noCounter), 100), token.totalSupply());
    }

    function isSubjectApproved() internal view returns(bool) {
        return yesCounter > noCounter && getVotedTokensPerc() >= minTokensPerc;
    }
}

// File: contracts/PollManagedFund.sol

/**
 * @title PollManagedFund
 * @dev Fund controlled by users
 */
contract PollManagedFund is Fund, DateTime, ITokenEventListener {
    uint256 public constant TAP_POLL_DURATION = 3 days;
    uint256 public constant REFUND_POLL_DURATION = 7 days;
    uint256 public constant MAX_VOTED_TOKEN_PERC = 10;

    TapPoll public tapPoll;
    RefundPoll public refundPoll;

    uint256 public minVotedTokensPerc = 0;
    uint256 public secondRefundPollDate = 0;
    bool public isWithdrawEnabled = true;

    uint256[] public refundPollDates = [
        1543651200, // 01.12.2018
        1551427200, // 01.03.2019
        1559376000 // 01.06.2019
    ];

    modifier onlyTokenHolder() {
        require(token.balanceOf(msg.sender) > 0);
        _;
    }

    event TapPollCreated();
    event TapPollFinished(bool approved, uint256 _tap);
    event RefundPollCreated();
    event RefundPollFinished(bool approved);

    /**
     * @dev PollManagedFund constructor
     * params - see Fund constructor
     */
    function PollManagedFund(
        address _teamWallet,
        address _mainSaleTokenWallet,
        address _foundationTokenWallet,
        address _teamTokenWallet,
        address _marketingTokenWallet,
        address _advisorTokenWallet,
        address _refundManager,
        address[] _owners
        ) public
    Fund(_teamWallet, _mainSaleTokenWallet, _foundationTokenWallet, _teamTokenWallet, _marketingTokenWallet, _advisorTokenWallet, _refundManager, _owners)
    {
    }

    function canWithdraw() public returns(bool) {
        if(
            address(refundPoll) != address(0) &&
            !refundPoll.finalized() &&
            refundPoll.holdEndTime() > 0 &&
            now >= refundPoll.holdEndTime() &&
            refundPoll.isNowApproved()
        ) {
            return false;
        }
        return isWithdrawEnabled;
    }

    /**
     * @dev ITokenEventListener implementation. Notify active poll contracts about token transfers
     */
    function onTokenTransfer(address _from, address /*_to*/, uint256 _value) external {
        require(msg.sender == address(token));
        if(address(tapPoll) != address(0) && !tapPoll.finalized()) {
            tapPoll.onTokenTransfer(_from, _value);
        }
         if(address(refundPoll) != address(0) && !refundPoll.finalized()) {
            refundPoll.onTokenTransfer(_from, _value);
        }
    }

    /**
     * @dev Update minVotedTokensPerc value after tap poll.
     * Set new value == 50% from current voted tokens amount
     */
    function updateMinVotedTokens(uint256 _minVotedTokensPerc) internal {
        uint256 newPerc = safeDiv(_minVotedTokensPerc, 2);
        if(newPerc > MAX_VOTED_TOKEN_PERC) {
            minVotedTokensPerc = MAX_VOTED_TOKEN_PERC;
            return;
        }
        minVotedTokensPerc = newPerc;
    }

    // Tap poll
    function createTapPoll(uint8 tapIncPerc) public onlyOwner {
        require(state == FundState.TeamWithdraw);
        require(tapPoll == address(0));
        require(getDay(now) == 10);
        require(tapIncPerc <= 50);
        uint256 _tap = safeAdd(tap, safeDiv(safeMul(tap, tapIncPerc), 100));
        uint256 startTime = now;
        uint256 endTime = startTime + TAP_POLL_DURATION;
        tapPoll = new TapPoll(_tap, token, this, startTime, endTime, minVotedTokensPerc);
        TapPollCreated();
    }

    function onTapPollFinish(bool agree, uint256 _tap) external {
        require(msg.sender == address(tapPoll) && tapPoll.finalized());
        if(agree) {
            tap = _tap;
        }
        updateMinVotedTokens(tapPoll.getVotedTokensPerc());
        TapPollFinished(agree, _tap);
        delete tapPoll;
    }

    // Refund poll
    function checkRefundPollDate() internal view returns(bool) {
        if(secondRefundPollDate > 0 && now >= secondRefundPollDate && now <= safeAdd(secondRefundPollDate, 1 days)) {
            return true;
        }

        for(uint i; i < refundPollDates.length; i++) {
            if(now >= refundPollDates[i] && now <= safeAdd(refundPollDates[i], 1 days)) {
                return true;
            }
        }
        return false;
    }

    function createRefundPoll() public onlyTokenHolder {
        require(state == FundState.TeamWithdraw);
        require(address(refundPoll) == address(0));
        require(checkRefundPollDate());

        if(secondRefundPollDate > 0 && now > safeAdd(secondRefundPollDate, 1 days)) {
            secondRefundPollDate = 0;
        }

        uint256 startTime = now;
        uint256 endTime = startTime + REFUND_POLL_DURATION;
        bool isFirstRefund = secondRefundPollDate == 0;
        uint256 holdEndTime = 0;

        if(isFirstRefund) {
            holdEndTime = toTimestamp(
                getYear(startTime),
                getMonth(startTime) + 1,
                1
            );
        }
        refundPoll = new RefundPoll(token, this, startTime, endTime, holdEndTime, isFirstRefund);
        RefundPollCreated();
    }

    function onRefundPollFinish(bool agree) external {
        require(msg.sender == address(refundPoll) && refundPoll.finalized());
        if(agree) {
            if(secondRefundPollDate > 0) {
                enableRefund();
            } else {
                uint256 startTime = refundPoll.startTime();
                secondRefundPollDate = toTimestamp(
                    getYear(startTime),
                    getMonth(startTime) + 2,
                    1
                );
                isWithdrawEnabled = false;
            }
        } else {
            secondRefundPollDate = 0;
            isWithdrawEnabled = true;
        }
        RefundPollFinished(agree);

        delete refundPoll;
    }

    function forceRefund() public {
        require(msg.sender == refundManager);
        enableRefund();
    }
}