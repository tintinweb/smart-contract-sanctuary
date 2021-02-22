/**
 *Submitted for verification at Etherscan.io on 2021-02-21
*/

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

pragma solidity ^0.6.11;

interface OsmLike {
    function poke() external;
    function pass() external view returns (bool);
}

interface SpotLike {
    function poke(bytes32) external;
}

contract MegaPoker {
    OsmLike constant eth          = OsmLike(0x81FE72B5A8d1A857d176C3E7d5Bd2679A9B85763);
    OsmLike constant bat          = OsmLike(0xB4eb54AF9Cc7882DF0121d26c5b97E802915ABe6);
    OsmLike constant btc          = OsmLike(0xf185d0682d50819263941e5f4EacC763CC5C6C42);
    OsmLike constant knc          = OsmLike(0xf36B79BD4C0904A5F350F1e4f776B81208c13069);
    OsmLike constant zrx          = OsmLike(0x7382c066801E7Acb2299aC8562847B9883f5CD3c);
    OsmLike constant mana         = OsmLike(0x8067259EA630601f319FccE477977E55C6078C13);
    OsmLike constant usdt         = OsmLike(0x7a5918670B0C390aD25f7beE908c1ACc2d314A3C);
    OsmLike constant comp         = OsmLike(0xBED0879953E633135a48a157718Aa791AC0108E4);
    OsmLike constant link         = OsmLike(0x9B0C694C6939b5EA9584e9b61C7815E8d97D9cC7);
    OsmLike constant lrc          = OsmLike(0x9eb923339c24c40Bef2f4AF4961742AA7C23EF3a);
    OsmLike constant yfi          = OsmLike(0x5F122465bCf86F45922036970Be6DD7F58820214);
    OsmLike constant bal          = OsmLike(0x3ff860c0F28D69F392543A16A397D0dAe85D16dE);
    OsmLike constant uni          = OsmLike(0xf363c7e351C96b910b92b45d34190650df4aE8e7);
    OsmLike constant aave         = OsmLike(0x8Df8f06DC2dE0434db40dcBb32a82A104218754c);
    OsmLike constant univ2daieth  = OsmLike(0x87ecBd742cEB40928E6cDE77B2f0b5CFa3342A09);
    OsmLike constant univ2wbtceth = OsmLike(0x771338D5B31754b25D2eb03Cea676877562Dec26);
    OsmLike constant univ2usdceth = OsmLike(0xECB03Fec701B93DC06d19B4639AA8b5a838472BE);
    OsmLike constant univ2daiusdc = OsmLike(0x25CD858a00146961611b18441353603191f110A0);
    OsmLike constant univ2ethusdt = OsmLike(0x9b015AA3e4787dd0df8B43bF2FE6d90fa543E13B);
    OsmLike constant univ2linketh = OsmLike(0x628009F5F5029544AE84636Ef676D3Cc5755238b);
    OsmLike constant univ2unieth  = OsmLike(0x8Ce9E9442F2791FC63CD6394cC12F2dE4fbc1D71);
    OsmLike constant univ2wbtcdai = OsmLike(0x5FB5a346347ACf4FCD3AAb28f5eE518785FB0AD0);
    OsmLike constant univ2aaveeth = OsmLike(0x8D34DC2c33A6386E96cA562D8478Eaf82305b81a);
    SpotLike constant spot        = SpotLike(0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3);

    function process() internal {
        if (         eth.pass())           eth.poke();
        if (         bat.pass())           bat.poke();
        if (         btc.pass())           btc.poke();
        if (         knc.pass())           knc.poke();
        if (         zrx.pass())           zrx.poke();
        if (        mana.pass())          mana.poke();
        if (        usdt.pass())          usdt.poke();
        if (        comp.pass())          comp.poke();
        if (        link.pass())          link.poke();
        if (         lrc.pass())           lrc.poke();
        if (         yfi.pass())           yfi.poke();
        if (         bal.pass())           bal.poke();
        if (         uni.pass())           uni.poke();
        if (        aave.pass())          aave.poke();
        if ( univ2daieth.pass())   univ2daieth.poke();
        if (univ2wbtceth.pass())  univ2wbtceth.poke();
        if (univ2usdceth.pass())  univ2usdceth.poke();
        if (univ2daiusdc.pass())  univ2daiusdc.poke();
        if (univ2ethusdt.pass())  univ2ethusdt.poke();
        if (univ2linketh.pass())  univ2linketh.poke();
        if ( univ2unieth.pass())   univ2unieth.poke();

        spot.poke("ETH-A");
        spot.poke("BAT-A");
        spot.poke("WBTC-A");
        spot.poke("KNC-A");
        spot.poke("ZRX-A");
        spot.poke("MANA-A");
        spot.poke("USDT-A");
        spot.poke("COMP-A");
        spot.poke("LINK-A");
        spot.poke("LRC-A");
        spot.poke("ETH-B");
        spot.poke("YFI-A");
        spot.poke("BAL-A");
        spot.poke("RENBTC-A");
        spot.poke("UNI-A");
        spot.poke("AAVE-A");
        spot.poke("UNIV2DAIETH-A");
        spot.poke("UNIV2WBTCETH-A");
        spot.poke("UNIV2USDCETH-A");
        spot.poke("UNIV2DAIUSDC-A");
        spot.poke("UNIV2ETHUSDT-A");
        spot.poke("UNIV2LINKETH-A");
        spot.poke("UNIV2UNIETH-A");
    }

    function poke() external {
        process();

        if (univ2wbtcdai.pass())  univ2wbtcdai.poke();
        if (univ2aaveeth.pass())  univ2aaveeth.poke();

        spot.poke("UNIV2WBTCDAI-A");
        spot.poke("UNIV2AAVEETH-A");
    }

    // Use for poking OSMs prior to collateral being added
    function pokeTemp() external {
        process();
    }
}