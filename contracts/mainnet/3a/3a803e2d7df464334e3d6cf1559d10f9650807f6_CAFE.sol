/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

// Sources flattened with hardhat v2.1.1 https://hardhat.org

// File @openzeppelin/contracts-upgradeable/utils/[email protected]


pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // This method relies on extcodesize, which returns 0 for contracts in
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
        return functionCallWithValue(target, data, 0, errorMessage);
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]


// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}


// File @openzeppelin/contracts-upgradeable/token/ERC20/[email protected]
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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


// File contracts/library/ERC20ReInitializable.sol

pragma solidity ^0.8.0;


contract ERC20ReInitializable is Initializable, IERC20Upgradeable {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal initializer {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    function __ERC20_re_initialize(string memory name_, string memory symbol_) internal {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
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
        _transfer(msg.sender, recipient, amount);
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
        _approve(msg.sender, spender, amount);
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, msg.sender, currentAllowance - amount);

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
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);

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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

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
    uint256[45] private __gap;
}


// File contracts/interfaces/IOwnable.sol

pragma solidity ^0.8.0;

interface IOwnable{
    function owner() external view returns(address);
}


// File contracts/interfaces/IWhitelist.sol

pragma solidity ^0.8.0;

/**
 * Source: https://raw.githubusercontent.com/simple-restricted-token/reference-implementation/master/contracts/token/ERC1404/ERC1404.sol
 * With ERC-20 APIs removed (will be implemented as a separate contract).
 * And adding authorizeTransfer.
 */
interface IWhitelist {
  /**
   * @notice Detects if a transfer will be reverted and if so returns an appropriate reference code
   * @param from Sending address
   * @param to Receiving address
   * @param value Amount of tokens being transferred
   * @return Code by which to reference message for rejection reasoning
   * @dev Overwrite with your custom transfer restriction logic
   */
  function detectTransferRestriction(
    address from,
    address to,
    uint value
  ) external view returns (uint8);

  /**
   * @notice Returns a human-readable message for a given restriction code
   * @param restrictionCode Identifier for looking up a message
   * @return Text showing the restriction's reasoning
   * @dev Overwrite with your custom message and restrictionCode handling
   */
  function messageForTransferRestriction(uint8 restrictionCode)
    external
    pure
    returns (string memory);

  /**
   * @notice Called by the DAT contract before a transfer occurs.
   * @dev This call will revert when the transfer is not authorized.
   * This is a mutable call to allow additional data to be recorded,
   * such as when the user aquired their tokens.
   */
  function authorizeTransfer(
    address _from,
    address _to,
    uint _value,
    bool _isSell
  ) external;
}


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File contracts/interfaces/IERC20Metadata.sol


pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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


// File contracts/math/BigDiv.sol

pragma solidity ^0.8.0;
/**
 * @title Reduces the size of terms before multiplication, to avoid an overflow, and then
*stores the proper size after division.
 * @notice This effectively allows us to overflow values in the numerator and/or denominator
* a fraction, so long as the end result does not overflow as well.
 * @dev Results may be off by 1 + 0.000001% for 2x1 calls and 2 + 0.00001% for 2x2 calls.
 * Do not use if your contract expects very small result values to be accurate.
 */
library BigDiv {
    // When multiplying 2 terms <= this value the result won't overflow
    uint private constant MAX_BEFORE_SQUARE = 2**128 - 1;

    // The max error target is off by 1 plus up to 0.000001% error
    // for bigDiv2x1 and that `* 2` for bigDiv2x2
    uint private constant MAX_ERROR = 100000000;

    // A larger error threshold to use when multiple rounding errors may apply
    uint private constant MAX_ERROR_BEFORE_DIV = MAX_ERROR * 2;

    /**
     * @notice Returns the approx result of `a * b / d` so long as the result is <= MAX_UINT
     * @param _numA the first numerator term
     * @param _numB the second numerator term
     * @param _den the denominator
     * @return the approx result with up to off by 1 + MAX_ERROR, rounding down if needed
     */
    function bigDiv2x1(
        uint _numA,
        uint _numB,
        uint _den
    ) internal pure returns (uint) {
        if (_numA == 0 || _numB == 0) {
            // would div by 0 or underflow if we don't special case 0
            return 0;
        }

        uint value;

        if (type(uint256).max / _numA >= _numB) {
            // a*b does not overflow, return exact math
            value = _numA * _numB;
            value /= _den;
            return value;
        }

        // Sort numerators
        uint numMax = _numB;
        uint numMin = _numA;
        if (_numA > _numB) {
            numMax = _numA;
            numMin = _numB;
        }

        value = numMax / _den;
        if (value > MAX_ERROR) {
            // _den is small enough to be MAX_ERROR or better w/o a factor
            value = value * numMin;
            return value;
        }

        // formula = ((a / f) * b) / (d / f)
        // factor >= a / sqrt(MAX) * (b / sqrt(MAX))
        uint factor = numMin - 1;
        factor /= MAX_BEFORE_SQUARE;
        factor += 1;
        uint temp = numMax - 1;
        temp /= MAX_BEFORE_SQUARE;
        temp += 1;
        if (type(uint256).max / factor >= temp) {
            factor *= temp;
            value = numMax / factor;
            if (value > MAX_ERROR_BEFORE_DIV) {
                value = value * numMin;
                temp = _den - 1;
                temp /= factor;
                temp = temp + 1;
                value /= temp;
                return value;
            }
        }

        // formula: (a / (d / f)) * (b / f)
        // factor: b / sqrt(MAX)
        factor = numMin - 1;
        factor /= MAX_BEFORE_SQUARE;
        factor += 1;
        value = numMin / factor;
        temp = _den - 1;
        temp /= factor;
        temp += 1;
        temp = numMax / temp;
        value = value * temp;
        return value;
    }

    /**
     * @notice Returns the approx result of `a * b / d` so long as the result is <= MAX_UINT
     * @param _numA the first numerator term
     * @param _numB the second numerator term
     * @param _den the denominator
     * @return the approx result with up to off by 1 + MAX_ERROR, rounding down if needed
     * @dev roundUp is implemented by first rounding down and then adding the max error to the result
     */
    function bigDiv2x1RoundUp(
        uint _numA,
        uint _numB,
        uint _den
    ) internal pure returns (uint) {
        // first get the rounded down result
        uint value = bigDiv2x1(_numA, _numB, _den);

        if (value == 0) {
            // when the value rounds down to 0, assume up to an off by 1 error
            return 1;
        }

        // round down has a max error of MAX_ERROR, add that to the result
        // for a round up error of <= MAX_ERROR
        uint temp = value - 1;
        temp /= MAX_ERROR;
        temp += 1;
        if (type(uint256).max - value < temp) {
            // value + error would overflow, return MAX
            return type(uint256).max;
        }

        value += temp;

        return value;
    }

    /**
     * @notice Returns the approx result of `a * b / (c * d)` so long as the result is <= MAX_UINT
     * @param _numA the first numerator term
     * @param _numB the second numerator term
     * @param _denA the first denominator term
     * @param _denB the second denominator term
     * @return the approx result with up to off by 2 + MAX_ERROR*10 error, rounding down if needed
     * @dev this uses bigDiv2x1 and adds additional rounding error so the max error of this
     * formula is larger
     */
    function bigDiv2x2(
        uint _numA,
        uint _numB,
        uint _denA,
        uint _denB
    ) internal pure returns (uint) {
        if (type(uint256).max / _denA >= _denB) {
            // denA*denB does not overflow, use bigDiv2x1 instead
            return bigDiv2x1(_numA, _numB, _denA * _denB);
        }

        if (_numA == 0 || _numB == 0) {
            // would div by 0 or underflow if we don't special case 0
            return 0;
        }

        // Sort denominators
        uint denMax = _denB;
        uint denMin = _denA;
        if (_denA > _denB) {
            denMax = _denA;
            denMin = _denB;
        }

        uint value;

        if (type(uint256).max / _numA >= _numB) {
            // a*b does not overflow, use `a / d / c`
            value = _numA * _numB;
            value /= denMin;
            value /= denMax;
            return value;
        }

        // `ab / cd` where both `ab` and `cd` would overflow

        // Sort numerators
        uint numMax = _numB;
        uint numMin = _numA;
        if (_numA > _numB) {
            numMax = _numA;
            numMin = _numB;
        }

        // formula = (a/d) * b / c
        uint temp = numMax / denMin;
        if (temp > MAX_ERROR_BEFORE_DIV) {
            return bigDiv2x1(temp, numMin, denMax);
        }

        // formula: ((a/f) * b) / d then either * f / c or / c * f
        // factor >= a / sqrt(MAX) * (b / sqrt(MAX))
        uint factor = numMin - 1;
        factor /= MAX_BEFORE_SQUARE;
        factor += 1;
        temp = numMax - 1;
        temp /= MAX_BEFORE_SQUARE;
        temp += 1;
        if (type(uint256).max / factor >= temp) {
            factor *= temp;

            value = numMax / factor;
            if (value > MAX_ERROR_BEFORE_DIV) {
                value = value * numMin;
                value /= denMin;
                if (value > 0 && type(uint256).max / value >= factor) {
                    value *= factor;
                    value /= denMax;
                    return value;
                }
            }
        }

        // formula: (a/f) * b / ((c*d)/f)
        // factor >= c / sqrt(MAX) * (d / sqrt(MAX))
        factor = denMin;
        factor /= MAX_BEFORE_SQUARE;
        temp = denMax;
        // + 1 here prevents overflow of factor*temp
        temp /= MAX_BEFORE_SQUARE + 1;
        factor *= temp;
        return bigDiv2x1(numMax / factor, numMin, type(uint256).max);
    }
}


// File contracts/math/Sqrt.sol

pragma solidity ^0.8.0;

/**
 * @title Calculates the square root of a given value.
 * @dev Results may be off by 1.
 */
library Sqrt {
    // Source: https://github.com/ethereum/dapp-bin/pull/50
    function sqrt(uint x) internal pure returns (uint y) {
        if (x == 0) {
            return 0;
        } else if (x <= 3) {
            return 1;
        } else if (x == type(uint256).max) {
            // Without this we fail on x + 1 below
            return 2**128 - 1;
        }

        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/access/[email protected]


pragma solidity ^0.8.0;


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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}


// File contracts/mixins/OperatorRole.sol

pragma solidity ^0.8.0;

// Original source: openzeppelin's SignerRole

/**
 * @notice allows a single owner to manage a group of operators which may
 * have some special permissions in the contract.
 */
contract OperatorRole is OwnableUpgradeable {
    mapping (address => bool) internal _operators;

    event OperatorAdded(address indexed account);
    event OperatorRemoved(address indexed account);

    function _initializeOperatorRole() internal {
        __Ownable_init();
        _addOperator(msg.sender);
    }

    modifier onlyOperator() {
        require(
            isOperator(msg.sender),
            "OperatorRole: caller does not have the Operator role"
        );
        _;
    }

    function isOperator(address account) public view returns (bool) {
        return _operators[account];
    }

    function addOperator(address account) public onlyOwner {
        _addOperator(account);
    }

    function removeOperator(address account) public onlyOwner {
        _removeOperator(account);
    }

    function renounceOperator() public {
        _removeOperator(msg.sender);
    }

    function _addOperator(address account) internal {
        _operators[account] = true;
        emit OperatorAdded(account);
    }

    function _removeOperator(address account) internal {
        _operators[account] = false;
        emit OperatorRemoved(account);
    }

    uint[50] private ______gap;
}


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity ^0.8.0;

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
        // This method relies on extcodesize, which returns 0 for contracts in
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
        return functionCallWithValue(target, data, 0, errorMessage);
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
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File contracts/CAFE.sol

pragma solidity ^0.8.3;
pragma abicoder v2;





/**
 * @title Continuous Agreement for Future Equity
 */
contract CAFE
    is ERC20ReInitializable
{
    using Sqrt for uint;
    using SafeERC20 for IERC20;
    event Buy(
        address indexed _from,
        address indexed _to,
        uint _currencyValue,
        uint _fairValue
    );
    event Sell(
        address indexed _from,
        address indexed _to,
        uint _currencyValue,
        uint _fairValue
    );
    event Burn(
        address indexed _from,
        uint _fairValue
    );
    event StateChange(
        uint _previousState,
        uint _newState
    );
    event Close();
    event UpdateConfig(
        address _whitelistAddress,
        address indexed _beneficiary,
        address indexed _control,
        address indexed _feeCollector,
        uint _feeBasisPoints,
        uint _minInvestment,
        uint _minDuration,
        uint _stakeholdersPoolAuthorized,
        uint _gasFee
    );

    //
    // Constants
    //

    enum State {
        Init,
        Run,
        Close,
        Cancel
    }

    // The denominator component for values specified in basis points.
    uint internal constant BASIS_POINTS_DEN = 10000;

    uint internal constant MAX_ITERATION = 10;

    /**
     * Data specific to our token business logic
     */

    /// @notice The contract for transfer authorizations, if any.
    IWhitelist public whitelist;

    /// @notice The total number of burned FAIR tokens, excluding tokens burned from a `Sell` action in the DAT.
    uint public burnedSupply;

    /**
     * Data for DAT business logic
     */

    /// @notice The address of the beneficiary organization which receives the investments.
    /// Points to the wallet of the organization.
    address payable public beneficiary;

    struct BuySlope {
        uint128 num;
        uint128 den;
    }

    BuySlope public buySlope;

    /// @notice The address from which the updatable variables can be updated
    address public control;

    /// @notice The address of the token used as reserve in the bonding curve
    /// (e.g. the DAI contract). Use ETH if 0.
    IERC20 public currency;

    /// @notice The address where fees are sent.
    address payable public feeCollector;

    /// @notice The percent fee collected each time new FAIR are issued expressed in basis points.
    uint public feeBasisPoints;

    /// @notice The initial fundraising goal (expressed in FAIR) to start the c-org.
    /// `0` means that there is no initial fundraising and the c-org immediately moves to run state.
    uint public initGoal;

    /// @notice A map with all investors in init state using address as a key and amount as value.
    /// @dev This structure's purpose is to make sure that only investors can withdraw their money if init_goal is not reached.
    mapping(address => uint) public initInvestors;

    /// @notice The initial number of FAIR created at initialization for the beneficiary.
    /// Technically however, this variable is not a constant as we must always have
    ///`init_reserve>=total_supply+burnt_supply` which means that `init_reserve` will be automatically
    /// decreased to equal `total_supply+burnt_supply` in case `init_reserve>total_supply+burnt_supply`
    /// after an investor sells his FAIRs.
    /// @dev Organizations may move these tokens into vesting contract(s)
    uint public initReserve;

    /// @notice The minimum amount of `currency` investment accepted.
    uint public minInvestment;

    /// @notice The current state of the contract.
    /// @dev See the constants above for possible state values.
    State public state;

    /// @dev If this value changes we need to reconstruct the DOMAIN_SEPARATOR
    string public constant version = "cafe-2.0";
    // --- EIP712 niceties ---
    // Original source: https://etherscan.io/address/0x6b175474e89094c44da98b954eedeac495271d0f#code
    mapping (address => uint) public nonces;
    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    // The success fee (expressed in currency) that will be earned by setupFeeRecipient as soon as initGoal
    // is reached. We must have setup_fee <= buy_slope*init_goal^(2)/2
    uint public setupFee;

    // The recipient of the setup_fee once init_goal is reached
    address payable public setupFeeRecipient;

    /// @notice The minimum time before which the c-org contract cannot be closed once the contract has
    /// reached the `run` state.
    /// @dev When updated, the new value of `minimum_duration` cannot be earlier than the previous value.
    uint public minDuration;

    /// @dev Initialized at `0` and updated when the contract switches from `init` state to `run` state
    /// or when the initial trial period ends.
    uint private startedOn;

    // keccak256("PermitBuy(address from,address to,uint256 currencyValue,uint256 minTokensBought,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_BUY_TYPEHASH = 0xaf42a244b3020d6a2253d9f291b4d3e82240da42b22129a8113a58aa7a3ddb6a;

    // keccak256("PermitSell(address from,address to,uint256 quantityToSell,uint256 minCurrencyReturned,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_SELL_TYPEHASH = 0x5dfdc7fb4c68a4c249de5e08597626b84fbbe7bfef4ed3500f58003e722cc548;

    // stkaeholdersPool struct separated
    uint public stakeholdersPoolIssued;

    uint public stakeholdersPoolAuthorized;

    // The orgs commitement that backs the value of CAFEs.
    // This value may be increased but not decreased.
    uint public equityCommitment;

    // Total number of tokens that have been attributed to current shareholders
    uint public shareholdersPool;

    // The max number of CAFEs investors can purchase (excludes the stakeholdersPool)
    uint public maxGoal;

    // The amount of CAFE to be sold to exit the trial mode.
    // 0 means there is no trial.
    uint public initTrial;

    // Represents the fundraising amount that can be sold as a fixed price
    uint public fundraisingGoal;

    // To fund operator a gasFee
    uint public gasFee;

    // increased when manual buy
    uint public manualBuybackReserve;

    uint public totalInvested;

    bytes32 private constant BEACON_SLOT = keccak256(abi.encodePacked("fairmint.beaconproxy.beacon"));
    modifier onlyBeaconOperator() {
        bytes32 slot = BEACON_SLOT;
        address beacon;
        assembly {
            beacon := sload(slot)
        }
        require(beacon == address(0) || OperatorRole(beacon).isOperator(msg.sender), "!BeaconOperator");
        _;
    }

    modifier authorizeTransfer(
        address _from,
        address _to,
        uint _value,
        bool _isSell
    )
    {
        require(state != State.Close, "INVALID_STATE");
        if(address(whitelist) != address(0))
        {
            // This is not set for the minting of initialReserve
            whitelist.authorizeTransfer(_from, _to, _value, _isSell);
        }
        _;
    }

    /**
     * BuySlope
     */
    function buySlopeNum() external view returns(uint256) {
        return uint256(buySlope.num);
    }

    function buySlopeDen() external view returns(uint256) {
        return uint256(buySlope.den);
    }

    /**
     * Stakeholders Pool
     */
    function stakeholdersPool() public view returns (uint256 issued, uint256 authorized) {
        return (stakeholdersPoolIssued, stakeholdersPoolAuthorized);
    }

    function trialEndedOn() public view returns(uint256 timestamp) {
        return startedOn;
    }

    /**
     * Buyback reserve
     */

    /// @notice The total amount of currency value currently locked in the contract and available to sellers.
    function buybackReserve() public view returns (uint)
    {
        uint reserve = address(this).balance;
        if(address(currency) != address(0))
        {
            reserve = currency.balanceOf(address(this));
        }

        if(reserve > type(uint128).max)
        {
            /// Math: If the reserve becomes excessive, cap the value to prevent overflowing in other formulas
            return type(uint128).max;
        }

        return reserve + manualBuybackReserve;
    }

    /**
     * Functions required by the ERC-20 token standard
     */

    /// @dev Moves tokens from one account to another if authorized.
    function _transfer(
        address _from,
        address _to,
        uint _amount
    ) internal override
        authorizeTransfer(_from, _to, _amount, false)
    {
        require(state != State.Init || _from == beneficiary, "ONLY_BENEFICIARY_DURING_INIT");
        super._transfer(_from, _to, _amount);
    }

    /// @dev Removes tokens from the circulating supply.
    function _burn(
        address _from,
        uint _amount,
        bool _isSell
    ) internal
        authorizeTransfer(_from, address(0), _amount, _isSell)
    {
        super._burn(_from, _amount);

        if(!_isSell)
        {
            // This is a burn
            // SafeMath not required as we cap how high this value may get during mint
            burnedSupply += _amount;
            emit Burn(_from, _amount);
        }
    }

    /// @notice Called to mint tokens on `buy`.
    function _mint(
        address _to,
        uint _quantity
    ) internal override
        authorizeTransfer(address(0), _to, _quantity, false)
    {
        super._mint(_to, _quantity);

        // Math: If this value got too large, the DAT may overflow on sell
        require(totalSupply() + burnedSupply <= type(uint128).max, "EXCESSIVE_SUPPLY");
    }

    /**
     * Transaction Helpers
     */

    /// @notice Confirms the transfer of `_quantityToInvest` currency to the contract.
    function _collectInvestment(
        address payable _from,
        uint _quantityToInvest,
        uint _msgValue
    ) internal
    {
        if(address(currency) == address(0))
        {
            // currency is ETH
            require(_quantityToInvest == _msgValue, "INCORRECT_MSG_VALUE");
        }
        else
        {
            // currency is ERC20
            require(_msgValue == 0, "DO_NOT_SEND_ETH");

            currency.safeTransferFrom(_from, address(this), _quantityToInvest);
        }
    }

    /// @dev Send `_amount` currency from the contract to the `_to` account.
    function _transferCurrency(
        address payable _to,
        uint _amount
    ) internal
    {
        if(_amount > 0)
        {
            if(address(currency) == address(0))
            {
                Address.sendValue(_to, _amount);
            }
            else
            {
                currency.safeTransfer(_to, _amount);
            }
        }
    }

    /**
     * Config / Control
     */

    struct MileStone {
        uint128 initReserve;
        uint128 initTrial;
        uint128 initGoal;
        uint128 maxGoal;
    }

    /// @notice Called once after deploy to set the initial configuration.
    /// None of the values provided here may change once initially set.
    /// @dev using the init pattern in order to support zos upgrades
    function initialize(
        string calldata _name,
        string calldata _symbol,
        address _currencyAddress,
        MileStone calldata _mileStone,
        BuySlope calldata _buySlope,
        uint _stakeholdersAuthorized,
        uint _equityCommitment,
        uint _setupFee,
        address payable _setupFeeRecipient
    ) external
        onlyBeaconOperator
    {
        // _initialize will enforce this is only called once
        // The ERC-20 implementation will confirm initialize is only run once
        ERC20ReInitializable.__ERC20_init(_name, _symbol);
        _initialize(
            _currencyAddress,
            _mileStone,
            _buySlope,
            _stakeholdersAuthorized,
            _equityCommitment,
            _setupFee,
            _setupFeeRecipient
        );
    }

    function reInitialize(
        string calldata _name,
        string calldata _symbol,
        address _currencyAddress,
        MileStone calldata _mileStone,
        BuySlope calldata _buySlope,
        uint _stakeholdersAuthorized,
        uint _equityCommitment,
        uint _setupFee,
        address payable _setupFeeRecipient
    ) external {
        require(msg.sender == beneficiary, "ONLY_BENEFICIARY_CAN_REINITIALIZE");
        require(balanceOf(msg.sender) == totalSupply(), "BENEFICIARY_SHOULD_HAVE_ALL_TOKENS");
        require(initReserve == totalSupply(), "SHOULD_NOT_HAVE_RECEIVED_ANY_FUND");
        ERC20ReInitializable.__ERC20_re_initialize(_name, _symbol);
        _burn(msg.sender, totalSupply());
        _initialize(
            _currencyAddress,
            _mileStone,
            _buySlope,
            _stakeholdersAuthorized,
            _equityCommitment,
            _setupFee,
            _setupFeeRecipient
        );
    }

    function _initialize(
        address _currencyAddress,
        MileStone memory _mileStone,
        BuySlope memory _buySlope,
        uint _stakeholdersAuthorized,
        uint _equityCommitment,
        uint _setupFee,
        address payable _setupFeeRecipient
    ) internal {
        require(_buySlope.num > 0, "INVALID_SLOPE_NUM");
        require(_buySlope.den > 0, "INVALID_SLOPE_DEN");
        buySlope = _buySlope;

        // Setup Fee
        require(_setupFee == 0 || _setupFeeRecipient != address(0), "MISSING_SETUP_FEE_RECIPIENT");
        require(_setupFeeRecipient == address(0) || _setupFee != 0, "MISSING_SETUP_FEE");
        // setup_fee <= (n/d)*(g^2)/2
        uint initGoalInCurrency = uint256(_mileStone.initGoal) * uint256(_mileStone.initGoal);
        initGoalInCurrency = initGoalInCurrency * uint256(_buySlope.num);
        initGoalInCurrency /= 2 * uint256(_buySlope.den);
        require(_setupFee <= initGoalInCurrency, "EXCESSIVE_SETUP_FEE");
        setupFee = _setupFee;
        setupFeeRecipient = _setupFeeRecipient;

        // Set default values (which may be updated using `updateConfig`)
        uint decimals = 18;
        if(_currencyAddress != address(0)){
            decimals = IERC20Metadata(_currencyAddress).decimals();
        }
        minInvestment = 100 * (10 ** decimals);
        beneficiary = payable(msg.sender);
        control = msg.sender;
        feeCollector = payable(msg.sender);

        // Save currency
        currency = IERC20(_currencyAddress);

        // Mint the initial reserve
        if(_mileStone.initReserve > 0)
        {
            initReserve = _mileStone.initReserve;
            _mint(beneficiary, initReserve);
        }

        initializeDomainSeparator();
        // Math: If this value got too large, the DAT would overflow on sell
        // new settings for CAFE
        require(_mileStone.maxGoal == 0 || _mileStone.initGoal == 0 || _mileStone.maxGoal >= _mileStone.initGoal, "MAX_GOAL_SMALLER_THAN_INIT_GOAL");
        require(_mileStone.initGoal == 0 || _mileStone.initTrial == 0 || _mileStone.initGoal >= _mileStone.initTrial, "INIT_GOAL_SMALLER_THAN_INIT_TRIAL");
        maxGoal = _mileStone.maxGoal;
        initTrial = _mileStone.initTrial;
        stakeholdersPoolIssued = _mileStone.initReserve;
        require(_stakeholdersAuthorized <= BASIS_POINTS_DEN, "STAKEHOLDERS_POOL_AUTHORIZED_SHOULD_BE_SMALLER_THAN_BASIS_POINTS_DEN");
        stakeholdersPoolAuthorized = _stakeholdersAuthorized;
        require(_equityCommitment > 0, "EQUITY_COMMITMENT_CANNOT_BE_ZERO");
        require(_equityCommitment <= BASIS_POINTS_DEN, "EQUITY_COMMITMENT_SHOULD_BE_LESS_THAN_100%");
        equityCommitment = _equityCommitment;
        // Set initGoal, which in turn defines the initial state
        if(_mileStone.initGoal == 0)
        {
            _stateChange(State.Run);
            startedOn = block.timestamp;
        }
        else
        {
            initGoal = _mileStone.initGoal;
            state = State.Init;
            startedOn = 0;
        }
    }

    function _stateChange(State _state) internal {
        emit StateChange(uint256(state), uint256(_state));
        state = _state;
    }

    function updateConfig(
        address _whitelistAddress,
        address payable _beneficiary,
        address _control,
        address payable _feeCollector,
        uint _feeBasisPoints,
        uint _minInvestment,
        uint _minDuration,
        uint _stakeholdersAuthorized,
        uint _gasFee
    ) external
    {
        // This require(also confirms that initialize has been called.
        require(msg.sender == control, "CONTROL_ONLY");

        // address(0) is okay
        whitelist = IWhitelist(_whitelistAddress);

        require(_control != address(0), "INVALID_ADDRESS");
        control = _control;

        require(_feeCollector != address(0), "INVALID_ADDRESS");
        feeCollector = _feeCollector;

        require(_feeBasisPoints <= BASIS_POINTS_DEN, "INVALID_FEE");
        feeBasisPoints = _feeBasisPoints;

        require(_minInvestment > 0, "INVALID_MIN_INVESTMENT");
        minInvestment = _minInvestment;

        require(_minDuration >= minDuration, "MIN_DURATION_MAY_NOT_BE_REDUCED");
        minDuration = _minDuration;

        if(beneficiary != _beneficiary)
        {
            require(_beneficiary != address(0), "INVALID_ADDRESS");
            uint tokens = balanceOf(beneficiary);
            initInvestors[_beneficiary] = initInvestors[_beneficiary] + initInvestors[beneficiary];
            initInvestors[beneficiary] = 0;
            if(tokens > 0)
            {
                _transfer(beneficiary, _beneficiary, tokens);
            }
            beneficiary = _beneficiary;
        }

        // new settings for CAFE
        require(_stakeholdersAuthorized <= BASIS_POINTS_DEN, "STAKEHOLDERS_POOL_AUTHORIZED_SHOULD_BE_SMALLER_THAN_BASIS_POINTS_DEN");
        stakeholdersPoolAuthorized = _stakeholdersAuthorized;

        gasFee = _gasFee;

        emit UpdateConfig(
            _whitelistAddress,
            _beneficiary,
            _control,
            _feeCollector,
            _feeBasisPoints,
            _minInvestment,
            _minDuration,
            _stakeholdersAuthorized,
            _gasFee
        );
    }

    /// @notice Used to initialize the domain separator used in meta-transactions
    /// @dev This is separate from `initialize` to allow upgraded contracts to update the version
    /// There is no harm in calling this multiple times / no permissions required
    function initializeDomainSeparator() public
    {
        uint id;
        // solium-disable-next-line
        assembly
        {
            id := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name())),
                keccak256(bytes(version)),
                id,
                address(this)
            )
        );
    }

    /**
     * Functions for our business logic
     */

    /// @notice Burn the amount of tokens from the address msg.sender if authorized.
    /// @dev Note that this is not the same as a `sell` via the DAT.
    function burn(
        uint _amount
    ) public
    {
        require(state == State.Run, "INVALID_STATE");
        require(msg.sender == beneficiary, "BENEFICIARY_ONLY");
        _burn(msg.sender, _amount, false);
    }

    // Buy

    /// @notice Purchase FAIR tokens with the given amount of currency.
    /// @param _to The account to receive the FAIR tokens from this purchase.
    /// @param _currencyValue How much currency to spend in order to buy FAIR.
    /// @param _minTokensBought Buy at least this many FAIR tokens or the transaction reverts.
    /// @dev _minTokensBought is necessary as the price will change if some elses transaction mines after
    /// yours was submitted.
    function buy(
        address _to,
        uint _currencyValue,
        uint _minTokensBought
    ) public payable
    {
        _collectInvestment(payable(msg.sender), _currencyValue, msg.value);
        //deduct gas fee and send it to feeCollector
        uint256 currencyValue = _currencyValue - gasFee;
        _transferCurrency(feeCollector, gasFee);
        _buy(payable(msg.sender), _to, currencyValue, _minTokensBought, false);
    }

    /// @notice Allow users to sign a message authorizing a buy
    function permitBuy(
        address payable _from,
        address _to,
        uint _currencyValue,
        uint _minTokensBought,
        uint _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external
    {
        require(_deadline >= block.timestamp, "EXPIRED");
        bytes32 digest = keccak256(abi.encode(PERMIT_BUY_TYPEHASH, _from, _to, _currencyValue, _minTokensBought, nonces[_from]++, _deadline));
        digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                digest
            )
        );
        address recoveredAddress = ecrecover(digest, _v, _r, _s);
        require(recoveredAddress != address(0) && recoveredAddress == _from, "INVALID_SIGNATURE");
        // CHECK !!! this is suspicious!! 0 should be msg.value but this is not payable function
        // msg.value will be zero since it is non-payable function and designed to be used to usdc-base CAFE contract
        _collectInvestment(_from, _currencyValue, 0);
        uint256 currencyValue = _currencyValue - gasFee;
        _transferCurrency(feeCollector, gasFee);
        _buy(_from, _to, currencyValue, _minTokensBought, false);
    }

    function _buy(
        address payable _from,
        address _to,
        uint _currencyValue,
        uint _minTokensBought,
        bool _manual
    ) internal
    {
        require(_to != address(0), "INVALID_ADDRESS");
        require(_to != beneficiary, "BENEFICIARY_CANNOT_BUY");
        require(_minTokensBought > 0, "MUST_BUY_AT_LEAST_1");
        require(state == State.Init || state == State.Run, "ONLY_BUY_IN_INIT_OR_RUN");
        // Calculate the tokenValue for this investment
        // returns zero if _currencyValue < minInvestment
        uint tokenValue = _estimateBuyValue(_currencyValue);
        require(tokenValue >= _minTokensBought, "PRICE_SLIPPAGE");
        if(state == State.Init){
            if(tokenValue + shareholdersPool < initTrial){
                //already received all currency from _collectInvestment
                if(!_manual) {
                    initInvestors[_to] = initInvestors[_to] + tokenValue;
                }
                initTrial = initTrial - tokenValue;
            }
            else if (initTrial > shareholdersPool){
                //already received all currency from _collectInvestment
                //send setup fee to beneficiary
                if(setupFee > 0){
                    _transferCurrency(setupFeeRecipient, setupFee);
                }
                _distributeInvestment(buybackReserve() - manualBuybackReserve);
                manualBuybackReserve = 0;
                initTrial = shareholdersPool;
                startedOn = block.timestamp;
            }
            else{
                _distributeInvestment(buybackReserve() - manualBuybackReserve);
                manualBuybackReserve = 0;
            }
        }
        else { //state == State.Run
            require(maxGoal == 0 || tokenValue + totalSupply() - stakeholdersPoolIssued <= maxGoal, "EXCEEDING_MAX_GOAL");
            _distributeInvestment(buybackReserve() - manualBuybackReserve);
            manualBuybackReserve = 0;
            if(fundraisingGoal != 0){
                if (tokenValue >= fundraisingGoal){
                    changeBuySlope(totalSupply() - stakeholdersPoolIssued, fundraisingGoal + totalSupply() - stakeholdersPoolIssued);
                    fundraisingGoal = 0;
                } else { //if (tokenValue < fundraisingGoal) {
                    changeBuySlope(totalSupply() - stakeholdersPoolIssued, tokenValue + totalSupply() - stakeholdersPoolIssued);
                    fundraisingGoal -= tokenValue;
                }
            }
        }

        totalInvested = totalInvested + _currencyValue;

        emit Buy(_from, _to, _currencyValue, tokenValue);
        _mint(_to, tokenValue);

        if(state == State.Init && totalSupply() - stakeholdersPoolIssued >= initGoal){
            _stateChange(State.Run);
        }
    }

    /// @dev Distributes _value currency between the beneficiary and feeCollector.
    function _distributeInvestment(
        uint _value
    ) internal
    {
        uint fee = _value * feeBasisPoints;
        fee /= BASIS_POINTS_DEN;

        // Math: since feeBasisPoints is <= BASIS_POINTS_DEN, this will never underflow.
        _transferCurrency(beneficiary, _value - fee);
        _transferCurrency(feeCollector, fee);
    }

    function estimateBuyValue(
        uint _currencyValue
    ) external view
    returns(uint)
    {
        return _estimateBuyValue(_currencyValue - gasFee);
    }

    /// @notice Calculate how many FAIR tokens you would buy with the given amount of currency if `buy` was called now.
    /// @param _currencyValue How much currency to spend in order to buy FAIR.
    function _estimateBuyValue(
        uint _currencyValue
    ) internal view
    returns(uint)
    {
        if(_currencyValue < minInvestment){
            return 0;
        }
        if(state == State.Init){
            uint currencyValue = _currencyValue;
            uint _totalSupply = totalSupply();
            uint max = BigDiv.bigDiv2x1(
                initGoal * buySlope.num,
                initGoal - (_totalSupply - stakeholdersPoolIssued),
                buySlope.den
            );

            if(currencyValue > max)
            {
                currencyValue = max;
            }

            uint256 tokenAmount = BigDiv.bigDiv2x1(
                currencyValue,
                buySlope.den,
                initGoal * buySlope.num
            );
            if(currencyValue != _currencyValue)
            {
                currencyValue = _currencyValue - max;
                // ((2*next_amount/buy_slope)+init_goal^2)^(1/2)-init_goal
                // a: next_amount | currencyValue
                // n/d: buy_slope (type(uint128).max / type(uint128).max)
                // g: init_goal (type(uint128).max/2)
                // r: init_reserve (type(uint128).max/2)
                // sqrt(((2*a/(n/d))+g^2)-g
                // sqrt((2 d a + n g^2)/n) - g

                // currencyValue == 2 d a
                uint temp = 2 * buySlope.den;
                currencyValue = temp * currencyValue;

                // temp == g^2
                temp = initGoal;
                temp *= temp;

                // temp == n g^2
                temp = temp * buySlope.num;

                // temp == (2 d a) + n g^2
                temp = currencyValue + temp;

                // temp == (2 d a + n g^2)/n
                temp /= buySlope.num;

                // temp == sqrt((2 d a + n g^2)/n)
                temp = temp.sqrt();

                // temp == sqrt((2 d a + n g^2)/n) - g
                temp -= initGoal;

                tokenAmount = tokenAmount + temp;
            }
            return tokenAmount;
        }
        else if(state == State.Run) {//state == State.Run{
            uint supply = totalSupply() - stakeholdersPoolIssued;
            // calculate fundraising amount (static price)
            uint currencyValue = _currencyValue;
            uint fundraisedAmount;
            if(fundraisingGoal > 0){
                uint max = BigDiv.bigDiv2x1(
                    supply,
                    fundraisingGoal * buySlope.num,
                    buySlope.den
                );
                if(currencyValue > max){
                    currencyValue = max;
                }
                fundraisedAmount = BigDiv.bigDiv2x2(
                    currencyValue,
                    buySlope.den,
                    supply,
                    buySlope.num
                );
                //forward leftover currency to be used as normal buy
                currencyValue = _currencyValue - currencyValue;
            }

            // initReserve is reduced on sell as necessary to ensure that this line will not overflow
            // Math: worst case
            // MAX * 2 * type(uint128).max
            // / type(uint128).max
            uint tokenAmount = BigDiv.bigDiv2x1(
                currencyValue,
                2 * buySlope.den,
                buySlope.num
            );

            // Math: worst case MAX + (type(uint128).max * type(uint128).max)
            tokenAmount = tokenAmount + supply * supply;
            tokenAmount = tokenAmount.sqrt();

            // Math: small chance of underflow due to possible rounding in sqrt
            tokenAmount = tokenAmount - supply;
            return fundraisedAmount + tokenAmount;
        } else {
            return 0;
        }
    }

    // Sell

    /// @notice Sell FAIR tokens for at least the given amount of currency.
    /// @param _to The account to receive the currency from this sale.
    /// @param _quantityToSell How many FAIR tokens to sell for currency value.
    /// @param _minCurrencyReturned Get at least this many currency tokens or the transaction reverts.
    /// @dev _minCurrencyReturned is necessary as the price will change if some elses transaction mines after
    /// yours was submitted.
    function sell(
        address payable _to,
        uint _quantityToSell,
        uint _minCurrencyReturned
    ) public
    {
        _sell(msg.sender, _to, _quantityToSell, _minCurrencyReturned);
    }

    /// @notice Allow users to sign a message authorizing a sell
    function permitSell(
        address _from,
        address payable _to,
        uint _quantityToSell,
        uint _minCurrencyReturned,
        uint _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external
    {
        require(_deadline >= block.timestamp, "EXPIRED");
        bytes32 digest = keccak256(
            abi.encode(PERMIT_SELL_TYPEHASH, _from, _to, _quantityToSell, _minCurrencyReturned, nonces[_from]++, _deadline)
        );
        digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                digest
            )
        );
        address recoveredAddress = ecrecover(digest, _v, _r, _s);
        require(recoveredAddress != address(0) && recoveredAddress == _from, "INVALID_SIGNATURE");
        _sell(_from, _to, _quantityToSell, _minCurrencyReturned);
    }

    function _sell(
        address _from,
        address payable _to,
        uint _quantityToSell,
        uint _minCurrencyReturned
    ) internal
    {
        require(_from != beneficiary, "BENEFICIARY_CANNOT_SELL");
        require(state != State.Init || initTrial != shareholdersPool, "INIT_TRIAL_ENDED");
        require(state == State.Init || state == State.Cancel, "ONLY_SELL_IN_INIT_OR_CANCEL");
        require(_minCurrencyReturned > 0, "MUST_SELL_AT_LEAST_1");
        // check for slippage
        uint currencyValue = estimateSellValue(_quantityToSell);
        require(currencyValue >= _minCurrencyReturned, "PRICE_SLIPPAGE");
        // it will work as checking _from has morethan _quantityToSell as initInvestors
        initInvestors[_from] = initInvestors[_from] - _quantityToSell;
        _burn(_from, _quantityToSell, true);
        _transferCurrency(_to, currencyValue);
        if(state == State.Init && initTrial != 0){
            // this can only happen if initTrial is set to zero from day one
            initTrial = initTrial + _quantityToSell;
        }
        totalInvested = totalInvested - currencyValue;
        emit Sell(_from, _to, currencyValue, _quantityToSell);
    }

    function estimateSellValue(
        uint _quantityToSell
    ) public view
        returns(uint)
    {
        if(state != State.Init && state != State.Cancel){
            return 0;
        }
        uint reserve = buybackReserve();

        // Calculate currencyValue for this sale
        uint currencyValue;
        // State.Init or State.Cancel
        // Math worst case:
        // MAX * type(uint128).max
        currencyValue = _quantityToSell * reserve;
        // Math: FAIR blocks initReserve from being burned unless we reach the RUN state which prevents an underflow
        currencyValue /= totalSupply() - stakeholdersPoolIssued - shareholdersPool;

        return currencyValue;
    }


    // Close

    /// @notice Called by the beneficiary account to State.Close or State.Cancel the c-org,
    /// preventing any more tokens from being minted.
    function close() public
    {
        _close();
        emit Close();
    }

    /// @notice Called by the beneficiary account to State.Close or State.Cancel the c-org,
    /// preventing any more tokens from being minted.
    /// @dev Requires an `exitFee` to be paid.    If the currency is ETH, include a little more than
    /// what appears to be required and any remainder will be returned to your account.    This is
    /// because another user may have a transaction mined which changes the exitFee required.
    /// For other `currency` types, the beneficiary account will be billed the exact amount required.
    function _close() internal
    {
        require(msg.sender == beneficiary, "BENEFICIARY_ONLY");

        if(state == State.Init)
        {
            // Allow the org to cancel anytime if the initGoal was not reached.
            require(initTrial > shareholdersPool,"CANNOT_CANCEL_IF_INITTRIAL_IS_ZERO");
            _stateChange(State.Cancel);
        }
        else if(state == State.Run)
        {
            require(type(uint256).max - minDuration > startedOn, "MAY_NOT_CLOSE");
            require(minDuration + startedOn <= block.timestamp, "TOO_EARLY");
            _stateChange(State.Close);
        }
        else
        {
            revert("INVALID_STATE");
        }
    }

    /// @notice mint new CAFE and send them to `wallet`
    function mint(
        address _wallet,
        uint256 _amount
    ) external
    {
        require(msg.sender == beneficiary, "ONLY_BENEFICIARY_CAN_MINT");
        require(
            _amount + stakeholdersPoolIssued <= (stakeholdersPoolAuthorized * (totalSupply() + _amount)) / BASIS_POINTS_DEN,
            "CANNOT_MINT_MORE_THAN_AUTHORIZED_PERCENTAGE"
        );
        //update stakeholdersPool issued value
        stakeholdersPoolIssued = stakeholdersPoolIssued + _amount;
        address to = _wallet == address(0) ? beneficiary : _wallet;
        //check if wallet is whitelist in the _mint() function
        _mint(to, _amount);
    }

    function manualBuy(
        address payable _wallet,
        uint256 _currencyValue
    ) external
    {
        require(msg.sender == beneficiary, "ONLY_BENEFICIARY_CAN_MINT");
        manualBuybackReserve += _currencyValue;
        _buy(_wallet, _wallet, _currencyValue, 1, true);
    }

    function increaseCommitment(
        uint256 _newCommitment,
        uint256 _amount
    ) external
    {
        require(state == State.Init || state == State.Run, "ONLY_IN_INIT_OR_RUN");
        require(msg.sender == beneficiary, "ONLY_BENEFICIARY_CAN_INCREASE_COMMITMENT");
        require(_newCommitment > 0, "COMMITMENT_CANT_BE_ZERO");
        require(equityCommitment + _newCommitment <= BASIS_POINTS_DEN, "EQUITY_COMMITMENT_SHOULD_BE_LESS_THAN_100%");
        equityCommitment = equityCommitment + _newCommitment;
        if(_amount > 0 ){
            if(state == State.Init){
                changeBuySlope(initGoal, _amount + initGoal);
                initGoal = initGoal + _amount;
            } else {
                fundraisingGoal = _amount;
            }
            if(maxGoal != 0){
                maxGoal = maxGoal + _amount;
            }
        }
    }

    function convertToCafe(
        uint256 _newCommitment,
        uint256 _amount,
        address _wallet
    ) external {
        require(state == State.Init || state == State.Run, "ONLY_IN_INIT_OR_RUN");
        require(msg.sender == beneficiary, "ONLY_BENEFICIARY_CAN_INCREASE_COMMITMENT");
        require(_newCommitment > 0, "COMMITMENT_CANT_BE_ZERO");
        require(equityCommitment + _newCommitment <= BASIS_POINTS_DEN, "EQUITY_COMMITMENT_SHOULD_BE_LESS_THAN_100%");
        require(_wallet != beneficiary && _wallet != address(0), "WALLET_CANNOT_BE_ZERO_OR_BENEFICIARY");
        equityCommitment = equityCommitment + _newCommitment;
        if(_amount > 0 ){
            shareholdersPool = shareholdersPool + _amount;
            if(state == State.Init){
                changeBuySlope(initGoal, _amount + initGoal);
                initGoal = initGoal + _amount;
                if(initTrial != 0){
                    initTrial = initTrial + _amount;
                }
            }
            else {
                changeBuySlope(totalSupply() - stakeholdersPoolIssued, _amount + totalSupply() - stakeholdersPoolIssued);
            }
            _mint(_wallet, _amount);
            if(maxGoal != 0){
                maxGoal = maxGoal + _amount;
            }
        }
    }

    function increaseValuation(uint256 _newValuation) external {
        require(state == State.Init || state == State.Run, "ONLY_IN_INIT_OR_RUN");
        require(msg.sender == beneficiary, "ONLY_BENEFICIARY_CAN_INCREASE_VALUATION");
        uint256 oldValuation;
        if(state == State.Init){
            oldValuation = (initGoal * initGoal * buySlope.num * BASIS_POINTS_DEN) / (buySlope.den * equityCommitment);
            require(_newValuation > oldValuation, "VALUATION_CAN_NOT_DECREASE");
            changeBuySlope(_newValuation, oldValuation);
        }else {
            oldValuation = ((totalSupply() - stakeholdersPoolIssued) * (totalSupply() - stakeholdersPoolIssued) * buySlope.num * BASIS_POINTS_DEN) / (buySlope.den * equityCommitment);
            require(_newValuation > oldValuation, "VALUATION_CAN_NOT_DECREASE");
            changeBuySlope(_newValuation, oldValuation);
        }
    }

    function changeBuySlope(uint256 _numerator, uint256 _denominator) internal {
        require(_denominator > 0, "DIV_0");
        if(_numerator == 0){
            buySlope.num = 0;
            return;
        }
        uint256 tryDen = BigDiv.bigDiv2x1(
            buySlope.den,
            _denominator,
            _numerator
        );
        if(tryDen <= type(uint128).max){
            buySlope.den = uint128(tryDen);
            return;
        }
        //if den exceeds type(uint128).max try num
        uint256 tryNum = BigDiv.bigDiv2x1(
            buySlope.num,
            _numerator,
            _denominator
        );
        if(tryNum > 0 && tryNum <= type(uint128).max) {
            buySlope.num = uint128(tryNum);
            return;
        }
        revert("error while changing slope");
    }

    function batchTransfer(address[] calldata recipients, uint256[] calldata amounts) external {
        require(msg.sender == beneficiary, "ONLY_BENEFICIARY_CAN_BATCH_TRANSFER");
        require(recipients.length == amounts.length, "ARRAY_LENGTH_DIFF");
        require(recipients.length <= MAX_ITERATION, "EXCEEDS_MAX_ITERATION");
        for(uint256 i = 0; i<recipients.length; i++) {
            _transfer(msg.sender, recipients[i], amounts[0]);
        }
    }

    /// @notice Pay the organization on-chain without minting any tokens.
    /// @dev This allows you to add funds directly to the buybackReserve.
    receive() external payable {
        require(address(currency) == address(0), "ONLY_FOR_CURRENCY_ETH");
    }


    // --- Approve by signature ---
    // EIP-2612
    // Original source: https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol
    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external
    {
        require(deadline >= block.timestamp, "EXPIRED");
        bytes32 digest = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline));
        digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                digest
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNATURE");
        _approve(owner, spender, value);
    }

    uint256[50] private __gap;
}