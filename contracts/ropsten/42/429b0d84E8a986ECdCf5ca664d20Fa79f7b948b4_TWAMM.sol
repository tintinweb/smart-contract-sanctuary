// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.9;

import "./interfaces/ITWAMM.sol";
import "./interfaces/IPair.sol";
import "./interfaces/IFactory.sol";
import "./libraries/Library.sol";
import "./libraries/TransferHelper.sol";
import "./interfaces/IWETH.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TWAMM is ITWAMM {
    address public immutable override factory;
    address public immutable override WETH;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "TWAMM: EXPIRED");
        _;
    }

    constructor(address _factory, address _WETH) {
        factory = _factory;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    function addInitialLiquidity(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1,
        uint256 deadline
    ) external virtual override ensure(deadline) {
        // create the pair if it doesn't exist yet
        if (IFactory(factory).getPair(token0, token1) == address(0)) {
            IFactory(factory).createPair(token0, token1);
        }
        address pair = Library.pairFor(factory, token0, token1);
        (address tokenA, ) = Library.sortTokens(token0, token1);
        (uint256 amountA, uint256 amountB) = tokenA == token0
            ? (amount0, amount1)
            : (amount1, amount0);
        IPair(pair).provideInitialLiquidity(msg.sender, amountA, amountB);
    }

    function addInitialLiquidityETH(
        address token,
        uint256 amountToken,
        uint256 amountETH,
        uint256 deadline
    ) external payable virtual override ensure(deadline) {
        if (IFactory(factory).getPair(token, WETH) == address(0)) {
            IFactory(factory).createPair(token, WETH);
        }
        address pair = Library.pairFor(factory, token, WETH);
        (address tokenA, ) = Library.sortTokens(token, WETH);
        (uint256 amountA, uint256 amountB) = tokenA == token
            ? (amountToken, amountETH)
            : (amountETH, amountToken);
        IWETH(WETH).deposit{value: amountETH}();
        IPair(pair).provideInitialLiquidity(msg.sender, amountA, amountB);
        // refund dust eth, if any
        if (msg.value > amountETH)
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    function addLiquidity(
        address token0,
        address token1,
        uint256 lpTokenAmount,
        uint256 deadline
    ) external virtual override ensure(deadline) {
        address pair = Library.pairFor(factory, token0, token1);
        IPair(pair).provideLiquidity(msg.sender, lpTokenAmount);
    }

    function addLiquidityETH(
        address token,
        uint256 lpTokenAmount,
        uint256 deadline
    ) external payable virtual override ensure(deadline) {
        address pair = Library.pairFor(factory, token, WETH);
        (, uint256 reserveETH) = Library.getReserves(factory, token, WETH);
        uint256 totalSupplyLP = IERC20(pair).totalSupply();
        uint256 amountETH = (lpTokenAmount * reserveETH) / totalSupplyLP;
        IWETH(WETH).deposit{value: amountETH}();
        IPair(pair).provideLiquidity(msg.sender, lpTokenAmount);
        // refund dust eth, if any
        if (msg.value > amountETH)
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
    }

    function withdrawLiquidity(
        address token0,
        address token1,
        uint256 lpTokenAmount,
        uint256 deadline
    ) external virtual override ensure(deadline) {
        address pair = Library.pairFor(factory, token0, token1);
        IPair(pair).removeLiquidity(msg.sender, lpTokenAmount);
    }

    function withdrawLiquidityETH(
        address token,
        uint256 lpTokenAmount,
        uint256 deadline
    ) external virtual override ensure(deadline) {
        address pair = Library.pairFor(factory, token, WETH);
        IPair(pair).removeLiquidity(msg.sender, lpTokenAmount);
        (, uint256 reserveETH) = Library.getReserves(factory, token, WETH);
        uint256 totalSupplyLP = IERC20(pair).totalSupply();
        uint256 amountETH = (reserveETH * lpTokenAmount) / totalSupplyLP;
        IWETH(WETH).withdraw(amountETH);
    }

    function instantSwapTokenToToken(
        address token0,
        address token1,
        uint256 amountIn,
        uint256 deadline
    ) external virtual override ensure(deadline) {
        address pair = Library.pairFor(factory, token0, token1);
        (address tokenA, ) = Library.sortTokens(token0, token1);

        if (tokenA == token0) {
            IPair(pair).swapFromAToB(msg.sender, amountIn);
        } else {
            IPair(pair).swapFromBToA(msg.sender, amountIn);
        }
    }

    function instantSwapTokenToETH(
        address token,
        uint256 amountTokenIn,
        uint256 deadline
    ) external virtual override ensure(deadline) {
        address pair = Library.pairFor(factory, token, WETH);
        (address tokenA, ) = Library.sortTokens(token, WETH);

        if (tokenA == token) {
            IPair(pair).swapFromAToB(msg.sender, amountTokenIn);
        } else {
            IPair(pair).swapFromBToA(msg.sender, amountTokenIn);
        }

        (uint256 reserveToken, uint256 reserveETH) = Library.getReserves(
            factory,
            token,
            WETH
        );
        uint256 amountETHOut = (reserveETH * amountTokenIn) /
            (reserveToken + amountTokenIn);
        //charge LP fee
        uint256 amountETHOutMinusFee = (amountETHOut * 997) / 1000;
        IWETH(WETH).withdraw(amountETHOutMinusFee);
    }

    function instantSwapETHToToken(
        address token,
        uint256 amountETHIn,
        uint256 deadline
    ) external payable virtual override ensure(deadline) {
        address pair = Library.pairFor(factory, WETH, token);
        (address tokenA, ) = Library.sortTokens(WETH, token);
        IWETH(WETH).deposit{value: amountETHIn}();

        if (tokenA == WETH) {
            IPair(pair).swapFromAToB(msg.sender, amountETHIn);
        } else {
            IPair(pair).swapFromBToA(msg.sender, amountETHIn);
        }
        // refund dust eth, if any
        if (msg.value > amountETHIn)
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountETHIn);
    }

    function termSwapTokenToToken(
        address token0,
        address token1,
        uint256 amountIn,
        uint256 numberOfBlockIntervals,
        uint256 deadline
    ) external virtual override ensure(deadline) {
        address pair = Library.pairFor(factory, token0, token1);
        (address tokenA, ) = Library.sortTokens(token0, token1);

        if (tokenA == token0) {
            IPair(pair).longTermSwapFromAToB(
                msg.sender,
                amountIn,
                numberOfBlockIntervals
            );
        } else {
            IPair(pair).longTermSwapFromBToA(
                msg.sender,
                amountIn,
                numberOfBlockIntervals
            );
        }
    }

    function termSwapTokenToETH(
        address token,
        uint256 amountTokenIn,
        uint256 numberOfBlockIntervals,
        uint256 deadline
    ) external virtual override ensure(deadline) {
        address pair = Library.pairFor(factory, token, WETH);
        (address tokenA, ) = Library.sortTokens(token, WETH);

        if (tokenA == token) {
            IPair(pair).longTermSwapFromAToB(
                msg.sender,
                amountTokenIn,
                numberOfBlockIntervals
            );
        } else {
            IPair(pair).longTermSwapFromBToA(
                msg.sender,
                amountTokenIn,
                numberOfBlockIntervals
            );
        }
    }

    function termSwapETHToToken(
        address token,
        uint256 amountETHIn,
        uint256 numberOfBlockIntervals,
        uint256 deadline
    ) external payable virtual override ensure(deadline) {
        address pair = Library.pairFor(factory, WETH, token);
        (address tokenA, ) = Library.sortTokens(WETH, token);
        IWETH(WETH).deposit{value: amountETHIn}();

        if (tokenA == WETH) {
            IPair(pair).longTermSwapFromAToB(
                msg.sender,
                amountETHIn,
                numberOfBlockIntervals
            );
        } else {
            IPair(pair).longTermSwapFromBToA(
                msg.sender,
                amountETHIn,
                numberOfBlockIntervals
            );
        }
        // refund dust eth, if any
        if (msg.value > amountETHIn)
            TransferHelper.safeTransferETH(msg.sender, msg.value - amountETHIn);
    }

    function cancelTermSwap(
        address token0,
        address token1,
        uint256 orderId,
        uint256 deadline
    ) external virtual override ensure(deadline) {
        address pair = Library.pairFor(factory, token0, token1);
        IPair(pair).cancelLongTermSwap(msg.sender, orderId);
    }

    function withdrawProceedsFromTermSwap(
        address token0,
        address token1,
        uint256 orderId,
        uint256 deadline
    ) external virtual override ensure(deadline) {
        address pair = Library.pairFor(factory, token0, token1);
        IPair(pair).withdrawProceedsFromLongTermSwap(msg.sender, orderId);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.9;

interface ITWAMM {
    function factory() external view returns (address);

    function WETH() external view returns (address);

    function addInitialLiquidity(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1,
        uint256 deadline
    ) external;

    function addInitialLiquidityETH(
        address token,
        uint256 amountToken,
        uint256 amountETH,
        uint256 deadline
    ) external payable;

    function addLiquidity(
        address token0,
        address token1,
        uint256 lpTokenAmount,
        uint256 deadline
    ) external;

    function addLiquidityETH(
        address token,
        uint256 lpTokenAmount,
        uint256 deadline
    ) external payable;

    function withdrawLiquidity(
        address token0,
        address token1,
        uint256 lpTokenAmount,
        uint256 deadline
    ) external;

    function withdrawLiquidityETH(
        address token,
        uint256 lpTokenAmount,
        uint256 deadline
    ) external;

    function instantSwapTokenToToken(
        address token0,
        address token1,
        uint256 amountIn,
        uint256 deadline
    ) external;

    function instantSwapTokenToETH(
        address token,
        uint256 amountTokenIn,
        uint256 deadline
    ) external;

    function instantSwapETHToToken(
        address token,
        uint256 amountETHIn,
        uint256 deadline
    ) external payable;

    function termSwapTokenToToken(
        address token0,
        address token1,
        uint256 amountIn,
        uint256 numberOfBlockIntervals,
        uint256 deadline
    ) external;

    function termSwapTokenToETH(
        address token,
        uint256 amountTokenIn,
        uint256 numberOfBlockIntervals,
        uint256 deadline
    ) external;

    function termSwapETHToToken(
        address token,
        uint256 amountETHIn,
        uint256 numberOfBlockIntervals,
        uint256 deadline
    ) external payable;

    function cancelTermSwap(
        address token0,
        address token1,
        uint256 orderId,
        uint256 deadline
    ) external;

    function withdrawProceedsFromTermSwap(
        address token0,
        address token1,
        uint256 orderId,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.9;

interface IPair {
    function factory() external view returns (address);

    function tokenA() external view returns (address);

    function tokenB() external view returns (address);

    function LP_FEE() external pure returns (uint256);

    function orderBlockInterval() external pure returns (uint256);

    function reserveMap(address) external view returns (uint256);

    function initialize(address, address) external;

    function tokenAReserves() external view returns (uint256);

    function tokenBReserves() external view returns (uint256);

    event InitialLiquidityProvided(
        address indexed addr,
        uint256 amountA,
        uint256 amountB
    );
    event LiquidityProvided(address indexed addr, uint256 lpTokens);
    event LiquidityRemoved(address indexed addr, uint256 lpTokens);
    event SwapAToB(address indexed addr, uint256 amountAIn, uint256 amountBOut);
    event SwapBToA(address indexed addr, uint256 amountBIn, uint256 amountAOut);
    event LongTermSwapAToB(
        address indexed addr,
        uint256 amountAIn,
        uint256 orderId
    );
    event LongTermSwapBToA(
        address indexed addr,
        uint256 amountBIn,
        uint256 orderId
    );
    event CancelLongTermOrder(address indexed addr, uint256 orderId);
    event WithdrawProceedsFromLongTermOrder(
        address indexed addr,
        uint256 orderId
    );

    function provideInitialLiquidity(
        address to,
        uint256 amountA,
        uint256 amountB
    ) external;

    function provideLiquidity(address to, uint256 lptokenAmount) external;

    function removeLiquidity(address to, uint256 lptokenAmount) external;

    function swapFromAToB(address sender, uint256 amountAIn) external;

    function longTermSwapFromAToB(
        address sender,
        uint256 amountAIn,
        uint256 numberOfBlockIntervals
    ) external;

    function swapFromBToA(address sender, uint256 amountBIn) external;

    function longTermSwapFromBToA(
        address sender,
        uint256 amountBIn,
        uint256 numberOfBlockIntervals
    ) external;

    function cancelLongTermSwap(address sender, uint256 orderId) external;

    function withdrawProceedsFromLongTermSwap(address sender, uint256 orderId)
        external;

    function userIdsCheck(address userAddress)
        external
        view
        returns (uint256[] memory);

    function orderIdStatusCheck(uint256 orderId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.9;

interface IFactory {
    event PairCreated(
        address indexed tokenA,
        address indexed tokenB,
        address pair,
        uint256
    );

    function getPair(address token0, address token1)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address token0, address token1)
        external
        returns (address pair);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.9;

import "../interfaces/IPair.sol";
import "./SafeMath.sol";

library Library {
    using SafeMath for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address token0, address token1)
        internal
        pure
        returns (address tokenA, address tokenB)
    {
        require(token0 != token1, "LIBRARY: IDENTICAL_ADDRESSES");
        (tokenA, tokenB) = token0 < token1
            ? (token0, token1)
            : (token1, token0);
        require(tokenA != address(0), "LIBRARY: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address token0,
        address token1
    ) internal pure returns (address pair) {
        (address tokenA, address tokenB) = sortTokens(token0, token1);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(tokenA, tokenB)),
                            hex"57f900fec4f9ef5dbff745cf1cbc43e5812bb34ebb13d0e8c948c689ba0ba59b" // init code hash
                        )
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address token0,
        address token1
    ) internal view returns (uint256 reserve0, uint256 reserve1) {
        (address tokenA, ) = sortTokens(token0, token1);
        uint256 reserveA = IPair(pairFor(factory, token0, token1))
            .tokenAReserves();
        uint256 reserveB = IPair(pairFor(factory, token0, token1))
            .tokenBReserves();
        (reserve0, reserve1) = token0 == tokenA
            ? (reserveA, reserveB)
            : (reserveB, reserveA);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amount0,
        uint256 reserve0,
        uint256 reserve1
    ) internal pure returns (uint256 amount1) {
        require(amount0 > 0, "LIBRARY: INSUFFICIENT_AMOUNT");
        require(
            reserve0 > 0 && reserve1 > 0,
            "LIBRARY: INSUFFICIENT_LIQUIDITY"
        );
        amount1 = amount0.mul(reserve1) / reserve0;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.9;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(
            success,
            "TransferHelper::safeTransferETH: ETH transfer failed"
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.9;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.9;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "sm-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "sm-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "sm-mul-overflow");
    }
}