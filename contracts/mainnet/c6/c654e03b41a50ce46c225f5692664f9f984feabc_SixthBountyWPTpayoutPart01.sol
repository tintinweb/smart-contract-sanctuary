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

contract SixthBountyWPTpayoutPart01 {
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
    addressOfBountyMembers.push(0x008B4d0a244F9F57FFb6B523Bed3707C38E51f92);
    addressOfBountyMembers.push(0x00a6B0385ca7902e187CAf2406348605cabC531a);
    addressOfBountyMembers.push(0x02C7eA8f0d6f3C4b12529edED6644696368B4d9c);
    addressOfBountyMembers.push(0x02EC043B63B2C8E3E6488779B245046FE912019e);
    addressOfBountyMembers.push(0x02Ed066fd536A05Fb38F3e4d023A46E47876B000);
    addressOfBountyMembers.push(0x043334e470f2cC274114806ad9BE2f19c9e04386);
    addressOfBountyMembers.push(0x047388B7A75b8AA45aA3c61537dA94f8154cDa43);
    addressOfBountyMembers.push(0x05481f8665fBD1AE0D178f2C90F20FAb6016b3C6);
    addressOfBountyMembers.push(0x05b580942037e6262f47A17d412778d56467ddaB);
    addressOfBountyMembers.push(0x05F9D39024dD7A21aD0FCDa57dFbc20F94de839d);
    addressOfBountyMembers.push(0x060fb9864CD812769791353821d655B5c270faAb);
    addressOfBountyMembers.push(0x0832c548114c2B9B3cdf04b3B466e8c71F2f3Dd0);
    addressOfBountyMembers.push(0x0896A74BF92Ffb18E825e12157e63A933541e301);
    addressOfBountyMembers.push(0x092EeB155Ea3959Ae47d43391b95c4F7A20324DC);
    addressOfBountyMembers.push(0x09B51a0afe2fECEcC0fC7eE5e577167eCFf74175);
    addressOfBountyMembers.push(0x0A72eb10549b4CE87fB90958D987e67df23777bC);
    addressOfBountyMembers.push(0x0b1C78648d904785Bea81B46442B12d41614DC04);
    addressOfBountyMembers.push(0x0b3AF6fB13DE7e8c121a151D765bee95Da937370);
    addressOfBountyMembers.push(0x0D53eBD922F5ADD303A33Ff42354553A6603ff4f);
    addressOfBountyMembers.push(0x0e14b822Bb33215eD86eD703CF98D65277a992A8);
    addressOfBountyMembers.push(0x0E1b754b804aD292E97185767B16Add1c4C61c75);
    addressOfBountyMembers.push(0x0EB1bD5F73F6c1cf6B835C6F4e971B2af6267d85);
    addressOfBountyMembers.push(0x103287b5682964B94be7eA4046d57adA24b7eB36);
    addressOfBountyMembers.push(0x1275ae9C3658FF98F6EAcDc42011Fa630c333366);
    addressOfBountyMembers.push(0x12B8Dc8e5eC866CFDFfFfcd9C3811AFa980A1776);
    addressOfBountyMembers.push(0x132eC9fabbafc29aDF004Fe4433B8b656e5Be093);
    addressOfBountyMembers.push(0x13769addF4DF5E362CeD6b57dc10C6755219b2cC);
    addressOfBountyMembers.push(0x13a142e6e6AC3Ab84e3D1ABFEFD1aF8491BaCBE7);
    addressOfBountyMembers.push(0x150863D99c6A0Be7E43e90Fb44D08E66997a30e3);
    addressOfBountyMembers.push(0x1606508b460b5F932cAE7Be4446563B6865bC34A);
    addressOfBountyMembers.push(0x17B2824ea0b15E1c71ad27988bB4Df996b0f9bA0);
    addressOfBountyMembers.push(0x19C368F3a6EEf701B4aE2949a76aF7ccADFDD845);
    addressOfBountyMembers.push(0x1a8EB2d5A99A13c90145002e2a26A09Faa996b1A);
    addressOfBountyMembers.push(0x1acaBC53186E43d74FF3c83eBe71D295Be3deb28);
    addressOfBountyMembers.push(0x1aCB1975200df1fc6ffCACA51EA63909005CDf99);
    addressOfBountyMembers.push(0x1B898a4e4B95dAD205786633e2f0552C0478d470);
    addressOfBountyMembers.push(0x1c2e7eeA9Dd9972ef1F15fF811B9F954c5ea5BF9);
    addressOfBountyMembers.push(0x1d478f80b2B28d9d9F5201FF02fBF88C385B6b1B);
    addressOfBountyMembers.push(0x1df51aB55a1e12B4AbD75333A688FDB3E9573c7A);
    addressOfBountyMembers.push(0x1E12E92AC761cEaE44bdBBF4EEDFb55042fc45ec);
    addressOfBountyMembers.push(0x1ed624a83F6023FFAce8d1874AeAC7947ca820ca);
    addressOfBountyMembers.push(0x1ed7890CBDC4B67B4673a09B10D60615D1783e0b);
    addressOfBountyMembers.push(0x1F33CeED48C06bD6acf2b4E56275322a0996425c);
    addressOfBountyMembers.push(0x2133F226469df87311B1aC384B861542528ee0CF);
    addressOfBountyMembers.push(0x214872F0C3b3Fe853c4485A3182CEdbC588B807b);
    addressOfBountyMembers.push(0x224C5857dC6399954F80DE3CA803d1C783424649);
    addressOfBountyMembers.push(0x224F57e78dAB30a43EEe025Debba63E572F5C246);
    addressOfBountyMembers.push(0x22e658A43C8567Da2Ad66A755873f900475910B8);
    addressOfBountyMembers.push(0x2425D0a3874ef6FcEEA3cAfb9509643149C7aB62);
    addressOfBountyMembers.push(0x24a710d15c6E1339D33fB86B48d22643A5a5E243);
    addressOfBountyMembers.push(0x2520cBE9EA45Fe477D4d347B7866325980285b06);
    addressOfBountyMembers.push(0x25519Ff67F6e97e5eDa2bCABfB4A20425E7c4Cb7);
    addressOfBountyMembers.push(0x257Bc25Eae57aFC4c6859F4c20a5F4318A0d24c6);
    addressOfBountyMembers.push(0x27d0cE31D8AfbA27F46A8053D06032074dbA448C);
    addressOfBountyMembers.push(0x28b51bD075283e0573903aE6bc3F9835DB49AF43);
    addressOfBountyMembers.push(0x291f1ea0E067a6E41A612cf5a0478DbD29012339);
    addressOfBountyMembers.push(0x2A4a888fd8690F7cB56855db98180a479A181fbd);
    addressOfBountyMembers.push(0x2B81Dc184bBF7FB631145D4f56DD9d3935cC8Ca6);
    addressOfBountyMembers.push(0x2CdEe43d16f8526b1142c04E269a750046B97277);
    addressOfBountyMembers.push(0x2D375a25A80747de74AE9AAE665B2D647cfA4884);
    addressOfBountyMembers.push(0x2F96c2F5183c1a4D1AB2da19E3595F909e602aBb);
    addressOfBountyMembers.push(0x30498cb97630fE187743368CDF620Cc61552B9C2);
    addressOfBountyMembers.push(0x307c905b084696D2190B13212c8C45245b8fFedF);
    addressOfBountyMembers.push(0x316B2C3a805035e4ceBB13F63bd9d4eAeF1586fA);
    addressOfBountyMembers.push(0x32D83105106e193beb495e2D3730De2aeD6fBcfE);
    addressOfBountyMembers.push(0x334F03ebAA3B292b4CAbA803f10E515C5165725B);
    addressOfBountyMembers.push(0x34925a7b96099563AbfCa95B93Ea64F9F8F4ddF8);
    addressOfBountyMembers.push(0x3585D0519Bb048368ec2eD4c682c7179f8a2d1dB);
    addressOfBountyMembers.push(0x36BB2Ac472ec9095a803eB66Dc6bE946d33Fe21A);
    addressOfBountyMembers.push(0x3780dF04c6d0074F6aAC8f1F5acAD61c57604496);
    addressOfBountyMembers.push(0x37BdA34b327256caB7ad706c07Aef96c6fb45f53);
    addressOfBountyMembers.push(0x384118A2c4405c4692eBFEC4Bc8B9c1eA9Fe198A);
    addressOfBountyMembers.push(0x3A5eD18F0B39bc78f753141b9F873c2b326144F4);
    addressOfBountyMembers.push(0x3B0c6A55747FB7Ec5e36B52df99428537B399be7);
    addressOfBountyMembers.push(0x3b7121c8d83976174333C4c09692f5C7B81653d2);
    addressOfBountyMembers.push(0x3cDC5bc15b68a782Ab9583C85E7E62da45C70Ba0);
    addressOfBountyMembers.push(0x3d813acE32f876C07B6E7ac1be14aC7bc1FBDB94);
    addressOfBountyMembers.push(0x3E63a6fcabB3e8bbc9c9e11c95D014Ec46B49baa);
    addressOfBountyMembers.push(0x3EB13628f4a7E76d87ca0EcfA8dad629f5eC7a85);
    addressOfBountyMembers.push(0x3F5A46A14648F40bd6C8FC487d16E3eac0Cf3d43);
    addressOfBountyMembers.push(0x3F7d1B8A58893d13c357F1089B9080874cAC0E41);
    addressOfBountyMembers.push(0x415E53a762fDf579ccDBC1082811f0FcC1f09745);
    addressOfBountyMembers.push(0x41d1527B4733A86497dD4a0E502171DD98f4ddD4);
    addressOfBountyMembers.push(0x4397beF5b7B5Ed32930C15Da81CFAA6ee1Fec5AB);
    addressOfBountyMembers.push(0x462134A25ef3D89c7376CEE71c0c41648EFB026D);
    addressOfBountyMembers.push(0x4694F54aaF0e060B261C2F12c128FC7a182765b0);
    addressOfBountyMembers.push(0x4823216D58149f25f7e5d43Ae66c338e99958530);
    addressOfBountyMembers.push(0x4830f11bdd82feb039E410c8564e1C008A3387D2);
    addressOfBountyMembers.push(0x48Ec399b6AF069614a326dc4D5CbdE560B099892);
    addressOfBountyMembers.push(0x49364EAA39Cc501bD8831583314c27B685fa6fA6);
    addressOfBountyMembers.push(0x493fFCced1827207D4FDBa3Ba37235c3304185D8);
    addressOfBountyMembers.push(0x4A60F7156061EC5AeBbe7979B69b86Dd7420C3ee);
    addressOfBountyMembers.push(0x4aB01De979775F4541055FdE988c634639331CAC);
    addressOfBountyMembers.push(0x4AF3bCCD6C082ed9807c27ee83e33c31a18D1d98);
    addressOfBountyMembers.push(0x4b65937Af1b4c39Da0396617d02686087a3A20eD);
    addressOfBountyMembers.push(0x4Db5A1F90f424cb0003b7c6732217A4cc02AB122);
    addressOfBountyMembers.push(0x4e14e87a9d57459133e8ba3e5680ee0d0a2ae2d9);
    addressOfBountyMembers.push(0x4E323aF448358CFAa2A72CC9Bc8689F097ef750A);
    addressOfBountyMembers.push(0x4eAC7faFd3CC34De6271E6598ac1c42c528aB18D);
    addressOfBountyMembers.push(0x4EAd7bacA6a23d88D3389876B620cA21B0678e77);
    addressOfBountyMembers.push(0x4F259A3E497c559FB15Eb4dB424D9a1ce938C81f);
    addressOfBountyMembers.push(0x4f6435f3d9eb349503A0a116F0006B127f70a69f);
    addressOfBountyMembers.push(0x524d99A5aE61961154bAA2668788c004923FfaEB);
    addressOfBountyMembers.push(0x53765FaA9C2AD3a7fFA1C8B6F11eABA58BCf6f1C);
    addressOfBountyMembers.push(0x54Adb65d1447FE56BECd5ac2Fa30E6dA6A2E4894);
    addressOfBountyMembers.push(0x55552D38a83d1A7fe9859B670453736EC31f2De1);
    addressOfBountyMembers.push(0x558C2af073229D3B4B52a625E32f3fdbFD57593C);
    addressOfBountyMembers.push(0x56EDBAC3ac856c4331B8C0E459D69b12b899d2B5);
    addressOfBountyMembers.push(0x58b44E1b59aa0333255c62734f4E691937DAE911);
    addressOfBountyMembers.push(0x58Cd522a2480e93b5bFd671479AaB2141cdC03BD);
  }

  function setBountyAmounts() internal { 
    bountyMembersAmounts[0x008B4d0a244F9F57FFb6B523Bed3707C38E51f92] =  100000000000000000000;
    bountyMembersAmounts[0x00a6B0385ca7902e187CAf2406348605cabC531a] =  145000000000000000000;
    bountyMembersAmounts[0x02C7eA8f0d6f3C4b12529edED6644696368B4d9c] =  165000000000000000000;
    bountyMembersAmounts[0x02EC043B63B2C8E3E6488779B245046FE912019e] =  152000000000000000000;
    bountyMembersAmounts[0x02Ed066fd536A05Fb38F3e4d023A46E47876B000] =  214000000000000000000;
    bountyMembersAmounts[0x043334e470f2cC274114806ad9BE2f19c9e04386] =  234000000000000000000;
    bountyMembersAmounts[0x047388B7A75b8AA45aA3c61537dA94f8154cDa43] =  609880000000000000000;
    bountyMembersAmounts[0x05481f8665fBD1AE0D178f2C90F20FAb6016b3C6] =  148000000000000000000;
    bountyMembersAmounts[0x05b580942037e6262f47A17d412778d56467ddaB] =  296000000000000000000;
    bountyMembersAmounts[0x05F9D39024dD7A21aD0FCDa57dFbc20F94de839d] =  220000000000000000000;
    bountyMembersAmounts[0x060fb9864CD812769791353821d655B5c270faAb] =  254000000000000000000;
    bountyMembersAmounts[0x0832c548114c2B9B3cdf04b3B466e8c71F2f3Dd0] =  196000000000000000000;
    bountyMembersAmounts[0x0896A74BF92Ffb18E825e12157e63A933541e301] =  126000000000000000000;
    bountyMembersAmounts[0x092EeB155Ea3959Ae47d43391b95c4F7A20324DC] =  251000000000000000000;
    bountyMembersAmounts[0x09B51a0afe2fECEcC0fC7eE5e577167eCFf74175] =  126000000000000000000;
    bountyMembersAmounts[0x0A72eb10549b4CE87fB90958D987e67df23777bC] =  174000000000000000000;
    bountyMembersAmounts[0x0b1C78648d904785Bea81B46442B12d41614DC04] =  200000000000000000000;
    bountyMembersAmounts[0x0b3AF6fB13DE7e8c121a151D765bee95Da937370] =  330000000000000000000;
    bountyMembersAmounts[0x0D53eBD922F5ADD303A33Ff42354553A6603ff4f] =  119000000000000000000;
    bountyMembersAmounts[0x0e14b822Bb33215eD86eD703CF98D65277a992A8] =  147000000000000000000;
    bountyMembersAmounts[0x0E1b754b804aD292E97185767B16Add1c4C61c75] =  101000000000000000000;
    bountyMembersAmounts[0x0EB1bD5F73F6c1cf6B835C6F4e971B2af6267d85] =  116000000000000000000;
    bountyMembersAmounts[0x103287b5682964B94be7eA4046d57adA24b7eB36] =  102000000000000000000;
    bountyMembersAmounts[0x1275ae9C3658FF98F6EAcDc42011Fa630c333366] =  176000000000000000000;
    bountyMembersAmounts[0x12B8Dc8e5eC866CFDFfFfcd9C3811AFa980A1776] =  160000000000000000000;
    bountyMembersAmounts[0x132eC9fabbafc29aDF004Fe4433B8b656e5Be093] =  249000000000000000000;
    bountyMembersAmounts[0x13769addF4DF5E362CeD6b57dc10C6755219b2cC] =  133000000000000000000;
    bountyMembersAmounts[0x13a142e6e6AC3Ab84e3D1ABFEFD1aF8491BaCBE7] =  144000000000000000000;
    bountyMembersAmounts[0x150863D99c6A0Be7E43e90Fb44D08E66997a30e3] =  156000000000000000000;
    bountyMembersAmounts[0x1606508b460b5F932cAE7Be4446563B6865bC34A] =  100000000000000000000;
    bountyMembersAmounts[0x17B2824ea0b15E1c71ad27988bB4Df996b0f9bA0] =  106000000000000000000;
    bountyMembersAmounts[0x19C368F3a6EEf701B4aE2949a76aF7ccADFDD845] =  200000000000000000000;
    bountyMembersAmounts[0x1a8EB2d5A99A13c90145002e2a26A09Faa996b1A] =  145000000000000000000;
    bountyMembersAmounts[0x1acaBC53186E43d74FF3c83eBe71D295Be3deb28] =  102000000000000000000;
    bountyMembersAmounts[0x1aCB1975200df1fc6ffCACA51EA63909005CDf99] =  173000000000000000000;
    bountyMembersAmounts[0x1B898a4e4B95dAD205786633e2f0552C0478d470] =  362000000000000000000;
    bountyMembersAmounts[0x1c2e7eeA9Dd9972ef1F15fF811B9F954c5ea5BF9] =  180000000000000000000;
    bountyMembersAmounts[0x1d478f80b2B28d9d9F5201FF02fBF88C385B6b1B] =  128000000000000000000;
    bountyMembersAmounts[0x1df51aB55a1e12B4AbD75333A688FDB3E9573c7A] =  115000000000000000000;
    bountyMembersAmounts[0x1E12E92AC761cEaE44bdBBF4EEDFb55042fc45ec] =  134000000000000000000;
    bountyMembersAmounts[0x1ed624a83F6023FFAce8d1874AeAC7947ca820ca] =  274000000000000000000;
    bountyMembersAmounts[0x1ed7890CBDC4B67B4673a09B10D60615D1783e0b] = 3364000000000000000000;
    bountyMembersAmounts[0x1F33CeED48C06bD6acf2b4E56275322a0996425c] =  198000000000000000000;
    bountyMembersAmounts[0x2133F226469df87311B1aC384B861542528ee0CF] =  182000000000000000000;
    bountyMembersAmounts[0x214872F0C3b3Fe853c4485A3182CEdbC588B807b] =  102000000000000000000;
    bountyMembersAmounts[0x224C5857dC6399954F80DE3CA803d1C783424649] =  232000000000000000000;
    bountyMembersAmounts[0x224F57e78dAB30a43EEe025Debba63E572F5C246] =  279000000000000000000;
    bountyMembersAmounts[0x22e658A43C8567Da2Ad66A755873f900475910B8] = 2200000000000000000000;
    bountyMembersAmounts[0x2425D0a3874ef6FcEEA3cAfb9509643149C7aB62] =  102000000000000000000;
    bountyMembersAmounts[0x24a710d15c6E1339D33fB86B48d22643A5a5E243] =  100000000000000000000;
    bountyMembersAmounts[0x2520cBE9EA45Fe477D4d347B7866325980285b06] =  130000000000000000000;
    bountyMembersAmounts[0x25519Ff67F6e97e5eDa2bCABfB4A20425E7c4Cb7] =  280000000000000000000;
    bountyMembersAmounts[0x257Bc25Eae57aFC4c6859F4c20a5F4318A0d24c6] =  111000000000000000000;
    bountyMembersAmounts[0x27d0cE31D8AfbA27F46A8053D06032074dbA448C] =  107000000000000000000;
    bountyMembersAmounts[0x28b51bD075283e0573903aE6bc3F9835DB49AF43] =  120000000000000000000;
    bountyMembersAmounts[0x291f1ea0E067a6E41A612cf5a0478DbD29012339] =  118000000000000000000;
    bountyMembersAmounts[0x2A4a888fd8690F7cB56855db98180a479A181fbd] =  114000000000000000000;
    bountyMembersAmounts[0x2B81Dc184bBF7FB631145D4f56DD9d3935cC8Ca6] =  100000000000000000000;
    bountyMembersAmounts[0x2CdEe43d16f8526b1142c04E269a750046B97277] =  131000000000000000000;
    bountyMembersAmounts[0x2D375a25A80747de74AE9AAE665B2D647cfA4884] =  102000000000000000000;
    bountyMembersAmounts[0x2F96c2F5183c1a4D1AB2da19E3595F909e602aBb] =  198000000000000000000;
    bountyMembersAmounts[0x30498cb97630fE187743368CDF620Cc61552B9C2] =  130000000000000000000;
    bountyMembersAmounts[0x307c905b084696D2190B13212c8C45245b8fFedF] =  150000000000000000000;
    bountyMembersAmounts[0x316B2C3a805035e4ceBB13F63bd9d4eAeF1586fA] =  106000000000000000000;
    bountyMembersAmounts[0x32D83105106e193beb495e2D3730De2aeD6fBcfE] =  102000000000000000000;
    bountyMembersAmounts[0x334F03ebAA3B292b4CAbA803f10E515C5165725B] =  432000000000000000000;
    bountyMembersAmounts[0x34925a7b96099563AbfCa95B93Ea64F9F8F4ddF8] =  217000000000000000000;
    bountyMembersAmounts[0x3585D0519Bb048368ec2eD4c682c7179f8a2d1dB] =  130000000000000000000;
    bountyMembersAmounts[0x36BB2Ac472ec9095a803eB66Dc6bE946d33Fe21A] =  116000000000000000000;
    bountyMembersAmounts[0x3780dF04c6d0074F6aAC8f1F5acAD61c57604496] =  132000000000000000000;
    bountyMembersAmounts[0x37BdA34b327256caB7ad706c07Aef96c6fb45f53] =  217000000000000000000;
    bountyMembersAmounts[0x384118A2c4405c4692eBFEC4Bc8B9c1eA9Fe198A] =  107000000000000000000;
    bountyMembersAmounts[0x3A5eD18F0B39bc78f753141b9F873c2b326144F4] =  122000000000000000000;
    bountyMembersAmounts[0x3B0c6A55747FB7Ec5e36B52df99428537B399be7] =  129000000000000000000;
    bountyMembersAmounts[0x3b7121c8d83976174333C4c09692f5C7B81653d2] =  115000000000000000000;
    bountyMembersAmounts[0x3cDC5bc15b68a782Ab9583C85E7E62da45C70Ba0] =  103000000000000000000;
    bountyMembersAmounts[0x3d813acE32f876C07B6E7ac1be14aC7bc1FBDB94] =  150000000000000000000;
    bountyMembersAmounts[0x3E63a6fcabB3e8bbc9c9e11c95D014Ec46B49baa] =  108000000000000000000;
    bountyMembersAmounts[0x3EB13628f4a7E76d87ca0EcfA8dad629f5eC7a85] =  699000000000000000000;
    bountyMembersAmounts[0x3F5A46A14648F40bd6C8FC487d16E3eac0Cf3d43] =  200000000000000000000;
    bountyMembersAmounts[0x3F7d1B8A58893d13c357F1089B9080874cAC0E41] =  118000000000000000000;
    bountyMembersAmounts[0x415E53a762fDf579ccDBC1082811f0FcC1f09745] =  255000000000000000000;
    bountyMembersAmounts[0x41d1527B4733A86497dD4a0E502171DD98f4ddD4] =  142000000000000000000;
    bountyMembersAmounts[0x4397beF5b7B5Ed32930C15Da81CFAA6ee1Fec5AB] =  148000000000000000000;
    bountyMembersAmounts[0x462134A25ef3D89c7376CEE71c0c41648EFB026D] =  235000000000000000000;
    bountyMembersAmounts[0x4694F54aaF0e060B261C2F12c128FC7a182765b0] =  198000000000000000000;
    bountyMembersAmounts[0x4823216D58149f25f7e5d43Ae66c338e99958530] =  143000000000000000000;
    bountyMembersAmounts[0x4830f11bdd82feb039E410c8564e1C008A3387D2] =  152000000000000000000;
    bountyMembersAmounts[0x48Ec399b6AF069614a326dc4D5CbdE560B099892] =  320000000000000000000;
    bountyMembersAmounts[0x49364EAA39Cc501bD8831583314c27B685fa6fA6] =  111000000000000000000;
    bountyMembersAmounts[0x493fFCced1827207D4FDBa3Ba37235c3304185D8] =  171000000000000000000;
    bountyMembersAmounts[0x4A60F7156061EC5AeBbe7979B69b86Dd7420C3ee] =  149000000000000000000;
    bountyMembersAmounts[0x4aB01De979775F4541055FdE988c634639331CAC] =  137000000000000000000;
    bountyMembersAmounts[0x4AF3bCCD6C082ed9807c27ee83e33c31a18D1d98] =  166000000000000000000;
    bountyMembersAmounts[0x4b65937Af1b4c39Da0396617d02686087a3A20eD] =  171000000000000000000;
    bountyMembersAmounts[0x4Db5A1F90f424cb0003b7c6732217A4cc02AB122] =  219000000000000000000;
    bountyMembersAmounts[0x4e14e87a9d57459133e8ba3e5680ee0d0a2ae2d9] =  174000000000000000000;
    bountyMembersAmounts[0x4E323aF448358CFAa2A72CC9Bc8689F097ef750A] =  140000000000000000000;
    bountyMembersAmounts[0x4eAC7faFd3CC34De6271E6598ac1c42c528aB18D] =  120000000000000000000;
    bountyMembersAmounts[0x4EAd7bacA6a23d88D3389876B620cA21B0678e77] =  100000000000000000000;
    bountyMembersAmounts[0x4F259A3E497c559FB15Eb4dB424D9a1ce938C81f] =  853000000000000000000;
    bountyMembersAmounts[0x4f6435f3d9eb349503A0a116F0006B127f70a69f] =  120000000000000000000;
    bountyMembersAmounts[0x524d99A5aE61961154bAA2668788c004923FfaEB] =  179000000000000000000;
    bountyMembersAmounts[0x53765FaA9C2AD3a7fFA1C8B6F11eABA58BCf6f1C] =  141000000000000000000;
    bountyMembersAmounts[0x54Adb65d1447FE56BECd5ac2Fa30E6dA6A2E4894] =  111000000000000000000;
    bountyMembersAmounts[0x55552D38a83d1A7fe9859B670453736EC31f2De1] =  128000000000000000000;
    bountyMembersAmounts[0x558C2af073229D3B4B52a625E32f3fdbFD57593C] =  181000000000000000000;
    bountyMembersAmounts[0x56EDBAC3ac856c4331B8C0E459D69b12b899d2B5] =  200000000000000000000;
    bountyMembersAmounts[0x58b44E1b59aa0333255c62734f4E691937DAE911] =  100000000000000000000;
    bountyMembersAmounts[0x58Cd522a2480e93b5bFd671479AaB2141cdC03BD] =  227000000000000000000;
  } 
}