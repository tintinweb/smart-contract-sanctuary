pragma solidity ^0.8.0;
import "./IERC20Metadata.sol";

interface IERC20 is IERC20Metadata {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.8.0;

interface IERC20Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

pragma solidity ^0.8.0;

import "./interfaces/IFutureExchangeRouter.sol";
import "./interfaces/IWETH.sol";
import "../future-token/interfaces/IFutureTokenFactory.sol";
import "../future-token/interfaces/IFutureToken.sol";
import "../common/interfaces/IERC20.sol";
import "./libraries/PrecogV2Library.sol";
import "./libraries/SafeMath.sol";

contract FutureExchangeRouter is IFutureExchangeRouter {
    using SafeMath for uint256;

    address public override futureTokenFactory;
    address public weth;
    
    mapping(address => address[]) listFutureTokensInPair;

    constructor(address _futureTokenFactory, address _weth) {
        futureTokenFactory = _futureTokenFactory;
        weth = _weth;
    }

    receive() external payable {
        assert(msg.sender == weth); // only accept ETH via fallback from the WETH contract
    }
    
    function getListFutureTokensInPair(address token) external view override returns(address[] memory) {
        return listFutureTokensInPair[token];
    }

    function isFutureToken(
        address tokenA,
        address tokenB,
        uint256 expiryDate
    ) internal view returns (address) {
        address futureToken = IFutureTokenFactory(futureTokenFactory).getFutureToken(tokenA, tokenB, expiryDate);
        require(futureToken != address(0), "Future Exchange Router: FUTURE_TOKEN_DOES_NOT_EXISTS");
        return futureToken;
    }

    function addLiquidityFuture(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 expiryDate
    ) override external {
        address futureToken = IFutureTokenFactory(futureTokenFactory).getFutureToken(tokenA, tokenB, expiryDate);
        if (futureToken == address(0)) {
            futureToken = IFutureTokenFactory(futureTokenFactory).createFutureToken(tokenA, tokenB, expiryDate);
            listFutureTokensInPair[tokenA].push(futureToken);
            listFutureTokensInPair[tokenB].push(futureToken);
        }
        
        uint256 reserveA = IERC20(tokenA).balanceOf(futureToken);
        uint256 reserveB = IERC20(tokenB).balanceOf(futureToken);
        if (reserveA != 0 && reserveB != 0) {
            require(
                reserveB != PrecogV2Library.quote(amountA, reserveA, reserveB), 
                "Future Exchange Router: LIQUIDITY_AMOUNT_INVALID"
            );   
        }
        
        IERC20(tokenA).transferFrom(msg.sender, futureToken, amountA);
        IERC20(tokenB).transferFrom(msg.sender, futureToken, amountB);
    }

    function swapFuture(
        address tokenIn,
        address tokenOut,
        uint256 expiryDate,
        address to,
        uint256 amount
    ) external override {
        address futureToken = isFutureToken(tokenIn, tokenOut, expiryDate);

        uint256 amountMint = getAmountsOutFuture(amount, tokenIn, tokenOut, expiryDate);
        IFutureTokenFactory(futureTokenFactory).mintFuture(futureToken, to, amountMint);

        IERC20(tokenIn).transferFrom(msg.sender, futureToken, amount);
        IFutureTokenFactory(futureTokenFactory).transferFromFuture(tokenOut, futureToken, address(this), amountMint);
    }
    
    function closeFuture(
        address tokenIn,
        address tokenOut,
        uint256 expiryDate,
        address to,
        uint256 amount
    ) external override {
        address futureToken = isFutureToken(tokenIn, tokenOut, expiryDate);
        IERC20(futureToken).transferFrom(msg.sender, futureTokenFactory, amount);
        IFutureTokenFactory(futureTokenFactory).burnFuture(futureToken, amount);
        IERC20(tokenOut).transfer(to, amount);
    }

    // **** LIBRARY FUNCTIONS ****
    function getAmountsOutFuture(
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        uint256 deadline
    ) public view override returns (uint256) {
        return PrecogV2Library.getAmountsOutFuture(futureTokenFactory, amountIn, tokenIn, tokenOut, deadline);
    }

    function getAmountsInFuture(
        uint256 amountOut,
        address tokenIn,
        address tokenOut,
        uint256 deadline
    ) public view override returns (uint256) {
        return PrecogV2Library.getAmountsInFuture(futureTokenFactory, amountOut, tokenIn, tokenOut, deadline);
    }
}

pragma solidity ^0.8.0;

interface IFutureExchangeRouter {
    
    function futureTokenFactory() external view returns (address);
    
    function getListFutureTokensInPair(address token) external view returns(address[] memory);
    
    function getAmountsOutFuture(uint256 amountIn, address tokenIn, address tokenOut, uint256 deadline) external view returns (uint256);
    
    function getAmountsInFuture(uint256 amountOut, address tokenIn, address tokenOut, uint256 deadline) external view returns (uint256);
    
    function addLiquidityFuture(address tokenA, address tokenB, uint256 amountA, uint256 amountB, uint256 deadline) external;
    
    function swapFuture(address tokenA, address tokenB, uint deadline, address to, uint amount) external;
    
    function closeFuture(address tokenA, address tokenB, uint deadline, address to, uint amount) external;
}

pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

pragma solidity ^0.8.0;

import "../../future-token/interfaces/IFutureTokenFactory.sol";
import "../../future-token/interfaces/IFutureToken.sol";

import "./SafeMath.sol";

library PrecogV2Library {
    using SafeMath for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "PrecogV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "PrecogV2Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            bytes20(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"8bbe3b87a8ff316d03607692c9e315540483dd03b2a3eff7147a4e04f4503f25" // init code hash
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReservesFuture(
        address factory,
        address tokenA,
        address tokenB,
        uint256 deadline
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        address futureToken =
            IFutureTokenFactory(factory).getFutureToken(
                tokenA,
                tokenB,
                deadline
            );
        (uint256 reserve0, uint256 reserve1) =
            IFutureToken(futureToken).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "PrecogV2Library: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "PrecogV2Library: INSUFFICIENT_LIQUIDITY"
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "PrecogV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "PrecogV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "PrecogV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "PrecogV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOutFuture(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "PrecogV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "PrecogV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = amountIn.mul(reserveOut);
        uint256 denominator = reserveIn.add(amountIn);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountInFuture(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "PrecogV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "PrecogV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn.mul(amountOut);
        uint256 denominator = reserveOut.sub(amountOut);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOutFuture(
        address factory,
        uint256 amountIn,
        address tokenIn,
        address tokenOut,
        uint256 deadline
    ) internal view returns (uint256 amountOut) {
        (uint256 reserveIn, uint256 reserveOut) =
            getReservesFuture(factory, tokenIn, tokenOut, deadline);
        amountOut = getAmountOutFuture(amountIn, reserveIn, reserveOut);
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsInFuture(
        address factory,
        uint256 amountOut,
        address tokenIn,
        address tokenOut,
        uint256 deadline
    ) internal view returns (uint256 amountIn) {
        (uint256 reserveIn, uint256 reserveOut) =
            getReservesFuture(factory, tokenIn, tokenOut, deadline);
        amountIn = getAmountInFuture(amountOut, reserveIn, reserveOut);
    }
}

pragma solidity ^0.8.0;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

pragma solidity ^0.8.0;

interface IFutureToken {
    function token0() external view returns (address);
    
    function token1() external view returns (address);
    
    function expiryDate() external view returns (uint256);
    
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;

    function getReserves() external view returns (uint256 reserve0, uint256 reserve1);
}

pragma solidity ^0.8.0;

interface IFutureTokenFactory {
    function exchange() external view returns (address);
    
    event futureTokenCreated(
        address indexed token0,
        address indexed token1,
        address futureTokenAddress,
        uint256 i
    );

    function getFutureToken(address tokenA, address tokenB, uint256 deadline) external view returns (address);

    function allFutureTokens(uint256 index) external view returns (address);

    function createFutureToken(address tokenA, address tokenB, uint256 deadline) external returns (address);

    function mintFuture(address futureToken, address to, uint256 amount) external;

    function burnFuture(address futureToken, uint256 amount) external;

    function transferFromFuture(address token, address from, address to, uint256 amount) external;
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}