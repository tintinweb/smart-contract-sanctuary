/**
 *Submitted for verification at polygonscan.com on 2021-12-28
*/

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity ^0.8.0;



/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}


// File @opengsn/contracts/src/interfaces/[email protected]

pragma solidity >=0.6.0;

/**
 * a contract must implement this interface in order to support relayed transaction.
 * It is better to inherit the BaseRelayRecipient as its implementation.
 */
abstract contract IRelayRecipient {

    /**
     * return if the forwarder is trusted to forward relayed transactions to us.
     * the forwarder is required to verify the sender's signature, and verify
     * the call is not a replay.
     */
    function isTrustedForwarder(address forwarder) public virtual view returns(bool);

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, then the real sender is appended as the last 20 bytes
     * of the msg.data.
     * otherwise, return `msg.sender`
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal virtual view returns (address);

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal virtual view returns (bytes calldata);

    function versionRecipient() external virtual view returns (string memory);
}


// File @opengsn/contracts/src/[email protected]

// solhint-disable no-inline-assembly
pragma solidity >=0.6.9;

/**
 * A base contract to be inherited by any contract that want to receive relayed transactions
 * A subclass must use "_msgSender()" instead of "msg.sender"
 */
abstract contract BaseRelayRecipient is IRelayRecipient {

    /*
     * Forwarder singleton we accept calls from
     */
    address private _trustedForwarder;

    function trustedForwarder() public virtual view returns (address){
        return _trustedForwarder;
    }

    function _setTrustedForwarder(address _forwarder) internal {
        _trustedForwarder = _forwarder;
    }

    function isTrustedForwarder(address forwarder) public virtual override view returns(bool) {
        return forwarder == _trustedForwarder;
    }

    /**
     * return the sender of this call.
     * if the call came through our trusted forwarder, return the original sender.
     * otherwise, return `msg.sender`.
     * should be used in the contract anywhere instead of msg.sender
     */
    function _msgSender() internal override virtual view returns (address ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            // At this point we know that the sender is a trusted forwarder,
            // so we trust that the last bytes of msg.data are the verified sender address.
            // extract sender address from the end of msg.data
            assembly {
                ret := shr(96,calldataload(sub(calldatasize(),20)))
            }
        } else {
            ret = msg.sender;
        }
    }

    /**
     * return the msg.data of this call.
     * if the call came through our trusted forwarder, then the real sender was appended as the last 20 bytes
     * of the msg.data - so this method will strip those 20 bytes off.
     * otherwise (if the call was made directly and not through the forwarder), return `msg.data`
     * should be used in the contract instead of msg.data, where this difference matters.
     */
    function _msgData() internal override virtual view returns (bytes calldata ret) {
        if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
            return msg.data[0:msg.data.length-20];
        } else {
            return msg.data;
        }
    }
}


// File @openzeppelin/contracts/utils/math/[email protected]


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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


// File contracts/ERC20Interface.sol

pragma solidity ^0.8.0;

interface ERC20Interface {

    function allowance(
        address owner,
        address spender
    )
    external
    view
    returns (
        uint256 remaining
    );

    function approve(
        address spender,
        uint256 value
    )
    external
    returns (
        bool success
    );

    function balanceOf(
        address owner
    )
    external
    view
    returns (
        uint256 balance
    );

    function decimals()
    external
    view
    returns (
        uint8 decimalPlaces
    );

    function decreaseApproval(
        address spender,
        uint256 addedValue
    )
    external
    returns (
        bool success
    );

    function increaseApproval(
        address spender,
        uint256 subtractedValue
    ) external;

    function name()
    external
    view
    returns (
        string memory tokenName
    );

    function symbol()
    external
    view
    returns (
        string memory tokenSymbol
    );

    function totalSupply()
    external
    view
    returns (
        uint256 totalTokensIssued
    );

    function transfer(
        address to,
        uint256 value
    )
    external
    returns (
        bool success
    );

    function transferAndCall(
        address to,
        uint256 value,
        bytes calldata data
    )
    external
    returns (
        bool success
    );

    function transferFrom(
        address from,
        address to,
        uint256 value
    )
    external
    returns (
        bool success
    );

}


// File contracts/TSLO.sol

pragma solidity ^ 0.8.10;

//import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";


contract Tslo {

    using SafeMath
    for uint256;

    // Bet Struct
    struct Bet {
        address _wallet;
        uint256 _betAmount;
        uint256 _lines;
    }

    //Chainlink VRF
    address internal _vrfCoordinator = 0x8C7382F9D8f56b33781fE506E897a4F1e2d17255;
    address internal _linkToken = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    uint256 internal _linkFee = 0.0001 * 10 ** 18;
    bytes32 internal _linkKeyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;

    address internal _relayer = 0x9E60b8eB855982F575658a065DBe4f83e9B97b3E;


    mapping(address => uint256) public _credits; // List of user credits.
    mapping(string => Bet) public requestIdToBet;

    ERC20Interface immutable internal BLBL;
    address immutable private _blblToken = 0x8bB8662e9192a3Cc68f2BBb9915E048a7250eeaD;

    uint256[84][3] public reels;


    constructor()
    //ERC20("Tslo", "TSLO")
    //    VRFConsumerBase(
    //        _vrfCoordinator, // VRF Coordinator
    //        _linkToken  // LINK Token
    //    )
    {
        //trustedForwarder = _gsnForwarder;

        BLBL = ERC20Interface(_blblToken);
        reels[0] = [72, 69, 79, 69, 66, 69, 51, 69, 71, 69, 66, 69, 50, 69, 67, 69, 51, 69, 79, 69, 79, 69, 87, 69, 71, 69, 50, 69, 76, 69, 79, 69, 49, 69, 87, 69, 67, 69, 71, 69, 87, 69, 79, 69, 76, 69, 67, 69, 87, 69, 71, 69, 76, 69, 79, 69, 87, 69, 67, 69, 71, 69, 76, 69, 79, 69, 87, 69, 49, 69, 71, 69, 76, 69, 67, 69, 79, 69, 68, 69, 76, 69, 87, 69];
       reels[1] = [76, 69, 87, 69, 71, 69, 79, 69, 67, 69, 66, 69, 87, 69, 79, 69, 76, 69, 50, 69, 87, 69, 71, 69, 67, 69, 79, 69, 87, 69, 68, 69, 71, 69, 79, 69, 50, 69, 67, 69, 72, 69, 76, 69, 51, 69, 71, 69, 79, 69, 67, 69, 76, 69, 87, 69, 49, 69, 79, 69, 76, 69, 71, 69, 67, 69, 87, 69, 76, 69, 79, 69, 87, 69, 49, 69, 76, 69, 67, 69, 71, 69, 51, 69];
        reels[2] = [87, 69, 49, 69, 67, 69, 76, 69, 72, 69, 71, 69, 50, 69, 87, 69, 67, 69, 79, 69, 76, 69, 79, 69, 71, 69, 66, 69, 76, 69, 67, 69, 79, 69, 76, 69, 87, 69, 49, 69, 79, 69, 71, 69, 67, 69, 76, 69, 71, 69, 50, 69, 87, 69, 67, 69, 76, 69, 87, 69, 87, 69, 71, 69, 68, 69, 49, 69, 87, 69, 71, 69, 79, 69, 51, 69, 67, 69, 79, 69, 76, 69, 87, 69];


    }

    function getSymbolFromPosition(uint256 reelPostion, uint256 reelNumber) private view returns(uint256 symbol) {
        uint256 mod = reelPostion % reels[reelNumber].length;
        //if(mod<0)
        //    mod = reels[reelNumber].length + mod;
        //console.log('index:',index,mod);
        // if(index>=this.length)
        //   index = 0;
        // else if(index<0)
        //   index = this.length-1;
        return reels[reelNumber][mod];
    }

    function getSymbolsFromPosition(uint256 pos, uint256 reelNumber) private view returns(uint256[3] memory reelSymbols) {
        reelSymbols[0] = getSymbolFromPosition(pos - 1, reelNumber);
        reelSymbols[1] = getSymbolFromPosition(pos, reelNumber);
        reelSymbols[2] = getSymbolFromPosition(pos + 1, reelNumber);

        return reelSymbols;
    }

    function append(string memory a, string memory b, string memory c) internal pure returns (string memory) {

        return string(abi.encodePacked(a, b, c));

    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    /**
     * Requests randomness
     * _bet : bet amount in decimals
     */
    function getRandomNumber(address _from, uint256 _bet, uint256 _lines, string memory _serverSeed, string memory _clientSeed) public {
        address userAddress;
        if (msg.sender == _relayer)
            userAddress = _from;
        else
            userAddress = msg.sender;

        uint256 totalBet = _bet * _lines;
        //  require(LINK.balanceOf(address(this)) >= _linkFee, "Not enough LINK - contact support");
        require(BLBL.balanceOf(userAddress) >= totalBet, "Not enough credits");
        _credits[userAddress] -= totalBet;
        uint256 number = uint256(keccak256(abi.encodePacked(_serverSeed, _clientSeed)));

        uint256[] memory reelPosition = new uint256[](3);
        uint256[3][3] memory reelsValues;
        for (uint256 i = 0; i < 3; i++) {
            reelPosition[i] = uint256(keccak256(abi.encode(number, i))).mod(reels[i].length);
            reelsValues[i] = getSymbolsFromPosition(reelPosition[i], i);
        }
        emit ReelsPosition(reelPosition[0],reelPosition[1],reelPosition[2]);
        string memory lineTop = append(uint2str(reelsValues[0][0]),uint2str(reelsValues[1][0]),uint2str(reelsValues[2][0]));
        string memory lineMiddle = append(uint2str(reelsValues[0][1]),uint2str(reelsValues[1][1]),uint2str(reelsValues[2][1]));
        string memory lineBottom = append(uint2str(reelsValues[0][2]),uint2str(reelsValues[1][2]),uint2str(reelsValues[2][2]));

        emit ReelsValues(reelsValues);
        emit Lines(lineTop,lineMiddle,lineBottom);
        //requestId = requestRandomness(_linkKeyHash, _linkFee);
        requestIdToBet[_clientSeed] = Bet(userAddress, _bet, _lines);
        uint256[3] memory winLines = checkWinOrLost(reelsValues,_lines);
        fulfillRandomness(_clientSeed, winLines);
        //return requestId;
    }


    function checkWinOrLost(uint256[3][3] memory reelsSymbols, uint256 lines) private pure returns(uint256[3] memory){

        uint256[3] memory lineWin;
        //uint256 win = 0;

        for (uint256 i = 0; i < 3; i++) {

            lineWin[i] = 0;

            if( (lines>=2 && i==0) || (lines>=1 && i==1) || (lines>=3 && i==2) ){
                if(reelsSymbols[0][i]==68 && reelsSymbols[1][i]==68 && reelsSymbols[2][i]==68) { lineWin[i] += 5000; }
                else if((reelsSymbols[0][i]==72 || reelsSymbols[0][i]==68) && (reelsSymbols[1][i]==72 || reelsSymbols[1][i]==68) && (reelsSymbols[2][i]==72 || reelsSymbols[2][i]==68)) { lineWin[i] += 700; }
                else if((reelsSymbols[0][i]==66 || reelsSymbols[0][i]==68) && (reelsSymbols[1][i]==66 || reelsSymbols[1][i]==68) && (reelsSymbols[2][i]==66 || reelsSymbols[2][i]==68)) { lineWin[i] += 600; }
                else if((reelsSymbols[0][i]==51 || reelsSymbols[0][i]==68) && (reelsSymbols[1][i]==51 || reelsSymbols[1][i]==68) && (reelsSymbols[2][i]==51 || reelsSymbols[2][i]==68)) { lineWin[i] += 500; }
                else if((reelsSymbols[0][i]==50 || reelsSymbols[0][i]==68) && (reelsSymbols[1][i]==50 || reelsSymbols[1][i]==68) && (reelsSymbols[2][i]==50 || reelsSymbols[2][i]==68)) { lineWin[i] += 400; }
                else if((reelsSymbols[0][i]==49 || reelsSymbols[0][i]==68) && (reelsSymbols[1][i]==49 || reelsSymbols[1][i]==68) && (reelsSymbols[2][i]==49 || reelsSymbols[2][i]==68)) { lineWin[i] += 300; }

                else if((reelsSymbols[0][i]==49 || reelsSymbols[0][i]==50 || reelsSymbols[0][i]==51 || reelsSymbols[0][i]==68) &&
                        (reelsSymbols[1][i]==49 || reelsSymbols[1][i]==50 || reelsSymbols[0][i]==51 || reelsSymbols[0][i]==68) &&
                        (reelsSymbols[2][i]==49 || reelsSymbols[2][i]==50 || reelsSymbols[0][i]==51 || reelsSymbols[0][i]==68)) { lineWin[i] += 140; }

                else if((reelsSymbols[0][i]==67 || reelsSymbols[0][i]==68) && (reelsSymbols[1][i]==67 || reelsSymbols[1][i]==68) && (reelsSymbols[2][i]==67 || reelsSymbols[2][i]==68)) { lineWin[i] += 100; }
                else if((reelsSymbols[0][i]==71 || reelsSymbols[0][i]==68) && (reelsSymbols[1][i]==71 || reelsSymbols[1][i]==68) && (reelsSymbols[2][i]==71 || reelsSymbols[2][i]==68)) { lineWin[i] += 80; }
                else if((reelsSymbols[0][i]==76 || reelsSymbols[0][i]==68) && (reelsSymbols[1][i]==76 || reelsSymbols[1][i]==68) && (reelsSymbols[2][i]==76 || reelsSymbols[2][i]==68)) { lineWin[i] += 70; }
                else if((reelsSymbols[0][i]==79 || reelsSymbols[0][i]==68) && (reelsSymbols[1][i]==79 || reelsSymbols[1][i]==68) && (reelsSymbols[2][i]==79 || reelsSymbols[2][i]==68)) { lineWin[i] += 60; }
                else if((reelsSymbols[0][i]==87 || reelsSymbols[0][i]==68) && (reelsSymbols[1][i]==87 || reelsSymbols[1][i]==68) && (reelsSymbols[2][i]==87 || reelsSymbols[2][i]==68)) { lineWin[i] += 50; }

                else if((reelsSymbols[0][i]==67 || reelsSymbols[0][i]==68) && (reelsSymbols[1][i]==67 || reelsSymbols[1][i]==68)) { lineWin[i] += 16; }
                else if((reelsSymbols[0][i]==71 || reelsSymbols[0][i]==68) && (reelsSymbols[1][i]==71 || reelsSymbols[1][i]==68)) { lineWin[i] += 14; }
                else if((reelsSymbols[0][i]==76 || reelsSymbols[0][i]==68) && (reelsSymbols[1][i]==76 || reelsSymbols[1][i]==68)) { lineWin[i] += 12; }
                else if((reelsSymbols[0][i]==79 || reelsSymbols[0][i]==68) && (reelsSymbols[1][i]==79 || reelsSymbols[1][i]==68)) { lineWin[i] += 8; }
                else if((reelsSymbols[0][i]==87 || reelsSymbols[0][i]==68) && (reelsSymbols[1][i]==87 || reelsSymbols[1][i]==68)) { lineWin[i] += 10; }

                else if((reelsSymbols[0][i]==71 || reelsSymbols[0][i]==76 || reelsSymbols[0][i]==79 || reelsSymbols[0][i]==87 || reelsSymbols[0][i]==68) &&
                        (reelsSymbols[0][i]==71 || reelsSymbols[1][i]==76 || reelsSymbols[1][i]==79 || reelsSymbols[0][i]==87 || reelsSymbols[0][i]==68) &&
                        (reelsSymbols[0][i]==71 || reelsSymbols[2][i]==76 || reelsSymbols[2][i]==79 || reelsSymbols[0][i]==87 || reelsSymbols[0][i]==68)) { lineWin[i] += 3; }

                else if((reelsSymbols[0][i]==71 || reelsSymbols[0][i]==76 || reelsSymbols[0][i]==79 || reelsSymbols[0][i]==87 || reelsSymbols[0][i]==68) &&
                        (reelsSymbols[0][i]==71 || reelsSymbols[1][i]==76 || reelsSymbols[1][i]==79 || reelsSymbols[0][i]==87 || reelsSymbols[0][i]==68)) { lineWin[i] += 1; }

            }

            //win += lineWin[i];
        }

        return lineWin;
    }


    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(string memory _clientSeed, uint256[3] memory winLines) internal {
        Bet memory _bet = requestIdToBet[_clientSeed];
        if(_bet._lines >= 1)
            _credits[_bet._wallet] += winLines[1] * _bet._betAmount;
        if(_bet._lines >= 2)
            _credits[_bet._wallet] += winLines[0] * _bet._betAmount;
        if(_bet._lines >= 3)
            _credits[_bet._wallet] += winLines[2] * _bet._betAmount;
        emit RandomReceived(_clientSeed, winLines);
    }



    //    // Let users participate by sending eth directly to contract address
    //    receive () external payable {
    //        // player name will be unknown
    //        emit ValueReceived(msg.sender,msg.value);
    //    }
    //
    //    // Let users participate by sending eth directly to contract address
    //    fallback () external payable {
    //        // player name will be unknown
    //        emit FallbackReceived(msg.sender,msg.value,msg.data);
    //    }

    function tokenFallback(address _from, uint256 _value) external payable {
        require(_blblToken == msg.sender, "Token not verified");
        _credits[_from] += _value;
        emit TokenReceived(_from, _value, msg.sender);
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function creditsOf(address account) public view virtual returns(uint256) {
        return _credits[account];
    }

    //Events
    event TransferCredits(address user, uint256 amount);
    event RandomReceived(string clientSeed, uint256[3] winLines);
    event ValueReceived(address user, uint amount);
    event FallbackReceived(address user, uint amount, bytes data);
    event TokenReceived(address _from, uint256 _value, address sender);
    event ReelsValues(uint256[3][3] values);
    event ReelsPosition(uint256, uint256, uint256);
    event Lines(string top,string middle,string bottom);
}