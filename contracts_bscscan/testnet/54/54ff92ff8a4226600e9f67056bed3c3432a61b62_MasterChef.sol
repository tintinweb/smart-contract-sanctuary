// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./VoidToken.sol";

// MasterChef is the master of Void. He can make Void and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once VOID is sufficiently
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
        //
        // We do some fancy math here. Basically, any point in time, the amount of VOIDs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accVoidPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accVoidPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. VOIDs to distribute per block.
        uint256 lastRewardBlock;  // Last block number that VOIDs distribution occurs.
        uint256 accVoidPerShare;   // Accumulated VOIDs per share, times 1e18. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
    }

    // The VOID TOKEN!
    VoidToken public void;
    // Dev address.
    address public devaddr;
    // The max supply ever
    uint256 public constant maxSupply = 30000 * 10 ** 18;
    // VOID tokens created per block.
    uint256 public voidPerBlock = 0.01 * 10 ** 18;
    // Bonus muliplier for early void makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Deposit Fee address
    address public feeAddress;
    // Total VOID in contract from deposits and rewards
    uint256 private voidDeposit = 0;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when VOID mining starts.
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);    event SetFeeAddress(address indexed user, address indexed newAddress);
    event SetDevAddress(address indexed user, address indexed newAddress);
    event UpdateEmissionRate(address indexed user, uint256 voidPerBlock);

    constructor(
        VoidToken _void,
        address _devaddr,
        address _feeAddress,
        uint256 _startBlock
    ) public {
        void = _void;
        devaddr = _devaddr;
        feeAddress = _feeAddress;
        startBlock = _startBlock;
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
    function add(uint256 _allocPoint, IBEP20 _lpToken, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner nonDuplicated(_lpToken) {
        require(_depositFeeBP <= 10000, "add: invalid deposit fee basis points");
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
            accVoidPerShare : 0,
            depositFeeBP : _depositFeeBP
        }));
    }

    // Update the given pool's VOID allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) public onlyOwner {
        require(_depositFeeBP <= 10000, "set: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (void.totalSupply() >= maxSupply) {
            return 0;
        }
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    // View function to see pending VOIDs on frontend.
    function pendingVoid(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accVoidPerShare = pool.accVoidPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 voidReward = multiplier.mul(voidPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accVoidPerShare = accVoidPerShare.add(voidReward.mul(1e18).div(lpSupply));
        }
        return user.amount.mul(accVoidPerShare).div(1e18).sub(user.rewardDebt);
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
        pool.lastRewardBlock = block.number;
        if (multiplier == 0) {
            return;
        }
        uint256 voidReward = multiplier.mul(voidPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        if (void.totalSupply().add(voidReward) > maxSupply) {
            voidReward = maxSupply.sub(void.totalSupply());
        }
        uint256 voidToDev = voidReward.div(50);
        voidReward = voidReward.sub(voidToDev);
        void.mint(devaddr, voidToDev); // 2% dev fee.
        void.mint(address(this), voidReward);
        voidDeposit = voidDeposit.add(voidReward); // Add void minted
        pool.accVoidPerShare = pool.accVoidPerShare.add(voidReward.mul(1e18).div(lpSupply));
    }

    // Deposit LP tokens to MasterChef for VOID allocation.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accVoidPerShare).div(1e18).sub(user.rewardDebt);
            if(pending > 0) {
                safeVoidTransfer(msg.sender, pending);
                voidDeposit = voidDeposit.sub(pending); // Subtract void reward
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            if(pool.depositFeeBP > 0){
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                user.amount = user.amount.add(_amount).sub(depositFee);
                pool.lpToken.safeTransfer(feeAddress, depositFee);
            }else{
                user.amount = user.amount.add(_amount);
            }
            // Condition added to add void deposits
            if (pool.lpToken == void){
                voidDeposit = voidDeposit.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accVoidPerShare).div(1e18);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accVoidPerShare).div(1e18).sub(user.rewardDebt);
        if(pending > 0) {
            safeVoidTransfer(msg.sender, pending);
            voidDeposit = voidDeposit.sub(pending); // Subtract void reward
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            // Condition added to subtract void deposit and burn the void received by reflection
            if (pool.lpToken == void){
                voidDeposit = voidDeposit.sub(_amount);
                burnReflectedVoid();
            }
        }
        user.rewardDebt = user.amount.mul(pool.accVoidPerShare).div(1e18);
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
        // Same condition added as in withdraw() function
        if (pool.lpToken == void){
            voidDeposit = voidDeposit.sub(amount);
            burnReflectedVoid();
        }
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe void transfer function, just in case if rounding error causes pool to not have enough VOIDs.
    function safeVoidTransfer(address _to, uint256 _amount) internal {
        uint256 voidBal = void.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > voidBal) {
            transferSuccess = void.transfer(_to, voidBal);
        } else {
            transferSuccess = void.transfer(_to, _amount);
        }
        require(transferSuccess, "safeVoidTransfer: transfer failed");
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        require(_devaddr != address(0), "new dev cannot be the zero address");
        devaddr = _devaddr;
        emit SetDevAddress(msg.sender, _devaddr);
    }

    function setFeeAddress(address _feeAddress) public{
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        require(_feeAddress != address(0), "new feeAddress cannot be the zero address");
        feeAddress = _feeAddress;
        emit SetFeeAddress(msg.sender, _feeAddress);
    }

    // Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _voidPerBlock) public onlyOwner {
        massUpdatePools();
        require(_voidPerBlock<=10000000000000000000, "You cannot make VOID Per Block more than 10 VOID"); // Clarified in documentation
        voidPerBlock = _voidPerBlock;
        emit UpdateEmissionRate(msg.sender, _voidPerBlock);
    }

    // Burn the void tokens received by reflection
    function burnReflectedVoid() internal {
        uint256 totalVoidBalance = void.balanceOf(address(this));
        bool burnSuccess = false;
        if(totalVoidBalance >= voidDeposit) {
            uint256 voidToBurn = totalVoidBalance.sub(voidDeposit);
            burnSuccess = void.burn(voidToBurn);
        }
    }
}