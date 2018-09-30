/**
 * Created on 2018-06-05 16:37
 * @summary: Our NFT Minting Contract which inherits ERC721 capability from LSNFT
 * @author: Fazri Zubair & Farhan Khwaja
 */
pragma solidity ^0.4.23;

pragma solidity ^0.4.23;

/* NFT Metadata Schema 
{
    "title": "Asset Metadata",
    "type": "object",
    "properties": {
        "name": {
            "type": "string",
            "description": "Identifies the asset to which this NFT represents",
        },
        "description": {
            "type": "string",
            "description": "Describes the asset to which this NFT represents",
        },
        "image": {
            "type": "string",
            "description": "A URI pointing to a resource with mime type image/* representing the asset to which this NFT represents. Consider making any images at a width between 320 and 1080 pixels and aspect ratio between 1.91:1 and 4:5 inclusive.",
        }
    }
}
*/

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

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
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solium-disable-next-line security/no-inline-assembly
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic {
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    function balanceOf(address _owner) public view returns (uint256 _balance);
    function ownerOf(uint256 _tokenId) public view returns (address _owner);
    function exists(uint256 _tokenId) public view returns (bool _exists);

    function approve(address _to, uint256 _tokenId) public;
    function getApproved(uint256 _tokenId)
        public view returns (address _operator);

    function setApprovalForAll(address _operator, bool _approved) public;
    function isApprovedForAll(address _owner, address _operator)
        public view returns (bool);

    function transferFrom(address _from, address _to, uint256 _tokenId) public;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    )
        public;
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Enumerable is ERC721Basic {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(
        address _owner,
        uint256 _index
    )
        public
        view
        returns (uint256 _tokenId);

    function tokenByIndex(uint256 _index) public view returns (uint256);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Metadata is ERC721Basic {
    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
    function tokenURI(uint256 _tokenId) public view returns (string);
}

/**
 * @title ERC-721 Non-Fungible Token Standard, full implementation interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721BasicToken is ERC721Basic {
    using SafeMath for uint256;
    using AddressUtils for address;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
    bytes4 public constant ERC721_RECEIVED = 0x150b7a02;

    // Mapping from token ID to owner
    mapping (uint256 => address) internal tokenOwner;

    // Mapping from token ID to approved address
    mapping (uint256 => address) internal tokenApprovals;

    // Mapping from owner to number of owned token
    mapping (address => uint256) internal ownedTokensCount;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) internal operatorApprovals;

    /**
    * @dev Guarantees msg.sender is owner of the given token
    * @param _tokenId uint256 ID of the token to validate its ownership belongs to msg.sender
    */
    modifier onlyOwnerOf(uint256 _tokenId) {
        require (ownerOf(_tokenId) == msg.sender);
        _;
    }

    /**
    * @dev Checks msg.sender can transfer a token, by being owner, approved, or operator
    * @param _tokenId uint256 ID of the token to validate
    */
    modifier canTransfer(uint256 _tokenId) {
        require (isApprovedOrOwner(msg.sender, _tokenId));
        _;
    }

    /**
    * @dev Gets the balance of the specified address
    * @param _owner address to query the balance of
    * @return uint256 representing the amount owned by the passed address
    */
    function balanceOf(address _owner) public view returns (uint256) {
        require (_owner != address(0));
        return ownedTokensCount[_owner];
    }

    /**
    * @dev Gets the owner of the specified token ID
    * @param _tokenId uint256 ID of the token to query the owner of
    * @return owner address currently marked as the owner of the given token ID
    */
    function ownerOf(uint256 _tokenId) public view returns (address) {
        address owner = tokenOwner[_tokenId];
        require (owner != address(0));
        return owner;
    }

    /**
    * @dev Returns whether the specified token exists
    * @param _tokenId uint256 ID of the token to query the existence of
    * @return whether the token exists
    */
    function exists(uint256 _tokenId) public view returns (bool) {
        address owner = tokenOwner[_tokenId];
        return owner != address(0);
    }

    /**
    * @dev Approves another address to transfer the given token ID
    * @dev The zero address indicates there is no approved address.
    * @dev There can only be one approved address per token at a given time.
    * @dev Can only be called by the token owner or an approved operator.
    * @param _to address to be approved for the given token ID
    * @param _tokenId uint256 ID of the token to be approved
    */
    function approve(address _to, uint256 _tokenId) public {
        address owner = ownerOf(_tokenId);
        require (_to != owner);
        require (msg.sender == owner || isApprovedForAll(owner, msg.sender));

        tokenApprovals[_tokenId] = _to;
        emit Approval(owner, _to, _tokenId);
    }

    /**
    * @dev Gets the approved address for a token ID, or zero if no address set
    * @param _tokenId uint256 ID of the token to query the approval of
    * @return address currently approved for the given token ID
    */
    function getApproved(uint256 _tokenId) public view returns (address) {
        return tokenApprovals[_tokenId];
    }

    /**
    * @dev Sets or unsets the approval of a given operator
    * @dev An operator is allowed to transfer all tokens of the sender on their behalf
    * @param _to operator address to set the approval
    * @param _approved representing the status of the approval to be set
    */
    function setApprovalForAll(address _to, bool _approved) public {
        require (_to != msg.sender);
        operatorApprovals[msg.sender][_to] = _approved;
        emit ApprovalForAll(msg.sender, _to, _approved);
    }

    /**
    * @dev Tells whether an operator is approved by a given owner
    * @param _owner owner address which you want to query the approval of
    * @param _operator operator address which you want to query the approval of
    * @return bool whether the given operator is approved by the given owner
    */
    function isApprovedForAll(
        address _owner,
        address _operator
    )
        public
        view
        returns (bool)
    {
        return operatorApprovals[_owner][_operator];
    }

    /**
    * @dev Transfers the ownership of a given token ID to another address
    * @dev Usage of this method is discouraged, use `safeTransferFrom` whenever possible
    * @dev Requires the msg sender to be the owner, approved, or operator
    * @param _from current owner of the token
    * @param _to address to receive the ownership of the given token ID
    * @param _tokenId uint256 ID of the token to be transferred
    */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public
        canTransfer(_tokenId)
    {
        require (_from != address(0));
        require (_to != address(0));

        clearApproval(_from, _tokenId);
        removeTokenFrom(_from, _tokenId);
        addTokenTo(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
    }

    /**
    * @dev Safely transfers the ownership of a given token ID to another address
    * @dev If the target address is a contract, it must implement `onERC721Received`,
    *  which is called upon a safe transfer, and return the magic value
    *  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
    *  the transfer is reverted.
    * @dev Requires the msg sender to be the owner, approved, or operator
    * @param _from current owner of the token
    * @param _to address to receive the ownership of the given token ID
    * @param _tokenId uint256 ID of the token to be transferred
    */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public
        canTransfer(_tokenId)
    {
        // solium-disable-next-line arg-overflow
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    /**
    * @dev Safely transfers the ownership of a given token ID to another address
    * @dev If the target address is a contract, it must implement `onERC721Received`,
    *  which is called upon a safe transfer, and return the magic value
    *  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
    *  the transfer is reverted.
    * @dev Requires the msg sender to be the owner, approved, or operator
    * @param _from current owner of the token
    * @param _to address to receive the ownership of the given token ID
    * @param _tokenId uint256 ID of the token to be transferred
    * @param _data bytes data to send along with a safe transfer check
    */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    )
        public
        canTransfer(_tokenId)
    {
        transferFrom(_from, _to, _tokenId);
        // solium-disable-next-line arg-overflow
        require (checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
    }

    /**
    * @dev Returns whether the given spender can transfer a given token ID
    * @param _spender address of the spender to query
    * @param _tokenId uint256 ID of the token to be transferred
    * @return bool whether the msg.sender is approved for the given token ID,
    *  is an operator of the owner, or is the owner of the token
    */
    function isApprovedOrOwner(
        address _spender,
        uint256 _tokenId
    )
        internal
        view
        returns (bool)
    {
        address owner = ownerOf(_tokenId);
        // Disable solium check because of
        // https://github.com/duaraghav8/Solium/issues/175
        // solium-disable-next-line operator-whitespace
        return (
        _spender == owner ||
        getApproved(_tokenId) == _spender ||
        isApprovedForAll(owner, _spender)
        );
    }

    /**
    * @dev Internal function to mint a new token
    * @dev Reverts if the given token ID already exists
    * @param _to The address that will own the minted token
    * @param _tokenId uint256 ID of the token to be minted by the msg.sender
    */
    function _mint(address _to, uint256 _tokenId) internal {
        require (_to != address(0));
        addTokenTo(_to, _tokenId);
        emit Transfer(address(0), _to, _tokenId);
    }

    /**
    * @dev Internal function to burn a specific token
    * @dev Reverts if the token does not exist
    * @param _tokenId uint256 ID of the token being burned by the msg.sender
    */
    function _burn(address _owner, uint256 _tokenId) internal {
        clearApproval(_owner, _tokenId);
        removeTokenFrom(_owner, _tokenId);
        emit Transfer(_owner, address(0), _tokenId);
    }

    /**
    * @dev Internal function to clear current approval of a given token ID
    * @dev Reverts if the given address is not indeed the owner of the token
    * @param _owner owner of the token
    * @param _tokenId uint256 ID of the token to be transferred
    */
    function clearApproval(address _owner, uint256 _tokenId) internal {
        require (ownerOf(_tokenId) == _owner);
        if (tokenApprovals[_tokenId] != address(0)) {
            tokenApprovals[_tokenId] = address(0);
        }
    }

    /**
    * @dev Internal function to add a token ID to the list of a given address
    * @param _to address representing the new owner of the given token ID
    * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
    */
    function addTokenTo(address _to, uint256 _tokenId) internal {
        require (tokenOwner[_tokenId] == address(0));
        tokenOwner[_tokenId] = _to;
        ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
    }

    /**
    * @dev Internal function to remove a token ID from the list of a given address
    * @param _from address representing the previous owner of the given token ID
    * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
    */
    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        require (ownerOf(_tokenId) == _from);
        ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
        tokenOwner[_tokenId] = address(0);
    }

    /**
    * @dev Internal function to invoke `onERC721Received` on a target address
    * @dev The call is not executed if the target address is not a contract
    * @param _from address representing the previous owner of the given token ID
    * @param _to target address that will receive the tokens
    * @param _tokenId uint256 ID of the token to be transferred
    * @param _data bytes optional data to send along with the call
    * @return whether the call correctly returned the expected magic value
    */
    function checkAndCallSafeTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    )
        internal
        returns (bool)
    {
        if (!_to.isContract()) {
            return true;
        }
        bytes4 retval = ERC721Receiver(_to).onERC721Received(
            msg.sender, _from, _tokenId, _data);
        return (retval == ERC721_RECEIVED);
    }
}

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 *  from ERC721 asset contracts.
 */
contract ERC721Receiver {
    /**
    * @dev Magic value to be returned upon successful reception of an NFT
    *  Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`,
    *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
    */
    bytes4 public constant ERC721_RECEIVED = 0x150b7a02;

    /**
    * @notice Handle the receipt of an NFT
    * @dev The ERC721 smart contract calls this function on the recipient
    *  after a `safetransfer`. This function MAY throw to revert and reject the
    *  transfer. This function MUST use 50,000 gas or less. Return of other
    *  than the magic value MUST result in the transaction being reverted.
    *  Note: the contract address is always the message sender.
    * @param _from The sending address
    * @param _tokenId The NFT identifier which is being transfered
    * @param _data Additional data with no specified format
    * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    */
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes _data
    )
        public
        returns(bytes4);
}

contract ERC721Holder is ERC721Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes
    ) 
        public
        returns(bytes4)
        {
            return ERC721_RECEIVED;
        }
}

/**
 * @title Full ERC721 Token
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Token is ERC721, ERC721BasicToken {

    // Token name
    string internal name_;

    // Token symbol
    string internal symbol_;

    // Mapping from owner to list of owned token IDs
    mapping(address => uint256[]) internal ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) internal ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] internal allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) internal allTokensIndex;

    // Base Server Address for Token MetaData URI
    string internal tokenURIBase;

    /**
    * @dev Returns an URI for a given token ID
    * @dev Throws if the token ID does not exist. May return an empty string.
    * @notice The user/developper needs to add the tokenID, in the end of URL, to 
    * use the URI and get all details. Ex. www.<apiURL>.com/token/<tokenID>
    * @param _tokenId uint256 ID of the token to query
    */
    function tokenURI(uint256 _tokenId) public view returns (string) {
        require (exists(_tokenId));
        return tokenURIBase;
    }

    /**
    * @dev Gets the token ID at a given index of the tokens list of the requested owner
    * @param _owner address owning the tokens list to be accessed
    * @param _index uint256 representing the index to be accessed of the requested tokens list
    * @return uint256 token ID at the given index of the tokens list owned by the requested address
    */
    function tokenOfOwnerByIndex(
        address _owner,
        uint256 _index
    )
        public
        view
        returns (uint256)
    {
        require (_index < balanceOf(_owner));
        return ownedTokens[_owner][_index];
    }

    /**
    * @dev Gets the total amount of tokens stored by the contract
    * @return uint256 representing the total amount of tokens
    */
    function totalSupply() public view returns (uint256) {
        return allTokens.length;
    }

    /**
    * @dev Gets the token ID at a given index of all the tokens in this contract
    * @dev Reverts if the index is greater or equal to the total number of tokens
    * @param _index uint256 representing the index to be accessed of the tokens list
    * @return uint256 token ID at the given index of the tokens list
    */
    function tokenByIndex(uint256 _index) public view returns (uint256) {
        require (_index < totalSupply());
        return allTokens[_index];
    }


    /**
    * @dev Internal function to set the token URI for a given token
    * @dev Reverts if the token ID does not exist
    * @param _uri string URI to assign
    */
    function _setTokenURIBase(string _uri) internal {
        tokenURIBase = _uri;
    }

    /**
    * @dev Internal function to add a token ID to the list of a given address
    * @param _to address representing the new owner of the given token ID
    * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
    */
    function addTokenTo(address _to, uint256 _tokenId) internal {
        super.addTokenTo(_to, _tokenId);
        uint256 length = ownedTokens[_to].length;
        ownedTokens[_to].push(_tokenId);
        ownedTokensIndex[_tokenId] = length;
    }

    /**
    * @dev Internal function to remove a token ID from the list of a given address
    * @param _from address representing the previous owner of the given token ID
    * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
    */
    function removeTokenFrom(address _from, uint256 _tokenId) internal {
        super.removeTokenFrom(_from, _tokenId);

        // To prevent a gap in the array, we store the last token in the index of the token to delete, and
        // then delete the last slot.
        uint256 tokenIndex = ownedTokensIndex[_tokenId];
        uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
        uint256 lastToken = ownedTokens[_from][lastTokenIndex];

        ownedTokens[_from][tokenIndex] = lastToken;
        // This also deletes the contents at the last position of the array
        ownedTokens[_from].length--;

        // Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are going to
        // be zero. Then we can make sure that we will remove _tokenId from the ownedTokens list since we are first swapping
        // the lastToken to the first position, and then dropping the element placed in the last position of the list

        ownedTokensIndex[_tokenId] = 0;
        ownedTokensIndex[lastToken] = tokenIndex;
    }

    /**
    * @dev Gets the token name
    * @return string representing the token name
    */
    function name() public view returns (string) {
        return name_;
    }

    /**
    * @dev Gets the token symbol
    * @return string representing the token symbol
    */
    function symbol() public view returns (string) {
        return symbol_;
    }

    /**
    * @dev Internal function to mint a new token
    * @dev Reverts if the given token ID already exists
    * @param _to address the beneficiary that will own the minted token
    * @param _tokenId uint256 ID of the token to be minted by the msg.sender
    */
    function _mint(address _to, uint256 _tokenId) internal {
        super._mint(_to, _tokenId);

        allTokensIndex[_tokenId] = allTokens.length;
        allTokens.push(_tokenId);
    }

    /**
    * @dev Internal function to burn a specific token
    * @dev Reverts if the token does not exist
    * @param _owner owner of the token to burn
    * @param _tokenId uint256 ID of the token being burned by the msg.sender
    */
    function _burn(address _owner, uint256 _tokenId) internal {
        super._burn(_owner, _tokenId);

        // Reorg all tokens array
        uint256 tokenIndex = allTokensIndex[_tokenId];
        uint256 lastTokenIndex = allTokens.length.sub(1);
        uint256 lastToken = allTokens[lastTokenIndex];

        allTokens[tokenIndex] = lastToken;
        allTokens[lastTokenIndex] = 0;

        allTokens.length--;
        allTokensIndex[_tokenId] = 0;
        allTokensIndex[lastToken] = tokenIndex;
    }

    bytes4 constant InterfaceSignature_ERC165 = 0x01ffc9a7;
    /*
    bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;));
    */

    bytes4 constant InterfaceSignature_ERC721Enumerable = 0x780e9d63;
    /*
    bytes4(keccak256(&#39;totalSupply()&#39;)) ^
    bytes4(keccak256(&#39;tokenOfOwnerByIndex(address,uint256)&#39;)) ^
    bytes4(keccak256(&#39;tokenByIndex(uint256)&#39;));
    */

    bytes4 constant InterfaceSignature_ERC721Metadata = 0x5b5e139f;
    /*
    bytes4(keccak256(&#39;name()&#39;)) ^
    bytes4(keccak256(&#39;symbol()&#39;)) ^
    bytes4(keccak256(&#39;tokenURI(uint256)&#39;));
    */

    bytes4 constant InterfaceSignature_ERC721 = 0x80ac58cd;
    /*
    bytes4(keccak256(&#39;balanceOf(address)&#39;)) ^
    bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^
    bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^
    bytes4(keccak256(&#39;getApproved(uint256)&#39;)) ^
    bytes4(keccak256(&#39;setApprovalForAll(address,bool)&#39;)) ^
    bytes4(keccak256(&#39;isApprovedForAll(address,address)&#39;)) ^
    bytes4(keccak256(&#39;transferFrom(address,address,uint256)&#39;)) ^
    bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256)&#39;)) ^
    bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256,bytes)&#39;));
    */

    bytes4 public constant InterfaceSignature_ERC721Optional =- 0x4f558e79;
    /*
    bytes4(keccak256(&#39;exists(uint256)&#39;));
    */

    /**
    * @notice Introspection interface as per ERC-165 (https://github.com/ethereum/EIPs/issues/165).
    * @dev Returns true for any standardized interfaces implemented by this contract.
    * @param _interfaceID bytes4 the interface to check for
    * @return true for any standardized interfaces implemented by this contract.
    */
    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {
        return ((_interfaceID == InterfaceSignature_ERC165)
        || (_interfaceID == InterfaceSignature_ERC721)
        || (_interfaceID == InterfaceSignature_ERC721Enumerable)
        || (_interfaceID == InterfaceSignature_ERC721Metadata));
    }

    function implementsERC721() public pure returns (bool) {
        return true;
    }

}
/* Lucid Sight, Inc. ERC-721 Collectibles. 
 * @title LSNFT - Lucid Sight, Inc. Non-Fungible Token
 * @author Fazri Zubair & Farhan Khwaja (Lucid Sight, Inc.)
 */
contract LSNFT is ERC721Token {
  
  /*** EVENTS ***/

  /// @dev The Created event is fired whenever a new collectible comes into existence.
  event Created(address owner, uint256 tokenId);
  
  /*** DATATYPES ***/
  
  struct NFT {
    // The sequence of potential attributes a Collectible has and can provide in creation events. Used in Creation logic to spwan new Cryptos
    uint256 attributes;

    // Current Game Card identifier
    uint256 currentGameCardId;

    // MLB Game Identifier (if asset generated as a game reward)
    uint256 mlbGameId;

    // player orverride identifier
    uint256 playerOverrideId;

    // official MLB Player ID
    uint256 mlbPlayerId;

    // earnedBy : In some instances we may want to retroactively write which MLB player triggered
    // the event that created a Legendary Trophy. This optional field should be able to be written
    // to after generation if we determine an event was newsworthy enough
    uint256 earnedBy;
    
    // asset metadata
    uint256 assetDetails;
    
    // Attach/Detach Flag
    uint256 isAttached;
  }

  NFT[] allNFTs;

  function isLSNFT() public view returns (bool) {
    return true;
  }

  /// For creating NFT
  function _createNFT (
    uint256[5] _nftData,
    address _owner,
    uint256 _isAttached)
    internal
    returns(uint256) {

    NFT memory _lsnftObj = NFT({
        attributes : _nftData[1],
        currentGameCardId : 0,
        mlbGameId : _nftData[2],
        playerOverrideId : _nftData[3],
        assetDetails: _nftData[0],
        isAttached: _isAttached,
        mlbPlayerId: _nftData[4],
        earnedBy: 0
    });

    uint256 newLSNFTId = allNFTs.push(_lsnftObj) - 1;

    _mint(_owner, newLSNFTId);
    
    // Created event
    emit Created(_owner, newLSNFTId);

    return newLSNFTId;
  }

  /// @dev Gets attributes of NFT  
  function _getAttributesOfToken(uint256 _tokenId) internal returns(NFT) {
    NFT storage lsnftObj = allNFTs[_tokenId];  
    return lsnftObj;
  }

  function _approveForSale(address _owner, address _to, uint256 _tokenId) internal {
    address owner = ownerOf(_tokenId);
    require (_to != owner);
    require (_owner == owner || isApprovedForAll(owner, _owner));

    if (getApproved(_tokenId) != address(0) || _to != address(0)) {
        tokenApprovals[_tokenId] = _to;
        emit Approval(_owner, _to, _tokenId);
    }
  }
}

/** Controls state and access rights for contract functions
 * @title Operational Control
 * @author Fazri Zubair & Farhan Khwaja (Lucid Sight, Inc.)
 * Inspired and adapted from contract created by OpenZeppelin 
 * Ref: https://github.com/OpenZeppelin/zeppelin-solidity/
 */
contract OperationalControl {
    /// Facilitates access & control for the game.
    /// Roles:
    ///  -The Managers (Primary/Secondary): Has universal control of all elements (No ability to withdraw)
    ///  -The Banker: The Bank can withdraw funds and adjust fees / prices.
    ///  -otherManagers: Contracts that need access to functions for gameplay

    /// @dev Emited when contract is upgraded
    event ContractUpgrade(address newContract);

    /// @dev The addresses of the accounts (or contracts) that can execute actions within each roles.
    address public managerPrimary;
    address public managerSecondary;
    address public bankManager;

    // Contracts that require access for gameplay
    mapping(address => uint8) public otherManagers;

    // @dev Keeps track whether the contract is paused. When that is true, most actions are blocked
    bool public paused = false;

    // @dev Keeps track whether the contract erroredOut. When that is true, most actions are blocked & refund can be claimed
    bool public error = false;

    /**
     * @dev Operation modifiers for limiting access only to Managers
     */
    modifier onlyManager() {
        require (msg.sender == managerPrimary || msg.sender == managerSecondary);
        _;
    }

    /**
     * @dev Operation modifiers for limiting access to only Banker
     */
    modifier onlyBanker() {
        require (msg.sender == bankManager);
        _;
    }

    /**
     * @dev Operation modifiers for any Operators
     */
    modifier anyOperator() {
        require (
            msg.sender == managerPrimary ||
            msg.sender == managerSecondary ||
            msg.sender == bankManager ||
            otherManagers[msg.sender] == 1
        );
        _;
    }

    /**
     * @dev        Operation modifier for any Other Manager
     */
    modifier onlyOtherManagers() {
        require (otherManagers[msg.sender] == 1);
        _;
    }

    /**
     * @dev Assigns a new address to act as the Primary Manager.
     * @param _newGM    New primary manager address
     */
    function setPrimaryManager(address _newGM) external onlyManager {
        require (_newGM != address(0));

        managerPrimary = _newGM;
    }

    /**
     * @dev Assigns a new address to act as the Secondary Manager.
     * @param _newGM    New Secondary Manager Address
     */
    function setSecondaryManager(address _newGM) external onlyManager {
        require (_newGM != address(0));

        managerSecondary = _newGM;
    }

    /**
     * @dev Assigns a new address to act as the Banker.
     * @param _newBK    New Banker Address
     */
    function setBanker(address _newBK) external onlyManager {
        require (_newBK != address(0));

        bankManager = _newBK;
    }

    /// @dev Assigns a new address to act as the Other Manager. (State = 1 is active, 0 is disabled)
    function setOtherManager(address _newOp, uint8 _state) external onlyManager {
        require (_newOp != address(0));

        otherManagers[_newOp] = _state;
    }

    /*** Pausable functionality adapted from OpenZeppelin ***/

    /// @dev Modifier to allow actions only when the contract IS NOT paused
    modifier whenNotPaused() {
        require (!paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract IS paused
    modifier whenPaused {
        require (paused);
        _;
    }

    /// @dev Modifier to allow actions only when the contract has Error
    modifier whenError {
        require (error);
        _;
    }

    /**
     * @dev Called by any Operator role to pause the contract.
     * Used only if a bug or exploit is discovered (Here to limit losses / damage)
     */
    function pause() external onlyManager whenNotPaused {
        paused = true;
    }

    /**
     * @dev Unpauses the smart contract. Can only be called by the Game Master
     */
    function unpause() public onlyManager whenPaused {
        // can&#39;t unpause if contract was upgraded
        paused = false;
    }

    /**
     * @dev Errors out the contract thus mkaing the contract non-functionable
     */
    function hasError() public onlyManager whenPaused {
        error = true;
    }

    /**
     * @dev Removes the Error Hold from the contract and resumes it for working
     */
    function noError() public onlyManager whenPaused {
        error = false;
    }
}

/** Base contract for DodgersNFT Collectibles. Holds all commons, events and base variables.
 * @title Lucid Sight MLB NFT 2018
 * @author Fazri Zubair & Farhan Khwaja (Lucid Sight, Inc.)
 */
contract CollectibleBase is LSNFT {

    /*** EVENTS ***/

    /// @dev Event emitted when an attribute of the player is updated
    event AssetUpdated(uint256 tokenId);

    /*** STORAGE ***/

    /// @dev A mapping of Team Id to Team Sequence Number to Collectible
    mapping (uint256 => mapping (uint32 => uint256) ) public nftTeamIdToSequenceIdToCollectible;

    /// @dev A mapping from Team IDs to the Sequqence Number .
    mapping (uint256 => uint32) public nftTeamIndexToCollectibleCount;

    /// @dev Array to hold details on attachment for each LS NFT Collectible
    mapping(uint256 => uint256[]) public nftCollectibleAttachments;

    /// @dev Mapping to control the asset generation per season.
    mapping(uint256 => uint256) public generationSeasonController;

    /// @dev Mapping for generation Season Dict.
    mapping(uint256 => uint256) public generationSeasonDict;

    /// @dev internal function to update player override id
    function _updatePlayerOverrideId(uint256 _tokenId, uint256 _newPlayerOverrideId) internal {

        // Get Token Obj
        NFT storage lsnftObj = allNFTs[_tokenId];
        lsnftObj.playerOverrideId = _newPlayerOverrideId;

        // Update Token Data with new updated attributes
        allNFTs[_tokenId] = lsnftObj;

        emit AssetUpdated(_tokenId);
    }

    /**
     * @dev An internal method that helps in generation of new NFT Collectibles
     * @param _teamId           teamId of the asset/token/collectible
     * @param _attributes       attributes of asset/token/collectible
     * @param _owner            owner of asset/token/collectible
     * @param _isAttached       State of the asset (attached or dettached)
     * @param _nftData          Array of data required for creation
     */
    function _createNFTCollectible(
        uint8 _teamId,
        uint256 _attributes,
        address _owner,
        uint256 _isAttached,
        uint256[5] _nftData
    )
        internal
        returns (uint256)
    {
        uint256 generationSeason = (_attributes % 1000000).div(1000);
        require (generationSeasonController[generationSeason] == 1);

        uint32 _sequenceId = getSequenceId(_teamId);

        uint256 newNFTCryptoId = _createNFT(_nftData, _owner, _isAttached);
        
        nftTeamIdToSequenceIdToCollectible[_teamId][_sequenceId] = newNFTCryptoId;
        nftTeamIndexToCollectibleCount[_teamId] = _sequenceId;

        return newNFTCryptoId;
    }
    
    function getSequenceId(uint256 _teamId) internal returns (uint32) {
        return (nftTeamIndexToCollectibleCount[_teamId] + 1);
    }

    /**
     * @dev Internal function, Helps in updating the Creation Stop Time
     * @param _season    Season UINT Code
     * @param _value    0 - Not allowed, 1 - Allowed
     */
    function _updateGenerationSeasonFlag(uint256 _season, uint8 _value) internal {
        generationSeasonController[_season] = _value;
    }

    /** @param _owner The owner whose ships tokens we are interested in.
      * @dev This method MUST NEVER be called by smart contract code. First, it&#39;s fairly
      *  expensive (it walks the entire Collectibles owners array looking for NFT belonging to owner)
    */      
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalItems = balanceOf(_owner);
            uint256 resultIndex = 0;

            // We count on the fact that all Collectible have IDs starting at 0 and increasing
            // sequentially up to the total count.
            uint256 _assetId;

            for (_assetId = 0; _assetId < totalItems; _assetId++) {
                result[resultIndex] = tokenOfOwnerByIndex(_owner,_assetId);
                resultIndex++;
            }

            return result;
        }
    }

    /// @dev internal function to update MLB player id
    function _updateMLBPlayerId(uint256 _tokenId, uint256 _newMLBPlayerId) internal {

        // Get Token Obj
        NFT storage lsnftObj = allNFTs[_tokenId];
        
        lsnftObj.mlbPlayerId = _newMLBPlayerId;

        // Update Token Data with new updated attributes
        allNFTs[_tokenId] = lsnftObj;

        emit AssetUpdated(_tokenId);
    }

    /// @dev internal function to update asset earnedBy value for an asset/token
    function _updateEarnedBy(uint256 _tokenId, uint256 _earnedBy) internal {

        // Get Token Obj
        NFT storage lsnftObj = allNFTs[_tokenId];
        
        lsnftObj.earnedBy = _earnedBy;

        // Update Token Data with new updated attributes
        allNFTs[_tokenId] = lsnftObj;

        emit AssetUpdated(_tokenId);
    }
}

/* Handles creating new Collectibles for promo and seed.
 * @title CollectibleMinting Minting
 * @author Fazri Zubair & Farhan Khwaja (Lucid Sight, Inc.)
 * Inspired and adapted from KittyCore.sol created by Axiom Zen
 * Ref: ETH Contract - 0x06012c8cf97BEaD5deAe237070F9587f8E7A266d
 */
contract CollectibleMinting is CollectibleBase, OperationalControl {

    uint256 public rewardsRedeemed = 0;

    /// @dev Counts the number of promo collectibles that can be made per-team
    uint256[31]  public promoCreatedCount;
    
    /// @dev Counts the number of seed collectibles that can be made in total
    uint256 public seedCreatedCount;

    /// @dev Bool to toggle batch support
    bool public isBatchSupported = true;
    
    /// @dev A mapping of contracts that can trigger functions
    mapping (address => bool) public contractsApprovedList;
    
    /**
     * @dev        Helps to toggle batch supported flag
     * @param      _flag  The flag
     */
    function updateBatchSupport(bool _flag) public onlyManager {
        isBatchSupported = _flag;
    }

    modifier canCreate() { 
        require (contractsApprovedList[msg.sender] || 
            msg.sender == managerPrimary ||
            msg.sender == managerSecondary); 
        _; 
    }
    
    /**
     * @dev Add an address to the Approved List
     * @param _newAddress   The new address to be approved for interaction with the contract
     */
    function addToApproveList(address _newAddress) public onlyManager {
        
        require (!contractsApprovedList[_newAddress]);
        contractsApprovedList[_newAddress] = true;
    }

    /**
     * @dev Remove an address from Approved List
     * @param _newAddress   The new address to be approved for interaction with the contract
     */
    function removeFromApproveList(address _newAddress) public onlyManager {
        require (contractsApprovedList[_newAddress]);
        delete contractsApprovedList[_newAddress];
    }

    
    /**
     * @dev Generates promo collectibles. Only callable by Game Master, with isAttached as 0.
     * @notice The generation of an asset if limited via the generationSeasonController
     * @param _teamId           teamId of the asset/token/collectible
     * @param _posId            position of the asset/token/collectible
     * @param _attributes       attributes of asset/token/collectible
     * @param _owner            owner of asset/token/collectible
     * @param _gameId          mlb game Identifier
     * @param _playerOverrideId player override identifier
     * @param _mlbPlayerId      official mlb player identifier
     */
    function createPromoCollectible(
        uint8 _teamId,
        uint8 _posId,
        uint256 _attributes,
        address _owner,
        uint256 _gameId,
        uint256 _playerOverrideId,
        uint256 _mlbPlayerId)
        external
        canCreate
        whenNotPaused
        returns (uint256)
        {

        address nftOwner = _owner;
        if (nftOwner == address(0)) {
             nftOwner = managerPrimary;
        }

        if(allNFTs.length > 0) {
            promoCreatedCount[_teamId]++;
        }
        
        uint32 _sequenceId = getSequenceId(_teamId);
        
        uint256 assetDetails = uint256(uint64(now));
        assetDetails |= uint256(_sequenceId)<<64;
        assetDetails |= uint256(_teamId)<<96;
        assetDetails |= uint256(_posId)<<104;

        uint256[5] memory _nftData = [assetDetails, _attributes, _gameId, _playerOverrideId, _mlbPlayerId];
        
        return _createNFTCollectible(_teamId, _attributes, nftOwner, 0, _nftData);
    }

    /**
     * @dev Generaes a new single seed Collectible, with isAttached as 0.
     * @notice Helps in creating seed collectible.The generation of an asset if limited via the generationSeasonController
     * @param _teamId           teamId of the asset/token/collectible
     * @param _posId            position of the asset/token/collectible
     * @param _attributes       attributes of asset/token/collectible
     * @param _owner            owner of asset/token/collectible
     * @param _gameId          mlb game Identifier
     * @param _playerOverrideId player override identifier
     * @param _mlbPlayerId      official mlb player identifier
     */
    function createSeedCollectible(
        uint8 _teamId,
        uint8 _posId,
        uint256 _attributes,
        address _owner,
        uint256 _gameId,
        uint256 _playerOverrideId,
        uint256 _mlbPlayerId)
        external
        canCreate
        whenNotPaused
        returns (uint256) {

        address nftOwner = _owner;
        
        if (nftOwner == address(0)) {
             nftOwner = managerPrimary;
        }
        
        seedCreatedCount++;
        uint32 _sequenceId = getSequenceId(_teamId);
        
        uint256 assetDetails = uint256(uint64(now));
        assetDetails |= uint256(_sequenceId)<<64;
        assetDetails |= uint256(_teamId)<<96;
        assetDetails |= uint256(_posId)<<104;

        uint256[5] memory _nftData = [assetDetails, _attributes, _gameId, _playerOverrideId, _mlbPlayerId];
        
        return _createNFTCollectible(_teamId, _attributes, nftOwner, 0, _nftData);
    }

    /**
     * @dev Generate new Reward Collectible and transfer it to the owner, with isAttached as 0.
     * @notice Helps in redeeming the Rewards using our Oracle. Creates & transfers the asset to the redeemer (_owner)
     * The generation of an asset if limited via the generationSeasonController
     * @param _teamId           teamId of the asset/token/collectible
     * @param _posId            position of the asset/token/collectible
     * @param _attributes       attributes of asset/token/collectible
     * @param _owner            owner (redeemer) of asset/token/collectible
     * @param _gameId           mlb game Identifier
     * @param _playerOverrideId player override identifier
     * @param _mlbPlayerId      official mlb player identifier
     */
    function createRewardCollectible (
        uint8 _teamId,
        uint8 _posId,
        uint256 _attributes,
        address _owner,
        uint256 _gameId,
        uint256 _playerOverrideId,
        uint256 _mlbPlayerId)
        external
        canCreate
        whenNotPaused
        returns (uint256) {

        address nftOwner = _owner;
        
        if (nftOwner == address(0)) {
             nftOwner = managerPrimary;
        }
        
        rewardsRedeemed++;
        uint32 _sequenceId = getSequenceId(_teamId);
        
        uint256 assetDetails = uint256(uint64(now));
        assetDetails |= uint256(_sequenceId)<<64;
        assetDetails |= uint256(_teamId)<<96;
        assetDetails |= uint256(_posId)<<104;

        uint256[5] memory _nftData = [assetDetails, _attributes, _gameId, _playerOverrideId, _mlbPlayerId];
        
        return _createNFTCollectible(_teamId, _attributes, nftOwner, 0, _nftData);
    }

    /**
     * @dev Generate new ETH Card Collectible, with isAttached as 2.
     * @notice Helps to generate Collectibles/Tokens/Asset and transfer to ETH Cards,
     * which can be redeemed using our web-app.The generation of an asset if limited via the generationSeasonController
     * @param _teamId           teamId of the asset/token/collectible
     * @param _posId            position of the asset/token/collectible
     * @param _attributes       attributes of asset/token/collectible
     * @param _owner            owner of asset/token/collectible
     * @param _gameId           mlb game Identifier
     * @param _playerOverrideId player override identifier
     * @param _mlbPlayerId      official mlb player identifier
     */
    function createETHCardCollectible (
        uint8 _teamId,
        uint8 _posId,
        uint256 _attributes,
        address _owner,
        uint256 _gameId,
        uint256 _playerOverrideId,
        uint256 _mlbPlayerId)
        external
        canCreate
        whenNotPaused
        returns (uint256) {

        address nftOwner = _owner;
        
        if (nftOwner == address(0)) {
             nftOwner = managerPrimary;
        }
        
        rewardsRedeemed++;
        uint32 _sequenceId = getSequenceId(_teamId);
        
        uint256 assetDetails = uint256(uint64(now));
        assetDetails |= uint256(_sequenceId)<<64;
        assetDetails |= uint256(_teamId)<<96;
        assetDetails |= uint256(_posId)<<104;

        uint256[5] memory _nftData = [assetDetails, _attributes, _gameId, _playerOverrideId, _mlbPlayerId];
        
        return _createNFTCollectible(_teamId, _attributes, nftOwner, 2, _nftData);
    }
}

/* @title Interface for DodgersNFT Contract
 * @author Fazri Zubair & Farhan Khwaja (Lucid Sight, Inc.)
 */
contract SaleManager {
    function createSale(uint256 _tokenId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration, address _owner) external;
}

/**
 * DodgersNFT manages all aspects of the Lucid Sight, Inc. CryptoBaseball.
 * @title DodgersNFT
 * @author Fazri Zubair & Farhan Khwaja (Lucid Sight, Inc.)
 */
contract DodgersNFT is CollectibleMinting {
    
    /// @dev Set in case the DodgersNFT contract requires an upgrade
    address public newContractAddress;

    string public constant MLB_Legal = "Major League Baseball trademarks and copyrights are used with permission of the applicable MLB entity.  All rights reserved.";

    // Time LS Oracle has to respond to detach requests
    uint32 public detachmentTime = 0;

    // Indicates if attached system is Active (Transfers will be blocked if attached and active)
    bool public attachedSystemActive;

    // Sale Manager Contract
    SaleManager public saleManagerAddress;

    /**
     * @dev DodgersNFT constructor.
     */
    constructor() public {
        // Starts paused.
        paused = true;
        managerPrimary = msg.sender;
        managerSecondary = msg.sender;
        bankManager = msg.sender;
        name_ = "LucidSight-DODGERS-NFT";
        symbol_ = "DNFTCB";
    }

    /**
     * @dev        Sets the address for the NFT Contract
     * @param      _saleManagerAddress  The nft address
     */
    function setSaleManagerAddress(address _saleManagerAddress) public onlyManager {
        require (_saleManagerAddress != address(0));
        saleManagerAddress = SaleManager(_saleManagerAddress);
    }

    /**
    * @dev Checks msg.sender can transfer a token, by being owner, approved, or operator
    * @param _tokenId uint256 ID of the token to validate
    */
    modifier canTransfer(uint256 _tokenId) {
        uint256 isAttached = checkIsAttached(_tokenId);
        if(isAttached == 2) {
            //One-Time Auth for Physical Card Transfers
            require (msg.sender == managerPrimary ||
                msg.sender == managerSecondary ||
                msg.sender == bankManager ||
                otherManagers[msg.sender] == 1
            );
            updateIsAttached(_tokenId, 0);
        } else if(attachedSystemActive == true && isAttached >= 1) {
            require (msg.sender == managerPrimary ||
                msg.sender == managerSecondary ||
                msg.sender == bankManager ||
                otherManagers[msg.sender] == 1
            );
        }
        else {
            require (isApprovedOrOwner(msg.sender, _tokenId));
        }
    _;
    }

    /**
     * @dev Used to mark the smart contract as upgraded, in case of a issue
     * @param _v2Address    The new contract address
     */
    function setNewAddress(address _v2Address) external onlyManager {
        require (_v2Address != address(0));
        newContractAddress = _v2Address;
        emit ContractUpgrade(_v2Address);
    }

    /**
     * @dev Returns all the relevant information about a specific Collectible.
     * @notice Get details about your collectible
     * @param _tokenId              The token identifier
     * @return isAttached           Is Object attached
     * @return teamId               team identifier of the asset/token/collectible
     * @return positionId           position identifier of the asset/token/collectible
     * @return creationTime         creation timestamp
     * @return attributes           attribute of the asset/token/collectible
     * @return currentGameCardId    current game card of the asset/token/collectible
     * @return mlbGameID            mlb game identifier in which the asset/token/collectible was generated
     * @return playerOverrideId     player override identifier of the asset/token/collectible
     * @return playerStatus         status of the player (Rookie/Veteran/Historical)
     * @return playerHandedness     handedness of the asset
     * @return mlbPlayerId          official MLB Player Identifier
     */
    function getCollectibleDetails(uint256 _tokenId)
        external
        view
        returns (
        uint256 isAttached,
        uint32 sequenceId,
        uint8 teamId,
        uint8 positionId,
        uint64 creationTime,
        uint256 attributes,
        uint256 playerOverrideId,
        uint256 mlbGameId,
        uint256 currentGameCardId,
        uint256 mlbPlayerId,
        uint256 earnedBy,
        uint256 generationSeason
        ) {
        NFT memory obj  = _getAttributesOfToken(_tokenId);
        
        attributes = obj.attributes;
        currentGameCardId = obj.currentGameCardId;
        mlbGameId = obj.mlbGameId;
        playerOverrideId = obj.playerOverrideId;
        mlbPlayerId = obj.mlbPlayerId;

        creationTime = uint64(obj.assetDetails);
        sequenceId = uint32(obj.assetDetails>>64);
        teamId = uint8(obj.assetDetails>>96);
        positionId = uint8(obj.assetDetails>>104);
        isAttached = obj.isAttached;
        earnedBy = obj.earnedBy;

        generationSeason = generationSeasonDict[(obj.attributes % 1000000) / 1000];
    }

    
    /**
     * @dev This is public rather than external so we can call super.unpause
     * without using an expensive CALL.
     */
    function unpause() public onlyManager {
        /// Actually unpause the contract.
        super.unpause();
    }

    /**
     * @dev Helper function to get the teamID of a collectible.To avoid using getCollectibleDetails
     * @notice Returns the teamID associated with the asset/collectible/token
     * @param _tokenId  The token identifier
     */
    function getTeamId(uint256 _tokenId) external view returns (uint256) {
        NFT memory obj  = _getAttributesOfToken(_tokenId);

        uint256 teamId = uint256(uint8(obj.assetDetails>>96));
        return uint256(teamId);
    }

    /**
     * @dev Helper function to get the position of a collectible.To avoid using getCollectibleDetails
     * @notice Returns the position of the asset/collectible/token
     * @param _tokenId  The token identifier
     */
    function getPositionId(uint256 _tokenId) external view returns (uint256) {
        NFT memory obj  = _getAttributesOfToken(_tokenId);

        uint256 positionId = uint256(uint8(obj.assetDetails>>104));

        return positionId;
    }

    /**
     * @dev Helper function to get the game card. To avoid using getCollectibleDetails
     * @notice Returns the gameCard associated with the asset/collectible/token
     * @param _tokenId  The token identifier
     */
    function getGameCardId(uint256 _tokenId) public view returns (uint256) {
        NFT memory obj  = _getAttributesOfToken(_tokenId);
        return obj.currentGameCardId;
    }

    /**
     * @dev Returns isAttached property value for an asset/collectible/token
     * @param _tokenId  The token identifier
     */
    function checkIsAttached(uint256 _tokenId) public view returns (uint256) {
        NFT memory obj  = _getAttributesOfToken(_tokenId);
        return obj.isAttached;
    }

    /**
     * @dev Helper function to get the attirbute of the collectible.To avoid using getCollectibleDetails
     * @notice Returns the ability of an asset/collectible/token from attributes.
     * @param _tokenId  The token identifier
     * @return ability  ability of the asset
     */
    function getAbilitiesForCollectibleId(uint256 _tokenId) external view returns (uint256 ability) {
        NFT memory obj  = _getAttributesOfToken(_tokenId);
        uint256 _attributes = uint256(obj.attributes);
        ability = (_attributes % 1000);
    }

    /**
     * @dev Only allows trasnctions to go throught if the msg.sender is in the apporved list
     * @notice Updates the gameCardID properrty of the asset
     * @param _gameCardNumber  The game card number
     * @param _playerId        The player identifier
     */
    function updateCurrentGameCardId(uint256 _gameCardNumber, uint256 _playerId) public whenNotPaused {
        require (contractsApprovedList[msg.sender]);

        NFT memory obj  = _getAttributesOfToken(_playerId);
        
        obj.currentGameCardId = _gameCardNumber;
        
        if ( _gameCardNumber == 0 ) {
            obj.isAttached = 0;
        } else {
            obj.isAttached = 1;
        }

        allNFTs[_playerId] = obj;
    }

    /**
     * @dev Only Manager can add an attachment (special events) to the collectible
     * @notice Adds an attachment to collectible.
     * @param _tokenId  The token identifier
     * @param _attachment  The attachment
     */
    function addAttachmentToCollectible ( 
        uint256 _tokenId,
        uint256 _attachment)
        external
        onlyManager
        whenNotPaused {
        require (exists(_tokenId));

        nftCollectibleAttachments[_tokenId].push(_attachment);
        emit AssetUpdated(_tokenId);
    }

    /**
     * @dev It will remove the attachment form the collectible. We will need to re-add all attachment(s) if removed.
     * @notice Removes all attachments from collectible.
     * @param _tokenId  The token identifier
     */
    function removeAllAttachmentsFromCollectible(uint256 _tokenId)
        external
        onlyManager
        whenNotPaused {

        require (exists(_tokenId));
        
        delete nftCollectibleAttachments[_tokenId];
        emit AssetUpdated(_tokenId);
    }

    /**
     * @notice Transfers the ownership of NFT from one address to another address
     * @dev responsible for gifting assets to other user.
     * @param _to       to address
     * @param _tokenId  The token identifier
     */
    function giftAsset(address _to, uint256 _tokenId) public whenNotPaused {        
        safeTransferFrom(msg.sender, _to, _tokenId);
    }
    
    /**
     * @dev responsible for setting the tokenURI.
     * @notice The user/developper needs to add the tokenID, in the end of URL, to 
     * use the URI and get all details. Ex. www.<apiURL>.com/token/<tokenID>
     * @param _tokenURI  The token uri
     */
    function setTokenURIBase (string _tokenURI) public anyOperator {
        _setTokenURIBase(_tokenURI);
    }

    /**
     * @dev Allowed to be called by onlyGameManager to update a certain collectible playerOverrideID
     * @notice Sets the player override identifier.
     * @param _tokenId      The token identifier
     * @param _newOverrideId     The new player override identifier
     */
    function setPlayerOverrideId(uint256 _tokenId, uint256 _newOverrideId) public onlyManager whenNotPaused {
        require (exists(_tokenId));

        _updatePlayerOverrideId(_tokenId, _newOverrideId);
    }

    /**
     * @notice Updates the Generation Season Controller.
     * @dev Allowed to be called by onlyGameManager to update the generation season.
     * this helps to control the generation of collectible.
     * @param _season    Season UINT representation
     * @param _value    0-Not allowed, 1-open, >=2 Locked Forever
     */
    function updateGenerationStopTime(uint256 _season, uint8 _value ) public  onlyManager whenNotPaused {
        require (generationSeasonController[_season] == 1 && _value != 0);
        _updateGenerationSeasonFlag(_season, _value);
    }

    /**
     * @dev set Generation Season Controller, can only be called by Managers._season can be [0,1,2,3..] and 
     * _value can be [0,1,N].
     * @notice _value of 1: means generation of collectible is allowed. anything, apart from 1, wont allow generating assets for that season.
     * @param _season    Season UINT representation
     */
    function setGenerationSeasonController(uint256 _season) public onlyManager whenNotPaused {
        require (generationSeasonController[_season] == 0);
        _updateGenerationSeasonFlag(_season, 1);
    }

    /**
     * @dev Adding value to DICT helps in showing the season value in getCollectibleDetails
     * @notice Updates the Generation Season Dict.
     * @param _season    Season UINT representation
     * @param _value    0-Not allowed,1-allowed
     */
    function updateGenerationDict(uint256 _season, uint64 _value) public onlyManager whenNotPaused {
        require (generationSeasonDict[_season] <= 1);
        generationSeasonDict[_season] = _value;
    }

    /**
     * @dev Helper function to avoid calling getCollectibleDetails
     * @notice Gets the MLB player Id from the player attributes
     * @param _tokenId  The token identifier
     * @return playerId  MLB Player Identifier
     */
    function getPlayerId(uint256 _tokenId) external view returns (uint256 playerId) {
        NFT memory obj  = _getAttributesOfToken(_tokenId);
        playerId = ((obj.attributes.div(100000000000000000)) % 1000);
    }
    
    /**
     * @dev Helper function to avoid calling getCollectibleDetails
     * @notice Gets the attachments for an asset
     * @param _tokenId  The token identifier
     * @return attachments
     */
    function getAssetAttachment(uint256 _tokenId) external view returns (uint256[]) {
        uint256[] _attachments = nftCollectibleAttachments[_tokenId];
        uint256[] attachments;
        for(uint i=0;i<_attachments.length;i++){
            attachments.push(_attachments[i]);
        }
        
        return attachments;
    }

    /**
     * @dev Can only be trigerred by Managers. Updates the earnedBy property of the NFT
     * @notice Helps in updating the earned _by property of an asset/token.
     * @param  _tokenId        asser/token identifier
     * @param  _earnedBy       New asset/token DNA
     */
    function updateEarnedBy(uint256 _tokenId, uint256 _earnedBy) public onlyManager whenNotPaused {
        require (exists(_tokenId));

        _updateEarnedBy(_tokenId, _earnedBy);
    }

    /**
     * @dev A batch function to facilitate batching of asset creation. canCreate modifier
     * helps in controlling who can call the function
     * @notice Batch Function to Create Assets
     * @param      _teamId            The team identifier
     * @param      _attributes        The attributes
     * @param      _playerOverrideId  The player override identifier
     * @param      _mlbPlayerId       The mlb player identifier
     * @param      _to                To Address
     */
    function batchCreateAsset(
        uint8[] _teamId,
        uint256[] _attributes,
        uint256[] _playerOverrideId,
        uint256[] _mlbPlayerId,
        address[] _to)
        external
        canCreate
        whenNotPaused {
            require (isBatchSupported);

            require (_teamId.length > 0 && _attributes.length > 0 && 
                _playerOverrideId.length > 0 && _mlbPlayerId.length > 0 && 
                _to.length > 0);

            uint256 assetDetails;
            uint256[5] memory _nftData;
            
            for(uint ii = 0; ii < _attributes.length; ii++){
                require (_to[ii] != address(0) && _teamId[ii] != 0 && _attributes.length != 0 && 
                    _mlbPlayerId[ii] != 0);
                
                assetDetails = uint256(uint64(now));
                assetDetails |= uint256(getSequenceId(_teamId[ii]))<<64;
                assetDetails |= uint256(_teamId[ii])<<96;
                assetDetails |= uint256((_attributes[ii]/1000000000000000000000000000000000000000)-800)<<104;
        
                _nftData = [assetDetails, _attributes[ii], 0, _playerOverrideId[ii], _mlbPlayerId[ii]];
                
                _createNFTCollectible(_teamId[ii], _attributes[ii], _to[ii], 0, _nftData);
            }
        }

    /**
     * @dev A batch function to facilitate batching of asset creation for ETH Cards. canCreate modifier
     * helps in controlling who can call the function
     * @notice        Batch Function to Create Assets
     * @param      _teamId            The team identifier
     * @param      _attributes        The attributes
     * @param      _playerOverrideId  The player override identifier
     * @param      _mlbPlayerId       The mlb player identifier
     * @param      _to                { parameter_description }
     */
    function batchCreateETHCardAsset(
        uint8[] _teamId,
        uint256[] _attributes,
        uint256[] _playerOverrideId,
        uint256[] _mlbPlayerId,
        address[] _to)
        external
        canCreate
        whenNotPaused {
            require (isBatchSupported);

            require (_teamId.length > 0 && _attributes.length > 0
                        && _playerOverrideId.length > 0 &&
                        _mlbPlayerId.length > 0 && _to.length > 0);

            uint256 assetDetails;
            uint256[5] memory _nftData;

            for(uint ii = 0; ii < _attributes.length; ii++){

                require (_to[ii] != address(0) && _teamId[ii] != 0 && _attributes.length != 0 && 
                    _mlbPlayerId[ii] != 0);
        
                assetDetails = uint256(uint64(now));
                assetDetails |= uint256(getSequenceId(_teamId[ii]))<<64;
                assetDetails |= uint256(_teamId[ii])<<96;
                assetDetails |= uint256((_attributes[ii]/1000000000000000000000000000000000000000)-800)<<104;
        
                _nftData = [assetDetails, _attributes[ii], 0, _playerOverrideId[ii], _mlbPlayerId[ii]];
                
                _createNFTCollectible(_teamId[ii], _attributes[ii], _to[ii], 2, _nftData);
            }
        }

    /**
     * @dev        Overriden TransferFrom, with the modifier canTransfer which uses our attachment system
     * @notice     Helps in trasnferring assets
     * @param      _from     the address sending from
     * @param      _to       the address sending to
     * @param      _tokenId  The token identifier
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public
        canTransfer(_tokenId)
    {
        // Asset should not be in play
        require (checkIsAttached(_tokenId) == 0);
        
        require (_from != address(0));

        require (_to != address(0));

        clearApproval(_from, _tokenId);
        removeTokenFrom(_from, _tokenId);
        addTokenTo(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
    }

    /**
     * @dev     Facilitates batch trasnfer of collectible with multiple TO Address, depending if batch is supported on contract.
     * @notice  Batch Trasnfer with multpple TO addresses
     * @param      _tokenIds  The token identifiers
     * @param      _fromB     the address sending from
     * @param      _toB       the address sending to
     */
    function multiBatchTransferFrom(
        uint256[] _tokenIds, 
        address[] _fromB, 
        address[] _toB) 
        public
    {
        require (isBatchSupported);

        require (_tokenIds.length > 0 && _fromB.length > 0 && _toB.length > 0);

        uint256 _id;
        address _to;
        address _from;
        
        for (uint256 i = 0; i < _tokenIds.length; ++i) {

            require (_tokenIds[i] != 0 && _fromB[i] != 0 && _toB[i] != 0);

            _id = _tokenIds[i];
            _to = _toB[i];
            _from = _fromB[i];

            transferFrom(_from, _to, _id);
        }
        
    }
    
    /**
     * @dev     Facilitates batch trasnfer of collectible, depending if batch is supported on contract
     * @notice        Batch TransferFrom with the same to & from address
     * @param      _tokenIds  The asset identifiers
     * @param      _from      the address sending from
     * @param      _to        the address sending to
     */
    function batchTransferFrom(uint256[] _tokenIds, address _from, address _to) 
        public
    {
        require (isBatchSupported);

        require (_tokenIds.length > 0 && _from != address(0) && _to != address(0));

        uint256 _id;
        
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            
            require (_tokenIds[i] != 0);

            _id = _tokenIds[i];

            transferFrom(_from, _to, _id);
        }
    }
    
    /**
     * @dev     Facilitates batch trasnfer of collectible, depending if batch is supported on contract.
     * Checks for collectible 0,address 0 and then performs the transfer
     * @notice        Batch SafeTransferFrom with multiple From and to Addresses
     * @param      _tokenIds  The asset identifiers
     * @param      _fromB     the address sending from
     * @param      _toB       the address sending to
     */
    function multiBatchSafeTransferFrom(
        uint256[] _tokenIds, 
        address[] _fromB, 
        address[] _toB
        )
        public
    {
        require (isBatchSupported);

        require (_tokenIds.length > 0 && _fromB.length > 0 && _toB.length > 0);

        uint256 _id;
        address _to;
        address _from;
        
        for (uint256 i = 0; i < _tokenIds.length; ++i) {

            require (_tokenIds[i] != 0 && _fromB[i] != 0 && _toB[i] != 0);

            _id = _tokenIds[i];
            _to  = _toB[i];
            _from  = _fromB[i];

            safeTransferFrom(_from, _to, _id);
        }
    }

    /**
     * @dev     Facilitates batch trasnfer of collectible, depending if batch is supported on contract.
     * Checks for collectible 0,address 0 and then performs the transfer
     * @notice        Batch SafeTransferFrom from a single address to another address
     * @param      _tokenIds  The asset identifiers
     * @param      _from     the address sending from
     * @param      _to       the address sending to
     */
    function batchSafeTransferFrom(
        uint256[] _tokenIds, 
        address _from, 
        address _to
        )
        public
    {   
        require (isBatchSupported);

        require (_tokenIds.length > 0 && _from != address(0) && _to != address(0));

        uint256 _id;
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            require (_tokenIds[i] != 0);
            _id = _tokenIds[i];
            safeTransferFrom(_from, _to, _id);
        }
    }

    /**
     * @notice     Batch Function to approve the spender
     * @dev        Helps to approve a batch of collectibles 
     * @param      _tokenIds  The asset identifiers
     * @param      _spender   The spender
     */
    function batchApprove(
        uint256[] _tokenIds, 
        address _spender
        )
        public
    {   
        require (isBatchSupported);

        require (_tokenIds.length > 0 && _spender != address(0));
        
        uint256 _id;
        for (uint256 i = 0; i < _tokenIds.length; ++i) {

            require (_tokenIds[i] != 0);
            
            _id = _tokenIds[i];
            approve(_spender, _id);
        }
        
    }

    /**
     * @dev        Batch Function to mark spender for approved for all. Does a check
     * for address(0) and throws if true
     * @notice     Facilitates batch approveAll
     * @param      _spenders  The spenders
     * @param      _approved  The approved
     */
    function batchSetApprovalForAll(
        address[] _spenders,
        bool _approved
        )
        public
    {   
        require (isBatchSupported);

        require (_spenders.length > 0);

        address _spender;
        for (uint256 i = 0; i < _spenders.length; ++i) {        

            require (address(_spenders[i]) != address(0));
                
            _spender = _spenders[i];
            setApprovalForAll(_spender, _approved);
        }
    }  
    
    /**
     * @dev        Function to request Detachment from our Contract
     * @notice     a wallet can request to detach it collectible, so, that it can be used in other third-party contracts.
     * @param      _tokenId  The token identifier
     */
    function requestDetachment(
        uint256 _tokenId
    )
        public
    {
        //Request can only be made by owner or approved address
        require (isApprovedOrOwner(msg.sender, _tokenId));

        uint256 isAttached = checkIsAttached(_tokenId);

        //If collectible is on a gamecard prevent detachment
        require(getGameCardId(_tokenId) == 0);

        require (isAttached >= 1);

        if(attachedSystemActive == true) {
            //Checks to see if request was made and if time elapsed
            if(isAttached > 1 && block.timestamp - isAttached > detachmentTime) {
                isAttached = 0;
            } else if(isAttached > 1) {
                //Forces Tx Fail if time is already set for attachment and not less than detachmentTime
                require (isAttached == 1);
            } else {
                //Is attached, set detachment time and make request to detach
                // emit AssetUpdated(_tokenId);
                isAttached = block.timestamp;
            }
        } else {
            isAttached = 0;
        }

        updateIsAttached(_tokenId, isAttached);
    }

    /**
     * @dev        Function to attach the asset, thus, restricting transfer
     * @notice     Attaches the collectible to our contract
     * @param      _tokenId  The token identifier
     */
    function attachAsset(
        uint256 _tokenId
    )
        public
        canTransfer(_tokenId)
    {
        uint256 isAttached = checkIsAttached(_tokenId);

        require (isAttached == 0);
        isAttached = 1;

        updateIsAttached(_tokenId, isAttached);

        emit AssetUpdated(_tokenId);
    }

    /**
     * @dev        Batch attach function
     * @param      _tokenIds  The identifiers
     */
    function batchAttachAssets(uint256[] _tokenIds) public {
        require (isBatchSupported);

        for(uint i = 0; i < _tokenIds.length; i++) {
            attachAsset(_tokenIds[i]);
        }
    }

    /**
     * @dev        Batch detach function
     * @param      _tokenIds  The identifiers
     */
    function batchDetachAssets(uint256[] _tokenIds) public {
        require (isBatchSupported);

        for(uint i = 0; i < _tokenIds.length; i++) {
            requestDetachment(_tokenIds[i]);
        }
    }

    /**
     * @dev        Function to facilitate detachment when contract is paused
     * @param      _tokenId  The identifiers
     */
    function requestDetachmentOnPause (uint256 _tokenId) public whenPaused {
        //Request can only be made by owner or approved address
        require (isApprovedOrOwner(msg.sender, _tokenId));

        updateIsAttached(_tokenId, 0);
    }

    /**
     * @dev        Toggle the Attachment Switch
     * @param      _state  The state
     */
    function toggleAttachedEnforcement (bool _state) public onlyManager {
        attachedSystemActive = _state;
    }

    /**
     * @dev        Set Attachment Time Period (this restricts user from continuously trigger detachment)
     * @param      _time  The time
     */
    function setDetachmentTime (uint256 _time) public onlyManager {
        //Detactment Time can not be set greater than 2 weeks.
        require (_time <= 1209600);
        detachmentTime = uint32(_time);
    }

    /**
     * @dev        Detach Asset From System
     * @param      _tokenId  The token iddentifier
     */
    function setNFTDetached(uint256 _tokenId) public anyOperator {
        require (checkIsAttached(_tokenId) > 0);

        updateIsAttached(_tokenId, 0);
    }

    /**
     * @dev        Batch function to detach multiple assets
     * @param      _tokenIds  The token identifiers
     */
    function setBatchDetachCollectibles(uint256[] _tokenIds) public anyOperator {
        uint256 _id;
        for(uint i = 0; i < _tokenIds.length; i++) {
            _id = _tokenIds[i];
            setNFTDetached(_id);
        }
    }

    /**
     * @dev        Function to update attach value
     * @param      _tokenId     The asset id
     * @param      _isAttached  Indicates if attached
     */
    function updateIsAttached(uint256 _tokenId, uint256 _isAttached) internal {
        NFT memory obj  = _getAttributesOfToken(_tokenId);
        
        obj.isAttached = _isAttached;
    
        allNFTs[_tokenId] = obj;
        emit AssetUpdated(_tokenId);
    }

    /**
    * @dev   Facilitates Creating Sale using the Sale Contract. Forces owner check & collectibleId check
    * @notice Helps a wallet to create a sale using our Sale Contract
    * @param      _tokenId        The token identifier
    * @param      _startingPrice  The starting price
    * @param      _endingPrice    The ending price
    * @param      _duration       The duration
    */
    function initiateCreateSale(uint256 _tokenId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration) external {
        require (_tokenId != 0);
        
        // If DodgersNFT is already on any sale, this will throw
        // because it will be owned by the sale contract.
        address owner = ownerOf(_tokenId);
        require (owner == msg.sender);

        // Sale contract checks input sizes
        require (_startingPrice == _startingPrice);
        require (_endingPrice == _endingPrice);
        require (_duration == _duration);

        require (checkIsAttached(_tokenId) == 0);
        
        // One time approval for the tokenID
        _approveForSale(msg.sender, address(saleManagerAddress), _tokenId);

        saleManagerAddress.createSale(_tokenId, _startingPrice, _endingPrice, _duration, msg.sender);
    }

    /**
     * @dev        Facilitates batch auction of collectibles, and enforeces strict checking on the collectibleId,starting/ending price, duration.
     * @notice     Batch function to put 10 or less collectibles on sale
     * @param      _tokenIds        The token identifier
     * @param      _startingPrices  The starting price
     * @param      _endingPrices    The ending price
     * @param      _durations       The duration
     */
    function batchCreateAssetSale(uint256[] _tokenIds, uint256[] _startingPrices, uint256[] _endingPrices, uint256[] _durations) external whenNotPaused {

        require (_tokenIds.length > 0 && _startingPrices.length > 0 && _endingPrices.length > 0 && _durations.length > 0);
        
        // Sale contract checks input sizes
        for(uint ii = 0; ii < _tokenIds.length; ii++){

            // Do not process for tokenId 0
            require (_tokenIds[ii] != 0);
            
            require (_startingPrices[ii] == _startingPrices[ii]);
            require (_endingPrices[ii] == _endingPrices[ii]);
            require (_durations[ii] == _durations[ii]);

            // If DodgersNFT is already on any sale, this will throw
            // because it will be owned by the sale contract.
            address _owner = ownerOf(_tokenIds[ii]);
            address _msgSender = msg.sender;
            require (_owner == _msgSender);

            // Check whether the collectible is inPlay. If inPlay cant put it on Sale
            require (checkIsAttached(_tokenIds[ii]) == 0);
            
            // approve token to for Sale creation
            _approveForSale(msg.sender, address(saleManagerAddress), _tokenIds[ii]);
            
            saleManagerAddress.createSale(_tokenIds[ii], _startingPrices[ii], _endingPrices[ii], _durations[ii], msg.sender);
        }
    }
}