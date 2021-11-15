pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IMasterChef {
  struct UserInfo {
    uint256 amount;         // How many LP tokens the user has provided.
    uint256 rewardDebt;     // Reward debt. See explanation below.
    
    //
    // We do some fancy math here. Basically, any point in time, the amount of CPCs
    // entitled to a user but is pending to be distributed is:
    //
    //   pending reward = (user.amount * pool.accCPCPerShare) - user.rewardDebt
    //
    // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
    //   1. The pool's `accCPCPerShare` (and `lastRewardBlock`) gets updated.
    //   2. User receives the pending reward sent to his/her address.
    //   3. User's `amount` gets updated.
    //   4. User's `rewardDebt` gets updated.
  }
    
  function userInfo(uint256 poolId, address wallet) external view returns(UserInfo memory);
}

contract CopycatTokenMigrator is Ownable {
  address public immutable adapterAddress;
  mapping(address => uint256) public a;
  mapping(address => uint256) public claimed;

  constructor(address _adapterAddress) {
    adapterAddress = _adapterAddress;

    a[0x01Cab493a81CD35C641cA247F505D8A6Ab82279a] = 62 ether;
    a[0x0245235CC5208c1B7a7B872763f810420Af344a9] = 2205 ether;
    a[0x0468c3183E52FDb2c8028434cDDDb77D6dF10426] = 1965 ether;
    a[0x06848D9d2AB02250E8BbB03Ac2115294dF8c9403] = 2089 ether;
    a[0x0694e8C9D228435c1053FCDA01809196D82549D2] = 7529 ether;
    a[0x070D2F3229AeD24B265c4164469b7c8C24C95Ac6] = 129 ether;
    a[0x07a02D9484D5363D33Ae83e64b8F02d8E0bCc489] = 2103 ether;
    a[0x093C2A23BD1f77653cf8a924322642493337B683] = 1120 ether;
    a[0x099a0Ff1BfdBFC8db4fA0957A17E248ffa1F0C85] = 187283 ether;
    a[0x0aeC0b2e76A93E2b8dcCC29F9F7653f7b26787C0] = 24 ether;
    a[0x0b29702F2362370a2e9dC5ea9E444535f8866353] = 46127 ether;
    a[0x0baC796e666DFd1253d88Bd950b78f8A169176Cf] = 108 ether;
    a[0x0bc7A4e31953A4eEfF7faCd8847EF0b17128a1F7] = 12 ether;
    a[0x0bdF8EfF73BF53305f088037b8D231F7ccc99805] = 1918 ether;
    a[0x0c45F49895232E64640dA076C048858cDd7246Ff] = 3767 ether;
    a[0x0c4c103c238D078c04087AA4530F862F3479dC23] = 150 ether;
    a[0x0fD424454E78230Bc9d833F2Bcd08a2c4F909f4A] = 6668 ether;
    a[0x10C9d12b2CDfE6AB3FD22e93593a7adfA8246f99] = 4615 ether;
    a[0x11e8e8696A4D284ccD1d7Fe247deD0A9eBA90421] = 1108 ether;
    a[0x1211dD43DDE287429aBB018FF3c926211299B734] = 1187 ether;
    a[0x1262b6d781EAd81D076867193A6713615456Cf16] = 91 ether;
    a[0x1440f7af1889f8546229481576E1481D1466e1aa] = 26 ether;
    a[0x1790a6D2517245Bdfe1f04b9340F9fFef37222FF] = 21 ether;
    a[0x194BBeD7295bf17710c52719418030436EAE978B] = 570 ether;
    a[0x19602E4ed56a904aaA8CfbD242A2B69683bB5848] = 7 ether;
    a[0x19f11c872dc243F03536a1115a4A7190B5295c58] = 16352 ether;
    a[0x1Be941C9424C86788D9CEc3B9A0A05c7B27f9768] = 113 ether;
    a[0x1C86E98A4CC451db8A502f31c14327D2B7CEC123] = 817 ether;
    a[0x1Ca012B2bBd39d3a67c406dc6af3aEb3FE2a7F81] = 2173 ether;
    a[0x1e06a2687c0930017525BEcd4637d6936f882191] = 1137 ether;
    a[0x21D3eDbB874D343E31021c9F078f7650e958DCEf] = 711 ether;
    a[0x222dFE436369f94ccf6389E0d56F64879F581053] = 19727 ether;
    a[0x2242A2a44ebD2B5ca6E8815EA54b295fb3F27987] = 411 ether;
    a[0x237c1041bDbcCc2e34743153FFabD1759043d7b1] = 3 ether;
    a[0x237CbdcbAc692c2Af39D8b79A3A10596a12a1e88] = 176 ether;
    a[0x25a6358F4b5D61bA9a2D42ee46c4bcb9a49D93bF] = 349 ether;
    a[0x291E849Cfb80eCea42B166cf5Bc2250B79D4b7D3] = 83 ether;
    a[0x2E101d2B6AE13B8585806c073428252462f177fb] = 788 ether;
    a[0x2E5cF537182BD6c88475bF62fB9DD37BA0AE1966] = 369 ether;
    a[0x2f98ec7247f1ad05b46447dBfA2D2243BDa5f108] = 106655 ether;
    a[0x2FDD1bc8aFfB60BCD30b96f9838d1DEDd6689998] = 5094 ether;
    a[0x31ea9e15ABf1F4067Ba0DC2529Be915f5326C92c] = 7261 ether;
    a[0x341AfA955291F40e10026c11f2720CFA1F2e352F] = 1485 ether;
    a[0x35195c58974AC78520aBEb6010Fc95695F738267] = 24793 ether;
    a[0x3C516f085E94177Eaf0BdFB5b5eb1aB71052d064] = 98 ether;
    a[0x3C89455B2Bd1D3D36a550e99aA986a427728D482] = 101 ether;
    a[0x3FCb7EFFcA26f7108154A2d83d3BE38c55E3F942] = 318 ether;
    a[0x403a52AFe80B4cE6930e6b2b746aC8E22F8144ac] = 677 ether;
    a[0x40981d51257A575f73418FF8647a68F246864F1C] = 341 ether;
    a[0x40cE3a36Fc1bF64A8e3FfC37B99b07573bCfbED8] = 952 ether;
    a[0x42281197FCc96cAa4934472327a0fE611BCE5384] = 1231 ether;
    a[0x42de67722E7Cb056041E456bfB195184384a8593] = 327 ether;
    a[0x440BD23858e50918895171F24D4e142E5A1Abe39] = 3097 ether;
    a[0x451aFE80464D85632C7FBC41CB12869E6d3A96bf] = 563 ether;
    a[0x45CfE1C52B761E36d233B913a486a39d9FcFB197] = 1962 ether;
    a[0x4a459480E4dC48CaD96cE726412470d790D308f5] = 372198 ether;
    a[0x4EBE5483df2e861C748394c55bfBE77C94dD46f0] = 5 ether;
    a[0x4F2fa02BAc75e0694Fe7cE22C13519B3fDC85CaC] = 54 ether;
    a[0x50D532e3A95Dd7D0cf1B04b02a5FE42DA1C9D2d3] = 4378 ether;
    a[0x520EEBAe24Ec7a1806Fd931E3330722E361b2620] = 6085 ether;
    a[0x530014662C29eCBDC93cB52F8984eBe81Bc4c301] = 40 ether;
    a[0x570214655b3888137F778b6A831d43916354E1f9] = 3571 ether;
    a[0x5814e1E0b3Eb919bA4231b14627cA406B1D9549a] = 3993 ether;
    a[0x589757C9346aE769b400274803c3dFAd24fFd34E] = 134 ether;
    a[0x5E1270eb5D5eF03825c814978d89880cCe309182] = 5493 ether;
    a[0x606C5D1033AF33b96C2b29334D0e85447DA6C4Fa] = 240 ether;
    a[0x6222329dC5b8C62F4e56E04f4c613a18Ae01C5cA] = 3255 ether;
    a[0x635a71066D2ca5e34209C22E2c72fa9C6A3f8573] = 87 ether;
    a[0x65adcb532d1037a2D22B9B0F8E75f7f960d85090] = 769 ether;
    a[0x67CB1E08fA19615828E601B7d7fD586dfEF6a842] = 16997 ether;
    a[0x697bF9fc627AD6C3da8da75966fAae1278247fF3] = 88 ether;
    a[0x69D8c4d917b3984fa83853f43b5028D375FA2701] = 108 ether;
    a[0x6aB5BE7e79C6F18e2CCC48988BE8EB7a5C7E9d32] = 15897 ether;
    a[0x6aFDeC2438F8709f2ef2b80dfd00faba22fEC4E2] = 161988 ether;
    a[0x6D103B80F678986D60fea337ebA29dEBD112f0ac] = 247 ether;
    a[0x6dBe4d49033DE3B9580A5377c21DCa58B287Ab4B] = 1925 ether;
    a[0x706067004Df1f393DD03bc0a15D12D338EAD8Ba2] = 4742 ether;
    a[0x707C6e715350Bb4A189bB542468518D009A24cAe] = 8605 ether;
    a[0x7208Bd63662Fa3a211B7D780f48f591282F16163] = 241 ether;
    a[0x73760B1A2971b85e2F4A172984865E3B3354e577] = 18500 ether;
    a[0x75150a08f7Addda22D16c791458b8b8F049Dce37] = 4300 ether;
    a[0x7644350B9189C8f3b446bB7D93b5d4A57DEc443c] = 955 ether;
    a[0x77a5b36e99EAdc62df9645E8DF34D9b2B24852db] = 697 ether;
    a[0x7B7b1938083bdFDE76FA30ef08964A8cD0A7b522] = 1292 ether;
    a[0x7bB48D1869F0Da23ec194FcCF2eFE1E9eaC8e860] = 21 ether;
    a[0x7d5Ea6D9D8892a7a02a35ae3A4AA44E3C905a77D] = 997 ether;
    a[0x81A3Aab18149ADAe19709e8E87d21A844D1CC5B9] = 311 ether;
    a[0x81c61C5fC10bB23380BAEA9D7dFA570203287748] = 20172 ether;
    a[0x82534cfDEB2464e08Bb1B394e3c0BcA62B3c965C] = 76 ether;
    a[0x851583AbbE19cc153C5809cCD62A6808cBCE601C] = 16 ether;
    a[0x8556F0f30B78707Ff9f96c8F35B8097e184f98B5] = 3703 ether;
    a[0x888Ca3F8063f08FE9CD678cbABBc850203900523] = 5042 ether;
    a[0x895C2066728D94Ecf3ed271EDA094170e328F2be] = 31349 ether;
    a[0x89757C23C37268A2059d24Ee43802fd818171B04] = 206 ether;
    a[0x8c52A0f279b4c7BC56b1903C19C91ecd7875fF8D] = 29 ether;
    a[0x8C61bfa9585ed46E7e3e5b4Bc47ab0565ADc0243] = 63 ether;
    a[0x8f6173288B9867E556a2b15610a9c5A9474eef70] = 756 ether;
    a[0x9045AfE497A2d24302131891631e3A3F22583156] = 232 ether;
    a[0x9215F394a637A4ED09B7357e8713fb15fB5D5A65] = 1657 ether;
    a[0x923DcB1bDAF3368016Ebc8eaA20FbA444F18F6E7] = 5349 ether;
    a[0x934CeC3b28baabc7e4285bE5ffacC4846d575782] = 2488 ether;
    a[0x9825c60C6060300b8f2965B0f14699339Ac916d4] = 579 ether;
    a[0x989Fca0AdBbFE49a6C1E47A2B6b5c908aE4925F1] = 2236 ether;
    a[0x9a98c3Da740eaDDA004d8dbB03E1669C20443C2b] = 6301 ether;
    a[0x9aCD39b332d31F3a4e361c4E56894B823630E3dc] = 11365 ether;
    a[0x9aE6B6a74e1059AE85fAaBb4d2e00Dd719362816] = 434 ether;
    a[0x9af78B89eddb9830E3E4ce2Ba8CA34Bab8DF5fC2] = 820 ether;
    a[0x9b10bd16bb39273B86C1934f1d857EC51B1122CC] = 107 ether;
    a[0x9b6Def8e53900780D8d2BB8c349d1fAC55Eba704] = 22 ether;
    a[0x9Cdc525b3a2ed868ef50ec5649eb64c34290De13] = 2605 ether;
    a[0xA4E131A22DF699e6b3EE2933B614bD75457f6bd7] = 18162 ether;
    a[0xa4f0A8105C564E54cf1f5b761a4Faae59A267973] = 212 ether;
    a[0xa617905AB90Ff1722ee2e7b7363793344C3AD0d7] = 97 ether;
    a[0xa721aB381BDF5AEDC05686792bd38b1D94F3168c] = 783 ether;
    a[0xa88fF6bFB02e175FB8b69a790c91eEA527eB19B5] = 3957 ether;
    a[0xA99941AF4d81A51588aDC01B189222700D3f2286] = 5 ether;
    a[0xAB99bD2cd338d856c56778da5413F7eac50C38cB] = 34855 ether;
    a[0xAbbbaa9b0Ae75E068b75F35313795FaF47C47230] = 254 ether;
    a[0xAc66218C5a717c7D72B1144980e3E6B942Dc9850] = 860 ether;
    a[0xaCB0d3143e0193c442a472b0E3B3ebC6Ab192b1D] = 159843 ether;
    a[0xAD4c31E7d3A5E0C399f0eC378474A71360c66d2D] = 26 ether;
    a[0xAf4a6e7438459F1cC99Cc0a80B075D4e6B62EcEE] = 3175 ether;
    a[0xAf9E59898270C170d1074EDEde97E645011d2f02] = 4022 ether;
    a[0xAfDaCeA33C44674C592A464f5f37F33d297BeE94] = 432 ether;
    a[0xb01A458cBB93461e3852cb4AeD8a8562358cAcB3] = 1435 ether;
    a[0xB0C555D876A0927c4741DBD0f14E75C36Dcf19d3] = 314 ether;
    a[0xb1025Fa2dd293Fab30d362239b8884E9CB4d2b71] = 65 ether;
    a[0xB1B5d0E64FDDF0c937E94C8B2D143c35A459721e] = 170 ether;
    a[0xb268849d8179BdDa73F6D9B9684359ED829ce3Ab] = 33 ether;
    a[0xB336FCda2f495a1acc1832f48Fb1300bAb999CB0] = 6969 ether;
    a[0xb35C453A9fAA1829C0B932a1935FB417823a9295] = 3825 ether;
    a[0xB36F086a1040B78b4a61f9B1bC4a079279cb1Af5] = 200 ether;
    a[0xb3c2d15ed7EB111deAbf8ffE0Dac0c4ADf1A2237] = 1020 ether;
    a[0xB67F7e6b0da5c9a2876f429bB760055c949b1528] = 3127 ether;
    a[0xBac18356C49F314feCC62366C6396864d501c912] = 2151 ether;
    a[0xbb1E0D910BbdDcA64Aca387bA555f805f7A97689] = 4828 ether;
    a[0xbD6abA8576D6a2efca534b7002f3fd8C563a3d08] = 172 ether;
    a[0xbdf3CC6c4Efa64e7De397f31E0d09E42e1e7654c] = 12797 ether;
    a[0xC1dD9f9525fB817a611298DC038C31b62ACd1d53] = 242 ether;
    a[0xc2221D3a952111012Bd3026B1292E1E7E4Cba2C7] = 4054 ether;
    a[0xC3FdCd1a1859229Bd39997aBE0AD532B066ff11d] = 81 ether;
    a[0xC443c4922368623DDEDE1558649c60b141e1144d] = 663 ether;
    a[0xc45D74B2f184796e49ef98a711Da8964685f4880] = 2809 ether;
    a[0xc58b02b363200d77515ee1A9727156De9D034d1E] = 1666 ether;
    a[0xc67f337d406Ff8f4Ebd6dD47E334d4d2CBead36B] = 4905 ether;
    a[0xc72D3B15C8dE940Ce3Fabd63222eE34dEC8698b4] = 55011 ether;
    a[0xcac2d42b38310759B423e7BB57fC1673a4a89542] = 2452 ether;
    a[0xcac66B5a75A34ac3Ce80b3DC52BD253164943D15] = 423 ether;
    a[0xcB619dfD4ffC1095A11010e34FD888606D122756] = 666 ether;
    a[0xcb89647255174cEd5Ee1e87ABC0Ef2Af333ddC7d] = 225 ether;
    a[0xCC3Adcddc1110d2282cA347df91ed34e9bE3fC15] = 4587 ether;
    a[0xcD5CD26437cBDeF15a92ebB9170838C784c770b7] = 2 ether;
    a[0xcDFfcBd1D9ac9CE0fa4F4f9679Be75CC40eD4250] = 5926 ether;
    a[0xcEBBb296DF5F87516dd6f9F8325996fB1883d5f3] = 876 ether;
    a[0xd07041C9B67d66bE5077A5d3F3B55B93dc0d6caa] = 1223 ether;
    a[0xd17a58cd9C882C69177a6C22E096A1C61a9Bd612] = 4 ether;
    a[0xD1f73b9E864cB3BA9C33a72F558d935e39E6911d] = 89 ether;
    a[0xD2A75AbAafb3727d5e6eB1791538042D591EaB20] = 327 ether;
    a[0xd2d2FB32360Bef330E2b1c80EE786228658ecf1B] = 49 ether;
    a[0xd3fE5270420486Fe71E7A8247E42AEEe581A6435] = 10548 ether;
    a[0xD526197344dB2AF4dc1121A2d28360188DFc6a93] = 1045 ether;
    a[0xd5372B34471e5F858731406Ac8afcB89a86ff4A5] = 3 ether;
    a[0xd71bcc532498A5Ab281E394aCF82bf58aC0ba09B] = 53614 ether;
    a[0xD8804786d0F6bE618ab16F381dA9c62d091Fa31B] = 149782 ether;
    a[0xdA61E49d4F761e99d5fc684726e974cd809506e5] = 50107 ether;
    a[0xdAE1DD81D3fFae28B86a51781c597b5B058BC567] = 3270 ether;
    a[0xdb06A579BC0796873F8aC6fc7AC6bF98Ca965730] = 1135 ether;
    a[0xDB6C7a1af71bA12e6478cA42Eb7380ad9Dafc868] = 1308 ether;
    a[0xdD6B88cf5bE2475342d99ed92A69Ee62ce11D47A] = 4202 ether;
    a[0xDf33Cf8651aEC39cEBf6C5f150766556353dF3E6] = 57 ether;
    a[0xE0EbD0A1D84E60349BC57bda77F9c35ECF61fb4e] = 3964 ether;
    a[0xe1283E9a77aF42943B3A6469F75eaFa626F55eCC] = 285 ether;
    a[0xe2eaCf129A660698D6C90733093d4Eb2c6c8D2eF] = 16000 ether;
    a[0xe341de566D1cf23BC000FE578bc2781d9fC0c543] = 9 ether;
    a[0xE3a692ceA117Ad2b1c714eA04C0894174E7E849B] = 578 ether;
    a[0xE4AC54B53E1d7535da4036cFcCE365bbe54C5f6e] = 3001 ether;
    a[0xE4aF5685CCF609aDeae93a974c48D700d6Bf21ea] = 89 ether;
    a[0xe91a75aa1b89F482eE65430CA9cDDCb9a0282970] = 38 ether;
    a[0xEae03EB54eB26B38057544895E834aF42fc46A69] = 17 ether;
    a[0xEb2AEb8C7c5C4fD3eA115ffF6b475c57D7Ca0188] = 142 ether;
    a[0xEd65a87AB264B68B0902D1888999E99B6e765FB0] = 22638 ether;
    a[0xEE5f5197E94fB8Fba3c7FB94219B3A238f3841bC] = 10434 ether;
    a[0xeE8FDAf62D29020E9702FaB09B807d55173Fb681] = 16 ether;
    a[0xEeC58132A0EF54C1d058d281D9d59Ce4A7bC7B00] = 754 ether;
    a[0xf01Dd015Bc442d872275A79b9caE84A6ff9B2A27] = 19538 ether;
    a[0xF111F70B15313Ad9D870cc2275F88DfBE5d831a5] = 294 ether;
    a[0xF4Ca7Dab37d9F31B3064D6929d65487BB68Cd111] = 66274 ether;
    a[0xF66278afB3417A4a8F6dfADca08DEEa2967fb783] = 1394 ether;
    a[0xf7bC5a09cC4843fe78b91cBD0247deaFF9507aAa] = 83 ether;
    a[0xf97b8A6Fea3Cdda688e1ba14D1A6f680143f315C] = 1 ether;
    a[0xFB527990c12186f8DB1640bf8DCb083100A39A21] = 9602 ether;
    a[0xFCc623784010cF10BB2DaF3EaA2BA49DeEe61a11] = 58 ether;
    a[0xFD5ff07c22FFE7064e6c3F0ca212BBcDA7F86933] = 3657 ether;
    a[0xBBD561B7997bfE9839ae4e678322E171644A21E9] = 37806 ether;
  }

  function balanceOf(address wallet) public view returns(uint256) {
    return a[wallet] - claimed[wallet];
  }

  function migrate(address wallet, uint256 amount) public {
    require(msg.sender == adapterAddress);
    claimed[wallet] += amount;
  }

  function setAmount(address wallet, uint256 amount) public onlyOwner {
    a[wallet] = amount;
    claimed[wallet] = 0;
  }

  function getStabBalance(address wallet) public view returns(uint256) {
    return IERC20(0xaf596EBEAF7b06571B39A5F88674B65832eaa6b8).balanceOf(wallet) + IMasterChef(0x9a1B69F216Ea3b9d7c4F938eDAEA0dAe7E758C17).userInfo(1, wallet).amount;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

