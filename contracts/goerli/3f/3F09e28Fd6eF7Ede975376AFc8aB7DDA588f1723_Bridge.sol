// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "../common/math/SafeMath.sol";
import "../common/access/Ownable.sol";
import "../permittableErc20/IPermittableToken.sol";
import "../erc20/IERC20.sol";

contract Bridge is Ownable {
    using SafeMath for uint256;

    event Deposit(address indexed recipient, uint value);
    event DepositFor(address indexed sender, uint value, address indexed recipient);
    event Withdrawal(address indexed src, uint value);
    event WithdrawalTo(address indexed sender, uint value, address indexed recipient);
    event DepositTokenFor(address indexed sender, uint amount, address indexed recipient, address indexed tokenAddress);
    event TokenWithdrawal(address indexed sender, address indexed token, uint value, address indexed recipient);
    event DepositWithdrawn(
        address indexed token,
        uint depositValue,
        uint fee,
        uint withdrawAmount,
        bytes32 txHash,
        address indexed recipient,
        bytes32 depositId
    );

    mapping (address => uint256) internal _balances;
    mapping (bytes32 => bool) internal _withdrawnDeposits;

    constructor() public Ownable() {}

    receive() external payable {
        deposit();
    }

    function deposit() virtual public payable {
        _balances[owner()] = _balances[owner()].add(msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function depositFor(address recipient) virtual public payable {
        _balances[owner()] = _balances[owner()].add(msg.value);
        emit DepositFor(msg.sender, msg.value, recipient);
    }

    function depositWithPermit(
        address tokenAddress,
        uint amount,
        address recipient,
        uint256 permitNonce,
        uint256 permitExpiry,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) virtual external {
        IPermittableToken token = IPermittableToken(tokenAddress);

        if (token.allowance(msg.sender, address(this)) < amount) {
            token.permit(
                msg.sender,
                address(this),
                permitNonce,
                permitExpiry,
                true,
                permitV,
                permitR,
                permitS
            );
        }
        depositTokenFor(tokenAddress, amount, recipient);
    }

    function depositTokenFor(
        address tokenAddress,
        uint amount,
        address recipient
    ) virtual public {
        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(msg.sender, address(this), amount);

        emit DepositTokenFor(msg.sender, amount, recipient, tokenAddress);
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function balanceOfToken(address token) public view returns (uint256) {
        return _getBalance(address(this), token);
    }

    function balanceOfBatch(address[] calldata tokens) public view returns (uint[] memory)
    {
        uint[] memory result = new uint[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] != address(0x0)) {
                result[i] = _getBalance(address(this), tokens[i]);
            } else {
                result[i] = _balances[owner()];
            }
        }

        return result;
    }

    function withdraw(uint value) virtual external {
        _withdraw(msg.sender, value);
        emit Withdrawal(msg.sender, value);
    }

    function withdrawTo(address recipient, uint value) virtual external {
        _withdraw(recipient, value);
        emit WithdrawalTo(msg.sender, value, recipient);
    }

    function _withdraw(address recipient, uint value) internal {
        _balances[msg.sender] = _balances[msg.sender].sub(value, "Bridge: withdrawal amount exceeds balance");

        require(
            // solhint-disable-next-line check-send-result
            payable(recipient).send(value)
        );
    }

    function withdrawToken(
        address token,
        uint value,
        address recipient
    ) virtual onlyOwner external {
        if (token != address(0x0)) {
            IERC20(token).transfer(recipient, value);
        } else {
            _withdraw(recipient, value);
        }
        emit TokenWithdrawal(msg.sender, token, value, recipient);
    }

    function withdrawTokens(
        address[] calldata tokens,
        uint[] calldata values,
        address[] calldata recipients
    ) virtual onlyOwner external {
        require(tokens.length == values.length, "Bridge#withdrawTokens: INVALID_ARRAY_LENGTH");

        for (uint256 i = 0; i < tokens.length; i++) {
            address recipient = recipients.length == 1 ? recipients[0] : recipients[i];
            if (tokens[i] != address(0x0)) {
                IERC20(tokens[i]).transfer(recipient, values[i]);
            } else {
                _withdraw(recipient, values[i]);
            }
            emit TokenWithdrawal(msg.sender, tokens[i], values[i], recipient);
        }
    }

    // Will be called on another network
    function withdrawDeposit(
        address token,
        uint depositValue,
        uint fee,
        bytes32 txHash,
        address recipient
    ) virtual onlyOwner public {
        bytes32 depositId = keccak256(abi.encodePacked(token, depositValue, txHash));
        require(!_withdrawnDeposits[depositId], 'Bridge#withdrawDeposit: DEPOSIT_ALREADY_WITHDRAWN');

        uint withdrawAmount = depositValue.sub(fee);

        if (token != address(0x0)) {
            IERC20(token).transfer(recipient, withdrawAmount);
        } else {
            _withdraw(recipient, withdrawAmount);
        }

        _withdrawnDeposits[depositId] = true;

        emit DepositWithdrawn(token, depositValue, fee, withdrawAmount, txHash, recipient, depositId);
    }

    function withdrawDepositsBatch(
        address[] calldata tokens,
        uint[] calldata depositValues,
        uint[] calldata fees,
        bytes32[] calldata txHashes,
        address[] calldata recipients
    ) virtual onlyOwner external {
        require(
            tokens.length == depositValues.length &&
            tokens.length == fees.length &&
            tokens.length == txHashes.length &&
            tokens.length == recipients.length
            , "Bridge#withdrawDepositsBatch: INVALID_ARRAY_LENGTH");

        for (uint256 i = 0; i < tokens.length; i++) {
            withdrawDeposit(
                tokens[i],
                depositValues[i],
                fees[i],
                txHashes[i],
                recipients[i]
            );
        }
    }

    function withdrawnDepositStatus(bytes32 depositId) public view returns (bool) {
        return _withdrawnDeposits[depositId];
    }

    // private functions

    function _getBalance(
        address account,
        address token
    )
        private
        view
        returns (uint256)
    {
        uint256 result = 0;
        uint256 tokenCode;

        /// @dev check if token is actually a contract
        // solhint-disable-next-line no-inline-assembly
        assembly { tokenCode := extcodesize(token) } // contract code size

        if (tokenCode > 0) {
            /// @dev is it a contract and does it implement balanceOf
            // solhint-disable-next-line avoid-low-level-calls
            (bool methodExists,) = token.staticcall(
                abi.encodeWithSelector(IERC20(token).balanceOf.selector, account)
            );

            if (methodExists) {
                result = IERC20(token).balanceOf(account);
            }
        }

        return result;
    }
}

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "../GSN/Context.sol";
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
    constructor () internal {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the contract name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the contract symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the amount of decimals.
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

interface IPermittableToken {
    function allowance(
        address holder,
        address spender
    )
        external
        view
        returns (uint256);

    function approve(
        address spender,
        uint256 value
    )
        external
        returns (bool);

    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external;

    function transfer(
        address to,
        uint256 value
    )
        external
        returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    )
        external
        returns (bool);

    function balanceOf(
        address account
    )
        external
        view
        returns (uint256);
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 2000
  },
  "remappings": [],
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