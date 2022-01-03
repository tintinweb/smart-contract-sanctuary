/**
 *Submitted for verification at BscScan.com on 2022-01-03
*/

// SPDX-License-Identifier: CC-BY-ND-4.0
pragma solidity 0.8.10;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract IndexVault is IERC20, Ownable {

    /// @title Index Vault
    /// @author Maison Capital

    using SafeERC20 for IERC20;
    using Address for address;

    struct Assets {
        address asset;
        uint256 allocation;
        uint8 route; // 0 - BUSD, 1 - WBNB
    }

    Assets[] private assets;

    uint256 totalAlloc = 10000;

    uint256 minimumMSNAlloc = 1000;
    bool minimumMSN = true;

    string _name;
    string _symbol;
    uint8 _decimals = 18;
    uint256 _totalSupply;
    uint256 _totalUsers;

    uint256 _lastRebalance;

    bool public depositsEnabled;
    bool privateInvestors = true;
    mapping (address => bool) privateInvestor;

    address managerAddress;
    uint256 managerFee = 0;
    uint256 immutable denominator = 1000;

    address immutable MSN = 0x631b92596bc7f5c4537F1a7Cd4CaEF2Db0d3000d;

    IERC20 BUSD = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    IUniswapV2Router02 private router =
        IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);   

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) _canTransfer;

    modifier onlyManager {
        require(_msgSender() == managerAddress || _msgSender() == owner());
        _;
    }

    event DepositSuccessful(address _address, uint256 _amount);
    event WithdrawalSuccessful(address _address, uint256 _amount);
    event ManagerFeeChanged(uint256 newFee);
    event RebalanceSuccessful();

    constructor(
        string memory name_,
        string memory symbol_,
        address _managerAddress,
        address[] memory _tokens,
        uint256[] memory _allocations,
        uint8[] memory _route
    ) {
        _name = name_;
        _symbol = symbol_;
        managerAddress = _managerAddress;
        BUSD.approve(address(router), ~uint256(0));
        IERC20(router.WETH()).approve(address(router), ~uint(0));
        _setTokens(_tokens, _allocations, _route);
        _canTransfer[address(this)] = true;
        depositsEnabled = true;
        _lastRebalance = block.number;
    }

    /// @dev Public and external functions

    function deposit(uint256 amount) external {
        require(depositsEnabled, "Deposits are currently paused");
        if (privateInvestors) {
            require(privateInvestor[_msgSender()] == true);
        }
        uint256 balanceBefore = getTotalValue();
        uint256 currentIndex = 10**18;
        if (balanceBefore != 0) {
            currentIndex = getIndex();
        }
        BUSD.safeTransferFrom(_msgSender(), address(this), amount);
        uint256 wbnbBalanceBefore = IERC20(router.WETH()).balanceOf(address(this));
        swapAssetForWBNB(address(BUSD), amount);
        uint256 wbnbAmount = IERC20(router.WETH()).balanceOf(address(this)) - wbnbBalanceBefore;
        address asset;
        uint256 tokenAmount;
        uint256 alloc;
        for (uint256 i = 0; i < assets.length; i++) {
            asset = assets[i].asset;
            alloc = assets[i].allocation;
            if (alloc > 0) {
                tokenAmount = wbnbAmount * alloc / totalAlloc;
                if (asset != router.WETH()) {
                    swapWBNBforAsset(asset, tokenAmount);
                }
            }
        }
        uint256 balanceAfter = getTotalValue();
        uint256 balanceChange = balanceAfter - balanceBefore;
        uint256 tokensToIssue;
        tokensToIssue = balanceChange * 10**18 / currentIndex;
        _totalSupply += tokensToIssue;
        if (_balances[_msgSender()] == 0) {
             _totalUsers ++;
        }
        _transfer(address(this), _msgSender(), tokensToIssue);
        emit DepositSuccessful(_msgSender(), amount);
    }

    function withdraw(uint256 amount) external {
        require(_balances[_msgSender()] >= amount, "Not enough balance");
        _transfer(_msgSender(), address(this), amount);
        uint256 userShare = amount * 10 ** 18 / _totalSupply; // 10**18 for precision
        _totalSupply -= amount;
        uint256 balanceBefore = IERC20(router.WETH()).balanceOf(address(this));
        address asset;
        uint256 alloc;
        uint256 totalTokens;
        uint256 tokenAmount;
        for (uint256 i = 0; i < assets.length; i++) {
            asset = assets[i].asset;
            alloc = assets[i].allocation;
            if (alloc > 0) {
                totalTokens = IERC20(asset).balanceOf(address(this));       
                tokenAmount = totalTokens * userShare / (10 ** 18);
                if (asset != router.WETH()) {
                    swapAssetForWBNB(asset, tokenAmount);
                } else {
                    balanceBefore -= tokenAmount;
                }
            }
        }
        uint256 totalReceivedWBNB = IERC20(router.WETH()).balanceOf(address(this)) - balanceBefore;
        uint256 busdBalanceBefore = BUSD.balanceOf(address(this));
        swapWBNBforAsset(address(BUSD), totalReceivedWBNB);
        uint256 totalReceived = BUSD.balanceOf(address(this)) - busdBalanceBefore;
        uint256 feeAmount;
        uint256 transferAmount;
        if (managerFee > 0) {
            feeAmount = totalReceived * managerFee / denominator;
            transferAmount = totalReceived - feeAmount;
            BUSD.safeTransfer(_msgSender(), transferAmount);
            BUSD.safeTransfer(managerAddress, feeAmount);
        } else {
            transferAmount = totalReceived;
            BUSD.safeTransfer(_msgSender(), transferAmount);
        }

        if (_balances[_msgSender()] == 0) {
            _totalUsers --;
        }

        emit WithdrawalSuccessful(_msgSender(), amount);
    }

    function getIndex() public view returns (uint256 indexPrice) {
        indexPrice =  getTotalValue() * 10 ** 18 / _totalSupply;
    }

    function getUserBalanceInBUSD(address _address) external view returns (uint256 userBalanceInBUSD) {
        userBalanceInBUSD = getTotalValue() * _balances[_address] / _totalSupply;
    }

    function getVaultInfo() external view returns (address[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256, uint256, uint256) {
        address[] memory _assets = new address[](assets.length);
        uint256[] memory _allocations = new uint256[](assets.length);
        uint256[] memory _amountInBUSD = new uint256[](assets.length);
        uint256[] memory _tokenAmount = new uint256[](assets.length);
        uint256 _TVL = getTotalValue();
        for (uint256 i = 0; i < assets.length; i++) {
            _assets[i] = assets[i].asset;
            _allocations[i] = assets[i].allocation;
            _amountInBUSD[i] = _getTokenPrice(i, IERC20(_assets[i]).balanceOf(address(this)));
            _tokenAmount[i] = IERC20(_assets[i]).balanceOf(address(this));
        }
        return (_assets, _allocations, _amountInBUSD, _tokenAmount, _TVL, _totalUsers, _lastRebalance);
    }

    function isInPrivate(address _address) external view returns (bool) {
        return privateInvestor[_address];
    }

    /// @dev onlyManager

    function rebalance(uint256[] memory _allocations) external onlyManager {
        require(_allocations.length == assets.length, "Incorrect length");
        require(checkTotalAllocation(_allocations), "Total Allocation is not 10000");
        uint256 len = assets.length;
        address asset;
        uint256 tokenAmount;
        for (uint256 i = 0; i < len; i++) {
            asset = assets[i].asset;
            tokenAmount = assets[i].allocation;
            if (asset != router.WETH() && tokenAmount > 0) {
                swapAssetForWBNB(asset, IERC20(asset).balanceOf(address(this)));
            }
            assets[i].allocation = _allocations[i];
            if (asset == address(MSN)) {
                require(assets[i].allocation >= minimumMSNAlloc, "Minimum MSN");
            }
        }

        uint256 WBNBPerUnit = IERC20(router.WETH()).balanceOf(address(this)) / totalAlloc; 
        for (uint256 i = 0; i < len; i++) {
            asset = assets[i].asset;
            tokenAmount = assets[i].allocation * WBNBPerUnit;
            if (asset != router.WETH() && tokenAmount > 0) {
                swapWBNBforAsset(asset, tokenAmount);
            }
        }

        _lastRebalance = block.number;
        emit RebalanceSuccessful();
    }

    /// @dev onlyOwner

    function setManagerAddress(address _address) external onlyOwner {
        managerAddress = _address;
    }

    function changeManagerFee(uint256 _newFee) external onlyOwner {
        managerFee = _newFee;
    }

    function setTransferToAddress(address _address, bool _value) external onlyOwner {
        _canTransfer[_address] = _value;
    }

    function setMinimumMSN(bool _value, uint256 _allocation) external onlyOwner {
        minimumMSN = _value;
        minimumMSNAlloc = _allocation;
    }

    function changeRouterAddress(address _router) external onlyOwner {
        router = IUniswapV2Router02(_router);
    }

    function setDeposits(bool _value) external onlyOwner {
        depositsEnabled = _value;
    }

    function setPrivate(bool _value) external onlyOwner {
        privateInvestors = _value;
    }

    function addPrivate(address[] memory _address, bool _value) external onlyOwner {
        for (uint256 i = 0; i< _address.length; i++) {
            _setPrivateInvestor(_address[i], _value);
        }
    }

    function recover() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function closeVault() external onlyOwner {
        for (uint256 i = 0; i < assets.length; i++){
            if (IERC20(assets[i].asset).balanceOf(address(this)) > 0) {
                revert("Funds are still locked");
            }
        }
        selfdestruct(payable(owner()));
    }

    function emergencyRecover(IERC20 _token) external onlyOwner {
        _token.safeTransfer(owner(), _token.balanceOf(address(this)));
    }

    function resetApprove() external onlyOwner {
        _resetApprove();
    }

    /// @dev Internal Functions

    function getTotalValue() internal view returns (uint256 totalValue) {
        uint256 tokenAmount;
        for (uint256 i = 0; i < assets.length; i++) {
            tokenAmount = IERC20(assets[i].asset).balanceOf(address(this));
            totalValue += _getTokenPrice(i, tokenAmount);
        }
    }

    function _getTokenPrice(uint256 index, uint256 tokenAmount) internal view returns (uint256) {
        address asset = assets[index].asset;
        uint8 _route = assets[index].route;
        uint256 value;
        if (_route == 0) {
            value = getPriceOfAsset(asset, tokenAmount); 
        } else if (_route == 1) {
            uint256 valueBNB = getPriceOfAssetInBNB(asset, tokenAmount);
            value = getPriceOfAsset(router.WETH(), valueBNB);
        }
        return value;
    }

    function _setTokens(address[] memory _tokens, uint256[] memory _allocations, uint8[] memory _route) internal {
        require(_tokens.length == _allocations.length, "Input Error: Lengths mismatch");

        require(checkTotalAllocation(_allocations));
        
        for (uint256 i = 0; i < _tokens.length; i ++) {
            assets.push(Assets({
                asset: _tokens[i],
                allocation: _allocations[i],
                route: _route[i]
            }));
            if (_tokens[i] == address(MSN)) {
                require(_allocations[i] >= minimumMSNAlloc, "Minimum MSN alloc");
            }
            IERC20(_tokens[i]).approve(address(router), ~uint256(0));
        }
    }

    function _setPrivateInvestor(address _address, bool _value) internal {
        privateInvestor[_address] = _value;
    }

    function checkTotalAllocation(uint256[] memory _allocations) internal view returns (bool) {
        uint256 total;
        for (uint256 i = 0; i < _allocations.length; i++) {
            total += _allocations[i];
        } 
        if (total == totalAlloc) {
            return true;
        } else {
            return false;
        }
    }

    function swapTokenForAsset(address asset, uint256 tokenAmount) internal {
        address[] memory path = new address[](3);
        path[0] = address(BUSD);
        path[1] = router.WETH();
        path[2] = asset;

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapAssetForToken(address asset, uint256 tokenAmount) internal {
        address[] memory path = new address[](3);
        path[0] = asset;
        path[1] = router.WETH();
        path[2] = address(BUSD);

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapAssetForWBNB(address asset, uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = asset;
        path[1] = router.WETH();

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function swapWBNBforAsset(address asset, uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = asset;

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function getPriceOfAssetInBNB(address asset, uint256 tokenAmount) internal view returns (uint256) {
            // returns how many BNB for AMOUNT token
        address pairAddress = IUniswapV2Factory(router.factory()).getPair(router.WETH(), asset);

        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        (uint256 Res0, uint256 Res1, ) = pair.getReserves();

        if (pair.token0() == router.WETH()) {
            return ((tokenAmount * Res0) / Res1); // return amount of token0 needed to buy token1
        } else {
            return ((tokenAmount * Res1) / Res0); // return amount of token0 needed to buy token1
        }
    }

    function getPriceOfAsset(address asset, uint256 tokenAmount) internal view returns (uint256) {
            // returns how many BUSD for AMOUNT token
        address pairAddress = IUniswapV2Factory(router.factory()).getPair(address(BUSD), asset);

        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        (uint256 Res0, uint256 Res1, ) = pair.getReserves();

        if (pair.token0() == address(BUSD)) {
            return ((tokenAmount * Res0) / Res1); // return amount of token0 needed to buy token1
        } else {
            return ((tokenAmount * Res1) / Res0); // return amount of token0 needed to buy token1
        }
    }

    function _resetApprove() internal {
        for (uint256 i = 0; i < assets.length; i++) {
            IERC20(assets[i].asset).approve(address(router), ~uint256(0));
        }
    }

    /// @dev TOKEN functions

    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function decimals() external view returns (uint8){
        return _decimals;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(address _from, address _to, uint256 _amount) internal {
        require(_canTransfer[_from] || _canTransfer[_to], "Cannot transfer token to this address");
        if (_from == address(this)) {
            _balances[_to] += _amount;
            emit Transfer(address(0), _to, _amount);
        } else if (_to == address(this)) {
            _balances[_from] -= _amount;
            emit Transfer(_from, address(0), _amount);
        } else {
            _balances[_from] -= _amount;
            _balances[_to] += _amount;
            emit Transfer(_from, _to, _amount);
        }

    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    receive() external payable{}

}