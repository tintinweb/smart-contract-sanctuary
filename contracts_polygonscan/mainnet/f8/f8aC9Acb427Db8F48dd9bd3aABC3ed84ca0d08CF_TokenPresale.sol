/**
 *Submitted for verification at polygonscan.com on 2021-08-14
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;


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

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
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


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}


interface IFeeTo {
    function feeTo() external view returns (address);

}


//@notice An initial offering for a single token

contract TokenPresale is Ownable {
    using Address for address;

    /// @notice Sale Token
    IERC20 public token;

    IFeeTo public factory;
    IUniswapV2Router02 public router;

    /// @notice Dates can be either timestamp or blocks (depending on useBlocks)
    uint256 public startTime;
    uint256 public endTime;
    uint256 public claimTime;
    uint256 public whitelistStartTime;
    uint256 public liquidityLockTime;

    bool public useBlocks;
    bool public burnUnsold;
    bool public autoAddLiquidity;

    uint256 public softCap;
    uint256 public hardCap;
    uint256 public hardCapEth;
    uint256 public minTokens;
    uint256 public maxTokens;

    /// @notice Percentage of the sale used for adding liquidity (on basis points)
    uint16 public liquidityPct;

    uint16 public feeBP;
    uint16 public listingType;

    /// @notice Wheter initialize method has been called (it can only be called once)
    bool public initialized = false;

    bool public tokensAdded = false;

    bool public liquidityAdded = false;

    /// @notice Balance of each address on native currency
    mapping(address => uint256) public balances;

    /// @notice Tokens bought by each address
    mapping(address => uint256) public tokensBought;

    /// @notice Whitelisted addresses and max whitelisted amount
    mapping(address => uint256) public whitelists;

    /// @notice Generic settings for the sale (website, social networks, etc)
    mapping(string => string) public settings;

    /// @notice Total number of participants
    uint256 public participants;

    /// @notice Number of tokens sold
    uint256 public tokensSold;

    /// @notice Total number of tokens already claimed
    uint256 public tokensClaimed;

    event TokensAdded(uint256 amount);
    event TokensRemoved();
    event AddressWhitelisted(address addr, uint256 amount);
    event TokensBought(uint256 amount);
    event TokensClaimed(uint256 amount);
    event EthClaimed(uint256 balance);
    event FundsWithdrawn();
    event LiquidityWithdrawn();
    event LiquidityAdded();

    constructor() {
        factory = IFeeTo(msg.sender);
    }

    /**
     * @dev Called by PresaleFactory when a new offering is created
     **/
    function initialize(
        IERC20 _token,
        address _router,
        uint256[5] memory _dates,
        uint256[3] memory _caps,
        uint256[2] memory _tokenLimits,
        uint16[3] memory _settings,
        bool[3] memory _features
    ) external onlyOwner {
        require(!initialized, 'initialize:ALREADY_INITIALIZED');
        initialized = true;

        token = _token;
        router = IUniswapV2Router02(_router);
        startTime = _dates[0];
        endTime = _dates[1];
        claimTime = _dates[2];
        whitelistStartTime = _dates[3];
        liquidityLockTime = _dates[4];
        useBlocks = _features[0];
        burnUnsold = _features[1];
        autoAddLiquidity = _features[2];
        softCap = _caps[0];
        hardCap = _caps[1];
        hardCapEth = _caps[2];
        minTokens = _tokenLimits[0];
        maxTokens = _tokenLimits[1];
        liquidityPct = _settings[0];
        feeBP = _settings[1];
        listingType = _settings[2];

        if (autoAddLiquidity) {
            address lpPair = IUniswapV2Factory(router.factory()).getPair(address(token), router.WETH());
            if (lpPair == address(0)) {
                IUniswapV2Factory(router.factory()).createPair(address(token), router.WETH());
            }
        }
    }

    function addTokens(uint256 _amount) external onlyOwner {
        require(!tokensAdded, 'addTokens:TOKENS_ALREADY_ADDED');
        token.transferFrom(msg.sender, address(this), _amount);
        require(
            token.balanceOf(address(this)) >= hardCap + getTokensForLiquidity(hardCap),
            'addTokens:INSUFFICIENT_BALANCE'
        );
        tokensAdded = true;
        emit TokensAdded(_amount);
    }

    function removeTokens() external onlyOwner {
        require(tokensAdded, 'removeTokens:TOKENS_NOT_ADDED');
        require(timeOrBlock() > startTime, 'removeTokens:ALREADY_STARTED');
        uint256 amount = hardCap + getTokensForLiquidity(hardCap);
        token.transfer(msg.sender, amount);
        tokensAdded = false;
        emit TokensRemoved();
    }

    function whitelistAddress(address _addr, uint256 _amount) external onlyOwner {
        whitelists[_addr] = _amount;
        emit AddressWhitelisted(_addr, _amount);
    }

    function buyTokens() external payable {
        require(tokensAdded, 'buyTokens:TOKENS_NOT_ADDED');
        require(timeOrBlock() <= endTime, 'buyTokens:ENDED');

        bool started = timeOrBlock() >= startTime;
        uint256 whitelistAmount = whitelists[msg.sender];
        if (whitelistAmount == 0) {
            require(started, 'buyTokens:NOT_STARTED');
        } else {
            require(timeOrBlock() >= whitelistStartTime, 'buyTokens:WHITELIST_NOT_STARTED');
        }

        uint256 amount = getTokenAmount(msg.value);
        require(amount >= minTokens, 'buyTokens:LESS_THAN_MIN');

        if (!started) {
            require(whitelistAmount >= amount, 'buyTokens:EXCEEDS_WHITELIST');
        }

        uint256 currentBalance = tokensBought[msg.sender];
        require(maxTokens >= amount + currentBalance, 'buyTokens:MORE_THAN_MAX');
        require(hardCap >= tokensSold + amount, 'buyTokens:NOT_ENOUGH_LEFT');

        balances[msg.sender] += msg.value;
        tokensBought[msg.sender] += amount;
        tokensSold += amount;

        if (currentBalance == 0) {
            participants += 1;
        }

        emit TokensBought(amount);

        // auto-claim tokens if claiming is open
        if (isClaimOpen()) {
            claimTokens();
        }

        if (!started) {
            whitelists[msg.sender] -= amount;
        }
    }

    function claimTokens() public {
        require(isClaimOpen(), 'claimTokens:NOT_CLAIMABLE');
        if (autoAddLiquidity && !liquidityAdded) {
            _addLiquidity();
        }
        uint256 amount = getTokenAmount(balances[msg.sender]);
        balances[msg.sender] = 0;
        tokensClaimed += amount;
        token.transfer(msg.sender, amount);
        emit TokensClaimed(amount);
    }

    function claimEth() external {
        require(timeOrBlock() > endTime, 'claimEth:NOT_ENDED');
        require(tokensSold < softCap, 'claimEth:SOFT_CAP_REACHED');
        uint256 balance = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(balance);
        emit EthClaimed(balance);
    }

    function withdrawFunds() external onlyOwner {
        require(timeOrBlock() > endTime, 'withdrawFunds:NOT_ENDED');
        require(tokensSold >= softCap, 'withdrawFunds:SOFT_CAP_NOT_REACHED');

        // Transfer unsold tokens to owner or dead
        uint256 unsoldTokens = token.balanceOf(address(this)) + tokensClaimed - tokensSold;

        uint256 transferTokens = liquidityAdded ? unsoldTokens : unsoldTokens - getTokensForLiquidity(tokensSold);
        if (transferTokens > 0) {
            address transferTo = burnUnsold ? 0x000000000000000000000000000000000000dEaD : owner();
            token.transfer(transferTo, transferTokens);
        }

        uint256 balance = address(this).balance;
        uint256 fee = (balance * feeBP) / 10000;
        payable(factory.feeTo()).transfer(fee);
        uint256 total = balance - fee;
        uint256 ethForLiquidity = liquidityAdded ? 0 : (total * liquidityPct) / 10000;
        uint256 withdrawableEth = total - ethForLiquidity;
        payable(owner()).transfer(withdrawableEth);
        emit FundsWithdrawn();
    }

    function withdrawLiquidity() external onlyOwner {
        require(tokensSold >= softCap, 'withdrawLiquidity:SOFT_CAP_NOT_REACHED');
        require(timeOrBlock() >= liquidityLockTime, 'withdrawLiquidity:LOCK_NOT_ENDED');
        IERC20 lpPair = IERC20(IUniswapV2Factory(router.factory()).getPair(address(token), router.WETH()));
        uint256 lpBalance = lpPair.balanceOf(address(this));
        lpPair.transfer(msg.sender, lpBalance);
        emit LiquidityWithdrawn();
    }

    function addLiquidity() external {
        require(timeOrBlock() > endTime, 'addLiquidity:NOT_ENDED');
        require(tokensSold >= softCap, 'addLiquidity:SOFT_CAP_NOT_REACHED');
        require(!liquidityAdded, 'addLiquidity:ALREADY_ADDED');
        _addLiquidity();
    }

    function _addLiquidity() internal {
        uint256 tokensForLiquidity = getTokensForLiquidity(tokensSold);
        if (tokensForLiquidity > 0) {
            uint256 initialTokenBalance = token.balanceOf(address(this));
            token.approve(address(router), tokensForLiquidity);

            uint256 balance = address(this).balance;
            uint256 initialEth = balance - (balance * feeBP) / 10000;
            uint256 ethForLiquidity = (initialEth * liquidityPct) / 10000;
            uint256 withdrawableEth = initialEth - ethForLiquidity;

            // add the liquidity
            router.addLiquidityETH{value: ethForLiquidity}(
                address(token),
                tokensForLiquidity,
                0,
                0,
                address(this),
                block.timestamp
            );

            uint256 ethLiquidityLeft = address(this).balance - withdrawableEth;
            uint256 ethToSwap = ethLiquidityLeft / 2;

            if (ethToSwap > 0) {
                address[] memory tradePath = new address[](2);
                tradePath[0] = router.WETH();
                tradePath[1] = address(token);
                router.swapExactETHForTokens{value: ethToSwap}(0, tradePath, address(this), block.timestamp);
                uint256 restTokensForLiquidity = initialTokenBalance - token.balanceOf(address(this));
                token.approve(address(router), restTokensForLiquidity);
                router.addLiquidityETH{value: ethToSwap}(
                    address(token),
                    restTokensForLiquidity,
                    0,
                    0,
                    address(this),
                    block.timestamp
                );
            }
        }
        liquidityAdded = true;
        emit LiquidityAdded();
    }

    function set(string memory _key, string memory _value) external onlyOwner {
        settings[_key] = _value;
    }

    function multiSet(string[2][] memory values) external onlyOwner {
        for (uint256 i = 0; i < values.length; i++) {
            settings[values[i][0]] = values[i][1];
        }
    }

    function isClaimOpen() public view returns (bool) {
        return timeOrBlock() >= claimTime && tokensSold >= softCap;
    }

    function getTokensForLiquidity(uint256 tokens) private view returns (uint256) {
        return (tokens * liquidityPct) / 10000;
    }

    function getTokenAmount(uint256 _ethValue) private view returns (uint256) {
        if (hardCapEth > 0) {
            return (_ethValue * hardCap) / hardCapEth;
        }
        uint256 whitelistAmount = whitelists[msg.sender];
        return startTime > timeOrBlock() ? whitelistAmount : maxTokens - tokensBought[msg.sender];
    }

    function timeOrBlock() private view returns (uint256) {
        return useBlocks ? block.number : block.timestamp;
    }
}