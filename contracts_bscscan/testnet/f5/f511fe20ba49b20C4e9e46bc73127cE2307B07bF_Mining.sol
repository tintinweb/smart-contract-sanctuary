/**
 *Submitted for verification at BscScan.com on 2021-11-30
*/

/*
质押LP可以获得平台币收益 --> 质押挖矿

用户swap兑换代币会进行交易挖矿  --> 交易挖矿

董事会
用户质押平台币到董事会, 会获得平台币奖励;
- 会有上下级关系
- 可以单独提取本金或收益
- 提取本金或收益, 都需要交税, 税收是按比例给到董事会的其它人员
- 提取的时候, 像扣税, 收益再按比例给到上级, 最后再给自己本金或收益
*/
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



// 挖矿配置合约; 用于配置或获取相关数据;
contract MiningSet is Ownable {
    using SafeMath for uint256;

    // 收益币的合约地址; 平台币
    address public sushi;
    // 每个区块的产币数量; 总的, 包括LP挖矿, 交易挖矿, 董事会挖矿
    uint256 public sushiPerBlock;
    // 开始挖矿的区块高度
    uint256 public startBlock;
    // 三种挖矿的占比; 默认 LP=35%, 交易挖矿=35%, 董事会=30%;
    uint256[3] public mining3 = [35, 35, 30];
    // 三种池子的每个区块的产币数量
    uint256 public sushiPerBlockLp;
    uint256 public sushiPerBlockTransfer;
    uint256 public sushiPerBlockBoard;
    // USDT-平台币的配对合约地址
    address public pairUsdtSushi;
    // Usdt代币地址
    address public usdt;
    // 路由合约地址; 用于交易挖矿的
    address public routerAddress;


    constructor(address _sushi, uint256 _sushiPerBlock, address _usdt, address _routerAddress) public {
        sushi = _sushi;
        sushiPerBlock = _sushiPerBlock;
        startBlock = block.number;
        usdt = _usdt;
        routerAddress = _routerAddress;
    }

    // 计算产出区块的数量
    function getMultiplier(uint256 _start, uint256 _end) public pure returns (uint256) {
        return _end > _start ? _end.sub(_start) : 0;
    }

    // 获取USDT-平台币合约的价格比例
    function getPrice() public view returns (uint256) {
        // 如果目前没有设置配对合约地址的话, 价格就按1来计算
        if (pairUsdtSushi == address(0)) {
            return 1e10;
        }
        // 获取该地址的两个币的余额
        uint256 _balanceUsdt = IERC20(usdt).balanceOf(pairUsdtSushi);
        uint256 _balanceSushi = IERC20(sushi).balanceOf(pairUsdtSushi);
        // 根据比例去计算价格; 防止价格过小, 所以先乘以10个0, 后面计算需要除以10个0
        return _balanceUsdt.mul(1e10).div(_balanceSushi);
    }

}

// LP挖矿; 用户质押LP代币, 进行挖矿产出
contract MiningLp is MiningSet {
    // 用户的质押信息
    struct UserInfoLp {
        // 用户质押的数量
        uint256 amount;
        // 用户已领取的数量; 用于计算收益的, 不是用户真正领取走的数量
        uint256 rewardDebt;
    }
    // 质押池子的信息
    struct PoolInfoLp {
        // 池子的地址; 一定得是LP;
        IERC20 lpToken;
        // 池子收益的占比
        uint256 allocPoint;
        // 最后的区块; 用来计算每个阶段的股份收益
        uint256 lastRewardBlock;
        // 记录股份; 用来统计给个阶段的股份
        uint256 accSushiPerShare;
        // 池子质押的总量
        uint256 lpSupplyLp;
    }
    // 所有的池子信息
    PoolInfoLp[] public poolInfoLp;
    // 池子id对应用户的质押信息
    mapping (uint256 => mapping (address => UserInfoLp)) public userInfoLp;
    // 是否已经存在; true=存在, false=不存在; 为了安全靠谱起见, 加上比较好;
    mapping(address => bool) public isPoolLp;
    // LP的总的占比例
    uint256 public totalAllocPointLp = 0;

    event DepositLp(address indexed user, uint256 indexed pid, uint256 amount);
    event WithdrawLp(address indexed user, uint256 indexed pid, uint256 amount);

    constructor() public {}

    // 池子必须是存在的
    modifier onlyIsPoolLp(uint256 _pid) {
        // 池子必须存在的
        require(isPoolLp[address(poolInfoLp[_pid].lpToken)], "add: pool not exist");
        _;
    }

    // 查询全部池子的长度
    function poolLengthLp() external view returns (uint256) {
        return poolInfoLp.length;
    }

    // 查询全部池子的信息
    function getPoolsLp() external view returns (PoolInfoLp[] memory _pools) {
        uint256 _length = poolInfoLp.length;
        _pools = new PoolInfoLp[](_length);
        for(uint256 i = 0; i < _length; i++) {
            _pools[i] = poolInfoLp[i];
        }
        return _pools;
    }

    // 添加一个池子
    // 参数1: 这个池子的占比
    // 参数2: 池子的地址
    function addLp(uint256 _allocPoint, IERC20 _lpToken) public onlyOwner {
        // 池子必须不存在的
        require(!isPoolLp[address(_lpToken)], "add: pool exist");
        // 池子设置成已经存在
        isPoolLp[address(_lpToken)] = true;

        // 最后的挖矿区块;
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        // 增加总的挖矿占比
        totalAllocPointLp = totalAllocPointLp.add(_allocPoint);
        // 增加一个池子
        poolInfoLp.push(PoolInfoLp({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accSushiPerShare: 0,
            lpSupplyLp: 0
            }));
    }

    // 修改池子的挖矿占比
    // 参数1: 池子的id; 也就是对应数组的索引, 从0开始;
    function setLp(uint256 _pid, uint256 _allocPoint) public onlyOwner onlyIsPoolLp(_pid) {
        // 重置该池子的信息
        updatePoolLp(_pid);
        // 修改信息
        totalAllocPointLp = totalAllocPointLp.sub(poolInfoLp[_pid].allocPoint).add(_allocPoint);
        poolInfoLp[_pid].allocPoint = _allocPoint;
    }

    // 循环遍历更新所有的池子信息; accSushiPerShare和lastRewardBlock;
    function massUpdatePoolsLp() public {
        uint256 length = poolInfoLp.length;
        for (uint256 pid = 0; pid < length; pid++) {
            updatePoolLp(pid);
        }
    }

    // 更新池子;
    function updatePoolLp(uint256 _pid) internal {
        PoolInfoLp storage pool = poolInfoLp[_pid];
        // 如果没有新的区块收益, 就不更新
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        // 如果本合约没有质押数量的话, 也不用更新池子信息
        uint256 lpSupply = pool.lpSupplyLp;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        // 计算挖矿的区块数量
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        // 计算出池子本次总挖矿收益;
        uint256 sushiReward = multiplier.mul(sushiPerBlockLp).mul(pool.allocPoint).div(totalAllocPointLp);
        // 计算股份, 从新赋值; 通过收益去计算股份
        pool.accSushiPerShare = pool.accSushiPerShare.add(sushiReward.mul(1e12).div(lpSupply));
        // 从新赋值最新的区块
        pool.lastRewardBlock = block.number;
    }

    // 计算用户当前可领取的收益数量(pending);
    // 参数1: 池子的pid
    // 参数2: 用户的地址
    function pendingSushiLp(uint256 _pid, address _user) public view returns (uint256) {
        // 获取池子的id的对应信息
        PoolInfoLp storage pool = poolInfoLp[_pid];
        // 查询池子对应用户的信息
        UserInfoLp storage user = userInfoLp[_pid][_user];
        // 获取池子的股份; 这个是memory变量, 不会修改到数据;
        uint256 accSushiPerShare = pool.accSushiPerShare;
        // 获取本合约的LP余额
        uint256 lpSupply = pool.lpSupplyLp;
        // 如果当前有了的新的挖矿区块, 并且质押量不等于0
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            // 计算挖矿的区块数量
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            // 计算出池子本次总挖矿收益;
            uint256 sushiReward = multiplier.mul(sushiPerBlockLp).mul(pool.allocPoint).div(totalAllocPointLp);
            // 计算股份; 通过收益去计算股份
            accSushiPerShare = accSushiPerShare.add(sushiReward.mul(1e12).div(lpSupply));
        }
        // 返回可领取收益
        return user.amount.mul(accSushiPerShare).div(1e12).sub(user.rewardDebt);
    }

    // 质押; 如果质押的是0, 就是领取收益,不质押
    // 参数1: 池子的id
    // 参数2: 质押的数量
    function depositLp(uint256 _pid, uint256 _amount) public onlyIsPoolLp(_pid) {
        // 获取到池子的详情信息
        PoolInfoLp storage pool = poolInfoLp[_pid];
        // 查询此池子对应的用户的质押信息
        UserInfoLp storage user = userInfoLp[_pid][msg.sender];
        // 更新池子id, 会更新accSushiPerShare和lastRewardBlock
        updatePoolLp(_pid);

        // 说明用户之前质押了币, 那就说明用户可能会有收益
        if (user.amount > 0) {
            // 计算用户的收益
            // 用户收益 = 用户质押量 * 池子股份 / 1e12 - 用户已领取数量
            uint256 pending = user.amount.mul(pool.accSushiPerShare).div(1e12).sub(user.rewardDebt);
            // 开始转账;
            TransferHelper.safeTransfer(sushi, msg.sender, pending);
        }
        // 把质押的lp币转给合约
        TransferHelper.safeTransferFrom(address(pool.lpToken), address(msg.sender), address(this), _amount);
        // 增加池子的总质押量
        pool.lpSupplyLp = pool.lpSupplyLp.add(_amount);

        // 增加用户的总质押量
        user.amount = user.amount.add(_amount);
        // 增加用户的已经领取的收益
        user.rewardDebt = user.amount.mul(pool.accSushiPerShare).div(1e12);
        // 触发事件
        emit DepositLp(msg.sender, _pid, _amount);
    }

    // 提取; 如果提取的是0, 就是领取收益, 不提取本金
    // 参数1: 提取池子的id
    // 参数2: 提取的代币数量
    function withdrawLp(uint256 _pid, uint256 _amount) public onlyIsPoolLp(_pid) {
        // 获取到池子的详情信息
        PoolInfoLp storage pool = poolInfoLp[_pid];
        // 查询此池子对应的用户的质押信息
        UserInfoLp storage user = userInfoLp[_pid][msg.sender];
        // 用户的质押总金额必须大于等于提取的金额
        require(user.amount >= _amount, "withdraw: not good");
        // 更新池子, 会更新accSushiPerShare和lastRewardBlock
        updatePoolLp(_pid);
        // 给用户计算收益, 并且领取;
        // 用户收益 = 用户质押量 * 池子股份 / 1e12 - 用户已领取数量
        uint256 pending = user.amount.mul(pool.accSushiPerShare).div(1e12).sub(user.rewardDebt);
        // 开始转账收益;
        TransferHelper.safeTransfer(sushi, msg.sender, pending);
        // 减少池子的总质押量
        pool.lpSupplyLp = pool.lpSupplyLp.sub(_amount);

        // 减去用户质押总金额
        user.amount = user.amount.sub(_amount);
        // 从新计算已经领取的金额;
        user.rewardDebt = user.amount.mul(pool.accSushiPerShare).div(1e12);
        // 转给用户本金
        TransferHelper.safeTransfer(sushi, msg.sender, _amount);
        // 触发提取事件
        emit WithdrawLp(msg.sender, _pid, _amount);
    }


}


// 交易挖矿; 用户在swap上进行兑换交易, 进行挖矿产出
contract MiningTransfer is MiningSet {
    /*
    此挖矿合约只针对有这个交易对的LP池子, 多个LP形成路径的池子的将不管

    1. 先在挖矿合约添加LP池子;
    2. 在swap合约里面交换的时候, 把LP地址传过来, 需要在挖矿合约里面判断这个LP池子是不是存在的, 存在再说, 不存在就不管;
    3. 所有的交易, 假设TokenA-TokenB的池子, 不管是A兑换B, 还是B兑换A, 都将以Token0进行统一计算, 也就是地址较小的那个,
       在swap合约里面, 把地址较小的对应的数量传入到挖矿合约里面, 作为挖矿的数量进行计算;
    4. 用户一旦领取收益, 那么本金就会消失, 总质押量也会减少;
    */


    // 用户的质押信息
    struct UserInfoTransfer {
        // 用户质押的数量
        uint256 amount;
        // 用户已领取的数量; 用于计算收益的, 不是用户真正领取走的数量
        uint256 rewardDebt;
        // 用户累积领取走的奖励
        uint256 rewardAccum;
        // 当前可以领取走的数量
        uint256 rewardCan;
    }
    // 质押池子的信息
    struct PoolInfoTransfer {
        // 池子的地址; 一定得是LP;
        IERC20 lpToken;
        // 池子收益的占比
        uint256 allocPoint;
        // 最后的区块; 用来计算每个阶段的股份收益
        uint256 lastRewardBlock;
        // 记录股份; 用来统计给个阶段的股份
        uint256 accSushiPerShare;
        // 池子质押的总量; 总的质押量, 无限累加, 不减少
        uint256 lpSupplyTransfer;
        // 池子当前的质押量; 减去了提取的金额
        uint256 lpSupplyNowTransfer;
        // 已被领取走的奖励; 这是收益的数量和质押量没啥关系
        uint256 totalReward;
    }
    // 所有的池子信息
    PoolInfoTransfer[] public poolInfoTransfer;
    // 池子id对应用户的质押信息
    mapping (uint256 => mapping (address => UserInfoTransfer)) public userInfoTransfer;
    // 是否已经存在; LpToken => bool; true=存在, false=不存在; 为了安全靠谱起见, 加上比较好;
    mapping(address => bool) public isPoolTransfer;
    // 交易池子的地址对应的pid; LpToken => pid
    mapping(address => uint256)  public isPoolTransferPid;
    // LP的总的占比例
    uint256 public totalAllocPointTransfer = 0;

    event DepositTransfer(address indexed user, uint256 indexed pid, uint256 amount);
    event WithdrawTransfer(address indexed user, uint256 indexed pid, uint256 amount);

    constructor() public {}

    // 池子必须是存在的
    modifier onlyIsPoolTransfer(uint256 _pid) {
        // 池子必须存在的
        require(isPoolTransfer[address(poolInfoTransfer[_pid].lpToken)], "add: pool not exist");
        _;
    }

    // 查询全部池子的长度
    function poolLengthTransfer() external view returns (uint256) {
        return poolInfoTransfer.length;
    }

    // 查询全部池子的信息
    function getPoolsTransfer() external view returns (PoolInfoTransfer[] memory _pools) {
        uint256 _length = poolInfoTransfer.length;
        _pools = new PoolInfoTransfer[](_length);
        for(uint256 i = 0; i < _length; i++) {
            _pools[i] = poolInfoTransfer[i];
        }
        return _pools;
    }

    // 添加一个池子
    // 参数1: 这个池子的占比
    // 参数2: 池子的地址
    function addTransfer(uint256 _allocPoint, IERC20 _lpToken) public onlyOwner {
        // 池子必须不存在的
        require(!isPoolTransfer[address(_lpToken)], "add: pool exist");
        // 池子设置成已经存在
        isPoolTransfer[address(_lpToken)] = true;
        // 池子地址对应的的pid
        isPoolTransferPid[address(_lpToken)] = poolInfoTransfer.length;

        // 最后的挖矿区块;
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        // 增加总的挖矿占比
        totalAllocPointTransfer = totalAllocPointTransfer.add(_allocPoint);
        // 增加一个池子
        poolInfoTransfer.push(PoolInfoTransfer({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accSushiPerShare: 0,
            lpSupplyTransfer: 0,
            lpSupplyNowTransfer: 0,
            totalReward: 0
            }));
    }

    // 修改池子的挖矿占比
    // 参数1: 池子的id; 也就是对应数组的索引, 从0开始;
    function setTransfer(uint256 _pid, uint256 _allocPoint) public onlyOwner onlyIsPoolTransfer(_pid) {
        // 重置该池子的信息
        updatePoolTransfer(_pid);
        // 修改信息
        totalAllocPointTransfer = totalAllocPointTransfer.sub(poolInfoTransfer[_pid].allocPoint).add(_allocPoint);
        poolInfoTransfer[_pid].allocPoint = _allocPoint;
    }

    // 循环遍历更新所有的池子信息; accSushiPerShare和lastRewardBlock;
    function massUpdatePoolsTransfer() public {
        uint256 length = poolInfoTransfer.length;
        for (uint256 pid = 0; pid < length; pid++) {
            updatePoolTransfer(pid);
        }
    }

    // 更新池子;
    function updatePoolTransfer(uint256 _pid) internal {
        PoolInfoTransfer storage pool = poolInfoTransfer[_pid];
        // 如果没有新的区块收益, 就不更新
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        // 如果本合约没有质押数量的话, 也不用更新池子信息
        uint256 lpSupply = pool.lpSupplyNowTransfer;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        // 计算挖矿的区块数量
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        // 计算出池子本次总挖矿收益;
        uint256 sushiReward = multiplier.mul(sushiPerBlockTransfer).mul(pool.allocPoint).div(totalAllocPointTransfer);
        // 计算股份, 从新赋值; 通过收益去计算股份
        pool.accSushiPerShare = pool.accSushiPerShare.add(sushiReward.mul(1e12).div(lpSupply));
        // 从新赋值最新的区块
        pool.lastRewardBlock = block.number;
    }

    // 计算用户当前可领取的收益数量(pending);
    // 参数1: 池子的pid
    // 参数2: 用户的地址
    function pendingSushiTransfer(uint256 _pid, address _user) public view returns (uint256) {
        // 获取池子的id的对应信息
        PoolInfoTransfer storage pool = poolInfoTransfer[_pid];
        // 查询池子对应用户的信息
        UserInfoTransfer storage user = userInfoTransfer[_pid][_user];
        // 获取池子的股份; 这个是memory变量, 不会修改到数据;
        uint256 accSushiPerShare = pool.accSushiPerShare;
        // 获取本合约的LP余额
        uint256 lpSupply = pool.lpSupplyNowTransfer;
        // 如果当前有了的新的挖矿区块, 并且质押量不等于0
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            // 计算挖矿的区块数量
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            // 计算出池子本次总挖矿收益;
            uint256 sushiReward = multiplier.mul(sushiPerBlockTransfer).mul(pool.allocPoint).div(totalAllocPointTransfer);
            // 计算股份; 通过收益去计算股份
            accSushiPerShare = accSushiPerShare.add(sushiReward.mul(1e12).div(lpSupply));
        }
        // 返回可领取收益
        return user.amount.mul(accSushiPerShare).div(1e12).add(user.rewardCan).sub(user.rewardDebt);
    }

    // 质押; 只质押, 不领取收益
    // 参数1: 用户的地址
    // 参数2: 池子的Lp地址
    // 参数3: 质押的数量
    function depositTransfer(address _user, address _lpToken, uint256 _amount) public {
        // 质押调用者必须是路由合约地址
        require(msg.sender == routerAddress, "not deposit");
        // 如果这个lp池子不存在, 就结束;
        if (!isPoolTransfer[_lpToken]) {
            return;
        }
        uint256 _pid = isPoolTransferPid[_lpToken];
        // 获取到池子的详情信息
        PoolInfoTransfer storage pool = poolInfoTransfer[_pid];
        // 查询此池子对应的用户的质押信息
        UserInfoTransfer storage user = userInfoTransfer[_pid][_user];
        // 更新池子id, 会更新accSushiPerShare和lastRewardBlock
        updatePoolTransfer(_pid);

        // 收益; 先计算用户当前的收益;
        uint256 pending = user.amount.mul(pool.accSushiPerShare).div(1e12).sub(user.rewardDebt);
        // 累加用户可以领取的收益
        user.rewardCan = user.rewardCan.add(pending);
        // 从新计算已经领取的金额
        user.rewardDebt = user.amount.mul(pool.accSushiPerShare).div(1e12);
        // 增加用户的质押总量
        user.amount = user.amount.add(_amount);
        // 质押; 增加质押总量;
        pool.lpSupplyTransfer = pool.lpSupplyTransfer.add(_amount);
        // 增加当前质押总量;
        pool.lpSupplyNowTransfer = pool.lpSupplyNowTransfer.add(_amount);

        // 触发事件
        emit DepositTransfer(msg.sender, _pid, _amount);
    }

    // 提取; 领取收益, 没有本金可领取
    // 参数1: 提取池子的id
    // 参数2: 提取的代币数量
    function withdrawTransfer(uint256 _pid) public onlyIsPoolTransfer(_pid) {
        // 获取到池子的详情信息
        PoolInfoTransfer storage pool = poolInfoTransfer[_pid];
        // 查询此池子对应的用户的质押信息
        UserInfoTransfer storage user = userInfoTransfer[_pid][msg.sender];
        // 更新池子, 会更新accSushiPerShare和lastRewardBlock
        updatePoolTransfer(_pid);

        // 给用户计算收益, 并且领取;
        // 用户收益 = 用户质押量 * 池子股份 / 1e12 - 用户已领取数量
        uint256 pending = user.amount.mul(pool.accSushiPerShare).div(1e12).sub(user.rewardDebt);
        // 累加用户可以领取的收益
        user.rewardCan = user.rewardCan.add(pending);
        // 从新计算已经领取的金额;
        user.rewardDebt = user.amount.mul(pool.accSushiPerShare).div(1e12);
        // 减少池子的总质押量
        pool.lpSupplyNowTransfer = pool.lpSupplyNowTransfer.sub(user.amount);
        // 增加池子的已被领取走的收益数量
        pool.totalReward = pool.totalReward.add(user.rewardCan);
        // 触发提取收益事件
        emit WithdrawTransfer(msg.sender, _pid, user.rewardCan);
        // 开始转账收益;
        TransferHelper.safeTransfer(sushi, msg.sender, user.rewardCan);
        // 减去用户质押总金额
        user.amount = 0;
        user.rewardCan = 0;
    }


}


// 董事会挖矿; 用户质押平台币到董事会, 进行挖矿产出
contract MiningBoard is MiningSet {
    // 用户的质押信息
    struct UserInfoBoard {
        // 用户质押的数量
        uint256 amount;
        // 用户已领取的数量; 用于计算收益的, 不是用户真正领取走的数量
        uint256 rewardDebt;
        // 用户当前可领取走的数量; 用于累加计算的
        uint256 rewardCan;
    }
    // 质押的总量
    uint256 public lpSupplyBoard;
    // 最后的区块; 用来计算每个阶段的股份收益
    uint256 lastRewardBlockBoard;
    // 记录股份; 用来统计给个阶段的股份
    uint256 accSushiPerShareBoard;
    // 董事会池子对应用户的质押信息
    mapping (address => UserInfoBoard) public userInfoBoard;
    // 上级; 用户=>上级
    mapping (address => address) public superAddress;
    // 上级和上上级费用比例; 百分比
    uint256[2] public superRatio = [20, 5];

    event DepositBoard(address indexed user, uint256 amount);
    event WithdrawBoard(address indexed user, uint256 amount, uint256 amountTax, uint256 reward, uint256 rewardTax, uint256 superReward, uint256 superSuperReward);

    constructor() public {}

    // 更新池子;
    function updatePoolBoard() public {
        // 如果没有新的区块收益, 就不更新
        if (block.number <= lastRewardBlockBoard) {
            return;
        }
        // 如果本合约没有质押数量的话, 也不用更新池子信息
        if (lpSupplyBoard == 0) {
            lastRewardBlockBoard = block.number;
            return;
        }

        // 计算挖矿的区块数量
        uint256 multiplier = getMultiplier(lastRewardBlockBoard, block.number);
        // 计算出池子本次总挖矿收益;
        uint256 sushiReward = multiplier.mul(sushiPerBlockBoard);
        // 计算股份, 从新赋值; 通过收益去计算股份
        accSushiPerShareBoard = accSushiPerShareBoard.add(sushiReward.mul(1e12).div(lpSupplyBoard));
        // 从新赋值最新的区块
        lastRewardBlockBoard = block.number;
    }
    // 董事会税收的更新池子
    function updatePoolBoard2(uint256 _sushiReward) private {
        // 增计算收益增加的每股,
        accSushiPerShareBoard = accSushiPerShareBoard.add(_sushiReward.mul(1e12).div(lpSupplyBoard));
    }

    // 计算用户当前可领取的收益数量(pending); 不包括税收
    // 参数1: 池子的pid
    // 参数2: 用户的地址
    function pendingSushiBoard(address _user) public view returns (uint256) {
        // 查询池子对应用户的信息
        UserInfoBoard storage user = userInfoBoard[_user];
        // 获取池子的股份; 这个是memory变量, 不会修改到数据;
        uint256 accSushiPerShare = accSushiPerShareBoard;
        // 如果当前有了的新的挖矿区块, 并且质押量不等于0
        if (block.number > lastRewardBlockBoard && lpSupplyBoard != 0) {
            // 计算挖矿的区块数量
            uint256 multiplier = getMultiplier(lastRewardBlockBoard, block.number);
            // 计算出池子本次总挖矿收益;
            uint256 sushiReward = multiplier.mul(sushiPerBlockBoard);
            // 计算股份; 通过收益去计算股份
            accSushiPerShare = accSushiPerShare.add(sushiReward.mul(1e12).div(lpSupplyBoard));
        }
        // 返回可领取收益
        return user.amount.mul(accSushiPerShare).div(1e12).sub(user.rewardDebt).add(user.rewardCan);
    }

    // 质押;
    // 参数1: 质押的数量
    function depositBoard(uint256 _amount) public {
        // 查询此池子对应的用户的质押信息
        UserInfoBoard storage user = userInfoBoard[msg.sender];
        // 更新池子, 会更新accSushiPerShare和lastRewardBlock
        updatePoolBoard();

        // 收益; 先计算用户当前的收益;
        uint256 pending = user.amount.mul(accSushiPerShareBoard).div(1e12).sub(user.rewardDebt);
        // 累加用户可以领取的收益
        user.rewardCan = user.rewardCan.add(pending);
        // 从新计算已经领取的金额
        user.rewardDebt = user.amount.mul(accSushiPerShareBoard).div(1e12);
        // 增加用户的质押总量
        user.amount = user.amount.add(_amount);
        // 质押; 不管是不是0, 也是可以正常交易的;
        // 把币转入到合约, 增加质押总量;
        TransferHelper.safeTransferFrom(sushi, address(msg.sender), address(this), _amount);
        lpSupplyBoard = lpSupplyBoard.add(_amount);
        // 触发事件
        emit DepositBoard(msg.sender, _amount);
    }

    // 提取; 提取本金+提取收益, 直接提取全部;
    function withdrawBoard() public {
        // 查询此池子对应的用户的质押信息
        UserInfoBoard storage user = userInfoBoard[msg.sender];
        // 更新池子, 会更新accSushiPerShare和lastRewardBlock
        updatePoolBoard();

        // 给用户计算收益, 并且领取;
        // 用户收益 = 用户质押量 * 池子股份 / 1e12 - 用户已领取数量
        uint256 pending = user.amount.mul(accSushiPerShareBoard).div(1e12).sub(user.rewardDebt);
        // 累加用户可以领取的收益
        user.rewardCan = user.rewardCan.add(pending);
        // 从新计算已经领取的金额;
        user.rewardDebt = user.amount.mul(accSushiPerShareBoard).div(1e12);
        // 全部可以领取的收益, 可以领取的金额
        uint256 _amount = user.amount;
        uint256 _rewardCan = user.rewardCan;
        // 重置用户质押金额和可领取的收益
        user.amount = 0;
        user.rewardCan = 0;
        // 减少总质押量
        lpSupplyBoard = lpSupplyBoard.sub(_amount);

        // 计算税收比例
        uint256 _tax = tax();
        // 领取本金; 本金根据税收比例分给其它董事会质押者; 金额为0也没有关系, 正常交易;
        // 本金税收 = 用户提取本金的数量 * 税收比例;
        uint256 _amountTax = _amount.mul(_tax).div(100);
        // 把剩余的本金转给用户; 金额为本金减去税收;
        TransferHelper.safeTransfer(sushi, address(msg.sender), _amount.sub(_amountTax));
        // 收益; 按比例给到董事会其它成员, 并且收益还要按上级费用给到上级或上上级
        uint256 _rewardTax = _rewardCan.mul(_tax).div(100);
        address _superAddress = superAddress[msg.sender];  // 上级地址
        address _superSuperAddress = superAddress[_superAddress]; // 上上级地址
        uint256 _superAmount = _rewardCan.mul(superRatio[0]);  // 上级收益
        uint256 _superSuperAmount = _rewardCan.mul(superRatio[1]);  // 上上级收益
        TransferHelper.safeTransfer(sushi, _superAddress, _superAmount);  // 转给上级
        TransferHelper.safeTransfer(sushi, _superSuperAddress, _superSuperAmount);  // 转给上上级
        uint256 _userAmount = _rewardCan.sub(_rewardTax).sub(_superAmount).sub(_superSuperAmount); // 自己的收益
        TransferHelper.safeTransfer(sushi, address(msg.sender), _userAmount);  // 转给自己

        updatePoolBoard2(_amountTax.add(_rewardTax)); // 本金税收+收益税收 给到合约的其它董事会质押者;
        // 触发提取事件; 用户地址, 用户领取本金数量, 税收本金数量, 用户收益数量, 税收收益数量, 上级收益数量, 上上级收益数量;
        emit WithdrawBoard(msg.sender, _amount.sub(_amountTax), _amountTax, _userAmount, _rewardTax, _superAmount, _superSuperAmount);
    }

    // 计算税收; 返回百分比, 返回的结果计算的需要除以100;
    function tax() public view returns (uint256) {
        // 计算平台币:USDT的比例; 价格是1e10后的数;
        uint256 _price = getPrice();
        // 计算当前的TVL; 当前质押量 * 价格U / 1e10;
        uint256 _tvl = lpSupplyBoard.mul(_price).div(1e10);
        // 根据区间去计算税收; 5e23=50万
        uint256[6] memory _tvlArr = [uint256(5e23), 2e24, 5e24, 1e25, 2e25, 5e25];
        uint256[7] memory _taxArr = [uint256(50), 45, 40, 35, 30, 25, 20];
        for(uint256 i; i < _tvlArr.length; i++) {
            if (_tvl <= _tvlArr[i]) {
                return _taxArr[i];
            }
        }
        return _taxArr[6];
    }

    // 设置上级
    function setSuper(address _super) external {
        // 不能是合约地址
        require(_super != address(this), "super: contract");
        // 如果没有上级就可以设置上级
        if (superAddress[msg.sender] == address(0)) {
            // 考虑闭环问题; 如果这个地址的上1级-10级有的我话, 那么它将不能成为的上级;
            address _s = superAddress[_super];
            for(uint256 i; i < 10; i++) {
                require(_s != msg.sender, "super: closed loop");
                _s = superAddress[_s];
            }
            // 否则就可以设置成上级
            superAddress[msg.sender] = _super;
        }
    }

    // 设置上级和上上级费用比例
    // 参数1: 上级比例
    // 参数2: 上上级比例
    function setSuperRatio(uint256 _superRatio, uint256 _superSuperRatio) external onlyOwner {
        superRatio[0] = _superRatio;
        superRatio[1] = _superSuperRatio;
    }


}


// 主合约
contract Mining is MiningLp, MiningTransfer, MiningBoard {

    // 参数1: 收益币的地址; 也是平台币, 也是质押董事会的币;
    // 参数2: 每个区块的产币数量
    // 参数3: usdt地址
    // 参数4: 路由合约地址
    constructor(address _sushi, uint256 _sushiPerBlock, address _usdt, address _routerAddress) public
    MiningSet(_sushi, _sushiPerBlock, _usdt, _routerAddress) {
        everyPool();
    }

    // 修改每个区块的挖矿数量; 考虑gas费溢出的问题;
    function setSushiPerBlock(uint256 _sushiPerBlock) external onlyOwner {
        // 循环重置LP池子的信息
        massUpdatePoolsLp();
        // 循环重置交易池子的信息
        massUpdatePoolsTransfer();
        // 重置董事池子的信息
        updatePoolBoard();
        // 从新赋值
        sushiPerBlock = _sushiPerBlock;
        // 根据当前占比对计算每种类型的产币数量
        everyPool();
    }

    // 设置三个大池子的占比
    function setMining3(uint256 _miningLP, uint256 _miningTransfer, uint256 _miningBoard) external onlyOwner {
        // 三个加起来必须是100
        uint256 _all = _miningLP.add(_miningTransfer).add(_miningBoard);
        require(_all == 100, "ratio not");
        // 如果比例一样就不更改, 比例不一样就更改;
        if(mining3[0] != _miningLP) {
            massUpdatePoolsLp();
            mining3[0] = _miningLP;
        }
        if(mining3[1] != _miningTransfer) {
            massUpdatePoolsTransfer();
            mining3[1] = _miningTransfer;

        }
        if(mining3[2] != _miningBoard) {
            updatePoolBoard();
            mining3[2] = _miningBoard;
        }
        everyPool();
    }

    // 重置各个池子的区块产出
    function everyPool() private {
        sushiPerBlockLp = sushiPerBlock.mul(mining3[0]).div(100);
        sushiPerBlockTransfer = sushiPerBlock.mul(mining3[1]).div(100);
        sushiPerBlockBoard = sushiPerBlock.mul(mining3[2]).div(100);
    }

    // 设置USDT-平台币的配对合约地址
    function setPairUsdtSushi(address _pairUsdtSushi) external onlyOwner {
        pairUsdtSushi = _pairUsdtSushi;
    }

    // 设置路由合约的地址; 地址为0将不会进行交易挖矿
    function setRouterAddress(address _routerAddress) external onlyOwner {
        routerAddress = _routerAddress;
    }

}