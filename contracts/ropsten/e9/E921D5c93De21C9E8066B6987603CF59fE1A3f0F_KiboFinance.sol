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

// SPDX-License-Identifier: MIT

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Context.sol";

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
    constructor (string memory name_, string memory symbol_) {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface ICERC20 {
    function balanceOf(address owner) external view returns (uint256);

    function mint(uint256) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface ICETH {
    function balanceOf(address owner) external view returns (uint256);
    
    function mint() external payable;

    function exchangeRateCurrent() external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint) external returns (uint);

    function redeemUnderlying(uint) external returns (uint);

    function transfer(address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IKToken {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function mint(address account, uint256 amount) external;
    
    function getUnderlying() external view returns (address);
    
    function getStrike() external view returns (uint);

    function getExpiresOn() external view returns (uint);
    
    function isPut() external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


interface IPriceConsumer {
    function getLatestPrice() external view returns (int);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IUniswapV2Router02 {
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
      external
      payable
      returns (uint[] memory amounts);
      
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
      
    function WETH() external returns (address); 
    
    function getAmountsIn(uint amountOut, address[] memory path) external view returns (uint[] memory amounts);
    
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
    
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
    
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
      external
      payable
      returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


import "./SafeERC20.sol";
import "./Ownable.sol";
import "./KiboStorage.sol";
import "./KiboConstants.sol";
import "./KiboUniswap.sol";
import "./IPriceConsumer.sol";

contract KiboAdmin is Ownable, KiboStorage, KiboUniswap {
    event OptionFinalPriceSet(address indexed option, uint256 assetPriceInUsdt, uint256 optionWorthInUsdt);

    modifier validOption(address _optionAddress) {
        require(options[_optionAddress].isValid, "Invalid option");
        require(IKToken(_optionAddress).getExpiresOn() > block.timestamp, "Expired option");
        _;
    }
    
    function _enableUnderlying(address _underlying, address _cToken, bool _stakeCollateral, address _priceConsumer) external onlyOwner {
        Underlying storage underlying = underlyings[_underlying];
        underlying.isActive = true;
        underlying.cToken = _cToken;
        underlying.stakeCollateral = _stakeCollateral;
        underlying.priceConsumer = _priceConsumer;
    }

    function _disableUnderlying(address _underlying) external onlyOwner {
        Underlying storage underlying = underlyings[_underlying];
        underlying.isActive = false;
    }
    
    function _deactivateOption(address _optionAddress) external onlyOwner {
        require(options[_optionAddress].isValid, "It is not activated");
        Option storage option = options[_optionAddress];
        option.isValid = false;
    }
    
    function _activatePutOption(address _optionAddress, uint256 _usdtCollateral, uint256 _uniswapInitialUSDT, uint256 _uniswapInitialTokens) external onlyOwner {
        require(_usdtCollateral > 0, "Collateral cannot be zero");
        require(_uniswapInitialUSDT > 0, "Uniswap USDT cannot be zero");
        require(_uniswapInitialTokens > 0, "Uniswap tokens cannot be zero");
        require(IKToken(_optionAddress).getExpiresOn() > block.timestamp, "Expired option");
        require(IKToken(_optionAddress).isPut(), "Option is not PUT");
        address underlying = IKToken(_optionAddress).getUnderlying();
        require(underlyings[underlying].isActive, "Invalid underlying");

        Option storage option = options[_optionAddress];
        option.isValid = true;

        IKToken(_optionAddress).mint(address(this), _uniswapInitialTokens); // This has 4 decimals
        
        Seller storage seller = options[_optionAddress].sellers[msg.sender];
        seller.collateral = _usdtCollateral;
        seller.isValid = true;
        
        uint256 decimals = 18;
        if (underlying != address(0)) {
            decimals = ERC20(underlying).decimals();
        }
        seller.notional = _uniswapInitialTokens * 10 ** (decimals-4);
        
        SafeERC20.safeTransferFrom(KiboConstants.usdtToken, msg.sender, address(this), _uniswapInitialUSDT + _usdtCollateral);
        //seller.cTokens += supplyErc20ToCompound(usdtToken, cUSDT, _usdtCollateral);

        createPairInUniswap(_optionAddress, _uniswapInitialTokens, _uniswapInitialUSDT);
    }
    
    function _activateCallOption(address _optionAddress, uint256 _uniswapInitialUSDT, uint256 _uniswapInitialTokens, uint256 _collateral) external payable onlyOwner {
        require(_uniswapInitialUSDT > 0, "Uniswap USDT cannot be zero");
        require(_uniswapInitialTokens > 0, "Uniswap tokens cannot be zero");
        require(!IKToken(_optionAddress).isPut(), "Option is not CALL");
        require(IKToken(_optionAddress).getExpiresOn() > block.timestamp, "Expired option");
        address underlying = IKToken(_optionAddress).getUnderlying();
        require(underlyings[underlying].isActive, "Invalid underlying");
        
        if (underlying != address(0)) {
            require(_collateral > 0, "Collateral cannot be zero");
        } else  {
            require(msg.value > 0, "Collateral cannot be zero");
        }

        Option storage option = options[_optionAddress];
        option.isValid = true;

        IKToken(_optionAddress).mint(address(this), _uniswapInitialTokens);
        
        //seller.cTokens += supplyEthToCompound(cETH, msg.value);

        SafeERC20.safeTransferFrom(KiboConstants.usdtToken, msg.sender, address(this), _uniswapInitialUSDT);

        Seller storage seller = options[_optionAddress].sellers[msg.sender];

        uint256 decimals = 18;
        if (underlying != address(0)) {
            decimals = ERC20(underlying).decimals();
            SafeERC20.safeTransferFrom(ERC20(underlying), msg.sender, address(this), _collateral);
        } else  {
            seller.collateral = msg.value;
        }

        seller.isValid = true;
        seller.notional = _uniswapInitialTokens * 10 ** (decimals-4); // KToken has 4 decimals. We deduce 4 from the underlying's number of decimals
        
        createPairInUniswap(_optionAddress, _uniswapInitialTokens, _uniswapInitialUSDT);
    }
    
    function _setFinalPriceAtMaturity(address _optionAddress) external onlyOwner {
        require(options[_optionAddress].isValid, "Invalid option");
        require(options[_optionAddress].spotPrice == 0, "Already set");
        require(IKToken(_optionAddress).getExpiresOn() < block.timestamp, "Still not expired");
        
        address underlying = IKToken(_optionAddress).getUnderlying();
        address priceConsumer = underlyings[underlying].priceConsumer;
        uint256 spotPrice = uint256(IPriceConsumer(priceConsumer).getLatestPrice()); // In USD, 8 decimals
        uint256 strike = IKToken(_optionAddress).getStrike(); // In USD, 8 decimals
        bool isPut = IKToken(_optionAddress).isPut();
        
        uint256 optionWorth = 0;
    
        if (isPut && spotPrice < strike) {
            optionWorth = strike - spotPrice;
        }
        else if (!isPut && spotPrice > strike) {
            optionWorth = spotPrice - strike;
        }
        
        optionWorth = optionWorth / 100; // I remove the extra 2 decimals to make it in USDT
        spotPrice = spotPrice / 100; // I remove the extra 2 decimals to make it in USDT
        
        Option storage option = options[_optionAddress];
        option.spotPrice = spotPrice;
        option.optionWorth = optionWorth;
        
        emit OptionFinalPriceSet(_optionAddress, spotPrice, optionWorth);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


import "./ERC20.sol";
import "./SafeERC20.sol";
import "./ICETH.sol";
import "./ICERC20.sol";


contract KiboCompound {
    address payable cETH = payable(0x859e9d8a4edadfEDb5A2fF311243af80F85A91b8);
    address cUSDT = 0xF6958Cf3127e62d3EB26c79F4f45d3F3b2CcdeD4;
    address cwBTC = 0xF6958Cf3127e62d3EB26c79F4f45d3F3b2CcdeD4;

    function supplyEthToCompound(address payable _cEtherContract, uint256 _total)
        internal
        returns (uint256)
    {
        // Create a reference to the corresponding cToken contract
        ICETH cToken = ICETH(_cEtherContract);

        uint256 balance = cToken.balanceOf(address(this));

        cToken.mint{value:_total, gas: 250000}();
        return cToken.balanceOf(address(this)) - balance;
    }
    
    function supplyErc20ToCompound(
        ERC20 _erc20Contract,
        address _ICERC20Contract,
        uint256 _numTokensToSupply
    ) internal returns (uint) {
        // Create a reference to the corresponding cToken contract, like cDAI
        ICERC20 cToken = ICERC20(_ICERC20Contract);

        uint256 balance = cToken.balanceOf(address(this));

        // Approve transfer on the ERC20 contract
        SafeERC20.safeApprove(_erc20Contract, _ICERC20Contract, _numTokensToSupply);

        // Mint cTokens
        cToken.mint(_numTokensToSupply);
        
        uint256 newBalance = cToken.balanceOf(address(this));

        return newBalance - balance;
    }
    
    function redeemICERC20Tokens(
        uint256 amount,
        bool redeemType,
        address _ICERC20Contract
    ) internal returns (uint256) {
        // Create a reference to the corresponding cToken contract, like cDAI
        ICERC20 cToken = ICERC20(_ICERC20Contract);

        // `amount` is scaled up, see decimal table here:
        // https://compound.finance/docs#protocol-math

        uint256 redeemResult;

        if (redeemType == true) {
            // Retrieve your asset based on a cToken amount
            redeemResult = cToken.redeem(amount);
        } else {
            // Retrieve your asset based on an amount of the asset
            redeemResult = cToken.redeemUnderlying(amount);
        }

        return redeemResult;
    }

    function redeemICETH(
        uint256 amount,
        bool redeemType,
        address _cEtherContract
    ) internal returns (uint256) {
        // Create a reference to the corresponding cToken contract
        ICETH cToken = ICETH(_cEtherContract);

        // `amount` is scaled up by 1e18 to avoid decimals

        uint256 redeemResult;

        if (redeemType == true) {
            // Retrieve your asset based on a cToken amount
            redeemResult = cToken.redeem(amount);
        } else {
            // Retrieve your asset based on an amount of the asset
            redeemResult = cToken.redeemUnderlying(amount);
        }

        // Error codes are listed here:
        // https://compound.finance/docs/ctokens#ctoken-error-codes
        return redeemResult;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


import "./ERC20.sol";


library KiboConstants {
    IERC20 constant public kiboToken =  IERC20(0xF096C24D20528bD45aC555F3c0cbf4F781316556);
    IERC20 constant public usdtToken = IERC20(0x83072aC0d1dFe6b79E1b95B8b96309065ECCd074);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


import "./SafeERC20.sol";
import "./Ownable.sol";
import "./KiboConstants.sol";

contract KiboFees is Ownable {
    uint256 public totalETHFees; // 18 decimals
    
    mapping(address => uint256) fees;
    
    function _withdrawFees(address _token) external onlyOwner {
        require(fees[_token] > 0, 'Nothing to claim');
        uint256 amount = fees[_token];
        fees[_token] = 0;
        SafeERC20.safeTransfer(ERC20(_token), msg.sender, amount);
    }
    
    function _withdrawETHFees() external onlyOwner {
        require(totalETHFees > 0, 'Nothing to claim');
        uint256 amount = totalETHFees;
        totalETHFees = 0;
        payable(msg.sender).transfer(amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./KiboFees.sol";
import "./KiboRewards.sol";
import "./KiboCompound.sol";
import "./KiboStorage.sol";
import "./KiboAdmin.sol";

contract KiboFinance is KiboFees, KiboRewards, KiboCompound, KiboStorage, KiboAdmin {
    event OptionPurchase(address indexed option, address indexed buyer, uint256 weiNotional, uint256 usdtCollateral, uint256 premium);
    event ReturnedToSeller(address indexed option, address indexed seller, uint256 totalUSDTReturned, uint256 collateral, uint256 notional);
    event ReturnedToBuyer(address indexed option, address indexed buyer, uint256 totalUSDTReturned, uint256 _numberOfTokens);
    
    function getHowMuchToClaimForSellers(address _optionAddress, address _seller) public view returns (uint256) {
        Seller memory seller = options[_optionAddress].sellers[_seller];
        if (seller.claimed) {
            return 0;
        }
        
        uint256 optionWorth = options[_optionAddress].optionWorth; // This has 6 decimals as it is in USDT
        // For CALL I need to convert the price from USDT to the underlying
        if (!IKToken(_optionAddress).isPut()) {
            optionWorth = optionWorth / options[_optionAddress].spotPrice;
        }
        
        uint256 amountToSubstract;
        address underlying = IKToken(_optionAddress).getUnderlying();
        if (underlying == address(0)) {
            amountToSubstract = seller.notional * optionWorth / 1e18; // I take out the decimals from the notional
        }
        else {
            uint256 decimals = ERC20(underlying).decimals();
            amountToSubstract = seller.notional * optionWorth / (10 ** (decimals)); // I take out the decimals from the notional
        }
        
        return seller.collateral - amountToSubstract;
    }
    
    function claimCollateralAtMaturityForSellers(address _optionAddress) external {
        require(options[_optionAddress].isValid, "Invalid option");
        require(options[_optionAddress].spotPrice > 0, "Still not ready");
        
        Seller storage seller = options[_optionAddress].sellers[msg.sender];
        
        require(seller.isValid, "Seller not valid");
        require(!seller.claimed, "Already claimed");
        
        uint256 totalToReturn = getHowMuchToClaimForSellers(_optionAddress, msg.sender); // This is in USDT for PUT and in the underlying for CALL
        require(totalToReturn > 0, 'Nothing to return');
        
        seller.claimed = true;

        if (IKToken(_optionAddress).isPut()) {
            //ICERC20 cToken = ICERC20(cUSDT);
            //uint256 interests = seller.cTokens * cToken.exchangeRateCurrent() - seller.collateral;

            //uint256 redeemResult = redeemICERC20Tokens(totalToReturn + interests, true, cUSDT);
            //require(redeemResult == 0, "An error occurred");

            SafeERC20.safeTransfer(KiboConstants.usdtToken, msg.sender, totalToReturn); // + interests
        } else {
            //ICETH cToken = ICETH(cETH);
            //uint256 interests = seller.cTokens * cToken.exchangeRateCurrent() - seller.collateral;
            //uint256 redeemResult = redeemICETH(totalToReturn + interests, true, cETH);
            //require(redeemResult == 0, "An error occurred");
            
            address underlying = IKToken(_optionAddress).getUnderlying();
            if (underlying == address(0)) {
                payable(msg.sender).transfer(totalToReturn);
            }
            else {
                SafeERC20.safeTransfer(ERC20(underlying), msg.sender, totalToReturn); // + interests
            }
        }
        
        emit ReturnedToSeller(_optionAddress, msg.sender, totalToReturn, seller.collateral, seller.notional);
    }
    
    function getHowMuchToClaimForBuyers(address _optionAddress, uint256 _numberOfKTokens) public view returns (uint256) {
        uint256 optionWorth = options[_optionAddress].optionWorth; // This has 6 decimals as it is in USDT
        return _numberOfKTokens * optionWorth / 1e4; // As KToken has 4 decimals
    }
    
    function claimCollateralAtMaturityForBuyers(address _optionAddress, uint256 _numberOfKTokens) external {
        require(options[_optionAddress].isValid, "Invalid option");
        require(options[_optionAddress].spotPrice > 0, "Still not ready");
        require(_numberOfKTokens > 0, "Invalid number of tokens");
        
        require(IERC20(_optionAddress).transferFrom(msg.sender, address(this), _numberOfKTokens), "Transfer failed");
        
        uint256 totalToReturn = getHowMuchToClaimForBuyers(_optionAddress, _numberOfKTokens);
        SafeERC20.safeTransfer(KiboConstants.usdtToken, msg.sender, totalToReturn);

        emit ReturnedToBuyer(_optionAddress, msg.sender, totalToReturn, _numberOfKTokens);
    }
    
    // Notional has the number of decimals of the underlying
    function sell(address _optionAddress, uint256 _notional) payable external validOption(_optionAddress) {
        Seller storage seller = options[_optionAddress].sellers[msg.sender];
        address underlying = IKToken(_optionAddress).getUnderlying();

        uint256 usdtCollateral;
        uint256 feesToCollect;
        uint256 decimals = 18;

        if (IKToken(_optionAddress).isPut()) {
            usdtCollateral = calculateCollateralForPut(_optionAddress, _notional);
            SafeERC20.safeTransferFrom(KiboConstants.usdtToken, msg.sender, address(this), usdtCollateral);
            //seller.cTokens += supplyErc20ToCompound(usdtToken, cUSDT, usdtCollateral);
        } 
        else {
            if (underlying != address(0)) {
                decimals = ERC20(underlying).decimals();
                SafeERC20.safeTransferFrom(ERC20(underlying), msg.sender, address(this), _notional);
                //seller.cTokens += supplyErc20ToCompound(wBTCToken, cwBTC, _notional);
            } else  {
                require(msg.value == _notional, 'Invalid collateral');
                //seller.cTokens += supplyEthToCompound(cETH, _notional);
            }
        }   

        require(decimals - 4 > 0, "You can't sell such a small notional");
        uint256 tokensToMint = _notional / 10 ** (decimals - 4);  // KToken has 4 decimals. We deduce 4 from the underlying's number of decimals
        IKToken(_optionAddress).mint(address(this), tokensToMint); 
        
        //We sell the tokens for USDT in Uniswap, which is sent to the user
        uint256 premium = sellKTokensInUniswap(_optionAddress, tokensToMint);
        
        if (IKToken(_optionAddress).isPut()) {
            feesToCollect = usdtCollateral / 100;
            seller.collateral += usdtCollateral - feesToCollect;
            fees[address(KiboConstants.usdtToken)] += feesToCollect;
        } else {
            feesToCollect = _notional / 100;
            seller.collateral += _notional - feesToCollect;
            
            if (underlying != address(0)) {
                fees[underlying] += feesToCollect;
            }
            else {
                totalETHFees += feesToCollect;
            }
        }

        seller.isValid = true;
        seller.notional += _notional;
        
        //We emit an event to be able to send KiboTokens offchain, according to the difference against the theoretical Premium
        emit OptionPurchase(_optionAddress, msg.sender, _notional, usdtCollateral, premium);
    }
    
    // Collateral is always kept in USDT
    function calculateCollateralForPut(address _optionAddress, uint256 _notional) public view returns (uint256) {
        uint256 collateral = IKToken(_optionAddress).getStrike() * _notional;

        // I still need to remove 2 decimals from the strike (as it is in USD, not USDT) and the notional decimals, which depend on the underlying

        uint256 decimals = 20;
        address underlying = IKToken(_optionAddress).getUnderlying();
        if (underlying != address(0)) {
            decimals = 2 + ERC20(underlying).decimals();
        }
            
        return collateral / (10 ** decimals);
    }

    receive() external payable {
        revert();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


import "./Ownable.sol";
import "./SafeERC20.sol";
import "./KiboConstants.sol";


contract KiboRewards is Ownable {
    event RewardsIncreased(address indexed beneficiary, uint256 total);
    event RewardsWithdrawn(address indexed beneficiary, uint256 total);

    mapping(address => uint256) public kiboRewards;
    
    function withdrawKiboTokens() external {
        require(kiboRewards[msg.sender] > 0, "Nothing to withdraw");
        uint256 total = kiboRewards[msg.sender];
        kiboRewards[msg.sender] = 0;
        SafeERC20.safeTransfer(KiboConstants.kiboToken, msg.sender, total);
        emit RewardsWithdrawn(msg.sender, total);
    }
    
    function _addKiboRewards(address _beneficiary, uint256 _total) external onlyOwner {
        kiboRewards[_beneficiary] += _total;
        emit RewardsIncreased(_beneficiary, _total);
    }
    
    function _withdrawKibo(uint256 _amount) external onlyOwner {
        SafeERC20.safeTransfer(KiboConstants.kiboToken, msg.sender, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./IKToken.sol";


contract KiboStorage {
    struct Seller {
        bool isValid;
        uint256 collateral; // This is in USDT (6 decimals) for PUT and in the underlying (same decimals) for CALL
        uint256 notional; // This has the same number of decimals as the underlying
        bool claimed;
        uint256 cTokens; // All decimals
    }
    
    struct Option {
        bool isValid;
        uint256 spotPrice; // This has 6 decimals (we remove 2 when moving from USD to USDT)
        uint256 optionWorth; // This has 6 decimals (same as above)
        mapping(address => Seller) sellers;
    }
    
    struct Underlying {
        bool isActive;
        address cToken;
        bool stakeCollateral;
        address priceConsumer;
    }
    
    mapping(address => Option) options;
    mapping(address => Underlying) underlyings;
    
    function getUnderlying(address _address) external view returns (bool _isActive, address _cToken, bool _stakeCollateral, address _priceConsumer) {
        return (underlyings[_address].isActive, underlyings[_address].cToken, underlyings[_address].stakeCollateral, underlyings[_address].priceConsumer);
    }
    
    function getOption(address _optionAddress) external view returns (bool _isValid, bool _isPut, uint256 _spotPrice, uint256 _optionWorth) {
        return (options[_optionAddress].isValid, IKToken(_optionAddress).isPut(), options[_optionAddress].spotPrice, options[_optionAddress].optionWorth);
    }
    
    function getSeller(address _optionAddress, address _seller) external view returns (bool _isValid, uint256 _collateral, uint256 _notional, bool _claimed, uint256 _cTokens) {
        Seller memory seller = options[_optionAddress].sellers[_seller];
        return (seller.isValid, seller.collateral, seller.notional, seller.claimed, seller.cTokens);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


import "./SafeERC20.sol";
import "./IUniswapV2Router02.sol";
import "./KiboConstants.sol";


contract KiboUniswap {
    IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    
    // Returns the amount in USDT if you sell 1 KiboToken in Uniswap
    function getKiboSellPrice() external view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(KiboConstants.kiboToken);
        path[1] = address(KiboConstants.usdtToken);
        uint[] memory amounts = uniswapRouter.getAmountsOut(1e18, path);
        return amounts[1];
    }
    
    // Returns the amount in USDT if you buy 1 KiboToken in Uniswap
    function getKiboBuyPrice() external view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(KiboConstants.usdtToken);
        path[1] = address(KiboConstants.kiboToken);
        uint[] memory amounts = uniswapRouter.getAmountsIn(1e18, path);
        return amounts[0];
    }
    
    function buyKTokensInUniswap(uint256 _notional, uint256 _totalUSDT, address _optionAddress) public {
        SafeERC20.safeTransferFrom(KiboConstants.usdtToken, msg.sender, address(this), _totalUSDT);
        uint256 allowance = KiboConstants.usdtToken.allowance(address(this), address(uniswapRouter));
        if (allowance > 0 && allowance < _totalUSDT) {
            SafeERC20.safeApprove(KiboConstants.usdtToken, address(uniswapRouter), 0);
        }
        if (allowance == 0) {
            SafeERC20.safeApprove(KiboConstants.usdtToken, address(uniswapRouter), _totalUSDT);
        }
        address[] memory path = new address[](2);
        path[0] = address(KiboConstants.usdtToken);
        path[1] = _optionAddress;
        uint[] memory amounts = uniswapRouter.swapTokensForExactTokens(_notional, _totalUSDT, path, msg.sender, block.timestamp);
        SafeERC20.safeTransferFrom(ERC20(_optionAddress), address(this), msg.sender, amounts[1]);
    }
    
    function sellKTokensInUniswap(address _optionAddress, uint256 _tokensAmount) internal returns (uint256)  {
        address[] memory path = new address[](2);
        path[0] = _optionAddress;
        path[1] = address(KiboConstants.usdtToken);
        IERC20(_optionAddress).approve(address(uniswapRouter), _tokensAmount);
        // TODO: uint256[] memory amountsOutMin = uniswapRouter.getAmountsOut(_tokensAmount, path);
        // Use amountsOutMin[1]
        uint[] memory amounts = uniswapRouter.swapExactTokensForTokens(_tokensAmount, 0, path, msg.sender, block.timestamp);
        return amounts[1];
    }
    
    function createPairInUniswap(address _optionAddress, uint256 _totalTokens, uint256 _totalUSDT) internal returns (uint amountA, uint amountB, uint liquidity) {
        uint256 allowance = KiboConstants.usdtToken.allowance(address(this), address(uniswapRouter));
        if (allowance > 0 && allowance < _totalUSDT) {
            SafeERC20.safeApprove(KiboConstants.usdtToken, address(uniswapRouter), 0);
        }
        if (allowance == 0) {
            SafeERC20.safeApprove(KiboConstants.usdtToken, address(uniswapRouter), _totalUSDT);
        }
        IERC20(_optionAddress).approve(address(uniswapRouter), _totalTokens);
        (amountA, amountB, liquidity) = uniswapRouter.addLiquidity(_optionAddress, address(KiboConstants.usdtToken), _totalTokens, _totalUSDT, 0, 0, msg.sender, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./Address.sol";

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