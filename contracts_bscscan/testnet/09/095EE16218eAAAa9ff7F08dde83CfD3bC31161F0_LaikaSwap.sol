/**
 *Submitted for verification at BscScan.com on 2021-10-14
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
    mapping(address=>bool) private _authorised;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event Authorised(
        address indexed account,
        bool isAuthorised
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        _authorised[msgSender] = true;
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
     * @dev Throws if called by any account that is not authorised.
     */
    modifier onlyAuthorised() {
        require(_authorised[_msgSender()] == true, "Ownable: caller is not authorised");
        _;
    }

    /**
     * @dev Adds and removes authorised addresses. Can only be called by the current owner.
     */
    function authorise(address account, bool isAuthorised) public virtual onlyOwner {
        require (_authorised[account] != isAuthorised, "Ownable: address is already set to that state");
        emit Authorised(account, isAuthorised);
        _authorised[account] = isAuthorised;
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


contract LaikaSwap is Context, Ownable {
    using SafeERC20 for IERC20;
    using Address for address payable;
    
    IUniswapV2Router02 private uniswapV2Router;
    
    address public oldLaika = 0x1e21be2147058E5D693F449d1cd17613db3b40E2;
    address public newLaika = 0x82A61Eb4755f66207CaFD183bE53ec45F6eB61E9;
    
    address[] private seedAccounts;
    address[] private excluded;
    
    mapping (address => bool) private isExcluded;
    
    uint256 public oldTotalSupply;
    uint256 public newTotalSupply;
    uint256 public immutable SUPPLY_MODIFIER;
    uint256 public constant MAGNITUDE = 2**128;
    
    mapping(address => uint256) private snapshotBalance;
    mapping(address => bool) private inSnapshot;
    bool public snapshotLoaded;
    
    bool private seedAccountsLoaded;
    
    bool public canClaim;
    
    mapping(address => uint256) public newLaikaBalance;
    uint256 private oldLaikaSold;
    uint256 private totalBNBCreated;
    
    constructor () {
        oldTotalSupply = IERC20(oldLaika).totalSupply();
        newTotalSupply = IERC20(newLaika).totalSupply();
        SUPPLY_MODIFIER = newTotalSupply / oldTotalSupply;
        
        //0x10ED43C718714eb63d5aA57B78B54704E256024E <-- Mainnet PCS address
        //0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3 <-- Testnet kiemtienonline PCS address - CHANGEME
        //0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D <-- Eth testnets Uniswap 
        uniswapV2Router = IUniswapV2Router02 (0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); 
    }
    

    function exclude (address account, bool value) external onlyAuthorised {
        require (isExcluded[account] != value, "Account exclusion is already set to value");
        
        if (value) {
            isExcluded[account] = true;
            excluded.push (account);
        } else {
            for (uint256 i = 0; i < excluded.length; i++) {
                if (excluded[i] == account) {
                    if (i != excluded.length - 1)
                        excluded[i] = excluded[excluded.length - 1];
                    
                    excluded.pop();
                    isExcluded[account] = false;
                }
            }
        }
    } 
    
    function checkExcluded (address account) external view onlyAuthorised returns (bool) {
        return isExcluded[account];
    }
    
    function loadSnapshot (address[] memory holders, uint256[] memory balances, address[] memory _seedAccounts) external onlyAuthorised {
        require (holders.length == balances.length, "Holders and balances must be equal length");
        
        for (uint256 i = 0; i < holders.length; i++) {
            snapshotBalance[holders[i]] = balances[i];
            inSnapshot[holders[i]] = true;
        }
            
        snapshotLoaded = true;
        loadSeedAccounts (_seedAccounts);
    }
    
    function loadSeedAccounts (address[] memory _seedAccounts) public onlyAuthorised {
        require (snapshotLoaded, "Snapshot must be loaded first");
        require (_seedAccounts.length > 0, "Must provide at least one seed account");
        
        for (uint256 i = 0; i < _seedAccounts.length; i++) {
            require (_seedAccounts[i] != address(0), "The zero address cannot be a seed account");
            require (inSnapshot[_seedAccounts[i]], "Seed accounts must be in snapshot");
            require (IERC20(oldLaika).balanceOf (_seedAccounts[i]) == snapshotBalance[_seedAccounts[i]], "Seed account balances must match snapshot");
        }
        
        seedAccounts = _seedAccounts;
        seedAccountsLoaded = true;
    }
    
    function deposit (uint256 amount) external {
        address account = _msgSender();
        require (snapshotLoaded, "Contract not ready for deposits");
        require (amount > 0, "Can't deposit 0");
        require (inSnapshot[account], "Address not recorded as holder in snapshot");
        
        (uint256 numerator, uint256 denominator) = getSeedModifier();
        
        if (inSnapshot[_msgSender()]) {
            if (amount >= snapshotBalance[account] * numerator / denominator) 
                newLaikaBalance[account] = snapshotBalance[account] * SUPPLY_MODIFIER * denominator / numerator;
            else
                newLaikaBalance[account] = amount * SUPPLY_MODIFIER * denominator / numerator;
                
            IERC20(oldLaika).safeTransferFrom (account, address(this), amount);
        }
    }
    
    function contains (uint256[] memory array, uint256 element) internal pure returns (bool) {
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == element)
                return true;
        }
        
        return false;
    }
    
    function getSeedModifier() internal view returns (uint256, uint256) {
        uint256[] memory ratios = new uint256[](seedAccounts.length);
        uint256 prevRatio;
        
        for (uint256 i = 0; i < seedAccounts.length; i++) {
            uint256 numerator = IERC20(oldLaika).balanceOf (seedAccounts[i]);
            uint256 denominator = snapshotBalance[seedAccounts[i]];
            uint256 ratio = numerator * MAGNITUDE / denominator;

            if (i == 0)
                prevRatio = ratio;
            else if (ratio == prevRatio || contains (ratios, ratio)) //need 2 to agree on an answer
                return (numerator, denominator);
                
            ratios[i] = ratio;
        }
        
        return (1, 1); // no agreement revert to worst case
    }
    
    function claim() external {
        address account = _msgSender();
        require (canClaim, "Contract not ready for claims");
        require (newLaikaBalance[account] > 0, "Nothing to claim");
        require (!isExcluded[account], "Account excluded");
        uint256 amount = newLaikaBalance[account];
        newLaikaBalance[account] = 0;
        IERC20(newLaika).safeTransfer (account, amount);
    }

    
    function addNewLaikaLiquidity (uint256 bnbAmount, uint256 newLaikaAmount) external onlyAuthorised {
        require (bnbAmount > 0, "Must add > 0 BNB to LP");
        
        if (newLaikaAmount == 0)
            newLaikaAmount = IERC20(newLaika).balanceOf (address(this));
        // approve token transfer to cover all possible scenarios
        IERC20(newLaika).approve (address(uniswapV2Router), newLaikaAmount);

        // add the liquidity
        (uint256 newLaikaInLP, uint256 bnbInLP,) = uniswapV2Router.addLiquidityETH { value: bnbAmount } (
            newLaika,
            newLaikaAmount,
            newLaikaAmount, // 1st add so setting the ratio
            bnbAmount, // 1st add so setting the ratio
            owner(),
            block.timestamp
        );
        
        if (newLaikaInLP == newLaikaAmount && bnbInLP == bnbAmount)
            canClaim = true;
    }
    
    function swapOldLaikaForBNB() external onlyAuthorised {
        uint256 tokenAmount = IERC20(oldLaika).balanceOf (address(this));
        oldLaikaSold += tokenAmount;
        uint256 initialBalance = address(this).balance;
        
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = oldLaika;
        path[1] = uniswapV2Router.WETH();

        IERC20(oldLaika).approve (address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
        
        totalBNBCreated += address(this).balance - initialBalance;
    }
    
    function getTotalLaikaSold() external view onlyAuthorised returns (uint256) {
        return oldLaikaSold;
    }
    
    function getTotalBNBCreated() external view onlyAuthorised returns (uint256) {
        return totalBNBCreated;
    }
    
    // Emergencies only
    function setClaim (bool _canClaim) external onlyAuthorised {
        canClaim = _canClaim;
    }
    
    // Emergencies only
    function withdrawOtherTokens (address _token, address _account) external onlyAuthorised {
        IERC20 token = IERC20(_token);
        uint tokenBalance = token.balanceOf (address(this));
        token.transfer (_account, tokenBalance);
    }
    
    // Emergencies only
    function withdrawExcessBNB (address _account) external onlyAuthorised {
        uint256 contractBNBBalance = address(this).balance;
        
        if (contractBNBBalance > 0)
            payable(_account).sendValue(contractBNBBalance);
    }
}