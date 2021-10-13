// SPDX-License-Identifier: MIT

pragma solidity 0.8.3;
pragma experimental ABIEncoderV2;


import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract XCVFarmV3 is
    Initializable,
    ReentrancyGuardUpgradeable,
    OwnableUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    // 抵押借款单信息
    struct DepositInfo {
        address nftAddress;
        uint256[] tokenId;
        address mortgagor; //抵押NFT借款人
        address lender; //债权人
        uint256 principle; //出借的稳定币数量
        uint256 amount; //计算奖励的稳定币数量
        uint256 startTime; //出借的开始时间
        uint256 paybackTime; //约定的还贷日期
        uint256 rewardDebt; //已奖励的代币数量
        uint256 lastHarvestTime;
    }

    // 池子信息
    struct PoolInfo {
        uint256 lendTokenBal; // 这个矿池中记录的抵押借贷中产生的借出代币的总余额
        uint256 allocPoint; // 分配给该池的分配点数。 XCV按块分配
        uint256 lastRewardBlock; // XCV分配发生的最后一个块号
        uint256 accXCVPerShare; // 每股累积XCV乘以1e12
    }

    // uint256 LOCK_DURATION = 180 days;
    uint256 public LOCK_DURATION;

    struct LockedReward {
        uint256 startTime;
        uint256 lastRewardTime;
        uint256 locked;
        uint256 toBeUnlocked;
    }

    // The XCV Token (as pools' reward)
    IERC20Upgradeable public xcv;
    // Dev address.开发人员地址
    address public devaddr;
    address public pendingDevaddr;
    // XCV tokens created per block.
    uint256 public xcvPerBlock;
    // 储存所有矿池对应的nft合约地址
    EnumerableSetUpgradeable.AddressSet private nftAddresses;

    // 池子信息数组
    // NFT合约address => 池子 的映射
    mapping(address => PoolInfo) public poolInfo;
    // orderId => 抵押借款信息 的映射
    mapping(uint256 => DepositInfo) public depositInfo;

    // 池子的白名单是否开启
    mapping(address => bool) private poolWhitelistOn;
    // NFT合约address => NFT的Token id => 是否在白名单 的映射
    mapping(address => mapping(uint256 => bool)) private _whitelistMap;

    mapping(address => LockedReward) private lockedRewards;
    // 总分配点。必须是所有池中所有分配点的总和
    uint256 public totalAllocPoint;
    // 挖掘开始时的块号
    uint256 public startBlock;
    // 触发合约动作的合约地址publisher
    address public emitter;
    address public publisherAddr;

    event Deposit(
        uint256 orderId,
        address indexed nftAddress,
        uint256[] tokenIds,
        uint256 principle,
        uint256 amount
    );
    event Withdraw(
        uint256 orderId,
        address indexed nftAddress,
        uint256[] tokenIds,
        uint256 principle,
        uint256 amount
    );

    event Harvest(
        uint256 orderId,
        address indexed nftAddress,
        uint256[] tokenIds,
        uint256 amount
    );

    event ClaimWithdrawReward(address indexed user, uint256 indexed amount);
    event WhitelistedAdded(address indexed nftAddress, uint256 indexed tokenId);
    event WhitelistedRemoved(
        address indexed nftAddress,
        uint256 indexed tokenId
    );
    event Whitelisted(address indexed nftAddresses, bool on);

    event SetRewardPerBlock(uint256 _reward);
    event SetPublisherAddr(address _publisherAddr);
    event SetEmitter(address _emitter);

    event Add(address _nftAddress, uint256 _allocPoint, bool _withUpdate);
    event Set(address _nftAddress, uint256 _allocPoint, bool _withUpdate);

    event PendingDev(address _newDevaddr);
    event ClaimDev(address _devAddr);

    event SetDepositPointLimit(uint256 _limit);

    event Initialize(
        address _xcv,
        address _devaddr,
        uint256 _xcvPerBlock,
        uint256 _startBlock,
        uint256 _depositeInfoPointLimit
    );

    //抵押借款单分配比例上限
    uint256 public depositeInfoPointLimit;

    modifier onlyEmitter() {
        require(msg.sender == emitter, "caller is not the emitter");
        _;
    }

    // /**
    //  * @dev 构造函数
    //  * @param _xcv 币地址
    //  * @param _devaddr 开发人员地址
    //  * @param _xcvPerBlock 每块创建的XCV令牌
    //  * @param _startBlock XCV挖掘开始时的块号
    //  */
    function initialize(
        address _xcv,   // 0xFeF4422ADd5Ab245594558Ae001D0e533f747fb4
        address _devaddr,   // 0x7BeDb3a2638fe9aE7c8E408b6FCd4B1eE914D4De
        uint256 _xcvPerBlock, // 10 * 1e18
        uint256 _startBlock, // 12009351
        uint256 _depositeInfoPointLimit // 300 * 1e18
    ) external initializer {
        __ReentrancyGuard_init();
        __Ownable_init();

        require(_xcv != address(0), "_xcv is zero address");
        require(_devaddr != address(0), "_devaddr is zero address");

        xcv = IERC20Upgradeable(_xcv);
        devaddr = _devaddr;
        xcvPerBlock = _xcvPerBlock;
        startBlock = _startBlock;
        depositeInfoPointLimit = _depositeInfoPointLimit;
        LOCK_DURATION = 2 hours;

        emit Initialize(_xcv, _devaddr, _xcvPerBlock, _startBlock, _depositeInfoPointLimit);
    }

    function setRewardPerBlock(uint256 _reward) public onlyOwner {
        require(_reward < xcvPerBlock, "only decress reward per block");
        xcvPerBlock = _reward;

        emit SetRewardPerBlock(_reward);
    }

    /**
     * @dev 返回所有池子对应NFT合约的地址
     */
    function getNFTAddresses() external view returns (address[] memory) {
        address[] memory result = new address[](nftAddresses.length());
        for (uint256 i = 0; i < nftAddresses.length(); ++i) {
            result[i] = nftAddresses.at(i);
        }
        return result;
    }

    function setPublisherAddr(address _publisherAddr) external onlyOwner {
        require(_publisherAddr != address(0), "_publisherAddr is zero address");
        publisherAddr = _publisherAddr;

        emit SetPublisherAddr(_publisherAddr);
    }

    function setEmitter(address _emitter) external onlyOwner {
        require(_emitter != address(0), "_emitter is zero address");
        emitter = _emitter;

        emit SetEmitter(_emitter);
    }

    /**
     * @dev 将新的lp添加到池中,只能由所有者调用
     * @param _allocPoint 分配给该池的分配点数。 XCV按块分配
     * @param _nftAddress 此新增矿池对应的NFT的合约地址
     * @param _withUpdate 触发更新所有池的奖励变量。注意gas消耗！
     */
    // 注意：对于同一个NFT合约地址可以请勿多次添加。如果您这样做，奖励将被搞砸
    function add(
        address _nftAddress,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        require(
            !nftAddresses.contains(_nftAddress),
            "Can not add existing NFT address for farming"
        );
        // 触发更新所有池的奖励变量
        if (_withUpdate) {
            massUpdatePools();
        }
        // 分配发生的最后一个块号 = 当前块号 > XCV挖掘开始时的块号 > 当前块号 : XCV挖掘开始时的块号
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        // 总分配点添加分配给该池的分配点数
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        // 添加新NFT地址
        nftAddresses.add(_nftAddress);
        // 池子信息推入池子数组
        poolInfo[_nftAddress] = PoolInfo({
            lendTokenBal: 0,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accXCVPerShare: 0
        });
        emit Add(_nftAddress, _allocPoint, _withUpdate);
    }

    /**
     * @dev 更新给定池的XCV分配点。只能由所有者调用
     * @param _nftAddress 此新增矿池对应的NFT的合约地址
     * @param _allocPoint 新的分配给该池的分配点数。 XCV按块分配
     * @param _withUpdate 触发更新所有池的奖励变量。注意gas消耗！
     */
    function set(
        address _nftAddress,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        require(
            nftAddresses.contains(_nftAddress),
            "Can not set non-existing farming pool"
        );
        // 触发更新所有池的奖励变量
        if (_withUpdate) {
            massUpdatePools();
        }
        // 总分配点 = 总分配点 - 池子映射[nft地址].分配点数 + 新的分配给该池的分配点数
        totalAllocPoint = totalAllocPoint
            .sub(poolInfo[_nftAddress].allocPoint)
            .add(_allocPoint);
        // 池子映射[nft地址].分配点数 = 新的分配给该池的分配点数
        poolInfo[_nftAddress].allocPoint = _allocPoint;

        emit Set(_nftAddress, _allocPoint, _withUpdate);
    }

    /**
     * @dev 查看功能以查看用户的处理中尚未领取的XCV
     * @param _orderId order id
     * @return 此笔质押单中尚未领取的XCV代币奖励（包括质押人和债权人）
     */
    // View function to see pending XCVs for per NFT on frontend.
    function earnedRewardPerDeposit(uint256 _orderId)
        external
        view
        returns (uint256)
    {
        DepositInfo storage singleDeposit = depositInfo[_orderId];
        address _nftAddress = singleDeposit.nftAddress;

        require(
            nftAddresses.contains(_nftAddress),
            "Can not check for non-existing farming pool"
        );
        require(singleDeposit.nftAddress != address(0), "order not exist");

        if (singleDeposit.lastHarvestTime >= singleDeposit.paybackTime){
            return 0;
        }

        PoolInfo storage pool = poolInfo[_nftAddress];

        // 每股累积XCV
        uint256 accXCVPerShare = pool.accXCVPerShare;
        // lendTokenBal的供应量
        uint256 lendTokenSupply = pool.lendTokenBal;
        // 如果当前区块号 > 池子信息.分配发生的最后一个块号 && lendToken的供应量 != 0
        if (block.number > pool.lastRewardBlock && lendTokenSupply != 0) {
            // xcv奖励 = 持续时间 * 每块创建的XCV令牌 * 池子分配点数 / 总分配点数
            uint256 xcvReward = (block.number.sub(pool.lastRewardBlock))
                .mul(xcvPerBlock)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            // 每股累积XCV = 每股累积XCV + XCV奖励 * 1e12 / lendToken的供应量
            accXCVPerShare = accXCVPerShare.add(
                xcvReward.mul(1e12).div(lendTokenSupply)
            );
        }
        uint256 totalReward = singleDeposit
            .amount
            .mul(accXCVPerShare)
            .div(1e12)
            .sub(singleDeposit.rewardDebt);

        if (block.timestamp > singleDeposit.paybackTime) {
            uint256 fullTime = singleDeposit.paybackTime.sub(
                singleDeposit.lastHarvestTime
            );
            uint256 allTime = block.timestamp.sub(singleDeposit.lastHarvestTime);
            totalReward = totalReward.mul(fullTime).div(allTime);
        }

        // 返回 用户.已添加的数额 * 每股累积XCV / 1e12 - 用户.已奖励数额
        return totalReward;
    }

    /**
     * @dev 更新所有池的奖励变量。注意gas消耗
     */
    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        for (uint256 i = 0; i < nftAddresses.length(); ++i) {
            updatePool(nftAddresses.at(i));
        }
    }

    /**
     * @dev 将给定池的奖励变量更新为最新
     * @param _nftAddress 此新增矿池对应的NFT的合约地址
     */
    // Update reward variables of the given pool to be up-to-date.
    function updatePool(address _nftAddress) public {
        require(
            nftAddresses.contains(_nftAddress),
            "Can not update for non-existing farming pool"
        );
        // 实例化池子信息
        PoolInfo storage pool = poolInfo[_nftAddress];
        // 如果当前区块号 <= 池子信息.分配发生的最后一个块号
        if (block.number <= pool.lastRewardBlock) {
            // 直接返回
            return;
        }
        // LPtoken的供应量 = 当前合约在`池子信息.lotoken地址`的余额
        uint256 lendTokenSupply = pool.lendTokenBal;
        // 如果 LPtoken的供应量 == 0
        if (lendTokenSupply == 0) {
            // 池子信息.分配发生的最后一个块号 = 当前块号
            pool.lastRewardBlock = block.number;
            // 返回
            return;
        }
        // xcv奖励 = 持续时间 * 每块创建的XCV令牌 * 池子分配点数 / 总分配点数
        uint256 xcvReward = (block.number.sub(pool.lastRewardBlock))
            .mul(xcvPerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);
        // 每股累积XCV = 每股累积XCV + xcv奖励 * 1e12 / lendToken的供应量
        pool.accXCVPerShare = pool.accXCVPerShare.add(
            xcvReward.mul(1e12).div(lendTokenSupply)
        );
        // 池子信息.分配发生的最后一个块号 = 当前块号
        pool.lastRewardBlock = block.number;
    }

    /**
     * @dev 记账Token存入，进行奖励代币分配。此方法仅允许在监听其他合约方法时被调用！
     * @param _orderId order id
     * @param _nftAddress 此新增矿池对应的NFT的合约地址
     * @param _tokenIds  此nft的tokenIds
     * @param _pledger 抵押人address
     * @param _lender 债权人address
     * @param _amount 借贷的数额
     * @param _duration 已约定还款期限
     *
     */
    function _deposit(
        uint256 _orderId,
        address _nftAddress,
        uint256[] memory _tokenIds,
        address _pledger,
        address _lender,
        uint256 _amount,
        uint256 _duration
    ) internal {
        require(
            nftAddresses.contains(_nftAddress),
            "Can not deposit to non-existing farming pool"
        );
        // require(((poolWhitelistOn[_nftAddress] && isOnWhitelist(_nftAddress, _tokenId)) || (!poolWhitelistOn[_nftAddress])),"this nft tokenId is not on whitelist");
        // require(isOnWhitelist(_nftAddress, _tokenId), "this nft tokenId is not on whitelist");
        require(_pledger != address(0), "mortgagor address is 0");
        require(_lender != address(0), "lender address is 0");
        require(_pledger != _lender, "_mortgagor == _lender");
        require(_amount > 0, "deposit amount is <= 0");
        require(_duration > 0, "duration should > 0");

        // 实例化池子信息
        PoolInfo storage pool = poolInfo[_nftAddress];

        // 根据nft合约地址和此笔质押nft的tokenId, 实例化此笔质押借款信息
        DepositInfo storage singleDeposit = depositInfo[_orderId];
        singleDeposit.nftAddress = _nftAddress;
        singleDeposit.tokenId = _tokenIds;
        singleDeposit.principle = _amount;

        uint256 calAmount = _amount;
        if (calAmount > depositeInfoPointLimit) {
            calAmount = depositeInfoPointLimit;
        }
        singleDeposit.amount = calAmount;
        singleDeposit.lender = _lender;
        singleDeposit.mortgagor = _pledger;
        singleDeposit.startTime = block.timestamp;
        singleDeposit.lastHarvestTime = block.timestamp;
        singleDeposit.paybackTime = block.timestamp.add(_duration); //质押的当前区块时间+约定的还款期限
        // 将给定池的奖励变量更新为最新
        updatePool(_nftAddress);

        // 增加当前lendToken的总余额
        pool.lendTokenBal = pool.lendTokenBal.add(calAmount);
        // 用户.已奖励数额 = 用户.已添加的数额 * 池子.每股累积XCV / 1e12
        singleDeposit.rewardDebt = singleDeposit
            .amount
            .mul(pool.accXCVPerShare)
            .div(1e12);
        // 触发存款事件
        emit Deposit(_orderId, _nftAddress, _tokenIds, _amount, calAmount);
    }


    function claimWithDrawReward() public {
       
        _updateLockReward(msg.sender, 0);

        LockedReward storage reward_ = lockedRewards[msg.sender];
        uint256 amount = reward_.toBeUnlocked;
        require(amount > 0, "to be claimed XCV balance is <= 0");
        require(
            amount <= xcv.balanceOf(address(this)),
            "Not enough XCV balance in this Farm contract!"
        );
        reward_.toBeUnlocked = 0;
        xcv.transfer(msg.sender, amount);

        emit ClaimWithdrawReward(msg.sender, amount);
    }

    /**
     * @dev 清楚这笔抵押借贷单tokenId记账。此方法仅允许在监听其他合约方法时被调用！
     * @param _orderId order id
     * @param _nftAddress 此新增矿池对应的NFT的合约地址
     * @param _mortgagor 抵押人address
     * @param _lender 债权人address
     * @param _amount 数额
     *
     */
    function _withdraw(
        uint256 _orderId,
        address _nftAddress,
        address _mortgagor,
        address _lender,
        uint256 _amount
    ) internal {
        require(
            nftAddresses.contains(_nftAddress),
            "Can not withdraw from non-existing farming pool"
        );
        // require(isOnWhitelist(_nftAddress, _tokenId), "this nft tokenId is not on whitelist");
        // require(((poolWhitelistOn[_nftAddress] && isOnWhitelist(_nftAddress, _tokenId)) || (!poolWhitelistOn[_nftAddress])),"this nft tokenId is not on whitelist");
        // 实例化池子信息
        PoolInfo storage pool = poolInfo[_nftAddress];
        // 根据池子id和当前抵押借贷单id, 实例化该笔借贷单信息
        DepositInfo storage singleDeposit = depositInfo[_orderId];
        address mortgagor = singleDeposit.mortgagor;
        uint256 amount = singleDeposit.amount;
        address lender = singleDeposit.lender;
        // uint256 paybackTime = singleDeposit.paybackTime;
        // uint256 rewardDebt = singleDeposit.rewardDebt;
        require(_amount > 0, "_amount should be > 0");
        require(
            singleDeposit.principle == _amount,
            "withdraw amount should be exactly equal to deposit amount"
        );
        require(mortgagor == _mortgagor, "mortgator should be the same one");
        require(lender == _lender, "lender should be the same one");

        
        _harvestInternal(_orderId);
        // 减少当前池子中lendToken的总余额
        pool.lendTokenBal = pool.lendTokenBal.sub(amount);
        // 清零该笔订单
        singleDeposit.amount = 0;
        // 清零
        singleDeposit.rewardDebt = 0;

        delete depositInfo[_orderId];

        // 触发提款事件
        emit Withdraw(
            _orderId,
            _nftAddress,
            singleDeposit.tokenId,
            singleDeposit.principle,
            amount
        );
    }

    function harvest(uint256 _orderId) public {
        DepositInfo storage singleDeposit = depositInfo[_orderId];
        address nftAddress_ = singleDeposit.nftAddress;
        require(nftAddress_ != address(0), "order not exist!");
        require(singleDeposit.mortgagor == msg.sender || singleDeposit.lender == msg.sender, "no auth");
        require(singleDeposit.lastHarvestTime < singleDeposit.paybackTime, "no reward could harvest");

        _harvestInternal(_orderId);
    }

    function batchHarvest(uint256[] calldata _orderIds) external {
        uint256 n = _orderIds.length;
        for (uint i = 0; i < n; i++) {
            harvest(_orderIds[i]);
        }
    }

    function _harvestInternal(uint256 _orderId) internal{
        
        DepositInfo storage singleDeposit = depositInfo[_orderId];
        address nftAddress_ = singleDeposit.nftAddress;
        address mortgagor = singleDeposit.mortgagor;
        uint256 amount = singleDeposit.amount;
        address lender = singleDeposit.lender;
        uint256 paybackTime = singleDeposit.paybackTime;
        uint256 rewardDebt = singleDeposit.rewardDebt;

        if (nftAddress_ == address(0))
            return;
        
        if (singleDeposit.lastHarvestTime >= singleDeposit.paybackTime){
            return;
        }
        
        PoolInfo storage pool = poolInfo[nftAddress_];

        updatePool(nftAddress_);

        uint256 totalReward = amount.mul(pool.accXCVPerShare).div(1e12).sub(
            rewardDebt
        );

        uint256 realReward = totalReward;
        if (totalReward > 0) {
            if (block.timestamp > paybackTime) {
                uint256 fullTime = paybackTime.sub(singleDeposit.lastHarvestTime);
                uint256 allTime = block.timestamp.sub(singleDeposit.lastHarvestTime);
                realReward = totalReward.mul(fullTime).div(allTime);
            }

            uint256 mortgagorReward = realReward.mul(3).div(10);
            uint256 lenderReward = realReward.sub(mortgagorReward);

            _updateLockReward(mortgagor, mortgagorReward);
            _updateLockReward(lender, lenderReward);
        }
        singleDeposit.lastHarvestTime = block.timestamp;
        singleDeposit.rewardDebt = singleDeposit
            .amount
            .mul(pool.accXCVPerShare)
            .div(1e12);

        emit Harvest(
            _orderId,
            nftAddress_,
            singleDeposit.tokenId,
            realReward
        );
    }

    function _updateLockReward(address _user, uint256 _addReward) internal{
        LockedReward storage reward_ = lockedRewards[_user];
        if (reward_.startTime == 0){
            uint256 rewardRelease = _addReward.mul(3).div(10);
            reward_.startTime = block.timestamp;
            reward_.lastRewardTime = block.timestamp;
            reward_.locked = _addReward.sub(rewardRelease);
            reward_.toBeUnlocked = rewardRelease;
            return;
        }

        uint256 readyForUnlock = 0;
        uint256 readyForLock = 0;

        if (reward_.locked > 0) {
            uint256 endTime = reward_.startTime.add(LOCK_DURATION);
            if (reward_.lastRewardTime >= endTime){
                readyForLock = 0;
                readyForUnlock = 0;
            }
            else if (block.timestamp > endTime){
                uint256 hasUnlocked = (reward_.lastRewardTime.sub(reward_.startTime))
                                    .mul(reward_.locked)
                                    .div(LOCK_DURATION);
                readyForUnlock = reward_.locked.sub(hasUnlocked);

                readyForLock = 0;

            }else {
                readyForUnlock = (block.timestamp.sub(reward_.lastRewardTime)).mul(reward_.locked).div(LOCK_DURATION);
                uint256 hasUnlock = (block.timestamp.sub(reward_.startTime))
                        .mul(reward_.locked)
                        .div(LOCK_DURATION);
                readyForLock = reward_.locked.sub(hasUnlock);
            }
        }
        uint256 rewardRelease = 0;
        if (_addReward > 0){
            rewardRelease = _addReward.mul(3).div(10);
            reward_.startTime = block.timestamp;
            reward_.locked = readyForLock.add(_addReward).sub(rewardRelease);
        }
        reward_.toBeUnlocked = reward_.toBeUnlocked.add(readyForUnlock).add(rewardRelease);
        
        reward_.lastRewardTime = block.timestamp;
    }



    function checkToBeClaimed(address _user) public view returns (uint256) {
        LockedReward storage reward_ = lockedRewards[_user];
        uint256 readyForUnlock = 0;
        if (reward_.locked > 0) {
            uint256 endTime = reward_.startTime.add(LOCK_DURATION);
             if (reward_.lastRewardTime >= endTime){
                readyForUnlock = 0;
            }
            else if (block.timestamp >= endTime){
                readyForUnlock = (reward_.lastRewardTime.sub(reward_.startTime))
                                    .mul(reward_.locked)
                                    .div(LOCK_DURATION);
                readyForUnlock = reward_.locked.sub(readyForUnlock);

            }else {
                readyForUnlock = (block.timestamp.sub(reward_.lastRewardTime)).mul(reward_.locked).div(LOCK_DURATION);
            }
        }
        return readyForUnlock.add(reward_.toBeUnlocked);
    } 


    function checkLocked(address _user) public view returns (uint256) {
        LockedReward storage reward_ = lockedRewards[_user];
        uint256 readyForLock = 0;
        if (reward_.locked > 0) {
            uint256 endTime = reward_.startTime.add(LOCK_DURATION);
            if (reward_.lastRewardTime >= endTime){
                readyForLock = 0;
            }
            else if (block.timestamp > endTime){
                readyForLock = 0;

            }else {
                uint256 hasUnlock = (block.timestamp.sub(reward_.startTime))
                        .mul(reward_.locked)
                        .div(LOCK_DURATION);
                readyForLock = reward_.locked.sub(hasUnlock);
            }
        }
        return readyForLock;
    } 

    function onDeposit(
        address publisher,
        bytes32 topic,
        bytes memory data
    ) external onlyEmitter {
        require(
            publisher == publisherAddr && topic == keccak256("deposit"),
            "!onDeposit"
        );

        (
            uint256 _orderId,
            address _nftAddress,
            uint256[] memory _tokenIds,
            address _pledger,
            address _lender,
            uint256 _amount,
            uint256 _duration
        ) = abi.decode(
                data,
                (
                    uint256,
                    address,
                    uint256[],
                    address,
                    address,
                    uint256,
                    uint256
                )
            );

        //order has been in the farming
        if (depositInfo[_orderId].nftAddress != address(0)) return;

        if (!nftAddresses.contains(_nftAddress)) {
            return;
        }

        if (poolWhitelistOn[_nftAddress]) {
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                if (!isOnWhitelist(_nftAddress, _tokenIds[i])) {
                    return;
                }
            }
        }

        _deposit(
            _orderId,
            _nftAddress,
            _tokenIds,
            _pledger,
            _lender,
            _amount,
            _duration
        );
    }

    function onWithdraw(
        address publisher,
        bytes32 topic,
        bytes memory data
    ) external onlyEmitter {
        require(
            publisher == publisherAddr && topic == keccak256("withdraw"),
            "!onWithdraw"
        );

        (
            uint256 _orderId,
            address _nftAddress,
            address _pledger,
            address _lender,
            uint256 _amount
        ) = abi.decode(data, (uint256, address, address, address, uint256));

        DepositInfo storage singleDeposit = depositInfo[_orderId];
        // order has not been in the farming, return
        if (singleDeposit.nftAddress == address(0)) {
            return;
        }

        _withdraw(_orderId, _nftAddress, _pledger, _lender, _amount);
    }

    // 下面两个来移交开发者地址
    function pendingDev(address _newDevaddr) public {
        require(_newDevaddr != address(0), "can not be 0 address");
        // 确认当前账户是开发者地址
        require(
            msg.sender == devaddr,
            "should be current dev address to operate it"
        );
        // 赋值新地址
        pendingDevaddr = _newDevaddr;

        emit PendingDev(_newDevaddr);
    }

    function claimDev() public {
        require(msg.sender == pendingDevaddr, "you are not the pending dev");
        devaddr = pendingDevaddr;
        pendingDevaddr = address(0);

        emit ClaimDev(devaddr);
    }

    //下面几个是来操作和查询白名单
    function isOnWhitelist(address _nftAddress, uint256 _tokenId)
        public
        view
        returns (bool)
    {
        return _whitelistMap[_nftAddress][_tokenId];
    }

    function addWhitelist(address _nftAddress, uint256 _tokenId)
        public
        onlyOwner
    {
        require(
            !isOnWhitelist(_nftAddress, _tokenId),
            "This nft tokenId has already on the whitelist"
        );
        _whitelistMap[_nftAddress][_tokenId] = true;
        emit WhitelistedAdded(_nftAddress, _tokenId);
    }

    function removeWhitelist(address _nftAddress, uint256 _tokenId)
        public
        onlyOwner
    {
        require(
            isOnWhitelist(_nftAddress, _tokenId),
            "This nft tokenId is not on the whitelist"
        );
        _whitelistMap[_nftAddress][_tokenId] = false;
        emit WhitelistedRemoved(_nftAddress, _tokenId);
    }

    function setDepositPointLimit(uint256 _limit) public onlyOwner {
        require(_limit > 0, "_limit should > 0");
        depositeInfoPointLimit = _limit;

        emit SetDepositPointLimit(_limit);
    }

    function setPoolWhiteListOn(address _nftAddress, bool _on)
        public
        onlyOwner
    {
        require(
            nftAddresses.contains(_nftAddress),
            "Can not set non-existing farming pool"
        );
        poolWhitelistOn[_nftAddress] = _on;
        emit Whitelisted(_nftAddress, _on);
    }

    function isPoolWhitelistOpen(address _nftAddress)
        public
        view
        returns (bool)
    {
        return poolWhitelistOn[_nftAddress];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

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
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
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
library SafeMathUpgradeable {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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