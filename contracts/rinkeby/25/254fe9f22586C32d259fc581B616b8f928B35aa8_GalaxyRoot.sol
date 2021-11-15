// Copyright (C) 2020 Centrifuge
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
pragma solidity >=0.5.15 <0.6.0;

import "../lib/galaxy-auth/src/auth.sol";

interface AuthLike {
    function rely(address) external;
    function deny(address) external;
}

interface DependLike {
    function depend(bytes32, address) external;
}

interface BorrowerDeployerLike {
    function collector() external returns (address);
    function feed() external returns (address);
    function shelf() external returns (address);
    function title() external returns (address);
}
interface LenderDeployerLike {
    function assessor() external returns (address);
    function reserve() external returns (address);
}


contract GalaxyRoot is Auth {
    BorrowerDeployerLike public borrowerDeployer;
    LenderDeployerLike public  lenderDeployer;

    bool public             deployed;
    address public          deployUsr;

    constructor (address deployUsr_) public {
        deployUsr = deployUsr_;
    }

    // --- Prepare ---
    // Sets the two deployer dependencies. This needs to be called by the deployUsr
    function prepare(address lender_, address borrower_, address ward_) public {
        require(deployUsr == msg.sender);
        borrowerDeployer = BorrowerDeployerLike(borrower_);
        lenderDeployer = LenderDeployerLike(lender_);
        wards[ward_] = 1;
        deployUsr = address(0); // disallow the deploy user to call this more than once.
    }

    // --- Deploy ---
    // After going through the deploy process on the lender and borrower method, this method is called to connect
    // lender and borrower contracts.
    function deploy() public {
        require(address(borrowerDeployer) != address(0) && address(lenderDeployer) != address(0) && deployed == false);
        deployed = true;

        address reserve_ = lenderDeployer.reserve();
        address shelf_ = borrowerDeployer.shelf();

        // Borrower depends
        DependLike(borrowerDeployer.collector()).depend("distributor", reserve_);
        DependLike(borrowerDeployer.shelf()).depend("lender", reserve_);
        DependLike(borrowerDeployer.shelf()).depend("distributor", reserve_);

        //AuthLike(reserve).rely(shelf_);

        //  Lender depends
        address navFeed = borrowerDeployer.feed();

        DependLike(reserve_).depend("shelf", shelf_);
        DependLike(lenderDeployer.assessor()).depend("navFeed", navFeed);
    }

    // --- Governance Functions ---
    // `relyContract` & `denyContract` can be called by any ward on the GalaxyRoot
    // contract to make an arbitrary address a ward on any contract the GalaxyRoot
    // is a ward on.
    function relyContract(address target, address usr) public auth {
        AuthLike(target).rely(usr);
    }

    function denyContract(address target, address usr) public auth {
        AuthLike(target).deny(usr);
    }

}

// Copyright (C) Centrifuge 2020, based on MakerDAO dss https://github.com/makerdao/dss
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

pragma solidity >=0.5.15 <0.6.0;

import "../../ds-note/src/note.sol";

contract Auth is DSNote {
    mapping (address => uint) public wards;
    function rely(address usr) public auth note { wards[usr] = 1; }
    function deny(address usr) public auth note { wards[usr] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }
}

/// note.sol -- the `note' modifier, for logging calls as events

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
pragma solidity >=0.5.15;

contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        uint256           wad,
        bytes             fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;
        uint256 wad;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
            wad := callvalue()
        }

        _;

        emit LogNote(msg.sig, msg.sender, foo, bar, wad, msg.data);
    }
}

