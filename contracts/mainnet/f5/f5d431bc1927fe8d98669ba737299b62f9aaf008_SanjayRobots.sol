// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/[email protected]/token/ERC721/ERC721.sol";
import "@openzeppelin/[email protected]/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";
import "@openzeppelin/[email protected]/utils/Counters.sol";
import "@openzeppelin/[email protected]/security/ReentrancyGuard.sol";

contract SanjayRobots is ERC721, ERC721Enumerable, ReentrancyGuard, Ownable {
    
    uint constant public tokenPrice = 0.069 ether;
    uint constant public whitelistPrice = 0.03 ether;
    uint constant public maxRobotsPerPurchase = 8;
    mapping (address => uint256) public whitelist;
    mapping (address => uint256) public cooldown;
    string private tokenBaseURI = "https://sanjayrobots.s3.amazonaws.com/metadata"; // this should host the masked metadata/images
    uint256 saleStart = 1632510000; // Fri Sep 24 2021 19:00:00 GMT+0000
    uint256 maximumRobotID = 10000;
    bool private paused = false;
    
    uint256 public seed = 0;
    
    using Counters for Counters.Counter;

    Counters.Counter private whitelistCounter;
    Counters.Counter private teamCounter;
    Counters.Counter private publicCounter;

    constructor() ERC721("SANJAY ROBOTS", "SJR") {
        whitelist[0x1D7B087234D89510bE132F8835C04d696Be4F43a] = 1;
        whitelist[0xBcE3BD3b206946AbBe094903Ae2B4244B52fb4e9] = 1;
        whitelist[0x8830779e6e3618D8f2bd5f15C15aC8A255cB98a6] = 1;
        whitelist[0xe59f57c91bB2684796167eCa78dC6AeeEFa49cD8] = 1;
        whitelist[0xD387A6E4e84a6C86bd90C158C6028A58CC8Ac459] = 1;
        whitelist[0xeF1E28064D31AaFF4DaFB34cfBCc7CbeE3397294] = 1;
        whitelist[0x4884EB76842F734e0DE54D79ad45266072Eb68E2] = 1;
        whitelist[0x6d26E9c2f9DE0dCdeAdDAeBEc25FD1338678AcE0] = 1;
        whitelist[0x197D9f1370f2f7441a17cb035f33A6C19866D67E] = 1;
        whitelist[0xcfc65EBDCD6b90b9036913971f963e8D9d83f37b] = 1;
        whitelist[0x09343DF739FcbcAF4ffd9776b56d2C673370162D] = 1;
        whitelist[0x73626e046fad657ba6c0a8830032f845549f040D] = 1;
        whitelist[0xC362923B7662218A972f84acEa000EdE3AF1aAde] = 1;
        whitelist[0x089aD55045fe72f1f77eAAC7e166de9e277600A5] = 1;
        whitelist[0x8F4839df0D4EAbAE1246cd036030140E5b0673c2] = 1;
        whitelist[0xD1F93089d9004004F8E30c54de5a584902962CE8] = 1;
        whitelist[0x339858A776bb65f4f4F12D5aB8aA40EB3447cB2e] = 1;
        whitelist[0x23E192E74FD531399458602605D3E2029C3BFB4f] = 1;
        whitelist[0x812B4e6E9F2899c4805Ac1a1ECD8f72E2E96bAAB] = 1;
        whitelist[0x671149e0af44fBCaEC953717554203630cB8e515] = 1;
        whitelist[0x3ec73fC792Ca878F17d48E8e16A822284AAb2F41] = 1;
        whitelist[0x7401572D8B4E07F89579D804e267ac000C8C67cC] = 1;
        whitelist[0xd13b083E3Aa86dD18083C9F00fA2e14a4c83a5c0] = 1;
        whitelist[0x65b23bb3BEAeCE1FE892D0Dba2E8593ba3377BFc] = 1;
        whitelist[0xbd16b6cf36301Bb279798aA39Bd0E19C5faa7BB6] = 1;
        whitelist[0xf59A0B7e736335241e5362133557309A9ab8986c] = 1;
        whitelist[0x33745a155A045d5E6B118EA93c80ab6295927Ea3] = 1;
        whitelist[0x14509Bb104Ee513817657A63e87528208f85A4Ce] = 1;
        whitelist[0xD6e28F71f349eDa12f6c56136eA2776626D5295d] = 1;
        whitelist[0xbF59E40112157017B69bE5734F8c702dCbd73336] = 1;
        whitelist[0x2C6A2bd4212CD6de651AA968f2296cb771bE7a55] = 1;
        whitelist[0x92c4786d828A4C42e0C0E6e7eF06b52f2E2cC38a] = 1;
        whitelist[0x31E04750dd87396eCf4AE8F976CBe4cc69224Eda] = 1;
        whitelist[0x4897D38b0974051D8Fa34364E37a5993f4A966a5] = 1;
        whitelist[0xE876B710b38C2E34513C5d2c40027b1Cda967578] = 1;
        whitelist[0xcc72F778Eedd8e337E6Cb58Ca9Ec8BA2912E71Dc] = 1;
        whitelist[0x5A4cB41663951004f44038AFC205a59D26192fA8] = 1;
        whitelist[0x77d6FeBbbC694fD12cd66a80938879De6797c314] = 1;
        whitelist[0x4AAA6AD4FFD5423868E34Bc993f3190068139149] = 1;
        whitelist[0xd75d912F74395cb89c5493D9ba5DEd5bD7919Cca] = 1;
        whitelist[0x68D537cb95aa9Aa8470b2c40ec6f827a4F547940] = 1;
        whitelist[0x036eFf96a00B461bf86CDFB6cF1FbEe08e9e3be6] = 1;
        whitelist[0x9BD91abdf39A167712B9F6c24d1c9805d5FB9242] = 1;
        whitelist[0xA56c04347AbeE42F663EFF9bC2d0147b97C8F782] = 1;
        whitelist[0x5A82411e1771Fa9e7d73BC64F39Bcdb28B321f6A] = 1;
        whitelist[0x42353a7Fc70Eab5C0017733813805313B7b10b8B] = 1;
        whitelist[0xD751Ff5Fb8D0cd79653c2d7d97d7F9b3E7e52978] = 1;
        whitelist[0x5668FabD29c89bd16DC78e150eB8A3AE32155DC3] = 1;
        whitelist[0x8e65890d4129EEF69e44087AeBDB69ddF38D1FBe] = 1;
        whitelist[0xeDA089739e7110819e680896a1edF752f2532fB0] = 1;
        whitelist[0x733f9d10432D8dbd6e339d7257ca113217218C5a] = 1;
        whitelist[0x72E5d8D85Db805C275561D9FCE16C11002c676FE] = 1;
        whitelist[0x81B6fdBa13085A4FBF15a0880931a384810FA8E0] = 1;
        whitelist[0x02C2e025b219976C85B70A2E0Cf110c97930E8C9] = 1;
        whitelist[0x7362c41F92Aa7dF9E6F963925DFf0f1417e80B94] = 1;
        whitelist[0x5BA8C82F74C61Ec40c3C80B12800c2ed3773A33B] = 1;
        whitelist[0xb5C3b594B26736123B9EE9E7D11832c3AC23cBf3] = 1;
        whitelist[0xC9F01986d767550708095E25fDaCF5f3AFD85121] = 1;
        whitelist[0x43b6708BDBDB34854874aA8e5900Ea3AA7BE16CF] = 1;
        whitelist[0x027041f1F636416709A551fDAcab232f38C120A5] = 1;
        whitelist[0x6Edb53EdfD126227A02903deb0F049032cfDdAA3] = 1;
        whitelist[0x4B1048A15C77A74402FdfFC1ec95E6211e3d6011] = 1;
        whitelist[0xcA5630a71f1610CdD8dFf76A19eE01A974aFd132] = 1;
        whitelist[0x0C66CA6aeD218806DF07FFF9d126D0485F94CB5f] = 1;
        whitelist[0x6f9cFAccA63145c906fAE462433Aa1d1F147eec9] = 1;
        whitelist[0xD7905bf00457D0AdB34b593205E08b60E72f0d39] = 1;
        whitelist[0xeB85C590E635aFD16d38fD8dd3B5C04D65df89fD] = 1;
        whitelist[0xD3D395877D7F5015cF98ba9A8645F13170863041] = 1;
        whitelist[0xc540557cC97aeCdC1aaB97D666Dc1AE5A9e426FB] = 1;
        whitelist[0x1047Bac3ce83f43142C39b2C33F7c7f062EB028d] = 1;
        whitelist[0x633f7F847090Ff1561FACd839194A47773df2446] = 1;
        whitelist[0xdc8D255E709EdF2ed2622B2691E8ED9a71abB59E] = 1;
        whitelist[0x9AbD6Ba67133c43827695D1Bf321666F1b1007cB] = 1;
        whitelist[0x16DC448E3a12B8fCA534D3fD39c340B6D1aDA5DF] = 1;
        whitelist[0x545a2eD169EaC188638763539D30951488a9c8F7] = 1;
        whitelist[0xAb05Fe7F1DeE4CDB5640d79fe847EF80204451f1] = 1;
        whitelist[0xA1f86b20c960154569Db4c52d8323477168A1E2e] = 1;
        whitelist[0x3b682c360204B4Bf6874C12cA44BF734f59CA9bd] = 1;
        whitelist[0xD00e3091708D80968aC45Bf0e3269ae37F69191D] = 1;
        whitelist[0xB2861cD1eCBc01b4Cf239491F8b951CA652B53C0] = 1;
        whitelist[0x4c292Eb48586482E566Ba2597808c47801E38A41] = 1;
        whitelist[0x6D04a93D4ac0610e65e4432DE9c0E4E85cC6d15b] = 1;
        whitelist[0x24192c81D1a8bC30e037E67EAaDDB59D199713a4] = 1;
        whitelist[0x086731aBE47E9145671deDFdE38e8dD2430d945E] = 1;
        whitelist[0x212EF51aa05A87488398326a386c4203B2eAF81F] = 1;
        whitelist[0x5Fea9DAcdE1fb43E87b8a9259Aebc937D995F51b] = 1;
        whitelist[0x68f95890aA877dd361c336E84A53E249C5Bc9D9a] = 1;
        whitelist[0xFE9c9591D0f1Ea7464bA503bEd40E06f5B62D1A1] = 1;
        whitelist[0x10992b1FF613308C9ce08A69c8716B0Ca75De081] = 1;
        whitelist[0xdC8bBaCAc5142A91637c4ebbDF33946bFB48BC50] = 1;
        whitelist[0x69C38C760634C23F3a3D9bE441ecCbD2e50e5F73] = 1;
        whitelist[0x5944DE446D171Ca13318cEdAaE115A056A3f398F] = 1;
        whitelist[0xd0370f7fe1239914Da55b5A3a7198Ec6B70fE2aE] = 1;
        whitelist[0xC3000C282D05d70a00f25D2c859C01E9728ff185] = 1;
        whitelist[0x91623b85675608dEcE212EE1E650cCbc9332F93a] = 1;
        whitelist[0x1fD4D93a7a5fF29Aa366C6d4EFAaaFf3b09a195B] = 1;
        whitelist[0xe0057A40A3F1F9F2A8618baa9bDCAf85979E6527] = 1;
        whitelist[0x606C3Af5cc0bF4afc6AFD1010E8Fb424593Eb9fB] = 1;
        whitelist[0x1E31c5C71e00C933cD83f944e85DE97564D0ffc7] = 1;
        whitelist[0x85d365405dFCfEeCDBD88A7c63476Ff976943C89] = 1;
        whitelist[0x765E406Eb1Bb0909F4Eae2fe5B52c21C9E61b498] = 1;
        whitelist[0x8f662d520eae1BeDC8d0303650956228F4748CFa] = 1;
        whitelist[0x7e00f4110Fb7D02A91632895FB93cd09af3209c6] = 1;
        whitelist[0xa9F71b18e97A88350037DF0A25A5de76c03101Ca] = 1;
        whitelist[0x08aA28b1c297E2A33d5A630B3a09be6440ff4823] = 1;
        whitelist[0x6dB5896bB044Ad064E70452f673910853727A4B2] = 1;
        whitelist[0xd630e991e407229174AA4F0E057800d80d4B80EC] = 1;
        whitelist[0xbCb5DC467D09d518a0EBa0bd968A3ecfB37768C8] = 1;
        whitelist[0x29cad6f1B5126D446e25c5406A2e8c1dee456D27] = 1;
        whitelist[0x178CbbF92637183Fb8Da503DD541813E4609294f] = 1;
        whitelist[0x447742Db52CBD9587118776B62DC3704E90a9834] = 1;
        whitelist[0xFC5B6E1E4E9b916BB8F8Ec1eE106e290A2Bcc5f1] = 1;
        whitelist[0x5E0c9043942734F432de41fAe563b9691bFCcb40] = 1;
        whitelist[0x7ca83Da48606CBFBbf12AF0294dFB7433C0393Ea] = 1;
        whitelist[0x264BF51639f5753F05D65e4637Ad22078F1652ca] = 1;
        whitelist[0x15DfF416ED3529436c7dfDb14Ae3Ee7dfD5d79A4] = 1;
        whitelist[0xaF4420a171b6aAe1c199fcAF2B561943927B30CA] = 1;
        whitelist[0x1F8eD3a89038a68F0DFB7196C6d32E493F2921Ac] = 1;
        whitelist[0x2947025a00F8CfA01a5Fb824bd1E98e129F178Cb] = 1;
        whitelist[0x023Cd4062b82Db1EEcC91Fe077Ec944d4b89384a] = 1;
        whitelist[0xCac8F01E56B49f1D44cc9a2BaDfE381D425606Ed] = 1;
        whitelist[0xC2BC30b75ACf15B2dE5D988e38c606b6208e63c4] = 1;
        whitelist[0xDC0B3127A71367227311f02Fe4Dda2A6cCDbAe78] = 1;
        whitelist[0x63330b3092a2fA6F328cB9776aFDd75D75ce406F] = 1;
        whitelist[0xbF1dAc60194bC2f3A83314Bc18DE1060a860D0da] = 1;
        whitelist[0xce1599327C6cB91C98f876CCc4666869E4862357] = 1;
        whitelist[0x9B11FfE23B74891BDc691C2d8b24068E32209320] = 1;
        whitelist[0x031Dc24943A42E1205417D1130B616ACcF667Bae] = 1;
        whitelist[0x3d8a657b63F85028dC02faDe8A9373Cf6AD73455] = 1;
        whitelist[0x1c0a70f3359FaA0476Fb33b8B2a808D10a559a44] = 1;
        whitelist[0xfe7d20712D3EcEB6884cee123d9dE9914a4AFf6a] = 1;
        whitelist[0xB22Ce37B9dF86FF4fEC4EA02EfB954FF24ACf179] = 1;
        whitelist[0xA85FDD41964F025e5309b44Ae04C55fE0C979f08] = 1;
        whitelist[0xa86B1ab5bc759FB0B7fc8611e1705688b747f487] = 1;
        whitelist[0xbbDb3AccFe65Fdd507354F37dd841d01576cFFAc] = 1;
        whitelist[0xD88d4F99ADC42A57e5949c94fDd984f43811f344] = 1;
        whitelist[0x125442956d5e34ee274253A0F32354b945aCf656] = 1;
        whitelist[0x155ddeB229939088809FeB653f37221Ea62BD9F3] = 1;
        whitelist[0x29533A8768100a03619c9E6a4697eD33ECd896F5] = 1;
        whitelist[0xfCFDA495A95FAb12957eEF60Cea88d33612520a1] = 1;
        whitelist[0x09B0B849C8c01781A3ff2C5a7DC045De7A136b5A] = 1;
        whitelist[0xb767855ada3f3268AFf07dE5840188120bA60Cd4] = 1;
        whitelist[0xD54f0ebdB4c5b668423130A0c487aF5393fe8eD4] = 1;
        whitelist[0xA41DCEe235F7F8Ab2C7d8a3e36fdC63704c142ae] = 1;
        whitelist[0x20C3EDc13C70310B97f60419DBC68BD58219B59F] = 1;
        whitelist[0xC27f2F8Adf67f8bce6b3a1dB5192fF3Ac845cAc0] = 1;
        whitelist[0xCa5A3c8DD61B02049B522C354871aF7311F67664] = 1;
        whitelist[0x9B275B982973754E1f46324D3d4c58E93805DB1F] = 1;
        whitelist[0xa49dcfD59f39DfadA7EB11f60f173187B5401a06] = 1;
        whitelist[0x0677D963f8950D456b375333C8832877De8c23d3] = 1;
        whitelist[0x60401db7a4FA99CB03879Cb201D4b2bBf64D6885] = 1;
        whitelist[0x05CcF21A74324542F5c68bC8F216E173382C0254] = 1;
        whitelist[0x4c88c30CDF53929Aee3fFce4e8f1cA2D113Fa596] = 1;
        whitelist[0x07173BB420de135AA05ff97e4750D1456865FFD0] = 1;
        whitelist[0x8aF9cCfD1B203186AE754b4FcB0c237F534Aa9e5] = 1;
        whitelist[0xf59e9B46B1474bcbeAD53789455daCB70B49A6cD] = 1;
        whitelist[0x0B012BbeaB64B0D52580879a85717B3fFcEC6C42] = 1;
        whitelist[0x64E7ea3c9612d9aBa9F6E1Ae63Aa27678dfFe6C9] = 1;
        whitelist[0x46Cb71838b2873E674cAC36daAe435125E18088B] = 1;
        whitelist[0x2EFfD878BD5869206d91588AF4DE68C112f4312E] = 1;
        whitelist[0x1e1c35f021f355A7D2e41a869e97e0321048Fe24] = 1;
        whitelist[0x1e1c35f021f355A7D2e41a869e97e0321048Fe24] = 1;
        whitelist[0x3D3316DFFd53ac2724fb05a066E23E5e56AbbF45] = 1;
        whitelist[0x3b7393118f0d8f99f269854CF441A5ebCb0Af246] = 1;
        whitelist[0xF187af150C87aB964709428F673E6C2A055Ce226] = 1;
        whitelist[0x729330EF0fE13e294e268a030F934819e95520dc] = 2;
        whitelist[0xEeeA2221483075a941E1502FAa818E7Ec76d63ae] = 2;
        whitelist[0x29305910D110E24776053BA1376fb85A2Ae2Bf05] = 2;
        whitelist[0xA60d3C68cE85B74c67C48216e760C1e03AC93030] = 2;
        whitelist[0x96236aDB640eC620A85898378375cEDf03ca21ff] = 2;
        whitelist[0x03F63b96240C4a0a3E197329787adf0Fa42806Df] = 2;
        whitelist[0x90149FaA3482D0E3A191Ad7AB51Ea473B20771ae] = 2;
        whitelist[0x9D41a0f6c47e5E7e9D322187986D4558FF3c78cB] = 2;
        whitelist[0x311E16701D3536e103Aa5b6872B3e0B05d79dE42] = 2;
        whitelist[0x74C5eC520a2dB65B28053D351F1258b94b15Ca0f] = 2;
        whitelist[0xe7dAe42Dee2BB6C1ef3c65e68d3E605faBcA875d] = 2;
        whitelist[0x7203046ECE340B997119D4A74524D4180A9a4C2C] = 2;
        whitelist[0x63cE10e873f0d5529C38e86ccb57d52117eD8A84] = 2;
        whitelist[0xF0812A075d631C8AC57274Eb2E9C9876f5d0c731] = 2;
        whitelist[0xee5280e9eb7B9d33cA03332Db7382b24F4A2D009] = 2;
        whitelist[0xCE266203cc90f26B346a9f359fEA7Ced2f4E62dD] = 2;
        whitelist[0x93624D811e9b1F5809f6b5a829E160188193CA0B] = 2;
        whitelist[0x0E7F1155cfd8cC186EC599964c7894442Afbf9b9] = 2;
        whitelist[0x87816ddFD2f9865CA3025E46022e17F4EBd2E0B1] = 2;
        whitelist[0x6e1741220945335479Ec361806753dFC83f51B27] = 2;
        whitelist[0x815c04e80E122De55D2B537DA90d8811577e3979] = 2;
        whitelist[0x518354c86A487041237084a1293Ca48D2d581Cd4] = 2;
        whitelist[0xe5Be9b04600BCE54302ff35989c30b0FAD2960f7] = 2;
        whitelist[0xbf1B8f400062C1F240b578BcBCec40a1AeE20C8c] = 2;
        whitelist[0x3458fd8F327f270B32092Cd406Ed8ba97405d9F5] = 2;
        whitelist[0x78aD7E703CA1bCD20ee47Fb64Ad5634720B51069] = 2;
        whitelist[0xF16323dB45ffDA53ADC9EEB30632009041069699] = 2;
        whitelist[0xa3918B53E51fbf173AeBB609eA2aD7C783D93CD4] = 2;
        whitelist[0x79cF2507732dF36C6514dcdC1cfB20ae83cF5B5D] = 2;
        whitelist[0x98f205e5e89b5A4fbe1a68Ee315A6c6089c93AFe] = 2;
        whitelist[0xe0f4232caEd7eC605CAD6092Bf1C495e95E1B079] = 2;
        whitelist[0xFA0611eFe7A1f4Ce14983AeA59EDCcECa73E2e7a] = 2;
        whitelist[0xB3ab08E50adaF5d17B4ED045E660a5094a83bc01] = 2;
        whitelist[0x7e0c90B243a2b091e96C14142dB287382dEaf2Eb] = 2;
        whitelist[0xCBb3ea95c95fe8962465040ED8595aB16E7EDF10] = 2;
        whitelist[0xcCB7B4a28D89CDaA8E25B8601abb379a4FC466c2] = 2;
        whitelist[0xa3299CCa7Dc226f978a96Dbb724a72ea1E6d7Cc8] = 2;
        whitelist[0xbe017be2D41f3965Aab034d71316F7662F50E9fB] = 2;
        whitelist[0x964fd5383DFdbFbd54224dE9F773E5aC7bDb0086] = 2;
        whitelist[0x9C996076A85B46061D9a70ff81F013853A86b619] = 2;
        whitelist[0x0A34299a0AA18dfdD4eeC5d20BDCE5B2a44f40dd] = 2;
        whitelist[0x34b2DBf0979B063f75DCC100D53607a72C595c00] = 2;
        whitelist[0xca4C7708DC417293a97Aa4f80E1a3e7084660EcE] = 2;
        whitelist[0x291E84FcC2aC41B07dadF80722130d524e25443E] = 2;
        whitelist[0x9CD1910b3aa2D2a42d861F772D6821d4378e513e] = 2;
        whitelist[0xDa4DFEFE25cf0123bBcB871573b83856A6977243] = 2;
        whitelist[0x3862903859eA9b1cE6804823bD9ca7a249afEBb3] = 3;
        whitelist[0x48c06dFB7a2245c288494f08FCC5b1D5A0312c62] = 3;
        whitelist[0x58E3C0d1678855d2C10bF82Be3D705ce3553601a] = 3;
        whitelist[0xA078EFb1e49bd30Fc720fB8f6aadc2228B15A53d] = 3;
        whitelist[0x5758a11032560d5A0dEF867c966E0D58766b410E] = 3;
        whitelist[0x3546BD99767246C358ff1497f1580C8365b25AC8] = 3;
        whitelist[0xab4787b17BfB2004C4B074Ea64871dfA238bd50c] = 3;
        whitelist[0xCcd342C5a02805ee661318BE1f2D062A68dc68A1] = 3;
        whitelist[0x58ce1E07f8F05BE96a5cc85fE3a82EA698A14a02] = 3;
        whitelist[0x97cDD6B65cC7ed9Ce076312284FF1be5ae1E09A5] = 3;
        whitelist[0x8043fA7F192dDAD1101757A9d155B4D7bE2dE159] = 3;
        whitelist[0x98e8a88dC25eFC7897acb329548380b9dA4C2270] = 3;
        whitelist[0xA47dA12d2db569fa1Dbb9B32970087dCE5Ae4ab3] = 3;
        whitelist[0xeD79D3FBd1E05Cc5eDc76C8eAeC89851882e5a35] = 3;
        whitelist[0x8BE73D367c6FE787c0484259057eA9d3E3AE66C9] = 3;
        whitelist[0x5f312DF04b19979EF4Bd5876737cfa481A928C0D] = 4;
        whitelist[0x8736eDFf3e5E722F4D2E77ed5376d34a867dF88C] = 4;
        whitelist[0xBD275ED21e220cC35fAF087385E09Db6AC11d242] = 4;
        whitelist[0x4E20746Dd3c16Aa3df9154Af4869d6B34234e65E] = 4;
        whitelist[0xE044BE24efA511730d9F70766d56D0FB1CE7b966] = 4;
        whitelist[0xdC190d7cEA8e8bf0b381617062200C10CFFF0A91] = 4;
        whitelist[0x6372D911ad7329509d683828be1BF5d4eb45bb42] = 4;
        whitelist[0x10c0be5F67833E7D98Bf438FC165d2D97E93f45C] = 4;
        whitelist[0x71E70A39fC2600b952036c99D858C7030cFf384C] = 4;
        whitelist[0x8EBE8Ec97e1D3098511754b9BCA45973B90436f4] = 4;
        whitelist[0x0c2887a18900480F1eC69E4E464684AF6918D4c1] = 5;
        whitelist[0x42d0E922d4EA648e2D9d41101e27c2585e6bb308] = 5;
        whitelist[0x5Ec0D096f8ef2Ac2dBd3536e3dFE2db1361BA6a7] = 5;
        whitelist[0x591F8a2deCC1c86cce0c7Bea22Fa921c2c72fb95] = 5;
        whitelist[0xB7A31346433430D92846f0181C55Fc506B9b22d8] = 5;
        whitelist[0x5eA12341d073Ec5a1226b85f0478413A19081535] = 5;
        whitelist[0x9078a0ce313C6EcF06825E50115bb5354723f2C1] = 5;
        whitelist[0x6fbD7D180EBeE8dc0df0cFa83E3Ab13023e22672] = 5;
        whitelist[0x28395765Cf8A8750E5a51A8A2a4907e6D35D8b3D] = 5;
        whitelist[0x750Ba3BEF0e83C9b0f5063234B8b231033Ffb5BE] = 5;
        whitelist[0x072DF329e2B6853D47964527c442668483F5c648] = 5;
        whitelist[0x330da697403eb8Bf2d59331f86F83cc513b79Bf9] = 5;
        whitelist[0xD83C7bcED50Ba86f1C1FBf29aBba278E3659F72A] = 6;
        whitelist[0x2687B8f2762D557fBC8CFBb5a73aeE71fDd5C604] = 6;
        whitelist[0x10b0615E2Dc77d51f0762C62b57Bd925d3353D12] = 6;
        whitelist[0x6A8a5C4a843f1dD1f3A769C75C7112bE2A568B79] = 6;
        whitelist[0x0Fb16Df1471A5D931F73D98DA8bDD4583a12443B] = 6;
        whitelist[0xCa65De0434Fb8987F702F6aAb690De1D229090dC] = 6;
        whitelist[0xE52EdACB729342786F650e466B98c0f81248E1f9] = 6;
        whitelist[0x64eB6a5a1e4B00Fc7640194D43e89F9D92345C40] = 6;
        whitelist[0x431573685058e5d480fE383Dc1Fd3b644913c239] = 6;
        whitelist[0x80d4495DD9C0C8fa110f5173aE352A7a56801961] = 7;
        whitelist[0x16792c97D007Ff25cdF5613EB7DB26DC5Ef54ba5] = 7;
        whitelist[0x551B807e76F4Bd7BE9B288e43e64F038D1d6D3b3] = 7;
        whitelist[0xdE09A8E048aA3f4C9399702032934Aeb26b77011] = 7;
        whitelist[0xb45158Adf2cdC4e67dd29672684E1053d90F0B78] = 7;
        whitelist[0x1541bdAE61582662C85833Bb0DfFc368316F6126] = 7;
        whitelist[0xe8A7A64554A0fC0d1352Fc7C3e17b656CAA84391] = 8;
        whitelist[0x6ef986B39fB4a18D01aF52aB826eA21E720a1e33] = 8;
        whitelist[0xA31a661FA0247e04499291C98c57ca23dC2d26DB] = 9;
        whitelist[0xa4Fd5F2d9A416AC45EfFd3B953ADad5dE9BDfc90] = 9;
        whitelist[0x40dF5eE2722B43628E7e4f4B59909627f0C018F8] = 9;
        whitelist[0xb104371D5a2680fB0d47eA9A3aA2348392454186] = 10;
        whitelist[0xE962B69739f70cE8Bf52d3ba28ec856BBfe37C44] = 10;
        whitelist[0x3EC52292aEF4039bCBf00cC10D0DCC4c05676141] = 11;
        whitelist[0xe001891949372e1AA33C50c7EA19568bE32ecDE7] = 10;
        whitelist[0xe60Ac1c5B48b3cc3225CaC1E55bA28AA47c9FcCc] = 11;
        whitelist[0x8ff9b14D82B7A4eFe95f248C6d8D7C8D6c447640] = 11;
        whitelist[0xD8DFb78a2d2fF891ae61A4cA1Ce80DD745b3A19c] = 11;
        whitelist[0x8ff9b14D82B7A4eFe95f248C6d8D7C8D6c447640] = 13;
        whitelist[0xD8DFb78a2d2fF891ae61A4cA1Ce80DD745b3A19c] = 13;
        whitelist[0x7da9F0170834dD08804b0240978915d569b7Eb21] = 14;
        whitelist[0xd7Fc4Ab828AFc1bb4b217f337f1777Ca856Efd12] = 14;
        whitelist[0x56879cc88fa3895C082C22035dB1386DcAc53bba] = 15;
        whitelist[0x368667e88e69849A8E4aD2DBbC71E7A0A8381f31] = 16;
        whitelist[0x7a277Cf6E2F3704425195caAe4148848c29Ff815] = 17;
        whitelist[0xB69e9610747520016BDE2a89E3407C5992759748] = 18;
        whitelist[0x73Ac93A7950AF4e92bE6Ed06F1c9F0fC8D166838] = 19;
        whitelist[0x73dEAEB8aA241b6fcdB992060Ae43193CcCBf638] = 19;
        whitelist[0xb6e5C9faD3bCA83c80cA3325F7B01dd5ecae9629] = 17;
        whitelist[0x98d6fe1c3dd4eD84fc1912ad5af1b75a253Ca502] = 24;
        whitelist[0xAB8114546C818A6841Df82347B2f752aD03F6f9C] = 26;
        whitelist[0x620051B8553a724b742ae6ae9cC3585d29F49848] = 33;
        whitelist[0x9C45759c699624DA8cE41Ab2B5fc2ae6B51C786e] = 50;
        whitelist[0x5Bad69D9F8b0600B3acBcC9C604d9879b9073ef7] = 89;
}
    function saleIsActive() public view returns (bool) {
        return((saleStart<=block.timestamp) && (!paused));
    }
    
    function assembleAsAPreviousOwner(uint256 robotAmount) public payable nonReentrant {
        require(saleIsActive(), "sale is not active");
        require(robotAmount <= 20, "cannot buy more than 20 robots per transaction");
        require(robotAmount >= 1, "cannot buy 0 robots");
        require(msg.value == (robotAmount*whitelistPrice), "you need to match the exact price for the amount of robots you try to buy");
        require(whitelist[msg.sender]>=robotAmount, "You cannot buy this many robots. Are you whitelisted? Try buying less robots");
        require((whitelistCounter.current()+robotAmount) <= 1000, "not enough robots left");
        
        for (uint8 i = 0; i < robotAmount; i++) {
            _mint(msg.sender, (whitelistCounter.current()+1));
            whitelistCounter.increment();
        }
        whitelist[msg.sender] -= robotAmount;
    }
    
    function adminMintWhitelisted(uint256 robotAmount, address to) public onlyOwner {
        require(robotAmount>0, "you cannot mint 0 robots");
        require((whitelistCounter.current()+robotAmount) <= 1000, "minting exeeds robot #1000");
        
        for (uint256 i = 0; i < robotAmount; i++) {
            _mint(to, (whitelistCounter.current()+1));
            whitelistCounter.increment();
        }
    }
    
    function adminMintTeam(uint256 robotAmount, address to) public onlyOwner {
        require(robotAmount>0, "you cannot mint 0 robots");
        require((teamCounter.current()+1000+robotAmount) <= 1200, "minting exeeds robot #1200");
        
        for (uint256 i = 0; i < robotAmount; i++) {
            _mint(to, (teamCounter.current()+1001));
            teamCounter.increment();
        }
    }

    function assemble(uint256 robotAmount) public payable nonReentrant {
        require(saleIsActive(), "sale is not active");
        require(robotAmount <= maxRobotsPerPurchase, "cannot buy more than maxRobotsPerPurchase");
        require(robotAmount >= 1, "cannot buy 0 robots");
        require(msg.value == (robotAmount*tokenPrice), "you need to match the exact price for the amount of robots you try to buy");
        require((publicCounter.current()+1200+robotAmount) <= maximumRobotID, "not enough robots left");
        
        if (block.timestamp < (saleStart+(24 hours))) {
            require(cooldown[msg.sender] < block.timestamp, "cooldown: try on the next block");
        }
        
        for (uint256 i = 0; i < robotAmount; i++) {
            _safeMint(msg.sender, publicCounter.current()+1201);
            publicCounter.increment();
        }
        
        cooldown[msg.sender] = block.number;
    }
    
    function withdraw() public onlyOwner {
        (bool success, ) = msg.sender.call{ value: address(this).balance }("");
        require(success, "Transfer failed.");
    }
    
    function revealTokens(string calldata newURI, uint256 newSeed) public onlyOwner {
        require(seed == 0, "robots already revealed");
        require(newSeed != 0, "seed of 0 is not a valid seed");
        tokenBaseURI = newURI;
        seed = newSeed;
    }
    
    function setWhitelistAmount(address previousOwner, uint256 amount) public onlyOwner {
        whitelist[previousOwner] = amount;
    }
    
    function togglePaused() public onlyOwner {
        paused = !paused;
    }
    
    function features(uint256 robotId) view public returns (bytes32) {
        require(seed != 0, "featured are not revealed yet");
        return(keccak256(abi.encodePacked(seed, robotId)));
    }

    function _baseURI() internal view override returns (string memory) {
        return tokenBaseURI;
    }
    
    fallback () external payable {
        require(false, "you need to call the assemble function if you want to buy a robot");
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
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
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
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
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
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

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
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
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
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
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
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
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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

