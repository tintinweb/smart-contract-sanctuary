// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './ISymbol.sol';
import './ISymbolManager.sol';
import './SymbolManagerStorage.sol';
import '../utils/NameVersion.sol';

contract SymbolManagerImplementation is SymbolManagerStorage, NameVersion {

    event AddSymbol(bytes32 indexed symbolId, address indexed symbol);

    event RemoveSymbol(bytes32 indexed symbolId, address indexed symbol);

    event Trade(
        uint256 indexed pTokenId,
        bytes32 indexed symbolId,
        int256 indexPrice,
        int256 tradeVolume,
        int256 tradeCost,
        int256 tradeFee
    );

    address public immutable pool;

    modifier _onlyPool_() {
        require(msg.sender == pool, 'SymbolManagerImplementation: only pool');
        _;
    }

    constructor (address pool_) NameVersion('SymbolManagerImplementation', '3.0.2') {
        pool = pool_;
    }

    function getActiveSymbols(uint256 pTokenId) external view returns (address[] memory) {
        return activeSymbols[pTokenId];
    }

    function getSymbolsLength() external view returns (uint256) {
        return indexedSymbols.length;
    }

    function addSymbol(address symbol) external _onlyAdmin_ {
        bytes32 symbolId = ISymbol(symbol).symbolId();
        require(
            symbols[symbolId] == address(0),
            'SymbolManagerImplementation.addSymbol: symbol exists'
        );
        require(
            ISymbol(symbol).manager() == address(this),
            'SymbolManagerImplementation.addSymbol: wrong manager'
        );

        symbols[symbolId] = symbol;
        indexedSymbols.push(symbol);

        emit AddSymbol(symbolId, symbol);
    }

    function removeSymbol(bytes32 symbolId) external _onlyAdmin_ {
        address symbol = symbols[symbolId];
        require(
            symbol != address(0),
            'SymbolManagerImplementation.removeSymbol: symbol not exists'
        );
        require(
            ISymbol(symbol).nPositionHolders() == 0,
            'SymbolManagerImplementation.removeSymbol: symbol has positions'
        );

        delete symbols[symbolId];

        uint256 length = indexedSymbols.length;
        for (uint256 i = 0; i < length; i++) {
            if (indexedSymbols[i] == symbol) {
                indexedSymbols[i] = indexedSymbols[length-1];
                break;
            }
        }
        indexedSymbols.pop();

        emit RemoveSymbol(symbolId, symbol);
    }

    //================================================================================

    function settleSymbolsOnAddLiquidity(int256 liquidity)
    external _onlyPool_ returns (ISymbolManager.SettlementOnAddLiquidity memory ss)
    {
        if (liquidity == 0) return ss;

        int256 deltaInitialMarginRequired;
        uint256 length = indexedSymbols.length;

        for (uint256 i = 0; i < length; i++) {
            ISymbol.SettlementOnAddLiquidity memory s =
            ISymbol(indexedSymbols[i]).settleOnAddLiquidity(liquidity);

            if (s.settled) {
                ss.funding += s.funding;
                ss.deltaTradersPnl += s.deltaTradersPnl;

                deltaInitialMarginRequired += s.deltaInitialMarginRequired;
            }
        }

        initialMarginRequired += deltaInitialMarginRequired;
    }

    function settleSymbolsOnRemoveLiquidity(int256 liquidity, int256 removedLiquidity)
    external _onlyPool_ returns (ISymbolManager.SettlementOnRemoveLiquidity memory ss)
    {
        int256 deltaInitialMarginRequired;
        uint256 length = indexedSymbols.length;

        for (uint256 i = 0; i < length; i++) {
            ISymbol.SettlementOnRemoveLiquidity memory s =
            ISymbol(indexedSymbols[i]).settleOnRemoveLiquidity(liquidity, removedLiquidity);

            if (s.settled) {
                ss.funding += s.funding;
                ss.deltaTradersPnl += s.deltaTradersPnl;
                ss.removeLiquidityPenalty += s.removeLiquidityPenalty;

                deltaInitialMarginRequired += s.deltaInitialMarginRequired;
            }
        }

        initialMarginRequired += deltaInitialMarginRequired;
        ss.initialMarginRequired = initialMarginRequired;
    }

    function settleSymbolsOnRemoveMargin(uint256 pTokenId, int256 liquidity)
    external _onlyPool_ returns (ISymbolManager.SettlementOnRemoveMargin memory ss)
    {
        int256 deltaInitialMarginRequired;
        uint256 length = activeSymbols[pTokenId].length;

        for (uint256 i = 0; i < length; i++) {
            ISymbol.SettlementOnTraderWithPosition memory s =
            ISymbol(activeSymbols[pTokenId][i]).settleOnTraderWithPosition(pTokenId, liquidity);

            ss.funding += s.funding;
            ss.deltaTradersPnl += s.deltaTradersPnl;
            deltaInitialMarginRequired += s.deltaInitialMarginRequired;

            ss.traderFunding += s.traderFunding;
            ss.traderPnl += s.traderPnl;
            ss.traderInitialMarginRequired += s.traderInitialMarginRequired;
        }

        initialMarginRequired += deltaInitialMarginRequired;
    }

    function settleSymbolsOnTrade(uint256 pTokenId, bytes32 symbolId, int256 tradeVolume, int256 liquidity, int256 priceLimit)
    external _onlyPool_ returns (ISymbolManager.SettlementOnTrade memory ss)
    {
        address tradeSymbol = symbols[symbolId];
        require(
            tradeSymbol != address(0),
            'SymbolManagerImplementation.settleSymbolsOnTrade: invalid symbol'
        );

        int256 deltaInitialMarginRequired;
        uint256 length = activeSymbols[pTokenId].length;

        uint256 index = type(uint256).max;
        for (uint256 i = 0; i < length; i++) {
            address symbol = activeSymbols[pTokenId][i];
            if (symbol != tradeSymbol) {
                ISymbol.SettlementOnTraderWithPosition memory s1 =
                ISymbol(symbol).settleOnTraderWithPosition(pTokenId, liquidity);

                ss.funding += s1.funding;
                ss.deltaTradersPnl += s1.deltaTradersPnl;
                deltaInitialMarginRequired += s1.deltaInitialMarginRequired;

                ss.traderFunding += s1.traderFunding;
                ss.traderPnl += s1.traderPnl;
                ss.traderInitialMarginRequired += s1.traderInitialMarginRequired;
            } else {
                index = i;
            }
        }

        ISymbol.SettlementOnTrade memory s2 = ISymbol(tradeSymbol).settleOnTrade(pTokenId, tradeVolume, liquidity, priceLimit);
        ss.funding += s2.funding;
        ss.deltaTradersPnl += s2.deltaTradersPnl;
        deltaInitialMarginRequired += s2.deltaInitialMarginRequired;

        ss.traderFunding += s2.traderFunding;
        ss.traderPnl += s2.traderPnl;
        ss.traderInitialMarginRequired += s2.traderInitialMarginRequired;

        ss.tradeFee = s2.tradeFee;
        ss.tradeRealizedCost = s2.tradeRealizedCost;

        initialMarginRequired += deltaInitialMarginRequired;
        ss.initialMarginRequired = initialMarginRequired;

        if (index == type(uint256).max && s2.positionChangeStatus == 1) {
            activeSymbols[pTokenId].push(tradeSymbol);
        } else if (index != type(uint256).max && s2.positionChangeStatus == -1) {
            activeSymbols[pTokenId][index] = activeSymbols[pTokenId][length-1];
            activeSymbols[pTokenId].pop();
        }

        emit Trade(pTokenId, symbolId, s2.indexPrice, tradeVolume, s2.tradeCost, s2.tradeFee);
    }

    function settleSymbolsOnLiquidate(uint256 pTokenId, int256 liquidity)
    external _onlyPool_ returns (ISymbolManager.SettlementOnLiquidate memory ss)
    {
        int256 deltaInitialMarginRequired;
        uint256 length = activeSymbols[pTokenId].length;

        for (uint256 i = 0; i < length; i++) {
            address symbol = activeSymbols[pTokenId][i];
            ISymbol.SettlementOnLiquidate memory s = ISymbol(symbol).settleOnLiquidate(pTokenId, liquidity);

            ss.funding += s.funding;
            ss.deltaTradersPnl += s.deltaTradersPnl;
            deltaInitialMarginRequired += s.deltaInitialMarginRequired;

            ss.traderFunding += s.traderFunding;
            ss.traderPnl += s.traderPnl;
            ss.traderMaintenanceMarginRequired += s.traderMaintenanceMarginRequired;

            ss.traderRealizedCost += s.tradeRealizedCost;

            emit Trade(pTokenId, ISymbol(symbol).symbolId(), s.indexPrice, s.tradeVolume, s.tradeCost, -1);
        }

        initialMarginRequired += deltaInitialMarginRequired;

        delete activeSymbols[pTokenId];
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

    function settleOnTrade(uint256 pTokenId, int256 tradeVolume, int256 liquidity, int256 priceLimit)
    external returns (ISymbol.SettlementOnTrade memory s);

    function settleOnLiquidate(uint256 pTokenId, int256 liquidity)
    external returns (ISymbol.SettlementOnLiquidate memory s);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface ISymbolManager {

    struct SettlementOnAddLiquidity {
        int256 funding;
        int256 deltaTradersPnl;
    }

    struct SettlementOnRemoveLiquidity {
        int256 funding;
        int256 deltaTradersPnl;
        int256 initialMarginRequired;
        int256 removeLiquidityPenalty;
    }

    struct SettlementOnRemoveMargin {
        int256 funding;
        int256 deltaTradersPnl;
        int256 traderFunding;
        int256 traderPnl;
        int256 traderInitialMarginRequired;
    }

    struct SettlementOnTrade {
        int256 funding;
        int256 deltaTradersPnl;
        int256 initialMarginRequired;
        int256 traderFunding;
        int256 traderPnl;
        int256 traderInitialMarginRequired;
        int256 tradeFee;
        int256 tradeRealizedCost;
    }

    struct SettlementOnLiquidate {
        int256 funding;
        int256 deltaTradersPnl;
        int256 traderFunding;
        int256 traderPnl;
        int256 traderMaintenanceMarginRequired;
        int256 traderRealizedCost;
    }

    function implementation() external view returns (address);

    function initialMarginRequired() external view returns (int256);

    function pool() external view returns (address);

    function getActiveSymbols(uint256 pTokenId) external view returns (address[] memory);

    function getSymbolsLength() external view returns (uint256);

    function addSymbol(address symbol) external;

    function removeSymbol(bytes32 symbolId) external;

    function settleSymbolsOnAddLiquidity(int256 liquidity)
    external returns (SettlementOnAddLiquidity memory ss);

    function settleSymbolsOnRemoveLiquidity(int256 liquidity, int256 removedLiquidity)
    external returns (SettlementOnRemoveLiquidity memory ss);

    function settleSymbolsOnRemoveMargin(uint256 pTokenId, int256 liquidity)
    external returns (SettlementOnRemoveMargin memory ss);

    function settleSymbolsOnTrade(uint256 pTokenId, bytes32 symbolId, int256 tradeVolume, int256 liquidity, int256 priceLimit)
    external returns (SettlementOnTrade memory ss);

    function settleSymbolsOnLiquidate(uint256 pTokenId, int256 liquidity)
    external returns (SettlementOnLiquidate memory ss);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import '../utils/Admin.sol';

abstract contract SymbolManagerStorage is Admin {

    // admin will be truned in to Timelock after deployment

    event NewImplementation(address newImplementation);

    address public implementation;

    // symbolId => symbol
    mapping (bytes32 => address) public symbols;

    // indexed symbols for looping
    address[] public indexedSymbols;

    // pTokenId => active symbols array for specific pTokenId (with position)
    mapping (uint256 => address[]) public activeSymbols;

    // total initial margin required for all symbols
    int256 public initialMarginRequired;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import './INameVersion.sol';

/**
 * @dev Convenience contract for name and version information
 */
abstract contract NameVersion is INameVersion {

    bytes32 public immutable nameId;
    bytes32 public immutable versionId;

    constructor (string memory name, string memory version) {
        nameId = keccak256(abi.encodePacked(name));
        versionId = keccak256(abi.encodePacked(version));
    }

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

interface INameVersion {

    function nameId() external view returns (bytes32);

    function versionId() external view returns (bytes32);

}