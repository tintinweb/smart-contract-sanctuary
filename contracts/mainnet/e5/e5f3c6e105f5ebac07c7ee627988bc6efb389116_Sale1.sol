pragma solidity 0.4.24;

// ERC20 Token with ERC223 Token compatibility
// SafeMath from OpenZeppelin Standard
// Added burn functions from Ethereum Token 
// - https://theethereum.wiki/w/index.php/ERC20_Token_Standard
// - https://github.com/Dexaran/ERC23-tokens/blob/Recommended/ERC223_Token.sol
// - https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol
// - https://www.ethereum.org/token (uncontrolled, non-standard)


// ERC223
interface ContractReceiver {
  function tokenFallback( address from, uint value, bytes data ) external;
}

// SafeMath
contract SafeMath2 {

    function safeSub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }
    
    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
}
}


contract RUNEToken is SafeMath2
{
    
    // Rune Characteristics
    string  public name = "Rune";
    string  public symbol  = "RUNE";
    uint256   public decimals  = 18;
    uint256 public totalSupply  = 1000000000 * (10 ** decimals);

    // Mapping
    mapping( address => uint256 ) balances_;
    mapping( address => mapping(address => uint256) ) allowances_;
    
    // Minting event
    function RUNEToken() public {
            balances_[msg.sender] = totalSupply;
                emit Transfer( address(0), msg.sender, totalSupply );
        }

    function() public payable { revert(); } // does not accept money
    
    // ERC20
    event Approval( address indexed owner,
                    address indexed spender,
                    uint value );

    event Transfer( address indexed from,
                    address indexed to,
                    uint256 value );


    // ERC20
    function balanceOf( address owner ) public constant returns (uint) {
        return balances_[owner];
    }

    // ERC20
    function approve( address spender, uint256 value ) public
    returns (bool success)
    {
        allowances_[msg.sender][spender] = value;
        emit Approval( msg.sender, spender, value );
        return true;
    }
    
    // recommended fix for known attack on any ERC20
    function safeApprove( address _spender,
                            uint256 _currentValue,
                            uint256 _value ) public
                            returns (bool success) {

        // If current allowance for _spender is equal to _currentValue, then
        // overwrite it with _value and return true, otherwise return false.

        if (allowances_[msg.sender][_spender] == _currentValue)
        return approve(_spender, _value);

        return false;
    }

    // ERC20
    function allowance( address owner, address spender ) public constant
    returns (uint256 remaining)
    {
        return allowances_[owner][spender];
    }

    // ERC20
    function transfer(address to, uint256 value) public returns (bool success)
    {
        bytes memory empty; // null
        _transfer( msg.sender, to, value, empty );
        return true;
    }

    // ERC20
    function transferFrom( address from, address to, uint256 value ) public
    returns (bool success)
    {
        require( value <= allowances_[from][msg.sender] );

        allowances_[from][msg.sender] -= value;
        bytes memory empty;
        _transfer( from, to, value, empty );

        return true;
    }

    // ERC223 Transfer and invoke specified callback
    function transfer( address to,
                        uint value,
                        bytes data,
                        string custom_fallback ) public returns (bool success)
    {
        _transfer( msg.sender, to, value, data );

        if ( isContract(to) )
        {
        ContractReceiver rx = ContractReceiver( to );
        require( address(rx).call.value(0)(bytes4(keccak256(custom_fallback)),
                msg.sender,
                value,
                data) );
        }

        return true;
    }

    // ERC223 Transfer to a contract or externally-owned account
    function transfer( address to, uint value, bytes data ) public
    returns (bool success)
    {
        if (isContract(to)) {
        return transferToContract( to, value, data );
        }

        _transfer( msg.sender, to, value, data );
        return true;
    }

    // ERC223 Transfer to contract and invoke tokenFallback() method
    function transferToContract( address to, uint value, bytes data ) private
    returns (bool success)
    {
        _transfer( msg.sender, to, value, data );

        ContractReceiver rx = ContractReceiver(to);
        rx.tokenFallback( msg.sender, value, data );

        return true;
    }

    // ERC223 fetch contract size (must be nonzero to be a contract)
    function isContract( address _addr ) private constant returns (bool)
    {
        uint length;
        assembly { length := extcodesize(_addr) }
        return (length > 0);
    }

    function _transfer( address from,
                        address to,
                        uint value,
                        bytes data ) internal
    {
        require( to != 0x0 );
        require( balances_[from] >= value );
        require( balances_[to] + value > balances_[to] ); // catch overflow

        balances_[from] -= value;
        balances_[to] += value;

        //Transfer( from, to, value, data ); ERC223-compat version
        bytes memory empty;
        empty = data;
        emit Transfer( from, to, value ); // ERC20-compat version
    }
    
    
        // Ethereum Token
    event Burn( address indexed from, uint256 value );
    
        // Ethereum Token
    function burn( uint256 value ) public
    returns (bool success)
    {
        require( balances_[msg.sender] >= value );
        balances_[msg.sender] -= value;
        totalSupply -= value;

        emit Burn( msg.sender, value );
        return true;
    }

    // Ethereum Token
    function burnFrom( address from, uint256 value ) public
    returns (bool success)
    {
        require( balances_[from] >= value );
        require( value <= allowances_[from][msg.sender] );

        balances_[from] -= value;
        allowances_[from][msg.sender] -= value;
        totalSupply -= value;

        emit Burn( from, value );
        return true;
    }
  
  
}




/**
 * @title ERC165
 * @dev https://github.com/ethereum/EIPs/blob/master/EIPS/eip-165.md
 */
interface ERC165 {

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceId The interface identifier, as specified in ERC-165
   * @dev Interface identification is specified in ERC-165. This function
   * uses less than 30,000 gas.
   */
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}



/**
 * @title SupportsInterfaceWithLookup
 * @author Matt Condon (@shrugs)
 * @dev Implements ERC165 using a lookup table.
 */
contract SupportsInterfaceWithLookup is ERC165 {

  bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;
  /**
   * 0x01ffc9a7 ===
   *   bytes4(keccak256(&#39;supportsInterface(bytes4)&#39;))
   */

  /**
   * @dev a mapping of interface id to whether or not it&#39;s supported
   */
  mapping(bytes4 => bool) internal supportedInterfaces;

  /**
   * @dev A contract implementing SupportsInterfaceWithLookup
   * implement ERC165 itself
   */
  constructor()
    public
  {
    _registerInterface(InterfaceId_ERC165);
  }

  /**
   * @dev implement supportsInterface(bytes4) using a lookup table
   */
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceId];
  }

  /**
   * @dev private method for registering an interface
   */
  function _registerInterface(bytes4 _interfaceId)
    internal
  {
    require(_interfaceId != 0xffffffff);
    supportedInterfaces[_interfaceId] = true;
  }
}


/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Basic is ERC165 {

  bytes4 internal constant InterfaceId_ERC721 = 0x80ac58cd;
  /*
   * 0x80ac58cd ===
   *   bytes4(keccak256(&#39;balanceOf(address)&#39;)) ^
   *   bytes4(keccak256(&#39;ownerOf(uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;approve(address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;getApproved(uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;setApprovalForAll(address,bool)&#39;)) ^
   *   bytes4(keccak256(&#39;isApprovedForAll(address,address)&#39;)) ^
   *   bytes4(keccak256(&#39;transferFrom(address,address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;safeTransferFrom(address,address,uint256,bytes)&#39;))
   */

  bytes4 internal constant InterfaceId_ERC721Enumerable = 0x780e9d63;
  /**
   * 0x780e9d63 ===
   *   bytes4(keccak256(&#39;totalSupply()&#39;)) ^
   *   bytes4(keccak256(&#39;tokenOfOwnerByIndex(address,uint256)&#39;)) ^
   *   bytes4(keccak256(&#39;tokenByIndex(uint256)&#39;))
   */

  bytes4 internal constant InterfaceId_ERC721Metadata = 0x5b5e139f;
  /**
   * 0x5b5e139f ===
   *   bytes4(keccak256(&#39;name()&#39;)) ^
   *   bytes4(keccak256(&#39;symbol()&#39;)) ^
   *   bytes4(keccak256(&#39;tokenURI(uint256)&#39;))
   */

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

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId)
    public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator)
    public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId)
    public;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}



contract THORChain721Receiver {
  /**
   * @dev Magic value to be returned upon successful reception of an NFT
   *  Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`,
   *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
   */
  bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

  bytes4 retval;
  bool reverts;

  constructor(bytes4 _retval, bool _reverts) public {
    retval = _retval;
    reverts = _reverts;
  }

  event Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes _data,
    uint256 _gas
  );

  function onERC721Received(
    address _operator,
    address _from,
    uint256 _tokenId,
    bytes _data
  )
    public
    returns(bytes4)
  {
    require(!reverts);
    emit Received(
      _operator,
      _from,
      _tokenId,
      _data,
      gasleft()
    );
    return retval;
  }
}



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

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


/**
 * Utility library of inline functions on addresses
 */
library AddressUtils {

  /**
   * Returns whether the target address is a contract
   * @dev This function will return false if invoked during the constructor of a contract,
   * as the code is not actually created until after the constructor finishes.
   * @param _account address of the account to check
   * @return whether the target address is a contract
   */
  function isContract(address _account) internal view returns (bool) {
    uint256 size;
    // XXX Currently there is no better way to check if there is a contract in an address
    // than to check the size of the code at that address.
    // See https://ethereum.stackexchange.com/a/14016/36603
    // for more details about how this works.
    // TODO Check this again before the Serenity release, because all addresses will be
    // contracts then.
    // solium-disable-next-line security/no-inline-assembly
    assembly { size := extcodesize(_account) }
    return size > 0;
  }

}


/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721BasicToken is SupportsInterfaceWithLookup, ERC721Basic {

  using SafeMath for uint256;
  using AddressUtils for address;

  // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
  bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

  // Mapping from token ID to owner
  mapping (uint256 => address) internal tokenOwner;

  // Mapping from token ID to approved address
  mapping (uint256 => address) internal tokenApprovals;

  // Mapping from owner to number of owned token
  mapping (address => uint256) internal ownedTokensCount;

  // Mapping from owner to operator approvals
  mapping (address => mapping (address => bool)) internal operatorApprovals;

  constructor()
    public
  {
    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(InterfaceId_ERC721);
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
   * @dev Approves another address to transfer the given token ID
   * The zero address indicates there is no approved address.
   * There can only be one approved address per token at a given time.
   * Can only be called by the token owner or an approved operator.
   * @param _to address to be approved for the given token ID
   * @param _tokenId uint256 ID of the token to be approved
   */
  function approve(address _to, uint256 _tokenId) public {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

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
   * An operator is allowed to transfer all tokens of the sender on their behalf
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
   * Usage of this method is discouraged, use `safeTransferFrom` whenever possible
   * Requires the msg sender to be the owner, approved, or operator
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
  {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    require(_to != address(0));

    clearApproval(_from, _tokenId);
    removeTokenFrom(_from, _tokenId);
    addTokenTo(_to, _tokenId);

    emit Transfer(_from, _to, _tokenId);
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   *
   * Requires the msg sender to be the owner, approved, or operator
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
  {
    // solium-disable-next-line arg-overflow
    safeTransferFrom(_from, _to, _tokenId, "");
  }

  /**
   * @dev Safely transfers the ownership of a given token ID to another address
   * If the target address is a contract, it must implement `onERC721Received`,
   * which is called upon a safe transfer, and return the magic value
   * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
   * the transfer is reverted.
   * Requires the msg sender to be the owner, approved, or operator
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
  {
    transferFrom(_from, _to, _tokenId);
    // solium-disable-next-line arg-overflow
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

  /**
   * @dev Returns whether the specified token exists
   * @param _tokenId uint256 ID of the token to query the existence of
   * @return whether the token exists
   */
  function _exists(uint256 _tokenId) internal view returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
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
   * Reverts if the given token ID already exists
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
   * Reverts if the token does not exist
   * @param _tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address _owner, uint256 _tokenId) internal {
    clearApproval(_owner, _tokenId);
    removeTokenFrom(_owner, _tokenId);
    emit Transfer(_owner, address(0), _tokenId);
  }

  /**
   * @dev Internal function to clear current approval of a given token ID
   * Reverts if the given address is not indeed the owner of the token
   * @param _owner owner of the token
   * @param _tokenId uint256 ID of the token to be transferred
   */
  function clearApproval(address _owner, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _owner);
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
   * The call is not executed if the target address is not a contract
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
    bytes4 retval = THORChain721Receiver(_to).onERC721Received(
      msg.sender, _from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
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
  function name() external view returns (string _name);
  function symbol() external view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


/**
 * @title ERC-721 Non-Fungible Token Standard, full implementation interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}




/**
 * @title Full ERC721 Token
 * This implementation includes all the required and some optional functionality of the ERC721 standard
 * Moreover, it includes approve all functionality using operator terminology
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721Token is SupportsInterfaceWithLookup, ERC721BasicToken, ERC721 {

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

  // Optional mapping for token URIs
  mapping(uint256 => string) internal tokenURIs;

  /**
   * @dev Constructor function
   */
  constructor(string _name, string _symbol) public {
    name_ = _name;
    symbol_ = _symbol;

    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(InterfaceId_ERC721Enumerable);
    _registerInterface(InterfaceId_ERC721Metadata);
  }

  /**
   * @dev Gets the token name
   * @return string representing the token name
   */
  function name() external view returns (string) {
    return name_;
  }

  /**
   * @dev Gets the token symbol
   * @return string representing the token symbol
   */
  function symbol() external view returns (string) {
    return symbol_;
  }

  /**
   * @dev Returns an URI for a given token ID
   * Throws if the token ID does not exist. May return an empty string.
   * @param _tokenId uint256 ID of the token to query
   */
  function tokenURI(uint256 _tokenId) public view returns (string) {
    require(_exists(_tokenId));
    return tokenURIs[_tokenId];
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
   * Reverts if the index is greater or equal to the total number of tokens
   * @param _index uint256 representing the index to be accessed of the tokens list
   * @return uint256 token ID at the given index of the tokens list
   */
  function tokenByIndex(uint256 _index) public view returns (uint256) {
    require(_index < totalSupply());
    return allTokens[_index];
  }

  /**
   * @dev Internal function to set the token URI for a given token
   * Reverts if the token ID does not exist
   * @param _tokenId uint256 ID of the token to set its URI
   * @param _uri string URI to assign
   */
  function _setTokenURI(uint256 _tokenId, string _uri) internal {
    require(_exists(_tokenId));
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
   * @dev Internal function to mint a new token
   * Reverts if the given token ID already exists
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
   * Reverts if the token does not exist
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

contract THORChain721 is ERC721Token {
    
    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor () public ERC721Token("testTC1", "testTC1") {
        owner = msg.sender;
    }

    // Revert any transaction to this contract.
    function() public payable { 
        revert(); 
    }
    
    function mint(address _to, uint256 _tokenId) public onlyOwner {
        super._mint(_to, _tokenId);
    }

    function burn(uint256 _tokenId) public onlyOwner {
        super._burn(ownerOf(_tokenId), _tokenId);
    }

    function setTokenURI(uint256 _tokenId, string _uri) public onlyOwner {
        super._setTokenURI(_tokenId, _uri);
    }

    function _removeTokenFrom(address _from, uint256 _tokenId) public {
        super.removeTokenFrom(_from, _tokenId);
    }
}

contract Whitelist {

    address public owner;
    mapping(address => bool) public whitelistAdmins;
    mapping(address => bool) public whitelist;

    constructor () public {
        owner = msg.sender;
        whitelistAdmins[owner] = true;
    }

    modifier onlyOwner () {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyWhitelistAdmin () {
        require(whitelistAdmins[msg.sender], "Only whitelist admin");
        _;
    }

    function isWhitelisted(address _addr) public view returns (bool) {
        return whitelist[_addr];
    }

    function addWhitelistAdmin(address _admin) public onlyOwner {
        whitelistAdmins[_admin] = true;
    }

    function removeWhitelistAdmin(address _admin) public onlyOwner {
        require(_admin != owner, "Cannot remove contract owner");
        whitelistAdmins[_admin] = false;
    }

    function whitelistAddress(address _user) public onlyWhitelistAdmin  {
        whitelist[_user] = true;
    }

    function whitelistAddresses(address[] _users) public onlyWhitelistAdmin {
        for (uint256 i = 0; i < _users.length; i++) {
            whitelist[_users[i]] = true;
        }
    }

    function unWhitelistAddress(address _user) public onlyWhitelistAdmin  {
        whitelist[_user] = false;
    }

    function unWhitelistAddresses(address[] _users) public onlyWhitelistAdmin {
        for (uint256 i = 0; i < _users.length; i++) {
            whitelist[_users[i]] = false;
        }
    }

}

contract Sale1 is Whitelist {
    
    using SafeMath for uint256;

    uint256 public maximumNonWhitelistAmount = 12500 * 50 ether; // in minimum units of rune

    // in minimum units of rune (1000 = 0.000000000000001000 RUNE per WEI)
    // note that this only works if the amount of rune per wei is more than 1
    uint256 public runeToWeiRatio = 12500;
    bool public withdrawalsAllowed = false;
    bool public tokensWithdrawn = false;
    address public owner;
    address public proceedsAddress = 0xd46cac034f44ac93049f8f1109b6b74f79b3e5e6;
    RUNEToken public RuneToken = RUNEToken(0xdEE02D94be4929d26f67B64Ada7aCf1914007F10);
    Whitelist public WhitelistContract = Whitelist(0x395Eb47d46F7fFa7Dd4b27e1B64FC6F21d5CC4C7);
    THORChain721 public ERC721Token = THORChain721(0x953d066d809dc71b8809dafb8fb55b01bc23a6e0);

    uint256 public CollectibleIndex0 = 0;
    uint256 public CollectibleIndex1 = 1;
    uint256 public CollectibleIndex2 = 2;
    uint256 public CollectibleIndex3 = 3;
    uint256 public CollectibleIndex4 = 4;
    uint256 public CollectibleIndex5 = 5;

    uint public winAmount0 = 666.666666666666666667 ether;
    uint public winAmount1 = 1333.333333333333333333 ether;
    uint public winAmount2 = 2000.0 ether;
    uint public winAmount3 = 2666.666666666666666667 ether;
    uint public winAmount4 = 3333.333333333333333333 ether;
    uint public winAmount5 = 4000.0 ether;

    mapping (uint256 => address) public collectibleAllocation;
    mapping (address => uint256) public runeAllocation;

    uint256 public totalRunePurchased;
    uint256 public totalRuneWithdrawn;

    event TokenWon(uint256 tokenId, address winner);

    modifier onlyOwner () {
        require(owner == msg.sender, "Only the owner can use this function");
        _;
    }

    constructor () public {
        owner = msg.sender;
    }

    function () public payable {
        require(!tokensWithdrawn, "Tokens withdrawn. No more purchases possible.");
        // Make sure we have enough tokens to sell
        uint runeRemaining = (RuneToken.balanceOf(this).add(totalRuneWithdrawn)).sub(totalRunePurchased);
        uint toForward = msg.value;
        uint weiToReturn = 0;
        uint purchaseAmount = msg.value * runeToWeiRatio;
        if(runeRemaining < purchaseAmount) {
            purchaseAmount = runeRemaining;
            uint price = purchaseAmount.div(runeToWeiRatio);
            weiToReturn = msg.value.sub(price);
            toForward = toForward.sub(weiToReturn);
        }

        // Assign NFTs
        uint ethBefore = totalRunePurchased.div(runeToWeiRatio);
        uint ethAfter = ethBefore.add(toForward);

        if(ethBefore <= winAmount0 && ethAfter > winAmount0) {
            collectibleAllocation[CollectibleIndex0] = msg.sender;
            emit TokenWon(CollectibleIndex0, msg.sender);
        } if(ethBefore < winAmount1 && ethAfter >= winAmount1) {
            collectibleAllocation[CollectibleIndex1] = msg.sender;
            emit TokenWon(CollectibleIndex1, msg.sender);
        } if(ethBefore < winAmount2 && ethAfter >= winAmount2) {
            collectibleAllocation[CollectibleIndex2] = msg.sender;
            emit TokenWon(CollectibleIndex2, msg.sender);
        } if(ethBefore < winAmount3 && ethAfter >= winAmount3) {
            collectibleAllocation[CollectibleIndex3] = msg.sender;
            emit TokenWon(CollectibleIndex3, msg.sender);
        } if(ethBefore < winAmount4 && ethAfter >= winAmount4) {
            collectibleAllocation[CollectibleIndex4] = msg.sender;
            emit TokenWon(CollectibleIndex4, msg.sender);
        } if(ethBefore < winAmount5 && ethAfter >= winAmount5) {
            collectibleAllocation[CollectibleIndex5] = msg.sender;
            emit TokenWon(CollectibleIndex5, msg.sender);
        } 

        runeAllocation[msg.sender] = runeAllocation[msg.sender].add(purchaseAmount);
        totalRunePurchased = totalRunePurchased.add(purchaseAmount);
        // Withdraw  ETH 
        proceedsAddress.transfer(toForward);
        if(weiToReturn > 0) {
            address(msg.sender).transfer(weiToReturn);
        }
    }

    function setMaximumNonWhitelistAmount (uint256 _newAmount) public onlyOwner {
        maximumNonWhitelistAmount = _newAmount;
    }

    function withdrawRune () public {
        require(withdrawalsAllowed, "Withdrawals are not allowed.");
        uint256 runeToWithdraw;
        if (WhitelistContract.isWhitelisted(msg.sender)) {
            runeToWithdraw = runeAllocation[msg.sender];
        } else {
            runeToWithdraw = (
                runeAllocation[msg.sender] > maximumNonWhitelistAmount
            ) ? maximumNonWhitelistAmount : runeAllocation[msg.sender];
        }

        runeAllocation[msg.sender] = runeAllocation[msg.sender].sub(runeToWithdraw);
        totalRuneWithdrawn = totalRuneWithdrawn.add(runeToWithdraw);
        RuneToken.transfer(msg.sender, runeToWithdraw); // ERC20 method
        distributeCollectiblesTo(msg.sender);
    }

    function ownerWithdrawRune () public onlyOwner {
        tokensWithdrawn = true;
        RuneToken.transfer(owner, RuneToken.balanceOf(this).sub(totalRunePurchased.sub(totalRuneWithdrawn)));
    }

    function allowWithdrawals () public onlyOwner {
        withdrawalsAllowed = true;
    }

    function distributeTo (address _receiver) public onlyOwner {
        require(runeAllocation[_receiver] > 0, "Receiver has not purchased any RUNE.");
        uint balance = runeAllocation[_receiver];
        delete runeAllocation[_receiver];
        RuneToken.transfer(_receiver, balance);
        distributeCollectiblesTo(_receiver);
    }

    function distributeCollectiblesTo (address _receiver) internal {
        if(collectibleAllocation[CollectibleIndex0] == _receiver) {
            delete collectibleAllocation[CollectibleIndex0];
            ERC721Token.safeTransferFrom(owner, _receiver, CollectibleIndex0);
        } 
        if(collectibleAllocation[CollectibleIndex1] == _receiver) {
            delete collectibleAllocation[CollectibleIndex1];
            ERC721Token.safeTransferFrom(owner, _receiver, CollectibleIndex1);
        } 
        if(collectibleAllocation[CollectibleIndex2] == _receiver) {
            delete collectibleAllocation[CollectibleIndex2];
            ERC721Token.safeTransferFrom(owner, _receiver, CollectibleIndex2);
        } 
        if(collectibleAllocation[CollectibleIndex3] == _receiver) {
            delete collectibleAllocation[CollectibleIndex3];
            ERC721Token.safeTransferFrom(owner, _receiver, CollectibleIndex3);
        } 
        if(collectibleAllocation[CollectibleIndex4] == _receiver) {
            delete collectibleAllocation[CollectibleIndex4];
            ERC721Token.safeTransferFrom(owner, _receiver, CollectibleIndex4);
        } 
        if(collectibleAllocation[CollectibleIndex5] == _receiver) {
            delete collectibleAllocation[CollectibleIndex5];
            ERC721Token.safeTransferFrom(owner, _receiver, CollectibleIndex5);
        }
    }
}