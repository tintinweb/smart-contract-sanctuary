// hevm: flattened sources of src/DssSpell.sol
pragma solidity =0.5.12 >=0.5.12;

////// lib/dss-interfaces/src/dapp/DSPauseAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/dapphub/ds-pause
interface DSPauseAbstract {
    function setOwner(address) external;
    function setAuthority(address) external;
    function setDelay(uint256) external;
    function plans(bytes32) external view returns (bool);
    function proxy() external view returns (address);
    function delay() external view returns (uint256);
    function plot(address, bytes32, bytes calldata, uint256) external;
    function drop(address, bytes32, bytes calldata, uint256) external;
    function exec(address, bytes32, bytes calldata, uint256) external returns (bytes memory);
}

////// lib/dss-interfaces/src/dss/CatAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/cat.sol
interface CatAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function box() external view returns (uint256);
    function litter() external view returns (uint256);
    function ilks(bytes32) external view returns (address, uint256, uint256);
    function live() external view returns (uint256);
    function vat() external view returns (address);
    function vow() external view returns (address);
    function file(bytes32, address) external;
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
    function file(bytes32, bytes32, address) external;
    function bite(bytes32, address) external returns (uint256);
    function claw(uint256) external;
    function cage() external;
}
////// lib/dss-interfaces/src/dss/ChainlogAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss-chain-log
interface ChainlogAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function keys() external view returns (bytes32[] memory);
    function version() external view returns (string memory);
    function ipfs() external view returns (string memory);
    function setVersion(string calldata) external;
    function setSha256sum(string calldata) external;
    function setIPFS(string calldata) external;
    function setAddress(bytes32,address) external;
    function removeAddress(bytes32) external;
    function count() external view returns (uint256);
    function get(uint256) external view returns (bytes32,address);
    function list() external view returns (bytes32[] memory);
    function getAddress(bytes32) external view returns (address);
}

////// lib/dss-interfaces/src/dss/FlipAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/flip.sol
interface FlipAbstract {
    function wards(address) external view returns (uint256);
    function rely(address usr) external;
    function deny(address usr) external;
    function bids(uint256) external view returns (uint256, uint256, address, uint48, uint48, address, address, uint256);
    function vat() external view returns (address);
    function cat() external view returns (address);
    function ilk() external view returns (bytes32);
    function beg() external view returns (uint256);
    function ttl() external view returns (uint48);
    function tau() external view returns (uint48);
    function kicks() external view returns (uint256);
    function file(bytes32, uint256) external;
    function kick(address, address, uint256, uint256, uint256) external returns (uint256);
    function tick(uint256) external;
    function tend(uint256, uint256, uint256) external;
    function dent(uint256, uint256, uint256) external;
    function deal(uint256) external;
    function yank(uint256) external;
}

////// lib/dss-interfaces/src/dss/GemJoinAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/join.sol
interface GemJoinAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function vat() external view returns (address);
    function ilk() external view returns (bytes32);
    function gem() external view returns (address);
    function dec() external view returns (uint256);
    function live() external view returns (uint256);
    function cage() external;
    function join(address, uint256) external;
    function exit(address, uint256) external;
}

////// lib/dss-interfaces/src/dss/IlkRegistryAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/ilk-registry
interface IlkRegistryAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function vat() external view returns (address);
    function cat() external view returns (address);
    function spot() external view returns (address);
    function ilkData(bytes32) external view returns (
        uint256, address, address, address, address, uint256, string memory, string memory
    );
    function ilks() external view returns (bytes32[] memory);
    function ilks(uint) external view returns (bytes32);
    function add(address) external;
    function remove(bytes32) external;
    function update(bytes32) external;
    function removeAuth(bytes32) external;
    function file(bytes32, address) external;
    function file(bytes32, bytes32, address) external;
    function file(bytes32, bytes32, uint256) external;
    function file(bytes32, bytes32, string calldata) external;
    function count() external view returns (uint256);
    function list() external view returns (bytes32[] memory);
    function list(uint256, uint256) external view returns (bytes32[] memory);
    function get(uint256) external view returns (bytes32);
    function info(bytes32) external view returns (
        string memory, string memory, uint256, address, address, address, address
    );
    function pos(bytes32) external view returns (uint256);
    function gem(bytes32) external view returns (address);
    function pip(bytes32) external view returns (address);
    function join(bytes32) external view returns (address);
    function flip(bytes32) external view returns (address);
    function dec(bytes32) external view returns (uint256);
    function symbol(bytes32) external view returns (string memory);
    function name(bytes32) external view returns (string memory);
}

////// lib/dss-interfaces/src/dss/JugAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/jug.sol
interface JugAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function ilks(bytes32) external view returns (uint256, uint256);
    function vat() external view returns (address);
    function vow() external view returns (address);
    function base() external view returns (address);
    function init(bytes32) external;
    function file(bytes32, bytes32, uint256) external;
    function file(bytes32, uint256) external;
    function file(bytes32, address) external;
    function drip(bytes32) external returns (uint256);
}

////// lib/dss-interfaces/src/dss/MedianAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/median
interface MedianAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function age() external view returns (uint32);
    function wat() external view returns (bytes32);
    function bar() external view returns (uint256);
    function orcl(address) external view returns (uint256);
    function bud(address) external view returns (uint256);
    function slot(uint8) external view returns (address);
    function read() external view returns (uint256);
    function peek() external view returns (uint256, bool);
    function lift(address[] calldata) external;
    function drop(address[] calldata) external;
    function setBar(uint256) external;
    function kiss(address) external;
    function diss(address) external;
    function kiss(address[] calldata) external;
    function diss(address[] calldata) external;
    function poke(uint256[] calldata, uint256[] calldata, uint8[] calldata, bytes32[] calldata, bytes32[] calldata) external;
}

////// lib/dss-interfaces/src/dss/OsmAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/osm
interface OsmAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function stopped() external view returns (uint256);
    function src() external view returns (address);
    function hop() external view returns (uint16);
    function zzz() external view returns (uint64);
    function cur() external view returns (uint128, uint128);
    function nxt() external view returns (uint128, uint128);
    function bud(address) external view returns (uint256);
    function stop() external;
    function start() external;
    function change(address) external;
    function step(uint16) external;
    function void() external;
    function pass() external view returns (bool);
    function poke() external;
    function peek() external view returns (bytes32, bool);
    function peep() external view returns (bytes32, bool);
    function read() external view returns (bytes32);
    function kiss(address) external;
    function diss(address) external;
    function kiss(address[] calldata) external;
    function diss(address[] calldata) external;
}

////// lib/dss-interfaces/src/dss/OsmMomAbstract.sol
/* pragma solidity >=0.5.12; */


// https://github.com/makerdao/osm-mom
interface OsmMomAbstract {
    function owner() external view returns (address);
    function authority() external view returns (address);
    function osms(bytes32) external view returns (address);
    function setOsm(bytes32, address) external;
    function setOwner(address) external;
    function setAuthority(address) external;
    function stop(bytes32) external;
}

////// lib/dss-interfaces/src/dss/SpotAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/spot.sol
interface SpotAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function ilks(bytes32) external view returns (address, uint256);
    function vat() external view returns (address);
    function par() external view returns (uint256);
    function live() external view returns (uint256);
    function file(bytes32, bytes32, address) external;
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
    function poke(bytes32) external;
    function cage() external;
}

////// lib/dss-interfaces/src/dss/VatAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/vat.sol
interface VatAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function can(address, address) external view returns (uint256);
    function hope(address) external;
    function nope(address) external;
    function ilks(bytes32) external view returns (uint256, uint256, uint256, uint256, uint256);
    function urns(bytes32, address) external view returns (uint256, uint256);
    function gem(bytes32, address) external view returns (uint256);
    function dai(address) external view returns (uint256);
    function sin(address) external view returns (uint256);
    function debt() external view returns (uint256);
    function vice() external view returns (uint256);
    function Line() external view returns (uint256);
    function live() external view returns (uint256);
    function init(bytes32) external;
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
    function cage() external;
    function slip(bytes32, address, int256) external;
    function flux(bytes32, address, address, uint256) external;
    function move(address, address, uint256) external;
    function frob(bytes32, address, address, address, int256, int256) external;
    function fork(bytes32, address, address, int256, int256) external;
    function grab(bytes32, address, address, address, int256, int256) external;
    function heal(uint256) external;
    function suck(address, address, uint256) external;
    function fold(bytes32, address, int256) external;
}

////// src/DssSpell.sol
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

/* pragma solidity 0.5.12; */

/* import "lib/dss-interfaces/src/dapp/DSPauseAbstract.sol"; */
/* import "lib/dss-interfaces/src/dss/CatAbstract.sol"; */
/* import "lib/dss-interfaces/src/dss/FlipAbstract.sol"; */
/* import "lib/dss-interfaces/src/dss/IlkRegistryAbstract.sol"; */
/* import "lib/dss-interfaces/src/dss/GemJoinAbstract.sol"; */
/* import "lib/dss-interfaces/src/dss/JugAbstract.sol"; */
/* import "lib/dss-interfaces/src/dss/MedianAbstract.sol"; */
/* import "lib/dss-interfaces/src/dss/OsmAbstract.sol"; */
/* import "lib/dss-interfaces/src/dss/OsmMomAbstract.sol"; */
/* import "lib/dss-interfaces/src/dss/SpotAbstract.sol"; */
/* import "lib/dss-interfaces/src/dss/VatAbstract.sol"; */
/* import "lib/dss-interfaces/src/dss/ChainlogAbstract.sol"; */

contract SpellAction {
    // MAINNET ADDRESSES
    //
    // The contracts in this list should correspond to MCD core contracts, verify
    //  against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/1.1.4/contracts.json
    address constant MCD_VAT         = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant MCD_CAT         = 0xa5679C04fc3d9d8b0AaB1F0ab83555b301cA70Ea;
    address constant MCD_JUG         = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant MCD_SPOT        = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address constant MCD_POT         = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;
    address constant MCD_END         = 0xaB14d3CE3F733CACB76eC2AbE7d2fcb00c99F3d5;
    address constant FLIPPER_MOM     = 0xc4bE7F74Ee3743bDEd8E0fA218ee5cf06397f472;
    address constant OSM_MOM         = 0x76416A4d5190d071bfed309861527431304aA14f;
    address constant ILK_REGISTRY    = 0x8b4ce5DCbb01e0e1f0521cd8dCfb31B308E52c24;
    address constant CHANGELOG       = 0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F;

    address constant BAL            = 0xba100000625a3754423978a60c9317c58a424e3D;
    address constant MCD_JOIN_BAL_A = 0x4a03Aa7fb3973d8f0221B466EefB53D0aC195f55;
    address constant MCD_FLIP_BAL_A = 0xb2b9bd446eE5e58036D2876fce62b7Ab7334583e;
    address constant PIP_BAL        = 0x3ff860c0F28D69F392543A16A397D0dAe85D16dE;

    address constant YFI            = 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e;
    address constant MCD_JOIN_YFI_A = 0x3ff33d9162aD47660083D7DC4bC02Fb231c81677;
    address constant MCD_FLIP_YFI_A = 0xEe4C9C36257afB8098059a4763A374a4ECFE28A7;
    address constant PIP_YFI        = 0x5F122465bCf86F45922036970Be6DD7F58820214;

    // Decimals & precision
    uint256 constant THOUSAND = 10 ** 3;
    uint256 constant MILLION  = 10 ** 6;
    uint256 constant WAD      = 10 ** 18;
    uint256 constant RAY      = 10 ** 27;
    uint256 constant RAD      = 10 ** 45;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    uint256 constant FOUR_PERCENT_RATE = 1000000001243680656318820312;
    uint256 constant FIVE_PERCENT_RATE = 1000000001547125957863212448;

    function execute() external {
        // Set the global debt ceiling
        // 1476 (current DC) + 4 (BAL-A) + 7 (YFI-A) - 50 (ETH-A decrease) - 10 (ETH-B decrease)
        // + 40 (WBTC-A increase) + 5 (LINK-A increase) - 7.5 (USDT-A decrease) - 0.75 (MANA-A decrease)
        VatAbstract(MCD_VAT).file("Line", (1463 * MILLION + 750 * THOUSAND) * RAD);

        // Set the ETH-A debt ceiling
        //
        // Existing debt ceiling: 540 million
        // New debt ceiling: 490 million
        VatAbstract(MCD_VAT).file("ETH-A", "line", 490 * MILLION * RAD);

        // Set the ETH-B debt ceiling
        //
        // Existing debt ceiling: 20 million
        // New debt ceiling: 10 million
        VatAbstract(MCD_VAT).file("ETH-B", "line", 10 * MILLION * RAD);

        // Set the WBTC-A debt ceiling
        //
        // Existing debt ceiling: 120 million
        // New debt ceiling: 160 million
        VatAbstract(MCD_VAT).file("WBTC-A", "line", 160 * MILLION * RAD);

        // Set the MANA-A debt ceiling
        //
        // Existing debt ceiling: 1 million
        // New debt ceiling: 250 thousand
        VatAbstract(MCD_VAT).file("MANA-A", "line", 250 * THOUSAND * RAD);

        // Set the USDT-A debt ceiling
        //
        // Existing debt ceiling: 10 million
        // New debt ceiling: 2.5 million
        VatAbstract(MCD_VAT).file("USDT-A", "line", (2 * MILLION + 500 * THOUSAND) * RAD);

        // Set the LINK-A debt ceiling
        //
        // Existing debt ceiling: 5 million
        // New debt ceiling: 10 million
        VatAbstract(MCD_VAT).file("LINK-A", "line", 10 * MILLION * RAD);

        // Set the ETH-B stability fee
        //
        // Previous: 6%
        // New: 4%
        JugAbstract(MCD_JUG).drip("ETH-B");
        JugAbstract(MCD_JUG).file("ETH-B", "duty", FOUR_PERCENT_RATE);

        // Version bump chainlog (due new collateral types)
        ChainlogAbstract(CHANGELOG).setVersion("1.1.4");

        //
        // Add BAL-A
        //
        bytes32 ilk = "BAL-A";

        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_BAL_A).vat() == MCD_VAT, "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_BAL_A).ilk() == ilk, "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_BAL_A).gem() == BAL, "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_BAL_A).dec() == 18, "join-dec-not-match");
        require(FlipAbstract(MCD_FLIP_BAL_A).vat() == MCD_VAT, "flip-vat-not-match");
        require(FlipAbstract(MCD_FLIP_BAL_A).cat() == MCD_CAT, "flip-cat-not-match");
        require(FlipAbstract(MCD_FLIP_BAL_A).ilk() == ilk, "flip-ilk-not-match");

        // Add the new flip and join to the Chainlog
        ChainlogAbstract(CHANGELOG).setAddress("BAL", BAL);
        ChainlogAbstract(CHANGELOG).setAddress("PIP_BAL", PIP_BAL);
        ChainlogAbstract(CHANGELOG).setAddress("MCD_JOIN_BAL_A", MCD_JOIN_BAL_A);
        ChainlogAbstract(CHANGELOG).setAddress("MCD_FLIP_BAL_A", MCD_FLIP_BAL_A);

        // Set the BAL PIP in the Spotter
        SpotAbstract(MCD_SPOT).file(ilk, "pip", PIP_BAL);

        // Set the BAL-A Flipper in the Cat
        CatAbstract(MCD_CAT).file(ilk, "flip", MCD_FLIP_BAL_A);

        // Init BAL-A ilk in Vat & Jug
        VatAbstract(MCD_VAT).init(ilk);
        JugAbstract(MCD_JUG).init(ilk);

        // Allow BAL-A Join to modify Vat registry
        VatAbstract(MCD_VAT).rely(MCD_JOIN_BAL_A);
        // Allow the BAL-A Flipper to reduce the Cat litterbox on deal()
        CatAbstract(MCD_CAT).rely(MCD_FLIP_BAL_A);
        // Allow Cat to kick auctions in BAL-A Flipper
        FlipAbstract(MCD_FLIP_BAL_A).rely(MCD_CAT);
        // Allow End to yank auctions in BAL-A Flipper
        FlipAbstract(MCD_FLIP_BAL_A).rely(MCD_END);
        // Allow FlipperMom to access to the BAL-A Flipper
        FlipAbstract(MCD_FLIP_BAL_A).rely(FLIPPER_MOM);
        // Disallow Cat to kick auctions in BAL-A Flipper
        // !!!!!!!! Only for certain collaterals that do not trigger liquidations like USDC-A)
        // FlipperMomAbstract(FLIPPER_MOM).deny(MCD_FLIP_BAL_A);

        // Allow OsmMom to access to the BAL Osm
        // !!!!!!!! Only if PIP_BAL = Osm and hasn't been already relied due a previous deployed ilk
        OsmAbstract(PIP_BAL).rely(OSM_MOM);
        // Whitelist Osm to read the Median data (only necessary if it is the first time the token is being added to an ilk)
        // !!!!!!!! Only if PIP_BAL = Osm, its src is a Median and hasn't been already whitelisted due a previous deployed ilk
        MedianAbstract(OsmAbstract(PIP_BAL).src()).kiss(PIP_BAL);
        // Whitelist Spotter to read the Osm data (only necessary if it is the first time the token is being added to an ilk)
        // !!!!!!!! Only if PIP_BAL = Osm or PIP_BAL = Median and hasn't been already whitelisted due a previous deployed ilk
        OsmAbstract(PIP_BAL).kiss(MCD_SPOT);
        // Whitelist End to read the Osm data (only necessary if it is the first time the token is being added to an ilk)
        // !!!!!!!! Only if PIP_BAL = Osm or PIP_BAL = Median and hasn't been already whitelisted due a previous deployed ilk
        OsmAbstract(PIP_BAL).kiss(MCD_END);
        // Set BAL Osm in the OsmMom for new ilk
        // !!!!!!!! Only if PIP_BAL = Osm
        OsmMomAbstract(OSM_MOM).setOsm(ilk, PIP_BAL);

        // Set the global debt ceiling (end of spell)
        // VatAbstract(MCD_VAT).file("Line", 1220 * MILLION * RAD);
        // Set the BAL-A debt ceiling
        VatAbstract(MCD_VAT).file(ilk, "line", 4 * MILLION * RAD);
        // Set the BAL-A dust
        VatAbstract(MCD_VAT).file(ilk, "dust", 100 * RAD);
        // Set the Lot size
        CatAbstract(MCD_CAT).file(ilk, "dunk", 50 * THOUSAND * RAD);
        // Set the BAL-A liquidation penalty (e.g. 13% => X = 113)
        CatAbstract(MCD_CAT).file(ilk, "chop", 113 * WAD / 100);
        // Set the BAL-A stability fee (e.g. 1% = 1000000000315522921573372069)
        JugAbstract(MCD_JUG).file(ilk, "duty", FIVE_PERCENT_RATE);
        // Set the BAL-A percentage between bids (e.g. 3% => X = 103)
        FlipAbstract(MCD_FLIP_BAL_A).file("beg", 103 * WAD / 100);
        // Set the BAL-A time max time between bids
        FlipAbstract(MCD_FLIP_BAL_A).file("ttl", 6 hours);
        // Set the BAL-A max auction duration to
        FlipAbstract(MCD_FLIP_BAL_A).file("tau", 6 hours);
        // Set the BAL-A min collateralization ratio (e.g. 150% => X = 150)
        SpotAbstract(MCD_SPOT).file(ilk, "mat", 175 * RAY / 100);

        // Update BAL-A spot value in Vat
        SpotAbstract(MCD_SPOT).poke(ilk);

        // Add new ilk to the IlkRegistry
        IlkRegistryAbstract(ILK_REGISTRY).add(MCD_JOIN_BAL_A);


        //
        // Add YFI-A
        //
        ilk = "YFI-A";

        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_YFI_A).vat() == MCD_VAT, "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_YFI_A).ilk() == ilk, "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_YFI_A).gem() == YFI, "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_YFI_A).dec() == 18, "join-dec-not-match");
        require(FlipAbstract(MCD_FLIP_YFI_A).vat() == MCD_VAT, "flip-vat-not-match");
        require(FlipAbstract(MCD_FLIP_YFI_A).cat() == MCD_CAT, "flip-cat-not-match");
        require(FlipAbstract(MCD_FLIP_YFI_A).ilk() == ilk, "flip-ilk-not-match");

        // Add the new flip and join to the Chainlog
        ChainlogAbstract(CHANGELOG).setAddress("YFI", YFI);
        ChainlogAbstract(CHANGELOG).setAddress("PIP_YFI", PIP_YFI);
        ChainlogAbstract(CHANGELOG).setAddress("MCD_JOIN_YFI_A", MCD_JOIN_YFI_A);
        ChainlogAbstract(CHANGELOG).setAddress("MCD_FLIP_YFI_A", MCD_FLIP_YFI_A);

        // Set the YFI PIP in the Spotter
        SpotAbstract(MCD_SPOT).file(ilk, "pip", PIP_YFI);

        // Set the YFI-A Flipper in the Cat
        CatAbstract(MCD_CAT).file(ilk, "flip", MCD_FLIP_YFI_A);

        // Init YFI-A ilk in Vat & Jug
        VatAbstract(MCD_VAT).init(ilk);
        JugAbstract(MCD_JUG).init(ilk);

        // Allow YFI-A Join to modify Vat registry
        VatAbstract(MCD_VAT).rely(MCD_JOIN_YFI_A);
        // Allow the YFI-A Flipper to reduce the Cat litterbox on deal()
        CatAbstract(MCD_CAT).rely(MCD_FLIP_YFI_A);
        // Allow Cat to kick auctions in YFI-A Flipper
        FlipAbstract(MCD_FLIP_YFI_A).rely(MCD_CAT);
        // Allow End to yank auctions in YFI-A Flipper
        FlipAbstract(MCD_FLIP_YFI_A).rely(MCD_END);
        // Allow FlipperMom to access to the YFI-A Flipper
        FlipAbstract(MCD_FLIP_YFI_A).rely(FLIPPER_MOM);
        // Disallow Cat to kick auctions in YFI-A Flipper
        // !!!!!!!! Only for certain collaterals that do not trigger liquidations like USDC-A)
        // FlipperMomAbstract(FLIPPER_MOM).deny(MCD_FLIP_YFI_A);

        // Allow OsmMom to access to the YFI Osm
        // !!!!!!!! Only if PIP_YFI = Osm and hasn't been already relied due a previous deployed ilk
        OsmAbstract(PIP_YFI).rely(OSM_MOM);
        // Whitelist Osm to read the Median data (only necessary if it is the first time the token is being added to an ilk)
        // !!!!!!!! Only if PIP_YFI = Osm, its src is a Median and hasn't been already whitelisted due a previous deployed ilk
        MedianAbstract(OsmAbstract(PIP_YFI).src()).kiss(PIP_YFI);
        // Whitelist Spotter to read the Osm data (only necessary if it is the first time the token is being added to an ilk)
        // !!!!!!!! Only if PIP_YFI = Osm or PIP_YFI = Median and hasn't been already whitelisted due a previous deployed ilk
        OsmAbstract(PIP_YFI).kiss(MCD_SPOT);
        // Whitelist End to read the Osm data (only necessary if it is the first time the token is being added to an ilk)
        // !!!!!!!! Only if PIP_YFI = Osm or PIP_YFI = Median and hasn't been already whitelisted due a previous deployed ilk
        OsmAbstract(PIP_YFI).kiss(MCD_END);
        // Set YFI Osm in the OsmMom for new ilk
        // !!!!!!!! Only if PIP_YFI = Osm
        OsmMomAbstract(OSM_MOM).setOsm(ilk, PIP_YFI);

        // Set the global debt ceiling (end of spell)
        // VatAbstract(MCD_VAT).file("Line", 1227 * MILLION * RAD);
        // Set the YFI-A debt ceiling
        VatAbstract(MCD_VAT).file(ilk, "line", 7 * MILLION * RAD);
        // Set the YFI-A dust
        VatAbstract(MCD_VAT).file(ilk, "dust", 100 * RAD);
        // Set the Lot size
        CatAbstract(MCD_CAT).file(ilk, "dunk", 50 * THOUSAND * RAD);
        // Set the YFI-A liquidation penalty (e.g. 13% => X = 113)
        CatAbstract(MCD_CAT).file(ilk, "chop", 113 * WAD / 100);
        // Set the YFI-A stability fee (e.g. 1% = 1000000000315522921573372069)
        JugAbstract(MCD_JUG).file(ilk, "duty", FOUR_PERCENT_RATE);
        // Set the YFI-A percentage between bids (e.g. 3% => X = 103)
        FlipAbstract(MCD_FLIP_YFI_A).file("beg", 103 * WAD / 100);
        // Set the YFI-A time max time between bids
        FlipAbstract(MCD_FLIP_YFI_A).file("ttl", 6 hours);
        // Set the YFI-A max auction duration to
        FlipAbstract(MCD_FLIP_YFI_A).file("tau", 6 hours);
        // Set the YFI-A min collateralization ratio (e.g. 150% => X = 150)
        SpotAbstract(MCD_SPOT).file(ilk, "mat", 175 * RAY / 100);

        // Update YFI-A spot value in Vat
        SpotAbstract(MCD_SPOT).poke(ilk);

        // Add new ilk to the IlkRegistry
        IlkRegistryAbstract(ILK_REGISTRY).add(MCD_JOIN_YFI_A);
    }
}

contract DssSpell {
    DSPauseAbstract public pause =
        DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);
    address         public action;
    bytes32         public tag;
    uint256         public eta;
    bytes           public sig;
    uint256         public expiration;
    bool            public done;

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/8413dc97baa7b6ccb8eb8fb1a007c15741d8d7e4/governance/votes/Executive%20vote%20-%20November%206%2C%202020.md -q -O - 2>/dev/null)"
    string constant public description =
        "2020-11-06 MakerDAO Executive Spell | Hash: 0x958c24628791d50feb4a0c84fcbe4f88e20c8eefc3c1cb3c7e1af21e5388ebba";

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        expiration = now + 30 days;
    }

    modifier officeHours {
        uint day = (now / 1 days + 3) % 7;
        require(day < 5, "Can only be cast on a weekday");
        uint hour = now / 1 hours % 24;
        require(hour >= 14 && hour < 21, "Outside office hours");
        _;
    }

    function schedule() public {
        require(now <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = now + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public officeHours {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}