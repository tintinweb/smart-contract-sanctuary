pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "./common/meta-transactions/ContentMixin.sol";

abstract contract PausableClaim is Context {
    bool private _claimPaused;

    event ClaimUnpaused(address account);
    event ClaimPaused(address account);

    constructor() {
        _claimPaused = true;
    }

    function claimPaused() public view virtual returns (bool) {
        return _claimPaused;
    }

    modifier whenClaimNotPaused() {
        require(!claimPaused(), "Claim is paused");
        _;
    }

    modifier whenClaimPaused() {
        require(claimPaused(), "Claim is not paused");
        _;
    }

    function _pauseClaim() internal virtual whenClaimNotPaused {
        _claimPaused = true;
        emit ClaimPaused(_msgSender());
    }

    function _unpauseClaim() internal virtual whenClaimPaused {
        _claimPaused = false;
        emit ClaimUnpaused(_msgSender());
    }
}

abstract contract ClaimableByPreviousOwners is Ownable {
    mapping(address => uint16) _balances;

    constructor() {
        initBalances();
    }

    function initBalances() internal {
        _balances[0x0FD522AA67B0b5d9429aBA6F6BF828454d0Ef03C] = 1;
        _balances[0xae8277ddb7D9EF0913520F3579bf155c591C6d44] = 1;
        _balances[0x1fB4b19861Ef7bb4De78d90fee2ce6d09D8E0BF7] = 4;
        _balances[0xe635B15291F31c1ba6C7a6C3D26cBdf6C0f77204] = 27;
        _balances[0x4EbE3AA1B6a599Cc1c338F9D32C8Aa747b7c8e51] = 15;
        _balances[0x4DF00689952974eDbE1Cc05D2710Ea1B2b6E185F] = 11;
        _balances[0x61e309F348F1AFb007d92dA348aA0cA006BE11a5] = 2;
        _balances[0xF69bC34B73DA823e18A6960975fB865a29B218A1] = 1;
        _balances[0xfd6230b8956b7F0f828bd1a58941396E256a19FB] = 6;
        _balances[0x0F7d51c5aBa85246CE83CaD6669C70b02910F910] = 3;
        _balances[0x297F9B53C6F7FCe35c7ACE6499Bf9ddfA6B8B5C9] = 1;
        _balances[0x8679DE11BE15aB60f718Da5eE77d8fa75604Ac16] = 8;
        _balances[0xC5CcBc1a97C508D46060f266c4814e05269E43d2] = 6;
        _balances[0xDc62e941fDDBDdDFc666B133E24E0C1aFae11847] = 12;
        _balances[0xa88235065D97A56719Ea7D4Fe72F8f953C984C0B] = 7;
        _balances[0x7f0413995EcF9E921CD9c0658afECa39d59289B3] = 3;
        _balances[0x55A5705453Ee82c742274154136Fce8149597058] = 3;
        _balances[0x827DeDC7D8f1FEe249fDf95123Ced9d03Cb2ab3B] = 2;
        _balances[0xa08F235264EC058333DBbDF2be8dc57751dC2210] = 1;
        _balances[0x167BF4636FA1C196807915C32845d0a55E53482F] = 2;
        _balances[0xA6311952D5E6273074977Cf9491965800FbC9233] = 3;
        _balances[0xbF590F3F6ee928e910a15F797ECeF239c83B39E7] = 1;
        _balances[0xBB1515279cF32eDddE0341241c2edf54866859cF] = 1;
        _balances[0xAe051E32Df2Facb1B1CaE583fD10481b6deaAc73] = 12;
        _balances[0xbC022950EC0aaEe835e49060cDB97739c51618be] = 1;
        _balances[0xB77e94369E4fF7CAF9c6fB955f8FA7Ffd32A5E94] = 1;
        _balances[0xC8b1F17000C85B56ea663A92cc17049D5419C5C4] = 1;
        _balances[0xf56D5F85C7557f65fE8Dd8090907a7117c048295] = 2;
        _balances[0x82B47799859E354eac6dBA1D0f6Dd5b45124c14b] = 2;
        _balances[0x27C934Ea235abD41bDd7Cfb48f7B1Bb9e629dB57] = 2;
        _balances[0x6d06eF9F663C0dDfD00126afb379eBe17C927794] = 1;
        _balances[0xcfaE6215009b5069DCc82d8498994B3Dd32a2DE1] = 1;
        _balances[0xAFF516744DDd9e285BFFa384c2Ef1b295e47ffFC] = 2;
        _balances[0x590534CbE8B5aC2890F77652fB5F0d334F18A0a3] = 4;
        _balances[0xC9fcE24f72B5F390E3f7bb2CF5D67fd144E51a89] = 1;
        _balances[0xb8A1E33F2A5D78225639Eb3283EA0a11a178225B] = 1;
        _balances[0x8d454e8f00D44aAd56Cccf12A3Cbe608fa58C6e0] = 6;
        _balances[0x765d46f2d42a21fa7C79294D84a45a5328a2a6Fd] = 2;
        _balances[0xCfF9Da0cA651dB868b95eeE4a74E46d43f115331] = 2;
        _balances[0x14E8F54f35eE42Cdf436A19086659B34dA6D9D47] = 1;
        _balances[0x397065ffeC392dA1C3b0D10a0C9fe946eCC91581] = 1;
        _balances[0xCDEb7C898602ABbfBC3966E7ce13A8b498b79Ec1] = 2;
        _balances[0xB5619CA0Bdd458EBfbc2b8B4b823E23D5717ea67] = 12;
        _balances[0xB3a5dA02664030Fe55f7bB0A16D1dCA1202F2868] = 2;
        _balances[0x91F227B05664f73cdEc5Dc78c37C91FcB7ABE956] = 1;
        _balances[0x29305910D110E24776053BA1376fb85A2Ae2Bf05] = 2;
        _balances[0xaA4681293F717Ec3118892bC475D601ca793D840] = 3;
        _balances[0x1802a514921e9Bd0a564E3F6720Aa3181d6eA46d] = 4;
        _balances[0x9AB7ADae1579eA2843742e6618433995b0F51044] = 3;
        _balances[0xc37Cc77B2E54f33e20A6EF42A52621F76EdD7Cc2] = 4;
        _balances[0x5D9FdfaACF5bC2e759fA210F6de3D7de5457B385] = 2;
        _balances[0x413eE671f3351f54CDeC60BFabfFca7E7E5A32f7] = 2;
        _balances[0xf7c32dc50685a75bfC58d0c3e642756BbFD3625B] = 1;
        _balances[0x179d872918135cD08122A16F7e2d52dDC8dB739D] = 2;
        _balances[0xED87aA0f671Cc6A5183bDD4Ca62878953142644A] = 2;
        _balances[0xe86dE2E2159090325429F20a77E051DAf97BA713] = 1;
        _balances[0x2EddB9CAb9EEb5AB229b956caC87479923C88C11] = 3;
        _balances[0x8725914eD034ca5d448443773A52ccd61C70281c] = 1;
        _balances[0x1F5Db7e50B086E89d8377fb2c4F22C7ea718A294] = 2;
        _balances[0x70d31251EFA31Bca4cfD370dB44f0a28Fc73662C] = 2;
        _balances[0x3faE9be26e14d789BCCb78Afb7DF4e9B288BEC73] = 2;
        _balances[0x315AE5C7F9B834616A5b5F2De5a7aefC79573FBf] = 1;
        _balances[0x67A095e00BB529374a6D4a35dfe41FAc82721b38] = 1;
        _balances[0x48a6ceaBf9998f11d97c304a4d38e7743DA4C9D4] = 2;
        _balances[0x7F16EC6D12ae3dFD255A022b52655A58Bdf75619] = 4;
        _balances[0x1B88a333a687F1608fdC71711b9DaCebD75D23dd] = 1;
        _balances[0x66C81E6222a01a67433746f018b3335Cad64D725] = 1;
        _balances[0x45Ebc55C3D90787F8379EC50c50ACb3fa1d51dfE] = 1;
        _balances[0x4E920B5721f4cf771452AE0bb013465261a4Ac11] = 1;
        _balances[0x66Ec34310bD83BE9cfa1A4d52C12Bdf4Fa6958C8] = 1;
        _balances[0x84341bD75AF5abe84E825601540F6F5649F0c2C4] = 1;
        _balances[0xDfC8a3e6fE8251E05c484f302858D36B1BED3e38] = 7;
        _balances[0x460D25dEC453926B861bD30ee55b6e6694e23508] = 1;
        _balances[0xE082e2da3E7AdD94F3Ac7C43828025174Be309bd] = 1;
        _balances[0xcc4803F3409A9A6405DFA39D9E29822e4414a3fD] = 1;
        _balances[0xD80775766186eF44c73422fDF97D92701C27f70E] = 1;
        _balances[0x8dFf027daADEacC7898851C4e750078aba53b922] = 1;
        _balances[0xa1559B0E3DFFF3fdDA0c45cA6d7C4C75188A90cE] = 1;
        _balances[0x8F64C199659612133A354cA289f355709E16eb47] = 1;
        _balances[0x8868d9eD819ebb22717c2Efc24deb864AF0988F1] = 1;
        _balances[0xDE861b1eE25D1dd7389d6A39d7aA6AB7868F16Fa] = 1;
        _balances[0x02C545e7E16afbBe405FaD98a8a5a9a9fEeCe114] = 1;
        _balances[0x79c800Da3577CCFA8813EDc5aBd91d328bC44bEE] = 1;
        _balances[0xC49786d5546edef7659621FF1746Ca6bAF6C50A4] = 1;
        _balances[0x0866e68B37CEc2517a7dB3b26BDCe0D7F5ca8CB6] = 5;
        _balances[0xa0Ff708151943D407ff866232e971471b0F1aD9a] = 2;
        _balances[0xA0625F017259a8F85C7501c6b4D7AD276FE59993] = 1;
        _balances[0x811c1aB500966bAE6eF3451c2c1820d89C3A9F0A] = 3;
        _balances[0x25f9454ABf96C656A151D85cD74EFD008838Aa54] = 2;
        _balances[0x823a76F7047b9d85e0220684Ac5e5752CC7AE494] = 2;
        _balances[0x0dF154Dcb67b92fF07e52f69A30BD4290B01C44B] = 3;
        _balances[0x9F696C668758C033a8EfFF03F73D8f8aC7fEAe08] = 1;
        _balances[0xEE74c2B604650FE6468f9f09Fb0685719Aeb735B] = 2;
        _balances[0x7e00f4110Fb7D02A91632895FB93cd09af3209c6] = 34;
        _balances[0x6bF866997112eEbF2B4F78F5840b218B2F6259e2] = 2;
        _balances[0x8C96838603Ee0620d6d970D415714E674ed20522] = 2;
        _balances[0xb16B295C3E174e650660e74B5Ec4aBe44c29849B] = 1;
        _balances[0xE8075d7B965e8BA4938ed158DE944E1E02A21D30] = 4;
        _balances[0x8E808a12345F954D6323d96a140D85daeaff82a9] = 14;
        _balances[0x5DCF136F33b537E0Ccc557e527276354C3CaB489] = 1;
        _balances[0xaeD49bF1C006Fed7a0C27a0C382a2f086019cDC3] = 2;
        _balances[0xbBcFf58f9707a419AD7a06A3993415B880c3Bf04] = 1;
        _balances[0x78Db105632eD69dB8a8c528559dC9d9f220d8171] = 11;
        _balances[0x9F5259Fe40F34941AcD627388Dc24d4DCf9b117C] = 1;
        _balances[0x704460AF51b7352cfe7b519CB18F9dfC4E6F52C7] = 11;
        _balances[0xf02Cd6f7b3d001b3f81E747e73A06Ad73CbD5E5b] = 1;
        _balances[0x6CB5c9fd6df9Ec4fd1B61C611A88161965E0D7D0] = 2;
        _balances[0xA021Da3af846EAdF9539Bba8D0d5Ac59C87B3ed7] = 1;
        _balances[0x0E5a1d84eD69067C078596bc6A17452425B005F1] = 3;
        _balances[0xA68d1Edd58Af7ceFe8F11DFDa18Db25C78206257] = 1;
        _balances[0x8E49b61Be4F02D68Eb620954730B5cC74Ef53b92] = 1;
        _balances[0x1A4999048a9Fa13125edCE959De4A5713B76735f] = 1;
        _balances[0xEA6F17757172B189342852744D17577408d0f6af] = 2;
        _balances[0xf4055bc28cb7Fa396A08FC0e8575fCF8498a4Dc6] = 1;
        _balances[0x9d80eDefb33F7Fa40DcFF768E15A173F0498d183] = 2;
        _balances[0xADAae0CF49B422fB24cB988d669e77F4E015608c] = 1;
        _balances[0x7B75BC70b928472856047FDEf0D08D5B5816AEFD] = 1;
        _balances[0xB6461bF5223dFe357745895ef4473024E9dC2E20] = 1;
        _balances[0xF521152c5fa16d2759E5D8885Db2Fb4DBE776647] = 1;
        _balances[0x2C13ccA4F78cE2e725111Bf9ed75cEdF51277061] = 1;
        _balances[0x635540C2BBf977d940bFb2C392BEf54b5449a313] = 6;
        _balances[0xbb434f639E9D56D15143A4cd4E6FB4b3310023dC] = 2;
        _balances[0xdAd37D1703872cF66d2C9aE521ea4a78C1d9Bcd1] = 2;
        _balances[0x4f2fF081BCc048fD9ADFA008453f1Bb017221150] = 1;
        _balances[0x1824655211eF781631C89372fE56f030Cbb137DC] = 5;
        _balances[0xB3f14DdE153F1f400fC4534041A8ccb293E8f123] = 1;
        _balances[0xd559eb2bdF862d7a82d716050D56599F03Ef44E7] = 5;
        _balances[0x9d156bc7c8768294510A4A41883d5A4EB15b15E3] = 1;
        _balances[0x34223719D75CBC336b77cCd8af6B9342bd6Af1cB] = 1;
        _balances[0x233b329780074a3A0fA4E90CD1f5e0Bf528F8736] = 3;
        _balances[0xac85b2C302e26E5a994a88203CaFE3797D1361e4] = 1;
        _balances[0xc1a880D8e488c16541E76EDA6e6aE9a1495F2DBF] = 1;
        _balances[0x69816eA28F78395c19770585c9C2eBb516500a7d] = 3;
        _balances[0xf09B1BCFFaD71B71eE0ef587dE93cE05E5C65cC3] = 2;
        _balances[0x869139316d79117003D69bD41DEaeCA22eA6cE18] = 2;
        _balances[0x8D23c2dc93bE2C90728c45Eade4d574E04F82Ec3] = 1;
        _balances[0x68d506515278069558C3AbD6790E111Fa6993E9B] = 2;
        _balances[0x17024bb9827221f6D9DAbaDed36F850c8cB522c2] = 1;
        _balances[0xF061Ef570e84Eff26dAA32017f63f3016636DC99] = 5;
        _balances[0xFC502A09854F5685171F6766F22f92121999248F] = 1;
        _balances[0x15F7320adb990020956D29Edb6ba17f3D468001e] = 1;
        _balances[0x726022a9fe1322fA9590FB244b8164936bB00489] = 6;
        _balances[0x82466928c6cf6984B723A653b3faA3E8206e09c8] = 1;
        _balances[0x16E397096381Ea03a02c4435a8118B3603C55C79] = 1;
        _balances[0x5c35B34610343bF51C30B3f5C590d972D9FAe97f] = 1;
        _balances[0xa0ba9d15Defb5E4667Fd14d2A65be5B4B191948E] = 1;
        _balances[0x295B0128e6a5a10d44dc6E079b419f1D21B075F6] = 3;
        _balances[0x6e8eE4656308297DdfeCE05b32f12aC24b1608e2] = 3;
        _balances[0x9f03f1a9Ea78741e8B741688Dd07768D347E24D5] = 1;
        _balances[0x7D112B3216455499f848ad9371df0667a0d87Eb6] = 6;
        _balances[0xB00CD8e790eC45971A04695849a17a647eB74463] = 2;
        _balances[0x65f7E3EA4c1507F50467B7334E6d8f7547bb41D3] = 1;
        _balances[0x581bD489306dF3fD5095b79d914D0db0F52eebD5] = 3;
        _balances[0xBf96b053003F62c67DAbD3d5fB64757033141Ba3] = 5;
        _balances[0x9C2355b55f2C6a4Da56731AAd78BB4b5a69e271A] = 3;
        _balances[0xA1E58AB88494Cd42F6902F6A2d6F3a35B92449B2] = 2;
        _balances[0xd065e59ba15836a50cd473AF4E51C77Fb2c3E1Bd] = 2;
        _balances[0x9C7b82c0302C7c945F9Cf45A5c73E6f48Ab84B14] = 1;
        _balances[0x8d174461277169979E7b5a48Eb94E85C9D62C220] = 1;
        _balances[0xA2ccdba148D69acb8e6054bAEFfCb564093bb6f6] = 1;
        _balances[0xdab13b3dBE8A3Ce3F864D1184Db9ddA24bB1D88c] = 1;
        _balances[0xd81be2Dd1fE5E3F9aAda3fFea6d64e62506edAcc] = 7;
        _balances[0x484749B9d349B3053DfE23BAD67137821D128433] = 1;
        _balances[0x38a63b0ae13d0d42BfF525f7766Bb3BDd7C2F68B] = 1;
        _balances[0xf71596193FbbCd97e42643C3112984b5e0355D3D] = 1;
        _balances[0xa85819617a048287Ae2f5bA42740D7d71C9e439C] = 1;
        _balances[0xbf38B42a96B0e33BE5F7eD18f14ffF7Aef14c99F] = 1;
        _balances[0x661f4B2c3675a4c1D4CD1DA8B7975357B01ec2Fa] = 2;
        _balances[0x528eDB13C46fF3Ff67C02ad23ebe230bF49f0b0A] = 2;
        _balances[0x9D0242be6a359935a594101B6E197EF008524239] = 1;
        _balances[0x414826bEb718F2b204Bca67b949604bdC739fCBA] = 1;
        _balances[0x3D5c457920Ff88a7a42D2aF63d450E5F2da61d14] = 1;
        _balances[0x90eBBdcd83B62C5528b4c95C58cfc5c054159836] = 2;
        _balances[0xEA06c7B29fEbe294C934eB8BFdEc476399063A5f] = 1;
        _balances[0xe77F50BB4734131b9dAc49Ae9bA243164030d1CF] = 3;
        _balances[0x49131F1A71414cc29fE5a8d408DD6AaFe0E48C4D] = 7;
        _balances[0x09800064d8321571e657C507e62cA92faf5c039B] = 1;
        _balances[0xe1dE917A6089f7c01ACCFb42695e2411d3B1DfD3] = 2;
        _balances[0xaa6CaA910C45FC7994bc5130F0bDE78b0Ff5E9c2] = 1;
        _balances[0xEEb6Faae3094b31859f6B7b34a183Ae212e43cfb] = 2;
        _balances[0xC006562812F7Adf75FA0aDCE5f02C33E070e0ada] = 1;
        _balances[0x71bE73dc95f816F69c9fB95EB985D1F1723f2392] = 1;
        _balances[0xE545C4A3f3265AA61366fda81f9c5f4f07A94c7f] = 1;
        _balances[0x12269196C57e800824762E5ed667b5b8BA5e364E] = 1;
        _balances[0x7d7d7F1A2aD27c110f91Eb89FF9c724B0Fd738F1] = 2;
        _balances[0x9b353523F266b3E1740f4077F5cA6A5aD070Cd8d] = 3;
        _balances[0x347d60941302bcB2E8AcBA3Bd78a8102413D14d4] = 1;
        _balances[0xa2f8ae5AF7Bd75d54ED172B3b9E557d104D3913C] = 1;
        _balances[0xbd16Ea350f19025ad2B92C3325a4D90e1205c7be] = 1;
        _balances[0x537b8e05b64D4af48d872F4251fb17a6A495E2e3] = 1;
        _balances[0x135b123FB59914DD7ff8cb8d2E92130D7BCB7bb8] = 1;
        _balances[0xC1117743CDE4dF3613A21a68Ab67CCF2cf040a54] = 1;
        _balances[0xFd186097B50370f400d0B428B9D5fF30b445a1aD] = 3;
        _balances[0xF3729461EB8fA31b078E4d6942c8c7f8Dd980989] = 1;
        _balances[0x0E944b6dEfBE18cb96a23AFA89325d1bfb01C5D7] = 1;
        _balances[0x782dCFDF065DFf4E80AfF38DAF6Df56A140181F4] = 1;
        _balances[0xDDB78a9f19Dd30246f53C947EC2eDB9dbAFF620F] = 2;
        _balances[0x5346A77C05FeEB4212Ae787bf3FDdFC48ffBcaC7] = 1;
        _balances[0x60aE12cDa66dab717d6Ab827148BC27eA22790a8] = 1;
        _balances[0xeE1CeDC52b268AB57844D0713657755af36671F2] = 1;
        _balances[0x4caDFE63af96404BcB3FbEF877Dc7AAf2593156d] = 1;
        _balances[0xa115201E245f16CcA90Ee1039290b690dddB5ef5] = 2;
        _balances[0xed01D36c1e315bb44b83d28bd78e78fFAE907ecf] = 1;
        _balances[0xBd852165A6fF4A4C04c1e378BDc90d6801929457] = 1;
        _balances[0xF9EAaC7E3ADa891F96CcF670cc3317A77CB5C7f7] = 1;
        _balances[0xc2587a1685b194831C0e4a8927DF0c33437fca3F] = 1;
        _balances[0x14A0adF86EE9b596f93DBb7dA5AFf6Fd7d3Ff160] = 1;
        _balances[0xb622772dddb59a9939458D8322e28a54e2ac1E89] = 1;
        _balances[0x8A274082CB26FE745374d4Def69C2432EADf2495] = 1;
        _balances[0x0Be2eA1A4b1a4098Ba535fC92F2352d103B5FFA0] = 2;
        _balances[0x3558B79D7503c0eCEd3B76CbF1894Aef327b0e76] = 1;
        _balances[0xf86780EdE26501CfC4649B4c1D7629e68A10F314] = 3;
        _balances[0xCEFD0E73cC48B0b9d4C8683E52B7d7396600AbB2] = 5;
        _balances[0xcB63958cAff1b3b94CB0D6875cD23e945B06A9dd] = 1;
        _balances[0xC7f8e17a84a8B18fDBe539C62A02A2709a044c65] = 3;
        _balances[0xEF610520a1ebB4c1F91d5A94D636a3274204D74c] = 5;
        _balances[0xb75ade59b0B962f90d1428B7024Dd628cC993Acc] = 2;
        _balances[0x10C342c1188Ce7c8b3444D8c7b99765Dadd5026e] = 1;
        _balances[0x88Dc672624B511DBF08881624629a13AF10aCFCE] = 1;
        _balances[0x1c70D3a0A945a5146cB852C47C9f93cA0b59aFb1] = 1;
        _balances[0x8F18d6a49Bb392a84A4A4c03B69D29179e333946] = 3;
        _balances[0x4c8ad72f93C7BD2131701F3790e6D06cc56c651F] = 1;
        _balances[0xE79Dc3C65cDd6B7a443297D2f412e27ff43eaA6C] = 1;
        _balances[0xEa88d663E8cC803bE8713199437355Ee50f68EBF] = 2;
        _balances[0x48d89aA6A0340Fb6dF240bB04611eA4d3dD4fa96] = 1;
        _balances[0x8719CC70152c03B0282216f4B97051467b2654Ec] = 1;
        _balances[0xCb7f2Fb6f83654E769e037C8d937f96Ea55658a4] = 2;
        _balances[0x790d5818D56F5a7a8e214A42797752822117BF3D] = 1;
        _balances[0xb104371D5a2680fB0d47eA9A3aA2348392454186] = 2;
        _balances[0xa9DE88886d114a4D7abdb43aD3a5F4BFeEdB5557] = 1;
        _balances[0xB26c7C84456241A8a48b5C7177f71A84Dba7B084] = 2;
        _balances[0x7d7EA735b7287D844c3A9312bC1114C6131781D0] = 1;
        _balances[0x7217BC604476859303A27f111b187526231A300C] = 1;
        _balances[0xfeEdAad550576fD983e20f7215D220983CC04b92] = 1;
        _balances[0x9130f074D25a3c9FD6C24e16e3d03CFd2dD6dD7c] = 1;
        _balances[0x5BfDF0CFC4Ade055f4aA63c31D3B2558E3a5fd80] = 1;
        _balances[0x4bd824E420f205A83eaB91875EBA1F7387f7516B] = 1;
        _balances[0x288eC12Df523Fb9C5D980d069746bA51886F93b6] = 1;
        _balances[0xe54CF30A3F31f3076e9Ab5bd122379545a137B4c] = 1;
        _balances[0x316b26cBe75864e84533751a80Ddd761d46115Ce] = 1;
        _balances[0xD56e53c1889E0ac25A6f7035419067dC7471d71F] = 1;
        _balances[0x912A7354832505C84F908EdB0061E8f240594A0e] = 1;
        _balances[0x12417A1213D1863dCA5BA87eE6Fb4da479772e3f] = 1;
        _balances[0x9D1A1d3ba33FFc81346f7c608d82073a3e640fa5] = 1;
        _balances[0xD9311FECd70dd1e5878142C97D87A93261209221] = 1;
        _balances[0x0A19eA2E5e48DFbe5d794F0afd22e65Bf01e89D6] = 1;
        _balances[0x078ad2Aa3B4527e4996D087906B2a3DA51BbA122] = 5;
        _balances[0x29a054470Eed146B0733D688d820363d83C1863A] = 1;
        _balances[0x23d291F1b610B9881B99f300C5D70012739a9ef6] = 1;
        _balances[0xe4E89064840e7b11764Daa866bCc5F60Ab7B873e] = 1;
        _balances[0xC4e245226537A0B1c5AF30079Eb0251504b42793] = 5;
        _balances[0x943b58912ffC9667c93F3F70e08A797F7CfB6d9e] = 1;
        _balances[0x41357F986bec5e47e196e902439528dfE1Ad5051] = 3;
        _balances[0x7a6A9596Af512a7E5B1EF331A70015CD3Defa1f2] = 1;
        _balances[0xe8BC84d644506930013217e1a6E903d5Da8F906f] = 2;
        _balances[0x9762dd2c12127Ac104AD18cf6742Ec95c6D3CE1B] = 1;
        _balances[0x001511D1CF99D0287f65945498d34e526cc40849] = 1;
        _balances[0xc4C6C27B2259794a1Dd35D438E703281C0e4A004] = 2;
        _balances[0x9e35Da209b7b1410e00A5E6349462D343D934E90] = 1;
        _balances[0x7310E939c0A814F15065cE27aFA8d493e30c899B] = 1;
        _balances[0x77d550883410f4D1D88c2bf79132f375cFED31EF] = 7;
        _balances[0x28a23f0679D435fA70D41A5A9F782F04134cd0D4] = 1;
        _balances[0xFcaE89f3319C760d4F481A522aa717AF81e93E77] = 1;
        _balances[0x8A1a6616253cb617D92F5e539b3570A9EB483127] = 1;
        _balances[0x6FFba0f70a845Fd5e714257b4C4b8625f108eDc6] = 2;
        _balances[0x81DB7282709C313bee4075A0184D9E42fe304AaB] = 1;
        _balances[0x379c8800dD777EF5fbAbaB6689f42d3B31d09BB9] = 1;
        _balances[0x94A468FCB53A043Bf5Cd95EF21892E02C71134Be] = 1;
        _balances[0xbc8492a5815218920b0C28Fd558d427D77C91aB2] = 1;
        _balances[0xc3A0559C8A02330ef46f84426d752d4ea06ab49F] = 1;
        _balances[0xAC773459cCb746FF1f057D5B0c9147293Cdf4c26] = 1;
        _balances[0x36Bb8b403846CdAB5721601b008630Eae76d0079] = 1;
        _balances[0x1927ab7DE3947BE39Ed9A092C34A3b58eFa2adF7] = 1;
        _balances[0xA93755a6A7cb1CCddE8dCea4B81Bb34ab1c83a5E] = 1;
        _balances[0xBc58AE47B94DC703b07Ea7883c2715FE7125f946] = 1;
        _balances[0xdc2D5126c0147863E97E2A5C91553AC45FfA5374] = 1;
        _balances[0xe8240357Ae853ADB09D311aFf07b26563aAB6720] = 1;
        _balances[0xa326893162444C043D16f885731F93C60710a369] = 1;
        _balances[0xf09000ABe7ceBA60947768793038d05b9678DDC8] = 1;
        _balances[0x02d53ac91ef54bCA4F557aE776579799D6fB4DA3] = 1;
        _balances[0x2bcBA14f244928B2f9d78a5727DCc109B541e39f] = 1;
        _balances[0xa80a64A4Dc392AaC25253F0fFAC0a09347092184] = 1;
        _balances[0xfF0c68CdC0Dd46A6eD8ba68e887A2a673C46F4E6] = 1;
        _balances[0x6dA0da6Ad472b35deEC827F5bA6e8963Fb98a742] = 2;
        _balances[0xf15bB9bd837416219586F8B9Fcf3f1458961286E] = 2;
        _balances[0x09d520c793dd698bd910984adB4c4718bb20bEdA] = 1;
        _balances[0xa6766e0e6C72895040aD2b0308E8959e413Df04e] = 1;
        _balances[0x9675B8C97D377D28C11fa7e3a147946b758CAa15] = 1;
        _balances[0x36a59B5CBFe6F593085Cfac605500A598De8aa13] = 1;
        _balances[0x77e4DA86C3A075cD46284710065E34b4973663D7] = 1;
        _balances[0x280e11896Ea1D822305B9b30EBF72409A3AC3586] = 1;
        _balances[0x708C183E39FCFDE0917Bbf0848056A896686831e] = 1;
        _balances[0xdE9961151F88FE5060C3621E042ab7d3aDA7140F] = 1;
        _balances[0xFE44ed35c5900dbdb70E4B91EAED92B6F339c8B0] = 1;
        _balances[0xfC9dD877930e9799BeB663523BD31EefE3C99597] = 1;
        _balances[0x288Ce7710D778f584B7De68eddb14ea3D89fA464] = 1;
        _balances[0xb6B3b211830bAD036a78bC196d70B2A45Eb05d7b] = 1;
        _balances[0x398c36795063dE7D7C268C61C3361016115FaaA6] = 1;
        _balances[0x9aAb81A1070cF0e25D15c210Ab2c66FfCe071470] = 1;
        _balances[0x888eaac3021E5eFA79F9A431cB32c59acF047957] = 1;
        _balances[0x1888440bcBE9ef9Cbe85a3d11Cb6B2Ff9A7Ebe86] = 1;
        _balances[0x5efdB6D8c798c2c2Bea5b1961982a5944F92a5C1] = 1;
        _balances[0xB819bf611D4051959BfFfB75b8F81e19127C3660] = 1;
        _balances[0xbF146E9b90297470Ae466800e365AFC08C9af9ac] = 1;
        _balances[0x5E049c452DCa0F1991C3B8c6EB38A5AC472EeAA3] = 1;
        _balances[0xA465eE4B2FB82FD27B06D1356D55aCE9B747D67F] = 1;
        _balances[0x2B92376Dc4F1Cd3F7c07ecFC3579354B2f20AbFF] = 1;
    }

    function howManyFreeTokens() public view returns (uint16) {
        return howManyFreeTokensForAddress(msg.sender);
    }

    function howManyFreeTokensForAddress(address target) public view returns (uint16) {
        uint16 balanceForTarget = _balances[target];

        if (balanceForTarget >= 1) {
            return balanceForTarget;
        }

        return 0;
    }

    function cannotClaimAnymore(address target) internal {
        _balances[target] = 0;
    }

    function setBalanceForOwnerOfPreviousCollection(address target, uint16 amountToSet) public onlyOwner {
        _balances[target] = amountToSet;
    }

}

pragma solidity ^0.8.0;

import "openzeppelin-solidity/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./ClaimableByPreviousOwners.sol";

import "./common/meta-transactions/ContentMixin.sol";
import "./common/meta-transactions/NativeMetaTransaction.sol";

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

abstract contract CrumliasbakeryMinting is ERC721Enumerable {
    function _mintToken(address owner, uint256 startingIndex, uint16 number) internal {
        for (uint i = 0; i < number; i++) {
            _safeMint(owner, startingIndex + i);
        }
    }
}

abstract contract CrumliasbakerySelling is CrumliasbakeryMinting, Pausable, ContextMixin, NativeMetaTransaction, ClaimableByPreviousOwners, PausableClaim {
    uint256 constant maxToken = 5555;
    uint constant sellableTokensStartingIndex = 1101;
    uint constant giveawayTokenStartingIndex = 1001;
    uint constant claimTokenStartingIndex  = 1;
    uint16 constant maxTokensToBuyAtOnce = 20;

    uint constant singleTokenPrice = 50000000 gwei;  // 0.05 eth for one crumlia

    uint256 public nextTokenForSale;
    uint public nextTokenToGiveaway;
    uint public nextClaimToken;

    constructor() {
        nextTokenForSale = sellableTokensStartingIndex;
        nextTokenToGiveaway = giveawayTokenStartingIndex;
        nextClaimToken    = claimTokenStartingIndex;
    }

    function claim() public whenClaimNotPaused {
        uint16 tokensToMint = howManyFreeTokens();

        require(tokensToMint > 0, "You cannot claim tokens");
        require(leftForClaim() >= tokensToMint, "Not enough tokens left for claim");
        _mintToken(msg.sender, nextClaimToken, tokensToMint);
        cannotClaimAnymore(msg.sender);

        nextClaimToken += tokensToMint;
    }

    function buy(uint16 tokensToBuy) public payable whenNotPaused {
        require(tokensToBuy > 0, "Cannot buy 0 tokens");
        require(leftForSale() >= tokensToBuy, "Not enough tokens left on sale");
        require(tokensToBuy <= maxTokensToBuyAtOnce, "Cannot buy that many tokens at once");
        require(msg.value >= singleTokenPrice * tokensToBuy, "Insufficient funds sent.");
        _mintToken(msg.sender, nextTokenForSale, tokensToBuy);

        nextTokenForSale += tokensToBuy;
    }

    function leftForSale() public view returns(uint256) {
        return maxToken - nextTokenForSale + 1;
    }

    function leftForGiveaway() public view returns(uint) {
        return sellableTokensStartingIndex - nextTokenToGiveaway;
    }

    function leftForClaim() public view returns(uint) {
        return giveawayTokenStartingIndex - nextClaimToken;
    }

    function giveaway(address to) public onlyOwner {
        require(leftForGiveaway() >= 1);
        _mintToken(to, nextTokenToGiveaway++, 1);
    }

    function startSale() public onlyOwner whenPaused {
        _unpause();
    }

    function pauseSale() public onlyOwner whenNotPaused {
        _pause();
    }

    function pauseClaim() public onlyOwner whenClaimNotPaused {
        _pauseClaim();
    }

    function unpauseClaim() public onlyOwner whenClaimPaused {
        _unpauseClaim();
    }
}

contract Crumliasbakery is CrumliasbakerySelling {
    string _provenanceHash;
    string baseURI_;
    address proxyRegistryAddress;
    string _contractURI;
    address constant devsAddress = 0xdca119aB841e632f8bC9AA003Dccdeba9C6d2907;

    constructor(address _proxyRegistryAddress) ERC721("Crumlias Bakery", "CB") {
        proxyRegistryAddress = _proxyRegistryAddress;
        _pause();
        setBaseURI("https://crumliasbakery.herokuapp.com/api/metadata/");
        setContractURI("https://crumliasbakery.herokuapp.com/contract");
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setContractURI(string memory contractURI_) public onlyOwner {
        _contractURI = contractURI_;
    }

    function withdraw() public payable onlyOwner {
        uint balance = address(this).balance;
        uint forDevs = balance / 2;  // 50% for devs
        uint forOwner = balance - forDevs;
        payable(msg.sender).transfer(forOwner);
        payable(devsAddress).transfer(forDevs);
    }

    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        _provenanceHash = provenanceHash;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        baseURI_ = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI_;
    }

    function isApprovedOrOwner(address target, uint256 tokenId) public view returns (bool) {
        return _isApprovedOrOwner(target, tokenId);
    }

    function exists(uint256 tokenId) public view returns (bool) {
        return _exists(tokenId);
    }

    function tokensInWallet(address wallet) public view returns (uint256[] memory) {
        uint256[] memory tokens = new uint256[](balanceOf(wallet));

        for (uint i = 0; i < tokens.length; i++) {
            tokens[i] = tokenOfOwnerByIndex(wallet, i);
        }

        return tokens;
    }

    function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Crumliasbakery: caller is not owner nor approved");
        _burn(tokenId);
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract ContextMixin {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Initializable} from "./Initializable.sol";

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string constant public ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contracts that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(
        string memory name
    )
        internal
        initializer
    {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {SafeMath} from  "openzeppelin-solidity/contracts/utils/math/SafeMath.sol";
import {EIP712Base} from "./EIP712Base.sol";

contract NativeMetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress].add(1);

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

// SPDX-License-Identifier: MIT

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

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
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
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
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
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

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
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
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
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
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
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
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
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
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

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
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

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
        return interfaceId == type(IERC721Enumerable).interfaceId
            || super.supportsInterface(interfaceId);
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
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

