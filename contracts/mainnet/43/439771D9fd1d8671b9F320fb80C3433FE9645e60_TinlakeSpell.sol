/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/spell.sol
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.6.12 >=0.7.0;

////// src/addresses_ff1.sol

/* pragma solidity >=0.7.0; */

// Gig Pool 1 addresses at Tue 05 Oct 2021 15:56:31 CEST
contract Addresses {
	address public ROOT = 0x4B6CA198d257D755A5275648D471FE09931b764A;
	address public TINLAKE_CURRENCY = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
	address public ASSESSOR = 0xCC2cA000DB7Df0499667ca4048987727151b0b1f;
	address public RESERVE = 0xd9Cec614db2b5A7490dF2462A4621D96bCD4bfE2;
	address public SENIOR_TRANCHE = 0xfc9E18e714c21539456d5f77F7F635781Cf56Af0;
	address public JUNIOR_TRANCHE = 0x7DA307394B052Af46Aba415289db24177B754C7e;
	address public SENIOR_MEMBERLIST = 0x6e79770F8B57cAd29D29b1884563556B31E792b0;
	address public JUNIOR_MEMBERLIST = 0x3FBD11B1f91765B32BD1231922F1E32f6bdfCB1c;
	address public SENIOR_TOKEN = 0x44718d306a8Fa89545704Ae38B2B97c06bF11FC1;
	address public FEED = 0xcAB9ed8e5EF4607A97f4e22Ad1D984ADB93ce890;
	address public MGR = 0x5b702e1fEF3F556cbe219eE697D7f170A236cc66;
    address public VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address public JUG = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address public SPOTTER = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
	address public CLERK_OLD = 0x04140410249C4e9bB85f948135671Af30D941034;
	address public COORDINATOR_OLD = 0x9dA6Ff36Fc054b7FD2F72935DD3A9cFbFc00B8B6;	
	address public POOL_ADMIN_OLD = 0x20ca8D29F1ad57e85A73c2aA99dFF46241C94A1A;
}



////// src/spell.sol
/* pragma solidity >=0.6.12; */

/* import "./addresses_ff1.sol"; */

////// src/spell.sol
/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/spell.sol

/* pragma solidity >=0.6.12; */

////// src/spell.sol
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
/* pragma solidity >=0.6.12; */

interface AuthLike {
    function rely(address) external;
    function deny(address) external;
    function wards(address) external returns(uint);
}

interface TinlakeRootLike {
    function relyContract(address, address) external;
    function denyContract(address, address) external;
}

interface FileLike {
    function file(bytes32, uint) external;
    function file(bytes32, address) external;
}

interface DependLike {
    function depend(bytes32, address) external;
}

interface MigrationLike {
        function migrate(address) external;
}

interface SpellMemberlistLike {
    function updateMember(address, uint) external;
}

interface PoolAdminLike {
    function setAdminLevel(address usr, uint level) external;
}

interface PoolRegistryLike {
    function file(address, bool, string memory, string memory) external;
    function find(address pool) external view returns (bool live, string memory name, string memory data);
}

// spell to swap clerk, coordinator & poolAdmin
contract TinlakeSpell is Addresses {

    bool public done;
    string constant public description = "Tinlake GigPool spell";

    // MAINNET ADDRESSES
    // The contracts in this list should correspond to a tinlake deployment
    // https://github.com/centrifuge/tinlake-pool-config/blob/master/mainnet-production.json

    address public CLERK = 0x8Cc9fCb43620DdB9b1573Cf9a94a6E7c167e6125;
    address public COORDINATOR = 0xA92c94818473F3583aDc69B85767949B2103eff7;
    address public POOL_ADMIN = 0x9033540ceda3C436C0a62CBAD682f8F4fc75F287;

    address public MEMBER_ADMIN = 0xB7e70B77f6386Ffa5F55DDCb53D87A0Fb5a2f53b;
    address public LEVEL3_ADMIN1 = 0x7b74bb514A1dEA0Ec3763bBd06084e712c8bce97;
    address public LEVEL1_ADMIN1 = 0x71d9f8CFdcCEF71B59DD81AB387e523E2834F2b8;
    address public LEVEL1_ADMIN2 = 0x46a71eEf8DbcFcbAC7A0e8D5d6B634A649e61fb8;
    address public LEVEL1_ADMIN3 = 0x9eDec77dd2651Ce062ab17e941347018AD4eAEA9;
    address public LEVEL1_ADMIN4 = 0xEf270f8877Aa1875fc13e78dcA31f3235210368f;
    address public LEVEL1_ADMIN5 = 0xddEa1De10E93c15037E83b8Ab937A46cc76f7009;
    address public AO_POOL_ADMIN = 0xB170597E474CC124aE8Fe2b335d0d80E08bC3e37;

    address public POOL_REGISTRY = 0xddf1C516Cf87126c6c610B52FD8d609E67Fb6033;

    string constant public IPFS_HASH = "Qmbb8UAtouEHUkZXwUWH1GLJnDPBqxccF43rjrWpjiTkRo";

    uint256 constant ONE = 10**27;
    address self;
    
    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
       TinlakeRootLike root = TinlakeRootLike(address(ROOT));
       self = address(this);
       // permissions 
       root.relyContract(CLERK, self); // required to file riskGroups & change discountRate
       root.relyContract(CLERK_OLD, self); // required to change the interestRates for loans according to new riskGroups
       root.relyContract(SENIOR_TRANCHE, self);
       root.relyContract(SENIOR_TOKEN, self);
       root.relyContract(SENIOR_TRANCHE, self);
       root.relyContract(JUNIOR_TRANCHE, self);
       root.relyContract(SENIOR_MEMBERLIST, self);
       root.relyContract(JUNIOR_MEMBERLIST, self);
       root.relyContract(POOL_ADMIN, self);
       root.relyContract(ASSESSOR, self);
       root.relyContract(COORDINATOR, self);
       root.relyContract(COORDINATOR_OLD, self);
       root.relyContract(RESERVE, self);
       root.relyContract(MGR, self);
       root.relyContract(FEED, self);
       
       migrateClerk();
       migrateCoordinator();
       migratePoolAdmin();
       updateRegistry();
     }  

    function migrateCoordinator() internal {
        // migrate state
        MigrationLike(COORDINATOR).migrate(COORDINATOR_OLD);

        // migrate dependencies
        DependLike(COORDINATOR).depend("assessor", ASSESSOR);
        DependLike(COORDINATOR).depend("juniorTranche", JUNIOR_TRANCHE);
        DependLike(COORDINATOR).depend("seniorTranche", SENIOR_TRANCHE);

        DependLike(CLERK).depend("coordinator", COORDINATOR);

        DependLike(SENIOR_TRANCHE).depend("coordinator", COORDINATOR);
        DependLike(JUNIOR_TRANCHE).depend("coordinator", COORDINATOR);

        // migrate permissions
        AuthLike(ASSESSOR).rely(COORDINATOR); 
        AuthLike(ASSESSOR).deny(COORDINATOR_OLD);
        AuthLike(JUNIOR_TRANCHE).rely(COORDINATOR); 
        AuthLike(JUNIOR_TRANCHE).deny(COORDINATOR_OLD); 
        AuthLike(SENIOR_TRANCHE).rely(COORDINATOR);
        AuthLike(SENIOR_TRANCHE).deny(COORDINATOR_OLD);
     }

    function migratePoolAdmin() internal {
        // setup dependencies 
        DependLike(POOL_ADMIN).depend("assessor", ASSESSOR);
        // DependLike(POOL_ADMIN).depend("lending", CLERK); // set in clerk migration
        DependLike(POOL_ADMIN).depend("seniorMemberlist", SENIOR_MEMBERLIST);
        DependLike(POOL_ADMIN).depend("juniorMemberlist", JUNIOR_MEMBERLIST);
        DependLike(POOL_ADMIN).depend("navFeed", FEED);
        DependLike(POOL_ADMIN).depend("coordinator", COORDINATOR);

        // setup permissions
        AuthLike(ASSESSOR).rely(POOL_ADMIN);
        AuthLike(ASSESSOR).deny(POOL_ADMIN_OLD);
        // AuthLike(CLERK).rely(POOL_ADMIN); // set in clerk migration
        // AuthLike(CLERK).deny(POOL_ADMIN_OLD);
        AuthLike(JUNIOR_MEMBERLIST).rely(POOL_ADMIN);
        AuthLike(JUNIOR_MEMBERLIST).deny(POOL_ADMIN_OLD);
        AuthLike(SENIOR_MEMBERLIST).rely(POOL_ADMIN);
        AuthLike(SENIOR_MEMBERLIST).deny(POOL_ADMIN_OLD);
        AuthLike(FEED).rely(POOL_ADMIN);
        AuthLike(FEED).deny(POOL_ADMIN_OLD);
        AuthLike(COORDINATOR).rely(POOL_ADMIN);
        AuthLike(COORDINATOR).deny(POOL_ADMIN_OLD);

        // set lvl3 admins
        AuthLike(POOL_ADMIN).rely(LEVEL3_ADMIN1);
        // set lvl1 admins
        PoolAdminLike(POOL_ADMIN).setAdminLevel(LEVEL1_ADMIN1, 1);
        PoolAdminLike(POOL_ADMIN).setAdminLevel(LEVEL1_ADMIN2, 1);
        PoolAdminLike(POOL_ADMIN).setAdminLevel(LEVEL1_ADMIN3, 1);
        PoolAdminLike(POOL_ADMIN).setAdminLevel(LEVEL1_ADMIN4, 1);
        PoolAdminLike(POOL_ADMIN).setAdminLevel(LEVEL1_ADMIN5, 1);
        PoolAdminLike(POOL_ADMIN).setAdminLevel(AO_POOL_ADMIN, 1);
        AuthLike(JUNIOR_MEMBERLIST).rely(MEMBER_ADMIN);
        AuthLike(SENIOR_MEMBERLIST).rely(MEMBER_ADMIN);
    }

    function migrateClerk() internal {
        // migrate state
        MigrationLike(CLERK).migrate(CLERK_OLD);
    
        // dependencies
        DependLike(CLERK).depend("assessor", ASSESSOR);
        DependLike(CLERK).depend("mgr", MGR);
        DependLike(CLERK).depend("coordinator", COORDINATOR);
        DependLike(CLERK).depend("reserve", RESERVE); 
        DependLike(CLERK).depend("tranche", SENIOR_TRANCHE);
        DependLike(CLERK).depend("collateral", SENIOR_TOKEN);
        DependLike(CLERK).depend("spotter", SPOTTER);
        DependLike(CLERK).depend("vat", VAT);
        DependLike(CLERK).depend("jug", JUG);

        // permissions
        AuthLike(CLERK).rely(RESERVE);
        AuthLike(CLERK).rely(POOL_ADMIN);
        AuthLike(SENIOR_TRANCHE).rely(CLERK);
        AuthLike(RESERVE).rely(CLERK);
        AuthLike(ASSESSOR).rely(CLERK);
        AuthLike(MGR).rely(CLERK);

        // adjust autohealing tolerance to unblock epoch exec
        FileLike(CLERK).file("autoHealMax", 3000 ether);

        FileLike(MGR).file("owner", CLERK);

        DependLike(ASSESSOR).depend("lending", CLERK);
        DependLike(RESERVE).depend("lending", CLERK);
        DependLike(POOL_ADMIN).depend("lending", CLERK);
       
        // restricted token setup
        SpellMemberlistLike(SENIOR_MEMBERLIST).updateMember(CLERK, uint(-1));

        // remove old clerk
        AuthLike(SENIOR_TRANCHE).deny(CLERK_OLD);
        AuthLike(RESERVE).deny(CLERK_OLD);
        AuthLike(ASSESSOR).deny(CLERK_OLD);
        AuthLike(MGR).deny(CLERK_OLD);
    }

    function updateRegistry() internal {
        PoolRegistryLike(POOL_REGISTRY).file(ROOT, true, "fortunafi-1", IPFS_HASH);
    }
}