/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

// hevm: flattened sources of src/Kovan-DssSpell.sol
pragma solidity =0.6.12 >=0.5.12 >=0.6.12 <0.7.0;

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
// SPDX-License-Identifier: AGPL-3.0-or-later
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

interface Initializable_1 {
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

    /*****************/
    /*** Constants ***/
    /*****************/
    address constant public LOG = 0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F;

    uint256 constant internal WAD      = 10 ** 18;
    uint256 constant internal RAY      = 10 ** 27;
    uint256 constant internal RAD      = 10 ** 45;
    uint256 constant internal THOUSAND = 10 ** 3;
    uint256 constant internal MILLION  = 10 ** 6;

    uint256 constant internal BPS_ONE_PCT             = 100;
    uint256 constant internal BPS_ONE_HUNDRED_PCT     = 100 * BPS_ONE_PCT;
    uint256 constant internal RATES_ONE_HUNDRED_PCT   = 1000000021979553151239153027;

    /**********************/
    /*** Math Functions ***/
    /**********************/
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    /****************************/
    /*** Core Address Helpers ***/
    /****************************/
    function dai()        public view returns (address) { return getChangelogAddress("MCD_DAI"); }
    function mkr()        public view returns (address) { return getChangelogAddress("MCD_GOV"); }
    function vat()        public view returns (address) { return getChangelogAddress("MCD_VAT"); }
    function cat()        public view returns (address) { return getChangelogAddress("MCD_CAT"); }
    function jug()        public view returns (address) { return getChangelogAddress("MCD_JUG"); }
    function pot()        public view returns (address) { return getChangelogAddress("MCD_POT"); }
    function vow()        public view returns (address) { return getChangelogAddress("MCD_VOW"); }
    function end()        public view returns (address) { return getChangelogAddress("MCD_END"); }
    function reg()        public view returns (address) { return getChangelogAddress("ILK_REGISTRY"); }
    function spotter()    public view returns (address) { return getChangelogAddress("MCD_SPOT"); }
    function flap()       public view returns (address) { return getChangelogAddress("MCD_FLAP"); }
    function flop()       public view returns (address) { return getChangelogAddress("MCD_FLOP"); }
    function osmMom()     public view returns (address) { return getChangelogAddress("OSM_MOM"); }
    function govGuard()   public view returns (address) { return getChangelogAddress("GOV_GUARD"); }
    function flipperMom() public view returns (address) { return getChangelogAddress("FLIPPER_MOM"); }
    function pauseProxy() public view returns (address) { return getChangelogAddress("MCD_PAUSE_PROXY"); }
    function autoLine()   public view returns (address) { return getChangelogAddress("MCD_IAM_AUTO_LINE"); }
    function daiJoin()    public view returns (address) { return getChangelogAddress("MCD_JOIN_DAI"); }

    function flip(bytes32 _ilk) public view returns (address _flip) {
        (,,,, _flip,,,) = RegistryLike(reg()).ilkData(_ilk);
    }

    function getChangelogAddress(bytes32 _key) public view returns (address) {
        return ChainlogLike(LOG).getAddress(_key);
    }

    /****************************/
    /*** Changelog Management ***/
    /****************************/
    /**
        @dev Set an address in the MCD on-chain changelog.
        @param _key Access key for the address (e.g. "MCD_VAT")
        @param _val The address associated with the _key
    */
    function setChangelogAddress(bytes32 _key, address _val) public {
        ChainlogLike(LOG).setAddress(_key, _val);
    }

    /**
        @dev Set version in the MCD on-chain changelog.
        @param _version Changelog version (e.g. "1.1.2")
    */
    function setChangelogVersion(string memory _version) public {
        ChainlogLike(LOG).setVersion(_version);
    }
    /**
        @dev Set IPFS hash of IPFS changelog in MCD on-chain changelog.
        @param _ipfsHash IPFS hash (e.g. "QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW")
    */
    function setChangelogIPFS(string memory _ipfsHash) public {
        ChainlogLike(LOG).setIPFS(_ipfsHash);
    }
    /**
        @dev Set SHA256 hash in MCD on-chain changelog.
        @param _SHA256Sum SHA256 hash (e.g. "e42dc9d043a57705f3f097099e6b2de4230bca9a020c797508da079f9079e35b")
    */
    function setChangelogSHA256(string memory _SHA256Sum) public {
        ChainlogLike(LOG).setSha256sum(_SHA256Sum);
    }


    /**********************/
    /*** Authorizations ***/
    /**********************/
    /**
        @dev Give an address authorization to perform auth actions on the contract.
        @param _base   The address of the contract where the authorization will be set
        @param _ward   Address to be authorized
    */
    function authorize(address _base, address _ward) public {
        Authorizable(_base).rely(_ward);
    }
    /**
        @dev Revoke contract authorization from an address.
        @param _base   The address of the contract where the authorization will be revoked
        @param _ward   Address to be deauthorized
    */
    function deauthorize(address _base, address _ward) public {
        Authorizable(_base).deny(_ward);
    }
    /**
        @dev Delegate vat authority to the specified address.
        @param _usr Address to be authorized
    */
    function delegateVat(address _usr) public {
        DssVat(vat()).hope(_usr);
    }
    /**
        @dev Revoke vat authority to the specified address.
        @param _usr Address to be deauthorized
    */
    function undelegateVat(address _usr) public {
        DssVat(vat()).nope(_usr);
    }

    /******************************/
    /*** OfficeHours Management ***/
    /******************************/

    /**
        @dev Returns true if a time is within office hours range
        @param _ts           The timestamp to check, usually block.timestamp
        @param _officeHours  true if office hours is enabled.
        @return              true if time is in castable range
    */
    function canCast(uint40 _ts, bool _officeHours) public pure returns (bool) {
        if (_officeHours) {
            uint256 day = (_ts / 1 days + 3) % 7;
            if (day >= 5)                 { return false; }  // Can only be cast on a weekday
            uint256 hour = _ts / 1 hours % 24;
            if (hour < 14 || hour >= 21)  { return false; }  // Outside office hours
        }
        return true;
    }

    /**
        @dev Calculate the next available cast time in epoch seconds
        @param _eta          The scheduled time of the spell plus the pause delay
        @param _ts           The current timestamp, usually block.timestamp
        @param _officeHours  true if office hours is enabled.
        @return castTime     The next available cast timestamp
    */
    function nextCastTime(uint40 _eta, uint40 _ts, bool _officeHours) public pure returns (uint256 castTime) {
        require(_eta != 0);  // "DssExecLib/invalid eta"
        require(_ts  != 0);  // "DssExecLib/invalid ts"
        castTime = _ts > _eta ? _ts : _eta; // Any day at XX:YY

        if (_officeHours) {
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

    /**************************/
    /*** Accumulating Rates ***/
    /**************************/
    /**
        @dev Update rate accumulation for the Dai Savings Rate (DSR).
    */
    function accumulateDSR() public {
        Drippable(pot()).drip();
    }
    /**
        @dev Update rate accumulation for the stability fees of a given collateral type.
        @param _ilk   Collateral type
    */
    function accumulateCollateralStabilityFees(bytes32 _ilk) public {
        Drippable(jug()).drip(_ilk);
    }

    /*********************/
    /*** Price Updates ***/
    /*********************/
    /**
        @dev Update price of a given collateral type.
        @param _ilk   Collateral type
    */
    function updateCollateralPrice(bytes32 _ilk) public {
        Pricing(spotter()).poke(_ilk);
    }

    /****************************/
    /*** System Configuration ***/
    /****************************/
    /**
        @dev Set a contract in another contract, defining the relationship (ex. set a new Cat contract in the Vat)
        @param _base   The address of the contract where the new contract address will be filed
        @param _what   Name of contract to file
        @param _addr   Address of contract to file
    */
    function setContract(address _base, bytes32 _what, address _addr) public {
        Fileable(_base).file(_what, _addr);
    }
    /**
        @dev Set a contract in another contract, defining the relationship (ex. set a new Cat contract in the Vat)
        @param _base   The address of the contract where the new contract address will be filed
        @param _ilk    Collateral type
        @param _what   Name of contract to file
        @param _addr   Address of contract to file
    */
    function setContract(address _base, bytes32 _ilk, bytes32 _what, address _addr) public {
        Fileable(_base).file(_ilk, _what, _addr);
    }

    /******************************/
    /*** System Risk Parameters ***/
    /******************************/
    // function setGlobalDebtCeiling(uint256 _amount) public { setGlobalDebtCeiling(vat(), _amount); }
    /**
        @dev Set the global debt ceiling. Amount will be converted to the correct internal precision.
        @param _amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setGlobalDebtCeiling(uint256 _amount) public {
        require(_amount < WAD);  // "LibDssExec/incorrect-global-Line-precision"
        Fileable(vat()).file("Line", _amount * RAD);
    }
    /**
        @dev Increase the global debt ceiling by a specific amount. Amount will be converted to the correct internal precision.
        @param _amount The amount to add in DAI (ex. 10m DAI amount == 10000000)
    */
    function increaseGlobalDebtCeiling(uint256 _amount) public {
        require(_amount < WAD);  // "LibDssExec/incorrect-Line-increase-precision"
        address _vat = vat();
        Fileable(_vat).file("Line", add(DssVat(_vat).Line(), _amount * RAD));
    }
    /**
        @dev Decrease the global debt ceiling by a specific amount. Amount will be converted to the correct internal precision.
        @param _amount The amount to reduce in DAI (ex. 10m DAI amount == 10000000)
    */
    function decreaseGlobalDebtCeiling(uint256 _amount) public {
        require(_amount < WAD);  // "LibDssExec/incorrect-Line-decrease-precision"
        address _vat = vat();
        Fileable(_vat).file("Line", sub(DssVat(_vat).Line(), _amount * RAD));
    }
    /**
        @dev Set the Dai Savings Rate. See: docs/rates.txt
        @param _rate   The accumulated rate (ex. 4% => 1000000001243680656318820312)
        @param _doDrip `true` to accumulate interest owed
    */
    function setDSR(uint256 _rate, bool _doDrip) public {
        require((_rate >= RAY) && (_rate <= RATES_ONE_HUNDRED_PCT));  // "LibDssExec/dsr-out-of-bounds"
        if (_doDrip) Drippable(pot()).drip();
        Fileable(pot()).file("dsr", _rate);
    }
    /**
        @dev Set the DAI amount for system surplus auctions. Amount will be converted to the correct internal precision.
        @param _amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setSurplusAuctionAmount(uint256 _amount) public {
        require(_amount < WAD);  // "LibDssExec/incorrect-vow-bump-precision"
        Fileable(vow()).file("bump", _amount * RAD);
    }
    /**
        @dev Set the DAI amount for system surplus buffer, must be exceeded before surplus auctions start. Amount will be converted to the correct internal precision.
        @param _amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setSurplusBuffer(uint256 _amount) public {
        require(_amount < WAD);  // "LibDssExec/incorrect-vow-hump-precision"
        Fileable(vow()).file("hump", _amount * RAD);
    }
    /**
        @dev Set minimum bid increase for surplus auctions. Amount will be converted to the correct internal precision.
        @dev Equation used for conversion is (1 + pct / 10,000) * WAD
        @param _pct_bps The pct, in basis points, to set in integer form (x100). (ex. 5% = 5 * 100 = 500)
    */
    function setMinSurplusAuctionBidIncrease(uint256 _pct_bps) public {
        require(_pct_bps < BPS_ONE_HUNDRED_PCT);  // "LibDssExec/incorrect-flap-beg-precision"
        Fileable(flap()).file("beg", add(WAD, wdiv(_pct_bps, BPS_ONE_HUNDRED_PCT)));
    }
    /**
        @dev Set bid duration for surplus auctions.
        @param _duration Amount of time for bids.
    */
    function setSurplusAuctionBidDuration(uint256 _duration) public {
        Fileable(flap()).file("ttl", _duration);
    }
    /**
        @dev Set total auction duration for surplus auctions.
        @param _duration Amount of time for auctions.
    */
    function setSurplusAuctionDuration(uint256 _duration) public {
        Fileable(flap()).file("tau", _duration);
    }
    /**
        @dev Set the number of seconds that pass before system debt is auctioned for MKR tokens.
        @param _duration Duration in seconds
    */
    function setDebtAuctionDelay(uint256 _duration) public {
        Fileable(vow()).file("wait", _duration);
    }
    /**
        @dev Set the DAI amount for system debt to be covered by each debt auction. Amount will be converted to the correct internal precision.
        @param _amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setDebtAuctionDAIAmount(uint256 _amount) public {
        require(_amount < WAD);  // "LibDssExec/incorrect-vow-sump-precision"
        Fileable(vow()).file("sump", _amount * RAD);
    }
    /**
        @dev Set the starting MKR amount to be auctioned off to cover system debt in debt auctions. Amount will be converted to the correct internal precision.
        @param _amount The amount to set in MKR (ex. 250 MKR amount == 250)
    */
    function setDebtAuctionMKRAmount(uint256 _amount) public {
        require(_amount < WAD);  // "LibDssExec/incorrect-vow-dump-precision"
        Fileable(vow()).file("dump", _amount * WAD);
    }
    /**
        @dev Set minimum bid increase for debt auctions. Amount will be converted to the correct internal precision.
        @dev Equation used for conversion is (1 + pct / 10,000) * WAD
        @param _pct_bps    The pct, in basis points, to set in integer form (x100). (ex. 5% = 5 * 100 = 500)
    */
    function setMinDebtAuctionBidIncrease(uint256 _pct_bps) public {
        require(_pct_bps < BPS_ONE_HUNDRED_PCT);  // "LibDssExec/incorrect-flap-beg-precision"
        Fileable(flop()).file("beg", add(WAD, wdiv(_pct_bps, BPS_ONE_HUNDRED_PCT)));
    }
    /**
        @dev Set bid duration for debt auctions.
        @param _duration Amount of time for bids.
    */
    function setDebtAuctionBidDuration(uint256 _duration) public {
        Fileable(flop()).file("ttl", _duration);
    }
    /**
        @dev Set total auction duration for debt auctions.
        @param _duration Amount of time for auctions.
    */
    function setDebtAuctionDuration(uint256 _duration) public {
        Fileable(flop()).file("tau", _duration);
    }
    /**
        @dev Set the rate of increasing amount of MKR out for auction during debt auctions. Amount will be converted to the correct internal precision.
        @dev MKR amount is increased by this rate every "tick" (if auction duration has passed and no one has bid on the MKR)
        @dev Equation used for conversion is (1 + pct / 10,000) * WAD
        @param _pct_bps    The pct, in basis points, to set in integer form (x100). (ex. 5% = 5 * 100 = 500)
    */
    function setDebtAuctionMKRIncreaseRate(uint256 _pct_bps) public {
        Fileable(flop()).file("pad", add(WAD, wdiv(_pct_bps, BPS_ONE_HUNDRED_PCT)));
    }
    /**
        @dev Set the maximum total DAI amount that can be out for liquidation in the system at any point. Amount will be converted to the correct internal precision.
        @param _amount The amount to set in DAI (ex. 250,000 DAI amount == 250000)
    */
    function setMaxTotalDAILiquidationAmount(uint256 _amount) public {
        require(_amount < WAD);  // "LibDssExec/incorrect-vow-dump-precision"
        Fileable(cat()).file("box", _amount * RAD);
    }
    /**
        @dev Set the duration of time that has to pass during emergency shutdown before collateral can start being claimed by DAI holders.
        @param _duration Time in seconds to set for ES processing time
    */
    function setEmergencyShutdownProcessingTime(uint256 _duration) public {
        Fileable(end()).file("wait", _duration);
    }
    /**
        @dev Set the global stability fee (is not typically used, currently is 0).
            Many of the settings that change weekly rely on the rate accumulator
            described at https://docs.makerdao.com/smart-contract-modules/rates-module
            To check this yourself, use the following rate calculation (example 8%):

            $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'

            A table of rates can also be found at:
            https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
        @param _rate   The accumulated rate (ex. 4% => 1000000001243680656318820312)
    */
    function setGlobalStabilityFee(uint256 _rate) public {
        require((_rate >= RAY) && (_rate <= RATES_ONE_HUNDRED_PCT));  // "LibDssExec/global-stability-fee-out-of-bounds"
        Fileable(jug()).file("base", _rate);
    }
    /**
        @dev Set the value of DAI in the reference asset (e.g. $1 per DAI). Value will be converted to the correct internal precision.
        @dev Equation used for conversion is value * RAY / 1000
        @param _value The value to set as integer (x1000) (ex. $1.025 == 1025)
    */
    function setDAIReferenceValue(uint256 _value) public {
        require(_value < WAD);  // "LibDssExec/incorrect-ilk-dunk-precision"
        Fileable(spotter()).file("par", rdiv(_value, 1000));
    }

    /*****************************/
    /*** Collateral Management ***/
    /*****************************/
    /**
        @dev Set a collateral debt ceiling. Amount will be converted to the correct internal precision.
        @param _ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param _amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setIlkDebtCeiling(bytes32 _ilk, uint256 _amount) public {
        require(_amount < WAD);  // "LibDssExec/incorrect-ilk-line-precision"
        Fileable(vat()).file(_ilk, "line", _amount * RAD);
    }
    /**
        @dev Increase a collateral debt ceiling. Amount will be converted to the correct internal precision.
        @param _ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param _amount The amount to increase in DAI (ex. 10m DAI amount == 10000000)
        @param _global If true, increases the global debt ceiling by _amount
    */
    function increaseIlkDebtCeiling(bytes32 _ilk, uint256 _amount, bool _global) public {
        require(_amount < WAD);  // "LibDssExec/incorrect-ilk-line-precision"
        address _vat = vat();
        (,,,uint256 line_,) = DssVat(_vat).ilks(_ilk);
        Fileable(_vat).file(_ilk, "line", add(line_, _amount * RAD));
        if (_global) { increaseGlobalDebtCeiling(_amount); }
    }
    /**
        @dev Decrease a collateral debt ceiling. Amount will be converted to the correct internal precision.
        @param _ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param _amount The amount to decrease in DAI (ex. 10m DAI amount == 10000000)
        @param _global If true, decreases the global debt ceiling by _amount
    */
    function decreaseIlkDebtCeiling(bytes32 _ilk, uint256 _amount, bool _global) public {
        require(_amount < WAD);  // "LibDssExec/incorrect-ilk-line-precision"
        address _vat = vat();
        (,,,uint256 line_,) = DssVat(_vat).ilks(_ilk);
        Fileable(_vat).file(_ilk, "line", sub(line_, _amount * RAD));
        if (_global) { decreaseGlobalDebtCeiling(_amount); }
    }
    /**
        @dev Set the parameters for an ilk in the "MCD_IAM_AUTO_LINE" auto-line
        @param _ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param _amount The Maximum value (ex. 100m DAI amount == 100000000)
        @param _gap    The amount of Dai per step (ex. 5m Dai == 5000000)
        @param _ttl    The amount of time (in seconds)
    */
    function setIlkAutoLineParameters(bytes32 _ilk, uint256 _amount, uint256 _gap, uint256 _ttl) public {
        require(_amount < WAD);  // "LibDssExec/incorrect-auto-line-amount-precision"
        require(_gap < WAD);  // "LibDssExec/incorrect-auto-line-gap-precision"
        IAMLike(autoLine()).setIlk(_ilk, _amount * RAD, _gap * RAD, _ttl);
    }
    /**
        @dev Set the debt ceiling for an ilk in the "MCD_IAM_AUTO_LINE" auto-line without updating the time values
        @param _ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param _amount The Maximum value (ex. 100m DAI amount == 100000000)
    */
    function setIlkAutoLineDebtCeiling(bytes32 _ilk, uint256 _amount) public {
        address _autoLine = autoLine();
        (, uint256 gap, uint48 ttl,,) = IAMLike(_autoLine).ilks(_ilk);
        require(gap != 0 && ttl != 0);  // "LibDssExec/auto-line-not-configured"
        IAMLike(_autoLine).setIlk(_ilk, _amount * RAD, uint256(gap), uint256(ttl));
    }
    /**
        @dev Remove an ilk in the "MCD_IAM_AUTO_LINE" auto-line
        @param _ilk    The ilk to remove (ex. bytes32("ETH-A"))
    */
    function removeIlkFromAutoLine(bytes32 _ilk) public {
        IAMLike(autoLine()).remIlk(_ilk);
    }
    /**
        @dev Set a collateral minimum vault amount. Amount will be converted to the correct internal precision.
        @param _ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param _amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setIlkMinVaultAmount(bytes32 _ilk, uint256 _amount) public {
        require(_amount < WAD);  // "LibDssExec/incorrect-ilk-dust-precision"
        Fileable(vat()).file(_ilk, "dust", _amount * RAD);
    }
    /**
        @dev Set a collateral liquidation penalty. Amount will be converted to the correct internal precision.
        @dev Equation used for conversion is (1 + pct / 10,000) * WAD
        @param _ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param _pct_bps    The pct, in basis points, to set in integer form (x100). (ex. 10.25% = 10.25 * 100 = 1025)
    */
    function setIlkLiquidationPenalty(bytes32 _ilk, uint256 _pct_bps) public {
        require(_pct_bps < BPS_ONE_HUNDRED_PCT);  // "LibDssExec/incorrect-ilk-chop-precision"
        Fileable(cat()).file(_ilk, "chop", add(WAD, wdiv(_pct_bps, BPS_ONE_HUNDRED_PCT)));
    }
    /**
        @dev Set max DAI amount for liquidation per vault for collateral. Amount will be converted to the correct internal precision.
        @param _ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param _amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setIlkMaxLiquidationAmount(bytes32 _ilk, uint256 _amount) public {
        require(_amount < WAD);  // "LibDssExec/incorrect-ilk-dunk-precision"
        Fileable(cat()).file(_ilk, "dunk", _amount * RAD);
    }
    /**
        @dev Set a collateral liquidation ratio. Amount will be converted to the correct internal precision.
        @dev Equation used for conversion is pct * RAY / 10,000
        @param _ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param _pct_bps    The pct, in basis points, to set in integer form (x100). (ex. 150% = 150 * 100 = 15000)
    */
    function setIlkLiquidationRatio(bytes32 _ilk, uint256 _pct_bps) public {
        require(_pct_bps < 10 * BPS_ONE_HUNDRED_PCT); // "LibDssExec/incorrect-ilk-mat-precision" // Fails if pct >= 1000%
        require(_pct_bps >= BPS_ONE_HUNDRED_PCT); // the liquidation ratio has to be bigger or equal to 100%
        Fileable(spotter()).file(_ilk, "mat", rdiv(_pct_bps, BPS_ONE_HUNDRED_PCT));
    }
    /**
        @dev Set minimum bid increase for collateral. Amount will be converted to the correct internal precision.
        @dev Equation used for conversion is (1 + pct / 10,000) * WAD
        @param _ilk   The ilk to update (ex. bytes32("ETH-A"))
        @param _pct_bps    The pct, in basis points, to set in integer form (x100). (ex. 5% = 5 * 100 = 500)
    */
    function setIlkMinAuctionBidIncrease(bytes32 _ilk, uint256 _pct_bps) public {
        require(_pct_bps < BPS_ONE_HUNDRED_PCT);  // "LibDssExec/incorrect-ilk-chop-precision"
        Fileable(flip(_ilk)).file("beg", add(WAD, wdiv(_pct_bps, BPS_ONE_HUNDRED_PCT)));
    }
    /**
        @dev Set bid duration for a collateral type.
        @param _ilk   The ilk to update (ex. bytes32("ETH-A"))
        @param _duration Amount of time for bids.
    */
    function setIlkBidDuration(bytes32 _ilk, uint256 _duration) public {
        Fileable(flip(_ilk)).file("ttl", _duration);
    }
    /**
        @dev Set auction duration for a collateral type.
        @param _ilk   The ilk to update (ex. bytes32("ETH-A"))
        @param _duration Amount of time for auctions.
    */
    function setIlkAuctionDuration(bytes32 _ilk, uint256 _duration) public {
        Fileable(flip(_ilk)).file("tau", _duration);
    }
    /**
        @dev Set the stability fee for a given ilk.
            Many of the settings that change weekly rely on the rate accumulator
            described at https://docs.makerdao.com/smart-contract-modules/rates-module
            To check this yourself, use the following rate calculation (example 8%):

            $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'

            A table of rates can also be found at:
            https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW

        @param _ilk    The ilk to update (ex. bytes32("ETH-A") )
        @param _rate   The accumulated rate (ex. 4% => 1000000001243680656318820312)
        @param _doDrip `true` to accumulate stability fees for the collateral
    */
    function setIlkStabilityFee(bytes32 _ilk, uint256 _rate, bool _doDrip) public {
        require((_rate >= RAY) && (_rate <= RATES_ONE_HUNDRED_PCT));  // "LibDssExec/ilk-stability-fee-out-of-bounds"
        address _jug = jug();
        if (_doDrip) Drippable(_jug).drip(_ilk);

        Fileable(_jug).file(_ilk, "duty", _rate);
    }


    /*************************/
    /*** Oracle Management ***/
    /*************************/
    /**
        @dev Adds oracle feeds to the Median's writer whitelist, allowing the feeds to write prices.
        @param _median Median core contract address
        @param _feeds      Array of oracle feed addresses to add to whitelist
    */
    function addWritersToMedianWhitelist(address _median, address[] memory _feeds) public {
        OracleLike_2(_median).lift(_feeds);
    }
    /**
        @dev Removes oracle feeds to the Median's writer whitelist, disallowing the feeds to write prices.
        @param _median Median core contract address
        @param _feeds      Array of oracle feed addresses to remove from whitelist
    */
    function removeWritersFromMedianWhitelist(address _median, address[] memory _feeds) public {
        OracleLike_2(_median).drop(_feeds);
    }
    /**
        @dev Adds addresses to the Median's reader whitelist, allowing the addresses to read prices from the median.
        @param _median Median core contract address
        @param _readers    Array of addresses to add to whitelist
    */
    function addReadersToMedianWhitelist(address _median, address[] memory _readers) public {
        OracleLike_2(_median).kiss(_readers);
    }
    /**
        @dev Adds an address to the Median's reader whitelist, allowing the address to read prices from the median.
        @param _median Median core contract address
        @param _reader     Address to add to whitelist
    */
    function addReaderToMedianWhitelist(address _median, address _reader) public {
        OracleLike_2(_median).kiss(_reader);
    }
    /**
        @dev Removes addresses from the Median's reader whitelist, disallowing the addresses to read prices from the median.
        @param _median Median core contract address
        @param _readers    Array of addresses to remove from whitelist
    */
    function removeReadersFromMedianWhitelist(address _median, address[] memory _readers) public {
        OracleLike_2(_median).diss(_readers);
    }
    /**
        @dev Removes an address to the Median's reader whitelist, disallowing the address to read prices from the median.
        @param _median Median core contract address
        @param _reader     Address to remove from whitelist
    */
    function removeReaderFromMedianWhitelist(address _median, address _reader) public {
        OracleLike_2(_median).diss(_reader);
    }
    /**
        @dev Sets the minimum number of valid messages from whitelisted oracle feeds needed to update median price.
        @param _median Median core contract address
        @param _minQuorum  Minimum number of valid messages from whitelisted oracle feeds needed to update median price (NOTE: MUST BE ODD NUMBER)
    */
    function setMedianWritersQuorum(address _median, uint256 _minQuorum) public {
        OracleLike_2(_median).setBar(_minQuorum);
    }
    /**
        @dev Adds an address to the Median's reader whitelist, allowing the address to read prices from the OSM.
        @param _osm        Oracle Security Module (OSM) core contract address
        @param _reader     Address to add to whitelist
    */
    function addReaderToOSMWhitelist(address _osm, address _reader) public {
        OracleLike_2(_osm).kiss(_reader);
    }
    /**
        @dev Removes an address to the Median's reader whitelist, disallowing the address to read prices from the OSM.
        @param _osm        Oracle Security Module (OSM) core contract address
        @param _reader     Address to remove from whitelist
    */
    function removeReaderFromOSMWhitelist(address _osm, address _reader) public {
        OracleLike_2(_osm).diss(_reader);
    }
    /**
        @dev Add OSM address to OSM mom, allowing it to be frozen by governance.
        @param _osm        Oracle Security Module (OSM) core contract address
        @param _ilk        Collateral type using OSM
    */
    function allowOSMFreeze(address _osm, bytes32 _ilk) public {
        MomLike(osmMom()).setOsm(_ilk, _osm);
    }
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

////// src/Kovan-DssSpell.sol
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

/* import {Fileable, ChainlogLike} from "dss-exec-lib/DssExecLib.sol"; */
/* import "dss-exec-lib/DssExec.sol"; */
/* import "dss-exec-lib/DssAction.sol"; */
/* import "dss-interfaces/dss/IlkRegistryAbstract.sol"; */
/* import "dss-interfaces/dss/VatAbstract.sol"; */
/* import "dss-interfaces/dss/GemJoinAbstract.sol"; */
/* import "dss-interfaces/dss/JugAbstract.sol"; */
/* import "dss-interfaces/dss/SpotAbstract.sol"; */
/* import "dss-interfaces/dapp/DSTokenAbstract.sol"; */

interface Initializable_2 {
    function init(bytes32) external;
}

interface Hopeable {
    function hope(address) external;
}

interface Kissable {
    function kiss(address) external;
}

interface RwaLiquidationLike {
    function ilks(bytes32) external returns (string memory,address,uint48,uint48);
    function init(bytes32, uint256, string calldata, uint48) external;
}

contract DssSpellAction is DssAction {

    string public constant description = "Kovan Spell";

    // Turn off office hours
    function officeHours() public override returns (bool) {
        return false;
    }

    address constant RWA002_OPERATOR         = 0x2CfADbd094a4D650049C53832B15842a3c59Db34;
    address constant RWA002_GEM              = 0xea8a2f6DC9236edb3f53744f5019a444e24F4379;
    address constant MCD_JOIN_RWA002_A       = 0x3B3fAD77D6977a19cc7B156143056a3E9C6Ca329;
    address constant RWA002_A_URN            = 0xc615F4188C255445290fB9E6dB5E021fe4CA8ECf;
    address constant RWA002_A_INPUT_CONDUIT  = 0x2CfADbd094a4D650049C53832B15842a3c59Db34;
    address constant RWA002_A_OUTPUT_CONDUIT = 0x2CfADbd094a4D650049C53832B15842a3c59Db34;

    uint256 constant THREE_PT_FIVE_PCT      = 1000000001090862085746321732;

    // precision
    uint256 constant public MILLION  = 10 ** 6;
    uint256 constant public WAD      = 10 ** 18;
    uint256 constant public RAY      = 10 ** 27;
    uint256 constant public RAD      = 10 ** 45;


    function actions() public override {
        // --------------------- Replace MIP22 ---------------------

        // Remove old NS2DRP (now RWA002)
        address MCD_VAT      = DssExecLib.vat();
        address ILK_REGISTRY = DssExecLib.reg();
        ChainlogLike CHANGELOG = ChainlogLike(
            DssExecLib.getChangelogAddress("CHANGELOG")
        );

        bytes32 oldIlk = "NS2DRP-A";

        VatAbstract(MCD_VAT).file(oldIlk, "line", 0);
        VatAbstract(MCD_VAT).deny(
            DssExecLib.getChangelogAddress("MCD_JOIN_NS2DRP_A")
        );

        CHANGELOG.removeAddress("NS2DRP");
        CHANGELOG.removeAddress("MCD_JOIN_NS2DRP_A");
        CHANGELOG.removeAddress("PIP_NS2DRP");
        CHANGELOG.removeAddress("NS2DRP_A_URN");
        CHANGELOG.removeAddress("NS2DRP_A_INPUT_CONDUIT");
        CHANGELOG.removeAddress("NS2DRP_A_OUTPUT_CONDUIT");

        IlkRegistryAbstract(ILK_REGISTRY).removeAuth(oldIlk);

        // Add fixed RWA002
        bytes32 ilk   = "RWA002-A";
        uint256 CEIL  = 5 * MILLION;
        uint256 PRICE = 5_634_804 * WAD;
        uint256 MAT   = 10_500;
        uint48 TAU    = 0;

        // https://ipfs.io/ipfs/QmdfuQSLmNFHoxvMjXvv8qbJ2NWprrsvp5L3rGr3JHw18E
        string memory DOC = "QmdfuQSLmNFHoxvMjXvv8qbJ2NWprrsvp5L3rGr3JHw18E";

        address MIP21_LIQUIDATION_ORACLE =
            DssExecLib.getChangelogAddress("MIP21_LIQUIDATION_ORACLE");

        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_RWA002_A).vat() == MCD_VAT, "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA002_A).ilk() == ilk, "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA002_A).gem() == RWA002_GEM, "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA002_A).dec() == DSTokenAbstract(RWA002_GEM).decimals(), "join-dec-not-match");

        RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).init(
            ilk, PRICE, DOC, TAU
        );
        (,address pip,,) = RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).ilks(ilk);

        // Set price feed for RWA002
        DssExecLib.setContract(DssExecLib.spotter(), ilk, "pip", pip);

        // Init RWA-002 in Vat
        Initializable_2(MCD_VAT).init(ilk);
        // Init RWA-002 in Jug
        Initializable_2(DssExecLib.jug()).init(ilk);

        // Allow RWA-002 Join to modify Vat registry
        DssExecLib.authorize(MCD_VAT, MCD_JOIN_RWA002_A);

        // Allow RwaLiquidationOracle to modify Vat registry
        // DssExecLib.authorize(MCD_VAT, MIP21_LIQUIDATION_ORACLE);

        // Set the ilk debt ceiling (not increasing global one as we are replacing the collateral)
        DssExecLib.setIlkDebtCeiling(ilk, CEIL);

        // No dust
        // DssExecLib.setIlkMinVaultAmount(ilk, 0);

        // stability fee
        DssExecLib.setIlkStabilityFee(ilk, THREE_PT_FIVE_PCT, false);

        // collateralization ratio
        DssExecLib.setIlkLiquidationRatio(ilk, MAT);

        // poke the spotter to pull in a price
        DssExecLib.updateCollateralPrice(ilk);

        // give the urn permissions on the join adapter
        // DssExecLib.authorize(MCD_JOIN_RWA002_A, RWA002_A_URN);

        // set up the urn
        Hopeable(RWA002_A_URN).hope(RWA002_OPERATOR);

        // set up output conduit
        // Hopeable(RWA002_A_OUTPUT_CONDUIT).hope(RWA002_OPERATOR);

        // Authorize the SC Domain team deployer address on the output conduit
        // during introductory phase. This allows the SC team to assist in the
        // testing of a complete circuit. Once a broker dealer arrangement is
        // established the deployer address should be `deny`ed on the conduit.
        // Kissable(RWA002_A_OUTPUT_CONDUIT).kiss(SC_DOMAIN_DEPLOYER_07);

        // Add collateral in IlkRegistry
        IlkRegistryAbstract(ILK_REGISTRY).put(
            ilk,
            MCD_JOIN_RWA002_A,
            RWA002_GEM,
            18,
            3,
            pip,
            address(0),
            "RWA-002",
            "RWA002"
        );

        // add RWA-002 contract to the changelog
        DssExecLib.setChangelogAddress("RWA002", RWA002_GEM);
        DssExecLib.setChangelogAddress("PIP_RWA002", pip);
        DssExecLib.setChangelogAddress("MCD_JOIN_RWA002_A", MCD_JOIN_RWA002_A);
        DssExecLib.setChangelogAddress("RWA002_A_URN", RWA002_A_URN);
        DssExecLib.setChangelogAddress(
            "RWA002_A_INPUT_CONDUIT", RWA002_A_INPUT_CONDUIT
        );
        DssExecLib.setChangelogAddress(
            "RWA002_A_OUTPUT_CONDUIT", RWA002_A_OUTPUT_CONDUIT
        );
        DssExecLib.setChangelogVersion("1.2.11");

        // --------------------- Remove ESM_BUG ---------------------
        address MCD_ESM          = DssExecLib.getChangelogAddress("MCD_ESM_ATTACK");
        address MCD_ESM_BUG      = DssExecLib.getChangelogAddress("MCD_ESM_BUG");
        address MCD_END          = DssExecLib.end();

        DssExecLib.deauthorize(MCD_END, MCD_ESM_BUG);

        CHANGELOG.removeAddress("MCD_ESM_BUG");
        CHANGELOG.removeAddress("MCD_ESM_ATTACK");
        DssExecLib.setChangelogAddress("MCD_ESM", MCD_ESM);

        DssExecLib.setChangelogVersion("1.3.0");
    }

}

contract DssSpell is DssExec {
    DssSpellAction internal action_ = new DssSpellAction();
    constructor() DssExec(action_.description(), block.timestamp + 30 days, address(action_)) public {}
}