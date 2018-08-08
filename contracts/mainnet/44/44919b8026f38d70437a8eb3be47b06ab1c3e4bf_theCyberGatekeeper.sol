pragma solidity ^0.4.19;


contract theCyberInterface {
  // The contract may call a few methods on theCyber once it is itself a member.
  function newMember(uint8 _memberId, bytes32 _memberName, address _memberAddress) public;
  function getMembershipStatus(address _memberAddress) public view returns (bool member, uint8 memberId);
  function getMemberInformation(uint8 _memberId) public view returns (bytes32 memberName, string memberKey, uint64 memberSince, uint64 inactiveSince, address memberAddress);
}


contract theCyberGatekeeper {
  // This contract collects addresses of the initial members of theCyber. In
  // order to register, the entrant must first provide a passphrase that will
  // hash to a sequence known to the gatekeeper. They must also find a way to
  // get around a few barriers to entry before they can successfully register.
  // Once 250 addresses have been submitted, the assignAll method may be called,
  // which (assuming theCyberGatekeeper is itself a member of theCyber), will
  // assign 250 new members, each owned by one of the submitted addresses.

  // The gatekeeper will interact with theCyber contract at the given address.
  address private constant THECYBERADDRESS_ = 0x97A99C819544AD0617F48379840941eFbe1bfAE1;

  // There can only be 250 entrant submissions.
  uint8 private constant MAXENTRANTS_ = 250;

  // The contract remains active until all entrants have been assigned.
  bool private active_ = true;

  // Entrants are stored as a list of addresses.
  address[] private entrants_;

  // Entrants are assigned memberships based on an incrementing member id.
  uint8 private nextAssigneeIndex_;

  // Addresses / passcodes must be unique; passcodes must hash to a known value.
  mapping (address => bool) private interactions_;
  mapping (bytes32 => bool) private knownHashes_;
  mapping (bytes32 => bool) private acceptedPasscodes_;

  modifier checkOne() {
    // The number of entrant submissions cannot exceed the maximum.
    require(entrants_.length <= MAXENTRANTS_);
    _;
  }

  modifier checkTwo() {
    // Each entrant&#39;s interaction with the gatekeeper must be unique.
    require(interactions_[msg.sender] == false);
    require(interactions_[tx.origin] == false);
    _;
  }  

  modifier checkThree(bytes32 _passcode) {
    // The provided passcode must hash to one of the initialized hashes.
    require(knownHashes_[keccak256(_passcode)] == true);
    _;
  }

  modifier checkFour(bytes32 _passcode) {
    // The provided passcode may not be reused.
    require(acceptedPasscodes_[_passcode] == false);
    _;
  }

  modifier gateOne() {
    require(msg.sender != tx.origin);
    _;
  }

  modifier gateTwo() {
    require(msg.gas % 8191 == 0);
    _;
  }

  modifier gateThree(bytes8 _gateKey) {
    require(uint32(_gateKey) == uint16(_gateKey));
    require(uint32(_gateKey) != uint64(_gateKey));
    require(uint32(_gateKey) == uint16(tx.origin));
    _;
  }

  function theCyberGatekeeper() public {
    // Initialize the gatekeeper by providing all permissible passcode hashes.
    knownHashes_[0x1f9da07c66fd136e4cfd1dc893ae9f0966341b0bb5f157dd65aed00dc3264f7b] = true;
    knownHashes_[0xb791069990a7ac90177cd90c455e4bac307d66a5740e42a14d6722c5cccd496e] = true;
    knownHashes_[0xf1b5ecc2e10c5b41b54f96213d1ee932d580cfffe0ec07cae58160ce5c097158] = true;
    knownHashes_[0xd5175b77b10e25fc855a5d7bd733345ba91169a60613ba9d862e80de56778b3a] = true;
    knownHashes_[0xf34dcd7da457ab40a72eac7bcef81df228516accd299e45f957d3427da041993] = true;
    knownHashes_[0x5de22f4ee9f2a052ec2d74368c18abc926dfa6d3b3dd354d37f5984234a5a3b9] = true;
    knownHashes_[0xc59d5da97925031b90aec7b62b996266ddd6a770d74cfeda64f61fc36efaebb9] = true;
    knownHashes_[0xce2a155eb4425417b7e6c730d6d8f28bc5a488f3ae991b8658df67c668936b25] = true;
    knownHashes_[0x7c7d029792140de3231b5d0e423bcf2db32b645102481ff98cb3fbc596e7bec3] = true;
    knownHashes_[0xbba66841434f000b3b5dad2fee2018222234708b4452188b0409fb87c96057da] = true;
    knownHashes_[0xd8093508edc481156076857e1a3e06ff5851db83f93e2d0e7385d8095ddd91f1] = true;
    knownHashes_[0x7fc987227e8bd30d90fd7009d4f4e87cbe08449f364eb7ea8cc1e0e8963a8bb9] = true;
    knownHashes_[0x7d488c3c67541f75695f3b85e9e03cabf09776a834cae3bd78deff5a61a79d84] = true;
    knownHashes_[0xfe8e1d9cfd511f648f7b2399b5e1b64fae0146b17d1887dd7d31cc62785af5a1] = true;
    knownHashes_[0xbc29c06b1854055fa0eb833b5380702154b25706e91be59ece70949133e0b100] = true;
    knownHashes_[0xd1b524312fe1faa9afd4c6e436ac5b7ffc25508915ced29b6a3a5a51c3f64edb] = true;
    knownHashes_[0x2214001a578b2f4d84832f0fcea5fc9c330788cc124be6568f000e7a237e7bc2] = true;
    knownHashes_[0xbe8f2f005c4eab111c5038c1facf9f34cdb74cc223e62da1afb6e9a68b34ca4e] = true;
    knownHashes_[0xe47770d9ad427c0662f8a4160529bd061efc5b06289245a4f15314e01ac45a3e] = true;
    knownHashes_[0xd9047ca158ff3d944db319ba900e195c790f10e9f733a26b959dda2d77f3269c] = true;
    knownHashes_[0x337c6fd80459dd8a43819956a3efcc21321ea61b03df6d22c08a855a2fa21d11] = true;
    knownHashes_[0x0f52968d0e726c5abea60a16fd8e54b35bdf84f2f00e60b85e51dd1da01eac7f] = true;
    knownHashes_[0x73a6ef9b3a23b3a024ce61190cd9e25646fea63e07b7a108a4069becd17592e1] = true;
    knownHashes_[0xf4553c021ac8627fb248332a94b4cfdda11fa730a5fd9d3104c6a5ae42d801f4] = true;
    knownHashes_[0x020bea449c109c63f9f2916ae45efedb68582b53ecf5bc1976c2f227ddbcea92] = true;
    knownHashes_[0x389cbc4a0968b13b251e9749a09f065f7455c8e32c51ab9e70d0cfe88f19f0d3] = true;
    knownHashes_[0x56a1df9bf60a6537bd66813412c4dab60948ad50d589d16fbcc803ff7e1d8d0e] = true;
    knownHashes_[0xce32119e262e9efefddcefc72360f9bc264ed352f37e88ad5dbc8563a1f5dee4] = true;
    knownHashes_[0x3d0836543f5fa63cf9a33cf89c5d6d58fa1f4a7ef6176f4aa0c9af50a5bc537b] = true;
    knownHashes_[0x0a63047da6dc9766ee02d6966d1aa3314a7809d62eb1718107f48506f9f9457c] = true;
    knownHashes_[0xc53397f780d9bbd2a6f0f0c8bf49ac08ed4cdf64930106be00721ac4d4511164] = true;
    knownHashes_[0xe81581a9c2c27417ba4f3c81e0fced1d0f79d358ed920a22ae00115487f228c5] = true;
    knownHashes_[0xe77056c319963c193dea91cb38d431eff8ab57c3ab170010356b4eebc22d7e97] = true;
    knownHashes_[0xa1fb6fdf27ba9b5544e3f12fbd9132492357cb7e55380021f25208888e3630f7] = true;
    knownHashes_[0xb90ab683410780e5a3d0f4ae869a04895db390b4a7ef7da54978cb7276249f06] = true;
    knownHashes_[0xaed50db7524cf03c1b00786985d114bac77e4efc94ca8de1d5f38c1abf4f2fd7] = true;
    knownHashes_[0xb8e02c5490299d4213b7aa5e73b81ca81b064b0d9136a81151e462b4e25f9874] = true;
    knownHashes_[0x20f107570ff7f5b87bf5f2e3562cd5724c93bede48a295c0eb2bde13dc6a29b0] = true;
    knownHashes_[0xb716c58f7969bbabf290500b49cbd47d27127c8273d92400ae986459a25c0fac] = true;
    knownHashes_[0xe2e53269c9a713aea39f3cd5bc1d843d2333671f001e9370d8d0af7fd538da94] = true;
    knownHashes_[0x0bbb7d412d6b31f9a09dc1b0c907b460b1b537213e26ee81f9807f29adf4fd15] = true;
    knownHashes_[0x7ab04d4c5b09c1447723b60fbdca4b3413b6f98da157bacfb434e41e2b058528] = true;
    knownHashes_[0x825593380f76d0636b54113c15cc60af3fd5c084662fd29aec5b73adfa126497] = true;
    knownHashes_[0xfe997c3e94789f21f04c14663073b6aa991ac2a844128501c12e6ef600c06588] = true;
    knownHashes_[0x3971dc6245d6ac485f674d04c92b9405aad2a99c550f1bc0db4bbb90bf95adac] = true;
    knownHashes_[0x001e58093e36d3df6435032e8756c4a3d7194703d7160b54a53abea1daeebea2] = true;
    knownHashes_[0x7bd7049df9d6d237d4d140e15d442bbc36d854f11dd3f29d95431fbf588fc595] = true;
    knownHashes_[0x41a03b78069100aee2080531046c5225723682709011dfaf73584efddb0d721b] = true;
    knownHashes_[0x1e28fd49fa726dce14c54fd0e795d504cb331c8b093d08480e2c141e7133afd7] = true;
    knownHashes_[0xbbfac7d658b3afa5e3f31b427d1c6337c09385f68d8a5c7391344048a9933dcc] = true;
    knownHashes_[0xabce501357182c6bc33f57f0358ffd0df3593ab84b560eaafe4e491e1a57161d] = true;
    knownHashes_[0x5f210994b6ab28175f582caea9ca3d8a60bd95f9143d296963ff0fe15824541f] = true;
    knownHashes_[0x52583357b332063c6b01ebb1adc2ea1a562d9047ba229007f54e16cbd6814911] = true;
    knownHashes_[0xbaab52c2bbb7cd02a520d2b6bfec5a9551e3e6defa60a3032873e8416ee4467c] = true;
    knownHashes_[0x6ae2961dfef7f3e0aa12c15e7a681ca18f2950d2657565bf15131912ea8da7dc] = true;
    knownHashes_[0xf031e143e1803147f958dd4c6665e8719058d5caae195b70087f9b5271762df4] = true;
    knownHashes_[0x28d76ea4ef99de0fec59ed37a9fd26773973b3fe154e22c90417d321558122a2] = true;
    knownHashes_[0x537ac9bd7ee6bf9da81eb33526e6b276470fc054ec02970009d8619f71f9721f] = true;
    knownHashes_[0x8fa26dab73b295def62cfe7f5c43d14582d2b3618420ad5a5b268cc379198e13] = true;
    knownHashes_[0x7b84ca8a1ab1da42a485a6fee17b4d566f3381a7e7e45093f1b31dd0733e35bb] = true;
    knownHashes_[0xabb230a36f2e2b45edf713e502c17177764fe97fa723396345faa9c176ba1726] = true;
    knownHashes_[0x202f9f673d28dbcd395bdcb5947e473d0ac8db873531bd421f1554b2b20ff9c9] = true;
    knownHashes_[0xe212ec4baaa718fc89304b32b3824049830056aba2217e5dda7ab19a38674dd7] = true;
    knownHashes_[0x797fb4e70019a12d858f7ec6e36e0e094c5491595458c071731cf74d910ca93c] = true;
    knownHashes_[0x746f5fe170aee652feecbe538b3ad0379a5a55c0642ff09d51d67f96e547e1b9] = true;
    knownHashes_[0x808dbf279f6ebaf867dba8f57e7e0985c0af3514e12bbd9179b76305873aa62d] = true;
    knownHashes_[0x58174ff390f50845020d81f58dec307980154bfcbcc2a6e52c8f00571fc4c18a] = true;
    knownHashes_[0xd21dd7a15bfe2cceed46b2545ba534371194c4243b0892d646a8c5a5af65d6cc] = true;
    knownHashes_[0x73aa239023dd8d73a9f9fb28824419078c3f714ab4486efd84781c683d71a839] = true;
    knownHashes_[0x691e364238f0b50f5aa51ea1d4433bf2efa59fea0be8b9c496554cb39498467a] = true;
    knownHashes_[0x46b4a5160c82b53114bfcc1474f38f7c43b6492bc3b9596d613defeaf8b89e97] = true;
    knownHashes_[0x8f88f909ffa924d4e3c2a606afd35c63d2a428a79a85576ff4930fac15de9fae] = true;
    knownHashes_[0x64958df63263f0829b0c0581bd29c3ba2c98303c4d1a5f498e1fbd9334b987e7] = true;
    knownHashes_[0xe055613d9fb1e64b10f2a19d23e0f210a62c77890c64f36ef19b7f9c9eeea73f] = true;
    knownHashes_[0x58d386f526477b55f07450e4bda7ebe5ba5a24c6a1de2c2a0589136e26455502] = true;
    knownHashes_[0x34a80f3e9802bdff7e72af17a101ff9f66a318fdab40aed5d1809fc5f2cc1c9a] = true;
    knownHashes_[0xd4f0c8fe0948d41171c9c9ce1d75ee424c8a88a240ef6e430e3e96a40f6276d4] = true;
    knownHashes_[0x1bcab73811b8ba9d2dad89dea585e5d714a1e599bce4577d19d2b43b7bf87fda] = true;
    knownHashes_[0x10028a06bc48264ae4c6a600ee386fa468b2aaa6e5b5645a1a6e31253228b8ad] = true;
    knownHashes_[0xde8d4db07409be3619916cbc1879b26c7e11b5b5a70e7d881af0c2fef29d7318] = true;
    knownHashes_[0xa5eef6d39384b151fdafb99544cf084e6c7a066fde1bb0b9ceae0821e9e2cd10] = true;
    knownHashes_[0xe3ca8dc2d344788fe4481650673ec321808a3997c8909fccd45b233ec758a393] = true;
    knownHashes_[0x9e6b8ef37fe278d3e8786e3c690e8d210b028e02cbd3de1cb7e4f195d07b8110] = true;
    knownHashes_[0x2688230319ac3209d60a958ecc1c6f9b7bcdc8f0b3b205593abfaf3e3cbdf77b] = true;
    knownHashes_[0x7b9bdcab954cec08267474edd4efd3f9404a9cb01d4daaa601a20bf983431904] = true;
    knownHashes_[0x43207aebbf8c583423271f9eb7902c2ec44ac0c4f352ab1819246832f4c0999b] = true;
    knownHashes_[0xac0266245ff71cc4a17bb0f63bc04d9666ddf71dd71643f24cf37e36bc4f155a] = true;
    knownHashes_[0xfc15e3c5983cc9cc686b66d89c99e63f4882e3d0058b552b67bfe2f766b56950] = true;
    knownHashes_[0xe804e62dd75bbe482087ab2837502f73007e1a73eea27623885dfbfe1e2fb0ef] = true;
    knownHashes_[0x13c7f7862f84b2c7a3954173f9c1d8effa93645c00bbd91913545541d2849b39] = true;
    knownHashes_[0xa873f8ffa13ce844fcaa237f5e8668d04e7b0ffc62a07b6954fd99dd2ec4c954] = true;
    knownHashes_[0xeb6f877cc66492cf069da186402edaab2fec618959323c05ecd27d6363200774] = true;
    knownHashes_[0x6c11b3fedeba28d1d9ecc01fa6b97e1a6b2cca5ccbb3cfcd25cfaf2555fd4621] = true;
    knownHashes_[0xa671809122a1d712c9953a2a3dab991bec0dea9dac04039674a48ce69307342f] = true;
    knownHashes_[0xee891d79c71c93c9c8dc67d551303fb6b578e69673207be5d93f9db8bfc65443] = true;
    knownHashes_[0x203530873bf7a0e21437d19fac50ad66b5d900cc5695d924091502c57e68b404] = true;
    knownHashes_[0x31c193092d0122b4bba4ff0b15502ccd81424d9d1faf6eb76dabe160d38ab86c] = true;
    knownHashes_[0x30437582c6835f6855ea08e4e6c9eb22b03445b3c9fdbf8520fb07b122db22a1] = true;
    knownHashes_[0x72be9f48790e00f9e4c3a12e3b76fe33ffa9f0e8fff75b711ad1158a2d96161d] = true;
    knownHashes_[0x19d429dde2aba4c05a71858f6c770dbf2007982a45514109089b135401ba97ab] = true;
    knownHashes_[0xd3f357697501c25321843787edc511fe9c4580fcd386617524fd71372a987f9e] = true;
    knownHashes_[0xfaefd15cd398d7f18a62f2b2b9282ec8706fc024fc95dbf35d44beb1e2e9b317] = true;
    knownHashes_[0xe499335f5a14d69d72b210691255ba1a849fc5b358ceca4e737ae99896aaffde] = true;
    knownHashes_[0xafeb5f1c9298777e8b9501cb812afbdbc551a7e03e4e2de437fef3eef0d89e3e] = true;
    knownHashes_[0xae48b79855ef93cc35d5776322242fabdb4a53fb7ff84916a3f7d3f665914e1d] = true;
    knownHashes_[0x5a6160a4fc39e66e69129aff6942405d07a3d3e81242bdc40b3af6aab7ae3642] = true;
    knownHashes_[0x9c76da2121f984e4c7bca901f474215dbce10c989894d927e6db17c0831fde30] = true;
    knownHashes_[0x5ecb6ccb02c15de47ddabb85571f48ae8413e48dd7e1f4f52a09a3db24acb2c5] = true;
    knownHashes_[0xc97f43a2a7aa7a7582dd81a8fc6c50d9c37c0b3359f087f7b15fb845fe18817a] = true;
    knownHashes_[0x2a567f38f252bd625fe9bc0224ba611e93e556f6d9fad0fc9929276120616f2f] = true;
    knownHashes_[0x86032752da8b70e1a3fece66bb42c2e51d5c1d7db7383490beb8707b544c713e] = true;
    knownHashes_[0x2bc1f494fade6a385893a9065a7b97d2aac775dc815639baafa7926de4f582df] = true;
    knownHashes_[0x3967c9d876382dda4dd223423d96d08fb3d9ee378a88ab63171543ac3a6f1a4f] = true;
    knownHashes_[0x9ac8fc599ce21b560d819005a1b22a6e4729de05557d5b3383cd41e3b13530ef] = true;
    knownHashes_[0x83b4b01d4238485529f01e4b7a0b2a18c783c4f06a6690488a08ad35723f46d6] = true;
    knownHashes_[0xe16362fabfbfab3bc5b52441e6f51b1bd6ed176357f177e06c22ea31a4e0490a] = true;
    knownHashes_[0x2bbec2393184e20e04df7f7ebf3e0a40f18f858ef24219e3e6a4cad732d2a996] = true;
    knownHashes_[0x26b9f114b862dd1fb217952b30f0243560c0014af62f1c6a569a93263da2ed87] = true;
    knownHashes_[0x8f50db6ad0f6b20a542c6ce2ce2ca88a5e28040499ad82050c5add5b671fbebb] = true;
    knownHashes_[0x31853fd02bb4be8eef98b6bb8910aacbaabdb6e7bb389c15e7ffa7cc877a2916] = true;
    knownHashes_[0xda6d55fafdbd62c3224f3c2a309732c141186846e72fbc1ba358e3005b0c0192] = true;
    knownHashes_[0xede6c624b4d83d690b628296696008e32afb731951b0785964557716ee17938f] = true;
    knownHashes_[0xf92e82d93f432af59aa615fcc1f320bfc881f8edb6c815ef249ffe1d581c118e] = true;
    knownHashes_[0xfd3465d044cfe45ed2b337a88c73de693aaf15e2089ec342b606053742c2d3d8] = true;
    knownHashes_[0xe67d0e588eda9b581e65b38196917b7f156c33b63a7b85faf9477161d80c3fa0] = true;
    knownHashes_[0x17ec4ff7ca53560624d20a4907a03db514e54167a07c470a78e8be670569eb1e] = true;
    knownHashes_[0x801f7c51809e14a63befb90bdd672eea429009ba0fb38265f96c5d74f61d648e] = true;
    knownHashes_[0x030b09c9fc307c524f015349267a9c887a785add273463962174f9a0bca8eade] = true;
    knownHashes_[0x32c740329e294cf199b574f5a129eb087105d407fe065c9e82d77d0e7f38c6df] = true;
    knownHashes_[0x4f5d91e1926a0abfc33cbbb1fe090755b3fa6f6878b16ddb1f4d51c0bb273626] = true;
    knownHashes_[0x1c347666ca233e998ccad5e58d499db78693a2880e76efef3f39ea75928aa3a7] = true;
    knownHashes_[0x86983f6f4376ef7fc0e1766ffce4b7bea3e34e023e941a7b7f82638ac72c660e] = true;
    knownHashes_[0x208d1fd0ad5b8f5d2d5239f9317b95cf11beac22780734caf8571ab4b0520d0d] = true;
    knownHashes_[0x9bdaa1a0d2f8e41777bc117b01bd1c75d7ef6233c204b3285a47e4fedb319e69] = true;
    knownHashes_[0xfb473f02109ef92a443b981b604a8991757eb0bb808ea5bc78e7e870f2354e62] = true;
    knownHashes_[0xe8a6cfdc3e580f2eab183acb79e5b86a3e9da4f249f74616046d6d29fcd4fed2] = true;
    knownHashes_[0x32abc540ef3bc5de09a23af1f982af2559fc2186036c599b3433d016b1a540a8] = true;
    knownHashes_[0x659a7368d541323bd45fc1877f7f1f30336ef11752e74114bd266ef54f7af614] = true;
    knownHashes_[0xc47854c4eafcf5d12b54b1eb0f4054029ee2a621f8a3e466512f989f9f3766b8] = true;
    knownHashes_[0x51ab11caa29aa797b6707bde74097b6b2a94f2933f67e829d5404511a04b9eee] = true;
    knownHashes_[0xd231100d8c758c8b96008206667beb0da75c8bdf5ef6372973f188a2f8479638] = true;
    knownHashes_[0xf2667981d338ea900cb94ee9b1e8734f402c6f97a5c26e025000c24495b5848a] = true;
    knownHashes_[0xd1bfe76a924b0f7375b5cfb70f9a9a38bbc4b0e0e954b4fd79c6a8249c8024eb] = true;
    knownHashes_[0x4461388e97040af4f18bd39fb43f6407c1dc0c97367493c71fa09e9ad0c041f3] = true;
    knownHashes_[0xaba9866a1182958298cd085e0852293a8a9a0b32e3566a8fc4e0d818e6fc9d1f] = true;
    knownHashes_[0x0fa820195b7911118b04f51a330222881e05b872bb6523c625ba0e44d783e089] = true;
    knownHashes_[0xf7fae749c6d9236a1e5c4c9f17d5f47e03c5b794c7d0838593a59c766b409fb1] = true;
    knownHashes_[0xd452a19b707816f98350c94bedef9a39d2a8387e6662fbf4ce1df2d08b9bbfce] = true;
    knownHashes_[0x88c601f5dbc07046d3100ba59d1d8259a2252494fe3d44df2493154f81cc6e83] = true;
    knownHashes_[0xd63bad678338c2efcc352bc52dc6d746ff7ad69fa3024a4c066242a5e017223e] = true;
    knownHashes_[0xbdafe5b7f2fb13e7a9d15fde4c20946aa9cf503d87c13d5e2b1f91cba24d6d02] = true;
    knownHashes_[0xf3e4c26fc4270c96091163d1f821ca1ee5e3e2cf38cbddb72ed0f016bc0cc301] = true;
    knownHashes_[0xe5d663f995b932d671a4239595c3e21bdf5eed4f387abf490064e110f815e13a] = true;
    knownHashes_[0x56e513d0909163ceb5c909f0a4f4996041e6f7dce868bea19e455160c73e0087] = true;
    knownHashes_[0x85dadba5e967d35663a2edc0a2854f2176140f2c5362199a7c1aeef92a23965f] = true;
    knownHashes_[0x31a6ee0d2173eb805ea73e2505ace7958a9b6b79f017eabe73dd20449202cc73] = true;
    knownHashes_[0xb0114eb4170b3a6089c93a3e6f3ca1ab430259cd01cb5c0d996ae2fed4ab8713] = true;
    knownHashes_[0xab882a2dc74f2cf4303d5042c19ca8c28b9138d41cfb92d1772a7db0f03cdcbd] = true;
    knownHashes_[0x750caffb2fc2e58326276d6626d58fffb7016fc2ca9f32db568c2b02d1a7e2e4] = true;
    knownHashes_[0xa0f68eb20c40da255433c06088ce4b5a92a29a39a431fcd5430caf46a55cfef8] = true;
    knownHashes_[0xf3b4aea050789d0ce0c09becf833057f37a512b19c09258bf27912c69748f81e] = true;
    knownHashes_[0x7a624c215ebf005e463dfd033a36daf69490c0ebf65a9bdf3cb64421e39290ea] = true;
    knownHashes_[0x1a83e43e04aeb7d6cd4e3af4b7c0761dacbd47a806c52eea0b90e26b8cc4d52c] = true;
    knownHashes_[0x0f7dd58c9f0617e197b0255ea9eedbb2cb1055e9762821bdfb6ebc89bf2cbc69] = true;
    knownHashes_[0x91110c6797d18867583e4bb971e8753c75a35e0bac534070c49102db7acfffe1] = true;
    knownHashes_[0x7487dc4230fdb71b3ca871b146d85331393b6830c3db03e961301e98b2f0ed83] = true;
    knownHashes_[0xe947fa9a35038f665c8eba2ed92e1a6c90dc08d463e378718be7e0939ccd2634] = true;
    knownHashes_[0xdcb1d082b5e889cb192fe66a0e4fef8664bbd63b4f5469bb6f41b28cbaaa2f08] = true;
    knownHashes_[0xe79a4da1c0dfd3183d0b4409faf9e5a267ada85a188cf26b37b4ffe1846d6f9f] = true;
    knownHashes_[0xbd63b716bd0133ab86e7781876c07ac130ba64c60628f81735b2ca760a6450c0] = true;
    knownHashes_[0x270a38dac311171970655d2584780fd2625f255053933f4863f2f1022e5ae99b] = true;
    knownHashes_[0x9472b387fa469e3dbe8b3e7a8aaa7054d98b7424d60e5f36c964a16c8fcdbebc] = true;
    knownHashes_[0x5d36315425c7e9699328e3f4c0962d40709c0cb78a7b72a015aa31caba784450] = true;
    knownHashes_[0x745367e8d87e841c203ccacbffc361affe39a16e69b348f99cf5fc04c00d6b7e] = true;
    knownHashes_[0x026d05c886b8530bef15e25ce3f915306624915a2edd7309d7c063c8baadd80b] = true;
    knownHashes_[0x0bbaf4ad40972b1d9aec644660790c7707976757305e4e2a0085af9adf444b31] = true;
    knownHashes_[0x13b72741563ee1d9e3e0df5cedca9d185b29dc0adc3d08a1c26fff4cb61b70c7] = true;
    knownHashes_[0x891bd970b36e5b892a8e43a153b5b1e199223d899808426b894569fb1ad3224c] = true;
    knownHashes_[0xe5dd6ba9a4647c35099ed76802c6f2aab16111f5994fd7c86598ef717693d33e] = true;
    knownHashes_[0x556c98600314be469b3d68e6909b68f32fbd7d2b8804bde2362b4f79148fcfde] = true;
    knownHashes_[0x0ea220fdd96c8a55b3b1feee9a67075dc162c3c6354347d4191cc614e463aa96] = true;
    knownHashes_[0x5388e66877be80f1599716f76d563dc4fd7f7dd6f18fd5aa173722c30df66283] = true;
    knownHashes_[0x9cdd8250621aeb3c88e919a8784f3d12828e10bd00403dc4c9e6881c55231a71] = true;
    knownHashes_[0xf502cb4dcbffc203db27df091b916ee616cdad39f662027ef3c9054d91c86c32] = true;
    knownHashes_[0x40c6b9be0005aac01c0d89d7e666168a83e17d5164b3fdb5bdf7cbb3e4770144] = true;
    knownHashes_[0xbff7468379d3a8a18637f24ceeada25214b74e91761d4950732aa037efaf46a6] = true;
    knownHashes_[0x52fc4c96b1eff265a5e78eb6d9b54e72e99bf31e89c99c4366e46cb757775cbf] = true;
    knownHashes_[0xebd7bd878a40ef58bee78d9ed873553b6af1ad4536fefd34e23dfca3d50206d8] = true;
    knownHashes_[0xf4a53103da3a424f705be1197d5d7edd58f395d81f5e3f6b912d4b1657cb656e] = true;
    knownHashes_[0x08e442e4dbae4c612654576a3b687d09b00a95ca4181ca937c82d395f833ae1a] = true;
    knownHashes_[0xd37e725b67a1003febdbae5e8a400af1d8e314e446dfcde2f921ac5769cd4fed] = true;
    knownHashes_[0xc199f1e49e8167a1684cd9ac5def4c71666bf5d6942ff63661486e139dee13df] = true;
    knownHashes_[0xc2af103fccfbf2a714f4e9a61d7e126996174a57050efcabe9e7e9d17f7ac36c] = true;
    knownHashes_[0x192240627f8356ea1caa66f75a4f2d4a4c9f328e76ce7c6d4afbd0645cf6998e] = true;
    knownHashes_[0x649a262b9674ef27f69a67a495feb49ec699657e250fe0e7a70a7e2091b86ff0] = true;
    knownHashes_[0x754178f9c0b70450f40416ca301354b39c5551f369b0057e84e877c0b59229b4] = true;
    knownHashes_[0xa3183cb641d72735e222815990343ee2f64a8ea1f3f3614c674987cdae454468] = true;
    knownHashes_[0x2581e9080a7c9695cb4a956144ff6478a5ff9005575c17fd8837299e1c3598c6] = true;
    knownHashes_[0xe7bdcc139d0f937bd1ef258a4b17b76daf58729eaed4ef5d8181842be119086e] = true;
    knownHashes_[0x5fa0b5b4ee49a272223effa7789dac1d0c97f5476a405968b06bdcf7e6f70c8c] = true;
    knownHashes_[0x6cf76f5d49f99cf3b6384d40d6447dba5db5e46af199e8c2876c580aa6c9ab43] = true;
    knownHashes_[0x5e5423c6d508ab391aabd4d842edc839bc54742df2bd62ec4a36370b9744bbeb] = true;
    knownHashes_[0xbb53ab62aa4fad4bcf86f6757e8fef8b022eab4bc17965c4a84842d54083b479] = true;
    knownHashes_[0xda6a6e12dfc7105a144bb0091ae1d419bd79a926fb3783ec13cb9658bd8b5bc2] = true;
    knownHashes_[0x0028cc8aa613b3f53cde95a59e5f3d78b1a5d370909836889920e818578b95ee] = true;
    knownHashes_[0x5ff151251e10f03bea31e7f83160bb1adad9df1f11c0ebc161c5c9330a87db8e] = true;
    knownHashes_[0x1056ee80df6c3c776f662138689c96107fd4fb0c71d784a85c4639c0f30a6acd] = true;
    knownHashes_[0xc9b5d332e96f7b6a5bb2d44ca3d847a5fca5ef4b2cde5f87c76e839d70ac95e0] = true;
    knownHashes_[0xed3515ab11fab92d1114b7e1f0736ecff17794ad1a5f76003838971c17373b39] = true;
    knownHashes_[0xaeedbd57c74386217a11806cb3ac9acf6661bc40b36d0fd644a975c5f6b54426] = true;
    knownHashes_[0xb15bc9952eae5559a85c14abefd0bf23c0066e5c63807fd83f6ca8e07cf8ac0f] = true;
    knownHashes_[0xc77584eb3625f35588eebc89277d71dcb53454aebb9176c9232b77071e7b5bd7] = true;
    knownHashes_[0xe17aab35ee48eef0707ece1c94464115ff39214963dfe64571fd0529443f464c] = true;
    knownHashes_[0xcd6619186614342e042f16bdd8508d4fb7a86a4734285f908889f3ac14d94cc4] = true;
    knownHashes_[0x1e6a469a9820448aa5fbcf146eb65fa54256f0d0d38d9a5db9598170ed4e5159] = true;
    knownHashes_[0x56e8db690925fd8fec603795b72187c727ed019772bb11e92015bd4227ea0de6] = true;
    knownHashes_[0x30df18b198d8006fcee31c5ab03c21599003902c38a0d46f89c83e0a50cdc722] = true;
    knownHashes_[0xc7ec2f5603c2664505cc16b9eca68a3a34cf0ef7caff5d9099c01f1facffcee6] = true;
    knownHashes_[0x37862b072052fc1b88afd2c8869b9a78a5bda139beba1c986717ec1fd526d61d] = true;
    knownHashes_[0xd402c6c43bd8ccdcf43b800168f1065d0d2e95d6cd8f48dd94a3a70078fd7f96] = true;
    knownHashes_[0xa41d986a203c53f553f63aa5f893146f25fb23754a37cc32d95f1312b0d1f58b] = true;
    knownHashes_[0x14b4feedfece7eb6df8faed2c7173b87f715a14c9d27ca88979bf3dd5d64605a] = true;
    knownHashes_[0x8d643ca159260bc55434f0f40552e88520c4d0217497eb540803b59f37f4120b] = true;
    knownHashes_[0xdd1a85c09957e8ad22907f83736ab3fd54742b1dce5ca22a0132970fdd4df6e0] = true;
    knownHashes_[0xec78a0437bca2a714d146b10ad6a5ae370794ff0c7f4ff077eea7b302e9ce1db] = true;
    knownHashes_[0xa20dd3512ca71ac2d44d9e45b2aec2b010a430c38a6c22bfb6f2f0ba401658f5] = true;
    knownHashes_[0x1f54cdbcec5639248461fe067a56a3bf3c03a16b0fa92f8128b585930157a4a3] = true;
    knownHashes_[0x258297a15ed3175983a05f7bb59dcc89fab5bb74ebfa7aa84cef74e7a35cefd3] = true;
    knownHashes_[0x432b0c57cab4566f47ae7f942ec3db7496c44fb211165299e49244e5feeb63fb] = true;
    knownHashes_[0xd4e325fae344777ddbfa91c405f431bec4419417245ab92bb04612d18c939309] = true;
    knownHashes_[0x08014c3be305fc7daafd910e3e286a1161ac5ccddbb1f553ae1fe67924bfb2f1] = true;
    knownHashes_[0xcc025016f45b21cca83d50d6b4e94b548869bb8de5c5a710091c9d64bd37332b] = true;
    knownHashes_[0x1cdb6bbc3a17c535d44cbe575669436ee7028e475e5fe47f7f98489439783f33] = true;
    knownHashes_[0x2976844209c565893bf4ffadb7a27f3fd96f2458bd40e5b49ebffae5ae0caedc] = true;
    knownHashes_[0x2cc94faaab298fbdf4af4d2fb86f6450bb708f18d3c3ebaa9c23e240c6f22325] = true;
    knownHashes_[0x5ea72f0a677eb4bc6dcb8343786fdee6f278ebd1b4d740f8cdc212bc451b6eef] = true;
    knownHashes_[0x1f40acf6a57ce9982c2b1135499b6c893b37a1df1bdf84275cf137cabd53ce50] = true;
    knownHashes_[0x3c36abe94eb067440cd9fe1006f6773e2b27548d0a306bcb168a75392b3b6297] = true;
    knownHashes_[0x049b381e7b45aba6dfd343331c4b56407b2a157dc878736ada0e9debecb68852] = true;
    knownHashes_[0x3981aab8ca4b4d2565b5079437d6ed0e10bc60c3016c5fd67241970f36d28f5e] = true;
    knownHashes_[0xe3674f344f52839b210a40d41a363ef8b1a2c049afe9b109c56af4d991fb86f4] = true;
    knownHashes_[0xf14978e47cc74f2a6dc7bd883f7dc4a3586ea2cd89f17359bfca73bc2a1f3977] = true;
    knownHashes_[0xe4b502345d6eb2938a811063515590368ec108bb434b0b39e9a42d776ad5fd64] = true;
    knownHashes_[0x7350feff51762a0bfc5e878deec872b5eb79427f3bbb2688b97d59b3b8257196] = true;
    knownHashes_[0x68d678bbcbb4519bc266cf4bb8f54a65c8dcab63d6fbeca7a1c1b58ce55f7d1a] = true;
    knownHashes_[0x8a2eb9517a8ca7e31a58a80880977f3b29b5649e09de0d10e2d40ce3d4a87bbd] = true;
    knownHashes_[0x49fd5256632a2565ec250854981f5ea3c1668e0cdf4979231111a464643d571d] = true;
    knownHashes_[0xa5e851c89ca2925f18e9eefa4855faa4c69d2c12b875bd1bbc233d0c81baf4a3] = true;
    knownHashes_[0x5d42e9a67094bb8cb3c2f078d1e02e722e9b44e6931dea3fc361b0c6b71a6424] = true;
    knownHashes_[0xd17c550587cc064af20dfb16f8b9e7ce07163cc4902cf67c94e09e94781ab45b] = true;
    knownHashes_[0x2ac1bbd505a0382f5b79f65aa5e768b6f956120e1e9adab1700e882aa2b435e9] = true;
    knownHashes_[0xd820d64bdcd12ec6c4ccb6eb857afd4f3e3fba039c60482d8eb17ac518e60ae4] = true;
    knownHashes_[0xb77c2f467217103baa4742a68f663b09bf01785653871eb9997f082378694e50] = true;
    knownHashes_[0x1e441e30ec1bd4475f9fd50008e80c36956219a76b98516115391b6a60a6e2e9] = true;
    knownHashes_[0x7d4d2f49945d4b0a6bdbcdd40feee2b6b76f4b5d34ddfd6a3e9d7fc93794a89b] = true;
    knownHashes_[0xd6e6ebee9bb19de629e56750211c2ac5bc018ccf00cc0d023cdcdc3f7de0258d] = true;
    knownHashes_[0x51198dd5ad4ca7ccb0112193f76e8d8325e66c0872da68e1e0a063363e0d28f7] = true;
    knownHashes_[0xa3f29b1ff1f4e8136b9b2f669494490704d13606b73aac04def08d95488d79c1] = true;
    knownHashes_[0xea3f1165ce868ab19978dcd32d7fe78fdc8dd26162057b54dc1c8f688332f0fb] = true;
    knownHashes_[0x7a2c8e589c3570c9dd8d3a4031a65b2b164c5b0f3cba0d610228351134b87d24] = true;
    knownHashes_[0x3e8d8eae37904d8a467efa882b1559a15bcbab3c02ceceaa34c1366855b31a4d] = true;
    knownHashes_[0x9266948ade2d86ef12bc0d38d4a98ebd1ff3d2046b2cd3150f47e6b41eb6c9d0] = true;
    knownHashes_[0x0ac0867e5d3c943115e715a3b7d129e63fd65c29fc3b2a0c75e245e8cc8e3cbc] = true;
    knownHashes_[0xc79ed203ef26b7e228dc957ee3581e87f76a03773756729f9a6e17953d78258d] = true;
    knownHashes_[0xd144249c42697104457147d9774e937cd9ff668da8133b4e9c7b14ba0d9c3745] = true;
    knownHashes_[0x984aabaf91e006bb4176e31dfe2e969f4c012936cd30cc1b0fdcca5173a4f96c] = true;
    knownHashes_[0x251a654a0a08c10ff2f1ee8d287f867c1dab7e1e2b7e1e76efd07e8c57e415de] = true;
    knownHashes_[0x887b4b89c813bbcea7ec00143867511bdbc5ef37042d9fb0a2fff2e7ac367a0e] = true;
    knownHashes_[0x76544c577c6549c6f3918fa0682388917cd893afbb957123cbfb898fe1518556] = true;
    knownHashes_[0xa19ac2a03c0c89cae8ee0c2db1d52b21386b710a83f810689ecb47c864fb2a55] = true;
    knownHashes_[0x11b2accc5b3d1d6af103f4048b62aed897f9a5e2d74669f8b389c706633b952c] = true;
    knownHashes_[0x1d8110d1e28a617a3d438aa479212ac8cb629c850286a7bd2d37ce1b3c73a6c0] = true;
    knownHashes_[0x8fa2a550db50cba22e90916d6decd9b4077b99eb4502e9ebee196f8c4b6fd41d] = true;
    knownHashes_[0x1c95cfe3e934357573c4fc494b14a934b664178d2658af1d95a249b4747e623f] = true;
    knownHashes_[0x4a7fdd5ecb85fefbd134037c54563b106883cf88d13d991e1315920b0e5c8a6d] = true;
    knownHashes_[0x168471be8819a5430ed54c076cdce0da303e00b88db692f9fe1e663f46afc2ab] = true;
    knownHashes_[0x4b8c86ceecef46755965c3b795bb3247cf90f524f201d532fbecd2be655dc908] = true;
    knownHashes_[0x61378c6396fa218e2d3df700d2dc02fba667df7a5072c805cbb2fad2fe9d00d3] = true;
    knownHashes_[0xad1b8c3ed94e252cb3671a2d3d404ef8844d3130e3a3ff87e0914a797bbbaa73] = true;
    knownHashes_[0x6c8af6c4484fca40444f51f9798915f19fd0a0dcedff06ade434d7ccc6cbf404] = true;
    knownHashes_[0x10d43739be9d4a2db0c9355129b3e1af634b049a2c6eae9cf915ee3ef27cccb5] = true;
    knownHashes_[0xebf68de80643eee9b471aa39a7f366a076fb305f0a1adeb726206ed0cd5a2bc9] = true;
    knownHashes_[0x506ded3d65c3a41b9ad502a8c0e685786058861e0c292c9fe075822d987d357e] = true;
    knownHashes_[0x051e531490eb2ad5a160fbc5b7b371ea6e20102635e3c612116f1eb117c6dd2d] = true;
    knownHashes_[0xf6009b990598b0ef14854eb38c49bc22c3a21606f84df02ac85b1e118bb90e77] = true;
    knownHashes_[0xf44e63fc8a12ca3d0d393ed67b84a6e8d857f4084e2959316c31a5c6bd6ae174] = true;
    knownHashes_[0x6d0cef3b24af04cd7666950e8950ec8da04900ed7cc01b8dc42737ddd810facb] = true;
    knownHashes_[0x9c766cb211e0036d3b11f70de1c960354d85c6e713b735c094e0040b4f61ca3b] = true;
    knownHashes_[0x50f41f1f7773962333b3260e70182962b13552a3e525085063ffa5bd26a960ac] = true;
    knownHashes_[0xe3b258e4c6c90d97f647586e1e53ea268cc851f13e69e835977b6b8399fc2cbd] = true;
    knownHashes_[0xe341f1ffe620d9de97b15169d1fa16d885fef299d52f6a0a7989dc0eafa76743] = true;
    knownHashes_[0xe7dfb8186f30e5d7844c72314448cfd059b070a41322d5ddd76cbf3e588b9dcd] = true;
    knownHashes_[0x07aa797be1bd3b701056405361160c2f62de1e5a452d9f0fb8a5c98ddf4bb255] = true;
    knownHashes_[0x92f8937ed2c57779a3697d9223ab17f598396f9802028bd3a34ec852413c60f4] = true;
    knownHashes_[0xbdf0a9d32af5ea64ef0d553b8b3fc0a4fd3101bc71b3cd57a165608efa7cf7f6] = true;
    knownHashes_[0x25ac304efba4df87b0d420c8eb8311b9d3314776176536e1d2245c38da938c13] = true;
    knownHashes_[0x417e5ab8e8e090d6cf05a551f629eac9c7fbc73b30a3ed8a2a2d4f4bba37e165] = true;
    knownHashes_[0x104a2b6fbaeb34315c8da0c6ced20f05f4702ffd81a31516813b9f771f3454b9] = true;
    knownHashes_[0x9e62e0694ed13bc54810ccaaa2dbb67ad1eb75d94dc53cd66ebc45a9cce9635d] = true;
    knownHashes_[0xd7b83539794844e00f1cba1d3b05297e9b262d1bb2fc91ba458d3c75d44ea6ca] = true;
  }

  function enter(bytes32 _passcode, bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) checkOne checkTwo checkThree(_passcode) checkFour(_passcode) returns (bool) {
    // Register that the contract has been interacted with.
    interactions_[tx.origin] = true;
    interactions_[msg.sender] = true;

    // Register that a given passcode has been used.
    acceptedPasscodes_[_passcode] = true;

    // Register the entrant with the gatekeeper.
    entrants_.push(tx.origin);

    return true;
  }

  function assignAll() public returns (bool) {
    // The contract must still be active in order to assign new members.
    require(active_);
    
    // All entrants must be registered in order to assign new members.
    require(entrants_.length == MAXENTRANTS_);

    // Initialize variables for checking membership statuses.
    bool member;
    address memberAddress;

    // The contract must be a member of theCyber in order to assign new members.
    (member,) = theCyberInterface(THECYBERADDRESS_).getMembershipStatus(this);
    require(member);
    
    // Pick up where the function last left off in assigning new members.
    uint8 i = nextAssigneeIndex_;

    // Loop through entrants as long as sufficient gas remains.
    while (i < MAXENTRANTS_ && msg.gas > 175000) {
      // Make sure that the target membership isn&#39;t already owned.
      (,,,,memberAddress) = theCyberInterface(THECYBERADDRESS_).getMemberInformation(i + 1);
      if (memberAddress == address(0)) {
        // If it is not owned, add the entrant as a new member of theCyber.
        theCyberInterface(THECYBERADDRESS_).newMember(i + 1, bytes32(""), entrants_[i]);
      }
      // Move on to the next entrant / member id.
      i++;
    }

    // Set the index where the function left off; set as inactive if finished.
    nextAssigneeIndex_ = i;
    if (nextAssigneeIndex_ == MAXENTRANTS_) {
      active_ = false;
    }

    return true;
  }

  function totalEntrants() public view returns(uint8) {
    // Return the total number of entrants registered with the gatekeeper.
    return uint8(entrants_.length);
  }

  function maxEntrants() public pure returns(uint8) {
    // Return the total number of entrants allowed by the gatekeeper.
    return MAXENTRANTS_;
  }
}