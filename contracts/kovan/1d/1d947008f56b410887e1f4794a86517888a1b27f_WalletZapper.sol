/**
 *Submitted for verification at Etherscan.io on 2021-07-30
*/

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.1;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma abicoder v2;

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

interface IAaveLendingPool {
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);
}

// Full interface here: https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Router01.sol
interface IUniswapSimple {
        function WETH() external pure returns (address);
        function swapTokensForExactTokens(
                uint amountOut,
                uint amountInMax,
                address[] calldata path,
                address to,
                uint deadline
        ) external returns (uint[] memory amounts);
	function swapExactTokensForTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);
}

// Decisions: will start with aave over compound (easier API - has `onBehalfOf`, referrals), compound can be added later if needed
// uni v3 needs to be supported since it's proving that it's efficient and the router is different
contract WalletZapper {
	struct Trade {
		IUniswapSimple router;
		uint amountIn;
		uint amountOutMin;
		address[] path;
		bool wrap;
	}
	struct DiversificationTrade {
		address tokenOut;
		uint24 fee;
		uint allocPts;
		uint amountOutMin;
		bool wrap;
	}

	address constant WETH = 0xd0A1E359811322d97991E03f863a0C30C2cF029C;

	address public admin;
	mapping (address => bool) public allowedSpenders;
	IAaveLendingPool public lendingPool;
	uint16 aaveRefCode;
	constructor(IAaveLendingPool _lendingPool, uint16 _aaveRefCode, address[] memory spenders) {
		admin = msg.sender;
		lendingPool = _lendingPool;
		aaveRefCode = _aaveRefCode;
		allowedSpenders[address(_lendingPool)] = true;
		for (uint i=0; i!=spenders.length; i++) {
			allowedSpenders[spenders[i]] = true;
		}
	}

	function approveMax(address token, address spender) external {
		require(msg.sender == admin, "NOT_ADMIN");
		require(allowedSpenders[spender], "NOT_ALLOWED");
		IERC20(token).approve(spender, type(uint256).max);
	}

	// Uniswap V2
	// We're choosing not to implement a special function for performing a single trade since it's not that much of a gas saving compared to this
	// We're also choosing not to implement a method like diversifyV3 which first trades the input asset to WETH and then WETH to whatever,
	//  because we expect diversifyV3 to be enough
	// We can very easily deploy a new Zapper and upgrade to it since it's just a UI change
	function exchangeV2(address[] calldata assetsToUnwrap, Trade[] memory trades) external {
		for (uint i=0; i!=assetsToUnwrap.length; i++) {
			lendingPool.withdraw(assetsToUnwrap[i], type(uint256).max, address(this));
		}
		address to = msg.sender;
		uint deadline = block.timestamp;
		uint len = trades.length;
		for (uint i=0; i!=len; i++) {
			Trade memory trade = trades[i];
			if (!trade.wrap) {
				trade.router.swapExactTokensForTokens(trade.amountIn, trade.amountOutMin, trade.path, to, deadline);
			} else {
				uint[] memory amounts = trade.router.swapExactTokensForTokens(trade.amountIn, trade.amountOutMin, trade.path, address(this), deadline);
				uint lastIdx = trade.path.length - 1;
				lendingPool.deposit(trade.path[lastIdx], amounts[lastIdx], to, aaveRefCode);
			}
		}
		// @TODO are there ways to ensure there are no leftover funds?

	}

	// go in/out of lending assets
	function wrapLending(address[] calldata assetsToWrap) external {
		for (uint i=0; i!=assetsToWrap.length; i++) {
			lendingPool.deposit(assetsToWrap[i], IERC20(assetsToWrap[i]).balanceOf(address(this)), msg.sender, aaveRefCode);
		}
	}
	function unwrapLending(address[] calldata assetsToUnwrap) external {
		for (uint i=0; i!=assetsToUnwrap.length; i++) {
			lendingPool.withdraw(assetsToUnwrap[i], type(uint256).max, msg.sender);
		}
	}

	// wrap WETH
	function wrapETH() payable external {
		// TODO: it may be slightly cheaper to call deposit() directly
		payable(WETH).transfer(msg.value);
	}

	// Uniswap V3
	function tradeV3(ISwapRouter uniV3Router, ISwapRouter.ExactInputParams calldata params) external returns (uint) {
		return uniV3Router.exactInput(params);
	}

	function tradeV3Single(ISwapRouter uniV3Router, ISwapRouter.ExactInputSingleParams calldata params, bool wrapOutputToLending) external returns (uint) {
		uint amountOut = uniV3Router.exactInputSingle(params);
		if(wrapOutputToLending) {
			lendingPool.deposit(params.tokenOut, amountOut, msg.sender, aaveRefCode);
		}
		return amountOut;
	}

	// @TODO: unwrap input from aToken?
	function diversifyV3(ISwapRouter uniV3Router, address inputAsset, uint24 inputFee, uint inputMinOut, DiversificationTrade[] memory trades) external {
		uint inputAmount;
		if (inputAsset != address(0)) {
			inputAmount = uniV3Router.exactInputSingle(
			    ISwapRouter.ExactInputSingleParams (
				inputAsset,
				WETH,
				inputFee,
				address(this),
				block.timestamp,
				IERC20(inputAsset).balanceOf(address(this)),
				inputMinOut,
				0
			    )
			);
		} else {
			inputAmount = IERC20(WETH).balanceOf(address(this));
		}

		uint totalAllocPts;
		uint len = trades.length;
		for (uint i=0; i!=len; i++) {
			DiversificationTrade memory trade = trades[i];
			totalAllocPts += trade.allocPts;
			if (!trade.wrap) {
				uniV3Router.exactInputSingle(
				    ISwapRouter.ExactInputSingleParams (
					WETH,
					trade.tokenOut,
					trade.fee,
					msg.sender,
					block.timestamp,
					inputAmount * trade.allocPts / 1000,
					trade.amountOutMin,
					0
				    )
				);
			} else {
				uint amountToDeposit = uniV3Router.exactInputSingle(
				    ISwapRouter.ExactInputSingleParams (
					WETH,
					trade.tokenOut,
					trade.fee,
					address(this),
					block.timestamp,
					inputAmount * trade.allocPts / 1000,
					trade.amountOutMin,
					0
				    )
				);
				lendingPool.deposit(trade.tokenOut, amountToDeposit, msg.sender, aaveRefCode);
			}
		}

		IERC20 wrappedETH = IERC20(WETH);
		uint wrappedETHAmount = wrappedETH.balanceOf(address(this));
		// NOTE: what if there is dust?
		if (wrappedETHAmount > 0) require(wrappedETH.transfer(msg.sender, wrappedETHAmount));
		// require(totalAllocPts == 1000, "ALLOC_PTS");
	}

	function recoverFunds(IERC20 token, uint amount) external {
		require(msg.sender == admin, "NOT_ADMIN");
		token.transfer(admin, amount);
	}
}