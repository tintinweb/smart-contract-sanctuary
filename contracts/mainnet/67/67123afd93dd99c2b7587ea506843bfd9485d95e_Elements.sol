pragma solidity ^0.4.2;

// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
// @author Dieter Shirley <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="fa9e9f8e9fba9b82939597809f94d49995">[email&#160;protected]</a>> (https://github.com/dete)
contract ERC721 {
  	// Required methods
  	function approve(address _to, uint256 _tokenId) public;
  	function balanceOf(address _owner) public view returns (uint256 balance);
  	function implementsERC721() public pure returns (bool);
  	function ownerOf(uint256 _tokenId) public view returns (address addr);
  	function takeOwnership(uint256 _tokenId) public;
  	function totalSupply() public view returns (uint256 total);
  	function transferFrom(address _from, address _to, uint256 _tokenId) public;
  	function transfer(address _to, uint256 _tokenId) public;
	
  	event Transfer(address indexed from, address indexed to, uint256 tokenId);
  	event Approval(address indexed owner, address indexed approved, uint256 tokenId);
}

contract Elements is ERC721 {

  	/*** EVENTS ***/
  	// @dev The Birth event is fired whenever a new element comes into existence.
  	event Birth(uint256 tokenId, string name, address owner);

  	// @dev The TokenSold event is fired whenever a token is sold.
  	event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

  	// @dev Transfer event as defined in current draft of ERC721. Ownership is assigned, including births.
  	event Transfer(address from, address to, uint256 tokenId);

  	/*** CONSTANTS, VARIABLES ***/

	// @notice Name and symbol of the non fungible token, as defined in ERC721.
	string public constant NAME = "CryptoElements"; // solhint-disable-line
	string public constant SYMBOL = "CREL"; // solhint-disable-line

  	uint256 private periodicStartingPrice = 5 ether;
  	uint256 private elementStartingPrice = 0.005 ether;
  	uint256 private scientistStartingPrice = 0.1 ether;
  	uint256 private specialStartingPrice = 0.05 ether;

  	uint256 private firstStepLimit =  0.05 ether;
  	uint256 private secondStepLimit = 0.75 ether;
  	uint256 private thirdStepLimit = 3 ether;

  	bool private periodicTableExists = false;

  	uint256 private elementCTR = 0;
  	uint256 private scientistCTR = 0;
  	uint256 private specialCTR = 0;

  	uint256 private constant elementSTART = 1;
  	uint256 private constant scientistSTART = 1000;
  	uint256 private constant specialSTART = 10000;

  	uint256 private constant specialLIMIT = 5000;

  	/*** STORAGE ***/

  	// @dev A mapping from element IDs to the address that owns them. All elements have
  	//  some valid owner address.
  	mapping (uint256 => address) public elementIndexToOwner;

  	// @dev A mapping from owner address to count of tokens that address owns.
  	//  Used internally inside balanceOf() to resolve ownership count.
  	mapping (address => uint256) private ownershipTokenCount;

  	// @dev A mapping from ElementIDs to an address that has been approved to call
  	//  transferFrom(). Each Element can only have one approved address for transfer
  	//  at any time. A zero value means no approval is outstanding.
  	mapping (uint256 => address) public elementIndexToApproved;

  	// @dev A mapping from ElementIDs to the price of the token.
  	mapping (uint256 => uint256) private elementIndexToPrice;

  	// The addresses of the accounts (or contracts) that can execute actions within each roles.
  	address public ceoAddress;
  	address public cooAddress;

  	/*** DATATYPES ***/
  	struct Element {
  		uint256 tokenId;
    	string name;
    	uint256 scientistId;
  	}

  	mapping(uint256 => Element) elements;

  	uint256[] tokens;

  	/*** ACCESS MODIFIERS ***/
  	// @dev Access modifier for CEO-only functionality
  	modifier onlyCEO() {
    	require(msg.sender == ceoAddress);
    	_;
  	}

  	// @dev Access modifier for COO-only functionality
  	modifier onlyCOO() {
  	  require(msg.sender == cooAddress);
  	  _;
  	}

  	// Access modifier for contract owner only functionality
  	modifier onlyCLevel() {
  	  	require(
  	    	msg.sender == ceoAddress ||
  	    	msg.sender == cooAddress
  	  	);
  	  	_;
  	}

  	/*** CONSTRUCTOR ***/
  	function Elements() public {
  	  	ceoAddress = msg.sender;
  	  	cooAddress = msg.sender;

  	  	createContractPeriodicTable("Periodic");
  	}

  	/*** PUBLIC FUNCTIONS ***/
  	// @notice Grant another address the right to transfer token via takeOwnership() and transferFrom().
  	// @param _to The address to be granted transfer approval. Pass address(0) to
  	//  clear all approvals.
  	// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
  	// @dev Required for ERC-721 compliance.
  	function approve(address _to, uint256 _tokenId) public {
  	  	// Caller must own token.
  	  	require(_owns(msg.sender, _tokenId));
	
	  	elementIndexToApproved[_tokenId] = _to;
	
	  	Approval(msg.sender, _to, _tokenId);
  	}

  	// For querying balance of a particular account
  	// @param _owner The address for balance query
  	// @dev Required for ERC-721 compliance.
  	function balanceOf(address _owner) public view returns (uint256 balance) {
    	return ownershipTokenCount[_owner];
  	}

  	// @notice Returns all the relevant information about a specific element.
  	// @param _tokenId The tokenId of the element of interest.
  	function getElement(uint256 _tokenId) public view returns (
  		uint256 tokenId,
    	string elementName,
    	uint256 sellingPrice,
    	address owner,
    	uint256 scientistId
  	) {
    	Element storage element = elements[_tokenId];
    	tokenId = element.tokenId;
    	elementName = element.name;
    	sellingPrice = elementIndexToPrice[_tokenId];
    	owner = elementIndexToOwner[_tokenId];
    	scientistId = element.scientistId;
  	}

  	function implementsERC721() public pure returns (bool) {
    	return true;
  	}

  	// For querying owner of token
  	// @param _tokenId The tokenID for owner inquiry
  	// @dev Required for ERC-721 compliance.
  	function ownerOf(uint256 _tokenId) public view returns (address owner) {
    	owner = elementIndexToOwner[_tokenId];
    	require(owner != address(0));
  	}

  	function payout(address _to) public onlyCLevel {
    	_payout(_to);
  	}

  	// Allows someone to send ether and obtain the token
  	function purchase(uint256 _tokenId) public payable {
    	address oldOwner = elementIndexToOwner[_tokenId];
    	address newOwner = msg.sender;

    	uint256 sellingPrice = elementIndexToPrice[_tokenId];
    	// Making sure token owner is not sending to self
    	require(oldOwner != newOwner);
    	require(sellingPrice > 0);

    	// Safety check to prevent against an unexpected 0x0 default.
    	require(_addressNotNull(newOwner));

    	// Making sure sent amount is greater than or equal to the sellingPrice
    	require(msg.value >= sellingPrice);

    	uint256 ownerPayout = SafeMath.mul(SafeMath.div(sellingPrice, 100), 96);
    	uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);
    	uint256	feeOnce = SafeMath.div(SafeMath.sub(sellingPrice, ownerPayout), 4);
    	uint256 fee_for_dev = SafeMath.mul(feeOnce, 2);

    	// Pay previous tokenOwner if owner is not contract
    	// and if previous price is not 0
    	if (oldOwner != address(this)) {
      		// old owner gets entire initial payment back
      		oldOwner.transfer(ownerPayout);
    	} else {
      		fee_for_dev = SafeMath.add(fee_for_dev, ownerPayout);
    	}

    	// Taxes for Periodic Table owner
	    if (elementIndexToOwner[0] != address(this)) {
	    	elementIndexToOwner[0].transfer(feeOnce);
	    } else {
	    	fee_for_dev = SafeMath.add(fee_for_dev, feeOnce);
	    }

	    // Taxes for Scientist Owner for given Element
	    uint256 scientistId = elements[_tokenId].scientistId;

	    if ( scientistId != scientistSTART ) {
	    	if (elementIndexToOwner[scientistId] != address(this)) {
		    	elementIndexToOwner[scientistId].transfer(feeOnce);
		    } else {
		    	fee_for_dev = SafeMath.add(fee_for_dev, feeOnce);
		    }
	    } else {
	    	fee_for_dev = SafeMath.add(fee_for_dev, feeOnce);
	    }
	        
    	if (purchaseExcess > 0) {
    		msg.sender.transfer(purchaseExcess);
    	}

    	ceoAddress.transfer(fee_for_dev);

    	_transfer(oldOwner, newOwner, _tokenId);

    	//TokenSold(_tokenId, sellingPrice, elementIndexToPrice[_tokenId], oldOwner, newOwner, elements[_tokenId].name);
    	// Update prices
    	if (sellingPrice < firstStepLimit) {
      		// first stage
      		elementIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), 100);
    	} else if (sellingPrice < secondStepLimit) {
      		// second stage
      		elementIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 150), 100);
    	} else if (sellingPrice < thirdStepLimit) {
    	  	// third stage
      		elementIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 130), 100);
    	} else {
      		// fourth stage
      		elementIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 115), 100);
    	}
  	}

  	function priceOf(uint256 _tokenId) public view returns (uint256 price) {
	    return elementIndexToPrice[_tokenId];
  	}

  	// @dev Assigns a new address to act as the CEO. Only available to the current CEO.
  	// @param _newCEO The address of the new CEO
  	function setCEO(address _newCEO) public onlyCEO {
	    require(_newCEO != address(0));

    	ceoAddress = _newCEO;
  	}

  	// @dev Assigns a new address to act as the COO. Only available to the current COO.
  	// @param _newCOO The address of the new COO
  	function setCOO(address _newCOO) public onlyCEO {
    	require(_newCOO != address(0));
    	cooAddress = _newCOO;
  	}

  	// @notice Allow pre-approved user to take ownership of a token
  	// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
  	// @dev Required for ERC-721 compliance.
  	function takeOwnership(uint256 _tokenId) public {
    	address newOwner = msg.sender;
    	address oldOwner = elementIndexToOwner[_tokenId];

    	// Safety check to prevent against an unexpected 0x0 default.
    	require(_addressNotNull(newOwner));

    	// Making sure transfer is approved
    	require(_approved(newOwner, _tokenId));

    	_transfer(oldOwner, newOwner, _tokenId);
  	}

  	// @param _owner The owner whose element tokens we are interested in.
  	// @dev This method MUST NEVER be called by smart contract code. First, it&#39;s fairly
  	//  expensive (it walks the entire Elements array looking for elements belonging to owner),
  	//  but it also returns a dynamic array, which is only supported for web3 calls, and
  	//  not contract-to-contract calls.
  	function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
    	uint256 tokenCount = balanceOf(_owner);
    	if (tokenCount == 0) {
        	// Return an empty array
      		return new uint256[](0);
    	} else {
      		uint256[] memory result = new uint256[](tokenCount);
      		uint256 totalElements = totalSupply();
      		uint256 resultIndex = 0;
      		uint256 elementId;
      		for (elementId = 0; elementId < totalElements; elementId++) {
      			uint256 tokenId = tokens[elementId];

		        if (elementIndexToOwner[tokenId] == _owner) {
		          result[resultIndex] = tokenId;
		          resultIndex++;
		        }
      		}
      		return result;
    	}
  	}

  	// For querying totalSupply of token
  	// @dev Required for ERC-721 compliance.
  	function totalSupply() public view returns (uint256 total) {
    	return tokens.length;
  	}

  	// Owner initates the transfer of the token to another account
  	// @param _to The address for the token to be transferred to.
  	// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
  	// @dev Required for ERC-721 compliance.
  	function transfer( address _to, uint256 _tokenId ) public {
   		require(_owns(msg.sender, _tokenId));
    	require(_addressNotNull(_to));
    	_transfer(msg.sender, _to, _tokenId);
  	}

  	// Third-party initiates transfer of token from address _from to address _to
  	// @param _from The address for the token to be transferred from.
  	// @param _to The address for the token to be transferred to.
  	// @param _tokenId The ID of the Token that can be transferred if this call succeeds.
  	// @dev Required for ERC-721 compliance.
  	function transferFrom( address _from, address _to, uint256 _tokenId) public {
    	require(_owns(_from, _tokenId));
    	require(_approved(_to, _tokenId));
    	require(_addressNotNull(_to));
    	_transfer(_from, _to, _tokenId);
  	}

  	/*** PRIVATE FUNCTIONS ***/
  	// Safety check on _to address to prevent against an unexpected 0x0 default.
  	function _addressNotNull(address _to) private pure returns (bool) {
    	return _to != address(0);
  	}

  	// For checking approval of transfer for address _to
	function _approved(address _to, uint256 _tokenId) private view returns (bool) {
		return elementIndexToApproved[_tokenId] == _to;
	}

  	// Private method for creating Element
  	function _createElement(uint256 _id, string _name, address _owner, uint256 _price, uint256 _scientistId) private returns (string) {

    	uint256 newElementId = _id;
    	// It&#39;s probably never going to happen, 4 billion tokens are A LOT, but
    	// let&#39;s just be 100% sure we never let this happen.
    	require(newElementId == uint256(uint32(newElementId)));

    	elements[_id] = Element(_id, _name, _scientistId);

    	Birth(newElementId, _name, _owner);

    	elementIndexToPrice[newElementId] = _price;

    	// This will assign ownership, and also emit the Transfer event as
    	// per ERC721 draft
    	_transfer(address(0), _owner, newElementId);

    	tokens.push(_id);

    	return _name;
  	}


  	// @dev Creates Periodic Table as first element
  	function createContractPeriodicTable(string _name) public onlyCEO {
  		require(periodicTableExists == false);

  		_createElement(0, _name, address(this), periodicStartingPrice, scientistSTART);
  		periodicTableExists = true;
  	}

  	// @dev Creates a new Element with the given name and Id
  	function createContractElement(string _name, uint256 _scientistId) public onlyCEO {
  		require(periodicTableExists == true);

    	uint256 _id = SafeMath.add(elementCTR, elementSTART);
    	uint256 _scientistIdProcessed = SafeMath.add(_scientistId, scientistSTART);

    	_createElement(_id, _name, address(this), elementStartingPrice, _scientistIdProcessed);
    	elementCTR = SafeMath.add(elementCTR, 1);
  	}

  	// @dev Creates a new Scientist with the given name Id
  	function createContractScientist(string _name) public onlyCEO {
  		require(periodicTableExists == true);

  		// to start from 1001
  		scientistCTR = SafeMath.add(scientistCTR, 1);
    	uint256 _id = SafeMath.add(scientistCTR, scientistSTART);
    	
    	_createElement(_id, _name, address(this), scientistStartingPrice, scientistSTART);	
  	}

  	// @dev Creates a new Special Card with the given name Id
  	function createContractSpecial(string _name) public onlyCEO {
  		require(periodicTableExists == true);
  		require(specialCTR <= specialLIMIT);

  		// to start from 10001
  		specialCTR = SafeMath.add(specialCTR, 1);
    	uint256 _id = SafeMath.add(specialCTR, specialSTART);

    	_createElement(_id, _name, address(this), specialStartingPrice, scientistSTART);
    	
  	}

  	// Check for token ownership
  	function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    	return claimant == elementIndexToOwner[_tokenId];
  	}


  	//**** HELPERS for checking elements, scientists and special cards
  	function checkPeriodic() public view returns (bool) {
  		return periodicTableExists;
  	}

  	function getTotalElements() public view returns (uint256) {
  		return elementCTR;
  	}

  	function getTotalScientists() public view returns (uint256) {
  		return scientistCTR;
  	}

  	function getTotalSpecials() public view returns (uint256) {
  		return specialCTR;
  	}

  	//**** HELPERS for changing prices limits and steps if it would be bad, community would like different
  	function changeStartingPricesLimits(uint256 _elementStartPrice, uint256 _scientistStartPrice, uint256 _specialStartPrice) public onlyCEO {
  		elementStartingPrice = _elementStartPrice;
  		scientistStartingPrice = _scientistStartPrice;
  		specialStartingPrice = _specialStartPrice;
	}

	function changeStepPricesLimits(uint256 _first, uint256 _second, uint256 _third) public onlyCEO {
		firstStepLimit = _first;
		secondStepLimit = _second;
		thirdStepLimit = _third;
	}

	// in case of error when assigning scientist to given element
	function changeScientistForElement(uint256 _tokenId, uint256 _scientistId) public onlyCEO {
    	Element storage element = elements[_tokenId];
    	element.scientistId = SafeMath.add(_scientistId, scientistSTART);
  	}

  	function changeElementName(uint256 _tokenId, string _name) public onlyCEO {
    	Element storage element = elements[_tokenId];
    	element.name = _name;
  	}

  	// This function can be used by the owner of a token to modify the current price
	function modifyTokenPrice(uint256 _tokenId, uint256 _newPrice) public payable {
	    require(_newPrice > elementStartingPrice);
	    require(elementIndexToOwner[_tokenId] == msg.sender);
	    require(_newPrice < elementIndexToPrice[_tokenId]);

	    if ( _tokenId == 0) {
	    	require(_newPrice > periodicStartingPrice);
	    } else if ( _tokenId < 1000) {
	    	require(_newPrice > elementStartingPrice);
	    } else if ( _tokenId < 10000 ) {
	    	require(_newPrice > scientistStartingPrice);
	    } else {
	    	require(_newPrice > specialStartingPrice);
	    }

	    elementIndexToPrice[_tokenId] = _newPrice;
	}

  	// For paying out balance on contract
  	function _payout(address _to) private {
    	if (_to == address(0)) {
      		ceoAddress.transfer(this.balance);
    	} else {
      		_to.transfer(this.balance);
    	}
  	}

  	// @dev Assigns ownership of a specific Element to an address.
  	function _transfer(address _from, address _to, uint256 _tokenId) private {
  	  	// Since the number of elements is capped to 2^32 we can&#39;t overflow this
  	  	ownershipTokenCount[_to]++;
  	  	//transfer ownership
  	  	elementIndexToOwner[_tokenId] = _to;
  	  	// When creating new elements _from is 0x0, but we can&#39;t account that address.
  	  	if (_from != address(0)) {
  	    	ownershipTokenCount[_from]--;
  	    	// clear any previously approved ownership exchange
  	    	delete elementIndexToApproved[_tokenId];
  	  	}
  	  	// Emit the transfer event.
  	  	Transfer(_from, _to, _tokenId);
  	}
}

library SafeMath {

  	/**
  	* @dev Multiplies two numbers, throws on overflow.
  	*/
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
		  return 0;
		}
		uint256 c = a * b;
		assert(c / a == b);
		return c;
	}

  	/**
  	* @dev Integer division of two numbers, truncating the quotient.
  	*/
  	function div(uint256 a, uint256 b) internal pure returns (uint256) {
    	// assert(b > 0); // Solidity automatically throws when dividing by 0
    	uint256 c = a / b;
    	// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    	return c;
  	}

  	/**
  	* @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  	*/
  	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    	assert(b <= a);
    	return a - b;
  	}

  	/**
  	* @dev Adds two numbers, throws on overflow.
  	*/
  	function add(uint256 a, uint256 b) internal pure returns (uint256) {
    	uint256 c = a + b;
    	assert(c >= a);
    	return c;
  	}
}