pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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

/**
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 * Note: the ERC-165 identifier for this interface is 0x5b5e139f.
 */
contract ERC721Metadata /* is ERC721 */ {
    string public tokenURIPrefix = &#39;https://backend.tribe.wtf/meta/product/&#39;;

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string){}

    //
    function changeTokenURIPrefix(string _prefix) public {
    	tokenURIPrefix = _prefix;
    }
}

/**
 * define new products, which can be bought
 * Products will be minted on demand
 */
//contract TribeProducts is ERC721Token {
contract TribeProducts is ERC721Metadata {

	// PRODUCT DEFINITIONS
	struct Product {
		address owner;
		string name;
		bool mintable;
		uint256 price;
		address tribe;
		uint256[] tokens;
	}

	mapping(string => Product) internal products;

	// Map tribes and tokens to products
	// Products themselves have tribe and tokens information. So both ways to query are possible.
	// See "tribeTokens" and "tokenTribe"
	mapping(address => string[]) internal tribeProducts; // address => [name]
	mapping(uint256 => string) public tokenProduct; // ID => name
	
	function TribeProducts() public {
		
	}

	// TODO: INHERITANCE!!!!!! SHOULD BE IN ERC721Metadata CLASS
	function tokenURI(uint256 _tokenId) external view returns (string){
		string name = tokenProduct[_tokenId];
		return string(abi.encodePacked(tokenURIPrefix, name));
	}

	function createProduct(string _name, bool _mintable, uint256 _price, address _tribe) public returns(bool){
		require(_tribe != address(0x0));
		require(products[_name].tribe == address(0x0));

		// create new product
		products[_name] = Product({
			owner: msg.sender,
			name: _name,
			mintable: _mintable,
			price: _price,
			tribe: _tribe,
			tokens: new uint256[](0)
		});
		tribeProducts[_tribe].push(_name);
		return true;
	}

	function buyProduct(string _name) payable public returns(bool){//returns(bool){
		Product storage p = products[_name];
		require(p.owner != address(0x0)); // product must exist
		require(p.price <= msg.value); // cost of product must be met

		//
		// TODO add product metadata? Do we really need metadata on chain? Cryptokitties do not save any additional data too...

		// buy as many products as value can buy
		uint256 v = msg.value;
		while(v >= p.price){
			uint256 newTokenId = totalSupply() + 1;
			// generate new product token
			// TODO: mintable or not? the mintable option does nothing at this point
			_mint(msg.sender, newTokenId);
			//
			// CONNECT TOKEN TO PRODUCT
			// TODO: move this code to the original minting function??
			tokenProduct[newTokenId] = _name;
			products[_name].tokens.push(newTokenId);
			//
			v -= p.price;
		}

		// send ether to tribe
		bool transaction = p.tribe.call.value(msg.value)();
		require(transaction);

		return true;
	}

	/*function getProduct(string _name) public returns(address, bool, address, uint){
		Product storage p = products[_name];
		return (p.owner, p.mintable, p.tribe, p.price);
	}*/

	function productOwner(string _name) public view returns(address){
		return products[_name].owner;
	}

	function productPrice(string _name) public view returns(uint256){
		return products[_name].price;
	}

	/**
	 * tribe -> tokens
	 */

	/*
	SHADOW DECLARATION
	function tribeProducts(address _tribe) public view returns(string[]){
		return tribeProducts[_tribe];
	}*/

	function productTokens(string _name) public view returns(uint256[]){
		return products[_name].tokens;
	}

	function tribeTokens(address _tribe) public view returns(uint256[]){
		uint256[] storage allTokens;
		//string[] products = tribeProducts(_tribe);
		string[] storage productNames = tribeProducts[_tribe];
		for(uint i=0; i<productNames.length; i++){
			uint256[] memory tokens = productTokens(productNames[i]);
			for(uint j=0; j<tokens.length; j++){
				allTokens.push(tokens[j]);
			}
		}
		return allTokens;
	}

	/**
	 * token -> tribe
	 */

	/*
	SHADOW DECLARATION
	function tokenProduct(uint _tokenId) public view returns(string){
		return tokenProduct[_tokenId];
	}
	*/

	function productTribe(string _name) public view returns(address){
		return products[_name].tribe;
	}

	function tokenTribe(uint _tokenId) public view returns(address){
		//string product = tokenProduct(_tokenId);
		string storage product = tokenProduct[_tokenId];
		address tribe = productTribe(product);
		return tribe;
	}

	//=========================================================================================================
	//=========================================================================================================
	//=========================================================================================================

	mapping(uint => bool) private redeemedToken;

	function redeem(uint _tokenId) public {
		require(tokenOwner[_tokenId] == msg.sender);
		redeemedToken[_tokenId] = true;
	}

	function redeemed(uint _tokenId) public view returns(bool){
		return redeemedToken[_tokenId];
	}

	function unRedeem(uint _tokenId) public {
		require(redeemed(_tokenId));
		Product storage p = products[tokenProduct[_tokenId]];
		require(p.owner == msg.sender);
		redeemedToken[_tokenId] = false;
	}

	//=========================================================================================================
	//=========================================================================================================
	//=========================================================================================================
	// (simple ERC721 contract)

	event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
	event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

	using SafeMath for uint256;

	// Total amount of tokens
	uint256 private totalTokens;

	// Mapping from token ID to owner
	mapping (uint256 => address) private tokenOwner;

	// Mapping from token ID to approved address
	mapping (uint256 => address) private tokenApprovals;

	// Mapping from owner to list of owned token IDs
	mapping (address => uint256[]) private ownedTokens;

	// Mapping from token ID to index of the owner tokens list
	mapping(uint256 => uint256) private ownedTokensIndex;

	/**
	* @dev Guarantees msg.sender is owner of the given token
	* @param _tokenId uint256 ID of the token to validate its ownership belongs to msg.sender
	*/
	modifier onlyOwnerOf(uint256 _tokenId) {
		require(ownerOf(_tokenId) == msg.sender);
		_;
	}

	/**
	* @dev Gets the total amount of tokens stored by the contract
	* @return uint256 representing the total amount of tokens
	*/
	function totalSupply() public view returns (uint256) {
		return totalTokens;
	}

	/**
	* @dev Gets the balance of the specified address
	* @param _owner address to query the balance of
	* @return uint256 representing the amount owned by the passed address
	*/
	function balanceOf(address _owner) public view returns (uint256) {
		return ownedTokens[_owner].length;
	}

	/**
	* @dev Gets the list of tokens owned by a given address
	* @param _owner address to query the tokens of
	* @return uint256[] representing the list of tokens owned by the passed address
	*/
	function tokensOf(address _owner) public view returns (uint256[]) {
		return ownedTokens[_owner];
	}

	/**
	* @dev Gets the owner of the specified token ID
	* @param _tokenId uint256 ID of the token to query the owner of
	* @return owner address currently marked as the owner of the given token ID
	*/
	function ownerOf(uint256 _tokenId) public view returns (address) {
		address owner = tokenOwner[_tokenId];
		require(owner != address(0));
		return owner;
	}

	/**
	 * @dev Gets the approved address to take ownership of a given token ID
	 * @param _tokenId uint256 ID of the token to query the approval of
	 * @return address currently approved to take ownership of the given token ID
	 */
	function approvedFor(uint256 _tokenId) public view returns (address) {
		return tokenApprovals[_tokenId];
	}

	/**
	* @dev Transfers the ownership of a given token ID to another address
	* @param _to address to receive the ownership of the given token ID
	* @param _tokenId uint256 ID of the token to be transferred
	*/
	function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
		clearApprovalAndTransfer(msg.sender, _to, _tokenId);
	}

	/**
	* @dev Approves another address to claim for the ownership of the given token ID
	* @param _to address to be approved for the given token ID
	* @param _tokenId uint256 ID of the token to be approved
	*/
	function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
		address owner = ownerOf(_tokenId);
		require(_to != owner);
		if (approvedFor(_tokenId) != 0 || _to != 0) {
		tokenApprovals[_tokenId] = _to;
		Approval(owner, _to, _tokenId);
		}
	}

	/**
	* @dev Claims the ownership of a given token ID
	* @param _tokenId uint256 ID of the token being claimed by the msg.sender
	*/
	function takeOwnership(uint256 _tokenId) public {
		require(isApprovedFor(msg.sender, _tokenId));
		clearApprovalAndTransfer(ownerOf(_tokenId), msg.sender, _tokenId);
	}

	/**
	* @dev Mint token function
	* @param _to The address that will own the minted token
	* @param _tokenId uint256 ID of the token to be minted by the msg.sender
	*/
	function _mint(address _to, uint256 _tokenId) internal {
		require(_to != address(0));
		addToken(_to, _tokenId);
		Transfer(0x0, _to, _tokenId);
	}

	/**
	* @dev Burns a specific token
	* @param _tokenId uint256 ID of the token being burned by the msg.sender
	*/
	function _burn(uint256 _tokenId) onlyOwnerOf(_tokenId) internal {
		if (approvedFor(_tokenId) != 0) {
		clearApproval(msg.sender, _tokenId);
		}
		removeToken(msg.sender, _tokenId);
		Transfer(msg.sender, 0x0, _tokenId);
	}

	/**
	 * @dev Tells whether the msg.sender is approved for the given token ID or not
	 * This function is not private so it can be extended in further implementations like the operatable ERC721
	 * @param _owner address of the owner to query the approval of
	 * @param _tokenId uint256 ID of the token to query the approval of
	 * @return bool whether the msg.sender is approved for the given token ID or not
	 */
	function isApprovedFor(address _owner, uint256 _tokenId) internal view returns (bool) {
		return approvedFor(_tokenId) == _owner;
	}

	/**
	* @dev Internal function to clear current approval and transfer the ownership of a given token ID
	* @param _from address which you want to send tokens from
	* @param _to address which you want to transfer the token to
	* @param _tokenId uint256 ID of the token to be transferred
	*/
	function clearApprovalAndTransfer(address _from, address _to, uint256 _tokenId) internal {
		require(_to != address(0));
		require(_to != ownerOf(_tokenId));
		require(ownerOf(_tokenId) == _from);

		clearApproval(_from, _tokenId);
		removeToken(_from, _tokenId);
		addToken(_to, _tokenId);
		Transfer(_from, _to, _tokenId);
	}

	/**
	* @dev Internal function to clear current approval of a given token ID
	* @param _tokenId uint256 ID of the token to be transferred
	*/
	function clearApproval(address _owner, uint256 _tokenId) private {
		require(ownerOf(_tokenId) == _owner);
		tokenApprovals[_tokenId] = 0;
		Approval(_owner, 0, _tokenId);
	}

	/**
	* @dev Internal function to add a token ID to the list of a given address
	* @param _to address representing the new owner of the given token ID
	* @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
	*/
	function addToken(address _to, uint256 _tokenId) private {
		// ADDED FOR TRIBE PRODUCTS ###############################
		require(!redeemed(_tokenId));
		// ADDED FOR TRIBE PRODUCTS ###############################

		require(tokenOwner[_tokenId] == address(0));
		tokenOwner[_tokenId] = _to;
		uint256 length = balanceOf(_to);
		ownedTokens[_to].push(_tokenId);
		ownedTokensIndex[_tokenId] = length;
		totalTokens = totalTokens.add(1);
	}

	/**
	* @dev Internal function to remove a token ID from the list of a given address
	* @param _from address representing the previous owner of the given token ID
	* @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
	*/
	function removeToken(address _from, uint256 _tokenId) private {
		// ADDED FOR TRIBE PRODUCTS ###############################
		require(!redeemed(_tokenId));
		// ADDED FOR TRIBE PRODUCTS ###############################

		require(ownerOf(_tokenId) == _from);

		uint256 tokenIndex = ownedTokensIndex[_tokenId];
		uint256 lastTokenIndex = balanceOf(_from).sub(1);
		uint256 lastToken = ownedTokens[_from][lastTokenIndex];

		tokenOwner[_tokenId] = 0;
		ownedTokens[_from][tokenIndex] = lastToken;
		ownedTokens[_from][lastTokenIndex] = 0;
		// Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are going to
		// be zero. Then we can make sure that we will remove _tokenId from the ownedTokens list since we are first swapping
		// the lastToken to the first position, and then dropping the element placed in the last position of the list

		ownedTokens[_from].length--;
		ownedTokensIndex[_tokenId] = 0;
		ownedTokensIndex[lastToken] = tokenIndex;
		totalTokens = totalTokens.sub(1);
	}
}