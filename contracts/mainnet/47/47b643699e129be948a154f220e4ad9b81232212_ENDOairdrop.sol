// Congratulations! Its your free airdrop token! Get 6 USD in EToken FREE!
// Promocode: 6forfree
// More: tokensale.endo.im/promo/
// Join us: https://t.me/endo_en
// ENDO is a Protocol that solves the problem of certified information tracking and encrypted data storage. 
// The ENDO ecosystem allows organisations and users to participate in information and service exchange through the EToken.

// おめでとうございます！これはあなたの無料エアドロップのトークンとなります！EToken建ての6ドルを無償で獲得してください。
// プロモーションコード：6forfree　
// 詳細はこちら：tokensale.endo.im/promo/
// こちらの公式Telegramクループにご参加ください：https://t.me/endo_jp　
// ENDOとは認定された情報の追跡と暗号化されたデータの保管に関する問題を解決するプロトコルです。 
// ENDOエコシステムでは、ユーザーと企業がETokenを使用して情報の交換やサービスの受領を出来ます。

// 恭喜！ 它是你的免费空投代币！ 免费获得6美元的EToken！
// 促销代码：6forfree
// 更多：tokensale.endo.im/promo/
// 加入我们：https://t.me/endo_cn
// ENDO是一个解决认证信息跟踪和加密数据存储问题的协议。
// ENDO生态系统允许组织和用户通过EToken参与信息和服务交换。

// 축하합니다! 무료 에어드랍 토큰! EToken에서 6 받으세요!
// 프로모션 코드 : 6forfree
// 더보기 : tokensale.endo.im/promo/
// 우리와 함께하십시오 : https://t.me/endo_ko
// ENDO는 정보를 안전하게 공유하고 검증할 수 있도록 하는 프로젝트 입니다.
// ENDO 토큰으로 서류를 검증하고 암호화 할 수 있습니다.

// Поздравляем! Ваш персональный Airdrop уже готов! Получите 6 USD в эквиваленте EToken бесплатно!
// Промокод: 6forfree
// Узнать больше: tokensale.endo.im/promo/
// Присоединяйтесь к нам: https://t.me/endo_ru
// ENDO – это протокол, решающий проблему отслеживания подтвержденной информации и хранения зашифрованных данных. 
// Экосистема ENDO позволяет организациям и пользователям принимать участие в процессе обмены информацией и пользоваться услугами с помощью токена ENDO.


pragma solidity ^0.4.11;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public returns (uint256);
  //function transfer(address to, uint256 value) public returns(bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public returns (uint256);
  //function transferFrom(address from, address to, uint256 value) public returns(bool);
  //function approve(address spender, uint256 value) public returns(bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;
  mapping(address => uint256) balances;
  function transfer(address _to, uint256 _value) public {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }
  function balanceOf(address _owner) public returns (uint256 balance) {
    return balances[_owner];
  }
}
contract StandardToken is ERC20, BasicToken {
  mapping (address => mapping (address => uint256)) allowed;
  function transferFrom(address _from, address _to, uint256 _value) public {
    var _allowance = allowed[_from][msg.sender];
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }
  function approve(address _spender, uint256 _value) public {
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }
  function allowance(address _owner, address _spender) public returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}
contract Ownable {
  address public owner;
  function Ownable() public {
    owner = msg.sender;
  }
  modifier onlyOwner() {
    if (msg.sender != owner) {
      revert();
    }
    _;
  }
  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}
contract ETokenPromo is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  string public name = "ENDO.network Promo Token";
  string public symbol = "ETP";
  uint256 public decimals = 18;

  bool public mintingFinished = false;

  modifier canMint() {
    if(mintingFinished) revert();
    _;
  }

  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract ENDOairdrop {
  using SafeMath for uint256;

  ETokenPromo public token;
  
  uint256 public currentTokenCount;
  address public owner;
  uint256 public maxTokenCount;

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function ENDOairdrop() public {
    token = createTokenContract();
    owner = msg.sender;
  }
  
  function sendToken(address[] recipients, uint256 value) public {
    for (uint256 i = 0; i < recipients.length; i++) {
      token.mint(recipients[i], value);
    }
  }

  function createTokenContract() internal returns (ETokenPromo) {
    return new ETokenPromo();
  }

}