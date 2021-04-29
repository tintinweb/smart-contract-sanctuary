/**
 *Submitted for verification at Etherscan.io on 2021-04-29
*/

// SPDX-License-Identifier: MIT
// @dev TG: defi_guru

pragma solidity >=0.6.0 <0.8.0;
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

pragma solidity >=0.6.4;
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint256 amount) external;
    function deductFee(uint256 amount) external returns(uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity >=0.6.2 <0.8.0;
library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

pragma solidity >=0.6.0 <0.8.0;
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
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

    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) { 
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

pragma solidity >=0.6.0 <0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; 
        return msg.data;
    }
}

pragma solidity >=0.6.0 <0.8.0;
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IVault {
    function stake(address account, uint256 amount) external;
    function unstake(address account, uint256 amount) external;
    function initialize() external;
}

pragma solidity ^0.6.12;
contract Farm is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 lastWithdrawn;
        uint256 lastVested;
        uint256 lastCompounded;
        uint256 vaultShares;
    }

    struct PoolInfo {
        IBEP20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accTokenPerShare;
        uint16 depositFeeBP;
        uint256 minDeposit;
        uint256 shareMultiplier;
    }

    IBEP20 public token;
    IVault public vault;
    address public devaddr;
    uint256 public tokenPerBlock;
    uint256 public constant BONUS_MULTIPLIER = 1;
    
    mapping(address => bool) registeredPools;

    PoolInfo[] public poolInfo;
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    address setup;
    uint256 public totalAllocPoint = 0;
    uint256 public startBlock;
    bool public paused = true;
    bool public initialized = false;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    uint256 public farmReserves;
    uint256 public withdrawDelay = 10 minutes;
    uint256 public vestingDelay = 1 minutes;
    uint256 public compoundDelay = 1 minutes;

    uint public nativePoolReserves;
    uint public undistributedFarmFee;

    constructor(
        IBEP20 _token
    ) public {
        token = _token;
        devaddr = msg.sender;
        tokenPerBlock = 37916666666666666;
        startBlock = 0;
    }
    
    function setVault(IVault _vault) external onlyOwner {
        vault = _vault;
    }

    function startFarming() external onlyOwner {
        require(!initialized,"Farming already started!");
        require(address(vault) != address(0),"Invalid vault!");
        vault.initialize();
        farmReserves = 2_000_000e18;
        require(token.balanceOf(address(this)) > farmReserves, "Should allocate farm reserves!");
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

    function add(uint256 _allocPoint, IBEP20 _token, uint16 _depositFeeBP, uint _minDeposit, uint _shareMultiplier) public onlyOwner {
        require(_depositFeeBP <= 10000, "add: invalid deposit fee basis points");
        require(!registeredPools[address(_token)],"Pool already exists!");
        registeredPools[address(_token)] = true;

        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _token,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accTokenPerShare: 0,
            depositFeeBP: _depositFeeBP,
            minDeposit: _minDeposit,
            shareMultiplier: _shareMultiplier
        }));
    }

    function set(uint256 _pid, uint256 _allocPoint, uint16 _depositFeeBP, uint256 _minDeposit, uint _shareMultiplier) public onlyOwner {
        require(_depositFeeBP <= 10000, "set: invalid deposit fee basis points");
        
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        poolInfo[_pid].depositFeeBP = _depositFeeBP;
        poolInfo[_pid].minDeposit = _minDeposit;
        poolInfo[_pid].shareMultiplier = _shareMultiplier;
    }

    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from).mul(BONUS_MULTIPLIER);
    }

    function pendingTokens(uint256 _pid, address _user) public view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if(address(pool.lpToken) == address(token))
            lpSupply = nativePoolReserves;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 tokenReward = multiplier.mul(tokenPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accTokenPerShare = accTokenPerShare.add(tokenReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accTokenPerShare).div(1e12).sub(user.rewardDebt);
    }

    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public {
        // farming has already finished!
        if(farmReserves == 0)
            return;

        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if(address(pool.lpToken) == address(token))
            lpSupply = nativePoolReserves;
        if (lpSupply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 tokenReward = multiplier.mul(tokenPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        uint256 devReward = tokenReward.div(10);
        tokenReward = tokenReward.sub(devReward);
        if(farmReserves >= tokenReward + devReward) {
            farmReserves = farmReserves.sub(tokenReward).sub(devReward);
            token.transfer(devaddr, devReward);
        } else {
            tokenReward = farmReserves;
            farmReserves = 0;
        }
        pool.accTokenPerShare = pool.accTokenPerShare.add(tokenReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    function distribute(uint amount) external {
        require(msg.sender == address(token), "Only Native Token!");
        if(paused){
            undistributedFarmFee = undistributedFarmFee.add(amount);
            return;
        }
        if(undistributedFarmFee > 0){
            amount = amount.add(undistributedFarmFee);
            undistributedFarmFee = 0;
        }
        for (uint256 i = 0; i < poolInfo.length; i++) {
            PoolInfo storage pool = poolInfo[i];
            uint256 lpSupply = pool.lpToken.balanceOf(address(this));
            if(address(pool.lpToken) == address(token))
                lpSupply = nativePoolReserves;
            if (lpSupply == 0 || pool.allocPoint == 0) {
                pool.lastRewardBlock = block.number;
                return;
            }
            pool.accTokenPerShare = pool.accTokenPerShare.add(amount.mul(1e12).div(lpSupply));
        }
    }

    function deposit(uint256 _pid, uint256 _amount) public {
        require(paused == false, "Paused!");
        require(token.balanceOf(msg.sender) >= poolInfo[_pid].minDeposit,"Not enough Required Token!");
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        bool canHarvest = user.amount > 0 && now > vestingDelay + user.lastVested;
        require(canHarvest || _amount > 0,"Harvest not available yet!");
        updatePool(_pid);
        bool didHarvest = false;
        if (canHarvest) {
            didHarvest = true;
            uint256 pending = user.amount.mul(pool.accTokenPerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeBEP20Transfer(msg.sender, pending);
                // Only allow to harvest each vesting period.
                user.lastVested = now; 
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            // deduct fee from amount, cause when the user withdraws, 
            // they will be receiving less tokens then deposited because of fee
            _amount = token.deductFee(_amount);
            if(address(pool.lpToken) == address(token))
                nativePoolReserves = nativePoolReserves.add(_amount);
             if(pool.depositFeeBP > 0){
                uint256 depositFee = _amount.mul(pool.depositFeeBP).div(10000);
                pool.lpToken.safeTransfer(devaddr, depositFee);
                user.amount = user.amount.add(_amount).sub(depositFee);
            }else{
                user.amount = user.amount.add(_amount);
            }
            // resets last withdraw and vested
            user.lastWithdrawn = now;
            user.lastVested = now;
        }
        if(didHarvest) {
            user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
            addVaultShares(_pid, _amount);
        }
        emit Deposit(msg.sender, _pid, _amount);
    }

    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount && now > withdrawDelay + user.lastWithdrawn, "Invalid Withdraw!");
        user.lastWithdrawn = now;
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accTokenPerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeBEP20Transfer(msg.sender, pending);
        }
        if(_amount > 0) {
           removeVaultShares(_pid, _amount);
           user.amount = user.amount.sub(_amount);
           pool.lpToken.safeTransfer(address(msg.sender), _amount);
           if(address(pool.lpToken) == address(token))
                nativePoolReserves = nativePoolReserves.sub(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }
   
    // only used for the native token pool
    function compound() public {
        // this assumes that the first pool is the native token pool
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        uint256 pending = pendingTokens(0, msg.sender);
        require(pending > 0 && now > user.lastCompounded + compoundDelay, "Compound not available yet!");
        updatePool(0);
        if(address(pool.lpToken) == address(token))
            nativePoolReserves = nativePoolReserves.add(pending);
        user.amount = user.amount.add(pending);          
        user.rewardDebt = user.amount.mul(pool.accTokenPerShare).div(1e12);
        user.lastCompounded = now;
    }

    function addVaultShares(uint _pid, uint currentAmount) private {
        UserInfo storage user = userInfo[_pid][msg.sender];
        PoolInfo storage pool = poolInfo[_pid];
        // this is the amount that is eligible to be use for vault shares
        uint sharesToAdd = user.amount.sub(user.vaultShares).sub(currentAmount);
        user.vaultShares = user.vaultShares.add(sharesToAdd);
        vault.stake(msg.sender,sharesToAdd.mul(pool.shareMultiplier).div(100));
    }

    function removeVaultShares(uint _pid, uint amount) private {
        UserInfo storage user = userInfo[_pid][msg.sender];
        PoolInfo storage pool = poolInfo[_pid];
        // this is the amount that was added newly and is still not available to be claimed as vault shares
        uint nonVaultShareAmount = user.amount.sub(user.vaultShares);
        if(amount > nonVaultShareAmount){
            uint sharesToRemove = amount.sub(nonVaultShareAmount);
            user.vaultShares = user.vaultShares.sub(sharesToRemove);
            vault.unstake(msg.sender,sharesToRemove.mul(pool.shareMultiplier).div(100));
        }
    }

    function setDelays(uint _withdrawDelay, uint _vestingDelay, uint _compoundingDelay) external onlyOwner {
        withdrawDelay = _withdrawDelay;
        vestingDelay = _vestingDelay;
        compoundDelay = _compoundingDelay;
    }

    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    function safeBEP20Transfer(address _to, uint256 _amount) internal {
        uint256 tokenBal = token.balanceOf(address(this));
        if (_amount > tokenBal) {
            token.transfer(_to, tokenBal);
        } else {
            token.transfer(_to, _amount);
        }
    }

    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }

    function updateEmissionRate(uint256 _tokenPerBlock) public onlyOwner {
        massUpdatePools();
        tokenPerBlock = _tokenPerBlock;
    }

    function updatePaused(bool _value) public onlyOwner {
        paused = _value;
    }

    function getUserInfo(uint pid, address account) external view 
        returns(uint lpBalance,uint stakedAmount, uint earnedTokens, uint vaultShares, 
                uint lastWithdraw, uint lastHarvest, uint lastCompound, 
                uint withdrawPeriod, uint vestingPeriod, uint compoundPeriod) 
        {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][account];
        lpBalance = pool.lpToken.balanceOf(account);
        stakedAmount = user.amount;
        earnedTokens = pendingTokens(pid, account);
        vaultShares = user.vaultShares.mul(pool.shareMultiplier).div(100);
        lastWithdraw = user.lastWithdrawn;
        lastHarvest = user.lastVested;
        lastCompound = user.lastCompounded;
        withdrawPeriod = withdrawDelay;
        vestingPeriod = vestingDelay;
        compoundPeriod = compoundDelay;
    }
}