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
	address constant public ASSESSOR = 0x546F37C27483ffd6deC56076d0F8b4B636C5616B;
	address constant public ASSESSOR_ADMIN = 0xc9caE66106B64D841ac5CB862d482704569DD52d;
	address constant public COLLECTOR = 0x101143B77b544918f2f4bDd8B9bD14b899f675af;
	address constant public COORDINATOR = 0x43DBBEA4fBe15acbfE13cfa2C2c820355e734475;
	address constant public FEED = 0x2CC23f2C2451C55a2f4Da389bC1d246E1cF10fc6;
	address constant public JUNIOR_MEMBERLIST = 0x00e6bbF959c2B2a14D118CC74D1c9744f0C7C5Da;
	address constant public JUNIOR_OPERATOR = 0xf234778f148a0bB483cC1508a5f7c3C5E445596E;
	address constant public JUNIOR_TOKEN = 0xd0E93A90556c92eE8E100C7c2Dd008fb650B0712;
	address constant public JUNIOR_TRANCHE = 0x836f3B2949722BED92719b28DeD38c4138818932;
	address constant public PILE = 0xe17F3c35C18b2Af84ceE2eDed673c6A08A671695;
	address constant public POOL_ADMIN = 0x2695758B7e213dC6dbfaBF3683e0c0b02E779343;
	address constant public PROXY_REGISTRY = 0xC9045c815bF123ad12EA75b9A7c579C1e05051f9;
	address constant public RESERVE = 0xE5FDaE082F6E22f25f0382C56cb3c856a803c9dD;
	address constant public ROOT = 0x560Ac248ce28972083B718778EEb0dbC2DE55740;
	address constant public SENIOR_MEMBERLIST = 0x26768a74819608B96fcC2a83Ba4A651b6b31AE96;
	address constant public SENIOR_OPERATOR = 0x378Ca1098eA1f4906247A146632635EC7c7e5735;
	address constant public SENIOR_TOKEN = 0x8d2b8Df9Cb35B875F9726F43a013caF16aEFA472;
	address constant public SENIOR_TRANCHE = 0x70B78902844691266D6b050A9725c5A6Dc328fc4;
	address constant public SHELF = 0xeCc564B98f3F50567C3ED0C1E784CbA4f97C6BcD;
	address constant public TINLAKE_CURRENCY = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
	address constant public TITLE = 0xd61E8D3Af157e70C175831C80BF331A16dC2442A;
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
    address constant public RESERVE_NEW = 0xB74C0A7929F5c35E5F4e74b628eE32a35a7535D7;
    string constant public IPFS_HASH = "QmeVrEbEVB4gFkoA4iHJUySzWsmwna9HXUgTKeKkRKH2v7";

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

        DependLike(SHELF).depend("reserve", RESERVE_NEW);
        DependLike(SHELF).depend("lender", RESERVE_NEW);
        DependLike(COLLECTOR).depend("reserve", RESERVE_NEW);
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
        PoolRegistryLike(POOL_REGISTRY).file(ROOT, true, "branch-3", IPFS_HASH);
    }
}