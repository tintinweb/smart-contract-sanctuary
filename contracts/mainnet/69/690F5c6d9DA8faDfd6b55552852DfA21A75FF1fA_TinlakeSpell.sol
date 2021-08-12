/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

// Harbor Trade 2 addresses at Thu Aug 12 13:31:01 CEST 2021
contract Addresses {
	address constant public ACTIONS = 0x80F33ED0A69935dd74310b9D0009D0BA647Cf223;
	address constant public AO_REWARD_RECIPIENT = 0x384bE790Ac9526D1103EfC520d733AD64618D90d;
	address constant public ASSESSOR = 0x6e40A9d1eE2c8eF95322b879CBae35BE6Dd2D143;
	address constant public ASSESSOR_ADMIN = 0x35e805BA2FB7Ad4C8Ad9D644Ca9Bd34a49f5500d;
	address constant public COLLECTOR = 0xDdA9c8631ea904Ef4c0444F2A252eC7B45B8e7e9;
	address constant public COORDINATOR = 0xE2a04a4d4Df350a752ADA79616D7f588C1A195cF;
	address constant public FEED = 0xdB9A84e5214e03a4e5DD14cFB3782e0bcD7567a7;
	address constant public JUNIOR_MEMBERLIST = 0x0b635CD35fC3AF8eA29f84155FA03dC9AD0Bab27;
	address constant public JUNIOR_OPERATOR = 0x6DAecbC801EcA2873599bA3d980c237D9296cF57;
	address constant public JUNIOR_TOKEN = 0xAA67Bb563e14fBd4E92DCc646aAac0c00c7d9526;
	address constant public JUNIOR_TRANCHE = 0x294309E42e1b3863a316BEb52df91B1CcB15eef9;
	address constant public PILE = 0xE7876f282bdF0f62e5fdb2C63b8b89c10538dF32;
	address constant public PROXY_REGISTRY = 0xC9045c815bF123ad12EA75b9A7c579C1e05051f9;
	address constant public RESERVE = 0x573a8a054e0C80F0E9B1e96E8a2198BB46c999D6;
	address constant public ROOT_CONTRACT = 0x4cA805cE8EcE2E63FfC1F9f8F2731D3F48DF89Df;
	address constant public SENIOR_MEMBERLIST = 0x1Bc55bcAf89f514CE5a8336bEC7429a99e804910;
	address constant public SENIOR_OPERATOR = 0xEDCD9e36017689c6Fc51C65c517f488E3Cb6C381;
	address constant public SENIOR_TOKEN = 0xd511397f79b112638ee3B6902F7B53A0A23386C4;
	address constant public SENIOR_TRANCHE = 0x1940E2A20525B103dCC9884902b0186371227393;
	address constant public SHELF = 0x5b2b43b3676057e38F332De73A9fCf0F8f6Babf7;
	address constant public TINLAKE_CURRENCY = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
	address constant public TITLE = 0x669Db70d3A0D7941F468B0d907E9d90BD7ddA8d1;  
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
    address constant public COORDINATOR_NEW = 0x37f3D10Bd18124a16f4DcCA02D41F910E3Aa746A;
    address constant public ASSESSOR_NEW  = 0xf2ED14102ee9D86606Ec24E48e89060ADB6DeFdb;
    address constant public RESERVE_NEW = 0x86284A692430c25EfF37007c5707a530A6d63A41;
    address constant public SENIOR_TRANCHE_NEW = 0x7E410F288583BfEe30a306F38e451a93Caaa5C47;
    address constant public JUNIOR_TRANCHE_NEW = 0x7fe1dBcBEA4e6D3846f5caB67cfC9fce39BF4d71;
    address constant public POOL_ADMIN = 0xad88b6F193bF31Be0a44A2914809BC517b03D22e;
    address constant public CLERK = 0xcC2B64dC91245110B513f0ad1393a9720F66B996;

    // TODO: check these global maker addresses
    address constant public SPOTTER = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address constant public VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant public JUG = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant public LIQ = 0x88f88Bb9E66241B73B84f3A6E197FbBa487b1E30;
    address constant public END = 0xBB856d1742fD182a90239D7AE85706C2FE4e5922;

    // TODO: set these pool specific maker addresses
    address constant public URN = 0xeF1699548717aa4Cf47aD738316280b56814C821;
    address constant public RWA_GEM = 0x873F2101047A62F84456E3B2B13df2287925D3F9;
    address constant public MAKER_MGR = 0xe1ed3F588A98bF8a3744f4BF74Fd8540e81AdE3f;

    // TODO: set these
    address constant public POOL_ADMIN1 = 0xd60f7CFC1E051d77031aC21D9DB2F66fE54AE312;
    address constant public POOL_ADMIN2 = 0x71d9f8CFdcCEF71B59DD81AB387e523E2834F2b8;
    address constant public POOL_ADMIN3 = 0x46a71eEf8DbcFcbAC7A0e8D5d6B634A649e61fb8;
    address constant public POOL_ADMIN4 = 0xa7Aa917b502d86CD5A23FFbD9Ee32E013015e069;
    address constant public POOL_ADMIN5 = 0x9eDec77dd2651Ce062ab17e941347018AD4eAEA9;
    address constant public POOL_ADMIN6 = 0xEf270f8877Aa1875fc13e78dcA31f3235210368f;
    address constant public AO_POOL_ADMIN = 0x384bE790Ac9526D1103EfC520d733AD64618D90d;

    // TODO: check these
    uint constant public ASSESSOR_MIN_SENIOR_RATIO = 0;
    uint constant public MAT_BUFFER = 0.01 * 10**27;

    // TODO set these
    string constant public SLUG = "harbor-trade-2";
    string constant public IPFS_HASH = "QmeZxngmMcMoHDTXY9ovrweykuW9ACK2VqGapyPxPdVRGf";

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