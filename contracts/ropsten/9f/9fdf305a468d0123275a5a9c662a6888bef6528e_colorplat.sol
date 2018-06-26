pragma solidity ^0.4.18;

    /**
     * @title SafeMath
     *  Math operations with safety checks that throw on error
     * @notice source: https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
     *
     * @notice check https://github.com/dharmaprotocol/NonFungibleToken for a generic modular implementation
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

  	/**
	 * @title SimpleERC721
	 *
	 * A crude, simple single file implementation of ERC721 standard
	 *  See https://github.com/ethereum/eips/issues/721
	 *
	 * Incomplete, the standard itself is not finalized yet (Done before the issue 841, see: https://github.com/ethereum/EIPs/pull/841)
	*/

contract SimpleERC721 {
    using SafeMath for uint256; // SafeMath methods will be available for the type &quot;unit256&quot;

    // ------------- Variables 

    uint256 public totalSupply;
    address public deployer; //deployer&#39;s wallet
    
    // Basic references
    mapping(uint => address) internal tokenIdToOwner;
    mapping(address => uint[]) internal listOfOwnerTokens;
    mapping(uint => uint) internal tokenIndexInOwnerArray;
    // Approval mapping
    mapping(uint => address) internal approvedAddressToTransferTokenId;
    // Metadata infos
    mapping(uint => string) internal referencedMetadata;  //this stores token attributes

    // ------------- Events 

    event Minted(address indexed _to, uint256 indexed _tokenId);

    event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

    // ------------- Modifier

    modifier onlyNonexistentToken(uint _tokenId) {
        require(tokenIdToOwner[_tokenId] == address(0));
        _;
    }

    modifier onlyExtantToken(uint _tokenId) {
        require(ownerOf(_tokenId) != address(0));
        _;
    }

    // ------------- (View) Functions 
    
    //  Returns the address currently marked as the owner of _tokenID. 
    function ownerOf() public view returns (address _creator)
    {
        return deployer;
    }
    //  Returns the address currently marked as the owner of _tokenID. 
    function ownerOf(uint256 _tokenId) public view returns (address _owner)
    {
        return tokenIdToOwner[_tokenId];
    }

    //  Get the total supply of token held by this contract. 
    function totalSupply() public view returns (uint256 _totalSupply)
    {
        return totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint _balance)
    {
        return listOfOwnerTokens[_owner].length;
    }

    //  Returns a multiaddress string referencing an external resource bundle that contains
    function tokenMetadata(uint _tokenId) public view returns (string _data)
    {
        return referencedMetadata[_tokenId];
    }

    // ------------- -------------(Core) Functions-------------------------------

    //  Only deployer can create new tokens
    function mint(address _owner, uint256 _tokenId,string data) public onlyNonexistentToken (_tokenId);

    // Only deployer can modify token Metadata of a token
    function change_metadata(uint256 _tokenId,string _newdata) public returns(bool _status) {
    	if(msg.sender==deployer){
    		referencedMetadata[_tokenId]=_newdata;
    		return true;
    	}
    	else 
    		return false; 	
    }

	//  Assigns the ownership of the NFT with ID _tokenId to _to
    function transfer(address _to, uint _tokenId) public onlyExtantToken (_tokenId)
    {
        require(ownerOf(_tokenId) == msg.sender);
        require(_to != address(0)); 

        _clearApprovalAndTransfer(msg.sender, _to, _tokenId);

        emit Transfer(msg.sender, _to, _tokenId);
    }

    //  Grants approval for address _to to take possession of the NFT with ID _tokenId.
    function approve(address _to, uint _tokenId) public onlyExtantToken(_tokenId)
    {
        require(msg.sender == ownerOf(_tokenId));
        require(msg.sender != _to);

        if (approvedAddressToTransferTokenId[_tokenId] != address(0) || _to != address(0)) {
            approvedAddressToTransferTokenId[_tokenId] = _to;
            emit Approval(msg.sender, _to, _tokenId);
        }
    }

    //  transfer token From _from to _to
    // @notice address _from is unnecessary
    function transferFrom(address _from, address _to, uint _tokenId) public onlyExtantToken(_tokenId)
    {
        require(approvedAddressToTransferTokenId[_tokenId] == msg.sender);
        require(ownerOf(_tokenId) == _from);
        require(_to != address(0));

        _clearApprovalAndTransfer(_from, _to, _tokenId);

        emit Approval(_from, 0, _tokenId);
        emit Transfer(_from, _to, _tokenId);
    }

    // ---------------------------- Internal, helper functions

    function _setTokenOwner(uint _tokenId, address _owner) internal
    {
        tokenIdToOwner[_tokenId] = _owner;
    }

    function _addTokenToOwnersList(address _owner, uint _tokenId) internal
    {
        listOfOwnerTokens[_owner].push(_tokenId);
        tokenIndexInOwnerArray[_tokenId] = listOfOwnerTokens[_owner].length - 1;
    }

    function _clearApprovalAndTransfer(address _from, address _to, uint _tokenId) internal
    {
        _clearTokenApproval(_tokenId);
        _removeTokenFromOwnersList(_from, _tokenId);
        _setTokenOwner(_tokenId, _to);
        _addTokenToOwnersList(_to, _tokenId);
    }

    function _removeTokenFromOwnersList(address _owner, uint _tokenId) internal
    {
        uint length = listOfOwnerTokens[_owner].length; // length of owner tokens
        uint index = tokenIndexInOwnerArray[_tokenId]; // index of token in owner array
        uint swapToken = listOfOwnerTokens[_owner][length - 1]; // last token in array

        listOfOwnerTokens[_owner][index] = swapToken; // last token pushed to the place of the one that was transfered
        tokenIndexInOwnerArray[swapToken] = index; // update the index of the token we moved

        delete listOfOwnerTokens[_owner][length - 1]; // remove the case we emptied
        listOfOwnerTokens[_owner].length--; // shorten the array&#39;s length
    }

    function _clearTokenApproval(uint _tokenId) internal
    {
        approvedAddressToTransferTokenId[_tokenId] = address(0);
    }

}



//Customised ERC721 token implementation

contract colorplat is SimpleERC721{  //defines a colorplat collectible as an ERC721 token

	using SafeMath for uint256; // SafeMath methods will be available for the type &quot;unit256&quot;

	string public constant name = &quot;Colorplat&quot;;
  	string public constant symbol = &quot;CLRPLAT&quot;;

 

     function mint(address _owner, uint256 _tokenId,string data) public onlyNonexistentToken (_tokenId)
     {
     	 if(msg.sender==deployer){
     	 	_setTokenOwner(_tokenId, _owner);
		    _addTokenToOwnersList(_owner, _tokenId);

		    referencedMetadata[_tokenId]=data;

	        totalSupply = totalSupply.add(1);

		    emit Minted(_owner, _tokenId);    
     	 }
     }


	function colorplat() public {  //the constructor
		totalSupply=0; //set initial supply
		deployer=msg.sender;
		mint(deployer,0,&quot;000000,2.5&quot;); //create first colorplat with index 0
	}

}