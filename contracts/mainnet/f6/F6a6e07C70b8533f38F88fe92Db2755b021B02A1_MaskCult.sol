// SPDX-License-Identifier: GPL-3.0

// Amended by HashLips
/**
    !Disclaimer!
    These contracts have been used to create tutorials,
    and was created for the purpose to teach people
    how to create smart contracts on the blockchain.
    please review this code on your own before using any of
    the following code for production.
    HashLips will not be liable in any way if for the use 
    of the code. That being said, the code has been tested 
    to the best of the developers' knowledge to work as intended.
*/

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MaskCult is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  string public notRevealedUri;
  uint256 public cost = 0.06 ether;
  uint256 public maxSupply = 3333;
  uint256 public maxMintAmount = 40;
  uint256 public nftPerAddressLimit = 3;
  bool public paused = true;
  bool public revealed = false;
  bool public onlyWhitelisted = true;
  address[] public whitelistedAddresses;
  mapping(address => uint256) public addressMintedBalance;


  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    require(!paused, "the contract is paused");
    uint256 supply = totalSupply();
    require(_mintAmount > 0, "need to mint at least 1 NFT");
    require(_mintAmount <= maxMintAmount, "max mint amount per session exceeded");
    require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

    if (msg.sender != owner()) {
        if(onlyWhitelisted == true) {
            require(isWhitelisted(msg.sender), "user is not whitelisted");
            uint256 ownerMintedCount = addressMintedBalance[msg.sender];
            require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, "max NFT per address exceeded");
        }
        require(msg.value >= cost * _mintAmount, "insufficient funds");
    }
    
    for (uint256 i = 1; i <= _mintAmount; i++) {
        addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, supply + i);
    }
  }
  
  function isWhitelisted(address _user) public view returns (bool) {
    for (uint i = 0; i < whitelistedAddresses.length; i++) {
      if (whitelistedAddresses[i] == _user) {
          return true;
      }
    }
    return false;
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function reveal() public onlyOwner {
      revealed = true;
  }
  
  function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
    nftPerAddressLimit = _limit;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
  function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state;
  }
  
  function whitelistUsers(address[] calldata _users) public onlyOwner {
    delete whitelistedAddresses;
    whitelistedAddresses = _users;
  }
 
  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
}

/**
 ["0x015B6a65CD902E75f2D7EC95273bdA3dfF888888",
 "0x01863B065D8D8eD5397B266DF2d121384e0b7d40",
 "0x04a05AD1c31E0621E3Df5D48935b4812b1D4df91",
 "0x04b75527dF1da2577a2682333dA6432882b7d7F1",
 "0x04cCafDB49Fa5961eC55c234a005E7663CC2eaaf",
 "0x057fD91F54A95246d168Fa78143270fCbD3B74B4",
 "0x071f4B3E27A4390aeD9194fEDA97307FE5b76751",
 "0x08115b886290941A6271444a66dBB9C3F5742a53",
 "0x0A5f07E05b56F45A1733b91aA60276d4c3E5EF00",
 "0x0a78dC771e50fE84f5832d259BFCa98bb492dbeF",
 "0x0aD759b06E6613AB7A13Ad39424bC196806F2498",
 "0x0B25c83e258854d552c2F0AC29CE75bE329F1D10",
 "0x0C269a6BE0bea7D16438DAB7553bd1449Ac7F532",
 "0x0F0cBd3DcCd9E64D59fc30449C773bA91E103918",
 "0x0f40612fCA2277b92b80Ac719e2D08337639B10a",
 "0x0F69f23463eF69fcecA3bd1052861Cd4bf62D5C1",
 "0x0fcb749e8dfb584a22134269e7191728ec5857ed",
 "0x10a348dDb0ae269eA73d9E01451eecd0a6164A28",
 "0x11b31523e0b6FbD8416E64DafF9BF26b900868c8",
 "0x120b0c9E44D2316be98f4A3ec1191610f6C6df6b",
 "0x12ADc0CFB830f71D52ee600d952976054557E5C2",
 "0x138198b16873b45713aB2C5D9545E3A20f065a41",
 "0x14Eee6fA252c5107Cd75461A0Bc4c827f4aB2Ff9",
 "0x15b27Df1aD6EB3BD8eF37F2A38F76bdA3044f1dd",
 "0x177821CbE97b3eB0a20de1FD534bC7160cBCd76e",
 "0x17E032e3Bd2EEaCD3EeCCC70B0a05C8BDc89693B",
 "0x17eF81738E4104658A7C84C1bd5E7FA6a2eFC975",
 "0x18c628Ad551e24Fe554Fae73B4FE6Bd1A164b03c",
 "0x192f1eD7cF9008a17070C43DC26AeA8bb70F2A22",
 "0x19CB1b1Cd398a9E70e019e9241b0a41664ee1eeF",
 "0x1a47Ef7e41E3ac6e7f9612F697E69F8D0D9F0249",
 "0x1a93d30a8b23744ccfbcA6103dbbe5E197F1C0de",
 "0x1BA1fF69F03d38Af7ef40E3afDc53ad073eb4642",
 "0x1c953dE703AB94b27aC536033626C73a37A08388",
 "0x1cEe5762323FB2730AFcDd88df5df24cFF333120",
 "0x1d156eAe76e088Eb85F95Ef4815769f672EB9330",
 "0x1D32034bc843aaCB09207f42CF4fec814c51855b",
 "0x1e92ad51a68856a44d58b471c02766619624cbb9",
 "0x1F1D0f618EF9dbFfE0BEf054362c5630Db3223D1",
 "0x1f912Cf70d9633Cb488836AfF039E09B87DE6CC6",
 "0x23c3724dadB200873cccC03115F74C6a29FaEe44",
 "0x24A4C3F71c75C53A35D74A4AFD42Ff4d6D450A3F",
 "0x24E6ae6EFc0C2D119073DAD52f6788830b7D1276",
 "0x24ef828971b6706287eb510cb9455b0ea6bb804b",
 "0x284CA6FE0F2e512D21DAD3F56DdE4C54BB6A73A7",
 "0x29008F90FEFbe3ce980c2D6553E2A5C3a9Ef3c5C",
 "0x2B927c125002371919ccCda76e45e8159aDbF6F4",
 "0x2c84d5e862B25D555324E2D546E1D86bdCE43e48",
 "0x2D8C24588c518ed8cb9e8D6F91ee77E6D091c031",
 "0x2f8C30C2844E086A47771bf047DD85A9d3cCC8F1",
 "0x2FB9A78667603B6917BC97193521697339EFBC92",
 "0x30874525489F70D5173D14F9652e0bcd2C23a52d",
 "0x314A6E1C5b07253a4d5CB85CCD2a9F868452c456",
 "0x3175580c8F8B634eA0c29f960CB0fD141560c26E",
 "0x31f1830C5893dD4408DAcA4709a961e5271F81fB",
 "0x322b4D1Dea0213047Ff23Dd7687b6E0FCC78e546",
 "0x326BE4F947cEEC771f364c91d86CDeC1f84411E3",
 "0x336Ab09A2C4A4FeF9956D8c10b5E34A265d76bBf",
 "0x33700418cE8b612f9c9b105FCa12260fEBc953F6",
 "0x34cce9354D488A2924Dc4532eb67CBAf962C4e66",
 "0x3568628d502eDAe3f3C1278F64bCFdc8715CAedE",
 "0x36331d0B3890f2a4E56223961058a1f8F1b01A9c",
 "0x378423d8c88D7705a1Db7FfCA528Df7c84beAF77",
 "0x3881e395D694ae71BCBe58f78164dd10d8bea139",
 "0x3b203d89abB3CE210216f85a3458683eefB2ACaf",
 "0x3B9d229a7Aa1E96D4fB1dA20aea1437503400a59",
 "0x3C179A8b4DfFa3b01d164969a8A1c0146cCfCac8",
 "0x3c3F94C8654D8aBbfa7A26981a0887D2383E7e73",
 "0x3cda751f42df22017f8e083047d3aa7f0cd7b295",
 "0x3F33947cbdd8C8C2f8DeE1B97CE1942592b9D71C",
 "0x3F4288AfA98b138a3fEDaB55F5506A9655d77410",
 "0x411D4c17d617564A657127741b784F490E283B4c",
 "0x4149fdaFb51eA2D8d59176b8848af8362f76713b",
 "0x41b3785d99f75e9DD97011FbdA7887c297dFb014",
 "0x41e4c6dB0baf2081A70Cc6e943a54EB683c0A9Ae",
 "0x45b96265cCF79c7a06d2F37bCBCe3c7E3FbC7d8a",
 "0x46073C5689ff372f8Fc2659F9A136b7DB14340e1",
 "0x4636E4f9B8730403a163eC08C880D9b5165C1C40",
 "0x4714990CF30d56c537EFb7cEb9d86CA8df6655a0",
 "0x4740D743d33191ba44Cd7c7215D8D82090c378A1",
 "0x48e95023bdd32822f4ab5289a9c55c824c782380",
 "0x4B341022C1151E34C1dB9474B53A926796b43258",
 "0x4Bdf780B96E306911c3081431d6b1869E8a22a74",
 "0x4c9BeCD7B52361a405b1aCA7909F6B4A2032a521",
 "0x4D0CAcd39D92f7E50a75e68db253b4247739dF46",
 "0x4d246e41D7131fF60cD533C13bD2aaFcE7aB1265",
 "0x4D9a831a88AbA289d274d72683B1020359dC5816",
 "0x4d9F70084bb1A5C0c9995D33D45Cf913f523E2E7",
 "0x4DaEb00e4e213A1acb51677e3414194F4a105FD3",
 "0x4F728127f6dFbceEFf64F8Da2932CCe670C4eCB9",
 "0x4fc43713688fFa85D18c9AA9477b710af4C13Dc5",
 "0x50C246140B2EF0E4Df781fc8911790DE4af2A96d",
 "0x50C2B9c3acDa872Dd71d88aA2C198aed0b788e5B",
 "0x512eF08d0bB53DE146E82F823803D1bb4d68d35A",
 "0x52027AE93EdD9B636Cb2Fc1Fbb7Ac7D3b759859d",
 "0x5238B9c4a8ed059F4eae497f463115Dd9A265064",
 "0x53050766b26B90375cF06fE624a19C4Db98832c1",
 "0x54b2b0E4A40f0B823Dd1e8a45f7374e13420C54f",
 "0x557D1721F2086FB281E61bE03AB62790c60065D3",
 "0x578fE53710B176dFd5a775610E598c7BCBb1DAEA",
 "0x593911A45C4AB007E711e4006F0C60dBa2138Ff2",
 "0x5979C7Fa759E121B9E604F1754b573A84dD30053",
 "0x5a45Fa1D4FfC1428Dc50F9df6fD1643F1012a39d",
 "0x5b1285B437E3D1C220A9e88c9DA3DDbA5E3ada49",
 "0x5b2c7bA963EC2461864dB8C293c723F7B1C488d3",
 "0x5BE1766DE32550378f48B0424c6F9E794108514B",
 "0x611A6Ed28cb59DEE17DF7B579Bf3796B10e326a6",
 "0x62315ce269d6d99587D0e86405F1ac5370D31d8B",
 "0x629530aAd476Ef5D9E85433Fd31D1da401a6874f",
 "0x62c347992DF4e87DA17520AEAdBCfd621d3664cF",
 "0x661e495f03cC395b8cA8923BA75b7D1e79033172",
 "0x66C483dd0518146385fA2c15B192C01d762a4BB1",
 "0x66Ce1a2B200Eb56A19f6CEaF7a8dFBbf02513188",
 "0x6775f2032aE8363cDbCf028f7Dc23e41B8f30f39",
 "0x682C115E0784db5255b800b912cd1C062Bf93f4d",
 "0x688Fa4A843dAfAD477C778183A645ADD0d200B7D",
 "0x69CA170a5d47935e1f92844D46Ac8E4895268fFd",
 "0x69CaF6aeDE842D4aE8679DA8240211eD91720185",
 "0x6aaEeA9fD70aE639fE0D4f7f637af80BEe775AA2",
 "0x6b92FF93Be126bE0B4671C2B32835611F881c091",
 "0x6c3F4b16121D75b5b51f4DC6813F3E962e8437BF",
 "0x6c8EAe03df06f742b5791445d48980Ac3D7169fE",
 "0x6E3a105f95d5d216ed88e0AE35B7ae43E6bd9E46",
 "0x6eABfA4A1177aaC6b021c7F1df1bc9864C75e754",
 "0x6f6E0eE1D8f40854B1B9e4FCaFC5E9b513A02636",
 "0x6Ff214F6494692965FA36184D68C381A91c91aBB",
 "0x7005c3F79dC4ffcB50BBC5A9Ec5fA599f795b527",
 "0x71eB7cd3ae4de03637571BDE945dEaf734E69B0D",
 "0x73206a2Ee45652C6607C181FFE2DdA9004326FFb",
 "0x734c55ded3cac07fcdd912440bc611bf3885ad8e",
 "0x73680F5713d40c6E902611Bab77F3008bAaBB4bd",
 "0x74050002133d58151977863A01a658B4B8888888",
 "0x74a28F0aFA2C4bc78901eD003B39C9962D6f0af7",
 "0x74Ca79D12cE85B145eF00e97F292A5435936d969",
 "0x75AF35BF6FC11dE14503217D6f7d4D7C4f2cb1E9",
 "0x75E31D9da769732658B7514a4AE57EcB29DE86d6",
 "0x77f8Ea28538d4fB6e2f9626D55ce4766343868Fe",
 "0x78516c09425B4f055919472C6DA4464e319e8b72",
 "0x785C7Ed8c45D21E44a08027823bA91D5579056fb",
 "0x787CE2654e4C2CFDeEe56d38a996798eC6eb580C",
 "0x7BCCF91d084df6BbA20467d8Eb143CAa47e96aDe",
 "0x7c8717eB6dE22F83ad1bBEb0eA45C7728880Fc58",
 "0x7D98e278b28d3510F657b7d6deffD700f3616b0D",
 "0x7Fb4D8041D9e6aD7C06534fC4F811f86Af4F8838",
 "0x80FaeB5d5C88AcA689C9A3e80306caDC50b4e311",
 "0x8204406b5B513B6B724976Ab2e872d7536b451ef",
 "0x83Af3255f1cA2c5f731D336eE1f4B5aB6ca2c602",
 "0x847071ba1bdFd687E98E9294a87FA133db21194d",
 "0x891c6A39eF1B66f7380C043e0BC5Df78396fE94b",
 "0x8a8fcDf0675946b0f22e35Da6ecC271465BAb8Bb",
 "0x8B84D36FABad1C32fC6C854854eBcc22DfC946fB",
 "0x8B9963963b953805451052F81027F730dF1937CF",
 "0x8bcAE31AC39691c461CE4BE6F7a4489fA8936DCf",
 "0x8c06e96007966A501351012E7969d1183B5bF851",
 "0x8e62fC2366B38c6E94C16329Fd7E1c2a4145dAc7",
 "0x8ECE93a13FBC0b375ab1fde2aE47616AFA052908",
 "0x920D785edB7448D074323c8C827885767c0fB129",
 "0x927B8e46344999FC3D7537AD642Bb2ac3a0dbE1f",
 "0x95Fb1896cB785F9806d4aD592a4b9D587D48A5b9",
 "0x96B03480e899e01086596E1FFC4eA57936a6CA4f",
 "0x9835119c65F42561852E5182f41005BFffCD41A8",
 "0x9aA226e6448698FBF131c42c48F2a3810183Bc2D",
 "0x9B5D3AA2e02FB77FA64aeA4fAcDDB98CC679bB2A",
 "0x9D75b8717aa34258DeA1afD74306Cb41e30F7B3F",
 "0x9d977f3985EE2b5ee85C19Bd95a1D200B4130790",
 "0x9eFCB9dcD66E9056dda436C2B988aABb16e7F62a",
 "0x9f16c4f6Adb51f55f57d644D61b2489E1CB70596",
 "0xa012Ed9c6aD49bB447B0AFDCfd1564eF853778A0",
 "0xA0346b55e532a3CA6cBccFa0b3489EAB6fbAfa40",
 "0xA38f82506C3AB79816D625AD286574133Fc6F4e9",
 "0xa3dea91d6F6F2E9b20506556a88b872872111A89",
 "0xA516C5f96a5a7f97DC0D26Ae20a3e8EA50A8FB14",
 "0xA764ADad3eB1b356AF22DFAcbf58d686d277A661",
 "0xA7F95D9988dFE3597940Db9c20eD084Ae4C6DC55",
 "0xA8A72134a22dC7c5c66c8d1D7d27BC452403Ca87",
 "0xa8F14Fdc0b3595CFc6BF71931B2Adc7bd0ed0d53",
 "0xaa413939FA2da0Ac9C6D5547473286532e4272fF",
 "0xaB8DC4F26A3AfE565fCD2f693B3cb782D6267fe3",
 "0xAc395a12Cd0b1Bf56e4c832bffB60E723953Cd5B",
 "0xAc97C502b1725c9780D99A7B6291bEd2133cBdC1",
 "0xAd50B95c9305488dC4444Deb39C6a102Df59D7AE",
 "0xb540da6a6115d162fb378a894665e69a78790c46",
 "0xB5Cda5b8CfA2265bE002f8Ce828b6DFdfbbBBb87",
 "0xB8e2875D287CeE2d8628a0eFece54fF152471A94",
 "0xbb504b85bc8c408f3b7de7716afc6b33042535d7",
 "0xBEcB4ecC92883f463ea4a2464276b165757985f4",
 "0xc06345370F0BEC65E5f3329517C5C35040Be20E0",
 "0xc2112148356BEcB3968FfDbf8CD1A9886dF0D2ad",
 "0xC2b58e59D5104D848cf26Cf40F9438ab81Ac2fB6",
 "0xc54Ec1494c7145E5324ad29625820935a24DEC74",
 "0xC7e3C24cc04286b948924aa52444651365A63531",
 "0xc844Bd4B98bE87685C66FE7B613e87c1bB2A577D",
 "0xc995A3D00F4C922757beE0b4ed70422B9A47fF73",
 "0xc9E7a9218dC2F30080F731DE5e29998427E3F8A8",
 "0xc9eD33f42bB0Dc26E7bA76BF61820328F03a3e5f",
 "0xCb33d3B2054Ab679074F566440Ad9eb5f43e4002",
 "0xcBC7894A2e85B9ede37Ff8c8BC80B125a890aa2E",
 "0xcE774ca9BA5A04e7fBb3fe47bfE75DEa6d78BbeD",
 "0xCeCfe64E27DEA7F337dC2fc963eEd21d51730fAe",
 "0xd3E66406bD9Cdb179fdeC30AA7d3f63b28Ef0cD1",
 "0xD5D4e55E5e6B2Ad64cF15eBce884CfE34450C1aa",
 "0xD5F609e64527F43569826551fDb1c63C54efd934",
 "0xD627C1f710F54A741DC2104780005500b9C84b96",
 "0xD632B9b3651817695f8733e656Ed8aF7591F969E",
 "0xd634FD8B07d29029359bc0a68e2Ea26DDA6B5AC3",
 "0xd65a09670aE3eBF98bd5B75A1f6533065f12Fb5C",
 "0xd6fA29dc1a4DB2CA919B2428FA39AfeC716C96d6",
 "0xd6fc613d949deABe63FC401416A4279A087DDf88",
 "0xD8F13D472E0A52245e35d7a0Eb6746e942440fbe",
 "0xdb3396542432A223F103527Cb987d560dB90112e",
 "0xDb57F1613Ef9d26Af65BCC5dD197a9f31a5aA091",
 "0xdbA095DA434e4B188B4C3B681a28b37e38Ac0601",
 "0xDBB6867c4085F6cca2A919A9611d58fCB113A6Ae",
 "0xdcB5f63467045d8f1838ED6bc8f76A527515aA60",
 "0xdCD4F7B13Bd5C647cb16e7D364B27eF468D93e38",
 "0xDEB88fc28A0B6aF53BD0bEEc2f7588d32D7fcbC9",
 "0xdfD880A8fcF14d7d4C0f90e062a97cFF20F967bF",
 "0xe25015bEB64f1051240f834Baf68311d6191AaB3",
 "0xe585f95b44905dfC8a8640C5B1933ba5d9BeCC75",
 "0xe5F1dc574b7aC25E416db8b79F7A97D3bb74b4AA",
 "0xe719FD122b3C50492f012622e866F590b180dd3C",
 "0xE83deD34AdbE4B52B1611dCA0ea4FCF23F3eE01f",
 "0xE9FA69E3f90f7Dd8570267C39b739bBd6B0aB4E7",
 "0xeA9FA1A3a9CF67584a758eb5BD4760b14510C583",
 "0xeAb1cD6D2DDe149F01b7330452480491BBB19056",
 "0xEBE2b4c6bB0ce7C31C9FC370967F3A042ac9d250",
 "0xeE9229213D9094001A8D1AF196800405011B009C",
 "0xf0104E41Eb8003d7F3c2Aa2d9a684B0D7a1baB2a",
 "0xf0762401d4360A02Bec763af881cfC83CBDe5580",
 "0xf0Acc92ed6fa386c6e3658539D3BCcEC2e7e8009",
 "0xf2447e44B9c4D9fBCb8eDd62C70C9c15f6dB121a",
 "0xf33Ff99514c71C6fb562c7D72fc0a5E5642c2D8B",
 "0xF34488813Ea18F2Dc392d324b91A71f0C182f6b1",
 "0xf41FCF8A7da7352d131beFeCd39131cE313A80aB",
 "0xF47e51499520A4D21E2C995D58A879C01252964e",
 "0xf54BF273717970e45cE30d1344ad099469bCa252",
 "0xf6158E06D58E36e6A0998185831E2834eBCecA74",
 "0xF6348B684F500E7398a72CcA08E4D87fb9681a59",
 "0xf6C15D7040F9d3Ba4Ea2049057BD29D73191818b",
 "0xF72b7D75b33aa72Ef68972fE08B52daE54bBD76f",
 "0xF9A025E96443fe8A129B98Def363848b71D8EFff",
 "0xfa2998fEA4dE910D2D3Ec6Ee3A281C98959B5739",
 "0xfaeDa3e9E4d03930f4Baf7fc625186E94102731c",
 "0xFb62e13f019Aa2aCFdEFB0DCf313453132c95ae5",
 "0xfbb4b3016dBfdE4308e8B108A4Ac4C4A10Ce8756",
 "0xfc63fbc70657E4719CBeC88461618fe1A0bF659b",
 "0xfcD0A7A75920a4eA487D535f71026888c86F4292",
 "0xfD635C1F8A2736E1c89E60fC5202c4CDb07156a6",
 "0xfFe323a4D0F3d7A2Acc0e581E75ba461d723460d",
 "0xfFFFE96D5dF4b535022Bcf9A901716bA3eBD8a82",
 "0x0a4341F492f8FA22A389c7546654cA44f5D1C8FA",
 "0x4a4de62deF811D7036a8fB666b8D4C2550Ff70fb",
 "0x3d33120103c9602B1281Da4D9E1eaE6eD9cD8977",
 "0xbA3cd6292643C74979F6FCB991fb1d9192135651",
 "0x2B927c125002371919ccCda76e45e8159aDbF6F4",
 "0xF18c767beb411fb6f4853a8F756Fd3f8C57999CF",
 "0x70Eddc502cb72affCDD064EDF0c8c3e731988cfe",
 "0x2b81dEE817C9cB177f8BB3323a63C45594591d7e",
 "0x3ccc9E75E6C63fcb68E30B81A3bc3209dB09A9f9",
 "0x6CcF0Fa295e6c4278dDCA2EfeeE7F465bA07ca0d",
 "0x0b1fBEd710F208e90683087cC77f85F98C180147"]
 */

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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