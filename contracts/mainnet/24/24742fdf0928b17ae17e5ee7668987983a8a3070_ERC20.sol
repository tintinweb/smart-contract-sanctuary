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

    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    modifier allButCFO() {
        require(msg.sender != cfoAddress);
        _;
    }

    function setCFO(address _newCFO) public onlyCEO {
        require(_newCFO != address(0));
        cfoAddress = _newCFO;
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

    //解封用户代币结构
    struct UserToken {
        uint index;              //放在数组中的下标
        address addr;            //用户账号
        uint256 tokens;          //通证数量

        uint256 unlockUnit;     // 每次解锁数量
        uint256 unlockPeriod;   // 解锁时间间隔
        uint256 unlockLeft;     // 未解锁通证数量
        uint256 unlockLastTime; // 上次解锁时间
    }

    mapping(address=>UserToken) private _balancesMap;           //用户可用代币映射
    address[] private _balancesArray;                           //用户可用代币数组,from 1

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

    //构造方法，将代币的初始总供给都分配给合约的部署账户。合约的构造方法只在合约部署时执行一次
    constructor(address cfoAddr) BobbyERC20Base(cfoAddr) public {

        //placeholder
        _balancesArray.push(address(0));

        //此处需要注意，请使用CEO的地址,因为初始化后，将会使用这个地址作为CEO地址
        //注意，一定要使用memory类型，否则，后面的赋值会影响其它成员变量
        UserToken memory userCFO;
        userCFO.index = _balancesArray.length;
        userCFO.addr = cfoAddr;
        userCFO.tokens = _totalSupply;
        userCFO.unlockUnit = 0;
        userCFO.unlockPeriod = 0;
        userCFO.unlockLeft = 0;
        userCFO.unlockLastTime = 0;
        _balancesArray.push(cfoAddr);
        _balancesMap[cfoAddr] = userCFO;
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
        UserToken storage user = _balancesMap[_owner];
        balance = user.tokens.add(user.unlockLeft);
    }

    //从代币合约的调用者地址上转移_value的数量token到的地址_to，并且必须触发Transfer事件
    function transfer(address _to, uint256 _value) public returns (bool success){
        require(!paused);
        require(msg.sender != cfoAddress);
        require(msg.sender != _to);

        //先判断是否有可以解禁
        if(_balancesMap[msg.sender].unlockLeft > 0){
            UserToken storage sender = _balancesMap[msg.sender];
            uint256 diff = now.sub(sender.unlockLastTime);
            uint256 round = diff.div(sender.unlockPeriod);
            if(round > 0) {
                uint256 unlocked = sender.unlockUnit.mul(round);
                if (unlocked > sender.unlockLeft) {
                    unlocked = sender.unlockLeft;
                }

                sender.unlockLeft = sender.unlockLeft.sub(unlocked);
                sender.tokens = sender.tokens.add(unlocked);
                sender.unlockLastTime = sender.unlockLastTime.add(sender.unlockPeriod.mul(round));

                emit Unlock(msg.sender, unlocked);
                log(actionUnlock, msg.sender, 0, unlocked, 0, 0);
            }
        }

        require(_balancesMap[msg.sender].tokens >= _value);
        _balancesMap[msg.sender].tokens = _balancesMap[msg.sender].tokens.sub(_value);

        uint index = _balancesMap[_to].index;
        if(index == 0){
            UserToken memory user;
            user.index = _balancesArray.length;
            user.addr = _to;
            user.tokens = _value;
            user.unlockUnit = 0;
            user.unlockPeriod = 0;
            user.unlockLeft = 0;
            user.unlockLastTime = 0;
            _balancesMap[_to] = user;
            _balancesArray.push(_to);
        }
        else{
            _balancesMap[_to].tokens = _balancesMap[_to].tokens.add(_value);
        }

        emit Transfer(msg.sender, _to, _value);
        log(actionTransfer, msg.sender, _to, _value, 0, 0);
        success = true;
    }

    function transferFrom(address, address, uint256) public returns (bool success){
        require(!paused);
        success = true;
    }

    function approve(address, uint256) public returns (bool success){
        require(!paused);
        success = true;
    }

    function allowance(address, address) public view returns (uint256 remaining){
        require(!paused);
        remaining = 0;
    }

    function grant(address _to, uint256 _value, uint256 _duration, uint256 _periods) public returns (bool success){
        require(msg.sender != _to);
        require(_balancesMap[msg.sender].tokens >= _value);
        require(_balancesMap[_to].unlockLastTime == 0);

        _balancesMap[msg.sender].tokens = _balancesMap[msg.sender].tokens.sub(_value);

        if(_balancesMap[_to].index == 0){
            UserToken memory user;
            user.index = _balancesArray.length;
            user.addr = _to;
            user.tokens = 0;
            user.unlockUnit = _value.div(_periods);
            user.unlockPeriod = _duration.mul(30).mul(1 days).div(_periods);
            /* user.unlockPeriod = _period; //for test */
            user.unlockLeft = _value;
            user.unlockLastTime = now;
            _balancesMap[_to] = user;
            _balancesArray.push(_to);
        }
        else{
            _balancesMap[_to].unlockUnit = _value.div(_periods);
            _balancesMap[_to].unlockPeriod = _duration.mul(30).mul(1 days).div(_periods);
            /* _balancesMap[_to].unlockPeriod = _period; //for test */
            _balancesMap[_to].unlockLeft = _value;
            _balancesMap[_to].unlockLastTime = now;
        }

        emit Grant(msg.sender, _to, _value);
        log(actionGrant, msg.sender, _to, _value, _duration, _periods);
        success = true;
    }

    function getBalanceAddr(uint256 _index) public view returns(address addr){
        require(_index < _balancesArray.length);
        require(_index >= 0);
        addr = _balancesArray[_index];
    }

    function getBalanceSize() public view returns(uint256 size){
        size = _balancesArray.length;
    }

    function getLockInfo(address addr) public view returns (uint256 unlocked, uint256 unit, uint256 period, uint256 last) {
        UserToken storage user = _balancesMap[addr];
        unlocked = user.unlockLeft;
        unit = user.unlockUnit;
        period = user.unlockPeriod;
        last = user.unlockLastTime;
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