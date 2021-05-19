// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract ERC20WithoutTotalSupply is IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 allowed = _allowances[sender][msg.sender];
        if ((allowed >> 255) == 0) {
            _approve(sender, msg.sender, allowed.sub(amount, "ERC20: transfer amount exceeds allowance"));
        }
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _mint(address account, uint256 amount) internal {
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        emit Transfer(account, address(0), amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        uint256 allowed = _allowances[account][msg.sender];
        if ((allowed >> 255) == 0) {
            _approve(account, msg.sender, allowed.sub(amount, "ERC20: burn amount exceeds allowance"));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the wrapped Gas Token Type
 */
interface IGasToken {

    /**
    * @dev calculate token total supply
    */
    function totalSupply() external view returns(uint256);

    /**
    * @dev calculate protocol fee
    */
    function calculateFee(uint256 value, uint256 feeValue) external pure returns(uint256);

    /**
     * @dev mints new tokens.
     */
    function mint(uint256 value) external; 

    /**
    * @dev mints new tokens at a fee discount.
    */
    function discountedMint(uint256 value, uint256 discountedFee, address recipient) external; 

    /**
    * @dev unwraps gas tokens.
    */
    function unwrap(uint256 value) external;

    /**
     * @dev return number of tokens freed up.
     */
    function free(uint256 value) external returns (uint256);

    /**
     * @dev return number of tokens freed up.
     */
    function freeUpTo(uint256 value) external returns (uint256);

    /**
     * @dev return number of tokens freed up.
     */
    function freeFrom(address from, uint256 value) external returns (uint256); 

    /**
     * @dev return number of tokens freed up.
     */
    function freeFromUpTo(address from, uint256 value) external returns (uint256); 

    /**
     * @dev updates fee address of this contract.
     */
    function updateFeeAddress(address newFeeAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import './ERC20WithoutTotalSupply.sol';
import "./IGasToken.sol";

/**
* @dev Wrapped Gas Token is a wrapper for all gas tokens. It provides them with uniform functions and interface
* It also makes non-erc20 compliant tokens like GST1 and GST2, compliant.
*/
contract WrappedGasToken is IERC20, ERC20WithoutTotalSupply, Ownable{
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 constant public decimals = 0;
    address public wrappedTokenAddress;

    uint256 public totalMinted;
    uint256 public totalBurned;

    uint256 constant public protocolFee = 2;

    address public feeAddress;

    /**
    * @dev We set the main elements of our wrapped token here.
    * the name, symbol and fee address and address of the underlying gas token
    */
    constructor(address _tokenAddress, address _feeAddress, string memory _name, string memory _symbol) {
        feeAddress = _feeAddress;
        wrappedTokenAddress = _tokenAddress;
        name = _name;
        symbol = _symbol;
    }


    /**
    * @dev returns total supply of the wrapped gas token
    */
    function totalSupply() public view override returns(uint256) {
        return totalMinted - totalBurned;
    }

    /**
    * @dev calculates the protocol fee. This is 1 + x% of the wrapped tokens. 
    * It scales based on the number of tokens wrapped in the transaction.
    * the x% is based on the manner in which the user decided to mint the token.
    * if they minted using the discounted or burned methods from the protocol, then they have a lower %.
    */
    function calculateFee(uint256 value, uint256 feeValue) public pure returns(uint256){
        uint256 fee = 1;
        fee = fee.add(value.div(100).mul(feeValue));
        return fee;
    }

    /**
    * @dev This function mints new wrapped gas tokens.
    * This is done by transfering the gas token to this contract
    * issuing wrapped gas tokens to the user
    * issuing wrapped gas tokens equal to the fee, to the fee address.
    */
    function mint(uint256 value) public {
        require(IERC20(wrappedTokenAddress).transferFrom(msg.sender, address(this), value), "GSVE: Gas Token Wrap Transfer Failed");
        uint256 fee = calculateFee(value, protocolFee);
        uint256 valueAfterFee =  value.sub(fee, "GSVE: Minted Value must be larger than fee");
        _mint(msg.sender, valueAfterFee);
        _mint(feeAddress, fee);
        totalMinted = totalMinted + value;
    }

    /**
    * @dev This function mints new wrapped gas tokens at a discount
    * it is guided by the protocols fee and tier system 
    * as the protocol is the owner of this contract, it is the only one that can interact with it.
    * The process is the same as minting. We transfer the gas token to this contract
    * issuing wrapped gas tokens to the user
    * issuing wrapped gas tokens equal to the fee, to the fee address, if there is a fee to be paid.
    */
    function discountedMint(uint256 value, uint256 discountedFee, address recipient) public onlyOwner {
        require(IERC20(wrappedTokenAddress).transferFrom(recipient, address(this), value), "GSVE: Gas Token Wrap Transfer Failed");
        uint256 fee = 0;
        if(discountedFee>0){
            fee = calculateFee(value, discountedFee);
        }
        uint256 valueAfterFee =  value.sub(fee, "GSVE: Minted Value must be larger than fee");
        _mint(recipient, valueAfterFee);

        if(fee>0){
            _mint(feeAddress, fee);
        }
        
        totalMinted = totalMinted + value;
    }

    /**
    * @dev This function allows the user to unwrap gas tokens
    * this is done by burning wrapped gas tokens from the user
    * transfering the equivelent number of gas tokens to the user.
    */
    function unwrap(uint256 value) public {
        if(value > 0){
            _burn(msg.sender, value);
            IERC20(wrappedTokenAddress).transfer(msg.sender, value);
            totalMinted = totalMinted + value;
        }
    }


    /**
    * @dev This function burns the wrapped gas token,
    * burns the equivelent gas tokens, and frees up the gas
    */
    function free(uint256 value) public returns (uint256)  {
        if (value > 0) {
            _burn(msg.sender, value);
            totalBurned = totalBurned + value;
            IGasToken(wrappedTokenAddress).free(value);
        }
        return value;
    }

    /**
    * @dev a safe way of freeing up x number of tokens
    * up to the users balance
    */
    function freeUpTo(uint256 value) public returns (uint256) {
        return free(Math.min(value, balanceOf(msg.sender)));
    }

    /**
    * @dev This function burns the wrapped gas token from a specified address,
    * burns the equivelent gas tokens, and frees up the gas
    */
    function freeFrom(address from, uint256 value) public returns (uint256) {
        if (value > 0) {
            _burnFrom(from, value);
            totalBurned = totalBurned + value;
            IGasToken(wrappedTokenAddress).free(value);
        }
        return value;
    }

    /**
    * @dev a safe way of freeing up x number of tokens
    * up to the users balance
    */
    function freeFromUpTo(address from, uint256 value) public returns (uint256) {
        return freeFrom(from, Math.min(Math.min(value, balanceOf(from)), allowance(from, msg.sender)));
    }

    /**
    * @dev a method for updating the address that receives the fees.
    * This is set by the owner, which will be the protocol.
    */
    function updateFeeAddress(address newFeeAddress) public onlyOwner {
        feeAddress = newFeeAddress;
    }
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}