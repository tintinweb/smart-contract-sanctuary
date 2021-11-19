/**
 *Submitted for verification at Etherscan.io on 2021-11-19
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
    function setChangelogVersion(string memory _version) public {}
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
    function setIlkAutoLineDebtCeiling(bytes32 _ilk, uint256 _amount) public {}
    function removeIlkFromAutoLine(bytes32 _ilk) public {}
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

////// lib/dss-interfaces/src/ERC/GemAbstract.sol
/* pragma solidity >=0.5.12; */

// A base ERC-20 abstract class
// https://eips.ethereum.org/EIPS/eip-20
interface GemAbstract {
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

////// lib/dss-interfaces/src/dapp/DSAuthorityAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/dapphub/ds-auth
interface DSAuthorityAbstract {
    function canCall(address, address, bytes4) external view returns (bool);
}

interface DSAuthAbstract {
    function authority() external view returns (address);
    function owner() external view returns (address);
    function setOwner(address) external;
    function setAuthority(address) external;
}

////// lib/dss-interfaces/src/dapp/DSChiefAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/dapphub/ds-chief
interface DSChiefAbstract {
    function live() external view returns (uint256);
    function launch() external;
    function slates(bytes32) external view returns (address[] memory);
    function votes(address) external view returns (bytes32);
    function approvals(address) external view returns (uint256);
    function deposits(address) external view returns (address);
    function GOV() external view returns (address);
    function IOU() external view returns (address);
    function hat() external view returns (address);
    function MAX_YAYS() external view returns (uint256);
    function lock(uint256) external;
    function free(uint256) external;
    function etch(address[] calldata) external returns (bytes32);
    function vote(address[] calldata) external returns (bytes32);
    function vote(bytes32) external;
    function lift(address) external;
    function setOwner(address) external;
    function setAuthority(address) external;
    function isUserRoot(address) external view returns (bool);
    function setRootUser(address, bool) external;
    function _root_users(address) external view returns (bool);
    function _user_roles(address) external view returns (bytes32);
    function _capability_roles(address, bytes4) external view returns (bytes32);
    function _public_capabilities(address, bytes4) external view returns (bool);
    function getUserRoles(address) external view returns (bytes32);
    function getCapabilityRoles(address, bytes4) external view returns (bytes32);
    function isCapabilityPublic(address, bytes4) external view returns (bool);
    function hasUserRole(address, uint8) external view returns (bool);
    function canCall(address, address, bytes4) external view returns (bool);
    function setUserRole(address, uint8, bool) external;
    function setPublicCapability(address, bytes4, bool) external;
    function setRoleCapability(uint8, address, bytes4, bool) external;
}

interface DSChiefFabAbstract {
    function newChief(address, uint256) external returns (address);
}

////// lib/dss-interfaces/src/dapp/DSPauseAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/dapphub/ds-pause
interface DSPauseAbstract {
    function owner() external view returns (address);
    function authority() external view returns (address);
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

////// lib/dss-interfaces/src/dapp/DSPauseProxyAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/dapphub/ds-pause
interface DSPauseProxyAbstract {
    function owner() external view returns (address);
    function exec(address, bytes calldata) external returns (bytes memory);
}

////// lib/dss-interfaces/src/dapp/DSRolesAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/dapphub/ds-roles
interface DSRolesAbstract {
    function _root_users(address) external view returns (bool);
    function _user_roles(address) external view returns (bytes32);
    function _capability_roles(address, bytes4) external view returns (bytes32);
    function _public_capabilities(address, bytes4) external view returns (bool);
    function getUserRoles(address) external view returns (bytes32);
    function getCapabilityRoles(address, bytes4) external view returns (bytes32);
    function isUserRoot(address) external view returns (bool);
    function isCapabilityPublic(address, bytes4) external view returns (bool);
    function hasUserRole(address, uint8) external view returns (bool);
    function canCall(address, address, bytes4) external view returns (bool);
    function setRootUser(address, bool) external;
    function setUserRole(address, uint8, bool) external;
    function setPublicCapability(address, bytes4, bool) external;
    function setRoleCapability(uint8, address, bytes4, bool) external;
    function authority() external view returns (address);
    function owner() external view returns (address);
    function setOwner(address) external;
    function setAuthority(address) external;
}

////// lib/dss-interfaces/src/dapp/DSRuneAbstract.sol

// Copyright (C) 2020 Maker Foundation
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

// https://github.com/makerdao/dss-spellbook
interface DSRuneAbstract {
    // @return [address] A contract address conforming to DSPauseAbstract
    function pause()    external view returns (address);
    // @return [address] The address of the contract to be executed
    // TODO: is `action()` a required field? Not all spells rely on a seconary contract.
    function action()   external view returns (address);
    // @return [bytes32] extcodehash of rune address
    function tag()      external view returns (bytes32);
    // @return [bytes] The `abi.encodeWithSignature()` result of the function to be called.
    function sig()      external view returns (bytes memory);
    // @return [uint256] Earliest time rune can execute
    function eta()      external view returns (uint256);
    // The schedule() function plots the rune in the DSPause
    function schedule() external;
    // @return [bool] true if the rune has been cast()
    function done()     external view returns (bool);
    // The cast() function executes the rune
    function cast()     external;
}

////// lib/dss-interfaces/src/dapp/DSSpellAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/dapphub/ds-spell
interface DSSpellAbstract {
    function whom() external view returns (address);
    function mana() external view returns (uint256);
    function data() external view returns (bytes memory);
    function done() external view returns (bool);
    function cast() external;
}

////// lib/dss-interfaces/src/dapp/DSThingAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/dapphub/ds-thing
interface DSThingAbstract {
    function authority() external view returns (address);
    function owner() external view returns (address);
    function setOwner(address) external;
    function setAuthority(address) external;
}

////// lib/dss-interfaces/src/dapp/DSTokenAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/dapphub/ds-token/blob/master/src/token.sol
interface DSTokenAbstract {
    function name() external view returns (bytes32);
    function symbol() external view returns (bytes32);
    function decimals() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function approve(address) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function push(address, uint256) external;
    function pull(address, uint256) external;
    function move(address, address, uint256) external;
    function mint(uint256) external;
    function mint(address,uint) external;
    function burn(uint256) external;
    function burn(address,uint) external;
    function setName(bytes32) external;
    function authority() external view returns (address);
    function owner() external view returns (address);
    function setOwner(address) external;
    function setAuthority(address) external;
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

////// lib/dss-interfaces/src/dss/AuthGemJoinAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss-deploy/blob/master/src/join.sol
interface AuthGemJoinAbstract {
    function vat() external view returns (address);
    function ilk() external view returns (bytes32);
    function gem() external view returns (address);
    function dec() external view returns (uint256);
    function live() external view returns (uint256);
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function cage() external;
    function join(address, uint256) external;
    function exit(address, uint256) external;
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

// Helper function for returning address or abstract of Chainlog
//  Valid on Mainnet, Kovan, Rinkeby, Ropsten, and Goerli
contract ChainlogHelper {
    address          public constant ADDRESS  = 0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F;
    ChainlogAbstract public constant ABSTRACT = ChainlogAbstract(ADDRESS);
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

////// lib/dss-interfaces/src/dss/DaiAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/dai.sol
interface DaiAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function version() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function nonces(address) external view returns (uint256);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external view returns (bytes32);
    function transfer(address, uint256) external;
    function transferFrom(address, address, uint256) external returns (bool);
    function mint(address, uint256) external;
    function burn(address, uint256) external;
    function approve(address, uint256) external returns (bool);
    function push(address, uint256) external;
    function pull(address, uint256) external;
    function move(address, address, uint256) external;
    function permit(address, address, uint256, uint256, bool, uint8, bytes32, bytes32) external;
}

////// lib/dss-interfaces/src/dss/DaiJoinAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/join.sol
interface DaiJoinAbstract {
    function wards(address) external view returns (uint256);
    function rely(address usr) external;
    function deny(address usr) external;
    function vat() external view returns (address);
    function dai() external view returns (address);
    function live() external view returns (uint256);
    function cage() external;
    function join(address, uint256) external;
    function exit(address, uint256) external;
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

////// lib/dss-interfaces/src/dss/DssCdpManager.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss-cdp-manager/
interface DssCdpManagerAbstract {
    function vat() external view returns (address);
    function cdpi() external view returns (uint256);
    function urns(uint256) external view returns (address);
    function list(uint256) external view returns (uint256,uint256);
    function owns(uint256) external view returns (address);
    function ilks(uint256) external view returns (bytes32);
    function first(address) external view returns (uint256);
    function last(address) external view returns (uint256);
    function count(address) external view returns (uint256);
    function cdpCan(address, uint256, address) external returns (uint256);
    function urnCan(address, address) external returns (uint256);
    function cdpAllow(uint256, address, uint256) external;
    function urnAllow(address, uint256) external;
    function open(bytes32, address) external returns (uint256);
    function give(uint256, address) external;
    function frob(uint256, int256, int256) external;
    function flux(uint256, address, uint256) external;
    function flux(bytes32, uint256, address, uint256) external;
    function move(uint256, address, uint256) external;
    function quit(uint256, address) external;
    function enter(address, uint256) external;
    function shift(uint256, uint256) external;
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

////// lib/dss-interfaces/src/dss/ETHJoinAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/join.sol
interface ETHJoinAbstract {
    function wards(address) external view returns (uint256);
    function rely(address usr) external;
    function deny(address usr) external;
    function vat() external view returns (address);
    function ilk() external view returns (bytes32);
    function live() external view returns (uint256);
    function cage() external;
    function join(address) external payable;
    function exit(address, uint256) external;
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

////// lib/dss-interfaces/src/dss/ExponentialDecreaseAbstract.sol

/// ExponentialDecreaseAbstract.sol -- Exponential Decrease Interface

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

interface ExponentialDecreaseAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function cut() external view returns (uint256);
    function file(bytes32,uint256) external;
    function price(uint256,uint256) external view returns (uint256);
}

////// lib/dss-interfaces/src/dss/FaucetAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/token-faucet/blob/master/src/RestrictedTokenFaucet.sol
interface FaucetAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function list(address) external view returns (uint256);
    function hope(address) external;
    function nope(address) external;
    function amt(address) external view returns (uint256);
    function done(address, address) external view returns (bool);
    function gulp(address) external;
    function gulp(address, address[] calldata) external;
    function shut(address) external;
    function undo(address, address) external;
    function setAmt(address, uint256) external;
}

////// lib/dss-interfaces/src/dss/FlapAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/flap.sol
interface FlapAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function bids(uint256) external view returns (uint256, uint256, address, uint48, uint48);
    function vat() external view returns (address);
    function gem() external view returns (address);
    function beg() external view returns (uint256);
    function ttl() external view returns (uint48);
    function tau() external view returns (uint48);
    function kicks() external view returns (uint256);
    function live() external view returns (uint256);
    function file(bytes32, uint256) external;
    function kick(uint256, uint256) external returns (uint256);
    function tick(uint256) external;
    function tend(uint256, uint256, uint256) external;
    function deal(uint256) external;
    function cage(uint256) external;
    function yank(uint256) external;
}

////// lib/dss-interfaces/src/dss/FlashAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss-flash/blob/master/src/flash.sol
interface FlashAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function vat() external view returns (address);
    function daiJoin() external view returns (address);
    function dai() external view returns (address);
    function vow() external view returns (address);
    function max() external view returns (uint256);
    function toll() external view returns (uint256);
    function CALLBACK_SUCCESS() external view returns (bytes32);
    function CALLBACK_SUCCESS_VAT_DAI() external view returns (bytes32);
    function file(bytes32, uint256) external;
    function maxFlashLoan(address) external view returns (uint256);
    function flashFee(address, uint256) external view returns (uint256);
    function flashLoan(address, address, uint256, bytes calldata) external returns (bool);
    function vatDaiFlashLoan(address, uint256, bytes calldata) external returns (bool);
    function convert() external;
    function accrue() external;
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

////// lib/dss-interfaces/src/dss/FlipperMomAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/flipper-mom/blob/master/src/FlipperMom.sol
interface FlipperMomAbstract {
    function owner() external view returns (address);
    function authority() external view returns (address);
    function setOwner(address) external;
    function setAuthority(address) external;
    function cat() external returns (address);
    function rely(address) external;
    function deny(address) external;
}

////// lib/dss-interfaces/src/dss/FlopAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/flop.sol
interface FlopAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function bids(uint256) external view returns (uint256, uint256, address, uint48, uint48);
    function vat() external view returns (address);
    function gem() external view returns (address);
    function beg() external view returns (uint256);
    function pad() external view returns (uint256);
    function ttl() external view returns (uint48);
    function tau() external view returns (uint48);
    function kicks() external view returns (uint256);
    function live() external view returns (uint256);
    function vow() external view returns (address);
    function file(bytes32, uint256) external;
    function kick(address, uint256, uint256) external returns (uint256);
    function tick(uint256) external;
    function dent(uint256, uint256, uint256) external;
    function deal(uint256) external;
    function cage() external;
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

////// lib/dss-interfaces/src/dss/GemJoinImplementationAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss-deploy/blob/master/src/join.sol
interface GemJoinImplementationAbstract {
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
    function setImplementation(address, uint256) external;
}

////// lib/dss-interfaces/src/dss/GemJoinManagedAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss-gem-joins/blob/master/src/join-managed.sol
interface GemJoinManagedAbstract {
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
    function exit(address, address, uint256) external;
}

////// lib/dss-interfaces/src/dss/GetCdpsAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss-cdp-manager/blob/master/src/GetCdps.sol
interface GetCdpsAbstract {
    function getCdpsAsc(address, address) external view returns (uint256[] memory, address[] memory, bytes32[] memory);
    function getCdpsDesc(address, address) external view returns (uint256[] memory, address[] memory, bytes32[] memory);
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

////// lib/dss-interfaces/src/dss/LerpAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss-lerp/blob/master/src/Lerp.sol
interface LerpAbstract_1 {
    function target() external view returns (address);
    function what() external view returns (bytes32);
    function start() external view returns (uint256);
    function end() external view returns (uint256);
    function duration() external view returns (uint256);
    function done() external view returns (bool);
    function startTime() external view returns (uint256);
    function tick() external;
    function ilk() external view returns (bytes32);
}

////// lib/dss-interfaces/src/dss/LerpFactoryAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss-lerp/blob/master/src/LerpFactory.sol
interface LerpFactoryAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function lerps(bytes32) external view returns (address);
    function active(uint256) external view returns (address);
    function newLerp(bytes32, address, bytes32, uint256, uint256, uint256, uint256) external view returns (address);
    function newIlkLerp(bytes32, address, bytes32, bytes32, uint256, uint256, uint256, uint256) external view returns (address);
    function tall() external;
    function count() external view returns (uint256);
    function list() external view returns (address[] memory);
}

////// lib/dss-interfaces/src/dss/LinearDecreaseAbstract.sol

/// LinearDecreaseAbstract.sol -- Linear Decrease Interface

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

interface LinearDecreaseAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function tau() external view returns (uint256);
    function file(bytes32,uint256) external;
    function price(uint256,uint256) external view returns (uint256);
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

////// lib/dss-interfaces/src/dss/MkrAuthorityAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/mkr-authority/blob/master/src/MkrAuthority.sol
interface MkrAuthorityAbstract {
    function root() external returns (address);
    function setRoot(address) external;
    function wards(address) external returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function canCall(address, address, bytes4) external returns (bool);
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

////// lib/dss-interfaces/src/dss/PotAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss/blob/master/src/pot.sol
interface PotAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function pie(address) external view returns (uint256);
    function Pie() external view returns (uint256);
    function dsr() external view returns (uint256);
    function chi() external view returns (uint256);
    function vat() external view returns (address);
    function vow() external view returns (address);
    function rho() external view returns (uint256);
    function live() external view returns (uint256);
    function file(bytes32, uint256) external;
    function file(bytes32, address) external;
    function cage() external;
    function drip() external returns (uint256);
    function join(uint256) external;
    function exit(uint256) external;
}

////// lib/dss-interfaces/src/dss/PotHelper.sol
/* pragma solidity >=0.5.12; */

/* import { PotAbstract } from "./PotAbstract.sol"; */

// https://github.com/makerdao/dss/blob/master/src/pot.sol
contract PotHelper {

    PotAbstract pa;

    constructor(address _pot) public {
        pa = PotAbstract(_pot);
    }

    // https://github.com/makerdao/dss/blob/master/src/pot.sol#L79
    uint256 constant ONE = 10 ** 27;

    function _mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function _rmul(uint x, uint y) internal pure returns (uint z) {
        z = _mul(x, y) / ONE;
    }

    function rpow(uint x, uint n, uint base) internal pure returns (uint z) {
        assembly {
            switch x case 0 {switch n case 0 {z := base} default {z := 0}}
            default {
                switch mod(n, 2) case 0 { z := base } default { z := x }
                let half := div(base, 2)  // for rounding.
                for { n := div(n, 2) } n { n := div(n,2) } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) { revert(0,0) }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) { revert(0,0) }
                    x := div(xxRound, base)
                    if mod(n,2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) { revert(0,0) }
                        z := div(zxRound, base)
                    }
                }
            }
        }
    }

    // View function for calculating value of chi iff drip() is called in the same block.
    function drop() external view returns (uint256) {
        if (block.timestamp == pa.rho()) return pa.chi();
        return _rmul(rpow(pa.dsr(), block.timestamp - pa.rho(), ONE), pa.chi());
    }

    // Pass the Pot Abstract for additional operations
    function pot() external view returns (PotAbstract) {
        return pa;
    }
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

////// lib/dss-interfaces/src/dss/StairstepExponentialDecreaseAbstract.sol

/// StairstepExponentialDecreaseAbstract.sol -- StairstepExponentialDecrease Interface

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

interface StairstepExponentialDecreaseAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function step() external view returns (uint256);
    function cut() external view returns (uint256);
    function file(bytes32,uint256) external;
    function price(uint256,uint256) external view returns (uint256);
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

////// lib/dss-interfaces/src/dss/VestAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss-vest/blob/master/src/DssVest.sol
interface VestAbstract {
    function TWENTY_YEARS() external view returns (uint256);
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function awards(uint256) external view returns (address, uint48, uint48, uint48, address, uint8, uint128, uint128);
    function ids() external view returns (uint256);
    function cap() external view returns (uint256);
    function usr(uint256) external view returns (address);
    function bgn(uint256) external view returns (uint256);
    function clf(uint256) external view returns (uint256);
    function fin(uint256) external view returns (uint256);
    function mgr(uint256) external view returns (address);
    function res(uint256) external view returns (uint256);
    function tot(uint256) external view returns (uint256);
    function rxd(uint256) external view returns (uint256);
    function file(bytes32, uint256) external;
    function create(address, uint256, uint256, uint256, uint256, address) external returns (uint256);
    function vest(uint256) external;
    function vest(uint256, uint256) external;
    function accrued(uint256) external view returns (uint256);
    function unpaid(uint256) external view returns (uint256);
    function restrict(uint256) external;
    function unrestrict(uint256) external;
    function yank(uint256) external;
    function yank(uint256, uint256) external;
    function move(uint256, address) external;
    function valid(uint256) external view returns (bool);
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

////// lib/dss-interfaces/src/sai/GemPitAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/sai/blob/master/src/pit.sol
interface GemPitAbstract {
    function burn(address) external;
}

////// lib/dss-interfaces/src/sai/SaiMomAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/sai/blob/master/src/mom.sol
interface SaiMomAbstract {
    function tub() external view returns (address);
    function tap() external view returns (address);
    function vox() external view returns (address);
    function setCap(uint256) external;
    function setMat(uint256) external;
    function setTax(uint256) external;
    function setFee(uint256) external;
    function setAxe(uint256) external;
    function setTubGap(uint256) external;
    function setPip(address) external;
    function setPep(address) external;
    function setVox(address) external;
    function setTapGap(uint256) external;
    function setWay(uint256) external;
    function setHow(uint256) external;
    function authority() external view returns (address);
    function owner() external view returns (address);
    function setOwner(address) external;
    function setAuthority(address) external;
}

////// lib/dss-interfaces/src/sai/SaiTapAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/sai/blob/master/src/tap.sol
interface SaiTapAbstract {
    function sai() external view returns (address);
    function sin() external view returns (address);
    function skr() external view returns (address);
    function vox() external view returns (address);
    function tub() external view returns (address);
    function gap() external view returns (uint256);
    function off() external view returns (bool);
    function fix() external view returns (uint256);
    function joy() external view returns (uint256);
    function woe() external view returns (uint256);
    function fog() external view returns (uint256);
    function mold(bytes32, uint256) external;
    function heal() external;
    function s2s() external returns (uint256);
    function bid(uint256) external returns (uint256);
    function ask(uint256) external returns (uint256);
    function bust(uint256) external;
    function boom(uint256) external;
    function cage(uint256) external;
    function cash(uint256) external;
    function mock(uint256) external;
    function vent() external;
    function authority() external view returns (address);
    function owner() external view returns (address);
    function setOwner(address) external;
    function setAuthority(address) external;
}

////// lib/dss-interfaces/src/sai/SaiTopAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/sai/blob/master/src/top.sol
interface SaiTopAbstract {
    function vox() external view returns (address);
    function tub() external view returns (address);
    function tap() external view returns (address);
    function sai() external view returns (address);
    function sin() external view returns (address);
    function skr() external view returns (address);
    function gem() external view returns (address);
    function fix() external view returns (uint256);
    function fit() external view returns (uint256);
    function caged() external view returns (uint256);
    function cooldown() external view returns (uint256);
    function era() external view returns (uint256);
    function cage() external;
    function flow() external;
    function setCooldown(uint256) external;
    function authority() external view returns (address);
    function owner() external view returns (address);
    function setOwner(address) external;
    function setAuthority(address) external;
}

////// lib/dss-interfaces/src/sai/SaiTubAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/sai/blob/master/src/tub.sol
interface SaiTubAbstract {
    function sai() external view returns (address);
    function sin() external view returns (address);
    function skr() external view returns (address);
    function gem() external view returns (address);
    function gov() external view returns (address);
    function vox() external view returns (address);
    function pip() external view returns (address);
    function pep() external view returns (address);
    function tap() external view returns (address);
    function pit() external view returns (address);
    function axe() external view returns (uint256);
    function cap() external view returns (uint256);
    function mat() external view returns (uint256);
    function tax() external view returns (uint256);
    function fee() external view returns (uint256);
    function gap() external view returns (uint256);
    function off() external view returns (bool);
    function out() external view returns (bool);
    function fit() external view returns (uint256);
    function rho() external view returns (uint256);
    function rum() external view returns (uint256);
    function cupi() external view returns (uint256);
    function cups(bytes32) external view returns (address, uint256, uint256, uint256);
    function lad(bytes32) external view returns (address);
    function ink(bytes32) external view returns (address);
    function tab(bytes32) external view returns (uint256);
    function rap(bytes32) external returns (uint256);
    function din() external returns (uint256);
    function air() external view returns (uint256);
    function pie() external view returns (uint256);
    function era() external view returns (uint256);
    function mold(bytes32, uint256) external;
    function setPip(address) external;
    function setPep(address) external;
    function setVox(address) external;
    function turn(address) external;
    function per() external view returns (uint256);
    function ask(uint256) external view returns (uint256);
    function bid(uint256) external view returns (uint256);
    function join(uint256) external;
    function exit(uint256) external;
    function chi() external returns (uint256);
    function rhi() external returns (uint256);
    function drip() external;
    function tag() external view returns (uint256);
    function safe(bytes32) external returns (bool);
    function open() external returns (bytes32);
    function give(bytes32, address) external;
    function lock(bytes32, uint256) external;
    function free(bytes32, uint256) external;
    function draw(bytes32, uint256) external;
    function wipe(bytes32, uint256) external;
    function shut(bytes32) external;
    function bite(bytes32) external;
    function cage(uint256, uint256) external;
    function flow() external;
    function authority() external view returns (address);
    function owner() external view returns (address);
    function setOwner(address) external;
    function setAuthority(address) external;
}

////// lib/dss-interfaces/src/sai/SaiVoxAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/sai/blob/master/src/vox.sol
interface SaiVoxAbstract {
    function fix() external view returns (uint256);
    function how() external view returns (uint256);
    function tau() external view returns (uint256);
    function era() external view returns (uint256);
    function mold(bytes32, uint256) external;
    function par() external returns (uint256);
    function way() external returns (uint256);
    function tell(uint256) external;
    function tune(uint256) external;
    function prod() external;
    function authority() external view returns (address);
    function owner() external view returns (address);
    function setOwner(address) external;
    function setAuthority(address) external;
}

////// lib/dss-interfaces/src/Interfaces.sol
/* pragma solidity >=0.5.12; */

/* import { GemAbstract } from "./ERC/GemAbstract.sol"; */

/* import { DSAuthorityAbstract, DSAuthAbstract } from "./dapp/DSAuthorityAbstract.sol"; */
/* import { DSChiefAbstract } from "./dapp/DSChiefAbstract.sol"; */
/* import { DSPauseAbstract } from "./dapp/DSPauseAbstract.sol"; */
/* import { DSPauseProxyAbstract } from "./dapp/DSPauseProxyAbstract.sol"; */
/* import { DSRolesAbstract } from "./dapp/DSRolesAbstract.sol"; */
/* import { DSSpellAbstract } from "./dapp/DSSpellAbstract.sol"; */
/* import { DSRuneAbstract } from "./dapp/DSRuneAbstract.sol"; */
/* import { DSThingAbstract } from "./dapp/DSThingAbstract.sol"; */
/* import { DSTokenAbstract } from "./dapp/DSTokenAbstract.sol"; */
/* import { DSValueAbstract } from "./dapp/DSValueAbstract.sol"; */

/* import { AuthGemJoinAbstract } from "./dss/AuthGemJoinAbstract.sol"; */
/* import { CatAbstract } from "./dss/CatAbstract.sol"; */
/* import { ChainlogAbstract } from "./dss/ChainlogAbstract.sol"; */
/* import { ChainlogHelper } from "./dss/ChainlogAbstract.sol"; */
/* import { ClipAbstract } from "./dss/ClipAbstract.sol"; */
/* import { ClipperMomAbstract } from "./dss/ClipperMomAbstract.sol"; */
/* import { DaiAbstract } from "./dss/DaiAbstract.sol"; */
/* import { DaiJoinAbstract } from "./dss/DaiJoinAbstract.sol"; */
/* import { DogAbstract } from "./dss/DogAbstract.sol"; */
/* import { DssAutoLineAbstract } from "./dss/DssAutoLineAbstract.sol"; */
/* import { DssCdpManagerAbstract } from "./dss/DssCdpManager.sol"; */
/* import { EndAbstract } from "./dss/EndAbstract.sol"; */
/* import { ESMAbstract } from "./dss/ESMAbstract.sol"; */
/* import { ETHJoinAbstract } from "./dss/ETHJoinAbstract.sol"; */
/* import { ExponentialDecreaseAbstract } from "./dss/ExponentialDecreaseAbstract.sol"; */
/* import { FaucetAbstract } from "./dss/FaucetAbstract.sol"; */
/* import { FlapAbstract } from "./dss/FlapAbstract.sol"; */
/* import { FlashAbstract } from "./dss/FlashAbstract.sol"; */
/* import { FlipAbstract } from "./dss/FlipAbstract.sol"; */
/* import { FlipperMomAbstract } from "./dss/FlipperMomAbstract.sol"; */
/* import { FlopAbstract } from "./dss/FlopAbstract.sol"; */
/* import { GemJoinAbstract } from "./dss/GemJoinAbstract.sol"; */
/* import { GemJoinImplementationAbstract } from "./dss/GemJoinImplementationAbstract.sol"; */
/* import { GemJoinManagedAbstract } from "./dss/GemJoinManagedAbstract.sol"; */
/* import { GetCdpsAbstract } from "./dss/GetCdpsAbstract.sol"; */
/* import { IlkRegistryAbstract } from "./dss/IlkRegistryAbstract.sol"; */
/* import { JugAbstract } from "./dss/JugAbstract.sol"; */
/* import { LerpAbstract } from "./dss/LerpAbstract.sol"; */
/* import { LerpFactoryAbstract } from "./dss/LerpFactoryAbstract.sol"; */
/* import { LinearDecreaseAbstract } from "./dss/LinearDecreaseAbstract.sol"; */
/* import { LPOsmAbstract } from "./dss/LPOsmAbstract.sol"; */
/* import { MkrAuthorityAbstract } from "./dss/MkrAuthorityAbstract.sol"; */
/* import { MedianAbstract } from "./dss/MedianAbstract.sol"; */
/* import { OsmAbstract } from "./dss/OsmAbstract.sol"; */
/* import { OsmMomAbstract } from "./dss/OsmMomAbstract.sol"; */
/* import { PotAbstract } from "./dss/PotAbstract.sol"; */
/* import { PotHelper } from "./dss/PotHelper.sol"; */
/* import { SpotAbstract } from "./dss/SpotAbstract.sol"; */
/* import { StairstepExponentialDecreaseAbstract } from "./dss/StairstepExponentialDecreaseAbstract.sol"; */
/* import { VatAbstract } from "./dss/VatAbstract.sol"; */
/* import { VestAbstract } from "./dss/VestAbstract.sol"; */
/* import { VowAbstract } from "./dss/VowAbstract.sol"; */

/* import { GemPitAbstract } from "./sai/GemPitAbstract.sol"; */
/* import { SaiMomAbstract } from "./sai/SaiMomAbstract.sol"; */
/* import { SaiTapAbstract } from "./sai/SaiTapAbstract.sol"; */
/* import { SaiTopAbstract } from "./sai/SaiTopAbstract.sol"; */
/* import { SaiTubAbstract } from "./sai/SaiTubAbstract.sol"; */
/* import { SaiVoxAbstract } from "./sai/SaiVoxAbstract.sol"; */

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
/* import { VatAbstract, LerpFactoryAbstract, SpotAbstract} from "dss-interfaces/Interfaces.sol"; */

interface LerpAbstract_2 {
    function tick() external returns (uint256);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/287beee2bb76636b8b9e02c7e698fa639cb6b859/governance/votes/Executive%20vote%20-%20October%2022%2C%202021.md -q -O - 2>/dev/null)"
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

    // --- Rates (Housekeeeping) ---
    uint256 constant ONE_PCT_RATE            = 1000000000315522921573372069;
    uint256 constant ONE_FIVE_PCT_RATE       = 1000000000472114805215157978;
    uint256 constant TWO_FIVE_PCT_RATE       = 1000000000782997609082909351;
    uint256 constant SIX_PCT_RATE            = 1000000001847694957439350562;

    // --- Rates ---
    uint256 constant FOUR_PCT_RATE           = 1000000001243680656318820312;
    uint256 constant SEVEN_PCT_RATE          = 1000000002145441671308778766;

    // --- Math ---
    uint256 constant MILLION                 = 10 ** 6;
    uint256 constant RAY                     = 10 ** 27;

    // --- WBTC-B ---
    address constant MCD_JOIN_WBTC_B         = 0x13B8EB3d2d40A00d65fD30abF247eb470dDF6C25;
    address constant MCD_CLIP_WBTC_B         = 0x4F51B15f8B86822d2Eca8a74BB4bA1e3c64F733F;
    address constant MCD_CLIP_CALC_WBTC_B    = 0x1b5a9aDaf15CAE0e3d0349be18b77180C1a0deCc;

    // --- Offboarding: Current Liquidation Ratio ---
    uint256 constant CURRENT_AAVE_MAT        =  165 * RAY / 100;
    uint256 constant CURRENT_BAL_MAT         =  165 * RAY / 100;
    uint256 constant CURRENT_COMP_MAT        =  165 * RAY / 100;

    // --- Offboarding: Target Liquidation Ratio ---
    uint256 constant TARGET_AAVE_MAT         = 2100 * RAY / 100;
    uint256 constant TARGET_BAL_MAT          = 2300 * RAY / 100;
    uint256 constant TARGET_COMP_MAT         = 2000 * RAY / 100;

    // --- OLD LERP FAB ---
    address constant OLD_LERP_FAB            = 0xbBD821c291c492c40Db2577D9b6E5B1bdAEBD207;

    // --- Offboarding: Increased Target Liquidation Ratios ---
    uint256 constant TARGET_LRC_MAT          = 24300 * RAY / 100;
    uint256 constant TARGET_BAT_MAT          = 11200 * RAY / 100;
    uint256 constant TARGET_ZRX_MAT          =  5500 * RAY / 100;
    uint256 constant TARGET_UNIV2LINKETH_MAT =  1600 * RAY / 100;

    function _add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "DssSpellAction-add-overflow");
    }
    function _sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "DssSpellAction-sub-underflow");
    }

    function actions() public override {

        //
        // Housekeeping: Sync Goerli System Values with Mainnet
        //

        // --- 2021-10-22 Weekly Executive ---
        // https://github.com/makerdao/spells-mainnet/blob/master/archive/2021-10-22-DssSpell/DssSpell.sol

        // Parameter Changes Proposal - MakerDAO Open Market Committee - October 18, 2021
        // https://vote.makerdao.com/polling/QmP6GPeK?network=mainnet#poll-detail
        DssExecLib.setIlkAutoLineParameters("ETH-A", 15_000 * MILLION, 150 * MILLION, 6 hours);
        DssExecLib.setIlkAutoLineParameters("ETH-B", 500 * MILLION, 20 * MILLION, 6 hours);
        DssExecLib.setIlkAutoLineParameters("WBTC-A", 1_500 * MILLION, 60 * MILLION, 6 hours);

        // --- 2021-11-05 Weekly Executive ---
        // https://github.com/makerdao/spells-mainnet/blob/master/archive/2021-11-05-DssSpell/DssSpell.sol

        // ----------------------------- Stability Fee updates ----------------------------
        // https://vote.makerdao.com/polling/QmXDCCPH?network=mainnet#poll-detail
        DssExecLib.setIlkStabilityFee("ETH-A",          TWO_FIVE_PCT_RATE, true);
        DssExecLib.setIlkStabilityFee("ETH-B",          SIX_PCT_RATE,      true);
        DssExecLib.setIlkStabilityFee("WBTC-A",         TWO_FIVE_PCT_RATE, true);
        DssExecLib.setIlkStabilityFee("LINK-A",         ONE_FIVE_PCT_RATE, true);
        DssExecLib.setIlkStabilityFee("RENBTC-A",       TWO_FIVE_PCT_RATE, true);
        DssExecLib.setIlkStabilityFee("USDC-A",         ONE_PCT_RATE,      true);
        DssExecLib.setIlkStabilityFee("UNIV2WBTCETH-A", TWO_FIVE_PCT_RATE, true);

        // ------------------------------ Debt ceiling updates -----------------------------
        // https://vote.makerdao.com/polling/QmXDCCPH?network=mainnet#poll-detail
        DssExecLib.setIlkAutoLineDebtCeiling("MANA-A",        10 * MILLION);
        DssExecLib.setIlkAutoLineParameters("MATIC-A",        20 * MILLION, 20 * MILLION, 8 hours);
        DssExecLib.setIlkAutoLineParameters("UNIV2WBTCETH-A", 50 * MILLION,  5 * MILLION, 8 hours);

        // ------------------------------ PSM updates --------------------------------------
        // https://vote.makerdao.com/polling/QmSkYED5?network=mainnet#poll-detail
        address MCD_PSM_USDC_A = DssExecLib.getChangelogAddress("MCD_PSM_USDC_A");
        address MCD_PSM_PAX_A  = DssExecLib.getChangelogAddress("MCD_PSM_PAX_A");
        DssExecLib.setValue(MCD_PSM_USDC_A, "tin", 0);
        DssExecLib.setValue(MCD_PSM_PAX_A,  "tin", 0);

        //
        // END Housekeeping
        //

        // WBTC
        address WBTC     = DssExecLib.getChangelogAddress("WBTC");
        address PIP_WBTC = DssExecLib.getChangelogAddress("PIP_WBTC");

        //  Add WBTC-B as a new Vault Type
        //  https://vote.makerdao.com/polling/QmSL1kDq?network=mainnet#poll-detail (WBTC-B Onboarding)
        //  https://vote.makerdao.com/polling/QmRUgsvi?network=mainnet#poll-detail (Stability Fee)
        //  https://forum.makerdao.com/t/wbtc-b-collateral-onboarding-risk-assessment/11397
        //  https://forum.makerdao.com/t/signal-request-new-iam-vault-type-for-wbtc-with-lower-lr/5736
        DssExecLib.addNewCollateral(
            CollateralOpts({
                ilk:                   "WBTC-B",
                gem:                   WBTC,
                join:                  MCD_JOIN_WBTC_B,
                clip:                  MCD_CLIP_WBTC_B,
                calc:                  MCD_CLIP_CALC_WBTC_B,
                pip:                   PIP_WBTC,
                isLiquidatable:        true,
                isOSM:                 true,
                whitelistOSM:          true,
                ilkDebtCeiling:        30 * MILLION,
                minVaultAmount:        30000,
                maxLiquidationAmount:  25 * MILLION,
                liquidationPenalty:    1300,           // 13% penalty fee
                ilkStabilityFee:       SEVEN_PCT_RATE, // 7% stability fee
                startingPriceFactor:   12000,          // Auction price begins at 120% of oracle
                breakerTolerance:      5000,           // Allows for a 50% hourly price drop before disabling liquidations
                auctionDuration:       90 minutes,
                permittedDrop:         4000,           // 40% price drop before reset
                liquidationRatio:      13000,          // 130% collateralization
                kprFlatReward:         300,            // 300 Dai
                kprPctReward:          10              // 0.1%
            })
        );
        DssExecLib.setStairstepExponentialDecrease(MCD_CLIP_CALC_WBTC_B, 60 seconds, 9900);
        DssExecLib.setIlkAutoLineParameters("WBTC-B", 500 * MILLION, 30 * MILLION, 8 hours);

        // Changelog
        DssExecLib.setChangelogAddress("MCD_JOIN_WBTC_B", MCD_JOIN_WBTC_B);
        DssExecLib.setChangelogAddress("MCD_CLIP_WBTC_B", MCD_CLIP_WBTC_B);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_WBTC_B", MCD_CLIP_CALC_WBTC_B);

        DssExecLib.setChangelogVersion("1.9.10");

        //
        // Collateral Offboarding
        //

        uint256 totalLineReduction;
        uint256 line;
        VatAbstract vat = VatAbstract(DssExecLib.vat());

        // Offboard AAVE-A
        // https://vote.makerdao.com/polling/QmPdvqZg?network=mainnet#poll-detail
        // https://forum.makerdao.com/t/proposed-offboarding-collateral-parameters-2/11548
        // https://forum.makerdao.com/t/signal-request-offboarding-matic-comp-aave-and-bal/11184

        (,,,line,) = vat.ilks("AAVE-A");
        totalLineReduction = _add(totalLineReduction, line);
        DssExecLib.setIlkLiquidationPenalty("AAVE-A", 0);
        DssExecLib.removeIlkFromAutoLine("AAVE-A");
        DssExecLib.setIlkDebtCeiling("AAVE-A", 0);
        DssExecLib.linearInterpolation({
            _name:      "AAVE-A Offboarding",
            _target:    DssExecLib.spotter(),
            _ilk:       "AAVE-A",
            _what:      "mat",
            _startTime: block.timestamp,
            _start:     CURRENT_AAVE_MAT,
            _end:       TARGET_AAVE_MAT,
            _duration:  30 days
        });

        // Offboard BAL-A
        // https://vote.makerdao.com/polling/QmcwtUau?network=mainnet#poll-detail
        // https://forum.makerdao.com/t/proposed-offboarding-collateral-parameters-2/11548
        // https://forum.makerdao.com/t/signal-request-offboarding-matic-comp-aave-and-bal/11184

        (,,,line,) = vat.ilks("BAL-A");
        totalLineReduction = _add(totalLineReduction, line);
        DssExecLib.setIlkLiquidationPenalty("BAL-A", 0);
        DssExecLib.removeIlkFromAutoLine("BAL-A");
        DssExecLib.setIlkDebtCeiling("BAL-A", 0);
        DssExecLib.linearInterpolation({
            _name:      "BAL-A Offboarding",
            _target:    DssExecLib.spotter(),
            _ilk:       "BAL-A",
            _what:      "mat",
            _startTime: block.timestamp,
            _start:     CURRENT_BAL_MAT,
            _end:       TARGET_BAL_MAT,
            _duration:  30 days
        });

        // Offboard COMP-A
        // https://vote.makerdao.com/polling/QmRDeGCn?network=mainnet#poll-detail
        // https://forum.makerdao.com/t/proposed-offboarding-collateral-parameters-2/11548
        // https://forum.makerdao.com/t/signal-request-offboarding-matic-comp-aave-and-bal/11184

        (,,,line,) = vat.ilks("COMP-A");
        totalLineReduction = _add(totalLineReduction, line);
        DssExecLib.setIlkLiquidationPenalty("COMP-A", 0);
        DssExecLib.removeIlkFromAutoLine("COMP-A");
        DssExecLib.setIlkDebtCeiling("COMP-A", 0);
        DssExecLib.linearInterpolation({
            _name:      "COMP-A Offboarding",
            _target:    DssExecLib.spotter(),
            _ilk:       "COMP-A",
            _what:      "mat",
            _startTime: block.timestamp,
            _start:     CURRENT_COMP_MAT,
            _end:       TARGET_COMP_MAT,
            _duration:  30 days
        });

        // Decrease Global Debt Ceiling in accordance with Offboarded Ilks
        vat.file("Line", _sub(vat.Line(), totalLineReduction));

        // Increase Ilk Local Liquidation Limits (ilk.hole)
        // https://vote.makerdao.com/polling/QmQN6FX8?network=mainnet#poll-detail
        // https://forum.makerdao.com/t/auction-throughput-parameters-adjustments-nov-9-2021/11531
        DssExecLib.setIlkMaxLiquidationAmount("ETH-A",    65 * MILLION); // From 40M to 65M DAI
        DssExecLib.setIlkMaxLiquidationAmount("ETH-B",    30 * MILLION); // From 25M to 30M DAI
        DssExecLib.setIlkMaxLiquidationAmount("ETH-C",    35 * MILLION); // From 30M to 35M DAI
        DssExecLib.setIlkMaxLiquidationAmount("WBTC-A",   40 * MILLION); // From 25M to 40M DAI
        DssExecLib.setIlkMaxLiquidationAmount("WSTETH-A",  7 * MILLION); // From  3M to  7M DAI

        // Increase WBTC-A Stability Fee (duty)
        // https://vote.makerdao.com/polling/QmRUgsvi?network=mainnet#poll-detail
        // https://forum.makerdao.com/t/mid-month-parameter-changes-proposal-ppg-omc-001-2021-11-10/11562
        DssExecLib.setIlkStabilityFee("WBTC-A", FOUR_PCT_RATE, true); // From 2.5% to 4%

        // Increase LRC-A Target Liquidation Ratio (mat)
        address LRC_LERP = LerpFactoryAbstract(OLD_LERP_FAB).lerps("LRC Offboarding");
        uint256 CURRENT_LRC_MAT = LerpAbstract_2(LRC_LERP).tick();
        SpotAbstract(DssExecLib.spotter()).deny(LRC_LERP);
        DssExecLib.linearInterpolation({
            _name:      "LRC-A Offboarding",
            _target:    DssExecLib.spotter(),
            _ilk:       "LRC-A",
            _what:      "mat",
            _startTime: block.timestamp,
            _start:     CURRENT_LRC_MAT,
            _end:       TARGET_LRC_MAT,
            _duration:  30 days
        });

        // Increase BAT-A Target Liquidation Ratio (mat)
        address BAT_LERP = LerpFactoryAbstract(OLD_LERP_FAB).lerps("BAT Offboarding");
        uint256 CURRENT_BAT_MAT = LerpAbstract_2(BAT_LERP).tick();
        SpotAbstract(DssExecLib.spotter()).deny(BAT_LERP);
        DssExecLib.linearInterpolation({
            _name:      "BAT-A Offboarding",
            _target:    DssExecLib.spotter(),
            _ilk:       "BAT-A",
            _what:      "mat",
            _startTime: block.timestamp,
            _start:     CURRENT_BAT_MAT,
            _end:       TARGET_BAT_MAT,
            _duration:  30 days
        });

        // Increase ZRX-A Target Liquidation Ratio (mat)
        address ZRX_LERP = LerpFactoryAbstract(OLD_LERP_FAB).lerps("ZRX Offboarding");
        uint256 CURRENT_ZRX_MAT = LerpAbstract_2(ZRX_LERP).tick();
        SpotAbstract(DssExecLib.spotter()).deny(ZRX_LERP);
        DssExecLib.linearInterpolation({
            _name:      "ZRX-A Offboarding",
            _target:    DssExecLib.spotter(),
            _ilk:       "ZRX-A",
            _what:      "mat",
            _startTime: block.timestamp,
            _start:     CURRENT_ZRX_MAT,
            _end:       TARGET_ZRX_MAT,
            _duration:  30 days
        });

        // Increase UNIV2LINKETH-A Target Liquidation Ratio (mat)
        address UNIV2LINKETH_LERP = LerpFactoryAbstract(OLD_LERP_FAB).lerps("UNIV2LINKETH Offboarding");
        uint256 CURRENT_UNIV2LINKETH_MAT = LerpAbstract_2(UNIV2LINKETH_LERP).tick();
        SpotAbstract(DssExecLib.spotter()).deny(UNIV2LINKETH_LERP);
        DssExecLib.linearInterpolation({
            _name:      "UNIV2LINKETH-A Offboarding",
            _target:    DssExecLib.spotter(),
            _ilk:       "UNIV2LINKETH-A",
            _what:      "mat",
            _startTime: block.timestamp,
            _start:     CURRENT_UNIV2LINKETH_MAT,
            _end:       TARGET_UNIV2LINKETH_MAT,
            _duration:  30 days
        });
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}