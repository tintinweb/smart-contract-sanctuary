contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
	uint	 	  wad,
        bytes             fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
        }

        LogNote(msg.sig, msg.sender, foo, bar, msg.value, msg.data);

        _;
    }
}

contract ERC20 {
    function totalSupply() constant returns (uint supply);
    function balanceOf( address who ) constant returns (uint value);
    function allowance( address owner, address spender ) constant returns (uint _allowance);

    function transfer( address to, uint value) returns (bool ok);
    function transferFrom( address from, address to, uint value) returns (bool ok);
    function approve( address spender, uint value ) returns (bool ok);

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
}

contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) constant returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    function DSAuth() {
        owner = msg.sender;
        LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        auth
    {
        owner = owner_;
        LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        auth
    {
        authority = authority_;
        LogSetAuthority(authority);
    }

    modifier auth {
        assert(isAuthorized(msg.sender, msg.sig));
        _;
    }

    modifier authorized(bytes4 sig) {
        assert(isAuthorized(msg.sender, sig));
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal returns (bool) {
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

    function assert(bool x) internal {
        if (!x) throw;
    }
}

contract DSExec {
    function tryExec( address target, bytes calldata, uint value)
             internal
             returns (bool call_ret)
    {
        return target.call.value(value)(calldata);
    }
    function exec( address target, bytes calldata, uint value)
             internal
    {
        if(!tryExec(target, calldata, value)) {
            throw;
        }
    }

    // Convenience aliases
    function exec( address t, bytes c )
        internal
    {
        exec(t, c, 0);
    }
    function exec( address t, uint256 v )
        internal
    {
        bytes memory c; exec(t, c, v);
    }
    function tryExec( address t, bytes c )
        internal
        returns (bool)
    {
        return tryExec(t, c, 0);
    }
    function tryExec( address t, uint256 v )
        internal
        returns (bool)
    {
        bytes memory c; return tryExec(t, c, v);
    }
}

contract DSMath {
    
    /*
    standard uint256 functions
     */

    function add(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x - y) <= x);
    }

    function mul(uint256 x, uint256 y) constant internal returns (uint256 z) {
        assert((z = x * y) >= x);
    }

    function div(uint256 x, uint256 y) constant internal returns (uint256 z) {
        z = x / y;
    }

    function min(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x <= y ? x : y;
    }
    function max(uint256 x, uint256 y) constant internal returns (uint256 z) {
        return x >= y ? x : y;
    }

    /*
    uint128 functions (h is for half)
     */


    function hadd(uint128 x, uint128 y) constant internal returns (uint128 z) {
        assert((z = x + y) >= x);
    }

    function hsub(uint128 x, uint128 y) constant internal returns (uint128 z) {
        assert((z = x - y) <= x);
    }

    function hmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        assert((z = x * y) >= x);
    }

    function hdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = x / y;
    }

    function hmin(uint128 x, uint128 y) constant internal returns (uint128 z) {
        return x <= y ? x : y;
    }
    function hmax(uint128 x, uint128 y) constant internal returns (uint128 z) {
        return x >= y ? x : y;
    }


    /*
    int256 functions
     */

    function imin(int256 x, int256 y) constant internal returns (int256 z) {
        return x <= y ? x : y;
    }
    function imax(int256 x, int256 y) constant internal returns (int256 z) {
        return x >= y ? x : y;
    }

    /*
    WAD math
     */

    uint128 constant WAD = 10 ** 18;

    function wadd(uint128 x, uint128 y) constant internal returns (uint128) {
        return hadd(x, y);
    }

    function wsub(uint128 x, uint128 y) constant internal returns (uint128) {
        return hsub(x, y);
    }

    function wmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * y + WAD / 2) / WAD);
    }
    function wmulfloor(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * y) / WAD);
    }

    function wdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * WAD + y / 2) / y);
    }
    function wdivfloor(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * WAD) / y);
    }

    function wmin(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmin(x, y);
    }
    function wmax(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmax(x, y);
    }

    /*
    RAY math
     */

    uint128 constant RAY = 10 ** 27;

    function radd(uint128 x, uint128 y) constant internal returns (uint128) {
        return hadd(x, y);
    }

    function rsub(uint128 x, uint128 y) constant internal returns (uint128) {
        return hsub(x, y);
    }

    function rmul(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * y + RAY / 2) / RAY);
    }

    function rdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * RAY + y / 2) / y);
    }

    function rpow(uint128 x, uint64 n) constant internal returns (uint128 z) {
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

    function rmin(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmin(x, y);
    }
    function rmax(uint128 x, uint128 y) constant internal returns (uint128) {
        return hmax(x, y);
    }

    function cast(uint256 x) constant internal returns (uint128 z) {
        assert((z = uint128(x)) == x);
    }

}

contract DSTokenBase is ERC20, DSMath {
    uint256                                            _supply;
    mapping (address => uint256)                       _balances;
    mapping (address => mapping (address => uint256))  _approvals;
    
    function DSTokenBase(uint256 supply) {
        _balances[msg.sender] = supply;
        _supply = supply;
    }
    
    function totalSupply() constant returns (uint256) {
        return _supply;
    }
    function balanceOf(address src) constant returns (uint256) {
        return _balances[src];
    }
    function allowance(address src, address guy) constant returns (uint256) {
        return _approvals[src][guy];
    }
    
    function transfer(address dst, uint wad) returns (bool) {
        assert(_balances[msg.sender] >= wad);
        
        _balances[msg.sender] = sub(_balances[msg.sender], wad);
        _balances[dst] = add(_balances[dst], wad);
        
        Transfer(msg.sender, dst, wad);
        
        return true;
    }
    
    function transferFrom(address src, address dst, uint wad) returns (bool) {
        assert(_balances[src] >= wad);
        assert(_approvals[src][msg.sender] >= wad);
        
        _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);
        _balances[src] = sub(_balances[src], wad);
        _balances[dst] = add(_balances[dst], wad);
        
        Transfer(src, dst, wad);
        
        return true;
    }
    
    function approve(address guy, uint256 wad) returns (bool) {
        _approvals[msg.sender][guy] = wad;
        
        Approval(msg.sender, guy, wad);
        
        return true;
    }

}

contract DSToken is DSTokenBase(0), DSAuth, DSNote {

    bytes32  public  symbol;
    uint256  public  decimals = 18; // standard token precision. override to customize

    function DSToken(bytes32 symbol_) {
        symbol = symbol_;
    }

    function transfer(address dst, uint wad) note returns (bool) {
        return super.transfer(dst, wad);
    }
    function transferFrom(
        address src, address dst, uint wad
    ) note returns (bool) {
        return super.transferFrom(src, dst, wad);
    }
    function approve(address guy, uint wad) note returns (bool) {
        return super.approve(guy, wad);
    }

    function push(address dst, uint128 wad) returns (bool) {
        return transfer(dst, wad);
    }
    function pull(address src, uint128 wad) returns (bool) {
        return transferFrom(src, msg.sender, wad);
    }

    function mint(uint128 wad) auth note {
        _balances[msg.sender] = add(_balances[msg.sender], wad);
        _supply = add(_supply, wad);
    }
    function burn(uint128 wad) auth note {
        _balances[msg.sender] = sub(_balances[msg.sender], wad);
        _supply = sub(_supply, wad);
    }

    // Optional token name

    bytes32   public  name = "";
    
    function setName(bytes32 name_) auth {
        name = name_;
    }

}

contract SplendSale is DSAuth, DSExec, DSMath {
    DSToken  public  splendToken;
    uint128  public  totalSupply;
    uint128  public  maxTokensFor1Ether;
    uint128  public  minEtherForDay0;
    uint128  public  IEFallocation;
    uint128  public  BAallocation;
    uint128  public  BTallocation;
    address  public  IEFaddress;
    address  public  BAaddress;
    address  public  BTaddress;

    uint     public  openTime;
    uint128  public  createFirstDay;

    uint     public  startTime;
    uint128  public  numberOfDays;
    uint128  public  createPerDay;

    mapping (uint => uint)                       public  dailyTotals;
    mapping (uint => mapping (address => uint))  public  userBuys;
    mapping (address => mapping (uint => uint))  public  userBuysDateWise;
    mapping (uint => mapping (address => bool))  public  claimed;
    mapping (uint => bool)                       public  claimedUnsold;

    event LogBuy         (uint window, address user, uint amount);
    event LogClaim       (uint window, address user, uint amount);
    event LogClaimUnsold (uint window, uint amount);
    event LogCollect     (uint amount);

    function SplendSale(
        uint128  _numberOfDays,
        uint128  _totalSupply,
        uint128  _maxTokensFor1Ether,
        uint128  _minEtherForDay0,
        uint     _openTime,
        uint     _startTime,
        uint128  _createFirstDay,
        uint128  _IEFallocation,
        uint128  _BAallocation,
        uint128  _BTallocation,
        address  _IEFaddress,
        address  _BAaddress,
        address  _BTaddress
    ) {
        numberOfDays        =  _numberOfDays;
        totalSupply         =  _totalSupply;
        maxTokensFor1Ether  =  _maxTokensFor1Ether;
        minEtherForDay0     =  _minEtherForDay0;
        openTime            =  _openTime;
        startTime           =  _startTime;
        createFirstDay      =  _createFirstDay;
        IEFallocation       =  _IEFallocation;
        BAallocation        =  _BAallocation;
        BTallocation        =  _BTallocation;
        IEFaddress          =  _IEFaddress;
        BAaddress           =  _BAaddress;
        BTaddress           =  _BTaddress;

        createPerDay = cast(div(
            sub(sub(sub(sub(totalSupply, IEFallocation), BAallocation), BTallocation), createFirstDay),
            numberOfDays
        ));

        assert(numberOfDays > 0);
        assert(totalSupply > wadd(wadd(wadd(IEFallocation, BAallocation), BTallocation), createFirstDay));
        assert(openTime < startTime);
    }

    function initialize(DSToken _splendToken) auth {
        assert(address(splendToken) == address(0));
        assert(_splendToken.owner() == address(this));
        assert(_splendToken.authority() == DSAuthority(0));
        assert(_splendToken.totalSupply() == 0);

        splendToken = _splendToken;
        splendToken.mint(totalSupply);

        splendToken.push(IEFaddress, IEFallocation);
        splendToken.push(BAaddress, BAallocation);
        splendToken.push(BTaddress, BTallocation);
    }

    function time() constant returns (uint) {
        return block.timestamp;
    }

    function today() constant returns (uint) {
        return dayFor(time());
    }

    // Each window is 23 hours long so that end-of-window rotates
    // around the clock for all timezones.
    function dayFor(uint timestamp) constant returns (uint) {
        return timestamp < startTime
            ? 0
            : sub(timestamp, startTime) / 23 hours + 1;
    }

    function createOnDay(uint day) constant returns (uint) {
        return day == 0 ? createFirstDay : createPerDay;
    }

    // This method provides the buyer some protections regarding which
    // day the buy order is submitted and the maximum price prior to
    // applying this payment that will be allowed.
    function buyWithLimit(uint day, uint limit) payable {
        assert(time() >= openTime && today() <= numberOfDays);
        assert(msg.value >= 0.01 ether);

        assert(day >= today());
        assert(day <= numberOfDays);

        userBuys[day][msg.sender] += msg.value;
        dailyTotals[day] += msg.value;
        if (day == 0) {
            userBuysDateWise[msg.sender][time() / 24 hours + 1] += msg.value;
        }

        if (day == 0) {
            assert(userBuys[day][msg.sender] >= minEtherForDay0);
        }
        if (limit != 0) {
            assert(dailyTotals[day] <= limit);
        }

        LogBuy(day, msg.sender, msg.value);
    }

    function buy() payable {
       buyWithLimit(today(), 0);
    }

    function () payable {
       buy();
    }

    function claim(uint day) {
        assert(today() > day);

        if (claimed[day][msg.sender] || dailyTotals[day] == 0) {
            return;
        }

        var dailyTotal = cast(dailyTotals[day]);
        var userTotal  = cast(userBuys[day][msg.sender]);
        var maxReward  = wmulfloor(userTotal, maxTokensFor1Ether);
        var reward     = wmin(maxReward, wdivfloor(wmulfloor(cast(createOnDay(day)), userTotal), dailyTotal));

        claimed[day][msg.sender] = true;
        splendToken.push(msg.sender, reward);

        LogClaim(day, msg.sender, reward);
    }

    function claimAll() {
        for (uint i = 0; i < today(); i++) {
            claim(i);
        }
    }

    function claimUnsold(uint day) {
        assert(today() > numberOfDays);

        if (claimedUnsold[day]) {
            return;
        }

        var dailyTotal = cast(dailyTotals[day]);
        var maxReward  = wmulfloor(dailyTotal, maxTokensFor1Ether);
        var reward     = wmax(maxReward, cast(createOnDay(day)));
        var unsold     = wsub(cast(createOnDay(day)), reward);

        assert(unsold > 0);

        claimedUnsold[day] = true;
        splendToken.push(BTaddress, unsold);

        LogClaimUnsold(day, unsold);
    }

    function claimAllUnsold() {
        for (uint i = 0; i < today(); i++) {
            claimUnsold(i);
        }
    }

    // Crowdsale owners can collect ETH any number of times
    function collect() auth {
        assert(today() > 0); // Prevent recycling during window 0
        exec(msg.sender, this.balance);
        LogCollect(this.balance);
    }
}