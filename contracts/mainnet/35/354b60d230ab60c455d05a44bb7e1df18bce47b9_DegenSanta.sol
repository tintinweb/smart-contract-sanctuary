// SPDX-License-Identifier: UNLICENSE
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract DegenSanta is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address public owner=0x5731D6C218b3F45A76A758B0FF05ca640896B68E;
    uint public normalPrice =25000000000000000;
    uint public totalMint=0;
    uint public maxMint=3333;
address[] public whitelistPS=[
0x486817bF40d1220D6cC4fEb5Dcb90116651629CF,
0x0a37bBc41356B97eeE9CA6EC51Cd142D29A90919,
0x8d2aA50B869b2510930e21ef8F29bBA2407F5C08,
0x814986Cb1Ea018f0B72934C2FdE4A42EE3887Cb8,
0xAc90fFD3434Db769AeB94e907879a5F3ABE93474,
0xA2E8B5226d5Fc9c0fF1d653F8132e4Dd88019465,
0x398Dd3E71D4D5c9e6D2aFD0668a99D4A7B74b90e,
0x8Ee316524EE3b51438240e8cA99c4af365Bda6B8,
0xF051B3107529c85c97FdE99D7feB14BCa8caED91,
0x57d0DD7dD9f8D79F6297D6aac15d07dA5f12b658,
0xdC2c666e4aB615eB7ba7ae39EC69EA6028BfD3ed,
0x93C80A4b1bb2bd418a4E55709f7F9a0459B8ddC8,
0x682C115E0784db5255b800b912cd1C062Bf93f4d,
0x192f1eD7cF9008a17070C43DC26AeA8bb70F2A22,
0xaEEeF36c5DE962FB256Ec828f8DF4D47aDfDfFa9,
0x203d75961405B10e19E5a1d5277FD67a8d1e2a6e,
0xc60904259F702Fbb39C7389C6A845fBe5b36A444,
0x240471181FF5F40E51Ba3F44994Cb0C844f7bDFB,
0x4cB259dAff37CF591630aD472d4D0Eb30f030c79,
0x0cFa01a8c2D7EA1b18f8c9929660dd79d7A283b5,
0x2e2F8Fd4122F26ee3E658659927524d31fbfa7B6,
0x381a6b61D5f352E17A9bE2DFa07C089fF260f55b,
0x263219b7Ef662f2493A3453C713F54b3f94A01ab,
0x7880548C5738DcdA62c42B672Fd823707858BCEC,
0xeA03f68291362bE983bC0aE2477ea1a9f472222D,
0x2df7C307F9B62d7Ec218A041249C9CA6c2947523,
0x503cE0d69e8e46c58535ca32dF1F89431E71D83B,
0x07AD76F4049210722f12c996e86169Da55f3B681,
0x6Ec5f787AC78d79d98E1b2C9184c6CBAC900A294,
0x06f97f429FF6c2c1284e7000470FbecdB0D52A05,
0x6d08Fd4335132E24555D198f1B855a76A8c9a7E2,
0xF80af3919e09f7ea98B2101193bd5890d88d2dC3,
0x30628ab7DB60B348FD872d1705abF802A1e2b945,
0xdf09092bAe5C265e404e0a8Ce01eBF341481F531,
0xD383c147E8226D91372601b2CD277052Ebe9cc03,
0xF9af21a0A8Bae1660EAd923d6713CEdD48434226,
0x3386Fa09690dd22482d546aa91a07d0b9CC526Fd,
0xD0b2732a4327A60038EF2bD160A67Ed44295294b,
0xD27eee122D0Af4Adae24c589b0916063fA0ED26a,
0x2229425578e3f50B3242C2adB4C141A23228AAcA,
0xb0Abd5E82D81AD7A69D0cfEAD5A8e0D133717fB5,
0x9C57bE9Ea33018a8c898d47ED416F1d40543e5F7,
0x66f158c507c0fe235Dcedae3A2A629D1b6dFBfF3,
0x301de8793757599D306bbC38b638292670cF9289,
0x1E6119Bacf188e44918868BB4aF31c00BeDEDe92,
0x5C3086CdEC08849CdC592Eb88F9b8d2F72E3e42f,
0xfa67f200E080aE2047222c150387c422ac096d3a,
0xC2f729c57A325c32caeb17d7129C6117738a8cB7,
0x9562D1A7360a06Bfa95419Ce8A8bdeec6d67253D,
0x51A0FFEaD1f362895d1aC2E3Bd896ffc3ee20221,
0xD91DC7c83bd01b91Cb25019DFc4E35BC6FaaB814,
0x742Ac9aD5ED0ADB3507dF053bd7b9D283aE5A0C5,
0x46B1630c1f631e9A1080F72E2Cd5A62D4f37c37a,
0xf8f9042A6359065A2d279B280580478fC2934aBe,
0xA9A019eAF3120a06c7C91cA1cE8B62f0C696c94e,
0xFD0927b3C0d2cBcF5Dd23E9dCF33E29Aa4F8fE0D,
0x4bfccF3168205A0b376C44F5FFA8836B6E42F19a,
0xe7fff44cb63BA9E4a9a4a7587bE8f7F1a3112401,
0xFC4e7b189aDb20F6F0599590B783D62CDD62847a,
0x307d81b1BE8B263F6c468B6Bc1Fa57eBf808CC5C,
0xEA7B08F0e6007a0817b2fDCd7D30a883Fd1624AD,
0xA7212045eEaa289dd976BeAcF07afACCB3cC5321,
0x8044034671a95a7d775ADe40E9e1D047827992a7,
0x08E5203F1209485C3BC1B0a7a344aAb6AFdF0983,
0xb534F6CF9bf22A722a9e6421A59B1cC9f4d27FFb,
0xED66f2ca147e4A8B15f3646D5e8DAf7C6B7405af,
0xa257cb0eF9E4Ab08Fb75181ee2E47919E5a2C98e,
0xB5A2370E6e741c6A12c40E6FF8FC6852D38e88cE,
0x81A39aa0b0D6FA8513aa79929E7C01DfaA232Fce,
0x29e613A8456dfe9F90c1fbD982c95598016241C4,
0xb87Ebf06f8C99F43ecad940e4F1ACe84EECE776b,
0x6c49750487f49384Ca8c262F0A260C1ce2f66B0F,
0x9970D175dEf87f68ff59609785027ECd3Cee3e62,
0x575500369B75d418Dde060A6AB876ada3A330E43,
0x2dF5A97C2AcE6e2dB08CEA422228B3E480eEbb86,
0x0700A358c55fAFD611160B5Fd79767a215718E84,
0x2Ac23EFc6e747CA1a1e01bad721Dd9Ba3676f66d,
0x41D402A509dE41BE3207A1e9C470010ab01B69A8,
0x6fc721d425791b4893B712c85ae30aB3F5F0f918,
0x901DF228d7FcE3B17A9745D353107534cBaDf668,
0x28E7591bB1525901Daf911c1967b3fdf49C4D422,
0x27cB1F9eB77c236803b0a6226ED32535bA727dAa,
0xA38A71c16104B9A274DDC09FBd4BEAb938897Ec0,
0x9ff18dc645D519B90021F704df134844195d76f6,
0xa038c03fFC4Aa4a55A961060CffED8665dC01BC3,
0x62d3E225Bb6B410aF13817c0C1f14dA1ff37402B,
0xE3A8783e0345Aa147Cb1e4fcFD4dAd36Fa39c393,
0xe211c9CF20364021980Fff5De4E21667548B65a1,
0x08E30E470a7568332064aA2a285aD5e272a7541d,
0x1796391eD1B00FC76D856C98Ec7F79e33424A48e,
0xEEEE451963d5A81C9D94776C9519ABb6b6342Ad5,
0xC64cc0eDB43bdF8555eCE2c199a089bE781E8a89,
0x4bAb3C9BE4C150DD73d16e040d3C766Fd4928e41,
0xb26a76fB5dA1a3cd337bC11be8b0222D2ab16e91,
0xf4a37C68E83eA9f7d3F3e1Ea65077223002609Af,
0xfb3156C2EeA76EbC44e9C292605527be3D7Aad87,
0x578018fbE5Dc1d2b45be69eE769C5A05Ce759Ff8,
0xc2e517e131a15e79875dc2b70f4FD1721924Fe13,
0xdd8842eCA6Cd5316FDB8F75A0e7ea756db01c9c7,
0x7456127380c7F1Eec02ABeFdf9987a289145293d,
0xF3AFb97f628913dB171C140c208E552cb968B1C2,
0xA403299f84fe4204fBCe07632b075E15A730F05A,
0x03C6547A6935Ec26dc9c9440bbE758afB2E06797,
0x37660b87525559598c053f0f5b4c93C44Ec35E13,
0x3a692FC43057222e8644cbbC850243929Cf9ef0d,
0xB271cf0e246541fbB2ACC847bAccc2ab8edbF5EB,
0xD01b08d2Bf4829d67412131ca9d3CffaEf33cC82,
0x8668F8B1542afaF8FF314E763e729CCe128Cc535,
0xD6b60B0Ca674e4289647a08AbEC30C71d932E465,
0x81CB73Ed7df07A00885249aD7dc85598eb1395d2,
0x7eD23aE1355ffC306cF5AFF8990Dc6b834272B21,
0x0199703A19b539fc914D9A0B5d6c04fE146E7956,
0xFA64cE83da357B607780fAA4873cAd31f09eeeec,
0x9b87f2EeA9707aeB4c42Ed9B84bB3D7C7E64DB4C,
0x8b2BE334F5516c947B617cc89F81Cc2bBB8DDce2,
0x5934F27BDEe5103bce9590631932e76Df87C52C1,
0xa0a7b66706b7f5c178AE49486a1C98B32670C038,
0xc8B8c11a61fAaf2e159F20dE4cab91c8fbeb759a,
0x8Bbc42dA742E9A5e0EE458A63Be0bcd23f0b5912,
0x62Ac503e46fCc13317580b8B177f28f2F5270f17,
0x386D63939cdd398454961C1fF03012000fCb6b7d,
0x9807261Ef6D63d03D427107A3124DD94E66d0182,
0xEA9F6d18CDC6c04a598893323Eb40FB0842E7ac5,
0x884d9a4C073096Ee84951bf079F8E17bC23AdD05,
0xdc702604A1bd2372333a445bd4CF571e2d050231,
0xB32d0fA770Cc6e5230F8BeaeeFb4aB47d6d78BAb,
0x1B4D468B039fe9D263e36F843fD063d2436af7EB,
0xBC2A97E602BEA2A342F2B827c0dd0bee9406f182,
0x17dD61F0657f00836a9406148432995F70EB3Ce9,
0x78E9F69edF35Bf133738B6d27D0D01ceB07B7414,
0xBAb6c8e26855814de30641f005c1635429A57fa1,
0xD9ACa0B3A35a9bD5c2575535465d9Ec9C9C8b278,
0x928Cc9b284242af32c0b46F2A720ffa43244E667,
0x5344B925e708aD57A5fCdc452938bC3C158f623b,
0x6440b180397E12B53A8e4E0c5418D4CD2907d7f4,
0x417668bcb53F9fc844Ad1632427471Ae03355D3B,
0x6E83eAc3a97014E94d068936294e6ffA769FCDC9,
0x8f1450C06e273BB11fC76227fB3Bd79943b29E95,
0xd184C6329f931CF04e5AACB0B7D61815de5Bb5A4,
0x3dc26b2faeb5F237475B98944668b7BB2f16E61c,
0xa5104d774fEa26004B146c4683FB620B969441EB,
0x6Ff214F6494692965FA36184D68C381A91c91aBB,
0xb1D7755DF863DAF441005AfCaB954c36045A84E0,
0x4187623E7b15A87588d57822410D336A114ca5Ec,
0x57De4F0cE1401377dFee575e4765FecCa6F6286A,
0xcCbe331C9f1D5b39AdD2E98DFc99fBF1cc7a3871,
0x8e28e10660f9998472e61A5e8447452E7c80a94a,
0x9d63552012D073BEBC4Cf8Ea0630A12061154BFC,
0x6536FeD97dC52568D87c6491ddCbE77643991A7f,
0xedF0E5c601835b63E3bc515aC982c5Fd1b16e5D7,
0x83FD7410158A17e97d9753a54240521f8AFC973d,
0x52Ada85c7ecE42Af0d3a5E1523A31aE9cCa2928d,
0x7f45689f3B93a6DB2f93DdFb86b37D8920449Dbf,
0xA71D920e7aDAA5B2774423471b5fb4fC2E8234c6,
0x734b8B57E4E6c60b0d4dcc7aF100E0b32aC9C914,
0xA0F7f8C53Bd76F99657F76a99256ec730535C7aF,
0xe0d4938f6325F0f4f944a581fc5bb68Faa07f47a,
0x54f03Ed17b4C48Fc29A59e1E9698abb5506A381b,
0x3fC6C4e152300f76b022C255b07BEcF37b5eB7Dc,
0xa736f32f96A9f1456661674983e150Bf22f543aA,
0xDbbc04eFFB0470A6C70FCB41b2F28044CD042643,
0xd8c95fdecBe38596B077c5E720F2a44529B7E3d7,
0x74472B723678dE7d41C00e2781e86Fb9bC2DE8E2,
0x11260D26BEd893387635b9341F69E5515454aEF2,
0xAAd74959532B32eecCF84D9c759C0db57A8B81d2,
0xbc811A7d71018F6056642C2801207b699B1A5469,
0x9D42b9Ae86d47Ee02900c5df8d090D27955FF8E3,
0x4FdbB5d791E3e1157e1e464D3862E21B0EFC0979,
0xe3B7861867143eF8c93cE56266483BDA3DAAe388,
0xB871cdCeA6C87216C90E1efB5131129F00488E25,
0xDADedd5be7F3fE09F80A6ffCe1B713e2Fbb58b0E,
0xe166E0A7c3F75D2A7746f63C122F9Fe427Ba65c5,
0xfcf7cF49aB34E43EFDeEaD51eEDc0f1D25E43cC5,
0xdB3aF355c3FD464dfE67D50CDf032CD859735d68,
0x04DC1e988FF93baFA22599122bF6678576c631D1,
0x3CeB33Aa7dD005f4b170115756dc8a079CBF20E2,
0x51fA840DeCE7bC6b46C00be3B2CbF9D90682D5Fb,
0xdF76EE72c075033d7d97A263C147a553b390ba73,
0x34964383584Fa9f2198fC909Cfec748d5E5f6D1C,
0x1CC944b061705A3d56207EB9dd1B17Dd8C8c1617,
0xe185b00ee969942eA17794524bb5fD22A418EBE2,
0xe3d270EeCE1356977147B5e3a41b0F3adbC1Fd21,
0xF285911E5362A896279adfB70B16078Eff5eA3D6,
0x59B12B7ECE14dDF563bF36e10F759b8045269204,
0xC5BAebc9e5b4ffc840b283a70F6227dfa854c818,
0x093781C02625FA9ff1EB61C09B898c87D6fAE35A,
0x6701a3b9FA6017f874D9255D57948ed49F12F802,
0xA9852147ee8Bbd4B5bb4cb0Bc65d6C1E960E606a,
0x3f078e652AB2F1872F1977FE9a2551C529281508,
0x0cfD8B5D82809740f2bEC4cfc17214558EE05c55,
0x3f078e652AB2F1872F1977FE9a2551C529281508,
0xfcD0A7A75920a4eA487D535f71026888c86F4292,
0x6B756219f10C50ba4CD085fcD882d79f53A90384,
0xA87653b466cB1aF7196de90be3Ca99Cb0F44D46A,
0x29a72290e435Af6C2ca04e609faDefb681cA2331,
0xAF5C0971a160d753C05A77256e29DE850cC8Fb23,
0x48708A047d1928fBB802e57B4b117f1c7590F738,
0xF6EbDdEd67F10E4477A9349Fde80c0868A7eda15,
0x712E4c77BF0c813e4C0c287D37F2be7C3a24a219,
0x08B5bfEB412443cfc54E38656Ae88f6bDDe4920f,
0xE120edDd8A1FEA7D73AaD75d8eD8406988B2C98D,
0x9Cea5304597DD796Ad56B2b21A2cb8FAA346afaE,
0xBCdb110BEd266C068B0FBf937e4701b07727a583,
0xDbCbC399f03CfaddF331Bd34E2671483531bC8d7,
0xe46bfC3ac7743E2D693D60ebAd719525634e23E4,
0x21F7e4bf4627E108FD3f0D63F87a18C144fb9D99,
0x1795011eA0D47f3Dbd757B77fDAa3F0366208237,
0x3a017854138C5f9b85b0457b832151B28213b6E6,
0x8BabeF9b30D5b2845F2A06051Ab43cB53A4107B0,
0xa72dd23f357b1E7b4E0D8470f551997B8ecBc85b,
0x58A95b83cBe75D5E5fe53134f141b92Ca31EAAbD,
0xB3A251c592ecDac80ad041A5449402d328F7bCA2,
0x0E88CBaEeAe8D34CF6b1f160E27EC01bcBC3c8cd,
0x399b672B0B7a88eB0cde1b4592b5E7aFADa2cc05,
0x18495C66001534504E56C1E242B74a8C1Ac73e9D,
0x83F80B5E2D5f8d00d5d935DdC6dCa022aC61eE7f,
0x1bcFFD08CA6A29aA6048971801e6a7A80b635341,
0xE1C1E13968099Ed438cd0771F8D1458CbdEF1038,
0xC581207D2e6AC5025aD03fd38e73D4Bef1EB682a,
0x2e8D1eAd7Ba51e04c2A8ec40a8A3eD49CC4E1ceF,
0x742Ac9aD5ED0ADB3507dF053bd7b9D283aE5A0C5,
0x734ebeCE6D698a50CF90aC9bF15e3F16dC34a204,
0xaAe049FaDBD4023aC47306Ffd241925258EC862e,
0x9bd4d4a231103e257EB9A618A00F6c3bBeE1Cf52,
0xeB81B99A7e2542D54C1C3D3ABe6e4dC3616cAff9,
0xCB68CC1d60Ef367FF0F18928BfC5D41ECe0C39bB,
0x0830A22FfE223389B057246ace6e874b3D7E259f
    ];
    uint public totalPrivateSale=0;
    uint public totalFreeSale=0;
    bool public salesOpen=false;
    string  public baseUrl="https://gateway.pinata.cloud/ipfs/QmToJQzZ8BpqZE4uVE8ZcRGemK3MUwbyjhHCGo7GpAtn3K/";


    constructor() ERC721("Degen Santa", "DS") {
    }
  

    receive() external payable {} 
    
     modifier onlyOwner{
        require(
            msg.sender==owner,"ADMIN_ONLY"
        );
        _;
    }
    function append(string memory a, string memory b, string memory c) internal pure returns (string memory) {

    return string(abi.encodePacked(a, b, c));

}
    function awardItem(address player, uint tokenCount) public payable{
    require(totalMint<=maxMint);
    require(!(((maxMint-totalMint)-tokenCount)<=0));

        bool _whitelistPS=false;
        uint16 userIndex=0;

    for (uint16 i=0;i<whitelistPS.length;i++){
            if(whitelistPS[i]==msg.sender){
                _whitelistPS=true;
                userIndex=i;
            }
        }

        require(((tokenCount*normalPrice<=msg.value)&&salesOpen)||(_whitelistPS));

        if(_whitelistPS){
           

            if(tokenCount==1){
            require(totalFreeSale<=333);
            totalFreeSale++;
            }
            else if(tokenCount>1){
            require(totalPrivateSale<=300);
            require(tokenCount<=5);
            require((((tokenCount-1)*normalPrice<=msg.value)&&(!((maxMint-tokenCount)<=0))));

            totalPrivateSale=tokenCount+totalPrivateSale;
            }

           delete whitelistPS[userIndex];
        }

        for (uint i=0; i<tokenCount; i++) {
        uint256 newItemId = _tokenIds.current();
        _tokenIds.increment();
        _mint(player, newItemId);
        _setTokenURI(newItemId, append(baseUrl,Strings.toString(newItemId+1),".json"));
        totalMint++;
        }


    }
    function claimBalance(uint withdrawAmount) external onlyOwner{
        payable(msg.sender).transfer(withdrawAmount);
    }
    function changeOwner(address adres) external onlyOwner{
        require(adres!=address(0x0));
        owner=adres;
    }
    function setSales(bool status) external onlyOwner{
        salesOpen=status;
    }
    function addList(address adres) external onlyOwner{
        whitelistPS.push(adres);
    }

    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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