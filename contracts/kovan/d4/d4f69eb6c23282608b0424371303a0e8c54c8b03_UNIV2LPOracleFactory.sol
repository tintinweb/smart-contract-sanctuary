/**
 *Submitted for verification at Etherscan.io on 2021-05-14
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

// A naïve approach to calculate the price of LP tokens, assuming the protocol
// fee is zero, is to compute the price of the assets locked in its liquidity
// pool, and divide it by the total amount of LP tokens issued:
//
// (p_0 * r_0 + p_1 * r_1) / LP_supply              (1)
//
// where r_0 and r_1 are the reserves of the two tokens held by the pool, and
// p_0 and p_1 are their respective prices in some reference unit of account.
//
// However, the price of LP tokens (i.e. pool shares) needs to be evaluated
// based on reserve values r_0 and r_1 that cannot be arbitraged, i.e. values
// that give the two halves of the pool equal economic value:
//
// r_0 * p_0 = r_1 * p_1                            (2)
// 
// Furthermore, two-asset constant product pools, neglecting fees, satisfy
// (before and after trades):
//
// r_0 * r_1 = k                                    (3)
//
// Using (2) and (3) we can compute R_i, the arbitrage-free reserve values, in a
// manner that depends only on k (which can be derived from the current reserve
// balances, even if they are far from equilibrium) and market prices p_i
// obtained from a trusted source:
//
// R_0 = sqrt(k * p_1 / p_0)                        (4)
//   and
// R_1 = sqrt(k * p_0 / p_1)                        (5)
//
// The value of an LP token is then, replacing (4) and (5) in (1):
//
// (p_0 * R_0 + p_1 * R_1) / LP_supply
//     = 2 * sqrt(k * p_0 * p_1) / LP_supply        (6)
//
// k can be re-expressed in terms of the current pool reserves r_0 and r_1:
//
// 2 * sqrt((r_0 * p_0) * (r_1 * p_1)) / LP_supply  (7)
//
// The structure of (7) is well-suited for use in fixed-point EVM calculations, as the
// terms (r_0 * p_0) and (r_1 * p_1), being the values of the reserves in the reference unit,
// should have reasonably-bounded sizes. This reduces the likelihood of overflow due to
// tokens with very low prices but large total supplies.

pragma solidity =0.6.12;

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
}

// Factory for creating Uniswap V2 LP Token Oracle instances
contract UNIV2LPOracleFactory {

    mapping(address => bool) public isOracle;

    event NewUNIV2LPOracle(address owner, address orcl, bytes32 wat, address indexed tok0, address indexed tok1, address orb0, address orb1);

    // Create new Uniswap V2 LP Token Oracle instance
    function build(
        address _owner,
        address _src,
        bytes32 _wat,
        address _orb0,
        address _orb1
        ) public returns (address orcl) {
        address tok0 = UniswapV2PairLike(_src).token0();
        address tok1 = UniswapV2PairLike(_src).token1();
        orcl = address(new UNIV2LPOracle(_src, _wat, _orb0, _orb1));
        UNIV2LPOracle(orcl).rely(_owner);
        UNIV2LPOracle(orcl).deny(address(this));
        isOracle[orcl] = true;
        emit NewUNIV2LPOracle(_owner, orcl, _wat, tok0, tok1, _orb0, _orb1);
    }
}

contract UNIV2LPOracle {

    // --- Auth ---
    mapping (address => uint256) public wards;                                       // Addresses with admin authority
    function rely(address _usr) external auth { wards[_usr] = 1; emit Rely(_usr); }  // Add admin
    function deny(address _usr) external auth { wards[_usr] = 0; emit Deny(_usr); }  // Remove admin
    modifier auth {
        require(wards[msg.sender] == 1, "UNIV2LPOracle/not-authorized");
        _;
    }

    address public immutable src;   // Price source

    // hop and zph are packed into single slot to reduce SLOADs;
    // this outweighs the cost from added bitmasking operations.
    uint8   public stopped;         // Stop/start ability to update
    uint16  public hop = 1 hours;   // Minimum time in between price updates
    uint232 public zph;             // Time of last price update plus hop

    bytes32 public immutable wat;   // Label of token whose price is being tracked

    // --- Whitelisting ---
    mapping (address => uint256) public bud;
    modifier toll { require(bud[msg.sender] == 1, "UNIV2LPOracle/contract-not-whitelisted"); _; }

    struct Feed {
        uint128 val;  // Price
        uint128 has;  // Is price valid
    }

    Feed    internal cur;  // Current price  (mem slot 0x3)
    Feed    internal nxt;  // Queued price   (mem slot 0x4)

    // --- Data ---
    uint256 private immutable UNIT_0;  // Numerical representation of one token of token0 (10^decimals) 
    uint256 private immutable UNIT_1;  // Numerical representation of one token of token1 (10^decimals) 

    address public            orb0;  // Oracle for token0, ideally a Medianizer
    address public            orb1;  // Oracle for token1, ideally a Medianizer

    // --- Math ---
    uint256 constant WAD = 10 ** 18;

    function add(uint256 _x, uint256 _y) internal pure returns (uint256 z) {
        require((z = _x + _y) >= _x, "UNIV2LPOracle/add-overflow");
    }
    function sub(uint256 _x, uint256 _y) internal pure returns (uint256 z) {
        require((z = _x - _y) <= _x, "UNIV2LPOracle/sub-underflow");
    }
    function mul(uint256 _x, uint256 _y) internal pure returns (uint256 z) {
        require(_y == 0 || (z = _x * _y) / _y == _x, "UNIV2LPOracle/mul-overflow");
    }

    // FROM https://github.com/abdk-consulting/abdk-libraries-solidity/blob/16d7e1dd8628dfa2f88d5dadab731df7ada70bdd/ABDKMath64x64.sol#L687
    function sqrt (uint256 _x) private pure returns (uint128) {
        if (_x == 0) return 0;
        else {
            uint256 xx = _x;
            uint256 r = 1;
            if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
            if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
            if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
            if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
            if (xx >= 0x100) { xx >>= 8; r <<= 4; }
            if (xx >= 0x10) { xx >>= 4; r <<= 2; }
            if (xx >= 0x8) { r <<= 1; }
            r = (r + _x / r) >> 1;
            r = (r + _x / r) >> 1;
            r = (r + _x / r) >> 1;
            r = (r + _x / r) >> 1;
            r = (r + _x / r) >> 1;
            r = (r + _x / r) >> 1;
            r = (r + _x / r) >> 1; // Seven iterations should be enough
            uint256 r1 = _x / r;
            return uint128 (r < r1 ? r : r1);
        }
    }

    // --- Events ---
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event Step(uint256 hop);
    event Stop();
    event Start();
    event Value(uint128 curVal, uint128 nxtVal);
    event Link(uint256 id, address orb);
    event Kiss(address a);
    event Diss(address a);

    // --- Init ---
    constructor (address _src, bytes32 _wat, address _orb0, address _orb1) public {
        require(_src  != address(0),                        "UNIV2LPOracle/invalid-src-address");
        require(_orb0 != address(0) && _orb1 != address(0), "UNIV2LPOracle/invalid-oracle-address");
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
        src  = _src;
        wat  = _wat;
        uint256 dec0 = uint256(ERC20Like(UniswapV2PairLike(_src).token0()).decimals());
        require(dec0 <= 18, "UNIV2LPOracle/token0-dec-gt-18");
        UNIT_0 = 10 ** dec0;
        uint256 dec1 = uint256(ERC20Like(UniswapV2PairLike(_src).token1()).decimals());
        require(dec1 <= 18, "UNIV2LPOracle/token1-dec-gt-18");
        UNIT_1 = 10 ** dec1;
        orb0 = _orb0;
        orb1 = _orb1;
    }

    function stop() external auth {
        stopped = 1;
        delete cur;
        delete nxt;
        zph = 0;
        emit Stop();
    }

    function start() external auth {
        stopped = 0;
        emit Start();
    }

    function step(uint256 _hop) external auth {
        require(_hop <= uint16(-1), "UNIV2LPOracle/invalid-hop");
        hop = uint16(_hop);
        emit Step(_hop);
    }

    function link(uint256 _id, address _orb) external auth {
        require(_orb != address(0), "UNIV2LPOracle/no-contract-0");
        if(_id == 0) {
            orb0 = _orb;
        } else if (_id == 1) {
            orb1 = _orb;
        } else {
            revert("UNIV2LPOracle/invalid-id");
        }
        emit Link(_id, _orb);
    }

    // For consistency with other oracles.
    function zzz() external view returns (uint256) {
        if (zph == 0) return 0;  // backwards compatibility
        return sub(zph, hop);
    }

    function pass() external view returns (bool) {
        return block.timestamp >= zph;
    }

    function seek() internal returns (uint128 quote) {
        // Sync up reserves of uniswap liquidity pool
        UniswapV2PairLike(src).sync();

        // Get reserves of uniswap liquidity pool
        (uint112 r0, uint112 r1,) = UniswapV2PairLike(src).getReserves();
        require(r0 > 0 && r1 > 0, "UNIV2LPOracle/invalid-reserves");

        // All Oracle prices are priced with 18 decimals against USD
        uint256 p0 = OracleLike(orb0).read();  // Query token0 price from oracle (WAD)
        require(p0 != 0, "UNIV2LPOracle/invalid-oracle-0-price");
        uint256 p1 = OracleLike(orb1).read();  // Query token1 price from oracle (WAD)
        require(p1 != 0, "UNIV2LPOracle/invalid-oracle-1-price");

        // Get LP token supply
        uint256 supply = ERC20Like(src).totalSupply();

        // This calculation should be overflow-resistant even for tokens with very high or very
        // low prices, as the dollar value of each reserve should lie in a fairly controlled range
        // regardless of the token prices.
        uint256 value0 = mul(p0, uint256(r0)) / UNIT_0;  // WAD
        uint256 value1 = mul(p1, uint256(r1)) / UNIT_1;  // WAD
        uint256 preq = mul(2 * WAD, sqrt(mul(value0, value1))) / supply;  // Will revert if supply == 0
        require(preq < 2 ** 128, "UNIV2LPOracle/quote-overflow");
        quote = uint128(preq);  // WAD
    }

    function poke() external {

        // Ensure a single SLOAD while avoiding solc's excessive bitmasking bureaucracy.
        uint256 hop_;
        {

            // Block-scoping these variables saves some gas.
            uint256 stopped_;
            uint256 zph_;
            assembly {
                let slot1 := sload(1)
                stopped_  := and(slot1,         0xff  )
                hop_      := and(shr(8, slot1), 0xffff)
                zph_      := shr(24, slot1)
            }

            // When stopped, values are set to zero and should remain such; thus, disallow updating in that case.
            require(stopped_ == 0, "UNIV2LPOracle/is-stopped");

            // Equivalent to requiring that pass() returns true.
            // The logic is repeated instead of calling pass() to save gas
            // (both by eliminating an internal call here, and allowing pass to be external).
            require(block.timestamp >= zph_, "UNIV2LPOracle/not-passed");
        }

        uint128 val = seek();
        require(val != 0, "UNIV2LPOracle/invalid-price");
        Feed memory cur_ = nxt;  // This memory value is used to save an SLOAD later.
        cur = cur_;
        nxt = Feed(val, 1);

        // The below is equivalent to:
        //
        //    zph = block.timestamp + hop
        //
        // but ensures no extra SLOADs are performed.
        //
        // Even if _hop = (2^16 - 1), the maximum possible value, add(timestamp(), _hop)
        // will not overflow (even a 232 bit value) for a very long time.
        //
        // Also, we know stopped was zero, so there is no need to account for it explicitly here.
        assembly {
            sstore(
                1,
                add(
                    // zph value starts 24 bits in
                    shl(24, add(timestamp(), hop_)),

                    // hop value starts 8 bits in
                    shl(8, hop_)
                )
            )
        }

        // Equivalent to emitting Value(cur.val, nxt.val), but averts extra SLOADs.
        emit Value(cur_.val, val);

        // Safe to terminate immediately since no postfix modifiers are applied.
        assembly {
            stop()
        }
    }

    function peek() external view toll returns (bytes32,bool) {
        return (bytes32(uint256(cur.val)), cur.has == 1);
    }

    function peep() external view toll returns (bytes32,bool) {
        return (bytes32(uint256(nxt.val)), nxt.has == 1);
    }

    function read() external view toll returns (bytes32) {
        require(cur.has == 1, "UNIV2LPOracle/no-current-value");
        return (bytes32(uint256(cur.val)));
    }

    function kiss(address _a) external auth {
        require(_a != address(0), "UNIV2LPOracle/no-contract-0");
        bud[_a] = 1;
        emit Kiss(_a);
    }

    function kiss(address[] calldata _a) external auth {
        for(uint256 i = 0; i < _a.length; i++) {
            require(_a[i] != address(0), "UNIV2LPOracle/no-contract-0");
            bud[_a[i]] = 1;
            emit Kiss(_a[i]);
        }
    }

    function diss(address _a) external auth {
        bud[_a] = 0;
        emit Diss(_a);
    }

    function diss(address[] calldata _a) external auth {
        for(uint256 i = 0; i < _a.length; i++) {
            bud[_a[i]] = 0;
            emit Diss(_a[i]);
        }
    }
}