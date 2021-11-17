// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import './SafeMath.sol';
import './IBEP20.sol';
import './SafeBEP20.sol';
import './Ownable.sol';
import "./ReentrancyGuard.sol";
import './ICalcifireReferral.sol';
import './CalcifireToken.sol';
import './IERC20.sol';
import './IUniswapV2Pair.sol';

// HowlsCastle is the residence of Calcifire and the place where all the magic happens. It can make CALCIFIRE tokens, powered by imagination and can keep moving for the whole eternity.

contract HowlsCastle is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        uint256 rewardLockedUp;  // Reward locked up.
        uint256 nextHarvestUntil; // When can the user harvest again.
        uint256 boost; // current user boost for this pool.
        uint256 boostLockedUp;  // reward earned due to boost locked up.
        //
        // We do some fancy math here. Basically, any point in time, the amount of CALCIFIREs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accCALCIFIREPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accCALCIFIREPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. CALCIFIREs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that CALCIFIREs distribution occurs.
        uint256 accCALCIFIREPerShare;   // Accumulated CALCIFIREs per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
        uint256 harvestInterval;  // Harvest interval in seconds
        bool isBoostEnabled;      // Is boost enabled for this Pool
        uint256 lpTotalSupply;    // total supply of LP
    }

    // The CALCIFIRE TOKEN!
    Calcifire public CALCIFIRE;
    // Dev address.
    address public devaddr;
    // Treasury address - for dividends.
    address public treasuryaddr;
    // CALCIFIRE tokens created per block.
    uint256 public calcifirePerBlock;
    // final CALCIFIRE per block after emission reduction.
    uint256 public targetCalcifirePerBlock;
    // emission halving time
    uint256 public calcifirePerBlockHalvingTime = block.timestamp;
    // emission halving interval (default 6h)
    uint256 public calcifireHalvingInterval = 21600;
    // emission decrease percentage (default 3%)
    uint256 public emissionRateDecreasePerBlock = 3;

    // Bonus muliplier for early CALCIFIRE makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Deposit Fee address
    address public feeAddress;

    //mapping to check each pool is unique
    mapping(IBEP20 => bool) public poolAdded;
    //Quest Operators
    mapping(address => bool) public operators;
    // overall user boost
    mapping(address => uint256) public userBoost;
    //Amount to be added to the boost on every click of the boost button. 100 means 1% increase
    uint256 public userPoolBoostAmount = 2500;
    //Amount % to be paid for doing Boost on a Farm/Pool
    uint256 public constant POOL_BOOST_FEE = 50;
    //max overall user boost
    uint256 public maxUserBoostAmount = 10000; //100%
    //max boost per pool
    uint256 public maxPoolBoostAmount = 15000; //150%

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when CALCIFIRE mining starts.
    uint256 public startBlock;

    // Total locked up rewards
    uint256 public totalLockedUpRewards;
    // Total CALCIFIRE in CALCIFIRE Pools (can be multiple pools)
    uint256 public totalCALCIFIREInPools = 0;

    // referral contract address.
    ICalcifireReferral public calcifireReferral;
    // Referral commission rate in basis points.
    uint16 public referralCommissionRate = 500;
    // Max referral commission rate: 10%.
    uint16 public constant MAXIMUM_REFERRAL_COMMISSION_RATE = 1000;

    // Maximum deposit fee rate: 10%
    uint16 public constant MAXIMUM_DEPOSIT_FEE_RATE = 1000;
    // Min Havest interval: 1 hour
    uint256 public constant MINIMUM_HARVEST_INTERVAL = 3600;
    // Max harvest interval: 14 days.
    uint256 public constant MAXIMUM_HARVEST_INTERVAL = 14 days;

    //DEAD TOKENS ADDRESS
    address public constant DEAD_TOKENS = 0x000000000000000000000000000000000000dEaD;

    //token-usd pair by token symbol - used by Boosts functionality
    mapping (string => address) private _tokenUSDPair;

    //Boost USD limits
    mapping (uint256 => uint256) private _boostUSDLimits;

    bool public _boostLimitsEnabled = true;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event Harvest(address indexed user, uint256 indexed pid, uint256 amountHarvest);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmissionRateUpdated(address indexed caller, uint256 previousAmount, uint256 newAmount);
    event ReferralCommissionPaid(address indexed user, address indexed referrer, uint256 commissionAmount);
    event RewardLockedUp(address indexed user, uint256 indexed pid, uint256 amountLockedUp);
    event Boost(address indexed user, uint256 indexed pid, uint256 userBoost);
    event OperatorUpdated(address indexed operator, bool indexed status);

    modifier onlyOperator {
        require(operators[msg.sender], "Operator: caller is not the operator");
        _;
    }

    constructor(
        Calcifire _CALCIFIRE,
        address _devaddr,
        address _treasuryaddr,
        address _feeAddress,
        uint256 _calcifirePerBlock,
        uint256 _targetCalcifirePerBlock,
        uint256 _startBlock
    ) public {
        CALCIFIRE = _CALCIFIRE;
        devaddr = _devaddr;
        treasuryaddr = _treasuryaddr;
        feeAddress = _feeAddress;
        calcifirePerBlock = _calcifirePerBlock;
        targetCalcifirePerBlock = _targetCalcifirePerBlock;
        startBlock = _startBlock;

        operators[_msgSender()] = true;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function remainRewards() external view returns (uint256) {
        return CALCIFIRE.balanceOf(address(this)).sub(totalCALCIFIREInPools);
    }

    // calculate price based on pair reserves
    function getTokenPrice(address pairAddress, uint256 amount, string memory tokenSymbol) public view returns(uint) {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        (uint256 Res0, uint256 Res1,) = pair.getReserves();
        IERC20 token = IERC20(pair.token0());
        uint256 price = 0;

        if (keccak256(bytes(token.symbol())) == keccak256(bytes(tokenSymbol))) {
          // return amount of token1 needed to buy token0
          price = amount.mul(Res1.mul(10**token.decimals())).div(Res0);
        }
        else {
          token = IERC20(pair.token1());
          // return amount of token0 needed to buy token1
          price = amount.mul(Res0.mul(10**token.decimals())).div(Res1);
        }

        return price;
    }

    // Set token-usd pair - used by Boosts functionality
    function setTokenUSDPair(address pairAddress, string memory tokenSymbol) public onlyOperator {
        require(_tokenUSDPair[tokenSymbol] != pairAddress, "setTokenUSDPair: pair address is already set for this token");
        _tokenUSDPair[tokenSymbol] = pairAddress;
    }

    // Get token-usd pair by token symbol
    function getTokenUSDPair(string memory tokenSymbol) public view returns(address) {
        return(_tokenUSDPair[tokenSymbol]);
    }

    // check native pool LP amount in USD
    function getNativePoolLPInUSD(address lpAddress, uint256 lpTotalSupply, uint256 amount) public view returns(uint256) {
        require(getTokenUSDPair("WBNB") != address(0x0), "getNativePoolLPInUSD: BNB-BUSD pair is mandatory");

        uint256 userLPinCalcifer = 0;
        uint256 nativePriceUSD = 0;
        uint256 poolAmountInUSD = 0;
        uint256 totalTokens = 0;

        //get BNB-BUSD LP address
        address quoteTokenLP = getTokenUSDPair("WBNB");
        uint256 priceBNBinUSD = getTokenPrice(quoteTokenLP, 1, "WBNB");

        //native token price calc
        uint256 priceCalciferInBNB = getTokenPrice(address(CALCIFIRE.uniswapV2Pair()), 1, "CALCIFIRE");
        nativePriceUSD = (priceCalciferInBNB.mul(priceBNBinUSD)).div(10**CALCIFIRE.decimals());

        //native pool
        if (lpAddress == address(CALCIFIRE)) {
          poolAmountInUSD = amount.mul(nativePriceUSD).div(10**CALCIFIRE.decimals());
          return poolAmountInUSD;
        }

        //native farms
        totalTokens = CALCIFIRE.balanceOf(lpAddress);
        userLPinCalcifer = amount.mul(totalTokens).mul(2).div(lpTotalSupply);

        poolAmountInUSD = userLPinCalcifer.mul(nativePriceUSD).div(10**CALCIFIRE.decimals());

        return poolAmountInUSD;
    }

    // Set token-usd pair - used by Boosts functionality
    function setBoostLimitsEnabled(bool boostLimitsEnabled) public onlyOperator {
        _boostLimitsEnabled = boostLimitsEnabled;
    }

    // Set Pool Boost limits
    function setPoolBoostUSDLimits(uint256 boostStep, uint256 boostUSDLimit) public onlyOperator {
        require(_boostUSDLimits[boostStep] != boostUSDLimit, "setPoolBoostUSDLimits: USD limit is already set for this % step");
        _boostUSDLimits[boostStep] = boostUSDLimit;

    }

    // Get Pool Boost limits
    function getPoolBoostUSDLimits(uint256 boostStep) public view returns(uint256) {
        return(_boostUSDLimits[boostStep]);
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, IBEP20 _lpToken, uint16 _depositFeeBP, uint256 _harvestInterval, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= MAXIMUM_DEPOSIT_FEE_RATE, "add: deposit fee too high");
        require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "add: invalid harvest interval");
        require(poolAdded[_lpToken] != true, "add: same LP cant be added twice");
        poolAdded[_lpToken] = true;
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accCALCIFIREPerShare: 0,
            depositFeeBP: _depositFeeBP,
            harvestInterval : _harvestInterval,
            isBoostEnabled : false,
            lpTotalSupply: _lpToken.totalSupply()
        }));
    }

    // Update the given pool's CALCIFIRE allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, uint256 _harvestInterval, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= MAXIMUM_DEPOSIT_FEE_RATE, "set: deposit fee too high");
        require(_harvestInterval <= MAXIMUM_HARVEST_INTERVAL, "set: invalid harvest interval");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].harvestInterval = _harvestInterval;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending CALCIFIREs on frontend.
    function pendingCalcifireTotal(uint256 _pid, address _user) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accCALCIFIREPerShare = pool.accCALCIFIREPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 calcifireReward = multiplier.mul(calcifirePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accCALCIFIREPerShare = accCALCIFIREPerShare.add(calcifireReward.mul(1e12).div(lpSupply));
        }
        uint256 pending = user.amount.mul(accCALCIFIREPerShare).div(1e12).sub(user.rewardDebt);

        if (userBoost[_user] > 0) {
            uint256 boostAmount = pending.mul(userBoost[_user]).div(10000);
            pending = pending.add(boostAmount);
        }

        if (pool.isBoostEnabled && user.boost > 0) {
            uint256 boostAmount = pending.mul(user.boost).div(10000);
            pending = pending.add(boostAmount);
        }

        return pending.add(user.rewardLockedUp).add(user.boostLockedUp);
    }

    // View function to see pending boosted amount of CALCIFIRE
    function pendingCalcifireBoosted(uint256 _pid, address _user) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accCALCIFIREPerShare = pool.accCALCIFIREPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 calcifireReward = multiplier.mul(calcifirePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accCALCIFIREPerShare = accCALCIFIREPerShare.add(calcifireReward.mul(1e12).div(lpSupply));
        }
        uint256 pending = user.amount.mul(accCALCIFIREPerShare).div(1e12).sub(user.rewardDebt);
        uint256 boostAmount = 0;

        if (userBoost[_user] > 0) {
            boostAmount = pending.mul(userBoost[_user]).div(10000);
        }

        if (pool.isBoostEnabled && user.boost > 0) {
            boostAmount = pending.mul(user.boost).div(10000);
        }

        return boostAmount.add(user.boostLockedUp);
    }

    // View function to see if user can harvest.
    function canHarvest(uint256 _pid, address _user) public view returns (bool) {
        UserInfo storage user = userInfo[_pid][_user];
        return block.timestamp >= user.nextHarvestUntil;
    }

    // View function to calc current Harvest Tax %
    function harvestTax(uint256 _pid, address _user) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        if (block.timestamp >= user.nextHarvestUntil) {
            return 0;
        } else {
            uint256 remainingBlocks = user.nextHarvestUntil.sub(block.timestamp);
            uint256 harvestTaxAmount = remainingBlocks.mul(100).div(pool.harvestInterval);

            if (harvestTaxAmount < 2) {
                return 0;
            } else {
                return harvestTaxAmount;
            }
        }

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

        autoReduceEmissionRate();

        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 calcifireReward = multiplier.mul(calcifirePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        CALCIFIRE.mint(devaddr, calcifireReward.div(20));
        CALCIFIRE.mint(treasuryaddr, calcifireReward.div(20));
        CALCIFIRE.mint(address(this), calcifireReward);
        pool.accCALCIFIREPerShare = pool.accCALCIFIREPerShare.add(calcifireReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to HowlsCastle for CALCIFIRE allocation.
    function deposit(uint256 _pid, uint256 _amount, bool _boost, address _referrer) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        uint256 amount = _amount;
        uint256 beforeTransfer;

        if (amount > 0) {
          //calculate balance of LP in the pool before transfer
          beforeTransfer = pool.lpToken.balanceOf(address(this));

          if (address(calcifireReferral) != address(0) && _referrer != address(0) && _referrer != msg.sender) {
              calcifireReferral.recordReferral(msg.sender, _referrer);
          }
        }

        if (_boost) {
            require(pool.isBoostEnabled, "deposit:BOOST NOT ENABlED");
            require(canHarvest(_pid, msg.sender),'deposit:BOOST NOT READY');
            if (_boostLimitsEnabled) {
              require(getNativePoolLPInUSD(address(pool.lpToken), pool.lpTotalSupply, user.amount) >= getPoolBoostUSDLimits(user.boost), 'deposit:BOOST USD LIMIT RESTRICTION');
            }
        }

        payOrLockupPendingCALCIFIRE(_pid, _boost, amount);

        if(!_boost && amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), amount);
            //calculate balance of LP in the pool after transfer
            uint256 afterTransfer = pool.lpToken.balanceOf(address(this));
            amount = afterTransfer.sub(beforeTransfer);
            if(pool.depositFeeBP > 0){
                uint256 depositFee = amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(amount).sub(depositFee);

                if (address(pool.lpToken) == address(CALCIFIRE)) {
                    totalCALCIFIREInPools = totalCALCIFIREInPools.add(amount).sub(depositFee);
                }
            } else {
                user.amount = user.amount.add(amount);

                if (address(pool.lpToken) == address(CALCIFIRE)) {
                    totalCALCIFIREInPools = totalCALCIFIREInPools.add(amount);
                }
            }
        }
        user.rewardDebt = user.amount.mul(pool.accCALCIFIREPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, amount);
    }

    // Withdraw LP tokens from HowlsCastle.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 amount = _amount;

        payOrLockupPendingCALCIFIRE(_pid, false, amount);

        if(amount > 0) {
            //calculate balance of LP in the pool before transfer
            uint256 beforeTransfer = pool.lpToken.balanceOf(address(this));

            pool.lpToken.safeTransfer(address(msg.sender), amount);

            //calculate balance of LP in the pool after transfer
            uint256 afterTransfer = pool.lpToken.balanceOf(address(this));
            amount = beforeTransfer.sub(afterTransfer);
            user.amount = user.amount.sub(amount);

            if (address(pool.lpToken) == address(CALCIFIRE)) {
                totalCALCIFIREInPools = totalCALCIFIREInPools.sub(amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accCALCIFIREPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        user.nextHarvestUntil = 0;
        user.rewardLockedUp = 0;
        user.boostLockedUp = 0;

        pool.lpToken.safeTransfer(address(msg.sender), amount);

        if (address(pool.lpToken) == address(CALCIFIRE)) {
            totalCALCIFIREInPools = totalCALCIFIREInPools.sub(amount);
        }
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Pay or lockup pending CALCIFIRE.
    function payOrLockupPendingCALCIFIRE(uint256 _pid, bool _boost, uint256 _amount) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 pending = user.amount.mul(pool.accCALCIFIREPerShare).div(1e12).sub(user.rewardDebt);

        if (pending > 0 || user.rewardLockedUp > 0) {

            uint256 boostAmount = 0;
            uint256 totalRewards = pending.add(user.rewardLockedUp).add(user.boostLockedUp);

            //Check if user has Boost and add to total rewards
             if (userBoost[msg.sender] > 0) {
                boostAmount = pending.mul(userBoost[msg.sender]).div(10000);
                totalRewards = totalRewards.add(boostAmount);
             }
            //Check if pool boost is enabled and add to total rewards
            if (pool.isBoostEnabled && user.boost > 0) {
                boostAmount = pending.mul(user.boost).div(10000);
                totalRewards = totalRewards.add(boostAmount);
            }

            if (_boost || _amount == 0) { // User wanna boost or harvest

                CALCIFIRE.mint(address(this), boostAmount.add(user.boostLockedUp));

                if (_boost) {
                    //add to User Pool Boost
                    user.boost = user.boost.add(userPoolBoostAmount);
                    if (user.boost > maxPoolBoostAmount) {
                        user.boost = maxPoolBoostAmount;
                    }
                    //take 50% boost fee and transfer
                    uint256 halfRewards = totalRewards.mul(POOL_BOOST_FEE).div(100);
                    safeCALCIFIRETransfer(DEAD_TOKENS, halfRewards);
                    safeCALCIFIRETransfer(msg.sender, halfRewards);
                    payReferralCommission(msg.sender, halfRewards);
                    emit Boost(msg.sender, _pid, user.boost);

                } else {
                    //check Harvest Tax
                    uint256 harvestTaxAmount = harvestTax(_pid, msg.sender);
                    uint256 taxRewards = totalRewards.mul(harvestTaxAmount).div(100);
                    uint256 netRewards = totalRewards.sub(taxRewards);

                    //send rewards
                    safeCALCIFIRETransfer(DEAD_TOKENS, taxRewards);
                    safeCALCIFIRETransfer(msg.sender, netRewards);
                    payReferralCommission(msg.sender, netRewards);
                    emit Harvest(msg.sender, _pid, netRewards);
                }

                // reset lockup
                totalLockedUpRewards = totalLockedUpRewards.sub(user.rewardLockedUp).sub(user.boostLockedUp);
                user.rewardLockedUp = 0;
                user.boostLockedUp = 0;
                user.nextHarvestUntil = block.timestamp.add(pool.harvestInterval);

            } else { // User is making another deposit or withdrawal & has some pending

                user.boostLockedUp = user.boostLockedUp.add(boostAmount);
                user.rewardLockedUp = user.rewardLockedUp.add(pending);
                totalLockedUpRewards = totalLockedUpRewards.add(pending).add(boostAmount);
                emit RewardLockedUp(msg.sender, _pid, pending);

            }

        }
    }

    // Safe CALCIFIRE transfer function, just in case if rounding error causes pool to not have enough CALCIFIREs.
    function safeCALCIFIRETransfer(address _to, uint256 _amount) internal {
        uint256 calcifireBal = CALCIFIRE.balanceOf(address(this)).sub(totalCALCIFIREInPools);
        if (_amount > calcifireBal) {
            CALCIFIRE.transfer(_to, calcifireBal);
        } else {
            CALCIFIRE.transfer(_to, _amount);
        }
    }

    function setBoostAmounts (uint256 _maxPoolBoostAmount, uint256 _maxUserBoostAmount, uint256 _userPoolBoostAmount) public onlyOwner {
        maxPoolBoostAmount = _maxPoolBoostAmount;
        maxUserBoostAmount = _maxUserBoostAmount;
        userPoolBoostAmount = _userPoolBoostAmount;
    }

    function setPoolBoost (uint256 _pid, bool _isBoostEnabled) public onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        pool.isBoostEnabled = _isBoostEnabled;
    }

    // Add to general User Boost by Quest Operator
    function addUserBoostByOperator(address _user, uint256 _amount) public onlyOperator {

        userBoost[_user] = userBoost[_user].add(_amount);

        if (userBoost[_user] > maxUserBoostAmount) {
            userBoost[_user] = maxUserBoostAmount;
        }
    }

    // Add to User Pool Boost by Operator
    function addUserPoolBoostByOperator(uint256 _pid, address _user, uint256 _amount) public onlyOperator {

        UserInfo storage user = userInfo[_pid][_user];

        user.boost = user.boost.add(_amount);
        if (user.boost > maxPoolBoostAmount) {
            user.boost = maxPoolBoostAmount;
        }
    }

    // Update dev address by the previous dev.
    function setDevAddress(address _devaddr) public {
        require(msg.sender == devaddr, "setDevAddress: FORBIDDEN");
        require(_devaddr != address(0), "setDevAddress: ZERO");
        devaddr = _devaddr;
    }

    function setFeeAddress(address _feeAddress) public{
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        require(_feeAddress != address(0), "setFeeAddress: ZERO");
        feeAddress = _feeAddress;
    }

    // Update the status of the operator
    function updateOperator(address _operator, bool _status) external onlyOwner {
        operators[_operator] = _status;
        emit OperatorUpdated(_operator, _status);
    }

    //Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _calcifirePerBlock) public onlyOwner {
        massUpdatePools();
        emit EmissionRateUpdated(msg.sender, calcifirePerBlock, _calcifirePerBlock);
        calcifirePerBlock = _calcifirePerBlock;
    }

    //Update emission halving settings
    function updateEmissionHalving(uint256 _calcifireHalvingInterval, uint256 _emissionRateDecreasePerBlock, uint256 _targetCalcifirePerBlock) public onlyOwner {
        massUpdatePools();
        calcifireHalvingInterval = _calcifireHalvingInterval;
        emissionRateDecreasePerBlock = _emissionRateDecreasePerBlock;
        targetCalcifirePerBlock = _targetCalcifirePerBlock;
    }

    //auto-reduce emission
    function autoReduceEmissionRate() internal returns (bool) {
        uint calcifirePerBlockCurrentTime = block.timestamp;
        // if 12h passed and calcifirePerBlock > 0.03
        if((calcifirePerBlockCurrentTime.sub(calcifirePerBlockHalvingTime) >= calcifireHalvingInterval) && (calcifirePerBlock > targetCalcifirePerBlock)){
            if(calcifirePerBlock.sub(calcifirePerBlock.mul(emissionRateDecreasePerBlock).div(100)) < targetCalcifirePerBlock) calcifirePerBlock = targetCalcifirePerBlock;
            else calcifirePerBlock = calcifirePerBlock.sub(calcifirePerBlock.mul(emissionRateDecreasePerBlock).div(100));

            calcifirePerBlockHalvingTime = calcifirePerBlockCurrentTime;
        }
        return true;
    }

    // Update the referral contract address by the owner
    function setReferralContract(ICalcifireReferral _calcifireReferral) public onlyOwner {
        calcifireReferral = _calcifireReferral;
    }

    // Update referral commission rate by the owner
    function setReferralCommissionRate(uint16 _referralCommissionRate) public onlyOwner {
        require(_referralCommissionRate <= MAXIMUM_REFERRAL_COMMISSION_RATE, "setReferralCommissionRate: invalid referral commission rate basis points");
        referralCommissionRate = _referralCommissionRate;
    }

    // Pay referral commission to the referrer who referred this user.
    function payReferralCommission(address _user, uint256 _pending) internal {
        if (address(calcifireReferral) != address(0) && referralCommissionRate > 0) {
            address referrer = calcifireReferral.getReferrer(_user);
            uint256 commissionAmount = _pending.mul(referralCommissionRate).div(10000);

            if (referrer != address(0) && commissionAmount > 0) {

                CALCIFIRE.mint(referrer, commissionAmount);
                calcifireReferral.recordReferralCommission(referrer, commissionAmount);
                emit ReferralCommissionPaid(_user, referrer, commissionAmount);

            }
        }
    }

    // Update start reward block
    function setStartRewardBlock(uint256 _block) public onlyOwner {
        startBlock = _block;
    }
}