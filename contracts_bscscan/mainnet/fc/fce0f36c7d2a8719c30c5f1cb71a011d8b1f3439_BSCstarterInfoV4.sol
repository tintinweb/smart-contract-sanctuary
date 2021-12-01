/**
 *Submitted for verification at BscScan.com on 2021-12-01
*/

// File: contracts/lib/Ownable.sol

pragma solidity ^0.6.12;

/**
 * @title Owned
 * @dev Basic contract for authorization control.
 * @author dicether
 */
contract Ownable {
    address public owner;
    address public pendingOwner;

    event LogOwnerShipTransferred(address indexed previousOwner, address indexed newOwner);
    event LogOwnerShipTransferInitiated(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Modifier, which throws if called by other account than owner.
     */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Modifier throws if called by any account other than the pendingOwner.
     */
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

    /**
     * @dev Set contract creator as initial owner
     */
    constructor() public {
        owner = msg.sender;
        pendingOwner = address(0);
    }

    /**
     * @dev Allows the current owner to set the pendingOwner address.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        pendingOwner = _newOwner;
        emit LogOwnerShipTransferInitiated(owner, _newOwner);
    }

    /**
     * @dev PendingOwner can accept ownership.
     */
    function claimOwnership() public onlyPendingOwner {
        owner = pendingOwner;
        pendingOwner = address(0);
        emit LogOwnerShipTransferred(owner, pendingOwner);
    }
}

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

// File: contracts/BSCstarterInfoV4.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;




interface ISTARTPresale {
    function investments(address) external view returns (uint256);

    function claimed(address) external view returns (uint256);

    function tokenPriceInWei() external view returns (uint256);
}

interface IBSCstarterStakingV3 {
    function accountInfos(address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}

interface IExternalStaking {
    function balanceOf(address) external view returns (uint256);
}

contract BSCstarterInfoV4 is Ownable {
    using SafeMath for uint256;

    uint256[] private devFeePercentage = [5, 2, 2];
    uint256 private minDevFeeInWei = 5 ether; // min fee amount going to dev AND BSCS hodlers
    uint256 private maxRewardQualifyBal = 20000 * 1e18; // max amount to HODL to qualify for BNB fee rewards
    uint256 private minRewardQualifyBal = 1250 * 1e18; // min amount to HODL to qualify for BNB fee rewards
    uint256 private minRewardQualifyPercentage = 10; // percentage of discount on tokens for qualifying holders

    address[] private presaleAddresses; // track all presales created

    uint256 private minInvestorBSCSBalance = 50 * 1e18; // min amount to investors HODL BSCS balance
    uint256 private minInvestorGuaranteedBalance = 500 * 1e18; // minimum number of BSCS tokens to hold to invest in guaranteed

    uint256 private minStakeTime = 24 hours;
    uint256 private minUnstakeTime = 7 days;
    uint256 private minClaimTime = 7 days;

    address payable[] private bscsTokenPresales;

    // address private pancakeSwapRouter =
    //     address(0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F);
    // address private pancakeSwapFactory =
    //     address(0xBCfCcbde45cE874adCB698cC183deBcF17952812);
    address private pancakeSwapRouter =
        address(0x10ED43C718714eb63d5aA57B78B54704E256024E); // PancakeSwapV2 Router
    address private pancakeSwapFactory =
        address(0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73); // PancakeSwapV2 Factory
    bytes32 private initCodeHash =
        0x00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5; // PancakeSwapV2 InitCodeHash

    address private starterSwapRouter =
        address(0x0000000000000000000000000000000000000000); // StarterSwap Router
    address private starterSwapFactory =
        address(0x0000000000000000000000000000000000000000); // StarterSwap Factory
    bytes32 private starterSwapICH =
        0x00fb7f630766e6a796048ea87d01acd3068e8ff67d078148a3fa3f4a84f69bd5; // StarterSwap InitCodeHash

    uint256 private starterSwapLPPercent = 5; // Liquidity will go StarterSwap

    address private wbnb = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

    address private bscsFactoryAddress;
    uint256 private investmentLimit = 20 * 1e18;

    mapping(address => bool) private bscsDevs;

    address private bscsVestingAddress =
        address(0x0000000000000000000000000000000000000000);

    address private startToken =
        address(0x31D0a7AdA4d4c131Eb612DB48861211F63e57610);
    uint256 private minYesVotesThreshold = 150000 * 1e18; // minimum number of yes votes needed to pass
    uint256 private minVoterBSCSBalance = 100 * 1e18; // minimum number of BSCS tokens to hold to vote
    uint256 private minCreatorStakedBalance = 50 * 1e18;

    IBSCstarterStakingV3 public bscsStakingPool;
    IExternalStaking public externalStaking;

    constructor(
        address payable[] memory _bscsTokenPresales,
        address _bscsStakingPool,
        address _bscsExternalStaking
    ) public {
        bscsTokenPresales = _bscsTokenPresales;
        bscsStakingPool = IBSCstarterStakingV3(_bscsStakingPool);
        externalStaking = IExternalStaking(_bscsExternalStaking);

        bscsDevs[address(0xf7e925818a20E5573Ee0f3ba7aBC963e17f2c476)] = true; // Chef
        bscsDevs[address(0x065d46a882F14a8BC02Ca366Fe23f211f20909b6)] = true; // Cock
    }

    modifier onlyFactory() {
        require(
            bscsFactoryAddress == msg.sender ||
                owner == msg.sender ||
                bscsDevs[msg.sender],
            "onlyFactoryOrDev"
        );
        _;
    }

    modifier onlyBscsDev() {
        require(owner == msg.sender || bscsDevs[msg.sender], "onlyBscsDev");
        _;
    }

    function getCakeV2LPAddress(address tokenA, address tokenB)
        public
        view
        returns (address pair)
    {
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        pancakeSwapFactory,
                        keccak256(abi.encodePacked(token0, token1)),
                        initCodeHash // init code hash
                    )
                )
            )
        );
    }

    function getStarterSwapLPAddress(address tokenA, address tokenB)
        public
        view
        returns (address pair)
    {
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        pair = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        starterSwapFactory,
                        keccak256(abi.encodePacked(token0, token1)),
                        starterSwapICH // init code hash
                    )
                )
            )
        );
    }

    function getBscsDev(address _dev) external view returns (bool) {
        return bscsDevs[_dev];
    }

    function setBscsDevAddress(address _newDev) external onlyOwner {
        bscsDevs[_newDev] = true;
    }

    function removeBscsDevAddress(address _oldDev) external onlyOwner {
        bscsDevs[_oldDev] = false;
    }

    function getBscsFactoryAddress() external view returns (address) {
        return bscsFactoryAddress;
    }

    function setBscsFactoryAddress(address _newFactoryAddress)
        external
        onlyBscsDev
    {
        bscsFactoryAddress = _newFactoryAddress;
    }

    function getBscsStakingPool() external view returns (address) {
        return address(bscsStakingPool);
    }

    function setBscsStakingPool(address _bscsStakingPool) external onlyBscsDev {
        bscsStakingPool = IBSCstarterStakingV3(_bscsStakingPool);
    }

    function getBscsExteranlStaking() external view returns (address) {
        return address(externalStaking);
    }

    function setBscsExteranlStaking(address _bscsStakingPool)
        external
        onlyBscsDev
    {
        externalStaking = IExternalStaking(_bscsStakingPool);
    }

    function addPresaleAddress(address _presale)
        external
        onlyFactory
        returns (uint256)
    {
        presaleAddresses.push(_presale);
        return presaleAddresses.length - 1;
    }

    function addPresaleAddresses(address[] memory _presales)
        external
        onlyBscsDev
        returns (uint256)
    {
        uint256 i = 0;
        for (i = 0; i < _presales.length; i++) {
            presaleAddresses.push(_presales[i]);
        }
        return presaleAddresses.length;
    }

    function getPresalesCount() external view returns (uint256) {
        return presaleAddresses.length;
    }

    function getPresaleAddress(uint256 bscsId) external view returns (address) {
        return presaleAddresses[bscsId];
    }

    function setPresaleAddress(uint256 bscsId, address _newAddress)
        external
        onlyBscsDev
    {
        presaleAddresses[bscsId] = _newAddress;
    }

    function getDevFeePercentage(uint256 presaleType)
        external
        view
        returns (uint256)
    {
        return devFeePercentage[presaleType];
    }

    function setDevFeePercentage(uint256 presaleType, uint256 _devFeePercentage)
        external
        onlyBscsDev
    {
        devFeePercentage[presaleType] = _devFeePercentage;
    }

    function getMinDevFeeInWei() external view returns (uint256) {
        return minDevFeeInWei;
    }

    function setMinDevFeeInWei(uint256 _minDevFeeInWei) external onlyBscsDev {
        minDevFeeInWei = _minDevFeeInWei;
    }

    function getMinRewardQualifyPercentage() external view returns (uint256) {
        return minRewardQualifyPercentage;
    }

    function setMinRewardQualifyPercentage(uint256 _minRewardQualifyPercentage)
        external
        onlyBscsDev
    {
        minRewardQualifyPercentage = _minRewardQualifyPercentage;
    }

    function getMinRewardQualifyBal() external view returns (uint256) {
        return minRewardQualifyBal;
    }

    function setMinRewardQualifyBal(uint256 _minRewardQualifyBal)
        external
        onlyBscsDev
    {
        minRewardQualifyBal = _minRewardQualifyBal;
    }

    function getMaxRewardQualifyBal() external view returns (uint256) {
        return maxRewardQualifyBal;
    }

    function setMaxRewardQualifyBal(uint256 _maxRewardQualifyBal)
        external
        onlyBscsDev
    {
        maxRewardQualifyBal = _maxRewardQualifyBal;
    }

    function getMinInvestorBSCSBalance() external view returns (uint256) {
        return minInvestorBSCSBalance;
    }

    function setMinInvestorBSCSBalance(uint256 _minInvestorBSCSBalance)
        external
        onlyBscsDev
    {
        minInvestorBSCSBalance = _minInvestorBSCSBalance;
    }

    function getMinVoterBSCSBalance() external view returns (uint256) {
        return minVoterBSCSBalance;
    }

    function setMinVoterBSCSBalance(uint256 _minVoterBSCSBalance)
        external
        onlyBscsDev
    {
        minVoterBSCSBalance = _minVoterBSCSBalance;
    }

    function getMinYesVotesThreshold() external view returns (uint256) {
        return minYesVotesThreshold;
    }

    function setMinYesVotesThreshold(uint256 _minYesVotesThreshold)
        external
        onlyBscsDev
    {
        minYesVotesThreshold = _minYesVotesThreshold;
    }

    function getMinCreatorStakedBalance() external view returns (uint256) {
        return minCreatorStakedBalance;
    }

    function setMinCreatorStakedBalance(uint256 _minCreatorStakedBalance)
        external
        onlyBscsDev
    {
        minCreatorStakedBalance = _minCreatorStakedBalance;
    }

    function getMinInvestorGuaranteedBalance() external view returns (uint256) {
        return minInvestorGuaranteedBalance;
    }

    function setMinInvestorGuaranteedBalance(
        uint256 _minInvestorGuaranteedBalance
    ) external onlyBscsDev {
        minInvestorGuaranteedBalance = _minInvestorGuaranteedBalance;
    }

    function getMinStakeTime() external view returns (uint256) {
        return minStakeTime;
    }

    function setMinStakeTime(uint256 _minStakeTime) external onlyBscsDev {
        minStakeTime = _minStakeTime;
    }

    function getMinUnstakeTime() external view returns (uint256) {
        return minUnstakeTime;
    }

    function setMinUnstakeTime(uint256 _minUnstakeTime) external onlyBscsDev {
        minUnstakeTime = _minUnstakeTime;
    }

    function getMinClaimTime() external view returns (uint256) {
        return minClaimTime;
    }

    function setMinClaimTime(uint256 _minClaimTime) external onlyBscsDev {
        minClaimTime = _minClaimTime;
    }

    function getBscsTokenPresales()
        external
        view
        returns (address payable[] memory)
    {
        return bscsTokenPresales;
    }

    function setBscsTokenPresales(address payable[] memory _bscsTokenPresales)
        external
        onlyBscsDev
    {
        bscsTokenPresales = _bscsTokenPresales;
    }

    function getLockedBalance(address payable sender)
        public
        view
        returns (uint256 totalLockedBalance)
    {
        totalLockedBalance = 0;
        for (uint256 i = 0; i < bscsTokenPresales.length; i++) {
            ISTARTPresale tokenPresale = ISTARTPresale(bscsTokenPresales[i]);

            uint256 senderInvestment = tokenPresale.investments(sender);
            uint256 senderClaimed = tokenPresale.claimed(sender);
            if (senderInvestment > 0 && senderClaimed < 4) {
                uint256 poolTokenPriceInWei = tokenPresale.tokenPriceInWei();
                uint256 poolLockedBalance = senderInvestment
                    .div(4)
                    .mul(4 - senderClaimed)
                    .mul(1e18)
                    .div(poolTokenPriceInWei);
                totalLockedBalance = totalLockedBalance.add(poolLockedBalance);
            }
        }
    }

    function getPancakeSwapRouter() external view returns (address) {
        return pancakeSwapRouter;
    }

    function setPancakeSwapRouter(address _pancakeSwapRouter)
        external
        onlyBscsDev
    {
        pancakeSwapRouter = _pancakeSwapRouter;
    }

    function getPancakeSwapFactory() external view returns (address) {
        return pancakeSwapFactory;
    }

    function setPancakeSwapFactory(address _pancakeSwapFactory)
        external
        onlyBscsDev
    {
        pancakeSwapFactory = _pancakeSwapFactory;
    }

    function getInitCodeHash() external view returns (bytes32) {
        return initCodeHash;
    }

    function setInitCodeHash(bytes32 _initCodeHash) external onlyBscsDev {
        initCodeHash = _initCodeHash;
    }

    function getStarterSwapRouter() external view returns (address) {
        return starterSwapRouter;
    }

    function setStarterSwapRouter(address _starterSwapRouter)
        external
        onlyBscsDev
    {
        starterSwapRouter = _starterSwapRouter;
    }

    function getStarterSwapFactory() external view returns (address) {
        return starterSwapFactory;
    }

    function setStarterSwapFactory(address _starterSwapFactory)
        external
        onlyBscsDev
    {
        starterSwapFactory = _starterSwapFactory;
    }

    function getStarterSwapICH() external view returns (bytes32) {
        return starterSwapICH;
    }

    function setStarterSwapICH(bytes32 _initCodeHash) external onlyBscsDev {
        starterSwapICH = _initCodeHash;
    }

    function getStarterSwapLPPercent() external view returns (uint256) {
        return starterSwapLPPercent;
    }

    function setStarterSwapLPPercent(uint256 _starterSwapLPPercent)
        external
        onlyBscsDev
    {
        starterSwapLPPercent = _starterSwapLPPercent;
    }

    function getWBNB() external view returns (address) {
        return wbnb;
    }

    function setWBNB(address _wbnb) external onlyBscsDev {
        wbnb = _wbnb;
    }

    function getVestingAddress() external view returns (address) {
        return bscsVestingAddress;
    }

    function setVestingAddress(address _newVesting) external onlyBscsDev {
        bscsVestingAddress = _newVesting;
    }

    function getInvestmentLimit() external view returns (uint256) {
        return investmentLimit;
    }

    function setInvestmentLimit(uint256 _limit) external onlyBscsDev {
        investmentLimit = _limit;
    }

    function getBscsStakedAndLocked(address payable sender)
        public
        view
        returns (uint256)
    {
        uint256 balance;
        uint256 lastStakedTimestamp;
        (balance, lastStakedTimestamp, ) = bscsStakingPool.accountInfos(
            address(sender)
        );
        uint256 externalBalance = externalStaking.balanceOf(sender);

        uint256 totalHodlerBalance = getLockedBalance(sender);

        if (lastStakedTimestamp + minStakeTime <= block.timestamp) {
            totalHodlerBalance = totalHodlerBalance.add(balance);
        }
        return totalHodlerBalance + externalBalance;
    }

    function getTotalLockedValues() external view returns (uint256) {
        uint256 totalLockedValues = 0;
        for (uint256 i = 0; i < bscsTokenPresales.length; i++) {
            totalLockedValues = totalLockedValues.add(
                ERC20(startToken).balanceOf(bscsTokenPresales[i])
            );
        }

        totalLockedValues = totalLockedValues.add(
            ERC20(startToken).balanceOf(address(bscsStakingPool))
        );
        return totalLockedValues;
    }
}