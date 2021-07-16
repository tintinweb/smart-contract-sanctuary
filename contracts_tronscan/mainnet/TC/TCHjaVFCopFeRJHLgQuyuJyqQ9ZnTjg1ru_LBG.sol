//SourceUnit: BlgLockInitNoAddr.sol

pragma solidity ^0.4.25;

contract TRC20Basic {
    function totalSupply() public view returns (uint256);  // totalSupply - 总发行量
    function balanceOf(address who) public view returns (uint256);  // 余额
    function transfer(address to, uint256 value) public returns (bool);  // 交易
    event Transfer(address indexed from, address indexed to, uint256 value);  // 交易事件
}

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20 is TRC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);  // 获取被授权令牌余额,获取 _owner 地址授权给 _spender 地址可以转移的令牌的余额
    function transferFrom(address from, address to, uint256 value) public returns (bool);  // A账户-》B账户的转账
    function approve(address spender, uint256 value) public returns (bool);  // 授权，允许 _spender 地址从你的账户中转移 _value 个令牌到任何地方
    event Approval(address indexed owner, address indexed spender, uint256 value);  // 授权事件
}

contract BasicToken is TRC20Basic {
    using SafeMath for uint256;
    mapping(address => uint256) balances; // 余额
    uint256 totalSupply_;  // 发行总量

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));  // 无效地址
        require(_value <= balances[msg.sender]);  // 转账账户余额大于转账数目

        balances[msg.sender] = balances[msg.sender].sub(_value);  // 转账账户余额=账户余额-转账金额
        balances[_to] = balances[_to].add(_value); // 接收账户的余额=原先账户余额+账金额
        emit Transfer(msg.sender, _to, _value);  // 转账事件
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];  // 查询合约调用者的余额
    }
}

/**
* functions, this simplifies the implementation of "user permissions".  为了对代币进行管理，首先需要给合约添加一个管理者
*/
contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @param newOwner The address to transfer ownership to.  指派一个新的管理员
    */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract StandardToken is ERC20, BasicToken, Ownable {
    mapping (address => mapping (address => uint256)) internal allowed;
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0)); // 到达B账户的地址不能为无效地址
        require(_value <= balances[_from]);  // 转账账户余额大于转账金额
        require(_value <= allowed[_from][msg.sender]);  // 允许 _from 地址转账给 _to地址

        balances[_from] = balances[_from].sub(_value); 
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);  // 允许转账的余额
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
    * 增加允许支付的最大额度
    */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
    * 减少允许支付的最大额度
    */
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
          allowed[msg.sender][_spender] = 0;
        } else {
          allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }

        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
}

/**
* `StandardToken` functions.  初始化合约，并且把初始的所有代币都给这合约的创建者
*/
contract LBG is StandardToken {
    using SafeMath for uint256;
    string public constant name = "LBG Token"; // solium-disable-line uppercase
    string public constant symbol = "LBG"; // solium-disable-line uppercase
    uint8 public constant decimals = 6; // solium-disable-line uppercase
    uint256 public constant INITIAL_SUPPLY = 5 * (10 ** 8) * (10 ** uint256(decimals));

    uint256 public lastTokenFreeTime = 0; // 记录币最后释放时间
    uint256 public initTokenFreeNum = 541096; // 初始释放数量

    /**
    * @ dev 创建四个账户地址，将解锁后的余额预分配到三个地址
    */
    // TYjgDYKa1vB7vqTSwBT5XpjadQrgXwpc9d
    address public freeReserveWallet = 0x00F9BBC9A4BBD11F1C34B97EC39A6C063E8FDA3F23; // 自由释放池

    // TRNwr733SYD2w7PXmtkLSHVmYB8JFit2jT
    address public projectReserveWallet = 0x00A9073837A39F718F10D51F6F2F8CF5239FFAF9B4; // 项目方锁仓
    // TRdHTW23pPcvr15rYi895VxoCoXuyr1F5E; // 技术锁仓
    address public tecReserveWallet = 0x00ABBD69B3EBF149E69832DD24C58795C4123818BE; // 技术锁仓
    // TMhRGaYY3JUZDnHB7umLgyHcoyfeDhfaTn;// 社区锁仓
    address public communityReserveWallet = 0x0080A518301E38DD734A06346DE1B0026B8A974C8E;// 社区锁仓
    // 直接流通仓 
    address public canUseReserveWallet = 0x00294AEC9C0C069B9AB021472BDDDEAC9F4D438C1F;// 直接流通仓
    
    /** 三个账户地址对应的锁仓金额 */
    uint256 public freeReserveAllocation = 3.95 * (10 ** 8) * (10 ** uint256(decimals)); // 5000万
    uint256 public projectReserveAllocation = 5 * (10 ** 7) * (10 ** uint256(decimals)); // 5000万
    uint256 public tecReserveAllocation = 1 * (10 ** 7) * (10 ** uint256(decimals)); // 1000万
    uint256 public communityReserveAllocation = 15 * (10 ** 6) * (10 ** uint256(decimals)); // 1500万
    uint256 public canUseReserveAllocation = 3 * (10 ** 7) * (10 ** uint256(decimals)); // 3000万

    // 总锁仓的金额 - 5 亿
    uint256 public totalAllocation = 5 * (10 ** 8) * (10 ** uint256(decimals));

    /** 地址对应的锁仓时间 */
    uint256 public freeTimeLock = 100 * 365 days;
    uint256 public projectTimeLock = 2 * 365 days;
    uint256 public tecReserveTimeLock = 2 * 365 days;
    uint256 public communityReserveTimeLock = 2 * 365 days;
    uint256 public canUseReserveTimeLock = 6 * 3600 seconds;
    uint256 public years_seconds = 1 * 365 days; // 每年的时间差 - s

    /** Reserve allocations */
    mapping(address => uint256) public allocations;  // 每个地址对应锁仓金额的映射表
    /** When timeLocks are over (UNIX Timestamp)  */ 
    mapping(address => uint256) public timeLocks;  // 每个地址对应锁仓时间的映射表
    /** How many tokens each reserve wallet has claimed */
    mapping(address => uint256) public claimed;  // 每个地址对应锁仓后已经解锁的金额的映射表

    /** When this vault was locked (UNIX Timestamp)*/
    uint256 public lockedAt = 0;
    // LibraToken public token;

    /** Allocated reserve tokens */
    event Allocated(address wallet, uint256 value);
    /** Distributed reserved tokens */
    event Distributed(address wallet, uint256 value);
    /** Tokens have been locked */
    event Locked(uint256 lockTime);

    //Any of the three reserve wallets
    modifier onlyReserveWallets {  // 合约调用者的锁仓余额大于 0 才能查询锁仓余额
        require(allocations[msg.sender] > 0);
        _;
    }

    //Only Libra team reserve wallet
    modifier onlyFreeReserve {  // 合约调用者的地址为 freeReserveWallet
        require(msg.sender == freeReserveWallet);
        require(allocations[msg.sender] > 0);
        _;
    }

    //Only first and second token reserve wallets
    modifier onlyTokenReserve { // 合约调用者的地址为 projectReserveWallet 或者 tecReserveWallet or communityReserveWallet canUseReserveWallet
        require(msg.sender == projectReserveWallet || msg.sender == tecReserveWallet || msg.sender == communityReserveWallet || msg.sender == canUseReserveWallet);
        require(allocations[msg.sender] > 0);
        _;
    }

    //Has not been locked yet
    modifier notLocked {  // 未锁定
        require(lockedAt == 0);
        _;
    }

    modifier locked { // 锁定
        require(lockedAt > 0);
        _;
    }

    //Token allocations have not been set
    modifier notAllocated {  // 没有为每个地址分配对应的锁仓金额时
        require(allocations[freeReserveWallet] == 0);
        require(allocations[projectReserveWallet] == 0);
        require(allocations[tecReserveWallet] == 0);
        require(allocations[communityReserveWallet] == 0);
        require(allocations[canUseReserveWallet] == 0);
        _;
    }

    function allocate() public notLocked notAllocated onlyOwner { 
        //Makes sure Token Contract has the exact number of tokens
        require(address(this).balance == totalAllocation); 

        allocations[freeReserveWallet] = freeReserveAllocation;
        allocations[projectReserveWallet] = projectReserveAllocation;
        allocations[tecReserveWallet] = tecReserveAllocation;
        allocations[communityReserveWallet] = communityReserveAllocation;
        allocations[canUseReserveWallet] = canUseReserveAllocation;

        emit Allocated(freeReserveWallet, freeReserveAllocation);
        emit Allocated(projectReserveWallet, projectReserveAllocation);
        emit Allocated(tecReserveWallet, tecReserveAllocation);
        emit Allocated(communityReserveWallet, communityReserveAllocation);
        emit Allocated(canUseReserveWallet, canUseReserveAllocation);
        lock();
    }

    function lock() internal notLocked onlyOwner {
        lockedAt = block.timestamp; // 区块当前时间
        timeLocks[freeReserveWallet] = lockedAt.add(freeTimeLock);
        timeLocks[projectReserveWallet] = lockedAt.add(projectTimeLock);
        timeLocks[tecReserveWallet] = lockedAt.add(tecReserveTimeLock);
        timeLocks[communityReserveWallet] = lockedAt.add(communityReserveTimeLock);
        timeLocks[canUseReserveWallet] = lockedAt.add(canUseReserveTimeLock);
        emit Locked(lockedAt);
    }

    function recoverFailedLock() external notLocked notAllocated onlyOwner {
        // Transfer all tokens on this contract back to the owner
        require(transfer(owner, balanceOf(address(this))));
    }

    // Total number of tokens currently in the vault
    // 查询当前合约所持有的金额
    function getTotalBalance() public view returns (uint256 tokensCurrentlyInVault) {
        return balanceOf(address(this));
    }

    // Number of tokens that are still locked
    function getLockedBalance() public view onlyReserveWallets returns (uint256 tokensLocked) {
        return allocations[msg.sender].sub(claimed[msg.sender]); 
    }

    // Claim tokens for project tec community reserve wallets
    function claimTokenReserve() onlyTokenReserve locked public {
        address reserveWallet = msg.sender;
        // Can't claim before Lock ends
        require(block.timestamp > timeLocks[reserveWallet]); 
        // Must Only claim once
        require(claimed[reserveWallet] == 0);  
        uint256 amount = allocations[reserveWallet];
        claimed[reserveWallet] = amount;  // 一次性解锁发放
        require(transfer(reserveWallet, amount));
        emit Distributed(reserveWallet, amount);
    }

    // Claim tokens for Libra free reserve wallet
    function claimFreeReserve() onlyFreeReserve locked public {
        uint256 time_difference = block.timestamp.sub(lastTokenFreeTime);
        require(time_difference >= 86400); // 必须大于 24 小时才能再次释放，防止恶意释放
        uint256 today_count = getTodayFreeCount();
        require(today_count <= allocations[freeReserveWallet]);

        claimed[freeReserveWallet] = claimed[freeReserveWallet].add(today_count);
        require(transfer(freeReserveWallet, today_count)); 
        emit Distributed(freeReserveWallet, today_count);

        // 修改最后释放币的时间
        lastTokenFreeTime = block.timestamp;
    }

    // 获取当天可释放的量
    function getTodayFreeCount() public view onlyFreeReserve returns(uint256){
        uint256 time_difference_new = block.timestamp.sub(lockedAt);
        uint256 years_count = time_difference_new.div(years_seconds);
        
        return initTokenFreeNum.div(2 ** years_count);
    }

    // function LibraToken() public {
    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        owner = msg.sender;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);

        allocations[freeReserveWallet] = freeReserveAllocation;
        allocations[projectReserveWallet] = projectReserveAllocation;
        allocations[tecReserveWallet] = tecReserveAllocation;
        allocations[communityReserveWallet] = communityReserveAllocation;
        allocations[canUseReserveWallet] = canUseReserveAllocation;

        emit Allocated(freeReserveWallet, freeReserveAllocation);
        emit Allocated(projectReserveWallet, projectReserveAllocation);
        emit Allocated(tecReserveWallet, tecReserveAllocation);
        emit Allocated(communityReserveWallet, communityReserveAllocation);
        emit Allocated(canUseReserveWallet, canUseReserveAllocation);
        
        lockedAt = block.timestamp; // 区块当前时间
        timeLocks[freeReserveWallet] = lockedAt.add(freeTimeLock);
        timeLocks[projectReserveWallet] = lockedAt.add(projectTimeLock);
        timeLocks[tecReserveWallet] = lockedAt.add(tecReserveTimeLock);
        timeLocks[communityReserveWallet] = lockedAt.add(communityReserveTimeLock);
        timeLocks[canUseReserveWallet] = lockedAt.add(canUseReserveTimeLock);
        emit Locked(lockedAt);
    }
}