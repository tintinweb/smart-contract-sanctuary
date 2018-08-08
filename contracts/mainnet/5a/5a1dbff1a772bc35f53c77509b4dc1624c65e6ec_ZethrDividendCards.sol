pragma solidity ^0.4.23;

/**

                                  ███████╗███████╗████████╗██╗  ██╗██████╗
                                  ╚══███╔╝██╔════╝╚══██╔══╝██║  ██║██╔══██╗
                                    ███╔╝ █████╗     ██║   ███████║██████╔╝
                                   ███╔╝  ██╔══╝     ██║   ██╔══██║██╔══██╗
                                  ███████╗███████╗   ██║   ██║  ██║██║  ██║
                                  ╚══════╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝

.------..------..------..------..------..------..------..------.     .------..------..------..------..------.
|D.--. ||I.--. ||V.--. ||I.--. ||D.--. ||E.--. ||N.--. ||D.--. |.-.  |C.--. ||A.--. ||R.--. ||D.--. ||S.--. |
| :/\: || (\/) || :(): || (\/) || :/\: || (\/) || :(): || :/\: ((5)) | :/\: || (\/) || :(): || :/\: || :/\: |
| (__) || :\/: || ()() || :\/: || (__) || :\/: || ()() || (__) |&#39;-.-.| :\/: || :\/: || ()() || (__) || :\/: |
| &#39;--&#39;D|| &#39;--&#39;I|| &#39;--&#39;V|| &#39;--&#39;I|| &#39;--&#39;D|| &#39;--&#39;E|| &#39;--&#39;N|| &#39;--&#39;D| ((1)) &#39;--&#39;C|| &#39;--&#39;A|| &#39;--&#39;R|| &#39;--&#39;D|| &#39;--&#39;S|
`------&#39;`------&#39;`------&#39;`------&#39;`------&#39;`------&#39;`------&#39;`------&#39;  &#39;-&#39;`------&#39;`------&#39;`------&#39;`------&#39;`------&#39;

An interactive, variable-dividend rate contract with an ICO-capped price floor and collectibles.
This contract describes those collectibles. Don&#39;t get left with a hot potato!

Launched at 00:00 GMT on 12th May 2018.

Credits
=======

Analysis:
    blurr
    Randall

Contract Developers:
    Etherguy
    klob
    Norsefire

Front-End Design:
    cryptodude
    oguzhanox
    TropicalRogue

**/

// Required ERC721 interface.

contract ERC721 {

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

contract ZethrDividendCards is ERC721 {
    using SafeMath for uint;

  /*** EVENTS ***/

  /// @dev The Birth event is fired whenever a new dividend card comes into existence.
  event Birth(uint tokenId, string name, address owner);

  /// @dev The TokenSold event is fired whenever a token (dividend card, in this case) is sold.
  event TokenSold(uint tokenId, uint oldPrice, uint newPrice, address prevOwner, address winner, string name);

  /// @dev Transfer event as defined in current draft of ERC721.
  ///  Ownership is assigned, including births.
  event Transfer(address from, address to, uint tokenId);

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

	onSale = false;

    administrators[0x4F4eBF556CFDc21c3424F85ff6572C77c514Fcae] = true; // Norsefire
    administrators[0x11e52c75998fe2E7928B191bfc5B25937Ca16741] = true; // klob
    administrators[0x20C945800de43394F70D789874a4daC9cFA57451] = true; // Etherguy
    administrators[0xef764BAC8a438E7E498c2E5fcCf0f174c3E3F8dB] = true; // blurr

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
        onlyCreator
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
    BANKROLL.send(bankrollProfit);
    oldOwner.send(oldOwnerProfit);

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

    _masterAddress.send(toMaster);
    _regularAddress.send(toRegular);
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

// SafeMath library
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint a, uint b) internal pure returns (uint) {
    if (a == 0) {
      return 0;
    }
    uint c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint a, uint b) internal pure returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}

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