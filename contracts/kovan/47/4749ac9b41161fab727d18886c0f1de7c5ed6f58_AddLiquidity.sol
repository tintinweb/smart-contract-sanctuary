// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TH_APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TH_TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TH_TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{ value: value }(new bytes(0));
        require(success, 'TH_ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, 'SM_ADD_OVERFLOW');
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = sub(x, y, 'SM_SUB_UNDERFLOW');
    }

    function sub(
        uint256 x,
        uint256 y,
        string memory message
    ) internal pure returns (uint256 z) {
        require((z = x - y) <= x, message);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'SM_MUL_OVERFLOW');
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SM_DIV_BY_ZERO');
        uint256 c = a / b;
        return c;
    }

    function ceil_div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = div(a, b);
        if (c == mul(a, b)) {
            return c;
        } else {
            return add(c, 1);
        }
    }

    function safe32(uint256 n) internal pure returns (uint32) {
        require(n < 2**32, 'IS_EXCEEDS_32_BITS');
        return uint32(n);
    }

    function add96(uint96 a, uint96 b) internal pure returns (uint96 c) {
        c = a + b;
        require(c >= a, 'SM_ADD_OVERFLOW');
    }

    function sub96(uint96 a, uint96 b) internal pure returns (uint96) {
        require(b <= a, 'SM_SUB_UNDERFLOW');
        return a - b;
    }

    function mul96(uint96 x, uint96 y) internal pure returns (uint96 z) {
        require(y == 0 || (z = x * y) / y == x, 'SM_MUL_OVERFLOW');
    }

    function div96(uint96 a, uint96 b) internal pure returns (uint96) {
        require(b > 0, 'SM_DIV_BY_ZERO');
        uint96 c = a / b;
        return c;
    }

    function add32(uint32 a, uint32 b) internal pure returns (uint32 c) {
        c = a + b;
        require(c >= a, 'SM_ADD_OVERFLOW');
    }

    function sub32(uint32 a, uint32 b) internal pure returns (uint32) {
        require(b <= a, 'SM_SUB_UNDERFLOW');
        return a - b;
    }

    function mul32(uint32 x, uint32 y) internal pure returns (uint32 z) {
        require(y == 0 || (z = x * y) / y == x, 'SM_MUL_OVERFLOW');
    }

    function div32(uint32 a, uint32 b) internal pure returns (uint32) {
        require(b > 0, 'SM_DIV_BY_ZERO');
        uint32 c = a / b;
        return c;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

// a library for performing various math operations

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x > y ? x : y;
    }

    function min32(uint32 x, uint32 y) internal pure returns (uint32 z) {
        z = x < y ? x : y;
    }

    function max32(uint32 x, uint32 y) internal pure returns (uint32 z) {
        z = x > y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import 'SafeMath.sol';

library Normalizer {
    using SafeMath for uint256;

    function normalize(uint256 amount, uint8 decimals) internal pure returns (uint256) {
        if (decimals == 18) {
            return amount;
        } else if (decimals > 18) {
            return amount.div(10**(decimals - 18));
        } else {
            return amount.mul(10**(18 - decimals));
        }
    }

    function denormalize(uint256 amount, uint8 decimals) internal pure returns (uint256) {
        if (decimals == 18) {
            return amount;
        } else if (decimals > 18) {
            return amount.mul(10**(decimals - 18));
        } else {
            return amount.div(10**(18 - decimals));
        }
    }
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

interface ITwapERC20 is IERC20 {
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

    function getFees() external view returns (uint256 fee0, uint256 fee1);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import 'ITwapERC20.sol';
import 'IReserves.sol';

interface ITwapPair is ITwapERC20, IReserves {
    event Mint(address indexed sender, address indexed to);
    event Burn(address indexed sender, address indexed to);
    event Swap(address indexed sender, address indexed to);
    event SetMintFee(uint256 fee);
    event SetBurnFee(uint256 fee);
    event SetSwapFee(uint256 fee);
    event SetOracle(address account);
    event SetTrader(address trader);

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

    function getSpotPrice() external view returns (uint256);

    function setSwapFee(uint256 fee) external;

    function setOracle(address account) external;

    function setTrader(address account) external;

    function collect(address to) external;

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        uint256 priceAccumulator,
        uint32 orderTimestamp
    ) external;

    function sync() external;

    function initialize(
        address _token0,
        address _token1,
        address _oracle,
        address _trader
    ) external;

    function fullSync() external;

    function getSwapAmount0In(
        uint256 amount1Out,
        uint256 priceAccumulator,
        uint32 orderTimestamp
    ) external view returns (uint256 swapAmount0In);

    function getSwapAmount1In(
        uint256 amount0Out,
        uint256 priceAccumulator,
        uint32 orderTimestamp
    ) external view returns (uint256 swapAmount1In);

    function getSwapAmount0Out(
        uint256 amount1In,
        uint256 priceAccumulator,
        uint32 orderTimestamp
    ) external view returns (uint256 swapAmount0Out);

    function getSwapAmount1Out(
        uint256 amount0In,
        uint256 priceAccumulator,
        uint32 orderTimestamp
    ) external view returns (uint256 swapAmount1Out);

    function getDepositAmount0In(
        uint256 amount0,
        uint256 priceAccumulator,
        uint32 timestamp
    ) external view returns (uint256 depositAmount0In);

    function getDepositAmount1In(
        uint256 amount1,
        uint256 priceAccumulator,
        uint32 timestamp
    ) external view returns (uint256 depositAmount1In);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

interface ITwapOracle {
    event OwnerSet(address owner);
    event UniswapPairSet(address uniswapPair);

    function xDecimals() external view returns (uint8);

    function yDecimals() external view returns (uint8);

    function owner() external view returns (address);

    function uniswapPair() external view returns (address);

    function getPriceInfo() external view returns (uint256 priceAccumulator, uint32 priceTimestamp);

    function getSpotPrice() external view returns (uint256);

    function getAveragePrice(uint256 priceAccumulator, uint32 priceTimestamp) external view returns (uint256 price);

    function setOwner(address _owner) external;

    function setUniswapPair(address _uniswapPair) external;

    function tradeX(
        uint256 xAfter,
        uint256 xBefore,
        uint256 yBefore,
        uint256 oldPriceAccumulator,
        uint32 oldPriceTimestamp
    ) external view returns (uint256 amount1Out);

    function tradeY(
        uint256 yAfter,
        uint256 yBefore,
        uint256 xBefore,
        uint256 oldPriceAccumulator,
        uint32 oldPriceTimestamp
    ) external view returns (uint256 amount0Out);
}

// SPDX-License-Identifier: GPL-3.0-or-later
// Deployed with donations via Gitcoin GR9

pragma solidity 0.7.5;

import 'TransferHelper.sol';
import 'SafeMath.sol';
import 'Math.sol';
import 'Normalizer.sol';
import 'ITwapPair.sol';
import 'ITwapOracle.sol';

library AddLiquidity {
    using SafeMath for uint256;

    function _quote(
        uint256 amount0,
        uint256 reserve0,
        uint256 reserve1
    ) private pure returns (uint256 amountB) {
        require(amount0 > 0, 'AL_INSUFFICIENT_AMOUNT');
        require(reserve0 > 0 && reserve1 > 0, 'AL_INSUFFICIENT_LIQUIDITY');
        amountB = amount0.mul(reserve1) / reserve0;
    }

    function addLiquidity(
        address pair,
        uint256 amount0Desired,
        uint256 amount1Desired
    ) external view returns (uint256 amount0, uint256 amount1) {
        if (amount0Desired == 0 || amount1Desired == 0) {
            return (0, 0);
        }
        (uint256 reserve0, uint256 reserve1, ) = ITwapPair(pair).getReserves();
        if (reserve0 == 0 && reserve1 == 0) {
            (amount0, amount1) = (amount0Desired, amount1Desired);
        } else {
            uint256 amount1Optimal = _quote(amount0Desired, reserve0, reserve1);
            if (amount1Optimal <= amount1Desired) {
                (amount0, amount1) = (amount0Desired, amount1Optimal);
            } else {
                uint256 amount0Optimal = _quote(amount1Desired, reserve1, reserve0);
                assert(amount0Optimal <= amount0Desired);
                (amount0, amount1) = (amount0Optimal, amount1Desired);
            }
        }
    }

    function swapDeposit0(
        address pair,
        address token0,
        uint256 amount0,
        uint256 minSwapPrice,
        uint256 priceAccumulator,
        uint32 orderTimestamp
    ) external returns (uint256 amount0Left, uint256 amount1Left) {
        uint256 amount0In = ITwapPair(pair).getDepositAmount0In(amount0, priceAccumulator, orderTimestamp);
        amount1Left = ITwapPair(pair).getSwapAmount1Out(amount0In, priceAccumulator, orderTimestamp);
        if (amount1Left == 0) {
            return (amount0, amount1Left);
        }
        uint256 price = getPrice(amount0In, amount1Left, pair);
        require(minSwapPrice == 0 || price >= minSwapPrice, 'AL_PRICE_TOO_LOW');
        TransferHelper.safeTransfer(token0, pair, amount0In);
        ITwapPair(pair).swap(0, amount1Left, address(this), priceAccumulator, orderTimestamp);
        amount0Left = amount0.sub(amount0In);
    }

    function swapDeposit1(
        address pair,
        address token1,
        uint256 amount1,
        uint256 maxSwapPrice,
        uint256 priceAccumulator,
        uint32 orderTimestamp
    ) external returns (uint256 amount0Left, uint256 amount1Left) {
        uint256 amount1In = ITwapPair(pair).getDepositAmount1In(amount1, priceAccumulator, orderTimestamp);
        amount0Left = ITwapPair(pair).getSwapAmount0Out(amount1In, priceAccumulator, orderTimestamp);
        if (amount0Left == 0) {
            return (amount0Left, amount1);
        }
        uint256 price = getPrice(amount0Left, amount1In, pair);
        require(maxSwapPrice == 0 || price <= maxSwapPrice, 'AL_PRICE_TOO_HIGH');
        TransferHelper.safeTransfer(token1, pair, amount1In);
        ITwapPair(pair).swap(amount0Left, 0, address(this), priceAccumulator, orderTimestamp);
        amount1Left = amount1.sub(amount1In);
    }

    function getPrice(
        uint256 amount0,
        uint256 amount1,
        address pair
    ) internal view returns (uint256) {
        ITwapOracle oracle = ITwapOracle(ITwapPair(pair).oracle());
        uint8 xDecimals = oracle.xDecimals();
        uint8 yDecimals = oracle.yDecimals();
        return Normalizer.normalize(amount1, yDecimals).mul(1e18).div(Normalizer.normalize(amount0, xDecimals));
    }
}

{
  "libraries": {
    "TransferHelper.sol": {},
    "SafeMath.sol": {},
    "Math.sol": {},
    "Normalizer.sol": {},
    "IERC20.sol": {},
    "ITwapERC20.sol": {},
    "IReserves.sol": {},
    "ITwapPair.sol": {},
    "ITwapOracle.sol": {},
    "AddLiquidity.sol": {}
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