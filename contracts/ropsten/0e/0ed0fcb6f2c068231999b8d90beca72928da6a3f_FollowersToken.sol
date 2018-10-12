pragma solidity ^0.4.18; // solhint-disable-line



/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author Dieter Shirley <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="452120312005243d2c2a283f202b6b262a">[email&#160;protected]</a>> (https://github.com/dete)
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

  // Optional
  // function name() public view returns (string name);
  // function symbol() public view returns (string symbol);
  // function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 tokenId);
  // function tokenMetadata(uint256 _tokenId) public view returns (string infoUrl);
}




/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

contract FollowersToken is ERC721 {

	string public constant NAME 		= "FollowersToken";
	string public constant SYMBOL 		= "FWTK";

	uint256 private startingPrice	= 0.05 ether;
	uint256 private firstStepLimit 	= 6.4 ether;
	uint256 private secondStepLimit = 120.9324 ether;
	uint256 private thirdStepLimit 	= 792.5423 ether;

	bool 	private isPresale;

	mapping (uint256 => address) public personIndexToOwner;
	mapping (address => uint256) private ownershipTokenCount;
	mapping (uint256 => address) public personIndexToApproved;
	mapping (uint256 => uint256) private personIndexToPrice;
	mapping (uint256 => uint256) private personIndexToPriceLevel;

	address public ceoAddress;
	address public cooAddress;

	struct Person {
		string name;
	}

	Person[] private persons;

	modifier onlyCEO() {
		require(msg.sender == ceoAddress);
		_;
	}

	modifier onlyCOO() {
		require(msg.sender == cooAddress);
		_;
	}

	modifier onlyCLevel() {
		require( msg.sender == ceoAddress || msg.sender == cooAddress );
		_;
	}

	constructor() public {
		ceoAddress = msg.sender;
		cooAddress = msg.sender;
		isPresale  = true;
	}

	function startPresale() public onlyCLevel {
		isPresale = true;
	}

	function stopPresale() public onlyCLevel {
		isPresale = false;
	}

	function presale() public view returns ( bool presaleStatus ) {
		return isPresale;
	}

	function approve( address _to, uint256 _tokenId ) public {
		// Caller must own token.
		require( _owns( msg.sender , _tokenId ) );
		personIndexToApproved[_tokenId] = _to;
		emit Approval( msg.sender , _to , _tokenId );
	}

	function balanceOf(address _owner) public view returns (uint256 balance) {
		return ownershipTokenCount[_owner];
	}

	function createContractPerson( string _name , uint256 _price , address _owner ) public onlyCOO {
		if ( _price <= 0 ) {
			_price = startingPrice;
		}
		_createPerson( _name , _owner , _price );
	}

	function getPerson(uint256 _tokenId) public view returns ( string personName, uint256 sellingPrice, address owner , uint256 sellingPriceNext , uint256 priceLevel ) {
		Person storage person = persons[_tokenId];
		personName 			= person.name;
		sellingPrice 		= personIndexToPrice[_tokenId];
		owner 				= personIndexToOwner[_tokenId];
		priceLevel 			= personIndexToPriceLevel[ _tokenId ];
		sellingPriceNext 	= _calcNextPrice( _tokenId );
	}

	function _calcNextPrice( uint256 _tokenId ) private view returns ( uint256 nextSellingPrice ) {
		uint256 sellingPrice 	= priceOf( _tokenId );
		if( isPresale == true ){
			nextSellingPrice =  uint256( SafeMath.div( SafeMath.mul( sellingPrice, 400 ) , 100 ) );
		}else{
			if ( sellingPrice < firstStepLimit ) {
				nextSellingPrice =  uint256( SafeMath.div( SafeMath.mul( sellingPrice, 200 ) , 100 ) );
			} else if ( sellingPrice < secondStepLimit ) {
				nextSellingPrice =  uint256( SafeMath.div( SafeMath.mul( sellingPrice, 180 ) , 100 ) );
			} else if ( sellingPrice < thirdStepLimit ) {
				nextSellingPrice =  uint256( SafeMath.div( SafeMath.mul( sellingPrice, 160 ) , 100 ) );
			} else {
				nextSellingPrice  =  uint256( SafeMath.div( SafeMath.mul( sellingPrice, 140 ) , 100 ) );
			}
		}
		return nextSellingPrice;
	}

	function implementsERC721() public pure returns (bool) {
		return true;
	}

	function name() public pure returns (string) {
		return NAME;
	}

	function ownerOf( uint256 _tokenId ) public view returns ( address owner ){
		owner = personIndexToOwner[_tokenId];
		require( owner != address(0) );
	}

	function payout( address _to ) public onlyCLevel {
		_payout( _to );
	}

	function purchase(uint256 _tokenId) public payable {
		address oldOwner 		= personIndexToOwner[_tokenId];
		address newOwner 		= msg.sender;
		uint256 sellingPrice 	= personIndexToPrice[_tokenId];

		require( oldOwner != newOwner );
		require( _addressNotNull( newOwner ) );
		require( msg.value >= sellingPrice );

		uint256 payment 		= uint256( SafeMath.div( SafeMath.mul( sellingPrice , 94 ) , 100 ) );
		uint256 purchaseExcess 	= SafeMath.sub( msg.value , sellingPrice );

		if( isPresale == true ){
			require( personIndexToPriceLevel[ _tokenId ] == 0 );
		}
		personIndexToPrice[ _tokenId ] 		= _calcNextPrice( _tokenId );
		personIndexToPriceLevel[ _tokenId ] = SafeMath.add( personIndexToPriceLevel[ _tokenId ] , 1 );

		_transfer( oldOwner , newOwner , _tokenId );

		if ( oldOwner != address(this) ) {
			oldOwner.transfer( payment );
		}

		msg.sender.transfer( purchaseExcess );
	}

	function priceOf(uint256 _tokenId) public view returns (uint256 price) {
		return personIndexToPrice[_tokenId];
	}

	function setCEO(address _newCEO) public onlyCEO {
		require(_newCEO != address(0));
		ceoAddress = _newCEO;
	}

	function setCOO(address _newCOO) public onlyCEO {
		require(_newCOO != address(0));
		cooAddress = _newCOO;
	}

	function symbol() public pure returns (string) {
		return SYMBOL;
	}

	function takeOwnership(uint256 _tokenId) public {
		address newOwner = msg.sender;
		address oldOwner = personIndexToOwner[_tokenId];
		require(_addressNotNull(newOwner));
		require(_approved(newOwner, _tokenId));
		_transfer(oldOwner, newOwner, _tokenId);
	}

	function tokensOfOwner(address _owner) public view returns( uint256[] ownerTokens ) {
		uint256 tokenCount = balanceOf(_owner);
		if (tokenCount == 0) {
			return new uint256[](0);
		} else {
			uint256[] memory result = new uint256[](tokenCount);
			uint256 totalPersons = totalSupply();
			uint256 resultIndex = 0;
			uint256 personId;
			for (personId = 0; personId <= totalPersons; personId++) {
				if (personIndexToOwner[personId] == _owner) {
					result[resultIndex] = personId;
					resultIndex++;
				}
			}
			return result;
		}
	}

	function totalSupply() public view returns (uint256 total) {
		return persons.length;
	}

	function transfer( address _to, uint256 _tokenId ) public {
		require( _owns(msg.sender, _tokenId ) );
		require( _addressNotNull( _to ) );
		_transfer( msg.sender, _to, _tokenId );
	}

	function transferFrom( address _from, address _to, uint256 _tokenId ) public {
		require(_owns(_from, _tokenId));
		require(_approved(_to, _tokenId));
		require(_addressNotNull(_to));
		_transfer(_from, _to, _tokenId);
	}

	function _addressNotNull(address _to) private pure returns (bool) {
		return _to != address(0);
	}

	function _approved(address _to, uint256 _tokenId) private view returns (bool) {
		return personIndexToApproved[_tokenId] == _to;
	}

	function _createPerson( string _name, address _owner, uint256 _price ) private {
		Person memory _person = Person({
			name: _name
		});

		uint256 newPersonId = persons.push(_person) - 1;
		require(newPersonId == uint256(uint32(newPersonId)));
		personIndexToPrice[newPersonId] = _price;
		personIndexToPriceLevel[ newPersonId ] = 0;
		_transfer( address(0) , _owner, newPersonId);
	}

	function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
		return claimant == personIndexToOwner[_tokenId];
	}

	function _payout(address _to) private {
		if (_to == address(0)) {
			ceoAddress.transfer( address( this ).balance );
		} else {
			_to.transfer( address( this ).balance );
		}
	}

	function _transfer(address _from, address _to, uint256 _tokenId) private {
		ownershipTokenCount[_to] = SafeMath.add( ownershipTokenCount[_to] , 1 );
		personIndexToOwner[_tokenId] = _to;
		if (_from != address(0)) {
			ownershipTokenCount[_from] = SafeMath.sub( ownershipTokenCount[_from] , 1 );
			delete personIndexToApproved[_tokenId];
		}
		emit Transfer(_from, _to, _tokenId);
	}

}