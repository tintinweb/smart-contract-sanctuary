pragma solidity ^0.4.18;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;
  address public agent; // sale agent

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
  modifier onlyAgentOrOwner() {
      require(msg.sender == owner || msg.sender == agent);
      _;
  }

  function setSaleAgent(address addr) public onlyOwner {
      agent = addr;
  }
  
}

contract HeartBoutToken {
    
    function transferTokents(address addr, uint256 tokens) public;
}

contract TransferHBCTtoHB {

    bool transferCompleted = false;
    
    HeartBoutToken tokenContract;
    function TransferHBCTtoHB(HeartBoutToken _tokenContract) public {

        tokenContract = _tokenContract;
    }
    
    function transferInitialTokens() public {
        require(transferCompleted == false);
        
        tokenContract.transferTokents(0x42cC2E32AcE9942b548B9848e6dB4bB838F4C2a0, 10000000 * (10 ** 14) );
		tokenContract.transferTokents(0x42cC2E32AcE9942b548B9848e6dB4bB838F4C2a0, 10000000 * (10 ** 14) );
		tokenContract.transferTokents(0xf6bee875b8099f8Aa58b8b14C8DfD45322a4e215, 83540000 * (10 ** 14) );
		tokenContract.transferTokents(0x0d25e4699feB3d64380B2654a95089C80E8B1614, 417700000 * (10 ** 14) );
		tokenContract.transferTokents(0x5b38b6e2a4A3ac9AecCD4F99930998C5b4D17667, 584780000 * (10 ** 14) );
		tokenContract.transferTokents(0xa6408f70726f1407FCee6D3Fb0d42a30F8ebb2C0, 751860000 * (10 ** 14) );
		tokenContract.transferTokents(0x9a86f6E59fF08F9b485019cF1cD17Ce43eEaC37f, 292390000 * (10 ** 14) );
		tokenContract.transferTokents(0xc8F5a68e1716e043D9D84D1306F8ecc258142f89, 351703399 * (10 ** 14) );
		tokenContract.transferTokents(0xA648ADA1985C6dCC7D05F7dFC064c6Bd9bdA4Bcf, 248113800 * (10 ** 14) );
		tokenContract.transferTokents(0x46753F4C02972a40aE2e26dC35cf5085cDB6B8dE, 615355640 * (10 ** 14) );
		tokenContract.transferTokents(0xA0c3Ba1e7B3fB1C65a48Fd9CfCf55daa6956B822, 279775460 * (10 ** 14) );
		tokenContract.transferTokents(0xE198755032014A9Ae0d1dC7a5510714Ddff3398C, 395561900 * (10 ** 14) );
		tokenContract.transferTokents(0x4d95AFbd16424f2cA7E3339707549ab9e8c9a429, 446771920 * (10 ** 14) );
		tokenContract.transferTokents(0x110a37D5AEf8E485aCe9119834160a0C10b81382, 598480560 * (10 ** 14) );
		tokenContract.transferTokents(0xD0902dFc23891f3bd33573e7d77E61a761656390, 760965860 * (10 ** 14) );
		tokenContract.transferTokents(0x23F0a910CC20c637e64Cce735f4c999d9d2ABaC3, 508006740 * (10 ** 14) );
		tokenContract.transferTokents(0x77c96cFf33A0571d022CF566a21EE7CA33c59a63, 168583720 * (10 ** 14) );
		tokenContract.transferTokents(0x99c819C357beCAc8593a89C37DFE41bE25583195, 833478579 * (10 ** 14) );
		tokenContract.transferTokents(0x6c716B30A5BaC931bf69419269c33a0B46b5eE48, 211857440 * (10 ** 14) );
		tokenContract.transferTokents(0x332D192F6830d80ea512fEe7732Cd5984eB6a05B, 666649200 * (10 ** 14) );
		tokenContract.transferTokents(0x130b36FD43e023EFE9370106e3168A0Cb4F5B589, 686114020 * (10 ** 14) );
		tokenContract.transferTokents(0x075Aa8Bb2a8E7CFaB95034F11368aBc5A0718bBD, 551280460 * (10 ** 14) );
		tokenContract.transferTokents(0x5842666B5b13537b16015e9cEdaC6f8DFe1ac3AB, 685278619 * (10 ** 14) );
		tokenContract.transferTokents(0xbfeB46F594Fe613b567BaBC4D56ee448b816164b, 729220660 * (10 ** 14) );
		tokenContract.transferTokents(0xeF5055914aF26Bee106C7c700A99a77231d776D2, 752444780 * (10 ** 14) );
		tokenContract.transferTokents(0x1B54158EA7aF68D290a972998bd317F053Ac1A34, 759211520 * (10 ** 14) );
		tokenContract.transferTokents(0xB973BC4953378834C23474Dbe1896c8BC8F6525F, 592966920 * (10 ** 14) );
		tokenContract.transferTokents(0x65bb27f5d6e71E41d79AB7a5AD60e74dF170C1f2, 729137120 * (10 ** 14) );
		tokenContract.transferTokents(0x0FaAe2131F2a27899BE57DCd91d34876EE58045C, 667484600 * (10 ** 14) );
		tokenContract.transferTokents(0xDc88e3c30ee6e75f4670a81D4507b18a1177c5Cb, 576676620 * (10 ** 14) );
		tokenContract.transferTokents(0x0327340d4c7E984100BD2bC8bBaD9b68bf6ADE2E, 651612000 * (10 ** 14) );
		tokenContract.transferTokents(0x98caE6001d5201C5dB066dA72c4fcb9d56DdBD70, 670993280 * (10 ** 14) );
		tokenContract.transferTokents(0x9e9173e5B85967aAC60C61BBa51da10328d1626C, 761216480 * (10 ** 14) );
		tokenContract.transferTokents(0x8fcb2D0A285AEE350eE13Edba940A0F3aa93a756, 661302640 * (10 ** 14) );
		tokenContract.transferTokents(0xb2cbc0c1387F2f857f221180e585F325DF17477a, 784691220 * (10 ** 14) );
		tokenContract.transferTokents(0xf414B148Dcc6f6C1757839995a67C404009625E4, 727884020 * (10 ** 14) );
		tokenContract.transferTokents(0x085595F7952ea6eAB6D787961188f02D959685Cf, 744341400 * (10 ** 14) );
		tokenContract.transferTokents(0xA0Fef122133FB1Dd82bEB3296BC3489A6b2234F7, 664226540 * (10 ** 14) );
		tokenContract.transferTokents(0x1239e3f9308FB08279f4B17Ea5A340768843B6C6, 1086020 * (10 ** 14) );
		tokenContract.transferTokents(0xd05035e5fd6329b2dB8a6744f036C34f982B0b83, 956189984 * (10 ** 14) );
		tokenContract.transferTokents(0x947aB691564ec5717E5dcC48E7d7379c6135e055, 11309979 * (10 ** 14) );
		tokenContract.transferTokents(0xc643d47E1FCbA63e26B95B32B561F7A7Fb9004A9, 203579962 * (10 ** 14) );
		tokenContract.transferTokents(0xa8C8fdE0449A2576EeAFF77E46e2382C874a2CDc, 204610010 * (10 ** 14) );
		tokenContract.transferTokents(0x12F2aA2aD7250b46D7113efCC81f9C546591DCbd, 106929946 * (10 ** 14) );
		tokenContract.transferTokents(0x6826c1f150FE764917637034418b772145423bF8, 113099960 * (10 ** 14) );
		tokenContract.transferTokents(0xFC39c4F2E458919A0248871305CF0A21f0EbC5f5, 312857300 * (10 ** 14) );
		tokenContract.transferTokents(0xd05035e5fd6329b2dB8a6744f036C34f982B0b83, 8354000 * (10 ** 14) );
		tokenContract.transferTokents(0xd05035e5fd6329b2dB8a6744f036C34f982B0b83, 8354000 * (10 ** 14) );
		tokenContract.transferTokents(0x4a181812681e79107adAF449f75486e69C833dBe, 749520880 * (10 ** 14) );
		tokenContract.transferTokents(0x2c46f2B2B944dCD52f91387587a2ea4723eD91aE, 540169640 * (10 ** 14) );
		tokenContract.transferTokents(0xf63253b6658B2A65c62c0Ca2FC60adBaCb3C7c2f, 738159440 * (10 ** 14) );
		tokenContract.transferTokents(0x698b0ac2C3b3d53CDd7B8c347880fB53a17c07F7, 621871760 * (10 ** 14) );
		tokenContract.transferTokents(0x0FB8925190a037FeE7Cc78b1F2136231Ce712979, 1109327660 * (10 ** 14) );
		tokenContract.transferTokents(0x49ED64538a416db3e2aA307c66DA4C5af1954bEc, 857705180 * (10 ** 14) );
		tokenContract.transferTokents(0x664F586d3027c357dE84c593d44Ad021f5e11B5e, 1184430120 * (10 ** 14) );
		tokenContract.transferTokents(0xa9e6a19E52fa4edFdd42f00D48c25115B0caC700, 1048009299 * (10 ** 14) );
		tokenContract.transferTokents(0xE5a35fB340e2978DDaD1954EedFdBb24CCbbAfFC, 878005399 * (10 ** 14) );
		tokenContract.transferTokents(0x184000ED17c7ac8990ea8c4515B97f95Ad870164, 970400640 * (10 ** 14) );
		tokenContract.transferTokents(0x5EB066Ae53B28AaeA7C3002299FdfA1c4CfC7370, 1078835560 * (10 ** 14) );
		tokenContract.transferTokents(0xDF33Dd4f7A5738067241c4ea69249f74650ACA54, 1241989180 * (10 ** 14) );
		tokenContract.transferTokents(0x012842FB73038f3E1C43412E2bAaA9f360679AE5, 898806860 * (10 ** 14) );
		tokenContract.transferTokents(0x513b9b77e9dEb82362040C77B34ff1192E44eA34, 1106737920 * (10 ** 14) );
		tokenContract.transferTokents(0x667556D6b1ADb08579F3EDcFeca41aE7E13444d5, 1226868440 * (10 ** 14) );
		tokenContract.transferTokents(0xB5c4B316feb9e5C56601fAFe97EEa0ccd8350339, 946006960 * (10 ** 14) );
		tokenContract.transferTokents(0x19B0634edf633c78E8628BD3E82012c00449f2f6, 1170228320 * (10 ** 14) );
		tokenContract.transferTokents(0xCe985B52E309B0720d32c785962077d757Cc32B2, 1341652316 * (10 ** 14) );
		tokenContract.transferTokents(0xe7D5e36e3AbB23a864fA22641997556b4ffB037e, 1262038780 * (10 ** 14) );
		tokenContract.transferTokents(0x222B623c0bf43Ea6c28C99086b9c26bF43739A98, 939323760 * (10 ** 14) );
		tokenContract.transferTokents(0xF94bBdD77A5F5bcD3F2976a2F2d0042f41cfEe2F, 1410405820 * (10 ** 14) );
		tokenContract.transferTokents(0xe998D2Cc834aEBefBCF1B517E5985C3166e5709C, 1394115520 * (10 ** 14) );
		tokenContract.transferTokents(0x37f3d770C1c5fdFee0e30e810ca5f60977bc5577, 1256859300 * (10 ** 14) );
		tokenContract.transferTokents(0x9c8149A14691Daa933546638C5d85144f6b68107, 1363122096 * (10 ** 14) );
		tokenContract.transferTokents(0x4bb2F79cd21079b8d08bdc127a7e4794Ad2645dF, 1434214720 * (10 ** 14) );
		tokenContract.transferTokents(0xcA2b1d1450356e3e2f749c9BbcaCd0aA17df2059, 1494196440 * (10 ** 14) );
		tokenContract.transferTokents(0x303d0B47Ba8800803D512826fa05fa18Ab39442B, 1387933560 * (10 ** 14) );
		tokenContract.transferTokents(0xA25F1a6457a3A0eb61fBaEB6769d97Cf0D0B5AD7, 1158532720 * (10 ** 14) );
		tokenContract.transferTokents(0x222B623c0bf43Ea6c28C99086b9c26bF43739A98, 1618838120 * (10 ** 14) );
		tokenContract.transferTokents(0x2c81437A551046e177998596Eb2aC0F922Ec759C, 768985700 * (10 ** 14) );
		tokenContract.transferTokents(0x8A2b9b8a0404AFe3705316B1760F0f0bAF6DCF47, 1186017380 * (10 ** 14) );
		tokenContract.transferTokents(0x5004F4D051fD90D297e151fa6a50Fe97859c103a, 1180169580 * (10 ** 14) );
		tokenContract.transferTokents(0x485e67f2Ac5B8184ba5A1f6C476968E9826c71ef, 909834140 * (10 ** 14) );
		tokenContract.transferTokents(0xDF6169C73039ee9a600BCef2406d1F0EFD59CdcC, 608254740 * (10 ** 14) );
		tokenContract.transferTokents(0x917D72f22F688798825e1199Df4846cda2Dd58fd, 1379913720 * (10 ** 14) );
		tokenContract.transferTokents(0x88b22B1be9E9aE4f2Ea707B7C8Fa9C21C09a8e0a, 1150262260 * (10 ** 14) );
		tokenContract.transferTokents(0xfeC86C3190F2fAab2c9A6F941B0DFE2335f5a7a1, 692045359 * (10 ** 14) );
		tokenContract.transferTokents(0x86762B03065cADAFE04a4eB17c0A5910a85050F0, 1310826140 * (10 ** 14) );
		tokenContract.transferTokents(0xED208E2d14599D9C8BF989915B090655F6197Ad3, 548022400 * (10 ** 14) );
		tokenContract.transferTokents(0x4F904f0b7728aEEF0AE275b8f8e02429fa800B87, 1322939440 * (10 ** 14) );
		tokenContract.transferTokents(0x3F00649A496b61654bbE0edbc520E117c2fAeEd3, 1208489640 * (10 ** 14) );
		tokenContract.transferTokents(0xDB8648A1648c153Daa539bA622BF3dd84Ed84C24, 717441520 * (10 ** 14) );
		tokenContract.transferTokents(0xA826A39fE95c920BFf4E8421051B4613DB96E437, 861798640 * (10 ** 14) );
		tokenContract.transferTokents(0x2FD9547773E4073fa543FC374F4C37677182D66E, 1222942060 * (10 ** 14) );
		tokenContract.transferTokents(0xdCa39CfDdad2790a853845Cb697d65101DbEcD0B, 653449880 * (10 ** 14) );
		tokenContract.transferTokents(0x270208f21fcDc602e481847026B18A4c227A5Bf5, 1051350900 * (10 ** 14) );
		tokenContract.transferTokents(0x740C4f4701d3E2AcD19bdD8e62ca6e7458382Df3, 165409199 * (10 ** 14) );
		tokenContract.transferTokents(0x430F3b42002Ba1A4DCeA128fAa87f6FaAb40e5d2, 1139819760 * (10 ** 14) );
		tokenContract.transferTokents(0xEFD3237308ad06989153Bc32f3a0AFbD25975C4d, 912006180 * (10 ** 14) );
		tokenContract.transferTokents(0x70f4550DC42EfB6Ee870e74FDE8E35dF07f76953, 427641259 * (10 ** 14) );
		tokenContract.transferTokents(0x61061990935ed1B21e0de79CBE8e3ee7f4F2ae34, 1031134220 * (10 ** 14) );
		tokenContract.transferTokents(0x35403C0889e6E7441c1c8BA213cE2c14162EBaea, 1178248160 * (10 ** 14) );
		tokenContract.transferTokents(0xB3fC0e0b268637C75e28AA53Addb7BCE588f9F5A, 100000000 * (10 ** 14) );
		tokenContract.transferTokents(0xa8C8fdE0449A2576EeAFF77E46e2382C874a2CDc, 178213333 * (10 ** 14) );
        
        transferCompleted = true;
    }
    
}