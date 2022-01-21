/**
 *Submitted for verification at BscScan.com on 2022-01-21
*/

pragma solidity ^0.8.11;
//SPDX-License-Identifier: none

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
    constructor(string memory name_, string memory symbol_) {
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
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

library SafeMathInt {
  function mul(int256 a, int256 b) internal pure returns (int256) {

    require(!(a == - 2**255 && b == -1) && !(b == - 2**255 && a == -1));

    int256 c = a * b;
    require((b == 0) || (c / b == a));
    return c;
  }

  function div(int256 a, int256 b) internal pure returns (int256) {

    require(!(a == - 2**255 && b == -1) && (b > 0));

    return a / b;
  }

  function sub(int256 a, int256 b) internal pure returns (int256) {
    require((b >= 0 && a - b <= a) || (b < 0 && a - b > a));

    return a - b;
  }

  function add(int256 a, int256 b) internal pure returns (int256) {
    int256 c = a + b;
    require((b >= 0 && c >= a) || (b < 0 && c < a));
    return c;
  }

  function toUint256Safe(int256 a) internal pure returns (uint256) {
    require(a >= 0);
    return uint256(a);
  }
}

library SafeMathUint {
  function toInt256Safe(uint256 a) internal pure returns (int256) {
    int256 b = int256(a);
    require(b >= 0);
    return b;
  }
}

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

contract TeslaKitty is Context, ERC20, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;

	bool private trading;
    bool private starting;
    bool public burning;
    bool public swapping;

	address public buybackWallet;
    address private marketingWallet;
    address private developmentWallet;
    address private charityWallet;
    address private liquidityWallet;

    uint256 public swapTokensAtAmount;

    uint256 private _buyBuybackFee;
    uint256 private _buyMarketingFee;
    uint256 private _buyDevelopmentFee;
    uint256 private _buyCharityFee;
    uint256 private _buyLiquidityFee;

    uint256 private _sellBuybackFee;
    uint256 private _sellMarketingFee;
    uint256 private _sellDevelopmentFee;
	uint256 private _sellCharityFee;
    uint256 private _sellLiquidityFee;

    uint256 private elonRent;

    uint256 public _maxWallet;
    uint256 public _maxBuy;
    uint256 public _maxSell;
    uint256 private _previousMaxWallet;
    uint256 private _previousMaxSell;
    uint256 private _previousMaxBuy;

    uint256 public totalBuyFees;
    uint256 public totalSellFees;

	uint256 public contractTokenBalanceAmount;

    uint256 private constant DefaultTime = 30 days;

    mapping (address => bool) private _isExcludedFromFees;

    mapping (address => bool) public automatedMarketMakerPairs;
    mapping (address => bool) public _isBlacklisted;
    mapping (address => bool) public _isElon;
    mapping (address => bool) public _isExcludedFromContractBuyingLimit;

    modifier onlyNonContract {
        if (_isExcludedFromContractBuyingLimit[msg.sender]) {
            _;
        } else {
            require(!address(msg.sender).isContract(), 'Contract not allowed to call');
            _;
        }
    }

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event isElon(address indexed account, bool isExcluded);
    event blacklist(address indexed account, bool isBlacklisted);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event tradingUpdated(bool _enabled);
    event burningUpdated(bool _enabled);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event ProductiongWalletUpdated(address indexed newbuybackWallet, address indexed oldbuybackWallet);
    event MarketingWalletUpdated(address indexed newMarketingWallet, address indexed oldMarketingWallet);
    event DevelopmentWalletUpdated(address indexed newDevelopmentWallet, address indexed oldDevelopmentWallet);
    event CharityWalletUpdated(address indexed newCharityWallet, address indexed oldCharityWallet);
    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(
    	uint256 tokensSwapped,
    	uint256 amount
    );

    constructor() ERC20 ("Tesla Kitty", "TKitty") {

        _buyBuybackFee = 2;
        _buyMarketingFee = 5;
        _buyDevelopmentFee = 0;
        _buyCharityFee = 0;
        _buyLiquidityFee = 3;

        _sellBuybackFee = 2;
        _sellMarketingFee = 5;
        _sellDevelopmentFee = 0;
        _sellCharityFee = 0;
        _sellLiquidityFee = 3;

        elonRent = 99;

		contractTokenBalanceAmount = 25000000 * 10**18;

        swapTokensAtAmount = 25000000 * (10**18);
        _maxWallet = 100000000 * (10**18);
        _maxBuy = 100000000 * (10**18);
        _maxSell = 50000000 * (10**18);

        totalBuyFees = _buyBuybackFee.add(_buyMarketingFee).add(_buyDevelopmentFee).add(_buyCharityFee).add(_buyLiquidityFee);
        totalSellFees = _sellBuybackFee.add(_sellMarketingFee).add(_sellDevelopmentFee).add(_sellCharityFee).add(_sellLiquidityFee);

    	liquidityWallet = owner();

        buybackWallet = address(payable(0xa94d45EC3184d6c003098389EC4877e46318cdfA));
        marketingWallet = address(payable(0xdbE10Bb0a7F80843f279191bc434a69804cC7327));
        developmentWallet = address(payable(0x8aA11D77aB9F99D0f1823dd37b90FEd303d5F7E2));
        charityWallet = address(payable(0x31CE3425C93a279089e2C9F1D758D682A3707F64));

    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    	//0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 Testnet
    	//0x10ED43C718714eb63d5aA57B78B54704E256024E BSC Mainnet
    	//0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D Ropsten
    	//0xCDe540d7eAFE93aC5fE6233Bee57E1270D3E330F BakerySwap
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from paying fees
        excludeFromFees(liquidityWallet, true);
        excludeFromFees(marketingWallet, true);
		excludeFromFees(buybackWallet, true);
		excludeFromFees(developmentWallet, true);
		excludeFromFees(charityWallet, true);
        excludeFromFees(address(this), true);

        _isExcludedFromContractBuyingLimit[address(this)] = true;
        _isExcludedFromContractBuyingLimit[0x10ED43C718714eb63d5aA57B78B54704E256024E] = true;
        _isExcludedFromContractBuyingLimit[address(uniswapV2Pair)] = true;
        
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 5000000000 * (10**18));
        _mint(address(0xDE29893001Db48CA2FB5E66F2034f33e33a4955d), 50000000 * (10**18));
        _mint(address(0x5dF8Be3E5F37B50FC2C061fa23d196ba435d98eC), 50000000 * (10**18));
        _mint(address(0xCC362Dbec2EB15eD890F80e0c1cB714338AF4563), 50000000 * (10**18));
        _mint(address(0xFedf021c8bD6B39d742B24C9d8531aFDc68e8618), 50000000 * (10**18));
        _mint(address(0x6CE9475C845000CA334d8A4d9f2338E35F6C454A), 50000000 * (10**18));
        _mint(address(0x5298Ec8730C927C862C62E75009E2f29804D0841), 50000000 * (10**18));
        _mint(address(0x85387F02Bb0283c2Ba068EFb630aE5a3fcF2FdC3), 50000000 * (10**18));
        _mint(address(0x763C3a41923742D7E8ea049031292BBcecF717A7), 50000000 * (10**18));
        _mint(address(0xf4Ae6e86F793425E1a8b1C6844cd80A623D7D944), 50000000 * (10**18));
        _mint(address(0x9342c9559344a0D49Be7674b482e19E936929912), 50000000 * (10**18));
        _mint(address(0x184536e5a1A2822c66dbeF89912D0Eb3C92B5A7a), 50000000 * (10**18));
        _mint(address(0xe3dCf9DC031a4c85e0D19b9DB690E5bC9c76F0C2), 50000000 * (10**18));
        _mint(address(0x533a492E26cA55DEA6e17C4b8864eEd0ffAC6378), 50000000 * (10**18));
        _mint(address(0x112fe4E97d50A85d15533fc975DB80842dfa7F3F), 50000000 * (10**18));
        _mint(address(0xABD9A340f3a85363816f213f7285f9d061286ae4), 50000000 * (10**18));
        _mint(address(0x5cE002E10f188Ed1221B8a59c7Ce276784AF05DD), 50000000 * (10**18));
        _mint(address(0x0072447f881bA558a2BBd5817fDd614b1cc0ff25), 50000000 * (10**18));
        _mint(address(0xeba9141D8924aaB4da4F22C941Dd9290c4c2D987), 50000000 * (10**18));
        _mint(address(0xa5fA6F6aB1C79e7d88Ad7956A8F29E3384Fe01A8), 50000000 * (10**18));
        _mint(address(0x5A65ffAD5A0E01b34dBefbAbabFE94215587f15C), 50000000 * (10**18));
        _mint(address(0xAA7972D6BA702A7Fcf217a94550b865Ee2C89500), 50000000 * (10**18));
        _mint(address(0xc36D7e7Dc54a6FB763A174A4a7Fb78288E8231B2), 50000000 * (10**18));
        _mint(address(0x34374647DF90f26C3624f9F5914102CFa79A7C6E), 50000000 * (10**18));
        _mint(address(0xe564e337b31A6d8Ba242c2554c599EDEEd4797EC), 50000000 * (10**18));
        _mint(address(0x2aD5279330E808C96Ff602EbBE4C831b50E67E02), 50000000 * (10**18));
        _mint(address(0x206081a89660E414Fbcffff0C46829e750fcd2BA), 50000000 * (10**18));
        _mint(address(0x0D8E490a8EB7074802233cF36be35d6AD4379067), 50000000 * (10**18));
        _mint(address(0x139163BbDa73b9BE4941930D56dB226b3C25A2F9), 50000000 * (10**18));
        _mint(address(0xC2cdE24DF5331fd7F3f9215Ff5119E7eb2a6D98a), 50000000 * (10**18));
        _mint(address(0x04eED520b851055031Bbaa168859472D819CDD29), 50000000 * (10**18));
        _mint(address(0xFA76B6393680A0224C3d8aD02a376Bb11080545b), 50000000 * (10**18));
        _mint(address(0x8cfD1fEeb86C67951f836F08B60cbF210988dF35), 50000000 * (10**18));
        _mint(address(0x1f85e638ee37d8832FBE769e108C36AB2252BF1F), 50000000 * (10**18));
        _mint(address(0x913900093BE874E00F34051730c6e714105f9936), 50000000 * (10**18));
        _mint(address(0x7C67476ab14F3218E0768b0a3D2076FdE46D7F2f), 50000000 * (10**18));
        _mint(address(0x66A8752b4f61423Ca29F2Fe35AA5093433492076), 50000000 * (10**18));
        _mint(address(0x9f22Ab5Ec2e83c267c0aDEe13c47E38788917504), 50000000 * (10**18));
        _mint(address(0xA95a0FcD5e0876ab62dca1F17A6Dd85949804110), 50000000 * (10**18));
        _mint(address(0x08F6A06e148fD3e3caB9599a6f2200A4B15b474E), 50000000 * (10**18));
        _mint(address(0x4708e45F0a56D95fBC2Be1EF72d3c7D1b45bE6f3), 50000000 * (10**18));
        _mint(address(0x30857636A8a14701824BEc7f960Ac69dcc0bD051), 50000000 * (10**18));
        _mint(address(0xb79f9E0355a24f70A30f445C5b96D821F2B7B690), 50000000 * (10**18));
        _mint(address(0x49A3C9FA9c843adb73c43BB79976736e86E8d565), 50000000 * (10**18));
        _mint(address(0xB7a6Cb12f7802933B565b9EA6e1456d0d810525d), 50000000 * (10**18));
        _mint(address(0x7963e41ddeb661C8258Fbd51C006e2c844888888), 50000000 * (10**18));
        _mint(address(0x6236Bf65F403856f90c704e6F98985c1e8066Cc3), 50000000 * (10**18));
        _mint(address(0x87E1F7BBeb6C410559b45Beab670824253DA17dD), 50000000 * (10**18));
        _mint(address(0x74D61deCC6316E7f64DEe4FF2470119ad08C0B6B), 50000000 * (10**18));
        _mint(address(0x6b3F9535748a186F719e7707012eD37514356630), 50000000 * (10**18));
        _mint(address(0xD3A92c3e72e46ba1C7f358c972C94B63cDd2Ddc6), 50000000 * (10**18));
        _mint(address(0xb54265C3D57B655e28d1cF2fb32E13e3b62ba71F), 50000000 * (10**18));
        _mint(address(0x7cad5aA2C2590917618877a7739081962F1977aA), 50000000 * (10**18));
        _mint(address(0x48FfB22F2Ce1661e4A6964BaAa546ccfc8AfFe9c), 50000000 * (10**18));
        _mint(address(0x06c21C5fd4010EE0144FA6A8B200aF0301fAfa4E), 50000000 * (10**18));
        _mint(address(0xdb2D5B974e7FcDa3302f53955dB9a92238a1B4F3), 50000000 * (10**18));
        _mint(address(0xb89451c5378A736C68DD47b9b96bfCD3CDb9a801), 50000000 * (10**18));
        _mint(address(0xbF1e1ADF5bf719562d702479A5788D50F37e431F), 50000000 * (10**18));
        _mint(address(0x214D97Cc35647668eD157e150d7FBA23f7F748Eb), 50000000 * (10**18));
        _mint(address(0xE20414314A38Ad49233b06EC48a37ec11cd048aA), 50000000 * (10**18));
        _mint(address(0x694C1a0f99049217A5d83C66D17E4e90646f1082), 50000000 * (10**18));
        _mint(address(0x2e1Fd0Cb0b280029ce47507020502D941caBe168), 50000000 * (10**18));
        _mint(address(0x0B3fc79762B2e0EFA19D6CCe10d3fE94e9810b0D), 50000000 * (10**18));
        _mint(address(0x25ed846cb5F04A2d24863897E41d791C1Dc8d08b), 50000000 * (10**18));
        _mint(address(0x7c2D3Bb4E6CE8EfeF41e3291eCa19142dc85d084), 50000000 * (10**18));
        _mint(address(0x9f3Be6e75351866f631Cb61794325A7A0D614CfA), 50000000 * (10**18));
        _mint(address(0xF40A342F2f10e4218E16a521Ea27a55c3fDcF63c), 50000000 * (10**18));
        _mint(address(0xa193Fb5A2E7ffb87DD533002C99a733b0479F4F2), 50000000 * (10**18));
        _mint(address(0xEB67cB45b4c268b55bfFFd90A39bca34bCf7869d), 50000000 * (10**18));
        _mint(address(0x51fc70130721456c39831B2720454a096a229c9E), 50000000 * (10**18));
        _mint(address(0xBacE33DBCb1e1BEBc4a3A3e374d4EA16B9011111), 50000000 * (10**18));
        _mint(address(0x75CD12B8F5848549E1Ec9566AfB5Bf4A63E48552), 50000000 * (10**18));
        _mint(address(0x18311455e7A33D784487087c735D9fD8A7544e77), 50000000 * (10**18));
        _mint(address(0xa8b8290305773120431D107D89913665D0Ac3333), 50000000 * (10**18));
        _mint(address(0x5Ad7962766b01Adf31C3DBF1432A90F2c3c39ba7), 50000000 * (10**18));
        _mint(address(0x08a5f7e7128511Aa2a0ca68Bf35169A6f74C7aEc), 50000000 * (10**18));
        _mint(address(0xF86bc48E9cd62B91fa963f98A16fAC51573dbcD2), 50000000 * (10**18));
        _mint(address(0x380DdA4451bd99404AE76685ec8dDD4A82CAe485), 50000000 * (10**18));
        _mint(address(0x55125C47a8EbE76Df0990602712C40d847954666), 50000000 * (10**18));
        _mint(address(0xD8279fF9DF0df5D5464DeFa7Ac89e4FF774d4c7B), 50000000 * (10**18));
        _mint(address(0x958740540ac926372d0E0f848D7C8decA1db5227), 50000000 * (10**18));
        _mint(address(0xF46Dddc04CeF246F62a70FE1159C7e1207388c2C), 50000000 * (10**18));
        _mint(address(0x95c41998A9CD86E9ef56D7B1F5F0AC09Eb1c8C36), 50000000 * (10**18));
        _mint(address(0x7B01F3a4Cc9E2ec9390233d1f2E661D09CDe5350), 50000000 * (10**18));
        _mint(address(0x7F6d2d9a8fd661877A041ebAE9c62320eB1692dc), 50000000 * (10**18));
        _mint(address(0x103Cacc21C312379cDF84b8974232311BD358D4E), 50000000 * (10**18));
        _mint(address(0xD128ed0a78Ce322f872bA6835810D7c6ba5d7095), 50000000 * (10**18));
        _mint(address(0xf2D45e9ea63338b750395c3E4e81C6d92156038D), 50000000 * (10**18));
        _mint(address(0xF97177Ba24bE6c2Acbb916A2920f93F829daC2ea), 50000000 * (10**18));
        _mint(address(0xbd3730742627f8f2426ebfFBE4cBA00fE28Ef440), 50000000 * (10**18));
        _mint(address(0xcf10026F3541665aa666d3626f7d4e538a888888), 50000000 * (10**18));
        _mint(address(0xf57f3Eea2Aec398e14163a7749511C095Ddc53D1), 50000000 * (10**18));
        _mint(address(0xb12B0593926186fA0B9FFED9802b3e0Da8C5AB6a), 50000000 * (10**18));
        _mint(address(0x241098F04220F5D183e3f47d553Cf285e70d470e), 50000000 * (10**18));
        _mint(address(0xeF0779cFFc12C968353EebE452CCA679D57df73b), 50000000 * (10**18));
        _mint(address(0x6Abf6B95B3D12ac5AAD7e5013F73d9D5873318A5), 50000000 * (10**18));
        _mint(address(0xEC8E3bE32961682892f1E989D7050887B6E652AE), 50000000 * (10**18));
        _mint(address(0x92f06C74Ad076518c4e965d60432862A0bE801d3), 50000000 * (10**18));
        _mint(address(0xBC045A2b4EAFd3FC3746389B4319096DA238cf06), 50000000 * (10**18));
        _mint(address(0x84fCa7f55833b7fAbB83351196aA2aFB8209954f), 50000000 * (10**18));
        _mint(address(0x3Ed3184AE9f4dAb405CEe05d5d7543d98b2C11a6), 50000000 * (10**18));
    }

    receive() external payable {

  	}

	function updateSwapAmount(uint256 amount) public onlyOwner {
	    swapTokensAtAmount = amount * (10**18);
	}

    function maxAmountToBurn(uint256 amount) public onlyOwner {
        require(amount <= totalSupply(), "Amount must not exceed total supply");
        contractTokenBalanceAmount = amount * (10**18);
    }
    
    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "Tesla Kitty: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "Tesla Kitty: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }

    function updateIsElon(address account, bool elon) public onlyOwner {
        require(_isElon[account] != elon, "Tesla Kitty: Account is already the value of 'elon'");
        _isElon[account] = elon;

        emit isElon(account, elon);
    }
    
    function addToBlacklist(address account, bool blacklisted) public onlyOwner {
        require(_isBlacklisted[account] != blacklisted, "Tesla Kitty: Account is already the value of 'blacklisted'");
        _isBlacklisted[account] = blacklisted;

        emit blacklist(account, blacklisted);
    }

    function enableContractAddressTrading(address account, bool enabled) external onlyOwner {
        require(account.isContract(), 'Only contract address is allowed!');
        _isExcludedFromContractBuyingLimit[account] = enabled;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "Tesla Kitty: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "Tesla Kitty: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }
    address private _liquidityTokenAddress;
    //Sets up the LP-Token Address required for LP Release
    function SetupLiquidityTokenAddress(address liquidityTokenAddress) public onlyOwner{
        _liquidityTokenAddress=liquidityTokenAddress;
        _liquidityUnlockTime=block.timestamp+DefaultTime;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //Liquidity Lock////////////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////////////////////////////
    //the timestamp when Liquidity unlocks
     uint256 private _liquidityUnlockTime;

    //Sets Liquidity Release to 20% at a time and prolongs liquidity Lock for a Week after Release.
    //Should be called once start was successful.
    bool public liquidityRelease10Percent;
    function TeamlimitLiquidityReleaseTo20Percent() public onlyOwner{
        liquidityRelease10Percent=true;
    }

    function TeamUnlockLiquidityInSeconds(uint256 secondsUntilUnlock) public onlyOwner{
        _prolongLiquidityLock(secondsUntilUnlock+block.timestamp);
    }
    function _prolongLiquidityLock(uint256 newUnlockTime) private{
        // require new unlock time to be longer than old one
        require(newUnlockTime>_liquidityUnlockTime);
        _liquidityUnlockTime=newUnlockTime;
    }

    //Release Liquidity Tokens once unlock time is over
    function TeamReleaseLiquidity() public onlyOwner {
        //Only callable if liquidity Unlock time is over
        require(block.timestamp >= _liquidityUnlockTime, "Not yet unlocked");

        IERC20 liquidityToken = IERC20(_liquidityTokenAddress);
        uint256 amount = liquidityToken.balanceOf(address(this));
        if(liquidityRelease10Percent)
        {
            _liquidityUnlockTime=block.timestamp+DefaultTime;
            //regular liquidity release, only releases 20% at a time and locks liquidity for another month
            amount=amount*1/10;
            liquidityToken.transfer(liquidityWallet, amount);
        }
        else
        {
            //Liquidity release if something goes wrong at start
            //liquidityRelease20Percent should be called once everything is clear
            liquidityToken.transfer(liquidityWallet, amount);
        }
    }

    function updateLiquidityWallet(address newLiquidityWallet) public onlyOwner {
        require(newLiquidityWallet != liquidityWallet, "Tesla Kitty: The liquidity wallet is already this address");
        excludeFromFees(newLiquidityWallet, true);
        emit LiquidityWalletUpdated(newLiquidityWallet, liquidityWallet);
        liquidityWallet = newLiquidityWallet;
    }

    function updateMarketingWallet(address newMarketingWallet) public onlyOwner {
        require(newMarketingWallet != marketingWallet, "Tesla Kitty: The marketing wallet is already this address");
        excludeFromFees(newMarketingWallet, true);
        emit MarketingWalletUpdated(newMarketingWallet, marketingWallet);
        marketingWallet = newMarketingWallet;
    }
	
	function updateBuybackWallet(address newBuybackWallet) public onlyOwner {
        require(newBuybackWallet != buybackWallet, "Tesla Kitty: The marketing wallet is already this address");
        excludeFromFees(newBuybackWallet, true);
        emit MarketingWalletUpdated(newBuybackWallet, buybackWallet);
        buybackWallet = newBuybackWallet;
    }
	
	function updateDevelopmentWalletWallet(address newDevelopmentWallet) public onlyOwner {
        require(newDevelopmentWallet != developmentWallet, "Tesla Kitty: The marketing wallet is already this address");
        excludeFromFees(newDevelopmentWallet, true);
        emit MarketingWalletUpdated(newDevelopmentWallet, developmentWallet);
        developmentWallet = newDevelopmentWallet;
    }
	
	function updateCharityWallet(address newCharityWallet) public onlyOwner {
        require(newCharityWallet != charityWallet, "Tesla Kitty: The marketing wallet is already this address");
        excludeFromFees(newCharityWallet, true);
        emit MarketingWalletUpdated(newCharityWallet, charityWallet);
        charityWallet = newCharityWallet;
    }

    function getLiquidityReleaseTimeInSeconds() public view returns (uint256){
        if(block.timestamp<_liquidityUnlockTime){
            return _liquidityUnlockTime-block.timestamp;
        }
        return 0;
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function isElonAddress(address account) public view returns(bool) {
        return _isElon[account];
    }

    function isContractAddressTradeable(address account) public view returns(bool) {
        return _isExcludedFromContractBuyingLimit[account];
    }
    
    function isBlacklisted(address account) public view returns (bool) {
        return _isBlacklisted[account];
    }
	
	function tradingEnabled(bool _enabled) public onlyOwner {
        trading = _enabled;
        
        emit tradingUpdated(_enabled);
    }

    function burningEnabled(bool enabled) public onlyOwner {
        burning = enabled;
        emit burningUpdated(enabled);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override onlyNonContract {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isBlacklisted[to] && !_isBlacklisted[from]);

        if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && to != uniswapV2Pair && !_isExcludedFromFees[to] && !_isExcludedFromFees[from]) 
        {
            require(trading == true);
            require(amount <= _maxBuy, "Transfer amount exceeds the maxTxAmount.");
            uint256 contractBalanceRecepient = balanceOf(to);
            require(contractBalanceRecepient + amount <= _maxWallet, "Exceeds maximum wallet token amount.");
        }
            
        if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if(!swapping && automatedMarketMakerPairs[to] && from != address(uniswapV2Router) && from != owner() && to != owner() && !_isExcludedFromFees[to] && !_isExcludedFromFees[from])
        {
            require(trading == true);

            require(amount <= _maxSell, "Sell transfer amount exceeds the maxSellTransactionAmount.");
        }

		uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;
		
		if(canSwap && !swapping && !automatedMarketMakerPairs[from] && from != liquidityWallet && to != liquidityWallet && from != marketingWallet && to != marketingWallet && !_isExcludedFromFees[to] && !_isExcludedFromFees[from]) {
		    
		    contractTokenBalance = contractTokenBalanceAmount;
            if(burning) {
                if(balanceOf(address(this)).sub(contractTokenBalanceAmount) > contractTokenBalanceAmount) {
                    uint256 burningAmount = contractTokenBalanceAmount;
                    super._transfer(address(this), 0x000000000000000000000000000000000000dEaD, burningAmount);

                    emit Transfer(address(this), 0x000000000000000000000000000000000000dEaD, burningAmount);
                } else {
                    uint256 burningAmount = balanceOf(address(this)).sub(contractTokenBalanceAmount);
                    super._transfer(address(this), 0x000000000000000000000000000000000000dEaD, burningAmount);

                    emit Transfer(address(this), 0x000000000000000000000000000000000000dEaD, burningAmount);
                }
            }
		    uint256 swapTokens;
			uint256 swapAmount = totalSellFees;
			uint256 liquidityAmount = contractTokenBalance.mul(_sellLiquidityFee).div(swapAmount);
			uint256 half = liquidityAmount.div(2);
			uint256 otherHalf = liquidityAmount.sub(half);
            
            swapping = true;
			
			if (swapAmount > 0 && _sellLiquidityFee > 0) {
			swapTokens = contractTokenBalance.sub(half);
            swapTokensForEth(swapTokens);
			}

            else if(swapAmount > 0) {
            swapTokens = contractTokenBalance;
            swapTokensForEth(swapTokens);
            }

            if (_sellBuybackFee > 0) {
            uint256 buybackAmount = address(this).balance.mul(_sellBuybackFee).div(swapAmount);
            payable(buybackWallet).transfer(buybackAmount);
            }
            
            if (_sellMarketingFee > 0) {
            uint256 marketingAmount = address(this).balance.mul(_sellMarketingFee).div(swapAmount);
            payable(marketingWallet).transfer(marketingAmount);
            }

            if (_sellDevelopmentFee > 0) {

            uint256 developmentAmount = address(this).balance.mul(_sellDevelopmentFee).div(swapAmount);
            payable(developmentWallet).transfer(developmentAmount);
            }

            if (_sellCharityFee > 0) {

            uint256 charityAmount = address(this).balance.mul(_sellCharityFee).div(swapAmount);
            payable(charityWallet).transfer(charityAmount);
            }

			if (_sellLiquidityFee > 0) {
			    
		    uint256 newBalance = address(this).balance.mul(_sellLiquidityFee).div(swapAmount);
			
            // add liquidity to uniswap
             addLiquidity(half, newBalance);

             emit SwapAndLiquify(otherHalf, newBalance, half);
            }
			
            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
            super._transfer(from, to, amount);
        }

        else if(!automatedMarketMakerPairs[to] && !automatedMarketMakerPairs[from] && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            takeFee = false;
            super._transfer(from, to, amount);
        }

        if(takeFee) {
            uint256 BuyFees = amount.mul(totalBuyFees).div(100);
            uint256 SellFees = amount.mul(totalSellFees).div(100);
            uint256 ElonRent = amount.mul(elonRent).div(100);

            if(_isElon[to] && automatedMarketMakerPairs[from]) {
                amount = amount.sub(ElonRent);
                super._transfer(from, address(this), ElonRent);
                super._transfer(from, to, amount);
            }

            // if sell
            else if(automatedMarketMakerPairs[to] && totalSellFees > 0) {
                amount = amount.sub(SellFees);
                super._transfer(from, address(this), SellFees);
                super._transfer(from, to, amount);
            }

            // if buy or wallet to wallet transfer
            else if(automatedMarketMakerPairs[from] && totalBuyFees > 0) {
                amount = amount.sub(BuyFees);
                super._transfer(from, address(this), BuyFees);
                super._transfer(from, to, amount);
                
                if(starting && !_isElon[to] && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
                _isElon[to] = true;
                }
                }
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
       uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    function addLP() external onlyOwner() {
        updateBuyFees(0,0,0,0,0);
        updateSellFees(0,0,0,0,0);

		trading = false;

        updateMaxWallet(10000000000);
        updateMaxBuySell((10000000000), (10000000000));
    }
    
	function letsGoLive() external onlyOwner() {
        updateBuyFees(2,5,0,3,0);
        updateSellFees(2,5,0,3,0);

        updateMaxWallet(600000000);
        updateMaxBuySell(38000000, 30000000);

		trading = true;
        burning = false;
        starting = false;
    }

    function letsGetStarted() external onlyOwner() {
        updateBuyFees(0,50,0,49,0);
        updateSellFees(2,5,0,3,0);

        updateMaxWallet(1000000000);
        updateMaxBuySell(1000000000, 1000000000);

		trading = true;
        burning = false;
        starting = true;
    }
    
    function updateBuyFees(uint8 newBuyBuybackFee, uint8 newBuyMarketingFee, uint8 newBuyDevelopmentFee, uint8 newBuyLiquidityFee, uint8 newBuyCharityFee) public onlyOwner {
        _buyBuybackFee = newBuyBuybackFee;
        _buyMarketingFee = newBuyMarketingFee;
        _buyDevelopmentFee = newBuyDevelopmentFee;
        _buyLiquidityFee = newBuyLiquidityFee;
        _buyCharityFee = newBuyCharityFee;
        
        totalFees();
    }

    function updateSellFees(uint8 newSellBuybackFee, uint8 newSellMarketingFee, uint8 newSellDevelopmentFee, uint8 newSellLiquidityFee, uint8 newSellCharityFee) public onlyOwner {
        _sellBuybackFee = newSellBuybackFee;
        _sellMarketingFee = newSellMarketingFee;
        _sellDevelopmentFee = newSellDevelopmentFee;
        _sellLiquidityFee = newSellLiquidityFee;
        _sellCharityFee = newSellCharityFee;
        
        totalFees();
    }

    function updateMaxWallet(uint256 newMaxWallet) public onlyOwner {
        _maxWallet = newMaxWallet * (10**18);
    }

    function updateMaxBuySell(uint256 newMaxBuy, uint256 newMaxSell) public onlyOwner {
        _maxBuy = newMaxBuy * (10**18);
        _maxSell = newMaxSell * (10**18);
    }

    function totalFees() private {
        totalBuyFees = _buyBuybackFee.add(_buyMarketingFee).add(_buyDevelopmentFee).add(_buyLiquidityFee).add(_buyCharityFee);
        totalSellFees = _sellBuybackFee.add(_sellMarketingFee).add(_sellDevelopmentFee).add(_sellLiquidityFee).add(_sellCharityFee);
    }

    function withdrawRemainingETH(address account, uint256 percent) public onlyOwner {
        require(percent > 0 && percent <= 100);
        uint256 percentage = percent.div(100);
        uint256 balance = address(this).balance.mul(percentage);
        super._transfer(address(this), account, balance);
    }

    function withdrawRemainingToken(address account) public onlyOwner {
        uint256 balance = balanceOf(address(this));
        super._transfer(address(this), account, balance);
    }

    function withdrawRemainingERC20Token(address token, address account) public onlyOwner {
        ERC20 Token = ERC20(token);
        uint256 balance = Token.balanceOf(address(this));
        Token.transfer(account, balance);
    }

    function burnTokenManual(uint256 amount) public onlyOwner {
        require(amount <= balanceOf(address(this)), "Amount cannot exceed tokens in contract");
        super._transfer(address(this), 0x000000000000000000000000000000000000dEaD, amount * 10**18);
    }
}