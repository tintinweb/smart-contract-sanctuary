/**
 *Submitted for verification at Etherscan.io on 2021-03-11
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

interface CoordinatorLike {
    function file(bytes32 name, uint value) external;
    function minimumEpochTime() external returns(uint);
}

interface NAVFeedLike {
    function file(bytes32 name, uint value) external;
    function file(bytes32 name, uint risk_, uint thresholdRatio_, uint ceilingRatio_, uint rate_, uint recoveryRatePD_) external;
    function discountRate() external returns(uint);
}

// This spell fixes the permissions and risk groups of the FC1 pool
contract TinlakeSpell {

    bool public done;
    string constant public description = "Tinlake Mainnet Spell";

    // FC1 root contracts
    address constant public ROOT = 0x714D520CfAC2027834c8Af8ffc901855c3aD41Ec;
    address constant public SENIOR_MEMBERLIST = 0xD0f425753437176923477F5b310bbd1a2e0A4253;
    address constant public JUNIOR_MEMBERLIST = 0x0F8129ce11653ED7fb83B60d8580b86022Bf0aeF;
    address constant public ASSESSOR = 0xab321CDc90b8882D19c2866b377b450284501219;
    address constant public ASSESSOR_ADMIN = 0x1C422e1cf17CCDBb78A795EfeA637d569C830c1d;
    address constant public FEED = 0x30E3f738f22f5a4671d1252793deB6e657e4b8AA;
    address constant public COORDINATOR = 0x44E9868B37e93F560Deccd5d8d62b26bC62Dce2d;
    address constant public PILE = 0x99D0333f97432fdEfA25B7634520d505e58B131B;
   
    // permissions to be set
    address constant public ADMIN_TO_BE_REMOVED = 0x0A735602a357802f553113F5831FE2fbf2F0E2e0;
    address constant public NEW_ADMIN1 = 0xcC7f213f835875175ec150c07AC774D57200f4d8;
    address constant public NEW_ADMIN2 = 0x71d9f8CFdcCEF71B59DD81AB387e523E2834F2b8;
    address constant public NEW_ADMIN3 = 0xa7Aa917b502d86CD5A23FFbD9Ee32E013015e069;
    address constant public NEW_ADMIN4 = 0xfEADaD6b75e6C899132587b7Cb3FEd60c8554821;
    address constant public NEW_ADMIN5 = 0xC3997Ef807A24af6Ca5Cb1d22c2fD87C6c3b79E8;
    address constant public NEW_ADMIN6 = 0xd60f7CFC1E051d77031aC21D9DB2F66fE54AE312;
    address constant public ORACLE = 0xCbd552356e4C2865387a4470D872265cD0FEFB34;

    // new minEpochTime
    uint constant public minEpochTime = 1 days - 10 minutes;

    uint256 constant ONE = 10**27;

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
      TinlakeRootLike root = TinlakeRootLike(address(ROOT));
      CoordinatorLike coordinator = CoordinatorLike(address(COORDINATOR));
      NAVFeedLike navFeed = NAVFeedLike(address(FEED));

      // Setup
      root.relyContract(COORDINATOR, address(this)); // required to modify min epoch time
      root.relyContract(FEED, address(this)); // required to file riskGroups

      // Fix config
      coordinator.file("minimumEpochTime", minEpochTime);

      // File risk groups
      // risk group: 5, APR: 12.000%%
      navFeed.file("riskGroup", 5, ONE, 75 * 10 ** 25, uint(1000000003805175038051750380), 99.9589*10**25);

      // Remove incorrect permissions
      root.denyContract(SENIOR_MEMBERLIST, ADMIN_TO_BE_REMOVED);
      root.denyContract(JUNIOR_MEMBERLIST, ADMIN_TO_BE_REMOVED);
      root.denyContract(ASSESSOR, ADMIN_TO_BE_REMOVED);
      root.denyContract(ASSESSOR_ADMIN, ADMIN_TO_BE_REMOVED);
      root.denyContract(FEED, ADMIN_TO_BE_REMOVED);
      root.denyContract(COORDINATOR, ADMIN_TO_BE_REMOVED);
    
      // Add correct permissions
      root.relyContract(ASSESSOR_ADMIN, NEW_ADMIN1);
      root.relyContract(ASSESSOR_ADMIN, NEW_ADMIN2);
      root.relyContract(ASSESSOR_ADMIN, NEW_ADMIN3);
      root.relyContract(ASSESSOR_ADMIN, NEW_ADMIN4);
      root.relyContract(ASSESSOR_ADMIN, NEW_ADMIN5);
      root.relyContract(ASSESSOR_ADMIN, NEW_ADMIN6);

      root.relyContract(JUNIOR_MEMBERLIST, NEW_ADMIN1);
      root.relyContract(JUNIOR_MEMBERLIST, NEW_ADMIN2);
      root.relyContract(JUNIOR_MEMBERLIST, NEW_ADMIN3);
      root.relyContract(JUNIOR_MEMBERLIST, NEW_ADMIN4);
      root.relyContract(JUNIOR_MEMBERLIST, NEW_ADMIN5);
      root.relyContract(JUNIOR_MEMBERLIST, NEW_ADMIN6);

      root.relyContract(SENIOR_MEMBERLIST, NEW_ADMIN1);
      root.relyContract(SENIOR_MEMBERLIST, NEW_ADMIN2);
      root.relyContract(SENIOR_MEMBERLIST, NEW_ADMIN3);
      root.relyContract(SENIOR_MEMBERLIST, NEW_ADMIN4);
      root.relyContract(SENIOR_MEMBERLIST, NEW_ADMIN5);
      root.relyContract(SENIOR_MEMBERLIST, NEW_ADMIN6);

      root.relyContract(FEED, ORACLE);
    }   
}