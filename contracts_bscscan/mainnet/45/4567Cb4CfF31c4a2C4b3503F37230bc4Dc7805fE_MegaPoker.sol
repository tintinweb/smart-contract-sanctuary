/**
 *Submitted for verification at BscScan.com on 2021-09-10
*/

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

interface OsmMedianLike {
    function poke() external;
}

interface SpotLike {
    function poke(bytes32) external;
}

contract MegaPoker {
    SpotLike constant spot        = SpotLike(0xE674a2A49B891eE17BA3551FA5BaAF05F97fc323);

    OsmMedianLike constant bnb_osm_median      = OsmMedianLike(0x640962E483e29Bafd5D324B982E721BEF125511D);
    OsmMedianLike constant eth_osm_median      = OsmMedianLike(0x3ECa830d9fA87B7998986d97d37BAc5B3123e2d7);
    OsmMedianLike constant btcb_osm_median     = OsmMedianLike(0x0D75a3c83C6692519fC5F37bcb70F29c155811c3);
    OsmMedianLike constant busd_osm_median     = OsmMedianLike(0xDd22bf0Beb6F1Fe88656C7D579087F3B755b1a10);
    
    OsmLike constant bnb_osm      = OsmLike(0x0d9C1686419D3B18fbd2F088CF7949b4905f779c);
    OsmLike constant eth_osm      = OsmLike(0xDE55FCC8Ceb62BB9FA98b21E7e620EBB3A617EAC);
    OsmLike constant btcb_osm     = OsmLike(0x61f75e44aA95DA470851945b0d083B530Ab73391);
    OsmLike constant busd_osm     = OsmLike(0x6113053F2fE42e03059DE480cD8a6Bdd8ea3494c);
   
    function process(bool withMedian) internal {
        if(withMedian){
            bnb_osm_median.poke();
            eth_osm_median.poke();
            btcb_osm_median.poke();
            busd_osm_median.poke();
        }

        if (bnb_osm.pass())           bnb_osm.poke();
        if (eth_osm.pass())           eth_osm.poke();
        if (btcb_osm.pass())          btcb_osm.poke();
        if (busd_osm.pass())          busd_osm.poke();

        spot.poke("BNB-A");
        spot.poke("BNB-B");
        spot.poke("ETH-A");
        spot.poke("ETH-B");
        spot.poke("BTCB-A");
        spot.poke("BTCB-B");
        spot.poke("BUSD-A");
        spot.poke("BUSD-B");
    }

    function poke() external {
        process(true);
    }
    
    function pokeWithoutMedian() external {
        process(false);
    }
}