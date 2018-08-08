pragma solidity ^0.4.11;

/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
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
    if (msg.sender != owner) {
      throw;
    }
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to. 
   */
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value);
  function approve(address spender, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint256 size) {
     if(msg.data.length < size + 4) {
       throw;
     }
     _;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
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
 * @dev Implemantation of the basic standart token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is BasicToken, ERC20 {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }

  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on beahlf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }

  /**
   * @dev Function to check the amount of tokens than an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

contract CryptoABS is StandardToken, Ownable {
  string public name;                                   // 名稱
  string public symbol;                                 // token 代號
  uint256 public decimals = 0;                          // decimals
  address public contractAddress;                       // contract address

  uint256 public minInvestInWei;                        // 最低投資金額 in wei
  uint256 public tokenExchangeRateInWei;                // 1 Token = n ETH in wei

  uint256 public startBlock;                            // ICO 起始的 block number
  uint256 public endBlock;                              // ICO 結束的 block number
  uint256 public maxTokenSupply;                        // ICO 的 max token，透過 USD to ETH 換算出來
  
  uint256 public initializedTime;                       // 起始時間，合約部署的時候會寫入
  uint256 public financingPeriod;                       // token 籌資期間
  uint256 public tokenLockoutPeriod;                    // token 閉鎖期，閉鎖期內不得 transfer
  uint256 public tokenMaturityPeriod;                   // token 到期日

  bool public paused;                                   // 暫停合約功能執行
  bool public initialized;                              // 合約啟動
  uint256 public finalizedBlock;                        // 合約終止投資的區塊編號
  uint256 public finalizedTime;                         // 合約終止投資的時間
  uint256 public finalizedCapital;                      // 合約到期的 ETH 金額

  struct ExchangeRate {
    uint256 blockNumber;                                // block number
    uint256 exchangeRateInWei;                          // 1 USD = n ETH in wei, 派發利息使用的利率基準
  }

  ExchangeRate[] public exchangeRateArray;              // exchange rate array
  uint256 public nextExchangeRateIndex;                 // exchange rate last index
  
  uint256[] public interestArray;                       // interest array

  struct Payee {
    bool isExists;                                      // payee 存在
    bool isPayable;                                     // payee 允許領錢
    uint256 interestInWei;                              // 待領利息金額
  }

  mapping (address => Payee) public payees; 
  address[] public payeeArray;                          // payee array
  uint256 public nextPayeeIndex;                        // payee deposite interest index

  struct Asset {
    string data;                                        // asset data
  }

  Asset[] public assetArray;                            // asset array

  /**
   * @dev Throws if contract paused.
   */
  modifier notPaused() {
    require(paused == false);
    _;
  }

  /**
   * @dev Throws if contract is paused.
   */
  modifier isPaused() {
    require(paused == true);
    _;
  }

  /**
   * @dev Throws if not a payee. 
   */
  modifier isPayee() {
    require(payees[msg.sender].isPayable == true);
    _;
  }

  /**
   * @dev Throws if contract not initialized. 
   */
  modifier isInitialized() {
    require(initialized == true);
    _;
  }

  /**
   * @dev Throws if contract not open. 
   */
  modifier isContractOpen() {
    require(
      getBlockNumber() >= startBlock &&
      getBlockNumber() <= endBlock &&
      finalizedBlock == 0);
    _;
  }

  /**
   * @dev Throws if token in lockout period. 
   */
  modifier notLockout() {
    require(now > (initializedTime + financingPeriod + tokenLockoutPeriod));
    _;
  }
  
  /**
   * @dev Throws if not over maturity date. 
   */
  modifier overMaturity() {
    require(now > (initializedTime + financingPeriod + tokenMaturityPeriod));
    _;
  }

  /**
   * @dev Contract constructor.
   */
  function CryptoABS() {
    paused = false;
  }

  /**
   * @dev Initialize contract with inital parameters. 
   * @param _name name of token
   * @param _symbol symbol of token
   * @param _contractAddress contract deployed address
   * @param _startBlock start block number
   * @param _endBlock end block number
   * @param _initializedTime contract initalized time
   * @param _financingPeriod contract financing period
   * @param _tokenLockoutPeriod contract token lockout period
   * @param _tokenMaturityPeriod contract token maturity period
   * @param _minInvestInWei minimum wei accept of invest
   * @param _maxTokenSupply maximum toke supply
   * @param _tokenExchangeRateInWei token exchange rate in wei
   * @param _exchangeRateInWei eth exchange rate in wei
   */
  function initialize(
      string _name,
      string _symbol,
      uint256 _decimals,
      address _contractAddress,
      uint256 _startBlock,
      uint256 _endBlock,
      uint256 _initializedTime,
      uint256 _financingPeriod,
      uint256 _tokenLockoutPeriod,
      uint256 _tokenMaturityPeriod,
      uint256 _minInvestInWei,
      uint256 _maxTokenSupply,
      uint256 _tokenExchangeRateInWei,
      uint256 _exchangeRateInWei) onlyOwner {
    require(bytes(name).length == 0);
    require(bytes(symbol).length == 0);
    require(decimals == 0);
    require(contractAddress == 0x0);
    require(totalSupply == 0);
    require(decimals == 0);
    require(_startBlock >= getBlockNumber());
    require(_startBlock < _endBlock);
    require(financingPeriod == 0);
    require(tokenLockoutPeriod == 0);
    require(tokenMaturityPeriod == 0);
    require(initializedTime == 0);
    require(_maxTokenSupply >= totalSupply);
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    contractAddress = _contractAddress;
    startBlock = _startBlock;
    endBlock = _endBlock;
    initializedTime = _initializedTime;
    financingPeriod = _financingPeriod;
    tokenLockoutPeriod = _tokenLockoutPeriod;
    tokenMaturityPeriod = _tokenMaturityPeriod;
    minInvestInWei = _minInvestInWei;
    maxTokenSupply = _maxTokenSupply;
    tokenExchangeRateInWei = _tokenExchangeRateInWei;
    ownerSetExchangeRateInWei(_exchangeRateInWei);
    initialized = true;
  }

  /**
   * @dev Finalize contract
   */
  function finalize() public isInitialized {
    require(getBlockNumber() >= startBlock);
    require(msg.sender == owner || getBlockNumber() > endBlock);

    finalizedBlock = getBlockNumber();
    finalizedTime = now;

    Finalized();
  }

  /**
   * @dev fallback function accept ether
   */
  function () payable notPaused {
    proxyPayment(msg.sender);
  }

  /**
   * @dev payment function, transfer eth to token
   * @param _payee The payee address
   */
  function proxyPayment(address _payee) public payable notPaused isInitialized isContractOpen returns (bool) {
    require(msg.value > 0);

    uint256 amount = msg.value;
    require(amount >= minInvestInWei); 

    uint256 refund = amount % tokenExchangeRateInWei;
    uint256 tokens = (amount - refund) / tokenExchangeRateInWei;
    require(totalSupply.add(tokens) <= maxTokenSupply);
    totalSupply = totalSupply.add(tokens);
    balances[_payee] = balances[_payee].add(tokens);

    if (payees[msg.sender].isExists != true) {
      payees[msg.sender].isExists = true;
      payees[msg.sender].isPayable = true;
      payeeArray.push(msg.sender);
    }

    require(owner.send(amount - refund));
    if (refund > 0) {
      require(msg.sender.send(refund));
    }
    return true;
  }

  /**
   * @dev transfer token
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   */
  function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) notLockout notPaused isInitialized {
    require(_to != contractAddress);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    if (payees[_to].isExists != true) {
      payees[_to].isExists = true;
      payees[_to].isPayable = true;
      payeeArray.push(_to);
    }
    Transfer(msg.sender, _to, _value);
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) notLockout notPaused isInitialized {
    require(_to != contractAddress);
    require(_from != contractAddress);
    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // if (_value > _allowance) throw;
    require(_allowance >= _value);

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    if (payees[_to].isExists != true) {
      payees[_to].isExists = true;
      payees[_to].isPayable = true;
      payeeArray.push(_to);
    }
    Transfer(_from, _to, _value);
  }

  /**
   * @dev add interest to each payees
   */
  function ownerDepositInterest() onlyOwner isPaused isInitialized {
    uint256 i = nextPayeeIndex;
    uint256 payeesLength = payeeArray.length;
    while (i < payeesLength && msg.gas > 2000000) {
      address _payee = payeeArray[i];
      uint256 _balance = balances[_payee];
      if (payees[_payee].isPayable == true && _balance > 0) {
        uint256 _interestInWei = (_balance * interestArray[getInterestCount() - 1]) / totalSupply;
        payees[_payee].interestInWei += _interestInWei;
        DepositInterest(getInterestCount(), _payee, _balance, _interestInWei);
      }
      i++;
    }
    nextPayeeIndex = i;
  }

  /**
   * @dev return interest by address, unit `wei`
   * @param _address The payee address
   */
  function interestOf(address _address) isInitialized constant returns (uint256 result)  {
    require(payees[_address].isExists == true);
    return payees[_address].interestInWei;
  }

  /**
   * @dev withdraw interest by payee
   * @param _interestInWei Withdraw interest amount in wei
   */
  function payeeWithdrawInterest(uint256 _interestInWei) payable isPayee isInitialized notLockout {
    require(msg.value == 0);
    uint256 interestInWei = _interestInWei;
    require(payees[msg.sender].isPayable == true && _interestInWei <= payees[msg.sender].interestInWei);
    require(msg.sender.send(interestInWei));
    payees[msg.sender].interestInWei -= interestInWei;
    PayeeWithdrawInterest(msg.sender, interestInWei, payees[msg.sender].interestInWei);
  }

  /**
   * @dev withdraw capital by payee
   */
  function payeeWithdrawCapital() payable isPayee isPaused isInitialized overMaturity {
    require(msg.value == 0);
    require(balances[msg.sender] > 0 && totalSupply > 0);
    uint256 capital = (balances[msg.sender] * finalizedCapital) / totalSupply;
    balances[msg.sender] = 0;
    require(msg.sender.send(capital));
    PayeeWithdrawCapital(msg.sender, capital);
  }

  /**
   * @dev pause contract
   */
  function ownerPauseContract() onlyOwner {
    paused = true;
  }

  /**
   * @dev resume contract
   */
  function ownerResumeContract() onlyOwner {
    paused = false;
  }

  /**
   * @dev set exchange rate in wei, 1 Token = n ETH in wei
   * @param _exchangeRateInWei change rate of ether
   */
  function ownerSetExchangeRateInWei(uint256 _exchangeRateInWei) onlyOwner {
    require(_exchangeRateInWei > 0);
    var _exchangeRate = ExchangeRate( getBlockNumber(), _exchangeRateInWei);
    exchangeRateArray.push(_exchangeRate);
    nextExchangeRateIndex = exchangeRateArray.length;
  }

  /**
   * @dev disable single payee in emergency
   * @param _address Disable payee address
   */
  function ownerDisablePayee(address _address) onlyOwner {
    require(_address != owner);
    payees[_address].isPayable = false;
  }

  /**
   * @dev enable single payee
   * @param _address Enable payee address
   */
  function ownerEnablePayee(address _address) onlyOwner {
    payees[_address].isPayable = true;
  }

  /**
   * @dev get payee count
   */
  function getPayeeCount() constant returns (uint256) {
    return payeeArray.length;
  }

  /**
   * @dev get block number
   */
  function getBlockNumber() internal constant returns (uint256) {
    return block.number;
  }

  /**
   * @dev add asset data, audit information
   * @param _data asset data
   */
  function ownerAddAsset(string _data) onlyOwner {
    var _asset = Asset(_data);
    assetArray.push(_asset);
  }

  /**
   * @dev get asset count
   */
  function getAssetCount() constant returns (uint256 result) {
    return assetArray.length;
  }

  /**
   * @dev put all capital in this contract
   */
  function ownerPutCapital() payable isInitialized isPaused onlyOwner {
    require(msg.value > 0);
    finalizedCapital = msg.value;
  }

  /**
   * @dev put interest in this contract
   * @param _terms Number of interest
   */
  function ownerPutInterest(uint256 _terms) payable isInitialized isPaused onlyOwner {
    require(_terms == (getInterestCount() + 1));
    interestArray.push(msg.value);
  }

  /**
   * @dev get interest count
   */
  function getInterestCount() constant returns (uint256 result) {
    return interestArray.length;
  }

  /**
   * @dev withdraw balance from contract if emergency
   */
  function ownerWithdraw() payable isInitialized onlyOwner {
    require(owner.send(this.balance));
  }

  event PayeeWithdrawCapital(address _payee, uint256 _capital);
  event PayeeWithdrawInterest(address _payee, uint256 _interest, uint256 _remainInterest);
  event DepositInterest(uint256 _terms, address _payee, uint256 _balance, uint256 _interest);
  event Finalized();
}