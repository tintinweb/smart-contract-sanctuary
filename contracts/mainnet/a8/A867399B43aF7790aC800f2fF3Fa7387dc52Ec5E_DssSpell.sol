/**
 *Submitted for verification at Etherscan.io on 2021-12-10
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
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {}
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {}
    function cat()        public view returns (address) { return getChangelogAddress("MCD_CAT"); }
    function dog()        public view returns (address) { return getChangelogAddress("MCD_DOG"); }
    function end()        public view returns (address) { return getChangelogAddress("MCD_END"); }
    function reg()        public view returns (address) { return getChangelogAddress("ILK_REGISTRY"); }
    function autoLine()   public view returns (address) { return getChangelogAddress("MCD_IAM_AUTO_LINE"); }
    function lerpFab()    public view returns (address) { return getChangelogAddress("LERP_FAB"); }
    function clip(bytes32 _ilk) public view returns (address _clip) {}
    function flip(bytes32 _ilk) public view returns (address _flip) {}
    function calc(bytes32 _ilk) public view returns (address _calc) {}
    function getChangelogAddress(bytes32 _key) public view returns (address) {}
    function canCast(uint40 _ts, bool _officeHours) public pure returns (bool) {}
    function nextCastTime(uint40 _eta, uint40 _ts, bool _officeHours) public pure returns (uint256 castTime) {}
    function setValue(address _base, bytes32 _what, uint256 _amt) public {}
    function setValue(address _base, bytes32 _ilk, bytes32 _what, uint256 _amt) public {}
    function setIlkAutoLineParameters(bytes32 _ilk, uint256 _amount, uint256 _gap, uint256 _ttl) public {}
    function setIlkMaxLiquidationAmount(bytes32 _ilk, uint256 _amount) public {}
    function setStartingPriceMultiplicativeFactor(bytes32 _ilk, uint256 _pct_bps) public {}
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

interface TokenLike {
    function approve(address, uint256) external returns (bool);
}

interface DssVestLike {
    function yank(uint256) external;
    function restrict(uint256) external;
    function create(
        address _usr,
        uint256 _tot,
        uint256 _bgn,
        uint256 _tau,
        uint256 _eta,
        address _mgr
  ) external returns (uint256);
}

contract DssSpellAction is DssAction {
    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/3224f50b0b5a9301831213ed858bc1d206de8e40/governance/votes/Executive%20vote%20-%20December%2010%2C%202021.md -q -O - 2>/dev/null)"
    string public constant override description =
        "2021-12-10 MakerDAO Executive Spell | Hash: 0x9cc240b4c1027d3dc1abb24ecc598703352d8135c8a1670a6591e9a334836e5d";

    // --- Math ---
    uint256 constant MILLION = 10**6;

    // --- Ilks ---
    bytes32 constant WSTETH_A = "WSTETH-A";
    bytes32 constant MATIC_A  = "MATIC-A";

    // --- Wallet addresses ---
    address constant GRO_WALLET = 0x7800C137A645c07132886539217ce192b9F0528e;
    address constant ORA_WALLET = 0x2d09B7b95f3F312ba6dDfB77bA6971786c5b50Cf;
    address constant PE_WALLET  = 0xe2c16c308b843eD02B09156388Cb240cEd58C01c;

    // --- Dates ---
    uint256 constant MAY_01_2021 = 1619827200;
    uint256 constant JUN_21_2021 = 1624233600;
    uint256 constant JUL_01_2021 = 1625097600;
    uint256 constant SEP_13_2021 = 1631491200;
    uint256 constant SEP_20_2021 = 1632096000;

    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {

        // ------------- Transfer vesting streams from MCD_VEST_MKR to MCD_VEST_MKR_TREASURY -------------
        // https://vote.makerdao.com/polling/QmYdDTsn

        address MCD_VEST_MKR          = DssExecLib.getChangelogAddress("MCD_VEST_MKR");
        address MCD_VEST_MKR_TREASURY = DssExecLib.getChangelogAddress("MCD_VEST_MKR_TREASURY");

        TokenLike(DssExecLib.getChangelogAddress("MCD_GOV")).approve(MCD_VEST_MKR_TREASURY, 16_484.43 * 10**18);

        // Growth MKR whole team vesting
        DssVestLike(MCD_VEST_MKR).yank(1);
        DssVestLike(MCD_VEST_MKR_TREASURY).restrict(
            DssVestLike(MCD_VEST_MKR_TREASURY).create({
                _usr: GRO_WALLET,
                _tot: 803.18 * 10**18,
                _bgn: JUL_01_2021,
                _tau: 365 days,
                _eta: 365 days,
                _mgr: address(0)
            })
        );

        // Oracles MKR whole team vesting
        DssVestLike(MCD_VEST_MKR).yank(2);
        DssVestLike(MCD_VEST_MKR_TREASURY).restrict(
            DssVestLike(MCD_VEST_MKR_TREASURY).create({
                _usr: ORA_WALLET,
                _tot: 1_051.25 * 10**18,
                _bgn: JUL_01_2021,
                _tau: 365 days,
                _eta: 365 days,
                _mgr: address(0)
            })
        );

        // PE MKR vestings (per individual)
        DssVestLike(MCD_VEST_MKR).yank(3);
        (
            DssVestLike(MCD_VEST_MKR_TREASURY).create({
                _usr: 0xfDB9F5e045D7326C1da87d0e199a05CDE5378EdD,
                _tot: 995.00 * 10**18,
                _bgn: MAY_01_2021,
                _tau: 4 * 365 days,
                _eta: 365 days,
                _mgr: PE_WALLET
            })
        );

        DssVestLike(MCD_VEST_MKR).yank(4);
        DssVestLike(MCD_VEST_MKR_TREASURY).restrict(
            DssVestLike(MCD_VEST_MKR_TREASURY).create({
                _usr: 0xBe4De3E151D52668c2C0610C985b4297833239C8,
                _tot: 995.00 * 10**18,
                _bgn: MAY_01_2021,
                _tau: 4 * 365 days,
                _eta: 365 days,
                _mgr: PE_WALLET
            })
        );

        DssVestLike(MCD_VEST_MKR).yank(5);
        DssVestLike(MCD_VEST_MKR_TREASURY).restrict(
            DssVestLike(MCD_VEST_MKR_TREASURY).create({
                _usr: 0x58EA3C96a8b81abC01EB78B98deCe2AD1e5fd7fc,
                _tot: 995.00 * 10**18,
                _bgn: MAY_01_2021,
                _tau: 4 * 365 days,
                _eta: 365 days,
                _mgr: PE_WALLET
            })
        );

        DssVestLike(MCD_VEST_MKR).yank(6);
        DssVestLike(MCD_VEST_MKR_TREASURY).restrict(
            DssVestLike(MCD_VEST_MKR_TREASURY).create({
                _usr: 0xBAB4Cd1cB31Cd28f842335973712a6015eB0EcD5,
                _tot: 995.00 * 10**18,
                _bgn: MAY_01_2021,
                _tau: 4 * 365 days,
                _eta: 365 days,
                _mgr: PE_WALLET
            })
        );

        DssVestLike(MCD_VEST_MKR).yank(7);
        (
            DssVestLike(MCD_VEST_MKR_TREASURY).create({
                _usr: 0xB5c86aff90944CFB3184902482799bD5fA3B18dD,
                _tot: 995.00 * 10**18,
                _bgn: MAY_01_2021,
                _tau: 4 * 365 days,
                _eta: 365 days,
                _mgr: PE_WALLET
            })
        );

        DssVestLike(MCD_VEST_MKR).yank(8);
        DssVestLike(MCD_VEST_MKR_TREASURY).restrict(
            DssVestLike(MCD_VEST_MKR_TREASURY).create({
                _usr: 0x780f478856ebE01e46d9A432e8776bAAB5A81b5b,
                _tot: 995.00 * 10**18,
                _bgn: MAY_01_2021,
                _tau: 4 * 365 days,
                _eta: 365 days,
                _mgr: PE_WALLET
            })
        );

        DssVestLike(MCD_VEST_MKR).yank(9);
        DssVestLike(MCD_VEST_MKR_TREASURY).restrict(
            DssVestLike(MCD_VEST_MKR_TREASURY).create({
                _usr: 0x34364E234b3DD02FF5c8A2ad9ba86bbD3D3D3284,
                _tot: 995.00 * 10**18,
                _bgn: MAY_01_2021,
                _tau: 4 * 365 days,
                _eta: 365 days,
                _mgr: PE_WALLET
            })
        );

        DssVestLike(MCD_VEST_MKR).yank(10);
        DssVestLike(MCD_VEST_MKR_TREASURY).restrict(
            DssVestLike(MCD_VEST_MKR_TREASURY).create({
                _usr: 0x46E5DBad3966453Af57e90Ec2f3548a0e98ec979,
                _tot: 995.00 * 10**18,
                _bgn: MAY_01_2021,
                _tau: 4 * 365 days,
                _eta: 365 days,
                _mgr: PE_WALLET
            })
        );

        DssVestLike(MCD_VEST_MKR).yank(11);
        DssVestLike(MCD_VEST_MKR_TREASURY).restrict(
            DssVestLike(MCD_VEST_MKR_TREASURY).create({
                _usr: 0x18CaE82909C31b60Fe0A9656D76406345C9cb9FB,
                _tot: 995.00 * 10**18,
                _bgn: MAY_01_2021,
                _tau: 4 * 365 days,
                _eta: 365 days,
                _mgr: PE_WALLET
            })
        );

        DssVestLike(MCD_VEST_MKR).yank(12);
        (
            DssVestLike(MCD_VEST_MKR_TREASURY).create({
                _usr: 0x301dD8eB831ddb93F128C33b9d9DC333210d9B25,
                _tot: 995.00 * 10**18,
                _bgn: MAY_01_2021,
                _tau: 4 * 365 days,
                _eta: 365 days,
                _mgr: PE_WALLET
            })
        );

        DssVestLike(MCD_VEST_MKR).yank(13);
        (
            DssVestLike(MCD_VEST_MKR_TREASURY).create({
                _usr: 0xBFC47D0D7452a25b7d3AA4d7379c69A891bD5d43,
                _tot: 995.00 * 10**18,
                _bgn: MAY_01_2021,
                _tau: 4 * 365 days,
                _eta: 365 days,
                _mgr: PE_WALLET
            })
        );

        DssVestLike(MCD_VEST_MKR).yank(14);
        (
            DssVestLike(MCD_VEST_MKR_TREASURY).create({
                _usr: 0xcD16aa978A89Aa26b3121Fc8dd32228d7D0fcF4a,
                _tot: 995.00 * 10**18,
                _bgn: SEP_13_2021,
                _tau: 4 * 365 days,
                _eta: 365 days,
                _mgr: PE_WALLET
            })
        );

        DssVestLike(MCD_VEST_MKR).yank(15);
        DssVestLike(MCD_VEST_MKR_TREASURY).restrict(
            DssVestLike(MCD_VEST_MKR_TREASURY).create({
                _usr: 0x3189cfe40CF011AAb13aDD8aE7284deD4CD30602,
                _tot: 995.00 * 10**18,
                _bgn: JUN_21_2021,
                _tau: 4 * 365 days,
                _eta: 365 days,
                _mgr: PE_WALLET
            })
        );

        DssVestLike(MCD_VEST_MKR).yank(16);
        DssVestLike(MCD_VEST_MKR_TREASURY).restrict(
            DssVestLike(MCD_VEST_MKR_TREASURY).create({
                _usr: 0x29b37159C09a65af6a7CFb062998B169879442B6,
                _tot: 995.00 * 10**18,
                _bgn: SEP_20_2021,
                _tau: 4 * 365 days,
                _eta: 365 days,
                _mgr: PE_WALLET
            })
        );


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
    }
}

contract DssSpell is DssExec {
    constructor() DssExec(block.timestamp + 30 days, address(new DssSpellAction())) public {}
}