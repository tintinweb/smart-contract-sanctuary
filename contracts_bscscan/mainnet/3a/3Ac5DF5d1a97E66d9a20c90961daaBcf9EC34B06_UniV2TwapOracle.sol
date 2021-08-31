/**
 *Submitted for verification at BscScan.com on 2021-08-31
*/

// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.6.0;

contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        uint256           wad,
        bytes             fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;
        uint256 wad;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
            wad := callvalue()
        }

        _;

        emit LogNote(msg.sig, msg.sender, foo, bar, wad, msg.data);
    }
}

interface DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) external view returns (bool);
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

    function setOwner(address owner_)
        public
        virtual
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        virtual
        auth
    {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "ds-auth-unauthorized");
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(address(0))) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
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

    //rounds to zero if x*y < WAD / 2
    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    //rounds to zero if x*y < WAD / 2
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    //rounds to zero if x*y < WAD / 2
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    //rounds to zero if x*y < RAY / 2
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

contract DSToken is DSMath, DSAuth {
    bool                                              public  stopped;
    uint256                                           public  totalSupply;
    mapping (address => uint256)                      public  balanceOf;
    mapping (address => mapping (address => uint256)) public  allowance;
    string                                            public  symbol;
    uint8                                             public  decimals = 18; // standard token precision. override to customize
    string                                            public  name = "";     // Optional token name


    constructor(string memory symbol_) public {
        symbol = symbol_;
    }

    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
    event Mint(address indexed guy, uint wad);
    event Burn(address indexed guy, uint wad);
    event Stop();
    event Start();

    modifier stoppable {
        require(!stopped, "ds-stop-is-stopped");
        _;
    }

    function approve(address guy) external returns (bool) {
        return approve(guy, uint(-1));
    }

    function approve(address guy, uint wad) public stoppable returns (bool) {
        allowance[msg.sender][guy] = wad;

        emit Approval(msg.sender, guy, wad);

        return true;
    }

    function transfer(address dst, uint wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint wad)
        public
        stoppable
        returns (bool)
    {
        if (src != msg.sender && allowance[src][msg.sender] != uint(-1)) {
            require(allowance[src][msg.sender] >= wad, "ds-token-insufficient-approval");
            allowance[src][msg.sender] = sub(allowance[src][msg.sender], wad);
        }

        require(balanceOf[src] >= wad, "ds-token-insufficient-balance");
        balanceOf[src] = sub(balanceOf[src], wad);
        balanceOf[dst] = add(balanceOf[dst], wad);

        emit Transfer(src, dst, wad);

        return true;
    }

    /*
    function push(address dst, uint wad) external {
        transferFrom(msg.sender, dst, wad);
    }

    function pull(address src, uint wad) external {
        transferFrom(src, msg.sender, wad);
    }

    function move(address src, address dst, uint wad) external {
        transferFrom(src, dst, wad);
    }
    */


    function mint(uint wad) external {
        mint(msg.sender, wad);
    }

    function burn(uint wad) external {
        burn(msg.sender, wad);
    }

    function mint(address guy, uint wad) public auth stoppable {
        balanceOf[guy] = add(balanceOf[guy], wad);
        totalSupply = add(totalSupply, wad);
        emit Mint(guy, wad);
    }

    function burn(address guy, uint wad) public auth stoppable {
        if (guy != msg.sender && allowance[guy][msg.sender] != uint(-1)) {
            require(allowance[guy][msg.sender] >= wad, "ds-token-insufficient-approval");
            allowance[guy][msg.sender] = sub(allowance[guy][msg.sender], wad);
        }

        require(balanceOf[guy] >= wad, "ds-token-insufficient-balance");
        balanceOf[guy] = sub(balanceOf[guy], wad);
        totalSupply = sub(totalSupply, wad);
        emit Burn(guy, wad);
    }

    function stop() public auth {
        stopped = true;
        emit Stop();
    }

    function start() public auth {
        stopped = false;
        emit Start();
    }


    function setName(string memory name_) public auth {
        name = name_;
    }
}

interface PipLike {
    function peek() external view returns (bytes32, bool);
    function read() external view returns (bytes32);
}

interface UniswapV2PairLike {
    function sync()        external;
    function token0()      external view returns (address);
    function token1()      external view returns (address);
    function getReserves() external view returns (uint112,uint112,uint32);  // reserve0, reserve1, blockTimestampLast
}

interface OracleLike
{
    function consultAveragePrice(address _pair, address _token, uint256 _amountIn) external view returns (uint256 _amountOut);
    function updateAveragePrice(address _pair) external;
}

contract UniV2TwapOracle is DSNote, PipLike {

    // --- Auth ---
    mapping (address => uint256) public wards;
    function rely(address _usr) external note auth { wards[_usr] = 1;  }
    function deny(address _usr) external note auth { wards[_usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "UniV2TwapOracle/not-authorized");
        _;
    }

    address public immutable src;     // Price source (LP)
    address public immutable token;   // Token from the pair (the other must be PSM-pegged coin, like BUSD)
    uint256 public immutable cap;     // Price cap
    uint256 public immutable unit;    // Price unit

    address public stwap;             // Short window TWAP implementation
    address public ltwap;             // Large window TWAP implementation

    // --- Whitelisting ---
    mapping (address => uint256) public bud;
    modifier toll { require(bud[msg.sender] == 1, "UniV2TwapOracle/contract-not-whitelisted"); _; }

    constructor (address _stwap, address _ltwap, address _src, address _token, uint256 _cap) public {
        require(_stwap != address(0), "UniV2TwapOracle/invalid-short-twap-address");
        require(_ltwap != address(0), "UniV2TwapOracle/invalid-long-twap-address");
        require(_src   != address(0), "UniV2TwapOracle/invalid-src-address");
        require(_token != address(0), "UniV2TwapOracle/invalid-token-address");
        require(_token == UniswapV2PairLike(_src).token0() || _token == UniswapV2PairLike(_src).token1(), "UniV2TwapOracle/unknown-token-address");
        uint8 _dec = DSToken(_token).decimals();
        require(_dec   <=         18, "UniV2TwapOracle/invalid-dec-places");
        wards[msg.sender] = 1;
        stwap = _stwap;
        ltwap = _ltwap;
        src  = _src;
        token = _token;
        cap = _cap > 0 ? _cap : uint256(-1);
        unit = 10 ** uint256(_dec);
    }

    function link(uint256 _id, address _twap) external note auth {
        require(_twap != address(0), "UniV2TwapOracle/no-contract");
        if(_id == 0) {
            stwap = _twap;
        } else if (_id == 1) {
            ltwap = _twap;
        } else {
            revert("UniV2TwapOracle/invalid-id");
        }
    }

    function poke() external {
        OracleLike(stwap).updateAveragePrice(src);
        OracleLike(ltwap).updateAveragePrice(src);
    }

    function read() external view override toll returns (bytes32) {
        uint256 sprice = OracleLike(stwap).consultAveragePrice(src, token, unit);
        uint256 lprice = OracleLike(ltwap).consultAveragePrice(src, token, unit);
        uint256 price = sprice < lprice ? sprice : lprice;
        if (price > cap) price = cap;
        require(price > 0, "UniV2TwapOracle/invalid-price-feed");
        return bytes32(price);
    }

    function peek() external view override toll returns (bytes32,bool) {
        uint256 sprice = OracleLike(stwap).consultAveragePrice(src, token, unit);
        uint256 lprice = OracleLike(ltwap).consultAveragePrice(src, token, unit);
        uint256 price = sprice < lprice ? sprice : lprice;
        if (price > cap) price = cap;
        return (bytes32(price), price > 0);
    }

    function kiss(address a) external note auth {
        require(a != address(0), "UniV2TwapOracle/no-contract-0");
        bud[a] = 1;
    }

    function diss(address a) external note auth {
        bud[a] = 0;
    }

    function kiss(address[] calldata a) external note auth {
        for(uint i = 0; i < a.length; i++) {
            require(a[i] != address(0), "UniV2TwapOracle/no-contract-0");
            bud[a[i]] = 1;
        }
    }

    function diss(address[] calldata a) external note auth {
        for(uint i = 0; i < a.length; i++) {
            bud[a[i]] = 0;
        }
    }
}