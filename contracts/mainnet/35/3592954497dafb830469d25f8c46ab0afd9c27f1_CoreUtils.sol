/**
 *Submitted for verification at Etherscan.io on 2020-07-21
*/

/**
 *Submitted for verification at Etherscan.io on 2020-07-20
*/

/**
 *Submitted for verification at Etherscan.io on 2020-07-17
*/

pragma experimental ABIEncoderV2;
pragma solidity ^0.6.0;


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

contract CoreUtils {
    using SafeMath for uint256;

    address public router;
    address public oracle;

    constructor (address _router, address _oracle) public {
        router = _router;
        oracle = _oracle;
    }

    function d(uint256 id) public view returns (address) {
        return IRouter(router).defaultDataContract(id);
    }

    function bondData(uint256 id) public view returns (IBondData) {
        return IBondData(d(id));
    }

    //principal + interest = principal * (1 + couponRate);
    function calcPrincipalAndInterest(uint256 principal, uint256 couponRate)
        public
        pure
        returns (uint256)
    {
        uint256 _1 = 1 ether;
        return principal.mul(_1.add(couponRate)).div(_1);
    }

    //可转出金额,募集到的总资金减去给所有投票人的手续费
    function transferableAmount(uint256 id) external view returns (uint256) {
        IBondData b = bondData(id);
        uint256 baseDec = 18;
        uint256 delta = baseDec.sub(
            uint256(ERC20Detailed(b.crowdToken()).decimals())
        );
        uint256 _1 = 1 ether;
        //principal * (1-0.05) * 1e18/(10** (18 - 6))
        return
            b.actualBondIssuance().mul(b.par()).mul((_1).sub(b.issueFee())).div(
                10**delta
            );
    }

    //总的募集资金量
    function debt(uint256 id) public view returns (uint256) {
        IBondData b = bondData(id);
        uint256 crowdDec = ERC20Detailed(b.crowdToken()).decimals();
        return b.actualBondIssuance().mul(b.par()).mul(10**crowdDec);
    }

    //总的募集资金量
    function totalInterest(uint256 id) external view returns (uint256) {
        IBondData b = bondData(id);
        uint256 crowdDec = ERC20Detailed(b.crowdToken()).decimals();
        return
            b
                .actualBondIssuance()
                .mul(b.par())
                .mul(10**crowdDec)
                .mul(b.couponRate())
                .div(1e18);
    }

    function debtPlusTotalInterest(uint256 id) public view returns (uint256) {
        IBondData b = bondData(id);
        uint256 crowdDec = ERC20Detailed(b.crowdToken()).decimals();
        uint256 _1 = 1 ether;
        return
            b
                .actualBondIssuance()
                .mul(b.par())
                .mul(10**crowdDec)
                .mul(_1.add(b.couponRate()))
                .div(1e18);
    }

    function CollateralDecimal(uint256 id) public view returns (uint256) {
        IBondData b = bondData(id);
        if (b.collateralToken() == address(0)) return 18;//ETH
        if (keccak256(abi.encodePacked(IERC20Detailed(b.collateralToken()).symbol())) == keccak256(abi.encodePacked(string("BAT")))) return 18;
        return ERC20Detailed(b.collateralToken()).decimals();
    }

    //可投资的剩余份数
    function remainInvestAmount(uint256 id) external view returns (uint256) {
        IBondData b = bondData(id);

        uint256 crowdDec = ERC20Detailed(b.crowdToken()).decimals();
        return
            b.totalBondIssuance().div(10**crowdDec).div(b.par()).sub(
                b.actualBondIssuance()
            );
    }

        function calcMinCollateralTokenAmount(uint256 id)
        external
        view
        returns (uint256)
    {
        IBondData b = bondData(id);
        uint256 CollateralDec = CollateralDecimal(id);
        uint256 crowdDec = ERC20Detailed(b.crowdToken()).decimals();

        //fix safemath mul overflow bug when crowddec is 18, eg. DAI, BUSD
        uint256 unit = 10 ** (crowdDec.add(18).sub(CollateralDec));


        return
            b
                .totalBondIssuance()
                .mul(b.depositMultiple())
                .mul(crowdPrice(id))
                .div(pawnPrice(id))
                .div(unit);
    }

    function pawnBalanceInUsd(uint256 id) public view returns (uint256) {
        IBondData b = bondData(id);

        uint256 unitPawn = 10 **
            uint256(CollateralDecimal(id));
        uint256 pawnUsd = pawnPrice(id).mul(b.getBorrowAmountGive()).div(unitPawn); //1e18
        return pawnUsd;
    }

    function disCountPawnBalanceInUsd(uint256 id)
        public
        view
        returns (uint256)
    {
        uint256 _1 = 1 ether;
        IBondData b = bondData(id);

        return pawnBalanceInUsd(id).mul(b.discount()).div(_1);
    }

    function crowdBalanceInUsd(uint256 id) public view returns (uint256) {
        IBondData b = bondData(id);

        uint256 unitCrowd = 10 **
            uint256(ERC20Detailed(b.crowdToken()).decimals());
        return crowdPrice(id).mul(b.liability()).div(unitCrowd);
    }

    //资不抵债判断，资不抵债时，为true，否则为false
    function isInsolvency(uint256 id) public view returns (bool) {
        return disCountPawnBalanceInUsd(id) < crowdBalanceInUsd(id);
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a <= b ? a : b;
    }

    //获取质押的代币价格
    function pawnPrice(uint256 id) public view returns (uint256) {
        IBondData b = bondData(id);

        (uint256 price, bool pawnPriceOk) = IOracle(oracle).get(b.collateralToken());
        require(pawnPriceOk, "invalid pawn price");
        return price;
    }

    //获取募资的代币价格
    function crowdPrice(uint256 id) public view returns (uint256) {
        IBondData b = bondData(id);

        (uint256 price, bool crowdPriceOk) = IOracle(oracle).get(b.crowdToken());
        require(crowdPriceOk, "invalid crowd price");
        return price;
    }

    //要清算的质押物数量
    //X = (AC*price - PCR*PD)/(price*(1-PCR*Discount))
    //X = (PCR*PD - AC*price)/(price*(PCR*Discount-1))
    function X(uint256 id) public view returns (uint256 res) {
        IBondData b = bondData(id);

        if (!isUnsafe(id)) {
            return 0;
        }

        //若质押资产不能清偿债务,全额清算
        if (isInsolvency(id)) {
            return b.getBorrowAmountGive();
        }

        //逾期未还款
        if (now >= b.bondExpired().add(b.gracePeriod())) {
            return calcLiquidatePawnAmount(id);
        }

        uint256 _1 = 1 ether;
        uint256 price = pawnPrice(id); //1e18
        uint256 pawnUsd = pawnBalanceInUsd(id);
        uint256 debtUsd = crowdBalanceInUsd(id).mul(b.depositMultiple()).div(_1);

        uint256 gap = pawnUsd >= debtUsd
            ? pawnUsd.sub(debtUsd)
            : debtUsd.sub(pawnUsd);
        uint256 pcrXdis = b.depositMultiple().mul(b.discount()).div(_1); //1e18
        require(pcrXdis != _1, "PCR*Discout == 1 error");
        pcrXdis = pawnUsd >= debtUsd ? _1.sub(pcrXdis) : pcrXdis.sub(_1);
        uint256 denominator = price.mul(pcrXdis).div(_1); //1e18
        uint256 unitPawn = 10 **
            uint256(CollateralDecimal(id));
        res = gap.mul(unitPawn).div(denominator); //1e18/1e18*1e18 == 1e18

        res = min(res, b.getBorrowAmountGive());
    }

    //清算额，减少的债务
    //X*price(collater)*Discount/price(crowd)
    function Y(uint256 id) public view returns (uint256 res) {
        IBondData b = bondData(id);

        if (!isUnsafe(id)) {
            return 0;
        }

        uint256 _1 = 1 ether;
        uint256 unitPawn = 10 **
            uint256(CollateralDecimal(id));
        uint256 xp = X(id).mul(pawnPrice(id)).div(unitPawn);
        xp = xp.mul(b.discount()).div(_1);

        uint256 unitCrowd = 10 **
            uint256(ERC20Detailed(b.crowdToken()).decimals());
        res = xp.mul(unitCrowd).div(crowdPrice(id));

        res = min(res, b.liability());
    }

    //到期后，由系统债务算出需要清算的抵押物数量
    function calcLiquidatePawnAmount(uint256 id) public view returns (uint256) {
        IBondData b = bondData(id);
        return calcLiquidatePawnAmount(id, b.liability());
    }
    
    //return ((a + m - 1) / m) * m;
    function ceil(uint256 a, uint256 m) public pure returns (uint256) {
        return (a.add(m).sub(1)).div(m).mul(m);
    }
    
    function precision(uint256 id) public view returns (uint256) {
        uint256 decPawn = uint256(CollateralDecimal(id));

        uint256 minUsdValue = 1e15;
        return minUsdValue.mul(10 ** decPawn).div(pawnPrice(id));
    }
    
    function ceilPawn(uint256 id, uint256 a) public view returns (uint256) {
        IBondData b = bondData(id);
        
        uint256 decCrowd = uint256(ERC20Detailed(b.crowdToken()).decimals());
        uint256 decPawn = uint256(CollateralDecimal(id));
        
        if (decPawn != decCrowd) {
            a = ceil(a, 10 ** abs(decPawn, decCrowd).sub(1));
        } else {
            a = ceil(a, 10);
        }

        return a;
    }
    
    //到期后，由系统债务算出需要清算的抵押物数量
    function calcLiquidatePawnAmount(uint256 id, uint256 liability) public view returns (uint256) {
        IBondData b = bondData(id);

        uint256 _crowdPrice = crowdPrice(id);
        uint256 _pawnPrice = pawnPrice(id);

        uint256 decPawn = uint256(CollateralDecimal(id));
        uint256 decCrowd = uint256(ERC20Detailed(b.crowdToken()).decimals());

        //fix safemath mul overflow bug when decCrowd is 18, eg. DAI, BUSD
        uint256 unit = 10 ** (decPawn.add(18).sub(decCrowd));

        uint256 x = liability
            .mul(_crowdPrice)
            .mul(unit)
            .div(_pawnPrice.mul(b.discount()));

        uint256 _x1 = liability.mul(_crowdPrice).mul(unit);
        uint256 _x2 = _pawnPrice.mul(b.discount());
        if (x.mul(_x2) != _x1) {
            x = x.add(1);
        }

        
        x = min(x, b.getBorrowAmountGive());


        return x;
    }

    function investPrincipalWithInterest(uint256 id, address who)
        external
        view
        returns (uint256)
    {
        require(d(id) != address(0), "invalid address");

        IBondData bond = bondData(id);
        address give = bond.crowdToken();

        (uint256 supplyGive) = bond.getSupplyAmount(who);
        uint256 bondAmount = convert2BondAmount(
            address(bond),
            give,
            supplyGive
        );

        uint256 crowdDec = IERC20Detailed(bond.crowdToken()).decimals();

        uint256 unrepayAmount = bond.liability(); //未还的债务
        uint256 actualRepay;

        if (unrepayAmount == 0) {
            actualRepay = calcPrincipalAndInterest(
                bondAmount.mul(1e18),
                bond.couponRate()
            );
            actualRepay = actualRepay.mul(bond.par()).mul(10**crowdDec).div(
                1e18
            );
        } else {
            //计算投资占比分之一,投资人亏损情况，从已还款（总债务-未还债务）中按比例分
            uint256 debtTotal = debtPlusTotalInterest(id);
            require(
                debtTotal >= unrepayAmount,
                "debtPlusTotalInterest < borrowGet, overflow"
            );
            actualRepay = debtTotal
                .sub(unrepayAmount)
                .mul(bondAmount)
                .div(bond.actualBondIssuance());
        }

        return actualRepay;
    }

    //bond:
    function convert2BondAmount(address b, address t, uint256 amount)
        public
        view
        returns (uint256)
    {
        IERC20Detailed erc20 = IERC20Detailed(t);
        uint256 dec = uint256(erc20.decimals());
        uint256 _par = IBondData(b).par();
        uint256 minAmount = _par.mul(10**dec);
        require(amount.mod(minAmount) == 0, "invalid amount"); //投资时，必须按份买

        return amount.div(minAmount);
    }

    function abs(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a >= b ? a.sub(b) : b.sub(a);
    }

    //bond:
    function convert2GiveAmount(uint256 id, uint256 bondAmount)
        external
        view
        returns (uint256)
    {
        IBondData b = bondData(id);

        ERC20Detailed erc20 = ERC20Detailed(b.crowdToken());
        uint256 dec = uint256(erc20.decimals());
        return bondAmount.mul(b.par()).mul(10**dec);
    }

    //判断是否回到原始质押率(400%),回到后，设置为false，否则为true
    function isDepositMultipleUnsafe(uint256 id) external view returns (bool unsafe) {
        IBondData b = bondData(id);

        if (b.liability() == 0 || b.getBorrowAmountGive() == 0) {
            return false;
        }

        if (b.bondStage() == uint(BondStage.CrowdFundingSuccess)
            || b.bondStage() == uint(BondStage.UnRepay)
            || b.bondStage() == uint(BondStage.Overdue)) {

            if (now >= b.bondExpired().add(b.gracePeriod())) {
                return true;
            }

            uint256 _1 = 1 ether;
            uint256 crowdUsdxLeverage = crowdBalanceInUsd(id)
                .mul(b.depositMultiple())
                .div(1e36);

            //CCR < 4
            //pawnUsd/crowdUsd < 4
            //unsafe = pawnBalanceInUsd(id) < crowdUsdxLeverage;
            
            uint256 _ceilPawn = ceil(pawnBalanceInUsd(id), 10);
            
            uint256 _crowdPrice = crowdPrice(id);
            uint256 decCrowd = uint256(ERC20Detailed(b.crowdToken()).decimals());
            uint256 minCrowdInUsd = _crowdPrice.div(10 ** decCrowd);
            
            unsafe = _ceilPawn < crowdUsdxLeverage;
            if (abs(_ceilPawn, crowdUsdxLeverage) <= minCrowdInUsd && _ceilPawn < crowdUsdxLeverage) {
                unsafe = false;
            }
            return unsafe;
        }
        
        return false;
    }

    function isDebtOpen(uint256 id) public view returns (bool) {
        IBondData b = bondData(id);
        uint256 decCrowd = uint256(ERC20Detailed(b.crowdToken()).decimals());
        uint256 _crowdPrice = crowdPrice(id);
        //1e15 is 0.001$
        return b.liability().mul(_crowdPrice).div(10 ** decCrowd) > 1e15 && b.getBorrowAmountGive() == 0;
    }

    //融资时是否满足最小发行比率，将core中的logic检查放到这里，减少core的字节码大小
    function isMinIssuanceCheckOK(uint256 id) public view returns (bool ok) {
        IBondData b = bondData(id);
        return b.totalBondIssuance().mul(b.minIssueRatio()).div(1e18) <= debt(id);
    }
    
    function isUnsafe(uint256 id) public view returns (bool unsafe) {
        IBondData b = bondData(id);
        uint256 decCrowd = uint256(ERC20Detailed(b.crowdToken()).decimals());
        uint256 _crowdPrice = crowdPrice(id);
        //1e15 is 0.001$
        if (b.liability().mul(_crowdPrice).div(10 ** decCrowd) <= 1e15 || b.getBorrowAmountGive() == 0) {
            return false;
        }

        if (b.liquidating()) {
            return true;
        }

        if (b.bondStage() == uint(BondStage.CrowdFundingSuccess)
            || b.bondStage() == uint(BondStage.UnRepay)
            || b.bondStage() == uint(BondStage.Overdue)) {

            if (now >= b.bondExpired().add(b.gracePeriod())) {
                return true;
            }

            uint256 _1 = 1 ether;
            uint256 crowdUsdxLeverage = crowdBalanceInUsd(id)
                .mul(b.depositMultiple())
                .mul(b.liquidateLine())
                .div(1e36);

            //CCR < 0.7 * 4
            //pawnUsd/crowdUsd < 0.7*4
            //unsafe = pawnBalanceInUsd(id) < crowdUsdxLeverage;
            
            uint256 _ceilPawn = ceilPawn(id, pawnBalanceInUsd(id));
            


            uint256 minCrowdInUsd = _crowdPrice.div(10 ** decCrowd);
            
            unsafe = _ceilPawn < crowdUsdxLeverage;
            if (abs(_ceilPawn, crowdUsdxLeverage) <= minCrowdInUsd && _ceilPawn < crowdUsdxLeverage) {
                unsafe = false;
            }
            return unsafe;
        }
        
        return false;
    }

    //获取实际需要的清算数量
    function getLiquidateAmount(uint id, uint y1) external view returns (uint256, uint256) {
        uint256 y2 = y1;//y2为实际清算额度
        uint256 y = Y(id);//y为剩余清算额度
        require(y1 <= y, "exceed max liquidate amount");

        //剩余额度小于一次清算量，将剩余额度全部清算
        IBondData b = bondData(id);

        uint decUnit = 10 ** uint(IERC20Detailed(b.crowdToken()).decimals());
        if (y <= b.partialLiquidateAmount()) {
            y2 = y;
        } else {
           require(y1 >= decUnit, "below min liquidate amount");//设置最小清算额度为1单位
        }
        uint256 x = calcLiquidatePawnAmount(id, y2);
        return (y2, x);
    }
}