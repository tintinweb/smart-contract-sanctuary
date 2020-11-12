/*

████████████████████████████████████████████████████████████████
█▄─██─▄█─▄─▄─█▄─▄▄▀██▀▄─██▄─▄▄▀█▄─▄▄─█████─▄▄▄─██▀▄─██─▄▄▄▄█─█─█
██─██─████─████─▄─▄██─▀─███─██─██─▄█▀█░░██─███▀██─▀─██▄▄▄▄─█─▄─█
▀▀▄▄▄▄▀▀▀▄▄▄▀▀▄▄▀▄▄▀▄▄▀▄▄▀▄▄▄▄▀▀▄▄▄▄▄▀▄▄▀▀▄▄▄▄▄▀▄▄▀▄▄▀▄▄▄▄▄▀▄▀▄▀

https://utrade.cash/
AUTOMATED TRADING ON UNISWAP

Utrade is an application for convenient trading on UNISWAP. Limit orders, stop orders, trailer stop and everything else that is available on traditional exchanges.
*/

pragma solidity ^0.4.13;
/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {

  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

  address public owner;

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }

}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken, Ownable {

  event Mint(address indexed to, uint256 amount);

  event MintFinished();

  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) public onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() public onlyOwner returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }

}

contract ERC20_Token is MintableToken {
    string public name;

    string public symbol;

    uint32 public decimals;

    constructor(string _name, string _symbol, uint32 _decimals) public{
       name = _name;
       symbol = _symbol;
       decimals = _decimals;
    }
}

contract ACrowdsale is Ownable{
    uint sat = 1e18;

    // *** Config ***

    // Token
    string name ="utrade.cash";
    string symbol = "UTRD";
    uint32 decimals = 18;

    // ICO
    uint start = 1599062400;
    uint period = 12 hours;
    uint maxSellingInICO = 140 * sat;
    uint256 coinsAfterIcoAmountTeam = 110 * sat;
    uint total = 500 * sat;

    // Block tokens
    uint partsAmountToTeam = 5;
    uint periodUnBlock = 1 weeks;

    // --- Config ---


    // Config dependences
    uint256 leftTokensAmountToTeamBlocked = 0;
    uint256 everyPeriodUnblockAmount = 0;
    uint nextUnblockUnix = start + period + periodUnBlock;

    address owner;
    address me = address(this);
    bool isFinished = false;
    bool isPreIco = true;
    uint icoSellingAmount = 0;
    uint capInICO = 0;

    mapping (address => uint) private influences;

    ERC20_Token public token = new ERC20_Token(name, symbol, decimals);

    constructor() public {
        owner = msg.sender;
        createInfluencesFirst();
        token.mint(me, total); // mint totalSupply to ICO_contract
        token.finishMinting(); // close minting tokens. Only <total> supply.
    }

    function() external payable {
        uint amount = msg.value;
        checkValidMsg(amount);
        transferICO(amount);
    }

    function checkValidMsg(uint amount){
        if(isFinished){revert("ICO is CLOSED");}
        if(now < start  || ICOtimeLeftMinsICO() <= 0){revert("ICO interval error");}
        if(!(influences[msg.sender] > 0)){revert("Address not found in whitelists");}
        if(maxSellingInICO <= icoSellingAmount){revert("Ico tokens run out");}
        if(influences[msg.sender] < (msg.value + token.balanceOf(msg.sender))){revert("Your limit has been exceeded");}
        if(amount != 1 * sat && amount != 2 * sat && amount != 3 * sat){revert("Integer token only");}
    }

    function transferICO(uint amount){
        token.transfer(msg.sender, amount);
        icoSellingAmount += amount;
        if(icoSellingAmount >= maxSellingInICO){
            closeICO();
        }
    }

    function ICOtimeLeftMinsICO() public view returns (int256) {
       return int256(start) + int256(period) - int256(now);
    }

    function createInfluencesFirst() private {
        setInfluenece(0x7015E9C7e1e5c77Bff80Fe24A9b4F09436F4a729, 1);
        setInfluenece(0x46775b2583502dbe0f594C725C5944543f19682b, 2);
        setInfluenece(0x731966E2D7BE010F61FeBFdad9300b88105aBD10, 2);
        setInfluenece(0x38bbe82f6D16FB4538a389766a72C180F02E2C62, 2);
        setInfluenece(0x8F70b3aC45A6896532FB90B992D5B7827bA88d3C, 2);
        setInfluenece(0x475E5FbE12DA0C0b16EF7690172de84bdF75c105, 2);
        setInfluenece(0x29d6D6D84c9662486198667B5a9fbda3E698b23f, 2);
        setInfluenece(0xCCa178a04D83Af193330C7927fb9a42212Fb1C25, 2);
        setInfluenece(0x5D9E720a1c16B98ab897165803C4D96E8060b8E4, 2);
        setInfluenece(0x1d436c04aA4875866A14d124171eb3cB8564077b, 2);
        setInfluenece(0xc05062409B9768eD3Bd7b7cf19B46223C43647b7, 2);
        setInfluenece(0x7aE3869e4341B63a5bC54BA956Cc1D1eA6a09aa8, 2);
        setInfluenece(0xD26867ceb87f09674A5EF63f6b32b3cA5B89834C, 2);
        setInfluenece(0x5978aB98214eB021a5Ca763cCAc0c43a7e335d24, 2);
        setInfluenece(0x5598B05c9DE624cCAdc469fB6EBb8eF7EF95C3E0, 2);
        setInfluenece(0xa4985fD2F781f1716109cD3FF6e68D718B01C5fD, 2);
        setInfluenece(0x9Ae673c304EA6A4c2E5bf1E1A14D21d8696fAE2D, 2);
        setInfluenece(0xF44666a64167c7685Faa98C2E87Bee7ED145acb9, 2);
        setInfluenece(0x9dd21593E675048916d377fe28D1cb04B29a51C6, 2);
        setInfluenece(0xc62785b58724D744B843e479D76D47897E61Ca7e, 2);
        setInfluenece(0x0FBbCB08fc99f3402148c20017D9572Fb9205deE, 1);
        setInfluenece(0x84670177112E04cd2bDe4884f23C345CCCc12D9b, 1);
        setInfluenece(0xCA3989447c3858d8f69A42263134C3121644998C, 1);
    }

    function createInfluencesSecond() public onlyOwner {
        setInfluenece(0x308e2feC61005Dc01571b14ead4f1734E1070300, 1);
        setInfluenece(0xA50d9221452b0E8d8FeD126b4Ac8F8e4f3144553, 1);
        setInfluenece(0xF5ABB5f3Ec53A7304447b0F47E25406B1AaAa66e, 1);
        setInfluenece(0x928220Dd02606186BF03eB9EDDE989De97fd461e, 1);
        setInfluenece(0x735636618A390a769853ea07Bc13447683d2015C, 1);
        setInfluenece(0x5449A630D69375E2A7308ab375EAa5802B2C1bB3, 1);
        setInfluenece(0x6DCd311Cb7454f2656897d7b714bA0B909BC2622, 1);
        setInfluenece(0x657D7888f5b88c636aE7796075327cF5970623D9, 1);
        setInfluenece(0x42D455B219214FDA88aF47786CC6e3B5f9a19c37, 1);
        setInfluenece(0x81aa6141923ea42fcaa763d9857418224d9b025a, 1);
        setInfluenece(0x4a0573F70E77A28dd079C0e079174135Ab6B41c5, 1);
        setInfluenece(0x383BB8E06c838F2822477d5c8ebCd59d35a74E65, 1);
        setInfluenece(0x99A2fFEaF83acb11FFa9EE76821648cE96B29De0, 1);
        setInfluenece(0x4Ff5867b278c3650aAE0a9f264531Bd14036CD15, 1);
        setInfluenece(0x33f144Aa851e9e55b042f46014bb4F737Bc777BF, 1);
        setInfluenece(0x624C878f8097B26b3ef42adAf5f26E38854E5E90, 1);
        setInfluenece(0x9c08D7bB1493F3A8e26761D5363bDF1Bd7901Fb5, 1);
        setInfluenece(0x0c936869E30B0a7893897c3dA9555d44D2A0A1A2, 1);
        setInfluenece(0x4aD330E8B16BCb8546f99239e1E4D95280C93226, 1);
        setInfluenece(0xD6a6027D168cE1f8036D8d01c2918F8Cb610271b, 1);
        setInfluenece(0xBA682E593784f7654e4F92D58213dc495f229Eec, 1);
        setInfluenece(0x72ddC9807B1616e65777CC69f73ECc33C2925a83, 1);
        setInfluenece(0x6927DdbA18dca7B978a4B6f4334fAFFBd6bA3c94, 1);
        setInfluenece(0x88e21d089101632F086794Efb63E6E799865D7CC, 1);
        setInfluenece(0x346d7C121A5089ded561Fed4E7fABBBcffB6406C, 1);
        setInfluenece(0x4b1bA9aA4337e65ffA2155b92BaFd8E177E73CB5, 1);
        setInfluenece(0x2C7121dCbd8e2288cd3E181D2C3B2477527C3e81, 1);
        setInfluenece(0x847Eaa8E0a808305b00305DA61b875Dd2Ca3FbAc, 1);
        setInfluenece(0x7257b76281C2E2b4b04a6e2ab867928535C32041, 1);
        setInfluenece(0x0C745F54d6CC5aC370B296A3610a325307F568cC, 1);
        setInfluenece(0x24Ad08d9589D96152AcC5452fb212Bd291BbB06C, 1);
        setInfluenece(0x12042A785b8D3D9f8b24FDbEdd0c11B2B35dCFCE, 1);
        setInfluenece(0x5D9E720a1c16B98ab897165803C4D96E8060b8E4, 1);
        setInfluenece(0x986058cb8e7558d53f790d678f0f3696a328f5a3, 1);
        setInfluenece(0x5A1255d306BcdC140F42df5bE5140b0F3E95C4D3, 1);
        setInfluenece(0xEF505053cd6015a09029F274c42A7DCF5a9Cc795, 1);
        setInfluenece(0x57E55a3a3e3361E9480f9C0f4132c9AD72Ccd3E7, 1);
        setInfluenece(0xF1c0Aa21577a81E455Fedf81c3b3ba26552d5d1f, 1);
        setInfluenece(0x9ABAe20Af4afbd7BA2b78a4db34Dc4210390aAB4, 1);
        setInfluenece(0x05552F4D5D4ba2D583A363b0372b5ebC4499f7Aa, 1);
        setInfluenece(0x3a331AeAca46790817403340f909c10f77140104, 1);
        setInfluenece(0x11414661E194b8b0D7248E789c1d41332904f2bA, 1);
        setInfluenece(0xb98c26531A4FB84D5AB1778df9771A59A720adDA, 1);
        setInfluenece(0xbAfb40bd711eD1C864dF95055FBd6f82c0F3F0c0, 1);
        setInfluenece(0x24BA7f4547fe5d3EBec6041C7080E264C989580B, 1);
        setInfluenece(0xfce0413BAD4E59f55946669E678EccFe87777777, 1);
        setInfluenece(0x731C48ceDBC3E96b7BEbF976dFCb0C633C177ec2, 1);
        setInfluenece(0xBDECcDb60C2962AbaD2AbD3f28c7b5BC6B468022, 1);
        setInfluenece(0xAcb272Eac895FA57394747615fCb068b8858AAF2, 1);
        setInfluenece(0xd1c299B36d6Cb2c19Af6d441dA6ea98402Bd3536, 1);
        setInfluenece(0x78eadF65FB7f9738d566a71002f245fc39f6Eaa5, 1);
        setInfluenece(0x1d436c04aA4875866A14d124171eb3cB8564077b, 1);
        setInfluenece(0xD39eFeaC6dEB8C00e228E04953DA9AA0Ff572B25, 1);
        setInfluenece(0xAfB3dC27B39E4979802e95750E5d4a679c30a182, 1);
        setInfluenece(0x31E985b4f7af6B479148d260309B7BcEcEF0fa7B, 1);
        setInfluenece(0xFCd3086ccf0817BFF780f45e4070d7DB5530506d, 1);
        setInfluenece(0x477Bf09DDB3049c1265f6E11FD33267c1D74D901, 1);
        setInfluenece(0x61543790F9D85284c16b36c15dAb02Fb975CA38B, 1);
        setInfluenece(0xA9f72Bc6511630Ac118f351C7144a8a5060765C5, 1);
        setInfluenece(0xB75B4a9e80f335e102c45C188BFed10cFDB10BbF, 1);
        setInfluenece(0x74c229C733244676CC81F4A7d5BCDbFE98C02A10, 1);
        setInfluenece(0x897853510D7fb160045122934110a3197E0DF2DF, 1);
        setInfluenece(0xAeC6B35e91ce4878Bc556810dD659dABA5c00530, 1);
        setInfluenece(0x9dcD2A7b3FB0EF1705437441deE74f691447Bb36, 1);
        setInfluenece(0x9Df9E4D06ebBD5381dd3b561B52BfE2CE0788Ed8, 1);
        setInfluenece(0x09127c9f1aF963f06b643B966BAf6A1700DAa38F, 1);
        setInfluenece(0x2488f090656BddB63fe3Bdb506D0D109AaaD93Bb, 1);
        setInfluenece(0x0147d4286a65fbad86102263b2468dd06f06c9f8, 1);
        setInfluenece(0xA94b40c53432f0576E64873CE1CEAd1aae62Fc90, 1);
        setInfluenece(0xd108480f40cd5D9FC08c9F64919d801BE88aC86d, 1);
        setInfluenece(0xB14df4544D6FD08E55Be8bF96a6745cDDD47e80f, 1);
        setInfluenece(0xfDEd54FE11500A6FE983A2f37669e5323eCEE40d, 1);
        setInfluenece(0x1e8df76D0DfE06b351c0B58C35E28A1Cb93595e4, 1);
        setInfluenece(0xc55175f8BE83D0477713a5B9f64aC4b82438cA5A, 1);
        setInfluenece(0x8f43dE6EE8644C43D46254c919E5B00BcbdaA7B4, 1);
        setInfluenece(0xDa892C1700147079d0bDeafB7b566E77315f98A4, 1);
        setInfluenece(0x08D6f4Ca2D5bA6ec96F14B6BfaF9312Ff3FE8BE1, 1);
        setInfluenece(0x4b1bA9aA4337e65ffA2155b92BaFd8E177E73CB5, 1);
        setInfluenece(0x7563f9f3951851ce0089b8a3293bb177c41abe73, 1);
        setInfluenece(0x80ba68D6E7AC418e717467C38E6587EAA74a84b4, 1);
        setInfluenece(0xD837c32efB8D93C151C13b5a558531DEf5FF84f1, 1);
        setInfluenece(0xb9890DCcb98A6737Bd8d370146709D99904Ac123, 1);
        setInfluenece(0xd61366B8a5E140765297039d9449Dc7a6D07A3AB, 1);
        setInfluenece(0x57DEf117605A239cF2feDe21C7e14818C2376710, 1);
        setInfluenece(0xDa892C1700147079d0bDeafB7b566E77315f98A4, 1);
        setInfluenece(0xd2Fb5EAd3cA3644F70a1D17B89e40B9769c58D9c, 1);
        setInfluenece(0xBB181B1BD9ECb002c9b2Ff3356261F4F02ECfE12, 1);
        setInfluenece(0xe78A6F195a04969E9e1E68E92B72e38e7b1ae21A, 1);
        setInfluenece(0xb68c2f299D391C900e5C0c92027aC3cF3dC21188, 1);
        setInfluenece(0x50946E16bE370726eb7Bb3b98ADD977887cC8BE2, 2);
        setInfluenece(0xc1bb29ee5f546eb85780dbfe1027234287bc6f61, 1);
        setInfluenece(0x9fcf9B0A90Dbfe291421B65B249bCDc710cb8Fc0, 1);
        setInfluenece(0xe599125686200c27964BC6Db2C32e838321d91d3, 1);
        setInfluenece(0x1D496C150e4f8443058A6AFA090F442349E3f664, 1);
        setInfluenece(0x49A3D1Fc6f2fA558882B774De4760D79fFF06Ed3, 1);
        setInfluenece(0xee1BeBEa20aA68BA6f3B706B05cF19bf61210137, 1);
        setInfluenece(0x76B4b27B47f211448964eD2cf92F731412602700, 1);
        setInfluenece(0xCd0D4CDb238Eec15Fcf4ff9d13d5a59051E507D7, 1);
        setInfluenece(0x85c7D244c6057D42C770aD85aE198Fc5F47957fC, 1);
        setInfluenece(0x8f76516Df6Ca5AF18cdc176f55FC0E85d73d49Fc, 1);
        setInfluenece(0xbe05a4e64d947621FfE87ecD2Ae94578746b44b6, 1);
        setInfluenece(0x4A14B8A7C64C50e6DcF6E9BE71045322C7ad0479, 1);
        setInfluenece(0x5e4F13110a329d3E8f575Da56ED3689311F78C3f, 1);
        setInfluenece(0x572Ce5Fc4495278a5f5fe0e6975d96EE5B7097AD, 1);
        setInfluenece(0x011152ADCCe81034c7A9bb0cD7060b0865C871E7, 1);
        setInfluenece(0xE31f159dC48466312A63B0Cab5C01833dA185C51, 1);
        setInfluenece(0x9Ae74b7582A451b4b0564380AeFDf9e7a418F3f6, 1);
        setInfluenece(0x49522Dc3C008FE3A3a26a70569f6fa0B86Ae70E2, 1);
        setInfluenece(0x305995b71109D53b2CFa1F9f3952A54274fE818d, 1);
        setInfluenece(0x43D2e66971D96dDA47C476f5141a13DaC48cC9D3, 1);
        setInfluenece(0xDfd748eAb0F32c6056b63F83df85FF9EE050918a, 1);
        setInfluenece(0x87eD35c08D4aF834350879f062cC02064C17B421, 1);
        setInfluenece(0xD0436Abe9F371851CB76C8c5fFBA3c5520B44a54, 1);
        setInfluenece(0x7c359032a39E5E9D4680553E1256291FDe65cfaD, 1);
        setInfluenece(0x20a4937AD3143a79Aa3C9DA639e0130a5984a1f6, 1);
        setInfluenece(0x0BE74e970B209ce27Ee1C5d1924D3D422287088f, 1);
        setInfluenece(0x37f48060490EEADcE18Da8965139b4Af6AC1b3C6, 1);
        setInfluenece(0x252bc4533a551878E4b6354b6c0E38A1fd311713, 1);
        setInfluenece(0xb0DC5932E4C277f1eCac227AA629E04B9614c917, 1);
        setInfluenece(0x0De69e83Ba189689067AA64939cbAfE5c98f507e, 1);
        setInfluenece(0x7A166f2Fe92551d6058777367634aC0D471c9C80, 1);
        setInfluenece(0xa9903C6C0489d0eaDaf310088955bABd2607E87D, 1);
        setInfluenece(0xe9b4F7755F74bE4389f54e07c94d1541e27c2f33, 1);
        setInfluenece(0x306bF96102eBE58579dff7b3C3c54DC360BdDB30, 1);
        setInfluenece(0xDc6B8B33630FAdE4a11d5f52666a4c30Ac800363, 1);
        setInfluenece(0x5926A1534A8AFb400c806e4C21e2bBbee4a023b8, 1);
        setInfluenece(0x891E8ebd0430Ab4360b7B74996C2AEe650A960d9, 1);
        setInfluenece(0x27Be743f13d892B9CF55ae3Ef9997BF533C05aF8, 1);
        setInfluenece(0xA5b936cD0f1731748d59C74E9510D8046b1a08ac, 1);
        setInfluenece(0xae479FFEba84b5Dd5fBD81E4d4958a3cAEd7a08a, 1);
        setInfluenece(0xa985ECe5F6468C2857fAa62a23E9551d342f8813, 1);
        setInfluenece(0x4F1c6872B0da93bAC1e13C0b27f15863b798F905, 1);
        setInfluenece(0x1d453eBD3a30ED9897c9CeA5AAeFcdc00928c418, 1);
        setInfluenece(0x072A96d5f54eB25A81B06cD4D2a5BCc2203Be388, 1);
        setInfluenece(0x6a8Ef41601cE5498f577ce4c433846246754a1af, 1);
        setInfluenece(0x6d54EAb8814F5515a3360E1774A1a3CE211Fa5d4, 1);
        setInfluenece(0x323D65b33DEabdD13637e31e938C802B19f703ba, 1);
        setInfluenece(0x60575aE40bbf646AfAA9154d87674dbbF365A458, 1);
        setInfluenece(0xe2Eb79E6C6B478b46f4c12736D5b004b952E99c8, 1);
        setInfluenece(0x9C5Dd910FBB6de08A3806E894d260F88F990Feaf, 1);
        setInfluenece(0x9B55108f9D9C4E4bFfb4895e3033293aFCD4FA0d, 1);
        setInfluenece(0x476E366f170B2563ae1AaA68533B9623Da2d3BFE, 1);
        setInfluenece(0x1f19f9ffdc7f8c71c6b09d7c7349f0932229d401, 1);
        setInfluenece(0xc32f4f415a4de14f36180a1b67463459c49fd087, 1);
        setInfluenece(0xb412B96Dbe138DA98be8e475f632E1A8F0037748, 1);
        setInfluenece(0xa583944170F9fE5B7e60d20FA1315eF3AFCab6F9, 1);
        setInfluenece(0x6f07C85494ccF426c71e2B651ac4c71d7758a927, 1);
        setInfluenece(0xB9069e74869d3577d956b230c86F32620E4bF9a2, 1);
        setInfluenece(0xF1Ee6Eedc0C62fD2DfF153cc017733035cAc7C63, 1);
        setInfluenece(0xAfADB4763b17a16044E231399469d59e7D3c76A5, 1);
        setInfluenece(0x5B1b75427Bf32E32e0A601159C70Bf3101aD4228, 1);
        setInfluenece(0x01647edfd56e7ff582046626760fcbfa67cd730a, 1);
        setInfluenece(0x165E631b7e81Ea7D1Cee086506f9927d51927e3E, 1);
        setInfluenece(0xBCaccD141800Eb17A75B1967d52c6D3F6ab0AFfE, 1);
        setInfluenece(0x48c7D866455700611F124685c80110848cE32dD1, 1);
        setInfluenece(0xA4eea4Cf6a8e8603C95df7B058a08AF945d2A581, 1);
        setInfluenece(0xecbc7b98f1199b908803524f28a9b00bc5e4a4b2, 1);
        setInfluenece(0x01FeD7F61B379ad59D86a8f5B7A6edb95eBa3134, 1);
        setInfluenece(0xe01a23A71715D4c50A210C4FDeeBa97cFE1Ffb69, 1);
        setInfluenece(0x470d2c3f820421fAf7ADa94bF8DCfB6C6Ae1Ad91, 1);
        setInfluenece(0x6769737CACf3848C45E35b0B7351aBaB3c8273C1, 1);
        setInfluenece(0x8c11f8bC26D656D2f9953c1c0Dfb6d33175C3bea, 1);
        setInfluenece(0x1E70Be098b27846f0880b09dF9815dE0855E95A6, 1);
        setInfluenece(0x210A5d5d5971ad689F31B00426bb2FfF5a7da82F, 1);
        setInfluenece(0xFF63Ee71A7AfC1d36Eb60669eE4105cFB8064095, 1);
        setInfluenece(0x5B4d2B0c80b063f3e0922619AFa532a1AA410d06, 1);
        setInfluenece(0xf4CfE4452C38C8C62a72eD8F09D0a5667F231c28, 1);
        setInfluenece(0xf4CfE4452C38C8C62a72eD8F09D0a5667F231c28, 1);
        setInfluenece(0x5bA3EeD97C38473239cE0D0b674BeCACB0967f66, 1);
        setInfluenece(0xF56B186BF3267ba89DA1F362Cf76B3E8e9149daE, 1);
        setInfluenece(0x670C843B8b3DB24290Df89EbF05ce58E1b7b039A, 1);
        setInfluenece(0x763a0A26FbFaa15C37aE663f14ae465F78670837, 1);
        setInfluenece(0x2281ce5EA91e5a236aDb91039d28e4f70a717C01, 1);
        setInfluenece(0xD0f7458c7960f94446B7992E4C588eeA961aDAeE, 1);
        setInfluenece(0xa2044Fe01d17709662068E24ec3d766713608c1D, 1);
        setInfluenece(0xe69eD750187a1f92348A3Fbfd704331b353EA511, 1);
        setInfluenece(0x3dF72C5B92eA4549D77ec800FFaB38dC7ae5A6B4, 1);
        setInfluenece(0x9e8d49A606E252e251a02FF82Eab5a6C8C0f07E0, 1);
        setInfluenece(0xDB84275BC3fD83eeCDd58ce2C2dF7DB1BA23eeEd, 1);
        setInfluenece(0xd8EC8EdE99AF3adb8a25eCD7Ee17BdABC2c2326E, 1);
        setInfluenece(0x8452bB062d554f374b68D58D8406fdf7C7cE5994, 1);
        setInfluenece(0x98A97D1E73FAaabEdD29E6439f77e45DC0174471, 1);
        setInfluenece(0x38C160bC49Ab7e03913AAb72e88DF5CB9aF6AA9F, 1);
        setInfluenece(0xa46fAf198Fc3a6dE196dB8E36761EdFf02a9CA8B, 1);
    }

    function setInfluenece(address addr, uint amount) public onlyOwner {
        influences[addr] = amount * sat;
        capInICO += amount;
    }

    function closeICO() private {
       isFinished = true;
       token.transfer(owner, coinsAfterIcoAmountTeam);
       leftTokensAmountToTeamBlocked = total - coinsAfterIcoAmountTeam - icoSellingAmount;
       everyPeriodUnblockAmount = leftTokensAmountToTeamBlocked / partsAmountToTeam;
    }

    function nextUnblockSentTeamTokens() public onlyOwner {
        require(nextUnblockUnix < now, "nextUnblockUnix is not now");
        require(leftTokensAmountToTeamBlocked > 0, "leftTokensAmountToTeamBlocked = 0");
        if(token.balanceOf(me)  < everyPeriodUnblockAmount){
            everyPeriodUnblockAmount = token.balanceOf(me);
        }
        token.transfer(owner, everyPeriodUnblockAmount);
        nextUnblockUnix = now +  periodUnBlock;
        leftTokensAmountToTeamBlocked -= everyPeriodUnblockAmount;
    }

    function getETH() public onlyOwner payable {
        owner.transfer(me.balance);
    }

    function manualCloseIco(uint pass) onlyOwner public{
        require(pass == 5 && ICOtimeLeftMinsICO() <= 0 && !isFinished, "Require ICOtimeLeftMinsICO");
        closeICO();
    }

    function totalSupplyToken() public view returns (uint balance){
        return token.totalSupply() / sat;
    }

     // Development utils
    function myBalance() public view returns (uint balance){
        return token.balanceOf(msg.sender) / sat;
    }

    function showIsFinished() public view returns (bool){
        return isFinished;
    }
    function showIsfinishMinting()  public view returns (bool){
        return token.mintingFinished();
    }

    function getIcoETH() public view returns (uint){
        return me.balance;
    }
    function geLefttTokensAmountToTeamBlocked() public view returns (uint){
        return leftTokensAmountToTeamBlocked / sat;
    }
    function getNextUnblockUnixMins() public view returns (uint){
        return nextUnblockUnix - now;
    }
    function getCapInICO() public view returns (uint){
        return capInICO;
    }
    function getLeftToStart() public view returns (uint){
        return (start - now) / 1 minutes;
    }
    function getInfluencerAmount(address addr) public view returns (uint){
        return influences[addr] / sat;
    }
    function getIcoSellingAmount() public view returns (uint){
        return icoSellingAmount / sat;
    }

}