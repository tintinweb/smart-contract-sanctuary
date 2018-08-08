pragma solidity ^0.4.13;


contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    function DSAuth() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(authority);
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, this, sig);
        }
    }
}


contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        uint              wad,
        bytes             fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
        }

        emit LogNote(msg.sig, msg.sender, foo, bar, msg.value, msg.data);

        _;
    }
}


contract DSStop is DSNote, DSAuth {

    bool public stopped;

    modifier stoppable {
        require(!stopped);
        _;
    }
    function stop() public auth note {
        stopped = true;
    }
    function start() public auth note {
        stopped = false;
    }

}


contract ERC20Events {
    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
}

contract ERC20 is ERC20Events {
    function totalSupply() public view returns (uint);
    function balanceOf(address guy) public view returns (uint);
    function allowance(address src, address guy) public view returns (uint);

    function approve(address guy, uint wad) public returns (bool);
    function transfer(address dst, uint wad) public returns (bool);
    function transferFrom(
        address src, address dst, uint wad
    ) public returns (bool);
}


contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It&#39;s O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}


contract DSTokenBase is ERC20, DSMath {
    uint256                                            _supply;
    mapping (address => uint256)                       _balances;
    mapping (address => mapping (address => uint256))  _approvals;

    function DSTokenBase(uint supply) public {
        _balances[msg.sender] = supply;
        _supply = supply;
    }

    function totalSupply() public view returns (uint) {
        return _supply;
    }
    function balanceOf(address src) public view returns (uint) {
        return _balances[src];
    }
    function allowance(address src, address guy) public view returns (uint) {
        return _approvals[src][guy];
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        returns (bool)
    {
        if (src != msg.sender) {
            _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);
        }

        _balances[src] = sub(_balances[src], wad);
        _balances[dst] = add(_balances[dst], wad);

        emit Transfer(src, dst, wad);

        return true;
    }

    function approve(address guy, uint wad) public returns (bool) {
        _approvals[msg.sender][guy] = wad;

        emit Approval(msg.sender, guy, wad);

        return true;
    }
}


contract DSToken is DSTokenBase(0), DSStop {

    string  public  symbol = "";
    string   public  name = "";
    uint256  public  decimals = 18; // standard token precision. override to customize

    function DSToken(
        string symbol_,
        string name_
    ) public {
        symbol = symbol_;
        name = name_;
    }

    event Mint(address indexed guy, uint wad);
    event Burn(address indexed guy, uint wad);

    function setName(string name_) public auth {
        name = name_;
    }

    function approve(address guy) public stoppable returns (bool) {
        return super.approve(guy, uint(-1));
    }

    function approve(address guy, uint wad) public stoppable returns (bool) {
        return super.approve(guy, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        stoppable
        returns (bool)
    {
        if (src != msg.sender && _approvals[src][msg.sender] != uint(-1)) {
            _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);
        }

        _balances[src] = sub(_balances[src], wad);
        _balances[dst] = add(_balances[dst], wad);

        emit Transfer(src, dst, wad);

        return true;
    }

    function push(address dst, uint wad) public {
        transferFrom(msg.sender, dst, wad);
    }
    function pull(address src, uint wad) public {
        transferFrom(src, msg.sender, wad);
    }
    function move(address src, address dst, uint wad) public {
        transferFrom(src, dst, wad);
    }

    function mint(uint wad) public {
        mint(msg.sender, wad);
    }
    function burn(uint wad) public {
        burn(msg.sender, wad);
    }
    function mint(address guy, uint wad) public auth stoppable {
        _balances[guy] = add(_balances[guy], wad);
        _supply = add(_supply, wad);
        emit Mint(guy, wad);
    }
    function burn(address guy, uint wad) public auth stoppable {
        if (guy != msg.sender && _approvals[guy][msg.sender] != uint(-1)) {
            _approvals[guy][msg.sender] = sub(_approvals[guy][msg.sender], wad);
        }

        _balances[guy] = sub(_balances[guy], wad);
        _supply = sub(_supply, wad);
        emit Burn(guy, wad);
    }
}


//==============================
// 使用说明
//1.发布DSToken合约
//
//2.发布TICDist代币操作合约
//
//3.钱包里面，DSToken绑定操作合约合约
//
//4.设置参数
//
// setDistConfig 创始人参数说明
//["0xc94cd681477e6a70a4797a9Cbaa9F1E52366823c","0xCc1696E57E2Cd0dCd61164eE884B4994EA3B916A","0x9bD5DB3059186FA8eeAD8e4275a2DA50F0380528"] //有3个创始人
//[51,15,34] //各自分配比例51%，15%，34%
// setLockedConfig 锁仓参数说明
//["0xc94cd681477e6a70a4797a9Cbaa9F1E52366823c"] //只有第一个创始人锁仓
//[50]	// 第一个人自己的份额，锁仓50%
//[10]	// 锁仓截至时间为，开始发行后的10天
//
//5.开始发行 startDist
//==============================

//===============================
// TIC代币 操作合约
//===============================
contract TICDist is DSAuth, DSMath {

    DSToken  public  TIC;                   // TIC代币对象
    uint256  public  initSupply = 0;        // 初始化发行供应量
    uint256  public  decimals = 18;         // 代币精度，默认小数点后18位，不建议修改

    // 发行相关
    uint public distDay = 0;                // 发行 开始时间
    bool public isDistConfig = false;       // 是否配置过发行标志
    bool public isLockedConfig = false;     // 是否配置过锁仓标志
    
    bool public bTest = true;               // 锁仓的情况下，每天释放1%，做演示用
    
    struct Detail {  
        uint distPercent;   // 发行时，创始人的分配比例
        uint lockedPercent; // 发行时，创始人的锁仓比例
        uint lockedDay;     // 发行时，创始人的锁仓时间
        uint256 lockedToken;   // 发行时，创始人的被锁仓代币
    }

    address[] public founderList;                 // 创始人列表
    mapping (address => Detail)  public  founders;// 发行时，创始人的分配比例
    
    // 默认构造
    function TICDist(uint256 initial_supply) public {
        initSupply = initial_supply;
    }

    // 此操作合约，绑定代币接口, 注意，一开始代币创建，代币都在发行者账号里面
    // @param  {DSToken} tic 代币对象
    function setTIC(DSToken  tic) public auth {
        // 判断之前没有绑定过
        assert(address(TIC) == address(0));
        // 本操作合约有代币所有权
        assert(tic.owner() == address(this));
        // 总发行量不能为0
        assert(tic.totalSupply() == 0);
        // 赋值
        TIC = tic;
        // 初始化代币总量，并把代币总量存到合约账号里面
        initSupply = initSupply*10**uint256(decimals);
        TIC.mint(initSupply);
    }

    // 设置发行参数
    // @param  {address[]nt} founders_ 创始人列表
    // @param  {uint[]} percents_ 创始人分配比例，总和必须小于100
    function setDistConfig(address[] founders_, uint[] percents_) public auth {
        // 判断是否配置过
        assert(isDistConfig == false);
        // 输入参数测试
        assert(founders_.length > 0);
        assert(founders_.length == percents_.length);
        uint all_percents = 0;
        uint i = 0;
        for (i=0; i<percents_.length; ++i){
            assert(percents_[i] > 0);
            assert(founders_[i] != address(0));
            all_percents += percents_[i];
        }
        assert(all_percents <= 100);
        // 赋值
        founderList = founders_;
        for (i=0; i<founders_.length; ++i){
            founders[founders_[i]].distPercent = percents_[i];
        }
        // 设置标志
        isDistConfig = true;
    }

    // 设置发行锁仓参数
    // @param  {address[]} founders_ 创始人列表，注意，不一定要所有创始人，只有锁仓需求的才要
    // @param  {uint[]} percents_ 对应的锁仓比例
    // @param  {uint[]} days_ 对应的锁仓时间，这个时间是相对distDay，发行后的时间
    function setLockedConfig(address[] founders_, uint[] percents_, uint[] days_) public auth {
        // 必须先设置发行参数
        assert(isDistConfig == true);
        // 判断是否配置过
        assert(isLockedConfig == false);
        // 判断是否有值
        if (founders_.length > 0){
            // 输入参数测试
            assert(founders_.length == percents_.length);
            assert(founders_.length == days_.length);
            uint i = 0;
            for (i=0; i<percents_.length; ++i){
                assert(percents_[i] > 0);
                assert(percents_[i] <= 100);
                assert(days_[i] > 0);
                assert(founders_[i] != address(0));
            }
            // 赋值
            for (i=0; i<founders_.length; ++i){
                founders[founders_[i]].lockedPercent = percents_[i];
                founders[founders_[i]].lockedDay = days_[i];
            }
        }
        // 设置标志
        isLockedConfig = true;
    }

    // 开始发行
    function startDist() public auth {
        // 必须还没发行过
        assert(distDay == 0);
        // 判断必须配置过
        assert(isDistConfig == true);
        assert(isLockedConfig == true);
        // 对每个创始人代币初始化
        uint i = 0;
        for(i=0; i<founderList.length; ++i){
            // 获得创始人的份额
            uint256 all_token_num = TIC.totalSupply()*founders[founderList[i]].distPercent/100;
            assert(all_token_num > 0);
            // 获得锁仓的份额
            uint256 locked_token_num = all_token_num*founders[founderList[i]].lockedPercent/100;
            // 记录锁仓的token
            founders[founderList[i]].lockedToken = locked_token_num;
            // 发放token给创始人
            TIC.push(founderList[i], all_token_num - locked_token_num);
        }
        // 设置发行时间
        distDay = today();
        // 更新锁仓时间
        for(i=0; i<founderList.length; ++i){
            if (founders[founderList[i]].lockedDay != 0){
                founders[founderList[i]].lockedDay += distDay;
            }
        }
    }

    // 确认锁仓时间是否到了，结束锁仓
    function checkLockedToken() public {
        // 必须发行过
        assert(distDay != 0);
        // 有锁仓需求的创始人
        assert(founders[msg.sender].lockedDay > 0);
        // 有锁仓代币
        assert(founders[msg.sender].lockedToken > 0);
        if (bTest){
            // 计算需要解锁的份额
            uint unlock_percent = today() - distDay;
            if(unlock_percent > founders[msg.sender].lockedPercent){
                unlock_percent = founders[msg.sender].lockedPercent;
            }
            // 获得总的代币
            uint256 all_token_num = TIC.totalSupply()*founders[msg.sender].distPercent/100;
            // 获得锁仓的份额
            uint256 locked_token_num = all_token_num*founders[msg.sender].lockedPercent/100;
            // 每天释放的量
            uint256 unlock_token_num = locked_token_num*unlock_percent/founders[msg.sender].lockedPercent;
            if (unlock_token_num > founders[msg.sender].lockedToken){
                unlock_token_num = founders[msg.sender].lockedToken;
            }
            // 开始解锁 token
            TIC.push(msg.sender, unlock_token_num);
            // 锁仓token数据减少
            founders[msg.sender].lockedToken -= unlock_token_num;
        } else {
            // 判断是否解锁时间到
            assert(today() > founders[msg.sender].lockedDay);
            // 开始解锁 token
            TIC.push(msg.sender, founders[msg.sender].lockedToken);
            // 锁仓token数据清空
            founders[msg.sender].lockedToken = 0;
        }
    }

    // 获得当前时间 单位天
    function today() public constant returns (uint) {
        return time() / 24 hours;
        // TODO test
        //return time() / 1 minutes;
    }
   
    // 获得区块链时间戳，单位秒
    function time() public constant returns (uint) {
        return block.timestamp;
    }
}