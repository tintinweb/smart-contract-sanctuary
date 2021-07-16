//SourceUnit: Rise.sol


// File: contracts/SafeMath.sol

pragma solidity 0.4.25;


/// @dev Math operations with safety checks that revert on error
library SafeMath {
    /// @dev Multiplies two numbers, reverts on overflow.
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'MUL_ERROR');

        return c;
    }

    /// @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'DIVIDING_ERROR');
        uint256 c = a / b;
        return c;
    }

    /// @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, 'SUB_ERROR');
        uint256 c = a - b;
        return c;
    }

    /// @dev Adds two numbers, reverts on overflow.
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'ADD_ERROR');
        return c;
    }

    /// @dev Divides two numbers and returns the remainder (unsigned integer modulo), reverts when dividing by zero.
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, 'MOD_ERROR');
        return a % b;
    }
}

// File: contracts/helpers/Claimable.sol

pragma solidity 0.4.25;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    function isOwner() public view returns (bool) {
        return (owner == msg.sender);
    }

    modifier onlyContractOwner() {
        require(isOwner(), 'Not a contract owner');
        _;
    }
}

contract Claimable is Ownable {
    address public pendingOwner;

    function transferOwnership(address _newOwner) public onlyContractOwner() {
        pendingOwner = _newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == pendingOwner, 'Not a pending owner');

        address previousOwner = owner;
        owner = msg.sender;
        pendingOwner = address(0);

        emit OwnershipTransferred(previousOwner, msg.sender);
    }
}

// File: contracts/helpers/Administrable.sol

pragma solidity 0.4.25;


contract Administrable is Claimable {
    mapping(address => bool) public isAdmin;

    event AdminAppointed(address admin);
    event AdminDismissed(address admin);

    constructor() public {
        isAdmin[owner] = true;

        emit AdminAppointed(owner);
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], 'NOT_AN_ADMIN');
        _;
    }

    function appointAdmin(address _newAdmin) public onlyContractOwner() returns (bool success) {
        if (isAdmin[_newAdmin] == false) {
            isAdmin[_newAdmin] = true;
        }

        emit AdminAppointed(_newAdmin);
        return true;
    }

    function dismissAdmin(address _admin) public onlyContractOwner() returns (bool success) {
        isAdmin[_admin] = false;

        emit AdminDismissed(_admin);
        return true;
    }
}

// File: contracts/TRC20.sol

pragma solidity 0.4.25;




interface ITRC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract TRC20 is ITRC20, Administrable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowed;

    uint256 private _totalSupply;

    uint256 private _totalBurnt;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function totalBurnt() public view returns (uint256) {
        return _totalBurnt;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0), 'spender cannot be address(0)');

        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        emit Approval(from, msg.sender, _allowed[from][msg.sender]);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0), 'spender cannot be address(0)');

        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0), 'spender cannot be address(0)');

        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        require(from != address(0), 'from cannot be address(0)');
        require(to != address(0), 'to cannot be address(0)');

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        require(account != address(0), 'account cannot be address(0)');

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    function _burn(address account, uint256 value) internal {
        require(account != address(0), 'account cannot be address(0)');

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);

        _totalBurnt = _totalBurnt.add(value);

        emit Transfer(account, address(0), value);
    }

    function _burnFrom(address account, uint256 value) internal {
        _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
        _burn(account, value);
    }
}


contract TRC20Detailed is TRC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(string name, string symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    function name() public view returns (string) {
        return _name;
    }

    function symbol() public view returns (string) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

// File: contracts/RoundMath.sol

pragma solidity 0.4.25;


/// @dev Math operations with safety checks that revert on error
library RoundMath {
    /// @dev Integer division of two numbers rounding the quotient, reverts on division by zero.
    function roundDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'DIVIDING_ERROR');
        uint256 c = (((a * 10) / b) + 5) / 10;
        return c;
    }

    /// @dev Integer division of two numbers ceiling the quotient, reverts on division by zero.
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'DIVIDING_ERROR');
        uint256 c = a / b;
        if (a % b > 0) {
            c = c + 1;
        }
        return c;
    }
}

// File: contracts/DateLib.sol

pragma solidity 0.4.25;


library DateLib {
    uint256 constant DAY_IN_SECONDS = 86400;
    uint256 constant YEAR_IN_SECONDS = 31536000;
    uint256 constant LEAP_YEAR_IN_SECONDS = 31622400;

    uint16 constant ORIGIN_YEAR = 1970;

    function getHoursInMonth(uint256 _timestamp) internal pure returns (uint256) {
        uint256 timestamp = _timestamp / 1000;

        uint256 secondsAccountedFor = 0;
        uint256 buf;
        uint8 i;

        uint16 year;
        uint8 month;

        // Year
        year = _getYear(timestamp);
        buf = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
        secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - buf);

        // Month
        uint256 secondsInMonth;
        for (i = 1; i <= 12; i++) {
            secondsInMonth = DAY_IN_SECONDS * _getDaysInMonth(i, year);
            if (secondsInMonth + secondsAccountedFor > timestamp) {
                month = i;
                break;
            }
            secondsAccountedFor += secondsInMonth;
        }

        return (_getDaysInMonth(month, year) * 24);
    }

    function _getDaysInMonth(uint8 _month, uint16 _year) private pure returns (uint256) {
        if (
            _month == 1 ||
            _month == 3 ||
            _month == 5 ||
            _month == 7 ||
            _month == 8 ||
            _month == 10 ||
            _month == 12
        ) {
            return 31;
        } else if (_month == 4 || _month == 6 || _month == 9 || _month == 11) {
            return 30;
        } else if (isLeapYear(_year)) {
            return 29;
        } else {
            return 28;
        }
    }

    function _getYear(uint256 _timestamp) private pure returns (uint16) {
        uint256 secondsAccountedFor = 0;
        uint16 year;
        uint256 numLeapYears;

        // Year
        year = uint16(ORIGIN_YEAR + _timestamp / YEAR_IN_SECONDS);
        numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
        secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

        while (secondsAccountedFor > _timestamp) {
            if (isLeapYear(uint16(year - 1))) {
                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
            } else {
                secondsAccountedFor -= YEAR_IN_SECONDS;
            }
            year -= 1;
        }
        return year;
    }

    function isLeapYear(uint16 _year) private pure returns (bool) {
        if (_year % 4 != 0) {
            return false;
        }
        if (_year % 100 != 0) {
            return true;
        }
        if (_year % 400 != 0) {
            return false;
        }
        return true;
    }

    function leapYearsBefore(uint256 _year) private pure returns (uint256) {
        uint256 year = _year - 1;
        return year / 4 - year / 100 + year / 400;
    }
}

// File: contracts/rise.sol

pragma solidity 0.4.25;





contract CashInterface {
    function totalSupply() public view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function mintFromRise(address to, uint256 value) public returns (bool);

    function burnFromRise(address tokensOwner, uint256 value) external returns (bool);
}


contract Rise is TRC20Detailed {
    using RoundMath for uint256;
    using DateLib for uint256;

    /**
     * STATE VARIABLES
     */
    address public cashContract;
    uint256 public quarantineBalance;
    uint256 public lastBlockNumber; // number of last created block
    uint256 public lastBalancedHour;

    // Price of Rise in USD has base of PRICE_BASE
    uint256 constant PRICE_BASE = 10**8;

    // Inital price of Rise in USD
    uint256 constant INITIAL_PRICE = 888901550;

    // Structure of a Price Block
    struct Block {
        uint256 risePrice; // USD price of Rise for the block
        uint256 growthRate; // FutureGrowthRate value at the time of block creation
        //solium-disable-next-line max-len
        uint256 change; // percentage (base of PRICE_BASE), RisePrice change relative to prev. block
        uint256 created; // hours, Unix epoch time
    }

    // Price Blocks for a given hour (number of hours since epoch time)
    mapping(uint256 => Block) public hoursToBlock;

    /**
     * Price factors for months with [28, 29, 30, 31] days,
     * price factors determine compounding hourly growth
     * from the headling monthly growthRate,
     * calculated as (1+r)^(1/t)-1
     * where:
     * r - growthRate,
     * t - number of hours in a given month
     *
     * e.g.: for growthRate=2850 (2850/GROWTH_RATE_BASE=0.285=28.5%)
     * price factors are (considering PRICE_FACTOR_BASE): [37322249, 36035043, 34833666, 33709810]
     */
    mapping(uint256 => uint256[4]) public growthRateToPriceFactors;
    uint256 constant GROWTH_RATE_BASE = 10**4;
    uint256 constant PRICE_FACTOR_BASE = 10**11;

    bool public priceFactorsLocked = false;

    event DoBalance(uint256 indexed currentHour, uint256 riseAmountBurnt);

    event ConvertToCash(
        address indexed converter,
        uint256 riseAmountSent,
        uint256 cashAmountReceived
    );

    event ConvertToRise(
        address indexed converter,
        uint256 cashAmountSent,
        uint256 riseAmountReceived
    );

    event MintCash(address receiver, uint256 amount);

    event BurnCash(uint256 amountBurnt);

    event PriceFactorSet(
        uint256 growthRate,
        uint256 priceFactor0,
        uint256 priceFactor1,
        uint256 priceFactor2,
        uint256 priceFactor3
    );

    event BlockCreated(
        uint256 blockNumber,
        uint256 risePrice,
        uint256 growthRate,
        uint256 change,
        uint256 created
    );

    event QuarantineBalanceBurnt(uint256 amount);

    event LostTokensBurnt(uint256 amount);

    /**
     * Creates Rise contract. Also sets the Cash address
     * to the contract storage to be able to interact with it.
     * Mints 1 billion tokens to _mintSaver address.
     */
    constructor(address _mintSaver, address _cashContract)
        public
        TRC20Detailed('Centric RISE', 'CNR', 8)
    {
        _mint(_mintSaver, 100000000000000000); // 1 Billion
        cashContract = _cashContract;
    }

    // Returns price of Rise for the current hour
    function getCurrentPrice() external view returns (uint256) {
        require(hoursToBlock[getCurrentHour()].risePrice > 0, 'BLOCK_NOT_DEFINED');
        return hoursToBlock[getCurrentHour()].risePrice;
    }

    // Returns price of Rise at a specified hour
    function getPrice(uint256 _hour) external view returns (uint256) {
        require(hoursToBlock[_hour].risePrice > 0, 'BLOCK_NOT_DEFINED');
        return hoursToBlock[_hour].risePrice;
    }

    /**
     *  Returns Price Block data
     *  uint256 risePrice;     // USD price of Rise for the block
     *  uint256 growthRate;    // growthRate value of the risePrice
     *  uint256 change;        // percentage (base of PRICE_BASE), RisePrice change relative to prev. block
     *  uint256 created;       // hours, unix epoch time
     */
    function getBlockData(uint256 _hoursEpoch)
        external
        view
        returns (uint256 _risePrice, uint256 _growthRate, uint256 _change, uint256 _created)
    {
        require(_hoursEpoch > 0, 'EMPTY_HOURS_VALUE');
        require(hoursToBlock[_hoursEpoch].risePrice > 0, 'BLOCK_NOT_DEFINED');

        _risePrice = hoursToBlock[_hoursEpoch].risePrice;
        _growthRate = hoursToBlock[_hoursEpoch].growthRate;
        _change = hoursToBlock[_hoursEpoch].change;
        _created = hoursToBlock[_hoursEpoch].created;

        return (_risePrice, _growthRate, _change, _created);
    }

    /**
     * Single call creates ONE Price Block with specified monthly _growthRate.
     * For creating a batch of blocks function needs to be run according amount of times.
     * Admin should always make sure that there is a block for the currentHour
     * and if not - create it. Otherwise users will not be able to convert tokens
     * until a new block is created.
     * _blockNumber - always has to be lastBlockNumber + 1 (works only as a security check)
     * _growthRate - must be specified in growthRateToPriceFactors
     * percentage (fraction of 1, e.g.: 0.3)
     * presented as integer with base of GROWTH_RATE_BASE (to be divided by GROWTH_RATE_BASE to get a fraction of 1)
     */
    function doCreateBlock(uint256 _blockNumber, uint256 _growthRate)
        external
        onlyAdmin()
        returns (bool _success)
    {
        require(priceFactorsLocked, 'PRICE_FACTORS_MUST_BE_LOCKED');

        require(_growthRate != 0, 'GROWTH_RATE_CAN_NOT_BE_ZERO');
        require(_growthRate < GROWTH_RATE_BASE, 'GROWTH_RATE_IS_GREATER_THAN_GROWTH_RATE_BASE');
        require(growthRateToPriceFactors[_growthRate][0] > 0, 'GROWTH_RATE_IS_NOT_SPECIFIED');

        require(_createBlock(_blockNumber, _growthRate), 'FAILED_TO_CREATE_BLOCK');
        return true;
    }

    /**
     * set growthRateToPriceFactors
     * _priceFactors - see comments for mapping growthRateToPriceFactors
     */
    function setPriceFactors(uint256 _growthRate, uint256[4] _priceFactors)
        external
        onlyAdmin()
        returns (bool _success)
    {
        require(priceFactorsLocked == false, 'PRICE_FACTORS_ALREADY_LOCKED');

        require(_growthRate != 0, 'GROWTH_RATE_CAN_NOT_BE_ZERO');
        require(_growthRate < GROWTH_RATE_BASE, 'GROWTH_RATE_IS_GREATER_THAN_GROWTH_RATE_BASE');

        require(_priceFactors[0] > 0, 'PRICE_FACTOR_0_CAN_NOT_BE_ZERO');
        require(_priceFactors[0] < 103200117, 'PRICE_FACTOR_0_IS_TOO_BIG');
        require(_priceFactors[1] > 0, 'PRICE_FACTOR_1_CAN_NOT_BE_ZERO');
        require(_priceFactors[1] < 99639720, 'PRICE_FACTOR_1_IS_TOO_BIG');
        require(_priceFactors[2] > 0, 'PRICE_FACTOR_2_CAN_NOT_BE_ZERO');
        require(_priceFactors[2] < 96316797, 'PRICE_FACTOR_2_IS_TOO_BIG');
        require(_priceFactors[3] > 0, 'PRICE_FACTOR_3_CAN_NOT_BE_ZERO');
        require(_priceFactors[3] < 93208356, 'PRICE_FACTOR_3_IS_TOO_BIG');

        require(
            _priceFactors[0] > _priceFactors[1] &&
                _priceFactors[1] > _priceFactors[2] &&
                _priceFactors[2] > _priceFactors[3],
            'PRICE_FACTORS_ARE_NOT_VALID'
        );

        growthRateToPriceFactors[_growthRate] = _priceFactors;

        emit PriceFactorSet(
            _growthRate,
            _priceFactors[0],
            _priceFactors[1],
            _priceFactors[2],
            _priceFactors[3]
        );
        return true;
    }

    /**
     * Call only after all priceFactors have been set
     * Call before creating first block
     */
    function lockPriceFactors() external onlyAdmin() returns (bool _success) {
        priceFactorsLocked = true;
        return true;
    }

    /**
     * Public function that burns Rise from quarantine
     * according to the burnQuarantine() formula.
     * Needed for economic logic of Rise token.
     */
    function doBalance() external returns (bool _success) {
        require(hoursToBlock[getCurrentHour()].risePrice != 0, 'CURRENT_PRICE_BLOCK_NOT_DEFINED');
        require(lastBalancedHour < getCurrentHour(), 'CHANGE_IS_ALREADY_BURNT_IN_THIS_HOUR');

        lastBalancedHour = getCurrentHour();

        uint256 _riseBurnt = _burnQuarantined();

        emit DoBalance(getCurrentHour(), _riseBurnt);
        return true;
    }

    /**
     * Public function that allows users to convert Cash tokens to Rise ones.
     * Amount of received Rise tokens depends on the risePrice of the current block.
     */
    function convertToRise(uint256 _cashAmount) external returns (bool _success) {
        require(hoursToBlock[getCurrentHour()].risePrice != 0, 'CURRENT_PRICE_BLOCK_NOT_DEFINED');

        require(
            CashInterface(cashContract).balanceOf(msg.sender) >= _cashAmount,
            'INSUFFICIENT_CASH_BALANCE'
        );

        require(
            CashInterface(cashContract).burnFromRise(msg.sender, _cashAmount),
            'BURNING_CASH_FAILED'
        );

        emit BurnCash(_cashAmount);

        uint256 _riseToDequarantine = (_cashAmount.mul(PRICE_BASE)).div(
            hoursToBlock[getCurrentHour()].risePrice
        );

        quarantineBalance = quarantineBalance.sub(_riseToDequarantine);
        require(this.transfer(msg.sender, _riseToDequarantine), 'CONVERT_TO_RISE_FAILED');

        emit ConvertToRise(msg.sender, _cashAmount, _riseToDequarantine);
        return true;
    }

    /**
     * Public function that allows users to convert Rise tokens to Cash ones.
     * Amount of received Cash tokens depends on the risePrice of a current block.
     */
    function convertToCash(uint256 _riseAmount) external returns (uint256) {
        require(hoursToBlock[getCurrentHour()].risePrice != 0, 'CURRENT_PRICE_BLOCK_NOT_DEFINED');

        require(balanceOf(msg.sender) >= _riseAmount, 'INSUFFICIENT_RISE_BALANCE');

        quarantineBalance = quarantineBalance.add(_riseAmount);
        require(transfer(address(this), _riseAmount), 'RISE_TRANSFER_FAILED');

        uint256 _cashToIssue = (_riseAmount.mul(hoursToBlock[getCurrentHour()].risePrice)).div(
            PRICE_BASE
        );

        require(
            CashInterface(cashContract).mintFromRise(msg.sender, _cashToIssue),
            'CASH_MINT_FAILED'
        );

        emit MintCash(msg.sender, _cashToIssue);

        emit ConvertToCash(msg.sender, _riseAmount, _cashToIssue);
        return _cashToIssue;
    }

    /**
     * Function is needed to burn lost tokens that probably were sent
     * to the contract address by mistake.
     */
    function burnLostTokens() external onlyContractOwner() returns (bool _success) {
        uint256 _amount = balanceOf(address(this)).sub(quarantineBalance);

        _burn(this, _amount);

        emit LostTokensBurnt(_amount);
        return true;
    }

    /**
     * Internal function that implements logic to burn a part of Rise tokens on quarantine.
     * Formula is based on network capitalization rules -
     * Network capitalization of quarantined Rise must be equal to
     * network capitalization of Cash
     * calculated as (q * pRISE - c * pCASH) / pRISE
     * where:
     * q - quarantined Rise,
     * pRISE - current risePrice
     * c - current cash supply
     * pCash - Cash pegged price ($1 USD fixed conversion price)
     */
    function _burnQuarantined() internal returns (uint256) {
        uint256 _quarantined = quarantineBalance;
        uint256 _currentPrice = hoursToBlock[getCurrentHour()].risePrice;
        uint256 _cashSupply = CashInterface(cashContract).totalSupply();

        uint256 _riseToBurn = (
            (((_quarantined.mul(_currentPrice)).div(PRICE_BASE)).sub(_cashSupply)).mul(PRICE_BASE)
        )
            .div(_currentPrice);

        quarantineBalance = quarantineBalance.sub(_riseToBurn);
        _burn(this, _riseToBurn);

        emit QuarantineBalanceBurnt(_riseToBurn);
        return _riseToBurn;
    }

    /**
     * Internal function for creating a new Price Block.
     */
    function _createBlock(uint256 _expectedBlockNumber, uint256 _growthRate)
        internal
        returns (bool _success)
    {
        uint256 _lastPrice;
        uint256 _nextBlockNumber;

        if (lastBlockNumber == 0) {
            require(_expectedBlockNumber > getCurrentHour(), 'FIRST_BLOCK_MUST_BE_IN_THE_FUTURE');
            require(
                _expectedBlockNumber < getCurrentHour() + 365 * 24,
                'FIRST_BLOCK_MUST_BE_WITHIN_ONE_YEAR'
            );
            _lastPrice = INITIAL_PRICE;
            _nextBlockNumber = _expectedBlockNumber;
        } else {
            _lastPrice = hoursToBlock[lastBlockNumber].risePrice;
            _nextBlockNumber = lastBlockNumber.add(1);
        }

        require(_nextBlockNumber == _expectedBlockNumber, 'WRONG_BLOCK_NUMBER');

        uint256 _risePriceFactor;

        uint256 _monthBlocks = (_nextBlockNumber * 60 * 60 * 1000).getHoursInMonth();
        if (_monthBlocks == 28 * 24) _risePriceFactor = growthRateToPriceFactors[_growthRate][0];
        else if (_monthBlocks == 29 * 24)
            _risePriceFactor = growthRateToPriceFactors[_growthRate][1];
        else if (_monthBlocks == 30 * 24)
            _risePriceFactor = growthRateToPriceFactors[_growthRate][2];
        else _risePriceFactor = growthRateToPriceFactors[_growthRate][3];

        uint256 _risePrice = (
            (_risePriceFactor.mul(_lastPrice)).add(_lastPrice.mul(PRICE_FACTOR_BASE))
        )
            .ceilDiv(PRICE_FACTOR_BASE);

        uint256 _change = (_risePrice.sub(_lastPrice)).mul(PRICE_BASE).roundDiv(_lastPrice);
        uint256 _created = getCurrentHour();

        hoursToBlock[_nextBlockNumber] = Block({
            risePrice: _risePrice,
            growthRate: _growthRate,
            change: _change,
            created: _created
        });

        lastBlockNumber = _nextBlockNumber;

        emit BlockCreated(_nextBlockNumber, _risePrice, _growthRate, _change, _created);
        return true;
    }

    // For testing purposes
    function getCurrentTime() public view returns (uint256) {
        return now;
    }

    // Helper function
    function getCurrentHour() public view returns (uint256) {
        return getCurrentTime().div(1 hours);
    }
}