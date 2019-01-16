pragma solidity ^0.4.21;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public;
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
}

contract KNBaseToken is ERC20 {
    using SafeMath for uint256;
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 totalSupply_;

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) internal allowed;

    constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply) public{
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply_ = _totalSupply;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function _transfer(address _from, address _to, uint256 _value) internal {
        require(_to != address(0));
        require(balances[_from] >= _value);
        require(balances[_to].add(_value) > balances[_to]);


        uint256 previousBalances = balances[_from].add(balances[_to]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);

        assert(balances[_from].add(balances[_to]) == previousBalances);
    }

    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_value <= allowed[_from][msg.sender]);     // Check allowance
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balances[_from] >= _value);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(msg.sender, _value);
        return true;
    }
}

contract KnowToken is KNBaseToken, Ownable {

    uint256 internal privateToken = 389774115000000000000000000;
    uint256 internal preSaleToken = 1169322346000000000000000000;
    uint256 internal crowdSaleToken = 3897741155000000000000000000;
    uint256 internal bountyToken;
    uint256 internal foundationToken;
    address public founderAddress;
    bool public unlockAllTokens;

    mapping (address => bool) public frozenAccount;

    event FrozenFunds(address target, bool unfrozen);
    event UnLockAllTokens(bool unlock);

    constructor() public {
        founderAddress = msg.sender;
        balances[founderAddress] = totalSupply_;
        emit Transfer(address(0), founderAddress, totalSupply_);
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != address(0));                               
        require (balances[_from] >= _value);               
        require (balances[_to].add(_value) >= balances[_to]); 
        require(!frozenAccount[_from] || unlockAllTokens);

        balances[_from] = balances[_from].sub(_value);                  
        balances[_to] = balances[_to].add(_value);                  
        emit Transfer(_from, _to, _value);
    }

    function unlockAllTokens(bool _unlock) public onlyOwner {
        unlockAllTokens = _unlock;
        emit UnLockAllTokens(_unlock);
    }

    function freezeAccount(address target, bool freeze) public onlyOwner {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
}

contract BountyKN is Ownable{
    using SafeMath for uint256;

    KnowToken public token;
    mapping(address => uint256) tokens;

    constructor() public {
        token = KnowToken(0x82d987E8c27DB4a75Dd22D770335a5E5435252CD);// address of KN Token
        tokens[address(0xE3e303ad0D9B97083365B07Ce7f964893c7B20aC)] = 1000;
        tokens[address(0x11518846DE0b4fd57875C284ff382D9d34d5Da2e)] = 1000;
        tokens[address(0xf10bCED548DAbAFd32A1cDf78919a90D45D0fd80)] = 900;
        tokens[address(0x9e158D913462eB21A301cE4259a9B62B592A45DC)] = 5100;
        tokens[address(0xED61184e80BFDEcB1f7B557c42D954Ed2A12DA97)] = 600;
        tokens[address(0xbC5a62b53A8470b4E9e473C6D8D5018f17217953)] = 13300;  
        tokens[address(0x440e9bDDAE3D55E5545dde6Be6e7781918651061)] = 3100;
        tokens[address(0x8915C3d2392A8F0eb60Dc0D61011E5F55AfE3571)] = 13600;
        tokens[address(0xBF5B7E163d6cA81BC12bf346e8eA518310444EB9)] = 2600;
        tokens[address(0xe1A7Bd4D6942be67D07bD2de4de5BF51829eC61E)] = 8100;
        tokens[address(0xBE28D4DaFa4ec5FC83D555bf142aAb1e9c4fcc9F)] = 23600;
        tokens[address(0x9D83c58297b6307a4C62830EFE16dA9470990F7A)] = 1900;
        tokens[address(0xaa482BD8fCd04aac773100b458C83D1249Dc5831)] = 2100;
        tokens[address(0x8AAd2C2884378EC1194D94EDfE9387756510824f)] = 19600;
        tokens[address(0x5ec4ce915D7638e71F358902977a4d34C44e0CD7)] = 2100;
        tokens[address(0xe68F27D6eba39daA24ABd773Ba71F9b296B950e2)] = 3400;
        tokens[address(0x6C74ef93630491eBD785AcA34e98DE6f74A683aC)] = 6700;
        tokens[address(0x86A6EbA0d5e8adCfA4D7918287d72Daf01ADE28b)] = 1600;
        tokens[address(0xBA7AD4A74Aa422ef25dBB88e800bbE9ECc8e793c)] = 800;
        tokens[address(0x14491F85590a43C8B29408007bDd427F4b7989a7)] = 4300;
        tokens[address(0xe9f9B4dC07d33C4509DB499155fACF4c807267f9)] = 3700;
        tokens[address(0x46F296807D4D04497AaaA84170a8Fd45B7D1ca1d)] = 4100;
        tokens[address(0xF8d69cB8df5562f1ea2De62c74Bae7E9A4Cf946c)] = 3500;
        tokens[address(0xD5f652068F02A91D0Ee5cbc8C226aF61Cb76efbC)] = 2100;
        tokens[address(0xCC272D5De4C687BeAFfB86FA554dFb6ee29E1d85)] = 21600;
        tokens[address(0xfCC6CDe55A7B62A7CD464064e060528dc84C90C4)] = 3900;
        tokens[address(0xDF1d7dd15f967dcC0444a04F5d75585b560c6783)] = 1800;
        tokens[address(0x50F83EA7da0f40E94ff17a17568D4bC608Cc0120)] = 1500;
        tokens[address(0x92dBa72D84052Fb1200dC5041FadE0E33938747f)] = 1900;
        tokens[address(0x37312AE82E1e6720f09055828E08D1dB877e55cA)] = 1100;
        tokens[address(0xAa53a9229FEa3713AB290ff2223DB2524Ad10497)] = 23700;
        tokens[address(0xcdC9A8d3F2270E08faE235b295100546eCCe2f0e)] = 1900;
        tokens[address(0x8BFda8413056ce28c99D03C18eb63959B34aC141)] = 10135;
        tokens[address(0x58aD3F106C64016D21b0Fdd56e4Bc5BC516199D3)] = 13100;
        tokens[address(0x6E1c50D5C1e4e77233673FaEEE3F77e299c2fE39)] = 2300;
        tokens[address(0xF5ec249FF3871aF4f8a051c6e07AcE99AB6A1922)] = 1400;
        tokens[address(0xD071e50Ef1aE68c6FDe8c72e78F824514feE4613)] = 2400;
        tokens[address(0xd30BCBd1cA646FCA8f1282BEf879E025BCb6F560)] = 2300;
        tokens[address(0xd442F3780f540F3ea97153C5b999B9fe9EBd9c71)] = 2800;
        tokens[address(0x6F63009e2d31dF1f6Ef431D574894E545f40e223)] = 900;
        tokens[address(0x27047d2eFB881649102E29EAf64eA0FDDf110E4B)] = 7800;
        tokens[address(0x41f8145E60E771693B0b32246e9fB4e278e3B270)] = 12800;
        tokens[address(0xf8203E1A90dEfD0cEa26A84632144787Fe60E55B)] = 1400;
        tokens[address(0x5A937D89D9ff4f1c43684Fc4f9Bbb8E85496D982)] = 1200;
        tokens[address(0x323eCbd99857C19be94d7F7D7662AF840F5Ff6A5)] = 1700;
        tokens[address(0xd5D14CF1c26f78De45B58776cF5F64DbF86a722C)] = 10500; 
        tokens[address(0xB01972DFC6bbCAD5584271EB1D9DbCd0721d2639)] = 17600;
        tokens[address(0xB6170C9d9A879e9B7958cc24c69b8E1dafFE33bb)] = 82900;
        tokens[address(0x0b1970Bc7030E0aE254a34228b613F30F710fD75)] = 3600;
        tokens[address(0xf987C20a0392AE99e836D146C08e55FE7130aC7c)] = 1600;
        tokens[address(0xcfaA032D070587b011d7627f5F7078368727a961)] = 1200;
        tokens[address(0x5cd1eb910e2779e24A009a8a6A609334fd49C9c9)] = 2100;
        tokens[address(0x38512f18C16d0499d9ae5f30f50b9292F044eB39)] = 1100;
        tokens[address(0xc82941abd40390E69007035fA99d5Ba65FAc5044)] = 3100;
        tokens[address(0xDEb4536Cf17070Dd79A853891857206b22Beb05C)] = 3100;
        tokens[address(0x778f68923f1F2a40117B3dB98083851c5d2e37ef)] = 2600;
        tokens[address(0x71Dea26B2EEB48B8c049964DC10Ed82B1EF0dD20)] = 2100;
        tokens[address(0x2a2D2A3C8D45e3Dd238dcC7C17e143a722218D95)] = 2100;
        tokens[address(0x83505B80ED8E7c15BD20B0A3A552c5d27EFF0C76)] = 2100;
        tokens[address(0x558249A9532a8665cf4bBA6645a74Fe69a917552)] = 1200;
        tokens[address(0xE8DF61368AEc385fbe89d26A47C984f24a480EeD)] = 900;
        tokens[address(0x298acc69206065C929594C270963013180B6823f)] = 4000;
        tokens[address(0x8D3E06145f5BA879b6CF82F06D15eA329154C979)] = 1500;
        tokens[address(0x86341Be59A39daCc60201dC78c247De4bB099891)] = 1900;
        tokens[address(0x0D554C6ee2a2f31441080f23ba6D36B845949d23)] = 21600; 
        tokens[address(0x985995E7e78723194064AeF580d6D2B850463EC8)] = 2400;
        tokens[address(0x8726e4753651Ed6206B459d592A37fF914ff0b1b)] = 4200;
        tokens[address(0x07D33791A5119D3095BAA1163040BbcAda871CF1)] = 2100;
        tokens[address(0xD1C1F4cb95A99c7c596e73bE62a2FBcF73AB6Cb6)] = 2100;
        tokens[address(0xa9392a9D02331c8C79DD381f1FAe0bE57fcb1192)] = 600;
        tokens[address(0x78E86dCAF7452787AC2cE12cC69F3Fe3F0201E32)] = 3100;
        tokens[address(0x63A690a115833Cc38451FBC8552d72cf8C5b0461)] = 5000;
        tokens[address(0x1C0a7ED85ec2Ff34F1a2Ff000B95db32895a2aEc)] = 2900;
        tokens[address(0xb7fECd21C4d236060e20FF87907dA613d7fb3d7b)] = 6600;
        tokens[address(0xc4415A2e76b282bE9C02BFE4818c793ed540a7e6)] = 2200;
        tokens[address(0x84E7Eb8033907cbD8Fd9f72a724eA838e1459897)] = 2600;
        tokens[address(0x62D84D039AD9CFdC9e2383A2B536f4eCb98ccf38)] = 600;
        tokens[address(0xb3B9Bb62E31549c1ce1aF76624242da2b2c23C8d)] = 6100;
        tokens[address(0x98Bc47546Ab7336A8B6e57bceb690752890e6460)] = 5700;
        tokens[address(0x5eEB3452Ed391a4f6054986401c85f2fbe041a63)] = 1500; 
        tokens[address(0x3916cE72F7b90883eDc484e1955Dd52d6798441F)] = 1600;
        tokens[address(0xD0496f389cF4187f23E8D16F0EC20d2EFe5E8113)] = 7400;
        tokens[address(0x88b3D8fCd43D2492399859067478e77D82B08b4F)] = 4400;
        tokens[address(0xa3cCdf76f19DCe3b69E7033d624a00d4eEc9635E)] = 2200;
        tokens[address(0xC5c0188D0c52A7BA02429D822C2641d816A2e090)] = 4500;
        tokens[address(0xAE83b2057F91167640af2933BC75877B7FBdf800)] = 600;
        tokens[address(0xbF376e8182AbD4C3D939b31a1De70BdccE0cbF29)] = 16700;
        tokens[address(0x24756e1BEc9a789E7977FECAaaC3A31d3589619e)] = 8100; 
        tokens[address(0x1b8f93901dE3b353B12D327B68D8E1806B25Af65)] = 1200;
        tokens[address(0x228f9c5e48Dd0B99d96AA27a04066664E4ae6aA7)] = 12100;
        tokens[address(0x4c9d6DB3e0B08ef346BeF080D2e1e05f70F919D0)] = 1300;
        tokens[address(0x1a9218D7151579f57EBf86D80cde8981bC3A6960)] = 12700;
        tokens[address(0x115E9308032dD8a7a647838f7FB5c4A5EC552432)] = 2335; 
        tokens[address(0x8e37Db3979B6d490d2aEC1F2609bCD2a1ee9721e)] = 2000;
        tokens[address(0x469F2Ec13B4f159C2fC65d1268376aB1087f3e54)] = 2700;
        tokens[address(0xC4Be8FD7826fD63aE3fd9b4493327C492690D747)] = 1900;
        tokens[address(0x2401Ad256bCD3a66BfB68Cb4D9DE5e297eC1b091)] = 4500; 
        tokens[address(0x934996e684D8c4EaD6D913d2b9ce6174e58CEd1A)] = 1700;
        tokens[address(0xFEeea46C35D1305cfcD6d73b7688896BB952a97b)] = 9500;
        tokens[address(0x7B6CE51816C04eBaDe05d59478603B02931005A6)] = 7600;
        tokens[address(0x964c52cC9e83249a273e7ea7D9bCA7C12a8C9fB8)] = 1200;
        tokens[address(0xbD5497D6A4E149F8555E23786eA228c401897b73)] = 32100;
        tokens[address(0x4B70f238678E4a2b061bbFdc57bd118C6979955d)] = 12100;
        tokens[address(0x953af5FAeb53d3e8Ad1b29d5f6D4bB30a22eFB5C)] = 1100;
        tokens[address(0x211E07dfC428AB92c15Ef77EdC0dB6B760448957)] = 3700;
        tokens[address(0x8De7f22EA8Da641D2D6130A011a04CCabdBA0Bf8)] = 17400;
        tokens[address(0xe07a986b3A99a215C3BF1a06f86C6b183111b199)] = 2100;
        tokens[address(0x5eD2fB840B7F6402B49Fe0C92087E6c11A6e3bB6)] = 2800;  
        tokens[address(0xC7C27359a6a46196A464259451342b6d2E344724)] = 2600;
        tokens[address(0x360cc28b20B4114B394398f1B671F4eD03B7Ad96)] = 6300;
        tokens[address(0x64497911EAcD46C3B27Ab43c5F795f9c0E51e4Fe)] = 2400;
        tokens[address(0x358f20e9D04fdB670749D36BAd55Cd6147D08270)] = 2100;
        tokens[address(0x0BD3Ddc696a5aF198C1A2fee125Aa86698cc74Ef)] = 2000;
        tokens[address(0x99E8C8c1148866444a84529DB76e28644caAea7A)] = 14600;
        tokens[address(0xB3A1313a9F85f4ad0c5D95E5558A0DFd8a2cc09E)] = 1600;
        tokens[address(0x2B1bf14f77703E9e8191e7C3f4F02ca9da47744C)] = 1200;
        tokens[address(0x5BFbf5A2611d76377353e44AC7CB0f3db307eE92)] = 1900;
        tokens[address(0xE7DE93F9D4B2CF54c09dccEe4c37Ac4900dDc99F)] = 84400;
        tokens[address(0xbc9354b890F524b31eedaD36c162b2a5D5290119)] = 5700;
        tokens[address(0x10f19342Fa7e60091e41e5370a80A1a44634C717)] = 3100;
        tokens[address(0x7A335874A722eb5a8b8172f1e603de6A2C3397bc)] = 1400;
        tokens[address(0x46b66E2857056024DFf5c872F3d2E758F2Ae3275)] = 3100;
        tokens[address(0xa34F7Dfe09448f05547676E3a0911cC966237c1C)] = 2100;
        tokens[address(0xDe9E459CD76f66E7465DF8333177207E50D127e9)] = 3200; 
        tokens[address(0xF7DE7Fa2bfD8570a74FB70049227BB38b48ccB43)] = 1400;
        tokens[address(0x61161EdC78A9835cD27E5d3aDDB875A7a107efF1)] = 18600;
        tokens[address(0x9064Cca032E89C901699e6469D1b63496266F9c5)] = 1600;
        tokens[address(0x0eEf075FA359C47C9c2f06477e9d4719a2f5ddA8)] = 11900;
        tokens[address(0x3Fd548d4BA96452E6c33A5d6492d321E80f4734e)] = 1300;
        tokens[address(0x450a9939161fe971D0fA6629934DE9aA62035A0a)] = 2000;
        tokens[address(0xFA558Cc3eE49A1Db69B8168a98A5fFc8bEceD3d5)] = 900;
        tokens[address(0x404Be73d9A891cBe3f7009e887378C7eD8262F0a)] = 1700;
        tokens[address(0x8C255Dd8aa814167b0663478114De8F5E83fD87A)] = 4100;
        tokens[address(0xC125FfB2b95224cf3cbdB8600C0EEBf4DE199265)] = 4100;
        tokens[address(0x5F307044d99507FC86AecDf1881Dd4781eB661C2)] = 11000;
        tokens[address(0xC974f617132b5fD0cD1FB1eD04a34bD4283171aB)] = 51800;
        tokens[address(0x44494EeeE8C726a2Bce19a289d21c2a6d144eD1A)] = 2500;
        tokens[address(0xB7077251cfD03B188e4BDB97435763f428EAB27f)] = 5300;
        tokens[address(0xb9850833513983c59639008Ee7B1E301ebC34081)] = 5500;
        tokens[address(0x76df9BF502b011feB06AF99086424430526Bd41d)] = 1900;
        tokens[address(0xb38EB6860470bBf6B778Fa9c2bcbe3cE5dA3089b)] = 1300;
        tokens[address(0x3458De0096fFd750EeF057347D02cc695Dde2673)] = 3900;
        tokens[address(0x5395c388C9139fb03019CCA7469BbB57B5613E7B)] = 2100;
        tokens[address(0x10Dfcf227e7e8bBCaBC3c522E0665ABa928368F9)] = 4200;
        tokens[address(0xeb85F3D6bDcAa47f99F1F3356771DB00612B2DDe)] = 3900;
        tokens[address(0xD67807340F51e2a128268FF2562063D4b17aBB28)] = 3300;
        tokens[address(0xBAD31725558c770BD5192E1e0DC7916E31A809CA)] = 7300;
        tokens[address(0x113995Fd378B089886E0A106E297688449288a62)] = 19900;
        tokens[address(0x7282175B14e50785A896d8c1F5Bd3b59806122f2)] = 2100;
        tokens[address(0xA72D2997B805465E780C2D2F0f24393CFC4c939c)] = 14100;
        tokens[address(0xA1d54dE31e5b3a2994fc09BD6F9Bc413e49D0130)] = 4500;
        tokens[address(0xe0E36a2d4Ca7c083Ef227D4cD386C83030Dac094)] = 1900;
        tokens[address(0xce00B08CfEA7aE7CD0b90a0e4647CC3b45b16c15)] = 1900;
        tokens[address(0x2e36Eb01f6753a4e63dd738E254e8915bdd756A2)] = 1600;
        tokens[address(0x1a3Df37a39bEFa5249cA2222b048a5cCf708F2C9)] = 3600;
        tokens[address(0xD7A78bcc6d0aE44A08C8E9926549b5CC44E27C91)] = 3700;
        tokens[address(0xa335175a42939176106A4d6D5D2277F8302f4a98)] = 19900;
        tokens[address(0xCdcd4b05149EC85d20716E8011BD09Dee74a3CC4)] = 3800; 
        tokens[address(0x19118d1C44210E2d341B56F93c642f2B26C852d4)] = 2200;
        tokens[address(0xa5D3757B0f45cC2a1fE8EF763b48b10E68160e24)] = 10800;
        tokens[address(0x7cd823Dc6558079D52D0fdb3baDf01D20057f096)] = 16900;
        tokens[address(0x9867Bcf27d7B4b804caD85A665A7e7A269CF8c58)] = 2700;
        tokens[address(0x2864d73100bE89bC630405d3f8DC04e5a589B88f)] = 2100;
        tokens[address(0xE8B8f787e0D1139Ee1E57a1c6908a09a49614528)] = 4300;
        tokens[address(0xb1016aD5e413423703053F32bac838C4c6821422)] = 2600;
        tokens[address(0x82D7732b45090416f5381A3401da40BcaA3f6572)] = 2800;
        tokens[address(0x95e5D4C98F3627Fd6764cBf3997c85c7f6cc91C1)] = 2700;
        tokens[address(0x43257F6a4CFdc152AcF5856302d3E49d63485508)] = 4100;
        tokens[address(0xf12b493ff9c9bfF4ceBa8f006b0dEDB0D4A26f34)] = 3700;
        tokens[address(0x95C95931E4ed2722a5A60BAaB647083F5F58f403)] = 2300;
        tokens[address(0x8B15E621E09cF15E1d7B3573339b485b6b75da9F)] = 2600;
        tokens[address(0xD26205A544EC45d8611DF4D3f22b1b3ec43B3802)] = 52700;
        tokens[address(0xA56FE8f2704aE10668e71106F5f21BCd5bAdc37F)] = 21000;
        tokens[address(0x5F7A9C0C9796221f294eF34e9B6cC855152ed6e7)] = 5400;
        tokens[address(0xfA0E97374b3252d845d6d1Abf9d2Be6e7115B78F)] = 900;
        tokens[address(0x10eE0069d5a7B6Cc8f3A54fb425F22F2dD77D685)] = 1700;
        tokens[address(0x1239F4aE845Ee39D0053DF9E6AA8b31FDf233a1A)] = 1900;
        tokens[address(0xbEb19b742Ae4Efa18C9115E149fde9aDf2E557B1)] = 22400;
        tokens[address(0x57829e2Ceb12b86130bCEB14415Ab263bCA03d08)] = 2100;
        tokens[address(0x6Ec23C3b03C30477e0306d812f78cC3E176aAF37)] = 1600;
        tokens[address(0xAad00CaF7c7C5305692777b9E224411B017F58ea)] = 600;
        tokens[address(0xf51621c94F027fA5464D730FCC9AFA27A80b6ABe)] = 600;
        tokens[address(0x2F05cBc986E0555CbE381E3850e3CD70b3e2CC75)] = 2600;
        tokens[address(0x8f27680e786F0BA025d001Bf80cA88C79A48a7F4)] = 13535;
        tokens[address(0x9F2046668FCE6dA462de54a0690eAb7581AB4Df1)] = 7500;
        tokens[address(0x789cF264621F1504475BB29315456a1a02977176)] = 4300;
        tokens[address(0x87c2E6D8B2393D77cE6f219D4668E1E256c89538)] = 8700;
        tokens[address(0x31C324a698A9F6bd915605A7321F0a337fF46b7A)] = 4300;
        tokens[address(0x2a3B2C39AE3958B875033349fd573eD14886C2Ee)] = 3400;
        tokens[address(0x884423E02DB1b3716E3c8014e871b7Fe3d3e224B)] = 2400; 
        tokens[address(0x387dC59d381E7fc4de7DC92A0118379A4a1f59cC)] = 1200;
        tokens[address(0x7b249dE6D98D83172E1189764330dB7484EAe568)] = 2400;
        tokens[address(0xcBC204317bF6dC59f933E87A309A2C4C5B419DAa)] = 5900;
        tokens[address(0x96911381C616165CEDF1Ca453a82357586C6fEab)] = 700;
        tokens[address(0x1D19fd2ED78F0312ec043eC381651770c0BdeB6F)] = 43000;
        tokens[address(0x3881e0973CD7C73965c3b90b7B71832c33323A66)] = 7600;
        tokens[address(0xC1F681c33345dD23EfA55ff6167C48E77F0Af369)] = 7400;
        tokens[address(0x255718C5781727e78ebb540a39b78A7DBe3b31ee)] = 5900;
        tokens[address(0x6380D625d56d60A152E8210CE64B376a82E19515)] = 2600;
        tokens[address(0x2846B2E0519Ccf873F73d086d9940B6Ddf54C862)] = 1700;
        tokens[address(0xa136D3F79EC445d749d3905702CaC790C79046E1)] = 9100;
        tokens[address(0x737b7905193FCFA28fCa1eF1581D959689eabea7)] = 1600;
        tokens[address(0x9B2ff7Fa5c2eDdfE7F4447779d73Ac9E8cF2702b)] = 2500;
        tokens[address(0xb3e81CeFc03aB9ba6Bb2FC0D8796001f3c4F668b)] = 4600;
        tokens[address(0x37DFCA4a5e34858D3Ad2E4D8B4DF179e197DA12B)] = 2800;
        tokens[address(0x28501F8DeA62d29fF5ee7553E0840d171C17bFad)] = 22600;
        tokens[address(0x7C689faae031DDBbe3B53b44678B0855DB028ff6)] = 3100;
        tokens[address(0xeDe71D58Eb92c4Eb065d2709a08970f789e7084b)] = 37000;
        tokens[address(0xAa73C514E8775c14fc069Fc57a19557A37585FA2)] = 2300;
        tokens[address(0x35dE792964AE652F3076C77649B3e66db5cD36DB)] = 6500;
        tokens[address(0x88c6fbeF6C31A4d5059Eb5cc3daa0C9D2e22b872)] = 1600;
        tokens[address(0xd0f9728AF51D6D0470c5b8bFcC299615D494F423)] = 1700;
        tokens[address(0x75b3a2e6EaA23C552acfd871BC68C93bC798b4eA)] = 3600;
        tokens[address(0xf602EbC65dfa90f700855eEC1d488300f580ae15)] = 2000;
        tokens[address(0x4937dd2007211789C662EBFD3AE1AFe3bCc0f777)] = 13600;
        tokens[address(0x893C9C14d2839B187445b7491d1ad412EA08d611)] = 2900;
        tokens[address(0x2C718A349C229DEbc3fb87f2aa09D476C46C859D)] = 94700;
        tokens[address(0x2B48Afaf5ADBc8E479FE5514Ad45eBC39d0C59A3)] = 2700;
        tokens[address(0x5dbcB95364cBc5604BACBB8c6eB9aa788f347a17)] = 2300;
        tokens[address(0xd35500515aCBB2243294976C6bFB275F01DC8db4)] = 8000;
        tokens[address(0x11A069BA9FF2a7Ad9c08C248ad606931299dc855)] = 21700;
        tokens[address(0xb65EdFAC6AA7B9639186D10E1b2c6644Cda57Cfc)] = 3600;
        tokens[address(0x03BD847d4f5AEc969BB65FD7cc977243AF411d0F)] = 23800;
        tokens[address(0xb25d699090B2B3C14cFe6BF063A6f3C5D46e6eFD)] = 1900;
        tokens[address(0x08405F0Dee96534F9d9027146e64081DeebD806a)] = 1600;
        tokens[address(0x510314A66afd4cACb31C1583563bA3E6C4D02bd4)] = 3300;
        tokens[address(0x9609A918759f8B90030E5428461EF5F9fcF8Bde0)] = 2600;
        tokens[address(0x65e5e1D9f64fa113e6da2f90Cc6e733463A44922)] = 1600;
        tokens[address(0xAd53dB614fe9cFE9e88dD83eA82138a5932D168e)] = 6100;
        tokens[address(0x325f88Bc1c4eE067Ef5d171A775f84016CC30165)] = 2600;
        tokens[address(0x97aA828a1e96043f3108D8d685e67234cb759362)] = 7900;
        tokens[address(0xf39409683dFE85d15F9Ca34e577A7045766E6ba3)] = 2900;
        tokens[address(0x0008e2dEE5AeE2c2516212f86A029e3602f42dA4)] = 10100;
        tokens[address(0x05286706c1708BbcCe18FcB1e6a9270624880d57)] = 2100;
        tokens[address(0xBC0155D083DFFfa14734215a7e36Dd467c92d4E9)] = 5600;
        tokens[address(0x76F26Ed80a501643057CE99e53A7630fEfEb6aB2)] = 3100;
        tokens[address(0x29b0788dA95E388989b62a79043b32063E94F12c)] = 2900;
        tokens[address(0x33a16cC1dB6589E9Ca855E05321bC8ea536410a5)] = 1600;
        tokens[address(0x2382bC117F521eF09731Ab53f38534d4d23190CC)] = 4500;
        tokens[address(0xEa9db6E979aF5FBf9571c75182D37B5D42556C38)] = 4700;
        tokens[address(0x67b4D90Baa5BCd79B93FA465a65cB0f5b0c85738)] = 5600;
        tokens[address(0xA2248BB7551C7Fab900A08f8a4e900b3C6cF5185)] = 19100;
        tokens[address(0x9CaDC8955D21E0c52af38d67C482acDe645d3a3A)] = 22900;
        tokens[address(0x96F2659c257AaB31BdF19D2bA378FE83eccB6822)] = 31200;
        tokens[address(0xCF0E0DbedD605dC7ef21EC9290500634E79566E3)] = 1700;
        tokens[address(0xE114F8b15b6Ede03e3d3b8eC6637Be0050Eab553)] = 2200;
        tokens[address(0x681a19a96B8BE6dAFBfC89042CAd159E703A90e9)] = 10900;
        tokens[address(0xc23583B12AcF922226d458A74E6dd7723867982E)] = 1200;
        tokens[address(0xE10CE618839C7cc4589b66A543B165A9d2BCa600)] = 12100;
        tokens[address(0x260F20892f86D80115852188F8e090a4D344b656)] = 9900;
        tokens[address(0x9f403f79B35B60a2B577b13F75Fda5cB0bd2C174)] = 2100;
        tokens[address(0x8C056c3DDe853a7Ab91Cc368fDc123be9269E136)] = 4900;
        tokens[address(0xE7e07f085FD876d3619af686Dcb3a295778Bb01d)] = 12400;
        tokens[address(0x01F1be5A0a5256C2D420476D4913Ec57B5DAaa3a)] = 2800;
        tokens[address(0xe0706dC72D826c8f25A34bc7951Ac7D1b44D6D3d)] = 2200;
        tokens[address(0xac9e954fa28E2e2C0b1EE2a5E3AED527BBED4e1A)] = 4600;
        tokens[address(0x2997A6b3D503207e5365C8DD8Eb1B0c88d1c04DF)] = 1900; 
        tokens[address(0xCae2d6cE0F959dE16Dd5eEd8E0dC19a623F18B05)] = 1400;
        tokens[address(0x08A1F6543205e47CbDc52b8BC82cB8b9D070B714)] = 9800;
        tokens[address(0xd3dE61685BAa88Ed9b9dd6d96d1Ac4E6209669D5)] = 153200;
        tokens[address(0x9692BA810E150bC57AceDf0D809B9a9B7Cfd2324)] = 4100;
        tokens[address(0x7179B30E81B208e71493460b29746f2A804aDff3)] = 1800;
        tokens[address(0x78Cf6881770f82d5Bb424b2adCFaC94558a35Ca5)] = 1200;
        tokens[address(0x9725274C250ba4A1294ee21710ACF963d46FD65F)] = 8100;
        tokens[address(0xddB8e580939e1543dAA215B81B0b5A9E03407425)] = 2600;
        tokens[address(0xedEFcB98739C8641aB52d304573B245710094CF7)] = 1900;
        tokens[address(0x35facb385F5F916D419f68C2310b20d25a13623B)] = 12400;
        tokens[address(0xd7fD6851a34E60eBD472E13DBd7aC7BF70155a43)] = 22700;
        tokens[address(0x4eaf662967a924FdA63598d1FAdb9e023681769e)] = 1600;
        tokens[address(0xa25a3BEbB04DD5F87c5416a36C4c225AF06555ab)] = 3500;
        tokens[address(0x2cdcCec23A8EaB9eB00725868b8D29c6ca21505b)] = 2100;
        tokens[address(0x25D3fe656420Fbdd9587FbA30a7a23B0328Ab2C9)] = 1700;
        tokens[address(0xB656bb3D3F1aa4b34783d4983b53ca281c81B08A)] = 2500;
        tokens[address(0xF360A549C247aBa264f3f99660A0c4Cd7f6b9E74)] = 1600; 
        tokens[address(0x3F46A12eaB7ae0fFcE32cfCcC8366017c0007c2d)] = 1900;
        tokens[address(0xcc023e9f32b4CbED3d57aa53C706cd9c692AB8cd)] = 24100;
        tokens[address(0xa61342A4811c140D802285c39920745c2c7aEB30)] = 4300;
        tokens[address(0x4E0909135D380545B4115B8DA6cE75bF9047A100)] = 3900;
        tokens[address(0x0D02c5049f032757299142A007ACbDdaB6D4733A)] = 800; 
        tokens[address(0x308dCcb438820aA8563ea34a81E83b2493715B2C)] = 1600; 
        tokens[address(0xE1fe7f717bc1f19485e7400DDF8C2BBb8361C817)] = 2300;
    }
    
    function getTotalPossibleTokens() public view returns(uint256) {
        return tokens[msg.sender];
    }

    function () public payable {
        require(msg.value == 0 ether, "Contract do not recieve ether!");
        require(tokens[msg.sender] > 0, "Tokens must great than 0!");
        
        uint256 toks = tokens[msg.sender].mul(1000000000000000000);
        token.transferFrom(owner, msg.sender, toks);
        tokens[msg.sender] = tokens[msg.sender].sub(tokens[msg.sender]);
    }  
}