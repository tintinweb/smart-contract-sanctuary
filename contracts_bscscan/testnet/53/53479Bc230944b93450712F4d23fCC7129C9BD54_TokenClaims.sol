/**
 *Submitted for verification at BscScan.com on 2021-08-13
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

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
  function allowance(address _owner, address spender) external view returns (uint256);

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


abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

contract TokenClaims is Auth {

	address public token;
	mapping (address => uint256) public claims;

	constructor(address t) Auth(msg.sender) {
		token = t;
		claims[address(0xC8b8e35d5d1Fea0DF864bcEa7dC958C1C1163E4a)] = 501900000;
		claims[address(0x70e98AD57B94A5e56942174A3c3e07469e4c4D02)] = 504100000;
		claims[address(0xD95aDB1CCb95e7e147096B04BbD6BA65ccef01aA)] = 505600000;
		claims[address(0x57cD88252fBf4C5EA39E65818cE890036f08A8A5)] = 508700000;
		claims[address(0xd86BeF0B1391F470D2dff1f118a9f7fDA452Ae82)] = 511400000;
		claims[address(0x40cD3087A3385a4A3e8004aE0883de9B8d8F9408)] = 514600000;
		claims[address(0xc521DBf4536E4e93b9314536181e7aF6b61D41A4)] = 515700000;
		claims[address(0xd0Cb7Ae43B2DaDfFa03aAA863297F5Fe251945f7)] = 518000000;
		claims[address(0x3Fc2d11b459F75d6F0D50Fe52e1D3186C56fDC66)] = 518300000;
		claims[address(0x3f1FF5727b56EE074278c0AB6f997D9d7C0cF503)] = 521700000;
		claims[address(0x4724fee4b96D149a05B99C078505F11FeB263796)] = 522900000;
		claims[address(0xbD79A1b3783DC24CF986c2b8c80dC87a96a033c6)] = 524600000;
		claims[address(0x39009d3d8a1c68Dc584445Cb0392Fe0718cE5254)] = 525300000;
		claims[address(0x48e74Aed0A3412e880F3f1fC1352450851E6d72e)] = 527300000;
		claims[address(0x3f30cC0da6C18DdabeC96483C02FB4336B202073)] = 530700000;
		claims[address(0x04f9Bc7Dce66DBE646838DA32C8f7596B23dCEB7)] = 534000000;
		claims[address(0xe3954889a91e3aAfd6df3A86BfF4bD1721Db5eC5)] = 536400000;
		claims[address(0xA35c08565f37DdE062E63953C15464caC203C6b5)] = 539300000;
		claims[address(0x7019708c590314b866011AC15bD3B6462503e974)] = 539700000;
		claims[address(0xe5B9B4DCDa2e1a85f290Fbfb8E90a86683BF5239)] = 539900000;
		claims[address(0x6151ef07aE42efe4815c8A62fD247C97532c695E)] = 540000000;
		claims[address(0x5F6d283863F2f73Ae0719270585b66B12b7AfD87)] = 543400000;
		claims[address(0x9c12491Fb8742A5BE25164f416153765C6Ab56d9)] = 544300000;
		claims[address(0x1196ac000D91e339DA78e4a6F6Df90Bf8BEdd835)] = 544400000;
		claims[address(0xD4Dbd01F2b0cD849aCC645ba2e3b45e83268deC1)] = 547300000;
		claims[address(0x96190e6853CE43aAb2813a25cc944d3F1cf6E692)] = 553600000;
		claims[address(0x185718a770532A63Fc11A2fF444da8DC11b9179D)] = 554000000;
		claims[address(0xa553503B639bb319521ec71261c13D53AEfF880E)] = 556500000;
		claims[address(0x29ABD4B95dD3634D9f97b74840D4fDD75C8B5d83)] = 560000000;
		claims[address(0xe6509C1983392f56C023bDeDFf6B83d0E5009256)] = 560700000;
		claims[address(0x9829ED8A8db42D865D8e4584A6353d061574E4C7)] = 564400000;
		claims[address(0xda811c0b2ec72cD66714a537CDb649edB420457E)] = 564700000;
		claims[address(0xC93fb552B5586625Ac0f65e3b873AF5fCEEBeFa1)] = 566100000;
		claims[address(0x05C51a9b20Be7A1FD0156A25253F21D3D1945Fd4)] = 567100000;
		claims[address(0x9a71ACA419A15c465a41bb653b48619d1211cA5d)] = 571200000;
		claims[address(0xC99D6644cC581b19428a52880698ef642E3BdD35)] = 573600000;
		claims[address(0x67050086a678dfE5d0Be286554c79164ef3b3479)] = 574000000;
		claims[address(0xcd27922B405d7f95d3467dE59fB7696e0A4E8F81)] = 576400000;
		claims[address(0x8690dd47fCAe910DEDCf1401F733Da253C0D662F)] = 584400000;
		claims[address(0x1eb95D89a56370C78EE918d14129Eae8ADC49217)] = 592500000;
		claims[address(0x0CEaFB603733daaAF5E63B52Bfa650B6Bf6Bb2Ad)] = 594700000;
		claims[address(0xf1d117214fA2A50097c7b9f90A003C61603fcA2c)] = 598200000;
		claims[address(0x55c3308Bd1Dc10dC85a226452Ba749bE0651d468)] = 599200000;
		claims[address(0x0Ea1b2dbb06A7F67C3C79947e5D4FB4D94A5dcae)] = 599700000;
		claims[address(0x5fEA7e78485B4Ebfd92611083d12E3454A952421)] = 600300000;
		claims[address(0x91255bbb4518Caf78094dAbc78A3B0A72Fd98Cd9)] = 601400000;
		claims[address(0x4d5EEB6B00Eda3C022e7075B936a23fa75fD211e)] = 603300000;
		claims[address(0xD5828346d70A33360ce84f6969bfb360F809E7FA)] = 608300000;
		claims[address(0xb929976a0754D34bb842BD917b186F1d2fF15f68)] = 610800000;
		claims[address(0xf8b2C08f5a65C5500cd8fAf966bdC8FcA7a44aC5)] = 613000000;
		claims[address(0x4449bf2b0Ac0490572a7C10d4d121F77604b6c0A)] = 613200000;
		claims[address(0x6520ADb4dF2eC52d78790Bface8c4358ccF96fcD)] = 614500000;
		claims[address(0x741489e311b55e46212362b8675d2aE0DA1696bA)] = 617600000;
		claims[address(0xcBfE82a02830BD19a92abeaff0dccF477fB372C0)] = 619200000;
		claims[address(0x84Ab1bfefAD1354246C35BA91ABeCD38062ac2A8)] = 619900000;
		claims[address(0xD5c3d525f8a928c3a241DD1EE32862A53683e828)] = 621800000;
		claims[address(0xBCF242080dfEead95950D2F243416E41541F5FBC)] = 625700000;
		claims[address(0x920D1BC90cD29f3e1f5F1Eb62d62F315983b7111)] = 627000000;
		claims[address(0xDB652d5427019FDf3b1967b994d7595008Dc5b9E)] = 627800000;
		claims[address(0x266559FF8500fDAe9675647c81531B1c0F2EFa1C)] = 631400000;
		claims[address(0xe478F590C15d552CcC165E7ca160771FA46064EF)] = 638300000;
		claims[address(0xF521896fc99640f6de4Ff748d53aC847EE374967)] = 639400000;
		claims[address(0x15Af233dBb06FF04802f178019A4eF3d40e35317)] = 641900000;
		claims[address(0x997EeA1434955c5DF1fD126561044c94Ef295E8a)] = 642200000;
		claims[address(0x1f021F0FA4E7F20124FE7b771B2EFFac21810B2E)] = 646100000;
		claims[address(0x0891329C40A22FAAeC349f52d816C4600168D5D9)] = 647200000;
		claims[address(0xd90E29ab6353918974A32518fD25388628ddbD09)] = 649500000;
		claims[address(0x0e5E6d0A5BE4826fB85C2310224D8dEEB2A23319)] = 655600000;
		claims[address(0xcE5B66a64AAD0d10F8e983FC10b1357D1f60D802)] = 658500000;
		claims[address(0x37c6Fa4BDC6de11E5349E90F156fa5a3255C5913)] = 659200000;
		claims[address(0x6869696AEd483eaeE2272e7a8fCa231F947332cc)] = 662200000;
		claims[address(0x46615AD1551743DDBf0E21Ab53E1C2590c76A322)] = 664500000;
		claims[address(0x00babD14a4f0E0b43D67Ddb88eC4C9feC5A551DD)] = 667000000;
		claims[address(0xc89280f9dd003eAd60404819615816A6e358fA53)] = 668300000;
		claims[address(0x693fD691a1EC17Dd6B98b75d8D6897571E181324)] = 673400000;
		claims[address(0x550c0868fbE82be49A583e13Bb593cCb90e50A03)] = 673700000;
		claims[address(0x965a268d6519284F6EDa56a841cC107339F80bcC)] = 676800000;
		claims[address(0xbaadD3e6afAd65A61dCc476e9c0BdBA2cb903Ff0)] = 679800000;
		claims[address(0xA624ABeBa1644Ab8228B817C81D3A899aF6C10E7)] = 681600000;
		claims[address(0xCc342CeFF8E98C3Dc7cc16C362F0b84f8300b5cE)] = 686000000;
		claims[address(0x56bF18d4ad0c64365752fE3a6614FfFcC9f29320)] = 689700000;
		claims[address(0xcfD44c7F3ef02311c355D1878a0d42177e0f2972)] = 695100000;
		claims[address(0x3AA116a10f17c019d9e534A42458e701a100fd1E)] = 696600000;
		claims[address(0xBCd08B917F6729221273F824Fac932C2c0bFEfd2)] = 696900000;
		claims[address(0xBF6bD93C2a5a1756407Da9c9d54C06cEa41d254E)] = 699000000;
		claims[address(0xC548427719289D4f1b8FBf990A1a9E329EB9adf4)] = 700000000;
		claims[address(0x9e0605B4d276D4F258089D159d434504DEf37C24)] = 700800000;
		claims[address(0x9FadBf13575A8991f843eEC6B828AEDAcEc8Be87)] = 701200000;
		claims[address(0x73Db2B3A732f0DD87b9164964A04aA2B574bF606)] = 703700000;
		claims[address(0x53A2B2C79B09e8f1B555DCAA3d668516cfb14B1f)] = 705700000;
		claims[address(0x070B755Cb15843316564D4229CA101AEe127c693)] = 707500000;
		claims[address(0x6723E9e370fB008B014e5D8d536490389c89D72a)] = 716900000;
		claims[address(0x64E6A95eAfF1B93A879a9177c3c7121dacDd5fCe)] = 717200000;
		claims[address(0x6d44709ce0A8D0751F0063F217A9Ed0b648d8E67)] = 719100000;
		claims[address(0xf21312b2F75F0Ba2cdb3bd0312b8964E1cA711e5)] = 725000000;
		claims[address(0xF83b31E83e55011F1b6A146eB327110930d49aF3)] = 725500000;
		claims[address(0xf44693631795A59E0EA6B5fab257c6dd8d134e3F)] = 725800000;
		claims[address(0x474AE560f41774234A3c170d679701D0a3eA4B20)] = 726200000;
		claims[address(0xEF6919a3dD51C0062D881148dCF50a93EB875346)] = 728600000;
		claims[address(0x4e72aCA1EDC19F9b220474B8071DedC714EEbBad)] = 731100000;
		claims[address(0x0323b793A74882f7f56Ce78c26fe5505517316a0)] = 731800000;
		claims[address(0x1A21935135a9f0D526A5cEc052E46cf7883Fd419)] = 739900000;
		claims[address(0x11A36D390aCa00Bd1797cb497b586981DAD59D95)] = 740600000;
		claims[address(0x2Ed14aD92D33f21A8b8b0ca6d1bF5C6B5E96f58a)] = 740900000;
		claims[address(0xD6BAdBDBaeEe9477339C7A2a49356963F1d804fb)] = 749900000;
		claims[address(0x5D42eCafB3171A6a77C9FeC80876107B98b03dC2)] = 750800000;
		claims[address(0xFD3733753DdDDa77d1e35fEffe81981db6425a26)] = 751900000;
		claims[address(0x8E00a11878461c0D7BD2AE33D51C24922732A51a)] = 758000000;
		claims[address(0x8a55298d9D22741bC9ca8a65cc11B378A8a11BBB)] = 758200000;
		claims[address(0x86d89B8225119bc1fd1280cFD9cb50207b8E9fB7)] = 761700000;
		claims[address(0x44954b705600c996012d2609881D2F37Ba8998af)] = 763300000;
		claims[address(0x5dDE415892293Ae645B95BEF65E8B3E1Fc46624C)] = 764900000;
		claims[address(0xcFf3d078755FE2D3800746f8B3E4721E460041aF)] = 765000000;
		claims[address(0x40c1242bf9709eA9A221dE498eAC9F668e427E33)] = 769800000;
		claims[address(0xf1d7Cd89f37632D52466Af86C757Da7a6ffD69a2)] = 776000000;
		claims[address(0xA11dC6f57d5Eafc6E17cb975B85008913dA0252E)] = 776000000;
		claims[address(0xF69659A5D445B58839ab030e9C4cC58682b7477C)] = 777400000;
		claims[address(0xAE4395917e91686e0070627dF529b30Fb39a5835)] = 778000000;
		claims[address(0x13707565864A34ffE8cA82c8af7Fb177a63d759A)] = 780700000;
		claims[address(0xf971815DC6Be304DbB4b45fFc85622ea2121D95D)] = 781800000;
		claims[address(0x7502D445E5424f02A1a5256A5E35e27160Ed6831)] = 789100000;
		claims[address(0x5Bc1fE6F26B62F0685A1014B2Eb95F15C9B5FcC1)] = 790900000;
		claims[address(0x39BEf8E43c7C6BCf90d4E818cd7114Bc5fbFC51e)] = 792300000;
		claims[address(0x0d5b4a4200F8C1a0663C1042A2ad23f9B0D2A9fb)] = 799900000;
		claims[address(0x178D1559c6Af7A0fef3319FB1623f80507D9798A)] = 803300000;
		claims[address(0xeF9fd64b3ca40F272D07f8eb69a249Ebb3Aaf81c)] = 805100000;
		claims[address(0xfa18BbDb221730e1CA4aAc2915B2bE2b9DDBB5DB)] = 806500000;
		claims[address(0x4Fbd9A798722704DBac80332Ce1E47a0A5Ec4540)] = 812400000;
		claims[address(0xdEFE4CBF06Ba76ECd700846dDd39ACA0B9f9564e)] = 817500000;
		claims[address(0xce1AbDc5b539a265d782aad62c91b3a099CEBa49)] = 820800000;
		claims[address(0x8AaccdA1FCC9b38E6E6F84A6F6FD6aDfcaEFae70)] = 824300000;
		claims[address(0x0F6e6909f223e2de9e26C946678417d44224fCE2)] = 827100000;
		claims[address(0x28f5d56A90f5c235e2201d342141ef9079F749A5)] = 828200000;
		claims[address(0xc065914AFf64161BAF72A0D67203bA6Ea7bA2bc1)] = 834600000;
		claims[address(0x031f26d2c2DD09854DBdd2fBE34Ad52b567d1Ec2)] = 846600000;
		claims[address(0x2D0512Cef88621E7908710f9D859896125ff6215)] = 847700000;
		claims[address(0xeA62bcEC7637e94509BC4FFE7391aED54f0d169C)] = 848700000;
		claims[address(0x307926a6A720849610f07c01D1e592b4acD809C3)] = 855600000;
		claims[address(0x54d947e319CA9725c6b2295cc3136676b414C7A2)] = 855800000;
		claims[address(0xfF8673B87Dc12FDFCC5108009BaC64754c1CEB8b)] = 857500000;
		claims[address(0xd30feDd7B71e69e536CCe7b97563b6Ae1b8259Cc)] = 863400000;
		claims[address(0x04C1a411C5a3BF3A66C0e0B7F07A140955c782A9)] = 870400000;
		claims[address(0x97351A2930CeF94047512D2BB0D453d46792Fd56)] = 871600000;
		claims[address(0x382CB79fC9521868a725852CC9bAE0b4417Fc120)] = 873000000;
		claims[address(0xa59659294e9615790414450754E93fE2111825A1)] = 875500000;
		claims[address(0xe54243199F63F3FD2826873Fcf72a0E492dbFF5E)] = 878900000;
		claims[address(0xea4bb6Ea61B81D0D9a1C63D121B1f49193cC5C9D)] = 880300000;
		claims[address(0x77c9844C60fBE854fD667c2F149842AA1c15Ff55)] = 881200000;
		claims[address(0x351F74699C73eA5BE5fD4Cd2Da9cb4c8E5Bb8Cd7)] = 887100000;
		claims[address(0x86880eA6Cc9b4A79E60d2618C31E507C745496ba)] = 889100000;
		claims[address(0xF64B6FE7A2C498377ADb32DABf3C5Ab2c3294f13)] = 891600000;
		claims[address(0x384A66d8EC31ABa898101c3B5Ab13e5F3f3C3590)] = 897300000;
		claims[address(0x1197F4f8cc8C63A5429c61782e9ECf93a5552E08)] = 898200000;
		claims[address(0xaC923d01055E920424c497C4B37C66B8f00995CF)] = 899200000;
		claims[address(0x67788fabF9cda76bAa33B18d663489D50412CCae)] = 901000000;
		claims[address(0x62fAa6A4e2a2A33144250EF6e5C375B76B69E7F8)] = 903100000;
		claims[address(0xC079D04273221Dd8e2Db6368ef2197AA739d6f2d)] = 904700000;
		claims[address(0x648d6D0CDd9104C78b507C851BbBB9AB5eDaf0CB)] = 905700000;
		claims[address(0x630686bCFE5e770Fd67aC021c4f2821091402270)] = 906500000;
		claims[address(0xd3C5C2f0736e63A602BF2c5328a6Fe2320145390)] = 907100000;
		claims[address(0x7e956C0eF7767167719Fc87afE4a0BbD889499e5)] = 919600000;
		claims[address(0x23004154949aaA009d756A3E06a93BacD4153053)] = 922300000;
		claims[address(0x04F2191551f5904173c359C047D5CC1709E6193A)] = 926600000;
		claims[address(0xBD0fB555b15c66F42ce1166EdfFC430943F3fec0)] = 929800000;
		claims[address(0x2Db794491D60Fb6AC00BE292c43842e3edd2F3b0)] = 931100000;
		claims[address(0x6549f3DA105dC0A8d95da6a32567C482a50d0414)] = 932100000;
		claims[address(0xc62B0aE32E8dbECc075332fd33d4536da7458eF4)] = 935500000;
		claims[address(0x7e75009bfa11A87D1b6714fE555bfd2dDEEE1F80)] = 938900000;
		claims[address(0x2700909F52e573D4016c09E8A1D7AE9FE31b6ca6)] = 941400000;
		claims[address(0x50b440AFB82aeF66cA4f79A8aa8Fdf1035CB2B90)] = 952200000;
		claims[address(0xE6E04F5F72839792Bd13F029D67D0aE515d5c46d)] = 955200000;
		claims[address(0xFb7337Bf7E3De7856a154DAA7DB52fbBa88710e0)] = 957100000;
		claims[address(0x072A8c3c680a5cccB6D1BCEe26ce19f1e4C506b6)] = 959100000;
		claims[address(0x14e6089DAA314B89C25b5eD781641838B8dE3598)] = 962700000;
		claims[address(0x0527c9047122D47A75B4249290E7BbcaA65b24Cd)] = 963100000;
		claims[address(0xbb8CF7152c371533E7E18ab6cc93553f8b1f3844)] = 965800000;
		claims[address(0xbf5744FcA5bE1B64E2f3FbA295FF191a7CD9ab89)] = 969900000;
		claims[address(0xBEAb3364322273971f0D31015624A719AeD8E74E)] = 969900000;
		claims[address(0x2CC37D5aCEbE8989dfA75A123375cF796c9519C3)] = 970000000;
		claims[address(0xe77d16Aa72e5209c41BeC381ad27590E3803222E)] = 970000000;
		claims[address(0x05f00A9A222C9E74dE123143115062684fa6003F)] = 970000000;
		claims[address(0xf0c57caA71fCBB150abfb83893A82f448083C8d4)] = 970000000;
		claims[address(0xfbaA14c00CF4720DA8dB3ea68FC81569bfc84d93)] = 970000000;
		claims[address(0xD70cEb92697AA750BFB1EcC739328120C61415c3)] = 970000000;
		claims[address(0x0D67E40c409f3eDc436040BC60de1fF83145C19d)] = 970000000;
		claims[address(0x3BC4259B44D15F60DD0EE6aC24E6a2Dc7Fd4f20D)] = 970000000;
		claims[address(0xa2C8a1AaEb4f687284df2e911A66ABf6D4084f8e)] = 970000000;
		claims[address(0x395b72B6C1E9B21D1d052179DDda999b1fB4d68e)] = 970000000;
		claims[address(0x83A864e12bf59d7A2faA2BE12D50Dff0D9d534eD)] = 970000000;
		claims[address(0x48527Af45E6382631c2822eB9bB4375E28a6529B)] = 970000000;
		claims[address(0x96ee1C83bd0E5D1d3B7d616921bD3c919bab2650)] = 970000000;
		claims[address(0x9969CDe4156547A755eD5e11D8F2447ebee1d3B3)] = 970000000;
		claims[address(0x629dadC0E6ecF9E9CBC56c30248d6611239dcaB0)] = 970000000;
		claims[address(0x044da0B9261D5b72D1e03b7656Ee107d0F8044d1)] = 970000000;
		claims[address(0x863446867806863E4c848DB81d7FA4f510E0Db91)] = 970000000;
		claims[address(0xA09896d87E206C7CEc217Ad0124f85EEBE85EDb5)] = 970000000;
		claims[address(0xAB578685a4cEAA8AA4AB9E2539F98D1887771B1d)] = 970000000;
		claims[address(0xF280F47A9b37136980865333973285583E8726FA)] = 970000000;
		claims[address(0x26433F8AD34E9026b2585b35E40506Dc796cBb2F)] = 970000000;
		claims[address(0x065db0a316efAA3C3EdD7Ee6Db7ba2e19282f7E4)] = 970000000;
		claims[address(0x8eF4de747fef742Fb0891B6601BaC9514D1Cb297)] = 970000000;
		claims[address(0xC0f43da590FD7177428086941861f66c7c39f54E)] = 970000000;
		claims[address(0x0025eC0784CcB820Fb65A5E4A8cf0A69F74488e9)] = 970000000;
		claims[address(0xa60e9139556cfAe223773103354B240b947CeF47)] = 970000000;
		claims[address(0x629c03aea60A88a218F1B56DaC52AF0BF6A8Fd81)] = 970000000;
		claims[address(0xd0e2dFf3edfac4438f83DaCf59BfB2758B566311)] = 970000000;
		claims[address(0x5c8a41078064b48D562C02f375709BAF026D0eAb)] = 970100000;
		claims[address(0xb57A8411d7D3b7B7d516caC23A517C0617F16163)] = 974900000;
		claims[address(0xdCB16079a5377ae26C8a52fC4a822Fdc05736646)] = 983100000;
		claims[address(0x33EA6313b7235a14e2C7734a00e59e301B17f31b)] = 983300000;
		claims[address(0xF52F20128379bbA314aE8c18AF81A82A44058893)] = 984200000;
		claims[address(0xD2b4dc595A29172aB69684D025ebC2DA8A4e6dAB)] = 985700000;
		claims[address(0x587CBdE67dE3DE091361BF5beA1A87F0883A96C2)] = 988100000;
		claims[address(0xC6788FD83Cc2338AD2FBfdA600E1843a64e52040)] = 989900000;
		claims[address(0xe6358447f819A8817AB90CdA65bf1269B6b3Ebd5)] = 990200000;
		claims[address(0x8e91a93521105a3a75B0e2edaa6315Df3a979335)] = 995300000;
		claims[address(0x2A5266De7e34a9310c9bAa4847a7F1D9CC316Db2)] = 995600000;
		claims[address(0xee0232E292EE48203656e18c8B1d9E7fe5eDe212)] = 996200000;
		claims[address(0x9D43A1B6203759cb29Ba8c0BC7034bc1717ff481)] = 999800000;
		claims[address(0x1f1CFa62aC1964D8197610Dd5241b25e7904568C)] = 1000000000;
		claims[address(0x18eaf48858256eDF264ead018CA0F509e2caDF23)] = 1000100000;
		claims[address(0x25aCfcaBF5F159ED6c61Ac96b36EbB7285E4d813)] = 1001700000;
		claims[address(0x3D46fC6226A17A09F1B9B3477A6B4C04355038D1)] = 1002700000;
		claims[address(0xA690B5a5332ff521D4A8f662D8E8e8c9DeEc9639)] = 1004600000;
		claims[address(0xCb21bD7B32B60EF9a1dc384782EDE25F2dF8a5Fb)] = 1005800000;
		claims[address(0xEd6b8ecF1401F270F45BDCb018D62CE41266f71b)] = 1011100000;
		claims[address(0x4C7b8CF0850fa0A3280bDA93cA1D01B26e3f256a)] = 1016500000;
		claims[address(0x1b1aA3a131B62e8C0480Cfbc094F56571ccACA8f)] = 1027400000;
		claims[address(0xFDf2E7409b7228d23E5cEEf452c7920F12E064EC)] = 1027900000;
		claims[address(0x77612D58b20c280C003D7e2Cda409bb2D5D83aD5)] = 1034700000;
		claims[address(0x14Db758d56134Da1af52d54a956c0Bb8070aC179)] = 1035900000;
		claims[address(0x18be9d4E96238B2dF69E4e0Fa73B9c20b4159Bb0)] = 1043200000;
		claims[address(0x2630084adFdDFc086d195738575514DA97e08BBe)] = 1053500000;
		claims[address(0x0719C4ECa564c0a8e9D79a3102D08ba5980cF491)] = 1055000000;
		claims[address(0x1faE13eF4037E2311d08894645490eB528d42171)] = 1057000000;
		claims[address(0xd5FC1e5585913c8f46d8E8cB97999e054B6Cb729)] = 1063800000;
		claims[address(0x61Cfe20E98144DbDCd0A76b24A14f3118D21b5AE)] = 1067000000;
		claims[address(0xB9aB768c68255796790C3C70cce47F8F6dCacA70)] = 1072200000;
		claims[address(0x6012dB07d3Bf22bfE870e50FCc60912592642Ce5)] = 1072700000;
		claims[address(0x81118e26682F3AbBa441f5e8f9F05e1Bd6d48Bd6)] = 1077600000;
		claims[address(0x2c4246e4daaaA9dB3B5c01657e7a100c01264521)] = 1081800000;
		claims[address(0x85F3Ad138A205f325e5725A850f410F9329d0990)] = 1084700000;
		claims[address(0x0C1a959231C8d5632BB86DDBC346c41B4784A7E9)] = 1085100000;
		claims[address(0xE082ecc9Fd83988d7Ef3a38321FEd958f0E04c2D)] = 1086000000;
		claims[address(0x155cd1E6fb41630B0677E95BE88B1424e87Cf7C7)] = 1097300000;
		claims[address(0x9490BD565BffF5763Db63d2AAb0C2043180395F1)] = 1099800000;
		claims[address(0xA05120e927256E6dF89021243DB638a2e413a93f)] = 1100400000;
		claims[address(0x8F15eB374e25132Fd6B4C58fb351CEf226788bfC)] = 1102400000;
		claims[address(0x1591A4C625A3647cD7229F8421545d912Ee75eC5)] = 1102600000;
		claims[address(0x0B577ed938A086C35e5d3BEb0B41309E7D075464)] = 1105600000;
		claims[address(0x28423393a7Af020723AfBB85d56213C19ef0946b)] = 1106900000;
		claims[address(0x37f3Faaa4584DD2686C1110cD8574A2b4455DEfD)] = 1112400000;
		claims[address(0x3c4fbFbdeeBD52e2BEa323EBD5F7136DA797e813)] = 1113700000;
		claims[address(0xF2b75A2170603597766De8297675F843a402c8C8)] = 1118600000;
		claims[address(0xAF0Ced13b0EB49b5B16cC5B9E40256275B100337)] = 1120400000;
		claims[address(0xC210fbb546CB409F106f1EEcc6292396C9E6C217)] = 1124600000;
		claims[address(0x5732c7939d1b18dFd540f35dBC885b6cB38C0c45)] = 1131100000;
		claims[address(0xC2F1935eDF9B61882d7d2bfa20eeA309451745CA)] = 1134000000;
		claims[address(0xEdD51Cf28b3FfDa13cb5533A332Fe05521C80c28)] = 1136900000;
		claims[address(0x912C39d52340c2877FB376019508B965a50faC57)] = 1138300000;
		claims[address(0xf889D59a6Db2179370f0DB71DfD0b2817762dCb5)] = 1139000000;
		claims[address(0x99586441FD08E48eF889072ad61b741D8Cf0a3F3)] = 1139100000;
		claims[address(0xAC9725754A99937Ad5669A05625137Fd882667b9)] = 1139200000;
		claims[address(0x17983e1766F6B5646190EcF6554ABD8fd00cfC5A)] = 1141000000;
		claims[address(0xf6f71485AEa72e422A8054e1d262f7Ad8A114676)] = 1143600000;
		claims[address(0x71f4F9B51a841A5Ba6Cc19225d68a87E178fa652)] = 1146900000;
		claims[address(0x75A382f4e42B690A4b6226a39f820a118c579d04)] = 1147100000;
		claims[address(0xBee005d9116f053dA6863B579aad764Ed94d6886)] = 1153800000;
		claims[address(0x6E7302553bfb512d9E5117BaBEFEADAAf5C209a0)] = 1164000000;
		claims[address(0xAa74465980763ce0bCceed768B383b5CD1b11D62)] = 1169800000;
		claims[address(0xE438529cA793e99d9C2d9817F225f51dad15a7ea)] = 1171300000;
		claims[address(0xE4bc17E2f1969794860789fE82faE7723d0E859f)] = 1175700000;
		claims[address(0x56cdc1D9F9a467F625a64C5328Ca3daA61951C1c)] = 1178900000;
		claims[address(0xcCD071d7d79612990874b2E0f3aaAFf95D4849E7)] = 1188500000;
		claims[address(0xaD7c6dD4AF60681d9c6D29DB005a76afaa7eb26b)] = 1191900000;
		claims[address(0x10AE1991B7B52891Af94C0A255107479798fEAB0)] = 1197200000;
		claims[address(0xa3cAb46F0aB218277Ae85aa543fdb7029Da8c173)] = 1204300000;
		claims[address(0xC4330c39Fc918737bb892CFb98C30e4113FD0370)] = 1207000000;
		claims[address(0x05Db56e2902FCb12F1B1eF7A03400a35Da171E10)] = 1208800000;
		claims[address(0xeA800EC1C5c695B5d9Ff8D929C76Df15a942EBF3)] = 1216500000;
		claims[address(0x1D0115349D836AAfcEE7e6Fd77e17C892A799155)] = 1223100000;
		claims[address(0x9cC85ECfC48db0483EfE07ECc349520877011615)] = 1229600000;
		claims[address(0x1424567B8521FC51d6F25e8B2858d1fFa6543706)] = 1229700000;
		claims[address(0xC94d19347F2a28c567e7B71c5F2EB1B9c6697DEA)] = 1234000000;
		claims[address(0x88D5deD1851291ED011333d95edBdA1627F5A34B)] = 1234600000;
		claims[address(0xD1bb56295aC52b1997bB3081068bCD13980510Ad)] = 1238600000;
		claims[address(0x5Be9F90079b1a1Ce148BCeD584db661942C753c0)] = 1252900000;
		claims[address(0xF3A3DF1B2a239Cf003EE3e23A274ad0642a9C1ca)] = 1255100000;
		claims[address(0x6E7D346a1Fea669512B0f68718398407C2E4d2E2)] = 1261000000;
		claims[address(0x1B4203ca8F9C263fC48EDF86c3f46E2EB1aD1dd6)] = 1262700000;
		claims[address(0x185c82f942473C5208088F6f9c84e0aC4AD00541)] = 1272400000;
		claims[address(0xa62414a556845Cd34553b3fB904DD41838809dB8)] = 1277900000;
		claims[address(0x0949A79B90f8c4829bF488EC19D678bb347B4Db1)] = 1279700000;
		claims[address(0x6338eB6aeef4E00f6694dA7f62aD47FAD60597b8)] = 1280600000;
		claims[address(0xcc315FE26009b5953E6E760Ce54C9Ffee5f0234d)] = 1284900000;
		claims[address(0xE3a6FDaAC1849E98de687D45ABDc85f4f9702D2E)] = 1292000000;
		claims[address(0x0E69B3Ba2Ee5c49cAa9c23A29803d27542c27113)] = 1299400000;
		claims[address(0x5Cb657de12Fb6adb81e2FbD665146cBB720DBbF8)] = 1301900000;
		claims[address(0x0F6041662794aF870E7078dB9d770Bd118f0682E)] = 1304700000;
		claims[address(0x0df09f122Fa4cF336a0038db11FdFcb073257DB8)] = 1310000000;
		claims[address(0x133FA160c78fa707C4757d210E3f193FA76Ee98C)] = 1311800000;
		claims[address(0xEe6eEEBA7E24646f2EeA36800645FC7eE6dDf9EC)] = 1317500000;
		claims[address(0xc9879c16a0F644a3f17f37b194F8c36a532b77C0)] = 1322700000;
		claims[address(0x69cDD53714dCC8Acda0805B8E04df12E597d708a)] = 1334400000;
		claims[address(0x4547F00F2b96433B16b79e668a902D6eDDF56f4b)] = 1341600000;
		claims[address(0x3C9f192B7a00bB3A81477f409568E9490E610231)] = 1342000000;
		claims[address(0x8aEfB8d2a52786e32b4f2a41069dBE750861EfE3)] = 1346000000;
		claims[address(0xe6c795e685F84CeC5A1bB796A5d9Ac58d304088F)] = 1348600000;
		claims[address(0xe892c70F880d223578Cb9cae0157E9cD03Fb3bC6)] = 1357000000;
		claims[address(0xEE08b503c36c9b9d1EdAD15DC80aD6EE316A9468)] = 1359400000;
		claims[address(0x1c0F665893DE5151782A09b40EaF287156FAb764)] = 1362500000;
		claims[address(0x5956cB611f726F784207BE05EbEd8DA7fFcAb182)] = 1365600000;
		claims[address(0x0580c0E41CE7BC93B00ae50CB31E14818D211200)] = 1369200000;
		claims[address(0x254b2c87B96610Ae94F8b7e0df874Be282bA766F)] = 1374800000;
		claims[address(0x42A6b4e7478a81c73E176Dca0C352b9A7d9014dA)] = 1404500000;
		claims[address(0xDD174612ad8d2F95eD85a867dA1b2E65D296C44A)] = 1409600000;
		claims[address(0x634fFE32Cd7adF622C54e09E638220F0388Af9Bc)] = 1409800000;
		claims[address(0x6E0Fd3d99d77c2Bb8dE4c489Cf93D28a664B3Ab0)] = 1410600000;
		claims[address(0xb02d16Ed1093043C2CDb6fe84dB3F4b8781987Fb)] = 1411400000;
		claims[address(0x408Ae602622Fae069D7104808807f2f4B4B40a77)] = 1411700000;
		claims[address(0x57242f22e67BC9b8D1AF0BB5Cb3E81f86949B60f)] = 1416300000;
		claims[address(0x417859B566140bAAAA3cA3d5abeC69B5C99e3173)] = 1418400000;
		claims[address(0x8305f66D7e0255d580C3a18327335182Ec051768)] = 1423800000;
		claims[address(0xC9aB1CEaE8b187E3C7CD6a1af51C1E63390C75a6)] = 1430400000;
		claims[address(0x8df27DcdEc79AbEa690F41F432F19263FC58c53D)] = 1436900000;
		claims[address(0x9527b8a6Ef65D03c949F1B052B127985Caf55aaF)] = 1444600000;
		claims[address(0x0863Ca03e0d64670dF6331084FB591eDf08D548f)] = 1453500000;
		claims[address(0x763da1662920574E27d877005ccEbE98fD1DAFD4)] = 1455000000;
		claims[address(0x5856263074a65A39538f2A7F0e2FAB7Ab12B715e)] = 1455000000;
		claims[address(0xCCD695C119F9dCBa88BF2134773bD7feAB9Fd864)] = 1455000000;
		claims[address(0x8B8efB1978EFd9b8183FaB1F4dCb1FBceF69efb0)] = 1461600000;
		claims[address(0x5fCD83210bB44C4D82b54895c20bDA8263a1a786)] = 1462400000;
		claims[address(0x7E2788CD91BEC192CBaeCf34D4b836c3f28F9013)] = 1468300000;
		claims[address(0xC8A9898DfBC913A18c1A49324838B01Bf2ccA4C4)] = 1477600000;
		claims[address(0x7093c06F24d8C98DD6aDB1bD9586995069f3cce1)] = 1480100000;
		claims[address(0xdAA464574F165b9F839541DCDb3A2f9361753292)] = 1495100000;
		claims[address(0x77BD780bf59BBb9c2c48Df580ce88E29eD0cB93F)] = 1497500000;
		claims[address(0x7D80921FFb8bf44f7F656e67D46f9cB3085e344a)] = 1505600000;
		claims[address(0xC6b51E9BF2143dF44D2E517C207b6884f0Bf4EE0)] = 1513000000;
		claims[address(0x8DdA3E52F834c9151a47b5C63CD867CFE0808333)] = 1518000000;
		claims[address(0x87351c6ed5ddA3a4Ff001C96E9FD7880c67091B7)] = 1520400000;
		claims[address(0x5620d74b00d0Fc525BC2fA003D86F38F724d4eAA)] = 1525000000;
		claims[address(0x25ce00971D8A3922dE5627d90BB7C93D44dEcD03)] = 1534100000;
		claims[address(0x226Cb97d3a4f8d040Ba2598555A47C20De59D28c)] = 1552700000;
		claims[address(0xe3E2A705A37065F179bB6972244C4832C4B7F093)] = 1553200000;
		claims[address(0xC1C3984F892914A695cDA427de46FCd75c2B8415)] = 1567600000;
		claims[address(0x0e44Ccebe5c4b5463291882d04c5a4Af1C2C04Be)] = 1571300000;
		claims[address(0x1aC2d4563023C553A17D814a1aA374D86C784e68)] = 1571600000;
		claims[address(0x55E2Cf3A252552B370A48e05C5d6A8384F17fb37)] = 1580200000;
		claims[address(0x45A7e5Af96538A97B4A8c4eb6CFA59627C21e2Cc)] = 1582800000;
		claims[address(0xda4ccBeCA5633601a5EAF67791a128a5910Fdc6E)] = 1583700000;
		claims[address(0x14EAf290ffA631253f86be048B09b60bd4077D62)] = 1590100000;
		claims[address(0xD8F9a5d5F6011619585cF82CC8CA55F0c15b730d)] = 1596200000;
		claims[address(0x671925B295b448BEdF1FD4b12A1B2650b7eF0f2C)] = 1596600000;
		claims[address(0x51763478CB82D5e7c434DB923d1bB7E68150CD75)] = 1597800000;
		claims[address(0xe7222F8405CE0DDc30D08a54284dD09b8A731239)] = 1599300000;
		claims[address(0x492A626A9a77D658E4160eBCC3b1CEC4EEf84519)] = 1611200000;
		claims[address(0xFCb4afE68cF9eC4Bf5c73dEfC83672a7762b914c)] = 1614800000;
		claims[address(0x7aBC5cC1FdDa73a0fbA23D6197e76f0D5ff80495)] = 1616000000;
		claims[address(0xDe765068a52941E2f860Ed6461fB94AaA7b932C9)] = 1630200000;
		claims[address(0xcAb088CC2f0aA06d8DB76B75AB9B6073b06405cD)] = 1636400000;
		claims[address(0x92aA8E96a3a5cE08261bCA9c6AB5856221546E2b)] = 1640300000;
		claims[address(0x57Fe4D0fEe5eeB6e4f1b36560C0F22f6B80E5b39)] = 1641700000;
		claims[address(0xcA013Fcad01C47FB77Af90304d9F0E2d3de90a66)] = 1652100000;
		claims[address(0x50F7e282d5f54FE55f8FfA1AD248B0fF5c64Cf15)] = 1659300000;
		claims[address(0xfBf7Ff8b28f3A68Fc3Cd8E23DDD277554D6Bc2a4)] = 1659900000;
		claims[address(0x3d4c5eBBAd848EFa431A5Fd54346DE99714c53dD)] = 1669700000;
		claims[address(0xCA2694Ff2254A20f08Dac6D1D92a0604a9AD0B25)] = 1675400000;
		claims[address(0xf3477f52054548CfD949D12387F1d6b3E80d2bb8)] = 1677500000;
		claims[address(0x91359E802dC9432ea77B4ca23246D8789eA95002)] = 1687400000;
		claims[address(0x4e1023D900eB1fEFa1BfC983dC2B28b158996b46)] = 1691400000;
		claims[address(0x049D1fe364CE2a27da827d19152D7BdDD028714B)] = 1695100000;
		claims[address(0xaf41a2DDc11c4537424D6c7B7eB9d6Ca9343AA58)] = 1698700000;
		claims[address(0xDA729BBf500FfD18Ce12455bff6829bf18595789)] = 1700300000;
		claims[address(0xD79f9B066d9AbE59A619783e20b37d224d381d49)] = 1701600000;
		claims[address(0x838a02bC8371f417a28B3c93B2D1899b2C051902)] = 1707900000;
		claims[address(0x91f67a3b46B8Ef0C68a3e004Ad1fad1a52176A31)] = 1709300000;
		claims[address(0xe8a23BfF144894Fa15FBDD7dfecC0F84F54A44B4)] = 1715100000;
		claims[address(0x0B1Bb662d21cd827b124C0beCb6f8959D962177e)] = 1724600000;
		claims[address(0x818EbB79b56D6d602Ff1Cf62DF713b28D9664053)] = 1732100000;
		claims[address(0xb6869Abc463725d6b51f1E5a621818FCC8320504)] = 1738800000;
		claims[address(0x357776615b79a3B3c1dAd11E5969d9E4bCcF9C98)] = 1740000000;
		claims[address(0xC0b83ea45CB0C8515cC8cA76F463E353c123d464)] = 1747800000;
		claims[address(0xBfAd1bBc61100Acf385c4CCAEaf5Af3E91934D58)] = 1749700000;
		claims[address(0xd70E6EaE7D216F9a64c0781D0AF1B567BDC1Cb4e)] = 1753400000;
		claims[address(0xD3406f22291758809DD5aAB6e4069d6492c97c75)] = 1757700000;
		claims[address(0xC0f57323d243FF1a0654e90bB1bD87b3f830DD90)] = 1758800000;
		claims[address(0x164461215ee3D3dcC66c5750fe4D366Da00b777D)] = 1772300000;
		claims[address(0xf23229fB7d9E9C3925C8F99fbFFe343DeBe80b19)] = 1776800000;
		claims[address(0x597d5fFDFE2e9c3072796D8259507306C15a4E75)] = 1800600000;
		claims[address(0xd7280849d04CB50705472590237cBeA7382374A4)] = 1805600000;
		claims[address(0xC59C17db7455e285c821Ac36268524b75b6F565c)] = 1814000000;
		claims[address(0x5Ee519d1C885eF70258c7fE2a48D67b5d1a3c755)] = 1814900000;
		claims[address(0x8746dCb2b0f28A0aBB3Bb4Ef8DD43B56733c9461)] = 1818000000;
		claims[address(0x09d17EcB8D79826618dc3c5eA6ac5202D959Ea0a)] = 1818000000;
		claims[address(0x9C4B76B235a82EFd83C0d26D179afDfCeED9E0d7)] = 1818600000;
		claims[address(0xFFdbA28a18EBba23D262A9422682066A3ca70c87)] = 1822000000;
		claims[address(0xA9a3a2a8Ef5bee083ecc0752474Fef658AcC7756)] = 1829700000;
		claims[address(0xFc10aC79Ca7741C370463c2De17ca804e88B1C7d)] = 1830200000;
		claims[address(0xdfC01Da2E8c053fcE824e3f83E7F37B4227E79f8)] = 1834200000;
		claims[address(0x9466357B3060AdA969Caf7cdA97cEea84AF2d083)] = 1840000000;
		claims[address(0xd750321B1fe482B4383094768746109391570606)] = 1853200000;
		claims[address(0x196e850bB5F8B3cab220b1C5e93c7C0567dfB7EA)] = 1854400000;
		claims[address(0x4Fe4c6c5cc4E9F2065faD25CC8cd41bBC656A28A)] = 1859400000;
		claims[address(0x88063bD993F8D50E4ab4c3C0965Ef131017E6b32)] = 1875300000;
		claims[address(0x4854FDA4737b62b2bD2d5E33e2B22959D83963C3)] = 1881500000;
		claims[address(0xfD84A20501655f40Cb0b7b9066AC7937Fa3835bb)] = 1896100000;
		claims[address(0x212608835CeE0a66E5864509829A84C07E51f8E7)] = 1900300000;
		claims[address(0x05FB9d34077D5846f5e74E784F94000EdD3dBba6)] = 1906200000;
		claims[address(0x82B88f2968f46aC027f9B50D21322a01ceeF2AB1)] = 1916400000;
		claims[address(0xEe8Fa23c194F6Faa5d0AD62D1cFa3B53769af174)] = 1922900000;
		claims[address(0xA228e71aBc6018650Fe26E9EfBB582F447af5E68)] = 1929700000;
		claims[address(0xF58BBed430BE6c4516d001fbBf6A0FC376CB3A68)] = 1940000000;
		claims[address(0x02d080F975FF18AA676b2F92dd579696bE2b5824)] = 1940000000;
		claims[address(0x6564b81E84Fe77B602347Df999Bb00cF060AE54B)] = 1940000000;
		claims[address(0xE27aF45FbD22EfAc81ed2fcda946b1785d153143)] = 1940000000;
		claims[address(0x9E4C4699E39AF9Db40c657E5a870A2aF1bc9A1F6)] = 1942200000;
		claims[address(0x6B0Bf3a6a042DF41dE060e096544bE11fEe312BA)] = 1944000000;
		claims[address(0x1bC9620DFf04fDE7DCE6698b5Fe30bCCcD069226)] = 1950600000;
		claims[address(0x234D1Acec50b5982B6aD343E3E4b1754D8d0Ca4A)] = 1952700000;
		claims[address(0x6527eB72b49353E1B2b4234e6c9B91fF40D7C851)] = 1976700000;
		claims[address(0x56Eb58b86db929A3797dD262A19441a5Ee61a180)] = 1979700000;
		claims[address(0x807ba816A3e81CbC2Fcef0311E7fe20c65383fa1)] = 1990900000;
		claims[address(0x0649A9164D66e29Ce6381964eEe3927B331174b8)] = 2000000000;
		claims[address(0x2676bF22326b71D2af7728458EaDd862d484b978)] = 2000000000;
		claims[address(0xdB7816f192dBbd9f5B709b9017f75EA3BB64cd3d)] = 2006800000;
		claims[address(0xf589a81ea24f51259b21fb47E26590FaA6CB8C7d)] = 2008900000;
		claims[address(0x9447c6fd48B025Cc3d15d052F4B61a3caf1d2566)] = 2011200000;
		claims[address(0x8e850D5cb92e2E8331031bAB61eFc6961333dAf7)] = 2016100000;
		claims[address(0x9F5F5277c1a83b90D0c6e4cf46CB280Cc541e00F)] = 2019900000;
		claims[address(0x4449eF0AFab70E83beC2CfaBB6792a238EDEe39B)] = 2024100000;
		claims[address(0x5e92a411A245e63f822c275f3B3314df1306E4fD)] = 2025900000;
		claims[address(0x40234d9d7330Ee393A5D8DaF3A6c97581Eb550c6)] = 2032200000;
		claims[address(0xb50864B80cDE38e6e722c55098c54c4EB6d7a8E4)] = 2037000000;
		claims[address(0xA5A1A5a34fB920cC2cCd69dF457101058911745F)] = 2053200000;
		claims[address(0x481CB2f58D76349712D87813AB2176D407C98fA0)] = 2088500000;
		claims[address(0xD483155dbFA04EE07Ce912bBE15a07faCBf8b034)] = 2092900000;
		claims[address(0xf2C4F87F30993386F9503c24F8683003422B4a5a)] = 2110000000;
		claims[address(0x352cB9d9984f5f7586502e49FE2BA84757681105)] = 2127900000;
		claims[address(0xA79fF5400619039C495511F51cdd3e763fA9fd71)] = 2143700000;
		claims[address(0xe6cf02934de033e0af7A415d3ef0e8E5840ed92c)] = 2173200000;
		claims[address(0xd932A7735AB6de3f1C11FC62cC449393F6418985)] = 2183100000;
		claims[address(0x0c44a85158586815a89E93842449789d036AFAe9)] = 2231000000;
		claims[address(0xEb67Ef239441f6328b7847c2EE20c14476CBEf71)] = 2239000000;
		claims[address(0x0A7557fA94719C3E17d38Bab4b18E7dFDdE75890)] = 2262000000;
		claims[address(0x9F6530b835b1D5F45480D453A960d9FFC1034346)] = 2286300000;
		claims[address(0xEA640C830842e9Fd5Bc92434f36e5F70F9f14A87)] = 2303700000;
		claims[address(0x6ec0244869052d1b68C3b65f12c5A1Ce4C13C127)] = 2304300000;
		claims[address(0x25863b9Fc9f970dc4f58e1f00BBCE6597eDF2E48)] = 2311000000;
		claims[address(0x571f11E4cd46bb5De6Ae6715996c82ca67f10C00)] = 2311800000;
		claims[address(0x8B3Fa653b227E14b2444e99f54Fe1AFcAF9f06C6)] = 2316100000;
		claims[address(0xd71B361D456c98E87B0541b0f4f636A6D7332F64)] = 2376000000;
		claims[address(0x36EFb0f235c393c1BCed1628fe62EE9E4d8E397B)] = 2386100000;
		claims[address(0xab869DB22D9FEd15A98aFF80f10d2C17691DF9a7)] = 2401100000;
		claims[address(0x0390877a933fcDBd7fC01F72B7C727090da123cd)] = 2403000000;
		claims[address(0x4353e26f7977a7c0cb64f1c4343eC59b5B64F5fe)] = 2403900000;
		claims[address(0x50E49452d8Cf6403c473B64510D3AeD56a7104Fa)] = 2425000000;
		claims[address(0x5E48AC4C9358220ed75809C724ee6E37a0593777)] = 2425000000;
		claims[address(0xdAA991B7635145fb88d6719Bed9C0c0d081bf4FA)] = 2431200000;
		claims[address(0x49BC591581a7957a13c064a72D8b46AC22CFF88E)] = 2435300000;
		claims[address(0xB975A09ce844aB10B2ABD9Ea704483e9E9Ae03f1)] = 2436300000;
		claims[address(0xD393D22a7c373595FfeB2036945174c570b9DD22)] = 2436500000;
		claims[address(0xD423b939Bb166e227d3049913a5F17f34a8B1574)] = 2462600000;
		claims[address(0x5f7D4c98672ae1aa60BcE3cACCcFe4d2919Baf0F)] = 2471200000;
		claims[address(0x570D2169Ccc21db2a9ef8Fd2f54aC8526e37b30D)] = 2475000000;
		claims[address(0x5fB211cf36ed3FCf02f42016E268705Bb25fdD24)] = 2475000000;
		claims[address(0x7Da6bBa3fca82a818Ed5e25b78Db2D795e685838)] = 2485100000;
		claims[address(0xFf469F74f0A7bbbeC2133aB859c4C9CC76be3159)] = 2491600000;
		claims[address(0xCd2a9a96Dcc34677A17E4308B7eD83347FA5031c)] = 2495100000;
		claims[address(0xBe31Fc0aE68fa301FfDa1dbe9074Df3CA0Cb4fE2)] = 2499300000;
		claims[address(0xc48de10441c9d4e11814f119cbE2bd784c888D8e)] = 2504400000;
		claims[address(0xE0A4ce187B95a024e6dE9541C049d40FD9F26B87)] = 2515600000;
		claims[address(0x8581e643159988C6824bDE31951535AaD4140e87)] = 2521400000;
		claims[address(0x9FAFa546f0124Cf8e2C79544bA1A866b1b84245E)] = 2525700000;
		claims[address(0x24506C743B0478676b7859539dD66d8a745E4e9d)] = 2528900000;
		claims[address(0xc8d7161D10032153fC14AB041C769c243303C147)] = 2540300000;
		claims[address(0x08A04b4bd4432294b51AEAF915AB5aDE5e4308Fc)] = 2546800000;
		claims[address(0xd28c5050C585cf2BB5bD9D9F1abD428382EEfDd6)] = 2606300000;
		claims[address(0x0649519A8B0090F9848639bF9C0dC22E60920762)] = 2607200000;
		claims[address(0x4610a371b3DB10aCce9039a0Ff47FFa30bCfDE9f)] = 2625300000;
		claims[address(0x0dCbebfb3edEe2c57036535a73c057adf55E53ea)] = 2625800000;
		claims[address(0xe7511e89a0945e1D0Daa241D0637ee55F28FE269)] = 2627500000;
		claims[address(0x86250F044eaB9FF00168F756a72c39F3c0820b71)] = 2627600000;
		claims[address(0x571C2b49b932a596de9C66401E1729e45e78e1d2)] = 2641800000;
		claims[address(0xccb43551b33fDcCc33e1750159DcbBb9Ec0a1903)] = 2646500000;
		claims[address(0x3562b2592495E8009eB3963A180907C1FD861154)] = 2653800000;
		claims[address(0x396Bb216088DF1B84E0b118b394180b6895dF8b5)] = 2656800000;
		claims[address(0xDc4A00ba1c1A48e455BeA0E1cEa6478975ECC0bC)] = 2671800000;
		claims[address(0x49370b2D343aE59C071b6dd0a1fD596ad1605De1)] = 2675800000;
		claims[address(0x6F095Ab882c53A3722881980AAd8090753d7779E)] = 2685500000;
		claims[address(0x76531b93c52EA6a64645D8Df8556D93752b53852)] = 2705200000;
		claims[address(0x5562a1730538916C366D5Ab9b30A31Cf4a66c2eA)] = 2708500000;
		claims[address(0x38Dde7c1A3C8067b9c3053Fad02bD339Fb085eD1)] = 2710700000;
		claims[address(0x5d862530253126e9cfc1C8daA1C7aB93B4a48fd0)] = 2716000000;
		claims[address(0x8efA96291EF7c15e13DA4067A3b54B7348983118)] = 2722600000;
		claims[address(0xffC1B747DdaB3D5eDa62A97C6a657Fb3A93F053d)] = 2726200000;
		claims[address(0x471a2664b64700db107D772Ccd999D359DC21613)] = 2739800000;
		claims[address(0x6b39Cd435e668CC444eF8f4656F11806E1C706af)] = 2768000000;
		claims[address(0x1d78aF529b75eb71Bb5183535d150771f0873363)] = 2773200000;
		claims[address(0x65f116AFF7201647FcA7c73DD6aCCFcB6cB29682)] = 2799200000;
		claims[address(0x969fDA415146398087f161082f97dF00FDA688FC)] = 2816300000;
		claims[address(0x20978d4495df2Fed87cE8524a5B2c6AB215e83f1)] = 2816400000;
		claims[address(0x926381B055ef82d73974C51Ce27Ed2334C3bf33d)] = 2835600000;
		claims[address(0x41f8ad0b04Ef3A3b50Ee08cCFca90d0c38F918F5)] = 2836100000;
		claims[address(0xAeBb57b0B32FcCbF0C5Cd2beEF686E4428BB3C73)] = 2852800000;
		claims[address(0xaC314B08105b63C8433467e3Dca589EF9259fFF2)] = 2857000000;
		claims[address(0x0853ef4F5C90EB6D7baCC7203f86A6FD27d9C2D3)] = 2860400000;
		claims[address(0x98964232B8242006516f59aabf2e45eb6B668cFf)] = 2862800000;
		claims[address(0xD4928DcF0a9F8aCD8ccD7fff963480a3f55Bd2ae)] = 2877700000;
		claims[address(0x497a9A869393444F1ad02b7b1478025ae778200c)] = 2910000000;
		claims[address(0xAD5E535881A87091560A4F05210DDE21B71d411D)] = 2910000000;
		claims[address(0xC80C3D7172FA24f0eadcd5d6dF95668B3EA2b904)] = 2910000000;
		claims[address(0x3390DeFb967e5f28F8924d2eEC1965973B9D239b)] = 2910000000;
		claims[address(0x6b759de29211281c2bF872cb053fF8c1E8eC7a2b)] = 2910000000;
		claims[address(0xc5f7e4CF8ff2f10EC994825000488798FdbF52D1)] = 2912900000;
		claims[address(0x146B5C6c6b60D11158C8ccf9eAa07ffe0f97c1F5)] = 2919700000;
		claims[address(0xc30d1Ada6087CFC0D7fbD8e84cCeEd988d61872E)] = 2925300000;
		claims[address(0xa4A1351de2827e5950fa709A196475A22D1BCB61)] = 2970900000;
		claims[address(0x08172c4135FB3130f2268Eb9AB4A4afeA9fE73BE)] = 2976800000;
		claims[address(0x5C7bD358203A589A384bEcfdE0A6921C2C0AE7B0)] = 2978000000;
		claims[address(0x7445b8c33Bc11fbd303AD7CC323A2b9353f4911c)] = 2990100000;
		claims[address(0xa6833BE3F7184fE9c3E949f4Bc5e6d9770aa0FcC)] = 2995200000;
		claims[address(0x8552146D3847cEd1f3091c976a406362eE65b166)] = 2995900000;
		claims[address(0xb75171A23C0013427c0e19183cA3b127ab30c7B4)] = 3000300000;
		claims[address(0x83D3310F412AAF9fC6ee6653D4ad845b358723A1)] = 3006700000;
		claims[address(0xDeEF569E3a6E841BA378C118D5f47b33534aaabc)] = 3007000000;
		claims[address(0x6491dF60beeE5192909184dc3b62466d7dD39470)] = 3017500000;
		claims[address(0xF8194fdf3B435406c4A352047a17cCD11C9ca5fE)] = 3018400000;
		claims[address(0xa235De64eEa4F4F404D86E51Ca64328831a852F8)] = 3021500000;
		claims[address(0x5797049C583F63aAE9f7E9266Db8bC915DaaDa4a)] = 3029300000;
		claims[address(0x1D834Cffb636aeCEAE5d45F8CbeFEB0908f00318)] = 3036900000;
		claims[address(0xDf4131f93e5FcffAb7587c0D56B5196D38717990)] = 3051900000;
		claims[address(0x81e15597D36259Bd4C9eeeA5Cc518082327707B4)] = 3053100000;
		claims[address(0x7B895a9e5C02Ed80f4C284c59C4cF5a02aA610c9)] = 3062400000;
		claims[address(0xddB5Bc4B7935DC50D610a25321B52636f823Dd71)] = 3090800000;
		claims[address(0x033388E4F1C0D5fAa8BB4A9Ab699655D01Be8b89)] = 3094700000;
		claims[address(0x00375Ea033a79D5350C157Ab3DCaf38c7c30E23F)] = 3095700000;
		claims[address(0xa0A4D56B6F74863133b32b81706e29AE0CDB9a81)] = 3102600000;
		claims[address(0x687794A97459342bEFFb799837b10a15c38AAc1D)] = 3113300000;
		claims[address(0x9F798680ACC3c3111f9ab58997bb027D6634e28A)] = 3120300000;
		claims[address(0x1337F76A790EC5fB2B97267FDe36529A828cE6a8)] = 3120900000;
		claims[address(0xac6bd3C095621a9EE29159Aea0FFC5a756C0b802)] = 3121900000;
		claims[address(0xDdf1B0EF104494472597F402F35de43075719228)] = 3125600000;
		claims[address(0x2F616dFCCec7d75d59f9056655E0B0567beCDfba)] = 3172900000;
		claims[address(0x98468c0e9342D4e0Ac3E09257251fab192992092)] = 3200200000;
		claims[address(0xc82D43aA08B52Cc94c15560c629B17cb3e2882A5)] = 3206000000;
		claims[address(0xd6E219590730F066E1415A461c18f067fF5789a7)] = 3209900000;
		claims[address(0x578DB00676Bf225CCC6822C3C0f3074218941E96)] = 3216900000;
		claims[address(0x811f2024f2B38AEB3d9e93930eC0BaeeDF76c80b)] = 3238600000;
		claims[address(0xa550639D8C0598405Bc979554f6fE36bC85e6532)] = 3258600000;
		claims[address(0x5ec62B71a4dCE8404d6b14238B67d46bD2A6bC88)] = 3266000000;
		claims[address(0x5D8f2D4C6A8B41b49dEA80F30BE19CD031a7e028)] = 3277900000;
		claims[address(0x2436Cea24B474Cd00fd1d917EA7E73088c6c818B)] = 3279000000;
		claims[address(0x2f26Bb1935DF1AeDc9355531925a5e58935055C7)] = 3303000000;
		claims[address(0xa0Fb4428Be863B3b247326651426C405124E4652)] = 3308300000;
		claims[address(0x9a251F9d445968A55040f66A0598cBCaa63FA335)] = 3339000000;
		claims[address(0x9e2C83Dd1B3890748d98C9c98f5a53511268C5ff)] = 3339800000;
		claims[address(0x3943588e0cAFeB6228cAbf10a7F58A95fE81BF14)] = 3353000000;
		claims[address(0x930bB4724D1c18DE996a3352Fd471B497E88f1e8)] = 3353100000;
		claims[address(0x958AABc529d86F61e50cBb13500a03f804Fa8D0E)] = 3361000000;
		claims[address(0x1Da72F13B05d91AeFbfB5e146105ee3E6e6FaF14)] = 3373000000;
		claims[address(0x2F543F9640B92db25BAe44BF469b16E547887FE4)] = 3385900000;
		claims[address(0xC2e5192687a6D327f29302bb776249f42a4cE88f)] = 3395000000;
		claims[address(0xc379e94E1fFeB59a36395186cA3Ed1bdCA4506DB)] = 3395000000;
		claims[address(0x95ED5fc3aa37A4433623B71e339fDbfe2F56Ab3c)] = 3399600000;
		claims[address(0x9B30F793c56E615B226402cbbA0d27eA71eac5C3)] = 3405300000;
		claims[address(0x78Ad1c9D5BA6077C75a3657DFf5DA01c6799a905)] = 3410000000;
		claims[address(0xC5D48fB0594B10E9Ef48029c33AE8dAB5aA2802c)] = 3438500000;
		claims[address(0xffbaa14cC536E1d4adf6E836b80be177125347cb)] = 3442500000;
		claims[address(0xD5937d7eAd542bE8189FCC404970068AdB9495ae)] = 3445300000;
		claims[address(0x7d77763528dA6529eEa255AF121A52CCfD75211b)] = 3457200000;
		claims[address(0xEc906Fae2969704856D0549Ea732Dd5370e0d6A0)] = 3464400000;
		claims[address(0xe198fbD9F8464D4f4f34247D7a8309F1eF33d565)] = 3483300000;
		claims[address(0x2939e6b743383b23077Aa2Ab68e710F83FA3c665)] = 3492200000;
		claims[address(0x90aF44c327E3948B8e1B2355f32795279326fE31)] = 3493000000;
		claims[address(0x1992a0f8d4C8C3E0a33F3B5c0e6a0dfD57E23C78)] = 3504500000;
		claims[address(0xAD14b468C13333A585D5814D02b8Cf516db3f2dd)] = 3514300000;
		claims[address(0x9DFbB01dC1C3411d13f0Ed8E10EB4Ad8ce9f03e6)] = 3516300000;
		claims[address(0xFC7ef2A6D36c8552169d3Ae726BC5009A2af7Ec8)] = 3519900000;
		claims[address(0x664a61406BC472c33e8860Fa3C5f0c05A7658746)] = 3524900000;
		claims[address(0x137e0B05e6A7Cf668761087032991b105Bceb42e)] = 3527300000;
		claims[address(0xda5da8857F4c9afE3b433F0A2a889C087da6A607)] = 3540700000;
		claims[address(0x28182B92E6DD48FfadE71f3f77EF4E5B785A8075)] = 3550200000;
		claims[address(0x2F17c6cF6dA7D7856A1032eEc413b91fc7A16312)] = 3569400000;
		claims[address(0xBD1dB75a002130fa24b4d96DE7941b6e5c722C33)] = 3574500000;
		claims[address(0xB74eD16C70f20557AFE188ce9DCE4dD7faA75694)] = 3593900000;
		claims[address(0x6e056F0CA4f337df2b016FC047CD467a195610ba)] = 3597600000;
		claims[address(0xF300F7Db860079cD2C2bc6F503afD7773b70d17C)] = 3614600000;
		claims[address(0x5875D918d32ec4b84B1d9cb16c0B97E7F3D94b67)] = 3627200000;
		claims[address(0xc520C237226f159885B1C4A726199c5C4dB18e84)] = 3642900000;
		claims[address(0x445b4cd1aFab9e54D3E679dD97bB8B080C0783b9)] = 3651200000;
		claims[address(0xB0148077D9A406c00B13ADa96c6Dc4069345A6dC)] = 3654000000;
		claims[address(0x2ed38d3D83713CB4D56e4380cddd0f0950DBb135)] = 3685200000;
		claims[address(0x654AFa4EB61bE2003C0b789d7f12966D5b5a4912)] = 3691700000;
		claims[address(0xdc0dbBB1E1aB815889D12893b8626da8A4244EdB)] = 3694500000;
		claims[address(0xd1ee559d5cE71f03Bdd14a1BB693eEaF2fC23d4A)] = 3698100000;
		claims[address(0x6E2E514F4fF21BB62889798905e066C0e5Eb7C5f)] = 3698900000;
		claims[address(0x1C23640dCf5D4d0a89935BaCA14Ff620F87Fd88B)] = 3763800000;
		claims[address(0x7Ad23ADeE556af7DbFca3D706a56A098E9C90530)] = 3767800000;
		claims[address(0x7416f61B47a82ac533C79C33C42b948F4E4A2195)] = 3780700000;
		claims[address(0x36D873Ad3690118521dAA8232E99a96A6466a2a9)] = 3791800000;
		claims[address(0x516db6bFA3bF852B44880D032C7F70013Ab6CCC1)] = 3801400000;
		claims[address(0x42f3a783b8DB7f9b66f822F621Cf0eeb546d998A)] = 3818600000;
		claims[address(0x057b8A59c9a51090B6D365Ba8Cd049d2C5EAbE7d)] = 3847200000;
		claims[address(0xfDf3e76b475eb404E8e68414379f7D069E789E15)] = 3869400000;
		claims[address(0x09dd4D176E46539129eb72c718a84dB24b98f988)] = 3880000000;
		claims[address(0x41F57C0304F50928FeDcE5DDfc20aE36467336be)] = 3905300000;
		claims[address(0xc2990459A102825F6664822d4A19Ee13acEC48ff)] = 3905300000;
		claims[address(0x1943Cb5e72cEf15a1Dd4dE9e624F64DEe23056B3)] = 3927500000;
		claims[address(0xAEa4c828Ac366c4A093be0019D93F0fB32087d4D)] = 3962700000;
		claims[address(0xC564673e6D372DfDAf43E14c16823895b56a8CB0)] = 3974100000;
		claims[address(0xC43afAafF80908BAa344afcf5991fd648586BFFc)] = 3975900000;
		claims[address(0x9b737b606133ec04FF5502a6D64C2793553cbde6)] = 3999200000;
		claims[address(0xC34c7bB74818AF847F4b5a2eA3916f219aDdd09E)] = 4009400000;
		claims[address(0x25650D6230B541532131afdcD676Fb995a800E45)] = 4018300000;
		claims[address(0x9c8eb756629b4c54F7c838964e13cE5e43c3807d)] = 4021600000;
		claims[address(0xCdfd524e028c035ed403F57249C589456Ee8542a)] = 4057100000;
		claims[address(0x46cA28D8bd2b45c859ec95099B6823124d262F59)] = 4085900000;
		claims[address(0x6DddD6EDF343fe6E110646e23De80c885E1936ed)] = 4095500000;
		claims[address(0xd3D6AE41581d243561218DA4A415998413AF89b7)] = 4099200000;
		claims[address(0x5ca9eEdd9A02B58A8cE032eA11D83Af7955de636)] = 4108400000;
		claims[address(0xFb87bDBC9b5F376E4866B1aC34a0D663ED541a86)] = 4112400000;
		claims[address(0xB02DfD2A85784755f8e1401d70740C47EdCE93a3)] = 4145300000;
		claims[address(0xF340C889a2E77f4BEcd8C6a73a941b7f80F5B4a6)] = 4148900000;
		claims[address(0x7E4173ccc3a2FCa8B6f6b11CE68c874665401E6A)] = 4153000000;
		claims[address(0x21eF9Dd6A7eb993Bc809BCf8d6342eb33c82e8c8)] = 4171000000;
		claims[address(0x1e61AD25A3a879aA810BE1711ef41285284b7AE9)] = 4200700000;
		claims[address(0xA7BcbD42e1AD51ef104848A45a6aFB130e57367c)] = 4238300000;
		claims[address(0x7F8BeB3C62f7128C3dBAC08b0C14be56A3b40Dc2)] = 4239300000;
		claims[address(0xedE66FCACbDA8b4c695Bc8b14ae7C4D22a2dD202)] = 4240500000;
		claims[address(0x272B789AF1153e5571d9FBa42B349D1301c9f9bA)] = 4264900000;
		claims[address(0x0A65E6d877b56471517b67BA42ae9dB1F2B62a76)] = 4265200000;
		claims[address(0x0A67595121228690D7a550ae0ab9F395368aCfc5)] = 4275900000;
		claims[address(0x13fC196cCc0ED092340D5388ac6B2cbFE34e7791)] = 4297100000;
		claims[address(0xe5bb60F9efEB5E88aC05F75717A8e8a4af400DBe)] = 4300000000;
		claims[address(0x5800fe003D3e73088f5448890e2516b42Da65Bbd)] = 4324000000;
		claims[address(0x6736d6b6E1F43737516a08A3C51D40ae74F8ad13)] = 4326700000;
		claims[address(0xb16F874b114B01f5D0E7831E1a4f57b49b74db7C)] = 4344100000;
		claims[address(0x1B4B8A2724f281E224D0BB9B8a652ad21550aC47)] = 4360900000;
		claims[address(0x7a28a2732A73321D31A8eE2120772ca86802D4E2)] = 4363900000;
		claims[address(0xA4140117Ac812ACd9d68D45dab3cfC8d766343EB)] = 4365000000;
		claims[address(0x658F42DE575d52Addc37A5B01617A4F228D7F182)] = 4384900000;
		claims[address(0xc0981cc35954483d59Dcd50C6e88D7f89BbAE092)] = 4394100000;
		claims[address(0xE8e4958F14f2600FBC32717AFf699E738E82d938)] = 4395500000;
		claims[address(0xf4100FeF70B0b68cff3eC14B180A5f03E5e750D4)] = 4401900000;
		claims[address(0xF340C30BE6ec07f08627AbCf202A36dF849351B7)] = 4418100000;
		claims[address(0xd8ed4516B4B082FF5C77b6d1CEd818382969bB6f)] = 4433200000;
		claims[address(0xacDda114dA3CC592a6B727aBc2bf11dDED2e4150)] = 4433800000;
		claims[address(0xE9Bed8C0016d76A9413a696B6C2c3F8D5FAbbE2A)] = 4453700000;
		claims[address(0x331bE3c9203E9224c8845160A8AB7505CB26F646)] = 4454400000;
		claims[address(0x84ef00ad9153220F54c85eB63510f410cE26dC51)] = 4474800000;
		claims[address(0xcF2bf892615c724e4c416fd6b40Af95E9cB9984b)] = 4504500000;
		claims[address(0x6c903d7fB50cCe82eA69FB12aB125654199c0f69)] = 4505300000;
		claims[address(0x3269fF7c25FCC0b082315327e795BAB5034865a9)] = 4522300000;
		claims[address(0xE9243b56aeECeA1E7259FD9C18fD36b7a047175b)] = 4524900000;
		claims[address(0x04a1403267D4B9ae6D938C0dF8CB918CA6587572)] = 4537800000;
		claims[address(0x02357e70F862CFCDfD00a431B3B4885C23faa42B)] = 4546000000;
		claims[address(0x21F947338e51FdA5Cc38fdf7fc8D7BaceBa843Bb)] = 4653500000;
		claims[address(0xCe30C8F0E1C0cEdc74308C2AAb11f30C82c8f5B3)] = 4659000000;
		claims[address(0xc38F91909E78635535B0287Bd0626468a2770576)] = 4671400000;
		claims[address(0xc9A0263Ecd13A60C6e514501B4AF5F97Ba40687c)] = 4710000000;
		claims[address(0xF3A2529F490D83749EE24324954bc5f34Bf181d9)] = 4723700000;
		claims[address(0x807B4eB03a92495F015274bdDB2b8caA05a895B8)] = 4735400000;
		claims[address(0x449423e554E2cD94Bf9Fbbbc9aA2634fFB56643d)] = 4736800000;
		claims[address(0x403355640e33d8BC281e79567494C800Ae583769)] = 4758100000;
		claims[address(0x6A403a3f4D0286C60f47A3EbBB825a0C44e32b56)] = 4778400000;
		claims[address(0x3679323FB114cB8CFF55E703907a6644216a0716)] = 4781600000;
		claims[address(0xB4c72f9101B03a5b8711c4e0D718b1A36C1C7f59)] = 4784100000;
		claims[address(0x990D23a58Dcd15852AF117d97FCcC4f57A233160)] = 4784500000;
		claims[address(0xD3C3aB11d209BbE6F9B955b14ab01799BbB02A41)] = 4793100000;
		claims[address(0xc59DC8082Bdd9Af15F0Ce0C148563FbaceDE8Df9)] = 4796000000;
		claims[address(0x401d5e11Db1AFA343C33767Faad54F43a40e7d82)] = 4809000000;
		claims[address(0xC272682D1a274d89c51aDFBE92D836497eA2bA8f)] = 4821600000;
		claims[address(0x31e9a505b1Cc67aB9c57d7BBf703B2b9087fde91)] = 4846100000;
		claims[address(0x001f5f16df3D70182d26925205Fa6462258F1f31)] = 4850000000;
		claims[address(0x5C60d4c31da342be700913B2614c1e39ec501C0c)] = 4850000000;
		claims[address(0x668BFe367071ACA14a2fC62EEfE026Dc749b2CD6)] = 4850000000;
		claims[address(0xc333e1597d83B0854D23F9d90cED0938Ee010af1)] = 4850000000;
		claims[address(0xd1a5666CD0294f66dC3864d3E879075084b3B3Bf)] = 4850000000;
		claims[address(0xD7259fE09952dD2cBa052e5179c786eB5885F1c9)] = 4850000000;
		claims[address(0xA346E143Ece024662Fc9FD31F318A70b2a5D30cc)] = 4850000000;
		claims[address(0xA02B6770B48cd5597DebDEA66A1DEA70B2CFC611)] = 4850000000;
		claims[address(0xFA5B9000b2AB32113ac4dcea76F18a27bB75C15E)] = 4850000000;
		claims[address(0x92f56ADc7cc6F58ce50Df4091d1d26ef17edFF45)] = 4850000000;
		claims[address(0xE0C9811dEC27eb1aB4Ce6EC003a582FbaeC9d7Ac)] = 4850000000;
		claims[address(0x7c0981F7c6a8872655477cBC46CD2D85302a9754)] = 4850000000;
		claims[address(0x7cf162204302C3860F3Be265a6e5a51fAF354716)] = 4850000000;
		claims[address(0x200FF627181E9721D28d6c42A840736EC05D24D2)] = 4850000000;
		claims[address(0xD19dDCe1f164e2605Bb7c287A5A33bFFa2b960de)] = 4850000000;
		claims[address(0x567e03715769F8748DE2678192E93Daf242cd300)] = 4850000000;
		claims[address(0x88a778426F226F4cc685d166527f7e58b74d86E8)] = 4850000000;
		claims[address(0xAf22CC3602985eF8626aA80ACC83834B3763F5ae)] = 4850000000;
		claims[address(0x4dA8a226FC9463257f280BB627467eBf836C61c6)] = 4850000000;
		claims[address(0xd0Cb1E713Ef60ca04FA3C89421c392Ac504E6A8D)] = 4873200000;
		claims[address(0x3996dF4488e7eAD79Be5C58374a02A7d7890cc09)] = 4888400000;
		claims[address(0xB2a3cC9Cd72C936c6d3fFcB258863726e60D0759)] = 4893700000;
		claims[address(0x1352c3eF2293d635d235baBcdbEd5932B289e921)] = 4905400000;
		claims[address(0xa509B019809EdB19FCe600DA5aD173548dA0a8fa)] = 4908900000;
		claims[address(0xD1b4A0D9301C4C365FD43a342C50fF1EcB73d96e)] = 4918400000;
		claims[address(0x3438Ad526adf28EC30F6626Fb06E052Ae8957DeE)] = 4924600000;
		claims[address(0x87Af1Ce171520E803b08BC8ADB267eEc0498499F)] = 4949200000;
		claims[address(0x5D66AcA08EA5Ba16125A2DD4446e8f504D8ef571)] = 4950300000;
		claims[address(0xB868cfD06344881475f3f59cF8824730bD9D8658)] = 4974000000;
		claims[address(0xb20402F1933Cf9FACdf97F058dC20859e91dd074)] = 4974200000;
		claims[address(0x9fAFE147623279025e736A524fC9a2e10C16E932)] = 4978100000;
		claims[address(0xc20982d7789739200AD6330Faf9788a3C15e773f)] = 5013500000;
		claims[address(0x773BF25425c33bEc8d9E73Ba9BCc903e2ceE8020)] = 5034000000;
		claims[address(0x0b791ba3d5b2Fb2c18fbFe4823971bFd82E7fC40)] = 5043000000;
		claims[address(0x62E6062E6365ab4ce6DB35Ac7eaaA2Bce7C59F0d)] = 5060000000;
		claims[address(0x1A20Ea3B4b986295f2ed115ECAad6424471F00B8)] = 5064200000;
		claims[address(0x8a2038148fFc93e69Ac43cDcaf65E1a7bd3755b3)] = 5076100000;
		claims[address(0xAC840BDf38315Fcfc9c0D7E66daEE33E69586256)] = 5097500000;
		claims[address(0xf988C3336E6D1BB5cA2e84C6679BC4fE95Dfdb87)] = 5111500000;
		claims[address(0xf9e3f72ECfa3270E9D3a259A49989D313aF775BB)] = 5113500000;
		claims[address(0xB0bA9773cfEC730C5e5a483FeD8322a9c8899ae9)] = 5114200000;
		claims[address(0x1808A3d9dF667223c84fB50b3C71C93136dcc013)] = 5175400000;
		claims[address(0x3b334fC2196330E95C7fe0001B03F23bC045cAec)] = 5181600000;
		claims[address(0x74bD3CcF221165b46d86A3Dd1209798f78ac9526)] = 5190000000;
		claims[address(0x8B994DD26856D7C1340E5F6E441aBFA95FC2A003)] = 5209500000;
		claims[address(0x89e92fDD28746BDbf0D97E27Fcb3C4ef5de04f24)] = 5226800000;
		claims[address(0x5E6805c8A75f903b2748C96ffe392A04FCa39Aa0)] = 5227200000;
		claims[address(0x131dE2f0dB905B30f7143712fdA550396B510F72)] = 5241200000;
		claims[address(0x109a555fD40591Dc2229f0eCBeD1f3a207A601b7)] = 5244300000;
		claims[address(0x23B240b298092F8eEd083AC8D36beFBCb84883a1)] = 5278300000;
		claims[address(0xA2aCa84CFC666f707931375B5c164927EA334EFe)] = 5305100000;
		claims[address(0xE5477fc84A4794C68369c33dDD21a5510cE20082)] = 5316100000;
		claims[address(0x84ac50876FA76417eaec3F01c286724F396a0121)] = 5319600000;
		claims[address(0xad986B2B972dE8f78BF978727744cd07e9A6E632)] = 5325800000;
		claims[address(0xDb8b4df452daEd3d7Faf1EFA597Df82Bb8B753C4)] = 5370400000;
		claims[address(0x4260600E2A5b6A5433c357aC6bAadd8cB96525a2)] = 5375900000;
		claims[address(0xcb9ab5C9B301145e12669C21ad7E0775D61475Cb)] = 5386500000;
		claims[address(0x0b942E2c95417c4BA2Ab55EFF67aB0BE63EdFf7b)] = 5418900000;
		claims[address(0x4a1B072B974FCF13c03fc41F38700046c5357814)] = 5432000000;
		claims[address(0x03746Cdb51C130954DC181D0d573EeBf36638FA0)] = 5446000000;
		claims[address(0xbB350147e371B8C5DbCC409bd679FB86c103cf35)] = 5447100000;
		claims[address(0x0b177e307e684c738152eEFFe1830F168756CD98)] = 5450800000;
		claims[address(0x3CE7379487A4430F09C6dA0B1253fC08D5014608)] = 5475300000;
		claims[address(0xc2Ff23DC67C8c19C646b44972078A13e34400eD7)] = 5500300000;
		claims[address(0xeC66bD8501a536427E36C1293802d5E3d13B4157)] = 5518200000;
		claims[address(0x06Df179CFf19F6C9B37bF37373214B1a54f23D29)] = 5531200000;
		claims[address(0xc79c8afd0C7a6f0642c7f23bca5Aa7e198bd24bc)] = 5532300000;
		claims[address(0x14b7c71Dc745088444FA693C36e9B5aE3e486556)] = 5554300000;
		claims[address(0x372cC7c7ccb044486b7AEB3FA7C6e971e37A2D44)] = 5566500000;
		claims[address(0x8bF12f9e30f54b94f3976E024bB8Feb0470FA878)] = 5567900000;
		claims[address(0x4D03c0d21D4aE6636fE5282EE183DdF59454A902)] = 5586000000;
		claims[address(0x8Dd1DD6aBd1fb40396761125269a34ad6583Ece0)] = 5593500000;
		claims[address(0xF2C9D73734a89Bb29aDFa4A5892E3f702506D059)] = 5606100000;
		claims[address(0x66Be07d8A2a03e49284f01aFC31A89E1E7caF42b)] = 5607100000;
		claims[address(0xdc248aD79AeC36Bb2d55F23D14d33a2BA9827ab7)] = 5608500000;
		claims[address(0xC6E4A17B5FdD7Dca9637dfAA7cC7aE091847017d)] = 5628100000;
		claims[address(0x8A82AC1b60b281784bA01c36A7E28aD719d0503D)] = 5650300000;
		claims[address(0x0bD91b289851fa852Cd27A113CcD337654Da6eBf)] = 5657900000;
		claims[address(0xdd1425BE64D2759929a95213EF29495Af8d3ACfc)] = 5660800000;
		claims[address(0x211950e464877b20DCB08c57F4f0fD1CA5caceEa)] = 5687200000;
		claims[address(0x994922908057aC44EB0bb13EA9EeDCaC46d4B42e)] = 5700500000;
		claims[address(0x8b8aff8C2BaB41Ec525DaB66c1fd4BFaf514bfE4)] = 5737400000;
		claims[address(0x3E2dAD596f27B1ee9e713E02AB4DC2d85cB0E38C)] = 5742500000;
		claims[address(0xED3452E3F8146c702D8dd6809d5bAfb1229C7025)] = 5756900000;
		claims[address(0x5aF1C7B1503b75C8D185e791D34fB342c2528AC6)] = 5763100000;
		claims[address(0xC254Aa6dEEAD9ADfA17F513FF6a643B2Cfb73293)] = 5790600000;
		claims[address(0xdE29496D502003405cB085839372154609ed61eD)] = 5793800000;
		claims[address(0x4d7Caa04E0729c2220589875590DcE6673829831)] = 5804900000;
		claims[address(0x2eC8fbFBe5B48ca82fA002A61f944F5f8d056147)] = 5810900000;
		claims[address(0x5593e024AB9D53B2209C121dD31daE3cEFb25026)] = 5811000000;
		claims[address(0x6752084cBdFF94FC30Df6c1F724B01417DB70A3e)] = 5812200000;
		claims[address(0xFAf406ab2B00a1B90db515cE5C0C2f96804C6ae1)] = 5820000000;
		claims[address(0xbDE36F8E56Ed6afF51C869A844cc768ab4dfFfa3)] = 5820000000;
		claims[address(0x2F0bFDb78720a2bF6D594cF668c880E2717EA66C)] = 5820000000;
		claims[address(0x3Bf7234434560eC916065D2f70DaF34fD7B9fe02)] = 5820000000;
		claims[address(0x8E582C765C53A530C0A09C51077dB465795F172B)] = 5820100000;
		claims[address(0x0A0751D7099a1eb2d9bF68BfCC144DD186d66a3E)] = 5820100000;
		claims[address(0x98e5Da803ddB98fb8a51E981FBbAf8d187A44156)] = 5838000000;
		claims[address(0x4e5e8c9f83830365994269943B28121843BeBed3)] = 5853100000;
		claims[address(0xD99fB5E3e06aE0A68FD08994dFd46768Bf36a223)] = 5889800000;
		claims[address(0x92bBaA1BF1FA02c18D5131c3a85aBF045196A0e9)] = 5898000000;
		claims[address(0x70905cb29751E5bdD04C5064Be35892ef0B6c8E9)] = 5928700000;
		claims[address(0x91D130c3cD5F95Cb4ad576EA32571827d3089824)] = 5935900000;
		claims[address(0x400Aa77a917B169C0116acC36A75BB683862494e)] = 5943300000;
		claims[address(0xA0bD8001327009e2b5483e36EE4708D88ac4b40A)] = 5989800000;
		claims[address(0xb2B28250150eFDe0Bdd31bDe777b6d40F50eBdE2)] = 5997900000;
		claims[address(0x168310A1111953D9E259f7c03f0E20f2BC27ED7a)] = 6005300000;
		claims[address(0x3AE9d103AC1553BB71854166dfbB52EbFfB7fd7b)] = 6007800000;
		claims[address(0xf1b3F2898b080e8b06b38Ea7aC6df8c6cEFF5A89)] = 6029500000;
		claims[address(0x2e90747Ab932Ab45131Da71F84BA612D5256ADf4)] = 6040700000;
		claims[address(0x5c30D13ED5A013932aEca72C74A7D9547375a3d2)] = 6055700000;
		claims[address(0x74E3bb79fC64547096144ef4E8Bd38aDF8F14209)] = 6058700000;
		claims[address(0xA2f832bbc3AAd3a68C746fbFa923A0FBaa5dc5a6)] = 6078000000;
		claims[address(0xA917D32Df3961bEb53C7A18283ca0Be9722c1214)] = 6091000000;
		claims[address(0xe837c7a1348516086E603E23F1B17Af98fB8AB37)] = 6103300000;
		claims[address(0x8D21a389da62dED6B3E31fCb2ceD7A47ac29Ed79)] = 6109500000;
		claims[address(0x0be473dD156588F7d64c624679A6274C27cc0795)] = 6111200000;
		claims[address(0xb7eEbEBF5407531ABe15865b5E353e08D365D575)] = 6118600000;
		claims[address(0x01A9C7f1BC3545158974EbD3d37c186A8181be54)] = 6154100000;
		claims[address(0x213685B5ba702267710E6D4eC9b81DE986304Ff7)] = 6160100000;
		claims[address(0x8Fe631C4EF3Ece07E63BAa853641C21874Ae721b)] = 6194900000;
		claims[address(0x9eFD2D33c30d42F35b015d1e27978AAdf40d78AD)] = 6198300000;
		claims[address(0xDf43c4b9b97ff61AC6C596f2deCb5b10c73D0B41)] = 6198500000;
		claims[address(0xB3374D21619d546621077eB74cD2E74da79d1b71)] = 6208000000;
		claims[address(0x9c64487230BFbB8881967007d31B08a534D4B8d1)] = 6217700000;
		claims[address(0xa06312988e5aC26503dAec60D1A9f1A696Fe8Ef2)] = 6225800000;
		claims[address(0xaBc642E9797642Db8ACF7d0d564ff9f0f0c10778)] = 6229600000;
		claims[address(0x8965e7BfbC092655ab6980F1EeBEBb387a7b2ffd)] = 6233100000;
		claims[address(0x699FCAabe14a40d43f092B10220a6E77A23C0682)] = 6246200000;
		claims[address(0x50876E1Bb47a661bEed13599C7B4af7ceB2DF973)] = 6255300000;
		claims[address(0x694f0FbAf02A84dB71E758A22f0f00ea4Ac8E664)] = 6264400000;
		claims[address(0x94c0F2aaE9f621D3D4B720ecFA8294df10d7C60B)] = 6285800000;
		claims[address(0x02716a1BD2993afD65379F8DfA057FC014a8fD75)] = 6292100000;
		claims[address(0x517a00e480635783dF24D38F0029cB704C91e9F9)] = 6305000000;
		claims[address(0x7d686a535e25866c53ce77A8bcDCA5fbA89955C0)] = 6309800000;
		claims[address(0x46B9f0F423f50050C50E24C72605c89A8b30D170)] = 6343100000;
		claims[address(0x4860837BE5ef910679EacfFB52d907E248D0a22f)] = 6362600000;
		claims[address(0x100e7bF191a6819De0314b7Bc50AC0c64c3CCffe)] = 6363200000;
		claims[address(0x09159Dc84f3eA7675d4dF514f864e3bfDfc482d3)] = 6367400000;
		claims[address(0x1777D1023785cDdE56b4E058344bdE33c07d81FE)] = 6397800000;
		claims[address(0xB071dbE5cc57150b21Ef6C4da022beb1c887474A)] = 6416300000;
		claims[address(0x0135230a8997cCe344154bC06A69c7D9f541e6A8)] = 6422700000;
		claims[address(0x7151d6755c84066a9abc103FEf16c7A63C216f4F)] = 6429100000;
		claims[address(0xD9D095576D4d4e4d8101B769191c51b72aA498F3)] = 6450700000;
		claims[address(0xe1FF0aa8878E44F3A7F2d706d2091Df2A7Ae5f7C)] = 6455000000;
		claims[address(0x8055B0c9A126Bb9a729b90f981177623bf4570fF)] = 6486200000;
		claims[address(0xC468f59444616E49305649Bb24279BB6A83200D4)] = 6516200000;
		claims[address(0x68dc545906718384813F1883b49214B1b5bBD403)] = 6519900000;
		claims[address(0x3bd03E50B16bD1813D0356A641762E698718F280)] = 6520000000;
		claims[address(0xFDf5B04b18a1c3B5E6f76eD59C64d879e5690eaE)] = 6520200000;
		claims[address(0xFEE3D0ccA283d6d1442BbFFD59C254333D4eDD7b)] = 6522400000;
		claims[address(0x4aE2f9751C17d5694621030F2650C3dEc9af4B24)] = 6523000000;
		claims[address(0x9C877eAE6Dc0e0837221Fb19Be3B93328BAE4164)] = 6533200000;
		claims[address(0xF98a5E1ec0c49751CFCc94F5Af9b715c443029FE)] = 6553700000;
		claims[address(0xB6C8aD5ac0442aaa5990c2e4C55803E26b732A56)] = 6560500000;
		claims[address(0x18ab86C446a0199a184a0083E948fB3f8a87BB7A)] = 6561300000;
		claims[address(0xFbF6d5313E4271769AE712e888bc04123880d2d5)] = 6563000000;
		claims[address(0x1D19E9b4289f5C0DCCaB32D6Ff479Da4d4DeCc99)] = 6580600000;
		claims[address(0xF9808cf0e92A351ed90D90a589382B71c6E434a6)] = 6606000000;
		claims[address(0x31c8dA10668e414F18d68C1fE0E858a5d1dE0138)] = 6607700000;
		claims[address(0xcfC3e86debcaA3813418994faC09fa98B1C3fd5D)] = 6624800000;
		claims[address(0xA8C666515f662a076Bebd92E816731e7f8b5268C)] = 6652700000;
		claims[address(0xdbd37058720c20FFf0d5200Bf67232653acEB3DD)] = 6692100000;
		claims[address(0x03c74ED5F8F3c6022D467698fD6bEd97A672C03B)] = 6713100000;
		claims[address(0x6f829e73e3979DFeF1cd18a7dB5f53bf9aF41211)] = 6718700000;
		claims[address(0x9eD59BaEe57bE1B75808e0f31d614696f327Db36)] = 6735700000;
		claims[address(0x981e4bAE364b712290ee074A6d3625941c2dfA16)] = 6743200000;
		claims[address(0xa445958Dac28ab7682FaAc29c718c7f0B57ABb55)] = 6756400000;
		claims[address(0x9B6bAA1a906145DB70858B03Ec9FB1F515Bf1f0a)] = 6762400000;
		claims[address(0xF52546cEE2E3c69B83A0A7030acD0Bf83cb8e51F)] = 6790000000;
		claims[address(0xe0B4145E78EA795eFA430427cC2975B03f4306B5)] = 6790000000;
		claims[address(0xE8EF80A0Ba2440ec3eC3A27FA5F13FD2e045fe33)] = 6799800000;
		claims[address(0x5Bf4edC7d02d5eE20506A86ECC9DB1feD139FaFc)] = 6838000000;
		claims[address(0x3c3b673486Bbae82a543A016e7CCa96e348E524C)] = 6863200000;
		claims[address(0x869c1a098e324d773Ef1d2F1B0Df8BbDADE7813B)] = 6867100000;
		claims[address(0xfDd688493caa1B0191c138028f4D874f0307f48B)] = 6870200000;
		claims[address(0x03F689B252aa0436D3CA52C978d9a22735704B3D)] = 6916900000;
		claims[address(0x778aB498977F5870EAf361FAdE09fF700869028D)] = 6934200000;
		claims[address(0x4132c98e5014C5E1FfF98A9D1126EFaB086FCcA4)] = 6947200000;
		claims[address(0x67Ad91cf29B13237777b5aE24C1fb42aE828F4Ec)] = 6949100000;
		claims[address(0xC16D03879B158604958A7bAE8b61763c2953a5f2)] = 6956700000;
		claims[address(0x995Cf67F70fC2d7286953b86FD5F0e8c184d4E62)] = 6961100000;
		claims[address(0x5B7b3a77C0E5De980D2b42cdb03155986Ea7358e)] = 6990600000;
		claims[address(0x9C180Ea177157FdAa28984918A2B224dCd62bD60)] = 6991900000;
		claims[address(0xafD889880909b41e7f8c3d662c6c93b7E89d2080)] = 7046000000;
		claims[address(0x1ADC0e16b54d2686E11a64ac412a6bc510b5b92F)] = 7065300000;
		claims[address(0x4B46Ec03739Ed46a51754ada728CfC521c7a2FaE)] = 7069800000;
		claims[address(0xEfFaEd8CE77C6eA9653c5Df4c55b27166dC4DDC7)] = 7077500000;
		claims[address(0x47378a98bd1CB6C397bBbF879e0e5c922D6b2205)] = 7101100000;
		claims[address(0x1870234BC090926205F86e9263ADFBdb05e81D9d)] = 7116000000;
		claims[address(0x85f8CD0F29258643Aa66f4b9BE8E3AEEF8d4C595)] = 7136400000;
		claims[address(0x2bbb3Bd41Df73C86a962eD9cC077dEE34E884F25)] = 7141000000;
		claims[address(0x73874166524175e3C7787B4D949A2Ec6896AFC6F)] = 7169000000;
		claims[address(0x58C66A1efff09F95934D6dE4Bae24e5d8c4fD0fF)] = 7188500000;
		claims[address(0x198593c9431C74e2192E4E3a6f490D197f7bBd36)] = 7197400000;
		claims[address(0x1A0dE78A106E27453438b4e775c79Df9973F9bD5)] = 7207700000;
		claims[address(0x9Ea7E78cBb113Cd7D658DEb1AeD2B88cBD7FcD97)] = 7215400000;
		claims[address(0xf46857226E6cfeBD99569B43c1B15783f3915D4b)] = 7219600000;
		claims[address(0xff550E7AD401d8c9C36292BE9Fc630f076eb9Aa1)] = 7229500000;
		claims[address(0x5B379941f02f806267C55bB587aA8636f9771932)] = 7230900000;
		claims[address(0xb720D2d5CeDA4C3DBD19cfFFcb6201C9eCC5A7dF)] = 7253200000;
		claims[address(0xEd73c6c0dc06467fDcE4f3C939A8189328969152)] = 7257600000;
		claims[address(0x92a04554a26aAC7E1eAAb7Db6Edbf8104cAb6b1c)] = 7275000000;
		claims[address(0xE694E04156e39e1A4DaF8845d31fB4A43417a7d4)] = 7283100000;
		claims[address(0x7004c7890CE7F34a3EEd47870fa92E2971d60877)] = 7290900000;
		claims[address(0x5f6943Aa75EF73D4B54d4C9Ac75b09864EF13635)] = 7340300000;
		claims[address(0xA7a97C3B0790A4BE6F6390dfCE5a1E3A44904ab2)] = 7362300000;
		claims[address(0x107256E1d459f198e227eaCA8B6909b172c5A335)] = 7386900000;
		claims[address(0x4Bc91323D1740D48C62849F8dF2E61238F227867)] = 7403400000;
		claims[address(0xcd907c9Ac2e101F0c282Ccc7CfAecfC67454e602)] = 7408600000;
		claims[address(0x54eCd3d8052d1afd746754F5647Ef198FB8a93E8)] = 7411700000;
		claims[address(0x7991205A6f6e852eE12C09218AE273810018e031)] = 7428800000;
		claims[address(0x4bf43929Ea6898e5fD5e9e8e59CB4bE8a4a3789c)] = 7431000000;
		claims[address(0xAa077f58C8c7F3DEb79D28Ea478DF1a0BbdA1DCb)] = 7437600000;
		claims[address(0x18b57D63Ae7Af4267ba1F278f88939D7464dDDB4)] = 7437700000;
		claims[address(0xa8963cB4984806A6C82170993815fE7Fbc2F599C)] = 7448100000;
		claims[address(0xa794512EE2e45C850275828AF24a290F19b43abF)] = 7474000000;
		claims[address(0x0C769b641b1C0c0A3Eb7772B2CB20ea5AF8fC715)] = 7480000000;
		claims[address(0x9A43C33fB5b6abE8C11081b4d45dF16307D0c5a9)] = 7497600000;
		claims[address(0x396F7ccb93A252f0a0Ffed73E08C2622a13518D2)] = 7540200000;
		claims[address(0xD219115E8963e5b0a4f30Cba384CAdDdF9030D09)] = 7542300000;
		claims[address(0x0db4eAA5a9999992895eCa79Ea80bB83182F7982)] = 7544400000;
		claims[address(0x4d53C6FCaedc1d6C93AAF8Da3C578b5BEeD5b96D)] = 7544400000;
		claims[address(0x0B1eff516b3cA623285b45A1d73b929f40cE9FC4)] = 7546400000;
		claims[address(0x24df488A8192eb804879B92F1C25b5DA4474C3CF)] = 7548400000;
		claims[address(0x36CCb4aD668a3bC8b00CaeB74dD93d1C70471deC)] = 7553100000;
		claims[address(0xF0FcDC2996B36e70e24208B0Db5C19462AB0f740)] = 7555600000;
		claims[address(0x993402C99baB39A1Bc2488848b6D45FAb4c813D3)] = 7572700000;
		claims[address(0xe0568392e8D5188Aee4aa829E4dd4882F75D647d)] = 7584600000;
		claims[address(0xAdDE9143b7CAEFEB5e2697b8A67B90Db1E734F6d)] = 7591900000;
		claims[address(0x425A8b56D2587Dd404abE043689aeA1c70B5a757)] = 7606300000;
		claims[address(0x5dEE5cA080B3FfE23b75ba4914abAEaB996a1dF5)] = 7619100000;
		claims[address(0xdc4C685fA8E1b6784a4E6713c84F4661C0d42865)] = 7628200000;
		claims[address(0x2649cDad9cdCF010a9065B765E7f6e51e15cdb11)] = 7659900000;
		claims[address(0x308f26DFaB41053226150Ce5be5Fe13059657725)] = 7699200000;
		claims[address(0x68564C578A9D88f6B4d25A5244C3402620eDB291)] = 7704200000;
		claims[address(0x7a0fc1e54b46bfcfe20020296bA493aa56c25021)] = 7749800000;
		claims[address(0x7cF2E058C3583E153f75BFf5D3d3B874056AC7A8)] = 7760000000;
		claims[address(0xaD0193C45B462Bd639cA9e6834E36ADFe61871c1)] = 7760000000;
		claims[address(0xdb859FA4Fd3a60B51b764E9d2344A91608e6Eb63)] = 7761500000;
		claims[address(0x2ACD9767b1feF26403Fa47BA368B57c0D447cfB0)] = 7762600000;
		claims[address(0xA015193B549683b5C31851e54b5f9eAe61b59eeb)] = 7764900000;
		claims[address(0x7cE02Cfe28D4bA6F32E67f643BA034c694DACe59)] = 7801400000;
		claims[address(0x4c66c4EEDaD0a8fDadA70077c400664Db5df2EF1)] = 7819100000;
		claims[address(0x618C3dEB380903BD63289ed6a8FCfFF702845896)] = 7824000000;
		claims[address(0xd6E56cE7E16DA6Cd3d33a2237BEa63CEFa44cf33)] = 7861500000;
		claims[address(0xe5D643764A885C219A0562946C7565CaEd27aFB0)] = 7863500000;
		claims[address(0xa7c5107cdC568EfcDB43be44fB7Fcd3287E86A8a)] = 7883700000;
		claims[address(0x925300832475ADd423697b61D1e4f115f3df8C25)] = 7900100000;
		claims[address(0x3D9e01B58Ae73F8DF8B7204E1DE5Bb3550710bDE)] = 7934600000;
		claims[address(0x7117561c251735ca6A11D733bcd4067531629815)] = 7981600000;
		claims[address(0x854cb3136C32E2898be5625Ae1385c2DD35051c6)] = 7986300000;
		claims[address(0x7400E5a237296D0B13dE088DfD9fa9d4B54311fC)] = 8007700000;
		claims[address(0x055D17C1cd8ae37A517d08A5d3AE592Ac210b965)] = 8011300000;
		claims[address(0x6C1Fbf1a2263189467737CfD52865F606E43cFaf)] = 8033400000;
		claims[address(0x8b8fa03Eb849832D784d01Ca26502d42ffe137b7)] = 8035900000;
		claims[address(0x5Bf2a1cAc8f3A2f48cd9237885b7F33285E8a111)] = 8051000000;
		claims[address(0x9DD1Db21CCD51f7a5d795503C94452977c924B5B)] = 8073500000;
		claims[address(0x3B6572f1Df4AC74Acc19b9c714486B8bAB0213F2)] = 8082000000;
		claims[address(0x59556E4c5c6562b14085788DDb5B3B134D00Ff1b)] = 8088900000;
		claims[address(0x65131dc9372189a02dc6c8FA231C8895ae7fe0f3)] = 8093300000;
		claims[address(0xD878f9de0ac862EF2d0de5299348643Ffd2a373d)] = 8109600000;
		claims[address(0x0C77Ff258A6C50c73c854CB46546099Faf0852a5)] = 8115300000;
		claims[address(0x8AA402C9119c99eE2E2AD1D8B84bc002d15cCc99)] = 8124900000;
		claims[address(0x344A164d6558B4D59765815613c418501118aEa8)] = 8136400000;
		claims[address(0x7b8A466A5145B80f93362f9a0b883C3cF3685a59)] = 8183600000;
		claims[address(0x3B84062E11902e9A094500d1E662aa106A668da3)] = 8184100000;
		claims[address(0xC3B2884E227cFB5B2901bA11B6a55C9d0cc3f598)] = 8197600000;
		claims[address(0xB253261aF803aAcEf96Ab5B78cBBd331aa902f5b)] = 8208000000;
		claims[address(0x61b7d048cA530919250B24C4505ECfD296872019)] = 8209800000;
		claims[address(0x97d6996a090635B084cd117eDfaf00cBA61693c7)] = 8215500000;
		claims[address(0xBdd4305c44aB9f0F9CB2f7d3Fe263Da4454a8963)] = 8220200000;
		claims[address(0x04c93005E3D1257f7cB1Dd337bd2F0E8af3E1D3d)] = 8234000000;
		claims[address(0xAEBB17b5a7aA3fEfb585319B6447A6dAFC42B27c)] = 8245000000;
		claims[address(0x613B1aC728f1cC8E210945522388D7A879238C6F)] = 8269800000;
		claims[address(0x7a7217eebe1B095A41f6cD1102b5C5646Bbc2Cf6)] = 8311200000;
		claims[address(0x7d5B0E1bA80aA50c36BD95d94c49F9EE065C2EE7)] = 8347200000;
		claims[address(0x054559E5eadaCd9EbA136D49b89C54bD7efa9573)] = 8426400000;
		claims[address(0xa99Fb5a7606bd3Effc4AD06E082901a16761cbE5)] = 8441700000;
		claims[address(0xbf651e76036bA62Db8a23ee1aC70060520565B96)] = 8455700000;
		claims[address(0x88991915D74D6b78110b4db5D07FdC699c738EFA)] = 8460700000;
		claims[address(0xa7846BFE0FC80DF2Bd978566C2d3d4a9E30bdd1B)] = 8479500000;
		claims[address(0x17cC8f96300DF01Ff236dF568A8A89E0316AaA3f)] = 8480800000;
		claims[address(0xc1e8fA2af1fbcD66E3cCbA777B8A220BcaE83554)] = 8493900000;
		claims[address(0x2612DfcB755E11621E65Fef405Db6aDC668E21b2)] = 8522400000;
		claims[address(0xda377eBc1788145b56222C74483C3740Ee6207Ac)] = 8548900000;
		claims[address(0xCB0F020e48E222E50E85102e0796d603C5556312)] = 8597100000;
		claims[address(0xf74ABbb9F7EbBce513DCb2189007fF9532A1AF53)] = 8603100000;
		claims[address(0xBB6E486BAb511dd38B60a573e1cba704c85D2b3a)] = 8607200000;
		claims[address(0x8B42Ff915897D08f7F312CF3731a15751Bb6032A)] = 8613400000;
		claims[address(0x0c2aF4Cf548ea6dac2e83667fA6a34D698375807)] = 8622100000;
		claims[address(0xaFD718cec3f3456395fa0dAcceeFc8800fE15B29)] = 8649300000;
		claims[address(0xF9D437790E5344Fd9091aE50bCaf700280E11cDD)] = 8656200000;
		claims[address(0x9011E3474E0e00C6Bd3e9F0E4701AeD3D919a5Ac)] = 8706000000;
		claims[address(0x938A1e9e84e6b8b9d1F39F1A71D1920B50EF6AB5)] = 8714200000;
		claims[address(0xbF278C33bAB8910F9775C95272070772f52a0682)] = 8724400000;
		claims[address(0xEA3456a4375748a0D6997161F0Ce299f258D0dCD)] = 8729300000;
		claims[address(0xaF4A2cE734A1aF0Ec26c041e483c36bF5820D7F9)] = 8730000000;
		claims[address(0x998cbb4F6afAB14ab15E3bB7a014588F514C6916)] = 8730000000;
		claims[address(0x468d56f1A8CdF09E7E9F3253eC2d0445bF12c97B)] = 8730000000;
		claims[address(0x3a9D015cE58F5aC47275E4fdbd2570c61b1AB453)] = 8730000000;
		claims[address(0x50B18654d567b5d51C8987fFc04d19c1fDf97e40)] = 8730000000;
		claims[address(0xB8222182AAEE3C4E4DECAB125F117CedD80A56C3)] = 8730100000;
		claims[address(0x6865413CB1734B90eA5d7c524C16D5878da51d45)] = 8730200000;
		claims[address(0xC28DFB9084e6197Afa27F9fA82Ea36CD2579CC0C)] = 8751500000;
		claims[address(0xE1fb872C48a342C1D3B02a26a4D5f29B58397838)] = 8767800000;
		claims[address(0x281eC82e8fdAFA1252d8e0AEBC0F51F6bD13E6dB)] = 8768300000;
		claims[address(0xC7518c72aC750aad9d6F5233DBf919484085002B)] = 8820900000;
		claims[address(0x64cFD8F6324D0dA34596ea26E6c6CC300301B17D)] = 8830600000;
		claims[address(0xe061Ac08A84FC1542F7fB10dFE214529851AddEa)] = 8864900000;
		claims[address(0x8B5f204F9e30e852BF72C3EBb1601A2697fA742e)] = 8892600000;
		claims[address(0x6A076E51A71e77bA026257A861cE29ac17B90EE2)] = 8892900000;
		claims[address(0x0735140d85A8e030f9C572BA4c91d0F9246F8462)] = 8898500000;
		claims[address(0x7ac41cBa8138305A5B4054F64C320118a5F78841)] = 8906300000;
		claims[address(0x07a233BC5B9Db706bfBfB139a992D2234a47eE1B)] = 8920400000;
		claims[address(0xEFE367761a33d88e3cf20Da0C3C7B08Bc74fCC09)] = 8924900000;
		claims[address(0x9A6DE991721420C79C9b8fFB268fb76DA4E88786)] = 8934200000;
		claims[address(0x4D677cD1E355dd604F6697Ba6f86D940771b106f)] = 9010400000;
		claims[address(0x98D226FEA1bEa89315371666485387e41ABb84B0)] = 9021300000;
		claims[address(0x979722bC56FAcd845C0DA4E201c6A269c8799F14)] = 9037500000;
		claims[address(0x0B9924ee30409b5C077dBF56d088f344dfBeAbB9)] = 9045300000;
		claims[address(0xE174546049f7AfdBa757aDAe600544FBe5755aD5)] = 9050200000;
		claims[address(0xbE13A982dE278b62c119174D325e3132d6c6B2bf)] = 9057900000;
		claims[address(0x4d4Ef149C8Cf103933252dfd141322A1DdBF3c47)] = 9063100000;
		claims[address(0x07ce07Fc5C5C79Ed68C78F45BbC3623B3bd776ad)] = 9113700000;
		claims[address(0x52bE31b9CFE531512aeB6259D38E1d4CD4838320)] = 9118000000;
	}

	function addClaimant(address claimant, uint256 tokens) public authorized {
		claims[claimant] = tokens;
	}

	function removeClaimant(address claimant) public authorized {
		delete claims[claimant];
	}

	function addClaimantBulk(uint256[] calldata tokens, address[] calldata claimants) public authorized {
		require(tokens.length == claimants.length);
		for (uint256 i = 0; i < tokens.length; i++) {
			claims[claimants[i]] = tokens[i];
		}
	}

	function addClaimantBulkSameTokens(uint256 tokens, address[] calldata claimants) public authorized {
		for (uint256 i = 0; i < claimants.length; i++) {
			claims[claimants[i]] = tokens;
		}
	}

	function viewClaim(address addy) public view returns (uint256) {		
		return claims[addy];
	}

	function claim() external {
		require(claims[msg.sender] > 0, "You have no tokens to claim.");
		IBEP20 t = IBEP20(token);
		t.transfer(msg.sender, claims[msg.sender]);
		delete claims[msg.sender];
	}
}