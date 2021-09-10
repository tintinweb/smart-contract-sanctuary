// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";
import "./SafeMath.sol";
import "./Ownable.sol";

contract XCVFarm is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    // 抵押借款单信息
    struct DepositInfo {
        address mortgagor;     //抵押NFT借款人
        address lender;        //债权人
        uint256 principle;        //出借的稳定币数量
        uint256 amount;           //计算奖励的稳定币数量
        uint256 startTime;     //出借的开始时间
        uint256 paybackTime;      //约定的还贷日期
        uint256 rewardDebt;    //已奖励的代币数量
    }

    // 池子信息
    struct PoolInfo {
        uint256 lendTokenBal;      // 这个矿池中记录的抵押借贷中产生的借出代币的总余额
        uint256 allocPoint;        // 分配给该池的分配点数。 XCV按块分配
        uint256 lastRewardBlock;   // XCV分配发生的最后一个块号
        uint256 accXCVPerShare;  // 每股累积XCV乘以1e12
    }

    // The XCV Token (as pools' reward)
    IERC20 public xcv;
    // Dev address.开发人员地址
    address public devaddr;
    address public pendingDevaddr;
    // XCV tokens created per block.
    uint256 public xcvPerBlock;
    // 储存所有矿池对应的nft合约地址
    EnumerableSet.AddressSet private nftAddresses;

    // 池子信息数组
    // NFT合约address => 池子 的映射
    mapping(address => PoolInfo) public poolInfo;
    // NFT合约address => NFT的Token id => 抵押借款信息 的映射
    mapping(address => mapping(uint256 => DepositInfo)) public depositInfo;

    // 池子的白名单是否开启
    mapping(address => bool) private poolWhitelistOn;
    // NFT合约address => NFT的Token id => 是否在白名单 的映射
    mapping(address => mapping(uint256 => bool)) private _whitelistMap;
    // 还贷触发的用户奖励记账  用户 => xcv奖励金额
    mapping(address => uint256) private _toBeClaimed;
    // 总分配点。必须是所有池中所有分配点的总和
    uint256 public totalAllocPoint = 0;
    // 挖掘开始时的块号
    uint256 public startBlock;
    // 触发合约动作的合约地址publisher
    address public emitter;
    address public publisherAddr;

    event Deposit(address indexed nftAddress, uint256 indexed tokenId, uint256 amount);
    event Withdraw(address indexed nftAddress, uint256 indexed tokenId, uint256 amount);
    event ClaimWithdrawReward(address indexed user, uint256 indexed amount);
    event WhitelistedAdded(address indexed nftAddress, uint256 indexed tokenId);
    event WhitelistedRemoved(address indexed nftAddress, uint256 indexed tokenId);
    event Whitelisted(address indexed nftAddresses,bool on);

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
    constructor(
        // IERC20 _xcv,
        // address _devaddr,
        // uint256 _xcvPerBlock,
        // uint256 _startBlock
    ) public {
        xcv = IERC20(0xFeF4422ADd5Ab245594558Ae001D0e533f747fb4);
        devaddr = 0x7BeDb3a2638fe9aE7c8E408b6FCd4B1eE914D4De;
        xcvPerBlock = 10 * 1e18;   // XCV decimal is 18
        startBlock = 12009351;
        depositeInfoPointLimit = 30000 * 1e18;
    }
    
    function setRewardPerBlock(uint256 _reward) public onlyOwner {
        require(_reward < xcvPerBlock, "only decress reward per block");
        xcvPerBlock = _reward;
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
        publisherAddr = _publisherAddr;
    }

    function setEmitter(address _emitter) external onlyOwner {
        emitter = _emitter;
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
        require (!nftAddresses.contains(_nftAddress), "Can not add existing NFT address for farming");
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
        require (nftAddresses.contains(_nftAddress), "Can not set non-existing farming pool");
        // 触发更新所有池的奖励变量
        if (_withUpdate) {
            massUpdatePools();
        }
        // 总分配点 = 总分配点 - 池子映射[nft地址].分配点数 + 新的分配给该池的分配点数
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_nftAddress].allocPoint).add(
            _allocPoint
        );
        // 池子映射[nft地址].分配点数 = 新的分配给该池的分配点数
        poolInfo[_nftAddress].allocPoint = _allocPoint;
    }

    /**
     * @dev 查看功能以查看用户的处理中尚未领取的XCV
     * @param _nftAddress 此新增矿池对应的NFT的合约地址
     * @param _tokenId    质押的nft的tokenId
     * @return 此笔质押单中尚未领取的XCV代币奖励（包括质押人和债权人）
     */
    // View function to see pending XCVs for per NFT on frontend.
    function earnedRewardPerDeposit(address _nftAddress, uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        require (nftAddresses.contains(_nftAddress), "Can not check for non-existing farming pool");
        // require (isOnWhitelist(_nftAddress, _tokenId), "this nft tokenId is not on whitelist");
        // 实例化池子信息
        PoolInfo storage pool = poolInfo[_nftAddress];

        // 根据池子id和用户地址,实例化用户信息
        DepositInfo storage singleDeposit = depositInfo[_nftAddress][_tokenId];
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

        if(block.timestamp > singleDeposit.paybackTime) {
            uint256 fullTime = singleDeposit.paybackTime.sub(singleDeposit.startTime);
            uint256 allTime = block.timestamp.sub(singleDeposit.startTime);
            return (singleDeposit.amount.mul(accXCVPerShare).div(1e12).sub(singleDeposit.rewardDebt)).mul(fullTime).div(allTime);
        }

        // 返回 用户.已添加的数额 * 每股累积XCV / 1e12 - 用户.已奖励数额
        return singleDeposit.amount.mul(accXCVPerShare).div(1e12).sub(singleDeposit.rewardDebt);
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
        require (nftAddresses.contains(_nftAddress), "Can not update for non-existing farming pool");
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
     * @param _nftAddress 此新增矿池对应的NFT的合约地址
     * @param _tokenId  此nft的tokenId
     * @param _mortgagor 抵押人address
     * @param _lender 债权人address
     * @param _amount 借贷的数额
     * @param _duration 已约定还款期限
     * 
     * 警告：此方法对于同一个NFT合约的同一个tokenId只能调用一次，如果重复调用会引发挖矿池记账混乱！
     */
    function _deposit(address _nftAddress, uint256 _tokenId, address _mortgagor, address _lender, uint256 _amount, uint256 _duration) internal {
        require(nftAddresses.contains(_nftAddress), "Can not deposit to non-existing farming pool");
        require(((poolWhitelistOn[_nftAddress] && isOnWhitelist(_nftAddress, _tokenId)) || (!poolWhitelistOn[_nftAddress])),"this nft tokenId is not on whitelist");
        // require(isOnWhitelist(_nftAddress, _tokenId), "this nft tokenId is not on whitelist");
        require(_mortgagor != address(0), "mortgagor address is 0");
        require(_lender != address(0), "lender address is 0");
        require(_mortgagor != _lender, "_mortgagor == _lender");
        require(_amount > 0, "deposit amount is <= 0");
        require(_duration > 0, "duration should > 0");

        // 实例化池子信息
        PoolInfo storage pool = poolInfo[_nftAddress];

        // 根据nft合约地址和此笔质押nft的tokenId, 实例化此笔质押借款信息
        DepositInfo storage singleDeposit = depositInfo[_nftAddress][_tokenId];
        singleDeposit.principle = _amount;

        uint256 calAmount = _amount;
        if (calAmount > depositeInfoPointLimit){
            calAmount = depositeInfoPointLimit;
        }
        singleDeposit.amount = calAmount;
        singleDeposit.lender = _lender;
        singleDeposit.mortgagor = _mortgagor;
        singleDeposit.startTime = block.timestamp;
        singleDeposit.paybackTime = block.timestamp.add(_duration);  //质押的当前区块时间+约定的还款期限
        // 将给定池的奖励变量更新为最新
        updatePool(_nftAddress);

        // 增加当前lendToken的总余额
        pool.lendTokenBal = pool.lendTokenBal.add(_amount);
        // 用户.已奖励数额 = 用户.已添加的数额 * 池子.每股累积XCV / 1e12
        singleDeposit.rewardDebt = singleDeposit.amount.mul(pool.accXCVPerShare).div(1e12);
        // 触发存款事件
        emit Deposit(_nftAddress, _tokenId, _amount);
    }


    function checkToBeClaimed(address user) public view returns (uint256) {
        return _toBeClaimed[user];
    }

    function claimWithDrawReward() public {
        require(_toBeClaimed[msg.sender] > 0, "to be claimed XCV balance is <= 0");
        require(_toBeClaimed[msg.sender] <= xcv.balanceOf(address(this)), "Not enough XCV balance in this Farm contract!");
        xcv.transfer(msg.sender, _toBeClaimed[msg.sender]);
        _toBeClaimed[msg.sender] = 0;
        
        emit ClaimWithdrawReward(msg.sender, _toBeClaimed[msg.sender]);
    }

    /**
     * @dev 清楚这笔抵押借贷单tokenId记账。此方法仅允许在监听其他合约方法时被调用！
     * @param _nftAddress 此新增矿池对应的NFT的合约地址
     * @param _tokenId  此nft的tokenId
     * @param _mortgagor 抵押人address
     * @param _lender 债权人address
     * @param _amount 数额
     * 
     * 警告：此方法对于同一个_tokenId只能调用一次，如果重复调用会引发挖矿池记账混乱！
     */
    function _withdraw(address _nftAddress, uint256 _tokenId, address _mortgagor, address _lender, uint256 _amount) internal {
        require(nftAddresses.contains(_nftAddress), "Can not withdraw from non-existing farming pool");
        // require(isOnWhitelist(_nftAddress, _tokenId), "this nft tokenId is not on whitelist");
        // require(((poolWhitelistOn[_nftAddress] && isOnWhitelist(_nftAddress, _tokenId)) || (!poolWhitelistOn[_nftAddress])),"this nft tokenId is not on whitelist");
        // 实例化池子信息
        PoolInfo storage pool = poolInfo[_nftAddress];
        // 根据池子id和当前抵押借贷单id, 实例化该笔借贷单信息
        DepositInfo storage singleDeposit = depositInfo[_nftAddress][_tokenId];
        address mortgagor = singleDeposit.mortgagor;
        address lender = singleDeposit.lender;
        uint256 amount = singleDeposit.principle;
        uint256 paybackTime = singleDeposit.paybackTime;
        uint256 rewardDebt = singleDeposit.rewardDebt;
        require(_amount > 0, "_amount should be > 0");
        require(amount == _amount, "withdraw amount should be exactly equal to deposit amount");
        require(mortgagor == _mortgagor, "mortgator should be the same one");
        require(lender == _lender, "lender should be the same one");

        // 将给定池的奖励变量更新为最新
        updatePool(_nftAddress);
        // 计算二者的总奖励
        uint256 totalReward = amount.mul(pool.accXCVPerShare).div(1e12).sub(rewardDebt);
        if (totalReward > 0) {
            
            uint256 realReward = totalReward;
            if (block.timestamp > paybackTime) {
                uint256 fullTime = paybackTime.sub(singleDeposit.startTime);
                uint256 allTime = block.timestamp.sub(singleDeposit.startTime);
                realReward = totalReward.mul(fullTime).div(allTime);
            }
            
            uint256 mortgagorReward = realReward.mul(3).div(10);
            uint256 lenderReward = realReward.sub(mortgagorReward);
            
            _toBeClaimed[mortgagor] = _toBeClaimed[mortgagor].add(mortgagorReward);
            _toBeClaimed[lender] = _toBeClaimed[lender].add(lenderReward);
        }
        // 清零该笔订单
        singleDeposit.amount = 0;
        // 减少当前池子中lendToken的总余额
        pool.lendTokenBal = pool.lendTokenBal.sub(_amount);
        // 清零
        singleDeposit.rewardDebt = 0;
        
        delete depositInfo[_nftAddress][_tokenId];
        
        // 触发提款事件
        emit Withdraw(_nftAddress, _tokenId, _amount);
    }
    

    function onDeposit(address publisher, bytes32 topic, bytes memory data) external onlyEmitter {
        require(publisher == publisherAddr && topic == keccak256("deposit"), "!onDeposit");

        (address _nftAddress, uint256 _tokenId, address _mortgagor, address _lender, uint256 _amount, uint256 _duration) =
            abi.decode(data, (address, uint256, address, address, uint256, uint256));

        if(!nftAddresses.contains(_nftAddress)){
            return;
        }
        if (poolWhitelistOn[_nftAddress] && !isOnWhitelist(_nftAddress, _tokenId)){
            return;
        }
    
        _deposit(_nftAddress, _tokenId, _mortgagor, _lender, _amount, _duration);
    }

    function onWithdraw(address publisher, bytes32 topic, bytes memory data) external onlyEmitter {
        require(publisher == publisherAddr && topic == keccak256("withdraw"), "!onWithdraw");

        (address _nftAddress, uint256 _tokenId, address _mortgagor, address _lender, uint256 _amount) =
            abi.decode(data, (address, uint256, address, address, uint256));

        if(!nftAddresses.contains(_nftAddress)){
            return;
        }
        
        DepositInfo storage singleDeposit = depositInfo[_nftAddress][_tokenId];
        if (singleDeposit.amount == 0){
            return;
        }

        _withdraw(_nftAddress, _tokenId, _mortgagor, _lender, _amount);
    }

    // 下面两个来移交开发者地址
    function pendingDev(address _newDevaddr) public {
        require(_newDevaddr != address(0), "can not be 0 address");
        // 确认当前账户是开发者地址
        require(msg.sender == devaddr, "should be current dev address to operate it");
        // 赋值新地址
        pendingDevaddr = _newDevaddr;
    }

    function claimDev() public {
        require(msg.sender == pendingDevaddr, "you are not the pending dev");
        devaddr = pendingDevaddr;
        pendingDevaddr = address(0);
    }

    //下面几个是来操作和查询白名单
    function isOnWhitelist(address _nftAddress, uint256 _tokenId) public view returns (bool) {
        return _whitelistMap[_nftAddress][_tokenId];
    }

    function addWhitelist(address _nftAddress, uint256 _tokenId) public onlyOwner {
        require(!isOnWhitelist(_nftAddress, _tokenId), "This nft tokenId has already on the whitelist");
        _whitelistMap[_nftAddress][_tokenId] = true;
        emit WhitelistedAdded(_nftAddress, _tokenId);
    }

    function removeWhitelist(address _nftAddress, uint256 _tokenId) public onlyOwner {
        require(isOnWhitelist(_nftAddress, _tokenId), "This nft tokenId is not on the whitelist");
        _whitelistMap[_nftAddress][_tokenId] = false;
        emit WhitelistedRemoved(_nftAddress, _tokenId);
    }

    function setDepositPointLimit(uint256 _limit) public onlyOwner {
        require(_limit > 0, "_limit should > 0");
        depositeInfoPointLimit = _limit;
    }

    function setPoolWhiteListOn(address _nftAddress, bool _on) public onlyOwner {
        require(nftAddresses.contains(_nftAddress), "Can not set non-existing farming pool");
        poolWhitelistOn[_nftAddress] = _on;
        emit Whitelisted(_nftAddress,_on);
    }

    function isPoolWhitelistOpen(address _nftAddress) public view returns (bool){
        return poolWhitelistOn[_nftAddress];
    }
}