//SourceUnit: ComboSwap.sol

pragma solidity 0.6.0;

import "./ITRC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./TokenInfo.sol";

contract ComboSwap is Ownable, TokenInfo {

  using SafeMath for uint256;

  address private _collector;
  address private _sponsor;

  ITRC20 private tokenIN1;
  ITRC20 private tokenIN2;
  ITRC20 private tokenOUT;

  uint256 private baseIN1;
  uint256 private baseIN2;
  uint256 private baseOUT;

  constructor (
    address IN1_token, uint256 IN1_amount,
    address IN2_token, uint256 IN2_amount,
    address OUT_token, uint256 OUT_amount,
    address collector, address sponsor
  ) public {
    setParameters(
      IN1_token, IN1_amount, IN2_token, IN2_amount,
      OUT_token, OUT_amount, collector, sponsor
    );
  }

  event NewParameters(
    address IN1_token, uint256 IN1_amount,
    address IN2_token, uint256 IN2_amount,
    address OUT_token, uint256 OUT_amount,
    address collector, address sponsor
  );

  function setParameters (
    address IN1_token, uint256 IN1_amount,
    address IN2_token, uint256 IN2_amount,
    address OUT_token, uint256 OUT_amount,
    address collector, address sponsor
  ) public onlyOwner {
    if(IN1_token != address(0) && IN1_token != address(tokenIN1)) tokenIN1 = ITRC20(IN1_token);
    if(IN2_token != address(0) && IN2_token != address(tokenIN2)) tokenIN2 = ITRC20(IN2_token);
    if(OUT_token != address(0) && OUT_token != address(tokenOUT)) tokenOUT = ITRC20(OUT_token);

    if(IN1_amount > 0 && IN1_amount != baseIN1) baseIN1 = IN1_amount;
    if(IN2_amount > 0 && IN2_amount != baseIN2) baseIN2 = IN2_amount;
    if(OUT_amount > 0 && OUT_amount != baseOUT) baseOUT = OUT_amount;

    if(collector != address(0) && collector != _collector) _collector = collector;
    if(sponsor != address(0) && sponsor != _sponsor) _sponsor   = sponsor;

    emit NewParameters(IN1_token, IN1_amount, IN2_token, IN2_amount, OUT_token, OUT_amount, collector, sponsor);
  }

  function getParameters() public view returns (
    address IN1_token, uint256 IN1_amount,
    address IN2_token, uint256 IN2_amount,
    address OUT_token, uint256 OUT_amount,
    address collector, address sponsor
  ) {
    IN1_token = address(tokenIN1);
    IN2_token = address(tokenIN2);
    OUT_token = address(tokenOUT);
    IN1_amount = baseIN1;
    IN2_amount = baseIN2;
    OUT_amount = baseOUT;
    collector = _collector;
    sponsor = _sponsor;
  }

  function _checkProportion(uint amount1, uint amount2) internal view returns (bool) {
      // (amount1/10**decimalsIN1)/baseIN1 == (amount2/10**decimalsIN2)/baseIN2
      // (amount1*10**decimalsIN2)/baseIN1 == (amount2*10**decimalsIN1)/baseIN2
      return (
        amount1
        .mul(10**uint256(tokenIN2.decimals()))
        .div(baseIN1)
        ==
        amount2
        .mul(10**uint256(tokenIN1.decimals()))
        .div(baseIN2)
      );
  }

  function _calcOut(uint amount1/*, uint amount2*/) internal view returns (uint out) {
    if(tokenIN2.decimals() == tokenIN1.decimals())
      // out/baseOUT = amount1/baseIN1;
      out = amount1.mul(baseOUT).div(baseIN1);
    else
      // (out/10**decimalsOUT)/baseOUT = (amount1/10**decimalsIN1)/baseIN1;
      out = amount1
            .mul(10**uint256(tokenOUT.decimals()))
            .mul(baseOUT)
            .div(baseIN1)
            .div(10**uint256(tokenIN1.decimals()));
  }

  event Swap(address user, uint in1, uint in2, uint out);

  function swap(uint256 amount1, uint256 amount2) external {
    require(tokenIN1.allowance(msg.sender, address(this)) >= amount1, "Not enough allowance for input token 1");
    require(tokenIN1.balanceOf(msg.sender) >= amount1, "Not enough balance of sender for input token 1");
    require(tokenIN2.allowance(msg.sender, address(this)) >= amount2, "Not enough allowance for input token 2");
    require(tokenIN2.balanceOf(msg.sender) >= amount1, "Not enough balance of sender for input token 1");
    require(_checkProportion(amount1, amount2), "Wrong proportion of prices");
    uint256 out = _calcOut(amount1/*, amount2*/);
    require(tokenOUT.allowance(_sponsor, address(this)) >= out, "Not enough allowance for output token");
    require(tokenOUT.balanceOf(_sponsor) >= out, "Not enough balance of sponsor for output token");
    tokenIN1.transferFrom(msg.sender, _collector, amount1);
    tokenIN2.transferFrom(msg.sender, _collector, amount2);
    tokenOUT.transferFrom(_sponsor, msg.sender, out);
    emit Swap(msg.sender, amount1, amount2, out);
  }

  function IN1_tokenInfo() public view returns (string memory name, string memory symbol, uint decimals, address tokenAddress ) { return _tokenInfo(tokenIN1); }
  function IN2_tokenInfo() public view returns (string memory name, string memory symbol, uint decimals, address tokenAddress ) { return _tokenInfo(tokenIN2); }
  function OUT_tokenInfo() public view returns (string memory name, string memory symbol, uint decimals, address tokenAddress ) { return _tokenInfo(tokenOUT); }

}

//SourceUnit: Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


//SourceUnit: ITRC20.sol

pragma solidity 0.6.0;

interface ITRC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SourceUnit: Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;
    uint96 private _;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


//SourceUnit: SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

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
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
     *
     * - Multiplication cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


//SourceUnit: TokenInfo.sol

pragma solidity 0.6.0;

import "./ITRC20.sol";

contract TokenInfo {
  function _tokenInfo(ITRC20 token) internal view returns (string memory name, string memory symbol, uint decimals, address tokenAddress ) {
    name = token.name();
    symbol = token.symbol();
    decimals = token.decimals();
    tokenAddress = address(token);
  }
}