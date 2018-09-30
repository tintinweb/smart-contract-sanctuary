/*
  Zethr | https://zethr.io
  (c) Copyright 2018 | All Rights Reserved
  This smart contract was developed by the Zethr Dev Team and its source code remains property of the Zethr Project.
*/

pragma solidity ^0.4.24;

// File: contracts/Libraries/SafeMath.sol

library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    if (a == 0) {
      return 0;
    }
    uint c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: contracts/Libraries/ZethrTierLibrary.sol

library ZethrTierLibrary {
  uint constant internal magnitude = 2 ** 64;

  // Gets the tier (1-7) of the divs sent based off of average dividend rate
  // This is an index used to call into the correct sub-bankroll to withdraw tokens
  function getTier(uint divRate) internal pure returns (uint8) {

    // Divide the average dividned rate by magnitude
    // Remainder doesn&#39;t matter because of the below logic
    uint actualDiv = divRate / magnitude;
    if (actualDiv >= 30) {
      return 6;
    } else if (actualDiv >= 25) {
      return 5;
    } else if (actualDiv >= 20) {
      return 4;
    } else if (actualDiv >= 15) {
      return 3;
    } else if (actualDiv >= 10) {
      return 2;
    } else if (actualDiv >= 5) {
      return 1;
    } else if (actualDiv >= 2) {
      return 0;
    } else {
      // Impossible
      revert();
    }
  }

  function getDivRate(uint _tier)
  internal pure
  returns (uint8)
  {
    if (_tier == 0) {
      return 2;
    } else if (_tier == 1) {
      return 5;
    } else if (_tier == 2) {
      return 10;
    } else if (_tier == 3) {
      return 15;
    } else if (_tier == 4) {
      return 20;
    } else if (_tier == 5) {
      return 25;
    } else if (_tier == 6) {
      return 33;
    } else {
      revert();
    }
  }
}

// File: contracts/ERC/ERC223Receiving.sol

contract ERC223Receiving {
  function tokenFallback(address _from, uint _amountOfTokens, bytes _data) public returns (bool);
}

// File: contracts/ZethrMultiSigWallet.sol

/* Zethr MultisigWallet
 *
 * Standard multisig wallet
 * Holds the bankroll ETH, as well as the bankroll 33% ZTH tokens.
*/ 
contract ZethrMultiSigWallet is ERC223Receiving {
  using SafeMath for uint;

  /*=================================
  =              EVENTS            =
  =================================*/

  event Confirmation(address indexed sender, uint indexed transactionId);
  event Revocation(address indexed sender, uint indexed transactionId);
  event Submission(uint indexed transactionId);
  event Execution(uint indexed transactionId);
  event ExecutionFailure(uint indexed transactionId);
  event Deposit(address indexed sender, uint value);
  event OwnerAddition(address indexed owner);
  event OwnerRemoval(address indexed owner);
  event WhiteListAddition(address indexed contractAddress);
  event WhiteListRemoval(address indexed contractAddress);
  event RequirementChange(uint required);
  event BankrollInvest(uint amountReceived);

  /*=================================
  =             VARIABLES           =
  =================================*/

  mapping (uint => Transaction) public transactions;
  mapping (uint => mapping (address => bool)) public confirmations;
  mapping (address => bool) public isOwner;
  address[] public owners;
  uint public required;
  uint public transactionCount;
  bool internal reEntered = false;
  uint constant public MAX_OWNER_COUNT = 15;

  /*=================================
  =         CUSTOM CONSTRUCTS       =
  =================================*/

  struct Transaction {
    address destination;
    uint value;
    bytes data;
    bool executed;
  }

  struct TKN {
    address sender;
    uint value;
  }

  /*=================================
  =            MODIFIERS            =
  =================================*/

  modifier onlyWallet() {
    if (msg.sender != address(this))
      revert();
    _;
  }

  modifier isAnOwner() {
    address caller = msg.sender;
    if (isOwner[caller])
      _;
    else
      revert();
  }

  modifier ownerDoesNotExist(address owner) {
    if (isOwner[owner]) 
      revert();
      _;
  }

  modifier ownerExists(address owner) {
    if (!isOwner[owner])
      revert();
    _;
  }

  modifier transactionExists(uint transactionId) {
    if (transactions[transactionId].destination == 0)
      revert();
    _;
  }

  modifier confirmed(uint transactionId, address owner) {
    if (!confirmations[transactionId][owner])
      revert();
    _;
  }

  modifier notConfirmed(uint transactionId, address owner) {
    if (confirmations[transactionId][owner])
      revert();
    _;
  }

  modifier notExecuted(uint transactionId) {
    if (transactions[transactionId].executed)
      revert();
    _;
  }

  modifier notNull(address _address) {
    if (_address == 0)
      revert();
    _;
  }

  modifier validRequirement(uint ownerCount, uint _required) {
    if ( ownerCount > MAX_OWNER_COUNT
      || _required > ownerCount
      || _required == 0
      || ownerCount == 0)
      revert();
    _;
  }


  /*=================================
  =         PUBLIC FUNCTIONS        =
  =================================*/

  /// @dev Contract constructor sets initial owners and required number of confirmations.
  /// @param _owners List of initial owners.
  /// @param _required Number of required confirmations.
  constructor (address[] _owners, uint _required)
    public
    validRequirement(_owners.length, _required)
  {
    // Add owners
    for (uint i=0; i<_owners.length; i++) {
      if (isOwner[_owners[i]] || _owners[i] == 0)
        revert();
      isOwner[_owners[i]] = true;
    }

    // Set owners
    owners = _owners;

    // Set required
    required = _required;
  }

  /** Testing only.
  function exitAll()
    public
  {
    uint tokenBalance = ZTHTKN.balanceOf(address(this));
    ZTHTKN.sell(tokenBalance - 1e18);
    ZTHTKN.sell(1e18);
    ZTHTKN.withdraw(address(0x0));
  }
  **/

  /// @dev Fallback function allows Ether to be deposited.
  function()
    public
    payable
  {

  }
    
  /// @dev Allows to add a new owner. Transaction has to be sent by wallet.
  /// @param owner Address of new owner.
  function addOwner(address owner)
    public
    onlyWallet
    ownerDoesNotExist(owner)
    notNull(owner)
    validRequirement(owners.length + 1, required)
  {
    isOwner[owner] = true;
    owners.push(owner);
    emit OwnerAddition(owner);
  }

  /// @dev Allows to remove an owner. Transaction has to be sent by wallet.
  /// @param owner Address of owner.
  function removeOwner(address owner)
    public
    onlyWallet
    ownerExists(owner)
    validRequirement(owners.length, required)
  {
    isOwner[owner] = false;
    for (uint i=0; i<owners.length - 1; i++)
      if (owners[i] == owner) {
        owners[i] = owners[owners.length - 1];
        break;
      }

    owners.length -= 1;
    if (required > owners.length)
      changeRequirement(owners.length);
    emit OwnerRemoval(owner);
  }

  /// @dev Allows to replace an owner with a new owner. Transaction has to be sent by wallet.
  /// @param owner Address of owner to be replaced.
  /// @param owner Address of new owner.
  function replaceOwner(address owner, address newOwner)
    public
    onlyWallet
    ownerExists(owner)
    ownerDoesNotExist(newOwner)
  {
    for (uint i=0; i<owners.length; i++)
      if (owners[i] == owner) {
        owners[i] = newOwner;
        break;
      }

    isOwner[owner] = false;
    isOwner[newOwner] = true;
    emit OwnerRemoval(owner);
    emit OwnerAddition(newOwner);
  }

  /// @dev Allows to change the number of required confirmations. Transaction has to be sent by wallet.
  /// @param _required Number of required confirmations.
  function changeRequirement(uint _required)
    public
    onlyWallet
    validRequirement(owners.length, _required)
  {
    required = _required;
    emit RequirementChange(_required);
  }

  /// @dev Allows an owner to submit and confirm a transaction.
  /// @param destination Transaction target address.
  /// @param value Transaction ether value.
  /// @param data Transaction data payload.
  /// @return Returns transaction ID.
  function submitTransaction(address destination, uint value, bytes data)
    public
    returns (uint transactionId)
  {
    transactionId = addTransaction(destination, value, data);
    confirmTransaction(transactionId);
  }

  /// @dev Allows an owner to confirm a transaction.
  /// @param transactionId Transaction ID.
  function confirmTransaction(uint transactionId)
    public
    ownerExists(msg.sender)
    transactionExists(transactionId)
    notConfirmed(transactionId, msg.sender)
  {
    confirmations[transactionId][msg.sender] = true;
    emit Confirmation(msg.sender, transactionId);
    executeTransaction(transactionId);
  }

  /// @dev Allows an owner to revoke a confirmation for a transaction.
  /// @param transactionId Transaction ID.
  function revokeConfirmation(uint transactionId)
    public
    ownerExists(msg.sender)
    confirmed(transactionId, msg.sender)
    notExecuted(transactionId)
  {
    confirmations[transactionId][msg.sender] = false;
    emit Revocation(msg.sender, transactionId);
  }

  /// @dev Allows anyone to execute a confirmed transaction.
  /// @param transactionId Transaction ID.
  function executeTransaction(uint transactionId)
    public
    notExecuted(transactionId)
  {
    if (isConfirmed(transactionId)) {
      Transaction storage txToExecute = transactions[transactionId];
      txToExecute.executed = true;
      if (txToExecute.destination.call.value(txToExecute.value)(txToExecute.data))
        emit Execution(transactionId);
      else {
        emit ExecutionFailure(transactionId);
        txToExecute.executed = false;
      }
    }
  }

  /// @dev Returns the confirmation status of a transaction.
  /// @param transactionId Transaction ID.
  /// @return Confirmation status.
  function isConfirmed(uint transactionId)
    public
    constant
    returns (bool)
  {
    uint count = 0;
    for (uint i=0; i<owners.length; i++) {
      if (confirmations[transactionId][owners[i]])
        count += 1;
      if (count == required)
        return true;
    }
  }

  /*=================================
  =        OPERATOR FUNCTIONS       =
  =================================*/

  /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
  /// @param destination Transaction target address.
  /// @param value Transaction ether value.
  /// @param data Transaction data payload.
  /// @return Returns transaction ID.
  function addTransaction(address destination, uint value, bytes data)
    internal
    notNull(destination)
    returns (uint transactionId)
  {
    transactionId = transactionCount;

    transactions[transactionId] = Transaction({
        destination: destination,
        value: value,
        data: data,
        executed: false
    });

    transactionCount += 1;
    emit Submission(transactionId);
  }

  /*
   * Web3 call functions
   */
  /// @dev Returns number of confirmations of a transaction.
  /// @param transactionId Transaction ID.
  /// @return Number of confirmations.
  function getConfirmationCount(uint transactionId)
    public
    constant
    returns (uint count)
  {
    for (uint i=0; i<owners.length; i++)
      if (confirmations[transactionId][owners[i]])
        count += 1;
  }

  /// @dev Returns total number of transactions after filers are applied.
  /// @param pending Include pending transactions.
  /// @param executed Include executed transactions.
  /// @return Total number of transactions after filters are applied.
  function getTransactionCount(bool pending, bool executed)
    public
    constant
    returns (uint count)
  {
    for (uint i=0; i<transactionCount; i++)
      if (pending && !transactions[i].executed || executed && transactions[i].executed)
        count += 1;
  }

  /// @dev Returns list of owners.
  /// @return List of owner addresses.
  function getOwners()
    public
    constant
    returns (address[])
  {
    return owners;
  }

  /// @dev Returns array with owner addresses, which confirmed transaction.
  /// @param transactionId Transaction ID.
  /// @return Returns array of owner addresses.
  function getConfirmations(uint transactionId)
    public
    constant
    returns (address[] _confirmations)
  {
    address[] memory confirmationsTemp = new address[](owners.length);
    uint count = 0;
    uint i;
    for (i=0; i<owners.length; i++)
      if (confirmations[transactionId][owners[i]]) {
        confirmationsTemp[count] = owners[i];
        count += 1;
      }

      _confirmations = new address[](count);

      for (i=0; i<count; i++)
        _confirmations[i] = confirmationsTemp[i];
  }

  /// @dev Returns list of transaction IDs in defined range.
  /// @param from Index start position of transaction array.
  /// @param to Index end position of transaction array.
  /// @param pending Include pending transactions.
  /// @param executed Include executed transactions.
  /// @return Returns array of transaction IDs.
  function getTransactionIds(uint from, uint to, bool pending, bool executed)
    public
    constant
    returns (uint[] _transactionIds)
  {
    uint[] memory transactionIdsTemp = new uint[](transactionCount);
    uint count = 0;
    uint i;

    for (i=0; i<transactionCount; i++)
      if (pending && !transactions[i].executed || executed && transactions[i].executed) {
        transactionIdsTemp[count] = i;
        count += 1;
      }

      _transactionIds = new uint[](to - from);

    for (i=from; i<to; i++)
      _transactionIds[i - from] = transactionIdsTemp[i];
  }

  function tokenFallback(address /*_from*/, uint /*_amountOfTokens*/, bytes /*_data*/)
  public
  returns (bool)
  {
    return true;
  }
}

// File: contracts/Bankroll/Interfaces/ZethrTokenBankrollInterface.sol

// Zethr token bankroll function prototypes
contract ZethrTokenBankrollInterface is ERC223Receiving {
  uint public jackpotBalance;
  
  function getMaxProfit(address) public view returns (uint);
  function gameTokenResolution(uint _toWinnerAmount, address _winnerAddress, uint _toJackpotAmount, address _jackpotAddress, uint _originalBetSize) external;
  function payJackpotToWinner(address _winnerAddress, uint payoutDivisor) public;
}

// File: contracts/Bankroll/Interfaces/ZethrBankrollControllerInterface.sol

contract ZethrBankrollControllerInterface is ERC223Receiving {
  address public jackpotAddress;

  ZethrTokenBankrollInterface[7] public tokenBankrolls; 
  
  ZethrMultiSigWallet public multiSigWallet;

  mapping(address => bool) public validGameAddresses;

  function gamePayoutResolver(address _resolver, uint _tokenAmount) public;

  function isTokenBankroll(address _address) public view returns (bool);

  function getTokenBankrollAddressFromTier(uint8 _tier) public view returns (address);

  function tokenFallback(address _from, uint _amountOfTokens, bytes _data) public returns (bool);
}

// File: contracts/ERC/ERC721Interface.sol

contract ERC721Interface {
  function approve(address _to, uint _tokenId) public;
  function balanceOf(address _owner) public view returns (uint balance);
  function implementsERC721() public pure returns (bool);
  function ownerOf(uint _tokenId) public view returns (address addr);
  function takeOwnership(uint _tokenId) public;
  function totalSupply() public view returns (uint total);
  function transferFrom(address _from, address _to, uint _tokenId) public;
  function transfer(address _to, uint _tokenId) public;

  event Transfer(address indexed from, address indexed to, uint tokenId);
  event Approval(address indexed owner, address indexed approved, uint tokenId);
}

// File: contracts/Libraries/AddressUtils.sol

/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   *  as the code is not actually created until after the constructor finishes.
   * @param addr address to check
   * @return whether the target address is a contract
   */
  function isContract(address addr) internal view returns (bool) {
    uint size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    assembly { size := extcodesize(addr) }  // solium-disable-line security/no-inline-assembly
    return size > 0;
  }
}

// File: contracts/Games/ZethrDividendCards.sol

contract ZethrDividendCards is ERC721Interface {
    using SafeMath for uint;

  /*** EVENTS ***/

  /// @dev The Birth event is fired whenever a new dividend card comes into existence.
  event Birth(uint tokenId, string name, address owner);

  /// @dev The TokenSold event is fired whenever a token (dividend card, in this case) is sold.
  event TokenSold(uint tokenId, uint oldPrice, uint newPrice, address prevOwner, address winner, string name);

  /// @dev Transfer event as defined in current draft of ERC721.
  ///  Ownership is assigned, including births.
  event Transfer(address from, address to, uint tokenId);

  // Events for calculating card profits / errors
  event BankrollDivCardProfit(uint bankrollProfit, uint percentIncrease, address oldOwner);
  event BankrollProfitFailure(uint bankrollProfit, uint percentIncrease, address oldOwner);
  event UserDivCardProfit(uint divCardProfit, uint percentIncrease, address oldOwner);
  event DivCardProfitFailure(uint divCardProfit, uint percentIncrease, address oldOwner);
  event masterCardProfit(uint toMaster, address _masterAddress, uint _divCardId);
  event masterCardProfitFailure(uint toMaster, address _masterAddress, uint _divCardId);
  event regularCardProfit(uint toRegular, address _regularAddress, uint _divCardId);
  event regularCardProfitFailure(uint toRegular, address _regularAddress, uint _divCardId);

  /*** CONSTANTS ***/

  /// @notice Name and symbol of the non fungible token, as defined in ERC721.
  string public constant NAME           = "ZethrDividendCard";
  string public constant SYMBOL         = "ZDC";
  address public         BANKROLL;

  /*** STORAGE ***/

  /// @dev A mapping from dividend card indices to the address that owns them.
  ///  All dividend cards have a valid owner address.

  mapping (uint => address) public      divCardIndexToOwner;

  // A mapping from a dividend rate to the card index.

  mapping (uint => uint) public         divCardRateToIndex;

  // @dev A mapping from owner address to the number of dividend cards that address owns.
  //  Used internally inside balanceOf() to resolve ownership count.

  mapping (address => uint) private     ownershipDivCardCount;

  /// @dev A mapping from dividend card indices to an address that has been approved to call
  ///  transferFrom(). Each dividend card can only have one approved address for transfer
  ///  at any time. A zero value means no approval is outstanding.

  mapping (uint => address) public      divCardIndexToApproved;

  // @dev A mapping from dividend card indices to the price of the dividend card.

  mapping (uint => uint) private        divCardIndexToPrice;

  mapping (address => bool) internal    administrators;

  address public                        creator;
  bool    public                        onSale;

  /*** DATATYPES ***/

  struct Card {
    string name;
    uint percentIncrease;
  }

  Card[] private divCards;

  modifier onlyCreator() {
    require(msg.sender == creator);
    _;
  }

  constructor (address _bankroll) public {
    creator = msg.sender;
    BANKROLL = _bankroll;

    createDivCard("2%", 1 ether, 2);
    divCardRateToIndex[2] = 0;

    createDivCard("5%", 1 ether, 5);
    divCardRateToIndex[5] = 1;

    createDivCard("10%", 1 ether, 10);
    divCardRateToIndex[10] = 2;

    createDivCard("15%", 1 ether, 15);
    divCardRateToIndex[15] = 3;

    createDivCard("20%", 1 ether, 20);
    divCardRateToIndex[20] = 4;

    createDivCard("25%", 1 ether, 25);
    divCardRateToIndex[25] = 5;

    createDivCard("33%", 1 ether, 33);
    divCardRateToIndex[33] = 6;

    createDivCard("MASTER", 5 ether, 10);
    divCardRateToIndex[999] = 7;

	  onSale = true;

    administrators[0x4F4eBF556CFDc21c3424F85ff6572C77c514Fcae] = true; // Norsefire
    administrators[0x11e52c75998fe2E7928B191bfc5B25937Ca16741] = true; // klob
    administrators[0x20C945800de43394F70D789874a4daC9cFA57451] = true; // Etherguy
    administrators[0xef764BAC8a438E7E498c2E5fcCf0f174c3E3F8dB] = true; // blurr

    administrators[msg.sender] = true; // Helps with debugging
  }

  /*** MODIFIERS ***/

  // Modifier to prevent contracts from interacting with the flip cards
  modifier isNotContract()
  {
    require (msg.sender == tx.origin);
    _;
  }

	// Modifier to prevent purchases before we open them up to everyone
	modifier hasStarted()
  {
		require (onSale == true);
		_;
	}

	modifier isAdmin()
  {
	  require(administrators[msg.sender]);
	  _;
  }

  /*** PUBLIC FUNCTIONS ***/
  // Administrative update of the bankroll contract address
  function setBankroll(address where)
    public
    isAdmin
  {
    BANKROLL = where;
  }

  /// @notice Grant another address the right to transfer token via takeOwnership() and transferFrom().
  /// @param _to The address to be granted transfer approval. Pass address(0) to
  ///  clear all approvals.
  /// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function approve(address _to, uint _tokenId)
    public
    isNotContract
  {
    // Caller must own token.
    require(_owns(msg.sender, _tokenId));

    divCardIndexToApproved[_tokenId] = _to;

    emit Approval(msg.sender, _to, _tokenId);
  }

  /// For querying balance of a particular account
  /// @param _owner The address for balance query
  /// @dev Required for ERC-721 compliance.
  function balanceOf(address _owner)
    public
    view
    returns (uint balance)
  {
    return ownershipDivCardCount[_owner];
  }

  // Creates a div card with bankroll as the owner
  function createDivCard(string _name, uint _price, uint _percentIncrease)
    public
    onlyCreator
  {
    _createDivCard(_name, BANKROLL, _price, _percentIncrease);
  }

	// Opens the dividend cards up for sale.
	function startCardSale()
        public
        isAdmin
  {
		onSale = true;
	}

  /// @notice Returns all the relevant information about a specific div card
  /// @param _divCardId The tokenId of the div card of interest.
  function getDivCard(uint _divCardId)
    public
    view
    returns (string divCardName, uint sellingPrice, address owner)
  {
    Card storage divCard = divCards[_divCardId];
    divCardName = divCard.name;
    sellingPrice = divCardIndexToPrice[_divCardId];
    owner = divCardIndexToOwner[_divCardId];
  }

  function implementsERC721()
    public
    pure
    returns (bool)
  {
    return true;
  }

  /// @dev Required for ERC-721 compliance.
  function name()
    public
    pure
    returns (string)
  {
    return NAME;
  }

  /// For querying owner of token
  /// @param _divCardId The tokenID for owner inquiry
  /// @dev Required for ERC-721 compliance.
  function ownerOf(uint _divCardId)
    public
    view
    returns (address owner)
  {
    owner = divCardIndexToOwner[_divCardId];
    require(owner != address(0));
	return owner;
  }

  // Allows someone to send Ether and obtain a card
  function purchase(uint _divCardId)
    public
    payable
    hasStarted
    isNotContract
  {
    address oldOwner  = divCardIndexToOwner[_divCardId];
    address newOwner  = msg.sender;

    // Get the current price of the card
    uint currentPrice = divCardIndexToPrice[_divCardId];

    // Making sure token owner is not sending to self
    require(oldOwner != newOwner);

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure sent amount is greater than or equal to the sellingPrice
    require(msg.value >= currentPrice);

    // To find the total profit, we need to know the previous price
    // currentPrice      = previousPrice * (100 + percentIncrease);
    // previousPrice     = currentPrice / (100 + percentIncrease);
    uint percentIncrease = divCards[_divCardId].percentIncrease;
    uint previousPrice   = SafeMath.mul(currentPrice, 100).div(100 + percentIncrease);

    // Calculate total profit and allocate 50% to old owner, 50% to bankroll
    uint totalProfit     = SafeMath.sub(currentPrice, previousPrice);
    uint oldOwnerProfit  = SafeMath.div(totalProfit, 2);
    uint bankrollProfit  = SafeMath.sub(totalProfit, oldOwnerProfit);
    oldOwnerProfit       = SafeMath.add(oldOwnerProfit, previousPrice);

    // Refund the sender the excess he sent
    uint purchaseExcess  = SafeMath.sub(msg.value, currentPrice);

    // Raise the price by the percentage specified by the card
    divCardIndexToPrice[_divCardId] = SafeMath.div(SafeMath.mul(currentPrice, (100 + percentIncrease)), 100);

    // Transfer ownership
    _transfer(oldOwner, newOwner, _divCardId);

    // Using send rather than transfer to prevent contract exploitability.
    if(BANKROLL.send(bankrollProfit)) {
      emit BankrollDivCardProfit(bankrollProfit, percentIncrease, oldOwner);
    } else {
      emit BankrollProfitFailure(bankrollProfit, percentIncrease, oldOwner);
    }

    if(oldOwner.send(oldOwnerProfit)) {
      emit UserDivCardProfit(oldOwnerProfit, percentIncrease, oldOwner);
    } else {
      emit DivCardProfitFailure(oldOwnerProfit, percentIncrease, oldOwner);
    }

    msg.sender.transfer(purchaseExcess);
  }

  function priceOf(uint _divCardId)
    public
    view
    returns (uint price)
  {
    return divCardIndexToPrice[_divCardId];
  }

  function setCreator(address _creator)
    public
    onlyCreator
  {
    require(_creator != address(0));

    creator = _creator;
  }

  /// @dev Required for ERC-721 compliance.
  function symbol()
    public
    pure
    returns (string)
  {
    return SYMBOL;
  }

  /// @notice Allow pre-approved user to take ownership of a dividend card.
  /// @param _divCardId The ID of the card that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function takeOwnership(uint _divCardId)
    public
    isNotContract
  {
    address newOwner = msg.sender;
    address oldOwner = divCardIndexToOwner[_divCardId];

    // Safety check to prevent against an unexpected 0x0 default.
    require(_addressNotNull(newOwner));

    // Making sure transfer is approved
    require(_approved(newOwner, _divCardId));

    _transfer(oldOwner, newOwner, _divCardId);
  }

  /// For querying totalSupply of token
  /// @dev Required for ERC-721 compliance.
  function totalSupply()
    public
    view
    returns (uint total)
  {
    return divCards.length;
  }

  /// Owner initates the transfer of the card to another account
  /// @param _to The address for the card to be transferred to.
  /// @param _divCardId The ID of the card that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function transfer(address _to, uint _divCardId)
    public
    isNotContract
  {
    require(_owns(msg.sender, _divCardId));
    require(_addressNotNull(_to));

    _transfer(msg.sender, _to, _divCardId);
  }

  /// Third-party initiates transfer of a card from address _from to address _to
  /// @param _from The address for the card to be transferred from.
  /// @param _to The address for the card to be transferred to.
  /// @param _divCardId The ID of the card that can be transferred if this call succeeds.
  /// @dev Required for ERC-721 compliance.
  function transferFrom(address _from, address _to, uint _divCardId)
    public
    isNotContract
  {
    require(_owns(_from, _divCardId));
    require(_approved(_to, _divCardId));
    require(_addressNotNull(_to));

    _transfer(_from, _to, _divCardId);
  }

  function receiveDividends(uint _divCardRate)
    public
    payable
  {
    uint _divCardId = divCardRateToIndex[_divCardRate];
    address _regularAddress = divCardIndexToOwner[_divCardId];
    address _masterAddress = divCardIndexToOwner[7];

    uint toMaster = msg.value.div(2);
    uint toRegular = msg.value.sub(toMaster);

    if(_masterAddress.send(toMaster)){
      emit masterCardProfit(toMaster, _masterAddress, _divCardId);
    } else {
      emit masterCardProfitFailure(toMaster, _masterAddress, _divCardId);
    }

    if(_regularAddress.send(toRegular)) {
      emit regularCardProfit(toRegular, _regularAddress, _divCardId);
    } else {
      emit regularCardProfitFailure(toRegular, _regularAddress, _divCardId);
    }
  }

  /*** PRIVATE FUNCTIONS ***/
  /// Safety check on _to address to prevent against an unexpected 0x0 default.
  function _addressNotNull(address _to)
    private
    pure
    returns (bool)
  {
    return _to != address(0);
  }

  /// For checking approval of transfer for address _to
  function _approved(address _to, uint _divCardId)
    private
    view
    returns (bool)
  {
    return divCardIndexToApproved[_divCardId] == _to;
  }

  /// For creating a dividend card
  function _createDivCard(string _name, address _owner, uint _price, uint _percentIncrease)
    private
  {
    Card memory _divcard = Card({
      name: _name,
      percentIncrease: _percentIncrease
    });
    uint newCardId = divCards.push(_divcard) - 1;

    // It&#39;s probably never going to happen, 4 billion tokens are A LOT, but
    // let&#39;s just be 100% sure we never let this happen.
    require(newCardId == uint(uint32(newCardId)));

    emit Birth(newCardId, _name, _owner);

    divCardIndexToPrice[newCardId] = _price;

    // This will assign ownership, and also emit the Transfer event as per ERC721 draft
    _transfer(BANKROLL, _owner, newCardId);
  }

  /// Check for token ownership
  function _owns(address claimant, uint _divCardId)
    private
    view
    returns (bool)
  {
    return claimant == divCardIndexToOwner[_divCardId];
  }

  /// @dev Assigns ownership of a specific Card to an address.
  function _transfer(address _from, address _to, uint _divCardId)
    private
  {
    // Since the number of cards is capped to 2^32 we can&#39;t overflow this
    ownershipDivCardCount[_to]++;
    //transfer ownership
    divCardIndexToOwner[_divCardId] = _to;

    // When creating new div cards _from is 0x0, but we can&#39;t account that address.
    if (_from != address(0)) {
      ownershipDivCardCount[_from]--;
      // clear any previously approved ownership exchange
      delete divCardIndexToApproved[_divCardId];
    }

    // Emit the transfer event.
    emit Transfer(_from, _to, _divCardId);
  }
}

// File: contracts/Zethr.sol

contract Zethr {
  using SafeMath for uint;

  /*=================================
  =            MODIFIERS            =
  =================================*/

  modifier onlyHolders() {
    require(myFrontEndTokens() > 0);
    _;
  }

  modifier dividendHolder() {
    require(myDividends(true) > 0);
    _;
  }

  modifier onlyAdministrator(){
    address _customerAddress = msg.sender;
    require(administrators[_customerAddress]);
    _;
  }

  /*==============================
  =            EVENTS            =
  ==============================*/

  event onTokenPurchase(
    address indexed customerAddress,
    uint incomingEthereum,
    uint tokensMinted,
    address indexed referredBy
  );

  event UserDividendRate(
    address user,
    uint divRate
  );

  event onTokenSell(
    address indexed customerAddress,
    uint tokensBurned,
    uint ethereumEarned
  );

  event onReinvestment(
    address indexed customerAddress,
    uint ethereumReinvested,
    uint tokensMinted
  );

  event onWithdraw(
    address indexed customerAddress,
    uint ethereumWithdrawn
  );

  event Transfer(
    address indexed from,
    address indexed to,
    uint tokens
  );

  event Approval(
    address indexed tokenOwner,
    address indexed spender,
    uint tokens
  );

  event Allocation(
    uint toBankRoll,
    uint toReferrer,
    uint toTokenHolders,
    uint toDivCardHolders,
    uint forTokens
  );

  event Referral(
    address referrer,
    uint amountReceived
  );

  /*=====================================
  =            CONSTANTS                =
  =====================================*/

  uint8 constant public                decimals = 18;

  uint constant internal               tokenPriceInitial_ = 0.000653 ether;
  uint constant internal               magnitude = 2 ** 64;

  uint constant internal               icoHardCap = 250 ether;
  uint constant internal               addressICOLimit = 1   ether;
  uint constant internal               icoMinBuyIn = 0.1 finney;
  uint constant internal               icoMaxGasPrice = 50000000000 wei;

  uint constant internal               MULTIPLIER = 9615;

  uint constant internal               MIN_ETH_BUYIN = 0.0001 ether;
  uint constant internal               MIN_TOKEN_SELL_AMOUNT = 0.0001 ether;
  uint constant internal               MIN_TOKEN_TRANSFER = 1e10;
  uint constant internal               referrer_percentage = 25;

  uint public                          stakingRequirement = 100e18;

  /*================================
   =          CONFIGURABLES         =
   ================================*/

  string public                        name = "Zethr";
  string public                        symbol = "ZTH";

  //bytes32 constant public              icoHashedPass      = bytes32(0x5ddcde33b94b19bdef79dd9ea75be591942b9ec78286d64b44a356280fb6a262); // public
  bytes32 constant public              icoHashedPass = bytes32(0x8a6ddee3fb2508ff4a5b02b48e9bc4566d0f3e11f306b0f75341bf235662a9e3); // test hunter2

  address internal                     bankrollAddress;

  ZethrDividendCards                   divCardContract;

  /*================================
   =            DATASETS            =
   ================================*/

  // Tracks front & backend tokens
  mapping(address => uint) internal    frontTokenBalanceLedger_;
  mapping(address => uint) internal    dividendTokenBalanceLedger_;
  mapping(address =>
  mapping(address => uint))
  public      allowed;

  // Tracks dividend rates for users
  mapping(uint8 => bool)    internal validDividendRates_;
  mapping(address => bool)    internal userSelectedRate;
  mapping(address => uint8)   internal userDividendRate;

  // Payout tracking
  mapping(address => uint)    internal referralBalance_;
  mapping(address => int256)  internal payoutsTo_;

  // ICO per-address limit tracking
  mapping(address => uint)    internal ICOBuyIn;

  uint public                          tokensMintedDuringICO;
  uint public                          ethInvestedDuringICO;

  uint public                          currentEthInvested;

  uint internal                        tokenSupply = 0;
  uint internal                        divTokenSupply = 0;

  uint internal                        profitPerDivToken;

  mapping(address => bool) public      administrators;

  bool public                          icoPhase = false;
  bool public                          regularPhase = false;

  uint                                 icoOpenTime;

  /*=======================================
  =            PUBLIC FUNCTIONS           =
  =======================================*/
  constructor (address _bankrollAddress, address _divCardAddress)
  public
  {
    bankrollAddress = _bankrollAddress;
    divCardContract = ZethrDividendCards(_divCardAddress);

    administrators[0x4F4eBF556CFDc21c3424F85ff6572C77c514Fcae] = true;
    // Norsefire
    administrators[0x11e52c75998fe2E7928B191bfc5B25937Ca16741] = true;
    // klob
    administrators[0x20C945800de43394F70D789874a4daC9cFA57451] = true;
    // Etherguy
    administrators[0xef764BAC8a438E7E498c2E5fcCf0f174c3E3F8dB] = true;
    // blurr
    administrators[0x8537aa2911b193e5B377938A723D805bb0865670] = true;
    // oguzhanox
    administrators[0x9D221b2100CbE5F05a0d2048E2556a6Df6f9a6C3] = true;
    // Randall
    administrators[0xDa83156106c4dba7A26E9bF2Ca91E273350aa551] = true;
    // TropicalRogue
    administrators[0x71009e9E4e5e68e77ECc7ef2f2E95cbD98c6E696] = true;
    // cryptodude

    administrators[msg.sender] = true;
    // Helps with debugging!

    validDividendRates_[2] = true;
    validDividendRates_[5] = true;
    validDividendRates_[10] = true;
    validDividendRates_[15] = true;
    validDividendRates_[20] = true;
    validDividendRates_[25] = true;
    validDividendRates_[33] = true;

    userSelectedRate[bankrollAddress] = true;
    userDividendRate[bankrollAddress] = 33;

  }

  /**
   * Same as buy, but explicitly sets your dividend percentage.
   * If this has been called before, it will update your `default&#39; dividend
   *   percentage for regular buy transactions going forward.
   */
  function buyAndSetDivPercentage(address _referredBy, uint8 _divChoice, string /*providedUnhashedPass*/)
  public
  payable
  returns (uint)
  {
    require(icoPhase || regularPhase);

    if (icoPhase) {

      // Anti-bot measures - not perfect, but should help some.
      // bytes32 hashedProvidedPass = keccak256(providedUnhashedPass);
      //require(hashedProvidedPass == icoHashedPass || msg.sender == bankrollAddress); // test; remove

      uint gasPrice = tx.gasprice;

      // Prevents ICO buyers from getting substantially burned if the ICO is reached
      //   before their transaction is processed.
      require(gasPrice <= icoMaxGasPrice && ethInvestedDuringICO <= icoHardCap);

    }

    // Dividend percentage should be a currently accepted value.
    require(validDividendRates_[_divChoice]);

    // Set the dividend fee percentage denominator.
    userSelectedRate[msg.sender] = true;
    userDividendRate[msg.sender] = _divChoice;
    emit UserDividendRate(msg.sender, _divChoice);

    // Finally, purchase tokens.
    purchaseTokens(msg.value, _referredBy);
  }

  // All buys except for the above one require regular phase.

  function buy(address _referredBy)
  public
  payable
  returns (uint)
  {
    require(regularPhase);
    address _customerAddress = msg.sender;
    require(userSelectedRate[_customerAddress]);
    purchaseTokens(msg.value, _referredBy);
  }

  function buyAndTransfer(address _referredBy, address target)
  public
  payable
  {
    bytes memory empty;
    buyAndTransfer(_referredBy, target, empty, 20);
  }

  function buyAndTransfer(address _referredBy, address target, bytes _data)
  public
  payable
  {
    buyAndTransfer(_referredBy, target, _data, 20);
  }

  // Overload
  function buyAndTransfer(address _referredBy, address target, bytes _data, uint8 divChoice)
  public
  payable
  {
    require(regularPhase);
    address _customerAddress = msg.sender;
    uint256 frontendBalance = frontTokenBalanceLedger_[msg.sender];
    if (userSelectedRate[_customerAddress] && divChoice == 0) {
      purchaseTokens(msg.value, _referredBy);
    } else {
      buyAndSetDivPercentage(_referredBy, divChoice, "0x0");
    }
    uint256 difference = SafeMath.sub(frontTokenBalanceLedger_[msg.sender], frontendBalance);
    transferTo(msg.sender, target, difference, _data);
  }

  // Fallback function only works during regular phase - part of anti-bot protection.
  function()
  payable
  public
  {
    /**
    / If the user has previously set a dividend rate, sending
    /   Ether directly to the contract simply purchases more at
    /   the most recent rate. If this is their first time, they
    /   are automatically placed into the 20% rate `bucket&#39;.
    **/
    require(regularPhase);
    address _customerAddress = msg.sender;
    if (userSelectedRate[_customerAddress]) {
      purchaseTokens(msg.value, 0x0);
    } else {
      buyAndSetDivPercentage(0x0, 20, "0x0");
    }
  }

  function reinvest()
  dividendHolder()
  public
  {
    require(regularPhase);
    uint _dividends = myDividends(false);

    // Pay out requisite `virtual&#39; dividends.
    address _customerAddress = msg.sender;
    payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);

    _dividends += referralBalance_[_customerAddress];
    referralBalance_[_customerAddress] = 0;

    uint _tokens = purchaseTokens(_dividends, 0x0);

    // Fire logging event.
    emit onReinvestment(_customerAddress, _dividends, _tokens);
  }

  function exit()
  public
  {
    require(regularPhase);
    // Retrieve token balance for caller, then sell them all.
    address _customerAddress = msg.sender;
    uint _tokens = frontTokenBalanceLedger_[_customerAddress];

    if (_tokens > 0) sell(_tokens);

    withdraw(_customerAddress);
  }

  function withdraw(address _recipient)
  dividendHolder()
  public
  {
    require(regularPhase);
    // Setup data
    address _customerAddress = msg.sender;
    uint _dividends = myDividends(false);

    // update dividend tracker
    payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);

    // add ref. bonus
    _dividends += referralBalance_[_customerAddress];
    referralBalance_[_customerAddress] = 0;

    if (_recipient == address(0x0)) {
      _recipient = msg.sender;
    }
    _recipient.transfer(_dividends);

    // Fire logging event.
    emit onWithdraw(_recipient, _dividends);
  }

  // Sells front-end tokens.
  // Logic concerning step-pricing of tokens pre/post-ICO is encapsulated in tokensToEthereum_.
  function sell(uint _amountOfTokens)
  onlyHolders()
  public
  {
    // No selling during the ICO. You don&#39;t get to flip that fast, sorry!
    require(!icoPhase);
    require(regularPhase);

    require(_amountOfTokens <= frontTokenBalanceLedger_[msg.sender]);

    uint _frontEndTokensToBurn = _amountOfTokens;

    // Calculate how many dividend tokens this action burns.
    // Computed as the caller&#39;s average dividend rate multiplied by the number of front-end tokens held.
    // As an additional guard, we ensure that the dividend rate is between 2 and 50 inclusive.
    uint userDivRate = getUserAverageDividendRate(msg.sender);
    require((2 * magnitude) <= userDivRate && (50 * magnitude) >= userDivRate);
    uint _divTokensToBurn = (_frontEndTokensToBurn.mul(userDivRate)).div(magnitude);

    // Calculate ethereum received before dividends
    uint _ethereum = tokensToEthereum_(_frontEndTokensToBurn);

    if (_ethereum > currentEthInvested) {
      // Well, congratulations, you&#39;ve emptied the coffers.
      currentEthInvested = 0;
    } else {currentEthInvested = currentEthInvested - _ethereum;}

    // Calculate dividends generated from the sale.
    uint _dividends = (_ethereum.mul(getUserAverageDividendRate(msg.sender)).div(100)).div(magnitude);

    // Calculate Ethereum receivable net of dividends.
    uint _taxedEthereum = _ethereum.sub(_dividends);

    // Burn the sold tokens (both front-end and back-end variants).
    tokenSupply = tokenSupply.sub(_frontEndTokensToBurn);
    divTokenSupply = divTokenSupply.sub(_divTokensToBurn);

    // Subtract the token balances for the seller
    frontTokenBalanceLedger_[msg.sender] = frontTokenBalanceLedger_[msg.sender].sub(_frontEndTokensToBurn);
    dividendTokenBalanceLedger_[msg.sender] = dividendTokenBalanceLedger_[msg.sender].sub(_divTokensToBurn);

    // Update dividends tracker
    int256 _updatedPayouts = (int256) (profitPerDivToken * _divTokensToBurn + (_taxedEthereum * magnitude));
    payoutsTo_[msg.sender] -= _updatedPayouts;

    // Let&#39;s avoid breaking arithmetic where we can, eh?
    if (divTokenSupply > 0) {
      // Update the value of each remaining back-end dividend token.
      profitPerDivToken = profitPerDivToken.add((_dividends * magnitude) / divTokenSupply);
    }

    // Fire logging event.
    emit onTokenSell(msg.sender, _frontEndTokensToBurn, _taxedEthereum);
  }

  /**
   * Transfer tokens from the caller to a new holder.
   * No charge incurred for the transfer. We&#39;d make a terrible bank.
   */
  function transfer(address _toAddress, uint _amountOfTokens)
  onlyHolders()
  public
  returns (bool)
  {
    require(_amountOfTokens >= MIN_TOKEN_TRANSFER && _amountOfTokens <= frontTokenBalanceLedger_[msg.sender]);
    bytes memory empty;
    transferFromInternal(msg.sender, _toAddress, _amountOfTokens, empty);
    return true;
  }

  function approve(address spender, uint tokens)
  public
  returns (bool)
  {
    address _customerAddress = msg.sender;
    allowed[_customerAddress][spender] = tokens;

    // Fire logging event.
    emit Approval(_customerAddress, spender, tokens);

    // Good old ERC20.
    return true;
  }

  /**
   * Transfer tokens from the caller to a new holder: the Used By Smart Contracts edition.
   * No charge incurred for the transfer. No seriously, we&#39;d make a terrible bank.
   */
  function transferFrom(address _from, address _toAddress, uint _amountOfTokens)
  public
  returns (bool)
  {
    // Setup variables
    address _customerAddress = _from;
    bytes memory empty;
    // Make sure we own the tokens we&#39;re transferring, are ALLOWED to transfer that many tokens,
    // and are transferring at least one full token.
    require(_amountOfTokens >= MIN_TOKEN_TRANSFER
    && _amountOfTokens <= frontTokenBalanceLedger_[_customerAddress]
    && _amountOfTokens <= allowed[_customerAddress][msg.sender]);

    transferFromInternal(_from, _toAddress, _amountOfTokens, empty);

    // Good old ERC20.
    return true;

  }

  function transferTo(address _from, address _to, uint _amountOfTokens, bytes _data)
  public
  {
    if (_from != msg.sender) {
      require(_amountOfTokens >= MIN_TOKEN_TRANSFER
      && _amountOfTokens <= frontTokenBalanceLedger_[_from]
      && _amountOfTokens <= allowed[_from][msg.sender]);
    }
    else {
      require(_amountOfTokens >= MIN_TOKEN_TRANSFER
      && _amountOfTokens <= frontTokenBalanceLedger_[_from]);
    }

    transferFromInternal(_from, _to, _amountOfTokens, _data);
  }

  // Who&#39;d have thought we&#39;d need this thing floating around?
  function totalSupply()
  public
  view
  returns (uint256)
  {
    return tokenSupply;
  }

  // Anyone can start the regular phase 2 weeks after the ICO phase starts.
  // In case the devs die. Or something.
  function publicStartRegularPhase()
  public
  {
    require(now > (icoOpenTime + 2 weeks) && icoOpenTime != 0);

    icoPhase = false;
    regularPhase = true;
  }

  /*----------  ADMINISTRATOR ONLY FUNCTIONS  ----------*/


  // Fire the starting gun and then duck for cover.
  function startICOPhase()
  onlyAdministrator()
  public
  {
    // Prevent us from startaring the ICO phase again
    require(icoOpenTime == 0);
    icoPhase = true;
    icoOpenTime = now;
  }

  // Fire the ... ending gun?
  function endICOPhase()
  onlyAdministrator()
  public
  {
    icoPhase = false;
  }

  function startRegularPhase()
  onlyAdministrator
  public
  {
    // disable ico phase in case if that was not disabled yet
    icoPhase = false;
    regularPhase = true;
  }

  // The death of a great man demands the birth of a great son.
  function setAdministrator(address _newAdmin, bool _status)
  onlyAdministrator()
  public
  {
    administrators[_newAdmin] = _status;
  }

  function setStakingRequirement(uint _amountOfTokens)
  onlyAdministrator()
  public
  {
    // This plane only goes one way, lads. Never below the initial.
    require(_amountOfTokens >= 100e18);
    stakingRequirement = _amountOfTokens;
  }

  function setName(string _name)
  onlyAdministrator()
  public
  {
    name = _name;
  }

  function setSymbol(string _symbol)
  onlyAdministrator()
  public
  {
    symbol = _symbol;
  }

  function changeBankroll(address _newBankrollAddress)
  onlyAdministrator
  public
  {
    bankrollAddress = _newBankrollAddress;
  }

  /*----------  HELPERS AND CALCULATORS  ----------*/

  function totalEthereumBalance()
  public
  view
  returns (uint)
  {
    return address(this).balance;
  }

  function totalEthereumICOReceived()
  public
  view
  returns (uint)
  {
    return ethInvestedDuringICO;
  }

  /**
   * Retrieves your currently selected dividend rate.
   */
  function getMyDividendRate()
  public
  view
  returns (uint8)
  {
    address _customerAddress = msg.sender;
    require(userSelectedRate[_customerAddress]);
    return userDividendRate[_customerAddress];
  }

  /**
   * Retrieve the total frontend token supply
   */
  function getFrontEndTokenSupply()
  public
  view
  returns (uint)
  {
    return tokenSupply;
  }

  /**
   * Retreive the total dividend token supply
   */
  function getDividendTokenSupply()
  public
  view
  returns (uint)
  {
    return divTokenSupply;
  }

  /**
   * Retrieve the frontend tokens owned by the caller
   */
  function myFrontEndTokens()
  public
  view
  returns (uint)
  {
    address _customerAddress = msg.sender;
    return getFrontEndTokenBalanceOf(_customerAddress);
  }

  /**
   * Retrieve the dividend tokens owned by the caller
   */
  function myDividendTokens()
  public
  view
  returns (uint)
  {
    address _customerAddress = msg.sender;
    return getDividendTokenBalanceOf(_customerAddress);
  }

  function myReferralDividends()
  public
  view
  returns (uint)
  {
    return myDividends(true) - myDividends(false);
  }

  function myDividends(bool _includeReferralBonus)
  public
  view
  returns (uint)
  {
    address _customerAddress = msg.sender;
    return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress);
  }

  function theDividendsOf(bool _includeReferralBonus, address _customerAddress)
  public
  view
  returns (uint)
  {
    return _includeReferralBonus ? dividendsOf(_customerAddress) + referralBalance_[_customerAddress] : dividendsOf(_customerAddress);
  }

  function getFrontEndTokenBalanceOf(address _customerAddress)
  view
  public
  returns (uint)
  {
    return frontTokenBalanceLedger_[_customerAddress];
  }

  function balanceOf(address _owner)
  view
  public
  returns (uint)
  {
    return getFrontEndTokenBalanceOf(_owner);
  }

  function getDividendTokenBalanceOf(address _customerAddress)
  view
  public
  returns (uint)
  {
    return dividendTokenBalanceLedger_[_customerAddress];
  }

  function dividendsOf(address _customerAddress)
  view
  public
  returns (uint)
  {
    return (uint) ((int256)(profitPerDivToken * dividendTokenBalanceLedger_[_customerAddress]) - payoutsTo_[_customerAddress]) / magnitude;
  }

  // Get the sell price at the user&#39;s average dividend rate
  function sellPrice()
  public
  view
  returns (uint)
  {
    uint price;

    if (icoPhase || currentEthInvested < ethInvestedDuringICO) {
      price = tokenPriceInitial_;
    } else {

      // Calculate the tokens received for 100 finney.
      // Divide to find the average, to calculate the price.
      uint tokensReceivedForEth = ethereumToTokens_(0.001 ether);

      price = (1e18 * 0.001 ether) / tokensReceivedForEth;
    }

    // Factor in the user&#39;s average dividend rate
    uint theSellPrice = price.sub((price.mul(getUserAverageDividendRate(msg.sender)).div(100)).div(magnitude));

    return theSellPrice;
  }

  // Get the buy price at a particular dividend rate
  function buyPrice(uint dividendRate)
  public
  view
  returns (uint)
  {
    uint price;

    if (icoPhase || currentEthInvested < ethInvestedDuringICO) {
      price = tokenPriceInitial_;
    } else {

      // Calculate the tokens received for 100 finney.
      // Divide to find the average, to calculate the price.
      uint tokensReceivedForEth = ethereumToTokens_(0.001 ether);

      price = (1e18 * 0.001 ether) / tokensReceivedForEth;
    }

    // Factor in the user&#39;s selected dividend rate
    uint theBuyPrice = (price.mul(dividendRate).div(100)).add(price);

    return theBuyPrice;
  }

  function calculateTokensReceived(uint _ethereumToSpend)
  public
  view
  returns (uint)
  {
    uint _dividends = (_ethereumToSpend.mul(userDividendRate[msg.sender])).div(100);
    uint _taxedEthereum = _ethereumToSpend.sub(_dividends);
    uint _amountOfTokens = ethereumToTokens_(_taxedEthereum);
    return _amountOfTokens;
  }

  // When selling tokens, we need to calculate the user&#39;s current dividend rate.
  // This is different from their selected dividend rate.
  function calculateEthereumReceived(uint _tokensToSell)
  public
  view
  returns (uint)
  {
    require(_tokensToSell <= tokenSupply);
    uint _ethereum = tokensToEthereum_(_tokensToSell);
    uint userAverageDividendRate = getUserAverageDividendRate(msg.sender);
    uint _dividends = (_ethereum.mul(userAverageDividendRate).div(100)).div(magnitude);
    uint _taxedEthereum = _ethereum.sub(_dividends);
    return _taxedEthereum;
  }

  /*
   * Get&#39;s a user&#39;s average dividend rate - which is just their divTokenBalance / tokenBalance
   * We multiply by magnitude to avoid precision errors.
   */

  function getUserAverageDividendRate(address user) public view returns (uint) {
    return (magnitude * dividendTokenBalanceLedger_[user]).div(frontTokenBalanceLedger_[user]);
  }

  function getMyAverageDividendRate() public view returns (uint) {
    return getUserAverageDividendRate(msg.sender);
  }

  /*==========================================
  =            INTERNAL FUNCTIONS            =
  ==========================================*/

  /* Purchase tokens with Ether.
     During ICO phase, dividends should go to the bankroll
     During normal operation:
       0.5% should go to the master dividend card
       0.5% should go to the matching dividend card
       25% of dividends should go to the referrer, if any is provided. */
  function purchaseTokens(uint _incomingEthereum, address _referredBy)
  internal
  returns (uint)
  {
    require(_incomingEthereum >= MIN_ETH_BUYIN || msg.sender == bankrollAddress, "Tried to buy below the min eth buyin threshold.");

    uint toBankRoll;
    uint toReferrer;
    uint toTokenHolders;
    uint toDivCardHolders;

    uint dividendAmount;

    uint tokensBought;
    uint dividendTokensBought;

    uint remainingEth = _incomingEthereum;

    uint fee;

    // 1% for dividend card holders is taken off before anything else
    if (regularPhase) {
      toDivCardHolders = _incomingEthereum.div(100);
      remainingEth = remainingEth.sub(toDivCardHolders);
    }

    /* Next, we tax for dividends:
       Dividends = (ethereum * div%) / 100
       Important note: if we&#39;re out of the ICO phase, the 1% sent to div-card holders
                       is handled prior to any dividend taxes are considered. */

    // Grab the user&#39;s dividend rate
    uint dividendRate = userDividendRate[msg.sender];

    // Calculate the total dividends on this buy
    dividendAmount = (remainingEth.mul(dividendRate)).div(100);

    remainingEth = remainingEth.sub(dividendAmount);

    // If we&#39;re in the ICO and bankroll is buying, don&#39;t tax
    if (icoPhase && msg.sender == bankrollAddress) {
      remainingEth = remainingEth + dividendAmount;
    }

    // Calculate how many tokens to buy:
    tokensBought = ethereumToTokens_(remainingEth);
    dividendTokensBought = tokensBought.mul(dividendRate);

    // This is where we actually mint tokens:
    tokenSupply = tokenSupply.add(tokensBought);
    divTokenSupply = divTokenSupply.add(dividendTokensBought);

    /* Update the total investment tracker
       Note that this must be done AFTER we calculate how many tokens are bought -
       because ethereumToTokens needs to know the amount *before* investment, not *after* investment. */

    currentEthInvested = currentEthInvested + remainingEth;

    // If ICO phase, all the dividends go to the bankroll
    if (icoPhase) {
      toBankRoll = dividendAmount;

      // If the bankroll is buying, we don&#39;t want to send eth back to the bankroll
      // Instead, let&#39;s just give it the tokens it would get in an infinite recursive buy
      if (msg.sender == bankrollAddress) {
        toBankRoll = 0;
      }

      toReferrer = 0;
      toTokenHolders = 0;

      /* ethInvestedDuringICO tracks how much Ether goes straight to tokens,
         not how much Ether we get total.
         this is so that our calculation using "investment" is accurate. */
      ethInvestedDuringICO = ethInvestedDuringICO + remainingEth;
      tokensMintedDuringICO = tokensMintedDuringICO + tokensBought;

      // Cannot purchase more than the hard cap during ICO.
      require(ethInvestedDuringICO <= icoHardCap);
      // Contracts aren&#39;t allowed to participate in the ICO.
      require(tx.origin == msg.sender || msg.sender == bankrollAddress);

      // Cannot purchase more then the limit per address during the ICO.
      ICOBuyIn[msg.sender] += remainingEth;
      //require(ICOBuyIn[msg.sender] <= addressICOLimit || msg.sender == bankrollAddress); // test:remove

      // Stop the ICO phase if we reach the hard cap
      if (ethInvestedDuringICO == icoHardCap) {
        icoPhase = false;
      }

    } else {
      // Not ICO phase, check for referrals

      // 25% goes to referrers, if set
      // toReferrer = (dividends * 25)/100
      if (_referredBy != 0x0000000000000000000000000000000000000000 &&
      _referredBy != msg.sender &&
      frontTokenBalanceLedger_[_referredBy] >= stakingRequirement)
      {
        toReferrer = (dividendAmount.mul(referrer_percentage)).div(100);
        referralBalance_[_referredBy] += toReferrer;
        emit Referral(_referredBy, toReferrer);
      }

      // The rest of the dividends go to token holders
      toTokenHolders = dividendAmount.sub(toReferrer);

      fee = toTokenHolders * magnitude;
      fee = fee - (fee - (dividendTokensBought * (toTokenHolders * magnitude / (divTokenSupply))));

      // Finally, increase the divToken value
      profitPerDivToken = profitPerDivToken.add((toTokenHolders.mul(magnitude)).div(divTokenSupply));
      payoutsTo_[msg.sender] += (int256) ((profitPerDivToken * dividendTokensBought) - fee);
    }

    // Update the buyer&#39;s token amounts
    frontTokenBalanceLedger_[msg.sender] = frontTokenBalanceLedger_[msg.sender].add(tokensBought);
    dividendTokenBalanceLedger_[msg.sender] = dividendTokenBalanceLedger_[msg.sender].add(dividendTokensBought);

    // Transfer to bankroll and div cards
    if (toBankRoll != 0) {ZethrBankroll(bankrollAddress).receiveDividends.value(toBankRoll)();}
    if (regularPhase) {divCardContract.receiveDividends.value(toDivCardHolders)(dividendRate);}

    // This event should help us track where all the eth is going
    emit Allocation(toBankRoll, toReferrer, toTokenHolders, toDivCardHolders, remainingEth);

    // Sanity checking
    uint sum = toBankRoll + toReferrer + toTokenHolders + toDivCardHolders + remainingEth - _incomingEthereum;
    assert(sum == 0);
  }

  // How many tokens one gets from a certain amount of ethereum.
  function ethereumToTokens_(uint _ethereumAmount)
  public
  view
  returns (uint)
  {
    require(_ethereumAmount > MIN_ETH_BUYIN, "Tried to buy tokens with too little eth.");

    if (icoPhase) {
      return _ethereumAmount.div(tokenPriceInitial_) * 1e18;
    }

    /*
     *  i = investment, p = price, t = number of tokens
     *
     *  i_current = p_initial * t_current                   (for t_current <= t_initial)
     *  i_current = i_initial + (2/3)(t_current)^(3/2)      (for t_current >  t_initial)
     *
     *  t_current = i_current / p_initial                   (for i_current <= i_initial)
     *  t_current = t_initial + ((3/2)(i_current))^(2/3)    (for i_current >  i_initial)
     */

    // First, separate out the buy into two segments:
    //  1) the amount of eth going towards ico-price tokens
    //  2) the amount of eth going towards pyramid-price (variable) tokens
    uint ethTowardsICOPriceTokens = 0;
    uint ethTowardsVariablePriceTokens = 0;

    if (currentEthInvested >= ethInvestedDuringICO) {
      // Option One: All the ETH goes towards variable-price tokens
      ethTowardsVariablePriceTokens = _ethereumAmount;

    } else if (currentEthInvested < ethInvestedDuringICO && currentEthInvested + _ethereumAmount <= ethInvestedDuringICO) {
      // Option Two: All the ETH goes towards ICO-price tokens
      ethTowardsICOPriceTokens = _ethereumAmount;

    } else if (currentEthInvested < ethInvestedDuringICO && currentEthInvested + _ethereumAmount > ethInvestedDuringICO) {
      // Option Three: Some ETH goes towards ICO-price tokens, some goes towards variable-price tokens
      ethTowardsICOPriceTokens = ethInvestedDuringICO.sub(currentEthInvested);
      ethTowardsVariablePriceTokens = _ethereumAmount.sub(ethTowardsICOPriceTokens);
    } else {
      // Option Four: Should be impossible, and compiler should optimize it out of existence.
      revert();
    }

    // Sanity check:
    assert(ethTowardsICOPriceTokens + ethTowardsVariablePriceTokens == _ethereumAmount);

    // Separate out the number of tokens of each type this will buy:
    uint icoPriceTokens = 0;
    uint varPriceTokens = 0;

    // Now calculate each one per the above formulas.
    // Note: since tokens have 18 decimals of precision we multiply the result by 1e18.
    if (ethTowardsICOPriceTokens != 0) {
      icoPriceTokens = ethTowardsICOPriceTokens.mul(1e18).div(tokenPriceInitial_);
    }

    if (ethTowardsVariablePriceTokens != 0) {
      // Note: we can&#39;t use "currentEthInvested" for this calculation, we must use:
      //  currentEthInvested + ethTowardsICOPriceTokens
      // This is because a split-buy essentially needs to simulate two separate buys -
      // including the currentEthInvested update that comes BEFORE variable price tokens are bought!

      uint simulatedEthBeforeInvested = toPowerOfThreeHalves(tokenSupply.div(MULTIPLIER * 1e6)).mul(2).div(3) + ethTowardsICOPriceTokens;
      uint simulatedEthAfterInvested = simulatedEthBeforeInvested + ethTowardsVariablePriceTokens;

      /* We have the equations for total tokens above; note that this is for TOTAL.
         To get the number of tokens this purchase buys, use the simulatedEthInvestedBefore
         and the simulatedEthInvestedAfter and calculate the difference in tokens.
         This is how many we get. */

      uint tokensBefore = toPowerOfTwoThirds(simulatedEthBeforeInvested.mul(3).div(2)).mul(MULTIPLIER);
      uint tokensAfter = toPowerOfTwoThirds(simulatedEthAfterInvested.mul(3).div(2)).mul(MULTIPLIER);

      /* Note that we could use tokensBefore = tokenSupply + icoPriceTokens instead of dynamically calculating tokensBefore;
         either should work.

         Investment IS already multiplied by 1e18; however, because this is taken to a power of (2/3),
         we need to multiply the result by 1e6 to get back to the correct number of decimals. */

      varPriceTokens = (1e6) * tokensAfter.sub(tokensBefore);
    }

    uint totalTokensReceived = icoPriceTokens + varPriceTokens;

    assert(totalTokensReceived > 0);
    return totalTokensReceived;
  }

  // How much Ether we get from selling N tokens
  function tokensToEthereum_(uint _tokens)
  public
  view
  returns (uint)
  {
    require(_tokens >= MIN_TOKEN_SELL_AMOUNT, "Tried to sell too few tokens.");

    /*
     *  i = investment, p = price, t = number of tokens
     *
     *  i_current = p_initial * t_current                   (for t_current <= t_initial)
     *  i_current = i_initial + (2/3)(t_current)^(3/2)      (for t_current >  t_initial)
     *
     *  t_current = i_current / p_initial                   (for i_current <= i_initial)
     *  t_current = t_initial + ((3/2)(i_current))^(2/3)    (for i_current >  i_initial)
     */

    // First, separate out the sell into two segments:
    //  1) the amount of tokens selling at the ICO price.
    //  2) the amount of tokens selling at the variable (pyramid) price
    uint tokensToSellAtICOPrice = 0;
    uint tokensToSellAtVariablePrice = 0;

    if (tokenSupply <= tokensMintedDuringICO) {
      // Option One: All the tokens sell at the ICO price.
      tokensToSellAtICOPrice = _tokens;

    } else if (tokenSupply > tokensMintedDuringICO && tokenSupply - _tokens >= tokensMintedDuringICO) {
      // Option Two: All the tokens sell at the variable price.
      tokensToSellAtVariablePrice = _tokens;

    } else if (tokenSupply > tokensMintedDuringICO && tokenSupply - _tokens < tokensMintedDuringICO) {
      // Option Three: Some tokens sell at the ICO price, and some sell at the variable price.
      tokensToSellAtVariablePrice = tokenSupply.sub(tokensMintedDuringICO);
      tokensToSellAtICOPrice = _tokens.sub(tokensToSellAtVariablePrice);

    } else {
      // Option Four: Should be impossible, and the compiler should optimize it out of existence.
      revert();
    }

    // Sanity check:
    assert(tokensToSellAtVariablePrice + tokensToSellAtICOPrice == _tokens);

    // Track how much Ether we get from selling at each price function:
    uint ethFromICOPriceTokens;
    uint ethFromVarPriceTokens;

    // Now, actually calculate:

    if (tokensToSellAtICOPrice != 0) {

      /* Here, unlike the sister equation in ethereumToTokens, we DON&#39;T need to multiply by 1e18, since
         we will be passed in an amount of tokens to sell that&#39;s already at the 18-decimal precision.
         We need to divide by 1e18 or we&#39;ll have too much Ether. */

      ethFromICOPriceTokens = tokensToSellAtICOPrice.mul(tokenPriceInitial_).div(1e18);
    }

    if (tokensToSellAtVariablePrice != 0) {

      /* Note: Unlike the sister function in ethereumToTokens, we don&#39;t have to calculate any "virtual" token count.
         This is because in sells, we sell the variable price tokens **first**, and then we sell the ICO-price tokens.
         Thus there isn&#39;t any weird stuff going on with the token supply.

         We have the equations for total investment above; note that this is for TOTAL.
         To get the eth received from this sell, we calculate the new total investment after this sell.
         Note that we divide by 1e6 here as the inverse of multiplying by 1e6 in ethereumToTokens. */

      uint investmentBefore = toPowerOfThreeHalves(tokenSupply.div(MULTIPLIER * 1e6)).mul(2).div(3);
      uint investmentAfter = toPowerOfThreeHalves((tokenSupply - tokensToSellAtVariablePrice).div(MULTIPLIER * 1e6)).mul(2).div(3);

      ethFromVarPriceTokens = investmentBefore.sub(investmentAfter);
    }

    uint totalEthReceived = ethFromVarPriceTokens + ethFromICOPriceTokens;

    assert(totalEthReceived > 0);
    return totalEthReceived;
  }

  function transferFromInternal(address _from, address _toAddress, uint _amountOfTokens, bytes _data)
  internal
  {
    require(regularPhase);
    require(_toAddress != address(0x0));
    address _customerAddress = _from;
    uint _amountOfFrontEndTokens = _amountOfTokens;

    // Withdraw all outstanding dividends first (including those generated from referrals).
    if (theDividendsOf(true, _customerAddress) > 0) withdrawFrom(_customerAddress);

    // Calculate how many back-end dividend tokens to transfer.
    // This amount is proportional to the caller&#39;s average dividend rate multiplied by the proportion of tokens being transferred.
    uint _amountOfDivTokens = _amountOfFrontEndTokens.mul(getUserAverageDividendRate(_customerAddress)).div(magnitude);

    if (_customerAddress != msg.sender) {
      // Update the allowed balance.
      // Don&#39;t update this if we are transferring our own tokens (via transfer or buyAndTransfer)
      allowed[_customerAddress][msg.sender] -= _amountOfTokens;
    }

    // Exchange tokens
    frontTokenBalanceLedger_[_customerAddress] = frontTokenBalanceLedger_[_customerAddress].sub(_amountOfFrontEndTokens);
    frontTokenBalanceLedger_[_toAddress] = frontTokenBalanceLedger_[_toAddress].add(_amountOfFrontEndTokens);
    dividendTokenBalanceLedger_[_customerAddress] = dividendTokenBalanceLedger_[_customerAddress].sub(_amountOfDivTokens);
    dividendTokenBalanceLedger_[_toAddress] = dividendTokenBalanceLedger_[_toAddress].add(_amountOfDivTokens);

    // Recipient inherits dividend percentage if they have not already selected one.
    if (!userSelectedRate[_toAddress])
    {
      userSelectedRate[_toAddress] = true;
      userDividendRate[_toAddress] = userDividendRate[_customerAddress];
    }

    // Update dividend trackers
    payoutsTo_[_customerAddress] -= (int256) (profitPerDivToken * _amountOfDivTokens);
    payoutsTo_[_toAddress] += (int256) (profitPerDivToken * _amountOfDivTokens);

    uint length;

    assembly {
      length := extcodesize(_toAddress)
    }

    if (length > 0) {
      // its a contract
      // note: at ethereum update ALL addresses are contracts
      ERC223Receiving receiver = ERC223Receiving(_toAddress);
      receiver.tokenFallback(_from, _amountOfTokens, _data);
    }

    // Fire logging event.
    emit Transfer(_customerAddress, _toAddress, _amountOfFrontEndTokens);
  }

  // Called from transferFrom. Always checks if _customerAddress has dividends.
  function withdrawFrom(address _customerAddress)
  internal
  {
    // Setup data
    uint _dividends = theDividendsOf(false, _customerAddress);

    // update dividend tracker
    payoutsTo_[_customerAddress] += (int256) (_dividends * magnitude);

    // add ref. bonus
    _dividends += referralBalance_[_customerAddress];
    referralBalance_[_customerAddress] = 0;

    _customerAddress.transfer(_dividends);

    // Fire logging event.
    emit onWithdraw(_customerAddress, _dividends);
  }


  /*=======================
   =    RESET FUNCTIONS   =
   ======================*/

  function injectEther()
  public
  payable
  onlyAdministrator
  {

  }

  /*=======================
   =   MATHS FUNCTIONS    =
   ======================*/

  function toPowerOfThreeHalves(uint x) public pure returns (uint) {
    // m = 3, n = 2
    // sqrt(x^3)
    return sqrt(x ** 3);
  }

  function toPowerOfTwoThirds(uint x) public pure returns (uint) {
    // m = 2, n = 3
    // cbrt(x^2)
    return cbrt(x ** 2);
  }

  function sqrt(uint x) public pure returns (uint y) {
    uint z = (x + 1) / 2;
    y = x;
    while (z < y) {
      y = z;
      z = (x / z + z) / 2;
    }
  }

  function cbrt(uint x) public pure returns (uint y) {
    uint z = (x + 1) / 3;
    y = x;
    while (z < y) {
      y = z;
      z = (x / (z * z) + 2 * z) / 3;
    }
  }
}

/*=======================
 =     INTERFACES       =
 ======================*/

contract ZethrBankroll {
  function receiveDividends() public payable {}
}

// File: contracts/Games/JackpotHolding.sol

/*
*
* Jackpot holding contract.
*  
* This accepts token payouts from a game for every player loss,
* and on a win, pays out *half* of the jackpot to the winner.
*
* Jackpot payout should only be called from the game.
*
*/
contract JackpotHolding is ERC223Receiving {

  /****************************
   * FIELDS
   ****************************/

  // How many times we&#39;ve paid out the jackpot
  uint public payOutNumber = 0;

  // The amount to divide the token balance by for a pay out (defaults to half the token balance)
  uint public payOutDivisor = 2;

  // Holds the bankroll controller info
  ZethrBankrollControllerInterface controller;

  // Zethr contract
  Zethr zethr;

  /****************************
   * CONSTRUCTOR
   ****************************/

  constructor (address _controllerAddress, address _zethrAddress) public {
    controller = ZethrBankrollControllerInterface(_controllerAddress);
    zethr = Zethr(_zethrAddress);
  }

  function() public payable {}

  function tokenFallback(address /*_from*/, uint /*_amountOfTokens*/, bytes/*_data*/)
  public
  returns (bool)
  {
    // Do nothing, we can track the jackpot by this balance
  }

  /****************************
   * VIEWS
   ****************************/
  function getJackpotBalance()
  public view
  returns (uint)
  {
    // Half of this balance + half of jackpotBalance in each token bankroll
    uint tempBalance;

    for (uint i=0; i<7; i++) {
      tempBalance += controller.tokenBankrolls(i).jackpotBalance() > 0 ? controller.tokenBankrolls(i).jackpotBalance() / payOutDivisor : 0;
    }

    tempBalance += zethr.balanceOf(address(this)) > 0 ? zethr.balanceOf(address(this)) / payOutDivisor : 0;

    return tempBalance;
  }

  /****************************
   * OWNER FUNCTIONS
   ****************************/

  /** @dev Sets the pay out divisor
    * @param _divisor The value to set the new divisor to
    */
  function ownerSetPayOutDivisor(uint _divisor)
  public
  ownerOnly
  {
    require(_divisor != 0);

    payOutDivisor = _divisor;
  }

  /** @dev Sets the address of the game controller
    * @param _controllerAddress The new address of the controller
    */
  function ownerSetControllerAddress(address _controllerAddress)
  public
  ownerOnly
  {
    controller = ZethrBankrollControllerInterface(_controllerAddress);
  }

  /** @dev Transfers the jackpot to _to
    * @param _to Address to send the jackpot tokens to
    */
  function ownerWithdrawZth(address _to)
  public
  ownerOnly
  {
    uint balance = zethr.balanceOf(address(this));
    zethr.transfer(_to, balance);
  }

  /** @dev Transfers any ETH received from dividends to _to
    * @param _to Address to send the ETH to
    */
  function ownerWithdrawEth(address _to)
  public
  ownerOnly
  {
    _to.transfer(address(this).balance);
  }

  /****************************
   * GAME FUNCTIONS
   ****************************/

  function gamePayOutWinner(address _winner)
  public
  gameOnly
  {
    // Call the payout function on all 7 token bankrolls
    for (uint i=0; i<7; i++) {
      controller.tokenBankrolls(i).payJackpotToWinner(_winner, payOutDivisor);
    }

    uint payOutAmount;

    // Calculate pay out & pay out
    if (zethr.balanceOf(address(this)) >= 1e10) {
      payOutAmount = zethr.balanceOf(address(this)) / payOutDivisor;
    }

    if (payOutAmount >= 1e10) {
      zethr.transfer(_winner, payOutAmount);
    }

    // Increment the statistics fields
    payOutNumber += 1;

    // Emit jackpot event
    emit JackpotPayOut(_winner, payOutNumber);
  }

  /****************************
   * EVENTS
   ****************************/

  event JackpotPayOut(
    address winner,
    uint payOutNumber
  );

  /****************************
   * MODIFIERS
   ****************************/

  // Only an owner can call this method (controller is always an owner)
  modifier ownerOnly()
  {
    require(msg.sender == address(controller) || controller.multiSigWallet().isOwner(msg.sender));
    _;
  }

  // Only a game can call this method
  modifier gameOnly()
  {
    require(controller.validGameAddresses(msg.sender));
    _;
  }
}

// File: contracts/Bankroll/ZethrGame.sol

/* Zethr Game Interface
 *
 * Contains the necessary functions to integrate with
 * the Zethr Token bankrolls & the Zethr game ecosystem.
 *
 * Token Bankroll Functions:
 *  - execute
 *
 * Player Functions:
 *  - finish
 *
 * Bankroll Controller / Owner Functions:
 *  - pauseGame
 *  - resumeGame
 *  - set resolver percentage
 *  - set controller address
 *
 * Player/Token Bankroll Functions:
 *  - resolvePendingBets
*/
contract ZethrGame {
  using SafeMath for uint;
  using SafeMath for uint56;

  // Default events:
  event Result (address player, uint amountWagered, int amountOffset);
  event Wager (address player, uint amount, bytes data);

  // Queue of pending/unresolved bets
  address[] pendingBetsQueue;
  uint queueHead = 0;
  uint queueTail = 0;

  // Store each player&#39;s latest bet via mapping
  mapping(address => BetBase) bets;

  // Bet structures must start with this layout
  struct BetBase {
    // Must contain these in this order
    uint56 tokenValue;    // Multiply by 1e14 to get tokens
    uint48 blockNumber;
    uint8 tier;
    // Game specific structures can add more after this
  }

  // Mapping of addresses to their *position* in the queue
  // Zero = they aren&#39;t in the queue
  mapping(address => uint) pendingBetsMapping;

  // Holds the bankroll controller info
  ZethrBankrollControllerInterface controller;

  // Is the game paused?
  bool paused;

  // Minimum bet should always be >= 1
  uint minBet = 1e18;

  // Percentage that a resolver gets when he resolves bets for the house
  uint resolverPercentage;

  // Every game has a name
  string gameName;

  constructor (address _controllerAddress, uint _resolverPercentage, string _name) public {
    controller = ZethrBankrollControllerInterface(_controllerAddress);
    resolverPercentage = _resolverPercentage;
    gameName = _name;
  }

  /** @dev Gets the max profit of this game as decided by the token bankroll
    * @return uint The maximum profit
    */
  function getMaxProfit()
  public view
  returns (uint)
  {
    return ZethrTokenBankrollInterface(msg.sender).getMaxProfit(address(this));
  }

  /** @dev Pauses the game, preventing anyone from placing bets
    */
  function ownerPauseGame()
  public
  ownerOnly
  {
    paused = true;
  }

  /** @dev Resumes the game, allowing bets
    */
  function ownerResumeGame()
  public
  ownerOnly
  {
    paused = false;
  }

  /** @dev Sets the percentage of the bets that a resolver gets when resolving tokens.
    * @param _percentage The percentage as x/1,000,000 that the resolver gets
    */
  function ownerSetResolverPercentage(uint _percentage)
  public
  ownerOnly
  {
    require(_percentage <= 1000000);
    resolverPercentage = _percentage;
  }

  /** @dev Sets the address of the game controller
    * @param _controllerAddress The new address of the controller
    */
  function ownerSetControllerAddress(address _controllerAddress)
  public
  ownerOnly
  {
    controller = ZethrBankrollControllerInterface(_controllerAddress);
  }

  // Every game should have a name
  /** @dev Sets the name of the game
    * @param _name The name of the game
    */
  function ownerSetGameName(string _name)
  ownerOnly
  public
  {
    gameName = _name;
  }

  /** @dev Gets the game name
    * @return The name of the game
    */
  function getGameName()
  public view
  returns (string)
  {
    return gameName;
  }

  /** @dev Resolve expired bets in the queue. Gives a percentage of the house edge to the resolver as ZTH
    * @param _numToResolve The number of bets to resolve.
    * @return tokensEarned The number of tokens earned
    * @return queueHead The new head of the queue
    */
  function resolveExpiredBets(uint _numToResolve)
  public
  returns (uint tokensEarned_, uint queueHead_)
  {
    uint mQueue = queueHead;
    uint head;
    uint tail = (mQueue + _numToResolve) > pendingBetsQueue.length ? pendingBetsQueue.length : (mQueue + _numToResolve);
    uint tokensEarned = 0;

    for (head = mQueue; head < tail; head++) {
      // Check the head of the queue to see if there is a resolvable bet
      // This means the bet at the queue head is older than 255 blocks AND is not 0
      // (However, if the address at the head is null, skip it, it&#39;s already been resolved)
      if (pendingBetsQueue[head] == address(0x0)) {
        continue;
      }

      if (bets[pendingBetsQueue[head]].blockNumber != 0 && block.number > 256 + bets[pendingBetsQueue[head]].blockNumber) {
        // Resolve the bet
        // finishBetfrom returns the *player* profit
        // this will be negative if the player lost and the house won
        // so flip it to get the house profit, if any
        int sum = - finishBetFrom(pendingBetsQueue[head]);

        // Tokens earned is a percentage of the loss
        if (sum > 0) {
          tokensEarned += (uint(sum).mul(resolverPercentage)).div(1000000);
        }

        // Queue-tail is always the "next" open spot, so queue head and tail will never overlap
      } else {
        // If we can&#39;t resolve a bet, stop going down the queue
        break;
      }
    }

    queueHead = head;

    // Send the earned tokens to the resolver
    if (tokensEarned >= 1e14) {
      controller.gamePayoutResolver(msg.sender, tokensEarned);
    }

    return (tokensEarned, head);
  }

  /** @dev Finishes the bet of the sender, if it exists.
    * @return int The total profit (positive or negative) earned by the sender
    */
  function finishBet()
  public
  hasNotBetThisBlock(msg.sender)
  returns (int)
  {
    return finishBetFrom(msg.sender);
  }

  /** @dev Resturns a random number
    * @param _blockn The block number to base the random number off of
    * @param _entropy Data to use in the random generation
    * @param _index Data to use in the random generation
    * @return randomNumber The random number to return
    */
  function maxRandom(uint _blockn, address _entropy, uint _index)
  private view
  returns (uint256 randomNumber)
  {
    return uint256(keccak256(
        abi.encodePacked(
          blockhash(_blockn),
          _entropy,
          _index
        )));
  }

  /** @dev Returns a random number
    * @param _upper The upper end of the range, exclusive
    * @param _blockn The block number to use for the random number
    * @param _entropy An address to be used for entropy
    * @param _index A number to get the next random number
    * @return randomNumber The random number
    */
  function random(uint256 _upper, uint256 _blockn, address _entropy, uint _index)
  internal view
  returns (uint256 randomNumber)
  {
    return maxRandom(_blockn, _entropy, _index) % _upper;
  }

  // Prevents the user from placing two bets in one block
  modifier hasNotBetThisBlock(address _sender)
  {
    require(bets[_sender].blockNumber != block.number);
    _;
  }

  // Requires that msg.sender is one of the token bankrolls
  modifier bankrollOnly {
    require(controller.isTokenBankroll(msg.sender));
    _;
  }

  // Requires that the game is not paused
  modifier isNotPaused {
    require(!paused);
    _;
  }

  // Requires that the bet given has max profit low enough
  modifier betIsValid(uint _betSize, uint _tier, bytes _data) {
    uint divRate = ZethrTierLibrary.getDivRate(_tier);
    require(isBetValid(_betSize, divRate, _data));
    _;
  }

  // Only an owner can call this method (controller is always an owner)
  modifier ownerOnly()
  {
    require(msg.sender == address(controller) || controller.multiSigWallet().isOwner(msg.sender));
    _;
  }

  /** @dev Places a bet. Callable only by token bankrolls
    * @param _player The player that is placing the bet
    * @param _tokenCount The total number of tokens bet
    * @param _divRate The dividend rate of the player
    * @param _data The game-specific data, encoded in bytes-form
    */
  function execute(address _player, uint _tokenCount, uint _divRate, bytes _data) public;

  /** @dev Resolves the bet of the supplied player.
    * @param _playerAddress The address of the player whos bet we are resolving
    * @return int The total profit the player earned, positive or negative
    */
  function finishBetFrom(address _playerAddress) internal returns (int);

  /** @dev Determines if a supplied bet is valid
    * @param _tokenCount The total number of tokens bet
    * @param _divRate The dividend rate of the bet
    * @param _data The game-specific bet data
    * @return bool Whether or not the bet is valid
    */
  function isBetValid(uint _tokenCount, uint _divRate, bytes _data) public view returns (bool);
}

// File: contracts/Games/ZethrSlots.sol

/* The actual game contract.
 *
 * This contract contains the actual game logic,
 * including placing bets (execute), resolving bets,
 * and resolving expired bets.
*/
contract ZethrSlots is ZethrGame {

  /****************************
   * GAME SPECIFIC
   ****************************/

  // Slots-specific bet structure
  struct Bet {
    // Must contain these in this order
    uint56 tokenValue;
    uint48 blockNumber;
    uint8 tier;
    // Game specific
    uint8 numSpins;
  }

  /****************************
   * FIELDS
   ****************************/

  // Sections with identical multipliers compressed for optimization
  uint[14] MULTIPLIER_BOUNDARIES = [uint(299), 3128, 44627, 46627, 49127, 51627, 53127, 82530, 150423, 310818, 364283, 417748, 471213, ~uint256(0)];

  // Maps indexes of results sections to multipliers as x/100
  uint[14] MULTIPLIERS = [uint(5000), 2000, 300, 1100, 750, 900, 1300, 250, 150, 100, 200, 125, 133, 250];

  // The holding contract for jackpot tokens
  JackpotHolding public jackpotHoldingContract;

  /****************************
   * CONSTRUCTOR
   ****************************/

  constructor (address _controllerAddress, uint _resolverPercentage, string _name)
  ZethrGame(_controllerAddress, _resolverPercentage, _name)
  public
  {
  }

  /****************************
   * USER METHODS
   ****************************/

  /** @dev Retrieve the results of the last spin of a plyer, for web3 calls.
    * @param _playerAddress The address of the player
    */
  function getLastSpinOutput(address _playerAddress)
  public view
  returns (uint winAmount, uint lossAmount, uint jackpotAmount, uint jackpotWins, uint[] memory output)
  {
    // Cast to Bet and read from storage
    Bet storage playerBetInStorage = getBet(_playerAddress);
    Bet memory playerBet = playerBetInStorage;

    // Safety check
    require(playerBet.blockNumber != 0);

    (winAmount, lossAmount, jackpotAmount, jackpotWins, output) = getSpinOutput(playerBet.blockNumber, playerBet.numSpins, playerBet.tokenValue.mul(1e14), _playerAddress);

    return (winAmount, lossAmount, jackpotAmount, jackpotWins, output);
  }
    
    event SlotsResult(
        uint    _blockNumber,
        address _target,
        uint    _numSpins,
        uint    _tokenValue,
        uint    _winAmount,
        uint    _lossAmount,
        uint[]  _output
    );
    
  /** @dev Retrieve the results of the spin, for web3 calls.
    * @param _blockNumber The block number of the spin
    * @param _numSpins The number of spins of this bet
    * @param _tokenValue The total number of tokens bet
    * @param _target The address of the better
    * @return winAmount The total number of tokens won
    * @return lossAmount The total number of tokens lost
    * @return jackpotAmount The total amount of tokens won in the jackpot
    * @return output An array of all of the results of a multispin
    */
  function getSpinOutput(uint _blockNumber, uint _numSpins, uint _tokenValue, address _target)
  public view
  returns (uint winAmount, uint lossAmount, uint jackpotAmount, uint jackpotWins, uint[] memory output)
  {
    output = new uint[](_numSpins);
    // Where the result sections start and stop

    // If current block for the first spin is older than 255 blocks, ALL spins are losses
    if (block.number - _blockNumber > 255) {
      // Output stays 0 for eveything, this is a loss
      // No jackpot wins
      // No wins
      // Loss is the total tokens bet
      lossAmount = (_tokenValue.mul(_numSpins).mul(99)).div(100);
      jackpotAmount = _tokenValue.mul(_numSpins).div(100);
    } else {

      for (uint i = 0; i < _numSpins; i++) {
        // Store the output
        output[i] = random(1000000, _blockNumber, _target, i) + 1;

        if (output[i] < 2) {
          // Jackpot get
          jackpotWins++;
          lossAmount += _tokenValue;
        } else if (output[i] > 506856) {
          // Player loss
          lossAmount += (_tokenValue.mul(99)).div(100);
          jackpotAmount += _tokenValue.div(100);
        } else {
          // Player win

          // Iterate over the array of win results to find the correct multiplier array index
          uint index;
          for (index = 0; index < MULTIPLIER_BOUNDARIES.length; index++) {
            if (output[i] < MULTIPLIER_BOUNDARIES[index]) break;
          }
          // Use index to find the correct multipliers
          winAmount += _tokenValue.mul(MULTIPLIERS[index]).div(100);
        }
      }
    }
    emit SlotsResult(_blockNumber, _target, _numSpins, _tokenValue, winAmount, lossAmount, output);
    return (winAmount, lossAmount, jackpotAmount, jackpotWins, output);
  }

  /** @dev Retrieve the results of the spin, for contract calls.
    * @param _blockNumber The block number of the spin
    * @param _numSpins The number of spins of this bet
    * @param _tokenValue The total number of tokens bet
    * @param _target The address of the better
    * @return winAmount The total number of tokens won
    * @return lossAmount The total number of tokens lost
    * @return jackpotAmount The total amount of tokens won in the jackpot
    */
  function getSpinResults(uint _blockNumber, uint _numSpins, uint _tokenValue, address _target)
  public
  returns (uint winAmount, uint lossAmount, uint jackpotAmount, uint jackpotWins)
  {
    // Where the result sections start and stop

    // If current block for the first spin is older than 255 blocks, ALL spins are losses
    if (block.number - _blockNumber > 255) {
      // Output stays 0 for eveything, this is a loss
      // No jackpot wins
      // No wins
      // Loss is the total tokens bet
      lossAmount = (_tokenValue.mul(_numSpins).mul(99)).div(100);
      jackpotAmount = _tokenValue.mul(_numSpins).div(100);
    } else {

      uint result;

      for (uint i = 0; i < _numSpins; i++) {
        // Store the output
        result = random(1000000, _blockNumber, _target, i) + 1;

        if (result < 2) {
          // Jackpot get
          jackpotWins++;
        } else if (result > 506856) {
          // Player loss
          lossAmount += (_tokenValue.mul(99)).div(100);
          jackpotAmount += _tokenValue.div(100);
        } else {
          // Player win

          // Iterate over the array of win results to find the correct multiplier array index
          uint index;
          for (index = 0; index < MULTIPLIER_BOUNDARIES.length; index++) {
            if (result < MULTIPLIER_BOUNDARIES[index]) break;
          }
          // Use index to find the correct multipliers
          winAmount += _tokenValue.mul(MULTIPLIERS[index]).div(100);
        }
      }
    }
    return (winAmount, lossAmount, jackpotAmount, jackpotWins);
  }

  /****************************
   * OWNER METHODS
   ****************************/

  /** @dev Set the address of the jackpot contract
    * @param _jackpotAddress The address of the jackpot contract
    */
  function ownerSetJackpotAddress(address _jackpotAddress)
  public
  ownerOnly
  {
    jackpotHoldingContract = JackpotHolding(_jackpotAddress);
  }

  /****************************
   * INTERNALS
   ****************************/

  /** @dev Returs the bet struct of a player
    * @param _playerAddress The address of the player
    * @return Bet The bet of the player
    */
  function getBet(address _playerAddress)
  internal view
  returns (Bet storage)
  {
    // Cast BetBase to Bet
    BetBase storage betBase = bets[_playerAddress];

    Bet storage playerBet;
    assembly {
    // tmp is pushed onto stack and points to betBase slot in storage
      let tmp := betBase_slot

    // swap1 swaps tmp and playerBet pointers
      swap1
    }
    // tmp is popped off the stack

    // playerBet now points to betBase
    return playerBet;
  }

  /** @dev Resturns a random number
    * @param _blockn The block number to base the random number off of
    * @param _entropy Data to use in the random generation
    * @param _index Data to use in the random generation
    * @return randomNumber The random number to return
    */
  function maxRandom(uint _blockn, address _entropy, uint _index)
  private view
  returns (uint256 randomNumber)
  {
    return uint256(keccak256(
        abi.encodePacked(
          blockhash(_blockn),
          _entropy,
          _index
        )));
  }

  /** @dev Returns a random number
    * @param _upper The upper end of the range, exclusive
    * @param _blockn The block number to use for the random number
    * @param _entropy An address to be used for entropy
    * @param _index A number to get the next random number
    * @return randomNumber The random number
    */
  function random(uint256 _upper, uint256 _blockn, address _entropy, uint _index)
  internal view
  returns (uint256 randomNumber)
  {
    return maxRandom(_blockn, _entropy, _index) % _upper;
  }

  /****************************
   * OVERRIDDEN METHODS
   ****************************/

  /** @dev Resolves the bet of the supplied player.
    * @param _playerAddress The address of the player whos bet we are resolving
    * @return totalProfit The total profit the player earned, positive or negative
    */
  function finishBetFrom(address _playerAddress)
  internal
  returns (int /*totalProfit*/)
  {
    // Memory vars to hold data as we compute it
    uint winAmount;
    uint lossAmount;
    uint jackpotAmount;
    uint jackpotWins;

    // Cast to Bet and read from storage
    Bet storage playerBetInStorage = getBet(_playerAddress);
    Bet memory playerBet = playerBetInStorage;

    // Player should not be able to resolve twice!
    require(playerBet.blockNumber != 0);

    // Safety check
    require(playerBet.blockNumber != 0);
    playerBetInStorage.blockNumber = 0;

    // Iterate over the number of spins and calculate totals:
    //  - player win amount
    //  - bankroll win amount
    //  - jackpot wins
    (winAmount, lossAmount, jackpotAmount, jackpotWins) = getSpinResults(playerBet.blockNumber, playerBet.numSpins, playerBet.tokenValue.mul(1e14), _playerAddress);

    // Figure out the token bankroll address
    address tokenBankrollAddress = controller.getTokenBankrollAddressFromTier(playerBet.tier);
    ZethrTokenBankrollInterface bankroll = ZethrTokenBankrollInterface(tokenBankrollAddress);

    // Call into the bankroll to do some token accounting
    bankroll.gameTokenResolution(winAmount, _playerAddress, jackpotAmount, address(jackpotHoldingContract), playerBet.tokenValue.mul(1e14).mul(playerBet.numSpins));

    // Pay out jackpot if won
    if (jackpotWins > 0) {
      for (uint x = 0; x < jackpotWins; x++) {
        jackpotHoldingContract.gamePayOutWinner(_playerAddress);
      }
    }

    // Grab the position of the player in the pending bets queue
    uint index = pendingBetsMapping[_playerAddress];

    // Remove the player from the pending bets queue by setting the address to 0x0
    pendingBetsQueue[index] = address(0x0);

    // Delete the player&#39;s bet by setting the mapping to zero
    pendingBetsMapping[_playerAddress] = 0;

    emit Result(_playerAddress, playerBet.tokenValue.mul(1e14), int(winAmount) - int(lossAmount) - int(jackpotAmount));

    // Return all bet results + total *player* profit
    return (int(winAmount) - int(lossAmount) - int(jackpotAmount));
  }

  /** @dev Places a bet. Callable only by token bankrolls
    * @param _player The player that is placing the bet
    * @param _tokenCount The total number of tokens bet
    * @param _tier The div rate tier the player falls in
    * @param _data The game-specific data, encoded in bytes-form
    */
  function execute(address _player, uint _tokenCount, uint _tier, bytes _data)
  isNotPaused
  bankrollOnly
  betIsValid(_tokenCount, _tier, _data)
  hasNotBetThisBlock(_player)
  public
  {
    Bet storage playerBet = getBet(_player);

    // Check for a player bet and resolve if necessary
    if (playerBet.blockNumber != 0) {
      finishBetFrom(_player);
    }

    uint8 spins = uint8(_data[0]);

    // Set bet information
    playerBet.tokenValue = uint56(_tokenCount.div(spins).div(1e14));
    playerBet.blockNumber = uint48(block.number);
    playerBet.tier = uint8(_tier);
    playerBet.numSpins = spins;

    // Add player to the pending bets queue
    pendingBetsQueue.length++;
    pendingBetsQueue[queueTail] = _player;
    queueTail++;

    // Add the player&#39;s position in the queue to the pending bets mapping
    pendingBetsMapping[_player] = queueTail - 1;

    // Emit event
    emit Wager(_player, _tokenCount, _data);
  }

  /** @dev Determines if a supplied bet is valid
    * @param _tokenCount The total number of tokens bet
    * @param _data The game-specific bet data
    * @return bool Whether or not the bet is valid
    */
  function isBetValid(uint _tokenCount, uint /*_divRate*/, bytes _data)
  public view
  returns (bool)
  {
    // Since the max win is 50x (for slots), the bet size must be
    // <= 1/50 * the maximum profit.
    uint8 spins = uint8(_data[0]);
    return (_tokenCount.div(spins).mul(50) <= getMaxProfit()) && (_tokenCount.div(spins) >= minBet);
  }
}