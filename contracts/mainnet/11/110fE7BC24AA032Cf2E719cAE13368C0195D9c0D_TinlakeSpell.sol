/**
 *Submitted for verification at Etherscan.io on 2021-07-08
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

// New Silver 2 addresses at Wed Jul  7 16:08:49 WEST 2021
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
	address constant public RESERVE = 0x1f5Fa2E665609CE4953C65CE532Ac8B47EC97cD5;
	address constant public ROOT_CONTRACT = 0x53b2d22d07E069a3b132BfeaaD275b10273d381E;
	address constant public SENIOR_MEMBERLIST = 0x5B5CFD6E45F1407ABCb4BFD9947aBea1EA6649dA;
	address constant public SENIOR_OPERATOR = 0x230f2E19D6c2Dc0c441c2150D4dD9d67B563A60C;
	address constant public SENIOR_TOKEN = 0xE4C72b4dE5b0F9ACcEA880Ad0b1F944F85A9dAA0;
	address constant public SENIOR_TRANCHE = 0x3f06DB6334435fF4150e14aD69F6280BF8E8dA64;
	address constant public SHELF = 0x7d057A056939bb96D682336683C10EC89b78D7CE;
	address constant public TINLAKE_CURRENCY = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
	address constant public TITLE = 0x07cdD617c53B07208b0371C93a02deB8d8D49C6e;  
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

interface NAVFeedLike {
    function file(bytes32, uint) external;
    function discountRate() external view returns (uint256);
}

contract TinlakeSpell is Addresses {

    bool public done;
    string constant public description = "Tinlake coordinator migration mainnet spell";

    address constant public COORDINATOR_NEW = 0x22a1caca2EE82e9cE7Ef900FD961891b66deB7cA;

    uint[4] discountRates = [1000000002243467782851344495, 1000000002108701166920345002, 1000000001973934550989345509, 1000000001839167935058346017];
    uint[4] timestamps;
    bool[4] rateAlreadySet = [false, false, false, false];
    
    // permissions to be set
    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
        SpellTinlakeRootLike root = SpellTinlakeRootLike(ROOT_CONTRACT);

        // set spell as ward on the core contract to be able to wire the new contracts correctly
        root.relyContract(JUNIOR_TRANCHE, address(this));
        root.relyContract(SENIOR_TRANCHE, address(this));
        root.relyContract(ASSESSOR, address(this));
        root.relyContract(RESERVE, address(this));
        root.relyContract(COORDINATOR_NEW, address(this));
        root.relyContract(CLERK, address(this));
        root.relyContract(FEED, address(this));

        // contract migration --> assumption: root contract is already ward on the new contracts
        migrateCoordinator();

        timestamps = [
            block.timestamp + 0 days,
            block.timestamp + 4 days,
            block.timestamp + 8 days,
            block.timestamp + 12 days
        ];

        setDiscount(0);
    }

    function migrateCoordinator() internal {
        // migrate dependencies
        DependLike(COORDINATOR_NEW).depend("assessor", ASSESSOR);
        DependLike(COORDINATOR_NEW).depend("juniorTranche", JUNIOR_TRANCHE);
        DependLike(COORDINATOR_NEW).depend("seniorTranche", SENIOR_TRANCHE);
        DependLike(COORDINATOR_NEW).depend("reserve", RESERVE);
        
        DependLike(JUNIOR_TRANCHE).depend("epochTicker", COORDINATOR_NEW);
        DependLike(SENIOR_TRANCHE).depend("epochTicker", COORDINATOR_NEW);
        DependLike(CLERK).depend("coordinator", COORDINATOR_NEW);

        // migrate permissions
        AuthLike(ASSESSOR).rely(COORDINATOR_NEW); 
        AuthLike(ASSESSOR).deny(COORDINATOR);
        AuthLike(JUNIOR_TRANCHE).rely(COORDINATOR_NEW); 
        AuthLike(JUNIOR_TRANCHE).deny(COORDINATOR); 
        AuthLike(SENIOR_TRANCHE).rely(COORDINATOR_NEW);
        AuthLike(SENIOR_TRANCHE).deny(COORDINATOR);

        // migrate state
        MigrationLike(COORDINATOR_NEW).migrate(COORDINATOR);
    }

    function setDiscount(uint i) public {
        require(block.timestamp >= timestamps[i], "not-yet-executable");
        require(i == 0 || NAVFeedLike(FEED).discountRate() == discountRates[i-1], "incorrect-execution-order");
        require(rateAlreadySet[i] == false, "already-executed");

        rateAlreadySet[i] = true;
        NAVFeedLike(FEED).file("discountRate", discountRates[i]);
    }

}