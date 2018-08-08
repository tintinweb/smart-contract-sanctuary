pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
//
// krypteum public sale contract
//
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
//
// Owned contract
//
// ----------------------------------------------------------------------------

contract Owned {

  address public owner;
  address public newOwner;

  // Events ---------------------------

  event OwnershipTransferProposed(address indexed _from, address indexed _to);
  event OwnershipTransferred(address indexed _from, address indexed _to);

  // Modifier -------------------------

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  // Functions ------------------------

  function Owned() public {
    owner = msg.sender;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != owner);
    require(_newOwner != address(0x0));
    OwnershipTransferProposed(owner, _newOwner);
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    require(msg.sender == newOwner);
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

// ----------------------------------------------------------------------------
//
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
//
// ----------------------------------------------------------------------------

contract ERC20Interface {

  // Events ---------------------------

  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);

  // Functions ------------------------

  function totalSupply() public constant returns (uint);
  function balanceOf(address _owner) public constant returns (uint balance);
  function transfer(address _to, uint _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint _value) public returns (bool success);
  function approve(address _spender, uint _value) public returns (bool success);
  function allowance(address _owner, address _spender) public constant returns (uint remaining);

}

// ----------------------------------------------------------------------------
//
// ERC Coin Standard #20
//
// ----------------------------------------------------------------------------

contract ERC20Coin is ERC20Interface, Owned {
  
  using SafeMath for uint;

  uint public coinsIssuedTotal = 0;
  mapping(address => uint) public balances;
  mapping(address => mapping (address => uint)) public allowed;

  // Functions ------------------------

  /* Total coin supply */

  function totalSupply() public constant returns (uint) {
    return coinsIssuedTotal;
  }

  /* Get the account balance for an address */

  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }

  /* Transfer the balance from owner&#39;s account to another account */

  function transfer(address _to, uint _amount) public returns (bool success) {
    // amount sent cannot exceed balance
    require(balances[msg.sender] >= _amount);

    // update balances
    balances[msg.sender] = balances[msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);

    // log event
    Transfer(msg.sender, _to, _amount);
    return true;
  }

  /* Allow _spender to withdraw from your account up to _amount */

  function approve(address _spender, uint _amount) public returns (bool success) {
    // approval amount cannot exceed the balance
    require (balances[msg.sender] >= _amount);
      
    // update allowed amount
    allowed[msg.sender][_spender] = _amount;
    
    // log event
    Approval(msg.sender, _spender, _amount);
    return true;
  }

  /* Spender of coins transfers coins from the owner&#39;s balance */
  /* Must be pre-approved by owner */

  function transferFrom(address _from, address _to, uint _amount) public returns (bool success) {
    // balance checks
    require(balances[_from] >= _amount);
    require(allowed[_from][msg.sender] >= _amount);

    // update balances and allowed amount
    balances[_from] = balances[_from].sub(_amount);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
    balances[_to] = balances[_to].add(_amount);

    // log event
    Transfer(_from, _to, _amount);
    return true;
  }

  /* Returns the amount of coins approved by the owner */
  /* that can be transferred by spender */

  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}

contract krypteum is ERC20Coin {

  /* Basic coin data */

  string public constant name = "krypteum";
  string public constant symbol = "KTM";
  uint8  public constant decimals = 2;

  /* Wallet and Admin addresses - initially set to owner at deployment */

  address public wallet;
  address public administrator;

  /* ICO dates */

  uint public constant DATE_ICO_START = 1518480000; // 13-Feb-2018 00:00 GMT
  uint public constant DATE_ICO_END   = 1522713540; // 2-Apr-2018 23:59 GMT

  /* ICO coins per ETH */
  uint public constant COIN_COST_ICO_TIER_1 = 110 finney; // 0.11 ETH
  uint public constant COIN_COST_ICO_TIER_2 = 120 finney; // 0.12 ETH
  uint public constant COIN_COST_ICO_TIER_3 = 130 finney; // 0.13 ETH

  /* ICO and other coin supply parameters */

  uint public constant COIN_SUPPLY_ICO_TIER_1 = 50000; // 50K coins
  uint public constant COIN_SUPPLY_ICO_TIER_2 = 25000; // 25K coins
  uint public constant COIN_SUPPLY_ICO_TIER_3 = 25000; // 25K coins
  uint public constant COIN_SUPPLY_ICO_TOTAL =         // 100K coins
    COIN_SUPPLY_ICO_TIER_1 + COIN_SUPPLY_ICO_TIER_2 + COIN_SUPPLY_ICO_TIER_3;

  uint public constant COIN_SUPPLY_MARKETING_TOTAL =   200000; // 200K coins

  /* Other ICO parameters */

  uint public constant COOLDOWN_PERIOD =  24 hours;

  /* Crowdsale variables */

  uint public icoEtherReceived = 0; // Ether actually received by the contract
  uint public coinsIssuedMkt = 0;
  uint public coinsIssuedIco  = 0;
  uint[] public numberOfCoinsAvailableInIcoTier;
  uint[] public costOfACoinInWeiForTier;

  /* Keep track of Ether contributed and coins received during Crowdsale */

  mapping(address => uint) public icoEtherContributed;
  mapping(address => uint) public icoCoinsReceived;

  /* Keep track of participants who
  /* - have reclaimed their contributions in case of failed Crowdsale */
  /* - are locked */

  mapping(address => bool) public locked;

  // Events ---------------------------

  event WalletUpdated(address _newWallet);
  event AdministratorUpdated(address _newAdministrator);
  event CoinsMinted(address indexed _owner, uint _coins, uint _balance);
  event CoinsIssued(address indexed _owner, uint _coins, uint _balance, uint _etherContributed);
  event LockRemoved(address indexed _participant);

  // Basic Functions ------------------

  /* Initialize (owner is set to msg.sender by Owned.Owned() */

  function krypteum() public {
    wallet = owner;
    administrator = owner;

    numberOfCoinsAvailableInIcoTier.length = 3;
    numberOfCoinsAvailableInIcoTier[0] = COIN_SUPPLY_ICO_TIER_1;
    numberOfCoinsAvailableInIcoTier[1] = COIN_SUPPLY_ICO_TIER_2;
    numberOfCoinsAvailableInIcoTier[2] = COIN_SUPPLY_ICO_TIER_3;

    costOfACoinInWeiForTier.length = 3;
    costOfACoinInWeiForTier[0] = COIN_COST_ICO_TIER_1;
    costOfACoinInWeiForTier[1] = COIN_COST_ICO_TIER_2;
    costOfACoinInWeiForTier[2] = COIN_COST_ICO_TIER_3;
  }

  /* Fallback */

  function () public payable {
    buyCoins();
  }

  // Information functions ------------

  /* What time is it? */

  function atNow() public constant returns (uint) {
    return now;
  }

    /* Are coins transferable? */

  function isTransferable() public constant returns (bool transferable) {
      return atNow() >= DATE_ICO_END + COOLDOWN_PERIOD;
  }

  // Lock functions -------------------

  /* Manage locked */

  function removeLock(address _participant) public {
    require(msg.sender == administrator || msg.sender == owner);

    locked[_participant] = false;
    LockRemoved(_participant);
  }

  function removeLockMultiple(address[] _participants) public {
    require(msg.sender == administrator || msg.sender == owner);

    for (uint i = 0; i < _participants.length; i++) {
      locked[_participants[i]] = false;
      LockRemoved(_participants[i]);
    }
  }

  // Owner Functions ------------------

  /* Change the crowdsale wallet address */

  function setWallet(address _wallet) public onlyOwner {
    require(_wallet != address(0x0));
    wallet = _wallet;
    WalletUpdated(wallet);
  }

  /* Change the administrator address */

  function setAdministrator(address _admin) public onlyOwner {
    require(_admin != address(0x0));
    administrator = _admin;
    AdministratorUpdated(administrator);
  }

  /* Granting / minting of marketing coins by owner */

  function grantCoins(address _participant, uint _coins) public onlyOwner {
    // check amount
    require(_coins <= COIN_SUPPLY_MARKETING_TOTAL.sub(coinsIssuedMkt));

    // update balances
    balances[_participant] = balances[_participant].add(_coins);
    coinsIssuedMkt = coinsIssuedMkt.add(_coins);
    coinsIssuedTotal = coinsIssuedTotal.add(_coins);

    // locked
    locked[_participant] = true;

    // log the minting
    Transfer(0x0, _participant, _coins);
    CoinsMinted(_participant, _coins, balances[_participant]);
  }

  /* Transfer out any accidentally sent ERC20 tokens */

  function transferAnyERC20Token(address tokenAddress, uint amount) public onlyOwner returns (bool success) {
      return ERC20Interface(tokenAddress).transfer(owner, amount);
  }

  // Private functions ----------------

  /* Accept ETH during crowdsale (called by default function) */

  function buyCoins() private {
    uint ts = atNow();
    uint coins = 0;
    uint change = 0;

    // check dates for ICO
    require(DATE_ICO_START < ts && ts < DATE_ICO_END);

    (coins, change) = calculateCoinsPerWeiAndUpdateAvailableIcoCoins(msg.value);

    // ICO coins are available to be sold.
    require(coins > 0);

    // ICO coin volume cap
    require(coinsIssuedIco.add(coins).add(sumOfAvailableIcoCoins()) == COIN_SUPPLY_ICO_TOTAL);

    // change is not given back unless we&#39;re selling the last available ICO coins.
    require(change == 0 || coinsIssuedIco.add(coins) == COIN_SUPPLY_ICO_TOTAL);

    // register coins
    balances[msg.sender] = balances[msg.sender].add(coins);
    icoCoinsReceived[msg.sender] = icoCoinsReceived[msg.sender].add(coins);
    coinsIssuedIco = coinsIssuedIco.add(coins);
    coinsIssuedTotal = coinsIssuedTotal.add(coins);

    // register Ether
    icoEtherReceived = icoEtherReceived.add(msg.value).sub(change);
    icoEtherContributed[msg.sender] = icoEtherContributed[msg.sender].add(msg.value).sub(change);

    // locked
    locked[msg.sender] = true;

    // log coin issuance
    Transfer(0x0, msg.sender, coins);
    CoinsIssued(msg.sender, coins, balances[msg.sender], msg.value.sub(change));

    // return a change if not enough ICO coins left
    if (change > 0)
       msg.sender.transfer(change);

    wallet.transfer(this.balance);
  }

  function sumOfAvailableIcoCoins() internal constant returns (uint totalAvailableIcoCoins) {
    totalAvailableIcoCoins = 0;
    for (uint8 i = 0; i < numberOfCoinsAvailableInIcoTier.length; i++) {
      totalAvailableIcoCoins = totalAvailableIcoCoins.add(numberOfCoinsAvailableInIcoTier[i]);
    }
  }

  function calculateCoinsPerWeiAndUpdateAvailableIcoCoins(uint value) internal returns (uint coins, uint change) {
    coins = 0;
    change = value;

    for (uint8 i = 0; i < numberOfCoinsAvailableInIcoTier.length; i++) {
      uint costOfAvailableCoinsInCurrentTier = numberOfCoinsAvailableInIcoTier[i].mul(costOfACoinInWeiForTier[i]);

      if (change <= costOfAvailableCoinsInCurrentTier) {
        uint coinsInCurrentTierToBuy = change.div(costOfACoinInWeiForTier[i]);
        coins = coins.add(coinsInCurrentTierToBuy);
        numberOfCoinsAvailableInIcoTier[i] = numberOfCoinsAvailableInIcoTier[i].sub(coinsInCurrentTierToBuy);
        change = 0;
        break;
      }

      coins = coins.add(numberOfCoinsAvailableInIcoTier[i]);
      change = change.sub(costOfAvailableCoinsInCurrentTier);
      numberOfCoinsAvailableInIcoTier[i] = 0;
    }
  }

  // ERC20 functions ------------------

  /* Override "transfer" (ERC20) */

  function transfer(address _to, uint _amount) public returns (bool success) {
    require(isTransferable());
    require(locked[msg.sender] == false);
    require(locked[_to] == false);

    return super.transfer(_to, _amount);
  }

  /* Override "transferFrom" (ERC20) */

  function transferFrom(address _from, address _to, uint _amount) public returns (bool success) {
    require(isTransferable());
    require(locked[_from] == false);
    require(locked[_to] == false);

    return super.transferFrom(_from, _to, _amount);
  }

  // External functions ---------------

  /* Multiple coin transfers from one address to save gas */
  /* (longer _amounts array not accepted = sanity check) */

  function transferMultiple(address[] _addresses, uint[] _amounts) external {
    require(isTransferable());
    require(locked[msg.sender] == false);
    require(_addresses.length == _amounts.length);

    for (uint i = 0; i < _addresses.length; i++) {
      if (locked[_addresses[i]] == false)
         super.transfer(_addresses[i], _amounts[i]);
    }
  }
}