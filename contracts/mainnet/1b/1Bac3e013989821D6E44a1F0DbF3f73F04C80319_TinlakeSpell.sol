/**
 *Submitted for verification at Etherscan.io on 2021-11-17
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/spell.sol

pragma solidity >=0.6.12;

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

// spell to swap the clerk contract in NS2 deployment
contract TinlakeSpell {

    bool public done;
    string constant public description = "Tinlake GigPool spell";

    // MAINNET ADDRESSES
    // The contracts in this list should correspond to a tinlake deployment
    // https://github.com/centrifuge/tinlake-pool-config/blob/master/mainnet-production.json

    address constant public ROOT = 0x53b2d22d07E069a3b132BfeaaD275b10273d381E;
    address constant public CLERK_OLD = 0xA9eCF012dD36512e5fFCD5585D72386E46135Cdd;
    address constant public COORDINATOR = 0x22a1caca2EE82e9cE7Ef900FD961891b66deB7cA;
    address constant public RESERVE = 0x1f5Fa2E665609CE4953C65CE532Ac8B47EC97cD5;
    address constant public SENIOR_TRANCHE = 0x3f06DB6334435fF4150e14aD69F6280BF8E8dA64;
    address constant public SENIOR_MEMBERLIST = 0x5B5CFD6E45F1407ABCb4BFD9947aBea1EA6649dA;
    address constant public SENIOR_TOKEN = 0xE4C72b4dE5b0F9ACcEA880Ad0b1F944F85A9dAA0;
    address constant public ASSESSOR = 0x83E2369A33104120746B589Cc90180ed776fFb91;
    address constant public MGR = 0x2474F297214E5d96Ba4C81986A9F0e5C260f445D;
    address constant public VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant public JUG = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant public SPOTTER = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address constant public CLERK = 0xfE27bAA63592CCF1E09550fc489342b5817388B5;
    address constant public POOL_ADMIN = 0xd7fb14d5C1259a47d46D156E74a9c3B69a147b4A;

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
       root.relyContract(SENIOR_MEMBERLIST, self);
       root.relyContract(POOL_ADMIN, self);
       root.relyContract(ASSESSOR, self);
       root.relyContract(COORDINATOR, self);
       root.relyContract(RESERVE, self);
       root.relyContract(MGR, self);
       
       migrateClerk();
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

        FileLike(MGR).file("owner", CLERK);

        DependLike(ASSESSOR).depend("clerk", CLERK); 
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
}