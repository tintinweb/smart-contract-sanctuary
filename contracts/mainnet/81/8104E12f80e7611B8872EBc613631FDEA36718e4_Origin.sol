// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract Origin is ERC1155, Ownable {
    uint public totalAvailable;
    bool public isRedemptionPaused;
    mapping(address => uint8) reserve;

    constructor() ERC1155("https://arweave.net/tFxcS71qir6yj1cUmY9_l5oA_xkLwzrqKfooOFEdekM") {
        totalAvailable = 500;
        
        reserve[address(0x60Fd35191FFa774e40934eFb8ed34b2Ec42da320)] = 100;
        reserve[address(0x5b20783f4bAaBd33BB53DD77C9B0459f5701E36A)] = 17;
        reserve[address(0x69Bd682c5fFFa4FfF2b6D64427aeD1AE234f69e2)] = 10;
        reserve[address(0xBC719AAC21aBF284A1f1A901EFc17C0cb1947782)] = 10;
        reserve[address(0x510437a6aa1400b97b32d0801872963D183F7A07)] = 10;
        reserve[address(0xEf3867Cb3D3baf773eC288CA93618bbC521df579)] = 10;
        reserve[address(0xE495C36e756Ba677D5Ae8fb868f8c8A41cc51611)] = 7;
        reserve[address(0x20335C504A4f0D8Db934e9f77a67b55E6AE8e1e1)] = 7;
        reserve[address(0xc54fcBC43f36124266ccc07965D4352Cf6da19E9)] = 6;
        reserve[address(0x8c8f1Be5DbDFA432BBFb33D6A13779E889D8Ccf9)] = 6;
        reserve[address(0xaa5146397cfFAc091eb64b21b7950F332eCcfD00)] = 6;
        reserve[address(0x79cF2507732dF36C6514dcdC1cfB20ae83cF5B5D)] = 5;
        reserve[address(0x3d6a89C8751a45DD577a4C1F3b34E71C58236193)] = 5;
        reserve[address(0xc05C4f2bf8c629d6F9F674e6949B6fe54832764E)] = 5;
        reserve[address(0xE0AF6F8F3090687918212037508fFecBB924377F)] = 5;
        reserve[address(0xA7B9744287F8d48e56adaefA21eA680E5c13A4D4)] = 5;
        reserve[address(0xC8Ed3c2d1509FCf3A3C97c68De3DBa66381d337C)] = 5;
        reserve[address(0xFE274ff2846a414e690606c2ed2CCC4Ad6bB9C53)] = 5;
        reserve[address(0xa4f0670468DFb825E6c2B5571e2c97D0844190a3)] = 5;
        reserve[address(0xBe5D6B71915A2b86D007f51432F5A79116196236)] = 5;
        reserve[address(0xD88d4F99ADC42A57e5949c94fDd984f43811f344)] = 4;
        reserve[address(0x8FF03F9A8Bed1Bf351310d72c0364c2da024f149)] = 3;
        reserve[address(0xD77D92f3C97B5ce6430560bd1Ab298E82ed4E058)] = 3;
        reserve[address(0x5E5BA665bfaacc1E0eEaD7057CE8251298a60439)] = 3;
        reserve[address(0x0C93929360FF8b46a46c2dE1C8eDeA9541B78eB3)] = 3;
        reserve[address(0x3dD85Df5A47b2b4b043a0F82555bc9A3DBF7EB5A)] = 2;
        reserve[address(0xDC0B3127A71367227311f02Fe4Dda2A6cCDbAe78)] = 2;
        reserve[address(0xef8e27BAD0F2eEE4e691e5B1eaAb3c019e369557)] = 2;
        reserve[address(0x802dEbc52e025461a592069f05a3df386Ee67187)] = 2;
        reserve[address(0x5BfDF0CFC4Ade055f4aA63c31D3B2558E3a5fd80)] = 2;
        reserve[address(0x53722a32FDdda871f35ef628B252d349744d4b71)] = 2;
        reserve[address(0xC2e7C3a5675EE1308D56f5E4fD614007e0fcc63b)] = 2;
        reserve[address(0xB577AAe0C6D9D788d5678a594A0274c2B8942A48)] = 2;
        reserve[address(0xd0f716638fD372a5Ee3656B512EDA6691907c3c4)] = 2;
        reserve[address(0x193a43a5157382dC877b78195B9AbbDCcA254302)] = 2;
        reserve[address(0x557c60995797fa7b47Be105227A2e46148D85750)] = 2;
        reserve[address(0xE6c9d15dB8957Bee5ab618b64a33731f2E35Ea23)] = 2;
        reserve[address(0x9127c9221b22EA3789c90383284C72dCd7d9B9FB)] = 2;
        reserve[address(0x63C696931d3d3Fd7cd83472Febd193488266660d)] = 2;
        reserve[address(0xDDF14Fa3e1BF3881cD6Ec491F0ccF3D1389A78d4)] = 2;
        reserve[address(0xe6b4EafD769F2D29eC4BD2F197E393dDB7d75B84)] = 2;
        reserve[address(0x97594A1C1Def0D71Cb0D7BAE3aF27a1C3C971282)] = 2;
        reserve[address(0xB066a5b94C4D1C7C06610d1628375E5E4b265DE5)] = 1;
        reserve[address(0x3b05429741445D71a45acCb35137CD0Ae18686d0)] = 1;
        reserve[address(0xa4Fb10666494D1d99eA305065a623401B48aceB8)] = 1;
        reserve[address(0x37fd216B2e06E5808437C8D22Aac3aE82FD4b724)] = 1;
        reserve[address(0xbb0fA986710DbFADF64d8E3C16B93DB06b351136)] = 1;
        reserve[address(0x2422d8f3C3b84Ff83475a85B17D1d860D8bBA7f3)] = 1;
        reserve[address(0x2d36FcB71196BEFF330a07197A78D87Bd1447b58)] = 1;
        reserve[address(0xfF0f2dECD8b5Ef4a467510C353D1B56BfBFBf3c5)] = 1;
        reserve[address(0xe15090DAB6C013da9A24FD7c9028460016DD53d8)] = 1;
        reserve[address(0xaf469C4a0914938e6149CF621c54FB4b1EC0c202)] = 1;
        reserve[address(0x5A3fC01752C6f620Ec7bC47803EbE53A5abc3473)] = 1;
        reserve[address(0x929fAAFACB9f11cfdF6294b44E08099F118dfA6f)] = 1;
        reserve[address(0xe5d009bbcE5a5D7ab9c6c2B1b0A56F9B98297Cff)] = 1;
        reserve[address(0xDB86848C3e7FA88DD274AD28b826A8ba963Af24C)] = 1;
        reserve[address(0x2eea4706F85b9A2D5DD9e9ff007F27C07443EAB1)] = 1;
        reserve[address(0x514FC379b4aE674F74dAC2A266AFF608a9b6507F)] = 1;
        reserve[address(0x376FFEff9820826a564A1BA05A464b9923862418)] = 1;
        reserve[address(0xA6E59b844891e619801B298F4f0af52054513a3C)] = 1;
        reserve[address(0x028134db627930C9a355261c83b86e2b40152304)] = 1;
        reserve[address(0x1b640c003d3F8Bba7aD69C9121cCbC94203Eb3c4)] = 1;
        reserve[address(0xFf1697Cd18f03242eA521a80334A9060f0C25c7A)] = 1;
        reserve[address(0xD48F8dF9E87C7E409072a53c6CC895350BE5567F)] = 1;
        reserve[address(0x80771c740F659760C9423F82110c03087c21Cbe8)] = 1;
        reserve[address(0x9B059f4D2199e73Aa86f8938167A1A6067474CF4)] = 1;
        reserve[address(0x5FD2C02689d138547B7b1b9E7d9A309d5A03edCd)] = 1;
        reserve[address(0x8719CC70152c03B0282216f4B97051467b2654Ec)] = 1;
        reserve[address(0x5e65605476b9Deabebd83A9566716318F75BF788)] = 1;
        reserve[address(0x4032aB8d5ccEd1444240c7b973F36d712981FB00)] = 1;
        reserve[address(0x141cA54Db6F8277917e0554b30F2B3270F65EB67)] = 1;
        reserve[address(0xa32173EBB0791338Fa7d302c7257B2BAF1cFf5EA)] = 1;
        reserve[address(0xd19956CfEa7c274d9E92d0e8ED54b962F03123E3)] = 1;
        reserve[address(0x5308685f6bbb6b56464E7c3b028ecc94ba6f830A)] = 1;
        reserve[address(0xc168A501DBbb91630a59FE30bDD40259DC2ef62a)] = 1;
        reserve[address(0x9De6405C0C7512ee94BCB79B860668a52aa7FAd2)] = 1;
        reserve[address(0x4bFBFaD0c46BF22e5b053963007605CB0618de55)] = 1;
        reserve[address(0x95fdD3157edae1f77E5E65Cd269018353938A585)] = 1;
        reserve[address(0x64af8c708A76d01c7CD64e332d5BE5f669D10189)] = 1;
        reserve[address(0x5E59E30C70B9c68e78FEBaA510b4411Bb67D64Ca)] = 1;
        reserve[address(0x842Ea67EF65D5Ee09f94F38860bef65949411B26)] = 1;
        reserve[address(0xF4568b53430B20b9C413d3f4eAbF0e67822ec37E)] = 1;
        reserve[address(0xdA28431f8c060E2a971209e29d0Ad1dFcC921746)] = 1;
        reserve[address(0x0C1b65A058ecF59CE5F63133712F4632a6E41e56)] = 1;
        reserve[address(0x362c73a2A17b6e1D94056bf050b8BB37bb0cb0e5)] = 1;
        reserve[address(0x5E231b0b9D489beEECF5B18D8d10377a9A01BE54)] = 1;
        reserve[address(0x7EA4066237fFD02759abD20e9Cf6f8768b2D835D)] = 1;
        reserve[address(0x762cd5cf73c0d8821E7b95De15D326ceC479dEcc)] = 1;
        reserve[address(0xa23b32C453e29079a826d3B8a3843a9eF9472A21)] = 1;
        reserve[address(0xd8fbD6a7F35b8af94910259D103dC261AF913B3C)] = 1;
        reserve[address(0x71915c85CFC6Fe52B00F63FD65c7b6d16a08b578)] = 1;
        reserve[address(0x023192b16a986dC4e5cB76c1ec2F4D2De4D08462)] = 1;
        reserve[address(0x9281f4d044a1C67E7647148ed5aCE6D63221315A)] = 1;
        reserve[address(0x44990d2bAEbc1917796Ac59097BC089A417582Ec)] = 1;
        reserve[address(0xA6C315021A2FB0C2f61dd7978714916304ff2007)] = 1;
        reserve[address(0xED2f402d5a4AC5b0A3fc14AC6d37F8c340410374)] = 1;
        reserve[address(0x8818D0C53d6F27CCFBEd2690C7A65fdB1D94f351)] = 1;
        reserve[address(0x27c5932eE1B0873e67279066bE914d46203fC738)] = 1;
        reserve[address(0x22115D784e9021Eadd07079d35ED0f5c87F78e02)] = 1;
        reserve[address(0x2A41282434f89f5bbF272B1091A7A0ceFD22Ccd8)] = 1;
        reserve[address(0x1c8181a1be395Ee958af164a4099d252494f3616)] = 1;
        reserve[address(0x95312CA698F23972A639c2c21e2885F390C0bb51)] = 1;
        reserve[address(0xdAd3fD6C9Fb0c2b56228e58AE191B62bFB1BEC83)] = 1;
        reserve[address(0xb85fcca7a189E0aEce9994dBEbfCd5be386e16b1)] = 1;
        reserve[address(0x75B772F2Bb4F47FBb31B14d6e034B81CB0a03730)] = 1;
        reserve[address(0x0c54abEF3D48C6c249006Bc01c88e20c4C4Cf35C)] = 1;
        reserve[address(0x777d1363CAee99E50E68789D6C5bD8F5445988b5)] = 1;
        reserve[address(0x09Bfa99BEcCBE7f815480219726Cd8e96b8a8F76)] = 1;
        reserve[address(0x728a8A6353Ee822481A83E9CC7B408cC8ac24f8e)] = 1;
        reserve[address(0x524fdea5EFe5db530E3a2b75cbF8D1C63A875BDD)] = 1;
        reserve[address(0xbFe8d5aBf248081FE03236E31EFdfdFE1562F9a2)] = 1;
        reserve[address(0x7C9285642F0ce18f7D44FD6eF89Fe94d0C298174)] = 1;
        reserve[address(0x9F1597681CC4C4dfD91ce5Fe9033aa39E7d7AD3e)] = 1;
        reserve[address(0x0e63d7E489363028E23a6da417D5767F9E399246)] = 1;
        reserve[address(0x8457513abdf710E69F0fb357d82Cacf048296f61)] = 1;
        reserve[address(0xA30eB1520cFA84F31f2021621d5Ae27857D5BBf6)] = 1;
        reserve[address(0xCba19876EE8225CC54A1b5B3DcC660b40d2dcd66)] = 1;
        reserve[address(0xbf4CC9EbfC3d71dA79Bf5245d408aDc27A9F7976)] = 1;
        reserve[address(0x884B906BE45340F967f7234AC63d854C6CC11f6f)] = 1;
        reserve[address(0xF668002aa08bD66cE407D9d45e82484f56823566)] = 1;
        reserve[address(0x17853cbED35F3153DC144D709e01575cb75d326b)] = 1;
        reserve[address(0xB9BEA0554B3CA76660712D6B525CBFbc101fEC1d)] = 1;
        reserve[address(0x96b160553Ee1f29CC982087e5d91CB94a519339A)] = 1;
        reserve[address(0xE760D893b1b9C007372EcDC931Aad10D08cf5aEb)] = 1;
        reserve[address(0x9765d4090dbf9bb5d61453795396840eCA909598)] = 1;
        reserve[address(0x0903b02Db2Adac11Df0247c1C38bF6C3ce782DB9)] = 1;
        reserve[address(0xb5556acb2EE4f6189032525F32cdaAf9ED7d3b84)] = 1;
        reserve[address(0xddEaEC88e4a183F5aCC7d7cFd6f69e300Bb6D455)] = 1;
        reserve[address(0x1B70A331CE1c01b86Ec986028191F7E41601abfd)] = 1;
        reserve[address(0xBEEA79Aa02534D1a7466cb49447B62308750C95e)] = 1;
        reserve[address(0x1CFda1C3e1864bAA7eAB936ad68BdFe1966c3c51)] = 1;
        reserve[address(0x39eBE8d2EEdA70f6a2701fF01E9EC07A29e4774a)] = 1;
        reserve[address(0xA3B5C163cbbB0C8364B62111d00A557C623470e4)] = 1;
        reserve[address(0xaea40F4a9897AEBC8775F964A6E3000BA258881C)] = 1;
        reserve[address(0xB5ED0864B96E661400980d4e72993815cEA8eCD5)] = 1;
        reserve[address(0x14dE2c6B28e0c4A06E140e7c91604FAeeEa350Af)] = 1;
        reserve[address(0x30ae0FfA2A822259D29D25327bb357D5aab9F1DA)] = 1;
        reserve[address(0xa958e6E90f570cA0293A01CdBbb6997De5848850)] = 1;
        reserve[address(0xFaEAE775e14493A8cc6c2582d588e20AFF1848e1)] = 1;
        reserve[address(0x9a116b9B8531d83c2e1Ac61BAbd4Fdf622b2dbb9)] = 1;
        reserve[address(0xd4Db6d8Ef756141DE0D838808Ddb8fFCd847D7ff)] = 1;
        reserve[address(0x4d4da657fDA69460f8083120089aE066F3655108)] = 1;
        reserve[address(0xE835e921e2b4fdfC9f18426B281ee7b9f173B31D)] = 1;
        reserve[address(0x203Bc267a4657ae5EE774Eb35cec32FAa2C0bC1f)] = 1;
        reserve[address(0xC2fA34a6FCb085F5E0295f233FAE7Fc90FBAfe85)] = 1;
        reserve[address(0x15F7320adb990020956D29Edb6ba17f3D468001e)] = 1;
        reserve[address(0xC0d5445b157bDcCCa8A3FfE6761925Cf9fc97Df7)] = 1;
        reserve[address(0x5eF89F92388E309F795081e0dd83C82011eD2546)] = 1;
        reserve[address(0x87773aACcABe6928fF0F764fe2887F41929FA855)] = 1;
        reserve[address(0xcBC49344c8802a532B8DbFDB5d9B9980D7e30702)] = 1;
        reserve[address(0xAe051E32Df2Facb1B1CaE583fD10481b6deaAc73)] = 1;
        reserve[address(0x0925D347f811d264879271D2905f54309EAcCB93)] = 1;
        reserve[address(0x2224924613e0901B9E2b2Ae5f22eBd8782AB2F1f)] = 1;
        reserve[address(0xe705F499F55f18197FbE15FaE4E315d6BA35Be5e)] = 1;
        reserve[address(0x54196238400305778bFf5Fa200Ee1896f6A9d5C2)] = 1;
        reserve[address(0xAe48F64abeaA92618b8180c0FD33CAEBfEd42f2b)] = 1;
        reserve[address(0x69661a09bAc77454Bf74C86F893817F67385f62c)] = 1;
        reserve[address(0x77a34e4Ed9DC35e1c96a5453328928be8E9E0D05)] = 1;
        reserve[address(0xdfbDB9b9174862eCB1010C39ca72409C1D63B18F)] = 1;
        reserve[address(0xa7485C99A2909a886F59b87B47DeB613860b8bFc)] = 1;
        reserve[address(0x05ce5d83371872CA8D6C4319170b452898fDA3f4)] = 1;
        reserve[address(0xd05D440A07Cd28f0B9fBa8cb698F86fE4C8f11ee)] = 1;
        reserve[address(0x11F9e23955397497d153C87878f603B422Ee61c2)] = 1;
        reserve[address(0x8870421efdA3f6611062126f3d247B6caA8D1F33)] = 1;
        reserve[address(0x851F9351F86a8969d40863046345f4FcDfA7bf9b)] = 1;
        reserve[address(0xa2140e9c5eA863Da58521737e566D27087E198c9)] = 1;
        reserve[address(0x6AfB1d981F31f765412800642c196288215Bc7fD)] = 1;
        reserve[address(0x69C38C760634C23F3a3D9bE441ecCbD2e50e5F73)] = 1;
        reserve[address(0x8F1C7dF143C66420b21c7fbbD01186b9ec821531)] = 1;
        reserve[address(0x05c83a1e632F1Fe3E00B144AeDed275c2Ee47995)] = 1;
        reserve[address(0xB4188367021173e8e352E90152566cA3bd939fBa)] = 1;
        reserve[address(0x8a5d546D0D9269770FABA8cFc2D8A84fCD93C231)] = 1;
        reserve[address(0xE1CCd64C452096538B07fC68E89196fB6309e01C)] = 1;
        reserve[address(0xCeDabD24F084df49A1ABb56783D404c943e503dB)] = 1;
        reserve[address(0x5eB5a9b88772E15672c380443CCe3A1066dA8d9e)] = 1;
        reserve[address(0x1674BF0498D726e034e893eC6da8Fa3D0db503D6)] = 1;
        reserve[address(0xdEF769bcf57dF5a2400ab5f9DD3AaD5981079689)] = 1;
        reserve[address(0xBb071066a805e1CF8552225eb62bB69CA6a950a5)] = 1;
        reserve[address(0xA72BC016Be8F075Fdf24964FD62c422101574bb4)] = 1;
        reserve[address(0x2Db3d4DF23069A937ddd42F5fb5Cab24032CA007)] = 1;
        reserve[address(0xC6dC654B5aa7969A24c7e4442a52E61FB8b24827)] = 1;
        reserve[address(0xEc2f189C25FD6E8deDD8Da54856d148F2ad1a0eD)] = 1;
        reserve[address(0xF6c7439B601776E97c6dEed8394aFBF3B553Eb2a)] = 1;
        reserve[address(0x8a4fFBcbCb3eabDbA21be5f23DD00C42bfC10440)] = 1;
        reserve[address(0x9b6faDedcbE50876eaB12F5109E4C370cb97089E)] = 1;
        reserve[address(0x2Fb5933955f0292e20B5dB15eAeB67C35D246482)] = 1;
        reserve[address(0x4824DC193DCA8Fe6C0bAD6dabBC7385aCff10E53)] = 1;
        reserve[address(0x65565D22279F1F90eAd09A1DfBD4FB1E7D4e707A)] = 1;
        reserve[address(0x7A72610aba824163D340f63dFf7515a839156B04)] = 1;
        reserve[address(0x357931791284f40765b462aa7AD217ebF82920Cb)] = 1;
        reserve[address(0x021d5ABEA6EFbcD5dBa2C8Ae9237471448Ea0856)] = 1;
        reserve[address(0x946237Dd48b0751D59dF97487ce483A0B27cD2D6)] = 1;
        reserve[address(0xED721dC63328be92A08b6b7D677e11100C945eA9)] = 1;
        reserve[address(0xD7b07B4dcfd4f0A4E0EC73DEdfcF8F6E9Cdd4A84)] = 1;
        reserve[address(0x535fd58A1AE82CcF3935b97347665059C89de636)] = 1;
        reserve[address(0xA733D53C52D8a07Ea28627187A047E7015eF34b1)] = 1;
        reserve[address(0x89BDe316a5Aa59D9995fc82B217308aBae60257c)] = 1;
        reserve[address(0xad3372Cd209550e03AEebA8a756688d6255F94EB)] = 1;
        reserve[address(0x1E506e6af1DCF5633e105AD36FCFe0AC83DCE013)] = 1;
        reserve[address(0xD0611Ec607d26a954Fff1E325A0CD0849D56Fb23)] = 1;
        reserve[address(0x70B8aC6BA517e152299d06Eb7A3FB2ECbbb00C90)] = 1;
        reserve[address(0xd61c66607C0bA44172Bd5C5f5b7C0FD79d64C6c8)] = 1;
        reserve[address(0x38c48591a1865E7824f9cE270c46d9cbD329c9F5)] = 1;
        reserve[address(0x49bbeFaC419e8348B9227e38E8331920Ce06F0ca)] = 1;
        reserve[address(0xF2AAe3991152F43bdB92cb61658a5B53D170036e)] = 1;
        reserve[address(0xc8430556dB46fBB9Ef7875dc3d20bCf93A2B13E8)] = 1;
        reserve[address(0x087e282F6275538Ed99B1E7df165EddEB745f3a6)] = 1;
        reserve[address(0x87661b4740FD1a6ac45a927079E1DB09827dA4bA)] = 1;
        reserve[address(0xF8062Dc3CaB598086d58fA6329e864b6B35C94BC)] = 1;
        reserve[address(0x6f1f500Ee2b486D7755FbdEA0C048672b07dBc73)] = 1;
        reserve[address(0x1427Cc00080f17dD10AA59e629eA3e2de14608c0)] = 1;
        reserve[address(0x38bf30d3F1528BBD2BB8A242E9a0F4405affb8d0)] = 1;
        reserve[address(0xB3479AC22aB13a9d359c1AA0fdf6F7e3D39A207C)] = 1;
        reserve[address(0x256B4Fb1ad00A7E6f130bEFFa33e435eb1F65b74)] = 1;
        reserve[address(0x07Fd1A1a634c35fdbE6b1f44F002b31E7c4e10D9)] = 1;
        reserve[address(0x9D3ff4d7C229635a3B5708664C728DAd30ADABd0)] = 1;
        reserve[address(0xF1fCfFBA10de3Cd282baf4b6E49393Ba03DD3Be7)] = 1;
        reserve[address(0x5D7dcb9F59d4E1Cf96463A72e866966149df1552)] = 1;
        reserve[address(0x667e13efA1a4ecDAD657128241045c1c26fE4645)] = 1;
        reserve[address(0xeF7655142d0c0502F0Cfe3B4e2b01D924C440028)] = 1;
        reserve[address(0xAc8C96600E469113C791F45f05FE12Cfc7D7438e)] = 1;
        reserve[address(0x4b05d8d17182E7d66D429A7981FA4330C4707b5c)] = 1;
        reserve[address(0x8BE13FF71224ad525f0474553Aa7f8621B856bD4)] = 1;
        reserve[address(0x6Db5E720a947c7Cc2f3FcaD4Cf5058402FC456c6)] = 1;
        reserve[address(0xFacC9E25E2cB511a51E980e2d0BEC5Fe6c62868E)] = 1;
        reserve[address(0xf94C3fD88Bae02B97aA6ed60Fbb3E569625C357B)] = 1;
        reserve[address(0x550e970E31A45b06dF01a00b1C89A478D4d5e00A)] = 1;
        reserve[address(0x0764dc400C280FF2B6D1F0582969C0c668271340)] = 1;
        reserve[address(0x300736a2C7eACaC5524930afF74779EcB2C775ED)] = 1;
        reserve[address(0x303c36E5c473bF36Bf643DeBEb61C68f780641Aa)] = 1;
        reserve[address(0x8011F9Bb55e6BEeC05BcE1e64Ff669eAC33afDa4)] = 1;
        reserve[address(0x1e77dC8B1a6a9b34487133bbce189412697131dE)] = 1;
        reserve[address(0x6FFCaD0e1BA3A8be68F0b8449CA1430173a3c451)] = 1;
        reserve[address(0xF13CCD4013DA3dc7b2dfbB2397dc9F5db8C1A44D)] = 1;
        reserve[address(0x56876f3F31582d65A9B99F22a7c2c84f0CCca723)] = 1;
        reserve[address(0x700643004BA7Cb17B824C6808A4196a06eB25E4b)] = 1;
        reserve[address(0x8cf85548aE57a91f8132D0831634c0fceF06e505)] = 1;
        reserve[address(0xa3E40b15F30A4A3D73C1d8435EE25041b05D1daA)] = 1;
        reserve[address(0x4F234aE48179a51E02b0566E885fcc8a1487dB02)] = 1;
        reserve[address(0x389458f93E387fC568Ca4568c231a64FFD0456d2)] = 1;
        reserve[address(0xFd4Ae32D49c48C62b3b3CEaAf588b7C1315F25B1)] = 1;
        reserve[address(0xC864B0Ab18B0ED0BeAb72F915Bacb12971FDb73a)] = 1;
        reserve[address(0x3401eA5a8d91c5e3944962C0148b08AC4A77f153)] = 1;
        reserve[address(0x0cE1e7CAFE72B4d48de78a2593d9f251345aE740)] = 1;
        reserve[address(0x0D30d188Ffb8e75C94d63e99609839f71752A761)] = 1;
        reserve[address(0x95e50880CE49E0F23339886cDeC174840eFFb6e0)] = 1;
        reserve[address(0xa6c3522C42bc46c0e4f7A20091ccc2fdB26f7303)] = 1;
        reserve[address(0x899ab9Bb40eF24a944856840739Aa99619B986F2)] = 1;
        reserve[address(0x2eE0485f71764bcD2062A84d9455688c581B90f8)] = 1;
        reserve[address(0xf22d36502069B9381b51EeBC1c4820C4Bebc660c)] = 1;
        reserve[address(0x1eAcc1960Efe0eDDA5f530A78071d2CF461616f4)] = 1;
        reserve[address(0xE707E35B08B6201a51Ab3B83d1c9Faeb816f8750)] = 1;
        reserve[address(0x79b66C1289BF77BD178B14bF33FF45b8aA4b692e)] = 1;
        reserve[address(0x9440505f4D2A69f3b4D2e90C9Bcc51E526bD7574)] = 1;
        reserve[address(0x6f4EfAf5429703649BEAa30da7e934bB42993C47)] = 1;
        reserve[address(0xa1B094E52401a9636e06EdDAcB2A772cEF671781)] = 1;
        reserve[address(0x65a78aBa0A3544c19F6503A7D39d8E45f85c60d0)] = 1;
        reserve[address(0xe2B5942e014215EB42Ecd00d5779a039418cF51f)] = 1;
    } 

    function redeem(address to) public {
        require(!isRedemptionPaused, "Redemption is paused.");
        uint _amountToSend = reserve[to];
        require(_amountToSend > 0, "No tokens to redeem");
        reserve[to] = 0;
        totalAvailable -= _amountToSend;
        _mint(to, 1, _amountToSend, "");
    }

    function available(address to) public view returns (uint) {
        return reserve[to];
    }

    function setRedemptionPaused(bool isRedemptionPaused_) public onlyOwner{
        isRedemptionPaused = isRedemptionPaused_;
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

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor (string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155).interfaceId
            || interfaceId == type(IERC1155MetadataURI).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        _balances[id][from] = fromBalance - amount;
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            _balances[id][from] = fromBalance - amount;
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] += amount;
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 accountBalance = _balances[id][account];
        require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
        _balances[id][account] = accountBalance - amount;

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 accountBalance = _balances[id][account];
            require(accountBalance >= amount, "ERC1155: burn amount exceeds balance");
            _balances[id][account] = accountBalance - amount;
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal
        virtual
    { }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
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

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}