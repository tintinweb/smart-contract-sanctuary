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

interface MedianAbstract {
    function kiss(address) external;
    function diss(address) external;
}

contract SpellAction {

    // MAINNET ADDRESSES
    //
    // The contracts in this list should correspond to MCD core contracts, verify
    // against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/1.1.1/contracts.json
    address constant MCD_VAT     = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;

    address constant ETHBTC      = 0x81A679f98b63B3dDf2F17CB5619f4d6775b3c5ED;

    address constant tBTC        = 0xA3F68d722FBa26173aB64697B4625d4aD0F4C818;
    address constant tBTC_OLD    = 0x3b995E9f719Cb5F4b106F795B01760a11d083823;

    // Decimals & precision
    uint256 constant MILLION  = 10 ** 6;
    uint256 constant RAD      = 10 ** 45;

    function execute() external {
        /*** Risk Parameter Adjustments ***/

        // Set the global debt ceiling to 823,000,000
        // 763 (current DC) + 60 (USDC-A increase)
        VatAbstract(MCD_VAT).file("Line", 823 * MILLION * RAD);

        // Set the USDC-A debt ceiling
        //
        // Existing debt ceiling: 40 million
        // New debt ceiling: 100 million
        VatAbstract(MCD_VAT).file("USDC-A", "line", 100 * MILLION * RAD);

        // https://forum.makerdao.com/t/mip10c9-subproposal-to-whitelist-new-tbtc-oracle-access/3805
        // Whitelist tBTC address to read ETHBTC median
        MedianAbstract(ETHBTC).kiss(tBTC);
        // Remove previous tBTC address from ETHBTC median whitelist
        MedianAbstract(ETHBTC).diss(tBTC_OLD);
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
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/c6b12fcd90c6c59795fa34e3bd573f2d2d7eb832/governance/votes/Executive%20vote%20-%20September%2011%2C%202020.md -q -O - 2>/dev/null)"
    string constant public description =
        "2020-09-11 MakerDAO Executive Spell | Hash: 0x54ead845e3b3dda69b7b5eede7c0150cd37f68302b7379deba19cbaee56a1ca6";

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        expiration = now + 30 days;
    }

    function schedule() public {
        require(now <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = now + DSPauseAbstract(pause).delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}