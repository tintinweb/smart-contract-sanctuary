/**
 *Submitted for verification at Etherscan.io on 2021-02-04
*/

// SPDX-License-Identifier: GPL-3.0-or-later

/// UNIV2LPOracle.sol

// Copyright (C) 2017-2020 Maker Ecosystem Growth Holdings, INC.

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

///////////////////////////////////////////////////////
//                                                   //
//    Methodology for Calculating LP Token Price     //
//                                                   //
///////////////////////////////////////////////////////

// INVARIANT k = reserve0 [num token0] * reserve1 [num token1]
//
// k = r_x * r_y
// r_y = k / r_x
//
// 50-50 pools try to stay balanced in dollar terms
// r_x * p_x = r_y * p_y    // Proportion of r_x and r_y can be manipulated so need to normalize them
//
// r_x * p_x = p_y * (k / r_x)
// r_x^2 = k * p_y / p_x
// r_x = sqrt(k * p_y / p_x) & r_y = sqrt(k * p_x / p_y)
//
// Now that we've calculated normalized values of r_x and r_y that are not prone to manipulation by an attacker,
// we can calculate the price of an lp token using the following formula.
//
// p_lp = (r_x * p_x + r_y * p_y) / supply_lp
//
pragma solidity ^0.6.11;

interface ERC20Like {
    function decimals()         external view returns (uint8);
    function balanceOf(address) external view returns (uint256);
    function totalSupply()      external view returns (uint256);
}

interface UniswapV2PairLike {
    function sync()        external;
    function token0()      external view returns (address);
    function token1()      external view returns (address);
    function getReserves() external view returns (uint112,uint112,uint32);  // reserve0, reserve1, blockTimestampLast
}

interface OracleLike {
    function read() external view returns (uint256);
    function peek() external view returns (uint256,bool);
}

// Factory for creating Uniswap V2 LP Token Oracle instances
contract UNIV2LPOracleFactory {

    mapping(address => bool) public isOracle;

    event Created(address sender, address orcl, bytes32 wat, address tok0, address tok1, address orb0, address orb1);

    // Create new Uniswap V2 LP Token Oracle instance
    function build(address _src, bytes32 _wat, address _orb0, address _orb1) public returns (address orcl) {
        address tok0 = UniswapV2PairLike(_src).token0();
        address tok1 = UniswapV2PairLike(_src).token1();
        orcl = address(new UNIV2LPOracle(_src, _wat, _orb0, _orb1));
        UNIV2LPOracle(orcl).rely(msg.sender);
        isOracle[orcl] = true;
        emit Created(msg.sender, orcl, _wat, tok0, tok1, _orb0, _orb1);
    }
}

contract UNIV2LPOracle {

    // --- Auth ---
    mapping (address => uint) public wards;                                       // Addresses with admin authority
    function rely(address usr) external auth { wards[usr] = 1; emit Rely(usr); }  // Add admin
    function deny(address usr) external auth { wards[usr] = 0; emit Deny(usr); }  // Remove admin
    modifier auth {
        require(wards[msg.sender] == 1, "UNIV2LPOracle/not-authorized");
        _;
    }

    // --- Stop ---
    uint256 public stopped;  // Stop/start ability to read
    modifier stoppable { require(stopped == 0, "UNIV2LPOracle/is-stopped"); _; }

    // --- Whitelisting ---
    mapping (address => uint256) public bud;
    modifier toll { require(bud[msg.sender] == 1, "UNIV2LPOracle/contract-not-whitelisted"); _; }

    // --- Data ---
    uint8   public immutable dec0;  // Decimals of token0
    uint8   public immutable dec1;  // Decimals of token1
    address public           orb0;  // Oracle for token0, ideally a Medianizer
    address public           orb1;  // Oracle for token1, ideally a Medianizer
    bytes32 public immutable wat;   // Token whose price is being tracked

    uint32  public hop = 1 hours;   // Minimum time inbetween price updates
    address public src;             // Price source
    uint32  public zzz;             // Time of last price update

    struct Feed {
        uint128 val;  // Price
        uint128 has;  // Is price valid
    }

    Feed    public cur;  // Current price
    Feed    public nxt;  // Queued price

    // --- Math ---
    uint256 constant WAD = 10 ** 18;

    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
    function div(uint x, uint y) internal pure returns (uint z) {
        require(y > 0 && (z = x / y) * y == x, "ds-math-divide-by-zero");
    }
    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    // Compute the square root using the Babylonian method.
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event Change(address indexed src);
    event Step(uint256 hop);
    event Stop();
    event Start();
    event Value(uint128 curVal, uint128 nxtVal);
    event Link(uint256 id, address orb);

    // --- Init ---
    constructor (address _src, bytes32 _wat, address _orb0, address _orb1) public {
        require(_src  != address(0),                        "UNIV2LPOracle/invalid-src-address");
        require(_orb0 != address(0) && _orb1 != address(0), "UNIV2LPOracle/invalid-oracle-address");
        wards[msg.sender] = 1;
        src  = _src;
        zzz  = 0;
        wat  = _wat;
        dec0 = uint8(ERC20Like(UniswapV2PairLike(_src).token0()).decimals());  // Get decimals of token0
        dec1 = uint8(ERC20Like(UniswapV2PairLike(_src).token1()).decimals());  // Get decimals of token1
        orb0 = _orb0;
        orb1 = _orb1;
    }

    function stop() external auth {
        stopped = 1;
        emit Stop();
    }

    function start() external auth {
        stopped = 0;
        emit Start();
    }

    function change(address _src) external auth {
        src = _src;
        emit Change(src);
    }

    function step(uint256 _hop) external auth {
        require(_hop <= uint32(-1), "UNIV2LPOracle/invalid-hop");
        hop = uint32(_hop);
        emit Step(hop);
    }

    function link(uint256 id, address orb) external auth {
        require(orb != address(0), "UNIV2LPOracle/no-contract-0");
        if(id == 0) {
            orb0 = orb;
        } else if (id == 1) {
            orb1 = orb;
        }
        emit Link(id, orb);
    }

    function pass() public view returns (bool ok) {
        return block.timestamp >= add(zzz, hop);
    }

    function seek() internal returns (uint128 quote, uint32 ts) {
        // Sync up reserves of uniswap liquidity pool
        UniswapV2PairLike(src).sync();

        // Get reserves of uniswap liquidity pool
        (uint112 res0, uint112 res1, uint32 _ts) = UniswapV2PairLike(src).getReserves();
        require(res0 > 0 && res1 > 0, "UNIV2LPOracle/invalid-reserves");
        ts = _ts;
        require(ts == block.timestamp);

        // Adjust reserves w/ respect to decimals
        if (dec0 != uint8(18)) res0 = uint112(res0 * 10 ** sub(18, dec0));
        if (dec1 != uint8(18)) res1 = uint112(res1 * 10 ** sub(18, dec1));

        // Calculate constant product invariant k (WAD * WAD)
        uint256 k = mul(res0, res1);

        // All Oracle prices are priced with 18 decimals against USD
        uint256 val0 = OracleLike(orb0).read();  // Query token0 price from oracle (WAD)
        uint256 val1 = OracleLike(orb1).read();  // Query token1 price from oracle (WAD)
        require(val0 != 0, "UNIV2LPOracle/invalid-oracle-0-price");
        require(val1 != 0, "UNIV2LPOracle/invalid-oracle-1-price");

        // Calculate normalized balances of token0 and token1
        uint256 bal0 =
            sqrt(
                wmul(
                    k,
                    wdiv(
                        val1,
                        val0
                    )
                )
            );
        uint256 bal1 = wdiv(k, bal0) / WAD;

        // Get LP token supply
        uint256 supply = ERC20Like(src).totalSupply();
        require(supply > 0, "UNIV2LPOracle/invalid-lp-token-supply");

        // Calculate price quote of LP token
        quote = uint128(
            wdiv(
                add(
                    wmul(bal0, val0),  // (WAD)
                    wmul(bal1, val1)   // (WAD)
                ),
                supply  // (WAD)
            )
        );
    }

    function poke() external stoppable {
        require(pass(), "UNIV2LPOracle/not-passed");
        (uint val, uint32 ts) = seek();
        require(val != 0, "UNIV2LPOracle/invalid-price");
        cur = nxt;
        nxt = Feed(uint128(val), 1);
        zzz = ts;
        emit Value(cur.val, nxt.val);
    }

    function peek() external view toll returns (bytes32,bool) {
        return (bytes32(uint(cur.val)), cur.has == 1);
    }

    function peep() external view toll returns (bytes32,bool) {
        return (bytes32(uint(nxt.val)), nxt.has == 1);
    }

    function read() external view toll returns (bytes32) {
        require(cur.has == 1, "UNIV2LPOracle/no-current-value");
        return (bytes32(uint(cur.val)));
    }

    function kiss(address a) external auth {
        require(a != address(0), "UNIV2LPOracle/no-contract-0");
        bud[a] = 1;
    }

    function kiss(address[] calldata a) external auth {
        for(uint i = 0; i < a.length; i++) {
            require(a[i] != address(0), "UNIV2LPOracle/no-contract-0");
            bud[a[i]] = 1;
        }
    }

    function diss(address a) external auth {
        bud[a] = 0;
    }

    function diss(address[] calldata a) external auth {
        for(uint i = 0; i < a.length; i++) {
            bud[a[i]] = 0;
        }
    }
}