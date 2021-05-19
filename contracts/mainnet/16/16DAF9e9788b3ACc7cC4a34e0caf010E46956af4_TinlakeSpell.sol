/**
 *Submitted for verification at Etherscan.io on 2021-05-18
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

interface TinlakeRootLike {
    function relyContract(address, address) external;
    function denyContract(address, address) external;
}

interface PoolAdminLike {
    function depend(bytes32, address) external;
    function relyAdmin(address) external;
    function deny(address) external;
}

contract TinlakeSpell {

    bool public done;
    string constant public description = "NS2 PoolAdmin Swap";

    // NS2 contracts
    address constant public ROOT = 0x53b2d22d07E069a3b132BfeaaD275b10273d381E;
    address constant public POOL_ADMIN_OLD = 0x6A82DdF0DF710fACD0414B37606dC9Db05a4F752;
    address constant public POOL_ADMIN_NEW = 0xd7fb14d5C1259a47d46D156E74a9c3B69a147b4A;
    address constant public ASSESSOR = 0x83E2369A33104120746B589Cc90180ed776fFb91;
    address constant public CLERK = 0xA9eCF012dD36512e5fFCD5585D72386E46135Cdd;
    address constant public SENIOR_MEMBERLIST = 0x5B5CFD6E45F1407ABCb4BFD9947aBea1EA6649dA;
    address constant public JUNIOR_MEMBERLIST = 0x42C2483EEE8c1Fe46C398Ac296C59674F9eb88CD;

    // Admins
    address constant public ADMIN1 = 0x71d9f8CFdcCEF71B59DD81AB387e523E2834F2b8;
    address constant public ADMIN2 = 0x46a71eEf8DbcFcbAC7A0e8D5d6B634A649e61fb8;
    address constant public ADMIN3 = 0xa7Aa917b502d86CD5A23FFbD9Ee32E013015e069;
    address constant public ADMIN4 = 0x9eDec77dd2651Ce062ab17e941347018AD4eAEA9;
    address constant public ADMIN5 = 0xd60f7CFC1E051d77031aC21D9DB2F66fE54AE312;
    address constant public ADMIN6 = 0x7Cae9bD865610750a48575aF15CAFe1e460c96a8;

    address constant public DEPLOYER = 0x3018F3F7a1a919Fd9a1e0D8FEDbe9164B6DF04f6;
    
    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
        TinlakeRootLike root = TinlakeRootLike(address(ROOT));
        PoolAdminLike poolAdmin = PoolAdminLike(address(POOL_ADMIN_NEW));

        root.relyContract(POOL_ADMIN_NEW, address(this));
        root.relyContract(ASSESSOR, POOL_ADMIN_NEW);
        root.relyContract(CLERK, POOL_ADMIN_NEW);
        root.relyContract(SENIOR_MEMBERLIST, POOL_ADMIN_NEW);
        root.relyContract(JUNIOR_MEMBERLIST, POOL_ADMIN_NEW);

        root.denyContract(ASSESSOR, POOL_ADMIN_OLD);
        root.denyContract(CLERK, POOL_ADMIN_OLD);
        root.denyContract(SENIOR_MEMBERLIST, POOL_ADMIN_OLD);
        root.denyContract(JUNIOR_MEMBERLIST, POOL_ADMIN_OLD);

        poolAdmin.depend("assessor", ASSESSOR);
        poolAdmin.depend("lending", CLERK);
        poolAdmin.depend("seniorMemberlist", SENIOR_MEMBERLIST);
        poolAdmin.depend("juniorMemberlist", JUNIOR_MEMBERLIST);

        poolAdmin.relyAdmin(ADMIN1);
        poolAdmin.relyAdmin(ADMIN2);
        poolAdmin.relyAdmin(ADMIN3);
        poolAdmin.relyAdmin(ADMIN4);
        poolAdmin.relyAdmin(ADMIN5);
        poolAdmin.relyAdmin(ADMIN6);

        poolAdmin.deny(DEPLOYER);
    }   
}