/**
 *Submitted for verification at Etherscan.io on 2021-06-11
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity =0.6.12 >=0.6.12 <0.7.0;

////// lib/dss-exec-lib/src/CollateralOpts.sol
/* pragma solidity ^0.6.12; */

struct CollateralOpts {
    bytes32 ilk;
    address gem;
    address join;
    address flip;
    address pip;
    bool    isLiquidatable;
    bool    isOSM;
    bool    whitelistOSM;
    uint256 ilkDebtCeiling;
    uint256 minVaultAmount;
    uint256 maxLiquidationAmount;
    uint256 liquidationPenalty;
    uint256 ilkStabilityFee;
    uint256 bidIncrease;
    uint256 bidDuration;
    uint256 auctionDuration;
    uint256 liquidationRatio;
}

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

/* import { CollateralOpts } from "./CollateralOpts.sol"; */

interface Initializable {
    function init(bytes32) external;
}

interface Authorizable {
    function rely(address) external;
    function deny(address) external;
}

interface Fileable {
    function file(bytes32, address) external;
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
    function file(bytes32, bytes32, address) external;
}

interface Drippable {
    function drip() external returns (uint256);
    function drip(bytes32) external returns (uint256);
}

interface Pricing {
    function poke(bytes32) external;
}

interface ERC20 {
    function decimals() external returns (uint8);
}

interface DssVat {
    function hope(address) external;
    function nope(address) external;
    function ilks(bytes32) external returns (uint256 Art, uint256 rate, uint256 spot, uint256 line, uint256 dust);
    function Line() external view returns (uint256);
    function suck(address, address, uint) external;
}

interface AuctionLike {
    function vat() external returns (address);
    function cat() external returns (address); // Only flip
    function beg() external returns (uint256);
    function pad() external returns (uint256); // Only flop
    function ttl() external returns (uint256);
    function tau() external returns (uint256);
    function ilk() external returns (bytes32); // Only flip
    function gem() external returns (bytes32); // Only flap/flop
}

interface JoinLike {
    function vat() external returns (address);
    function ilk() external returns (bytes32);
    function gem() external returns (address);
    function dec() external returns (uint256);
    function join(address, uint) external;
    function exit(address, uint) external;
}

// Includes Median and OSM functions
interface OracleLike_2 {
    function src() external view returns (address);
    function lift(address[] calldata) external;
    function drop(address[] calldata) external;
    function setBar(uint256) external;
    function kiss(address) external;
    function diss(address) external;
    function kiss(address[] calldata) external;
    function diss(address[] calldata) external;
}

interface MomLike {
    function setOsm(bytes32, address) external;
}

interface RegistryLike {
    function add(address) external;
    function info(bytes32) external view returns (
        string memory, string memory, uint256, address, address, address, address
    );
    function ilkData(bytes32) external view returns (
        uint256       pos,
        address       gem,
        address       pip,
        address       join,
        address       flip,
        uint256       dec,
        string memory name,
        string memory symbol
    );
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

interface IAMLike {
    function ilks(bytes32) external view returns (uint256,uint256,uint48,uint48,uint48);
    function setIlk(bytes32,uint256,uint256,uint256) external;
    function remIlk(bytes32) external;
    function exec(bytes32) external returns (uint256);
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
    function increaseGlobalDebtCeiling(uint256) public {}
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
/* import { CollateralOpts } from "./CollateralOpts.sol"; */

interface OracleLike_1 {
    function src() external view returns (address);
}

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

/* import {Fileable} from "dss-exec-lib/DssExecLib.sol"; */
/* import "dss-exec-lib/DssExec.sol"; */
/* import "dss-exec-lib/DssAction.sol"; */

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/d2eaa6d2b4ac8e286b998e8e1c2177fcd7733e8d/governance/votes/Executive%20vote%20-%20June%2011%2C%202021.md -q -O - 2> /dev/null)"
    string public constant description =
        "2021-06-11 MakerDAO Executive Spell | Hash: 0x46e7883cb0adb7713ff078bea1ec97d1fbd0ee6cfab17e0f48083c171ad27a4f";

    uint256 constant RAY = 10**27;
    uint256 constant RAD = 10**45;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //
    uint256 constant POINT_FIVE_PCT       = 1000000000158153903837946257;
    uint256 constant ONE_PCT              = 1000000000315522921573372069;
    uint256 constant TWO_PCT              = 1000000000627937192491029810;
    uint256 constant TWO_POINT_FIVE_PCT   = 1000000000782997609082909351;
    uint256 constant THREE_PCT            = 1000000000937303470807876289;
    uint256 constant THREE_POINT_FIVE_PCT = 1000000001090862085746321732;
    uint256 constant FOUR_PCT             = 1000000001243680656318820312;
    uint256 constant NINE_PCT             = 1000000002732676825177582095;

    function actions() public override {
        address MCD_DOG               = DssExecLib.getChangelogAddress("MCD_DOG");
        address YEARN_UNI_OSM_READER  = 0x6987e6471D4e7312914Edce4a6f92737C5fd0A8A;
        address YEARN_LINK_OSM_READER = 0xCd73F1Ed2b1078EA35DAB29a8B35d335e0137c83;
        address YEARN_AAVE_OSM_READER = 0x17b20900320D7C23866203cA6808F857B2b3fdA3;
        address YEARN_COMP_OSM_READER = 0x4e9452CD5ba694de87ea1d791aBfdc4a250800f4;

        // ----------------------------- Ilk AutoLine Updates ---------------------------
        //                                  ilk               DC              gap          ttl
        DssExecLib.setIlkAutoLineParameters("ETH-A",          15_000_000_000, 100_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("ETH-B",             300_000_000,  10_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("ETH-C",           2_000_000_000, 100_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("BAT-A",               7_000_000,   1_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("WBTC-A",            750_000_000,  30_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("ZRX-A",               3_000_000,     500_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("MANA-A",              5_000_000,   1_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("COMP-A",             20_000_000,   2_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("LRC-A",               3_000_000,     500_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("LINK-A",            140_000_000,   7_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("BAL-A",              30_000_000,   3_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("YFI-A",             130_000_000,   7_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("UNI-A",              50_000_000,   5_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("RENBTC-A",           10_000_000,   1_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("AAVE-A",             50_000_000,   5_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("UNIV2DAIETH-A",      50_000_000,   5_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("UNIV2WBTCETH-A",     20_000_000,   3_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("UNIV2USDCETH-A",     50_000_000,   5_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("UNIV2DAIUSDC-A",     50_000_000,  10_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("UNIV2ETHUSDT-A",     10_000_000,   2_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("UNIV2LINKETH-A",     20_000_000,   2_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("UNIV2UNIETH-A",      20_000_000,   3_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("UNIV2WBTCDAI-A",     20_000_000,   3_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("UNIV2AAVEETH-A",     20_000_000,   2_000_000, 8 hours);
        DssExecLib.setIlkAutoLineParameters("UNIV2DAIUSDT-A",     10_000_000,   2_000_000, 8 hours);

        // ----------------------------- Stability Fee updates --------------------------
        DssExecLib.setIlkStabilityFee("ETH-A", THREE_POINT_FIVE_PCT, true);
        DssExecLib.setIlkStabilityFee("ETH-B", NINE_PCT, true);
        DssExecLib.setIlkStabilityFee("ETH-C", ONE_PCT, true);
        DssExecLib.setIlkStabilityFee("WBTC-A", THREE_POINT_FIVE_PCT, true);
        DssExecLib.setIlkStabilityFee("LINK-A", FOUR_PCT, true);
        DssExecLib.setIlkStabilityFee("YFI-A", FOUR_PCT, true);
        DssExecLib.setIlkStabilityFee("UNI-A", TWO_PCT, true);
        DssExecLib.setIlkStabilityFee("AAVE-A", TWO_PCT, true);
        DssExecLib.setIlkStabilityFee("BAT-A", FOUR_PCT, true);
        DssExecLib.setIlkStabilityFee("RENBTC-A", FOUR_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2DAIETH-A", TWO_POINT_FIVE_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2USDCETH-A", THREE_POINT_FIVE_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2WBTCETH-A", THREE_POINT_FIVE_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2UNIETH-A", FOUR_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2ETHUSDT-A", FOUR_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2LINKETH-A", THREE_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2AAVEETH-A", THREE_PCT, true);
        DssExecLib.setIlkStabilityFee("UNIV2DAIUSDT-A", TWO_PCT, true);

        // ----------------------------- UNIV2DAIUSDC-A SF and CR -----------------------
        DssExecLib.setIlkLiquidationRatio("UNIV2DAIUSDC-A", 10200);
        DssExecLib.setIlkStabilityFee("UNIV2DAIUSDC-A", POINT_FIVE_PCT, true);

        // ----------------------------- ETH Auction Params -----------------------------
        Fileable(MCD_DOG).file("ETH-A", "hole", 30_000_000 * RAD);
        Fileable(MCD_DOG).file("ETH-B", "hole", 15_000_000 * RAD);
        Fileable(MCD_DOG).file("ETH-C", "hole", 20_000_000 * RAD);
        Fileable(DssExecLib.getChangelogAddress("MCD_CLIP_CALC_ETH_B")).file(
            "step", 60 seconds
        );
        Fileable(DssExecLib.getChangelogAddress("MCD_CLIP_ETH_B")).file(
            "buf", 120 * RAY / 100
        );

        // ----------------------------- Yearn OSM Whitelist ----------------------------
        DssExecLib.addReaderToOSMWhitelist(
            DssExecLib.getChangelogAddress("PIP_UNI"), YEARN_UNI_OSM_READER
        );
        DssExecLib.addReaderToOSMWhitelist(
            DssExecLib.getChangelogAddress("PIP_LINK"), YEARN_LINK_OSM_READER
        );
        DssExecLib.addReaderToOSMWhitelist(
            DssExecLib.getChangelogAddress("PIP_AAVE"), YEARN_AAVE_OSM_READER
        );
        DssExecLib.addReaderToOSMWhitelist(
            DssExecLib.getChangelogAddress("PIP_COMP"), YEARN_COMP_OSM_READER
        );

        // -------------------------------- PSM-USDC-A line --------------------------------
        // https://ipfs.io/ipfs/QmYhDkCvxBz3TRLGztY2gDPu4SkjQ6FEFtXp4fmKgFSxrb
        DssExecLib.increaseIlkDebtCeiling("PSM-USDC-A", 1_000_000_000, true); // From to 3B to 4B
    }
}

contract DssSpell is DssExec {
    DssSpellAction internal action_ = new DssSpellAction();
    constructor() DssExec(action_.description(), block.timestamp + 30 days, address(action_)) public {}
}