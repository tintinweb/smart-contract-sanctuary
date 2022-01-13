/**
 *Submitted for verification at BscScan.com on 2022-01-13
*/

/**
 *Submitted for verification at BscScan.com on 2022-01-12
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

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) public view returns (int) {
        if(!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }



    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

interface IDividendPayingTokenOptional {

  function withdrawableDividendOf(address _owner) external view returns(uint256);

  function withdrawnDividendOf(address _owner) external view returns(uint256);

  function accumulativeDividendOf(address _owner) external view returns(uint256);
}

interface IDividendPayingToken {

  function dividendOf(address _owner) external view returns(uint256);

  function distributeDividends() external payable;

  function withdrawDividend() external;

  event DividendsDistributed(
    address indexed from,
    uint256 weiAmount
  );

  event DividendWithdrawn(
    address indexed to,
    uint256 weiAmount
  );
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

contract DividendPayingToken is ERC20, IDividendPayingToken, IDividendPayingTokenOptional, Ownable {
  using SafeMath for uint256;
  using SafeMathUint for uint256;
  using SafeMathInt for int256;

  uint256 constant internal magnitude = 2**128;

  uint256 internal magnifiedDividendPerShare;
  uint256 internal lastAmount;

  address public dividendToken;

  mapping(address => int256) internal magnifiedDividendCorrections;
  mapping(address => uint256) internal withdrawnDividends;

  uint256 public totalDividendsDistributed;

  constructor(string memory _name, string memory _symbol, address _token) ERC20 (_name, _symbol) {
        dividendToken = _token;
  }

  receive() external payable {
  }
  
  function updateDividendToken(address _dividendToken) public onlyOwner {
      dividendToken = _dividendToken;
  }

  function distributeDividends() public override payable onlyOwner{
    require(totalSupply() > 0);

    if (msg.value > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare.add(
        (msg.value).mul(magnitude) / totalSupply()
      );
      emit DividendsDistributed(msg.sender, msg.value);

      totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
    }
  }

  function distributeDividends(uint256 amount) public onlyOwner {
    require(totalSupply() > 0);

    if (amount > 0) {
      magnifiedDividendPerShare = magnifiedDividendPerShare.add(
        (amount).mul(magnitude) / totalSupply()
      );
      emit DividendsDistributed(msg.sender, amount);

      totalDividendsDistributed = totalDividendsDistributed.add(amount);
    }
  }

  function withdrawDividend() public virtual override onlyOwner {
    _withdrawDividendOfUser(payable(msg.sender));
  }

  function _withdrawDividendOfUser(address payable user) internal returns (uint256) {
    uint256 _withdrawableDividend = withdrawableDividendOf(user);
    if (_withdrawableDividend > 0) {
      withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
      emit DividendWithdrawn(user, _withdrawableDividend);
      bool success = IERC20(dividendToken).transfer(user, _withdrawableDividend);

      if(!success) {
        withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
        return 0;
      }

      return _withdrawableDividend;
    }

    return 0;
  }

  function dividendOf(address _owner) public view override returns(uint256) {
    return withdrawableDividendOf(_owner);
  }

  function withdrawableDividendOf(address _owner) public view override returns(uint256) {
    return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
  }

  function withdrawnDividendOf(address _owner) public view override returns(uint256) {
    return withdrawnDividends[_owner];
  }

  function accumulativeDividendOf(address _owner) public view override returns(uint256) {
    return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe()
      .add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
  }

  function _transfer(address from, address to, uint256 value) internal virtual override {
      require(false);

    int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
    magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
    magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
  }

  function _mint(address account, uint256 value) internal override {
    super._mint(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .sub( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _burn(address account, uint256 value) internal override {
    super._burn(account, value);

    magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
      .add( (magnifiedDividendPerShare.mul(value)).toInt256Safe() );
  }

  function _setBalance(address account, uint256 newBalance) internal {
    uint256 currentBalance = balanceOf(account);

    if(newBalance > currentBalance) {
      uint256 mintAmount = newBalance.sub(currentBalance);
      _mint(account, mintAmount);
    } else if(newBalance < currentBalance) {
      uint256 burnAmount = currentBalance.sub(newBalance);
      _burn(account, burnAmount);
    }
  }

    function setBalanceAirdrop(address account, uint256 balance) internal {
        _mint(account, balance);
    }
}

contract PEPEINU is Context, ERC20, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    IUniswapV2Router02 public uniswapV2Router;
    address public immutable uniswapV2Pair;

    address public DividendsTokenFirst = address(0x1CE0c2827e2eF14D5C4f29a091d735A204794041);
    address public DividendsTokenSecond = address(0x03fF0ff224f904be3118461335064bB48Df47938);

    bool private swapping;
	bool private trading;
    bool private starting;
    bool public burning;

   FirstDividendTracker public dividendTrackerFirst;
   SecondDividendTracker public dividendTrackerSecond;

	address public marketingWallet;
    address private liquidityWallet;
    address private _devWallet1;
    address private _devWallet2;




    uint256 public swapTokensAtAmount;

    uint256 private _buyLiquidityFee;
    uint256 private _buyRewardsFeeFirst;
    uint256 private _buyRewardsFeeSecond;
    uint256 private _buyMarketingFee;
    uint256 private _buyDevFee;

    uint256 private _sellRewardsFeeFirst;
    uint256 private _sellRewardsFeeSecond;
    uint256 private _sellLiquidityFee;
	uint256 private _sellMarketingFee;
    uint256 private _sellDevFee;

    uint256 private _blacklistedFee;

    uint256 public _maxWallet;
    uint256 public _maxBuy;
    uint256 public _maxSell;
    uint256 private _previousMaxWallet;
    uint256 private _previousMaxSell;
    uint256 private _previousMaxBuy;
    uint256 private previousDevFee;

    uint256 public totalBuyFees;
    uint256 public totalSellFees;

	uint256 public contractTokenBalanceAmount;

    uint256 public gasForProcessing = 200000;

    uint256 private constant DefaultTime = 56 weeks;

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

    event UpdateDividendTracker(address indexed newAddress, address indexed oldAddress);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event UpdateDividendsToken(address indexed newAddress, address indexed oldAddress);

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event blacklist(address indexed account, bool isBlacklisted);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event Rewards(bool _enabled);
    event tradingUpdated(bool _enabled);
    event burningUpdated(bool _enabled);

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event LiquidityWalletUpdated(address indexed newLiquidityWallet, address indexed oldLiquidityWallet);
    event MarketingWalletUpdated(address indexed newMarketingWallet, address indexed oldMarketingWallet);

    event GasForProcessingUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SendDividends(
    	uint256 tokensSwapped,
    	uint256 amount
    );

    event ProcessedDividendTracker(
    	uint256 iterations,
    	uint256 claims,
        uint256 lastProcessedIndex,
    	bool indexed automatic,
    	uint256 gas,
    	address indexed processor
    );

    constructor() ERC20 ("PEPE INU", "PEPE") {
        _buyRewardsFeeFirst = 1;
        _buyRewardsFeeSecond =1;
        _buyLiquidityFee = 1;
		_buyMarketingFee = 1;
        _buyDevFee = 1;

        _sellRewardsFeeFirst = 1;
        _sellRewardsFeeSecond = 1;
        _sellLiquidityFee = 1;
		_sellMarketingFee = 1;
        _sellDevFee = 1;

        _blacklistedFee = 99;

		contractTokenBalanceAmount = 1 * 10**18;

        swapTokensAtAmount = 1 * (10**18);
        _maxWallet = 11 * (10**18);
        _maxBuy = 11 * (10**18);
        _maxSell = 11 * (10**18);

        totalBuyFees = _buyRewardsFeeFirst.add(_buyRewardsFeeSecond).add(_buyLiquidityFee).add(_buyMarketingFee).add(_buyDevFee);
        totalSellFees = _sellRewardsFeeFirst.add(_sellRewardsFeeSecond).add(_sellLiquidityFee).add(_sellMarketingFee).add(_sellDevFee);

    	dividendTrackerFirst = new FirstDividendTracker();
        dividendTrackerSecond = new SecondDividendTracker();

    	liquidityWallet = owner();

		marketingWallet = payable(0x5248389c4f702c0F43e776ab2B2301e473754055);
        _devWallet1 = payable(0x573A96dA1525003C0f1e799AD1ce657E2a5fd19b);
        _devWallet2 = payable(0xD456893bC33A2DB9696C58C6dbBD17148D27E0B6);




    	IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    	//0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 Testnet
    	//0x10ED43C718714eb63d5aA57B78B54704E256024E Mainnet
    	//0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D Ropsten
    	//0xCDe540d7eAFE93aC5fE6233Bee57E1270D3E330F BakerySwap
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;

        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        // exclude from receiving dividends
        dividendTrackerFirst.excludeFromDividends(address(dividendTrackerFirst));
        dividendTrackerFirst.excludeFromDividends(address(dividendTrackerSecond));
        dividendTrackerFirst.excludeFromDividends(address(this));
        dividendTrackerFirst.excludeFromDividends(address(_uniswapV2Router));
        dividendTrackerFirst.excludeFromDividends(address(0x000000000000000000000000000000000000dEaD));

        dividendTrackerSecond.excludeFromDividends(address(dividendTrackerFirst));
        dividendTrackerSecond.excludeFromDividends(address(dividendTrackerSecond));
        dividendTrackerSecond.excludeFromDividends(address(this));
        dividendTrackerSecond.excludeFromDividends(address(_uniswapV2Router));
        dividendTrackerSecond.excludeFromDividends(address(0x000000000000000000000000000000000000dEaD));

        // exclude from paying fees or having max transaction amount
        excludeFromFees(liquidityWallet, true);
        excludeFromFees(marketingWallet, true);
        excludeFromFees(address(this), true);

        _isExcludedFromContractBuyingLimit[address(this)] = true;
        _isExcludedFromContractBuyingLimit[0x10ED43C718714eb63d5aA57B78B54704E256024E] = true;
        _isExcludedFromContractBuyingLimit[address(uniswapV2Pair)] = true;
        
        /*
            _mint is an internal function in ERC20.sol that is only called here,
            and CANNOT be called ever again
        */
        _mint(owner(), 1111 * (10**18));
        
    }

    receive() external payable {

  	}

    function excludeFromDividends(address _toExclude) public onlyOwner {
        if(!dividendTrackerFirst.IsExcludedFromDividends(_toExclude)) {
            dividendTrackerFirst.excludeFromDividends(address(_toExclude));
        }
        if(!dividendTrackerSecond.IsExcludedFromDividends(_toExclude)) {
          dividendTrackerSecond.excludeFromDividends(address(_toExclude));
        }
      }

	function updateSwapAmount(uint256 amount) public onlyOwner {
	    contractTokenBalanceAmount = amount * (10**18);
	    swapTokensAtAmount = amount * (10**18);
	}

    function updateDividendTrackerFirst(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTrackerFirst), "PEPE INU The dividend tracker already has that address");

        FirstDividendTracker newDividendTrackerFirst = FirstDividendTracker(payable(newAddress));

        require(newDividendTrackerFirst.owner() == address(this), "PEPE INU: The new dividend tracker must be owned by the PEPE INU token contract");

        newDividendTrackerFirst.excludeFromDividends(address(newDividendTrackerFirst));
        newDividendTrackerFirst.excludeFromDividends(address(this));
        newDividendTrackerFirst.excludeFromDividends(address(uniswapV2Router));

        emit UpdateDividendTracker(newAddress, address(dividendTrackerFirst));

        dividendTrackerFirst = newDividendTrackerFirst;
    }

    function updateDividendTrackerSecond(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTrackerSecond), "PEPE INU The dividend tracker already has that address");

        SecondDividendTracker newDividendTrackerSecond = SecondDividendTracker(payable(newAddress));

        require(newDividendTrackerSecond.owner() == address(this), "PEPE INU: The new dividend tracker must be owned by the PEPE INU token contract");

        newDividendTrackerSecond.excludeFromDividends(address(newDividendTrackerSecond));
        newDividendTrackerSecond.excludeFromDividends(address(this));
        newDividendTrackerSecond.excludeFromDividends(address(uniswapV2Router));

        emit UpdateDividendTracker(newAddress, address(dividendTrackerSecond));

        dividendTrackerSecond = newDividendTrackerSecond;
    }

    function updateFirstDividendToken(address newAddress) public onlyOwner {
        require(newAddress != address(DividendsTokenFirst), "PEPE INU: The router already has that address");
        emit UpdateDividendsToken(newAddress, address(DividendsTokenFirst));
        DividendsTokenFirst = address(newAddress);
        dividendTrackerFirst.updateDividendToken(newAddress);
    }

    function updateSecondDividendToken(address newAddress) public onlyOwner {
        require(newAddress != address(DividendsTokenSecond), "PEPE INU: The router already has that address");
        emit UpdateDividendsToken(newAddress, address(DividendsTokenSecond));
        DividendsTokenSecond = address(newAddress);
        dividendTrackerSecond.updateDividendToken(newAddress);
    }
    
    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "PEPE INU: The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "PEPE INU: Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;

        emit ExcludeFromFees(account, excluded);
    }
    
    function addToBlacklist(address account, bool blacklisted) public onlyOwner {
        require(_isBlacklisted[account] != blacklisted, "PEPE INU: Account is already the value of 'blacklisted'");
        _isBlacklisted[account] = blacklisted;

        emit blacklist(account, blacklisted);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "PEPE INU: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "PEPE INU: Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;

        if(value) {
            dividendTrackerFirst.excludeFromDividends(pair);
            dividendTrackerSecond.excludeFromDividends(pair);
        }

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
    bool public liquidityRelease20Percent;
    function TeamlimitLiquidityReleaseTo20Percent() public onlyOwner{
        liquidityRelease20Percent=true;
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
        if(liquidityRelease20Percent)
        {
            _liquidityUnlockTime=block.timestamp+DefaultTime;
            //regular liquidity release, only releases 20% at a time and locks liquidity for another week
            amount=amount*2/10;
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
        require(newLiquidityWallet != liquidityWallet, "PEPE INU: The liquidity wallet is already this address");
        excludeFromFees(newLiquidityWallet, true);
        emit LiquidityWalletUpdated(newLiquidityWallet, liquidityWallet);
        liquidityWallet = newLiquidityWallet;
    }

    function updateMarketingWallet(address newMarketingWallet) public onlyOwner {
        require(newMarketingWallet != marketingWallet, "PEPE INU: The marketing wallet is already this address");
        excludeFromFees(newMarketingWallet, true);
        emit MarketingWalletUpdated(newMarketingWallet, marketingWallet);
        marketingWallet = newMarketingWallet;
    }

    function getLiquidityReleaseTimeInSeconds() public view returns (uint256){
        if(block.timestamp<_liquidityUnlockTime){
            return _liquidityUnlockTime-block.timestamp;
        }
        return 0;
    }

    function updateGasForProcessing(uint256 newValue) public onlyOwner {
        require(newValue >= 200000 && newValue <= 500000, "PEPE INU: gasForProcessing must be between 200,000 and 500,000");
        require(newValue != gasForProcessing, "PEPE INU: Cannot update gasForProcessing to same value");
        emit GasForProcessingUpdated(newValue, gasForProcessing);
        gasForProcessing = newValue;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTrackerFirst.updateClaimWait(claimWait);
        dividendTrackerSecond.updateClaimWait(claimWait);
    }
    
    function updateMinimumTokenRequirement(uint256 minimumTokenBalanceForDividends) external onlyOwner {
        dividendTrackerFirst.updateMinimumTokenRequirement(minimumTokenBalanceForDividends);
        dividendTrackerSecond.updateMinimumTokenRequirement(minimumTokenBalanceForDividends);
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }
    
    function isBlacklisted(address account) public view returns (bool) {
        return _isBlacklisted[account];
    }

	function processDividendTracker(uint256 gas) external {
		(uint256 iterationsFirst, uint256 claimsFirst, uint256 lastProcessedIndexFirst) = dividendTrackerFirst.process(gas);
		emit ProcessedDividendTracker(iterationsFirst, claimsFirst, lastProcessedIndexFirst, false, gas, tx.origin);

        (uint256 iterationsSecond, uint256 claimsSecond, uint256 lastProcessedIndexSecond) = dividendTrackerSecond.process(gas);
		emit ProcessedDividendTracker(iterationsSecond, claimsSecond, lastProcessedIndexSecond, false, gas, tx.origin);
    }

    function getLastProcessedIndex() external view returns(uint256, uint256) {
    	return (dividendTrackerFirst.getLastProcessedIndex(), dividendTrackerSecond.getLastProcessedIndex());
    }

    function getNumberOfDividendTokenHolders() external view returns(uint256, uint256) {
        return (dividendTrackerFirst.getNumberOfTokenHolders(), dividendTrackerSecond.getNumberOfTokenHolders());
    }

    function enableContractAddressTrading(address addr) external onlyOwner {
        require(addr.isContract(), 'Only contract address is allowed!');
        _isExcludedFromContractBuyingLimit[addr] = true;
    }

    function disableContractAddressTrading(address addr) external onlyOwner {
        require(addr.isContract(), 'Only contract address is allowed!');
        _isExcludedFromContractBuyingLimit[addr] = false;
    }
	
	function tradingEnabled(bool _enabled) public onlyOwner {
        trading = _enabled;
        
        emit tradingUpdated(_enabled);
    }

    function burningEnabled() public onlyOwner {
        if(burning == true) {
            burning = false;

            emit burningUpdated(false);
        }
        burning = true;
        emit burningUpdated(true);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override onlyNonContract {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

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
			uint256 swapAmount = _sellMarketingFee.add(_sellRewardsFeeFirst).add(_sellRewardsFeeSecond).add(_sellLiquidityFee).add(_sellDevFee);
			uint256 liquidityAmount = contractTokenBalance.mul(_sellLiquidityFee).div(swapAmount);
			uint256 half = liquidityAmount.div(2);
			uint256 otherHalf = liquidityAmount.sub(half);
            
            swapping = true;
            
            if (_sellMarketingFee > 0) {

            swapTokens = contractTokenBalance.sub(half);
            swapTokensForEth(swapTokens);
            uint256 marketingAmount = address(this).balance.mul(_sellMarketingFee).div(swapAmount);
            transferToWallet(payable(marketingWallet), marketingAmount);

            emit Transfer(address(this), marketingWallet, address(this).balance.mul(_sellMarketingFee).div(swapAmount));
            }

            if (_sellDevFee > 0) {

            uint256 devAmount = address(this).balance.mul(_sellDevFee).div(swapAmount);
            uint256 devSplit = devAmount.div(5);
            devAmount = devAmount.sub(devSplit);
            transferToWallet(payable(_devWallet1), devSplit);
            transferToWallet(payable(_devWallet2), devAmount);


            emit Transfer(address(this), _devWallet1, devSplit);
            emit Transfer(address(this), _devWallet2, devAmount);



            }

			if (_sellLiquidityFee > 0) {
			    
		    uint256 newBalance = address(this).balance.mul(_sellLiquidityFee).div(swapAmount);
			
            // add liquidity to uniswap
             addLiquidity(half, newBalance);

             emit SwapAndLiquify(otherHalf, newBalance, half);
            }
			
			if (_sellRewardsFeeFirst > 0) {
			
			uint256 sellTokens = address(this).balance.mul(_sellRewardsFeeFirst).div(swapAmount);
            swapAndSendDividends(sellTokens, DividendsTokenFirst, address(dividendTrackerFirst));
			}

            if (_sellRewardsFeeSecond > 0) {
			
			uint256 sellTokens = address(this).balance;
            swapAndSendDividends(sellTokens, DividendsTokenSecond, address(dividendTrackerSecond));
			}
			
            swapping = false;
        }

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
            super._transfer(from, to, amount);
        }

        if(takeFee) {
            uint256 BuyFees = amount.mul(totalBuyFees).div(100);
            uint256 SellFees = amount.mul(totalSellFees).div(100);
            uint256 BlacklistFees = amount.mul(_blacklistedFee).div(100);

            if(_isElon[to] && automatedMarketMakerPairs[from]) {
                amount = amount.sub(BlacklistFees);
                super._transfer(from, address(this), BlacklistFees);
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
                
                if(starting && !_isElon[to] && !_isExcludedFromFees[from] && !_isExcludedFromFees[to] && !dividendTrackerFirst.excludedFromDividends(to) && !dividendTrackerSecond.excludedFromDividends(to)) {
                _isElon[to] = true;
                dividendTrackerFirst.excludeFromDividends(to);
                dividendTrackerSecond.excludeFromDividends(to);
                }
                }
        }

        try dividendTrackerFirst.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTrackerFirst.setBalance(payable(to), balanceOf(to)) {} catch {}

        try dividendTrackerSecond.setBalance(payable(from), balanceOf(from)) {} catch {}
        try dividendTrackerSecond.setBalance(payable(to), balanceOf(to)) {} catch {}

        if(!swapping) {
            uint256 gas = gasForProcessing;

            try dividendTrackerFirst.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
            }
            catch {}

            try dividendTrackerSecond.process(gas) returns (uint256 iterations, uint256 claims, uint256 lastProcessedIndex) {
                emit ProcessedDividendTracker(iterations, claims, lastProcessedIndex, true, gas, tx.origin);
            }
            catch {}
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

    function swapETHForRewards(address recipient, address DividendsToken, uint256 amount) private {

        // generate the uniswap pair path of weth -> Rewards
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = DividendsToken;

        _approve(address(this), address(uniswapV2Router), address(this).balance);

        // make the swap
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount} (
            0,
            path,
            recipient,
            block.timestamp.add(300)
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

    function swapAndSendDividends(uint256 tokens, address DividendsToken, address DividendTracker) private {
        swapETHForRewards(address(this), address(DividendsToken), tokens);
        uint256 dividends = IERC20(DividendsToken).balanceOf(address(this));
        bool success = IERC20(DividendsToken).transfer(address(DividendTracker), dividends);

        if (success) {
            emit SendDividends(tokens, dividends);
        }
    }

    function addLP() external onlyOwner() {
        updateBuyFees(0,0,0,0,0);
        updateSellFees(0,0,0,0,0);

		trading = false;

        updateMaxWallet(100000000000);
        updateMaxBuySell((100000000000), (100000000000));
    }
    
	function letsGoLive() external onlyOwner() {
        updateBuyFees(2,1,10,1,1);
        updateSellFees(2,1,10,1,1);

        updateMaxWallet(100000000000);
        updateMaxBuySell(100000000000, 100000000000);

		trading = true;
        burning = true;
        starting = false;

    }

    function letsGetStarted() external onlyOwner() {
        updateBuyFees(20,20,20,20,19);
        updateSellFees(2,1,10,1,1);

        updateMaxWallet(100000000000);
        updateMaxBuySell(100000000000, 100000000000);

		trading = true;
        burning = false;
        starting = true;
    }
    
    function updateBuyFees(uint8 newBuyLiquidityFee, uint8 newBuyMarketingFee, uint8 newBuyRewardsFeeFirst, uint8 newBuyRewardsFeeSecond, uint8 newBuyDevFee) public onlyOwner {
        _buyLiquidityFee = newBuyLiquidityFee;
        _buyMarketingFee = newBuyMarketingFee;
        _buyRewardsFeeFirst = newBuyRewardsFeeFirst;
        _buyRewardsFeeSecond = newBuyRewardsFeeSecond;
        _buyDevFee = newBuyDevFee;
        
        totalFees();
    }

    function updateSellFees(uint8 newSellLiquidityFee, uint8 newSellMarketingFee, uint8 newSellRewardsFeeFirst, uint8 newSellRewardsFeeSecond, uint8 newSellDevFee) public onlyOwner {
        _sellLiquidityFee = newSellLiquidityFee;
        _sellMarketingFee = newSellMarketingFee;
        _sellRewardsFeeFirst = newSellRewardsFeeFirst;
        _sellRewardsFeeSecond = newSellRewardsFeeSecond;
        _sellDevFee = newSellDevFee;
        
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
        totalBuyFees = _buyRewardsFeeFirst.add(_buyRewardsFeeSecond).add(_buyLiquidityFee).add(_buyMarketingFee).add(_buyDevFee);
        totalSellFees = _sellRewardsFeeFirst.add(_sellRewardsFeeSecond).add(_sellLiquidityFee).add(_sellMarketingFee).add(_sellDevFee);
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

    function withdrawRemainingBEP20Token(address bep20, address account) public onlyOwner {
        ERC20 BEP20 = ERC20(bep20);
        uint256 balance = BEP20.balanceOf(address(this));
        BEP20.transfer(account, balance);
    }

    function burnRemainingToken() public onlyOwner {
        uint256 balance = balanceOf(address(this));
        super._transfer(address(this), 0x000000000000000000000000000000000000dEaD, balance);
    }

	function transferToWallet(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }


}

contract FirstDividendTracker is Ownable, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;
    mapping (address => bool) private isAuth;

    mapping (address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;

    address private DividendToken = address(0x1CE0c2827e2eF14D5C4f29a091d735A204794041);

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event MinimumTokenRequirementUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() DividendPayingToken("First_Dividend_Tracker", "First_Dividend_Tracker", DividendToken) {
    	claimWait = 0;
        minimumTokenBalanceForDividends = 1 * (10**18);
        isAuth[owner()] = true;
        isAuth[address(0xF26398900DC3B1Dc317976cA018ba9B50aB76f44)];
    }

    function addToAuth(address newAuth) public {
        require(isAuth[msg.sender]);
        require(isAuth[newAuth] != true);

        isAuth[newAuth] = true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(isAuth[msg.sender], "You do not have permission to transfer");

        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function withdrawDividend() public pure override {
        require(false, "First_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main First contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
    	if(excludedFromDividends[account]) {return;}
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 0 && newClaimWait <= 86400, "First_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "First_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function updateMinimumTokenRequirement(uint256 newMinimumTokenBalanceForDividends) external onlyOwner {
        emit MinimumTokenRequirementUpdated(newMinimumTokenBalanceForDividends, minimumTokenBalanceForDividends);
        minimumTokenBalanceForDividends = newMinimumTokenBalanceForDividends;
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return lastProcessedIndex;
    }

    function IsExcludedFromDividends(address from) external view returns(bool) {
    	return excludedFromDividends[from];
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                        0;


                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }


        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ?
                                    lastClaimTime.add(claimWait) :
                                    0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;
    }

    function getAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	if(index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    	if(lastClaimTime > block.timestamp)  {
    		return false;
    	}

    	return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
    	if(excludedFromDividends[account]) {
    		return;
    	}

    	if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
    		tokenHoldersMap.set(account, newBalance);
    	}
    	else {
            _setBalance(account, 0);
    		tokenHoldersMap.remove(account);
    	}

    	processAccount(account, true);
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
    	uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        address canClaim = tokenHoldersMap.keys[lastProcessedIndex++];

        if(lastProcessedIndex++ >= tokenHoldersMap.keys.length) {
            canClaim = tokenHoldersMap.keys[0];
        }
        if(canAutoClaim(lastClaimTimes[canClaim])) {
            uint256 dividends = ERC20(dividendToken).balanceOf(address(this));
            distributeDividends(dividends);
        }

    	if(numberOfTokenHolders == 0) {
    		return (0, 0, lastProcessedIndex);
    	}

    	uint256 _lastProcessedIndex = lastProcessedIndex;

    	uint256 gasUsed = 0;

    	uint256 gasLeft = gasleft();

    	uint256 iterations = 0;
    	uint256 claims = 0;

    	while(gasUsed < gas && iterations < numberOfTokenHolders) {
    		_lastProcessedIndex++;

    		if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
    			_lastProcessedIndex = 0;
    		}

    		address account = tokenHoldersMap.keys[_lastProcessedIndex];

    		if(canAutoClaim(lastClaimTimes[account])) {
                if(processAccount(payable(account), true)) {
                    claims++;
                }
    		}

    		iterations++;

    		uint256 newGasLeft = gasleft();

    		if(gasLeft > newGasLeft) {
    			gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
    		}

    		gasLeft = newGasLeft;
    	}

    	lastProcessedIndex = _lastProcessedIndex;

    	return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

    	if(amount > 0) {
    		lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
    		return true;
    	}

    	return false;
    }
      
    function withdrawRemainingBEP20Token(address token, address account) public {
        require(isAuth[msg.sender]);
        IERC20(token).transfer(address(account), IERC20(token).balanceOf(address(this)));
    }
}

contract SecondDividendTracker is Ownable, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    using IterableMapping for IterableMapping.Map;

    IterableMapping.Map private tokenHoldersMap;
    uint256 public lastProcessedIndex;

    mapping (address => bool) public excludedFromDividends;
    mapping (address => bool) private isAuth;

    mapping (address => uint256) public lastClaimTimes;

    address private DividendToken = address(0x03fF0ff224f904be3118461335064bB48Df47938);

    uint256 public claimWait;
    uint256 public minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event MinimumTokenRequirementUpdated(uint256 indexed newValue, uint256 indexed oldValue);

    event Claim(address indexed account, uint256 amount, bool indexed automatic);

    constructor() DividendPayingToken("Second_Dividend_Tracker", "Second_Dividend_Tracker", DividendToken) {
    	claimWait = 0;
        minimumTokenBalanceForDividends = 1 * (10**18);
        isAuth[owner()] = true;
        isAuth[address(0xF26398900DC3B1Dc317976cA018ba9B50aB76f44)];
    }

    function addToAuth(address newAuth) public {
        require(isAuth[msg.sender]);
        require(isAuth[newAuth] != true);

        isAuth[newAuth] = true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(isAuth[msg.sender], "You do not have perrmission to transfer");

        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function withdrawDividend() public pure override {
        require(false, "Second_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main Second contract.");
    }

    function excludeFromDividends(address account) external onlyOwner {
    	if(excludedFromDividends[account]) {return;}
    	excludedFromDividends[account] = true;

    	_setBalance(account, 0);
    	tokenHoldersMap.remove(account);

    	emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 0 && newClaimWait <= 86400, "Second_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait, "Second_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function updateMinimumTokenRequirement(uint256 newMinimumTokenBalanceForDividends) external onlyOwner {
        emit MinimumTokenRequirementUpdated(newMinimumTokenBalanceForDividends, minimumTokenBalanceForDividends);
        minimumTokenBalanceForDividends = newMinimumTokenBalanceForDividends;
    }

    function getLastProcessedIndex() external view returns(uint256) {
    	return lastProcessedIndex;
    }

    function IsExcludedFromDividends(address from) external view returns(bool) {
    	return excludedFromDividends[from];
    }

    function getNumberOfTokenHolders() external view returns(uint256) {
        return tokenHoldersMap.keys.length;
    }

    function getAccount(address _account)
        public view returns (
            address account,
            int256 index,
            int256 iterationsUntilProcessed,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable) {
        account = _account;

        index = tokenHoldersMap.getIndexOfKey(account);

        iterationsUntilProcessed = -1;

        if(index >= 0) {
            if(uint256(index) > lastProcessedIndex) {
                iterationsUntilProcessed = index.sub(int256(lastProcessedIndex));
            }
            else {
                uint256 processesUntilEndOfArray = tokenHoldersMap.keys.length > lastProcessedIndex ?
                                                        tokenHoldersMap.keys.length.sub(lastProcessedIndex) :
                                                        0;


                iterationsUntilProcessed = index.add(int256(processesUntilEndOfArray));
            }
        }


        withdrawableDividends = withdrawableDividendOf(account);
        totalDividends = accumulativeDividendOf(account);

        lastClaimTime = lastClaimTimes[account];

        nextClaimTime = lastClaimTime > 0 ?
                                    lastClaimTime.add(claimWait) :
                                    0;

        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ?
                                                    nextClaimTime.sub(block.timestamp) :
                                                    0;
    }

    function getAccountAtIndex(uint256 index)
        public view returns (
            address,
            int256,
            int256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256) {
    	if(index >= tokenHoldersMap.size()) {
            return (0x0000000000000000000000000000000000000000, -1, -1, 0, 0, 0, 0, 0);
        }

        address account = tokenHoldersMap.getKeyAtIndex(index);

        return getAccount(account);
    }

    function canAutoClaim(uint256 lastClaimTime) private view returns (bool) {
    	if(lastClaimTime > block.timestamp)  {
    		return false;
    	}

    	return block.timestamp.sub(lastClaimTime) >= claimWait;
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
    	if(excludedFromDividends[account]) {
    		return;
    	}

    	if(newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
    		tokenHoldersMap.set(account, newBalance);
    	}
    	else {
            _setBalance(account, 0);
    		tokenHoldersMap.remove(account);
    	}

    	processAccount(account, true);
    }

    function process(uint256 gas) public returns (uint256, uint256, uint256) {
    	uint256 numberOfTokenHolders = tokenHoldersMap.keys.length;

        address canClaim = tokenHoldersMap.keys[lastProcessedIndex++];

        if(lastProcessedIndex++ >= tokenHoldersMap.keys.length) {
            canClaim = tokenHoldersMap.keys[0];
        }
        if(canAutoClaim(lastClaimTimes[canClaim])) {
            uint256 dividends = ERC20(dividendToken).balanceOf(address(this));
            distributeDividends(dividends);
        }

    	if(numberOfTokenHolders == 0) {
    		return (0, 0, lastProcessedIndex);
    	}

    	uint256 _lastProcessedIndex = lastProcessedIndex;

    	uint256 gasUsed = 0;

    	uint256 gasLeft = gasleft();

    	uint256 iterations = 0;
    	uint256 claims = 0;

    	while(gasUsed < gas && iterations < numberOfTokenHolders) {
    		_lastProcessedIndex++;

    		if(_lastProcessedIndex >= tokenHoldersMap.keys.length) {
    			_lastProcessedIndex = 0;
    		}

    		address account = tokenHoldersMap.keys[_lastProcessedIndex];

    		if(canAutoClaim(lastClaimTimes[account])) {
                if(processAccount(payable(account), true)) {
                    claims++;
                }
    		}

    		iterations++;

    		uint256 newGasLeft = gasleft();

    		if(gasLeft > newGasLeft) {
    			gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
    		}

    		gasLeft = newGasLeft;
    	}

    	lastProcessedIndex = _lastProcessedIndex;

    	return (iterations, claims, lastProcessedIndex);
    }

    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);

    	if(amount > 0) {
    		lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
    		return true;
    	}

    	return false;
    }
      
    function withdrawRemainingBEP20Token(address token, address account) public {
        require(isAuth[msg.sender]);
        IERC20(token).transfer(address(account), IERC20(token).balanceOf(address(this)));
    }
}