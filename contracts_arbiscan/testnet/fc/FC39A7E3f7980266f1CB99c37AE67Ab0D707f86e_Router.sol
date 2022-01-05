// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IRouter.sol";
import "./interfaces/IPairFactory.sol";
import "./interfaces/IAmm.sol";
import "./interfaces/IMargin.sol";
import "./interfaces/ILiquidityERC20.sol";
import "./interfaces/IWETH.sol";
import "../libraries/TransferHelper.sol";
import "../libraries/FullMath.sol";

contract Router is IRouter {
    address public immutable override pairFactory;
    address public immutable override pcvTreasury;
    address public immutable override WETH;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "Router: EXPIRED");
        _;
    }

    constructor(
        address pairFactory_,
        address pcvTreasury_,
        address _WETH
    ) {
        pairFactory = pairFactory_;
        pcvTreasury = pcvTreasury_;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == WETH); // only accept ETH via fallback from the WETH contract
    }

    function addLiquidity(
        address baseToken,
        address quoteToken,
        uint256 baseAmount,
        uint256 quoteAmountMin,
        uint256 deadline,
        bool pcv
    ) external override ensure(deadline) returns (uint256 quoteAmount, uint256 liquidity) {
        address amm = IPairFactory(pairFactory).getAmm(baseToken, quoteToken);
        if (amm == address(0)) {
            (amm, ) = IPairFactory(pairFactory).createPair(baseToken, quoteToken);
        }

        TransferHelper.safeTransferFrom(baseToken, msg.sender, amm, baseAmount);
        if (pcv) {
            (, quoteAmount, liquidity) = IAmm(amm).mint(address(this));
            TransferHelper.safeTransfer(amm, pcvTreasury, liquidity);
        } else {
            (, quoteAmount, liquidity) = IAmm(amm).mint(msg.sender);
        }
        require(quoteAmount >= quoteAmountMin, "Router.addLiquidity: INSUFFICIENT_QUOTE_AMOUNT");
    }

    function addLiquidityETH(
        address quoteToken,
        uint256 quoteAmountMin,
        uint256 deadline,
        bool pcv
    )
        external
        payable
        override
        ensure(deadline)
        returns (
            uint256 ethAmount,
            uint256 quoteAmount,
            uint256 liquidity
        )
    {
        address amm = IPairFactory(pairFactory).getAmm(WETH, quoteToken);
        if (amm == address(0)) {
            (amm, ) = IPairFactory(pairFactory).createPair(WETH, quoteToken);
        }

        ethAmount = msg.value;
        IWETH(WETH).deposit{value: ethAmount}();
        assert(IWETH(WETH).transfer(amm, ethAmount));
        if (pcv) {
            (, quoteAmount, liquidity) = IAmm(amm).mint(address(this));
            TransferHelper.safeTransfer(amm, pcvTreasury, liquidity);
        } else {
            (, quoteAmount, liquidity) = IAmm(amm).mint(msg.sender);
        }
        require(quoteAmount >= quoteAmountMin, "Router.addLiquidityETH: INSUFFICIENT_QUOTE_AMOUNT");
    }

    function removeLiquidity(
        address baseToken,
        address quoteToken,
        uint256 liquidity,
        uint256 baseAmountMin,
        uint256 deadline
    ) external override ensure(deadline) returns (uint256 baseAmount, uint256 quoteAmount) {
        address amm = IPairFactory(pairFactory).getAmm(baseToken, quoteToken);
        TransferHelper.safeTransferFrom(amm, msg.sender, amm, liquidity);
        (baseAmount, quoteAmount, ) = IAmm(amm).burn(msg.sender);
        require(baseAmount >= baseAmountMin, "Router.removeLiquidity: INSUFFICIENT_BASE_AMOUNT");
    }

    function removeLiquidityETH(
        address quoteToken,
        uint256 liquidity,
        uint256 ethAmountMin,
        uint256 deadline
    ) external override ensure(deadline) returns (uint256 ethAmount, uint256 quoteAmount) {
        address amm = IPairFactory(pairFactory).getAmm(WETH, quoteToken);
        TransferHelper.safeTransferFrom(amm, msg.sender, amm, liquidity);
        (ethAmount, quoteAmount, ) = IAmm(amm).burn(address(this));
        require(ethAmount >= ethAmountMin, "Router.removeLiquidityETH: INSUFFICIENT_ETH_AMOUNT");
        IWETH(WETH).withdraw(ethAmount);
        TransferHelper.safeTransferETH(msg.sender, ethAmount);
    }

    function deposit(
        address baseToken,
        address quoteToken,
        address holder,
        uint256 amount
    ) external override {
        address margin = IPairFactory(pairFactory).getMargin(baseToken, quoteToken);
        require(margin != address(0), "Router.deposit: NOT_FOUND_MARGIN");
        TransferHelper.safeTransferFrom(baseToken, msg.sender, margin, amount);
        IMargin(margin).addMargin(holder, amount);
    }

    function depositETH(address quoteToken, address holder) external payable override {
        address margin = IPairFactory(pairFactory).getMargin(WETH, quoteToken);
        require(margin != address(0), "Router.depositETH: NOT_FOUND_MARGIN");
        uint256 amount = msg.value;
        IWETH(WETH).deposit{value: amount}();
        assert(IWETH(WETH).transfer(margin, amount));
        IMargin(margin).addMargin(holder, amount);
    }

    function withdraw(
        address baseToken,
        address quoteToken,
        uint256 amount
    ) external override {
        address margin = IPairFactory(pairFactory).getMargin(baseToken, quoteToken);
        require(margin != address(0), "Router.withdraw: NOT_FOUND_MARGIN");
        IMargin(margin).removeMargin(msg.sender, msg.sender, amount);
    }

    function withdrawETH(address quoteToken, uint256 amount) external override {
        address margin = IPairFactory(pairFactory).getMargin(WETH, quoteToken);
        require(margin != address(0), "Router.withdraw: NOT_FOUND_MARGIN");
        IMargin(margin).removeMargin(msg.sender, address(this), amount);
        IWETH(WETH).withdraw(amount);
        TransferHelper.safeTransferETH(msg.sender, amount);
    }

    function openPositionWithWallet(
        address baseToken,
        address quoteToken,
        uint8 side,
        uint256 marginAmount,
        uint256 quoteAmount,
        uint256 baseAmountLimit,
        uint256 deadline
    ) external override ensure(deadline) returns (uint256 baseAmount) {
        address margin = IPairFactory(pairFactory).getMargin(baseToken, quoteToken);
        require(margin != address(0), "Router.openPositionWithWallet: NOT_FOUND_MARGIN");
        require(side == 0 || side == 1, "Router.openPositionWithWallet: INSUFFICIENT_SIDE");
        TransferHelper.safeTransferFrom(baseToken, msg.sender, margin, marginAmount);
        IMargin(margin).addMargin(msg.sender, marginAmount);
        baseAmount = IMargin(margin).openPosition(msg.sender, side, quoteAmount);
        if (side == 0) {
            require(baseAmount >= baseAmountLimit, "Router.openPositionWithWallet: INSUFFICIENT_QUOTE_AMOUNT");
        } else {
            require(baseAmount <= baseAmountLimit, "Router.openPositionWithWallet: INSUFFICIENT_QUOTE_AMOUNT");
        }
    }

    function openPositionETHWithWallet(
        address quoteToken,
        uint8 side,
        uint256 quoteAmount,
        uint256 baseAmountLimit,
        uint256 deadline
    ) external payable override ensure(deadline) returns (uint256 baseAmount) {
        address margin = IPairFactory(pairFactory).getMargin(WETH, quoteToken);
        require(margin != address(0), "Router.openPositionETHWithWallet: NOT_FOUND_MARGIN");
        require(side == 0 || side == 1, "Router.openPositionETHWithWallet: INSUFFICIENT_SIDE");
        uint256 marginAmount = msg.value;
        IWETH(WETH).deposit{value: marginAmount}();
        assert(IWETH(WETH).transfer(margin, marginAmount));
        IMargin(margin).addMargin(msg.sender, marginAmount);
        baseAmount = IMargin(margin).openPosition(msg.sender, side, quoteAmount);
        if (side == 0) {
            require(baseAmount >= baseAmountLimit, "Router.openPositionETHWithWallet: INSUFFICIENT_QUOTE_AMOUNT");
        } else {
            require(baseAmount <= baseAmountLimit, "Router.openPositionETHWithWallet: INSUFFICIENT_QUOTE_AMOUNT");
        }
    }

    function openPositionWithMargin(
        address baseToken,
        address quoteToken,
        uint8 side,
        uint256 quoteAmount,
        uint256 baseAmountLimit,
        uint256 deadline
    ) external override ensure(deadline) returns (uint256 baseAmount) {
        address margin = IPairFactory(pairFactory).getMargin(baseToken, quoteToken);
        require(margin != address(0), "Router.openPositionWithMargin: NOT_FOUND_MARGIN");
        require(side == 0 || side == 1, "Router.openPositionWithMargin: INSUFFICIENT_SIDE");
        baseAmount = IMargin(margin).openPosition(msg.sender, side, quoteAmount);
        if (side == 0) {
            require(baseAmount >= baseAmountLimit, "Router.openPositionWithMargin: INSUFFICIENT_QUOTE_AMOUNT");
        } else {
            require(baseAmount <= baseAmountLimit, "Router.openPositionWithMargin: INSUFFICIENT_QUOTE_AMOUNT");
        }
    }

    function closePosition(
        address baseToken,
        address quoteToken,
        uint256 quoteAmount,
        uint256 deadline,
        bool autoWithdraw
    ) external override ensure(deadline) returns (uint256 baseAmount, uint256 withdrawAmount) {
        address margin = IPairFactory(pairFactory).getMargin(baseToken, quoteToken);
        require(margin != address(0), "Router.closePosition: NOT_FOUND_MARGIN");
        (, int256 quoteSize, ) = IMargin(margin).getPosition(msg.sender);
        baseAmount = IMargin(margin).closePosition(msg.sender, quoteAmount);
        if (autoWithdraw) {
            uint256 withdrawable = IMargin(margin).getWithdrawable(msg.sender);
            if (withdrawable > 0) {
                if (quoteSize > 0) {
                    withdrawAmount = FullMath.mulDiv(quoteAmount, withdrawable, uint256(quoteSize));
                } else {
                    withdrawAmount = FullMath.mulDiv(quoteAmount, withdrawable, uint256(0 - quoteSize));
                }
                IMargin(margin).removeMargin(msg.sender, msg.sender, withdrawAmount);
            }
        }
    }

    function closePositionETH(
        address quoteToken,
        uint256 quoteAmount,
        uint256 deadline
    ) external override ensure(deadline) returns (uint256 baseAmount, uint256 withdrawAmount) {
        address margin = IPairFactory(pairFactory).getMargin(WETH, quoteToken);
        require(margin != address(0), "Router.closePositionETH: NOT_FOUND_MARGIN");
        (, int256 quoteSize, ) = IMargin(margin).getPosition(msg.sender);
        baseAmount = IMargin(margin).closePosition(msg.sender, quoteAmount);
        uint256 withdrawable = IMargin(margin).getWithdrawable(msg.sender);
        if (withdrawable > 0) {
            if (quoteSize > 0) {
                withdrawAmount = FullMath.mulDiv(quoteAmount, withdrawable, uint256(quoteSize));
            } else {
                withdrawAmount = FullMath.mulDiv(quoteAmount, withdrawable, uint256(0 - quoteSize));
            }
            IMargin(margin).removeMargin(msg.sender, address(this), withdrawAmount);
            IWETH(WETH).withdraw(withdrawAmount);
            TransferHelper.safeTransferETH(msg.sender, withdrawAmount);
        }
    }

    function getReserves(address baseToken, address quoteToken)
        external
        view
        override
        returns (uint256 reserveBase, uint256 reserveQuote)
    {
        address amm = IPairFactory(pairFactory).getAmm(baseToken, quoteToken);
        (reserveBase, reserveQuote, ) = IAmm(amm).getReserves();
    }

    function getQuoteAmount(
        address baseToken,
        address quoteToken,
        uint8 side,
        uint256 baseAmount
    ) external view override returns (uint256 quoteAmount) {
        address amm = IPairFactory(pairFactory).getAmm(baseToken, quoteToken);
        (uint256 reserveBase, uint256 reserveQuote, ) = IAmm(amm).getReserves();
        if (side == 0) {
            quoteAmount = getAmountIn(baseAmount, reserveQuote, reserveBase);
        } else {
            quoteAmount = getAmountOut(baseAmount, reserveBase, reserveQuote);
        }
    }

    function getWithdrawable(
        address baseToken,
        address quoteToken,
        address holder
    ) external view override returns (uint256 amount) {
        address margin = IPairFactory(pairFactory).getMargin(baseToken, quoteToken);
        amount = IMargin(margin).getWithdrawable(holder);
    }

    function getPosition(
        address baseToken,
        address quoteToken,
        address holder
    )
        external
        view
        override
        returns (
            int256 baseSize,
            int256 quoteSize,
            uint256 tradeSize
        )
    {
        address margin = IPairFactory(pairFactory).getMargin(baseToken, quoteToken);
        (baseSize, quoteSize, tradeSize) = IMargin(margin).getPosition(holder);
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "Router.getAmountOut: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "Router.getAmountOut: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn * 999;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "Router.getAmountIn: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "Router.getAmountIn: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 999;
        amountIn = numerator / denominator + 1;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IRouter {
    function pairFactory() external view returns (address);

    function pcvTreasury() external view returns (address);

    function WETH() external view returns (address);

    function addLiquidity(
        address baseToken,
        address quoteToken,
        uint256 baseAmount,
        uint256 quoteAmountMin,
        uint256 deadline,
        bool pcv
    ) external returns (uint256 quoteAmount, uint256 liquidity);

    function addLiquidityETH(
        address quoteToken,
        uint256 quoteAmountMin,
        uint256 deadline,
        bool pcv
    )
        external
        payable
        returns (
            uint256 ethAmount,
            uint256 quoteAmount,
            uint256 liquidity
        );

    function removeLiquidity(
        address baseToken,
        address quoteToken,
        uint256 liquidity,
        uint256 baseAmountMin,
        uint256 deadline
    ) external returns (uint256 baseAmount, uint256 quoteAmount);

    function removeLiquidityETH(
        address quoteToken,
        uint256 liquidity,
        uint256 ethAmountMin,
        uint256 deadline
    ) external returns (uint256 ethAmount, uint256 quoteAmount);

    function deposit(
        address baseToken,
        address quoteToken,
        address holder,
        uint256 amount
    ) external;

    function depositETH(address quoteToken, address holder) external payable;

    function withdraw(
        address baseToken,
        address quoteToken,
        uint256 amount
    ) external;

    function withdrawETH(address quoteToken, uint256 amount) external;

    function openPositionWithWallet(
        address baseToken,
        address quoteToken,
        uint8 side,
        uint256 marginAmount,
        uint256 quoteAmount,
        uint256 baseAmountLimit,
        uint256 deadline
    ) external returns (uint256 baseAmount);

    function openPositionETHWithWallet(
        address quoteToken,
        uint8 side,
        uint256 quoteAmount,
        uint256 baseAmountLimit,
        uint256 deadline
    ) external payable returns (uint256 baseAmount);

    function openPositionWithMargin(
        address baseToken,
        address quoteToken,
        uint8 side,
        uint256 quoteAmount,
        uint256 baseAmountLimit,
        uint256 deadline
    ) external returns (uint256 baseAmount);

    function closePosition(
        address baseToken,
        address quoteToken,
        uint256 quoteAmount,
        uint256 deadline,
        bool autoWithdraw
    ) external returns (uint256 baseAmount, uint256 withdrawAmount);

    function closePositionETH(
        address quoteToken,
        uint256 quoteAmount,
        uint256 deadline
    ) external returns (uint256 baseAmount, uint256 withdrawAmount);

    function getReserves(address baseToken, address quoteToken)
        external
        view
        returns (uint256 reserveBase, uint256 reserveQuote);

    function getQuoteAmount(
        address baseToken,
        address quoteToken,
        uint8 side,
        uint256 baseAmount
    ) external view returns (uint256 quoteAmount);

    function getWithdrawable(
        address baseToken,
        address quoteToken,
        address holder
    ) external view returns (uint256 amount);

    function getPosition(
        address baseToken,
        address quoteToken,
        address holder
    )
        external
        view
        returns (
            int256 baseSize,
            int256 quoteSize,
            uint256 tradeSize
        );
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IPairFactory {
    event NewPair(address indexed baseToken, address indexed quoteToken, address amm, address margin);

    function createPair(address baseToken, address quotoToken) external returns (address amm, address margin);

    function ammFactory() external view returns (address);

    function marginFactory() external view returns (address);

    function getAmm(address baseToken, address quoteToken) external view returns (address);

    function getMargin(address baseToken, address quoteToken) external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IAmm {
    event Mint(address indexed sender, address indexed to, uint256 baseAmount, uint256 quoteAmount, uint256 liquidity);
    event Burn(address indexed sender, address indexed to, uint256 baseAmount, uint256 quoteAmount, uint256 liquidity);
    event Swap(address indexed inputToken, address indexed outputToken, uint256 inputAmount, uint256 outputAmount);
    event ForceSwap(address indexed inputToken, address indexed outputToken, uint256 inputAmount, uint256 outputAmount);
    event Rebase(uint256 quoteReserveBefore, uint256 quoteReserveAfter);
    event Sync(uint112 reserveBase, uint112 reserveQuote);

    // only factory can call this function
    function initialize(
        address baseToken_,
        address quoteToken_,
        address margin_
    ) external;

    function mint(address to)
        external
        returns (
            uint256 baseAmount,
            uint256 quoteAmount,
            uint256 liquidity
        );

    function burn(address to)
        external
        returns (
            uint256 baseAmount,
            uint256 quoteAmount,
            uint256 liquidity
        );

    // only binding margin can call this function
    function swap(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external returns (uint256[2] memory amounts);

    // only binding margin can call this function
    function forceSwap(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external;

    function rebase() external returns (uint256 quoteReserveAfter);

    function factory() external view returns (address);

    function config() external view returns (address);

    function baseToken() external view returns (address);

    function quoteToken() external view returns (address);

    function margin() external view returns (address);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function lastPrice() external view returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 reserveBase,
            uint112 reserveQuote,
            uint32 blockTimestamp
        );

    function estimateSwap(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external view returns (uint256[2] memory amounts);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IMargin {
    struct Position {
        int256 quoteSize; //quote amount of position
        int256 baseSize; //margin + fundingFee + unrealizedPnl + deltaBaseWhenClosePosition
        uint256 tradeSize; //if quoteSize>0 unrealizedPnl = baseValueOfQuoteSize - tradeSize; if quoteSize<0 unrealizedPnl = tradeSize - baseValueOfQuoteSize;
    }

    event AddMargin(address indexed trader, uint256 depositAmount, Position position);
    event RemoveMargin(
        address indexed trader,
        address indexed to,
        uint256 withdrawAmount,
        int256 fundingFee,
        uint256 withdrawAmountFromMargin,
        Position position
    );
    event OpenPosition(address indexed trader, uint8 side, uint256 baseAmount, uint256 quoteAmount, Position position);
    event ClosePosition(
        address indexed trader,
        uint256 quoteAmount,
        uint256 baseAmount,
        int256 fundingFee,
        Position position
    );
    event Liquidate(
        address indexed liquidator,
        address indexed trader,
        uint256 quoteAmount,
        uint256 baseAmount,
        uint256 bonus,
        Position position
    );
    event UpdateCPF(uint256 timeStamp, int256 cpf);

    /// @notice only factory can call this function
    /// @param baseToken_ margin's baseToken.
    /// @param quoteToken_ margin's quoteToken.
    /// @param amm_ amm address.
    function initialize(
        address baseToken_,
        address quoteToken_,
        address amm_
    ) external;

    /// @notice add margin to trader
    /// @param trader .
    /// @param depositAmount base amount to add.
    function addMargin(address trader, uint256 depositAmount) external;

    /// @notice remove margin to msg.sender
    /// @param withdrawAmount base amount to withdraw.
    function removeMargin(
        address trader,
        address to,
        uint256 withdrawAmount
    ) external;

    /// @notice open position with side and quoteAmount by msg.sender
    /// @param side long or short.
    /// @param quoteAmount quote amount.
    function openPosition(
        address trader,
        uint8 side,
        uint256 quoteAmount
    ) external returns (uint256 baseAmount);

    /// @notice close msg.sender's position with quoteAmount
    /// @param quoteAmount quote amount to close.
    function closePosition(address trader, uint256 quoteAmount) external returns (uint256 baseAmount);

    /// @notice liquidate trader
    function liquidate(address trader)
        external
        returns (
            uint256 quoteAmount,
            uint256 baseAmount,
            uint256 bonus
        );

    function updateCPF() external returns (int256);

    /// @notice get factory address
    function factory() external view returns (address);

    /// @notice get config address
    function config() external view returns (address);

    /// @notice get base token address
    function baseToken() external view returns (address);

    /// @notice get quote token address
    function quoteToken() external view returns (address);

    /// @notice get amm address of this margin
    function amm() external view returns (address);

    /// @notice get all users' net position of base
    function netPosition() external view returns (int256 netBasePosition);

    /// @notice get trader's position
    function getPosition(address trader)
        external
        view
        returns (
            int256 baseSize,
            int256 quoteSize,
            uint256 tradeSize
        );

    /// @notice get withdrawable margin of trader
    function getWithdrawable(address trader) external view returns (uint256 amount);

    /// @notice check if can liquidate this trader's position
    function canLiquidate(address trader) external view returns (bool);

    /// @notice calculate the latest funding fee with current position
    function calFundingFee(address trader) external view returns (int256 fundingFee);

    /// @notice calculate the latest debt ratio with Pnl and funding fee
    function calDebtRatio(address trader) external view returns (uint256 debtRatio);

    function calUnrealizedPnl(address trader) external view returns (int256);

    function getNewLatestCPF() external view returns (int256);

    function querySwapBaseWithAmm(bool isLong, uint256 quoteAmount) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./IERC20.sol";

interface ILiquidityERC20 is IERC20 {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
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
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
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
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product

        // todo unchecked
        unchecked {
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (~denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }

            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.

            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);
}