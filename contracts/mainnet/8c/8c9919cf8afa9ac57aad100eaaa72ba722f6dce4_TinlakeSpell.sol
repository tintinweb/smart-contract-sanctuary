/**
 *Submitted for verification at Etherscan.io on 2021-08-04
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/draft/spell.sol
// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.0;
pragma experimental ABIEncoderV2;

////// src/draft/addresses.sol

/* pragma solidity >=0.7.0; */

// Untangled 1 addresses at Wed Aug  4 10:54:00 CEST 2021
contract Addresses {
	address constant public ACTIONS = 0x80F33ED0A69935dd74310b9D0009D0BA647Cf223;
	address constant public ASSESSOR = 0xdBBa712f10061A3c7619Dc46852d8399F33C9fC7;
	address constant public CLERK = 0xAb028F84521ECAe4F03a846743F619F6b1532f87;
	address constant public COLLECTOR = 0x8E341534acc586903B930B160e58bc68Bd7Cfbd6;
	address constant public COORDINATOR = 0x7359206302EC387C6db94422f09203915F15eB89;
	address constant public FEED = 0x800aa0DD91374364E3De476D97dca32848CeA6c4;
	address constant public JUNIOR_MEMBERLIST = 0xF32bAC8a57f2e7354bb82D05DCEe658A5Db5981a;
	address constant public JUNIOR_OPERATOR = 0x2840292eeC553c5816e7715a1427BfeD69EBF82E;
	address constant public JUNIOR_TOKEN = 0x0097f415bf4C1B5d1145896D7de74f3f767d5A31;
	address constant public JUNIOR_TRANCHE = 0x3Bb758A44034BDDFe44D50bA0eDE962B699665Fd;
	address constant public MAKER_MGR = 0x5390e37a59748F0884609789EA90957b3803056D;
	address constant public MKR_JUG = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
	address constant public MKR_VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
	address constant public PILE = 0xB7d1DE24c0243e6A3eC4De9fAB2B19AB46Fa941F;
	address constant public POOL_ADMIN = 0x545D98baa87B9C13305b081ef102ECb6F4F6f3C0;
	address constant public PROXY_REGISTRY = 0xC9045c815bF123ad12EA75b9A7c579C1e05051f9;
	address constant public RESERVE = 0x6942f8779C5C4aa385121A3Ee203f2cA1D9d10bc;
	address constant public ROOT_CONTRACT = 0x9De3064f49696a25066252C35ede68850EA33BF8;
	address constant public SENIOR_MEMBERLIST = 0xe9Eaf8054476F73782B408b4F20CDfA277390817;
	address constant public SENIOR_OPERATOR = 0x2B1448781b53fd399f380a31FBa9f839e04889fA;
	address constant public SENIOR_TOKEN = 0x42A95D51a7bd4Ef4c3558E638F09268f4DE726c2;
	address constant public SENIOR_TRANCHE = 0xe66162910e6d28965D1A90bB15Bb0E861745115F;
	address constant public SHELF = 0xE80C9e9fbaE9868e1D645f9727436afE5381047A;
	address constant public TINLAKE_CURRENCY = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
	address constant public TITLE = 0x1d903bd1C602Ef3A64f47E9aaDC85BC80a38A28E;  
}


////// src/draft/spell.sol
/* pragma solidity >=0.7.0; */
/* pragma experimental ABIEncoderV2; */

/* import "./addresses.sol"; */

interface SpellTinlakeRootLike {
    function relyContract(address, address) external;
}

interface DependLike {
    function depend(bytes32, address) external;
}

contract TinlakeSpell is Addresses {

    bool public done;
    string constant public description = "Tinlake clerk unwiring mainnet spell";

    // permissions to be set
    function cast() public {
        require(!done, "spell-already-cast");
        done = true;
        execute();
    }

    function execute() internal {
        SpellTinlakeRootLike root = SpellTinlakeRootLike(ROOT_CONTRACT);

        root.relyContract(ASSESSOR, address(this));
        root.relyContract(RESERVE, address(this));

        DependLike(ASSESSOR).depend("lending", address(0));
        DependLike(RESERVE).depend("lending", address(0));
    }

}