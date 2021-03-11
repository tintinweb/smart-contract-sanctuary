/**
 *Submitted for verification at Etherscan.io on 2021-03-09
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

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}


/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.0;

/** A heterogeneous, restricted, managed (heterogeneous) vault that targets ERC-1155 conforming contracts. */
contract Vault1155ERM is ERC20, IERC1155Receiver {
    /** @dev The address of the user that is currently depositing tokens. This will not be persisted, to reduce gas usage. */
    address private _depositor;

    /** @dev  The amount of mintable / burnable ERC-20 tokens for each action. */
    uint256 private _baseWrappedAmount;

    /** @dev The whitelist of contracts that can be vaulted. */
    address[] private _coreAddresses;
    /** @dev How many tokens are currently in the vault for a given contract. */
    uint256[] private _contractTokenCounts;
    /** @dev The index of a given contract, 1-based. We use 0 for the existance check. */
    mapping(address => uint256) private _coreAddressIndices;

    // The tokens stored in the vault and their contracts' address.
    address[] private _tokenContracts;
    uint256[] private _tokenIds;
    uint256[] private _tokenCounts;

    /**
     * @dev The mapping of token ids to their index, 1-based.
     * We merge together the index of the contract and the token id (`CONTRACT_INDEX_OFFSET`), which lets us support a larger vault.
     * Both the contract index the token index are 1-based, so that 0 can be used as an existance check.
     */
    mapping(uint256 => uint256) private _indices;
    uint256 private constant CONTRACT_INDEX_OFFSET = 200; // See `deposit()`. Supports 10^60 tokens for each of 10^16 contracts.

    // There are three role levels. We separate depositor and withdrawer as compared to "contributor" so we can whitelist other
    // vaults for parity swaps. Likewise, we also have global whitelists on depositor / withdrawer roles. We use a single mapping on
    // addresses along with bitmasks to reduce storage requirements. We also keep a count of the total number of admin addresses to
    // prevent the vault from being completely locked out.
    //
    //   Admin: Can add / remove any role for any address
    //   Depositor: Can deposit tokens
    //   Withdrawer: Can withdraw tokens
    //
    // The roles.
    uint256 private constant R_CAN_DEPOSIT     = 0x1; // 001
    uint256 private constant R_CAN_WITHDRAW    = 0x2; // 010
    uint256 private constant R_IS_ADMIN        = 0x4; // 100
    mapping(address => uint256) _addressRoles;

    // We can choose to restrict deposits / withdrawals to only those addresses with the appropriate role (`_addressRoles`). We pack
    // this into one value to save on storage manipulation costs.
    uint256 private constant WL_RESTRICT_NONE        = 0x0; // 00
    uint256 private constant WL_RESTRICT_DEPOSITS    = 0x1; // 01
    uint256 private constant WL_RESTRICT_WITHDRAWALS = 0x2; // 10
    uint256 private constant WL_RESTRICT_ALL         = 0x3; // 11
    uint256 _roleRestrictions;

    // We include this here instead of the `nonReentrant` modifier to reduce gas costs. See OpenZeppelin - ReentrancyGuard for more.
    uint256 private constant S_NOT_ENTERED = 1;
    uint256 private constant S_ENTERED = 2;
    uint256 private constant S_FROZEN = 2;
    uint256 private _status;

	constructor () ERC20("Test Vault 2", "TEST") public {
        address owner = 0x6FeDdd5a2952Eab0F4CbB4FD3C975F11bC7B323D;
        bool restrictDeposits = false;
        bool restrictWithdrawals = false;
        
        // Set the token ratio, defaulting to 10^18.
        _baseWrappedAmount = uint256(10) ** decimals();

        // Set up the caller with all permissions.
        _addressRoles[owner] = 0x7; // R_IS_ADMIN | R_CAN_WITHDRAW | R_CAN_DEPOSIT;

        // Set the global allows.
        if (restrictDeposits && restrictWithdrawals) {
            _roleRestrictions = WL_RESTRICT_ALL;
        } else if (restrictDeposits) {
            _roleRestrictions = WL_RESTRICT_DEPOSITS;
        } else if (restrictWithdrawals) {
            _roleRestrictions = WL_RESTRICT_WITHDRAWALS;
        } else {
            _roleRestrictions = WL_RESTRICT_NONE;
        }

        // Set us up for reentrancy guarding.
        _status = S_NOT_ENTERED;
    }

    /// Events ///

    /** Fired when token are deposited. */
    event TokensDeposited(address tokenContract, uint256 tokenId, uint256 tokenCount);

    /** Fired when token are withdrawn. */
    event TokensWithdrawn(address tokenContract, uint256 tokenId, uint256 tokenCount);

    /** Fired when a user's role has changed. */
    event RoleChanged(address user, uint256 newRole);

    /** Fired when a contract has been added. */
    event ContractAddressAdded(address contractAddress);

    /** Fired when a contract has been migrated. */
    event ContractAddressChanged(address oldAddress, address newAddress);

    /** Fired when a contract has been removed. */
    event ContractAddressRemoved(address contractAddress);

    /// Token Details ///

    /** Returns the details of a specific contract. */
    function contractAt(uint256 index) external view returns (uint256[3] memory) {
        address contractAddress = _coreAddresses[index];
        return [
            uint256(contractAddress),
            _contractTokenCounts[index],
            _coreAddressIndices[contractAddress]
        ];
    }

    /**
     * Returns the total number of whitelisted contracts and vaulted NFTs. There may be any number of removed contracts (set to the
     * zero address) at the end of the contract addresses array. Use `contractAt()` to verify the contract details.
     */
    function size() external view returns (uint256[2] memory) {
        return [
            _coreAddresses.length,
            _tokenIds.length
        ];
    }

    /** Returns the details of a specific token. */
    function tokenAt(uint256 index) external view returns (uint256[3] memory) {
        return [
            uint256(_tokenContracts[index]),
            _tokenIds[index],
            _tokenCounts[index]
        ];
    }

    /// Role Manipulation ///

    /** Change if we are restricting interaction according to the roles by type. */
    function changeRoleRestrictions(bool restrictDeposits, bool restrictWithdrawals) external {
        // Reentrancy guard.
        require(_status == S_NOT_ENTERED || _status == S_FROZEN, "Reentrancy: reentrant call");
        require(_addressRoles[msg.sender] & R_IS_ADMIN == R_IS_ADMIN, "Not admin");

        if (restrictDeposits && restrictWithdrawals) {
            _roleRestrictions = WL_RESTRICT_ALL;
        } else if (restrictDeposits) {
            _roleRestrictions = WL_RESTRICT_DEPOSITS;
        } else if (restrictWithdrawals) {
            _roleRestrictions = WL_RESTRICT_WITHDRAWALS;
        } else {
            _roleRestrictions = WL_RESTRICT_NONE;
        }
    }

    /**
     * Check if a token can be withdrawn by its id and its deposit counter. Use `getDepositCounter()` to see the maximum value for
     * `depositCounter`, if it is unknown. Use `getCurrentDepositCounts()` to see how many of the token are currently deposited.
     */
    function getTokenIndex(address tokenContract, uint256 tokenId) external view returns (uint256) {
        uint256 index = _indices[(_coreAddressIndices[tokenContract] << CONTRACT_INDEX_OFFSET) | tokenId];
        require(index > 0, "Token not in vault");

        return index - 1;
    }

    /** Returns the roles a given user has. */
    function getRoles(address user) external view returns (uint256) {
        return _addressRoles[user];
    }

    /** Returns the current role restrictions the vault has. */
    function getRoleRestrictions() external view returns (uint256) {
        return _roleRestrictions;
    }

    /**
     * Set the role flags for a given set of users. It's possible, but not recommended, to remove all admins. This will lock out all
     * future role and contract management. Depositor and withdrawal flags will have no affect unless the vault is using this
     * whitelist to restrict those actions (see: `changeRoleRestrictions()`). It's possible, but not recommended, to set strip admins
     * of deposit/withdrawal permissions.
     */
    function setRoles(address[] calldata users, bool enableRoles, bool adminFlag, bool depositorFlag, bool withdrawerFlag) external {
        // Reentrancy guard.
        require(_status == S_NOT_ENTERED || _status == S_FROZEN, "Reentrancy: reentrant call");
        require((_addressRoles[msg.sender] & R_IS_ADMIN) == R_IS_ADMIN, "Not admin");

        // Build up the roles flag assuming that we'll be setting the roles. We'll negate this if we're clearing it.
        uint256 rolesFlag;
        if (depositorFlag) {
            rolesFlag |= R_CAN_DEPOSIT;
        }
        if (withdrawerFlag) {
            rolesFlag |= R_CAN_WITHDRAW;
        }
        if (adminFlag) {
            rolesFlag |= R_IS_ADMIN;
        }

        address user;
        uint256 count = users.length;
        uint256 i;
        for (; i < count; i ++) {
            user = users[i];
            if (enableRoles) {
                _addressRoles[user] |= rolesFlag;
            } else {
                _addressRoles[user] &= ~rolesFlag;
            }

            // Hello world!
            emit RoleChanged(user, _addressRoles[user]);
        }
    }

    /// Management ///

    /** Track a new contract. */
    function addContractAddress(address contractAddress) external {
        // Reentrancy guard.
        require(_status == S_NOT_ENTERED || _status == S_FROZEN, "Reentrancy: reentrant call");
        require((_addressRoles[msg.sender] & R_IS_ADMIN) == R_IS_ADMIN, "Not admin");

        // Make sure the address is an external contract that is not being tracked. We don't do any validation on if the target
        // address is a contract, or even if it supports `IERC1155`, since it will be unusable if either of those are true.
        require(
               contractAddress != address(0)
            && contractAddress != address(this)
            && _coreAddressIndices[contractAddress] == 0,
        "Invalid address");

        // Add the contract.
        _coreAddresses.push(contractAddress);
        _contractTokenCounts.push(0);
        _coreAddressIndices[contractAddress] = _coreAddresses.length;

        // Hello world!
        emit ContractAddressAdded(contractAddress);
    }

    /** Change the currently tracked contract. */
    function changeContractAddress(address oldContract, address newContract) external {
        // Reentrancy guard.
        require(_status == S_NOT_ENTERED || _status == S_FROZEN, "Reentrancy: reentrant call");
        require((_addressRoles[msg.sender] & R_IS_ADMIN) == R_IS_ADMIN, "Not admin");

        // Make sure the address is an external contract that is currently being tracked. We don't do any validation on if the target
        // address is a contract, or even if it supports `IERC1155`, since it will be unusable if either of those are true.
        uint256 index = _coreAddressIndices[oldContract];
        require(
               newContract != address(0)
            && newContract != address(this)
            && index > 0
            && _contractTokenCounts[index - 1] == 0,
        "Invalid address");

        // Change the contract.
        _coreAddresses[index - 1] = newContract;
        _coreAddressIndices[oldContract] = 0;
        _coreAddressIndices[newContract] = index;

        // Hello world!
        emit ContractAddressChanged(oldContract, newContract);
    }

    /** Lock out all non-management aspects of the contract. Token transfers are still allowed. */
    function freeze() external {
        // Reentrancy guard.
        require(_status == S_NOT_ENTERED, "Reentrancy: reentrant call");
        require((_addressRoles[msg.sender] & R_IS_ADMIN) == R_IS_ADMIN, "Not admin");

        _status = S_FROZEN;
    }

    /** Remove a tracked contract from the vault. This will fail if there are any tokens vaulted for this contract. */
    function removeContractAddress(address contractAddress) external {
        // Reentrancy guard.
        require(_status == S_NOT_ENTERED || _status == S_FROZEN, "Reentrancy: reentrant call");
        require((_addressRoles[msg.sender] & R_IS_ADMIN) == R_IS_ADMIN, "Not admin");

        // Make sure the contract is tracked and has no stored tokens.
        uint256 contractIndex = _coreAddressIndices[contractAddress];
        require(
               contractIndex-- > 0
            && _contractTokenCounts[contractIndex] == 0
        , "Invalid address");

        // Remove the contract. We can't do a pop and swap, or otherwise shrink the contract arrays, since that would require
        // updating the keys for all tokens whose contract indices are greater than the index we are clearing.
        _coreAddresses[contractIndex] = address(0);
        _coreAddressIndices[contractAddress] = 0;

        // Hello world!
        emit ContractAddressRemoved(contractAddress);
    }

    /** Restore all non-management aspects of the contract. */
    function unfreeze() external {
        // Reentrancy guard.
        require(_status == S_FROZEN, "Reentrancy: reentrant call");
        require((_addressRoles[msg.sender] & R_IS_ADMIN) == R_IS_ADMIN, "Not admin");

        _status = S_NOT_ENTERED;
    }

    /// ERC-1155 ///

    /**
     * Called when an ERC-1155 compliant contract is targeting this contract as the receiver in a `safeTransferFrom()` call. This
     * checks to make sure we are expecting a token to be transferred. This should only be called as a result of `deposit()`.
     *
     * @param operator Who (from the perspective of the ERC-1155 contract) called `safeTransferFrom()`. This must always be this Vault.
     * @param from Who is the owner of the ERC-1155 token. This must always be `_depositor`.
     * @dev Unused parameter: id - The ID of the token being transferred.
     * @dev Unused parameter: value - The amount of tokens being transferred.
     * @dev Unused parameter: data - Optional data sent from the ERC-1155 contract.
     */
    function onERC1155Received(address operator, address from, uint256, uint256, bytes calldata) override external returns (bytes4) {
        // We must be in the middle of a deposit. If this function is called as a side-effect of a withdrawal / parity swap, this will
        // have a false-negative. However, that is only the case if the underlying contract is not valid / malicious.
        require(_status == S_ENTERED, "Reentrancy: non-reentrant call");

        require(operator == address(this),                "Cannot call directly");
        require(from == _depositor && from != address(0), "Depositor mismatch");
        require(_coreAddressIndices[msg.sender] > 0,      "Token not allowed in vault");

        // Accept this transfer.
        return 0xf23a6e61; // bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    }

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceID) override external view returns (bool) {
        return
            // ERC-165 support:
            //      bytes4(keccak256('supportsInterface(bytes4)'))
               interfaceID == 0x01ffc9a7

            // ERC-1155 `ERC1155TokenReceiver` support:
            //      bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
            //    ^ bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
            || interfaceID == 0x4e2312e0;      
    }

    /** @dev We can't do batch transfers since this is a Heterogenous vault. */
    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) override external returns (bytes4) {
        // Reject by reverting.
        revert("ERC1155 batch not supported");
    }

    /// Vault ///

    /**
     * Deposit any number of tokens into the vault, receiving ERC-20 wrapped tokens in response. Users can deposit tokens on behalf
     * of a third party (the one who would receive the parity tokens), so long as they are the owners of the token.
     *
     * @param depositor Who will be receiving the ERC-20 parity tokens.
     * @param tokenIds The ids of the tokens that will be deposited. All tokens must be approved for transfer first.
     */
    function deposit(address depositor, address[] calldata tokenContracts, uint256[] calldata tokenIds, uint256[] calldata tokenCounts) external {
        // Reentrancy guard.
        require(_status == S_NOT_ENTERED, "Reentrancy: reentrant call");
        _status = S_ENTERED;

        // Make sure the user is allowed to deposit. We use the sender instead of the provided depositor because this function could
        // be called via paritySwap (or some other contract). Plus `depositor` is just the user who receives the parity token. We
        // don't need to do any checking if the vault does not restrict depositing.
        require(
               ((_roleRestrictions & WL_RESTRICT_DEPOSITS)  != WL_RESTRICT_DEPOSITS)
            || ((_addressRoles[msg.sender] & R_CAN_DEPOSIT) == R_CAN_DEPOSIT)
        , "Not a depositor");

        // We need to know who will be receiving the parity tokens. The depositor can't be one of the tracked contracts.
        require(
               depositor != address(0)
            && depositor != address(this)
            && _coreAddressIndices[depositor] == 0,
        "Invalid address");

        // There are two additional guards that we are explicitly not doing. The first is ensuring that our arrays do not exceed their
        // theoretical bounds (e.g., overflow on `_tokenIds.length`). This is functionally impossible given the limitations of our
        // current technology, the design life of this vault, and the current ecosystem of smart contracts.
        //
        // The second check we are not doing is ensuring that the length of our three arrays are the same. The EVM will revert
        // ('invalid opcode'), so this is just unnecessary gas. It is self evident that the three arrays should be equal size.

        // Preserve the user so we know who to receive tokens from.
        _depositor = msg.sender;

        // We don't want to keep reading the length from storage.
        uint256 _length = _tokenIds.length;

        // Try and deposit everything.
        IERC1155 tokenContract;
        uint256 contractIndex;
        uint256 mintCount;
        uint256 count = tokenIds.length;
        uint256 i;

        for (; i < count; i ++) {
            // Make sure that the vault can accept this token's contract. We skip any contracts that aren't whitelisted within this
            // vault. In principle, the vault's contract whitelist should not change frequently, and removals should be especially
            // rare. So it's up to the user to be aware of what the vault will accept before initiating a deposit.
            tokenContract = IERC1155(tokenContracts[i]);
            contractIndex = _coreAddressIndices[address(tokenContract)];
            if (contractIndex == 0) {
                continue;
            }

            // Check to see if we've already stored this token. If we have, then we only need to increase the tracked count.
            uint256 tokenId = tokenIds[i];
            uint256 tokenCount = tokenCounts[i];
            uint256 currentIndex__currentBalance = _indices[(contractIndex << 200) | tokenId];
            _contractTokenCounts[contractIndex - 1] += tokenCount;
            if (currentIndex__currentBalance > 0) {
                _tokenCounts[currentIndex__currentBalance - 1] += tokenCount;
            } else {
                // Store it in the vault. We merge together the index of a token's contract with its token id to store in `_indices`,
                // left-shifting the index as much as we can. This works so long as an NFT id isn't >2^200. That is a reasonable
                // assumption, which is doubly assuming that all NFT ids start at 0 and the practical upper bound on NFT ids is
                // somewhere below 2^60 (10^18). If that doesn't hold true (probably because NFT ids are non-conforming), then we run
                // the risk of overwriting the lowest bits of the contract index with the highest bits of the NFT id. At worst, this
                // would prevent withdrawing an NFT with a specific id if it's collision has already been withdrawn. This puts the
                // hard limit of a vault at 70 quadrillion contracts with 1 novemdecillion NFTs per contract. Have fun!
                _tokenIds.push(tokenId);
                _tokenContracts.push(address(tokenContract));
                _tokenCounts.push(tokenCount);
                _indices[(contractIndex << 200) | tokenId] = ++_length;
            }

            // We need to know the prior balance in order to validate that the token contract did the full transfer. We will adjust
            // the intended token count value if they are trying to deposit more than they own. If they don't have any balance at all,
            // then we'll just move on to the next token.
            currentIndex__currentBalance = tokenContract.balanceOf(msg.sender, tokenId);
            uint256 currentVaultBalance = tokenContract.balanceOf(address(this), tokenId);
            if (currentIndex__currentBalance == 0) {
                continue;
            }
            if (tokenCount > currentIndex__currentBalance) {
                tokenCount = currentIndex__currentBalance;
            }

            // Track the true number to be minted.
            mintCount += tokenCount;

            // Attempt to transfer the token. If the sender hasn't approved this contract for this specific token then it will fail.
            tokenContract.safeTransferFrom(msg.sender, address(this), tokenId, tokenCount, bytes(""));

            // Validate the transfer balances.
            require(
                   tokenContract.balanceOf(msg.sender, tokenId)    == (currentIndex__currentBalance - tokenCount)
                && tokenContract.balanceOf(address(this), tokenId) == (currentVaultBalance + tokenCount)
            , "Transfer failed");

            // Hello world!
            emit TokensDeposited(address(tokenContract), tokenId, tokenCount);
        }

        // Give them the wrapped ERC-20 token.
        if (mintCount > 0) {
            _mint(depositor, mintCount * _baseWrappedAmount);
        }

        // By storing the original value once again, a refund is triggered (see https://eips.ethereum.org/EIPS/eip-2200).
        _depositor = address(0);
        _status = S_NOT_ENTERED;
    }

    /** Withdraw a token by its index within the vault. This is a failsafe if there is a collision on the contract index. */
    function withdrawTokenAtIndex(address destination, uint256 index, uint256 count) external {
        // Reentrancy guard.
        require(_status == S_NOT_ENTERED, "Reentrancy: reentrant call");
        _status = S_ENTERED;

        // Make sure the user is allowed to withdraw. We don't need to do any checking if the vault does not restrict withdrawing.
        require(
               ((_roleRestrictions & WL_RESTRICT_WITHDRAWALS) != WL_RESTRICT_WITHDRAWALS)
            || ((_addressRoles[msg.sender] & R_CAN_WITHDRAW)  == R_CAN_WITHDRAW)
        , "Not a withdrawer");

        // We need to know who will be receiving the tokens. The destination can't be one of the tracked contracts.
        require(
               destination != address(0)
            && destination != address(this)
            && _coreAddressIndices[destination] == 0,
        "Invalid address");

        // Make sure we have at least some tokens vaulted. We don't need to validate that the index is valid since the EVM will just
        // revert ('invalid opcode'), so this is just unnecessary gas.
        require( _tokenIds.length > 0, "No tokens to withdraw");

        // Attempt the withdrawal
        uint256 burnCount = _withdrawTokens(destination, index, count);

        // Take the wrapped ERC-20 tokens.
        if (burnCount > 0) {
            _burn(msg.sender, burnCount * _baseWrappedAmount);
        }

        // By storing the original value once again, a refund is triggered (see https://eips.ethereum.org/EIPS/eip-2200).
        _status = S_NOT_ENTERED;
    }

    /**
     * Attempts to withdraw the tokens with the specified ids. Only the stored tokens will be withdrawn.
     *
     * @param destination Who will receive the ERC-1155 tokens.
     * @param tokenContracts The contracts of the tokens that will be withdrawn.
     * @param tokenIds The ids of the tokens that will be withdrawn.
     * @param tokenCounts The maximum number of tokens that will be withdrawn.
     */
    function withdrawTokens(address destination, address[] calldata tokenContracts, uint256[] calldata tokenIds, uint256[] calldata tokenCounts) external {
        // Reentrancy guard.
        require(_status == S_NOT_ENTERED, "Reentrancy: reentrant call");
        _status = S_ENTERED;

        // Make sure the user is allowed to withdraw. We don't need to do any checking if the vault does not restrict withdrawing.
        require(
               ((_roleRestrictions & WL_RESTRICT_WITHDRAWALS) != WL_RESTRICT_WITHDRAWALS)
            || ((_addressRoles[msg.sender] & R_CAN_WITHDRAW)  == R_CAN_WITHDRAW)
        , "Not a withdrawer");

        // We need to know who will be receiving the tokens. The destination can't be one of the tracked contracts.
        require(
               destination != address(0)
            && destination != address(this)
            && _coreAddressIndices[destination] == 0,
        "Invalid address");

        // Make sure we have at least some tokens vaulted.
        require(_tokenIds.length > 0, "No tokens to withdraw");
        
        // We don't need to ensure that the length of our three arrays are the same. The EVM will revert ('invalid opcode'), so this
        // is just unnecessary gas. It is self evident that the three arrays should be equal size.

        // We don't want to revert if this vault doesn't contain some of the tokens, so we are checking for existence and only
        // transferring those that this vault owns. Because of this, we can't burn the parity token up front since there's no way to
        // know how many will actually be transferred.
        uint256 burnCount;
        uint256 count = tokenIds.length;
        for (uint256 i; i < count; i ++) {
            // If we can't find it, we'll skip it. Index is off by 1 so that 0 = nonexistent. We also need to check to make sure the
            // token stored at that index matches what we want to withdraw (contract and id) since the mapping could have a collision.
            address tokenContract = tokenContracts[i];
            uint256 tokenId = tokenIds[i];
            uint256 contractIndex = _coreAddressIndices[tokenContract];
            uint256 tokenIndex = _indices[(contractIndex << CONTRACT_INDEX_OFFSET) | tokenId];
            if (
                   contractIndex == 0 // Contract is not allowed in this vault.
                || tokenIndex == 0 // Token is not in this vault.
                || _tokenContracts[--tokenIndex] != tokenContract // Contract for token at that index does not match expected.
                || _tokenIds[tokenIndex] != tokenIds[i] // Token at that index does not match expected.
            ) {
                continue;
            }
            burnCount += _withdrawTokens(destination, tokenIndex, tokenCounts[i]);
        }

        // Take the wrapped ERC-20 tokens.
        if (burnCount > 0) {
            _burn(msg.sender, burnCount * _baseWrappedAmount);
        }

        // By storing the original value once again, a refund is triggered (see https://eips.ethereum.org/EIPS/eip-2200).
        _status = S_NOT_ENTERED;
    }

    /**
     * Executes a withdrawal.
     *
     * @param destination Who will be receiving the NFT.
     * @param index The index within the vault that will be withdrawn.
     * @param tokenCount How many of the token should be withdrawn. It will only withdraw as many as are vaulted.
     *
     * @return The number of withdrawn tokens.
     */
    function _withdrawTokens(address destination, uint256 index, uint256 tokenCount) internal returns (uint256) {
        IERC1155 tokenContract = IERC1155(_tokenContracts[index]);
        uint256 tokenId = _tokenIds[index];
        uint256 contractIndex = _coreAddressIndices[address(tokenContract)];

        // We can only withdraw as many as we have vaulted.
        if (_tokenCounts[index] <= tokenCount) {
            tokenCount = _tokenCounts[index];
            
            // Swap and pop the ids and counts.
            uint256 lastIndex = _tokenIds.length - 1;
            uint256 tailTokenId = _tokenIds[lastIndex];
            _tokenIds[index] = tailTokenId;
            _tokenIds.pop();
            _tokenCounts[index] = _tokenCounts[lastIndex];
            _tokenCounts.pop();

            // Swap and pop the contract.
            address tailTokenContract = _tokenContracts[lastIndex];
            _tokenContracts[index] = tailTokenContract;
            _tokenContracts.pop();

            // Update the index mapping.
            lastIndex = _coreAddressIndices[tailTokenContract]; // Reuse to reduce local stack size.
            _indices[(lastIndex << CONTRACT_INDEX_OFFSET) | tailTokenId] = index + 1;
            _indices[(contractIndex << CONTRACT_INDEX_OFFSET) | tokenId] = 0;
            
        } else {
            _tokenCounts[index] -= tokenCount;
        }

        // Update the count.
        _contractTokenCounts[contractIndex - 1] -= tokenCount;

        // Get the state prior to the transfer so we can do validation.
        uint256 currentDestinationBalance = tokenContract.balanceOf(destination,   tokenId);
        uint256 currentVaultBalance       = tokenContract.balanceOf(address(this), tokenId);

        // Attempt to transfer the tokens.
        tokenContract.safeTransferFrom(address(this), destination, tokenId, tokenCount, bytes(""));

        // Validate the transfer balances.
        require(
               tokenContract.balanceOf(destination, tokenId)   == (currentDestinationBalance + tokenCount)
            && tokenContract.balanceOf(address(this), tokenId) == (currentVaultBalance - tokenCount)
        , "Transfer failed");

        // Hello world!
        emit TokensWithdrawn(address(tokenContract), tokenId, tokenCount);

        return tokenCount;
    }
}