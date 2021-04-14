/**
 *Submitted for verification at Etherscan.io on 2021-04-13
*/

// SPDX-License-Identifier: AGPL-3.0-or-later

/// DssAutoLine.sol

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
pragma solidity ^0.6.11;

interface VatLike {
    function ilks(bytes32) external view returns (uint256, uint256, uint256, uint256, uint256);
    function Line() external view returns (uint256);
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
}

contract DssAutoLine {
    /*** Data ***/
    struct Ilk {
        uint256   line;  // Max ceiling possible                                               [rad]
        uint256    gap;  // Max Value between current debt and line to be set                  [rad]
        uint48     ttl;  // Min time to pass before a new increase                             [seconds]
        uint48    last;  // Last block the ceiling was updated                                 [blocks]
        uint48 lastInc;  // Last time the ceiling was increased compared to its previous value [seconds]
    }

    mapping (bytes32 => Ilk)     public ilks;
    mapping (address => uint256) public wards;

    VatLike immutable public vat;

    /*** Events ***/
    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event Setup(bytes32 indexed ilk, uint256 line, uint256 gap, uint256 ttl);
    event Remove(bytes32 indexed ilk);
    event Exec(bytes32 indexed ilk, uint256 line, uint256 lineNew);

    /*** Init ***/
    constructor(address vat_) public {
        vat = VatLike(vat_);
        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    /*** Math ***/
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

    /*** Administration ***/

    /**
        @dev Add or update an ilk
        @param ilk    Collateral type (ex. ETH-A)
        @param line   Collateral maximum debt ceiling that can be configured [RAD]
        @param gap    Amount of collateral to step [RAD]
        @param ttl    Minimum time between increase [seconds]
    */
    function setIlk(bytes32 ilk, uint256 line, uint256 gap, uint256 ttl) external auth {
        require(ttl  < uint48(-1), "DssAutoLine/invalid-ttl");
        require(line > 0,          "DssAutoLine/invalid-line");
        ilks[ilk] = Ilk(line, gap, uint48(ttl), 0, 0);
        emit Setup(ilk, line, gap, ttl);
    }

    /**
        @dev Remove an ilk
        @param ilk    Collateral type (ex. ETH-A)
    */
    function remIlk(bytes32 ilk) external auth {
        delete ilks[ilk];
        emit Remove(ilk);
    }

    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }

    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    modifier auth {
        require(wards[msg.sender] == 1, "DssAutoLine/not-authorized");
        _;
    }

    /*** Auto-Line Update ***/
    // @param  _ilk  The bytes32 ilk tag to adjust (ex. "ETH-A")
    // @return       The ilk line value as uint256
    function exec(bytes32 _ilk) external returns (uint256) {
        (uint256 Art, uint256 rate,, uint256 line,) = vat.ilks(_ilk);
        uint256 ilkLine = ilks[_ilk].line;

        // Return if the ilk is not enabled
        if (ilkLine == 0) return line;

        // 1 SLOAD
        uint48 ilkTtl     = ilks[_ilk].ttl;
        uint48 ilkLast    = ilks[_ilk].last;
        uint48 ilkLastInc = ilks[_ilk].lastInc;
        //

        // Return if there was already an update in the same block
        if (ilkLast == block.number) return line;

        // Calculate collateral debt
        uint256 debt = mul(Art, rate);

        uint256 ilkGap  = ilks[_ilk].gap;

        // Calculate new line based on the minimum between the maximum line and actual collateral debt + gap
        uint256 lineNew = min(add(debt, ilkGap), ilkLine);

        // Short-circuit if there wasn't an update or if the time since last increment has not passed
        if (lineNew == line || lineNew > line && block.timestamp < add(ilkLastInc, ilkTtl)) return line;

        // Set collateral debt ceiling
        vat.file(_ilk, "line", lineNew);
        // Set general debt ceiling
        vat.file("Line", add(sub(vat.Line(), line), lineNew));

        // Update lastInc if it is an increment in the debt ceiling
        // and update last whatever the update is
        if (lineNew > line) {
            // 1 SSTORE
            ilks[_ilk].lastInc = uint48(block.timestamp);
            ilks[_ilk].last    = uint48(block.number);
            //
        } else {
            ilks[_ilk].last    = uint48(block.number);
        }

        emit Exec(_ilk, line, lineNew);

        return lineNew;
    }
}