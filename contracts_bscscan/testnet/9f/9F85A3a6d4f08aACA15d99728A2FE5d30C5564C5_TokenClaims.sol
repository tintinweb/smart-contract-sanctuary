/**
 *Submitted for verification at BscScan.com on 2021-08-13
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

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

contract TokenClaims is Auth {

	address public token;
	mapping (address => uint256) public claims;

	constructor(address t) Auth(msg.sender) {
		token = t;

	}

	function addClaimant(address claimant, uint256 tokens) public authorized {
		claims[claimant] = tokens;

		addClaimant(address(0xC8b8e35d5d1Fea0DF864bcEa7dC958C1C1163E4a), 501900000);
		addClaimant(address(0x70e98AD57B94A5e56942174A3c3e07469e4c4D02), 504100000);
		addClaimant(address(0xD95aDB1CCb95e7e147096B04BbD6BA65ccef01aA), 505600000);
		addClaimant(address(0x57cD88252fBf4C5EA39E65818cE890036f08A8A5), 508700000);
		addClaimant(address(0xd86BeF0B1391F470D2dff1f118a9f7fDA452Ae82), 511400000);
		addClaimant(address(0x40cD3087A3385a4A3e8004aE0883de9B8d8F9408), 514600000);
		addClaimant(address(0xc521DBf4536E4e93b9314536181e7aF6b61D41A4), 515700000);
		addClaimant(address(0xd0Cb7Ae43B2DaDfFa03aAA863297F5Fe251945f7), 518000000);
		addClaimant(address(0x3Fc2d11b459F75d6F0D50Fe52e1D3186C56fDC66), 518300000);
		addClaimant(address(0x3f1FF5727b56EE074278c0AB6f997D9d7C0cF503), 521700000);
		addClaimant(address(0x4724fee4b96D149a05B99C078505F11FeB263796), 522900000);
		addClaimant(address(0xbD79A1b3783DC24CF986c2b8c80dC87a96a033c6), 524600000);
		addClaimant(address(0x39009d3d8a1c68Dc584445Cb0392Fe0718cE5254), 525300000);
		addClaimant(address(0x48e74Aed0A3412e880F3f1fC1352450851E6d72e), 527300000);
		addClaimant(address(0x3f30cC0da6C18DdabeC96483C02FB4336B202073), 530700000);
		addClaimant(address(0x04f9Bc7Dce66DBE646838DA32C8f7596B23dCEB7), 534000000);
		addClaimant(address(0xe3954889a91e3aAfd6df3A86BfF4bD1721Db5eC5), 536400000);
		addClaimant(address(0xA35c08565f37DdE062E63953C15464caC203C6b5), 539300000);
		addClaimant(address(0x7019708c590314b866011AC15bD3B6462503e974), 539700000);
		addClaimant(address(0xe5B9B4DCDa2e1a85f290Fbfb8E90a86683BF5239), 539900000);
		addClaimant(address(0x6151ef07aE42efe4815c8A62fD247C97532c695E), 540000000);
		addClaimant(address(0x5F6d283863F2f73Ae0719270585b66B12b7AfD87), 543400000);
		addClaimant(address(0x9c12491Fb8742A5BE25164f416153765C6Ab56d9), 544300000);
		addClaimant(address(0x1196ac000D91e339DA78e4a6F6Df90Bf8BEdd835), 544400000);
		addClaimant(address(0xD4Dbd01F2b0cD849aCC645ba2e3b45e83268deC1), 547300000);
		addClaimant(address(0x96190e6853CE43aAb2813a25cc944d3F1cf6E692), 553600000);
		addClaimant(address(0x185718a770532A63Fc11A2fF444da8DC11b9179D), 554000000);
		addClaimant(address(0xa553503B639bb319521ec71261c13D53AEfF880E), 556500000);
		addClaimant(address(0x29ABD4B95dD3634D9f97b74840D4fDD75C8B5d83), 560000000);
		addClaimant(address(0xe6509C1983392f56C023bDeDFf6B83d0E5009256), 560700000);
		addClaimant(address(0x9829ED8A8db42D865D8e4584A6353d061574E4C7), 564400000);
		addClaimant(address(0xda811c0b2ec72cD66714a537CDb649edB420457E), 564700000);
		addClaimant(address(0xC93fb552B5586625Ac0f65e3b873AF5fCEEBeFa1), 566100000);
		addClaimant(address(0x05C51a9b20Be7A1FD0156A25253F21D3D1945Fd4), 567100000);
		addClaimant(address(0x9a71ACA419A15c465a41bb653b48619d1211cA5d), 571200000);
		addClaimant(address(0xC99D6644cC581b19428a52880698ef642E3BdD35), 573600000);
		addClaimant(address(0x67050086a678dfE5d0Be286554c79164ef3b3479), 574000000);
		addClaimant(address(0xcd27922B405d7f95d3467dE59fB7696e0A4E8F81), 576400000);
		addClaimant(address(0x8690dd47fCAe910DEDCf1401F733Da253C0D662F), 584400000);
		addClaimant(address(0x1eb95D89a56370C78EE918d14129Eae8ADC49217), 592500000);
		addClaimant(address(0x0CEaFB603733daaAF5E63B52Bfa650B6Bf6Bb2Ad), 594700000);
		addClaimant(address(0xf1d117214fA2A50097c7b9f90A003C61603fcA2c), 598200000);
		addClaimant(address(0x55c3308Bd1Dc10dC85a226452Ba749bE0651d468), 599200000);
		addClaimant(address(0x0Ea1b2dbb06A7F67C3C79947e5D4FB4D94A5dcae), 599700000);
		addClaimant(address(0x5fEA7e78485B4Ebfd92611083d12E3454A952421), 600300000);
		addClaimant(address(0x91255bbb4518Caf78094dAbc78A3B0A72Fd98Cd9), 601400000);
		addClaimant(address(0x4d5EEB6B00Eda3C022e7075B936a23fa75fD211e), 603300000);
		addClaimant(address(0xD5828346d70A33360ce84f6969bfb360F809E7FA), 608300000);
		addClaimant(address(0xb929976a0754D34bb842BD917b186F1d2fF15f68), 610800000);
		addClaimant(address(0xf8b2C08f5a65C5500cd8fAf966bdC8FcA7a44aC5), 613000000);
		addClaimant(address(0x4449bf2b0Ac0490572a7C10d4d121F77604b6c0A), 613200000);
		addClaimant(address(0x6520ADb4dF2eC52d78790Bface8c4358ccF96fcD), 614500000);
		addClaimant(address(0x741489e311b55e46212362b8675d2aE0DA1696bA), 617600000);
		addClaimant(address(0xcBfE82a02830BD19a92abeaff0dccF477fB372C0), 619200000);
		addClaimant(address(0x84Ab1bfefAD1354246C35BA91ABeCD38062ac2A8), 619900000);
		addClaimant(address(0xD5c3d525f8a928c3a241DD1EE32862A53683e828), 621800000);
		addClaimant(address(0xBCF242080dfEead95950D2F243416E41541F5FBC), 625700000);
		addClaimant(address(0x920D1BC90cD29f3e1f5F1Eb62d62F315983b7111), 627000000);
		addClaimant(address(0xDB652d5427019FDf3b1967b994d7595008Dc5b9E), 627800000);
		addClaimant(address(0x266559FF8500fDAe9675647c81531B1c0F2EFa1C), 631400000);
		addClaimant(address(0xe478F590C15d552CcC165E7ca160771FA46064EF), 638300000);
		addClaimant(address(0xF521896fc99640f6de4Ff748d53aC847EE374967), 639400000);
		addClaimant(address(0x15Af233dBb06FF04802f178019A4eF3d40e35317), 641900000);
		addClaimant(address(0x997EeA1434955c5DF1fD126561044c94Ef295E8a), 642200000);
		addClaimant(address(0x1f021F0FA4E7F20124FE7b771B2EFFac21810B2E), 646100000);
		addClaimant(address(0x0891329C40A22FAAeC349f52d816C4600168D5D9), 647200000);
		addClaimant(address(0xd90E29ab6353918974A32518fD25388628ddbD09), 649500000);
		addClaimant(address(0x0e5E6d0A5BE4826fB85C2310224D8dEEB2A23319), 655600000);
		addClaimant(address(0xcE5B66a64AAD0d10F8e983FC10b1357D1f60D802), 658500000);
		addClaimant(address(0x37c6Fa4BDC6de11E5349E90F156fa5a3255C5913), 659200000);
		addClaimant(address(0x6869696AEd483eaeE2272e7a8fCa231F947332cc), 662200000);
		addClaimant(address(0x46615AD1551743DDBf0E21Ab53E1C2590c76A322), 664500000);
		addClaimant(address(0x00babD14a4f0E0b43D67Ddb88eC4C9feC5A551DD), 667000000);
		addClaimant(address(0xc89280f9dd003eAd60404819615816A6e358fA53), 668300000);
		addClaimant(address(0x693fD691a1EC17Dd6B98b75d8D6897571E181324), 673400000);
		addClaimant(address(0x550c0868fbE82be49A583e13Bb593cCb90e50A03), 673700000);
		addClaimant(address(0x965a268d6519284F6EDa56a841cC107339F80bcC), 676800000);
		addClaimant(address(0xbaadD3e6afAd65A61dCc476e9c0BdBA2cb903Ff0), 679800000);
		addClaimant(address(0xA624ABeBa1644Ab8228B817C81D3A899aF6C10E7), 681600000);
		addClaimant(address(0xCc342CeFF8E98C3Dc7cc16C362F0b84f8300b5cE), 686000000);
		addClaimant(address(0x56bF18d4ad0c64365752fE3a6614FfFcC9f29320), 689700000);
		addClaimant(address(0xcfD44c7F3ef02311c355D1878a0d42177e0f2972), 695100000);
		addClaimant(address(0x3AA116a10f17c019d9e534A42458e701a100fd1E), 696600000);
		addClaimant(address(0xBCd08B917F6729221273F824Fac932C2c0bFEfd2), 696900000);
		addClaimant(address(0xBF6bD93C2a5a1756407Da9c9d54C06cEa41d254E), 699000000);
		addClaimant(address(0xC548427719289D4f1b8FBf990A1a9E329EB9adf4), 700000000);
		addClaimant(address(0x9e0605B4d276D4F258089D159d434504DEf37C24), 700800000);
		addClaimant(address(0x9FadBf13575A8991f843eEC6B828AEDAcEc8Be87), 701200000);
		addClaimant(address(0x73Db2B3A732f0DD87b9164964A04aA2B574bF606), 703700000);
		addClaimant(address(0x53A2B2C79B09e8f1B555DCAA3d668516cfb14B1f), 705700000);
		addClaimant(address(0x070B755Cb15843316564D4229CA101AEe127c693), 707500000);
		addClaimant(address(0x6723E9e370fB008B014e5D8d536490389c89D72a), 716900000);
		addClaimant(address(0x64E6A95eAfF1B93A879a9177c3c7121dacDd5fCe), 717200000);
		addClaimant(address(0x6d44709ce0A8D0751F0063F217A9Ed0b648d8E67), 719100000);
		addClaimant(address(0xf21312b2F75F0Ba2cdb3bd0312b8964E1cA711e5), 725000000);
		addClaimant(address(0xF83b31E83e55011F1b6A146eB327110930d49aF3), 725500000);
		addClaimant(address(0xf44693631795A59E0EA6B5fab257c6dd8d134e3F), 725800000);
		addClaimant(address(0x474AE560f41774234A3c170d679701D0a3eA4B20), 726200000);
		addClaimant(address(0xEF6919a3dD51C0062D881148dCF50a93EB875346), 728600000);
		addClaimant(address(0x4e72aCA1EDC19F9b220474B8071DedC714EEbBad), 731100000);
		addClaimant(address(0x0323b793A74882f7f56Ce78c26fe5505517316a0), 731800000);
		addClaimant(address(0x1A21935135a9f0D526A5cEc052E46cf7883Fd419), 739900000);
		addClaimant(address(0x11A36D390aCa00Bd1797cb497b586981DAD59D95), 740600000);
		addClaimant(address(0x2Ed14aD92D33f21A8b8b0ca6d1bF5C6B5E96f58a), 740900000);
		addClaimant(address(0xD6BAdBDBaeEe9477339C7A2a49356963F1d804fb), 749900000);
		addClaimant(address(0x5D42eCafB3171A6a77C9FeC80876107B98b03dC2), 750800000);
		addClaimant(address(0xFD3733753DdDDa77d1e35fEffe81981db6425a26), 751900000);
		addClaimant(address(0x8E00a11878461c0D7BD2AE33D51C24922732A51a), 758000000);
		addClaimant(address(0x8a55298d9D22741bC9ca8a65cc11B378A8a11BBB), 758200000);
		addClaimant(address(0x86d89B8225119bc1fd1280cFD9cb50207b8E9fB7), 761700000);
		addClaimant(address(0x44954b705600c996012d2609881D2F37Ba8998af), 763300000);
		addClaimant(address(0x5dDE415892293Ae645B95BEF65E8B3E1Fc46624C), 764900000);
		addClaimant(address(0xcFf3d078755FE2D3800746f8B3E4721E460041aF), 765000000);
		addClaimant(address(0x40c1242bf9709eA9A221dE498eAC9F668e427E33), 769800000);
		addClaimant(address(0xf1d7Cd89f37632D52466Af86C757Da7a6ffD69a2), 776000000);
		addClaimant(address(0xA11dC6f57d5Eafc6E17cb975B85008913dA0252E), 776000000);
		addClaimant(address(0xF69659A5D445B58839ab030e9C4cC58682b7477C), 777400000);
		addClaimant(address(0xAE4395917e91686e0070627dF529b30Fb39a5835), 778000000);
		addClaimant(address(0x13707565864A34ffE8cA82c8af7Fb177a63d759A), 780700000);
		addClaimant(address(0xf971815DC6Be304DbB4b45fFc85622ea2121D95D), 781800000);
		addClaimant(address(0x7502D445E5424f02A1a5256A5E35e27160Ed6831), 789100000);
		addClaimant(address(0x5Bc1fE6F26B62F0685A1014B2Eb95F15C9B5FcC1), 790900000);
		addClaimant(address(0x39BEf8E43c7C6BCf90d4E818cd7114Bc5fbFC51e), 792300000);
		addClaimant(address(0x0d5b4a4200F8C1a0663C1042A2ad23f9B0D2A9fb), 799900000);
		addClaimant(address(0x178D1559c6Af7A0fef3319FB1623f80507D9798A), 803300000);
		addClaimant(address(0xeF9fd64b3ca40F272D07f8eb69a249Ebb3Aaf81c), 805100000);
		addClaimant(address(0xfa18BbDb221730e1CA4aAc2915B2bE2b9DDBB5DB), 806500000);
		addClaimant(address(0x4Fbd9A798722704DBac80332Ce1E47a0A5Ec4540), 812400000);
		addClaimant(address(0xdEFE4CBF06Ba76ECd700846dDd39ACA0B9f9564e), 817500000);
		addClaimant(address(0xce1AbDc5b539a265d782aad62c91b3a099CEBa49), 820800000);
		addClaimant(address(0x8AaccdA1FCC9b38E6E6F84A6F6FD6aDfcaEFae70), 824300000);
		addClaimant(address(0x0F6e6909f223e2de9e26C946678417d44224fCE2), 827100000);
		addClaimant(address(0x28f5d56A90f5c235e2201d342141ef9079F749A5), 828200000);
		addClaimant(address(0xc065914AFf64161BAF72A0D67203bA6Ea7bA2bc1), 834600000);
		addClaimant(address(0x031f26d2c2DD09854DBdd2fBE34Ad52b567d1Ec2), 846600000);
		addClaimant(address(0x2D0512Cef88621E7908710f9D859896125ff6215), 847700000);
		addClaimant(address(0xeA62bcEC7637e94509BC4FFE7391aED54f0d169C), 848700000);
		addClaimant(address(0x307926a6A720849610f07c01D1e592b4acD809C3), 855600000);
		addClaimant(address(0x54d947e319CA9725c6b2295cc3136676b414C7A2), 855800000);
		addClaimant(address(0xfF8673B87Dc12FDFCC5108009BaC64754c1CEB8b), 857500000);
		addClaimant(address(0xd30feDd7B71e69e536CCe7b97563b6Ae1b8259Cc), 863400000);
		addClaimant(address(0x04C1a411C5a3BF3A66C0e0B7F07A140955c782A9), 870400000);
		addClaimant(address(0x97351A2930CeF94047512D2BB0D453d46792Fd56), 871600000);
		addClaimant(address(0x382CB79fC9521868a725852CC9bAE0b4417Fc120), 873000000);
		addClaimant(address(0xa59659294e9615790414450754E93fE2111825A1), 875500000);
		addClaimant(address(0xe54243199F63F3FD2826873Fcf72a0E492dbFF5E), 878900000);
		addClaimant(address(0xea4bb6Ea61B81D0D9a1C63D121B1f49193cC5C9D), 880300000);
		addClaimant(address(0x77c9844C60fBE854fD667c2F149842AA1c15Ff55), 881200000);
		addClaimant(address(0x351F74699C73eA5BE5fD4Cd2Da9cb4c8E5Bb8Cd7), 887100000);
		addClaimant(address(0x86880eA6Cc9b4A79E60d2618C31E507C745496ba), 889100000);
		addClaimant(address(0xF64B6FE7A2C498377ADb32DABf3C5Ab2c3294f13), 891600000);
		addClaimant(address(0x384A66d8EC31ABa898101c3B5Ab13e5F3f3C3590), 897300000);
		addClaimant(address(0x1197F4f8cc8C63A5429c61782e9ECf93a5552E08), 898200000);
		addClaimant(address(0xaC923d01055E920424c497C4B37C66B8f00995CF), 899200000);
		addClaimant(address(0x67788fabF9cda76bAa33B18d663489D50412CCae), 901000000);
		addClaimant(address(0x62fAa6A4e2a2A33144250EF6e5C375B76B69E7F8), 903100000);
		addClaimant(address(0xC079D04273221Dd8e2Db6368ef2197AA739d6f2d), 904700000);
		addClaimant(address(0x648d6D0CDd9104C78b507C851BbBB9AB5eDaf0CB), 905700000);
		addClaimant(address(0x630686bCFE5e770Fd67aC021c4f2821091402270), 906500000);
		addClaimant(address(0xd3C5C2f0736e63A602BF2c5328a6Fe2320145390), 907100000);
		addClaimant(address(0x7e956C0eF7767167719Fc87afE4a0BbD889499e5), 919600000);
		addClaimant(address(0x23004154949aaA009d756A3E06a93BacD4153053), 922300000);
		addClaimant(address(0x04F2191551f5904173c359C047D5CC1709E6193A), 926600000);
		addClaimant(address(0xBD0fB555b15c66F42ce1166EdfFC430943F3fec0), 929800000);
		addClaimant(address(0x2Db794491D60Fb6AC00BE292c43842e3edd2F3b0), 931100000);
		addClaimant(address(0x6549f3DA105dC0A8d95da6a32567C482a50d0414), 932100000);
		addClaimant(address(0xc62B0aE32E8dbECc075332fd33d4536da7458eF4), 935500000);
		addClaimant(address(0x7e75009bfa11A87D1b6714fE555bfd2dDEEE1F80), 938900000);
		addClaimant(address(0x2700909F52e573D4016c09E8A1D7AE9FE31b6ca6), 941400000);
		addClaimant(address(0x50b440AFB82aeF66cA4f79A8aa8Fdf1035CB2B90), 952200000);
		addClaimant(address(0xE6E04F5F72839792Bd13F029D67D0aE515d5c46d), 955200000);
		addClaimant(address(0xFb7337Bf7E3De7856a154DAA7DB52fbBa88710e0), 957100000);
		addClaimant(address(0x072A8c3c680a5cccB6D1BCEe26ce19f1e4C506b6), 959100000);
		addClaimant(address(0x14e6089DAA314B89C25b5eD781641838B8dE3598), 962700000);
		addClaimant(address(0x0527c9047122D47A75B4249290E7BbcaA65b24Cd), 963100000);
		addClaimant(address(0xbb8CF7152c371533E7E18ab6cc93553f8b1f3844), 965800000);
		addClaimant(address(0xbf5744FcA5bE1B64E2f3FbA295FF191a7CD9ab89), 969900000);
		addClaimant(address(0xBEAb3364322273971f0D31015624A719AeD8E74E), 969900000);
		addClaimant(address(0x2CC37D5aCEbE8989dfA75A123375cF796c9519C3), 970000000);
		addClaimant(address(0xe77d16Aa72e5209c41BeC381ad27590E3803222E), 970000000);
		addClaimant(address(0x05f00A9A222C9E74dE123143115062684fa6003F), 970000000);
		addClaimant(address(0xf0c57caA71fCBB150abfb83893A82f448083C8d4), 970000000);
		addClaimant(address(0xfbaA14c00CF4720DA8dB3ea68FC81569bfc84d93), 970000000);
		addClaimant(address(0xD70cEb92697AA750BFB1EcC739328120C61415c3), 970000000);
		addClaimant(address(0x0D67E40c409f3eDc436040BC60de1fF83145C19d), 970000000);
		addClaimant(address(0x3BC4259B44D15F60DD0EE6aC24E6a2Dc7Fd4f20D), 970000000);
		addClaimant(address(0xa2C8a1AaEb4f687284df2e911A66ABf6D4084f8e), 970000000);
		addClaimant(address(0x395b72B6C1E9B21D1d052179DDda999b1fB4d68e), 970000000);
		addClaimant(address(0x83A864e12bf59d7A2faA2BE12D50Dff0D9d534eD), 970000000);
		addClaimant(address(0x48527Af45E6382631c2822eB9bB4375E28a6529B), 970000000);
		addClaimant(address(0x96ee1C83bd0E5D1d3B7d616921bD3c919bab2650), 970000000);
		addClaimant(address(0x9969CDe4156547A755eD5e11D8F2447ebee1d3B3), 970000000);
		addClaimant(address(0x629dadC0E6ecF9E9CBC56c30248d6611239dcaB0), 970000000);
		addClaimant(address(0x044da0B9261D5b72D1e03b7656Ee107d0F8044d1), 970000000);
		addClaimant(address(0x863446867806863E4c848DB81d7FA4f510E0Db91), 970000000);
		addClaimant(address(0xA09896d87E206C7CEc217Ad0124f85EEBE85EDb5), 970000000);
		addClaimant(address(0xAB578685a4cEAA8AA4AB9E2539F98D1887771B1d), 970000000);
		addClaimant(address(0xF280F47A9b37136980865333973285583E8726FA), 970000000);
		addClaimant(address(0x26433F8AD34E9026b2585b35E40506Dc796cBb2F), 970000000);
		addClaimant(address(0x065db0a316efAA3C3EdD7Ee6Db7ba2e19282f7E4), 970000000);
		addClaimant(address(0x8eF4de747fef742Fb0891B6601BaC9514D1Cb297), 970000000);
		addClaimant(address(0xC0f43da590FD7177428086941861f66c7c39f54E), 970000000);
		addClaimant(address(0x0025eC0784CcB820Fb65A5E4A8cf0A69F74488e9), 970000000);
		addClaimant(address(0xa60e9139556cfAe223773103354B240b947CeF47), 970000000);
		addClaimant(address(0x629c03aea60A88a218F1B56DaC52AF0BF6A8Fd81), 970000000);
		addClaimant(address(0xd0e2dFf3edfac4438f83DaCf59BfB2758B566311), 970000000);
		addClaimant(address(0x5c8a41078064b48D562C02f375709BAF026D0eAb), 970100000);
		addClaimant(address(0xb57A8411d7D3b7B7d516caC23A517C0617F16163), 974900000);
		addClaimant(address(0xdCB16079a5377ae26C8a52fC4a822Fdc05736646), 983100000);
		addClaimant(address(0x33EA6313b7235a14e2C7734a00e59e301B17f31b), 983300000);
		addClaimant(address(0xF52F20128379bbA314aE8c18AF81A82A44058893), 984200000);
		addClaimant(address(0xD2b4dc595A29172aB69684D025ebC2DA8A4e6dAB), 985700000);
		addClaimant(address(0x587CBdE67dE3DE091361BF5beA1A87F0883A96C2), 988100000);
		addClaimant(address(0xC6788FD83Cc2338AD2FBfdA600E1843a64e52040), 989900000);
		addClaimant(address(0xe6358447f819A8817AB90CdA65bf1269B6b3Ebd5), 990200000);
		addClaimant(address(0x8e91a93521105a3a75B0e2edaa6315Df3a979335), 995300000);
		addClaimant(address(0x2A5266De7e34a9310c9bAa4847a7F1D9CC316Db2), 995600000);
		addClaimant(address(0xee0232E292EE48203656e18c8B1d9E7fe5eDe212), 996200000);
		addClaimant(address(0x9D43A1B6203759cb29Ba8c0BC7034bc1717ff481), 999800000);
		addClaimant(address(0x1f1CFa62aC1964D8197610Dd5241b25e7904568C), 1000000000);
		addClaimant(address(0x18eaf48858256eDF264ead018CA0F509e2caDF23), 1000100000);
		addClaimant(address(0x25aCfcaBF5F159ED6c61Ac96b36EbB7285E4d813), 1001700000);
		addClaimant(address(0x3D46fC6226A17A09F1B9B3477A6B4C04355038D1), 1002700000);
		addClaimant(address(0xA690B5a5332ff521D4A8f662D8E8e8c9DeEc9639), 1004600000);
		addClaimant(address(0xCb21bD7B32B60EF9a1dc384782EDE25F2dF8a5Fb), 1005800000);
		addClaimant(address(0xEd6b8ecF1401F270F45BDCb018D62CE41266f71b), 1011100000);
		addClaimant(address(0x4C7b8CF0850fa0A3280bDA93cA1D01B26e3f256a), 1016500000);
		addClaimant(address(0x1b1aA3a131B62e8C0480Cfbc094F56571ccACA8f), 1027400000);
		addClaimant(address(0xFDf2E7409b7228d23E5cEEf452c7920F12E064EC), 1027900000);
		addClaimant(address(0x77612D58b20c280C003D7e2Cda409bb2D5D83aD5), 1034700000);
		addClaimant(address(0x14Db758d56134Da1af52d54a956c0Bb8070aC179), 1035900000);
		addClaimant(address(0x18be9d4E96238B2dF69E4e0Fa73B9c20b4159Bb0), 1043200000);
		addClaimant(address(0x2630084adFdDFc086d195738575514DA97e08BBe), 1053500000);
		addClaimant(address(0x0719C4ECa564c0a8e9D79a3102D08ba5980cF491), 1055000000);
		addClaimant(address(0x1faE13eF4037E2311d08894645490eB528d42171), 1057000000);
		addClaimant(address(0xd5FC1e5585913c8f46d8E8cB97999e054B6Cb729), 1063800000);
		addClaimant(address(0x61Cfe20E98144DbDCd0A76b24A14f3118D21b5AE), 1067000000);
		addClaimant(address(0xB9aB768c68255796790C3C70cce47F8F6dCacA70), 1072200000);
		addClaimant(address(0x6012dB07d3Bf22bfE870e50FCc60912592642Ce5), 1072700000);
		addClaimant(address(0x81118e26682F3AbBa441f5e8f9F05e1Bd6d48Bd6), 1077600000);
		addClaimant(address(0x2c4246e4daaaA9dB3B5c01657e7a100c01264521), 1081800000);
		addClaimant(address(0x85F3Ad138A205f325e5725A850f410F9329d0990), 1084700000);
		addClaimant(address(0x0C1a959231C8d5632BB86DDBC346c41B4784A7E9), 1085100000);
		addClaimant(address(0xE082ecc9Fd83988d7Ef3a38321FEd958f0E04c2D), 1086000000);
		addClaimant(address(0x155cd1E6fb41630B0677E95BE88B1424e87Cf7C7), 1097300000);
		addClaimant(address(0x9490BD565BffF5763Db63d2AAb0C2043180395F1), 1099800000);
		addClaimant(address(0xA05120e927256E6dF89021243DB638a2e413a93f), 1100400000);
		addClaimant(address(0x8F15eB374e25132Fd6B4C58fb351CEf226788bfC), 1102400000);
		addClaimant(address(0x1591A4C625A3647cD7229F8421545d912Ee75eC5), 1102600000);
		addClaimant(address(0x0B577ed938A086C35e5d3BEb0B41309E7D075464), 1105600000);
		addClaimant(address(0x28423393a7Af020723AfBB85d56213C19ef0946b), 1106900000);
		addClaimant(address(0x37f3Faaa4584DD2686C1110cD8574A2b4455DEfD), 1112400000);
		addClaimant(address(0x3c4fbFbdeeBD52e2BEa323EBD5F7136DA797e813), 1113700000);
		addClaimant(address(0xF2b75A2170603597766De8297675F843a402c8C8), 1118600000);
		addClaimant(address(0xAF0Ced13b0EB49b5B16cC5B9E40256275B100337), 1120400000);
		addClaimant(address(0xC210fbb546CB409F106f1EEcc6292396C9E6C217), 1124600000);
		addClaimant(address(0x5732c7939d1b18dFd540f35dBC885b6cB38C0c45), 1131100000);
		addClaimant(address(0xC2F1935eDF9B61882d7d2bfa20eeA309451745CA), 1134000000);
		addClaimant(address(0xEdD51Cf28b3FfDa13cb5533A332Fe05521C80c28), 1136900000);
		addClaimant(address(0x912C39d52340c2877FB376019508B965a50faC57), 1138300000);
		addClaimant(address(0xf889D59a6Db2179370f0DB71DfD0b2817762dCb5), 1139000000);
		addClaimant(address(0x99586441FD08E48eF889072ad61b741D8Cf0a3F3), 1139100000);
		addClaimant(address(0xAC9725754A99937Ad5669A05625137Fd882667b9), 1139200000);
		addClaimant(address(0x17983e1766F6B5646190EcF6554ABD8fd00cfC5A), 1141000000);
		addClaimant(address(0xf6f71485AEa72e422A8054e1d262f7Ad8A114676), 1143600000);
		addClaimant(address(0x71f4F9B51a841A5Ba6Cc19225d68a87E178fa652), 1146900000);
		addClaimant(address(0x75A382f4e42B690A4b6226a39f820a118c579d04), 1147100000);
		addClaimant(address(0xBee005d9116f053dA6863B579aad764Ed94d6886), 1153800000);
		addClaimant(address(0x6E7302553bfb512d9E5117BaBEFEADAAf5C209a0), 1164000000);
		addClaimant(address(0xAa74465980763ce0bCceed768B383b5CD1b11D62), 1169800000);
		addClaimant(address(0xE438529cA793e99d9C2d9817F225f51dad15a7ea), 1171300000);
	}

	function removeClaimant(address claimant) public authorized {
		delete claims[claimant];
	}

	function addClaimantBulk(uint256[] calldata tokens, address[] calldata claimants) public authorized {
		require(tokens.length == claimants.length);
		for (uint256 i = 0; i < tokens.length; i++) {
			addClaimant(claimants[i], tokens[i]);
		}
	}

	function addClaimantBulkSameTokens(uint256 tokens, address[] calldata claimants) public authorized {
		for (uint256 i = 0; i < claimants.length; i++) {
			addClaimant(claimants[i], tokens);
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