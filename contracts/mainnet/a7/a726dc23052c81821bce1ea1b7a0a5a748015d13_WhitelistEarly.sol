/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

contract WhitelistEarly {
    
    mapping(address => bool) isWhitelistedEarly;
    
    constructor() {
        isWhitelistedEarly[0xAA4830313654C86417aca0292dd3573daf7905C8] = true;
        isWhitelistedEarly[0xFb5c4E3ACc53038B2d610F30c017479E9665C442] = true;
        isWhitelistedEarly[0x08257a3230469fCECBdA4155b27CBb65F75c40a4] = true;
        isWhitelistedEarly[0x20d60A9b4256920Dd556c0B42592CB1f355C02b1] = true;
        isWhitelistedEarly[0x5D9a1979c554F9f199d8390EBA88E25234882d3f] = true;
        isWhitelistedEarly[0x5f96816E479631903068520A407b5F170E989D2C] = true;
        isWhitelistedEarly[0x9D83Fb2d3f09b041AE6100647676155Db36B61aa] = true;
        isWhitelistedEarly[0x070339e8016ffC869dfAf647fbd78513a7d735b1] = true;
        isWhitelistedEarly[0x20548A781572163c3f48D5e6769368468d3Dea62] = true;
        isWhitelistedEarly[0x22aAce211cdd0280021D48717200c0119A8C3764] = true;
        isWhitelistedEarly[0xd1C72714182A7444DC543B7022ad4BeaB6A5dA45] = true;
        isWhitelistedEarly[0x353339c5EBc17B740BE010A6F7C5627b46B005e5] = true;
        isWhitelistedEarly[0xBA93f4686CBA0aA9652080EcC17d581425Ed7F13] = true;
        isWhitelistedEarly[0x168970485A76690DEF9CB863C11B49B608f49203] = true;
        isWhitelistedEarly[0x74C609f880EB4655fa3aBB448e221dE38325fa84] = true;
        isWhitelistedEarly[0x1002CA2d139962cA9bA0B560C7A703b4A149F6e0] = true;
        isWhitelistedEarly[0x353339c5EBc17B740BE010A6F7C5627b46B005e5] = true;
        isWhitelistedEarly[0x111d2a98D67dE15fBA25661ebC8276B0Fd87DCF8] = true;
        isWhitelistedEarly[0x1eb54C74F5f68502A5F270cb5609798caD6AC6F4] = true;
        isWhitelistedEarly[0x3b464c069A714F4d9a12B349b6120AF74c817bAA] = true;
    }
    
    function WhitelistedEarly(address _user) public view returns (bool) {
        return isWhitelistedEarly[_user];
    }   
}