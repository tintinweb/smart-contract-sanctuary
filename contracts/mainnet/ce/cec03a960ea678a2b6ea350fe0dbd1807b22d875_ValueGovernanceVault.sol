// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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

/**
 * @dev Collection of functions related to the address type
 */
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
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
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
    using Address for address;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
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
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

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
     * - the caller must have allowance for ``sender``'s tokens of at least
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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

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

        _beforeTokenTransfer(sender, recipient, amount);

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

        _beforeTokenTransfer(address(0), account, amount);

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

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

interface IController {
    function vaults(address) external view returns (address);
    function rewards() external view returns (address);
    function want(address) external view returns (address);
    function balanceOf(address) external view returns (uint);
    function withdraw(address, uint) external;
    function maxAcceptAmount(address) external view returns (uint256);
    function earn(address, uint) external;

    function getStrategyCount(address _vault) external view returns(uint256);
    function depositAvailable(address _vault) external view returns(bool);
    function harvestAllStrategies(address _vault) external;
    function harvestStrategy(address _vault, address _strategy) external;
}

interface ITokenInterface is IERC20 {
    /** VALUE, YFV, vUSD, vETH has minters **/
    function minters(address account) external view returns (bool);
    function mint(address _to, uint _amount) external;

    /** YFV <-> VALUE **/
    function deposit(uint _amount) external;
    function withdraw(uint _amount) external;
    function cap() external returns (uint);
    function yfvLockedBalance() external returns (uint);
}

interface IYFVReferral {
    function setReferrer(address farmer, address referrer) external;
    function getReferrer(address farmer) external view returns (address);
}

interface IFreeFromUpTo {
    function freeFromUpTo(address from, uint valueToken) external returns (uint freed);
}

contract ValueGovernanceVault is ERC20 {
    using Address for address;
    using SafeMath for uint;

    IFreeFromUpTo public constant chi = IFreeFromUpTo(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);

    modifier discountCHI(uint8 _flag) {
        if ((_flag & 0x1) == 0) {
            _;
        } else {
            uint gasStart = gasleft();
            _;
            uint gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
            chi.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41130);
        }
    }

    ITokenInterface public yfvToken; // stake and wrap to VALUE
    ITokenInterface public valueToken; // stake and reward token
    ITokenInterface public vUSD; // reward token
    ITokenInterface public vETH; // reward token

    uint public fundCap = 9500; // use up to 95% of fund (to keep small withdrawals cheap)
    uint public constant FUND_CAP_DENOMINATOR = 10000;

    uint public earnLowerlimit;

    address public governance;
    address public controller;
    address public rewardReferral;

    // Info of each user.
    struct UserInfo {
        uint amount;
        uint valueRewardDebt;
        uint vusdRewardDebt;
        uint lastStakeTime;
        uint accumulatedStakingPower; // will accumulate every time user harvest

        uint lockedAmount;
        uint lockedDays; // 7 days -> 150 days (5 months)
        uint boostedExtra; // times 1e12 (285200000000 -> +28.52%). See below.
        uint unlockedTime;
    }

    uint maxLockedDays = 150;

    uint lastRewardBlock;  // Last block number that reward distribution occurs.
    uint accValuePerShare; // Accumulated VALUEs per share, times 1e12. See below.
    uint accVusdPerShare; // Accumulated vUSD per share, times 1e12. See below.

    uint public valuePerBlock; // 0.2 VALUE/block at start
    uint public vusdPerBlock; // 5 vUSD/block at start

    mapping(address => UserInfo) public userInfo;
    uint public totalDepositCap;

    uint public constant vETH_REWARD_FRACTION_RATE = 1000;
    uint public minStakingAmount = 0 ether;
    uint public unstakingFrozenTime = 40 hours;
    // ** unlockWithdrawFee = 1.92%: stakers will need to pay 1.92% (sent to insurance fund) of amount they want to withdraw if the coin still frozen
    uint public unlockWithdrawFee = 192; // per ten thousand (eg. 15 -> 0.15%)
    address public valueInsuranceFund = 0xb7b2Ea8A1198368f950834875047aA7294A2bDAa; // set to Governance Multisig at start

    event Deposit(address indexed user, uint amount);
    event Withdraw(address indexed user, uint amount);
    event RewardPaid(address indexed user, uint reward);
    event CommissionPaid(address indexed user, uint reward);
    event Locked(address indexed user, uint amount, uint _days);
    event EmergencyWithdraw(address indexed user, uint amount);

    constructor (ITokenInterface _yfvToken,
        ITokenInterface _valueToken,
        ITokenInterface _vUSD,
        ITokenInterface _vETH,
        uint _valuePerBlock,
        uint _vusdPerBlock,
        uint _startBlock) public ERC20("GovVault:ValueLiquidity", "gvVALUE") {
        yfvToken = _yfvToken;
        valueToken = _valueToken;
        vUSD = _vUSD;
        vETH = _vETH;
        valuePerBlock = _valuePerBlock;
        vusdPerBlock = _vusdPerBlock;
        lastRewardBlock = _startBlock;
        governance = msg.sender;
    }

    function balance() public view returns (uint) {
        uint bal = valueToken.balanceOf(address(this));
        if (controller != address(0)) bal = bal.add(IController(controller).balanceOf(address(valueToken)));
        return bal;
    }

    function setFundCap(uint _fundCap) external {
        require(msg.sender == governance, "!governance");
        fundCap = _fundCap;
    }

    function setTotalDepositCap(uint _totalDepositCap) external {
        require(msg.sender == governance, "!governance");
        totalDepositCap = _totalDepositCap;
    }

    function setGovernance(address _governance) public {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function setController(address _controller) public {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }

    function setRewardReferral(address _rewardReferral) external {
        require(msg.sender == governance, "!governance");
        rewardReferral = _rewardReferral;
    }

    function setEarnLowerlimit(uint _earnLowerlimit) public {
        require(msg.sender == governance, "!governance");
        earnLowerlimit = _earnLowerlimit;
    }

    function setMaxLockedDays(uint _maxLockedDays) public {
        require(msg.sender == governance, "!governance");
        maxLockedDays = _maxLockedDays;
    }

    function setValuePerBlock(uint _valuePerBlock) public {
        require(msg.sender == governance, "!governance");
        require(_valuePerBlock <= 10 ether, "Too big _valuePerBlock"); // <= 10 VALUE
        updateReward();
        valuePerBlock = _valuePerBlock;
    }

    function setVusdPerBlock(uint _vusdPerBlock) public {
        require(msg.sender == governance, "!governance");
        require(_vusdPerBlock <= 200 * (10 ** 9), "Too big _vusdPerBlock"); // <= 200 vUSD
        updateReward();
        vusdPerBlock = _vusdPerBlock;
    }

    function setMinStakingAmount(uint _minStakingAmount) public {
        require(msg.sender == governance, "!governance");
        minStakingAmount = _minStakingAmount;
    }

    function setUnstakingFrozenTime(uint _unstakingFrozenTime) public {
        require(msg.sender == governance, "!governance");
        unstakingFrozenTime = _unstakingFrozenTime;
    }

    function setUnlockWithdrawFee(uint _unlockWithdrawFee) public {
        require(msg.sender == governance, "!governance");
        require(_unlockWithdrawFee <= 1000, "Dont be too greedy"); // <= 10%
        unlockWithdrawFee = _unlockWithdrawFee;
    }

    function setValueInsuranceFund(address _valueInsuranceFund) public {
        require(msg.sender == governance, "!governance");
        valueInsuranceFund = _valueInsuranceFund;
    }

    // To upgrade vUSD contract (v1 is still experimental, we may need vUSDv2 with rebase() function working soon - then governance will call this upgrade)
    function upgradeVUSDContract(address _vUSDContract) public {
        require(msg.sender == governance, "!governance");
        vUSD = ITokenInterface(_vUSDContract);
    }

    // To upgrade vETH contract (v1 is still experimental, we may need vETHv2 with rebase() function working soon - then governance will call this upgrade)
    function upgradeVETHContract(address _vETHContract) public {
        require(msg.sender == governance, "!governance");
        vETH = ITokenInterface(_vETHContract);
    }

    // Custom logic in here for how much the vault allows to be borrowed
    // Sets minimum required on-hand to keep small withdrawals cheap
    function available() public view returns (uint) {
        return valueToken.balanceOf(address(this)).mul(fundCap).div(FUND_CAP_DENOMINATOR);
    }

    function earn(uint8 _flag) public discountCHI(_flag) {
        if (controller != address(0)) {
            uint _amount = available();
            uint _accepted = IController(controller).maxAcceptAmount(address(valueToken));
            if (_amount > _accepted) _amount = _accepted;
            if (_amount > 0) {
                yfvToken.transfer(controller, _amount);
                IController(controller).earn(address(yfvToken), _amount);
            }
        }
    }

    function getRewardAndDepositAll(uint8 _flag) external discountCHI(_flag) {
        unstake(0, 0x0);
        depositAll(address(0), 0x0);
    }

    function depositAll(address _referrer, uint8 _flag) public discountCHI(_flag) {
        deposit(valueToken.balanceOf(msg.sender), _referrer, 0x0);
    }

    function deposit(uint _amount, address _referrer, uint8 _flag) public discountCHI(_flag) {
        uint _pool = balance();
        uint _before = valueToken.balanceOf(address(this));
        valueToken.transferFrom(msg.sender, address(this), _amount);
        uint _after = valueToken.balanceOf(address(this));
        require(totalDepositCap == 0 || _after <= totalDepositCap, ">totalDepositCap");
        _amount = _after.sub(_before); // Additional check for deflationary tokens
        uint _shares = _deposit(address(this), _pool, _amount);
        _stakeShares(msg.sender, _shares, _referrer);
    }

    function depositYFV(uint _amount, address _referrer, uint8 _flag) public discountCHI(_flag) {
        uint _pool = balance();
        yfvToken.transferFrom(msg.sender, address(this), _amount);
        uint _before = valueToken.balanceOf(address(this));
        yfvToken.approve(address(valueToken), 0);
        yfvToken.approve(address(valueToken), _amount);
        valueToken.deposit(_amount);
        uint _after = valueToken.balanceOf(address(this));
        require(totalDepositCap == 0 || _after <= totalDepositCap, ">totalDepositCap");
        _amount = _after.sub(_before); // Additional check for deflationary tokens
        uint _shares = _deposit(address(this), _pool, _amount);
        _stakeShares(msg.sender, _shares, _referrer);
    }

    function buyShares(uint _amount, uint8 _flag) public discountCHI(_flag) {
        uint _pool = balance();
        uint _before = valueToken.balanceOf(address(this));
        valueToken.transferFrom(msg.sender, address(this), _amount);
        uint _after = valueToken.balanceOf(address(this));
        require(totalDepositCap == 0 || _after <= totalDepositCap, ">totalDepositCap");
        _amount = _after.sub(_before); // Additional check for deflationary tokens
        _deposit(msg.sender, _pool, _amount);
    }

    function depositShares(uint _shares, address _referrer, uint8 _flag) public discountCHI(_flag) {
        require(totalDepositCap == 0 || balance().add(_shares) <= totalDepositCap, ">totalDepositCap");
        uint _before = balanceOf(address(this));
        IERC20(address(this)).transferFrom(msg.sender, address(this), _shares);
        uint _after = balanceOf(address(this));
        _shares = _after.sub(_before); // Additional check for deflationary tokens
        _stakeShares(msg.sender, _shares, _referrer);
    }

    function lockShares(uint _locked, uint _days, uint8 _flag) external discountCHI(_flag) {
        require(_days >= 7 && _days <= maxLockedDays, "_days out-of-range");
        UserInfo storage user = userInfo[msg.sender];
        if (user.unlockedTime < block.timestamp) {
            user.lockedAmount = 0;
        } else {
            require(_days >= user.lockedDays, "Extra days should not less than current locked days");
        }
        user.lockedAmount = user.lockedAmount.add(_locked);
        require(user.lockedAmount <= user.amount, "lockedAmount > amount");
        user.unlockedTime = block.timestamp.add(_days * 86400);
        // (%) = 5 + (lockedDays - 7) * 0.15
        user.boostedExtra = 50000000000 + (_days - 7) * 1500000000;
        emit Locked(msg.sender, user.lockedAmount, _days);
    }

    function _deposit(address _mintTo, uint _pool, uint _amount) internal returns (uint _shares) {
        _shares = 0;
        if (totalSupply() == 0) {
            _shares = _amount;
        } else {
            _shares = (_amount.mul(totalSupply())).div(_pool);
        }
        if (_shares > 0) {
            if (valueToken.balanceOf(address(this)) > earnLowerlimit) {
                earn(0x0);
            }
            _mint(_mintTo, _shares);
        }
    }

    function _stakeShares(address _account, uint _shares, address _referrer) internal {
        UserInfo storage user = userInfo[_account];
        require(minStakingAmount == 0 || user.amount.add(_shares) >= minStakingAmount, "<minStakingAmount");
        updateReward();
        _getReward();
        user.amount = user.amount.add(_shares);
        if (user.lockedAmount > 0 && user.unlockedTime < block.timestamp) {
            user.lockedAmount = 0;
        }
        user.valueRewardDebt = user.amount.mul(accValuePerShare).div(1e12);
        user.vusdRewardDebt = user.amount.mul(accVusdPerShare).div(1e12);
        user.lastStakeTime = block.timestamp;
        emit Deposit(_account, _shares);
        if (rewardReferral != address(0) && _account != address(0)) {
            IYFVReferral(rewardReferral).setReferrer(_account, _referrer);
        }
    }

    function unfrozenStakeTime(address _account) public view returns (uint) {
        return userInfo[_account].lastStakeTime + unstakingFrozenTime;
    }

    // View function to see pending VALUEs on frontend.
    function pendingValue(address _account) public view returns (uint _pending) {
        UserInfo storage user = userInfo[_account];
        uint _accValuePerShare = accValuePerShare;
        uint lpSupply = balanceOf(address(this));
        if (block.number > lastRewardBlock && lpSupply != 0) {
            uint numBlocks = block.number.sub(lastRewardBlock);
            _accValuePerShare = accValuePerShare.add(numBlocks.mul(valuePerBlock).mul(1e12).div(lpSupply));
        }
        _pending = user.amount.mul(_accValuePerShare).div(1e12).sub(user.valueRewardDebt);
        if (user.lockedAmount > 0 && user.unlockedTime >= block.timestamp) {
            uint _bonus = _pending.mul(user.lockedAmount.mul(user.boostedExtra).div(1e12)).div(user.amount);
            uint _ceilingBonus = _pending.mul(33).div(100); // 33%
            if (_bonus > _ceilingBonus) _bonus = _ceilingBonus; // Additional check to avoid insanely high bonus!
            _pending = _pending.add(_bonus);
        }
    }

    // View function to see pending vUSDs on frontend.
    function pendingVusd(address _account) public view returns (uint) {
        UserInfo storage user = userInfo[_account];
        uint _accVusdPerShare = accVusdPerShare;
        uint lpSupply = balanceOf(address(this));
        if (block.number > lastRewardBlock && lpSupply != 0) {
            uint numBlocks = block.number.sub(lastRewardBlock);
            _accVusdPerShare = accVusdPerShare.add(numBlocks.mul(vusdPerBlock).mul(1e12).div(lpSupply));
        }
        return user.amount.mul(_accVusdPerShare).div(1e12).sub(user.vusdRewardDebt);
    }

    // View function to see pending vETHs on frontend.
    function pendingVeth(address _account) public view returns (uint) {
        return pendingVusd(_account).div(vETH_REWARD_FRACTION_RATE);
    }

    function stakingPower(address _account) public view returns (uint) {
        return userInfo[_account].accumulatedStakingPower.add(pendingValue(_account));
    }

    function updateReward() public {
        if (block.number <= lastRewardBlock) {
            return;
        }
        uint lpSupply = balanceOf(address(this));
        if (lpSupply == 0) {
            lastRewardBlock = block.number;
            return;
        }
        uint _numBlocks = block.number.sub(lastRewardBlock);
        accValuePerShare = accValuePerShare.add(_numBlocks.mul(valuePerBlock).mul(1e12).div(lpSupply));
        accVusdPerShare = accVusdPerShare.add(_numBlocks.mul(vusdPerBlock).mul(1e12).div(lpSupply));
        lastRewardBlock = block.number;
    }

    function _getReward() internal {
        UserInfo storage user = userInfo[msg.sender];
        uint _pendingValue = user.amount.mul(accValuePerShare).div(1e12).sub(user.valueRewardDebt);
        if (_pendingValue > 0) {
            if (user.lockedAmount > 0) {
                if (user.unlockedTime < block.timestamp) {
                    user.lockedAmount = 0;
                } else {
                    uint _bonus = _pendingValue.mul(user.lockedAmount.mul(user.boostedExtra).div(1e12)).div(user.amount);
                    uint _ceilingBonus = _pendingValue.mul(33).div(100); // 33%
                    if (_bonus > _ceilingBonus) _bonus = _ceilingBonus; // Additional check to avoid insanely high bonus!
                    _pendingValue = _pendingValue.add(_bonus);
                }
            }
            user.accumulatedStakingPower = user.accumulatedStakingPower.add(_pendingValue);
            uint actualPaid = _pendingValue.mul(99).div(100); // 99%
            uint commission = _pendingValue - actualPaid; // 1%
            safeValueMint(msg.sender, actualPaid);
            address _referrer = address(0);
            if (rewardReferral != address(0)) {
                _referrer = IYFVReferral(rewardReferral).getReferrer(msg.sender);
            }
            if (_referrer != address(0)) { // send commission to referrer
                safeValueMint(_referrer, commission);
                CommissionPaid(_referrer, commission);
            } else { // send commission to valueInsuranceFund
                safeValueMint(valueInsuranceFund, commission);
                CommissionPaid(valueInsuranceFund, commission);
            }
        }
        uint _pendingVusd = user.amount.mul(accVusdPerShare).div(1e12).sub(user.vusdRewardDebt);
        if (_pendingVusd > 0) {
            safeVusdMint(msg.sender, _pendingVusd);
        }
    }

    function withdrawAll(uint8 _flag) public discountCHI(_flag) {
        UserInfo storage user = userInfo[msg.sender];
        uint _amount = user.amount;
        if (user.lockedAmount > 0) {
            if (user.unlockedTime < block.timestamp) {
                user.lockedAmount = 0;
            } else {
                _amount = user.amount.sub(user.lockedAmount);
            }
        }
        unstake(_amount, 0x0);
        withdraw(balanceOf(msg.sender), 0x0);
    }

    // Used to swap any borrowed reserve over the debt limit to liquidate to 'token'
    function harvest(address reserve, uint amount) external {
        require(msg.sender == controller, "!controller");
        require(reserve != address(valueToken), "token");
        ITokenInterface(reserve).transfer(controller, amount);
    }

    function unstake(uint _amount, uint8 _flag) public discountCHI(_flag) returns (uint _actualWithdraw) {
        updateReward();
        _getReward();
        UserInfo storage user = userInfo[msg.sender];
        _actualWithdraw = _amount;
        if (_amount > 0) {
            require(user.amount >= _amount, "stakedBal < _amount");
            if (user.lockedAmount > 0) {
                if (user.unlockedTime < block.timestamp) {
                    user.lockedAmount = 0;
                } else {
                    require(user.amount.sub(user.lockedAmount) >= _amount, "stakedBal-locked < _amount");
                }
            }
            user.amount = user.amount.sub(_amount);

            if (block.timestamp < user.lastStakeTime.add(unstakingFrozenTime)) {
                // if coin is still frozen and governance does not allow stakers to unstake before timer ends
                if (unlockWithdrawFee == 0 || valueInsuranceFund == address(0)) revert("Coin is still frozen");

                // otherwise withdrawFee will be calculated based on the rate
                uint _withdrawFee = _amount.mul(unlockWithdrawFee).div(10000);
                uint r = _amount.sub(_withdrawFee);
                if (_amount > r) {
                    _withdrawFee = _amount.sub(r);
                    _actualWithdraw = r;
                    IERC20(address(this)).transfer(valueInsuranceFund, _withdrawFee);
                    emit RewardPaid(valueInsuranceFund, _withdrawFee);
                }
            }

            IERC20(address(this)).transfer(msg.sender, _actualWithdraw);
        }
        user.valueRewardDebt = user.amount.mul(accValuePerShare).div(1e12);
        user.vusdRewardDebt = user.amount.mul(accVusdPerShare).div(1e12);
        emit Withdraw(msg.sender, _amount);
    }

    // No rebalance implementation for lower fees and faster swaps
    function withdraw(uint _shares, uint8 _flag) public discountCHI(_flag) {
        uint _userBal = balanceOf(msg.sender);
        if (_shares > _userBal) {
            uint _need = _shares.sub(_userBal);
            require(_need <= userInfo[msg.sender].amount, "_userBal+staked < _shares");
            uint _actualWithdraw = unstake(_need, 0x0);
            _shares = _userBal.add(_actualWithdraw); // may be less than expected due to unlockWithdrawFee
        }
        uint r = (balance().mul(_shares)).div(totalSupply());
        _burn(msg.sender, _shares);

        // Check balance
        uint b = valueToken.balanceOf(address(this));
        if (b < r) {
            uint _withdraw = r.sub(b);
            if (controller != address(0)) {
                IController(controller).withdraw(address(valueToken), _withdraw);
            }
            uint _after = valueToken.balanceOf(address(this));
            uint _diff = _after.sub(b);
            if (_diff < _withdraw) {
                r = b.add(_diff);
            }
        }

        valueToken.transfer(msg.sender, r);
    }

    function getPricePerFullShare() public view returns (uint) {
        return balance().mul(1e18).div(totalSupply());
    }

    function getStrategyCount() external view returns (uint) {
        return (controller != address(0)) ? IController(controller).getStrategyCount(address(this)) : 0;
    }

    function depositAvailable() external view returns (bool) {
        return (controller != address(0)) ? IController(controller).depositAvailable(address(this)) : false;
    }

    function harvestAllStrategies(uint8 _flag) public discountCHI(_flag) {
        if (controller != address(0)) {
            IController(controller).harvestAllStrategies(address(this));
        }
    }

    function harvestStrategy(address _strategy, uint8 _flag) public discountCHI(_flag) {
        if (controller != address(0)) {
            IController(controller).harvestStrategy(address(this), _strategy);
        }
    }

    // Safe valueToken mint, ensure it is never over cap and we are the current owner.
    function safeValueMint(address _to, uint _amount) internal {
        if (valueToken.minters(address(this)) && _to != address(0)) {
            uint totalSupply = valueToken.totalSupply();
            uint realCap = valueToken.cap().add(valueToken.yfvLockedBalance());
            if (totalSupply.add(_amount) > realCap) {
                valueToken.mint(_to, realCap.sub(totalSupply));
            } else {
                valueToken.mint(_to, _amount);
            }
        }
    }

    // Safe vUSD mint, ensure we are the current owner.
    // vETH will be minted together with fixed rate.
    function safeVusdMint(address _to, uint _amount) internal {
        if (vUSD.minters(address(this)) && _to != address(0)) {
            vUSD.mint(_to, _amount);
        }
        if (vETH.minters(address(this)) && _to != address(0)) {
            vETH.mint(_to, _amount.div(vETH_REWARD_FRACTION_RATE));
        }
    }

    // This is for governance in some emergency circumstances to release lock immediately for an account
    function governanceResetLocked(address _account) external {
        require(msg.sender == governance, "!governance");
        UserInfo storage user = userInfo[_account];
        user.lockedAmount = 0;
        user.lockedDays = 0;
        user.boostedExtra = 0;
        user.unlockedTime = 0;
    }

    // This function allows governance to take unsupported tokens out of the contract, since this pool exists longer than the others.
    // This is in an effort to make someone whole, should they seriously mess up.
    // There is no guarantee governance will vote to return these.
    // It also allows for removal of airdropped tokens.
    function governanceRecoverUnsupported(IERC20 _token, uint _amount, address _to) external {
        require(msg.sender == governance, "!governance");
        require(address(_token) != address(valueToken) || balance().sub(_amount) >= totalSupply(), "cant withdraw VALUE more than gvVALUE supply");
        _token.transfer(_to, _amount);
    }
}