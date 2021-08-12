/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

// ConsolFreight 4 addresses at Thu Aug 12 13:08:46 CEST 2021
contract Addresses {
	address constant public ACTIONS = 0x80F33ED0A69935dd74310b9D0009D0BA647Cf223;
	address constant public AO_REWARD_RECIPIENT = 0x8CE8fC2e297F1688385Fc115A3cB104393FE3659;
	address constant public ASSESSOR = 0x6aaf2EE5b2B62fb9E29E021a1bF3B381454d900a;
	address constant public ASSESSOR_ADMIN = 0x533Ea66C62fad098599dE145970a8d49D6B5f9C4;
	address constant public COLLECTOR = 0x026AA71fCB79684639d2f0F11ad74569Fbd5d590;
	address constant public COORDINATOR = 0xFc224d40Eb9c40c85c71efa773Ce24f8C95aAbAb;
	address constant public FEED = 0x69504da6B2Cd8320B9a62F3AeD410a298d3E7Ac6;
	address constant public JUNIOR_MEMBERLIST = 0x4CA09F24f3342327da42d2b6035af741fC1AeB4A;
	address constant public JUNIOR_OPERATOR = 0x9b68611127275b3B5f04161884f2c5C308CCE0Dd;
	address constant public JUNIOR_TOKEN = 0x05DD145AA26dBDcc7774E4118E34Bb67C64661c6;
	address constant public JUNIOR_TRANCHE = 0x145d6256e20CD115eDA44Eb9258A3BC13c2a86fc;
	address constant public PILE = 0x3fC72dA5545E2AB6202D81fbEb1C8273Be95068C;
	address constant public PROXY_REGISTRY = 0xC9045c815bF123ad12EA75b9A7c579C1e05051f9;
	address constant public RESERVE = 0x0d601b451aFD502e473bA4CE6E3876D652BCbee7;
	address constant public ROOT_CONTRACT = 0xdB3bC9fB1893222d266762e9fF857EB74D75c7D6;
	address constant public SENIOR_MEMBERLIST = 0x26129802A858F3C28553f793E1008b8338e6aEd2;
	address constant public SENIOR_OPERATOR = 0x21335b1b19964Ef33787138122fD1CDc6deD8186;
	address constant public SENIOR_TOKEN = 0x5b2F0521875B188C0afc925B1598e1FF246F9306;
	address constant public SENIOR_TRANCHE = 0xB101eD16AD86cb5cc92dAdc357aD994Ab6c663A5;
	address constant public SHELF = 0xA0B0d8394ADC79f5d1563a892abFc6186E519644;
	address constant public TINLAKE_CURRENCY = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
	address constant public TITLE = 0x9Ab3ada106afdFAE83f13428e40da70b3A22C50C;  
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
    address constant public COORDINATOR_NEW = 0x585c080f36042bA2CD4C310660386cA3d95FdfAD;
    address constant public ASSESSOR_NEW  = 0x989e5F083cF5B2065C60032d7Bafd176237f8E09;
    address constant public RESERVE_NEW = 0xFAec38fFEe969cf18e88097EC62E30b70494e234;
    address constant public SENIOR_TRANCHE_NEW = 0x675f5A545Fd57eC8Fe0916Fb61a2D9F19e2Da926;
    address constant public JUNIOR_TRANCHE_NEW = 0xC90fE5884C1c2f2913fFee5440ce4dd34f4B279D;
    address constant public POOL_ADMIN = 0x7A5f9AE1d4c81B5ea0Ab318ae24055898Bfb0abC;
    address constant public CLERK = 0x43b3f07667906026336C92bFade718a3430A845d;

    // TODO: check these global maker addresses
    address constant public SPOTTER = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address constant public VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
    address constant public JUG = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address constant public LIQ = 0x88f88Bb9E66241B73B84f3A6E197FbBa487b1E30;
    address constant public END = 0xBB856d1742fD182a90239D7AE85706C2FE4e5922;

    // TODO: set these pool specific maker addresses
    address constant public URN = 0x7bF825718e7C388c3be16CFe9982539A7455540F;
    address constant public RWA_GEM = 0x07F0A80aD7AeB7BfB7f139EA71B3C8f7E17156B9;
    address constant public MAKER_MGR = 0x2A9798c6F165B6D60Cfb923Fe5BFD6f338695D9B;

    // TODO: set these
    address constant public POOL_ADMIN1 = 0xd60f7CFC1E051d77031aC21D9DB2F66fE54AE312;
    address constant public POOL_ADMIN2 = 0x71d9f8CFdcCEF71B59DD81AB387e523E2834F2b8;
    address constant public POOL_ADMIN3 = 0x46a71eEf8DbcFcbAC7A0e8D5d6B634A649e61fb8;
    address constant public POOL_ADMIN4 = 0xa7Aa917b502d86CD5A23FFbD9Ee32E013015e069;
    address constant public POOL_ADMIN5 = 0x9eDec77dd2651Ce062ab17e941347018AD4eAEA9;
    address constant public POOL_ADMIN6 = 0xEf270f8877Aa1875fc13e78dcA31f3235210368f;
    address constant public AO_POOL_ADMIN = 0x8CE8fC2e297F1688385Fc115A3cB104393FE3659;

    // TODO: check these
    uint constant public ASSESSOR_MIN_SENIOR_RATIO = 0;
    uint constant public MAT_BUFFER = 0.01 * 10**27;

    // TODO set these
    string constant public SLUG = "consolfreight-4";
    string constant public IPFS_HASH = "Qme29E923WNGrscuLdhPVZGSR5YkdoKaSWhUDogdsjW5ky";

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