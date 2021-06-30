/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

contract Addresses {
	address constant public ACTIONS = 0x80F33ED0A69935dd74310b9D0009D0BA647Cf223;
	address constant public ASSESSOR = 0x76343D8BDACAFbabE2a4476ec004Ac3D5501DdF8;
	address constant public COLLECTOR = 0x813B7c6692A56ff440eD6C638b7357d040bC8958;
	address constant public COORDINATOR = 0x3e3f323a95018Ee133D47c4841f5AF235E2aF4f5;
	address constant public FEED = 0xd9b2471F5c7494254b8d52f4aB3146e747ABc9AB;
	address constant public JUNIOR_MEMBERLIST = 0x364B69aFc0101Af31089C5aE234D8444C355e8a0;
	address constant public JUNIOR_OPERATOR = 0x54c2B9AE8D556c74677dA2e286c8198b354E7d27;
	address constant public JUNIOR_TOKEN = 0xD7a70741B44F5ddaB371c2D2EB9D030A7c1a4BA0;
	address constant public JUNIOR_TRANCHE = 0xF53EBEDAe8E3e0C77BA12e26c504ee1B0Eccd147;
	address constant public PILE = 0xAAEaCfcCc3d3249f125Ba0644495560309C266cB;
	address constant public POOL_ADMIN = 0x68c19d14937e43ACa58538628ac2F99e167F2C9C;
	address constant public PROXY_REGISTRY = 0xC9045c815bF123ad12EA75b9A7c579C1e05051f9;
	address constant public RESERVE = 0x5Aa3F927619d522d21AE9522F018030038aDC0E6;
	address constant public ROOT = 0x235893Bf9695F68a922daC055598401D832b538b;
	address constant public SENIOR_MEMBERLIST = 0x3e77f47e5e1Ec71fabE473347400A06d9Af13eE3;
	address constant public SENIOR_OPERATOR = 0x2844b69835F182190eB6F602C6cfA2981E143c20;
	address constant public SENIOR_TOKEN = 0x419A0B6f55Ff030cC50c6C5178d579D5828D8Db8;
	address constant public SENIOR_TRANCHE = 0xB9c79d0721E378D9CF8D18a1e74CB462D57B571F;
	address constant public SHELF = 0x4Ca7049E61629407a7E829564C1Dd2538d70182C;
	address constant public TINLAKE_CURRENCY = 0xad3E3Fc59dff318BecEaAb7D00EB4F68b1EcF195;
	address constant public TITLE = 0x33a764604EA9624B4258d7d6dCc08Ce2b8EDa825; 
	address constant public POOL_REGISTRY = 0xddf1C516Cf87126c6c610B52FD8d609E67Fb6033;
}


interface SpellTinlakeRootLike {
    function relyContract(address, address) external;
}
interface SpellReserveLike {
    function payout(uint currencyAmount) external;
}

interface DependLike {
    function depend(bytes32, address) external;
}

interface AuthLike {
    function rely(address) external;
    function deny(address) external;
    function wards(address) external returns(uint);
}

interface PoolRegistryLike {
  function file(address pool, bool live, string memory name, string memory data) external;
  function find(address pool) external view returns (bool live, string memory name, string memory data);
}

interface MigrationLike {
    function migrate(address) external;
}

interface SpellERC20Like {
    function balanceOf(address) external view returns (uint256);
    function transferFrom(address, address, uint) external returns (bool);
    function approve(address, uint) external;
}

contract TinlakeSpell is Addresses {

    bool public done;
    string constant public description = "Tinlake Reserve migration spell";

    // TODO: replace the following address
    address constant public RESERVE_NEW = 0xB12e705733042610174ed22F6726d26DB12DBdFE;
    string constant public IPFS_HASH = "QmbaWWRy2MAsABKvCstdWmLzdKfvujTEQNq7qWuz2sr6sg";

    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
        SpellTinlakeRootLike root = SpellTinlakeRootLike(ROOT);

        // set spell as ward on the core contract to be able to wire the new contracts correctly
        root.relyContract(SHELF, address(this));
        root.relyContract(COLLECTOR, address(this));
        root.relyContract(JUNIOR_TRANCHE, address(this));
        root.relyContract(SENIOR_TRANCHE, address(this));
        // root.relyContract(CLERK, address(this));
        root.relyContract(ASSESSOR, address(this));
        root.relyContract(COORDINATOR, address(this));
        root.relyContract(RESERVE, address(this));
        root.relyContract(RESERVE_NEW, address(this));
        
        migrateReserve();
        updateRegistry();
    }

    function migrateReserve() internal {
        MigrationLike(RESERVE_NEW).migrate(RESERVE);

        // migrate dependencies 
        DependLike(RESERVE_NEW).depend("assessor", ASSESSOR);
        DependLike(RESERVE_NEW).depend("currency", TINLAKE_CURRENCY);
        DependLike(RESERVE_NEW).depend("shelf", SHELF);
        // DependLike(RESERVE_NEW).depend("lending", CLERK);
        DependLike(RESERVE_NEW).depend("pot", RESERVE_NEW);
        DependLike(SHELF).depend("distributor", RESERVE_NEW);
        DependLike(SHELF).depend("lender", RESERVE_NEW);
        DependLike(COLLECTOR).depend("distributor", RESERVE_NEW);
        DependLike(JUNIOR_TRANCHE).depend("reserve", RESERVE_NEW);
        DependLike(SENIOR_TRANCHE).depend("reserve", RESERVE_NEW);
        // DependLike(CLERK).depend("reserve", RESERVE_NEW); 
        DependLike(ASSESSOR).depend("reserve", RESERVE_NEW);
        DependLike(COORDINATOR).depend("reserve", RESERVE_NEW);

        // migrate permissions
        AuthLike(RESERVE_NEW).rely(JUNIOR_TRANCHE);
        AuthLike(RESERVE_NEW).rely(SENIOR_TRANCHE);
        AuthLike(RESERVE_NEW).rely(ASSESSOR);
        // AuthLike(RESERVE_NEW).rely(CLERK);

        // AuthLike(CLERK).rely(RESERVE_NEW);
        // AuthLike(CLERK).deny(RESERVE);
        AuthLike(ASSESSOR).rely(RESERVE_NEW);
        AuthLike(ASSESSOR).deny(RESERVE);
        
        // migrate reserve balance
        SpellERC20Like currency = SpellERC20Like(TINLAKE_CURRENCY);
        uint balanceReserve = currency.balanceOf(RESERVE);
        SpellReserveLike(RESERVE).payout(balanceReserve);
        currency.transferFrom(address(this), RESERVE_NEW, balanceReserve);
    }

    function updateRegistry() internal {
        PoolRegistryLike(POOL_REGISTRY).file(ROOT, true, "Pezesha-1", IPFS_HASH);
    }
}