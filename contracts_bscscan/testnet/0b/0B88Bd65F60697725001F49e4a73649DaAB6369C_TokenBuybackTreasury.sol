// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

// this is a token buyback contract

import "./libs/IBEP20.sol";
import "./libs/SafeBEP20.sol";
import "./libs/SafeMath.sol";
import "./libs/Ownable.sol";
import "./libs/ReentrancyGuard.sol";
import "./libs/Address.sol";
import "./modules/IUniswapV2Pair.sol";
import "./modules/IUniswapV2Factory.sol";
import "./modules/IUniswapV2Router.sol";
import "./modules/IWETH.sol";

contract TokenBuybackTreasury is ReentrancyGuard, Ownable
{
	using SafeMath for uint256;
	using SafeMath for IBEP20;
	using SafeBEP20 for IBEP20;
	bool public stopped = false;

	uint256 constant DEFAULT__BUYBACK_PERCENT = 100e16; // 100%

	address constant public FURNACE = 0x000000000000000000000000000000000000dEaD;

  // wBNB MAINNET: 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c
  // wBNB TESTNET: 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd
  address constant public WBNB = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;

	// swapTarget => approval status
	mapping(address => bool) public approvedTargets;

	address public immutable buybackToken; //token bought and burned


	//no deadline errors
	uint256 private constant deadline = 0xf000000000000000000000000000000000000000000000000000000000000000;
	//no allowance errors
	uint256 private constant permitAllowance = 79228162514260000000000000000;

	// mainnet router 0x10ED43C718714eb63d5aA57B78B54704E256024E
	// testnet router 0xD99D1c33F9fC3444f8101754aBC46c52416550D1
	IUniswapV2Router02 private constant router = IUniswapV2Router02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);

	// mainnet factory 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73
	// testnet factory 0x6725F303b657a9451d8BA641348b6761A6CC7a17
	IUniswapV2Factory private constant uniswapFactory = IUniswapV2Factory(0x6725F303b657a9451d8BA641348b6761A6CC7a17);


	uint256 public rewardBuybackTokenAmount = DEFAULT__BUYBACK_PERCENT;

	address private _operator;

	event OperatorTransferred(
		address indexed previousOperator,
		address indexed newOperator
	);
	event zapOut(
			address sender,
			address pool,
			address token,
			uint256 tokensRec
	);


	modifier onlyOperator() {
			require(_operator == msg.sender, "Operator: caller is not the operator");
			_;
	}

		// circuit breaker modifiers
	modifier stopInEmergency {
			if (stopped) {
					revert("Temporarily Paused");
			} else {
					_;
			}
	}

	receive() external payable { }

	// must set address of buyback token at start
	// default route token is wbnb
	constructor (
		address _buybackToken  // address of token that is to be purchased and burned
		) public {
		buybackToken = _buybackToken;
		_operator = msg.sender;
	}

		// - to Pause the contract in an emergency
	function toggleContractActive() public onlyOwner {
			stopped = !stopped;
	}


	// views operator address
	function operator() public view returns (address) {
        return _operator;
    }

	// transferOperator function
  function transferOperator(address newOperator) public onlyOperator {
      require(newOperator != address(0), "TransferOperator: new operator is the zero address");
      emit OperatorTransferred(_operator, newOperator);
      _operator = newOperator;
    }

		//the following functions are used by the zap functions
		//they are just erc20 functions but to keep the zap functions consistent, they are put here
		function _getBalance(address token) internal view returns (uint256 balance){
				if (token == address(0)) {
					balance = address(this).balance;
				} else {
					balance = IBEP20(token).balanceOf(address(this));
				}
			}

			function _approveToken(address token, address spender) internal {
        IBEP20 _token = IBEP20(token);
        if (_token.allowance(address(this), spender) > 0) return;
        else {
            _token.safeApprove(spender, type(uint256).max);
        }
    }

    function _approveToken(
        address token,
        address spender,
        uint256 amount
    ) internal {
        IBEP20(token).safeApprove(spender, 0);
        IBEP20(token).safeApprove(spender, amount);
    }

		/**
		 @dev Transfer tokens from msg.sender to this contract
		 @param token The ERC20 token to transfer to this contract
		 @param shouldSellEntireBalance If True transfers entrire allowable amount from another contract
		 @return Quantity of tokens transferred to this contract
	*/
	 function _pullTokens(
			 address token,
			 uint256 amount,
			 bool shouldSellEntireBalance
	 ) internal returns (uint256) {
			 if (shouldSellEntireBalance) {
					 require(
							 Address.isContract(msg.sender),
							 "ERR: shouldSellEntireBalance is true for EOA"
					 );

					 uint256 allowance =
							 IBEP20(token).allowance(msg.sender, address(this));
					 IBEP20(token).safeTransferFrom(
							 msg.sender,
							 address(this),
							 allowance
					 );

					 return allowance;
			 } else {
					 IBEP20(token).safeTransferFrom(msg.sender, address(this), amount);

					 return amount;
			 }
	 }



		// the below function removes LP from a pool and also unwraps the tokens in the LP
		/**
				@notice Zap out in both tokens
				@param fromPoolAddress Pool from which to remove liquidity
				@param incomingLP Quantity of LP to remove from pool
				@return amountA Quantity of tokenA received after zapout
				@return amountB Quantity of tokenB received after zapout
		*/
		function UnwrapLiquidityToken(address fromPoolAddress, uint256 incomingLP) public stopInEmergency onlyOperator returns (uint256 amountA, uint256 amountB) {
				IUniswapV2Pair pair = IUniswapV2Pair(fromPoolAddress);

				require(address(pair) != address(0), "Pool Cannot be Zero Address");

				// get reserves
				address token0 = pair.token0();
				address token1 = pair.token1();

				IBEP20(fromPoolAddress).safeTransferFrom(
						msg.sender,
						address(this),
						incomingLP
				);

				_approveToken(fromPoolAddress, address(router), incomingLP);

				if (token0 == WBNB || token1 == WBNB) {
						address _token = token0 == WBNB ? token1 : token0;
						(amountA, amountB) = router.removeLiquidityETH(
								_token,
								incomingLP,
								1,
								1,
								address(this),
								deadline
						);
						// send tokens to contract for buyback
						IBEP20(_token).safeTransfer(address(this), amountA);
						Address.sendValue(payable(address(this)), amountB);
				} else {
						(amountA, amountB) = router.removeLiquidity(
								token0,
								token1,
								incomingLP,
								1,
								1,
								address(this),
								deadline
						);

						// send tokens to contract for buyback
						IBEP20(token0).safeTransfer(address(this), amountA);
						IBEP20(token1).safeTransfer(address(this), amountB);
				}
				emit zapOut(msg.sender, fromPoolAddress, token0, amountA);
				emit zapOut(msg.sender, fromPoolAddress, token1, amountB);
		}


// zaps out into a single token
// used by ZapOutWithPermit function

/**
		@notice Zap out in a single token
		@param toTokenAddress Address of desired token
		@param fromPoolAddress Pool from which to remove liquidity
		@param incomingLP Quantity of LP to remove from pool
		@param minTokensRec Minimum quantity of tokens to receive
		@param swapTargets Execution targets for swaps
		@param swapData DEX swap data
		@param shouldSellEntireBalance If True transfers entrire allowable amount from another contract
*/
function ZapOut(
		address toTokenAddress,
		address fromPoolAddress,
		uint256 incomingLP,
		uint256 minTokensRec,
		address[] memory swapTargets,
		bytes[] memory swapData,
		bool shouldSellEntireBalance
) public stopInEmergency returns (uint256 tokensRec) {
		(uint256 amount0, uint256 amount1) =
				_removeLiquidity(
						fromPoolAddress,
						incomingLP,
						shouldSellEntireBalance
				);

		//swaps tokens to token
		tokensRec = _swapTokens(
				fromPoolAddress,
				amount0,
				amount1,
				toTokenAddress,
				swapTargets,
				swapData
		);
		require(tokensRec >= minTokensRec, "High Slippage");

		// transfer toTokens to sender
		if (toTokenAddress == address(0)) {
				payable(msg.sender).transfer(tokensRec);
		} else {
				IBEP20(toTokenAddress).safeTransfer(
						msg.sender,
						tokensRec
				);
		}

		tokensRec = tokensRec;

		emit zapOut(msg.sender, fromPoolAddress, toTokenAddress, tokensRec);

		return tokensRec;
}


//function to remove liquidity and sell into a single token
//potentially risky due to slippage

	/**
	@notice Zap out in a single token with permit
	@param toTokenAddress Address of desired token
	@param fromPoolAddress Pool from which to remove liquidity
	@param incomingLP Quantity of LP to remove from pool
	@param minTokensRec Minimum quantity of tokens to receive
	@param permitSig Signature for permit
	@param swapTargets Execution targets for swaps
	@param swapData DEX swap data
	*/
	function ZapOutWithPermit(
			address toTokenAddress,
			address fromPoolAddress,
			uint256 incomingLP,
			uint256 minTokensRec,
			bytes calldata permitSig,
			address[] memory swapTargets,
			bytes[] memory swapData
	) public stopInEmergency onlyOperator returns (uint256) {
			// permit
			_permit(fromPoolAddress, permitAllowance, permitSig);

			return (
					ZapOut(
							toTokenAddress,
							fromPoolAddress,
							incomingLP,
							minTokensRec,
							swapTargets,
							swapData,
							false
					)
			);
	}

	function _permit(
			address fromPoolAddress,
			uint256 amountIn,
			bytes memory permitSig
	) internal {
			require(permitSig.length == 65, "Invalid signature length");

			bytes32 r;
			bytes32 s;
			uint8 v;
			assembly {
					r := mload(add(permitSig, 32))
					s := mload(add(permitSig, 64))
					v := byte(0, mload(add(permitSig, 96)))
			}
			IUniswapV2Pair(fromPoolAddress).permit(
					msg.sender,
					address(this),
					amountIn,
					deadline,
					v,
					r,
					s
			);
	}

	function _removeLiquidity(
			address fromPoolAddress,
			uint256 incomingLP,
			bool shouldSellEntireBalance
	) internal returns (uint256 amount0, uint256 amount1) {
			IUniswapV2Pair pair = IUniswapV2Pair(fromPoolAddress);

			require(address(pair) != address(0), "Pool Cannot be Zero Address");

			address token0 = pair.token0();
			address token1 = pair.token1();

			_pullTokens(fromPoolAddress, incomingLP, shouldSellEntireBalance);

			_approveToken(fromPoolAddress, address(router), incomingLP);

			(amount0, amount1) = router.removeLiquidity(
					token0,
					token1,
					incomingLP,
					1,
					1,
					address(this),
					deadline
			);
			require(amount0 > 0 && amount1 > 0, "Removed Insufficient Liquidity");
	}

	function _swapTokens(
			address fromPoolAddress,
			uint256 amount0,
			uint256 amount1,
			address toToken,
			address[] memory swapTargets,
			bytes[] memory swapData
	) internal returns (uint256 tokensBought) {
			address token0 = IUniswapV2Pair(fromPoolAddress).token0();
			address token1 = IUniswapV2Pair(fromPoolAddress).token1();

			//swap token0 to toToken
			if (token0 == toToken) {
					tokensBought = tokensBought + amount0;
			} else {
					//swap token using 0x swap
					tokensBought =
							tokensBought +
							_fillQuote(
									token0,
									toToken,
									amount0,
									swapTargets[0],
									swapData[0]
							);
			}

			//swap token1 to toToken
			if (token1 == toToken) {
					tokensBought = tokensBought + amount1;
			} else {
					//swap token using 0x swap
					tokensBought =
							tokensBought +
							_fillQuote(
									token1,
									toToken,
									amount1,
									swapTargets[1],
									swapData[1]
							);
			}
	}

	function _fillQuote(
			address fromTokenAddress,
			address toToken,
			uint256 amount,
			address swapTarget,
			bytes memory swapData
	) internal returns (uint256) {
			if (fromTokenAddress == WBNB && toToken == address(0)) {
					IWETH(WBNB).withdraw(amount);
					return amount;
			}

			uint256 valueToSend;
			if (fromTokenAddress == address(0)) {
					valueToSend = amount;
			} else {
					_approveToken(fromTokenAddress, swapTarget, amount);
			}

			uint256 initialBalance = _getBalance(toToken);

			require(approvedTargets[swapTarget], "Target not Authorized");
			(bool success, ) = swapTarget.call{ value: valueToSend }(swapData);
			require(success, "Error Swapping Tokens");

			uint256 finalBalance = _getBalance(toToken) - initialBalance;

			require(finalBalance > 0, "Swapped to Invalid Intermediate");

			return finalBalance;
	}

// NOTE: can just use zapout contract then make the 'send' address immutable as address(this)!
// this makes it impossible to send any tokens anywhere, securing it as a 'treasury'
// then make the only function with an alternative send address as the buyback function
// you can use the Thoreum buyback function or the feeToken buyback function
// but make the buying function able to input token address
// so various tokens could be used to purchase the token


	// function to transfer tokens to WBNB
	// input token Address you want to swap for WBNB
	// input token amount you want to swap for WBNB
	function TriggerTokenTradeForWBNB(address tokenAddressToSwap, uint256 amountTokenToSwap) external stopInEmergency onlyOperator {
		swapTokensForWBNB(tokenAddressToSwap, amountTokenToSwap, address(this));
	}

	function swapTokensForWBNB(address tokenAddressToSwap, uint256 amountTokenToSwap, address to) internal returns (uint256 wbnbBought) {
		address[] memory path = new address[](2);
		path[0] = tokenAddressToSwap;
		path[1] = WBNB;


		router.swapExactTokensForETH(
			0,
			0,
			path,
			to,
			block.timestamp
		);
	}


	// function to buyback BUYBACKTOKEN using WBNB and send to burn address

	function triggerTokenBuyback(uint256 amount) external onlyOwner {
			buybackTokens(amount, FURNACE);
	}

	function buybackTokens(uint256 amount, address to) internal {
		address[] memory path = new address[](2);
		path[0] = WBNB;
		path[1] = buybackToken;

		router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
				0,
				path,
				to,
				block.timestamp
		);
	}

	function setApprovedTargets(
			address[] calldata targets,
			bool[] calldata isApproved
	) external onlyOwner {
			require(targets.length == isApproved.length, "Invalid Input length");

			for (uint256 i = 0; i < targets.length; i++) {
					approvedTargets[targets[i]] = isApproved[i];
			}
	}

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

import "./IBEP20.sol";
import "./SafeMath.sol";
import "./Address.sol";

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeBEP20: decreased allowance below zero"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.7.4;

// SPDX-License-Identifier: MIT License

import "./Context.sol";

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () public {
        address msgSender = _msgSender();
        _owner = msgSender;
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

// File @openzeppelin/contracts/utils/[email protected]

pragma solidity >=0.6.2 <0.8.0;

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

pragma solidity ^0.7.4;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.7.4;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

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



// pragma solidity >=0.6.2;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

interface IWETH {
    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

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

