pragma solidity ^0.4.18;

/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error
*/
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20Interface {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);
    string public symbol;

    function totalSupply() constant returns (uint256 supply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
}

/// @title ServiceAllowance.
///
/// Provides a way to delegate operation allowance decision to a service contract
contract ServiceAllowance {
    function isTransferAllowed(address _from, address _to, address _sender, address _token, uint _value) public view returns (bool);
}

/// @title DepositWalletInterface
///
/// Defines an interface for a wallet that can be deposited/withdrawn by 3rd contract
contract DepositWalletInterface {
    function deposit(address _asset, address _from, uint256 amount) public returns (uint);
    function withdraw(address _asset, address _to, uint256 amount) public returns (uint);
}

/**
 * @title Owned contract with safe ownership pass.
 *
 * Note: all the non constant functions return false instead of throwing in case if state change
 * didn&#39;t happen yet.
 */
contract Owned {
    /**
     * Contract owner address
     */
    address public contractOwner;

    /**
     * Contract owner address
     */
    address public pendingContractOwner;

    function Owned() {
        contractOwner = msg.sender;
    }

    /**
    * @dev Owner check modifier
    */
    modifier onlyContractOwner() {
        if (contractOwner == msg.sender) {
            _;
        }
    }

    /**
     * @dev Destroy contract and scrub a data
     * @notice Only owner can call it
     */
    function destroy() onlyContractOwner {
        suicide(msg.sender);
    }

    /**
     * Prepares ownership pass.
     *
     * Can only be called by current owner.
     *
     * @param _to address of the next owner. 0x0 is not allowed.
     *
     * @return success.
     */
    function changeContractOwnership(address _to) onlyContractOwner() returns(bool) {
        if (_to  == 0x0) {
            return false;
        }

        pendingContractOwner = _to;
        return true;
    }

    /**
     * Finalize ownership pass.
     *
     * Can only be called by pending owner.
     *
     * @return success.
     */
    function claimContractOwnership() returns(bool) {
        if (pendingContractOwner != msg.sender) {
            return false;
        }

        contractOwner = pendingContractOwner;
        delete pendingContractOwner;

        return true;
    }
}

/**
 * @title Generic owned destroyable contract
 */
contract Object is Owned {
    /**
    *  Common result code. Means everything is fine.
    */
    uint constant OK = 1;
    uint constant OWNED_ACCESS_DENIED_ONLY_CONTRACT_OWNER = 8;

    function withdrawnTokens(address[] tokens, address _to) onlyContractOwner returns(uint) {
        for(uint i=0;i<tokens.length;i++) {
            address token = tokens[i];
            uint balance = ERC20Interface(token).balanceOf(this);
            if(balance != 0)
                ERC20Interface(token).transfer(_to,balance);
        }
        return OK;
    }

    function checkOnlyContractOwner() internal constant returns(uint) {
        if (contractOwner == msg.sender) {
            return OK;
        }

        return OWNED_ACCESS_DENIED_ONLY_CONTRACT_OWNER;
    }
}

contract OracleContractAdapter is Object {

    event OracleAdded(address _oracle);
    event OracleRemoved(address _oracle);

    mapping(address => bool) public oracles;

    /// @dev Allow access only for oracle
    modifier onlyOracle {
        if (oracles[msg.sender]) {
            _;
        }
    }

    modifier onlyOracleOrOwner {
        if (oracles[msg.sender] || msg.sender == contractOwner) {
            _;
        }
    }

    /// @notice Add oracles to whitelist.
    ///
    /// @param _whitelist user list.
    function addOracles(address[] _whitelist) external onlyContractOwner returns (uint)    {
        for (uint _idx = 0; _idx < _whitelist.length; ++_idx) {
            address _oracle = _whitelist[_idx];
            if (!oracles[_oracle]) {
                oracles[_oracle] = true;
                _emitOracleAdded(_oracle);
            }
        }
        return OK;
    }

    /// @notice Removes oracles from whitelist.
    ///
    /// @param _blacklist user in whitelist.
    function removeOracles(address[] _blacklist) external onlyContractOwner returns (uint)    {
        for (uint _idx = 0; _idx < _blacklist.length; ++_idx) {
            address _oracle = _blacklist[_idx];
            if (oracles[_oracle]) {
                delete oracles[_oracle];
                _emitOracleRemoved(_oracle);
            }
        }
        return OK;
    }

    function _emitOracleAdded(address _oracle) internal {
        OracleAdded(_oracle);
    }

    function _emitOracleRemoved(address _oracle) internal {
        OracleRemoved(_oracle);
    }
}

contract ProfiteroleEmitter {

    event DepositPendingAdded(uint amount, address from, uint timestamp);
    event BonusesWithdrawn(bytes32 userKey, uint amount, uint timestamp);

    event Error(uint errorCode);

    function _emitError(uint _errorCode) internal returns (uint) {
        Error(_errorCode);
        return _errorCode;
    }
}

contract TreasuryEmitter {
    event TreasuryDeposited(bytes32 userKey, uint value, uint lockupDate);
    event TreasuryWithdrawn(bytes32 userKey, uint value);
}

contract ERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);
    string public symbol;

    function totalSupply() constant returns (uint256 supply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
}





/// @title Treasury contract.
///
/// Treasury for CCs deposits for particular fund with bmc-days calculations.
/// Accept BMC deposits from Continuous Contributors via oracle and
/// calculates bmc-days metric for each CC&#39;s role.
contract Treasury is OracleContractAdapter, ServiceAllowance, TreasuryEmitter {

    /* ERROR CODES */

    uint constant PERCENT_PRECISION = 10000;

    uint constant TREASURY_ERROR_SCOPE = 108000;
    uint constant TREASURY_ERROR_TOKEN_NOT_SET_ALLOWANCE = TREASURY_ERROR_SCOPE + 1;

    using SafeMath for uint;

    struct LockedDeposits {
        uint counter;
        mapping(uint => uint) index2Date;
        mapping(uint => uint) date2deposit;
    }

    struct Period {
        uint transfersCount;
        uint totalBmcDays;
        uint bmcDaysPerDay;
        uint startDate;
        mapping(bytes32 => uint) user2bmcDays;
        mapping(bytes32 => uint) user2lastTransferIdx;
        mapping(bytes32 => uint) user2balance;
        mapping(uint => uint) transfer2date;
    }

    /* FIELDS */

    address token;
    address profiterole;
    uint periodsCount;

    mapping(uint => Period) periods;
    mapping(uint => uint) periodDate2periodIdx;
    mapping(bytes32 => uint) user2lastPeriodParticipated;
    mapping(bytes32 => LockedDeposits) user2lockedDeposits;

    /* MODIFIERS */

    /// @dev Only profiterole contract allowed to invoke guarded functions
    modifier onlyProfiterole {
        require(profiterole == msg.sender);
        _;
    }

    /* PUBLIC */
    
    function Treasury(address _token) public {
        require(address(_token) != 0x0);
        token = _token;
        periodsCount = 1;
    }

    function init(address _profiterole) public onlyContractOwner returns (uint) {
        require(_profiterole != 0x0);
        profiterole = _profiterole;
        return OK;
    }

    /// @notice Do not accept Ether transfers
    function() payable public {
        revert();
    }

    /* EXTERNAL */

    /// @notice Deposits tokens on behalf of users
    /// Allowed only for oracle.
    ///
    /// @param _userKey aggregated user key (user ID + role ID)
    /// @param _value amount of tokens to deposit
    /// @param _feeAmount amount of tokens that will be taken from _value as fee
    /// @param _feeAddress destination address for fee transfer
    /// @param _lockupDate lock up date for deposit. Until that date the deposited value couldn&#39;t be withdrawn
    ///
    /// @return result code of an operation
    function deposit(bytes32 _userKey, uint _value, uint _feeAmount, address _feeAddress, uint _lockupDate) external onlyOracle returns (uint) {
        require(_userKey != bytes32(0));
        require(_value != 0);
        require(_feeAmount < _value);

        ERC20 _token = ERC20(token);
        if (_token.allowance(msg.sender, address(this)) < _value) {
            return TREASURY_ERROR_TOKEN_NOT_SET_ALLOWANCE;
        }

        uint _depositedAmount = _value - _feeAmount;
        _makeDepositForPeriod(_userKey, _depositedAmount, _lockupDate);

        uint _periodsCount = periodsCount;
        user2lastPeriodParticipated[_userKey] = _periodsCount;
        delete periods[_periodsCount].startDate;

        if (!_token.transferFrom(msg.sender, address(this), _value)) {
            revert();
        }

        if (!(_feeAddress == 0x0 || _feeAmount == 0 || _token.transfer(_feeAddress, _feeAmount))) {
            revert();
        }

        TreasuryDeposited(_userKey, _depositedAmount, _lockupDate);
        return OK;
    }

    /// @notice Withdraws deposited tokens on behalf of users
    /// Allowed only for oracle
    ///
    /// @param _userKey aggregated user key (user ID + role ID)
    /// @param _value an amount of tokens that is requrested to withdraw
    /// @param _withdrawAddress address to withdraw; should not be 0x0
    /// @param _feeAmount amount of tokens that will be taken from _value as fee
    /// @param _feeAddress destination address for fee transfer
    ///
    /// @return result of an operation
    function withdraw(bytes32 _userKey, uint _value, address _withdrawAddress, uint _feeAmount, address _feeAddress) external onlyOracle returns (uint) {
        require(_userKey != bytes32(0));
        require(_value != 0);
        require(_feeAmount < _value);

        _makeWithdrawForPeriod(_userKey, _value);
        uint _periodsCount = periodsCount;
        user2lastPeriodParticipated[_userKey] = periodsCount;
        delete periods[_periodsCount].startDate;

        ERC20 _token = ERC20(token);
        if (!(_feeAddress == 0x0 || _feeAmount == 0 || _token.transfer(_feeAddress, _feeAmount))) {
            revert();
        }

        uint _withdrawnAmount = _value - _feeAmount;
        if (!_token.transfer(_withdrawAddress, _withdrawnAmount)) {
            revert();
        }

        TreasuryWithdrawn(_userKey, _withdrawnAmount);
        return OK;
    }

    /// @notice Gets shares (in percents) the user has on provided date
    ///
    /// @param _userKey aggregated user key (user ID + role ID)
    /// @param _date date where period ends
    ///
    /// @return percent from total amount of bmc-days the treasury has on this date.
    /// Use PERCENT_PRECISION to get right precision
    function getSharesPercentForPeriod(bytes32 _userKey, uint _date) public view returns (uint) {
        uint _periodIdx = periodDate2periodIdx[_date];
        if (_date != 0 && _periodIdx == 0) {
            return 0;
        }

        if (_date == 0) {
            _date = now;
            _periodIdx = periodsCount;
        }

        uint _bmcDays = _getBmcDaysAmountForUser(_userKey, _date, _periodIdx);
        uint _totalBmcDeposit = _getTotalBmcDaysAmount(_date, _periodIdx);
        return _totalBmcDeposit != 0 ? _bmcDays * PERCENT_PRECISION / _totalBmcDeposit : 0;
    }

    /// @notice Gets user balance that is deposited
    /// @param _userKey aggregated user key (user ID + role ID)
    /// @return an amount of tokens deposited on behalf of user
    function getUserBalance(bytes32 _userKey) public view returns (uint) {
        uint _lastPeriodForUser = user2lastPeriodParticipated[_userKey];
        if (_lastPeriodForUser == 0) {
            return 0;
        }

        if (_lastPeriodForUser <= periodsCount.sub(1)) {
            return periods[_lastPeriodForUser].user2balance[_userKey];
        }

        return periods[periodsCount].user2balance[_userKey];
    }

    /// @notice Gets amount of locked deposits for user
    /// @param _userKey aggregated user key (user ID + role ID)
    /// @return an amount of tokens locked
    function getLockedUserBalance(bytes32 _userKey) public returns (uint) {
        return _syncLockedDepositsAmount(_userKey);
    }

    /// @notice Gets list of locked up deposits with dates when they will be available to withdraw
    /// @param _userKey aggregated user key (user ID + role ID)
    /// @return {
    ///     "_lockupDates": "list of lockup dates of deposits",
    ///     "_deposits": "list of deposits"
    /// }
    function getLockedUserDeposits(bytes32 _userKey) public view returns (uint[] _lockupDates, uint[] _deposits) {
        LockedDeposits storage _lockedDeposits = user2lockedDeposits[_userKey];
        uint _lockedDepositsCounter = _lockedDeposits.counter;
        _lockupDates = new uint[](_lockedDepositsCounter);
        _deposits = new uint[](_lockedDepositsCounter);

        uint _pointer = 0;
        for (uint _idx = 1; _idx < _lockedDepositsCounter; ++_idx) {
            uint _lockDate = _lockedDeposits.index2Date[_idx];

            if (_lockDate > now) {
                _lockupDates[_pointer] = _lockDate;
                _deposits[_pointer] = _lockedDeposits.date2deposit[_lockDate];
                ++_pointer;
            }
        }
    }

    /// @notice Gets total amount of bmc-day accumulated due provided date
    /// @param _date date where period ends
    /// @return an amount of bmc-days
    function getTotalBmcDaysAmount(uint _date) public view returns (uint) {
        return _getTotalBmcDaysAmount(_date, periodsCount);
    }

    /// @notice Makes a checkpoint to start counting a new period
    /// @dev Should be used only by Profiterole contract
    function addDistributionPeriod() public onlyProfiterole returns (uint) {
        uint _periodsCount = periodsCount;
        uint _nextPeriod = _periodsCount.add(1);
        periodDate2periodIdx[now] = _periodsCount;

        Period storage _previousPeriod = periods[_periodsCount];
        uint _totalBmcDeposit = _getTotalBmcDaysAmount(now, _periodsCount);
        periods[_nextPeriod].startDate = now;
        periods[_nextPeriod].bmcDaysPerDay = _previousPeriod.bmcDaysPerDay;
        periods[_nextPeriod].totalBmcDays = _totalBmcDeposit;
        periodsCount = _nextPeriod;

        return OK;
    }

    function isTransferAllowed(address, address, address, address, uint) public view returns (bool) {
        return true;
    }

    /* INTERNAL */

    function _makeDepositForPeriod(bytes32 _userKey, uint _value, uint _lockupDate) internal {
        Period storage _transferPeriod = periods[periodsCount];

        _transferPeriod.user2bmcDays[_userKey] = _getBmcDaysAmountForUser(_userKey, now, periodsCount);
        _transferPeriod.totalBmcDays = _getTotalBmcDaysAmount(now, periodsCount);
        _transferPeriod.bmcDaysPerDay = _transferPeriod.bmcDaysPerDay.add(_value);

        uint _userBalance = getUserBalance(_userKey);
        uint _updatedTransfersCount = _transferPeriod.transfersCount.add(1);
        _transferPeriod.transfersCount = _updatedTransfersCount;
        _transferPeriod.transfer2date[_transferPeriod.transfersCount] = now;
        _transferPeriod.user2balance[_userKey] = _userBalance.add(_value);
        _transferPeriod.user2lastTransferIdx[_userKey] = _updatedTransfersCount;

        _registerLockedDeposits(_userKey, _value, _lockupDate);
    }

    function _makeWithdrawForPeriod(bytes32 _userKey, uint _value) internal {
        uint _userBalance = getUserBalance(_userKey);
        uint _lockedBalance = _syncLockedDepositsAmount(_userKey);
        require(_userBalance.sub(_lockedBalance) >= _value);

        uint _periodsCount = periodsCount;
        Period storage _transferPeriod = periods[_periodsCount];

        _transferPeriod.user2bmcDays[_userKey] = _getBmcDaysAmountForUser(_userKey, now, _periodsCount);
        uint _totalBmcDeposit = _getTotalBmcDaysAmount(now, _periodsCount);
        _transferPeriod.totalBmcDays = _totalBmcDeposit;
        _transferPeriod.bmcDaysPerDay = _transferPeriod.bmcDaysPerDay.sub(_value);

        uint _updatedTransferCount = _transferPeriod.transfersCount.add(1);
        _transferPeriod.transfer2date[_updatedTransferCount] = now;
        _transferPeriod.user2lastTransferIdx[_userKey] = _updatedTransferCount;
        _transferPeriod.user2balance[_userKey] = _userBalance.sub(_value);
        _transferPeriod.transfersCount = _updatedTransferCount;
    }

    function _registerLockedDeposits(bytes32 _userKey, uint _amount, uint _lockupDate) internal {
        if (_lockupDate <= now) {
            return;
        }

        LockedDeposits storage _lockedDeposits = user2lockedDeposits[_userKey];
        uint _lockedBalance = _lockedDeposits.date2deposit[_lockupDate];

        if (_lockedBalance == 0) {
            uint _lockedDepositsCounter = _lockedDeposits.counter.add(1);
            _lockedDeposits.counter = _lockedDepositsCounter;
            _lockedDeposits.index2Date[_lockedDepositsCounter] = _lockupDate;
        }
        _lockedDeposits.date2deposit[_lockupDate] = _lockedBalance.add(_amount);
    }

    function _syncLockedDepositsAmount(bytes32 _userKey) internal returns (uint _lockedSum) {
        LockedDeposits storage _lockedDeposits = user2lockedDeposits[_userKey];
        uint _lockedDepositsCounter = _lockedDeposits.counter;

        for (uint _idx = 1; _idx <= _lockedDepositsCounter; ++_idx) {
            uint _lockDate = _lockedDeposits.index2Date[_idx];

            if (_lockDate <= now) {
                _lockedDeposits.index2Date[_idx] = _lockedDeposits.index2Date[_lockedDepositsCounter];

                delete _lockedDeposits.index2Date[_lockedDepositsCounter];
                delete _lockedDeposits.date2deposit[_lockDate];

                _lockedDepositsCounter = _lockedDepositsCounter.sub(1);
                continue;
            }

            _lockedSum = _lockedSum.add(_lockedDeposits.date2deposit[_lockDate]);
        }

        _lockedDeposits.counter = _lockedDepositsCounter;
    }

    function _getBmcDaysAmountForUser(bytes32 _userKey, uint _date, uint _periodIdx) internal view returns (uint) {
        uint _lastPeriodForUserIdx = user2lastPeriodParticipated[_userKey];
        if (_lastPeriodForUserIdx == 0) {
            return 0;
        }

        Period storage _transferPeriod = _lastPeriodForUserIdx <= _periodIdx ? periods[_lastPeriodForUserIdx] : periods[_periodIdx];
        uint _lastTransferDate = _transferPeriod.transfer2date[_transferPeriod.user2lastTransferIdx[_userKey]];
        // NOTE: It is an intended substraction separation to correctly round dates
        uint _daysLong = (_date / 1 days) - (_lastTransferDate / 1 days);
        uint _bmcDays = _transferPeriod.user2bmcDays[_userKey];
        return _bmcDays.add(_transferPeriod.user2balance[_userKey] * _daysLong);
    }

    /* PRIVATE */

    function _getTotalBmcDaysAmount(uint _date, uint _periodIdx) private view returns (uint) {
        Period storage _depositPeriod = periods[_periodIdx];
        uint _transfersCount = _depositPeriod.transfersCount;
        uint _lastRecordedDate = _transfersCount != 0 ? _depositPeriod.transfer2date[_transfersCount] : _depositPeriod.startDate;

        if (_lastRecordedDate == 0) {
            return 0;
        }

        // NOTE: It is an intended substraction separation to correctly round dates
        uint _daysLong = (_date / 1 days).sub((_lastRecordedDate / 1 days));
        uint _totalBmcDeposit = _depositPeriod.totalBmcDays.add(_depositPeriod.bmcDaysPerDay.mul(_daysLong));
        return _totalBmcDeposit;
    }
}

/// @title Profiterole contract
/// Collector and distributor for creation and redemption fees.
/// Accepts bonus tokens from EmissionProvider, BurningMan or other distribution source.
/// Calculates CCs shares in bonuses. Uses Treasury Contract as source of shares in bmc-days.
/// Allows to withdraw bonuses on request.
contract Profiterole is OracleContractAdapter, ServiceAllowance, ProfiteroleEmitter {

    uint constant PERCENT_PRECISION = 10000;

    uint constant PROFITEROLE_ERROR_SCOPE = 102000;
    uint constant PROFITEROLE_ERROR_INSUFFICIENT_DISTRIBUTION_BALANCE = PROFITEROLE_ERROR_SCOPE + 1;
    uint constant PROFITEROLE_ERROR_INSUFFICIENT_BONUS_BALANCE = PROFITEROLE_ERROR_SCOPE + 2;
    uint constant PROFITEROLE_ERROR_TRANSFER_ERROR = PROFITEROLE_ERROR_SCOPE + 3;

    using SafeMath for uint;

    struct Balance {
        uint left;
        bool initialized;
    }

    struct Deposit {
        uint balance;
        uint left;
        uint nextDepositDate;
        mapping(bytes32 => Balance) leftToWithdraw;
    }

    struct UserBalance {
        uint lastWithdrawDate;
    }

    mapping(address => bool) distributionSourcesList;
    mapping(bytes32 => UserBalance) bonusBalances;
    mapping(uint => Deposit) public distributionDeposits;

    uint public firstDepositDate;
    uint public lastDepositDate;

    address public bonusToken;
    address public treasury;
    address public wallet;

    /// @dev Guards functions only for distributionSource invocations
    modifier onlyDistributionSource {
        if (!distributionSourcesList[msg.sender]) {
            revert();
        }
        _;
    }

    function Profiterole(address _bonusToken, address _treasury, address _wallet) public {
        require(_bonusToken != 0x0);
        require(_treasury != 0x0);
        require(_wallet != 0x0);

        bonusToken = _bonusToken;
        treasury = _treasury;
        wallet = _wallet;
    }

    function() payable public {
        revert();
    }

    /* EXTERNAL */

    /// @notice Sets new treasury address
    /// Only for contract owner.
    function updateTreasury(address _treasury) external onlyContractOwner returns (uint) {
        require(_treasury != 0x0);
        treasury = _treasury;
        return OK;
    }

    /// @notice Sets new wallet address for profiterole
    /// Only for contract owner.
    function updateWallet(address _wallet) external onlyContractOwner returns (uint) {
        require(_wallet != 0x0);
        wallet = _wallet;
        return OK;
    }

    /// @notice Add distribution sources to whitelist.
    ///
    /// @param _whitelist addresses list.
    function addDistributionSources(address[] _whitelist) external onlyContractOwner returns (uint) {
        for (uint _idx = 0; _idx < _whitelist.length; ++_idx) {
            distributionSourcesList[_whitelist[_idx]] = true;
        }
        return OK;
    }

    /// @notice Removes distribution sources from whitelist.
    /// Only for contract owner.
    ///
    /// @param _blacklist addresses in whitelist.
    function removeDistributionSources(address[] _blacklist) external onlyContractOwner returns (uint) {
        for (uint _idx = 0; _idx < _blacklist.length; ++_idx) {
            delete distributionSourcesList[_blacklist[_idx]];
        }
        return OK;
    }

    /// @notice Allows to withdraw user&#39;s bonuses that he deserves due to Treasury shares for
    /// every distribution period.
    /// Only oracles allowed to invoke this function.
    ///
    /// @param _userKey aggregated user key (user ID + role ID) on behalf of whom bonuses will be withdrawn
    /// @param _value an amount of tokens to withdraw
    /// @param _withdrawAddress destination address of withdrawal (usually user&#39;s address)
    /// @param _feeAmount an amount of fee that will be taken from resulted _value
    /// @param _feeAddress destination address of fee transfer
    ///
    /// @return result code of an operation
    function withdrawBonuses(bytes32 _userKey, uint _value, address _withdrawAddress, uint _feeAmount, address _feeAddress) external onlyOracle returns (uint) {
        require(_userKey != bytes32(0));
        require(_value != 0);
        require(_feeAmount < _value);
        require(_withdrawAddress != 0x0);

        DepositWalletInterface _wallet = DepositWalletInterface(wallet);
        ERC20Interface _bonusToken = ERC20Interface(bonusToken);
        if (_bonusToken.balanceOf(_wallet) < _value) {
            return _emitError(PROFITEROLE_ERROR_INSUFFICIENT_BONUS_BALANCE);
        }

        if (OK != _withdrawBonuses(_userKey, _value)) {
            revert();
        }

        if (!(_feeAddress == 0x0 || _feeAmount == 0 || OK == _wallet.withdraw(_bonusToken, _feeAddress, _feeAmount))) {
            revert();
        }

        if (OK != _wallet.withdraw(_bonusToken, _withdrawAddress, _value - _feeAmount)) {
            revert();
        }

        BonusesWithdrawn(_userKey, _value, now);
        return OK;
    }

    /* PUBLIC */

    /// @notice Gets total amount of bonuses user has during all distribution periods
    /// @param _userKey aggregated user key (user ID + role ID)
    /// @return _sum available amount of bonuses to withdraw
    function getTotalBonusesAmountAvailable(bytes32 _userKey) public view returns (uint _sum) {
        uint _startDate = _getCalculationStartDate(_userKey);
        Treasury _treasury = Treasury(treasury);

        for (
            uint _endDate = lastDepositDate;
            _startDate <= _endDate && _startDate != 0;
            _startDate = distributionDeposits[_startDate].nextDepositDate
        ) {
            Deposit storage _pendingDeposit = distributionDeposits[_startDate];
            Balance storage _userBalance = _pendingDeposit.leftToWithdraw[_userKey];

            if (_userBalance.initialized) {
                _sum = _sum.add(_userBalance.left);
            } else {
                uint _sharesPercent = _treasury.getSharesPercentForPeriod(_userKey, _startDate);
                _sum = _sum.add(_pendingDeposit.balance.mul(_sharesPercent).div(PERCENT_PRECISION));
            }
        }
    }

    /// @notice Gets an amount of bonuses user has for concrete distribution date
    /// @param _userKey aggregated user key (user ID + role ID)
    /// @param _distributionDate date of distribution operation
    /// @return available amount of bonuses to withdraw for selected distribution date
    function getBonusesAmountAvailable(bytes32 _userKey, uint _distributionDate) public view returns (uint) {
        Deposit storage _deposit = distributionDeposits[_distributionDate];
        if (_deposit.leftToWithdraw[_userKey].initialized) {
            return _deposit.leftToWithdraw[_userKey].left;
        }

        uint _sharesPercent = Treasury(treasury).getSharesPercentForPeriod(_userKey, _distributionDate);
        return _deposit.balance.mul(_sharesPercent).div(PERCENT_PRECISION);
    }

    /// @notice Gets total amount of deposits that has left after users&#39; bonus withdrawals
    /// @return amount of deposits available for bonus payments
    function getTotalDepositsAmountLeft() public view returns (uint _amount) {
        uint _lastDepositDate = lastDepositDate;
        for (
            uint _startDate = firstDepositDate;
            _startDate <= _lastDepositDate || _startDate != 0;
            _startDate = distributionDeposits[_startDate].nextDepositDate
        ) {
            _amount = _amount.add(distributionDeposits[_startDate].left);
        }
    }

    /// @notice Gets an amount of deposits that has left after users&#39; bonus withdrawals for selected date
    /// @param _distributionDate date of distribution operation
    /// @return amount of deposits available for bonus payments for concrete distribution date
    function getDepositsAmountLeft(uint _distributionDate) public view returns (uint _amount) {
        return distributionDeposits[_distributionDate].left;
    }

    /// @notice Makes checkmark and deposits tokens on profiterole account
    /// to pay them later as bonuses for Treasury shares holders. Timestamp of transaction
    /// counts as the distribution period date.
    /// Only addresses that were added as a distributionSource are allowed to call this function.
    ///
    /// @param _amount an amount of tokens to distribute
    ///
    /// @return result code of an operation.
    /// PROFITEROLE_ERROR_INSUFFICIENT_DISTRIBUTION_BALANCE, PROFITEROLE_ERROR_TRANSFER_ERROR errors
    /// are possible
    function distributeBonuses(uint _amount) public onlyDistributionSource returns (uint) {

        ERC20Interface _bonusToken = ERC20Interface(bonusToken);

        if (_bonusToken.allowance(msg.sender, address(this)) < _amount) {
            return _emitError(PROFITEROLE_ERROR_INSUFFICIENT_DISTRIBUTION_BALANCE);
        }

        if (!_bonusToken.transferFrom(msg.sender, wallet, _amount)) {
            return _emitError(PROFITEROLE_ERROR_TRANSFER_ERROR);
        }

        if (firstDepositDate == 0) {
            firstDepositDate = now;
        }

        uint _lastDepositDate = lastDepositDate;
        if (_lastDepositDate != 0) {
            distributionDeposits[_lastDepositDate].nextDepositDate = now;
        }

        lastDepositDate = now;
        distributionDeposits[now] = Deposit(_amount, _amount, 0);

        Treasury(treasury).addDistributionPeriod();

        DepositPendingAdded(_amount, msg.sender, now);
        return OK;
    }

    function isTransferAllowed(address, address, address, address, uint) public view returns (bool) {
        return false;
    }

    /* PRIVATE */

    function _getCalculationStartDate(bytes32 _userKey) private view returns (uint _startDate) {
        _startDate = bonusBalances[_userKey].lastWithdrawDate;
        return _startDate != 0 ? _startDate : firstDepositDate;
    }

    function _withdrawBonuses(bytes32 _userKey, uint _value) private returns (uint) {
        uint _startDate = _getCalculationStartDate(_userKey);
        uint _lastWithdrawDate = _startDate;
        Treasury _treasury = Treasury(treasury);

        for (
            uint _endDate = lastDepositDate;
            _startDate <= _endDate && _startDate != 0 && _value > 0;
            _startDate = distributionDeposits[_startDate].nextDepositDate
        ) {
            uint _balanceToWithdraw = _withdrawBonusesFromDeposit(_userKey, _startDate, _value, _treasury);
            _value = _value.sub(_balanceToWithdraw);
        }

        if (_lastWithdrawDate != _startDate) {
            bonusBalances[_userKey].lastWithdrawDate = _lastWithdrawDate;
        }

        if (_value > 0) {
            revert();
        }

        return OK;
    }

    function _withdrawBonusesFromDeposit(bytes32 _userKey, uint _periodDate, uint _value, Treasury _treasury) private returns (uint) {
        Deposit storage _pendingDeposit = distributionDeposits[_periodDate];
        Balance storage _userBalance = _pendingDeposit.leftToWithdraw[_userKey];

        uint _balanceToWithdraw;
        if (_userBalance.initialized) {
            _balanceToWithdraw = _userBalance.left;
        } else {
            uint _sharesPercent = _treasury.getSharesPercentForPeriod(_userKey, _periodDate);
            _balanceToWithdraw = _pendingDeposit.balance.mul(_sharesPercent).div(PERCENT_PRECISION);
            _userBalance.initialized = true;
        }

        if (_balanceToWithdraw > _value) {
            _userBalance.left = _balanceToWithdraw - _value;
            _balanceToWithdraw = _value;
        } else {
            delete _userBalance.left;
        }

        _pendingDeposit.left = _pendingDeposit.left.sub(_balanceToWithdraw);
        return _balanceToWithdraw;
    }
}