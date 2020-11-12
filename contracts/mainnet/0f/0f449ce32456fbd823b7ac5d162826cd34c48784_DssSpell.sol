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
    function wards(address) external view returns (uint256);
}

contract SpellAction {

    // MAINNET ADDRESSES
    //
    // The contracts in this list should correspond to MCD core contracts, verify
    // against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/1.0.9/contracts.json
    address constant MCD_VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;

    function execute() external {
		// proving the Pause Proxy has access to the MCD core system at the execution time
		require(VatAbstract(MCD_VAT).wards(address(this)) == 1, "no-access");
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
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/fc5bbefb3d304408f6261a8968b7b8b924b53b58/governance/votes/Executive%20vote%20-%20August%2024%2C%202020.md -q -O - 2>/dev/null)"
    string constant public description =
        "2020-08-24 MakerDAO August 2020 Governance Cycle Bundle | Hash: 0xa0d81d0896decfa0e74f1e4d353640d132953c373605e2fe22f1da23a7c3ed6c";

    // MIP13c3-SP1 Declaration of Intent (Forward Guidance)
    // https://raw.githubusercontent.com/makerdao/mips/30e57b376d239a948310a7ff316b1a659d73af02/MIP13/MIP13c3-Subproposals/MIP13c3-SP1.md
	string constant public MIP13C3SP1 = "0xdc1d9ca6751a4f9e138a5852d1bc0372cd175a8007b9f0a05f8e4e8b4213c9a4";

    // MIP0c13-SP1 Subproposal for Core Personnel Offboarding
    // https://raw.githubusercontent.com/makerdao/mips/e5b3640087c7c8b5b04527a9562b99c291b17e9b/MIP0/MIP0c13-Subproposals/MIP0c13-SP1.md
	string constant public MIP0C13SP1 = "0xf8c9b8e15faf490c1f6b4a3d089453d496f2a27a662a70114b446c76a629172e";

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        expiration = now + 4 days + 2 hours;
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