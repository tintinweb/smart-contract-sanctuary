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
contract DSPauseAbstract {
    function delay() public view returns (uint256);
    function plot(address, bytes32, bytes memory, uint256) public;
    function exec(address, bytes32, bytes memory, uint256) public returns (bytes memory);
}

// https://github.com/makerdao/dss/blob/master/src/vat.sol
contract VatAbstract {
    function wards(address) external view returns (uint256);
}

// https://github.com/makerdao/flipper-mom/blob/master/src/FlipperMom.sol
contract FlipperMomAbstract {
    function rely(address) external;
    function deny(address) external;
}

// https://github.com/makerdao/ilk-registry/blob/master/src/IlkRegistry.sol
contract IlkRegistryAbstract {
    function list() external view returns (bytes32[] memory);
    function flip(bytes32) external view returns (address);
}

contract SpellAction {
    // The contracts in this list should correspond to MCD core contracts, verify
    //  against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/1.1.1/contracts.json
    //
    address constant MCD_VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;

    // Common orders of magnitude needed in spells
    //
    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;
    uint256 constant RAD = 10**45;
    uint256 constant MLN = 10**6;
    uint256 constant BLN = 10**9;

    function execute() external {
        require(VatAbstract(MCD_VAT).wards(address(this)) == 1, "no-access");
    }
}

contract DssSpell {
    DSPauseAbstract  public pause;
    address          public action;
    bytes32          public tag;
    uint256          public eta;
    bytes            public sig;
    uint256          public expiration;
    bool             public done;

    address constant MCD_PAUSE    = 0xbE286431454714F511008713973d3B053A2d38f3;
    address constant FLIPPER_MOM  = 0xc4bE7F74Ee3743bDEd8E0fA218ee5cf06397f472;
    address constant ILK_REGISTRY = 0x8b4ce5DCbb01e0e1f0521cd8dCfb31B308E52c24;

    uint256 constant T2021_02_01_1200UTC = 1612180800;

    // Provides a descriptive tag for bot consumption
    string constant public description = "DEFCON-5 Emergency Spell";

    constructor() public {
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        pause = DSPauseAbstract(MCD_PAUSE);
        expiration = T2021_02_01_1200UTC;
    }

    function schedule() public {
        require(now <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = now + pause.delay();
        pause.plot(action, tag, sig, eta);

        // Loop over all ilks
        //
        IlkRegistryAbstract registry = IlkRegistryAbstract(ILK_REGISTRY);
        bytes32[] memory ilks = registry.list();

        for (uint i = 0; i < ilks.length; i++) {
            // skip the rest of the loop for the following ilks:
            //
            if (ilks[i] == "USDC-A" ||
                ilks[i] == "USDC-B" ||
                ilks[i] == "TUSD-A" ||
                ilks[i] == "PAXUSD-A"
            ) { continue; }

            // Enable collateral liquidations
            //
            // This change will enable liquidations for collateral types
            // and is colloquially referred to as the "circuit breaker".
            //
            FlipperMomAbstract(FLIPPER_MOM).rely(registry.flip(ilks[i]));
        }
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}