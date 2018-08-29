pragma solidity ^0.4.8;


library BobbySafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
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


contract BobbyERC20Base {

    address public ceoAddress;
    address public cfoAddress;

    //是否暂停智能合约的运行
    bool public paused = false;

    constructor(address cfoAddr) public {
        ceoAddress = msg.sender;
        cfoAddress = cfoAddr;
    }

    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused {
        require(paused);
        _;
    }

    function pause() external onlyCEO whenNotPaused {
        paused = true;
    }

    function unpause() public onlyCEO whenPaused {
        paused = false;
    }
}

contract ERC20Interface {

    //ERC20指定接口
    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);

    //extend event
    event Grant(address indexed src, address indexed dst, uint wad);    //发放代币，有解禁期
    event Unlock(address indexed user, uint wad);                       //解禁代币

    function name() public view returns (string n);
    function symbol() public view returns (string s);
    function decimals() public view returns (uint8 d);
    function totalSupply() public view returns (uint256 t);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
}

//Erc智能合约
contract ERC20 is ERC20Interface, BobbyERC20Base {
    using BobbySafeMath for uint256;

    uint private _Thousand = 1000;
    uint private _Billion = _Thousand * _Thousand * _Thousand;

    //代币基本信息
    string private _name = "BOBBY";     //代币名称
    string private _symbol = "BOBBY";   //代币标识
    uint8 private _decimals = 9;        //小数点后位数
    uint256 private _totalSupply = 10 * _Billion * (10 ** uint256(_decimals));

    struct LockedToken {
        uint256 total;          // 数量
        uint256 duration;       // 解锁总时长
        uint256 periods;        // 解锁期数

        uint256 balance;         // 剩余未解锁数量
        uint256 unlockLast;      // 上次解锁时间
    }

    //解封用户代币结构
    struct UserToken {
        uint index;                     //放在数组中的下标
        address addr;                   //用户账号
        uint256 tokens;                 //通证数量
        LockedToken[] lockedTokens;     //锁定的token
    }

    mapping(address=>UserToken) private _userMap;           //用户映射
    address[] private _userArray;                           //用户数组,from 1

    uint32 private actionTransfer = 0;
    uint32 private actionGrant = 1;
    uint32 private actionUnlock = 2;

    struct LogEntry {
        uint256 time;
        uint32  action;       // 0 转账 1 发放 2 解锁
        address from;
        address to;
        uint256 v1;
        uint256 v2;
        uint256 v3;
    }

    LogEntry[] private _logs;

    function _addUser(address addrUser) private returns (UserToken storage) {
        _userMap[addrUser].index = _userArray.length;
        _userMap[addrUser].addr = addrUser;
        _userMap[addrUser].tokens = 0;
        _userArray.push(addrUser);
        return _userMap[addrUser];
    }

    //构造方法，将代币的初始总供给都分配给合约的部署账户。合约的构造方法只在合约部署时执行一次
    constructor(address cfoAddr) BobbyERC20Base(cfoAddr) public {

        //placeholder
        _userArray.push(address(0));

        UserToken storage userCFO = _addUser(cfoAddr);
        userCFO.tokens = _totalSupply;
    }

    //返回合约名称。view关键子表示函数只查询状态变量，而不写入
    function name() public view returns (string n){
        n = _name;
    }

    //返回合约标识符
    function symbol() public view returns (string s){
        s = _symbol;
    }

    //返回合约小数位
    function decimals() public view returns (uint8 d){
        d = _decimals;
    }

    //返回合约总供给额
    function totalSupply() public view returns (uint256 t){
        t = _totalSupply;
    }

    //查询账户_owner的账户余额
    function balanceOf(address _owner) public view returns (uint256 balance){
        UserToken storage user = _userMap[_owner];
        if (0 == user.index) {
            balance = 0;
            return;
        }

        balance = user.tokens;
        for (uint index = 0; index < user.lockedTokens.length; index++) {
            balance = balance.add((user.lockedTokens[index]).balance);
        }
    }

    function _checkUnlock(address addrUser) private {
        UserToken storage user = _userMap[addrUser];
        if (0 == user.index) {
            return;
        }

        for (uint index = 0; index < user.lockedTokens.length; index++) {
            LockedToken storage locked = user.lockedTokens[index];
            if(locked.balance <= 0){
                continue;
            }

            uint256 diff = now.sub(locked.unlockLast);
            uint256 unlockUnit = locked.total.div(locked.periods);
            uint256 periodDuration = locked.duration.div(locked.periods);
            uint256 unlockedPeriods = locked.total.sub(locked.balance).div(unlockUnit);
            uint256 periodsToUnlock = diff.div(periodDuration);

            if(periodsToUnlock > 0) {
                uint256 tokenToUnlock = 0;
                if(unlockedPeriods + periodsToUnlock >= locked.periods) {
                    tokenToUnlock = locked.balance;
                }else{
                    tokenToUnlock = unlockUnit.mul(periodsToUnlock);
                }

                if (tokenToUnlock >= locked.balance) {
                    tokenToUnlock = locked.balance;
                }

                locked.balance = locked.balance.sub(tokenToUnlock);
                user.tokens = user.tokens.add(tokenToUnlock);
                locked.unlockLast = locked.unlockLast.add(periodDuration.mul(periodsToUnlock));

                emit Unlock(addrUser, tokenToUnlock);
                log(actionUnlock, addrUser, 0, tokenToUnlock, 0, 0);
            }
        }
    }   

    //从代币合约的调用者地址上转移_value的数量token到的地址_to，并且必须触发Transfer事件
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool success){
        require(msg.sender != _to);

        //检查是否有可以解锁的token
        _checkUnlock(msg.sender);

        require(_userMap[msg.sender].tokens >= _value);
        _userMap[msg.sender].tokens = _userMap[msg.sender].tokens.sub(_value);

        UserToken storage userTo = _userMap[_to];
        if(0 == userTo.index){
            userTo = _addUser(_to);
        }
        userTo.tokens = userTo.tokens.add(_value);

        emit Transfer(msg.sender, _to, _value);
        log(actionTransfer, msg.sender, _to, _value, 0, 0);

        success = true;
    }

    function transferFrom(address, address, uint256) public whenNotPaused returns (bool success){
        success = true;
    }

    function approve(address, uint256) public whenNotPaused returns (bool success){
        success = true;
    }

    function allowance(address, address) public view returns (uint256 remaining){
        remaining = 0;
    }

    function grant(address _to, uint256 _value, uint256 _duration, uint256 _periods) public whenNotPaused returns (bool success){
        require(msg.sender != _to);

        //检查是否有可以解锁的token
        _checkUnlock(msg.sender);

        require(_userMap[msg.sender].tokens >= _value);
        _userMap[msg.sender].tokens = _userMap[msg.sender].tokens.sub(_value);
        
        UserToken storage userTo = _userMap[_to];
        if(0 == userTo.index){
            userTo = _addUser(_to);
        }

        LockedToken memory locked;
        locked.total = _value;
        locked.duration = _duration.mul(30 days);
        // locked.duration = _duration.mul(1 minutes); //for test
        locked.periods = _periods;
        locked.balance = _value;
        locked.unlockLast = now;
        userTo.lockedTokens.push(locked);

        emit Grant(msg.sender, _to, _value);
        log(actionGrant, msg.sender, _to, _value, _duration, _periods);

        success = true;
    }

    function getUserAddr(uint256 _index) public view returns(address addr){
        require(_index < _userArray.length);
        addr = _userArray[_index];
    }

    function getUserSize() public view returns(uint256 size){
        size = _userArray.length;
    }


    function getLockSize(address addr) public view returns (uint256 len) {
        UserToken storage user = _userMap[addr];
        len = user.lockedTokens.length;
    }

    function getLock(address addr, uint256 index) public view returns (uint256 total, uint256 duration, uint256 periods, uint256 balance, uint256 unlockLast) {
        UserToken storage user = _userMap[addr];
        require(index < user.lockedTokens.length);
        total = user.lockedTokens[index].total;
        duration = user.lockedTokens[index].duration;
        periods = user.lockedTokens[index].periods;
        balance = user.lockedTokens[index].balance;
        unlockLast = user.lockedTokens[index].unlockLast;
    }

    function getLockInfo(address addr) public view returns (uint256[] totals, uint256[] durations, uint256[] periodses, uint256[] balances, uint256[] unlockLasts) {
        UserToken storage user = _userMap[addr];
        uint256 len = user.lockedTokens.length;
        totals = new uint256[](len);
        durations = new uint256[](len);
        periodses = new uint256[](len);
        balances = new uint256[](len);
        unlockLasts = new uint256[](len);
        for (uint index = 0; index < user.lockedTokens.length; index++) {
            totals[index] = user.lockedTokens[index].total;
            durations[index] = user.lockedTokens[index].duration;
            periodses[index] = user.lockedTokens[index].periods;
            balances[index] = user.lockedTokens[index].balance;
            unlockLasts[index] = user.lockedTokens[index].unlockLast;
        }
    }

    function log(uint32 action, address from, address to, uint256 _v1, uint256 _v2, uint256 _v3) private {
        LogEntry memory entry;
        entry.action = action;
        entry.time = now;
        entry.from = from;
        entry.to = to;
        entry.v1 = _v1;
        entry.v2 = _v2;
        entry.v3 = _v3;
        _logs.push(entry);
    }

    function getLogSize() public view returns(uint256 size){
        size = _logs.length;
    }

    function getLog(uint256 _index) public view returns(uint time, uint32 action, address from, address to, uint256 _v1, uint256 _v2, uint256 _v3){
        require(_index < _logs.length);
        require(_index >= 0);
        LogEntry storage entry = _logs[_index];
        action = entry.action;
        time = entry.time;
        from = entry.from;
        to = entry.to;
        _v1 = entry.v1;
        _v2 = entry.v2;
        _v3 = entry.v3;
    }
}