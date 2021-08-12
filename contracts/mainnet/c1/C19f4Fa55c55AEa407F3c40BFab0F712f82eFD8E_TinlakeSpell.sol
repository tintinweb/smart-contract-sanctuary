/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

// Fortunafi 1 addresses at Tue Jul 27 14:33:15 CEST 2021
contract Addresses {
	address constant public ACTIONS = 0x80F33ED0A69935dd74310b9D0009D0BA647Cf223;
	address constant public AO_REWARD_RECIPIENT = 0xB170597E474CC124aE8Fe2b335d0d80E08bC3e37;
	address constant public ASSESSOR = 0x4e7D665FB7747747bd770CB35F604412249AE8bC;
	address constant public ASSESSOR_ADMIN = 0x71d8ec8bE0d8C694f0c177C9aCb531B1D9076D08;
	address constant public COLLECTOR = 0x459f12aE89A956E245800f692a1510F0d01e3d48;
	address constant public COORDINATOR = 0xD7965D41c37B9F8691F0fe83878f6FFDbCb90996;
	address constant public FEED = 0xcAB9ed8e5EF4607A97f4e22Ad1D984ADB93ce890;
	address constant public JUNIOR_MEMBERLIST = 0x3FBD11B1f91765B32BD1231922F1E32f6bdfCB1c;
	address constant public JUNIOR_OPERATOR = 0x0B5Fb20BF5381A92Dd026208f4177a2Af85DACB9;
	address constant public JUNIOR_TOKEN = 0xf2dEB8F74C5dDA88CCD606ea88cCD3fC9FC98a1F;
	address constant public JUNIOR_TRANCHE = 0xc3e80961386D0C52C0988c12C6665d3AB2E04f0D;
	address constant public PILE = 0x11C14AAa42e361Cf3500C9C46f34171856e3f657;
	address constant public PROXY_REGISTRY = 0xC9045c815bF123ad12EA75b9A7c579C1e05051f9;
	address constant public RESERVE = 0x78aF512B18C0893e77138b02B1393cd887816EDF;
	address constant public ROOT_CONTRACT = 0x4B6CA198d257D755A5275648D471FE09931b764A;
	address constant public SENIOR_MEMBERLIST = 0x6e79770F8B57cAd29D29b1884563556B31E792b0;
	address constant public SENIOR_OPERATOR = 0x3247f0d72303567A313FC87d04E533a845d1ba5A;
	address constant public SENIOR_TOKEN = 0x44718d306a8Fa89545704Ae38B2B97c06bF11FC1;
	address constant public SENIOR_TRANCHE = 0xCebdAb943781878627fd04e8E0641Ee73941B1C5;
	address constant public SHELF = 0x9C3a54AC3af2e1FC9ee49e991a0452629C9bca64;
	address constant public TINLAKE_CURRENCY = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
	address constant public TITLE = 0x9E0c12ab26CC7939Efe63f307Db4fF8E4D29EC82;  
}


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

interface PoolRegistryLike {
  function file(address pool, bool live, string memory name, string memory data) external;
  function find(address pool) external view returns (bool live, string memory name, string memory data);
}

contract TinlakeSpell is Addresses {

    bool public done;
    string constant public description = "Tinlake maker integration mainnet spell";

    address constant public GOVERNANCE = 0xf3BceA7494D8f3ac21585CA4b0E52aa175c24C25;
    address constant public POOL_REGISTRY = 0xddf1C516Cf87126c6c610B52FD8d609E67Fb6033;

    // TODO: set these new swapped addresses
    address constant public COORDINATOR_NEW = 0x9dA6Ff36Fc054b7FD2F72935DD3A9cFbFc00B8B6;
    address constant public ASSESSOR_NEW  = 0xCC2cA000DB7Df0499667ca4048987727151b0b1f;
    address constant public RESERVE_NEW = 0xd9Cec614db2b5A7490dF2462A4621D96bCD4bfE2;
    address constant public SENIOR_TRANCHE_NEW = 0xfc9E18e714c21539456d5f77F7F635781Cf56Af0;
    address constant public JUNIOR_TRANCHE_NEW = 0x7DA307394B052Af46Aba415289db24177B754C7e;
    address constant public POOL_ADMIN = 0x20ca8D29F1ad57e85A73c2aA99dFF46241C94A1A;
    address constant public CLERK = 0x04140410249C4e9bB85f948135671Af30D941034;

    // TODO: check these global maker addresses
    address constant public SPOTTER = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address constant public VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant public JUG = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant public LIQ = 0x88f88Bb9E66241B73B84f3A6E197FbBa487b1E30;
    address constant public END = 0xBB856d1742fD182a90239D7AE85706C2FE4e5922;

    // TODO: set these pool specific maker addresses
    address constant public URN = 0xc40907545C57dB30F01a1c2acB242C7c7ACB2B90;
    address constant public RWA_GEM = 0x6DB236515E90fC831D146f5829407746EDdc5296;
    address constant public MAKER_MGR = 0x5b702e1fEF3F556cbe219eE697D7f170A236cc66;

    // TODO: set these
    address constant public POOL_ADMIN1 = 0xd60f7CFC1E051d77031aC21D9DB2F66fE54AE312;
    address constant public POOL_ADMIN2 = 0x71d9f8CFdcCEF71B59DD81AB387e523E2834F2b8;
    address constant public POOL_ADMIN3 = 0x46a71eEf8DbcFcbAC7A0e8D5d6B634A649e61fb8;
    address constant public POOL_ADMIN4 = 0xa7Aa917b502d86CD5A23FFbD9Ee32E013015e069;
    address constant public POOL_ADMIN5 = 0x9eDec77dd2651Ce062ab17e941347018AD4eAEA9;
    address constant public POOL_ADMIN6 = 0xEf270f8877Aa1875fc13e78dcA31f3235210368f;
    address constant public AO_POOL_ADMIN = 0xB170597E474CC124aE8Fe2b335d0d80E08bC3e37;

    // TODO: check these
    uint constant public ASSESSOR_MIN_SENIOR_RATIO = 0;
    uint constant public MAT_BUFFER = 0.01 * 10**27;

    // TODO set these
    string constant public SLUG = "fortunafi-1";
    string constant public IPFS_HASH = "QmcMhaxveNCHP8TyG7hxnUzDBMxQxXVFqtwaRRfFx4qCjj";

    // permissions to be set
    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
        SpellTinlakeRootLike root = SpellTinlakeRootLike(ROOT_CONTRACT);

        // set spell as ward on the core contract to be able to wire the new contracts correctly
        root.relyContract(SHELF, address(this));
        root.relyContract(COLLECTOR, address(this));
        root.relyContract(JUNIOR_TRANCHE, address(this));
        root.relyContract(SENIOR_TRANCHE, address(this));
        root.relyContract(JUNIOR_OPERATOR, address(this));
        root.relyContract(SENIOR_OPERATOR, address(this));
        root.relyContract(JUNIOR_TOKEN, address(this));
        root.relyContract(SENIOR_TOKEN, address(this));
        root.relyContract(JUNIOR_TRANCHE_NEW, address(this));
        root.relyContract(SENIOR_TRANCHE_NEW, address(this));
        root.relyContract(JUNIOR_MEMBERLIST, address(this));
        root.relyContract(SENIOR_MEMBERLIST, address(this));
        root.relyContract(CLERK, address(this));
        root.relyContract(POOL_ADMIN, address(this));
        root.relyContract(ASSESSOR_NEW, address(this));
        root.relyContract(COORDINATOR_NEW, address(this));
        root.relyContract(RESERVE, address(this));
        root.relyContract(RESERVE_NEW, address(this));
        root.relyContract(MAKER_MGR, address(this));
    
        // contract migration --> assumption: root contract is already ward on the new contracts
        migrateAssessor();
        migrateCoordinator();
        migrateReserve();
        migrateSeniorTranche();
        migrateJuniorTranche();
        integrateAdapter();
        setupPoolAdmin();

        // for mkr integration: set minSeniorRatio in Assessor to 0      
        FileLike(ASSESSOR_NEW).file("minSeniorRatio", ASSESSOR_MIN_SENIOR_RATIO);

        updateRegistry();
    }

    function migrateAssessor() internal {
        MigrationLike(ASSESSOR_NEW).migrate(ASSESSOR);

        // migrate dependencies 
        DependLike(ASSESSOR_NEW).depend("navFeed", FEED);
        DependLike(ASSESSOR_NEW).depend("juniorTranche", JUNIOR_TRANCHE_NEW);
        DependLike(ASSESSOR_NEW).depend("seniorTranche", SENIOR_TRANCHE_NEW);
        DependLike(ASSESSOR_NEW).depend("reserve", RESERVE_NEW);
        DependLike(ASSESSOR_NEW).depend("lending", CLERK); 

        // migrate permissions
        AuthLike(ASSESSOR_NEW).rely(COORDINATOR_NEW); 
        AuthLike(ASSESSOR_NEW).rely(RESERVE_NEW);
    }

    function migrateCoordinator() internal {
        MigrationLike(COORDINATOR_NEW).migrate(COORDINATOR);

         // migrate dependencies 
        DependLike(COORDINATOR_NEW).depend("assessor", ASSESSOR_NEW);
        DependLike(COORDINATOR_NEW).depend("juniorTranche", JUNIOR_TRANCHE_NEW);
        DependLike(COORDINATOR_NEW).depend("seniorTranche", SENIOR_TRANCHE_NEW);
        DependLike(COORDINATOR_NEW).depend("reserve", RESERVE_NEW);

        // migrate permissions
        AuthLike(JUNIOR_TRANCHE_NEW).rely(COORDINATOR_NEW); 
        AuthLike(JUNIOR_TRANCHE).deny(COORDINATOR); 
        AuthLike(SENIOR_TRANCHE_NEW).rely(COORDINATOR_NEW);
        AuthLike(SENIOR_TRANCHE).deny(COORDINATOR); 
    }

    function migrateReserve() internal {
        MigrationLike(RESERVE_NEW).migrate(RESERVE);

        // migrate dependencies 
        DependLike(RESERVE_NEW).depend("currency", TINLAKE_CURRENCY);
        DependLike(RESERVE_NEW).depend("shelf", SHELF);
        DependLike(RESERVE_NEW).depend("lending", CLERK);
        DependLike(RESERVE_NEW).depend("pot", RESERVE_NEW);

        DependLike(SHELF).depend("distributor", RESERVE_NEW);
        DependLike(SHELF).depend("lender", RESERVE_NEW);
        DependLike(COLLECTOR).depend("distributor", RESERVE_NEW);
        DependLike(JUNIOR_TRANCHE).depend("reserve", RESERVE_NEW);

        // migrate permissions
        AuthLike(RESERVE_NEW).rely(JUNIOR_TRANCHE_NEW);
        AuthLike(RESERVE_NEW).rely(SENIOR_TRANCHE_NEW);
        AuthLike(RESERVE_NEW).rely(ASSESSOR_NEW);
        
        // migrate reserve balance
        SpellERC20Like currency = SpellERC20Like(TINLAKE_CURRENCY);
        uint balanceReserve = currency.balanceOf(RESERVE);
        SpellReserveLike(RESERVE).payout(balanceReserve);
        currency.transferFrom(address(this), RESERVE_NEW, balanceReserve);
    }

    function migrateSeniorTranche() internal {
        TrancheLike tranche = TrancheLike(SENIOR_TRANCHE_NEW);
        require((tranche.totalSupply() == 0 && tranche.totalRedeem() == 0), "tranche-has-orders");

        DependLike(SENIOR_TRANCHE_NEW).depend("reserve", RESERVE_NEW);
        DependLike(SENIOR_TRANCHE_NEW).depend("coordinator", COORDINATOR_NEW);
        DependLike(SENIOR_OPERATOR).depend("tranche", SENIOR_TRANCHE_NEW);

        AuthLike(SENIOR_TOKEN).deny(SENIOR_TRANCHE);
        AuthLike(SENIOR_TOKEN).rely(SENIOR_TRANCHE_NEW);
        AuthLike(SENIOR_TRANCHE_NEW).rely(SENIOR_OPERATOR);

        SpellMemberlistLike(SENIOR_MEMBERLIST).updateMember(SENIOR_TRANCHE_NEW, type(uint256).max);
    }

    function migrateJuniorTranche() internal {
        TrancheLike tranche = TrancheLike(JUNIOR_TRANCHE_NEW);
        require((tranche.totalSupply() == 0 && tranche.totalRedeem() == 0), "tranche-has-orders");

        DependLike(JUNIOR_TRANCHE_NEW).depend("reserve", RESERVE_NEW);
        DependLike(JUNIOR_TRANCHE_NEW).depend("coordinator", COORDINATOR_NEW);
        DependLike(JUNIOR_OPERATOR).depend("tranche", JUNIOR_TRANCHE_NEW);

        AuthLike(JUNIOR_TOKEN).deny(JUNIOR_TRANCHE);
        AuthLike(JUNIOR_TOKEN).rely(JUNIOR_TRANCHE_NEW);
        AuthLike(JUNIOR_TRANCHE_NEW).rely(JUNIOR_OPERATOR);

        SpellMemberlistLike(JUNIOR_MEMBERLIST).updateMember(JUNIOR_TRANCHE_NEW, type(uint256).max);
    }

    function integrateAdapter() internal {
        require(SpellERC20Like(RWA_GEM).balanceOf(MAKER_MGR) == 1 ether);

        // dependencies
        DependLike(CLERK).depend("assessor", ASSESSOR_NEW);
        DependLike(CLERK).depend("mgr", MAKER_MGR);
        DependLike(CLERK).depend("coordinator", COORDINATOR_NEW);
        DependLike(CLERK).depend("reserve", RESERVE_NEW); 
        DependLike(CLERK).depend("tranche", SENIOR_TRANCHE_NEW);
        DependLike(CLERK).depend("collateral", SENIOR_TOKEN);
        DependLike(CLERK).depend("spotter", SPOTTER);
        DependLike(CLERK).depend("vat", VAT);
        DependLike(CLERK).depend("jug", JUG);

        FileLike(CLERK).file("buffer", MAT_BUFFER);

        // permissions
        AuthLike(CLERK).rely(COORDINATOR_NEW);
        AuthLike(CLERK).rely(RESERVE_NEW);
        AuthLike(SENIOR_TRANCHE_NEW).rely(CLERK);
        AuthLike(RESERVE_NEW).rely(CLERK);
        AuthLike(ASSESSOR_NEW).rely(CLERK);

        // currency
        SpellMemberlistLike(SENIOR_MEMBERLIST).updateMember(CLERK, type(uint256).max);
        SpellMemberlistLike(SENIOR_MEMBERLIST).updateMember(MAKER_MGR, type(uint256).max);

        // setup mgr
        AuthLike(MAKER_MGR).rely(CLERK);
        FileLike(MAKER_MGR).file("urn", URN);
        FileLike(MAKER_MGR).file("liq", LIQ);
        FileLike(MAKER_MGR).file("end", END);
        FileLike(MAKER_MGR).file("owner", CLERK);
        FileLike(MAKER_MGR).file("pool", SENIOR_OPERATOR);
        FileLike(MAKER_MGR).file("tranche", SENIOR_TRANCHE_NEW);

        // lock token
        MgrLike(MAKER_MGR).lock(1 ether);
    }

    function setupPoolAdmin() internal {
        PoolAdminLike poolAdmin = PoolAdminLike(POOL_ADMIN);

        // setup dependencies 
        DependLike(POOL_ADMIN).depend("assessor", ASSESSOR_NEW);
        DependLike(POOL_ADMIN).depend("lending", CLERK);
        DependLike(POOL_ADMIN).depend("seniorMemberlist", SENIOR_MEMBERLIST);
        DependLike(POOL_ADMIN).depend("juniorMemberlist", JUNIOR_MEMBERLIST);

        // setup permissions
        AuthLike(ASSESSOR_NEW).rely(POOL_ADMIN);
        AuthLike(CLERK).rely(POOL_ADMIN);
        AuthLike(JUNIOR_MEMBERLIST).rely(POOL_ADMIN);
        AuthLike(SENIOR_MEMBERLIST).rely(POOL_ADMIN);

        // directly relying governance so it can be used to directly add/remove pool admins without going through the root
        AuthLike(POOL_ADMIN).rely(GOVERNANCE);

        // setup admins
        poolAdmin.relyAdmin(POOL_ADMIN1);
        poolAdmin.relyAdmin(POOL_ADMIN2);
        poolAdmin.relyAdmin(POOL_ADMIN3);
        poolAdmin.relyAdmin(POOL_ADMIN4);
        poolAdmin.relyAdmin(POOL_ADMIN5);
        poolAdmin.relyAdmin(POOL_ADMIN6);
        poolAdmin.relyAdmin(AO_POOL_ADMIN);
    }

    function updateRegistry() internal {
        PoolRegistryLike(POOL_REGISTRY).file(ROOT_CONTRACT, true, SLUG, IPFS_HASH);
    }

}