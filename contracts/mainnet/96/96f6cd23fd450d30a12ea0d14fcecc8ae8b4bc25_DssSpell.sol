// hevm: flattened sources of src/DssSpell.sol
pragma solidity =0.5.12 >0.4.13 >=0.4.23 >=0.5.12;

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
    //     https://changelog.makerdao.com/releases/mainnet/1.1.2/contracts.json

    address constant MCD_VAT         = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant MCD_CAT         = 0xa5679C04fc3d9d8b0AaB1F0ab83555b301cA70Ea;
    address constant MCD_JUG         = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant MCD_SPOT        = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address constant MCD_POT         = 0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7;
    address constant MCD_END         = 0xaB14d3CE3F733CACB76eC2AbE7d2fcb00c99F3d5;
    address constant FLIPPER_MOM     = 0xc4bE7F74Ee3743bDEd8E0fA218ee5cf06397f472;
    address constant OSM_MOM         = 0x76416A4d5190d071bfed309861527431304aA14f;
    address constant ILK_REGISTRY    = 0x8b4ce5DCbb01e0e1f0521cd8dCfb31B308E52c24;
    address constant CHAINLOG        = 0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F;

    // ETH-B specific addresses
    address constant ETH            = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant MCD_JOIN_ETH_B = 0x08638eF1A205bE6762A8b935F5da9b700Cf7322c;
    address constant MCD_FLIP_ETH_B = 0xD499d71bE9e9E5D236A07ac562F7B6CeacCa624c;
    address constant PIP_ETH        = 0x81FE72B5A8d1A857d176C3E7d5Bd2679A9B85763; // OSM

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
    uint256 constant         SIX_PCT_RATE = 1000000001847694957439350562;

    function execute() external {

        /*** ETH-B Collateral Onboarding ***/

        //   $ seth --to-bytes32 $(seth --from-ascii "ETH-B")
        //   0x4554482d42000000000000000000000000000000000000000000000000000000
        bytes32 ilk = "ETH-B";

        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_ETH_B).vat() == MCD_VAT, "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_ETH_B).ilk() == ilk, "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_ETH_B).gem() == ETH, "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_ETH_B).dec() == 18, "join-dec-not-match");
        require(FlipAbstract(MCD_FLIP_ETH_B).vat() == MCD_VAT, "flip-vat-not-match");
        require(FlipAbstract(MCD_FLIP_ETH_B).cat() == MCD_CAT, "flip-cat-not-match");
        require(FlipAbstract(MCD_FLIP_ETH_B).ilk() == ilk, "flip-ilk-not-match");

        // Add the new flip and join to the Chainlog
        ChainlogAbstract(CHAINLOG).setAddress("MCD_JOIN_ETH_B", MCD_JOIN_ETH_B);
        ChainlogAbstract(CHAINLOG).setAddress("MCD_FLIP_ETH_B", MCD_FLIP_ETH_B);
        ChainlogAbstract(CHAINLOG).setVersion("1.1.3");

        // Set the TOKEN PIP in the Spotter
        SpotAbstract(MCD_SPOT).file(ilk, "pip", PIP_ETH);

        // Set the TOKEN-LETTER Flipper in the Cat
        CatAbstract(MCD_CAT).file(ilk, "flip", MCD_FLIP_ETH_B);

        // Init TOKEN-LETTER ilk in Vat & Jug
        VatAbstract(MCD_VAT).init(ilk);
        JugAbstract(MCD_JUG).init(ilk);

        // Allow TOKEN-LETTER Join to modify Vat registry
        VatAbstract(MCD_VAT).rely(MCD_JOIN_ETH_B);
        // Allow the TOKEN-LETTER Flipper to reduce the Cat litterbox on deal()
        CatAbstract(MCD_CAT).rely(MCD_FLIP_ETH_B);
        // Allow Cat to kick auctions in TOKEN-LETTER Flipper
        FlipAbstract(MCD_FLIP_ETH_B).rely(MCD_CAT);
        // Allow End to yank auctions in TOKEN-LETTER Flipper
        FlipAbstract(MCD_FLIP_ETH_B).rely(MCD_END);
        // Allow FlipperMom to access to the TOKEN-LETTER Flipper
        FlipAbstract(MCD_FLIP_ETH_B).rely(FLIPPER_MOM);
        // Disallow Cat to kick auctions in TOKEN-LETTER Flipper
        // !!!!!!!! Only for certain collaterals that do not trigger liquidations like USDC-A)
        //FlipperMomAbstract(FLIPPER_MOM).deny(MCD_FLIP_ETH_B);

        // Allow OsmMom to access to the TOKEN Osm
        // !!!!!!!! Only if PIP_TOKEN = Osm and hasn't been already relied due a previous deployed ilk
        //OsmAbstract(PIP_TOKEN).rely(OSM_MOM);
        // Whitelist Osm to read the Median data (only necessary if it is the first time the token is being added to an ilk)
        // !!!!!!!! Only if PIP_TOKEN = Osm, its src is a Median and hasn't been already whitelisted due a previous deployed ilk
        //MedianAbstract(OsmAbstract(PIP_TOKEN).src()).kiss(PIP_TOKEN);
        // Whitelist Spotter to read the Osm data (only necessary if it is the first time the token is being added to an ilk)
        // !!!!!!!! Only if PIP_TOKEN = Osm or PIP_TOKEN = Median and hasn't been already whitelisted due a previous deployed ilk
        //OsmAbstract(PIP_TOKEN).kiss(MCD_SPOT);
        // Whitelist End to read the Osm data (only necessary if it is the first time the token is being added to an ilk)
        // !!!!!!!! Only if PIP_TOKEN = Osm or PIP_TOKEN = Median and hasn't been already whitelisted due a previous deployed ilk
        //OsmAbstract(PIP_TOKEN).kiss(MCD_END);
        // Set TOKEN Osm in the OsmMom for new ilk
        // !!!!!!!! Only if PIP_TOKEN = Osm
        OsmMomAbstract(OSM_MOM).setOsm(ilk, PIP_ETH);

        // Set the global debt ceiling
        VatAbstract(MCD_VAT).file("Line", 1476 * MILLION * RAD);
        // Set the TOKEN-LETTER debt ceiling
        VatAbstract(MCD_VAT).file(ilk, "line", 20 * MILLION * RAD);
        // Set the TOKEN-LETTER dust
        VatAbstract(MCD_VAT).file(ilk, "dust", 100 * RAD);
        // Set the Lot size
        CatAbstract(MCD_CAT).file(ilk, "dunk", 50 * THOUSAND * RAD);
        // Set the TOKEN-LETTER liquidation penalty (e.g. 13% => X = 113)
        CatAbstract(MCD_CAT).file(ilk, "chop", 113 * WAD / 100);
        // Set the TOKEN-LETTER stability fee (e.g. 1% = 1000000000315522921573372069)
        JugAbstract(MCD_JUG).file(ilk, "duty", SIX_PCT_RATE);
        // Set the TOKEN-LETTER percentage between bids (e.g. 3% => X = 103)
        FlipAbstract(MCD_FLIP_ETH_B).file("beg", 103 * WAD / 100);
        // Set the TOKEN-LETTER time max time between bids
        FlipAbstract(MCD_FLIP_ETH_B).file("ttl", 6 hours);
        // Set the TOKEN-LETTER max auction duration to
        FlipAbstract(MCD_FLIP_ETH_B).file("tau", 6 hours);
        // Set the TOKEN-LETTER min collateralization ratio (e.g. 150% => X = 150)
        SpotAbstract(MCD_SPOT).file(ilk, "mat", 130 * RAY / 100);

        // Update TOKEN-LETTER spot value in Vat
        SpotAbstract(MCD_SPOT).poke(ilk);

        // Add new ilk to the IlkRegistry
        IlkRegistryAbstract(ILK_REGISTRY).add(MCD_JOIN_ETH_B);
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
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/6a97b8f1f145d86b2ea898826cd3232a5abc7c1d/governance/votes/Executive%20vote%20-%20October%2016%2C%202020.md -q -O - 2>/dev/null)"
    string constant public description =
        "2020-10-16 MakerDAO Executive Spell | Hash: 0xbaf455a1f3360f0d9f9941f79626e38344c5c58e96c4d2cf03461995fa1fe913";

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