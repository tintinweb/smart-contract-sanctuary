// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IWETH.sol';
import '@uniswap/lib/contracts/libraries/TransferHelper.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

import '../../peripheries/interfaces/IFeeApprover.sol';
import '../../peripheries/interfaces/IEonsUniVault.sol';
import '../../peripheries/libraries/Math.sol';
import '../../peripheries/libraries/UniswapV2Library.sol';

contract EonsQuickSwapRouter is OwnableUpgradeable {
	mapping(address => uint256) public hardEons;

	address public _eonsToken;
	address public _eonsWETHPair;
	IFeeApprover public _feeApprover;
	IEonsUniVault public _eonsUniVault;
	IWETH public _WETH;
	address public _uniV2Factory;
	uint private _uniLpIncome;

	event FeeApproverChanged(address indexed newAddress, address indexed oldAddress);

	function initialize(address eonsToken, address WETH, address uniV2Factory, address feeApprover, address eonsUniVault) external initializer {
		_eonsToken = eonsToken;
		_WETH = IWETH(WETH);
		_uniV2Factory = uniV2Factory;
		_feeApprover = IFeeApprover(feeApprover);
		_eonsWETHPair = IUniswapV2Factory(_uniV2Factory).getPair(
				WETH,
				_eonsToken
		);
		_eonsUniVault = IEonsUniVault(eonsUniVault);
		// IUniswapV2Pair(_eonsWETHPair).approve(
		// 		address(_eonsUniVault),
		// 		uint256(-1)
		// );
	}

	function refreshApproval() external {
		IUniswapV2Pair(_eonsWETHPair).approve(
				address(_eonsUniVault),
				type(uint256).max
		);
	}

	fallback() external payable {
		if (msg.sender != address(_WETH)) {
			addLiquidityETHOnly(payable(msg.sender));
		}
	}

	function getLpAmount() external onlyOwner returns(uint amount) {
		_uniLpIncome = IUniswapV2Pair(_eonsWETHPair).balanceOf(address(this));
		return _uniLpIncome;
	}

	function getTotalSupplyOfUniLp() external view returns(uint amount) {
		return IUniswapV2Pair(_eonsWETHPair).totalSupply();
	}

	function getPairReserves()
		public
		view
		returns (uint256 wethReserves, uint256 eonsReserves)
	{
		(address token0, ) = UniswapV2Library.sortTokens(
			address(_WETH),
			_eonsToken
		);
		(uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(_eonsWETHPair)
			.getReserves();
		(wethReserves, eonsReserves) = token0 == _eonsToken
			? (reserve1, reserve0)
			: (reserve0, reserve1);
	}

	function addLiquidity(address payable to, uint256 eonsAmount) external payable {
		(uint256 reserveWeth, uint256 reserveEons) = getPairReserves();
		uint256 outEons = UniswapV2Library.getAmountOut(
			msg.value,
			reserveWeth,
			reserveEons
		);
		require(outEons <= eonsAmount, 'Invalid eons token amount');

		_WETH.deposit{value: msg.value}();

		_WETH.transfer(_eonsWETHPair, msg.value);
		(address token0, address token1) = UniswapV2Library.sortTokens(
			address(_WETH),
			_eonsToken
		);

		IUniswapV2Pair(_eonsWETHPair).swap(
			_eonsToken == token0 ? outEons : 0,
			_eonsToken == token1 ? outEons : 0,
			address(this),
			''
		);
		_addLiquidity(eonsAmount, msg.value, to);

		_feeApprover.sync();
	}

	function addLiquidityETHOnly(address payable to)
		public
		payable
	{
			// Store deposited eth in hardEons
		hardEons[msg.sender] = hardEons[msg.sender] + msg.value;

		uint256 buyAmount = msg.value/2;
		require(buyAmount > 0, 'Insufficient ETH amount');

		_WETH.deposit{value: msg.value}();

		(uint256 reserveWeth, uint256 reserveEons) = getPairReserves();
		uint256 outEons = UniswapV2Library.getAmountOut(
			buyAmount,
			reserveWeth,
			reserveEons
		);

		_WETH.transfer(_eonsWETHPair, buyAmount);

		(address token0, address token1) = UniswapV2Library.sortTokens(
			address(_WETH),
			_eonsToken
		);

		IUniswapV2Pair(_eonsWETHPair).swap(
			_eonsToken == token0 ? outEons : 0,
			_eonsToken == token1 ? outEons : 0,
			address(this),
			''
		);

		_addLiquidity(outEons, buyAmount, to);

		_feeApprover.sync();
	}

	    // **** REMOVE LIQUIDITY ****
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        address to
    ) public virtual returns (uint amountA, uint amountB) {
        IUniswapV2Pair(_eonsWETHPair).transferFrom(msg.sender, _eonsWETHPair, liquidity); // send liquidity to pair
        (uint amount0, uint amount1) = IUniswapV2Pair(_eonsWETHPair).burn(to);
        (address token0,) = UniswapV2Library.sortTokens(tokenA, tokenB);
        (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
    }
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to
    ) external virtual returns (uint amountToken, uint amountETH) {
        (amountToken, amountETH) = removeLiquidity(
            token,
            address(_WETH),
            liquidity,
            address(this)
        );
        TransferHelper.safeTransfer(token, to, amountToken);
        _WETH.withdraw(amountETH);
        TransferHelper.safeTransferETH(to, amountETH);
    }

	function _addLiquidity(
		uint256 eonsAmount,
		uint256 wethAmount,
		address payable to
	) internal {
		(uint256 wethReserve, uint256 eonsReserve) = getPairReserves();

			// Get the amount of ALQO token representing equivalent value to weth amount
		uint256 optimalEonsAmount = UniswapV2Library.quote(
			wethAmount,
			wethReserve,
			eonsReserve
		);

		uint256 optimalWETHAmount;

		if (optimalEonsAmount > eonsAmount) {
			optimalWETHAmount = UniswapV2Library.quote(
				eonsAmount,
				eonsReserve,
				wethReserve
			);
			optimalEonsAmount = eonsAmount;
		} else optimalWETHAmount = wethAmount;

		assert(_WETH.transfer(_eonsWETHPair, optimalWETHAmount));
		assert(
			IERC20(_eonsToken).transfer(_eonsWETHPair, optimalEonsAmount)
		);

		uint lp = IUniswapV2Pair(_eonsWETHPair).mint(address(this));

		_eonsUniVault.depositFor(to, 0, lp);

		//refund dust
		if (eonsAmount > optimalEonsAmount)
			IERC20(_eonsToken).transfer(
				to,
				eonsAmount-optimalEonsAmount
			);

		if (wethAmount > optimalWETHAmount) {
			uint256 withdrawAmount = wethAmount-optimalWETHAmount;
			_WETH.withdraw(withdrawAmount);
			to.transfer(withdrawAmount);
		}
	}

	function changeFeeApprover(address feeApprover) external onlyOwner {
		address oldAddress = address(_feeApprover);
		_feeApprover = IFeeApprover(feeApprover);

		emit FeeApproverChanged(feeApprover, oldAddress);
	}

	function getLPTokenPerEthUnit(uint256 ethAmt)
		external
		view
		returns (uint256 liquidity)
	{
		(uint256 reserveWeth, uint256 reserveEons) = getPairReserves();
		uint256 outEons = UniswapV2Library.getAmountOut(
			ethAmt/2,
			reserveWeth,
			reserveEons
		);
		uint256 _totalSupply = IUniswapV2Pair(_eonsWETHPair).totalSupply();

		(address token0, ) = UniswapV2Library.sortTokens(
			address(_WETH),
			_eonsToken
		);
		(uint256 amount0, uint256 amount1) = token0 == _eonsToken
			? (outEons, ethAmt/2)
			: (ethAmt/2, outEons);
		(uint256 _reserve0, uint256 _reserve1) = token0 == _eonsToken
			? (reserveEons, reserveWeth)
			: (reserveWeth, reserveEons);
				
		liquidity = Math.min(
			amount0*_totalSupply / _reserve0,
			amount1*_totalSupply / _reserve1
		);
	}

	function updatePair() public {
		_eonsWETHPair = IUniswapV2Factory(_uniV2Factory).getPair(address(_WETH), _eonsToken);
	}
}

pragma solidity >=0.5.0;

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

pragma solidity >=0.5.0;

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

pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

pragma solidity >=0.6.0;

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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

interface IFeeApprover {
    function check(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function setPaused(bool _pause) external;

    function setFeeMultiplier(uint256 _feeMultiplier) external;

    function feePercentX100() external view returns (uint256);

    function setTokenUniswapPair(address _tokenUniswapPair) external;

    function setEonsVaultAddress(address _EonsVaultAddress) external;

    function sync() external;

    function calculateAmountsAfterFee(
        address sender,
        address recipient,
        uint256 amount
    )
        external
        returns (uint256 transferToAmount, uint256 transferToFeeBearerAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IEonsUniVault {
  function getUserStakedAmount(uint256 _pid, address _userAddress) external view returns (uint256 stakedAmount);
  function isContract(address addr) external view returns (bool);
  function add(IERC20 token, bool withdrawable, uint pid) external;
  function setPoolWithdrawable(uint256 _pid, bool _withdrawable) external;
  function deposit(uint256 _pid, uint256 _amount) external;
  function depositFor(address _depositFor, uint256 _pid, uint256 _amount) external;
  function setAllowanceForPoolToken(address spender, uint256 _pid, uint256 value) external;
  function withdrawFrom(address owner, uint256 _pid, uint256 _amount) external;
  function withdraw(uint256 _pid, uint256 _amount) external;
  function emergencyWithdraw(uint256 _pid) external;
  function updateEmissionDistribution() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// a library for performing various math operations

library Math {
  function min(uint x, uint y) internal pure returns (uint z) {
    z = x < y ? x : y;
  }

  // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
  function sqrt(uint y) internal pure returns (uint z) {
    if (y > 3) {
      z = y;
      uint x = y / 2 + 1;
      while (x < z) {
        z = x;
        x = (y / x + x) / 2;
      }
    } else if (y != 0) {
      z = 1;
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

library UniswapV2Library {

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint256(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            )))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA*reserveB / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn*997;
        uint numerator = amountInWithFee*reserveOut;
        uint denominator = reserveIn*1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn*amountOut*1000;
        uint denominator = (reserveOut-amountOut)*997;
        amountIn = (numerator / denominator) + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
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
import "../proxy/utils/Initializable.sol";

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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}