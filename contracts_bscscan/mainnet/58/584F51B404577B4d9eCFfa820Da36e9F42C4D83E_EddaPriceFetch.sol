// SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.6;
import '@openzeppelin/contracts/access/Ownable.sol';

interface IPancakeSwapRouter {
	function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);
	function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

}

contract EddaPriceFetch is Ownable {
	address public pancakeswapRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
	address public WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

	function changeRouter(address _newRouter) external onlyOwner() {
		pancakeswapRouter = _newRouter;
	}

	/**
	 * @dev get path for exchange ETH->BNB->USDT via Pancake
	 */
	function getPathFromTokenToToken(address fromToken, address toToken) private view returns (address[] memory) {
		if (fromToken == WBNB || toToken == WBNB) {
			address[] memory path = new address[](2);
			path[0] = fromToken == WBNB ? WBNB : fromToken;
			path[1] = toToken == WBNB ? WBNB : toToken;
			return path;
		} else {
			address[] memory path = new address[](3);
			path[0] = fromToken;
			path[1] = WBNB;
			path[2] = toToken;
			return path;
		}
	}

	function estimateTokenAmount(
		address _fromToken,
		address _toToken,
		uint256 _amount
	) external view returns (uint256) {
		uint256[] memory amounts;
		uint256 result;

		address[] memory path;
		uint256 amountIn = _amount;
		path = getPathFromTokenToToken(_fromToken, _toToken);
		amounts = IPancakeSwapRouter(pancakeswapRouter).getAmountsOut(amountIn, path);
        if(path.length == 2) {
            result = amounts[1];
        } else { 
            result = amounts[2];
        }
		
		return result;
	}

	function estimateSwapAmount(
		address _fromToken,
		address _toToken,
		uint256 _amountOut
	) external view returns (uint256) {
		uint256[] memory amounts;
		address[] memory path;
		path = getPathFromTokenToToken(_fromToken, _toToken);
		amounts = IPancakeSwapRouter(pancakeswapRouter).getAmountsIn(_amountOut, path);
		return amounts[0];
	}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}