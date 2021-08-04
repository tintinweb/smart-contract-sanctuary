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

// GIG Pool addresses at Wed Aug  4 10:21:20 CEST 2021
contract Addresses {
	address constant public ACTIONS = 0x80F33ED0A69935dd74310b9D0009D0BA647Cf223;
	address constant public ASSESSOR = 0x87C67534d9aF78d678101f2dE0F796F4d911697a;
	address constant public ASSESSOR_ADMIN = 0xc9caE66106B64D841ac5CB862d482704569DD52d;
	address constant public CLERK = 0x8Fd59d6869b313eF4aeA5d979D4f97fa5fF4c07E;
	address constant public COLLECTOR = 0x5C90e483f32C3FE88261fba02E66D1E6C2f5DBcC;
	address constant public COORDINATOR = 0x12688FffCbebf876dC22E024C21c0AA02902e559;
	address constant public FEED = 0x468eb2408c6F24662a291892550952eb0d70b707;
	address constant public JUNIOR_MEMBERLIST = 0x7D28C732B7B8498665Df973f52059C51476DB4E1;
	address constant public JUNIOR_OPERATOR = 0x2540A03ba843eEC2c15B1c317117F3c2e2514e5D;
	address constant public JUNIOR_TOKEN = 0x6408E86B8F80F6c265a5ECDa0c3a9f654f9Cc80F;
	address constant public JUNIOR_TRANCHE = 0xb46A80A5337c70a80b1003826DE1D9796Ee69E8f;
	address constant public MAKER_MGR = 0x5726eBB2B741FED41a1Fb0F402F40A9261BEB60c;
	address constant public MKR_JUG = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
	address constant public MKR_VAT = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;
	address constant public PILE = 0x9E39e0130558cd9A01C1e3c7b2c3803baCb59616;
	address constant public POOL_ADMIN = 0xD8BF797E416ac564db24143c96A850a9AcAb10C3;
	address constant public PROXY_REGISTRY = 0xC9045c815bF123ad12EA75b9A7c579C1e05051f9;
	address constant public RESERVE = 0x1794A4B29fF2eCdC044Ad5d4972Fa118D4C121b9;
	address constant public ROOT_CONTRACT = 0x3d167bd08f762FD391694c67B5e6aF0868c45538;
	address constant public SENIOR_MEMBERLIST = 0xEcc423aB19AFdae990a7afaD0616Bd02E9809495;
	address constant public SENIOR_OPERATOR = 0x429B14613A804F8212052C6AeA0939229C819647;
	address constant public SENIOR_TOKEN = 0xA08399989e77B8Ce8Dd68374cC7b4345304b3161;
	address constant public SENIOR_TRANCHE = 0x408A885c2fc354b70e737565cae86b4c10A92Ac7;
	address constant public SHELF = 0x661f03AcE6Bd3087201503541ac7b0Cb1185d673;
	address constant public TINLAKE_CURRENCY = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
	address constant public TITLE = 0x4AC844d4B76A1E17a1EA0CED8582eAa49253e807;  
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