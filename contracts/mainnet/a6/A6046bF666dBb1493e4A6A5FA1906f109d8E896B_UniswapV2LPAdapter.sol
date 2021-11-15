// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import {UniswapV2Library} from "@mochifi/library/contracts/UniswapV2Library.sol";
import "../interfaces/ICSSRAdapter.sol";
import "../interfaces/ICSSRRouter.sol";
import "../interfaces/IUniswapV2CSSR.sol";
contract UniswapV2LPAdapter is ICSSRAdapter {
    using Float for float;

    ICSSRRouter public immutable router;
    IUniswapV2CSSR public immutable cssr;
    address public immutable weth;
    address public immutable factory;
    //using uint256 since we don't need 224 for this
    uint256 public constant Q112 = 2**112;

    constructor(address _weth, address _factory, address _router, address _cssr) {
        weth = _weth;
        router = ICSSRRouter(_router);
        cssr = IUniswapV2CSSR(_cssr);
        factory = _factory;
    }

    function support(address _asset) external view override returns(bool) {
        address underlying = getUnderlyingAsset(IUniswapV2Pair(_asset));
        address calculatedAddress = UniswapV2Library.pairFor(factory, underlying, weth);
        return _asset == calculatedAddress;
    }

    function update(address _asset, bytes memory _proof) external override returns(float memory price) {
        address underlying = getUnderlyingAsset(IUniswapV2Pair(_asset));
        router.update(_asset, _proof);
        return _getPrice(IUniswapV2Pair(_asset), underlying);
    }

    function getUnderlyingAsset(IUniswapV2Pair _pair) public view returns(address underlyingAsset) {
        if (_pair.token0() == weth) {
            underlyingAsset = _pair.token1();
        } else if (_pair.token1() == weth) {
            underlyingAsset = _pair.token0();
        } else {
            revert("!eth paired");
        }
    }

    function getPrice(address _asset) external view override returns(float memory price){
        IUniswapV2Pair pair = IUniswapV2Pair(_asset);
        address underlying = getUnderlyingAsset(pair);
        return _getPrice(pair, underlying);
    }

    function _getPrice(IUniswapV2Pair _pair, address _underlying) internal view returns(float memory price) {
        uint256 eAvg = cssr.getExchangeRatio(_underlying, weth);
        (uint112 _reserve0, uint112 _reserve1,) = _pair.getReserves();
        uint256 aPool; // current asset pool
        uint256 ePool; // current weth pool
        if (_pair.token0() == _underlying) {
            aPool = uint(_reserve0);
            ePool = uint(_reserve1);
        } else {
            aPool = uint(_reserve1);
            ePool = uint(_reserve0);
        }

        uint256 eCurr = ePool * Q112 / aPool; // current price of 1 token in weth
        uint256 ePoolCalc; // calculated weth pool

        if (eCurr < eAvg) {
            // flashloan buying weth
            uint256 sqrtd = ePool * (
                (ePool * 9)
                +(aPool * 3988000 * eAvg / Q112)
            );
            uint256 eChange = (sqrt(sqrtd) - (ePool * 1997)) / 2000;
            ePoolCalc = ePool + eChange;
        } else {
            // flashloan selling weth
            uint256 a = aPool * eAvg;
            uint256 b = a * 9 / Q112;
            uint256 c = ePool * 3988000;
            uint256 sqRoot = sqrt( (a / Q112) * (b + c));
            uint256 d = a * 3 / Q112;
            uint256 eChange = ePool - ((d + sqRoot) / 2000);
            ePoolCalc = ePool - eChange;
        }

        uint256 num = ePoolCalc * 2;
        uint256 priceInEth;
        if (num > Q112) {
            priceInEth = (num / _pair.totalSupply()) * Q112;
        } else {
            priceInEth = num * Q112 / _pair.totalSupply();
        }

        return float({numerator:priceInEth, denominator: Q112}).mul(router.getPrice(weth));
    }

    function getLiquidity(address _asset) external view override returns(uint256) {
        address underlying = getUnderlyingAsset(IUniswapV2Pair(_asset));
        return router.getLiquidity(underlying);
    }

    function sqrt(uint x) internal pure returns (uint y) {
        if (x > 3) {
            uint z = x / 2 + 1;
            y = x;
            while (z < y) {
                y = z;
                z = (x / z + z) / 2;
            }
        } else if (x != 0) {
            y = 1;
        }
    }
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

// SPDX-License-Identifier: MIT
// fetched from https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/libraries/UniswapV2Library.sol
// slightly modified to remove SafeMath and 0.8 compatible
pragma solidity ^0.8.0;

import { IUniswapV2Pair } from '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

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
        pair = address(bytes20(uint160(uint256(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f'
            ))))));
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
        amountB = amountA * reserveB / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn * amountOut * 1000;
        uint denominator = (reserveOut - amountOut) * 997;
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

import "@mochifi/library/contracts/Float.sol";

interface ICSSRAdapter {
    function update(address _asset, bytes memory _data)
        external
        returns (float memory price);

    function support(address _asset) external view returns (bool);

    function getPrice(address _asset)
        external
        view
        returns (float memory price);

    function getLiquidity(address _asset)
        external
        view
        returns (uint256 _liquidity);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@mochifi/library/contracts/Float.sol";

interface ICSSRRouter {
    function update(address _asset, bytes memory _data)
        external
        returns (float memory);

    function getPrice(address _asset) external view returns (float memory);

    function getLiquidity(address _asset) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

struct Window {
    uint128 from;
    uint128 to;
}

struct BlockData {
    uint256 blockTimestamp;
    bytes32 stateRoot;
}

struct ObservedData {
    uint32 reserveTimestamp;
    uint112 reserve0;
    uint112 reserve1;
    uint256 price0Data;
    uint256 price1Data;
}

interface IUniswapV2CSSR {
    function uniswapFactory() external view returns (address);

    function getExchangeRatio(address token, address denominator)
        external
        view
        returns (uint256);

    function getLiquidity(address token, address denominator)
        external
        view
        returns (uint256);

    function saveState(bytes memory blockData)
        external
        returns (
            bytes32 stateRoot,
            uint256 blockNumber,
            uint256 blockTimestamp
        );

    function saveReserve(
        uint256 blockNumber,
        address pair,
        bytes memory accountProof,
        bytes memory reserveProof,
        bytes memory price0Proof,
        bytes memory price1Proof
    ) external returns (ObservedData memory data);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;

struct float {
    uint256 numerator;
    uint256 denominator;
}

library Float {
    function multiply(uint256 a, float memory f) internal pure returns(uint256) {
        require(f.denominator != 0, "div 0");
        return a * f.numerator / f.denominator;
    }

    function inverse(float memory f) internal pure returns(float memory) {
        require(f.numerator != 0 && f.denominator != 0, "div 0");
        return float({
            numerator: f.denominator,
            denominator: f.numerator
        });
    }

    function divide(uint256 a, float memory f) internal pure returns(uint256) {
        require(f.denominator != 0, "div 0");
        return a * f.denominator / f.numerator;
    }

    function add(float memory a, float memory b) internal pure returns(float memory res) {
        require(a.denominator != 0 && b.denominator != 0, "div 0");
        res = float({
            numerator : a.numerator*b.denominator + a.denominator*b.numerator,
            denominator : a.denominator*b.denominator
        });
        if(res.numerator > 2**128 && res.denominator > 2**128){
            res.numerator = res.numerator / 2**64;
            res.denominator = res.denominator / 2**64;
        }
    }
    
    function sub(float memory a, float memory b) internal pure returns(float memory res) {
        require(a.denominator != 0 && b.denominator != 0, "div 0");
        res = float({
            numerator : a.numerator*b.denominator - b.numerator*a.denominator,
            denominator : a.denominator*b.denominator
        });
        if(res.numerator > 2**128 && res.denominator > 2**128){
            res.numerator = res.numerator / 2**64;
            res.denominator = res.denominator / 2**64;
        }
    }

    function mul(float memory a, float memory b) internal pure returns(float memory res) {
        require(a.denominator != 0 && b.denominator != 0, "div 0");
        res = float({
            numerator : a.numerator * b.numerator,
            denominator : a.denominator * b.denominator
        });
        if(res.numerator > 2**128 && res.denominator > 2**128){
            res.numerator = res.numerator / 2**64;
            res.denominator = res.denominator / 2**64;
        }
    }

    function gt(float memory a, float memory b) internal pure returns(bool) {
        require(a.denominator != 0 && b.denominator != 0, "div 0");
        return a.numerator * b.denominator > a.denominator * b.numerator;
    }

    function lt(float memory a, float memory b) internal pure returns(bool) {
        require(a.denominator != 0 && b.denominator != 0, "div 0");
        return a.numerator * b.denominator < a.denominator * b.numerator;
    }

    function gte(float memory a, float memory b) internal pure returns(bool) {
        require(a.denominator != 0 && b.denominator != 0, "div 0");
        return a.numerator * b.denominator >= a.denominator * b.numerator;
    }

    function lte(float memory a, float memory b) internal pure returns(bool) {
        require(a.denominator != 0 && b.denominator != 0, "div 0");
        return a.numerator * b.denominator <= a.denominator * b.numerator;
    }

    function equals(float memory a, float memory b) internal pure returns(bool) {
        require(a.denominator != 0 && b.denominator != 0, "div 0");
        return a.numerator * b.denominator == b.numerator * a.denominator;
    }
}

