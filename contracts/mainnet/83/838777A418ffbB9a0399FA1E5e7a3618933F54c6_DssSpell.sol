/**
 *Submitted for verification at Etherscan.io on 2021-09-03
*/

// hevm: flattened sources of src/DssSpell.sol
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity =0.6.12 >=0.6.12 <0.7.0;
// pragma experimental ABIEncoderV2;

////// lib/dss-exec-lib/src/CollateralOpts.sol
/* pragma solidity ^0.6.12; */

struct CollateralOpts {
    bytes32 ilk;
    address gem;
    address join;
    address clip;
    address calc;
    address pip;
    bool    isLiquidatable;
    bool    isOSM;
    bool    whitelistOSM;
    uint256 ilkDebtCeiling;
    uint256 minVaultAmount;
    uint256 maxLiquidationAmount;
    uint256 liquidationPenalty;
    uint256 ilkStabilityFee;
    uint256 startingPriceFactor;
    uint256 breakerTolerance;
    uint256 auctionDuration;
    uint256 permittedDrop;
    uint256 liquidationRatio;
    uint256 kprFlatReward;
    uint256 kprPctReward;
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
/* // pragma experimental ABIEncoderV2; */

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

interface ClipLike {
    function vat() external returns (address);
    function dog() external returns (address);
    function spotter() external view returns (address);
    function calc() external view returns (address);
    function ilk() external returns (bytes32);
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
    function orb0() external view returns (address);
    function orb1() external view returns (address);
}

interface MomLike {
    function setOsm(bytes32, address) external;
    function setPriceTolerance(address, uint256) external;
}

interface RegistryLike {
    function add(address) external;
    function xlip(bytes32) external view returns (address);
}

// https://github.com/makerdao/dss-chain-log
interface ChainlogLike_1 {
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

interface LerpFactoryLike {
    function newLerp(bytes32 name_, address target_, bytes32 what_, uint256 startTime_, uint256 start_, uint256 end_, uint256 duration_) external returns (address);
    function newIlkLerp(bytes32 name_, address target_, bytes32 ilk_, bytes32 what_, uint256 startTime_, uint256 start_, uint256 end_, uint256 duration_) external returns (address);
}

interface LerpLike {
    function tick() external;
}


library DssExecLib {

    /* WARNING

The following library code acts as an interface to the actual DssExecLib
library, which can be found in its own deployed contract. Only trust the actual
library's implementation.

    */

    address constant public LOG = 0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F;
    uint256 constant internal WAD      = 10 ** 18;
    uint256 constant internal RAY      = 10 ** 27;
    uint256 constant internal RAD      = 10 ** 45;
    uint256 constant internal THOUSAND = 10 ** 3;
    uint256 constant internal MILLION  = 10 ** 6;
    uint256 constant internal BPS_ONE_PCT             = 100;
    uint256 constant internal BPS_ONE_HUNDRED_PCT     = 100 * BPS_ONE_PCT;
    uint256 constant internal RATES_ONE_HUNDRED_PCT   = 1000000021979553151239153027;
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {}
    function dai()        public view returns (address) { return getChangelogAddress("MCD_DAI"); }
    function vat()        public view returns (address) { return getChangelogAddress("MCD_VAT"); }
    function vow()        public view returns (address) { return getChangelogAddress("MCD_VOW"); }
    function end()        public view returns (address) { return getChangelogAddress("MCD_END"); }
    function reg()        public view returns (address) { return getChangelogAddress("ILK_REGISTRY"); }
    function daiJoin()    public view returns (address) { return getChangelogAddress("MCD_JOIN_DAI"); }
    function lerpFab()    public view returns (address) { return getChangelogAddress("LERP_FAB"); }
    function clip(bytes32 _ilk) public view returns (address _clip) {}
    function flip(bytes32 _ilk) public view returns (address _flip) {}
    function calc(bytes32 _ilk) public view returns (address _calc) {}
    function getChangelogAddress(bytes32 _key) public view returns (address) {}
    function setChangelogAddress(bytes32 _key, address _val) public {}
    function setChangelogVersion(string memory _version) public {}
    function authorize(address _base, address _ward) public {}
    function canCast(uint40 _ts, bool _officeHours) public pure returns (bool) {}
    function nextCastTime(uint40 _eta, uint40 _ts, bool _officeHours) public pure returns (uint256 castTime) {}
    function setValue(address _base, bytes32 _what, uint256 _amt) public {}
    function setValue(address _base, bytes32 _ilk, bytes32 _what, uint256 _amt) public {}
    function increaseGlobalDebtCeiling(uint256 _amount) public {}
    function increaseIlkDebtCeiling(bytes32 _ilk, uint256 _amount, bool _global) public {}
    function sendPaymentFromSurplusBuffer(address _target, uint256 _amount) public {}
    function linearInterpolation(bytes32 _name, address _target, bytes32 _ilk, bytes32 _what, uint256 _startTime, uint256 _start, uint256 _end, uint256 _duration) public returns (address) {}
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

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://<executive-vote-canonical-post> -q -O - 2>/dev/null)"
    function description() external virtual view returns (string memory);

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
    function description() external view returns (string memory);
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
    function description() external view returns (string memory) {
        return SpellAction(action).description();
    }

    function officeHours() external view returns (bool) {
        return SpellAction(action).officeHours();
    }

    function nextCastTime() external view returns (uint256 castTime) {
        return SpellAction(action).nextCastTime(eta);
    }

    // @param _description  A string description of the spell
    // @param _expiration   The timestamp this spell will expire. (Ex. now + 30 days)
    // @param _spellAction  The address of the spell action
    constructor(uint256 _expiration, address _spellAction) public {
        pause       = PauseAbstract(log.getAddress("MCD_PAUSE"));
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

/* pragma solidity 0.6.12; */

/* import "dss-exec-lib/DssExec.sol"; */
/* import "dss-exec-lib/DssAction.sol"; */

interface ChainlogLike_2 {
    function removeAddress(bytes32) external;
}

interface DssVestLike_1 {
    function create(address, uint256, uint256, uint256, uint256, address) external returns (uint256);
    function file(bytes32, uint256) external;
    function restrict(uint256) external;
}

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/6410a8f1f720099f7ba6553c84b9f9d966a3d319/governance/votes/Executive%20vote%20-%20September%203%2C%202021.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2021-09-03 MakerDAO Executive Spell | Hash: 0xaa8b302da5c9a3f4bfd45685fd04398d3d35af1b4c1cbdfe83f166a6455de0ea";

    address constant MCD_VEST_DAI = 0x2Cc583c0AaCDaC9e23CB601fDA8F1A0c56Cdcb71;
    address constant MCD_VEST_MKR = 0x0fC8D4f2151453ca0cA56f07359049c8f07997Bd;

    // Com Core Unit
    address constant COM_WALLET     = 0x1eE3ECa7aEF17D1e74eD7C447CcBA61aC76aDbA9;
    // Dai Foundation Core Unit
    address constant DAIF_WALLET    = 0x34D8d61050Ef9D2B48Ab00e6dc8A8CA6581c5d63;
    // Dai Foundation Core Unit (Emergency Fund)
    address constant DAIF_EF_WALLET = 0x5F5c328732c9E52DfCb81067b8bA56459b33921f;
    // GovAlpha Core Unit
    address constant GOV_WALLET     = 0x01D26f8c5cC009868A4BF66E268c17B057fF7A73;
    // Growth Core Unit
    address constant GRO_WALLET     = 0x7800C137A645c07132886539217ce192b9F0528e;
    // Marketing Content Production Core Unit
    address constant MKT_WALLET     = 0xDCAF2C84e1154c8DdD3203880e5db965bfF09B60;
    // Oracles Core Unit
    address constant ORA_WALLET     = 0x2d09B7b95f3F312ba6dDfB77bA6971786c5b50Cf;
    // Protocol Engineering
    address constant PE_WALLET      = 0xe2c16c308b843eD02B09156388Cb240cEd58C01c;
    // Risk Core Unit
    address constant RISK_WALLET    = 0xd98ef20520048a35EdA9A202137847A62120d2d9;
    // Real-World Finance Core Unit
    address constant RWF_WALLET     = 0x9e1585d9CA64243CE43D42f7dD7333190F66Ca09;
    // Ses Core Unit
    address constant SES_WALLET     = 0x87AcDD9208f73bFc9207e1f6F0fDE906bcA95cc6;

    uint256 constant MAY_01_2021 = 1619827200;
    uint256 constant JUN_21_2021 = 1624233600;
    uint256 constant JUL_01_2021 = 1625097600;
    uint256 constant SEP_01_2021 = 1630454400;
    uint256 constant SEP_13_2021 = 1631491200;
    uint256 constant SEP_20_2021 = 1632096000;
    uint256 constant OCT_01_2021 = 1633046400;
    uint256 constant NOV_01_2021 = 1635724800;
    uint256 constant JAN_01_2022 = 1640995200;
    uint256 constant MAY_01_2022 = 1651363200;
    uint256 constant JUL_01_2022 = 1656633600;
    uint256 constant SEP_01_2022 = 1661990400;

    uint256 constant MILLION = 10 ** 6;
    uint256 constant WAD     = 10 ** 18;

    // Turn off office hours
    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {
        // Fix PAX keys
        DssExecLib.setChangelogAddress("PAX", DssExecLib.getChangelogAddress("PAXUSD"));
        DssExecLib.setChangelogAddress("PIP_PAX", DssExecLib.getChangelogAddress("PIP_PAXUSD"));
        ChainlogLike_2(DssExecLib.LOG).removeAddress("PIP_PSM_PAX");

        // Set unique payments
        DssExecLib.sendPaymentFromSurplusBuffer(DAIF_EF_WALLET, 2_000_000);
        DssExecLib.sendPaymentFromSurplusBuffer(DAIF_WALLET,      138_591);
        DssExecLib.sendPaymentFromSurplusBuffer(SES_WALLET,       155_237);

        // Setup both DssVest modules
        DssExecLib.authorize(DssExecLib.vat(), MCD_VEST_DAI);
        DssExecLib.authorize(DssExecLib.getChangelogAddress("GOV_GUARD"), MCD_VEST_MKR);
        DssVestLike_1(MCD_VEST_DAI).file("cap", 1 * MILLION * WAD / 30 days);
        DssVestLike_1(MCD_VEST_MKR).file("cap", 1_100 * WAD / 365 days);
        DssExecLib.setChangelogAddress("MCD_VEST_DAI", MCD_VEST_DAI);
        DssExecLib.setChangelogAddress("MCD_VEST_MKR", MCD_VEST_MKR);

        // DssVestLike(VEST).restrict( Only recipient can request funds
        //     DssVestLike(VEST).create(
        //         Recipient of vest,
        //         Total token amount of vest over period,
        //         Start timestamp of vest,
        //         Duration of the vesting period (in seconds),
        //         Length of cliff period (in seconds),
        //         Manager address
        //     )
        // );

        // Set DAI stream payments
        DssVestLike_1(MCD_VEST_DAI).restrict(
            DssVestLike_1(MCD_VEST_DAI).create(                                COM_WALLET,   122_700.00 * 10**18, SEP_01_2021, JAN_01_2022 - SEP_01_2021,            0, address(0))
        );
        DssVestLike_1(MCD_VEST_DAI).restrict(
            DssVestLike_1(MCD_VEST_DAI).create(                               DAIF_WALLET,   492_971.00 * 10**18, OCT_01_2021, SEP_01_2022 - OCT_01_2021,            0, address(0))
        );
        DssVestLike_1(MCD_VEST_DAI).restrict(
            DssVestLike_1(MCD_VEST_DAI).create(                                GOV_WALLET,   123_333.00 * 10**18, SEP_01_2021, OCT_01_2021 - SEP_01_2021,            0, address(0))
        );
        DssVestLike_1(MCD_VEST_DAI).restrict(
            DssVestLike_1(MCD_VEST_DAI).create(                                GRO_WALLET,   300_050.00 * 10**18, SEP_01_2021, NOV_01_2021 - SEP_01_2021,            0, address(0))
        );
        DssVestLike_1(MCD_VEST_DAI).restrict(
            DssVestLike_1(MCD_VEST_DAI).create(                                MKT_WALLET,   103_134.00 * 10**18, SEP_01_2021, NOV_01_2021 - SEP_01_2021,            0, address(0))
        );
        DssVestLike_1(MCD_VEST_DAI).restrict(
            DssVestLike_1(MCD_VEST_DAI).create(                                ORA_WALLET, 4_196_771.00 * 10**18, SEP_01_2021, JUL_01_2022 - SEP_01_2021,            0, address(0))
        );
        DssVestLike_1(MCD_VEST_DAI).restrict(
            DssVestLike_1(MCD_VEST_DAI).create(                                 PE_WALLET, 4_080_000.00 * 10**18, SEP_01_2021, MAY_01_2022 - SEP_01_2021,            0, address(0))
        );
        DssVestLike_1(MCD_VEST_DAI).restrict(
            DssVestLike_1(MCD_VEST_DAI).create(                               RISK_WALLET, 2_184_000.00 * 10**18, SEP_01_2021, SEP_01_2022 - SEP_01_2021,            0, address(0))
        );
        DssVestLike_1(MCD_VEST_DAI).restrict(
            DssVestLike_1(MCD_VEST_DAI).create(                                RWF_WALLET,   620_000.00 * 10**18, SEP_01_2021, JAN_01_2022 - SEP_01_2021,            0, address(0))
        );

        // Growth MKR whole team vesting
        DssVestLike_1(MCD_VEST_MKR).restrict(
            DssVestLike_1(MCD_VEST_MKR).create(GRO_WALLET,                                       803.18 * 10**18, JUL_01_2021,                      365 days, 365 days, address(0))
        );

        // Oracles MKR whole team vesting
        DssVestLike_1(MCD_VEST_MKR).restrict(
            DssVestLike_1(MCD_VEST_MKR).create(ORA_WALLET,                                     1_051.25 * 10**18, JUL_01_2021,                      365 days, 365 days, address(0))
        );

        // PE MKR vestings (per individual)
        (
            DssVestLike_1(MCD_VEST_MKR).create(0xfDB9F5e045D7326C1da87d0e199a05CDE5378EdD,       995.00 * 10**18, MAY_01_2021,                  4 * 365 days, 365 days,  PE_WALLET)
        );
        DssVestLike_1(MCD_VEST_MKR).restrict(
            DssVestLike_1(MCD_VEST_MKR).create(0xBe4De3E151D52668c2C0610C985b4297833239C8,       995.00 * 10**18, MAY_01_2021,                  4 * 365 days, 365 days,  PE_WALLET)
        );
        DssVestLike_1(MCD_VEST_MKR).restrict(
            DssVestLike_1(MCD_VEST_MKR).create(0x58EA3C96a8b81abC01EB78B98deCe2AD1e5fd7fc,       995.00 * 10**18, MAY_01_2021,                  4 * 365 days, 365 days,  PE_WALLET)
        );
        DssVestLike_1(MCD_VEST_MKR).restrict(
            DssVestLike_1(MCD_VEST_MKR).create(0xBAB4Cd1cB31Cd28f842335973712a6015eB0EcD5,       995.00 * 10**18, MAY_01_2021,                  4 * 365 days, 365 days,  PE_WALLET)
        );
        (
            DssVestLike_1(MCD_VEST_MKR).create(0xB5c86aff90944CFB3184902482799bD5fA3B18dD,       995.00 * 10**18, MAY_01_2021,                  4 * 365 days, 365 days,  PE_WALLET)
        );
        DssVestLike_1(MCD_VEST_MKR).restrict(
            DssVestLike_1(MCD_VEST_MKR).create(0x780f478856ebE01e46d9A432e8776bAAB5A81b5b,       995.00 * 10**18, MAY_01_2021,                  4 * 365 days, 365 days,  PE_WALLET)
        );
        DssVestLike_1(MCD_VEST_MKR).restrict(
            DssVestLike_1(MCD_VEST_MKR).create(0x34364E234b3DD02FF5c8A2ad9ba86bbD3D3D3284,       995.00 * 10**18, MAY_01_2021,                  4 * 365 days, 365 days,  PE_WALLET)
        );
        DssVestLike_1(MCD_VEST_MKR).restrict(
            DssVestLike_1(MCD_VEST_MKR).create(0x46E5DBad3966453Af57e90Ec2f3548a0e98ec979,       995.00 * 10**18, MAY_01_2021,                  4 * 365 days, 365 days,  PE_WALLET)
        );
        DssVestLike_1(MCD_VEST_MKR).restrict(
            DssVestLike_1(MCD_VEST_MKR).create(0x18CaE82909C31b60Fe0A9656D76406345C9cb9FB,       995.00 * 10**18, MAY_01_2021,                  4 * 365 days, 365 days,  PE_WALLET)
        );
        (
            DssVestLike_1(MCD_VEST_MKR).create(0x301dD8eB831ddb93F128C33b9d9DC333210d9B25,       995.00 * 10**18, MAY_01_2021,                  4 * 365 days, 365 days,  PE_WALLET)
        );
        (
            DssVestLike_1(MCD_VEST_MKR).create(0xBFC47D0D7452a25b7d3AA4d7379c69A891bD5d43,       995.00 * 10**18, MAY_01_2021,                  4 * 365 days, 365 days,  PE_WALLET)
        );
        (
            DssVestLike_1(MCD_VEST_MKR).create(0xcD16aa978A89Aa26b3121Fc8dd32228d7D0fcF4a,       995.00 * 10**18, SEP_13_2021,                  4 * 365 days, 365 days,  PE_WALLET)
        );
        DssVestLike_1(MCD_VEST_MKR).restrict(
            DssVestLike_1(MCD_VEST_MKR).create(0x3189cfe40CF011AAb13aDD8aE7284deD4CD30602,       995.00 * 10**18, JUN_21_2021,                  4 * 365 days, 365 days,  PE_WALLET)
        );
        DssVestLike_1(MCD_VEST_MKR).restrict(
            DssVestLike_1(MCD_VEST_MKR).create(0x29b37159C09a65af6a7CFb062998B169879442B6,       995.00 * 10**18, SEP_20_2021,                  4 * 365 days, 365 days,  PE_WALLET)
        );

        // Increase PAX-PSM-A DC from 50 million DAI to 500 million DAI
        DssExecLib.increaseIlkDebtCeiling("PSM-PAX-A", 450 * MILLION, true);

        // Decrease Flash Mint Fee (toll) from 0.05% to 0%
        DssExecLib.setValue(DssExecLib.getChangelogAddress("MCD_FLASH"), "toll", 0);

        // Bump changelog version
        DssExecLib.setChangelogVersion("1.9.5");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}