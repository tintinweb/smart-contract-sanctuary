/**
 *Submitted for verification at Etherscan.io on 2021-06-03
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
pragma experimental ABIEncoderV2;

// TODO: split interfaces between tests and spell. Exclude all the function that afre only used in tests
interface SpellTinlakeRootLike {
    function relyContract(address, address) external;
}

interface SpellMemberlistLike {
    function updateMember(address, uint) external;
}

interface SpellReserveLike {
    function payout(uint currencyAmount) external;
}

interface DependLike {
    function depend(bytes32, address) external;
}

interface FileLike {
    function file(bytes32, uint) external;
    function file(bytes32, address) external;
}

interface AuthLike {
    function rely(address) external;
    function deny(address) external;
}

interface MigrationLike {
    function migrate(address) external;
}

interface TrancheLike {
    function totalSupply() external returns(uint);
    function totalRedeem() external returns(uint);
}

interface PoolAdminLike {
    function relyAdmin(address) external;
}

interface MgrLike {
    function lock(uint) external;
}

interface SpellERC20Like {
    function balanceOf(address) external view returns (uint256);
    function transferFrom(address, address, uint) external returns (bool);
    function approve(address, uint) external;
}

// spell for: ns2 tranche migration
contract TinlakeSpell {

// {
//   "DEPLOYMENT_NAME": "NewSilver 2 mainnet deployment",
//   "ROOT_CONTRACT": "0x53b2d22d07E069a3b132BfeaaD275b10273d381E",
//   "TINLAKE_CURRENCY": "0x6b175474e89094c44da98b954eedeac495271d0f",
//   "BORROWER_DEPLOYER": "0x9137BFdbB43BDf83DB5B8e691B5D2ceBE6475392",
//   "TITLE_FAB": "0x8bA230C8b7C6B4C5d6A1bfC53B4d992CD0963661",
//   "SHELF_FAB": "0xEa66cD92CaFF63c82A31BAa2BdA274ACbBA6323a",
//   "PILE_FAB": "0xc1C9330Fcc5694B902CB27bCB615fB126DfACc55",
//   "COLLECTOR_FAB": "0x7d882A8513C9cf5D7623222607Ea67a6C03676d2",
//   "FEED_FAB": "0xC2f81D0e9744ca806f024c884FD18462Ce787550",
//   "TITLE": "0x07cdD617c53B07208b0371C93a02deB8d8D49C6e",
//   "PILE": "0x3eC5c16E7f2C6A80E31997C68D8Fa6ACe089807f",
//   "SHELF": "0x7d057A056939bb96D682336683C10EC89b78D7CE",
//   "COLLECTOR": "0x62f290512c690a817f47D2a4a544A5d48D1408BE",
//   "FEED": "0x41fAD1Eb242De19dA0206B0468763333BB6C2B3D",
//   "LENDER_DEPLOYER": "0xed0d554A3125E79B9E77A919c7cc651d235A3B1A",
//   "OPERATOR_FAB": "0x782436a28B5d45645C8b56f4456f1593AF29FD8f",
//   "ASSESSOR_FAB": "0xc2ACC63c37634f37a8Fa26F041CC2FA4331a3184",
//   "ASSESSOR_ADMIN_FAB": "0xcA0fA916eB9003AD35d1356bE867c0CF28a9aab4",
//   "COORDINATOR_FAB": "0x2b0E830af4353CDeED11E3FB32b35E67a6641162",
//   "TRANCHE_FAB": "0xFA75dFDa070dC69EadCD6eb17fE08BAECBa23C88",
//   "MEMBERLIST_FAB": "0x7E3bd3ee54febd930DA077479093C527F11d1729",
//   "RESTRICTEDTOKEN_FAB": "0x0e9A86D770EDa4dea6c1d7C8cd23245318F4327a",
//   "RESERVE_FAB": "0x067129E2D2f1aE84B1014c33C54eAE92D18A5454",
//   "JUNIOR_OPERATOR": "0x4c4Cc6a0573db5823ECAA1d1d65EB64E5E0E5F01",
//   "SENIOR_OPERATOR": "0x230f2E19D6c2Dc0c441c2150D4dD9d67B563A60C",
//   "JUNIOR_TRANCHE": "0x7cD2a6Be6ca8fEB02aeAF08b7F350d7248dA7707",
//   "SENIOR_TRANCHE": "0x636214f455480D19F17FE1aa45B9989C86041767",
//   "JUNIOR_TOKEN": "0x961e1d4c9A7C0C3e05F17285f5FA34A66b62dBb1",
//   "SENIOR_TOKEN": "0xE4C72b4dE5b0F9ACcEA880Ad0b1F944F85A9dAA0",
//   "JUNIOR_MEMBERLIST": "0x42C2483EEE8c1Fe46C398Ac296C59674F9eb88CD",
//   "SENIOR_MEMBERLIST": "0x5B5CFD6E45F1407ABCb4BFD9947aBea1EA6649dA",
//   "ASSESSOR": "0x83E2369A33104120746B589Cc90180ed776fFb91",
//   "ASSESSOR_ADMIN": "0x46470030e1c732A9C2b541189471E47661311375",
//   "COORDINATOR": "0xcC7AFB5DeED34CF67E72d4C53B142F44c9268ab9",
//   "RESERVE": "0xD9E4391cF31638a8Da718Ff0Bf69249Cdc48fB2B",
//   "GOVERNANCE": "0xf3BceA7494D8f3ac21585CA4b0E52aa175c24C25",
//   "MAIN_DEPLOYER": "0x1a5a533BcF4ef8A884732056f413114159d03058",
//   "CLERK": "0xA9eCF012dD36512e5fFCD5585D72386E46135Cdd",
//   "MAKER_MGR": "0x2474F297214E5d96Ba4C81986A9F0e5C260f445D",
//   "COMMIT_HASH": "fc1f8e275a9d05d877e64f46810c107cde0808ce",
// }

// senior
// dapp create 'src/lender/tranche.sol:Tranche' 0x6b175474e89094c44da98b954eedeac495271d0f 0xE4C72b4dE5b0F9ACcEA880Ad0b1F944F85A9dAA0
// 0x3f06DB6334435fF4150e14aD69F6280BF8E8dA64
// junior
// dapp create 'src/lender/tranche.sol:Tranche' 0x6b175474e89094c44da98b954eedeac495271d0f 0x961e1d4c9A7C0C3e05F17285f5FA34A66b62dBb1
// 0x53CF3CCd97CA914F9e441B8cd9A901E69B170f27

    bool public done;
    string constant public description = "Tinlake NS2 migration mainnet Spell";

    address constant public ROOT = 0x53b2d22d07E069a3b132BfeaaD275b10273d381E;
    address constant public SENIOR_TOKEN = 0xE4C72b4dE5b0F9ACcEA880Ad0b1F944F85A9dAA0;
    address constant public JUNIOR_TOKEN = 0x961e1d4c9A7C0C3e05F17285f5FA34A66b62dBb1;
    address constant public SENIOR_OPERATOR = 0x230f2E19D6c2Dc0c441c2150D4dD9d67B563A60C;
    address constant public JUNIOR_OPERATOR = 0x4c4Cc6a0573db5823ECAA1d1d65EB64E5E0E5F01;

    address constant public ASSESSOR = 0x83E2369A33104120746B589Cc90180ed776fFb91;
    address constant public COORDINATOR = 0xcC7AFB5DeED34CF67E72d4C53B142F44c9268ab9;
    address constant public RESERVE = 0xD9E4391cF31638a8Da718Ff0Bf69249Cdc48fB2B;

    address constant public CLERK = 0xA9eCF012dD36512e5fFCD5585D72386E46135Cdd;
    address constant public MGR =  0x2474F297214E5d96Ba4C81986A9F0e5C260f445D;

    address constant public SENIOR_TRANCHE_OLD = 0x636214f455480D19F17FE1aa45B9989C86041767;
    address constant public JUNIOR_TRANCHE_OLD = 0x7cD2a6Be6ca8fEB02aeAF08b7F350d7248dA7707;
    address constant public TINLAKE_CURRENCY = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI

    // new contracts -> to be migrated
    address constant public SENIOR_TRANCHE_NEW = 0x3f06DB6334435fF4150e14aD69F6280BF8E8dA64;
    address constant public JUNIOR_TRANCHE_NEW = 0x53CF3CCd97CA914F9e441B8cd9A901E69B170f27;

    address self;

    // permissions to be set
    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
        SpellTinlakeRootLike root = SpellTinlakeRootLike(ROOT);
        self = address(this);
        // set spell as ward on the core contract to be able to wire the new contracts correctly
        root.relyContract(JUNIOR_TRANCHE_OLD, self);
        root.relyContract(SENIOR_TRANCHE_OLD, self);
        root.relyContract(SENIOR_TRANCHE_NEW, self);
        root.relyContract(JUNIOR_TRANCHE_NEW, self);
        root.relyContract(SENIOR_OPERATOR, self);
        root.relyContract(JUNIOR_OPERATOR, self);
        root.relyContract(SENIOR_TOKEN, self);
        root.relyContract(JUNIOR_TOKEN, self);

        root.relyContract(ASSESSOR, self);
        root.relyContract(COORDINATOR, self);
        root.relyContract(RESERVE, self);

        root.relyContract(CLERK, self);
        root.relyContract(MGR, self);

        // contract migration --> assumption: root contract is already ward on the new contracts
        migrateTranches();
    }

    function migrateTranches() internal {

        // senior
        TrancheLike seniorTranche = TrancheLike(SENIOR_TRANCHE_NEW);
        require((seniorTranche.totalSupply() == 0 && seniorTranche.totalRedeem() == 0), "senior-tranche-has-orders");

        // dependencies
        DependLike(SENIOR_TRANCHE_NEW).depend("reserve", RESERVE);
        DependLike(SENIOR_TRANCHE_NEW).depend("epochTicker", COORDINATOR);
        DependLike(SENIOR_OPERATOR).depend("tranche", SENIOR_TRANCHE_NEW);
        DependLike(ASSESSOR).depend("seniorTranche", SENIOR_TRANCHE_NEW);
        DependLike(COORDINATOR).depend("seniorTranche", SENIOR_TRANCHE_NEW);
        DependLike(CLERK).depend("tranche", SENIOR_TRANCHE_NEW);
        FileLike(MGR).file("tranche", SENIOR_TRANCHE_NEW);

        // permissions
        AuthLike(SENIOR_TRANCHE_NEW).rely(SENIOR_OPERATOR);
        AuthLike(SENIOR_TRANCHE_NEW).rely(COORDINATOR);
        AuthLike(SENIOR_TRANCHE_NEW).rely(CLERK);

        AuthLike(SENIOR_TOKEN).deny(SENIOR_TRANCHE_OLD);
        AuthLike(SENIOR_TOKEN).rely(SENIOR_TRANCHE_NEW);
        AuthLike(RESERVE).deny(SENIOR_TRANCHE_OLD);
        AuthLike(RESERVE).rely(SENIOR_TRANCHE_NEW);

        // junior
        TrancheLike juniorTranche = TrancheLike(SENIOR_TRANCHE_NEW);
        require((juniorTranche.totalSupply() == 0 && juniorTranche.totalRedeem() == 0), "junior-tranche-has-orders");

        // dependencies
        DependLike(JUNIOR_TRANCHE_NEW).depend("reserve", RESERVE);
        DependLike(JUNIOR_TRANCHE_NEW).depend("epochTicker", COORDINATOR);
        DependLike(JUNIOR_OPERATOR).depend("tranche", JUNIOR_TRANCHE_NEW);
        DependLike(ASSESSOR).depend("juniorTranche", JUNIOR_TRANCHE_NEW);
        DependLike(COORDINATOR).depend("juniorTranche", JUNIOR_TRANCHE_NEW);

        // permissions
        AuthLike(JUNIOR_TRANCHE_NEW).rely(JUNIOR_OPERATOR);
        AuthLike(JUNIOR_TRANCHE_NEW).rely(COORDINATOR);
        
        AuthLike(JUNIOR_TOKEN).deny(JUNIOR_TRANCHE_OLD);
        AuthLike(JUNIOR_TOKEN).rely(JUNIOR_TRANCHE_NEW);
        AuthLike(RESERVE).deny(JUNIOR_TRANCHE_OLD);
        AuthLike(RESERVE).rely(JUNIOR_TRANCHE_NEW);
    }
}