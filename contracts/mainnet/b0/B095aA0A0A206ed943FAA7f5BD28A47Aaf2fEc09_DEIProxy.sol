// Be name Khoda
// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma abicoder v2;
// =================================================================================================================
//  _|_|_|    _|_|_|_|  _|    _|    _|_|_|      _|_|_|_|  _|                                                       |
//  _|    _|  _|        _|    _|  _|            _|            _|_|_|      _|_|_|  _|_|_|      _|_|_|    _|_|       |
//  _|    _|  _|_|_|    _|    _|    _|_|        _|_|_|    _|  _|    _|  _|    _|  _|    _|  _|        _|_|_|_|     |
//  _|    _|  _|        _|    _|        _|      _|        _|  _|    _|  _|    _|  _|    _|  _|        _|           |
//  _|_|_|    _|_|_|_|    _|_|    _|_|_|        _|        _|  _|    _|    _|_|_|  _|    _|    _|_|_|    _|_|_|     |
// =================================================================================================================
// ========================= DEIProxy ============================
// ===============================================================
// DEUS Finance: https://github.com/DeusFinance

// Primary Author(s)
// Vahid Gh: https://github.com/vahid-dev

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDEIStablecoin {
	function global_collateral_ratio() external view returns (uint);
}

interface IDEIPool {
	function mintFractionalDEI(
		uint256 collateral_amount,
		uint256 deus_amount,
		uint256 collateral_price,
		uint256 deus_current_price,
		uint256 expireBlock,
		bytes[] calldata sigs
	) external returns (uint);

	function minting_fee() external view returns (uint);
}


interface IUniswapV2Router02 {
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

	function swapExactETHForTokens(
		uint amountOutMin, 
		address[] calldata path, 
		address to, 
		uint deadline
	) external payable returns (uint[] memory amounts);

	function getAmountsIn(
		uint amountOut, 
		address[] memory path
	) external view returns (uint[] memory amounts);

	function getAmountsOut(
		uint amountIn, 
		address[] memory path
	) external view returns (uint[] memory amounts);
}

interface ISSP {
	function swapUsdcForExactDei(uint deiNeededAmount) external;
	function getAmountIn(uint deiNeededAmount) external view returns (uint usdcAmount);
}


contract DEIProxy is Ownable {

	struct ProxyInput {
		uint amountIn;
		uint minAmountOut;
		uint deusPriceUSD;
		uint colPriceUSD;
		uint usdcForMintAmount;
		uint deusNeededAmount;
		uint expireBlock;
		bytes[] sigs;
	}

	/* ========== STATE VARIABLES ========== */

	address public uniswapRouter;
	address public minterPool;
	address public sspAddress;
	address public deiAddress;
	address public deusAddress;
	address public usdcAddress;

	address[] public dei2deusPath;
	address[] public deus2deiPath;

	uint public collateralMissingDecimalsD18 = 1e12;  // missing decimal of collateral token (USDC)
	uint public deadline = 0xf000000000000000000000000000000000000000000000000000000000000000;

	/* ========== CONSTRUCTOR ========== */

	constructor(
		address _uniswapRouter,
		address _minterPool,
		address _deusAddress,
		address _deiAddress,
		address _usdcAddress,
		address[] memory _dei2deusPath,
		address[] memory _deus2deiPath
	) {
		uniswapRouter = _uniswapRouter;
		minterPool = _minterPool;
		deusAddress = _deusAddress;		
		deiAddress = _deiAddress;
		usdcAddress = _usdcAddress;

		dei2deusPath = _dei2deusPath;
		deus2deiPath = _deus2deiPath;

		IERC20(usdcAddress).approve(_uniswapRouter, type(uint256).max);
		IERC20(deusAddress).approve(_uniswapRouter, type(uint256).max);
		IERC20(usdcAddress).approve(_minterPool, type(uint256).max);
		IERC20(deusAddress).approve(_minterPool, type(uint256).max);
		IERC20(deiAddress).approve(_uniswapRouter, type(uint256).max);
	}

	/* ========== RESTRICTED FUNCTIONS ========== */

	function setSSP(address _sspAddress) external onlyOwner {
		sspAddress = _sspAddress;
		IERC20(usdcAddress).approve(sspAddress, type(uint256).max);
	}

	function setMinterPool(address _minterPool) external onlyOwner {
		minterPool = _minterPool;
		IERC20(usdcAddress).approve(_minterPool, type(uint256).max);
		IERC20(deusAddress).approve(_minterPool, type(uint256).max);
	}

	function approve(address token, address to) external onlyOwner {
		IERC20(token).approve(to, type(uint256).max);
	}

	function emergencyWithdrawERC20(address token, address to, uint amount) external onlyOwner {
		IERC20(token).transfer(to, amount);
	}

	function emergencyWithdrawETH(address to, uint amount) external onlyOwner {
		payable(to).transfer(amount);
	}

	/* ========== PUBLIC FUNCTIONS ========== */

	function USDC2DEI(ProxyInput memory proxyInput) external returns (uint deiAmount) {
		IERC20(usdcAddress).transferFrom(msg.sender, address(this), proxyInput.amountIn);

		uint globalCollateralRatio = IDEIStablecoin(deiAddress).global_collateral_ratio();
		require(0 < globalCollateralRatio && globalCollateralRatio < 1e6, "Minter Proxy: Collateral ratio needs to be between .000001 and .999999");

		// buy needed deus
		uint deiNeededAmount = IUniswapV2Router02(uniswapRouter).getAmountsIn(proxyInput.deusNeededAmount, dei2deusPath)[0];
		ISSP(sspAddress).swapUsdcForExactDei(deiNeededAmount);
		IUniswapV2Router02(uniswapRouter).swapTokensForExactTokens(proxyInput.deusNeededAmount, deiNeededAmount, dei2deusPath, address(this), deadline);

		deiAmount = IDEIPool(minterPool).mintFractionalDEI(proxyInput.usdcForMintAmount, proxyInput.deusNeededAmount, proxyInput.colPriceUSD, proxyInput.deusPriceUSD, proxyInput.expireBlock, proxyInput.sigs);

		// swap residual deus to dei
		uint residualDeus = IERC20(deusAddress).balanceOf(address(this));
		if (residualDeus > 0) {
			uint residualDei = IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(residualDeus, 0, deus2deiPath, address(this), deadline)[1];
			deiAmount += residualDei;
		}
		require(deiAmount >= proxyInput.minAmountOut, "Minter Proxy: Insufficient output amount");

		IERC20(deiAddress).transfer(msg.sender, deiAmount);

		emit Buy(usdcAddress, deiAmount, globalCollateralRatio);
	}


	function ERC202DEI(ProxyInput memory proxyInput, address[] memory path) external returns (uint deiAmount) {
		require(path.length >= 2, "Minter Proxy: wrong path");
		IERC20(path[0]).transferFrom(msg.sender, address(this), proxyInput.amountIn);

		// approve if it doesn't have allowance
		if (IERC20(path[0]).allowance(address(this), uniswapRouter) == 0) {IERC20(path[0]).approve(uniswapRouter, type(uint).max);}

		//swap erc20 tokens to usdc
		IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(proxyInput.amountIn, 0, path, address(this), deadline)[path.length-1];

		uint globalCollateralRatio = IDEIStablecoin(deiAddress).global_collateral_ratio();
		require(0 < globalCollateralRatio && globalCollateralRatio < 1e6, "Minter Proxy: Collateral ratio needs to be between .000001 and .999999");

		// buy needed deus
		uint deiNeededAmount = IUniswapV2Router02(uniswapRouter).getAmountsIn(proxyInput.deusNeededAmount, dei2deusPath)[0];
		ISSP(sspAddress).swapUsdcForExactDei(deiNeededAmount);
		IUniswapV2Router02(uniswapRouter).swapTokensForExactTokens(proxyInput.deusNeededAmount, deiNeededAmount, dei2deusPath, address(this), deadline);

		deiAmount = IDEIPool(minterPool).mintFractionalDEI(proxyInput.usdcForMintAmount, proxyInput.deusNeededAmount, proxyInput.colPriceUSD, proxyInput.deusPriceUSD, proxyInput.expireBlock, proxyInput.sigs);

		// swap residual deus to dei
		uint residualDeus = IERC20(deusAddress).balanceOf(address(this));
		if (residualDeus > 0) {
			uint residualDei = IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(residualDeus, 0, deus2deiPath, address(this), deadline)[1];
			deiAmount += residualDei;
		}
		require(deiAmount >= proxyInput.minAmountOut, "Minter Proxy: Insufficient output amount");

		IERC20(deiAddress).transfer(msg.sender, deiAmount);

		emit Buy(path[0], deiAmount, globalCollateralRatio);
	}

	function Nativecoin2DEI(ProxyInput memory proxyInput, address[] memory path) payable external returns (uint deiAmount) {
		require(path.length >= 2, "Minter Proxy: wrong path");

		// swap nativecoin to usdc
		IUniswapV2Router02(uniswapRouter).swapExactETHForTokens{value: msg.value}(0, path, address(this), deadline)[path.length-1];

		uint globalCollateralRatio = IDEIStablecoin(deiAddress).global_collateral_ratio();
		require(0 < globalCollateralRatio && globalCollateralRatio < 1e6, "Minter Proxy: Collateral ratio needs to be between .000001 and .999999");

		// buy needed deus
		uint deiNeededAmount = IUniswapV2Router02(uniswapRouter).getAmountsIn(proxyInput.deusNeededAmount, dei2deusPath)[0];
		ISSP(sspAddress).swapUsdcForExactDei(deiNeededAmount);
		IUniswapV2Router02(uniswapRouter).swapTokensForExactTokens(proxyInput.deusNeededAmount, deiNeededAmount, dei2deusPath, address(this), deadline);

		deiAmount = IDEIPool(minterPool).mintFractionalDEI(proxyInput.usdcForMintAmount, proxyInput.deusNeededAmount, proxyInput.colPriceUSD, proxyInput.deusPriceUSD, proxyInput.expireBlock, proxyInput.sigs);

		// swap residual deus to dei
		uint residualDeus = IERC20(deusAddress).balanceOf(address(this));
		if (residualDeus > 0) {
			uint residualDei = IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(residualDeus, 0, deus2deiPath, address(this), deadline)[1];
			deiAmount += residualDei;
		}
		require(deiAmount >= proxyInput.minAmountOut, "Minter Proxy: Insufficient output amount");

		IERC20(deiAddress).transfer(msg.sender, deiAmount);

		emit Buy(path[0], deiAmount, globalCollateralRatio);
	}

	/* ========== VIEWS ========== */

	struct MintFD_Params {
		uint256 deus_price_usd; 
		uint256 col_price_usd;
		uint256 collateral_amount;
		uint256 col_ratio;
	}

	function calcMintFractionalDEI(MintFD_Params memory params) public pure returns (uint256, uint256) {
		uint256 c_dollar_value_d18;
		c_dollar_value_d18 = (params.collateral_amount * params.col_price_usd) / (1e6);
		uint calculated_deus_dollar_value_d18 = ((c_dollar_value_d18 * (1e6)) / params.col_ratio) - c_dollar_value_d18;
		uint calculated_deus_needed = (calculated_deus_dollar_value_d18 * (1e6)) / params.deus_price_usd;
		return (c_dollar_value_d18 + calculated_deus_dollar_value_d18, calculated_deus_needed); // mint amount, deus needed
	}

	function getUSDC2DEIInputs(uint amountIn, uint deusPriceUSD, uint colPriceUSD) public view returns (uint amountOut, uint usdcForMintAmount, uint deusNeededAmount) {
		uint deusUsedAmount;
		uint globalCollateralRatio = IDEIStablecoin(deiAddress).global_collateral_ratio();
		(, deusNeededAmount) = calcMintFractionalDEI(MintFD_Params(deusPriceUSD, colPriceUSD, amountIn * collateralMissingDecimalsD18 * globalCollateralRatio / 1e6, globalCollateralRatio));
		uint deiNeededAmount = IUniswapV2Router02(uniswapRouter).getAmountsIn(deusNeededAmount, dei2deusPath)[0];
		uint usdcNeededAmount = ISSP(sspAddress).getAmountIn(deiNeededAmount);
		usdcForMintAmount = amountIn - usdcNeededAmount;
		(amountOut, deusUsedAmount) = calcMintFractionalDEI(MintFD_Params(deusPriceUSD, colPriceUSD, usdcForMintAmount * collateralMissingDecimalsD18, globalCollateralRatio));
		uint deusExtraAmount = deusNeededAmount - deusUsedAmount;
		uint deiExtraAmount = IUniswapV2Router02(uniswapRouter).getAmountsOut(deusExtraAmount, deus2deiPath)[1];
		uint mintingFee = IDEIPool(minterPool).minting_fee();
		amountOut = (amountOut * (uint256(1e6) - mintingFee)) / (1e6);
		amountOut += deiExtraAmount;
	}

	function getERC202DEIInputs(uint amountIn, uint deusPriceUSD, uint colPriceUSD, address[] memory path) public view returns (uint amountOut, uint usdcForMintAmount, uint deusNeededAmount) {
		amountIn = IUniswapV2Router02(uniswapRouter).getAmountsOut(amountIn, path)[path.length-1];
		uint deusUsedAmount;
		uint globalCollateralRatio = IDEIStablecoin(deiAddress).global_collateral_ratio();
		(, deusNeededAmount) = calcMintFractionalDEI(MintFD_Params(deusPriceUSD, colPriceUSD, amountIn * collateralMissingDecimalsD18 * globalCollateralRatio / 1e6, globalCollateralRatio));
		uint deiNeededAmount = IUniswapV2Router02(uniswapRouter).getAmountsIn(deusNeededAmount, dei2deusPath)[0];
		uint usdcNeededAmount = ISSP(sspAddress).getAmountIn(deiNeededAmount);
		usdcForMintAmount = amountIn - usdcNeededAmount;
		(amountOut, deusUsedAmount) = calcMintFractionalDEI(MintFD_Params(deusPriceUSD, colPriceUSD, usdcForMintAmount * collateralMissingDecimalsD18, globalCollateralRatio));
		uint deusExtraAmount = deusNeededAmount - deusUsedAmount;
		uint deiExtraAmount = IUniswapV2Router02(uniswapRouter).getAmountsOut(deusExtraAmount, deus2deiPath)[1];
		uint mintingFee = IDEIPool(minterPool).minting_fee();
		amountOut = (amountOut * (uint256(1e6) - mintingFee)) / (1e6);
		amountOut += deiExtraAmount;
	}

	/* ========== EVENTS ========== */

	event Buy(address tokenIn, uint amountOut, uint globalCollateralRatio);
}

// Dar panahe Khoda

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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