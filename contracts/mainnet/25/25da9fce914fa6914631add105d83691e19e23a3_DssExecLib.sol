/**
 *Submitted for verification at Etherscan.io on 2021-02-11
*/

// hevm: flattened sources of src/DssExecLib.sol
pragma solidity >=0.6.11 <0.7.0;

////// src/MathLib.sol
// SPDX-License-Identifier: AGPL-3.0-or-later
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

////// src/DssExecLib.sol
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

interface JoinLike_2 {
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
        require(JoinLike_2(_join).vat() == _vat);     // "join-vat-not-match"
        require(JoinLike_2(_join).ilk() == _ilk);     // "join-ilk-not-match"
        require(JoinLike_2(_join).gem() == _gem);     // "join-gem-not-match"
        require(JoinLike_2(_join).dec() ==
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