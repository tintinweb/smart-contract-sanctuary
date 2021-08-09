// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import "./IPermissions.sol";
import "../token/IRusd.sol";

/// @title Core Interface
/// @author Ring Protocol
interface ICore is IPermissions {
    // ----------- Events -----------

    event RusdUpdate(address indexed _rusd);
    event RingUpdate(address indexed _ring);
    event GenesisGroupUpdate(address indexed _genesisGroup);
    event RingAllocation(address indexed _to, uint256 _amount);
    event GenesisPeriodComplete(uint256 _timestamp);

    // ----------- Governor only state changing api -----------

    function init() external;

    // ----------- Governor only state changing api -----------

    function setRusd(address token) external;

    function setRing(address token) external;

    function setGenesisGroup(address _genesisGroup) external;

    function allocateRing(address to, uint256 amount) external;

    // ----------- Genesis Group only state changing api -----------

    function completeGenesisGroup() external;

    // ----------- Getters -----------

    function rusd() external view returns (IRusd);

    function ring() external view returns (IERC20);

    function genesisGroup() external view returns (address);

    function hasGenesisGroupCompleted() external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

/// @title Permissions interface
/// @author Ring Protocol
interface IPermissions {
    // ----------- Governor only state changing api -----------

    function createRole(bytes32 role, bytes32 adminRole) external;

    function grantMinter(address minter) external;

    function grantBurner(address burner) external;

    function grantPCVController(address pcvController) external;

    function grantGovernor(address governor) external;

    function grantGuardian(address guardian) external;

    function revokeMinter(address minter) external;

    function revokeBurner(address burner) external;

    function revokePCVController(address pcvController) external;

    function revokeGovernor(address governor) external;

    function revokeGuardian(address guardian) external;

    // ----------- Revoker only state changing api -----------

    function revokeOverride(bytes32 role, address account) external;

    // ----------- Getters -----------

    function isBurner(address _address) external view returns (bool);

    function isMinter(address _address) external view returns (bool);

    function isGovernor(address _address) external view returns (bool);

    function isGuardian(address _address) external view returns (bool);

    function isPCVController(address _address) external view returns (bool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRing is IERC20 {
    function delegate(address delegatee) external;
    function setMinter(address minter_) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

/// @title Genesis Group interface
/// @author Ring Protocol
interface IGenesisGroup {
    // ----------- Events -----------

    event Launch(uint256 _timestamp);

    // ----------- State changing API -----------

    function launch() external;

    // ----------- Getters -----------

    function launchBlock() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

interface IOrchestrator {
    function detonate() external;
}

interface IBondingCurveOrchestrator is IOrchestrator {
    function init(
        address core,
        address uniswapOracle,
        address erc20UniswapPCVDeposit,
        uint256 bondingCurveIncentiveDuration,
        uint256 bondingCurveIncentiveAmount,
        uint256 purchaseLimit,
        address tokenAddress
    ) external returns (address erc20BondingCurve);
}

interface IEthBondingCurveOrchestrator is IOrchestrator {
    function init(
        address core,
        address uniswapOracle,
        address erc20UniswapPCVDeposit,
        uint256 bondingCurveIncentiveDuration,
        uint256 bondingCurveIncentiveAmount,
        uint256 purchaseLimit
    ) external returns (address ethBondingCurve);
}

interface IIncentiveOrchestrator is IOrchestrator {
    function init(
        address core,
        uint256 rewardAmount
    ) external returns (address swapIncentive);
}

interface IGenesisOrchestrator is IOrchestrator {
    function init(
        address core,
        address ido
    ) external returns (address genesisGroup);
}

interface IStakingOrchestrator is IOrchestrator {
    function init(
        address core,
        address rusd,
        address ring,
        uint stakingDuration,
        uint dripFrequency,
        uint incentiveAmount
    ) external returns (address stakingRewards, address distributor);
}

interface IGovernanceOrchestrator is IOrchestrator {
    function init(
        address ring,
        address admin,
        uint256 timelockDelay
    ) external returns (address governorAlpha, address timelock);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../token/ISwapIncentive.sol";
import "../token/IRusd.sol";
import "../genesis/IGenesisGroup.sol";
import "../core/ICore.sol";
import "../staking/IRewardsDistributor.sol";
import "./IOrchestratorV2.sol";
import "../dao/IRing.sol";

// solhint-disable-next-line max-states-count
contract CoreV2Orchestrator is Ownable {
    address public admin;

    // ----------- Uniswap Addresses -----------
    address public constant ETH_BASE_UNI_PAIR =
        address(0x44892ab8F7aFfB7e1AdA4Fb956CCE2a2f3049619); // TODO: FIX1
    address public constant WBTC_BASE_UNI_PAIR =
        address(0x4352d79049518ff8c22441A3011fe62c0BCFfF73); // TODO: FIX1
    address public constant ROUTER =
        address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); // TODO: FIX1

    address public constant BASE =
        address(0xb7a4F3E9097C08dA09517b5aB877F7a917224ede); // TODO: FIX1
    address public constant WETH =
        address(0xd0A1E359811322d97991E03f863a0C30C2cF029C); // TODO: FIX1
    address public constant WBTC =
        address(0xd3A691C852CDB01E281545A27064741F0B7f6825); // TODO: FIX1

    IUniswapV2Factory public constant UNISWAP_FACTORY =
        IUniswapV2Factory(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f); // TODO: FIX1

    address public baseRusdPair;
    address public ethRusdPair;
    address public wbtcRusdPair;
    address public ringRusdPair;

    // ----------- Time periods -----------
    uint256 public constant TOKEN_TIMELOCK_RELEASE_WINDOW = 3 * 365 days;

    uint256 public constant DAO_TIMELOCK_DELAY = 1 days;

    uint256 public constant STAKING_REWARDS_DURATION = 2 * 365 days;

    uint256 public constant STAKING_REWARDS_DRIP_FREQUENCY = 1 weeks;

    uint32 public constant UNI_ORACLE_TWAP_DURATION = 10 minutes; // 10 min twap

    uint256 public constant BONDING_CURVE_ALLOCATE_INCENTIVE_FREQUENCY = 1 days; // 1 day duration

    // ----------- Params -----------
    uint256 public constant RING_KEEPER_INCENTIVE = 0;
    uint256 public constant REWARD_AMOUNT = 1;

    uint256 public constant BASE_LIMIT = 5_000e18; // TODO: CONSIDER
    uint256 public constant WETH_LIMIT = 5_000e18; // TODO: CONSIDER
    uint256 public constant WBTC_LIMIT = 5_000e18; // TODO: CONSIDER

    uint256 public constant MIN_REWEIGHT_DISTANCE_BPS = 100;

    bool public constant BASE_PER_ETH_IS_PRICE_0 = WETH < BASE; // for the ETH_BASE pair
    bool public constant BASE_PER_WBTC_IS_PRICE_0 = WBTC < BASE; // for the WBTC_BASE pair

    uint256 public ringSupply;
    uint256 public constant IDO_RING_PERCENTAGE = 1;
    uint256 public constant STAKING_RING_PERCENTAGE = 10;

    uint256 public constant RING_GRANTS_AMT = 60_000_000e18;
    uint256[3] public RING_TIMELOCK_AMTS = [
        uint256(150_000_000e18),
        uint256(150_000_000e18),
        uint256(130_000_000e18)
    ];

    // ----------- Orchestrators -----------
    IPCVDepositV2Orchestrator private pcvDepositV2Orchestrator;
    IBasePCVDepositV2Orchestrator private basePCVDepositV2Orchestrator;
    IBondingCurveOrchestrator private bcOrchestrator;
    IEthBondingCurveOrchestrator private ethBcOrchestrator;
    IIncentiveOrchestrator private incentiveOrchestrator;
    IControllerV2Orchestrator private controllerV2Orchestrator;
    IIDOV2Orchestrator private idoV2Orchestrator;
    IGenesisOrchestrator private genesisOrchestrator;
    IGovernanceOrchestrator private governanceOrchestrator;
    IStakingOrchestrator private stakingOrchestrator;

    // ----------- Deployed Contracts -----------
    ICore public core;
    address public rusd;
    address public ring;

    address public baseUniswapPCVDeposit;
    address public ethUniswapPCVDeposit;
    address public wbtcUniswapPCVDeposit;
    address public baseBondingCurve;
    address public ethBondingCurve;
    address public wbtcBondingCurve;

    address public baseUniswapOracle;
    address public ethUniswapOracle;
    address public wbtcUniswapOracle;

    address public swapIncentive;

    address public baseUniswapPCVController;
    address public ethUniswapPCVController;
    address public wbtcUniswapPCVController;

    address public ido;
    address public timelockedDelegator;
    address[] public timelockedDelegators;

    address public genesisGroup;

    address public ringStakingRewards;
    address public ringRewardsDistributor;

    address public governorAlpha;
    address public timelock;

    constructor(
        address _pcvDepositV2Orchestrator,
        address _basePCVDepositV2Orchestrator,
        address _bcOrchestrator,
        address _ethBcOrchestrator,
        address _incentiveOrchestrator,
        address _controllerV2Orchestrator,
        address _idoV2Orchestrator,
        address _genesisOrchestrator,
        address _governanceOrchestrator,
        address _stakingOrchestrator,
        address _admin
    ) {
        require(_admin != address(0), "CoreV2Orchestrator: no admin");

        pcvDepositV2Orchestrator = IPCVDepositV2Orchestrator(
            _pcvDepositV2Orchestrator
        );
        basePCVDepositV2Orchestrator = IBasePCVDepositV2Orchestrator(
            _basePCVDepositV2Orchestrator
        );
        bcOrchestrator = IBondingCurveOrchestrator(_bcOrchestrator);
        ethBcOrchestrator = IEthBondingCurveOrchestrator(_ethBcOrchestrator);
        incentiveOrchestrator = IIncentiveOrchestrator(_incentiveOrchestrator);
        idoV2Orchestrator = IIDOV2Orchestrator(_idoV2Orchestrator);
        controllerV2Orchestrator = IControllerV2Orchestrator(
            _controllerV2Orchestrator
        );
        genesisOrchestrator = IGenesisOrchestrator(_genesisOrchestrator);
        governanceOrchestrator = IGovernanceOrchestrator(
            _governanceOrchestrator
        );
        stakingOrchestrator = IStakingOrchestrator(_stakingOrchestrator);

        admin = _admin;
    }

    function initCore(address _core) public onlyOwner {
        core = ICore(_core);

        core.init();
        core.grantGuardian(admin);

        ring = address(core.ring());
        rusd = address(core.rusd());
        ringSupply = IERC20(ring).totalSupply();
    }

    function initPairBASE() public onlyOwner {
        baseRusdPair = UNISWAP_FACTORY.createPair(BASE, rusd);
    }

    function initPairETH() public onlyOwner {
        ethRusdPair = UNISWAP_FACTORY.createPair(WETH, rusd);
    }

    function initPairWBTC() public onlyOwner {
        wbtcRusdPair = UNISWAP_FACTORY.createPair(WBTC, rusd);
    }

    function initPoolGovernanceToken() public onlyOwner {
        ringRusdPair = UNISWAP_FACTORY.createPair(ring, rusd);
    }

    function initPCVDepositBASE() public onlyOwner() {
        (baseUniswapPCVDeposit, baseUniswapOracle) = basePCVDepositV2Orchestrator.init(
            address(core),
            baseRusdPair,
            ROUTER,
            UNI_ORACLE_TWAP_DURATION
        );
        core.grantMinter(baseUniswapPCVDeposit);
        // basePCVDepositV2Orchestrator.detonate();
    }

    function initPCVDepositETH() public onlyOwner() {
        (ethUniswapPCVDeposit, ethUniswapOracle) = pcvDepositV2Orchestrator.init(
            address(core),
            ethRusdPair,
            ROUTER,
            ETH_BASE_UNI_PAIR,
            UNI_ORACLE_TWAP_DURATION,
            BASE_PER_ETH_IS_PRICE_0
        );
        core.grantMinter(ethUniswapPCVDeposit);
    }

    function initPCVDepositWBTC() public onlyOwner() {
        (wbtcUniswapPCVDeposit, wbtcUniswapOracle) = pcvDepositV2Orchestrator.init(
            address(core),
            wbtcRusdPair,
            ROUTER,
            WBTC_BASE_UNI_PAIR,
            UNI_ORACLE_TWAP_DURATION,
            BASE_PER_WBTC_IS_PRICE_0
        );
        core.grantMinter(wbtcUniswapPCVDeposit);
        // pcvDepositV2Orchestrator.detonate();
    }

    function initBondingCurve() public onlyOwner {
        ethBondingCurve = ethBcOrchestrator.init(
            address(core),
            ethUniswapOracle,
            ethUniswapPCVDeposit,
            BONDING_CURVE_ALLOCATE_INCENTIVE_FREQUENCY,
            RING_KEEPER_INCENTIVE,
            WETH_LIMIT
        );
        core.grantMinter(ethBondingCurve);
        ethBcOrchestrator.detonate();

        baseBondingCurve = bcOrchestrator.init(
            address(core),
            baseUniswapOracle,
            baseUniswapPCVDeposit,
            BONDING_CURVE_ALLOCATE_INCENTIVE_FREQUENCY,
            RING_KEEPER_INCENTIVE,
            BASE_LIMIT,
            BASE
        );
        core.grantMinter(baseBondingCurve);

        wbtcBondingCurve = bcOrchestrator.init(
            address(core),
            wbtcUniswapOracle,
            wbtcUniswapPCVDeposit,
            BONDING_CURVE_ALLOCATE_INCENTIVE_FREQUENCY,
            RING_KEEPER_INCENTIVE,
            WBTC_LIMIT,
            WBTC
        );
        core.grantMinter(wbtcBondingCurve);
        bcOrchestrator.detonate();
    }

    function initIncentive() public onlyOwner {
        swapIncentive = incentiveOrchestrator.init(
            address(core),
            REWARD_AMOUNT
        );
        IRusd(rusd).setIncentiveContract(swapIncentive);
        incentiveOrchestrator.detonate();
    }

    function initControllerBASE() public onlyOwner {
        baseUniswapPCVController = controllerV2Orchestrator.init(
            address(core),
            baseUniswapOracle,
            baseUniswapPCVDeposit,
            baseRusdPair,
            ROUTER,
            RING_KEEPER_INCENTIVE,
            MIN_REWEIGHT_DISTANCE_BPS
        );
        core.grantMinter(baseUniswapPCVController);
        core.grantPCVController(baseUniswapPCVController);
    }

    function initControllerETH() public onlyOwner {
        ethUniswapPCVController = controllerV2Orchestrator.init(
            address(core),
            ethUniswapOracle,
            ethUniswapPCVDeposit,
            ethRusdPair,
            ROUTER,
            RING_KEEPER_INCENTIVE,
            MIN_REWEIGHT_DISTANCE_BPS
        );
        core.grantMinter(ethUniswapPCVController);
        core.grantPCVController(ethUniswapPCVController);
    }

    function initControllerWBTC() public onlyOwner {
        wbtcUniswapPCVController = controllerV2Orchestrator.init(
            address(core),
            wbtcUniswapOracle,
            wbtcUniswapPCVDeposit,
            wbtcRusdPair,
            ROUTER,
            RING_KEEPER_INCENTIVE,
            MIN_REWEIGHT_DISTANCE_BPS
        );
        core.grantMinter(wbtcUniswapPCVController);
        core.grantPCVController(wbtcUniswapPCVController);
        controllerV2Orchestrator.detonate();
    }

    function initIDO() public onlyOwner {
        (ido, timelockedDelegator) = idoV2Orchestrator.init(
            address(core),
            admin,
            ring,
            ringRusdPair,
            ROUTER,
            TOKEN_TIMELOCK_RELEASE_WINDOW
        );
        core.grantMinter(ido);
        core.grantBurner(ido);

        core.allocateRing(ido, (ringSupply * IDO_RING_PERCENTAGE) / 100);

        idoV2Orchestrator.detonate();
    }

    function initTimelocks(address[] memory _timelockedDelegators) public onlyOwner {
        require(timelockedDelegators.length == 0, "Already initialized");

        uint256 length = RING_TIMELOCK_AMTS.length;
        require(_timelockedDelegators.length == length, "Length mismatch");

        for (uint i = 0; i < length; i++) {
            core.allocateRing(
                _timelockedDelegators[i],
                RING_TIMELOCK_AMTS[i]
            );
        }

        core.allocateRing(
            admin,
            RING_GRANTS_AMT
        );

        timelockedDelegators = _timelockedDelegators;
    }

    function initGenesis() public onlyOwner {
        (genesisGroup) = genesisOrchestrator.init(
            address(core),
            ido
        );
        core.setGenesisGroup(genesisGroup);

        genesisOrchestrator.detonate();
    }

    function initStaking() public onlyOwner {
        (ringStakingRewards, ringRewardsDistributor) = stakingOrchestrator.init(
            address(core),
            rusd,
            ring,
            STAKING_REWARDS_DURATION,
            STAKING_REWARDS_DRIP_FREQUENCY,
            RING_KEEPER_INCENTIVE
        );

        core.allocateRing(
            ringRewardsDistributor,
            (ringSupply * STAKING_RING_PERCENTAGE) / 100
        );
        core.grantMinter(ringRewardsDistributor);

        IRewardsDistributor(ringRewardsDistributor).setStakingContract(ringStakingRewards);

        stakingOrchestrator.detonate();
    }

    function initGovernance() public onlyOwner {
        (governorAlpha, timelock) = governanceOrchestrator.init(
            ring,
            admin,
            DAO_TIMELOCK_DELAY
        );
        governanceOrchestrator.detonate();
        core.grantGovernor(timelock);
        IRing(ring).setMinter(timelock);
    }

    function renounceGovernor() public onlyOwner {
        core.revokeGovernor(address(this));
        renounceOwnership();
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "../orchestration/IOrchestrator.sol";

interface IBasePCVDepositV2Orchestrator is IOrchestrator {
    function init(
        address core,
        address pair,
        address router,
        uint32 twapDuration
    ) external returns (address erc20UniswapPCVDeposit, address uniswapOracle);
}

interface IPCVDepositV2Orchestrator is IOrchestrator {
    function init(
        address core,
        address pair,
        address router,
        address oraclePair,
        uint32 twapDuration,
        bool isPrice0
    ) external returns (address erc20UniswapPCVDeposit, address uniswapOracle);
}

interface IControllerV2Orchestrator is IOrchestrator {
    function init(
        address core,
        address oracle,
        address erc20UniswapPCVDeposit,
        address pair,
        address router,
        uint256 reweightIncentive,
        uint256 reweightMinDistanceBPs
    ) external returns (address erc20UniswapPCVController);
}

interface IIDOV2Orchestrator is IOrchestrator {
    function init(
        address core,
        address admin,
        address ring,
        address pair,
        address router,
        uint256 releaseWindowDuration
    ) external returns (address ido, address timelockedDelegator);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import "./IStakingRewards.sol";

/// @title Rewards Distributor interface
/// @author Ring Protocol
interface IRewardsDistributor {
    // ----------- Events -----------

    event Drip(
        address indexed _caller,
        uint256 _amount
    );

    event RingWithdraw(
        uint256 _amount
    );

    event FrequencyUpdate(
        uint256 _frequency
    );

    event IncentiveUpdate(
        uint256 _incentiveAmount
    );

    event StakingContractUpdate(
        address _stakingContract
    );

    // ----------- State changing API -----------

    function drip() external returns (uint256);

    // ----------- Governor-only changing API -----------

    function governorWithdrawRing(uint256 amount) external;

    function governorRecover(address tokenAddress, address to, uint256 amount) external;

    function setDripFrequency(uint256 _frequency) external;

    function setIncentiveAmount(uint256 _incentiveAmount) external;

    function setStakingContract(address _stakingRewards) external;

    // ----------- Getters -----------

    function totalReward() external view returns (uint256);

    function releasedReward() external view returns (uint256);

    function unreleasedReward() external view returns (uint256);

    function rewardBalance() external view returns (uint256);

    function distributedRewards() external view returns (uint256);

    function stakingContract() external view returns (IStakingRewards);

    function lastDistributionTime() external view returns (uint256);

    function isDripAvailable() external view returns (bool);

    function nextDripAvailable() external view returns (uint256);

    function dripFrequency() external view returns (uint256);

    function incentiveAmount() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStakingRewards {
    
    // ----------- Getters -----------

    function rewardsToken() external view returns(IERC20);

    function stakingToken() external view returns(IERC20);

    function periodFinish() external view returns(uint256);

    function rewardRate() external view returns(uint256);

    function rewardsDuration() external view returns(uint256);

    function lastUpdateTime() external view returns(uint256);

    function rewardPerTokenStored() external view returns(uint256);

    function userRewardPerTokenPaid(address account) external view returns(uint256);

    function rewards(address account) external view returns(uint256);

    function totalSupply() external view returns(uint256);

    function balanceOf(address account) external view returns(uint256);

    function lastTimeRewardApplicable() external view returns(uint256);

    function rewardPerToken() external view returns(uint256);

    function earned(address account) external view returns(uint256);

    function getRewardForDuration() external view returns(uint256);


    // ----------- State changing API -----------

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;

    // ----------- Rewards Distributor-Only State changing API -----------

    function notifyRewardAmount(uint256 reward) external;

    function recoverERC20(address tokenAddress, address to, uint256 tokenAmount) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title RUSD stablecoin interface
/// @author Ring Protocol
interface IRusd is IERC20 {
    // ----------- Events -----------

    event Minting(
        address indexed _to,
        address indexed _minter,
        uint256 _amount
    );

    event Burning(
        address indexed _to,
        address indexed _burner,
        uint256 _amount
    );

    event IncentiveContractUpdate(
        address indexed _incentiveContract
    );

    // ----------- State changing api -----------

    function burn(uint256 amount) external;

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    // ----------- Burner only state changing api -----------

    function burnFrom(address account, uint256 amount) external;

    // ----------- Minter only state changing api -----------

    function mint(address account, uint256 amount) external;

    // ----------- Governor only state changing api -----------

    function setIncentiveContract(address incentive) external;

    // ----------- Getters -----------

    function incentiveContract() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title SwapIncentive interface
/// @author Ring Protocol
interface ISwapIncentive {
    event RewardAmountUpdated(uint256 rewardAmount);

    function setRewardAmount(uint256 _rewardAmount) external;
    
    function incentivize(address sender, address recipient, address operator, uint256 amount) external;

    // ----------- Getters -----------

    function rewardAmount() external returns (uint256);
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
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