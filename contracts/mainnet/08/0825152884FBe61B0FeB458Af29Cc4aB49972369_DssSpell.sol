/**
 *Submitted for verification at Etherscan.io on 2021-02-12
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
// hevm: flattened sources of src/DssSpell.sol
pragma solidity =0.6.11 >=0.5.12 >=0.6.11 <0.7.0;

////// lib/dss-exec-lib/src/CollateralOpts.sol
/* pragma solidity ^0.6.11; */

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

////// lib/dss-exec-lib/src/MathLib.sol
//
// MathLib.sol -- Math Functions
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
/* pragma solidity ^0.6.11; */

library MathLib {

    uint256 constant internal WAD      = 10 ** 18;
    uint256 constant internal RAY      = 10 ** 27;
    uint256 constant internal RAD      = 10 ** 45;
    uint256 constant internal THOUSAND = 10 ** 3;
    uint256 constant internal MILLION  = 10 ** 6;

    uint256 constant internal BPS_ONE_PCT             = 100;
    uint256 constant internal BPS_ONE_HUNDRED_PCT     = 100 * BPS_ONE_PCT;
    uint256 constant internal RATES_ONE_HUNDRED_PCT   = 1000000021979553151239153027;

    // --- SafeMath Functions ---
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }
}

////// lib/dss-exec-lib/src/DssExecLib.sol
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
/* pragma solidity ^0.6.11; */

/* import "./MathLib.sol"; */

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
    function ilks(bytes32) external returns (uint256 Art, uint256 rate, uint256 spot, uint256 line, uint256 dust);
    function Line() external view returns (uint256);
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

    using MathLib for *;

    /****************************/
    /*** Changelog Management ***/
    /****************************/
    /**
        @dev Set an address in the MCD on-chain changelog.
        @param _log Address of the chainlog contract
        @param _key Access key for the address (e.g. "MCD_VAT")
        @param _val The address associated with the _key
    */
    function setChangelogAddress(address _log, bytes32 _key, address _val) public {
        ChainlogLike(_log).setAddress(_key, _val);
    }

    /**
        @dev Set version in the MCD on-chain changelog.
        @param _log Address of the chainlog contract
        @param _version Changelog version (e.g. "1.1.2")
    */
    function setChangelogVersion(address _log, string memory _version) public {
        ChainlogLike(_log).setVersion(_version);
    }
    /**
        @dev Set IPFS hash of IPFS changelog in MCD on-chain changelog.
        @param _log Address of the chainlog contract
        @param _ipfsHash IPFS hash (e.g. "QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW")
    */
    function setChangelogIPFS(address _log, string memory _ipfsHash) public {
        ChainlogLike(_log).setIPFS(_ipfsHash);
    }
    /**
        @dev Set SHA256 hash in MCD on-chain changelog.
        @param _log Address of the chainlog contract
        @param _SHA256Sum SHA256 hash (e.g. "e42dc9d043a57705f3f097099e6b2de4230bca9a020c797508da079f9079e35b")
    */
    function setChangelogSHA256(address _log, string memory _SHA256Sum) public {
        ChainlogLike(_log).setSha256sum(_SHA256Sum);
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

    /**************************/
    /*** Accumulating Rates ***/
    /**************************/
    /**
        @dev Update rate accumulation for the Dai Savings Rate (DSR).
        @param _pot   Address of the MCD_POT core contract
    */
    function accumulateDSR(address _pot) public {
        Drippable(_pot).drip();
    }
    /**
        @dev Update rate accumulation for the stability fees of a given collateral type.
        @param _jug   Address of the MCD_JUG core contract
        @param _ilk   Collateral type
    */
    function accumulateCollateralStabilityFees(address _jug, bytes32 _ilk) public {
        Drippable(_jug).drip(_ilk);
    }

    /*********************/
    /*** Price Updates ***/
    /*********************/
    /**
        @dev Update price of a given collateral type.
        @param _spot  Spotter contract address
        @param _ilk   Collateral type
    */
    function updateCollateralPrice(address _spot, bytes32 _ilk) public {
        Pricing(_spot).poke(_ilk);
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
        @param _vat    The address of the Vat core accounting contract
        @param _amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setGlobalDebtCeiling(address _vat, uint256 _amount) public {
        require(_amount < MathLib.WAD);  // "LibDssExec/incorrect-global-Line-precision"
        Fileable(_vat).file("Line", _amount * MathLib.RAD);
    }
    /**
        @dev Increase the global debt ceiling by a specific amount. Amount will be converted to the correct internal precision.
        @param _vat    The address of the Vat core accounting contract
        @param _amount The amount to add in DAI (ex. 10m DAI amount == 10000000)
    */
    function increaseGlobalDebtCeiling(address _vat, uint256 _amount) public {
        require(_amount < MathLib.WAD);  // "LibDssExec/incorrect-Line-increase-precision"
        Fileable(_vat).file("Line", MathLib.add(DssVat(_vat).Line(), _amount * MathLib.RAD));
    }
    /**
        @dev Decrease the global debt ceiling by a specific amount. Amount will be converted to the correct internal precision.
        @param _vat    The address of the Vat core accounting contract
        @param _amount The amount to reduce in DAI (ex. 10m DAI amount == 10000000)
    */
    function decreaseGlobalDebtCeiling(address _vat, uint256 _amount) public {
        require(_amount < MathLib.WAD);  // "LibDssExec/incorrect-Line-decrease-precision"
        Fileable(_vat).file("Line", MathLib.sub(DssVat(_vat).Line(), _amount * MathLib.RAD));
    }
    /**
        @dev Set the Dai Savings Rate. See: docs/rates.txt
        @param _pot    The address of the Pot core contract
        @param _rate   The accumulated rate (ex. 4% => 1000000001243680656318820312)
    */
    function setDSR(address _pot, uint256 _rate) public {
        require((_rate >= MathLib.RAY) && (_rate <= MathLib.RATES_ONE_HUNDRED_PCT));  // "LibDssExec/dsr-out-of-bounds"
        Fileable(_pot).file("dsr", _rate);
    }
    /**
        @dev Set the DAI amount for system surplus auctions. Amount will be converted to the correct internal precision.
        @param _vow    The address of the Vow core contract
        @param _amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setSurplusAuctionAmount(address _vow, uint256 _amount) public {
        require(_amount < MathLib.WAD);  // "LibDssExec/incorrect-vow-bump-precision"
        Fileable(_vow).file("bump", _amount * MathLib.RAD);
    }
    /**
        @dev Set the DAI amount for system surplus buffer, must be exceeded before surplus auctions start. Amount will be converted to the correct internal precision.
        @param _vow    The address of the Vow core contract
        @param _amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setSurplusBuffer(address _vow, uint256 _amount) public {
        require(_amount < MathLib.WAD);  // "LibDssExec/incorrect-vow-hump-precision"
        Fileable(_vow).file("hump", _amount * MathLib.RAD);
    }
    /**
        @dev Set minimum bid increase for surplus auctions. Amount will be converted to the correct internal precision.
        @dev Equation used for conversion is (1 + pct / 10,000) * WAD
        @param _flap    The address of the Flapper core contract
        @param _pct_bps The pct, in basis points, to set in integer form (x100). (ex. 5% = 5 * 100 = 500)
    */
    function setMinSurplusAuctionBidIncrease(address _flap, uint256 _pct_bps) public {
        require(_pct_bps < MathLib.BPS_ONE_HUNDRED_PCT);  // "LibDssExec/incorrect-flap-beg-precision"
        Fileable(_flap).file("beg", MathLib.add(MathLib.WAD, MathLib.wdiv(_pct_bps, MathLib.BPS_ONE_HUNDRED_PCT)));
    }
    /**
        @dev Set bid duration for surplus auctions.
        @param _flap   The address of the Flapper core contract
        @param _duration Amount of time for bids.
    */
    function setSurplusAuctionBidDuration(address _flap, uint256 _duration) public {
        Fileable(_flap).file("ttl", _duration);
    }
    /**
        @dev Set total auction duration for surplus auctions.
        @param _flap   The address of the Flapper core contract
        @param _duration Amount of time for auctions.
    */
    function setSurplusAuctionDuration(address _flap, uint256 _duration) public {
        Fileable(_flap).file("tau", _duration);
    }
    /**
        @dev Set the number of seconds that pass before system debt is auctioned for MKR tokens.
        @param _vow    The address of the Vow core contract
        @param _duration Duration in seconds
    */
    function setDebtAuctionDelay(address _vow, uint256 _duration) public {
        Fileable(_vow).file("wait", _duration);
    }
    /**
        @dev Set the DAI amount for system debt to be covered by each debt auction. Amount will be converted to the correct internal precision.
        @param _vow    The address of the Vow core contract
        @param _amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setDebtAuctionDAIAmount(address _vow, uint256 _amount) public {
        require(_amount < MathLib.WAD);  // "LibDssExec/incorrect-vow-sump-precision"
        Fileable(_vow).file("sump", _amount * MathLib.RAD);
    }
    /**
        @dev Set the starting MKR amount to be auctioned off to cover system debt in debt auctions. Amount will be converted to the correct internal precision.
        @param _vow    The address of the Vow core contract
        @param _amount The amount to set in MKR (ex. 250 MKR amount == 250)
    */
    function setDebtAuctionMKRAmount(address _vow, uint256 _amount) public {
        require(_amount < MathLib.WAD);  // "LibDssExec/incorrect-vow-dump-precision"
        Fileable(_vow).file("dump", _amount * MathLib.WAD);
    }
    /**
        @dev Set minimum bid increase for debt auctions. Amount will be converted to the correct internal precision.
        @dev Equation used for conversion is (1 + pct / 10,000) * WAD
        @param _flop   The address of the Flopper core contract
        @param _pct_bps    The pct, in basis points, to set in integer form (x100). (ex. 5% = 5 * 100 = 500)
    */
    function setMinDebtAuctionBidIncrease(address _flop, uint256 _pct_bps) public {
        require(_pct_bps < MathLib.BPS_ONE_HUNDRED_PCT);  // "LibDssExec/incorrect-flap-beg-precision"
        Fileable(_flop).file("beg", MathLib.add(MathLib.WAD, MathLib.wdiv(_pct_bps, MathLib.BPS_ONE_HUNDRED_PCT)));
    }
    /**
        @dev Set bid duration for debt auctions.
        @param _flop   The address of the Flopper core contract
        @param _duration Amount of time for bids.
    */
    function setDebtAuctionBidDuration(address _flop, uint256 _duration) public {
        Fileable(_flop).file("ttl", _duration);
    }
    /**
        @dev Set total auction duration for debt auctions.
        @param _flop   The address of the Flopper core contract
        @param _duration Amount of time for auctions.
    */
    function setDebtAuctionDuration(address _flop, uint256 _duration) public {
        Fileable(_flop).file("tau", _duration);
    }
    /**
        @dev Set the rate of increasing amount of MKR out for auction during debt auctions. Amount will be converted to the correct internal precision.
        @dev MKR amount is increased by this rate every "tick" (if auction duration has passed and no one has bid on the MKR)
        @dev Equation used for conversion is (1 + pct / 10,000) * WAD
        @param _flop   The address of the Flopper core contract
        @param _pct_bps    The pct, in basis points, to set in integer form (x100). (ex. 5% = 5 * 100 = 500)
    */
    function setDebtAuctionMKRIncreaseRate(address _flop, uint256 _pct_bps) public {
        Fileable(_flop).file("pad", MathLib.add(MathLib.WAD, MathLib.wdiv(_pct_bps, MathLib.BPS_ONE_HUNDRED_PCT)));
    }
    /**
        @dev Set the maximum total DAI amount that can be out for liquidation in the system at any point. Amount will be converted to the correct internal precision.
        @param _cat    The address of the Cat core contract
        @param _amount The amount to set in DAI (ex. 250,000 DAI amount == 250000)
    */
    function setMaxTotalDAILiquidationAmount(address _cat, uint256 _amount) public {
        require(_amount < MathLib.WAD);  // "LibDssExec/incorrect-vow-dump-precision"
        Fileable(_cat).file("box", _amount * MathLib.RAD);
    }
    /**
        @dev Set the duration of time that has to pass during emergency shutdown before collateral can start being claimed by DAI holders.
        @param _end    The address of the End core contract
        @param _duration Time in seconds to set for ES processing time
    */
    function setEmergencyShutdownProcessingTime(address _end, uint256 _duration) public {
        Fileable(_end).file("wait", _duration);
    }
    /**
        @dev Set the global stability fee (is not typically used, currently is 0).
            Many of the settings that change weekly rely on the rate accumulator
            described at https://docs.makerdao.com/smart-contract-modules/rates-module
            To check this yourself, use the following rate calculation (example 8%):

            $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'

            A table of rates can also be found at:
            https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
        @param _jug    The address of the Jug core accounting contract
        @param _rate   The accumulated rate (ex. 4% => 1000000001243680656318820312)
    */
    function setGlobalStabilityFee(address _jug, uint256 _rate) public {
        require((_rate >= MathLib.RAY) && (_rate <= MathLib.RATES_ONE_HUNDRED_PCT));  // "LibDssExec/global-stability-fee-out-of-bounds"
        Fileable(_jug).file("base", _rate);
    }
    /**
        @dev Set the value of DAI in the reference asset (e.g. $1 per DAI). Value will be converted to the correct internal precision.
        @dev Equation used for conversion is value * RAY / 1000
        @param _spot   The address of the Spot core contract
        @param _value The value to set as integer (x1000) (ex. $1.025 == 1025)
    */
    function setDAIReferenceValue(address _spot, uint256 _value) public {
        require(_value < MathLib.WAD);  // "LibDssExec/incorrect-ilk-dunk-precision"
        Fileable(_spot).file("par", MathLib.rdiv(_value, 1000));
    }

    /*****************************/
    /*** Collateral Management ***/
    /*****************************/
    /**
        @dev Set a collateral debt ceiling. Amount will be converted to the correct internal precision.
        @param _vat    The address of the Vat core accounting contract
        @param _ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param _amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setIlkDebtCeiling(address _vat, bytes32 _ilk, uint256 _amount) public {
        require(_amount < MathLib.WAD);  // "LibDssExec/incorrect-ilk-line-precision"
        Fileable(_vat).file(_ilk, "line", _amount * MathLib.RAD);
    }
    /**
        @dev Increase a collateral debt ceiling. Amount will be converted to the correct internal precision.
        @param _vat    The address of the Vat core accounting contract
        @param _ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param _amount The amount to increase in DAI (ex. 10m DAI amount == 10000000)
        @param _global If true, increases the global debt ceiling by _amount
    */
    function increaseIlkDebtCeiling(address _vat, bytes32 _ilk, uint256 _amount, bool _global) public {
        require(_amount < MathLib.WAD);  // "LibDssExec/incorrect-ilk-line-precision"
        (,,,uint256 line_,) = DssVat(_vat).ilks(_ilk);
        Fileable(_vat).file(_ilk, "line", MathLib.add(line_, _amount * MathLib.RAD));
        if (_global) { increaseGlobalDebtCeiling(_vat, _amount); }
    }
    /**
        @dev Decrease a collateral debt ceiling. Amount will be converted to the correct internal precision.
        @param _vat    The address of the Vat core accounting contract
        @param _ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param _amount The amount to decrease in DAI (ex. 10m DAI amount == 10000000)
        @param _global If true, decreases the global debt ceiling by _amount
    */
    function decreaseIlkDebtCeiling(address _vat, bytes32 _ilk, uint256 _amount, bool _global) public {
        require(_amount < MathLib.WAD);  // "LibDssExec/incorrect-ilk-line-precision"
        (,,,uint256 line_,) = DssVat(_vat).ilks(_ilk);
        Fileable(_vat).file(_ilk, "line", MathLib.sub(line_, _amount * MathLib.RAD));
        if (_global) { decreaseGlobalDebtCeiling(_vat, _amount); }
    }
    /**
        @dev Set the parameters for an ilk in the "MCD_IAM_AUTO_LINE" auto-line
        @param _iam    The address of the Vat core accounting contract
        @param _ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param _amount The Maximum value (ex. 100m DAI amount == 100000000)
        @param _gap    The amount of Dai per step (ex. 5m Dai == 5000000)
        @param _ttl    The amount of time (in seconds)
    */
    function setIlkAutoLineParameters(address _iam, bytes32 _ilk, uint256 _amount, uint256 _gap, uint256 _ttl) public {
        require(_amount < MathLib.WAD);  // "LibDssExec/incorrect-auto-line-amount-precision"
        require(_gap < MathLib.WAD);  // "LibDssExec/incorrect-auto-line-gap-precision"
        IAMLike(_iam).setIlk(_ilk, _amount * MathLib.RAD, _gap * MathLib.RAD, _ttl);
    }
    /**
        @dev Set the debt ceiling for an ilk in the "MCD_IAM_AUTO_LINE" auto-line without updating the time values
        @param _iam    The address of the Vat core accounting contract
        @param _ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param _amount The amount to decrease in DAI (ex. 10m DAI amount == 10000000)
    */
    function setIlkAutoLineDebtCeiling(address _iam, bytes32 _ilk, uint256 _amount) public {
        (, uint256 gap, uint48 ttl,,) = IAMLike(_iam).ilks(_ilk);
        require(gap != 0 && ttl != 0);  // "LibDssExec/auto-line-not-configured"
        IAMLike(_iam).setIlk(_ilk, _amount * MathLib.RAD, uint256(gap), uint256(ttl));
    }
    /**
        @dev Remove an ilk in the "MCD_IAM_AUTO_LINE" auto-line
        @param _iam    The address of the MCD_IAM_AUTO_LINE core accounting contract
        @param _ilk    The ilk to remove (ex. bytes32("ETH-A"))
    */
    function removeIlkFromAutoLine(address _iam, bytes32 _ilk) public {
        IAMLike(_iam).remIlk(_ilk);
    }
    /**
        @dev Set a collateral minimum vault amount. Amount will be converted to the correct internal precision.
        @param _vat    The address of the Vat core accounting contract
        @param _ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param _amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setIlkMinVaultAmount(address _vat, bytes32 _ilk, uint256 _amount) public {
        require(_amount < MathLib.WAD);  // "LibDssExec/incorrect-ilk-dust-precision"
        Fileable(_vat).file(_ilk, "dust", _amount * MathLib.RAD);
    }
    /**
        @dev Set a collateral liquidation penalty. Amount will be converted to the correct internal precision.
        @dev Equation used for conversion is (1 + pct / 10,000) * WAD
        @param _cat    The address of the Cat core accounting contract (will need to revisit for LIQ-2.0)
        @param _ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param _pct_bps    The pct, in basis points, to set in integer form (x100). (ex. 10.25% = 10.25 * 100 = 1025)
    */
    function setIlkLiquidationPenalty(address _cat, bytes32 _ilk, uint256 _pct_bps) public {
        require(_pct_bps < MathLib.BPS_ONE_HUNDRED_PCT);  // "LibDssExec/incorrect-ilk-chop-precision"
        Fileable(_cat).file(_ilk, "chop", MathLib.add(MathLib.WAD, MathLib.wdiv(_pct_bps, MathLib.BPS_ONE_HUNDRED_PCT)));
    }
    /**
        @dev Set max DAI amount for liquidation per vault for collateral. Amount will be converted to the correct internal precision.
        @param _cat    The address of the Cat core accounting contract (will need to revisit for LIQ-2.0)
        @param _ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param _amount The amount to set in DAI (ex. 10m DAI amount == 10000000)
    */
    function setIlkMaxLiquidationAmount(address _cat, bytes32 _ilk, uint256 _amount) public {
        require(_amount < MathLib.WAD);  // "LibDssExec/incorrect-ilk-dunk-precision"
        Fileable(_cat).file(_ilk, "dunk", _amount * MathLib.RAD);
    }
    /**
        @dev Set a collateral liquidation ratio. Amount will be converted to the correct internal precision.
        @dev Equation used for conversion is pct * RAY / 10,000
        @param _spot   The address of the Spot core accounting contract
        @param _ilk    The ilk to update (ex. bytes32("ETH-A"))
        @param _pct_bps    The pct, in basis points, to set in integer form (x100). (ex. 150% = 150 * 100 = 15000)
    */
    function setIlkLiquidationRatio(address _spot, bytes32 _ilk, uint256 _pct_bps) public {
        require(_pct_bps < 10 * MathLib.BPS_ONE_HUNDRED_PCT); // "LibDssExec/incorrect-ilk-mat-precision" // Fails if pct >= 1000%
        require(_pct_bps >= MathLib.BPS_ONE_HUNDRED_PCT); // the liquidation ratio has to be bigger or equal to 100%
        Fileable(_spot).file(_ilk, "mat", MathLib.rdiv(_pct_bps, MathLib.BPS_ONE_HUNDRED_PCT));
    }
    /**
        @dev Set minimum bid increase for collateral. Amount will be converted to the correct internal precision.
        @dev Equation used for conversion is (1 + pct / 10,000) * WAD
        @param _flip   The address of the ilk's flip core accounting contract
        @param _pct_bps    The pct, in basis points, to set in integer form (x100). (ex. 5% = 5 * 100 = 500)
    */
    function setIlkMinAuctionBidIncrease(address _flip, uint256 _pct_bps) public {
        require(_pct_bps < MathLib.BPS_ONE_HUNDRED_PCT);  // "LibDssExec/incorrect-ilk-chop-precision"
        Fileable(_flip).file("beg", MathLib.add(MathLib.WAD, MathLib.wdiv(_pct_bps, MathLib.BPS_ONE_HUNDRED_PCT)));
    }
    /**
        @dev Set bid duration for a collateral type.
        @param _flip   The address of the ilk's flip core accounting contract
        @param _duration Amount of time for bids.
    */
    function setIlkBidDuration(address _flip, uint256 _duration) public {
        Fileable(_flip).file("ttl", _duration);
    }
    /**
        @dev Set auction duration for a collateral type.
        @param _flip   The address of the ilk's flip core accounting contract
        @param _duration Amount of time for auctions.
    */
    function setIlkAuctionDuration(address _flip, uint256 _duration) public {
        Fileable(_flip).file("tau", _duration);
    }
    /**
        @dev Set the stability fee for a given ilk.
            Many of the settings that change weekly rely on the rate accumulator
            described at https://docs.makerdao.com/smart-contract-modules/rates-module
            To check this yourself, use the following rate calculation (example 8%):

            $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'

            A table of rates can also be found at:
            https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW

        @param _jug    The address of the Jug core accounting contract
        @param _ilk    The ilk to update (ex. bytes32("ETH-A") )
        @param _rate   The accumulated rate (ex. 4% => 1000000001243680656318820312)
        @param _doDrip `true` to accumulate stability fees for the collateral
    */
    function setIlkStabilityFee(address _jug, bytes32 _ilk, uint256 _rate, bool _doDrip) public {
        require((_rate >= MathLib.RAY) && (_rate <= MathLib.RATES_ONE_HUNDRED_PCT));  // "LibDssExec/ilk-stability-fee-out-of-bounds"
        if (_doDrip) Drippable(_jug).drip(_ilk);

        Fileable(_jug).file(_ilk, "duty", _rate);
    }

    /***********************/
    /*** Core Management ***/
    /***********************/
    /**
        @dev Update collateral auction contracts.
        @param _vat        Vat core contract address
        @param _cat        Cat core contract address
        @param _end        End core contract address
        @param _flipperMom Flipper Mom core contract address
        @param _ilk        The collateral's auction contract to update
        @param _newFlip    New auction contract address
        @param _oldFlip    Old auction contract address
    */
    function updateCollateralAuctionContract(
        address _vat,
        address _cat,
        address _end,
        address _flipperMom,
        bytes32 _ilk,
        address _newFlip,
        address _oldFlip
    ) public {
        // Add new flip address to Cat
        setContract(_cat, _ilk, "flip", _newFlip);

        // Authorize MCD contracts for new flip
        authorize(_newFlip, _cat);
        authorize(_newFlip, _end);
        authorize(_newFlip, _flipperMom);

        // Deauthorize MCD contracts for old flip
        deauthorize(_oldFlip, _cat);
        deauthorize(_oldFlip, _end);
        deauthorize(_oldFlip, _flipperMom);

        // Transfer auction params from old flip to new flip
        Fileable(_newFlip).file("beg", AuctionLike(_oldFlip).beg());
        Fileable(_newFlip).file("ttl", AuctionLike(_oldFlip).ttl());
        Fileable(_newFlip).file("tau", AuctionLike(_oldFlip).tau());

        // Sanity checks
        require(AuctionLike(_newFlip).ilk() == _ilk);  // "non-matching-ilk"
        require(AuctionLike(_newFlip).vat() == _vat);  // "non-matching-vat"
    }
    /**
        @dev Update surplus auction contracts.
        @param _vat     Vat core contract address
        @param _vow     Vow core contract address
        @param _newFlap New surplus auction contract address
        @param _oldFlap Old surplus auction contract address
    */
    function updateSurplusAuctionContract(address _vat, address _vow, address _newFlap, address _oldFlap) public {

        // Add new flap address to Vow
        setContract(_vow, "flapper", _newFlap);

        // Authorize MCD contracts for new flap
        authorize(_newFlap, _vow);

        // Deauthorize MCD contracts for old flap
        deauthorize(_oldFlap, _vow);

        // Transfer auction params from old flap to new flap
        Fileable(_newFlap).file("beg", AuctionLike(_oldFlap).beg());
        Fileable(_newFlap).file("ttl", AuctionLike(_oldFlap).ttl());
        Fileable(_newFlap).file("tau", AuctionLike(_oldFlap).tau());

        // Sanity checks
        require(AuctionLike(_newFlap).gem() == AuctionLike(_oldFlap).gem());  // "non-matching-gem"
        require(AuctionLike(_newFlap).vat() == _vat);  // "non-matching-vat"
    }
    /**
        @dev Update debt auction contracts.
        @param _vat          Vat core contract address
        @param _vow          Vow core contract address
        @param _mkrAuthority MKRAuthority core contract address
        @param _newFlop      New debt auction contract address
        @param _oldFlop      Old debt auction contract address
    */
    function updateDebtAuctionContract(address _vat, address _vow, address _mkrAuthority, address _newFlop, address _oldFlop) public {
        // Add new flop address to Vow
        setContract(_vow, "flopper", _newFlop);

        // Authorize MCD contracts for new flop
        authorize(_newFlop, _vow);
        authorize(_vat, _newFlop);
        authorize(_mkrAuthority, _newFlop);

        // Deauthorize MCD contracts for old flop
        deauthorize(_oldFlop, _vow);
        deauthorize(_vat, _oldFlop);
        deauthorize(_mkrAuthority, _oldFlop);

        // Transfer auction params from old flop to new flop
        Fileable(_newFlop).file("beg", AuctionLike(_oldFlop).beg());
        Fileable(_newFlop).file("pad", AuctionLike(_oldFlop).pad());
        Fileable(_newFlop).file("ttl", AuctionLike(_oldFlop).ttl());
        Fileable(_newFlop).file("tau", AuctionLike(_oldFlop).tau());

        // Sanity checks
        require(AuctionLike(_newFlop).gem() == AuctionLike(_oldFlop).gem()); // "non-matching-gem"
        require(AuctionLike(_newFlop).vat() == _vat);  // "non-matching-vat"
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
        OracleLike(_median).lift(_feeds);
    }
    /**
        @dev Removes oracle feeds to the Median's writer whitelist, disallowing the feeds to write prices.
        @param _median Median core contract address
        @param _feeds      Array of oracle feed addresses to remove from whitelist
    */
    function removeWritersFromMedianWhitelist(address _median, address[] memory _feeds) public {
        OracleLike(_median).drop(_feeds);
    }
    /**
        @dev Adds addresses to the Median's reader whitelist, allowing the addresses to read prices from the median.
        @param _median Median core contract address
        @param _readers    Array of addresses to add to whitelist
    */
    function addReadersToMedianWhitelist(address _median, address[] memory _readers) public {
        OracleLike(_median).kiss(_readers);
    }
    /**
        @dev Adds an address to the Median's reader whitelist, allowing the address to read prices from the median.
        @param _median Median core contract address
        @param _reader     Address to add to whitelist
    */
    function addReaderToMedianWhitelist(address _median, address _reader) public {
        OracleLike(_median).kiss(_reader);
    }
    /**
        @dev Removes addresses from the Median's reader whitelist, disallowing the addresses to read prices from the median.
        @param _median Median core contract address
        @param _readers    Array of addresses to remove from whitelist
    */
    function removeReadersFromMedianWhitelist(address _median, address[] memory _readers) public {
        OracleLike(_median).diss(_readers);
    }
    /**
        @dev Removes an address to the Median's reader whitelist, disallowing the address to read prices from the median.
        @param _median Median core contract address
        @param _reader     Address to remove from whitelist
    */
    function removeReaderFromMedianWhitelist(address _median, address _reader) public {
        OracleLike(_median).diss(_reader);
    }
    /**
        @dev Sets the minimum number of valid messages from whitelisted oracle feeds needed to update median price.
        @param _median Median core contract address
        @param _minQuorum  Minimum number of valid messages from whitelisted oracle feeds needed to update median price (NOTE: MUST BE ODD NUMBER)
    */
    function setMedianWritersQuorum(address _median, uint256 _minQuorum) public {
        OracleLike(_median).setBar(_minQuorum);
    }
    /**
        @dev Adds an address to the Median's reader whitelist, allowing the address to read prices from the OSM.
        @param _osm        Oracle Security Module (OSM) core contract address
        @param _reader     Address to add to whitelist
    */
    function addReaderToOSMWhitelist(address _osm, address _reader) public {
        OracleLike(_osm).kiss(_reader);
    }
    /**
        @dev Removes an address to the Median's reader whitelist, disallowing the address to read prices from the OSM.
        @param _osm        Oracle Security Module (OSM) core contract address
        @param _reader     Address to remove from whitelist
    */
    function removeReaderFromOSMWhitelist(address _osm, address _reader) public {
        OracleLike(_osm).diss(_reader);
    }
    /**
        @dev Add OSM address to OSM mom, allowing it to be frozen by governance.
        @param _osmMom     OSM Mom core contract address
        @param _osm        Oracle Security Module (OSM) core contract address
        @param _ilk        Collateral type using OSM
    */
    function allowOSMFreeze(address _osmMom, address _osm, bytes32 _ilk) public {
        MomLike(_osmMom).setOsm(_ilk, _osm);
    }


    /*****************************/
    /*** Collateral Onboarding ***/
    /*****************************/

    /**
        @dev Performs basic functions and sanity checks to add a new collateral type to the MCD system
        @param _vat      MCD_VAT
        @param _cat      MCD_CAT
        @param _jug      MCD_JUG
        @param _end      MCD_END
        @param _spot     MCD_SPOT
        @param _reg      ILK_REGISTRY
        @param _ilk      Collateral type key code [Ex. "ETH-A"]
        @param _gem      Address of token contract
        @param _join     Address of join adapter
        @param _flip     Address of flipper
        @param _pip      Address of price feed
    */
    function addCollateralBase(
        address _vat,
        address _cat,
        address _jug,
        address _end,
        address _spot,
        address _reg,
        bytes32 _ilk,
        address _gem,
        address _join,
        address _flip,
        address _pip
    ) public {
        // Sanity checks
        require(JoinLike(_join).vat() == _vat);     // "join-vat-not-match"
        require(JoinLike(_join).ilk() == _ilk);     // "join-ilk-not-match"
        require(JoinLike(_join).gem() == _gem);     // "join-gem-not-match"
        require(JoinLike(_join).dec() ==
                   ERC20(_gem).decimals());         // "join-dec-not-match"
        require(AuctionLike(_flip).vat() == _vat);  // "flip-vat-not-match"
        require(AuctionLike(_flip).cat() == _cat);  // "flip-cat-not-match"
        require(AuctionLike(_flip).ilk() == _ilk);  // "flip-ilk-not-match"

        // Set the token PIP in the Spotter
        setContract(_spot, _ilk, "pip", _pip);

        // Set the ilk Flipper in the Cat
        setContract(_cat, _ilk, "flip", _flip);

        // Init ilk in Vat & Jug
        Initializable(_vat).init(_ilk);  // Vat
        Initializable(_jug).init(_ilk);  // Jug

        // Allow ilk Join to modify Vat registry
        authorize(_vat, _join);
		// Allow the ilk Flipper to reduce the Cat litterbox on deal()
        authorize(_cat, _flip);
        // Allow Cat to kick auctions in ilk Flipper
        authorize(_flip, _cat);
        // Allow End to yank auctions in ilk Flipper
        authorize(_flip, _end);

        // Add new ilk to the IlkRegistry
        RegistryLike(_reg).add(_join);
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

/* pragma solidity ^0.6.11; */

/* import "./CollateralOpts.sol"; */
/* import "./DssExecLib.sol"; */

abstract contract DssAction {

    using DssExecLib for *;

    bool    public immutable officeHours;

    // Changelog address applies to MCD deployments on
    //        mainnet, kovan, rinkeby, ropsten, and goerli
    address constant public LOG = 0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F;

    constructor(bool officeHours_) public {
        officeHours = officeHours_;
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
        if (officeHours) {
            uint day = (block.timestamp / 1 days + 3) % 7;
            require(day < 5, "Can only be cast on a weekday");
            uint hour = block.timestamp / 1 hours % 24;
            require(hour >= 14 && hour < 21, "Outside office hours");
        }
        _;
    }

    /****************************/
    /*** Core Address Helpers ***/
    /****************************/
    function vat()        internal view returns (address) { return getChangelogAddress("MCD_VAT"); }
    function cat()        internal view returns (address) { return getChangelogAddress("MCD_CAT"); }
    function jug()        internal view returns (address) { return getChangelogAddress("MCD_JUG"); }
    function pot()        internal view returns (address) { return getChangelogAddress("MCD_POT"); }
    function vow()        internal view returns (address) { return getChangelogAddress("MCD_VOW"); }
    function end()        internal view returns (address) { return getChangelogAddress("MCD_END"); }
    function reg()        internal view returns (address) { return getChangelogAddress("ILK_REGISTRY"); }
    function spot()       internal view returns (address) { return getChangelogAddress("MCD_SPOT"); }
    function flap()       internal view returns (address) { return getChangelogAddress("MCD_FLAP"); }
    function flop()       internal view returns (address) { return getChangelogAddress("MCD_FLOP"); }
    function osmMom()     internal view returns (address) { return getChangelogAddress("OSM_MOM"); }
    function govGuard()   internal view returns (address) { return getChangelogAddress("GOV_GUARD"); }
    function flipperMom() internal view returns (address) { return getChangelogAddress("FLIPPER_MOM"); }
    function autoLine()   internal view returns (address) { return getChangelogAddress("MCD_IAM_AUTO_LINE"); }

    function flip(bytes32 ilk) internal view returns (address) {
        (,,,, address _flip,,,) = RegistryLike(reg()).ilkData(ilk);
        return _flip;
    }

    function getChangelogAddress(bytes32 key) internal view returns (address) {
        return ChainlogLike(LOG).getAddress(key);
    }


    /****************************/
    /*** Changelog Management ***/
    /****************************/
    function setChangelogAddress(bytes32 key, address value) internal {
        DssExecLib.setChangelogAddress(LOG, key, value);
    }

    function setChangelogVersion(string memory version) internal {
        DssExecLib.setChangelogVersion(LOG, version);
    }

    function setChangelogIPFS(string memory ipfs) internal {
        DssExecLib.setChangelogIPFS(LOG, ipfs);
    }

    function setChangelogSHA256(string memory SHA256) internal {
        DssExecLib.setChangelogSHA256(LOG, SHA256);
    }

    /**********************/
    /*** Authorizations ***/
    /**********************/
    function authorize(address base, address ward) internal virtual {
        DssExecLib.authorize(base, ward);
    }

    function deauthorize(address base, address ward) internal {
        DssExecLib.deauthorize(base, ward);
    }

    /**************************/
    /*** Accumulating Rates ***/
    /**************************/
    function accumulateDSR() internal {
        DssExecLib.accumulateDSR(pot());
    }

    function accumulateCollateralStabilityFees(bytes32 ilk) internal {
        DssExecLib.accumulateCollateralStabilityFees(jug(), ilk);
    }

    /*********************/
    /*** Price Updates ***/
    /*********************/
    function updateCollateralPrice(bytes32 ilk) internal {
        DssExecLib.updateCollateralPrice(spot(), ilk);
    }

    /****************************/
    /*** System Configuration ***/
    /****************************/
    function setContract(address base, bytes32 what, address addr) internal {
        DssExecLib.setContract(base, what, addr);
    }

    function setContract(address base, bytes32 ilk, bytes32 what, address addr) internal {
        DssExecLib.setContract(base, ilk, what, addr);
    }

    /******************************/
    /*** System Risk Parameters ***/
    /******************************/
    function setGlobalDebtCeiling(uint256 amount) internal {
        DssExecLib.setGlobalDebtCeiling(vat(), amount);
    }

    function increaseGlobalDebtCeiling(uint256 amount) internal {
        DssExecLib.increaseGlobalDebtCeiling(vat(), amount);
    }

    function decreaseGlobalDebtCeiling(uint256 amount) internal {
        DssExecLib.decreaseGlobalDebtCeiling(vat(), amount);
    }

    function setDSR(uint256 rate) internal {
        DssExecLib.setDSR(pot(), rate);
    }

    function setSurplusAuctionAmount(uint256 amount) internal {
        DssExecLib.setSurplusAuctionAmount(vow(), amount);
    }

    function setSurplusBuffer(uint256 amount) internal {
        DssExecLib.setSurplusBuffer(vow(), amount);
    }

    function setMinSurplusAuctionBidIncrease(uint256 pct_bps) internal {
        DssExecLib.setMinSurplusAuctionBidIncrease(flap(), pct_bps);
    }

    function setSurplusAuctionBidDuration(uint256 duration) internal {
        DssExecLib.setSurplusAuctionBidDuration(flap(), duration);
    }

    function setSurplusAuctionDuration(uint256 duration) internal {
        DssExecLib.setSurplusAuctionDuration(flap(), duration);
    }

    function setDebtAuctionDelay(uint256 duration) internal {
        DssExecLib.setDebtAuctionDelay(vow(), duration);
    }

    function setDebtAuctionDAIAmount(uint256 amount) internal {
        DssExecLib.setDebtAuctionDAIAmount(vow(), amount);
    }

    function setDebtAuctionMKRAmount(uint256 amount) internal {
        DssExecLib.setDebtAuctionMKRAmount(vow(), amount);
    }

    function setMinDebtAuctionBidIncrease(uint256 pct_bps) internal {
        DssExecLib.setMinDebtAuctionBidIncrease(flop(), pct_bps);
    }

    function setDebtAuctionBidDuration(uint256 duration) internal {
        DssExecLib.setDebtAuctionBidDuration(flop(), duration);
    }

    function setDebtAuctionDuration(uint256 duration) internal {
        DssExecLib.setDebtAuctionDuration(flop(), duration);
    }

    function setDebtAuctionMKRIncreaseRate(uint256 pct_bps) internal {
        DssExecLib.setDebtAuctionMKRIncreaseRate(flop(), pct_bps);
    }

    function setMaxTotalDAILiquidationAmount(uint256 amount) internal {
        DssExecLib.setMaxTotalDAILiquidationAmount(cat(), amount);
    }

    function setEmergencyShutdownProcessingTime(uint256 duration) internal {
        DssExecLib.setEmergencyShutdownProcessingTime(end(), duration);
    }

    function setGlobalStabilityFee(uint256 rate) internal {
        DssExecLib.setGlobalStabilityFee(jug(), rate);
    }

    function setDAIReferenceValue(uint256 value) internal {
        DssExecLib.setDAIReferenceValue(spot(), value);
    }

    /*****************************/
    /*** Collateral Management ***/
    /*****************************/
    function setIlkDebtCeiling(bytes32 ilk, uint256 amount) internal {
        DssExecLib.setIlkDebtCeiling(vat(), ilk, amount);
    }

    function increaseIlkDebtCeiling(bytes32 ilk, uint256 amount, bool global) internal {
        DssExecLib.increaseIlkDebtCeiling(vat(), ilk, amount, global);
    }

    function increaseIlkDebtCeiling(bytes32 ilk, uint256 amount) internal {
        DssExecLib.increaseIlkDebtCeiling(vat(), ilk, amount, true);
    }

    function decreaseIlkDebtCeiling(bytes32 ilk, uint256 amount, bool global) internal {
        DssExecLib.decreaseIlkDebtCeiling(vat(), ilk, amount, global);
    }

    function decreaseIlkDebtCeiling(bytes32 ilk, uint256 amount) internal {
        DssExecLib.decreaseIlkDebtCeiling(vat(), ilk, amount, true);
    }

    function setIlkAutoLineParameters(bytes32 ilk, uint256 amount, uint256 gap, uint256 ttl) internal {
        DssExecLib.setIlkAutoLineParameters(autoLine(), ilk, amount, gap, ttl);
    }

    function setIlkAutoLineDebtCeiling(bytes32 ilk, uint256 amount) internal {
        DssExecLib.setIlkAutoLineDebtCeiling(autoLine(), ilk, amount);
    }

    function removeIlkFromAutoLine(bytes32 ilk) internal {
        DssExecLib.removeIlkFromAutoLine(autoLine(), ilk);
    }

    function setIlkMinVaultAmount(bytes32 ilk, uint256 amount) internal {
        DssExecLib.setIlkMinVaultAmount(vat(), ilk, amount);
    }

    function setIlkLiquidationPenalty(bytes32 ilk, uint256 pct_bps) internal {
        DssExecLib.setIlkLiquidationPenalty(cat(), ilk, pct_bps);
    }

    function setIlkMaxLiquidationAmount(bytes32 ilk, uint256 amount) internal {
        DssExecLib.setIlkMaxLiquidationAmount(cat(), ilk, amount);
    }

    function setIlkLiquidationRatio(bytes32 ilk, uint256 pct_bps) internal {
        DssExecLib.setIlkLiquidationRatio(spot(), ilk, pct_bps);
    }

    function setIlkMinAuctionBidIncrease(bytes32 ilk, uint256 pct_bps) internal {
        DssExecLib.setIlkMinAuctionBidIncrease(flip(ilk), pct_bps);
    }

    function setIlkBidDuration(bytes32 ilk, uint256 duration) internal {
        DssExecLib.setIlkBidDuration(flip(ilk), duration);
    }

    function setIlkAuctionDuration(bytes32 ilk, uint256 duration) internal {
        DssExecLib.setIlkAuctionDuration(flip(ilk), duration);
    }

    function setIlkStabilityFee(bytes32 ilk, uint256 rate, bool doDrip) internal {
        DssExecLib.setIlkStabilityFee(jug(), ilk, rate, doDrip);
    }

    function setIlkStabilityFee(bytes32 ilk, uint256 rate) internal {
        DssExecLib.setIlkStabilityFee(jug(), ilk, rate, true);
    }

    /***********************/
    /*** Core Management ***/
    /***********************/
    function updateCollateralAuctionContract(bytes32 ilk, address newFlip, address oldFlip) internal {
        DssExecLib.updateCollateralAuctionContract(vat(), cat(), end(), flipperMom(), ilk, newFlip, oldFlip);
    }

    function updateSurplusAuctionContract(address newFlap, address oldFlap) internal {
        DssExecLib.updateSurplusAuctionContract(vat(), vow(), newFlap, oldFlap);
    }

    function updateDebtAuctionContract(address newFlop, address oldFlop) internal {
        DssExecLib.updateDebtAuctionContract(vat(), vow(), govGuard(), newFlop, oldFlop);
    }

    /*************************/
    /*** Oracle Management ***/
    /*************************/
    function addWritersToMedianWhitelist(address medianizer, address[] memory feeds) internal {
        DssExecLib.addWritersToMedianWhitelist(medianizer, feeds);
    }

    function removeWritersFromMedianWhitelist(address medianizer, address[] memory feeds) internal {
        DssExecLib.removeWritersFromMedianWhitelist(medianizer, feeds);
    }

    function addReadersToMedianWhitelist(address medianizer, address[] memory readers) internal {
        DssExecLib.addReadersToMedianWhitelist(medianizer, readers);
    }

    function addReaderToMedianWhitelist(address medianizer, address reader) internal {
        DssExecLib.addReaderToMedianWhitelist(medianizer, reader);
    }

    function removeReadersFromMedianWhitelist(address medianizer, address[] memory readers) internal {
        DssExecLib.removeReadersFromMedianWhitelist(medianizer, readers);
    }

    function removeReaderFromMedianWhitelist(address medianizer, address reader) internal {
        DssExecLib.removeReaderFromMedianWhitelist(medianizer, reader);
    }

    function setMedianWritersQuorum(address medianizer, uint256 minQuorum) internal {
        DssExecLib.setMedianWritersQuorum(medianizer, minQuorum);
    }

    function addReaderToOSMWhitelist(address osm, address reader) internal {
        DssExecLib.addReaderToOSMWhitelist(osm, reader);
    }

    function removeReaderFromOSMWhitelist(address osm, address reader) internal {
        DssExecLib.removeReaderFromOSMWhitelist(osm, reader);
    }

    function allowOSMFreeze(address osm, bytes32 ilk) internal {
        DssExecLib.allowOSMFreeze(osmMom(), osm, ilk);
    }

    /*****************************/
    /*** Collateral Onboarding ***/
    /*****************************/

    // Minimum actions to onboard a collateral to the system with 0 line.
    function addCollateralBase(bytes32 ilk, address gem, address join, address flipper, address pip) internal {
        DssExecLib.addCollateralBase(vat(), cat(), jug(), end(), spot(), reg(), ilk, gem, join, flipper, pip);
    }

    // Complete collateral onboarding logic.
    function addNewCollateral(CollateralOpts memory co) internal {
        // Add the collateral to the system.
        addCollateralBase(co.ilk, co.gem, co.join, co.flip, co.pip);

        // Allow FlipperMom to access to the ilk Flipper
        authorize(co.flip, flipperMom());
        // Disallow Cat to kick auctions in ilk Flipper
        if(!co.isLiquidatable) deauthorize(flipperMom(), co.flip);

        if(co.isOSM) { // If pip == OSM
            // Allow OsmMom to access to the TOKEN OSM
            authorize(co.pip, osmMom());
            if (co.whitelistOSM) { // If median is src in OSM
                // Whitelist OSM to read the Median data (only necessary if it is the first time the token is being added to an ilk)
                addReaderToMedianWhitelist(address(OracleLike(co.pip).src()), co.pip);
            }
            // Whitelist Spotter to read the OSM data (only necessary if it is the first time the token is being added to an ilk)
            addReaderToOSMWhitelist(co.pip, spot());
            // Whitelist End to read the OSM data (only necessary if it is the first time the token is being added to an ilk)
            addReaderToOSMWhitelist(co.pip, end());
            // Set TOKEN OSM in the OsmMom for new ilk
            allowOSMFreeze(co.pip, co.ilk);
        }
        // Increase the global debt ceiling by the ilk ceiling
        increaseGlobalDebtCeiling(co.ilkDebtCeiling);
        // Set the ilk debt ceiling
        setIlkDebtCeiling(co.ilk, co.ilkDebtCeiling);
        // Set the ilk dust
        setIlkMinVaultAmount(co.ilk, co.minVaultAmount);
        // Set the dunk size
        setIlkMaxLiquidationAmount(co.ilk, co.maxLiquidationAmount);
        // Set the ilk liquidation penalty
        setIlkLiquidationPenalty(co.ilk, co.liquidationPenalty);

        // Set the ilk stability fee
        setIlkStabilityFee(co.ilk, co.ilkStabilityFee);

        // Set the ilk percentage between bids
        setIlkMinAuctionBidIncrease(co.ilk, co.bidIncrease);
        // Set the ilk time max time between bids
        setIlkBidDuration(co.ilk, co.bidDuration);
        // Set the ilk max auction duration
        setIlkAuctionDuration(co.ilk, co.auctionDuration);
        // Set the ilk min collateralization ratio
        setIlkLiquidationRatio(co.ilk, co.liquidationRatio);

        // Update ilk spot value in Vat
        updateCollateralPrice(co.ilk);
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

/* pragma solidity ^0.6.11; */

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

////// src/DssSpell.sol
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
/* pragma solidity 0.6.11; */

/* import "dss-exec-lib/DssExec.sol"; */
/* import "dss-exec-lib/DssAction.sol"; */
/* import "lib/dss-interfaces/src/dss/VatAbstract.sol"; */
/* import "lib/dss-interfaces/src/dss/DaiJoinAbstract.sol"; */
/* import "lib/dss-interfaces/src/dss/DaiAbstract.sol"; */

interface ChainlogAbstract_2 {
    function removeAddress(bytes32) external;
}

interface LPOracle {
    function orb0() external view returns (address);
    function orb1() external view returns (address);
}

interface GnosisAllowanceModule {
    function executeAllowanceTransfer(address safe, address token, address to, uint96 amount, address paymentToken, uint96 payment, address delegate, bytes memory signature) external;
}

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/9b7eba966a6f43e95935276313cac2490ec44e71/governance/votes/Executive%20vote%20-%20February%2012%2C%202021.md -q -O - 2>/dev/null)"
    string public constant description =
        "2021-02-12 MakerDAO Executive Spell | Hash: 0x82215e761ec28f92aa02ac1c3533a9315a9accc2847b9dac99ae2aa65d9a9b27";


    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //
    uint256 constant TWO_PCT            = 1000000000627937192491029810;
    uint256 constant TWO_PT_FIVE_PCT    = 1000000000782997609082909351;
    uint256 constant THREE_PCT          = 1000000000937303470807876289;
    uint256 constant THREE_PT_FIVE_PCT  = 1000000001090862085746321732;
    uint256 constant FOUR_PCT           = 1000000001243680656318820312;
    uint256 constant FOUR_PT_FIVE_PCT   = 1000000001395766281313196627;
    uint256 constant FIVE_PT_FIVE_PCT   = 1000000001697766583380253701;
    uint256 constant SIX_PCT            = 1000000001847694957439350562;
    uint256 constant SEVEN_PT_FIVE_PCT  = 1000000002293273137447730714;

    /**
        @dev constructor (required)
        @param officeHours true if officehours enabled
    */
    constructor(bool officeHours) public DssAction(officeHours) {}

    uint256 constant WAD        = 10**18;
    uint256 constant RAD        = 10**45;
    uint256 constant MILLION    = 10**6;

    bytes32 constant ETH_A_ILK          = "ETH-A";
    bytes32 constant ETH_B_ILK          = "ETH-B";
    bytes32 constant UNI_ILK            = "UNI-A";
    bytes32 constant AAVE_ILK           = "AAVE-A";
    bytes32 constant COMP_ILK           = "COMP-A";
    bytes32 constant LINK_ILK           = "LINK-A";
    bytes32 constant WBTC_ILK           = "WBTC-A";
    bytes32 constant YFI_ILK            = "YFI-A";
    bytes32 constant BAL_ILK            = "BAL-A";
    bytes32 constant BAT_ILK            = "BAT-A";
    bytes32 constant UNIV2DAIETH_ILK    = "UNIV2DAIETH-A";
    bytes32 constant UNIV2USDCETH_ILK   = "UNIV2USDCETH-A";
    bytes32 constant UNIV2WBTCETH_ILK   = "UNIV2WBTCETH-A";

    bytes32 constant UNIV2LINKETH_ILK   = "UNIV2LINKETH-A";
    address constant UNIV2LINKETH_GEM   = 0xa2107FA5B38d9bbd2C461D6EDf11B11A50F6b974;
    address constant UNIV2LINKETH_JOIN  = 0xDae88bDe1FB38cF39B6A02b595930A3449e593A6;
    address constant UNIV2LINKETH_FLIP  = 0xb79f818E3c73FCA387845f892356224CA75eac4b;
    address constant UNIV2LINKETH_PIP   = 0x628009F5F5029544AE84636Ef676D3Cc5755238b;

    bytes32 constant UNIV2UNIETH_ILK    = "UNIV2UNIETH-A";
    address constant UNIV2UNIETH_GEM    = 0xd3d2E2692501A5c9Ca623199D38826e513033a17;
    address constant UNIV2UNIETH_JOIN   = 0xf11a98339FE1CdE648e8D1463310CE3ccC3d7cC1;
    address constant UNIV2UNIETH_FLIP   = 0xe5ED7da0483e291485011D5372F3BF46235EB277;
    address constant UNIV2UNIETH_PIP    = 0x8Ce9E9442F2791FC63CD6394cC12F2dE4fbc1D71;

    // Interim Budget Addresses
    address constant DAO_MULTISIG       = 0x73f09254a81e1F835Ee442d1b3262c1f1d7A13ff;
    address constant ALLOWANCE_MODULE   = 0xCFbFaC74C26F8647cBDb8c5caf80BB5b32E43134;

    function actions() public override {
        // DC-IAM
        setIlkAutoLineParameters(UNI_ILK, 50 * MILLION, 3 * MILLION, 12 hours);
        setIlkAutoLineParameters(AAVE_ILK, 25 * MILLION, 2 * MILLION, 12 hours);
        setIlkAutoLineParameters(COMP_ILK, 10 * MILLION, 2 * MILLION, 12 hours);
        setIlkAutoLineParameters(LINK_ILK, 140 * MILLION, 7 * MILLION, 12 hours);
        setIlkAutoLineParameters(WBTC_ILK, 350 * MILLION, 15 * MILLION, 12 hours);
        setIlkAutoLineParameters(YFI_ILK, 45 * MILLION, 5 * MILLION, 12 hours);

        // add UNI-V2-LINK-ETH-A collateral type
        addReaderToMedianWhitelist(
            LPOracle(UNIV2LINKETH_PIP).orb0(),
            UNIV2LINKETH_PIP
        );
        addReaderToMedianWhitelist(
            LPOracle(UNIV2LINKETH_PIP).orb1(),
            UNIV2LINKETH_PIP
        );
        CollateralOpts memory UNIV2LINKETH_A = CollateralOpts({
            ilk: UNIV2LINKETH_ILK,
            gem: UNIV2LINKETH_GEM,
            join: UNIV2LINKETH_JOIN,
            flip: UNIV2LINKETH_FLIP,
            pip: UNIV2LINKETH_PIP,
            isLiquidatable: true,
            isOSM: true,
            whitelistOSM: false,
            ilkDebtCeiling: 3 * MILLION, // initially 3 million
            minVaultAmount: 2000,
            maxLiquidationAmount: 50000,
            liquidationPenalty: 1300,
            ilkStabilityFee: FOUR_PCT, // 4%
            bidIncrease: 300, // 3%
            bidDuration: 6 hours,
            auctionDuration: 6 hours,
            liquidationRatio: 16500 // 165%
        });
        addNewCollateral(UNIV2LINKETH_A);

        // add UNI-V2-ETH-USDT-A collateral type
        addReaderToMedianWhitelist(
            LPOracle(UNIV2UNIETH_PIP).orb0(),
            UNIV2UNIETH_PIP
        );
        addReaderToMedianWhitelist(
            LPOracle(UNIV2UNIETH_PIP).orb1(),
            UNIV2UNIETH_PIP
        );
        CollateralOpts memory UNIV2UNIETH_A = CollateralOpts({
            ilk: UNIV2UNIETH_ILK,
            gem: UNIV2UNIETH_GEM,
            join: UNIV2UNIETH_JOIN,
            flip: UNIV2UNIETH_FLIP,
            pip: UNIV2UNIETH_PIP,
            isLiquidatable: true,
            isOSM: true,
            whitelistOSM: false,
            ilkDebtCeiling: 3 * MILLION, // initially 3 million
            minVaultAmount: 2000,
            maxLiquidationAmount: 50000,
            liquidationPenalty: 1300,
            ilkStabilityFee: FOUR_PCT, // 4%
            bidIncrease: 300, // 3%
            bidDuration: 6 hours,
            auctionDuration: 6 hours,
            liquidationRatio: 16500 // 165%
        });
        addNewCollateral(UNIV2UNIETH_A);

        // Rates changes
        setIlkStabilityFee(ETH_A_ILK, FOUR_PT_FIVE_PCT, true);
        setIlkStabilityFee(ETH_B_ILK, SEVEN_PT_FIVE_PCT, true);
        setIlkStabilityFee(WBTC_ILK, FOUR_PT_FIVE_PCT, true);
        setIlkStabilityFee(LINK_ILK, THREE_PT_FIVE_PCT, true);
        setIlkStabilityFee(COMP_ILK, THREE_PCT, true);
        setIlkStabilityFee(BAL_ILK, THREE_PT_FIVE_PCT, true);
        setIlkStabilityFee(UNIV2DAIETH_ILK, TWO_PCT, true);
        setIlkStabilityFee(UNIV2USDCETH_ILK, TWO_PT_FIVE_PCT, true);
        setIlkStabilityFee(UNIV2WBTCETH_ILK, THREE_PT_FIVE_PCT, true);
        setIlkStabilityFee(BAT_ILK, SIX_PCT, true);
        setIlkStabilityFee(YFI_ILK, FIVE_PT_FIVE_PCT, true);

        // Interim DAO Budget (Note: we are leaving daiJoin hope'd from the Pause Proxy for future payments)
        // Sending 100,001 DAI to the DAO multi-sig (1 extra to test retrieval)
        address MCD_JOIN_DAI    = getChangelogAddress("MCD_JOIN_DAI");
        address MCD_DAI         = getChangelogAddress("MCD_DAI");
        address MCD_PAUSE_PROXY = getChangelogAddress("MCD_PAUSE_PROXY");
        VatAbstract(vat()).suck(vow(), address(this), 100_001 * RAD);
        VatAbstract(vat()).hope(MCD_JOIN_DAI);
        DaiJoinAbstract(MCD_JOIN_DAI).exit(DAO_MULTISIG, 100_001 * WAD);
        // Testing the ability for governance to retrieve funds from the multi-sig
        GnosisAllowanceModule(ALLOWANCE_MODULE).executeAllowanceTransfer(
            DAO_MULTISIG,
            MCD_DAI,
            MCD_PAUSE_PROXY,
            uint96(1 * WAD),
            address(0),
            uint96(0),
            address(this),
            ""
        );
        DaiAbstract(MCD_DAI).approve(MCD_JOIN_DAI, 1 * WAD);
        DaiJoinAbstract(MCD_JOIN_DAI).join(vow(), 1 * WAD);

        // add UNIV2LINKETH to Changelog
        setChangelogAddress("UNIV2LINKETH",             UNIV2LINKETH_GEM);
        setChangelogAddress("MCD_JOIN_UNIV2LINKETH_A",  UNIV2LINKETH_JOIN);
        setChangelogAddress("MCD_FLIP_UNIV2LINKETH_A",  UNIV2LINKETH_FLIP);
        setChangelogAddress("PIP_UNIV2LINKETH",         UNIV2LINKETH_PIP);

        // add UNIV2UNIETH to Changelog
        setChangelogAddress("UNIV2UNIETH",             UNIV2UNIETH_GEM);
        setChangelogAddress("MCD_JOIN_UNIV2UNIETH_A",  UNIV2UNIETH_JOIN);
        setChangelogAddress("MCD_FLIP_UNIV2UNIETH_A",  UNIV2UNIETH_FLIP);
        setChangelogAddress("PIP_UNIV2UNIETH",         UNIV2UNIETH_PIP);

        // bump Changelog version
        setChangelogVersion("1.2.6");
    }
}

contract DssSpell is DssExec {
    DssSpellAction public spell = new DssSpellAction(true);
    constructor() DssExec(spell.description(), now + 30 days, address(spell)) public {}
}