// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IAlitaPair {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

interface IAlitaRouter01 {
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
        uint deadline,
        uint startingSwapTime
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        uint startingSwapTime
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

pragma solidity >=0.6.2;

import "./IAlitaRouter01.sol";

interface IAlitaRouter02 is IAlitaRouter01 {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPriceFeed {
    function getPrice() external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IPriceFeed.sol";
import "../interfaces/IAlitaRouter02.sol";

import "../interfaces/IAlitaPair.sol";


contract ALIPriceFeed is IPriceFeed, OwnableUpgradeable {

	struct RoutePath {
		address[] path;
	}

	address public router;
	address public ali;
	address public busd;
	address[] public pairs;

	// The route for swaping a token into BUSD
	mapping(address => RoutePath) private tokenToRoutes;

	mapping(address => bool) public isExistedPair;

	uint constant MANTISSA = 10 ** 18;

	function initialize(address _router, address _pairAliBusd, address _pairAliUsdt, address _pairAliEth, address _pairAliWbnb, address _ali) public initializer {
		__Ownable_init();
		require(owner() != address(0), "ALIPriceFeed: owner must be set");
		router = _router;
		ali = _ali;

		busd = IAlitaPair(_pairAliBusd).token0() != ali ? IAlitaPair(_pairAliBusd).token0() : IAlitaPair(_pairAliBusd).token1();
		address usdt = IAlitaPair(_pairAliUsdt).token0() != ali ? IAlitaPair(_pairAliUsdt).token0() : IAlitaPair(_pairAliUsdt).token1();
		address eth = IAlitaPair(_pairAliEth).token0() != ali ? IAlitaPair(_pairAliEth).token0() : IAlitaPair(_pairAliEth).token1();
		address wbnb = IAlitaPair(_pairAliWbnb).token0() != ali ? IAlitaPair(_pairAliWbnb).token0() : IAlitaPair(_pairAliWbnb).token1();

		addPair(_pairAliBusd);
		addPair(_pairAliUsdt);
		addPair(_pairAliEth);
		addPair(_pairAliWbnb);

		tokenToRoutes[usdt].path = [usdt, busd];
		tokenToRoutes[eth].path =  [eth, wbnb, busd];
		tokenToRoutes[wbnb].path = [wbnb, busd];
	}

	/*
    * @title The price of ALI based on many liquidity pools.
    * @notice the price is mantissa form.
    *   Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is: 5100000000000000000
    *   aliPrice = (aliPrice0 * pairTotalValue0 + aliPrice1 * pairTotalValue1 + ...) / (pairTotalValue0 +  pairTotalValue1 + ...)
    */
	function getPrice() public view override returns (uint) {
		uint length = pairs.length; // save gas
		uint priceMul = 0;
		uint sumTotalValue = 0;
		for (uint i = 0; i < length; i++) {
			(uint aliPrice, uint pairTotalValue) = getPriceInPair(pairs[i]);
			priceMul = priceMul + aliPrice * pairTotalValue;
			sumTotalValue = sumTotalValue + pairTotalValue;
		}
		return priceMul / sumTotalValue;
	}

	/*
    * @title The price of a token based on BUSD.
    * @notice the price is mantissa form.
    *   Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is: 5100000000000000000
    *   aliPrice = otherPrice  * otherReserve  / aliReserve
    *   pairTotalValue = aliPrice * aliReserve + otherPrice * otherReserve
    */
	function getPriceInPair(address _pair) public view returns(uint aliPrice, uint pairTotalValue) {
		IAlitaPair pair = IAlitaPair(_pair);
		(uint256 reserve0, uint112 reserve1, ) = pair.getReserves();
		uint256 aliReserve = pair.token0() == ali? reserve0 : reserve1;
		uint256 otherReserve = pair.token0() == ali? reserve1 : reserve0;
		address otherToken = pair.token0() == ali? pair.token1(): pair.token0();
		uint otherPrice;
		if(otherToken == busd) {
			otherPrice = MANTISSA;
		}
		else {
			address[] memory path = tokenToRoutes[otherToken].path;
			otherPrice = IAlitaRouter02(router).getAmountsOut(MANTISSA, path)[path.length - 1];
		}
		aliPrice = otherPrice * otherReserve / aliReserve;
		pairTotalValue = aliPrice * aliReserve / MANTISSA + otherPrice * otherReserve / MANTISSA;
	}

	function getRoutePath(address _token) public view returns(address[] memory path) {
		return tokenToRoutes[_token].path;
	}

	function getPairLength() public view returns(uint) {
		return pairs.length;
	}

	function addPair(address _pair) public onlyOwner {
		require(_pair != address(0), "AliPriceFeed: _pair must not be zero address");
		IAlitaPair pair = IAlitaPair(_pair);
		require(pair.token0() == ali || pair.token1() == ali, "AliPriceFeed: _pair must be paired with ALI");
		require(isExistedPair[_pair] == false, "AliPriceFeed: _pair is existed");
		pairs.push(_pair);
		isExistedPair[_pair] = true;
	}

	function removePair(uint _index) external onlyOwner {
		require(_index < pairs.length, "AliPriceFeed: _index is out invalid");
		isExistedPair[pairs[_index]] = false;
		pairs[_index] = pairs[pairs.length - 1];
		pairs.pop();
	}

	function setRoutePath(address _token, address[] memory _path) public onlyOwner {
		tokenToRoutes[_token].path = _path;
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