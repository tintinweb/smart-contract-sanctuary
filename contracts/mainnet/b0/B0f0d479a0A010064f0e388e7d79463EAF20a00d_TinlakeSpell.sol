/**
 *Submitted for verification at Etherscan.io on 2021-06-09
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/spell.sol
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.0;

////// src/addresses.sol

/* pragma solidity >=0.7.0; */

contract Addresses {
	address constant public BR3_ACTIONS = 0x80F33ED0A69935dd74310b9D0009D0BA647Cf223;
	address constant public BR3_ASSESSOR = 0x546F37C27483ffd6deC56076d0F8b4B636C5616B;
	address constant public BR3_ASSESSOR_ADMIN = 0xc9caE66106B64D841ac5CB862d482704569DD52d;
	address constant public BR3_COLLECTOR = 0x101143B77b544918f2f4bDd8B9bD14b899f675af;
	address constant public BR3_COORDINATOR = 0x43DBBEA4fBe15acbfE13cfa2C2c820355e734475;
	address constant public BR3_FEED = 0x2CC23f2C2451C55a2f4Da389bC1d246E1cF10fc6;
	address constant public BR3_JUNIOR_MEMBERLIST = 0x00e6bbF959c2B2a14D118CC74D1c9744f0C7C5Da;
	address constant public BR3_JUNIOR_OPERATOR = 0xf234778f148a0bB483cC1508a5f7c3C5E445596E;
	address constant public BR3_JUNIOR_TOKEN = 0xd0E93A90556c92eE8E100C7c2Dd008fb650B0712;
	address constant public BR3_JUNIOR_TRANCHE = 0x836f3B2949722BED92719b28DeD38c4138818932;
	address constant public BR3_PILE = 0xe17F3c35C18b2Af84ceE2eDed673c6A08A671695;
	address constant public BR3_POOL_ADMIN = 0x2695758B7e213dC6dbfaBF3683e0c0b02E779343;
	address constant public BR3_PROXY_REGISTRY = 0xC9045c815bF123ad12EA75b9A7c579C1e05051f9;
	address constant public BR3_RESERVE = 0xE5FDaE082F6E22f25f0382C56cb3c856a803c9dD;
	address constant public BR3_ROOT_CONTRACT = 0x560Ac248ce28972083B718778EEb0dbC2DE55740;
	address constant public BR3_SENIOR_MEMBERLIST = 0x26768a74819608B96fcC2a83Ba4A651b6b31AE96;
	address constant public BR3_SENIOR_OPERATOR = 0x378Ca1098eA1f4906247A146632635EC7c7e5735;
	address constant public BR3_SENIOR_TOKEN = 0x8d2b8Df9Cb35B875F9726F43a013caF16aEFA472;
	address constant public BR3_SENIOR_TRANCHE = 0x70B78902844691266D6b050A9725c5A6Dc328fc4;
	address constant public BR3_SHELF = 0xeCc564B98f3F50567C3ED0C1E784CbA4f97C6BcD;
	address constant public BR3_TINLAKE_CURRENCY = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
	address constant public BR3_TITLE = 0xd61E8D3Af157e70C175831C80BF331A16dC2442A;

	address constant public HTC2_ACTIONS = 0x80F33ED0A69935dd74310b9D0009D0BA647Cf223;
	address constant public HTC2_ASSESSOR = 0x6e40A9d1eE2c8eF95322b879CBae35BE6Dd2D143;
	address constant public HTC2_ASSESSOR_ADMIN = 0x35e805BA2FB7Ad4C8Ad9D644Ca9Bd34a49f5500d;
	address constant public HTC2_COLLECTOR = 0xDdA9c8631ea904Ef4c0444F2A252eC7B45B8e7e9;
	address constant public HTC2_COORDINATOR = 0xE2a04a4d4Df350a752ADA79616D7f588C1A195cF;
	address constant public HTC2_FEED = 0xdB9A84e5214e03a4e5DD14cFB3782e0bcD7567a7;
	address constant public HTC2_JUNIOR_MEMBERLIST = 0x0b635CD35fC3AF8eA29f84155FA03dC9AD0Bab27;
	address constant public HTC2_JUNIOR_OPERATOR = 0x6DAecbC801EcA2873599bA3d980c237D9296cF57;
	address constant public HTC2_JUNIOR_TOKEN = 0xAA67Bb563e14fBd4E92DCc646aAac0c00c7d9526;
	address constant public HTC2_JUNIOR_TRANCHE = 0x294309E42e1b3863a316BEb52df91B1CcB15eef9;
	address constant public HTC2_PILE = 0xE7876f282bdF0f62e5fdb2C63b8b89c10538dF32;
	address constant public HTC2_PROXY_REGISTRY = 0xC9045c815bF123ad12EA75b9A7c579C1e05051f9;
	address constant public HTC2_RESERVE = 0x573a8a054e0C80F0E9B1e96E8a2198BB46c999D6;
	address constant public HTC2_ROOT_CONTRACT = 0x4cA805cE8EcE2E63FfC1F9f8F2731D3F48DF89Df;
	address constant public HTC2_SENIOR_MEMBERLIST = 0x1Bc55bcAf89f514CE5a8336bEC7429a99e804910;
	address constant public HTC2_SENIOR_OPERATOR = 0xEDCD9e36017689c6Fc51C65c517f488E3Cb6C381;
	address constant public HTC2_SENIOR_TOKEN = 0xd511397f79b112638ee3B6902F7B53A0A23386C4;
	address constant public HTC2_SENIOR_TRANCHE = 0x1940E2A20525B103dCC9884902b0186371227393;
	address constant public HTC2_SHELF = 0x5b2b43b3676057e38F332De73A9fCf0F8f6Babf7;
	address constant public HTC2_TINLAKE_CURRENCY = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
	address constant public HTC2_TITLE = 0x669Db70d3A0D7941F468B0d907E9d90BD7ddA8d1;  

	address constant public FF1_ACTIONS = 0x80F33ED0A69935dd74310b9D0009D0BA647Cf223;
	address constant public FF1_AO_REWARD_RECIPIENT = 0xB170597E474CC124aE8Fe2b335d0d80E08bC3e37;
	address constant public FF1_ASSESSOR = 0x4e7D665FB7747747bd770CB35F604412249AE8bC;
	address constant public FF1_ASSESSOR_ADMIN = 0x71d8ec8bE0d8C694f0c177C9aCb531B1D9076D08;
	address constant public FF1_COLLECTOR = 0x459f12aE89A956E245800f692a1510F0d01e3d48;
	address constant public FF1_COORDINATOR = 0xD7965D41c37B9F8691F0fe83878f6FFDbCb90996;
	address constant public FF1_FEED = 0xcAB9ed8e5EF4607A97f4e22Ad1D984ADB93ce890;
	address constant public FF1_JUNIOR_MEMBERLIST = 0x3FBD11B1f91765B32BD1231922F1E32f6bdfCB1c;
	address constant public FF1_JUNIOR_OPERATOR = 0x0B5Fb20BF5381A92Dd026208f4177a2Af85DACB9;
	address constant public FF1_JUNIOR_TOKEN = 0xf2dEB8F74C5dDA88CCD606ea88cCD3fC9FC98a1F;
	address constant public FF1_JUNIOR_TRANCHE = 0xc3e80961386D0C52C0988c12C6665d3AB2E04f0D;
	address constant public FF1_PILE = 0x11C14AAa42e361Cf3500C9C46f34171856e3f657;
	address constant public FF1_PROXY_REGISTRY = 0xC9045c815bF123ad12EA75b9A7c579C1e05051f9;
	address constant public FF1_RESERVE = 0x78aF512B18C0893e77138b02B1393cd887816EDF;
	address constant public FF1_ROOT_CONTRACT = 0x4B6CA198d257D755A5275648D471FE09931b764A;
	address constant public FF1_SENIOR_MEMBERLIST = 0x6e79770F8B57cAd29D29b1884563556B31E792b0;
	address constant public FF1_SENIOR_OPERATOR = 0x3247f0d72303567A313FC87d04E533a845d1ba5A;
	address constant public FF1_SENIOR_TOKEN = 0x44718d306a8Fa89545704Ae38B2B97c06bF11FC1;
	address constant public FF1_SENIOR_TRANCHE = 0xCebdAb943781878627fd04e8E0641Ee73941B1C5;
	address constant public FF1_SHELF = 0x9C3a54AC3af2e1FC9ee49e991a0452629C9bca64;
	address constant public FF1_TINLAKE_CURRENCY = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
	address constant public FF1_TITLE = 0x9E0c12ab26CC7939Efe63f307Db4fF8E4D29EC82; 
	
	address constant public DBF1_ROOT_CONTRACT = 0xfc2950dD337ca8496C18dfc0256Fb905A7E7E5c6;
	address constant public DBF1_FEED = 0x00cD3AE59fdbd375A187BF8074DB59eDAF766C19;

	address constant public BL1_ROOT_CONTRACT = 0x0CED6166873038Ac0cc688e7E6d19E2cBE251Bf0;
	address constant public BL1_COORDINATOR = 0xdf69bf5826ADF9EE6E7316312CE521988305C7B2;

	address constant public CF4_ROOT_CONTRACT = 0xdB3bC9fB1893222d266762e9fF857EB74D75c7D6;
	address constant public CF4_COORDINATOR = 0xFc224d40Eb9c40c85c71efa773Ce24f8C95aAbAb;
}


////// src/spell.sol
/* pragma solidity >=0.7.0; */

/* import "./addresses.sol"; */

interface TinlakeRootLike {
    function relyContract(address, address) external;
    function denyContract(address, address) external;
}

interface FileLike {
    function file(bytes32, uint) external;
    function file(bytes32, address) external;
}

interface NAVFeedLike {
    function file(bytes32 name, uint value) external;
    function file(bytes32 name, uint risk_, uint thresholdRatio_, uint ceilingRatio_, uint rate_, uint recoveryRatePD_) external;
    function discountRate() external returns(uint);
}

contract TinlakeSpell is Addresses {

    bool public done;
    string constant public description = "Tinlake Rate Update spell";

    uint constant public br3_seniorInterestRate = uint(1000000003170979198376458650); // 10.00%
    uint constant public br3_discountRate = uint(1000000004100076103500761035); // 12.93%

    uint constant public htc2_seniorInterestRate = uint(1000000002219685438863521055); // 7.00%
    address constant public htc2_oracle = 0x47B4B2a7a674da66a557a508f3A8e7b68a4759C3;

    uint constant public ff1_seniorInterestRate = uint(1000000001585489599188229325); // 5.00%

    address constant public dbf1_oracle = 0xE84a6555777452c34Bc1Bf3929484083E81d940a;

    uint constant public bl1_minEpochTime = 1 days - 10 minutes;
    uint constant public cf4_challengeTime = 30 minutes;

    uint256 constant ONE = 10**27;
    address self;
    
    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
        updateBR3();
        updateHTC2();
        updateFF1();
        updateDBF1();
        updateBL1();
        updateCF4();
    }

    function updateBR3() internal {
        TinlakeRootLike root = TinlakeRootLike(address(BR3_ROOT_CONTRACT));
        NAVFeedLike navFeed = NAVFeedLike(address(BR3_FEED));

        root.relyContract(BR3_ASSESSOR, address(this));
        root.relyContract(BR3_FEED, address(this));

        FileLike(BR3_ASSESSOR).file("seniorInterestRate", br3_seniorInterestRate);
        navFeed.file("discountRate", br3_discountRate);
    }

    function updateHTC2() internal {
        TinlakeRootLike root = TinlakeRootLike(address(HTC2_ROOT_CONTRACT));
        NAVFeedLike navFeed = NAVFeedLike(address(HTC2_FEED));

        root.relyContract(HTC2_ASSESSOR, address(this));
        root.relyContract(HTC2_FEED, address(this));
        root.relyContract(HTC2_FEED, htc2_oracle);

        FileLike(HTC2_ASSESSOR).file("seniorInterestRate", htc2_seniorInterestRate);

        // risk group: 1 - , APR: 5%
        navFeed.file("riskGroup", 1, ONE, ONE, uint(1000000001585490000), 99.95*10**25);
        // risk group: 2 - , APR: 5.25%
        navFeed.file("riskGroup", 2, ONE, ONE, uint(1000000001664760000), 99.93*10**25);
        // risk group: 3 - , APR: 5.5%
        navFeed.file("riskGroup", 3, ONE, ONE, uint(1000000001744040000), 99.91*10**25);
        // risk group: 4 - , APR: 5.75%
        navFeed.file("riskGroup", 4, ONE, ONE, uint(1000000001823310000), 99.9*10**25);
        // risk group: 5 - , APR: 6%
        navFeed.file("riskGroup", 5, ONE, ONE, uint(1000000001902590000), 99.88*10**25);
        // risk group: 6 - , APR: 6.25%
        navFeed.file("riskGroup", 6, ONE, ONE, uint(1000000001981860000), 99.87*10**25);
        // risk group: 7 - , APR: 6.5%
        navFeed.file("riskGroup", 7, ONE, ONE, uint(1000000002061140000), 99.85*10**25);
        // risk group: 8 - , APR: 6.75%
        navFeed.file("riskGroup", 8, ONE, ONE, uint(1000000002140410000), 99.84*10**25);
        // risk group: 9 - , APR: 7%
        navFeed.file("riskGroup", 9, ONE, ONE, uint(1000000002219690000), 99.82*10**25);
        // risk group: 10 - , APR: 7.25%
        navFeed.file("riskGroup", 10, ONE, ONE, uint(1000000002298960000), 99.81*10**25);
        // risk group: 11 - , APR: 7.5%
        navFeed.file("riskGroup", 11, ONE, ONE, uint(1000000002378230000), 99.79*10**25);
        // risk group: 12 - , APR: 7.75%
        navFeed.file("riskGroup", 12, ONE, ONE, uint(1000000002457510000), 99.78*10**25);
        // risk group: 13 - , APR: 8%
        navFeed.file("riskGroup", 13, ONE, ONE, uint(1000000002536780000), 99.76*10**25);
        // risk group: 14 - , APR: 8.25%
        navFeed.file("riskGroup", 14, ONE, ONE, uint(1000000002616060000), 99.74*10**25);
        // risk group: 15 - , APR: 8.5%
        navFeed.file("riskGroup", 15, ONE, ONE, uint(1000000002695330000), 99.73*10**25);
        // risk group: 16 - , APR: 8.75%
        navFeed.file("riskGroup", 16, ONE, ONE, uint(1000000002774610000), 99.71*10**25);
        // risk group: 17 - , APR: 9%
        navFeed.file("riskGroup", 17, ONE, ONE, uint(1000000002853880000), 99.7*10**25);
        // risk group: 18 - , APR: 9.25%
        navFeed.file("riskGroup", 18, ONE, ONE, uint(1000000002933160000), 99.68*10**25);
        // risk group: 19 - , APR: 9.5%
        navFeed.file("riskGroup", 19, ONE, ONE, uint(1000000003012430000), 99.67*10**25);
        // risk group: 20 - , APR: 9.75%
        navFeed.file("riskGroup", 20, ONE, ONE, uint(1000000003091700000), 99.65*10**25);
        // risk group: 21 - , APR: 10%
        navFeed.file("riskGroup", 21, ONE, ONE, uint(1000000003170980000), 99.64*10**25);
        // risk group: 22 - , APR: 10.25%
        navFeed.file("riskGroup", 22, ONE, ONE, uint(1000000003250250000), 99.62*10**25);
        // risk group: 23 - , APR: 10.5%
        navFeed.file("riskGroup", 23, ONE, ONE, uint(1000000003329530000), 99.61*10**25);
        // risk group: 24 - , APR: 10.75%
        navFeed.file("riskGroup", 24, ONE, ONE, uint(1000000003408800000), 99.59*10**25);
        // risk group: 25 - , APR: 11%
        navFeed.file("riskGroup", 25, ONE, ONE, uint(1000000003488080000), 99.58*10**25);
        // risk group: 26 - , APR: 11.25%
        navFeed.file("riskGroup", 26, ONE, ONE, uint(1000000003567350000), 99.56*10**25);
        // risk group: 27 - , APR: 11.5%
        navFeed.file("riskGroup", 27, ONE, ONE, uint(1000000003646630000), 99.54*10**25);
        // risk group: 28 - , APR: 11.75%
        navFeed.file("riskGroup", 28, ONE, ONE, uint(1000000003725900000), 99.53*10**25);
        // risk group: 29 - , APR: 12%
        navFeed.file("riskGroup", 29, ONE, ONE, uint(1000000003805180000), 99.51*10**25);
        // risk group: 30 - , APR: 12.25%
        navFeed.file("riskGroup", 30, ONE, ONE, uint(1000000003884450000), 99.5*10**25);
        // risk group: 31 - , APR: 12.5%
        navFeed.file("riskGroup", 31, ONE, ONE, uint(1000000003963720000), 99.48*10**25);
        // risk group: 32 - , APR: 12.75%
        navFeed.file("riskGroup", 32, ONE, ONE, uint(1000000004043000000), 99.47*10**25);
        // risk group: 33 - , APR: 13%
        navFeed.file("riskGroup", 33, ONE, ONE, uint(1000000004122270000), 99.45*10**25);
    }

    function updateFF1() internal {
        TinlakeRootLike root = TinlakeRootLike(address(FF1_ROOT_CONTRACT));
        NAVFeedLike navFeed = NAVFeedLike(address(FF1_FEED));

        root.relyContract(FF1_ASSESSOR, address(this));
        root.relyContract(FF1_FEED, address(this));

        FileLike(FF1_ASSESSOR).file("seniorInterestRate", ff1_seniorInterestRate);

        // risk group: 1 - P A, APR: 5.35%
        navFeed.file("riskGroup", 1, ONE, ONE, uint(1000000001696470000), 99.5*10**25);
        // risk group: 2 - P BBB, APR: 5.83%
        navFeed.file("riskGroup", 2, ONE, ONE, uint(1000000001848680000), 99.5*10**25);
        // risk group: 3 - P BB, APR: 6.3%
        navFeed.file("riskGroup", 3, ONE, ONE, uint(1000000001997720000), 99.5*10**25);
        // risk group: 4 - P B, APR: 6.77%
        navFeed.file("riskGroup", 4, ONE, ONE, uint(1000000002146750000), 99.5*10**25);
        // risk group: 5 - C, APR: 13.98%
        navFeed.file("riskGroup", 5, ONE, ONE, uint(1000000004433030000), 98.5*10**25);
    }

    function updateDBF1() internal {
        TinlakeRootLike root = TinlakeRootLike(address(DBF1_ROOT_CONTRACT));
        root.relyContract(DBF1_FEED, dbf1_oracle);
    }

    function updateBL1() internal {
        TinlakeRootLike root = TinlakeRootLike(address(BL1_ROOT_CONTRACT));
        root.relyContract(BL1_COORDINATOR, address(this));

        FileLike(BL1_COORDINATOR).file("minimumEpochTime", bl1_minEpochTime);
    }

    function updateCF4() internal {
        TinlakeRootLike root = TinlakeRootLike(address(CF4_ROOT_CONTRACT));
        root.relyContract(CF4_COORDINATOR, address(this));

        FileLike(CF4_COORDINATOR).file("challengeTime", cf4_challengeTime);
    }
}