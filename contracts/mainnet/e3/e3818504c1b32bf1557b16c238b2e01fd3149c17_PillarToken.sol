pragma solidity ^0.4.11;


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

contract TeamAllocation is Ownable {
  using SafeMath for uint;
  //uint public constant lockedTeamAllocationTokens = 16000000;
  uint public unlockedAt;
  PillarToken plr;
  mapping (address => uint) allocations;
  uint tokensCreated = 0;
  uint constant public lockedTeamAllocationTokens = 16000000e18;
  //address of the team storage vault
  address public teamStorageVault = 0x3f5D90D5Cc0652AAa40519114D007Bf119Afe1Cf;

  function TeamAllocation() {
    plr = PillarToken(msg.sender);
    // Locked time of approximately 9 months before team members are able to redeeem tokens.
    uint nineMonths = 9 * 30 days;
    unlockedAt = now.add(nineMonths);
    //2% tokens from the Marketing bucket which are locked for 9 months
    allocations[teamStorageVault] = lockedTeamAllocationTokens;
  }

  function getTotalAllocation() returns (uint){
      return lockedTeamAllocationTokens;
  }

  function unlock() external payable {
    if (now < unlockedAt) throw;

    if (tokensCreated == 0) {
      tokensCreated = plr.balanceOf(this);
    }
    //transfer the locked tokens to the teamStorageAddress
    plr.transfer(teamStorageVault, tokensCreated);
  }
}

contract UnsoldAllocation is Ownable {
  using SafeMath for uint;
  uint unlockedAt;
  uint allocatedTokens;
  PillarToken plr;
  mapping (address => uint) allocations;

  uint tokensCreated = 0;

  /*
    Split among team members
    Tokens reserved for Team: 1,000,000
    Tokens reserved for 20|30 projects: 1,000,000
    Tokens reserved for future sale: 1,000,000
  */

  function UnsoldAllocation(uint _lockTime, address _owner, uint _tokens) {
    if(_lockTime == 0) throw;

    if(_owner == address(0)) throw;

    plr = PillarToken(msg.sender);
    uint lockTime = _lockTime * 1 years;
    unlockedAt = now.add(lockTime);
    allocatedTokens = _tokens;
    allocations[_owner] = _tokens;
  }

  function getTotalAllocation()returns(uint){
      return allocatedTokens;
  }

  function unlock() external payable {
    if (now < unlockedAt) throw;

    if (tokensCreated == 0) {
      tokensCreated = plr.balanceOf(this);
    }

    var allocation = allocations[msg.sender];
    allocations[msg.sender] = 0;
    var toTransfer = (tokensCreated.mul(allocation)).div(allocatedTokens);
    plr.transfer(msg.sender, toTransfer);
  }
}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev modifier to allow actions only when the contract IS paused
   */
  modifier whenNotPaused() {
    if (paused) throw;
    _;
  }

  /**
   * @dev modifier to allow actions only when the contract IS NOT paused
   */
  modifier whenPaused {
    if (!paused) throw;
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
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

/// @title PillarToken - Crowdfunding code for the Pillar Project
/// @author Parthasarathy Ramanujam, Gustavo Guimaraes, Ronak Thacker
contract PillarToken is StandardToken, Ownable {

    using SafeMath for uint;
    string public constant name = "PILLAR";
    string public constant symbol = "PLR";
    uint public constant decimals = 18;

    TeamAllocation public teamAllocation;
    UnsoldAllocation public unsoldTokens;
    UnsoldAllocation public twentyThirtyAllocation;
    UnsoldAllocation public futureSaleAllocation;

    uint constant public minTokensForSale  = 32000000e18;

    uint constant public maxPresaleTokens             =  48000000e18;
    uint constant public totalAvailableForSale        = 528000000e18;
    uint constant public futureTokens                 = 120000000e18;
    uint constant public twentyThirtyTokens           =  80000000e18;
    uint constant public lockedTeamAllocationTokens   =  16000000e18;
    uint constant public unlockedTeamAllocationTokens =   8000000e18;

    address public unlockedTeamStorageVault = 0x4162Ad6EEc341e438eAbe85f52a941B078210819;
    address public twentyThirtyVault = 0xe72bA5c6F63Ddd395DF9582800E2821cE5a05D75;
    address public futureSaleVault = 0xf0231160Bd1a2a2D25aed2F11B8360EbF56F6153;
    address unsoldVault;

    //Storage years
    uint constant coldStorageYears = 10;
    uint constant futureStorageYears = 3;

    uint totalPresale = 0;

    // Funding amount in ether
    uint public constant tokenPrice  = 0.0005 ether;

    // Multisigwallet where the proceeds will be stored.
    address public pillarTokenFactory;

    uint fundingStartBlock;
    uint fundingStopBlock;

    // flags whether ICO is afoot.
    bool fundingMode;

    //total used tokens
    uint totalUsedTokens;

    event Refund(address indexed _from,uint256 _value);
    event Migrate(address indexed _from, address indexed _to, uint256 _value);
    event MoneyAddedForRefund(address _from, uint256 _value,uint256 _total);

    modifier isNotFundable() {
        if (fundingMode) throw;
        _;
    }

    modifier isFundable() {
        if (!fundingMode) throw;
        _;
    }

    //@notice  Constructor of PillarToken
    //@param `_pillarTokenFactory` - multisigwallet address to store proceeds.
    //@param `_icedWallet` - Multisigwallet address to which unsold tokens are assigned
    function PillarToken(address _pillarTokenFactory, address _icedWallet) {
      if(_pillarTokenFactory == address(0)) throw;
      if(_icedWallet == address(0)) throw;

      pillarTokenFactory = _pillarTokenFactory;
      totalUsedTokens = 0;
      totalSupply = 800000000e18;
      unsoldVault = _icedWallet;

      //allot 8 million of the 24 million marketing tokens to an address
      balances[unlockedTeamStorageVault] = unlockedTeamAllocationTokens;

      //allocate tokens for 2030 wallet locked in for 3 years
      futureSaleAllocation = new UnsoldAllocation(futureStorageYears,futureSaleVault,futureTokens);
      balances[address(futureSaleAllocation)] = futureTokens;

      //allocate tokens for future wallet locked in for 3 years
      twentyThirtyAllocation = new UnsoldAllocation(futureStorageYears,twentyThirtyVault,twentyThirtyTokens);
      balances[address(twentyThirtyAllocation)] = twentyThirtyTokens;

      fundingMode = false;
    }

    //@notice Fallback function that accepts the ether and allocates tokens to
    //the msg.sender corresponding to msg.value
    function() payable isFundable external {
      purchase();
    }

    //@notice function that accepts the ether and allocates tokens to
    //the msg.sender corresponding to msg.value
    function purchase() payable isFundable {
      if(block.number < fundingStartBlock) throw;
      if(block.number > fundingStopBlock) throw;
      if(totalUsedTokens >= totalAvailableForSale) throw;

      if (msg.value < tokenPrice) throw;

      uint numTokens = msg.value.div(tokenPrice);
      if(numTokens < 1) throw;
      //transfer money to PillarTokenFactory MultisigWallet
      pillarTokenFactory.transfer(msg.value);

      uint tokens = numTokens.mul(1e18);
      totalUsedTokens = totalUsedTokens.add(tokens);
      if (totalUsedTokens > totalAvailableForSale) throw;

      balances[msg.sender] = balances[msg.sender].add(tokens);

      //fire the event notifying the transfer of tokens
      Transfer(0, msg.sender, tokens);
    }

    //@notice Function reports the number of tokens available for sale
    function numberOfTokensLeft() constant returns (uint256) {
      uint tokensAvailableForSale = totalAvailableForSale.sub(totalUsedTokens);
      return tokensAvailableForSale;
    }

    //@notice Finalize the ICO, send team allocation tokens
    //@notice send any remaining balance to the MultisigWallet
    //@notice unsold tokens will be sent to icedwallet
    function finalize() isFundable onlyOwner external {
      if (block.number <= fundingStopBlock) throw;

      if (totalUsedTokens < minTokensForSale) throw;

      if(unsoldVault == address(0)) throw;

      // switch funding mode off
      fundingMode = false;

      //Allot team tokens to a smart contract which will frozen for 9 months
      teamAllocation = new TeamAllocation();
      balances[address(teamAllocation)] = lockedTeamAllocationTokens;

      //allocate unsold tokens to iced storage
      uint totalUnSold = numberOfTokensLeft();
      if(totalUnSold > 0) {
        unsoldTokens = new UnsoldAllocation(coldStorageYears,unsoldVault,totalUnSold);
        balances[address(unsoldTokens)] = totalUnSold;
      }

      //transfer any balance available to Pillar Multisig Wallet
      pillarTokenFactory.transfer(this.balance);
    }

    //@notice Function that can be called by purchasers to refund
    //@notice Used only in case the ICO isn&#39;t successful.
    function refund() isFundable external {
      if(block.number <= fundingStopBlock) throw;
      if(totalUsedTokens >= minTokensForSale) throw;

      uint plrValue = balances[msg.sender];
      if(plrValue == 0) throw;

      balances[msg.sender] = 0;

      uint ethValue = plrValue.mul(tokenPrice).div(1e18);
      msg.sender.transfer(ethValue);
      Refund(msg.sender, ethValue);
    }

    //@notice Function used for funding in case of refund.
    //@notice Can be called only by the Owner
    function allocateForRefund() external payable onlyOwner returns (uint){
      //does nothing just accepts and stores the ether
      MoneyAddedForRefund(msg.sender,msg.value,this.balance);
      return this.balance;
    }

    //@notice Function to allocate tokens to an user.
    //@param `_to` the address of an user
    //@param `_tokens` number of tokens to be allocated.
    //@notice Can be called only when funding is not active and only by the owner
    function allocateTokens(address _to,uint _tokens) isNotFundable onlyOwner external {
      uint numOfTokens = _tokens.mul(1e18);
      totalPresale = totalPresale.add(numOfTokens);

      if(totalPresale > maxPresaleTokens) throw;

      balances[_to] = balances[_to].add(numOfTokens);
    }

    //@notice Function to unPause the contract.
    //@notice Can be called only when funding is active and only by the owner
    function unPauseTokenSale() onlyOwner isNotFundable external returns (bool){
      fundingMode = true;
      return fundingMode;
    }

    //@notice Function to pause the contract.
    //@notice Can be called only when funding is active and only by the owner
    function pauseTokenSale() onlyOwner isFundable external returns (bool){
      fundingMode = false;
      return !fundingMode;
    }

    //@notice Function to start the contract.
    //@param `_fundingStartBlock` - block from when ICO commences
    //@param `_fundingStopBlock` - block from when ICO ends.
    //@notice Can be called only when funding is not active and only by the owner
    function startTokenSale(uint _fundingStartBlock, uint _fundingStopBlock) onlyOwner isNotFundable external returns (bool){
      if(_fundingStopBlock <= _fundingStartBlock) throw;

      fundingStartBlock = _fundingStartBlock;
      fundingStopBlock = _fundingStopBlock;
      fundingMode = true;
      return fundingMode;
    }

    //@notice Function to get the current funding status.
    function fundingStatus() external constant returns (bool){
      return fundingMode;
    }
}