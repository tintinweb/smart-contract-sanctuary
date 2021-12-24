// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";

import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./IUniswapV2Router02.sol";

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./UFGrainToken.sol";

// MasterChef is the master of UFGRAIN. He can make UFGRAIN and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once UFGRAIN is sufgrainiciently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MasterUFGrain is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of UFGRAINs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accUFGRAINPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accUFGRAINPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. UFGRAIN to distribute per block.
        uint256 lastRewardBlock;  // Last block number that UFGRAIN distribution occurs.
        uint256 accUFGrainPerShare;   // Accumulated UFGRAIN per share, times 1e12. See below.
        uint16 withdrawFeeBP;      // Withdraw fee in basis points
    }
    
    // The operator is NOT the owner, is the operator of the machine
    address private _operator;

    // The UFUFGRAIN TOKEN!
    UFGrainToken public ufgrain;

    // The Router
    IUniswapV2Router02 public router;

    // UFGRAIN tokens created per block.
    uint256 public ufgrainPerBlock;
    // Bonus muliplier for early UFGRAIN makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Deposit Fee address / Dev Address and BuyBack Wallet
    address public feeAddDev;
    address public feeAddBb;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when UFGRAIN mining starts.
    uint256 public startBlock;

    // Convert Rewards
    bool public convertRewards = false;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmissionRateUpdated(address indexed user, uint256 ufgrainPerBlock);

    constructor(
        UFGrainToken _ufgrain,
        address _feeAddDev,
        address _feeAddBb,
        uint256 _ufgrainPerBlock,
        uint256 _startBlock
    ) public {
        ufgrain = _ufgrain;
        feeAddDev = _feeAddDev;
        feeAddBb = _feeAddBb;
        ufgrainPerBlock = _ufgrainPerBlock;
        startBlock = _startBlock;
        _operator = msg.sender;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    mapping(IBEP20 => bool) public poolExistence;

    modifier nonDuplicated(IBEP20 _lpToken) {
        require(poolExistence[_lpToken] == false, "nonDuplicated: duplicated");
        _;
    }

    // Operator CAN do modifier
    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    modifier poolExists(uint256 pid) {
        require(pid < poolInfo.length, "pool inexistent");
        _;
    }

    modifier lpProtection(uint256 pid, uint256 _amount) {
        PoolInfo storage pool = poolInfo[pid];
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        uint256 maxWithdraw = lpSupply.mul(1500).div(10000);
        require(_amount < maxWithdraw, "withdraw: _amount is higher than maximum LP withdraw");
        _;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint256 _allocPoint, IBEP20 _lpToken, uint16 _withdrawFeeBP, bool _withUpdate) public onlyOwner nonDuplicated(_lpToken) {
        require(_withdrawFeeBP <= 1200, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExistence[_lpToken] = true;
        poolInfo.push(PoolInfo({
            lpToken : _lpToken,
            allocPoint : _allocPoint,
            lastRewardBlock : lastRewardBlock,
            accUFGrainPerShare : 0,
            withdrawFeeBP : _withdrawFeeBP
        }));
    }

    // Update the given pool's UFGRAIN allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _withdrawFeeBP, bool _withUpdate) public onlyOwner poolExists(_pid) {
        require(_withdrawFeeBP <= 1200, "set: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].withdrawFeeBP = _withdrawFeeBP;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending UFGRAINs on frontend.
    function pendingUFGrain(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accUFGrainPerShare = pool.accUFGrainPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 ufgrainReward = multiplier.mul(ufgrainPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accUFGrainPerShare = accUFGrainPerShare.add(ufgrainReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accUFGrainPerShare).div(1e12).sub(user.rewardDebt);
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
        uint256 ufgrainReward = multiplier.mul(ufgrainPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        if (convertRewards) {
            ufgrain.mint(address(this), ufgrainReward.mul(1500).div(10000));
            convertAndSendRewards(ufgrainReward.mul(1500).div(10000));
        } else {
            ufgrain.mint(feeAddDev, ufgrainReward.mul(1500).div(10000));
        }
        ufgrain.mint(address(this), ufgrainReward);
        pool.accUFGrainPerShare = pool.accUFGrainPerShare.add(ufgrainReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for UFGRAIN allocation.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant poolExists(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);

        // Try to harvest
        if (user.amount > 0) {
            harvest(_pid);
        }

        // Thanks for RugDoc advice
        // Add user.amount
        if (_amount > 0) {
            // LP ammount before
            uint256 before = pool.lpToken.balanceOf(address(this));
            // Transafer from user
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            // LP ammount after
            uint256 _after = pool.lpToken.balanceOf(address(this));
            // Real amount of LP transfer to this address
            _amount = _after.sub(before);
            user.amount = user.amount.add(_amount);
        }

        // Update user reward debt and emit Deposit
        user.rewardDebt = user.amount.mul(pool.accUFGrainPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant poolExists(_pid) lpProtection(_pid, _amount){
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: Amount to withdraw higher than LP balance.");
        updatePool(_pid);
        
        // Harvest before withdraw
        harvest(_pid);

        // Withdraw procedure
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            // Remove fee 
            if (pool.withdrawFeeBP > 0) {
                uint256 withdrawFee = _amount.mul(pool.withdrawFeeBP).div(10000);
                uint256 withdrawFeeHalf = withdrawFee.div(2);
                pool.lpToken.safeTransfer(feeAddDev, withdrawFeeHalf);
                pool.lpToken.safeTransfer(feeAddBb, withdrawFeeHalf);
                _amount = _amount.sub(withdrawFee);
                pool.lpToken.safeTransfer(address(msg.sender), _amount);
            }
        }

        user.rewardDebt = user.amount.mul(pool.accUFGrainPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    /// @dev Swap tokens for eth
    function convertAndSendRewards(uint256 tokenAmount) private {
        // generate the UFGRAIN pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(ufgrain);
        path[1] = router.WETH();

        ufgrain.approve(address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            feeAddDev,
            block.timestamp
        );
    }

    // Safe UFGRAIN transfer function, just in case if rounding error causes pool to not have enough UFGRAINs.
    function safeUFGrainTransfer(address _to, uint256 _amount) internal {
        uint256 ufgrainBal = ufgrain.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > ufgrainBal) {
            transferSuccess = ufgrain.transfer(_to, ufgrainBal);
        } else {
            transferSuccess = ufgrain.transfer(_to, _amount);
        }
        require(transferSuccess, "safeUFGrainTransfer: transfer failed");
    }

    // Harvest UFGRAINs.
    function harvest(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 pending = user.amount.mul(pool.accUFGrainPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            // send rewards
            safeUFGrainTransfer(msg.sender, pending);
        }
    }

    // Update router
    function updateRouter(address _router) public onlyOperator {
        router = IUniswapV2Router02(_router);
    }

    // Pancake has to add hidden dummy pools in order to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _ufgrainPerBlock) public onlyOperator {
        massUpdatePools();
        emit EmissionRateUpdated(msg.sender, _ufgrainPerBlock);
        ufgrainPerBlock = _ufgrainPerBlock;
    }
    
    // update fee address dev
    function updateFeeAddDev(address _newFeeAddDev) public onlyOperator {
        require(_newFeeAddDev != address(0), "update: fee address dev is zero");
        feeAddDev = _newFeeAddDev;
    }

    // update fee address BuyBack
    function updateFeeAddBb(address _newFeeAddBb) public onlyOperator {
        require(_newFeeAddBb != address(0), "update: fee address BuyBack is zero");
        feeAddBb = _newFeeAddBb;
    }

    function updateStartBlock(uint256 _newStartBlock) public onlyOperator {
        startBlock = _newStartBlock;
    }

    // allow owner to finalize the presale once the presale is ended
    function updateUFGRAINOwner(address newOwner) public onlyOperator {
        ufgrain.transferOwnership(newOwner);
    }

    // Update convert rewards
    function updateConvertRewards(bool _convert) public onlyOperator {
        convertRewards = _convert;
    }

    // To receive BNB from SwapRouter when swapping
    receive() external payable {}
}