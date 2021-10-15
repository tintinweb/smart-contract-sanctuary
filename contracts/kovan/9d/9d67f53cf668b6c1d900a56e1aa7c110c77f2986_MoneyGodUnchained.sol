/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.6 <0.9.0;

//⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⣀⣀⣀⣀⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀      
//⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣴⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⣦⣄⡀⠀⠀⠀⠀⠀      
//⠀⠀⠀⠀⠀⠀⠀⠀⣴⡇⣴⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⢸⣦⠀⠀      
//⠀⠀⠀⠀⠀⠀⠀⢰⣿⡇⠉⠛⠛⠿⠿⣿⣿⣿⠋⠁⠀⠀⠈⠙⣿⣿⣿⠿⠿⠛⠛⠉⢸⣿⡆⠀      
//⠀⠀⠀⠀⠀⠀⠀⣼⣿⠀⠀⠀⠀⠀⠀⠀⠀⢿⡀⠀⠀⠀⠀⠀⣿⠀⠀⠀⠀⠀⠀⠀⠸⣿⣧⠀      
//⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⠀⠀⠀⠀⡟⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀      
//⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⠀      
//⠀⠀⠀⠀⠀⠀⢰⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠘⠃⠀⠀⠀⠀⠀⡇⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⡄      
//⠀⠀⠀⠀⠀⠀⢸⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⣿⣿⣿⣦⡁⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⡇      
//⠀⠀⠀⠀⠀⠀⢸⣿⣿⠀⠀⠀⠀⠀⠀⠀⢰⣿⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⣿⣿⡇      
//⠀⠀⠀⠀⠀⠀⢸⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⢈⣉⣉⣉⣉⣉⣉⡁⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⡇      
//⠀⠀⠀⠀⠀⠀⠸⣿⣿⠀⠀⠀⠀⠀⠀⠴⠚⠛⢋⣉⣉⣉⣉⡙⠛⠓⠦⠀⠀⠀⠀⠀⢰⣿⣿⠇      
//⠀⠀⠀⠀⠀⠀⠀⠛⠿⠇⠀⠀⠀⠀⢠⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣶⡄⠀⠀⠀⠀⢸⠿⠛⠀      
//⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠁⠀⠀⠀⠀⠀⠀⠀⠀      
//⠀⠀⠀⠀⠀⠀⠀⠀⠀⣤⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣧⠀⠀⠀      
//⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣿⣧⠀⠀      
//⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣷⣶⣤⣤⣤⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣤⣤⣤⣶⣾⣿⣿⣿⠀⠀      
//⠀⠀⠀⠀⠀⠀⠀⠀⠛⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠛⠀⠀      
//⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠉⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠛⠉⠉⠉⠀⠀⠀⠀⠀    
//                                          

////// src/External.sol
/* pragma solidity ^0.8.6; */

interface Hevm {
    function warp(uint256) external;

    function roll(uint256) external;

    function store(
        address,
        bytes32,
        bytes32
    ) external;

    function store(
        address,
        bytes32,
        address
    ) external;

    function load(address, bytes32) external view returns (bytes32);
}

interface SafeEngineLike {
    function safeRights(address, address) external view returns (uint256);

    function coinBalance(address) external view returns (uint256);

    function safes(bytes32, address) external view returns (uint256, uint256);

    function modifySAFECollateralization(
        bytes32 collateralType,
        address safe,
        address collateralSource,
        address debtDestination,
        int256 deltaCollateral,
        int256 deltaDebt
    ) external;

    function collateralTypes(bytes32)
        external
        view
        returns (
            uint256 debtAmount, // [wad]
            uint256 accumulatedRate, // [ray]
            uint256 safetyPrice, // [ray]
            uint256 debtCeiling, // [rad]
            uint256 debtFloor, // [rad]
            uint256 liquidationPrice // [ray]
        );

    function approveSAFEModification(address) external;

    function transferInternalCoins(
        address,
        address,
        uint256
    ) external;

    function tokenCollateral(bytes32, address) external view returns (uint256);

    function safeDebtCeiling() external view returns (uint256);
}

interface OracleRelayerLike {
    function collateralTypes(bytes32)
        external
        view
        returns (
            address,
            uint256,
            uint256
        );

    function liquidationCRatio(bytes32) external view returns (uint256);

    function redemptionPrice() external returns (uint256);
}

interface TaxCollectorLike {
    function taxSingle(bytes32) external returns (uint256);
}

interface JoinLike {
    function decimals() external returns (uint256);

    function join(address, uint256) external payable;

    function exit(address, uint256) external;
}

interface LiquidationEngineLike {
    function liquidateSAFE(bytes32 collateralType, address safe)
        external
        returns (uint256 auctionId);
}

interface PingerBundlerCall {
    function updateOsmAndEthAOracleRelayer() external;
}

interface IncreasingDiscountCollateralAuctionHouseLike {
    function buyCollateral(uint256, uint256) external;
}

interface WethLike {
    function balanceOf(address) external view returns (uint256);

    function approve(address, uint256) external;

    function transfer(address, uint256) external;

    function transferFrom(
        address,
        address,
        uint256
    ) external;

    function deposit() external payable;

    function withdraw(uint256) external;
}

interface TokenLike {
    function approve(address, uint256) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external;

    function transferFrom(
        address,
        address,
        uint256
    ) external;
}

////// src/IMoneyGodUnchained.sol
/* pragma solidity ^0.8.6; */

/* import "./External.sol"; */

contract IMoneyGodUnchained {
    // === STRUCTS ===

    struct Disciple {
        // Grace credited
        uint256 grace;
        // Grace per offering already paid out
        uint256 gracePerOfferingPaid;
        // Amount of ETH offered in sacrifice so far
        uint256 offerings;
    }

    // === CONSTANTS ====

    uint256 public constant MIN_SACRIFICE_TO_LEAD = 0.1 ether;
    bytes32 public constant COLLATERAL_TYPE = "ETH-A";
    uint256 public constant LIQUIDATION_PERIOD = 24 hours;

    uint256 internal constant WAD = 1e18;
    uint256 internal constant RAY = 1e27;
    uint256 internal constant RAD = 1e45;

    // === STATE ===

    // Individual state
    mapping(address => Disciple) public disciples;

    // If the game was seeded
    bool public isInit = false;

    // Whether the
    bool public finalized = false;

    // Address to win the jackpot
    address public leader;

    // Start time of the game
    uint256 public startTime;

    // Total ETH contributed so far
    uint256 public totalOfferings;

    // Amount of grace divided by the total amount of offering already distributed
    uint256 public gracePerOfferingStored;

    // Last time that the grace accounting was done (updateGrace modifier)
    uint256 public lastUpdatedTime;

    // Rate of RAI minting, is readjusted everytime someones make a sacrifice above the threhold
    uint256 public mintRate;

    // === EXTERNAL CONTRACTS ====

    SafeEngineLike constant safeEngine =
        SafeEngineLike(0x7f63fE955fFF8EA474d990f1Fc8979f2C650edbE);
    JoinLike constant ethJoin =
        JoinLike(0xad4AB4Cb7b8aDC45Bf2873507fC8700f3dFB9Dd3);
    JoinLike constant raiJoin =
        JoinLike(0x7d4fe9659D80970097E604727a2BA3F094B00758);
    OracleRelayerLike constant oracleRelayer =
        OracleRelayerLike(0xE5Ae4E49bEA485B5E5172EE6b1F99243cB15225c);
    TaxCollectorLike constant taxCollector =
        TaxCollectorLike(0xc1a94C5ad9FCD79b03F79B34d8C0B0C8192fdc16);
    WethLike constant weth =
        WethLike(0xd0A1E359811322d97991E03f863a0C30C2cF029C);

    // === EVENTS ===

    event Initialized(uint256 initialCollateral, uint256 initialDebt);
    event Sacrifice(address indexed disciple, uint256 amount);
    event UpdateGrace(
        address indexed leader,
        uint256 totalOfferings,
        uint256 collateralAdded,
        uint256 mintRate
    );
    event WithdrawGrace(address indexed from, uint256 amount);
    event WithdrawBlessings(address indexed leader, uint256 amount);
}

////// src/MoneyGodUnchained.sol
/* pragma solidity ^0.8.6; */

/* import "./External.sol"; */
/* import "./IMoneyGodUnchained.sol"; */

contract MoneyGodUnchained is IMoneyGodUnchained {
    // === CONSTRUCTOR ===

    constructor() payable {
        // Set the approval needed to join eth into the safe engine
        weth.approve(address(ethJoin), type(uint256).max);

        // Allow the RAI join to access the internal balance to exit RAI
        safeEngine.approveSAFEModification(address(raiJoin));
    }

    // === MODIFIERS ===

    modifier requireInit() {
        require(isInit, "not started");
        _;
    }

    modifier updateGrace(address discipleAddress, uint256 collateralToAdd) {
        // Update and fetch the accumulated rate
        uint256 accumulatedRate = taxCollector.taxSingle(COLLATERAL_TYPE);

        // Fetch the liquidation price (amount of RAI that can be minted per unit of collateral)
        (, , , , , uint256 liquidationPrice) = safeEngine.collateralTypes(
            COLLATERAL_TYPE
        );

        // Fetch the debt and collateral of the Safe
        (uint256 collateral, uint256 debt) = safeEngine.safes(
            COLLATERAL_TYPE,
            address(this)
        );

        // If debt is at 0, it means we got liquidated
        require(debt > 0, "Game over");

        // The maximum amount of RAI we could mint before getting liquidated
        uint256 maxMintableRai = (collateral * liquidationPrice) /
            RAY -
            (debt * accumulatedRate) /
            RAY -
            1;

        // Amount of RAI we will be minting
        uint256 raiToMint = min(
            mintRate * (block.timestamp - lastUpdatedTime),
            maxMintableRai
        );

        // Raw debt, not including the accumulated rate
        uint256 nonAdjustedRaiToMint = (raiToMint * RAY) / accumulatedRate;

        // Similar to proxy actions, due to precission loss from applying the rate above, we sometime need to add 1
        nonAdjustedRaiToMint = nonAdjustedRaiToMint * accumulatedRate <
            raiToMint * RAY
            ? nonAdjustedRaiToMint + 1
            : nonAdjustedRaiToMint;

        // If we're adding collateral, we need to wrap and join into internal balance first
        if (collateralToAdd > 0) {
            weth.deposit{value: collateralToAdd}();
            ethJoin.join(address(this), collateralToAdd);
        }

        // Make the actual safe modification
        safeEngine.modifySAFECollateralization(
            COLLATERAL_TYPE,
            address(this),
            address(this),
            address(this),
            toInt256(collateralToAdd),
            toInt256(nonAdjustedRaiToMint)
        );

        // Update global state
        if (totalOfferings > 0)
            // I should never be zero unless the function is call in the same block as the initialization
            gracePerOfferingStored += (raiToMint * WAD) / totalOfferings;
        totalOfferings += collateralToAdd;
        lastUpdatedTime = block.timestamp;

        // Update individual address state
        if (discipleAddress != address(0)) {
            // Credit disciple account
            disciples[discipleAddress].grace = graceEarned(discipleAddress);
            disciples[discipleAddress]
                .gracePerOfferingPaid = gracePerOfferingStored;
            disciples[discipleAddress].offerings += collateralToAdd;

            // Set the discple as leader and reset the mint rate if the deposit is significant enough
            if (collateralToAdd >= MIN_SACRIFICE_TO_LEAD) {
                leader = discipleAddress;

                (collateral, debt) = safeEngine.safes(
                    COLLATERAL_TYPE,
                    address(this)
                );
                maxMintableRai =
                    (collateral * liquidationPrice) /
                    RAY -
                    (debt * accumulatedRate) /
                    RAY;
                mintRate = maxMintableRai / LIQUIDATION_PERIOD;
            }
        }

        emit UpdateGrace(leader, totalOfferings, collateralToAdd, mintRate);

        // Modifier placeholder
        _;
    }

    // === VIEW ====

    function graceEarned(address discipleAddress)
        public
        view
        returns (uint256)
    {
        return
            (disciples[discipleAddress].offerings *
                (gracePerOfferingStored -
                    disciples[discipleAddress].gracePerOfferingPaid)) /
            WAD +
            disciples[discipleAddress].grace;
    }

    // === MUTATIVE ====

    function initialize(uint256 initialDebt) external payable {
        // The game should have not been initialized before
        require(!isInit);

        // We need to tax before making any safe m,odification
        uint256 accumulatedRate = taxCollector.taxSingle(COLLATERAL_TYPE);

        // Fetch the liquidation price (amount of RAI that can be minted per unit of collateral)
        (, , , , , uint256 liquidationPrice) = safeEngine.collateralTypes(
            COLLATERAL_TYPE
        );

        // Wrap and join as internal balance the collateral
        weth.deposit{value: msg.value}();
        ethJoin.join(address(this), msg.value);

        // Initialize the safe
        safeEngine.modifySAFECollateralization(
            COLLATERAL_TYPE,
            address(this),
            address(this),
            address(this),
            toInt256(msg.value),
            toInt256((initialDebt * RAY) / accumulatedRate)
        );

        startTime = block.timestamp;
        lastUpdatedTime = block.timestamp;

        // Initilizer becomes the first depositor with the initial ETH
        leader = msg.sender;
        totalOfferings += msg.value;
        disciples[msg.sender].offerings += msg.value;

        // Directly credit the initial debt to the initializer
        disciples[msg.sender].grace = initialDebt;

        // Set the initial mint rate
        uint256 maxMintableRai = (msg.value * liquidationPrice) /
            RAY -
            (initialDebt * accumulatedRate) /
            RAY;
        mintRate = maxMintableRai / LIQUIDATION_PERIOD;

        // The ritual has started
        isInit = true;

        emit Initialized(msg.value, initialDebt);
    }

    function sacrifice()
        external
        payable
        requireInit
        updateGrace(msg.sender, msg.value)
    {
        emit Sacrifice(msg.sender, msg.value);
    }

    function withdrawGrace()
        external
        requireInit
        updateGrace(msg.sender, 0)
        returns (uint256)
    {
        uint256 grace = disciples[msg.sender].grace;

        if (grace > 0) {
            disciples[msg.sender].grace = 0;
            // Since the internal balance is RAD, withdraw 1 less wei to be sure to have sufficient internal balance
            raiJoin.exit(msg.sender, grace - 1);

            emit WithdrawGrace(address(msg.sender), grace - 1);
        }

        return grace;
    }

    function withdrawBlessings() external requireInit returns (uint256) {
        uint256 blessing = safeEngine.tokenCollateral(
            COLLATERAL_TYPE,
            address(this)
        );
        ethJoin.exit(leader, blessing);

        emit WithdrawBlessings(leader, blessing);

        return blessing;
    }

    // === INTERNAL ===

    // Utilities from Open Zepplin
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(
            value <= uint256(type(int256).max),
            "SafeCast: value doesn't fit in an int256"
        );
        return int256(value);
    }
}