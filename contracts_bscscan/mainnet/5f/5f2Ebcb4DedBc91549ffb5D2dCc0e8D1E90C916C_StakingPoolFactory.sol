// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../Role/PoolCreator.sol";
import "./StakingPoolProxy.sol";
import "../interfaces/IRewardManager.sol";
import "../Distribution/USDRetriever.sol";

contract StakingPoolFactory is PoolCreator {
    ITotemToken public totemToken;
    IRewardManager public rewardManager;

    address public superAdmin;
    address public stakingPoolImplementationAdr;
    address public swapRouter;
    address public usdToken;
    uint256 public stakingPoolTaxRate;
    uint256 public minimumStakeAmount;

    /**
     * @param variables The StakingPoolProxy is created with these specs:
            variables[0] = launchDate
            variables[1] = maturityTime
            variables[2] = lockTime
            variables[3] = sizeAllocation
            variables[4] = stakeApr
            variables[5] = prizeAmount
            variables[6] = usdPrizeAmount
            variables[7] = potentialCollabReward
            variables[8] = collaborativeRange
            variables[9] = stakingPoolTaxRate
            variables[10] = minimumStakeAmount
     */
    event PoolCreated(
        address indexed pool,
        string wrappedTokenSymbol,
        string poolType,
        uint256[11] variables,
        uint256[8] ranks,
        uint256[8] percentages,
        bool isEnhancedEnabled
    );

    event NewStakingPoolImplemnetationWasSet();

    event NewSuperAdminWasSet();

    constructor (
        ITotemToken _totemToken,
        IRewardManager _rewardManager,
        address _swapRouter,
        address _usdToken,
        address _stakingPoolImplementation,
        address _superAdmin
    ){
        totemToken = _totemToken;
        rewardManager = _rewardManager;
        swapRouter = _swapRouter;
        usdToken = _usdToken;
        stakingPoolImplementationAdr = _stakingPoolImplementation;
        superAdmin = _superAdmin;
         
        stakingPoolTaxRate = 300;
    }

    /**
     * @notice creates a StakingPoolProxy for the  provided stakingPoolImplementationAdr
            and initializes it so that the pool is ready to be used.
       @param _variables The StakingPoolProxy is created with these specs:
            variables[0] = launchDate
            variables[1] = maturityTime
            variables[2] = lockTime
            variables[3] = sizeAllocation
            variables[4] = stakeApr
            variables[5] = prizeAmount
            variables[6] = usdPrizeAmount
            variables[7] = potentialCollabReward
            variables[8] = collaborativeRange
            variables[9] = stakingPoolTaxRate
            variables[10] = minimumStakeAmount
    */
    function createPoolProxy(
        address _oracleContract,
        address _wrappedTokenContract,
        string memory _wrappedTokenSymbol,
        string memory _poolType,
        uint256[11] memory _variables,
        uint256[8] memory _ranks,
        uint256[8] memory _percentages,
        bool isEnhancedEnabled
    ) external onlyPoolCreator returns (address) {
        
        require(
            _ranks.length == _percentages.length,
            "length of ranks and percentages should be same"
        );

        if (_variables[9] == 0) {
            _variables[9] = stakingPoolTaxRate;
        }

        StakingPoolProxy stakingPoolProxy = new StakingPoolProxy();
        address stakingPoolProxyAdr = address(stakingPoolProxy);

        stakingPoolProxy.upgradeTo(stakingPoolImplementationAdr);

        address[4] memory addrs = [swapRouter, usdToken, _oracleContract, _wrappedTokenContract];

        _createPool( 
            addrs, 
            _wrappedTokenSymbol, 
            _poolType, 
            _variables, 
            _ranks, 
            _percentages, 
            isEnhancedEnabled,
            stakingPoolProxy
        );

        stakingPoolProxy.transferOwnership(superAdmin);

        rewardManager.addPool(stakingPoolProxyAdr);

        return stakingPoolProxyAdr;
    }

    function _createPool(
        address[4] memory _addrs,
        string memory _wrappedTokenSymbol,
        string memory _poolType,
        uint256[11] memory _variables,
        uint256[8] memory _ranks,
        uint256[8] memory _percentages,
        bool _isEnhancedEnabled,
        StakingPoolProxy _stakingPoolProxy
    ) internal {
        _stakingPoolProxy.initialize(
            _wrappedTokenSymbol,
            _poolType,
            totemToken,
            rewardManager,
            _msgSender(),
            _addrs,
            _variables,
            _ranks,
            _percentages,
            _isEnhancedEnabled
        );

        address stakingPoolProxyAdr = address(_stakingPoolProxy);

        emit PoolCreated(
            stakingPoolProxyAdr,
            _wrappedTokenSymbol,
            _poolType,
            _variables,
            _ranks,
            _percentages,
            _isEnhancedEnabled
        );
    }

    /**
     * @notice This function is called whenever we want to use a new StakingPoolImplementation
            to create our proxies for.
     * @param _ImpAdr address of the new StakingPoolImplementation contract.
    */
    function setNewStakingPoolImplementationAdr(address _ImpAdr) external onlyPoolCreator {
        require(
            stakingPoolImplementationAdr != _ImpAdr, 
            'This address is the implementation that is already being used'
        );
        stakingPoolImplementationAdr = _ImpAdr;
        emit NewStakingPoolImplemnetationWasSet();
    }

    /**
     * @notice Changes superAdmin's address so that new StakingPoolProxies have this new superAdmin
    */
    function setNewSuperAdmin(address _superAdmin) external onlyPoolCreator {
        superAdmin = _superAdmin;
        emit NewSuperAdminWasSet();
    }

    function setSwapRouter(address _swapRouter) external onlyPoolCreator {
        require(_swapRouter != address(0), "0410");
        swapRouter = _swapRouter;
    }

    function setDefaultTaxRate(uint256 newStakingPoolTaxRate)
        external
        onlyPoolCreator
    {
        require(
            newStakingPoolTaxRate < 10000,
            "0420 Tax connot be over 100% (10000 BP)"
        );
        stakingPoolTaxRate = newStakingPoolTaxRate;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "./Roles.sol";

contract PoolCreator is Context {
    using Roles for Roles.Role;

    event PoolCreatorAdded(address indexed account);
    event PoolCreatorRemoved(address indexed account);

    Roles.Role private _poolCreators;

    constructor() {
        if (!isPoolCreator(_msgSender())) {
            _addPoolCreator(_msgSender());
        }
    }

    modifier onlyPoolCreator() {
        require(
            isPoolCreator(_msgSender()),
            "PoolCreatorRole: caller does not have the PoolCreator role"
        );
        _;
    }

    function isPoolCreator(address account) public view returns (bool) {
        return _poolCreators.has(account);
    }

    function addPoolCreator(address account) public onlyPoolCreator {
        _addPoolCreator(account);
    }

    function renouncePoolCreator() public {
        _removePoolCreator(_msgSender());
    }

    function _addPoolCreator(address account) internal {
        _poolCreators.add(account);
        emit PoolCreatorAdded(account);
    }

    function _removePoolCreator(address account) internal {
        _poolCreators.remove(account);
        emit PoolCreatorRemoved(account);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StakingPoolStorageStructure.sol";

contract StakingPoolProxy is StakingPoolStorageStructure {

    modifier onlyPoolCreator() {
        require (msg.sender == poolCreator, "msg.sender is not an owner");
        _;
    }

    event ImplementationUpgraded();

    /**
     * @dev poolCreator is set to the address of StakingPoolFactory here, but it will change
            to the address of the owner after initialize is called. This is to prevent any other
            entity other than the StakingPoolFactory to call initialize and upgradeTo (for the 
            first time).
            upgradeEnabled set to true so that upgradeTo can be called for the first time
            when the main impelementaiton is being set. 
    */
    constructor() {
        poolCreator = msg.sender;
        upgradeEnabled = true;
    }

    /**
     * @notice This is called in case we want to upgrade a working pool which inherits from
            the original implementation, to apply bug fixes and consider emergency cases.
    */
    function upgradeTo(address _newStakingPoolImplementation) external onlyPoolCreator {
        require(upgradeEnabled, "Upgrade is not enabled yet");
        require(
            stakingPoolImplementation != _newStakingPoolImplementation, 
            "Is already the implementation"
        );
        _setStakingPoolImplementation(_newStakingPoolImplementation);
        upgradeEnabled = false;
    }

    /**
     * @notice StakingPoolImplementation can't be upgraded unless superAdmin sets upgradeEnabled
     */
    function enableUpgrade() external onlyOwner{
        upgradeEnabled = true;
    }

    function disableUpgrade() external onlyOwner{
        upgradeEnabled = false;
    }

    /**
     * @notice The initializer modifier is used to make sure initialize() is not called 
            more than once because we want it to act like a constructor.
       @param _addrs Addresses used by priceConsumer and WrappedTokenDistributor
                _addrs[0] = swapRouterAddress
                _addrs[1] = BUSDContractAddress
                _addrs[2] = OracleAddress
                _addrs[3] = WrappedTokenContractAddress
    */
    function initialize(
        string memory _wrappedTokenSymbol,
        string memory _poolType,
        ITotemToken _totemToken,
        IRewardManager _rewardManager,
        address _poolCreator, 
        address[4] memory _addrs,
        uint256[11] memory _variables,
        uint256[8] memory _ranks,
        uint256[8] memory _percentages,
        bool _isEnhancedEnabled
    ) public initializer onlyPoolCreator
    {
        /// @dev we should call inits because we don't have a constructor to do it for us
        OwnableUpgradeable.__Ownable_init();
        ContextUpgradeable.__Context_init();
        
        PriceConsumerUpgradeable.__PriceConsumer_initialize(_addrs[2]);
        
        WrappedTokenDistributorUpgradeable.__WrappedTokenDistributor_initialize(
            _addrs[0],
            _addrs[1],
            _addrs[3]
        );

        require(
            _variables[0] > block.timestamp,
            "0301 launch date can't be in the past"
        );

        wrappedTokenSymbol = _wrappedTokenSymbol;
        poolType = _poolType;
        totemToken = _totemToken;
        rewardManager = _rewardManager;
        poolCreator = _poolCreator;
        setUSDToken(_addrs[1]);
        oracleContract = _addrs[2];        
        wrappedToken = IERC20(_addrs[3]);

        launchDate = _variables[0];
        maturityTime = _variables[1];
        lockTime = _variables[2];
        sizeAllocation = _variables[3];
        stakeApr = _variables[4];
        prizeAmount = _variables[5];
        usdPrizeAmount = _variables[6];
        potentialCollabReward = _variables[7];
        collaborativeRange = _variables[8];
        stakeTaxRate = _variables[9];
        minimumStakeAmount = _variables[10];   

        isEnhancedEnabled = _isEnhancedEnabled; 

        for (uint256 i = 0; i < _ranks.length; i++) {

            if (_percentages[i] == 0) break;

            prizeRewardRates.push(
                PrizeRewardRate({
                    rank: _ranks[i], 
                    percentage: _percentages[i]
                })
            );
        }

        /**
         * @notice LibParams are set here. Some of them may change in the lifetime of a pool
                which is also considered
        */ 
        lps.launchDate = launchDate;
        lps.lockTime = lockTime;
        lps.maturityTime = maturityTime;
        lps.maturingPrice = maturingPrice;
        lps.usdPrizeAmount = usdPrizeAmount;
        lps.prizeAmount = prizeAmount;
        lps.stakeApr = stakeApr;
        lps.collaborativeReward = collaborativeReward;
        lps.isEnhancedEnabled = isEnhancedEnabled;
        lps.isMatured = isMatured;
    }

    fallback() external payable {
        address opr = stakingPoolImplementation;
        require(opr != address(0));
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), opr, 0, calldatasize(), 0, 0)
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
    
    receive() external payable {}

    function _setStakingPoolImplementation(address _newStakingPool) internal {
        stakingPoolImplementation = _newStakingPool;
        emit ImplementationUpgraded();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IRewardManager {

    function setOperator(address _newOperator) external;

    function addPool(address _poolAddress) external;

    function rewardUser(address _user, uint256 _amount) external;

    event SetOperator(address operator);
    event SetRewarder(address rewarder);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract USDRetriever {
    IERC20 internal USDCContract;

    event ReceivedTokens(address indexed from, uint256 amount);
    event TransferTokens(address indexed to, uint256 amount);
    event ApproveTokens(address indexed to, uint256 amount);

    function setUSDToken(address _usdContractAddress) internal {
        USDCContract = IERC20(_usdContractAddress);
    }

    function approveTokens(address _to, uint256 _amount) internal {
        USDCContract.approve(_to, _amount);
        emit ApproveTokens(_to, _amount);
    }

    function getUSDBalance() external view returns (uint256) {
        return USDCContract.balanceOf(address(this));
    }

    function getUSDToken() external view returns (address) {
        return address(USDCContract);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account)
        internal
        view
        returns (bool)
    {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "../Distribution/USDRetriever.sol";
import "../Price/PriceConsumerUpgradeable.sol";
import "../Distribution/WrappedTokenDistributorUpgradeable.sol";

import "../libraries/BasisPoints.sol";
import "../libraries/CalculateRewardLib.sol";
import "../libraries/IndexedClaimRewardLib.sol";
import "../libraries/ClaimRewardLib.sol";

import "../interfaces/ITotemToken.sol";
import "../interfaces/IRewardManager.sol";

contract StakingPoolStorageStructure is 
    OwnableUpgradeable,  
    PriceConsumerUpgradeable,
    USDRetriever,
    WrappedTokenDistributorUpgradeable
{
    address public stakingPoolImplementation;
    address public poolCreator;
    address public oracleContract;

    /**
     * @notice Declared for passing the needed params to libraries.
     */
    struct LibParams {
        uint256 launchDate;
        uint256 lockTime;
        uint256 maturityTime;
        uint256 maturingPrice;
        uint256 usdPrizeAmount;
        uint256 prizeAmount;
        uint256 stakeApr;
        uint256 collaborativeReward;
        bool isEnhancedEnabled;
        bool isMatured;
    }

    struct StakeWithPrediction {
        uint256 stakedBalance;
        uint256 stakedTime;
        uint256 amountWithdrawn;
        uint256 lastWithdrawalTime;
        uint256 pricePrediction;
        uint256 difference;
        uint256 rank;
        bool prizeRewardWithdrawn;
        bool didUnstake;
    }

    struct Staker {
        address stakerAddress;
        uint256 index;
    }

    struct PrizeRewardRate {
        uint256 rank;
        uint256 percentage;
    }

    LibParams public lps;

    PrizeRewardRate[] public prizeRewardRates;
    Staker[] public stakers;
    Staker[] public sortedStakers;

    mapping(address => StakeWithPrediction[]) public predictions;

    ITotemToken public totemToken;
    IRewardManager public rewardManager;
    IERC20 public wrappedToken;

    string public wrappedTokenSymbol;
    string public poolType;

    uint256 public constant sizeLimitRangeRate = 5;
    uint256 public constant oracleDecimal = 8;

    uint256 public launchDate;
    uint256 public lockTime;
    uint256 public maturityTime;
    uint256 public sizeAllocation;
    uint256 public stakeApr;
    uint256 public prizeAmount;
    /**
     * @notice usdPrizeAmount is the enabler of WrappedToken rewarder; If it is set to 0 
            then the pool is only TOTM rewarder.
     */
    uint256 public usdPrizeAmount;
    uint256 public stakeTaxRate;
    uint256 public minimumStakeAmount;
    uint256 public totalStaked;
    uint256 public maturingPrice;
    uint256 public potentialCollabReward;
    uint256 public collaborativeRange;
    /**
     * @notice Based on the white paper, the collaborative reward can be 20% (2000),
             25% (2500) or 35% (3500).
     */
    uint256 public collaborativeReward; 

    bool public isAnEmergency;
    bool public isEnhancedEnabled;
    bool public isActive;
    bool public isLocked;
    bool public isMatured;
    bool public isDeleted;
    /**
     * @dev StakingPoolImplementation can't be upgraded unless superAdmin sets this flag.
     */
    bool public upgradeEnabled;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract PriceConsumerUpgradeable is Initializable {
    AggregatorV3Interface internal priceFeed;

    /**
     * @param _oracle The chainlink node oracle address to send requests
    */
    function __PriceConsumer_initialize(address _oracle) public initializer {
        priceFeed = AggregatorV3Interface(_oracle);
    }

    /**
     * @notice Returns decimals for oracle contract
    */
    function getDecimals() external view returns (uint8) {
        uint8 decimals = priceFeed.decimals();
        return decimals;
    }

    /**
     * @notice Returns the latest price from oracle contract
    */
    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();

        return price >= 0 ? uint256(price) : 0;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IPancakeRouter.sol";

contract WrappedTokenDistributorUpgradeable is Initializable{
    IPancakeRouter02 internal swapRouter;
    address internal BUSD_CONTRACT_ADDRESS;
    address internal WRAPPED_Token_CONTRACT_ADDRESS;

    event DistributedBTC(address indexed to, uint256 amount);

    function __WrappedTokenDistributor_initialize(
        address swapRouterAddress,
        address BUSDContractAddress,
        address WrappedTokenContractAddress
    ) public initializer {
        swapRouter = IPancakeRouter02(swapRouterAddress);
        BUSD_CONTRACT_ADDRESS = BUSDContractAddress;
        WRAPPED_Token_CONTRACT_ADDRESS = WrappedTokenContractAddress;
    }

    /**
     * @param _to Reciever address
     * @param _usdAmount USD Amount
     * @param _wrappedTokenAmount Wrapped Token Amount
     */
    function transferTokensThroughSwap(
        address _to,
        uint256 _usdAmount,
        uint256 _wrappedTokenAmount,
        uint256 _deadline
    ) internal {
        require(_to != address(0));
        // Get max USD price we can spend for this amount.
        swapRouter.swapExactTokensForTokens(
            _usdAmount,
            _wrappedTokenAmount,
            getPathForUSDToWrappedToken(),
            _to,
            _deadline
        );
    }

    /**
     * @param _amount Amount
     */
    function getEstimatedWrappedTokenForUSD(uint256 _amount)
        public
        view
        returns (uint256)
    {
        uint256[] memory wrappedTokenAmount =
            swapRouter.getAmountsOut(_amount, getPathForUSDToWrappedToken());
        // since in the path the wrappedToken is the second one, so we should retuen the second one also here    
        return wrappedTokenAmount[1];
    }

    function getPathForUSDToWrappedToken() public view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = BUSD_CONTRACT_ADDRESS;
        path[1] = WRAPPED_Token_CONTRACT_ADDRESS;

        return path;
    }

    // the function should be rename to getSwapRouter
    function getswapRouter() public view returns (address) {
        return address(swapRouter);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library BasisPoints {
    using SafeMath for uint256;

    uint256 private constant BASIS_POINTS = 10000;

    function mulBP(uint256 amt, uint256 bp) internal pure returns (uint256) {
        return amt.mul(bp).div(BASIS_POINTS);
    }

    function divBP(uint256 amt, uint256 bp) internal pure returns (uint256) {
        require(bp > 0, "Cannot divide by zero.");
        return amt.mul(BASIS_POINTS).div(bp);
    }

    function addBP(uint256 amt, uint256 bp) internal pure returns (uint256) {
        if (amt == 0) return 0;
        if (bp == 0) return amt;
        return amt.add(mulBP(amt, bp));
    }

    function subBP(uint256 amt, uint256 bp) internal pure returns (uint256) {
        if (amt == 0) return 0;
        if (bp == 0) return amt;
        return amt.sub(mulBP(amt, bp));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../libraries/BasisPoints.sol";
import "../Staking/StakingPoolStorageStructure.sol";

library CalculateRewardLib {

    using BasisPoints for uint256;
    using SafeMath for uint256;

    uint256 public constant oracleDecimal = 8;

    function getTotalStakedBalance(StakingPoolStorageStructure.StakeWithPrediction[] storage _staker)
        public
        view
        returns (uint256)
    {
        if (_staker.length == 0) return 0;

        uint256 totalStakedBalance = 0;
        for (uint256 i = 0; i < _staker.length; i++) {
            if (!_staker[i].didUnstake) {
                totalStakedBalance = totalStakedBalance.add(
                    _staker[i].stakedBalance
                );
            }
        }

        return totalStakedBalance;
    }

    /**
     * @notice the reward formula is:
          ((1 + stakeAPR +enhancedReward)^((MaturingDate - StakingDate)/365) - 1) * StakingBalance
    */
    function _getStakingRewardPerStake(
        StakingPoolStorageStructure.StakeWithPrediction[] storage _staker, 
        uint256 _stakeIndex,
        StakingPoolStorageStructure.LibParams storage _lps
    )
        internal
        view
        returns (uint256)
    {
        uint256 maturityDate = 
            _lps.launchDate + 
            _lps.lockTime + 
            _lps.maturityTime;

        uint256 timeTo =
            block.timestamp > maturityDate ? maturityDate : block.timestamp;

        uint256 enhancedApr;
        if ( _lps.isEnhancedEnabled ) {
            enhancedApr = _getEnhancedRewardRate(
                _staker[_stakeIndex].stakedTime,
                _lps
            );
        }

        uint256 rewardPerStake = _calcStakingReturn(
            _lps.stakeApr.add(enhancedApr),
            timeTo.sub(_staker[_stakeIndex].stakedTime),
            _staker[_stakeIndex].stakedBalance
        );

        rewardPerStake = rewardPerStake.sub(_staker[_stakeIndex].amountWithdrawn);

        return rewardPerStake;
    }

    function _getEnhancedRewardRate(
        uint256 stakedTime,
        StakingPoolStorageStructure.LibParams storage _lps
    )
        internal
        view
        returns (uint256)
    {

        if (!_lps.isEnhancedEnabled) {
            return 0;
        }

        uint256 lockDate = _lps.launchDate.add(_lps.lockTime);
        uint256 difference = lockDate.sub(stakedTime);

        if (difference < 48 hours) {
            return 0;
        } else if (difference < 72 hours) {
            return 100;
        } else if (difference < 96 hours) {
            return 200;
        } else if (difference < 120 hours) {
            return 300;
        } else if (difference < 144 hours) {
            return 400;
        } else {
            return 500;
        }
    }

    function _calcStakingReturn(uint256 totalRewardRate, uint256 timeDuration, uint256 totalStakedBalance) 
        internal 
        pure
        returns (uint256) 
    {
        uint256 yearInSeconds = 365 days;

        uint256 first = (yearInSeconds**2)
            .mul(10**8);

        uint256 second = timeDuration
            .mul(totalRewardRate) 
            .mul(yearInSeconds)
            .mul(5000);
        
        uint256 third = totalRewardRate
            .mul(yearInSeconds**2)
            .mul(5000);

        uint256 forth = (timeDuration**2)
            .mul(totalRewardRate**2)
            .div(6);

        uint256 fifth = timeDuration
            .mul(totalRewardRate**2)
            .mul(yearInSeconds)
            .div(2);

        uint256 sixth = (totalRewardRate**2)
            .mul(yearInSeconds**2)
            .div(3);
 
        uint256 rewardPerStake = first.add(second).add(forth).add(sixth);

        rewardPerStake = rewardPerStake.sub(third).sub(fifth);

        rewardPerStake = rewardPerStake
            .mul(totalRewardRate)
            .mul(timeDuration);

        rewardPerStake = rewardPerStake
            .mul(totalStakedBalance)
            .div(yearInSeconds**3)
            .div(10**12);

        return rewardPerStake; 
    }

    function _getPercentageReward(
        uint256 _rank, 
        StakingPoolStorageStructure.PrizeRewardRate[] storage _prizeRewardRates
    )
        internal
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < _prizeRewardRates.length; i++) {
            if (_rank <= _prizeRewardRates[i].rank) {
                return _prizeRewardRates[i].percentage;
            }
        }

        return 0;
    }        



}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./CalculateRewardLib.sol";
import "../libraries/BasisPoints.sol";
import "../Staking/StakingPoolStorageStructure.sol";

library IndexedClaimRewardLib {

    using CalculateRewardLib for *;
    using BasisPoints for uint256; 
    using SafeMath for uint256;

    uint256 public constant oracleDecimal = 8;

    function withdrawIndexedStakingReturn(
        StakingPoolStorageStructure.StakeWithPrediction[] storage _staker, 
        uint256 _stakeIndex,
        StakingPoolStorageStructure.LibParams storage _lps
    ) 
        public
    {
        if (_staker.length == 0) return;
        if (_stakeIndex >= _staker.length) return;

        uint256 rewardPerStake = CalculateRewardLib._getStakingRewardPerStake(
            _staker, 
            _stakeIndex,
            _lps
        );

        _staker[_stakeIndex].lastWithdrawalTime = block.timestamp;
        _staker[_stakeIndex].amountWithdrawn = _staker[_stakeIndex].amountWithdrawn.add(
            rewardPerStake
        );
    }

    function withdrawIndexedPrize(
        StakingPoolStorageStructure.StakeWithPrediction[] storage _staker, 
        uint256 _stakeIndex
    ) 
        public 
    {
        if (_staker.length == 0) return;
        if (_staker[_stakeIndex].prizeRewardWithdrawn) return;

        _staker[_stakeIndex].prizeRewardWithdrawn = true;
    }

    function withdrawIndexedStakedBalance(
        StakingPoolStorageStructure.StakeWithPrediction[] storage _staker, 
        uint256 _stakeIndex
    ) 
        public
    {
        if (_staker.length == 0) return;
        if (_stakeIndex >= _staker.length) return;

        _staker[_stakeIndex].didUnstake = true;
    }

    function getIndexedStakedBalance(
        StakingPoolStorageStructure.StakeWithPrediction[] storage _staker, 
        uint256 _stakeIndex
    )
        public
        view
        returns (uint256)
    {
        if (_staker.length == 0) return 0;
        if (_stakeIndex >= _staker.length) return 0; 

        uint256 totalStakedBalance = 0;

        if (!_staker[_stakeIndex].didUnstake) {
            totalStakedBalance = totalStakedBalance.add(
                _staker[_stakeIndex].stakedBalance
            );
        }

        return totalStakedBalance;
    }

    function getIndexedStakingReturn(
        StakingPoolStorageStructure.StakeWithPrediction[] storage _staker, 
        uint256 _stakeIndex,
        StakingPoolStorageStructure.LibParams storage _lps
    ) 
        public
        view 
        returns (uint256) 
    {
        if (_staker.length == 0) return 0;
        if (_stakeIndex >= _staker.length) return 0;

        uint256 reward = 0;
        
        uint256 rewardPerStake = CalculateRewardLib._getStakingRewardPerStake(
            _staker, 
            _stakeIndex,
            _lps
        );
        reward = reward.add(rewardPerStake);

        return reward;
    }

    function getIndexedPrize(
        StakingPoolStorageStructure.StakeWithPrediction[] storage _staker, 
        uint256 _stakeIndex,
        StakingPoolStorageStructure.LibParams storage _lps,
        StakingPoolStorageStructure.PrizeRewardRate[] storage _prizeRewardRates
    )
        public
        view
        returns (uint256, uint256)
    {
        if (!_lps.isMatured) return (0, 0);

        if (_staker.length == 0) return (0, 0);

        if (_stakeIndex >= _staker.length) return (0,0);

        if (_staker[_stakeIndex].prizeRewardWithdrawn) return (0, 0);

        uint256 maturingWrappedTokenPrizeAmount =
            (_lps.usdPrizeAmount.mul(10**oracleDecimal)).div(_lps.maturingPrice);

        uint256 reward = 0;
        uint256 wrappedTokenReward = 0;

        uint256 _percent = CalculateRewardLib._getPercentageReward(
            _staker[_stakeIndex].rank,
            _prizeRewardRates
        );

        reward = reward.add(
                        _lps.prizeAmount.mulBP(_percent)
                    );

        wrappedTokenReward = wrappedTokenReward.add(
                        maturingWrappedTokenPrizeAmount
                            .mulBP(_percent)
                    );            

        if (_lps.collaborativeReward > 0) {
            reward = reward.addBP(_lps.collaborativeReward);
            wrappedTokenReward = wrappedTokenReward.addBP(_lps.collaborativeReward);
        }

        return (reward, wrappedTokenReward);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./CalculateRewardLib.sol";
import "../libraries/BasisPoints.sol";
import "../Staking/StakingPoolStorageStructure.sol";

library ClaimRewardLib {

    using CalculateRewardLib for *;
    using BasisPoints for uint256; 
    using SafeMath for uint256;

    uint256 public constant oracleDecimal = 8;

    function withdrawStakingReturn(
        StakingPoolStorageStructure.StakeWithPrediction[] storage _staker,
        StakingPoolStorageStructure.LibParams storage _lps
    )
        public 
    {
        
        if (_staker.length == 0) return;

        for (uint256 i = 0; i < _staker.length; i++) {
            uint256 rewardPerStake = CalculateRewardLib._getStakingRewardPerStake(
                _staker, 
                i, 
                _lps);

            _staker[i].lastWithdrawalTime = block.timestamp;
            _staker[i].amountWithdrawn = _staker[i].amountWithdrawn.add(
                rewardPerStake
            );
        }
    }

    function withdrawPrize(
        StakingPoolStorageStructure.StakeWithPrediction[] storage _staker
    ) 
        public
    {
        if (_staker.length == 0) return;

        for (uint256 i = 0; i < _staker.length; i++) {
            _staker[i].prizeRewardWithdrawn = true;
        }
    }

    function withdrawStakedBalance(
        StakingPoolStorageStructure.StakeWithPrediction[] storage _staker
    )
        public 
    {
        
        if (_staker.length == 0) return;

        for (uint256 i = 0; i < _staker.length; i++) {
            _staker[i].didUnstake = true;
        }
    }

    function getStakingReturn(
        StakingPoolStorageStructure.StakeWithPrediction[] storage _staker,
        StakingPoolStorageStructure.LibParams storage _lps  
    ) 
        public 
        view 
        returns (uint256) 
    {
        if (_staker.length == 0) return 0;

        uint256 reward = 0;
        for (uint256 i = 0; i < _staker.length; i++) {
            uint256 rewardPerStake = CalculateRewardLib._getStakingRewardPerStake(
                _staker,
                i, 
                _lps
            );

            reward = reward.add(rewardPerStake);
        }

        return reward;
    }

    function getPrize(
        StakingPoolStorageStructure.StakeWithPrediction[] storage _staker, 
        StakingPoolStorageStructure.LibParams storage _lps,
        StakingPoolStorageStructure.PrizeRewardRate[] storage _prizeRewardRates
    )
        public
        view
        returns (uint256, uint256)
    {
        if (!_lps.isMatured) return (0, 0);

        if (_staker.length == 0) return (0, 0);

        uint256 maturingWrappedTokenPrizeAmount =
            (_lps.usdPrizeAmount.mul(10**oracleDecimal)).div(_lps.maturingPrice);

        uint256 reward = 0;
        uint256 wrappedTokenReward = 0;

        for (uint256 i = 0; i < _staker.length; i++) {
            if (!_staker[i].prizeRewardWithdrawn) {

                uint256 _percent = CalculateRewardLib._getPercentageReward(
                    _staker[i].rank,
                    _prizeRewardRates
                );

                reward = reward.add(
                            _lps.prizeAmount.mulBP(_percent)
                        );

                wrappedTokenReward = wrappedTokenReward.add(
                            maturingWrappedTokenPrizeAmount
                                .mulBP(_percent)
                        );        
            }
        }

        if (_lps.collaborativeReward > 0) {
            reward = reward.addBP(_lps.collaborativeReward);
            wrappedTokenReward = wrappedTokenReward.addBP(_lps.collaborativeReward);
        }

        return (reward, wrappedTokenReward);
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ITotemToken {
    
    function setLocker(address _locker) external;

    function setDistributionTeamsAddresses(
        address _CommunityDevelopmentAddr,
        address _StakingRewardsAddr,
        address _LiquidityPoolAddr,
        address _PublicSaleAddr,
        address _AdvisorsAddr,
        address _SeedInvestmentAddr,
        address _PrivateSaleAddr,
        address _TeamAllocationAddr,
        address _StrategicRoundAddr
    ) external;

    function distributeTokens() external;

    function setTaxRate(uint256 newTaxRate) external;

    function setTaxExemptStatus(address account, bool status) external;

    function setTaxationWallet(address newTaxationWallet) external;


    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function taxRate() external returns (uint256);

    function taxationWallet() external returns (address);

    function taxExempt(address _msgSender) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPancakeRouter01 {
    function factory() external view returns (address);

    function WETH() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}