/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

// hevm: flattened sources of src/DssSpell.sol
pragma solidity =0.6.12 >=0.5.12 >=0.6.12 <0.7.0;

////// lib/dss-exec-lib/src/DssExecLib.sol
// SPDX-License-Identifier: AGPL-3.0-or-later
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
    function decreaseIlkDebtCeiling(bytes32, uint256, bool) public {}
    function setIlkAutoLineParameters(bytes32, uint256, uint256, uint256) public {}
    function setIlkAutoLineDebtCeiling(bytes32, uint256) public {}
    function addReaderToOSMWhitelist(address, address) public {}
    function removeReaderFromOSMWhitelist(address, address) public {}
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

////// lib/dss-interfaces/src/dss/DogAbstract.sol

/// DogAbstract.sol -- Dog Interface

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

interface DogAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function vat() external view returns (address);
    function ilks(bytes32) external view returns (address,uint256,uint256,uint256);
    function vow() external view returns (address);
    function live() external view returns (uint256);
    function Hole() external view returns (uint256);
    function Dirt() external view returns (uint256);
    function file(bytes32,address) external;
    function file(bytes32,uint256) external;
    function file(bytes32,bytes32,uint256) external;
    function file(bytes32,bytes32,address) external;
    function chop(bytes32) external view returns (uint256);
    function bark(bytes32,address,address) external returns (uint256);
    function digs(bytes32,uint256) external;
    function cage() external;
}

////// lib/dss-interfaces/src/dss/ESMAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/esm/blob/master/src/ESM.sol
interface ESMAbstract {
    function gem() external view returns (address);
    function end() external view returns (address);
    function proxy() external view returns (address);
    function min() external view returns (uint256);
    function sum(address) external view returns (address);
    function Sum() external view returns (uint256);
    function revokesGovernanceAccess() external view returns (bool);
    function fire() external;
    function deny(address) external;
    function join(uint256) external;
    function burn() external;
}

////// lib/dss-interfaces/src/dss/EndAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/end.sol
interface EndAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function vat() external view returns (address);
    function cat() external view returns (address);
    function dog() external view returns (address);
    function vow() external view returns (address);
    function pot() external view returns (address);
    function spot() external view returns (address);
    function live() external view returns (uint256);
    function when() external view returns (uint256);
    function wait() external view returns (uint256);
    function debt() external view returns (uint256);
    function tag(bytes32) external view returns (uint256);
    function gap(bytes32) external view returns (uint256);
    function Art(bytes32) external view returns (uint256);
    function fix(bytes32) external view returns (uint256);
    function bag(address) external view returns (uint256);
    function out(bytes32, address) external view returns (uint256);
    function WAD() external view returns (uint256);
    function RAY() external view returns (uint256);
    function file(bytes32, address) external;
    function file(bytes32, uint256) external;
    function cage() external;
    function cage(bytes32) external;
    function skip(bytes32, uint256) external;
    function snip(bytes32, uint256) external;
    function skim(bytes32, address) external;
    function free(bytes32) external;
    function thaw() external;
    function flow(bytes32) external;
    function pack(uint256) external;
    function cash(bytes32, uint256) external;
}

////// lib/dss-interfaces/src/dss/IlkRegistryAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/ilk-registry
interface IlkRegistryAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function vat() external view returns (address);
    function dog() external view returns (address);
    function cat() external view returns (address);
    function spot() external view returns (address);
    function ilkData(bytes32) external view returns (
        uint96, address, address, uint8, uint96, address, address, string memory, string memory
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
        string memory, string memory, uint256, uint256, address, address, address, address
    );
    function pos(bytes32) external view returns (uint256);
    function class(bytes32) external view returns (uint256);
    function gem(bytes32) external view returns (address);
    function pip(bytes32) external view returns (address);
    function join(bytes32) external view returns (address);
    function xlip(bytes32) external view returns (address);
    function dec(bytes32) external view returns (uint256);
    function symbol(bytes32) external view returns (string memory);
    function name(bytes32) external view returns (string memory);
    function put(bytes32, address, address, uint256, uint256, address, address, string calldata, string calldata) external;
}

////// lib/dss-interfaces/src/dss/VowAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/vow.sol
interface VowAbstract {
    function wards(address) external view returns (uint256);
    function rely(address usr) external;
    function deny(address usr) external;
    function vat() external view returns (address);
    function flapper() external view returns (address);
    function flopper() external view returns (address);
    function sin(uint256) external view returns (uint256);
    function Sin() external view returns (uint256);
    function Ash() external view returns (uint256);
    function wait() external view returns (uint256);
    function dump() external view returns (uint256);
    function sump() external view returns (uint256);
    function bump() external view returns (uint256);
    function hump() external view returns (uint256);
    function live() external view returns (uint256);
    function file(bytes32, uint256) external;
    function file(bytes32, address) external;
    function fess(uint256) external;
    function flog(uint256) external;
    function heal(uint256) external;
    function kiss(uint256) external;
    function flop() external returns (uint256);
    function flap() external returns (uint256);
    function cage() external;
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
/* import "dss-interfaces/dss/IlkRegistryAbstract.sol"; */
/* import "dss-interfaces/dss/VowAbstract.sol"; */
/* import "dss-interfaces/dss/DogAbstract.sol"; */
/* import "dss-interfaces/dss/ClipAbstract.sol"; */
/* import "dss-interfaces/dss/ClipperMomAbstract.sol"; */
/* import "dss-interfaces/dss/EndAbstract.sol"; */
/* import "dss-interfaces/dss/ESMAbstract.sol"; */

interface LerpFabLike_1 {
    function newLerp(bytes32, address, bytes32, uint256, uint256, uint256, uint256) external returns (address);
}

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/57f8d6d1f2a7882879901ca52aaf65c0c4f0a916/governance/votes/Executive%20vote%20-%20April%2023%2C%202021.md -q -O - 2>/dev/null)"
    string public constant description =
        "2021-04-23 MakerDAO Executive Spell | Hash: 0x43eaf55ab4d67c46081871b142f37e85e36c72476dd31b0422e79e9520450d63";

    // New addresses
    address constant MCD_CLIP_YFI_A      = 0x9daCc11dcD0aa13386D295eAeeBBd38130897E6f;
    address constant MCD_CLIP_CALC_YFI_A = 0x1f206d7916Fd3B1b5B0Ce53d5Cab11FCebc124DA;
    address constant LERP_FAB            = 0x00B416da876fe42dd02813da435Cc030F0d72434;

    // Units used
    uint256 constant MILLION    = 10**6;
    uint256 constant WAD        = 10**18;
    uint256 constant RAY        = 10**27;
    uint256 constant RAD        = 10**45;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //
    uint256 constant ZERO_PCT           = 1000000000000000000000000000;
    uint256 constant ONE_PCT            = 1000000000315522921573372069;
    uint256 constant TWO_PCT            = 1000000000627937192491029810;
    uint256 constant THREE_PCT          = 1000000000937303470807876289;
    uint256 constant THREE_PT_FIVE_PCT  = 1000000001090862085746321732;
    uint256 constant FOUR_PCT           = 1000000001243680656318820312;
    uint256 constant FOUR_PT_FIVE_PCT   = 1000000001395766281313196627;
    uint256 constant FIVE_PCT           = 1000000001547125957863212448;
    uint256 constant TEN_PCT            = 1000000003022265980097387650;

    function actions() public override {
        // ------------- Get all the needed addresses from Chainlog -------------

        address MCD_VAT        = DssExecLib.vat();
        address MCD_CAT        = DssExecLib.cat();
        address MCD_DOG        = DssExecLib.getChangelogAddress("MCD_DOG");
        address MCD_VOW        = DssExecLib.vow();
        address MCD_SPOT       = DssExecLib.spotter();
        address MCD_END        = DssExecLib.end();
        address MCD_ESM        = DssExecLib.getChangelogAddress("MCD_ESM");
        address FLIPPER_MOM    = DssExecLib.flipperMom();
        address CLIPPER_MOM    = DssExecLib.getChangelogAddress("CLIPPER_MOM");
        address ILK_REGISTRY   = DssExecLib.getChangelogAddress("ILK_REGISTRY");
        address PIP_YFI        = DssExecLib.getChangelogAddress("PIP_YFI");
        address MCD_FLIP_YFI_A = DssExecLib.getChangelogAddress("MCD_FLIP_YFI_A");
        address CHANGELOG      = DssExecLib.getChangelogAddress("CHANGELOG");

        // ------------- Increase the System Surplus Buffer And Add Burn Percentage -------------

        address lerp = LerpFabLike_1(LERP_FAB).newLerp("20210423_VOW_HUMP1", MCD_VOW, "hump", 1619773200, 30 * MILLION * RAD, 60 * MILLION * RAD, 99 days);
        VowAbstract(MCD_VOW).rely(lerp);
        DssExecLib.setChangelogAddress("LERP_FAB", LERP_FAB);

        // ------------- Add YFI-A to Liquidations 2.0 Framework -------------

        // Check constructor values of Clipper
        require(ClipAbstract(MCD_CLIP_YFI_A).vat() == MCD_VAT, "DssSpell/clip-wrong-vat");
        require(ClipAbstract(MCD_CLIP_YFI_A).spotter() == MCD_SPOT, "DssSpell/clip-wrong-spotter");
        require(ClipAbstract(MCD_CLIP_YFI_A).dog() == MCD_DOG, "DssSpell/clip-wrong-dog");
        require(ClipAbstract(MCD_CLIP_YFI_A).ilk() == "YFI-A", "DssSpell/clip-wrong-ilk");

        // Set CLIP for YFI-A in the DOG
        DssExecLib.setContract(MCD_DOG, "YFI-A", "clip", MCD_CLIP_YFI_A);

        // Set VOW in the YFI-A CLIP
        DssExecLib.setContract(MCD_CLIP_YFI_A, "vow", MCD_VOW);

        // Set CALC in the YFI-A CLIP
        DssExecLib.setContract(MCD_CLIP_YFI_A, "calc", MCD_CLIP_CALC_YFI_A);

        // Authorize CLIP can access to VAT
        DssExecLib.authorize(MCD_VAT, MCD_CLIP_YFI_A);

        // Authorize CLIP can access to DOG
        DssExecLib.authorize(MCD_DOG, MCD_CLIP_YFI_A);

        // Authorize DOG can kick auctions on CLIP
        DssExecLib.authorize(MCD_CLIP_YFI_A, MCD_DOG);

        // Authorize the new END to access the YFI CLIP
        DssExecLib.authorize(MCD_CLIP_YFI_A, MCD_END);

        // Authorize CLIPPERMOM can set the stopped flag in CLIP
        DssExecLib.authorize(MCD_CLIP_YFI_A, CLIPPER_MOM);

        // Authorize new ESM to execute in YFI-A Clipper
        DssExecLib.authorize(MCD_CLIP_YFI_A, MCD_ESM);

        // Whitelist CLIP in the YFI osm
        DssExecLib.addReaderToOSMWhitelist(PIP_YFI, MCD_CLIP_YFI_A);

        // Whitelist CLIPPER_MOM in the YFI osm
        DssExecLib.addReaderToOSMWhitelist(PIP_YFI, CLIPPER_MOM);

        // No more auctions kicked via the CAT:
        DssExecLib.deauthorize(MCD_FLIP_YFI_A, MCD_CAT);

        // No more circuit breaker for the FLIP in YFI-A:
        DssExecLib.deauthorize(MCD_FLIP_YFI_A, FLIPPER_MOM);

        Fileable(MCD_DOG).file("YFI-A", "hole", 5 * MILLION * RAD);
        Fileable(MCD_DOG).file("YFI-A", "chop", 113 * WAD / 100);
        Fileable(MCD_CLIP_YFI_A).file("buf", 130 * RAY / 100);
        Fileable(MCD_CLIP_YFI_A).file("tail", 140 minutes);
        Fileable(MCD_CLIP_YFI_A).file("cusp", 40 * RAY / 100);
        Fileable(MCD_CLIP_YFI_A).file("chip", 1 * WAD / 1000);
        Fileable(MCD_CLIP_YFI_A).file("tip", 0);
        Fileable(MCD_CLIP_CALC_YFI_A).file("cut", 99 * RAY / 100); // 1% cut
        Fileable(MCD_CLIP_CALC_YFI_A).file("step", 90 seconds);

        //  Tolerance currently set to 50%.
        //   n.b. 600000000000000000000000000 == 40% acceptable drop
        ClipperMomAbstract(CLIPPER_MOM).setPriceTolerance(MCD_CLIP_YFI_A, 50 * RAY / 100);

        ClipAbstract(MCD_CLIP_YFI_A).upchost();

        // Replace flip to clip in the ilk registry
        DssExecLib.setContract(ILK_REGISTRY, "YFI-A", "xlip", MCD_CLIP_YFI_A);
        Fileable(ILK_REGISTRY).file("YFI-A", "class", 1);

        DssExecLib.setChangelogAddress("MCD_CLIP_YFI_A", MCD_CLIP_YFI_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_YFI_A", MCD_CLIP_CALC_YFI_A);
        ChainlogLike(CHANGELOG).removeAddress("MCD_FLIP_YFI_A");

        // ------------- Stability fees -------------
        DssExecLib.setIlkStabilityFee("LINK-A", FIVE_PCT, true);
        DssExecLib.setIlkStabilityFee("ETH-B", TEN_PCT, true);
        DssExecLib.setIlkStabilityFee("ZRX-A", FOUR_PCT, true);
        DssExecLib.setIlkStabilityFee("LRC-A", FOUR_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2DAIETH-A", THREE_PT_FIVE_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2USDCETH-A", FOUR_PT_FIVE_PCT, true);
        DssExecLib.setIlkStabilityFee("AAVE-A", THREE_PCT, true);
        DssExecLib.setIlkStabilityFee("BAT-A", FIVE_PCT, true);
        DssExecLib.setIlkStabilityFee("MANA-A", THREE_PCT, true);
        DssExecLib.setIlkStabilityFee("BAL-A", TWO_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2DAIUSDC-A", ONE_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2LINKETH-A", FOUR_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2WBTCDAI-A", ZERO_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2AAVEETH-A", FOUR_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2DAIUSDT-A", THREE_PCT, true);

        // ------------- Regular debt ceilings -------------

        DssExecLib.decreaseIlkDebtCeiling("USDT-A", 25 * MILLION / 10, true);

        // ------------- Auto line max ceiling changes -------------

        DssExecLib.setIlkAutoLineDebtCeiling("YFI-A", 90 * MILLION);
        // DssExecLib.setIlkAutoLineDebtCeiling("AAVE-A", 50 * MILLION);
        DssExecLib.setIlkAutoLineDebtCeiling("BAT-A", 7 * MILLION);
        // DssExecLib.setIlkAutoLineDebtCeiling("RENBTC-A", 10 * MILLION);
        // DssExecLib.setIlkAutoLineDebtCeiling("MANA-A", 5 * MILLION);
        // DssExecLib.setIlkAutoLineDebtCeiling("BAL-A", 30 * MILLION);
        DssExecLib.setIlkAutoLineDebtCeiling("UNIV2DAIETH-A", 50 * MILLION);
        // DssExecLib.setIlkAutoLineDebtCeiling("LRC-A", 5 * MILLION);

        // ------------- Auto line gap changes -------------

        DssExecLib.setIlkAutoLineParameters("AAVE-A", 50 * MILLION, 5 * MILLION, 12 hours);
        DssExecLib.setIlkAutoLineParameters("RENBTC-A", 10 * MILLION, 1 * MILLION, 12 hours);
        DssExecLib.setIlkAutoLineParameters("MANA-A", 5 * MILLION, 1 * MILLION, 12 hours);
        DssExecLib.setIlkAutoLineParameters("BAL-A", 30 * MILLION, 3 * MILLION, 12 hours);
        DssExecLib.setIlkAutoLineParameters("LRC-A", 5 * MILLION, 1 * MILLION, 12 hours);

        // ------------- Auto line new ilks -------------

        DssExecLib.setIlkAutoLineParameters("UNIV2WBTCETH-A", 20 * MILLION, 3 * MILLION, 12 hours);
        DssExecLib.setIlkAutoLineParameters("UNIV2UNIETH-A", 20 * MILLION, 3 * MILLION, 12 hours);
        DssExecLib.setIlkAutoLineParameters("UNIV2LINKETH-A", 20 * MILLION, 2 * MILLION, 12 hours);
        DssExecLib.setIlkAutoLineParameters("UNIV2AAVEETH-A", 20 * MILLION, 2 * MILLION, 12 hours);
        DssExecLib.setIlkAutoLineParameters("UNIV2ETHUSDT-A", 10 * MILLION, 2 * MILLION, 12 hours);
        DssExecLib.setIlkAutoLineParameters("UNIV2DAIUSDT-A", 10 * MILLION, 2 * MILLION, 12 hours);
        DssExecLib.setIlkAutoLineParameters("UNIV2WBTCDAI-A", 20 * MILLION, 3 * MILLION, 12 hours);

        // ------------- Chainlog version -------------

        DssExecLib.setChangelogVersion("1.4.0");
    }
}

contract DssSpell is DssExec {
    DssSpellAction internal action_ = new DssSpellAction();
    constructor() DssExec(action_.description(), block.timestamp + 30 days, address(action_)) public {}
}