/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

// hevm: flattened sources of src/DssSpell.sol
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity =0.6.12 >=0.6.12 <0.7.0;

////// lib/dss-exec-lib/src/DssExecLib.sol
//
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
/* pragma solidity ^0.6.12; */
/* pragma experimental ABIEncoderV2; */


library DssExecLib {
    function canCast(uint40, bool) public pure returns (bool) {}
    function nextCastTime(uint40, uint40, bool) public pure returns (uint256) {}
    function sendPaymentFromSurplusBuffer(address, uint256) public {}
}

////// lib/dss-exec-lib/src/DssAction.sol
//
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

/* pragma solidity ^0.6.12; */

/* import { DssExecLib } from "./DssExecLib.sol"; */

abstract contract DssAction {

    using DssExecLib for *;

    // Modifier used to limit execution time when office hours is enabled
    modifier limited {
        require(DssExecLib.canCast(uint40(block.timestamp), officeHours()), "Outside office hours");
        _;
    }

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

    // Returns the next available cast time
    function nextCastTime(uint256 eta) external returns (uint256 castTime) {
        require(eta <= uint40(-1));
        castTime = DssExecLib.nextCastTime(uint40(eta), uint40(block.timestamp), officeHours());
    }
}

////// lib/dss-exec-lib/src/DssExec.sol
//
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

/* pragma solidity ^0.6.12; */

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
    function nextCastTime(uint256) external view returns (uint256);
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
        return SpellAction(action).nextCastTime(eta);
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

////// src/DssSpell.sol
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

/* pragma solidity 0.6.12; */

/* import "dss-exec-lib/DssExec.sol"; */
/* import "dss-exec-lib/DssAction.sol"; */

contract DssSpellAction is DssAction {

    // Provides a descriptive tag for bot consumption
    // This should be modified weekly to provide a summary of the actions
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/community/eae06d4b38346a7d90d92cd951beff16a3d548c9/governance/votes/Executive%20vote%20-%20May%2024%2C%202021.md -q -O - 2> /dev/null)"
    string public constant description =
        "2021-05-24 MakerDAO Executive Spell | Hash: 0xca4176704005e00b4357c0ef4ebb1812c88b21e57463bdfbb90da1c8189b406d";

    // SES auditors Multisig
    address constant SES_AUDITORS_MULTISIG = 0x87AcDD9208f73bFc9207e1f6F0fDE906bcA95cc6;
    // Monthly expenses
    uint256 constant SES_AUDITORS_AMOUNT = 1_153_480;

    // MIP50: Direct Deposit Module
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/c23fd23b340ecf66a16f0e1ecfe7b55a5232864d/MIP50/mip50.md -q -O - 2> /dev/null)"
    string constant public MIP50 = "0xb6ba98197a58fab2af683951e753dfac802e0fef29d736ef58dd91a35706fb61";

    // MIP51: Monthly Governance Cycle
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/c23fd23b340ecf66a16f0e1ecfe7b55a5232864d/MIP51/mip51.md -q -O - 2> /dev/null)"
    string constant public MIP51 = "0xa9e81bc611853444ebfe5e3cca2f14b48a8490612ed4077ba7aa52a302db2366";

    // MIP4c2-SP14: MIP Amendment Subproposals
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/c23fd23b340ecf66a16f0e1ecfe7b55a5232864d/MIP4/MIP4c2-Subproposals/MIP4c2-SP14.md -q -O - 2> /dev/null)"
    string constant public MIP4c2SP14 = "0x466c906898858488c5083ef8e9d67bf5c26e86c372064bd483de3a203285b1a2";

    // MIP39c2-SP10: Adding Sustainable Ecosystem Scaling Core Unit
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/c23fd23b340ecf66a16f0e1ecfe7b55a5232864d/MIP39/MIP39c2-Subproposals/MIP39c2-SP10.md -q -O - 2> /dev/null)"
    string constant public MIP39c2SP10 = "0x29b327498fe5b300cd0f81b2fa0eacd886916162b188b967fb5bb330f5b68b94";

    // MIP40c3-SP10: Modify Core Unit Budget
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/c23fd23b340ecf66a16f0e1ecfe7b55a5232864d/MIP40/MIP40c3-Subproposals/MIP40c3-SP10.md -q -O - 2> /dev/null)"
    string constant public MIP40c3SP10 = "0xa3afb63a4710cb30ad67082cdbb8156a11b315cadb251bfe6af7732c08303aa6";

    // MIP41c4-SP10: Facilitator Onboarding (Subproposal Process) Template
    // Hash: seth keccak -- "$(wget https://raw.githubusercontent.com/makerdao/mips/c23fd23b340ecf66a16f0e1ecfe7b55a5232864d/MIP41/MIP41c4-Subproposals/MIP41c4-SP10.md -q -O - 2> /dev/null)"
    string constant public MIP41c4SP10 = "0xe37c37e3ffc8a2c638500f05f179b1d07d00e5aa35ae37ac88a1e10d43e77728";

    // Disable Office Hours
    function officeHours() public override returns (bool) {
        return false;
    }

    function actions() public override {
        // Payment of SES auditors budget
        DssExecLib.sendPaymentFromSurplusBuffer(SES_AUDITORS_MULTISIG, SES_AUDITORS_AMOUNT);
    }
}

contract DssSpell is DssExec {
    DssSpellAction internal action_ = new DssSpellAction();
    constructor() DssExec(action_.description(), block.timestamp + 4 days, address(action_)) public {}
}