//SourceUnit: TGOLDe.sol

/**
 *Submitted for verification at Etherscan.io on 2020-02-08
*/

pragma solidity ^0.5.10;
// lib/ds-math/src/math.sol
// math.sol -- mixin for inline numerical wizardry
contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }
    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
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
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

// lib/ds-stop/lib/ds-auth/src/auth.sol

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

     constructor() public {
        owner = msg.sender;
       emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_) public auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_) public auth
    {
        authority = authority_;
        emit LogSetAuthority(address(authority));
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
           return authority.canCall(src, address(this), sig);
        }
    }
}

////// lib/ds-stop/lib/ds-note/src/note.sol
contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        uint256              wad,
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

////// lib/ds-stop/src/stop.sol
/// stop.sol -- mixin for enable/disable functionality

contract DSStop is DSNote, DSAuth {

    bool public stopped;

    modifier stoppable {
        require(!stopped);
        _;
    }
    function stop() public auth note payable {
        stopped = true;
    }
    function start() public auth  note payable {
        stopped = false;
    }

}

////// lib/erc20/src/erc20.sol
/// erc20.sol -- API for the ERC20 token standard

contract ERC20Events {
    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
}

contract ERC20 is ERC20Events {
    function totalSupply() public view returns (uint256);
    function balanceOf(address guy) public view returns (uint256);
    function allowance(address src, address guy) public view returns (uint256);

    function approve(address guy, uint256 wad) public returns (bool);
    function transfer(address dst, uint256 wad) public returns (bool);
    function transferFrom(
        address src, address dst, uint256 wad
    ) public returns (bool);
}

////// src/base.sol
/// base.sol -- basic ERC20 implementation

contract DSTokenBase is ERC20, DSMath {
    uint256                                            _supply;
    mapping (address => uint256)                       _balances;
    mapping (address => mapping (address => uint256))  _approvals;

    constructor(uint256 supply) public {
        _balances[msg.sender] = supply;
        _supply = supply;
    }

    function totalSupply() public view returns (uint256) {
        return _supply;
    }
    function balanceOf(address src) public view returns (uint256) {
        return _balances[src];
    }
    function allowance(address src, address guy) public view returns (uint256) {
        return _approvals[src][guy];
    }

    function transfer(address dst, uint256 wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint256 wad) public  returns (bool)
    {
        if (src != msg.sender && _approvals[src][msg.sender] != uint256(-1)) {
            _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);
        }

        _balances[src] = sub(_balances[src], wad);
        _balances[dst] = add(_balances[dst], wad);

       emit Transfer(src, dst, wad);

        return true;
    }

    function approve(address guy, uint256 wad) public returns (bool) {
        _approvals[msg.sender][guy] = wad;

       emit  Approval(msg.sender, guy, wad);

        return true;
    }
}

////// src/token.sol
/// token.sol -- ERC20 implementation with minting and burning
contract BaseToken is DSTokenBase(0), DSStop {

    string  public  symbol;
    string   public  name;
    uint8  public  decimals = 18; 
	mapping (address => uint256) public freezeOf;
    /* constructor(string memory symbol_) public {
        symbol = symbol_;
    }*/
    constructor(string memory symbol_,string memory name_,uint256 totalSupply) public {
        symbol = symbol_;
        name = name_;
        _balances[msg.sender] = totalSupply;
        _supply = totalSupply;
    }

	/* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 value);

	/* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 value);

    event Burn(address indexed guy, uint256 wad);

    function approve(address guy) public stoppable returns (bool) {
        return super.approve(guy, uint256(-1));
    }

    function approve(address guy, uint256 wad) public stoppable returns (bool) {
        return super.approve(guy, wad);
    }

    function transferFrom(address src, address dst, uint256 wad) public
        stoppable
        returns (bool)
    {
        if (src != msg.sender && _approvals[src][msg.sender] != uint256(-1)) {
            _approvals[src][msg.sender] = sub(_approvals[src][msg.sender], wad);
        }

        _balances[src] = sub(_balances[src], wad);
        _balances[dst] = add(_balances[dst], wad);

       emit Transfer(src, dst, wad);

        return true;
    }

    function push(address dst, uint256 wad) public {
        transferFrom(msg.sender, dst, wad);
    }
    function pull(address src, uint256 wad) public {
        transferFrom(src, msg.sender, wad);
    }
    function move(address src, address dst, uint256 wad) public {
        transferFrom(src, dst, wad);
    }

	function freeze(uint256 wad)  public  {
           freeze(msg.sender, wad);
    }


   function freeze(address guy,uint256 wad)  public  auth  {
       if (guy != msg.sender && _approvals[guy][msg.sender] != uint256(-1)) {
            _approvals[guy][msg.sender] = sub(_approvals[guy][msg.sender], wad);
        }
        require(wad <=  _balances[guy]);   // Check if the sender has enough
		require(0 <= wad); 
        _balances[guy] = sub( _balances[guy], wad);   // Subtract from the sender
        freezeOf[guy] = add(freezeOf[guy], wad);     // Updates totalSupply
        emit Freeze(guy, wad);

    }
	
	function unfreeze(uint256 wad)  public  {
        unfreeze(msg.sender, wad);
    }

    function unfreeze(address guy,uint256 wad)  public auth  {
        if (guy != msg.sender && _approvals[guy][msg.sender] != uint256(-1)) {
            _approvals[guy][msg.sender] = sub(_approvals[guy][msg.sender], wad);
        }
        require( wad <= freezeOf[guy]);            // Check if the sender has enough
		require(0 <= wad) ; 
        freezeOf[guy] = sub(freezeOf[guy], wad);  // Subtract from the sender
		 _balances[guy] = add( _balances[guy], wad);
        emit Unfreeze(guy, wad);
 
    }

    function burn(uint256 wad) public {
        burn(msg.sender, wad);
    }

    function burn(address guy, uint256 wad) public auth stoppable {
        if (guy != msg.sender && _approvals[guy][msg.sender] != uint256(-1)) {
            _approvals[guy][msg.sender] = sub(_approvals[guy][msg.sender], wad);
        }

        _balances[guy] = sub(_balances[guy], wad);
        _supply = sub(_supply, wad);
       emit  Burn(guy, wad);
    }


    function setName(string memory name_) public auth {
        name = name_;
    }
}