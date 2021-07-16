//SourceUnit: MingVerify.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.12;

// helper methods for interacting with TRC20 tokens  that do not consistently return true/false
library TransferHelper {
    // TODO: Replace in deloy script
    address constant USDTAddr = 0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C;

    function safeApprove(address token, address to, uint value) internal returns (bool){
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransfer(address token, address to, uint value) internal returns (bool){
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        if (token == USDTAddr) {
            return success;
        }
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal returns (bool){
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        return (success && (data.length == 0 || abi.decode(data, (bool))));
    }
}

interface IBlct {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address _owner) external view returns (uint);
    
    function transfer(address _to, uint _value) external returns (bool);
    function transferFrom(address _from, address _to, uint _value) external returns (bool);
    function approve(address _spender, uint _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint);
    
    function burn(uint _value) external returns (bool);

    function mint(address to, uint256 amount) external returns (bool);
    
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

// SPDX-License-Identifier: MIT


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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface ITRC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address _owner) external view returns (uint);
    
    function transfer(address _to, uint _value) external returns (bool);
    function transferFrom(address _from, address _to, uint _value) external returns (bool);
    function approve(address _spender, uint _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint);
    
    function burn(uint _value) external returns (bool);
    function burnFrom(address _from, uint _value) external returns (bool);
    
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract Mining {
    using SafeMath for uint256;
    using TransferHelper for address;
    
    // Info of each user.
    struct UserInfo {
        uint256 amount;     // 用户提供了多少个LP令牌.
        uint256 rewardDebt; // 奖励债务.
    }

    // Info of each pool.
    struct PoolInfo {
        ITRC20 lpToken;           // LP代币合约、普通代币合约的地址.
        uint256 allocPoint;       // 分配给该池的分配点数.
        uint256 lastRewardBlock;  // BLCT分发发生的最后一个块号.
        uint256 accBlctPerShare; // 每股累计BLCT，乘以1e12.
        uint256 totalAmount;    // 当前池存款总额.
    }
    
    IBlct public blct;                  // The BLCT Token!
    uint256 public blctPerBlock = 0.1*1e18;   // 每个区块产生的BLCT的数量为0.1
    PoolInfo[] public poolInfo;         // 池子列表.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;   // 池子ID=》用户地址=》用户信息.
    mapping(address => uint256) public LpOfPid;     // 池子代币地址=》池子ID - 1
    bool public paused = false;                     // 控制挖矿，为true时停止挖矿
    uint256 public totalAllocPoint = 0;             // 总分配点，必须是所有池中所有分配点的总和。
    uint256 public startBlock;                      // BLCT挖掘开始时的块号。
    address public owner;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event ChangeOwner(address indexed oldOwner, address indexed newOwner);
    
    address public feeAddr; // 收取手续费的地址
    
    constructor(address _feeAddr, IBlct _blct) public {
        startBlock = block.number;
        owner = msg.sender;
        feeAddr = _feeAddr;
        blct = _blct;
    }
    
    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }
    
    modifier onlyOwner() {
        require(_msgSender() == owner, "caller is not the owner");
        _;
    }
    
    function changeBlct(IBlct _blct) public onlyOwner returns(bool _res) {
        blct = _blct;
        _res = true;
    }
    function changeFeeAddr(address _feeAddr) public onlyOwner returns(bool _res) {
        feeAddr = _feeAddr;
        _res = true;
    }
    
    function changeOwner(address _newOwner) public onlyOwner returns(bool _res) {
        require(_newOwner != address(0), "new owner is the zero address");
        emit ChangeOwner(owner, _newOwner);
        owner = _newOwner;
        _res = true;
    }
    
    function setPause() public onlyOwner returns(bool _res) {
        paused = !paused;
        _res = true;
    }
    
    // 设置每个区块产生的BLCT。 只能由owner调用。
    function setBlctPerBlock(uint256 _blctPerBlock) public onlyOwner returns(bool _res) {
        massUpdatePools();
        blctPerBlock = _blctPerBlock;
        _res = true;
    }

    // 更新给定池的BLCT分配点。 只能由owner调用。
    function setAllocPoint(uint256 _pid, uint256 _allocPoint) public onlyOwner returns(bool _res) {
        massUpdatePools();
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
        _res = true;
    }
    
    // 将新的lp添加到池中，只能由owner添加.
    // XXX请勿多次添加相同的LP令牌，否则容易出现错误
    function add(uint256 _allocPoint, ITRC20 _lpToken) public onlyOwner returns(bool _res) {
        require(address(_lpToken) != address(0), "_lpToken is the zero address");
        require(LpOfPid[address(_lpToken)] == 0, "this token already exists");
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
        lpToken : _lpToken,
        allocPoint : _allocPoint,
        lastRewardBlock : lastRewardBlock,
        accBlctPerShare : 0,
        totalAmount : 0
        }));
        LpOfPid[address(_lpToken)] = poolLength();
        _res = true;
    }
    
    function getBlctBlockReward(uint256 _lastRewardBlock) public view returns (uint256) {
        return (block.number.sub(_lastRewardBlock)).mul(blctPerBlock);
    }
    
    // 更新所有池的奖励变量。 注意gas消耗！
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // 将给定池的奖励变量更新为最新。
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        // uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        uint256 lpSupply = pool.totalAmount;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 blockReward = getBlctBlockReward(pool.lastRewardBlock);
        if (blockReward <= 0) {
            return;
        }
        uint256 blctReward = blockReward.mul(pool.allocPoint).div(totalAllocPoint);
        bool minRet = blct.mint(address(this), blctReward);
        require(minRet, "mint fail");
        pool.accBlctPerShare = pool.accBlctPerShare.add(blctReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // 查看功能: 以查看前端的未领取的BLCT。
    function pending(uint256 _pid, address _user) external view returns (uint256){
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accBlctPerShare = pool.accBlctPerShare;
        // uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        uint256 lpSupply = pool.totalAmount;
        if (user.amount > 0) {
            if (block.number > pool.lastRewardBlock) {
                uint256 blockReward = getBlctBlockReward(pool.lastRewardBlock);
                uint256 blctReward = blockReward.mul(pool.allocPoint).div(totalAllocPoint);
                accBlctPerShare = accBlctPerShare.add(blctReward.mul(1e12).div(lpSupply));
                return user.amount.mul(accBlctPerShare).div(1e12).sub(user.rewardDebt);
            }
            if (block.number == pool.lastRewardBlock) {
                return user.amount.mul(accBlctPerShare).div(1e12).sub(user.rewardDebt);
            }
        }
        return 0;
    }
    
    // 存入LP令牌进行BLCT分配
    function deposit(uint256 _pid, uint256 _amount) public notPause returns(bool _res) {
        address _user = _msgSender();
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pendingAmount = user.amount.mul(pool.accBlctPerShare).div(1e12).sub(user.rewardDebt);
            if (pendingAmount > 0) {
                safeBlctTransfer(feeAddr, pendingAmount.mul(6).div(1000));
                safeBlctTransfer(_user, pendingAmount.mul(994).div(1000));
            }
        }
        if (_amount > 0) {
            require(address(pool.lpToken).safeTransferFrom(_user, address(this), _amount), "lp safeTransferFrom fail");
            user.amount = user.amount.add(_amount);
            pool.totalAmount = pool.totalAmount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accBlctPerShare).div(1e12);
        _res = true;
        emit Deposit(_user, _pid, _amount);
    }
    
    // Withdraw LP tokens.
    function withdraw(uint256 _pid, uint256 _amount) public notPause returns(bool _res) {
        PoolInfo storage pool = poolInfo[_pid];
        address _user = _msgSender();
        UserInfo storage user = userInfo[_pid][_user];
        require(user.amount >= _amount, "withdrawBlct: not good");
        updatePool(_pid);
        uint256 pendingAmount = user.amount.mul(pool.accBlctPerShare).div(1e12).sub(user.rewardDebt);
        if (pendingAmount > 0) {
            safeBlctTransfer(feeAddr, pendingAmount.mul(6).div(1000));
            safeBlctTransfer(_user, pendingAmount.mul(994).div(1000));
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.totalAmount = pool.totalAmount.sub(_amount);
            require(address(pool.lpToken).safeTransfer(feeAddr, _amount.mul(6).div(1000)), "lp safeTransfer to feeAddr fail");
            require(address(pool.lpToken).safeTransfer(_user, _amount.mul(994).div(1000)), "lp safeTransfer fail");
        }
        user.rewardDebt = user.amount.mul(pool.accBlctPerShare).div(1e12);
        _res = true;
        emit Withdraw(_user, _pid, _amount);
    }
    
    // 安全的blct transfer函数，以防万一舍入错误导致池中没有足够的blct
    function safeBlctTransfer(address _to, uint256 _amount) internal {
        uint256 blctBal = blct.balanceOf(address(this));
        if (_amount > blctBal) {
            require(address(blct).safeTransfer(_to, blctBal), "blct safeTransfer fail");
        } else {
            require(address(blct).safeTransfer(_to, _amount), "blct safeTransfer fail");
        }
    }
    
    modifier notPause() {
        require(paused == false, "Mining has been suspended");
        _;
    }
    
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}