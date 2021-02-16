/**
 *Submitted for verification at Etherscan.io on 2021-02-15
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
}

contract MemberlistLike {
    function rely(address) external;
}

contract MemberAdminLike {
    function relyAdmin(address) external;
    function admins(address) external returns(uint);
}

// This spell adds wards to all memberlists
contract TinlakeSpell {

    bool public done;
    string constant public description = "Tinlake Mainnet Spell";

    // MAINNET ADDRESSES
    // Member admin contract
    address constant public MEMBERADMIN = 0xB7e70B77f6386Ffa5F55DDCb53D87A0Fb5a2f53b;
   
    // Active memberlists
    address constant public ROOT_BL1 = 0x0CED6166873038Ac0cc688e7E6d19E2cBE251Bf0;
    address constant public SENIOR_MEMBERLIST_BL1 = 0x9b0b65ad4b477F38864BE014abd40C97c385a2dd;
    address constant public JUNIOR_MEMBERLIST_BL1 = 0x000620c6ef2996b2107d91707830751AcaFF90Bb;

    address constant public ROOT_CF4 = 0xdB3bC9fB1893222d266762e9fF857EB74D75c7D6;
    address constant public SENIOR_MEMBERLIST_CF4 = 0x26129802A858F3C28553f793E1008b8338e6aEd2;
    address constant public JUNIOR_MEMBERLIST_CF4 = 0x4CA09F24f3342327da42d2b6035af741fC1AeB4A;

    address constant public ROOT_DBF1 = 0xfc2950dD337ca8496C18dfc0256Fb905A7E7E5c6;
    address constant public SENIOR_MEMBERLIST_DBF1 = 0x58e211AFED5843813dD09F185A0eb0bdb6BbCa72;
    address constant public JUNIOR_MEMBERLIST_DBF1 = 0xfaEea82d9Db2737B959e3BeF985A91c90abC9486;

    address constant public ROOT_FF1 = 0x4B6CA198d257D755A5275648D471FE09931b764A;
    address constant public SENIOR_MEMBERLIST_FF1 = 0x6e79770F8B57cAd29D29b1884563556B31E792b0;
    address constant public JUNIOR_MEMBERLIST_FF1 = 0x3FBD11B1f91765B32BD1231922F1E32f6bdfCB1c;

    address constant public ROOT_HTC2 = 0x4cA805cE8EcE2E63FfC1F9f8F2731D3F48DF89Df;
    address constant public SENIOR_MEMBERLIST_HTC2 = 0x1Bc55bcAf89f514CE5a8336bEC7429a99e804910;
    address constant public JUNIOR_MEMBERLIST_HTC2 = 0x0b635CD35fC3AF8eA29f84155FA03dC9AD0Bab27;

    address constant public ROOT_NS2 = 0x53b2d22d07E069a3b132BfeaaD275b10273d381E;
    address constant public SENIOR_MEMBERLIST_NS2 = 0x5B5CFD6E45F1407ABCb4BFD9947aBea1EA6649dA;
    address constant public JUNIOR_MEMBERLIST_NS2 = 0x42C2483EEE8c1Fe46C398Ac296C59674F9eb88CD;

    address constant public ROOT_PC3 = 0x82B8617A16e388256617FeBBa1826093401a3fE5;
    address constant public SENIOR_MEMBERLIST_PC3 = 0x1770129cd23C680C1c52C8D3a9c3D527B73CE1de;
    address constant public JUNIOR_MEMBERLIST_PC3 = 0xA768ACDe6B95720ba926E4a615ACA733e51F6FD1;
   
    // Onboard API admin account
    address constant public ONBOARD_API = 0x264AEcFa131f880eE885f034C26bD67c52c3EC1d;   

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
        // Make ward on all memberlists
        TinlakeRootLike rootBL1 = TinlakeRootLike(address(ROOT_BL1));
        rootBL1.relyContract(SENIOR_MEMBERLIST_BL1, MEMBERADMIN);
        rootBL1.relyContract(JUNIOR_MEMBERLIST_BL1, MEMBERADMIN);

        TinlakeRootLike rootCF4 = TinlakeRootLike(address(ROOT_CF4));
        rootCF4.relyContract(SENIOR_MEMBERLIST_CF4, MEMBERADMIN);
        rootCF4.relyContract(JUNIOR_MEMBERLIST_CF4, MEMBERADMIN);

        TinlakeRootLike rootDBF1 = TinlakeRootLike(address(ROOT_DBF1));
        rootDBF1.relyContract(SENIOR_MEMBERLIST_DBF1, MEMBERADMIN);
        rootDBF1.relyContract(JUNIOR_MEMBERLIST_DBF1, MEMBERADMIN);

        TinlakeRootLike rootFF1 = TinlakeRootLike(address(ROOT_FF1));
        rootFF1.relyContract(SENIOR_MEMBERLIST_FF1, MEMBERADMIN);
        rootFF1.relyContract(JUNIOR_MEMBERLIST_FF1, MEMBERADMIN);

        TinlakeRootLike rootHTC2 = TinlakeRootLike(address(ROOT_HTC2));
        rootHTC2.relyContract(SENIOR_MEMBERLIST_HTC2, MEMBERADMIN);
        rootHTC2.relyContract(JUNIOR_MEMBERLIST_HTC2, MEMBERADMIN);

        TinlakeRootLike rootNS2 = TinlakeRootLike(address(ROOT_NS2));
        rootNS2.relyContract(SENIOR_MEMBERLIST_NS2, MEMBERADMIN);
        rootNS2.relyContract(JUNIOR_MEMBERLIST_NS2, MEMBERADMIN);

        TinlakeRootLike rootPC3 = TinlakeRootLike(address(ROOT_PC3));
        rootPC3.relyContract(SENIOR_MEMBERLIST_PC3, MEMBERADMIN);
        rootPC3.relyContract(JUNIOR_MEMBERLIST_PC3, MEMBERADMIN);

        // Make onboard API an admin on the memberadmin
        MemberAdminLike(address(MEMBERADMIN)).relyAdmin(ONBOARD_API);
    }   
}