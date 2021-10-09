/**
 *Submitted for verification at Etherscan.io on 2021-10-08
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
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {}
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {}
    function dai()        public view returns (address) { return getChangelogAddress("MCD_DAI"); }
    function vat()        public view returns (address) { return getChangelogAddress("MCD_VAT"); }
    function dog()        public view returns (address) { return getChangelogAddress("MCD_DOG"); }
    function pot()        public view returns (address) { return getChangelogAddress("MCD_POT"); }
    function vow()        public view returns (address) { return getChangelogAddress("MCD_VOW"); }
    function end()        public view returns (address) { return getChangelogAddress("MCD_END"); }
    function reg()        public view returns (address) { return getChangelogAddress("ILK_REGISTRY"); }
    function spotter()    public view returns (address) { return getChangelogAddress("MCD_SPOT"); }
    function autoLine()   public view returns (address) { return getChangelogAddress("MCD_IAM_AUTO_LINE"); }
    function daiJoin()    public view returns (address) { return getChangelogAddress("MCD_JOIN_DAI"); }
    function lerpFab()    public view returns (address) { return getChangelogAddress("LERP_FAB"); }
    function clip(bytes32 _ilk) public view returns (address _clip) {}
    function flip(bytes32 _ilk) public view returns (address _flip) {}
    function calc(bytes32 _ilk) public view returns (address _calc) {}
    function getChangelogAddress(bytes32 _key) public view returns (address) {}
    function setChangelogAddress(bytes32 _key, address _val) public {}
    function setChangelogVersion(string memory _version) public {}
    function canCast(uint40 _ts, bool _officeHours) public pure returns (bool) {}
    function nextCastTime(uint40 _eta, uint40 _ts, bool _officeHours) public pure returns (uint256 castTime) {}
    function setValue(address _base, bytes32 _what, uint256 _amt) public {}
    function setValue(address _base, bytes32 _ilk, bytes32 _what, uint256 _amt) public {}
    function setIlkDebtCeiling(bytes32 _ilk, uint256 _amount) public {}
    function removeIlkFromAutoLine(bytes32 _ilk) public {}
    function setIlkLiquidationPenalty(bytes32 _ilk, uint256 _pct_bps) public {}
    function sendPaymentFromSurplusBuffer(address _target, uint256 _amount) public {}
    function linearInterpolation(bytes32 _name, address _target, bytes32 _what, uint256 _startTime, uint256 _start, uint256 _end, uint256 _duration) public returns (address) {}
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
// 
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

interface VatLike {
    function ilks(bytes32) external view returns (uint256, uint256, uint256, uint256, uint256);
    function Line() external view returns (uint256);
    function file(bytes32, uint256) external;
}

interface TokenLike {
    function approve(address, uint256) external returns (bool);
}

interface DssVestLike {
    function file(bytes32, uint256) external;
    function create(address, uint256, uint256, uint256, uint256, address) external returns (uint256);
    function restrict(uint256) external;
}

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/f33870a7938c1842e8467226f8007a2d47f9ddeb/governance/votes/Executive%20vote%20-%20October%208%2C%202021.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2021-10-08 MakerDAO Executive Spell | Hash: 0xe1126241f8df6e094363eac12a5c4620f0dbf54c4d7da7fa94f5b8dd499e30d2";

    uint256 constant WAD     = 10 ** 18;
    uint256 constant RAY     = 10 ** 27;

    address constant CES_WALLET  = 0x25307aB59Cd5d8b4E2C01218262Ddf6a89Ff86da;
    address constant RISK_WALLET = 0x5d67d5B1fC7EF4bfF31967bE2D2d7b9323c1521c;

    address constant MCD_VEST_MKR_TREASURY = 0x6D635c8d08a1eA2F1687a5E46b666949c977B7dd;
    address constant OPTIMISM_DAI_BRIDGE   = 0x10E6593CDda8c58a1d0f14C5164B376352a55f2F;
    address constant OPTIMISM_ESCROW       = 0x467194771dAe2967Aef3ECbEDD3Bf9a310C76C65;
    address constant OPTIMISM_GOV_RELAY    = 0x09B354CDA89203BB7B3131CC728dFa06ab09Ae2F;
    address constant ARBITRUM_DAI_BRIDGE   = 0xD3B5b60020504bc3489D6949d545893982BA3011;
    address constant ARBITRUM_ESCROW       = 0xA10c7CE4b876998858b1a9E12b10092229539400;
    address constant ARBITRUM_GOV_RELAY    = 0x9ba25c289e351779E0D481Ba37489317c34A899d;

    uint256 constant APR_01_2021 = 1617235200;

    uint256 constant CURRENT_BAT_MAT          = 150 * RAY / 100;
    uint256 constant CURRENT_LRC_MAT          = 175 * RAY / 100;
    uint256 constant CURRENT_ZRX_MAT          = 175 * RAY / 100;
    uint256 constant CURRENT_UNIV2AAVEETH_MAT = 165 * RAY / 100;
    uint256 constant CURRENT_UNIV2LINKETH_MAT = 165 * RAY / 100;

    uint256 constant TARGET_BAT_MAT          = 800 * RAY / 100;
    uint256 constant TARGET_LRC_MAT          = 2600 * RAY / 100;
    uint256 constant TARGET_ZRX_MAT          = 900 * RAY / 100;
    uint256 constant TARGET_UNIV2AAVEETH_MAT = 400 * RAY / 100;
    uint256 constant TARGET_UNIV2LINKETH_MAT = 300 * RAY / 100;

    function _add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function _sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function actions() public override {
       
        //
        // Direct payment
        //
        
        // CES-001 - 1_223_552 DAI - 0x25307aB59Cd5d8b4E2C01218262Ddf6a89Ff86da
        // https://vote.makerdao.com/polling/QmbM8u7Q?network=mainnet#vote-breakdown
        DssExecLib.sendPaymentFromSurplusBuffer(CES_WALLET, 1_223_552);

        //
        // MKR vesting
        //

        TokenLike(DssExecLib.getChangelogAddress("MCD_GOV")).approve(MCD_VEST_MKR_TREASURY, 700 * WAD);

        // Set system-wide cap on maximum vesting speed
        DssVestLike(MCD_VEST_MKR_TREASURY).file("cap", 1100 * WAD / 365 days);

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

        // RISK-001 - 700 MKR - 0x5d67d5B1fC7EF4bfF31967bE2D2d7b9323c1521c
        // https://vote.makerdao.com/polling/QmUAXKm4?network=mainnet#vote-breakdown

        DssVestLike(MCD_VEST_MKR_TREASURY).restrict(
            DssVestLike(MCD_VEST_MKR_TREASURY).create(
                RISK_WALLET,
                700 * WAD,
                APR_01_2021,
                365 days,
                365 days,
                address(0)
            )
        );

        //
        // Collateral offboarding
        //

        uint256 totalLineReduction;
        uint256 line;
        VatLike vat = VatLike(DssExecLib.vat());

        // Offboard BAT-A
        // https://vote.makerdao.com/polling/QmWJfX8U?network=mainnet#vote-breakdown

        (,,,line,) = vat.ilks("BAT-A");
        totalLineReduction = _add(totalLineReduction, line);
        DssExecLib.setIlkLiquidationPenalty("BAT-A", 0);
        DssExecLib.removeIlkFromAutoLine("BAT-A");
        DssExecLib.setIlkDebtCeiling("BAT-A", 0);
        DssExecLib.linearInterpolation({
            _name:      "BAT Offboarding",
            _target:    DssExecLib.spotter(),
            _ilk:       "BAT-A",
            _what:      "mat",
            _startTime: block.timestamp,
            _start:     CURRENT_BAT_MAT,
            _end:       TARGET_BAT_MAT,
            _duration:  60 days
        });

        // Offboard LRC-A 
        // https://vote.makerdao.com/polling/QmUx9LVs?network=mainnet#vote-breakdown

        (,,,line,) = vat.ilks("LRC-A");
        totalLineReduction = _add(totalLineReduction, line);
        DssExecLib.setIlkLiquidationPenalty("LRC-A", 0);
        DssExecLib.removeIlkFromAutoLine("LRC-A");
        DssExecLib.setIlkDebtCeiling("LRC-A", 0);
        DssExecLib.linearInterpolation({
            _name:      "LRC Offboarding",
            _target:    DssExecLib.spotter(),
            _ilk:       "LRC-A",
            _what:      "mat",
            _startTime: block.timestamp,
            _start:     CURRENT_LRC_MAT,
            _end:       TARGET_LRC_MAT,
            _duration:  60 days
        });

        // Offboard ZRX-A 
        // https://vote.makerdao.com/polling/QmPfuF2W?network=mainnet#vote-breakdown

        (,,,line,) = vat.ilks("ZRX-A");
        totalLineReduction = _add(totalLineReduction, line);
        DssExecLib.setIlkLiquidationPenalty("ZRX-A", 0);
        DssExecLib.removeIlkFromAutoLine("ZRX-A");
        DssExecLib.setIlkDebtCeiling("ZRX-A", 0);
        DssExecLib.linearInterpolation({
            _name:      "ZRX Offboarding",
            _target:    DssExecLib.spotter(),
            _ilk:       "ZRX-A",
            _what:      "mat",
            _startTime: block.timestamp,
            _start:     CURRENT_ZRX_MAT,
            _end:       TARGET_ZRX_MAT,
            _duration:  60 days
        });

        // Offboard UNIV2AAVEETH-A
        // https://vote.makerdao.com/polling/QmcuJHkq?network=mainnet#vote-breakdown

        (,,,line,) = vat.ilks("UNIV2AAVEETH-A");
        totalLineReduction = _add(totalLineReduction, line);
        DssExecLib.setIlkLiquidationPenalty("UNIV2AAVEETH-A", 0);
        DssExecLib.removeIlkFromAutoLine("UNIV2AAVEETH-A");
        DssExecLib.setIlkDebtCeiling("UNIV2AAVEETH-A", 0);
        DssExecLib.linearInterpolation({
            _name:      "UNIV2AAVEETH Offboarding",
            _target:    DssExecLib.spotter(),
            _ilk:       "UNIV2AAVEETH-A",
            _what:      "mat",
            _startTime: block.timestamp,
            _start:     CURRENT_UNIV2AAVEETH_MAT,
            _end:       TARGET_UNIV2AAVEETH_MAT,
            _duration:  60 days
        });

        // Offboard UNIV2LINKETH-A
        // https://vote.makerdao.com/polling/Qmd7DPye?network=mainnet#vote-breakdown

        (,,,line,) = vat.ilks("UNIV2LINKETH-A");
        totalLineReduction = _add(totalLineReduction, line);
        DssExecLib.setIlkLiquidationPenalty("UNIV2LINKETH-A", 0);
        DssExecLib.removeIlkFromAutoLine("UNIV2LINKETH-A");
        DssExecLib.setIlkDebtCeiling("UNIV2LINKETH-A", 0);
        DssExecLib.linearInterpolation({
            _name:      "UNIV2LINKETH Offboarding",
            _target:    DssExecLib.spotter(),
            _ilk:       "UNIV2LINKETH-A",
            _what:      "mat",
            _startTime: block.timestamp,
            _start:     CURRENT_UNIV2LINKETH_MAT,
            _end:       TARGET_UNIV2LINKETH_MAT,
            _duration:  60 days
        });

        // Decrease global debt ceiling in accordance with offboarded ilks
        vat.file("Line", _sub(vat.Line(), totalLineReduction));

        //
        // Update Changelog
        //

        DssExecLib.setChangelogAddress("MCD_VEST_MKR_TREASURY", MCD_VEST_MKR_TREASURY);
        DssExecLib.setChangelogAddress("OPTIMISM_DAI_BRIDGE", OPTIMISM_DAI_BRIDGE);
        DssExecLib.setChangelogAddress("OPTIMISM_ESCROW", OPTIMISM_ESCROW);
        DssExecLib.setChangelogAddress("OPTIMISM_GOV_RELAY", OPTIMISM_GOV_RELAY);
        DssExecLib.setChangelogAddress("ARBITRUM_DAI_BRIDGE", ARBITRUM_DAI_BRIDGE);
        DssExecLib.setChangelogAddress("ARBITRUM_ESCROW", ARBITRUM_ESCROW);
        DssExecLib.setChangelogAddress("ARBITRUM_GOV_RELAY", ARBITRUM_GOV_RELAY);
        DssExecLib.setChangelogVersion("1.9.7");
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}