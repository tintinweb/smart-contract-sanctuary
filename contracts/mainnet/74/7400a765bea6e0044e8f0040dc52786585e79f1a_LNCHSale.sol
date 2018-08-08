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

    function wdiv(uint128 x, uint128 y) constant internal returns (uint128 z) {
        z = cast((uint256(x) * WAD + y / 2) / y);
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

contract DSStop is DSAuth, DSNote {

    bool public stopped;

    modifier stoppable {
        assert (!stopped);
        _;
    }
    function stop() auth note {
        stopped = true;
    }
    function start() auth note {
        stopped = false;
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

contract DSToken is DSTokenBase(0), DSStop {

    bytes32  public  symbol;
    uint256  public  decimals = 18; // standard token precision. override to customize

    function DSToken(bytes32 symbol_) {
        symbol = symbol_;
    }

    function transfer(address dst, uint wad) stoppable note returns (bool) {
        return super.transfer(dst, wad);
    }
    function transferFrom(
        address src, address dst, uint wad
    ) stoppable note returns (bool) {
        return super.transferFrom(src, dst, wad);
    }
    function approve(address guy, uint wad) stoppable note returns (bool) {
        return super.approve(guy, wad);
    }

    function push(address dst, uint128 wad) returns (bool) {
        return transfer(dst, wad);
    }
    function pull(address src, uint128 wad) returns (bool) {
        return transferFrom(src, msg.sender, wad);
    }

    function mint(uint128 wad) auth stoppable note {
        _balances[msg.sender] = add(_balances[msg.sender], wad);
        _supply = add(_supply, wad);
    }
    function burn(uint128 wad) auth stoppable note {
        _balances[msg.sender] = sub(_balances[msg.sender], wad);
        _supply = sub(_supply, wad);
    }

    // Optional token name

    bytes32   public  name = "";
    
    function setName(bytes32 name_) auth {
        name = name_;
    }

}

contract LNCHSale is DSAuth, DSExec, DSMath {
    DSToken  public  LNCH;                  // The LNCH token itself
    uint128  public  totalSupply;          // Total LNCH amount created
    uint128  public  foundersAllocation;   // Amount given to founders
    string   public  foundersKey;          // Public key of founders
    uint128  public  partnersAllocation;   // Amount given to partners
    string   public  partnersKey;          // Public key of partners
    uint128  public  consultantsAllocation;   // Amount given to consultants
    string   public  consultantsKey;          // Public key of consultants
    uint128  public  advisorsAllocation;   // Amount given to advisors
    string   public  advisorsKey;          // Public key of advisors
    uint128  public  developersAllocation;   // Amount given to developers
    string   public  developersKey;          // Public key of developers

    uint     public  openTime;             // Time of window 0 opening
    uint     public  createFirstDay;       // Tokens sold in window 0

    uint     public  startTime;            // Time of window 1 opening
    uint     public  numberOfDays;         // Number of windows after 0
    uint     public  createPerDay;         // Tokens sold in each window

    mapping (uint => uint)                       public  dailyTotals;
    mapping (uint => mapping (address => uint))  public  userBuys;
    mapping (uint => mapping (address => bool))  public  claimed;
    mapping (address => string)                  public  keys;

    event LogBuy      (uint window, address user, uint amount);
    event LogClaim    (uint window, address user, uint amount);
    event LogRegister (address user, string key);
    event LogCollect  (uint amount);
    event LogFreeze   ();

function LNCHSale(
        uint     _numberOfDays,
        uint128  _totalSupply,
        uint     _openTime,
        uint     _startTime,
        uint128  _foundersAllocation,
        string   _foundersKey,
        uint128  _partnersAllocation,
        string   _partnersKey,
        uint128  _consultantsAllocation,
        string   _consultantsKey,
        uint128  _advisorsAllocation,
        string   _advisorsKey,
        uint128  _developersAllocation,
        string   _developersKey
    ) {
        numberOfDays          = _numberOfDays;
        totalSupply           = _totalSupply;
        openTime              = _openTime;
        startTime             = _startTime;
        foundersAllocation    = _foundersAllocation;
        foundersKey           = _foundersKey;
        partnersAllocation    = _partnersAllocation;
        partnersKey           = _partnersKey;
        consultantsAllocation = _consultantsAllocation;
        consultantsKey        = _consultantsKey;
        advisorsAllocation    = _advisorsAllocation;
        advisorsKey           = _advisorsKey;
        developersAllocation  = _developersAllocation;
        developersKey         = _developersKey;

        createFirstDay = wmul(totalSupply, 0.25 ether);
        createPerDay = div(
            createFirstDay,
            numberOfDays
        );

        assert(numberOfDays > 0);
        assert(totalSupply > foundersAllocation);
        assert(totalSupply > partnersAllocation);
        assert(totalSupply > consultantsAllocation);
        assert(totalSupply > advisorsAllocation);
        assert(totalSupply > developersAllocation);
        assert(openTime < startTime);
    }

    function digitToNumber(uint8 b) constant returns (uint8) {
      if ( b <= 57 )
	return b-48 ;
      if ( b <= 70 )
	return b-65+10 ;
      return b-97+10 ;
    }	    

    function stringToAddress(string __address) constant returns (address) {
      bytes memory _address = bytes(__address) ;
      uint160 m = 0;
      uint160 b = 0;
      
      for (uint8 i = 2; i < 42; i++) {
	m *= 16;
	b = uint160(digitToNumber(uint8(_address[i])));
	m += (b);
      }
      
      return address(m);
    }
 
    function initialize(DSToken lnch) auth {
        address addr ;
        assert(address(LNCH) == address(0));
        assert(lnch.owner() == address(this));
        assert(lnch.authority() == DSAuthority(0));
        assert(lnch.totalSupply() == 0);

        LNCH = lnch;
        LNCH.mint(totalSupply);

	addr = stringToAddress(foundersKey) ;
        LNCH.push(addr, foundersAllocation);
	keys[addr] = foundersKey;
        LogRegister(addr, foundersKey);

	addr = stringToAddress(partnersKey) ;
        LNCH.push(addr, partnersAllocation);
	keys[addr] = partnersKey;
        LogRegister(addr, partnersKey);

	addr = stringToAddress(consultantsKey) ;
        LNCH.push(addr, consultantsAllocation);
	keys[addr] = consultantsKey;
        LogRegister(addr, consultantsKey);

	addr = stringToAddress(advisorsKey) ;
        LNCH.push(addr, advisorsAllocation);
	keys[addr] = advisorsKey;
        LogRegister(addr, advisorsKey);
        
    addr = stringToAddress(developersKey) ;
        LNCH.push(addr, developersAllocation);
	keys[addr] = developersKey;
        LogRegister(addr, developersKey);
	
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

        // This will have small rounding errors, but the token is
        // going to be truncated to 8 decimal places or less anyway
        // when launched on its own chain.

        var dailyTotal = cast(dailyTotals[day]);
        var userTotal  = cast(userBuys[day][msg.sender]);
        var price      = wdiv(cast(createOnDay(day)), dailyTotal);
        var reward     = wmul(price, userTotal);

        claimed[day][msg.sender] = true;
        LNCH.push(msg.sender, reward);

        LogClaim(day, msg.sender, reward);
    }

    function claimAll() {
        for (uint i = 0; i < today(); i++) {
            claim(i);
        }
    }

    // Value should be a public key.  Read full key import policy.
    // Manually registering requires a base58
    // encoded using the LNCH public key format.
    function register(string key) {
        assert(today() <=  numberOfDays + 1);
        assert(bytes(key).length <= 64);

        keys[msg.sender] = key;

        LogRegister(msg.sender, key);
    }

    // Crowdsale owners can collect ETH any number of times
    function collect() auth {
        assert(today() > 0); // Prevent recycling during window 0
        exec(msg.sender, this.balance);
        LogCollect(this.balance);
    }

    // Anyone can freeze the token 1 day after the sale ends
    function freeze() {
        assert(today() > numberOfDays + 1);
        LNCH.stop();
        LogFreeze();
    }
}