pragma solidity ^0.8.0;

import "./interfaces/IRouter.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/IAmm.sol";
import "./interfaces/IMargin.sol";
import "./interfaces/ILiquidityERC20.sol";
import "./interfaces/IStaking.sol";
import "./libraries/TransferHelper.sol";

contract Router is IRouter {
    address public immutable override factory;
    address public immutable override WETH;

    modifier ensure(uint256 deadline) {
        require(deadline >= block.timestamp, "Router: EXPIRED");
        _;
    }

    constructor(address _factory, address _WETH) {
        factory = _factory;
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
        bool autoStake
    ) external override ensure(deadline) returns (uint256 quoteAmount, uint256 liquidity) {
        if (IFactory(factory).getAmm(baseToken, quoteToken) == address(0)) {
            IFactory(factory).createPair(baseToken, quoteToken);
            IFactory(factory).createStaking(baseToken, quoteToken);
        }
        address amm = IFactory(factory).getAmm(baseToken, quoteToken);
        TransferHelper.safeTransferFrom(baseToken, msg.sender, amm, baseAmount);
        if (autoStake) {
            (quoteAmount, liquidity) = IAmm(amm).mint(address(this));
            address staking = IFactory(factory).getStaking(amm);
            ILiquidityERC20(amm).approve(staking, liquidity);
            IStaking(staking).stake(liquidity);
        } else {
            (quoteAmount, liquidity) = IAmm(amm).mint(msg.sender);
        }
        require(quoteAmount >= quoteAmountMin, "Router: INSUFFICIENT_QUOTE_AMOUNT");
    }

    function removeLiquidity(
        address baseToken,
        address quoteToken,
        uint256 liquidity,
        uint256 baseAmountMin,
        uint256 deadline
    ) external override ensure(deadline) returns (uint256 baseAmount, uint256 quoteAmount) {
        address amm = IFactory(factory).getAmm(baseToken, quoteToken);
        ILiquidityERC20(amm).transferFrom(msg.sender, amm, liquidity);
        (baseAmount, quoteAmount) = IAmm(amm).burn(msg.sender);
        require(baseAmount >= baseAmountMin, "Router: INSUFFICIENT_BASE_AMOUNT");
    }

    function deposit(
        address baseToken,
        address quoteToken,
        address holder,
        uint256 amount
    ) external override {
        address margin = IFactory(factory).getMargin(baseToken, quoteToken);
        require(margin != address(0), "Router: ZERO_ADDRESS");
        TransferHelper.safeTransferFrom(baseToken, msg.sender, margin, amount);
        IMargin(margin).addMargin(holder, amount);
    }

    function withdraw(
        address baseToken,
        address quoteToken,
        uint256 amount
    ) external override {
        address margin = IFactory(factory).getMargin(baseToken, quoteToken);
        require(margin != address(0), "Router: ZERO_ADDRESS");
        delegateTo(margin, abi.encodeWithSignature("removeMargin(uint256)", amount));
    }

    function openPositionWithWallet(
        address baseToken,
        address quoteToken,
        uint8 side,
        uint256 marginAmount,
        uint256 baseAmount,
        uint256 quoteAmountLimit,
        uint256 deadline
    ) external override ensure(deadline) returns (uint256 quoteAmount) {
        address margin = IFactory(factory).getMargin(baseToken, quoteToken);
        require(margin != address(0), "Router: ZERO_ADDRESS");
        TransferHelper.safeTransferFrom(baseToken, msg.sender, margin, marginAmount);
        IMargin(margin).addMargin(msg.sender, marginAmount);
        require(side == 0 || side == 1, "Router: INSUFFICIENT_SIDE");
        // bytes memory data = delegateTo(
        //     margin,
        //     abi.encodeWithSignature("openPosition(uint8,uint256)", side, baseAmount)
        // );
        // quoteAmount = abi.decode(data, (uint256));
        // if (side == 0) {
        //     require(quoteAmount <= quoteAmountLimit, "Router: INSUFFICIENT_QUOTE_AMOUNT");
        // } else {
        //     require(quoteAmount >= quoteAmountLimit, "Router: INSUFFICIENT_QUOTE_AMOUNT");
        // }
        IMargin(margin).openPosition(side, baseAmount);
    }

    function openPositionWithMargin(
        address baseToken,
        address quoteToken,
        uint8 side,
        uint256 baseAmount,
        uint256 quoteAmountLimit,
        uint256 deadline
    ) external override ensure(deadline) returns (uint256 quoteAmount) {
        address margin = IFactory(factory).getMargin(baseToken, quoteToken);
        require(margin != address(0), "Router: ZERO_ADDRESS");
        require(side == 0 || side == 1, "Router: INSUFFICIENT_SIDE");
        bytes memory data = delegateTo(
            margin,
            abi.encodeWithSignature("openPosition(uint8,uint256)", side, baseAmount)
        );
        quoteAmount = abi.decode(data, (uint256));
        if (side == 0) {
            require(quoteAmount <= quoteAmountLimit, "Router: INSUFFICIENT_QUOTE_AMOUNT");
        } else {
            require(quoteAmount >= quoteAmountLimit, "Router: INSUFFICIENT_QUOTE_AMOUNT");
        }
    }

    function closePosition(
        address baseToken,
        address quoteToken,
        uint256 quoteAmount,
        uint256 deadline,
        bool autoWithdraw
    ) external override ensure(deadline) returns (uint256 baseAmount, uint256 withdrawAmount) {
        address margin = IFactory(factory).getMargin(baseToken, quoteToken);
        require(margin != address(0), "Router: ZERO_ADDRESS");
        bytes memory data = delegateTo(margin, abi.encodeWithSignature("closePosition(uint256)", quoteAmount));
        baseAmount = abi.decode(data, (uint256));
        if (autoWithdraw) {
            withdrawAmount = IMargin(margin).getWithdrawable(msg.sender);
            IMargin(margin).removeMargin(withdrawAmount);
        }
    }

    function getReserves(address baseToken, address quoteToken)
        external
        view
        override
        returns (uint256 reserveBase, uint256 reserveQuote)
    {
        address amm = IFactory(factory).getAmm(baseToken, quoteToken);
        (reserveBase, reserveQuote, ) = IAmm(amm).getReserves();
    }

    function getQuoteAmount(
        address baseToken,
        address quoteToken,
        uint8 side,
        uint256 baseAmount
    ) external view override returns (uint256 quoteAmount) {
        address amm = IFactory(factory).getAmm(baseToken, quoteToken);
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
        address margin = IFactory(factory).getMargin(baseToken, quoteToken);
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
        address margin = IFactory(factory).getMargin(baseToken, quoteToken);
        (baseSize, quoteSize, tradeSize) = IMargin(margin).getPosition(holder);
    }

    function queryMaxOpenPosition(
        address baseToken,
        address quoteToken,
        uint8 side,
        uint256 baseAmount
    ) external view override returns (uint256 quoteAmount) {
        address margin = IFactory(factory).getMargin(baseToken, quoteToken);
        return IMargin(margin).queryMaxOpenPosition(side, baseAmount);
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
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
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 999;
        amountIn = numerator / denominator + 1;
    }

    function delegateTo(address callee, bytes memory data) internal returns (bytes memory) {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return returnData;
    }
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IRouter {
    function factory() external view returns (address);

    function WETH() external view returns (address);

    function addLiquidity(
        address baseToken,
        address quoteToken,
        uint256 baseAmount,
        uint256 quoteAmountMin,
        uint256 deadline,
        bool autoStake
    ) external returns (uint256 quoteAmount, uint256 liquidity);

    function removeLiquidity(
        address baseToken,
        address quoteToken,
        uint256 liquidity,
        uint256 baseAmountMin,
        uint256 deadline
    ) external returns (uint256 baseAmount, uint256 quoteAmount);

    function deposit(
        address baseToken,
        address quoteToken,
        address holder,
        uint256 amount
    ) external;

    function withdraw(
        address baseToken,
        address quoteToken,
        uint256 amount
    ) external;

    function openPositionWithWallet(
        address baseToken,
        address quoteToken,
        uint8 side,
        uint256 marginAmount,
        uint256 baseAmount,
        uint256 quoteAmountLimit,
        uint256 deadline
    ) external returns (uint256 quoteAmount);

    function openPositionWithMargin(
        address baseToken,
        address quoteToken,
        uint8 side,
        uint256 baseAmount,
        uint256 quoteAmountLimit,
        uint256 deadline
    ) external returns (uint256 quoteAmount);

    function closePosition(
        address baseToken,
        address quoteToken,
        uint256 quoteAmount,
        uint256 deadline,
        bool autoWithdraw
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

    function queryMaxOpenPosition(
        address baseToken,
        address quoteToken,
        uint8 side,
        uint256 baseAmount
    ) external view returns (uint256 quoteAmount);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IFactory {
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
    event NewAdmin(address oldAdmin, address newAdmin);
    event NewPair(address indexed baseToken, address indexed quoteToken, address amm, address margin, address vault);
    event NewStaking(address indexed baseToken, address indexed quoteToken, address staking);

    function pendingAdmin() external view returns (address);

    function admin() external view returns (address);

    function config() external view returns (address);

    function getAmm(address baseToken, address quoteToken) external view returns (address amm);

    function getMargin(address baseToken, address quoteToken) external view returns (address margin);

    function getVault(address baseToken, address quoteToken) external view returns (address vault);

    function getStaking(address amm) external view returns (address staking);

    function setPendingAdmin(address newPendingAdmin) external;

    function acceptAdmin() external;

    function createPair(address baseToken, address quotoToken)
        external
        returns (
            address amm,
            address margin,
            address vault
        );

    function createStaking(address baseToken, address quoteToken) external returns (address staking);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IAmm {
    event Mint(address indexed sender, address indexed to, uint256 baseAmount, uint256 quoteAmount, uint256 liquidity);
    event Burn(address indexed sender, address indexed to, uint256 baseAmount, uint256 quoteAmount);
    event Swap(address indexed inputToken, address indexed outputToken, uint256 inputAmount, uint256 outputAmount);
    event ForceSwap(address indexed inputToken, address indexed outputToken, uint256 inputAmount, uint256 outputAmount);
    event Rebase(uint256 quoteAmountBefore, uint256 quoteAmountAfter, uint256 baseAmount);
    event Sync(uint112 reserveBase, uint112 reserveQuote);

    function baseToken() external view returns (address);

    function quoteToken() external view returns (address);

    function factory() external view returns (address);

    function config() external view returns (address);

    function margin() external view returns (address);

    function vault() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserveBase,
            uint112 reserveQuote,
            uint32 blockTimestamp
        );

    // only factory can call this function
    function initialize(
        address _baseToken,
        address _quoteToken,
        address _config,
        address _margin,
        address _vault
    ) external;

    function mint(address to) external returns (uint256 quoteAmount, uint256 liquidity);

    function burn(address to) external returns (uint256 baseAmount, uint256 quoteAmount);

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

    function rebase() external returns (uint256 amount);

    function swapQuery(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external view returns (uint256[2] memory amounts);

    function swapQueryWithAcctSpecMarkPrice(
        address inputToken,
        address outputToken,
        uint256 inputAmount,
        uint256 outputAmount
    ) external view returns (uint256[2] memory amounts);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IMargin {
    event AddMargin(address indexed trader, uint256 depositAmount);
    event RemoveMargin(address indexed trader, uint256 withdrawAmount);
    event OpenPosition(address indexed trader, uint8 side, uint256 baseAmount, uint256 quoteAmount);
    event ClosePosition(address indexed trader, uint256 quoteAmount, uint256 baseAmount);
    event Liquidate(
        address indexed liquidator,
        address indexed trader,
        uint256 quoteAmount,
        uint256 baseAmount,
        uint256 bonus
    );

    function baseToken() external view returns (address);

    function quoteToken() external view returns (address);

    function factory() external view returns (address);

    function config() external view returns (address);

    function amm() external view returns (address);

    function vault() external view returns (address);

    function getPosition(address trader)
        external
        view
        returns (
            int256 baseSize,
            int256 quoteSize,
            uint256 tradeSize
        );

    function getWithdrawable(address trader) external view returns (uint256 amount);

    function canLiquidate(address trader) external view returns (bool);

    function queryMaxOpenPosition(uint8 side, uint256 baseAmount) external view returns (uint256 quoteAmount);

    // only factory can call this function
    function initialize(
        address _baseToken,
        address _quoteToken,
        address _config,
        address _amm,
        address _vault
    ) external;

    function addMargin(address trader, uint256 depositAmount) external;

    function removeMargin(uint256 withdrawAmount) external;

    function openPosition(uint8 side, uint256 baseAmount) external returns (uint256 quoteAmount);

    function closePosition(uint256 quoteAmount) external returns (uint256 baseAmount);

    function liquidate(address trader)
        external
        returns (
            uint256 quoteAmount,
            uint256 baseAmount,
            uint256 bonus
        );
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./IERC20.sol";

interface ILiquidityERC20 is IERC20 {
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
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IStaking {
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    function factory() external view returns (address);
    
    function config() external view returns (address);

    function stakingToken() external view returns (address);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;
}

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
            'TransferHelper::safeApprove: approve failed'
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
            'TransferHelper::safeTransfer: transfer failed'
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
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

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