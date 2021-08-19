// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

//  .----------------.  .----------------.  .----------------.  .----------------.  .----------------. 
// | .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
// | |  ___  ____   | || |     ____     | || |      __      | || |   _____      | || |      __      | |
// | | |_  ||_  _|  | || |   .'    `.   | || |     /  \     | || |  |_   _|     | || |     /  \     | |
// | |   | |_/ /    | || |  /  .--.  \  | || |    / /\ \    | || |    | |       | || |    / /\ \    | |
// | |   |  __'.    | || |  | |    | |  | || |   / ____ \   | || |    | |   _   | || |   / ____ \   | |
// | |  _| |  \ \_  | || |  \  `--'  /  | || | _/ /    \ \_ | || |   _| |__/ |  | || | _/ /    \ \_ | |
// | | |____||____| | || |   `.____.'   | || ||____|  |____|| || |  |________|  | || ||____|  |____|| |
// | |              | || |              | || |              | || |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
// '----------------'  '----------------'  '----------------'  '----------------'  '----------------' 

// website : https://koaladefi.finance/
// twitter : https://twitter.com/KoalaDefi

import "./ReentrancyGuard.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./IReferral.sol";
import "./ILocker.sol";
import "./Address.sol";
import "./SafeBEP20.sol";
import "./SafeMath.sol";
import "./BEP20.sol";
import "./NALISToken.sol";


// MasterChef is the master of Nalis. He can make Nalis and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once NALIS is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        uint256 rewardLockedUp;  // Reward locked up.
        uint256 nextHarvestUntil; // When can the user harvest again.
        uint256 noWithdrawalFeeAfter; //No withdrawal fee after this duration
        //
        // We do some fancy math here. Basically, any point in time, the amount of NALISs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accNalisPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accNalisPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. NALISs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that NALISs distribution occurs.
        uint256 accNalisPerShare;   // Accumulated NALISs per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
        uint256 dynamicDepositFeeBP;      // Dynamic deposit fee in basis points
        uint256 lpPriceMA7;     // LP or token price based on moving avarage price from last 7 days / Regulary updated by the operator
        uint256 totalBuybackBurnDepFee; // Store the total amount of buyback and burn dep fee in the pool since the last reset
        uint256 harvestInterval;  // Harvest interval in seconds
        uint256 withdrawalFeeInterval; // Withdrawal fee minimum interval in seconds
        uint256 withdrawalFeeBP; // Withdrawal fee in basis points when the withdrawal occurs before the minimum interval
    }

    // NALIS token
    NalisToken public nalis;
    // LYPTUS token
    IBEP20 public lyptus;
    // Lyptus price based on moving avarage price from last 7 days / Regulary updated by the operator
    uint256 public lyptusPriceMA7=0;
    
    // Dev address.
    address public devAddress;
    // Deposit Fee address
    address public feeAddress;
    // Deposit Charity address
    address public charityAddress;    
    // Lottery contract address : default address is the burn address and will be updated when lottery release
    address public lotteryAddress;
    // NALIS tokens created per block.
    uint256 public nalisPerBlock;
    // Maximum emission rate : nalisPerBlock can't be more than 50 per block
    uint256 public constant MAX_EMISSION_RATE = 50000000000000000000;    
    // Bonus muliplier for early nalis makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Max harvest interval: 14 days.
    uint256 public constant MAXIMUM_HARVEST_INTERVAL = 14 days;
    // Max harvest interval: 14 days.
    uint256 public constant MAXIMUM_WITHDRAWFEE_INTERVAL = 5 days;    
    // Max deposit fee : 10% (in basis point)
    uint256 public constant MAXIMUM_DEPOSIT_FEE = 1000;
    // Max withdrawal fee : 10% (in basis point)
    uint256 public constant MAXIMUM_WITHDRAWAL_FEE = 1000;   
    // Lottery mint rate : maximum 4% (in basis point) :  default rate is 0 and will be updated when lottery release
    uint16 public lotteryMintRate;
    // Burn address
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;  
    // Charity fee is a part of deposit fee (in basis point)
    uint16 public charityFeeBP;
    // Charity fee is a part of deposit fee (in basis point)
    uint16 public lyptusDiscountFeeBP;    
    // Locker interface
    ILocker nalisLocker;
    // Locker adresse
    address public nalisLockerAddress;
    // Locker rate (in basis point) if = 0 locker desactivated
    uint16 public lockerRate;
    // Addresses that are excluded from locker - Used only for vault purposes during the launch locker period
    mapping(address => bool) private _excludedFromLocker;  
    

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when NALIS mining starts.
    uint256 public startBlock;
    // Total locked up rewards
    uint256 public totalLockedUpRewards;

    // Nalis referral contract address.
    IReferral public nalisReferral;
    // Referral commission rate in basis points.
    uint16 public referralCommissionRate = 100;
    
    // The operator can only update the lyptusPriceMA7 + lpPriceMA7 & reset totaldynamicdepfee & change operator adresse
    address private _operator;  

    // Events
    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event BurnLyptus(address indexed user,address indexed target, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmissionRateUpdated(address indexed caller, uint256 previousAmount, uint256 newAmount);
    event ReferralCommissionPaid(address indexed user, address indexed referrer, uint256 newAmount);
    event RewardLockedUp(address indexed user, uint256 indexed pid, uint256 newAmount);
    event FeeAddressUpdated(address indexed user, address indexed newAddress);
    event CharityAddressUpdated(address indexed user, address indexed newAddress);
    event CharityFeeRateUpdated(address indexed user, uint256 previousAmount, uint16 newAmount);
    event LyptusDiscountFeeRateUpdated(address indexed user, uint256 previousAmount, uint16 newAmount);
    event DevAddressUpdated(address indexed user, address indexed newAddress);
    event NalisReferralUpdated(address indexed user, IReferral newAddress);
    event NalisLockerUpdated(address indexed user, address newAddress);
    event LockerRateUpdated(address indexed user, uint256 previousAmount, uint256 newAmount);
    event ReferralRateUpdated(address indexed user, uint256 previousAmount, uint256 newAmount);
    event LotteryAddressUpdated(address indexed user, address indexed newAddress);
    event LotteryMintRateUpdated(address indexed user, uint256 previousAmount, uint16 newAmount);
    event LyptusPriceMA7Updated(address indexed user, uint256 previousAmount, uint256 newAmount);
    event LpPriceMA7Updated(address indexed user, uint256 previousAmount, uint256 newAmount);
    event TotalBuybackBurnDepFeeReseted(address indexed user, uint256 previousAmount, uint256 newAmount);
    event ExcludedFromLocker(address indexed exludedAdresse, bool indexed excludedStatut);
    
    // Modifiers
    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    constructor(
        NalisToken _nalis,
        IBEP20 _lyptus,
        uint256 _startBlock,
        uint256 _nalisPerBlock,
        address _nalisLockerAddress
    ) public {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);        
        nalis = _nalis;
        lyptus = _lyptus;
        startBlock = _startBlock;
        nalisPerBlock = _nalisPerBlock;
        lotteryAddress = BURN_ADDRESS;
        lotteryMintRate = 0;
        charityFeeBP = 1000;
        lyptusDiscountFeeBP = 5000;
        lockerRate = 5000;

        devAddress = msg.sender;
        feeAddress = msg.sender;
        charityAddress = msg.sender;
        nalisLockerAddress = _nalisLockerAddress;
        nalisLocker = ILocker(_nalisLockerAddress);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }
    
	// add a check for avoid duplicate lptoken
    mapping(IBEP20 => bool) public poolExistence;
    modifier nonDuplicated(IBEP20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }    

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, IBEP20 _lpToken, uint16 _depositFeeBP, uint256 _dynamicDepositFeeBP, uint256 _lpPriceMA7, uint256 _harvestInterval, uint256 _withdrawalFeeInterval, uint256 _withdrawalFeeBP, bool _withUpdate) public onlyOwner nonDuplicated(_lpToken) {
        // test if the lptoken address is a token contract
        require(_lpToken.balanceOf(address(_lpToken)) >=0, "add: try to add non token contracdt");
        // deposit fee can't excess more than 10%
        require(_depositFeeBP <= MAXIMUM_DEPOSIT_FEE, "add: invalid deposit fee basis points");
        // dynamic deposit fee can't excess more than 10%
        require(_dynamicDepositFeeBP <= MAXIMUM_DEPOSIT_FEE, "set: invalid dynamic deposit fee basis points");         
        // withdrawal fee can't excess more than 10%
        require(_withdrawalFeeBP <= MAXIMUM_WITHDRAWAL_FEE, "add: invalid deposit fee basis points");      
        require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "add: invalid harvest interval");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExistence[_lpToken] = true;
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accNalisPerShare: 0,
            depositFeeBP: _depositFeeBP,
            dynamicDepositFeeBP: _dynamicDepositFeeBP,
            lpPriceMA7: _lpPriceMA7,
            totalBuybackBurnDepFee: 0,
            harvestInterval: _harvestInterval,
            withdrawalFeeInterval: _withdrawalFeeInterval,
            withdrawalFeeBP: _withdrawalFeeBP
        }));
    }

    // Update the given pool's NALIS allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, uint16 _dynamicDepositFeeBP, uint256 _lpPriceMA7, uint256 _harvestInterval, uint256 _withdrawalFeeInterval, uint256 _withdrawalFeeBP, bool _withUpdate) public onlyOwner {
        // deposit fee can't excess more than 10%
        require(_depositFeeBP <= MAXIMUM_DEPOSIT_FEE, "set: invalid deposit fee basis points");
        // dynamic deposit fee can't excess more than 10%
        require(_dynamicDepositFeeBP <= MAXIMUM_DEPOSIT_FEE, "set: invalid dynamic deposit fee basis points");        
        // withdrawal fee can't excess more than 10%
        require(_withdrawalFeeBP <= MAXIMUM_WITHDRAWAL_FEE, "add: invalid deposit fee basis points");         
        require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "set: invalid harvest interval");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].dynamicDepositFeeBP = _dynamicDepositFeeBP;
        poolInfo[_pid].lpPriceMA7 = _lpPriceMA7;
        poolInfo[_pid].harvestInterval = _harvestInterval;
        poolInfo[_pid].withdrawalFeeInterval = _withdrawalFeeInterval;
        poolInfo[_pid].withdrawalFeeBP = _withdrawalFeeBP;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending NALISs on frontend.
    function pendingNalis(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accNalisPerShare = pool.accNalisPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 nalisReward = multiplier.mul(nalisPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accNalisPerShare = accNalisPerShare.add(nalisReward.mul(1e12).div(lpSupply));
        }
        uint256 pending = user.amount.mul(accNalisPerShare).div(1e12).sub(user.rewardDebt);
        return pending.add(user.rewardLockedUp);
    }

    // View function to see if user can harvest NALISs.
    function canHarvest(uint256 _pid, address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_pid][_user];
        return block.timestamp >= user.nextHarvestUntil;
    }
    
    // View function to see if user withdrawal fees apply to the harvest
    // return true if time is over
    function noWithdrawFee(uint256 _pid, address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_pid][_user];
        return block.timestamp >= user.noWithdrawalFeeAfter;
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
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 nalisReward = multiplier.mul(nalisPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        nalis.mint(devAddress, nalisReward.mul(100).div(1000));
        // Automatically burn 2% of minted tokens
        nalis.mint(BURN_ADDRESS, nalisReward.mul(20).div(1000));
        // Automatically mint some NALIS for the lottery pot
        if (address(lotteryAddress) != address(0) && lotteryMintRate > 0) {
            nalis.mint(lotteryAddress, nalisReward.mul(lotteryMintRate).div(10000));
        }        
        nalis.mint(address(this), nalisReward);
        pool.accNalisPerShare = pool.accNalisPerShare.add(nalisReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for NALIS allocation.
    function deposit(uint256 _pid, uint256 _amount, address _referrer, bool _lyptusFee) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        
        uint256 dynamicDepositFee = 0;
        
        // force lyptusfee to false if lyptus address is not yet set
        if (address(lyptus) == 0x000000000000000000000000000000000000dEaD) {
            _lyptusFee=false;
        }
        
        // Dynamic deposit fee are only applied if deposit fee are set > 0
        // dynamic fee type
        if (_amount > 0 && _lyptusFee==true && pool.dynamicDepositFeeBP>0 && pool.depositFeeBP > 0) {
            // A Type Fee : part of the fee is payed in LYPTUS token
            
            require(lyptusPriceMA7 > 0, "lyptus price not valid");
            require(pool.lpPriceMA7 > 0, "lp price not valid");
            require(lyptusDiscountFeeBP > 0, "lyptuDiscountFeeBP not valid");
            
            uint256 lyptusAmount = 0;
            uint256 lyptusFee =  pool.dynamicDepositFeeBP.mul(lyptusDiscountFeeBP).div(10000);

            uint256 amountMulByPrice = _amount.mul(pool.lpPriceMA7);
            lyptusAmount = ((amountMulByPrice.mul(lyptusFee).div(10000)).mul(1e18)).div(lyptusPriceMA7);
            lyptusAmount = lyptusAmount.div(1e18);
            
            emit BurnLyptus(msg.sender,BURN_ADDRESS, lyptusAmount);
            
            lyptus.transferFrom(msg.sender,BURN_ADDRESS,lyptusAmount);
            dynamicDepositFee = 0;
        }    
        else if (_amount > 0 && _lyptusFee==false && pool.dynamicDepositFeeBP>0 && pool.depositFeeBP > 0) {
            // B Type Fee : all fee is payed in deposit token

            dynamicDepositFee = _amount.mul(pool.dynamicDepositFeeBP).div(10000);
            // The part which is not payed in LYPTUS will serve for buyback and burn LYPTUS
            uint256 buybackBurnDepFee = dynamicDepositFee.mul(lyptusDiscountFeeBP).div(10000);
            pool.totalBuybackBurnDepFee = pool.totalBuybackBurnDepFee.add(buybackBurnDepFee);
        }
        
        updatePool(_pid);
        
        if (_amount > 0 && address(nalisReferral) != address(0) && _referrer != address(0) && _referrer != BURN_ADDRESS && _referrer != msg.sender) {
            nalisReferral.recordReferral(msg.sender, _referrer);
        }
        payOrLockupPendingNalis(_pid,false);
        if (_amount > 0) {
            // Handle any token with transfer tax
            uint256 balanceBefore = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            _amount = pool.lpToken.balanceOf(address(this)).sub(balanceBefore);
            
            if (pool.depositFeeBP > 0) {
                if (charityFeeBP > 0) {
                    uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                    uint256 charityFee = depositFee.mul(charityFeeBP).div(10000);
                    user.amount = user.amount.add(_amount).sub(depositFee).sub(dynamicDepositFee);
                    pool.lpToken.safeTransfer(feeAddress, depositFee.sub(charityFee).add(dynamicDepositFee));
                    pool.lpToken.safeTransfer(charityAddress, charityFee);
                } else {
                    uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                    user.amount = user.amount.add(_amount).sub(depositFee).sub(dynamicDepositFee);
                    pool.lpToken.safeTransfer(feeAddress, depositFee.add(dynamicDepositFee));
                }  
            } else {
                user.amount = user.amount.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accNalisPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        payOrLockupPendingNalis(_pid,true);
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accNalisPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        user.rewardLockedUp = 0;
        user.nextHarvestUntil = 0;
        user.noWithdrawalFeeAfter = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Pay or lockup pending NALISs.
    function payOrLockupPendingNalis(uint256 _pid, bool _isWithdrawal) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if (user.nextHarvestUntil == 0) {
            user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);
        }
        
        if (user.noWithdrawalFeeAfter == 0) {
            user.noWithdrawalFeeAfter = block.timestamp.add(pool.withdrawalFeeInterval);
        }        

        // pending reward for user
        uint256 pending = user.amount.mul(pool.accNalisPerShare).div(1e12).sub(user.rewardDebt);
        
        if (_isWithdrawal) {
             // if user withdrawal before the interval, user get X% less of pending reward               
            if (noWithdrawFee(_pid, msg.sender)==false) {
                uint256 withdrawalfeeamount = pending.mul(pool.withdrawalFeeBP).div(10000);
                pending = pending.sub(withdrawalfeeamount);
                // tax on withdrawal is send to the burn address
                safeNalisTransfer(BURN_ADDRESS, withdrawalfeeamount);     
            }
            // reset timer at each withdrawal
            user.noWithdrawalFeeAfter = block.timestamp.add(pool.withdrawalFeeInterval);                
        }
        
        if (canHarvest(_pid, msg.sender)) {
            if (pending > 0 || user.rewardLockedUp > 0) {
                uint256 totalRewards = pending.add(user.rewardLockedUp);

                // reset lockup
                totalLockedUpRewards = totalLockedUpRewards.sub(user.rewardLockedUp);
                user.rewardLockedUp = 0;
                user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);
                
                if (address(nalisLocker) != address(0) && _excludedFromLocker[msg.sender] == false){
                    uint256 startReleaseBlock = ILocker(nalisLocker).getStartReleaseBlock();
                    if (lockerRate > 0 && block.number < startReleaseBlock) {
                        uint256 _lockerAmount = totalRewards.mul(lockerRate).div(10000);
                        totalRewards = totalRewards.sub(_lockerAmount);
                        IBEP20(nalis).safeIncreaseAllowance(address(nalisLockerAddress), _lockerAmount);
                        ILocker(nalisLocker).lock(msg.sender, _lockerAmount); 
                    }
                }
                
                // send rewards 
                safeNalisTransfer(msg.sender, totalRewards);
                payReferralCommission(msg.sender, totalRewards); // extra mint for referral
            }
        } else if (pending > 0) {
            user.rewardLockedUp = user.rewardLockedUp.add(pending);
            totalLockedUpRewards = totalLockedUpRewards.add(pending);
            emit RewardLockedUp(msg.sender, _pid, pending);
        }
    }

    // Safe nalis transfer function, just in case if rounding error causes pool to not have enough NALISs.
    function safeNalisTransfer(address _to, uint256 _amount) internal {
        uint256 nalisBal = nalis.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > nalisBal) {
            transferSuccess = nalis.transfer(_to, nalisBal);
        } else {
            transferSuccess = nalis.transfer(_to, _amount);
        }
        require(transferSuccess, "safeNalisTransfer: transfer failed");
    }

    // Update dev address by the previous dev address
    function setDevAddress(address _devAddress) public {
        require(msg.sender == devAddress, "setDevAddress: FORBIDDEN");
        require(_devAddress != address(0), "setDevAddress: ZERO");
        devAddress = _devAddress;
        emit DevAddressUpdated(msg.sender, _devAddress);
    }

    //Update fee address by the previous fee address
    function setFeeAddress(address _feeAddress) public {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        require(_feeAddress != address(0), "setFeeAddress: ZERO");
        feeAddress = _feeAddress;
        emit FeeAddressUpdated(msg.sender, _feeAddress);
    }
    
    //Update charity address by the previous charity address
    function setCharityAddress(address _charityAddress) public {
        require(msg.sender == charityAddress, "setCharityAddress: FORBIDDEN");
        require(_charityAddress != address(0), "setCharityAddress: ZERO");
        charityAddress = _charityAddress;
        emit CharityAddressUpdated(msg.sender, _charityAddress);
    }    

    //Update lottery address by the owner
    function setLotteryAddress(address _lotteryAddress) public onlyOwner {
        require(_lotteryAddress != address(0), "setLotteryAddress: ZERO");
        lotteryAddress = _lotteryAddress;
        emit LotteryAddressUpdated(msg.sender, _lotteryAddress);
    }    

    // Update emission rate by the owner
    function updateEmissionRate(uint256 _nalisPerBlock) public onlyOwner {
		require(_nalisPerBlock <= MAX_EMISSION_RATE, "Too high");
        massUpdatePools();
        emit EmissionRateUpdated(msg.sender, nalisPerBlock, _nalisPerBlock);
        nalisPerBlock = _nalisPerBlock;
    }

    // Update the nalis referral contract address by the owner
    function setNalisReferral(IReferral _nalisReferral) public onlyOwner {
        require(address(_nalisReferral) != address(0), "setNalisReferral: ZERO");
        nalisReferral = _nalisReferral;
        emit NalisReferralUpdated(msg.sender, _nalisReferral);
    }

    // Update referral commission rate by the owner
    function setReferralCommissionRate(uint16 _referralCommissionRate) public onlyOwner {
        // Max referral commission rate: 10%.
        require(_referralCommissionRate <= 1000, "setReferralCommissionRate: invalid referral commission rate basis points");
        emit ReferralRateUpdated(msg.sender, referralCommissionRate, _referralCommissionRate);
        referralCommissionRate = _referralCommissionRate;
    }

    // Update lottery mint rate by the owner
    function setLotteryMintRate(uint16 _lotteryMintRate) public onlyOwner {
        // Max lottery mint rate : 4%.
        require(_lotteryMintRate <= 400, "setLotteryMintRate: invalid lottery mint rate basis points");
        emit LotteryMintRateUpdated(msg.sender, lotteryMintRate, _lotteryMintRate);
        lotteryMintRate = _lotteryMintRate;
    }  

    // Update charity fee rate by the owner
    function setCharityFeeRate(uint16 _charityFeeBP) public onlyOwner {
        // Max charity fee rate: 50%
        // charity fee is a part of deposit fee and not added fee
        require(_charityFeeBP <= 5000, "setCharityFeeRate: invalid charity fee rate basis points");
        emit CharityFeeRateUpdated(msg.sender, charityFeeBP, _charityFeeBP);
        charityFeeBP = _charityFeeBP;
    }
    
    // Update lyptus discount fee rate by the owner
    function setLyptusDiscountFeeRate(uint16 _lyptusDiscountFeeBP) public onlyOwner {
        // Max lyptus discount fee rate: 50%
        // lyptus discount fee is a part of dynamic deposit fee and not added fee
        require(_lyptusDiscountFeeBP <= 5000, "setLyptusDiscountFeeRate: invalid lyptus discount fee rate basis points");
        emit LyptusDiscountFeeRateUpdated(msg.sender, lyptusDiscountFeeBP, _lyptusDiscountFeeBP);
        lyptusDiscountFeeBP = _lyptusDiscountFeeBP;
    }        

    
    // Update the nalis locker contract address by the owner
    function setNalisLocker(address _nalisLockerAddress) public onlyOwner {
        nalisLocker = ILocker(_nalisLockerAddress);
        nalisLockerAddress = _nalisLockerAddress;
        emit NalisLockerUpdated(msg.sender, _nalisLockerAddress);
    }        

    // Update locker rate by the owner
    function setLockerRate(uint16 _lockerRate) public onlyOwner {
        // Max locker rate: 50%.
        require(_lockerRate <= 5000, "setLockerRate: invalid locker rate basis points");
        emit LockerRateUpdated(msg.sender, lockerRate, _lockerRate);
        lockerRate = _lockerRate;
    }

    // Pay referral commission to the referrer who referred this user.
    function payReferralCommission(address _user, uint256 _pending) internal {
        if (address(nalisReferral) != address(0) && referralCommissionRate > 0) {
            address referrer = nalisReferral.getReferrer(_user);
            uint256 commissionAmount = _pending.mul(referralCommissionRate).div(10000);

            if (referrer != address(0) && referrer != BURN_ADDRESS && commissionAmount > 0) {
                nalis.mint(referrer, commissionAmount);
                nalisReferral.recordReferralCommission(referrer, commissionAmount);
                emit ReferralCommissionPaid(_user, referrer, commissionAmount);
            }
        }
    }
    
    // Returns the address of the current operator.
    function operator() public view returns (address) {
        return _operator;
    }

    // Transfers operator of the contract to a new account (`newOperator`). Can only be called by the current operator.
    function transferOperator(address newOperator) public onlyOperator {
        require(newOperator != address(0), "transferOperator: new operator is the zero address");
        emit OperatorTransferred(_operator, newOperator);
        _operator = newOperator;
    }
    
    // Update the lyptus MA 7 price. Can only be called by the current operator.
    function updateLyptusPriceMA7(uint256 _lyptusPriceMA7) public onlyOperator {
        require(_lyptusPriceMA7 > 0, "updateLyptusPriceMA7: value must be higher then 0");
        emit LyptusPriceMA7Updated(msg.sender, lyptusPriceMA7, _lyptusPriceMA7);
        lyptusPriceMA7 = _lyptusPriceMA7;
    } 
    
    // Update the LP MA 7 price. Can only be called by the current operator.
    function updateLpPriceMA7(uint256 _pid, uint256 _lpPriceMA7) public onlyOperator {
        require(_lpPriceMA7 > 0, "updateLpPriceMA7: value must be higher then 0");
        emit LpPriceMA7Updated(msg.sender, poolInfo[_pid].lpPriceMA7, _lpPriceMA7);
        poolInfo[_pid].lpPriceMA7 = _lpPriceMA7;
    }   
    
    // Reset amount of totalBuybackBurnDepFee per pool. Can only be called by the current operator.
    function resetTotalBuybackBurnDepFee(uint256 _pid) public onlyOperator {
        emit TotalBuybackBurnDepFeeReseted(msg.sender, poolInfo[_pid].totalBuybackBurnDepFee, 0);
        poolInfo[_pid].totalBuybackBurnDepFee = 0;
    }      
    
    // Exclude or include an address from locker
    function setExcludedFromLocker(address _account, bool _excluded) public onlyOwner {
        _excludedFromLocker[_account] = _excluded;
        emit ExcludedFromLocker(_account, _excluded);
    }       
    
    // Returns the address is excluded from locker or not.
    function isExcludedFromLocker(address _account) public view returns (bool) {
        return _excludedFromLocker[_account];
    } 

    function updateStartBlock(uint256 _startBlock) external onlyOwner {
        require(startBlock > block.number, "Farm already started");
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            pool.lastRewardBlock = _startBlock;
        }
        startBlock = _startBlock;
    }   
    
    //Update lyptus address by the owner
    function setLyptusAddress(address _lyptusAddress) public onlyOwner {
        require(_lyptusAddress != address(0), "setLyptusAddress: ZERO");
        require(address(lyptus) == 0x000000000000000000000000000000000000dEaD, "setLyptusAddress: already set");
        lyptus = IBEP20(_lyptusAddress);
    }      
    
}