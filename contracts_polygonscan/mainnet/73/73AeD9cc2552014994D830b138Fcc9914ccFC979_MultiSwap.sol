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
// ========================= MultiSwap ============================
// ===============================================================
// DEUS Finance: https://github.com/DeusFinance

// Primary Author(s)
// Kazem

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IDEIProxy {
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
	function USDC2DEI(ProxyInput memory proxyInput) external returns (uint deiAmount);
    function ERC202DEI(ProxyInput memory proxyInput, address[] memory path) external returns (uint deiAmount);
    function Nativecoin2DEI(ProxyInput memory proxyInput, address[] memory path) payable external returns (uint deiAmount);
    function getUSDC2DEIInputs(uint amountIn, uint deusPriceUSD, uint colPriceUSD) external view returns (uint amountOut, uint usdcForMintAmount, uint deusNeededAmount);
    function getERC202DEIInputs(uint amountIn, uint deusPriceUSD, uint colPriceUSD, address[] memory path) external view returns (uint amountOut, uint usdcForMintAmount, uint deusNeededAmount);
}


interface IUniswapV2Router02 {
	function swapExactTokensForTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external returns (uint[] memory amounts);

	function getAmountsOut(
		uint amountIn, 
		address[] memory path
	) external view returns (uint[] memory amounts);
}

contract MultiSwap is Ownable {
	/* ========== STATE VARIABLES ========== */

	address public uniswapRouter;
	address public deiAddress;
	address public usdcAddress;
    address public deiProxy;

	address[] public dei2deusPath;

	uint public deadline = 0xf000000000000000000000000000000000000000000000000000000000000000;

	/* ========== CONSTRUCTOR ========== */

	constructor(
		address _uniswapRouter,
		address _deiAddress,
		address _usdcAddress,
        address _deiProxy,
		address[] memory _dei2deusPath
	) {
		uniswapRouter = _uniswapRouter;
		deiAddress = _deiAddress;
		usdcAddress = _usdcAddress;
        deiProxy = _deiProxy;

		dei2deusPath = _dei2deusPath;

		IERC20(usdcAddress).approve(_deiProxy, type(uint256).max);
		IERC20(deiAddress).approve(_uniswapRouter, type(uint256).max);
	}

	/* ========== RESTRICTED FUNCTIONS ========== */

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

	function USDC2DEUS(IDEIProxy.ProxyInput memory proxyInput) external returns (uint deusAmount) {
        IERC20(usdcAddress).transferFrom(msg.sender, address(this), proxyInput.amountIn);

		uint deiAmount = IDEIProxy(deiProxy).USDC2DEI(proxyInput);
        
        deusAmount = IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(deiAmount, 1, dei2deusPath, msg.sender, deadline)[1];

        require(proxyInput.minAmountOut <= deusAmount, "Multi Swap: Insufficient output amount");

        emit Buy(usdcAddress, proxyInput.amountIn, deusAmount);
	}


	function ERC202DEUS(IDEIProxy.ProxyInput memory proxyInput, address[] memory path) external returns (uint deusAmount) {
		IERC20(path[0]).transferFrom(msg.sender, address(this), proxyInput.amountIn);

		// approve if it doesn't have allowance
		if (IERC20(path[0]).allowance(address(this), deiProxy) == 0) {IERC20(path[0]).approve(deiProxy, type(uint).max);}
        
        uint deiAmount = IDEIProxy(deiProxy).ERC202DEI(proxyInput, path);
        
        deusAmount = IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(deiAmount, 1, dei2deusPath, msg.sender, deadline)[1];

        require(proxyInput.minAmountOut <= deusAmount, "Multi Swap: Insufficient output amount");

        emit Buy(path[0], proxyInput.amountIn, deusAmount);
	}

	function Nativecoin2DEUS(IDEIProxy.ProxyInput memory proxyInput, address[] memory path) payable external returns (uint deusAmount) {
		uint deiAmount = IDEIProxy(deiProxy).Nativecoin2DEI{value: msg.value}(proxyInput, path);
        
        deusAmount = IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(deiAmount, 1, dei2deusPath, msg.sender, deadline)[1];

        require(proxyInput.minAmountOut <= deusAmount, "Multi Swap: Insufficient output amount");

        emit Buy(path[0], proxyInput.amountIn, deusAmount);
	}

	/* ========== VIEWS ========== */

	function getUSDC2DEUSInputs(uint amountIn, uint deusPriceUSD, uint colPriceUSD) public view returns (uint amountOut, uint usdcForMintAmount, uint deusNeededAmount) {
		(amountOut, usdcForMintAmount, deusNeededAmount) = IDEIProxy(deiProxy).getUSDC2DEIInputs(amountIn, deusPriceUSD, colPriceUSD);
        amountOut = IUniswapV2Router02(uniswapRouter).getAmountsOut(amountOut, dei2deusPath)[1];
	}

	function getERC202DEUSInputs(uint amountIn, uint deusPriceUSD, uint colPriceUSD, address[] memory path) public view returns (uint amountOut, uint usdcForMintAmount, uint deusNeededAmount) {
		(amountOut, usdcForMintAmount, deusNeededAmount) = IDEIProxy(deiProxy).getERC202DEIInputs(amountIn, deusPriceUSD, colPriceUSD, path);
        amountOut = IUniswapV2Router02(uniswapRouter).getAmountsOut(amountOut, dei2deusPath)[1];
	}

	/* ========== EVENTS ========== */

	event Buy(address tokenIn, uint amountIn, uint amountOut);
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