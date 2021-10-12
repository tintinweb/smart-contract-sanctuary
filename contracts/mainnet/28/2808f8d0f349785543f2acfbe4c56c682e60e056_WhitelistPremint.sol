/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

contract WhitelistPremint {
    
    mapping(address => bool) isWhitelistedPremint;
    
    constructor() {
        isWhitelistedPremint[0x68bCaECbDe98A2B0086C7B8196182b74169BC940] = true;
        isWhitelistedPremint[0xa5b51559ed72a558368742E50394e089c53716aE] = true;
        isWhitelistedPremint[0xa9793B01BA723A37463E2e35ac7Ed98773820650] = true;
        isWhitelistedPremint[0x5E2FBCbbD05841159dCe188C315f0fAda689C123] = true;
        isWhitelistedPremint[0xd3022599033430bF3fDFb6D9CE41D3CdA7E20245] = true;
        isWhitelistedPremint[0xEf9Fdc930d645299D01440D82B6c417CBd8F7162] = true;
        isWhitelistedPremint[0x3bb9B35DDA5286b58d0Cf17d39F5a8c7122E81F0] = true;
        isWhitelistedPremint[0x976Cce61E57d9bfCfaaa53Ce25E4f9B839664043] = true;
        isWhitelistedPremint[0x539F3B2B465BDa0B4113a8C27c196ABF69e72EC0] = true;
        isWhitelistedPremint[0x90339c3d449b908eb51Ba9A5FC42Ef2Dc170C0a1] = true;
        isWhitelistedPremint[0x4253d654b574d29E118faE5A513C0C3793b6bAD5] = true;
        isWhitelistedPremint[0x6F82C06403bd30647e2fe25093BF4CAB377e19bf] = true;
        isWhitelistedPremint[0x7B07f10723e213E8E73f9E86DdaE0A03E7E126d6] = true;
        isWhitelistedPremint[0xfe0D666e2B1A69d57475C4D516AF1fD47FD2173c] = true;
        isWhitelistedPremint[0x1ab7079292872fC69052dc4Ef0f9c3417547C43b] = true;
        isWhitelistedPremint[0x1fe14e53d8C857DFcBFE01243dd922ACfB7cF46C] = true;
        isWhitelistedPremint[0x9bCBf958364AAd003552DE214Ab562B8aacbeE68] = true;
        isWhitelistedPremint[0x135e0109E96cb885DB973516CE37554d5764Cab9] = true;
        isWhitelistedPremint[0xC844A4a63bb232B8c1C761663bD5e98f4068b43F] = true;
        isWhitelistedPremint[0xc94894B2f11F68CF41e493673C5eE6cDC52e28D4] = true;
        isWhitelistedPremint[0xD24c3b537571826C11f48D8A27575eCb5e744604] = true;
        isWhitelistedPremint[0x590d531d00A3F83ee254fE8D0b8267b0189e9118] = true;
        isWhitelistedPremint[0xeA0e95671074c0B8fB9a699C2562932651021C32] = true;
        isWhitelistedPremint[0x16F49EA10C8F47Efb7035e1f2FCC1a7CB6D50a64] = true;
        isWhitelistedPremint[0xe715A88AC6166f9899B9ffE8C687d00CAC884CC0] = true;
        isWhitelistedPremint[0x76114A36054e02745F5aBeC5702606e7d6e5A584] = true;
        isWhitelistedPremint[0x6f2d9b59F562d3148845676646eA053cDA537632] = true;
        isWhitelistedPremint[0xe4c07654Ff5246AE3d3Fe94d630cD017F4CdfC3B] = true;
        isWhitelistedPremint[0x0755a358A82834569C81Ca4751649f2B763eEe8F] = true;
        isWhitelistedPremint[0xE13Bd3DE23D437B1EDde24b082b9AfB731f2f277] = true;
        isWhitelistedPremint[0x425c2E78D4d72A56DC3D8D134ef4b10a98EaAAd9] = true;
        isWhitelistedPremint[0x002A9a4A1c2a5bfB889833a1Af14eEC452bE86Da] = true;
        isWhitelistedPremint[0x30e867D2F3D1D5b645B21E0C4Cb451d492424A40] = true;
        isWhitelistedPremint[0x7cBF5D9d5FBB582045660C4BC81FE0339dcd12F8] = true;
        isWhitelistedPremint[0x111d2a98D67dE15fBA25661ebC8276B0Fd87DCF8] = true;
        isWhitelistedPremint[0x64EC28aba72F4C1a9dedc4EDA6c9CC72c0Ba2b1e] = true;
        isWhitelistedPremint[0x3E4a6212fF392A739010E203a7b82448A3f177cA] = true;
        isWhitelistedPremint[0xdAd536568Ba804AF3f2F8bc021Db8688cCEd420b] = true;
        isWhitelistedPremint[0xc0A4D627b3466c39878259d86debC362c3f96e7b] = true;
        isWhitelistedPremint[0x7dE874cD783C8387c63Aa86C7Bfd23254FF3832c] = true;
        isWhitelistedPremint[0x1002CA2d139962cA9bA0B560C7A703b4A149F6e0] = true;
        isWhitelistedPremint[0x80e151f1074C0D1cdcA8546BEe30934a4e6d1Af8] = true;
        isWhitelistedPremint[0x5B394506b8FFA2B7a7EACeddA1cA9f47BB75820f] = true;
    }
    
    function WhitelistedPremint(address _user) public view returns (bool) {
        return isWhitelistedPremint[_user];
    }   
}