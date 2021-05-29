/**
 *Submitted for verification at Etherscan.io on 2021-05-28
*/

// hevm: flattened sources of src/DssSpell.sol
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity =0.6.12 >=0.5.12 >=0.6.12 <0.7.0;

////// lib/dss-exec-lib/src/DssExecLib.sol
//
// DssExecLib.sol -- MakerDAO Executive Spellcrafting Library
//
// Copyright (C) 2020 Maker Ecosystem Growth Holdings, Inc.
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
/* pragma solidity ^0.6.12; */
/* pragma experimental ABIEncoderV2; */


interface Fileable {
    function file(bytes32, address) external;
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
    function file(bytes32, bytes32, address) external;
}

// https://github.com/makerdao/dss-chain-log
interface ChainlogLike {
    function setVersion(string calldata) external;
    function setIPFS(string calldata) external;
    function setSha256sum(string calldata) external;
    function getAddress(bytes32) external view returns (address);
    function setAddress(bytes32, address) external;
    function removeAddress(bytes32) external;
}

library DssExecLib {
    address constant public LOG = 0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F;
    function vat()        public view returns (address) {}
    function cat()        public view returns (address) {}
    function pot()        public view returns (address) {}
    function vow()        public view returns (address) {}
    function end()        public view returns (address) {}
    function reg()        public view returns (address) {}
    function spotter()    public view returns (address) {}
    function flipperMom() public view returns (address) {}
    function flip(bytes32) public view returns (address) {}
    function getChangelogAddress(bytes32) public view returns (address) {}
    function setChangelogAddress(bytes32, address) public {}
    function setChangelogVersion(string memory) public {}
    function authorize(address, address) public {}
    function deauthorize(address, address) public {}
    function canCast(uint40, bool) public pure returns (bool) {}
    function nextCastTime(uint40, uint40, bool) public pure returns (uint256) {}
    function setContract(address, bytes32, address) public {}
    function setContract(address, bytes32, bytes32, address) public {}
    function setIlkStabilityFee(bytes32, uint256, bool) public {}
    function setIlkLiquidationRatio(bytes32, uint256) public {}
    function increaseIlkDebtCeiling(bytes32, uint256, bool) public {}
    function decreaseIlkDebtCeiling(bytes32, uint256, bool) public {}
    function setIlkAutoLineParameters(bytes32, uint256, uint256, uint256) public {}
    function addWritersToMedianWhitelist(address, address[] memory) public {}
    function removeWritersFromMedianWhitelist(address, address[] memory) public {}
    function setIlkAutoLineDebtCeiling(bytes32, uint256) public {}
    function addReaderToMedianWhitelist(address, address) public {}
    function addReaderToOSMWhitelist(address, address) public {}
    function removeReaderFromOSMWhitelist(address, address) public {}
    function sendPaymentFromSurplusBuffer(address, uint256) public {}
}

////// lib/dss-exec-lib/src/DssAction.sol
//
// DssAction.sol -- DSS Executive Spell Actions
//
// Copyright (C) 2020 Maker Ecosystem Growth Holdings, Inc.
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

/* pragma solidity ^0.6.12; */

/* import { DssExecLib } from "./DssExecLib.sol"; */

abstract contract DssAction {

    using DssExecLib for *;

    // Modifier used to limit execution time when office hours is enabled
    modifier limited {
        require(DssExecLib.canCast(uint40(block.timestamp), officeHours()), "Outside office hours");
        _;
    }

    // Office Hours defaults to true by default.
    //   To disable office hours, override this function and
    //    return false in the inherited action.
    function officeHours() public virtual returns (bool) {
        return true;
    }

    // DssExec calls execute. We limit this function subject to officeHours modifier.
    function execute() external limited {
        actions();
    }

    // DssAction developer must override `actions()` and place all actions to be called inside.
    //   The DssExec function will call this subject to the officeHours limiter
    //   By keeping this function public we allow simulations of `execute()` on the actions outside of the cast time.
    function actions() public virtual;

    // Returns the next available cast time
    function nextCastTime(uint256 eta) external returns (uint256 castTime) {
        require(eta <= uint40(-1));
        castTime = DssExecLib.nextCastTime(uint40(eta), uint40(block.timestamp), officeHours());
    }
}

////// lib/dss-exec-lib/src/DssExec.sol
//
// DssExec.sol -- MakerDAO Executive Spell Template
//
// Copyright (C) 2020 Maker Ecosystem Growth Holdings, Inc.
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

/* pragma solidity ^0.6.12; */

interface PauseAbstract {
    function delay() external view returns (uint256);
    function plot(address, bytes32, bytes calldata, uint256) external;
    function exec(address, bytes32, bytes calldata, uint256) external returns (bytes memory);
}

interface Changelog {
    function getAddress(bytes32) external view returns (address);
}

interface SpellAction {
    function officeHours() external view returns (bool);
    function nextCastTime(uint256) external view returns (uint256);
}

contract DssExec {

    Changelog      constant public log   = Changelog(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);
    uint256                 public eta;
    bytes                   public sig;
    bool                    public done;
    bytes32       immutable public tag;
    address       immutable public action;
    uint256       immutable public expiration;
    PauseAbstract immutable public pause;

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://<executive-vote-canonical-post> -q -O - 2>/dev/null)"
    string                  public description;

    function officeHours() external view returns (bool) {
        return SpellAction(action).officeHours();
    }

    function nextCastTime() external view returns (uint256 castTime) {
        return SpellAction(action).nextCastTime(eta);
    }

    // @param _description  A string description of the spell
    // @param _expiration   The timestamp this spell will expire. (Ex. now + 30 days)
    // @param _spellAction  The address of the spell action
    constructor(string memory _description, uint256 _expiration, address _spellAction) public {
        pause       = PauseAbstract(log.getAddress("MCD_PAUSE"));
        description = _description;
        expiration  = _expiration;
        action      = _spellAction;

        sig = abi.encodeWithSignature("execute()");
        bytes32 _tag;                    // Required for assembly access
        address _action = _spellAction;  // Required for assembly access
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
    }

    function schedule() public {
        require(now <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = now + PauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}

////// lib/dss-interfaces/src/dss/ClipAbstract.sol

/// ClipAbstract.sol -- Clip Interface

// Copyright (C) 2021 Maker Ecosystem Growth Holdings, INC.
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

/* pragma solidity >=0.5.12; */

interface ClipAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function ilk() external view returns (bytes32);
    function vat() external view returns (address);
    function dog() external view returns (address);
    function vow() external view returns (address);
    function spotter() external view returns (address);
    function calc() external view returns (address);
    function buf() external view returns (uint256);
    function tail() external view returns (uint256);
    function cusp() external view returns (uint256);
    function chip() external view returns (uint64);
    function tip() external view returns (uint192);
    function chost() external view returns (uint256);
    function kicks() external view returns (uint256);
    function active(uint256) external view returns (uint256);
    function sales(uint256) external view returns (uint256,uint256,uint256,address,uint96,uint256);
    function stopped() external view returns (uint256);
    function file(bytes32,uint256) external;
    function file(bytes32,address) external;
    function kick(uint256,uint256,address,address) external returns (uint256);
    function redo(uint256,address) external;
    function take(uint256,uint256,uint256,address,bytes calldata) external;
    function count() external view returns (uint256);
    function list() external view returns (uint256[] memory);
    function getStatus(uint256) external view returns (bool,uint256,uint256,uint256);
    function upchost() external;
    function yank(uint256) external;
}

////// lib/dss-interfaces/src/dss/ClipperMomAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/Clipper-mom/blob/master/src/ClipperMom.sol
interface ClipperMomAbstract {
    function owner() external view returns (address);
    function authority() external view returns (address);
    function locked(address) external view returns (uint256);
    function tolerance(address) external view returns (uint256);
    function spotter() external view returns (address);
    function setOwner(address) external;
    function setAuthority(address) external;
    function setPriceTolerance(address, uint256) external;
    function setBreaker(address, uint256, uint256) external;
    function tripBreaker(address) external;
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

////// src/DssSpell.sol
// Copyright (C) 2021 Maker Ecosystem Growth Holdings, INC.
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

/* pragma solidity 0.6.12; */

/* import {Fileable, ChainlogLike} from "dss-exec-lib/DssExecLib.sol"; */
/* import "dss-exec-lib/DssExec.sol"; */
/* import "dss-exec-lib/DssAction.sol"; */
/* import "dss-interfaces/dss/ClipAbstract.sol"; */
/* import "dss-interfaces/dss/ClipperMomAbstract.sol"; */
/* import "dss-interfaces/dss/OsmAbstract.sol"; */

struct Collateral {
    bytes32 ilk;
    address vat;
    address vow;
    address spotter;
    address cat;
    address dog;
    address end;
    address esm;
    address flipperMom;
    address clipperMom;
    address ilkRegistry;
    address pip;
    address clipper;
    address flipper;
    address calc;
    uint256 hole;
    uint256 chop;
    uint256 buf;
    uint256 tail;
    uint256 cusp;
    uint256 chip;
    uint256 tip;
    uint256 cut;
    uint256 step;
    uint256 tolerance;
    bytes32 clipKey;
    bytes32 calcKey;
    bytes32 flipKey;
}

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/1159b773b56c125c9f955b8012316fc752b287ce/governance/votes/Executive%20vote%20-%20May%2028%2C%202021.md -q -O - 2> /dev/null)"
    string public constant description =
        "2021-05-28 MakerDAO Executive Spell | Hash: 0x7b5931dc6df8c864bcdd752e0d465d0e41024e82712495fd39d5b02b2787a1e3";

    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;
    uint256 constant RAD = 10**45;

    address constant MCD_CLIP_UNIV2DAIETH_A       = 0x9F6981bA5c77211A34B76c6385c0f6FA10414035;
    address constant MCD_CLIP_CALC_UNIV2DAIETH_A  = 0xf738C272D648Cc4565EaFb43c0C5B35BbA3bf29d;
    address constant MCD_CLIP_UNIV2USDCETH_A      = 0x93AE03815BAF1F19d7F18D9116E4b637cc32A131;
    address constant MCD_CLIP_CALC_UNIV2USDCETH_A = 0x022ff40643e8b94C43f0a1E54f51EF6D070AcbC4;
    address constant MCD_CLIP_UNIV2ETHUSDT_A      = 0x2aC4C9b49051275AcB4C43Ec973082388D015D48;
    address constant MCD_CLIP_CALC_UNIV2ETHUSDT_A = 0xA475582E3D6Ec35091EaE81da3b423C1B27fa029;
    address constant MCD_CLIP_UNIV2WBTCDAI_A      = 0x4fC53a57262B87ABDa61d6d0DB2bE7E9BE68F6b8;
    address constant MCD_CLIP_CALC_UNIV2WBTCDAI_A = 0x863AEa7D2c4BF2B5Aa191B057240b6Dc29F532eB;
    address constant MCD_CLIP_UNIV2WBTCETH_A      = 0xb15afaB996904170f87a64Fe42db0b64a6F75d24;
    address constant MCD_CLIP_CALC_UNIV2WBTCETH_A = 0xC94ee71e909DbE08d63aA9e6EFbc9976751601B4;
    address constant MCD_CLIP_UNIV2LINKETH_A      = 0x6aa0520354d1b84e1C6ABFE64a708939529b619e;
    address constant MCD_CLIP_CALC_UNIV2LINKETH_A = 0x8aCeC2d937a4A4cAF42565aFbbb05ac242134F14;
    address constant MCD_CLIP_UNIV2UNIETH_A       = 0xb0ece6F5542A4577E2f1Be491A937Ccbbec8479e;
    address constant MCD_CLIP_CALC_UNIV2UNIETH_A  = 0xad609Ed16157014EF955C94553E40e94A09049f0;
    address constant MCD_CLIP_UNIV2AAVEETH_A      = 0x854b252BA15eaFA4d1609D3B98e00cc10084Ec55;
    address constant MCD_CLIP_CALC_UNIV2AAVEETH_A = 0x5396e541E1F648EC03faf338389045F1D7691960;
    address constant MCD_CLIP_UNIV2DAIUSDT_A      = 0xe4B82Be84391b9e7c56a1fC821f47569B364dd4a;
    address constant MCD_CLIP_CALC_UNIV2DAIUSDT_A = 0x4E88cE740F6bEa31C2b14134F6C5eB2a63104fcF;

    address constant BPROTOCOL_WBTC_MED_READER    = 0x2325aa20DEAa9770a978f1dc7C073589ffC79DC3;
    address constant BPROTOCOL_WBTC_OSM_READER    = 0x4530AEb397b234f0208c8A7c238C7c7545DaEc15;

    function flipperToClipper(Collateral memory col) internal {
        // Check constructor values of Clipper
        require(ClipAbstract(col.clipper).vat() == col.vat, "DssSpell/clip-wrong-vat");
        require(ClipAbstract(col.clipper).spotter() == col.spotter, "DssSpell/clip-wrong-spotter");
        require(ClipAbstract(col.clipper).dog() == col.dog, "DssSpell/clip-wrong-dog");
        require(ClipAbstract(col.clipper).ilk() == col.ilk, "DssSpell/clip-wrong-ilk");
        // Set CLIP for the ilk in the DOG
        DssExecLib.setContract(col.dog, col.ilk, "clip", col.clipper);
        // Set VOW in the CLIP
        DssExecLib.setContract(col.clipper, "vow", col.vow);
        // Set CALC in the CLIP
        DssExecLib.setContract(col.clipper, "calc", col.calc);
        // Authorize CLIP can access to VAT
        DssExecLib.authorize(col.vat, col.clipper);
        // Authorize CLIP can access to DOG
        DssExecLib.authorize(col.dog, col.clipper);
        // Authorize DOG can kick auctions on CLIP
        DssExecLib.authorize(col.clipper, col.dog);
        // Authorize the END to access the CLIP
        DssExecLib.authorize(col.clipper, col.end);
        // Authorize CLIPPERMOM can set the stopped flag in CLIP
        DssExecLib.authorize(col.clipper, col.clipperMom);
        // Authorize ESM to execute in Clipper
        DssExecLib.authorize(col.clipper, col.esm);
        // Whitelist CLIP in the osm
        DssExecLib.addReaderToOSMWhitelist(col.pip, col.clipper);
        // Whitelist clipperMom in the osm
        DssExecLib.addReaderToOSMWhitelist(col.pip, col.clipperMom);
        // No more auctions kicked via the CAT:
        DssExecLib.deauthorize(col.flipper, col.cat);
        // No more circuit breaker for the FLIP:
        DssExecLib.deauthorize(col.flipper, col.flipperMom);
        // Set values
        Fileable(col.dog).file(col.ilk, "hole", col.hole);
        Fileable(col.dog).file(col.ilk, "chop", col.chop);
        Fileable(col.clipper).file("buf", col.buf);
        Fileable(col.clipper).file("tail", col.tail);
        Fileable(col.clipper).file("cusp", col.cusp);
        Fileable(col.clipper).file("chip", col.chip);
        Fileable(col.clipper).file("tip", col.tip);
        Fileable(col.calc).file("cut", col.cut);
        Fileable(col.calc).file("step", col.step);
        ClipperMomAbstract(col.clipperMom).setPriceTolerance(col.clipper, col.tolerance);
        // Update chost
        ClipAbstract(col.clipper).upchost();
        // Replace flip to clip in the ilk registry
        DssExecLib.setContract(col.ilkRegistry, col.ilk, "xlip", col.clipper);
        Fileable(col.ilkRegistry).file(col.ilk, "class", 1);
        // Update Chainlog
        DssExecLib.setChangelogAddress(col.clipKey, col.clipper);
        DssExecLib.setChangelogAddress(col.calcKey, col.calc);
        ChainlogLike(DssExecLib.LOG).removeAddress(col.flipKey);
    }

    function actions() public override {
        address MCD_VAT         = DssExecLib.vat();
        address MCD_CAT         = DssExecLib.cat();
        address MCD_DOG         = DssExecLib.getChangelogAddress("MCD_DOG");
        address MCD_VOW         = DssExecLib.vow();
        address MCD_SPOT        = DssExecLib.spotter();
        address MCD_END         = DssExecLib.end();
        address MCD_ESM         = DssExecLib.getChangelogAddress("MCD_ESM");
        address FLIPPER_MOM     = DssExecLib.getChangelogAddress("FLIPPER_MOM");
        address CLIPPER_MOM     = DssExecLib.getChangelogAddress("CLIPPER_MOM");
        address ILK_REGISTRY    = DssExecLib.getChangelogAddress("ILK_REGISTRY");

        // -------------------------------- PSM-USDC-A line --------------------------------
        DssExecLib.increaseIlkDebtCeiling("PSM-USDC-A", 1_000_000_000, true); // From to 2B to 3B

        // --------------------------- Set tip for prev Clippers ---------------------------
        Fileable(DssExecLib.getChangelogAddress("MCD_CLIP_ETH_A")).file("tip", 300 * RAD);
        Fileable(DssExecLib.getChangelogAddress("MCD_CLIP_ETH_B")).file("tip", 300 * RAD);
        Fileable(DssExecLib.getChangelogAddress("MCD_CLIP_ETH_C")).file("tip", 300 * RAD);
        Fileable(DssExecLib.getChangelogAddress("MCD_CLIP_BAT_A")).file("tip", 300 * RAD);
        Fileable(DssExecLib.getChangelogAddress("MCD_CLIP_WBTC_A")).file("tip", 300 * RAD);
        Fileable(DssExecLib.getChangelogAddress("MCD_CLIP_KNC_A")).file("tip", 300 * RAD);
        Fileable(DssExecLib.getChangelogAddress("MCD_CLIP_ZRX_A")).file("tip", 300 * RAD);
        Fileable(DssExecLib.getChangelogAddress("MCD_CLIP_MANA_A")).file("tip", 300 * RAD);
        Fileable(DssExecLib.getChangelogAddress("MCD_CLIP_COMP_A")).file("tip", 300 * RAD);
        Fileable(DssExecLib.getChangelogAddress("MCD_CLIP_LRC_A")).file("tip", 300 * RAD);
        Fileable(DssExecLib.getChangelogAddress("MCD_CLIP_LINK_A")).file("tip", 300 * RAD);
        Fileable(DssExecLib.getChangelogAddress("MCD_CLIP_BAL_A")).file("tip", 300 * RAD);
        Fileable(DssExecLib.getChangelogAddress("MCD_CLIP_YFI_A")).file("tip", 300 * RAD);
        Fileable(DssExecLib.getChangelogAddress("MCD_CLIP_UNI_A")).file("tip", 300 * RAD);
        Fileable(DssExecLib.getChangelogAddress("MCD_CLIP_RENBTC_A")).file("tip", 300 * RAD);
        Fileable(DssExecLib.getChangelogAddress("MCD_CLIP_AAVE_A")).file("tip", 300 * RAD);

        // ------------------------------- Feed whitelisting -------------------------------
        address PIP_WBTC = DssExecLib.getChangelogAddress("PIP_WBTC");
        DssExecLib.addReaderToMedianWhitelist(OsmAbstract(PIP_WBTC).src(), BPROTOCOL_WBTC_MED_READER);
        DssExecLib.addReaderToOSMWhitelist(PIP_WBTC, BPROTOCOL_WBTC_OSM_READER);

        // --------------------------------- UNIV2DAIETH-A ---------------------------------
        flipperToClipper(Collateral({
            ilk: "UNIV2DAIETH-A",
            vat: MCD_VAT,
            vow: MCD_VOW,
            spotter: MCD_SPOT,
            cat: MCD_CAT,
            dog: MCD_DOG,
            end: MCD_END,
            esm: MCD_ESM,
            flipperMom: FLIPPER_MOM,
            clipperMom: CLIPPER_MOM,
            ilkRegistry: ILK_REGISTRY,
            pip: DssExecLib.getChangelogAddress("PIP_UNIV2DAIETH"),
            clipper: MCD_CLIP_UNIV2DAIETH_A,
            flipper: DssExecLib.getChangelogAddress("MCD_FLIP_UNIV2DAIETH_A"),
            calc: MCD_CLIP_CALC_UNIV2DAIETH_A,
            hole: 5_000_000 * RAD,
            chop: 113 * WAD / 100,
            buf: 115 * RAY / 100,
            tail: 215 minutes,
            cusp: 60 * RAY / 100,
            chip: 1 * WAD / 1000,
            tip: 300 * RAD,
            cut: 995 * RAY / 1000,
            step: 125 seconds,
            tolerance: 70 * RAY / 100,
            clipKey: "MCD_CLIP_UNIV2DAIETH_A",
            calcKey: "MCD_CLIP_CALC_UNIV2DAIETH_A",
            flipKey: "MCD_FLIP_UNIV2DAIETH_A"
        }));

        // --------------------------------- UNIV2USDCETH-A ---------------------------------
        flipperToClipper(Collateral({
            ilk: "UNIV2USDCETH-A",
            vat: MCD_VAT,
            vow: MCD_VOW,
            spotter: MCD_SPOT,
            cat: MCD_CAT,
            dog: MCD_DOG,
            end: MCD_END,
            esm: MCD_ESM,
            flipperMom: FLIPPER_MOM,
            clipperMom: CLIPPER_MOM,
            ilkRegistry: ILK_REGISTRY,
            pip: DssExecLib.getChangelogAddress("PIP_UNIV2USDCETH"),
            clipper: MCD_CLIP_UNIV2USDCETH_A,
            flipper: DssExecLib.getChangelogAddress("MCD_FLIP_UNIV2USDCETH_A"),
            calc: MCD_CLIP_CALC_UNIV2USDCETH_A,
            hole: 5_000_000 * RAD,
            chop: 113 * WAD / 100,
            buf: 115 * RAY / 100,
            tail: 215 minutes,
            cusp: 60 * RAY / 100,
            chip: 1 * WAD / 1000,
            tip: 300 * RAD,
            cut: 995 * RAY / 1000,
            step: 125 seconds,
            tolerance: 70 * RAY / 100,
            clipKey: "MCD_CLIP_UNIV2USDCETH_A",
            calcKey: "MCD_CLIP_CALC_UNIV2USDCETH_A",
            flipKey: "MCD_FLIP_UNIV2USDCETH_A"
        }));

        // --------------------------------- UNIV2ETHUSDT-A ---------------------------------
        flipperToClipper(Collateral({
            ilk: "UNIV2ETHUSDT-A",
            vat: MCD_VAT,
            vow: MCD_VOW,
            spotter: MCD_SPOT,
            cat: MCD_CAT,
            dog: MCD_DOG,
            end: MCD_END,
            esm: MCD_ESM,
            flipperMom: FLIPPER_MOM,
            clipperMom: CLIPPER_MOM,
            ilkRegistry: ILK_REGISTRY,
            pip: DssExecLib.getChangelogAddress("PIP_UNIV2ETHUSDT"),
            clipper: MCD_CLIP_UNIV2ETHUSDT_A,
            flipper: DssExecLib.getChangelogAddress("MCD_FLIP_UNIV2ETHUSDT_A"),
            calc: MCD_CLIP_CALC_UNIV2ETHUSDT_A,
            hole: 5_000_000 * RAD,
            chop: 113 * WAD / 100,
            buf: 115 * RAY / 100,
            tail: 215 minutes,
            cusp: 60 * RAY / 100,
            chip: 1 * WAD / 1000,
            tip: 300 * RAD,
            cut: 995 * RAY / 1000,
            step: 125 seconds,
            tolerance: 70 * RAY / 100,
            clipKey: "MCD_CLIP_UNIV2ETHUSDT_A",
            calcKey: "MCD_CLIP_CALC_UNIV2ETHUSDT_A",
            flipKey: "MCD_FLIP_UNIV2ETHUSDT_A"
        }));

        // --------------------------------- UNIV2WBTCDAI-A ---------------------------------
        flipperToClipper(Collateral({
            ilk: "UNIV2WBTCDAI-A",
            vat: MCD_VAT,
            vow: MCD_VOW,
            spotter: MCD_SPOT,
            cat: MCD_CAT,
            dog: MCD_DOG,
            end: MCD_END,
            esm: MCD_ESM,
            flipperMom: FLIPPER_MOM,
            clipperMom: CLIPPER_MOM,
            ilkRegistry: ILK_REGISTRY,
            pip: DssExecLib.getChangelogAddress("PIP_UNIV2WBTCDAI"),
            clipper: MCD_CLIP_UNIV2WBTCDAI_A,
            flipper: DssExecLib.getChangelogAddress("MCD_FLIP_UNIV2WBTCDAI_A"),
            calc: MCD_CLIP_CALC_UNIV2WBTCDAI_A,
            hole: 5_000_000 * RAD,
            chop: 113 * WAD / 100,
            buf: 115 * RAY / 100,
            tail: 215 minutes,
            cusp: 60 * RAY / 100,
            chip: 1 * WAD / 1000,
            tip: 300 * RAD,
            cut: 995 * RAY / 1000,
            step: 125 seconds,
            tolerance: 70 * RAY / 100,
            clipKey: "MCD_CLIP_UNIV2WBTCDAI_A",
            calcKey: "MCD_CLIP_CALC_UNIV2WBTCDAI_A",
            flipKey: "MCD_FLIP_UNIV2WBTCDAI_A"
        }));

        // --------------------------------- UNIV2WBTCETH-A ---------------------------------
        flipperToClipper(Collateral({
            ilk: "UNIV2WBTCETH-A",
            vat: MCD_VAT,
            vow: MCD_VOW,
            spotter: MCD_SPOT,
            cat: MCD_CAT,
            dog: MCD_DOG,
            end: MCD_END,
            esm: MCD_ESM,
            flipperMom: FLIPPER_MOM,
            clipperMom: CLIPPER_MOM,
            ilkRegistry: ILK_REGISTRY,
            pip: DssExecLib.getChangelogAddress("PIP_UNIV2WBTCETH"),
            clipper: MCD_CLIP_UNIV2WBTCETH_A,
            flipper: DssExecLib.getChangelogAddress("MCD_FLIP_UNIV2WBTCETH_A"),
            calc: MCD_CLIP_CALC_UNIV2WBTCETH_A,
            hole: 5_000_000 * RAD,
            chop: 113 * WAD / 100,
            buf: 130 * RAY / 100,
            tail: 200 minutes,
            cusp: 40 * RAY / 100,
            chip: 1 * WAD / 1000,
            tip: 300 * RAD,
            cut: 99 * RAY / 100,
            step: 130 seconds,
            tolerance: 50 * RAY / 100,
            clipKey: "MCD_CLIP_UNIV2WBTCETH_A",
            calcKey: "MCD_CLIP_CALC_UNIV2WBTCETH_A",
            flipKey: "MCD_FLIP_UNIV2WBTCETH_A"
        }));

        // --------------------------------- UNIV2LINKETH-A ---------------------------------
        flipperToClipper(Collateral({
            ilk: "UNIV2LINKETH-A",
            vat: MCD_VAT,
            vow: MCD_VOW,
            spotter: MCD_SPOT,
            cat: MCD_CAT,
            dog: MCD_DOG,
            end: MCD_END,
            esm: MCD_ESM,
            flipperMom: FLIPPER_MOM,
            clipperMom: CLIPPER_MOM,
            ilkRegistry: ILK_REGISTRY,
            pip: DssExecLib.getChangelogAddress("PIP_UNIV2LINKETH"),
            clipper: MCD_CLIP_UNIV2LINKETH_A,
            flipper: DssExecLib.getChangelogAddress("MCD_FLIP_UNIV2LINKETH_A"),
            calc: MCD_CLIP_CALC_UNIV2LINKETH_A,
            hole: 3_000_000 * RAD,
            chop: 113 * WAD / 100,
            buf: 130 * RAY / 100,
            tail: 200 minutes,
            cusp: 40 * RAY / 100,
            chip: 1 * WAD / 1000,
            tip: 300 * RAD,
            cut: 99 * RAY / 100,
            step: 130 seconds,
            tolerance: 50 * RAY / 100,
            clipKey: "MCD_CLIP_UNIV2LINKETH_A",
            calcKey: "MCD_CLIP_CALC_UNIV2LINKETH_A",
            flipKey: "MCD_FLIP_UNIV2LINKETH_A"
        }));

        // --------------------------------- UNIV2UNIETH-A ---------------------------------
        flipperToClipper(Collateral({
            ilk: "UNIV2UNIETH-A",
            vat: MCD_VAT,
            vow: MCD_VOW,
            spotter: MCD_SPOT,
            cat: MCD_CAT,
            dog: MCD_DOG,
            end: MCD_END,
            esm: MCD_ESM,
            flipperMom: FLIPPER_MOM,
            clipperMom: CLIPPER_MOM,
            ilkRegistry: ILK_REGISTRY,
            pip: DssExecLib.getChangelogAddress("PIP_UNIV2UNIETH"),
            clipper: MCD_CLIP_UNIV2UNIETH_A,
            flipper: DssExecLib.getChangelogAddress("MCD_FLIP_UNIV2UNIETH_A"),
            calc: MCD_CLIP_CALC_UNIV2UNIETH_A,
            hole: 3_000_000 * RAD,
            chop: 113 * WAD / 100,
            buf: 130 * RAY / 100,
            tail: 200 minutes,
            cusp: 40 * RAY / 100,
            chip: 1 * WAD / 1000,
            tip: 300 * RAD,
            cut: 99 * RAY / 100,
            step: 130 seconds,
            tolerance: 50 * RAY / 100,
            clipKey: "MCD_CLIP_UNIV2UNIETH_A",
            calcKey: "MCD_CLIP_CALC_UNIV2UNIETH_A",
            flipKey: "MCD_FLIP_UNIV2UNIETH_A"
        }));

        // --------------------------------- UNIV2AAVEETH-A ---------------------------------
        flipperToClipper(Collateral({
            ilk: "UNIV2AAVEETH-A",
            vat: MCD_VAT,
            vow: MCD_VOW,
            spotter: MCD_SPOT,
            cat: MCD_CAT,
            dog: MCD_DOG,
            end: MCD_END,
            esm: MCD_ESM,
            flipperMom: FLIPPER_MOM,
            clipperMom: CLIPPER_MOM,
            ilkRegistry: ILK_REGISTRY,
            pip: DssExecLib.getChangelogAddress("PIP_UNIV2AAVEETH"),
            clipper: MCD_CLIP_UNIV2AAVEETH_A,
            flipper: DssExecLib.getChangelogAddress("MCD_FLIP_UNIV2AAVEETH_A"),
            calc: MCD_CLIP_CALC_UNIV2AAVEETH_A,
            hole: 3_000_000 * RAD,
            chop: 113 * WAD / 100,
            buf: 130 * RAY / 100,
            tail: 200 minutes,
            cusp: 40 * RAY / 100,
            chip: 1 * WAD / 1000,
            tip: 300 * RAD,
            cut: 99 * RAY / 100,
            step: 130 seconds,
            tolerance: 50 * RAY / 100,
            clipKey: "MCD_CLIP_UNIV2AAVEETH_A",
            calcKey: "MCD_CLIP_CALC_UNIV2AAVEETH_A",
            flipKey: "MCD_FLIP_UNIV2AAVEETH_A"
        }));

        // --------------------------------- UNIV2DAIUSDT-A ---------------------------------
        flipperToClipper(Collateral({
            ilk: "UNIV2DAIUSDT-A",
            vat: MCD_VAT,
            vow: MCD_VOW,
            spotter: MCD_SPOT,
            cat: MCD_CAT,
            dog: MCD_DOG,
            end: MCD_END,
            esm: MCD_ESM,
            flipperMom: FLIPPER_MOM,
            clipperMom: CLIPPER_MOM,
            ilkRegistry: ILK_REGISTRY,
            pip: DssExecLib.getChangelogAddress("PIP_UNIV2DAIUSDT"),
            clipper: MCD_CLIP_UNIV2DAIUSDT_A,
            flipper: DssExecLib.getChangelogAddress("MCD_FLIP_UNIV2DAIUSDT_A"),
            calc: MCD_CLIP_CALC_UNIV2DAIUSDT_A,
            hole: 5_000_000 * RAD,
            chop: 113 * WAD / 100,
            buf: 105 * RAY / 100,
            tail: 220 minutes,
            cusp: 90 * RAY / 100,
            chip: 1 * WAD / 1000,
            tip: 300 * RAD,
            cut: 999 * RAY / 1000,
            step: 120 seconds,
            tolerance: 95 * RAY / 100,
            clipKey: "MCD_CLIP_UNIV2DAIUSDT_A",
            calcKey: "MCD_CLIP_CALC_UNIV2DAIUSDT_A",
            flipKey: "MCD_FLIP_UNIV2DAIUSDT_A"
        }));

        // ------------------------- Update Chainlog -------------------------

        DssExecLib.setChangelogVersion("1.8.0");
    }
}

contract DssSpell is DssExec {
    DssSpellAction internal action_ = new DssSpellAction();
    constructor() DssExec(action_.description(), block.timestamp + 30 days, address(action_)) public {}
}