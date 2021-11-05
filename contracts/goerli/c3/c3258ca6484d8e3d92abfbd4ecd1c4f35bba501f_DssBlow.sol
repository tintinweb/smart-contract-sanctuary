/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright (C) 2021 Dai Foundation
//
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

pragma solidity ^0.6.12;

interface DaiLike {
    function balanceOf(address) external returns (uint256);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
}
    
interface DaiJoinLike {
    function dai() external view returns (address);
    function join(address, uint256) external;
}

contract DssBlow {

    DaiJoinLike public immutable daiJoin;
    DaiLike     public immutable dai;
    address     public immutable vow;

    // --- Events ---
    event Blow(uint256 amount);

    // --- Init ---
    constructor(address daiJoin_, address vow_) public { 
        daiJoin = DaiJoinLike(daiJoin_);
        DaiLike dai_ = dai = DaiLike(DaiJoinLike(daiJoin_).dai());
        vow = vow_;
    }

    // Send Dai deposited in this contract to the `vow`
    function blow() public {
        uint256 balance = dai.balanceOf(address(this));
        dai.transferFrom(address(this), vow, balance);
        emit Blow(balance);
    }

    // Send `wad` amount of Dai from your wallet to the `vow`
    function blow(uint256 wad) public {
        dai.transferFrom(msg.sender, vow, wad);
        emit Blow(wad);
    }
}