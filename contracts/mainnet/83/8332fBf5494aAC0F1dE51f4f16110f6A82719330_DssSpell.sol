/**
 *Submitted for verification at Etherscan.io on 2021-03-05
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
pragma solidity 0.6.11;

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

library DssExecLib {
    function vat()        public view returns (address) {}
    function jug()        public view returns (address) {}
    function spotter()    public view returns (address) {}
    function getChangelogAddress(bytes32) public view returns (address) {}
    function setChangelogAddress(bytes32, address) public {}
    function setChangelogVersion(string memory) public {}
    function authorize(address, address) public {}
    function updateCollateralPrice(bytes32) public {}
    function setContract(address, bytes32, bytes32, address) public {}
    function increaseGlobalDebtCeiling(uint256) public {}
    function setMaxTotalDAILiquidationAmount(uint256) public {}
    function setIlkDebtCeiling(bytes32, uint256) public {}
    function setIlkAutoLineParameters(bytes32, uint256, uint256, uint256) public {}
    function setIlkMinVaultAmount(bytes32, uint256) public {}
    function setIlkLiquidationRatio(bytes32, uint256) public {}
    function setIlkMinAuctionBidIncrease(bytes32, uint256) public {}
    function setIlkBidDuration(bytes32, uint256) public {}
    function setIlkAuctionDuration(bytes32, uint256) public {}
    function setIlkStabilityFee(bytes32, uint256, bool) public {}
}

interface OracleLike {
    function src() external view returns (address);
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

interface GemJoinAbstract {
    function vat() external view returns (address);
    function ilk() external view returns (bytes32);
    function gem() external view returns (address);
    function dec() external view returns (uint256);
}

interface DSTokenAbstract {
    function decimals() external view returns (uint256);
}

interface Initializable {
    function init(bytes32) external;
}

interface Hopeable {
    function hope(address) external;
}

interface Kissable {
    function kiss(address) external;
}

interface RwaLiquidationLike {
    function ilks(bytes32) external returns (bytes32,address,uint48,uint48);
    function init(bytes32, uint256, string calldata, uint48) external;
}

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/5925c52da6f8d485447228ca5acd435997522de6/governance/votes/Executive%20vote%20-%20March%205%2C%202021.md -q -O - 2>/dev/null)"
    string public constant description =
        "2021-03-05 MakerDAO Executive Spell | Hash: 0xb9829a5159cc2270de0592c8fcb9f7cbcc79491e26ad7ded78afb7994227f18b";


    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW
    //
    uint256 constant THREE_PCT_RATE  = 1000000000937303470807876289;

    uint256 constant MILLION    = 10**6;
    uint256 constant WAD        = 10**18;
    uint256 constant RAD        = 10**45;

    address constant RWA001_OPERATOR           = 0x7709f0840097170E5cB1F8c890AcB8601d73b35f;
    address constant RWA001_GEM                = 0x10b2aA5D77Aa6484886d8e244f0686aB319a270d;
    address constant MCD_JOIN_RWA001_A         = 0x476b81c12Dc71EDfad1F64B9E07CaA60F4b156E2;
    address constant RWA001_A_URN              = 0xa3342059BcDcFA57a13b12a35eD4BBE59B873005;
    address constant RWA001_A_INPUT_CONDUIT    = 0x486C85e2bb9801d14f6A8fdb78F5108a0fd932f2;
    address constant RWA001_A_OUTPUT_CONDUIT   = 0xb3eFb912e1cbC0B26FC17388Dd433Cecd2206C3d;
    address constant MIP21_LIQUIDATION_ORACLE  = 0x88f88Bb9E66241B73B84f3A6E197FbBa487b1E30;
    address constant SC_DOMAIN_DEPLOYER_07     = 0xDA0FaB0700A4389F6E6679aBAb1692B4601ce9bf;

    function actions() public override {

        // Increase ETH-A target available debt (gap) from 30M to 80M
        DssExecLib.setIlkAutoLineParameters("ETH-A", 2_500 * MILLION, 80 * MILLION, 12 hours);

        // Decrease the bid duration (ttl) and max auction duration (tau) from 6 to 4 hours to all the ilks with liquidation on
        DssExecLib.setIlkBidDuration("ETH-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("ETH-A", 4 hours);
        DssExecLib.setIlkBidDuration("ETH-B", 4 hours);
        DssExecLib.setIlkAuctionDuration("ETH-B", 4 hours);
        DssExecLib.setIlkBidDuration("BAT-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("BAT-A", 4 hours);
        DssExecLib.setIlkBidDuration("WBTC-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("WBTC-A", 4 hours);
        DssExecLib.setIlkBidDuration("KNC-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("KNC-A", 4 hours);
        DssExecLib.setIlkBidDuration("ZRX-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("ZRX-A", 4 hours);
        DssExecLib.setIlkBidDuration("MANA-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("MANA-A", 4 hours);
        DssExecLib.setIlkBidDuration("USDT-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("USDT-A", 4 hours);
        DssExecLib.setIlkBidDuration("COMP-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("COMP-A", 4 hours);
        DssExecLib.setIlkBidDuration("LRC-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("LRC-A", 4 hours);
        DssExecLib.setIlkBidDuration("LINK-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("LINK-A", 4 hours);
        DssExecLib.setIlkBidDuration("BAL-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("BAL-A", 4 hours);
        DssExecLib.setIlkBidDuration("YFI-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("YFI-A", 4 hours);
        DssExecLib.setIlkBidDuration("UNI-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("UNI-A", 4 hours);
        DssExecLib.setIlkBidDuration("RENBTC-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("RENBTC-A", 4 hours);
        DssExecLib.setIlkBidDuration("AAVE-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("AAVE-A", 4 hours);
        DssExecLib.setIlkBidDuration("UNIV2DAIETH-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("UNIV2DAIETH-A", 4 hours);
        DssExecLib.setIlkBidDuration("UNIV2WBTCETH-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("UNIV2WBTCETH-A", 4 hours);
        DssExecLib.setIlkBidDuration("UNIV2USDCETH-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("UNIV2USDCETH-A", 4 hours);
        DssExecLib.setIlkBidDuration("UNIV2ETHUSDT-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("UNIV2ETHUSDT-A", 4 hours);
        DssExecLib.setIlkBidDuration("UNIV2LINKETH-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("UNIV2LINKETH-A", 4 hours);
        DssExecLib.setIlkBidDuration("UNIV2UNIETH-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("UNIV2UNIETH-A", 4 hours);
        DssExecLib.setIlkBidDuration("UNIV2WBTCDAI-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("UNIV2WBTCDAI-A", 4 hours);
        DssExecLib.setIlkBidDuration("UNIV2AAVEETH-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("UNIV2AAVEETH-A", 4 hours);
        DssExecLib.setIlkBidDuration("UNIV2DAIUSDT-A", 4 hours);
        DssExecLib.setIlkAuctionDuration("UNIV2DAIUSDT-A", 4 hours);

        // Increase the box parameter from 15M to 20M
        DssExecLib.setMaxTotalDAILiquidationAmount(20 * MILLION);

        // Increase the minimum bid increment (beg) from 3% to 5% for the following collaterals
        DssExecLib.setIlkMinAuctionBidIncrease("ETH-B", 500);
        DssExecLib.setIlkMinAuctionBidIncrease("UNIV2USDCETH-A", 500);
        DssExecLib.setIlkMinAuctionBidIncrease("UNIV2WBTCETH-A", 500);
        DssExecLib.setIlkMinAuctionBidIncrease("UNIV2DAIETH-A", 500);
        DssExecLib.setIlkMinAuctionBidIncrease("UNIV2UNIETH-A", 500);
        DssExecLib.setIlkMinAuctionBidIncrease("UNIV2ETHUSDT-A", 500);
        DssExecLib.setIlkMinAuctionBidIncrease("UNIV2LINKETH-A", 500);
        DssExecLib.setIlkMinAuctionBidIncrease("UNIV2WBTCDAI-A", 500);
        DssExecLib.setIlkMinAuctionBidIncrease("UNIV2AAVEETH-A", 500);
        DssExecLib.setIlkMinAuctionBidIncrease("UNIV2DAIUSDT-A", 500);

        // RWA001-A collateral deploy
        bytes32 ilk = "RWA001-A";

        address vat = DssExecLib.vat();

        // Sanity checks
        require(GemJoinAbstract(MCD_JOIN_RWA001_A).vat() == vat, "join-vat-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA001_A).ilk() == ilk, "join-ilk-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA001_A).gem() == RWA001_GEM, "join-gem-not-match");
        require(GemJoinAbstract(MCD_JOIN_RWA001_A).dec() == DSTokenAbstract(RWA001_GEM).decimals(), "join-dec-not-match");

        // init the RwaLiquidationOracle
        // Oracle initial price: 1060
        // doc: "https://ipfs.io/ipfs/QmdmAUTU3sd9VkdfTZNQM6krc9jsKgF2pz7W1qvvfJo1xk"
        //   MIP13c3-SP4 Declaration of Intent & Commercial Points -
        //   Off-Chain Asset Backed Lender to onboard Real World Assets
        //   as Collateral for a DAI loan
        // tau: 30 days
        RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).init(
            ilk, 1060 * WAD, "QmdmAUTU3sd9VkdfTZNQM6krc9jsKgF2pz7W1qvvfJo1xk", 30 days
        );
        (,address pip,,) = RwaLiquidationLike(MIP21_LIQUIDATION_ORACLE).ilks(ilk);

        // Set price feed for RWA001
        DssExecLib.setContract(DssExecLib.spotter(), ilk, "pip", pip);

        // Init RWA-001 in Vat
        Initializable(vat).init(ilk);
        // Init RWA-001 in Jug
        Initializable(DssExecLib.jug()).init(ilk);

        // Allow RWA-001 Join to modify Vat registry
        DssExecLib.authorize(vat, MCD_JOIN_RWA001_A);

        // Allow RwaLiquidationOracle to modify Vat registry
        DssExecLib.authorize(vat, MIP21_LIQUIDATION_ORACLE);

        // Increase the global debt ceiling by the ilk ceiling
        DssExecLib.increaseGlobalDebtCeiling(1_000);
        // Set the ilk debt ceiling
        DssExecLib.setIlkDebtCeiling(ilk, 1_000);

        // No dust
        // DssExecLib.setIlkMinVaultAmount(ilk, 0);

        // 3% stability fee
        DssExecLib.setIlkStabilityFee(ilk, THREE_PCT_RATE, false);

        // collateralization ratio 100%
        DssExecLib.setIlkLiquidationRatio(ilk, 10_000);

        // poke the spotter to pull in a price
        DssExecLib.updateCollateralPrice(ilk);

        // give the urn permissions on the join adapter
        DssExecLib.authorize(MCD_JOIN_RWA001_A, RWA001_A_URN);

        // set up the urn
        Hopeable(RWA001_A_URN).hope(RWA001_OPERATOR);

        // set up output conduit
        Hopeable(RWA001_A_OUTPUT_CONDUIT).hope(RWA001_OPERATOR);

        // Authorize the SC Domain team deployer address on the output conduit during introductory phase.
        //  This allows the SC team to assist in the testing of a complete circuit.
        //  Once a broker dealer arrangement is established the deployer address should be `deny`ed on the conduit.
        Kissable(RWA001_A_OUTPUT_CONDUIT).kiss(SC_DOMAIN_DEPLOYER_07);

        // add RWA-001 contract to the changelog
        DssExecLib.setChangelogAddress("RWA001", RWA001_GEM);
        DssExecLib.setChangelogAddress("PIP_RWA001", pip);
        DssExecLib.setChangelogAddress("MCD_JOIN_RWA001_A", MCD_JOIN_RWA001_A);
        DssExecLib.setChangelogAddress("MIP21_LIQUIDATION_ORACLE", MIP21_LIQUIDATION_ORACLE);
        DssExecLib.setChangelogAddress("RWA001_A_URN", RWA001_A_URN);
        DssExecLib.setChangelogAddress("RWA001_A_INPUT_CONDUIT", RWA001_A_INPUT_CONDUIT);
        DssExecLib.setChangelogAddress("RWA001_A_OUTPUT_CONDUIT", RWA001_A_OUTPUT_CONDUIT);

        // bump changelog version
        DssExecLib.setChangelogVersion("1.2.9");
    }
}

contract DssSpell is DssExec {
    DssSpellAction internal action_ = new DssSpellAction();
    constructor() DssExec(action_.description(), block.timestamp + 30 days, address(action_)) public {}
}