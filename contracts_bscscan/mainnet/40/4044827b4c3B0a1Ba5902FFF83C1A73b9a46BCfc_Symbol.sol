// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './ISymbol.sol';
import './SymbolStorage.sol';

contract Symbol is SymbolStorage {

    constructor (string memory symbol_) {
        symbol = symbol_;
    }

    function setImplementation(address newImplementation) external _onlyAdmin_ {
        address oldImplementation = implementation;
        if (oldImplementation != address(0)) {
            require(
                ISymbol(oldImplementation).manager() == ISymbol(newImplementation).manager(),
                'Symbol.setImplementation: wrong manager'
            );
            require(
                ISymbol(oldImplementation).symbolId() == ISymbol(newImplementation).symbolId(),
                'Symbol.setImplementation: wrong symbolId'
            );
        }
        implementation = newImplementation;
        emit NewImplementation(newImplementation);
    }

    fallback() external {
        address imp = implementation;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), imp, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface ISymbol {

    struct SettlementOnAddLiquidity {
        bool settled;
        int256 funding;
        int256 deltaTradersPnl;
        int256 deltaInitialMarginRequired;
    }

    struct SettlementOnRemoveLiquidity {
        bool settled;
        int256 funding;
        int256 deltaTradersPnl;
        int256 deltaInitialMarginRequired;
        int256 removeLiquidityPenalty;
    }

    struct SettlementOnTraderWithPosition {
        int256 funding;
        int256 deltaTradersPnl;
        int256 deltaInitialMarginRequired;
        int256 traderFunding;
        int256 traderPnl;
        int256 traderInitialMarginRequired;
    }

    struct SettlementOnTrade {
        int256 funding;
        int256 deltaTradersPnl;
        int256 deltaInitialMarginRequired;
        int256 indexPrice;
        int256 traderFunding;
        int256 traderPnl;
        int256 traderInitialMarginRequired;
        int256 tradeCost;
        int256 tradeFee;
        int256 tradeRealizedCost;
        int256 positionChangeStatus; // 1: new open (enter), -1: total close (exit), 0: others (not change)
    }

    struct SettlementOnLiquidate {
        int256 funding;
        int256 deltaTradersPnl;
        int256 deltaInitialMarginRequired;
        int256 indexPrice;
        int256 traderFunding;
        int256 traderPnl;
        int256 traderMaintenanceMarginRequired;
        int256 tradeVolume;
        int256 tradeCost;
        int256 tradeRealizedCost;
    }

    struct Position {
        int256 volume;
        int256 cost;
        int256 cumulativeFundingPerVolume;
    }

    function implementation() external view returns (address);

    function symbol() external view returns (string memory);

    function netVolume() external view returns (int256);

    function netCost() external view returns (int256);

    function indexPrice() external view returns (int256);

    function fundingTimestamp() external view returns (uint256);

    function cumulativeFundingPerVolume() external view returns (int256);

    function tradersPnl() external view returns (int256);

    function initialMarginRequired() external view returns (int256);

    function nPositionHolders() external view returns (uint256);

    function positions(uint256 pTokenId) external view returns (Position memory);

    function setImplementation(address newImplementation) external;

    function manager() external view returns (address);

    function oracleManager() external view returns (address);

    function symbolId() external view returns (bytes32);

    function feeRatio() external view returns (int256);             // futures only

    function alpha() external view returns (int256);

    function fundingPeriod() external view returns (int256);

    function minTradeVolume() external view returns (int256);

    function initialMarginRatio() external view returns (int256);

    function maintenanceMarginRatio() external view returns (int256);

    function pricePercentThreshold() external view returns (int256);

    function timeThreshold() external view returns (uint256);

    function isCloseOnly() external view returns (bool);

    function priceId() external view returns (bytes32);              // option only

    function volatilityId() external view returns (bytes32);         // option only

    function feeRatioITM() external view returns (int256);           // option only

    function feeRatioOTM() external view returns (int256);           // option only

    function strikePrice() external view returns (int256);           // option only

    function minInitialMarginRatio() external view returns (int256); // option only

    function isCall() external view returns (bool);                  // option only

    function hasPosition(uint256 pTokenId) external view returns (bool);

    function settleOnAddLiquidity(int256 liquidity)
    external returns (ISymbol.SettlementOnAddLiquidity memory s);

    function settleOnRemoveLiquidity(int256 liquidity, int256 removedLiquidity)
    external returns (ISymbol.SettlementOnRemoveLiquidity memory s);

    function settleOnTraderWithPosition(uint256 pTokenId, int256 liquidity)
    external returns (ISymbol.SettlementOnTraderWithPosition memory s);

    function settleOnTrade(uint256 pTokenId, int256 tradeVolume, int256 liquidity)
    external returns (ISymbol.SettlementOnTrade memory s);

    function settleOnLiquidate(uint256 pTokenId, int256 liquidity)
    external returns (ISymbol.SettlementOnLiquidate memory s);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/Admin.sol';

abstract contract SymbolStorage is Admin {

    // admin will be truned in to Timelock after deployment

    event NewImplementation(address newImplementation);

    address public implementation;

    string public symbol;

    int256 public netVolume;

    int256 public netCost;

    int256 public indexPrice;

    uint256 public fundingTimestamp;

    int256 public cumulativeFundingPerVolume;

    int256 public tradersPnl;

    int256 public initialMarginRequired;

    uint256 public nPositionHolders;

    struct Position {
        int256 volume;
        int256 cost;
        int256 cumulativeFundingPerVolume;
    }

    // pTokenId => Position
    mapping (uint256 => Position) public positions;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './IAdmin.sol';

abstract contract Admin is IAdmin {

    address public admin;

    modifier _onlyAdmin_() {
        require(msg.sender == admin, 'Admin: only admin');
        _;
    }

    constructor () {
        admin = msg.sender;
        emit NewAdmin(admin);
    }

    function setAdmin(address newAdmin) external _onlyAdmin_ {
        admin = newAdmin;
        emit NewAdmin(newAdmin);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface IAdmin {

    event NewAdmin(address indexed newAdmin);

    function admin() external view returns (address);

    function setAdmin(address newAdmin) external;

}