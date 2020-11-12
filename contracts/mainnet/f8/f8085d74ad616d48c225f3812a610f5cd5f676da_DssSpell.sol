// Copyright (C) 2020 Maker Ecosystem Growth Holdings, INC.
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

pragma solidity 0.5.12;

// https://github.com/dapphub/ds-pause
interface DSPauseAbstract {
    function delay() external view returns (uint256);
    function plot(address, bytes32, bytes calldata, uint256) external;
    function exec(address, bytes32, bytes calldata, uint256) external returns (bytes memory);
}

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

// https://github.com/makerdao/dss/blob/master/src/end.sol
interface EndAbstract {
    function file(bytes32, address) external;
    function file(bytes32, uint256) external;
}

// https://github.com/makerdao/dss/blob/master/src/flip.sol
interface FlipAbstract {
    function rely(address usr) external;
    function deny(address usr) external;
    function vat() external view returns (address);
    function cat() external view returns (address);
    function ilk() external view returns (bytes32);
    function beg() external view returns (uint256);
    function ttl() external view returns (uint48);
    function tau() external view returns (uint48);
    function file(bytes32, uint256) external;
}

// https://github.com/makerdao/flipper-mom/blob/master/src/FlipperMom.sol
interface FlipperMomAbstract {
    function setAuthority(address) external;
    function cat() external returns (address);
    function rely(address) external;
    function deny(address) external;
}

// https://github.com/makerdao/osm
interface OsmAbstract {
    function kiss(address) external;
}

// https://github.com/makerdao/dss/blob/master/src/vat.sol
interface VatAbstract {
    function rely(address) external;
    function deny(address) external;
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
}

// https://github.com/makerdao/dss/blob/master/src/vow.sol
interface VowAbstract {
    function rely(address usr) external;
    function deny(address usr) external;
}

contract SpellAction {

    // MAINNET ADDRESSES
    //
    // The contracts in this list should correspond to MCD core contracts, verify
    // against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/1.1.0/contracts.json

    address constant MCD_VAT             = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant MCD_VOW             = 0xA950524441892A31ebddF91d3cEEFa04Bf454466;
    address constant MCD_ADM             = 0x9eF05f7F6deB616fd37aC3c959a2dDD25A54E4F5;
    address constant MCD_END             = 0xaB14d3CE3F733CACB76eC2AbE7d2fcb00c99F3d5;
    address constant FLIPPER_MOM         = 0xc4bE7F74Ee3743bDEd8E0fA218ee5cf06397f472;
    address constant MCD_CAT             = 0xa5679C04fc3d9d8b0AaB1F0ab83555b301cA70Ea;
    address constant MCD_CAT_OLD         = 0x78F2c2AF65126834c51822F56Be0d7469D7A523E;

    address constant MCD_FLIP_ETH_A      = 0xF32836B9E1f47a0515c6Ec431592D5EbC276407f;
    address constant MCD_FLIP_ETH_A_OLD  = 0x0F398a2DaAa134621e4b687FCcfeE4CE47599Cc1;

    address constant MCD_FLIP_BAT_A      = 0xF7C569B2B271354179AaCC9fF1e42390983110BA;
    address constant MCD_FLIP_BAT_A_OLD  = 0x5EdF770FC81E7b8C2c89f71F30f211226a4d7495;

    address constant MCD_FLIP_USDC_A     = 0xbe359e53038E41a1ffA47DAE39645756C80e557a;
    address constant MCD_FLIP_USDC_A_OLD = 0x545521e0105C5698f75D6b3C3050CfCC62FB0C12;

    address constant MCD_FLIP_USDC_B     = 0x77282aD36aADAfC16bCA42c865c674F108c4a616;
    address constant MCD_FLIP_USDC_B_OLD = 0x6002d3B769D64A9909b0B26fC00361091786fe48;

    address constant MCD_FLIP_WBTC_A     = 0x58CD24ac7322890382eE45A3E4F903a5B22Ee930;
    address constant MCD_FLIP_WBTC_A_OLD = 0xF70590Fa4AaBe12d3613f5069D02B8702e058569;

    address constant MCD_FLIP_ZRX_A      = 0xa4341cAf9F9F098ecb20fb2CeE2a0b8C78A18118;
    address constant MCD_FLIP_ZRX_A_OLD  = 0x92645a34d07696395b6e5b8330b000D0436A9aAD;

    address constant MCD_FLIP_KNC_A      = 0x57B01F1B3C59e2C0bdfF3EC9563B71EEc99a3f2f;
    address constant MCD_FLIP_KNC_A_OLD  = 0xAD4a0B5F3c6Deb13ADE106Ba6E80Ca6566538eE6;

    address constant MCD_FLIP_TUSD_A     = 0x9E4b213C4defbce7564F2Ac20B6E3bF40954C440;
    address constant MCD_FLIP_TUSD_A_OLD = 0x04C42fAC3e29Fd27118609a5c36fD0b3Cb8090b3;

    address constant MCD_FLIP_MANA_A     = 0x0a1D75B4f49BA80724a214599574080CD6B68357;
    address constant MCD_FLIP_MANA_A_OLD = 0x4bf9D2EBC4c57B9B783C12D30076507660B58b3a;

    address constant YEARN               = 0xCF63089A8aD2a9D8BD6Bb8022f3190EB7e1eD0f1;
    address constant OSM_ETHUSD          = 0x81FE72B5A8d1A857d176C3E7d5Bd2679A9B85763;

    // Decimals & precision
    uint256 constant THOUSAND = 10 ** 3;
    uint256 constant MILLION  = 10 ** 6;
    uint256 constant WAD      = 10 ** 18;
    uint256 constant RAY      = 10 ** 27;
    uint256 constant RAD      = 10 ** 45;

    function execute() external {

        // ************************
        // *** Liquidations 1.2 ***
        // ************************

        require(CatAbstract(MCD_CAT_OLD).vat() == MCD_VAT,          "non-matching-vat");
        require(CatAbstract(MCD_CAT_OLD).vow() == MCD_VOW,          "non-matching-vow");

        require(CatAbstract(MCD_CAT).vat() == MCD_VAT,              "non-matching-vat");
        require(CatAbstract(MCD_CAT).live() == 1,                   "cat-not-live");

        require(FlipperMomAbstract(FLIPPER_MOM).cat() == MCD_CAT,   "non-matching-cat");

        /*** Update Cat ***/
        CatAbstract(MCD_CAT).file("vow", MCD_VOW);
        VatAbstract(MCD_VAT).rely(MCD_CAT);
        VatAbstract(MCD_VAT).deny(MCD_CAT_OLD);
        VowAbstract(MCD_VOW).rely(MCD_CAT);
        VowAbstract(MCD_VOW).deny(MCD_CAT_OLD);
        EndAbstract(MCD_END).file("cat", MCD_CAT);
        CatAbstract(MCD_CAT).rely(MCD_END);

        CatAbstract(MCD_CAT).file("box", 30 * MILLION * RAD);

        /*** Set Auth in Flipper Mom ***/
        FlipperMomAbstract(FLIPPER_MOM).setAuthority(MCD_ADM);

        /*** ETH-A Flip ***/
        _changeFlip(FlipAbstract(MCD_FLIP_ETH_A), FlipAbstract(MCD_FLIP_ETH_A_OLD));

        /*** BAT-A Flip ***/
        _changeFlip(FlipAbstract(MCD_FLIP_BAT_A), FlipAbstract(MCD_FLIP_BAT_A_OLD));

        /*** USDC-A Flip ***/
        _changeFlip(FlipAbstract(MCD_FLIP_USDC_A), FlipAbstract(MCD_FLIP_USDC_A_OLD));
        FlipperMomAbstract(FLIPPER_MOM).deny(MCD_FLIP_USDC_A); // Auctions disabled

        /*** USDC-B Flip ***/
        _changeFlip(FlipAbstract(MCD_FLIP_USDC_B), FlipAbstract(MCD_FLIP_USDC_B_OLD));
        FlipperMomAbstract(FLIPPER_MOM).deny(MCD_FLIP_USDC_B); // Auctions disabled

        /*** WBTC-A Flip ***/
        _changeFlip(FlipAbstract(MCD_FLIP_WBTC_A), FlipAbstract(MCD_FLIP_WBTC_A_OLD));

        /*** TUSD-A Flip ***/
        _changeFlip(FlipAbstract(MCD_FLIP_TUSD_A), FlipAbstract(MCD_FLIP_TUSD_A_OLD));
        FlipperMomAbstract(FLIPPER_MOM).deny(MCD_FLIP_TUSD_A); // Auctions disabled

        /*** ZRX-A Flip ***/
        _changeFlip(FlipAbstract(MCD_FLIP_ZRX_A), FlipAbstract(MCD_FLIP_ZRX_A_OLD));

        /*** KNC-A Flip ***/
        _changeFlip(FlipAbstract(MCD_FLIP_KNC_A), FlipAbstract(MCD_FLIP_KNC_A_OLD));

        /*** MANA-A Flip ***/
        _changeFlip(FlipAbstract(MCD_FLIP_MANA_A), FlipAbstract(MCD_FLIP_MANA_A_OLD));

        // *********************
        // *** Other Changes ***
        // *********************

        /*** Risk Parameter Adjustments ***/

        // set the global debt ceiling to 588,000,000
        // 688 (current DC) - 100 (USDC-A decrease)
        VatAbstract(MCD_VAT).file("Line", 588 * MILLION * RAD);

        // Set the USDC-A debt ceiling
        //
        // Existing debt: 140 million
        // New debt ceiling: 40 million
        uint256 USDC_A_LINE = 40 * MILLION * RAD;
        VatAbstract(MCD_VAT).file("USDC-A", "line", USDC_A_LINE);

        /*** Whitelist yearn on ETHUSD Oracle ***/
        OsmAbstract(OSM_ETHUSD).kiss(YEARN);
    }

    function _changeFlip(FlipAbstract newFlip, FlipAbstract oldFlip) internal {
        bytes32 ilk = newFlip.ilk();
        require(ilk == oldFlip.ilk(), "non-matching-ilk");
        require(newFlip.vat() == oldFlip.vat(), "non-matching-vat");
        require(newFlip.cat() == MCD_CAT, "non-matching-cat");
        require(newFlip.vat() == MCD_VAT, "non-matching-vat");

        CatAbstract(MCD_CAT).file(ilk, "flip", address(newFlip));
        (, uint oldChop,) = CatAbstract(MCD_CAT_OLD).ilks(ilk);
        CatAbstract(MCD_CAT).file(ilk, "chop", oldChop / 10 ** 9);

        CatAbstract(MCD_CAT).file(ilk, "dunk", 50 * THOUSAND * RAD);
        CatAbstract(MCD_CAT).rely(address(newFlip));

        newFlip.rely(MCD_CAT);
        newFlip.rely(MCD_END);
        newFlip.rely(FLIPPER_MOM);
        newFlip.file("beg", oldFlip.beg());
        newFlip.file("ttl", oldFlip.ttl());
        newFlip.file("tau", oldFlip.tau());
    }
}

contract DssSpell {
    DSPauseAbstract public pause =
        DSPauseAbstract(0xbE286431454714F511008713973d3B053A2d38f3);
    address         public action;
    bytes32         public tag;
    uint256         public eta;
    bytes           public sig;
    uint256         public expiration;
    bool            public done;

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/6304d5d461f6a0811699eb04fa48b95d68515d8f/governance/votes/Executive%20vote%20-%20August%2028%2C%202020.md -q -O - 2>/dev/null)"
    string constant public description =
        "2020-08-28 MakerDAO Executive Spell | Hash: 0x67885f84f0d31dc816fc327d9912bae6f207199d299543d95baff20cf6305963";

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        expiration = now + 30 days;
    }

    modifier officeHours {
        uint day = (now / 1 days + 3) % 7;
        require(day < 5, "Can only be cast on a weekday");
        uint hour = now / 1 hours % 24;
        require(hour >= 14 && hour < 21, "Outside office hours");
        _;
    }

    function schedule() public {
        require(now <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = now + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public officeHours {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}