pragma solidity ^0.4.18;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address owner) public constant returns (uint256 balance);
  function transfer(address to, uint256 value) public returns (bool success);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256 remaining);
  function transferFrom(address from, address to, uint256 value) public returns (bool success);
  function approve(address spender, uint256 value) public returns (bool success);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
    
  using SafeMath for uint256;
 
  mapping (address => uint256) public balances;
 
  function transfer(address _to, uint256 _value) public returns (bool) {
    require (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to] && _value > 0 && _to != address(this) && _to != address(0)); 
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;
 
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to] && _value > 0 && _to != address(this) && _to != address(0));
    uint _allowance = allowed[_from][msg.sender];
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
      require (((_value == 0) || (allowed[msg.sender][_spender] == 0)) && _spender != address(this) && _spender != address(0));
      allowed[msg.sender][_spender] = _value;
      Approval(msg.sender, _spender, _value);
      return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
 
}

contract UNICToken is owned, StandardToken {
    
  string public constant name = &#39;UNIC Token&#39;;
  string public constant symbol = &#39;UNIC&#39;;
  uint8 public constant decimals = 18;
  uint256 public constant initialSupply = 250000000 * 10 ** uint256(decimals);

  function UNICToken() public onlyOwner {
    totalSupply = initialSupply;
    balances[msg.sender] = initialSupply;
  }

}

contract Crowdsale is owned, UNICToken {
    
  using SafeMath for uint;
  
  UNICToken public token = new UNICToken();

  address constant multisig = 0x867570869f8a46c685A51EE87b5D979A6ef657A9;
  uint constant rate = 3400;

  uint256 public constant forSale = 55000000 * 10 ** uint256(decimals);

  uint public constant presaleWhitelistDiscount = 40;
  uint public presaleWhitelistTokensLimit = 750000 * 10 ** uint256(decimals);

  uint public constant presaleStart = 1520503200;           /** 08.03 */
  uint public constant presaleEnd = 1521453600;             /** 19.03 */
  uint public constant presaleDiscount = 30;
  uint public presaleTokensLimit = 5000000 * 10 ** uint256(decimals);

  uint public constant firstRoundICOStart = 1522317600;      /** 29.03 */
  uint public constant firstRoundICOEnd = 1523527200;        /** 12.04 */
  uint public constant firstRoundICODiscount = 20;
  uint public firstRoundICOTokensLimit = 6250000 * 10 ** uint256(decimals);

  uint public constant secondRoundICOStart = 1524736800;     /** 26.04 */
  uint public constant secondRoundICOEnd = 1526551200;       /** 17.05 */
  uint public constant secondRoundICODiscount = 10;
  uint public secondRoundICOTokensLimit = 43750000 * 10 ** uint256(decimals);

  uint public constant presaleFemaleStart = 1520467200;       /** 08.03 */
  uint public constant presaleFemaleEnd = 1520553600;         /** 09.03 */
  uint public constant presaleFemaleDiscount = 88;
  uint public presaleFemaleTokensLimit = 88888 * 10 ** uint256(decimals);  

  uint public constant presalePiStart = 1520985600;           /** 14.03 The day of number PI */
  uint public constant presalePiEnd = 1521072000;             /** 15.03 */
  uint public constant presalePiDiscount = 34;
  uint public presalePiTokensLimit = 31415926535897932384626;

  uint public constant firstRoundWMStart = 1522800000;           /** 04.04 The Day of webmaster 404 */
  uint public constant firstRoundWMEnd = 1522886400;             /** 05.04 */
  uint public constant firstRoundWMDiscount = 25;
  uint public firstRoundWMTokensLimit = 404404 * 10 ** uint256(decimals);

  uint public constant firstRoundCosmosStart = 1523491200;       /** 12.04 The day of cosmonautics */
  uint public constant firstRoundCosmosEnd = 1523577600;         /** 13.04 */
  uint public constant firstRoundCosmosDiscount = 25;
  uint public firstRoundCosmosTokensLimit = 121961 * 10 ** uint256(decimals);

  uint public constant secondRoundMayStart = 1525132800;          /** 01.05 International Solidarity Day for Workers */
  uint public constant secondRoundMayEnd = 1525219200;            /** 02.05 */
  uint public constant secondRoundMayDiscount = 15;
  uint public secondRoundMayTokensLimit = 1111111 * 10 ** uint256(decimals);

  uint public etherRaised = 0;
  uint public tokensSold = 0;

  address public icoManager;
    
  mapping (address => bool) public WhiteList;
  mapping (address => bool) public Females;

  mapping (address => bool) public KYC1;
  mapping (address => bool) public KYC2;
  mapping (address => uint256) public KYCLimit;
  uint256 public constant KYCLimitValue = 1.5 ether;

  modifier onlyManager() {
    require(msg.sender == icoManager);
    _;
  }

  function setICOManager(address _newIcoManager) public onlyOwner returns (bool) {
    require(_newIcoManager != address(0));
    icoManager = _newIcoManager;
    return true;
  }

  function massPay(address[] dests, uint256 value) public onlyOwner returns (bool) {
    uint256 i = 0;
    uint256 toSend = value * 10 ** uint256(decimals);
    while (i < dests.length) {
      if(dests[i] != address(0)){
        transfer(dests[i], toSend);
      }
      i++;
    }
    return true;
  }

  function Crowdsale() public onlyOwner {
    token = UNICToken(this);
    balances[msg.sender] = balances[msg.sender].sub(forSale);
    balances[token] = balances[token].add(forSale);
  }

  function setParams(address[] dests, uint _type) internal {
    uint256 i = 0;
    while (i < dests.length) {
      if(dests[i] != address(0)){
        if(_type==1){
          WhiteList[dests[i]] = true;
        }else if(_type==2){
          Females[dests[i]] = true;
        }else if(_type==3){
          KYC1[dests[i]] = true;
          KYCLimit[dests[i]] = KYCLimitValue;
        }else if(_type==4){
          KYC2[dests[i]] = true;
        }
      }
      i++;
    }
  } 

  function setWhiteList(address[] dests) onlyManager external {
    setParams(dests, 1);
  }

  function setFemaleBonus(address[] dests) onlyManager external {
    setParams(dests, 2);
  }

  function setKYCLimited(address[] dests) onlyManager external {
    setParams(dests, 3);
  }

  function setKYCFull(address[] dests) onlyManager external {
    setParams(dests, 4);
  }

  function isPresale() internal view returns (bool) {
    return now >= presaleStart && now <= presaleEnd;
  }

  function isFirstRound() internal view returns (bool) {
    return now >= firstRoundICOStart && now <= firstRoundICOEnd;
  }

  function isSecondRound() internal view returns (bool) {
    return now >= secondRoundICOStart && now <= secondRoundICOEnd;
  }

  modifier saleIsOn() {
    require(isPresale() || isFirstRound() || isSecondRound());
    _;
  }

  function isFemaleSale() internal view returns (bool) {
    return now >= presaleFemaleStart && now <= presaleFemaleEnd;
  }

  function isPiSale() internal view returns (bool) {
    return now >= presalePiStart && now <= presalePiEnd;
  }

  function isWMSale() internal view returns (bool) {
    return now >= firstRoundWMStart && now <= firstRoundWMEnd;
  }

  function isCosmosSale() internal view returns (bool) {
    return now >= firstRoundCosmosStart && now <= firstRoundCosmosEnd;
  }

  function isMaySale() internal view returns (bool) {
    return now >= secondRoundMayStart && now <= secondRoundMayEnd;
  }

  function discount(uint _discount, uint _limit, uint _saleLimit, uint _value, uint _defultDiscount) internal pure returns(uint){
    uint tmpDiscount = _value.mul(_discount).div(100);
    uint newValue = _value.add(tmpDiscount);
    if(_limit >= newValue && _saleLimit >= newValue) {
      return tmpDiscount;
    }else{
      return _defultDiscount;
    }
  }

  function() external payable {
    buyTokens(msg.sender);
  }

  function buyTokens(address _buyer) saleIsOn public payable {
    assert((_buyer != address(0) && msg.value > 0 && ((KYC1[_buyer] && msg.value < KYCLimitValue) || KYC2[_buyer])));
    assert((KYC2[_buyer] || (KYC1[_buyer] && msg.value < KYCLimit[_buyer])));

    uint tokens = rate.mul(msg.value);
    uint discountTokens = 0;
    
    if (isPresale()) {

      discountTokens = discount(presaleDiscount, presaleTokensLimit, presaleTokensLimit, tokens, discountTokens);

      if(isFemaleSale() && Females[_buyer]) {
        discountTokens = discount(presaleFemaleDiscount, presaleFemaleTokensLimit, presaleTokensLimit, tokens, discountTokens);
      }
      if(WhiteList[_buyer]) {
        discountTokens = discount(presaleWhitelistDiscount, presaleWhitelistTokensLimit, presaleTokensLimit, tokens, discountTokens);
      }
      if(isPiSale()) {
        discountTokens = discount(presalePiDiscount, presalePiTokensLimit, presaleTokensLimit, tokens, discountTokens);
      }

    } else if (isFirstRound()) {

      discountTokens = discount(firstRoundICODiscount, firstRoundICOTokensLimit, firstRoundICOTokensLimit, tokens, discountTokens);

      if(isCosmosSale()) {
        discountTokens = discount(firstRoundCosmosDiscount, firstRoundCosmosTokensLimit, firstRoundICOTokensLimit, tokens, discountTokens);
      }
      if(isWMSale()) {
        discountTokens = discount(firstRoundWMDiscount, firstRoundWMTokensLimit, firstRoundICOTokensLimit, tokens, discountTokens);
      } 

    } else if (isSecondRound()) {

      discountTokens = discount(secondRoundICODiscount, secondRoundICOTokensLimit, secondRoundICOTokensLimit, tokens, discountTokens);

      if(isMaySale()) {
        discountTokens = discount(secondRoundMayDiscount, secondRoundMayTokensLimit, secondRoundICOTokensLimit, tokens, discountTokens);
      }

    }
        
    uint tokensWithBonus = tokens.add(discountTokens);
      
    if((isPresale() && presaleTokensLimit >= tokensWithBonus) ||
      (isFirstRound() && firstRoundICOTokensLimit >=  tokensWithBonus) ||
      (isSecondRound() && secondRoundICOTokensLimit >= tokensWithBonus)){
      
      multisig.transfer(msg.value);
      etherRaised = etherRaised.add(msg.value);
      token.transfer(msg.sender, tokensWithBonus);
      tokensSold = tokensSold.add(tokensWithBonus);

      if(KYC1[_buyer]){
        KYCLimit[_buyer] = KYCLimit[_buyer].sub(msg.value);
      }

      if (isPresale()) {
        
        presaleTokensLimit = presaleTokensLimit.sub(tokensWithBonus);
        
        if(WhiteList[_buyer]) {
          presaleWhitelistTokensLimit = presaleWhitelistTokensLimit.sub(tokensWithBonus);
        }
      
        if(isFemaleSale() && Females[_buyer]) {
          presaleFemaleTokensLimit = presaleFemaleTokensLimit.sub(tokensWithBonus);
        }

        if(isPiSale()) {
          presalePiTokensLimit = presalePiTokensLimit.sub(tokensWithBonus);
        }

      } else if (isFirstRound()) {

        firstRoundICOTokensLimit = firstRoundICOTokensLimit.sub(tokensWithBonus);
        
        if(isWMSale()) {
          firstRoundWMTokensLimit = firstRoundWMTokensLimit.sub(tokensWithBonus);
        }
      
        if(isCosmosSale()) {
          firstRoundCosmosTokensLimit = firstRoundCosmosTokensLimit.sub(tokensWithBonus);
        }

      } else if (isSecondRound()) {

        secondRoundICOTokensLimit = secondRoundICOTokensLimit.sub(tokensWithBonus);

        if(isMaySale()) {
          secondRoundMayTokensLimit = secondRoundMayTokensLimit.sub(tokensWithBonus);
        }

      }

    }

  }

}