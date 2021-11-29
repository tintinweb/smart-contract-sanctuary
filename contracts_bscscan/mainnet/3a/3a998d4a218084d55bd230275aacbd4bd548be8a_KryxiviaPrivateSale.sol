/**
 *Submitted for verification at BscScan.com on 2021-11-29
*/

// File: contracts/lib/SafeMath.sol

pragma solidity ^0.6.12;

// File: @openzeppelin/contracts/math/SafeMath.sol

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: contracts/lib/Address.sol

pragma solidity ^0.6.12;

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
        assembly {
            size := extcodesize(account)
        }
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
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

// File: contracts/lib/Context.sol

pragma solidity ^0.6.12;

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

// File: contracts/interfaces/IERC20.sol

pragma solidity ^0.6.12;

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

// File: contracts/lib/ERC20.sol

pragma solidity ^0.6.12;





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

    mapping(address => uint256) _balances;

    mapping(address => mapping(address => uint256)) _allowances;

    uint256 _totalSupply;

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
    constructor(string memory name, string memory symbol) public {
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
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
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
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
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

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: contracts/KryxiviaPrivateSale.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;



interface IPancakeSwapV2Router02 {
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

interface IBSCstarterVesting {
    function lockTokens(
        address _tokenAddress,
        address _withdrawalAddress,
        uint256 _lockAmount,
        uint256 _unlockTime
    ) external returns (uint256 _id);
}

interface IBSCstarterInfoV3 {
    function getBscsDev(address _dev) external view returns (bool);

    function getMinYesVotesThreshold() external view returns (uint256);

    function getBscsStakedAndLocked(address payable sender)
        external
        view
        returns (uint256);

    function getMinInvestorBSCSBalance() external view returns (uint256);
}

contract KryxiviaPrivateSale {
    using SafeMath for uint256;

    address payable internal bscsFactoryAddress; // address that creates the presale contracts
    address payable public bscsDevAddress; // address where dev fees will be transferred to
    ERC20 public lpToken; // address where LP tokens will be locked
    ERC20 public starterLpToken; //address where starter LP tokens will be locked
    address public bscsStakingPool;
    IBSCstarterInfoV3 public bscStarterInfo;

    ERC20 public token; // token that will be sold
    uint8 public tokenDecimals = 18; // token decimals
    ERC20 public bscsToken; // system token
    uint256 public tokenMagnitude = 1e18; // token magnitude

    address payable public presaleCreatorAddress; // address where percentage of invested wei will be transferred to
    address public unsoldTokensDumpAddress; // address where unsold tokens will be transferred to
    address payable public buyBackBurnAddress; // address where buy back burn tokens will be transferred to

    mapping(address => uint256) public investments; // total wei invested per address

    mapping(address => bool) public whitelistedAddresses; // addresses eligible in presale
    mapping(address => bool) public blacklistedAddresses; // addresses blocked in presale
    mapping(address => uint256) public claimed; // if true, it means investor already claimed the tokens or got a refund
    mapping(address => uint256) public claimedTimes; // if true, it means investor already claimed the tokens or got a refund

    uint256 private bscsDevFeePercentage; // dev fee to support the development of BSCstarter
    uint256 private bscsMinDevFeeInWei; // minimum fixed dev fee to support the development of BSCstarter
    uint256 public bscsId; // used for fetching presale without referencing its address

    uint256 public totalInvestorsCount; // total investors count
    uint256 public presaleCreatorClaimTime; // time when presale creator can collect funds raise
    uint256 public totalCollectedWei; // total wei collected
    uint256 public totalTokens; // total tokens to be sold
    uint256 public tokensLeft; // available tokens to be sold
    uint256 public tokenPriceInWei; // token presale wei price per 1 token
    uint256 public hardCapInWei; // maximum wei amount that can be invested in presale
    uint256 public softCapInWei; // minimum wei amount to invest in presale, if not met, invested wei will be returned
    uint256 public maxInvestInWei; // maximum wei amount that can be invested per wallet address
    uint256 public minInvestInWei; // minimum wei amount that can be invested per wallet address
    uint256 public openTime; // time when presale starts, investing is allowed
    uint256 public closeTime; // time when presale closes, investing is not allowed
    uint256 public presaleType; // 0: Private, 1: Public, 2: Certified START
    uint256 public guaranteedHours; // hours for guaranteed allocation
    uint256 public releasePerCycle = 2500; // 25% or 10% release
    uint256 public releasePerCycle2 = 83;
    uint256 public releaseCycle = 30 days; // 1month, 1day or 1 week
    uint256 public releaseCycle2 = 1 days;
    uint256 public releasePoint = 30 days;

    uint256 public cakeListingPriceInWei; // token price when listed in PancakeSwap
    uint256 public cakeLiquidityAddingTime; // time when adding of liquidity in PancakeSwap starts, investors can claim their tokens afterwards
    uint256 public cakeLPTokensLockDurationInDays; // how many days after the liquity is added the presale creator can unlock the LP tokens
    uint256 public cakeLiquidityPercentageAllocation; // how many percentage of the total invested wei that will be added as liquidity

    mapping(address => uint256) public voters; // addresses voting on sale
    uint256 public noVotes; // total number of no votes
    uint256 public yesVotes; // total number of yes votes

    uint256 public minRewardQualifyBal; // min amount to HODL to qualify for token discounts
    uint256 public minRewardQualifyPercentage; // percentage of discount on tokens for qualifying holders

    bool public cakeLiquidityAdded = false; // if true, liquidity is added in PancakeSwap and lp tokens are locked
    bool public onlyWhitelistedAddressesAllowed = false; // if true, only whitelisted addresses can invest
    bool public bscsDevFeesExempted = false; // if true, presale will be exempted from dev fees
    bool public presaleCancelled = false; // if true, investing will not be allowed, investors can withdraw, presale creator can withdraw their tokens
    bool public claimAllowed = false; // if false, investor will not be allowed to be claimed

    bytes32 public saleTitle;
    bytes32 public linkTelegram;
    bytes32 public linkTwitter;
    bytes32 public linkGithub;
    bytes32 public linkWebsite;
    string public linkLogo;
    string public kycInformation;
    string public description;
    string public whitepaper;
    uint256 public categoryId;

    mapping(address => bool) public auditorWhitelistedAddresses; // addresses eligible to perform audit
    struct AuditorInfo {
        bytes32 auditor; // auditor name
        bool isVerified; // if true -> passed, false -> failed
        bool isWarning; // if true -> warning, false -> no warning
        string linkAudit; // stores content of audit summary (actual text)
    }
    AuditorInfo public auditInformation;

    constructor(
        address _bscsFactoryAddress,
        address _bscStarterInfo,
        address _bscsDevAddress,
        uint256 _minRewardQualifyBal,
        uint256 _minRewardQualifyPercentage
    ) public {
        require(_bscsFactoryAddress != address(0));
        require(_bscsDevAddress != address(0));

        bscsFactoryAddress = payable(_bscsFactoryAddress);
        bscsDevAddress = payable(_bscsDevAddress);
        minRewardQualifyBal = _minRewardQualifyBal;
        minRewardQualifyPercentage = _minRewardQualifyPercentage;
        bscStarterInfo = IBSCstarterInfoV3(_bscStarterInfo);
    }

    modifier onlyBscsDev() {
        require(
            bscsFactoryAddress == msg.sender ||
                bscsDevAddress == msg.sender ||
                bscStarterInfo.getBscsDev(msg.sender)
        );
        _;
    }

    modifier onlyPresaleCreatorOrBscsFactory() {
        require(
            presaleCreatorAddress == msg.sender ||
                bscsFactoryAddress == msg.sender ||
                bscsDevAddress == msg.sender ||
                bscStarterInfo.getBscsDev(msg.sender)
        );
        _;
    }

    modifier onlyPresaleCreator() {
        require(presaleCreatorAddress == msg.sender);
        _;
    }

    modifier whitelistedAddressOnly() {
        require(
            !onlyWhitelistedAddressesAllowed || whitelistedAddresses[msg.sender]
        );
        _;
    }

    modifier notBlacklistedAddress() {
        require(!blacklistedAddresses[msg.sender]);
        _;
    }

    modifier presaleIsNotCancelled() {
        require(!presaleCancelled);
        _;
    }

    modifier investorOnly() {
        require(investments[msg.sender] > 0);
        _;
    }

    modifier notYetClaimedOrRefunded() {
        require(claimed[msg.sender] < getTokenAmount(investments[msg.sender]));
        _;
    }

    modifier votesPassed() {
        uint256 minYesVotesThreshold = bscStarterInfo.getMinYesVotesThreshold();
        require(
            yesVotes >= noVotes.add(minYesVotesThreshold) || presaleType != 1
        );
        _;
    }

    modifier whitelistedAuditorOnly() {
        require(auditorWhitelistedAddresses[msg.sender]);
        _;
    }

    modifier claimAllowedOrLiquidityAdded() {
        require(
            (presaleType == 0 && claimAllowed) ||
                (presaleType != 0 && cakeLiquidityAdded)
        );
        _;
    }

    function setAddressInfo(
        address _presaleCreator,
        address _tokenAddress,
        uint8 _tokenDecimals,
        address _bscsTokenAddress,
        address _unsoldTokensDumpAddress,
        address payable _buyBackBurnAddress
    ) external onlyBscsDev {
        presaleCreatorAddress = payable(_presaleCreator);
        token = ERC20(_tokenAddress);
        tokenDecimals = _tokenDecimals;
        bscsToken = ERC20(_bscsTokenAddress);
        unsoldTokensDumpAddress = _unsoldTokensDumpAddress;
        buyBackBurnAddress = _buyBackBurnAddress;
        tokenMagnitude = uint256(10)**uint256(tokenDecimals);
    }

    function setGeneralInfo(
        uint256 _totalTokens,
        uint256 _tokenPriceInWei,
        uint256 _hardCapInWei,
        uint256 _softCapInWei,
        uint256 _maxInvestInWei,
        uint256 _minInvestInWei,
        uint256 _openTime,
        uint256 _closeTime,
        uint256 _presaleType,
        uint256 _guaranteedHours,
        uint256 _releasePerCycle,
        uint256 _releaseCycle
    ) external onlyBscsDev {
        require(
            _totalTokens > 0 &&
                _tokenPriceInWei > 0 &&
                _openTime > 0 &&
                _closeTime > 0 &&
                _hardCapInWei > 0 &&
                _releasePerCycle > 0 &&
                _releaseCycle > 0
        );

        require(
            _hardCapInWei <= _totalTokens.mul(_tokenPriceInWei) &&
                _softCapInWei <= _hardCapInWei &&
                _minInvestInWei <= _maxInvestInWei &&
                _openTime < _closeTime
        );

        totalTokens = _totalTokens;
        tokensLeft = _totalTokens;
        tokenPriceInWei = _tokenPriceInWei;
        hardCapInWei = _hardCapInWei;
        softCapInWei = _softCapInWei;
        maxInvestInWei = _maxInvestInWei;
        minInvestInWei = _minInvestInWei;
        openTime = _openTime;
        closeTime = _closeTime;
        presaleType = _presaleType;
        guaranteedHours = _guaranteedHours;
        releasePerCycle = _releasePerCycle;
        releaseCycle = _releaseCycle;
    }

    function setReleaseConfig(
        uint256 _releaseCycle,
        uint256 _releasePerCycle,
        uint256 _releaseCycle2,
        uint256 _releasePerCycle2,
        uint256 _releasePoint
    ) external onlyBscsDev {
        releaseCycle = _releaseCycle;
        releasePerCycle = _releasePerCycle;
        releaseCycle2 = _releaseCycle2;
        releasePerCycle2 = _releasePerCycle2;
        releasePoint = _releasePoint;
    }

    function setPancakeSwapInfo(
        uint256 _cakeListingPriceInWei,
        uint256 _cakeLiquidityAddingTime,
        uint256 _cakeLPTokensLockDurationInDays,
        uint256 _cakeLiquidityPercentageAllocation
    ) external onlyBscsDev {
        require(
            _cakeListingPriceInWei > 0 &&
                _cakeLiquidityAddingTime > 0 &&
                _cakeLPTokensLockDurationInDays > 0 &&
                _cakeLiquidityPercentageAllocation > 0
        );

        require(closeTime > 0 && _cakeLiquidityAddingTime >= closeTime);

        cakeListingPriceInWei = _cakeListingPriceInWei;
        cakeLiquidityAddingTime = _cakeLiquidityAddingTime;
        cakeLPTokensLockDurationInDays = _cakeLPTokensLockDurationInDays;
        cakeLiquidityPercentageAllocation = _cakeLiquidityPercentageAllocation;
    }

    function setSwapTimes(uint256 _closeTime, uint256 _cakeLiquidityAddingTime)
        external
        onlyPresaleCreatorOrBscsFactory
    {
        closeTime = _closeTime;
        cakeLiquidityAddingTime = _cakeLiquidityAddingTime;
    }

    function allowClaim() external onlyPresaleCreatorOrBscsFactory {
        require(presaleType == 0);
        claimAllowed = true;
    }

    function disableClaim() external onlyPresaleCreatorOrBscsFactory {
        require(presaleType == 0);
        claimAllowed = false;
    }

    function setStringInfo(
        bytes32 _saleTitle,
        bytes32 _linkTelegram,
        bytes32 _linkGithub,
        bytes32 _linkTwitter,
        bytes32 _linkWebsite,
        string calldata _linkLogo,
        string calldata _kycInformation,
        string calldata _description,
        string calldata _whitepaper,
        uint256 _categoryId
    ) external onlyPresaleCreatorOrBscsFactory {
        saleTitle = _saleTitle;
        linkTelegram = _linkTelegram;
        linkGithub = _linkGithub;
        linkTwitter = _linkTwitter;
        linkWebsite = _linkWebsite;
        linkLogo = _linkLogo;
        kycInformation = _kycInformation;
        description = _description;
        whitepaper = _whitepaper;
        categoryId = _categoryId;
    }

    function setAuditorInfo(
        bytes32 _auditor,
        bool _isVerified,
        bool _isWarning,
        string calldata _linkAudit
    ) external whitelistedAuditorOnly {
        auditInformation.auditor = _auditor;
        auditInformation.isVerified = _isVerified;
        auditInformation.isWarning = _isWarning;
        auditInformation.linkAudit = _linkAudit;
    }

    function setBscsInfo(
        address _lpToken,
        address _starterLpToken,
        uint256 _bscsDevFeePercentage,
        uint256 _bscsMinDevFeeInWei,
        uint256 _bscsId,
        address _bscsStakingPool
    ) external onlyBscsDev {
        lpToken = ERC20(_lpToken);
        starterLpToken = ERC20(_starterLpToken);
        bscsDevFeePercentage = _bscsDevFeePercentage;
        bscsMinDevFeeInWei = _bscsMinDevFeeInWei;
        bscsId = _bscsId;
        bscsStakingPool = _bscsStakingPool;
    }

    function setBscsDevFeesExempted(bool _bscsDevFeesExempted)
        external
        onlyBscsDev
    {
        bscsDevFeesExempted = _bscsDevFeesExempted;
    }

    function setOnlyWhitelistedAddressesAllowed(
        bool _onlyWhitelistedAddressesAllowed
    ) external onlyPresaleCreatorOrBscsFactory {
        onlyWhitelistedAddressesAllowed = _onlyWhitelistedAddressesAllowed;
    }

    function addWhitelistedAddresses(address[] calldata _whitelistedAddresses)
        external
        onlyPresaleCreatorOrBscsFactory
    {
        onlyWhitelistedAddressesAllowed = _whitelistedAddresses.length > 0;
        for (uint256 i = 0; i < _whitelistedAddresses.length; i++) {
            whitelistedAddresses[_whitelistedAddresses[i]] = true;
        }
    }

    function addBlacklistedAddresses(address[] calldata _blacklistedAddresses)
        external
        onlyPresaleCreatorOrBscsFactory
    {
        for (uint256 i = 0; i < _blacklistedAddresses.length; i++) {
            blacklistedAddresses[_blacklistedAddresses[i]] = true;
        }
    }

    function addAuditorWhitelistedAddresses(
        address[] calldata _whitelistedAddresses
    ) external onlyBscsDev {
        for (uint256 i = 0; i < _whitelistedAddresses.length; i++) {
            auditorWhitelistedAddresses[_whitelistedAddresses[i]] = true;
        }
    }

    function getTokenAmount(uint256 _weiAmount)
        internal
        view
        returns (uint256)
    {
        uint256 bscsBalance = bscStarterInfo.getBscsStakedAndLocked(msg.sender);
        if (bscsBalance >= minRewardQualifyBal) {
            uint256 pctQualifyingDiscount = tokenPriceInWei
                .mul(minRewardQualifyPercentage)
                .div(100);
            return
                _weiAmount.mul(tokenMagnitude).div(
                    tokenPriceInWei.sub(pctQualifyingDiscount)
                );
        } else {
            return _weiAmount.mul(tokenMagnitude).div(tokenPriceInWei);
        }
    }

    function invest()
        public
        payable
        whitelistedAddressOnly
        notBlacklistedAddress
        presaleIsNotCancelled
        votesPassed
    {
        require(
            block.timestamp >= openTime && block.timestamp < closeTime,
            "1"
        );
        require(
            totalCollectedWei < hardCapInWei && tokensLeft > 0 && msg.value > 0,
            "2"
        );
        require(
            msg.value <= tokensLeft.mul(tokenPriceInWei).div(tokenMagnitude),
            "4"
        );
        uint256 bscsBalance = bscStarterInfo.getBscsStakedAndLocked(msg.sender);
        uint256 totalInvestmentInWei = investments[msg.sender].add(msg.value);

        require(
            totalInvestmentInWei >= minInvestInWei ||
                totalCollectedWei >= hardCapInWei.sub(1 ether),
            "5"
        );
        uint256 minInvestorBSCSBalance = bscStarterInfo
            .getMinInvestorBSCSBalance();

        require(
            totalInvestmentInWei <= maxInvestInWei &&
                bscsBalance >= minInvestorBSCSBalance,
            "a"
        );

        if (investments[msg.sender] == 0) {
            totalInvestorsCount = totalInvestorsCount.add(1);
        }

        totalCollectedWei = totalCollectedWei.add(msg.value);
        investments[msg.sender] = totalInvestmentInWei;
        tokensLeft = tokensLeft.sub(getTokenAmount(msg.value));
    }

    receive() external payable {
        invest();
    }

    function sendFeesToDevs() internal returns (uint256) {
        uint256 finalTotalCollectedWei = totalCollectedWei;
        uint256 bscsDevFeeInWei;
        if (!bscsDevFeesExempted) {
            uint256 pctDevFee = finalTotalCollectedWei
                .mul(bscsDevFeePercentage)
                .div(100);
            bscsDevFeeInWei = pctDevFee > bscsMinDevFeeInWei ||
                bscsMinDevFeeInWei >= finalTotalCollectedWei
                ? pctDevFee
                : bscsMinDevFeeInWei;
        }
        if (bscsDevFeeInWei > 0) {
            finalTotalCollectedWei = finalTotalCollectedWei.sub(
                bscsDevFeeInWei
            );
            bscsDevAddress.transfer(bscsDevFeeInWei);

            if (presaleType != 0) {
                finalTotalCollectedWei = finalTotalCollectedWei.sub(
                    bscsDevFeeInWei
                );

                // factory manages BSCS hodlers fund where they can claim earned BNB rewards
                bscsFactoryAddress.transfer(bscsDevFeeInWei.div(4));
                buyBackBurnAddress.transfer(bscsDevFeeInWei.mul(3).div(4));
            }
        }
        return finalTotalCollectedWei;
    }

    function claimTokens()
        external
        whitelistedAddressOnly
        notBlacklistedAddress
        presaleIsNotCancelled
        investorOnly
        notYetClaimedOrRefunded
        claimAllowedOrLiquidityAdded
    {
        uint256 tokenAmount = getTokenAmount(investments[msg.sender]);
        uint256 releaseAmount;
        if (claimedTimes[msg.sender] > 0) {
            require(
                block.timestamp >
                    openTime.add(releasePoint).add(
                        claimedTimes[msg.sender].mul(releaseCycle2)
                    ),
                "1"
            );
            releaseAmount = tokenAmount.mul(releasePerCycle2).div(10000);
        } else {
            releaseAmount = tokenAmount.mul(releasePerCycle).div(10000);
        }

        if (claimed[msg.sender].add(releaseAmount) > tokenAmount) {
            releaseAmount = tokenAmount.sub(claimed[msg.sender]);
        }
        claimed[msg.sender] = claimed[msg.sender].add(releaseAmount); // make sure this goes first before transfer to prevent reentrancy
        claimedTimes[msg.sender] = claimedTimes[msg.sender].add(1);
        token.transfer(msg.sender, releaseAmount);
    }

    function getRefund()
        external
        whitelistedAddressOnly
        notBlacklistedAddress
        investorOnly
        notYetClaimedOrRefunded
    {
        require(
            presaleCancelled ||
                (block.timestamp >= closeTime &&
                    softCapInWei > 0 &&
                    totalCollectedWei < softCapInWei)
        );

        claimed[msg.sender] = getTokenAmount(investments[msg.sender]); // make sure this goes first before transfer to prevent reentrancy
        if (investments[msg.sender] > 0) {
            msg.sender.transfer(investments[msg.sender]);
        }
    }

    function cancelAndTransferTokensToPresaleCreator() external {
        if (
            msg.sender == bscsDevAddress ||
            (msg.sender == presaleCreatorAddress &&
                !cakeLiquidityAdded &&
                !claimAllowed)
        ) {
            presaleCancelled = true;
            token.transfer(
                presaleCreatorAddress,
                token.balanceOf(address(this))
            );
        }
    }

    function collectFundsRaised()
        external
        onlyPresaleCreator
        claimAllowedOrLiquidityAdded
    {
        require(
            !presaleCancelled &&
                block.timestamp >= presaleCreatorClaimTime &&
                auditInformation.isVerified
        );
        if (presaleType == 0) {
            sendFeesToDevs();
        }
        presaleCreatorAddress.transfer(address(this).balance);
    }

    function sendUnsoldTokens() external onlyBscsDev {
        require(
            !presaleCancelled &&
                block.timestamp >= presaleCreatorClaimTime + 1 days
        ); // wait 2 days before allowing burn
        token.transfer(unsoldTokensDumpAddress, token.balanceOf(address(this)));
    }
}