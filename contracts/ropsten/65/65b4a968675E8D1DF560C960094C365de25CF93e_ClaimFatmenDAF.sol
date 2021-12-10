// contracts/ClaimFatmenDAF.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

contract ClaimFatmenDAF is AccessControl
{
	using SafeMath for uint256;
	using SafeERC20 for IERC20;
	IERC20 public token;
	IERC721 public token2;
	

	uint public constant DafForFatmen = 50;
	address public Creator = _msgSender();
	mapping (address => uint256) claimers;
	mapping (address => uint256) public Sended;

	uint256 public Amount = 2500 * 10**18;
	address public TokenAddr = 0x26574A2e05632444Fa33090E3269a9E49952E482;
	address public FatmenContract = 0xCC9A348075F7ecfd3c207D97D2343F06769A3EA0;

	uint8 public ClaimCount;

	event textLog(address,uint256,uint256);

	constructor() 
	{
	_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

	// 10**14 detail on https://github.com/dArtFlex/fatmen-airdrop/blob/main/fatmen_nft_address_list.sol
	// Because the gas is very large, then we will take the data directly from the transaction
	/* 
	claimers[0xF6168297046Ca6fa514834c30168e63A47256AF4] = 50; // 121,120,119,118,117,116,115,114,113,112,111,110,109,108,107,106,105,104,103,102,101,100,99,98,97,96,95,94,93,92,91,90,89,88,87,86,85,84,83,82,81,80,79,78,77,76,75,74,73,72
	claimers[0x0B01fE5189d95c0fa890fd6b431928B5dF58D027] = 40; // 275,274,273,272,271,270,269,268,267,266,265,264,263,262,261,260,259,258,257,256,252,251,250,249,248,247,246,245,244,243,242,241,240,239,238,237,236,235,234,233
	claimers[0x7A4Ad79C4EACe6db85a86a9Fa71EEBD9bbA17Af2] = 21; // 462,461,460,459,458,457,456,455,454,453,452,451,450,449,448,447,446,445,444,443,442
	claimers[0xbc8ec3182E5243681a848d2a0fBF10df8ebFe230] = 20; // 306,305,304,303,302,301,300,299,298,297,157,156,155,154,153,152,151,150,149,148
	claimers[0xb8b52400D83e12e61Ea0D00A1fcD7e1E2F8d5f83] = 20; // 191,190,189,188,187,186,185,184,183,182,181,180,179,178,177,176,175,174,173,172
	claimers[0x84414ef56970b4F6B44673cdeC093cEE916Ad471] = 20; // 221,220,219,218,217,216,215,214,213,212,211,210,209,208,207,206,205,204,203,202
	claimers[0x04bfcB7b6bc81361F14c1E2C7592d712e3b9f456] = 10; // 71,70,69,68,67,66,65,64,63,62
	claimers[0x8ac51a5d5921Bf5640ddc6633f13FcD0d8e19be6] = 10; // 131,130,129,128,127,126,125,124,123,122
	claimers[0x35e55F287EFA64dAb88A289a32F9e5942Ab28b18] = 10; // 232,231,230,229,228,227,226,225,224,223
	claimers[0x1aB89De00F039d9De0E17cd1F1A5E7372C475aC3] = 10; // 478,474,473,472,471,470,390,356,338,1
	claimers[0x0DB0f4506F5De744052D90f04E3fcA3D1dD3600d] = 9; // 142,141,140,139,138,137,136,134,133
	claimers[0xFC04c7710A9D28fefc989d57e2D64F3A10A0ADBA] = 7; // 387,386,385,384,383,382,381
	claimers[0x3478b441e07c418BBa592e9CA395A056ddBB4501] = 6; // 355,354,350,348,347,346
	claimers[0x4d35B59A3C1F59D5fF94dD7B2b3A1198378c4678] = 6; // 201,200,199,171,170,169
	claimers[0x44e02B37c29d3689d95Df1C87e6153CC7e2609AA] = 5; // 327,326,325,324,323
	claimers[0x82E19d4D7C8628d0d3b9F81aDcbE851110837009] = 5; // 6,5,4,3,2
	claimers[0x2E274c4b918A6C24120a5cf6Bee08aF71621fD3A] = 5; // 147,146,145,144,143
	claimers[0xB28d41a6009a62370000b4eB95f6eE8a1Cd37df9] = 5; // 48,19,13,12,10
	claimers[0x48483532FdEaAE4c3EfD9fc0fe198FD9b205f83a] = 5; // 198,197,196,195,194
	claimers[0x1301A5a67ac6F7B48226Cd66883676f7D1aAB280] = 5; // 405,404,403,402,401
	claimers[0xb1939686CbFACE3f81941dBb7CcdAC99e4BDf3a8] = 5; // 377,376,375,374,373
	claimers[0x6187Db185Dc494Ac870A7CE3EA6F7e84DaC37db0] = 5; // 296,295,294,293,292
	claimers[0x871359604Fc77163EAB9b170007CE45203f451d2] = 4; // 168,167,166,164
	claimers[0x043475088B4A4f5f96665C874Ec3715B760CB9be] = 4; // 412,411,410,409
	claimers[0x2dC63AFdcD09710F00CceFb88fe4926C9312bb84] = 4; // 360,336,335,46
	claimers[0x40eb586F9bD55B1a05b6F840e0b43d4877494050] = 4; // 316,315,314,313
	claimers[0x4273e7ADE3386986d8C60Cd9AE6520696686d574] = 4; // 489,488,487,422
	claimers[0x88591bc3054339708bA101116E04f0359232962F] = 4; // 322,321,320,319
	claimers[0xCBa0A892a9A7eB7953D4D32a53B329920969A984] = 4; // 165,162,36,0
	claimers[0x5973FFe2B9608e66A328c87c534e4Bb758618e73] = 4; // 499,498,497,496
	claimers[0x24a5FFc3E20f8B88BaF5A9B1D90EE4DA3915643b] = 3; // 353,352,351
	claimers[0xA165273b0B3e7E79bdEc610B2E28CCED92F3A986] = 3; // 279,278,277
	claimers[0xFF57cb5479d011fD3E2136D9d67DD5DA92ee9A60] = 3; // 334,333,332
	claimers[0x5904bef7365FDC41E476Ff9A41B702D72E80B6Ec] = 3; // 288,287,29
	claimers[0x773338f432A608D09F7099045509a7c9be34edb0] = 3; // 418,417,416
	claimers[0x0EeCfeFECc0AaB00b0180dB036525e016Cb5cb4F] = 3; // 425,424,423
	claimers[0x057291BD078F28687009ec4f17672adf6FE88423] = 3; // 286,285,284
	claimers[0x846f1b46354b4E1E5Dc90c83d5139571AB1cA8ab] = 3; // 435,434,433
	claimers[0x24f39151D6d8A9574D1DAC49a44F1263999D0dda] = 3; // 465,464,463
	claimers[0x7fBD680e9F080D1077e924aAF150539518bD8185] = 3; // 469,468,467
	claimers[0xfbF9EfC74f0b7bA03497Be13B757fe138Eb0ffa1] = 3; // 477,476,475
	claimers[0x498E96c727700a6B7aC2c4EfBd3E9a5DA4F0d137] = 3; // 482,481,480
	claimers[0x245Fc88F2549eA81914BEA427Ce3ae84Efc381F5] = 3; // 486,485,484
	claimers[0xc3a53f6ECa08FD0F9B4Fb927C14caD0168aB4049] = 2; // 282,281
	claimers[0xD387A6E4e84a6C86bd90C158C6028A58CC8Ac459] = 2; // 23,16
	claimers[0x54Ec6aa232B3BbD497b8aB9163bbC74271090BE4] = 2; // 290,289
	claimers[0x18Eeda2a6bB673DEEC7cdbF5167D13b9dC061189] = 2; // 429,329
	claimers[0x93AF249b7d54d33fCd5CeF3f4d88feeEFD68251c] = 2; // 331,330
	claimers[0xc674fFaD8082Aa238F15cd5a91aB1fd68aFEcEaE] = 2; // 253,222
	claimers[0x31923E1811CB6d5C26870439d457705505dCf402] = 2; // 341,340
	claimers[0x057f2D45771a7b4741b4AD854DD2127A1974bEDA] = 2; // 364,39
	claimers[0x619B23Ef1f2990ac94E4A5D2Af9877BCae5C37c0] = 2; // 398,397
	claimers[0xd94B222eB8b1838c8a89EeC73A41211259B5Ff5d] = 2; // 437,349
	claimers[0xe7bD790Bf7Ba642Ed5bf77a411147bDBBe7ae6BA] = 2; // 362,361
	claimers[0xbcE5fADDb7419A160Caf15567e310a07a2F677A1] = 2; // 379,378
	claimers[0x6Acb64A76e62D433a9bDCB4eeA8343Be8b3BeF48] = 2; // 396,395
	claimers[0xaf2F5dAd0b2D44ddcA1d4D673bE401C63E089d97] = 2; // 400,399
	claimers[0x67C188C9619Eec8c2964906502540d8Ddb447790] = 2; // 428,427
	claimers[0x3b63410fAdbDA0ec0bA932fAD2997edd7A842679] = 2; // 432,431
	claimers[0x9f8eF2849133286860A8216cA11359381706Fa4a] = 2; // 466,439
	claimers[0x14D2e76401aBFFeC6b34FA3961b2Cad5c3a263Bd] = 2; // 441,440
	claimers[0x1DfC5a35DCB9F8A9611652723E47875d810a8E9C] = 2; // 493,492
	claimers[0xaa8404c21A938551aD09719392a0Ed282538305F] = 2; // 193,192
	claimers[0xDD627852e2BD9ecc3208c481E39b4014bDfDa0F8] = 2; // 310,309
	claimers[0x1EAA3F1Db7FE01b28C8f7765F4Ad280CC1E49496] = 2; // 161,160
	claimers[0x280b8503E2927060120391baf51733E357B190eb] = 2; // 159,158
	claimers[0x6936FBD29759615Aed4e7Efe98b0718516aaB70E] = 1; // 30
	claimers[0xe01756f828795057de1578bb340DC51B38970DB5] = 1; // 55
	claimers[0x067c0487d514959342f1DCf84C66FfC360c8f4f0] = 1; // 419
	claimers[0xcdE5C5A08e8D8a50b0BE7d0eCC11AaC77b9bb96a] = 1; // 54
	claimers[0xBFCD54D183fAb1F84Af3517D07b600095E1d8F9E] = 1; // 415
	claimers[0xf7a92220D34A64a0f1678F3540217e7508Eb1f9f] = 1; // 414
	claimers[0xe4d7613Aba9d39DCa56A6eCB5d462a4595172282] = 1; // 413
	claimers[0x9F06d7e9cEfd3092d18736d41Dc6DdA1673A9645] = 1; // 9
	claimers[0x5798c7E2213094D158593f7732D4fe64ba0a9305] = 1; // 408
	claimers[0x6F6ed604bc1A64a385978c99310D2fc0758AF29e] = 1; // 407
	claimers[0xdD03BaBfaBa0150354a8601F61f7DD3055D98fee] = 1; // 406
	claimers[0x6E02e27F03Ae982a3De019BCdB01AeF3CA8a91e0] = 1; // 11
	claimers[0x0B330Fc7B758428bD0CdE1061aEcf00824410EFb] = 1; // 57
	claimers[0xC411d2393edd298186A2b31C0C6cC979B0e81836] = 1; // 56
	claimers[0x32AF08475300DE2d3B55F924695A754De593e493] = 1; // 421
	claimers[0xED53542Fd38535940cc616699Fe53a03f41fbc8F] = 1; // 394
	claimers[0x06E1AB8BaA241b8A527dBC320573305C7eE80528] = 1; // 393
	claimers[0x19CaF2B2a757e30Df112328e93B7090ffB49a37e] = 1; // 392
	claimers[0xe2cB4Ae013fbe5871f44968A317071eC624D90F1] = 1; // 391
	claimers[0xF95da47df439d6347d4F60C33b803A5A213FE01E] = 1; // 389
	claimers[0x21504E435ceEFce0d9fed6327719F9fA07251B69] = 1; // 388
	claimers[0x883Abb36260Dc066F318115DDE0F4Fd6E8311875] = 1; // 14
	claimers[0xBaeD449f8D45A0ad59fc4EA7aaa8123355415bd2] = 1; // 380
	claimers[0xDc0e734AE36F960445b5F38E4ae14133eb47cC7d] = 1; // 58
	claimers[0x468F18273df540cca6dF3380b28ab16BDf9Ab9d1] = 1; // 420
	claimers[0xC03fe5A6a856adcb1b2A1f3080D44888F47385CD] = 1; // 53
	claimers[0x12bBc0f95a3e86B34e6943bF6f9eA81a44595c02] = 1; // 8
	claimers[0xfC670EC7caBB23CAc716B02bAefdA4b107e7027D] = 1; // 45
	claimers[0xA1e46ae1BAEbe23d50E45BAbda5d683Ede0D36Ca] = 1; // 495
	claimers[0x62cfc31f574F8ec9719d719709BCCE9866BEcaCd] = 1; // 494
	claimers[0x817292C7e0941cf99C37277f2f81236A002aE27c] = 1; // 41
	claimers[0xC0c7BDF412828A3f21400a5072ED8290Cd7Dc180] = 1; // 491
	claimers[0x46F269eaa51081E94c9f125734845c3DF1e60C55] = 1; // 490
	claimers[0xA51f6fD2b777b69dFCFF66184989a03aDe0A0F6e] = 1; // 42
	claimers[0x9f993647Ef8d2779D0119dB1EB5Db3c9fbebD7A9] = 1; // 483
	claimers[0x42dB72DD43758eE47123BE5824efDb593E916888] = 1; // 43
	claimers[0x5bb3e01c8dDCE82AF3f6e76f46d8965176A2daEe] = 1; // 479
	claimers[0xAb4582c3e0815308a0F6d4AEf9d5dd7a8E5Cb8f8] = 1; // 44
	claimers[0xa75e5f016502E93d1e917a6ba3bB9C0505611a9A] = 1; // 38
	claimers[0xF517c71629d54b366003caCf776A2760a7D882A7] = 1; // 372
	claimers[0xBC99c4BD93c24Db1Bf553F2c7F9348be639fe5B6] = 1; // 7
	claimers[0xddA1b324EA03E00C4f982FfC6660059abAD5d557] = 1; // 47
	claimers[0xf6C55D31480DAF896B843E4E57981a4413B31883] = 1; // 49
	claimers[0xdE0D35cbb92e5fA393663d62F09b54805C1F22c9] = 1; // 438
	claimers[0xC8c8436cb67Db1c17E00C465a098e49fA2E9563F] = 1; // 436
	claimers[0xE9d5704D68B98E122aa6CF9C76DF8c1C4CAbE6Fc] = 1; // 50
	claimers[0x8E97AE3878cac64f2395758c5DFd5EC0014F3691] = 1; // 51
	claimers[0xDa60FCB3bcDf2DFC3bc6Ad834e39766e41AFfb07] = 1; // 430
	claimers[0xE6e7bf8d5785882295D311bdE277aB9c3717E079] = 1; // 52
	claimers[0x16984947A9DF713BD940b2CAEEf32C42950b5006] = 1; // 426
	claimers[0x2D234804F7Bfa491DEDDf87f7b96633126858F8F] = 1; // 15
	claimers[0xdcedfd717EAC6f6ac1cb585b4b5ceFD9a80366Ec] = 1; // 370
	claimers[0xace1CBA951bd93DF58fC043011C9A02B24e766e2] = 1; // 371
	claimers[0xd612ed448e90027cC27a7Fd70045899C2f7BA395] = 1; // 32
	claimers[0x010594cA1B98ffEd9dFE3d15b749f8BaE3F21C1B] = 1; // 317
	claimers[0xf2FF0E3d2673F924e98d6598f4F1DbE914e7ceBa] = 1; // 20
	claimers[0x3CCAD6b51B2c68F3eE5640Dbd3366a1ad739b4cD] = 1; // 312
	claimers[0x2a4EE310F91863e5345E9ee3f4e97C3AeF910882] = 1; // 311
	claimers[0xFA6b6756d2CB986fC49375E1440898c1a7b0CB95] = 1; // 21
	claimers[0x7C22107E32213e0702eE83f27238FFF43955199f] = 1; // 308
	claimers[0xFc85c3A8e8bCF16feb4136B4ee92917DF6F35Cf9] = 1; // 307
	claimers[0x6f8d29c94c7b196C5E53137EE97be32D3136B413] = 1; // 22
	claimers[0x01E04479DB63d47dF5354ECf83815BB5927296e0] = 1; // 291
	claimers[0x07587c046d4d4BD97C2d64EDBfAB1c1fE28A10E5] = 1; // 135
	claimers[0xF2c578B1aDa582A7a8882920245673b1e0CddAA1] = 1; // 283
	claimers[0x3D6f6043fFC09AD396535CdFAcb6e4bC47668e02] = 1; // 18
	claimers[0xAf06E9d60f4057EEB49289d905CF8Af13122A2AB] = 1; // 31
	claimers[0x3af46de2aCc78D4d4902a87618d28C0B194d7e63] = 1; // 280
	claimers[0x6592aB22faD2d91c01cCB4429F11022E2595C401] = 1; // 276
	claimers[0x2cda4759594fF9999CEbFD03B3F168265F2cb12E] = 1; // 255
	claimers[0x786110D49af1e8Ff5066A7dc64528656dF7A66dA] = 1; // 254
	claimers[0x6F11E78B1871BDc5c6724134CBA9a952B822A7e5] = 1; // 24
	claimers[0x339396b58CeB4D10b5196a0986d21E260EB94Cc6] = 1; // 25
	claimers[0x0090DdE383865bC21a72639313975CDB67D2D612] = 1; // 26
	claimers[0x79F320b0b657BfBB20a619600e1Fda721026EB1c] = 1; // 27
	claimers[0xa542e3CDd21841CcBcCA70017101eb6a2fc68723] = 1; // 163
	claimers[0x214CFA8e58F89c8c4429Ff5a7B623184d06d1a53] = 1; // 318
	claimers[0x31A750069A7aF08cA127995B06d33566f927DFE0] = 1; // 17
	claimers[0xb47c36bC19D227bE55C7Ad6837BdB4090eae35BB] = 1; // 28
	claimers[0xc16dCEF2f6F407cda72863C3481e1bE6158f46A2] = 1; // 60
	claimers[0xA6E53C8b49B74be4a37151D7f6275B8E9B7E1779] = 1; // 369
	claimers[0x31d837A6f6F5e940a0678dBab3849347FB035d97] = 1; // 368
	claimers[0x910D381F63389eE86F4Db7c1C0E4f8a290DB186a] = 1; // 367
	claimers[0x4eb0af6DA44fe0f6b7B370a72CDF1E3919985d94] = 1; // 366
	claimers[0x82Fd5b51EE922220Ba489b3aB34189be8082361B] = 1; // 365
	claimers[0x8209a9DCb4E848bf242c09ADc847B8e1123136f6] = 1; // 363
	claimers[0x1B3Ed87aE5C638D5527af101542A6Ab2b9Cf00e6] = 1; // 59
	claimers[0x8B52e53D2F9E0cB51954E66d57A047c6FEbaFf34] = 1; // 359
	claimers[0x238a9a4C25BE812113D5AD7469e385997a4cc526] = 1; // 358
	claimers[0x66E6Aeaa1458F71B1D17EA9781EAf4cD6537d26F] = 1; // 357
	claimers[0x8637576EbDF8b8cb96de6a32C99cb8bDa61d2A11] = 1; // 61
	claimers[0x8BF484D5f691bb13A320aae0F6A1325118c45569] = 1; // 328
	claimers[0xE0D2508F57503CdE11AcE344743995Cd4973E0F5] = 1; // 37
	claimers[0xC877d757680529971fc83440739864cf2a307aCc] = 1; // 345
	claimers[0x6c4Cd639a31C658549824559ECC2d04BED1a9ab9] = 1; // 344
	claimers[0x3a844ee6957afb881cc1e2e8BEC79087391BB640] = 1; // 343
	claimers[0xfbbdB682949Fb616ad5Fb7b030505Cc7d4fe688B] = 1; // 40
	claimers[0x19dE5455ad629FD540a8DB37706C92aa797A324d] = 1; // 35
	claimers[0x4BB9E9F84B3d63b592CEa6188c82975548B9C1A3] = 1; // 339
	claimers[0x8EBba7B3cfa1e1391d44CDBD4C5EB6fe9440eb89] = 1; // 337
	claimers[0x3A874840130a10372865F392954AA65A7500dCe5] = 1; // 34
	claimers[0xCA755A9bD26148F18B4D2e316966E9fE915d46aC] = 1; // 132
	claimers[0xC46170F2b86C1e87E043b220221886bF65683831] = 1; // 33
	claimers[0x7d30209018e854730D783dcBe8e94e508adAbbc4] = 1; // 342
	*/
	}


	// Start: Admin functions
	event adminModify(string txt, address addr);
	modifier onlyAdmin() 
	{
		require(IsAdmin(_msgSender()), "Access for Admin's only");
		_;
	}

	function IsAdmin(address account) public virtual view returns (bool)
	{
		return hasRole(DEFAULT_ADMIN_ROLE, account);
	}
	function AdminAdd(address account) public virtual onlyAdmin
	{
		require(!IsAdmin(account),'Account already ADMIN');
		grantRole(DEFAULT_ADMIN_ROLE, account);
		emit adminModify('Admin added',account);
	}
	function AdminDel(address account) public virtual onlyAdmin
	{
		require(IsAdmin(account),'Account not ADMIN');
		require(_msgSender()!=account,'You can`t remove yourself');
		revokeRole(DEFAULT_ADMIN_ROLE, account);
		emit adminModify('Admin deleted',account);
	}
	// End: Admin functions

	function TokenAmountSet(uint amount)public virtual onlyAdmin
	{
		Amount = amount;
	}

	function TokenAddrSet(address addr)public virtual onlyAdmin
	{
		TokenAddr = addr;
	}

	function ClaimCheckEnable(address addr)public view returns(bool)
	{
		uint256 val;
		IERC721 ierc20Token = IERC721(FatmenContract);
		val = ierc20Token.balanceOf(addr);
		bool status = false;
		if(val > 0)status = true;
		return status;
	}
	function ClaimCheckAmount(address addr)public view returns(uint)
	{
		uint value;
		uint256 val;
		IERC721 ierc20Token = IERC721(FatmenContract);
		val = ierc20Token.balanceOf(addr);

		value = DafForFatmen.mul(val);
		return value;
	}
	function Claim(address addr)public virtual
	{
		//address addr;
		//addr = _msgSender();
		require(TokenAddr != 0x0000000000000000000000000000000000000000,"Admin not set TokenAddr");

		bool status;
//		if(claimers[addr] > 0)status = true;
		status = ClaimCheckEnable(addr);

		require(status,"Token has already been requested or Wallet is not in the whitelist");
		uint256 SendAmount;
		SendAmount = ClaimCheckAmount(addr);
		if(Sended[addr] > 0)SendAmount = SendAmount.sub(Sended[addr]);
		Sended[addr] = SendAmount;
		claimers[addr] = 0;

		IERC20 ierc20Token = IERC20(TokenAddr);
		require(SendAmount <= ierc20Token.balanceOf(address(this)),"Not enough tokens to receive");
		ierc20Token.safeTransfer(addr, SendAmount);

		ClaimCount++;
		emit textLog(addr,SendAmount,claimers[addr]);
	}
	
	function AdminGetCoin(uint256 amount) public onlyAdmin
	{
		payable(_msgSender()).transfer(amount);
	}

	function AdminGetToken(address tokenAddress, uint256 amount) public onlyAdmin 
	{
		IERC20 ierc20Token = IERC20(tokenAddress);
		ierc20Token.safeTransfer(_msgSender(), amount);
	}
	function MetaiBalance()public view returns(uint256)
	{
	        IERC20 ierc20Token = IERC20(TokenAddr);
	        return ierc20Token.balanceOf(address(this));
	}

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

import "../token/ERC20/extensions/IERC20Metadata.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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