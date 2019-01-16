//Have an idea for a studio? Email: admin[at]EtherPornStars.com
pragma solidity ^0.4.25;


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  function totalSupply() public view returns (uint256);

  function balanceOf(address _who) public view returns (uint256);

  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _value)
    public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
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
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) balances;

  mapping (address => mapping (address => uint256)) allowed;

  uint256 totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param _account The account that will receive the created tokens.
   * @param _amount The amount that will be created.
   */
  function _mint(address _account, uint256 _amount) internal {
    require(_account != 0);
    totalSupply_ = totalSupply_.add(_amount);
    balances[_account] = balances[_account].add(_amount);
    emit Transfer(address(0), _account, _amount);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param _account The account whose tokens will be burnt.
   * @param _amount The amount that will be burnt.
   */
  function _burn(address _account, uint256 _amount) internal {
    require(_account != 0);
    require(_amount <= balances[_account]);

    totalSupply_ = totalSupply_.sub(_amount);
    balances[_account] = balances[_account].sub(_amount);
    emit Transfer(_account, address(0), _amount);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender&#39;s allowance for said account. Uses the
   * internal _burn function.
   * @param _account The account whose tokens will be burnt.
   * @param _amount The amount that will be burnt.
   */
  function _burnFrom(address _account, uint256 _amount) internal {
    require(_amount <= allowed[_account][msg.sender]);

    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    allowed[_account][msg.sender] = allowed[_account][msg.sender].sub(_amount);
    _burn(_account, _amount);
  }
}

/**
 * @title ERC20 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 *  from ERC20 asset contracts.
 */

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */



contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}


contract StarCoin is Ownable, StandardToken {
    using SafeMath for uint;
    address gateway;
    string public name = "EtherPornStars Coin";
    string public symbol = "EPS";
    uint8 public decimals = 18;
    mapping (uint8 => address) public studioContracts;
    mapping (address => bool) public isStudio;
    event Withdrawal(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    modifier onlyStudios {
      require(isStudio[msg.sender]);
      _;
    }

    constructor () public {
  }
  /**
   * @dev Future sidechain integration for studios.
   */
    function setGateway(address _gateway) external onlyOwner {
        gateway = _gateway;
    }

    function _mintTokens(address _user, uint256 _amount) private {
        require(_user != address(0));
        balances[_user] = balances[_user].add(_amount);
        totalSupply_ = totalSupply_.add(_amount);
        emit Transfer(address(this), _user, _amount);
    }

    function rewardTokens(address _user, uint256 _tokens) external   { 
        require(isStudio[msg.sender]);
        _mintTokens(_user, _tokens);
    }
    function buyStudioStake(address _user, uint256 _tokens) external   { 
        require(isStudio[msg.sender]);
        _burn(_user, _tokens);
    }
    function transferFromStudio(
      address _from,
      address _to,
      uint256 _value
    )
      external
      returns (bool)
    {
      require(msg.sender == owner || isStudio[msg.sender]);
      require(_value <= balances[_from]);
      require(_to != address(0));
      balances[_from] = balances[_from].sub(_value);
      balances[_to] = balances[_to].add(_value);
      emit Transfer(_from, _to, _value);
      return true;
  }
     function() payable public {
        // Intentionally left empty, for use by studios
    }
    function accountAuth(uint256 /*_challenge*/) external {
        // Does nothing by design
    }

    function burn(uint256 _amount) external {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        totalSupply_ = totalSupply_.sub(_amount);
        emit Burn(msg.sender, _amount);
    }

    function withdrawBalance(uint _amount) external {
        require(balances[msg.sender] >= _amount);
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        totalSupply_ = totalSupply_.sub(_amount);
        uint ethexchange = _amount.div(2);
        msg.sender.transfer(ethexchange);
    }
    
    function buyStarCoin() external payable {
        uint _tokens = msg.value.mul(2);
        _mintTokens(msg.sender, _tokens);
    }

    function setIsStudio(address _address, bool _value) external onlyOwner {
        isStudio[_address] = _value;
    }

    function depositToGateway(uint256 amount) external {
        transfer(gateway, amount);
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


contract StarLogicInterface {
    function isTransferAllowed(address _from, address _to, uint256 _tokenId) public view returns (bool);
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
}


/**
 * @title ERC-721 Non-Fungible Token Standard, full implementation interface
 * @dev See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md
 */
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}




/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
contract ERC721Receiver {
  /**
   * @dev Magic value to be returned upon successful reception of an NFT
   *  Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`,
   *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
   */
  bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

  /**
   * @notice Handle the receipt of an NFT
   * @dev The ERC721 smart contract calls this function on the recipient
   * after a `safetransfer`. This function MAY throw to revert and reject the
   * transfer. Return of other than the magic value MUST result in the
   * transaction being reverted.
   * Note: the contract address is always the message sender.
   * @param _operator The address which called `safeTransferFrom` function
   * @param _from The address which previously owned the token
   * @param _tokenId The NFT identifier which is being transferred
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
    bytes4 retval = ERC721Receiver(_to).onERC721Received(
      msg.sender, _from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}






/**
 * @title SupportsInterfaceWithLookup
 * @author Matt Condon (@shrugs)
 * @dev Implements ERC165 using a lookup table.
 */

contract EtherPornStars is Ownable, SupportsInterfaceWithLookup, ERC721BasicToken, ERC721 {

  struct StarData {
      uint16 fieldA;
      uint16 fieldB;
      uint32 fieldC;
      uint32 fieldD;
      uint32 fieldE;
      uint64 fieldF;
      uint64 fieldG;
  }

  address public logicContractAddress;
  address public starCoinAddress;

  // Ether Porn Star data
  mapping(uint256 => StarData) public starData;
  mapping(uint256 => bool) public starPower;
  mapping(uint256 => uint256) public starStudio;
  // Active Ether Porn Star
  mapping(address => uint256) public activeStar;
  event ActiveStarChanged(address indexed _from, uint256 _tokenId);
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
   // Mapping for multi-level network rewards
  mapping (uint256 => uint256) inviter;
  // Emitted when a user buys a star
  event BoughtStar(address indexed buyer, uint256 _tokenId, uint8 _studioId );
  address public leadAddress;
  address public reinvestmentContractAddress;
  address public withdrawalContractAddress;
  uint256 public totalStakeholders;
  uint256 public stakeMultiplier;
  uint public totalStake;
  uint256 public roundId;
  uint256 public roundEndTime;
  uint256 public roundEndTimeInitial;
  mapping (uint => address ) public holders;
  mapping(address => uint) public ownershipamt;
  mapping(address => uint) public divs;
  event CashedOut(address payee);
  /**
   * @dev Constructor function
   */
  modifier onlyLogicContract {
    require(msg.sender == logicContractAddress || msg.sender == owner);
    _;
  }
  constructor(string _name, string _symbol, address _starCoinAddress) public {
    name_ = _name;
    symbol_ = _symbol;
    starCoinAddress = _starCoinAddress;
    roundId = 1;
    roundEndTime = 1540844437; // round 1 end time
    roundEndTimeInitial = 1540844437;
    stakeMultiplier = 110;
    totalStake = 1000000000;

    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(InterfaceId_ERC721Enumerable);
    _registerInterface(InterfaceId_ERC721Metadata);
  }

    /**
    * @dev Sets the token&#39;s interchangeable logic contract
    */
  function setLogicContract(address _logicContractAddress) external onlyOwner {
    logicContractAddress = _logicContractAddress;
  }
  function setWithdrawalAndReinvestmentContracts(address _withdrawalContractAddress, address _reinvestmentContractAddress) external onlyOwner {
    withdrawalContractAddress = _withdrawalContractAddress;
    reinvestmentContractAddress = _reinvestmentContractAddress;
  }

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
   * @dev Internal function to add a token ID to the list of a given address
   * @param _to address representing the new owner of the given token ID
   * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function addTokenTo(address _to, uint256 _tokenId) internal {
    super.addTokenTo(_to, _tokenId);
    uint256 length = ownedTokens[_to].length;
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;

    if (activeStar[_to] == 0) {
      activeStar[_to] = _tokenId;
      emit ActiveStarChanged(_to, _tokenId);
    }
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

  function mint(address _to, uint256 _tokenId) external onlyLogicContract {
    _mint(_to, _tokenId);
  }
  /**
   * @dev Internal function to burn a specific token
   * Reverts if the token does not exist
   * @param _owner owner of the token to burn
   * @param _tokenId uint256 ID of the token being burned by the msg.sender
   */
  function _burn(address _owner, uint256 _tokenId) internal {
    super._burn(_owner, _tokenId);
    uint256 tokenIndex = allTokensIndex[_tokenId];
    uint256 lastTokenIndex = allTokens.length.sub(1);
    uint256 lastToken = allTokens[lastTokenIndex];

    allTokens[tokenIndex] = lastToken;
    allTokens[lastTokenIndex] = 0;

    allTokens.length--;
    allTokensIndex[_tokenId] = 0;
    allTokensIndex[lastToken] = tokenIndex;
  }

  function burn(address _owner, uint256 _tokenId) external onlyLogicContract {
    _burn(_owner, _tokenId);
}

/**
    * @dev Allows setting star data for a star
    * @param _tokenId star to set data for
    */
  function setStarData(
      uint256 _tokenId,
      uint16 _fieldA,
      uint16 _fieldB,
      uint32 _fieldC,
      uint32 _fieldD,
      uint32 _fieldE,
      uint64 _fieldF,
      uint64 _fieldG
  ) external onlyLogicContract {
      starData[_tokenId] = StarData(
          _fieldA,
          _fieldB,
          _fieldC,
          _fieldD,
          _fieldE,
          _fieldF,
          _fieldG
      );
  }

  function setActiveStar(uint256 _tokenId) external {
    require(msg.sender == ownerOf(_tokenId));
    activeStar[msg.sender] = _tokenId;
    emit ActiveStarChanged(msg.sender, _tokenId);
    }

  function forceTransfer(address _from, address _to, uint256 _tokenId) external onlyLogicContract {
      require(_from != address(0));
      require(_to != address(0));
      removeTokenFrom(_from, _tokenId);
      addTokenTo(_to, _tokenId);
      emit Transfer(_from, _to, _tokenId);
  }
  function transfer(address _to, uint256 _tokenId) external {
    require(msg.sender == ownerOf(_tokenId));
    require(_to != address(0));
    removeTokenFrom(msg.sender, _tokenId);
    addTokenTo(_to, _tokenId);
    emit Transfer(msg.sender, _to, _tokenId);
    }
  function addrecruit(uint256 _recId, uint256 _inviterId) private {
    inviter[_recId] = _inviterId;
}
  function buyStar(uint256 _tokenId, uint8 _studioId, uint256 _inviterId) external payable {
      require(msg.value >= 0.1 ether);
      _mint(msg.sender, _tokenId);
      emit BoughtStar(msg.sender, _tokenId, _studioId);
      uint amount = msg.value;
      starCoinAddress.transfer(msg.value);
      addrecruit(_tokenId, _inviterId);
      starStudio[_tokenId] = _studioId;
      StarCoin instanceStarCoin = StarCoin(starCoinAddress);
      instanceStarCoin.rewardTokens(msg.sender, amount);
        if (_inviterId != 0) {
          recReward(amount, _inviterId);
      }
      if(_studioId == 1) {
          starPower[_tokenId] = true;
      }
    }
  function recReward(uint amount, uint256 _inviterId) private {
    StarCoin instanceStarCoin = StarCoin(starCoinAddress);
    uint i=0;
    owner = ownerOf(_inviterId);
    amount = amount/2;
    instanceStarCoin.rewardTokens(owner, amount);
    while (i < 4) {
      amount = amount/2;
      owner = ownerOf(inviter[_inviterId]);
      if(owner==address(0)){
        break;
      }
      instanceStarCoin.rewardTokens(owner, amount);
      _inviterId = inviter[_inviterId];
      i++;
    }
  }

  function myTokens()
    external
    view
    returns (
      uint256[]
    )
  {
    return ownedTokens[msg.sender];
  }
  //FOMO Style lottery game integration
    function() public payable {
        require(msg.value >= 10000000000000000);

        if(now > roundEndTime){
            startNewRound();
        }

        uint stakeBought = msg.value.div(2);
        for(uint i = 0 ; i < totalStakeholders; i++) {
            address divEarner = holders[i];
            uint shareOfBuy = ownershipamt[divEarner].mul(100);
            shareOfBuy = shareOfBuy/totalStake;
            shareOfBuy = shareOfBuy.mul(stakeBought);
            divs[divEarner] += shareOfBuy/100;
        }
        if(ownershipamt[msg.sender] == 0 ){
            holders[totalStakeholders] = msg.sender;
            totalStakeholders += 1;
        }
        stakeBought = stakeBought.mul(stakeMultiplier);
        stakeBought = stakeBought.div(100);
        ownershipamt[msg.sender] += stakeBought;
        leadAddress = msg.sender;
        totalStake += stakeBought;
        addTime(stakeBought);
    }
    
    function buyStakeWithStarCoin(uint _tokens, address _referrer) public payable {
        require(_tokens >= 10000000000000000);
        StarCoin instanceStarCoin = StarCoin(starCoinAddress);
        instanceStarCoin.buyStudioStake(msg.sender, _tokens);
        if(_referrer != address(0)){
            uint _referralBonus = msg.value.div(50);
            divs[_referrer] += _referralBonus;
            if(activeStar[msg.sender] != 0){
                divs[_referrer] += _referralBonus;
            }
        }

        if(now > roundEndTime){
            startNewRound();
        }

        uint stakeBought = _tokens.div(4);
        for(uint i = 0 ; i < totalStakeholders; i++) {
            address divEarner = holders[i];
            uint shareOfBuy = ownershipamt[divEarner].mul(100);
            shareOfBuy = shareOfBuy/totalStake;
            shareOfBuy = shareOfBuy.mul(stakeBought);
            divs[divEarner] += shareOfBuy/100;
        }
        if(ownershipamt[msg.sender] == 0 ){
            holders[totalStakeholders] = msg.sender;
            totalStakeholders += 1;
        }
        stakeBought = stakeBought.mul(stakeMultiplier);
        stakeBought = stakeBought.div(100);
        ownershipamt[msg.sender] += stakeBought;
        leadAddress = msg.sender;
        totalStake += stakeBought;
        addTime(stakeBought);
    }
    
    function reinvestDivs(uint _divs) public{
        uint senderDivs = divs[msg.sender];
        require(_divs <= senderDivs);
        divs[msg.sender] = senderDivs.sub(_divs);
        leadAddress = msg.sender;
        ownershipamt[msg.sender] += _divs;
        totalStake += _divs;
        addTime(_divs);
        require(senderDivs >= 0); //double check to prevent re-entrancy exploit
    }
    
    function withdrawDivs(uint _divs) public{
        uint senderDivs = divs[msg.sender];
        require(_divs <= senderDivs);
        divs[msg.sender] = senderDivs.sub(_divs);
        msg.sender.transfer(senderDivs);
        require(senderDivs >= 0); //double check to prevent re-entrancy exploit
    }
    
    function reinvestDivsWithContract(address _reinvestor) public{
        require(msg.sender == reinvestmentContractAddress);
        uint senderDivs = divs[_reinvestor];
        require(senderDivs >= 10000000000000000);
        divs[_reinvestor] = 0;
        leadAddress = _reinvestor;
        ownershipamt[_reinvestor] += senderDivs;
        totalStake += senderDivs;
        addTime(senderDivs);
        require(divs[_reinvestor] == 0); //double check to prevent re-entrancy exploit
    }
    
    function withdrawDivsWithContract(address _withdrawer) public{
        require(msg.sender == withdrawalContractAddress);
        uint senderDivs = divs[_withdrawer];
        divs[_withdrawer] = 0;
        _withdrawer.transfer(senderDivs);
        require(divs[_withdrawer] == 0); //double check to prevent re-entrancy exploit
    }
    
    function addTime(uint stakeBought) private {
        if(stakeBought/10000000000000 < 86400){
            roundEndTime += stakeBought/1000000000000;
        }else{
        roundEndTime += 86400; //24 hour cap
        }
            
        if(now > roundEndTimeInitial.add(604800) && stakeMultiplier > 100 ) {
        stakeMultiplier -= 1;
        roundEndTimeInitial = now;
        }
    }
    
    function startNewRound() public { //change
        uint nextRoundSeed = totalStake.div(10);
        uint winnerShare = totalStake.sub(nextRoundSeed);
        leadAddress.transfer(winnerShare);
        roundId += 1;
        roundEndTimeInitial = now + 604800;  //add 1 week time to start next round
        roundEndTime = roundEndTimeInitial; // save initial round end time pre-increases for multiplier
        for(uint i = 0 ; i < totalStakeholders; i++) {
            delete ownershipamt[holders[i]];
            delete holders[i];
        }
        stakeMultiplier = 110;
        totalStakeholders = 0;
        totalStake = nextRoundSeed;
    }

    function returnTimeLeft()
     public view
     returns(uint256) {
     return(roundEndTime.sub(now));
     }
}
contract WithdrawalContract {
    
    address public etherPornStarsaddress;
    address public owner;
    
    
    constructor(address _etherPornStarsaddress) public {
        etherPornStarsaddress = _etherPornStarsaddress;
        owner = msg.sender;
    }
    
    function() public payable{
        require(msg.value >= 10000000000000000);
        EtherPornStars instanceEPS = EtherPornStars(etherPornStarsaddress);
        instanceEPS.withdrawDivsWithContract(msg.sender);
    }
    
    function collectFees() external {
        owner.transfer(address(this).balance);
    }
}

contract ReinvestmentContract {
    
    address public etherPornStarsaddress;
    address public owner;
    
    
    constructor(address _etherPornStarsaddress) public {
        etherPornStarsaddress = _etherPornStarsaddress;
        owner = msg.sender;
    }
    
    function() public payable{
        require(msg.value >= 10000000000000000);
        EtherPornStars instanceEPS = EtherPornStars(etherPornStarsaddress);
        instanceEPS.reinvestDivsWithContract(msg.sender);
    }
    
    function collectFees() external {
        owner.transfer(address(this).balance);
    }
}