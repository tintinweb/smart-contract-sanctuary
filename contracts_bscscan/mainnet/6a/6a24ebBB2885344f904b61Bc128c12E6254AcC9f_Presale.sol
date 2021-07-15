/**
 *Submitted for verification at BscScan.com on 2021-07-15
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface BEP20Interface {

  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function getOwner() external view returns (address);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address _owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    return add(a, b, "SafeMath: addition overflow");
  }


  function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, errorMessage);

    return c;
  }


  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }


  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }


  function mul(uint256 a, uint256 b) internal pure returns (uint256) {

    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }


  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }


  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }


  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

contract Ownable {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () {
    address msgSender = msg.sender;
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract Presale is Ownable {
    using SafeMath for uint256;

    uint256 public presaleCost;
    uint256 public depositMaxAmount;

    BEP20Interface public dexf;
    BEP20Interface public usdc;

    address[] public whiteList;
    address public reservior;

    mapping(address => uint256) depositedAmount;
    mapping(address => uint256) paidOut;

    uint256 public totalDepositedAmount; // total deposited USDC amount
    uint256 public totalPaidOut; // total paid out DEXF amount
    uint256 public participants;

    event Deposited(address indexed account, uint256 depositedAmount, uint256 paidOut);

    constructor() {
        dexf = BEP20Interface(0x9FE75b6f6c642ED9081326C4AFe92762B4ed8C7b);
        usdc = BEP20Interface(0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d);
        reservior = address(0xb357929b957E3B36204Cc2D02DD52e59Ab762177);

        presaleCost = 111111111111111111111; // 111.111111111 DEXF per 1 USDC
        depositMaxAmount = 250E18;

        whiteList.push(0x299AF87bDfBfFa41632A776da32F9999015Bd637);
        whiteList.push(0xFd7EFeA4050263A451329599b3BB59F2f8E09b9c);
        whiteList.push(0xfbf9137Aa3aD1F8b38B42D90AFB7e4cB2b39e633);
        whiteList.push(0x353EC1f8Cd40D43de8197F7a25fFC25955Dfe4dF);
        whiteList.push(0xB29f53c7a2119CDa07128E5f0C961b0CCE044B70);
        whiteList.push(0xFF5f12bBA5Aa236e74D05e4D7a14a2904205E0a7);
        whiteList.push(0x46783E47ba77781D1f29272Be9f1A6Daa14E4c1f);
        whiteList.push(0x358FA0e6A86e441d8dE9D6a4d00C371FAe54486b);
        whiteList.push(0x743C8AA0d37663Ab2f0552cE5d1016874f083e33);
        whiteList.push(0x8E491dadF098F21439eDd95907909baD7AEc5B39);
        whiteList.push(0xFD63A08cE8e06cfAB51bc10525C4D3270328a663);
        whiteList.push(0x0B37DD5D8418269eaAA6a86a8035474546A19d12);
        whiteList.push(0xCf926C645038EDa43502BdB01785CB586b85b1FD);
        whiteList.push(0xf28220e80e7e77B417Ca8ad295DaF5E01D4945EE);
        whiteList.push(0x77C53F895C1250Dc8Ffe29BE2291Cc85F72bc70e);
        whiteList.push(0x88702F13bea30Bb3cB701A609692dE9657A19eE7);
        whiteList.push(0x18f612EbD88C12bA31D0D2a90C4D26e243F5f2bF);
        whiteList.push(0xab67a3601F3047a4d97F7cf18221A9fD5e142aF4);
        whiteList.push(0x4a6338d765f55f9EB6B52C12934bf832230842A6);
        whiteList.push(0x8F4DE593645782750113586316a27f520afFcd2b);
        whiteList.push(0x2a81361A1077FD626daD38725D70733972d7e30d);
        whiteList.push(0x3E9650E9525f021B7e9Fa8417566805Ae60739D0);
        whiteList.push(0x5C8e2Ba9DF0c510Fc724Ab575804f9892eB2c678);
        whiteList.push(0x78d626162fa915F48fDaC19367e4F34A29473dA9);
        whiteList.push(0xbA49d06250F914C4CB178CdDDbae11b19D6c1785);
        whiteList.push(0xA90Ce09B27df88DfE73045211C399CdC6feF118A);
        whiteList.push(0x591696397Ef3A097C9675ACF31eD7a1807D868Ca);
        whiteList.push(0x398Bbe12bd395195fbf1FE73DDc9C70aBD7c0E2C);
        whiteList.push(0xf51d266CB1bE87930A36264F6F30C6b32ae98F57);
        whiteList.push(0x8875bCB0C601897c9fCB250128dC00bee9c292b4);
        whiteList.push(0x64e58eB4C8595d83aaC71e6264f146c026897090);
        whiteList.push(0x3747a7b74c6e11294A8a5e5105CcC9De06A28997);
        whiteList.push(0x3c20e3d790aad94FfBF5471a09429a0E38103aBf);
        whiteList.push(0xF47210337D9940833bB221B6e935d33896405d2C);
        whiteList.push(0xF5a9ee2Ba013adFc5Bf7412eb186a32d9677ba03);
        whiteList.push(0x3926B7e5029d9BB6616dB26D8ABb34b1Fa3F8F8d);
        whiteList.push(0x6ae72A1475fa42D105CA9737F20d7bAbA9AeF413);
        whiteList.push(0xE0F6dC932B91afF54D90EDCB0E79dd619103cAa3);
        whiteList.push(0x61a20aFf98e9C2DbCa3A455e1d30F8C9b1e87d4D);
        whiteList.push(0x9e6B01aeBba8C4F1816c99a545846547d4288D1c);
        whiteList.push(0x65A9B9E3b8C94D4e960E7b848F42c8eD75DdF658);
        whiteList.push(0xCb186eF97db6E90322fF0D2E0B9a896e171833C0);
        whiteList.push(0xb4Fab50bf6479088f13c7D3Ee8c947d634DC00a6);
        whiteList.push(0x5FDc0265E0CF7B9D4b3Aac4e2D05F9e98243B455);
        whiteList.push(0x683e2Ae49af295AB50d0a907077A3a612c80D592);
        whiteList.push(0xC77931eb4755F3F40c95c86B6898709c88BAE346);
        whiteList.push(0xF5f7ff35c76Ae27765B1528A76b61ad210C12858);
        whiteList.push(0xf09a9E448c4aE0a813D4489dc3424CfaAad42026);
        whiteList.push(0xe2EE7b0Ae575bab41CA3164cDe806d66d62f8753);
        whiteList.push(0x7BB5d06F61922cD0147fd58347FC01e58D161350);
        whiteList.push(0x971740Ed368934875f1890898D5FFC10EA99FA43);
        whiteList.push(0xcaD8F2192A5713CcF9Faf92F264c40d16fa79760);
        whiteList.push(0x6Bc79F8974187E6921C5aF317C1BBF9FC1D0dB97);
        whiteList.push(0xC6aAf281B4E677B4910D1f5f05463ba28140b7Cb);
        whiteList.push(0x249Dd37D97ab9649aA90608a2bB080246ee60a2a);
        whiteList.push(0x58B47Ec65D985eed84c369F1bAc7f054A2273018);
        whiteList.push(0x021C4aeb2C021B85c16adD7292504853c5224bDA);
        whiteList.push(0xF9F9A90Bddb429c699b36BbF94B78Be1FfFC7eAB);
        whiteList.push(0x38ED9BC1a1E17662CafBeBd359F6E9122faB7314);
        whiteList.push(0xC7dEF88612158B69332702B597c9aa6FF622D463);
        whiteList.push(0xF3e72aB117D8Cbcde44e44a7276aF68B888EF3EB);
        whiteList.push(0x0a2d3Dd46E44AcEC0DA085268502880bB384bCC0);
        whiteList.push(0x5A83C5067B3aA9B185f2ef0629e53584828F6A37);
        whiteList.push(0x0Efa1331c343FE8803B76e85c95f546C14271ddD);
        whiteList.push(0xc5eDe3C150Ff4D48BF4672aBE5087E24338eDAd9);
        whiteList.push(0x4FB0689053AE15CFB3c275316858F2bfE0935904);
        whiteList.push(0x9825f3899De52700a8641C83398274f4610bF6B4);
        whiteList.push(0x12BF113d5633536269Ea71CeD6a250e048dF7FE3);
        whiteList.push(0x6a4d47896e4277732DEe36851b4C1Ab2C6149F3b);
        whiteList.push(0xe2FCF179d712DD417B4fa36a834E57a9D9282E1A);
        whiteList.push(0xDC41732F931D916E103F96861eC7962fF4b9bc28);
        whiteList.push(0x851A527f1b6502828F28d1F0F9499Ab8248e6E6b);
        whiteList.push(0x300Ef369708D850446dfDE4c1C14D70E358d31cc);
        whiteList.push(0x7aC97D8b2791a14F66Dca19702e0FDb3e8Bf9246);
        whiteList.push(0x904A23EDE4BD95d7A93c61F4f60116665b7ef4EE);
        whiteList.push(0x2820A2b534eC948412699074389EDF8aab88aD30);
        whiteList.push(0x7C6C49210b27853FCAE9f17A578efdA108AB0ba6);
        whiteList.push(0x2d3d72B3e0ACc8032c25c1305b7618209cb4c705);
        whiteList.push(0xE8FbB0a7C31a6a83723BA6d4F90f9623F5e5881d);
        whiteList.push(0x7e3865EA41c7E3d669dc9b091Ded7030AD5E1495);
        whiteList.push(0x688F49ded20352f0220f67566b03F7DD3fE188D4);
        whiteList.push(0xaBCF00d690449e8C9bc2d2ffb551dA1AaF7D11ec);
        whiteList.push(0x18c7B1FDba2fe6EDbb94B24BdcE541127657F760);
        whiteList.push(0xD45CFD9Ff10E2C961028339304644903602896da);
        whiteList.push(0xcE7E9aCa23D7A79873a06B4ceD3C750B91714EeE);
        whiteList.push(0x78413a094c8a4676Be3D2ea27F163dE323D79Bd5);
        whiteList.push(0xf2FC896c15EEe32E9DC6dAEB356FD32A72279C8B);
        whiteList.push(0x4e0777886373fC9e0d2c93141DFaAa01A27ec26d);
        whiteList.push(0xbeF371B949951F495Ec778A14B7eB5dCb40dbda6);
        whiteList.push(0xF63c14dE4c7fBB3a958282D2824B22ADe9903718);
        whiteList.push(0x8Ce32e7548384B200c99C64E972941B0094A0744);
        whiteList.push(0x0b26De0697F75b1713AD1D8d54EB80d7995FAAf6);
        whiteList.push(0xbe7f58eF5f0A8163d808EB9a86d53A7ACb4b518f);
        whiteList.push(0xFe8560331b24D45D6998932b751e8CF3B13bD82f);
        whiteList.push(0xeeb75B7810ADb04FF9fCF46bA117A53a21A342e4);
        whiteList.push(0x2b0931c78DEDD4CEE637A786A4F0E2950E3f60e4);
        whiteList.push(0x02c04e2D2C2A56992641Bd9EDbb7D1FC8E282bc4);
        whiteList.push(0xb58d02F180f9613EC6Da321A0a7A7e712d11A5BC);
        whiteList.push(0x4166607EB63fa4b3D7653bf375C904480C8397F6);
        whiteList.push(0xF64CBAb8971dEe096e8954dbD180eb6e5c6cC41f);
        whiteList.push(0xeA392bdd8bc3Ae0985C9EAFf84b2967BF25a73C6);
        whiteList.push(0x7D0E6ddda314217C0F9a35f0fc8A58fd33e43323);
        whiteList.push(0x2D019625A30a053ADaD8a0627Dc7ce95e9aB79bE);
        whiteList.push(0x731Bf4FA4F2E968F1B77025E481a885531Ea7c82);
        whiteList.push(0xE75637C73511DD2639e0A1cd09B75d821322F71E);
        whiteList.push(0x6f081e94597fD0BA8006bDeE60b11a7Cd8ab5F26);
        whiteList.push(0x45553F8AbF49AacBd9361583811F40cb003Ebc8F);
        whiteList.push(0x8A9d8fC6f2573793faF722D0b9CD7bD485d63f33);
        whiteList.push(0x581974A7C4E2Ff1DD5656DBc62bf46509d821276);
        whiteList.push(0xFbd918784e49a2A72F17783acabF766904d55869);
        whiteList.push(0x330E7F9Fe13AFf2296A5E03d5C86d3490d524bAb);
        whiteList.push(0x3D6e4A3857EdB49d0704e1940cacF5B8512D121b);
        whiteList.push(0xf661e99c8D4EC92Eb462E8DcbF24a221fD467F35);
        whiteList.push(0x2e3842F928Ab341ad7a15D824654e0a5A6F43786);
        whiteList.push(0xE37d9c07682D4A101a05B2ca54c5100D4Ee40437);
        whiteList.push(0x4094Ac8AaeAD5e9A575843Ca335F1CD49B58A567);
        whiteList.push(0x4959425274D74A2a652aD2679708A82fB247DAA3);
        whiteList.push(0x056BB56e625B756b92E58c25c998eaBC50c29e09);
        whiteList.push(0xAD7cc7861778a0f1f52d64E8A082a400c974288f);
        whiteList.push(0x8FC255855f15e3933b690E2AAfACdf7Fe3242C4b);
        whiteList.push(0xC575eDa37B72810Aff0569aC496f00982897FDFf);
        whiteList.push(0x25786A50DA09d25D5A2b7cA73f108F69dd5D1F81);
        whiteList.push(0xd11745EF0Cb5a7d81493d42f9469e6DeE0123028);
        whiteList.push(0x2f419dfF732Be9aF8D6f74B600a04c7c3477a52D);
        whiteList.push(0x89625bb758d12b1Dfbe7206bE0f11017B81aBae2);
        whiteList.push(0x3663A6012Ccd05B3d65eC666d4dD0372dEB87Ad3);
        whiteList.push(0x64d6Fcc63bA022fcaEc0e1b207934c9E94333776);
        whiteList.push(0xD457eeaDcB2c1C923E07a2fF2a44ceC0fA6B4aef);
        whiteList.push(0x924b569b23935A0bf7A422594c94A046fA0e3491);
        whiteList.push(0x43E113733a430565C4d29082E9E0c23B7Fb6306F);
        whiteList.push(0x529CDE390d75292A1e114aa0Ce591eF68D0Bac71);
        whiteList.push(0x2B786BD7af48d41263388c63e6613dFe9c6A27e1);
        whiteList.push(0xCAb5b71eF27AA7427EC7A87D95FfC0e7E3434565);
        whiteList.push(0x302fb23138ac2c4A5C810c27cAE014e3fCcbA73d);
        whiteList.push(0x5ccC36ed967662B8AF0f9af19fa016742e4f319C);
        whiteList.push(0x877444579532453050720cEd6a8A66C0c60B04C8);
        whiteList.push(0xF7a7584495345DEC3caB71C44FeB591106E37fBC);
        whiteList.push(0x134270FfD847a6b0B873047Dc9Bf18b646a75a13);
        whiteList.push(0x980B91Ca58247353A9722D0738075c913df5Ad14);
        whiteList.push(0x816a9811e73303F24036621161Ba54fC36B6c9B6);
        whiteList.push(0x71896F8Fb982dfC19636A5F202AF329c07a641c9);
        whiteList.push(0xfCA2B66aD9771Ed512FD80b7D2074F3Fcd89AAF0);
        whiteList.push(0x4f804a32C719fe8542F1df7C2121114f8a0Ed248);
        whiteList.push(0xd940633D48c756a2D28b63BeA4fb7366DA0cE9b9);
        whiteList.push(0x2b7FEf409d28650934007a3C863C2b245d20eDd9);
        whiteList.push(0x7A37ad6540407730460EAE225Fbfbd01D134b745);
        whiteList.push(0xE8Ebb7A1a46F41Ca0a7952E3132c8c570dcf0e46);
        whiteList.push(0x1b392755F5D15484A40990c45BD985f60c479881);
        whiteList.push(0x65935eeCa6a9A5C9d5F3Df0bD8341960b2516A5E);
        whiteList.push(0xd2B2FdaaA34D8Af309469b3e2B90a43bB180BD15);
        whiteList.push(0xa7c8D5922FBF35550762c073F41F1aFDc8087900);
        whiteList.push(0x0742DB2e48A615dE5aC2AeC992a281e3e34f0beC);
        whiteList.push(0x1f225655410E0F267EEa1197492660bA000890ee);
        whiteList.push(0xaAe266b62BC1f4678890aD09688ab0bC9fcd3FA9);
        whiteList.push(0x398E7b3E1B2E10Ed40Cf3CD0c9f28d05D9e0a289);
        whiteList.push(0x6b16554cAA2ba1618744166154bf2ecCF767113a);
        whiteList.push(0xb22780440F54e92efA791731B46e4Ed9820CDF19);
        whiteList.push(0xB1218545418dF27159220cc871e255068902972c);
        whiteList.push(0x588D777b03d451137379f16bF79484EA12FDF9cc);
        whiteList.push(0xb895E675289E5ccB3abA8ACd3AD12dE2b789dEb3);
        whiteList.push(0xA226bd6e3Df92c0b2085C401511fc7b891E61988);
        whiteList.push(0xea3012471790914B2f14Fc8f2566dFA14CB2bD8d);
        whiteList.push(0x298523fAA843CA40e83b7934170ca874a4FA1b04);
        whiteList.push(0x672179636A89aB608C8255EdAff9f87A7587DB49);
        whiteList.push(0xB13D15d63efb6e0483c0753e7e85601b992a8F76);
        whiteList.push(0xEA53611f2dA2362b447d28366e7df24742da372d);
        whiteList.push(0x5768A7EFCd49D65Cd489BC7bB39122C2E550cA3b);
        whiteList.push(0xb51656f089fF962E9a10762cF39eDA1EdA5E2622);
        whiteList.push(0x405BF73F7Ee055A50Ea968373147AF3B27288726);
        whiteList.push(0x9eeBC28e44054b0b7b6534275379880196B8b42A);
        whiteList.push(0xe6f52688577eAA412a1B13b18514bF18D6eBcF1A);
        whiteList.push(0x1873A794dfee7cE62fd53a22D64AEd7f7B2b9759);
        whiteList.push(0xdd2EE131b1AcFeeAA9c31F16c6d48979a1Cc8896);
        whiteList.push(0xC47145A82F21C5Bb731e0Dd419a668a5014A7037);
        whiteList.push(0x980F9f7ECF7Fc97A21D96b0D33BCc0f0cc049B5f);
        whiteList.push(0xa5ca6A1DC6Eb120EC1a7368D3618792D68FdD308);
        whiteList.push(0xefC6f9C09E52a4B21D80445d9204b79800888014);
        whiteList.push(0x73d862E761e58A2B9A7da94681F151E3C55ADb5c);
        whiteList.push(0x28e5e5924EA25BFbB81Be6080904B1125C784bb5);
        whiteList.push(0x1E69AE5990209119011372E0EEDbDA1759C210c3);
        whiteList.push(0x89483941a2f91c83aFb5553859372bE2225fB5Df);
        whiteList.push(0x0FC588D6c2cAC062Ba0f4e8ca9C559a14c3C5909);
        whiteList.push(0x38bD9D84545728C520B2aCABDBdBe16bbfcf2FA5);
        whiteList.push(0x0B08f3AbaAf45A351519B993e870E019a0638D9b);
        whiteList.push(0x55b434e4E5D27CD60946e79e1C7f50B3ca50d6E2);
        whiteList.push(0xA2C8dF414CBf1789d1D463Cb02B48B0AC81DCef9);
        whiteList.push(0x5a65DFfEAf4c708902AbfCa1b96C6AB1CB16915b);
        whiteList.push(0x82Ef536e21fa65Eeb536FCCbEA43C2e4066D3731);
        whiteList.push(0x1eb7c4C104757d6485d9C3caC305a22443b909AC);
        whiteList.push(0x994Cc83AB1db615Ac16C3B2771154Edd47a79690);
        whiteList.push(0x314769bFfA2dDF902F1E276212621A88644479e3);
        whiteList.push(0x016208E43ACB445947b5D6E8B4c870CFB5eaE533);
        whiteList.push(0x85D8179BaCB371C3F343365fec64b1233D914B69);
        whiteList.push(0x699584D60b54ec1f63e2c3a51109aADB2A42C8f8);
        whiteList.push(0xFC14F33d24797D5Fe1EbBc1010dd4d14eA2FCBBa);
        whiteList.push(0x47cD5987BA951b7d6DE3CeDD78538BB7131f337d);
        whiteList.push(0x0f0924A3a5111e7987A23a49Af826D2Ba431342e);
        whiteList.push(0x3c6ee522DDD9BBe622192c0276fB316c45790143);
        whiteList.push(0x5c8c58D4bD2F210A71e7Efda2A83c5eEc4B2b09f);
        whiteList.push(0xe5D8A2E6191c716FDDb079306bc1d90d54036B17);
        whiteList.push(0x0e4A0744346170B163010E0d2d59D285295056B8);
        whiteList.push(0x9A815e666c62aAB21dCB3Cb9542a610dbf420fa2);
        whiteList.push(0x6C761a5a3eFa7097701cf2A6e8179e54Ce1103a6);
        whiteList.push(0x41aaa09cF8e4bf23e4Ed1177408f7Fa5AdEfEE03);
        whiteList.push(0x5482e0843d8cB240293B7DB865ff04E19C5e821b);
        whiteList.push(0x73e39EFe31BCA1a621605CAD64bD727bA3d3Dc93);
        whiteList.push(0xb6738C97b8dC04c59B24bD147eeBE49990e789D7);
        whiteList.push(0xfD213514C4cD32026951bf40905451aB4410Ee84);
        whiteList.push(0x90025538eEf6DCC448b87cE5Ce46973618D9d83b);
        whiteList.push(0x794eD6f48138Dd7080816F17ff0C82984AC90238);
        whiteList.push(0x363085D9eBc20715fC61C3337f293b7940529e1f);
        whiteList.push(0xF8988f7692D373Cd0F901272a23e3aAf33Ed85ed);
        whiteList.push(0x5db0BFe70B6D9E32213FC05C1fC22bD58Bb005Bd);
        whiteList.push(0x345CC8Da3F2eD35E2fD60F3Eeb3FEDD6BB53dB8b);
        whiteList.push(0xf0fC9f106EBa57fe964913df51087E3E0C1dC452);
        whiteList.push(0xddE93Ee529bF5Fcd09F439021ff59e9B9a6b12F5);
        whiteList.push(0x7B81B1fF0D597a5Ad9D34Aac95C07F783357E7C8);
        whiteList.push(0x3218fa2B8DcCdc91c85aF8D72Fa5AfDC39175745);
        whiteList.push(0x1fA62F406fFc52244B8b30dc28c0e0352DB688Bc);
        whiteList.push(0x5341c9127998B9a9D8e31d5a3F8142aAE2074d19);
        whiteList.push(0x8Ff919BF70264FbC1ea303D649F27243d9d8E3Fc);
        whiteList.push(0x57AE4d91D79AB5b891A1beAaD958D093A93e91cF);
        whiteList.push(0xF5416690223f436De800FeDcaEF244f03E03Bb14);
        whiteList.push(0x401659B5a5176b73645d82931E2481a19dA6DAfa);
        whiteList.push(0x0d2eeaC23694b5a13BB481fD997aB3F01Cbc6635);
        whiteList.push(0x8425176e0b0E1d2CB0220a7EB7702F215440eDf3);
        whiteList.push(0x7A8E6052bc3f850f819f9656cDE45d7EC893bFF1);
        whiteList.push(0x262958877B7b0911CAEE1876636d1F8bBF181296);
        whiteList.push(0x951864056Af5df77316Ca383246Bb802e722f1F8);
        whiteList.push(0x757a1f2D75E776364498f991D6C52428EF7097DE);
        whiteList.push(0x9849b7ed69539112C90467843B32146ED5daC051);
        whiteList.push(0xaA14C52d5359AaF9a86Ab4C417aD34bbdE1BD024);
        whiteList.push(0xf845A40a01763ba1b83462BEeCee331bc4653ED1);
        whiteList.push(0xEEA2fc495B2f272C70a1b185ba34B6632adfBf63);
        whiteList.push(0x3f529523984f91908c551B4ac9432e1049888Fd0);
        whiteList.push(0xAb9220E61CfE2f8DE46Bb85B339616152518eff0);
        whiteList.push(0xA3C4dB2436c90A8cB99f1B2B2137F4D0eDafee8d);
        whiteList.push(0x6890249ace0EafC7eA5e3C8Db1B898Ee30222Bd6);
        whiteList.push(0x31CF9C95E5E38e14f82B96E66408393299EF5a3E);
        whiteList.push(0x804e2Fa1d69126Eacb219d6A79c34702BC77B90A);
        whiteList.push(0xE6D828acc91333aB85B136400e30d1F71aC9837D);
        whiteList.push(0xd07dBAc430dc8f078037Fdbc39Dd96911A71143D);
        whiteList.push(0x656bF27D3A789d3B173b89BFBC10631bF1087557);
        whiteList.push(0x3F2812a4C190FF665E46715fDEde778059e4c6b6);
        whiteList.push(0xcC3fd96776724a83BC3599084D7bDeDC778a8e6b);
        whiteList.push(0x7890dD0c31c592592aD2cBb547cB5336E6CF33b3);
        whiteList.push(0xB437A90e59785740A67FC5376180AcC3b705EdC4);
        whiteList.push(0x7862Ca0fCb33845FdC64db0aE4F9F97d03b46af0);
        whiteList.push(0x18a6B8493C6ddB4101b4288335E513D7860f0B45);
        whiteList.push(0x483C0672f094D209DaC7378E6822F11A4826774f);
        whiteList.push(0x26E1e573578cDb4f2d88E34321Ff2B832E42c42D);
        whiteList.push(0xA6A4839539bB9F03C5ad035CD1cDCF109AC6C67E);
        whiteList.push(0x09483Ec95294082CC5a749E3E888567bd7A909CE);
        whiteList.push(0x4D0F9beCED6b7DE54274338a97d43dA0231948D2);
        whiteList.push(0x1007f0a5af195017C6214b28dbB8630413D83aD1);
        whiteList.push(0x06C6353F86499515EB1405dbe2C4f74d2CE13853);
        whiteList.push(0x7B4920c43Fba5b53EeBCf439E5bC5a5fE98a958C);
        whiteList.push(0xe259B2616C3930D6A0756041c86D1a7c545279e4);
        whiteList.push(0x733111c8acEE0b9307d3194Ea142daE2A339cD8a);
        whiteList.push(0x6DA4c2962470ff02fA1533A369CFA3fE7c71D173);
        whiteList.push(0xBE49CE8c7e99236BCD7aC4caF0Aa24E0c3A6EccF);
        whiteList.push(0x3F1C99f9bf035B7bAB7a7C24962179608a37Edcf);
        whiteList.push(0x9d9E5ec2EbB0711EA8219d6D589A8AADBf1250Db);
        whiteList.push(0x9F5dd232234B2f07Cd44ed98f9721d9599acee21);
        whiteList.push(0xC2f61C2cCdD601F352476684D3EF70051EA32029);
        whiteList.push(0xeC19C6559316674c810E6A4CDBC39C8cC4b14aEA);
        whiteList.push(0x01572ec51CA35d7d8C4fDe5EEa8eA9f0D6229de0);
        whiteList.push(0xc49A212346AE2411B4C346E4cA03b51621D8859e);
        whiteList.push(0x4361b66fA886C89C2778f5CdcfA36582C1C2631C);
        whiteList.push(0xa1b732D6353c410a8db87eB90BE95f93a9a8024b);
        whiteList.push(0x587CBdE67dE3DE091361BF5beA1A87F0883A96C2);
        whiteList.push(0xFc8f92E3AF18E0D815ef722EaEDdCd5fb7Fbc1D5);
        whiteList.push(0x1e5a2247eFBf8d8Ee76EB00aE92F2E89d45C52F1);
        whiteList.push(0x7F2317F5939384CEBA965dbf9EB67057FCcc451c);
        whiteList.push(0xF4cB7ca9e5c143fE590Cc3426A9437A6c50998Fc);
        whiteList.push(0xc8c8559ab47C68B2A5f24D8F559Ae95290Cd68DF);
        whiteList.push(0x6796F38938624CfC44A3A17D7cd2ACe3059078D6);
        whiteList.push(0xB3613adf843e1424e3917727591cc9b60992Caaf);
        whiteList.push(0x6b1Ced8F984a5e7A68BF5646511C3013405Bbc27);
        whiteList.push(0xCFE65aEB43f6b316671B56565228aa53BaBB15Fb);
        whiteList.push(0x57dF970D85620d6A95bb0f29D6c0a0C0b55F6282);
        whiteList.push(0xCf90B8Af531BA17334636b1b5F16FbD33489C252);
        whiteList.push(0xa87cdc4464B8a3fDeA083cfa3826Ef2994E66e0D);
        whiteList.push(0x2473C01Ff897e8D1f0DEAa9cDeEd3480727dbf81);
        whiteList.push(0x7aF5598B5F29152F2EAA1405fC1B179A41831615);
        whiteList.push(0xe2aB0138144414f76Ef449BCEB32A7C7A0cEeDa5);
        whiteList.push(0x91FF99a93a57D12A3c94f8F6bF82E0f36af26915);
        whiteList.push(0xe70B85657c9d7dde0F413832d0383aA60D3DcCE5);
        whiteList.push(0x420CB838c0BF4254A096F7F88d04910Becc70001);
        whiteList.push(0xd982AAde581dE718dB7d3A73cb106c922a3b0fE4);
        whiteList.push(0x4F40303CD89B7daCC680b131737d09288ccC861a);
        whiteList.push(0xA7A1460CB4469d5f12EBD07DFBFFeA5Ea2bB136C);
        whiteList.push(0x0AC974608ea03f9A1c09c918b33Aa98B85fBaf98);
        whiteList.push(0x07461301603d5505DBC05b498507CDf90C06876f);
        whiteList.push(0x896BFb75Ce74DE57944Be5CDB0Fe8cb113E1091E);
        whiteList.push(0x3a6486f910d188Eb13969A1B449A84Fdf32F82Dc);
        whiteList.push(0x89c5eA08AAA020B13708576092F78855bF78fDC8);
        whiteList.push(0xFD77888b59164755bC369A9b4e53F9DF57fD44Fe);
        whiteList.push(0x6cc87C563694ce0c9eCc525d9acAB7e4e279903C);
        whiteList.push(0xA30930A49cEdfA3f9CD2760C41f341f3ccdEA7eb);
        whiteList.push(0x256b0D2F9f3D33d447601bc4C4BBBaCC031aBA5B);
        whiteList.push(0x1C06959c865fAEb2aFfE4c598aa8De1dCe8C2258);
        whiteList.push(0xfeCd22D39f7f8c121bFF7285747084c86F2c4436);
        whiteList.push(0x8B037029f06A7e0DB437fed0641489111D19F7A9);
        whiteList.push(0xa59D60a61e4f3f3fc1a0c46f4e3AbA59671770f7);
        whiteList.push(0xebB42c14ba3631712a15be65472051977c579FbB);
        whiteList.push(0xbF923438A135a99712D4c4b3DB413a0817a90f99);
        whiteList.push(0x79d811C184f632fC8F41ED0DDD9B1CF824D8FC56);
        whiteList.push(0xc553ab5A21735bf3fe2949a9f7Df8C25263a694B);
        whiteList.push(0x5584cF54ADE7C81aB6d6Bc870C714F87FC0a7721);
        whiteList.push(0x4d708F6CB938e02fb524D7f0f47F916Ef120464b);
        whiteList.push(0x040cEeaBa3AFFc45Ed27A564300A63E29A0566A6);
        whiteList.push(0x675169C8283b4346d9cB31a64De343E38a13B776);
        whiteList.push(0xe39073489c1F1df8BDB06BA746B63C10eAD304Aa);
        whiteList.push(0x17FE89ad6C7300CAbCbB8D1eadF687f799a0Cb8b);
        whiteList.push(0x42565C799491Ed4C7F371C7a9cd371BD9f85EAF3);
        whiteList.push(0x0585146882669Cb3B5395DC83c2deE37c283e5C9);
        whiteList.push(0xc0D861751Bc0dE2Cd0197AC22D10815d31f85914);
        whiteList.push(0x9fFCfe879e3753206E6834d2D2d0844296aC9173);
        whiteList.push(0x42c09acbE8B28B4cA6237a88aB24D4F8b66fc13C);
        whiteList.push(0xaC0F84Ca66910dCc26a865DB2bBa176946Af123f);
        whiteList.push(0x3d446c9528f5deC1848dbe4CC6D4fd2c432b336c);
        whiteList.push(0x34D5aFd94E31954EcA040171494522726144352E);
        whiteList.push(0xB7dA72d1EAd5F8BeA63Deb31A6a802c4F887C589);
        whiteList.push(0x2bB9Cb499e34Ff648C2191Ec59bbbC4c40088bA3);
        whiteList.push(0x33E4a4B9Cfd4ac89556C570fE529fD8314826DF4);
        whiteList.push(0xcE49d3939Be7703E9B9d526B19A56af1925D808d);
        whiteList.push(0xA7E5a837382C4B2A484BD2AFAdc8B5A5f6d74e87);
        whiteList.push(0x8A7913e1d8A23D1a88B712f8cefd59dC905b467f);
        whiteList.push(0xB08560237F31691f566b1d50fE1bea7028A94d12);
        whiteList.push(0x522117ED5CF7C3772eDb6BE27840008C385f0Ad0);
        whiteList.push(0xDcF918ca3ec6B82d73fc614Bf135b424D50AaA48);
        whiteList.push(0xd9dE10Af936ec65AFD1FC84EEa5449a6Cb431b10);
        whiteList.push(0x7eb66AD4579A20E2e47a1337FE53F526E1e2Ec7e);
        whiteList.push(0x6be093cbF0256236b65b45B9D0C49caA4a988b7e);
        whiteList.push(0x85e4dC00f4cd70afF6b03e68fB8bdc2501F8Dcf3);
        whiteList.push(0x2c24863601d07417C4af46C4Bb1FB841DE5257C7);
        whiteList.push(0xe0d7Aff81BFfbed294351F5300a6233a05936C61);
        whiteList.push(0x236e90C4f54213AC28ebAcCdfc784C3c5958b4cF);
        whiteList.push(0x5BCC504283179544321094E75D5Ef2ff02C6F6f4);
        whiteList.push(0xf997558AE6aB4e5b7DF35B6686becf512A50202c);
        whiteList.push(0x2A80E3630aa57B12519D72A52E7B0F6CE9B0b089);
        whiteList.push(0x542C1631BB8eFa335fc7CF43fdF424DEA727465D);
        whiteList.push(0x91b883bBea30d674b617E64271779DE2E693a1ec);
        whiteList.push(0xa4F0FD9d92e257B9D8e3FccEE740836bbD6c8bdC);
        whiteList.push(0xa4C6eBb5fa2AA145F64D644F331421b3EEb69831);
        whiteList.push(0x68494ABD39456B4500b0277B59aE050F5d97600A);
        whiteList.push(0x3142B7a2780CcdBF3f1be8084A28aFce41b5B967);
        whiteList.push(0x48a2f743483daC0bb8973a22a3A7E55aD35022F3);
        whiteList.push(0xA83dAe65DC9F0E6f1116e34eb056D1cE894e1B4b);
        whiteList.push(0x9592F1d7a698Dd3316999337d7b22a4af5adDD56);
        whiteList.push(0xdB9E450Bb772F63425B9f6dF81D69f2c3b8EE832);
        whiteList.push(0x81B6dC98547765a370F1ACD2566a059295Ef16cA);
        whiteList.push(0xe6F0277480714390E378Db8977E1cCdf1205A5Ec);
        whiteList.push(0xbf6fdf993061e5F54CfabD02986869fD3E2F2C9F);
        whiteList.push(0x60F8bEaea790cDF9d5Aa59C34f98c463c5B13283);
        whiteList.push(0x44eA95257A4d3c03Da44676c6B17C4eD9BDC1d04);
        whiteList.push(0x1A54f7998eD4F1Bd84bf98Ea34353352acd070b0);
        whiteList.push(0xc61828a3141c42d060381beABF0B70Bd781A5e5a);
        whiteList.push(0xbc56d69751B6a216BD1c7A09b0e081fc3Dd1015A);
        whiteList.push(0x81419974408BD8366f64a9CEb8bfA48C7A1EEf33);
        whiteList.push(0xd53E52233175995181515EE1D4C59CA77eD0E2c4);
        whiteList.push(0x50C77E7F4a83dE5Fb9e3B1eC6e157520BFcE9b61);
        whiteList.push(0xd6429F7cfe68f84631cDF7B3011Af743D7578659);
        whiteList.push(0xCb0cFEEa0Ad863c70Cfb27c24AE6f98367675e56);
        whiteList.push(0x19d50766C78a75f80Bf2bd33b51e9bAA26882a6f);
        whiteList.push(0x8d2957Bc1EBeCf30dB2d885F53e8b2378D16c60d);
        whiteList.push(0x74beAeb59500B4486ec3c83B81552279b79c6728);
        whiteList.push(0x09e21b21133c02C07760a991fef3f33129C21B4D);
        whiteList.push(0xeA2B0B5E68dD1488Aabe763251Cd149D0B5a8959);
        whiteList.push(0x466e8BB56842CC27558D5FECA4B923BdA8f2E9eC);
        whiteList.push(0x74969f8CaEafCb62f053f8332657afeB6aa07c38);
        whiteList.push(0x841cF31Dcde4c344bDC42B570546b7Cdf33fb8Ae);
        whiteList.push(0x5E160b6aB1a3F4a6ffe06cfd21B33C323Ac8Aca3);
        whiteList.push(0x69e2e620af5a284d7E17c709C3aBa86a539C8CbF);
        whiteList.push(0x6Fa4B84B330F1050731240FFE18127dE69eCb5ec);
        whiteList.push(0x969eEe22840015bbd8F4d88df17809D784820212);
        whiteList.push(0xf7F5a0Ce4A095DDd7c20883FD57683E9CDF977B7);
        whiteList.push(0xd4495A99643505Fd8f3fd9F816F2fc93642761d2);
        whiteList.push(0x4D4c4F0Be1e17C0953761B166aB36C759ECb4B7B);
        whiteList.push(0xe7463385d9DDfFb5a080A4df1af40dB758f0cE95);
        whiteList.push(0x6C620AeE9FAe15FeEa0032076168e43EAB4BDD11);
        whiteList.push(0x1107741a8059b384A90d6C6B25749cAA3B6A3F24);
        whiteList.push(0x74930FC1576414EB520761F178117eeF76b1B6C0);
        whiteList.push(0x09D7F6Ca625Eb2f3807Ba2CA3DFD341BF3aD3C69);
        whiteList.push(0xAc5Ef0d088A38c204F87Df24Dfe9f61040d4D3Fa);
        whiteList.push(0xf49B1aE373Cbf19238A64Fd8233B391978D7843e);
        whiteList.push(0x4c689018D571302001BA9e41CB7c1546fD0A434b);
        whiteList.push(0x138fBee9b56ee02d14c312B019a0D69Ba975c8cC);
        whiteList.push(0x620aeD8bc62ef4537C464dB432E2a7766989208b);
        whiteList.push(0xf5C0f439e0c2110d714d5F8AdE780D178A7fddC7);
        whiteList.push(0x6217b98e085e39770B3E35f32dBD158062926629);
        whiteList.push(0x81544E889021d90b8474B5c665D5eD020142334B);
        whiteList.push(0x38e63bA0C2a81672012bDecf73eCE5fFD8E73d26);
        whiteList.push(0x566946d4AE14a8ce63B259165a815720C78c177c);
        whiteList.push(0xd796fE50003D751a996969ffbf446ff4C178f5B7);
        whiteList.push(0x6816200a59ABb264F3f0f48E52f2fD9e7842018C);
        whiteList.push(0x563742Cc2c3D23C7AD3550441bdB7155db0eE933);
        whiteList.push(0x873b05a87F88F3300A3bee68FfE5C85471a2d327);
        whiteList.push(0x817B1106cda1A14103458855FB52451c1F65380B);
        whiteList.push(0x705391aaE45309bd66F0b28C7abB79c217EE7f67);
        whiteList.push(0x43019Ca6B7Ba2c31aA9312C27B1242fbCE8ea315);
        whiteList.push(0xB9636BBF404771731b81C150Bb9E492454660153);
        whiteList.push(0x735c08068fDFBdC0959Cd84D21f0d56495612fE8);
        whiteList.push(0xD64166B5667001E395Fe0653f2C91D5Bc738Bae1);
        whiteList.push(0xc87A03441DCD685525a3e91a2Ba4577f16a7ec64);
        whiteList.push(0xC7e9ed9FB47bd2D2FcDb11baf24c57C93f33Cc3D);
        whiteList.push(0x01571848a383a2E718E463E0A22C3B8513fFEc6e);
        whiteList.push(0x1a6a3176E51Eba3C9344F2c83CeC0C5E1B385d0b);
        whiteList.push(0x424Bd795A1ebcF401CA0E93Dcf4Cd6C8328B891e);
        whiteList.push(0x741B3fA0b2bf3b14C2D6F13ccfDFd584C68abD4E);
        whiteList.push(0xe1B443C465984CE0F498484Ce5F4f4697158AF29);
        whiteList.push(0x05beCC38DD2D070B8038A16785bCA1944dD5e9A4);
        whiteList.push(0xF8465AA9BB76656F0E95a66f45979deC03cB76c2);
        whiteList.push(0x240cc08b04a67F3732158c49Ac602D56D1dF7CAA);
        whiteList.push(0x728f762ec09152B45124814A5F1fF24397Ed3c83);
        whiteList.push(0x39E03e34Ca304D135D0e413B364B0dF65542c7B1);
        whiteList.push(0x6B1cf6d736c107630c40C7ba7bb652821F6DD6bb);
        whiteList.push(0xA3A369156E0F96f77b74ACF91867A21F6d8dc4b2);
        whiteList.push(0xDaa3fA727860179826154fF772053e6f7fB97758);
        whiteList.push(0xb565A438F4666675797C8729b87f22b72F372aA7);
        whiteList.push(0x1BB523268Fe5a7edd54C4e3b1deB9FFEBF732F31);
        whiteList.push(0xE2B1e00029f2252523C1F7dBB81e5B97c129e5be);
        whiteList.push(0x7165E5DfAbe30b290d5bb40650Eac9699B7CdFd3);
        whiteList.push(0x15E4Ce2ED89c2BD7e5D51c5BCcf976eaE8e89491);
        whiteList.push(0xA3668D0D94daD5c732Ce915a443991F05913f0F8);
        whiteList.push(0x01426cB6EbA3fA9b50B42c4D018C9B540670e8F1);
        whiteList.push(0xE4F11ef8C483C1d1Db02e89357E59f3329334568);
        whiteList.push(0xf974Cf8BD9b71B84A7A8d80AA446d306095e81B8);
        whiteList.push(0x2ab80aEfea898D144aa03f5590a2A82bEDdfc282);
        whiteList.push(0x9b2b802285321DF8A57b2533E7956e47D44974cc);
        whiteList.push(0x2ab80aefEa898D144aA03F5590A2a82BeDdf2737);
        whiteList.push(0x2c9fB87667105e004F5B1C484861928cFB963572);
        whiteList.push(0x05f485A6C842487854FF32DA35dE2aC106E0eE4b);
        whiteList.push(0xF6cBc2a3666Cfa0EFA6fF591A48955191821DB56);
        whiteList.push(0x4eE62Df8DC94aD5C9439b58a96C3828Ef704b9Cb);
        whiteList.push(0xc99372035cF3b00EC0CD4218289F61ad3aceEce3);
        whiteList.push(0xf9d5c971805bE42a418Eb52Dd3c34BaA03040ad7);
        whiteList.push(0xAdbB1851C0cDbA2B4f9e2Ed68b93F1bBF5953E5E);
        whiteList.push(0x2B39cb2B4dFf21c762D8D1C8eC69034A888e4503);
        whiteList.push(0xaE0217c035436453D4F6b64d1321C89b4051121b);
        whiteList.push(0xC9C1F84bA15D91D789aF72253f3A2994919BB454);
        whiteList.push(0x46412d9c73d74D3ac9238C12035e052Ee83e879c);
        whiteList.push(0xAf74ad08e027763006f92ff4Ff3307F8B3Cd1480);
        whiteList.push(0xb70084C99b8b2502e810CB442bB72C4dddBBF8ce);
        whiteList.push(0xfEDD7dD6b52c5f7353A0629ca90a3dE1c6Ce47A9);
        whiteList.push(0xAe6f2269283463e14708654CA32A4b8668357B8C);
        whiteList.push(0xaf33c42bE73A05F6Af6C225b3c2895D01F5D5008);
        whiteList.push(0x733AB147ef8F4efEA84ced248F1AFE74FBe21582);
        whiteList.push(0x4418C717F21FB80b753aa20c7906b964938137af);
        whiteList.push(0xF63b56ea3d14b2Fd5FDBF1Aa1b5CF7dc2434e509);
        whiteList.push(0x64C480274ef983a0178334F9C0395CD392724a32);
        whiteList.push(0xDeaF2ac1C2A1E9b4419b9a1D4eaCf6D49ffF745A);
        whiteList.push(0x510623f885E859C400d1792bE4AE22718E6FaC0c);
        whiteList.push(0x09e9D1d4699208d2470E535A422E67685f5c9cF7);
        whiteList.push(0x43646b09d07FA7fBA070c8d000B2AA0c22029148);
        whiteList.push(0xbB8277304F86A60Eaa8075c1a80cd9b15d4f6678);
        whiteList.push(0xdC9F813f7f6E2dcB55b8cA4b851bE0BAF057C796);
        whiteList.push(0x523c1506841F0B773770a412f28e9808B71D7222);
        whiteList.push(0xf76c2cD1D2D1028125CA675013e22a74d51BA468);
        whiteList.push(0x5fdd94014e63664eD3053C869515F5a82544Db2b);
        whiteList.push(0xDbbCE179e3C080912bd6BD0e9321b45386aef5eF);
        whiteList.push(0xaB0D99398605e959a669bC9e28CD6A75B60BD0f7);
        whiteList.push(0x29FF859cc59A602a2906f80f910feF57B20b3567);
        whiteList.push(0x8C30109c1631C12712dd5C588B8C454191efe259);
        whiteList.push(0x48b6d586919a9427D183FF4E2953Bba0422543B2);
        whiteList.push(0xCDf7F865d485E9139Ac4DA52618A85AC6222C118);
        whiteList.push(0x155606A6fBdf6B9538Da86783e5963C506d8717b);
        whiteList.push(0x7FC55EcF955f1C0072b3b6caCAB654532f10f017);
        whiteList.push(0x5F57222fA85193Cc44Ea2DE750d00Ae6447f9eFE);
        whiteList.push(0x4612f942FAfBCBaabE2916424ed74db4cbfA1822);
        whiteList.push(0xF1A1B7F122dFBF1478992B05C8C2d595c61954d8);
        whiteList.push(0x97a5c0A893a6468D30A79d9EF84Dce7CE89A545e);
        whiteList.push(0x32e80AC39b6e21673bCb83AC612bCA903bDfaAeA);
        whiteList.push(0x1e4F95dD8e26C06875f9E551fB7a4cfdAA2CEFc2);
        whiteList.push(0x4b5b9dec07F1862d6Dce0820d875e09b71559514);
        whiteList.push(0xF3d7076F487754e11ba16270644dc1E8A1c09227);
        whiteList.push(0xBd565209559ae6729bf08Ac89fd8855acF426B70);
        whiteList.push(0x2F639Ff2e0F3f85244D10e14AA7bF7FCfE7198a7);
        whiteList.push(0x57dF970D85620d6A95bb0f29D6c0a0C0b55F6282);
        whiteList.push(0x004893BfBd3889b8AD13b17D793a3c7aAf5E3144);
        whiteList.push(0x9291FC78748254699f2F4efA6C802Fa1445Ea061);
        whiteList.push(0x0bF61B669207fb3215b5733488b25D2E10CD9085);
        whiteList.push(0x7dBb18150bD3AAfa9Eb206ddCF1CCda3Eb7f8451);
        whiteList.push(0x1cc39872609A7ecB727653B835fB94056e9F9D4f);
        whiteList.push(0x4bd77E5637212bc070B6C1382B3bF40BC1a7DE18);
        whiteList.push(0xB8fb129642148c964230768826e3cCBB23D7C68e);
        whiteList.push(0xd9806d65843856c175C709C8Cb2bAb09B7Ec81ad);
        whiteList.push(0xB9092fAd6fcCED4512203896e4e2B4BfA738FcCf);
        whiteList.push(0x91A41fC7653F57584d46475Db4936deB032D35A0);
        whiteList.push(0x8309167FbE39D9D1ac1319dE64116dC888c67914);
        whiteList.push(0x3E5fFfaf17a2285c3d358E6891738F7bE56C014d);
        whiteList.push(0xCCAa398FA4bd82f8e6c2a4d95561f8387dB93ca2);
        whiteList.push(0x1e25AF449AF3A8a37B66367869ca7002036E98BA);
        whiteList.push(0x95445CC101bfADcEeC7942b4Ee3b786767063bd7);
        whiteList.push(0xaec6DE453efA34f8798b2D2b6969D568E0881B52);
        whiteList.push(0x2eCC650E73D984DB98c2d239108D2931BdAB7028);
        whiteList.push(0x2A7D0CD19D2617cE25b62642E51F1757Ad082e49);
        whiteList.push(0x6fC64A16AB9d27ce47685B87F36C611e96B73242);
        whiteList.push(0x861D69B295492e34984C0BE64Ac9CFc9b6c1B66c);
        whiteList.push(0x83890AF1668473e856dA269a5BC70d89dB33049C);
        whiteList.push(0x2F7543CE9eE888167D7999F83EB59a8f6a360063);
        whiteList.push(0x8e9e7F5B31dCab4ed2d9C3FaAa7Ae14aD1d40aF0);
        whiteList.push(0xd37056Df07A661998437CE9ffe874716D575b2f0);
    }

    // View functions

    function getDepositedAmount(address user) public view returns(uint256) {
      return depositedAmount[user];
    }

    function getPaidOut(address user) public view returns(uint256) {
      return paidOut[user];
    }

    function getExpectedPayOut(uint256 usdcAmount) public view returns(uint256) {
      return presaleCost.mul(usdcAmount).div(10 ** 18);
    }

    function whiteListLength() public view returns(uint256) {
        return whiteList.length;
    }

    function checkWhiteListByAddress(address _one) public view returns(bool) {
        require(_one != address(0), "Invalid address to check");

        for (uint256 i = 0; i < whiteListLength(); i++) {
            if (whiteList[i] == _one) {
                return true;
            }
        }
        return false;
    }

    // write functions

    function setPresaleCost(uint256 cost) external onlyOwner {
      presaleCost = cost;
    }

    function setDexfToken(address _dexf) external onlyOwner {
      dexf = BEP20Interface(_dexf);
    }

    function setReservior(address _reservior) external onlyOwner {
      reservior = _reservior;
    }

    function setBuyToken(address token) external onlyOwner {
      usdc = BEP20Interface(token);
    }

    function setDepositMaxAmount(uint256 amount) external onlyOwner {
      depositMaxAmount = amount;
    }

    function setWhiteList(address[] memory _whiteList) external onlyOwner {
        uint256 length = _whiteList.length;

        require(whiteListLength() == 0 && length > 0, "Invalid setting for white list");

        for (uint256 i = 0; i < length; i++) {
            whiteList.push(_whiteList[i]);
        }
    }

    function addOneToWhiteList(address _one) public onlyOwner {
        require(_one != address(0), "Invalid address to add");

        whiteList.push(_one);
    }

    function removeOneFromWhiteList(address _one) external onlyOwner {
        require(_one != address(0), "Invalid address to remove");

        for (uint256 i = 0; i < whiteList.length; i++) {
            if (whiteList[i] == _one) {
                whiteList[i] = whiteList[whiteList.length - 1];
                whiteList.pop();
                break;
            }
        }
    }

    function deposit(uint256 amount) external {
        require(!_isContract(msg.sender), "Sender could not be a contract");
        require(checkWhiteListByAddress(msg.sender), "Address not allowed");
        require(depositedAmount[msg.sender].add(amount) <= depositMaxAmount, "Invalid amount to deposit");

        usdc.transferFrom(msg.sender, address(this), amount);
        totalDepositedAmount = totalDepositedAmount.add(amount);

        if (depositedAmount[msg.sender] == 0)
          participants++;

        depositedAmount[msg.sender] = depositedAmount[msg.sender].add(amount);

        uint256 payOut = getExpectedPayOut(amount);
        dexf.transferFrom(reservior, address(this), payOut);
        totalPaidOut = totalPaidOut.add(payOut);
        paidOut[msg.sender] = paidOut[msg.sender].add(payOut);

        // send usdc to reservior
        usdc.transfer(reservior, amount);

        // send dexf to users
        dexf.transfer(msg.sender, payOut);

        emit Deposited(msg.sender, amount, payOut);
    }

    // check if address is contract
    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}