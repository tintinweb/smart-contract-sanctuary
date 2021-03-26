// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

interface IIntegralReader {
    struct Parameters {
        int256[] bidExponents;
        int256[] bidQs;
        int256[] askExponents;
        int256[] askQs;
    }

    function getPairParameters(address pair)
        external
        view
        returns (
            bool exists,
            uint112 reserve0,
            uint112 reserve1,
            uint112 reference0,
            uint112 reference1,
            uint256 mintFee,
            uint256 burnFee,
            uint256 swapFee,
            uint32 pairEpoch,
            uint32 oracleEpoch,
            int256 price,
            Parameters memory parameters
        );
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import 'IERC20.sol';

interface IIntegralERC20 is IERC20 {
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

interface IReserves {
    event Sync(uint112 reserve0, uint112 reserve1);
    event Fees(uint256 fee0, uint256 fee1);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 lastTimestamp
        );

    function getReferences()
        external
        view
        returns (
            uint112 reference0,
            uint112 reference1,
            uint32 epoch
        );

    function getFees() external view returns (uint256 fee0, uint256 fee1);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import 'IIntegralERC20.sol';
import 'IReserves.sol';

interface IIntegralPair is IIntegralERC20, IReserves {
    event Mint(address indexed sender, address indexed to);
    event Burn(address indexed sender, address indexed to);
    event Swap(address indexed sender, address indexed to);
    event SetMintFee(uint256 fee);
    event SetBurnFee(uint256 fee);
    event SetSwapFee(uint256 fee);
    event SetOracle(address account);
    event SetTrader(address trader);
    event SetToken0AbsoluteLimit(uint256 limit);
    event SetToken1AbsoluteLimit(uint256 limit);
    event SetToken0RelativeLimit(uint256 limit);
    event SetToken1RelativeLimit(uint256 limit);
    event SetPriceDeviationLimit(uint256 limit);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function oracle() external view returns (address);

    function trader() external view returns (address);

    function mintFee() external view returns (uint256);

    function setMintFee(uint256 fee) external;

    function mint(address to) external returns (uint256 liquidity);

    function burnFee() external view returns (uint256);

    function setBurnFee(uint256 fee) external;

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swapFee() external view returns (uint256);

    function setSwapFee(uint256 fee) external;

    function setOracle(address account) external;

    function setTrader(address account) external;

    function token0AbsoluteLimit() external view returns (uint256);

    function setToken0AbsoluteLimit(uint256 limit) external;

    function token1AbsoluteLimit() external view returns (uint256);

    function setToken1AbsoluteLimit(uint256 limit) external;

    function token0RelativeLimit() external view returns (uint256);

    function setToken0RelativeLimit(uint256 limit) external;

    function token1RelativeLimit() external view returns (uint256);

    function setToken1RelativeLimit(uint256 limit) external;

    function priceDeviationLimit() external view returns (uint256);

    function setPriceDeviationLimit(uint256 limit) external;

    function collect(address to) external;

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to
    ) external;

    function sync() external;

    function initialize(
        address _token0,
        address _token1,
        address _oracle,
        address _trader
    ) external;

    function syncWithOracle() external;

    function fullSync() external;

    function getSpotPrice() external view returns (uint256 spotPrice);

    function getSwapAmount0In(uint256 amount1Out) external view returns (uint256 swapAmount0In);

    function getSwapAmount1In(uint256 amount0Out) external view returns (uint256 swapAmount1In);

    function getSwapAmount0Out(uint256 amount1In) external view returns (uint256 swapAmount0Out);

    function getSwapAmount1Out(uint256 amount0In) external view returns (uint256 swapAmount1Out);

    function getDepositAmount0In(uint256 amount0) external view returns (uint256 depositAmount0In);

    function getDepositAmount1In(uint256 amount1) external view returns (uint256 depositAmount1In);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

interface IIntegralOracle {
    event OwnerSet(address owner);
    event UniswapPairSet(address uniswapPair);
    event PriceUpdateIntervalSet(uint32 interval);
    event ParametersSet(uint32 epoch, int256[] bidExponents, int256[] bidQs, int256[] askExponents, int256[] askQs);

    function owner() external view returns (address);

    function setOwner(address) external;

    function epoch() external view returns (uint32);

    function xDecimals() external view returns (uint8);

    function yDecimals() external view returns (uint8);

    function getParameters()
        external
        view
        returns (
            int256[] memory bidExponents,
            int256[] memory bidQs,
            int256[] memory askExponents,
            int256[] memory askQs
        );

    function setParameters(
        int256[] calldata bidExponents,
        int256[] calldata bidQs,
        int256[] calldata askExponents,
        int256[] calldata askQs
    ) external;

    function price() external view returns (int256);

    function priceUpdateInterval() external view returns (uint32);

    function updatePrice() external returns (uint32 _epoch);

    function setPriceUpdateInterval(uint32 interval) external;

    function price0CumulativeLast() external view returns (uint256);

    function blockTimestampLast() external view returns (uint32);

    function tradeX(
        uint256 xAfter,
        uint256 xBefore,
        uint256 yBefore
    ) external view returns (uint256 yAfter);

    function tradeY(
        uint256 yAfter,
        uint256 xBefore,
        uint256 yBefore
    ) external view returns (uint256 xAfter);

    function getSpotPrice(uint256 xCurrent, uint256 xBefore) external view returns (uint256 spotPrice);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;
pragma experimental ABIEncoderV2;

import 'IIntegralReader.sol';
import 'IIntegralPair.sol';
import 'IIntegralOracle.sol';

contract IntegralReader is IIntegralReader {
    function isContract(address addressToCheck) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addressToCheck)
        }
        return size > 0;
    }

    function getPairParameters(address pair)
        external
        view
        override
        returns (
            bool exists,
            uint112 reserve0,
            uint112 reserve1,
            uint112 reference0,
            uint112 reference1,
            uint256 mintFee,
            uint256 burnFee,
            uint256 swapFee,
            uint32 pairEpoch,
            uint32 oracleEpoch,
            int256 price,
            Parameters memory parameters
        )
    {
        exists = isContract(pair);
        if (exists) {
            (reserve0, reserve1, ) = IIntegralPair(pair).getReserves();
            (reference0, reference1, pairEpoch) = IIntegralPair(pair).getReferences();
            mintFee = IIntegralPair(pair).mintFee();
            burnFee = IIntegralPair(pair).burnFee();
            swapFee = IIntegralPair(pair).swapFee();
            address oracle = IIntegralPair(pair).oracle();
            oracleEpoch = IIntegralOracle(oracle).epoch();
            if (oracleEpoch != pairEpoch) {
                reference0 = reserve0;
                reference1 = reserve1;
            }
            price = IIntegralOracle(oracle).price();
            {
                (
                    int256[] memory bidExponents,
                    int256[] memory bidQs,
                    int256[] memory askExponents,
                    int256[] memory askQs
                ) = IIntegralOracle(oracle).getParameters();
                parameters = Parameters(bidExponents, bidQs, askExponents, askQs);
            }
        }
    }
}

{
  "libraries": {
    "IIntegralReader.sol": {},
    "IERC20.sol": {},
    "IIntegralERC20.sol": {},
    "IReserves.sol": {},
    "IIntegralPair.sol": {},
    "IIntegralOracle.sol": {},
    "IntegralReader.sol": {}
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