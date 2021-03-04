/**
 *Submitted for verification at Etherscan.io on 2021-03-03
*/

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

// https://github.com/makerdao/dss/blob/master/src/pot.sol
contract PotAbstract {
    function file(bytes32, uint256) external;
    function drip() external returns (uint256);
}

// https://github.com/makerdao/dss/blob/master/src/jug.sol
contract JugAbstract {
    function file(bytes32, bytes32, uint256) external;
    function drip(bytes32) external returns (uint256);
}

// https://github.com/makerdao/dss/blob/master/src/vat.sol
contract VatAbstract {
    function ilks(bytes32) external view returns (uint256, uint256, uint256, uint256, uint256);
    function file(bytes32, uint256) external;
    function file(bytes32, bytes32, uint256) external;
}

// https://github.com/makerdao/dss/blob/master/src/flip.sol
contract FlipAbstract {
    function file(bytes32, uint256) external;
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

// https://github.com/makerdao/dss-chain-log/blob/master/src/ChainLog.sol
contract ChainlogAbstract {
    function getAddress(bytes32) public view returns (address);
}

contract SpellAction {
    // This address should correspond to the latest MCD Chainlog contract; verify
    //  against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/active/contracts.json
    ChainlogAbstract constant CHANGELOG =
        ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    // Many of the settings that change weekly rely on the rate accumulator
    // described at https://docs.makerdao.com/smart-contract-modules/rates-module
    // To check this yourself, use the following rate calculation (example 8%):
    //
    // $ bc -l <<< 'scale=27; e( l(1.08)/(60 * 60 * 24 * 365) )'
    //
    uint256 constant ZERO_PCT_RATE = 1000000000000000000000000000;

    // Common orders of magnitude needed in spells
    //
    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;
    uint256 constant RAD = 10**45;
    uint256 constant MLN = 10**6;
    uint256 constant BLN = 10**9;

    function execute() external {
        address MCD_VAT      = CHANGELOG.getAddress("MCD_VAT");
        address MCD_JUG      = CHANGELOG.getAddress("MCD_JUG");
        address MCD_POT      = CHANGELOG.getAddress("MCD_POT");
        address ILK_REGISTRY = CHANGELOG.getAddress("ILK_REGISTRY");
        uint256 totalLine = 0;

        // MCD Modifications

        // Ensure we drip pot prior to modifications (housekeeping).
        //
        PotAbstract(MCD_POT).drip();

        // Set the Dai Savings Rate
        // DSR_RATE is a value determined by the rate accumulator calculation
        // ex. an 8% annual rate will be 1000000002440418608258400030
        //
        PotAbstract(MCD_POT).file("dsr", ZERO_PCT_RATE);

        // Loop over all ilks
        //
        IlkRegistryAbstract registry = IlkRegistryAbstract(ILK_REGISTRY);
        bytes32[] memory ilks = registry.list();

        for (uint i = 0; i < ilks.length; i++) {
            // skip the rest of the loop for the following ilks:
            //
            if (ilks[i] == "USDC-B") {
                continue;
            }

            // Always drip the ilk prior to modifications (housekeeping)
            //
            JugAbstract(MCD_JUG).drip(ilks[i]);

            // Set the ilk stability fee
            //
            JugAbstract(MCD_JUG).file(ilks[i], "duty", ZERO_PCT_RATE);

            // Keep a running total of all ilk Debt Ceilings
            //
            (,,, uint256 ilkLine,) = VatAbstract(MCD_VAT).ilks(ilks[i]);
            totalLine += ilkLine;
        }

        // Set the USDC-B debt ceiling
        // USDC_B_LINE is the number of Dai that can be created with USDC token
        // collateral.
        // ex. a 60 million Dai USDC-B ceiling will be USDC_B_LINE = 60000000
        //
        // New Line: +50m
        (,,, uint256 ilkLine,) = VatAbstract(MCD_VAT).ilks("USDC-B");
        uint256 USDC_B_LINE = ilkLine + (50 * MLN * RAD);
        VatAbstract(MCD_VAT).file("USDC-B", "line", USDC_B_LINE);
        totalLine += USDC_B_LINE;

        // Set the Global Debt Ceiling to the sum of all ilk line
        //
        VatAbstract(MCD_VAT).file("Line", totalLine);
    }
}

contract DssSpell {
    // This address should correspond to the latest MCD Chainlog contract; verify
    //  against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/active/contracts.json
    ChainlogAbstract constant CHANGELOG =
        ChainlogAbstract(0xdA0Ab1e0017DEbCd72Be8599041a2aa3bA7e740F);

    DSPauseAbstract  public pause;
    address          public action;
    bytes32          public tag;
    uint256          public eta;
    bytes            public sig;
    uint256          public expiration;
    bool             public done;

    uint256 constant T2021_07_01_1200UTC = 1625140800;

    // Provides a descriptive tag for bot consumption
    string constant public description = "DEFCON-3 Emergency Spell";

    constructor() public {
        address MCD_PAUSE = CHANGELOG.getAddress("MCD_PAUSE");
        sig = abi.encodeWithSignature("execute()");
        action = address(new SpellAction());
        bytes32 _tag;
        address _action = action;
        assembly { _tag := extcodehash(_action) }
        tag = _tag;
        pause = DSPauseAbstract(MCD_PAUSE);
        expiration = T2021_07_01_1200UTC;
    }

    function schedule() public {
        require(now <= expiration, "This contract has expired");
        require(eta == 0, "This spell has already been scheduled");
        eta = now + pause.delay();
        pause.plot(action, tag, sig, eta);
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}