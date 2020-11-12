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
    function delay() external view returns (uint256);
    function plot(address, bytes32, bytes calldata, uint256) external;
    function exec(address, bytes32, bytes calldata, uint256) external returns (bytes memory);
}

interface VatAbstract {
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
}

interface SpotAbstract {
    function file(bytes32, bytes32, uint256) external;
    function poke(bytes32) external;
}

interface CatAbstract {
    function file(bytes32, uint256) external;
}

contract SpellAction {

    // MAINNET ADDRESSES
    //
    // The contracts in this list should correspond to MCD core contracts, verify
    // against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/1.1.1/contracts.json
    address constant MCD_VAT     = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant MCD_SPOT    = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address constant MCD_CAT     = 0xa5679C04fc3d9d8b0AaB1F0ab83555b301cA70Ea;

    // Decimals & precision
    uint256 constant MILLION  = 10 ** 6;
    uint256 constant RAY      = 10 ** 27;
    uint256 constant RAD      = 10 ** 45;

    function execute() external {
        /*** Risk Parameter Adjustments ***/

        // Set the global debt ceiling to 948,000,000
        // 823 (current DC) + 100 (USDC-A increase) + 25 (PAXUSD-A increase)
        VatAbstract(MCD_VAT).file("Line", 948 * MILLION * RAD);

        // Set the USDC-A debt ceiling
        //
        // Existing debt ceiling: 100 million
        // New debt ceiling: 200 million
        VatAbstract(MCD_VAT).file("USDC-A", "line", 200 * MILLION * RAD);

        // Set the PAXUSD-A debt ceiling
        //
        // Existing debt ceiling: 5 million
        // New debt ceiling: 30 million
        VatAbstract(MCD_VAT).file("PAXUSD-A", "line", 30 * MILLION * RAD);

        // Set USDC-A collateralization ratio
        // Existing ratio: 110%
        // New ratio: 103%
        SpotAbstract(MCD_SPOT).file("USDC-A", "mat", 103 * RAY / 100); // 103% coll. ratio
        SpotAbstract(MCD_SPOT).poke("USDC-A");

        // Set PAXUSD-A collateralization ratio
        // Existing ratio: 120%
        // New ratio: 103%
        SpotAbstract(MCD_SPOT).file("PAXUSD-A", "mat", 103 * RAY / 100); // 103% coll. ratio
        SpotAbstract(MCD_SPOT).poke("PAXUSD-A");

        // Set Cat box variable
        // Existing box: 30m
        // New box: 15m    
        CatAbstract(MCD_CAT).file("box", 15 * MILLION * RAD);
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
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/15215ebaf8bbb4a20567b3233383788a68afb58b/governance/votes/Executive%20vote%20-%20September%2014%2C%202020.md -q -O - 2>/dev/null)"
    string constant public description =
        "2020-09-14 MakerDAO Executive Spell | Hash: 0xf0155120204be06c56616181ea82bbfa93f48494455c6d0b3c0ab1d581464657";

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
    }

    function cast() public /*officeHours*/ {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}