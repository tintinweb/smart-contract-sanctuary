pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";

abstract contract ClaimableWithSvin is Ownable {
    mapping(address => uint) _svinBalances;

    function initSvinBalances() internal {
        _svinBalances[0x034a45B00000AF335F81A38D1a36cB555D516A92] = 1;
        _svinBalances[0x047cfa189b23203c3d2d16550f4683c50da78392] = 1;
        _svinBalances[0x05AE0683d8B39D13950c053E70538f5810737bC5] = 1;
        _svinBalances[0x05B0319c6f3AA8A895cA30B5eEb29657C1285983] = 1;
        _svinBalances[0x0605ABe3d7F1268b816c1EDfbF96e3e1828b9F22] = 1;
        _svinBalances[0x06899B851e0Cc9B1e9348C0E985E6c5454bBd889] = 3;
        _svinBalances[0x07b24ba3e50Be7b4411138823176f4382163D59a] = 1;
        _svinBalances[0x080E285cBe0B28b06B2F803C59D0CBE541201ADE] = 4;
        _svinBalances[0x094cb885eb92607aF232825c5a9B64318709749F] = 1;
        _svinBalances[0x0C93929360FF8b46a46c2dE1C8eDeA9541B78eB3] = 1;
        _svinBalances[0x0caC9C3D7196f5BbD76FaDcd771fB69b772c0F9d] = 1;
        _svinBalances[0x0E5a1d84eD69067C078596bc6A17452425B005F1] = 1;
        _svinBalances[0x0e8A9d56cEd084A70926A7B5c1c48EAcc441e138] = 1;
        _svinBalances[0x12269196C57e800824762E5ed667b5b8BA5e364E] = 3;
        _svinBalances[0x122b0eaa0a4252CEfcB877f0BF608bAe2cF7CA9e] = 1;
        _svinBalances[0x12417A1213D1863dCA5BA87eE6Fb4da479772e3f] = 11;
        _svinBalances[0x12CCdf3513f8f09f4C0E6Ad7821988a7A8Ac0bE1] = 1;
        _svinBalances[0x12Edc1D51bF2dD34C3703B7521F871E7e9A37C67] = 2;
        _svinBalances[0x17E72A77A84C2705E77C686a3f756ce9d3637C58] = 1;
        _svinBalances[0x1813183E1A2a5a565d09b0F16a868A4e1b7610c0] = 1;
        _svinBalances[0x1a7B50e158a478DcA8A7EE1f5b1c86154692Aba5] = 1;
        _svinBalances[0x1ac59132270545cD927fB7cE80E7C00f278C2673] = 1;
        _svinBalances[0x1b21A4287CBfA8F81753de2A17028Bf2fA231034] = 2;
        _svinBalances[0x1b640c003d3F8Bba7aD69C9121cCbC94203Eb3c4] = 1;
        _svinBalances[0x1b8565F9336Ea2d9145005303520957E254171fe] = 2;
        _svinBalances[0x1BB2f62f9958eC1F875E4B0B42fD775eE3FD955E] = 1;
        _svinBalances[0x1c1382c9aDc5CE1f93c55914F2FBCaD07747aA84] = 2;
        _svinBalances[0x1c2E4b068f69A46d8Cf7995db90D38428163B979] = 2;
        _svinBalances[0x1D5C30676cA03adAe00257568B830C8D424A1e53] = 2;
        _svinBalances[0x1D7B087234D89510bE132F8835C04d696Be4F43a] = 1;
        _svinBalances[0x1dAC5Bf20722e462B3c388d4D1153836926C9b5C] = 6;
        _svinBalances[0x1FC4B87ce7C31507ec1d0cCAE20e674B13840a6C] = 1;
        _svinBalances[0x203019c38E4890E81A5d8C9513b97aEc0fC2FC66] = 1;
        _svinBalances[0x20cca2DfCCa8ed99E559c9f3FB08cC406b3fC2df] = 1;
        _svinBalances[0x21B33d5bfF0B07462bCb3E2613cbeAeC909588d0] = 1;
        _svinBalances[0x22085DdF122BbE0C74bf8822a8B0034B34e7B00c] = 1;
        _svinBalances[0x23a35DCc4dbEeA3CbAC3Ae1db37Cb87c625b8F54] = 1;
        _svinBalances[0x24D8E4a8d59f00C370ca6f9344Ed8Ba47f74D85f] = 5;
        _svinBalances[0x25c84928c5CF3971a4CeAdf26F1808a3E11CF374] = 1;
        _svinBalances[0x26CfD6f7Ae12c677aff5e0eDe78D85054A9351B3] = 4;
        _svinBalances[0x2734a7F407d296311A0FD83e04c05e0CC76b4A34] = 1;
        _svinBalances[0x27f8F53eb60877607A589051B181ec3Df2118d11] = 1;
        _svinBalances[0x28E174a5797C60D34b338F5Fc3155Cb4571B19A9] = 1;
        _svinBalances[0x28E3E03240c4B7101c474BDBCAB13c6Bc42Cc7eb] = 1;
        _svinBalances[0x291121dA7faEEDd25CEfc0E289B359dE52b8050c] = 4;
        _svinBalances[0x2A41282434f89f5bbF272B1091A7A0ceFD22Ccd8] = 1;
        _svinBalances[0x2D036b57ec3713704Db5fBdF0eC3F5991cB79A08] = 4;
        _svinBalances[0x2dF23b2807E421085efF3035191EAfa5a5E17545] = 1;
        _svinBalances[0x2F60d06Fa6795365B7b42B27Fa23e3e8c8b82f66] = 1;
        _svinBalances[0x30b4a5477314e3FbD0C22D6Afcd71EeCF4d9D22F] = 1;
        _svinBalances[0x338F8AdbaEfe63cb4526F693c586c26D77A6dCD9] = 1;
        _svinBalances[0x33F0F57DCd106DF64FA2B8991cd6bDAe8f53dcf5] = 2;
        _svinBalances[0x366c0ae1eDBE7c648Bb63fC343910B4e54eE5F87] = 1;
        _svinBalances[0x38bf30d3F1528BBD2BB8A242E9a0F4405affb8d0] = 1;
        _svinBalances[0x3c2262255793f2b4629F7b9A2D57cE78f7842A8d] = 2;
        _svinBalances[0x3C9A28263B5Becf6b0773BF9736b9d0D5F08Cb06] = 2;
        _svinBalances[0x3D7f2165d3d54eAF9F6af52fd8D91669D4E02ebC] = 1;
        _svinBalances[0x3E1ffCda317FE588F5c217fBA8C22F82B368A249] = 2;
        _svinBalances[0x3f3E2f43f0aC69f30ec38d3E4FEC304bdF330E7A] = 1;
        _svinBalances[0x446a6560f8073919D8402c98dB55dB342A20300B] = 4;
        _svinBalances[0x4518344525d32415F3ebdA186bDB2C375D9443d6] = 2;
        _svinBalances[0x454C66152A110Eb759b2fC09Ddc52cd74Dca3f54] = 3;
        _svinBalances[0x484749B9d349B3053DfE23BAD67137821D128433] = 1;
        _svinBalances[0x48756f98f4b56Da7077d1cE5a71056e9b9b3F0B1] = 1;
        _svinBalances[0x487Ee33B7243A51e7091103dC079C1f5eED7518d] = 1;
        _svinBalances[0x48cb2253e3a83bB312d9AE7797A3FcBE835b7C26] = 2;
        _svinBalances[0x4a93A25509947d0744eFc310ae23C1a15bE7c19b] = 1;
        _svinBalances[0x4D4f9ede676f634DBd36755C4eE5FDB49377df88] = 3;
        _svinBalances[0x4D633603A302C771e600590388606632c9447d76] = 1;
        _svinBalances[0x4d88DBF593A0dAd711AEc4c02A7CEE79eF6e725C] = 1;
        _svinBalances[0x4db09171350Be4f317a67223825abeCC65482E32] = 2;
        _svinBalances[0x4DB0c7466F177ec218d8735Ee4729634Ae434BAa] = 1;
        _svinBalances[0x4F234aE48179a51E02b0566E885fcc8a1487dB02] = 1;
        _svinBalances[0x4F5eC5bd224218ca16b4D9E66858c149a4b6465c] = 7;
        _svinBalances[0x544Ea5eFaC91017A96072E153C279050Fd9bf861] = 2;
        _svinBalances[0x550e970E31A45b06dF01a00b1C89A478D4d5e00A] = 7;
        _svinBalances[0x55594059b44f73c0038699B42132B639262F186B] = 2;
        _svinBalances[0x558c43d33919775f1eb4e26aa488DaB361f95f74] = 2;
        _svinBalances[0x55A9C5180DCAFC98D99d3f3E4B248E9156B12Ac1] = 2;
        _svinBalances[0x573bF0D4D215C2f6cD58dE04c38B81E855F1D7a8] = 2;
        _svinBalances[0x58D49377C74Fe5aA1C098D9ed4161248b73faa30] = 1;
        _svinBalances[0x591F8a2deCC1c86cce0c7Bea22Fa921c2c72fb95] = 1;
        _svinBalances[0x5A4a8f46972ad7eBb1A366680C94AD24e9650c05] = 1;
        _svinBalances[0x5b9b338646317E8BD7E3f2FcB45d793f3363AD1B] = 1;
        _svinBalances[0x5D18C78f374286D1FA6B1880545BFAD714c29273] = 2;
        _svinBalances[0x5f8b9B4541Ecef965424f1dB923806aAD626Add2] = 1;
        _svinBalances[0x5FD2C02689d138547B7b1b9E7d9A309d5A03edCd] = 4;
        _svinBalances[0x61ad944C6520116Fff7d537a789d28391A7A6425] = 1;
        _svinBalances[0x638b2Aa3DFc973c9dc727060cB54D7E39541B7F5] = 1;
        _svinBalances[0x65b89f14C1AADd7E24dD0bd1cA080ce964E1237E] = 4;
        _svinBalances[0x678B8f0026fb7893b249C83a2e89f711b0DDb385] = 1;
        _svinBalances[0x67C6CD886f6F29aa6b124698d84d3E472177BA29] = 2;
        _svinBalances[0x68C62D8db8dB114dD39A1bfac9A43D146b86fC06] = 1;
        _svinBalances[0x69C38C760634C23F3a3D9bE441ecCbD2e50e5F73] = 1;
        _svinBalances[0x6b611D278233CB7ca76FD5C08579c3337C01e577] = 2;
        _svinBalances[0x711bdaFEA11Ca315e29a331d427d9f375b185766] = 1;
        _svinBalances[0x71649d768128DfC64734CB58713e972e045421Dc] = 2;
        _svinBalances[0x719f973d8Fe35F35C56d634B4D70E2791Dc960C4] = 1;
        _svinBalances[0x73dEAEB8aA241b6fcdB992060Ae43193CcCBf638] = 2;
        _svinBalances[0x750364CcecC0250C2160b5e1Cc9F9AFdAA99138b] = 1;
        _svinBalances[0x7675291453DAf025cEF152bef7296D4Ef9d72514] = 3;
        _svinBalances[0x767aE578b41BE33A9acBeF5e70dfaBFC4DACEA5e] = 1;
        _svinBalances[0x7833A725c3d5A2B583CbBeaAF3c50a01E2d81d91] = 1;
        _svinBalances[0x78b95D0e7A72A5C70B3c1d544F2979b47dE3541c] = 2;
        _svinBalances[0x7a277Cf6E2F3704425195caAe4148848c29Ff815] = 1;
        _svinBalances[0x7a6DAAE2255491c56D82c44e522cBaC4b601985F] = 1;
        _svinBalances[0x7D112B3216455499f848ad9371df0667a0d87Eb6] = 4;
        _svinBalances[0x7dAa8740FE15F9A0334Ff2d6210eF65BD61ee8Bf] = 1;
        _svinBalances[0x7DdF9BEB649c25F74C5EAc6CA8B4aa2Dda3b028D] = 1;
        _svinBalances[0x7e00f4110Fb7D02A91632895FB93cd09af3209c6] = 7;
        _svinBalances[0x7f8C2e2AF79E43f957064356c641b07316BE7a2c] = 1;
        _svinBalances[0x7fb6F52996ba02884Fd4Cd136bB2af3D8909c56C] = 1;
        _svinBalances[0x82B3b4BE8033dFB277c70AE9b4e1EFB0ae08cB93] = 1;
        _svinBalances[0x85345e4095dfd7d5252A69a9a7537AfdA09B1280] = 1;
        _svinBalances[0x869c9009A0d8279B63D83040a1aCC96a6Ad8Bf89] = 1;
        _svinBalances[0x886478D3cf9581B624CB35b5446693Fc8A58B787] = 1;
        _svinBalances[0x8DC2ce42b6b2b2255E9B094Dbe79f97774767458] = 5;
        _svinBalances[0x8e101059Bd832496fC443D47ca2B6D0767b288DF] = 1;
        _svinBalances[0x906c2F8e230B61dd183E0696265F8FED8A1a387b] = 1;
        _svinBalances[0x90c19feA1eF7BEBA9274217431F148094795B074] = 6;
        _svinBalances[0x90C40098d9146729506E5B4087F8765e10c13061] = 1;
        _svinBalances[0x913D0C60b9BeFC1b16f551465863fDD643Eb81b4] = 2;
        _svinBalances[0x99df8a2b8d02bADe773Fa7451A69E05e1d86a05D] = 1;
        _svinBalances[0x99ED7190511ac2B714fFbb9e4E1817f6851EF9f5] = 1;
        _svinBalances[0x9A428d7491ec6A669C7fE93E1E331fe881e9746f] = 1;
        _svinBalances[0x9b6faDedcbE50876eaB12F5109E4C370cb97089E] = 4;
        _svinBalances[0x9C0A9b7ffE633AD11963745f2b7c604F8a97194C] = 1;
        _svinBalances[0x9CA26730aa028D098C52C3974ab89eC81c74f56c] = 1;
        _svinBalances[0x9dff008EDA68184Fbc2dA18AB7d31f3BA1A77dB3] = 2;
        _svinBalances[0xa01dd79c6A09CD5d51278dba059114Bc2Cb5eBCe] = 4;
        _svinBalances[0xa1c384289A9cAFB44A4f792aCf2E7f9Ac5E5f3aD] = 1;
        _svinBalances[0xA49958fa14309F3720159c83cD92C5F38B1e3306] = 1;
        _svinBalances[0xa4edADe797b3C429E07527B46eB0a9F60a4D4B8E] = 1;
        _svinBalances[0xA53a742502A374B3916049067EadA96a8Da5c42C] = 1;
        _svinBalances[0xa85819617a048287Ae2f5bA42740D7d71C9e439C] = 1;
        _svinBalances[0xA8b09b62B0ADDB3c89195466Ee15Cc9e825d6877] = 1;
        _svinBalances[0xa9a94502637Fd1642DB5b4416a34b9cAf034D553] = 1;
        _svinBalances[0xaA4681293F717Ec3118892bC475D601ca793D840] = 1;
        _svinBalances[0xAB6cA2017548A170699890214bFd66583A0C1754] = 4;
        _svinBalances[0xABA24Dc8b54B4e5d8B609cacEe3D1dcA6530f36E] = 1;
        _svinBalances[0xacc013315c848293A57641486aEB707e302cBdb5] = 1;
        _svinBalances[0xadA13FC7089745118D55468d8b384f2697c33e14] = 1;
        _svinBalances[0xB00CD8e790eC45971A04695849a17a647eB74463] = 1;
        _svinBalances[0xb104371D5a2680fB0d47eA9A3aA2348392454186] = 30;
        _svinBalances[0xB381dF6c35235AbD138Df31E64B0d7a3104a4AeB] = 1;
        _svinBalances[0xB3ab08E50adaF5d17B4ED045E660a5094a83bc01] = 2;
        _svinBalances[0xb5A2b414B3c4E0fBd905095E6A8CfeA736def914] = 1;
        _svinBalances[0xb5d3947335A87a30fE11f51C99D0B4644716dA71] = 1;
        _svinBalances[0xB6DC34F69d7973eb7C26D173644685F78E3b9858] = 1;
        _svinBalances[0xB71fE696c3967E79fb5A36c7894230882923fD39] = 1;
        _svinBalances[0xb99426903d812A09b8DE7DF6708c70F97D3dD0aE] = 5;
        _svinBalances[0xbA726320a6D963b3a9E7E3685fb12AEA71Af3f6d] = 2;
        _svinBalances[0xBAA02edb7cb6dc2865bC2440de9caf6A9E31f23e] = 4;
        _svinBalances[0xbaaaBce9D8b6e0e7b26E107f33DdfC7Bd582E301] = 1;
        _svinBalances[0xbD6907023e8129C6219536C1Bf2e7FB9e0CEd8E1] = 2;
        _svinBalances[0xc071823c582c2ecdfE5306F20af4e5Bd3C51e25e] = 1;
        _svinBalances[0xC0d5445b157bDcCCa8A3FfE6761925Cf9fc97Df7] = 1;
        _svinBalances[0xc1fA63BD4189a9C49A30010B6a3aB11194A95842] = 1;
        _svinBalances[0xC26241D386dD0c1e711C7104fCf72b7C6e0ECc0b] = 1;
        _svinBalances[0xc3D3f90e2210bbE23690E32B80A81745EB4dB807] = 1;
        _svinBalances[0xC6A50A166Be98087078DaF764417fa4E2b405542] = 3;
        _svinBalances[0xc6Cc7f25Ba045B8c08Fb84aA1494b106Fb6824a5] = 4;
        _svinBalances[0xC792b1a1CD45631b7b9D213Cf108A16DE34Ee9c9] = 1;
        _svinBalances[0xc8F1a199EEb0ECCedfb0F401b828EE6Fb894aaa7] = 1;
        _svinBalances[0xCA50Cc37abaA58d19E3A23CCB086f17F8384cb3C] = 1;
        _svinBalances[0xCA6B710cbeF9ffE90D0Ab865b76D6e6bBa4Db5f9] = 2;
        _svinBalances[0xcAeF892f50DB75582139b5d5145284ad31CD4912] = 4;
        _svinBalances[0xD1216994Acc2e0201c04db6397882791973d8984] = 2;
        _svinBalances[0xD1BBdE3515d075CB2741CAA92ad0C03bad4d9D4A] = 2;
        _svinBalances[0xd36954DF517cFd9D533d4494B0E62B61c02Fc29a] = 1;
        _svinBalances[0xd4Db6d8Ef756141DE0D838808Ddb8fFCd847D7ff] = 2;
        _svinBalances[0xd559eb2bdF862d7a82d716050D56599F03Ef44E7] = 15;
        _svinBalances[0xd5a9C4a92dDE274e126f82b215Fccb511147Cd8e] = 3;
        _svinBalances[0xd5e8A9a3839ba67be8A5fFEACAD5Aa23Acce75bB] = 2;
        _svinBalances[0xd78F0E92C56C45Ff017B7116189eB5712518a7E9] = 2;
        _svinBalances[0xd815FEaeb858838690440F7298Eb0465b27a7Ff4] = 1;
        _svinBalances[0xD83C7bcED50Ba86f1C1FBf29aBba278E3659F72A] = 2;
        _svinBalances[0xDc62e941fDDBDdDFc666B133E24E0C1aFae11847] = 2;
        _svinBalances[0xdC8bBaCAc5142A91637c4ebbDF33946bFB48BC50] = 1;
        _svinBalances[0xdd8b6fB4c5fD3eF7a45B08aa64bDe01Ddc1b207E] = 4;
        _svinBalances[0xDeC51742Cd5B54eECC66b08d0A784488B29e2c89] = 5;
        _svinBalances[0xe288a00DF4b697606078876788e4D64633CD2e01] = 2;
        _svinBalances[0xe2B1081Dc27703F36b444665254b0BDa0eE9ed27] = 1;
        _svinBalances[0xE2bDaE527f99a68724B9D5C271438437FC2A4695] = 1;
        _svinBalances[0xE7c7652969aB78b74c7921041416A82632EA7b2d] = 6;
        _svinBalances[0xe7dAe42Dee2BB6C1ef3c65e68d3E605faBcA875d] = 1;
        _svinBalances[0xe8D6c9f9ad3E7db3545CF15DeF74A2072F30e1Cb] = 1;
        _svinBalances[0xe913a5FE3FAA5F0fa0D420C87337c7CB99A0C6e5] = 9;
        _svinBalances[0xEA2c15B73e07Bdd59cAec75c08f675Fd4cb04229] = 1;
        _svinBalances[0xea39c551834D07EE2EE87f1cEFF843c308e089AF] = 24;
        _svinBalances[0xeAAB59269bD1bA8522E8e5E0FE510F7aa4d47A09] = 1;
        _svinBalances[0xED1f2d7Bc291209131D992De059723f492EE40F5] = 3;
        _svinBalances[0xeEF44ca98EB0c7E412366C020c6bD3cFaff8b33E] = 2;
        _svinBalances[0xEfBb701e123526d087e17bC18F417465fA09876a] = 1;
        _svinBalances[0xf02Cd6f7b3d001b3f81E747e73A06Ad73CbD5E5b] = 10;
        _svinBalances[0xF14c883B4940e0F8c4257D72674f003D8B6Cdb58] = 1;
        _svinBalances[0xf25Ad24b791E37e83F4dadFE212e0e9Bb45a1f8b] = 4;
        _svinBalances[0xF29BA56dC71f2Eeaf12252D94bf0Ad8F7a56AC02] = 7;
        _svinBalances[0xf5493d28b94521fe392F640aA78df3C68531964e] = 1;
        _svinBalances[0xf7785f2e2815ab19143a5Bab3050EDfe0C2bB470] = 1;
        _svinBalances[0xf8B202dE4dBeaeBda8dEf3614e81FB1E8294DCC7] = 1;
        _svinBalances[0xf9570Eb74727A6e08562C3ef799876706d86A5E2] = 4;
        _svinBalances[0xf972D156658508d6096f7576840a70780074bf0c] = 1;
        _svinBalances[0xFa8E37Da2E4cBA1f7B6E8d637Dc39f8df6D18526] = 1;
        _svinBalances[0xfC9dD877930e9799BeB663523BD31EefE3C99597] = 2;
        _svinBalances[0xFCBBdF31E9840807582f1F3571293b97918c1E4d] = 1;
        _svinBalances[0xFe5573C66273313034F7fF6050c54b5402553716] = 3;
        _svinBalances[0xDc62e941fDDBDdDFc666B133E24E0C1aFae11847] = 2;
    }

    function howManyFreePorks() public view returns (uint16) {
        return howManyFreePorksForAddress(msg.sender);
    }

    function howManyFreePorksForAddress(address target) public view returns (uint16) {
        uint svinBalanceForSender = _svinBalances[target];

        if (svinBalanceForSender >= 1 && svinBalanceForSender < 10) {
            return 1;
        }

        if (svinBalanceForSender >= 10) {
            return 3;
        }

        return 0;
    }

    function cannotClaimAnymore(address target) internal {
        _svinBalances[target] = 0;
    }

    function setFakeSvinBalance(address target, uint16 amountToSet) public onlyOwner {
        _svinBalances[target] = amountToSet;
    }
}

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

import "./common/meta-transactions/ContentMixin.sol";
import "./common/meta-transactions/NativeMetaTransaction.sol";
import "./ClaimableWithSvin.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

abstract contract Pork1984Minting is ERC721Enumerable {
    function _mintPork1984(address owner, uint256 startingIndex, uint16 number) internal {
        for (uint i = 0; i < number; i++) {
            _safeMint(owner, startingIndex + i);
        }
    }
}

abstract contract Pork1984Selling is Pork1984Minting, Pausable, ContextMixin, NativeMetaTransaction, ClaimableWithSvin {
    uint256 constant maxPork1984 = 9840;
    uint constant sellablePork1984StartingIndex = 600;
    uint constant giveawayPork1984StartingIndex = 20;
    uint constant specialPork1984StartingIndex  = 1;
    uint16 constant maxPork1984ToBuyAtOnce = 10;

    uint constant singlePork1984Price = 45100000 gwei;  // 0.0451 eth for one pork

    uint256 public nextPork1984ForSale;
    uint public nextPork1984ToGiveaway;
    uint public nextSpecialPork1984;

    constructor() {
        nextPork1984ForSale = sellablePork1984StartingIndex;
        nextPork1984ToGiveaway = giveawayPork1984StartingIndex;
        nextSpecialPork1984    = specialPork1984StartingIndex;
        initSvinBalances();
    }

    function claimPork1984() public {
        uint16 porksToMint = howManyFreePorks();

        require(porksToMint > 0, "You cannot claim pork1984 tokens");
        require(leftForSale() >= porksToMint, "Not enough porks left on sale");
        _mintPork1984(msg.sender, nextPork1984ForSale, porksToMint);
        cannotClaimAnymore(msg.sender);

        nextPork1984ForSale += porksToMint;
    }

    function buyPork1984(uint16 porksToBuy)
        public
        payable
        whenNotPaused
        {
            require(porksToBuy > 0, "Cannot buy 0 porks");
            require(leftForSale() >= porksToBuy, "Not enough porks left on sale");
            require(porksToBuy <= maxPork1984ToBuyAtOnce, "Cannot buy that many porks at once");
            require(msg.value >= singlePork1984Price * porksToBuy, "Insufficient funds sent.");
            _mintPork1984(msg.sender, nextPork1984ForSale, porksToBuy);

            nextPork1984ForSale += porksToBuy;
        }

    function leftForSale() public view returns(uint256) {
        return maxPork1984 - nextPork1984ForSale;
    }

    function leftForGiveaway() public view returns(uint) {
        return sellablePork1984StartingIndex - nextPork1984ToGiveaway;
    }

    function leftSpecial() public view returns(uint) {
        return giveawayPork1984StartingIndex - nextSpecialPork1984;
    }

    function giveawayPork1984(address to) public onlyOwner {
        require(leftForGiveaway() >= 1);
        _mintPork1984(to, nextPork1984ToGiveaway++, 1);
    }

    function mintSpecialPork1984(address to) public onlyOwner {
        require(leftSpecial() >= 1);
        _mintPork1984(to, nextSpecialPork1984++, 1);
    }

    function startSale() public onlyOwner whenPaused {
        _unpause();
    }

    function pauseSale() public onlyOwner whenNotPaused {
        _pause();
    }
}

contract Pork1984 is Pork1984Selling {
    string _provenanceHash;
    string baseURI_;
    address proxyRegistryAddress;

    constructor(address _proxyRegistryAddress) ERC721("Pork1984", "PORK1984") {
        proxyRegistryAddress = _proxyRegistryAddress;
        _pause();
        setBaseURI("https://api.pork1984.io/api/svin/");
    }

    function contractURI() public pure returns (string memory) {
        return "https://api.pork1984.io/contract/opensea-pork1984";
    }

    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner
    {
        _provenanceHash = provenanceHash;
    }

    function setBaseURI(string memory baseURI) public onlyOwner
    {
        baseURI_ = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI_;
    }

    function isApprovedOrOwner(address target, uint256 tokenId) public view returns (bool) {
        return _isApprovedOrOwner(target, tokenId);
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function tokensInWallet(address wallet) public view returns (uint256[] memory) {
        uint256[] memory tokens = new uint256[](balanceOf(wallet));

        for (uint i = 0; i < tokens.length; i++) {
            tokens[i] = tokenOfOwnerByIndex(wallet, i);
        }

        return tokens;
    }

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Pork1984: caller is not owner nor approved");
        _burn(tokenId);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract ContextMixin {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Initializable} from "./Initializable.sol";

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string constant public ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contracts that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(
        string memory name
    )
        internal
        initializer
    {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {SafeMath} from  "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import {EIP712Base} from "./EIP712Base.sol";

contract NativeMetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress].add(1);

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

