pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../libs/IBEP20.sol";
import "../libs/SafeBEP20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../OctaGold.sol";
import "./IOctaGoldMasterPool.sol";
import "./DCAMasterChefDeposit.sol";
import "../MasterChef.sol";
import "../Exchanges/UniswapRouter/IUniswapV2Router02.sol";
import "../Exchanges/UniswapRouter/IUniswapV2Factory.sol";
import "../Exchanges/UniswapRouter/IUniswapV2Pair.sol";

// DCAMasterChef is the master of OctaGold. He can make OctaGold and he is a fair guy.
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once OctaGold is sufficiently
// distributed and the community can show to govern itself.
// Have fun reading it. Hopefully it's bug-free. God bless.
contract DCAMasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    uint256 public constant MAX_INT_TYPE = type(uint256).max;
    IUniswapV2Router02 public uniswapV2Router;
    IUniswapV2Factory public uniswapV2Factory;
    IUniswapV2Pair public uniswapV2Pair;
    MasterChef public octaXMasterChef;
    DCAMasterChefDeposit public dCAMasterChefDeposit;
    address public tokenBusdAddress =
        0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 rewardGoldDebt;
        uint256 lastBlcokWithdrawal;
        uint256 lastBlockTimestemp;
        // We do some fancy math here. Basically, any point in time, the amount of OctaGolds
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accOctaGoldPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accOctaGoldPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    } 
    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. OctaGolds to distribute per block.
        uint256 lastRewardBlock; // Last block number that OctaGolds distribution occurs.
        uint256 accOctaGoldPerShare; // Accumulated OctaGolds per share, times 1e12. See below.
        uint16 depositFeeBP; // Deposit fee in basis points
    }

    OctaGold public OctaGoldToken;
    IOctaGoldMasterPool public octaGoldMasterPool;
    // Dev address.
    address public devaddr;
    // OctaGold tokens created per block.
    // Having block every x day.
    uint256 public OctaGoldPerBlock;

    uint256 public OctaGoldPerBlockStartValue;

    // Bonus muliplier for early OctaGold makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Deposit burn address
    address public burnAddress;
    uint256 public WithdrawalBurnFeePercent;
    uint256 public WithdrawalFeeToRefPercent;
    uint256 public WithdrawalFeeToBurnAddresPercent;
    uint256 public WithdrawalFeeToBurnSupplyPercent;
    address public constant BurnSupplyAddress =
        0x5555500000000000005555500000000000055555;
    uint256 public constant BlockHavingDay = 60; //Having Every XX Day
    uint256 public constant BlockPerDay = 28800; //AVG
    uint256 public LockDayWithdraw = 1; //Withdraw
    uint256 private constant PercentValue = 10000;
    uint256 public LastHavingTime;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when OctaGold mining starts.
    uint256 public startBlock;

    uint256 public referralFee;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event SetNewOwnerTokenAddress(
        address indexed user,
        address indexed newAddress
    );
    event SetBurnAddress(address indexed user, address indexed newAddress);
    event SetDevAddress(address indexed user, address indexed newAddress);
    event UpdateEmissionRate(address indexed user, uint256 goosePerBlock);
    event SetLockDayWithdraw(uint256 day);
    // event SetReferralPartnershipAddress(
    //     address indexed user,
    //     address indexed referralAddress
    // );

    constructor(
        OctaGold _OctaGold,
        address _octaGoldMasterPoolAddress,
        address _OctaXMasterChef,
        address _dCAMasterChefDepositAddress,
        address _routeUniswapV2,
        address _devaddr,
        address _feeAddress,
        uint256 _OctaGoldPerBlock,
        uint256 _startBlock,
        uint256 _feePartnership,
        uint256 _feeWithdrawalForBurn,
        uint256 _feeWithdrawalFeeToRefPercent,
        uint256 _feeWithdrawalFeeToBurnAddresPercent,
        uint256 _feeWithdrawalFeeToBurnSupplyPercent
    ) public {
        octaGoldMasterPool = IOctaGoldMasterPool(_octaGoldMasterPoolAddress);
        octaXMasterChef = MasterChef(_OctaXMasterChef);
        dCAMasterChefDeposit = DCAMasterChefDeposit(
            _dCAMasterChefDepositAddress
        );
        OctaGoldToken = _OctaGold;
        devaddr = _devaddr;
        burnAddress = _feeAddress;
        OctaGoldPerBlock = _OctaGoldPerBlock;
        OctaGoldPerBlockStartValue = _OctaGoldPerBlock;

        if (block.number > _startBlock) {
            startBlock = block.number;
        } else {
            startBlock = _startBlock;
        }
        referralFee = _feePartnership;
        WithdrawalBurnFeePercent = _feeWithdrawalForBurn;
        WithdrawalFeeToRefPercent = _feeWithdrawalFeeToRefPercent;
        WithdrawalFeeToBurnAddresPercent = _feeWithdrawalFeeToBurnAddresPercent;
        WithdrawalFeeToBurnSupplyPercent = _feeWithdrawalFeeToBurnSupplyPercent;
        setRouteSwapAddress(_routeUniswapV2);
    }

    function setRouteSwapAddress(address newAddress) public onlyOwner {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(newAddress);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Factory = IUniswapV2Factory(_uniswapV2Router.factory());
    }

    function nextHavingTime() external view returns (uint256) {
        uint256 nextDue = LastHavingTime + (BlockHavingDay * 1 days);
        return nextDue;
    }

    function updatePointPerBlock() internal {
        uint256 nextDue = LastHavingTime + (BlockHavingDay * 1 days);
        if (block.timestamp >= nextDue) {
            uint256 outHv = OctaGoldPerBlock.div(2);
            OctaGoldPerBlock = outHv;
            LastHavingTime = block.timestamp;
        }
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    mapping(IBEP20 => bool) public poolExistence;
    modifier nonDuplicated(IBEP20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        IBEP20 _lpToken,
        uint16 _depositFeeBP,
        bool _withUpdate
    ) public onlyOwner nonDuplicated(_lpToken) {
        require(
            _depositFeeBP <= PercentValue,
            "add: invalid deposit fee basis points"
        );
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock
            ? block.number
            : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExistence[_lpToken] = true;
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accOctaGoldPerShare: 0,
                depositFeeBP: _depositFeeBP
            })
        );
    }

    // Update the given pool's OctaGold allocation point and deposit fee. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        uint16 _depositFeeBP,
        bool _withUpdate
    ) public onlyOwner {
        require(
            _depositFeeBP <= PercentValue,
            "set: invalid deposit fee basis points"
        );
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending OctaGolds on frontend.
    function pendingOctaGold(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accOctaGoldPerShare = pool.accOctaGoldPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 OctaGoldReward = multiplier
                .mul(OctaGoldPerBlock)
                .mul(pool.allocPoint)
                .div(totalAllocPoint);
            accOctaGoldPerShare = accOctaGoldPerShare.add(
                OctaGoldReward.mul(1e12).div(lpSupply)
            );
        }
        return
            user.amount.mul(accOctaGoldPerShare).div(1e12).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function thisAddress() public view returns (address) {
        return address(this);
    }

    function nextUserWithdraw(uint256 _pid, address _userIndex)
        public
        view
        returns (uint256)
    {
        UserInfo storage user = userInfo[_pid][_userIndex];
        uint256 _nextWithdraw = user.lastBlockTimestemp +
            (LockDayWithdraw * 1 days);
        return _nextWithdraw;
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        updatePointPerBlock();
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
        uint256 OctaGoldReward = multiplier
            .mul(OctaGoldPerBlock)
            .mul(pool.allocPoint)
            .div(totalAllocPoint);
        octaGoldMasterPool.mintOctaGoldTo(devaddr, OctaGoldReward.div(10));
        octaGoldMasterPool.mintOctaGoldTo(address(this), OctaGoldReward);
        pool.accOctaGoldPerShare = pool.accOctaGoldPerShare.add(
            OctaGoldReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for OctaGold allocation.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        internalDepositLP(_pid,_amount,0,false); 
    }
    function internalDepositLP(uint256 _pid, uint256 _amount,uint256 _busdAmount,bool _isInternal)internal nonReentrant{
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        (
            address partnerAddress,
            bool isRegister,
            uint256 totalChild
        ) = octaXMasterChef.partnerInfo(msg.sender);
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user
                .amount
                .mul(pool.accOctaGoldPerShare)
                .div(1e12)
                .sub(user.rewardDebt);
            if (pending > 0) {
                uint256 withdrawFeeBurn = pending
                    .mul(WithdrawalBurnFeePercent)
                    .div(PercentValue);
                if (referralFee > 0 && isRegister) {
                    uint256 withdrawalFeeToRefAmount = withdrawFeeBurn
                        .mul(WithdrawalFeeToRefPercent)
                        .div(PercentValue);
                    uint256 withdrawalBalanceOut = withdrawFeeBurn.sub(
                        withdrawalFeeToRefAmount
                    );
                    uint256 withdrawalFeeToBurnSupplyAmount = withdrawalBalanceOut
                            .mul(WithdrawalFeeToBurnSupplyPercent)
                            .div(PercentValue);
                    uint256 withdrawalFeeToBurnAddresAmount = withdrawalBalanceOut
                            .sub(withdrawalFeeToBurnSupplyAmount);
                    if (withdrawalFeeToBurnSupplyAmount > 0) {
                        safeOctaGoldTransfer(
                            BurnSupplyAddress,
                            withdrawalFeeToBurnSupplyAmount
                        );
                    }
                    if (withdrawalFeeToBurnAddresAmount > 0) {
                        safeOctaGoldTransfer(
                            burnAddress,
                            withdrawalFeeToBurnAddresAmount
                        );
                    }
                    if (withdrawalFeeToRefAmount > 0) {
                        safeOctaGoldTransfer(
                            partnerAddress,
                            withdrawalFeeToRefAmount
                        );
                    }
                } else {
                    uint256 feeBurnSupplyAmount = withdrawFeeBurn
                        .mul(WithdrawalFeeToBurnSupplyPercent)
                        .div(PercentValue);
                    uint256 feeBurnAddressAmount = withdrawFeeBurn.sub(
                        feeBurnSupplyAmount
                    );
                    if (feeBurnAddressAmount > 0) {
                        safeOctaGoldTransfer(burnAddress, feeBurnAddressAmount);
                    }
                    if (feeBurnSupplyAmount > 0) {
                        safeOctaGoldTransfer(
                            BurnSupplyAddress,
                            feeBurnSupplyAmount
                        );
                    }
                }
                uint256 pendingOut = pending.sub(withdrawFeeBurn);
                if (pendingOut > 0) {
                    safeOctaGoldTransfer(address(msg.sender), pendingOut);
                }
            }
        }
        if (_amount > 0) { 
            if(!_isInternal){
                pool.lpToken.safeTransferFrom(
                    address(msg.sender),
                    address(this),
                    _amount
                );
            }
            dCAMasterChefDeposit.addDeposit(address(msg.sender), _pid, _busdAmount, _amount);
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(
                    PercentValue
                );
                if (referralFee > 0 && isRegister) {
                    uint256 depositFeePartner = depositFee.mul(referralFee).div(
                        PercentValue
                    );
                    uint256 blDepositFee = depositFee.sub(depositFeePartner);
                    pool.lpToken.safeTransfer(
                        partnerAddress,
                        depositFeePartner
                    );
                    pool.lpToken.safeTransfer(burnAddress, blDepositFee);
                } else {
                    pool.lpToken.safeTransfer(burnAddress, depositFee);
                }
                user.amount = user.amount.add(_amount).sub(depositFee);
            } else {
                user.amount = user.amount.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accOctaGoldPerShare).div(1e12);
        user.lastBlcokWithdrawal = block.number;
        user.lastBlockTimestemp=block.timestamp;
        emit Deposit(msg.sender, _pid, _amount);
    }
    function internalDeposit(uint256 _pid, uint256 _amount,uint256 _busdAmount) internal nonReentrant {
        internalDepositLP(_pid,_amount,_busdAmount,true); 
    } 
    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount,bool _isSeparateLP) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        (
            address partnerAddress,
            bool isRegister,
            uint256 totalChild
        ) = octaXMasterChef.partnerInfo(msg.sender);
        require(user.amount >= _amount, "withdraw: not good");
        //Timelock
        bool canWithdraw = false;
        uint256 _nextWithdraw = user.lastBlockTimestemp +
            (LockDayWithdraw * 1 days);
        if (block.timestamp >= _nextWithdraw) {
            canWithdraw = true;
        }
        require(canWithdraw, "withdraw :time lock");

        updatePool(_pid);
        //Check timeout
        uint256 pending = user
            .amount
            .mul(pool.accOctaGoldPerShare)
            .div(1e12)
            .sub(user.rewardDebt);
        if (pending > 0) {
            uint256 withdrawFeeBurn = pending.mul(WithdrawalBurnFeePercent).div(
                PercentValue
            );
            if (referralFee > 0 && isRegister) {
                uint256 withdrawalFeeToRefAmount = withdrawFeeBurn
                    .mul(WithdrawalFeeToRefPercent)
                    .div(PercentValue);
                uint256 withdrawalBalanceOut = withdrawFeeBurn.sub(
                    withdrawalFeeToRefAmount
                );
                uint256 withdrawalFeeToBurnSupplyAmount = withdrawalBalanceOut
                    .mul(WithdrawalFeeToBurnSupplyPercent)
                    .div(PercentValue);
                uint256 withdrawalFeeToBurnAddresAmount = withdrawalBalanceOut
                    .sub(withdrawalFeeToBurnSupplyAmount);
                if (withdrawalFeeToBurnSupplyAmount > 0) {
                    safeOctaGoldTransfer(
                        BurnSupplyAddress,
                        withdrawalFeeToBurnSupplyAmount
                    );
                }
                if (withdrawalFeeToBurnAddresAmount > 0) {
                    safeOctaGoldTransfer(
                        burnAddress,
                        withdrawalFeeToBurnAddresAmount
                    );
                }
                if (withdrawalFeeToRefAmount > 0) {
                    safeOctaGoldTransfer(
                        partnerAddress,
                        withdrawalFeeToRefAmount
                    );
                }
            } else {
                uint256 feeBurnSupplyAmount = withdrawFeeBurn
                    .mul(WithdrawalFeeToBurnSupplyPercent)
                    .div(PercentValue);
                uint256 feeBurnAddressAmount = withdrawFeeBurn.sub(
                    feeBurnSupplyAmount
                );
                if (feeBurnAddressAmount > 0) {
                    safeOctaGoldTransfer(burnAddress, feeBurnAddressAmount);
                }
                if (feeBurnSupplyAmount > 0) {
                    safeOctaGoldTransfer(
                        BurnSupplyAddress,
                        feeBurnSupplyAmount
                    );
                }
            }
            uint256 pendingOut = pending.sub(withdrawFeeBurn);
            if (pendingOut > 0) {
                safeOctaGoldTransfer(address(msg.sender), pendingOut);
            }
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            if(_isSeparateLP){
               pool.lpToken.safeTransfer(address(dCAMasterChefDeposit), _amount);
               dCAMasterChefDeposit.RemoveLiquidityTo(address(pool.lpToken), _amount, address(msg.sender));
            }
            else{
                pool.lpToken.safeTransfer(address(msg.sender), _amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accOctaGoldPerShare).div(1e12);
        user.lastBlcokWithdrawal = block.number;
        user.lastBlockTimestemp = block.timestamp;
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe OctaGold transfer function, just in case if rounding error causes pool to not have enough OctaGolds.
    function safeOctaGoldTransfer(address _to, uint256 _amount) internal {
        uint256 OctaGoldBal = OctaGoldToken.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > OctaGoldBal) {
            transferSuccess = OctaGoldToken.transfer(_to, OctaGoldBal);
        } else {
            transferSuccess = OctaGoldToken.transfer(_to, _amount);
        }
        require(transferSuccess, "safeOctaGoldTransfer: transfer failed");
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
        emit SetDevAddress(msg.sender, _devaddr);
    }

    function setBurnAddress(address _burnAddress) public {
        require(msg.sender == burnAddress, "setBurnAddress: FORBIDDEN");
        burnAddress = _burnAddress;
        emit SetBurnAddress(msg.sender, _burnAddress);
    }

    //Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _OctaGoldPerBlock) public onlyOwner {
        massUpdatePools();
        OctaGoldPerBlock = _OctaGoldPerBlock;
        emit UpdateEmissionRate(msg.sender, _OctaGoldPerBlock);
    }

    function setLockDayWithdraw(uint256 _lockDay) public onlyOwner {
        LockDayWithdraw = _lockDay;
        emit SetLockDayWithdraw(_lockDay);
    }

    function TokenTransferOwner(address _newOwner) public onlyOwner {
        OctaGoldToken.transferOwnership(_newOwner);
        emit SetNewOwnerTokenAddress(msg.sender, _newOwner);
    }

    function safeTransferFrom(IBEP20 token, uint256 _amount) private {
        bool transferSuccess = false;
        uint256 bl = token.balanceOf(address(msg.sender));
        if (bl >= _amount) {
            transferSuccess = token.transferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
        }
        require(transferSuccess, "safeTransferFrom: transfer failed");
    }

    function safeTokenTransfer(
        IBEP20 token,
        address _to,
        uint256 _amount
    ) internal {
        uint256 busdBL = token.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > busdBL) {
            transferSuccess = token.transfer(_to, busdBL);
        } else {
            transferSuccess = token.transfer(_to, _amount);
        }
        require(transferSuccess, "safeTokenTransfer: transfer failed");
    }

    //New Implement
    function PairExists(address _tokenA, address _totkenB)
        public
        view
        returns (bool)
    {
        address pair = uniswapV2Factory.getPair(
            address(_tokenA),
            address(_totkenB)
        );
        if (pair != address(0)) {
            return true;
        }
        return false;
    } 
    function depositBusdInternal(uint256 _pid,uint256 _busdAmount,uint256 _sharePercent)internal{
        PoolInfo storage poolData=poolInfo[_pid];
        uint256 busdShare=_busdAmount.mul(_sharePercent).div(100);
        uint256 busdForTokenA=busdShare.div(2);
        uint256 busdForTokenB=busdShare.sub(busdForTokenA); 
        uint256 amountA=0;
        uint256 amountB=0;
        //Swap
        IUniswapV2Pair pair0=IUniswapV2Pair(address(poolData.lpToken));
        if(pair0.token0()!=tokenBusdAddress){
            safeTokenTransfer(IBEP20(tokenBusdAddress),address(dCAMasterChefDeposit),busdForTokenB);
            amountA=dCAMasterChefDeposit.SwapTo(tokenBusdAddress, pair0.token0(), busdForTokenA, address(this));
        }
        else{
            //BUSD
            amountB=busdForTokenA;
        }
        if(pair0.token1()!=tokenBusdAddress){
            safeTokenTransfer(IBEP20(tokenBusdAddress),address(dCAMasterChefDeposit),busdForTokenB);
            amountB=dCAMasterChefDeposit.SwapTo(tokenBusdAddress, pair0.token1(), busdForTokenB, address(this));
        }
        else{
            //BUSD
            amountB=busdForTokenB;
        }
        //Add liquidity
        safeTokenTransfer(IBEP20(pair0.token0()),address(dCAMasterChefDeposit),amountA);
        safeTokenTransfer(IBEP20(pair0.token1()),address(dCAMasterChefDeposit),amountB);
        (uint256 amountTokenA,uint256 amountTokenB,uint256 amountLp)=dCAMasterChefDeposit.AddLiquidityTo(pair0.token0(),pair0.token1(),amountA,amountB,address(this));
        //Deposit Internal Pool
        internalDeposit(_pid,amountLp,busdShare);
    }
    function depositBusd(uint256 _gId, uint256 _busdAmount)
        public
        nonReentrant
    {
        uint256 busdBalance = IBEP20(tokenBusdAddress).balanceOf(msg.sender);
        require(busdBalance >= _busdAmount, "BUSD Insufficient funds!");
        safeTransferFrom(IBEP20(tokenBusdAddress), _busdAmount); //Transfer from investor to masterchef
        (
            string memory name,
            uint256 LPtoken1PoolIndex,
            uint256 LPtoken1Percent,
            uint256 LPtoken2PoolIndex,
            uint256 LPtoken2Percent,
            uint256 LPtoken3PoolIndex,
            uint256 LPtoken3Percent,
            uint256 LPtoken4PoolIndex,
            uint256 LPtoken4Percent,
            uint16 depositFeeBP
        ) = dCAMasterChefDeposit.gorupPoolnfo(_gId); 
        uint256 poolGroupSum=LPtoken1Percent+LPtoken2Percent+LPtoken3Percent+LPtoken4Percent;
        require(poolGroupSum==100,"Group pool config invalid!");
        depositBusdInternal(LPtoken1PoolIndex,_busdAmount,LPtoken1Percent);//PoolIndex1
        depositBusdInternal(LPtoken2PoolIndex,_busdAmount,LPtoken1Percent);//PoolIndex2
        depositBusdInternal(LPtoken3PoolIndex,_busdAmount,LPtoken1Percent);//PoolIndex3
        depositBusdInternal(LPtoken4PoolIndex,_busdAmount,LPtoken1Percent);//PoolIndex4 
    }
}

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "../libs/IBEP20.sol";
import "../libs/SafeBEP20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../OctaGold.sol";
import "./IOctaGoldMasterPool.sol";
import "../MasterChef.sol"; 
import "../Exchanges/UniswapRouter/IUniswapV2Router02.sol";
import "../Exchanges/UniswapRouter/IUniswapV2Factory.sol";
import "../Exchanges/UniswapRouter/IUniswapV2Pair.sol";
// DCAMasterChef is the master of OctaGold. He can make OctaGold and he is a fair guy.
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once OctaGold is sufficiently
// distributed and the community can show to govern itself.
// Have fun reading it. Hopefully it's bug-free. God bless.
contract DCAMasterChefDeposit is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    uint256 public constant MAX_INT_TYPE = type(uint256).max; 
    uint256 private constant PercentValue = 10000;

    IUniswapV2Router02 public uniswapV2Router;
    IUniswapV2Factory public uniswapV2Factory;
    IUniswapV2Pair public uniswapV2Pair; 
    address public tokenBusdAddress =
    0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    // Info of each user. 
    struct DepositInfo {
        address CreateBy;
        uint256 CreateDate;
        uint256 BusdAmountIn; 
        uint256 PoolIndex;
        uint256 LPAmount;
    } 
    struct GroupPoolInfo { 
        string groupName;//Not duplicate
        uint256 LPtoken1PoolIndex; //BUSD->OctaGold
        uint256 LPtoken1Percent; //5%
        uint256 LPtoken2PoolIndex; //BUSD->OCTAG
        uint256 LPtoken2Percent; //5%
        uint256 LPtoken3PoolIndex;
        uint256 LPtoken3Percent; //45%
        uint256 LPtoken4PoolIndex;
        uint256 LPtoken4Percent; //45%      
        uint16 depositFeeBP; // Deposit fee in basis points
    } 
    GroupPoolInfo[] public gorupPoolnfo;
    mapping(address=>DepositInfo[])public depositInfoHistory; 
    // Info of each user that stakes LP tokens. 
    constructor(
         address _routeUniswapV2
    ) public {
          setRouteSwapAddress(_routeUniswapV2);
    } 
    mapping(string => bool) public poolGroupExistence;
    modifier nonGroupDuplicated(string memory _groupName) {
        require(poolGroupExistence[_groupName] == false, "nonDuplicated: duplicated");
        _;
    } 
    function addGroupPool(
        string memory _groupName, 
        uint256 _LPtoken1PoolIndex, //BUSD->OctaGold
        uint256 _LPtoken1Percent, //5%
        uint256 _LPtoken2PoolIndex,//BUSD->OCTAG
        uint256 _LPtoken2Percent, //5%
        uint256 _LPtoken3PoolIndex,
        uint256 _LPtoken3Percent, //45%
        uint256 _LPtoken4PoolIndex,
        uint256 _LPtoken4Percent,//45%
        uint16 _depositFeeBP) public onlyOwner{
            require(
                _depositFeeBP <= PercentValue,
                "add: invalid deposit fee basis points"
            ); 
            poolGroupExistence[_groupName] = true;
            gorupPoolnfo.push(
                GroupPoolInfo({
                    groupName: _groupName, 
                    LPtoken1PoolIndex: _LPtoken1PoolIndex, 
                    LPtoken1Percent:_LPtoken1Percent,
                    LPtoken2PoolIndex:_LPtoken2PoolIndex,
                    LPtoken2Percent:_LPtoken2Percent,
                    LPtoken3PoolIndex:_LPtoken3PoolIndex, 
                    LPtoken3Percent:_LPtoken3Percent,
                    LPtoken4PoolIndex:_LPtoken4PoolIndex,
                    LPtoken4Percent:_LPtoken4Percent,
                    depositFeeBP: _depositFeeBP
                })
            );
        }
    function setGroupPool(
        uint256 _groupIndex,  
        uint256 _LPtoken1Percent, //5% 
        uint256 _LPtoken2Percent, //5% 
        uint256 _LPtoken3Percent, //45% 
        uint256 _LPtoken4Percent,//45%
        uint16 _depositFeeBP) public onlyOwner{
            require(
                _depositFeeBP <= PercentValue,
                "add: invalid deposit fee basis points"
            ); 
            gorupPoolnfo[_groupIndex].LPtoken1Percent=_LPtoken1Percent;
            gorupPoolnfo[_groupIndex].LPtoken2Percent=_LPtoken2Percent;
            gorupPoolnfo[_groupIndex].LPtoken3Percent=_LPtoken3Percent;
            gorupPoolnfo[_groupIndex].LPtoken4Percent=_LPtoken4Percent;
            gorupPoolnfo[_groupIndex].depositFeeBP=_depositFeeBP; 
    }
    function addDeposit(
        address _ownerAddress,
        uint256 _poolIndex, 
        uint256 _busdAmount, 
        uint256 _lpAmount) public {  
            depositInfoHistory[_ownerAddress].push(DepositInfo({
                CreateBy:address(msg.sender),
                CreateDate:block.timestamp,
                BusdAmountIn:_busdAmount,
                PoolIndex:_poolIndex,
                LPAmount:_lpAmount
            })); 
        }
    function PairExists(address _tokenA, address _totkenB)
        public
        view
        returns (bool)
    {
        address pair = uniswapV2Factory.getPair(
            address(_tokenA),
            address(_totkenB)
        );
        if (pair != address(0)) {
            return true;
        }
        return false;
    }

    function SwapTo(
        address _tokenA,
        address _tokenB,
        uint256 _inputAmount,
        address _toAddress
    ) public returns (uint256) {
        require(
            IBEP20(_tokenA).approve(address(uniswapV2Router), MAX_INT_TYPE),
            "Approve failed."
        );
        require(PairExists(_tokenA, _tokenB), "Pair not exists!");
        address[] memory pathOut = new address[](2);
        pathOut[0] = address(_tokenA);
        pathOut[1] = address(_tokenB);
        uint256[] memory outMin = uniswapV2Router.getAmountsOut(
            _inputAmount,
            pathOut
        );
        require(
            uniswapV2Router.swapExactTokensForTokens(
                _inputAmount,
                outMin[1],
                pathOut,
                address(_toAddress),
                block.timestamp.add(20)
            )[1] > outMin[1],
            "SwapExactTokensForTokens failed."
        );
        return outMin[1];
    }

    function AddLiquidityTo(
        address _tokenA,
        address _tokenB,
        uint256 _tokenAAmount,
        uint256 _tokenBAmount,
        address _toAddress
    )
        public
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        require(
            IBEP20(_tokenA).approve(address(uniswapV2Router), MAX_INT_TYPE),
            "Approve failed."
        );
        require(
            IBEP20(_tokenB).approve(address(uniswapV2Router), MAX_INT_TYPE),
            "Approve failed."
        );
        require(PairExists(_tokenA, _tokenB), "Pair not exists!");
        (
            uint256 outAmountA,
            uint256 outAmountB,
            uint256 outAmountLP
        ) = uniswapV2Router.addLiquidity(
                _tokenA,
                _tokenB,
                _tokenAAmount,
                _tokenBAmount,
                1,
                1,
                _toAddress,
                block.timestamp.add(20)
            );
        return (outAmountA, outAmountB, outAmountLP);
    }
    
    function setRouteSwapAddress(address newAddress) public onlyOwner {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(newAddress);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Factory = IUniswapV2Factory(_uniswapV2Router.factory());
    }
    function RemoveLiquidityTo(
        address _lpAddress,
        uint256 _liquidity,
        address _toAddress
    ) public {
        require(
            IBEP20(_lpAddress).approve(address(uniswapV2Router), MAX_INT_TYPE),
            "Approve failed."
        );
        IUniswapV2Pair pairLp = IUniswapV2Pair(_lpAddress);
        uniswapV2Router.removeLiquidity(
            pairLp.token0(),
            pairLp.token1(),
            _liquidity,
            1,
            1,
            _toAddress,
            block.timestamp.add(20)
        );
    }
    function safeTokenTransfer(
        IBEP20 token,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        uint256 busdBL = token.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > busdBL) {
            transferSuccess = token.transfer(_to, busdBL);
        } else {
            transferSuccess = token.transfer(_to, _amount);
        }
        require(transferSuccess, "safeTokenTransfer: transfer failed");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12; 
//implemented by [email protected]
interface IOctaGoldMasterPool {  
     function mintOctaGoldTo(address toAddress,uint256 amount) external;
}

pragma solidity ^0.6.12;
  
interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

pragma solidity ^0.6.12;
  
interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

pragma solidity ^0.6.12;
 
 



interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

pragma solidity ^0.6.12;
import "../../Exchanges/UniswapRouter/IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./libs/IBEP20.sol";
import "./libs/SafeBEP20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./OctaX.sol";

// MasterChef is the master of OctaX. He can make OctaX and he is a fair guy.
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once OctaX is sufficiently
// distributed and the community can show to govern itself.
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 rewardGoldDebt;
        uint256 lastBlcokWithdrawal;
        // We do some fancy math here. Basically, any point in time, the amount of OctaXs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accOctaXPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accOctaXPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    struct PartnerInfo {
        address partnerAddress;
        bool isRegister;
        uint256 totalChildPartner;
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. OctaXs to distribute per block.
        uint256 lastRewardBlock; // Last block number that OctaXs distribution occurs.
        uint256 accOctaXPerShare; // Accumulated OctaXs per share, times 1e12. See below.
        uint16 depositFeeBP; // Deposit fee in basis points
    }
    // The OctaX TOKEN!
    OctaX public OctaXToken;
    // Dev address.
    address public devaddr;
    // OctaX tokens created per block.
    // Having block every x day.
    uint256 public OctaXPerBlock;

    uint256 public OctaXPerBlockStartValue;

    // Bonus muliplier for early OctaX makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Deposit burn address
    address public burnAddress;
    uint256 public WithdrawalBurnFeePercent;
    uint256 public WithdrawalFeeToRefPercent;
    uint256 public WithdrawalFeeToBurnAddresPercent;
    uint256 public WithdrawalFeeToBurnSupplyPercent;
    address public constant BurnSupplyAddress =
        0x5555500000000000005555500000000000055555;
    uint256 public constant BlockHavingDay = 15; //Having Every XX Day
    uint256 public constant BlockPerDay = 28800; //AVG
    uint256 public LockDayWithdraw = 1; //Withdraw
    uint256 private constant PercentValue = 10000;
    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when OctaX mining starts.
    uint256 public startBlock;

    uint256 public referralFee;
    mapping(address => PartnerInfo) public partnerInfo;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );
    event SetNewOwnerTokenAddress(
        address indexed user,
        address indexed newAddress
    );
    event SetBurnAddress(address indexed user, address indexed newAddress);
    event SetDevAddress(address indexed user, address indexed newAddress);
    event UpdateEmissionRate(address indexed user, uint256 goosePerBlock);
    event SetLockDayWithdraw(uint256 day);
    event SetReferralPartnershipAddress(
        address indexed user,
        address indexed referralAddress
    );

    constructor(
        OctaX _OctaX,
        address _devaddr,
        address _feeAddress,
        uint256 _OctaXPerBlock,
        uint256 _startBlock,
        uint256 _feePartnership,
        uint256 _feeWithdrawalForBurn,
        uint256 _feeWithdrawalFeeToRefPercent,
        uint256 _feeWithdrawalFeeToBurnAddresPercent,
        uint256 _feeWithdrawalFeeToBurnSupplyPercent
    ) public {
        OctaXToken = _OctaX;
        devaddr = _devaddr;
        burnAddress = _feeAddress;
        OctaXPerBlock = _OctaXPerBlock;
        OctaXPerBlockStartValue = _OctaXPerBlock;

        if (block.number > _startBlock) {
            startBlock = block.number;
        } else {
            startBlock = _startBlock;
        }
        referralFee = _feePartnership;
        WithdrawalBurnFeePercent = _feeWithdrawalForBurn;
        WithdrawalFeeToRefPercent = _feeWithdrawalFeeToRefPercent;
        WithdrawalFeeToBurnAddresPercent = _feeWithdrawalFeeToBurnAddresPercent;
        WithdrawalFeeToBurnSupplyPercent = _feeWithdrawalFeeToBurnSupplyPercent;
    }

    function updateBlockPerBlock() internal {
        uint256 currentBlock = block.number.sub(startBlock);
        if (currentBlock > 0) {
            uint256 moveDay = currentBlock.div(BlockPerDay);
            if (moveDay > 0) {
                uint256 hv = moveDay.div(BlockHavingDay);
                if (hv > 0) {
                    uint256 outHv = OctaXPerBlockStartValue.div(hv.add(1));
                    OctaXPerBlock = outHv;
                }
            }
        }
    }

    function getMoveDay() external view returns (uint256) {
        uint256 currentBlock = block.number - startBlock;
        uint256 moveDay = currentBlock.div(BlockPerDay);
        return moveDay;
    }

    //Implement for partner referral
    function registerPartner(address _partnerAddress) public {
        PartnerInfo storage partner = partnerInfo[msg.sender];
        require(
            msg.sender != _partnerAddress,
            "Partnership must have different addresses"
        );
        require(partner.isRegister != true, "partnership has been registed!");
        require(_partnerAddress == address(_partnerAddress), "Invalid address");
        partner.partnerAddress = _partnerAddress;
        partner.isRegister = true;
        emit SetReferralPartnershipAddress(msg.sender, _partnerAddress);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    mapping(IBEP20 => bool) public poolExistence;
    modifier nonDuplicated(IBEP20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(
        uint256 _allocPoint,
        IBEP20 _lpToken,
        uint16 _depositFeeBP,
        bool _withUpdate
    ) public onlyOwner nonDuplicated(_lpToken) {
        require(
            _depositFeeBP <= PercentValue,
            "add: invalid deposit fee basis points"
        );
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExistence[_lpToken] = true;
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accOctaXPerShare: 0,
                depositFeeBP: _depositFeeBP
            })
        );
    }

    // Update the given pool's OctaX allocation point and deposit fee. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        uint16 _depositFeeBP,
        bool _withUpdate
    ) public onlyOwner {
        require(
            _depositFeeBP <= PercentValue,
            "set: invalid deposit fee basis points"
        );
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending OctaXs on frontend.
    function pendingOctaX(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accOctaXPerShare = pool.accOctaXPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier =
                getMultiplier(pool.lastRewardBlock, block.number);
            uint256 OctaXReward =
                multiplier.mul(OctaXPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accOctaXPerShare = accOctaXPerShare.add(
                OctaXReward.mul(1e12).div(lpSupply)
            );
        }
        return
            user.amount.mul(accOctaXPerShare).div(1e12).sub(
                user.rewardDebt
            );
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function thisAddress() public view returns (address) {
        return address(this);
    }

    function withdrawLastLockDay(uint256 _pid, address _user)
        public
        view
        returns (uint256)
    {
        UserInfo storage user = userInfo[_pid][_user];
        uint256 _currentBlock = block.number;
        uint256 _lastBlock = user.lastBlcokWithdrawal;
        if (_currentBlock > _lastBlock) {
            uint256 moveBlockSub = _currentBlock.sub(_lastBlock);
            if (moveBlockSub > 0) {
                uint256 moveDayWd = moveBlockSub.div(BlockPerDay);
                if (LockDayWithdraw > moveDayWd) {
                    uint256 moveDayDef = LockDayWithdraw.sub(moveDayWd);
                    return moveDayDef;
                } else {
                    return 0;
                }
            }
        }
        return LockDayWithdraw;
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        updateBlockPerBlock();
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
        uint256 OctaXReward =
            multiplier.mul(OctaXPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );
        OctaXToken.mint(devaddr, OctaXReward.div(10));
        OctaXToken.mint(address(this), OctaXReward);
        pool.accOctaXPerShare = pool.accOctaXPerShare.add(
            OctaXReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for OctaX allocation.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        PartnerInfo storage partnerData = partnerInfo[msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accOctaXPerShare).div(1e12).sub(
                    user.rewardDebt
                );
            if (pending > 0) {
                uint256 withdrawFeeBurn =
                    pending.mul(WithdrawalBurnFeePercent).div(PercentValue);
                if (referralFee > 0 && partnerData.isRegister) {
                    uint256 withdrawalFeeToRefAmount =
                        withdrawFeeBurn.mul(WithdrawalFeeToRefPercent).div(
                            PercentValue
                        );
                    uint256 withdrawalBalanceOut =
                        withdrawFeeBurn.sub(withdrawalFeeToRefAmount);
                    uint256 withdrawalFeeToBurnSupplyAmount =
                        withdrawalBalanceOut
                            .mul(WithdrawalFeeToBurnSupplyPercent)
                            .div(PercentValue);
                    uint256 withdrawalFeeToBurnAddresAmount =
                        withdrawalBalanceOut.sub(
                            withdrawalFeeToBurnSupplyAmount
                        );
                    if (withdrawalFeeToBurnSupplyAmount > 0) {
                        safeOctaXTransfer(
                            BurnSupplyAddress,
                            withdrawalFeeToBurnSupplyAmount
                        );
                    }
                    if (withdrawalFeeToBurnAddresAmount > 0) {
                        safeOctaXTransfer(
                            burnAddress,
                            withdrawalFeeToBurnAddresAmount
                        );
                    }
                    if (withdrawalFeeToRefAmount > 0) {
                        safeOctaXTransfer(
                            partnerData.partnerAddress,
                            withdrawalFeeToRefAmount
                        );
                    }
                } else {
                    uint256 feeBurnSupplyAmount =
                        withdrawFeeBurn
                            .mul(WithdrawalFeeToBurnSupplyPercent)
                            .div(PercentValue);
                    uint256 feeBurnAddressAmount =
                        withdrawFeeBurn.sub(feeBurnSupplyAmount);
                    if (feeBurnAddressAmount > 0) {
                        safeOctaXTransfer(
                            burnAddress,
                            feeBurnAddressAmount
                        );
                    }
                    if (feeBurnSupplyAmount > 0) {
                        safeOctaXTransfer(
                            BurnSupplyAddress,
                            feeBurnSupplyAmount
                        );
                    }
                }
                uint256 pendingOut = pending.sub(withdrawFeeBurn);
                if (pendingOut > 0) {
                    safeOctaXTransfer(address(msg.sender), pendingOut);
                }
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            if (pool.depositFeeBP > 0) {
                uint256 depositFee =
                    _amount.mul(pool.depositFeeBP).div(PercentValue);
                if (referralFee > 0 && partnerData.isRegister) {
                    uint256 depositFeePartner =
                        depositFee.mul(referralFee).div(PercentValue);
                    uint256 blDepositFee = depositFee.sub(depositFeePartner);
                    pool.lpToken.safeTransfer(
                        partnerData.partnerAddress,
                        depositFeePartner
                    );
                    pool.lpToken.safeTransfer(burnAddress, blDepositFee);
                } else {
                    pool.lpToken.safeTransfer(burnAddress, depositFee);
                }
                user.amount = user.amount.add(_amount).sub(depositFee);
            } else {
                user.amount = user.amount.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accOctaXPerShare).div(1e12);
        user.lastBlcokWithdrawal = block.number;
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        PartnerInfo storage partnerData = partnerInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");

        bool canWithdraw = false;
        uint256 _currentBlock = block.number;
        uint256 _lastBlock = user.lastBlcokWithdrawal;
        if (_currentBlock > _lastBlock) {
            uint256 moveBlockSub = _currentBlock.sub(_lastBlock);
            if (moveBlockSub > 0) {
                uint256 moveDayWd = moveBlockSub.div(BlockPerDay);
                if (LockDayWithdraw <= moveDayWd) {
                    canWithdraw = true;
                }
            }
        }
        require(canWithdraw, "withdraw :time lock");
        updatePool(_pid);
        //Check timeout
        uint256 pending =
            user.amount.mul(pool.accOctaXPerShare).div(1e12).sub(
                user.rewardDebt
            );
        if (pending > 0) {
            uint256 withdrawFeeBurn =
                pending.mul(WithdrawalBurnFeePercent).div(PercentValue);
            if (referralFee > 0 && partnerData.isRegister) {
                uint256 withdrawalFeeToRefAmount =
                    withdrawFeeBurn.mul(WithdrawalFeeToRefPercent).div(
                        PercentValue
                    );
                uint256 withdrawalBalanceOut =
                    withdrawFeeBurn.sub(withdrawalFeeToRefAmount);
                uint256 withdrawalFeeToBurnSupplyAmount =
                    withdrawalBalanceOut
                        .mul(WithdrawalFeeToBurnSupplyPercent)
                        .div(PercentValue);
                uint256 withdrawalFeeToBurnAddresAmount =
                    withdrawalBalanceOut.sub(withdrawalFeeToBurnSupplyAmount);
                if (withdrawalFeeToBurnSupplyAmount > 0) {
                    safeOctaXTransfer(
                        BurnSupplyAddress,
                        withdrawalFeeToBurnSupplyAmount
                    );
                }
                if (withdrawalFeeToBurnAddresAmount > 0) {
                    safeOctaXTransfer(
                        burnAddress,
                        withdrawalFeeToBurnAddresAmount
                    );
                }
                if (withdrawalFeeToRefAmount > 0) {
                    safeOctaXTransfer(
                        partnerData.partnerAddress,
                        withdrawalFeeToRefAmount
                    );
                }
            } else {
                uint256 feeBurnSupplyAmount =
                    withdrawFeeBurn.mul(WithdrawalFeeToBurnSupplyPercent).div(
                        PercentValue
                    );
                uint256 feeBurnAddressAmount =
                    withdrawFeeBurn.sub(feeBurnSupplyAmount);
                if (feeBurnAddressAmount > 0) {
                    safeOctaXTransfer(burnAddress, feeBurnAddressAmount);
                }
                if (feeBurnSupplyAmount > 0) {
                    safeOctaXTransfer(
                        BurnSupplyAddress,
                        feeBurnSupplyAmount
                    );
                }
            }
            uint256 pendingOut = pending.sub(withdrawFeeBurn);
            if (pendingOut > 0) {
                safeOctaXTransfer(address(msg.sender), pendingOut);
            }
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accOctaXPerShare).div(1e12);
        user.lastBlcokWithdrawal = block.number;
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        bool canWithdraw = false;
        uint256 _currentBlock = block.number;
        uint256 _lastBlock = user.lastBlcokWithdrawal;
        if (_currentBlock > _lastBlock) {
            uint256 moveBlockSub = _currentBlock.sub(_lastBlock);
            if (moveBlockSub > 0) {
                uint256 moveDayWd = moveBlockSub.div(BlockPerDay);
                if (LockDayWithdraw <= moveDayWd) {
                    canWithdraw = true;
                }
            }
        }
        require(canWithdraw, "withdraw :time lock");

        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe OctaX transfer function, just in case if rounding error causes pool to not have enough OctaXs.
    function safeOctaXTransfer(address _to, uint256 _amount) internal {
        uint256 OctaXBal = OctaXToken.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > OctaXBal) {
            transferSuccess = OctaXToken.transfer(_to, OctaXBal);
        } else {
            transferSuccess = OctaXToken.transfer(_to, _amount);
        }
        require(transferSuccess, "safeOctaXTransfer: transfer failed");
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
        emit SetDevAddress(msg.sender, _devaddr);
    }

    function setBurnAddress(address _burnAddress) public {
        require(msg.sender == burnAddress, "setBurnAddress: FORBIDDEN");
        burnAddress = _burnAddress;
        emit SetBurnAddress(msg.sender, _burnAddress);
    }

    //Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _OctaXPerBlock) public onlyOwner {
        massUpdatePools();
        OctaXPerBlock = _OctaXPerBlock;
        emit UpdateEmissionRate(msg.sender, _OctaXPerBlock);
    }

    function setLockDayWithdraw(uint256 _lockDay) public onlyOwner {
        LockDayWithdraw = _lockDay;
        emit SetLockDayWithdraw(_lockDay);
    }

    function TokenTransferOwner(address _newOwner) public onlyOwner {
        OctaXToken.transferOwnership(_newOwner);
        emit SetNewOwnerTokenAddress(msg.sender, _newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./libs/BEP20.sol";

// Octa Gold with Governance.
contract OctaGold is BEP20("Octa Gold", "OCTAG") { 
      ///@notice Max Supply 888888
    uint256 public MaxSupply =888888000000000000000000;
    ///@notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        uint256 newTotalSupply = totalSupply();
        newTotalSupply = newTotalSupply.add(_amount);
        require(newTotalSupply <= MaxSupply, "Can't mint token!");
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }
    // Copied and modified from YAM code: 
    mapping(address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance
    );

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator) external view returns (address) {
        return _delegates[delegator];
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 domainSeparator =
            keccak256(
                abi.encode(
                    DOMAIN_TYPEHASH,
                    keccak256(bytes(name())),
                    getChainId(),
                    address(this)
                )
            );

        bytes32 structHash =
            keccak256(
                abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry)
            );

        bytes32 digest =
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, structHash)
            );

        address signatory = ecrecover(digest, v, r, s);
        require(
            signatory != address(0),
            "Dragon Gon::delegateBySig: invalid signature"
        );
        require(
            nonce == nonces[signatory]++,
            "Dragon Gon::delegateBySig: invalid nonce"
        );
        require(now <= expiry, "Dragon Gon::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint256) {
        uint32 nCheckpoints = numCheckpoints[account];
        return
            nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint256 blockNumber)
        external
        view
        returns (uint256)
    {
        require(
            blockNumber < block.number,
            "Dragon Gon::getPriorVotes: not yet determined"
        );

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying Dragon Gons (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint256 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld =
                    srcRepNum > 0
                        ? checkpoints[srcRep][srcRepNum - 1].votes
                        : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld =
                    dstRepNum > 0
                        ? checkpoints[dstRep][dstRepNum - 1].votes
                        : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    ) internal {
        uint32 blockNumber =
            safe32(
                block.number,
                "Dragon Gon::_writeCheckpoint: block number exceeds 32 bits"
            );

        if (
            nCheckpoints > 0 &&
            checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber
        ) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(
                blockNumber,
                newVotes
            );
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint256 n, string memory errorMessage)
        internal
        pure
        returns (uint32)
    {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./libs/BEP20.sol";

// OctaX with Governance.
contract OctaX is BEP20("OctaX", "OCTAX") {
    ///@notice Max Supply 88888
    uint256 public MaxSupply =88888000000000000000000;
    ///@notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        uint256 newTotalSupply = totalSupply();
        newTotalSupply = newTotalSupply.add(_amount);
        require(newTotalSupply <= MaxSupply, "Can't mint token!");
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }
    // Copied and modified from YAM code: 
    mapping(address => address) internal _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance
    );

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator) external view returns (address) {
        return _delegates[delegator];
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 domainSeparator =
            keccak256(
                abi.encode(
                    DOMAIN_TYPEHASH,
                    keccak256(bytes(name())),
                    getChainId(),
                    address(this)
                )
            );

        bytes32 structHash =
            keccak256(
                abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry)
            );

        bytes32 digest =
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, structHash)
            );

        address signatory = ecrecover(digest, v, r, s);
        require(
            signatory != address(0),
            "Dragon Moon::delegateBySig: invalid signature"
        );
        require(
            nonce == nonces[signatory]++,
            "Dragon Moon::delegateBySig: invalid nonce"
        );
        require(now <= expiry, "Dragon Moon::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint256) {
        uint32 nCheckpoints = numCheckpoints[account];
        return
            nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint256 blockNumber)
        external
        view
        returns (uint256)
    {
        require(
            blockNumber < block.number,
            "Dragon Moon::getPriorVotes: not yet determined"
        );

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying Dragon Moons (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint256 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld =
                    srcRepNum > 0
                        ? checkpoints[srcRep][srcRepNum - 1].votes
                        : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld =
                    dstRepNum > 0
                        ? checkpoints[dstRep][dstRepNum - 1].votes
                        : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    ) internal {
        uint32 blockNumber =
            safe32(
                block.number,
                "Dragon Moon::_writeCheckpoint: block number exceeds 32 bits"
            );

        if (
            nCheckpoints > 0 &&
            checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber
        ) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(
                blockNumber,
                newVotes
            );
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint256 n, string memory errorMessage)
        internal
        pure
        returns (uint32)
    {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/GSN/Context.sol";
import "./IBEP20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-BEP20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of BEP20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IBEP20-approve}.
 */
contract BEP20 is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view override returns (address) {
        return owner();
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     */
    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "BEP20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "BEP20: decreased allowance below zero"
            )
        );
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(
            amount,
            "BEP20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");

        _balances[account] = _balances[account].sub(
            amount,
            "BEP20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(
                amount,
                "BEP20: burn amount exceeds allowance"
            )
        );
    }
}

pragma solidity >=0.6.4;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

import "./IBEP20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeBEP20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";

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
library SafeMath {
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor () internal {
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
}

