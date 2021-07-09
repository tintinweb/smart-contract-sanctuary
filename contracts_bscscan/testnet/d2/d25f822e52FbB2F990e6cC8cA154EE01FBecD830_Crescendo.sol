/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

pragma solidity ^0.8.3;
// SPDX-License-Identifier: Unlicensed
/* 

Ascii Art Section - Thanks to https://patorjk.com/software/taag

 _____ ______ _____ _____ _____  _____ _   _______ _____ 
/  __ \| ___ \  ___/  ___/  __ \|  ___| \ | |  _  \  _  |
| /  \/| |_/ / |__ \ `--.| /  \/| |__ |  \| | | | | | | |
| |    |    /|  __| `--. \ |    |  __|| . ` | | | | | | |
| \__/\| |\ \| |___/\__/ / \__/\| |___| |\  | |/ /\ \_/ /
 \____/\_| \_\____/\____/ \____/\____/\_| \_/___/  \___/ 
                                                         
*/

/*
 -----------------------------------------------------------------------------
|                                                                             |
| Crescendo.sol                                                               |
|                                                                             |
| CREATED                                                                     |
| =======                                                                     |
| TokenLH  2021-06-19                                                         |                                                 
|                                                                             |
| UPDATED                                                                     |
| =======                                                                     |
| TokenLH  2021-06-23  Dynamic Marketing, Prizes, Charity addresses enabled   |
| TokenLH  2021-06-25  Dynammic Anti-Bot SuperTax Policy enabled              |
| TokenLH  2021-06-27  Dynamic Anti-Whale Transaction Size Policy enabled     |
| TokenLH  2021-06-28  Dynamic Anti-Whale Transaction Timing Policy enabled   |
| TokenLH  2021-07-01  Prototype coding completed.                            |
| TokenLH  2021-07-03  First set of enhancements implemented                  |
| TokenLH  2021-07-05  Second set of enhancements implemented                 |
| TokenLH  2021-07-06  Final contract testing on JVM started                  |
| TokenLH  2021-07-06  Final Contract testing on JVM concluded                |
| TokenLH  2021-07-07  Final Contract testing on TESTNET started              |
|                                                                             |
 -----------------------------------------------------------------------------
*/

/*
****************************
** Interface IERC20 BEGIN **
****************************
https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IERC20.sol
*/
interface IERC20 {
    
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

/* 
*********************************
** Interface IUniswapV2Factory **
*********************************
https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Factory.sol
*/
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

/* 
******************************
** Interface IUniswapV2Pair **
******************************
https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/interfaces/IUniswapV2Pair.sol
*/
interface IUniswapV2Pair {
    
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    event Sync(uint112 reserve0, uint112 reserve1);
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, int amount1Out, address indexed to);
 
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
**********************************
** Interface IUniswapV2Router01 **
**********************************
https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router01.sol
*/
interface IUniswapV2Router01 {
    
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

/* 
**********************************
** Interface IUniswapV2Router02 **
**********************************
https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router02.sol
*/
interface IUniswapV2Router02 is IUniswapV2Router01 {
    
    function removeLiquidityETHSupportingFeeOnTransferTokens(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

/* 
**********************
** Contract Context **
**********************
https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol
*/

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

/* 
**********************
** Contract Ownable **
**********************
https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
*/

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {

    /*
    ** This modifier throws an error if any function modified by onlyOwner is 
    ** called by any account other than the contract owner.  I am using it to 
    *  publicly expose methods on the contract, mostly.
    */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

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
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
    */
    
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

/* 
*********************
** Library Address **
*********************
https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol
*/

 /**
 * @dev Collection of functions related to the address type
 */

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     * 
     * Why does this check matter?  
     * 
     * Because sending value to a contract can result in the value being lost forever
     *
     * [IMPORTANT]
     * ===========
     * It is unsafe to assume that every time an address for which this function 
     * returns false is an externally-owned account (EOA) and not a contract.
     *
     * This function will return false for the following types of addresses:
     *
     *  - an externally-owned account
     *  - a contract still in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     *
     * This method relies on extcodesize, which returns 0 for contracts in
     * construction, since the code is only stored at the end of the
     * constructor execution.
     *
    */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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

/*
*********************************
**  CRESCENDO CODE STARTS HERE **
*********************************
*/
contract Crescendo is Context, IERC20, Ownable {

    /*
    *******************
    ** LIBRARY CALLS **
    *******************
    */
    using Address for address;

    /*
    *****************
    ** MODIFIER(S) **
    *****************
    */
    
    /*
    ** @dev:  Use of the "_" enables a kind of macro wrapper functionality around the 
    **        entire contract to allow for the insertion of new modifiers.
    **
    **        What I am not sure about is why we need to lock the swap?
    **        Is it because of the asynchronous nature of the blockchain?
    **        is lockTheSwap acting like a blocking semaphore?
    */
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
//todo:  Where is this used?

    /*
    **************
    ** EVENT(S) **
    **************
    */
    
    /*
    ** @dev:  Define custom events that this contract can announce
    **        and apps listening to the blockchain can listen for...
    */
    event LiquidityTriggered(uint256 liquidityTrigger);

    /*
    ***************
    ** CONSTANTS **
    ***************
    */

    // Token Heaven & Hell (Born & Burn Address)
    address private bitbucket = 0x0000000000000000000000000000000000000000;

    // Who owns this contract?
	address public contractOwner = _msgSender();
    
    // What is the address of this contract (once registered on blockchain)
    address public contractAddress = address(this);
    
    // Token name 
    string private tokenName   = "CRESCENDO";

    // Token Symbol    
    string private tokenSymbol = "CRESCENDO";

    // Token precision
    uint8 private tokenDecimals = 18;

    // Token total supply (1 Quadrillion at 18 decimal places of precision)
    uint256 public tokenSupply = 10**33;

    /*
    ************
    ** CALLER **
    ************
    */
    address sender = _msgSender();
    
    /*
    ** How many tokens does this caller have?
    */
    uint256 currentHolding = balanceOf(sender);
    
    /*
    *************************
    ** HOLDINGS MANAGEMENT **
    *************************
    */
    
 	/*
	** Create 1-dimensional array for keeping track of holders
    */
    mapping(address => uint) private balances;
  
	/*
	** Create 2-dimensional array for keeping track of spenders on behalf of holders 
    */
    mapping (address => mapping (address => uint256)) private allowances;

    /*
	****************
	** EXCLUSIONS **
	****************
	*/

    /*
    ** Create 1-dimensional array for keeping track of excluded addresses
    ** Excluded addresses could include the contract owner, among others
    */
    mapping (address => bool) private isExcludedFromFee;

    function isAddressExcludedFromFee(address _account) public view returns(bool) {
        return isExcludedFromFee[_account];
    }

    // Flag for fee application
    bool private taxable = true;
    
    // remove all fees
    function disableFees() private onlyOwner {
        
        // Test to see if fees are already disabled
        if(liquidityFee == 0) return;
        
        taxable = false;
        
        marketingFeeBefore  = marketingFee;
        prizesFeeBefore     = prizesFee;
        charityFeeBefore    = charityFee;
        liquidityFeeBefore  = liquidityFee;

        marketingFee = 0;
        prizesFee    = 0;
        charityFee   = 0;
        liquidityFee = 0;
    }
    
    // Restore all fees
    function enableFees() private onlyOwner {
        
        taxable = true;
        
        marketingFee = marketingFeeBefore;
        prizesFee    = prizesFeeBefore;
        charityFee   = charityFeeBefore;
        liquidityFee = liquidityFeeBefore;
    }

	/*
	**********************
	** MARKETING WALLET **
	**********************
	*/

    // Marketing Wallet Address		
    address public marketingWalletAddress;
	
	// Marketing Wallet Fee (integer as percent, or n/100) 
    uint256 public marketingFee = 3;

    // Marketing Wallet Previous Fee
    uint256 private marketingFeeBefore = marketingFee;

    function setMarketingWalletAddress(address account) external onlyOwner() {
        marketingWalletAddress = account;
    }

    function setMarketingFee(uint256 _marketingFee) external onlyOwner() {
        marketingFee = _marketingFee;
    }


	/*
	*******************
	** PRIZES WALLET **
	*******************
	*/
		
    // Prizes Wallet address
    address public prizesWalletAddress;
    
	// Prizes Wallet Fee (integer as percent, or n/100) 
    uint256 public prizesFee = 1;
    
    // Prizes Wallet Previous Fee
    uint256 private prizesFeeBefore = prizesFee;

    function setPrizesWalletAddress(address _account) external onlyOwner() {
        prizesWalletAddress = _account;
    }

    function setPrizesFee(uint256 _prizesFee) external onlyOwner() {
        prizesFee = _prizesFee;
    }
    
    
	/*
	********************
	** CHARITY WALLET **
	********************
	*/

    // Charity Wallet address
    address public charityWalletAddress;

	// Charity Wallet Fee (integer as percent, or n/100) 
    uint256 public charityFee = 1;
    
    // Charity Wallet Previous Fee
    uint256 private charityFeeBefore = charityFee;

    function setCharityWalletAddress(address _account) external onlyOwner() {
        charityWalletAddress = _account;
    }

    function setCharityFee(uint256 _charityFee) external onlyOwner() {
        charityFee = _charityFee;
    }
	
		  
	/*
	***************
	** LIQUIDITY **
	***************
	*/
    
	// Liquidity Fee (integer as percent, or n/100) 
    uint256 public liquidityFee = 7;
    
    // Liquidity Previous Fee
    uint256 private liquidityFeeBefore = liquidityFee;

    function setLiquidityFee(uint256 _liquidityFee) external onlyOwner() {
        liquidityFee = _liquidityFee;
    }

    // @dev:  Liquidity Trigger is 0.01% of token supply
    uint256 public liquidityTrigger = tokenSupply * 10 / 10**5;
    
    function setLiquidityTrigger(uint256 _liquidityTrigger) external onlyOwner() {
	    liquidityTrigger = _liquidityTrigger;
    }

    // Flag to track if Swap & Liquify is enabled    
	bool public swapAndLiquifyEnabled = true;

    // Event type to announce that Swap & Liquify is enabled
    event SwapAndLiquifyEnabledUpdated(bool enabled);

    // Function to turn Swap & Liquify functionality off or on
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
    // Flag to indicate when Swap & Liquify functionality is enabled
    bool inSwapAndLiquify = false;

    // Flag to indicate that we are in a liquidity event, to prevent a "liquidity loop"
    bool inLiquidityEvent = false;

    // Event to announce that Swap & Liquify was executed
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived, uint256 tokensIntoLiqudity);

    /*
    *************************
    ** COMMON TRADE LIMITS **
    *************************
    */

	// Flag for tracking whether Trade Limits are in force
	bool public tradeLimits = true;

    // Turn Trade Limits on
    function enableTradeLimits() private onlyOwner() {
        tradeLimits = true;
    }
    
    // Turn Trade Limits off
    function disableTradeLimits() private onlyOwner() {
        tradeLimits = false;
    }

    // Max holdings set to 2.5% of token supply
    uint public maxHolding = tokenSupply * 25 / 10**3;

    function setMaxHolding (uint256 _maxHolding) external onlyOwner() {
        maxHolding = _maxHolding;
    }

    // Max transaction size set to 0.05 of token supply, or 1/50 of max holdings
    uint256 public maxTransaction = tokenSupply * 5 / 10**4;

    function setMaxTransaction(uint256 _maxTransaction) external onlyOwner() {
        maxTransaction = _maxTransaction;
    }

	/*
	**********************
	** WHALE MANAGEMENT **
	**********************
	*/

    // Flag for individual Whales
    bool isWhale = false;

	// Flag for tracking whether Whale Limits are in force
    bool public limitTheWhales = true;
    
    // Turn Whale Limits on
    function startLimitingTheWhales() public onlyOwner() {
        limitTheWhales = true;
    }
    
    // Turn Whale Limits off
    function stopLimitingTheWhales() public onlyOwner() {
        limitTheWhales = false;
    }

    // Whales are defined here as holders with at least 1% of token supply
    uint public whaleSize = tokenSupply / 100;

    function setWhaleSize (uint256 _whaleSize) public onlyOwner() {
        whaleSize = _whaleSize;
    }

	// Whales may trade at most every n seconds 
	uint public whaleFrequency = 60;

    // Adjust whale trading interval
    function setWhaleFrequency (uint _whaleFrequency) public onlyOwner() {
        whaleFrequency = _whaleFrequency;
    }

    // Overactive whales are penalized by n seconds if they trade too aggressively
    uint public whalePenalty = 60;

    // Adjust whale penalty period
    function setWhalePenalty (uint _whalePenalty) public onlyOwner() {
	    whalePenalty = _whalePenalty;
    }

    /*
    ********************* 
    ** TIME MANAGEMENT **
    *********************
    */
    
    // List of trade times, by address
    mapping (address => uint256) public lastTokenTransfer;

    // Variable to hold time of last trade 
    uint previousTime = lastTokenTransfer[sender];

    // Variable to hold current time, more or less
    uint thisTime = block.timestamp;

    // Variable to hold difference in time between trades
    uint elapsedTime = thisTime - previousTime;

	/*
	** PANCAKESWAP TESTNET 
	** ===================
    ** V2 Factory: 0x6725F303b657a9451d8BA641348b6761A6CC7a17
    ** V2 Router: 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
    **
	** PANCAKESWAP MAINNET 
	** ===================
	** V2 Router:  0x10ED43C718714eb63d5aA57B78B54704E256024E
	*/

    // DEX Router Address	
	address public routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;

    // DEX Router Object Handle 
    IUniswapV2Router02 tokenRouter;
	
    // Token Pair Address
	address public tokenPair;

    // Set token pair addresses (safety measure)
    function setTokenPair (address _tokenPair) public onlyOwner {
        tokenPair = _tokenPair;
    }

    /*
    *****************
    ** CONSTRUCTOR **
    *****************
    */
    
    constructor () payable {

		// Exclude contract creator from fees
		isExcludedFromFee[contractOwner] = true;

        // Exclude contract address from fees        
		isExcludedFromFee[contractAddress] = true;

        // Bind local instance of router object to DEX address (TEXT/MAIN)
        tokenRouter = IUniswapV2Router02(routerAddress);

        // Obtain address for token pair from DEX (this can be done manually with contract address)    
        tokenPair = IUniswapV2Factory(tokenRouter.factory()).createPair(contractAddress, tokenRouter.WETH());

        // Assign token suppy to contract owner
        balances[contractOwner] = tokenSupply;

        // Tell the world about the token transfer
		emit Transfer(bitbucket, contractOwner, tokenSupply);

    }

	/*
	*************************************************************************
	** HERE WE OVERRIDDE ALL OF THE STANDARD ERC20/BSC20 LIBRARY FUNCTIONS **
	*************************************************************************
	*/
	
    function name() public view override returns (string memory) {
        return tokenName;
    }

    function symbol() public view override returns (string memory) {
        return tokenSymbol;
    }

    function decimals() public view override returns (uint8) {
        return tokenDecimals;
    }

    function totalSupply() public view override returns (uint256) {
        return tokenSupply;
    }

    function balanceOf(address _owner) public view override returns (uint balance) {
        return balances[_owner];
    }
    
    function allowance(address _owner, address _spender) public view override returns (uint remaining) {
        return allowances[_owner][_spender];
    }

    function approve(address _spender, uint _value) public override returns (bool success) {
        _approve(sender, _spender, _value);
        return true;
    }

    function transfer(address _to, uint _value) public override returns (bool success) {
        _transfer(sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public override returns (bool success) {
        _approve(_from, sender, _value);
        _transfer(_from, _to, _value);
        return true;
    }
//todo double check me - this may end up in trouble because it is 3rd party...

    /*
    **********************
    ** CUSTOM FUNCTIONS **
    **********************
    */

    // Alternate implementation of approve() with assignable <owner>
    function _approve(address _owner, address _spender, uint256 _value) private {

        // Sanity checks
        require(_owner   != bitbucket, "ERC20: approve from the bitbucket forbidden");
        require(_spender != bitbucket, "ERC20: approve to the bitbucket forbidden");
        require(_value > 0, "Value must be greater than zero");
        require(_value < allowances[_owner][_spender], "ERC20:  Value sent exceeds allowance");

        // Update allowances
        allowances[_owner][_spender] = _value;
        
        // Announce new spending limit
        emit Approval(_owner, _spender, _value);
    }


    // Alternate implementation of transfer() with assignable <from>
    function _transfer(address _from, address _to, uint256 _value) private {

        // Sanity checks
        require(_from != bitbucket, "ERC20: Transfer from the bitbucket forbidden");
        require(_to   != bitbucket, "ERC20: Transfer to the bitbucket forbidden");
        require(_to   != contractAddress, "ERC20: transfer to the contract forbidden");
        require(_value > 0, "ERC20: Value transferred must be greater than zero");

        // Check to see if Liquidity has been triggered
        _checkLiqudityTriggered(_from);

        // Precondition - enable fees, enable trade limits
        enableFees();
        enableTradeLimits();
        
        // Is the contract owner involved?
        if (_from == contractOwner || _to == contractOwner) {
            
            disableFees();
            disableTradeLimits();
        }
        else {

            // Are we imposing trade limits?
            if (tradeLimits) {

                // is a sale to a DEX involved?
                if (_to == address(tokenPair) || _to == address(tokenRouter)) {
                    
                    // Is the requested amount excessive?  Trim it!
                    if (_value > maxTransaction) _value = maxTransaction;
                    
                    // Will the holder exceed the maximum holding limit?  Trim it!
                    if (_value + currentHolding > maxHolding) _value = maxHolding - currentHolding;
                    
                    // Are we limiting whales?             
                    if (limitTheWhales) {

                        // Is the Caller a whale?
                        if (currentHolding >= whaleSize) {

                            // Is this whale trading too frequently?  Penalize!
                            if (elapsedTime < whaleFrequency) lastTokenTransfer[_from] = thisTime + whalePenalty;
                        
                            // Abort trade if whale is hyperactive
                            require((thisTime - lastTokenTransfer[_from]) < 1 minutes, "You are trading too frequently, slow down!");
                        }
                    }
                }
            }
        }

        // If any implicated account is in isExcludedFromFee, disable fees
        if (isExcludedFromFee[_from] || isExcludedFromFee[_to]) disableFees();
    
        // Transfer the tokens        
        _tokenTransfer(_from, _to, _value, taxable);

    }
    
    /*
    ** _tokenTransfer (address, address, uint256, boolean) private 
    */
    function _tokenTransfer(address _from, address _to, uint256 _amount, bool _taxable) private {

        // Log the time of this transfer
        lastTokenTransfer[_from] = block.timestamp;
        
        // Set precondition
        enableFees();
        
        // If _taxable is FALSE remove all fees
	    if(!_taxable) disableFees();
        
        // Calculate Liquidity Fee and send to contract address
        uint256 liquidityFeePayable = _amount * (liquidityFee / 100);
        emit Transfer(_from, contractAddress, liquidityFeePayable);
        
        // Calculate Marketing Fee and send to Marketing multi-sig wallet
        uint256 marketingFeePayable = _amount * (marketingFee / 100);
        emit Transfer(_from, marketingWalletAddress, marketingFeePayable);

        // Calculate Prizes Fee and send to Prizes multi-sig wallet
        uint256 prizesFeePayable = _amount * (prizesFee / 100);
        emit Transfer(_from, prizesWalletAddress, prizesFeePayable);
        
        // Calculate Charity Fee and send to Charity multi-sig wallet
        uint256 charityFeePayable = _amount * (charityFee / 100);
        emit Transfer(_from, charityWalletAddress, charityFeePayable);
        
        // Calculate residual amount to be transferred
        _amount = _amount - liquidityFeePayable - marketingFeePayable - prizesFeePayable - charityFeePayable;
        
        // Inform blockchain of the result
        emit Transfer(_from, _to, _amount);
        
    }
  
    function _checkLiqudityTriggered(address _from) private {

        // Is the current caller the token pair address?  If so skip.
        if (_from == tokenPair) {

            // YES, the Caller is the token pair address...skip!
            inLiquidityEvent = false;

            // Don't get caught in a loop.
            inSwapAndLiquify = false;
        }
        else {
            
            // Were we already in a Swap & Liquify event?  If so skip.
            if (inSwapAndLiquify) {
            
                // YES, we were in a Swap & Liquify event...skip!
                inLiquidityEvent = false;

                // Don't get caught in a loop.
                inSwapAndLiquify = false;
            }
            else {
        
                // Is swapAndLiquifyEnabled on?
                if (swapAndLiquifyEnabled) {
            
                    // Get the balance of the contract
                    uint256 contractTokenBalance = balanceOf(contractAddress);

                    // Is the contract balance more than the liquidity trigger?
                    if (contractTokenBalance >= liquidityTrigger) {

                        // YES, it is 
                        inLiquidityEvent = true;

                        // Swap & Liquify the Liquidity Trigger amount
                        swapAndLiquify(liquidityTrigger);
                    }
                }        
            }
        }
    }


    // Swap & Liquify function
    function swapAndLiquify(uint256 _tokensToLiquidate) private lockTheSwap {

        // Get the value balance of the contract
        uint256 currentValueBalance = contractAddress.balance;

        // Get the token balance of the contract
        uint256 currentTokenBalance = balanceOf(contractAddress);

        // Handler for when the contract has more value than expected
        if (currentValueBalance > 0) {
        
            // This is an error condition - send to contract owner for further action
            // (n00bs often send value to the contract address by accident)
            disableFees();
            disableTradeLimits();
            _tokenTransfer(contractAddress, contractOwner, currentValueBalance, taxable);
            enableFees();
            enableTradeLimits();
        }
        
        // Handler for when contract has less tokens than called for
        if (currentTokenBalance < _tokensToLiquidate) {
            
            _tokensToLiquidate = currentTokenBalance;
        }
        
        // Sanity check
        require(_tokensToLiquidate > 1, "ERC20: Swap for zero tokens forbidden");
        
        // Do we have an odd number of tokens?  If so, trim by one...
        if (_tokensToLiquidate %2 == 1) {
            
            _tokensToLiquidate = _tokensToLiquidate - 1;
        }

        // Now we should have an even number of tokens to deal with

        // Split the contract token balance into two equal pieces
        uint256 firstHalf  = _tokensToLiquidate / 2;
        uint256 secondHalf = _tokensToLiquidate - firstHalf;

        // swap tokens for external value
        swapTokens(firstHalf); 
        
        // how much value did we just swap into?
        uint256 newBalance = contractAddress.balance;

        // add liquidity
        addLiquidity(secondHalf, newBalance);
        
        emit SwapAndLiquify(firstHalf, newBalance, secondHalf);
    }


    function swapTokens(uint256 _tokenAmount) private {

        // generate the path associative array for DEX
        address[] memory path = new address[](2);
        
        path[0] = contractAddress;
        path[1] = tokenRouter.WETH();

        _approve(contractAddress, routerAddress, _tokenAmount);

        // make the swap
        tokenRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _tokenAmount,
            0, // accept any amount of ETH
            path,
            contractAddress,
            block.timestamp
        );

    }

    function addLiquidity(uint256 _internalAmount, uint256 _externalAmount) private {

        // approve token transfer to cover all possible scenarios
        _approve(contractAddress, routerAddress, _externalAmount);

        // add the liquidity
        tokenRouter.addLiquidityETH{value: _externalAmount}(
            contractAddress,
            _internalAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            contractOwner,
            block.timestamp
        );
        
    }
    
    /*
    ** This is here to make the contract able to accept tokens (payable).  
    **
    ** It is also called a "catch all"
    */
    receive() external payable {}
    
}