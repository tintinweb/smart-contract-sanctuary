/**
 *Submitted for verification at Etherscan.io on 2021-07-14
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.6;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
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

contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract PresaleWithSwapping is Ownable {
	using SafeERC20 for IERC20;
	IUniswapV2Router02 public router;
	IERC20 public tokenForSale; //token for sale
	IERC20 public tokenToPay; //token to be used for payment
    address public safeAddress; //safe to receive proceeds
	uint256 public exchangeRateWholeToken; //amount of tokenToPay that buys an entire tokenForSale
	uint256 public immutable exchangeRateDivisor; //divisor for exchange rate. set in constructor equal to 10**decimcals of tokenForSale
	uint256 public saleStart; //UTC timestamp of sale start
	uint256 public saleEnd; //UTC timestamp of sale end
    uint256 public amountLeftToSell; //amount of tokens remaining to sell
    uint256 public totalTokensSold; //tracks sum of all tokens sold
    uint256 public totalProceeds; //tracks sum of proceeds from all token sales
    uint256 public whitelistBonusBIPS; //bonus to whitelisted addresses in BIPS
	bool public adjustableExchangeRate; //determines if exchange rate is adjustable or fixed
    bool public adjustableTiming; //determines if start/end times can be adjusted, or if they are fixed
	mapping(address => uint256) public tokensPurchased; //amount of tokens purchased by each address
    mapping(address => bool) public whitelist; //whether each address is whitelisted or not
    mapping(address => bool) public hasPurchased; //whether each address has purchased tokens or not
    address[] public purchasers; //array of all purchasers for ease of querying

	event TokensPurchased(address indexed buyer, uint256 amountPurchased);
	event ExchangeRateSet(uint256 newExchangeRate);

	modifier checkPurchase(address buyer, uint256 amountToBuy) {
		require(saleOngoing(),"sale not ongoing");
        uint256 amountToSend = amountToBuy;
        if (whitelist[buyer]) {
            amountToSend = amountToBuy * (10000 + whitelistBonusBIPS) / 10000;
        }
		require(amountToSend <= amountLeftToSell, "amountToSend exceeds amountLeftToSell");
        _;
	}

	constructor(
            IUniswapV2Router02 router_,
			IERC20 tokenForSale_,
			IERC20 tokenToPay_,
            address safeAddress_,
			uint256 saleStart_,
			uint256 saleEnd_,
            uint256 amountTokensToSell_,
			uint256 exchangeRateWholeToken_,
            uint256 whitelistBonusBIPS_,
			bool adjustableExchangeRate_,
            bool adjustableTiming_
            ) {
        require(whitelistBonusBIPS_ <= 5000, "bonus too high");
		require(saleStart_ > block.timestamp, "sale must start in future");
		require(saleStart_ < saleEnd_, "sale must start before it ends");
        router = router_;
		tokenForSale = tokenForSale_;
		tokenToPay = tokenToPay_;
        safeAddress = safeAddress_;
		saleStart = saleStart_;
		saleEnd = saleEnd_;
        amountLeftToSell = amountTokensToSell_;
		exchangeRateWholeToken = exchangeRateWholeToken_;
		emit ExchangeRateSet(exchangeRateWholeToken_);
        whitelistBonusBIPS = whitelistBonusBIPS_;
		adjustableExchangeRate = adjustableExchangeRate_;
        adjustableTiming = adjustableTiming_;
        exchangeRateDivisor = 10**(tokenForSale.decimals());
	}

    receive() external payable {}

	//PUBLIC FUNCTIONS
	function saleStarted() public view returns(bool) {
		return(block.timestamp >= saleStart);
	}

	function saleEnded() public view returns(bool) {
		return(block.timestamp > saleEnd);
	}

	function saleOngoing() public view returns(bool) {
		return(saleStarted() && !saleEnded());
	}

    //find amount of tokenToPay needed to buy amountToBuy of tokenForSale
    function findAmountToPay(uint256 amountToBuy) public view returns(uint256) {
        uint256 amountToPay = (amountToBuy * exchangeRateWholeToken) / exchangeRateDivisor;
        return amountToPay;
    }

    //find amount of ETH to send in a call to purchaseTokensWithETH( amountToBuy )
    //to be conservative, we overestimate the amount of ETH  by 2%. the router will ultimately refund any extra ETH that is sent
    function findAmountETHToPay(uint256 amountToBuy) public view returns(uint256) {
        uint256 amountToPay = findAmountToPay(amountToBuy);
        address[] memory swapPath = new address[](2); //WETH, tokenToPay
        swapPath[0] = router.WETH();
        swapPath[1] = address(tokenToPay);
        uint256[] memory amountsIn = router.getAmountsIn(amountToPay, swapPath);
        uint256 ETHToPay = amountsIn[amountsIn.length - 1];
        return ((ETHToPay * 102) / 100);
    }

    function numberOfPurchasers() public view returns(uint256) {
        return purchasers.length;
    }

	//EXTERNAL FUNCTIONS
	function purchaseTokens(uint256 amountToBuy) external checkPurchase(msg.sender, amountToBuy) {
		_processPurchase(msg.sender, amountToBuy);
	}

	function purchaseTokensWithETH(uint256 amountToBuy) external payable checkPurchase(msg.sender, amountToBuy) {
		_swapToPurchaseTokens(msg.sender, msg.value, amountToBuy);
		_processPurchase(msg.sender, amountToBuy);
	}

	//OWNER-ONLY FUNCTIONS
	function adjustStart(uint256 newStartTime) external onlyOwner {
        require(adjustableTiming, "timing is not adjustable");
		require(!saleOngoing(), "cannot adjust start while sale ongoing");
		require(newStartTime < saleEnd, "sale must start before it ends");
		require(newStartTime > block.timestamp, "sale must start in future");
		saleStart = newStartTime;
	}

	function adjustEnd(uint256 newEndTime) external onlyOwner {
        require(adjustableTiming, "timing is not adjustable");
		require(saleStart < newEndTime, "sale must start before it ends");
		saleEnd = newEndTime;
	}

	function adjustExchangeRate(uint256 newExchangeRate) external onlyOwner {
		require(adjustableExchangeRate, "exchange rate is not adjustable");
		exchangeRateWholeToken = newExchangeRate;
		emit ExchangeRateSet(newExchangeRate);
	}

    function addToWhitelist(address[] calldata users) external onlyOwner {
        for(uint256 i = 0; i < users.length; i++) {
            whitelist[users[i]] = true;
        }
    }

    function removeFromWhitelist(address[] calldata users) external onlyOwner {
        for(uint256 i = 0; i < users.length; i++) {
            whitelist[users[i]] = false;
        }
    }

    function setwhitelistBonusBIPS(uint256 value) external onlyOwner {
        require(value <= 5000, "bonus too high");
        whitelistBonusBIPS = value;
    }

	//INTERNAL FUNCTIONS
	function _processPurchase(address buyer, uint256 amountToBuy) internal {
		uint256 amountToPay = findAmountToPay(amountToBuy);
        totalProceeds += amountToPay;
        uint256 amountToSend = amountToBuy;
        if (whitelist[buyer]) {
            amountToSend = amountToBuy * (10000 + whitelistBonusBIPS) / 10000;
        }
        totalTokensSold += amountToSend;
        tokensPurchased[buyer] += amountToSend;
		emit TokensPurchased(buyer, amountToSend);
        amountLeftToSell -= amountToSend;
        if (!hasPurchased[buyer] && amountToBuy > 0) {
            hasPurchased[buyer] = true;
            purchasers.push(buyer);
        }
        tokenToPay.safeTransferFrom(buyer, safeAddress, amountToPay);
	}

	function _swapToPurchaseTokens(address buyer, uint256 amountETH, uint256 amountToBuy) internal {
        uint256 amountToPay = findAmountToPay(amountToBuy);
        require(tokenToPay.allowance(buyer, address(this)) >= amountToPay, "must approve the contract first");
		address[] memory swapPath = new address[](2); //WETH, tokenToPay. assumes good liquidity for this pair
        swapPath[0] = router.WETH();
        swapPath[1] = address(tokenToPay);
        //swap tokens for buyer, ensuring that they get the amount out needed to buy the tokens
		router.swapETHForExactTokens{value:amountETH}(amountToPay, swapPath, buyer, block.timestamp);
        //send any extra ETH back to buyer
        payable(buyer).transfer(address(this).balance);
	}

}