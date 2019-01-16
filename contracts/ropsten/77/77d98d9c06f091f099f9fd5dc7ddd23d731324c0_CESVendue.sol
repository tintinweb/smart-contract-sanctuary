pragma solidity ^0.4.18;

contract ERC20 {
    function totalSupply() constant public returns (uint supply);
    function balanceOf( address who ) constant public returns (uint value);
    function allowance( address owner, address spender ) constant public returns (uint _allowance);

    function transfer( address to, uint value) public returns (bool ok);
    function transferFrom( address from, address to, uint value) public returns (bool ok);
    function approve( address spender, uint value ) public returns (bool ok);

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
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

contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) constant public returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_) public
        auth
    {
        require(owner_ != address(0));
        
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_) public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(authority);
    }

    modifier auth {
        assert(isAuthorized(msg.sender, msg.sig));
        _;
    }

    modifier authorized(bytes4 sig) {
        assert(isAuthorized(msg.sender, sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) view internal returns (bool) {
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

contract DSStop is DSAuth, DSNote {

    bool public stopped;

    modifier stoppable {
        assert (!stopped);
        _;
    }
    
    function stop() public auth note {
        stopped = true;
    }
    
    function start() public auth note {
        stopped = false;
    }

}

contract DSMath {
    
    /*
    standard uint256 functions
     */

    function add(uint256 x, uint256 y) pure internal returns (uint256 z) {
        assert((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) pure internal returns (uint256 z) {
        assert((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) pure internal returns (uint256 z) {
        assert((z = x * y) >= x);
    }

    function div(uint256 x, uint256 y) pure internal returns (uint256 z) {
        z = x / y;
    }

    function min(uint256 x, uint256 y) pure internal returns (uint256 z) {
        return x <= y ? x : y;
    }
    
    function max(uint256 x, uint256 y) pure internal returns (uint256 z) {
        return x >= y ? x : y;
    }
    

    /*
    uint128 functions (h is for half)
     */

    function hadd(uint128 x, uint128 y) pure internal returns (uint128 z) {
        assert((z = x + y) >= x);
    }

    function hsub(uint128 x, uint128 y) pure internal returns (uint128 z) {
        assert((z = x - y) <= x);
    }

    function hmul(uint128 x, uint128 y) pure internal returns (uint128 z) {
        assert((z = x * y) >= x);
    }

    function hdiv(uint128 x, uint128 y) pure internal returns (uint128 z) {
        z = x / y;
    }

    function hmin(uint128 x, uint128 y) pure internal returns (uint128 z) {
        return x <= y ? x : y;
    }
    
    function hmax(uint128 x, uint128 y) pure internal returns (uint128 z) {
        return x >= y ? x : y;
    }


    /*
    int256 functions
     */

    function imin(int256 x, int256 y) pure internal returns (int256 z) {
        return x <= y ? x : y;
    }
    
    function imax(int256 x, int256 y) pure internal returns (int256 z) {
        return x >= y ? x : y;
    }

    /*
    WAD math
     */

    uint128 constant WAD = 10 ** 18;

    function wadd(uint128 x, uint128 y) pure internal returns (uint128) {
        return hadd(x, y);
    }

    function wsub(uint128 x, uint128 y) pure internal returns (uint128) {
        return hsub(x, y);
    }

    function wmul(uint128 x, uint128 y) pure internal returns (uint128 z) {
        z = cast((uint256(x) * y + WAD / 2) / WAD);
    }

    function wdiv(uint128 x, uint128 y) pure internal returns (uint128 z) {
        z = cast((uint256(x) * WAD + y / 2) / y);
    }

    function wmin(uint128 x, uint128 y) pure internal returns (uint128) {
        return hmin(x, y);
    }
    
    function wmax(uint128 x, uint128 y) pure internal returns (uint128) {
        return hmax(x, y);
    }

    /*
    RAY math
     */

    uint128 constant RAY = 10 ** 27;

    function radd(uint128 x, uint128 y) pure internal returns (uint128) {
        return hadd(x, y);
    }

    function rsub(uint128 x, uint128 y) pure internal returns (uint128) {
        return hsub(x, y);
    }

    function rmul(uint128 x, uint128 y) pure internal returns (uint128 z) {
        z = cast((uint256(x) * y + RAY / 2) / RAY);
    }

    function rdiv(uint128 x, uint128 y) pure internal returns (uint128 z) {
        z = cast((uint256(x) * RAY + y / 2) / y);
    }

    function rpow(uint128 x, uint64 n) pure internal returns (uint128 z) {
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

        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }

    function rmin(uint128 x, uint128 y) pure internal returns (uint128) {
        return hmin(x, y);
    }
    
    function rmax(uint128 x, uint128 y) pure internal returns (uint128) {
        return hmax(x, y);
    }

    function cast(uint256 x) pure internal returns (uint128 z) {
        assert((z = uint128(x)) == x);
    }

}

contract DSTokenBase is ERC20, DSMath {
    uint256                                            _supply;
    mapping (address => uint256)                       _balances;
    mapping (address => mapping (address => uint256))  _approvals;
    
    
    constructor(uint256 supply) public {
        _balances[msg.sender] = supply;
        _supply = supply;
    }
    
    function totalSupply() public constant returns (uint256) {
        return _supply;
    }
    
    function balanceOf(address src) public constant returns (uint256) {
        return _balances[src];
    }
    
    function allowance(address src, address guy) public constant returns (uint256) {
        return _approvals[src][guy];
    }
    
    function transfer(address dst, uint wad) public returns (bool) {
        assert(_balances[msg.sender] >= wad);
        
        _balances[msg.sender] = sub(_balances[msg.sender], wad);
        _balances[dst] = add(_balances[dst], wad);
        
        emit Transfer(msg.sender, dst, wad);
        
        return true;
    }
    
    function transferFrom(address src, address dst, uint wad) public returns (bool) {
        assert(_balances[src] >= wad);
        assert(_approvals[src][msg.sender] >= wad);
        
        _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);
        _balances[src] = sub(_balances[src], wad);
        _balances[dst] = add(_balances[dst], wad);
        
        emit Transfer(src, dst, wad);
        
        return true;
    }
    
    function approve(address guy, uint256 wad) public returns (bool) {
        _approvals[msg.sender][guy] = wad;
        
        emit Approval(msg.sender, guy, wad);
        
        return true;
    }
}

contract DSToken is DSTokenBase(0), DSStop {

    string public name = "ERC20 CES";
    string public symbol = "CES"; // token name
    uint8  public decimals = 0;   // standard token precision

    function transfer(address dst, uint wad) public stoppable note returns (bool) {
        return super.transfer(dst, wad);
    }
    
    function transferFrom(address src, address dst, uint wad) 
        public stoppable note returns (bool) {
        return super.transferFrom(src, dst, wad);
    }
    
    function approve(address guy, uint wad) public stoppable note returns (bool) {
        return super.approve(guy, wad);
    }

    function push(address dst, uint128 wad) public returns (bool) {
        return transfer(dst, wad);
    }
    
    function pull(address src, uint128 wad) public returns (bool) {
        return transferFrom(src, msg.sender, wad);
    }

    function mint(uint128 wad) public auth stoppable note {
        _balances[msg.sender] = add(_balances[msg.sender], wad);
        _supply = add(_supply, wad);
    }

    function burn(uint128 wad) public auth stoppable note {
        _balances[msg.sender] = sub(_balances[msg.sender], wad);
        _supply = sub(_supply, wad);
    }
    
    /*
    function setName(string name_, string symbol_) public auth {
        name = name_;
        symbol = symbol_;
    }
    */
}


contract CESVendue is DSAuth, DSMath {
    
    DSToken public CES;
    
    uint public totalETH;      // total ETH was got by vendue
    uint public price;         // vendue Reserve price
    
    uint32 public iaSupply;    // total initialize account for vendue
    uint32 public iaLeft;      // how many initialize account was left
    
    struct accountInfo {
        // vendue ETH
        uint ethVendue;
        
        // The account name used at CES block chain ecocsystem
        string accountName;
        // The public key used for your account
        string publicKey;
        // The pinblock used for your account calc by your password
        string pinblock;
    }
    
    struct elfInfo {
        // whether get the elf
        bool bGetElf;
        
        // The elf sex
        uint8 elfSex;
        // The elf type
        uint16 elfType;
    }
    
    mapping (address => elfInfo)     public elfInfos;
    mapping (address => accountInfo) public initAccInfos; //   init account
    mapping (address => string)      public commonAccs;   // common account
    
    address public godOwner;// the owner who got the god after vendue was closed
    uint16  public godID;   // god owner select his god
    
    bool public vendueClose = false;
    bool public tokenFreeze = false;
    
    address[] public addrLists;
    
    uint startLine;
    
    
    event LogFund(address backer, uint amount, bool isContribution, uint gift);
    event LogFreeze();
    event LogElf(address user, uint8 elfSex, uint16 elfType);
    event LogGod(address owner, uint16 godID);
    event LogInitAcc(address user, string account, string key, string pin);
    event LogRegister(address user, string key, uint token);
    

    constructor() public {
        iaSupply = 20000;
        iaLeft = iaSupply;
        startLine = now;
        price = 5 ether;
    }
    
    function initialize(DSToken tokenReward) public auth {
        assert(address(CES) == address(0));
        assert(tokenReward.owner() == address(this));
        assert(tokenReward.authority() == DSAuthority(0));
        assert(tokenReward.totalSupply() == 0);
        
        uint128 totalIssue     = 1000000000; //   1 billion coin total issue
        uint128 coinDisable    =  600000000; // 0.6 billion coin for disable
        uint128 coinContribute =  200000000; // 0.2 billion coin for contribute
      //uint128 coinGiftA      =  100000000; // 0.1 billion coin gift for vendue
        uint128 coinGiftB      =  100000000; // 0.1 billion coin for chain, APP, airdrops
                                             
        startLine = now;
        
        CES = tokenReward;
        CES.mint(totalIssue);
        CES.push(0x00, hadd(coinDisable, coinContribute));
        CES.push(msg.sender, coinGiftB);
    }
    
    function setPrice(uint price_) external auth {
        require(!vendueClose);
        
        price = price_;
    }
    
    function balanceToken() public view returns (uint256) {
        assert(address(CES) != address(0));
        
        return CES.balanceOf(this);
    }
    
    function todayDays() public view returns (uint) {
        return (div(sub(now, startLine), 1 days) + 1);
    }

    function () public payable {
        require(!vendueClose);
        require(iaLeft > 0);
        require(msg.value >= price);
        require(initAccInfos[msg.sender].ethVendue == 0);
        
        uint money = msg.value;
        initAccInfos[msg.sender].ethVendue = money;
        totalETH = add(totalETH, money);
        
        iaLeft--;
        
        // release period is 1 day 
        // elf gift at first month
        uint dayNow = todayDays();
        if(dayNow <= (31 + 1)) {
            elfInfos[msg.sender].bGetElf = true;
        }
        
        uint coinNeed;
        uint giftLeft = balanceToken();
        
        // coin gift by initialize account
        if(dayNow <= (91 + 1)) {
            if(giftLeft >= 3500) {
                coinNeed = 3500;
            }
        }
        else {
            if(giftLeft >= 2000) {
                coinNeed = 2000;
            }
        }
        
        // coin gift by overflow ETH
        if(money > price) {
            uint multiple = div(sub(money, price), 1 ether);
            uint moreGift = mul(multiple, 800);

            if(moreGift > 0 && (sub(giftLeft, coinNeed) >= moreGift)) {
                coinNeed = add(coinNeed, moreGift);
            }
        }

        if(coinNeed > 0) {
            CES.transfer(msg.sender, coinNeed);
        }
        
        pushAddr(msg.sender);
        
        emit LogFund(msg.sender, money, true, coinNeed);
    }
    
    function withdrawal() external auth {
        
        uint takeNow = sub(address(this).balance, 1 finney);
        
        if(takeNow > 0) {
            if (msg.sender.send(takeNow)) {
                emit LogFund(msg.sender, takeNow, false, 0);
            }
        } 
    }
    
    function vendueClosed() external auth {
        vendueClose = true;
        distillGodOwner();
    }
    
    function freezeToken() external auth {
        require(vendueClose);

        tokenFreeze = true;
        CES.stop();
        
        emit LogFreeze();
    }
    
    function distillGodOwner() public auth {
        require(vendueClose);

        uint ethHighest = 0;
        address addrHighest = address(0);
        
        address addr;
        for(uint i = 0; i < addrLists.length; i++) {
            addr = addrLists[i];
            
            if(address(addr) == address(0)) {
                continue;
            }
            
            if(initAccInfos[addr].ethVendue > ethHighest) {
                ethHighest  = initAccInfos[addr].ethVendue;
                addrHighest = addr;
            }
        }
        
        godOwner = addrHighest;
    }
    
    function pushAddr(address dst) internal {

        bool bExist = false;
        address addr;
        for(uint i = 0; i < addrLists.length; i++) {
            addr = addrLists[i];
            
            if(address(addr) == address(dst)) {
                bExist = true;
                break;
            }
        }
        
        if(!bExist)
        {
            addrLists.push(dst);
        }
    }
    
    // Do this after we provide elf type to you select
    function selectElf(uint8 elfSex, uint16 elfType) external {
        require(elfInfos[msg.sender].bGetElf);

        elfInfos[msg.sender].elfSex = elfSex;
        elfInfos[msg.sender].elfType = elfType;
    
        emit LogElf(msg.sender, elfSex, elfType);
    }
    
    // Do this after we provide god to you select
    function selectGod(uint16 godID_) external {
        require(vendueClose);
        require(msg.sender == godOwner);

        godID = godID_;
        
        emit LogGod(godOwner, godID);
    }
    
    // Do this after we provide tool to produce public key and encrypt your password
    function regInitAccount(string account, string publicKey, string pinblock) external {
        require(initAccInfos[msg.sender].ethVendue > 0);

        assert(bytes(account).length <= 10 && bytes(account).length >= 2);
        assert(bytes(publicKey).length <= 128); //maybe public key is 64 bytes
        assert(bytes(pinblock).length == 16 || bytes(pinblock).length == 32);

        initAccInfos[msg.sender].accountName = account;
        initAccInfos[msg.sender].publicKey = publicKey;
        initAccInfos[msg.sender].pinblock = pinblock;
    
        emit LogInitAcc(msg.sender, account, publicKey, pinblock);
    }
    
    // register your account then tell me your public key for transform token to coin
    // init account don&#39;t need to do this
    function register(string publicKey) external {
        require(tokenFreeze);

        assert(bytes(publicKey).length <= 128); //maybe public key is 64 bytes

        commonAccs[msg.sender] = publicKey;
        
        uint token = CES.balanceOf(msg.sender);
        emit LogRegister(msg.sender, publicKey, token);
    }
    
}