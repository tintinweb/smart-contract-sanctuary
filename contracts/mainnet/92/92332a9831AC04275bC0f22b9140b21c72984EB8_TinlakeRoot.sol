/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

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

pragma solidity >=0.4.23;

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

contract Auth is DSNote {
    mapping (address => uint) public wards;
    function rely(address usr) public auth note { wards[usr] = 1; }
    function deny(address usr) public auth note { wards[usr] = 0; }
    modifier auth { require(wards[msg.sender] == 1); _; }
}

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
    function pile() external returns (address);
}
interface LenderDeployerLike {
    function assessor() external returns (address);
    function reserve() external returns (address);
    function assessorAdmin() external returns (address);
    function juniorMemberlist() external returns (address);
    function seniorMemberlist() external returns (address);
    function juniorOperator() external returns (address);
    function seniorOperator() external returns (address);
    function coordinator() external returns (address);
}


contract TinlakeRoot is Auth {
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

        // Permissions
        address poolAdmin1 = 0x24730a9D68008c6Bd8F43e60Ed2C00cbe57Ac829;
        address poolAdmin2 = 0x71d9f8CFdcCEF71B59DD81AB387e523E2834F2b8;
        address poolAdmin3 = 0xa7Aa917b502d86CD5A23FFbD9Ee32E013015e069;
        address poolAdmin4 = 0xfEADaD6b75e6C899132587b7Cb3FEd60c8554821;
        address poolAdmin5 = 0xC3997Ef807A24af6Ca5Cb1d22c2fD87C6c3b79E8;
        address poolAdmin6 = 0xd60f7CFC1E051d77031aC21D9DB2F66fE54AE312;
        address poolAdmin7 = 0x46a71eEf8DbcFcbAC7A0e8D5d6B634A649e61fb8;
        address oracle = 0x8F1afCFDB6B4264B8fbFfBB9ca900e66187543cf;

        AuthLike(lenderDeployer.assessorAdmin()).rely(poolAdmin1);
        AuthLike(lenderDeployer.assessorAdmin()).rely(poolAdmin2);
        AuthLike(lenderDeployer.assessorAdmin()).rely(poolAdmin3);
        AuthLike(lenderDeployer.assessorAdmin()).rely(poolAdmin4);
        AuthLike(lenderDeployer.assessorAdmin()).rely(poolAdmin5);
        AuthLike(lenderDeployer.assessorAdmin()).rely(poolAdmin6);
        AuthLike(lenderDeployer.assessorAdmin()).rely(poolAdmin7);

        AuthLike(lenderDeployer.juniorMemberlist()).rely(poolAdmin1);
        AuthLike(lenderDeployer.juniorMemberlist()).rely(poolAdmin2);
        AuthLike(lenderDeployer.juniorMemberlist()).rely(poolAdmin3);
        AuthLike(lenderDeployer.juniorMemberlist()).rely(poolAdmin4);
        AuthLike(lenderDeployer.juniorMemberlist()).rely(poolAdmin5);
        AuthLike(lenderDeployer.juniorMemberlist()).rely(poolAdmin6);
        AuthLike(lenderDeployer.juniorMemberlist()).rely(poolAdmin7);

        AuthLike(lenderDeployer.seniorMemberlist()).rely(poolAdmin1);
        AuthLike(lenderDeployer.seniorMemberlist()).rely(poolAdmin2);
        AuthLike(lenderDeployer.seniorMemberlist()).rely(poolAdmin3);
        AuthLike(lenderDeployer.seniorMemberlist()).rely(poolAdmin4);
        AuthLike(lenderDeployer.seniorMemberlist()).rely(poolAdmin5);
        AuthLike(lenderDeployer.seniorMemberlist()).rely(poolAdmin6);
        AuthLike(lenderDeployer.seniorMemberlist()).rely(poolAdmin7);

        AuthLike(navFeed).rely(oracle);
    }

    // --- Governance Functions ---
    // `relyContract` & `denyContract` can be called by any ward on the TinlakeRoot
    // contract to make an arbitrary address a ward on any contract the TinlakeRoot
    // is a ward on.
    function relyContract(address target, address usr) public auth {
        AuthLike(target).rely(usr);
    }

    function denyContract(address target, address usr) public auth {
        AuthLike(target).deny(usr);
    }

}