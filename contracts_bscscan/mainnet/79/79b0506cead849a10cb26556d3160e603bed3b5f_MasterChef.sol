// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./SafeMath.sol";
import "./IBEP20Mintable.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./IReferral.sol";
import "./Referral.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC1155.sol";


contract Reserve is Ownable {
    IBEP20 rewardToken;
    constructor(IBEP20 token) public {
        rewardToken = token;
    }
    
    function safeTransfer(address _to, uint256 _amount) external onlyOwner {
        uint256 tokenBal = rewardToken.balanceOf(address(this));
        if (_amount > tokenBal) {
            rewardToken.transfer(_to, tokenBal);
        } else {
            rewardToken.transfer(_to, _amount);
        }
    }
}

contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 rewardLockedUp;  // Reward locked up.
        uint256 nextHarvestUntil; // When can the user harvest again.
    }

    struct PoolInfo {
        IBEP20 token;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accTokenPerShare;
        uint16 depositFeeBP;
        uint256 minDeposit;
        uint256 harvestInterval;  // Harvest interval in seconds
        uint256 nftId;
        uint256 minNft;
    }

    IBEP20Mintable public token;
    IERC1155 public nft;
    Reserve public rewardReserve;
    address public devaddr;
    uint256 public tokenPerBlock;
    uint256 public devReward;
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Max harvest interval: 14 days.
    uint256 public constant MAXIMUM_HARVEST_INTERVAL = 14 days;
    uint256 public totalLockedUpRewards;
    address public feeAddress;
    // The maximum supply for AME will be 80,640
    uint256 public constant maxSupply = 80640e18;
    
    mapping(address => bool) exists;

    PoolInfo[] public poolInfo;
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    address public setup;
    uint256 public totalAllocPoint = 0;
    uint256 public startBlock;
    bool public paused = true;
    bool public initialized = false;

    IReferral public referral;
    uint16 public referralCommissionRate = 0;
    uint16 public constant MAXIMUM_REFERRAL_COMMISSION_RATE = 1000;

    modifier onlyOwnerAndSetup() {
        require(owner() == _msgSender() || setup == _msgSender(), "CHEF: caller is not the owner or setup");
        _;
    }
    
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardLockedUp(address indexed user, uint256 indexed pid, uint256 amountLockedUp);
    event ReferralCommissionPaid(address indexed user, address indexed referrer, uint256 commissionAmount);

    constructor(
        IBEP20Mintable _token,
        address _setup,
        address _owner
    ) public {
        token = _token;
        setup = _setup;
        devaddr = _owner;
        feeAddress = _owner;
        tokenPerBlock = 30e18;
        devReward = 1500;
        startBlock = 10888888;
        rewardReserve = new Reserve(_token);
        transferOwnership(_owner);
    }
    
    function startFarming() public onlyOwner {
        require(!initialized,"Farming already started!");
        initialized = true;
        paused = false;
        startBlock = block.number;
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            poolInfo[pid].lastRewardBlock = startBlock;
        }
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function add(uint256 _allocPoint, IBEP20 _token, uint16 _depositFeeBP, uint256 _minDeposit, uint256 _harvestInterval, uint256 _nftId, uint256 _minNft) public onlyOwnerAndSetup {
        require(poolInfo.length <= 1000, "Pool Length Full!");
        require(!exists[address(_token)], "Already Exists!");
        require(_depositFeeBP <= 400, "add: invalid deposit fee basis points");
        require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "add: invalid harvest interval");
        
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            token: _token,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accTokenPerShare: 0,
            depositFeeBP: _depositFeeBP,
            minDeposit: _minDeposit,
            harvestInterval: _harvestInterval,
            nftId: _nftId,
            minNft: _minNft
        }));
        exists[address(_token)] = true;
    }

    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, uint256 _minDeposit, uint256 _harvestInterval, uint256 _nftId, uint256 _minNft) public onlyOwnerAndSetup {
        require(_depositFeeBP <= 400, "set: invalid deposit fee basis points");
        require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "add: invalid harvest interval");
        
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].minDeposit = _minDeposit;
        poolInfo[_pid].harvestInterval = _harvestInterval;
        poolInfo[_pid].nftId = _nftId;
        poolInfo[_pid].minNft = _minNft;
    }

    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (token.totalSupply() >= maxSupply) {
            return 0;
        }
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    function pendingToken(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 lpSupply = pool.token.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 tokenReward = multiplier.mul(tokenPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accTokenPerShare = accTokenPerShare.add(tokenReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accTokenPerShare).div(1e12).sub(user.rewardDebt);
    }

    // View function to see if user can harvest AME.
    function canHarvest(uint256 _pid, address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_pid][_user];
        return block.timestamp >= user.nextHarvestUntil;
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 tokenBalance = pool.token.balanceOf(address(this));
        if (tokenBalance == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 tokenReward = multiplier.mul(tokenPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        if (token.totalSupply().add(tokenReward) > maxSupply) {
            tokenReward = maxSupply.sub(token.totalSupply());
        } 
        token.mint(devaddr, tokenReward.mul(devReward).div(10000));
        token.mint(address(rewardReserve), tokenReward);
        pool.accTokenPerShare = pool.accTokenPerShare.add(tokenReward.mul(1e12).div(tokenBalance));
        pool.lastRewardBlock = block.number;
    }

    function deposit(uint256 _pid, uint256 _amount, address _referrer) public {
        require(paused == false, "Paused!");
        require(token.balanceOf(msg.sender) >= poolInfo[_pid].minDeposit,"Not Enough Required Tokens!");
        if(address(nft) != address(0) && poolInfo[_pid].minNft > 0) {
            require(nft.balanceOf(msg.sender,poolInfo[_pid].nftId) >= poolInfo[_pid].minNft,"Not Enough Required NFT!");
        }
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (_amount > 0 && address(referral) != address(0) && _referrer != address(0) && _referrer != msg.sender) {
            referral.recordReferral(msg.sender, _referrer);
        }
        payOrLockupPendingToken(_pid);
        if(_amount > 0) {
            // track balance before and after calling tranferFrom to incorporate tokens that charge a fee on transfer
            uint256 initialBalance = pool.token.balanceOf(address(this));
            pool.token.safeTransferFrom(address(msg.sender), address(this), _amount);
            uint256 finalBalance = pool.token.balanceOf(address(this));
            uint256 delta = finalBalance.sub(initialBalance);
            if(pool.depositFeeBP > 0){
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.token.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(delta).sub(depositFee);
            }else{
                user.amount = user.amount.add(delta);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        payOrLockupPendingToken(_pid);
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.token.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function payOrLockupPendingToken(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.nextHarvestUntil == 0) {
            user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);
        }

        uint256 pending = user.amount.mul(pool.accTokenPerShare).div(1e12).sub(user.rewardDebt);
        if (canHarvest(_pid, msg.sender)) {
            if (pending > 0 || user.rewardLockedUp > 0) {
                uint256 totalRewards = pending.add(user.rewardLockedUp);

                // reset lockup
                totalLockedUpRewards = totalLockedUpRewards.sub(user.rewardLockedUp);
                user.rewardLockedUp = 0;
                user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);

                // send rewards
                rewardReserve.safeTransfer(msg.sender, totalRewards);
                payReferralCommission(msg.sender, totalRewards);
            }
        } else if (pending > 0) {
            user.rewardLockedUp = user.rewardLockedUp.add(pending);
            totalLockedUpRewards = totalLockedUpRewards.add(pending);
            emit RewardLockedUp(msg.sender, _pid, pending);
        }
    }

    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        user.rewardLockedUp = 0;
        user.nextHarvestUntil = 0;
        pool.token.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    function setNFT(IERC1155 _nft) external onlyOwnerAndSetup {
        nft = _nft;
    }

    function updateEmissionRate(uint256 _tokenPerBlock, uint _devReward) public onlyOwner {
        massUpdatePools();
        tokenPerBlock = _tokenPerBlock;
        devReward = _devReward;
    }

    function setReferral(IReferral _referral) public onlyOwnerAndSetup {
        referral = _referral;
    }

    function setReferralCommissionRate(uint16 _referralCommissionRate) public onlyOwner {
        require(_referralCommissionRate <= MAXIMUM_REFERRAL_COMMISSION_RATE, "setReferralCommissionRate: invalid referral commission rate basis points");
        referralCommissionRate = _referralCommissionRate;
    }

    function payReferralCommission(address _user, uint256 _pending) internal {
        if (address(referral) != address(0) && referralCommissionRate > 0) {
            address referrer = referral.getReferrer(_user);
            uint256 commissionAmount = _pending.mul(referralCommissionRate).div(10000);

            if (referrer != address(0) && commissionAmount > 0) {
                token.mint(referrer, commissionAmount);
                referral.recordReferralCommission(referrer, commissionAmount);
                emit ReferralCommissionPaid(_user, referrer, commissionAmount);
            }
        }
    }

    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

    function setFeeAddress(address _feeAddress) public {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        feeAddress = _feeAddress;
    }

    function updateSetup(address _setup) public onlyOwnerAndSetup {
        setup = _setup;
    }

    function updatePaused(bool _value) public onlyOwner {
        paused = _value;
    }
}