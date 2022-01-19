// SPDX-License-Identifier: MIT
/* ======================================================== DEFI HUNTERS DAO ==========================================================================
                                                       https://defihuntersdao.club/
------------------------------------------------------------ January 2021 -----------------------------------------------------------------------------
#######       #######          ####         #####             ####      ###   #######     #######       #######        #####      #######   
##########    ##########      ######      #########          ######     ###   #########   ##########    #########    #########    ######### 
###########   ###########     ######     ###########         ######     ###   ##########  ###########   ##########  ###########   ##########
###    ####   ###    ####     ######    ####     ####        ######     ###   ###   ####  ###    ####   ###   #### ####     ####  ###   #### 
###     ####  ###     ####   ########   ####     ####       ########    ###   ###   ####  ###     ####  ###   #### ####     ####  ###   ####
###     ####  ###     ####   ###  ###   ###       ###       ###  ###    ###   #########   ###     ####  #########  ###       ###  ######### 
###     ####  ###     ####  ##########  ###       ###      ##########   ###   ########    ###     ####  ########   ###       ###  ########  
###     ####  ###     ####  ##########  ####     ####      ##########   ###   ###  ####   ###     ####  ###  ####  ####     ####  #####      
###    ####   ###    ####  ############ #####   #####     ############  ###   ###   ####  ###    ####   ###   #### #####   #####  ###        
##########    ##########   ####    ####  ###########      ####    ####  ###   ###   ####  ##########    ###   ####  ###########   ###        
#########     #########    ###     ####   #########       ###     ####  ###   ###   ####  #########     ###   ####   #########    ###        
==================================================================================================================================================== */
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract DDAOclaim is AccessControl
{
	using SafeMath for uint256;
	using SafeERC20 for IERC20;
	IERC20 public token;

	address public owner = _msgSender();
	mapping (address => uint256) claimers;
	mapping (address => uint256) public Sended;

	// testnet
	address public TokenAddr = 0xcf17001DcFE45Ac926B886C76D8b937c852c8B23;
	// mainnet
	//address public TokenAddr = 0xca1931c970ca8c225a3401bb472b52c46bba8382;

	uint8 public ClaimCount;
	uint256 public ClaimedAmount;

	event textLog(address,uint256,uint256);

	constructor() 
	{
	_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
                claimers[0xf18210B928bc3CD75966329429131a7fD6D1b667] = 50 * 10**18; // 1
                claimers[0x611b3f03fc28Eb165279eADeaB258388D125e8BC] = 50 * 10**18; // 2
                claimers[0x0130F60bFe7EA24027eBa9894Dd4dAb331885209] = 50 * 10**18; // 3
                claimers[0xFD9346bB6be8088a16632BE05c21536e697Cd514] = 50 * 10**18; // 4
                claimers[0x852dBe4212563946dfb82788fC0Ab1649b719EA7] = 50 * 10**18; // 5
                claimers[0xecCE210948363F54034b53FCEeA8BeE420b2Dad6] = 50 * 10**18; // 6
                claimers[0x46728c3ed31C5588D5a5989Ad7f3143eB37F90D1] = 50 * 10**18; // 7
                claimers[0x23D623D3C6F334f55EF0DDF14FF0e05f1c88A76F] = 50 * 10**18; // 8
                claimers[0x9b2D76f2E5E92b2C78C6e2ce07c6f86B95091964] = 50 * 10**18; // 9
                claimers[0xdCCd89bC40cD81A2a2c8631907174CA8aac6Bb6F] = 50 * 10**18; // 10
                claimers[0x7F052861bf21f5208e7C0e30C9056a79E8314bA9] = 50 * 10**18; // 11
                claimers[0xDcEEF35A4c1221C4F39f9eaA270e3C46f64701c8] = 50 * 10**18; // 12
                claimers[0x68D546Bc9ea85dA2027B318c8dC045b05547B60B] = 50 * 10**18; // 13
                claimers[0xb6B05931FA328D0622Ddfcca882f9366A0072372] = 50 * 10**18; // 14
                claimers[0xbb8b593aE36FaDFE56c20A054Bc095DFCcd000Ec] = 50 * 10**18; // 15
                claimers[0xd2C8CC3DcB9C79A4F85Bcad9EF4e0ccf4619d690] = 50 * 10**18; // 16
                claimers[0xBB5913bb6FA84f02ce78fFEEb9e7D43e3D075b16] = 50 * 10**18; // 17
                claimers[0x50648FB34E1A5B9b9D11F0E5B3b268f1Eacaa7bB] = 50 * 10**18; // 18
                claimers[0x5bb3e01c8dDCE82AF3f6e76f46d8965176A2daEe] = 50 * 10**18; // 19
                claimers[0xf8a5Ef9803787cAdE641D6F8767e660dC1951319] = 50 * 10**18; // 20
                claimers[0x3f6e6029E95cE74E0c286B7da173EBE7ebA72caf] = 50 * 10**18; // 21
                claimers[0x4Ae6155789d8D8CDA7bFaC23d9D5AdD2253d3171] = 50 * 10**18; // 22
                claimers[0x2aE024C5EE8dA720b9A51F50D53a291aca37dEb1] = 50 * 10**18; // 23
                claimers[0x73073A915f8a582B061091368486fECA640552BA] = 50 * 10**18; // 24
                claimers[0x8B9d3F19DF766D39Ac1C781509D18411EF8dB493] = 50 * 10**18; // 25
                claimers[0xd1cBd75d6217637655fc16c6321C967Db5AeDa4e] = 50 * 10**18; // 26
                claimers[0x44e02B37c29d3689d95Df1C87e6153CC7e2609AA] = 50 * 10**18; // 27
                claimers[0x266EEC4B2968fd655C362B1D1c5a9269caD4aA42] = 50 * 10**18; // 28
                claimers[0x61889b6da417A0467206756c7a980B3d0568DC3a] = 50 * 10**18; // 29
                claimers[0x43E70CB1B70d06439b8FBaD9f2de91508D73105d] = 50 * 10**18; // 30
                claimers[0x687922176D1BbcBcdC295E121BcCaA45A1f40fCd] = 50 * 10**18; // 31
                claimers[0xcCf70d7637AEbF9D0fa22e542Ac4082569f4ED5A] = 50 * 10**18; // 32
                claimers[0xDA9b467C311047f2Cc22e7e62120C2c513dB1794] = 50 * 10**18; // 33
                claimers[0x86649d0a9cAf37b51E33b04d89d4BF63dd696fE6] = 50 * 10**18; // 34
                claimers[0xAD5D752f2138a207E3BcD6685470759Fe2f463CD] = 50 * 10**18; // 35
                claimers[0x55d51687E9dE6a670301747A0e1194e46A385d44] = 50 * 10**18; // 36
                claimers[0x0E9F6CdcafA80aF5c97fe6c0e6C750860eb48AE7] = 50 * 10**18; // 37
                claimers[0xDf5B7bE800A5A7A67e887C2f677Cd29a7a05b6E1] = 50 * 10**18; // 38
                claimers[0xbC78fFa671925Fc5c86cA6362B19D47617af9168] = 50 * 10**18; // 39
                claimers[0xd85bCc93d3A3E89303AAaF43c58E624D24160455] = 50 * 10**18; // 40
                claimers[0xF2CA16da81687313AE2d8d3DD122ABEF11e1f68f] = 50 * 10**18; // 41
                claimers[0xD0A5ce6b581AFF1813f4376eF50A155e952218D8] = 50 * 10**18; // 42
                claimers[0xc3297c34F0d82E4C78B62455573A06AFa5F5F48D] = 50 * 10**18; // 43
                claimers[0x3034024f8CE00e21e33A618B301A9A2E7F65aF65] = 50 * 10**18; // 44
                claimers[0x826121D2a47c9D6e71Fd4FED082CECCc8A5381b1] = 50 * 10**18; // 45
                claimers[0x686241b898D7616FF78e22cc45fb07e92A74B7B5] = 50 * 10**18; // 46
                claimers[0xE770748e5781f171a0364fbd013188Bc0b33E72f] = 50 * 10**18; // 47
                claimers[0x6A2e363b31D5fd9556765C8f37C1ddd2Cd480fA3] = 50 * 10**18; // 48
                claimers[0xf10367decc6F0e6A12Aa14E7512AF94a4C791Fd7] = 50 * 10**18; // 49
                claimers[0xb5C2Bc605CfE15d31554C6aD0B6e0844132BE3cb] = 50 * 10**18; // 50
                claimers[0xB6a95916221Abef28339594161cd154Bc650c515] = 50 * 10**18; // 51
                claimers[0x1eC98f3101f5c8e51EE469905348A28d6f3886d1] = 50 * 10**18; // 52
                claimers[0x36bD9BA8C1AAdC49bc4e983C2ACCf0DA90C04019] = 50 * 10**18; // 53
                claimers[0xCE06EDfa8503147888728B2eE92f961B09B7bFfB] = 50 * 10**18; // 54
                claimers[0xe2D18861c892f4eFbaB6b2749e2eDe16aF458A94] = 50 * 10**18; // 55
                claimers[0x07F3813CB3A7302eF49903f112e9543D44170a50] = 50 * 10**18; // 56
                claimers[0x5973FFe2B9608e66A328c87c534e4Bb758618e73] = 50 * 10**18; // 57
                claimers[0xE088efbff6aA52f679F76F33924C61F2D79FF8E2] = 50 * 10**18; // 58
                claimers[0x024713784f675dd28b5CE07dB91a4d47213c2394] = 50 * 10**18; // 59
                claimers[0x94d3B13745c23fB57a9634Db0b6e4f0d8b5a1053] = 50 * 10**18; // 60
                claimers[0xB248B3309e31Ca924449fd2dbe21862E9f1accf5] = 50 * 10**18; // 61
                claimers[0xC5E57C099Ed08c882ea1ddF42AFf653e31Ac40df] = 50 * 10**18; // 62
                claimers[0x6B745dEfEE931Ee790DFe5333446eF454c45D8Cf] = 50 * 10**18; // 63
                claimers[0x125EaE40D9898610C926bb5fcEE9529D9ac885aF] = 50 * 10**18; // 64
                claimers[0xb827857235d4eACc540A79e9813c80E351F0dC06] = 50 * 10**18; // 65
                claimers[0xB67c99dfb3422b61f9E38070f021eaB7B42e9CAF] = 50 * 10**18; // 66
                claimers[0xb20Ce1911054DE1D77E1a66ec402fcB3d06c06c2] = 50 * 10**18; // 67
                claimers[0x572f60c0b887203324149D9C308574BcF2dfaD82] = 50 * 10**18; // 68
                claimers[0x7988E3ae0d19Eff3c8bC567CA0438F6Df3cB2813] = 50 * 10**18; // 69
                claimers[0xe20193B98487c9922C8059F2270682C0BAC9C561] = 50 * 10**18; // 70
                claimers[0xee86f2BAFC7e33EFDD5cf3970e33C361Cb7aDeD9] = 50 * 10**18; // 71
                claimers[0x7Ca612a4D526eB1C5583598fEdA57E938424f0CE] = 50 * 10**18; // 72
                claimers[0x712b4FA81f72532575599bC325bAE39F73AFC0D3] = 50 * 10**18; // 73
                claimers[0xd63613F91a6EFF9f479e052dF2c610108FE48048] = 50 * 10**18; // 74
                claimers[0xB61921297de2b18De6375Ba6fcA640a8dc6e2BDB] = 50 * 10**18; // 75
                claimers[0x37cec7bBFeCbB924Bb54e138312eB82Fee07b05d] = 50 * 10**18; // 76
                claimers[0x77167885E8393f1052A8cE8D5dfF2fF16c08f98d] = 50 * 10**18; // 77
                claimers[0x9E0e571F9EA6756A6910b25D747e46D12D4796e8] = 50 * 10**18; // 78
                claimers[0x0aa05378529F2D1707a0B196B846d7963d677d37] = 50 * 10**18; // 79
                claimers[0xb14ae50038abBd0F5B38b93F4384e4aFE83b9350] = 50 * 10**18; // 80
                claimers[0xbb6D29A522DDb640fc05862D8b129D991555cc4e] = 50 * 10**18; // 81
                claimers[0xB4264E181207E2e701f72331E0998c38e04c8512] = 50 * 10**18; // 82
                claimers[0xD1421ae08b24f5b24fa97980341DAbCADEeD3873] = 50 * 10**18; // 83
                claimers[0xfB89fBaFE753873386D6E46dB066c47d8Ef857Fa] = 50 * 10**18; // 84
                claimers[0x6e55632E9F6e245381e118bEAB75bF73C1D9be2e] = 50 * 10**18; // 85
                claimers[0x0eB4088C1c684Adf431747d4287bdBeAC67fAAbE] = 50 * 10**18; // 86
                claimers[0x1fCAb39c506517d0cc2a12D49eBe5B98f415ed92] = 50 * 10**18; // 87
                claimers[0xEA01E7DFc9B7e1341B02f0421fC61212290BE30E] = 50 * 10**18; // 88
                claimers[0x9E1fDAB0FE4141fe269060f098bc7076d248cE7B] = 50 * 10**18; // 89
                claimers[0x08Bd844e3c92d369eAF74Cc8E799493Fa9BC153c] = 50 * 10**18; // 90
                claimers[0x1326ad1DF89267f2C55Dc8a4cA01388d53763055] = 50 * 10**18; // 91
                claimers[0x8696da95087Cdc22cfea9fdbA3986F5c519571E4] = 50 * 10**18; // 92
                claimers[0x053AA35E51A8Ef8F43fd0d89dd24Ef40a8C91556] = 50 * 10**18; // 93
                claimers[0xF33782f1384a931A3e66650c3741FCC279a838fC] = 50 * 10**18; // 94
                claimers[0x93C927A836bF0CD6f92760ECB05E46A67D8A3FB3] = 50 * 10**18; // 95
                claimers[0xA0f31bF73eD86ab881d6E8f5Ae2E4Ec9E81f04Fc] = 50 * 10**18; // 96
                claimers[0xD54F610d744b64393386a354cf1ADD944cBD42c9] = 50 * 10**18; // 97
                claimers[0x5e0819Db5c0b3952149150310945752ae22745B0] = 50 * 10**18; // 98
                claimers[0x007D02E85c3486A6FDaed4dfCE9742BfDCD818D9] = 50 * 10**18; // 99
                claimers[0x14df5677aa90eC0D64c631621DaD80b44f9DeAFF] = 50 * 10**18; // 100
                claimers[0x15c5F3a14d4492b1a26f4c6557251a6F247a2Dd5] = 50 * 10**18; // 101
                claimers[0xaF792Fe5cC70CD7aDF8f6acBa7776d60bd07688f] = 50 * 10**18; // 102
                claimers[0xfA79F7c2601a4C2A40C80eC10cE0667988B0FC36] = 50 * 10**18; // 103
                claimers[0x61603cD19B067B417284cf9fC94B3ebF5703824a] = 50 * 10**18; // 104
                claimers[0x04b5b1906745FE9E501C10B3191118FA76CD76Ba] = 50 * 10**18; // 105
                claimers[0x58d2c45cEb3f33425D76cbe2f0F61529f1Df9BbF] = 50 * 10**18; // 106
                claimers[0xf295b48AB129A88a9b289C42f251A0EA75561D80] = 50 * 10**18; // 107
                claimers[0xb42FeE033AD3809cf9D1d6C1f922478F1C4A652c] = 50 * 10**18; // 108
                claimers[0xAA504202187c620EeB0B1434695b32a2eE24E043] = 50 * 10**18; // 109
                claimers[0x46f75A3e9702d89E3E269361D9c1e4D2A9779044] = 50 * 10**18; // 110
                claimers[0xE40Cc4De1a57e83AAc249Bb4EF833B766f26e2F2] = 50 * 10**18; // 111
                claimers[0x4D38C1D5f66EA0307be14017deC6A572017aCfE4] = 50 * 10**18; // 112
                claimers[0x4d35B59A3C1F59D5fF94dD7B2b3A1198378c4678] = 50 * 10**18; // 113
                claimers[0x7A4Ad79C4EACe6db85a86a9Fa71EEBD9bbA17Af2] = 50 * 10**18; // 114
                claimers[0x8F1B34eAF577413db89889beecdb61f4cc590aC2] = 50 * 10**18; // 115
                claimers[0x2F48e68D0e507AF5a278130d375AA39f4966E452] = 50 * 10**18; // 116
                claimers[0xC9D15F4E6f1b37CbF0E8068Ff84B5282edEF9707] = 50 * 10**18; // 117
                claimers[0x255F717704da11603063174e5Bc43D7881D28202] = 50 * 10**18; // 118
                claimers[0xC60Eec28b22F3b7A70fCAB10A5a45Bf051a83d2B] = 50 * 10**18; // 119
                claimers[0xae64d3d28b714982bFA990c2130afC92EA9e8bCC] = 50 * 10**18; // 120
                claimers[0xd79c0707083A92234F0ef5FD4Bfba3cd2b7bc81D] = 50 * 10**18; // 121
                claimers[0x2c064Aa8aBe232babf7a32932f7AB7c4E22b3885] = 50 * 10**18; // 122
                claimers[0xbD0Ad704f38AfebbCb4BA891389938D4177A8A92] = 50 * 10**18; // 123
                claimers[0xcB60257f43Db2AE8f743c863d561528EedeaA409] = 50 * 10**18; // 124
                claimers[0x5557A2dFafC875Af4dE5355b3bDd2c115ccc6911] = 50 * 10**18; // 125
                claimers[0x7E18B16467d3b7663fBA4f1F070f968c46d1BDCC] = 50 * 10**18; // 126
                claimers[0x65aeA388b214e9bE7d121B757EA0B2645a74026b] = 50 * 10**18; // 127
                claimers[0x4Dfd842a2C49Bd490a55585cAb0C441e948bD79a] = 50 * 10**18; // 128
                claimers[0x96C7fcC0d3426714Bf62c4B508A0fBADb7A9B692] = 50 * 10**18; // 129
                claimers[0x81cee999e0cf2DA5b420a5c02649C894F69C86bD] = 50 * 10**18; // 130
                claimers[0x87beC71BCE1F7E036eb1E5D969fD5C1887EF43A5] = 50 * 10**18; // 131
                claimers[0xeDf32B8F98D464b9Eb29C74202e6Baae28134fC7] = 50 * 10**18; // 132
                claimers[0xCDE3a031E5a8aC75954557D0DE3A7171A0408104] = 50 * 10**18; // 133
                claimers[0xf1180102846D1b587cD326358Bc1D54fC7441ec3] = 50 * 10**18; // 134
                claimers[0x7Ff698e124d1D14E6d836aF4dA0Ae448c8FfFa6F] = 50 * 10**18; // 135
                claimers[0x80057Cb5B18DEcACF366Ef43b5032440f5C97490] = 50 * 10**18; // 136
                claimers[0x6ACa5d4890CCc8A2d153bF16A9a5b0C5560A62ff] = 50 * 10**18; // 137
                claimers[0x328824B1468f47163787d0Fa40c44a04aaaF4fD9] = 50 * 10**18; // 138
                claimers[0x2F275B5bAb3C35F1070eDF2328CB02080Cd62D7D] = 50 * 10**18; // 139
                claimers[0x2E5F97Ce8b95Ffb5B007DA1dD8fE0399679a6F23] = 50 * 10**18; // 140
                claimers[0x0667b277d3CC7F8e0dc0c2106bD546214dB7B4B7] = 50 * 10**18; // 141
                claimers[0xB2CAE2cE07582FaDEf7B9c2751145Cc16B1206d2] = 50 * 10**18; // 142
                claimers[0x4F80d10339CdA1EDc936e15E7066C1DBbd8Eb01F] = 50 * 10**18; // 143
                claimers[0x3ef7Bf350074EFDE3FD107ce38e652a10a5750f5] = 50 * 10**18; // 144
                claimers[0x871cAEF9d39e05f76A3F6A3Bb7690168f0188925] = 50 * 10**18; // 145
                claimers[0x52539F834eD6801eDB460c31a19CFb33E2572B52] = 50 * 10**18; // 146
                claimers[0x637FB6aeC7933D91Deb2a0094D73D25100Dd5A1B] = 50 * 10**18; // 147
                claimers[0x86d94A6DC215991127c36f9420F30C44b5d8CbaD] = 50 * 10**18; // 148
                claimers[0x3A79caC51e770a84E8Cb5155AAafAA9CaC83F429] = 50 * 10**18; // 149
                claimers[0xD34CAdd64DBb8c4D0cA9cAfCe279E9895e890196] = 50 * 10**18; // 150
                claimers[0x7E004aeF8b4976f52f172e78c8240CFb3fc9d0ca] = 50 * 10**18; // 151
                claimers[0xF93b47482eCB4BB738A640eCbE0280549d83F562] = 50 * 10**18; // 152
                claimers[0xF7f341C7Cf5557536eBADDbe1A55dFf0a4981F51] = 50 * 10**18; // 153
                claimers[0x88D09b28739B6C301be94b76Aab0554bde287D50] = 50 * 10**18; // 154
                claimers[0xC4b1bb0c1c8c29E234F1884b7787c7e14E1bC0a1] = 50 * 10**18; // 155
                claimers[0x2c46bc2F0b73b75248567CA25db6CA83d56dEA65] = 50 * 10**18; // 156
                claimers[0x4460dD70a847481f63e015b689a9E226E8bD5b71] = 50 * 10**18; // 157
                claimers[0x99dcfb0E41BEF20Dc9661905D4ABBD92267095Ee] = 50 * 10**18; // 158
                claimers[0x2E72d671fa07be54ae9671f793895520268eF00E] = 50 * 10**18; // 159
                claimers[0x49e03A6C22602682B3Fbecc5B181F7649b1DB6Ad] = 50 * 10**18; // 160
                claimers[0x6Acb64A76e62D433a9bDCB4eeA8343Be8b3BeF48] = 50 * 10**18; // 161
                claimers[0x6D5888bCA7431F80A1659889658c4a2B1477Edd3] = 50 * 10**18; // 162
                claimers[0x64aF1b02c5C82738f5958c3BC8140BD9662674C6] = 50 * 10**18; // 163
                claimers[0x67C5A03d5769aDEe5fc232f2169aC5bf0bb7f18F] = 50 * 10**18; // 164
                claimers[0x68cf193fFE134aD92C1DB0267d2062D01FEFDD06] = 50 * 10**18; // 165
                claimers[0xD05Da93aEa709abCc31979A63eC50F93c29999C4] = 50 * 10**18; // 166
                claimers[0x2A77484F4cca78a5B3f71c22A50e3A1b8583072D] = 50 * 10**18; // 167
                claimers[0x04bfcB7b6bc81361F14c1E2C7592d712e3b9f456] = 50 * 10**18; // 168
                claimers[0xf93d494D5A3791e0Ceccf45DAECd4A5264667E98] = 50 * 10**18; // 169
                claimers[0x9edC40c89Ba7455148a2b85C3527ed2A4D241aA8] = 50 * 10**18; // 170
                claimers[0xDfB78f8181A5e82e8931b0FAEBe22cC4F94CD788] = 50 * 10**18; // 171
                claimers[0x58bb897f0612235FA7Ae324F9b9718a06A2f6df3] = 50 * 10**18; // 172
                claimers[0xe1C69F432f2Ba9eEb33ab4bDd23BD417cb89886a] = 100 * 10**18; // 173
                claimers[0x49A3f1200730D84551d13FcBC121A6405eDe4D56] = 100 * 10**18; // 174
                claimers[0x79440849d5BA6Df5fb1F45Ff36BE3979F4271fa4] = 100 * 10**18; // 175
                claimers[0xC8ab8461129fEaE84c4aB3929948235106514AdF] = 100 * 10**18; // 176
                claimers[0x28864AF76e73B38e2C9D4e856Ea97F66947961aB] = 100 * 10**18; // 177
                claimers[0xE513dE08500025E9a15E0cb54B232169e5c169BC] = 100 * 10**18; // 178
                claimers[0x1eAc5483377F43b34888CFa050222EF68eeAA52D] = 100 * 10**18; // 179
                claimers[0x7eE33a8939C6e08cfE207519e220456CB770b982] = 100 * 10**18; // 180
                claimers[0x764108BAcf10e30F6f249d17E7612fB9008923F0] = 100 * 10**18; // 181
                claimers[0x2220d8b0539CB4613A5112856a9B192b380be37f] = 100 * 10**18; // 182
                claimers[0xAeC39A38C839A9A3647f599Ba060D3B68C13D95E] = 100 * 10**18; // 183
                claimers[0x24f39151D6d8A9574D1DAC49a44F1263999D0dda] = 100 * 10**18; // 184
                claimers[0x00737ac98C3272Ee47014273431fE189047524e1] = 100 * 10**18; // 185
                claimers[0x237b3c12D93885b65227094092013b2a792e92dd] = 100 * 10**18; // 186
                claimers[0xfE61D830b99E40b3E905CD7EcF4a08DD06fa7F03] = 100 * 10**18; // 187
                claimers[0x7DcE9e613b3583C600255A230497DD77429b0e21] = 100 * 10**18; // 188
                claimers[0xeD08e8D72D35428b28390B7334ebe7F9f7a64822] = 100 * 10**18; // 189
                claimers[0xB83FC0c399e46b69e330f19baEB87B6832Ec890d] = 100 * 10**18; // 190
                claimers[0x3a026dCc53A4bc80b4EdcC155550d444c4e0eBF8] = 100 * 10**18; // 191
                claimers[0x184cfB6915daDb4536D397fEcfA4fD8A18823719] = 100 * 10**18; // 192
                claimers[0x0f5A11bEc9B124e73F51186042f4516F924353e0] = 100 * 10**18; // 193
                claimers[0xa6700EA3f19830e2e8b35363c2978cb9D5630303] = 100 * 10**18; // 194
                claimers[0x3A484fc4E7873Bd79D0B9B05ED6067A549eC9f49] = 100 * 10**18; // 195
                claimers[0x9e0eD477f110cb75453181Cd4261D40Fa7396056] = 100 * 10**18; // 196
                claimers[0xF962e687562999a127a5b5A2ECBE99d0601564Eb] = 100 * 10**18; // 197
                claimers[0x8ad686fB89b2944B083C900ec5dDCd2bB02af1D0] = 200 * 10**18; // 198
                claimers[0x712Ca047e7A31c7049DF72084906A48fEaD2D57A] = 200 * 10**18; // 199
                claimers[0x5f3E1bf780cA86a7fFA3428ce571d4a6D531575D] = 200 * 10**18; // 200
                claimers[0x35E3c412286d59Af71ba5836cE6017E416ACf8BC] = 200 * 10**18; // 201
                claimers[0x44956BBEA170eAf91B49b2DbD13f502c86E6753b] = 200 * 10**18; // 202
                claimers[0xc8e1020c45532FEEA0d65d7C202bc79609e21579] = 200 * 10**18; // 203
                claimers[0x38400B6bBd2B19d7B4a4C3559bcbB0fe1Ef45ec3] = 200 * 10**18; // 204
                claimers[0x5dfCDA39199c47a962e39975C92D91E76d16a335] = 200 * 10**18; // 205
                claimers[0xeBc4006EfD8fCCD9Aa144ee145AB453099266B92] = 200 * 10**18; // 206
                claimers[0x55E9762e2aa135584969DCd6A7d550A0FaadBcd6] = 200 * 10**18; // 207
                claimers[0x0118838575Be097D0e41E666924cd5E267ceF444] = 200 * 10**18; // 208
                claimers[0xEc8c50223E785C3Ff21fd9F9ABafAcfB1e2215FC] = 200 * 10**18; // 209
                claimers[0x0be82Fe1422d6D5cA74fd73A37a6C89636235B25] = 200 * 10**18; // 210
                claimers[0x77724E749eFB937CE0a78e16E1f1ec5979Cba55a] = 200 * 10**18; // 211
                claimers[0xE04DE279a00C1E17a54f7a743355125DDc31D185] = 200 * 10**18; // 212
                claimers[0x99CD484206f19A0341f06228BF501aBfee457b95] = 200 * 10**18; // 213
                claimers[0x76b2e65407e9f24cE944B62DB0c82e4b61850233] = 200 * 10**18; // 214
                claimers[0xc7B5D7057BB3A77d8FFD89D3065Ad14E1E9deD7c] = 200 * 10**18; // 215
		// testers
		claimers[0xF11Ffb4848e8a2E05eAb2cAfb02108277b56d0B7] = 1000000000000000000;
		claimers[0x97299ea1C42b3fA53b805e0E92b1e05500519762] = 1000000000000000000;
		claimers[0x9134408d47239DD81402723B8f0444cf66B82e5D] = 1000000000000000000;
		claimers[0x675162726340338856a8Ff4923930e3A4b1e3Daf] = 1000000000000000000;
		claimers[0xe44b45E38E5Fe6d39c0370E55eB2453E25F7c3C5] = 1000000000000000000;
		claimers[0xa5B32272f2FE16d402Fe6Da4EDfF84cD6f8e4AA0] = 1000000000000000000;
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

	function TokenAddrSet(address addr)public virtual onlyAdmin
	{
		TokenAddr = addr;
	}

	function ClaimCheckEnable(address addr)public view returns(bool)
	{
		bool status = false;
		if(claimers[addr] > 0)status = true;
		return status;
	}
	function ClaimCheckAmount(address addr)public view returns(uint value)
	{
		value = claimers[addr];
	}
	function Claim(address addr)public virtual
	{
		//address addr;
		//addr = _msgSender();
		require(TokenAddr != address(0),"Admin not set TokenAddr");

		bool status = false;
		if(claimers[addr] > 0)status = true;

		require(status,"Token has already been requested or Wallet is not in the whitelist [check: Sended and claimers]");
		uint256 SendAmount;
		SendAmount = ClaimCheckAmount(addr);
		if(Sended[addr] > 0)SendAmount = SendAmount.sub(Sended[addr]);
		Sended[addr] = SendAmount;
		claimers[addr] = 0;

		IERC20 ierc20Token = IERC20(TokenAddr);
		require(SendAmount <= ierc20Token.balanceOf(address(this)),"Not enough tokens to receive");
		ierc20Token.safeTransfer(addr, SendAmount);

		ClaimCount++;
		ClaimedAmount = ClaimedAmount.add(SendAmount);
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
	function balanceOf(address addr)public view returns(uint256 balance)
	{
		balance = claimers[addr];
	}
        function TokenBalance() public view returns(uint256)
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