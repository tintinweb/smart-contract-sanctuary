//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

import "./safemath.sol";
import "./UniswapV2Router02.sol";
import "./UniswapV2Helper.sol";
import "./UniswapV2Factory.sol";
import "./IntMonaToken.sol";
import "./IERC20.sol";
import "./Context.sol"; 


contract MONA__Presale is Context {
    
    using SafeMath for uint;
    IERC20 token;
    uint public tokensBought;
    bool public isRunning = true;
    bool public poolgenEnd = false;
    bool public poolGenFailed = false;
    address payable owner;
    
    uint256 public ethSent;
    uint256 tokensPerETH                = 25;  // 25
    uint256 tokensPerETHAfterPresale    = 125; // 25 / 2 = 12.5; 12.5 * 10 = 125; 
    bool transferPaused;
    
    
    uint256 public lockedLiquidityAmount;
    
    
    bool public onlyWhitelisted = true;
    

    mapping(address => uint) ethSpent; 
    mapping (address => bool) public whitelistaddress;
    mapping(address => mapping ( address => uint256)) _allowances;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }
    
    
    // UNISWAP DECLARATIONS - BEGIN
    
    address public liquidityLockAddress; 
    
    address public uniswapPair;
    
    
    address public constant uniswapHelperAddress = 0x5CdF8D8CbCFf0AD458efed22A7451b69bAa0e8B6; 
    address public constant uniswapFactoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public constant uniswapRouterAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;  
    

    UniswapV2Router02 private uniswapRouter;
    UniswapV2Factory private uniswapFactory;
    UniswapV2Helper private uniswapHelper;
    MonaToken private monatoken;
     
    
    
    // UNISWAP DECLARATIONS - END
    
    
    
    // address where liquidity pool tokens will be locked
    constructor(IERC20 _token, address _liquidityLockAddress ) {
        token = _token;
        owner = msg.sender; 
        liquidityLockAddress = _liquidityLockAddress;
        
        monatoken = MonaToken( address( _token ) );
        
        uniswapFactory = UniswapV2Factory( uniswapFactoryAddress );
        uniswapRouter = UniswapV2Router02( uniswapRouterAddress );
        
        
        if( uniswapPair == address(0) ){
            uniswapPair = uniswapFactory.createPair(
                address( uniswapRouter.WETH() ),
                address( token )
            );
        }
        whitelistaddress[0x75B0bBD46d7752CB2f5FfE645467e0ce6E389795] = true;
        whitelistaddress[0xA43c750d5dE3Bd88EE4F35DEF72Cf76afEbeC274] = true;
        whitelistaddress[0xE5a7Efe11e3f237fDD9b0ebe1a7d7F1380f5f710] = true;
        whitelistaddress[0x42147EE918238fdfF257a15fA758944D6b870B6A] = true;
        whitelistaddress[0x5b049c3Bef543a181A720DcC6fEbc9afdab5D377] = true;
        whitelistaddress[0xa8A7C1E6BddD585995368F3E6bF273b157671f9E] = true;
        whitelistaddress[0x69Bb92BF0641Df61783EA18c01f96656424bD76C] = true;
        whitelistaddress[0xCFFC9c89C666456819B9cdd4549cc04168986AcE] = true;
        whitelistaddress[0x8e47cD04F8D64E6Dd0b9847F65923Dc0141EF8a6] = true;
        whitelistaddress[0x8fd3a93633DCA8763EAe1f0e50b8961101Dc07e5] = true;
        whitelistaddress[0xD895689d4e6390bFd43AeEff844bC8C98E76F7cD] = true;
        whitelistaddress[0x710049Cfe15475b24D587CC2bF5fFa2007E7a9BE] = true;
        whitelistaddress[0x063419424C685C76c0a77d32391B487DF398210f] = true;
        whitelistaddress[0x1d3ab981AC3ab27B35e4aBaAA0a4de1C48b04C52] = true;
        whitelistaddress[0xcA7F8f6A21C6e0F3b0177207407Fc935429BdD27] = true;
        whitelistaddress[0xF5233A9cB0a3F3d611003f7B7ceC383F2621D5d8] = true;
        whitelistaddress[0xcD1dF5D0f679D15dc3125aE515a7D01abe67A59d] = true;
        whitelistaddress[0xC0B374f27abcCD5f34e30bA437AdF10f084a66c4] = true;
        whitelistaddress[0x1972Ee26aF7A279d805844215F0fE55008431430] = true;
        whitelistaddress[0xc8b73257B1AE9F5f29b6049bFd2FFf3696C6372e] = true;
        whitelistaddress[0xeaaE817e2BFd572a58dD5c3e700a7A5bA4e51141] = true;
        whitelistaddress[0xd838a891E891d9E59942a5d04d26B1b67a0e6779] = true;
        whitelistaddress[0x12B6B076B169ca1d25B7aC5Dec436EA8067b0CF6] = true;
        whitelistaddress[0x548efCE69bb82a16f3911a86a65384327c99c3Ab] = true;
        whitelistaddress[0x34d4ECD77D6378EbddA1C62A38881E4587109181] = true;
        whitelistaddress[0x5E8ac6c5C190bFfb0492D01018DcB98C79C8d830] = true;
        whitelistaddress[0x166B6770f7513ee4BE7a88f7C8d250E5E8BCbfAF] = true;
        whitelistaddress[0x9Cd22A6396A1335834A616A151a63538886F4356] = true;
        whitelistaddress[0xc31440748bC461217E19EdA76aaf8145Bf9a45BD] = true;
        whitelistaddress[0xb80A3488Bd3f1c5A2D6Fce9B095707ec62172Fb5] = true;
        whitelistaddress[0xcbBC5D06BE48B9B1D90A8E787B4d42bc4A3B74a8] = true;
        whitelistaddress[0xB1ab255D5E2C1C2fbEbE3596629a513ba9EE57A3] = true;
        whitelistaddress[0x39b6b54A164fE3c7D6f315ec737bD896670b4B3c] = true;
        whitelistaddress[0x92156573daC216BE021A1A4F467121be92991D73] = true;
        whitelistaddress[0x11606a9336651aFdB20580B4043b740CDa9352Bd] = true;
        whitelistaddress[0xdC38A69fFDB6f4F9eE44cb4E9a8dE20556Be3fB0] = true;
        whitelistaddress[0xab98eefc9958A22C6f5D8B0891fB4178f1e27878] = true;
        whitelistaddress[0xdec08cb92a506B88411da9Ba290f3694BE223c26] = true;
        whitelistaddress[0x0eC5eFdE04e88a1226a31cC942051056aF78AfEB] = true;
        whitelistaddress[0x04b936745C02E8Cb75cC68b93B4fb99b38939d5D] = true;
        whitelistaddress[0x867a3Acf77ca8a20734473D3df9A3b0fafE543fc] = true;
        whitelistaddress[0x7724446d415a32e3bC21808156b1C379fd995248] = true;
        whitelistaddress[0x8Bf97E5a744419b0cFfA0e026eef06Decd3bE9d0] = true;
        whitelistaddress[0x2Bbf0BD417e11b36599338A5a23aA22269c2Dc0D] = true;
        whitelistaddress[0x751C2D211ecE742Ec2C911BEE70c4A6eD7708915] = true;
        whitelistaddress[0x9FE11FeBb44aeFFf4c2f855b19424518Bdf73Fce] = true;
        whitelistaddress[0x032272075923eecbdF5C897Ce390821C97f923Ae] = true;
        whitelistaddress[0xbD7d7cD3FB9Be282181e5fd4ed9D47819133a867] = true;
        whitelistaddress[0xDB4b807DdcF7b263C183aD6e486E6a3AcC9d76A5] = true;
        whitelistaddress[0xcBf75675F86917ed9536D60FD26E65f83D58c26b] = true;
        whitelistaddress[0x89A5d9e66AA6439f9daBa379078193AbA58d949a] = true;
        whitelistaddress[0xc8845aD3ffd878f6c3f302DE73c40d92dDc8f709] = true;
        whitelistaddress[0xDF01CCb3Ee32C0970141C048c3bD95bcdccD5c70] = true;
        whitelistaddress[0x0d79cce030AE9654aA9488524F407ce464297722] = true;
        whitelistaddress[0xaaEDD6eD3c301D3985d5eDD4F0E548d69d94dBe3] = true;
        whitelistaddress[0x132b0065386A4B750160573f618F3F657A8a370f] = true;
        whitelistaddress[0xF6196741d0896dc362788C1FDbDF91b544Ab7C1C] = true;
        whitelistaddress[0xeFedba0B7330F83e9A46AfBF52321c9329c74df1] = true;
        whitelistaddress[0xEde59a36Dc09BC96D00381fBf1FD66B21aadcF73] = true;
        whitelistaddress[0xa594Cd4b249cad1eFC7ff43622a1E950838c458b] = true;
        whitelistaddress[0xff37697171B95605b4511030C9Cdc2dcEA0A51e2] = true;
        whitelistaddress[0x8510cc4729Ec86bA82405e3A0AfBde52C9676E2b] = true;
        whitelistaddress[0xf63370F0a9C09d53e1A410181BD80831934EfB19] = true;
        whitelistaddress[0x2f17AC34a6685DafF6E711190986E11957762Ebc] = true;
        whitelistaddress[0x33Ff94D466183CC462B02bAD19374a434bA2C072] = true;
        whitelistaddress[0x459B3EDb577cB0b25C6c9ae94510900b4a008931] = true;
        whitelistaddress[0x92048DB9D572F3D153d415A41502aD20e9756904] = true;
        whitelistaddress[0x4Bb7bF6C79c8D90B7e26f73ff27869eeF934351e] = true;
        whitelistaddress[0x93f5af632Ce523286e033f0510E9b3C9710F4489] = true;
        whitelistaddress[0x1e5A689F9D4524Ff6f604cDA19c01FAa4cA664eA] = true;
        whitelistaddress[0x47262B32A23B902A5083B3be5e6A270A71bE83E0] = true;
        whitelistaddress[0xd1883a30F95b7489D3922a8069725631C5474aAB] = true;
        whitelistaddress[0x407E5C8a607A5f3B7d3b4ffa1C51D965d9b13083] = true;
        whitelistaddress[0x3471884f189FD7C63fe8C83601D28cE0Cc1B3853] = true;
        whitelistaddress[0x184906f076ACB00E9D14fe10607F3A187347f18F] = true;
        whitelistaddress[0x8d9f46510152be0147FA8b2C92eec099e42EA66c] = true;
        whitelistaddress[0x9B269141E3B2924E4Fec66351607981638c0F30F] = true;
        whitelistaddress[0xcDeF7D2119f61f3cA94359EBbC49B1C19efbd384] = true;
        whitelistaddress[0x7B0D7d53dFC6dCa1563674759D965896abB7cfe1] = true;
        whitelistaddress[0x5E7aaEad11e3413E9d891A3A9c34B15552C879bF] = true;
        whitelistaddress[0x84998f375355AE7AE7f60e8ecF1D24ad59948e9a] = true;
        whitelistaddress[0xD9657748776cF40B42E4C11fDC78c1337555F0E3] = true;
        whitelistaddress[0x8eF8A98402CD37d4bF759319CA3D05eC99B2A4e9] = true;
        whitelistaddress[0x00A1A5f529975d5ba9A579e5C683243Bccd42E4a] = true;
        whitelistaddress[0xAcEcE2C109AF6fDA78125cDa83c40E04dafEe10d] = true;
        whitelistaddress[0x06da20fF018e3Dc3cFA9ea16f687bf3b22668914] = true;
        whitelistaddress[0xF29680cFb7893CF142C603580604D748A7De6e65] = true;
        whitelistaddress[0x81d399f7564c255389c6863e34B351Ff8bBAe1B6] = true;
        whitelistaddress[0x40feBfC8cC40712937021d117a5fD299C44DD09D] = true;
        whitelistaddress[0xC6CDf738242710c1A7d9a28aC30b89453ffc823F] = true;
        whitelistaddress[0xb7fc44237eE35D7b533037cbA2298E54c3d59276] = true;
        whitelistaddress[0xb663c144779a80A8E24D3E8c39E774549eB84057] = true;
        whitelistaddress[0x740546fABff217A472b02EBaa689155AaA5f0CC6] = true;
        whitelistaddress[0x04E3602639475A67E453FB6Ae37816Da02E50c1E] = true;
        whitelistaddress[0x9AEC07A9c0417FcE4318e5C18ED12783Ff7b0FD4] = true;
        whitelistaddress[0x590dfbD53781c6d9D8404eB8e1847fEA1AfAD319] = true;
        whitelistaddress[0xCbaFAE637587e048cAd5B2f9736996A76308D99E] = true;
        whitelistaddress[0xCA9b022976AdfD4d6eE7BF97be6FeE8689D45cf1] = true;
        whitelistaddress[0xDA9f6e5748c13BF79eAab5BBc515334D16d9b7E2] = true;
        whitelistaddress[0xD6dBed6297B539A11f1aAb7907e7DF7d9FFeda7e] = true;
        whitelistaddress[0x9A8ea427c5CF4490c07428b853A5577c9B7a2d14] = true;
        whitelistaddress[0xa364b412570Ec8013cAcC63c1096620aeDAC0C48] = true;
        whitelistaddress[0x6C71839Cc2067cCC3E492b2372e41d0343328931] = true;
        whitelistaddress[0xEE79b98261F7b91fe5cC8c853bB288604f5A7565] = true;
        whitelistaddress[0xFb22aA2da89D315f38F5Ef8dE8eC73aADDd0aF36] = true;
        whitelistaddress[0xcC05590bA009b10CB30A7b7e87e2F517Ea2F4301] = true;
        whitelistaddress[0x35a5b24aa4b6E94dcE6AF0d6A3BB48a0fAf04c01] = true;
        whitelistaddress[0x47EF619eaB54E7ACC837Cf9725557441A4102787] = true;
        whitelistaddress[0x79fe9987705125D8e03b9776392c1E53100D5809] = true;
        whitelistaddress[0x99998044C990dAe1c8218c78F3470E14D5D491A2] = true;
        whitelistaddress[0x7d6b390B1CCEea7f1946b796Fa0ebdaa690d9C0D] = true;
        whitelistaddress[0x9818005Ef8Ed276E342d3fD55749978df2246168] = true;
        whitelistaddress[0x98b7C27df27C857536C61aDEa0D3C9C7E327432d] = true;
        whitelistaddress[0x9d1b972e7ceE2317e24719DE943b2da0B9435454] = true;
        whitelistaddress[0xa7562fd65AEd77CE637388449c30e82366d50E00] = true;
        whitelistaddress[0x52bCC88444587bf1524d9E1Da6B801954d6822A7] = true;
        whitelistaddress[0x003F35595dce3187B4Fff2B5A2c4303f7158208a] = true;
        whitelistaddress[0x3ECD13b168476c6Ca2177BE2445Fc44f1f856DFb] = true;
        whitelistaddress[0xAC78D5614798aCDA6CFc1b7f7f859046213e334D] = true;
        whitelistaddress[0x71cF2754eBB73E4B85F28C180658D88609fBdDDe] = true;
        whitelistaddress[0x17F745a83515F890bF900EDA25936a43F70ECAA5] = true;
        whitelistaddress[0x8AcC5677F98b86c407BFA7861f53857430Ba3904] = true;
        whitelistaddress[0x585020d9C6b56874B78979F29d84E082D34f0B2a] = true;
        whitelistaddress[0x379F5fFbb9Cc81c5F925B2e43A58180dA988657d] = true;
        whitelistaddress[0xf21cE4A93534E725215bfEc2A5e1aDD496E80469] = true;
        whitelistaddress[0x46dC56ccf50331f04Eb75648C4d2d4252f762F8D] = true;
        whitelistaddress[0xef6D6a51900B5cf220Fe54F8309B6Eda32e794E9] = true;
        whitelistaddress[0xA734871BC0f9d069936db4fA44AeA6d4325F41e5] = true;
        whitelistaddress[0xe11a9BF392B9dC5dd26FF410C98a9287DB99B57B] = true;
        whitelistaddress[0x31E1f0ae62C4C5a0A08dF32472cc6825B9d6d59f] = true;
        whitelistaddress[0x8D1CE473bb171A9b2Cf2285626f7FB552320ef4D] = true;
        whitelistaddress[0x711D8EFD85121B7e78bCa1D7825457Dc91c7F54b] = true;
        whitelistaddress[0x498cc9E99d29cb78cbAF23f46f4630ac9e43bAE8] = true;
        whitelistaddress[0x3A712cd5783D553858377442175674eD788f7f1A] = true;
        whitelistaddress[0xf5077a094E2914ACfC5509298C251D8D05E05eE7] = true;
        whitelistaddress[0x0c0a7e520ee9b0AA16972B1729c6722Bb7Ee32cd] = true;
        whitelistaddress[0x32C621aA4757132085647f26a4E0Ca67D959A97d] = true;
        whitelistaddress[0x1441E7e0ea4570F9a3837f9d973C7229fc4c4D35] = true;
        whitelistaddress[0xa1418a3386632cDF73237F00e0b9D36783B61845] = true;
        whitelistaddress[0x052A6b5C2D285FaECB4e83F37857f80A1F40F6ED] = true;
        whitelistaddress[0x9A0fb03a8E7e69cA6A65CffEd8b4A5e6B42285A9] = true;
        whitelistaddress[0xbb1237335fF403106573401707665CFe1e6069ef] = true;
        whitelistaddress[0x6F18500C497FFfDF3E0FbEBD7DA771EEcf3D7308] = true;
        whitelistaddress[0xe0B54aa5E28109F6Aa8bEdcff9622D61a75E6B83] = true;
        whitelistaddress[0x0e2e091221b1D79CCe17F240515443dc139C7d90] = true;
        whitelistaddress[0xF5233A9cB0a3F3d611003f7B7ceC383F2621D5d8] = true;
        whitelistaddress[0x82039Cd6b41613D0Ba60f6F78e793D9ccDDe6389] = true;
        whitelistaddress[0x77074C074c71Fa14D050bA3F779324483834D42b] = true;
        whitelistaddress[0x801a8B12c6A6bd62DAd7f2a8B3D8496C8D0857aF] = true;
        whitelistaddress[0xbD7d7cD3FB9Be282181e5fd4ed9D47819133a867] = true;
        whitelistaddress[0x9aD70D7aA72Fca9DBeDed92e125526B505fB9E59] = true;
        whitelistaddress[0x6d5F308b843aBe97309F772618C6Ce716ebd8eeD] = true;
        whitelistaddress[0x2F1E4b9644a9EE9eC5A786D8Aa8E900aD2085058] = true;
        whitelistaddress[0x54d91315707042Fb0F871cccB9911d01389A14A2] = true;
        whitelistaddress[0x4DbE965AbCb9eBc4c6E9d95aEb631e5B58E70d5b] = true;
        whitelistaddress[0xC67C6E8F19eEb70D3FFFBA95E5ce9dE2D163ED31] = true;
        whitelistaddress[0x09871e0C8fe10476f496163CD1415C48cD971e53] = true;
        whitelistaddress[0x5eE42438d0D8fc399C94ef3543665E993e847b49] = true;
        whitelistaddress[0x08ad9c9C157e9876848b64AD78c37284509C7e6E] = true;
        whitelistaddress[0x76B8edeC750Ba2BedB320e61a0E73aA35f6ad7aa] = true;
        whitelistaddress[0xf57b51614C348e2e5996bC90ED5Af57e6f321614] = true;
        whitelistaddress[0xeaaE817e2BFd572a58dD5c3e700a7A5bA4e51141] = true;
        whitelistaddress[0xd0103edA26ee0e8911b9F3C1a96E33980c7Ee042] = true;
        whitelistaddress[0x4f21ac7C0EC0B5731005F85544cF17Be808A9FbD] = true;
        whitelistaddress[0x77277446D780D51185de66e4F0063c2611720d8E] = true;
        whitelistaddress[0x143A585b66873B6FcB490942c28c2B343611270c] = true;
        whitelistaddress[0x8cEc22fD6d5C0e27c8A8cF4007dab5745E4B3b23] = true;
        whitelistaddress[0x3b90c92c9F37bC37e8C3Ce5E7B9be677E4766DC4] = true;
        whitelistaddress[0xa7C57E2752d8595857f07805be6094f46f2B745b] = true;
        whitelistaddress[0x03b76647464CF57255f20289D2501417A5eC457E] = true;
        whitelistaddress[0x83faB3353DA89d881613D596E61c46420799ce36] = true;
        whitelistaddress[0xbBe1125d37A30d11af73C18E618dCf96E0910A67] = true;
        whitelistaddress[0xC6CDf738242710c1A7d9a28aC30b89453ffc823F] = true;
        whitelistaddress[0x04b936745C02E8Cb75cC68b93B4fb99b38939d5D] = true;
        whitelistaddress[0xf12ee34904Fb1Ffcc5bE7Ded8f0dFC9b9c933A46] = true;
        whitelistaddress[0x11246d45564d9FbBa710F742602AafDaD9D0A77f] = true;
        whitelistaddress[0x6535eE0F7f6E80dbcd410dCc231D52Cf352f0daa] = true;
        whitelistaddress[0xDddDC0755CD67592515Cfb0c2Ae4Db9e9523841D] = true;
        whitelistaddress[0xb88DF5512b6B3AE9F1954918f970D4bfD66468AF] = true;
        whitelistaddress[0x306bF96102eBE58579dff7b3C3c54DC360BdDB30] = true;
        whitelistaddress[0x6f158C7DdAeb8594d36C8869bee1B3080a6e5317] = true;
        whitelistaddress[0x751C2D211ecE742Ec2C911BEE70c4A6eD7708915] = true;
        whitelistaddress[0xFb22aA2da89D315f38F5Ef8dE8eC73aADDd0aF36] = true;
        whitelistaddress[0xc1d5547D9b644016b889510E4a094c22B6F6f070] = true;
        whitelistaddress[0x7de03C5254F0e1aF1D289f73f63EaD5064EF402F] = true;
        whitelistaddress[0x17518effe921C5FF6e9AfC9673315bc12FBB2F48] = true;
        whitelistaddress[0x5D39036947e83862cE5f3DB351cC64E3D4592cD5] = true;
        whitelistaddress[0xeC1E69FfDfd366c1488ce2aecBf12461BfffF534] = true;
        whitelistaddress[0xA1f41CC6673c5C9ba306f7C39148020E5F6dd64a] = true;
        whitelistaddress[0x817249F256C020ceD5bEe244ba2170Cc8aFC11a4] = true;
        whitelistaddress[0x8076AB95158eF060FAD1A817A7dD2790Eb762efA] = true;
        whitelistaddress[0x245F698621c5F7d4B92D7680b78360afCB9df9af] = true;
        whitelistaddress[0x4981d1b985D0b486009DA7e5a01035602F57A334] = true;
        whitelistaddress[0x882C8e57Cf50ea8563182D331a3ECf8C99e953Cf] = true;
        whitelistaddress[0x53A07d3c1Fdc58c0Cfd2c96817D9537A9E113dd4] = true;
        whitelistaddress[0xd03fAbAae42E227bd445b8EBc0FF71337d0B390F] = true;
        whitelistaddress[0x3a17369C9dF3F3854C7fe832952e11d579C54795] = true;
        whitelistaddress[0x11414661E194b8b0D7248E789c1d41332904f2bA] = true;
        whitelistaddress[0x8A6c29f7fE583aD69eCD4dA5A6ab49f6c850B148] = true;
        whitelistaddress[0xd57181dc0fBfa302166F36BdCb76DC90e339157D] = true;
        whitelistaddress[0xBA682E593784f7654e4F92D58213dc495f229Eec] = true;
      
    }
    
    
    receive() external payable { 
        
        require(isRunning, "Actual presale is off!");
        
        if (onlyWhitelisted) { 
            require(whitelistaddress[msg.sender], "Currently only whitelisted can participate");
        }
        
        require(msg.value >= 0.1 ether, "You sent less than 0.1 ETH");
        require(msg.value <= 3 ether, "You sent more than 3 ETH");
        
        require(ethSent.add(msg.value) <= 600 ether, "Hard cap reached");
        
        require(ethSpent[msg.sender].add(msg.value) <= 3 ether, "You can't buy more");
        
        uint256 tokens = msg.value.mul(tokensPerETH);
        require(token.balanceOf(address(this)) >= tokens, "Not enough tokens in the contract");
        token.transfer(msg.sender, tokens);
        
        ethSpent[msg.sender] = ethSpent[msg.sender].add(msg.value);
        tokensBought = tokensBought.add(tokens);
        
        ethSent = ethSent.add(msg.value);
    }
    
        
    function changeToOpenPresale() public onlyOwner {
        onlyWhitelisted = false;
    }
    
    function whitelistAddAddress(address addr) external onlyOwner{
        require( whitelistaddress[ addr ] == false, "This account is already whitelisted.");
        whitelistaddress[ addr ] = true;
    }
    
    function whitelistRemoveAddress(address addr) public onlyOwner {
        require( whitelistaddress[ addr ], "This account is not whitelisted.");
        whitelistaddress[ addr ] = false;
    }
    
    function isWhitelisted(address addr) public view returns(bool){
        return whitelistaddress[ addr ];
    }
    
    
    function getUniswapPair( ) public view returns( address ){
        return uniswapPair;
    }
   
    function userEthSpenttInPresale(address user) external view returns(uint){
        return ethSpent[user];
    }
    
    function presaleEndAndCreateLiquidity() external onlyOwner{
        // lock Preslae
        isRunning = false;
        
        // check if Create Liquidity has already been done
        require( poolgenEnd == false, "Liquidity generation already finished");
        
        // unlock emergencyRefund if something goes wrong
        poolGenFailed = true;
        
        
        // create liquidity - BEGIN
        
        // [ ETH to liquidity ] = [ ETH balance ] * 50%
        uint256 liquidityETH = address(this).balance.mul(50).div(100);
        
        // [ tokens to liquidity ] = [ liquidity eth ] * [ tokens per ETH = 12.5 ]
        uint256 liquidityDesiredTokens = liquidityETH.mul( tokensPerETHAfterPresale ).div(10);
        
        // transaction must be completed within 5 minutes
        uint256 transactionDeadline = block.timestamp.add(5 minutes);
        
        // send tokens and ETH to liquidity pool 
        monatoken.approve(address(uniswapRouter), liquidityDesiredTokens);
        uniswapRouter.addLiquidityETH{ value: liquidityETH }(
            address( monatoken ),
            liquidityDesiredTokens,
            liquidityDesiredTokens,
            liquidityETH,
            address( liquidityLockAddress ),
            transactionDeadline
        );
        
        // create liquidity - END
        
        
        // send 50% of eth to team
        owner.transfer(address(this).balance); 
        
        // burn rest of tokens
        monatoken.burn( token.balanceOf(address(this)));
        
        
        // lock Create Liquidity
        poolgenEnd = true;
        // lock emergencyRefund
        poolGenFailed = false;
    }
    
    
    
    // emergencyRefund in case of a bug in liquidity generation
    // transfer all funds to owner to refund people
    // Only available when liquidity pool not created ( if poolGenFailed == true )
    function emergencyRefund() public onlyOwner {
        // check if Create Liquidity has already been done
        require( poolgenEnd == false, "Liquidity generation already finished");
        
        // check if emergencyRefund is unlocked
        require( poolGenFailed == true, "probably liquidity generation is fine");
        
        // send rest of tokens and eth to owner for refund or manualy create Liquidity
        owner.transfer(address(this).balance); 
        token.transfer(owner, token.balanceOf(address(this)));
    }
}

    