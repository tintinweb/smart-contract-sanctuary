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

// https://github.com/makerdao/dss/blob/master/src/vat.sol
contract VatAbstract {
    function wards(address) external view returns (uint256);
}

// https://github.com/makerdao/dss/blob/master/src/flip.sol
contract FlipAbstract {
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

    // Common orders of magnitude needed in spells
    //
    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;
    uint256 constant RAD = 10**45;
    uint256 constant MLN = 10**6;
    uint256 constant BLN = 10**9;

    function execute() external {
        address MCD_VAT = CHANGELOG.getAddress("MCD_VAT");
        require(VatAbstract(MCD_VAT).wards(address(this)) == 1, "no-access");
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
    string constant public description = "DEFCON-5 Emergency Spell";

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
        address FLIPPER_MOM  = CHANGELOG.getAddress("FLIPPER_MOM");
        address ILK_REGISTRY = CHANGELOG.getAddress("ILK_REGISTRY");
        eta = now + pause.delay();
        pause.plot(action, tag, sig, eta);

        // Loop over all ilks
        //
        IlkRegistryAbstract registry = IlkRegistryAbstract(ILK_REGISTRY);
        bytes32[] memory ilks = registry.list();

        for (uint i = 0; i < ilks.length; i++) {
            // Enable collateral liquidations
            //
            // This change will enable liquidations for collateral types
            // and is colloquially referred to as the "circuit breaker".
            //
            if (FlipAbstract(registry.flip(ilks[i])).wards(FLIPPER_MOM) == 1) {
                FlipperMomAbstract(FLIPPER_MOM).rely(registry.flip(ilks[i]));
            }
        }
    }

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}