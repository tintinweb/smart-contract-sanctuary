/**
 *Submitted for verification at BscScan.com on 2021-11-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

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
        return msg.data;
    }
}

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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

interface IPinkAntiBot {
    function setTokenOwner(address owner) external;

    function onPreTransferCheck(
      address from,
      address to,
      uint256 amount
    ) external;
}

contract RLOKI is Ownable, IERC20 {
    string private _name = "Floki Rocket";
    string private _symbol = "RLOKI";

    uint256 public marketingFeeBPS = 500;
    uint256 public liquidityFeeBPS = 300;
    uint256 public dividendFeeBPS = 400;
    uint256 public totalFeeBPS = 1200;

    uint256 public swapTokensAtAmount = 10000000 * (10**18);
    uint256 public lastSwapTime;

    bool public swapEnabled = true;
    bool public taxEnabled = true;
    bool public compoundingEnabled = true;

    uint256 private _totalSupply;
    bool private swapping;

    address public marketingWallet;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public automatedMarketMakerPairs;

    event SwapAndAddLiquidity(uint256 tokensSwapped, uint256 nativeReceived, uint256 tokensIntoLiquidity);
    event SendDividends(uint256 tokensSwapped, uint256 amount);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);
    event SwapEnabled(bool enabled);
    event TaxEnabled(bool enabled);
    event CompoundingEnabled(bool enabled);

    DividendTracker public dividendTracker;
    IUniswapV2Router02 public uniswapV2Router;
    
    address public uniswapV2Pair;

    IPinkAntiBot public pinkAntiBot;
    bool public antiBotEnabled;

    uint256 public maxTxBPS = 75;
    uint256 public maxWalletBPS = 175;

    bool public maxTxEnabled = true;
    bool public maxWalletEnabled = true;

    mapping(address => bool) private _isExcludedFromMaxTx;
    mapping(address => bool) private _isExcludedFromMaxWallet;

    address public constant BUSD = address(0xE0dFffc2E01A7f051069649aD4eb3F518430B6a4);

    constructor() {

        dividendTracker = new DividendTracker(address(this));

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0xCc7aDc94F3D80127849D2b41b6439b7CF1eB4Ae0);

        address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = _uniswapV2Pair;
        
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);

        dividendTracker.excludeFromDividends(address(dividendTracker), true);
        dividendTracker.excludeFromDividends(address(this), true);
        dividendTracker.excludeFromDividends(owner(), true);
        dividendTracker.excludeFromDividends(address(_uniswapV2Router), true);

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(dividendTracker), true);

        excludeFromMaxTx(owner(), true);
        excludeFromMaxTx(address(this), true);
        excludeFromMaxTx(address(dividendTracker), true);

        excludeFromMaxWallet(owner(), true);
        excludeFromMaxWallet(address(this), true);
        excludeFromMaxWallet(address(dividendTracker), true);

        _mint(owner(), 1000000000000 * (10**18));

        // pinkAntiBot = IPinkAntiBot(0x8EFDb3b642eb2a20607ffe0A56CFefF6a95Df002);
        // pinkAntiBot.setTokenOwner(msg.sender);
        antiBotEnabled = false;
    }

    receive() external payable {

    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }    
    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }    

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "RLOKI: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "RLOKI: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }    

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "RLOKI: transfer from the zero address");
        require(recipient != address(0), "RLOKI: transfer to the zero address");
        if(antiBotEnabled) {
            pinkAntiBot.onPreTransferCheck(sender, recipient, amount);
        }

        if(sender == address(uniswapV2Pair) && recipient != address(uniswapV2Router)) {
            // check the max tx, unless sender or recipient excluded
            if(maxTxEnabled && !_isExcludedFromMaxTx[sender] && !_isExcludedFromMaxTx[recipient]) {
                uint256 maxTx = totalSupply() * maxTxBPS / 10000;
                require(amount <= maxTx, "anti-whale max tx enforced");
            }

            // check the max wallet size, unless sender or recipient excluded
            if(maxWalletEnabled && !_isExcludedFromMaxWallet[sender] && !_isExcludedFromMaxWallet[recipient]) {
                uint256 maxWallet = totalSupply() * maxWalletBPS / 10000;
                require((balanceOf(recipient) + amount) <= maxWallet, "anti-whale max wallet enforced");
            }
        }

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "RLOKI: transfer amount exceeds balance");

        uint256 contractTokenBalance = balanceOf(address(this));
        uint256 contractNativeBalance = address(this).balance;

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(swapEnabled &&
            canSwap &&
            !swapping &&
            !automatedMarketMakerPairs[sender] && // no swap on remove liquidity step 1 or DEX buy
            sender != address(uniswapV2Router) && // no swap on remove liquidity step 2
            sender != owner() &&
            recipient != owner()
        ) {
            swapping = true;

            _executeSwap(contractTokenBalance, contractNativeBalance);

            lastSwapTime = block.timestamp;
            swapping = false;
        }

        bool takeFee;

        if(sender == address(uniswapV2Pair) || recipient == address(uniswapV2Pair)) {
            takeFee = true;
        }

        if(_isExcludedFromFees[sender] || _isExcludedFromFees[recipient]) {
            takeFee = false;
        }

        if(swapping || !taxEnabled) {
            takeFee = false;
        }

        if(takeFee) {
            uint256 fees = amount * totalFeeBPS / 10000;
            amount -= fees;
            _executeTransfer(sender, address(this), fees);
        }

        _executeTransfer(sender, recipient, amount);

        dividendTracker.setBalance(payable(sender), balanceOf(sender));
        dividendTracker.setBalance(payable(recipient), balanceOf(recipient));
    }

    function _executeTransfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "RLOKI: transfer from the zero address");
        require(recipient != address(0), "RLOKI: transfer to the zero address");
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "RLOKI: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);       
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "RLOKI: approve from the zero address");
        require(spender != address(0), "RLOKI: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _mint(address account, uint256 amount) private {
        require(account != address(0), "RLOKI: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) private {
        require(account != address(0), "RLOKI: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "RLOKI: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function swapTokensForNative(uint256 tokens) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokens);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokens,
            0, // accept any amount of native
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokens, uint256 native) private {
        _approve(address(this), address(uniswapV2Router), tokens);
        uniswapV2Router.addLiquidityETH{value: native}(
            address(this),
            tokens,
            0, // slippage unavoidable
            0, // slippage unavoidable
            address(0), // no one gets the liquidity tokens, its locked
            block.timestamp
        );
    }

    function _executeSwap(uint256 tokens, uint256 native) private {

        if(tokens <= 0) {
            return;
        }

        uint256 swapTokensMarketing;
        if(address(marketingWallet) != address(0)) {
            swapTokensMarketing = tokens * marketingFeeBPS / totalFeeBPS;
        }

        uint256 swapTokensDividends;
        if(dividendTracker.totalSupply() > 0) {
            swapTokensDividends = tokens * dividendFeeBPS / totalFeeBPS;
        }

        uint256 tokensForLiquidity = tokens - swapTokensMarketing - swapTokensDividends;
        uint256 swapTokensLiquidity = tokensForLiquidity / 2;
        uint256 addTokensLiquidity = tokensForLiquidity - swapTokensLiquidity;
        uint256 swapTokensTotal = swapTokensMarketing + swapTokensDividends + swapTokensLiquidity;

        uint256 initNativeBal = address(this).balance;
        swapTokensForNative(swapTokensTotal);
        uint256 nativeSwapped = (address(this).balance - initNativeBal) + native;

        uint256 nativeMarketing = nativeSwapped * swapTokensMarketing / swapTokensTotal;
        uint256 nativeDividends = nativeSwapped * swapTokensDividends / swapTokensTotal;
        uint256 nativeLiquidity = nativeSwapped - nativeMarketing - nativeDividends;

        if(nativeMarketing > 0) {
            payable(marketingWallet).transfer(nativeMarketing);
        }

        addLiquidity(addTokensLiquidity, nativeLiquidity);
        emit SwapAndAddLiquidity(swapTokensLiquidity, nativeLiquidity, addTokensLiquidity);

        if(nativeDividends > 0) {
            (bool success, ) = address(dividendTracker).call{value: nativeDividends}("");
            if(success) {
                emit SendDividends(swapTokensDividends, nativeDividends);
            }
        }
    }    

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "RLOKI: account is already set to requested state");
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function isExcludedFromFees(address account) public view returns (bool) {
      return _isExcludedFromFees[account];
    }

    function excludeFromDividends(address account, bool excluded) public onlyOwner {
        dividendTracker.excludeFromDividends(account, excluded);
    }

    function isExcludedFromDividends(address account) public view returns (bool) {
        return dividendTracker.isExcludedFromDividends(account);
    }

    function setMarketingWallet(address payable wallet) external onlyOwner {
        marketingWallet = wallet;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != uniswapV2Pair, "RLOKI: DEX pair can not be removed");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "RLOKI: automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        if(value) {
            dividendTracker.excludeFromDividends(pair, true);
        }
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        require(newAddress != address(uniswapV2Router), "RLOKI: the router is already set to the new address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
          .createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
    }

    function claim() public {
        dividendTracker.processAccount(payable(_msgSender()));
    }

    function compound() public {
        require(compoundingEnabled, "RLOKI: compounding is not enabled");
        dividendTracker.compoundAccount(payable(_msgSender()));
    }

    function withdrawableDividendOf(address account) public view returns (uint256) {
        return dividendTracker.withdrawableDividendOf(account);
    }    

    function withdrawnDividendOf(address account) public view returns (uint256) {
        return dividendTracker.withdrawnDividendOf(account);
    }

    function accumulativeDividendOf(address account) public view returns (uint256) {
        return dividendTracker.accumulativeDividendOf(account);
    }

    function getAccountInfo(address account) public view returns (address, uint256, uint256, uint256) {
        return dividendTracker.getAccountInfo(account);
    }

    function getLastClaimTime(address account) public view returns (uint256) {
        return dividendTracker.getLastClaimTime(account);
    }

    function setSwapEnabled(bool _enabled) external onlyOwner () {
        swapEnabled = _enabled;
        emit SwapEnabled(_enabled);
    }

    function setTaxEnabled(bool _enabled) external onlyOwner () {
        taxEnabled = _enabled;
        emit TaxEnabled(_enabled);
    }

    function setCompoundingEnabled(bool _enabled) external onlyOwner () {
        compoundingEnabled = _enabled;
        emit CompoundingEnabled(_enabled);
    }

    function setEnabledAntiBot(bool _enabled) external onlyOwner () {
        antiBotEnabled = _enabled;
    }

    function setMaxTxEnabled(bool _enabled) external onlyOwner () {
        maxTxEnabled = _enabled;
    }

    function setMaxTxBPS(uint256 bps) external onlyOwner () {
        require(bps >= 75 && bps <= 10000, "BPS must be between 75 and 10000");
        maxTxBPS = bps;
    }

    function excludeFromMaxTx(address account, bool excluded) public onlyOwner () {
        _isExcludedFromMaxTx[account] = excluded;
    }

    function isExcludedFromMaxTx(address account) public view returns (bool) {
        return _isExcludedFromMaxTx[account];
    }

    function setMaxWalletEnabled(bool _enabled) external onlyOwner () {
        maxWalletEnabled = _enabled;
    }

    function setMaxWalletBPS(uint256 bps) external onlyOwner () {
        require(bps >= 175 && bps <= 10000, "BPS must be between 175 and 10000");
        maxWalletBPS = bps;
    }

    function excludeFromMaxWallet(address account, bool excluded) public onlyOwner () {
        _isExcludedFromMaxWallet[account] = excluded;
    }

    function isExcludedFromMaxWallet(address account) public view returns (bool) {
        return _isExcludedFromMaxWallet[account];
    }    
}

contract DividendTracker is Ownable, IERC20 {
    string private _name = "RLOKI_DividendTracker";
    string private _symbol = "RLOKI_DividendTracker";  

    uint256 public lastProcessedIndex;

    uint256 private _totalSupply;
    mapping (address => uint256) private _balances;

    uint256 constant private magnitude = 2**128;
    uint256 public immutable minTokenBalanceForDividends;
    uint256 private magnifiedDividendPerShare;
    uint256 public totalDividendsDistributed;
    uint256 public totalDividendsWithdrawn;
    
    address public tokenAddress;

    mapping (address => bool) public excludedFromDividends;
    mapping (address => int256) private magnifiedDividendCorrections;
    mapping (address => uint256) private withdrawnDividends;
    mapping (address => uint256) private lastClaimTimes;

    event DividendsDistributed(address indexed from, uint256 weiAmount);
    event DividendWithdrawn(address indexed to, uint256 weiAmount);
    event ExcludeFromDividends(address indexed account, bool excluded);
    event Claim(address indexed account, uint256 amount);
    event Compound(address indexed account, uint256 amount, uint256 tokens);

    struct AccountInfo {
        address account;
        uint256 withdrawableDividends;
        uint256 totalDividends;
        uint256 lastClaimTime;
    }

    constructor(address _tokenAddress) {
        minTokenBalanceForDividends = 2500000 * (10**18);
        tokenAddress = _tokenAddress;
    }

    receive() external payable {
        distributeDividends();
    }

    function distributeDividends() public payable {
        require(_totalSupply > 0);
        if(msg.value > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare + ((msg.value * magnitude) / _totalSupply);
            emit DividendsDistributed(msg.sender, msg.value);
            totalDividendsDistributed += msg.value;
        }
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner {
        if(excludedFromDividends[account]) {
            return;
        }
        if(newBalance >= minTokenBalanceForDividends) {
            _setBalance(account, newBalance);
        } else {
            _setBalance(account, 0);
        }
    }

    function excludeFromDividends(address account, bool excluded) external onlyOwner {
        require(excludedFromDividends[account] != excluded, "RLOKI_DividendTracker: account already set to requested state");
        excludedFromDividends[account] = excluded;
        if(excluded) {
            _setBalance(account, 0);
        } else {
            uint256 newBalance = IERC20(tokenAddress).balanceOf(account);
            if(newBalance >= minTokenBalanceForDividends) {
                _setBalance(account, newBalance);
            } else {
                _setBalance(account, 0);
            }
        }
        emit ExcludeFromDividends(account, excluded);
    }

    function isExcludedFromDividends(address account) public view returns (bool) {
        return excludedFromDividends[account];
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = _balances[account];
        if(newBalance > currentBalance) {
            uint256 addAmount = newBalance - currentBalance;
            _mint(account, addAmount);
        } else if(newBalance < currentBalance) {
            uint256 subAmount = currentBalance - newBalance;
            _burn(account, subAmount);
        }
    }

    function _mint(address account, uint256 amount) private {
        require(account != address(0), "RLOKI_DividendTracker: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
          - int256(magnifiedDividendPerShare * amount);
    }

    function _burn(address account, uint256 amount) private {
        require(account != address(0), "RLOKI_DividendTracker: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "RLOKI_DividendTracker: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account]
          + int256(magnifiedDividendPerShare * amount);    
    }

    function processAccount(address payable account) public onlyOwner returns (bool) {
        uint256 amount = _withdrawDividendOfUser(account);
        if(amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount);
            return true;
        }
        return false;
    }

    function _withdrawDividendOfUser(address payable account) private returns (uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(account);
        if(_withdrawableDividend > 0) {
            withdrawnDividends[account] += _withdrawableDividend;
            totalDividendsWithdrawn += _withdrawableDividend;
            emit DividendWithdrawn(account, _withdrawableDividend);
            (bool success, ) = account.call{value: _withdrawableDividend, gas: 3000}("");
            if(!success) {
                withdrawnDividends[account] -= _withdrawableDividend;
                totalDividendsWithdrawn -= _withdrawableDividend;
                return 0;
            }
            return _withdrawableDividend;
        }
        return 0;
    }

    function compoundAccount(address payable account) public onlyOwner returns (bool) {
        (uint256 amount, uint256 tokens) = _compoundDividendOfUser(account);
        if(amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Compound(account, amount, tokens);
            return true;
        }
        return false;
    }

    function _compoundDividendOfUser(address payable account) private returns (uint256, uint256) {
        uint256 _withdrawableDividend = withdrawableDividendOf(account);
        if(_withdrawableDividend > 0) {
            withdrawnDividends[account] += _withdrawableDividend;
            totalDividendsWithdrawn += _withdrawableDividend;
            emit DividendWithdrawn(account, _withdrawableDividend);

            IUniswapV2Router02 uniswapV2Router = IUniswapV2Router02(0xCc7aDc94F3D80127849D2b41b6439b7CF1eB4Ae0);

            address[] memory path = new address[](2);
            path[0] = uniswapV2Router.WETH();            
            path[1] = address(tokenAddress);

            bool success;
            uint256 tokens;

            uint256 initTokenBal = IERC20(tokenAddress).balanceOf(account);
            try uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: _withdrawableDividend}(
              0,
              path,
              address(account),
              block.timestamp
            ) {
              success = true;
              tokens = IERC20(tokenAddress).balanceOf(account) - initTokenBal;
            } catch Error(string memory /*err*/) {
              success = false;
            }

            if(!success) {
                withdrawnDividends[account] -= _withdrawableDividend;
                totalDividendsWithdrawn -= _withdrawableDividend;
                return (0, 0);
            }            

            return (_withdrawableDividend, tokens);
        }
        return (0, 0);
    }

    function withdrawableDividendOf(address account) public view returns (uint256) {
        return accumulativeDividendOf(account) - withdrawnDividends[account];
    }

    function withdrawnDividendOf(address account) public view returns (uint256) {
        return withdrawnDividends[account];
    }

    function accumulativeDividendOf(address account) public view returns (uint256) {
        int256 a = int256(magnifiedDividendPerShare * balanceOf(account));
        int256 b = magnifiedDividendCorrections[account]; // this is an explicit int256 (signed)
        return uint256(a + b) / magnitude;
    }

    function getAccountInfo(address account) public view returns (address, uint256, uint256, uint256) {
        AccountInfo memory info;
        info.account = account;
        info.withdrawableDividends = withdrawableDividendOf(account);
        info.totalDividends = accumulativeDividendOf(account);
        info.lastClaimTime = lastClaimTimes[account];
        return (
            info.account,
            info.withdrawableDividends,
            info.totalDividends,
            info.lastClaimTime
        );
    }

    function getLastClaimTime(address account) public view returns (uint256) {
        return lastClaimTimes[account];
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address, uint256) public pure override returns (bool) {
        revert("RLOKI_DividendTracker: method not implemented");
    }

    function allowance(address, address) public pure override returns (uint256) {
        revert("RLOKI_DividendTracker: method not implemented");
    }

    function approve(address, uint256) public pure override returns (bool) {
        revert("RLOKI_DividendTracker: method not implemented");
    }

    function transferFrom(address, address, uint256) public pure override returns (bool) {
        revert("RLOKI_DividendTracker: method not implemented");
    }
}