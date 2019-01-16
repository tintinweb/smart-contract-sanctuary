pragma solidity 0.5.1;

/**
 * @dev Math operations with safety checks that throw on error. This contract is based on the 
 * source code at: 
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol.
 */
library SafeMath
{

  /**
   * @dev Error constants.
   */
  string constant OVERFLOW = "008001";
  string constant SUBTRAHEND_GREATER_THEN_MINUEND = "008002";
  string constant DIVISION_BY_ZERO = "008003";

  /**
   * @dev Multiplies two numbers, reverts on overflow.
   * @param _factor1 Factor number.
   * @param _factor2 Factor number.
   * @return The product of the two factors.
   */
  function mul(
    uint256 _factor1,
    uint256 _factor2
  )
    internal
    pure
    returns (uint256 product)
  {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_factor1 == 0)
    {
      return 0;
    }

    product = _factor1 * _factor2;
    require(product / _factor1 == _factor2, OVERFLOW);
  }

  /**
   * @dev Integer division of two numbers, truncating the quotient, reverts on division by zero.
   * @param _dividend Dividend number.
   * @param _divisor Divisor number.
   * @return The quotient.
   */
  function div(
    uint256 _dividend,
    uint256 _divisor
  )
    internal
    pure
    returns (uint256 quotient)
  {
    // Solidity automatically asserts when dividing by 0, using all gas.
    require(_divisor > 0, DIVISION_BY_ZERO);
    quotient = _dividend / _divisor;
    // assert(_dividend == _divisor * quotient + _dividend % _divisor); // There is no case in which this doesn&#39;t hold.
  }

  /**
   * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
   * @param _minuend Minuend number.
   * @param _subtrahend Subtrahend number.
   * @return Difference.
   */
  function sub(
    uint256 _minuend,
    uint256 _subtrahend
  )
    internal
    pure
    returns (uint256 difference)
  {
    require(_subtrahend <= _minuend, SUBTRAHEND_GREATER_THEN_MINUEND);
    difference = _minuend - _subtrahend;
  }

  /**
   * @dev Adds two numbers, reverts on overflow.
   * @param _addend1 Number.
   * @param _addend2 Number.
   * @return Sum.
   */
  function add(
    uint256 _addend1,
    uint256 _addend2
  )
    internal
    pure
    returns (uint256 sum)
  {
    sum = _addend1 + _addend2;
    require(sum >= _addend1, OVERFLOW);
  }

  /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo), reverts when
    * dividing by zero.
    * @param _dividend Number.
    * @param _divisor Number.
    * @return Remainder.
    */
  function mod(
    uint256 _dividend,
    uint256 _divisor
  )
    internal
    pure
    returns (uint256 remainder) 
  {
    require(_divisor != 0, DIVISION_BY_ZERO);
    remainder = _dividend % _divisor;
  }

}

/**
 * @dev Contract for setting abilities.
 */
contract Abilitable
{

  using SafeMath for uint;

  /**
   * @dev Error constants.
   */
  string constant NOT_AUTHORIZED = "017001";
  string constant ONE_ZERO_ABILITY_HAS_TO_EXIST = "017002";

  /**
   * @dev Id 0 is a reserved ability. It is an ability to assign or revoke abilities. 
   * There can be minimum of 1 address with 0 id ability.
   * Other ability id are determined by implementing contract.
   */
  uint8 constant ABILITY_TO_MANAGE_ABILITIES = 0;

  /**
   * @dev Maps address to ability id.
   */
  mapping(address => mapping(uint8 => bool)) private addressToAbility;

  /**
   * @dev Count of zero ability addresses.
   */
  uint256 private zeroAbilityCount;

  /**
   * @dev Emits when an address is assigned an ability.
   * @param _target Address to which we are assigning ability.
   * @param _ability Id of ability.
   */
  event AssignAbility(
    address indexed _target,
    uint8 indexed _ability
  );

  /**
   * @dev Emits when an address gets an ability revoked.
   * @param _target Address of which we are revoking an ability.
   * @param _ability Id of ability.
   */
  event RevokeAbility(
    address indexed _target,
    uint8 indexed _ability
  );

  /**
   * @dev Guarantees that msg.sender has a certain ability.
   */
  modifier hasAbility(
    uint8 _ability
  ) 
  {
    require(addressToAbility[msg.sender][_ability], NOT_AUTHORIZED);
    _;
  }

  /**
   * @dev Contract constructor.
   * Sets zero ability to the sender account.
   */
  constructor()
    public
  {
    addressToAbility[msg.sender][0] = true;
    zeroAbilityCount = 1;
    emit AssignAbility(msg.sender, 0);
  }

  /**
   * @dev Assigns specific abilities to specified address.
   * @param _target Address to assign abilities to.
   * @param _abilities List of ability IDs.
   */
  function assignAbilities(
    address _target,
    uint8[] memory _abilities
  )
    public
    hasAbility(ABILITY_TO_MANAGE_ABILITIES)
  {
    for(uint8 i; i<_abilities.length; i++)
    {
      if(_abilities[i] == 0)
      {
        zeroAbilityCount = zeroAbilityCount.add(1);
      }

      addressToAbility[_target][_abilities[i]] = true;
      emit AssignAbility(_target, _abilities[i]);
    }
  }

  /**
   * @dev Assigns specific abilities to specified address.
   * @param _target Address of which we revoke abilites.
   * @param _abilities List of ability IDs.
   */
  function revokeAbilities(
    address _target,
    uint8[] memory _abilities
  )
    public
    hasAbility(ABILITY_TO_MANAGE_ABILITIES)
  {
    for(uint8 i; i<_abilities.length; i++)
    {
      if(_abilities[i] == 0 )
      {
        require(zeroAbilityCount > 1, ONE_ZERO_ABILITY_HAS_TO_EXIST);
        zeroAbilityCount--;
      }

      addressToAbility[_target][_abilities[i]] = false;
      emit RevokeAbility(_target, _abilities[i]);
    }
  }

  /**
   * @dev Check if an address has a specific ability.
   * @param _target Address for which we want to check if it has a specific ability.
   * @param _ability Id of ability.
   */
  function isAble(
    address _target,
    uint8 _ability
  )
    public
    view
    returns (bool)
  {
    return addressToAbility[_target][_ability];
  }
  
}

pragma solidity 0.5.1;

/**
 * @dev ERC-721 non-fungible token standard. 
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface ERC721
{

  /**
   * @dev Emits when ownership of any NFT changes by any mechanism. This event emits when NFTs are
   * created (`from` == 0) and destroyed (`to` == 0). Exception: during contract creation, any
   * number of NFTs may be created and assigned without emitting Transfer. At the time of any
   * transfer, the approved address for that NFT (if any) is reset to none.
   */
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );

  /**
   * @dev This emits when the approved address for an NFT is changed or reaffirmed. The zero
   * address indicates there is no approved address. When a Transfer event emits, this also
   * indicates that the approved address for that NFT (if any) is reset to none.
   */
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );

  /**
   * @dev This emits when an operator is enabled or disabled for an owner. The operator can manage
   * all NFTs of the owner.
   */
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  /**
   * @dev Transfers the ownership of an NFT from one address to another address.
   * @notice Throws unless `msg.sender` is the current owner, an authorized operator, or the
   * approved address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is
   * the zero address. Throws if `_tokenId` is not a valid NFT. When transfer is complete, this
   * function checks if `_to` is a smart contract (code size > 0). If so, it calls
   * `onERC721Received` on `_to` and throws if the return value is not 
   * `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   * @param _data Additional data with no specified format, sent in call to `_to`.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
    external;

  /**
   * @dev Transfers the ownership of an NFT from one address to another address.
   * @notice This works identically to the other function with an extra data parameter, except this
   * function just sets data to ""
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  /**
   * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
   * address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is the zero
   * address. Throws if `_tokenId` is not a valid NFT.
   * @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
   * they mayb be permanently lost.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  /**
   * @dev Set or reaffirm the approved address for an NFT.
   * @notice The zero address indicates there is no approved address. Throws unless `msg.sender` is
   * the current NFT owner, or an authorized operator of the current owner.
   * @param _approved The new approved NFT controller.
   * @param _tokenId The NFT to approve.
   */
  function approve(
    address _approved,
    uint256 _tokenId
  )
    external;

  /**
   * @dev Enables or disables approval for a third party ("operator") to manage all of
   * `msg.sender`&#39;s assets. It also emits the ApprovalForAll event.
   * @notice The contract MUST allow multiple operators per owner.
   * @param _operator Address to add to the set of authorized operators.
   * @param _approved True if the operators is approved, false to revoke approval.
   */
  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external;

  /**
   * @dev Returns the number of NFTs owned by `_owner`. NFTs assigned to the zero address are
   * considered invalid, and this function throws for queries about the zero address.
   * @param _owner Address for whom to query the balance.
   * @return Balance of _owner.
   */
  function balanceOf(
    address _owner
  )
    external
    view
    returns (uint256);

  /**
   * @dev Returns the address of the owner of the NFT. NFTs assigned to zero address are considered
   * invalid, and queries about them do throw.
   * @param _tokenId The identifier for an NFT.
   * @return Address of _tokenId owner.
   */
  function ownerOf(
    uint256 _tokenId
  )
    external
    view
    returns (address);
    
  /**
   * @dev Get the approved address for a single NFT.
   * @notice Throws if `_tokenId` is not a valid NFT.
   * @param _tokenId The NFT to find the approved address for.
   * @return Address that _tokenId is approved for. 
   */
  function getApproved(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  /**
   * @dev Returns true if `_operator` is an approved operator for `_owner`, false otherwise.
   * @param _owner The address that owns the NFTs.
   * @param _operator The address that acts on behalf of the owner.
   * @return True if approved for all, false otherwise.
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    view
    returns (bool);

}

/**
 * @dev Standard interface for a dex proxy contract.
 */
interface Proxy {

  /**
   * @dev Executes an action.
   * @param _target Target of execution.
   * @param _a Address usually represention from.
   * @param _b Address usually representing to.
   * @param _c Integer usually repersenting amount/value/id.
   */
  function execute(
    address _target,
    address _a,
    address _b,
    uint256 _c
  )
    external;
    
}

/** 
 * @title NFTokenTransferProxy - Transfers none-fundgible tokens on behalf of contracts that have 
 * been approved via decentralized governance.
 * @dev based on:https://github.com/0xProject/contracts/blob/master/contracts/TokenTransferProxy.sol
 */
contract NFTokenSafeTransferProxy is 
  Proxy,
  Abilitable 
{

  /**
   * @dev List of abilities:
   * 1 - Ability to execute. 
   */
  uint8 constant ABILITY_TO_EXECUTE = 1;

  /**
   * @dev Transfers a NFT.
   * @param _target Address of NFT contract.
   * @param _a Address from which the NFT will be sent.
   * @param _b Address to which the NFT will be sent.
   * @param _c Id of the NFT being sent.
   */
  function execute(
    address _target,
    address _a,
    address _b,
    uint256 _c
  )
    external
    hasAbility(ABILITY_TO_EXECUTE)
  {
    ERC721(_target).safeTransferFrom(_a, _b, _c);
  }
  
}