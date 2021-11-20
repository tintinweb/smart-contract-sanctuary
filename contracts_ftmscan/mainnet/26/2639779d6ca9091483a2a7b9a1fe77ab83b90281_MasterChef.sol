// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SafeMath.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./Raven.sol";

contract MasterChef is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;         // How many LP tokens the user has provided.
        uint256 rewardDebt;     // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of RAVEN
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accRavenPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accRavenPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. RAVEN to distribute per block.
        uint256 lastRewardBlock;  // Last block that RAVEN distribution occurs.
        uint256 accRavenPerShare;   // Accumulated RAVEN per share, times 1e12. See below.
        uint16 depositFeeBP;      // Deposit fee in basis points
        uint256 lpSupply;
    }

    // The RAVEN TOKEN!
    Raven public raven;
    // Dev address.
    address public devaddr;
    // RAVEN tokens created per block.
    uint256 public ravenPerBlock;
    // Bonus muliplier for early RAVEN makers.
    uint256 public constant BONUS_MULTIPLIER = 1;
    // Deposit Fee address
    address public feeAddress1;
    address public feeAddress2;
    address public feeAddress3;
    //buyback address
    address public buyBackAddress;

    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when Raven mining starts.
    uint256 public startBlock;
    // The maximum supply for RAVEN
    uint256 public maxSupply = 160000 * 10 ** 18;


    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetFeeAddress1(address indexed user, address indexed newAddress);
    event SetFeeAddress2(address indexed user, address indexed newAddress);
    event SetFeeAddress3(address indexed user, address indexed newAddress);
    event SetBuyBackAddress(address indexed user, address indexed newAddress);
    event SetDevAddress(address indexed user, address indexed newAddress);
    event UpdateEmissionRate(address indexed user, uint256 ravenPerBlock);
    event addPool(uint256 indexed pid, address lpToken, uint256 allocPoint, uint256 depositFeeBP);
    event setPool(uint256 indexed pid, address lpToken, uint256 allocPoint, uint256 depositFeeBP);
    event UpdateStartBlock(uint256 newStartBlock);
    event UpdateMaxSupply(uint256 newMaxSupply);

    constructor(
        Raven _raven,
        address _devaddr,
        address _feeAddress1,
        address _feeAddress2,
        address _feeAddress3,
        address _buyBackAddress,
        uint256 _ravenPerBlock,
        uint256 _startBlock
    ) public {
        raven = _raven;
        devaddr = _devaddr;
        feeAddress1 = _feeAddress1;
        feeAddress2 = _feeAddress2;
        feeAddress3 = _feeAddress3;
        buyBackAddress = _buyBackAddress;
        ravenPerBlock = _ravenPerBlock;
        startBlock  = _startBlock;
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
    function add(uint256 _allocPoint, IBEP20 _lpToken, uint16 _depositFeeBP, bool _withUpdate) external onlyOwner nonDuplicated(_lpToken) {
        // valid ERC20 token
        _lpToken.balanceOf(address(this));

        require(_depositFeeBP <= 400, "add: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock  = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolExistence[_lpToken] = true;
        poolInfo.push(PoolInfo({
            lpToken : _lpToken,
            allocPoint : _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accRavenPerShare : 0,
            depositFeeBP : _depositFeeBP,
            lpSupply: 0
        }));

        emit addPool(poolInfo.length - 1, address(_lpToken), _allocPoint, _depositFeeBP);
    }

    // Update the given pool's RAVEN allocation point and deposit fee. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, bool _withUpdate) external onlyOwner {
        require(_depositFeeBP <= 400, "set: invalid deposit fee basis points");
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;

        emit setPool(_pid, address(poolInfo[_pid].lpToken), _allocPoint, _depositFeeBP);
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (raven.totalSupply() >= maxSupply) {
            return 0;
        }
        return _to.sub(_from);
    }

    // View function to see pending RAVEN on frontend.
    function pendingRaven(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accRavenPerShare = pool.accRavenPerShare;
        if (block.number  > pool.lastRewardBlock  && pool.lpSupply != 0 && totalAllocPoint > 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 ravenReward = multiplier.mul(ravenPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accRavenPerShare = accRavenPerShare.add(ravenReward.mul(1e12).div(pool.lpSupply));
        }
        return user.amount.mul(accRavenPerShare).div(1e12).sub(user.rewardDebt);
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
        if (block.number  <= pool.lastRewardBlock) {
            return;
        }
        if (pool.lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock  = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 ravenReward = multiplier.mul(ravenPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        // add condition for max supply
        if (raven.totalSupply().add(ravenReward) > maxSupply) {
            ravenReward = maxSupply.sub(raven.totalSupply());
        }
        raven.mint(devaddr, ravenReward.div(10));
        raven.mint(address(this), ravenReward);
        pool.accRavenPerShare = pool.accRavenPerShare.add(ravenReward.mul(1e12).div(pool.lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for RAVEN allocation.
    function deposit(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accRavenPerShare).div(1e12).sub(user.rewardDebt);
            if (pending > 0) {
                safeRavenTransfer(msg.sender, pending);
            }
        }
        if (_amount > 0) {
            uint256 previousAmount = pool.lpToken.balanceOf(address(this));
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            uint256 afterAmount =  pool.lpToken.balanceOf(address(this));
            _amount = afterAmount.sub(previousAmount);
            if (pool.depositFeeBP > 0) {
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(feeAddress1, depositFee.div(100).mul(29));
                pool.lpToken.safeTransfer(feeAddress2, depositFee.div(100).mul(29));
                pool.lpToken.safeTransfer(feeAddress3, depositFee.div(100).mul(29));
                pool.lpToken.safeTransfer(buyBackAddress, depositFee.div(100).mul(13));
                user.amount = user.amount.add(_amount).sub(depositFee);
                pool.lpSupply = pool.lpSupply.add(_amount).sub(depositFee);
            } else {
                user.amount = user.amount.add(_amount);
                pool.lpSupply = pool.lpSupply.add(_amount);
            }
        }
        user.rewardDebt = user.amount.mul(pool.accRavenPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accRavenPerShare).div(1e12).sub(user.rewardDebt);
        if (pending > 0) {
            safeRavenTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            pool.lpSupply = pool.lpSupply.sub(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accRavenPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) external nonReentrant {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);

        if (pool.lpSupply >=  amount) {
            pool.lpSupply = pool.lpSupply.sub(amount);
        } else {
            pool.lpSupply = 0;
        }

        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    // Safe raven transfer function, just in case if rounding error causes pool to not have enough RAVEN.
    function safeRavenTransfer(address _to, uint256 _amount) internal {
        uint256 ravenBal = raven.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > ravenBal) {
            transferSuccess = raven.transfer(_to, ravenBal);
        } else {
            transferSuccess = raven.transfer(_to, _amount);
        }
        require(transferSuccess, "safeRavenTransfer: transfer failed");
    }

    // Update dev address.
    function setDevAddress(address _devaddr) external {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
        emit SetDevAddress(msg.sender, _devaddr);
    }

    function setFeeAddress1(address _feeAddress1) external {
        require(msg.sender == feeAddress1, "setFeeAddress1: FORBIDDEN");
        require(_feeAddress1 != address(0), "!nonzero");
        feeAddress1 = _feeAddress1;
        emit SetFeeAddress1(msg.sender, _feeAddress1);
    }

    function setFeeAddress2(address _feeAddress2) external {
        require(msg.sender == feeAddress2, "setFeeAddress2: FORBIDDEN");
        require(_feeAddress2 != address(0), "!nonzero");
        feeAddress2 = _feeAddress2;
        emit SetFeeAddress2(msg.sender, _feeAddress2);
    }

    function setFeeAddress3(address _feeAddress3) external {
        require(msg.sender == feeAddress3, "setFeeAddress3: FORBIDDEN");
        require(_feeAddress3 != address(0), "!nonzero");
        feeAddress3 = _feeAddress3;
        emit SetFeeAddress3(msg.sender, _feeAddress3);
    }

    function setBuyBackAddress(address _buyBackAddress) external {
        require(msg.sender == buyBackAddress, "setBuyBackAddress: FORBIDDEN");
        require(_buyBackAddress != address(0), "!nonzero");
        buyBackAddress = _buyBackAddress;
        emit SetBuyBackAddress(msg.sender, _buyBackAddress);
    }

    //Pancake has to add hidden dummy pools inorder to alter the emission, here we make it simple and transparent to all.
    function updateEmissionRate(uint256 _ravenPerBlock) external onlyOwner {
        massUpdatePools();
        ravenPerBlock = _ravenPerBlock;
        emit UpdateEmissionRate(msg.sender, _ravenPerBlock);
    }

    // Only update before start of farm
    function updateStartBlock(uint256 _newStartBlock) external onlyOwner {
        require(block.number < startBlock, "cannot change start block if farm has already started");
        require(block.number < _newStartBlock, "cannot set start block in the past");
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            PoolInfo storage pool = poolInfo[pid];
            pool.lastRewardBlock = _newStartBlock;
        }
        startBlock = _newStartBlock;

        emit UpdateStartBlock(startBlock);
    }

    function updateMaxSupply(uint256 _newMaxSupply) external onlyOwner {
        require(raven.totalSupply() < maxSupply, "cannot change max supply if max supply has already been reached");
        maxSupply = _newMaxSupply;
        emit UpdateMaxSupply(maxSupply);
    }
}