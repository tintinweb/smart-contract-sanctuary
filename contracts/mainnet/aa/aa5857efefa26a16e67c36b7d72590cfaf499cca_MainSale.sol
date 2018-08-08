pragma solidity ^0.4.13;


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
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
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
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
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


contract DisbursableToken is MintableToken {
  using SafeMath for uint256;

  struct Account {
    uint claimedPoints;
    uint allowedPoints;
    uint lastPointsPerToken;
  }

  event Disburse(address _source, uint _amount);
  event ClaimDisbursement(address _account, uint _amount);
  // The disbursement multiplier exists to correct rounding errors
  // One disbursed wei = 1e18 disbursement points
  uint pointMultiplier = 1e18;
  uint totalPointsPerToken;
  uint unclaimedDisbursement;
  uint totalDisbursement;

  mapping(address => Account) accounts;

  /**
   * @dev Function to send eth to owners of this token.
   */
  function disburse() public payable {
    totalPointsPerToken = totalPointsPerToken.add(msg.value.mul(pointMultiplier).div(totalSupply));
    unclaimedDisbursement = unclaimedDisbursement.add(msg.value);
    totalDisbursement = totalDisbursement.add(msg.value);
    Disburse(msg.sender, msg.value);
  }

  /**
   * @dev Function to update the claimable disbursements whenever tokens change hands
   * @param _account address The address whose claimable disbursements should be updated
   * @return A uint256 specifing the amount of wei still available for the owner.
   */
  function updatePoints(address _account) internal {
    uint newPointsPerToken = totalPointsPerToken.sub(accounts[_account].lastPointsPerToken);
    accounts[_account].allowedPoints = accounts[_account].allowedPoints.add(balances[_account].mul(newPointsPerToken));
    accounts[_account].lastPointsPerToken = totalPointsPerToken;
  }

  /**
   * @dev Function to check the amount of wei that a token owner can claim.
   * @param _owner address The address which owns the funds.
   * @return A uint256 specifing the amount of wei still available for the owner.
   */
  function claimable(address _owner) constant returns (uint256 remaining) {
    updatePoints(_owner);
    return accounts[_owner].allowedPoints.sub(accounts[_owner].claimedPoints).div(pointMultiplier);
  }

  /**
   * @dev Function to claim the wei that a token owner is entitled to
   * @param _amount uint256 How much of the wei the user will take
   */
  function claim(uint _amount) public {
    require(_amount > 0);
    updatePoints(msg.sender);
    uint claimingPoints = _amount.mul(pointMultiplier);
    require(accounts[msg.sender].claimedPoints.add(claimingPoints) <= accounts[msg.sender].allowedPoints);
    accounts[msg.sender].claimedPoints = accounts[msg.sender].claimedPoints.add(claimingPoints);
    ClaimDisbursement(msg.sender, _amount);
    require(msg.sender.send(_amount));
  }

  /**
   * @dev Function to mint tokens. We need to modify this to update points.
   * @param _to The address that will recieve the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    updatePoints(_to);
    super.mint(_to, _amount);
  }

  function transfer(address _to, uint _value) returns(bool) {
    updatePoints(msg.sender);
    updatePoints(_to);
    super.transfer(_to, _value);
  }

  /**
   * @dev Transfer tokens from one address to another while ensuring that claims remain where they are
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint _value) returns(bool) {
    updatePoints(_from);
    updatePoints(_to);
    super.transferFrom(_from, _to, _value);
  }
}


/**
 * @title Hero token
 * @dev This is the token being sold
 *
 * ABI
 * [{"constant":true,"inputs":[],"name":"mintingFinished","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_value","type":"uint256"}],"name":"approve","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_from","type":"address"},{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transferFrom","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"startTrading","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_amount","type":"uint256"}],"name":"claim","outputs":[],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"claimable","outputs":[{"name":"remaining","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_amount","type":"uint256"}],"name":"mint","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"tradingStarted","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"finishMinting","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transfer","outputs":[{"name":"","type":"bool"}],"payable":false,"type":"function"},{"constant":false,"inputs":[],"name":"disburse","outputs":[],"payable":true,"type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"},{"name":"_spender","type":"address"}],"name":"allowance","outputs":[{"name":"remaining","type":"uint256"}],"payable":false,"type":"function"},{"constant":false,"inputs":[{"name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"payable":false,"type":"function"},{"payable":true,"type":"fallback"},{"anonymous":false,"inputs":[{"indexed":false,"name":"_source","type":"address"},{"indexed":false,"name":"_amount","type":"uint256"}],"name":"Disburse","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"_account","type":"address"},{"indexed":false,"name":"_amount","type":"uint256"}],"name":"ClaimDisbursement","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"amount","type":"uint256"}],"name":"Mint","type":"event"},{"anonymous":false,"inputs":[],"name":"MintFinished","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"owner","type":"address"},{"indexed":true,"name":"spender","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Transfer","type":"event"}]
 */

contract HeroToken is DisbursableToken {
  string public name = "Hero Token";
  string public symbol = "HERO";
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
   * @dev Allows anyone to transfer the DEVE tokens once trading has started
   * @param _to the recipient address of the tokens.
   * @param _value number of tokens to be transfered.
   */
  function transfer(address _to, uint _value) hasStartedTrading returns(bool) {
    super.transfer(_to, _value);
  }

   /**
   * @dev Allows anyone to transfer the DEVE tokens once trading has started
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint _value) hasStartedTrading returns(bool) {
    super.transferFrom(_from, _to, _value);
  }

  function() external payable {
    disburse();
  }
}

/**
 * @title MainSale
 * @dev The main HERO token sale contract
 *
 * ABI
 * [{"constant":false,"inputs":[{"name":"_multisigVault","type":"address"}],"name":"setMultisigVault","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_minimum","type":"uint256"}],"name":"setMinimum","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"saleOngoing","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"exchangeRate","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"base","type":"uint256"}],"name":"bonusTokens","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"altDeposits","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"recipient","type":"address"},{"name":"tokens","type":"uint256"}],"name":"authorizedCreateTokens","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"minimum","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_saleOngoing","type":"bool"}],"name":"setSaleOngoing","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[],"name":"finishMinting","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"owner","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"totalAltDeposits","type":"uint256"}],"name":"setAltDeposits","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_token","type":"address"}],"name":"retrieveTokens","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"hardcap","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"start","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"recipient","type":"address"}],"name":"createTokens","outputs":[],"payable":true,"stateMutability":"payable","type":"function"},{"constant":true,"inputs":[],"name":"multisigVault","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_exchangeRate","type":"uint256"}],"name":"setExchangeRate","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_hardcap","type":"uint256"}],"name":"setHardcap","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":false,"inputs":[{"name":"_start","type":"uint256"}],"name":"setStart","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"token","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"payable":true,"stateMutability":"payable","type":"fallback"},{"anonymous":false,"inputs":[{"indexed":false,"name":"recipient","type":"address"},{"indexed":false,"name":"ether_amount","type":"uint256"},{"indexed":false,"name":"token_amount","type":"uint256"},{"indexed":false,"name":"exchangerate","type":"uint256"}],"name":"TokenSold","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"name":"recipient","type":"address"},{"indexed":false,"name":"token_amount","type":"uint256"}],"name":"AuthorizedCreate","type":"event"},{"anonymous":false,"inputs":[],"name":"MainSaleClosed","type":"event"}]
 */
contract MainSale is Ownable {
  using SafeMath for uint;
  event TokenSold(address recipient, uint ether_amount, uint token_amount, uint exchangerate);
  event AuthorizedCreate(address recipient, uint token_amount);
  event MainSaleClosed();

  HeroToken public token = new HeroToken();

  address public multisigVault = 0x877f1DAa6e6E9dc2764611D48c56172CE3547656;

  uint public hardcap = 250000 ether;
  uint public exchangeRate = 200;
  uint public minimum = 10 ether;

  uint public altDeposits = 0;
  uint public start = 1504266900; //new Date("September 1, 2017 19:55:00 GMT+8").getTime() / 1000
  bool public saleOngoing = true;

  /**
   * @dev modifier to allow token creation only when the sale IS ON
   */
  modifier isSaleOn() {
    require(start < now && saleOngoing && !token.mintingFinished());
    _;
  }

  /**
   * @dev modifier to prevent buying tokens below the minimum required
   */
  modifier isOverMinimum() {
    require(msg.value >= minimum);
    _;
  }

  /**
   * @dev modifier to allow token creation only when the hardcap has not been reached
   */
  modifier isUnderHardcap() {
    require(multisigVault.balance + altDeposits <= hardcap);
    _;
  }

  /*
   * @dev Allows anyone to create tokens by depositing ether.
   * @param recipient the recipient to receive tokens.
   */
  function createTokens(address recipient) public isOverMinimum isUnderHardcap isSaleOn payable {
    uint base = exchangeRate.mul(msg.value).mul(10**token.decimals()).div(1 ether);
    uint bonus = bonusTokens(base);
    uint tokens = base.add(bonus);
    token.mint(recipient, tokens);
    require(multisigVault.send(msg.value));
    TokenSold(recipient, msg.value, tokens, exchangeRate);
  }

  /**
   * @dev Computes the number of bonus tokens awarded based on the current time.
   * @param base the original number of tokens made without counting the bonus
   */
  function bonusTokens(uint base) constant returns(uint) {
    uint bonus = 0;
    if (now <= start + 3 hours) {
      bonus = base.mul(3).div(10);
    } else if (now <= start + 24 hours) {
      bonus = base.mul(2).div(10);
    } else if (now <= start + 3 days) {
      bonus = base.div(10);
    } else if (now <= start + 7 days) {
      bonus = base.div(20);
    } else if (now <= start + 14 days) {
      bonus = base.div(40);
    }
    return bonus;
  }

  /**
   * @dev Allows authorized acces to create tokens. This is used for Bitcoin and ERC20 deposits
   * @param recipient the recipient to receive tokens.
   * @param tokens number of tokens to be created.
   */
  function authorizedCreateTokens(address recipient, uint tokens) public onlyOwner {
    token.mint(recipient, tokens);
    AuthorizedCreate(recipient, tokens);
  }

  /**
   * @dev Allows the owner to set the starting time.
   * @param _start the new _start
   */
  function setStart(uint _start) public onlyOwner {
    start = _start;
  }

  /**
   * @dev Allows the owner to set the minimum purchase.
   * @param _minimum the new _minimum
   */
  function setMinimum(uint _minimum) public onlyOwner {
    minimum = _minimum;
  }

  /**
   * @dev Allows the owner to set the hardcap.
   * @param _hardcap the new hardcap
   */
  function setHardcap(uint _hardcap) public onlyOwner {
    hardcap = _hardcap;
  }

  /**
   * @dev Allows to set the toal alt deposit measured in ETH to make sure the hardcap includes other deposits
   * @param totalAltDeposits total amount ETH equivalent
   */
  function setAltDeposits(uint totalAltDeposits) public onlyOwner {
    altDeposits = totalAltDeposits;
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
   * @dev Allows the owner to set the exchange rate
   * @param _exchangeRate the exchangerate address
   */
  function setExchangeRate(uint _exchangeRate) public onlyOwner {
    exchangeRate = _exchangeRate;
  }

  /**
   * @dev Allows the owner to stop the sale
   * @param _saleOngoing whether the sale is ongoing or not
   */
  function setSaleOngoing(bool _saleOngoing) public onlyOwner {
    saleOngoing = _saleOngoing;
  }

  /**
   * @dev Allows the owner to finish the minting.
   * The ownership of the token contract is transfered
   * to this owner.
   */
  function finishMinting() public onlyOwner {
    token.finishMinting();
    token.transferOwnership(owner);
    MainSaleClosed();
  }

  /**
   * @dev Allows the owner to transfer ERC20 tokens to the multi sig vault
   * @param _token the contract address of the ERC20 contract
   */
  function retrieveTokens(address _token) public onlyOwner {
    ERC20 foreignToken = ERC20(_token);
    foreignToken.transfer(multisigVault, foreignToken.balanceOf(this));
  }

  /**
   * @dev Fallback function which receives ether and created the appropriate number of tokens for the
   * msg.sender.
   */
  function() external payable {
    createTokens(msg.sender);
  }
}