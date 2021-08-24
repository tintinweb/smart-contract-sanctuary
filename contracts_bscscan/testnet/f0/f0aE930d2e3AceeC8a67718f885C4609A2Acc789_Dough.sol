/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;


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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/// @title Dividend-Paying Token Optional Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev OPTIONAL functions for a dividend-paying token contract.
interface DividendPayingTokenOptionalInterface {
    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function withdrawableDividendOf(address _owner)
        external
        view
        returns (uint256);

    /// @notice View the amount of dividend in wei that an address has withdrawn.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has withdrawn.
    function withdrawnDividendOf(address _owner)
        external
        view
        returns (uint256);

    /// @notice View the amount of dividend in wei that an address has earned in total.
    /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has earned in total.
    function accumulativeDividendOf(address _owner)
        external
        view
        returns (uint256);
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

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) internal view returns (uint256) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key)
        internal
        view
        returns (int256)
    {
        if (!map.inserted[key]) {
            return -1;
        }
        return int256(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint256 index)
        internal
        view
        returns (address)
    {
        return map.keys[index];
    }

    function size(Map storage map) internal view returns (uint256) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        address key,
        uint256 val
    ) internal {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) internal {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

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
    function balanceOf (address account) public view virtual override returns (uint256) {
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
    function transfer (address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer (_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance (address owner, address spender) public view virtual override returns (uint256) {
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
        _approve (_msgSender(), spender, amount);
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
    function transferFrom (address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer (sender, recipient, amount);
        _approve (sender, _msgSender(), _allowances[sender][_msgSender()]- amount);
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
    function increaseAllowance (address spender, uint256 addedValue) public virtual returns (bool) {
        _approve (_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
    function decreaseAllowance (address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve (_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
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
    function _transfer (address sender, address recipient, uint256 amount) internal virtual {
        require (sender != address(0), "ERC20: transfer from the zero address");
        require (recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] -= amount;
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
     * - `account` cannot be the zero address.
     */
    function _mint (address account, uint256 amount) internal virtual {
        require (account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer (address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer (address(0), account, amount);
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
    function _burn (address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer (account, address(0), amount);

        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Transfer (account, address(0), amount);
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
    function _approve (address owner, address spender, uint256 amount) internal virtual {
        require (owner != address(0), "ERC20: approve from the zero address");
        require (spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval (owner, spender, amount);
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
    function _beforeTokenTransfer (address from, address to, uint256 amount) internal virtual {}
}

/*
MIT License

Copyright (c) 2018 requestnetwork
Copyright (c) 2018 Fragments, Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety checks.
 */
library SafeMathConversion {
    function toUint256Safe (int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
    
    function toInt256Safe (uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}

/// @title Dividend-Paying Token Interface
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev An interface for a dividend-paying token contract.
interface DividendPayingTokenInterface {
    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function dividendOf (address _owner) external view returns (uint256);

    /// @notice Withdraws the reward distributed to the sender.
    /// @dev SHOULD transfer `dividendOf(msg.sender)` wei to `msg.sender`, and `dividendOf(msg.sender)` SHOULD be 0 after the transfer.
    ///  MUST emit a `DividendWithdrawn` event if the amount of reward transferred is greater than 0.
    function withdrawDividend() external;

    /// @dev This event MUST emit when reward is distributed to token holders.
    /// @param from The address which sends reward to this contract.
    /// @param weiAmount The amount of distributed reward in wei.
    event DividendsDistributed (address indexed from, uint256 weiAmount);

    /// @dev This event MUST emit when an address withdraws their dividend.
    /// @param to The address which withdraws reward from this contract.
    /// @param weiAmount The amount of withdrawn reward in wei.
    event DividendWithdrawn (address indexed to, uint256 weiAmount);
}

contract SharedConstants {
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    address public constant CAKE = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7; // Mainnet Cake address - 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82 - CHANGEME
    uint8 public constant BUY = 0;
    uint8 public constant SELL = 1;
    // 0x07865c6E87B9F70255377e024ace6630C1Eaa37F - Ropsten USDC
    // 0xaD6D458402F60fD3Bd25163575031ACDce07538D - Ropsten DAI
    // 0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684 - BSC Testnet USDT
    // 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd - BSC Testnet WBNB
    // 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7 - Kiemtiem BUSD
    // 0x01BE23585060835E02B77ef475b0Cc51aA1e0709 - Rinkeby LINK
    // 0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa - Rinkeby DAI
    /*event Debug (string debugText, uint256 debugNumber);
    
    bool[8] public test;
    
    function setTests (bool[] memory _test) external {
        for (uint i = 0; i < _test.length; i++)
            test[i] = _test[i];
    }*/
}


/// @title Dividend-Paying Token
/// @author Roger Wu (https://github.com/roger-wu)
/// @dev A mintable ERC20 token that allows anyone to pay and distribute rewards
///  to token holders as dividends and allows token holders to withdraw their dividends.
///  Reference: the source code of PoWH3D: https://etherscan.io/address/0xB3775fB83F7D12A36E0475aBdD1FCA35c091efBe#code
contract DividendPayingToken is
    ERC20,
    Ownable,
    DividendPayingTokenInterface,
    DividendPayingTokenOptionalInterface,
    SharedConstants
{
    using SafeMathConversion for uint256;
    using SafeMathConversion for int256;
    using SafeERC20 for IERC20;

    // With `MAGNITUDE`, we can properly distribute dividends even if the amount of received reward is small.
    // For more discussion about choosing the value of `MAGNITUDE`,
    //  see https://github.com/ethereum/EIPs/issues/1726#issuecomment-472352728
    uint256 internal constant MAGNITUDE = 2**128;

    uint256 internal magnifiedDividendPerShare;
    
    address internal rewardToken;

    // About dividendCorrection:
    // If the token balance of a `_user` is never changed, the dividend of `_user` can be computed with:
    //   `dividendOf(_user) = dividendPerShare * balanceOf(_user)`.
    // When `balanceOf(_user)` is changed (via minting/burning/transferring tokens),
    //   `dividendOf(_user)` should not be changed,
    //   but the computed value of `dividendPerShare * balanceOf(_user)` is changed.
    // To keep the `dividendOf(_user)` unchanged, we add a correction term:
    //   `dividendOf(_user) = dividendPerShare * balanceOf(_user) + dividendCorrectionOf(_user)`,
    //   where `dividendCorrectionOf(_user)` is updated whenever `balanceOf(_user)` is changed:
    //   `dividendCorrectionOf(_user) = dividendPerShare * (old balanceOf(_user)) - (new balanceOf(_user))`.
    // So now `dividendOf(_user)` returns the same value before and after `balanceOf(_user)` is changed.
    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;

    uint256 public totalDividendsDistributed;

    constructor (string memory _name, string memory _symbol, address _rewardToken) ERC20(_name, _symbol) {
        require (_rewardToken != address(0), "DividendPayingToken: rewards token cannot be the zero address");
        rewardToken = _rewardToken;
    }

    function distributeDividends (uint256 amount) public onlyOwner {
        require (totalSupply() > 0, "DividendPayingToken: No dividends exist to distribute");

        if (amount > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare + (amount * MAGNITUDE / totalSupply());
            emit DividendsDistributed (msg.sender, amount);
            totalDividendsDistributed += amount;
        }
    }

    /// @notice Gets the DividendPayingToken's dividend address.
    function getRewardToken() public view returns (address) {
        return rewardToken;
    }

    /// @notice Withdraws the reward distributed to the sender.
    /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn reward is greater than 0.
    function withdrawDividend() public virtual override {
        _withdrawDividendOfUser (msg.sender);
    }

    /// @notice Withdraws the reward distributed to the sender.
    /// @dev It emits a `DividendWithdrawn` event if the amount of withdrawn reward is greater than 0.
    function _withdrawDividendOfUser (address user) internal returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf (user);
        
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] += _withdrawableDividend;
            emit DividendWithdrawn (user, _withdrawableDividend);
            bool success = IERC20(rewardToken).transfer (user, _withdrawableDividend);
        
            if (!success) {
                withdrawnDividends[user] -= _withdrawableDividend;
                return 0;
            }
            
            return _withdrawableDividend;
        }

        return 0;
    }

    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function dividendOf (address _owner) public view override returns (uint256) {
        return withdrawableDividendOf (_owner);
    }

    /// @notice View the amount of dividend in wei that an address can withdraw.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` can withdraw.
    function withdrawableDividendOf (address _owner) public view override returns (uint256) {
        return (accumulativeDividendOf(_owner) - withdrawnDividends[_owner]);
    }

    /// @notice View the amount of dividend in wei that an address has withdrawn.
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has withdrawn.
    function withdrawnDividendOf (address _owner) public view override returns (uint256) {
        return withdrawnDividends[_owner];
    }

    /// @notice View the amount of dividend in wei that an address has earned in total.
    /// @dev accumulativeDividendOf(_owner) = withdrawableDividendOf(_owner) + withdrawnDividendOf(_owner)
    /// = (magnifiedDividendPerShare * balanceOf(_owner) + magnifiedDividendCorrections[_owner]) / MAGNITUDE
    /// @param _owner The address of a token holder.
    /// @return The amount of dividend in wei that `_owner` has earned in total.
    function accumulativeDividendOf (address _owner) public view override returns (uint256) {
        return ((magnifiedDividendPerShare * balanceOf(_owner)).toInt256Safe() + magnifiedDividendCorrections[_owner]).toUint256Safe() / MAGNITUDE;
    }

    /// @dev Internal function that transfer tokens from one address to another.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param from The address to transfer from.
    /// @param to The address to transfer to.
    /// @param value The amount to be transferred.
    function _transfer (address from, address to, uint256 value) internal virtual override {
        require (false);

        int256 _magCorrection = (magnifiedDividendPerShare * value).toInt256Safe();
        magnifiedDividendCorrections[from] += _magCorrection;
        magnifiedDividendCorrections[to] -= _magCorrection;
    }

    /// @dev Internal function that mints tokens to an account.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param account The account that will receive the created tokens.
    /// @param value The amount that will be created.
    function _mint (address account, uint256 value) internal override {
        super._mint (account, value);

        magnifiedDividendCorrections[account] -= (magnifiedDividendPerShare * value).toInt256Safe();
    }

    /// @dev Internal function that burns an amount of the token of a given account.
    /// Update magnifiedDividendCorrections to keep dividends unchanged.
    /// @param account The account whose tokens will be burnt.
    /// @param value The amount that will be burnt.
    function _burn (address account, uint256 value) internal override {
        super._burn (account, value);

        magnifiedDividendCorrections[account] += (magnifiedDividendPerShare * value).toInt256Safe();
    }

    function _setBalance (address account, uint256 newBalance) internal {
        uint256 currentBalance = balanceOf (account);

        if (newBalance > currentBalance) {
            uint256 mintAmount = newBalance - currentBalance;
            _mint (account, mintAmount);
        } else if (newBalance < currentBalance) {
            uint256 burnAmount = currentBalance - newBalance;
            _burn (account, burnAmount);
        }
    }
}


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

    function safeTransfer (IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn (token, abi.encodeWithSelector (token.transfer.selector, to, value));
    }

    function safeTransferFrom (IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn (token, abi.encodeWithSelector (token.transferFrom.selector, from, to, value));
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
        require ((value == 0) || (token.allowance (address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance");
        _callOptionalReturn (token, abi.encodeWithSelector (token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance (address(this), spender) + value;
        _callOptionalReturn (token, abi.encodeWithSelector (token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) - value;
        _callOptionalReturn (token, abi.encodeWithSelector (token.approve.selector, spender, newAllowance));
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

        bytes memory returndata = address(token).functionCall (data, "SafeERC20: low-level call failed");
        
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require (abi.decode (returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

library CircularBuffer {
    struct Buffer {
        // Represents the index in the array of the oldest element
        uint8 start; 
        // Represents the next position to write to
        uint8 end; 
        // Represents the size of the data (max of maxSize)
        uint8 size; 
        // Max length the buffer can be before it overwrites old data
        uint8 maxSize;
        // Circular buffer of amounts, will be initialised to maxSize
        uint256[] value;
        // Circular buffer of keys, will be initialised to maxSize
        uint8[] key;
        // Whether the buffer has been initialised (required to set maxSize)
        bool isInitialised;
        // Sum per key (updated every append)
        mapping(uint8 => uint256) sumPerKey;
        
        // The below will track any key that has ever been in the buffer
        // The keyList is used to zero mapping elements before the sum operation
        mapping(uint8 => bool) keyExists;
        uint8[] keyList; 
    }

    // Initialises the circular buffer to a maxSize of _bufferMaxLength
    function initialise (Buffer storage buffer, uint8 _bufferMaxLength) internal {
        require (_bufferMaxLength > 1, "CircularBuffer: should contain more than 1 element");
        buffer.maxSize = _bufferMaxLength;
        buffer.key = new uint8[](_bufferMaxLength);
        buffer.value = new uint256[](_bufferMaxLength);
        buffer.isInitialised = true;
    }

    // Appends a key-value pair to the buffer and caluclates the summed value per key
    function append (Buffer storage buffer, uint256 _value, uint8 _key) internal {
        require (buffer.isInitialised, "CircularBuffer: initialise buffer before use");
        buffer.value[buffer.end] = _value;
        buffer.key[buffer.end] = _key;
        buffer.end = (buffer.end + 1) % buffer.maxSize;
        
        if (!buffer.keyExists[_key]) {
            buffer.keyExists[_key] = true;
            buffer.keyList.push(_key);
        }

        if (buffer.size < buffer.maxSize)
            buffer.size += 1;
        else // start was just overwritten
            buffer.start = (buffer.start + 1) % buffer.maxSize;
            
        sum (buffer);
    }
    
    // Provides the summed values for all keys that have ever been contained in the buffer
    // As some keys may not be in the current buffer, these entries will still return but with a sum of 0
    function sum (Buffer storage buffer) internal {
        require (buffer.isInitialised, "CircularBuffer: initialise buffer before use");
        
        // First zero all keys
        for (uint8 i = 0; i < buffer.keyList.length; i++)
            buffer.sumPerKey[buffer.keyList[i]] = 0;
        
        // Then calculate sums for all existing keys
        for (uint8 i = 0; i < buffer.size; i++) {
            uint8 position = (buffer.start + i) % buffer.maxSize; // Go from oldest to newest
            buffer.sumPerKey[buffer.key[position]] += buffer.value[position];
        }
    }
}


contract Dough is ERC20, Ownable, SharedConstants {
    using Address for address payable;
    using SafeERC20 for IERC20;
    using CircularBuffer for CircularBuffer.Buffer;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private swapping;

    DividendManager public dividendManager;
    CircularBuffer.Buffer public transactionBuffer;
    address private doughDT;

    uint256 public constant SWAP_TOKENS_AT_AMOUNT = 100_000 * 10**18;
    
    uint256 public maxWalletAmount = 20_000_000 * 10**18;

    mapping(address => bool) public isBlacklisted;
    mapping(address => bool) private canStopAntibotMeasures;
    uint256 private antibotEndTime;
    uint256 private antibotTimeout;
    
    uint256 private marketingTokens; 
    uint256 private liquidityTokens;
    // Token counts for rewards are stored in each DividendTracker
    
    uint8[2] public liquidityFee = [4, 4];
    uint8[2] public marketingFee = [1, 6];
    // Fees for dividends are set in the constructor
    
    uint8 public maxSellPercentage = 100;//20; - CHANGEME
    uint256 public sellDelay = 2 hours;
    uint256 public paperHandsPenaltyTime = 1 minutes; //7 days; - CHANGEME
    mapping(address => uint256) public lastSellTime;
    mapping(address => uint256) public lastSellTimeBalance;
    mapping(address => uint256) public firstBuyTime;

    address payable public marketingWalletAddress = payable (0xFA26c6015850A393CF970ff4192776CdE859f893); //CHANGEME
    
    // use by default 500,000 gas to process auto-claiming dividends
    uint256 public gasForProcessing = 600_000;

    // exlcude from fees and max transaction amount
    mapping(address => bool) private isExcludedFromFees;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;

    event UpdateDividendManager (address indexed newAddress, address indexed oldAddress);
    event UpdateUniswapV2Router (address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees (address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees (address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair (address indexed pair, bool indexed value);
    event LiquidityWalletUpdated (address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event GasForProcessingUpdated (uint256 indexed newValue, uint256 indexed oldValue);
    event SwapAndLiquify (uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiquidity);
    event SendDividends (address indexed rewardToken, uint256 tokensSwapped, uint256 amount);
    event ProcessedDividendTracker (uint256 iterations, uint256 claims, uint256 lastProcessedIndex, bool indexed automatic, uint256 gas, address indexed processor);
    event BuybackFundsCreated (uint256 ethCreated);
    event BuybackAndBurn (uint256 ethSpent, uint256 tokensBurned);
    event MarketingWalletChanged (address indexed oldMarketingWallet, address indexed newMarketingWallet);
    event BuyFeesChanged (uint8[] oldRewardsFees, uint8[] newRewardsFees, uint8 oldLiquidityFee, uint8 newLiquidityFee, uint8 oldMarketingFee, uint8 newMarketingFee);
    event SellFeesChanged (uint8[] oldRewardsFees, uint8[] newRewardsFees, uint8 oldLiquidityFee, uint8 newLiquidityFee, uint8 oldMarketingFee, uint8 newMarketingFee);
    event PaperHandsPenaltyTimeChanged (uint256 oldPaperHandsPenaltyTime, uint256 newPaperHandsPenaltyTime);
    event SellRestrictionsChanged (uint256 oldMaxSellPercentage, uint256 newMaxSellPercentage, uint256 oldSellDelay, uint256 newSellDelay);
    event MaxWalletAmountChanged (uint256 oldMaxWalletAmount, uint256 newMaxWalletAmount);

    constructor() ERC20 ("Dough", "DOUGH") {
        dividendManager = new DividendManager();
        doughDT = dividendManager.addDividendTracker ("DoughDividendTracker", "DoughDT", address(this), 3600, 100_000 * 10**18, 5, 5); 
        dividendManager.addDividendTracker ("CakeDividendTracker", "CakeDT", CAKE, 3600, 100_000 * 10**18, 5, 5); 
        transactionBuffer.initialise (20);

        //0x10ED43C718714eb63d5aA57B78B54704E256024E <-- Mainnet PCS address
        //0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 <-- Testnet kiemtienonline PCS address - CHANGEME
        //0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D <-- Eth testnets Uniswap 
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); 
        // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from receiving dividends
        dividendManager.excludeFromAllDividends (address(dividendManager));
        dividendManager.excludeFromAllDividends (address(this));
        dividendManager.excludeFromAllDividends (address(_uniswapV2Router));
        dividendManager.excludeFromAllDividends (BURN_ADDRESS);
        dividendManager.excludeFromAllDividends (doughDT);

        // exclude from paying fees or having max transaction amount
        isExcludedFromFees[owner()] = true;
        isExcludedFromFees[marketingWalletAddress] = true;
        isExcludedFromFees[address(this)] = true;
        isExcludedFromFees[BURN_ADDRESS] = true;
        isExcludedFromFees[doughDT] = true;

        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 1_000_000_000 * (10**18));
    }

    receive() external payable {}

    function updateDividendManager (address newAddress) external onlyOwner {
        require (newAddress != address(dividendManager), "Dough: The dividend manager already exists");
        DividendManager newDividendManager = DividendManager(newAddress);
        
        require (newDividendManager.owner() == address(this), "Dough: The new dividend manager must be owned by the token contract");
        newDividendManager.excludeFromAllDividends (address(newDividendManager));
        newDividendManager.excludeFromAllDividends (address(this));
        newDividendManager.excludeFromAllDividends (address(uniswapV2Router));
        newDividendManager.excludeFromAllDividends(BURN_ADDRESS);
        newDividendManager.excludeFromAllDividends(doughDT);
        emit UpdateDividendManager (newAddress, address(dividendManager));
        dividendManager = newDividendManager;
    }

    function updateUniswapV2Router (address newAddress) external onlyOwner {
        require(newAddress != address(uniswapV2Router), "Dough: The router already has that address");
        emit UpdateUniswapV2Router (newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02 (newAddress);
        address _uniswapV2Pair = IUniswapV2Factory (uniswapV2Router.factory()).createPair (address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function excludeFromFees (address account, bool excluded) external onlyOwner {
        require (isExcludedFromFees[account] != excluded, "Dough: Account is already the value of 'excluded'");
        isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees (account, excluded);
    }

    function excludeMultipleAccountsFromFees (address[] memory accounts, bool excluded) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++)
            isExcludedFromFees[accounts[i]] = excluded;

        emit ExcludeMultipleAccountsFromFees (accounts, excluded);
    }

    function setMarketingWallet (address payable wallet) external onlyOwner {
        require (wallet != address(0), "Dough: Can't set marketing wallet to zero address");
        emit MarketingWalletChanged (marketingWalletAddress, wallet);
        marketingWalletAddress = wallet;
    }

    function setAntiBotStopAddresses (address[] memory accounts, bool canStop, uint256 _antibotTimeout) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            require (accounts[i] != address(0), "Dough: Can't set zero address as antibot stop address");
            canStopAntibotMeasures[accounts[i]] = canStop;
        }
        
        antibotTimeout = _antibotTimeout;
    }
    
    function setBuyFees (uint8[] memory _rewardsFee, uint8 _liquidityFee, uint8 _marketingFee) external onlyOwner {
        require (_rewardsFee.length == dividendManager.dividendTrackers(), "Dough: Must provide a fee per dividend tracker (array wrong length)");
        uint256 totalBuyFees;
        
        for (uint256 i = 0; i < _rewardsFee.length; i++)
            totalBuyFees += _rewardsFee[i];
        
        totalBuyFees += _liquidityFee + _marketingFee;
        require (totalBuyFees <= 35, "Dough: Fees can't be > 35%");
        emit BuyFeesChanged (dividendManager.getFees(BUY), _rewardsFee, liquidityFee[BUY], _liquidityFee, marketingFee[BUY], _marketingFee);
        
        liquidityFee[BUY] = _liquidityFee;
        marketingFee[BUY] = _marketingFee;
        dividendManager.updateFees (_rewardsFee, BUY);
    }
    
    function setSellFees (uint8[] memory _rewardsFee, uint8 _liquidityFee, uint8 _marketingFee) external onlyOwner {
        require (_rewardsFee.length == dividendManager.dividendTrackers(), "Dough: Must provide a fee per dividend tracker (array wrong length)");
        uint256 totalSellFees;
        
        for (uint256 i = 0; i < _rewardsFee.length; i++)
            totalSellFees += _rewardsFee[i];
        
        totalSellFees += _liquidityFee + _marketingFee;
        require (totalSellFees <= 35, "Dough: Fees can't be > 35%");
        emit SellFeesChanged (dividendManager.getFees(SELL), _rewardsFee, liquidityFee[SELL], _liquidityFee, marketingFee[SELL], _marketingFee);
        
        liquidityFee[SELL] = _liquidityFee;
        marketingFee[SELL] = _marketingFee;
        dividendManager.updateFees (_rewardsFee, SELL);
    }

    function updatePaperHandsPenaltyTime (uint256 _paperHandsPenaltyTimeInDays) external onlyOwner {
        require (_paperHandsPenaltyTimeInDays >= 0 && _paperHandsPenaltyTimeInDays <= 14 days, "Dough: paperHandsPenaltyTime must be between 0 and 14 days");
        uint256 newPaperHandsPenaltyTime = _paperHandsPenaltyTimeInDays * 1 days;
        emit PaperHandsPenaltyTimeChanged (paperHandsPenaltyTime, newPaperHandsPenaltyTime);
        paperHandsPenaltyTime = newPaperHandsPenaltyTime;
    }

    function updateSellRestrictions (uint8 _maxSellPercentage, uint256 _sellDelayInMinutes) external onlyOwner {
        require (_maxSellPercentage >= 5 && _maxSellPercentage <= 100, "Dough: maxSellPercentage must be between 5% and 100%");
        require (_sellDelayInMinutes >= 0 && _sellDelayInMinutes <= 1440, "Dough: sellDelay must be between 0 minutes and 1 day (1440 minutes)");
        uint256 newSellDelay = _sellDelayInMinutes * 1 minutes;
        emit SellRestrictionsChanged (maxSellPercentage, _maxSellPercentage, sellDelay, newSellDelay);
        maxSellPercentage = _maxSellPercentage;
        sellDelay = newSellDelay;
    }

    function setAutomatedMarketMakerPair (address pair, bool value) external onlyOwner {
        require (pair != uniswapV2Pair, "Dough: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair (pair, value);
    }

    function blacklistAddress (address account, bool blacklist) external onlyOwner {
        isBlacklisted[account] = blacklist;
    }
       
    function setMaxWalletPermille (uint8 maxWalletPermille) external onlyOwner {
        require (maxWalletPermille >= 5 && maxWalletPermille <= 1000, "Dough: The max wallet percentage must be between 0.5% (5) and 100% (1000)");
        uint256 newMaxWalletAmount = totalSupply() * maxWalletPermille / 1000;
        emit MaxWalletAmountChanged (maxWalletAmount, newMaxWalletAmount);
        maxWalletAmount = newMaxWalletAmount;
    }

    function setAntiBotStopAddress (address account, bool canStop, uint256 _antibotTimeout) external onlyOwner {
        require (account != address(0), "Dough: Can't set zero address as antibot stop address");
        canStopAntibotMeasures[account] = canStop;
        antibotTimeout = _antibotTimeout;
    }

    function _setAutomatedMarketMakerPair (address pair, bool value) private {
        require (automatedMarketMakerPairs[pair] != value, "Dough: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if (value)
            dividendManager.excludeFromAllDividends (pair);

        emit SetAutomatedMarketMakerPair (pair, value);
    }

    function updateGasForProcessing (uint256 newValue) external onlyOwner {
        require (newValue >= 200_000 && newValue <= 750_000, "Dough: gasForProcessing must be between 200,000 and 750,000");
        require (newValue != gasForProcessing, "Dough: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated (newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWaits (uint256[] memory claimWait) external onlyOwner {
        dividendManager.updateClaimWaits (claimWait);
    }

    function getClaimWaits() external view returns (uint256[] memory) {
        return dividendManager.claimWaits();
    }

    function getTotalDividendsDistributed() external view returns (uint256[] memory) {
        return dividendManager.totalDividendsDistributed();
    }

    function checkIfExcludedFromFees (address account) external view returns (bool) {
        return isExcludedFromFees[account];
    }

    function withdrawableDividendsOf (address account) external view returns (uint256[] memory) {
        return dividendManager.withdrawableDividendsOf (account);
    }

    function dividendTokenBalancesOf (address account) external view returns (uint256[] memory) {
        return dividendManager.balancesOf (account);
    }

    function excludeFromAllDividends (address account) external onlyOwner {
        dividendManager.excludeFromAllDividends (account);
    }

    function excludeFromSelectedDividends (address account, bool[] memory excluded) external onlyOwner {
        dividendManager.excludeFromSelectedDividends (account, excluded);
    }

    function getAccountDividendsInfo (address account, uint256 dividendTrackerID) external view returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256) {
        return dividendManager.getAccount (account, dividendTrackerID);
    }

    function getAccountDividendsInfoAtIndex (uint256 index, uint256 dividendTrackerID) external view returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256) {
        return dividendManager.getAccountAtIndex (index, dividendTrackerID);
    }

    function processDividendTrackers (uint256 gas) external {
        (uint256[] memory iterations, uint256[] memory claims, uint256[] memory lastProcessedIndex) = dividendManager.process (gas);
        
        for (uint256 i = 0; i < iterations.length; i++)
            emit ProcessedDividendTracker(iterations[i], claims[i], lastProcessedIndex[i], false, (gas / iterations.length), tx.origin);
    }

    function claim (address account) external onlyOwner {
        dividendManager.processAccount (account);
    }

    function getLastProcessedIndexes() external view returns (uint256[] memory) {
        return dividendManager.getLastProcessedIndexes();
    }

    function getNumberOfDividendTokenHolders() external view returns (uint256[] memory) {
        return dividendManager.getNumberOfTokenHolders();
    }
    
    function getTransferAmounts (uint256 amount, uint8 feeType) private returns (uint256, uint256) {
        uint256 _marketingTokens = amount * marketingFee[feeType] / 100;
        uint256 _liquidityTokens = amount * liquidityFee[feeType] / 100;
        
        // Specific for Dough, breaks extensibility
        uint8 cakeFee = dividendManager.getFee (feeType, CAKE); 
        uint8 doughFee = dividendManager.getFee (feeType, address(this)); 
        uint8 ttlRwdFees = dividendManager.getSummedFees (feeType);
        
        // Dough Fee In Percent  = Sum Sells * Original Dough Fee * Total Dividend Fees / (Sum Buys * Original Cake Fee + Sum Sells * Original Dough Fee)
        // increase dough fee on sells, increase on buys
        uint256 doughTokens = amount * transactionBuffer.sumPerKey[SELL] * doughFee * ttlRwdFees
            / (100 * (transactionBuffer.sumPerKey[SELL] * doughFee + transactionBuffer.sumPerKey[BUY] * cakeFee));
            
        // Cake Fee In Percent = Sum Buys * Original Cake Fee * Total Dividend Fees / (Sum Buys * Original Cake Fee + Sum Sells * Original Dough Fee)
        // increase cake fee on buys, decrease on sells
        uint256 cakeTokens = amount * transactionBuffer.sumPerKey[BUY] * cakeFee * ttlRwdFees
            / (100 * (transactionBuffer.sumPerKey[SELL] * doughFee + transactionBuffer.sumPerKey[BUY] * cakeFee));
        
        // Keep track of balances so we can split the address balance
        dividendManager.incrementFeeTokens (doughTokens, address(this));
        dividendManager.incrementFeeTokens (cakeTokens, CAKE);
        marketingTokens += _marketingTokens;
        liquidityTokens += _liquidityTokens;
        uint256 fees = _marketingTokens + _liquidityTokens + doughTokens + cakeTokens;
        return (amount - fees, fees);
    }

    function _transfer (address from, address to, uint256 amount) internal override {
        require (from != address(0), "ERC20: transfer from the zero address");
        require (to != address(0), "ERC20: transfer to the zero address");
        require (!isBlacklisted[from] && !isBlacklisted[to], "Blacklisted address");
        
        // Need to allow owner to add liquidity, otherwise prevent any snipers from buying for the first few blocks
        if (from != owner() && to != owner() && (block.timestamp <= antibotEndTime || antibotEndTime == 0)) {
            require (canStopAntibotMeasures[to], "Dough: Bots can't stop antibot measures");
            
            if (antibotEndTime == 0)
                antibotEndTime = block.timestamp + antibotTimeout;
        }

        if (amount == 0) {
            super._transfer (from, to, 0);
            return;
        } else if (from == doughDT) { // Don't get caught in circular payout events
            super._transfer (from, to, amount);
            return;
        }
        
        // Check max wallet
        if (from != owner() && !isExcludedFromFees[to] && to != uniswapV2Pair)
            require (balanceOf(to) + amount <= maxWalletAmount, "Dough: Receiver's wallet balance exceeds the max wallet amount");
        
        uint8 feeType = BUY;
        
        if (automatedMarketMakerPairs[to]) {
            feeType = SELL;
            
            //if (from != address(this)) - CHANGEME may need to add this if skewed too far towards sell
            transactionBuffer.append (amount, SELL);
            
            if (!isExcludedFromFees[from]) {
                // Can only sell maxSellPercentage of wallet every sellDelay
                uint256 maxAllowedToSell = balanceOf(from) * maxSellPercentage / 100;
                require (amount <= maxAllowedToSell, "Dough: Sell amount too high"); // Catches sells > maxSellPercentage
                
                if (block.timestamp - lastSellTime[from] <= sellDelay) {
                    maxAllowedToSell = lastSellTimeBalance[from] * maxSellPercentage / 100;
                    // Catches multiple sells > maxSellPercentage within sellDelay
                    require (balanceOf(from) - amount >= lastSellTimeBalance[from] - maxAllowedToSell, "Dough: Wait until sell delay is up to sell again"); 
                } else {
                    lastSellTime[from] = block.timestamp;
                    lastSellTimeBalance[from] = balanceOf(from);
                }
                
                if (block.timestamp - firstBuyTime[from] < paperHandsPenaltyTime) // If you sell within paperHandsPenaltyTime of buying, you don't get rewards
                    dividendManager.excludeFromAllDividends (from);
            }
        } else if (automatedMarketMakerPairs[from]) {
            transactionBuffer.append (amount, BUY);
            
            if (firstBuyTime[to] == 0) //first time they have bought
                firstBuyTime[to] = block.timestamp;
        }

        if (balanceOf (address(this)) >= SWAP_TOKENS_AT_AMOUNT && !swapping && !automatedMarketMakerPairs[from] && !isExcludedFromFees[from] && to != owner()) {
            swapping = true;
            sellTokensForBNBAndTakeFees();
            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if (isExcludedFromFees[from] || isExcludedFromFees[to])
            takeFee = false;

        if (takeFee) {
            (uint256 transferAmount, uint256 fees) = getTransferAmounts (amount, feeType);
            amount = transferAmount;
            super._transfer (from, address(this), fees);
        }

        super._transfer (from, to, amount);

        try dividendManager.setBalance (from, balanceOf(from)) {} catch {}
        try dividendManager.setBalance (to, balanceOf(to)) {} catch {}

        if (!swapping) {
            uint256 gas = gasForProcessing;

            try dividendManager.process(gas) returns (uint256[] memory iterations, uint256[] memory claims, uint256[] memory lastProcessedIndex) {
                for (uint256 i = 0; i < iterations.length; i++)
                    emit ProcessedDividendTracker(iterations[i], claims[i], lastProcessedIndex[i], true, (gas / iterations.length), tx.origin);
            } catch {}
        }
    }
    
    function sellTokensForBNBAndTakeFees() private {
        uint256 bnbForMarketingAndRewards = swapLiquifyAndSellToBNB();
        uint256 cakeRewardTokens = dividendManager.getFeeTokensFromRewardAddress (CAKE);
        // Split returned BNB into marketing and dividend amounts
        uint256 bnbForCake = bnbForMarketingAndRewards * cakeRewardTokens / (marketingTokens + cakeRewardTokens);
        // Swap BNB to Cake and send dividends to Cake dividend tracker and distribute
        swapAndSendDividends (bnbForCake);
        // Send BNB to marketing wallet
        uint256 bnbForMarketing = address(this).balance - bnbForCake;
        marketingWalletAddress.sendValue (bnbForMarketing);
        // Send native dividends to Dough dividend tracker and distribute
        uint256 doughDividends = balanceOf (address(this));
        super._transfer (address(this), dividendManager.getTrackerAddress (address(this)), doughDividends);
        dividendManager.distributeDividends (doughDividends, address(this));
        emit SendDividends (address(this), doughDividends, doughDividends);
        // Make sure we zero the count of tokens set aside for Dough dividends
        dividendManager.resetFeeTokens (address(this));
    }

    function swapLiquifyAndSellToBNB() private returns (uint256) {
        uint256 bnbForFees;
        // split tokens for LP into halves
        uint256 half = liquidityTokens / 2;
        uint256 otherHalf = liquidityTokens - half;
        // Swap half LP tokens + marketing + Cake reward tokens at once to avoid multiple contract sells
        uint256 tokensToSwap = half + marketingTokens + dividendManager.getFeeTokensFromRewardAddress (CAKE);
        bnbForFees = swapTokensForBNB (tokensToSwap);

        if (bnbForFees > 0) {
            liquidityTokens = 0;
            uint256 bnbToLiquidity;
            // Send all BNB to addLiquidity as additional will be returned
            (bnbForFees, bnbToLiquidity) = addLiquidity (otherHalf, bnbForFees);
            emit SwapAndLiquify (half, bnbToLiquidity, otherHalf);
        }
        
        return bnbForFees;
    }

    function swapTokensForBNB (uint256 tokenAmount) private returns (uint256) {
        uint256 initialBalance = address(this).balance;
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve (address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens (
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        
        return (address(this).balance - initialBalance);
    }

    function swapBNBForCake (uint256 bnbAmount) private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = CAKE;

        // make the swap
        uniswapV2Router.swapExactETHForTokens {value: bnbAmount} (
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity (uint256 tokenAmount, uint256 bnbAmount) private returns (uint256, uint256) {
        // approve token transfer to cover all possible scenarios
        _approve (address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        (,uint256 bnbToLiquidity,) = uniswapV2Router.addLiquidityETH {value: bnbAmount} (
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
        
        return (bnbAmount - bnbToLiquidity, bnbToLiquidity);
    }

    function swapAndSendDividends (uint256 bnbForDividend) private {
        swapBNBForCake (bnbForDividend);
        uint256 dividends = IERC20(CAKE).balanceOf (address(this));
        
        if (dividends > 0) {
            bool success = IERC20(CAKE).transfer (dividendManager.getTrackerAddress (CAKE), dividends);
        
            if (success) {
                dividendManager.distributeDividends (dividends, CAKE);
                emit SendDividends (CAKE, dividendManager.getFeeTokensFromRewardAddress (CAKE), dividends);
            }
        
        
            dividendManager.resetFeeTokens (CAKE);
        }
    }
}

contract DividendManager is Ownable, SharedConstants {
    DividendTracker[] public dtArray;
    uint256[] public trackerFeeTokensToSwap;
    
    constructor() { }
    
    function addDividendTracker (string memory name, string memory ticker, address rewardToken, uint256 claimWait, uint256 minBalanceForDividends, uint8 buyFeeToTake, uint8 sellFeeToTake) 
        external 
        onlyOwner 
        returns (address)
    {
        DividendTracker newDividendTracker = new DividendTracker (name, ticker, rewardToken, claimWait, minBalanceForDividends, buyFeeToTake, sellFeeToTake);
        dtArray.push (newDividendTracker);
        uint256 feeTokens;
        trackerFeeTokensToSwap.push (feeTokens);
        
        //exclude all other dividends from this
       for (uint i = 0; i < dtArray.length - 1; i++) 
            excludeFromAllDividends (address(dtArray[i]));
        
        return address(newDividendTracker);
    }
    
    function incrementFeeTokens (uint256 tokens, uint256 dividendTrackerID) external onlyOwner {
        trackerFeeTokensToSwap[dividendTrackerID] += tokens;
    }
    
    function incrementFeeTokens (uint256 tokens, address rewardToken) external onlyOwner {
        trackerFeeTokensToSwap[getIDFromRewardAddress (rewardToken)] += tokens;
    }
    
    function incrementFeeTokens (uint256[] memory tokens) external onlyOwner {
        require (tokens.length == dtArray.length, "DividendManager: Must provide fee tokens value for each tracker (array wrong length)");
        
        
        for (uint256 i = 0; i < dtArray.length; i++)
            trackerFeeTokensToSwap[i] += tokens[i];
    }
    
    function resetFeeTokens (uint256 dividendTrackerID) external onlyOwner {
        trackerFeeTokensToSwap[dividendTrackerID] = 0;
    }
    
    function resetFeeTokens (address rewardToken) external onlyOwner {
        trackerFeeTokensToSwap[getIDFromRewardAddress (rewardToken)] = 0;
    }
    
    function excludeFromSelectedDividends (address account, bool[] memory excluded) public onlyOwner {
        require (excluded.length == dtArray.length, "DividendManager: Must provide excluded value for each tracker (array wrong length)");
        
        for (uint256 i = 0; i < dtArray.length; i++) {
            if (excluded[i])
                dtArray[i].excludeFromDividends (account);
        }
    }
    
    function excludeFromAllDividends (address account) public onlyOwner {
        for (uint256 i = 0; i < dtArray.length; i++)
            dtArray[i].excludeFromDividends (account);
    }
    
    function updateClaimWaits (uint256[] memory newClaimWaits) external onlyOwner {
        require (newClaimWaits.length == dtArray.length, "DividendManager: Must provide newClaimwWait for each tracker (array wrong length)");
        
        for (uint256 i = 0; i < dtArray.length; i++)
            dtArray[i].updateClaimWait (newClaimWaits[i]);
    }
    
    function updateFees (uint8[] memory newFees, uint8 feeType) external onlyOwner {
        require (newFees.length == dtArray.length, "DividendManager: Must provide new fees for each tracker (array wrong length)");
        
        for (uint256 i = 0; i < dtArray.length; i++)
            dtArray[i].updateFee (newFees[i], feeType);
    }
    
    function distributeDividends (uint256 amount, uint256 dividendTrackerID) external onlyOwner {
        dtArray[dividendTrackerID].distributeDividends (amount);
    }
    
    function distributeDividends (uint256 amount, address rewardToken) external onlyOwner {
        dtArray[getIDFromRewardAddress (rewardToken)].distributeDividends (amount);
    }
    
    function process (uint256 gas) external onlyOwner returns (uint256[] memory, uint256[] memory, uint256[] memory) {
        uint256 gasPerTracker = gas / dtArray.length; //Split the available gas between the trackers
        uint256[] memory iterations = new uint256[](dtArray.length);
        uint256[] memory claims = new uint256[](dtArray.length);
        uint256[] memory lastProcessedIndex = new uint256[](dtArray.length);
        
        for (uint256 i = 0; i < dtArray.length; i++) {
            (uint256 _iterations, uint256 _claims, uint256 _lastProcessedIndex) = dtArray[i].process (gasPerTracker);
            iterations[i] = _iterations;
            claims[i] = _claims;
            lastProcessedIndex[i] = _lastProcessedIndex;
        }
        
        return (iterations, claims, lastProcessedIndex);
    }
    
    function setBalance (address account, uint256 newBalance) external onlyOwner {
        for (uint256 i = 0; i < dtArray.length; i++)
            dtArray[i].setBalance (account, newBalance);
    }
    
    function processAccount (address account) external onlyOwner {
        for (uint256 i = 0; i < dtArray.length; i++)
            dtArray[i].processAccount (account, false);
    }
    
    function getIDFromRewardAddress (address reward) public view returns (uint256) {
        for (uint256 i = 0; i < dtArray.length; i++) {
            if (reward == dtArray[i].getRewardToken())
                return i;
        }
        
        revert ("DividendManager: Reward Address not found in DividendTracker rewards");
    }
    
    function getFeeTokensFromRewardAddress (address reward) public view returns (uint256) {
        return trackerFeeTokensToSwap[getIDFromRewardAddress (reward)];
    }
    
    function getSummedFeeTokens() public view returns (uint256) {
        uint256 summedFeeTokens;
        
        for (uint256 i = 0; i < trackerFeeTokensToSwap.length; i++) {
            summedFeeTokens += trackerFeeTokensToSwap[i];
        }
        
        return summedFeeTokens;
    }
    
    function getRewardToken (uint256 dividendTrackerID) public view returns (address) {
        return dtArray[dividendTrackerID].getRewardToken();
    }
    
    function getTrackerAddress (uint256 dividendTrackerID) public view returns (address) {
        return address(dtArray[dividendTrackerID]);
    }
    
    function getTrackerAddress (address rewardToken) public view returns (address) {
        return address(dtArray[getIDFromRewardAddress (rewardToken)]);
    }
    
    function getLastProcessedIndexes() public view returns (uint256[] memory) {
        uint256[] memory lastProcessedIndexes = new uint256[](dtArray.length);
        
        for (uint256 i = 0; i < dtArray.length; i++)
            lastProcessedIndexes[i] = dtArray[i].getLastProcessedIndex();
            
        return lastProcessedIndexes;
    }

    function getNumberOfTokenHolders() public view returns (uint256[] memory) {
        uint256[] memory numberOfTokenHolders = new uint256[](dtArray.length);
        
        for (uint256 i = 0; i < dtArray.length; i++)
            numberOfTokenHolders[i] = dtArray[i].getNumberOfTokenHolders();
            
        return numberOfTokenHolders;
    }
    
    function totalDividendsDistributed() public view returns (uint256[] memory) {
        uint256[] memory totalDividendsPerTracker = new uint256[](dtArray.length);
        
        for (uint256 i = 0; i < dtArray.length; i++)
            totalDividendsPerTracker[i] = dtArray[i].totalDividendsDistributed();
        
        return totalDividendsPerTracker;
    }
    
    function withdrawableDividendsOf (address account) public view returns (uint256[] memory) {
        uint256[] memory withdrawableDividendPerTracker = new uint256[](dtArray.length);
        
        for (uint256 i = 0; i < dtArray.length; i++)
            withdrawableDividendPerTracker[i] = dtArray[i].withdrawableDividendOf (account);
        
        return withdrawableDividendPerTracker;
    }
    
    // Returns fees per tracker for this feeType in an array, with the last element being the summed fees for all trackers
    function getFees (uint8 feeType) public view returns (uint8[] memory) {
        uint8[] memory fees = new uint8[](dtArray.length + 1);
        uint8 summedFees;
        
        for (uint256 i = 0; i < dtArray.length; i++) {
            fees[i] = dtArray[i].fee (feeType);
            summedFees += fees[i];
        }
        
        fees[dtArray.length] = summedFees;
        return fees;
    }
    
    function getSummedFees (uint8 feeType) public view returns (uint8) {
        uint8 summedFees;
        
        for (uint256 i = 0; i < dtArray.length; i++) {
            summedFees += dtArray[i].fee (feeType);
        }
        
        return summedFees;
    }
    
    function getFee (uint8 feeType, address rewardToken) public view returns (uint8) {
        return dtArray[getIDFromRewardAddress (rewardToken)].fee(feeType);
    }
    
    function claimWaits() public view returns (uint256[] memory) {
        uint256[] memory claimWait = new uint256[](dtArray.length);
        
        for (uint256 i = 0; i < dtArray.length; i++)
            claimWait[i] = dtArray[i].claimWait();
        
        return claimWait;
    }
    
    function balancesOf(address account) public view returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](dtArray.length);
        
        for (uint256 i = 0; i < dtArray.length; i++)
            balances[i] = dtArray[i].balanceOf (account);
        
        return balances;
    }
    
    function getAccount (address account, uint256 dividendTrackerID) public view returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256) {
        require (dividendTrackerID < dtArray.length, "DividendManager: ID does not exist");
        return dtArray[dividendTrackerID].getAccount (account);
    }
    
    function getAccountAtIndex (uint256 index, uint256 dividendTrackerID) public view returns (address, int256, int256, uint256, uint256, uint256, uint256, uint256) {
        require (dividendTrackerID < dtArray.length, "DividendManager: ID does not exist");
        return dtArray[dividendTrackerID].getAccountAtIndex (index);
    }
    
    function dividendTrackers() public view returns (uint256) {
        return dtArray.length;
    }
}

contract DividendTracker is Ownable, DividendPayingToken {
    using SafeMathConversion for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping(address => bool) public excludedFromDividends;

    mapping(address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;
    uint8[2] public fee;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor (string memory _name, string memory _ticker, address _rewardToken, uint256 _claimWait, uint256 _minimumTokenBalanceForDividends, uint8 _buyFee, uint8 _sellFee) 
        DividendPayingToken (_name, _ticker, _rewardToken) 
    {
        claimWait = _claimWait;
        minimumTokenBalanceForDividends = _minimumTokenBalanceForDividends;
        fee[BUY] = _buyFee;
        fee[SELL] = _sellFee;
    }
    
    function updateFee (uint8 newFee, uint8 feeType) external onlyOwner {
        fee[feeType] = newFee;
    }

    function _transfer (address, address, uint256) internal pure override {
        require(false, "DividendTracker: No transfers allowed");
    }

    function withdrawDividend() public pure override {
        require(false, "DividendTracker: withdrawDividend disabled. Use the 'claim' function on the main contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
        excludedFromDividends[account] = true;
        _setBalance(account, 0);
        tokenHoldersMap.remove(account);
        emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 900 && newClaimWait <= 86400, "DividendTracker: claimWait must be updated to between 15 mins and 24 hours");
        require(newClaimWait != claimWait, "DividendTracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function getLastProcessedIndex() external view returns (uint256) {
        return lastProcessedIndex;
    }
    
    function getNumberOfTokenHolders() external view returns (uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getAccount (address _account) public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable
        )
    {
        account = _account;
        index = tokenHoldersMap.getIndexOfKey(account);
        iterationsUntilProcessed = -1;

        if (index >= 0) {
            if (uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index - int256(lastProcessedIndex);
            } else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ? tokenHoldersMap.keys.length - lastProcessedIndex : 0;
                iterationsUntilProcessed = index + int256(processesUntilEndOfArray);
            }
        }

        withdrawableDividends = withdrawableDividendOf (account);
        totalDividends = accumulativeDividendOf (account);

        lastClaimTime = lastClaimTimes[account];
        nextClaimTime = lastClaimTime > 0 ? lastClaimTime + claimWait : 0;
        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ? nextClaimTime - block.timestamp : 0;
    }

    function getAccountAtIndex (uint256 index) public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        if (index >= tokenHoldersMap.size())
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);

        address account = tokenHoldersMap.getKeyAtIndex (index);
        return getAccount (account);
    }

    function canAutoClaim (uint256 lastClaimTime) private view returns (bool) {
        if (lastClaimTime > block.timestamp)
            return false;

        return block.timestamp - lastClaimTime >= claimWait;
    }

    function setBalance (address account, uint256 newBalance) external onlyOwner {
        if (excludedFromDividends[account])
            return;

        if (newBalance >= minimumTokenBalanceForDividends) {
            _setBalance (account, newBalance);
            tokenHoldersMap.set (account, newBalance);
        } else {
            _setBalance (account, 0);
            tokenHoldersMap.remove (account);
        }

        processAccount (account, true);
    }

    function process (uint256 gas) public returns (uint256, uint256, uint256) {
        uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        if (numberOfTokenHolders == 0)
            return (0, 0, lastProcessedIndex);

        uint256 _lastProcessedIndex = lastProcessedIndex;
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 iterations = 0;
        uint256 claims = 0;

        while (gasUsed < gas && iterations < numberOfTokenHolders) {
            _lastProcessedIndex++;

            if (_lastProcessedIndex >= tokenHoldersMap.keys.length)
                _lastProcessedIndex = 0;

            address account = tokenHoldersMap.keys[_lastProcessedIndex];

            if (canAutoClaim (lastClaimTimes[account])) {
                if (processAccount (account, true)) {
                    claims++;
                }
            }

            iterations++;
            uint256 newGasLeft = gasleft();

            if (gasLeft > newGasLeft)
                gasUsed += (gasLeft - newGasLeft);

            gasLeft = newGasLeft;
        }

        lastProcessedIndex = _lastProcessedIndex;
        return (iterations, claims, lastProcessedIndex);
    }

    function processAccount (address account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser (account);

        if (amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim (account, amount, automatic);
            return true;
        }

        return false;
    }
}