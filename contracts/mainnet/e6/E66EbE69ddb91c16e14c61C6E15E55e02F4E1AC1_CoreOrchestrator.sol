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
pragma solidity =0.7.6;

import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../genesis/IGenesisGroup.sol";
import "../core/ICore.sol";
import "../staking/IRewardsDistributor.sol";
import "./IOrchestrator.sol";
import "../dao/IRing.sol";

// solhint-disable-next-line max-states-count
contract CoreOrchestrator is Ownable {
    address public admin;

    // ----------- Uniswap Addresses -----------
    address public constant USDC_USDT_UNI_POOL =
        address(0x7858E59e0C01EA06Df3aF3D20aC7B0003275D4Bf);
    address public constant USDC_DAI_UNI_POOL =
        address(0x6c6Bc977E13Df9b0de53b251522280BB72383700);
    address public constant NFT =
        address(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);
    address public constant ROUTER =
        address(0xE592427A0AEce92De3Edee1F18E0157C05861564);


    address public constant USDC =
        address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address public constant USDT =
        address(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    address public constant DAI =
        address(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    address public usdcRusdPool;
    address public usdtRusdPool;
    address public daiRusdPool;
    address public ringRusdPool;

    // ----------- Time periods -----------
    uint256 public constant TOKEN_TIMELOCK_RELEASE_WINDOW = 3 * 365 days;

    uint256 public constant DAO_TIMELOCK_DELAY = 1 days;

    uint256 public constant STAKING_REWARDS_DURATION = 2 * 365 days;

    uint256 public constant STAKING_REWARDS_DRIP_FREQUENCY = 1 weeks;

    uint32 public constant UNI_ORACLE_TWAP_DURATION = 10 minutes; // 10 min twap

    uint256 public constant BONDING_CURVE_ALLOCATE_INCENTIVE_FREQUENCY = 1 days; // 1 day duration

    // ----------- Params -----------
    uint256 public constant RING_KEEPER_INCENTIVE = 100e18;

    uint256 public constant MIN_REWEIGHT_DISTANCE_BPS = 100;

    bool public constant USDC_PER_USDT_IS_PRICE_0 = USDT < USDC; // for the USDT_USDC pair
    bool public constant USDC_PER_DAI_IS_PRICE_0 = DAI < USDC; // for the DAI_USDC pair

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
    IPCVDepositOrchestrator private pcvDepositOrchestrator;
    IUSDCPCVDepositOrchestrator private usdcPCVDepositOrchestrator;
    IBondingCurveOrchestrator private bcOrchestrator;
    IControllerOrchestrator private controllerOrchestrator;
    IIDOOrchestrator private idoOrchestrator;
    IGenesisOrchestrator private genesisOrchestrator;
    IGovernanceOrchestrator private governanceOrchestrator;
    IStakingOrchestrator private stakingOrchestrator;

    // ----------- Deployed Contracts -----------
    ICore public core;
    address public rusd;
    address public ring;

    address public usdcUniswapPCVDeposit;
    address public usdtUniswapPCVDeposit;
    address public daiUniswapPCVDeposit;
    address public usdcBondingCurve;
    address public usdtBondingCurve;
    address public daiBondingCurve;

    address public usdcUniswapOracle;
    address public usdtUniswapOracle;
    address public daiUniswapOracle;

    address public usdcUniswapPCVController;
    address public usdtUniswapPCVController;
    address public daiUniswapPCVController;

    address public ido;
    address public timelockedDelegator;
    address[] public timelockedDelegators;

    address public genesisGroup;

    address public ringStakingRewards;
    address public ringRewardsDistributor;

    address public governorAlpha;
    address public timelock;

    constructor(
        address _pcvDepositOrchestrator,
        address _usdcPCVDepositOrchestrator,
        address _bcOrchestrator,
        address _controllerOrchestrator,
        address _idoOrchestrator,
        address _genesisOrchestrator,
        address _governanceOrchestrator,
        address _stakingOrchestrator,
        address _admin
    ) {
        require(_admin != address(0), "CoreOrchestrator: no admin");

        pcvDepositOrchestrator = IPCVDepositOrchestrator(
            _pcvDepositOrchestrator
        );
        usdcPCVDepositOrchestrator = IUSDCPCVDepositOrchestrator(
            _usdcPCVDepositOrchestrator
        );
        bcOrchestrator = IBondingCurveOrchestrator(_bcOrchestrator);
        idoOrchestrator = IIDOOrchestrator(_idoOrchestrator);
        controllerOrchestrator = IControllerOrchestrator(
            _controllerOrchestrator
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

    function initPoolUSDC() public onlyOwner {
        usdcRusdPool = INonfungiblePositionManager(NFT).createAndInitializePoolIfNecessary(
            rusd < USDC ? rusd : USDC, rusd < USDC ? USDC : rusd, 500, rusd < USDC ? 79228162514264337593543 : 79228162514264337593543950336000000
        );
    }

    function initPoolUSDT() public onlyOwner {
        usdtRusdPool = INonfungiblePositionManager(NFT).createAndInitializePoolIfNecessary(
            rusd < USDT ? rusd : USDT, rusd < USDT ? USDT : rusd, 500, rusd < USDT ? 79228162514264337593543 : 79228162514264337593543950336000000
        );
    }

     function initPoolDAI() public onlyOwner {
        daiRusdPool = INonfungiblePositionManager(NFT).createAndInitializePoolIfNecessary(
            rusd < DAI ? rusd : DAI, rusd < DAI ? DAI : rusd, 500, 79228162514264337593543950336
        );
    }

    function initPoolGovernanceToken() public onlyOwner {
        ringRusdPool = INonfungiblePositionManager(NFT).createAndInitializePoolIfNecessary(
            ring < rusd ? ring : rusd, ring < rusd ? rusd : ring, 3000, ring < rusd ? 17715955711429571029610171616 : 354319114228591420592203432321
        );
    }

    function initPCVDepositUSDC() public onlyOwner() {
        (int24 usdcTickLower, int24 usdcTickUpper) = rusd < USDC ? (-276530, -276130) : (int24(276120), int24(276520));
        (usdcUniswapPCVDeposit, usdcUniswapOracle) = usdcPCVDepositOrchestrator.init(
            address(core),
            usdcRusdPool,
            NFT,
            ROUTER,
            UNI_ORACLE_TWAP_DURATION,
            usdcTickLower,
            usdcTickUpper
        );
        core.grantMinter(usdcUniswapPCVDeposit);
        usdcPCVDepositOrchestrator.detonate();
    }

    function initPCVDepositUSDT() public onlyOwner() {
        (int24 usdtTickLower, int24 usdtTickUpper) = rusd < USDT ? (-276530, -276130) : (int24(276120), int24(276520));
        (usdtUniswapPCVDeposit, usdtUniswapOracle) = pcvDepositOrchestrator.init(
            address(core),
            usdtRusdPool,
            NFT,
            ROUTER,
            USDC_USDT_UNI_POOL,
            UNI_ORACLE_TWAP_DURATION,
            USDC_PER_USDT_IS_PRICE_0,
            usdtTickLower,
            usdtTickUpper
        );
        core.grantMinter(usdtUniswapPCVDeposit);
    }

    function initPCVDepositDAI() public onlyOwner() {
        (daiUniswapPCVDeposit, daiUniswapOracle) = pcvDepositOrchestrator.init(
            address(core),
            daiRusdPool,
            NFT,
            ROUTER,
            USDC_DAI_UNI_POOL,
            UNI_ORACLE_TWAP_DURATION,
            USDC_PER_DAI_IS_PRICE_0,
            -200,
            200
        );
        core.grantMinter(daiUniswapPCVDeposit);
        pcvDepositOrchestrator.detonate();
    }

    function initBondingCurve() public onlyOwner {
        usdcBondingCurve = bcOrchestrator.init(
            address(core),
            usdcUniswapOracle,
            usdcUniswapPCVDeposit,
            BONDING_CURVE_ALLOCATE_INCENTIVE_FREQUENCY,
            RING_KEEPER_INCENTIVE,
            USDC
        );
        core.grantMinter(usdcBondingCurve);

        usdtBondingCurve = bcOrchestrator.init(
            address(core),
            usdtUniswapOracle,
            usdtUniswapPCVDeposit,
            BONDING_CURVE_ALLOCATE_INCENTIVE_FREQUENCY,
            RING_KEEPER_INCENTIVE,
            USDT
        );
        core.grantMinter(usdtBondingCurve);

        daiBondingCurve = bcOrchestrator.init(
            address(core),
            daiUniswapOracle,
            daiUniswapPCVDeposit,
            BONDING_CURVE_ALLOCATE_INCENTIVE_FREQUENCY,
            RING_KEEPER_INCENTIVE,
            DAI
        );
        core.grantMinter(daiBondingCurve);
        bcOrchestrator.detonate();
    }

    function initControllerUSDC() public onlyOwner {
        usdcUniswapPCVController = controllerOrchestrator.init(
            address(core),
            usdcUniswapOracle,
            usdcUniswapPCVDeposit,
            usdcRusdPool,
            NFT,
            ROUTER,
            RING_KEEPER_INCENTIVE,
            MIN_REWEIGHT_DISTANCE_BPS
        );
        core.grantMinter(usdcUniswapPCVController);
        core.grantPCVController(usdcUniswapPCVController);
    }

    function initControllerUSDT() public onlyOwner {
        usdtUniswapPCVController = controllerOrchestrator.init(
            address(core),
            usdtUniswapOracle,
            usdtUniswapPCVDeposit,
            usdtRusdPool,
            NFT,
            ROUTER,
            RING_KEEPER_INCENTIVE,
            MIN_REWEIGHT_DISTANCE_BPS
        );
        core.grantMinter(usdtUniswapPCVController);
        core.grantPCVController(usdtUniswapPCVController);
    }

    function initControllerDAI() public onlyOwner {
        daiUniswapPCVController = controllerOrchestrator.init(
            address(core),
            daiUniswapOracle,
            daiUniswapPCVDeposit,
            daiRusdPool,
            NFT,
            ROUTER,
            RING_KEEPER_INCENTIVE,
            MIN_REWEIGHT_DISTANCE_BPS
        );
        core.grantMinter(daiUniswapPCVController);
        core.grantPCVController(daiUniswapPCVController);
        controllerOrchestrator.detonate();
    }

    function initIDO() public onlyOwner {
        (ido, timelockedDelegator) = idoOrchestrator.init(
            address(core),
            admin,
            ring,
            ringRusdPool,
            NFT,
            ROUTER,
            TOKEN_TIMELOCK_RELEASE_WINDOW
        );
        core.grantMinter(ido);
        core.grantBurner(ido);

        core.allocateRing(ido, (ringSupply * IDO_RING_PERCENTAGE) / 100);

        idoOrchestrator.detonate();
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

interface IOrchestrator {
    function detonate() external;
}

interface IPCVDepositOrchestrator is IOrchestrator {
    function init(
        address core,
        address pool,
        address nft,
        address router,
        address oraclePool,
        uint32 twapDuration,
        bool isPrice0,
        int24 tickLower,
        int24 tickUpper
    ) external returns (address erc20UniswapPCVDeposit, address uniswapOracle);
}

interface IUSDCPCVDepositOrchestrator is IOrchestrator {
    function init(
        address core,
        address pool,
        address nft,
        address router,
        uint32 twapDuration,
        int24 tickLower,
        int24 tickUpper
    ) external returns (address erc20UniswapPCVDeposit, address uniswapOracle);
}

interface IBondingCurveOrchestrator is IOrchestrator {
    function init(
        address core,
        address uniswapOracle,
        address erc20UniswapPCVDeposit,
        uint256 bondingCurveIncentiveDuration,
        uint256 bondingCurveIncentiveAmount,
        address tokenAddress
    ) external returns (address erc20BondingCurve);
}

interface IControllerOrchestrator is IOrchestrator {
    function init(
        address core,
        address oracle,
        address erc20UniswapPCVDeposit,
        address pool,
        address nft,
        address router,
        uint256 reweightIncentive,
        uint256 reweightMinDistanceBPs
    ) external returns (address erc20UniswapPCVController);
}

interface IIDOOrchestrator is IOrchestrator {
    function init(
        address core,
        address admin,
        address ring,
        address pool,
        address nft,
        address router,
        uint256 releaseWindowDuration
    ) external returns (address ido, address timelockedDelegator);
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
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

/// @title ERC721 with permit
/// @notice Extension to ERC721 that includes a permit function for signature based approvals
interface IERC721Permit is IERC721 {
    /// @notice The permit typehash used in the permit signature
    /// @return The typehash for the permit
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    /// @notice The domain separator used in the permit signature
    /// @return The domain seperator used in encoding of permit signature
    function DOMAIN_SEPARATOR() external view returns (bytes32);

    /// @notice Approve of a specific token ID for spending by spender via signature
    /// @param spender The account that is being approved
    /// @param tokenId The ID of the token that is being approved for spending
    /// @param deadline The deadline timestamp by which the call must be mined for the approve to work
    /// @param v Must produce valid secp256k1 signature from the holder along with `r` and `s`
    /// @param r Must produce valid secp256k1 signature from the holder along with `v` and `s`
    /// @param s Must produce valid secp256k1 signature from the holder along with `r` and `v`
    function permit(
        address spender,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC721/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol';

import './IPoolInitializer.sol';
import './IERC721Permit.sol';
import './IPeripheryPayments.sol';
import './IPeripheryImmutableState.sol';
import '../libraries/PoolAddress.sol';

/// @title Non-fungible token for positions
/// @notice Wraps Uniswap V3 positions in a non-fungible token interface which allows for them to be transferred
/// and authorized.
interface INonfungiblePositionManager is
    IPoolInitializer,
    IPeripheryPayments,
    IPeripheryImmutableState,
    IERC721Metadata,
    IERC721Enumerable,
    IERC721Permit
{
    /// @notice Emitted when liquidity is increased for a position NFT
    /// @dev Also emitted when a token is minted
    /// @param tokenId The ID of the token for which liquidity was increased
    /// @param liquidity The amount by which liquidity for the NFT position was increased
    /// @param amount0 The amount of token0 that was paid for the increase in liquidity
    /// @param amount1 The amount of token1 that was paid for the increase in liquidity
    event IncreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when liquidity is decreased for a position NFT
    /// @param tokenId The ID of the token for which liquidity was decreased
    /// @param liquidity The amount by which liquidity for the NFT position was decreased
    /// @param amount0 The amount of token0 that was accounted for the decrease in liquidity
    /// @param amount1 The amount of token1 that was accounted for the decrease in liquidity
    event DecreaseLiquidity(uint256 indexed tokenId, uint128 liquidity, uint256 amount0, uint256 amount1);
    /// @notice Emitted when tokens are collected for a position NFT
    /// @dev The amounts reported may not be exactly equivalent to the amounts transferred, due to rounding behavior
    /// @param tokenId The ID of the token for which underlying tokens were collected
    /// @param recipient The address of the account that received the collected tokens
    /// @param amount0 The amount of token0 owed to the position that was collected
    /// @param amount1 The amount of token1 owed to the position that was collected
    event Collect(uint256 indexed tokenId, address recipient, uint256 amount0, uint256 amount1);

    /// @notice Returns the position information associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the position
    /// @return nonce The nonce for permits
    /// @return operator The address that is approved for spending
    /// @return token0 The address of the token0 for a specific pool
    /// @return token1 The address of the token1 for a specific pool
    /// @return fee The fee associated with the pool
    /// @return tickLower The lower end of the tick range for the position
    /// @return tickUpper The higher end of the tick range for the position
    /// @return liquidity The liquidity of the position
    /// @return feeGrowthInside0LastX128 The fee growth of token0 as of the last action on the individual position
    /// @return feeGrowthInside1LastX128 The fee growth of token1 as of the last action on the individual position
    /// @return tokensOwed0 The uncollected amount of token0 owed to the position as of the last computation
    /// @return tokensOwed1 The uncollected amount of token1 owed to the position as of the last computation
    function positions(uint256 tokenId)
        external
        view
        returns (
            uint96 nonce,
            address operator,
            address token0,
            address token1,
            uint24 fee,
            int24 tickLower,
            int24 tickUpper,
            uint128 liquidity,
            uint256 feeGrowthInside0LastX128,
            uint256 feeGrowthInside1LastX128,
            uint128 tokensOwed0,
            uint128 tokensOwed1
        );

    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    /// @notice Creates a new position wrapped in a NFT
    /// @dev Call this when the pool does exist and is initialized. Note that if the pool is created but not initialized
    /// a method does not exist, i.e. the pool is assumed to be initialized.
    /// @param params The params necessary to mint a position, encoded as `MintParams` in calldata
    /// @return tokenId The ID of the token that represents the minted position
    /// @return liquidity The amount of liquidity for this position
    /// @return amount0 The amount of token0
    /// @return amount1 The amount of token1
    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct IncreaseLiquidityParams {
        uint256 tokenId;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Increases the amount of liquidity in a position, with tokens paid by the `msg.sender`
    /// @param params tokenId The ID of the token for which liquidity is being increased,
    /// amount0Desired The desired amount of token0 to be spent,
    /// amount1Desired The desired amount of token1 to be spent,
    /// amount0Min The minimum amount of token0 to spend, which serves as a slippage check,
    /// amount1Min The minimum amount of token1 to spend, which serves as a slippage check,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return liquidity The new liquidity amount as a result of the increase
    /// @return amount0 The amount of token0 to acheive resulting liquidity
    /// @return amount1 The amount of token1 to acheive resulting liquidity
    function increaseLiquidity(IncreaseLiquidityParams calldata params)
        external
        payable
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct DecreaseLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    /// @notice Decreases the amount of liquidity in a position and accounts it to the position
    /// @param params tokenId The ID of the token for which liquidity is being decreased,
    /// amount The amount by which liquidity will be decreased,
    /// amount0Min The minimum amount of token0 that should be accounted for the burned liquidity,
    /// amount1Min The minimum amount of token1 that should be accounted for the burned liquidity,
    /// deadline The time by which the transaction must be included to effect the change
    /// @return amount0 The amount of token0 accounted to the position's tokens owed
    /// @return amount1 The amount of token1 accounted to the position's tokens owed
    function decreaseLiquidity(DecreaseLiquidityParams calldata params)
        external
        payable
        returns (uint256 amount0, uint256 amount1);

    struct CollectParams {
        uint256 tokenId;
        address recipient;
        uint128 amount0Max;
        uint128 amount1Max;
    }

    /// @notice Collects up to a maximum amount of fees owed to a specific position to the recipient
    /// @param params tokenId The ID of the NFT for which tokens are being collected,
    /// recipient The account that should receive the tokens,
    /// amount0Max The maximum amount of token0 to collect,
    /// amount1Max The maximum amount of token1 to collect
    /// @return amount0 The amount of fees collected in token0
    /// @return amount1 The amount of fees collected in token1
    function collect(CollectParams calldata params) external payable returns (uint256 amount0, uint256 amount1);

    /// @notice Burns a token ID, which deletes it from the NFT contract. The token must have 0 liquidity and all tokens
    /// must be collected first.
    /// @param tokenId The ID of the token that is being burned
    function burn(uint256 tokenId) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Immutable state
/// @notice Functions that return immutable state of the router
interface IPeripheryImmutableState {
    /// @return Returns the address of the Uniswap V3 factory
    function factory() external view returns (address);

    /// @return Returns the address of WETH9
    function WETH9() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;

/// @title Periphery Payments
/// @notice Functions to ease deposits and withdrawals of ETH
interface IPeripheryPayments {
    /// @notice Unwraps the contract's WETH9 balance and sends it to recipient as ETH.
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing WETH9 from users.
    /// @param amountMinimum The minimum amount of WETH9 to unwrap
    /// @param recipient The address receiving ETH
    function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

    /// @notice Refunds any ETH balance held by this contract to the `msg.sender`
    /// @dev Useful for bundling with mint or increase liquidity that uses ether, or exact output swaps
    /// that use ether for the input amount
    function refundETH() external payable;

    /// @notice Transfers the full amount of a token held by this contract to recipient
    /// @dev The amountMinimum parameter prevents malicious contracts from stealing the token from users
    /// @param token The contract address of the token which will be transferred to `recipient`
    /// @param amountMinimum The minimum amount of token required for a transfer
    /// @param recipient The destination address of the token
    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) external payable;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

/// @title Creates and initializes V3 Pools
/// @notice Provides a method for creating and initializing a pool, if necessary, for bundling with other methods that
/// require the pool to exist.
interface IPoolInitializer {
    /// @notice Creates a new pool if it does not exist, then initializes if not initialized
    /// @dev This method can be bundled with others via IMulticall for the first action (e.g. mint) performed against a pool
    /// @param token0 The contract address of token0 of the pool
    /// @param token1 The contract address of token1 of the pool
    /// @param fee The fee amount of the v3 pool for the specified token pair
    /// @param sqrtPriceX96 The initial square root price of the pool as a Q64.96 value
    /// @return pool Returns the pool address based on the pair of tokens and fee, will return the newly created pool address if necessary
    function createAndInitializePoolIfNecessary(
        address token0,
        address token1,
        uint24 fee,
        uint160 sqrtPriceX96
    ) external payable returns (address pool);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Provides functions for deriving a pool address from the factory, tokens, and the fee
library PoolAddress {
    bytes32 internal constant POOL_INIT_CODE_HASH = 0xe34f199b19b2b4f47f68442619d555527d244f78a3297ea89325f843f87b8b54;

    /// @notice The identifying key of the pool
    struct PoolKey {
        address token0;
        address token1;
        uint24 fee;
    }

    /// @notice Returns PoolKey: the ordered tokens with the matched fee levels
    /// @param tokenA The first token of a pool, unsorted
    /// @param tokenB The second token of a pool, unsorted
    /// @param fee The fee level of the pool
    /// @return Poolkey The pool details with ordered token0 and token1 assignments
    function getPoolKey(
        address tokenA,
        address tokenB,
        uint24 fee
    ) internal pure returns (PoolKey memory) {
        if (tokenA > tokenB) (tokenA, tokenB) = (tokenB, tokenA);
        return PoolKey({token0: tokenA, token1: tokenB, fee: fee});
    }

    /// @notice Deterministically computes the pool address given the factory and PoolKey
    /// @param factory The Uniswap V3 factory contract address
    /// @param key The PoolKey
    /// @return pool The contract address of the V3 pool
    function computeAddress(address factory, PoolKey memory key) internal pure returns (address pool) {
        require(key.token0 < key.token1);
        pool = address(
            uint256(
                keccak256(
                    abi.encodePacked(
                        hex'ff',
                        factory,
                        keccak256(abi.encode(key.token0, key.token1, key.fee)),
                        POOL_INIT_CODE_HASH
                    )
                )
            )
        );
    }
}

