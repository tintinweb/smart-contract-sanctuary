// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import '@openzeppelin/contracts/access/Ownable.sol';

interface IUniswapV2Router02 {
	function WETH() external pure returns (address);
	function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
}

contract SOTAExchange is Ownable {
	address public uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
	address public USDT = 0x92699a06889Fb2de94d20449c7D463C8D9b6b16d;
	address public WETH = 0x454336232490b3f87801368Bcb167385abcC2122;

	function changeRouter(address _newRouter) external onlyOwner {
		uniswapRouter = _newRouter;
	}

	function setUSDTAddress(address _USDT) public {
		USDT = _USDT;
	}

	function setWETHAddress(address _WETH) public {
		WETH = _WETH;
	}

	/**
	 * @dev get path for exchange ETH->BNB->USDT via Pancake
	 */
	function getPathFromTokenToUSDT(address token) private view returns (address[] memory) {
		if (token == WETH) {
			address[] memory path = new address[](2);
			path[0] = WETH;
			path[1] = USDT;
			return path;
		} else {
			address[] memory path = new address[](3);
			path[0] = token;
			path[1] = WETH;
			path[2] = USDT;
			return path;
		}
	}

	function getPathFromUsdtToToken(address token) private view returns (address[] memory) {
		if (token == WETH) {
			address[] memory path = new address[](2);
			path[0] = USDT;
			path[1] = WETH;
			return path;
		} else {
			address[] memory path = new address[](3);
			path[0] = USDT;
			path[1] = WETH;
			path[2] = token;
			return path;
		}
	}

	function estimateToUSDT(address _paymentToken, uint256 _paymentAmount) public view returns (uint256) {
		uint256[] memory amounts;
		uint256 result;
		if (_paymentToken != USDT) {
			address[] memory path;
			uint256 amountIn = _paymentAmount;
			if (_paymentToken == address(0)) {
				path = getPathFromTokenToUSDT(WETH);
				amounts = IUniswapV2Router02(uniswapRouter).getAmountsOut(amountIn, path);
				result = amounts[1];
			} else {
				path = getPathFromTokenToUSDT(_paymentToken);
				amounts = IUniswapV2Router02(uniswapRouter).getAmountsOut(amountIn, path);
				result = amounts[2];
			}
		} else {
			result = _paymentAmount;
		}
		return result;
	}

	function estimateFromUSDT(address _paymentToken, uint256 _usdtAmount) public view returns (uint256) {
		uint256[] memory amounts;
		uint256 result;
		if (_paymentToken != USDT) {
			address[] memory path;
			uint256 amountIn = _usdtAmount;
			if (_paymentToken == address(0) || _paymentToken == WETH) {
				path = getPathFromUsdtToToken(WETH);
				amounts = IUniswapV2Router02(uniswapRouter).getAmountsOut(amountIn, path);
				result = amounts[1];
			} else {
				path = getPathFromUsdtToToken(_paymentToken);
				amounts = IUniswapV2Router02(uniswapRouter).getAmountsOut(amountIn, path);
				result = amounts[2];
			}
		} else {
			result = _usdtAmount;
		}
		return result;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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