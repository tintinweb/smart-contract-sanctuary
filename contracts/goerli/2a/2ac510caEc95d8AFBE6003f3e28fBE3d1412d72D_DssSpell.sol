/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

// hevm: flattened sources of src/Goerli-DssSpell.sol
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity =0.6.12 >=0.6.12 <0.7.0;
pragma experimental ABIEncoderV2;

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
/* pragma experimental ABIEncoderV2; */

/* import { CollateralOpts } from "./CollateralOpts.sol"; */

interface Initializable {
    function init(bytes32) external;
}

interface Authorizable {
    function rely(address) external;
    function deny(address) external;
    function setAuthority(address) external;
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

interface DogLike {
    function ilks(bytes32) external returns (address clip, uint256 chop, uint256 hole, uint256 dirt);
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
    function tick() external returns (uint256);
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
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {}
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {}
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {}
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {}
    function vat()        public view returns (address) { return getChangelogAddress("MCD_VAT"); }
    function cat()        public view returns (address) { return getChangelogAddress("MCD_CAT"); }
    function dog()        public view returns (address) { return getChangelogAddress("MCD_DOG"); }
    function jug()        public view returns (address) { return getChangelogAddress("MCD_JUG"); }
    function pot()        public view returns (address) { return getChangelogAddress("MCD_POT"); }
    function vow()        public view returns (address) { return getChangelogAddress("MCD_VOW"); }
    function end()        public view returns (address) { return getChangelogAddress("MCD_END"); }
    function esm()        public view returns (address) { return getChangelogAddress("MCD_ESM"); }
    function reg()        public view returns (address) { return getChangelogAddress("ILK_REGISTRY"); }
    function spotter()    public view returns (address) { return getChangelogAddress("MCD_SPOT"); }
    function osmMom()     public view returns (address) { return getChangelogAddress("OSM_MOM"); }
    function clipperMom() public view returns (address) { return getChangelogAddress("CLIPPER_MOM"); }
    function autoLine()   public view returns (address) { return getChangelogAddress("MCD_IAM_AUTO_LINE"); }
    function lerpFab()    public view returns (address) { return getChangelogAddress("LERP_FAB"); }
    function clip(bytes32 _ilk) public view returns (address _clip) {}
    function flip(bytes32 _ilk) public view returns (address _flip) {}
    function calc(bytes32 _ilk) public view returns (address _calc) {}
    function getChangelogAddress(bytes32 _key) public view returns (address) {}
    function setChangelogAddress(bytes32 _key, address _val) public {}
    function setChangelogVersion(string memory _version) public {}
    function authorize(address _base, address _ward) public {}
    function setAuthority(address _base, address _authority) public {}
    function canCast(uint40 _ts, bool _officeHours) public pure returns (bool) {}
    function nextCastTime(uint40 _eta, uint40 _ts, bool _officeHours) public pure returns (uint256 castTime) {}
    function updateCollateralPrice(bytes32 _ilk) public {}
    function setContract(address _base, bytes32 _what, address _addr) public {}
    function setContract(address _base, bytes32 _ilk, bytes32 _what, address _addr) public {}
    function setValue(address _base, bytes32 _what, uint256 _amt) public {}
    function setValue(address _base, bytes32 _ilk, bytes32 _what, uint256 _amt) public {}
    function increaseGlobalDebtCeiling(uint256 _amount) public {}
    function decreaseGlobalDebtCeiling(uint256 _amount) public {}
    function setIlkDebtCeiling(bytes32 _ilk, uint256 _amount) public {}
    function setIlkAutoLineParameters(bytes32 _ilk, uint256 _amount, uint256 _gap, uint256 _ttl) public {}
    function setIlkMinVaultAmount(bytes32 _ilk, uint256 _amount) public {}
    function setIlkLiquidationPenalty(bytes32 _ilk, uint256 _pct_bps) public {}
    function setIlkMaxLiquidationAmount(bytes32 _ilk, uint256 _amount) public {}
    function setIlkLiquidationRatio(bytes32 _ilk, uint256 _pct_bps) public {}
    function setStartingPriceMultiplicativeFactor(bytes32 _ilk, uint256 _pct_bps) public {}
    function setAuctionTimeBeforeReset(bytes32 _ilk, uint256 _duration) public {}
    function setAuctionPermittedDrop(bytes32 _ilk, uint256 _pct_bps) public {}
    function setKeeperIncentivePercent(bytes32 _ilk, uint256 _pct_bps) public {}
    function setKeeperIncentiveFlatRate(bytes32 _ilk, uint256 _amount) public {}
    function setLiquidationBreakerPriceTolerance(address _clip, uint256 _pct_bps) public {}
    function setIlkStabilityFee(bytes32 _ilk, uint256 _rate, bool _doDrip) public {}
    function setStairstepExponentialDecrease(address _calc, uint256 _duration, uint256 _pct_bps) public {}
    function whitelistOracleMedians(address _oracle) public {}
    function addReaderToWhitelist(address _oracle, address _reader) public {}
    function addReaderToWhitelistCall(address _oracle, address _reader) public {}
    function allowOSMFreeze(address _osm, bytes32 _ilk) public {}
    function addCollateralBase(
        bytes32 _ilk,
        address _gem,
        address _join,
        address _clip,
        address _calc,
        address _pip
    ) public {}
    function addNewCollateral(CollateralOpts memory co) public {}
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

////// src/Goerli-DssSpellCollateralOnboarding.sol
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

/* import "dss-exec-lib/DssExecLib.sol"; */

contract DssSpellCollateralOnboardingAction {

    // --- Rates ---
    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmTRiQ3GqjCiRhh1ojzKzgScmSsiwQPLyjhgYSxZASQekj
    //
    uint256 constant ONE_PCT_RATE = 1000000000315522921573372069;

    // --- Math ---
    uint256 constant MILLION = 10 ** 6;

    // --- DEPLOYED COLLATERAL ADDRESSES ---
    // --- GUNIV3DAIUSDC2-A ---
    address constant GUNIV3DAIUSDC2                 = 0x540BBCcb890cEb6c539fA94a0d63fF7a6aA25762;
    address constant MCD_JOIN_GUNIV3DAIUSDC2_A      = 0xbd039ea6d63AC57F2cD051202dC4fB6BA6681489;
    address constant MCD_CLIP_GUNIV3DAIUSDC2_A      = 0x39aee8F2D5ea5dffE4b84529f0349743C71C07c3;
    address constant MCD_CLIP_CALC_GUNIV3DAIUSDC2_A = 0xbF87fbA8ec2190E50Da297815A9A6Ae668306aFE;
    address constant PIP_GUNIV3DAIUSDC2             = 0x6Fb18806ff87B45220C2DB0941709142f2395069;

    function onboardNewCollaterals() internal {
        // ----------------------------- Collateral onboarding -----------------------------
        //  Add GUNIV3DAIUSDC2-A as a new Vault Type
        //  https://vote.makerdao.com/polling/QmSkHE8T?network=mainnet#poll-detail
        DssExecLib.addNewCollateral(
            CollateralOpts({
                ilk:                   "GUNIV3DAIUSDC2-A",
                gem:                   GUNIV3DAIUSDC2,
                join:                  MCD_JOIN_GUNIV3DAIUSDC2_A,
                clip:                  MCD_CLIP_GUNIV3DAIUSDC2_A,
                calc:                  MCD_CLIP_CALC_GUNIV3DAIUSDC2_A,
                pip:                   PIP_GUNIV3DAIUSDC2,
                isLiquidatable:        false,
                isOSM:                 true,
                whitelistOSM:          true,
                ilkDebtCeiling:        10 * MILLION,
                minVaultAmount:        15_000,
                maxLiquidationAmount:  5 * MILLION,
                liquidationPenalty:    1300,
                ilkStabilityFee:       ONE_PCT_RATE,
                startingPriceFactor:   10500,
                breakerTolerance:      9500,
                auctionDuration:       220 minutes,
                permittedDrop:         9000,
                liquidationRatio:      10500,
                kprFlatReward:         300,
                kprPctReward:          10
            })
        );

        DssExecLib.setStairstepExponentialDecrease(MCD_CLIP_CALC_GUNIV3DAIUSDC2_A, 120 seconds, 9990);
        DssExecLib.setIlkAutoLineParameters("GUNIV3DAIUSDC2-A", 10 * MILLION, 10 * MILLION, 8 hours);

        // ChainLog Updates
        // Add the new gem, join, clip, calc and pip to the Chainlog and bump its version
        // address constant CHAINLOG        = 0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F;
        DssExecLib.setChangelogAddress("GUNIV3DAIUSDC2", GUNIV3DAIUSDC2);
        DssExecLib.setChangelogAddress("MCD_JOIN_GUNIV3DAIUSDC2_A", MCD_JOIN_GUNIV3DAIUSDC2_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_GUNIV3DAIUSDC2_A", MCD_CLIP_GUNIV3DAIUSDC2_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_GUNIV3DAIUSDC2_A", MCD_CLIP_CALC_GUNIV3DAIUSDC2_A);
        DssExecLib.setChangelogAddress("PIP_GUNIV3DAIUSDC2", PIP_GUNIV3DAIUSDC2);

        DssExecLib.setChangelogVersion("1.9.12");

    }
}

////// src/Goerli-DssSpell.sol
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
/* pragma experimental ABIEncoderV2; */

/* import "dss-exec-lib/DssExec.sol"; */
/* import "dss-exec-lib/DssAction.sol"; */

/* import { DssSpellCollateralOnboardingAction } from "./Goerli-DssSpellCollateralOnboarding.sol"; */

contract DssSpellAction is DssAction, DssSpellCollateralOnboardingAction {
    // Provides a descriptive tag for bot consumption
    string public constant override description = "Goerli Spell";

    // Office Hours Off
    function officeHours() public override returns (bool) {
        return false;
    }

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //

    // --- Rates ---
    uint256 constant ZERO_ONE_PCT_RATE       = 1000000000031693947650284507;
    uint256 constant TWO_PCT_RATE            = 1000000000627937192491029810;
    uint256 constant TWO_FIVE_PCT_RATE       = 1000000000782997609082909351;
    uint256 constant TWO_SEVEN_FIVE_PCT_RATE = 1000000000860244400048238898;
    uint256 constant THREE_PCT_RATE          = 1000000000937303470807876289;
    uint256 constant FOUR_PCT_RATE           = 1000000001243680656318820312;
    uint256 constant SIX_PCT_RATE            = 1000000001847694957439350562;
    uint256 constant SIX_FIVE_PCT_RATE       = 1000000001996917783620820123;

    // --- Math ---
    uint256 constant BILLION = 10 ** 9;

    // --- Ilks ---
    bytes32 constant WSTETH_A = "WSTETH-A";
    bytes32 constant MATIC_A  = "MATIC-A";
    bytes32 constant RWA006_A = "RWA006-A";

    function actions() public override {


        // ------------- Changes corresponding to the 2021-12-03 mainnet spell -------------
        // ---------------------------------------------------------------------------------

        // ---------------------------------------------------------------------------------
        // Includes changes from the DssSpellCollateralOnboardingAction
        onboardNewCollaterals();

        // ----------------------------- Rates updates -----------------------------
        // https://vote.makerdao.com/polling/QmNqCZGa?network=mainnet
        // Increase the ETH-A Stability Fee from 2.5% to 2.75%
        DssExecLib.setIlkStabilityFee("ETH-A", TWO_SEVEN_FIVE_PCT_RATE, true);

        // Increase the ETH-B Stability Fee from 6.0% to 6.5%
        DssExecLib.setIlkStabilityFee("ETH-B", SIX_FIVE_PCT_RATE, true);

        // Increase the LINK-A Stability Fee from 1.5% to 2.5%
        DssExecLib.setIlkStabilityFee("LINK-A", TWO_FIVE_PCT_RATE, true);

        // Increase the MANA-A Stability Fee from 3.0% to 6.0%
        DssExecLib.setIlkStabilityFee("MANA-A", SIX_PCT_RATE, true);

        // Increase the UNI-A Stability Fee from 1.0% to 3.0%
        DssExecLib.setIlkStabilityFee("UNI-A", THREE_PCT_RATE, true);

        // Increase the GUSD-A Stability Fee from 0.0% to 1.0%
        DssExecLib.setIlkStabilityFee("GUSD-A", ONE_PCT_RATE, true);

        // Increase the UNIV2DAIETH-A Stability Fee from 1.5% to 2.0%
        DssExecLib.setIlkStabilityFee("UNIV2DAIETH-A", TWO_PCT_RATE, true);

        // Increase the UNIV2WBTCETH-A Stability Fee from 2.5% to 3.0%
        DssExecLib.setIlkStabilityFee("UNIV2WBTCETH-A", THREE_PCT_RATE, true);

        // Increase the UNIV2USDCETH-A Stability Fee from 2.0% to 2.5%
        DssExecLib.setIlkStabilityFee("UNIV2USDCETH-A", TWO_FIVE_PCT_RATE, true);

        // Increase the UNIV2UNIETH-A Stability Fee from 2.0% to 4.0%
        DssExecLib.setIlkStabilityFee("UNIV2UNIETH-A", FOUR_PCT_RATE, true);

        // Decrease the GUNIV3DAIUSDC1-A Stability Fee from 0.5% to 0.1%
        DssExecLib.setIlkStabilityFee("GUNIV3DAIUSDC1-A", ZERO_ONE_PCT_RATE, true);

        // ----------------------------- Debt Ceiling updates -----------------------------
        // Increase the WBTC-A Maximum Debt Ceiling (line) from 1.5 billion DAI to 2 billion DAI
        // Increase the WBTC-A Target Available Debt (gap) from 60 million DAI to 80 million DAI
        // https://vote.makerdao.com/polling/QmNqCZGa?network=mainnet
        DssExecLib.setIlkAutoLineParameters("WBTC-A", 2 * BILLION, 80 * MILLION, 6 hours);

        // Increase the Dust Parameter from 30,000 DAI to 40,000 DAI for the ETH-B
        // https://vote.makerdao.com/polling/QmZXnn16?network=mainnet#poll-detail
        DssExecLib.setIlkMinVaultAmount("ETH-B", 40_000);

        // Increase the Dust Parameter from 10,000 DAI to 15,000 DAI for all vault-types excluding ETH-B and ETH-C
        // https://vote.makerdao.com/polling/QmUYLPcr?network=mainnet#poll-detail
        DssExecLib.setIlkMinVaultAmount("ETH-A", 15_000);
        DssExecLib.setIlkMinVaultAmount("USDC-A", 15_000);
        DssExecLib.setIlkMinVaultAmount("WBTC-A", 15_000);
        DssExecLib.setIlkMinVaultAmount("TUSD-A", 15_000);
        DssExecLib.setIlkMinVaultAmount("MANA-A", 15_000);
        DssExecLib.setIlkMinVaultAmount("PAXUSD-A", 15_000);
        DssExecLib.setIlkMinVaultAmount("LINK-A", 15_000);
        DssExecLib.setIlkMinVaultAmount("YFI-A", 15_000);
        DssExecLib.setIlkMinVaultAmount("GUSD-A", 15_000);
        DssExecLib.setIlkMinVaultAmount("UNI-A", 15_000);
        DssExecLib.setIlkMinVaultAmount("RENBTC-A", 15_000);
        // DssExecLib.setIlkMinVaultAmount("UNIV2DAIETH-A", 15_000); // Updated in Jan 14 spell below
        // DssExecLib.setIlkMinVaultAmount("UNIV2WBTCETH-A", 15_000); // Updated in Jan 14 spell below
        // DssExecLib.setIlkMinVaultAmount("UNIV2USDCETH-A", 15_000); // Updated in Jan 14 spell below
        DssExecLib.setIlkMinVaultAmount("UNIV2DAIUSDC-A", 15_000);
        // DssExecLib.setIlkMinVaultAmount("UNIV2UNIETH-A", 15_000); // Updated in Jan 14 spell below
        // DssExecLib.setIlkMinVaultAmount("UNIV2WBTCDAI-A", 15_000); // Updated in Jan 14 spell below
        DssExecLib.setIlkMinVaultAmount("MATIC-A", 15_000);
        DssExecLib.setIlkMinVaultAmount("GUNIV3DAIUSDC1-A", 15_000);
        DssExecLib.setIlkMinVaultAmount("WSTETH-A", 15_000);


        // no budget distributions on Görli


        // ---------------------------------------------------------------------------------
        // ------------- Changes corresponding to the 2021-12-10 mainnet spell -------------
        // ---------------------------------------------------------------------------------


        // ------------- Transfer vesting streams from MCD_VEST_MKR to MCD_VEST_MKR_TREASURY -------------
        // https://vote.makerdao.com/polling/QmYdDTsn

        // no vesting streams on Görli


        // -------------------- wstETH-A Parameter Changes ------------------------
        // https://vote.makerdao.com/polling/QmYuK441

        DssExecLib.setIlkAutoLineParameters({
            _ilk:    WSTETH_A,
            _amount: 200 * MILLION,
            _gap:    20 * MILLION,
            _ttl:    6 hours
        });
        DssExecLib.setStartingPriceMultiplicativeFactor(WSTETH_A, 120_00);
        DssExecLib.setIlkMaxLiquidationAmount(WSTETH_A, 15 * MILLION);


        // ------------------- MATIC-A Parameter Changes --------------------------
        // https://vote.makerdao.com/polling/QmdzwZyS

        DssExecLib.setIlkAutoLineParameters({
            _ilk:    MATIC_A,
            _amount: 35 * MILLION,
            _gap:    10 * MILLION,
            _ttl:    8 hours
        });


        // ---------------------------------------------------------------------------------
        // ------------- Changes corresponding to the 2022-01-14 mainnet spell -------------
        // ---------------------------------------------------------------------------------

        // ----------------------------- Delegate Compensation -----------------------------
        // https://forum.makerdao.com/t/delegate-compensation-breakdown-december-2021/12462

        // no budget distributions on Görli

        // ----------------------------- Optimism Dai Recovery -----------------------------
        // https://vote.makerdao.com/polling/Qmcfb72e

        // no recovery on Görli

        // ---------------------- Dust Parameter Updates for LP Tokens ---------------------
        // https://vote.makerdao.com/polling/QmUSfhmF


        DssExecLib.setIlkMinVaultAmount("UNIV2DAIETH-A", 60_000);
        DssExecLib.setIlkMinVaultAmount("UNIV2USDCETH-A", 60_000);
        DssExecLib.setIlkMinVaultAmount("UNIV2WBTCDAI-A", 60_000);
        
        DssExecLib.setIlkMinVaultAmount("UNIV2WBTCETH-A", 25_000);
        DssExecLib.setIlkMinVaultAmount("UNIV2UNIETH-A", 25_000);

        // ------------------------------------------------------------------------
        // ----------------- Other cleanup changes --------------------------------
        // ------------------------------------------------------------------------

        DssExecLib.setIlkDebtCeiling({
            _ilk:    RWA006_A,
            _amount: 0
        });

        DssExecLib.decreaseGlobalDebtCeiling(20 * MILLION);

    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}