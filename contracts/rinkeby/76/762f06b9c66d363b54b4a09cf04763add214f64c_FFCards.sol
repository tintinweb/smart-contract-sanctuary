//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.7.0;
import "./ERC1155.sol";

contract FFCards is ERC1155 {
    using SafeMath for uint256;
    using Address for address;
    string metadataURI="https://fastfoodcurios.com/api/card/{id}";

    bytes4 constant private INTERFACE_SIGNATURE_URI = 0x0e89341c;
    // id => contracts
    
    //  IDS 31 to 60 = special version , ie card 4 = 34 (SE) , supply is 1. 
    uint256 constant CARD_COLLECTIONS=30;
    
    uint256 constant CARDS_PER_CLAIM=1;
    
    uint256 FREE_CARD_ID=8;
    
    uint256 MAX_FREE_CLAIMS=2800;
    
    uint256[] CARD_MAX_SUPPLY=[
        1809, //1
        1603,
        1584,
        460,
        438, //5
        438,
        1865,
        2000,
        1817,
        2000,// 10
        2000,
        1837,
        2000,
        500,
        500,// 15
        500,
        500,
        492,
        492,
        500, // 20
        1547,
        500,
        250,
        333,
        222,// 25
        106,
        565,
        400,
        200,
        816
    ];
    
   

    mapping(uint256 => bool) specialMinted;
    mapping(uint256 => uint256) normalMinted;
    mapping(address => bool) whitelist;
    mapping(address => bool) claimed;
    
    uint256 freeClaims = 0;
    
    uint256 constant PRICE=0.005 ether;
    uint256 constant MAX_PER_TX=40;  // buy limit per tx
    uint256 constant DEV_FEE=5;
    address payable constant dev=payable(0x25CAF0150A6D74544724554F4edfDFA2B0E7c182);
    
    uint256 public dev_balance;
    address public owner;

    constructor(){
        owner = msg.sender;
        whitelist[0x518e5A942Ed7Db4B45e9A491ce318373346dB240]=true;
        whitelist[0xD20Ce27F650598c2d790714B4f6a7222B8dDcE22]=true;
        whitelist[0xEdae46bc4357e4619397EF4E121fc3067D931CD1]=true;
        whitelist[0x49468F702436d1E590895fFA7155bCD393ce52aE]=true;
        whitelist[0x2466997b691e9AB01477E8058F51c77011Ca1A7F]=true;
        whitelist[0xB618aaCb9DcDc21Ca69D310A6fC04674D293A193]=true;
        whitelist[0xd836da33a6629548271eb9ef4f62D083376eB4A6]=true;
        whitelist[0xE6a9D0539FAbe0Fda237C3c4baFEaE2042B06E67]=true;
        whitelist[0x178A61498172D59BAD609b7Ad2469DD555642151]=true;
        whitelist[0x972e4394327f20C2c35758486212C9C85c02075d]=true;
        whitelist[0x3670f896ce5d578a5bd12f5D022fcE4015D70c96]=true;
        whitelist[0x97575AAC6912233403e9B8935e980DEc40c55548]=true;
        whitelist[0x1649B7518ED8D64f07771Ee16DEF11174aFe8B12]=true;
        whitelist[0xE4A12D142b218ed96C75AA8D43aa153dc774F403]=true;
        whitelist[0x820dA45C2641421a26314b271c6314AbB922A3B8]=true;
        whitelist[0xDf6e87287c96498320EC42a02C57A59C78c5133F]=true;
        whitelist[0xEd0d4aAeDb89eA4F62eb16E4033F05aCC359f938]=true;
        whitelist[0x5eA4B9E3304bBb2d9f3EA7ffDa0cAEbF83604A02]=true;
        whitelist[0x478aEfbBaDE4fed8E527c98552B68404Ea0a304B]=true;
        whitelist[0x275381048C9D6b9CDE3375815466F9aE14736a86]=true;
        whitelist[0xfe6474CB60d7a3771cd436fc9893f78dA7B8D7Bc]=true;
        whitelist[0x1DA7c2b48e22b9D823fB9420f26a95753C2D720b]=true;
        whitelist[0x3643420Ae82819Edd3f8Bf99bb4543ccCe478757]=true;
        whitelist[0xF65d7B36d147896A2FDD08A0f6fC59EA5a4BA48b]=true;
        whitelist[0x6F1B12a415E035eEbDc8559130eA8bdb96ADd48c]=true;
        whitelist[0xa4B0a77c312535B8a5863732ACC42cfa7B6Af9da]=true;
        whitelist[0x12BCF162bcaaB6C6F829dcaA5026D72aF956864c]=true;
        whitelist[0xD65919ef50cab25946d5b663211e9BeBcAA1de94]=true;
        whitelist[0xcE61cA41e238E0AA4c88D3c385dEE9a91c8E83d5]=true;
        whitelist[0xAd9F11D1DD6D202243473A0CdaE606308aB243B4]=true;
        whitelist[0xEe02d400e5bb07b1398FDA9E644F53e458256c8b]=true;
        whitelist[0xAE926010D9fCed9D05c0575732c4B69D79a16FE5]=true;
        whitelist[0x18BA0a1b3A9Bb30abef0D0dAbdC8e443d4b0B2ec]=true;
        whitelist[0x7d378ED22143F32FC86D0ACc463eB0adC29143D2]=true;
        whitelist[0x0764dc400C280FF2B6D1F0582969C0c668271340]=true;
        whitelist[0x6F879496D783559e8b50e09d6ea8F8143E74af36]=true;
        whitelist[0xb72181C41452E82F8b29F051EA48F26B8c4b1A9e]=true;
        whitelist[0xAE26b20104F4b7ef39d23E01b83048F28CbaE01D]=true;
        whitelist[0x66cc1dd0fF1C6fb9315444ED3679b5877FA219b2]=true;
        whitelist[0x07c9856e6d0cdA3b7d76d2954b61d5462c7CC2c3]=true;
        whitelist[0xfD3003D75ac304649a8F7098D87B96f6e097F9A9]=true;
        whitelist[0xcE9b6Da25e5B9578305F9c593C670736754Ed4C5]=true;
        whitelist[0x34407ec11973130509303011De431BcA3E633aA1]=true;
        whitelist[0x6eFd1D958bB9C42db8340E35a8fc8bCb159609c7]=true;
        whitelist[0x3e17fac953DE2Cd729B0aCe7f6d4353387717e9e]=true;
        whitelist[0x83C9440dc34DA00c47A0d4dC2b598d7BDB1b53F7]=true;
        whitelist[0x976Ecf870F376e53e4476eA4C7E13E21036c1131]=true;
        whitelist[0x92f708cF04A083Df54f77124abb8ec22692e3bb5]=true;
        whitelist[0x9a568bFeB8CB19e4bAfcB57ee69498D57D9591cA]=true;
        whitelist[0xe4f789F7549500f1809888CC732efc8Dec50daa9]=true;
        whitelist[0x4bf7Db76757302876d319Ab727E26ab66753128C]=true;
        whitelist[0x0Eeb15cadA5996AE022d72Ef5a1cf3f6A4f3a017]=true;
        whitelist[0xD035a780DECCF7808875c6a555937B7c44299F45]=true;
        whitelist[0x39183cd265F50Af7533eC058A4c807CA9bB6D10a]=true;
        whitelist[0xEbbb6cbAEac05094FBB0AA81b0f6510344fCA7a0]=true;
        whitelist[0x21d14E2c2BFCFa07de7999E08C4b0256293dE748]=true;
        whitelist[0xCa11d10CEb098f597a0CAb28117fC3465991a63c]=true;
        whitelist[0x48C3932347586d9354553C3a4eE76858E34d0CAc]=true;
        whitelist[0x4CC33bF57e8b507C115D253cA5018Dcea4eF747a]=true;
        whitelist[0xAD3E6A65B34D55C6CB20382E35114570Ba42eD2E]=true;
        whitelist[0x19831b174e9deAbF9E4B355AadFD157F09E2af1F]=true;
        whitelist[0xEb1FBB2D250D7A20eCD76A33C079d7C0B74F965E]=true;
        whitelist[0xECc953EFBd82D7Dea4aa0F7Bc3329Ea615e0CfF2]=true;
        whitelist[0x7335ce9EedE1f9d8940657B0d8a01080d3B5eA9A]=true;
        whitelist[0xb0eBc8B96f17DB967A8558fb3e33E05329fCf0C9]=true;
        whitelist[0xc797E9b7B99D1B0020b640bE930169d908DBe72a]=true;
        whitelist[0xFD35356DCD225Bbc7e8f1FdE622bfBF5AF105fe6]=true;
        whitelist[0x6456757ADC431892E368A9A4203F8625258BE47c]=true;
        whitelist[0x174D9FC753A8a7Ed04d3475d4260aC0d4e07F29F]=true;
        whitelist[0x4DE24ec733289921E7d190834F8e5f935D5961a0]=true;
        whitelist[0xe11BFCBDd43745d4Aa6f4f18E24aD24f4623af04]=true;
        whitelist[0x655ab4B2C31eAfFDDe8ab6BAf3F247e4245DaC11]=true;
        whitelist[0xA4663e48a4E2565d4d7c0fF85321294e2A313CFb]=true;
        whitelist[0x26c1e466CE41070585d6876dC17B7bD9295C41d5]=true;
        whitelist[0x5e153cdef9E03D7211Eb20654f9115B43Ca598Aa]=true;
        whitelist[0x80D1228F6eF0fE08CE83f675C1BA83a4d0C80a84]=true;
        whitelist[0xd5B3988eD0AB5ec375E51bB6fd10e205cEC16A2E]=true;
        whitelist[0xf2B9ec5724dC97362A53907c0b4cc0AA72369e63]=true;
        whitelist[0x777799e6f5DA150fDB667c4b3287D78cA12d3E2D]=true;
        whitelist[0xC51447aD3B831DFC5603B92bFa46A06637250851]=true;
        whitelist[0xa4d0cFEBfF84aE2A584c6dc0CA91d8768eDC299C]=true;
        whitelist[0xD9a657ACB3960DB92AaaA32942019bD3c473FCCB]=true;
        whitelist[0x55fe0C55359F02292E95b67763d41d0181399188]=true;
        whitelist[0x17c09406cA6e612893A104e4DD9b1Bc55D4C1120]=true;
        whitelist[0x73029536412d32449FB7135469368c65E3DBbE48]=true;
        whitelist[0xE0Dd8C40ACC74005C71CE5d02Cd5116A2eEDB1b0]=true;
        whitelist[0xB9D9BAa174702596FAc7ADcAb58325C741F2EA6b]=true;
        whitelist[0x6dfc99cdefD0f2Da327b0f31fd0046D8096e955B]=true;
        whitelist[0xa24804c1e84c51D24E17877493F29B9528EFD51a]=true;
        whitelist[0x0C2ccCcc447E7b86524F73C20eBAC195E721c584]=true;
        whitelist[0x010edAFA8a3C464413A680a1F6a7115B4eE4c74d]=true;
        whitelist[0x06CAd0470D892037B55672b1A9Ad85A16C86d12e]=true;
        whitelist[0x290FbE4d4745f6B5267c209C92C8D81CebB5E9f0]=true;
        whitelist[0x9F8b1dFF7f2B77D3532786dEB1213Bbe31c0676f]=true;
        whitelist[0x6Aeaab73cFF1aa7da9504Ec1E080D8E136a472f0]=true;
        whitelist[0x36A5Bc205DF1ED65C86301022cfc343a6ce546ff]=true;
        whitelist[0xB75CDf900688e5CA2922BbBDbDAB106039A5120b]=true;
        whitelist[0xfA6c54De608C9a0a2C2a3220bB7E42B95d1B910b]=true;
        whitelist[0x1D3643399e5534dd49f2B04F2f0615153bd209fd]=true;
        whitelist[0x263108604e0c9e1f6cdcf698E160Cd563635a328]=true;
        whitelist[0x08a03B37448A860883aaD9287fADEe602b23e296]=true;
        whitelist[0x23EbC99Ce4ee47e3689944ad40c810cB1b815E39]=true;
        whitelist[0x5D080b5D2718bd65678c9582519EB876c3042511]=true;
        whitelist[0xCDbe8a515aBe014b57A0aF0a989CbE5dd9820d8e]=true;
        whitelist[0xB830B2FD1518B04310D264704A4e46f9E083B41e]=true;
        whitelist[0xdB4A34F4794b661772A6eEeD8263698a1E15F07a]=true;
        whitelist[0x1DC814b5def304FeEc68548772176264A9DF98BB]=true;
        whitelist[0x0610Ca7e29a92bD84484A9C98C5563D9bD9c7531]=true;
        whitelist[0xb38BD68A6F0BA599808D65c7A9cF2a428105b680]=true;
        whitelist[0xC2789bABe1a5cd95E81AE5f2444E82E1391bF7ce]=true;
        whitelist[0xF89a7412049d1F8Ef55593ce0F64377E43624E22]=true;
        whitelist[0x52032c05d8991402195F1b4F2aE1869F46F953AE]=true;
        whitelist[0xb08F95dbC639621DbAf48A472AE8Fce0f6f56a6e]=true;
        whitelist[0xfFF33c0bde72f6472f1D185166b7CbFcc3E9e150]=true;
        whitelist[0x56A673D2a738478f4A27F2D396527d779A1eD6d3]=true;
        whitelist[0xbB20D7fB3cf15f5db693cb23F3eac76f74e0e1FF]=true;
        whitelist[0xc24D112C58a87C17a0484b2a7D8fD69E1B625CCf]=true;
        whitelist[0x5F7a0098E205343b2c58fDa149D8BD4f2Bb05895]=true;
        whitelist[0x4d0730811477a31ec202C04b3B72d43eE44CF8E9]=true;
        whitelist[0xa80be8CAC8333330106585ee210C3F245D4f98Df]=true;
        whitelist[0x3923DF650747cA0499cBF12ECD97BE7a3C0B623A]=true;
        whitelist[0x2A3F7E5170Ea8Ca967f85f091eF84591f639E031]=true;
        whitelist[0xE0666cAC0C2267209Ba3Da4Db00c03315Fe64fA8]=true;
        whitelist[0xeb97952c39C36aCE5Af7B2919ab058ab9BbCAD12]=true;
        whitelist[0x670B1a4b100f0ecbedEB3Da19198ADC864d1d9BB]=true;
        whitelist[0x40D80168B6663700B6AE55d71a8c2Cf61d0C1225]=true;
        whitelist[0x465DCa9995D6c2a81A9Be80fBCeD5a770dEE3daE]=true;
        whitelist[0x47045D1eE924AD6Ff890Ce8B52D6c1F08Ad42235]=true;
        whitelist[0x9Fd7BE134D8D4ddb8FA8D093e348C899716f6b0B]=true;
        whitelist[0xeD5EFaCc438E21eB6C9F83082fC061748989eb5e]=true;
        whitelist[0x31e99699bCCde902afc7C4B6b23bB322b8459d22]=true;
        whitelist[0x7cA1F0fC809aa7abdE1839a3607295bf5902EBf9]=true;
        whitelist[0xc1C42a4CBd6A71Fb03C681658aC85A60e09E0C9D]=true;
        whitelist[0x2b0D29fFA81fa6Bf35D31db7C3bc11a5913B45ef]=true;
        whitelist[0xdDA652DabdD7c9A50cc1Fe389B6Ae93570539B82]=true;
        whitelist[0x13Ac2c9314C262F1b79D5A9B331B625b15EF029F]=true;
        whitelist[0x910f50D0f8c5Faf30d29fb9DD1B7ed65C5A444fd]=true;
        whitelist[0xb3522064694Ac9870Dbf00eEBC2712762193Bb64]=true;
        whitelist[0x333Bd1558E02e42676CEdE4C439448100F3b9bc9]=true;
        whitelist[0x5Fae9D4B591f213b3bA75287f2cfAc0883D17f7A]=true;
        whitelist[0x19847a32B0eB348b006C79c1FB2d3aE1276c6028]=true;
        whitelist[0x75B772F2Bb4F47FBb31B14d6e034B81CB0a03730]=true;
        whitelist[0xBd72D021d3cb334dEb3151Db905EE073b8eEE518]=true;
        whitelist[0x59165f6219936b1E6A970c44F750d588d1F5D558]=true;
        whitelist[0x5cE9aD759E41BF1b3dFC1a41Db940A90d7a43460]=true;
        whitelist[0x0EA9f5D0C97b430D5426465e2832A504Bd6Dd9F9]=true;
        whitelist[0xf7229519D48CAdd0748d54C15df8E6434aA66CBC]=true;
        whitelist[0x85d1696B6F859465Fdbd42d1e3d6D8Ab3fe1431F]=true;
        whitelist[0x2a8f1940ff9EdB8a6be937F171Cc12e1E2eAb264]=true;
        whitelist[0xC9d25B9A3496c776688833D6cCfE507Ef4f41645]=true;
        whitelist[0x7EE8F8f465896f56EDbDb5209015b64249c96DDC]=true;
        whitelist[0xC8CCE8cac93A010B02E3b7e4e083B0465b1d36F2]=true;
        whitelist[0x6eBDbCAcfFDA2F78Be2B66395EE852DBF104E83C]=true;
        whitelist[0xd3F0862E4AcEf9A0c2D7FC4EAc9AB02c80D7b16c]=true;
        whitelist[0x5AE9a64F9f5EB912662FE348F8EaDF33F0a9dE12]=true;
        whitelist[0x8a13Db815d3b3359A6ec7fb1137a04704d8984C6]=true;
        whitelist[0x7e455CAaC23Eb8eD9884f55eD7e5A42d5DEC2bD9]=true;
        whitelist[0x23a5d154429Daab56360ed9f5b729634aB40FfB8]=true;
        whitelist[0xa585a32D3509a7acDa9c8438f2D975d6AA6347ee]=true;
        whitelist[0x54bec524eC3F945D8945BC344B6aEC72B532B8fb]=true;
        whitelist[0x8E6e6e6ea346bE5bAc353caD8F48D65b2a1cA01e]=true;
        whitelist[0x15daD22419B7e23C5cD9a47380Fd6B14623fE07b]=true;
        whitelist[0xbf70B986F9c5C0418434B8a31a6Ba56A21080fA7]=true;
        whitelist[0xaD5957d9527Ae3412270aFA5AEd589a482982580]=true;
        whitelist[0x55611b747Af18E27bA99C251377912FcD96ea656]=true;
        whitelist[0xd49F791e5919204f063a794D652287a65E95dc59]=true;
        whitelist[0xD772Fb57b3136fbC8caba86Dc82200124385dCba]=true;
        whitelist[0xF1db8A2623193757317639d0532daA5e3C8EA20c]=true;
        whitelist[0x57805B72EE6838866F4937CEd7E9e3b76CF527e8]=true;
        whitelist[0x426923E98e347158D5C471a9391edaEa95516473]=true;
        whitelist[0x5b4Bff0a281cC480103ef992CFEF0b1e10d62969]=true;
        whitelist[0x73024F4C577ded086CCf97921c51286F8ed1Ce86]=true;
        whitelist[0xCed2662Fe30D876bEf52F219eeAC67e2b328Effc]=true;
        whitelist[0xE8aeA1BBA7aec9b7a4522e6c2A96327964c217CB]=true;
        whitelist[0x47BB55752db81389b684E8660Ca9712470e3d843]=true;
        whitelist[0x2999377CD7A7b5FC9Fd61dB33610C891602Ce037]=true;
        whitelist[0xa97d80fFD0a12eB1C44469054cCcF8aDF45D6a3d]=true;
        whitelist[0xcbEACE38860ec4140a2d8A90b2F7EFd7e6e9d1Fc]=true;
        whitelist[0xD402514D2fEc96dF7294Cc53CFBe756e5b761f03]=true;
        whitelist[0xb292A277b61341cf121FEd5A710B05E998bEC6B5]=true;
        whitelist[0x0a373008F6712aEd69D699BCa4C72CB71666c627]=true;
        whitelist[0xd9f7FA14dA177ff68bAD47ab30fE933Db75c3e43]=true;
        whitelist[0x2F7670e702dC14c87C7690701E4442bF5b474A50]=true;
        whitelist[0x684981C4f9635A1e9d666CcAe2a0f8312cc57745]=true;
        whitelist[0x6fcaDe9de3aB9A1e57Eab1684cf30e2CEBa234Fb]=true;
        whitelist[0xC283C9eeb9Ee4117d64c410C3D7511B0B9f4C5ac]=true;
        whitelist[0xD98779366fac82a66f82d22749C9AC13d91fb8Fb]=true;
        whitelist[0xD82ae6C377e9cfd6eeBFF48bd4caAA2814319a04]=true;
        whitelist[0x6D334a61967237b3a15d763f14017CB1c7ABc1C1]=true;
        whitelist[0xF6032Ef54ff0a2439245731887815bed94423125]=true;
        whitelist[0xa1f257F534d2eA65b2B6be420d01E552114872c5]=true;
        whitelist[0xDFe8beeE223412F316baf2968B17527D6EbA29F1]=true;
        whitelist[0xB541edB5D1A02BE66507674A6A53e286ad09DF23]=true;
        whitelist[0xaC94e0B83367ccb1fe64dc333757f48B07577B1f]=true;
        whitelist[0xDAE6cA75bB2aFD213E5887513D8b1789122EaAea]=true;
        whitelist[0xF65d7B36d147896A2FDD08A0f6fC59EA5a4BA48b]=true;
        whitelist[0x25CAF0150A6D74544724554F4edfDFA2B0E7c182]=true;
    }

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }
    
    modifier onlyDev() {
        require(dev == msg.sender);
        _;
    }
    

    function supportsInterface(bytes4 _interfaceId) override
    public
    pure
    returns (bool) {
        if (_interfaceId == INTERFACE_SIGNATURE_URI) {
            return true;
        } else {
            return super.supportsInterface(_interfaceId);
        }
    }
    
   
    
    function withdraw() public onlyOwner {
        uint256 total=(address(this)).balance.sub(dev_balance);
        payable(owner).transfer(total);
    }
    
    function dev_withdraw() public onlyDev {
        dev.transfer(dev_balance);
        dev_balance=0;
    }


    function mint(uint256 _id, address  _to, uint256  _quantity) internal {

            // Grant the items to the caller
            balances[_id][_to] = _quantity.add(balances[_id][_to]);

            // Emit the Transfer/Mint event.
            // the 0x0 source address implies a mint 
            // It will also provide the circulating supply info.
            emit TransferSingle(msg.sender, address(0x0), _to, _id, _quantity);

            if (_to.isContract()) {
                _doSafeTransferAcceptanceCheck(msg.sender, msg.sender, _to, _id, _quantity, '');
            }
    }
    
    function random(uint256 odds) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp)))%odds;
    }
    
    function currentSupply(uint256 id) public view returns(uint256 supply){
        return normalMinted[id];
    }
    
    function claim() public{
        require(whitelist[msg.sender],"Sorry, you were not selected for the free claim");
        require(!claimed[msg.sender],"You already claimed");
        require(freeClaims<MAX_FREE_CLAIMS,"All free cards claimed");
        uint256 cardsToClaim=CARDS_PER_CLAIM;
        if(freeClaims+CARDS_PER_CLAIM>MAX_FREE_CLAIMS){
            cardsToClaim=MAX_FREE_CLAIMS-freeClaims;
        }
        uint256 cardId=FREE_CARD_ID;
        bool claimAvailable=true;
        if(currentSupply(cardId)+CARDS_PER_CLAIM<=CARD_MAX_SUPPLY[cardId-1]){
            cardId=10;
        }
        if(currentSupply(cardId)+CARDS_PER_CLAIM<=CARD_MAX_SUPPLY[cardId-1]){
            cardId=11;
        }
        if(currentSupply(cardId)+CARDS_PER_CLAIM<=CARD_MAX_SUPPLY[cardId-1]){
            claimAvailable=true;
        }
        if(claimAvailable){
            freeClaims=freeClaims+cardsToClaim;
            claimed[msg.sender]=true;
            normalMinted[cardId]=normalMinted[cardId]+1;
            mint(cardId,msg.sender,cardsToClaim);
        }
        else{
            revert("All the types of cards available for free claims reached max supply");
        }
    }
    
    function buy(uint256 id,uint256 amount) public  payable{
        require(id>0 && id<=30,"Invalid id");
        require(msg.value==PRICE.mul(amount),"Amount sent is wrong");
        uint256 cardSupply= normalMinted[id];
        require(cardSupply<CARD_MAX_SUPPLY[id-1],"Sorry, this is card sold out!");
        require(amount<=MAX_PER_TX,"You cant mint that many tokens per tx");
        //odds increase as normal supply is minted to guarantee at least one special card will exist
        dev_balance = dev_balance.add(PRICE.mul(amount).mul(DEV_FEE).div(100));
        uint256 se_chance=CARD_MAX_SUPPLY[id-1]-cardSupply;
        se_chance=se_chance.div(amount);
        bool normal=random(se_chance)!=0;

        if(normal || specialMinted[id]){
          normalMinted[id]=cardSupply+amount;
          mint(id,msg.sender,amount);
        }
        else{
           specialMinted[id]=true;
           mint(id+30,msg.sender,1);
           if(amount>1){
                mint(id,msg.sender,amount-1);
                normalMinted[id]=cardSupply+amount-1;
           }
        }
    }


    function setBaseURI(string calldata _uri) public onlyOwner{
        metadataURI=_uri;
    }

    function uri(uint256) public view returns (string memory) {
        return metadataURI;
    }
}