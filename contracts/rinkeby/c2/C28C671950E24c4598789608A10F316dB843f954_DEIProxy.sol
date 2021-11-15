// Be name Khoda
// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
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

// Reviewer(s) / Contributor(s)
// ...

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDEIStablecoin {
	function global_collateral_ratio() external view returns (uint);
}

interface IDEIPool {
	function mint1t1DEI(
		uint256 collateral_amount, 
		uint256 collateral_price, 
		uint256 expireBlock, 
		bytes[] calldata sigs
	) external returns (uint);
	function mintAlgorithmicDEI(
		uint256 deus_amount_d18,
		uint256 deus_current_price,
		uint256 expireBlock,
		bytes[] calldata sigs
	) external returns (uint);
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

	function getAmountsOut(
		uint amountIn, 
		address[] memory path
	) external view returns (uint[] memory amounts);
}

contract DEIProxy is Ownable {

	struct ProxyInput {
		uint256 collateral_price;
		uint256 deus_price;
		uint256 expire_block;
		uint min_amount_out;
		bytes[] sigs;
		address[] path;
	}

	/* ========== STATE VARIABLES ========== */

	address public dei_address;
	address public collateral_address;
	address public deus_address;
	address public pool_collateral;
	address public uniswap_router;  // maybe uniswap v2 forks
	uint public collateral_missing_decimals_d18;  // missing decimal of collateral token
	uint public deadline = 0xf000000000000000000000000000000000000000000000000000000000000000;
	address[] public collateral2deus_path;
	address[] public deus2collateral_path;
	uint public while_times = 3;  // set error rate in getCollateralAmountIn2DEUSForMintDEI


	/* ========== CONSTRUCTOR ========== */

	constructor(
		address _dei_address, 
		address _collateral_address, 
		address _deus_address, 
		address _pool_collateral, 
		address _uniswap_router, 
		address[] memory _collateral2deus_path, 
		address[] memory _deus2collateral_path
	) {
		dei_address = _dei_address;
		collateral_address = _collateral_address;
		deus_address = _deus_address;
		pool_collateral = _pool_collateral;
		uniswap_router = _uniswap_router;
		collateral2deus_path = _collateral2deus_path;
		deus2collateral_path = _deus2collateral_path;
		collateral_missing_decimals_d18 = 12;

		IERC20(collateral_address).approve(_uniswap_router, type(uint256).max);
		IERC20(deus_address).approve(_uniswap_router, type(uint256).max);
		IERC20(collateral_address).approve(_pool_collateral, type(uint256).max);
		IERC20(deus_address).approve(_pool_collateral, type(uint256).max);
	}

	/* ========== RESTRICTED FUNCTIONS ========== */

	function setVariables(
		address _dei_address, 
		address _collateral_address, 
		address _deus_address, 
		address _pool_collateral, 
		address _uniswap_router, 
		address[] memory _collateral2deus_path, 
		address[] memory _deus2collateral_path,
		uint _collateral_missing_decimals_d18,
		uint _while_times
	) external onlyOwner {
		dei_address = _dei_address;
		collateral_address = _collateral_address;
		deus_address = _deus_address;
		pool_collateral = _pool_collateral;
		uniswap_router = _uniswap_router;
		collateral2deus_path = _collateral2deus_path;
		deus2collateral_path = _deus2collateral_path;
		collateral_missing_decimals_d18 = _collateral_missing_decimals_d18;
		while_times = _while_times;
	}

	function approve(address token, address to) external onlyOwner {
		IERC20(token).approve(to, type(uint256).max);
	}

	function withdrawERC20(address token, address to, uint amount) external onlyOwner {
		IERC20(token).transfer(to, amount);
	}

	/* ========== PUBLIC FUNCTIONS ========== */

	function Nativecoin2DEI(
		ProxyInput memory proxy_input
	) external payable returns(uint dei_amount) {
		// check min amount out, require(dei_amount > proxy_input.min_amount_out, "DEIProxy::collateral2DEI: INSUFFICIENT_OUTPUT_AMOUNT");
		require(proxy_input.min_amount_out >= getAmountOutNativecoin2DEI(msg.value, proxy_input.deus_price, proxy_input.path));
		require(proxy_input.path[proxy_input.path.length - 1] != collateral_address && proxy_input.path.length >= 2, "PROXY: WRONG_PATH");

		uint[] memory amounts_out = IUniswapV2Router02(uniswap_router).swapExactETHForTokens{value: msg.value}(1, proxy_input.path, address(this), deadline);
		uint collateral_amount = amounts_out[amounts_out.length - 1];

		uint global_collateral_ratio = IDEIStablecoin(dei_address).global_collateral_ratio();
		if(global_collateral_ratio == 1000000) {
			dei_amount = IDEIPool(pool_collateral).mint1t1DEI(collateral_amount, proxy_input.collateral_price, proxy_input.expire_block, proxy_input.sigs);
		} else if(global_collateral_ratio == 0) {
			amounts_out = IUniswapV2Router02(uniswap_router).swapExactTokensForTokens(
																	collateral_amount,
																	1,
																	collateral2deus_path,
																	address(this),
																	deadline
																);
			uint deus_amount = amounts_out[amounts_out.length - 1];
			dei_amount = IDEIPool(pool_collateral).mintAlgorithmicDEI(deus_amount, proxy_input.deus_price, proxy_input.expire_block, proxy_input.sigs);
		} else {
			uint collateral_to_deus = getCollateralAmountIn2DEUSForMintDEI(global_collateral_ratio, collateral_amount, proxy_input.deus_price);

			amounts_out = IUniswapV2Router02(uniswap_router).swapExactTokensForTokens(
																	collateral_to_deus,
																	1,
																	collateral2deus_path,
																	address(this),
																	deadline
																);
			uint deus_amount = amounts_out[amounts_out.length - 1];
			
			dei_amount = IDEIPool(pool_collateral).mintFractionalDEI(
							collateral_amount - collateral_to_deus,
							deus_amount,
							proxy_input.collateral_price,
							proxy_input.deus_price,
							proxy_input.expire_block,
							proxy_input.sigs
						);
		}

		IERC20(dei_address).transfer(msg.sender, dei_amount);
	
		emit Buy(address(0), msg.value, dei_amount, global_collateral_ratio);
	}

	function ERC202DEI(
		ProxyInput memory proxy_input,
		uint erc20amount
	) external returns(uint dei_amount) {
		// check min amount out, require(dei_amount > proxy_input.min_amount_out, "DEIProxy::collateral2DEI: INSUFFICIENT_OUTPUT_AMOUNT");
		require(proxy_input.path[proxy_input.path.length - 1] != collateral_address && proxy_input.path.length >= 2, "PROXY: WRONG_PATH");

		IERC20(proxy_input.path[0]).transferFrom(msg.sender, address(this), erc20amount);

		uint[] memory amounts_out = IUniswapV2Router02(uniswap_router).swapExactTokensForTokens(erc20amount, 1, proxy_input.path, address(this), deadline);
		uint collateral_amount = amounts_out[amounts_out.length - 1];
		
		uint global_collateral_ratio = IDEIStablecoin(dei_address).global_collateral_ratio();
		if(global_collateral_ratio == 1000000) {
			dei_amount = IDEIPool(pool_collateral).mint1t1DEI(collateral_amount, proxy_input.collateral_price, proxy_input.expire_block, proxy_input.sigs);
		} else if(global_collateral_ratio == 0) {
			amounts_out = IUniswapV2Router02(uniswap_router).swapExactTokensForTokens(
																	collateral_amount,
																	1,
																	collateral2deus_path,
																	address(this),
																	deadline
																);
			uint deus_amount = amounts_out[amounts_out.length - 1];
			dei_amount = IDEIPool(pool_collateral).mintAlgorithmicDEI(deus_amount, proxy_input.deus_price, proxy_input.expire_block, proxy_input.sigs);
		} else {
			uint collateral_to_deus = getCollateralAmountIn2DEUSForMintDEI(global_collateral_ratio, collateral_amount, proxy_input.deus_price);

			amounts_out = IUniswapV2Router02(uniswap_router).swapExactTokensForTokens(
																	collateral_to_deus,
																	1,
																	collateral2deus_path,
																	address(this),
																	deadline
																);
			uint deus_amount = amounts_out[amounts_out.length - 1];
			
			dei_amount = IDEIPool(pool_collateral).mintFractionalDEI(
							collateral_amount - collateral_to_deus,
							deus_amount,
							proxy_input.collateral_price,
							proxy_input.deus_price,
							proxy_input.expire_block,
							proxy_input.sigs
						);
		}
		
		IERC20(dei_address).transfer(msg.sender, dei_amount);
	
		emit Buy(proxy_input.path[0], erc20amount, dei_amount, global_collateral_ratio);
	}

	function collateral2DEI(
		ProxyInput memory proxy_input,
		uint collateral_amount
	) external returns (uint dei_amount) {
		// check min amount out
		IERC20(collateral_address).transferFrom(msg.sender, address(this), collateral_amount);
	
		uint global_collateral_ratio = IDEIStablecoin(dei_address).global_collateral_ratio();
		if(global_collateral_ratio == 1000000) {
			dei_amount = IDEIPool(pool_collateral).mint1t1DEI(collateral_amount, proxy_input.collateral_price, proxy_input.expire_block, proxy_input.sigs);
		} else if(global_collateral_ratio == 0) {
			uint[] memory amounts_out = IUniswapV2Router02(uniswap_router).swapExactTokensForTokens(
																	collateral_amount,
																	1,
																	collateral2deus_path,
																	address(this),
																	deadline
																);
			uint deus_amount = amounts_out[amounts_out.length - 1];
			dei_amount = IDEIPool(pool_collateral).mintAlgorithmicDEI(deus_amount, proxy_input.deus_price, proxy_input.expire_block, proxy_input.sigs);
		} else {
			uint collateral_to_deus = getCollateralAmountIn2DEUSForMintDEI(global_collateral_ratio, collateral_amount, proxy_input.deus_price);

			uint[] memory amounts_out = IUniswapV2Router02(uniswap_router).swapExactTokensForTokens(
																	collateral_to_deus,
																	1,
																	collateral2deus_path,
																	address(this),
																	deadline
																);
			uint deus_amount = amounts_out[amounts_out.length - 1];
			
			dei_amount = IDEIPool(pool_collateral).mintFractionalDEI(
							collateral_amount - collateral_to_deus,
							deus_amount,
							proxy_input.collateral_price,
							proxy_input.deus_price,
							proxy_input.expire_block,
							proxy_input.sigs
						);
		}

		IERC20(dei_address).transfer(msg.sender, dei_amount);
	
		emit Buy(collateral_address, collateral_amount, dei_amount, global_collateral_ratio);
	}


	function DEUS2DEI(
		ProxyInput memory proxy_input,
		uint deus_amount
	) external returns (uint dei_amount) {
		// check min amount out
		IERC20(deus_address).transferFrom(msg.sender, address(this), deus_amount);

		uint global_collateral_ratio = IDEIStablecoin(dei_address).global_collateral_ratio();
		if(global_collateral_ratio == 1000000) {
			uint[] memory amounts_out = IUniswapV2Router02(uniswap_router).swapExactTokensForTokens(
																	deus_amount,
																	1,
																	deus2collateral_path,
																	address(this),
																	deadline
																);
			uint collateral_amount = amounts_out[amounts_out.length - 1];
			dei_amount = IDEIPool(pool_collateral).mint1t1DEI(collateral_amount, proxy_input.collateral_price, proxy_input.expire_block, proxy_input.sigs);
		} else if(global_collateral_ratio == 0) {
			dei_amount = IDEIPool(pool_collateral).mintAlgorithmicDEI(deus_amount, proxy_input.deus_price, proxy_input.expire_block, proxy_input.sigs);
		} else {
			uint deus_to_collateral = getDEUSAmountIn2CollateralForMintDEI(global_collateral_ratio, deus_amount, proxy_input.deus_price);

			uint[] memory amounts_out = IUniswapV2Router02(uniswap_router).swapExactTokensForTokens(
																	deus_to_collateral,
																	1,
																	deus2collateral_path,
																	address(this),
																	deadline
																);
			uint collateral_amount = amounts_out[amounts_out.length - 1];
			
			dei_amount = IDEIPool(pool_collateral).mintFractionalDEI(
							collateral_amount,
							deus_amount - deus_to_collateral,
							proxy_input.collateral_price,
							proxy_input.deus_price,
							proxy_input.expire_block,
							proxy_input.sigs
						);
		}

		IERC20(dei_address).transfer(msg.sender, dei_amount);
	
		emit Buy(deus_address, deus_amount, dei_amount, global_collateral_ratio);
	}


	/* ========== VIEWS ========== */

	function getDEUSAmountIn2CollateralForMintDEI(
		uint global_collateral_ratio, 
		uint deus_amount, 
		uint deus_price
	) public view returns(uint) {
		uint deus_to_callateral;
		uint times = while_times;
		while(times > 0) {
			uint deus_for_swap = deus_amount * global_collateral_ratio / 1e6;
			deus_to_callateral += deus_for_swap;
			uint[] memory amounts_out = IUniswapV2Router02(uniswap_router).getAmountsOut(deus_for_swap, deus2collateral_path);
			uint collateral_amount = amounts_out[amounts_out.length - 1];
			uint deus_needed = (collateral_amount * (1e6 - global_collateral_ratio) / deus_price);
			deus_amount = deus_amount - (deus_needed + deus_for_swap);
			times -= 1;
		}
		return deus_to_callateral;
	}

	function getAmountOutDEUS2DEI(
		uint deus_amount, 
		uint deus_price
	) public view returns (uint dei_amount) {
		uint global_collateral_ratio = IDEIStablecoin(dei_address).global_collateral_ratio();
		if(global_collateral_ratio == 1000000) {
			uint[] memory amounts_out = IUniswapV2Router02(uniswap_router).getAmountsOut(
																	deus_amount,
																	deus2collateral_path
																);
			uint collateral_amount = amounts_out[amounts_out.length - 1];
			dei_amount = collateral_amount * collateral_missing_decimals_d18;
		} else if(global_collateral_ratio == 0) {
			dei_amount = deus_amount * deus_price / 1e6;
		} else {
			uint deus_to_collateral = getDEUSAmountIn2CollateralForMintDEI(global_collateral_ratio, deus_amount, deus_price);

			uint[] memory amounts_out = IUniswapV2Router02(uniswap_router).getAmountsOut(
																	deus_to_collateral,
																	collateral2deus_path
																);
			uint collateral_amount = amounts_out[amounts_out.length - 1];
			dei_amount = ((deus_amount - deus_to_collateral) * deus_price / 1e6)  + collateral_amount * collateral_missing_decimals_d18;
		}
		uint minting_fee = IDEIPool(pool_collateral).minting_fee();
		dei_amount = (dei_amount * (uint(1e6) - minting_fee)) / 1e6;

		return dei_amount;
	}

	function getCollateralAmountIn2DEUSForMintDEI(
		uint global_collateral_ratio, 
		uint collateral_amount, 
		uint deus_price
	) public view returns(uint) {
		uint collateral_to_deus;
		uint times = while_times;
		while(times > 0) {
			uint collateral_for_swap = collateral_amount * (1e6 - global_collateral_ratio) / 1e6;
			collateral_to_deus += collateral_for_swap;
			uint[] memory amounts_out = IUniswapV2Router02(uniswap_router).getAmountsOut(collateral_for_swap, collateral2deus_path);
			uint deus_amount = amounts_out[amounts_out.length - 1];
			uint deus_to_collateral = (deus_amount * deus_price) / (1e6 * collateral_missing_decimals_d18);
			uint collateral_needed = global_collateral_ratio * deus_to_collateral / (1e6 - global_collateral_ratio);
			collateral_amount = collateral_amount - (deus_to_collateral + collateral_needed);
			times -= 1;
		}
		return collateral_to_deus;
	}

	function getAmountOutNativecoin2DEI(
		uint native_amount, 
		uint deus_price, 
		address[] memory path
	) public view returns(uint) {
		uint[] memory amounts_out = IUniswapV2Router02(uniswap_router).getAmountsOut(native_amount, path);
		uint collateral_amount = amounts_out[amounts_out.length - 1];
		return getAmountOutCollateral2DEI(collateral_amount, deus_price);
	}

	function getAmountOutERC202DEI(
		uint erc20amount, 
		uint deus_price, 
		address[] memory path
	) public view returns(uint) {
		uint[] memory amounts_out = IUniswapV2Router02(uniswap_router).getAmountsOut(erc20amount, path);
		uint collateral_amount = amounts_out[amounts_out.length - 1];
		return getAmountOutCollateral2DEI(collateral_amount, deus_price);
	}

	function getAmountOutCollateral2DEI(
		uint collateral_amount, 
		uint deus_price
	) public view returns (uint dei_amount) {
		uint global_collateral_ratio = IDEIStablecoin(dei_address).global_collateral_ratio();
		if(global_collateral_ratio == 1000000) {
			dei_amount = collateral_amount * collateral_missing_decimals_d18;
		} else if(global_collateral_ratio == 0) {
			uint[] memory amounts_out = IUniswapV2Router02(uniswap_router).getAmountsOut(
																	collateral_amount,
																	collateral2deus_path
																);
			uint deus_amount = amounts_out[amounts_out.length - 1];
			dei_amount = deus_amount * deus_price / 1e6;
		} else {
			uint collateral_to_deus = getCollateralAmountIn2DEUSForMintDEI(global_collateral_ratio, collateral_amount, deus_price);

			uint[] memory amounts_out = IUniswapV2Router02(uniswap_router).getAmountsOut(
																	collateral_to_deus,
																	collateral2deus_path
																);
			uint deus_amount = amounts_out[amounts_out.length - 1];
			dei_amount = ((collateral_amount - collateral_to_deus) * collateral_missing_decimals_d18) + (deus_amount * deus_price / 1e6);
		}
		uint minting_fee = IDEIPool(pool_collateral).minting_fee();
		dei_amount = (dei_amount * (uint(1e6) - minting_fee)) / 1e6;
	}


	receive() external payable {revert();}

	/* ========== EVENTS ========== */

	event Buy(address tokenIn, uint amountIn, uint amountOut, uint globalCollateralRatio);
	event WhileTimesSet(uint while_times);
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

