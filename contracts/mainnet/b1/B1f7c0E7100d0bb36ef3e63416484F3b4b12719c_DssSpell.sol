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

interface DSPauseAbstract {
    function proxy() external view returns (address);
    function delay() external view returns (uint256);
    function plot(address, bytes32, bytes calldata, uint256) external;
    function exec(address, bytes32, bytes calldata, uint256) external returns (bytes memory);
}

interface JugAbstract {
    function file(bytes32, bytes32, uint256) external;
    function drip(bytes32) external returns (uint256);
}

interface MedianAbstract {
    function kiss(address) external;
    function kiss(address[] calldata) external;
}

interface OsmAbstract {
    function kiss(address) external;
}

interface VatAbstract {
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
}

interface MedianizerV1Abstract {
    function setAuthority(address) external;
    function setOwner(address) external;
    function setMin(uint96) external;
    function setNext(bytes12) external;
    function set(bytes12, address) external;
}

contract SpellAction {

    // MAINNET ADDRESSES
    //
    // The contracts in this list should correspond to MCD core contracts, verify
    // against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/1.1.1/contracts.json
    address constant MCD_JUG  = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant MCD_VAT  = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;

    address constant ETHUSD   = 0x64DE91F5A373Cd4c28de3600cB34C7C6cE410C85;
    address constant BTCUSD   = 0xe0F30cb149fAADC7247E953746Be9BbBB6B5751f;
    address constant PIP_WBTC = 0xf185d0682d50819263941e5f4EacC763CC5C6C42;

    address constant KYBER    = 0xe1BDEb1F71b1CD855b95D4Ec2d1BFdc092E00E4F;
    address constant DDEX     = 0x4935B1188EB940C39e22172cc5fe595E267706a1;
    address constant ETHUSDv1 = 0x729D19f657BD0614b4985Cf1D82531c67569197B;
    address constant YEARN    = 0x82c93333e4E295AA17a05B15092159597e823e8a;

    // Decimals & precision
    uint256 constant THOUSAND = 10 ** 3;
    uint256 constant MILLION  = 10 ** 6;
    uint256 constant WAD      = 10 ** 18;
    uint256 constant RAY      = 10 ** 27;
    uint256 constant RAD      = 10 ** 45;

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    uint256 constant TWO_TWENTYFIVE_PCT_RATE    = 1000000000705562181084137268;
    uint256 constant FOUR_TWENTYFIVE_PCT_RATE   = 1000000001319814647332759691;
    uint256 constant EIGHT_TWENTYFIVE_PCT_RATE  = 1000000002513736079215619839;
    uint256 constant TWELVE_TWENTYFIVE_PCT_RATE = 1000000003664330950215446102;
    uint256 constant FIFTY_TWENTYFIVE_PCT_RATE  = 1000000012910019978921115695;

    function execute() external {
        /*** Risk Parameter Adjustments ***/

        // Set the global debt ceiling to 1,401,000,000
        // 1,196 (current DC) + 85 (USDC-A increase) + 85 (TUSD-A increase) + 30 (PAXUSD-A increase) + 5 (BAT-A increase)
        VatAbstract(MCD_VAT).file("Line", 1401 * MILLION * RAD);

        // Set the BAT-A debt ceiling
        //
        // Existing debt ceiling: 5 million
        // New debt ceiling: 10 million
        VatAbstract(MCD_VAT).file("BAT-A", "line", 10 * MILLION * RAD);

        // Set the USDC-A debt ceiling
        //
        // Existing debt ceiling: 400 million
        // New debt ceiling: 485 million
        VatAbstract(MCD_VAT).file("USDC-A", "line", 485 * MILLION * RAD);

        // Set the TUSD-A debt ceiling
        //
        // Existing debt ceiling: 50 million
        // New debt ceiling: 135 million
        VatAbstract(MCD_VAT).file("TUSD-A", "line", 135 * MILLION * RAD);

        // Set the PAXUSD-A debt ceiling
        //
        // Existing debt ceiling: 30 million
        // New debt ceiling: 60 million
        VatAbstract(MCD_VAT).file("PAXUSD-A", "line", 60 * MILLION * RAD);


        // Set the ETH-A stability fee
        //
        // Previous: 0%
        // New: 2.25%
        JugAbstract(MCD_JUG).drip("ETH-A"); // drip right before
        JugAbstract(MCD_JUG).file("ETH-A", "duty", TWO_TWENTYFIVE_PCT_RATE);

        // Set the BAT-A stability fee
        //
        // Previous: 4%
        // New: 4.25%
        JugAbstract(MCD_JUG).drip("BAT-A"); // drip right before
        JugAbstract(MCD_JUG).file("BAT-A", "duty", FOUR_TWENTYFIVE_PCT_RATE);

        // Set the USDC-A stability fee
        //
        // Previous: 4%
        // New: 4.25%
        JugAbstract(MCD_JUG).drip("USDC-A"); // drip right before
        JugAbstract(MCD_JUG).file("USDC-A", "duty", FOUR_TWENTYFIVE_PCT_RATE);

        // Set the USDC-B stability fee
        //
        // Previous: 50%
        // New: 50.25%
        JugAbstract(MCD_JUG).drip("USDC-B"); // drip right before
        JugAbstract(MCD_JUG).file("USDC-B", "duty", FIFTY_TWENTYFIVE_PCT_RATE);

        // Set the WBTC-A stability fee
        //
        // Previous: 4%
        // New: 4.25%
        JugAbstract(MCD_JUG).drip("WBTC-A"); // drip right before
        JugAbstract(MCD_JUG).file("WBTC-A", "duty", FOUR_TWENTYFIVE_PCT_RATE);

        // Set the TUSD-A stability fee
        //
        // Previous: 4%
        // New: 4.25%
        JugAbstract(MCD_JUG).drip("TUSD-A"); // drip right before
        JugAbstract(MCD_JUG).file("TUSD-A", "duty", FOUR_TWENTYFIVE_PCT_RATE);

        // Set the KNC-A stability fee
        //
        // Previous: 4%
        // New: 4.25%
        JugAbstract(MCD_JUG).drip("KNC-A"); // drip right before
        JugAbstract(MCD_JUG).file("KNC-A", "duty", FOUR_TWENTYFIVE_PCT_RATE);

        // Set the ZRX-A stability fee
        //
        // Previous: 4%
        // New: 4.25%
        JugAbstract(MCD_JUG).drip("ZRX-A"); // drip right before
        JugAbstract(MCD_JUG).file("ZRX-A", "duty", FOUR_TWENTYFIVE_PCT_RATE);

        // Set the MANA-A stability fee
        //
        // Previous: 12%
        // New: 12.25%
        JugAbstract(MCD_JUG).drip("MANA-A"); // drip right before
        JugAbstract(MCD_JUG).file("MANA-A", "duty", TWELVE_TWENTYFIVE_PCT_RATE);

        // Set the USDT-A stability fee
        //
        // Previous: 8%
        // New: 8.25%
        JugAbstract(MCD_JUG).drip("USDT-A"); // drip right before
        JugAbstract(MCD_JUG).file("USDT-A", "duty", EIGHT_TWENTYFIVE_PCT_RATE);

        // Set the PAXUSD-A stability fee
        //
        // Previous: 4%
        // New: 4.25%
        JugAbstract(MCD_JUG).drip("PAXUSD-A"); // drip right before
        JugAbstract(MCD_JUG).file("PAXUSD-A", "duty", FOUR_TWENTYFIVE_PCT_RATE);

        // Whitelisting:

        // https://forum.makerdao.com/t/mip10c9-sp11-whitelist-kybers-promo-token-pricing-contract-on-ethusd-oracle/4193
        // https://forum.makerdao.com/t/mip10c9-sp7-whitelist-opyn-on-ethusd-oracle/4061
        address[] memory addrs = new address[](2);
        addrs[0] = KYBER;
        addrs[1] = ETHUSDv1;
        MedianAbstract(ETHUSD).kiss(addrs);

        // Add the new median as the only src of the old medianizer
        MedianizerV1Abstract(ETHUSDv1).setMin(1);
        MedianizerV1Abstract(ETHUSDv1).setNext(0x000000000000000000000002);
        MedianizerV1Abstract(ETHUSDv1).set(0x000000000000000000000001, ETHUSD);

        // https://forum.makerdao.com/t/mip10c9-sp8-whitelist-ddex-on-wbtcusd-oracle/4094
        MedianAbstract(BTCUSD).kiss(DDEX);

        // https://forum.makerdao.com/t/mip10c9-sp10-whitelist-yearn-finance-on-btcusd-oracle/4192
        OsmAbstract(PIP_WBTC).kiss(YEARN);
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

    address constant ETHUSDv1 = 0x729D19f657BD0614b4985Cf1D82531c67569197B;

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/9ba21e7f4106b184124a2f94a7ab2591c3446c64/governance/votes/Executive%20vote%20-%20September%2025%2C%202020.md -q -O - 2>/dev/null)"
    string constant public description =
        "2020-09-25 MakerDAO Executive Spell | Hash: 0x86cac34c2d63bd581cc36f7688f57c6005a6de0382903fe30179953d025c3450";

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        expiration = now + 30 days;
    }

    // modifier officeHours {
    //     uint day = (now / 1 days + 3) % 7;
    //     require(day < 5, "Can only be cast on a weekday");
    //     uint hour = now / 1 hours % 24;
    //     require(hour >= 14 && hour < 21, "Outside office hours");
    //     _;
    // }

    function schedule() public {
        require(now <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = now + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);

        // Set the ownership of the medianizer v1 to the pause proxy and remove the direct
        // access from the chief (this way it will need to pass via governance delay) and
        // can be executed during cast (coded in the SpellAction)
        MedianizerV1Abstract(ETHUSDv1).setOwner(pause.proxy());
        MedianizerV1Abstract(ETHUSDv1).setAuthority(address(0));
    }

    function cast() public /*officeHours*/ {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}