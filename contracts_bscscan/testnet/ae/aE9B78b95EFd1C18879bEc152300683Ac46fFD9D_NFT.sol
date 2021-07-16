/**
 *Submitted for verification at BscScan.com on 2021-07-16
*/

// SPDX-License-Identifier: MIT


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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
   *  Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`,
   *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
   */
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

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
   * @return `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
   */
  function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
}


contract ERC721Holder is ERC721Receiver {
  function onERC721Received(address, uint256, bytes) public returns(bytes4) {
    return ERC721_RECEIVED;
  }
}


/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId) public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator) public view returns (bool);

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
  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId);
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

// File: node_modules\openzeppelin-solidity\contracts\AddressUtils.sol

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
    assembly { size := extcodesize(addr) }  // solium-disable-line security/no-inline-assembly
    return size > 0;
  }

}

// File: node_modules\openzeppelin-solidity\contracts\math\SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

// File: node_modules\openzeppelin-solidity\contracts\token\ERC721\ERC721BasicToken.sol

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721BasicToken is ERC721Basic {
  using SafeMath for uint256;
  using AddressUtils for address;

  // Equals to `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`
  // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

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
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

  /**
   * @dev Checks msg.sender can transfer a token, by being owner, approved, or operator
   * @param _tokenId uint256 ID of the token to validate
   */
  modifier canTransfer(uint256 _tokenId) {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    _;
  }

  /**
   * @dev Gets the balance of the specified address
   * @param _owner address to query the balance of
   * @return uint256 representing the amount owned by the passed address
   */
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0));
    return ownedTokensCount[_owner];
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
   * @dev Returns whether the specified token exists
   * @param _tokenId uint256 ID of the token to query the existance of
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
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    if (getApproved(_tokenId) != address(0) || _to != address(0)) {
      tokenApprovals[_tokenId] = _to;
      emit Approval(owner, _to, _tokenId);
    }
  }

  /**
   * @dev Gets the approved address for a token ID, or zero if no address set
   * @param _tokenId uint256 ID of the token to query the approval of
   * @return address currently approved for a the given token ID
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
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

  /**
   * @dev Tells whether an operator is approved by a given owner
   * @param _owner owner address which you want to query the approval of
   * @param _operator operator address which you want to query the approval of
   * @return bool whether the given operator is approved by the given owner
   */
  function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
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
  function transferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
    require(_from != address(0));
    require(_to != address(0));

    clearApproval(_from, _tokenId);
    removeTokenFrom(_from, _tokenId);
    addTokenTo(_to, _tokenId);

    emit Transfer(_from, _to, _tokenId);
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * @dev If the target address is a contract, it must implement `onERC721Received`,
   *  which is called upon a safe transfer, and return the magic value
   *  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`; otherwise,
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
   *  `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`; otherwise,
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
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

  /**
   * @dev Returns whether the given spender can transfer a given token ID
   * @param _spender address of the spender to query
   * @param _tokenId uint256 ID of the token to be transferred
   * @return bool whether the msg.sender is approved for the given token ID,
   *  is an operator of the owner, or is the owner of the token
   */
  function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
    address owner = ownerOf(_tokenId);
    return _spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender);
  }

  /**
   * @dev Internal function to mint a new token
   * @dev Reverts if the given token ID already exists
   * @param _to The address that will own the minted token
   * @param _tokenId uint256 ID of the token to be minted by the msg.sender
   */
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
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
    require(ownerOf(_tokenId) == _owner);
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
      emit Approval(_owner, address(0), _tokenId);
    }
  }

  /**
   * @dev Internal function to add a token ID to the list of a given address
   * @param _to address representing the new owner of the given token ID
   * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function addTokenTo(address _to, uint256 _tokenId) internal {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
  }

  /**
   * @dev Internal function to remove a token ID from the list of a given address
   * @param _from address representing the previous owner of the given token ID
   * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _from);
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
    bytes4 retval = ERC721Receiver(_to).onERC721Received(_from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}

// File: node_modules\openzeppelin-solidity\contracts\token\ERC721\ERC721Token.sol

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
  mapping (address => uint256[]) internal ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) internal ownedTokensIndex;

  // Array with all token ids, used for enumeration
  uint256[] internal allTokens;

  // Mapping from token id to position in the allTokens array
  mapping(uint256 => uint256) internal allTokensIndex;

  // Optional mapping for token URIs
  mapping(uint256 => string) internal tokenURIs;

  /**
   * @dev Constructor function
   */
  function ERC721Token(string _name, string _symbol) public {
    name_ = _name;
    symbol_ = _symbol;
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
   * @dev Returns an URI for a given token ID
   * @dev Throws if the token ID does not exist. May return an empty string.
   * @param _tokenId uint256 ID of the token to query
   */
  function tokenURI(uint256 _tokenId) public view returns (string) {
    require(exists(_tokenId));
    return tokenURIs[_tokenId];
  }

  /**
   * @dev Gets the token ID at a given index of the tokens list of the requested owner
   * @param _owner address owning the tokens list to be accessed
   * @param _index uint256 representing the index to be accessed of the requested tokens list
   * @return uint256 token ID at the given index of the tokens list owned by the requested address
   */
  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
    require(_index < balanceOf(_owner));
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
    require(_index < totalSupply());
    return allTokens[_index];
  }

  /**
   * @dev Internal function to set the token URI for a given token
   * @dev Reverts if the token ID does not exist
   * @param _tokenId uint256 ID of the token to set its URI
   * @param _uri string URI to assign
   */
  function _setTokenURI(uint256 _tokenId, string _uri) internal {
    require(exists(_tokenId));
    tokenURIs[_tokenId] = _uri;
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

    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    ownedTokens[_from][tokenIndex] = lastToken;
    ownedTokens[_from][lastTokenIndex] = 0;
    // Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are going to
    // be zero. Then we can make sure that we will remove _tokenId from the ownedTokens list since we are first swapping
    // the lastToken to the first position, and then dropping the element placed in the last position of the list

    ownedTokens[_from].length--;
    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
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

    // Clear metadata (if any)
    if (bytes(tokenURIs[_tokenId]).length != 0) {
      delete tokenURIs[_tokenId];
    }

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

}

// File: contracts\Integers.sol

/**
 * Integers Library
 *
 * In summary this is a simple library of integer functions which allow a simple
 * conversion to and from strings
 *
 * @author James Lockhart <[email protected]>
 */
library Integers {
    /**
     * Parse Int
     *
     * Converts an ASCII string value into an uint as long as the string
     * its self is a valid unsigned integer
     *
     * @param _value The ASCII string to be converted to an unsigned integer
     * @return uint The unsigned value of the ASCII string
     */
    function parseInt(string _value)
        public
        returns (uint _ret) {
        bytes memory _bytesValue = bytes(_value);
        uint j = 1;
        for(uint i = _bytesValue.length-1; i >= 0 && i < _bytesValue.length; i--) {
            assert(_bytesValue[i] >= 48 && _bytesValue[i] <= 57);
            _ret += (uint(_bytesValue[i]) - 48)*j;
            j*=10;
        }
    }

    /**
     * To String
     *
     * Converts an unsigned integer to the ASCII string equivalent value
     *
     * @param _base The unsigned integer to be converted to a string
     * @return string The resulting ASCII string value
     */
    function toString(uint _base)
        internal
        returns (string) {

        if  (_base==0){
            return "0";
        }

        bytes memory _tmp = new bytes(32);
        uint i;
        for(i = 0;_base > 0;i++) {
            _tmp[i] = byte((_base % 10) + 48);
            _base /= 10;
        }
        bytes memory _real = new bytes(i--);
        for(uint j = 0; j < _real.length; j++) {
            _real[j] = _tmp[i--];
        }
        return string(_real);
    }

    /**
     * To Byte
     *
     * Convert an 8 bit unsigned integer to a byte
     *
     * @param _base The 8 bit unsigned integer
     * @return byte The byte equivalent
     */
    function toByte(uint8 _base)
        public
        returns (byte _ret) {
        assembly {
            let m_alloc := add(msize(),0x1)
            mstore8(m_alloc, _base)
            _ret := mload(m_alloc)
        }
    }

    /**
     * To Bytes
     *
     * Converts an unsigned integer to bytes
     *
     * @param _base The integer to be converted to bytes
     * @return bytes The bytes equivalent
     */
    function toBytes(uint _base)
        internal
        returns (bytes _ret) {
        assembly {
            let m_alloc := add(msize(),0x1)
            _ret := mload(m_alloc)
            mstore(_ret, 0x20)
            mstore(add(_ret, 0x20), _base)
        }
    }
}

// File: contracts\Strings.sol

/**
 * Strings Library
 *
 * In summary this is a simple library of string functions which make simple
 * string operations less tedious in solidity.
 *
 * Please be aware these functions can be quite gas heavy so use them only when
 * necessary not to clog the blockchain with expensive transactions.
 *
 * @author James Lockhart <[email protected]>
 */
library Strings {

    /**
     * Concat (High gas cost)
     *
     * Appends two strings together and returns a new value
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string which will be the concatenated
     *              prefix
     * @param _value The value to be the concatenated suffix
     * @return string The resulting string from combinging the base and value
     */
    function concat(string _base, string _value)
        internal
        returns (string) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length > 0);

        string memory _tmpValue = new string(_baseBytes.length +
            _valueBytes.length);
        bytes memory _newValue = bytes(_tmpValue);

        uint i;
        uint j;

        for(i = 0; i < _baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for(i = 0; i<_valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i];
        }

        return string(_newValue);
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function indexOf(string _base, string _value)
        internal
        returns (int) {
        return _indexOf(_base, _value, 0);
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string starting
     * from a defined offset
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @param _offset The starting point to start searching from which can start
     *                from 0, but must not exceed the length of the string
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function _indexOf(string _base, string _value, uint _offset)
        internal
        returns (int) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length == 1);

        for(uint i = _offset; i < _baseBytes.length; i++) {
            if (_baseBytes[i] == _valueBytes[0]) {
                return int(i);
            }
        }

        return -1;
    }

    /**
     * Length
     *
     * Returns the length of the specified string
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string to be measured
     * @return uint The length of the passed string
     */
    function length(string _base)
        internal
        returns (uint) {
        bytes memory _baseBytes = bytes(_base);
        return _baseBytes.length;
    }

    /**
     * Sub String
     *
     * Extracts the beginning part of a string based on the desired length
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string that will be used for
     *              extracting the sub string from
     * @param _length The length of the sub string to be extracted from the base
     * @return string The extracted sub string
     */
    function substring(string _base, int _length)
        internal
        returns (string) {
        return _substring(_base, _length, 0);
    }

    /**
     * Sub String
     *
     * Extracts the part of a string based on the desired length and offset. The
     * offset and length must not exceed the lenth of the base string.
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string that will be used for
     *              extracting the sub string from
     * @param _length The length of the sub string to be extracted from the base
     * @param _offset The starting point to extract the sub string from
     * @return string The extracted sub string
     */
    function _substring(string _base, int _length, int _offset)
        internal
        returns (string) {
        bytes memory _baseBytes = bytes(_base);

        assert(uint(_offset+_length) <= _baseBytes.length);

        string memory _tmp = new string(uint(_length));
        bytes memory _tmpBytes = bytes(_tmp);

        uint j = 0;
        for(uint i = uint(_offset); i < uint(_offset+_length); i++) {
          _tmpBytes[j++] = _baseBytes[i];
        }

        return string(_tmpBytes);
    }

    /**
     * String Split (Very high gas cost)
     *
     * Splits a string into an array of strings based off the delimiter value.
     * Please note this can be quite a gas expensive function due to the use of
     * storage so only use if really required.
     *
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string value to be split.
     * @param _value The delimiter to split the string on which must be a single
     *               character
     * @return string[] An array of values split based off the delimiter, but
     *                  do not container the delimiter.
     */
    function split(string _base, string _value)
        internal
        returns (string[] storage splitArr) {
        bytes memory _baseBytes = bytes(_base);
        uint _offset = 0;

        while(_offset < _baseBytes.length-1) {

            int _limit = _indexOf(_base, _value, _offset);
            if (_limit == -1) {
                _limit = int(_baseBytes.length);
            }

            string memory _tmp = new string(uint(_limit)-_offset);
            bytes memory _tmpBytes = bytes(_tmp);

            uint j = 0;
            for(uint i = _offset; i < uint(_limit); i++) {
                _tmpBytes[j++] = _baseBytes[i];
            }
            _offset = uint(_limit) + 1;
            splitArr.push(string(_tmpBytes));
        }
        return splitArr;
    }

    /**
     * Compare To
     *
     * Compares the characters of two strings, to ensure that they have an
     * identical footprint
     *
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string base to compare against
     * @param _value The string the base is being compared to
     * @return bool Simply notates if the two string have an equivalent
     */
    function compareTo(string _base, string _value)
        internal
        returns (bool) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        if (_baseBytes.length != _valueBytes.length) {
            return false;
        }

        for(uint i = 0; i < _baseBytes.length; i++) {
            if (_baseBytes[i] != _valueBytes[i]) {
                return false;
            }
        }

        return true;
    }

    /**
     * Compare To Ignore Case (High gas cost)
     *
     * Compares the characters of two strings, converting them to the same case
     * where applicable to alphabetic characters to distinguish if the values
     * match.
     *
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string base to compare against
     * @param _value The string the base is being compared to
     * @return bool Simply notates if the two string have an equivalent value
     *              discarding case
     */
    function compareToIgnoreCase(string _base, string _value)
        internal
        returns (bool) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        if (_baseBytes.length != _valueBytes.length) {
            return false;
        }

        for(uint i = 0; i < _baseBytes.length; i++) {
            if (_baseBytes[i] != _valueBytes[i] &&
                _upper(_baseBytes[i]) != _upper(_valueBytes[i])) {
                return false;
            }
        }

        return true;
    }

    /**
     * Upper
     *
     * Converts all the values of a string to their corresponding upper case
     * value.
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to upper case
     * @return string
     */
    function upper(string _base)
        internal
        returns (string) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _upper(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Lower
     *
     * Converts all the values of a string to their corresponding lower case
     * value.
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to lower case
     * @return string
     */
    function lower(string _base)
        internal
        returns (string) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _lower(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Upper
     *
     * Convert an alphabetic character to upper case and return the original
     * value when not alphabetic
     *
     * @param _b1 The byte to be converted to upper case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a lower case otherwise returns the original value
     */
    function _upper(bytes1 _b1)
        private
        constant
        returns (bytes1) {

        if (_b1 >= 0x61 && _b1 <= 0x7A) {
            return bytes1(uint8(_b1)-32);
        }

        return _b1;
    }

    /**
     * Lower
     *
     * Convert an alphabetic character to lower case and return the original
     * value when not alphabetic
     *
     * @param _b1 The byte to be converted to lower case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a upper case otherwise returns the original value
     */
    function _lower(bytes1 _b1)
        private
        constant
        returns (bytes1) {

        if (_b1 >= 0x41 && _b1 <= 0x5A) {
            return bytes1(uint8(_b1)+32);
        }

        return _b1;
    }
}

pragma solidity ^0.4.24 ;

interface IERC20 {
    function mint(address _to, uint256 _amount) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function getTotalSupply() external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract NFT is Ownable, ERC721Token, ERC721Holder {
    using Strings for string;
    using Integers for uint;

    function NFT () ERC721Token("NFT" ,"NFT") public {

    }

    struct DigitalNFT {
        string ipfsHash;
        address publisher;
        string name;
        string description;
    }

    uint256 maxTotalSupply = 20000000000000000000000;
    bool public mintEnable = false;
    
    IERC20 public addressBargainToken;
    IERC20 public addressLP;

    uint128 public feeToOwner = 3;
    uint128 public percentMintBargainToken = 1;
    uint256 public amountMintBargainToken = 10000000000000000;

    mapping (address => uint) public depositedTokens;

    DigitalNFT[] public digitalNFTs;
    mapping (string => uint256) ipfsHashToTokenId;

    mapping (address => uint256) internal publishedTokensCount;
    mapping (address => uint256[]) internal publishedTokens;

    mapping(address => mapping (uint256 => uint256)) internal publishedTokensIndex;

    struct SellingItem {
        address seller;
        uint256 price;
        string ipfsHash;
        string name;
        string description;
    }

    mapping (uint256 => SellingItem) public tokenIdToSellingItem;

    uint128 public createNFTFee = 0.08 ether;
    uint128 public createNFTWithLPFee = 0.0008 ether;
    
    uint128 public publisherCut = 100; 

    /*** Modifier ***/
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /*** Owner Action ***/
    function withdraw() public onlyOwner {
        owner.transfer(this.balance);
    }

    function setMintEnable(bool _value) public onlyOwner {
        mintEnable = _value;
    }

    function setCreateNFTFee(uint128 _fee) public onlyOwner {
        createNFTFee = _fee;
    }

    function setCreateNFTWithLPFee(uint128 _fee) public onlyOwner {
        createNFTWithLPFee = _fee;
    }

    function setTokenLP(address _address) public onlyOwner {
        addressLP = IERC20(_address);
    }

    function setBargainToken(address _address) public onlyOwner {
        addressBargainToken = IERC20(_address);
    }

    function setAmountMint(uint256 _amount) public onlyOwner {
        amountMintBargainToken = _amount;
    }

    function setPublisherCut(uint128 _cut) public onlyOwner {
        require(_cut > 0 && _cut < 10000);
        publisherCut = _cut;
    }

    function getIpfsHashToTokenId(string _string) public view returns (uint256){
        return ipfsHashToTokenId[_string];
    }

    function getOwnedTokens(address _owner) public view returns (uint256[]) {
        return ownedTokens[_owner];
    }

    function getAllTokens() public view returns (uint256[]) {
        return allTokens;
    }

    function getBalance() public view returns (uint256) {
        return this.balance;
    }

    function publishedCountOf(address _publisher) public view returns (uint256) {
        return publishedTokensCount[_publisher];
    }

    function publishedTokenOfOwnerByIndex(address _publisher, uint256 _index) public view returns (uint256) {
        require(_index < publishedCountOf(_publisher));
        return publishedTokens[_publisher][_index];
    }

    function getPublishedTokens(address _publisher) public view returns (uint256[]) {
        return publishedTokens[_publisher];
    }

    function mintNFT(string _ipfsHash, string _name, string _description, uint _copies) public payable {
        require(msg.value == createNFTFee);
        require(ipfsHashToTokenId[_ipfsHash] == 0);
        
        if(_copies == 0){
          _copies = 1;
        }

        if(mintEnable){
          if(addressBargainToken.getTotalSupply() <= maxTotalSupply){
              require(addressBargainToken.mint(msg.sender, amountMintBargainToken));
          }
        }

        for(uint i = 0; i < _copies; i++){
          DigitalNFT memory _digitalNFT = DigitalNFT({
              ipfsHash: _ipfsHash, 
              publisher: msg.sender, 
              name: _name, 
              description: _description
          });

          uint256 newDigitalNFTId = digitalNFTs.push(_digitalNFT) - 1;
          ipfsHashToTokenId[_ipfsHash] = newDigitalNFTId;
          _mint(msg.sender, newDigitalNFTId);

          publishedTokensCount[msg.sender]++;
          uint256 length = publishedTokens[msg.sender].length;
          publishedTokens[msg.sender].push(newDigitalNFTId);
          publishedTokensIndex[msg.sender][newDigitalNFTId] = length;
        }
        
    }

    function mintNFTWithLP(uint256 createFee, string _ipfsHash, string _name, string _description, uint _copies) public {
        require(createFee > 0, "Cannot deposit 0 Tokens");
        require(createFee == createNFTWithLPFee);
        require(ipfsHashToTokenId[_ipfsHash] == 0);
        require(addressLP.transferFrom(msg.sender, address(this), createFee), "Insufficient Token Allowance");
        
        if(_copies == 0){
          _copies = 1;
        }

        if(mintEnable){
          if(addressBargainToken.getTotalSupply() <= maxTotalSupply){
            require(addressBargainToken.mint(msg.sender, amountMintBargainToken));
          }
        }

        depositedTokens[msg.sender] = depositedTokens[msg.sender].add(createNFTWithLPFee);

        for(uint i = 0; i < _copies; i++){
          DigitalNFT memory _digitalNFT = DigitalNFT({
              ipfsHash: _ipfsHash, 
              publisher: msg.sender, 
              name: _name, 
              description: _description
          });

          uint256 newDigitalNFTId = digitalNFTs.push(_digitalNFT) - 1;
          ipfsHashToTokenId[_ipfsHash] = newDigitalNFTId;
          _mint(msg.sender, newDigitalNFTId);

          publishedTokensCount[msg.sender]++;
          uint256 length = publishedTokens[msg.sender].length;
          publishedTokens[msg.sender].push(newDigitalNFTId);
          publishedTokensIndex[msg.sender][newDigitalNFTId] = length;
        }    
    }

    function addNFTSellingItem(uint256 _tokenId, uint256 _price) public onlyOwnerOf(_tokenId) {
        require(tokenIdToSellingItem[_tokenId].seller == address(0));
        SellingItem memory _sellingItem = SellingItem(
            msg.sender, 
            uint256(_price), 
            digitalNFTs[_tokenId].ipfsHash, 
            digitalNFTs[_tokenId].name, 
            digitalNFTs[_tokenId].description
        );
        tokenIdToSellingItem[_tokenId] = _sellingItem;
        approve(address(this), _tokenId);
        safeTransferFrom(msg.sender, address(this), _tokenId);
    }

    function cancelNFTSellingItem(uint256 _tokenId) public {
        require(tokenIdToSellingItem[_tokenId].seller == msg.sender);
        this.safeTransferFrom(address(this), tokenIdToSellingItem[_tokenId].seller, _tokenId);
        delete tokenIdToSellingItem[_tokenId];
    }

    function purchaseNFTSellingItem(uint256 _tokenId) public payable {
        uint256 priceItemEther = tokenIdToSellingItem[_tokenId].price;
        address sellerAddress = tokenIdToSellingItem[_tokenId].seller;

        require(sellerAddress != address(0));
        require(sellerAddress != msg.sender);
        require(priceItemEther == msg.value);

        if(mintEnable){
          if(addressBargainToken.getTotalSupply() <= maxTotalSupply){ 
              require(addressBargainToken.mint(msg.sender, _computeAmountMintToken(priceItemEther)));
          }
        }
        uint256 feeToOwnerItem = priceItemEther.mul(feeToOwner).div(100);
        uint256 priceItemEtherFee = priceItemEther.sub(feeToOwnerItem);

        sellerAddress.transfer(priceItemEtherFee);

        SellingItem memory sellingItem = tokenIdToSellingItem[_tokenId];

        if (sellingItem.price > 0) {
            uint256 actualPublisherCut = _computePublisherCut(sellingItem.price);
            digitalNFTs[_tokenId].publisher.transfer(actualPublisherCut);
        }

        if(depositedTokens[sellerAddress] > 0){
          require(addressLP.transfer(sellerAddress, createNFTWithLPFee), "Could not transfer tokens.");
          depositedTokens[sellerAddress] = depositedTokens[sellerAddress].sub(createNFTWithLPFee);
        }

        delete tokenIdToSellingItem[_tokenId];
        this.safeTransferFrom(address(this), msg.sender, _tokenId);
    }

    /*** Tools ***/
    function _computePublisherCut(uint256 _price) internal view returns (uint256) {
        return _price.mul(publisherCut).div(10000);
    }

    function _computeAmountMintToken(uint256 _amount) internal view returns (uint256) {
        return _amount.mul(percentMintBargainToken).div(100);
    }

}