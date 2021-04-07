/**
 *Submitted for verification at Etherscan.io on 2021-04-06
*/

// SPDX-License-Identifier: MIT

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Migrations {
    address public owner;
    uint public lastCompletedMigration;

    constructor() {
        owner = msg.sender;
    }

    modifier restricted() {
        if (msg.sender == owner) _;
    }

    function setCompleted(uint completed) public restricted {
        lastCompletedMigration = completed;
    }

    function upgrade(address newAddress) public restricted {
        Migrations upgraded = Migrations(newAddress);
        upgraded.setCompleted(lastCompletedMigration);
    }
}

contract Ownable {
    /**
     * @dev map for list of owners
     */
    address creator;
    mapping(address => uint256) public owner;
    uint256 index = 0;

    /**
     * @dev constructor, where first user is an administrator
     */
    constructor() {
        owner[msg.sender] = ++index;
        creator = msg.sender;
    }

    /**
     * @dev modifier which check the status of user and continue only if msg.sender is administrator
     */
    modifier onlyOwner() {
        require(owner[msg.sender] > 0, "onlyOwner exception");
        _;
    }

    /**
     * @dev adding new owner to list of owners
     * @param newOwner address of new administrator
     * @return true when operation is successful
     */
    function addNewOwner(address newOwner) public onlyOwner returns(bool) {
        owner[newOwner] = ++index;
        return true;
    }

    /**
     * @dev remove owner from list of owners
     * @param removedOwner address of removed administrator
     * @return true when operation is successful
     */
    function removeOwner(address removedOwner) public onlyOwner returns(bool) {
        require(msg.sender != removedOwner, "Denied deleting of yourself");
        owner[removedOwner] = 0;
        return true;
    }
}


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


library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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


contract ERC20 is Context, IERC20, IERC20Metadata {
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
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
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
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

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
}


library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}


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


abstract contract ERC165 is IERC165 {
/**
 * @dev See {IERC165-supportsInterface}.
 */
function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
return interfaceId == type(IERC165).interfaceId;
}
}


interface IERC721 is IERC165 {
/**
 * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
 */
event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

/**
 * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
 */
event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

/**
 * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
 */
event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

/**
 * @dev Returns the number of tokens in ``owner``'s account.
 */
function balanceOf(address owner) external view returns (uint256 balance);

/**
 * @dev Returns the owner of the `tokenId` token.
 *
 * Requirements:
 *
 * - `tokenId` must exist.
 */
function ownerOf(uint256 tokenId) external view returns (address owner);

/**
 * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
 * are aware of the ERC721 protocol to prevent tokens from being forever locked.
 *
 * Requirements:
 *
 * - `from` cannot be the zero address.
 * - `to` cannot be the zero address.
 * - `tokenId` token must exist and be owned by `from`.
 * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
 * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
 *
 * Emits a {Transfer} event.
 */
function safeTransferFrom(address from, address to, uint256 tokenId) external;

/**
 * @dev Transfers `tokenId` token from `from` to `to`.
 *
 * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
 *
 * Requirements:
 *
 * - `from` cannot be the zero address.
 * - `to` cannot be the zero address.
 * - `tokenId` token must be owned by `from`.
 * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
 *
 * Emits a {Transfer} event.
 */
function transferFrom(address from, address to, uint256 tokenId) external;

/**
 * @dev Gives permission to `to` to transfer `tokenId` token to another account.
 * The approval is cleared when the token is transferred.
 *
 * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
 *
 * Requirements:
 *
 * - The caller must own the token or be an approved operator.
 * - `tokenId` must exist.
 *
 * Emits an {Approval} event.
 */
function approve(address to, uint256 tokenId) external;

/**
 * @dev Returns the account approved for `tokenId` token.
 *
 * Requirements:
 *
 * - `tokenId` must exist.
 */
function getApproved(uint256 tokenId) external view returns (address operator);

/**
 * @dev Approve or remove `operator` as an operator for the caller.
 * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
 *
 * Requirements:
 *
 * - The `operator` cannot be the caller.
 *
 * Emits an {ApprovalForAll} event.
 */
function setApprovalForAll(address operator, bool _approved) external;

/**
 * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
 *
 * See {setApprovalForAll}
 */
function isApprovedForAll(address owner, address operator) external view returns (bool);

/**
  * @dev Safely transfers `tokenId` token from `from` to `to`.
  *
  * Requirements:
  *
  * - `from` cannot be the zero address.
  * - `to` cannot be the zero address.
  * - `tokenId` token must exist and be owned by `from`.
  * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
  * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
  *
  * Emits a {Transfer} event.
  */
function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}


interface IERC721Metadata is IERC721 {

/**
 * @dev Returns the token collection name.
 */
function name() external view returns (string memory);

/**
 * @dev Returns the token collection symbol.
 */
function symbol() external view returns (string memory);

/**
 * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
 */
function tokenURI(uint256 tokenId) external view returns (string memory);
}


interface IERC721Receiver {
/**
 * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
 * by `operator` from `from`, this function is called.
 *
 * It must return its Solidity selector to confirm the token transfer.
 * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
 *
 * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
 */
function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}


contract ETHSteps is ERC20, Ownable {
address public stepMarket;

constructor() ERC20("CoinClash", "CoC") {}

function init(address _stepMarket) public onlyOwner {
stepMarket = _stepMarket;
}

/**
 * mint tokens to user
 * @param  _to address token receiver
 * @param _value uint256 amount of tokens for mint
 */
function mint(address _to, uint256 _value) public {
require(msg.sender == stepMarket, "address not stepmarket");
_mint(_to, _value);
}

/**
 * burn tokens from user
 * @param _from address address of user for burning
 * @param _value uint256 amount of tokens for burn
 */
function burnFrom(address _from, uint256 _value) public {
require(msg.sender == stepMarket, "address not stepmarket");
_burn(_from, _value);
}

function getOwner() external view returns (address) {
return creator;
}
}


contract NFTToken is Context, ERC165, IERC721, IERC721Metadata, Ownable {
using Address for address;
using Strings for uint256;
using Counters for Counters.Counter;

// Token name
string private _name;

// Token symbol
string private _symbol;

// Mapping from token ID to meta hash
mapping (uint256 => bytes) public metaHash;

// Mapping from token ID to owner address
mapping (uint256 => address) private _owners;

// Mapping owner address to token count
mapping (address => uint256) private _balances;

// Mapping from token ID to approved address
mapping (uint256 => address) private _tokenApprovals;

// Mapping from owner to operator approvals
mapping (address => mapping (address => bool)) private _operatorApprovals;

event MintRequest(
address from,
uint256 tokenId
);

/**
 * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
 */
constructor (string memory name_, string memory symbol_) {
_name = name_;
_symbol = symbol_;
}

/**
 * @dev See {IERC165-supportsInterface}.
 */
function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
return interfaceId == type(IERC721).interfaceId
|| interfaceId == type(IERC721Metadata).interfaceId
|| super.supportsInterface(interfaceId);
}

/**
 * @dev See {IERC721-balanceOf}.
 */
function balanceOf(address owner) public view virtual override returns (uint256) {
require(owner != address(0), "ERC721: balance query for the zero address");
return _balances[owner];
}

/**
 * @dev See {IERC721-ownerOf}.
 */
function ownerOf(uint256 tokenId) public view virtual override returns (address) {
address owner = _owners[tokenId];
require(owner != address(0), "ERC721: owner query for nonexistent token");
return owner;
}

/**
 * @dev See {IERC721Metadata-name}.
 */
function name() public view virtual override returns (string memory) {
return _name;
}

/**
 * @dev See {IERC721Metadata-symbol}.
 */
function symbol() public view virtual override returns (string memory) {
return _symbol;
}

/**
 * @dev See {IERC721Metadata-tokenURI}.
 */
function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

string memory baseURI = _baseURI();
return bytes(baseURI).length > 0
? string(abi.encodePacked(baseURI, tokenId.toString()))
: '';
}

/**
 * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
 * in child contracts.
 */
function _baseURI() internal view virtual returns (string memory) {
return "";
}

/**
 * @dev See {IERC721-approve}.
 */
function approve(address to, uint256 tokenId) public virtual override {
address owner = NFTToken.ownerOf(tokenId);
require(to != owner, "ERC721: approval to current owner");

require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
"ERC721: approve caller is not owner nor approved for all"
);

_approve(to, tokenId);
}

/**
 * @dev See {IERC721-getApproved}.
 */
function getApproved(uint256 tokenId) public view virtual override returns (address) {
require(_exists(tokenId), "ERC721: approved query for nonexistent token");

return _tokenApprovals[tokenId];
}

/**
 * @dev See {IERC721-setApprovalForAll}.
 */
function setApprovalForAll(address operator, bool approved) public virtual override {
require(operator != _msgSender(), "ERC721: approve to caller");

_operatorApprovals[_msgSender()][operator] = approved;
emit ApprovalForAll(_msgSender(), operator, approved);
}

/**
 * @dev See {IERC721-isApprovedForAll}.
 */
function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
return _operatorApprovals[owner][operator];
}

/**
 * @dev See {IERC721-transferFrom}.
 */
function transferFrom(address from, address to, uint256 tokenId) public virtual override {
//solhint-disable-next-line max-line-length
require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

_transfer(from, to, tokenId);
}

/**
 * @dev See {IERC721-safeTransferFrom}.
 */
function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
safeTransferFrom(from, to, tokenId, "");
}

/**
 * @dev See {IERC721-safeTransferFrom}.
 */
function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
_safeTransfer(from, to, tokenId, _data);
}

/**
 * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
 * are aware of the ERC721 protocol to prevent tokens from being forever locked.
 *
 * `_data` is additional data, it has no specified format and it is sent in call to `to`.
 *
 * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
 * implement alternative mechanisms to perform token transfer, such as signature-based.
 *
 * Requirements:
 *
 * - `from` cannot be the zero address.
 * - `to` cannot be the zero address.
 * - `tokenId` token must exist and be owned by `from`.
 * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
 *
 * Emits a {Transfer} event.
 */
function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
_transfer(from, to, tokenId);
require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
}

/**
 * @dev Returns whether `tokenId` exists.
 *
 * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
 *
 * Tokens start existing when they are minted (`_mint`),
 * and stop existing when they are burned (`_burn`).
 */
function _exists(uint256 tokenId) internal view virtual returns (bool) {
return _owners[tokenId] != address(0);
}

/**
 * @dev Returns whether `spender` is allowed to manage `tokenId`.
 *
 * Requirements:
 *
 * - `tokenId` must exist.
 */
function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
require(_exists(tokenId), "ERC721: operator query for nonexistent token");
address owner = NFTToken.ownerOf(tokenId);
return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
}

/**
 * @dev Safely mints `tokenId` and transfers it to `to`.
 *
 * Requirements:
 *
 * - `tokenId` must not exist.
 * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
 *
 * Emits a {Transfer} event.
 */
function _safeMint(address to, uint256 tokenId) internal virtual {
_safeMint(to, tokenId, "");
}

/**
 * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
 * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
 */
function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
_mint(to, tokenId);
require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
}

/**
 * @dev Mints `tokenId` and transfers it to `to`.
 *
 * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
 *
 * Requirements:
 *
 * - `tokenId` must not exist.
 * - `to` cannot be the zero address.
 *
 * Emits a {Transfer} event.
 */
function _mint(address to, uint256 tokenId) internal virtual {
require(to != address(0), "ERC721: mint to the zero address");
require(!_exists(tokenId), "ERC721: token already minted");

_beforeTokenTransfer(address(0), to, tokenId);

_balances[to] += 1;
_owners[tokenId] = to;

emit Transfer(address(0), to, tokenId);
}

/**
 * @dev Destroys `tokenId`.
 * The approval is cleared when the token is burned.
 *
 * Requirements:
 *
 * - `tokenId` must exist.
 *
 * Emits a {Transfer} event.
 */
function _burn(uint256 tokenId) internal virtual {
address owner = NFTToken.ownerOf(tokenId);

_beforeTokenTransfer(owner, address(0), tokenId);

// Clear approvals
_approve(address(0), tokenId);

_balances[owner] -= 1;
delete _owners[tokenId];

emit Transfer(owner, address(0), tokenId);
}

/**
 * @dev Transfers `tokenId` from `from` to `to`.
 *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
 *
 * Requirements:
 *
 * - `to` cannot be the zero address.
 * - `tokenId` token must be owned by `from`.
 *
 * Emits a {Transfer} event.
 */
function _transfer(address from, address to, uint256 tokenId) internal virtual {
require(NFTToken.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
require(to != address(0), "ERC721: transfer to the zero address");

_beforeTokenTransfer(from, to, tokenId);

// Clear approvals from the previous owner
_approve(address(0), tokenId);

_balances[from] -= 1;
_balances[to] += 1;
_owners[tokenId] = to;

emit Transfer(from, to, tokenId);
}

/**
 * @dev Approve `to` to operate on `tokenId`
 *
 * Emits a {Approval} event.
 */
function _approve(address to, uint256 tokenId) internal virtual {
_tokenApprovals[tokenId] = to;
emit Approval(NFTToken.ownerOf(tokenId), to, tokenId);
}

/**
 * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
 * The call is not executed if the target address is not a contract.
 *
 * @param from address representing the previous owner of the given token ID
 * @param to target address that will receive the tokens
 * @param tokenId uint256 ID of the token to be transferred
 * @param _data bytes optional data to send along with the call
 * @return bool whether the call correctly returned the expected magic value
 */
function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
private returns (bool)
{
if (to.isContract()) {
try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
return retval == IERC721Receiver(to).onERC721Received.selector;
} catch (bytes memory reason) {
if (reason.length == 0) {
revert("ERC721: transfer to non ERC721Receiver implementer");
} else {
// solhint-disable-next-line no-inline-assembly
assembly {
revert(add(32, reason), mload(reason))
}
}
}
} else {
return true;
}
}

/**
 * @dev Hook that is called before any token transfer. This includes minting
 * and burning.
 *
 * Calling conditions:
 *
 * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
 * transferred to `to`.
 * - When `from` is zero, `tokenId` will be minted for `to`.
 * - When `to` is zero, ``from``'s `tokenId` will be burned.
 * - `from` cannot be the zero address.
 * - `to` cannot be the zero address.
 *
 * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
 */
function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

contract ETHStepMarket is Ownable {
using SafeMath for uint256;

mapping(address => uint256) public percentages;
address[] public admins;
ETHSteps public stepAddress;
uint256 public adminPart;
uint256 public treasurePart;
uint256 public commissionPart;
uint256 public treasurePercentage = 90;
uint256 public adminPercentage = 10;

/**
 * event of success airdrop of coc tokens
 */
event WithdrawAdminProcessed(
address caller,
uint256 amount,
uint256 timestamp
);
event AdminAddressAdded(
address newAddress,
uint256 percentage
);
event AdminAddressRemoved(
address oldAddress
);
event AdminPercentageChanged(
address admin,
uint256 newPercentage
);
event StepsAirdropped(
address indexed user,
uint256 amount
);
event AirdropDeposited(
address indexed user,
uint256 amount
);
event StepsBoughtViaEth(
address indexed user,
uint256 ethAmount
);
event TreasurePercentagesChanged(
uint256 treasurePercentage,
uint256 adminPercentage
);
event TreasureAdded(uint256 amount);
event WithdrawEmitted(address indexed user);
event EmitInternalDrop(address indexed user);
event TreasureSwapped(
address indexed receiver,
uint256 ethAmount
);

function init(address _stepAddress) public onlyOwner {
stepAddress = ETHSteps(_stepAddress);
}

/**
 * send free steps to many users as airdrop
 * @param _user address[] receivers address list
 * @param _amount uint256[] amount of tokens for sending
 */
function airdropToMany(
address[] memory _user,
uint256[] memory _amount
) public onlyOwner {
require(_user.length == _amount.length, "Length must be equal");

for (uint256 i = 0; i < _user.length; i++) {
stepAddress.mint(_user[i], _amount[i].mul(1 ether));

emit StepsAirdropped(_user[i], _amount[i].mul(1 ether));
}
}

function sendRewardToMany(
address[] memory _user,
uint256[] memory _amount,
uint256 totaRewardSent
) public onlyOwner {
require(_user.length == _amount.length, "Length must be equal");
require(treasurePart >= totaRewardSent);

treasurePart = treasurePart.sub(totaRewardSent);

for (uint256 i = 0; i < _user.length; i++) {
payable(_user[i]).transfer(_amount[i]);
}
}

function receiveCommission() public onlyOwner {
require(commissionPart > 0, "There are no commission");

uint256 value = commissionPart;
commissionPart = 0;

payable(msg.sender).transfer(value);
}

function getInternalAirdrop() public {
stepAddress.mint(msg.sender, 1 ether);
stepAddress.burnFrom(msg.sender, 1 ether);

emit EmitInternalDrop(msg.sender);
}

function buySteps() public payable {
require(msg.value != 0, "value can't be 0");

stepAddress.mint(msg.sender, msg.value);
stepAddress.burnFrom(msg.sender, msg.value);

adminPart = adminPart.add(msg.value.mul(adminPercentage).div(100));
treasurePart = treasurePart.add(msg.value.mul(treasurePercentage).div(100));

emit StepsBoughtViaEth(
msg.sender,
msg.value
);
}

function depositToGame() public {
require(stepAddress.balanceOf(msg.sender) != 0, "No tokens for deposit");

emit AirdropDeposited(
msg.sender,
stepAddress.balanceOf(msg.sender)
);

stepAddress.burnFrom(msg.sender, stepAddress.balanceOf(msg.sender));
}

function changeTreasurePercentage(
uint256 _treasurePercentage,
uint256 _adminPercentage
) public onlyOwner {
require(_treasurePercentage + _adminPercentage == 100, "Total percentage not 100");
treasurePercentage = _treasurePercentage;
adminPercentage = _adminPercentage;

emit TreasurePercentagesChanged(
treasurePercentage,
adminPercentage
);
}

function addAdmin(address _admin, uint256 _percentage) public onlyOwner {
require(percentages[_admin] == 0, "Admin exists");

admins.push(_admin);
percentages[_admin] = _percentage;

emit AdminAddressAdded(
_admin,
_percentage
);
}

function addToTreasure() public payable {
treasurePart = treasurePart.add(msg.value);

emit TreasureAdded(
msg.value
);
}

function emitWithdrawal() public payable {
require(msg.value >= 4000000000000000 wei, "value can't be less then 4 finney");

commissionPart = commissionPart.add(msg.value);

emit WithdrawEmitted(
msg.sender
);
}

function changePercentage(
address _admin,
uint256 _percentage
) public onlyOwner {
percentages[_admin] = _percentage;

emit AdminPercentageChanged(
_admin,
_percentage
);
}

function deleteAdmin(address _removedAdmin) public onlyOwner {
uint256 found = 0;
for (uint256 i = 0; i < admins.length; i++) {
if (admins[i] == _removedAdmin) {
found = i;
}
}

for (uint256 i = found; i < admins.length - 1; i++) {
admins[i] = admins[i + 1];
}

admins.pop();

percentages[_removedAdmin] = 0;

emit AdminAddressRemoved(_removedAdmin);
}

function withdrawAdmins() public payable {
uint256 percent = 0;

uint256 value = adminPart;
adminPart = 0;

for (uint256 i = 0; i < admins.length; i++) {
percent = percent.add(percentages[admins[i]]);
}

require(percent == 10000, "Total admin percent must be 10000 or 100,00%");

for (uint256 i = 0; i < admins.length; i++) {
uint256 amount = value.mul(percentages[admins[i]]).div(10000);
payable(admins[i]).transfer(amount);
}

emit WithdrawAdminProcessed(
msg.sender,
adminPart,
block.timestamp
);
}
}


contract CoCNFT is NFTToken {
uint256 commissions = 0;

constructor() NFTToken("CoinClash", "CoC"){
}

function receiveCommission() public onlyOwner {
require(commissions > 0, "There are no commission");

uint256 value = commissions;
commissions = 0;

payable(msg.sender).transfer(value);
}

/**
 * @dev See {IERC721-safeMint}.
 */
function mintRequest(uint256 tokenId) public payable {
require(metaHash[tokenId].length == 0, "Token already exists");
require(msg.value >= 5000000000000000 wei, "value can't be less then 5 finney");

commissions += msg.value;

emit MintRequest(msg.sender, tokenId);
}

/**
 * @dev See {IERC721-safeMint}.
 */
function safeMint(address to, bytes memory hash, uint256 tokenId) public onlyOwner {
require(metaHash[tokenId].length == 0, "Token already exists");

metaHash[tokenId] = hash;
_mint(to, tokenId);
}

/**
 * @dev See {IERC721-safeMint}.
 */
function safeBurn(uint256 tokenId) public {
address owner = NFTToken.ownerOf(tokenId);

require(msg.sender == owner, "Only owner can burn");

delete metaHash[tokenId];
_burn(tokenId);
}
}