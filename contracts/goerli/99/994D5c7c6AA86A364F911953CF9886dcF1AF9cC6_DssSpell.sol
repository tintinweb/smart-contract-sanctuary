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

////// lib/dss-interfaces/src/dss/LPOsmAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/univ2-lp-oracle
interface LPOsmAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function stopped() external view returns (uint256);
    function bud(address) external view returns (uint256);
    function dec0() external view returns (uint8);
    function dec1() external view returns (uint8);
    function orb0() external view returns (address);
    function orb1() external view returns (address);
    function wat() external view returns (bytes32);
    function hop() external view returns (uint32);
    function src() external view returns (address);
    function zzz() external view returns (uint64);
    function change(address) external;
    function step(uint256) external;
    function stop() external;
    function start() external;
    function pass() external view returns (bool);
    function poke() external;
    function peek() external view returns (bytes32, bool);
    function peep() external view returns (bytes32, bool);
    function read() external view returns (bytes32);
    function kiss(address) external;
    function diss(address) external;
    function kiss(address[] calldata) external;
    function diss(address[] calldata) external;
    function link(uint256, address) external;
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
/* import "dss-interfaces/dss/MedianAbstract.sol"; */
/* import "dss-interfaces/dss/LPOsmAbstract.sol"; */
/* import "dss-interfaces/dss/IlkRegistryAbstract.sol"; */

interface FaucetLike {
    function setAmt(address,uint256) external;
}

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/TODO -q -O - 2>/dev/null)"
    string public constant override description = "Goerli Spell";

    address constant UNIV2DAIETH                    = 0x5dD9dec52a16d4d1Df10a66ac71d4731c9Dad984;
    address constant PIP_UNIV2DAIETH                = 0x044c9aeD56369aA3f696c898AEd0C38dC53c6C3D;
    address constant MCD_JOIN_UNIV2DAIETH_A         = 0x66931685b532CB4F31abfe804d2408dD34Cd419D;
    address constant MCD_CLIP_UNIV2DAIETH_A         = 0x76a4Ee8acEAAF7F92455277C6e10471F116ffF2c;
    address constant MCD_CLIP_CALC_UNIV2DAIETH_A    = 0x7DCA9CAE2Dc463eBBF05341727FB6ed181D690c2;
    address constant UNIV2WBTCETH                   = 0x7883a92ac3e914F3400e8AE6a2FF05E6BA4Bd403;
    address constant PIP_UNIV2WBTCETH               = 0xD375daC26f7eF991878136b387ca959b9ac1DDaF;
    address constant MCD_JOIN_UNIV2WBTCETH_A        = 0x345a29Db10Aa5CF068D61Bb20F74771eC7DF66FE;
    address constant MCD_CLIP_UNIV2WBTCETH_A        = 0x8520AA6784d51B1984B6f693f1Ea646368d9f868;
    address constant MCD_CLIP_CALC_UNIV2WBTCETH_A   = 0xab5B4759c8D28d05c4cd335a0315A52981F93D04;
    address constant UNIV2USDCETH                   = 0xD90313b3E43D9a922c71d26a0fBCa75A01Bb3Aeb;
    address constant PIP_UNIV2USDCETH               = 0x54ADcaB9B99b1B548764dAB637db751eC66835F0;
    address constant MCD_JOIN_UNIV2USDCETH_A        = 0x46267d84dA4D6e7b2F5A999518Cf5DAF91E204E3;
    address constant MCD_CLIP_UNIV2USDCETH_A        = 0x7424D5319172a3dC57add04dBb48E6323Da4B473;
    address constant MCD_CLIP_CALC_UNIV2USDCETH_A   = 0x83B20C43D92224E128c2b1e0ECb6305B1001FF4f;
    address constant UNIV2DAIUSDC                   = 0x260719B2ef507A86116FC24341ff0994F2097D42;
    address constant PIP_UNIV2DAIUSDC               = 0xEf22289E240cFcCCdCD2B98fdefF167da10f452d;
    address constant MCD_JOIN_UNIV2DAIUSDC_A        = 0x4CEEf4EB4988cb374B0b288D685AeBE4c6d4C41E;
    address constant MCD_CLIP_UNIV2DAIUSDC_A        = 0x04254C28c09C8a09c76653acA92538EC04954341;
    address constant MCD_CLIP_CALC_UNIV2DAIUSDC_A   = 0x3dB02f19D2d1609661f9bD774De23a962642F25B;
    address constant UNIV2ETHUSDT                   = 0xfcB32e1C4A4F1C820c9304B5CFfEDfB91aE2321C;
    address constant PIP_UNIV2ETHUSDT               = 0x974f7f4dC6D91f144c87cc03749c98f85F997bc7;
    address constant MCD_JOIN_UNIV2ETHUSDT_A        = 0x46A8f8e2C0B62f5D7E4c95297bB26a457F358C82;
    address constant MCD_CLIP_UNIV2ETHUSDT_A        = 0x4bBCD4dc8cD4bfc907268AB5AD3aE01e2567f0E1;
    address constant MCD_CLIP_CALC_UNIV2ETHUSDT_A   = 0x9e24c087EbBA685dFD4AF1fC6C31C414f6EfA74f;
    address constant UNIV2LINKETH                   = 0x3361fB8f923D1Aa1A45B2d2eD4B8bdF313a3dA0c;
    address constant PIP_UNIV2LINKETH               = 0x11C884B3FEE1494A666Bb20b6F6144387beAf4A6;
    address constant MCD_JOIN_UNIV2LINKETH_A        = 0x98B7023Aced6D8B889Ad7D340243C3F9c81E8c5F;
    address constant MCD_CLIP_UNIV2LINKETH_A        = 0x71c6d999c54AB5C91589F45Aa5F0E2E782647268;
    address constant MCD_CLIP_CALC_UNIV2LINKETH_A   = 0x30747d2D2f9C23CBCc2ff318c31C15A6f0AA78bF;
    address constant UNIV2UNIETH                    = 0xB80A38E50B2990Ac83e46Fe16631fFBb94F2780b;
    address constant PIP_UNIV2UNIETH                = 0xB18BC24e52C23A77225E7cf088756581EE257Ad8;
    address constant MCD_JOIN_UNIV2UNIETH_A         = 0x52c31E3592352Cd0CBa20Fa73Da42584EC693283;
    address constant MCD_CLIP_UNIV2UNIETH_A         = 0xaBb1F3fBe1c404829BC1807D67126286a71b85dE;
    address constant MCD_CLIP_CALC_UNIV2UNIETH_A    = 0x663D47b5AF171D7b54dfB2A234406903307721b8;
    address constant UNIV2WBTCDAI                   = 0x3f78Bd3980c49611E5FA885f25Ca3a5fCbf0d7A0;
    address constant PIP_UNIV2WBTCDAI               = 0x916fc346910fd25867c81874f7F982a1FB69aac7;
    address constant MCD_JOIN_UNIV2WBTCDAI_A        = 0x04d23e99504d61050CAF46B4ce2dcb9D4135a7fD;
    address constant MCD_CLIP_UNIV2WBTCDAI_A        = 0xee139bB397211A21656046efb2c7a5b255d3bC07;
    address constant MCD_CLIP_CALC_UNIV2WBTCDAI_A   = 0xf89C3DDA6D0f496900ecC39e4a7D31075d360856;
    address constant UNIV2AAVEETH                   = 0xaF2CC6F46d1d0AB30dd45F59B562394c3E21e6f3;
    address constant PIP_UNIV2AAVEETH               = 0xFADF05B56E4b211877248cF11C0847e7F8924e10;
    address constant MCD_JOIN_UNIV2AAVEETH_A        = 0x73C4E5430768e24Fd704291699823f35953bbbA2;
    address constant MCD_CLIP_UNIV2AAVEETH_A        = 0xeA4F6DA7Ac68F9244FCDd13AE2C36647829AfCa0;
    address constant MCD_CLIP_CALC_UNIV2AAVEETH_A   = 0x14F4D6cB78632535230D1591121E35108bbBdAAA;
    address constant UNIV2DAIUSDT                   = 0xBF2C9aBbEC9755A0b6144051E19c6AD4e6fd6D71;
    address constant PIP_UNIV2DAIUSDT               = 0x2fc2706C61Fba5b941381e8838bC646908845db6;
    address constant MCD_JOIN_UNIV2DAIUSDT_A        = 0xBF70Ca17ce5032CCa7cD55a946e96f0E72f79452;
    address constant MCD_CLIP_UNIV2DAIUSDT_A        = 0xABB9ca15E7e261E255560153e312c98F638E57f4;
    address constant MCD_CLIP_CALC_UNIV2DAIUSDT_A   = 0xDD610087b4a029BD63e4990A6A29a077764B632B;

    uint256 constant THOUSAND   = 10 ** 3;
    uint256 constant MILLION    = 10 ** 6;

    // Turn off office hours
    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {
        // UNIV2DAIETH-A
        DssExecLib.addNewCollateral(CollateralOpts({
            ilk:                   "UNIV2DAIETH-A",
            gem:                   UNIV2DAIETH,
            join:                  MCD_JOIN_UNIV2DAIETH_A,
            clip:                  MCD_CLIP_UNIV2DAIETH_A,
            calc:                  MCD_CLIP_CALC_UNIV2DAIETH_A,
            pip:                   PIP_UNIV2DAIETH,
            isLiquidatable:        true,
            isOSM:                 true,
            whitelistOSM:          false,
            ilkDebtCeiling:        5 * MILLION,
            minVaultAmount:        10 * THOUSAND,
            maxLiquidationAmount:  5 * MILLION,
            liquidationPenalty:    1300,
            ilkStabilityFee:       1000000000472114805215157978,
            startingPriceFactor:   11500,
            breakerTolerance:      7000,
            auctionDuration:       215 minutes,
            permittedDrop:         6000,
            liquidationRatio:      12500,
            kprFlatReward:         300,
            kprPctReward:          10
        }));
        MedianAbstract(LPOsmAbstract(PIP_UNIV2DAIETH).orb1()).kiss(PIP_UNIV2DAIETH);
        DssExecLib.setStairstepExponentialDecrease(MCD_CLIP_CALC_UNIV2DAIETH_A, 125 seconds, 9950);
        DssExecLib.setIlkAutoLineParameters("UNIV2DAIETH-A", 50 * MILLION, 5 * MILLION, 8 hours);
        IlkRegistryAbstract(DssExecLib.reg()).update("UNIV2DAIETH-A");
        DssExecLib.setChangelogAddress("UNIV2DAIETH", UNIV2DAIETH);
        DssExecLib.setChangelogAddress("PIP_UNIV2DAIETH", PIP_UNIV2DAIETH);
        DssExecLib.setChangelogAddress("MCD_JOIN_UNIV2DAIETH_A", MCD_JOIN_UNIV2DAIETH_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_UNIV2DAIETH_A", MCD_CLIP_UNIV2DAIETH_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_UNIV2DAIETH_A", MCD_CLIP_CALC_UNIV2DAIETH_A);
        //
        // UNIV2WBTCETH-A
        DssExecLib.addNewCollateral(CollateralOpts({
            ilk:                   "UNIV2WBTCETH-A",
            gem:                   UNIV2WBTCETH,
            join:                  MCD_JOIN_UNIV2WBTCETH_A,
            clip:                  MCD_CLIP_UNIV2WBTCETH_A,
            calc:                  MCD_CLIP_CALC_UNIV2WBTCETH_A,
            pip:                   PIP_UNIV2WBTCETH,
            isLiquidatable:        true,
            isOSM:                 true,
            whitelistOSM:          true,
            ilkDebtCeiling:        3 * MILLION,
            minVaultAmount:        10 * THOUSAND,
            maxLiquidationAmount:  5 * MILLION,
            liquidationPenalty:    1300,
            ilkStabilityFee:       1000000000627937192491029810,
            startingPriceFactor:   13000,
            breakerTolerance:      5000,
            auctionDuration:       200 minutes,
            permittedDrop:         4000,
            liquidationRatio:      15000,
            kprFlatReward:         300,
            kprPctReward:          10
        }));
        DssExecLib.setStairstepExponentialDecrease(MCD_CLIP_CALC_UNIV2WBTCETH_A, 130 seconds, 9900);
        DssExecLib.setIlkAutoLineParameters("UNIV2WBTCETH-A", 20 * MILLION, 3 * MILLION, 8 hours);
        IlkRegistryAbstract(DssExecLib.reg()).update("UNIV2WBTCETH-A");
        DssExecLib.setChangelogAddress("UNIV2WBTCETH", UNIV2WBTCETH);
        DssExecLib.setChangelogAddress("PIP_UNIV2WBTCETH", PIP_UNIV2WBTCETH);
        DssExecLib.setChangelogAddress("MCD_JOIN_UNIV2WBTCETH_A", MCD_JOIN_UNIV2WBTCETH_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_UNIV2WBTCETH_A", MCD_CLIP_UNIV2WBTCETH_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_UNIV2WBTCETH_A", MCD_CLIP_CALC_UNIV2WBTCETH_A);
        //
        // UNIV2USDCETH-A
        DssExecLib.addNewCollateral(CollateralOpts({
            ilk:                   "UNIV2USDCETH-A",
            gem:                   UNIV2USDCETH,
            join:                  MCD_JOIN_UNIV2USDCETH_A,
            clip:                  MCD_CLIP_UNIV2USDCETH_A,
            calc:                  MCD_CLIP_CALC_UNIV2USDCETH_A,
            pip:                   PIP_UNIV2USDCETH,
            isLiquidatable:        true,
            isOSM:                 true,
            whitelistOSM:          false,
            ilkDebtCeiling:        5 * MILLION,
            minVaultAmount:        10 * THOUSAND,
            maxLiquidationAmount:  5 * MILLION,
            liquidationPenalty:    1300,
            ilkStabilityFee:       1000000000627937192491029810,
            startingPriceFactor:   11500,
            breakerTolerance:      7000,
            auctionDuration:       215 minutes,
            permittedDrop:         6000,
            liquidationRatio:      12500,
            kprFlatReward:         300,
            kprPctReward:          10
        }));
        MedianAbstract(LPOsmAbstract(PIP_UNIV2USDCETH).orb1()).kiss(PIP_UNIV2USDCETH);
        DssExecLib.setStairstepExponentialDecrease(MCD_CLIP_CALC_UNIV2USDCETH_A, 125 seconds, 9950);
        DssExecLib.setIlkAutoLineParameters("UNIV2USDCETH-A", 50 * MILLION, 5 * MILLION, 8 hours);
        IlkRegistryAbstract(DssExecLib.reg()).update("UNIV2USDCETH-A");
        DssExecLib.setChangelogAddress("UNIV2USDCETH", UNIV2USDCETH);
        DssExecLib.setChangelogAddress("PIP_UNIV2USDCETH", PIP_UNIV2USDCETH);
        DssExecLib.setChangelogAddress("MCD_JOIN_UNIV2USDCETH_A", MCD_JOIN_UNIV2USDCETH_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_UNIV2USDCETH_A", MCD_CLIP_UNIV2USDCETH_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_UNIV2USDCETH_A", MCD_CLIP_CALC_UNIV2USDCETH_A);
        //
        // UNIV2DAIUSDC-A
        DssExecLib.addNewCollateral(CollateralOpts({
            ilk:                   "UNIV2DAIUSDC-A",
            gem:                   UNIV2DAIUSDC,
            join:                  MCD_JOIN_UNIV2DAIUSDC_A,
            clip:                  MCD_CLIP_UNIV2DAIUSDC_A,
            calc:                  MCD_CLIP_CALC_UNIV2DAIUSDC_A,
            pip:                   PIP_UNIV2DAIUSDC,
            isLiquidatable:        false,
            isOSM:                 true,
            whitelistOSM:          false,
            ilkDebtCeiling:        10 * MILLION,
            minVaultAmount:        10 * THOUSAND,
            maxLiquidationAmount:  0,
            liquidationPenalty:    1300,
            ilkStabilityFee:       1000000000000000000000000000,
            startingPriceFactor:   10500,
            breakerTolerance:      9500,
            auctionDuration:       220 minutes,
            permittedDrop:         9000,
            liquidationRatio:      10200,
            kprFlatReward:         300,
            kprPctReward:          10
        }));
        DssExecLib.setStairstepExponentialDecrease(MCD_CLIP_CALC_UNIV2DAIUSDC_A, 120 seconds, 9990);
        DssExecLib.setIlkAutoLineParameters("UNIV2DAIUSDC-A", 250 * MILLION, 10 * MILLION, 8 hours);
        IlkRegistryAbstract(DssExecLib.reg()).update("UNIV2DAIUSDC-A");
        DssExecLib.setChangelogAddress("UNIV2DAIUSDC", UNIV2DAIUSDC);
        DssExecLib.setChangelogAddress("PIP_UNIV2DAIUSDC", PIP_UNIV2DAIUSDC);
        DssExecLib.setChangelogAddress("MCD_JOIN_UNIV2DAIUSDC_A", MCD_JOIN_UNIV2DAIUSDC_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_UNIV2DAIUSDC_A", MCD_CLIP_UNIV2DAIUSDC_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_UNIV2DAIUSDC_A", MCD_CLIP_CALC_UNIV2DAIUSDC_A);
        //
        // UNIV2ETHUSDT-A
        DssExecLib.addNewCollateral(CollateralOpts({
            ilk:                   "UNIV2ETHUSDT-A",
            gem:                   UNIV2ETHUSDT,
            join:                  MCD_JOIN_UNIV2ETHUSDT_A,
            clip:                  MCD_CLIP_UNIV2ETHUSDT_A,
            calc:                  MCD_CLIP_CALC_UNIV2ETHUSDT_A,
            pip:                   PIP_UNIV2ETHUSDT,
            isLiquidatable:        true,
            isOSM:                 true,
            whitelistOSM:          true,
            ilkDebtCeiling:        0,
            minVaultAmount:        10 * THOUSAND,
            maxLiquidationAmount:  5 * MILLION,
            liquidationPenalty:    1300,
            ilkStabilityFee:       1000000000627937192491029810,
            startingPriceFactor:   11500,
            breakerTolerance:      7000,
            auctionDuration:       215 minutes,
            permittedDrop:         6000,
            liquidationRatio:      14000,
            kprFlatReward:         300,
            kprPctReward:          10
        }));
        DssExecLib.setStairstepExponentialDecrease(MCD_CLIP_CALC_UNIV2ETHUSDT_A, 125 seconds, 9950);
        IlkRegistryAbstract(DssExecLib.reg()).update("UNIV2ETHUSDT-A");
        DssExecLib.setChangelogAddress("UNIV2ETHUSDT", UNIV2ETHUSDT);
        DssExecLib.setChangelogAddress("PIP_UNIV2ETHUSDT", PIP_UNIV2ETHUSDT);
        DssExecLib.setChangelogAddress("MCD_JOIN_UNIV2ETHUSDT_A", MCD_JOIN_UNIV2ETHUSDT_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_UNIV2ETHUSDT_A", MCD_CLIP_UNIV2ETHUSDT_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_UNIV2ETHUSDT_A", MCD_CLIP_CALC_UNIV2ETHUSDT_A);
        //
        // UNIV2LINKETH-A
        DssExecLib.addNewCollateral(CollateralOpts({
            ilk:                   "UNIV2LINKETH-A",
            gem:                   UNIV2LINKETH,
            join:                  MCD_JOIN_UNIV2LINKETH_A,
            clip:                  MCD_CLIP_UNIV2LINKETH_A,
            calc:                  MCD_CLIP_CALC_UNIV2LINKETH_A,
            pip:                   PIP_UNIV2LINKETH,
            isLiquidatable:        true,
            isOSM:                 true,
            whitelistOSM:          true,
            ilkDebtCeiling:        2 * MILLION,
            minVaultAmount:        10 * THOUSAND,
            maxLiquidationAmount:  3 * MILLION,
            liquidationPenalty:    1300,
            ilkStabilityFee:       1000000000937303470807876289,
            startingPriceFactor:   13000,
            breakerTolerance:      5000,
            auctionDuration:       200 minutes,
            permittedDrop:         4000,
            liquidationRatio:      16500,
            kprFlatReward:         300,
            kprPctReward:          10
        }));
        DssExecLib.setStairstepExponentialDecrease(MCD_CLIP_CALC_UNIV2LINKETH_A, 130 seconds, 9900);
        DssExecLib.setIlkAutoLineParameters("UNIV2LINKETH-A", 20 * MILLION, 2 * MILLION, 8 hours);
        IlkRegistryAbstract(DssExecLib.reg()).update("UNIV2LINKETH-A");
        DssExecLib.setChangelogAddress("UNIV2LINKETH", UNIV2LINKETH);
        DssExecLib.setChangelogAddress("PIP_UNIV2LINKETH", PIP_UNIV2LINKETH);
        DssExecLib.setChangelogAddress("MCD_JOIN_UNIV2LINKETH_A", MCD_JOIN_UNIV2LINKETH_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_UNIV2LINKETH_A", MCD_CLIP_UNIV2LINKETH_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_UNIV2LINKETH_A", MCD_CLIP_CALC_UNIV2LINKETH_A);
        //
        // UNIV2UNIETH-A
        DssExecLib.addNewCollateral(CollateralOpts({
            ilk:                   "UNIV2UNIETH-A",
            gem:                   UNIV2UNIETH,
            join:                  MCD_JOIN_UNIV2UNIETH_A,
            clip:                  MCD_CLIP_UNIV2UNIETH_A,
            calc:                  MCD_CLIP_CALC_UNIV2UNIETH_A,
            pip:                   PIP_UNIV2UNIETH,
            isLiquidatable:        true,
            isOSM:                 true,
            whitelistOSM:          true,
            ilkDebtCeiling:        2 * MILLION,
            minVaultAmount:        10 * THOUSAND,
            maxLiquidationAmount:  3 * MILLION,
            liquidationPenalty:    1300,
            ilkStabilityFee:       1000000000627937192491029810,
            startingPriceFactor:   13000,
            breakerTolerance:      5000,
            auctionDuration:       200 minutes,
            permittedDrop:         4000,
            liquidationRatio:      16500,
            kprFlatReward:         300,
            kprPctReward:          10
        }));
        DssExecLib.setStairstepExponentialDecrease(MCD_CLIP_CALC_UNIV2UNIETH_A, 130 seconds, 9900);
        DssExecLib.setIlkAutoLineParameters("UNIV2UNIETH-A", 20 * MILLION, 3 * MILLION, 8 hours);
        IlkRegistryAbstract(DssExecLib.reg()).update("UNIV2UNIETH-A");
        DssExecLib.setChangelogAddress("UNIV2UNIETH", UNIV2UNIETH);
        DssExecLib.setChangelogAddress("PIP_UNIV2UNIETH", PIP_UNIV2UNIETH);
        DssExecLib.setChangelogAddress("MCD_JOIN_UNIV2UNIETH_A", MCD_JOIN_UNIV2UNIETH_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_UNIV2UNIETH_A", MCD_CLIP_UNIV2UNIETH_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_UNIV2UNIETH_A", MCD_CLIP_CALC_UNIV2UNIETH_A);
        //
        // UNIV2WBTCDAI-A
        DssExecLib.addNewCollateral(CollateralOpts({
            ilk:                   "UNIV2WBTCDAI-A",
            gem:                   UNIV2WBTCDAI,
            join:                  MCD_JOIN_UNIV2WBTCDAI_A,
            clip:                  MCD_CLIP_UNIV2WBTCDAI_A,
            calc:                  MCD_CLIP_CALC_UNIV2WBTCDAI_A,
            pip:                   PIP_UNIV2WBTCDAI,
            isLiquidatable:        true,
            isOSM:                 true,
            whitelistOSM:          false,
            ilkDebtCeiling:        3 * MILLION,
            minVaultAmount:        10 * THOUSAND,
            maxLiquidationAmount:  5 * MILLION,
            liquidationPenalty:    1300,
            ilkStabilityFee:       1000000000000000000000000000,
            startingPriceFactor:   11500,
            breakerTolerance:      7000,
            auctionDuration:       215 minutes,
            permittedDrop:         6000,
            liquidationRatio:      12500,
            kprFlatReward:         300,
            kprPctReward:          10
        }));
        MedianAbstract(LPOsmAbstract(PIP_UNIV2WBTCDAI).orb1()).kiss(PIP_UNIV2WBTCDAI);
        DssExecLib.setStairstepExponentialDecrease(MCD_CLIP_CALC_UNIV2WBTCDAI_A, 125 seconds, 9950);
        DssExecLib.setIlkAutoLineParameters("UNIV2WBTCDAI-A", 20 * MILLION, 3 * MILLION, 8 hours);
        IlkRegistryAbstract(DssExecLib.reg()).update("UNIV2WBTCDAI-A");
        DssExecLib.setChangelogAddress("UNIV2WBTCDAI", UNIV2WBTCDAI);
        DssExecLib.setChangelogAddress("PIP_UNIV2WBTCDAI", PIP_UNIV2WBTCDAI);
        DssExecLib.setChangelogAddress("MCD_JOIN_UNIV2WBTCDAI_A", MCD_JOIN_UNIV2WBTCDAI_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_UNIV2WBTCDAI_A", MCD_CLIP_UNIV2WBTCDAI_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_UNIV2WBTCDAI_A", MCD_CLIP_CALC_UNIV2WBTCDAI_A);
        //
        // UNIV2AAVEETH-A
        DssExecLib.addNewCollateral(CollateralOpts({
            ilk:                   "UNIV2AAVEETH-A",
            gem:                   UNIV2AAVEETH,
            join:                  MCD_JOIN_UNIV2AAVEETH_A,
            clip:                  MCD_CLIP_UNIV2AAVEETH_A,
            calc:                  MCD_CLIP_CALC_UNIV2AAVEETH_A,
            pip:                   PIP_UNIV2AAVEETH,
            isLiquidatable:        true,
            isOSM:                 true,
            whitelistOSM:          true,
            ilkDebtCeiling:        2 * MILLION,
            minVaultAmount:        10 * THOUSAND,
            maxLiquidationAmount:  3 * MILLION,
            liquidationPenalty:    1300,
            ilkStabilityFee:       1000000000937303470807876289,
            startingPriceFactor:   13000,
            breakerTolerance:      5000,
            auctionDuration:       200 minutes,
            permittedDrop:         4000,
            liquidationRatio:      16500,
            kprFlatReward:         300,
            kprPctReward:          10
        }));
        DssExecLib.setStairstepExponentialDecrease(MCD_CLIP_CALC_UNIV2AAVEETH_A, 130 seconds, 9900);
        DssExecLib.setIlkAutoLineParameters("UNIV2AAVEETH-A", 20 * MILLION, 2 * MILLION, 8 hours);
        IlkRegistryAbstract(DssExecLib.reg()).update("UNIV2AAVEETH-A");
        DssExecLib.setChangelogAddress("UNIV2AAVEETH", UNIV2AAVEETH);
        DssExecLib.setChangelogAddress("PIP_UNIV2AAVEETH", PIP_UNIV2AAVEETH);
        DssExecLib.setChangelogAddress("MCD_JOIN_UNIV2AAVEETH_A", MCD_JOIN_UNIV2AAVEETH_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_UNIV2AAVEETH_A", MCD_CLIP_UNIV2AAVEETH_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_UNIV2AAVEETH_A", MCD_CLIP_CALC_UNIV2AAVEETH_A);
        //
        // UNIV2DAIUSDT-A
        DssExecLib.addNewCollateral(CollateralOpts({
            ilk:                   "UNIV2DAIUSDT-A",
            gem:                   UNIV2DAIUSDT,
            join:                  MCD_JOIN_UNIV2DAIUSDT_A,
            clip:                  MCD_CLIP_UNIV2DAIUSDT_A,
            calc:                  MCD_CLIP_CALC_UNIV2DAIUSDT_A,
            pip:                   PIP_UNIV2DAIUSDT,
            isLiquidatable:        true,
            isOSM:                 true,
            whitelistOSM:          false,
            ilkDebtCeiling:        0,
            minVaultAmount:        10 * THOUSAND,
            maxLiquidationAmount:  5 * MILLION,
            liquidationPenalty:    1300,
            ilkStabilityFee:       1000000000627937192491029810,
            startingPriceFactor:   10500,
            breakerTolerance:      9500,
            auctionDuration:       220 minutes,
            permittedDrop:         9000,
            liquidationRatio:      12500,
            kprFlatReward:         300,
            kprPctReward:          10
        }));
        MedianAbstract(LPOsmAbstract(PIP_UNIV2DAIUSDT).orb1()).kiss(PIP_UNIV2DAIUSDT);
        DssExecLib.setStairstepExponentialDecrease(MCD_CLIP_CALC_UNIV2DAIUSDT_A, 120 seconds, 9990);
        IlkRegistryAbstract(DssExecLib.reg()).update("UNIV2DAIUSDT-A");
        DssExecLib.setChangelogAddress("UNIV2DAIUSDT", UNIV2DAIUSDT);
        DssExecLib.setChangelogAddress("PIP_UNIV2DAIUSDT", PIP_UNIV2DAIUSDT);
        DssExecLib.setChangelogAddress("MCD_JOIN_UNIV2DAIUSDT_A", MCD_JOIN_UNIV2DAIUSDT_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_UNIV2DAIUSDT_A", MCD_CLIP_UNIV2DAIUSDT_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_UNIV2DAIUSDT_A", MCD_CLIP_CALC_UNIV2DAIUSDT_A);
        //
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}