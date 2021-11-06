/**
 *Submitted for verification at Etherscan.io on 2021-11-06
*/

// 测试质押挖矿的合约
// 可以增加池子
// 可以修改池子的占比
// 可以修改全局的每个区块产出的数量
pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;


// erc20
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// 安全数学计算
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "Math error");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(a >= b, "Math error");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "Math error");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint256 c = a / b;
        return c;
    }

}


// 安全转账
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        // (bool success,) = to.call{value:value}(new bytes(0));
        (bool success,) = to.call.value(value)(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}


// 管理员
contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}


// 挖矿合约
contract WaKuang is Ownable {
    using SafeMath for uint256;

    // 用户的质押信息
    struct UserInfo {
        // 用户质押的数量
        uint256 amount;
        // 用户已领取的数量; 用于计算收益的, 不是用户真正领取走的数量
        uint256 rewardDebt;
    }
    // 质押池子的信息
    struct PoolInfo {
        // 池子的地址; 可以是单币也可以是LP;
        IERC20 lpToken;
        // 池子收益的占比
        uint256 allocPoint;
        // 最后的区块; 用来计算每个阶段的股份收益
        uint256 lastRewardBlock;
        // 记录股份; 用来统计给个阶段的股份
        uint256 accSushiPerShare;
    }
    // 所有的池子信息
    PoolInfo[] public poolInfo;
    // 池子id对应用户的质押信息
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    // 是否已经存在; true=存在, false=不存在; 为了安全靠谱起见, 加上比较好;
    mapping(address => bool) public isPool;

    // 总的占比
    uint256 public totalAllocPoint = 0;
    // 每个区块可以挖出数量
    uint256 public sushiPerBlock;
    // 开始挖矿的区块高度
    uint256 public startBlock;
    // ETM代币的合约地址
    address public sushi;


    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    // 参数1: ETM代币合约地址
    // 参数2: 每个区块挖出的总数量
    // 参数3: 开始挖矿的高度
    constructor(address _sushi, uint256 _sushiPerBlock, uint256 _startBlock) public {
        sushi = _sushi;
        sushiPerBlock = _sushiPerBlock;
        startBlock = _startBlock;
    }

    // 池子必须是存在的
    modifier onlyIsPool(uint256 _pid) {
        // 池子必须存在的
        require(isPool[address(poolInfo[_pid].lpToken)], "add: pool not exist");
        _;
    }

    // 查询全部池子的长度
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // 查询全部池子的信息
    function getPools() external view returns (PoolInfo[] memory _pools) {
        uint256 _length = poolInfo.length;
        _pools = new PoolInfo[](_length);
        for(uint256 i = 0; i < _length; i++) {
            _pools[i] = poolInfo[i];
        }
        return _pools;
    }

    // 添加一个池子
    // 参数1: 这个池子的占比
    // 参数2: 池子的地址
    function add(uint256 _allocPoint, IERC20 _lpToken) public onlyOwner {
        // 池子必须不存在的
        require(!isPool[address(_lpToken)], "add: pool exist");
        // 池子设置成已经存在
        isPool[address(_lpToken)] = true;

        // 最后的挖矿区块;
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        // 增加总的挖矿占比
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        // 增加一个池子
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accSushiPerShare: 0
            }));
    }

    // 修改池子的挖矿占比
    // 参数1: 池子的id; 也就是对应数组的索引, 从0开始;
    function set(uint256 _pid, uint256 _allocPoint) public onlyOwner onlyIsPool(_pid) {
        // 重置该池子的信息
        updatePool(_pid);
        // 修改信息
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // 修改每个区块的挖矿数量; 考虑gas费溢出的问题;
    function setSushiPerBlock(uint256 _sushiPerBlock) public onlyOwner {
        // 循环重置池子的信息
        massUpdatePools();
        // 从新赋值
        sushiPerBlock = _sushiPerBlock;
    }

    // 循环遍历更新所有的池子信息; accSushiPerShare和lastRewardBlock;
    function massUpdatePools() internal {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; pid++) {
            updatePool(pid);
        }
    }

    // 更新池子;
    function updatePool(uint256 _pid) internal {
        PoolInfo storage pool = poolInfo[_pid];
        // 如果没有新的区块收益, 就不更新
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        // 如果本合约没有质押数量的话, 也不用更新池子信息
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        // 计算挖矿的区块数量
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        // 计算出池子本次总挖矿收益;
        uint256 sushiReward = multiplier.mul(sushiPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        // 计算股份, 从新赋值; 通过收益去计算股份
        pool.accSushiPerShare = pool.accSushiPerShare.add(sushiReward.mul(1e12).div(lpSupply));
        // 从新赋值最新的区块
        pool.lastRewardBlock = block.number;
    }

    // 计算用户当前可领取的收益数量(pending);
    // 参数1: 池子的pid
    // 参数2: 用户的地址
    function pendingSushi(uint256 _pid, address _user) public view returns (uint256) {
        // 获取池子的id的对应信息
        PoolInfo storage pool = poolInfo[_pid];
        // 查询池子对应用户的信息
        UserInfo storage user = userInfo[_pid][_user];
        // 获取池子的股份; 这个是memory变量, 不会修改到数据;
        uint256 accSushiPerShare = pool.accSushiPerShare;
        // 获取本合约的LP余额
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        // 如果当前有了的新的挖矿区块, 并且质押量不等于0
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            // 计算挖矿的区块数量
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            // 计算出池子本次总挖矿收益;
            uint256 sushiReward = multiplier.mul(sushiPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            // 计算股份; 通过收益去计算股份
            accSushiPerShare = accSushiPerShare.add(sushiReward.mul(1e12).div(lpSupply));
        }
        // 返回可领取收益
        return user.amount.mul(accSushiPerShare).div(1e12).sub(user.rewardDebt);
    }

    function getMultiplier(uint256 _start, uint256 _end) public pure returns (uint256) {
        return _end.sub(_start);
    }

    // 质押; 如果质押的是0, 就是领取收益,不质押
    // 参数1: 池子的id
    // 参数2: 质押的数量
    function deposit(uint256 _pid, uint256 _amount) public onlyIsPool(_pid) {
        // 获取到池子的详情信息
        PoolInfo storage pool = poolInfo[_pid];
        // 查询此池子对应的用户的质押信息
        UserInfo storage user = userInfo[_pid][msg.sender];
        // 更新池子id, 会更新accSushiPerShare和lastRewardBlock
        updatePool(_pid);

        // 说明用户之前质押了币, 那就说明用户可能会有收益
        if (user.amount > 0) {
            // 计算用户的收益
            // 用户收益 = 用户质押量 * 池子股份 / 1e12 - 用户已领取数量
            uint256 pending = user.amount.mul(pool.accSushiPerShare).div(1e12).sub(user.rewardDebt);
            // 开始转账; 考虑到有些token不能交易0
            if (pending > 0) {
                TransferHelper.safeTransfer(sushi, msg.sender, pending);
            }
        }
        // 把质押的lp币转给合约
        if (_amount > 0) {
            TransferHelper.safeTransferFrom(address(pool.lpToken), address(msg.sender), address(this), _amount);
        }
        // 增加用户的总质押量
        user.amount = user.amount.add(_amount);
        // 增加用户的已经领取的收益
        user.rewardDebt = user.amount.mul(pool.accSushiPerShare).div(1e12);
        // 触发事件
        emit Deposit(msg.sender, _pid, _amount);
    }

    // 提取; 如果提取的是0, 就是领取收益, 不提取本金
    // 参数1: 提取池子的id
    // 参数2: 提取的代币数量
    function withdraw(uint256 _pid, uint256 _amount) public onlyIsPool(_pid) {
        // 获取到池子的详情信息
        PoolInfo storage pool = poolInfo[_pid];
        // 查询此池子对应的用户的质押信息
        UserInfo storage user = userInfo[_pid][msg.sender];
        // 用户的质押总金额必须大于等于提取的金额
        require(user.amount >= _amount, "withdraw: not good");
        // 更新池子, 会更新accSushiPerShare和lastRewardBlock
        updatePool(_pid);
        // 给用户计算收益, 并且领取;
        // 用户收益 = 用户质押量 * 池子股份 / 1e12 - 用户已领取数量
        uint256 pending = user.amount.mul(pool.accSushiPerShare).div(1e12).sub(user.rewardDebt);
        // 开始转账收益; 考虑到有些token不能交易0
        if (pending > 0) {
            TransferHelper.safeTransfer(sushi, msg.sender, pending);
        }
        // 减去用户质押总金额
        user.amount = user.amount.sub(_amount);
        // 从新计算已经领取的金额;
        user.rewardDebt = user.amount.mul(pool.accSushiPerShare).div(1e12);
        // 转给用户本金
        if (_amount > 0) {
            TransferHelper.safeTransfer(sushi, msg.sender, _amount);
        }
        // 触发提取事件
        emit Withdraw(msg.sender, _pid, _amount);
    }




}