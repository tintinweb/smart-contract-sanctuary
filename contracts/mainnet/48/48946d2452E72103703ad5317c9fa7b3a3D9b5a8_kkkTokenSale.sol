// Copyright (C) 2017 DappHub, LLC

pragma solidity ^0.4.11;

//import "ds-exec/exec.sol";

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

//import "ds-auth/auth.sol";
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

//import "ds-note/note.sol";
contract DSNote {
    event LogNote(
    bytes4   indexed  sig,
    address  indexed  guy,
    bytes32  indexed  foo,
    bytes32  indexed  bar,
    uint        wad,
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


//import "ds-math/math.sol";
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
        z = x * y;
        assert(x == 0 || z / x == y);
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
        z = x * y;
        assert(x == 0 || z / x == y);
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

//import "erc20/erc20.sol";
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



//import "ds-token/base.sol";
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


//import "ds-stop/stop.sol";
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


//import "ds-token/token.sol";
contract DSToken is DSTokenBase(0), DSStop {

    bytes32  public  symbol;
    uint256  public  decimals = 18; // standard token precision. override to customize
    address  public  generator;

    modifier onlyGenerator {
        if(msg.sender!=generator) throw;
        _;
    }

    function DSToken(bytes32 symbol_) {
        symbol = symbol_;
        generator=msg.sender;
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

    // owner can transfer token even stop,
    function generatorTransfer(address dst, uint wad) onlyGenerator note returns (bool) {
        return super.transfer(dst, wad);
    }

    // Optional token name

    bytes32   public  name = "";

    function setName(bytes32 name_) auth {
        name = name_;
    }

}


contract kkkTokenSale is DSStop, DSMath, DSExec {

    DSToken public kkk;

    // kkk PRICES (ETH/kkk)
    uint128 public constant PUBLIC_SALE_PRICE = 200000 ether;

    uint128 public constant TOTAL_SUPPLY = 10 ** 11 * 1 ether;  // 100 billion kkk in total

    uint128 public constant SELL_SOFT_LIMIT = TOTAL_SUPPLY * 12 / 100; // soft limit is 12% , 60000 eth
    uint128 public constant SELL_HARD_LIMIT = TOTAL_SUPPLY * 16 / 100; // hard limit is 16% , 80000 eth

    uint128 public constant FUTURE_DISTRIBUTE_LIMIT = TOTAL_SUPPLY * 84 / 100; // 84% for future distribution

    uint128 public constant USER_BUY_LIMIT = 500 ether; // 500 ether limit
    uint128 public constant MAX_GAS_PRICE = 50000000000;  // 50GWei

    uint public startTime;
    uint public endTime;

    bool public moreThanSoftLimit;

    mapping (address => uint)  public  userBuys; // limit to 500 eth

    address public destFoundation; //multisig account , 4-of-6

    uint128 public sold;
    uint128 public constant soldByChannels = 40000 * 200000 ether; // 2 ICO websites, each 20000 eth

    function kkkTokenSale(uint startTime_, address destFoundation_) {

        kkk = new DSToken("kkk");

        destFoundation = destFoundation_;

        startTime = startTime_;
        endTime = startTime + 14 days;

        sold = soldByChannels; // sold by 3rd party ICO websites;
        kkk.mint(TOTAL_SUPPLY);

        kkk.transfer(destFoundation, FUTURE_DISTRIBUTE_LIMIT);
        kkk.transfer(destFoundation, soldByChannels);

        //disable transfer
        kkk.stop();
    }

    // overrideable for easy testing
    function time() constant returns (uint) {
        return now;
    }

    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) return false;
        assembly {
        size := extcodesize(_addr)
        }
        return size > 0;
    }

    function canBuy(uint total) returns (bool) {
        return total <= USER_BUY_LIMIT;
    }

    function() payable stoppable note {

        require(!isContract(msg.sender));
        require(msg.value >= 0.01 ether);
        require(tx.gasprice <= MAX_GAS_PRICE);

        assert(time() >= startTime && time() < endTime);

        var toFund = cast(msg.value);

        var requested = wmul(toFund, PUBLIC_SALE_PRICE);

        // selling SELL_HARD_LIMIT tokens ends the sale
        if( add(sold, requested) >= SELL_HARD_LIMIT) {
            requested = SELL_HARD_LIMIT - sold;
            toFund = wdiv(requested, PUBLIC_SALE_PRICE);

            endTime = time();
        }

        // User cannot buy more than USER_BUY_LIMIT
        var totalUserBuy = add(userBuys[msg.sender], toFund);
        assert(canBuy(totalUserBuy));
        userBuys[msg.sender] = totalUserBuy;

        sold = hadd(sold, requested);

        // Soft limit triggers the sale to close in 24 hours
        if( !moreThanSoftLimit && sold >= SELL_SOFT_LIMIT ) {
            moreThanSoftLimit = true;
            endTime = time() + 24 hours; // last 24 hours after soft limit,
        }

        kkk.start();
        kkk.transfer(msg.sender, requested);
        kkk.stop();

        exec(destFoundation, toFund); // send collected ETH to multisig

        // return excess ETH to the user
        uint toReturn = sub(msg.value, toFund);
        if(toReturn > 0) {
            exec(msg.sender, toReturn);
        }
    }

    function setStartTime(uint startTime_) auth note {
        require(time() <= startTime && time() <= startTime_);

        startTime = startTime_;
        endTime = startTime + 14 days;
    }

    function finalize() auth note {
        require(time() >= endTime);

        // enable transfer
        kkk.start();

        // transfer undistributed kkk
        kkk.transfer(destFoundation, kkk.balanceOf(this));

        // owner -> destFoundation
        kkk.setOwner(destFoundation);
    }


    // @notice This method can be used by the controller to extract mistakenly
    //  sent tokens to this contract.
    // @param dst The address that will be receiving the tokens
    // @param wad The amount of tokens to transfer
    // @param _token The address of the token contract that you want to recover
    function transferTokens(address dst, uint wad, address _token) public auth note {
        ERC20 token = ERC20(_token);
        token.transfer(dst, wad);
    }

    function summary()constant returns(
        uint128 _sold,
        uint _startTime,
        uint _endTime)
        {
        _sold = sold;
        _startTime = startTime;
        _endTime = endTime;
        return;
    }

}