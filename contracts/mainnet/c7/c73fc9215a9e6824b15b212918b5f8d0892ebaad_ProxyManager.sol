// SPDX-License-Identifier: BUSL-1.1
// For further clarification please see https://license.premia.legal

pragma solidity ^0.8.0;

import {OwnableInternal} from "@solidstate/contracts/access/OwnableInternal.sol";

import {IProxyManager} from "./IProxyManager.sol";
import {ProxyManagerStorage} from "./ProxyManagerStorage.sol";
import {PoolProxy} from "../pool/PoolProxy.sol";
import {OptionMath} from "../libraries/OptionMath.sol";
import {IPoolView} from "../pool/IPoolView.sol";
import {IPremiaMining} from "../mining/IPremiaMining.sol";

/**
 * @title Options pair management contract
 * @dev deployed standalone and connected to Premia as diamond facet
 */
contract ProxyManager is IProxyManager, OwnableInternal {
    using ProxyManagerStorage for ProxyManagerStorage.Layout;

    address private immutable DIAMOND;

    // 64x64 fixed point representation of 1e
    int128 private constant INITIAL_C_LEVEL_64x64 = 0x2b7e151628aed2a6b;
    // 64x64 fixed point representation of 0.5
    int128 private constant INITIAL_STEEPNESS_64x64 = 0x8000000000000000;

    event DeployPool(
        address indexed base,
        address indexed underlying,
        int128 indexed initialCLevel64x64,
        address baseOracle,
        address underlyingOracle,
        address pool
    );

    constructor(address diamond) {
        DIAMOND = diamond;
    }

    /**
     * @notice get address of Pool contract for given assets
     * @param base base token
     * @param underlying underlying token
     * @return pool address (zero address if pool does not exist)
     */
    function getPool(address base, address underlying)
        external
        view
        returns (address)
    {
        return ProxyManagerStorage.layout().getPool(base, underlying);
    }

    /**
     * @notice get address list of all Pool contracts
     * @return list of pool addresses
     */
    function getPoolList() external view returns (address[] memory) {
        return ProxyManagerStorage.layout().poolList;
    }

    /**
     * @notice deploy PoolProxy contracts for the pair
     * @param base base token
     * @param underlying underlying token
     * @param baseOracle Chainlink price aggregator for base
     * @param underlyingOracle Chainlink price aggregator for underlying
     * @param baseMinimum64x64 64x64 fixed point representation of minimum base currency amount
     * @param underlyingMinimum64x64 64x64 fixed point representation of minimum underlying currency amount
     * @param basePoolCap64x64 64x64 fixed point representation of pool-wide base currency deposit cap
     * @param underlyingPoolCap64x64 64x64 fixed point representation of pool-wide underlying currency deposit cap
     * @param miningAllocPoints alloc points attributed per pool (call and put) for liquidity mining
     * @return deployment address
     */
    function deployPool(
        address base,
        address underlying,
        address baseOracle,
        address underlyingOracle,
        int128 baseMinimum64x64,
        int128 underlyingMinimum64x64,
        int128 basePoolCap64x64,
        int128 underlyingPoolCap64x64,
        uint256 miningAllocPoints
    ) external onlyOwner returns (address) {
        ProxyManagerStorage.Layout storage l = ProxyManagerStorage.layout();

        require(
            l.getPool(base, underlying) == address(0),
            "ProxyManager: Pool already exists"
        );

        address pool = address(
            new PoolProxy(
                DIAMOND,
                base,
                underlying,
                baseOracle,
                underlyingOracle,
                baseMinimum64x64,
                underlyingMinimum64x64,
                basePoolCap64x64,
                underlyingPoolCap64x64,
                INITIAL_C_LEVEL_64x64,
                INITIAL_STEEPNESS_64x64
            )
        );
        l.setPool(base, underlying, underlyingOracle);

        l.poolList.push(pool);

        IPremiaMining(IPoolView(DIAMOND).getPremiaMining()).addPool(
            pool,
            miningAllocPoints
        );

        emit DeployPool(
            base,
            underlying,
            INITIAL_C_LEVEL_64x64,
            baseOracle,
            underlyingOracle,
            pool
        );

        return pool;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { OwnableStorage } from './OwnableStorage.sol';

abstract contract OwnableInternal {
    using OwnableStorage for OwnableStorage.Layout;

    modifier onlyOwner() {
        require(
            msg.sender == OwnableStorage.layout().owner,
            'Ownable: sender must be owner'
        );
        _;
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.0;

interface IProxyManager {
    function getPoolList() external view returns (address[] memory);
}

// SPDX-License-Identifier: BUSL-1.1
// For further clarification please see https://license.premia.legal

pragma solidity ^0.8.0;

library ProxyManagerStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256("premia.contracts.storage.ProxyManager");

    struct Layout {
        // base => underlying => Pool
        mapping(address => mapping(address => address)) pools;
        address[] poolList;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function getPool(
        Layout storage l,
        address base,
        address underlying
    ) internal view returns (address) {
        return l.pools[base][underlying];
    }

    function setPool(
        Layout storage l,
        address base,
        address underlying,
        address pool
    ) internal {
        l.pools[base][underlying] = pool;
    }
}

// SPDX-License-Identifier: BUSL-1.1
// For further clarification please see https://license.premia.legal

pragma solidity ^0.8.0;

import {OwnableStorage} from "@solidstate/contracts/access/OwnableStorage.sol";
import {ERC165Storage} from "@solidstate/contracts/introspection/ERC165Storage.sol";
import {Proxy} from "@solidstate/contracts/proxy/Proxy.sol";
import {IDiamondLoupe} from "@solidstate/contracts/proxy/diamond/IDiamondLoupe.sol";
import {IERC20Metadata} from "@solidstate/contracts/token/ERC20/metadata/IERC20Metadata.sol";
import {IERC1155} from "@solidstate/contracts/token/ERC1155/IERC1155.sol";
import {IERC165} from "@solidstate/contracts/introspection/IERC165.sol";

import {IProxyManager} from "../core/IProxyManager.sol";
import {PoolStorage} from "./PoolStorage.sol";
import {ABDKMath64x64Token} from "../libraries/ABDKMath64x64Token.sol";

/**
 * @title Upgradeable proxy with centrally controlled Pool implementation
 */
contract PoolProxy is Proxy {
    using PoolStorage for PoolStorage.Layout;
    using ERC165Storage for ERC165Storage.Layout;

    address private immutable DIAMOND;

    constructor(
        address diamond,
        address base,
        address underlying,
        address baseOracle,
        address underlyingOracle,
        int128 baseMinimum64x64,
        int128 underlyingMinimum64x64,
        int128 basePoolCap64x64,
        int128 underlyingPoolCap64x64,
        int128 initialCLevel64x64,
        int128 initialSteepness64x64
    ) {
        DIAMOND = diamond;
        OwnableStorage.layout().owner = msg.sender;

        {
            PoolStorage.Layout storage l = PoolStorage.layout();

            l.base = base;
            l.underlying = underlying;

            l.setOracles(baseOracle, underlyingOracle);

            uint8 baseDecimals = IERC20Metadata(base).decimals();
            uint8 underlyingDecimals = IERC20Metadata(underlying).decimals();

            l.baseDecimals = baseDecimals;
            l.underlyingDecimals = underlyingDecimals;

            l.baseMinimum = ABDKMath64x64Token.toDecimals(
                baseMinimum64x64,
                baseDecimals
            );

            l.underlyingMinimum = ABDKMath64x64Token.toDecimals(
                underlyingMinimum64x64,
                underlyingDecimals
            );

            l.basePoolCap = ABDKMath64x64Token.toDecimals(
                basePoolCap64x64,
                baseDecimals
            );

            l.underlyingPoolCap = ABDKMath64x64Token.toDecimals(
                underlyingPoolCap64x64,
                underlyingDecimals
            );

            l.steepnessBase64x64 = initialSteepness64x64;
            l.steepnessUnderlying64x64 = initialSteepness64x64;
            l.cLevelBase64x64 = initialCLevel64x64;
            l.cLevelUnderlying64x64 = initialCLevel64x64;

            int128 newPrice64x64 = l.fetchPriceUpdate();
            l.setPriceUpdate(block.timestamp, newPrice64x64);

            l.updatedAt = block.timestamp;
            l.cLevelBaseUpdatedAt = block.timestamp;
            l.cLevelUnderlyingUpdatedAt = block.timestamp;
        }

        {
            ERC165Storage.Layout storage l = ERC165Storage.layout();
            l.setSupportedInterface(type(IERC165).interfaceId, true);
            l.setSupportedInterface(type(IERC1155).interfaceId, true);
        }
    }

    function _getImplementation() internal view override returns (address) {
        return IDiamondLoupe(DIAMOND).facetAddress(msg.sig);
    }
}

// SPDX-License-Identifier: BUSL-1.1
// For further clarification please see https://license.premia.legal

pragma solidity ^0.8.0;

import {ABDKMath64x64} from "abdk-libraries-solidity/ABDKMath64x64.sol";

library OptionMath {
    using ABDKMath64x64 for int128;

    struct QuoteArgs {
        int128 varianceAnnualized64x64; // 64x64 fixed point representation of annualized variance
        int128 strike64x64; // 64x64 fixed point representation of strike price
        int128 spot64x64; // 64x64 fixed point representation of spot price
        int128 timeToMaturity64x64; // 64x64 fixed point representation of duration of option contract (in years)
        int128 oldCLevel64x64; // 64x64 fixed point representation of C-Level of Pool before purchase
        int128 oldPoolState; // 64x64 fixed point representation of current state of the pool
        int128 newPoolState; // 64x64 fixed point representation of state of the pool after trade
        int128 steepness64x64; // 64x64 fixed point representation of Pool state delta multiplier
        int128 minAPY64x64; // 64x64 fixed point representation of minimum APY for capital locked up to underwrite options
        bool isCall; // whether to price "call" or "put" option
    }

    struct CalculateCLevelDecayArgs {
        int128 timeIntervalsElapsed64x64; // 64x64 fixed point representation of quantity of discrete arbitrary intervals elapsed since last update
        int128 oldCLevel64x64; // 64x64 fixed point representation of C-Level prior to accounting for decay
        int128 utilization64x64; // 64x64 fixed point representation of pool capital utilization rate
        int128 utilizationLowerBound64x64;
        int128 utilizationUpperBound64x64;
        int128 cLevelLowerBound64x64;
        int128 cLevelUpperBound64x64;
        int128 cConvergenceULowerBound64x64;
        int128 cConvergenceUUpperBound64x64;
    }

    // 64x64 fixed point integer constants
    int128 internal constant ONE_64x64 = 0x10000000000000000;
    int128 internal constant THREE_64x64 = 0x30000000000000000;

    // 64x64 fixed point constants used in Choudhury’s approximation of the Black-Scholes CDF
    int128 private constant CDF_CONST_0 = 0x09109f285df452394; // 2260 / 3989
    int128 private constant CDF_CONST_1 = 0x19abac0ea1da65036; // 6400 / 3989
    int128 private constant CDF_CONST_2 = 0x0d3c84b78b749bd6b; // 3300 / 3989

    /**
     * @notice recalculate C-Level based on change in liquidity
     * @param initialCLevel64x64 64x64 fixed point representation of C-Level of Pool before update
     * @param oldPoolState64x64 64x64 fixed point representation of liquidity in pool before update
     * @param newPoolState64x64 64x64 fixed point representation of liquidity in pool after update
     * @param steepness64x64 64x64 fixed point representation of steepness coefficient
     * @return 64x64 fixed point representation of new C-Level
     */
    function calculateCLevel(
        int128 initialCLevel64x64,
        int128 oldPoolState64x64,
        int128 newPoolState64x64,
        int128 steepness64x64
    ) external pure returns (int128) {
        return
            newPoolState64x64
                .sub(oldPoolState64x64)
                .div(
                    oldPoolState64x64 > newPoolState64x64
                        ? oldPoolState64x64
                        : newPoolState64x64
                )
                .mul(steepness64x64)
                .neg()
                .exp()
                .mul(initialCLevel64x64);
    }

    /**
     * @notice calculate the price of an option using the Premia Finance model
     * @param args arguments of quotePrice
     * @return premiaPrice64x64 64x64 fixed point representation of Premia option price
     * @return cLevel64x64 64x64 fixed point representation of C-Level of Pool after purchase
     */
    function quotePrice(QuoteArgs memory args)
        external
        pure
        returns (
            int128 premiaPrice64x64,
            int128 cLevel64x64,
            int128 slippageCoefficient64x64
        )
    {
        int128 deltaPoolState64x64 = args
            .newPoolState
            .sub(args.oldPoolState)
            .div(args.oldPoolState)
            .mul(args.steepness64x64);
        int128 tradingDelta64x64 = deltaPoolState64x64.neg().exp();

        int128 blackScholesPrice64x64 = _blackScholesPrice(
            args.varianceAnnualized64x64,
            args.strike64x64,
            args.spot64x64,
            args.timeToMaturity64x64,
            args.isCall
        );

        cLevel64x64 = tradingDelta64x64.mul(args.oldCLevel64x64);
        slippageCoefficient64x64 = ONE_64x64.sub(tradingDelta64x64).div(
            deltaPoolState64x64
        );

        premiaPrice64x64 = blackScholesPrice64x64.mul(cLevel64x64).mul(
            slippageCoefficient64x64
        );

        int128 intrinsicValue64x64;

        if (args.isCall && args.strike64x64 < args.spot64x64) {
            intrinsicValue64x64 = args.spot64x64.sub(args.strike64x64);
        } else if (!args.isCall && args.strike64x64 > args.spot64x64) {
            intrinsicValue64x64 = args.strike64x64.sub(args.spot64x64);
        }

        int128 collateralValue64x64 = args.isCall
            ? args.spot64x64
            : args.strike64x64;

        int128 minPrice64x64 = intrinsicValue64x64.add(
            collateralValue64x64.mul(args.minAPY64x64).mul(
                args.timeToMaturity64x64
            )
        );

        if (minPrice64x64 > premiaPrice64x64) {
            premiaPrice64x64 = minPrice64x64;
        }
    }

    /**
     * @notice calculate the decay of C-Level based on heat diffusion function
     * @param args structured CalculateCLevelDecayArgs
     * @return cLevelDecayed64x64 C-Level after accounting for decay
     */
    function calculateCLevelDecay(CalculateCLevelDecayArgs memory args)
        external
        pure
        returns (int128 cLevelDecayed64x64)
    {
        int128 convFHighU64x64 = (args.utilization64x64 >=
            args.utilizationUpperBound64x64 &&
            args.oldCLevel64x64 <= args.cLevelLowerBound64x64)
            ? ONE_64x64
            : int128(0);

        int128 convFLowU64x64 = (args.utilization64x64 <=
            args.utilizationLowerBound64x64 &&
            args.oldCLevel64x64 >= args.cLevelUpperBound64x64)
            ? ONE_64x64
            : int128(0);

        cLevelDecayed64x64 = args
            .oldCLevel64x64
            .sub(args.cConvergenceULowerBound64x64.mul(convFLowU64x64))
            .sub(args.cConvergenceUUpperBound64x64.mul(convFHighU64x64))
            .mul(
                convFLowU64x64
                    .mul(ONE_64x64.sub(args.utilization64x64))
                    .add(convFHighU64x64.mul(args.utilization64x64))
                    .mul(args.timeIntervalsElapsed64x64)
                    .neg()
                    .exp()
            )
            .add(
                args.cConvergenceULowerBound64x64.mul(convFLowU64x64).add(
                    args.cConvergenceUUpperBound64x64.mul(convFHighU64x64)
                )
            );
    }

    /**
     * @notice calculate the exponential decay coefficient for a given interval
     * @param oldTimestamp timestamp of previous update
     * @param newTimestamp current timestamp
     * @return 64x64 fixed point representation of exponential decay coefficient
     */
    function _decay(uint256 oldTimestamp, uint256 newTimestamp)
        internal
        pure
        returns (int128)
    {
        return
            ONE_64x64.sub(
                (-ABDKMath64x64.divu(newTimestamp - oldTimestamp, 7 days)).exp()
            );
    }

    /**
     * @notice calculate Choudhury’s approximation of the Black-Scholes CDF
     * @param input64x64 64x64 fixed point representation of random variable
     * @return 64x64 fixed point representation of the approximated CDF of x
     */
    function _N(int128 input64x64) internal pure returns (int128) {
        // squaring via mul is cheaper than via pow
        int128 inputSquared64x64 = input64x64.mul(input64x64);

        int128 value64x64 = (-inputSquared64x64 >> 1).exp().div(
            CDF_CONST_0.add(CDF_CONST_1.mul(input64x64.abs())).add(
                CDF_CONST_2.mul(inputSquared64x64.add(THREE_64x64).sqrt())
            )
        );

        return input64x64 > 0 ? ONE_64x64.sub(value64x64) : value64x64;
    }

    /**
     * @notice calculate the price of an option using the Black-Scholes model
     * @param varianceAnnualized64x64 64x64 fixed point representation of annualized variance
     * @param strike64x64 64x64 fixed point representation of strike price
     * @param spot64x64 64x64 fixed point representation of spot price
     * @param timeToMaturity64x64 64x64 fixed point representation of duration of option contract (in years)
     * @param isCall whether to price "call" or "put" option
     * @return 64x64 fixed point representation of Black-Scholes option price
     */
    function _blackScholesPrice(
        int128 varianceAnnualized64x64,
        int128 strike64x64,
        int128 spot64x64,
        int128 timeToMaturity64x64,
        bool isCall
    ) internal pure returns (int128) {
        int128 cumulativeVariance64x64 = timeToMaturity64x64.mul(
            varianceAnnualized64x64
        );
        int128 cumulativeVarianceSqrt64x64 = cumulativeVariance64x64.sqrt();

        int128 d1_64x64 = spot64x64
            .div(strike64x64)
            .ln()
            .add(cumulativeVariance64x64 >> 1)
            .div(cumulativeVarianceSqrt64x64);
        int128 d2_64x64 = d1_64x64.sub(cumulativeVarianceSqrt64x64);

        if (isCall) {
            return
                spot64x64.mul(_N(d1_64x64)).sub(strike64x64.mul(_N(d2_64x64)));
        } else {
            return
                -spot64x64.mul(_N(-d1_64x64)).sub(
                    strike64x64.mul(_N(-d2_64x64))
                );
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.0;

import {IERC1155Metadata} from "@solidstate/contracts/token/ERC1155/metadata/IERC1155Metadata.sol";

import {PoolStorage} from "./PoolStorage.sol";

/**
 * @notice Pool view function interface
 */
interface IPoolView is IERC1155Metadata {
    /**
     * @notice get fee receiver address
     * @dev called by PremiaMakerKeeper
     * @return fee receiver address
     */
    function getFeeReceiverAddress() external view returns (address);

    /**
     * @notice get fundamental pool attributes
     * @return structured PoolSettings
     */
    function getPoolSettings()
        external
        view
        returns (PoolStorage.PoolSettings memory);

    /**
     * @notice get the list of all token ids in circulation
     * @return list of token ids
     */
    function getTokenIds() external view returns (uint256[] memory);

    /**
     * @notice get current C-Level, accounting for unrealized decay and pending deposits
     * @param isCall whether query is for call or put pool
     * @return cLevel64x64 64x64 fixed point representation of C-Level
     */
    function getCLevel64x64(bool isCall) external view returns (int128);

    /**
     * @notice get steepness coefficient
     * @param isCall whether query is for call or put pool
     * @return 64x64 fixed point representation of C steepness of Pool
     */
    function getSteepness64x64(bool isCall) external view returns (int128);

    /**
     * @notice get oracle price at timestamp
     * @param timestamp timestamp to query
     * @return 64x64 fixed point representation of price
     */
    function getPrice(uint256 timestamp) external view returns (int128);

    /**
     * @notice get parameters for token id
     * @param tokenId token id to query
     * @return token type enum
     * @return maturity
     * @return 64x64 fixed point representation of strike price
     */
    function getParametersForTokenId(uint256 tokenId)
        external
        pure
        returns (
            PoolStorage.TokenType,
            uint64,
            int128
        );

    /**
     * @notice get minimum purchase and interval amounts
     * @return minCallTokenAmount minimum call pool amount
     * @return minPutTokenAmount minimum put pool amount
     */
    function getMinimumAmounts()
        external
        view
        returns (uint256 minCallTokenAmount, uint256 minPutTokenAmount);

    /**
     * @notice get deposit cap amounts
     * @return callTokenCapAmount call pool deposit cap
     * @return putTokenCapAmount put pool deposit cap
     */
    function getCapAmounts()
        external
        view
        returns (uint256 callTokenCapAmount, uint256 putTokenCapAmount);

    /**
     * @notice get TVL (total value locked) for given address
     * @param account address whose TVL to query
     * @return underlyingTVL user total value locked in call pool (in underlying token amount)
     * @return baseTVL user total value locked in put pool (in base token amount)
     */
    function getUserTVL(address account)
        external
        view
        returns (uint256 underlyingTVL, uint256 baseTVL);

    /**
     * @notice get TVL (total value locked) of entire Pool
     * @return underlyingTVL total value locked in call pool (in underlying token amount)
     * @return baseTVL total value locked in put pool (in base token amount)
     */
    function getTotalTVL()
        external
        view
        returns (uint256 underlyingTVL, uint256 baseTVL);

    /**
     * @notice get position in the liquidity queue of the Pool
     * @param account account address whose liquidity position to query
     * @param isCallPool whether query is for call or put pool
     * @return liquidityBeforePosition total available liquidity before account's liquidity queue
     * @return positionSize size of the account's liquidity queue position
     */
    function getLiquidityQueuePosition(address account, bool isCallPool)
        external
        view
        returns (uint256 liquidityBeforePosition, uint256 positionSize);

    /**
     * @notice get the address of PremiaMining contract
     * @return address of PremiaMining contract
     */
    function getPremiaMining() external view returns (address);

    /**
     * @notice get the gradual divestment timestamps of a user
     * @param account address whose divestment timestamps to query
     * @return callDivestmentTimestamp gradual divestment timestamp of the user for the call pool
     * @return putDivestmentTimestamp gradual divestment timestamp of the user for the put pool
     */
    function getDivestmentTimestamps(address account)
        external
        view
        returns (
            uint256 callDivestmentTimestamp,
            uint256 putDivestmentTimestamp
        );
}

// SPDX-License-Identifier: LGPL-3.0-or-later

pragma solidity ^0.8.0;

import {PremiaMiningStorage} from "./PremiaMiningStorage.sol";

interface IPremiaMining {
    function addPremiaRewards(uint256 _amount) external;

    function premiaRewardsAvailable() external view returns (uint256);

    function getTotalAllocationPoints() external view returns (uint256);

    function getPoolInfo(address pool, bool isCallPool)
        external
        view
        returns (PremiaMiningStorage.PoolInfo memory);

    function getPremiaPerYear() external view returns (uint256);

    function addPool(address _pool, uint256 _allocPoints) external;

    function setPoolAllocPoints(
        address[] memory _pools,
        uint256[] memory _allocPoints
    ) external;

    function pendingPremia(
        address _pool,
        bool _isCallPool,
        address _user
    ) external view returns (uint256);

    function updatePool(
        address _pool,
        bool _isCallPool,
        uint256 _totalTVL
    ) external;

    function allocatePending(
        address _user,
        address _pool,
        bool _isCallPool,
        uint256 _userTVLOld,
        uint256 _userTVLNew,
        uint256 _totalTVL
    ) external;

    function claim(
        address _user,
        address _pool,
        bool _isCallPool,
        uint256 _userTVLOld,
        uint256 _userTVLNew,
        uint256 _totalTVL
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library OwnableStorage {
    struct Layout {
        address owner;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.Ownable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function setOwner(Layout storage l, address owner) internal {
        l.owner = owner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ERC165Storage {
    struct Layout {
        mapping(bytes4 => bool) supportedInterfaces;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC165');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function isSupportedInterface(Layout storage l, bytes4 interfaceId)
        internal
        view
        returns (bool)
    {
        return l.supportedInterfaces[interfaceId];
    }

    function setSupportedInterface(
        Layout storage l,
        bytes4 interfaceId,
        bool status
    ) internal {
        require(interfaceId != 0xffffffff, 'ERC165: invalid interface id');
        l.supportedInterfaces[interfaceId] = status;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { AddressUtils } from '../utils/AddressUtils.sol';

/**
 * @title Base proxy contract
 */
abstract contract Proxy {
    using AddressUtils for address;

    /**
     * @notice delegate all calls to implementation contract
     * @dev reverts if implementation address contains no code, for compatibility with metamorphic contracts
     * @dev memory location in use by assembly may be unsafe in other contexts
     */
    fallback() external payable virtual {
        address implementation = _getImplementation();

        require(
            implementation.isContract(),
            'Proxy: implementation must be contract'
        );

        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @notice get logic implementation address
     * @return implementation address
     */
    function _getImplementation() internal virtual returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Diamond proxy introspection interface
 * @dev see https://eips.ethereum.org/EIPS/eip-2535
 */
interface IDiamondLoupe {
    struct Facet {
        address target;
        bytes4[] selectors;
    }

    /**
     * @notice get all facets and their selectors
     * @return diamondFacets array of structured facet data
     */
    function facets() external view returns (Facet[] memory diamondFacets);

    /**
     * @notice get all selectors for given facet address
     * @param facet address of facet to query
     * @return selectors array of function selectors
     */
    function facetFunctionSelectors(address facet)
        external
        view
        returns (bytes4[] memory selectors);

    /**
     * @notice get addresses of all facets used by diamond
     * @return addresses array of facet addresses
     */
    function facetAddresses()
        external
        view
        returns (address[] memory addresses);

    /**
     * @notice get the address of the facet associated with given selector
     * @param selector function selector to query
     * @return facet facet address (zero address if not found)
     */
    function facetAddress(bytes4 selector)
        external
        view
        returns (address facet);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC20 metadata interface
 */
interface IERC20Metadata {
    /**
     * @notice return token name
     * @return token name
     */
    function name() external view returns (string memory);

    /**
     * @notice return token symbol
     * @return token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @notice return token decimals, generally used only for display purposes
     * @return token decimals
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC1155Internal } from './IERC1155Internal.sol';
import { IERC165 } from '../../introspection/IERC165.sol';

/**
 * @notice ERC1155 interface
 * @dev see https://github.com/ethereum/EIPs/issues/1155
 */
interface IERC1155 is IERC1155Internal, IERC165 {
    /**
     * @notice query the balance of given token held by given address
     * @param account address to query
     * @param id token to query
     * @return token balance
     */
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    /**
     * @notice query the balances of given tokens held by given addresses
     * @param accounts addresss to query
     * @param ids tokens to query
     * @return token balances
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @notice query approval status of given operator with respect to given address
     * @param account address to query for approval granted
     * @param operator address to query for approval received
     * @return whether operator is approved to spend tokens held by account
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool);

    /**
     * @notice grant approval to or revoke approval from given operator to spend held tokens
     * @param operator address whose approval status to update
     * @param status whether operator should be considered approved
     */
    function setApprovalForAll(address operator, bool status) external;

    /**
     * @notice transfer tokens between given addresses, checking for ERC1155Receiver implementation if applicable
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param id token ID
     * @param amount quantity of tokens to transfer
     * @param data data payload
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @notice transfer batch of tokens between given addresses, checking for ERC1155Receiver implementation if applicable
     * @param from sender of tokens
     * @param to receiver of tokens
     * @param ids list of token IDs
     * @param amounts list of quantities of tokens to transfer
     * @param data data payload
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC165 interface registration interface
 * @dev see https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 {
    /**
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return bool whether interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
// For further clarification please see https://license.premia.legal

pragma solidity ^0.8.0;

import {AggregatorInterface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {EnumerableSet, ERC1155EnumerableStorage} from "@solidstate/contracts/token/ERC1155/enumerable/ERC1155EnumerableStorage.sol";

import {ABDKMath64x64} from "abdk-libraries-solidity/ABDKMath64x64.sol";
import {ABDKMath64x64Token} from "../libraries/ABDKMath64x64Token.sol";
import {OptionMath} from "../libraries/OptionMath.sol";

library PoolStorage {
    using ABDKMath64x64 for int128;
    using PoolStorage for PoolStorage.Layout;

    enum TokenType {
        UNDERLYING_FREE_LIQ,
        BASE_FREE_LIQ,
        UNDERLYING_RESERVED_LIQ,
        BASE_RESERVED_LIQ,
        LONG_CALL,
        SHORT_CALL,
        LONG_PUT,
        SHORT_PUT
    }

    struct PoolSettings {
        address underlying;
        address base;
        address underlyingOracle;
        address baseOracle;
    }

    struct QuoteArgsInternal {
        address feePayer; // address of the fee payer
        uint64 maturity; // timestamp of option maturity
        int128 strike64x64; // 64x64 fixed point representation of strike price
        int128 spot64x64; // 64x64 fixed point representation of spot price
        uint256 contractSize; // size of option contract
        bool isCall; // true for call, false for put
    }

    struct QuoteResultInternal {
        int128 baseCost64x64; // 64x64 fixed point representation of option cost denominated in underlying currency (without fee)
        int128 feeCost64x64; // 64x64 fixed point representation of option fee cost denominated in underlying currency for call, or base currency for put
        int128 cLevel64x64; // 64x64 fixed point representation of C-Level of Pool after purchase
        int128 slippageCoefficient64x64; // 64x64 fixed point representation of slippage coefficient for given order size
    }

    struct BatchData {
        uint256 eta;
        uint256 totalPendingDeposits;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("premia.contracts.storage.Pool");

    uint256 private constant C_DECAY_BUFFER = 12 hours;
    uint256 private constant C_DECAY_INTERVAL = 4 hours;

    struct Layout {
        // ERC20 token addresses
        address base;
        address underlying;
        // AggregatorV3Interface oracle addresses
        address baseOracle;
        address underlyingOracle;
        // token metadata
        uint8 underlyingDecimals;
        uint8 baseDecimals;
        // minimum amounts
        uint256 baseMinimum;
        uint256 underlyingMinimum;
        // deposit caps
        uint256 basePoolCap;
        uint256 underlyingPoolCap;
        // market state
        int128 _deprecated_steepness64x64;
        int128 cLevelBase64x64;
        int128 cLevelUnderlying64x64;
        uint256 cLevelBaseUpdatedAt;
        uint256 cLevelUnderlyingUpdatedAt;
        uint256 updatedAt;
        // User -> isCall -> depositedAt
        mapping(address => mapping(bool => uint256)) depositedAt;
        mapping(address => mapping(bool => uint256)) divestmentTimestamps;
        // doubly linked list of free liquidity intervals
        // isCall -> User -> User
        mapping(bool => mapping(address => address)) liquidityQueueAscending;
        mapping(bool => mapping(address => address)) liquidityQueueDescending;
        // minimum resolution price bucket => price
        mapping(uint256 => int128) bucketPrices64x64;
        // sequence id (minimum resolution price bucket / 256) => price update sequence
        mapping(uint256 => uint256) priceUpdateSequences;
        // isCall -> batch data
        mapping(bool => BatchData) nextDeposits;
        // user -> batch timestamp -> isCall -> pending amount
        mapping(address => mapping(uint256 => mapping(bool => uint256))) pendingDeposits;
        EnumerableSet.UintSet tokenIds;
        // user -> isCallPool -> total value locked of user (Used for liquidity mining)
        mapping(address => mapping(bool => uint256)) userTVL;
        // isCallPool -> total value locked
        mapping(bool => uint256) totalTVL;
        // steepness values
        int128 steepnessBase64x64;
        int128 steepnessUnderlying64x64;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /**
     * @notice calculate ERC1155 token id for given option parameters
     * @param tokenType TokenType enum
     * @param maturity timestamp of option maturity
     * @param strike64x64 64x64 fixed point representation of strike price
     * @return tokenId token id
     */
    function formatTokenId(
        TokenType tokenType,
        uint64 maturity,
        int128 strike64x64
    ) internal pure returns (uint256 tokenId) {
        tokenId =
            (uint256(tokenType) << 248) +
            (uint256(maturity) << 128) +
            uint256(int256(strike64x64));
    }

    /**
     * @notice derive option maturity and strike price from ERC1155 token id
     * @param tokenId token id
     * @return tokenType TokenType enum
     * @return maturity timestamp of option maturity
     * @return strike64x64 option strike price
     */
    function parseTokenId(uint256 tokenId)
        internal
        pure
        returns (
            TokenType tokenType,
            uint64 maturity,
            int128 strike64x64
        )
    {
        assembly {
            tokenType := shr(248, tokenId)
            maturity := shr(128, tokenId)
            strike64x64 := tokenId
        }
    }

    function getTokenDecimals(Layout storage l, bool isCall)
        internal
        view
        returns (uint8 decimals)
    {
        decimals = isCall ? l.underlyingDecimals : l.baseDecimals;
    }

    /**
     * @notice get the total supply of free liquidity tokens, minus pending deposits
     * @param l storage layout struct
     * @param isCall whether query is for call or put pool
     * @return 64x64 fixed point representation of total free liquidity
     */
    function totalFreeLiquiditySupply64x64(Layout storage l, bool isCall)
        internal
        view
        returns (int128)
    {
        uint256 tokenId = formatTokenId(
            isCall ? TokenType.UNDERLYING_FREE_LIQ : TokenType.BASE_FREE_LIQ,
            0,
            0
        );

        return
            ABDKMath64x64Token.fromDecimals(
                ERC1155EnumerableStorage.layout().totalSupply[tokenId] -
                    l.nextDeposits[isCall].totalPendingDeposits,
                l.getTokenDecimals(isCall)
            );
    }

    function getReinvestmentStatus(
        Layout storage l,
        address account,
        bool isCallPool
    ) internal view returns (bool) {
        uint256 timestamp = l.divestmentTimestamps[account][isCallPool];
        return timestamp == 0 || timestamp > block.timestamp;
    }

    function addUnderwriter(
        Layout storage l,
        address account,
        bool isCallPool
    ) internal {
        require(account != address(0));

        mapping(address => address) storage asc = l.liquidityQueueAscending[
            isCallPool
        ];
        mapping(address => address) storage desc = l.liquidityQueueDescending[
            isCallPool
        ];

        if (_isInQueue(account, asc, desc)) return;

        address last = desc[address(0)];

        asc[last] = account;
        desc[account] = last;
        desc[address(0)] = account;
    }

    function removeUnderwriter(
        Layout storage l,
        address account,
        bool isCallPool
    ) internal {
        require(account != address(0));

        mapping(address => address) storage asc = l.liquidityQueueAscending[
            isCallPool
        ];
        mapping(address => address) storage desc = l.liquidityQueueDescending[
            isCallPool
        ];

        if (!_isInQueue(account, asc, desc)) return;

        address prev = desc[account];
        address next = asc[account];
        asc[prev] = next;
        desc[next] = prev;
        delete asc[account];
        delete desc[account];
    }

    function isInQueue(
        Layout storage l,
        address account,
        bool isCallPool
    ) internal view returns (bool) {
        mapping(address => address) storage asc = l.liquidityQueueAscending[
            isCallPool
        ];
        mapping(address => address) storage desc = l.liquidityQueueDescending[
            isCallPool
        ];

        return _isInQueue(account, asc, desc);
    }

    function _isInQueue(
        address account,
        mapping(address => address) storage asc,
        mapping(address => address) storage desc
    ) private view returns (bool) {
        return asc[account] != address(0) || desc[address(0)] == account;
    }

    /**
     * @notice get current C-Level, without accounting for pending adjustments
     * @param l storage layout struct
     * @param isCall whether query is for call or put pool
     * @return cLevel64x64 64x64 fixed point representation of C-Level
     */
    function getRawCLevel64x64(Layout storage l, bool isCall)
        internal
        view
        returns (int128 cLevel64x64)
    {
        cLevel64x64 = isCall ? l.cLevelUnderlying64x64 : l.cLevelBase64x64;
    }

    /**
     * @notice get current C-Level, accounting for unrealized decay
     * @param l storage layout struct
     * @param isCall whether query is for call or put pool
     * @return cLevel64x64 64x64 fixed point representation of C-Level
     */
    function getDecayAdjustedCLevel64x64(Layout storage l, bool isCall)
        internal
        view
        returns (int128 cLevel64x64)
    {
        // get raw C-Level from storage
        cLevel64x64 = l.getRawCLevel64x64(isCall);

        // account for C-Level decay
        cLevel64x64 = l.applyCLevelDecayAdjustment(cLevel64x64, isCall);
    }

    /**
     * @notice get updated C-Level and pool liquidity level, accounting for decay and pending deposits
     * @param l storage layout struct
     * @param isCall whether to update C-Level for call or put pool
     * @return cLevel64x64 64x64 fixed point representation of C-Level
     * @return liquidity64x64 64x64 fixed point representation of new liquidity amount
     */
    function getRealPoolState(Layout storage l, bool isCall)
        internal
        view
        returns (int128 cLevel64x64, int128 liquidity64x64)
    {
        PoolStorage.BatchData storage batchData = l.nextDeposits[isCall];

        int128 oldCLevel64x64 = l.getDecayAdjustedCLevel64x64(isCall);
        int128 oldLiquidity64x64 = l.totalFreeLiquiditySupply64x64(isCall);

        if (
            batchData.totalPendingDeposits > 0 &&
            batchData.eta != 0 &&
            block.timestamp >= batchData.eta
        ) {
            liquidity64x64 = ABDKMath64x64Token
                .fromDecimals(
                    batchData.totalPendingDeposits,
                    l.getTokenDecimals(isCall)
                )
                .add(oldLiquidity64x64);

            cLevel64x64 = l.applyCLevelLiquidityChangeAdjustment(
                oldCLevel64x64,
                oldLiquidity64x64,
                liquidity64x64,
                isCall
            );
        } else {
            cLevel64x64 = oldCLevel64x64;
            liquidity64x64 = oldLiquidity64x64;
        }
    }

    /**
     * @notice calculate updated C-Level, accounting for unrealized decay
     * @param l storage layout struct
     * @param oldCLevel64x64 64x64 fixed point representation pool C-Level before accounting for decay
     * @param isCall whether query is for call or put pool
     * @return cLevel64x64 64x64 fixed point representation of C-Level of Pool after accounting for decay
     */
    function applyCLevelDecayAdjustment(
        Layout storage l,
        int128 oldCLevel64x64,
        bool isCall
    ) internal view returns (int128 cLevel64x64) {
        uint256 timeElapsed = block.timestamp -
            (isCall ? l.cLevelUnderlyingUpdatedAt : l.cLevelBaseUpdatedAt);

        // do not apply C decay if less than 24 hours have elapsed

        if (timeElapsed > C_DECAY_BUFFER) {
            timeElapsed -= C_DECAY_BUFFER;
        } else {
            return oldCLevel64x64;
        }

        int128 timeIntervalsElapsed64x64 = ABDKMath64x64.divu(
            timeElapsed,
            C_DECAY_INTERVAL
        );

        uint256 tokenId = formatTokenId(
            isCall ? TokenType.UNDERLYING_FREE_LIQ : TokenType.BASE_FREE_LIQ,
            0,
            0
        );

        uint256 tvl = l.totalTVL[isCall];

        int128 utilization = ABDKMath64x64.divu(
            tvl -
                (ERC1155EnumerableStorage.layout().totalSupply[tokenId] -
                    l.nextDeposits[isCall].totalPendingDeposits),
            tvl
        );

        return
            OptionMath.calculateCLevelDecay(
                OptionMath.CalculateCLevelDecayArgs(
                    timeIntervalsElapsed64x64,
                    oldCLevel64x64,
                    utilization,
                    0xb333333333333333, // 0.7
                    0xe666666666666666, // 0.9
                    0x10000000000000000, // 1.0
                    0x10000000000000000, // 1.0
                    0xe666666666666666, // 0.9
                    0x56fc2a2c515da32ea // 2e
                )
            );
    }

    /**
     * @notice calculate updated C-Level, accounting for change in liquidity
     * @param l storage layout struct
     * @param oldCLevel64x64 64x64 fixed point representation pool C-Level before accounting for liquidity change
     * @param oldLiquidity64x64 64x64 fixed point representation of previous liquidity
     * @param newLiquidity64x64 64x64 fixed point representation of current liquidity
     * @param isCallPool whether to update C-Level for call or put pool
     * @return cLevel64x64 64x64 fixed point representation of C-Level
     */
    function applyCLevelLiquidityChangeAdjustment(
        Layout storage l,
        int128 oldCLevel64x64,
        int128 oldLiquidity64x64,
        int128 newLiquidity64x64,
        bool isCallPool
    ) internal view returns (int128 cLevel64x64) {
        int128 steepness64x64 = isCallPool
            ? l.steepnessUnderlying64x64
            : l.steepnessBase64x64;

        // fallback to deprecated storage value if side-specific value is not set
        if (steepness64x64 == 0) steepness64x64 = l._deprecated_steepness64x64;

        cLevel64x64 = OptionMath.calculateCLevel(
            oldCLevel64x64,
            oldLiquidity64x64,
            newLiquidity64x64,
            steepness64x64
        );

        if (cLevel64x64 < 0xb333333333333333) {
            cLevel64x64 = int128(0xb333333333333333); // 64x64 fixed point representation of 0.7
        }
    }

    /**
     * @notice set C-Level to arbitrary pre-calculated value
     * @param cLevel64x64 new C-Level of pool
     * @param isCallPool whether to update C-Level for call or put pool
     */
    function setCLevel(
        Layout storage l,
        int128 cLevel64x64,
        bool isCallPool
    ) internal {
        if (isCallPool) {
            l.cLevelUnderlying64x64 = cLevel64x64;
            l.cLevelUnderlyingUpdatedAt = block.timestamp;
        } else {
            l.cLevelBase64x64 = cLevel64x64;
            l.cLevelBaseUpdatedAt = block.timestamp;
        }
    }

    function setOracles(
        Layout storage l,
        address baseOracle,
        address underlyingOracle
    ) internal {
        require(
            AggregatorV3Interface(baseOracle).decimals() ==
                AggregatorV3Interface(underlyingOracle).decimals(),
            "Pool: oracle decimals must match"
        );

        l.baseOracle = baseOracle;
        l.underlyingOracle = underlyingOracle;
    }

    function fetchPriceUpdate(Layout storage l)
        internal
        view
        returns (int128 price64x64)
    {
        int256 priceUnderlying = AggregatorInterface(l.underlyingOracle)
            .latestAnswer();
        int256 priceBase = AggregatorInterface(l.baseOracle).latestAnswer();

        return ABDKMath64x64.divi(priceUnderlying, priceBase);
    }

    /**
     * @notice set price update for hourly bucket corresponding to given timestamp
     * @param l storage layout struct
     * @param timestamp timestamp to update
     * @param price64x64 64x64 fixed point representation of price
     */
    function setPriceUpdate(
        Layout storage l,
        uint256 timestamp,
        int128 price64x64
    ) internal {
        uint256 bucket = timestamp / (1 hours);
        l.bucketPrices64x64[bucket] = price64x64;
        l.priceUpdateSequences[bucket >> 8] += 1 << (255 - (bucket & 255));
    }

    /**
     * @notice get price update for hourly bucket corresponding to given timestamp
     * @param l storage layout struct
     * @param timestamp timestamp to query
     * @return 64x64 fixed point representation of price
     */
    function getPriceUpdate(Layout storage l, uint256 timestamp)
        internal
        view
        returns (int128)
    {
        return l.bucketPrices64x64[timestamp / (1 hours)];
    }

    /**
     * @notice get first price update available following given timestamp
     * @param l storage layout struct
     * @param timestamp timestamp to query
     * @return 64x64 fixed point representation of price
     */
    function getPriceUpdateAfter(Layout storage l, uint256 timestamp)
        internal
        view
        returns (int128)
    {
        // price updates are grouped into hourly buckets
        uint256 bucket = timestamp / (1 hours);
        // divide by 256 to get the index of the relevant price update sequence
        uint256 sequenceId = bucket >> 8;

        // get position within sequence relevant to current price update

        uint256 offset = bucket & 255;
        // shift to skip buckets from earlier in sequence
        uint256 sequence = (l.priceUpdateSequences[sequenceId] << offset) >>
            offset;

        // iterate through future sequences until a price update is found
        // sequence corresponding to current timestamp used as upper bound

        uint256 currentPriceUpdateSequenceId = block.timestamp / (256 hours);

        while (sequence == 0 && sequenceId <= currentPriceUpdateSequenceId) {
            sequence = l.priceUpdateSequences[++sequenceId];
        }

        // if no price update is found (sequence == 0) function will return 0
        // this should never occur, as each relevant external function triggers a price update

        // the most significant bit of the sequence corresponds to the offset of the relevant bucket

        uint256 msb;

        for (uint256 i = 128; i > 0; i >>= 1) {
            if (sequence >> i > 0) {
                msb += i;
                sequence >>= i;
            }
        }

        return l.bucketPrices64x64[((sequenceId + 1) << 8) - msb - 1];
    }

    function fromBaseToUnderlyingDecimals(Layout storage l, uint256 value)
        internal
        view
        returns (uint256)
    {
        int128 valueFixed64x64 = ABDKMath64x64Token.fromDecimals(
            value,
            l.baseDecimals
        );
        return
            ABDKMath64x64Token.toDecimals(
                valueFixed64x64,
                l.underlyingDecimals
            );
    }

    function fromUnderlyingToBaseDecimals(Layout storage l, uint256 value)
        internal
        view
        returns (uint256)
    {
        int128 valueFixed64x64 = ABDKMath64x64Token.fromDecimals(
            value,
            l.underlyingDecimals
        );
        return ABDKMath64x64Token.toDecimals(valueFixed64x64, l.baseDecimals);
    }
}

// SPDX-License-Identifier: BUSL-1.1
// For further clarification please see https://license.premia.legal

pragma solidity ^0.8.0;

import {ABDKMath64x64} from "abdk-libraries-solidity/ABDKMath64x64.sol";

library ABDKMath64x64Token {
    using ABDKMath64x64 for int128;

    /**
     * @notice convert 64x64 fixed point representation of token amount to decimal
     * @param value64x64 64x64 fixed point representation of token amount
     * @param decimals token display decimals
     * @return value decimal representation of token amount
     */
    function toDecimals(int128 value64x64, uint8 decimals)
        internal
        pure
        returns (uint256 value)
    {
        value = value64x64.mulu(10**decimals);
    }

    /**
     * @notice convert decimal representation of token amount to 64x64 fixed point
     * @param value decimal representation of token amount
     * @param decimals token display decimals
     * @return value64x64 64x64 fixed point representation of token amount
     */
    function fromDecimals(uint256 value, uint8 decimals)
        internal
        pure
        returns (int128 value64x64)
    {
        value64x64 = ABDKMath64x64.divu(value, 10**decimals);
    }

    /**
     * @notice convert 64x64 fixed point representation of token amount to wei (18 decimals)
     * @param value64x64 64x64 fixed point representation of token amount
     * @return value wei representation of token amount
     */
    function toWei(int128 value64x64) internal pure returns (uint256 value) {
        value = toDecimals(value64x64, 18);
    }

    /**
     * @notice convert wei representation (18 decimals) of token amount to 64x64 fixed point
     * @param value wei representation of token amount
     * @return value64x64 64x64 fixed point representation of token amount
     */
    function fromWei(uint256 value) internal pure returns (int128 value64x64) {
        value64x64 = fromDecimals(value, 18);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library AddressUtils {
    function toString(address account) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(account)));
        bytes memory alphabet = '0123456789abcdef';
        bytes memory chars = new bytes(42);

        chars[0] = '0';
        chars[1] = 'x';

        for (uint256 i = 0; i < 20; i++) {
            chars[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            chars[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }

        return string(chars);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        require(success, 'AddressUtils: failed to send value');
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            'AddressUtils: insufficient balance for call'
        );
        return _functionCallWithValue(target, data, value, error);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        require(
            isContract(target),
            'AddressUtils: function call to non-contract'
        );

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IERC165 } from '../../introspection/IERC165.sol';

/**
 * @notice Partial ERC1155 interface needed by internal functions
 */
interface IERC1155Internal {
    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(
        address indexed account,
        address indexed operator,
        bool approved
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorInterface {
  function latestAnswer() external view returns (int256);

  function latestTimestamp() external view returns (uint256);

  function latestRound() external view returns (uint256);

  function getAnswer(uint256 roundId) external view returns (int256);

  function getTimestamp(uint256 roundId) external view returns (uint256);

  event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 updatedAt);

  event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableSet } from '../../../utils/EnumerableSet.sol';

library ERC1155EnumerableStorage {
    struct Layout {
        mapping(uint256 => uint256) totalSupply;
        mapping(uint256 => EnumerableSet.AddressSet) accountsByToken;
        mapping(address => EnumerableSet.UintSet) tokensByAccount;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.ERC1155Enumerable');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.0;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
  /*
   * Minimum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

  /*
   * Maximum value signed 64.64-bit fixed point number may have. 
   */
  int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

  /**
   * Convert signed 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromInt (int256 x) internal pure returns (int128) {
    unchecked {
      require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (x << 64);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 64-bit integer number
   * rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
  function toInt (int128 x) internal pure returns (int64) {
    unchecked {
      return int64 (x >> 64);
    }
  }

  /**
   * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
   * number.  Revert on overflow.
   *
   * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function fromUInt (uint256 x) internal pure returns (int128) {
    unchecked {
      require (x <= 0x7FFFFFFFFFFFFFFF);
      return int128 (int256 (x << 64));
    }
  }

  /**
   * Convert signed 64.64 fixed point number into unsigned 64-bit integer
   * number rounding down.  Revert on underflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
  function toUInt (int128 x) internal pure returns (uint64) {
    unchecked {
      require (x >= 0);
      return uint64 (uint128 (x >> 64));
    }
  }

  /**
   * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
   * number rounding down.  Revert on overflow.
   *
   * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function from128x128 (int256 x) internal pure returns (int128) {
    unchecked {
      int256 result = x >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Convert signed 64.64 fixed point number into signed 128.128 fixed point
   * number.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
  function to128x128 (int128 x) internal pure returns (int256) {
    unchecked {
      return int256 (x) << 64;
    }
  }

  /**
   * Calculate x + y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function add (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) + y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x - y.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sub (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) - y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding down.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function mul (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 result = int256(x) * y >> 64;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
   * number and y is signed 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
  function muli (int128 x, int256 y) internal pure returns (int256) {
    unchecked {
      if (x == MIN_64x64) {
        require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
          y <= 0x1000000000000000000000000000000000000000000000000);
        return -y << 63;
      } else {
        bool negativeResult = false;
        if (x < 0) {
          x = -x;
          negativeResult = true;
        }
        if (y < 0) {
          y = -y; // We rely on overflow behavior here
          negativeResult = !negativeResult;
        }
        uint256 absoluteResult = mulu (x, uint256 (y));
        if (negativeResult) {
          require (absoluteResult <=
            0x8000000000000000000000000000000000000000000000000000000000000000);
          return -int256 (absoluteResult); // We rely on overflow behavior here
        } else {
          require (absoluteResult <=
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
          return int256 (absoluteResult);
        }
      }
    }
  }

  /**
   * Calculate x * y rounding down, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
  function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    unchecked {
      if (y == 0) return 0;

      require (x >= 0);

      uint256 lo = (uint256 (int256 (x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
      uint256 hi = uint256 (int256 (x)) * (y >> 128);

      require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      hi <<= 64;

      require (hi <=
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
      return hi + lo;
    }
  }

  /**
   * Calculate x / y rounding towards zero.  Revert on overflow or when y is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function div (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      int256 result = (int256 (x) << 64) / y;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are signed 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divi (int256 x, int256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);

      bool negativeResult = false;
      if (x < 0) {
        x = -x; // We rely on overflow behavior here
        negativeResult = true;
      }
      if (y < 0) {
        y = -y; // We rely on overflow behavior here
        negativeResult = !negativeResult;
      }
      uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
      if (negativeResult) {
        require (absoluteResult <= 0x80000000000000000000000000000000);
        return -int128 (absoluteResult); // We rely on overflow behavior here
      } else {
        require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return int128 (absoluteResult); // We rely on overflow behavior here
      }
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
  function divu (uint256 x, uint256 y) internal pure returns (int128) {
    unchecked {
      require (y != 0);
      uint128 result = divuu (x, y);
      require (result <= uint128 (MAX_64x64));
      return int128 (result);
    }
  }

  /**
   * Calculate -x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function neg (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return -x;
    }
  }

  /**
   * Calculate |x|.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function abs (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != MIN_64x64);
      return x < 0 ? -x : x;
    }
  }

  /**
   * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
   * zero.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function inv (int128 x) internal pure returns (int128) {
    unchecked {
      require (x != 0);
      int256 result = int256 (0x100000000000000000000000000000000) / x;
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function avg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      return int128 ((int256 (x) + int256 (y)) >> 1);
    }
  }

  /**
   * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
   * Revert on overflow or in case x * y is negative.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function gavg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
      int256 m = int256 (x) * int256 (y);
      require (m >= 0);
      require (m <
          0x4000000000000000000000000000000000000000000000000000000000000000);
      return int128 (sqrtu (uint256 (m)));
    }
  }

  /**
   * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
   * and y is unsigned 256-bit integer number.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
  function pow (int128 x, uint256 y) internal pure returns (int128) {
    unchecked {
      bool negative = x < 0 && y & 1 == 1;

      uint256 absX = uint128 (x < 0 ? -x : x);
      uint256 absResult;
      absResult = 0x100000000000000000000000000000000;

      if (absX <= 0x10000000000000000) {
        absX <<= 63;
        while (y != 0) {
          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x2 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x4 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          if (y & 0x8 != 0) {
            absResult = absResult * absX >> 127;
          }
          absX = absX * absX >> 127;

          y >>= 4;
        }

        absResult >>= 64;
      } else {
        uint256 absXShift = 63;
        if (absX < 0x1000000000000000000000000) { absX <<= 32; absXShift -= 32; }
        if (absX < 0x10000000000000000000000000000) { absX <<= 16; absXShift -= 16; }
        if (absX < 0x1000000000000000000000000000000) { absX <<= 8; absXShift -= 8; }
        if (absX < 0x10000000000000000000000000000000) { absX <<= 4; absXShift -= 4; }
        if (absX < 0x40000000000000000000000000000000) { absX <<= 2; absXShift -= 2; }
        if (absX < 0x80000000000000000000000000000000) { absX <<= 1; absXShift -= 1; }

        uint256 resultShift = 0;
        while (y != 0) {
          require (absXShift < 64);

          if (y & 0x1 != 0) {
            absResult = absResult * absX >> 127;
            resultShift += absXShift;
            if (absResult > 0x100000000000000000000000000000000) {
              absResult >>= 1;
              resultShift += 1;
            }
          }
          absX = absX * absX >> 127;
          absXShift <<= 1;
          if (absX >= 0x100000000000000000000000000000000) {
              absX >>= 1;
              absXShift += 1;
          }

          y >>= 1;
        }

        require (resultShift < 64);
        absResult >>= 64 - resultShift;
      }
      int256 result = negative ? -int256 (absResult) : int256 (absResult);
      require (result >= MIN_64x64 && result <= MAX_64x64);
      return int128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down.  Revert if x < 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function sqrt (int128 x) internal pure returns (int128) {
    unchecked {
      require (x >= 0);
      return int128 (sqrtu (uint256 (int256 (x)) << 64));
    }
  }

  /**
   * Calculate binary logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function log_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      int256 msb = 0;
      int256 xc = x;
      if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
      if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
      if (xc >= 0x10000) { xc >>= 16; msb += 16; }
      if (xc >= 0x100) { xc >>= 8; msb += 8; }
      if (xc >= 0x10) { xc >>= 4; msb += 4; }
      if (xc >= 0x4) { xc >>= 2; msb += 2; }
      if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

      int256 result = msb - 64 << 64;
      uint256 ux = uint256 (int256 (x)) << uint256 (127 - msb);
      for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
        ux *= ux;
        uint256 b = ux >> 255;
        ux >>= 127 + b;
        result += bit * int256 (b);
      }

      return int128 (result);
    }
  }

  /**
   * Calculate natural logarithm of x.  Revert if x <= 0.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function ln (int128 x) internal pure returns (int128) {
    unchecked {
      require (x > 0);

      return int128 (int256 (
          uint256 (int256 (log_2 (x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128));
    }
  }

  /**
   * Calculate binary exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp_2 (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      uint256 result = 0x80000000000000000000000000000000;

      if (x & 0x8000000000000000 > 0)
        result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
      if (x & 0x4000000000000000 > 0)
        result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
      if (x & 0x2000000000000000 > 0)
        result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
      if (x & 0x1000000000000000 > 0)
        result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
      if (x & 0x800000000000000 > 0)
        result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
      if (x & 0x400000000000000 > 0)
        result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
      if (x & 0x200000000000000 > 0)
        result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
      if (x & 0x100000000000000 > 0)
        result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
      if (x & 0x80000000000000 > 0)
        result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
      if (x & 0x40000000000000 > 0)
        result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
      if (x & 0x20000000000000 > 0)
        result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
      if (x & 0x10000000000000 > 0)
        result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
      if (x & 0x8000000000000 > 0)
        result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
      if (x & 0x4000000000000 > 0)
        result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
      if (x & 0x2000000000000 > 0)
        result = result * 0x1000162E525EE054754457D5995292026 >> 128;
      if (x & 0x1000000000000 > 0)
        result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
      if (x & 0x800000000000 > 0)
        result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
      if (x & 0x400000000000 > 0)
        result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
      if (x & 0x200000000000 > 0)
        result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
      if (x & 0x100000000000 > 0)
        result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
      if (x & 0x80000000000 > 0)
        result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
      if (x & 0x40000000000 > 0)
        result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
      if (x & 0x20000000000 > 0)
        result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
      if (x & 0x10000000000 > 0)
        result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
      if (x & 0x8000000000 > 0)
        result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
      if (x & 0x4000000000 > 0)
        result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
      if (x & 0x2000000000 > 0)
        result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
      if (x & 0x1000000000 > 0)
        result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
      if (x & 0x800000000 > 0)
        result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
      if (x & 0x400000000 > 0)
        result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
      if (x & 0x200000000 > 0)
        result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
      if (x & 0x100000000 > 0)
        result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
      if (x & 0x80000000 > 0)
        result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
      if (x & 0x40000000 > 0)
        result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
      if (x & 0x20000000 > 0)
        result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
      if (x & 0x10000000 > 0)
        result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
      if (x & 0x8000000 > 0)
        result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
      if (x & 0x4000000 > 0)
        result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
      if (x & 0x2000000 > 0)
        result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
      if (x & 0x1000000 > 0)
        result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
      if (x & 0x800000 > 0)
        result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
      if (x & 0x400000 > 0)
        result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
      if (x & 0x200000 > 0)
        result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
      if (x & 0x100000 > 0)
        result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
      if (x & 0x80000 > 0)
        result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
      if (x & 0x40000 > 0)
        result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
      if (x & 0x20000 > 0)
        result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
      if (x & 0x10000 > 0)
        result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
      if (x & 0x8000 > 0)
        result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
      if (x & 0x4000 > 0)
        result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
      if (x & 0x2000 > 0)
        result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
      if (x & 0x1000 > 0)
        result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
      if (x & 0x800 > 0)
        result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
      if (x & 0x400 > 0)
        result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
      if (x & 0x200 > 0)
        result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
      if (x & 0x100 > 0)
        result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
      if (x & 0x80 > 0)
        result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
      if (x & 0x40 > 0)
        result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
      if (x & 0x20 > 0)
        result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
      if (x & 0x10 > 0)
        result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
      if (x & 0x8 > 0)
        result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
      if (x & 0x4 > 0)
        result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
      if (x & 0x2 > 0)
        result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
      if (x & 0x1 > 0)
        result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

      result >>= uint256 (int256 (63 - (x >> 64)));
      require (result <= uint256 (int256 (MAX_64x64)));

      return int128 (int256 (result));
    }
  }

  /**
   * Calculate natural exponent of x.  Revert on overflow.
   *
   * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
  function exp (int128 x) internal pure returns (int128) {
    unchecked {
      require (x < 0x400000000000000000); // Overflow

      if (x < -0x400000000000000000) return 0; // Underflow

      return exp_2 (
          int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
    }
  }

  /**
   * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
   * integer numbers.  Revert on overflow or when y is zero.
   *
   * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
  function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    unchecked {
      require (y != 0);

      uint256 result;

      if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
        result = (x << 64) / y;
      else {
        uint256 msb = 192;
        uint256 xc = x >> 192;
        if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
        if (xc >= 0x10000) { xc >>= 16; msb += 16; }
        if (xc >= 0x100) { xc >>= 8; msb += 8; }
        if (xc >= 0x10) { xc >>= 4; msb += 4; }
        if (xc >= 0x4) { xc >>= 2; msb += 2; }
        if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

        result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
        require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 hi = result * (y >> 128);
        uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

        uint256 xh = x >> 192;
        uint256 xl = x << 64;

        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here
        lo = hi << 128;
        if (xl < lo) xh -= 1;
        xl -= lo; // We rely on overflow behavior here

        assert (xh == hi >> 128);

        result += xl / y;
      }

      require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
      return uint128 (result);
    }
  }

  /**
   * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
   * number.
   *
   * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
  function sqrtu (uint256 x) private pure returns (uint128) {
    unchecked {
      if (x == 0) return 0;
      else {
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
        if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
        if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
        if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
        if (xx >= 0x100) { xx >>= 8; r <<= 4; }
        if (xx >= 0x10) { xx >>= 4; r <<= 2; }
        if (xx >= 0x8) { r <<= 1; }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return uint128 (r < r1 ? r : r1);
      }
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, value);
    }

    function indexOf(AddressSet storage set, address value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(UintSet storage set, uint256 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            'EnumerableSet: index out of bounds'
        );
        return set._values[index];
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _indexOf(Set storage set, bytes32 value)
        private
        view
        returns (uint256)
    {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 index = valueIndex - 1;
            bytes32 last = set._values[set._values.length - 1];

            // move last value to now-vacant index

            set._values[index] = last;
            set._indexes[last] = index + 1;

            // clear last index

            set._values.pop();
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC1155Metadata interface
 */
interface IERC1155Metadata {
    /**
     * @notice get generated URI for given token
     * @return token URI
     */
    function uri(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: BUSL-1.1
// For further clarification please see https://license.premia.legal

pragma solidity ^0.8.0;

library PremiaMiningStorage {
    bytes32 internal constant STORAGE_SLOT =
        keccak256("premia.contracts.storage.PremiaMining");

    // Info of each pool.
    struct PoolInfo {
        uint256 allocPoint; // How many allocation points assigned to this pool. PREMIA to distribute per block.
        uint256 lastRewardTimestamp; // Last timestamp that PREMIA distribution occurs
        uint256 accPremiaPerShare; // Accumulated PREMIA per share, times 1e12. See below.
    }

    // Info of each user.
    struct UserInfo {
        uint256 reward; // Total allocated unclaimed reward
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of PREMIA
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accPremiaPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accPremiaPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    struct Layout {
        // Total PREMIA left to distribute
        uint256 premiaAvailable;
        // Amount of premia distributed per year
        uint256 premiaPerYear;
        // pool -> isCallPool -> PoolInfo
        mapping(address => mapping(bool => PoolInfo)) poolInfo;
        // pool -> isCallPool -> user -> UserInfo
        mapping(address => mapping(bool => mapping(address => UserInfo))) userInfo;
        // Total allocation points. Must be the sum of all allocation points in all pools.
        uint256 totalAllocPoint;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}