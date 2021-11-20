/**
 *Submitted for verification at FtmScan.com on 2021-11-19
*/

pragma solidity ^0.8.6;

interface I{
	function transfer(address to, uint value) external returns(bool);
	function balanceOf(address) external view returns(uint);
	function genesisBlock() external view returns(uint);
}

contract Treasury {
	address private _governance;

	struct Beneficiary {
		uint128 amount;
		uint128 emission;
		uint lastClaim;
	}

	mapping (address => Beneficiary) public bens;
	struct Poster {
		uint128 amount;
		uint128 lastClaim;
	}

	mapping (address => Poster) public posters;
	struct AirdropRecepient {
		uint128 amount;
		uint128 lastClaim;
	}

	mapping (address => AirdropRecepient) public airdrops;
	
	struct Refund {
	    uint128 amount;
	    uint128 lastClaim;
	    uint emission;
	}
	mapping (address => Refund) public refunds;
	
	address private _oracle;
	address private _letToken;
	address private _founding;
	uint public totalPosters;
	uint public totalAirdrops;
	uint public totalRefundsEmission;
	uint public totBenEmission;
	uint public epochBlock;

	function init() public {
		_governance=0x5C8403A2617aca5C86946E32E14148776E37f72A;
		//_letToken =0x7DA2331C522D4EDFAf545d2F5eF61406D9d637A9;
		//_founding =0xAE6ba0D4c93E529e273c8eD48484EA39129AaEdc;
		
		//GENESIS POSTERS:
		//poster address                                                                    //rewards address
		//this one combines first 6 periods
	/*0x7624286abCC6844820a865985B812e1491C27eB9,0x590F71c02F34c712725D21EC489B9A49a5744618*/	addAirdrop(0x298016db488516E9FdB860E12424366f47E3Df2a,8409276891862e9);//1355445099002e9+4763008208587e9+2290823484273e9
	/*0xb2b969406c7B5CD78F38F886546E03b29732c868,0xCA62CEB6b303CcaE7e93DBFAD9b2C5226ECBcD9a*/	addAirdrop(0x5C8403A2617aca5C86946E32E14148776E37f72A,9973652395879e9);//4578569433e9+9748217040355e9+220856786091e9
	/*0xb22a07aa77B86A480d9A1e58115e2f51454A57Ce,0xb95c6E794B24f6d6eaA711f1a56970EFb1Cf28f4*/	addAirdrop(0xb22a07aa77B86A480d9A1e58115e2f51454A57Ce,2942054105290e9);//1659912275574e9+693508225838e9+588633603878e9
	/*0xA7cfC2C4821e61738a3cd78ECD519E125811c22d,0x37EaE1f5C83d9d762823D679b927740bf2CBB1f3*/	addAirdrop(0xCd148Bc79B0E415161d9d6Df1BFB2DF545B509DA,971636504326e9);//509886791340e9+683763199e9+461065949787e9
	/*0x1429c66c47BC802AE3A7DF0C572f7b8F3763bC68*/	addAirdrop(0xb8824771aF976B78A75af75746860ae5B4Bb8d21,4354120598847e9);
	/*0x712092Da547D45535935f25F31eA77dbDcaAF0C9*/	addAirdrop(0xA2543A9A96Cc4b35B4dCEb8AA85450fA1884D96F,1186385207e10);
	/*0x8c5a463EE76F337B768CAbB00331aF5F435DfDBE*/	addAirdrop(0x6890a4813DCE1769a068F8616c696D106c632eb2,15423007691e10);
	/*0x93Eb0bdd70030A93086a22Cbdfae5B50EB9BA35C*/	addAirdrop(0xc693A445BA97F2c46Adf33f122d25ee47510bf47,2707934055083e9);
	/*0xcedABfd6CC2EE45218E01b16Fb11B3e80c29f3d6*/	addAirdrop(0xe161fb51737770d1908235683d479c2DAfbC3aF8,8839870288e9);
	/*0x14c811580D8cea36a3217FE1e458CeeAa4E85d7c*/	addAirdrop(0xca4ed1a1f03345a24bAa6D39E8886f99Aca7Bf59,10677466863e9);
	/*0xb400aaa2Ec0068a42CFC95B63Fee82B7106DB945*/	addAirdrop(0xAA5a65D14df735b3bc39f9e639847160402a40eD,51736798994e9);
	/*0x1575Cfad1210043020CF960de07FDFeB0f37374d*/	addAirdrop(0xc660215CDcDEbA3Ca2d016f47C1B6890314Da6AF,65786360224e9);
	/*0x0e332b84DdDB17F5cE436254bD72949C96dB573A*/	addAirdrop(0x18FE7625B6B0dd30bEaAfFDEEA63F386bE84Ab76,111520209458e9);
	/*0x1A6A64EC952935cE597a20D89Ed1155472239920*/	addAirdrop(0x0a2Cce3b5caa3A505e69A36e140FfdAC90b93A8d,1182405602245e9);
	/*0xD9ED523eA4A620521110761262101b3Db6c1C7B9*/	addAirdrop(0xa8aA887c2480A5095A0984aB6c8b038866f429cf,4539166729113e9);//4225307291525e9+313859437588e9
	/*0x480f8676dE082A30E990bCA70b9a96584b78Bb03*/	addAirdrop(0xC5757Cb3A85E67C5dc6648B9520B970a6b2e23A5,677251634281e9);
	/*0x1b910114ac08aBD123625DeA2485BF1B2EA2D6F0*/	addAirdrop(0xCeCe87a0Cc16Ed7a41Ffd9D74158ED06E74Bf041,8304696449e10);
	/*0x2529D7333B0840867A86FC1891eedc991b8A0744*/	addAirdrop(0x9900749C03B45970Be0365d8084F95CD17C5D580,3954534393434e9);
	/*0xa94c1dF74D251A52F2F0969dB35Dd6ED02D79163*/	addAirdrop(0x09E5A998b548eaAfd4346933d1C8231576740EEa,2372770414e10);
	/*0xA6559801FE3Dd11dB5e09BDAa74663bd5830c67d*/	addAirdrop(0xCAd88b9aA4bdEE0333707A88b8D4DDaD1bd1688a,30690330354e9);
	/*0x1a76C2CEB00e41e9308960E837325E357E8DAf46*/	addAirdrop(0x438Bd153F138a45751576ecA0960eB0155a54ac2,41589363588e9);
	/*0x26bB046B581Fb0C926cF37B9Ba8184C4c42049BE*/	addAirdrop(0xA4fbe3b21D0eF250E7781B2d9440dAF4fEbD6E7C,129431472998e9);
	/*0xB9C29Fb11fd9b17294D224C14330d9eAFC55D7F6*/	addAirdrop(0x56228eCE4Ed037B739F89e157AF5393F27C7217a,322024735262e9);
	/*0x85970790F2f25217f159dE74648fD34Fae90f952*/	addAirdrop(0xc95EB2A57ed8B1ae2093cA8Fa95E35a222DCF396,307395770522e9);
	/*0x651934252d730A373022a00DDacC86d46974A2Dc*/	addAirdrop(0x579759B2D158cacc3483d7916E56B8AE8441192c,261056386199e10);
	/*0x0D444402c072a3c903f62F83DB090b4B70017983*/	addAirdrop(0xA90e227E8D9BdC3811Fdfe1D074A7663232bA1C1,204247509266e9);
	/*0x6F4b03e8884B02Ac1698842a12C3fcB0Ba27A413*/	addAirdrop(0x1feC87F1B172fF535C7b680F07E052BA5B946d5f,98033705286e9);
	/*0xd3b4dC7e5ff0420DeaD3d29088eA79615Ac73bf6*/	addAirdrop(0xA6E23236b01B67c96784098e25566804c9D190b5,366463696192e9);//328193399965e9+38270296227e9
	/*0xc1446C4804e35175CF823Bb4C24083B8694ce2C6*/	addAirdrop(0xbDecBB867b37908B4B216FC5bd164aeD5DefBa78,246838514749e9);
	/*0x66939EC5fDf8DC8906998ef0b10c35a7DE5F5CB6*/	addAirdrop(0x63FEeB2fe03100692ca05D2caA9E03c79e033d2c,2735052795e10);
	/*0xA7993e5e6A76D597Ae4014DBbc6070215E6a32C5*/	addAirdrop(0xB733bE65e4E15c8b074945Cf8d86fafD3A5e39C7,60986989751e9);
	/*0xF27B5f220410E8eA10aFA05D4951bA3F5d581218*/	addAirdrop(0xCd35Bd176364e553D0f7BDc21C88aEC21F3d3ec9,683763199e9);
	/*0x219d1484CC5Fd8C4f227320f306c935415F0F0c6*/	addAirdrop(0xB021a13Bbc3eeA6B2988F5BfF773a55c4845eB2B,793084572588e9);//384868079496e9+408216493092e9
	/*0x0FFFAa813b8840bEaDCaC70108c65F1e412fbF0A*/	addAirdrop(0xbB18b2aD3082Dc8E1c18fD5438fFb3E7ef5Af2D6,3418815994e9);
	/*0x2eA08727073011B9EFDEBa3fBdA13b200FC47571*/	addAirdrop(0x5CEbA48722A6549235a009Dc45aBB31ae065Db58,85812281443e9);
	/*0xa1Da338c757F58a71c8388Cf3322ad2f1e04aebE*/	addAirdrop(0x9d6718f99bF4e292f9037c7221F71fb295d0a1cE,6837631988e9);
	/*0xad0d8CFc84187e13d1ebD669973773412E53c88A*/	addAirdrop(0xa9aA6A7B2e9A7C2ad628E096C5EFa148a6754F89,6837631988e9);
	/*0xde2DCA33BA591dD7124d693c6ea1fCEDA7340A9a*/	addAirdrop(0x0783462Aec2C07Ffb26ff222b56CeFA56CFDD8b9,3418815994e9);
	/*0x0e61824d96ae257Ad5697c2A02D49198417d4251*/	addAirdrop(0xC20B282d6d26a05DDD2FFD26c643459246520889,12572288306e10);
	/*0xC20B282d6d26a05DDD2FFD26c643459246520889*/	addAirdrop(0xC20B282d6d26a05DDD2FFD26c643459246520889,799453229e10);
	/*0xff6160Ce01F6B7c85e8aD577659C88de44633024*/	addAirdrop(0x481D26A19e7014acFbF30491Fd54b004D7D05109,899025626350e9);//363241479166e9+535784147184e9
	/*0x882f165c1bD1dD3c13Aa2c29E4BAa7CDBEEc2C71*/	addAirdrop(0xA8FA8CefeEa10Dd5EfbE020C479aC18Df8aB9A4D,125381557715e9);//23327434442e9+102054123273e9
	
	//IF YOU SEE THAT YOUR REWARDS ADDRESS IS SET INCORRECTLY OR YOUR ADDRESS IS MISSING, DO NOT HESITATE TO REACH OUT
	/*0xA27a4FE9a98Def35CCa53A04fc24192f55D63d52*/	addAirdrop(0xA27a4FE9a98Def35CCa53A04fc24192f55D63d52,13050237277e10);
	/*0xD1c4D9487a29302531E4358A631368AA9c6b580d*/	addAirdrop(0xD1c4D9487a29302531E4358A631368AA9c6b580d,9491081656e9);
	/*0x43F04314eC5e18Be5D1708717EC5C7c78e2dD5Fc*/	addAirdrop(0x43F04314eC5e18Be5D1708717EC5C7c78e2dD5Fc,249140893471e9);
	/*0x9CbFBc68B8938032E07564084A88b1da1E27a95a*/	addAirdrop(0x9CbFBc68B8938032E07564084A88b1da1E27a95a,1186385207e10);
	/*0x8afE8Ef93D3d2b5DF49c07465f6FF23d1Dce9b86*/	addAirdrop(0x8afE8Ef93D3d2b5DF49c07465f6FF23d1Dce9b86,17795778105e9);
	/*0xB0ffEdF10fEeE57Ec4e89aA3fA149059010f8164*/	addAirdrop(0xB0ffEdF10fEeE57Ec4e89aA3fA149059010f8164,136434298805e9);
	/*0xC51bCa9db7Cf91F0341143D1d51FDE645ca1b383*/	addAirdrop(0xC51bCa9db7Cf91F0341143D1d51FDE645ca1b383,10703476785e9);
	/*0x3e16541ecADB2D8B5b3480FdE2823baF39EE2303*/	addAirdrop(0x3e16541ecADB2D8B5b3480FdE2823baF39EE2303,90979552668e9);
	/*0x444053c2a9f4FE79869ada8fd403DE1835983aF3*/	addAirdrop(0x444053c2a9f4FE79869ada8fd403DE1835983aF3,10703476785e9);
	/*0x302e9d4ee70f5393dff11d3bc87dB58034Db0F95*/	addAirdrop(0x302e9d4ee70f5393dff11d3bc87dB58034Db0F95,153426778881e9);
	/*0x65A9bf405184c71445Ce166Ee0c6f6599032c944*/	addAirdrop(0x65A9bf405184c71445Ce166Ee0c6f6599032c944,16055215177e9);
	/*0x7158287A38a9528Df52d7171189dA80a0604d834*/	addAirdrop(0x7158287A38a9528Df52d7171189dA80a0604d834,341881599e9);
	/*0xCfe64Ad9595C8E23D1161945d5088b68B85f3138*/	addAirdrop(0xCfe64Ad9595C8E23D1161945d5088b68B85f3138,1006465190904e9);
	/*0xaeEafd0383Ada3ef89E79c606Fc551eaa88f1361*/	addAirdrop(0xaeEafd0383Ada3ef89E79c606Fc551eaa88f1361,84961007842e9);//80004092284e9+4956914558e9
	/*0x1fd22bB198000743af6C97c4eB64bcEAd0678576*/	addAirdrop(0x1fd22bB198000743af6C97c4eB64bcEAd0678576,41915086344e9);
	/*0xC7d46CB56F732354819624556Fb4Ae1905DCAc13*/	addAirdrop(0xC7d46CB56F732354819624556Fb4Ae1905DCAc13,47140257455e9);
	/*0xA6D8416548ac7A49ABC1FE4f69037BdEd89f7b92*/	addAirdrop(0xA6D8416548ac7A49ABC1FE4f69037BdEd89f7b92,61961431987e9);
	/*0x543af6FF1c1195e56bdB91B4422A1bbd0dC4A945*/	addAirdrop(0x543af6FF1c1195e56bdB91B4422A1bbd0dC4A945,44539335228e9);

//added without arrays, so the code is representative
//Fantom
//first one:
    addAirdrop(0x76b60dCf71dA2294f8aA034432D925D1eED8cf68,25e18);
    addAirdrop(0x6718EB204A15601BCE38b6695816D6206F8207AB,260e18);
    addAirdrop(0x4B254c5F0014487fB6DB637835a123667cc6e08b,2500e18);
    addAirdrop(0x679B4172E1698579d562D1d8b4774968305b80b2,500e18);
    addAirdrop(0xa25e3A5F8268538c3726CcEc9624056973b71d2F,2500e18);
    addAirdrop(0xEC2e79b2df2fF15Bf74dC6FD2dbA4eEd348Aa677,200e18);
    addAirdrop(0x3a2Fe85E391D75ed31133A6b91D1AA1a7BF47D79,50e18);
    addAirdrop(0x62581E22530F7D4Af5bbAAA62e5364d8B44F9A84,50e18);
    addAirdrop(0xe5936d9De1527832d39d05F9F9f7EC88cc2755Ed,500e18);
    addAirdrop(0xe5936d9De1527832d39d05F9F9f7EC88cc2755Ed,5e18);
    addAirdrop(0xC0D35857e87F5ADe6055714706fb4dFD96DE087E,5e18);
    addAirdrop(0x2D8e1Ef6B2b5F6Bae1D47aa61c3BE3Bf413A34C3,100e18);
    addAirdrop(0x5C8403A2617aca5C86946E32E14148776E37f72A,5e18);
    addAirdrop(0x1f3236F64Cb6878F164e3A281c2a9393e19A6D00,250e18);
    addAirdrop(0x08539431F4d59a02D0347588F6fBdb7d69aAd2c3,5000e18);
    addAirdrop(0xd517970724351D1c3A676D45B79634DDe2a2899b,250e18);
    addAirdrop(0x9253ced0fdFb7BD4E505CD5E2a5C8712F3251d69,50e18);
    addAirdrop(0xC04d40CCD06f85Efd7A760a85D7aA42355DB00D5,50e18);
    addAirdrop(0xB7DC6A421bE69A53F1A6db51808bD3080e54aDfB,1250e18);
    addAirdrop(0x79be773e584954205b6533708c2f33ae5827b790,50e18);
    addAirdrop(0xc6C8AeCb1d9cA59A09d691cDa8539992655dbfB3,3000e18);
    addAirdrop(0x6e32a45cce1e03Fc13D49E73DdC329dB99A1364a,5e18);
    addAirdrop(0x9b090761223bF884AE902C66C0373e5920F567Aa,250e18);
    addAirdrop(0x57a99f34721418E3c4A054E0F7356a1bC712b8e9,50e18);
    addAirdrop(0x1e62A12D4981e428D3F4F28DF261fdCB2CE743Da,5000e18);
    addAirdrop(0x1F2bC22E55fBD7853A49421C8e038d1f2025dC3c,2500e18);
    addAirdrop(0xffC4C7896526105338742f74f91667D94199C1E8,10e18);
    addAirdrop(0x185269516c6a37af244B94bE962C9B33A3Cbd52B,200e18);
    addAirdrop(0x0A5aec13f9cF73d848f6B03E4F7Ee6D888cD924e,5000e18);
    addAirdrop(0x61edd22e98c32ccf986CBf406297423D95bD3cA3,1250e18);
//second one:
//manual migration
	addAirdrop(0x62172b838724a9Ad965F278f1d2438BB2Ab20ea2,50e18);
	addAirdrop(0xb83C10E1a1a713f60Ce847528D44F66aCC767f05,250e18);
	addAirdrop(0x1924eb636F5b7949656BB3a089ea7715849bd724,1035e18);
	addAirdrop(0xd517970724351D1c3A676D45B79634DDe2a2899b,50e18);
	addAirdrop(0x91ddEb35264287785762e666B5fba5Da9E83b5C8,50e18);
	addAirdrop(0x61edd22e98c32ccf986CBf406297423D95bD3cA3,385e18);
	addAirdrop(0xA8FA8CefeEa10Dd5EfbE020C479aC18Df8aB9A4D,225e17);
	addAirdrop(0x39E24A5024b44a9350cc43f7e1bf59427ba79B87,100e18);
	addAirdrop(0x49d8b33c50e0fA7fcDF78C5bd0c1B01238390E4d,5e18);
	addAirdrop(0x0a5B57FbaC6e432c01555edD74deCC232b174d07,5e18);
	addAirdrop(0x0a5B57FbaC6e432c01555edD74deCC232b174d07,1898e17);
	addAirdrop(0xabCa5C6C22C69e27D1C7Cc3b8Cbd2E7D9bBB3666,5e18);
	addAirdrop(0xa8b5dD12e943a1AC67F17E3d1273e9B02beF8483,250e18);
	addAirdrop(0xA407496f8eFBE5aC9baA834f833084dc3d2cB14d,2970e18);
	addAirdrop(0x707A29e6593406E6444C4A465f535aD44962cEf6,2000e18);
	addAirdrop(0x298016db488516E9FdB860E12424366f47E3Df2a,2500e18);
	addAirdrop(0x13E5C4425502c2a0De10Fe0eA16b5Ec74C504c5d,15e18);
	addAirdrop(0x5C8403A2617aca5C86946E32E14148776E37f72A,1250e18);
	addAirdrop(0x13E5C4425502c2a0De10Fe0eA16b5Ec74C504c5d,135e18);
//contributions
	addAirdrop(0x7E13b262daB598Dd9d4e11a5Bc61c3097aF73088,1500e18);
	addAirdrop(0xffC4C7896526105338742f74f91667D94199C1E8,50e18);
	addAirdrop(0xbECc7a18CA0718939dd2Bf03D49F38ed7D91AbCE,50e18);
	addAirdrop(0x5C8403A2617aca5C86946E32E14148776E37f72A,500e18);
	addAirdrop(0x73A74B1E90C8301813379d7b77a2cfbD90D8B277,5000e18);
	addAirdrop(0x54fd4Fcaa9e47580FFB7F937633F84166ab4E5DA,5e18);
	addAirdrop(0xC04d40CCD06f85Efd7A760a85D7aA42355DB00D5,75e18);
	addAirdrop(0xBFd271EcC7a54f0950f7021E3A0A81a39bF7434a,1125e17);
	addAirdrop(0x5C8403A2617aca5C86946E32E14148776E37f72A,250e18);
	addAirdrop(0xBFd271EcC7a54f0950f7021E3A0A81a39bF7434a,150e18);
	addAirdrop(0xBFd271EcC7a54f0950f7021E3A0A81a39bF7434a,500e18);
	addAirdrop(0x25eC428481C715f54C9c4219605Fb4DF446850E2,50e18);
	addAirdrop(0x13E5C4425502c2a0De10Fe0eA16b5Ec74C504c5d,60e18);
	addAirdrop(0x8f1bF7072f3772509f863c659A9d5e2Fb0a56971,5e16);
	addAirdrop(0x8976b2FDE745D8857D7b953D9C85F011094A1838,50e18);
	addAirdrop(0x8976b2FDE745D8857D7b953D9C85F011094A1838,100e18);
	addAirdrop(0xe61d4CfB4e0C97fE896064849917Ffd867a1DBFA,5e18);
	addAirdrop(0x5C8403A2617aca5C86946E32E14148776E37f72A,150e18);
	addAirdrop(0x3c1acE375b585d21382AD64cdDA174283b96A8EC,540e18);
	addAirdrop(0xf9bA2F51Def499979Bfdb66996ac19DE956B3F0D,5e18);
	addAirdrop(0x8592d6527DA473d4686Dd84805E6e94DD5Da2609,2500e18);
	addAirdrop(0xbDF3a518341F8DC49f14c644665Fa35034DA41Fa,75e17);
	addAirdrop(0x42c1905bbE243cc125Cc7426381309748091F250,100e18);
	addAirdrop(0x1d8B28a0Fdb71De81280E6a254707c4006476428,5e17);
	addAirdrop(0x12F0da4056A8d22a0F605cDF80d6771adb0e79Cc,5e18);
	addAirdrop(0xf077eC872d3cA323Ae3aEf0F53Fbe36cdd8924A8,369913e15);
	addAirdrop(0x89778fDB388A0CC83b19B51F0b50E78100540B43,2500e18);
	addAirdrop(0xBFd271EcC7a54f0950f7021E3A0A81a39bF7434a,250e18);
	addAirdrop(0xBFd271EcC7a54f0950f7021E3A0A81a39bF7434a,200e18);
	addAirdrop(0x5C8403A2617aca5C86946E32E14148776E37f72A,250e18);

//95% withdrawals missing other 5%
	addAirdrop(0xAf2B13bdF7071208071F083572205b53776e445E,125e17);
	addAirdrop(0xA8FA8CefeEa10Dd5EfbE020C479aC18Df8aB9A4D,1e17);
	addAirdrop(0x19495E77e394077e45820AaA589283aF2C6A84eE,225e17);


//ETHEREUM
//Ethereum ratio 1 ether = 1000 fantom
    addAirdrop(0xbCB28129b40105b1B38eB1F4e759c358Be892D19,1190e18);
    addAirdrop(0x298016db488516E9FdB860E12424366f47E3Df2a,50e18);
    addAirdrop(0x119840f12E9D21F1c37097e3f65d3Cc1AC084646,15000e18);
    addAirdrop(0x3F73Ea32dcD34a0B5CDc16EAF9b95bf3b3C8F44a,700e18);
    addAirdrop(0x56228eCE4Ed037B739F89e157AF5393F27C7217a,1250e18);
    addAirdrop(0x9E0dffC8134BC73cE08Cce55259774674B701C2b,250e18);
    addAirdrop(0xb44FC936577C8929541C52C76e1d642E7B393EA4,1315e18);
    addAirdrop(0xAb769309EbCEEDa984E666ab727b36211bA02A8a,100e18);
    addAirdrop(0x19c41f73416d68590e953868505F4bb8239Cefb5,425e18);
    addAirdrop(0xBf26925f736E90E1715ce4E04cD9c289dD1bc002,5000e18);
    addAirdrop(0x1Fd92A677e862fCcE9CFeF75ABAD79DF18B88d51,500e18);
    addAirdrop(0xB6d3aa0B6D3b47BE1736F277eCBc7e03A6fB91d7,50e18);
    addAirdrop(0xD5e4a02aF646B5466Ab9984d49890ED30d4d47Eb,100e18);
    addAirdrop(0x0e979995e1dFB7546904E087c712DA6dd117F066,500e18);
    addAirdrop(0x3b7c23B91eAad19aF4f085C99E36bBaaf8E66741,200e18);

//dev fund
	addBen(0x5C8403A2617aca5C86946E32E14148776E37f72A,1e23,0,7e22);
	//addBen(0xD6980B8f28d0b6Fa89b7476841E341c57508a3F6,1e23,0,1e22);//change addy
	//addBen(0x1Fd92A677e862fCcE9CFeF75ABAD79DF18B88d51,1e23,0,5e21);// change addy
	}

	function genesis(uint block) public {
		require(msg.sender == 0xAE6ba0D4c93E529e273c8eD48484EA39129AaEdc);
		epochBlock = block;
	}

	function setGov(address a)external{
		require(msg.sender==_governance);
		_governance=a;
	}

	function setOracle(address a)external{
		require(msg.sender==_governance);
		_oracle=a;
	}

	function _getRate() internal view returns(uint){
		uint rate = 31e14;
		uint quarter = block.number/28e6;
		if (quarter>0) {
			for (uint i=0;i<quarter;i++) {
				rate=rate*4/5;
			}
		}
		return rate;
	}

// ADD
	function addBen(address a, uint amount, uint lastClaim, uint emission) public {
		require(msg.sender == _governance && bens[a].amount == 0 && totBenEmission <=1e23);
		if(lastClaim < block.number) {
			lastClaim = block.number;
		}
		uint lc = bens[a].lastClaim;
		if (lc == 0) {
			bens[a].lastClaim = uint64(lastClaim);
		}
		if (bens[a].amount == 0 && lc != 0) {
			bens[a].lastClaim = uint64(lastClaim);
		}
		bens[a].amount = uint128(amount);
		bens[a].emission = uint128(emission);
		totBenEmission+=emission;
	}

	function addAirdropBulk(address[] memory r,uint[] memory amounts) external {
		require(msg.sender == _governance);
		for(uint i = 0;i<r.length;i++) {
			uint prevA = airdrops[r[i]].amount;
			airdrops[r[i]].amount += uint128(amounts[i]);
			if(prevA<1e20&&airdrops[r[i]].amount>=1e20){
				totalAirdrops+=1;
			}
			if(airdrops[r[i]].lastClaim==0){
				airdrops[r[i]].lastClaim=uint128(block.number);
			}
		}
	}

	function addAirdrop(address r,uint amount) public {
		require(msg.sender == _governance);
		uint prevA = airdrops[r].amount;
		airdrops[r].amount += uint128(amount);
		if(prevA<1e20&&airdrops[r].amount>=1e20){
			totalAirdrops+=1;
		}
		if(airdrops[r].lastClaim==0){
			airdrops[r].lastClaim=uint128(block.number);
		}
	}

	function addPosters(address[] memory r, uint[] memory amounts) external{
		require(msg.sender == _oracle);
		for(uint i = 0;i<r.length;i++) {
			uint prevA = posters[r[i]].amount;
			posters[r[i]].amount += uint128(amounts[i]);
			if(prevA<1e20&&posters[r[i]].amount>=1e20){
				totalPosters+=1;
			}
			if(posters[r[i]].lastClaim==0){
				posters[r[i]].lastClaim=uint128(block.number);
			}
		}
	}
// CLAIM
	function getRewards(address a,uint amount) external{ //for staking
		require(epochBlock != 0 && msg.sender == 0x0FaCF0D846892a10b1aea9Ee000d7700992B64f8);//staking
		I(0x7DA2331C522D4EDFAf545d2F5eF61406D9d637A9).transfer(a,amount);//token
	}

	function claimBenRewards() external returns(uint){
		uint lastClaim = bens[msg.sender].lastClaim;
		if (lastClaim < epochBlock) {
			lastClaim = epochBlock;
		}
		require(epochBlock != 0 && block.number>lastClaim);
		uint rate = _getRate();
		rate = rate*bens[msg.sender].emission/1e23;
		uint toClaim = (block.number - lastClaim)*rate;
		if(toClaim>bens[msg.sender].amount){
			toClaim=bens[msg.sender].amount;
		}
		if(toClaim>I(0x7DA2331C522D4EDFAf545d2F5eF61406D9d637A9).balanceOf(address(this))){//this check was supposed to be added on protocol upgrade, emission was so slow, that it could not possibly trigger overflow
			toClaim=I(0x7DA2331C522D4EDFAf545d2F5eF61406D9d637A9).balanceOf(address(this));
		}
		bens[msg.sender].lastClaim = uint64(block.number);
		bens[msg.sender].amount -= uint128(toClaim);
		I(0x944B79AD758c86Df6d004A14F2f79B25B40a4229).transfer(msg.sender, toClaim);
		return toClaim;
	}

	function claimAirdrop()external {
		uint lastClaim = airdrops[msg.sender].lastClaim;
		if(epochBlock>lastClaim){
			lastClaim=epochBlock;
		}
		airdrops[msg.sender].lastClaim=uint128(block.number);
		require(airdrops[msg.sender].amount>0&&epochBlock!=0&&block.number>lastClaim);
		uint toClaim;
		if(airdrops[msg.sender].amount>=1e20){
			uint rate =_getRate()*2;
			toClaim = (block.number-lastClaim)*rate/totalAirdrops;
			if(toClaim>airdrops[msg.sender].amount){
				toClaim=airdrops[msg.sender].amount;
			}
			if(toClaim>I(0x7DA2331C522D4EDFAf545d2F5eF61406D9d637A9).balanceOf(address(this))){
				toClaim=I(0x7DA2331C522D4EDFAf545d2F5eF61406D9d637A9).balanceOf(address(this));
			}
			airdrops[msg.sender].amount -= uint128(toClaim);
			if(airdrops[msg.sender].amount<1e20){
				totalAirdrops-=1;
				if(airdrops[msg.sender].amount==0){
					delete airdrops[msg.sender];
				}
			}
		} else {
			toClaim = airdrops[msg.sender].amount;
			delete airdrops[msg.sender];
		}
		I(0x7DA2331C522D4EDFAf545d2F5eF61406D9d637A9).transfer(msg.sender, toClaim);
    }

	function claimPosterRewards()external {
		uint lastClaim = posters[msg.sender].lastClaim;
		if(epochBlock>lastClaim){
			lastClaim=epochBlock;
		}
		posters[msg.sender].lastClaim=uint128(block.number);
		require(posters[msg.sender].amount>0&&epochBlock!=0&&block.number>lastClaim);
		uint rate=31e14;rate*=2;
		uint toClaim =(block.number-lastClaim)*rate/totalPosters;
		if(toClaim>posters[msg.sender].amount){toClaim=posters[msg.sender].amount;}
		if(toClaim>I(0x7DA2331C522D4EDFAf545d2F5eF61406D9d637A9).balanceOf(address(this))){
			toClaim=I(0x7DA2331C522D4EDFAf545d2F5eF61406D9d637A9).balanceOf(address(this));
		}
		posters[msg.sender].amount-=uint128(toClaim);
		I(0x7DA2331C522D4EDFAf545d2F5eF61406D9d637A9).transfer(msg.sender, toClaim);
		if(posters[msg.sender].amount==0){
			totalPosters-=1;
			posters[msg.sender].lastClaim==0;
		}
	}

// IN CASE OF ANY ISSUE
	function removeAirdrops(address[] memory r) external{
		require(msg.sender == _governance);
		for(uint i = 0;i<r.length;i++) {
			if(airdrops[r[i]].amount>=1e20){
				totalAirdrops -=1;
			}
			delete airdrops[r[i]];
		}
	}

	function removePosters(address[] memory r) external{
		require(msg.sender == _oracle);
		for(uint i = 0;i<r.length;i++) {
			if(airdrops[r[i]].amount>=1e20){
				totalPosters -=1;
			}
			delete posters[r[i]];
		}
	}

	function removeBen(address a) public {
		require(msg.sender == _governance);
		totBenEmission-=bens[a].emission;
		delete bens[a];
	}
	
	function removeRefunds(address[] memory r) external{ 
		require(msg.sender == _governance); for(uint i = 0;i<r.length;i++) {
			if(refunds[r[i]].emission>=totalRefundsEmission){refunds[r[i]].emission=totalRefundsEmission;}totalRefundsEmission -= refunds[r[i]].emission; delete refunds[r[i]];
		}
	}
	
	function removeRefund(address a) public{ 
		require(msg.sender == _governance); 
		if(refunds[a].emission>=totalRefundsEmission){refunds[a].emission=totalRefundsEmission;}totalRefundsEmission -= refunds[a].emission; delete refunds[a];
	}
}