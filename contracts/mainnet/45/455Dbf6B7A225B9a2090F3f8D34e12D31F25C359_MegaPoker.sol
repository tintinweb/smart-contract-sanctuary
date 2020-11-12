// SPDX-License-Identifier: AGPL-3.0
// The MegaPoker
//
// Copyright (C) 2020 Maker Ecosystem Growth Holdings, INC.
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

pragma solidity >=0.5.12;

interface OsmLike {
    function poke() external;
    function pass() external view returns (bool);
}

interface SpotLike {
    function poke(bytes32) external;
}

contract MegaPoker {
    OsmLike constant eth = OsmLike(0x81FE72B5A8d1A857d176C3E7d5Bd2679A9B85763);
    OsmLike constant bat = OsmLike(0xB4eb54AF9Cc7882DF0121d26c5b97E802915ABe6);
    OsmLike constant wbtc = OsmLike(0xf185d0682d50819263941e5f4EacC763CC5C6C42);
    OsmLike constant knc = OsmLike(0xf36B79BD4C0904A5F350F1e4f776B81208c13069);
    OsmLike constant zrx = OsmLike(0x7382c066801E7Acb2299aC8562847B9883f5CD3c);
    OsmLike constant mana = OsmLike(0x8067259EA630601f319FccE477977E55C6078C13);
    OsmLike constant usdt = OsmLike(0x7a5918670B0C390aD25f7beE908c1ACc2d314A3C);
    SpotLike constant spot = SpotLike(0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3);

    function poke() external {
        if (eth.pass()) eth.poke();
        if (bat.pass()) bat.poke();
        if (wbtc.pass()) wbtc.poke();
        if (knc.pass()) knc.poke();
        if (zrx.pass()) zrx.poke();
        if (mana.pass()) mana.poke();
        if (usdt.pass()) usdt.poke();

        spot.poke("ETH-A");
        spot.poke("BAT-A");
        spot.poke("WBTC-A");
        spot.poke("KNC-A");
        spot.poke("ZRX-A");
        spot.poke("MANA-A");
        spot.poke("USDT-A");
    }
}