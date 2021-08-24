/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

// hevm: flattened sources of src/Goerli-DssSpell.sol
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity =0.6.12 >=0.5.12 >=0.6.12 <0.7.0;
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
}

interface Fileable_1 {
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
    function authorize(address _base, address _ward) public {}
    function canCast(uint40 _ts, bool _officeHours) public pure returns (bool) {}
    function nextCastTime(uint40 _eta, uint40 _ts, bool _officeHours) public pure returns (uint256 castTime) {}
    function updateCollateralPrice(bytes32 _ilk) public {}
    function setContract(address _base, bytes32 _what, address _addr) public {}
    function setContract(address _base, bytes32 _ilk, bytes32 _what, address _addr) public {}
    function setValue(address _base, bytes32 _what, uint256 _amt) public {}
    function setValue(address _base, bytes32 _ilk, bytes32 _what, uint256 _amt) public {}
    function increaseGlobalDebtCeiling(uint256 _amount) public {}
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
    function addReaderToMedianWhitelist(address _median, address _reader) public {}
    function addReaderToOSMWhitelist(address _osm, address _reader) public {}
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

////// lib/dss-interfaces/src/dapp/DSValueAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/dapphub/ds-value/blob/master/src/value.sol
interface DSValueAbstract {
    function has() external view returns (bool);
    function val() external view returns (bytes32);
    function peek() external view returns (bytes32, bool);
    function read() external view returns (bytes32);
    function poke(bytes32) external;
    function void() external;
    function authority() external view returns (address);
    function owner() external view returns (address);
    function setOwner(address) external;
    function setAuthority(address) external;
}

////// lib/dss-interfaces/src/dss/DssAutoLineAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss-auto-line/blob/master/src/DssAutoLine.sol
interface DssAutoLineAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function vat() external view returns (address);
    function ilks(bytes32) external view returns (uint256,uint256,uint48,uint48,uint48);
    function setIlk(bytes32,uint256,uint256,uint256) external;
    function remIlk(bytes32) external;
    function exec(bytes32) external returns (uint256);
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

////// src/Goerli-DssSpell.sol
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
/* pragma experimental ABIEncoderV2; */

/* import "dss-exec-lib/DssExec.sol"; */
/* import "dss-exec-lib/DssAction.sol"; */
/* import "dss-interfaces/dapp/DSValueAbstract.sol"; */
/* import "dss-interfaces/dss/SpotAbstract.sol"; */
/* import "dss-interfaces/dss/DssAutoLineAbstract.sol"; */

interface Fileable_2 {
    function file(bytes32,uint256) external;
}

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/TODO -q -O - 2>/dev/null)"
    string public constant override description = "Goerli Spell";

    // Turn off office hours
    function officeHours() public override returns (bool) {
        return false;
    }

    address constant MCD_JOIN_PSM_USDC_A       = 0xF2f86B76d1027f3777c522406faD710419C80bbB;
    address constant MCD_CLIP_PSM_USDC_A       = 0x8f570B146655Cd52173B0db2DDeb40B7b32c5A9C;
    address constant MCD_CLIP_CALC_PSM_USDC_A  = 0x6eB7f16842b13A1Fbb270Fc952Fb9a73D7c90a0e;
    address constant MCD_PSM_USDC_A            = 0xb480B8dD5A232Cb7B227989Eacda728D1F247dB6;
    bytes32 constant ILK_PSM_USDC_A            = "PSM-USDC-A";

    uint256 constant BILLION = 10 ** 9;
    uint256 constant WAD     = 10 ** 18;
    uint256 constant RAY     = 10 ** 27;
    uint256 constant RAD     = 10 ** 45;

    function actions() public override {
        address USDC = DssExecLib.getChangelogAddress("USDC");
        address PIP_USDC = DssExecLib.getChangelogAddress("PIP_USDC");

        // Fix price stables
        DSValueAbstract(PIP_USDC).poke(bytes32(WAD));
        DSValueAbstract(DssExecLib.getChangelogAddress("PIP_TUSD")).poke(bytes32(WAD));
        DSValueAbstract(DssExecLib.getChangelogAddress("PIP_PAXUSD")).poke(bytes32(WAD));
        DSValueAbstract(DssExecLib.getChangelogAddress("PIP_GUSD")).poke(bytes32(WAD));

        DssExecLib.updateCollateralPrice("USDC-A");
        DssExecLib.updateCollateralPrice("USDC-B");
        DssExecLib.updateCollateralPrice("TUSD-A");
        DssExecLib.updateCollateralPrice("PAXUSD-A");
        DssExecLib.updateCollateralPrice("GUSD-A");
        //

        // Add PSM_USDC_A
        DssExecLib.authorize(MCD_JOIN_PSM_USDC_A, MCD_PSM_USDC_A);

        DssExecLib.addNewCollateral(CollateralOpts({
            ilk: ILK_PSM_USDC_A,
            gem: USDC,
            join: MCD_JOIN_PSM_USDC_A,
            clip: MCD_CLIP_PSM_USDC_A,
            calc: MCD_CLIP_CALC_PSM_USDC_A,
            pip: PIP_USDC,
            isLiquidatable: false,
            isOSM: false,
            whitelistOSM: false,
            ilkDebtCeiling: 0,
            minVaultAmount: 0,
            maxLiquidationAmount: 0,
            liquidationPenalty: 1300,
            ilkStabilityFee: RAY,
            startingPriceFactor: 10500,
            breakerTolerance: 9500,
            auctionDuration: 220 minutes,
            permittedDrop: 9000,
            liquidationRatio: 10000,
            kprFlatReward: 300,
            kprPctReward: 10
        }));

        DssExecLib.setStairstepExponentialDecrease(MCD_CLIP_CALC_PSM_USDC_A, 120 seconds, 9990);
        Fileable_2(MCD_PSM_USDC_A).file("tin", WAD / 1000);

        DssExecLib.setIlkAutoLineParameters(ILK_PSM_USDC_A, 10 * BILLION, 1 * BILLION, 24 hours);
        DssAutoLineAbstract(DssExecLib.autoLine()).exec(ILK_PSM_USDC_A);

        DssExecLib.setChangelogAddress("MCD_JOIN_PSM_USDC_A", MCD_JOIN_PSM_USDC_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_PSM_USDC_A", MCD_CLIP_PSM_USDC_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_PSM_USDC_A", MCD_CLIP_CALC_PSM_USDC_A);
        DssExecLib.setChangelogAddress("MCD_PSM_USDC_A", MCD_PSM_USDC_A);
        //
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}