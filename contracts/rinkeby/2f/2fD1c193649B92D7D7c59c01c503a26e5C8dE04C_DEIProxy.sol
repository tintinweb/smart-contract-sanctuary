// Be name Khoda
// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;
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
	function swap(uint usdc_amount) external returns (uint amount);
	function getAmountIn(uint dei_amount) external view returns(uint);
}


contract DEIProxy is Ownable {

	struct ProxyInput {
		uint256 collateral_price;
		uint256 deus_price;
		uint256 expire_block;
		uint amount_out;
		uint max_amount_in;
		bytes[] sigs;
		address[] path;
	}

	/* ========== STATE VARIABLES ========== */

	address public dei_address;
	address public collateral_address;
	address public deus_address;
	address public pool_collateral;
	address public uniswap_router;  // maybe uniswap v2 forks
	address public ssp_address;
	address[] public collateral2deus_path;
	address[] public deus2collateral_path;
	address[] public dei2deus_path;
	uint public collateral_missing_decimals_d18;  // missing decimal of collateral token
	uint public deadline = 0xf000000000000000000000000000000000000000000000000000000000000000;

	/* ========== CONSTRUCTOR ========== */

	constructor(
		address _dei_address, 
		address _collateral_address, 
		address _deus_address, 
		address _pool_collateral, 
		address _uniswap_router, 
		address[] memory _collateral2deus_path, 
		address[] memory _deus2collateral_path,
		address[] memory _dei2deus_path
	) {
		dei_address = _dei_address;
		collateral_address = _collateral_address;
		deus_address = _deus_address;
		pool_collateral = _pool_collateral;
		uniswap_router = _uniswap_router;
		collateral2deus_path = _collateral2deus_path;
		deus2collateral_path = _deus2collateral_path;
		dei2deus_path = _dei2deus_path;
		collateral_missing_decimals_d18 = 1e12;

		IERC20(collateral_address).approve(_uniswap_router, type(uint256).max);
		IERC20(deus_address).approve(_uniswap_router, type(uint256).max);
		IERC20(collateral_address).approve(_pool_collateral, type(uint256).max);
		IERC20(deus_address).approve(_pool_collateral, type(uint256).max);
	}

	/* ========== RESTRICTED FUNCTIONS ========== */

	function setSSP(address _ssp_address) external onlyOwner {
		ssp_address = _ssp_address;
		IERC20(collateral_address).approve(ssp_address, type(uint256).max);
	}

	function setVariables(
		address _dei_address, 
		address _collateral_address, 
		address _deus_address, 
		address _pool_collateral, 
		address _uniswap_router, 
		address _ssp_address,
		address[] memory _collateral2deus_path, 
		address[] memory _deus2collateral_path,
		uint _collateral_missing_decimals_d18
	) external onlyOwner {
		dei_address = _dei_address;
		collateral_address = _collateral_address;
		deus_address = _deus_address;
		pool_collateral = _pool_collateral;
		uniswap_router = _uniswap_router;
		ssp_address = _ssp_address;
		collateral2deus_path = _collateral2deus_path;
		deus2collateral_path = _deus2collateral_path;
		collateral_missing_decimals_d18 = _collateral_missing_decimals_d18;
	}

	function approve(address token, address to) external onlyOwner {
		IERC20(token).approve(to, type(uint256).max);
	}

	function withdrawERC20(address token, address to, uint amount) external onlyOwner {
		IERC20(token).transfer(to, amount);
	}

	function withdrawETH(address to, uint amount) external onlyOwner {
		payable(to).transfer(amount);
	}

	/* ========== PUBLIC FUNCTIONS ========== */

	function Nativecoin2DEI(
		ProxyInput memory proxy_input
	) external payable returns(uint dei_amount) {
		require(proxy_input.path.length >= 2 && proxy_input.path[proxy_input.path.length - 1] == collateral_address, "PROXY: WRONG_PATH");
		uint _amount = getAmountInERC20ORNativecoin2DEI(proxy_input.amount_out, proxy_input.deus_price, proxy_input.collateral_price, proxy_input.path);
		require(_amount <= proxy_input.max_amount_in, "PROXY: INSUFFICIENT_INPUT_AMOUNT");
		IUniswapV2Router02(uniswap_router).swapExactETHForTokens{value: _amount}(1, proxy_input.path, address(this), deadline);

		uint global_collateral_ratio = IDEIStablecoin(dei_address).global_collateral_ratio();

		if(global_collateral_ratio == 1000000) {
			dei_amount = IDEIPool(pool_collateral).mint1t1DEI(proxy_input.amount_out, proxy_input.collateral_price, proxy_input.expire_block, proxy_input.sigs);
		} else if(global_collateral_ratio == 0) {
			uint deus_needed_amount = proxy_input.amount_out * 1e6 / proxy_input.deus_price;  // d18
			uint amount_in = IUniswapV2Router02(uniswap_router).getAmountsIn(deus_needed_amount, collateral2deus_path)[0];
			IUniswapV2Router02(uniswap_router).swapExactTokensForTokens(amount_in, 1, collateral2deus_path, address(this), deadline);
			dei_amount = IDEIPool(pool_collateral).mintAlgorithmicDEI(deus_needed_amount, proxy_input.deus_price, proxy_input.expire_block, proxy_input.sigs);
		} else {
			(uint collateral_needed_amount, uint collateral_for_deus_amount, uint deus_amount) = getAmountsForMint(global_collateral_ratio, proxy_input.amount_out, proxy_input.deus_price, proxy_input.collateral_price);
			IUniswapV2Router02(uniswap_router).swapExactTokensForTokens(collateral_for_deus_amount, 1, collateral2deus_path, address(this), deadline);
			
			dei_amount = IDEIPool(pool_collateral).mintFractionalDEI(
							collateral_needed_amount,
							deus_amount,
							proxy_input.collateral_price,
							proxy_input.deus_price,
							proxy_input.expire_block,
							proxy_input.sigs
						);
		}
		IERC20(dei_address).transfer(msg.sender, dei_amount);
		payable(msg.sender).transfer(msg.value - _amount);
	
		emit Buy(address(0), dei_amount, global_collateral_ratio);
	}

	function ERC202DEI(
		ProxyInput memory proxy_input
	) external returns(uint dei_amount) {
		require(proxy_input.path.length >= 2 && proxy_input.path[proxy_input.path.length - 1] == collateral_address, "PROXY: WRONG_PATH");
		if (IERC20(proxy_input.path[0]).allowance(address(this), uniswap_router) == 0) IERC20(proxy_input.path[0]).approve(uniswap_router, type(uint).max);

		uint _amount = getAmountInERC20ORNativecoin2DEI(proxy_input.amount_out, proxy_input.deus_price, proxy_input.collateral_price, proxy_input.path);
		require(_amount <= proxy_input.max_amount_in, "PROXY: INSUFFICIENT_INPUT_AMOUNT");
		IERC20(proxy_input.path[0]).transferFrom(msg.sender, address(this), _amount);
		IUniswapV2Router02(uniswap_router).swapExactTokensForTokens(_amount, 1, proxy_input.path, address(this), deadline);

		uint global_collateral_ratio = IDEIStablecoin(dei_address).global_collateral_ratio();

		if(global_collateral_ratio == 1000000) {
			dei_amount = IDEIPool(pool_collateral).mint1t1DEI(proxy_input.amount_out, proxy_input.collateral_price, proxy_input.expire_block, proxy_input.sigs);
		} else if(global_collateral_ratio == 0) {
			uint deus_needed_amount = proxy_input.amount_out * 1e6 / proxy_input.deus_price;  // d18
			uint amount_in = IUniswapV2Router02(uniswap_router).getAmountsIn(deus_needed_amount, collateral2deus_path)[0];
			// require(amount_in <= proxy_input.max_amount_in, "PROXY: INSUFFICIENT_INPUT_AMOUNT");
			IUniswapV2Router02(uniswap_router).swapExactTokensForTokens(amount_in, 1, collateral2deus_path, address(this), deadline);
			dei_amount = IDEIPool(pool_collateral).mintAlgorithmicDEI(deus_needed_amount, proxy_input.deus_price, proxy_input.expire_block, proxy_input.sigs);
		} else {
			(uint collateral_needed_amount, uint collateral_for_deus_amount, uint deus_amount) = getAmountsForMint(global_collateral_ratio, proxy_input.amount_out, proxy_input.deus_price, proxy_input.collateral_price);
			IUniswapV2Router02(uniswap_router).swapExactTokensForTokens(collateral_for_deus_amount, 1, collateral2deus_path, address(this), deadline);
			
			dei_amount = IDEIPool(pool_collateral).mintFractionalDEI(
							collateral_needed_amount,
							deus_amount,
							proxy_input.collateral_price,
							proxy_input.deus_price,
							proxy_input.expire_block,
							proxy_input.sigs
						);
		}
		IERC20(dei_address).transfer(msg.sender, dei_amount);
	
		emit Buy(proxy_input.path[0], dei_amount, global_collateral_ratio);
	}

	function collateral2DEI(
		ProxyInput memory proxy_input
	) external returns (uint dei_amount) {
		uint _amount = getAmountInCollateral2DEI(proxy_input.amount_out, proxy_input.deus_price, proxy_input.collateral_price);
		require(_amount <= proxy_input.max_amount_in, "PROXY: INSUFFICIENT_INPUT_AMOUNT");

		uint global_collateral_ratio = IDEIStablecoin(dei_address).global_collateral_ratio();

		if(global_collateral_ratio == 1000000) {
			IERC20(collateral_address).transferFrom(msg.sender, address(this), proxy_input.amount_out);
			dei_amount = IDEIPool(pool_collateral).mint1t1DEI(proxy_input.amount_out, proxy_input.collateral_price, proxy_input.expire_block, proxy_input.sigs);
		} else if(global_collateral_ratio == 0) {
			uint deus_needed_amount = proxy_input.amount_out * 1e6 / proxy_input.deus_price;  // d18
			uint amount_in = IUniswapV2Router02(uniswap_router).getAmountsIn(deus_needed_amount, collateral2deus_path)[0];
			IERC20(collateral_address).transferFrom(msg.sender, address(this), amount_in);
			IUniswapV2Router02(uniswap_router).swapExactTokensForTokens(amount_in, 1, collateral2deus_path, address(this), deadline);
			dei_amount = IDEIPool(pool_collateral).mintAlgorithmicDEI(deus_needed_amount, proxy_input.deus_price, proxy_input.expire_block, proxy_input.sigs);
		} else {
			(uint collateral_needed_amount, uint collateral_for_deus_amount, uint deus_amount) = getAmountsForMint(global_collateral_ratio, proxy_input.amount_out, proxy_input.deus_price, proxy_input.collateral_price);
			IERC20(collateral_address).transferFrom(msg.sender, address(this), collateral_needed_amount + collateral_for_deus_amount);

			uint _dei_amount = ISSP(ssp_address).swap(collateral_for_deus_amount);
			IUniswapV2Router02(uniswap_router).swapExactTokensForTokens(_dei_amount, 1, dei2deus_path, address(this), deadline);
			
			dei_amount = IDEIPool(pool_collateral).mintFractionalDEI(
							collateral_needed_amount,
							deus_amount,
							proxy_input.collateral_price,
							proxy_input.deus_price,
							proxy_input.expire_block,
							proxy_input.sigs
						);
		}

		IERC20(dei_address).transfer(msg.sender, dei_amount);
	
		emit Buy(collateral_address, dei_amount, global_collateral_ratio);
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

	function getAmountsForMint(
		uint global_collateral_ratio,
		uint amount_out,
		uint deus_price,
		uint collateral_price
	) public view returns (uint collateral_needed_amount, uint collateral_for_deus_amount, uint deus_amount) {
		uint mint_amount;
		collateral_needed_amount = (amount_out * global_collateral_ratio) / (1e6);
		(mint_amount, deus_amount) = calcMintFractionalDEI(MintFD_Params(deus_price, collateral_price, collateral_needed_amount, global_collateral_ratio));
		require(mint_amount == amount_out, "PROXY: CALCULATION_ERROR");
		uint _dei_amount = IUniswapV2Router02(uniswap_router).getAmountsIn(deus_amount, dei2deus_path)[0];
		collateral_for_deus_amount = ISSP(ssp_address).getAmountIn(_dei_amount);
		collateral_needed_amount /= collateral_missing_decimals_d18;
	}

	function getAmountInCollateral2DEI(
		uint amount_out,
		uint deus_price,
		uint collateral_price
	) public view returns (uint _amount) {
		uint global_collateral_ratio = IDEIStablecoin(dei_address).global_collateral_ratio();
		(uint collateral_needed_amount, uint collateral_for_deus_amount,) = getAmountsForMint(global_collateral_ratio, amount_out, deus_price, collateral_price);
		_amount = collateral_needed_amount + collateral_for_deus_amount;
	}

	function getAmountInERC20ORNativecoin2DEI(
		uint amount_out,
		uint deus_price,
		uint collateral_price,
		address[] memory path
	) public view returns (uint _amount) {
		uint global_collateral_ratio = IDEIStablecoin(dei_address).global_collateral_ratio();
		(uint collateral_needed_amount, uint collateral_for_deus_amount,) = getAmountsForMint(global_collateral_ratio, amount_out, deus_price, collateral_price);
		_amount = IUniswapV2Router02(uniswap_router).getAmountsIn(collateral_needed_amount + collateral_for_deus_amount, path)[0];
	}

	receive() external payable {revert();}

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

