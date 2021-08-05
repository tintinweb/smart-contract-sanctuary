/**
 *Submitted for verification at Etherscan.io on 2020-07-16
*/

/**
 *Submitted for verification at Etherscan.io on 2020-07-15
*/

pragma experimental ABIEncoderV2;
pragma solidity ^0.6.0;


interface IRouter {
    function f(uint id, bytes32 k) external view returns (address);
    function defaultDataContract(uint id) external view returns (address);
    function bondNr() external view returns (uint);
    function setBondNr(uint _bondNr) external;

    function setDefaultContract(uint id, address data) external;
    function addField(uint id, bytes32 field, address data) external;
}

enum BondStage {
        //无意义状态
        DefaultStage,
        //评级
        RiskRating,
        RiskRatingFail,
        //募资
        CrowdFunding,
        CrowdFundingSuccess,
        CrowdFundingFail,
        UnRepay,//待还款
        RepaySuccess,
        Overdue,
        //由清算导致的债务结清
        DebtClosed
    }

//状态标签
enum IssuerStage {
        DefaultStage,
		UnWithdrawCrowd,
        WithdrawCrowdSuccess,
		UnWithdrawPawn,
        WithdrawPawnSuccess       
    }

/**
 *Submitted for verification at Etherscan.io on 2020-04-03
*/
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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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

library SafeMath {
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
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

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    // function toPayable(address account) internal pure returns (address payable) {
    //     return address(uint160(account));
    // }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     *
     * _Available since v2.4.0._
     */
    // function sendValue(address payable recipient, uint256 amount) internal {
    //     require(address(this).balance >= amount, "Address: insufficient balance");

    //     // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    //     (bool success, ) = recipient.call.value(amount)("");
    //     require(success, "Address: unable to send value, recipient may have reverted");
    // }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    // function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
    //     uint256 newAllowance = token.allowance(address(this), spender).add(value);
    //     callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    // }

    // function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
    //     uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
    //     callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    // }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

/**
 * @dev Optional functions from the ERC20 standard.
 */
abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for `name`, `symbol`, and `decimals`. All three of
     * these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
    // function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
    //     _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    //     return true;
    // }

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
    // function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
    //     _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
    //     return true;
    // }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
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
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        // _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        // _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        // _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    // function _burnFrom(address account, uint256 amount) internal virtual {
    //     _burn(account, amount);
    //     _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    // }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of `from`'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of `from`'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:using-hooks.adoc[Using Hooks].
     */
    // function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// File: ../../../../tmp/openzeppelin-contracts/contracts/token/ERC20/ERC20Burnable.sol
// pragma solidity ^0.6.0;
/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev See {ERC20-_burnFrom}.
     */
    // function burnFrom(address account, uint256 amount) public virtual {
    //     _burnFrom(account, amount);
    // }
}

interface IBondData {
    struct what {
        address proposal;
        uint256 weight;
    }

    struct prwhat {
        address who;
        address proposal;
        uint256 reason;
    }

    struct Balance {
        //发行者：
        //amountGive: 质押的token数量，项目方代币
        //amountGet: 募集的token数量，USDT，USDC

        //投资者：
        //amountGive: 投资的token数量，USDT，USDC
        //amountGet: 债券凭证数量
        uint256 amountGive;
        uint256 amountGet;
    }

    function issuer() external view returns (address);

    function collateralToken() external view returns (address);

    function crowdToken() external view returns (address);

    function getBorrowAmountGive() external view returns (uint256);



    function getSupplyAmount(address who) external view returns (uint256);


    function par() external view returns (uint256);

    function mintBond(address who, uint256 amount) external;

    function burnBond(address who, uint256 amount) external;


    function transferableAmount() external view returns (uint256);

    function debt() external view returns (uint256);

    function actualBondIssuance() external view returns (uint256);

    function couponRate() external view returns (uint256);

    function depositMultiple() external view returns (uint256);

    function discount() external view returns (uint256);


    function voteExpired() external view returns (uint256);


    function investExpired() external view returns (uint256);

    function totalBondIssuance() external view returns (uint256);

    function maturity() external view returns (uint256);

    function config() external view returns (address);

    function weightOf(address who) external view returns (uint256);

    function totalWeight() external view returns (uint256);

    function bondExpired() external view returns (uint256);

    function interestBearingPeriod() external;


    function bondStage() external view returns (uint256);

    function issuerStage() external view returns (uint256);

    function issueFee() external view returns (uint256);


    function totalInterest() external view returns (uint256);

    function gracePeriod() external view returns (uint256);

    function liability() external view returns (uint256);

    function remainInvestAmount() external view returns (uint256);

    function supplyMap(address) external view returns (Balance memory);


    function balanceOf(address account) external view returns (uint256);

    function setPar(uint256) external;

    function liquidateLine() external view returns (uint256);

    function setBondParam(bytes32 k, uint256 v) external;

    function setBondParamAddress(bytes32 k, address v) external;

    function minIssueRatio() external view returns (uint256);

    function partialLiquidateAmount() external view returns (uint256);

    function votes(address who) external view returns (what memory);

    function setVotes(address who, address proposal, uint256 amount) external;

    function weights(address proposal) external view returns (uint256);

    function setBondParamMapping(bytes32 name, address k, uint256 v) external;

    function top() external view returns (address);


    function voteLedger(address who) external view returns (uint256);

    function totalWeights() external view returns (uint256);


    function setPr(address who, address proposal, uint256 reason) external;

    function pr() external view returns (prwhat memory);

    function fee() external view returns (uint256);

    function profits(address who) external view returns (uint256);



    function totalProfits() external view returns (uint256);

    function originLiability() external view returns (uint256);

    function liquidating() external view returns (bool);
    function setLiquidating(bool _liquidating) external;

    function sysProfit() external view returns (uint256);
    function totalFee() external view returns (uint256);

    function supportRedeem() external view returns (bool);
}

/*
 * Copyright (c) The Force Protocol Development Team
 */
interface ICoreUtils {
    function d(uint256 id) external view returns (address);

    function bondData(uint256 id) external view returns (IBondData);

    //principal + interest = principal * (1 + couponRate);
    function calcPrincipalAndInterest(uint256 principal, uint256 couponRate)
        external
        pure
        returns (uint256);

    //可转出金额,募集到的总资金减去给所有投票人的手续费
    function transferableAmount(uint256 id) external view returns (uint256);

    //总的募集资金量
    function debt(uint256 id) external view returns (uint256);

    //总的募集资金量
    function totalInterest(uint256 id) external view returns (uint256);

    function debtPlusTotalInterest(uint256 id) external view returns (uint256);

    //可投资的剩余份数
    function remainInvestAmount(uint256 id) external view returns (uint256);

        function calcMinCollateralTokenAmount(uint256 id)
        external
        view
        returns (uint256);
    function pawnBalanceInUsd(uint256 id) external view returns (uint256);

    function disCountPawnBalanceInUsd(uint256 id)
        external
        view
        returns (uint256);

    function crowdBalanceInUsd(uint256 id) external view returns (uint256);

    //资不抵债判断，资不抵债时，为true，否则为false
    function isInsolvency(uint256 id) external view returns (bool);

    //获取质押的代币价格
    function pawnPrice(uint256 id) external view returns (uint256);

    //获取募资的代币价格
    function crowdPrice(uint256 id) external view returns (uint256);

    //要清算的质押物数量
    //X = (AC*price - PCR*PD)/(price*(1-PCR*Discount))
    //X = (PCR*PD - AC*price)/(price*(PCR*Discount-1))
    function X(uint256 id) external view returns (uint256 res);
    //清算额，减少的债务
    //X*price(collater)*Discount/price(crowd)
    function Y(uint256 id) external view returns (uint256 res);

    //到期后，由系统债务算出需要清算的抵押物数量
    function calcLiquidatePawnAmount(uint256 id) external view returns (uint256);
    function calcLiquidatePawnAmount(uint256 id, uint256 liability) external view returns (uint256);

    function investPrincipalWithInterest(uint256 id, address who)
        external
        view
        returns (uint256);

        //bond:
    function convert2BondAmount(address b, address t, uint256 amount)
        external
        view
        returns (uint256);

    //bond:
    function convert2GiveAmount(uint256 id, uint256 bondAmount)
        external
        view
        returns (uint256);
    
    function isUnsafe(uint256 id) external view returns (bool unsafe);
    function isDepositMultipleUnsafe(uint256 id) external view returns (bool unsafe);
    function getLiquidateAmount(uint id, uint y1) external view returns (uint256, uint256);
    function precision(uint256 id) external view returns (uint256);
    function isDebtOpen(uint256 id) external view returns (bool);
    function isMinIssuanceCheckOK(uint256 id) external view returns (bool ok);
}

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20Detailed {
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
}

interface IOracle {
    function get(address t) external view returns (uint, bool);
}

interface IConfig {
    function voteDuration() external view returns (uint256);

    function investDuration() external view returns (uint256);

    function discount(address token) external view returns (uint256);
    function depositMultiple(address token) external view returns (uint256);
    function liquidateLine(address token) external view returns (uint256);

    function gracePeriod() external view returns (uint256);
    function partialLiquidateAmount(address token) external view returns (uint256);
    function gov() external view returns(address);
    function ratingFeeRatio() external view returns (uint256);
}

interface IACL {
    function accessible(address from, address to, bytes4 sig)
        external
        view
        returns (bool);
}

contract Core {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public ACL;
    address public router;
    address public config;
    address public oracle;
    ICoreUtils public coreUtils;
    address public nameGen;

    modifier auth {
        IACL _ACL = IACL(ACL);
        require(_ACL.accessible(msg.sender, address(this), msg.sig), "core: access unauthorized");
        _;
    }

    constructor(
        address _ACL,
        address _router,
        address _config,
        address _coreUtils,
        address _oracle,
	    address _nameGen
    ) public {
        ACL = _ACL;
        router = _router;
        config = _config;
        coreUtils = ICoreUtils(_coreUtils);
        oracle = _oracle;
	    nameGen = _nameGen;
    }

    function setCoreParamAddress(bytes32 k, address v) external auth {
        if (k == bytes32("router")) {
            router = v;
            return;
        }
        if (k == bytes32("config")) {
            config = v;
            return;
        }
        if (k == bytes32("coreUtils")) {
            coreUtils = ICoreUtils(v);
            return;
        }
        if (k == bytes32("oracle")) {
            oracle = v;
            return;
        }
        revert("setCoreParamAddress: invalid k");
    }

    function setACL(
        address _ACL) external {
        require(msg.sender == ACL, "require ACL");
        ACL = _ACL;
    }

    function d(uint256 id) public view returns (address) {
        return IRouter(router).defaultDataContract(id);
    }

    function bondData(uint256 id) public view returns (IBondData) {
        return IBondData(d(id));
    }

    event MonitorEvent(address indexed who, address indexed bond, bytes32 indexed funcName, bytes);

    function MonitorEventCallback(address who, address bond, bytes32 funcName, bytes calldata payload) external auth {
        emit MonitorEvent(who, bond, funcName, payload);
    }

    function initialDepositCb(uint256 id, uint256 amount) external auth {
        IBondData b = bondData(id);
        b.setBondParam("depositMultiple", IConfig(config).depositMultiple(b.collateralToken()));

        require(amount >= ICoreUtils(coreUtils).calcMinCollateralTokenAmount(id), "invalid deposit amount");
        
        // 支持评级
        if (b.supportRedeem()) {
            b.setBondParam("bondStage", uint256(BondStage.RiskRating));
            b.setBondParamAddress("gov", IConfig(config).gov());

            uint256 voteDuration = IConfig(config).voteDuration(); //s
            b.setBondParam("voteExpired", now + voteDuration);
        } else {
            b.setBondParam("bondStage", uint256(BondStage.CrowdFunding));
            b.setBondParam("voteExpired", now);//不支持评级的债券发债后，投票立即到期
            b.setBondParam("investExpired", now + IConfig(config).investDuration());
            b.setBondParam("bondExpired", now + IConfig(config).investDuration() + b.maturity());
        }

        b.setBondParam("gracePeriod", IConfig(config).gracePeriod());

        b.setBondParam("discount", IConfig(config).discount(b.collateralToken()));
        b.setBondParam("liquidateLine", IConfig(config).liquidateLine(b.collateralToken()));
        b.setBondParam("partialLiquidateAmount", IConfig(config).partialLiquidateAmount(b.crowdToken()));


        b.setBondParam("borrowAmountGive", b.getBorrowAmountGive().add(amount));
               

    }

    //发债方追加资金, amount为需要转入的token数
    function depositCb(address who, uint256 id, uint256 amount)
        external
        auth
        returns (bool)
    {
        require(d(id) != address(0) && bondData(id).issuer() == who, "invalid address or issuer");

        IBondData b = bondData(id);
        // //充值amount token到合约中，充值之前需要approve
        // safeTransferFrom(b.collateralToken(), msg.sender, address(this), address(this), amount);

        b.setBondParam("borrowAmountGive",b.getBorrowAmountGive().add(amount));

        return true;
    }

    //投资债券接口
    //id: 发行的债券id，唯一标志债券
    //amount： 投资的数量
    function investCb(address who, uint256 id, uint256 amount)
        external
        auth
        returns (bool)
    {
        IBondData b = bondData(id);
        require(d(id) != address(0) 
            && who != b.issuer() 
            && now <= b.investExpired()
            && b.bondStage() == uint(BondStage.CrowdFunding), "forbidden self invest, or invest is expired");
        uint256 bondAmount = coreUtils.convert2BondAmount(address(b), b.crowdToken(), amount);
        //投资不能超过剩余可投份数
        require(
            bondAmount > 0 && bondAmount <= coreUtils.remainInvestAmount(id),
            "invalid bondAmount"
        );
        b.mintBond(who, bondAmount);

        // //充值amount token到合约中，充值之前需要approve
        // safeTransferFrom(give, msg.sender, address(this), address(this), amount);

        require(coreUtils.remainInvestAmount(id) >= 0, "bond overflow");


        return true;
    }

    //停止融资, 开始计息
    function interestBearingPeriod(uint256 id) external {
        IBondData b = bondData(id);

        //设置众筹状态, 调用的前置条件必须满足债券投票完成并且通过.
        //@auth 仅允许 @Core 合约调用.
        require(d(id) != address(0)
            && b.bondStage() == uint256(BondStage.CrowdFunding)
            && (now > b.investExpired() || coreUtils.remainInvestAmount(id) == 0), "already closed invest");
        //计算融资进度.
        if (coreUtils.isMinIssuanceCheckOK(id)) {
            uint sysDebt = coreUtils.debtPlusTotalInterest(id);
            b.setBondParam("liability", sysDebt);
            b.setBondParam("originLiability", sysDebt);

            uint256 _1 = 1 ether;
            uint256 crowdUsdxLeverage = coreUtils.crowdBalanceInUsd(id)
                .mul(b.depositMultiple())
                .mul(b.liquidateLine())
                .div(1e36);

            //CCR < 0.7 * 4
            //pawnUsd/crowdUsd < 0.7*4
            bool unsafe = coreUtils.pawnBalanceInUsd(id) < crowdUsdxLeverage;
            if (unsafe) {
                b.setBondParam("bondStage", uint256(BondStage.CrowdFundingFail));
                b.setBondParam("issuerStage", uint256(IssuerStage.UnWithdrawPawn));
            } else {
                b.setBondParam("bondExpired", now + b.maturity());

                b.setBondParam("bondStage", uint256(BondStage.CrowdFundingSuccess));
                b.setBondParam("issuerStage", uint256(IssuerStage.UnWithdrawCrowd));

                //根据当前融资额度获取投票手续费.
                uint256 totalFee = b.totalFee();
                uint256 voteFee = totalFee.mul(IConfig(config).ratingFeeRatio()).div(_1);

                //支持评级
                if (b.supportRedeem()) {
                    b.setBondParam("fee", voteFee);
                    b.setBondParam("sysProfit", totalFee.sub(voteFee));
                } else {
                    b.setBondParam("fee", 0);//无投票手续费
                    b.setBondParam("sysProfit", totalFee);//发债手续费全部归ForTube平台
                }
            }
        } else {
            b.setBondParam("bondStage", uint256(BondStage.CrowdFundingFail));
            b.setBondParam("issuerStage", uint256(IssuerStage.UnWithdrawPawn));
        }

        emit MonitorEvent(msg.sender, address(b), "interestBearingPeriod", abi.encodePacked());
    }

    //转出募集到的资金,只有债券发行者可以转出资金
    function txOutCrowdCb(address who, uint256 id) external auth returns (uint) {
        IBondData b = IBondData(bondData(id));
        require(d(id) != address(0) && b.issuerStage() == uint(IssuerStage.UnWithdrawCrowd) && b.issuer() == who, "only txout crowd once or require issuer");


        uint256 balance = coreUtils.transferableAmount(id);
        // safeTransferFrom(crowd, address(this), address(this), msg.sender, balance);

        b.setBondParam("issuerStage", uint256(IssuerStage.WithdrawCrowdSuccess));
        b.setBondParam("bondStage", uint256(BondStage.UnRepay));

        return balance;
    }

    function overdueCb(uint256 id) external auth {
        IBondData b = IBondData(bondData(id));
        require(now >= b.bondExpired().add(b.gracePeriod()) 
            && (b.bondStage() == uint(BondStage.UnRepay) || b.bondStage() == uint(BondStage.CrowdFundingSuccess) ), "invalid overdue call state");
        b.setBondParam("bondStage", uint256(BondStage.Overdue));
        emit MonitorEvent(msg.sender, address(b), "overdue", abi.encodePacked());
    }

    //发债方还款
    //id: 发行的债券id，唯一标志债券
    //get: 募集的token地址
    //amount: 还款数量
    function repayCb(address who, uint256 id) external auth returns (uint) {
        require(d(id) != address(0) && bondData(id).issuer() == who, "invalid address or issuer");
        IBondData b = bondData(id);
        //募资成功，起息后即可还款,只有未还款或者逾期中可以还款，债务被关闭或者抵押物被清算完，不用还款
        require(
            b.bondStage() == uint(BondStage.UnRepay) || b.bondStage() == uint(BondStage.Overdue),
            "invalid state"
        );

        //充值repayAmount token到合约中，充值之前需要approve
        //使用amountGet进行计算
        uint256 repayAmount = b.liability();
        b.setBondParam("liability", 0);

        //safeTransferFrom(crowd, msg.sender, address(this), address(this), repayAmount);

        b.setBondParam("bondStage", uint256(BondStage.RepaySuccess));
        b.setBondParam("issuerStage", uint256(IssuerStage.UnWithdrawPawn));

        //清算一部分后,正常还款，需要设置清算中为false
        if (b.liquidating()) {
            b.setLiquidating(false);
        }

        return repayAmount;
    }

    //发债方取回质押token,在发债方已还清贷款的情况下，可以取回质押品
    //id: 发行的债券id，唯一标志债券
    //pawn: 抵押的token地址
    //amount: 取回数量
    function withdrawPawnCb(address who, uint256 id) external auth returns (uint) {
        IBondData b = bondData(id);
        require(d(id) != address(0) 
            && b.issuer() == who
            && b.issuerStage() == uint256(IssuerStage.UnWithdrawPawn), "invalid issuer, txout state or address");

        b.setBondParam("issuerStage", uint256(IssuerStage.WithdrawPawnSuccess));
        uint256 borrowGive = b.getBorrowAmountGive();
        //刚好结清债务和抵押物均为0（b.issuerStage() == uint256(IssuerStage.DebtClosed)）时，不能取回抵押物
        require(borrowGive > 0, "invalid give amount");
        b.setBondParam("borrowAmountGive", 0);//更新抵押品数量为0

        return borrowGive;
    }

    //募资失败，投资人凭借"债券"取回本金
    function withdrawPrincipalCb(address who, uint256 id)
        external
        auth
        returns (uint256)
    {
        IBondData b = bondData(id);

        //募资完成, 但是未募资成功.
        require(d(id) != address(0) && 
            b.bondStage() == uint(BondStage.CrowdFundingFail),
            "must crowdfunding failure"
        );

        (uint256 supplyGive) = b.getSupplyAmount(who);
        //safeTransferFrom(give, address(this), address(this), msg.sender, supplyGive);

        uint256 bondAmount = coreUtils.convert2BondAmount(
            address(b),
            b.crowdToken(),
            supplyGive
        );
        b.burnBond(who, bondAmount);


        return supplyGive;
    }

    //债券到期, 投资人取回本金和收益
    function withdrawPrincipalAndInterestCb(address who, uint256 id)
        external
        auth
        returns (uint256)
    {
        IBondData b = bondData(id);
        //募资成功，并且债券到期
        require(d(id) != address(0) && (
            b.bondStage() == uint(BondStage.RepaySuccess)
            || b.bondStage() == uint(BondStage.DebtClosed)),
            "unrepay or unliquidate"
        );


        (uint256 supplyGive) = b.getSupplyAmount(who);
        uint256 bondAmount = coreUtils.convert2BondAmount(
            address(b),
            b.crowdToken(),
            supplyGive
        );

        uint256 actualRepay = coreUtils.investPrincipalWithInterest(id, who);

        //safeTransferFrom(give, address(this), address(this), msg.sender, actualRepay);

        b.burnBond(who, bondAmount);


        return actualRepay;
    }

    function abs(uint256 a, uint256 b) internal pure returns (uint c) {
        c = a >= b ? a.sub(b) : b.sub(a);
    }

    function liquidateInternal(address who, uint256 id, uint y1, uint x1) internal returns (uint256, uint256, uint256, uint256) {
        IBondData b = bondData(id);
        require(b.issuer() != who, "can't self-liquidate");

        //当前已经处于清算中状态
        if (b.liquidating()) {
            bool depositMultipleUnsafe = coreUtils.isDepositMultipleUnsafe(id);
            require(depositMultipleUnsafe, "in depositMultiple safe state");
        } else {
            require(coreUtils.isUnsafe(id), "in safe state");

            //设置为清算中状态
            b.setLiquidating(true);
        }

        uint256 balance = IERC20(b.crowdToken()).balanceOf(who);
        uint256 y = coreUtils.Y(id);
        uint256 x = coreUtils.X(id);

        require(balance >= y1 && y1 <= y, "insufficient y1 or balance");

        if (y1 == b.liability() || abs(y1, b.liability()) <= uint256(1) 
        || x1 == b.getBorrowAmountGive() 
        || abs(x1, b.getBorrowAmountGive()) <= coreUtils.precision(id)) {
            b.setBondParam("bondStage", uint(BondStage.DebtClosed));
            b.setLiquidating(false);
        }

        if (y1 == b.liability() || abs(y1, b.liability()) <= uint256(1)) {
            if (!(x1 == b.getBorrowAmountGive() || abs(x1, b.getBorrowAmountGive()) <= coreUtils.precision(id))) {
                b.setBondParam("issuerStage", uint(IssuerStage.UnWithdrawPawn));
            }
        }

        //对债务误差为1的处理
        if (abs(y1, b.liability()) <= uint256(1)) {
            b.setBondParam("liability", 0);
        } else {
            b.setBondParam("liability", b.liability().sub(y1));
        }

        if (abs(x1, b.getBorrowAmountGive()) <= coreUtils.precision(id)) {
            b.setBondParam("borrowAmountGive", 0);
        } else {
            b.setBondParam("borrowAmountGive", b.getBorrowAmountGive().sub(x1));
        }


        if (!coreUtils.isDepositMultipleUnsafe(id)) {
            b.setLiquidating(false);
        }

        if (coreUtils.isDebtOpen(id)) {
            b.setBondParam("sysProfit", b.sysProfit().add(b.fee()));
            b.setBondParam("fee", 0);
        }

        return (y1, x1, y, x);
    }

    //分批清算债券接口
    //id: 债券发行id，同上
    function liquidateCb(address who, uint256 id, uint256 y1)
        external
        auth
        returns (uint256, uint256, uint256, uint256)
    {
        (uint y, uint x) = coreUtils.getLiquidateAmount(id, y1);

        return liquidateInternal(who, id, y, x);
    }

    //取回系统盈利
    function withdrawSysProfitCb(address who, uint256 id) external auth returns (uint256) {
        IBondData b = bondData(id);
        uint256 _sysProfit = b.sysProfit();
        require(_sysProfit > 0, "no withdrawable sysProfit");
        b.setBondParam("sysProfit", 0);
        return _sysProfit;
    }
}