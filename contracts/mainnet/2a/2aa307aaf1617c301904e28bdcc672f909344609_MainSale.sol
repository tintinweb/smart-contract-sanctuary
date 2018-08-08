pragma solidity 0.4.11;


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
 * @title Authorizable
 * @dev Allows to authorize access to certain function calls
 * 
 * ABI
 * [{"constant":true,"inputs":[{"name":"authorizerIndex","type":"uint256"}],"name":"getAuthorizer","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_addr","type":"address"}],"name":"addAuthorized","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_addr","type":"address"}],"name":"isAuthorized","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"inputs":[],"payable":false,"type":"constructor"}]
 */
contract Authorizable {

  address[] authorizers;
  mapping(address => uint) authorizerIndex;

  /**
   * @dev Throws if called by any account tat is not authorized. 
   */
  modifier onlyAuthorized {
    require(isAuthorized(msg.sender));
    _;
  }

  /**
   * @dev Contructor that authorizes the msg.sender. 
   */
  function Authorizable() {
    authorizers.length = 2;
    authorizers[1] = msg.sender;
    authorizerIndex[msg.sender] = 1;
  }

  /**
   * @dev Function to get a specific authorizer
   * @param authorizerIndex index of the authorizer to be retrieved.
   * @return The address of the authorizer.
   */
  function getAuthorizer(uint authorizerIndex) external constant returns(address) {
    return address(authorizers[authorizerIndex + 1]);
  }

  /**
   * @dev Function to check if an address is authorized
   * @param _addr the address to check if it is authorized.
   * @return boolean flag if address is authorized.
   */
  function isAuthorized(address _addr) constant returns(bool) {
    return authorizerIndex[_addr] > 0;
  }

  /**
   * @dev Function to add a new authorizer
   * @param _addr the address to add as a new authorizer.
   */
  function addAuthorized(address _addr) external onlyAuthorized {
    authorizerIndex[_addr] = authorizers.length;
    authorizers.length++;
    authorizers[authorizers.length - 1] = _addr;
  }

}

/**
 * @title ExchangeRate
 * @dev Allows updating and retrieveing of Conversion Rates for PAY tokens
 *
 * ABI
 * [{"constant":false,"inputs":[{"name":"_symbol","type":"string"},{"name":"_rate","type":"uint256"}],"name":"updateRate","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"data","type":"uint256[]"}],"name":"updateRates","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_symbol","type":"string"}],"name":"getRate","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"","type":"bytes32"}],"name":"rates","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"payable":false,"type":"function"},{"anonymous":false,"inputs":[{"indexed":false,"name":"timestamp","type":"uint256"},{"indexed":false,"name":"symbol","type":"bytes32"},{"indexed":false,"name":"rate","type":"uint256"}],"name":"RateUpdated","type":"event"}]
 */
contract ExchangeRate is Ownable {

  event RateUpdated(uint timestamp, bytes32 symbol, uint rate);

  mapping(bytes32 => uint) public rates;

  /**
   * @dev Allows the current owner to update a single rate.
   * @param _symbol The symbol to be updated. 
   * @param _rate the rate for the symbol. 
   */
  function updateRate(string _symbol, uint _rate) public onlyOwner {
    rates[sha3(_symbol)] = _rate;
    RateUpdated(now, sha3(_symbol), _rate);
  }

  /**
   * @dev Allows the current owner to update multiple rates.
   * @param data an array that alternates sha3 hashes of the symbol and the corresponding rate . 
   */
  function updateRates(uint[] data) public onlyOwner {
    if (data.length % 2 > 0)
      throw;
    uint i = 0;
    while (i < data.length / 2) {
      bytes32 symbol = bytes32(data[i * 2]);
      uint rate = data[i * 2 + 1];
      rates[symbol] = rate;
      RateUpdated(now, symbol, rate);
      i++;
    }
  }

  /**
   * @dev Allows the anyone to read the current rate.
   * @param _symbol the symbol to be retrieved. 
   */
  function getRate(string _symbol) public constant returns(uint) {
    return rates[sha3(_symbol)];
  }

}

/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
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

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
}




/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}




/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances. 
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

  /**
   * @dev Fix for the ERC20 short address attack.
   */
  modifier onlyPayloadSize(uint size) {
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
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint balance) {
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

  mapping (address => mapping (address => uint)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
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
  function approve(address _spender, uint _value) {

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
   * @return A uint specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}






/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint value);
  event MintFinished();

  bool public mintingFinished = false;
  uint public totalSupply = 0;


  modifier canMint() {
    if(mintingFinished) throw;
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}


/**
 * @title PayToken
 * @dev The main PAY token contract
 * 
 * ABI 
 * [{"constant":true,"inputs":[],"name":"mintingFinished","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_value","type":"uint256"}],"name":"approve","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_from","type":"address"},{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transferFrom","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"startTrading","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_amount","type":"uint256"}],"name":"mint","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"tradingStarted","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"finishMinting","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transfer","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"},{"name":"_spender","type":"address"}],"name":"allowance","outputs":[{"name":"remaining","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"payable":false,"type":"function"},{"anonymous":false,"inputs":[{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Mint","type":"event"},{"anonymous":false,"inputs":[],"name":"MintFinished","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"owner","type":"address"},{"indexed":true,"name":"spender","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Transfer","type":"event"}]
 */
contract IceToken is MintableToken {

  string public name = "Ice Token";
  string public symbol = "ICE";
  uint public decimals = 18;

  bool public tradingStarted = false;

  /**
   * @dev modifier that throws if trading has not started yet
   */
  modifier hasStartedTrading() {
    require(tradingStarted);
    _;
  }

  /**
   * @dev Allows the owner to enable the trading. This can not be undone
   */
  function startTrading() onlyOwner {
    tradingStarted = true;
  }

  /**
   * @dev Allows anyone to transfer the PAY tokens once trading has started
   * @param _to the recipient address of the tokens. 
   * @param _value number of tokens to be transfered. 
   */
  function transfer(address _to, uint _value) hasStartedTrading {
    super.transfer(_to, _value);
  }

   /**
   * @dev Allows anyone to transfer the PAY tokens once trading has started
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint _value) hasStartedTrading {
    super.transferFrom(_from, _to, _value);
  }

}


/**
 * @title MainSale
 * @dev The main token sale contract
 * 
 * ABI
 * [{"constant":false,"inputs":[{"name":"_multisigVault","type":"address"}],"name":"setMultisigVault","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"authorizerIndex","type":"uint256"}],"name":"getAuthorizer","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"exchangeRate","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"altDeposits","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"recipient","type":"address"},{"name":"tokens","type":"uint256"}],"name":"authorizedCreateTokens","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"finishMinting","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_exchangeRate","type":"address"}],"name":"setExchangeRate","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_token","type":"address"}],"name":"retrieveTokens","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"totalAltDeposits","type":"uint256"}],"name":"setAltDeposit","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"start","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"recipient","type":"address"}],"name":"createTokens","outputs":[],"payable":true,"type":"function"},{"constant":false,"inputs":[{"name":"_addr","type":"address"}],"name":"addAuthorized","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"multisigVault","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_hardcap","type":"uint256"}],"name":"setHardCap","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_start","type":"uint256"}],"name":"setStart","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"token","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_addr","type":"address"}],"name":"isAuthorized","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"payable":true,"type":"fallback"},{"anonymous":false,"inputs":[{"indexed":false,"name":"recipient","type":"address"},{"indexed":false,"name":"ether_amount","type":"uint256"},{"indexed":false,"name":"pay_amount","type":"uint256"},{"indexed":false,"name":"exchangerate","type":"uint256"}],"name":"TokenSold","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"recipient","type":"address"},{"indexed":false,"name":"pay_amount","type":"uint256"}],"name":"AuthorizedCreate","type":"event"},{"anonymous":false,"inputs":[],"name":"MainSaleClosed","type":"event"}]
 */
contract MainSale is Ownable, Authorizable {
  using SafeMath for uint;
  event TokenSold(address recipient, uint ether_amount, uint pay_amount, uint exchangerate);
  event AuthorizedCreate(address recipient, uint pay_amount);
  event MainSaleClosed();

  IceToken public token = new IceToken();

  address public multisigVault;

  uint hardcap = 2000 ether;
  ExchangeRate public exchangeRate;

  uint public altDeposits = 0;
  uint public start = 1498302000; //new Date("Jun 24 2017 11:00:00 GMT").getTime() / 1000

  /**
   * @dev modifier to allow token creation only when the sale IS ON
   */
  modifier saleIsOn() {
    require(now > start && now < start + 365 days);
    _;
  }

  /**
   * @dev modifier to allow token creation only when the hardcap has not been reached
   */
  modifier isUnderHardCap() {
    require(multisigVault.balance + altDeposits <= hardcap);
    _;
  }

  /**
   * @dev Allows anyone to create tokens by depositing ether.
   * @param recipient the recipient to receive tokens. 
   */
  function createTokens(address recipient) public isUnderHardCap saleIsOn payable {
    uint rate = exchangeRate.getRate("ETH");
    uint tokens = rate.mul(msg.value).div(1 ether);
    token.mint(recipient, tokens);
    require(multisigVault.send(msg.value));
    TokenSold(recipient, msg.value, tokens, rate);
  }


  function transferTokenOwnership() public onlyOwner {
    token.transferOwnership(owner);
  }

  /**
   * @dev Allows to set the toal alt deposit measured in ETH to make sure the hardcap includes other deposits
   * @param totalAltDeposits total amount ETH equivalent
   */
  function setAltDeposit(uint totalAltDeposits) public onlyOwner {
    altDeposits = totalAltDeposits;
  }

  /**
   * @dev Allows authorized acces to create tokens. This is used for Bitcoin and ERC20 deposits
   * @param recipient the recipient to receive tokens.
   * @param tokens number of tokens to be created. 
   */
  function authorizedCreateTokens(address recipient, uint tokens) public onlyAuthorized {
    token.mint(recipient, tokens);
    AuthorizedCreate(recipient, tokens);
  }

  /**
   * @dev Allows the owner to set the hardcap.
   * @param _hardcap the new hardcap
   */
  function setHardCap(uint _hardcap) public onlyOwner {
    hardcap = _hardcap;
  }

  /**
   * @dev Allows the owner to set the starting time.
   * @param _start the new _start
   */
  function setStart(uint _start) public onlyOwner {
    start = _start;
  }

  /**
   * @dev Allows the owner to set the multisig contract.
   * @param _multisigVault the multisig contract address
   */
  function setMultisigVault(address _multisigVault) public onlyOwner {
    if (_multisigVault != address(0)) {
      multisigVault = _multisigVault;
    }
  }

  /**
   * @dev Allows the owner to set the exchangerate contract.
   * @param _exchangeRate the exchangerate address
   */
  function setExchangeRate(address _exchangeRate) public onlyOwner {
    exchangeRate = ExchangeRate(_exchangeRate);
  }

  /**
   * @dev Allows the owner to finish the minting. This will create the 
   * restricted tokens and then close the minting.
   * Then the ownership of the PAY token contract is transfered 
   * to this owner.
   */
  function finishMinting() public onlyOwner {
    uint issuedTokenSupply = token.totalSupply();
    uint restrictedTokens = issuedTokenSupply.mul(49).div(51);
    token.mint(multisigVault, restrictedTokens);
    token.finishMinting();
    token.transferOwnership(owner);
    MainSaleClosed();
  }

  /**
   * @dev Allows the owner to transfer ERC20 tokens to the multi sig vault
   * @param _token the contract address of the ERC20 contract
   */
  function retrieveTokens(address _token) public onlyOwner {
    ERC20 token = ERC20(_token);
    token.transfer(multisigVault, token.balanceOf(this));
  }

  /**
   * @dev Fallback function which receives ether and created the appropriate number of tokens for the 
   * msg.sender.
   */
  function() external payable {
    createTokens(msg.sender);
  }

}