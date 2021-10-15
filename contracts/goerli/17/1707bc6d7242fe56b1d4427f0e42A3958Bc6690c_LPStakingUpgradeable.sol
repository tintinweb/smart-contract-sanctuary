// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

import "@openzeppelin/contracts/proxy/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts-upgradeable/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import "../lib/access/OwnableUpgradeable.sol";
import "../lib/util/ArrayUtil.sol";
import "../NFT/base/IBaseNftUpgradeable.sol";
import "../NFT/base/IMultiModelNftUpgradeable.sol";
import "../PriceOracle/IPriceOracleUpgradeable.sol";

contract LPStakingUpgradeable is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using AddressUpgradeable for address;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    /* 
    Basically, any point in time, the amount of ZONEs entitled to a user but is pending to be distributed is:
    
    pending ZONE = (user.lpAmount * pool.accZONEPerLP) - user.finishedZONE
    
    Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
    1. The pool's `accZONEPerLP` (and `lastRewardTime`) gets updated.
    2. User receives the pending ZONE sent to his/her address.
    3. User's `lpAmount` gets updated.
    4. User's `finishedZONE` gets updated.
    */
    struct Pool {
        // Address of LP token
        address lpTokenAddress;
        // Total amount deposited
        uint256 lpSupply;
        // Weight of pool
        uint256 poolWeight;
        // Last block timestamp that ZONEs distribution occurs for pool
        uint256 lastRewardTime;
        // Accumulated ZONEs per LP of pool
        uint256 accZONEPerLP; 
        // Pool ID of this pool
        uint256 pid;
    }

    struct User {
        // LP token amount that user provided
        uint256 lpAmount;     
        // Finished distributed ZONEs to user
        uint256 finishedZONE;
        // Timestamp of the deposit at the time that lpAmount is zero, or the timestamp of the last withdrawal. The locked period is calculated from this timestamp
        uint256 lockStartTime;
    }

    uint256 private constant SECONDS_IN_DAY = 24 * 3600;

    uint256 private constant LP_LOCKED_AMOUNT = 5856918985268619881152;
    uint256 private constant LP_UNLOCK_DATE = 1661997600;

    // Total pool weight / Sum of all pool weights
    uint256 public totalPoolWeight;
    // Array of pools
    Pool[] public pool;
    // LP token => pool
    mapping (address => Pool) public poolMap;

    // pool id => user address => user info
    mapping (uint256 => mapping (address => User)) public user;
    // Minimum deposit amount in ETH
    uint256 public minDepositAmountInEth;

    bool public rewardInZoneEnabled;
    bool public rewardInNftEnabled;
    bool private _lpUnlockedFromUniswapV2Locker;

    // First block that DAOstake will start from
    uint256 public START_TIME;
    // Locking period to get reward
    uint256 public lockPeriod;
    // ZONE tokens distributed per block.
    uint256 public zonePerMinute;

    // ZONE amount finished by changing ZONE per minute
    uint256 private _totalFinishedZONE;
    // Last block timestamp that _totalFinishedZONE updated
    uint256 private _lastFinishUpdateTime;
    // ZONE tokens which not distributed because there are no depositor
    uint256 public unusedZone;

    // Addresse of NFT contract to reward
    address[] public nftAddresses;
    // Model id of the NFT to reward. If the NFT doesn't have a model, the value is uint256.max
    uint256[] public nftModels;
    // Price in ETH. This arrays is expected to be sorted in ascending order, and to contain no repeated elements.
    uint256[] public nftPrices;

    IERC20Upgradeable public zoneToken;
    IPriceOracleUpgradeable public priceOracle;

    address public governorTimelock;

    event SetLockPeriod(uint256 newLockPeriod);
    event SetZonePerMinute(uint256 newZonePerMinute);
    event SetMinDepositAmountInEth(uint256 newMinDepositAmountInEth);
    event EnableRewardInZone(bool enabled);
    event EnableRewardInNft(bool enabled);
    event AddPool(address indexed lpTokenAddress, uint256 indexed poolWeight, uint256 indexed lastRewardTime);
    event SetPoolWeight(uint256 indexed poolId, uint256 indexed poolWeight, uint256 totalPoolWeight);
    event UpdatePool(uint256 indexed poolId, uint256 indexed lastRewardTime, uint256 rewardToPool);
    event Deposit(address indexed account, uint256 indexed poolId, uint256 amount);
    event Withdraw(address indexed account, uint256 indexed poolId, uint256 amount);
    event RewardZone(address indexed account, uint256 indexed poolId, uint256 amount);
    event RewardNft(address indexed account, uint256 indexed poolId, address indexed rewardNftAddress, uint256 rewardNftModel, uint256 rewardNftPrice);
    event RemoveRewardNft(address indexed rewardNftAddress, uint256 indexed rewardNftModel, uint256 indexed rewardNftPrice);
    event EmergencyWithdraw(address indexed account, uint256 indexed poolId, uint256 amount);

    modifier onlyOwnerOrCommunity() {
        address sender = _msgSender();
        require((owner() == sender) || (governorTimelock == sender), "The caller should be owner or governor");
        _;
    }

    /**
     * @notice Initializes the contract.
     * @param _ownerAddress Address of owner
     * @param _priceOracle Library contract for the mint price
     * @param _zonePerMinute ZONE tokens distributed per block
     * @param _minDepositAmountInEth Minimum deposit amount in ETH
     * @param _nftAddresses Addresse of NFT contract
     * @param _nftModels Model id of the NFT. If the NFT doesn't have a model, the value is uint256.max
     * @param _nftPrices Price in ETH. This arrays is expected to be sorted in ascending order, and to contain no repeated elements.
     */
    function initialize(
        address _ownerAddress,
        address _priceOracle,
        uint256 _zonePerMinute,
        uint256 _minDepositAmountInEth,
        address[] memory _nftAddresses,
        uint256[] memory _nftModels,
        uint256[] memory _nftPrices
    ) public initializer {
        require(_ownerAddress != address(0), "Owner address is invalid");
        require(_priceOracle != address(0), "Price oracle address is invalid");

        __Ownable_init(_ownerAddress);
        __ReentrancyGuard_init();

        rewardInZoneEnabled = true;
        rewardInNftEnabled = true;

        lockPeriod = 180 * SECONDS_IN_DAY; // 180 days by default
        START_TIME = block.timestamp;
        _lastFinishUpdateTime = START_TIME;

        priceOracle = IPriceOracleUpgradeable(_priceOracle);
        zoneToken = IERC20Upgradeable(priceOracle.zoneToken());
        zonePerMinute = _zonePerMinute;
        minDepositAmountInEth = _minDepositAmountInEth;
        _setRewardNfts(_nftAddresses, _nftModels, _nftPrices);

        _addPool(address(priceOracle.lpZoneEth()), 100, false);
        pool[0].lpSupply = LP_LOCKED_AMOUNT;
    }

    function setGovernorTimelock(address _governorTimelock) external onlyOwner()  {
        governorTimelock = _governorTimelock;
    }

    /* Update the locking period */
    function setLockPeriod(uint256 _lockPeriod) external onlyOwnerOrCommunity() {
        // require(SECONDS_IN_DAY * 30 <= _lockPeriod, "lockDay should be equal or greater than 30 day");
        lockPeriod = _lockPeriod;
        emit SetLockPeriod(lockPeriod);
    }

    /* Update ZONE tokens per block */
    function setZonePerMinute(uint256 _zonePerMinute) external onlyOwnerOrCommunity() {
        _setZonePerMinute(_zonePerMinute);
    }

    function _setZonePerMinute(uint256 _zonePerMinute) private {
        massUpdatePools();

        uint256 multiplier = _getMultiplier(_lastFinishUpdateTime, block.timestamp);
        _totalFinishedZONE = _totalFinishedZONE.add(multiplier.mul(zonePerMinute));
        _lastFinishUpdateTime = block.timestamp;

        zonePerMinute = _zonePerMinute;
        emit SetZonePerMinute(zonePerMinute);
    }

    /* Update the locking period */
    function setMinDepositAmountInEth(uint256 _minDepositAmountInEth) external onlyOwnerOrCommunity() {
        minDepositAmountInEth = _minDepositAmountInEth;
        emit SetMinDepositAmountInEth(minDepositAmountInEth);
    }

    /* Finish the rewarding */
    function finish() external onlyOwnerOrCommunity() {
        if (0 < zonePerMinute) {
            _setZonePerMinute(0);
        }
        uint256 length = poolLength();
        for (uint256 pid = 0; pid < length; pid++) {
            Pool memory pool_ = pool[pid];
            if (0 < pool_.lpSupply) {
                return;
            }
        }
        uint256 zoneBalance = zoneToken.balanceOf(address(this));
        if (0 < zoneBalance) {
            zoneToken.safeTransfer(owner(), zoneBalance);
        }
    }

    function enableRewardInZone(bool _enable) external onlyOwnerOrCommunity() {
        rewardInZoneEnabled = _enable;
        emit EnableRewardInZone(rewardInZoneEnabled);
    }

    function enableRewardInNft(bool _enable) external onlyOwnerOrCommunity() {
        rewardInNftEnabled = _enable;
        emit EnableRewardInNft(rewardInNftEnabled);
    }

    /**
     * @notice Set the array of NFTs to reward.
     * @param _contractAddresses Addresse of NFT contract
     * @param _modelIds Model id of the NFT. If the NFT doesn't have a model, the value is uint256.max
     * @param _pricesInEth Price in ETH. This arrays is expected to be sorted in ascending order, and to contain no repeated elements.
     */
    function setRewardNfts(
        address[] memory _contractAddresses,
        uint256[] memory _modelIds,
        uint256[] memory _pricesInEth
    ) external onlyOwner() {
        _setRewardNfts(_contractAddresses, _modelIds, _pricesInEth);
    }

    function _setRewardNfts(
        address[] memory _contractAddresses,
        uint256[] memory _modelIds,
        uint256[] memory _pricesInEth
    ) internal {
        require(
            _contractAddresses.length == _modelIds.length
            && _contractAddresses.length == _pricesInEth.length,
            "Mismatched data"
        );

        nftAddresses = _contractAddresses;
        nftModels = _modelIds;
        nftPrices = _pricesInEth;
    }

    /** 
     * @notice Return reward multiplier over given _from to _to block. [_from, _to)
     * 
     * @param _from    From block timestamp (included)
     * @param _to      To block timestamp (exluded)
     */
    function _getMultiplier(uint256 _from, uint256 _to) internal pure returns(uint256 multiplier) {
        return _to.sub(_from).div(60);
    }

    /** 
     * @notice Get pending ZONE amount of user in pool
     */
    function pendingZONE(uint256 _pid, address _account) public view returns(uint256) {
        Pool storage pool_ = pool[_pid];
        if (pool_.lpSupply == 0) {
            // If lpSupply is zero, it means that the user's lpAmount is also zero.
            return 0;
        }

        User storage user_ = user[_pid][_account];
        uint256 accZONEPerLP = pool_.accZONEPerLP;

        if (pool_.lastRewardTime < block.timestamp) {
            uint256 multiplier = _getMultiplier(pool_.lastRewardTime, block.timestamp);
            uint256 rewardToPool = multiplier.mul(zonePerMinute).mul(pool_.poolWeight).div(totalPoolWeight);
            accZONEPerLP = accZONEPerLP.add(rewardToPool.mul(1 ether).div(pool_.lpSupply));
        }

        return user_.lpAmount.mul(accZONEPerLP).div(1 ether).sub(user_.finishedZONE);
    }

    /**
     * @notice return the total finished ZONE amount
     */
    function totalFinishedZONE() public view returns(uint256) {
        uint256 multiplier = _getMultiplier(_lastFinishUpdateTime, block.timestamp);
        return _totalFinishedZONE.add(multiplier.mul(zonePerMinute));
    }

    /**
     * @notice Get the length/amount of pool
     */
    function poolLength() public view returns(uint256) {
        return pool.length;
    }

    /** 
     * @notice Add a new LP to pool. Can only be called by owner
     * DO NOT add the same LP token more than once. ZONE rewards will be messed up if you do
     */
    function addPool(address _lpTokenAddress, uint256 _poolWeight, bool _withUpdate) external onlyOwner() {
        _addPool(_lpTokenAddress, _poolWeight, _withUpdate);
    }

    function _addPool(address _lpTokenAddress, uint256 _poolWeight, bool _withUpdate) private {
        require(_lpTokenAddress.isContract(), "LP token address should be smart contract address");
        require(poolMap[_lpTokenAddress].lpTokenAddress == address(0), "LP token already added");

        if (_withUpdate) {
            massUpdatePools();
        }
        
        uint256 lastRewardTime = START_TIME < block.timestamp ? block.timestamp : START_TIME;
        totalPoolWeight = totalPoolWeight + _poolWeight;

        Pool memory newPool_ = Pool({
            lpTokenAddress: _lpTokenAddress,
            lpSupply: 0,
            poolWeight: _poolWeight,
            lastRewardTime: lastRewardTime,
            accZONEPerLP: 0,
            pid: poolLength()
        });

        pool.push(newPool_);
        poolMap[_lpTokenAddress] = newPool_;

        emit AddPool(_lpTokenAddress, _poolWeight, lastRewardTime);
    }

    /** 
     * @notice Update the given pool's weight. Can only be called by owner.
     */
    function setPoolWeight(uint256 _pid, uint256 _poolWeight, bool _withUpdate) external onlyOwnerOrCommunity() {
        if (_withUpdate) {
            massUpdatePools();
        }

        totalPoolWeight = totalPoolWeight.sub(pool[_pid].poolWeight).add(_poolWeight);
        pool[_pid].poolWeight = _poolWeight;

        emit SetPoolWeight(_pid, _poolWeight, totalPoolWeight);
    }

    /**
     * @notice Update reward variables of the given pool to be up-to-date.
     */
    function updatePool(uint256 _pid) public {
        Pool storage pool_ = pool[_pid];
        if (block.timestamp <= pool_.lastRewardTime) {
            return;
        }

        uint256 multiplier = _getMultiplier(pool_.lastRewardTime, block.timestamp);
        uint256 rewardToPool = multiplier.mul(zonePerMinute).mul(pool_.poolWeight).div(totalPoolWeight);

        if (0 < pool_.lpSupply) {
            pool_.accZONEPerLP = pool_.accZONEPerLP.add(rewardToPool.mul(1 ether).div(pool_.lpSupply));
        } else {
            unusedZone = unusedZone.add(rewardToPool);
        }

        if (_pid == 0 && _lpUnlockedFromUniswapV2Locker == false && LP_UNLOCK_DATE < block.timestamp) {
            // LP tokens unlocked in UniswapV2Locker.
            pool_.lpSupply = pool_.lpSupply.sub(LP_LOCKED_AMOUNT);
            _lpUnlockedFromUniswapV2Locker = true;
        }

        pool_.lastRewardTime = block.timestamp;
        emit UpdatePool(_pid, pool_.lastRewardTime, rewardToPool);
    }

    /** 
     * @notice Update reward variables for all pools. Be careful of gas spending!
     * Due to gas limit, please make sure here no significant amount of pools!
     */
    function massUpdatePools() public {
        uint256 length = poolLength();
        for (uint256 pid = 0; pid < length; pid++) {
            updatePool(pid);
        }
    }

    function _getClaimIn(uint256 _lockStartTime) internal view returns(uint256) {
        uint256 endTs = _lockStartTime.add(lockPeriod);
        return (block.timestamp < endTs) ? endTs - block.timestamp : 0;
    }

    function _chooseRewardNft(uint256 _zoneAmount) internal view returns(bool, uint256) {
        uint256 rewardAmountInEth = priceOracle.getOutAmount(address(zoneToken), _zoneAmount);
        (bool found, uint256 index) = ArrayUtil.findLowerBound(nftPrices, rewardAmountInEth);
        return (found, index);
    }

    function getStakeInfo(uint256 _pid, address _account) external view returns (
        uint256 stakedAmount,
        uint256 claimIn,
        uint256 rewardAmount,
        address rewardNftAddress,
        uint256 rewardNftModel,
        uint256 rewardNftPrice
    ) {
        User storage user_ = user[_pid][_account];
        if (user_.lpAmount == 0) {
            return (0, 0, 0, address(0), 0, 0);
        }

        stakedAmount = user_.lpAmount;
        claimIn = _getClaimIn(user_.lockStartTime);
        rewardAmount = pendingZONE(_pid, _account);

        (bool found, uint256 index) = _chooseRewardNft(rewardAmount);
        if (found == true) {
            rewardNftAddress = nftAddresses[index];
            rewardNftModel = nftModels[index];
            rewardNftPrice = nftPrices[index];
        }
    }

    function getMinDepositLpAmount() public view returns(uint256) {
        uint256 lpPriceInEth = priceOracle.getLPFairPrice();
        return (0 < minDepositAmountInEth && 0 < lpPriceInEth) ? minDepositAmountInEth.mul(1e18).div(lpPriceInEth) : 0;
    }

    /** 
     * @notice Deposit LP tokens for ZONE rewards
     * Before depositing, user needs approve this contract to be able to spend or transfer their LP tokens
     *
     * @param _pid       Id of the pool to be deposited to
     * @param _amount    Amount of LP tokens to be deposited
     */
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant() {
        require(0 < _pid || minDepositAmountInEth == 0 || getMinDepositLpAmount() <= _amount, "The worth of LP amount should greater than minimum value");

        address _account = _msgSender();
        Pool storage pool_ = pool[_pid];
        User storage user_ = user[_pid][_account];

        updatePool(_pid);

        uint256 pendingZONE_;
        if (user_.lpAmount > 0) {
            // Reward will be transferred in the withdrawal and claiming
            pendingZONE_ = user_.lpAmount.mul(pool_.accZONEPerLP).div(1 ether).sub(user_.finishedZONE);
        } else {
            user_.lockStartTime = block.timestamp;
        }

        if(_amount > 0) {
            uint256 prevSupply = IERC20Upgradeable(pool_.lpTokenAddress).balanceOf(address(this));
            IERC20Upgradeable(pool_.lpTokenAddress).safeTransferFrom(_account, address(this), _amount);
            uint256 newSupply = IERC20Upgradeable(pool_.lpTokenAddress).balanceOf(address(this));
            uint256 depositedAmount = newSupply.sub(prevSupply);
            user_.lpAmount = user_.lpAmount.add(depositedAmount);
            pool_.lpSupply = pool_.lpSupply.add(depositedAmount);
        }

        user_.finishedZONE = user_.lpAmount.mul(pool_.accZONEPerLP).div(1 ether).sub(pendingZONE_);
        emit Deposit(_account, _pid, _amount);
    }

    /** 
     * @notice Withdraw LP tokens
     *
     * @param _pid       Id of the pool to be withdrawn from
     * @param _amount    amount of LP tokens to be withdrawn
     */
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant() {
        address _account = _msgSender();
        Pool storage pool_ = pool[_pid];
        User storage user_ = user[_pid][_account];
        require(_amount <= user_.lpAmount, "Not enough LP token balance");

        updatePool(_pid);

        uint256 pendingZONE_ = user_.lpAmount.mul(pool_.accZONEPerLP).div(1 ether).sub(user_.finishedZONE);
        uint256 claimIn = _getClaimIn(user_.lockStartTime);
        if(0 < pendingZONE_ && claimIn == 0) {
            _reward(_pid, _account, pendingZONE_);
            pendingZONE_ = 0;
        } else if(0 < _amount) {
            // remove pending amount related to the withdrawing share
            pendingZONE_ = pendingZONE_.mul(user_.lpAmount.sub(_amount)).div(user_.lpAmount);
        }
        user_.lockStartTime = block.timestamp;

        if(0 < _amount) {
            pool_.lpSupply = pool_.lpSupply.sub(_amount);
            user_.lpAmount = user_.lpAmount.sub(_amount);
            IERC20Upgradeable(pool_.lpTokenAddress).safeTransfer(_account, _amount);
        }

        user_.finishedZONE = user_.lpAmount.mul(pool_.accZONEPerLP).div(1 ether).sub(pendingZONE_);
        emit Withdraw(_account, _pid, _amount);
    }

    /** 
     * @notice Claim rewards
     *
     * @param _pid       Id of the pool to be withdrawn from
     */
    function claim(uint256 _pid) external nonReentrant() {
        address _account = _msgSender();
        Pool storage pool_ = pool[_pid];
        User storage user_ = user[_pid][_account];

        updatePool(_pid);

        uint256 pendingZONE_ = user_.lpAmount.mul(pool_.accZONEPerLP).div(1 ether).sub(user_.finishedZONE);
        require(0 < pendingZONE_, "No pending ZONE to reward");

        uint256 claimIn = _getClaimIn(user_.lockStartTime);
        require(claimIn == 0, "The reward not allowed yet. please wait for more"); 

        _reward(_pid, _account, pendingZONE_);

        user_.finishedZONE = user_.lpAmount.mul(pool_.accZONEPerLP).div(1 ether);
    }

    function _reward(uint256 _pid, address _account, uint256 _pendingZONE) private {
        if (rewardInZoneEnabled) {
            _safeZONETransfer(_account, _pendingZONE);
            emit RewardZone(_account, _pid, _pendingZONE);
        }

        if (rewardInNftEnabled) {
            (bool found, uint256 index) = _chooseRewardNft(_pendingZONE);
            if (found == true) {
                address rewardNftAddress = nftAddresses[index];
                uint256 rewardNftModel = nftModels[index];
                uint256 rewardNftPrice = nftPrices[index];

                uint256 leftCapacity;
                if (rewardNftModel != type(uint256).max) {
                    IMultiModelNftUpgradeable multiModelNft = IMultiModelNftUpgradeable(rewardNftAddress);
                    address[] memory addresses = new address[](1);
                    addresses[0] = _account;
                    leftCapacity = multiModelNft.doAirdrop(rewardNftModel, addresses);
                } else {
                    IBaseNftUpgradeable baseNft = IBaseNftUpgradeable(rewardNftAddress);
                    address[] memory addresses = new address[](1);
                    addresses[0] = _account;
                    leftCapacity = baseNft.doAirdrop(addresses);
                }
                emit RewardNft(_account, _pid, rewardNftAddress, rewardNftModel, rewardNftPrice);

                if (leftCapacity == 0) {
                    // remove the reward NFT from the list
                    nftAddresses[index] = nftAddresses[nftAddresses.length - 1];
                    nftAddresses.pop();
                    nftModels[index] = nftModels[nftModels.length - 1];
                    nftModels.pop();
                    nftPrices[index] = nftPrices[nftPrices.length - 1];
                    nftPrices.pop();
                    emit RemoveRewardNft(rewardNftAddress, rewardNftModel, rewardNftPrice);
                }
            }
        }
    }

    /**
     * @notice Withdraw LP tokens without caring about rewards. EMERGENCY ONLY
     *
     * @param _pid    Id of the pool to be emergency withdrawn from
     */
    function emergencyWithdraw(uint256 _pid) external nonReentrant() {
        address _account = _msgSender();
        Pool storage pool_ = pool[_pid];
        User storage user_ = user[_pid][_account];

        uint256 amount = user_.lpAmount;
        user_.lpAmount = 0;
        pool_.lpSupply = pool_.lpSupply.sub(amount);
        IERC20Upgradeable(pool_.lpTokenAddress).safeTransfer(_account, amount);
        emit EmergencyWithdraw(_account, _pid, amount);
    }

    /** 
     * @notice Safe ZONE transfer function, just in case if rounding error causes pool to not have enough ZONEs
     *
     * @param _to        Address to get transferred ZONEs
     * @param _amount    Amount of ZONE to be transferred
     */
    function _safeZONETransfer(address _to, uint256 _amount) internal {
        uint256 balance = zoneToken.balanceOf(address(this));
        
        if (balance < _amount) {
            zoneToken.safeTransfer(_to, balance);
        } else {
            zoneToken.safeTransfer(_to, _amount);
        }
    }

    // fund the contract with ZONE. _from address must have approval to execute ZONE Token Contract transferFrom
    function fund(address _from, uint256 _amount) external {
        require(_from != address(0), '_from is invalid');
        require(0 < _amount, '_amount is invalid');
        require(_amount <= zoneToken.balanceOf(_from), 'Insufficient balance');
        zoneToken.safeTransferFrom(_from, address(this), _amount);
    }

    uint256[32] private __gap;
}

contract LPStakingUpgradeableProxy is TransparentUpgradeableProxy {
    constructor(address logic, address admin, bytes memory data) TransparentUpgradeableProxy(logic, admin, data) public {
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./UpgradeableProxy.sol";

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is UpgradeableProxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {UpgradeableProxy-constructor}.
     */
    constructor(address _logic, address admin_, bytes memory _data) public payable UpgradeableProxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _setAdmin(admin_);
    }

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _admin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        require(newAdmin != address(0), "TransparentUpgradeableProxy: new admin is the zero address");
        emit AdminChanged(_admin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external virtual ifAdmin {
        _upgradeTo(newImplementation);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable virtual ifAdmin {
        _upgradeTo(newImplementation);
        Address.functionDelegateCall(newImplementation, data);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address adm) {
        bytes32 slot = _ADMIN_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            adm := sload(slot)
        }
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        bytes32 slot = _ADMIN_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newAdmin)
        }
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _admin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "./IERC20Upgradeable.sol";
import "../../math/SafeMathUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

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
    address private _pendingOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init(address _ownerAddress) internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained(_ownerAddress);
    }

    function __Ownable_init_unchained(address _ownerAddress) internal initializer {
        _owner = _ownerAddress;
        emit OwnershipTransferred(address(0), _ownerAddress);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
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
    function safeTransferOwnership(address newOwner, bool safely) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        if (safely) {
            _pendingOwner = newOwner;
        } else {
            emit OwnershipTransferred(_owner, newOwner);
            _owner = newOwner;
            _pendingOwner = address(0);
        }
    }

    function safeAcceptOwnership() public virtual {
        require(_msgSender() == _pendingOwner, "acceptOwnership: Call must come from pendingOwner.");
        emit OwnershipTransferred(_owner, _pendingOwner);
        _owner = _pendingOwner;
    }

    uint256[48] private __gap;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/math/MathUpgradeable.sol";

library ArrayUtil {

    /**
     * @dev Searches a sorted `array` and returns the first index that contains
     * a value less or equal to `element`.
     *
     * `array` is expected to be sorted in ascending order, and to contain no
     * repeated elements.
     */
    function findLowerBound(uint256[] memory array, uint256 element) internal pure returns (bool, uint256) {
        if (array.length == 0) {
            // Nothing in the array
            return (false, 0);
        }
        if (element < array[0]) {
            // Out of array range
            return (false, 0);
        }

        uint256 low = 0;
        uint256 high = array.length;
        uint256 mid;

        // The looping is limited as 256. In fact, this looping will be early broken because the maximum slot count is 2^256
        for (uint16 i = 0; i < 256; i ++) {
            mid = MathUpgradeable.average(low, high);

            // Note that mid will always be strictly less than high (i.e. it will be a valid array index)
            // because Math.average rounds down (it does integer division with truncation).
            if (element < array[mid]) {
                high = mid;
            } else if (element == array[mid] || low == mid) {
                // Found the correct element
                // Or the array[low] is the less and the nearest value to the element
                break;
            } else {
                low = mid;
            }
        }
        return (true, mid);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;
pragma abicoder v2;

interface IBaseNftUpgradeable {

    function initialize(
        address _nymLib,
        address _priceOracle,
        address _ownerAddress,
        string memory _name,
        string memory _symbol,
        string[] memory _metafileUris,
        uint256 _capacity,
        uint256 _price,
        bool _nameChangeable,
        bool _colorChangeable,
        bytes4[] memory _color
    ) external;

    function doAirdrop(address[] memory _accounts) external returns(uint256 leftCapacity);

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

interface IMultiModelNftUpgradeable {
    function doAirdrop(uint256 _modelId, address[] memory _accounts) external returns(uint256 leftCapacity);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.6;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

interface IPriceOracleUpgradeable {
    function zoneToken() external view returns(address);

    function lpZoneEth() external view returns(IUniswapV2Pair);

    function getOutAmount(address token, uint256 tokenAmount) external view returns (uint256);

    function mintPriceInZone(uint256 _mintPrice) external returns (uint256);

    function getLPFairPrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Proxy.sol";
import "../utils/Address.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 *
 * Upgradeability is only provided internally through {_upgradeTo}. For an externally upgradeable proxy see
 * {TransparentUpgradeableProxy}.
 */
contract UpgradeableProxy is Proxy {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) public payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_logic);
        if(_data.length > 0) {
            Address.functionDelegateCall(_logic, _data);
        }
    }

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal virtual {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableProxy: new implementation is not a contract");

        bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}