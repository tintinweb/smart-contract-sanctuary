/**
 *Submitted for verification at Etherscan.io on 2021-11-23
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/draft/spell.sol
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

////// src/draft/addresses.sol

/* pragma solidity >=0.7.0; */

// Harbor Trade 2 addresses at Fri Nov 19 11:29:52 EST 2021
contract Addresses {
	address constant public ACTIONS = 0x80F33ED0A69935dd74310b9D0009D0BA647Cf223;
	address constant public ASSESSOR = 0xf2ED14102ee9D86606Ec24E48e89060ADB6DeFdb;
	address constant public ASSESSOR_ADMIN = 0x35e805BA2FB7Ad4C8Ad9D644Ca9Bd34a49f5500d;
	address constant public CLERK = 0xcC2B64dC91245110B513f0ad1393a9720F66B996;
	address constant public COLLECTOR = 0xDdA9c8631ea904Ef4c0444F2A252eC7B45B8e7e9;
	address constant public COORDINATOR = 0x37f3D10Bd18124a16f4DcCA02D41F910E3Aa746A;
	address constant public FEED = 0xdB9A84e5214e03a4e5DD14cFB3782e0bcD7567a7;
	address constant public JUNIOR_MEMBERLIST = 0x0b635CD35fC3AF8eA29f84155FA03dC9AD0Bab27;
	address constant public JUNIOR_OPERATOR = 0x6DAecbC801EcA2873599bA3d980c237D9296cF57;
	address constant public JUNIOR_TOKEN = 0xAA67Bb563e14fBd4E92DCc646aAac0c00c7d9526;
	address constant public JUNIOR_TRANCHE = 0x7fe1dBcBEA4e6D3846f5caB67cfC9fce39BF4d71;
	address constant public PILE = 0xE7876f282bdF0f62e5fdb2C63b8b89c10538dF32;
	address constant public POOL_ADMIN = 0xad88b6F193bF31Be0a44A2914809BC517b03D22e;
	address constant public PROXY_REGISTRY = 0xC9045c815bF123ad12EA75b9A7c579C1e05051f9;
	address constant public RESERVE = 0x86284A692430c25EfF37007c5707a530A6d63A41;
	address constant public ROOT_CONTRACT = 0x4cA805cE8EcE2E63FfC1F9f8F2731D3F48DF89Df;
	address constant public SENIOR_MEMBERLIST = 0x1Bc55bcAf89f514CE5a8336bEC7429a99e804910;
	address constant public SENIOR_OPERATOR = 0xEDCD9e36017689c6Fc51C65c517f488E3Cb6C381;
	address constant public SENIOR_TOKEN = 0xd511397f79b112638ee3B6902F7B53A0A23386C4;
	address constant public SENIOR_TRANCHE = 0x7E410F288583BfEe30a306F38e451a93Caaa5C47;
	address constant public SHELF = 0x5b2b43b3676057e38F332De73A9fCf0F8f6Babf7;
	address constant public TINLAKE_CURRENCY = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
	address constant public TITLE = 0x669Db70d3A0D7941F468B0d907E9d90BD7ddA8d1;  
}


////// src/draft/spell.sol
/* pragma solidity >=0.7.0; */
/* pragma experimental ABIEncoderV2; */

/* import "./addresses.sol"; */

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
    string constant public description = "HTC discount rate change mainnet spell";

    uint[3] discountRates = [1000000002853881278538812785, 1000000002576420598680872653, 1000000002298959918822932521];
    uint[3] timestamps;
    bool[3] rateAlreadySet = [false, false, false];
    
    // permissions to be set
    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
        SpellTinlakeRootLike root = SpellTinlakeRootLike(ROOT_CONTRACT);

        root.relyContract(FEED, address(this));
    
        timestamps = [
            block.timestamp + 0 days,
            block.timestamp + 7 days,
            block.timestamp + 21 days
        ];

        setDiscount(0);
    }

    function setDiscount(uint i) public {
        require(block.timestamp >= timestamps[i], "not-yet-executable");
        require(i == 0 || NAVFeedLike(FEED).discountRate() == discountRates[i-1], "incorrect-execution-order");
        require(rateAlreadySet[i] == false, "already-executed");

        rateAlreadySet[i] = true;
        NAVFeedLike(FEED).file("discountRate", discountRates[i]);
    }

}