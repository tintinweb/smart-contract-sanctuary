// hevm: flattened sources of src/DssSpell.sol
pragma solidity =0.5.12 >0.4.13 >=0.4.23 >=0.5.12;

////// lib/dss-interfaces/src/dapp/DSPauseAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/dapphub/ds-pause
interface DSPauseAbstract {
    function setOwner(address) external;
    function setAuthority(address) external;
    function setDelay(uint256) external;
    function plans(bytes32) external view returns (bool);
    function proxy() external view returns (address);
    function delay() external view returns (uint256);
    function plot(address, bytes32, bytes calldata, uint256) external;
    function drop(address, bytes32, bytes calldata, uint256) external;
    function exec(address, bytes32, bytes calldata, uint256) external returns (bytes memory);
}

////// lib/dss-interfaces/src/dss/FlipperMomAbstract.sol
/* pragma solidity >=0.5.12; */

// https://github.com/makerdao/flipper-mom/blob/master/src/FlipperMom.sol
interface FlipperMomAbstract {
    function owner() external returns (address);
    function setOwner(address) external;
    function authority() external returns (address);
    function setAuthority(address) external;
    function cat() external returns (address);
    function rely(address) external;
    function deny(address) external;
}

////// lib/dss-interfaces/src/dss/OsmMomAbstract.sol
/* pragma solidity >=0.5.12; */


// https://github.com/makerdao/osm-mom
interface OsmMomAbstract {
    function owner() external view returns (address);
    function authority() external view returns (address);
    function osms(bytes32) external view returns (address);
    function setOsm(bytes32, address) external;
    function setOwner(address) external;
    function setAuthority(address) external;
    function stop(bytes32) external;
}

////// src/DssSpell.sol
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

/* pragma solidity 0.5.12; */

/* import "lib/dss-interfaces/src/dapp/DSPauseAbstract.sol"; */
/* import "lib/dss-interfaces/src/dss/OsmMomAbstract.sol"; */
/* import "lib/dss-interfaces/src/dss/FlipperMomAbstract.sol"; */

contract SpellAction {
    // MAINNET ADDRESSES
    //
    // The contracts in this list should correspond to MCD core contracts, verify
    //  against the current release list at:
    //     https://changelog.makerdao.com/releases/mainnet/1.1.3/contracts.json

    address constant FLIPPER_MOM = 0xc4bE7F74Ee3743bDEd8E0fA218ee5cf06397f472;
    address constant MCD_PAUSE   = 0xbE286431454714F511008713973d3B053A2d38f3;
    address constant OSM_MOM     = 0x76416A4d5190d071bfed309861527431304aA14f;

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
    // A table of rates can be found at
    //    https://ipfs.io/ipfs/QmefQMseb3AiTapiAKKexdKHig8wroKuZbmLtPLv4u2YwW

    function execute() external {
        // increase governance delay to 72 hours
        DSPauseAbstract(MCD_PAUSE).setDelay(72 hours);

        // remove authority from the FlipperMom
        FlipperMomAbstract(FLIPPER_MOM).setAuthority(address(0));

        // remove authority from the OsmMom
        OsmMomAbstract(OSM_MOM).setAuthority(address(0));
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
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/32eab726f883b00c500cfc288612ec0fe696c7da/governance/votes/Executive%20vote%20-%20October%2030%2C%202020.md -q -O - 2>/dev/null)"
    string constant public description =
        "2020-10-30 MakerDAO Executive Spell | Hash: 0x458b4e4acf4055bac448d17cafcfa847f5d721f7894fe8a34f0fc8479a1ec645";

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

    function cast() public /* officeHours */ {
        require(!done, "spell-already-cast");
        done = true;
        pause.exec(action, tag, sig, eta);
    }
}