pragma solidity ^0.4.18;

// ----------------------------------------------------------------------------
//
// ZanteCoin smart contract
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

contract ZanteCoin is ERC20Coin {

    /* Basic coin data */

    string public constant name = "Zpay";
    string public constant symbol = "ZPAY";
    uint8  public constant decimals = 18;

    /* ICO dates */

    uint public constant DATE_ICO_START = 1521072000; // 15-Mar-2018 00:00 UTC
    uint public constant DATE_ICO_END   = 1531612800; // 15-Jul-2018 00:00 UTC

    /* Max ICO and other coin supply parameters */  

    uint public constant COIN_SUPPLY_ICO_PHASE_0 = 30000000 * 10**18;  //  30M coins Pre-ICO
    uint public constant COIN_SUPPLY_ICO_PHASE_1 = 70000000 * 10**18;  //  70M coins
    uint public constant COIN_SUPPLY_ICO_PHASE_2 = 200000000 * 10**18; // 200M coins
    uint public constant COIN_SUPPLY_ICO_PHASE_3 = 300000000 * 10**18; // 300M coins
    uint public constant COIN_SUPPLY_ICO_TOTAL   = 
        COIN_SUPPLY_ICO_PHASE_0
        + COIN_SUPPLY_ICO_PHASE_1
        + COIN_SUPPLY_ICO_PHASE_2
        + COIN_SUPPLY_ICO_PHASE_3;

    uint public constant COIN_SUPPLY_MKT_TOTAL = 600000000 * 10**18;

    uint public constant COIN_SUPPLY_COMPANY_TOTAL = 800000000 * 10**18;

    uint public constant COIN_SUPPLY_TOTAL = 
        COIN_SUPPLY_ICO_TOTAL
        + COIN_SUPPLY_MKT_TOTAL
        + COIN_SUPPLY_COMPANY_TOTAL;

    /* Other ICO parameters */  

    uint public constant MIN_CONTRIBUTION = 1 ether / 100; // 0.01 ether
    uint public constant MAX_CONTRIBUTION = 15610 ether;

    /* Current coin supply variables */

    uint public coinsIssuedIco = 0;
    uint public coinsIssuedMkt = 0;
    uint public coinsIssuedCmp = 0;  

    // Events ---------------------------

    event IcoCoinsIssued(address indexed _owner, uint _coins);
    event MarketingCoinsGranted(address indexed _participant, uint _coins, uint _balance);
    event CompanyCoinsGranted(address indexed _participant, uint _coins, uint _balance);

    // Basic Functions ------------------

    /* Initialize (owner is set to msg.sender by Owned.Owned() */

    function ZanteCoin() public {  }

    /* Fallback */

    function () public {
        // Not a payable to prevent ether transfers to this contract.
    }

    function issueIcoCoins(address _participant, uint _coins) public onlyOwner {
        // Check if enough supply remaining
        require(_coins <= COIN_SUPPLY_ICO_TOTAL.sub(coinsIssuedIco));

        // update balances
        balances[_participant] = balances[_participant].add(_coins);
        coinsIssuedIco = coinsIssuedIco.add(_coins);
        coinsIssuedTotal = coinsIssuedTotal.add(_coins);

        // log the minting
        Transfer(0x0, _participant, _coins);
        IcoCoinsIssued(_participant, _coins);
    }

    /* Granting / minting of marketing coins by owner */
    function grantMarketingCoins(address _participant, uint _coins) public onlyOwner {
        // check amount
        require(_coins <= COIN_SUPPLY_MKT_TOTAL.sub(coinsIssuedMkt));

        // update balances
        balances[_participant] = balances[_participant].add(_coins);
        coinsIssuedMkt = coinsIssuedMkt.add(_coins);
        coinsIssuedTotal = coinsIssuedTotal.add(_coins);

        // log the minting
        Transfer(0x0, _participant, _coins);
        MarketingCoinsGranted(_participant, _coins, balances[_participant]);
    }

    /* Granting / minting of Company bonus coins by owner */
    function grantCompanyCoins(address _participant, uint _coins) public onlyOwner {
        // check amount
        require(_coins <= COIN_SUPPLY_COMPANY_TOTAL.sub(coinsIssuedCmp));

        // update balances
        balances[_participant] = balances[_participant].add(_coins);
        coinsIssuedCmp = coinsIssuedCmp.add(_coins);
        coinsIssuedTotal = coinsIssuedTotal.add(_coins);

        // log the minting
        Transfer(0x0, _participant, _coins);
        CompanyCoinsGranted(_participant, _coins, balances[_participant]);
    }
}