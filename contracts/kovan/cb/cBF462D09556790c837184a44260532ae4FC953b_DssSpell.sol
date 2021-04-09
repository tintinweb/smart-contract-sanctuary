/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
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

pragma solidity 0.6.12;

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
interface OracleLike {
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
    function dai()        public view returns (address) {}
    function mkr()        public view returns (address) {}
    function vat()        public view returns (address) {}
    function cat()        public view returns (address) {}
    function jug()        public view returns (address) {}
    function pot()        public view returns (address) {}
    function vow()        public view returns (address) {}
    function end()        public view returns (address) {}
    function reg()        public view returns (address) {}
    function spotter()    public view returns (address) {}
    function flap()       public view returns (address) {}
    function flop()       public view returns (address) {}
    function osmMom()     public view returns (address) {}
    function govGuard()   public view returns (address) {}
    function flipperMom() public view returns (address) {}
    function pauseProxy() public view returns (address) {}
    function autoLine()   public view returns (address) {}
    function daiJoin()    public view returns (address) {}

    function authorize(address, address) public {}

    function deauthorize(address, address) public {}

    function flip(bytes32) public view returns (address) {}

    function getChangelogAddress(bytes32) public view returns (address) {}

    function setChangelogAddress(bytes32, address) public {}

    function setChangelogVersion(string memory) public {}

    function setContract(address, bytes32, address) public {}

    function setContract(address, bytes32, bytes32, address) public {}

    function setIlkStabilityFee(bytes32, uint256, bool) public {}


    function addReaderToOSMWhitelist(address, address) public {}

    function removeReaderFromOSMWhitelist(address, address) public {}
}

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
        require(eta != 0, "DssExec/spell-not-scheduled");
        castTime = block.timestamp > eta ? block.timestamp : eta; // Any day at XX:YY

        if (SpellAction(action).officeHours()) {
            uint256 day    = (castTime / 1 days + 3) % 7;
            uint256 hour   = castTime / 1 hours % 24;
            uint256 minute = castTime / 1 minutes % 60;
            uint256 second = castTime % 60;

            if (day >= 5) {
                castTime += (6 - day) * 1 days;                 // Go to Sunday XX:YY
                castTime += (24 - hour + 14) * 1 hours;         // Go to 14:YY UTC Monday
                castTime -= minute * 1 minutes + second;        // Go to 14:00 UTC
            } else {
                if (hour >= 21) {
                    if (day == 4) castTime += 2 days;           // If Friday, fast forward to Sunday XX:YY
                    castTime += (24 - hour + 14) * 1 hours;     // Go to 14:YY UTC next day
                    castTime -= minute * 1 minutes + second;    // Go to 14:00 UTC
                } else if (hour < 14) {
                    castTime += (14 - hour) * 1 hours;          // Go to 14:YY UTC same day
                    castTime -= minute * 1 minutes + second;    // Go to 14:00 UTC
                }
            }
        }
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

abstract contract DssAction {

    using DssExecLib for *;

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

    // Modifier required to
    modifier limited {
        if (officeHours()) {
            uint day = (block.timestamp / 1 days + 3) % 7;
            require(day < 5, "Can only be cast on a weekday");
            uint hour = block.timestamp / 1 hours % 24;
            require(hour >= 14 && hour < 21, "Outside office hours");
        }
        _;
    }
}

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

contract DssSpellAction is DssAction {

    string public constant description = "Kovan Spell";

    address constant MCD_DOG              = 0x121D0953683F74e9a338D40d9b4659C0EBb539a0;
    address constant MCD_END              = 0x0D1a98E93d9cE32E44bC035e8C6E4209fdB70C27;
    address constant MCD_ESM_BUG          = 0x0798603b8AE1f76D2823aDbc2E15d047Eac1Efd7;
    address constant MCD_ESM_ATTACK       = 0x23Aa7cbeb266413f968D284acce3a3f9EEFFC2Ec;
    address constant ILK_REGISTRY         = 0xB3fBb13b831F254DbBB9a1abdb81d8D91589B3B4;
    address constant CLIPPER_MOM          = 0x96E9a19Be6EA91d1C0908e5E207f944dc2E7B878;
    address constant MCD_CLIP_LINK_A      = 0x1eB71cC879960606F8ab0E02b3668EEf92CE6D98;
    address constant MCD_CLIP_CALC_LINK_A = 0xbd586d6352Fcf0C45f77FC9348F4Ee7539F6e2bD;

    uint256 constant THOUSAND   = 10**3;
    uint256 constant MILLION    = 10**6;
    uint256 constant WAD        = 10**18;
    uint256 constant RAY        = 10**27;
    uint256 constant RAD        = 10**45;

    // Turn off office hours
    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {
        // Set stability for ETH-A to 4% (whatever higher than 0)
        DssExecLib.setIlkStabilityFee("ETH-A", 1000000001243680656318820312, true);


        address MCD_VAT          = DssExecLib.vat();
        address MCD_CAT          = DssExecLib.cat();
        address MCD_VOW          = DssExecLib.vow();
        address MCD_POT          = DssExecLib.pot();
        address MCD_SPOT         = DssExecLib.spotter();
        address MCD_END_OLD      = DssExecLib.end();
        address MCD_FLIP_LINK_A  = DssExecLib.flip("LINK-A");
        address ILK_REGISTRY_OLD = DssExecLib.reg();
        address PIP_LINK         = DssExecLib.getChangelogAddress("PIP_LINK");

        // ------------------  END  ------------------

        // Set contracts in END
        DssExecLib.setContract(MCD_END,  "vat", MCD_VAT);
        DssExecLib.setContract(MCD_END,  "cat", MCD_CAT);
        DssExecLib.setContract(MCD_END,  "dog", MCD_DOG);
        DssExecLib.setContract(MCD_END,  "vow", MCD_VOW);
        DssExecLib.setContract(MCD_END,  "pot", MCD_POT);
        DssExecLib.setContract(MCD_END, "spot", MCD_SPOT);

        // Authorize the new END in contracts
        DssExecLib.authorize(MCD_VAT, MCD_END);
        DssExecLib.authorize(MCD_CAT, MCD_END);
        DssExecLib.authorize(MCD_DOG, MCD_END);
        DssExecLib.authorize(MCD_VOW, MCD_END);
        DssExecLib.authorize(MCD_POT, MCD_END);
        DssExecLib.authorize(MCD_SPOT, MCD_END);

        // Set wait time in END
        Fileable(MCD_END).file("wait", EndAbstract(MCD_END_OLD).wait());

        // Deauthorize the old END in contracts
        DssExecLib.deauthorize(MCD_VAT, MCD_END_OLD);
        DssExecLib.deauthorize(MCD_CAT, MCD_END_OLD);
        DssExecLib.deauthorize(MCD_VOW, MCD_END_OLD);
        DssExecLib.deauthorize(MCD_POT, MCD_END_OLD);
        DssExecLib.deauthorize(MCD_SPOT, MCD_END_OLD);

        // Deauthorize the old END from all the FLIPS
        // Authorize the new END in all the FLIPS
        bytes32[] memory ilks = IlkRegistryAbstract(ILK_REGISTRY_OLD).list();
        address[] memory flips = new address[](ilks.length);
        for (uint256 i = 0; i < ilks.length; i++) {
            bytes32 ilk = ilks[i];

            address flip = DssExecLib.flip(ilk);
            flips[i] = flip;
            DssExecLib.deauthorize(flip, MCD_END_OLD);
            DssExecLib.authorize(flip, MCD_END);

            try DssExecLib.removeReaderFromOSMWhitelist(IlkRegistryAbstract(ILK_REGISTRY_OLD).pip(ilk), MCD_END_OLD) {} catch {}
            try DssExecLib.addReaderToOSMWhitelist(IlkRegistryAbstract(ILK_REGISTRY_OLD).pip(ilk), MCD_END) {} catch {}
        }

        // ------------------  ESM  ------------------

        // Authorize new ESM to execute in new END
        DssExecLib.authorize(MCD_END, MCD_ESM_BUG);
        DssExecLib.authorize(MCD_END, MCD_ESM_ATTACK);

        // Authorize new ESM to execute in VAT
        DssExecLib.authorize(MCD_VAT, MCD_ESM_ATTACK);

        // Make every flipper relies the MCD_ESM_ATTACK
        for (uint256 i = 0; i < flips.length; i++) {
            DssExecLib.authorize(flips[i], MCD_ESM_ATTACK);
        }

        // ------------------  DOG  ------------------

        // Set VOW in the DOG
        DssExecLib.setContract(MCD_DOG, "vow", MCD_VOW);

        // Authorize DOG can access to VAT
        DssExecLib.authorize(MCD_VAT, MCD_DOG);

        // Authorize DOG can access to VOW
        DssExecLib.authorize(MCD_VOW, MCD_DOG);

        Fileable(MCD_DOG).file("Hole", 10 * THOUSAND * RAD);


        // --------------  CLIPPER_MOM  --------------

        ClipperMomAbstract(CLIPPER_MOM).setAuthority(DssExecLib.getChangelogAddress("MCD_ADM"));

        // ----------------  LINK-A  -----------------

        // Set CLIP for LINK-A in the DOG
        DssExecLib.setContract(MCD_DOG, "LINK-A", "clip", MCD_CLIP_LINK_A);

        // Set VOW in the LINK-A CLIP
        DssExecLib.setContract(MCD_CLIP_LINK_A, "vow", MCD_VOW);

        // Set CALC in the LINK-A CLIP
        DssExecLib.setContract(MCD_CLIP_LINK_A, "calc", MCD_CLIP_CALC_LINK_A);

        // Authorize CLIP can access to VAT
        DssExecLib.authorize(MCD_VAT, MCD_CLIP_LINK_A);

        // Authorize CLIP can access to DOG
        DssExecLib.authorize(MCD_DOG, MCD_CLIP_LINK_A);

        // Authorize DOG can kick auctions on CLIP
        DssExecLib.authorize(MCD_CLIP_LINK_A, MCD_DOG);

        // Authorize the new END to access the LINK CLIP
        DssExecLib.authorize(MCD_CLIP_LINK_A, MCD_END);

        // Authorize CLIPPERMOM can set the stopped flag in CLIP
        DssExecLib.authorize(MCD_CLIP_LINK_A, CLIPPER_MOM);

        // Authorize new ESM to execute in LINK-A Clipper
        DssExecLib.authorize(MCD_CLIP_LINK_A, MCD_ESM_ATTACK);

        // Whitelist CLIP in the LINK osm
        DssExecLib.addReaderToOSMWhitelist(PIP_LINK, MCD_CLIP_LINK_A);

        // Whitelist CLIPPER_MOM in the LINK osm
        DssExecLib.addReaderToOSMWhitelist(PIP_LINK, CLIPPER_MOM);

        // No more auctions kicked via the CAT:
        DssExecLib.deauthorize(MCD_FLIP_LINK_A, MCD_CAT);

        // No more circuit breaker for the FLIP in LINK-A:
        DssExecLib.deauthorize(MCD_FLIP_LINK_A, DssExecLib.flipperMom());

        Fileable(MCD_DOG).file("LINK-A", "hole", 5 * THOUSAND * RAD);
        Fileable(MCD_DOG).file("LINK-A", "chop", 113 * WAD / 100);
        Fileable(MCD_CLIP_LINK_A).file("buf", 130 * RAY / 100);
        Fileable(MCD_CLIP_LINK_A).file("tail", 140 minutes);
        Fileable(MCD_CLIP_LINK_A).file("cusp", 40 * RAY / 100);
        Fileable(MCD_CLIP_LINK_A).file("chip", 1 * WAD / 1000);
        Fileable(MCD_CLIP_LINK_A).file("tip", 0);
        Fileable(MCD_CLIP_CALC_LINK_A).file("cut", 99 * RAY / 100); // 1% cut
        Fileable(MCD_CLIP_CALC_LINK_A).file("step", 90 seconds);

        //  Tolerance currently set to 50%.
        //   n.b. 600000000000000000000000000 == 40% acceptable drop
        ClipperMomAbstract(CLIPPER_MOM).setPriceTolerance(MCD_CLIP_LINK_A, 50 * RAY / 100);

        ClipAbstract(MCD_CLIP_LINK_A).upchost();

        // Replace flip to clip in the ilk registry
        DssExecLib.setContract(ILK_REGISTRY, "LINK-A", "xlip", MCD_CLIP_LINK_A);
        Fileable(ILK_REGISTRY).file("LINK-A", "class", 1);


        // ------------------  CHAINLOG  -----------------

        address log = DssExecLib.getChangelogAddress("CHANGELOG");

        DssExecLib.setChangelogAddress("MCD_DOG", MCD_DOG);
        DssExecLib.setChangelogAddress("MCD_END", MCD_END);
        ChainlogLike(log).removeAddress("MCD_ESM");
        DssExecLib.setChangelogAddress("MCD_ESM_BUG", MCD_ESM_BUG);
        DssExecLib.setChangelogAddress("MCD_ESM_ATTACK", MCD_ESM_ATTACK);
        DssExecLib.setChangelogAddress("CLIPPER_MOM", CLIPPER_MOM);
        DssExecLib.setChangelogAddress("MCD_CLIP_LINK_A", MCD_CLIP_LINK_A);
        DssExecLib.setChangelogAddress("MCD_CLIP_CALC_LINK_A", MCD_CLIP_CALC_LINK_A);
        DssExecLib.setChangelogAddress("ILK_REGISTRY", ILK_REGISTRY);
        ChainlogLike(log).removeAddress("MCD_FLIP_LINK_A");

        // DssExecLib.setChangelogVersion("1.3.0");
    }

}

contract DssSpell is DssExec {
    DssSpellAction internal action_ = new DssSpellAction();
    constructor() DssExec(action_.description(), block.timestamp + 30 days, address(action_)) public {}
}