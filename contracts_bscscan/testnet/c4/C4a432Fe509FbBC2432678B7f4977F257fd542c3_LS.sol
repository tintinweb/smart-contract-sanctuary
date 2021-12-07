/**
 *Submitted for verification at BscScan.com on 2021-12-06
*/

pragma solidity 0.8.9;

// SPDX-License-Identifier: MIT

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

interface IDEXFactory {
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

interface IDEXRouter {
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

contract LS is Context, IERC20, Ownable {
	using Address for address payable;

	string constant NAME = "Last Survivor";
	string constant SYMBOL = "LSC";
	uint8 constant DECIMALS = 9;

	uint256 constant MAX_UINT = 2 ** 256 - 1;
	address constant ROUTER_ADDRESS = address(0x10ED43C718714eb63d5aA57B78B54704E256024E);
	address constant ZERO_ADDRESS = address(0);
	address constant DEAD_ADDRESS = address(0x000000000000000000000000000000000000dEaD);

	mapping(address => uint256) rOwned;
	mapping(address => uint256) tOwned;

	mapping(address => mapping(address => uint256)) allowances;

	mapping(address => bool) public isExcludedFromFees;
	mapping(address => bool) public isExcludedFromRewards;
	mapping(address => bool) public isExcludedFromMaxWallet;
	address[] excluded;

	mapping(address => bool) public isBot;
	uint256 tTotal = 1000000000000000 * 10**9;
	uint256 rTotal = (MAX_UINT - (MAX_UINT % tTotal));

	uint256 public maxTxAmountBuy = tTotal;
	uint256 public maxTxAmountSell = tTotal;
	uint256 public maxWalletAmount = tTotal / 5;

	uint256 launchedAt;
	uint256 launchedAtTime;
	address payable marketingAddress;

	mapping(address => bool) automatedMarketMakerPairs;

	bool areFeesBeingProcessed;
	bool public isFeeProcessingEnabled = false;
	uint256 public feeProcessingThreshold = tTotal / 10000;

	IDEXRouter router;

	bool isTradingOpen;

	struct FeeSet {
		uint256 reflectFee;
		uint256 marketingFee;
		uint256 liquidityFee;
	}

	FeeSet public fees = FeeSet({
		reflectFee: 0,
		marketingFee: 10,
		liquidityFee: 0
	});

	struct ReflectValueSet {
		uint256 rAmount;
		uint256 rTransferAmount;
		uint256 rReflectFee;
		uint256 rOtherFee;
		uint256 tTransferAmount;
		uint256 tReflectFee;
		uint256 tOtherFee;

		uint256 rExtraFee;
		uint256 tExtraFee;
	}

	modifier lockTheSwap {
		areFeesBeingProcessed = true;
		_;
		areFeesBeingProcessed = false;
	}

	constructor() {
		address self = address(this);

		rOwned[owner()] = rTotal;

		router = IDEXRouter(ROUTER_ADDRESS);

		marketingAddress = payable(0x0);

		isExcludedFromFees[owner()] = true;
		isExcludedFromFees[marketingAddress] = true;
		isExcludedFromFees[self] = true;
		isExcludedFromFees[DEAD_ADDRESS] = true;

		isExcludedFromMaxWallet[owner()] = true;
		isExcludedFromMaxWallet[marketingAddress] = true;
		isExcludedFromMaxWallet[self] = true;
		isExcludedFromMaxWallet[DEAD_ADDRESS] = true;

		//new - exclude owner from rewards for fair distribution
		tOwned[owner()] = tokenFromReflection(rOwned[owner()]);
		isExcludedFromRewards[owner()] = true;
		excluded.push(owner());

		emit Transfer(ZERO_ADDRESS, owner(), tTotal);
	}

	function name() public pure returns (string memory) {
		return NAME;
	}

	function symbol() public pure returns (string memory) {
		return SYMBOL;
	}

	function decimals() public pure returns (uint8) {
		return DECIMALS;
	}

	function totalSupply() public view override returns (uint256) {
		return tTotal;
	}

	function balanceOf(address account) public view override returns (uint256) {
		if (isExcludedFromRewards[account]) return tOwned[account];
		return tokenFromReflection(rOwned[account]);
	}

	function transfer(address recipient, uint256 amount) public override returns (bool) {
		_transfer(_msgSender(), recipient, amount);
		return true;
	}

	function allowance(address owner, address spender) public view override returns (uint256) {
		return allowances[owner][spender];
	}

	function approve(address spender, uint256 amount) public override returns (bool) {
		_approve(_msgSender(), spender, amount);
		return true;
	}

	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
		_transfer(sender, recipient, amount);

		uint256 currentAllowance = allowances[sender][_msgSender()];
		require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");

		unchecked {
			_approve(sender, _msgSender(), currentAllowance - amount);
		}

		return true;
	}

	function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
		_approve(_msgSender(), spender, allowances[_msgSender()][spender] + addedValue);
		return true;
	}

	function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
		uint256 currentAllowance = allowances[_msgSender()][spender];
		require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");

		unchecked {
			_approve(_msgSender(), spender, currentAllowance - subtractedValue);
		}

		return true;
	}

	function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
		require(rAmount <= rTotal, "Amount must be less than total reflections");
		uint256 currentRate = _getRate();
		return rAmount / currentRate;
	}

	function excludeFromRewards(address account) external onlyOwner {
		require(!isExcludedFromRewards[account], "Account is already excluded");

		if (rOwned[account] > 0) {
			tOwned[account] = tokenFromReflection(rOwned[account]);
		}

		isExcludedFromRewards[account] = true;
		excluded.push(account);
	}

	function includeInRewards(address account) external onlyOwner {
		require(isExcludedFromRewards[account], "Account is not excluded");

		for (uint256 i = 0; i < excluded.length; i++) {
			if (excluded[i] == account) {
				excluded[i] = excluded[excluded.length - 1];
				tOwned[account] = 0;
				isExcludedFromRewards[account] = false;
				excluded.pop();
				break;
			}
		}
	}

	function _getValues(uint256 tAmount, bool takeFee, uint256 extraFee) private view returns (ReflectValueSet memory set) {
		set = _getTValues(tAmount, takeFee, extraFee);
		(set.rAmount, set.rTransferAmount, set.rReflectFee, set.rOtherFee, set.rExtraFee) = _getRValues(set, tAmount, takeFee, _getRate());
		return set;
	}

	function _getTValues(uint256 tAmount, bool takeFee, uint256 extraFee) private view returns (ReflectValueSet memory set) {
		if (!takeFee) {
			set.tTransferAmount = tAmount;
			return set;
		}

		set.tReflectFee = tAmount * fees.reflectFee / 100;
		set.tExtraFee = tAmount * extraFee / 100;
		set.tOtherFee = tAmount * (fees.marketingFee + fees.liquidityFee) / 100;
		set.tTransferAmount = tAmount - set.tReflectFee - set.tOtherFee - set.tExtraFee;

		return set;
	}

	function _getRValues(ReflectValueSet memory set, uint256 tAmount, bool takeFee, uint256 currentRate) private pure returns (uint256 rAmount, uint256 rTransferAmount, uint256 rReflectFee, uint256 rOtherFee, uint256 rExtraFee) {
		rAmount = tAmount * currentRate;

		if (!takeFee) {
			return (rAmount, rAmount, 0, 0, 0);
		}

		rReflectFee = set.tReflectFee * currentRate;
		rOtherFee = set.tOtherFee * currentRate;
		rExtraFee = set.tExtraFee * currentRate;
		rTransferAmount = rAmount - rReflectFee - rOtherFee - rExtraFee;
		return (rAmount, rTransferAmount, rReflectFee, rOtherFee, rExtraFee);
	}

	function _getRate() private view returns (uint256) {
		(uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
		return rSupply / tSupply;
	}

	function _getCurrentSupply() private view returns (uint256, uint256) {
		uint256 rSupply = rTotal;
		uint256 tSupply = tTotal;

		for (uint256 i = 0; i < excluded.length; i++) {
			if (rOwned[excluded[i]] > rSupply || tOwned[excluded[i]] > tSupply) return (rTotal, tTotal);
			rSupply -= rOwned[excluded[i]];
			tSupply -= tOwned[excluded[i]];
		}

		if (rSupply < rTotal / tTotal) return (rTotal, tTotal);
		return (rSupply, tSupply);
	}

	function _approve(address owner, address spender, uint256 amount) private {
		require(owner != ZERO_ADDRESS, "ERC20: approve from the zero address");
		require(spender != ZERO_ADDRESS, "ERC20: approve to the zero address");

		allowances[owner][spender] = amount;

		emit Approval(owner, spender, amount);
	}

	function _transfer(address from, address to, uint256 amount) private {
		require(from != ZERO_ADDRESS, "ERC20: transfer from the zero address");
		require(to != ZERO_ADDRESS, "ERC20: transfer to the zero address");
		require(!isBot[from], "ERC20: address blacklisted (bot)");
		require(amount > 0, "Transfer amount must be greater than zero");
		require(amount <= balanceOf(from), "You are trying to transfer more than your balance");

		if (maxWalletAmount > 0 && !automatedMarketMakerPairs[to] && !isExcludedFromMaxWallet[to]) {
			require((balanceOf(to) + amount) <= maxWalletAmount, "You are trying to transfer more than the max wallet amount");
		}

		if (launchedAt == 0 && automatedMarketMakerPairs[to]) {
			launchedAt = block.number;
		}

		bool shouldTakeFees = !isExcludedFromFees[from] && !isExcludedFromFees[to];

		uint256 balance = balanceOf(address(this));

		if (balance > maxTxAmountSell) {
			balance = maxTxAmountSell;
		}
		uint256 extraFees = 0;
		if(!automatedMarketMakerPairs[from]) 
		{
			if (isFeeProcessingEnabled && !areFeesBeingProcessed 
        		&& balance >= feeProcessingThreshold 
			) {
				areFeesBeingProcessed = true;
				_processFees(balance);
				areFeesBeingProcessed = false;
			}
			if(automatedMarketMakerPairs[to]){ 
				uint256 blockTime = block.timestamp;
				//first day bot protection = 30% liquidity fee
				if(blockTime < launchedAtTime + 1 days){
					extraFees = 30;
				}
			}
		}

		_tokenTransfer(from, to, amount, shouldTakeFees, extraFees);
	}

	function _takeReflectFees(uint256 rReflectFee) private {
		rTotal -= rReflectFee;
	}

	function _takeOtherFees(uint256 rOtherFee, uint256 tOtherFee) private {
		address self = address(this);

		rOwned[self] += rOtherFee;

		if (isExcludedFromRewards[self]) {
			tOwned[self] += tOtherFee;
		}
	}

	function _takeExtraFees(uint256 rExtraFee, uint256 tExtraFee) private {
		rOwned[DEAD_ADDRESS] += rExtraFee;
		if (isExcludedFromRewards[DEAD_ADDRESS]) {
			tOwned[DEAD_ADDRESS] += tExtraFee;
		}
	}

	function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool shouldTakeFees, uint256 extraFee) private {
		ReflectValueSet memory set = _getValues(tAmount, shouldTakeFees, extraFee);

		if (isExcludedFromRewards[sender]) {
			tOwned[sender] -= tAmount;
		}

		if (isExcludedFromRewards[recipient]) {
			tOwned[recipient] += set.tTransferAmount;
		}

		rOwned[sender] -= set.rAmount;
		rOwned[recipient] += set.rTransferAmount;

		if (shouldTakeFees) {
			_takeReflectFees(set.rReflectFee);
			_takeOtherFees(set.rOtherFee + set.rExtraFee, set.tOtherFee + set.tExtraFee);
			emit Transfer(sender, address(this), set.tOtherFee + set.tExtraFee);
		}

		emit Transfer(sender, recipient, set.tTransferAmount);
	}

	function _processFees(uint256 amount) private lockTheSwap {
		if (amount == 0) return;
		_swapExactTokensForETH(amount);
		marketingAddress.transfer(address(this).balance);
	}

	function _addLiquidity(uint256 amount) private {
		address self = address(this);

		uint256 tokensToSell = amount / 2;
		uint256 tokensForLiquidity = amount - tokensToSell;

		uint256 ethForLiquidity = _swapExactTokensForETH(tokensToSell);

		_approve(self, address(router), MAX_UINT);
		router.addLiquidityETH{value: ethForLiquidity}(self, tokensForLiquidity, 0, 0, DEAD_ADDRESS, block.timestamp);
	}

	function _swapExactTokensForETH(uint256 amountIn) private returns (uint256) {
		address self = address(this);

		address[] memory path = new address[](2);
		path[0] = self;
		path[1] = router.WETH();

		_approve(self, address(router), MAX_UINT);

		uint256 previousBalance = self.balance;
		router.swapExactTokensForETHSupportingFeeOnTransferTokens(amountIn, 0, path, self, block.timestamp);
		return self.balance - previousBalance;
	}

	function openTrading(uint256 tokensForLiquidity) external payable onlyOwner {
		address self = address(this);
		require(!isTradingOpen, "Trading is already open");
		require(balanceOf(_msgSender()) >= tokensForLiquidity, "Insufficient token balance for initial liquidity");
		require(msg.value > 0, "Insufficient ETH for initial liquidity");

		_tokenTransfer(_msgSender(), self, tokensForLiquidity, false, 0);

		//Create pair
		address pairAddress = IDEXFactory(router.factory()).createPair(self, router.WETH());
		automatedMarketMakerPairs[pairAddress] = true;
		isExcludedFromMaxWallet[pairAddress] = true;

		//Add liquidity
		_approve(self, address(router), MAX_UINT);
		router.addLiquidityETH{value: msg.value}(self, tokensForLiquidity, 0, 0, owner(), block.timestamp);

		isFeeProcessingEnabled = true;
		isTradingOpen = true;
		launchedAtTime = block.timestamp;
	}

	function setIsBot(address[] memory accounts, bool value) external onlyOwner {
		for (uint256 i = 0; i < accounts.length; i++){
			isBot[accounts[i]] = value;
		}
	}

	receive() external payable {}
}