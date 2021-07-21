/**
 *Submitted for verification at BscScan.com on 2021-07-21
*/

pragma solidity ^0.4.23;

contract PADICAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    PADICAuthority  public  authority;
    address      public  owner;

    constructor() public {
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

    function setAuthority(PADICAuthority authority_)
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
        } else if (authority == PADICAuthority(0)) {
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

contract PadiCoin is ERC20, DSMath {
    uint256                                            _supply;
    mapping (address => uint256)                       _balances;
    mapping (address => mapping (address => uint256))  _approvals;

    uint256  public  airdropBSupply = 5*10**3*10**8; // airdrop total supply = 50%
    uint256  public  currentAirdropAmount = 0;
    uint256  airdropNum  =  100*10**8;                // 100PADIC each time for airdrop
    mapping (address => bool) touched;               //records whether an address has received an airdrop;

    constructor(uint supply) public {
        _balances[msg.sender] = sub(supply, airdropBSupply);
        _supply = supply;
        emit Transfer(0x0, msg.sender, _balances[msg.sender]);
    }

    function totalSupply() public view returns (uint) {
        return _supply;
    }
    function balanceOf(address src) public view returns (uint) {
        return getBalance(src);
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
        require(_balances[src] >= wad);

        if (src != msg.sender) {
            require(_approvals[src][msg.sender] >= wad);
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

    //
    function getBalance(address src) internal constant returns(uint) {
        if( currentAirdropAmount < airdropBSupply && !touched[src]) {
            return add(_balances[src], airdropNum);
        } else {
            return _balances[src];
        }
    }
}

contract ContractLock is DSStop {

    uint  public  unlockTime;         // Start time for token transferring
    mapping (address => bool) public isAdmin;  // Admin accounts

    event LogAddAdmin(address whoAdded, address newAdmin);
    event LogRemoveAdmin(address whoRemoved, address admin);

    constructor(uint _unlockTime) public {
        unlockTime = _unlockTime;
        isAdmin[msg.sender] = true;
        emit LogAddAdmin(msg.sender, msg.sender);
    }

    function addAdmin(address admin) public auth returns (bool) {
        if(isAdmin[admin] == false) {
            isAdmin[admin] = true;
            emit LogAddAdmin(msg.sender, admin);
        }
        return true;
    }

    function removeAdmin(address admin) public auth returns (bool) {
        if(isAdmin[admin] == true) {
            isAdmin[admin] = false;
            emit LogRemoveAdmin(msg.sender, admin);
        }
        return true;
    }

    function setOwner(address owner_)
        public
        auth
    {   
        removeAdmin(owner);
        owner = owner_;
        addAdmin(owner);
        emit LogSetOwner(owner);

    }


    modifier onlyAdmin {
        require (isAdmin[msg.sender]);
        _;
    }


    modifier isUnlocked {
        require( now > unlockTime || isAdmin[msg.sender]);
        _;
    }

    function setUnlockTime(uint unlockTime_) public auth {
        unlockTime = unlockTime_;
    }

}

contract PADIC is PadiCoin (1*10**6*10**8), ContractLock(1527782400) {

    string  public  symbol;
    uint256  public  decimals = 8; // standard token precision. override to customize

    constructor(string symbol_) public {
        symbol = symbol_;
    }

    function approve(address guy) public stoppable returns (bool) {
        return super.approve(guy, uint(-1));
    }

    function approve(address guy, uint wad) public stoppable returns (bool) {
        return super.approve(guy, wad);
    }

    function transferFrom(address src, address dst, uint wad) public stoppable isUnlocked returns (bool)
    {
        require(_balances[src] >= wad);

        if(!touched[src] && currentAirdropAmount < airdropBSupply) {
            _balances[src] = add( _balances[src], airdropNum );
            touched[src] = true;
            currentAirdropAmount = add(currentAirdropAmount, airdropNum);
        }

        if (src != msg.sender && _approvals[src][msg.sender] != uint(-1)) {
            require(_approvals[src][msg.sender] >= wad);
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

    // Optional token name
    string   public  name = "PADICOIN TECH";

    function setName(string name_) public auth {
        name = name_;
    }

    //
}