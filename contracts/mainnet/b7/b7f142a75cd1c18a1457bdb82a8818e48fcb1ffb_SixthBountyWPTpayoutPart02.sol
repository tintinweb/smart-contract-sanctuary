pragma solidity ^0.4.24;

contract Ownable {}
contract AddressesFilterFeature is Ownable {}
contract ERC20Basic {}
contract BasicToken is ERC20Basic {}
contract ERC20 {}
contract StandardToken is ERC20, BasicToken {}
contract MintableToken is AddressesFilterFeature, StandardToken {}

contract Token is MintableToken {
  function mint(address, uint256) public returns (bool);
}

contract SixthBountyWPTpayoutPart02 {
  //storage
  address public owner;
  Token public company_token;
  address[] public addressOfBountyMembers;
  mapping(address => uint256) bountyMembersAmounts;
  uint currentBatch;
  uint addrPerStep;

  //modifiers
  modifier onlyOwner
  {
    require(owner == msg.sender);
    _;
  }
  
  
  //Events
  event Transfer(address indexed to, uint indexed value);
  event OwnerChanged(address indexed owner);


  //constructor
  constructor (Token _company_token) public {
    owner = msg.sender;
    company_token = _company_token;
    currentBatch = 0;
    addrPerStep = 25;
    setBountyAddresses();
    setBountyAmounts();
  }


  /// @dev Fallback function: don&#39;t accept ETH
  function()
    public
    payable
  {
    revert();
  }

  function setCountPerStep(uint _newValue) public onlyOwner {
	addrPerStep = _newValue;
  }

  function setOwner(address _owner) 
    public 
    onlyOwner 
  {
    require(_owner != 0);
    
    owner = _owner;
    emit OwnerChanged(owner);
  }

  
  
  function makePayout() public onlyOwner {
    uint startIndex = currentBatch * addrPerStep;
    uint endIndex = (currentBatch + 1 ) * addrPerStep;
    for (uint i = startIndex; (i < endIndex && i < addressOfBountyMembers.length); i++)
    {
      company_token.mint(addressOfBountyMembers[i], bountyMembersAmounts[addressOfBountyMembers[i]]);
    }
    currentBatch++;
  }

  function setBountyAddresses() internal {
    addressOfBountyMembers.push(0x593699bd16480a398dfc5cbbc455dce627f156cb);
    addressOfBountyMembers.push(0x5B367be9bfD87391aCA778abcA4105A7A8C70616);
    addressOfBountyMembers.push(0x5cad022750b4f37730819c04bccc5aa828b445f6);
    addressOfBountyMembers.push(0x5cC19cfF6D3030303118925576Df83D4AA7A602C);
    addressOfBountyMembers.push(0x5e4B80c8EFF9D6f1eF6B3c46472EFf6A1CAd7fd4);
    addressOfBountyMembers.push(0x5FF1084C4AC881a86AE8CdfFF08FF0a846e56489);
    addressOfBountyMembers.push(0x632de0e68779CEc7E2dc3a336F89Da0618a03fdC);
    addressOfBountyMembers.push(0x63515D455393dDc5F8F321dd084d1bd000545573);
    addressOfBountyMembers.push(0x642c055FF4eDC984216a613a88E22c8f8fa8aB33);
    addressOfBountyMembers.push(0x6621159d53251c145e030ADeDF1B6e10f3E85DdA);
    addressOfBountyMembers.push(0x663942E76762d75d3fA47242A7C9D133005cf7e7);
    addressOfBountyMembers.push(0x66f2A3cf344fD0f4F987C341c774452B753fE684);
    addressOfBountyMembers.push(0x671BDddd4d5696868ccDEec369f69A4D653e81eD);
    addressOfBountyMembers.push(0x675491b1b3f70ee5e7e1a3ae4dd27dc6a8a91425);
    addressOfBountyMembers.push(0x69E56d1E036c74f1F31cdDDEC09D7085D49b2947);
    addressOfBountyMembers.push(0x6ae322828E573f06695Ac0E39490A9bd31B6498F);
    addressOfBountyMembers.push(0x6b72DB853D72B473Bed7AaBddA8ab90BFD4558eB);
    addressOfBountyMembers.push(0x6bfb350FcbE780bA6b18314Df92d886C01d74c6e);
    addressOfBountyMembers.push(0x6C0844F2737bB5986E3c95e89CcC2928bAc4702A);
    addressOfBountyMembers.push(0x6cB67CC2540541AF4633E195e2970956a815e720);
    addressOfBountyMembers.push(0x6Cd5Be6cAe6a37D3500E224117E93369928d51b0);
    addressOfBountyMembers.push(0x6d9fd31D93C7e4B43250e3E3D181c4393ce2cB99);
    addressOfBountyMembers.push(0x6E82fbC3AAAAF22E517842AEfdf957317386C537);
    addressOfBountyMembers.push(0x6e9c261D10575c87fE8724c54ccD26e59F77101a);
    addressOfBountyMembers.push(0x6eA012B7E536E51CF9149609Df775FadEf263b19);
    addressOfBountyMembers.push(0x71f51E7455B26D7C70467Cddfc5153Ca53a58CCb);
    addressOfBountyMembers.push(0x72Bf7B0ef8e2753493B22A1B6492359e432F819B);
    addressOfBountyMembers.push(0x72fF7EB7100cc0AdA5B114E1c78Cab287F44aB30);
    addressOfBountyMembers.push(0x733FF886E1B196e2Bd38829043efFE0971220479);
    addressOfBountyMembers.push(0x77d00c9F51669d5D5615f8902C9c3534c9ED8967);
    addressOfBountyMembers.push(0x78E934eBd3d7Fa0D703eb101baD0261dC0973238);
    addressOfBountyMembers.push(0x791Ab7014A7AD2892a55298CFEdd9A48c7Bc687D);
    addressOfBountyMembers.push(0x793a9F8b936AD8a66e018F6f62be9A235cDb3FfF);
    addressOfBountyMembers.push(0x7A791EFb0749e2B1B5f3EfD5588f04cF21265678);
    addressOfBountyMembers.push(0x7ba18657684d37053f9d84b305785d1c26b0c28d);
    addressOfBountyMembers.push(0x7bD19eBbA137BdFD4a55815AfAD06094030a680A);
    addressOfBountyMembers.push(0x7C2627Ac3c081e2Ac8d3aC2207B329003EddEAC0);
    addressOfBountyMembers.push(0x7ce5E965068c73f9F89e3c8C244666FB5cee3B60);
    addressOfBountyMembers.push(0x7De09DD2Ad9cdFe1143aabFD94106b7C1e4cB8cd);
    addressOfBountyMembers.push(0x7e0d6F45346539E08054B1fC49d03F5e3002d13A);
    addressOfBountyMembers.push(0x7e1F1bD14DCbcCAf268BFd067018812Da4cA4d5F);
    addressOfBountyMembers.push(0x7e5CeBeE3C4bEF1f2aa6ad06C9a9C4A5BfB5A74e);
    addressOfBountyMembers.push(0x7ed9916dd87032e998ced31d435d2971c9ce4e45);
    addressOfBountyMembers.push(0x7f500f8561f8282903f73663c57242b8feaF3572);
    addressOfBountyMembers.push(0x7FBD6d575142959c842BD5D590261F955a86E936);
    addressOfBountyMembers.push(0x80476f7A837aeA5619Ef7f7f38218A933F3DA572);
    addressOfBountyMembers.push(0x806403646EBF5503361aA6A84c70EfCd4C71678e);
    addressOfBountyMembers.push(0x80B832CA39D0be75b17b0194DCAB400D0a75C97f);
    addressOfBountyMembers.push(0x8178DD2579aC4059d76c745c263a9Dbc405BFb0c);
    addressOfBountyMembers.push(0x829d4C463D09B786Db8E22cB6Fda3a750C621a83);
    addressOfBountyMembers.push(0x82AF599aE8a62842dA38be6E5d4b14cD5882bddb);
    addressOfBountyMembers.push(0x82F383AD178C43F1a27B947432f43af8851798AA);
    addressOfBountyMembers.push(0x834997EEAD7B42445fc7A8e8c2139C8263e74b4E);
    addressOfBountyMembers.push(0x8556364917c9b36Cf2046f136604AA7193E696a9);
    addressOfBountyMembers.push(0x86f7FE5486E224108899f19A7094a5908EF2EffF);
    addressOfBountyMembers.push(0x8876DCD446beF809408b06746a1d2bd98a4db8c7);
    addressOfBountyMembers.push(0x89add593581d22c7e8690b15f6a4f1c738b4a3d1);
    addressOfBountyMembers.push(0x8BAB0aC53F3604b9dA57EA81Ad3cb2320CCF71b0);
    addressOfBountyMembers.push(0x8d3Ad35453104F55649fe5c0446005622b0A610e);
    addressOfBountyMembers.push(0x8ea28df1858D905dc25918357c5654301489F285);
    addressOfBountyMembers.push(0x8f6f9a2BA2130989F51D08138bfb72c4bfe873bd);
    addressOfBountyMembers.push(0x8Fb806f314D4853cD32a7Ca445870DC4dAD27993);
    addressOfBountyMembers.push(0x903e83be4592c4E30018eAB394d834026a89C26b);
    addressOfBountyMembers.push(0x907A577bC365Bf73c0429d5F2C4FB939517aDEbb);
    addressOfBountyMembers.push(0x9138d2a99b47fF2A98927fEBF620C622939a6E66);
    addressOfBountyMembers.push(0x9193eD9cbf94D109667c3D5659CafFe21b4197Bc);
    addressOfBountyMembers.push(0x93744bcc687bb217e6b55d8fcbcb0e92ddff4569);
    addressOfBountyMembers.push(0x94c30dBB7EA6df4FCAd8c8864Edfc9c59cB8Db14);
    addressOfBountyMembers.push(0x9624fb11531aa9352f301caa822f951f433e89a7);
    addressOfBountyMembers.push(0x96305fFC2C0E586c31aA28f2b76615D78CAB403c);
    addressOfBountyMembers.push(0x9674b04fcdff254b8c641cf79f44d2a5a8bddd2c);
    addressOfBountyMembers.push(0x96923a2a08089C16FfC588cfe57CB37842332D91);
    addressOfBountyMembers.push(0x96cCF043C91055d17461239A0872CD72aA1fD269);
    addressOfBountyMembers.push(0x972978353E8054e4CfF24dd7348ea2B2ec768d55);
    addressOfBountyMembers.push(0x98503A0114C0D6c6826dE2A9679a6E9f6DdC4a1f);
    addressOfBountyMembers.push(0x98A031B94A1857757b9E1f024cAb37B165EB3945);
    addressOfBountyMembers.push(0x99B0DAc5a9C03C38E61778acc99a392DAb760975);
    addressOfBountyMembers.push(0x9aA5cfa67d7E6c5Dd5F7c0D9d96636ae6adEE91c);
    addressOfBountyMembers.push(0x9CF3D0264cE6b49c854411FE23BB89179878AE3B);
    addressOfBountyMembers.push(0x9D1fc2DD56A9a318c3FAc488C1Fa1df25247B779);
    addressOfBountyMembers.push(0x9d2386eA6FF3FE82Cdc2EcceAE033bbA9347545a);
    addressOfBountyMembers.push(0x9D71EB0B6d716e8a12f2e895E6021B68846c0a6f);
    addressOfBountyMembers.push(0x9d9a53525F75bdB7AaBE33a4F6817e49d041348d);
    addressOfBountyMembers.push(0x9Ea2131Fb37dDF32aECb38219e84D4E2946585bf);
    addressOfBountyMembers.push(0x9eE59c11458D564f83c056aF679da378a1f990a2);
    addressOfBountyMembers.push(0x9ffcF2A3cC2663fb605620778573cc99AA924Cee);
    addressOfBountyMembers.push(0xA1e906c4910857C9c48cDcb404c81DAe87fCA460);
    addressOfBountyMembers.push(0xa2A60167389B6B3a68a375f3EA7232ED5218e1eE);
    addressOfBountyMembers.push(0xA33040835975F17E6D68F3BE3ccd46327dC35027);
    addressOfBountyMembers.push(0xA3bEE330Bc1C26699C332B4a816b8D2995B48A33);
    addressOfBountyMembers.push(0xA56FE8f2704aE10668e71106F5f21BCd5bAdc37F);
    addressOfBountyMembers.push(0xA577A90D8C8F4d6a928AdB4693B735002C2Ab314);
    addressOfBountyMembers.push(0xA6e152d33b48Fc8D5bb24Bf1bC4dE61928903657);
    addressOfBountyMembers.push(0xa86A37054550a30003c06D0027ea4A567322AAB8);
    addressOfBountyMembers.push(0xa887218360933fc94297ad6baeA5ccEf48Bf4Fac);
    addressOfBountyMembers.push(0xa8c73ee57c268872b9d2d7a90e5f2e31af8493fb);
    addressOfBountyMembers.push(0xa8D815a9aF99d9b68EC9F127274d9Ba844B2b95C);
    addressOfBountyMembers.push(0xA9E261F0fb6e1B895376c9010CF116a8470Eff58);
    addressOfBountyMembers.push(0xAA7f6eB4EAB1d514C292Ae0eCcECd9FccA21c280);
    addressOfBountyMembers.push(0xab3Dc75A6F90a5cA18dd2e8e8E8F06044567c0AC);
    addressOfBountyMembers.push(0xab71B03091c6f03a85B4cf61580cbca29c0bb889);
    addressOfBountyMembers.push(0xabCf615E500F26A31c5FB392C2558aC0B8e7Cb30);
    addressOfBountyMembers.push(0xAc042A8E61fBa338011508625E9416Bf1e4e6922);
    addressOfBountyMembers.push(0xac4c9c0d2931Fa5e29Baafbcaf4e5dB1cE8A1758);
    addressOfBountyMembers.push(0xaD1c78a822c8244D40DdA29407286c30cF5402d4);
    addressOfBountyMembers.push(0xae3fAAe6E6b380baa8839201C6EA13EF409f4151);
    addressOfBountyMembers.push(0xafcA10C2c2aDEE754b670a5A647ED2D788d1E2FC);
    addressOfBountyMembers.push(0xb03243Ac0E3F9f8a3Ff7D09F394a91214Cbb0f4E);
    addressOfBountyMembers.push(0xB28A5c7b8AbC65c67E36bA61C1961b971EbC0d7f);
    addressOfBountyMembers.push(0xB2C92bc929c28e6812E7E74dA3DDa6b529bFbCFc);
  }

  function setBountyAmounts() internal { 
    bountyMembersAmounts[0x593699bd16480a398dfc5cbbc455dce627f156cb] =  113000000000000000000;
    bountyMembersAmounts[0x5B367be9bfD87391aCA778abcA4105A7A8C70616] = 1671000000000000000000;
    bountyMembersAmounts[0x5cad022750b4f37730819c04bccc5aa828b445f6] =  250000000000000000000;
    bountyMembersAmounts[0x5cC19cfF6D3030303118925576Df83D4AA7A602C] =  109000000000000000000;
    bountyMembersAmounts[0x5e4B80c8EFF9D6f1eF6B3c46472EFf6A1CAd7fd4] =  114000000000000000000;
    bountyMembersAmounts[0x5FF1084C4AC881a86AE8CdfFF08FF0a846e56489] =  197000000000000000000;
    bountyMembersAmounts[0x632de0e68779CEc7E2dc3a336F89Da0618a03fdC] =  276000000000000000000;
    bountyMembersAmounts[0x63515D455393dDc5F8F321dd084d1bd000545573] =  200000000000000000000;
    bountyMembersAmounts[0x642c055FF4eDC984216a613a88E22c8f8fa8aB33] =  172000000000000000000;
    bountyMembersAmounts[0x6621159d53251c145e030ADeDF1B6e10f3E85DdA] =  184000000000000000000;
    bountyMembersAmounts[0x663942E76762d75d3fA47242A7C9D133005cf7e7] =  170000000000000000000;
    bountyMembersAmounts[0x66f2A3cf344fD0f4F987C341c774452B753fE684] =  210000000000000000000;
    bountyMembersAmounts[0x671BDddd4d5696868ccDEec369f69A4D653e81eD] =  202000000000000000000;
    bountyMembersAmounts[0x675491b1b3f70ee5e7e1a3ae4dd27dc6a8a91425] =  173000000000000000000;
    bountyMembersAmounts[0x69E56d1E036c74f1F31cdDDEC09D7085D49b2947] =  125000000000000000000;
    bountyMembersAmounts[0x6ae322828E573f06695Ac0E39490A9bd31B6498F] =  254000000000000000000;
    bountyMembersAmounts[0x6b72DB853D72B473Bed7AaBddA8ab90BFD4558eB] =  150000000000000000000;
    bountyMembersAmounts[0x6bfb350FcbE780bA6b18314Df92d886C01d74c6e] =  127000000000000000000;
    bountyMembersAmounts[0x6C0844F2737bB5986E3c95e89CcC2928bAc4702A] =  106000000000000000000;
    bountyMembersAmounts[0x6cB67CC2540541AF4633E195e2970956a815e720] =  100000000000000000000;
    bountyMembersAmounts[0x6Cd5Be6cAe6a37D3500E224117E93369928d51b0] =  136000000000000000000;
    bountyMembersAmounts[0x6d9fd31D93C7e4B43250e3E3D181c4393ce2cB99] =  272000000000000000000;
    bountyMembersAmounts[0x6E82fbC3AAAAF22E517842AEfdf957317386C537] =  100000000000000000000;
    bountyMembersAmounts[0x6e9c261D10575c87fE8724c54ccD26e59F77101a] =  808000000000000000000;
    bountyMembersAmounts[0x6eA012B7E536E51CF9149609Df775FadEf263b19] =  274000000000000000000;
    bountyMembersAmounts[0x71f51E7455B26D7C70467Cddfc5153Ca53a58CCb] =  167000000000000000000;
    bountyMembersAmounts[0x72Bf7B0ef8e2753493B22A1B6492359e432F819B] =  249000000000000000000;
    bountyMembersAmounts[0x72fF7EB7100cc0AdA5B114E1c78Cab287F44aB30] =  100000000000000000000;
    bountyMembersAmounts[0x733FF886E1B196e2Bd38829043efFE0971220479] =  118000000000000000000;
    bountyMembersAmounts[0x77d00c9F51669d5D5615f8902C9c3534c9ED8967] =  100000000000000000000;
    bountyMembersAmounts[0x78E934eBd3d7Fa0D703eb101baD0261dC0973238] =  261000000000000000000;
    bountyMembersAmounts[0x791Ab7014A7AD2892a55298CFEdd9A48c7Bc687D] =  159000000000000000000;
    bountyMembersAmounts[0x793a9F8b936AD8a66e018F6f62be9A235cDb3FfF] =  142000000000000000000;
    bountyMembersAmounts[0x7A791EFb0749e2B1B5f3EfD5588f04cF21265678] =  100000000000000000000;
    bountyMembersAmounts[0x7ba18657684d37053f9d84b305785d1c26b0c28d] =  328000000000000000000;
    bountyMembersAmounts[0x7bD19eBbA137BdFD4a55815AfAD06094030a680A] =  109000000000000000000;
    bountyMembersAmounts[0x7C2627Ac3c081e2Ac8d3aC2207B329003EddEAC0] =  154000000000000000000;
    bountyMembersAmounts[0x7ce5E965068c73f9F89e3c8C244666FB5cee3B60] =  100000000000000000000;
    bountyMembersAmounts[0x7De09DD2Ad9cdFe1143aabFD94106b7C1e4cB8cd] =  268000000000000000000;
    bountyMembersAmounts[0x7e0d6F45346539E08054B1fC49d03F5e3002d13A] =  243000000000000000000;
    bountyMembersAmounts[0x7e1F1bD14DCbcCAf268BFd067018812Da4cA4d5F] =  104000000000000000000;
    bountyMembersAmounts[0x7e5CeBeE3C4bEF1f2aa6ad06C9a9C4A5BfB5A74e] =  180000000000000000000;
    bountyMembersAmounts[0x7ed9916dd87032e998ced31d435d2971c9ce4e45] =  132000000000000000000;
    bountyMembersAmounts[0x7f500f8561f8282903f73663c57242b8feaF3572] =  310000000000000000000;
    bountyMembersAmounts[0x7FBD6d575142959c842BD5D590261F955a86E936] =  104000000000000000000;
    bountyMembersAmounts[0x80476f7A837aeA5619Ef7f7f38218A933F3DA572] =  153000000000000000000;
    bountyMembersAmounts[0x806403646EBF5503361aA6A84c70EfCd4C71678e] =  100000000000000000000;
    bountyMembersAmounts[0x80B832CA39D0be75b17b0194DCAB400D0a75C97f] =  200000000000000000000;
    bountyMembersAmounts[0x8178DD2579aC4059d76c745c263a9Dbc405BFb0c] =  220000000000000000000;
    bountyMembersAmounts[0x829d4C463D09B786Db8E22cB6Fda3a750C621a83] =  123000000000000000000;
    bountyMembersAmounts[0x82AF599aE8a62842dA38be6E5d4b14cD5882bddb] =  132000000000000000000;
    bountyMembersAmounts[0x82F383AD178C43F1a27B947432f43af8851798AA] =  105000000000000000000;
    bountyMembersAmounts[0x834997EEAD7B42445fc7A8e8c2139C8263e74b4E] =  104000000000000000000;
    bountyMembersAmounts[0x8556364917c9b36Cf2046f136604AA7193E696a9] =  117000000000000000000;
    bountyMembersAmounts[0x86f7FE5486E224108899f19A7094a5908EF2EffF] =  100000000000000000000;
    bountyMembersAmounts[0x8876DCD446beF809408b06746a1d2bd98a4db8c7] =  162000000000000000000;
    bountyMembersAmounts[0x89add593581d22c7e8690b15f6a4f1c738b4a3d1] =  200000000000000000000;
    bountyMembersAmounts[0x8BAB0aC53F3604b9dA57EA81Ad3cb2320CCF71b0] =  118000000000000000000;
    bountyMembersAmounts[0x8d3Ad35453104F55649fe5c0446005622b0A610e] =  214000000000000000000;
    bountyMembersAmounts[0x8ea28df1858D905dc25918357c5654301489F285] =  284000000000000000000;
    bountyMembersAmounts[0x8f6f9a2BA2130989F51D08138bfb72c4bfe873bd] =  117000000000000000000;
    bountyMembersAmounts[0x8Fb806f314D4853cD32a7Ca445870DC4dAD27993] =  108000000000000000000;
    bountyMembersAmounts[0x903e83be4592c4E30018eAB394d834026a89C26b] =  184000000000000000000;
    bountyMembersAmounts[0x907A577bC365Bf73c0429d5F2C4FB939517aDEbb] =  108000000000000000000;
    bountyMembersAmounts[0x9138d2a99b47fF2A98927fEBF620C622939a6E66] =  204000000000000000000;
    bountyMembersAmounts[0x9193eD9cbf94D109667c3D5659CafFe21b4197Bc] =  208000000000000000000;
    bountyMembersAmounts[0x93744bcc687bb217e6b55d8fcbcb0e92ddff4569] =  205000000000000000000;
    bountyMembersAmounts[0x94c30dBB7EA6df4FCAd8c8864Edfc9c59cB8Db14] =  114000000000000000000;
    bountyMembersAmounts[0x9624fb11531aa9352f301caa822f951f433e89a7] =  151000000000000000000;
    bountyMembersAmounts[0x96305fFC2C0E586c31aA28f2b76615D78CAB403c] =  107000000000000000000;
    bountyMembersAmounts[0x9674b04fcdff254b8c641cf79f44d2a5a8bddd2c] =  111000000000000000000;
    bountyMembersAmounts[0x96923a2a08089C16FfC588cfe57CB37842332D91] =  178000000000000000000;
    bountyMembersAmounts[0x96cCF043C91055d17461239A0872CD72aA1fD269] =  115000000000000000000;
    bountyMembersAmounts[0x972978353E8054e4CfF24dd7348ea2B2ec768d55] =  329000000000000000000;
    bountyMembersAmounts[0x98503A0114C0D6c6826dE2A9679a6E9f6DdC4a1f] =  231000000000000000000;
    bountyMembersAmounts[0x98A031B94A1857757b9E1f024cAb37B165EB3945] =  104000000000000000000;
    bountyMembersAmounts[0x99B0DAc5a9C03C38E61778acc99a392DAb760975] =  140000000000000000000;
    bountyMembersAmounts[0x9aA5cfa67d7E6c5Dd5F7c0D9d96636ae6adEE91c] =  104000000000000000000;
    bountyMembersAmounts[0x9CF3D0264cE6b49c854411FE23BB89179878AE3B] =  115000000000000000000;
    bountyMembersAmounts[0x9D1fc2DD56A9a318c3FAc488C1Fa1df25247B779] =  120000000000000000000;
    bountyMembersAmounts[0x9d2386eA6FF3FE82Cdc2EcceAE033bbA9347545a] =  171000000000000000000;
    bountyMembersAmounts[0x9D71EB0B6d716e8a12f2e895E6021B68846c0a6f] =  111000000000000000000;
    bountyMembersAmounts[0x9d9a53525F75bdB7AaBE33a4F6817e49d041348d] =  100000000000000000000;
    bountyMembersAmounts[0x9Ea2131Fb37dDF32aECb38219e84D4E2946585bf] =  193000000000000000000;
    bountyMembersAmounts[0x9eE59c11458D564f83c056aF679da378a1f990a2] =  174000000000000000000;
    bountyMembersAmounts[0x9ffcF2A3cC2663fb605620778573cc99AA924Cee] =  130000000000000000000;
    bountyMembersAmounts[0xA1e906c4910857C9c48cDcb404c81DAe87fCA460] =  142000000000000000000;
    bountyMembersAmounts[0xa2A60167389B6B3a68a375f3EA7232ED5218e1eE] =  179000000000000000000;
    bountyMembersAmounts[0xA33040835975F17E6D68F3BE3ccd46327dC35027] =  105000000000000000000;
    bountyMembersAmounts[0xA3bEE330Bc1C26699C332B4a816b8D2995B48A33] =  114000000000000000000;
    bountyMembersAmounts[0xA56FE8f2704aE10668e71106F5f21BCd5bAdc37F] =  180000000000000000000;
    bountyMembersAmounts[0xA577A90D8C8F4d6a928AdB4693B735002C2Ab314] =  100000000000000000000;
    bountyMembersAmounts[0xA6e152d33b48Fc8D5bb24Bf1bC4dE61928903657] =  200000000000000000000;
    bountyMembersAmounts[0xa86A37054550a30003c06D0027ea4A567322AAB8] =  163000000000000000000;
    bountyMembersAmounts[0xa887218360933fc94297ad6baeA5ccEf48Bf4Fac] =  129000000000000000000;
    bountyMembersAmounts[0xa8c73ee57c268872b9d2d7a90e5f2e31af8493fb] =  102000000000000000000;
    bountyMembersAmounts[0xa8D815a9aF99d9b68EC9F127274d9Ba844B2b95C] =  129000000000000000000;
    bountyMembersAmounts[0xA9E261F0fb6e1B895376c9010CF116a8470Eff58] =  100000000000000000000;
    bountyMembersAmounts[0xAA7f6eB4EAB1d514C292Ae0eCcECd9FccA21c280] =  148000000000000000000;
    bountyMembersAmounts[0xab3Dc75A6F90a5cA18dd2e8e8E8F06044567c0AC] =  141000000000000000000;
    bountyMembersAmounts[0xab71B03091c6f03a85B4cf61580cbca29c0bb889] =  100000000000000000000;
    bountyMembersAmounts[0xabCf615E500F26A31c5FB392C2558aC0B8e7Cb30] =  134000000000000000000;
    bountyMembersAmounts[0xAc042A8E61fBa338011508625E9416Bf1e4e6922] =  162000000000000000000;
    bountyMembersAmounts[0xac4c9c0d2931Fa5e29Baafbcaf4e5dB1cE8A1758] =  166000000000000000000;
    bountyMembersAmounts[0xaD1c78a822c8244D40DdA29407286c30cF5402d4] =  105000000000000000000;
    bountyMembersAmounts[0xae3fAAe6E6b380baa8839201C6EA13EF409f4151] =  146000000000000000000;
    bountyMembersAmounts[0xafcA10C2c2aDEE754b670a5A647ED2D788d1E2FC] =  386000000000000000000;
    bountyMembersAmounts[0xb03243Ac0E3F9f8a3Ff7D09F394a91214Cbb0f4E] =  122000000000000000000;
    bountyMembersAmounts[0xB28A5c7b8AbC65c67E36bA61C1961b971EbC0d7f] =  122000000000000000000;
    bountyMembersAmounts[0xB2C92bc929c28e6812E7E74dA3DDa6b529bFbCFc] =  114000000000000000000;
  } 
}