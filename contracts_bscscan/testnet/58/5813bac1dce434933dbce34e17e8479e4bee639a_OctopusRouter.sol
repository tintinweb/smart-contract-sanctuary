// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import '../interfaces/IOctopusFactory.sol';
import '../interfaces/IOctopusRouter.sol';
import '../interfaces/IOctopusPair.sol';
import '../libraries/OctopusLibrary.sol';
import '../libraries/TransferHelper.sol';

contract OctopusRouter is Initializable, OwnableUpgradeable, IOctopusRouter {
	address public addressStore;
	address public override factory;

	modifier ensure(uint deadline) {
		require(deadline >= block.timestamp, 'OctopusRouter: EXPIRED');
		_;
	}

	function initialize(
		address _addressStore,
		address _factory
	) initializer public {
		addressStore = _addressStore;
		factory = _factory;
		__Ownable_init();
	}

	// **** ADD LIQUIDITY ****
	function _addLiquidity(
		address tokenA,
		address tokenB,
		uint amountADesired,
		uint amountBDesired,
		uint amountAMin,
		uint amountBMin
	) internal virtual returns (uint amountA, uint amountB) {
		// create the pair if it doesn't exist yet
		if (IOctopusFactory(factory).getPair(tokenA, tokenB) == address(0)) {
			IOctopusFactory(factory).createPair(tokenA, tokenB);
		}
		(uint reserveA, uint reserveB) = OctopusLibrary.getReserves(factory, tokenA, tokenB);
		if (reserveA == 0 && reserveB == 0) {
			(amountA, amountB) = (amountADesired, amountBDesired);
		} else {
			uint amountBOptimal = OctopusLibrary.quote(amountADesired, reserveA, reserveB);
			if (amountBOptimal <= amountBDesired) {
				require(amountBOptimal >= amountBMin, 'OctopusRouter: INSUFFICIENT_B_AMOUNT');
				(amountA, amountB) = (amountADesired, amountBOptimal);
			} else {
				uint amountAOptimal = OctopusLibrary.quote(amountBDesired, reserveB, reserveA);
				assert(amountAOptimal <= amountADesired);
				require(amountAOptimal >= amountAMin, 'OctopusRouter: INSUFFICIENT_A_AMOUNT');
				(amountA, amountB) = (amountAOptimal, amountBDesired);
			}
		}
	}

	function addLiquidity(
		address tokenA,
		address tokenB,
		uint amountADesired,
		uint amountBDesired,
		uint amountAMin,
		uint amountBMin,
		address to,
		uint deadline
	) external virtual override ensure(deadline) returns (uint amountA, uint amountB, uint liquidity) {
		(amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
		address pair = OctopusLibrary.pairFor(factory, tokenA, tokenB);
		TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
		TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
		liquidity = IOctopusPair(pair).mint(to);
	}

	// **** REMOVE LIQUIDITY ****
	function removeLiquidity(
		address tokenA,
		address tokenB,
		uint liquidity,
		uint amountAMin,
		uint amountBMin,
		address to,
		uint deadline
	) public virtual override ensure(deadline) returns (uint amountA, uint amountB) {
		address pair = OctopusLibrary.pairFor(factory, tokenA, tokenB);
		IOctopusPair(pair).transferFrom(msg.sender, pair, liquidity); // send liquidity to pair
		(uint amount0, uint amount1) = IOctopusPair(pair).burn(to);
		(address token0,) = OctopusLibrary.sortTokens(tokenA, tokenB);
		(amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
		require(amountA >= amountAMin, 'OctopusRouter: INSUFFICIENT_A_AMOUNT');
		require(amountB >= amountBMin, 'OctopusRouter: INSUFFICIENT_B_AMOUNT');
	}

	// **** SWAP ****
	// requires the initial amount to have already been sent to the first pair
	function _swap(uint[] memory amounts, address[] memory path, address _to) internal virtual {
		for (uint i; i < path.length - 1; i++) {
			(address input, address output) = (path[i], path[i + 1]);
			(address token0,) = OctopusLibrary.sortTokens(input, output);
			uint amountOut = amounts[i + 1];
			(uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOut) : (amountOut, uint(0));
			address to = i < path.length - 2 ? OctopusLibrary.pairFor(factory, output, path[i + 2]) : _to;
			IOctopusPair(OctopusLibrary.pairFor(factory, input, output)).swap(
				amount0Out, amount1Out, to, new bytes(0)
			);
		}
	}

	function swapExactTokensForTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external virtual override ensure(deadline) returns (uint[] memory amounts) {
		amounts = OctopusLibrary.getAmountsOut(factory, amountIn, path);
		require(amounts[amounts.length - 1] >= amountOutMin, 'OctopusRouter: INSUFFICIENT_OUTPUT_AMOUNT');
		TransferHelper.safeTransferFrom(
			path[0], msg.sender, OctopusLibrary.pairFor(factory, path[0], path[1]), amounts[0]
		);
		_swap(amounts, path, to);
	}

	function swapTokensForExactTokens(
		uint amountOut,
		uint amountInMax,
		address[] calldata path,
		address to,
		uint deadline
	) external virtual override ensure(deadline) returns (uint[] memory amounts) {
		amounts = OctopusLibrary.getAmountsIn(factory, amountOut, path);
		require(amounts[0] <= amountInMax, 'OctopusRouter: EXCESSIVE_INPUT_AMOUNT');
		TransferHelper.safeTransferFrom(
				path[0], msg.sender, OctopusLibrary.pairFor(factory, path[0], path[1]), amounts[0]
		);
		_swap(amounts, path, to);
	}

	// **** SWAP (supporting fee-on-transfer tokens) ****
	// requires the initial amount to have already been sent to the first pair
	function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual {
		for (uint i; i < path.length - 1; i++) {
			(address input, address output) = (path[i], path[i + 1]);
			(address token0,) = OctopusLibrary.sortTokens(input, output);
			IOctopusPair pair = IOctopusPair(OctopusLibrary.pairFor(factory, input, output));
			uint amountInput;
			uint amountOutput;
			{ // scope to avoid stack too deep errors
				(uint reserve0, uint reserve1,) = pair.getReserves();
				(uint reserveInput, uint reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
				amountInput = IERC20(input).balanceOf(address(pair)) - reserveInput;
				amountOutput = OctopusLibrary.getAmountOut(amountInput, reserveInput, reserveOutput);
			}
			(uint amount0Out, uint amount1Out) = input == token0 ? (uint(0), amountOutput) : (amountOutput, uint(0));
			address to = i < path.length - 2 ? OctopusLibrary.pairFor(factory, output, path[i + 2]) : _to;
			pair.swap(amount0Out, amount1Out, to, new bytes(0));
		}
	}
	function swapExactTokensForTokensSupportingFeeOnTransferTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external virtual override ensure(deadline) {
		TransferHelper.safeTransferFrom(
			path[0], msg.sender, OctopusLibrary.pairFor(factory, path[0], path[1]), amountIn
		);
		uint balanceBefore = IERC20(path[path.length - 1]).balanceOf(to);
		_swapSupportingFeeOnTransferTokens(path, to);
		require(
			IERC20(path[path.length - 1]).balanceOf(to) - balanceBefore >= amountOutMin,
			'OctopusRouter: INSUFFICIENT_OUTPUT_AMOUNT'
		);
	}

	// **** LIBRARY FUNCTIONS ****
	function quote(uint amountA, uint reserveA, uint reserveB) public pure virtual override returns (uint amountB) {
		return OctopusLibrary.quote(amountA, reserveA, reserveB);
	}

	function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut)
		public
		pure
		virtual
		override
		returns (uint amountOut)
	{
		return OctopusLibrary.getAmountOut(amountIn, reserveIn, reserveOut);
	}

	function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut)
		public
		pure
		virtual
		override
		returns (uint amountIn)
	{
		return OctopusLibrary.getAmountIn(amountOut, reserveIn, reserveOut);
	}

	function getAmountsOut(uint amountIn, address[] memory path)
		public
		view
		virtual
		override
		returns (uint[] memory amounts)
	{
		return OctopusLibrary.getAmountsOut(factory, amountIn, path);
	}

	function getAmountsIn(uint amountOut, address[] memory path)
		public
		view
		virtual
		override
		returns (uint[] memory amounts)
	{
		return OctopusLibrary.getAmountsIn(factory, amountOut, path);
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

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOctopusFactory {
	event PairCreated(address indexed token0, address indexed token1, address pair, uint);

	function feeTo() external view returns (address);

	function getPair(address tokenA, address tokenB) external view returns (address pair);
	function allPairs(uint) external view returns (address pair);
	function allPairsLength() external view returns (uint);

	function createPair(address tokenA, address tokenB) external returns (address pair);

	function setFeeTo(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOctopusRouter {
	function factory() external view returns (address);

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
	function removeLiquidity(
		address tokenA,
		address tokenB,
		uint liquidity,
		uint amountAMin,
		uint amountBMin,
		address to,
		uint deadline
	) external returns (uint amountA, uint amountB);

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
	function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
	function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
	function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
	function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
	function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
	
	function swapExactTokensForTokensSupportingFeeOnTransferTokens(
		uint amountIn,
		uint amountOutMin,
		address[] calldata path,
		address to,
		uint deadline
	) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IOctopusPair is IERC20 {
	function getReserves() external view returns (uint reserve0, uint reserve1, uint32 blockTimestampLast);

	function mint(address to) external returns (uint liquidity);
	function burn(address to) external returns (uint amount0, uint amount1);
	function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
	function skim(address to) external;
	function sync() external;

	function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../interfaces/IOctopusPair.sol';

library OctopusLibrary {

	// returns sorted token addresses, used to handle return values from pairs sorted in this order
	function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
		require(tokenA != tokenB, 'OctopusLibrary: IDENTICAL_ADDRESSES');
		(token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
		require(token0 != address(0), 'OctopusLibrary: ZERO_ADDRESS');
	}

	// calculates the CREATE2 address for a pair without making any external calls
	function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
		(address token0, address token1) = sortTokens(tokenA, tokenB);
		pair = address(uint160(uint(keccak256(abi.encodePacked(
			hex'ff',
			factory,
			keccak256(abi.encodePacked(token0, token1)),
			hex'd0d4c4cd0848c93cb4fd1f498d7013ee6bfb25783ea21593d5834f5d250ece66' // init code hash
		)))));
	}

	// fetches and sorts the reserves for a pair
	function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
		(address token0,) = sortTokens(tokenA, tokenB);
		pairFor(factory, tokenA, tokenB);
		(uint reserve0, uint reserve1,) = IOctopusPair(pairFor(factory, tokenA, tokenB)).getReserves();
		(reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
	}

	// given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
	function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
		require(amountA > 0, 'OctopusLibrary: INSUFFICIENT_AMOUNT');
		require(reserveA > 0 && reserveB > 0, 'OctopusLibrary: INSUFFICIENT_LIQUIDITY');
		amountB = amountA * reserveB / reserveA;
	}

	// given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
	function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
		require(amountIn > 0, 'OctopusLibrary: INSUFFICIENT_INPUT_AMOUNT');
		require(reserveIn > 0 && reserveOut > 0, 'OctopusLibrary: INSUFFICIENT_LIQUIDITY');
		uint amountInWithFee = amountIn * 998;
		uint numerator = amountInWithFee * reserveOut;
		uint denominator = reserveIn * 1000 + amountInWithFee;
		amountOut = numerator / denominator;
	}

	// given an output amount of an asset and pair reserves, returns a required input amount of the other asset
	function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
		require(amountOut > 0, 'OctopusLibrary: INSUFFICIENT_OUTPUT_AMOUNT');
		require(reserveIn > 0 && reserveOut > 0, 'OctopusLibrary: INSUFFICIENT_LIQUIDITY');
		uint numerator = reserveIn * amountOut * 1000;
		uint denominator = (reserveOut - amountOut) * 998;
		amountIn = numerator / denominator + 1;
	}

	// performs chained getAmountOut calculations on any number of pairs
	function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
		require(path.length >= 2, 'OctopusLibrary: INVALID_PATH');
		amounts = new uint[](path.length);
		amounts[0] = amountIn;
		for (uint i; i < path.length - 1; i++) {
			(uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
			amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
		}
	}

	// performs chained getAmountIn calculations on any number of pairs
	function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
		require(path.length >= 2, 'OctopusLibrary: INVALID_PATH');
		amounts = new uint[](path.length);
		amounts[amounts.length - 1] = amountOut;
		for (uint i = path.length - 1; i > 0; i--) {
			(uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
			amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
		}
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
	function safeApprove(address token, address to, uint value) internal {
		// bytes4(keccak256(bytes('approve(address,uint256)')));
		(bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
		require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
	}

	function safeTransfer(address token, address to, uint value) internal {
		// bytes4(keccak256(bytes('transfer(address,uint256)')));
		(bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
		require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
	}

	function safeTransferFrom(address token, address from, address to, uint value) internal {
		// bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
		(bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
		require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
	}

	function safeTransferETH(address to, uint value) internal {
		(bool success,) = to.call{value:value}(new bytes(0));
		require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

