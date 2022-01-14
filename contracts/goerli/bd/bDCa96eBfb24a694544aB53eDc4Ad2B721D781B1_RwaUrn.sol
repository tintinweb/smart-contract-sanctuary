/**
 *Submitted for verification at Etherscan.io on 2022-01-14
*/

// hevm: flattened sources of src/RwaUrn.sol
// SPDX-License-Identifier: AGPL-3.0-or-later AND GPL-3.0-or-later
pragma solidity >=0.5.12 >=0.6.8 <0.7.0;

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
interface LerpAbstract {
    function target() external view returns (address);
    function what() external view returns (bytes32);
    function start() external view returns (uint256);
    function end() external view returns (uint256);
    function duration() external view returns (uint256);
    function done() external view returns (bool);
    function startTime() external view returns (uint256);
    function tick() external returns (uint256);
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

////// lib/dss-interfaces/src/dss/PsmAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/dss-psm/blob/master/src/psm.sol
interface PsmAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function vat() external view returns (address);
    function gemJoin() external view returns (address);
    function dai() external view returns (address);
    function daiJoin() external view returns (address);
    function ilk() external view returns (bytes32);
    function vow() external view returns (address);
    function tin() external view returns (uint256);
    function tout() external view returns (uint256);
    function file(bytes32 what, uint256 data) external;
    function hope(address) external;
    function nope(address) external;
    function sellGem(address usr, uint256 gemAmt) external;
    function buyGem(address usr, uint256 gemAmt) external;
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

////// lib/dss-interfaces/src/utils/WardsAbstract.sol
/* pragma solidity >=0.5.12; */

interface WardsAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
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
/* import { PsmAbstract } from "./dss/PsmAbstract.sol"; */
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

// Partial DSS Abstracts
/* import { WardsAbstract } from "./utils/WardsAbstract.sol"; */

////// src/RwaUrn.sol
/* pragma solidity >=0.6.8 <0.7.0; */

// import {VatAbstract, JugAbstract, DSTokenAbstract, GemJoinAbstract, DaiJoinAbstract, DaiAbstract} from "dss-interfaces/Interfaces.sol";

/**
 * @title An extension/subset of `DSMath` containing only the methods required in this file.
 */
library DSMathCustom_2 {
    uint256 internal constant RAY = 10**27;

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "DSMath/add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "DSMath/sub-overflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "DSMath/mul-overflow");
    }

    /**
     * @dev Divides x/y, but rounds it up.
     */
    function divup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(x, sub(y, 1)) / y;
    }

    /**
     * @dev Converts `wad` (10^18) into a `rad` (10^45) by multiplying it by RAY (10^27).
     *  - wad: used for token balances
     *  - ray: used for interest rates
     *  - rad: used for Dai balances inside the Vat
     */
    function rad(uint256 wad) internal pure returns (uint256 z) {
        return mul(wad, RAY);
    }
}

/**
 * @title A vault for Real-World Assets (RWA).
 */
contract RwaUrn {
    /// @notice Core module address.
    VatAbstract public immutable vat;
    /// @notice The GemJoin adapter for the gem in this urn.
    GemJoinAbstract public immutable gemJoin;
    /// @notice The adapter to mint/burn Dai tokens.
    DaiJoinAbstract public immutable daiJoin;
    /// @notice The stability fee management module.
    JugAbstract public jug;
    /// @notice The destination of Dai drawn from this urn.
    address public outputConduit;

    /// @notice Addresses with admin access on this contract. `wards[usr]`
    mapping(address => uint256) public wards;
    /// @notice Addresses with operator access on this contract. `can[usr]`
    mapping(address => uint256) public can;

    /**
     * @notice `usr` was granted admin access.
     * @param usr The user address.
     */
    event Rely(address indexed usr);
    /**
     * @notice `usr` admin access was revoked.
     * @param usr The user address.
     */
    event Deny(address indexed usr);
    /**
     * @notice `usr` was granted operator access.
     * @param usr The user address.
     */
    event Hope(address indexed usr);
    /**
     * @notice `usr` operator address was revoked.
     * @param usr The user address.
     */
    event Nope(address indexed usr);
    /**
     * @notice A contract parameter was updated.
     * @param what The changed parameter name. Currently the supported values are: "outputConduit" and "jug".
     * @param data The new value of the parameter.
     */
    event File(bytes32 indexed what, address data);
    /**
     * @notice `wad` amount of the gem was locked in the contract by `usr`.
     * @param usr The operator address.
     * @param wad The amount locked.
     */
    event Lock(address indexed usr, uint256 wad);
    /**
     * @notice `wad` amount of the gem was freed the contract by `usr`.
     * @param usr The operator address.
     * @param wad The amount freed.
     */
    event Free(address indexed usr, uint256 wad);
    /**
     * @notice `wad` amount of Dai was drawn by `usr` into `outputConduit`.
     * @param usr The operator address.
     * @param wad The amount drawn.
     */
    event Draw(address indexed usr, uint256 wad);
    /**
     * @notice `wad` amount of Dai was repaid by `usr`.
     * @param usr The operator address.
     * @param wad The amount repaid.
     */
    event Wipe(address indexed usr, uint256 wad);

    /**
     * @notice The urn outstanding balance was flushed out to `outputConduit`.
     * @dev This can happen only after `cage()` has been called on the `Vat`.
     * @param usr The operator address.
     * @param wad The amount flushed out.
     */
    event Quit(address indexed usr, uint256 wad);

    modifier auth() {
        require(wards[msg.sender] == 1, "RwaUrn/not-authorized");
        _;
    }

    modifier operator() {
        require(can[msg.sender] == 1, "RwaUrn/not-operator");
        _;
    }

    /**
     * @param vat_ Core module address.
     * @param jug_ GemJoin adapter for the gem in this urn.
     * @param gemJoin_ Adapter to mint/burn Dai tokens.
     * @param daiJoin_ Stability fee management module.
     * @param outputConduit_ Destination of Dai drawn from this urn.
     */
    constructor(
        address vat_,
        address jug_,
        address gemJoin_,
        address daiJoin_,
        address outputConduit_
    ) public {
        require(outputConduit_ != address(0), "RwaUrn/invalid-conduit");

        vat = VatAbstract(vat_);
        jug = JugAbstract(jug_);
        gemJoin = GemJoinAbstract(gemJoin_);
        daiJoin = DaiJoinAbstract(daiJoin_);
        outputConduit = outputConduit_;

        wards[msg.sender] = 1;

        DSTokenAbstract(GemJoinAbstract(gemJoin_).gem()).approve(gemJoin_, type(uint256).max);
        DaiAbstract(DaiJoinAbstract(daiJoin_).dai()).approve(daiJoin_, type(uint256).max);
        VatAbstract(vat_).hope(daiJoin_);

        emit Rely(msg.sender);
        emit File("outputConduit", outputConduit_);
        emit File("jug", jug_);
    }

    /*//////////////////////////////////
               Authorization
    //////////////////////////////////*/

    /**
     * @notice Grants `usr` admin access to this contract.
     * @param usr The user address.
     */
    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }

    /**
     * @notice Revokes `usr` admin access from this contract.
     * @param usr The user address.
     */
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    /**
     * @notice Grants `usr` operator access to this contract.
     * @param usr The user address.
     */
    function hope(address usr) external auth {
        can[usr] = 1;
        emit Hope(usr);
    }

    /**
     * @notice Revokes `usr` admin access from this contract.
     * @param usr The user address.
     */
    function nope(address usr) external auth {
        can[usr] = 0;
        emit Nope(usr);
    }

    /*//////////////////////////////////
               Administration
    //////////////////////////////////*/

    /**
     * @notice Updates a contract parameter.
     * @param what The changed parameter name. `"outputConduit" | "jug"`
     * @param data The new value of the parameter.
     */
    function file(bytes32 what, address data) external auth {
        if (what == "outputConduit") {
            require(data != address(0), "RwaUrn/invalid-conduit");
            outputConduit = data;
        } else if (what == "jug") {
            jug = JugAbstract(data);
        } else {
            revert("RwaUrn/unrecognised-param");
        }

        emit File(what, data);
    }

    /*//////////////////////////////////
              Vault Operation
    //////////////////////////////////*/

    /**
     * @notice Locks `wad` amount of the gem in the contract.
     * @param wad The amount to lock.
     */
    function lock(uint256 wad) external operator {
        require(wad <= 2**255 - 1, "RwaUrn/overflow");

        DSTokenAbstract(gemJoin.gem()).transferFrom(msg.sender, address(this), wad);
        // join with address this
        gemJoin.join(address(this), wad);
        vat.frob(gemJoin.ilk(), address(this), address(this), address(this), int256(wad), 0);

        emit Lock(msg.sender, wad);
    }

    /**
     * @notice Frees `wad` amount of the gem from the contract.
     * @param wad The amount to free.
     */
    function free(uint256 wad) external operator {
        require(wad <= 2**255, "RwaUrn/overflow");

        vat.frob(gemJoin.ilk(), address(this), address(this), address(this), -int256(wad), 0);
        gemJoin.exit(msg.sender, wad);
        emit Free(msg.sender, wad);
    }

    /**
     * @notice Draws `wad` amount of Dai from the contract.
     * @param wad The amount to draw.
     */
    function draw(uint256 wad) external operator {
        bytes32 ilk = gemJoin.ilk();
        jug.drip(ilk);
        (, uint256 rate, , , ) = vat.ilks(ilk);

        uint256 dart = DSMathCustom_2.divup(DSMathCustom_2.rad(wad), rate);
        require(dart <= 2**255 - 1, "RwaUrn/overflow");

        vat.frob(ilk, address(this), address(this), address(this), 0, int256(dart));
        daiJoin.exit(outputConduit, wad);
        emit Draw(msg.sender, wad);
    }

    /**
     * @notice Repays `wad` amount of Dai to the contract.
     * @param wad The amount to wipe.
     */
    function wipe(uint256 wad) external {
        daiJoin.join(address(this), wad);

        bytes32 ilk = gemJoin.ilk();
        jug.drip(ilk);
        (, uint256 rate, , , ) = vat.ilks(ilk);

        uint256 dart = DSMathCustom_2.rad(wad) / rate;
        require(dart <= 2**255, "RwaUrn/overflow");

        vat.frob(ilk, address(this), address(this), address(this), 0, -int256(dart));
        emit Wipe(msg.sender, wad);
    }

    /**
     * @notice Flushes out any outstanding Dai balance to `outputConduit`.
     * @dev Can only be called after `cage()` has been called on the Vat.
     */
    function quit() external {
        require(vat.live() == 0, "RwaUrn/vat-still-live");

        DSTokenAbstract dai = DSTokenAbstract(daiJoin.dai());
        uint256 wad = dai.balanceOf(address(this));

        dai.transfer(outputConduit, wad);
        emit Quit(msg.sender, wad);
    }
}