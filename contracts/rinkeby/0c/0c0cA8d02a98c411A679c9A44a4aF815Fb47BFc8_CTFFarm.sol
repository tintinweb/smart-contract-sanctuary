// SPDX-License-Identifier: MIT

pragma solidity 0.7.5;

/*import "./IERC20.sol";
import "./SafeERC20.sol";
import "./EnumerableSet.sol";*/
import "./SafeMath.sol";
//import "./Ownable.sol";
import "./SafeERC20.sol";
import "./CTF.sol";

contract CTFFarm is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of CTF
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accCTFPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws tokens to a pool. Here's what happens:
        //   1. The pool's `accCTFPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. CTFs to distribute per block.
        uint256 lastRewardBlock; // Last block number that CTFs distribution occurs.
        uint256 accCTFPerShare; // Accumulated CTFs per share, times 1e18.
        uint16 depositFeeBP;      // Deposit fee in basis points , 500 = 5%
    }

    // The CTF TOKEN!
    CTF public ctf;
    // Dev address.
    address public devaddr;
    // Deposit Fee address
    address public feeAddress;
    // address to receive the team rewards
    address public teamRewardsReceiver;
    // CTF tokens created per block.
    uint256 public CTFPerBlock;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when CTF mining starts.
    uint256 public startBlock;

    // team share, 10%
    uint256 public teamShare;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);

    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    event Add(address indexed tokenAddress, uint256 indexed allocation);

    event Set(uint256 indexed pid, uint256 indexed allocPoint, uint256 indexed fee);

    event EmergencyWithdraw(
        address indexed user,
        uint256 indexed pid,
        uint256 amount
    );

    event SetDev(address indexed user, address indexed _devaddr);

    constructor(
        CTF _ctf,
        address _devaddr,
        address _teamRewardsReceiver,
        uint256 _teamShare,
        uint256 _startBlock
    ) {
        feeAddress = msg.sender;
        ctf = _ctf;
        devaddr = _devaddr;
        teamShare = _teamShare; // 1000 = 10%
        CTFPerBlock = 4704900000000000; // 0.0047049 CTF per block
        startBlock = _startBlock;
        teamRewardsReceiver = _teamRewardsReceiver;
    }

    modifier validatePool(uint256 _pid) {
        require(_pid < poolInfo.length, "farm: pool do not exists");
        _;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    modifier onlyDev() {
        require(msg.sender == devaddr, "farm: wrong developer");
        _;
    }

    // Add a new token to the pool. Can only be called by the owner.
    // XXX DO NOT add the same token more than once. Rewards will be messed up if you do.
    function checkPoolDuplicate(IERC20 _token) public view {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(poolInfo[pid].token != _token, "add: existing pool?");
        }
    }

    function add(
        uint256 _allocPoint,
        IERC20 _token,
        uint16 _depositFeeBP,
        bool _withUpdate
    ) external onlyDev {
        if (_withUpdate) {
            massUpdatePools();
        }
        checkPoolDuplicate(_token);
        require(_depositFeeBP <= 500, "add: invalid deposit fee basis points");
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                token: _token,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accCTFPerShare: 0, 
                depositFeeBP: _depositFeeBP
            })
        );

        emit Add(address(_token) , _allocPoint);
    }

    // Update the given pool's CTF allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        uint16 _depositFeeBP,
        bool _withUpdate
    ) external onlyDev {
        require(_depositFeeBP <= 500, "set: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        if (poolInfo[_pid].allocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint
                .sub(poolInfo[_pid].allocPoint)
                .add(_allocPoint);
            poolInfo[_pid].allocPoint = _allocPoint;
        }
        
        
        poolInfo[_pid].depositFeeBP = _depositFeeBP;

        emit Set(_pid, _allocPoint, _depositFeeBP);
    }

    // get multiplier reward
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from);
    }

    // View function to see pending CTFs on frontend.
    function pendingCTF(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accCTFPerShare = pool.accCTFPerShare;
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        
        if (block.number > pool.lastRewardBlock && tokenSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 ctfReward = multiplier.mul(CTFPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accCTFPerShare = accCTFPerShare.add(
                ctfReward.mul(1e18).div(tokenSupply)
            );
        }
        return user.amount.mul(accCTFPerShare).div(1e18).sub(user.rewardDebt);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public validatePool(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 tokenSupply = pool.token.balanceOf(address(this));
        if (tokenSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 ctfReward = multiplier.mul(CTFPerBlock).mul(pool.allocPoint).div(totalAllocPoint);

        // staker share
        uint256 teamReward = ctfReward.mul(teamShare).div(10000);

        // mint reward for stakers
        //safeCTFTransfer(address(this), ctfReward.sub(teamReward));

        // mint reward of the team
        safeCTFTransfer(teamRewardsReceiver, teamReward);
        

        pool.accCTFPerShare = pool.accCTFPerShare.add(
            ctfReward.mul(1e18).div(tokenSupply)
        );
        
        pool.lastRewardBlock = block.number;
    }

    // Deposit Tokens for CTF allocation.
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant validatePool(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accCTFPerShare).div(1e18).sub(
                    user.rewardDebt
                );
            if (pending > 0) {
                safeCTFTransfer(msg.sender, pending);
            }
        }
        
        
        
        if (_amount > 0) {
            pool.token.safeTransferFrom(address(msg.sender), address(this), _amount);
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.token.safeTransfer(feeAddress, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
            } else {
                user.amount = user.amount.add(_amount);
            }
        }
        
        
        
        //user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accCTFPerShare).div(1e18);

        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw tokens
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant validatePool(_pid) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(_amount > 0, "withdraw: invalid amount");
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending =
            user.amount.mul(pool.accCTFPerShare).div(1e18).sub(
                user.rewardDebt
            );

        if (pending > 0) {
            safeCTFTransfer(msg.sender, pending);
        }
        
        

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.token.safeTransfer(address(msg.sender), _amount);
        }

        user.rewardDebt = user.amount.mul(pool.accCTFPerShare).div(1e18);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // claim CTF tokens
    function claim(uint256 _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount > 0, "No Rewards to claim");
        updatePool(_pid);
        uint256 pending =
            user.amount.mul(pool.accCTFPerShare).div(1e18).sub(
                user.rewardDebt
            );
        user.rewardDebt = user.amount.mul(pool.accCTFPerShare).div(1e18);
        
        if (pending > 0) {
            safeCTFTransfer(msg.sender, pending);
        }
        
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amt = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.token.safeTransfer(address(msg.sender), amt);
        emit EmergencyWithdraw(msg.sender, _pid, amt);
    }

    // Safe CTFs transfer function, just in case if rounding error causes pool to not have enough CTF.
    function safeCTFTransfer(address _to, uint256 _amount) internal {
        uint256 ctfBal = ctf.balanceOf(address(this));
        if (_amount > ctfBal) {
            require(ctf.transfer(_to, ctfBal), "ERC20: transfer failed");
        } else {
            require(ctf.transfer(_to, _amount), "ECR20: transfer failed");
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) external onlyDev {
        devaddr = _devaddr;
        emit SetDev(msg.sender, _devaddr);
    }
    
    function setFeeAddress(address _feeAddress) external {
        require(msg.sender == feeAddress, "setFeeAddress: FORBIDDEN");
        require(_feeAddress != address(0), "setFeeAddress: ZERO");
        feeAddress = _feeAddress;
    }

    // 1000 is 10%
    function updateTeamShare(uint256 _newShare) external onlyDev {
        require(_newShare > 0 && _newShare < 1000, "Wrong Values");
        teamShare = _newShare;
    }

    function updateCTFperBlock(uint256 _newCTFperBlock) external onlyDev {
        CTFPerBlock = _newCTFperBlock;
    }
}