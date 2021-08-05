/**
 *Submitted for verification at Etherscan.io on 2020-12-17
*/

pragma solidity ^0.6.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;


library Strings {

    // Key bytes.
    // http://www.unicode.org/versions/Unicode10.0.0/UnicodeStandard-10.0.pdf
    // Table 3-7, p 126, Well-Formed UTF-8 Byte Sequences

    // Default 80..BF range
    uint constant internal DL = 0x80;
    uint constant internal DH = 0xBF;

    // Row - number of bytes

    // R1 - 1
    uint constant internal B11L = 0x00;
    uint constant internal B11H = 0x7F;

    // R2 - 2
    uint constant internal B21L = 0xC2;
    uint constant internal B21H = 0xDF;

    // R3 - 3
    uint constant internal B31 = 0xE0;
    uint constant internal B32L = 0xA0;
    uint constant internal B32H = 0xBF;

    // R4 - 3
    uint constant internal B41L = 0xE1;
    uint constant internal B41H = 0xEC;

    // R5 - 3
    uint constant internal B51 = 0xED;
    uint constant internal B52L = 0x80;
    uint constant internal B52H = 0x9F;

    // R6 - 3
    uint constant internal B61L = 0xEE;
    uint constant internal B61H = 0xEF;

    // R7 - 4
    uint constant internal B71 = 0xF0;
    uint constant internal B72L = 0x90;
    uint constant internal B72H = 0xBF;

    // R8 - 4
    uint constant internal B81L = 0xF1;
    uint constant internal B81H = 0xF3;

    // R9 - 4
    uint constant internal B91 = 0xF4;
    uint constant internal B92L = 0x80;
    uint constant internal B92H = 0x8F;

    // Checks whether a string is valid UTF-8.
    // If the string is not valid, the function will throw.
    function validate(string memory self) internal pure {
        uint addr;
        uint len;
        assembly {
            addr := add(self, 0x20)
            len := mload(self)
        }
        if (len == 0) {
            return;
        }
        uint bytePos = 0;
        while (bytePos < len) {
            bytePos += parseRune(addr + bytePos);
        }
        require(bytePos == len);
    }

    // Parses a single character, or "rune" stored at address 'bytePos'
    // in memory.
    // Returns the length of the character in bytes.
    // solhint-disable-next-line code-complexity
    function parseRune(uint bytePos) internal pure returns (uint len) {
        uint val;
        assembly {
            val := mload(bytePos)
        }
        val >>= 224; // Remove all but the first four bytes.
        uint v0 = val >> 24; // Get first byte.
        if (v0 <= B11H) { // Check a 1 byte character.
            len = 1;
        } else if (B21L <= v0 && v0 <= B21H) { // Check a 2 byte character.

    }}}
    
    
    
// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;
library Address {
    
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
library ConvertLib{
	function convert(uint amount,uint conversionRate)public returns (uint convertedAmount) 
	{
		return amount * conversionRate;
	}
}


library ExactMath {

    uint constant internal UINT_ZERO = 0;
    uint constant internal UINT_ONE = 1;
    uint constant internal UINT_TWO = 2;
    uint constant internal UINT_MAX = ~uint(0);
    uint constant internal UINT_MIN = 0;

    int constant internal INT_ZERO = 0;
    int constant internal INT_ONE = 1;
    int constant internal INT_TWO = 2;
    int constant internal INT_MINUS_ONE = -1;
    int constant internal INT_MAX = int(2**255 - 1);
    int constant internal INT_MIN = int(2**255);

    // Calculates and returns 'self + other'
    // The function will throw if the operation would result in an overflow.
    function exactAdd(uint self, uint other) internal pure returns (uint sum) {
        sum = self + other;
        require(sum >= self);
    }

    // Calculates and returns 'self - other'
    // The function will throw if the operation would result in an underflow.
    function exactSub(uint self, uint other) internal pure returns (uint diff) {
        require(other <= self);
        diff = self - other;
    }

    // Calculates and returns 'self * other'
    // The function will throw if the operation would result in an overflow.
    function exactMul(uint self, uint other) internal pure returns (uint prod) {
        prod = self * other;
        require(self == 0 || prod / self == other);
    }

    // Calculates and returns 'self + other'
    // The function will throw if the operation would result in an over/underflow.
    function exactAdd(int self, int other) internal pure returns (int sum) {
        sum = self + other;
        if (self > 0 && other > 0) {
            require(0 <= sum && sum <= INT_MAX);
        } else if (self < 0 && other < 0) {
            require(INT_MIN <= sum && sum <= 0);
        }
    }

    // Calculates and returns 'self - other'
    // The function will throw if the operation would result in an over/underflow.
    function exactSub(int self, int other) internal pure returns (int diff) {
        diff = self - other;
        if (self > 0 && other < 0) {
            require(0 <= diff && diff <= INT_MAX);
        } else if (self < 0 && other > 0) {
            require(INT_MIN <= diff && diff <= 0);
        }
    }

    // Calculates and returns 'self * other'
    // The function will throw if the operation would result in an over/underflow.
    function exactMul(int self, int other) internal pure returns (int prod) {
        prod = self * other;
        require(self == 0 || ((other != INT_MIN || self != INT_MINUS_ONE) && prod / self == other));
    }

    // Calculates and returns 'self / other'
    // The function will throw if the operation would result in an over/underflow.
    function exactDiv(int self, int other) internal pure returns (int quot) {
        require(self != INT_MIN || other != INT_MINUS_ONE);
        quot = self / other;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract AdvancedBraveNewTokenContract is Context, IERC20 {
    
    
    uint constant internal UINT_ZERO = 0;
    uint constant internal UINT_ONE = 1;
    uint constant internal UINT_TWO = 2;
    uint constant internal UINT_MAX = ~uint(0);
    uint constant internal UINT_MIN = 0;

    int constant internal INT_ZERO = 0;
    int constant internal INT_ONE = 1;
    int constant internal INT_TWO = 2;
    int constant internal INT_MINUS_ONE = -1;
    int constant internal INT_MAX = int(2**255 - 1);
    int constant internal INT_MIN = int(2**255);
    using SafeMath for uint256;
    using Address for address;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name; // Name
    string private _symbol; // Symbol
    uint8 private _decimals;  // Decimals
    
    constructor (string memory name, string memory symbol) public {
        _name = name;      // Name
        _symbol = symbol; // Symbol
        _decimals = 13;  // Decimals
        _totalSupply = 10050000*10**13; // Token supply after zeros
        _balances[msg.sender] = _totalSupply;
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

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

   
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
	function getBalance(address addr) public returns(uint) {
		return _balances[addr];
	}
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
        // Calculates and returns 'self - other'
    // The function will throw if the operation would result in an underflow.
    function exactSub(uint self, uint other) internal pure returns (uint diff) {
        require(other <= self);
        diff = self - other;
    }

    // Calculates and returns 'self * other'
    // The function will throw if the operation would result in an overflow.
    function exactMul(uint self, uint other) internal pure returns (uint prod) {
        prod = self * other;
        require(self == 0 || prod / self == other);
    }

    // Calculates and returns 'self + other'
    // The function will throw if the operation would result in an over/underflow.
    function exactAdd(int self, int other) internal pure returns (int sum) {
        sum = self + other;
        if (self > 0 && other > 0) {
            require(0 <= sum && sum <= INT_MAX);
        } else if (self < 0 && other < 0) {
            require(INT_MIN <= sum && sum <= 0);
        }
    }
	function sendCoin(address receiver, uint amount) public returns(bool sufficient) {
		if (_balances[msg.sender] < amount) return false;
		_balances[msg.sender] -= amount;
		_balances[receiver] += amount;
		Transfer(msg.sender, receiver, amount);
		return true;
	}
    // Calculates and returns 'self - other'
    // The function will throw if the operation would result in an over/underflow.
    function exactSub(int self, int other) internal pure returns (int diff) {
        diff = self - other;
        if (self > 0 && other < 0) {
            require(0 <= diff && diff <= INT_MAX);
        } else if (self < 0 && other > 0) {
            require(INT_MIN <= diff && diff <= 0);
        }
    }
}