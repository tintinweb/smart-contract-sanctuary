// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./WexRefferal.sol";
import "./WEX.sol";

interface IMigratorChef {
    function migrate(uint256 _pid, address _user, uint256 _amount, uint256[] memory _investments_amount, uint256[] memory _investments_lock_until) external;
}
// MasterChef is the master of Wedex. He can create new Wedex and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once Wedex is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract WedexChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    struct DepositAmount {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 lockUntil;
    }

    // Info of each user.
    struct UserInfo {
        uint256 amount;
        DepositAmount[] investments;
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 rewardLockedUp; // Reward locked up.
        uint256 nextHarvestUntil; // When can the user harvest again.
        uint256 startInvestmentPosition; //The first position haven't withdrawed

        //
        // We do some fancy math here. Basically, any point in time, the amount of WEDEXES
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accWedexPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accWedexPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken; // Address of LP token contract.
        uint256 totalAmount; // Total amount in pool
        uint256 lastRewardBlock; // Last block number that WEDEX distribution occurs.
        uint256 accWedexPerShare; // Accumulated WEDEX per share, times 1e12. See below.
        uint16 depositFeeBP; // Deposit fee in basis points
        uint256 harvestInterval; // Harvest interval in seconds
        uint256 lockingPeriod;
        uint256 fixedApr;
        uint256 tokenType; // 0 for wex token, 1 for other token, 2 for stable lp token, 3 for other lp
        address token1BusdLPaddress;
        uint256 directCommission; //commission pay direct for the Leader;
    }

    // The WEDEX TOKEN!
    Wedex public wedex;
    // Dev address.
    address public devAddress;
    // Deposit Fee address
    address public feeAddress;
    //busdAddress
    address public busdAddress = 0x55d398326f99059fF775485246999027B3197955;
    // uint256 public wedexPerBlock;
    // Bonus muliplier for early Wedex Holder.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Max harvest interval: 14 days.
    uint256 public constant MAXIMUM_HARVEST_INTERVAL = 14 days;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when Wedex mining starts.
    uint256 public startBlock;
    // Total locked up rewards
    uint256 public totalLockedUpRewards;
    bool public emergencyLockingWithdrawEnable = false;
    // Wedex referral contract address.
    WEXReferral public wedexReferral;
    uint256 public referDepth = 5;
    uint256[] public referralCommissionTier = [5000,4000,3000,2000,1000];

    address public wexLPAddress;
    IUniswapV2Router02 public pancakeRouterV2 = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    
    // variables for migrate
    IMigratorChef public newChefAddress;
    IMigratorChef public oldChefAddress;
    bool public isMigrating = false;
    uint256 constant BLOCKS_PER_YEAR = 10512000;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event EmissionRateUpdated(
        address indexed caller,
        uint256 previousAmount,
        uint256 newAmount
    );
    event ReferralCommissionPaid(
        address indexed user,
        address indexed referrer,
        uint256 commissionAmount
    );
    event RewardLockedUp(
        address indexed user,
        uint256 indexed pid,
        uint256 amountLockedUp
    );

    constructor(
        Wedex _wedex,
        uint256 _startBlock,
        address _wexLPAddress
    ) public {
        wedex = _wedex;
        startBlock = _startBlock;
        wexLPAddress = _wexLPAddress;

        devAddress = msg.sender;
        feeAddress = msg.sender;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    //Modifier to prevent adding the pool with the same token - I don't know what could happen here.
    // mapping(IBEP20 => bool) public poolExistence;
    // modifier nonDuplicated(IBEP20 _lpToken) {
    //     require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
    //     _;
    // }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(
        IBEP20 _lpToken,
        uint16 _depositFeeBP,
        uint256 _harvestInterval,
        uint256 _lockingPeriod,
    	uint256 _fixedApr,
    	uint256 _tokenType,
    	uint256 _directCommission,
        
        bool _withUpdate
    ) public onlyOwner {
        require(
            _depositFeeBP <= 10000,
            "add: invalid deposit fee basis points"
        );
        require(
            _harvestInterval <= MAXIMUM_HARVEST_INTERVAL,
            "add: invalid harvest interval"
        );
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;

        //poolExistence[_lpToken] = true;
        
        address _token1BusdLpaddress = 0x0000000000000000000000000000000000000000;
        if(_tokenType==1){
            _token1BusdLpaddress = IUniswapV2Factory(pancakeRouterV2.factory()).getPair(
                address(_lpToken),
                busdAddress
            );
        }
        if(_tokenType==3){
            _token1BusdLpaddress = IUniswapV2Factory(pancakeRouterV2.factory()).getPair(
                IUniswapV2Pair(address(_lpToken)).token0(),
                busdAddress
            );
        }
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                lastRewardBlock: lastRewardBlock,
                accWedexPerShare: 0,
                depositFeeBP: _depositFeeBP,
                harvestInterval: _harvestInterval,
                lockingPeriod: _lockingPeriod,
                fixedApr: _fixedApr,
                tokenType: _tokenType,
                totalAmount: 0,
                token1BusdLPaddress: _token1BusdLpaddress,
                directCommission: _directCommission
            })
        );
    }

    // Update the given pool's Wedex allocation point and deposit fee. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint16 _depositFeeBP,
        uint256 _harvestInterval,
    	uint256 _fixedApr,
    	uint256 _tokenType,
    	uint256 _directCommission,
        
        bool _withUpdate
    ) public onlyOwner {
        require(
            _depositFeeBP <= 10000,
            "set: invalid deposit fee basis points"
        );
        require(
            _harvestInterval <= MAXIMUM_HARVEST_INTERVAL,
            "set: invalid harvest interval"
        );
        if (_withUpdate) {
            massUpdatePools();
        }
            
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].harvestInterval = _harvestInterval;
        poolInfo[_pid].fixedApr = _fixedApr;
        poolInfo[_pid].tokenType = _tokenType;
        poolInfo[_pid].directCommission = _directCommission;
        if(_tokenType==1){
            poolInfo[_pid].token1BusdLPaddress = IUniswapV2Factory(pancakeRouterV2.factory()).getPair(
                address(poolInfo[_pid].lpToken),
                busdAddress
            );
        }
        if(_tokenType==3){
            poolInfo[_pid].token1BusdLPaddress = IUniswapV2Factory(pancakeRouterV2.factory()).getPair(
                IUniswapV2Pair( address(poolInfo[_pid].lpToken)).token0(),
                busdAddress
            );
        }
        updatePool(_pid);
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        pure
        returns (uint256)
    {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    function getWexPrice() public view returns (uint256) {
        // wexLPAddress
        return IBEP20(busdAddress).balanceOf(wexLPAddress).mul(1e2).div(wedex.balanceOf(wexLPAddress));
    }
    
    function getLPPrice(uint256 _pid) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        if(pool.tokenType == 0)
            return getWexPrice();
        if(pool.tokenType == 1)
            return IBEP20(busdAddress).balanceOf(pool.token1BusdLPaddress).mul(1e2).div(IBEP20(pool.lpToken).balanceOf(pool.token1BusdLPaddress));
        if(pool.tokenType == 2)
            return IBEP20(busdAddress).balanceOf(address(pool.lpToken)).mul(2e2).div(pool.lpToken.totalSupply());
        return IBEP20(busdAddress).balanceOf(pool.token1BusdLPaddress).div(IBEP20(pool.lpToken).balanceOf(pool.token1BusdLPaddress)).mul(2e2).div(pool.lpToken.totalSupply());
    }

    // View function to see pending Wedex on frontend.
    function pendingWedex(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accWedexPerShare = pool.accWedexPerShare;
        if (block.number > pool.lastRewardBlock) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            
            uint256 WedexReward = multiplier.mul(pool.fixedApr).mul(getLPPrice(_pid)).mul(1e12).div(getWexPrice()).div(BLOCKS_PER_YEAR.mul(100));

            accWedexPerShare = accWedexPerShare.add(WedexReward);
        }
        uint256 pending = user.amount.mul(accWedexPerShare).div(1e12).sub(
            user.rewardDebt
        );
        return pending.add(user.rewardLockedUp);
    }

    // View function to see if user can harvest Wedex.
    function canHarvest(uint256 _pid, address _user)
        public
        view
        returns (bool)
    {
        UserInfo storage user = userInfo[_pid][_user];
        return block.timestamp >= user.nextHarvestUntil;
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        if (pool.totalAmount == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        
        uint256 wedexReward = multiplier.mul(pool.fixedApr).mul(getLPPrice(_pid)).mul(pool.totalAmount).mul(1e12).div(BLOCKS_PER_YEAR.mul(100)).div(getWexPrice());

        wedex.mint(devAddress, wedexReward.div(1e12).div(10));
        wedex.mint(address(this), wedexReward.div(1e12));
        
        pool.accWedexPerShare = pool.accWedexPerShare.add(
            wedexReward.div(pool.totalAmount)
        );
        
        pool.lastRewardBlock = block.number;
    }
    
    function getLeader(address user) public view returns(address){
        (address referrer, bool vipBranch, uint256 leaderCommission) = wedexReferral.referrers(user);
        if(!vipBranch){
            return user;
        }
        return getLeader(referrer);
    }
    
    function getUpperVip(address user) public view returns(address) {
        address referrer = wedexReferral.getReferrer(user);
        while(!(wedexReferral.isVip(referrer) || referrer == address(0))){
            referrer = wedexReferral.getReferrer(referrer);
        }
        
        return referrer;
    }

    // Deposit LP tokens to MasterChef for Wedex allocation.
    function deposit(
        uint256 _pid,
        uint256 _amount,
        address _referrer,
        bool _vipBranch,
        uint256 _leaderCommission
    ) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (
            address(wedexReferral) != address(0) &&
            _referrer != address(0) &&
            _referrer != msg.sender &&
            wedexReferral.getReferrer(msg.sender) == address(0)
        ) {
            wedexReferral.recordReferral(msg.sender, _referrer,_vipBranch,_leaderCommission);
        }

        payOrLockupPendingWedex(_pid);
        if (_amount > 0) {
             pool.lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            if (address(wedexReferral) != address(0)) {
                (address referrer, bool vipBranch, uint256 leaderCommission) = wedexReferral.referrers(msg.sender);
                if (referrer != address(0)) {
                    uint256 totalFund = _amount.mul(getLPPrice(_pid)).div(1e2);
                    wedexReferral.addTotalFund(referrer, totalFund, 0);
                    if(pool.lockingPeriod > 0) {
                        payDirectCommission(_pid,_amount,vipBranch,leaderCommission,referrer);
                    }
                }
            }
            
            if (address(pool.lpToken) == address(wedex)) {
                uint256 transferTax = _amount.mul(wedex.transferTaxRate()).div(
                    10000
                );
                _amount = _amount.sub(transferTax);
            }
            
            if(pool.lockingPeriod > 0){
                user.investments.push(DepositAmount({
                    amount: _amount,
                    lockUntil: block.timestamp.add(pool.lockingPeriod)
                }));
            }

            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
                
                pool.totalAmount = pool.totalAmount.add(_amount).sub(depositFee);
            } else {
                user.amount = user.amount.add(_amount);
                
                pool.totalAmount = pool.totalAmount.add(_amount);
            }
            
        }
        if(isMigrating && user.amount > 0){
          uint256[] memory _investments_amount = new uint256[](user.investments.length);
          uint256[] memory _investments_lock_until = new uint256[](user.investments.length);
          
          for(uint256 i=0;i<user.investments.length;i++){
              _investments_amount[i] = user.investments[i].amount;
              _investments_lock_until[i] = user.investments[i].lockUntil;
          }

          pool.lpToken.approve(address(newChefAddress), user.amount);
          newChefAddress.migrate(_pid, msg.sender, user.amount, _investments_amount, _investments_lock_until);
          user.amount = 0;
        }
        user.rewardDebt = user.amount.mul(pool.accWedexPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }
    
    function migrate(uint256 _pid, address _user, uint256 _amount, uint256[] memory _investments_amount , uint256[] memory _investments_lock_until) external{
        require(msg.sender == address(oldChefAddress),"not Allow");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        
        pool.lpToken.safeTransferFrom(address(oldChefAddress), address(this), _amount);
        user.amount = user.amount.add(_amount);
        
        if(_investments_amount.length > 0 && _investments_amount.length == _investments_lock_until.length){
            for(uint256 i=0;i<_investments_amount.length;i++){
                user.investments.push(DepositAmount({
                    amount: _investments_amount[i],
                    lockUntil: _investments_lock_until[i]
                }));
            }
        }
        user.rewardDebt = user.amount.mul(pool.accWedexPerShare).div(1e12);
    }

    function setNewChefAddress(IMigratorChef _newChefAddress) public onlyOwner {
      newChefAddress = _newChefAddress;
    }
    
    function setOldChefAddress(IMigratorChef _oldChefAddress) public onlyOwner {
      oldChefAddress = _oldChefAddress;
    }
    
    function setIsMigrating(bool _isMigrating) public onlyOwner {
      isMigrating = _isMigrating;
    }
    
    function payDirectCommission(uint256 _pid,uint256 _amount, bool vipBranch, uint256 leaderCommission, address referrer) internal {
        uint256 lpPrice = getLPPrice(_pid);
        PoolInfo storage pool = poolInfo[_pid];
        
        uint256 directCommissionAmount = _amount.mul(lpPrice).mul(pool.directCommission).div(getWexPrice());
        
        if(vipBranch){
            wedex.mint(
                address(referrer),
                directCommissionAmount.mul(uint256(10).sub(leaderCommission)).div(1e3)
            );
            wedexReferral.recordReferralCommission(referrer, directCommissionAmount.mul(uint256(10).sub(leaderCommission)).div(1e3));
            
            if(getLeader(msg.sender) != address(0)){
                wedex.mint(
                    getLeader(msg.sender),
                    directCommissionAmount.mul(leaderCommission).div(1e3)
                );
                wedexReferral.recordReferralCommission(
                    getLeader(msg.sender),
                    directCommissionAmount.mul(leaderCommission).div(1e3)
                );
            }
            
        } else {
            wedex.mint(
                address(referrer),
                directCommissionAmount.mul(7).div(1e3)
            );
            wedexReferral.recordReferralCommission(referrer,directCommissionAmount.mul(7).div(1e3));
            
            
            address upperVip = getUpperVip(msg.sender);
            if(upperVip!=address(0)){
                wedex.mint(
                    upperVip,
                    directCommissionAmount.mul(3).div(1e3)
                );  
                wedexReferral.recordReferralCommission(upperVip,directCommissionAmount.mul(3).div(1e3));
            }
        }
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        
        require(user.amount >= _amount, "withdraw: not good");
        require(pool.lockingPeriod == 0, "withdraw: not good");

        updatePool(_pid);
        payOrLockupPendingWedex(_pid);
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.totalAmount = pool.totalAmount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            if (
                address(wedexReferral) != address(0) &&
                wedexReferral.getReferrer(msg.sender) != address(0)
            ) {
                wedexReferral.reduceTotalFund(
                    wedexReferral.getReferrer(msg.sender),
                    _amount.mul(getLPPrice(_pid)).div(1e2),
                    0
                );
            }
        }
        user.rewardDebt = user.amount.mul(pool.accWedexPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function withdrawInvestment(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(pool.lockingPeriod > 0, "withdraw: not good");

        updatePool(_pid);
        payOrLockupPendingWedex(_pid);

        uint _startInvestmentPosition = 0;
        uint256 _totalWithdrawalAmount = 0;

        for(uint i=user.startInvestmentPosition; i<user.investments.length;i++){
            
            if(user.investments[i].amount > 0 && user.investments[i].lockUntil <= block.timestamp){
                _totalWithdrawalAmount = _totalWithdrawalAmount.add(user.investments[i].amount);
                user.investments[i].amount = 0;
                _startInvestmentPosition = i+1;
            } else {
                break;
            }
            
        }

        if(_startInvestmentPosition > user.startInvestmentPosition){
            user.startInvestmentPosition = _startInvestmentPosition;
        }
        if(_totalWithdrawalAmount > 0 && _totalWithdrawalAmount <= user.amount){
            user.amount = user.amount.sub(_totalWithdrawalAmount);
            pool.totalAmount = pool.totalAmount.sub(_totalWithdrawalAmount);
            pool.lpToken.safeTransfer(address(msg.sender), _totalWithdrawalAmount);

            if (
                address(wedexReferral) != address(0) &&
                wedexReferral.getReferrer(msg.sender) != address(0)
            ) {
                wedexReferral.reduceTotalFund(
                    wedexReferral.getReferrer(msg.sender),
                    _totalWithdrawalAmount.mul(getLPPrice(_pid)).div(1e2),
                    0
                );
            }
        }
        user.rewardDebt = user.amount.mul(pool.accWedexPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _totalWithdrawalAmount);
    }

    function getFreeInvestmentAmount(uint256 _pid, address _user) public view returns (uint256) {
        UserInfo storage user = userInfo[_pid][_user];
        uint256 _total = 0;

        for(uint i=user.startInvestmentPosition; i<user.investments.length;i++){
            if(user.investments[i].amount > 0 && user.investments[i].lockUntil <= block.timestamp){
                _total = _total.add(user.investments[i].amount);
            } else {
                break;
            }
        }

        return _total;
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(pool.lockingPeriod == 0 || emergencyLockingWithdrawEnable, "withdraw: not good");
        uint256 amount = user.amount;
        user.amount = 0;
        pool.totalAmount = pool.totalAmount.sub(amount);
        user.rewardDebt = 0;
        user.rewardLockedUp = 0;
        user.nextHarvestUntil = 0;
        if (
            address(wedexReferral) != address(0) &&
            wedexReferral.getReferrer(msg.sender) != address(0)
        ) {
            wedexReferral.reduceTotalFund(
                wedexReferral.getReferrer(msg.sender),
                amount.mul(getLPPrice(_pid)).div(1e2),
                0
            );
        }
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Pay or lockup pending Wedex.
    function payOrLockupPendingWedex(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.nextHarvestUntil == 0) {
            user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);
        }

        uint256 pending = user.amount.mul(pool.accWedexPerShare).div(1e12).sub(
            user.rewardDebt
        );
        if (canHarvest(_pid, msg.sender)) {
            if (pending > 0 || user.rewardLockedUp > 0) {
                uint256 totalRewards = pending.add(user.rewardLockedUp);

                // reset lockup
                totalLockedUpRewards = totalLockedUpRewards.sub(
                    user.rewardLockedUp
                );
                user.rewardLockedUp = 0;
                user.nextHarvestUntil = block.timestamp.add(
                    pool.harvestInterval
                );

                // send rewards
                safeWedexTransfer(msg.sender, totalRewards);
                payReferralCommission(msg.sender, totalRewards, 0);
            }
        } else if (pending > 0) {
            user.rewardLockedUp = user.rewardLockedUp.add(pending);
            totalLockedUpRewards = totalLockedUpRewards.add(pending);
            emit RewardLockedUp(msg.sender, _pid, pending);
        }
    }

    // Safe Wedex transfer function, just in case if rounding error causes pool to not have enough Wedex to pay.
    function safeWedexTransfer(address _to, uint256 _amount) internal {
        uint256 wedexBal = wedex.balanceOf(address(this));
        if (_amount > wedexBal) {
            wedex.transfer(_to, wedexBal);
        } else {
            wedex.transfer(_to, _amount);
        }
    }

    function setReferDepth(uint256 _depth) public onlyOwner {
        referDepth = _depth;
    }
    function setReferralCommissionTier(uint256[] memory _referralCommissionTier) public onlyOwner {
        referralCommissionTier = _referralCommissionTier;
    }
    function setWexLpAddress (address _wexLPAddress) public onlyOwner {
        wexLPAddress = _wexLPAddress;
    }
    // Update dev address by the previous dev.
    function setDevAddress(address _devAddress) public {
        require(msg.sender == devAddress, "setDevAddress: FORBIDDEN");
        require(_devAddress != address(0), "setDevAddress: ZERO");
        devAddress = _devAddress;
    }

    function setFeeAddress(address _feeAddress) public {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        require(_feeAddress != address(0), "setFeeAddress: ZERO");
        feeAddress = _feeAddress;
    }
    
    function setPancakeRouterV2 (IUniswapV2Router02 _pancakeRouterV2) external onlyOwner
    {
        pancakeRouterV2 = _pancakeRouterV2;
    }
    function setBusdAddress (address _busdAddress) external onlyOwner
    {
        busdAddress = _busdAddress;
    }

    // Update the Wedex referral contract address by the owner
    function setWedexReferral(WEXReferral _wedexReferral) public onlyOwner {
        wedexReferral = _wedexReferral;
    }
    //Update the EmergencyWithdrawEnable
    function setEmergencyWithdrawEnable(bool _emergencyWithdrawEnable) public onlyOwner {
        emergencyLockingWithdrawEnable = _emergencyWithdrawEnable;
    }
    
    function getReferralCommissionRate(uint256 depth) private view returns (uint256){
        return referralCommissionTier[depth];
    }

    // Pay referral commission to the referrer who referred this user.
    function payReferralCommission(
        address _user,
        uint256 _pending,
        uint256 depth
    ) internal {
        if (depth < referDepth) {
            if (address(wedexReferral) != address(0)) {
                address _referrer  = wedexReferral.getReferrer(_user);
                
                uint256 commissionAmount = _pending
                    .mul(getReferralCommissionRate(depth))
                    .div(10000);
    
                if (commissionAmount > 0 && _referrer!=address(0)) {
                    wedex.mint(_referrer, commissionAmount);
                    wedexReferral.recordReferralCommission(
                        _referrer,
                        commissionAmount
                    );
                    emit ReferralCommissionPaid(_user, _referrer, commissionAmount);
                        payReferralCommission(
                            _referrer,
                            _pending,
                            depth.add(1)
                        );
                    }
            }
        }
    }
    
}