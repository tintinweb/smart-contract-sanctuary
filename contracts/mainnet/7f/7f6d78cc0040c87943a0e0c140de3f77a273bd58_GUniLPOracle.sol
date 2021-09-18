/**
 *Submitted for verification at Etherscan.io on 2021-09-17
*/

// SPDX-License-Identifier: AGPL-3.0-or-later

/// GUniLPOracle.sol

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

// We derive the sqrtPriceX96 via Maker's own oracles to prevent price manipulation in the pool:
// 
// p0 = price of token0 in USD
// p1 = price of token1 in USD
// UNITS_0 = decimals of token0
// UNITS_1 = decimals of token1
// 
// token1/token0 = (p0 / 10^UNITS_0) / (p1 / 10^UNITS_1)               [Conversion from Maker's price ratio into Uniswap's format]
//               = (p0 * 10^UNITS_1) / (p1 * 10^UNITS_0)
// 
// sqrtPriceX96 = sqrt(token1/token0) * 2^96                           [From Uniswap's definition]
//              = sqrt((p0 * 10^UNITS_1) / (p1 * 10^UNITS_0)) * 2^96
//              = sqrt((p0 * 10^UNITS_1) / (p1 * 10^UNITS_0)) * 2^48 * 2^48
//              = sqrt((p0 * 10^UNITS_1 * 2^96) / (p1 * 10^UNITS_0)) * 2^48
// 
// Once we have the sqrtPriceX96 we can use that to compute the fair reserves for each token. This part may be slightly subjective
// depending on the implementation, but we expect most tokens to provide something like getUnderlyingBalancesAtPrice(uint160 sqrtPriceX96)
// which will forward our oracle-calculated `sqrtPriceX96` to the Uniswap-provided LiquidityAmounts.getAmountsForLiquidity(...)
// This function will return the fair reserves for each token. Vendor-specific logic is then used to tack any uninvested fees on top of those amounts.
// 
// Once we have the fair reserves and the prices we can compute the token price by:
// 
// Token Price = TVL / Token Supply
//             = (r0 * p0 + r1 * p1) / totalSupply

pragma solidity =0.6.12;

interface ERC20Like {
    function decimals()                 external view returns (uint8);
    function totalSupply()              external view returns (uint256);
}

interface GUNILike {
    function token0()                               external view returns (address);
    function token1()                               external view returns (address);
    function getUnderlyingBalancesAtPrice(uint160)  external view returns (uint256,uint256);
}

interface OracleLike {
    function read() external view returns (uint256);
}

contract GUniLPOracle {

    // --- Auth ---
    mapping (address => uint256) public wards;                                       // Addresses with admin authority
    function rely(address _usr) external auth { wards[_usr] = 1; emit Rely(_usr); }  // Add admin
    function deny(address _usr) external auth { wards[_usr] = 0; emit Deny(_usr); }  // Remove admin
    modifier auth {
        require(wards[msg.sender] == 1, "GUniLPOracle/not-authorized");
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
    modifier toll { require(bud[msg.sender] == 1, "GUniLPOracle/contract-not-whitelisted"); _; }

    struct Feed {
        uint128 val;  // Price
        uint128 has;  // Is price valid
    }

    Feed    internal cur;  // Current price  (mem slot 0x3)
    Feed    internal nxt;  // Queued price   (mem slot 0x4)

    // --- Data ---
    uint256 private immutable UNIT_0;  // Numerical representation of one token of token0 (10^decimals) 
    uint256 private immutable UNIT_1;  // Numerical representation of one token of token1 (10^decimals) 
    uint256 private immutable TO_18_DEC_0;  // Conversion factor to 18 decimals
    uint256 private immutable TO_18_DEC_1;  // Conversion factor to 18 decimals

    address public            orb0;  // Oracle for token0, ideally a Medianizer
    address public            orb1;  // Oracle for token1, ideally a Medianizer

    // --- Math ---
    uint256 constant WAD = 10 ** 18;

    function _add(uint256 _x, uint256 _y) internal pure returns (uint256 z) {
        require((z = _x + _y) >= _x, "GUniLPOracle/add-overflow");
    }
    function _sub(uint256 _x, uint256 _y) internal pure returns (uint256 z) {
        require((z = _x - _y) <= _x, "GUniLPOracle/sub-underflow");
    }
    function _mul(uint256 _x, uint256 _y) internal pure returns (uint256 z) {
        require(_y == 0 || (z = _x * _y) / _y == _x, "GUniLPOracle/mul-overflow");
    }
    function toUint160(uint256 x) internal pure returns (uint160 z) {
        require((z = uint160(x)) == x, "GUniLPOracle/uint160-overflow");
    }

    // FROM https://github.com/abdk-consulting/abdk-libraries-solidity/blob/16d7e1dd8628dfa2f88d5dadab731df7ada70bdd/ABDKMath64x64.sol#L687
    function sqrt(uint256 _x) private pure returns (uint128) {
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
        require(_src  != address(0),                        "GUniLPOracle/invalid-src-address");
        require(_orb0 != address(0) && _orb1 != address(0), "GUniLPOracle/invalid-oracle-address");
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
        src  = _src;
        wat  = _wat;
        uint256 dec0 = uint256(ERC20Like(GUNILike(_src).token0()).decimals());
        require(dec0 <= 18, "GUniLPOracle/token0-dec-gt-18");
        UNIT_0 = 10 ** dec0;
        TO_18_DEC_0 = 10 ** (18 - dec0);
        uint256 dec1 = uint256(ERC20Like(GUNILike(_src).token1()).decimals());
        require(dec1 <= 18, "GUniLPOracle/token1-dec-gt-18");
        UNIT_1 = 10 ** dec1;
        TO_18_DEC_1 = 10 ** (18 - dec1);
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
        require(_hop <= uint16(-1), "GUniLPOracle/invalid-hop");
        hop = uint16(_hop);
        emit Step(_hop);
    }

    function link(uint256 _id, address _orb) external auth {
        require(_orb != address(0), "GUniLPOracle/no-contract-0");
        if(_id == 0) {
            orb0 = _orb;
        } else if (_id == 1) {
            orb1 = _orb;
        } else {
            revert("GUniLPOracle/invalid-id");
        }
        emit Link(_id, _orb);
    }

    // For consistency with other oracles.
    function zzz() external view returns (uint256) {
        if (zph == 0) return 0;  // backwards compatibility
        return _sub(zph, hop);
    }

    function pass() external view returns (bool) {
        return block.timestamp >= zph;
    }

    function seek() internal returns (uint128 quote) {
        // All Oracle prices are priced with 18 decimals against USD
        uint256 p0 = OracleLike(orb0).read();  // Query token0 price from oracle (WAD)
        require(p0 != 0, "GUniLPOracle/invalid-oracle-0-price");
        uint256 p1 = OracleLike(orb1).read();  // Query token1 price from oracle (WAD)
        require(p1 != 0, "GUniLPOracle/invalid-oracle-1-price");
        uint160 sqrtPriceX96 = toUint160(sqrt(_mul(_mul(p0, UNIT_1), (1 << 96)) / (_mul(p1, UNIT_0))) << 48);

        // Get balances of the tokens in the pool
        (uint256 r0, uint256 r1) = GUNILike(src).getUnderlyingBalancesAtPrice(sqrtPriceX96);
        require(r0 > 0 || r1 > 0, "GUniLPOracle/invalid-balances");
        uint256 totalSupply = ERC20Like(src).totalSupply();
        require(totalSupply >= 1e9, "GUniLPOracle/total-supply-too-small"); // Protect against precision errors with dust-levels of collateral

        // Add the total value of each token together and divide by the totalSupply to get the unit price
        uint256 preq = _add(
            _mul(p0, _mul(r0, TO_18_DEC_0)),
            _mul(p1, _mul(r1, TO_18_DEC_1))
        ) / totalSupply;
        require(preq < 2 ** 128, "GUniLPOracle/quote-overflow");
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
            require(stopped_ == 0, "GUniLPOracle/is-stopped");

            // Equivalent to requiring that pass() returns true.
            // The logic is repeated instead of calling pass() to save gas
            // (both by eliminating an internal call here, and allowing pass to be external).
            require(block.timestamp >= zph_, "GUniLPOracle/not-passed");
        }

        uint128 val = seek();
        require(val != 0, "GUniLPOracle/invalid-price");
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
        require(cur.has == 1, "GUniLPOracle/no-current-value");
        return (bytes32(uint256(cur.val)));
    }

    function kiss(address _a) external auth {
        require(_a != address(0), "GUniLPOracle/no-contract-0");
        bud[_a] = 1;
        emit Kiss(_a);
    }

    function kiss(address[] calldata _a) external auth {
        for(uint256 i = 0; i < _a.length; i++) {
            require(_a[i] != address(0), "GUniLPOracle/no-contract-0");
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