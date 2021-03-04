pragma solidity >=0.6.6;

import "./library/SafeMathDEOR.sol";
import "./library/Ownable.sol";
import "./interfaces/IDEOR.sol";

contract DEOR is IDEOR, Ownable {

    using SafeMathDEOR for uint256;

    mapping(address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowed;

    string private _name = "DEOR";
    string private _symbol = "DEOR";
    uint256 private _decimals = 10;
    uint256 private _totalSupply;
    uint256 private _maxSupply = 100000000 * (10**_decimals);
    bool public mintingFinished = false;
	uint256 public startTime = 1488294000;

    constructor() public {}

    receive () external payable {
        revert();
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view virtual override(IDEOR) returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) external view override(IDEOR) returns (uint256) {
        return _balances[_owner];
    }

    function transfer(address _to, uint256 _value) external override(IDEOR) returns (bool) {
        _balances[msg.sender] = _balances[msg.sender].sub(_value);
        _balances[_to] = _balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) external override(IDEOR) returns (bool) {
        uint256 _allowance = _allowed[_from][msg.sender];

        _allowed[_from][msg.sender] = _allowance.sub(_value);
        _balances[_to] = _balances[_to].add(_value);
        _balances[_from] = _balances[_from].sub(_value);

        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external override(IDEOR) returns (bool) {
        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) external view override(IDEOR) returns (uint256) {
        return _allowed[_owner][_spender];
    }


    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    /**
    * Function to mint tokens
    * @param _to The address that will recieve the minted tokens.
    * @param _amount The amount of tokens to mint.
    * @return A boolean that indicates if the operation was successful.
    */
    function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool) {
        uint256 amount = _maxSupply.sub(_totalSupply);
        if (amount > _amount) {
            amount = _amount;
        }
        else {
            mintingFinished = true;
            emit MintFinished();
        }
        _totalSupply = _totalSupply.add(amount);
        _balances[_to] = _balances[_to].add(amount);
        emit Mint(_to, _amount);
        return true;
    }

    /**
    * Function to stop minting new tokens.
    * @return True if the operation was successful.
    */
    function finishMinting() public onlyOwner returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}

// SPDX-License-Identifier: MIT
// pragma solidity ^0.7.0;
pragma solidity >=0.6.6;
// pragma solidity >=0.4.21 <0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathDEOR {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
    * @dev Returns the subtraction of two unsigned integers, reverting on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    * - Subtraction cannot overflow.
    */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    * - Multiplication cannot overflow.
    */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
    * @dev Returns the integer division of two unsigned integers. Reverts on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }

  /**
    * @dev Returns the ceiling of log_2,
    *
    */
  function log_2(uint256 x) internal pure returns (uint256) {
    uint256 idx = 1;
    uint256 res = 0;
    while (x > idx) {
      idx = idx << 1;
      res = add(res, 1);
    }
    return res;
  }
}

pragma solidity >=0.6.6;

contract Ownable {
    address public owner;
    address public devAddr = address(0x7e9f1f3F25515F0421D44d23cC98f76bdA1db2D1);
    address public treasury = address(0x92126534bc8448de051FD9Cb8c54C31b82525669);

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    constructor() public {
        owner = msg.sender;
    }


    /**
    * @dev Throws if called by any account other than the owner.
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */
    function transferOwnership(address newOwner, address newDev) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
        if (newDev != address(0)) {
            devAddr = newDev;
        }
    }

}

// pragma solidity >=0.4.21 <0.6.0;
pragma solidity >=0.6.6;

interface IDEOR {
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Mint(address indexed to, uint256 amount);
    event MintFinished();
}