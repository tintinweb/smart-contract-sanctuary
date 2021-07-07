/**
 *Submitted for verification at BscScan.com on 2021-07-07
*/

pragma solidity =0.6.6;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'math-mul-overflow');
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, 'math-div-overflow');
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, 'math-mod-overflow');
        return a % b;
    }
}

contract YLSToken is IERC20 {
    
    event Release(address indexed from, uint value);
    
    event AddedBlackList(address _user);
    
    using SafeMath for uint;

    address private _owner ;
    string private override constant _name = "YLS";
    string private override constant _symbol = "YLS";
    uint8 private override constant _decimals = 18;
    uint  private override _totalSupply ;
    uint private _init = 10000 * 10**18;
    uint private _groups = 500 * 10**18;
    uint private _community = 500 * 10**18;
    uint private _sum_release = 9000 * 10**18;
    uint private _released = 0;
    uint private _group_per_release = 50 * 10**18;
    
    mapping (address => uint256) public isBlackListed;
    
    struct ReleaseInfo {
        uint256 per_timestamp;
        uint256 sum;
        uint256 per_release;
        uint256 left;
    }
    
    struct FreezeStruct {
        uint256 max_time ; // max release time
        uint256 released_time ;// this time of release;
        uint256 last_timestamp ; // last timestamp of release;
        uint256 per_timestamp ;
        uint256 per_release ; // release number per time;
    }
    
    ReleaseInfo[] public releaseInfo ;
    
    uint256 public phase = 0 ;
    
    uint256 public phaseLeftBalance = 0;//this phase left.
    
    bool public phaseStart = false;//if phase started
    
    mapping(uint256 => mapping(address=>FreezeStruct)) public userInfo;
    
    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) public _allowances;
    
    uint256 public _half_year = 600;//half year time
    
    uint256 public _month = 120;//one month time
    
    uint256 public _phase_times = 10;//every phase ervery user release times.

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    
    function addBlackList (address _evilUser) public  {
        require(msg.sender == _owner,"permission error");
        isBlackListed[_evilUser] = block.timestamp;
        emit AddedBlackList(_evilUser);
    }
    
    
    function startPhase()public returns (bool){
        require(msg.sender == _owner,"permission error");
        phaseStart = true;
    }
    
    function stopPhase()public returns (bool){
        require(msg.sender == _owner,"permission error");
        phaseStart = false;
    }
    
    function addPhase(uint256 maxBalance,uint256 perBalance)public returns (bool){
        if(phase>0){
            require(releaseInfo[phase].left==0,"last phase not end.");
        }
        require(msg.sender == _owner,"permission error");
        require(maxBalance.add(_released)<=_sum_release,"balance overflow");
        require(maxBalance.mod(perBalance)==0,"math:can not div to integer.");
        require(perBalance.mod(_phase_times)==0,"math:can not div to integer.");
        releaseInfo.push(ReleaseInfo({
            per_timestamp : _month,
            sum : maxBalance,
            per_release : perBalance,
            left : maxBalance
        }));
        phaseLeftBalance = maxBalance;
        _released = _released.add(maxBalance);
        phase = phase + 1;
        phaseStart = true;
    }
    
    function buy(address to)public returns (bool){
        require(msg.sender == _owner,"permission error");
        require(phase>0,"phase error.");
        require(phaseStart,"phase not start.");
        ReleaseInfo storage info = releaseInfo[phase];
        require(info.left>=info.per_release.mul(_phase_times),"no enough balance");
        FreezeStruct storage freezeStruct = userInfo[phase][to];
        require(freezeStruct.last_timestamp==0&&freezeStruct.max_time==0,"address already buys.");
        info.left = info.left.sub(info.per_release.mul(_phase_times));
        phaseLeftBalance = phaseLeftBalance.sub(info.per_release.mul(_phase_times));
        userInfo[phase][to].max_time=_phase_times;
        userInfo[phase][to].released_time=1;
        userInfo[phase][to].last_timestamp=block.timestamp;
        userInfo[phase][to].per_timestamp=_month;
        userInfo[phase][to].per_release=info.per_release;
        _balances[to] = _balances[to].add(info.per_release);
        emit Release(to, info.per_release);
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        uint256 balance = _balances[account];
        for(uint256 i = 0 ;i<= phase;i++){
            FreezeStruct storage freezeStruct = userInfo[i][account];
            if(block.timestamp>=freezeStruct.last_timestamp){
                if(freezeStruct.last_timestamp!=0&&freezeStruct.max_time!=0){
                    uint256 checkTime = block.timestamp;
                    if(isBlackListed[account]>0){
                        checkTime = isBlackListed[account];
                    }
                    if(checkTime>freezeStruct.last_timestamp){
                        uint256 releaseTimes = checkTime.sub( freezeStruct.last_timestamp)
                                    .div(freezeStruct.per_timestamp);
                        if(releaseTimes>freezeStruct.max_time.sub( freezeStruct.released_time)){
                            releaseTimes = freezeStruct.max_time.sub(freezeStruct.released_time);
                        }
                        balance = balance.add(releaseTimes.mul(freezeStruct.per_release));
                    }
                }
            }
        }
        return balance;
    }
    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    constructor() public {
        _owner = msg.sender;
        _totalSupply = _init;
        _balances[msg.sender] = _balances[msg.sender].add(_community);
        emit Transfer(address(0), msg.sender, _community);
        _initGroup(_month,_groups,_group_per_release,block.timestamp.add(_half_year));
    }
    
    function _initGroup(uint per_timestamp,uint sum,uint per_release,uint start_release) private {
        releaseInfo.push(ReleaseInfo({
            per_timestamp : per_timestamp,
            sum : sum,
            per_release : per_release,
            left : 0
        }));
        userInfo[phase][msg.sender].max_time=_phase_times;
        userInfo[phase][msg.sender].released_time=0;
        userInfo[phase][msg.sender].last_timestamp=start_release.sub(_month);
        userInfo[phase][msg.sender].per_timestamp=_month;
        userInfo[phase][msg.sender].per_release=per_release;
    }
    
    function _release(address from) private {
        for(uint256 i = 0 ;i<= phase;i++){
            FreezeStruct storage freezeStruct = userInfo[i][from];
            if(block.timestamp>=freezeStruct.last_timestamp){
                if(freezeStruct.last_timestamp!=0&&freezeStruct.max_time!=0){
                    uint256 checkTime = block.timestamp;
                    if(isBlackListed[from]>0){
                        checkTime = isBlackListed[from];
                    }
                    if(checkTime>freezeStruct.last_timestamp){
                        uint256 releaseTimes = checkTime.sub( freezeStruct.last_timestamp)
                                    .div(freezeStruct.per_timestamp);
                        if(releaseTimes>freezeStruct.max_time.sub( freezeStruct.released_time)){
                            releaseTimes = freezeStruct.max_time.sub( freezeStruct.released_time);
                        }
                        if(releaseTimes>0){
                            userInfo[i][from].released_time = freezeStruct.released_time.add( releaseTimes);
                            userInfo[i][from].last_timestamp = 
                                freezeStruct.last_timestamp.add( releaseTimes.mul(freezeStruct.per_timestamp));
                            _balances[from] = _balances[from].add(releaseTimes.mul(freezeStruct.per_release));
                            emit Release(from, releaseTimes.mul(freezeStruct.per_release));
                        }
                    }
                }
            }
        }
    }
    

    function _mint(address to, uint value) private  {
        _totalSupply = _totalSupply.add(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) private {
        _balances[from] = _balances[from].sub(value);
        _totalSupply = _totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        _release(from);
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external override returns (bool) {
        if (_allowances[from][msg.sender] != uint(-1)) {
            _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

}