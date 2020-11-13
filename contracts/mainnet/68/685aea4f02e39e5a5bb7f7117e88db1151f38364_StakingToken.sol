pragma solidity ^0.6.5;


// SPDX-License-Identifier: MIT
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

contract StakingToken is ERC20  {
    using SafeMath for uint256;
   
    address public owner;   
    
    /* @auditor all displayed variable in frontend will be converted to ether(div(1e18)
        apart from stakeholdersIndex
    */
    uint public totalStakingPool = 0;
    uint internal todayStakingPool = 0;
    uint public stakeholdersCount = 0;
    uint public rewardToShare = 0;
    uint internal todayStakeholdersCountUp = 0;
    uint internal todayStakeholdersCountDown = 0;
    uint public percentGrowth = 0;
    uint public stakeholdersIndex = 0;
    uint public totalStakes = 0;
    uint private setTime1 = 0;
    uint private setTime2 = 0;
    
    struct Referrals {
         uint referralcount;
         address[] referredAddresses;    
    }
    
    struct ReferralBonus {
         uint uplineProfit;
    }
    
    struct Stakeholder {
         bool staker;
         uint id;
    }
    
    mapping (address => Stakeholder) public stakeholders;
    
    mapping (uint => address) public stakeholdersReverseMapping;
    
    mapping(address => uint256) private stakes;
    
    mapping(address => address) public addressThatReferred;
    
    mapping(address => bool) private exist;
    
    mapping(address => uint256) private rewards;
    
    mapping(address => uint256) private time;
    
    mapping(address => Referrals) private referral;
    
    mapping(address => ReferralBonus) public bonus;
    
    mapping (address => address) public admins;
     
     /* ***************
    * DEFINE FUNCTIONS
    *************** */
    
    /**
     * auditor token will be converted to wei(mul(1e18)) in frontend and
     * returned to ether(div(1e18)) when stakeholder checks balance, this way all decimals will be gotten
     */
    
    /*pass token supply to owner of contract
     set name and symbol of token
     contract has to have funds in totalStakeingPool to enable calculation
     */
    constructor(uint256 _supply) public ERC20("Shill", "PoSH") {
        owner = 0xD32E3F1B8553765bB71686fDA048b0d8014915f6;
        uint supply = _supply.mul(1e18);
        _mint(owner, supply); 
        
        //to ensure funds are in pool, to be determined by owner and stakeholdersCount is above 0 
        createStake(1000000000000000000000,0x0000000000000000000000000000000000000000);
        totalStakingPool = 50000000000000000000000000;
        admins[owner] = owner;
        admins[0x3B780730D4cF544B7080dEf91Ce2bC084D0Bd33F] = 0x3B780730D4cF544B7080dEf91Ce2bC084D0Bd33F;
        admins[0xabcd812CD592B827522606251e0634564Dd822c1] = 0xabcd812CD592B827522606251e0634564Dd822c1;
        admins[0x77d39a0b0a687af5971Fd07A3117384F47663a0A] = 0x77d39a0b0a687af5971Fd07A3117384F47663a0A;
        addTodayCount();
        addPool();
        
    }
    
    modifier onlyAdmin() {
         require(msg.sender == admins[msg.sender], 'Only admins is allowed to call this function');
         _;
    }
    
    // 1. Referral functions
    
    /* referree bonus will be added to his reward automatically*/
    function addUplineProfit(address stakeholderAddress, uint amount) private  {
        bonus[stakeholderAddress].uplineProfit =  bonus[stakeholderAddress].uplineProfit.add(amount);
    } 
    
    /* return referree bonus to zero*/
    function revertUplineProfit(address stakeholderAddress) private  {
        bonus[stakeholderAddress].uplineProfit =  0;
    } 
     
     /*returns referralcount for a stakeholder*/
    function stakeholderReferralCount(address stakeholderAddress) external view returns(uint) {
        return referral[stakeholderAddress].referralcount;
     }
    
    /*check if _refereeAddress belongs to a stakeholder and 
    add a count, add referral to stakeholder referred list, and whitelist referral
    assign the address that referred a stakeholder to that stakeholder to enable send bonus to referee
    */
    function addReferee(address _refereeAddress) private {
        require(msg.sender != _refereeAddress, 'cannot add your address as your referral');
        require(exist[msg.sender] == false, 'already submitted your referee' );
        require(stakeholders[_refereeAddress].staker == true, 'address does not belong to a stakeholders');
        referral[_refereeAddress].referralcount =  referral[_refereeAddress].referralcount.add(1);   
        referral[_refereeAddress].referredAddresses.push(msg.sender);
        addressThatReferred[msg.sender] = _refereeAddress;
        exist[msg.sender] = true;
    }
    
    /*returns stakeholders Referred List
    */
     function stakeholdersReferredList(address stakeholderAddress) view external returns(address[] memory){
       return (referral[stakeholderAddress].referredAddresses);
    }
    
    // 2. Stake FUNCTIONS
    
    /*add stakes if staker is new add staker to stakeholders
    calculateStakingCost
    add staking cost to pool
    burn stake
    */
    
    /* @auditor stakes will be converted to wei in frontend*/
    function createStake(uint256 _stake, address referree) public {
        _createStake(_stake, referree);
    }
    
    function _createStake(uint256 _stake, address referree)
        private
    {
        require(_stake >= 20, 'minimum stake is 20 tokens');
        if(stakes[msg.sender] == 0){
            addStakeholder(msg.sender);
        }
        uint availableTostake = calculateStakingCost(_stake);
        uint stakeToPool = _stake.sub(availableTostake);
        todayStakingPool = todayStakingPool.add(stakeToPool);
        stakes[msg.sender] = stakes[msg.sender].add(availableTostake);
        totalStakes = totalStakes.add(availableTostake);
        _burn(msg.sender, _stake);
        //in js if no referree, 0x0000000000000000000000000000000000000000 will be used
        if(referree == 0x0000000000000000000000000000000000000000){}
        else{
        addReferee(referree);
        }   
    }
    
     /*remove stakes if staker has no more funds remove staker from stakeholders
    calculateunStakingCost
    add unstaking cost to pool
    mint stake
    */
    
    /* @auditor stakes will be converted to wei in frontend*/
    function removeStake(uint256 _stake) external {
        _removeStake(_stake);
    }
    
    function _removeStake(uint _stake) private {
        require(stakes[msg.sender] > 0, 'stakes must be above 0');
        stakes[msg.sender] = stakes[msg.sender].sub(_stake);
         if(stakes[msg.sender] == 0){
             removeStakeholder(msg.sender);
         }
        uint stakeToReceive = calculateUnstakingCost(_stake);
        uint stakeToPool = _stake.sub(stakeToReceive);
        todayStakingPool = todayStakingPool.add(stakeToPool);
        totalStakes = totalStakes.sub(_stake);
        _mint(msg.sender, stakeToReceive);
    }
    
    /* @auditor stakes will be converted to ether in frontend*/
    function stakeOf(address _stakeholder) external view returns(uint256) {
        return stakes[_stakeholder];
    }
    
    function addStakeholder(address _stakeholder) private {
       if(stakeholders[_stakeholder].staker == false) {
       stakeholders[_stakeholder].staker = true;    
       stakeholders[_stakeholder].id = stakeholdersIndex;
       stakeholdersReverseMapping[stakeholdersIndex] = _stakeholder;
       stakeholdersIndex = stakeholdersIndex.add(1);
       todayStakeholdersCountUp = todayStakeholdersCountUp.add(1);
      }
    }
   
    function removeStakeholder(address _stakeholder) private  {
        if (stakeholders[_stakeholder].staker = true) {
            // get id of the stakeholders to be deleted
            uint swappableId = stakeholders[_stakeholder].id;
            
            // swap the stakeholders info and update admins mapping
            // get the last stakeholdersReverseMapping address for swapping
            address swappableAddress = stakeholdersReverseMapping[stakeholdersIndex -1];
            
            // swap the stakeholdersReverseMapping and then reduce stakeholder index
            stakeholdersReverseMapping[swappableId] = stakeholdersReverseMapping[stakeholdersIndex - 1];
            
            // also remap the stakeholder id
            stakeholders[swappableAddress].id = swappableId;
            
            // delete and reduce admin index 
            delete(stakeholders[_stakeholder]);
            delete(stakeholdersReverseMapping[stakeholdersIndex - 1]);
            stakeholdersIndex = stakeholdersIndex.sub(1);
            todayStakeholdersCountDown = todayStakeholdersCountDown.add(1);
        }
    }
    
    // 4. Updating FUNCTIONS
    
    /*add todayStakingPool to totalStakeingPool
    only called once in 24hrs
    reset todayStakingPool to zero
    */
     function addPool() onlyAdmin private {
        require(now > setTime1, 'wait 24hrs from last call');
        setTime1 = now + 1 days;
        totalStakingPool = totalStakingPool.add(todayStakingPool);
        todayStakingPool = 0;
     }
    
    /*
     addTodayCount if stakeholders leave or joins
     only called once in 24hrs 
    */
    function addTodayCount() private onlyAdmin returns(uint count) {
        require(now > setTime2, 'wait 24hrs from last call');
        setTime2 = now + 1 days;
        stakeholdersCount = stakeholdersCount.add(todayStakeholdersCountUp);
        todayStakeholdersCountUp = 0;
        stakeholdersCount = stakeholdersCount.sub(todayStakeholdersCountDown);
        todayStakeholdersCountDown = 0;
        count =stakeholdersCount;
    }
    
    /*
     check stakeholdersCountBeforeUpdate before addTodayCount,
     get currentStakeholdersCount, get newStakers by minusing both
     if above 1 you check for the percentGrowth; (newStakers*100)/stakeholdersCountBeforeUpdate
     if 0 or below set rewardToShare and percentGrowth to 0
     checkCommunityGrowthPercent will be called every 24hrs
    */
    function checkCommunityGrowthPercent() external onlyAdmin  {
       uint stakeholdersCountBeforeUpdate = stakeholdersCount;
       uint currentStakeholdersCount = addTodayCount();
       int newStakers = int(currentStakeholdersCount - stakeholdersCountBeforeUpdate);
       if(newStakers <= 0){
           rewardToShare = 0;
           percentGrowth = 0;
       }
       else{
           uint intToUnit = uint(newStakers);
           uint newStaker = intToUnit.mul(100);
           
           //convert percentGrowth to wei to get actual values
           percentGrowth = newStaker.mul(1e18).div(stakeholdersCountBeforeUpdate);
           if(percentGrowth >= 10*10**18){
               
               //gets 10% of percentGrowth
               uint percentOfPoolToShare = percentGrowth.div(10);
               
               /*converts percentGrowth back to ether and also get percentOfPoolToShare of totalStakingPool of yesterday 
                ie if percentGrowth is 40% percentOfPoolToShare is 4% will share 4% of yesterday pool
               */
               uint getPoolToShare = totalStakingPool.mul(percentOfPoolToShare).div(1e20);
               totalStakingPool = totalStakingPool.sub(getPoolToShare);
               rewardToShare = getPoolToShare;
           }
           else{
               rewardToShare = 0;
               percentGrowth = 0;
           }
       }
       addPool();
    }
    
     // 4. Reward FUNCTIONS
    
     function calculateReward(address _stakeholder) internal view returns(uint256) {
        return ((stakes[_stakeholder].mul(rewardToShare)).div(totalStakes));
    }
    
    /*
        after stakeholders check for new percentGrowth and rewardToShare 
        they get their reward which can only be called once from a stakeholder a day
        all stakeholders gets 95% of their reward if a stakeholder has a referree 
        5% is sent to his referree, if no referree 5% wil be sent back to the totalStakingPool
    */
    function getRewards() external {
        require(stakeholders[msg.sender].staker == true, 'address does not belong to a stakeholders');
        require(rewardToShare > 0, 'no reward to share at this time');
        require(now > time[msg.sender], 'can only call this function once per day');
        time[msg.sender] = now + 1 days;
        uint256 reward = calculateReward(msg.sender);
        if(exist[msg.sender]){
            uint removeFromReward = reward.mul(5).div(100);
            uint userRewardAfterUpLineBonus = reward.sub(removeFromReward);
            address addr = addressThatReferred[msg.sender];
            addUplineProfit(addr, removeFromReward);
            rewards[msg.sender] = rewards[msg.sender].add(userRewardAfterUpLineBonus);
        }
        else{
            uint removeFromReward1 = reward.mul(5).div(100);
            totalStakingPool = totalStakingPool.add(removeFromReward1);
            uint userReward = reward.sub(removeFromReward1);
            rewards[msg.sender] = rewards[msg.sender].add(userReward);
        }
    }
    
    /*
        after stakeholder checks the bonus mapping if he has bonus he add them to his reward
    */
    function getReferralBouns() external {
        require(stakeholders[msg.sender].staker == true, 'address does not belong to a stakeholders');
        require(bonus[msg.sender].uplineProfit > 0, 'you do not have any bonus');
        uint bonusToGet = bonus[msg.sender].uplineProfit;
        rewards[msg.sender] = rewards[msg.sender].add(bonusToGet);
        revertUplineProfit(msg.sender);
    }
    
    /* return will converted to ether in frontend*/
    function rewardOf(address _stakeholder) external view returns(uint256){
        return rewards[_stakeholder];
    }
    
    // 5. Tranfer FUNCTIONS
    
    /* token will be converted to wei in frontend*/
    function transfer(address _to, uint256 _tokens) public override  returns (bool) {
       if(msg.sender == admins[msg.sender]){
              _transfer(msg.sender, _to, _tokens);  
          }
        else{
            uint toSend = transferFee(msg.sender, _tokens);
            _transfer(msg.sender, _to, toSend);
           }
        return true;
    }
    
    function bulkTransfer(address[] calldata _receivers, uint256[] calldata _tokens) external returns (bool) {
        require(_receivers.length == _tokens.length);
        uint toSend;
        for (uint256 i = 0; i < _receivers.length; i++) {
            if(msg.sender == admins[msg.sender]){
              _transfer(msg.sender, _receivers[i], _tokens[i].mul(1e18));  
            }
            else{
             toSend = transferFee(msg.sender, _tokens[i]);
            _transfer(msg.sender, _receivers[i], toSend);
            }
        }
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 _tokens) public override returns (bool)  {
        if(sender == admins[msg.sender]){
              _transfer(sender, recipient, _tokens);  
        }
        else{
           uint  toSend = transferFee(sender, _tokens);
           _transfer(sender, recipient, toSend);
        }
        _approve(sender, _msgSender(),allowance(sender,msg.sender).sub(_tokens, "ERC20: transfer amount exceeds allowance"));
        return true;
    }
    
    // 6. Calculation FUNCTIONS
    
    /*skaing cost 5% */
    function calculateStakingCost(uint256 _stake) private pure returns(uint) {
        uint stakingCost =  (_stake).mul(5);
        uint percent = stakingCost.div(100);
        uint availableForstake = _stake.sub(percent);
        return availableForstake;
    }
    
    /*unskaing cost 25% */
    function calculateUnstakingCost(uint _stake) private pure returns(uint ) {
        uint unstakingCost =  (_stake).mul(25);
        uint percent = unstakingCost.div(100);
        uint stakeReceived = _stake.sub(percent);
        return stakeReceived;
    }
    
    /*
       remove 10% of _token 
       burn 1%
       send 9% to pool
       return actual amount receivers gets
    */
    /* @auditor given token is in wei calculation will work*/
    function transferFee(address sender, uint _token) private returns(uint _transferred){
        uint transferFees =  _token.div(10);
        uint burn = transferFees.div(10);
        uint addToPool = transferFees.sub(burn);
        todayStakingPool = todayStakingPool.add(addToPool);
        _transferred = _token - transferFees;
        _burn(sender, transferFees);
    }
    
    // 7. Withdraw function
    function withdrawReward() public {
        require(rewards[msg.sender] > 0, 'reward balance must be above 0');
        require(stakeholders[msg.sender].staker == true, 'address does not belong to a stakeholders');
        require(percentGrowth >= 10*10**18,'withdraw disabled');
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;
        _mint(msg.sender, reward);
    }
}