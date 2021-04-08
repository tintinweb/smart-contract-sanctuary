// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;

import "../helpers/SafeMath.sol";
import "../helpers/IUniswapV2PairFull.sol";
import "../interfaces/IOracleEth.sol";
import "../interfaces/IOracleUsd.sol";
import "../interfaces/IOracleRegistry.sol";


/**
 * @title OraclePoolToken
 * @dev Calculates the USD price of Uniswap LP tokens
 **/
contract OraclePoolToken is IOracleUsd {
    using SafeMath for uint;

    IOracleRegistry public immutable oracleRegistry;

    address public immutable WETH;

    uint public immutable Q112 = 2 ** 112;

    constructor(address _oracleRegistry) public {
        oracleRegistry = IOracleRegistry(_oracleRegistry);
        WETH = IOracleRegistry(_oracleRegistry).WETH();
    }

    /**
     * @notice Flashloan-resistant logic to determine USD price of Uniswap LP tokens
     * @notice Pair must be registered at Chainlink
     * @param asset The LP token address
     * @param amount Amount of asset
     * @return Q112 encoded price of asset in USD
     **/
    function assetToUsd(
        address asset,
        uint amount
    )
        public
        override
        view
        returns (uint)
    {
        IUniswapV2PairFull pair = IUniswapV2PairFull(asset);
        address underlyingAsset;
        if (pair.token0() == WETH) {
            underlyingAsset = pair.token1();
        } else if (pair.token1() == WETH) {
            underlyingAsset = pair.token0();
        } else {
            revert("Unit Protocol: NOT_REGISTERED_PAIR");
        }

        address oracle = oracleRegistry.oracleByAsset(underlyingAsset);
        require(oracle != address(0), "Unit Protocol: ORACLE_NOT_FOUND");

        uint usdValue_q112 = IOracleUsd(oracle).assetToUsd(underlyingAsset, 1);
        // average price of 1 token unit in ETH
        uint eAvg = IOracleEth(oracleRegistry.oracleByAsset(WETH)).usdToEth(usdValue_q112);


        (uint112 _reserve0, uint112 _reserve1,) = pair.getReserves();
        uint aPool; // current asset pool
        uint ePool; // current WETH pool
        if (pair.token0() == underlyingAsset) {
            aPool = uint(_reserve0);
            ePool = uint(_reserve1);
        } else {
            aPool = uint(_reserve1);
            ePool = uint(_reserve0);
        }

        uint eCurr = ePool.mul(Q112).div(aPool); // current price of 1 token in WETH
        uint ePoolCalc; // calculated WETH pool

        if (eCurr < eAvg) {
            // flashloan buying WETH
            uint sqrtd = ePool.mul((ePool).mul(9).add(
                aPool.mul(3988000).mul(eAvg).div(Q112)
            ));
            uint eChange = sqrt(sqrtd).sub(ePool.mul(1997)).div(2000);
            ePoolCalc = ePool.add(eChange);
        } else {
            // flashloan selling WETH
            uint a = aPool.mul(eAvg);
            uint b = a.mul(9).div(Q112);
            uint c = ePool.mul(3988000);
            uint sqRoot = sqrt(a.div(Q112).mul(b.add(c)));
            uint d = a.mul(3).div(Q112);
            uint eChange = ePool.sub(d.add(sqRoot).div(2000));
            ePoolCalc = ePool.sub(eChange);
        }

        uint num = ePoolCalc.mul(2).mul(amount);
        uint priceInEth;
        if (num > Q112) {
            priceInEth = num.div(pair.totalSupply()).mul(Q112);
        } else {
            priceInEth = num.mul(Q112).div(pair.totalSupply());
        }

        return IOracleEth(oracleRegistry.oracleByAsset(WETH)).ethToUsd(priceInEth);
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

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

// SPDX-License-Identifier: bsl-1.1

/*
  Copyright 2020 Unit Protocol: Artem Zakharov ([email protected]).
*/
pragma solidity 0.7.6;

interface IUniswapV2PairFull {
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

interface IOracleEth {

    // returns Q112-encoded value
    // returned value 10**18 * 2**112 is 1 Ether
    function assetToEth(address asset, uint amount) external view returns (uint);

    // returns the value "as is"
    function ethToUsd(uint amount) external view returns (uint);

    // returns the value "as is"
    function usdToEth(uint amount) external view returns (uint);
}

interface IOracleUsd {

    // returns Q112-encoded value
    // returned value 10**18 * 2**112 is $1
    function assetToUsd(address asset, uint amount) external view returns (uint);
}

pragma abicoder v2;


interface IOracleRegistry {

    struct Oracle {
        uint oracleType;
        address oracleAddress;
    }

    function WETH (  ) external view returns ( address );
    function getKeydonixOracleTypes (  ) external view returns ( uint256[] memory );
    function getOracles (  ) external view returns ( Oracle[] memory foundOracles );
    function keydonixOracleTypes ( uint256 ) external view returns ( uint256 );
    function maxOracleType (  ) external view returns ( uint256 );
    function oracleByAsset ( address asset ) external view returns ( address );
    function oracleByType ( uint256 ) external view returns ( address );
    function oracleTypeByAsset ( address ) external view returns ( uint256 );
    function oracleTypeByOracle ( address ) external view returns ( uint256 );
    function setKeydonixOracleTypes ( uint256[] memory _keydonixOracleTypes ) external;
    function setOracle ( uint256 oracleType, address oracle ) external;
    function setOracleTypeForAsset ( address asset, uint256 oracleType ) external;
    function setOracleTypeForAssets ( address[] memory assets, uint256 oracleType ) external;
    function unsetOracle ( uint256 oracleType ) external;
    function unsetOracleForAsset ( address asset ) external;
    function unsetOracleForAssets ( address[] memory assets ) external;
    function vaultParameters (  ) external view returns ( address );
}

{
  "metadata": {
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
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
  }
}