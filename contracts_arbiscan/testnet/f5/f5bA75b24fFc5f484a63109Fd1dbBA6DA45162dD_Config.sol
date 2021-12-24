// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IConfig.sol";
import "../utils/Ownable.sol";

//config is upgradable proxy, contains configurations of core contracts
contract Config is IConfig, Ownable {
    address public override priceOracle;

    uint8 public override beta = 100; // 50-200
    uint256 public override maxCPFBoost = 10; // default 10
    uint256 public override rebasePriceGap = 5; //0-100 , if 5 means 5%
    uint256 public override tradingSlippage = 5; //0-100, if 5 means 5%
    uint256 public override initMarginRatio = 800; //if 1000, means margin ratio >= 10%
    uint256 public override liquidateThreshold = 10000; //if 10000, means debt ratio < 100%
    uint256 public override liquidateFeeRatio = 100; //if 100, means liquidator bot get 1% as fee
    uint256 public override feeParameter = 150; // 100 * (1/fee -1)

    mapping(address => bool) public override routerMap;

    constructor() {
        owner = msg.sender;
    }

    function setMaxCPFBoost(uint256 newMaxCPFBoost) external override onlyOwner {
        emit SetMaxCPFBoost(maxCPFBoost, newMaxCPFBoost);
        maxCPFBoost = newMaxCPFBoost;
    }

    function setPriceOracle(address newOracle) external override onlyOwner {
        require(newOracle != address(0), "Config: ZERO_ADDRESS");
        emit PriceOracleChanged(priceOracle, newOracle);
        priceOracle = newOracle;
    }

    function setRebasePriceGap(uint256 newGap) external override onlyOwner {
        require(newGap > 0 && newGap < 100, "Config: ZERO_GAP");
        emit RebasePriceGapChanged(rebasePriceGap, newGap);
        rebasePriceGap = newGap;
    }

    function setTradingSlippage(uint256 newTradingSlippage) external override onlyOwner {
        require(newTradingSlippage > 0 && newTradingSlippage < 100, "Config: TRADING_SLIPPAGE_RANGE_ERROR");
        emit TradingSlippageChanged(tradingSlippage, newTradingSlippage);
        tradingSlippage = newTradingSlippage;
    }

    function setInitMarginRatio(uint256 marginRatio) external override onlyOwner {
        require(marginRatio >= 500, "Config: INVALID_MARGIN_RATIO");
        emit SetInitMarginRatio(initMarginRatio, marginRatio);
        initMarginRatio = marginRatio;
    }

    function setLiquidateThreshold(uint256 threshold) external override onlyOwner {
        require(threshold > 9000 && threshold <= 10000, "Config: INVALID_LIQUIDATE_THRESHOLD");
        emit SetLiquidateThreshold(liquidateThreshold, threshold);
        liquidateThreshold = threshold;
    }

    function setLiquidateFeeRatio(uint256 feeRatio) external override onlyOwner {
        require(feeRatio > 0 && feeRatio <= 2000, "Config: INVALID_LIQUIDATE_FEE_RATIO");
        emit SetLiquidateFeeRatio(liquidateFeeRatio, feeRatio);
        liquidateFeeRatio = feeRatio;
    }

    function setFeeParameter(uint256 newFeeParameter) external override onlyOwner {
        emit SetFeeParameter(feeParameter, newFeeParameter);
        feeParameter = newFeeParameter;
    }

    function setBeta(uint8 newBeta) external override onlyOwner {
        require(newBeta >= 50 && newBeta <= 200, "Config: INVALID_BETA");
        emit SetBeta(beta, newBeta);
        beta = newBeta;
    }

    //must be careful, expose all traders's position
    function registerRouter(address router) external override onlyOwner {
        require(router != address(0), "Config: ZERO_ADDRESS");
        require(!routerMap[router], "Config: REGISTERED");
        routerMap[router] = true;

        emit RouterRegistered(router);
    }

    function unregisterRouter(address router) external override onlyOwner {
        require(router != address(0), "Config: ZERO_ADDRESS");
        require(routerMap[router], "Config: UNREGISTERED");
        delete routerMap[router];

        emit RouterUnregistered(router);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IConfig {
    event PriceOracleChanged(address indexed oldOracle, address indexed newOracle);
    event RebasePriceGapChanged(uint256 oldGap, uint256 newGap);
    event TradingSlippageChanged(uint256 oldTradingSlippage, uint256 newTradingSlippage);
    event RouterRegistered(address indexed router);
    event RouterUnregistered(address indexed router);
    event SetLiquidateFeeRatio(uint256 oldLiquidateFeeRatio, uint256 liquidateFeeRatio);
    event SetLiquidateThreshold(uint256 oldLiquidateThreshold, uint256 liquidateThreshold);
    event SetInitMarginRatio(uint256 oldInitMarginRatio, uint256 initMarginRatio);
    event SetBeta(uint256 oldBeta, uint256 beta);
    event SetFeeParameter(uint256 oldFeeParameter, uint256 feeParameter);
    event SetMaxCPFBoost(uint256 oldMaxCPFBoost, uint256 maxCPFBoost);

    /// @notice get price oracle address.
    function priceOracle() external view returns (address);

    /// @notice get beta of amm.
    function beta() external view returns (uint8);

    /// @notice get feeParameter of amm.
    function feeParameter() external view returns (uint256);

    /// @notice get init margin ratio of margin.
    function initMarginRatio() external view returns (uint256);

    /// @notice get liquidate threshold of margin.
    function liquidateThreshold() external view returns (uint256);

    /// @notice get liquidate fee ratio of margin.
    function liquidateFeeRatio() external view returns (uint256);

    /// @notice get trading slippage  of amm.
    function tradingSlippage() external view returns (uint256);

    /// @notice get rebase gap of amm.
    function rebasePriceGap() external view returns (uint256);

    function routerMap(address) external view returns (bool);

    function maxCPFBoost() external view returns (uint256);

    function registerRouter(address router) external;

    function unregisterRouter(address router) external;

    /// @notice Set a new oracle
    /// @param newOracle new oracle address.
    function setPriceOracle(address newOracle) external;

    /// @notice Set a new beta of amm
    /// @param newBeta new beta.
    function setBeta(uint8 newBeta) external;

    /// @notice Set a new rebase gap of amm
    /// @param newGap new gap.
    function setRebasePriceGap(uint256 newGap) external;

    /// @notice Set a new trading slippage of amm
    /// @param newTradingSlippage .
    function setTradingSlippage(uint256 newTradingSlippage) external;

    /// @notice Set a new init margin ratio of margin
    /// @param marginRatio new init margin ratio.
    function setInitMarginRatio(uint256 marginRatio) external;

    /// @notice Set a new liquidate threshold of margin
    /// @param threshold new liquidate threshold of margin.
    function setLiquidateThreshold(uint256 threshold) external;

    /// @notice Set a new liquidate fee of margin
    /// @param feeRatio new liquidate fee of margin.
    function setLiquidateFeeRatio(uint256 feeRatio) external;

    /// @notice Set a new feeParameter.
    /// @param newFeeParameter New feeParameter get from AMM swap fee.
    /// @dev feeParameter = (1/fee -1 ) *100 where fee set by owner.
    function setFeeParameter(uint256 newFeeParameter) external;

    function setMaxCPFBoost(uint256 newMaxCPFBoost) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

abstract contract Ownable {
    address public owner;
    address public pendingOwner;

    event NewOwner(address indexed oldOwner, address indexed newOwner);
    event NewPendingOwner(address indexed oldPendingOwner, address indexed newPendingOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: REQUIRE_OWNER");
        _;
    }

    function setPendingOwner(address newPendingOwner) external onlyOwner {
        require(pendingOwner != newPendingOwner, "Ownable: ALREADY_SET");
        emit NewPendingOwner(pendingOwner, newPendingOwner);
        pendingOwner = newPendingOwner;
    }

    function acceptOwner() external {
        require(msg.sender == pendingOwner, "Ownable: REQUIRE_PENDING_OWNER");
        address oldOwner = owner;
        address oldPendingOwner = pendingOwner;
        owner = pendingOwner;
        pendingOwner = address(0);
        emit NewOwner(oldOwner, owner);
        emit NewPendingOwner(oldPendingOwner, pendingOwner);
    }
}