// SPDX-License-Identifier: GPL3

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface IStaker {
	struct Epoch {
		uint number;
		uint distribute;
		uint32 length;
		uint32 endTime;
	}
	function stake(uint _amount, address _recipient) external returns (bool);
	function unstake(uint _amount, bool _trigger) external;
	function epoch() external pure returns (Epoch memory);
	function warmupPeriod() external pure returns (uint);
}

contract delta is Ownable {
	event Swap(address indexed account, address indexed fromAsset, address indexed toAsset, uint256 inAmount, uint256 outAmount);
	event Stake(address indexed account, uint256 inAmount);
	event Unstake(address indexed account, uint256 outAmount);

	IUniswapV2Router02 public router;
	IStaker public staker;
	IERC20 public time;
	IERC20 public memo;
	IERC20 public mim;

	constructor() {
		router = IUniswapV2Router02(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
		staker = IStaker(0x4456B87Af11e87E329AB7d7C7A246ed1aC2168B9);
		time = IERC20(0xb54f16fB19478766A268F172C9480f8da1a7c9C3);
		memo = IERC20(0x136Acd46C134E8269052c62A67042D6bDeDde3C9);
		mim = IERC20(0x130966628846BFd36ff31a822705796e8cb8C18D);
	}


	function stake(uint256 amount) private returns (bool) {
		time.approve(address(staker), amount);
		return staker.stake(amount, address(this));
	}

	function unstake(uint256 amount) private {
		memo.approve(address(staker), amount);
		staker.unstake(amount, true);
	}

	function swapAsset(
			IUniswapV2Router02 uniRouter,
			address[] memory swapPath,
			uint256 inAmount,
			uint256 outMinAmount,
			uint deadline
			) private returns (uint256) {
		IERC20 inAsset = IERC20(swapPath[0]);
		inAsset.approve(address(uniRouter), inAmount);
		uint[] memory amounts = uniRouter.swapExactTokensForTokens(inAmount, outMinAmount, swapPath, address(this), deadline);
		return amounts[amounts.length - 1];
	}

	function inCaseFundsGetStuck(IERC20 asset, uint256 amount) public onlyOwner() {
		asset.transfer(msg.sender, amount);
	}

	function zapIn(uint256 inAmount, uint256 outMinAmount, uint deadline, bool ignoreWarmup) public {
		require(ignoreWarmup || warmupPeriod() == 0, "warmup period is set to none zero");
		require(mim.balanceOf(msg.sender) >= inAmount, "not enough mim");
		mim.transferFrom(msg.sender, address(this), inAmount);
		address[] memory path = new address[](2);
		path[0] = address(mim);
		path[1] = address(time);
		uint256 timeAmount = swapAsset(router, path, inAmount, outMinAmount, deadline);
		require(stake(timeAmount), "staking failed");
		memo.transfer(msg.sender, timeAmount);
	}

	function zapOut(uint256 inAmount, uint256 outMinAmount, uint deadline) public {
		require(memo.balanceOf(msg.sender) >= inAmount, "not enough memo");
		memo.transferFrom(msg.sender, address(this), inAmount);
		unstake(inAmount);
		address[] memory path = new address[](2);
		path[0] = address(time);
		path[1] = address(mim);
		uint256 mimAmount = swapAsset(router, path, inAmount, outMinAmount, deadline);
		mim.transfer(msg.sender, mimAmount);
	}

	function dryZapIn(uint256 inAmount) public view returns (uint256) {
		address[] memory path = new address[](2);
		path[0] = address(mim);
		path[1] = address(time);
		uint[] memory amounts = router.getAmountsOut(inAmount, path);
		return amounts[amounts.length - 1];
	}

	function dryZapOut(uint256 inAmount) public view returns (uint256) {
		address[] memory path = new address[](2);
		path[0] = address(time);
		path[1] = address(mim);
		uint[] memory amounts = router.getAmountsOut(inAmount, path);
		return amounts[amounts.length - 1];
	}

	function epoch() public view returns (uint, uint, uint32, uint32) {
		IStaker.Epoch memory _epoch = staker.epoch();
		return (_epoch.number, _epoch.distribute, _epoch.length, _epoch.endTime);
	}

	function nextEpoch() public view returns (uint32) {
		(,,,uint32 endTime) = epoch();
		return endTime;
	}

	function warmupPeriod() public view returns (uint) {
		return staker.warmupPeriod();
	}
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

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

pragma solidity >=0.6.2;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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