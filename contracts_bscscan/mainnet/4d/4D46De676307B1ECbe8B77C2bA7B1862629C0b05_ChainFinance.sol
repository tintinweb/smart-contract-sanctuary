/**
 *Submitted for verification at BscScan.com on 2021-12-18
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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

contract ChainFinance is IBEP20, Ownable {

    using Address for address;

    // Modifiers
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    bool private inSwapAndLiquify = false;

    // Events
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 BNBReceived,
        uint256 tokensIntoLiqudity
    );
    event MarketingWalletPaid(uint256 tokensSwapped);
    event TokensBurned(uint256 amount);
    event TaxUpdated(string taxType, uint256 taxAmount);
    event MaxHoldUpdated(uint256 maxHold);

    // Constants
    uint8 private _decimals = 18;
    uint256 private _totalSupply = 100 * 10**6 * 10**_decimals; // The total supply of tokens 1,000,000,000
    string private _symbol = "CHF";
    string private _name = "Chain Finance";

    // Taxes

    // Buy fees in %
    uint256 private _liquidityFeeBuy = 3;
    uint256 private _marketingFeeBuy = 6;

    // Sell fees in %
    uint256 private _liquidityFeeSell = 5;
    uint256 private _marketingFeeSell = 9;
    uint256 private _burnFeeSell = 4;

    // Addresses and contracts
    address private _marketingWallet;
    address private _deadAddress = 0x000000000000000000000000000000000000dEaD;
    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;

    // Mappings
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcludedFromMaxHold;
    mapping (address => bool) private _isMarketMakerPair;
    mapping (address => bool) public isBlacklisted;

    // Limits
    uint256 private _maxHoldAmount = (_totalSupply * 3) / 1000; // 0.3% of total supply
    uint256 private _numTokensSellToAddToLiquidity = _totalSupply / 1000; // 0.1% of total supply
    uint256 private _maxGasPrice = 10000000000;

    // Tracking
    bool public swapAndLiquifyEnabled = true;
    uint256 private _tradingEnabledBlock;
    uint256 private _liquidityTokensPooled = 0;
    uint256 private _marketingTokensPooled = 0;
    bool private _tradingEnabled = false;

    constructor(address _uniswapV2RouterAddr, address marketingWallet) {

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);

        _marketingWallet = marketingWallet;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_uniswapV2RouterAddr);

         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        addMarketMakerPair(uniswapV2Pair);

        // Set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        // Exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        // Exclude functional accounts from max hold
        _isExcludedFromMaxHold[owner()] = true;
        _isExcludedFromMaxHold[address(this)] = true;
        _isExcludedFromMaxHold[address(0)] = true;
        _isExcludedFromMaxHold[_deadAddress] = true;

    }

    //to recieve BNB from uniswapV2Router when swaping
    receive() external payable {}

    /**
    * @dev Returns the bep token owner.
    */
    function getOwner() external view override returns (address) {
        return owner();
    }

    /**
    * @dev Returns the token decimals.
    */
    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    /**
    * @dev Returns the token symbol.
    */
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /**
    * @dev Returns the token name.
    */
    function name() external view override returns (string memory) {
        return _name;
    }

    /**
    * @dev See {BEP20-totalSupply}.
    */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
    * @dev See {BEP20-balanceOf}.
    */
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @notice Enable trading and keep track of the block we enabled on
    */
    function enableTrading() external onlyOwner {
        _tradingEnabledBlock = block.number;
        _tradingEnabled = true;
    }

    /**
     * @notice Adds a market maker pair (these are used for deciding when to apply taxes)
     *
     * @param pair The pair to tax
     */
    function addMarketMakerPair(address pair) public onlyOwner {
        _isExcludedFromMaxHold[pair] = true;
        _isMarketMakerPair[pair] = true;
    }

    /**
     * @notice updates the burn tax on sells
     *
     * @param newBurnFeeSell The new fee
     */
    function updateBurnFeeSell(uint256 newBurnFeeSell) external onlyOwner {
        require(newBurnFeeSell < 10, 'updateBurnFeeSell(): Tax too high!');
        _burnFeeSell = newBurnFeeSell;
        emit TaxUpdated("burnFeeSell", newBurnFeeSell);
    }

    /**
     * @notice updates the marketing tax on sells
     *
     * @param newMarketingFeeSell The new fee
     */
    function updateMarketingFeeSell(uint256 newMarketingFeeSell) external onlyOwner {
        require(newMarketingFeeSell < 10, 'updateMarketingFeeSell(): Tax too high!');
        _marketingFeeSell = newMarketingFeeSell;
        emit TaxUpdated("marketingFeeSell", newMarketingFeeSell);
    }

    /**
     * @notice updates the liqduity tax on sells
     *
     * @param newLiquidityFeeSell The new fee
     */
    function updateLiquidityFeeSell(uint256 newLiquidityFeeSell) external onlyOwner {
        require(newLiquidityFeeSell < 10, 'updateLiquidityFeeSell(): Tax too high!');
        _liquidityFeeSell = newLiquidityFeeSell;
        emit TaxUpdated("liquidityFeeSell", newLiquidityFeeSell);
    }

    /**
     * @notice updates the liqduity tax on buys
     *
     * @param newLiquidityFeeBuy The new fee
     */
    function updateLiquidityFeeBuy(uint256 newLiquidityFeeBuy) external onlyOwner {
        require(newLiquidityFeeBuy < 10, 'updateLiquidityFeeBuy(): Tax too high!');
        _liquidityFeeBuy = newLiquidityFeeBuy;
        emit TaxUpdated("liquidityFeeBuy", newLiquidityFeeBuy);
    }

    /**
     * @notice updates the marketing tax on buys
     *
     * @param newMarketingFeeBuy The new fee
     */
    function updateMarketingFeeBuy(uint256 newMarketingFeeBuy) external onlyOwner {
        require(newMarketingFeeBuy < 10, 'updateMarketingFeeBuy(): Tax too high!');
        _marketingFeeBuy = newMarketingFeeBuy;
        emit TaxUpdated("marketingFeeBuy", newMarketingFeeBuy);
    }

    /**
     * @notice updates the max amount of tokens a wallet can hold
     *
     * @param newMaxHoldAmount The new max hold
     */
    function updateMaxHoldAmount(uint256 newMaxHoldAmount) external onlyOwner {
        require(newMaxHoldAmount > 0, 'updateMaxHoldAmount(): Max hold must be greater than 0!');
        _maxHoldAmount = newMaxHoldAmount;
        emit MaxHoldUpdated(newMaxHoldAmount);
    }

        /**
     * @notice Set whether or not an address is blacklisted
     *
     * @param addr The address to modify
     * @param _isBlacklisted Whether or not the address is blacklisted
     */
    function setIsBlacklisted(address addr, bool _isBlacklisted) external onlyOwner {
        isBlacklisted[addr] = _isBlacklisted;
    }

    /**
     * @notice Update the marketing wallet (in case of a breach)
     *
     * @param wallet The address of the new marketing wallet
     */
    function updateMarketingWallet(address wallet) external onlyOwner {
        _marketingWallet = wallet;
    }

    /**
     * @notice Exclude an account from the max hold restriction
     *
     * @param account The address of the account to exclude
     */
    function excludeFromMaxHold(address account) external onlyOwner {
        _isExcludedFromMaxHold[account] = true;
    }

    /**
     * @notice Exclude an address from transaction fees (Can only be executed by the contract owner)
     *
     * @param account the address of the account to exclude
     */
    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    /**
     * @notice Include an address in transaction fees (Can only be executed by the contract owner)
     *
     * @param account the address of the account to include
     */
    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    /**
     * @notice Toggle liquidity generation
     *
     * @param value A boolean representing if liquidity generation is enabled or not
     */
    function setSwapAndLiquifyEnabled(bool value) external onlyOwner {
        swapAndLiquifyEnabled = value;
        emit SwapAndLiquifyEnabledUpdated(value);
    }

    /**
     * @notice Update the maxmimum gas price a transaction can use without being blacklisted
     *
     * @param newMaxGasPrice the new gas limit in wei
     */
    function updateMaxGasPrice(uint256 newMaxGasPrice) external onlyOwner {
        require(newMaxGasPrice > 5000000000, 'updateMaxGasPrice(): Max gas price must be greater than 5000000000!');
        _maxGasPrice = newMaxGasPrice;
    }

    /**
     * @notice Calculate a percentage cut of an amount
     *
     * @param amount The amount of tokensSwapped
     * @param fee The fee in % i.e. 5% would be 5
     * @return The percentage amount of the tokens
     */
    function _calculateFee(uint256 amount, uint256 fee) internal pure returns (uint256) {
        return (amount * fee) / 100;
    }


    /**
    * @dev See {BEP20-transfer}.
    *
    * Requirements:
    *
    * - `recipient` cannot be the zero address.
    * - the caller must have a balance of at least `amount`.
    */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
    * @dev See {BEP20-allowance}.
    */
    function allowance(address owner, address spender) external override view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
    * @dev See {BEP20-approve}.
    *
    * Requirements:
    *
    * - `spender` cannot be the zero address.
    */
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
    * @dev See {BEP20-transferFrom}.
    *
    * Emits an {Approval} event indicating the updated allowance. This is not
    * required by the EIP. See the note at the beginning of {BEP20};
    *
    * Requirements:
    * - `sender` and `recipient` cannot be the zero address.
    * - `sender` must have a balance of at least `amount`.
    * - the caller must have allowance for `sender`'s tokens of at least
    * `amount`.
    */
    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    /**
   * @dev Atomically increases the allowance granted to `spender` by the caller.
   *
   * This is an alternative to {approve} that can be used as a mitigation for
   * problems described in {BEP20-approve}.
   *
   * Emits an {Approval} event indicating the updated allowance.
   *
   * Requirements:
   *
   * - `spender` cannot be the zero address.
    */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
    * @dev Atomically decreases the allowance granted to `spender` by the caller.
    *
    * This is an alternative to {approve} that can be used as a mitigation for
    * problems described in {BEP20-approve}.
    *
    * Emits an {Approval} event indicating the updated allowance.
    *
    * Requirements:
    *
    * - `spender` cannot be the zero address.
    * - `spender` must have allowance for the caller of at least
    * `subtractedValue`.
    */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    /**
     * @notice Remove tokens from supply
     *
     * @param tokenAmount The amount of tokens to be burned
     */
    function burnTokens(uint256 tokenAmount) private {
        _totalSupply -= tokenAmount;
        emit TokensBurned(tokenAmount);
    }

    /**
     * @notice Sell tokens into BNB and send to a specified address
     *
     * @param tokenAmount The amount of chf to sell
     * @param to The address of the recipient
     */
    function _swapTokensForBNB(uint256 tokenAmount, address to) private {

        // generate the uniswap pair path of token -> wBNB
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            to,
            block.timestamp
        );

    }

    /**
     * @notice Add liquidity to the token on pancake swap
     *
     * @param tokenAmount The amount of chf to pair
     * @param BNBAmount The amount of BNB to pair
     */
    function _addLiquidity(uint256 tokenAmount, uint256 BNBAmount) private {

        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: BNBAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );

    }

    /**
     * @notice Sell tokens into BNB and pair with chain finance for liquidity and pay marketing wallet
     *
     * @param tokenAmount the amount of stadnard tokens to be distributed
     */
    function _swapAndLiquify(uint256 tokenAmount) private lockTheSwap {

        uint256 liquidityCut = (_liquidityTokensPooled * tokenAmount) / (_liquidityTokensPooled + _marketingTokensPooled);
        if (liquidityCut > _liquidityTokensPooled) { liquidityCut = _liquidityTokensPooled; }

        uint256 marketingCut = tokenAmount - liquidityCut;
        if (marketingCut > _marketingTokensPooled) { marketingCut = _marketingTokensPooled; }

        // Update pools
        _liquidityTokensPooled -= liquidityCut;
        _marketingTokensPooled -= marketingCut;

        // split the contract balance into halves
        uint256 half = liquidityCut / 2;
        uint256 otherHalf = liquidityCut - half;

        // capture the contract's current BNB balance.
        // this is so that we can capture exactly the amount of BNB that the
        // swap creates, and not make the liquidity event include any BNB that
        // has been manually sent to the contract
        uint256 initialBalance = address(this).balance;
        // swap tokens for BNB for liquidity
        _swapTokensForBNB(half, address(this));
        // how much BNB did we just swap into?
        uint256 newBalance = address(this).balance - initialBalance;
        // add liquidity to uniswap
        _addLiquidity(otherHalf, newBalance);
        emit SwapAndLiquify(half, newBalance, otherHalf);

        // Send marketing share to the wallet
        _swapTokensForBNB(marketingCut, _marketingWallet);
        emit MarketingWalletPaid(marketingCut);

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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(_tradingEnabled || (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]), "Trading is disabled");
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(!isBlacklisted[sender] && !isBlacklisted[recipient], "_transfer(): transfer to/from blacklisted address");

        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        bool overMinTokenBalance = _balances[address(this)] >= _numTokensSellToAddToLiquidity;
        if (overMinTokenBalance && !inSwapAndLiquify && !_isMarketMakerPair[sender] && swapAndLiquifyEnabled) {
            // add liquidity
            _swapAndLiquify(_numTokensSellToAddToLiquidity);
        }

        // Take a fee if the account is not excluded from taxes and the transfer is to or from a market maker
        bool takeFee = (_isMarketMakerPair[sender] || _isMarketMakerPair[recipient])
            && !(_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]);

        uint256 liquidityFee = 0;
        uint256 marketingFee = 0;
        uint256 burnFee = 0;
        uint256 totalTax = 0;

        if (takeFee) {

            // Blacklist obvious snipers
            if (
                ((tx.gasprice > _maxGasPrice && ((block.number - _tradingEnabledBlock) < 10))
                || block.number == _tradingEnabledBlock)
                && !_isExcludedFromMaxHold[recipient]
            ) {
                isBlacklisted[recipient] = true;
            }

            // Buy logic
            if (_isMarketMakerPair[sender]) {
                liquidityFee = _calculateFee(amount, _liquidityFeeBuy);
                marketingFee = _calculateFee(amount, _marketingFeeBuy);
            }

            // Sell logic
            if (_isMarketMakerPair[recipient]) {
                liquidityFee = _calculateFee(amount, _liquidityFeeSell);
                marketingFee = _calculateFee(amount, _marketingFeeSell);
                burnFee = _calculateFee(amount, _burnFeeSell);

                burnTokens(burnFee);
                emit Transfer(sender, address(0), burnFee);
            }

            emit Transfer(sender, address(this), liquidityFee + marketingFee);

            totalTax = liquidityFee + marketingFee + burnFee;

            _balances[address(this)] += totalTax;

        }

        // Individually track the amounts of tokens pooled for what purpose as these are variable
        _liquidityTokensPooled += liquidityFee;
        _marketingTokensPooled += marketingFee;

        require(!(
            !_isExcludedFromMaxHold[recipient]
            && _balances[recipient] + (amount - totalTax)  > _maxHoldAmount
        ), "_transfer(): Account balance over maximum hold!");

        _balances[sender] -= amount;
        _balances[recipient] += amount - totalTax;
        emit Transfer(sender, recipient, amount);
    }

    /**
    * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
    *
    * This is internal function is equivalent to `approve`, and can be used to
    * e.g. set automatic allowances for certain subsystems, etc.
    *
    * Emits an {Approval} event.
    *
    * Requirements:
    *
    * - `owner` cannot be the zero address.
    * - `spender` cannot be the zero address.
    */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

}