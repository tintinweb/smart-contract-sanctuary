/**
 *Submitted for verification at BscScan.com on 2022-01-02
*/

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

library AddrArrayLib {
    using AddrArrayLib for Addresses;

    struct Addresses {
      address[]  _items;
    }

    function pushAddress(Addresses storage self, address element) internal {
      if (!exists(self, element)) {
        self._items.push(element);
      }
    }

    function removeAddress(Addresses storage self, address element) internal returns (bool) {
        for (uint i = 0; i < self.size(); i++) {
            if (self._items[i] == element) {
                self._items[i] = self._items[self.size() - 1];
                self._items.pop();
                return true;
            }
        }
        return false;
    }

    function getAddressAtIndex(Addresses storage self, uint256 index) internal view returns (address) {
        require(index < size(self), "the index is out of bounds");
        return self._items[index];
    }

    function size(Addresses storage self) internal view returns (uint256) {
      return self._items.length;
    }

    function exists(Addresses storage self, address element) internal view returns (bool) {
        for (uint i = 0; i < self.size(); i++) {
            if (self._items[i] == element) {
                return true;
            }
        }
        return false;
    }

    function getAllAddresses(Addresses storage self) internal view returns(address[] memory) {
        return self._items;
    }

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

// library DateTimeLibrary {
//
//     uint constant SECONDS_PER_DAY = 24 * 60 * 60;
//     uint constant SECONDS_PER_HOUR = 60 * 60;
//     uint constant SECONDS_PER_MINUTE = 60;
//     int constant OFFSET19700101 = 2440588;
//
//     uint constant DOW_MON = 1;
//     uint constant DOW_TUE = 2;
//     uint constant DOW_WED = 3;
//     uint constant DOW_THU = 4;
//     uint constant DOW_FRI = 5;
//     uint constant DOW_SAT = 6;
//     uint constant DOW_SUN = 7;
//
//     function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
//         require(year >= 1970);
//         int _year = int(year);
//         int _month = int(month);
//         int _day = int(day);
//
//         int __days = _day
//           - 32075
//           + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
//           + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
//           - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
//           - OFFSET19700101;
//
//         _days = uint(__days);
//     }
//
//     function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
//         int __days = int(_days);
//
//         int L = __days + 68569 + OFFSET19700101;
//         int N = 4 * L / 146097;
//         L = L - (146097 * N + 3) / 4;
//         int _year = 4000 * (L + 1) / 1461001;
//         L = L - 1461 * _year / 4 + 31;
//         int _month = 80 * L / 2447;
//         int _day = L - 2447 * _month / 80;
//         L = _month / 11;
//         _month = _month + 2 - 12 * L;
//         _year = 100 * (N - 49) + _year + L;
//
//         year = uint(_year);
//         month = uint(_month);
//         day = uint(_day);
//     }
//
//     function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
//         timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
//     }
//     function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
//         timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
//     }
//     function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
//         (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
//     }
//     function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
//         (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
//         uint secs = timestamp % SECONDS_PER_DAY;
//         hour = secs / SECONDS_PER_HOUR;
//         secs = secs % SECONDS_PER_HOUR;
//         minute = secs / SECONDS_PER_MINUTE;
//         second = secs % SECONDS_PER_MINUTE;
//     }
//
//     function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
//         if (year >= 1970 && month > 0 && month <= 12) {
//             uint daysInMonth = _getDaysInMonth(year, month);
//             if (day > 0 && day <= daysInMonth) {
//                 valid = true;
//             }
//         }
//     }
//     function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
//         if (isValidDate(year, month, day)) {
//             if (hour < 24 && minute < 60 && second < 60) {
//                 valid = true;
//             }
//         }
//     }
//     function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
//         uint year;
//         uint month;
//         uint day;
//         (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
//         leapYear = _isLeapYear(year);
//     }
//     function _isLeapYear(uint year) internal pure returns (bool leapYear) {
//         leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
//     }
//     function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
//         weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
//     }
//     function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
//         weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
//     }
//     function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
//         uint year;
//         uint month;
//         uint day;
//         (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
//         daysInMonth = _getDaysInMonth(year, month);
//     }
//     function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
//         if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
//             daysInMonth = 31;
//         } else if (month != 2) {
//             daysInMonth = 30;
//         } else {
//             daysInMonth = _isLeapYear(year) ? 29 : 28;
//         }
//     }
//     // 1 = Monday, 7 = Sunday
//     function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
//         uint _days = timestamp / SECONDS_PER_DAY;
//         dayOfWeek = (_days + 3) % 7 + 1;
//     }
//
//     function getYear(uint timestamp) internal pure returns (uint year) {
//         uint month;
//         uint day;
//         (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
//     }
//     function getMonth(uint timestamp) internal pure returns (uint month) {
//         uint year;
//         uint day;
//         (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
//     }
//     function getDay(uint timestamp) internal pure returns (uint day) {
//         uint year;
//         uint month;
//         (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
//     }
//     function getHour(uint timestamp) internal pure returns (uint hour) {
//         uint secs = timestamp % SECONDS_PER_DAY;
//         hour = secs / SECONDS_PER_HOUR;
//     }
//     function getMinute(uint timestamp) internal pure returns (uint minute) {
//         uint secs = timestamp % SECONDS_PER_HOUR;
//         minute = secs / SECONDS_PER_MINUTE;
//     }
//     function getSecond(uint timestamp) internal pure returns (uint second) {
//         second = timestamp % SECONDS_PER_MINUTE;
//     }
//
//     function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
//         uint year;
//         uint month;
//         uint day;
//         (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
//         year += _years;
//         uint daysInMonth = _getDaysInMonth(year, month);
//         if (day > daysInMonth) {
//             day = daysInMonth;
//         }
//         newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
//         require(newTimestamp >= timestamp);
//     }
//     function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
//         uint year;
//         uint month;
//         uint day;
//         (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
//         month += _months;
//         year += (month - 1) / 12;
//         month = (month - 1) % 12 + 1;
//         uint daysInMonth = _getDaysInMonth(year, month);
//         if (day > daysInMonth) {
//             day = daysInMonth;
//         }
//         newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
//         require(newTimestamp >= timestamp);
//     }
//     function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
//         newTimestamp = timestamp + _days * SECONDS_PER_DAY;
//         require(newTimestamp >= timestamp);
//     }
//     function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
//         newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
//         require(newTimestamp >= timestamp);
//     }
//     function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
//         newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
//         require(newTimestamp >= timestamp);
//     }
//     function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
//         newTimestamp = timestamp + _seconds;
//         require(newTimestamp >= timestamp);
//     }
//
//     function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
//         uint year;
//         uint month;
//         uint day;
//         (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
//         year -= _years;
//         uint daysInMonth = _getDaysInMonth(year, month);
//         if (day > daysInMonth) {
//             day = daysInMonth;
//         }
//         newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
//         require(newTimestamp <= timestamp);
//     }
//     function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
//         uint year;
//         uint month;
//         uint day;
//         (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
//         uint yearMonth = year * 12 + (month - 1) - _months;
//         year = yearMonth / 12;
//         month = yearMonth % 12 + 1;
//         uint daysInMonth = _getDaysInMonth(year, month);
//         if (day > daysInMonth) {
//             day = daysInMonth;
//         }
//         newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
//         require(newTimestamp <= timestamp);
//     }
//     function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
//         newTimestamp = timestamp - _days * SECONDS_PER_DAY;
//         require(newTimestamp <= timestamp);
//     }
//     function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
//         newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
//         require(newTimestamp <= timestamp);
//     }
//     function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
//         newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
//         require(newTimestamp <= timestamp);
//     }
//     function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
//         newTimestamp = timestamp - _seconds;
//         require(newTimestamp <= timestamp);
//     }
//
//     function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
//         require(fromTimestamp <= toTimestamp);
//         uint fromYear;
//         uint fromMonth;
//         uint fromDay;
//         uint toYear;
//         uint toMonth;
//         uint toDay;
//         (fromYear, fromMonth, fromDay) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
//         (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
//         _years = toYear - fromYear;
//     }
//     function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
//         require(fromTimestamp <= toTimestamp);
//         uint fromYear;
//         uint fromMonth;
//         uint fromDay;
//         uint toYear;
//         uint toMonth;
//         uint toDay;
//         (fromYear, fromMonth, fromDay) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
//         (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
//         _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
//     }
//     function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
//         require(fromTimestamp <= toTimestamp);
//         _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
//     }
//     function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
//         //require(fromTimestamp <= toTimestamp);
//         if (fromTimestamp <= toTimestamp) _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
//         else _hours = 0;
//     }
//     function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
//         //require(fromTimestamp <= toTimestamp);
//         if (fromTimestamp <= toTimestamp) _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
//         else _minutes = 0;
//     }
//     function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
//         //require(fromTimestamp <= toTimestamp);
//         if (fromTimestamp <= toTimestamp) _seconds = toTimestamp - fromTimestamp;
//         else _seconds = 0;
//     }
// }

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
    using AddrArrayLib for AddrArrayLib.Addresses;
    //using DateTimeLibrary for uint;

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
        uint firstBuyTransferTime;
        uint claimTime;
        bool inBlaclist;
        uint isLocked;
        //bool isBot;
        bool isExcludedFromTaxFee;
        bool isExcludedFromForBuyFee;
        bool isExcludedFromAntiSellFee;
        bool isExcludedFromReward;
        uint256 NFTPercentageMax;
    }
    mapping (address => tokenHolders) private _tokenHoldersList;
    address[] private _tokenHoldersAccounts;

    ///////////////////////////////////////////////////////////////////////////////////////
    ////////// struttura per registrazione attributes del token NFT ERC721 ////////////////
    ///////////////////////////////////////////////////////////////////////////////////////
    struct Attributes {
      string displayType;
      string traitTypes;
      uint256 values;
      uint256 maxValues;
    }
    struct Tokens {
        uint256 tokenId;
        string tokenuri;
        bool deleted; // quando è a true il token si considera cancellato ovvero spostato ad altro indirizzo
        // dimensione totale attributi
        uint256 attributeSize;
        mapping(uint256=>Attributes) attributes;
    }
    mapping(address => mapping(uint256=>Tokens)) tokenlist;

    // dimensione totale tokens
    mapping(address=>uint256) public tokenSize;

    event TokenMintError(address ownerToken, uint256 tokenid, string message); // evento emesso in caso di errore
    //event MintedToken(address ownerToken, uint256 tokenid, string tokenuri, uint256 attrSize,uint256 tokenSize);
    //event MintedAttributes(uint256 tokenId, string displayType, string traitType, uint256 value , uint256 maxValue);

    ///////////////////////////////////////////////////////////////////////////////////////

    mapping (address => mapping (address => uint256)) private _allowances;

    // List of gameDev addresses which can riceive reflections
    AddrArrayLib.Addresses gameDevAccounts;

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
    uint256 private _antiSellFeeTotal; // qui vengono accumulate le fee antiSell ed una volta distribuite tale variabile viene riportata a 0
    uint256 private _forBuyFeeTotal; // qui vengono accumulate le fee forBuy ed una volta distribuite tale variabile viene riportata a 0
    uint256 private _totalReflectionsLastTransfer; // somma delle rflexions dell'ultima transazione
    uint256 private _noSellHoldersReflectionsTotal; // questa variabile viene sempre aggiornata anche quando avviene la distribuzione1
    // che resetta le variabili che calcolano le reflections di tutti, in questo modo anche se la distrubuzione2 avviene dopo tante
    //distribuzioni di tipo 1 l'ammontare da distrubuire per la distribuzione2 viene mantenuto e non resettato con gli altri
    uint256 private _nftHoldersReflectionsTotal;// questa variabile viene sempre aggiornata anche quando avviene la distribuzione1
    // che resetta le variabili che calcolano le reflections di tutti, in questo modo anche se la distrubuzione3 avviene dopo tante
    //distribuzioni di tipo 1 l'ammontare da distrubuire per la distribuzione3 viene mantenuto e non resettato con gli altri

    uint256 public BNB_Balance;
    uint256 public WETH_Balance;

    bool private _tradingIsEnabled = true;
    bool private _isDistributionInWETHEnabled = true;
    bool private _inSwapAndLiquify;
    bool private _isGameDevActive = false;

    uint256 private amountMarketingToTranfer;
    uint256 private amountNftToTranfer;
    uint256 private amountTeamToTranfer;
    uint256 private amountTaxFeeToTranfer;
    uint256 private amountAntiSellToReflectToHoldersAddressToTranfer;
    uint256 private amountGameDevToTranfer;
    uint256 private amountGameDevToTranferForBuySide;
    uint256 private amountGameDevToTranferAntiSellSide;
    uint256 private amountGameDevToTranferReflectionsSide;

    uint256 private _maxTxAmount = 200_000_000e9; // Max transferrable in one transaction (0,2% of _tokenTotal)
    uint256 private _minTokensBeforeSwap = 200_000e9; // una volta accumulati questi token fa lo swap, se la singola massima transazione avviene ovviamente tale quota minima sarà di gran lunga superata e lo swap avverrà con una quota maggiore, cioè se maxAmont=200.000.000 e taxFee=5% swapperà 10.000.000 cioè 50 volte la quoota minima.
    uint256 private _minAmountPercentBeforeSwap = 20; // percentuale dell'amount che swapperà solo in transazioni transfer
    uint256 private _balanceOfMaxPermitted = 3_000_000_000e9; // massimo permesso nell'account di un holder, superato il quale viene posto in Locked List (3% del total amount)
    // trasformandoli in BNB mandandoli nel wallet buyBack, dovrebbe causare un crollo dello 0,04% della curva del prezzo

    address private _antiSellAddress; ///
    address private _marketingAddress; ///

    address private _presaleAddress; // indirizzo del contratto di presale cui autorizzare i trasferimenti con il router di PancakeSwap quando si crea il liquidity pool

    uint256 private _marketingWalletPercentOfForBuyFeeTotal = 71; // percentuale del _forBuyFeeTotal dedicata al marketing pari circa al 5% sul 7% totale
    uint256 private _gameDevWalletPercentOfForBuyFeeTotal = 28; // percentuale del _forBuyFeeTotal dedicata al gamedev pari circa al 2% sul 7% totale che sarà sottratta a _marketingWalletPercentOfForBuyFeeTotal in caso di _isGameDevActive == true
    uint256 private _nftWalletPercentOfForBuyFeeTotal;

    uint256 private _antiSellToReflectToHoldersWalletPercentOfAntiSellFeeTotal = 25; // percentuale del _antiSellFeeTotal inviata agli holders che non hanno mai venduto pari al 1,25% sul 5% totale (25% del totale)
    uint256 private _gameDevWalletPercentOfAntiSellFeeTotal = 20; // percentuale del _antiSellFeeTotal dedicata al gamedev pari circa al 1% sul 5% totale che sarà sottratta all'antiSell in caso di _isGameDevActive == true

    uint256 private _gameDevWalletPercentOfReflectionsFeeTotal = 20; // percentuale delle reflections dedicata al gamedev pari circa al 1% sul 5% totale che sarà sottratta alle reflections totali in caso di _isGameDevActive == true

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
    uint private _periodTime_3d = 259200; // 3 giorni = 86.400 blocchi
    uint private _periodTime_1W = 604800; // 1 settimana = 201.600 blocchi
    uint private _periodTime_1M = 2592000; // 1 mese = 864.000 blocchi
    uint private _periodTime_3M = 7776000; // 3 mesi = 2.592.000 blocchi
    uint private _periodTime_6M = 15552000; // 6 mesi = 5.184.000 blocchi
    uint private _periodTime_1Y = 31104000; // 1 anno = 10.368.000 blocchi

    uint private _epoch_1 = _periodTime_30m; // periodo di distribuzione reward in WETH a holders normali e wallet team
    uint private _epoch_2 = _periodTime_4h; // periodo di distribuzione reward in WETH a holders che non hanno mai venduto
    uint private _epoch_3 = _periodTime_1W; // periodo di distribuzione reward in WETH a holders che hanno NFT
    uint private _periodFromListingToClaimNft = _periodTime_1W; // tempo che passa dal listing al momento in cui sdi potrà fare il claim NFT
    uint private _periodFromFirstBuyToClaimNft = _periodTime_3d; // periodo di tempo che deve passare dal primo buy per poter superare il check5 del claim dell'NFT

    uint private _nextDistributionTime_1; // orario di start della prossima distribuzione 1 a holders normali e wallet team
    uint private _nextDistributionTime_2; // orario di start della prossima distribuzione 2 a holders che non hanno mai venduto
    uint private _nextDistributionTime_3; // orario di start della prossima distribuzione 3 a holders che hanno NFT
    uint private _fromListingToClaimNftDistributionTime; // orario di start per la distribuzione del claim NFT dopo il listing
    uint private _fromFirstBuyToClaimNftDistributionTime; // orario di start per la distribuzione del claim NFT dopo il primo buy

    bool private _isDistribution_1_Enabled = true; // attiva o meno tale distribuzione 1 a holders normali e wallet team
    bool private _isDistribution_2_Enabled = true; // attiva o meno tale distribuzione 2 a holders che non hanno mai venduto
    bool private _isDistribution_3_Enabled = true; // attiva o meno tale distribuzione 3 a holders che hanno NFT
    bool private _isClaim_Enabled = true; // attiva o meno il claim

    uint256 private _balanceNeededForClaim;

    //bool private _antiBotMode = false;
    bool private _lockedListMode = false;
    //uint256 private _maxGWeiPermitted = 12000000000; // 8 GWei

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    ///////////// Token's contract addressess BSC Mainnet///////////////////
    // address public constant WETH_BinanceToken = 0x2170Ed0880ac9A755fd29B2688956BD959F933F8;
    // address public constant USDC_BinanceToken = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;
    // address public constant BUSD_BinanceToken = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    // address public constant Cake = 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82;
    // address public constant USDT_BinanceToken = 0x55d398326f99059fF775485246999027B3197955;

    ///////////// Token's contract addressess BSC Testnet ///////////////////
    address private constant WETH_BinanceToken = 0x8BaBbB98678facC7342735486C851ABD7A0d17Ca;
    //address public constant BUSD_BinanceToken = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;
    //address public constant USDT_BinanceToken = 0x7ef95a0fee0dd31b22626fa2e10ee6a223f8a684;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped,uint256 ethReceived, uint256 tokensIntoLiqudity);
    //event antiBotActivated(address bot, uint256 gWeiPaid);
    event SwapAndDistribute(address indexed sender, address indexed recipient, uint256 amount);

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
        _tokenHoldersList[_msgSender()].firstBuyTransferTime = 0;
        _tokenHoldersList[_msgSender()].claimTime = 0;
        _tokenHoldersList[_msgSender()].inBlaclist = false;
        _tokenHoldersList[_msgSender()].isLocked = 2;
        //_tokenHoldersList[_msgSender()].isBot = false;
        _tokenHoldersList[_msgSender()].isExcludedFromTaxFee = true;
        _tokenHoldersList[_msgSender()].isExcludedFromForBuyFee = true;
        _tokenHoldersList[_msgSender()].isExcludedFromAntiSellFee = true;
        _tokenHoldersList[_msgSender()].isExcludedFromReward = false;
        _tokenHoldersList[_msgSender()].NFTPercentageMax = 0;
        _tokenHoldersAccounts.push(_msgSender());

        // inerisce address(this), cioè il contratto, tra gli holders
        _tokenHoldersList[address(this)].inserted = true;
        _tokenHoldersList[address(this)].balanceBeforeTransfer = 0;
        _tokenHoldersList[address(this)].balance = 0;
        _tokenHoldersList[address(this)].reflectionsForTransfer = 0;
        _tokenHoldersList[address(this)].reflectionsAccumulated = 0;
        _tokenHoldersList[address(this)].lastSellTransferTime = 0;
        _tokenHoldersList[address(this)].firstBuyTransferTime = 0;
        _tokenHoldersList[address(this)].claimTime = 0;
        _tokenHoldersList[address(this)].inBlaclist = false;
        _tokenHoldersList[address(this)].isLocked = 2;
        //_tokenHoldersList[address(this)].isBot = false;
        _tokenHoldersList[address(this)].isExcludedFromTaxFee = true;
        _tokenHoldersList[address(this)].isExcludedFromForBuyFee = true;
        _tokenHoldersList[address(this)].isExcludedFromAntiSellFee = true;
        _tokenHoldersList[address(this)].isExcludedFromReward = false;
        _tokenHoldersList[address(this)].NFTPercentageMax = 0;
        _tokenHoldersAccounts.push(address(this));

        // inerisce il pair di PancakeSwap
        _tokenHoldersList[uniswapV2Pair].inserted = true;
        _tokenHoldersList[uniswapV2Pair].balanceBeforeTransfer = 0;
        _tokenHoldersList[uniswapV2Pair].balance = 0;
        _tokenHoldersList[uniswapV2Pair].reflectionsForTransfer = 0;
        _tokenHoldersList[uniswapV2Pair].reflectionsAccumulated = 0;
        _tokenHoldersList[uniswapV2Pair].lastSellTransferTime = 0;
        _tokenHoldersList[uniswapV2Pair].firstBuyTransferTime = 0;
        _tokenHoldersList[uniswapV2Pair].claimTime = 0;
        _tokenHoldersList[uniswapV2Pair].inBlaclist = false;
        _tokenHoldersList[uniswapV2Pair].isLocked = 2;
        //_tokenHoldersList[uniswapV2Pair].isBot = false;
        _tokenHoldersList[uniswapV2Pair].isExcludedFromTaxFee = false;
        _tokenHoldersList[uniswapV2Pair].isExcludedFromForBuyFee = false;
        _tokenHoldersList[uniswapV2Pair].isExcludedFromAntiSellFee = false;
        _tokenHoldersList[uniswapV2Pair].isExcludedFromReward = true;
        _tokenHoldersList[uniswapV2Pair].NFTPercentageMax = 0;
        _tokenHoldersAccounts.push(uniswapV2Pair);

        emit Transfer(address(0), _msgSender(), _tokenTotal);
    }

    // function mint(address _account, uint256 _amount) public onlyOwner returns (bool) {
    //     require(_account != address(0), "BEP20: mint to the zero address");
    //     _tokenTotal = _tokenTotal.add(_amount);
    //     _tokenHoldersList[_account].balance.add(_amount);
    //     emit Transfer(address(0), _account, _amount);
    //     return true;
    // }

    function burn(address _account, uint256 _amount) public onlyOwner returns (bool) {
        require(_account != address(0), "BEP20: burn from the zero address");
        require(_tokenTotal >= _amount, "BEP20: total supply must be >= amout");
        _tokenTotal = _tokenTotal.sub(_amount);
        require(_tokenHoldersList[_account].balance >= _amount, "BEP20: the balance of account must be >= of amount");
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

    function get_AntiSellAddress() external view returns (address) {
        return _antiSellAddress;
    }

    function get_MarketingAddress() external view returns (address) {
        return _marketingAddress;
    }

    function get_PresaleAddress() external view returns (address) {
        return _presaleAddress;
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

    function get_maxTXAmountPerTransfer() private view returns (uint256) {
        return _maxTxAmount;
    }

    function get_AntiSellAutoFromOracle() private view returns (bool) {
        return _autoMode;
    }

    function get_antiSellFeeFromOracle() external view returns (uint256) {
        return _antiSellFeeFromOracle;
    }

    function set_antiSellFeeFromOracle(uint256 antiSellFeeFromOracle) external onlyOwner returns (uint256) {
        _antiSellFeeFromOracle = antiSellFeeFromOracle;
        return _antiSellFeeFromOracle;
    }

    function get_MarketingWalletPercentOfForBuyFeeTotal() external view returns (uint256) {
        return _marketingWalletPercentOfForBuyFeeTotal;
    }

    function get_GameDevWalletPercentOfForBuyFeeTotal() external view onlyOwner returns (uint256) {
        return _gameDevWalletPercentOfForBuyFeeTotal;
    }

    function get_GameDevWalletPercentOfAntiSellFeeTotal() private view returns (uint256) {
        return _gameDevWalletPercentOfAntiSellFeeTotal;
    }

    function get_GameDevWalletPercentOfReflectionsFeeTotal() private view returns (uint256) {
        return _gameDevWalletPercentOfReflectionsFeeTotal;
    }

    function get_antiSellToReflectToHoldersWalletPercentOfAntiSellFeeTotal() external view returns (uint256) {
        return _antiSellToReflectToHoldersWalletPercentOfAntiSellFeeTotal;
    }

    function get_AmountMarketingToTranfer() external view onlyOwner returns (uint256) {
        return amountMarketingToTranfer;
    }

    function get_AmountNftToTranfer() external view onlyOwner returns (uint256) {
        return amountNftToTranfer;
    }

    function get_AmountTeamToTranfer() external view onlyOwner returns (uint256) {
        return amountTeamToTranfer;
    }

    function get_AmountTaxFeeToTranfer() external view onlyOwner returns (uint256) {
        return amountTaxFeeToTranfer;
    }

    function get_AmountAntiSellToReflectToHoldersAddressToTranfer() external view onlyOwner returns (uint256) {
        return amountAntiSellToReflectToHoldersAddressToTranfer;
    }

    function get_AmountGameDevToTranfer() external view onlyOwner returns (uint256) {
        return amountGameDevToTranfer;
    }

    function balanceOf(address addr) public view override returns (uint256) {
        return _tokenHoldersList[addr].balance;
    }

    function set_PresaleParameters (
        address presaleaddress, // l'indirizzo del contratto di presale assegnato da PinkSale
        address marketingaddress,
        address antiselladdress

    ) external onlyOwner {
        removeTaxFee();
        removeForBuyFee();
        removeAntiSellFee();
        set_AntiSellAutoFromOracle(false); // settare a false
        set_MaxTxPerThousand(1000); // settare a 1000
        set_TradingIsEnabled(false);
        set_DistributionInWETHEnabled(false);
        set_LockedListMode(false);
        set_IsDistributionEnabled(false,false,false);
        set_IsClaim_Enabled(false);
        changeMarketingAddress(marketingaddress);
        changeAntiSellAddress(antiselladdress);
        changePresaleAddress(presaleaddress);
    }

    function set_PancakeSwapParameters (
        uint256 _MaxTXPerThousand,
        bool _antiSellAutoFromOracle,
        bool _enableTrading,
        bool _enableDistributionInWETH,
        uint periodfromlistingtoclaimnft,
        uint periodfromfirstbuytoclaimnft,
        bool lockedListMode,
        bool isdistribution1enabled,
        bool isdistribution2enabled,
        bool isdistribution3enabled,
        bool isclaimenabled

    ) external onlyOwner {
        restoreTaxFee();
        restoreForBuyFee();
        restoreAntiSellFee();
        set_AntiSellAutoFromOracle(_antiSellAutoFromOracle); // settare a true
        set_MaxTxPerThousand(_MaxTXPerThousand); // settare a 2
        set_TradingIsEnabled(_enableTrading); // mettere a true se si vuole permettere il trading da subito
        set_DistributionInWETHEnabled(_enableDistributionInWETH); // mettere a true se si vuole swappare ed inviare reflections
        //set_AntiBotMode(true);
        set_LockedListMode(lockedListMode);
        set_Epoch(1,_epoch_1);
        set_Epoch(2,_epoch_2);
        set_Epoch(3,_epoch_3);
        set_PeriodFromListingToClaimNft(periodfromlistingtoclaimnft);
        set_PeriodFromFirstBuyToClaimNft(periodfromfirstbuytoclaimnft);
        set_NextDistributionTime(1);
        set_NextDistributionTime(2);
        set_NextDistributionTime(3);
        set_FromListingToClaimNftDistributionTime();
        set_FromFirstBuyToClaimNftDistributionTime();
        set_IsDistributionEnabled(isdistribution1enabled,isdistribution2enabled,isdistribution3enabled);
        set_IsClaim_Enabled(isclaimenabled);
    }

    function randomNumber() private view returns(uint256) {
        uint256 seed = uint256(keccak256(abi.encodePacked(block.timestamp.add(block.difficulty).add(block.gaslimit).add((uint256(keccak256(abi.encodePacked(msg.sender)))).div(block.timestamp)).add(block.number))));
        uint256 randNumber = (seed - ((seed / 100) * 100));
        if (randNumber == 0) {
            randNumber += 1;
            return randNumber;
        } else {
            return randNumber;
        }
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        return _transfer(_msgSender(), recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BNB20: transfer amount exceeds allowance"));
        return _transfer2(sender, recipient, amount);
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

    function calculateTaxFeeTotal() private view returns (uint256) {
        return _taxFeeTotal;
    }

    function calculateForBuyFeeTotal() private view returns (uint256) {
        return _forBuyFeeTotal;
    }

    function calculateAntiSellFeeTotal() private view returns (uint256) {
        return _antiSellFeeTotal;
    }

    function set_AntiSellAutoFromOracle(bool autoMode) public onlyOwner {
        _autoMode = autoMode;
    }

    // function set_AntiBotMode(bool antiBotMode) public onlyOwner {
    //     _antiBotMode = antiBotMode;
    // }
    //
    // function get_AntiBotMode() private view returns (bool) {
    //     return _antiBotMode;
    // }

    function set_LockedListMode(bool lockedListMode) public onlyOwner {
         _lockedListMode = lockedListMode;
     }

    function get_LockedListMode() private view returns (bool) {
       return _lockedListMode;
    }

    function set_MaxTxPerThousand(uint256 maxTxThousand) public onlyOwner { // expressed in per thousand and not in percent
        _maxTxAmount = _tokenTotal.mul(maxTxThousand).div(10**3);
    }

    function get_Epoch(uint set) private view returns (uint) {
        // set = 1 -> distribuzione reward in WETH a holders normali e wallet team
        // set = 2 -> distribuzione reward in WETH a holders che non hanno mai venduto
        // set = 3 -> distribuzione reward in WETH a holders che hanno NFT
        if (set == 1) return _epoch_1;
        else if (set == 2) return _epoch_2;
        else if (set == 3) return _epoch_3;
        else return 0;
    }

    function set_Epoch(uint set, uint epochPeriod) public onlyOwner returns (bool) {
        // set = 1 -> distribuzione reward in WETH a holders normali e wallet team
        // set = 2 -> distribuzione reward in WETH a holders che non hanno mai venduto
        // set = 3 -> distribuzione reward in WETH a holders che hanno NFT
        if (set == 1) {
            _epoch_1 = epochPeriod;
            return true;
        }
        else if (set == 2) {
            _epoch_2 = epochPeriod;
            return true;
        }
        else if (set == 3) {
            _epoch_3 = epochPeriod;
            return true;
        }
        else return false;
    }

    function set_PeriodFromListingToClaimNft(uint period) public onlyOwner returns (bool) {
        _periodFromListingToClaimNft = period;
        return true;
    }

    function get_PeriodFromListingToClaimNft() private view returns (uint) {
        return _periodFromListingToClaimNft;
    }

    function set_PeriodFromFirstBuyToClaimNft(uint period) public onlyOwner returns (bool) {
        _periodFromFirstBuyToClaimNft = period;
        return true;
    }

    function get_PeriodFromFirstBuyToClaimNft() private view returns (uint) {
        return _periodFromFirstBuyToClaimNft;
    }

    function set_NextDistributionTime (uint set) public onlyOwner returns (bool) {
        // set = 1 -> distribuzione reward in WETH a holders normali e wallet team
        // set = 2 -> distribuzione reward in WETH a holders che non hanno mai venduto
        // set = 3 -> distribuzione reward in WETH a holders che hanno NFT
        if (set == 1) {
            _nextDistributionTime_1 = block.timestamp.add(_epoch_1);
            return true;
        }
        else if (set == 2) {
            _nextDistributionTime_2 = block.timestamp.add(_epoch_2);
            return true;
        }
        else if (set == 3) {
            _nextDistributionTime_3 = block.timestamp.add(_epoch_3);
            return true;
        }
        else return false;
    }

    function get_NextDistributionTime (uint set) public view returns (uint) {
        // set = 1 -> distribuzione reward in WETH a holders normali e wallet team
        // set = 2 -> distribuzione reward in WETH a holders che non hanno mai venduto
        // set = 3 -> distribuzione reward in WETH a holders che hanno NFT
        if (set == 1) return _nextDistributionTime_1;
        else if (set == 2) return _nextDistributionTime_2;
        else if (set == 3) return _nextDistributionTime_3;
        else return 0;
    }

    function set_FromListingToClaimNftDistributionTime () public onlyOwner returns (bool) {
        _fromListingToClaimNftDistributionTime = block.timestamp.add(_periodFromListingToClaimNft);
        return true;
    }

    function get_FromListingToClaimNftDistributionTime () external view returns (uint) {
        return _fromListingToClaimNftDistributionTime;
    }

    function set_FromFirstBuyToClaimNftDistributionTime () public onlyOwner returns (bool) {
        _fromFirstBuyToClaimNftDistributionTime = block.timestamp.add(_periodFromFirstBuyToClaimNft);
        return true;
    }

    function get_FromFirstBuyToClaimNftDistributionTime () external view returns (uint) {
        return _fromFirstBuyToClaimNftDistributionTime;
    }

    // function get_RemainingTimeToNextDistribution(uint set) public view returns (uint[] memory) {
    //     // set = 1 -> distribuzione reward in WETH a holders normali e wallet team
    //     // set = 2 -> distribuzione reward in WETH a holders che non hanno mai venduto
    //     // set = 3 -> distribuzione reward in WETH a holders che hanno NFT
    //     uint[] memory remainingtime = new uint[](3);
    //     uint _hoursTotal = DateTimeLibrary.diffHours(block.timestamp, get_NextDistributionTime(set));
    //     uint _minutesTotal = DateTimeLibrary.diffMinutes(block.timestamp, get_NextDistributionTime(set));
    //     uint _secondsTotal = DateTimeLibrary.diffSeconds(block.timestamp, get_NextDistributionTime(set));
    //     uint _hoursInMinutes = _hoursTotal.mul(60);
    //     uint _hoursInSeconds = _hoursTotal.mul(3600);
    //     uint _minutes;
    //     uint _minutesInSeconds;
    //     uint _seconds;
    //     if (_hoursTotal != 0) _minutes = _minutesTotal.mod(_hoursInMinutes);
    //     else _minutes = _minutesTotal;
    //     _minutesInSeconds = _minutes.mul(60);
    //     if (_hoursInSeconds.add(_minutesInSeconds) != 0) _seconds = _secondsTotal.mod(_hoursInSeconds.add(_minutesInSeconds));
    //     else _seconds = _secondsTotal;
    //     remainingtime[0] = _hoursTotal;
    //     remainingtime[1] = _minutes;
    //     remainingtime[2] = _seconds;
    //     return remainingtime;
    // }
    //
    // function get_RemainingTimeFromListingToNftClaim() public view returns (uint[] memory) {
    //     uint[] memory remainingtime = new uint[](3);
    //     uint _hoursTotal = DateTimeLibrary.diffHours(block.timestamp, get_FromListingToClaimNftDistributionTime());
    //     uint _minutesTotal = DateTimeLibrary.diffMinutes(block.timestamp, get_FromListingToClaimNftDistributionTime());
    //     uint _secondsTotal = DateTimeLibrary.diffSeconds(block.timestamp, get_FromListingToClaimNftDistributionTime());
    //     uint _hoursInMinutes = _hoursTotal.mul(60);
    //     uint _hoursInSeconds = _hoursTotal.mul(3600);
    //     uint _minutes;
    //     uint _minutesInSeconds;
    //     uint _seconds;
    //     if (_hoursTotal != 0) _minutes = _minutesTotal.mod(_hoursInMinutes);
    //     else _minutes = _minutesTotal;
    //     _minutesInSeconds = _minutes.mul(60);
    //     if (_hoursInSeconds.add(_minutesInSeconds) != 0) _seconds = _secondsTotal.mod(_hoursInSeconds.add(_minutesInSeconds));
    //     else _seconds = _secondsTotal;
    //     remainingtime[0] = _hoursTotal;
    //     remainingtime[1] = _minutes;
    //     remainingtime[2] = _seconds;
    //     return remainingtime;
    // }
    //
    // function get_RemainingTimeFromFirstBuyToNftClaim() public view returns (uint[] memory) {
    //     uint[] memory remainingtime = new uint[](3);
    //     uint _hoursTotal = DateTimeLibrary.diffHours(block.timestamp, get_FromFirstBuyToClaimNftDistributionTime());
    //     uint _minutesTotal = DateTimeLibrary.diffMinutes(block.timestamp, get_FromFirstBuyToClaimNftDistributionTime());
    //     uint _secondsTotal = DateTimeLibrary.diffSeconds(block.timestamp, get_FromFirstBuyToClaimNftDistributionTime());
    //     uint _hoursInMinutes = _hoursTotal.mul(60);
    //     uint _hoursInSeconds = _hoursTotal.mul(3600);
    //     uint _minutes;
    //     uint _minutesInSeconds;
    //     uint _seconds;
    //     if (_hoursTotal != 0) _minutes = _minutesTotal.mod(_hoursInMinutes);
    //     else _minutes = _minutesTotal;
    //     _minutesInSeconds = _minutes.mul(60);
    //     if (_hoursInSeconds.add(_minutesInSeconds) != 0) _seconds = _secondsTotal.mod(_hoursInSeconds.add(_minutesInSeconds));
    //     else _seconds = _secondsTotal;
    //     remainingtime[0] = _hoursTotal;
    //     remainingtime[1] = _minutes;
    //     remainingtime[2] = _seconds;
    //     return remainingtime;
    // }

    function changeAntiSellAddress(address _newaddress) public onlyOwner {
        _antiSellAddress = _newaddress;
    }

    function changeMarketingAddress(address _newaddress) public onlyOwner {
        _marketingAddress = _newaddress;
    }

    function changePresaleAddress(address _newaddress) public onlyOwner {
        _presaleAddress = _newaddress;
    }

    function changeMarketingWalletPercentOfForBuyFeeTotal(uint256  _newpercent) public onlyOwner {
        _marketingWalletPercentOfForBuyFeeTotal = _newpercent;
    }

    function changeGameDevWalletPercentOfForBuyFeeTotal(uint256  _newpercent) public onlyOwner {
        _gameDevWalletPercentOfForBuyFeeTotal = _newpercent;
    }

    function changeGameDevWalletPercentOfAntiSellFeeTotal(uint256  _newpercent) public onlyOwner {
        _gameDevWalletPercentOfAntiSellFeeTotal = _newpercent;
    }

    function changeGameDevWalletPercentOfReflectionsFeeTotal(uint256  _newpercent) public onlyOwner {
        _gameDevWalletPercentOfReflectionsFeeTotal = _newpercent;
    }

    function changeAntiSellToReflectToHoldersWalletPercentOfForBuyFeeTotal(uint256  _newpercent) public onlyOwner {
     _antiSellToReflectToHoldersWalletPercentOfAntiSellFeeTotal = _newpercent;
    }

    function set_MinTokensBeforeSwap(uint256 amount) external onlyOwner {
        _minTokensBeforeSwap = amount;
    }

    function get_MinTokensBeforeSwap() private view returns (uint256) {
        return _minTokensBeforeSwap;
    }

    function set_MinAmountPercentBeforeSwap(uint256 amount) external onlyOwner {
        _minAmountPercentBeforeSwap = amount;
    }

    function get_MinAmountPercentBeforeSwap() private view returns (uint256) {
        return _minAmountPercentBeforeSwap;
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
        uint256 _marketingwallpercentdfforbuyfeetotal,
        uint256 _gamedevwalletpercentofforbuyfeetotal,
        uint256 _gamedevwalletpercentofantisellfeetotal,
        uint256 _antisellToreflecttoholderswalletpercentofantisellfeetotal,
        uint256 _gamedevwalletpercentofreflectionsfeetotal
        ) external onlyOwner {

        _marketingWalletPercentOfForBuyFeeTotal = _marketingwallpercentdfforbuyfeetotal;
        _gameDevWalletPercentOfForBuyFeeTotal = _gamedevwalletpercentofforbuyfeetotal;
        _gameDevWalletPercentOfAntiSellFeeTotal = _gamedevwalletpercentofantisellfeetotal;
        _antiSellToReflectToHoldersWalletPercentOfAntiSellFeeTotal = _antisellToreflecttoholderswalletpercentofantisellfeetotal;
        _gameDevWalletPercentOfReflectionsFeeTotal = _gamedevwalletpercentofreflectionsfeetotal;
    }

    function set_TradingIsEnabled(bool enabled) public onlyOwner {
        _tradingIsEnabled = enabled;
        emit SwapAndLiquifyEnabledUpdated(enabled);
    }

    // questa funzione per dare true, anche quando il trading è disabilitato, deve avere il router di pancakeswap incluso nella transazione e l'altro attore deve essere sempre il _presaleAddress
    // in modo da permettere transazioni anche con trading disabled solo se è coinvolto il router di PancakeSwap ed un address garantito (_presaleAddress).
    function get_TradingIsEnabled(address sender, address recipient) private view returns (bool) {
        if (sender == uniswapV2Pair && recipient == _presaleAddress) return true; // se il pair di pancakeswap è il sender ed il recipient è _presaleAddress, in questo caso abilita il trading anche se _tradingIsEnabled == false
        if (recipient == uniswapV2Pair && sender == _presaleAddress) return true; // se il pair di pancakeswap è il recipient ed il sender è = _presaleAddress, in questo caso abilita il trading anche se _tradingIsEnabled == false
        return _tradingIsEnabled;
    }

    function set_IsDistributionEnabled(bool enabled1, bool enabled2, bool enabled3) public onlyOwner {
        _isDistribution_1_Enabled = enabled1;
        _isDistribution_2_Enabled = enabled2;
        _isDistribution_3_Enabled = enabled3;
    }

    function get_IsDistributionEnabled(uint set) private view returns (bool) {
        if (set == 1) return _isDistribution_1_Enabled;
        else if (set == 2) return _isDistribution_2_Enabled;
        else if (set == 3) return _isDistribution_3_Enabled;
        return false;
    }

   function set_IsClaim_Enabled(bool enabled) public onlyOwner {
        _isClaim_Enabled = enabled;
    }

    function get_IsClaim_Enabled() private view returns (bool) {
        return _isClaim_Enabled;
    }

    function set_IsGameDevActive(bool activate) public onlyOwner {
        _isGameDevActive = activate;
    }

    function get_IsGameDevActive() private view returns (bool) {
        return _isGameDevActive;
    }

    function set_DistributionInWETHEnabled(bool enabled) public onlyOwner {
        _isDistributionInWETHEnabled = enabled;
    }

    function get_DistributionInWETHEnabled() private view returns (bool) {
        return _isDistributionInWETHEnabled;
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
    function _transfer (
        address sender,
        address recipient,
        uint256 amount
    ) private returns (bool) {
        require(sender != address(0), "BNB20: transfer from the zero address");
        require(recipient != address(0), "BNB20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(get_TradingIsEnabled(sender,recipient), "Trading disabled !");
        if(sender != owner() && recipient != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            require(get_InBlackListFromAddressTokenHolder(recipient) == false, "the recipient account is Black listed!");
            require(get_InBlackListFromAddressTokenHolder(sender) == false, "the sender account is Black listed!");

        if (_lockedListMode) { // impedisce agli utenti di fare trading se hanno raggiunto un alta percentuale di balance
            require(get_IsLockedFromAddressTokenHolder(recipient) != 1, "the recipient account is Locked! his balance over 3% of total amount");
            require(get_IsLockedFromAddressTokenHolder(sender) != 1, "the sender account is Locked! his balance over 3% of total amount");
        }

        // if (_antiBotMode) { // impedisce agli sniper di conprare dal pool, con GWei >= 8, normalmente pancakeswap permette Gwei = 4,5,6
        //     if(tx.gasprice >= _maxGWeiPermitted){
        //         set_IsBotFromAddressTokenHolder(recipient,true);
        //         emit antiBotActivated(recipient, tx.gasprice);
        //     }
        //     require(get_IsBotFromAddressTokenHolder(recipient) == false, "Bots are not welcome !");
        // }
        _tokenTransfer (sender, recipient, amount);
        return true;
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

        uint firstbuytime = block.timestamp;
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

        _UpdateTokenReflexionsToTokenHolders(taxfee, TotalTokenHoldersBalance()); // vengono solo registrate ma non distribuite realmente e quindi non presenti in balance
        _checkFirstBuy(recipient,firstbuytime);
        _contractReBalance(contractAmountFees);
        emit Transfer(sender, recipient, amount);
        emit SwapAndDistribute(sender, recipient, amount);
    }

/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////// funzione di transfer per il transferfrom ////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////

    //questa funzione è utilizzata praticamente per la vendita di token a pancakeswap, qui il sender è l'holder che vende ed il recipient è il PancakeSwapRouterV2
    function _transfer2(
        address sender,
        address recipient,
        uint256 amount
    ) private returns (bool) {
        require(sender != address(0), "BNB20: transfer from the zero address");
        require(recipient != address(0), "BNB20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(get_TradingIsEnabled(sender,recipient), "Trading disabled !");
        if(sender != owner() && recipient != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            require(get_InBlackListFromAddressTokenHolder(recipient) == false, "the recipient account is Black listed!");
            require(get_InBlackListFromAddressTokenHolder(sender) == false, "the sender account is Black listed!");

        if (_lockedListMode) { // impedisce agli utenti di fare trading se hanno raggiunto un alta percentuale di balance
            require(get_IsLockedFromAddressTokenHolder(recipient) != 1, "the recipient account is Locked! his balance over 3% of total amount");
            require(get_IsLockedFromAddressTokenHolder(sender) != 1, "the sender account is Locked! his balance over 3% of total amount");
        }

        // if (_antiBotMode) { // impedisce agli sniper di conprare dal pool, con GWei >= 8, normalmente pancakeswap permette Gwei = 4,5,6
        //     if(tx.gasprice >= _maxGWeiPermitted){
        //         set_IsBotFromAddressTokenHolder(sender,true);
        //         emit antiBotActivated(sender, tx.gasprice);
        //     }
        //     require(get_IsBotFromAddressTokenHolder(sender) == false, "Bots are not welcome !");
        // }
        _tokenTransfer2 (sender, recipient, amount);
        return true;
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

        _UpdateTokenReflexionsToTokenHolders(taxfee, TotalTokenHoldersBalance()); // vengono solo registrate ma non distribuite realmente e quindi non presenti in balance
        _set_LastSellTransferTimeFromAddressTokenHolder(sender,lastselltime);
        _contractReBalance(contractAmountFees);
        emit Transfer(sender, recipient, amount);
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///////////// funzioni per loswap dei token in BNB e la distribuzione ai vari wallet del team //////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////

    function swapAndDistribute(address contractAddress) public onlyOwner {
        uint256 balanceToSwapAndSend = balanceOf(contractAddress); // balanceToSwapAndSend lo setta al balance del contratto in quel momento
        bool overMinTokenBalance = balanceToSwapAndSend >= _minTokensBeforeSwap;
        // se il balance del contratto è maggiore del minimo consentito e maggiore procede a swappare
        if (balanceToSwapAndSend > _minTokensBeforeSwap) {
            if (!_inSwapAndLiquify && overMinTokenBalance && _tradingIsEnabled) {
                if (_isDistributionInWETHEnabled) {
                    _firstSwap(balanceToSwapAndSend,contractAddress);
                    if (BNB_Balance > 0) _secondSwap(BNB_Balance,contractAddress);
                    if (WETH_Balance > 0) {
                        _prepareDistributionWETHToMarketingAndNft(WETH_Balance,balanceToSwapAndSend);
                        _prepareDistributionWETHToAntiSell(WETH_Balance,balanceToSwapAndSend);
                        _prepareDistributionWETHToHolders(WETH_Balance,balanceToSwapAndSend);
                        _distributeWETH();
                        _resetReflectionsAccumulated();
                    }
                }
            }
        }
    }

    function _swapTokensForBNB(uint256 tokenAmount, address contractaddress) private {
        address[] memory path = new address[](2);
        path[0] = contractaddress;
        path[1] = uniswapV2Router.WETH();
        _approve(contractaddress, address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            contractaddress,
            block.timestamp
        );
    }

    function _swapBNBForWETH(uint256 BNBAmount, address contractaddress) private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = WETH_BinanceToken;
        _approve(contractaddress, address(WETH_BinanceToken), BNBAmount);
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: BNBAmount}(
            0,
            path,
            contractaddress,
            block.timestamp
        );
    }

    function _firstSwap(uint256 amount, address contractaddress) private lockTheSwap {
        // primo swap effettuato per trasformare una piccola porzione di tokens in BNB
        uint256 contractAddressBalance = get_BalanceFromAddressTokenHolder(contractaddress);
        uint256 newContractAddessBalance = contractAddressBalance.sub(amount);
        _swapTokensForBNB(amount,contractaddress);
        set_BalanceFromAddressTokenHolder(contractaddress,newContractAddessBalance);
        BNB_Balance = contractaddress.balance;
    }

    function _secondSwap(uint256 bnb_balance, address contractaddress) private lockTheSwap {
        //secondo swap effettuato per trasformare tutti i BNB precedentemente swappati in WETH
        _swapBNBForWETH(bnb_balance,contractaddress);
        WETH_Balance = IERC20(WETH_BinanceToken).balanceOf(contractaddress);
        BNB_Balance = 0;
    }

    function _prepareDistributionWETHToMarketingAndNft(uint256 weth_balance, uint256 amounttoswapandsend) private {
        if (_isGameDevActive) {
            // calcolo distribuzione WETH a marketing e NFT
            uint256 gameDevQuotaToSubtractFromMarketing = _gameDevWalletPercentOfForBuyFeeTotal; // 28 parti su 71, equivalenti al 40% di quello che prenderà il marketing, ovvero se per il marketing è previsto il 5% in realtà gli arriverà il 3% ed il 2% andra al gameDev
            uint256 gameDevQuotaToSubtractFromNft = _gameDevWalletPercentOfForBuyFeeTotal.div(2); // 14 parti su 29, equivalenti al 50% di quello che prenderà l'NFT, ovvero se per l'NFT è previsto il 2% in realtà gli arriverà l'1% e l'1% andra al gameDev
            uint256 gameDevTotalQuota = gameDevQuotaToSubtractFromMarketing.add(gameDevQuotaToSubtractFromNft);
            uint256 marketingQuoteOfForBuyTotalGameDevSubtracted =  _marketingWalletPercentOfForBuyFeeTotal.sub(gameDevQuotaToSubtractFromMarketing); // sottrae la quota per il gameDev (2% gameDev 3% rimane al marketing)

            uint256 marketingQuoteOfForBuyTotal = _forBuyFeeTotal.mul(marketingQuoteOfForBuyTotalGameDevSubtracted).div(100);
            uint256 gameDevQuoteOfForBuyTotal = _forBuyFeeTotal.mul(gameDevTotalQuota).div(100);
            uint256 nftQuoteOfForBuyTotal =  _forBuyFeeTotal.sub(marketingQuoteOfForBuyTotal).sub(gameDevQuoteOfForBuyTotal);

            amountMarketingToTranfer = marketingQuoteOfForBuyTotal.mul(weth_balance).div(amounttoswapandsend);
            amountNftToTranfer = nftQuoteOfForBuyTotal.mul(weth_balance).div(amounttoswapandsend);
            amountGameDevToTranferForBuySide = gameDevQuoteOfForBuyTotal.mul(weth_balance).div(amounttoswapandsend);
        }
        else {
            // calcolo distribuzione WETH a marketing e NFT
            uint256 marketingQuoteOfForBuyTotal = _forBuyFeeTotal.mul(_marketingWalletPercentOfForBuyFeeTotal).div(100);
            uint256 nftQuoteOfForBuyTotal =  _forBuyFeeTotal.sub(marketingQuoteOfForBuyTotal);

            amountMarketingToTranfer = marketingQuoteOfForBuyTotal.mul(weth_balance).div(amounttoswapandsend);
            amountNftToTranfer = nftQuoteOfForBuyTotal.mul(weth_balance).div(amounttoswapandsend);
        }
    }

    function _prepareDistributionWETHToAntiSell(uint256 weth_balance, uint256 amounttoswapandsend) private {
        if (_isGameDevActive) {
            // calcolo distribuzione WETH a antiSell
            uint256 gameDevQuotaToSubtractFromAntiSell = _gameDevWalletPercentOfAntiSellFeeTotal; // 20 parti su 100, equivalenti al 20% di quello andrà nell'antiSell, ovvero se per l'antiSell è previsto il 5% in realtà gli arriverà il 4% e l'1% andra al gameDev
            uint256 holdersQuotaToSubtractFromAntiSell = _antiSellToReflectToHoldersWalletPercentOfAntiSellFeeTotal; // 25 parti su 100, equivalenti al 25% di quello andrà nell'antiSell verrà ridistribuito tra gli holders che non hanno mai venduto, ovvero se per l'antiSell è previsto il 5% equivale all'1,25%

            uint256 gameDevQuotaOfAntiSellTotal = _antiSellFeeTotal.mul(gameDevQuotaToSubtractFromAntiSell).div(100);
            uint256 holdersQuotaOfAntiSellTotal = _antiSellFeeTotal.mul(holdersQuotaToSubtractFromAntiSell).div(100);
            uint256 teamQuotaOfAntiSellTotal =  _antiSellFeeTotal.sub(gameDevQuotaOfAntiSellTotal).sub(holdersQuotaOfAntiSellTotal);

            amountAntiSellToReflectToHoldersAddressToTranfer = holdersQuotaOfAntiSellTotal.mul(weth_balance).div(amounttoswapandsend);
            amountTeamToTranfer = teamQuotaOfAntiSellTotal.mul(weth_balance).div(amounttoswapandsend);
            amountGameDevToTranferAntiSellSide = gameDevQuotaOfAntiSellTotal.mul(weth_balance).div(amounttoswapandsend);
        }
        else {
            // calcolo distribuzione WETH a antiSell
            uint256 holdersQuotaOfAntiSellTotal = _antiSellFeeTotal.mul(_antiSellToReflectToHoldersWalletPercentOfAntiSellFeeTotal).div(100);
            uint256 teamQuotaOfAntiSellTotal =  _antiSellFeeTotal.sub(holdersQuotaOfAntiSellTotal);

            amountAntiSellToReflectToHoldersAddressToTranfer = holdersQuotaOfAntiSellTotal.mul(weth_balance).div(amounttoswapandsend);
            amountTeamToTranfer = teamQuotaOfAntiSellTotal.mul(weth_balance).div(amounttoswapandsend);
        }
    }

    function _prepareDistributionWETHToHolders(uint256 weth_balance, uint256 amounttoswapandsend) private {
        if (_isGameDevActive) {
            // calcolo distribuzione WETH delle reflections agli holders
            uint256 TotalTaxFeeToken = amounttoswapandsend.sub(_forBuyFeeTotal).sub(_antiSellFeeTotal);
            uint256 gameDevQuotaToSubtractFromReflections = _gameDevWalletPercentOfReflectionsFeeTotal; // 20 parti su 100, equivalenti al 20% di quello che tornerà in reflections, ovvero se per per le reflections è previsto il 5% in realtà gli arriverà il 4% e l'1% andra al gameDev

            uint256 gameDevQuotaOfReflectionsTotal = TotalTaxFeeToken.mul(gameDevQuotaToSubtractFromReflections).div(100);
            uint256 holdersQuotaOfReflectionsTotal = TotalTaxFeeToken.sub(gameDevQuotaOfReflectionsTotal);

            amountGameDevToTranferReflectionsSide = gameDevQuotaOfReflectionsTotal.mul(weth_balance).div(amounttoswapandsend);
            amountTaxFeeToTranfer = holdersQuotaOfReflectionsTotal.mul(weth_balance).div(amounttoswapandsend);
            amountGameDevToTranfer = amountGameDevToTranferForBuySide.add(amountGameDevToTranferAntiSellSide).add(amountGameDevToTranferReflectionsSide);
        }
        else {
            // calcolo distribuzione WETH delle reflections agli holders
            uint256 TotalTaxFeeToken = amounttoswapandsend.sub(_forBuyFeeTotal).sub(_antiSellFeeTotal);
            amountTaxFeeToTranfer = TotalTaxFeeToken.mul(weth_balance).div(amounttoswapandsend);
        }
    }

    function _distributeWETH() private {
        uint nextdistributiontime_1 = get_NextDistributionTime(1);
        uint nextdistributiontime_2 = get_NextDistributionTime(2);
        uint nextdistributiontime_3 = get_NextDistributionTime(3);

        if (block.timestamp >= nextdistributiontime_1 && _isDistribution_1_Enabled) {
            _distributeToMarketing(amountMarketingToTranfer);
            _distributeToAntiSell(amountTeamToTranfer);
            _distributeToAllHolders(amountTaxFeeToTranfer);
            if (_isGameDevActive) {
                _distributeToGameDev(amountGameDevToTranfer);
            }
            set_NextDistributionTime(1);
        }
        if (block.timestamp >= nextdistributiontime_2 && _isDistribution_2_Enabled) {
            if (_noSellHoldersReflectionsTotal == 0) _distributeToNoSellHolders(amountAntiSellToReflectToHoldersAddressToTranfer);
            else _distributeToNoSellHolders(_noSellHoldersReflectionsTotal);
            set_NextDistributionTime(2);
            // resetta la viariabile globale che conteggia gli accumuli di tale reflection per evitare che venga resettato il loro accumulo nella funzione _resetReflectionsAccumulated()
            _noSellHoldersReflectionsTotal = 0;
        }
        if (block.timestamp >= nextdistributiontime_3 && _isDistribution_3_Enabled) {
            if (_nftHoldersReflectionsTotal == 0) _distributeToNftHolders(amountNftToTranfer);
            else _distributeToNftHolders(_nftHoldersReflectionsTotal);
            set_NextDistributionTime(3);
            // resetta la viariabile globale che conteggia gli accumuli di tale reflection per evitare che venga resettato il loro accumulo nella funzione _resetReflectionsAccumulated()
            _nftHoldersReflectionsTotal = 0;
        }

    }

    function _distributeToAllHolders(uint256 tokenAmount) private {
        uint256 size = _tokenHoldersAccounts.length;
        address keyAddress;
        uint256 amountToSend;
        bool isExcludedFromReward;
        uint256 holderbalance;

        if (size>0) {
            for (uint256 i = 0; i < size ; i++) {
                keyAddress = _tokenHoldersAccounts[i];
                holderbalance = balanceOf(keyAddress);
                if (holderbalance > 0) {
                    amountToSend = holderbalance.mul(tokenAmount).div(TotalTokenHoldersBalance()); // calcola la porzione da inviare ad ogni holders
                    isExcludedFromReward = get_IsExcludedFromRewardFromAddressTokenHolder(keyAddress);
                    if (!isExcludedFromReward && tokenAmount>0) {
                        //require (msg.sender == owner(), "Only owner can withdraw funds");
                        require(tokenAmount <= WETH_Balance, "balance is too low");
                        IERC20(WETH_BinanceToken).transfer(keyAddress, amountToSend);
                    }
                }
            }
        }
    }

    function _distributeToNftHolders(uint256 tokenAmount) private {
        uint256 size = _tokenHoldersAccounts.length;
        address keyAddress;
        uint256 amountToSend;
        uint256 NFTpercentagemax;
        uint256 virtualBalance;
        uint256 virtualTotalNFTTokenHoldersBalance;
        bool isExcludedFromReward;
        uint256 holderbalance;

        if (size>0) {
            for (uint256 i = 0; i < size ; i++) {
                keyAddress = _tokenHoldersAccounts[i];
                NFTpercentagemax = get_AttributeValuesByDisplayTypesAndTraitType (keyAddress,"","Rarity");
                holderbalance = balanceOf(keyAddress);
                if (holderbalance > 0 && NFTpercentagemax > 0) {
                    set_NFTPercentageMaxFromAddressTokenHolder(keyAddress,NFTpercentagemax);
                    virtualBalance = holderbalance.add(holderbalance.mul(NFTpercentagemax).div(100));
                    virtualTotalNFTTokenHoldersBalance = TotalNFTTokenHoldersBalance().sub(holderbalance).add(virtualBalance);
                    amountToSend = virtualBalance.mul(tokenAmount).div(virtualTotalNFTTokenHoldersBalance); // calcola la porzione da inviare ad ogni holders che ha NFT nel wallet aggiungendo ai suoi token una porzione % data dalla carta
                    isExcludedFromReward = get_IsExcludedFromRewardFromAddressTokenHolder(keyAddress);
                    if (!isExcludedFromReward && tokenAmount>0) {
                        //require (msg.sender == owner(), "Only owner can withdraw funds");
                        require(tokenAmount <= WETH_Balance, "balance is too low");
                        IERC20(WETH_BinanceToken).transfer(keyAddress, amountToSend);
                    }
                }
            }
        }
    }

    function _distributeToNoSellHolders(uint256 tokenAmount) private {
        uint256 size = _tokenHoldersAccounts.length;
        address keyAddress;
        uint256 amountToSend;
        uint lastselltime;
        uint256 holderbalance;
        bool isExcludedFromReward;

        if (size>0) {
            for (uint256 i = 0; i < size ; i++) {
                keyAddress = _tokenHoldersAccounts[i];
                lastselltime = get_LastSellTransferTimeFromAddressTokenHolder(keyAddress);
                holderbalance = balanceOf(keyAddress);
                if (holderbalance > 0 && lastselltime == 0) {// non ha mai venduto
                    amountToSend = holderbalance.mul(tokenAmount).div(TotalNoSellTokenHoldersBalance()); // calcola la porzione da inviare ad ogni holders
                    if (!isExcludedFromReward && tokenAmount>0) {
                        //require (msg.sender == owner(), "Only owner can withdraw funds");
                        require(tokenAmount <= WETH_Balance, "balance is too low");
                        IERC20(WETH_BinanceToken).transfer(keyAddress, amountToSend);
                    }
                }
            }
        }
    }

    function _distributeToAntiSell(uint256 tokenAmount) private {
        if (tokenAmount>0) {
            //require (msg.sender == owner(), "Only owner can withdraw funds");
            require(tokenAmount <= WETH_Balance, "balance is too low");
            IERC20(WETH_BinanceToken).transfer(_antiSellAddress, tokenAmount);
        }
    }

    function _distributeToMarketing(uint256 tokenAmount) private {
        if (tokenAmount>0) {
            //require (msg.sender == owner(), "Only owner can withdraw funds");
            require(tokenAmount <= WETH_Balance, "balance is too low");
            IERC20(WETH_BinanceToken).transfer(_marketingAddress, tokenAmount);
        }
    }

    // distribuisce tra gli account gameDev in modo casuale tra il prezzo medio e +-40% dello stesso
    function _distributeToGameDev(uint256 tokenAmount) private {
        uint256 size = getSizeGameDevAccount();
        uint256 mediumAmountPerUser = tokenAmount.div(size);
        uint256 rangePrice = mediumAmountPerUser.mul(40).div(100); // oscillazione dal prezzo medio per +- 40% del prezzo medio stesso, se il prezzo medio è 5€ l'oscillazione è da 3,00 a 7,00, rangePrice = 2
        uint256 priceToSubtractFromMediumPrice;
        uint256 priceToAddToMediumPrice;
        address keyAddress;
        uint256 amountToSend;

        if (size>0 && tokenAmount>0) {
            for (uint256 i = 0; i < size ; i++) {
                keyAddress = getAddressAtIndexGameDevAccount(i);
                if (i.mod(2) == 0) {
                    // nel caso fossero elementi dispari l'ultimo elemento l,o assegna pieno
                    if (i == size.sub(1)) amountToSend = mediumAmountPerUser;
                    else {
                        priceToSubtractFromMediumPrice = rangePrice.mul(randomNumber()).div(100);
                        amountToSend = mediumAmountPerUser.sub(priceToSubtractFromMediumPrice);
                    }
                }
                else {
                    priceToAddToMediumPrice = priceToSubtractFromMediumPrice;
                    amountToSend = mediumAmountPerUser.add(priceToAddToMediumPrice);
                }
                //require (msg.sender == owner(), "Only owner can withdraw funds");
                require(amountToSend <= WETH_Balance, "balance is too low");
                IERC20(WETH_BinanceToken).transfer(keyAddress, amountToSend);
            }
        }
    }

    /////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////// funzioni del mapping TokenHolder /////////////////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////
    function get_BalanceBeforeTransferFromAddressTokenHolder(address addr) private view returns (uint256) {
        return _tokenHoldersList[addr].balanceBeforeTransfer;
    }

    function get_BalanceFromAddressTokenHolder(address addr) private view returns (uint256) {
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

    function get_LastSellTransferTimeFromAddressTokenHolder(address addr) private view returns (uint256) {
        return _tokenHoldersList[addr].lastSellTransferTime;
    }

    function _set_LastSellTransferTimeFromAddressTokenHolder(address addr, uint lastselltime) private {
        _tokenHoldersList[addr].lastSellTransferTime = lastselltime;
    }

    function get_FirstBuyTransferTimeFromAddressTokenHolder(address addr) private view returns (uint256) {
        return _tokenHoldersList[addr].firstBuyTransferTime;
    }

    function set_FirstBuyTransferTimeFromAddressTokenHolder(address addr, uint firstbuytime) private {
        _tokenHoldersList[addr].firstBuyTransferTime = firstbuytime;
    }

    function _checkFirstBuy(address addr, uint firstbuytime) private {
        uint firstbuytimefromaddresstokenholder = get_FirstBuyTransferTimeFromAddressTokenHolder(addr);
        if (firstbuytimefromaddresstokenholder == 0) set_FirstBuyTransferTimeFromAddressTokenHolder(addr,firstbuytime);
    }

    function get_ClaimTimeFromAddressTokenHolder(address addr) private view returns (uint256) {
        return _tokenHoldersList[addr].claimTime;
    }

    function get_InBlackListFromAddressTokenHolder(address addr) private view returns (bool) {
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

    function get_InsertedFromAddressTokenHolder(address addr) private view returns (bool) {
        return _tokenHoldersList[addr].inserted;
    }

    function set_NFTPercentageMaxFromAddressTokenHolder(address addr, uint256 value) private {
        _tokenHoldersList[addr].NFTPercentageMax = value;
    }

    function get_NFTPercentageMaxFromAddressTokenHolder(address addr) public view returns (uint256) {
        return _tokenHoldersList[addr].NFTPercentageMax;
    }

    // function set_IsBotFromAddressTokenHolder(address addr, bool value) public onlyOwner {
    //     _tokenHoldersList[addr].isBot = value;
    // }
    //
    // function get_IsBotFromAddressTokenHolder(address addr) public view returns (bool) {
    //     return _tokenHoldersList[addr].isBot;
    // }

    function set_IsExcludedFromTaxFeeFromAddressTokenHolder(address addr, bool value) public onlyOwner {
          _tokenHoldersList[addr].isExcludedFromTaxFee = value;
    }

    function get_IsExcludedFromTaxFeeFromAddressTokenHolder(address addr) private view returns (bool) {
        return _tokenHoldersList[addr].isExcludedFromTaxFee;
    }

    function set_IsExcludedFromForBuyFeeFromAddressTokenHolder(address addr, bool value) public onlyOwner {
          _tokenHoldersList[addr].isExcludedFromForBuyFee = value;
    }

    function get_IsExcludedFromForBuyFeeFromAddressTokenHolder(address addr) private view returns (bool) {
        return _tokenHoldersList[addr].isExcludedFromForBuyFee;
    }

    function set_IsExcludedFromAntiSellFeeFromAddressTokenHolder(address addr, bool value) public onlyOwner {
          _tokenHoldersList[addr].isExcludedFromAntiSellFee = value;
    }

    function get_IsExcludedFromAntiSellFeeFromAddressTokenHolder(address addr) private view returns (bool) {
        return _tokenHoldersList[addr].isExcludedFromAntiSellFee;
    }

    function set_IsExcludedFromRewardFromAddressTokenHolder(address addr, bool value) public onlyOwner {
          _tokenHoldersList[addr].isExcludedFromReward = value;
    }

    function get_IsExcludedFromRewardFromAddressTokenHolder(address addr) private view returns (bool) {
        return _tokenHoldersList[addr].isExcludedFromReward;
    }

    function get_SizeTokenHolder() private view returns (uint) {
        return _tokenHoldersAccounts.length;
    }

    function get_TokenHolderList() private view returns (address[] memory) {
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
            _tokenHoldersList[addr].firstBuyTransferTime = 0;
            _tokenHoldersList[addr].claimTime = 0;
            _tokenHoldersList[addr].inBlaclist = false;
            _tokenHoldersList[addr].isLocked = 0;
            //_tokenHoldersList[addr].isBot = false;
            _tokenHoldersList[addr].isExcludedFromTaxFee = false;
            _tokenHoldersList[addr].isExcludedFromForBuyFee = false;
            _tokenHoldersList[addr].isExcludedFromAntiSellFee = false;
            _tokenHoldersList[addr].isExcludedFromReward = false;
            _tokenHoldersList[addr].NFTPercentageMax = 0;
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
        if (size>0) {
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
    }

    function TotalTokenHoldersBalance() private view returns (uint256 totalHoldersBalance) {

        // setta i valori di tutti gli altri holder non updated
        uint256 size = _tokenHoldersAccounts.length;
        address keyAddress;
        uint256 holderBalance;
        bool isExcludedFromReward;
        totalHoldersBalance = 0;
        if (size>0) {
            for (uint256 i = 0; i < size ; i++) {
                keyAddress = _tokenHoldersAccounts[i];
                holderBalance = _tokenHoldersList[keyAddress].balance;
                isExcludedFromReward = get_IsExcludedFromRewardFromAddressTokenHolder(keyAddress);
                if(holderBalance != 0 && !isExcludedFromReward) { // se un account è escluso dai reward non contribuisce al calcolo del balance totale degli holders
                    totalHoldersBalance = totalHoldersBalance.add(holderBalance);
                }
            }
        }
        return totalHoldersBalance;
    }

    function TotalNFTTokenHoldersBalance() private view returns (uint256 totalNFTHoldersBalance) {

        // setta i valori di tutti gli altri holder non updated
        uint256 size = _tokenHoldersAccounts.length;
        address keyAddress;
        uint256 holderBalance;
        bool isExcludedFromReward;
        uint256 NFTpercentagemax;
        bool isNFTHolder;
        totalNFTHoldersBalance = 0;
        if (size>0) {
            for (uint256 i = 0; i < size ; i++) {
                keyAddress = _tokenHoldersAccounts[i];
                holderBalance = _tokenHoldersList[keyAddress].balance;
                isExcludedFromReward = get_IsExcludedFromRewardFromAddressTokenHolder(keyAddress);
                NFTpercentagemax = get_NFTPercentageMaxFromAddressTokenHolder(keyAddress);

                if (NFTpercentagemax > 0) {
                    isNFTHolder = true;
                }
                else isNFTHolder = false;
                if(holderBalance != 0 && !isExcludedFromReward && isNFTHolder) { // se un account è escluso dai reward non contribuisce al calcolo del balance totale degli holders
                    totalNFTHoldersBalance = totalNFTHoldersBalance.add(holderBalance);
                }
            }
        }
        return totalNFTHoldersBalance;
    }

    function TotalNoSellTokenHoldersBalance() private view returns (uint256 totalNoSellHoldersBalance) {

        // setta i valori di tutti gli altri holder non updated
        uint256 size = _tokenHoldersAccounts.length;
        address keyAddress;
        uint256 holderBalance;
        bool isExcludedFromReward;
        uint lastselltime;
        bool isNoSellHolder;
        totalNoSellHoldersBalance = 0;
        if (size>0) {
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

    // resetta tutte le reflections accumulate e sposta quelle relative agli holder NFT in una variabile globale per distribuirle in un secondo momento dato che abbiamo due epoche diverse di distribuzione
    function _resetReflectionsAccumulated () private {
        // azzera le reflections accumulate di tutti gli holders appena ha concluso il ciclo di distribuzione
        uint256 size = _tokenHoldersAccounts.length;
        address keyAddress;
        uint256 holderReflectionAccumulated;
        if (size>0) {
            for (uint256 i = 0; i < size ; i++) {
                keyAddress = _tokenHoldersAccounts[i];
                holderReflectionAccumulated = get_ReflectionsAccumulatedFromAddressTokenHolder(keyAddress);
                if (holderReflectionAccumulated > 0) set_ReflectionsAccumulatedFromAddressTokenHolder(keyAddress,0);
                _forBuyFeeTotal=0; // resetta la variabile globale che registra le tasse di forBuy
                _antiSellFeeTotal=0; // resetta la variabile globale che registra le tasse di antiSell
                _noSellHoldersReflectionsTotal = _noSellHoldersReflectionsTotal.add(amountAntiSellToReflectToHoldersAddressToTranfer); // aggiorna la variabile globale che tiene conto del totale raggiunto per questa reflection
                _nftHoldersReflectionsTotal = _nftHoldersReflectionsTotal.add(amountNftToTranfer); // aggiorna la variabile globale che tiene conto del totale raggiunto per questa reflection
            }
        }
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


    // verifica la condizione 0 del claim ovvero che il claim sia enabled
    function get_claimCheck0() external view returns (bool _check) {
        if (_isClaim_Enabled) _check = true;
        else _check = false;
        return (_check);
    }

    // verificala condizione 1 del claim ovvero se il saldo del balance è sufficiente
    function get_claimCheck1(address addr) external view returns (uint256, bool) {
        uint256 balanceneededforclaim = _balanceNeededForClaim;
        bool _check = false;
        if (balanceOf(addr) >= balanceneededforclaim) _check = true;
        else _check = false;
        return (balanceOf(addr), _check);
    }

    // verifica la condizione 2 del claim ovvero se è passato un certo periodo (circa una settimana) dalla data di listing
    function get_claimCheck2() external view returns (uint fromListingToClaimNftDistributionTime, bool _check) {
        uint _now = block.timestamp;
        if (_now >= _fromListingToClaimNftDistributionTime) _check = true;
        else _check = false;
        return (_fromListingToClaimNftDistributionTime, _check);
    }

    // verifica la condizione 3 del claim ovvero se non si è mai venduto fino a quel momento
    function get_claimCheck3(address addr) external view returns (bool _check) {
        uint _lastselltransaction = _tokenHoldersList[addr].lastSellTransferTime;
        if (_lastselltransaction == 0) _check = true;
        else _check = false;
        return (_check);
    }

    // verifica la condizione 4 del claim ovvero se non si è mai fatto un claim
    function get_claimCheck4(address addr) external view returns (bool _check) {
        uint _claimTime = _tokenHoldersList[addr].claimTime;
        if (_claimTime == 0) _check = true;
        else _check = false;
        return (_check);
    }

    // verifica la condizione 5 del claim ovvero la persona deve aver fatto il suo primo acquisto da almeno 6 giorni
    function get_claimCheck5() external view returns (uint fromFirstBuyToClaimNftDistributionTime, bool _check) {
        uint _now = block.timestamp;
        if (_now >= _fromFirstBuyToClaimNftDistributionTime) _check = true;
        else _check = false;
        return (_fromFirstBuyToClaimNftDistributionTime, _check);
    }

    /////////////////////////////////////////////////////////////////////////////////////////
    //////////////////////// Strutture per registrazione attributes NFT /////////////////////
    /////////////////////////////////////////////////////////////////////////////////////////
    //ritorna solo valori uint256256 prelevati dasl campo values, quindi è opportuno richiedere solo displaytype e traittype che conducano a values di tipo uint256
    function get_AttributeValuesByDisplayTypesAndTraitType (
        address userAddress,
        string memory displayTypeName,
        string memory traitTypeName
      ) private view returns (uint256) {

       uint256 dSize = tokenSize[userAddress];
       uint256 pushedValues=0;
       uint256[] memory values = new uint256[](dSize*20);
       // verifica se il sono presenti elementi
       if(dSize>0) {
            // cerca in tutti i tokens
            for(uint256 i=0; i<dSize; i++) {
                Tokens storage t = tokenlist[userAddress][i];
                // per ogni token leggi gli attributi
                uint256 attrSize = t.attributeSize;
                bool del = t.deleted;

                if(attrSize>0 && !del) {
                    // itera gli attributi per cercare i display types e i traitTypes
                    for(uint256 j =0; j<attrSize; j++){
                        // ottiene il display type dell'attributo j del token i
                        string memory dt = t.attributes[j].displayType;

                        // ottiene il trait type dell'attributo j del token i
                        string memory tp = t.attributes[j].traitTypes;

                        // ottiene il values dell'attributo j del token i
                        uint256 valuesData =  t.attributes[j].values;

                        // verifica la condizione se displatype corrisponde al valore passato e anche il trait type
                        if(keccak256(abi.encodePacked(dt)) == keccak256(abi.encodePacked(displayTypeName)) && keccak256(abi.encodePacked(tp)) == keccak256(abi.encodePacked(traitTypeName))) {
                            values[pushedValues] = valuesData;
                            pushedValues++;
                        }
                    }
                }
            }
        }
        // ridimensiona l'array ai soli valori necessari
        uint256 maxValue = values[0];
        for (uint256 j = 1; j < values.length; j++) {
            uint256 currentItem = values[j];
            uint256 prevItem = values[j-1];
            if(currentItem>prevItem){
                maxValue = currentItem;
            }
        }
        return maxValue;
    }

    // questa funzione carica direttamente la tabella presente nella pagina di "Mint NFT" nella struttura degli attributi dell'NFT
    function set_Attributes (
        address fromUserAddress,
        address toUserAddress,
        uint256 tokenid,
        string memory tokenuri,
        Attributes[] memory newAttributes
      ) public onlyOwner returns (bool) {

        uint256 dSize = tokenSize[toUserAddress];
        // verifica se il sono presenti elementi
        if(dSize>0) {
            // cerca in tutti i tokens
            for(uint256 i=0; i<dSize; i++) {
                Tokens storage tTo = tokenlist[toUserAddress][i];
                if (tTo.tokenId == tokenid) { // NFT già inserito in precedenza, resetta e sostituiscetutti gli attributi
                   emit TokenMintError(toUserAddress,tokenid,"Token already minted");
                    return false;
                }
            }
        }
        // non è uscito con return true vuol dire che non ha trovato il tokenId quindi lo aggiunge ed inserisce tutti i parametri passati dalla funzione
        pushTokens(toUserAddress,tokenid,tokenuri,newAttributes);

        // è un transfer di NFT da un utente ad un altro in quanto from è diverso da to
        if (fromUserAddress != toUserAddress) {
            uint256 fSize = tokenSize[fromUserAddress];
            // verifica se il sono presenti elementi
            if(fSize>0) {
                // cerca in tutti i tokens
                for(uint256 i=0; i<fSize; i++) {
                    Tokens storage tfrom = tokenlist[fromUserAddress][i];
                    if (tfrom.tokenId == tokenid) {
                        tfrom.deleted = true;
                    }
                }
            }
        }
        return true;
    }

    //forma l'item per passarlo alla funzione
    function pushTokens (
        address userAddress,
        uint256 tokenid,
        string memory tokenuri,
        Attributes[] memory newAttributes
        ) private {

        uint256 tSize = tokenSize[userAddress];
        // incrementa tokensize
        tokenlist[userAddress][tSize].tokenId= tokenid;
        tokenlist[userAddress][tSize].tokenuri= tokenuri;
        tokenlist[userAddress][tSize].deleted = false;

        // aggiungi gli attributi
        uint256 totalAttr = newAttributes.length;
        tokenlist[userAddress][tSize].attributeSize = totalAttr;

        for(uint256 i=0;i<totalAttr;i++){
            //Tokens storage tItem = tokenlist[userAddress][tSize];

            tokenlist[userAddress][tSize].attributes[i].displayType= newAttributes[i].displayType;
            tokenlist[userAddress][tSize].attributes[i].traitTypes =newAttributes[i].traitTypes;
            tokenlist[userAddress][tSize].attributes[i].values= newAttributes[i].values;
            tokenlist[userAddress][tSize].attributes[i].maxValues= newAttributes[i].maxValues;

            // emit MintedAttributes(tItem.tokenId,
            //     tItem.attributes[i].displayType,
            //     tItem.attributes[i].traitTypes,
            //     tItem.attributes[i].values,
            //     tItem.attributes[i].maxValues
            // );
        }
        //Tokens storage t = tokenlist[userAddress][tSize];
        tokenSize[userAddress]++;
        //emit MintedToken(userAddress,t.tokenId,t.tokenuri,t.attributeSize,tokenSize[userAddress]);
    }

    //////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////// funzioni per la gestione degli address GameDev ///////////////////////////
    //////////////////////////////////////////////////////////////////////////////////////////////
    function addGameDevAccount(address addr) public onlyOwner {
        gameDevAccounts.pushAddress(addr);
    }

    function removeGameDevAccount(address addr) public onlyOwner returns (bool){
        return gameDevAccounts.removeAddress(addr);
    }

    function existGameDevAccount(address addr) public onlyOwner view returns (bool){
        return gameDevAccounts.exists(addr);
    }

    function getAllGameDevAccount() internal view returns(address[] memory) {
        return gameDevAccounts._items;
    }

    function getSizeGameDevAccount() internal view returns (uint256) {
      return gameDevAccounts._items.length;
    }

    function getAddressAtIndexGameDevAccount(uint256 index) internal view returns (address) {
        return gameDevAccounts._items[index];
    }

    //////////////////////////////////////////////////////////////////////////////////////////////

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    receive() external payable {}
}