//"SPDX-License-Identifier: MIT"

pragma solidity ^0.8.4;


interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library DateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        uint year;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        uint year;
        uint month;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        uint fromYear;
        uint fromMonth;
        uint fromDay;
        uint toYear;
        uint toMonth;
        uint toDay;
        (fromYear, fromMonth, fromDay) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        uint fromYear;
        uint fromMonth;
        uint fromDay;
        uint toYear;
        uint toMonth;
        uint toDay;
        (fromYear, fromMonth, fromDay) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        //require(fromTimestamp <= toTimestamp);
        if (fromTimestamp <= toTimestamp) _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
        else _hours = 0;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        //require(fromTimestamp <= toTimestamp);
        if (fromTimestamp <= toTimestamp) _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
        else _minutes = 0;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        //require(fromTimestamp <= toTimestamp);
        if (fromTimestamp <= toTimestamp) _seconds = toTimestamp - fromTimestamp;
        else _seconds = 0;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        // The account hash of 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned for non-contract addresses,
        // so-called Externally Owned Account (EOA)
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Pair {
    function sync() external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract TokenNew2 is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using DateTimeLibrary for uint;

    string private _name = "TokenNew2";
    string private _symbol = "TKNN2";
    uint8 private _decimals = 9;

    struct tokenHolders {
        address addresses;
        uint256 balanceBeforeTransfer;
        uint256 balance;
        uint256 reflectionsForTransfer;
        uint256 reflectionsAccumulated;
        bool inserted;
        uint lastSellTransferTime;
        uint claimTime;
        uint256 NFTPercentageMax;
        bool inBlaclist;
        uint isLocked;
        bool isBot;
        bool isExcludedFromTaxFee;
        bool isExcludedFromForBuyFee;
        bool isExcludedFromAntiSellFee;
        bool isExcludedFromReward;
    }
    mapping (address => tokenHolders) private _tokenHoldersList;
    address[] private _tokenHoldersAccounts;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _tokenTotal = 100_000_000_000e9; // TOTAL AMOUNT : 100.000.000.000 tokens
    uint256 private _tokenCirculatingTotal = 100_000_000_000e9; // totale crcolante espresso come somma dei balance degli holders esclusi i token in liquidity
    uint256 private _tokenNoSellTotal = 100_000_000_000e9; // totale dei token posseduti da holders che non hanno mai venduto
    uint256 private _tokenWithNftTotal = 100_000_000_000e9; // totale dei token posseduti da holders che hanno anche almeno un NFT

    bool private _autoMode = false; // allo start disattiva il calcolo della Anti Sell fee tramite Oracolo
    uint256 private _antiSellFeeFromOracle = 3; // variable% taxation in BNB to avoid Sells
    uint256 private _previousAntiSellFeeFromOracle = _antiSellFeeFromOracle;

    uint256 private _taxFee = 1; // 5% redistribuition
    uint256 private _previousTaxFee = _taxFee;

    uint256 private _forBuyFee = 2; // 5% forBuy fee divisa tra NFT Fee pari al 2% e Marketing Fee pari al 3%
    uint256 private _previousForBuyFee = _forBuyFee;

    uint256 private _taxFeeTotal;
    uint256 private _antiSellFeeTotal;
    uint256 private _forBuyFeeTotal;
    uint256 private _totalReflectionsLastTransfer; // somma delle rflexions dell'ultima transazione
    uint256 public VerifyAmountToTranferInBNB;

    bool private _tradingIsEnabled = true;
    bool private _isDistributionInWethEnabled = true;
    bool private _inSwapAndLiquify;

    uint256 private _maxTxAmount = 200_000_000e9; // Max transferrable in one transaction (0,2% of _tokenTotal)
    uint256 private _minTokensBeforeSwap = 200_000e9; // una volta accumulati questi token li bende e fa lo swap
    uint256 private _balanceOfMaxPermitted = 3_000_000_000e9; // massimo permesso nell'account di un holder, superato il quale viene posto in Locked List (3% del total amount)
    // trasformandoli in BNB mandandoli nel wallet buyBack, dovrebbe causare un crollo dello 0,04% della curva del prezzo

    address private _antiDipAddress = 0xFebCfaAFF11edA4Ba94C9788c28567e2FEA6237C; ///
    address private _marketingAddress = 0xFebCfaAFF11edA4Ba94C9788c28567e2FEA6237C; ///
    address private _forBuyAddress = address(this); // For Buy address -  usa il contratto stesso come wallet per raccogliere queste fee
    address private _antiSellAddress = address(this); // Anti Sell address -  usa il contratto stesso come wallet per raccogliere queste fee
    address private _gameDevAddress = 0xDf430DA77C2cc6eB9EeF2dc77F794040042a73be; //

    uint256 private _marketingWalletPercent = 16;
    uint256 private _nftWalletPercent = 8;
    uint256 private _antiDipToReflectToHoldersWalletPercent = 15;
    uint256 private _taxFeeWalletPercent = 16;
    uint256 private _gameDevWalletPercent = 15;
    uint256 private _antiDipWalletPercent = 30;

    // tempo di elaborazione medio di un blocco su BSC = 3 secondi
    uint private _periodTime_1m = 60; // 1 minuto = 20 blocchi
    uint private _periodTime_5m = 300; // 5 minuti = 100 blocchi
    uint private _periodTime_15m = 900; // 15 minuti = 300 blocchi
    uint private _periodTime_30m = 1800; // 30 minut1 = 600 blocchi
    uint private _periodTime_1h = 3600; // 1 ora = 1.200 blocchi
    uint private _periodTime_2h = 7200; // 2 ore = 2.400 blocchi
    uint private _periodTime_4h = 14400; // 4 ore = 4.800 blocchi
    uint private _periodTime_6h = 21600; // 6 ore = 7.200 blocchi
    uint private _periodTime_12h = 43200; // 12 ore = 14.400 blocchi
    uint private _periodTime_1d = 86400; // 1 giorno = 28.800 blocchi
    uint private _periodTime_1W = 604800; // 1 settimana = 201.600 blocchi
    uint private _periodTime_1M = 2592000; // 1 mese = 864.000 blocchi
    uint private _periodTime_3M = 7776000; // 3 mesi = 2.592.000 blocchi
    uint private _periodTime_6M = 15552000; // 6 mesi = 5.184.000 blocchi
    uint private _periodTime_1Y = 31104000; // 1 anno = 10.368.000 blocchi

    uint private _epoch_1 = _periodTime_30m; // periodo di distribuzione reward in WETH a holders normali e wallet team
    uint private _epoch_2 = _periodTime_4h; // periodo di distribuzione reward in WETH a holders che non hanno mai venduto
    uint private _epochClaimNft = _periodTime_1W; // tempo che passa dal listing al momento in cui sdi potrà fare il claim NFT

    uint private _nextDistributionTime_1; // orario di start della prossima distribuzione 1
    uint private _nextDistributionTime_2; // orario di start della prossima distribuzione 2
    uint private _claimNftDistributionTime; // orario di start per la distribuzione del claim NFT dopo il listing

    uint256 private _balanceNeededForClaim;

    bool private _antiBotMode = false;
    bool private _lockedListMode = false;
    uint256 private _maxGWeiPermitted = 12000000000; // 8 GWei

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    ///////////// Token's contract addressess BSC Mainnet///////////////////
    // address public constant ETH_BinanceToken = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
    // address public constant USDC_BinanceToken = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    // address public constant BUSD_BinanceToken = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    // address public constant Cake = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    // address public constant USDT_BinanceToken = 0x55d398326f99059fF775485246999027B3197955;

    ///////////// Token's contract addressess BSC Testnet ///////////////////
    //address public constant ETH_BinanceToken = 0x8babbb98678facc7342735486c851abd7a0d17ca;
    address public constant BUSD_BinanceToken = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;
    //address public constant USDT_BinanceToken = 0x7ef95a0fee0dd31b22626fa2e10ee6a223f8a684;


    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped,uint256 ethReceived, uint256 tokensIntoLiqudity);
    event antiBotActivated(address bot, uint256 gWeiPaid);

    modifier lockTheSwap {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    constructor ()  {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); // Pancake Router Testnet
        //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E); // Pancake Router Mainnet
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        // inerisce l'owner tra gli holders
        _tokenHoldersList[_msgSender()].inserted = true;
        _tokenHoldersList[_msgSender()].balanceBeforeTransfer = _tokenTotal;
        _tokenHoldersList[_msgSender()].balance = _tokenTotal;
        _tokenHoldersList[_msgSender()].reflectionsForTransfer = 0;
        _tokenHoldersList[_msgSender()].reflectionsAccumulated = 0;
        _tokenHoldersList[_msgSender()].lastSellTransferTime = 0;
        _tokenHoldersList[_msgSender()].claimTime = 0;
        _tokenHoldersList[_msgSender()].NFTPercentageMax = 0;
        _tokenHoldersList[_msgSender()].inBlaclist = false;
        _tokenHoldersList[_msgSender()].isLocked = 2;
        _tokenHoldersList[_msgSender()].isBot = false;
        _tokenHoldersList[_msgSender()].isExcludedFromTaxFee = true;
        _tokenHoldersList[_msgSender()].isExcludedFromForBuyFee = true;
        _tokenHoldersList[_msgSender()].isExcludedFromAntiSellFee = true;
        _tokenHoldersList[_msgSender()].isExcludedFromReward = false;
        _tokenHoldersAccounts.push(_msgSender());

        // inerisce address(this), cioè il contratto, tra gli holders
        _tokenHoldersList[address(this)].inserted = true;
        _tokenHoldersList[address(this)].balanceBeforeTransfer = 0;
        _tokenHoldersList[address(this)].balance = 0;
        _tokenHoldersList[address(this)].reflectionsForTransfer = 0;
        _tokenHoldersList[address(this)].reflectionsAccumulated = 0;
        _tokenHoldersList[address(this)].lastSellTransferTime = 0;
        _tokenHoldersList[address(this)].claimTime = 0;
        _tokenHoldersList[address(this)].NFTPercentageMax = 0;
        _tokenHoldersList[address(this)].inBlaclist = false;
        _tokenHoldersList[address(this)].isLocked = 2;
        _tokenHoldersList[address(this)].isBot = false;
        _tokenHoldersList[address(this)].isExcludedFromTaxFee = true;
        _tokenHoldersList[address(this)].isExcludedFromForBuyFee = true;
        _tokenHoldersList[address(this)].isExcludedFromAntiSellFee = true;
        _tokenHoldersList[address(this)].isExcludedFromReward = false;
        _tokenHoldersAccounts.push(address(this));

        // inerisce il router di PancakeSwap
        _tokenHoldersList[uniswapV2Pair].inserted = true;
        _tokenHoldersList[uniswapV2Pair].balanceBeforeTransfer = 0;
        _tokenHoldersList[uniswapV2Pair].balance = 0;
        _tokenHoldersList[uniswapV2Pair].reflectionsForTransfer = 0;
        _tokenHoldersList[uniswapV2Pair].reflectionsAccumulated = 0;
        _tokenHoldersList[uniswapV2Pair].lastSellTransferTime = 0;
        _tokenHoldersList[uniswapV2Pair].claimTime = 0;
        _tokenHoldersList[uniswapV2Pair].NFTPercentageMax = 0;
        _tokenHoldersList[uniswapV2Pair].inBlaclist = false;
        _tokenHoldersList[uniswapV2Pair].isLocked = 2;
        _tokenHoldersList[uniswapV2Pair].isBot = false;
        _tokenHoldersList[uniswapV2Pair].isExcludedFromTaxFee = false;
        _tokenHoldersList[uniswapV2Pair].isExcludedFromForBuyFee = false;
        _tokenHoldersList[uniswapV2Pair].isExcludedFromAntiSellFee = true;
        _tokenHoldersList[uniswapV2Pair].isExcludedFromReward = true;
        _tokenHoldersAccounts.push(uniswapV2Pair);

        emit Transfer(address(0), _msgSender(), _tokenTotal);
    }

    function mint(address _account, uint256 _amount) public onlyOwner returns (bool) {
        require(_account != address(0), "BEP20: mint to the zero address");
        _tokenTotal = _tokenTotal.add(_amount);
        _tokenHoldersList[_account].balance.add(_amount);
        emit Transfer(address(0), _account, _amount);
        return true;
    }

    function burn(address _account, uint256 _amount) public onlyOwner returns (bool) {
        require(_account != address(0), "BEP20: burn from the zero address");
        require(_tokenTotal >= _amount, "BEP20: total supply must be >= amout");
        _tokenTotal = _tokenTotal.sub(_amount);
        require(_tokenHoldersList[_account].balance >= _amount, "BEP20: the balance of account must be >= of amount");
        _tokenHoldersList[_account].balance.sub(_amount);

        emit Transfer(_account, address(0), _amount);
        return true;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function get_AntiDipAddress() external view returns (address) {
        return _antiDipAddress;
    }

    function get_MarketingAddress() external view returns (address) {
        return _marketingAddress;
    }

    function get_ContractAddress() external view returns (address) {
        return address(this);
    }

    function set_TaxFee (uint256 value) external onlyOwner {
        _taxFee = value;
    }

    function get_TaxFee() external view returns (uint256) {
        return _taxFee;
    }

    function set_ForBuyFee (uint256 value) external onlyOwner {
        _forBuyFee = value;
    }

    function get_ForBuyFee() external view returns (uint256) {
        return _forBuyFee;
    }

    function totalSupply() public view override returns (uint256) {
        return _tokenTotal;
    }

    function get_maxTXAmountPerTransfer() external view returns (uint256) {
        return _maxTxAmount;
    }

    function get_AntiSellAutoFromOracle() external view returns (bool) {
        return _autoMode;
    }

    function get_antiSellFeeFromOracle() external view returns (uint256) {
        return _antiSellFeeFromOracle;
    }

    function set_antiSellFeeFromOracle(uint256 antiSellFeeFromOracle) external onlyOwner returns (uint256) {
        _antiSellFeeFromOracle = antiSellFeeFromOracle;
        return _antiSellFeeFromOracle;
    }

    function get_marketingWalletPercent() external view returns (uint256) {
        return _marketingWalletPercent;
    }

    function get_nftWalletPercent() external view returns (uint256) {
        return _nftWalletPercent;
    }

    function get_antiDipToReflectToHoldersWalletPercent() external view returns (uint256) {
        return _antiDipToReflectToHoldersWalletPercent;
    }

    function get_taxFeeWalletPercent() external view returns (uint256) {
        return _taxFeeWalletPercent;
    }

    function get_antiDipWalletPercent() external view returns (uint256) {
        return _antiDipWalletPercent;
    }

    function get_gameDevWalletPercent() external view returns (uint256) {
        return _gameDevWalletPercent;
    }

    function balanceOf(address addr) public view override returns (uint256) {
        return _tokenHoldersList[addr].balance;
    }

    function set_PresaleParameters (
    ) external onlyOwner {
        removeTaxFee();
        removeForBuyFee();
        removeAntiSellFee();
        set_AntiSellAutoFromOracle(false); // settare a false
        set_MaxTxPerThousand(1000); // settare a 1000
        set_TradingIsEnabled(true); // se si mette a false non si riesce a creare il liquidity pool a mano
        set_DistributionInWethEnabled(false);
        set_LockedListMode(false);
    }

    function set_PancakeSwapParameters (
      uint256 _MaxTXPerThousand,
      bool _antiSellAutoFromOracle,
      bool _enableTrading,
      bool _enableDistributionInWeth,
      uint epochPeriod1,
      uint epochPeriod2,
      uint epochClaimNftPeriod,
      bool lockedListMode

    ) external onlyOwner {
        restoreTaxFee();
        restoreForBuyFee();
        restoreAntiSellFee();
        set_AntiSellAutoFromOracle(_antiSellAutoFromOracle); // settare a true
        set_MaxTxPerThousand(_MaxTXPerThousand); // settare a 2
        set_TradingIsEnabled(_enableTrading); // mettere a true se si vuole permettere il trading da subito
        set_DistributionInWethEnabled(_enableDistributionInWeth); // mettere a true se si vuole swappare ed inviare reflections
        set_AntiBotMode(true);
        set_LockedListMode(lockedListMode);
        set_Epoch(1,epochPeriod1);
        set_Epoch(2,epochPeriod2);
        set_EpochClaimNft(epochClaimNftPeriod);
        set_NextDistributionTime(1);
        set_NextDistributionTime(2);
        set_ClaimNftDistributionTime();
    }

    function randomNumber() public view returns(uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp + block.difficulty + ((uint256(keccak256(abi.encodePacked(block.coinbase)))) /
                    (block.timestamp)) + block.gaslimit + ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                    (block.timestamp)) + block.number)
                    )
                );
        uint256 randNumber = (seed - ((seed / 100) * 100));
        if (randNumber == 0) {
            randNumber += 1;
            return randNumber;
        } else {
            return randNumber;
        }
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BNB20: transfer amount exceeds allowance"));
        _transfer2(sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BNB20: decreased allowance below zero"));
        return true;
    }

    function calculateTaxFeeTotal() external view returns (uint256) {
        return _taxFeeTotal;
    }

    function calculateForBuyFeeTotal() external view returns (uint256) {
        return _forBuyFeeTotal;
    }

    function calculateAntiSellFeeTotal() external view returns (uint256) {
        return _antiSellFeeTotal;
    }

    function set_AntiSellAutoFromOracle(bool autoMode) public onlyOwner {
        _autoMode = autoMode;
    }

    function set_AntiBotMode(bool antiBotMode) public onlyOwner {
        _antiBotMode = antiBotMode;
    }

    function get_AntiBotMode() external view returns (bool) {
        return _antiBotMode;
    }

    function set_LockedListMode(bool lockedListMode) public onlyOwner {
         _lockedListMode = lockedListMode;
     }

     function get_LockedListMode() external view returns (bool) {
         return _lockedListMode;
     }

    function set_MaxGWeiPermitted(uint256 maxGWeiPermitted) public onlyOwner {
        _maxGWeiPermitted = maxGWeiPermitted;
    }

    function get_MaxGWeiPermitted() external view returns (uint256) {
        return _maxGWeiPermitted;
    }

    function set_MaxTxPerThousand(uint256 maxTxThousand) public onlyOwner { // expressed in per thousand and not in percent
        _maxTxAmount = _tokenTotal.mul(maxTxThousand).div(10**3);
    }

    function get_Epoch(uint set) public view returns (uint) {
        // set = 1 -> distribuzione reward in WETH a holders normali e wallet team
        // set = 2 -> distribuzione reward in WETH a holders che non hanno mai venduto
        if (set == 1) return _epoch_1;
        else if (set == 2) return _epoch_2;
        else return 0;
    }

    function set_Epoch(uint set, uint epochPeriod) public onlyOwner returns (bool) {
        // set = 1 -> distribuzione reward in WETH a holders normali e wallet team
        // set = 2 -> distribuzione reward in WETH a holders che non hanno mai venduto
        if (set == 1) {
            _epoch_1 = epochPeriod;
            return true;
        }
        else if (set == 2) {
            _epoch_2 = epochPeriod;
            return true;
        }
        else return false;
    }

    function set_EpochClaimNft(uint epochclaimnftperiod) public onlyOwner returns (bool) {
        _epochClaimNft = epochclaimnftperiod;
        return true;
    }

    function get_EpochClaimNft() public view returns (uint) {
        return _epochClaimNft;
    }

    function set_NextDistributionTime (uint set) public onlyOwner returns (bool) {
        // set = 1 -> distribuzione reward in WETH a holders normali e wallet team
        // set = 2 -> distribuzione reward in WETH a holders che non hanno mai venduto
        if (set == 1) {
            _nextDistributionTime_1 = block.timestamp.add(_epoch_1);
            return true;
        }
        else if (set == 2) {
            _nextDistributionTime_2 = block.timestamp.add(_epoch_2);
            return true;
        }
        else return false;
    }

    function get_NextDistributionTime (uint set) public view returns (uint) {
        // set = 1 -> distribuzione reward in WETH a holders normali e wallet team
        // set = 2 -> distribuzione reward in WETH a holders che non hanno mai venduto
        if (set == 1) return _nextDistributionTime_1;
        else if (set == 2) return _nextDistributionTime_2;
        else return 0;
    }

    function set_ClaimNftDistributionTime () public onlyOwner returns (bool) {
        _claimNftDistributionTime = block.timestamp.add(_epochClaimNft);
        return true;
    }

    function get_ClaimNftDistributionTime () public view returns (uint) {
        return _claimNftDistributionTime;
    }

    function get_RemainingTimeToNextDistribution(uint set) public view returns (uint[] memory) {
        // set = 1 -> distribuzione reward in WETH a holders normali e wallet team
        // set = 2 -> distribuzione reward in WETH a holders che non hanno mai venduto
        uint[] memory remainingtime = new uint[](3);
        uint _hoursTotal = DateTimeLibrary.diffHours(block.timestamp, get_NextDistributionTime(set));
        uint _minutesTotal = DateTimeLibrary.diffMinutes(block.timestamp, get_NextDistributionTime(set));
        uint _secondsTotal = DateTimeLibrary.diffSeconds(block.timestamp, get_NextDistributionTime(set));
        uint _hoursInMinutes = _hoursTotal.mul(60);
        uint _hoursInSeconds = _hoursTotal.mul(3600);
        uint _minutes;
        uint _minutesInSeconds;
        uint _seconds;
        if (_hoursTotal != 0) _minutes = _minutesTotal.mod(_hoursInMinutes);
        else _minutes = _minutesTotal;
        _minutesInSeconds = _minutes.mul(60);
        if (_hoursInSeconds.add(_minutesInSeconds) != 0) _seconds = _secondsTotal.mod(_hoursInSeconds.add(_minutesInSeconds));
        else _seconds = _secondsTotal;
        remainingtime[0] = _hoursTotal;
        remainingtime[1] = _minutes;
        remainingtime[2] = _seconds;
        return remainingtime;
    }

    function get_RemainingTimeToNftClaim() public view returns (uint[] memory) {
        uint[] memory remainingtime = new uint[](3);
        uint _hoursTotal = DateTimeLibrary.diffHours(block.timestamp, get_ClaimNftDistributionTime());
        uint _minutesTotal = DateTimeLibrary.diffMinutes(block.timestamp, get_ClaimNftDistributionTime());
        uint _secondsTotal = DateTimeLibrary.diffSeconds(block.timestamp, get_ClaimNftDistributionTime());
        uint _hoursInMinutes = _hoursTotal.mul(60);
        uint _hoursInSeconds = _hoursTotal.mul(3600);
        uint _minutes;
        uint _minutesInSeconds;
        uint _seconds;
        if (_hoursTotal != 0) _minutes = _minutesTotal.mod(_hoursInMinutes);
        else _minutes = _minutesTotal;
        _minutesInSeconds = _minutes.mul(60);
        if (_hoursInSeconds.add(_minutesInSeconds) != 0) _seconds = _secondsTotal.mod(_hoursInSeconds.add(_minutesInSeconds));
        else _seconds = _secondsTotal;
        remainingtime[0] = _hoursTotal;
        remainingtime[1] = _minutes;
        remainingtime[2] = _seconds;
        return remainingtime;
    }

    function get_NowTime () public view returns (uint) {
        return block.timestamp;
    }

    function changeAntiDipAddress(address payable _newaddress) public onlyOwner {
        _antiDipAddress = _newaddress;
    }

    function changeMarketingAddress(address payable _newaddress) public onlyOwner {
        _marketingAddress = _newaddress;
    }

    function changeGameDevAddress(address payable _newaddress) public onlyOwner {
        _gameDevAddress = _newaddress;
    }

    function changeMarketingWalletPercent(uint256  _newpercent) public onlyOwner {
        _marketingWalletPercent = _newpercent;
    }

    function changeNftWalletPercent(uint256  _newpercent) public onlyOwner {
        _nftWalletPercent = _newpercent;
    }

    function changeAntiDipToReflectToHoldersWalletPercent(uint256  _newpercent) public onlyOwner {
        _antiDipToReflectToHoldersWalletPercent = _newpercent;
    }

    function changeTaxFeeWalletPercent(uint256  _newpercent) public onlyOwner {
        _taxFeeWalletPercent = _newpercent;
    }

    function changeAntiDipWalletPercent(uint256  _newpercent) public onlyOwner {
        _antiDipWalletPercent = _newpercent;
    }

    function changeGameDevWalletPercent(uint256  _newpercent) public onlyOwner {
        _gameDevWalletPercent = _newpercent;
    }

    function set_MinTokensBeforeSwap(uint256 amount) external onlyOwner {
        _minTokensBeforeSwap = amount;
    }

    function _updateTaxFeesTotal(uint256 taxfeeamont) private {
        _taxFeeTotal = _taxFeeTotal.add(taxfeeamont);
    }

    function _updateForBuyFeesTotal(uint256 forbuyfeeamount) private {
        _forBuyFeeTotal = _forBuyFeeTotal.add(forbuyfeeamount);
    }

    function _updateAntiSellFeesTotal(uint256 antisellfeeamount) private {
        _antiSellFeeTotal = _antiSellFeeTotal.add(antisellfeeamount);
    }

    function set_WalletsPercent(
        uint256 _marketingWallPercent,
        uint256 _nftWallPercent,
        uint256 _antiDipToReflectToHoldersWallPercent,
        uint256 _taxFeeWallPercent,
        uint256 _antiDipWallPercent
        ) external onlyOwner {

        _marketingWalletPercent = _marketingWallPercent;
        _nftWalletPercent = _nftWallPercent;
        _antiDipToReflectToHoldersWalletPercent = _antiDipToReflectToHoldersWallPercent;
        _taxFeeWalletPercent = _taxFeeWallPercent;
        _taxFeeWalletPercent = _taxFeeWallPercent;
        _antiDipWalletPercent = _antiDipWallPercent;
    }

    function set_TradingIsEnabled(bool enabled) public onlyOwner {
        _tradingIsEnabled = enabled;
        emit SwapAndLiquifyEnabledUpdated(enabled);
    }

    function get_tradingIsEnabled() external view returns (bool) {
        return _tradingIsEnabled;
    }

    function set_DistributionInWethEnabled(bool enabled) public onlyOwner {
        _isDistributionInWethEnabled = enabled;
    }

    function get_DistributionInWethEnabled() external view returns (bool) {
        return _isDistributionInWethEnabled;
    }

//////////////////////////////////////////////////////////////////////////////////////////////
////////// funzioni utilizzate per il calcolo delle fee dal transfer /////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**2);
    }

    function calculateForBuyFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_forBuyFee).div(10**2);
    }

    function calculateAntiSellFee(uint256 _amount) private pure returns (uint256) {
        return _amount.mul(0).div(10**2);
    }

//////////////////////////////////////////////////////////////////////////////////////////////
////////// funzioni utilizzate per il calcolo delle fee dal transferfrom /////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////

    function calculateTaxFee2(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**2);
    }

    function calculateForBuyFee2(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_forBuyFee).div(10**2);
    }

    function calculateAntiSellFee2(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_antiSellFeeFromOracle).div(10**2);
    }

//////////////////////////////////////////////////////////////////////////////////////////////

    function removeTaxFee() private {
        if(_taxFee == 0) return;
        _previousTaxFee = _taxFee;
        _taxFee = 0;
    }

    function removeForBuyFee() private {
        if(_forBuyFee == 0) return;
        _previousForBuyFee = _forBuyFee;
        _forBuyFee = 0;
    }

    function removeAntiSellFee() private {
        if(_antiSellFeeFromOracle == 0) return;
        _previousAntiSellFeeFromOracle = _antiSellFeeFromOracle;
        _antiSellFeeFromOracle = 0;
    }

    function restoreTaxFee() private {
        _taxFee = _previousTaxFee;
    }

    function restoreForBuyFee() private {
        _forBuyFee = _previousForBuyFee;
    }

    function restoreAntiSellFee() private {
        _antiSellFeeFromOracle = _previousAntiSellFeeFromOracle;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "BNB20: approve from the zero address");
        require(spender != address(0), "BNB20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /////////////////////////////////////////////////////////////////////////////////////////
    //////////////////// funzione di transfer per il transfer ///////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////
    //questa funzione è utilizzata per comprare token da pancakeswap o per inviarli a terzi, qui il sender è pancakeswap che vende ed il recipient è l'holder che compra
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "BNB20: transfer from the zero address");
        require(recipient != address(0), "BNB20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(_tradingIsEnabled, "Trading disabled !");
        if(sender != owner() && recipient != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            require(get_InBlackListFromAddressTokenHolder(recipient) == false, "the recipient account is Black listed!");
            require(get_InBlackListFromAddressTokenHolder(sender) == false, "the sender account is Black listed!");

        if (_lockedListMode) { // impedisce agli utenti di fare trading se hanno raggiunto un alta percentuale di balance
            require(get_IsLockedFromAddressTokenHolder(recipient) != 1, "the recipient account is Locked! his balance over 3% of total amount");
            require(get_IsLockedFromAddressTokenHolder(sender) != 1, "the sender account is Locked! his balance over 3% of total amount");
        }

        if (_antiBotMode) { // impedisce agli sniper di conprare dal pool, con GWei >= 8, normalmente pancakeswap permette Gwei = 4,5,6
            if(tx.gasprice >= _maxGWeiPermitted){
                set_IsBotFromAddressTokenHolder(recipient,true);
                emit antiBotActivated(recipient, tx.gasprice);
            }
            require(get_IsBotFromAddressTokenHolder(recipient) == false, "Bots are not welcome !");
        }
        _tokenTransfer (sender, recipient, amount);
    }

    function _tokenTransfer (address sender, address recipient, uint256 amount) private {

        uint256 taxfee;
        uint256 forbuyfee;
        uint256 antisellfee;
        bool excludedFromTaxFee_sender = get_IsExcludedFromTaxFeeFromAddressTokenHolder(sender);
        bool excludedFromForBuyFee_sender = get_IsExcludedFromForBuyFeeFromAddressTokenHolder(sender);
        bool excludedFromAntiSellFee_sender = get_IsExcludedFromAntiSellFeeFromAddressTokenHolder(sender);
        uint256 allTaxAmountFees; // totale di tutte le tasse (taxfee + forbuyfee + antisellfee)
        uint256 contractAmountFees; // totale di tutte le tasse che vanno al contratto (forbuyfee + antisellfee)

        if (excludedFromTaxFee_sender) taxfee = 0;
        else taxfee = calculateTaxFee(amount);

        if (excludedFromForBuyFee_sender) forbuyfee = 0;
        else forbuyfee = calculateForBuyFee(amount);

        if (excludedFromAntiSellFee_sender) antisellfee = 0;
        else antisellfee = calculateAntiSellFee(amount);

        allTaxAmountFees = taxfee.add(forbuyfee).add(antisellfee);
        contractAmountFees = forbuyfee.add(antisellfee);

        _updateTaxFeesTotal(taxfee);
        _updateForBuyFeesTotal(forbuyfee);
        _updateAntiSellFeesTotal(antisellfee);

        _tokenTransferExecute (sender, recipient, amount, contractAmountFees, taxfee);
    }

    function _tokenTransferExecute (address sender, address recipient, uint256 amount, uint256 contractAmountFees, uint256 taxfee) private {

        uint256 balanceBefore_recipient = balanceOf(recipient);
        uint256 balanceBefore_sender = balanceOf(sender);
        uint256 balanceBefore_contrAddress = balanceOf(address(this));
        uint256 balanceSubtracted_sender = balanceBefore_sender.sub(amount);
        uint256 balanceAdded_recipient = balanceBefore_recipient.add(amount).sub(contractAmountFees).sub(taxfee);
        uint256 balanceAdded_contractaddress = balanceBefore_contrAddress.add(contractAmountFees);
        uint256 balance_sender = set_BalanceFromAddressTokenHolder(sender,balanceSubtracted_sender);
        uint256 balance_recipient = set_BalanceFromAddressTokenHolder(recipient,balanceAdded_recipient);
        uint256 balance_contractaddress = set_BalanceFromAddressTokenHolder(address(this),balanceAdded_contractaddress);

        _updateSenderRecipientContractTokenHolderValues(sender, balanceBefore_sender, balance_sender);
        _updateSenderRecipientContractTokenHolderValues(recipient, balanceBefore_recipient, balance_recipient);
        _updateSenderRecipientContractTokenHolderValues(address(this), balanceBefore_contrAddress, balance_contractaddress);

        _UpdateTokenReflexionsToTokenHolders(taxfee, _TotalTokenHoldersBalance()); // vengono solo registrate ma non distribuite realmente e quindi non presenti in balance
        _contractReBalance(contractAmountFees);
        emit Transfer(sender, recipient, amount);
        //_updateDistributeAllinWETH(sender);
    }

/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////// funzione di transfer per il transferfrom ////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////

    //questa funzione è utilizzata praticamente per la vendita di token a pancakeswap, qui il sender è l'holder che vende ed il recipient è il PancakeSwapRouterV2
    function _transfer2(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "BNB20: transfer from the zero address");
        require(recipient != address(0), "BNB20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(_tradingIsEnabled, "Trading disabled !");
        if(sender != owner() && recipient != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            require(get_InBlackListFromAddressTokenHolder(recipient) == false, "the recipient account is Black listed!");
            require(get_InBlackListFromAddressTokenHolder(sender) == false, "the sender account is Black listed!");

        if (_lockedListMode) { // impedisce agli utenti di fare trading se hanno raggiunto un alta percentuale di balance
            require(get_IsLockedFromAddressTokenHolder(recipient) != 1, "the recipient account is Locked! his balance over 3% of total amount");
            require(get_IsLockedFromAddressTokenHolder(sender) != 1, "the sender account is Locked! his balance over 3% of total amount");
        }

        if (_antiBotMode) { // impedisce agli sniper di conprare dal pool, con GWei >= 8, normalmente pancakeswap permette Gwei = 4,5,6
            if(tx.gasprice >= _maxGWeiPermitted){
                set_IsBotFromAddressTokenHolder(sender,true);
                emit antiBotActivated(sender, tx.gasprice);
            }
            require(get_IsBotFromAddressTokenHolder(sender) == false, "Bots are not welcome !");
        }
        _tokenTransfer2 (sender, recipient, amount);
    }

    function _tokenTransfer2 (address sender, address recipient, uint256 amount) private {

        uint lastselltime = block.timestamp;
        uint256 taxfee;
        uint256 forbuyfee;
        uint256 antisellfee;
        bool excludedFromTaxFee_sender = get_IsExcludedFromTaxFeeFromAddressTokenHolder(sender);
        bool excludedFromForBuyFee_sender = get_IsExcludedFromForBuyFeeFromAddressTokenHolder(sender);
        bool excludedFromAntiSellFee_sender = get_IsExcludedFromAntiSellFeeFromAddressTokenHolder(sender);
        uint256 allTaxAmountFees; // totale di tutte le tasse (taxfee + forbuyfee + antisellfee)
        uint256 contractAmountFees; // totale di tutte le tasse che vanno al contratto (forbuyfee + antisellfee)

        if (excludedFromTaxFee_sender) taxfee = 0;
        else taxfee = calculateTaxFee2(amount);

        if (excludedFromForBuyFee_sender) forbuyfee = 0;
        else forbuyfee = calculateForBuyFee2(amount);

        if (excludedFromAntiSellFee_sender) antisellfee = 0;
        else antisellfee = calculateAntiSellFee2(amount);

        allTaxAmountFees = taxfee.add(forbuyfee).add(antisellfee);
        contractAmountFees = forbuyfee.add(antisellfee);

        _updateTaxFeesTotal(taxfee);
        _updateForBuyFeesTotal(forbuyfee);
        _updateAntiSellFeesTotal(antisellfee);

        _tokenTransferExecute2 (sender, recipient, amount, contractAmountFees, taxfee, lastselltime);
    }

    function _tokenTransferExecute2 (address sender, address recipient, uint256 amount, uint256 contractAmountFees, uint256 taxfee, uint lastselltime) private {

        uint256 balanceBefore_recipient = balanceOf(recipient);
        uint256 balanceBefore_sender = balanceOf(sender);
        uint256 balanceBefore_contrAddress = balanceOf(address(this));
        uint256 balanceSubtracted_sender = balanceBefore_sender.sub(amount);
        uint256 balanceAdded_recipient = balanceBefore_recipient.add(amount).sub(contractAmountFees).sub(taxfee);
        uint256 balanceAdded_contractaddress = balanceBefore_contrAddress.add(contractAmountFees);
        uint256 balance_sender = set_BalanceFromAddressTokenHolder(sender,balanceSubtracted_sender);
        uint256 balance_recipient = set_BalanceFromAddressTokenHolder(recipient,balanceAdded_recipient);
        uint256 balance_contractaddress = set_BalanceFromAddressTokenHolder(address(this),balanceAdded_contractaddress);

        _updateSenderRecipientContractTokenHolderValues(sender, balanceBefore_sender, balance_sender);
        _updateSenderRecipientContractTokenHolderValues(recipient, balanceBefore_recipient, balance_recipient);
        _updateSenderRecipientContractTokenHolderValues(address(this), balanceBefore_contrAddress, balance_contractaddress);

        _UpdateTokenReflexionsToTokenHolders(taxfee, _TotalTokenHoldersBalance()); // vengono solo registrate ma non distribuite realmente e quindi non presenti in balance
        set_LastSellTransferTimeFromAddressTokenHolder(sender,lastselltime);
        _contractReBalance(contractAmountFees);
        emit Transfer(sender, recipient, amount);
        //_updateDistributeAllinWETH(sender);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////// funzioni per loswap dei token in BNB e la distribuzione ai vari wallet del team //////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    function _updateDistributeAllinWETH(address sender) public {
      uint256 constractBal=balanceOf(address(this));
      bool overMinTokenBalance = constractBal >= _minTokensBeforeSwap;
      if (!_inSwapAndLiquify && overMinTokenBalance && sender != uniswapV2Pair && _tradingIsEnabled) {
        if (_isDistributionInWethEnabled) _distributeInWETH(constractBal);
      }
    }

    function _swapTokensForBNB(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _swapBNBForBUSD(uint256 BNBAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = BUSD_BinanceToken;
        _approve(address(this), address(BUSD_BinanceToken), BNBAmount);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            BNBAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _distributeInWETH(uint256 amount) private lockTheSwap {
        // primo swap effettuato per trasformare una piccola porzione di tokens in BNB
        uint256 contractAddressBalance = get_BalanceFromAddressTokenHolder(address(this));
        uint256 newContractAddessBalance = contractAddressBalance.sub(amount);
        _swapTokensForBNB(amount);
        set_BalanceFromAddressTokenHolder(address(this),newContractAddessBalance);
        //IERC20 BNB = IERC20(address(uniswapV2Router));
        //uint256 BNB_Balance = BNB.balanceOf(address(this));

        // secondo swap effettuato per trasformare tutti i BNB precedentemente swappati in BUSD
        //_swapBNBForBUSD(BNB_Balance);
        //IERC20 BUSD = IERC20(address(BUSD_BinanceToken));
        //uint256 BUSD_Balance = BUSD.balanceOf(address(this));

        //uint256 amountToTranfer = BNB_Balance;
        // uint256 amountMarketingToTranfer = amountToTranfer.mul(16).div(100); // _marketingWalletPercent = 16;
        // uint256 amountNftToTranfer = amountToTranfer.mul(8).div(100); // _nftWalletPercent = 8;
        // uint256 amountAntiDipToReflectToHoldersAddressToTranfer = amountToTranfer.mul(15).div(100); // _zntiDipToReflectToHoldersWalletPercent = 15; // sarebbe il 25% del totale rimasto nel wallert antidip che risulta 60%
        // uint256 amountTaxFeeToTranfer = amountToTranfer.mul(16).div(100); // _taxFeeWalletPercent = 16;
        // uint256 amountGameDevToTranfer = amountToTranfer.mul(15).div(100); // _marketingWalletPercent = 15;
        // uint256 amountsum = amountMarketingToTranfer.add(amountNftToTranfer).add(amountAntiDipToReflectToHoldersAddressToTranfer).add(amountTaxFeeToTranfer).add(amountGameDevToTranfer);
        // uint256 amountAntiDipToTranfer = amountToTranfer.sub(amountsum); // _antiDipWalletPercent = 30

        // uint nextdistributiontime_1 = get_NextDistributionTime(1);
        // uint nextdistributiontime_2 = get_NextDistributionTime(2);

        // if (block.timestamp >= nextdistributiontime_1) {
        //     _distributeToAllHolders(amountTaxFeeToTranfer);
        //     _distributeToNftHolders(amountNftToTranfer);
        //     _distributeToAntiDip(amountAntiDipToTranfer);
        //     _distributeToMarketing(amountMarketingToTranfer);
        //     _distributeToGameDev(amountGameDevToTranfer);
        //     set_NextDistributionTime(1);
        // }
        // if (block.timestamp >= nextdistributiontime_2) {
        //     _distributeToNoSellHolders(amountAntiDipToReflectToHoldersAddressToTranfer);
        //     set_NextDistributionTime(2);
        // }
    }

    function _distributeToAllHolders(uint256 tokenAmount) private {
        uint256 size = _tokenHoldersAccounts.length;
        address keyAddress;
        uint256 amountToSend;
        bool isExcludedFromReward;
        uint256 holderbalance;
    
        for (uint256 i = 0; i < size ; i++) {
            keyAddress = _tokenHoldersAccounts[i];
            holderbalance = balanceOf(keyAddress);
            if (holderbalance > 0) {
                amountToSend = holderbalance.mul(tokenAmount).div(_TotalTokenHoldersBalance()); // calcola la porzione da inviare ad ogni holders
                isExcludedFromReward = get_IsExcludedFromRewardFromAddressTokenHolder(keyAddress);
                if (!isExcludedFromReward) payable(keyAddress).transfer(amountToSend);
            }
        }
    }
    //
    function _distributeToNftHolders(uint256 tokenAmount) private {
        uint256 size = _tokenHoldersAccounts.length;
        address keyAddress;
        uint256 amountToSend;
        uint256 nftPercentageMax;
        uint256 virtualBalance;
        uint256 virtualTotalNFTTokenHoldersBalance;
        bool isExcludedFromReward;
        uint256 holderbalance;
    
        for (uint256 i = 0; i < size ; i++) {
            keyAddress = _tokenHoldersAccounts[i];
            nftPercentageMax = get_NFTPercentageMaxFromAddressTokenHolder(keyAddress);
            holderbalance = balanceOf(keyAddress);
            if (holderbalance > 0 && nftPercentageMax > 0) {
                virtualBalance = holderbalance.add(holderbalance.mul(nftPercentageMax).div(100));
                virtualTotalNFTTokenHoldersBalance = _TotalNFTTokenHoldersBalance().sub(holderbalance).add(virtualBalance);
                amountToSend = virtualBalance.mul(tokenAmount).div(virtualTotalNFTTokenHoldersBalance); // calcola la porzione da inviare ad ogni holders che ha NFT nel wallet aggiungendo ai suoi token una porzione % data dalla carta
                isExcludedFromReward = get_IsExcludedFromRewardFromAddressTokenHolder(keyAddress);
                if (!isExcludedFromReward) payable(keyAddress).transfer(amountToSend);
            }
        }
        
    }
    //
    function _distributeToNoSellHolders(uint256 tokenAmount) private {
        uint256 size = _tokenHoldersAccounts.length;
        address keyAddress;
        uint256 amountToSend;
        uint lastselltime;
        uint256 holderbalance;
        bool isExcludedFromReward;

        for (uint256 i = 0; i < size ; i++) {
            keyAddress = _tokenHoldersAccounts[i];
            lastselltime = get_LastSellTransferTimeFromAddressTokenHolder(keyAddress);
            holderbalance = balanceOf(keyAddress);
            if (holderbalance > 0 && lastselltime == 0) {// non ha mai venduto
                amountToSend = holderbalance.mul(tokenAmount).div(_TotalNoSellTokenHoldersBalance()); // calcola la porzione da inviare ad ogni holders
                if (!isExcludedFromReward) payable(keyAddress).transfer(amountToSend);
            }
        }
    }
    
    function _distributeToAntiDip(uint256 tokenAmount) private {
         payable(_antiDipAddress).transfer(tokenAmount);
    }
    //
    function _distributeToMarketing(uint256 tokenAmount) private {
         payable(_marketingAddress).transfer(tokenAmount);
    }
    
    function _distributeToGameDev(uint256 tokenAmount) private {
         payable(_gameDevAddress).transfer(tokenAmount);
    }

    /////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////// funzioni del mapping TokenHolder /////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////

    function get_BalanceBeforeTransferFromAddressTokenHolder(address addr) public view returns (uint256) {
        return _tokenHoldersList[addr].balanceBeforeTransfer;
    }

    function get_BalanceFromAddressTokenHolder(address addr) public view returns (uint256) {
        return _tokenHoldersList[addr].balance;
    }

    function set_BalanceFromAddressTokenHolder(address addr, uint256 value) private returns (uint256) {
        _tokenHoldersList[addr].balance = value;
        return value;
    }

    function get_ReflectionsForTransferFromAddressTokenHolder(address addr) public view returns (uint256) {
        return _tokenHoldersList[addr].reflectionsForTransfer;
    }

    function set_ReflectionsForTransferFromAddressTokenHolder(address addr, uint256 value) private {
        _tokenHoldersList[addr].reflectionsForTransfer = value;
    }

    function get_ReflectionsAccumulatedFromAddressTokenHolder(address addr) public view returns (uint256) {
        return _tokenHoldersList[addr].reflectionsAccumulated;
    }

    function set_ReflectionsAccumulatedFromAddressTokenHolder(address addr, uint256 value) private {
        _tokenHoldersList[addr].reflectionsAccumulated = value ;
    }

    function get_LastSellTransferTimeFromAddressTokenHolder(address addr) public view returns (uint256) {
        return _tokenHoldersList[addr].lastSellTransferTime;
    }

    function set_LastSellTransferTimeFromAddressTokenHolder(address addr, uint lastselltime) private {
        _tokenHoldersList[addr].lastSellTransferTime = lastselltime;
    }

    function get_ClaimTimeFromAddressTokenHolder(address addr) public view returns (uint256) {
        return _tokenHoldersList[addr].claimTime;
    }

    function get_NFTPercentageMaxFromAddressTokenHolder(address addr) public view returns (uint256) {
        return _tokenHoldersList[addr].NFTPercentageMax;
    }

    function set_NFTPercentageMaxTokenHolder(address addr, uint256 percentagemax) public onlyOwner returns(bool) {
        _tokenHoldersList[addr].NFTPercentageMax = percentagemax;
        return true;
    }

    function get_InBlackListFromAddressTokenHolder(address addr) public view returns (bool) {
        return _tokenHoldersList[addr].inBlaclist;
    }

    function set_InBlackListFromAddressTokenHolder(address addr, bool enabled) public onlyOwner returns(bool) {
        _tokenHoldersList[addr].inBlaclist = enabled;
        return true;
    }

    // quando value = 1 sono indirizzi considerati bloccati perchè hanno superato il 3% del total amount
    // quando value = 2 sono indirizzi esclusi dal controllo
    // quando value != 1 o 2  sono indirizzi non ancora mappati ad esempio 0
    function set_IsLockedFromAddressTokenHolder(address addr, uint value) public onlyOwner {
        _tokenHoldersList[addr].isLocked = value;
    }

    function get_IsLockedFromAddressTokenHolder(address addr) public view returns (uint) {
        return _tokenHoldersList[addr].isLocked;
    }

    function get_InsertedFromAddressTokenHolder(address addr) public view returns (bool) {
        return _tokenHoldersList[addr].inserted;
    }

    function set_IsBotFromAddressTokenHolder(address addr, bool value) public onlyOwner {
        _tokenHoldersList[addr].isBot = value;
    }

    function get_IsBotFromAddressTokenHolder(address addr) public view returns (bool) {
        return _tokenHoldersList[addr].isBot;
    }

    function set_IsExcludedFromTaxFeeFromAddressTokenHolder(address addr, bool value) public onlyOwner {
          _tokenHoldersList[addr].isExcludedFromTaxFee = value;
    }

    function get_IsExcludedFromTaxFeeFromAddressTokenHolder(address addr) public view returns (bool) {
        return _tokenHoldersList[addr].isExcludedFromTaxFee;
    }

    function set_IsExcludedFromForBuyFeeFromAddressTokenHolder(address addr, bool value) public onlyOwner {
          _tokenHoldersList[addr].isExcludedFromForBuyFee = value;
    }

    function get_IsExcludedFromForBuyFeeFromAddressTokenHolder(address addr) public view returns (bool) {
        return _tokenHoldersList[addr].isExcludedFromForBuyFee;
    }

    function set_IsExcludedFromAntiSellFeeFromAddressTokenHolder(address addr, bool value) public onlyOwner {
          _tokenHoldersList[addr].isExcludedFromAntiSellFee = value;
    }

    function get_IsExcludedFromAntiSellFeeFromAddressTokenHolder(address addr) public view returns (bool) {
        return _tokenHoldersList[addr].isExcludedFromAntiSellFee;
    }

    function set_IsExcludedFromRewardFromAddressTokenHolder(address addr, bool value) public onlyOwner {
          _tokenHoldersList[addr].isExcludedFromReward = value;
    }

    function get_IsExcludedFromRewardFromAddressTokenHolder(address addr) public view returns (bool) {
        return _tokenHoldersList[addr].isExcludedFromReward;
    }

    function get_SizeTokenHolder() public view returns (uint) {
        return _tokenHoldersAccounts.length;
    }

    function get_TokenHolderList() public view returns (address[] memory) {
        return _tokenHoldersAccounts;
    }

    function set_AllValuesTokenHolder(
        address addr,
        uint256 balancebeforetransfer,
        uint256 balance
        ) private {

        if (_tokenHoldersList[addr].inserted) {
            _tokenHoldersList[addr].balanceBeforeTransfer = balancebeforetransfer;
            _tokenHoldersList[addr].balance = balance;
        } else {
            _tokenHoldersList[addr].inserted = true;
            _tokenHoldersList[addr].balanceBeforeTransfer = balancebeforetransfer;
            _tokenHoldersList[addr].reflectionsForTransfer = 0;
            _tokenHoldersList[addr].reflectionsAccumulated = 0;
            _tokenHoldersList[addr].lastSellTransferTime = 0;
            _tokenHoldersList[addr].claimTime = 0;
            _tokenHoldersList[addr].NFTPercentageMax = 0;
            _tokenHoldersList[addr].inBlaclist = false;
            _tokenHoldersList[addr].isLocked = 0;
            _tokenHoldersList[addr].isBot = false;
            _tokenHoldersList[addr].isExcludedFromTaxFee = false;
            _tokenHoldersList[addr].isExcludedFromForBuyFee = false;
            _tokenHoldersList[addr].isExcludedFromAntiSellFee = false;
            _tokenHoldersList[addr].isExcludedFromReward = false;
            _tokenHoldersAccounts.push(addr);
        }
    }

    /////////////////////////////////////////////////////////////////////////////////////////
    ///////////// funzioni per aggiornamento dei dati dei token holders /////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////


    function _updateSenderRecipientContractTokenHolderValues (
        address addr,
        uint256 balancebeforetransfer,
        uint256 balance
        ) private {

        set_AllValuesTokenHolder(
            addr, // sender
            balancebeforetransfer, // before transfer
            balance); // after transfer
    }

    function _UpdateTokenReflexionsToTokenHolders (uint256 taxfee, uint256 totaltokenholdersbalance) private {

        // setta i valori di tutti gli altri holder non updated
        uint256 size = _tokenHoldersAccounts.length;
        address keyAddress;
        uint256 holderBalance;
        bool isExcludedFromReward;
        uint256 reflectionsForTransfer;
        uint256 reflectionsAccumulated;
        _totalReflectionsLastTransfer = 0;

        for (uint256 i = 0; i < size ; i++) {
            keyAddress = _tokenHoldersAccounts[i];
            holderBalance = _tokenHoldersList[keyAddress].balance;
            isExcludedFromReward = get_IsExcludedFromRewardFromAddressTokenHolder(keyAddress);

            if(holderBalance != 0 && !isExcludedFromReward) {
                reflectionsForTransfer = holderBalance.mul(taxfee).div(totaltokenholdersbalance);
                set_ReflectionsForTransferFromAddressTokenHolder(keyAddress,reflectionsForTransfer);
                reflectionsAccumulated = get_ReflectionsAccumulatedFromAddressTokenHolder(keyAddress).add(reflectionsForTransfer);
                set_ReflectionsAccumulatedFromAddressTokenHolder(keyAddress,reflectionsAccumulated);
                _totalReflectionsLastTransfer = _totalReflectionsLastTransfer.add(reflectionsForTransfer);
            }
        }
    }

    function _TotalTokenHoldersBalance() public view returns (uint256 totalHoldersBalance) {

        // setta i valori di tutti gli altri holder non updated
        uint256 size = _tokenHoldersAccounts.length;
        address keyAddress;
        uint256 holderBalance;
        bool isExcludedFromReward;
        totalHoldersBalance = 0;

        for (uint256 i = 0; i < size ; i++) {
            keyAddress = _tokenHoldersAccounts[i];
            holderBalance = _tokenHoldersList[keyAddress].balance;
            isExcludedFromReward = get_IsExcludedFromRewardFromAddressTokenHolder(keyAddress);
            if(holderBalance != 0 && !isExcludedFromReward) { // se un account è escluso dai reward non contribuisce al calcolo del balance totale degli holders
                totalHoldersBalance = totalHoldersBalance.add(holderBalance);
            }
        }
        return totalHoldersBalance;
    }

    function _TotalNFTTokenHoldersBalance() public view returns (uint256 totalNFTHoldersBalance) {

        // setta i valori di tutti gli altri holder non updated
        uint256 size = _tokenHoldersAccounts.length;
        address keyAddress;
        uint256 holderBalance;
        bool isExcludedFromReward;
        uint256 NFTPercentage;
        bool isNFTHolder;
        totalNFTHoldersBalance = 0;

        for (uint256 i = 0; i < size ; i++) {
            keyAddress = _tokenHoldersAccounts[i];
            holderBalance = _tokenHoldersList[keyAddress].balance;
            isExcludedFromReward = get_IsExcludedFromRewardFromAddressTokenHolder(keyAddress);
            NFTPercentage = get_NFTPercentageMaxFromAddressTokenHolder(keyAddress);
            if (NFTPercentage > 0) isNFTHolder = true;
            else isNFTHolder = false;
            if(holderBalance != 0 && !isExcludedFromReward && isNFTHolder) { // se un account è escluso dai reward non contribuisce al calcolo del balance totale degli holders
                totalNFTHoldersBalance = totalNFTHoldersBalance.add(holderBalance);
            }
        }
        return totalNFTHoldersBalance;
    }

    function _TotalNoSellTokenHoldersBalance() public view returns (uint256 totalNoSellHoldersBalance) {

        // setta i valori di tutti gli altri holder non updated
        uint256 size = _tokenHoldersAccounts.length;
        address keyAddress;
        uint256 holderBalance;
        bool isExcludedFromReward;
        uint lastselltime;
        bool isNoSellHolder;
        totalNoSellHoldersBalance = 0;

        for (uint256 i = 0; i < size ; i++) {
            keyAddress = _tokenHoldersAccounts[i];
            holderBalance = _tokenHoldersList[keyAddress].balance;
            isExcludedFromReward = get_IsExcludedFromRewardFromAddressTokenHolder(keyAddress);
            lastselltime = get_LastSellTransferTimeFromAddressTokenHolder(keyAddress);
            if (lastselltime == 0) isNoSellHolder = true;
            else isNoSellHolder = false;
            if(holderBalance != 0 && !isExcludedFromReward && isNoSellHolder) { // se un account è escluso dai reward non contribuisce al calcolo del balance totale degli holders
                totalNoSellHoldersBalance = totalNoSellHoldersBalance.add(holderBalance);
            }
        }
        return totalNoSellHoldersBalance;
    }

    function _contractReBalance (uint256 contractamountfees) private {
        // assegna al balance del contratto le reflections calcolate nell'ultima operazione di transfer o transferfrom, in tale calcolo deve comprendere anche le reflections del contratto stesso
        // Quindi nel balance del contratto saranno assorbite le seguenti voci:
        // somma delle refelctions da tutti gli holders (contratto compreso) + fees totali pagate solo al contratto (fromBuyFee + antiSellFee)
        address contractAddress = address(this);
        uint256 contractBalanceBefore = get_BalanceBeforeTransferFromAddressTokenHolder(contractAddress);
        uint256 newContractBalance = contractBalanceBefore.add(_totalReflectionsLastTransfer).add(contractamountfees);
        set_BalanceFromAddressTokenHolder(contractAddress, newContractBalance);
    }

    /////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////// funzioni da usare per il claim NFT /////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////

    function set_balanceNeededForClaim(uint256 balanceNeededforclaim) external onlyOwner {
        _balanceNeededForClaim = balanceNeededforclaim;
    }

    function get_balanceNeededForClaim() external view returns (uint256) {
        return _balanceNeededForClaim;
    }

    // verificala condizione 1 del claim ovvero se il saldo del balance è sufficiente
    function get_claimCheck1(address addr) external view returns (uint256, bool) {
        uint256 balanceneededforclaim = _balanceNeededForClaim;
        bool _check = false;
        if (balanceOf(addr) >= balanceneededforclaim) _check = true;
        else _check = false;
        return (balanceOf(addr), _check);
    }

    // verificala condizione 2 del claim ovvero se è passato un certo periodo (circa una settimana) dalla data di listing
    function get_claimCheck2() external view returns (uint[] memory, bool _check) {
        uint _now = block.timestamp;
        uint[] memory timeResult = new uint[](3);
        if (_now >= _claimNftDistributionTime) _check = true;
        else _check = false;
        for (uint i = 0; i<timeResult.length; i++) {timeResult[i] = get_RemainingTimeToNftClaim()[i];
        }
        return (timeResult, _check);
    }

    // verificala condizione 3 del claim ovvero se non si è mai venduto fino a quel momento
    function get_claimCheck3(address addr) external view returns (bool) {
        bool _check = false;
        uint _lastselltransaction = _tokenHoldersList[addr].lastSellTransferTime;
        if (_lastselltransaction == 0) _check = true;
        else _check = false;
        return (_check);
    }

    // verificala condizione 4 del claim ovvero se non si è mai fatto un claim
    function get_claimCheck4(address addr) external view returns (bool) {
        bool _check = false;
        uint _claimTime = _tokenHoldersList[addr].claimTime;
        if (_claimTime == 0) _check = true;
        else _check = false;
        return (_check);
    }


    /////////////////////////////////////////////////////////////////////////////////////////

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    receive() external payable {}
}