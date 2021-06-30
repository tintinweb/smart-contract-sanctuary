/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/spell.sol
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

////// src/addresses.sol

/* pragma solidity >=0.7.0; */

// New Silver 2 addresses at Wed 23 Jun 2021 09:31:31 CEST
contract Addresses {
	address constant public ACTIONS = 0x80F33ED0A69935dd74310b9D0009D0BA647Cf223;
	address constant public AO_REWARD_RECIPIENT = 0x7Cae9bD865610750a48575aF15CAFe1e460c96a8;
	address constant public ASSESSOR = 0x83E2369A33104120746B589Cc90180ed776fFb91;
	address constant public ASSESSOR_ADMIN = 0x46470030e1c732A9C2b541189471E47661311375;
	address constant public CLERK = 0xA9eCF012dD36512e5fFCD5585D72386E46135Cdd;
	address constant public COLLECTOR = 0x62f290512c690a817f47D2a4a544A5d48D1408BE;
	address constant public COORDINATOR = 0xcC7AFB5DeED34CF67E72d4C53B142F44c9268ab9;
	address constant public FEED = 0x41fAD1Eb242De19dA0206B0468763333BB6C2B3D;
	address constant public JUNIOR_MEMBERLIST = 0x42C2483EEE8c1Fe46C398Ac296C59674F9eb88CD;
	address constant public JUNIOR_OPERATOR = 0x4c4Cc6a0573db5823ECAA1d1d65EB64E5E0E5F01;
	address constant public JUNIOR_TOKEN = 0x961e1d4c9A7C0C3e05F17285f5FA34A66b62dBb1;
	address constant public JUNIOR_TRANCHE = 0x53CF3CCd97CA914F9e441B8cd9A901E69B170f27;
	address constant public MAKER_MGR = 0x2474F297214E5d96Ba4C81986A9F0e5C260f445D;
	address constant public MCD_JUG = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
	address constant public MCD_VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
	address constant public PILE = 0x3eC5c16E7f2C6A80E31997C68D8Fa6ACe089807f;
	address constant public POOL_ADMIN = 0xd7fb14d5C1259a47d46D156E74a9c3B69a147b4A;
	address constant public PROXY_REGISTRY = 0xC9045c815bF123ad12EA75b9A7c579C1e05051f9;
	address constant public RESERVE = 0xD9E4391cF31638a8Da718Ff0Bf69249Cdc48fB2B;
	address constant public ROOT = 0x53b2d22d07E069a3b132BfeaaD275b10273d381E;
	address constant public SENIOR_MEMBERLIST = 0x5B5CFD6E45F1407ABCb4BFD9947aBea1EA6649dA;
	address constant public SENIOR_OPERATOR = 0x230f2E19D6c2Dc0c441c2150D4dD9d67B563A60C;
	address constant public SENIOR_TOKEN = 0xE4C72b4dE5b0F9ACcEA880Ad0b1F944F85A9dAA0;
	address constant public SENIOR_TRANCHE = 0x3f06DB6334435fF4150e14aD69F6280BF8E8dA64;
	address constant public SHELF = 0x7d057A056939bb96D682336683C10EC89b78D7CE;
	address constant public TINLAKE_CURRENCY = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
	address constant public TITLE = 0x07cdD617c53B07208b0371C93a02deB8d8D49C6e;  
	address constant public POOL_REGISTRY = 0xddf1C516Cf87126c6c610B52FD8d609E67Fb6033;
}



////// src/spell.sol
/* pragma solidity >=0.7.0; */
/* pragma experimental ABIEncoderV2; */

/* import "./addresses.sol"; */

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
    address constant public RESERVE_NEW = 0x1f5Fa2E665609CE4953C65CE532Ac8B47EC97cD5;
    string constant public IPFS_HASH = "QmaWk34vLJ6ohAqvTKjJHN93t1SJ8vVPkNMgSvCzNeCSzz";

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
        root.relyContract(CLERK, address(this));
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
        DependLike(RESERVE_NEW).depend("lending", CLERK);
        DependLike(RESERVE_NEW).depend("pot", RESERVE_NEW);

        DependLike(SHELF).depend("distributor", RESERVE_NEW);
        DependLike(SHELF).depend("lender", RESERVE_NEW);
        DependLike(COLLECTOR).depend("distributor", RESERVE_NEW);
        DependLike(JUNIOR_TRANCHE).depend("reserve", RESERVE_NEW);
        DependLike(SENIOR_TRANCHE).depend("reserve", RESERVE_NEW);
        DependLike(CLERK).depend("reserve", RESERVE_NEW); 
        DependLike(ASSESSOR).depend("reserve", RESERVE_NEW);
        DependLike(COORDINATOR).depend("reserve", RESERVE_NEW);

        // migrate permissions
        AuthLike(RESERVE_NEW).rely(JUNIOR_TRANCHE);
        AuthLike(RESERVE_NEW).rely(SENIOR_TRANCHE);
        AuthLike(RESERVE_NEW).rely(ASSESSOR);
        AuthLike(RESERVE_NEW).rely(CLERK);

        AuthLike(CLERK).rely(RESERVE_NEW);
        AuthLike(CLERK).deny(RESERVE);
        AuthLike(ASSESSOR).rely(RESERVE_NEW);
        AuthLike(ASSESSOR).deny(RESERVE);
        
        // migrate reserve balance
        SpellERC20Like currency = SpellERC20Like(TINLAKE_CURRENCY);
        uint balanceReserve = currency.balanceOf(RESERVE);
        SpellReserveLike(RESERVE).payout(balanceReserve);
        currency.transferFrom(address(this), RESERVE_NEW, balanceReserve);
    }

    function updateRegistry() internal {
        PoolRegistryLike(POOL_REGISTRY).file(ROOT, true, "new-silver-2", IPFS_HASH);
    }
}