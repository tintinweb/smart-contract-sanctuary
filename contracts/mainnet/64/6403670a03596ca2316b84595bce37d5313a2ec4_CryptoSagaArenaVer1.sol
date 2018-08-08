pragma solidity ^0.4.18;


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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


/**
 * @title Claimable
 * @dev Extension for the Ownable contract, where the ownership needs to be claimed.
 * This allows the new owner to accept the transfer.
 */
contract Claimable is Ownable {
  address public pendingOwner;

  /**
   * @dev Modifier throws if called by any account other than the pendingOwner.
   */
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

  /**
   * @dev Allows the current owner to set the pendingOwner address.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) onlyOwner public {
    pendingOwner = newOwner;
  }

  /**
   * @dev Allows the pendingOwner address to finalize the transfer.
   */
  function claimOwnership() onlyPendingOwner public {
    OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}


/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}


/**
 * @title ERC721 interface
 * @dev see https://github.com/ethereum/eips/issues/721
 */
contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
}


/**
 * @title ERC721Token
 * Generic implementation for the required functionality of the ERC721 standard
 */
contract ERC721Token is ERC721 {
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


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}


/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


/**
 * @title AccessDeposit
 * @dev Adds grant/revoke functions to the contract.
 */
contract AccessDeposit is Claimable {

  // Access for adding deposit.
  mapping(address => bool) private depositAccess;

  // Modifier for accessibility to add deposit.
  modifier onlyAccessDeposit {
    require(msg.sender == owner || depositAccess[msg.sender] == true);
    _;
  }

  // @dev Grant acess to deposit heroes.
  function grantAccessDeposit(address _address)
    onlyOwner
    public
  {
    depositAccess[_address] = true;
  }

  // @dev Revoke acess to deposit heroes.
  function revokeAccessDeposit(address _address)
    onlyOwner
    public
  {
    depositAccess[_address] = false;
  }

}


/**
 * @title AccessDeploy
 * @dev Adds grant/revoke functions to the contract.
 */
contract AccessDeploy is Claimable {

  // Access for deploying heroes.
  mapping(address => bool) private deployAccess;

  // Modifier for accessibility to deploy a hero on a location.
  modifier onlyAccessDeploy {
    require(msg.sender == owner || deployAccess[msg.sender] == true);
    _;
  }

  // @dev Grant acess to deploy heroes.
  function grantAccessDeploy(address _address)
    onlyOwner
    public
  {
    deployAccess[_address] = true;
  }

  // @dev Revoke acess to deploy heroes.
  function revokeAccessDeploy(address _address)
    onlyOwner
    public
  {
    deployAccess[_address] = false;
  }

}

/**
 * @title AccessMint
 * @dev Adds grant/revoke functions to the contract.
 */
contract AccessMint is Claimable {

  // Access for minting new tokens.
  mapping(address => bool) private mintAccess;

  // Modifier for accessibility to define new hero types.
  modifier onlyAccessMint {
    require(msg.sender == owner || mintAccess[msg.sender] == true);
    _;
  }

  // @dev Grant acess to mint heroes.
  function grantAccessMint(address _address)
    onlyOwner
    public
  {
    mintAccess[_address] = true;
  }

  // @dev Revoke acess to mint heroes.
  function revokeAccessMint(address _address)
    onlyOwner
    public
  {
    mintAccess[_address] = false;
  }

}


/**
 * @title Gold
 * @dev ERC20 Token that can be minted.
 */
contract Gold is StandardToken, Claimable, AccessMint {

  string public constant name = "Gold";
  string public constant symbol = "G";
  uint8 public constant decimals = 18;

  // Event that is fired when minted.
  event Mint(
    address indexed _to,
    uint256 indexed _tokenId
  );

  // @dev Mint tokens with _amount to the address.
  function mint(address _to, uint256 _amount) 
    onlyAccessMint
    public 
    returns (bool) 
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

}


/**
 * @title CryptoSaga Card
 * @dev ERC721 Token that repesents CryptoSaga&#39;s cards.
 *  Buy consuming a card, players of CryptoSaga can get a heroe.
 */
contract CryptoSagaCard is ERC721Token, Claimable, AccessMint {

  string public constant name = "CryptoSaga Card";
  string public constant symbol = "CARD";

  // Rank of the token.
  mapping(uint256 => uint8) public tokenIdToRank;

  // The number of tokens ever minted.
  uint256 public numberOfTokenId;

  // The converter contract.
  CryptoSagaCardSwap private swapContract;

  // Event that should be fired when card is converted.
  event CardSwap(address indexed _by, uint256 _tokenId, uint256 _rewardId);

  // @dev Set the address of the contract that represents CryptoSaga Cards.
  function setCryptoSagaCardSwapContract(address _contractAddress)
    public
    onlyOwner
  {
    swapContract = CryptoSagaCardSwap(_contractAddress);
  }

  function rankOf(uint256 _tokenId) 
    public view
    returns (uint8)
  {
    return tokenIdToRank[_tokenId];
  }

  // @dev Mint a new card.
  function mint(address _beneficiary, uint256 _amount, uint8 _rank)
    onlyAccessMint
    public
  {
    for (uint256 i = 0; i < _amount; i++) {
      _mint(_beneficiary, numberOfTokenId);
      tokenIdToRank[numberOfTokenId] = _rank;
      numberOfTokenId ++;
    }
  }

  // @dev Swap this card for reward.
  //  The card will be burnt.
  function swap(uint256 _tokenId)
    onlyOwnerOf(_tokenId)
    public
    returns (uint256)
  {
    require(address(swapContract) != address(0));

    var _rank = tokenIdToRank[_tokenId];
    var _rewardId = swapContract.swapCardForReward(this, _rank);
    CardSwap(ownerOf(_tokenId), _tokenId, _rewardId);
    _burn(_tokenId);
    return _rewardId;
  }

}


/**
 * @title The interface contract for Card-For-Hero swap functionality.
 * @dev With this contract, a card holder can swap his/her CryptoSagaCard for reward.
 *  This contract is intended to be inherited by CryptoSagaCardSwap implementation contracts.
 */
contract CryptoSagaCardSwap is Ownable {

  // Card contract.
  address internal cardAddess;

  // Modifier for accessibility to define new hero types.
  modifier onlyCard {
    require(msg.sender == cardAddess);
    _;
  }
  
  // @dev Set the address of the contract that represents ERC721 Card.
  function setCardContract(address _contractAddress)
    public
    onlyOwner
  {
    cardAddess = _contractAddress;
  }

  // @dev Convert card into reward.
  //  This should be implemented by CryptoSagaCore later.
  function swapCardForReward(address _by, uint8 _rank)
    onlyCard
    public 
    returns (uint256);

}


/**
 * @title CryptoSagaHero
 * @dev The token contract for the hero.
 *  Also a superset of the ERC721 standard that allows for the minting
 *  of the non-fungible tokens.
 */
contract CryptoSagaHero is ERC721Token, Claimable, Pausable, AccessMint, AccessDeploy, AccessDeposit {

  string public constant name = "CryptoSaga Hero";
  string public constant symbol = "HERO";
  
  struct HeroClass {
    // ex) Soldier, Knight, Fighter...
    string className;
    // 0: Common, 1: Uncommon, 2: Rare, 3: Heroic, 4: Legendary.
    uint8 classRank;
    // 0: Human, 1: Celestial, 2: Demon, 3: Elf, 4: Dark Elf, 5: Yogoe, 6: Furry, 7: Dragonborn, 8: Undead, 9: Goblin, 10: Troll, 11: Slime, and more to come.
    uint8 classRace;
    // How old is this hero class? 
    uint32 classAge;
    // 0: Fighter, 1: Rogue, 2: Mage.
    uint8 classType;

    // Possible max level of this class.
    uint32 maxLevel; 
    // 0: Water, 1: Fire, 2: Nature, 3: Light, 4: Darkness.
    uint8 aura; 

    // Base stats of this hero type. 
    // 0: ATK	1: DEF 2: AGL	3: LUK 4: HP.
    uint32[5] baseStats;
    // Minimum IVs for stats. 
    // 0: ATK	1: DEF 2: AGL	3: LUK 4: HP.
    uint32[5] minIVForStats;
    // Maximum IVs for stats.
    // 0: ATK	1: DEF 2: AGL	3: LUK 4: HP.
    uint32[5] maxIVForStats;
    
    // Number of currently instanced heroes.
    uint32 currentNumberOfInstancedHeroes;
  }
    
  struct HeroInstance {
    // What is this hero&#39;s type? ex) John, Sally, Mark...
    uint32 heroClassId;
    
    // Individual hero&#39;s name.
    string heroName;
    
    // Current level of this hero.
    uint32 currentLevel;
    // Current exp of this hero.
    uint32 currentExp;

    // Where has this hero been deployed? (0: Never depolyed ever.) ex) Dungeon Floor #1, Arena #5...
    uint32 lastLocationId;
    // When a hero is deployed, it takes time for the hero to return to the base. This is in Unix epoch.
    uint256 availableAt;

    // Current stats of this hero. 
    // 0: ATK	1: DEF 2: AGL	3: LUK 4: HP.
    uint32[5] currentStats;
    // The individual value for this hero&#39;s stats. 
    // This will affect the current stats of heroes.
    // 0: ATK	1: DEF 2: AGL	3: LUK 4: HP.
    uint32[5] ivForStats;
  }

  // Required exp for level up will increase when heroes level up.
  // This defines how the value will increase.
  uint32 public requiredExpIncreaseFactor = 100;

  // Required Gold for level up will increase when heroes level up.
  // This defines how the value will increase.
  uint256 public requiredGoldIncreaseFactor = 1000000000000000000;

  // Existing hero classes.
  mapping(uint32 => HeroClass) public heroClasses;
  // The number of hero classes ever defined.
  uint32 public numberOfHeroClasses;

  // Existing hero instances.
  // The key is _tokenId.
  mapping(uint256 => HeroInstance) public tokenIdToHeroInstance;
  // The number of tokens ever minted. This works as the serial number.
  uint256 public numberOfTokenIds;

  // Gold contract.
  Gold public goldContract;

  // Deposit of players (in Gold).
  mapping(address => uint256) public addressToGoldDeposit;

  // Random seed.
  uint32 private seed = 0;

  // Event that is fired when a hero type defined.
  event DefineType(
    address indexed _by,
    uint32 indexed _typeId,
    string _className
  );

  // Event that is fired when a hero is upgraded.
  event LevelUp(
    address indexed _by,
    uint256 indexed _tokenId,
    uint32 _newLevel
  );

  // Event that is fired when a hero is deployed.
  event Deploy(
    address indexed _by,
    uint256 indexed _tokenId,
    uint32 _locationId,
    uint256 _duration
  );

  // @dev Get the class&#39;s entire infomation.
  function getClassInfo(uint32 _classId)
    external view
    returns (string className, uint8 classRank, uint8 classRace, uint32 classAge, uint8 classType, uint32 maxLevel, uint8 aura, uint32[5] baseStats, uint32[5] minIVs, uint32[5] maxIVs) 
  {
    var _cl = heroClasses[_classId];
    return (_cl.className, _cl.classRank, _cl.classRace, _cl.classAge, _cl.classType, _cl.maxLevel, _cl.aura, _cl.baseStats, _cl.minIVForStats, _cl.maxIVForStats);
  }

  // @dev Get the class&#39;s name.
  function getClassName(uint32 _classId)
    external view
    returns (string)
  {
    return heroClasses[_classId].className;
  }

  // @dev Get the class&#39;s rank.
  function getClassRank(uint32 _classId)
    external view
    returns (uint8)
  {
    return heroClasses[_classId].classRank;
  }

  // @dev Get the heroes ever minted for the class.
  function getClassMintCount(uint32 _classId)
    external view
    returns (uint32)
  {
    return heroClasses[_classId].currentNumberOfInstancedHeroes;
  }

  // @dev Get the hero&#39;s entire infomation.
  function getHeroInfo(uint256 _tokenId)
    external view
    returns (uint32 classId, string heroName, uint32 currentLevel, uint32 currentExp, uint32 lastLocationId, uint256 availableAt, uint32[5] currentStats, uint32[5] ivs, uint32 bp)
  {
    HeroInstance memory _h = tokenIdToHeroInstance[_tokenId];
    var _bp = _h.currentStats[0] + _h.currentStats[1] + _h.currentStats[2] + _h.currentStats[3] + _h.currentStats[4];
    return (_h.heroClassId, _h.heroName, _h.currentLevel, _h.currentExp, _h.lastLocationId, _h.availableAt, _h.currentStats, _h.ivForStats, _bp);
  }

  // @dev Get the hero&#39;s class id.
  function getHeroClassId(uint256 _tokenId)
    external view
    returns (uint32)
  {
    return tokenIdToHeroInstance[_tokenId].heroClassId;
  }

  // @dev Get the hero&#39;s name.
  function getHeroName(uint256 _tokenId)
    external view
    returns (string)
  {
    return tokenIdToHeroInstance[_tokenId].heroName;
  }

  // @dev Get the hero&#39;s level.
  function getHeroLevel(uint256 _tokenId)
    external view
    returns (uint32)
  {
    return tokenIdToHeroInstance[_tokenId].currentLevel;
  }
  
  // @dev Get the hero&#39;s location.
  function getHeroLocation(uint256 _tokenId)
    external view
    returns (uint32)
  {
    return tokenIdToHeroInstance[_tokenId].lastLocationId;
  }

  // @dev Get the time when the hero become available.
  function getHeroAvailableAt(uint256 _tokenId)
    external view
    returns (uint256)
  {
    return tokenIdToHeroInstance[_tokenId].availableAt;
  }

  // @dev Get the hero&#39;s BP.
  function getHeroBP(uint256 _tokenId)
    public view
    returns (uint32)
  {
    var _tmp = tokenIdToHeroInstance[_tokenId].currentStats;
    return (_tmp[0] + _tmp[1] + _tmp[2] + _tmp[3] + _tmp[4]);
  }

  // @dev Get the hero&#39;s required gold for level up.
  function getHeroRequiredGoldForLevelUp(uint256 _tokenId)
    public view
    returns (uint256)
  {
    return (uint256(2) ** (tokenIdToHeroInstance[_tokenId].currentLevel / 10)) * requiredGoldIncreaseFactor;
  }

  // @dev Get the hero&#39;s required exp for level up.
  function getHeroRequiredExpForLevelUp(uint256 _tokenId)
    public view
    returns (uint32)
  {
    return ((tokenIdToHeroInstance[_tokenId].currentLevel + 2) * requiredExpIncreaseFactor);
  }

  // @dev Get the deposit of gold of the player.
  function getGoldDepositOfAddress(address _address)
    external view
    returns (uint256)
  {
    return addressToGoldDeposit[_address];
  }

  // @dev Get the token id of the player&#39;s #th token.
  function getTokenIdOfAddressAndIndex(address _address, uint256 _index)
    external view
    returns (uint256)
  {
    return tokensOf(_address)[_index];
  }

  // @dev Get the total BP of the player.
  function getTotalBPOfAddress(address _address)
    external view
    returns (uint32)
  {
    var _tokens = tokensOf(_address);
    uint32 _totalBP = 0;
    for (uint256 i = 0; i < _tokens.length; i ++) {
      _totalBP += getHeroBP(_tokens[i]);
    }
    return _totalBP;
  }

  // @dev Set the hero&#39;s name.
  function setHeroName(uint256 _tokenId, string _name)
    onlyOwnerOf(_tokenId)
    public
  {
    tokenIdToHeroInstance[_tokenId].heroName = _name;
  }

  // @dev Set the address of the contract that represents ERC20 Gold.
  function setGoldContract(address _contractAddress)
    onlyOwner
    public
  {
    goldContract = Gold(_contractAddress);
  }

  // @dev Set the required golds to level up a hero.
  function setRequiredExpIncreaseFactor(uint32 _value)
    onlyOwner
    public
  {
    requiredExpIncreaseFactor = _value;
  }

  // @dev Set the required golds to level up a hero.
  function setRequiredGoldIncreaseFactor(uint256 _value)
    onlyOwner
    public
  {
    requiredGoldIncreaseFactor = _value;
  }

  // @dev Contructor.
  function CryptoSagaHero(address _goldAddress)
    public
  {
    require(_goldAddress != address(0));

    // Assign Gold contract.
    setGoldContract(_goldAddress);

    // Initial heroes.
    // Name, Rank, Race, Age, Type, Max Level, Aura, Stats.
    defineType("Archangel", 4, 1, 13540, 0, 99, 3, [uint32(74), 75, 57, 99, 95], [uint32(8), 6, 8, 5, 5], [uint32(8), 10, 10, 6, 6]);
    defineType("Shadowalker", 3, 4, 134, 1, 75, 4, [uint32(45), 35, 60, 80, 40], [uint32(3), 2, 10, 4, 5], [uint32(5), 5, 10, 7, 5]);
    defineType("Pyromancer", 2, 0, 14, 2, 50, 1, [uint32(50), 28, 17, 40, 35], [uint32(5), 3, 2, 3, 3], [uint32(8), 4, 3, 4, 5]);
    defineType("Magician", 1, 3, 224, 2, 30, 0, [uint32(35), 15, 25, 25, 30], [uint32(3), 1, 2, 2, 2], [uint32(5), 2, 3, 3, 3]);
    defineType("Farmer", 0, 0, 59, 0, 15, 2, [uint32(10), 22, 8, 15, 25], [uint32(1), 2, 1, 1, 2], [uint32(1), 3, 1, 2, 3]);
  }

  // @dev Define a new hero type (class).
  function defineType(string _className, uint8 _classRank, uint8 _classRace, uint32 _classAge, uint8 _classType, uint32 _maxLevel, uint8 _aura, uint32[5] _baseStats, uint32[5] _minIVForStats, uint32[5] _maxIVForStats)
    onlyOwner
    public
  {
    require(_classRank < 5);
    require(_classType < 3);
    require(_aura < 5);
    require(_minIVForStats[0] <= _maxIVForStats[0] && _minIVForStats[1] <= _maxIVForStats[1] && _minIVForStats[2] <= _maxIVForStats[2] && _minIVForStats[3] <= _maxIVForStats[3] && _minIVForStats[4] <= _maxIVForStats[4]);

    HeroClass memory _heroType = HeroClass({
      className: _className,
      classRank: _classRank,
      classRace: _classRace,
      classAge: _classAge,
      classType: _classType,
      maxLevel: _maxLevel,
      aura: _aura,
      baseStats: _baseStats,
      minIVForStats: _minIVForStats,
      maxIVForStats: _maxIVForStats,
      currentNumberOfInstancedHeroes: 0
    });

    // Save the hero class.
    heroClasses[numberOfHeroClasses] = _heroType;

    // Fire event.
    DefineType(msg.sender, numberOfHeroClasses, _heroType.className);

    // Increment number of hero classes.
    numberOfHeroClasses ++;

  }

  // @dev Mint a new hero, with _heroClassId.
  function mint(address _owner, uint32 _heroClassId)
    onlyAccessMint
    public
    returns (uint256)
  {
    require(_owner != address(0));
    require(_heroClassId < numberOfHeroClasses);

    // The information of the hero&#39;s class.
    var _heroClassInfo = heroClasses[_heroClassId];

    // Mint ERC721 token.
    _mint(_owner, numberOfTokenIds);

    // Build random IVs for this hero instance.
    uint32[5] memory _ivForStats;
    uint32[5] memory _initialStats;
    for (uint8 i = 0; i < 5; i++) {
      _ivForStats[i] = (random(_heroClassInfo.maxIVForStats[i] + 1, _heroClassInfo.minIVForStats[i]));
      _initialStats[i] = _heroClassInfo.baseStats[i] + _ivForStats[i];
    }

    // Temporary hero instance.
    HeroInstance memory _heroInstance = HeroInstance({
      heroClassId: _heroClassId,
      heroName: "",
      currentLevel: 1,
      currentExp: 0,
      lastLocationId: 0,
      availableAt: now,
      currentStats: _initialStats,
      ivForStats: _ivForStats
    });

    // Save the hero instance.
    tokenIdToHeroInstance[numberOfTokenIds] = _heroInstance;

    // Increment number of token ids.
    // This will only increment when new token is minted, and will never be decemented when the token is burned.
    numberOfTokenIds ++;

     // Increment instanced number of heroes.
    _heroClassInfo.currentNumberOfInstancedHeroes ++;

    return numberOfTokenIds - 1;
  }

  // @dev Set where the heroes are deployed, and when they will return.
  //  This is intended to be called by Dungeon, Arena, Guild contracts.
  function deploy(uint256 _tokenId, uint32 _locationId, uint256 _duration)
    onlyAccessDeploy
    public
    returns (bool)
  {
    // The hero should be possessed by anybody.
    require(ownerOf(_tokenId) != address(0));

    var _heroInstance = tokenIdToHeroInstance[_tokenId];

    // The character should be avaiable. 
    require(_heroInstance.availableAt <= now);

    _heroInstance.lastLocationId = _locationId;
    _heroInstance.availableAt = now + _duration;

    // As the hero has been deployed to another place, fire event.
    Deploy(msg.sender, _tokenId, _locationId, _duration);
  }

  // @dev Add exp.
  //  This is intended to be called by Dungeon, Arena, Guild contracts.
  function addExp(uint256 _tokenId, uint32 _exp)
    onlyAccessDeploy
    public
    returns (bool)
  {
    // The hero should be possessed by anybody.
    require(ownerOf(_tokenId) != address(0));

    var _heroInstance = tokenIdToHeroInstance[_tokenId];

    var _newExp = _heroInstance.currentExp + _exp;

    // Sanity check to ensure we don&#39;t overflow.
    require(_newExp == uint256(uint128(_newExp)));

    _heroInstance.currentExp += _newExp;

  }

  // @dev Add deposit.
  //  This is intended to be called by Dungeon, Arena, Guild contracts.
  function addDeposit(address _to, uint256 _amount)
    onlyAccessDeposit
    public
  {
    // Increment deposit.
    addressToGoldDeposit[_to] += _amount;
  }

  // @dev Level up the hero with _tokenId.
  //  This function is called by the owner of the hero.
  function levelUp(uint256 _tokenId)
    onlyOwnerOf(_tokenId) whenNotPaused
    public
  {

    // Hero instance.
    var _heroInstance = tokenIdToHeroInstance[_tokenId];

    // The character should be avaiable. (Should have already returned from the dungeons, arenas, etc.)
    require(_heroInstance.availableAt <= now);

    // The information of the hero&#39;s class.
    var _heroClassInfo = heroClasses[_heroInstance.heroClassId];

    // Hero shouldn&#39;t level up exceed its max level.
    require(_heroInstance.currentLevel < _heroClassInfo.maxLevel);

    // Required Exp.
    var requiredExp = getHeroRequiredExpForLevelUp(_tokenId);

    // Need to have enough exp.
    require(_heroInstance.currentExp >= requiredExp);

    // Required Gold.
    var requiredGold = getHeroRequiredGoldForLevelUp(_tokenId);

    // Owner of token.
    var _ownerOfToken = ownerOf(_tokenId);

    // Need to have enough Gold balance.
    require(addressToGoldDeposit[_ownerOfToken] >= requiredGold);

    // Increase Level.
    _heroInstance.currentLevel += 1;

    // Increase Stats.
    for (uint8 i = 0; i < 5; i++) {
      _heroInstance.currentStats[i] = _heroClassInfo.baseStats[i] + (_heroInstance.currentLevel - 1) * _heroInstance.ivForStats[i];
    }
    
    // Deduct exp.
    _heroInstance.currentExp -= requiredExp;

    // Deduct gold.
    addressToGoldDeposit[_ownerOfToken] -= requiredGold;

    // Fire event.
    LevelUp(msg.sender, _tokenId, _heroInstance.currentLevel);
  }

  // @dev Transfer deposit (with the allowance pattern.)
  function transferDeposit(uint256 _amount)
    whenNotPaused
    public
  {
    require(goldContract.allowance(msg.sender, this) >= _amount);

    // Send msg.sender&#39;s Gold to this contract.
    if (goldContract.transferFrom(msg.sender, this, _amount)) {
       // Increment deposit.
      addressToGoldDeposit[msg.sender] += _amount;
    }
  }

  // @dev Withdraw deposit.
  function withdrawDeposit(uint256 _amount)
    public
  {
    require(addressToGoldDeposit[msg.sender] >= _amount);

    // Send deposit of Golds to msg.sender. (Rather minting...)
    if (goldContract.transfer(msg.sender, _amount)) {
      // Decrement deposit.
      addressToGoldDeposit[msg.sender] -= _amount;
    }
  }

  // @dev return a pseudo random number between lower and upper bounds
  function random(uint32 _upper, uint32 _lower)
    private
    returns (uint32)
  {
    require(_upper > _lower);

    seed = uint32(keccak256(keccak256(block.blockhash(block.number), seed), now));
    return seed % (_upper - _lower) + _lower;
  }

}


/**
 * @title CryptoSagaCorrectedHeroStats
 * @dev Corrected hero stats is needed to fix the bug in hero stats.
 */
contract CryptoSagaCorrectedHeroStats {

  // The hero contract.
  CryptoSagaHero private heroContract;

  // @dev Constructor.
  function CryptoSagaCorrectedHeroStats(address _heroContractAddress)
    public
  {
    heroContract = CryptoSagaHero(_heroContractAddress);
  }

  // @dev Get the hero&#39;s stats and some other infomation.
  function getCorrectedStats(uint256 _tokenId)
    external view
    returns (uint32 currentLevel, uint32 currentExp, uint32[5] currentStats, uint32[5] ivs, uint32 bp)
  {
    var (, , _currentLevel, _currentExp, , , _currentStats, _ivs, ) = heroContract.getHeroInfo(_tokenId);
    
    if (_currentLevel != 1) {
      for (uint8 i = 0; i < 5; i ++) {
        _currentStats[i] += _ivs[i];
      }
    }

    var _bp = _currentStats[0] + _currentStats[1] + _currentStats[2] + _currentStats[3] + _currentStats[4];
    return (_currentLevel, _currentExp, _currentStats, _ivs, _bp);
  }

  // @dev Get corrected total BP of the address.
  function getCorrectedTotalBPOfAddress(address _address)
    external view
    returns (uint32)
  {
    var _balance = heroContract.balanceOf(_address);

    uint32 _totalBP = 0;

    for (uint256 i = 0; i < _balance; i ++) {
      var (, , _currentLevel, , , , _currentStats, _ivs, ) = heroContract.getHeroInfo(heroContract.getTokenIdOfAddressAndIndex(_address, i));
      if (_currentLevel != 1) {
        for (uint8 j = 0; j < 5; j ++) {
          _currentStats[j] += _ivs[j];
        }
      }
      _totalBP += (_currentStats[0] + _currentStats[1] + _currentStats[2] + _currentStats[3] + _currentStats[4]);
    }

    return _totalBP;
  }

  // @dev Get corrected total BP of the address.
  function getCorrectedTotalBPOfTokens(uint256[] _tokens)
    external view
    returns (uint32)
  {
    uint32 _totalBP = 0;

    for (uint256 i = 0; i < _tokens.length; i ++) {
      var (, , _currentLevel, , , , _currentStats, _ivs, ) = heroContract.getHeroInfo(_tokens[i]);
      if (_currentLevel != 1) {
        for (uint8 j = 0; j < 5; j ++) {
          _currentStats[j] += _ivs[j];
        }
      }
      _totalBP += (_currentStats[0] + _currentStats[1] + _currentStats[2] + _currentStats[3] + _currentStats[4]);
    }

    return _totalBP;
  }
}


/**
 * @title CryptoSagaArenaRecord
 * @dev The record of battles in the Arena.
 */
contract CryptoSagaArenaRecord is Pausable, AccessDeploy {

  // Number of players for the leaderboard.
  uint8 public numberOfLeaderboardPlayers = 25;

  // Top players in the leaderboard.
  address[] public leaderBoardPlayers;

  // For checking whether the player is in the leaderboard.
  mapping(address => bool) public addressToIsInLeaderboard;

  // Number of recent player recorded for matchmaking.
  uint8 public numberOfRecentPlayers = 50;

  // List of recent players.
  address[] public recentPlayers;

  // Front of recent players.
  uint256 public recentPlayersFront;

  // Back of recent players.
  uint256 public recentPlayersBack;

  // Record of each player.
  mapping(address => uint32) public addressToElo;

  // Event that is fired when a new change has been made to the leaderboard.
  event UpdateLeaderboard(
    address indexed _by,
    uint256 _dateTime
  );

  // @dev Get elo rating of a player.
  function getEloRating(address _address)
    external view
    returns (uint32)
  {
    if (addressToElo[_address] != 0)
      return addressToElo[_address];
    else
      return 1500;
  }

  // @dev Get players in the leaderboard.
  function getLeaderboardPlayers()
    external view
    returns (address[])
  {
    return leaderBoardPlayers;
  }

  // @dev Get current length of the leaderboard.
  function getLeaderboardLength()
    external view
    returns (uint256)
  {
    return leaderBoardPlayers.length;
  }

  // @dev Get recently played players.
  function getRecentPlayers()
    external view
    returns (address[])
  {
    return recentPlayers;
  }

  // @dev Get current number of players in the recently played players queue.
  function getRecentPlayersCount()
    public view
    returns (uint256) 
  {
    return recentPlayersBack - recentPlayersFront;
  }

  // @dev Constructor.
  function CryptoSagaArenaRecord(
    address _firstPlayerAddress,
    uint32 _firstPlayerElo, 
    uint8 _numberOfLeaderboardPlayers, 
    uint8 _numberOfRecentPlayers)
    public
  {

    numberOfLeaderboardPlayers = _numberOfLeaderboardPlayers;
    numberOfRecentPlayers = _numberOfRecentPlayers;

    // The initial player gets into leaderboard.
    leaderBoardPlayers.push(_firstPlayerAddress);
    addressToIsInLeaderboard[_firstPlayerAddress] = true;

    // The initial player pushed into the recent players queue. 
    pushPlayer(_firstPlayerAddress);
    
    // The initial player&#39;s Elo.
    addressToElo[_firstPlayerAddress] = _firstPlayerElo;
  }

  // @dev Update record.
  function updateRecord(address _myAddress, address _enemyAddress, bool _didWin)
    whenNotPaused onlyAccessDeploy
    public
  {
    address _winnerAddress = _didWin? _myAddress: _enemyAddress;
    address _loserAddress = _didWin? _enemyAddress: _myAddress;
    
    // Initial value of Elo.
    uint32 _winnerElo = addressToElo[_winnerAddress];
    if (_winnerElo == 0)
      _winnerElo = 1500;
    uint32 _loserElo = addressToElo[_loserAddress];
    if (_loserElo == 0)
      _loserElo = 1500;

    // Adjust Elo.
    if (_winnerElo >= _loserElo) {
      if (_winnerElo - _loserElo < 50) {
        addressToElo[_winnerAddress] = _winnerElo + 5;
        addressToElo[_loserAddress] = _loserElo - 5;
      } else if (_winnerElo - _loserElo < 80) {
        addressToElo[_winnerAddress] = _winnerElo + 4;
        addressToElo[_loserAddress] = _loserElo - 4;
      } else if (_winnerElo - _loserElo < 150) {
        addressToElo[_winnerAddress] = _winnerElo + 3;
        addressToElo[_loserAddress] = _loserElo - 3;
      } else if (_winnerElo - _loserElo < 250) {
        addressToElo[_winnerAddress] = _winnerElo + 2;
        addressToElo[_loserAddress] = _loserElo - 2;
      } else {
        addressToElo[_winnerAddress] = _winnerElo + 1;
        addressToElo[_loserAddress] = _loserElo - 1;
      }
    } else {
      if (_loserElo - _winnerElo < 50) {
        addressToElo[_winnerAddress] = _winnerElo + 5;
        addressToElo[_loserAddress] = _loserElo - 5;
      } else if (_loserElo - _winnerElo < 80) {
        addressToElo[_winnerAddress] = _winnerElo + 6;
        addressToElo[_loserAddress] = _loserElo - 6;
      } else if (_loserElo - _winnerElo < 150) {
        addressToElo[_winnerAddress] = _winnerElo + 7;
        addressToElo[_loserAddress] = _loserElo - 7;
      } else if (_loserElo - _winnerElo < 250) {
        addressToElo[_winnerAddress] = _winnerElo + 8;
        addressToElo[_loserAddress] = _loserElo - 8;
      } else {
        addressToElo[_winnerAddress] = _winnerElo + 9;
        addressToElo[_loserAddress] = _loserElo - 9;
      }
    }

    // Update recent players list.
    if (!isPlayerInQueue(_myAddress)) {
      
      // If the queue is full, pop a player.
      if (getRecentPlayersCount() >= numberOfRecentPlayers)
        popPlayer();
      
      // Push _myAddress to the queue.
      pushPlayer(_myAddress);
    }

    // Update leaderboards.
    if(updateLeaderboard(_enemyAddress) || updateLeaderboard(_myAddress))
    {
      UpdateLeaderboard(_myAddress, now);
    }

  }

  // @dev Update leaderboard.
  function updateLeaderboard(address _addressToUpdate)
    whenNotPaused
    private
    returns (bool isChanged)
  {

    // If this players is already in the leaderboard, there&#39;s no need for replace the minimum recorded player.
    if (addressToIsInLeaderboard[_addressToUpdate]) {
      // Do nothing.
    } else {
      if (leaderBoardPlayers.length >= numberOfLeaderboardPlayers) {
        
        // Need to replace existing player.
        // First, we need to find the player with miminum Elo value.
        uint32 _minimumElo = 99999;
        uint8 _minimumEloPlayerIndex = numberOfLeaderboardPlayers;
        for (uint8 i = 0; i < leaderBoardPlayers.length; i ++) {
          if (_minimumElo > addressToElo[leaderBoardPlayers[i]]) {
            _minimumElo = addressToElo[leaderBoardPlayers[i]];
            _minimumEloPlayerIndex = i;
          }
        }

        // Second, if the minimum elo value is smaller than the player&#39;s elo value, then replace the entity.
        if (_minimumElo <= addressToElo[_addressToUpdate]) {
          leaderBoardPlayers[_minimumEloPlayerIndex] = _addressToUpdate;
          addressToIsInLeaderboard[_addressToUpdate] = true;
          addressToIsInLeaderboard[leaderBoardPlayers[_minimumEloPlayerIndex]] = false;
          isChanged = true;
        }
      } else {
        // The list is not full yet. 
        // Just add the player to the list.
        leaderBoardPlayers.push(_addressToUpdate);
        addressToIsInLeaderboard[_addressToUpdate] = true;
        isChanged = true;
      }
    }
  }

  // #dev Check whether contain the element or not.
  function isPlayerInQueue(address _player)
    view private
    returns (bool isContain)
  {
    isContain = false;
    for (uint256 i = recentPlayersFront; i < recentPlayersBack; i++) {
      if (_player == recentPlayers[i]) {
        isContain = true;
      }
    }
  }
    
  // @dev Push a new player into the queue.
  function pushPlayer(address _player)
    private
  {
    recentPlayers.push(_player);
    recentPlayersBack++;
  }
    
  // @dev Pop the oldest player in this queue.
  function popPlayer() 
    private
    returns (address player)
  {
    if (recentPlayersBack == recentPlayersFront)
      return address(0);
    player = recentPlayers[recentPlayersFront];
    delete recentPlayers[recentPlayersFront];
    recentPlayersFront++;
  }

}


/**
 * @title CryptoSagaArenaVer1
 * @dev The actual gameplay is done by this contract. Version 1.0.0.
 */
contract CryptoSagaArenaVer1 is Claimable, Pausable {

  struct PlayRecord {
    // This is needed for reconstructing the record.
    uint32 initialSeed;
    // The address of the enemy player.
    address enemyAddress;
    // Hero&#39;s token ids.
    uint256[4] tokenIds;
    // Unit&#39;s class ids. 0 ~ 3: Heroes. 4 ~ 7: Mobs.
    uint32[8] unitClassIds;
    // Unit&#39;s levels. 0 ~ 3: Heroes. 4 ~ 7: Mobs.
    uint32[8] unitLevels;
    // Exp reward given.
    uint32 expReward;
    // Gold Reward given.
    uint256 goldReward;
  }

  // This information can be reconstructed with seed and dateTime.
  // For the optimization this won&#39;t be really used.
  struct TurnInfo {
    // Number of turns before a team was vanquished.
    uint8 turnLength;
    // Turn order of units.
    uint8[8] turnOrder;
    // Defender list. (The unit that is attacked.)
    uint8[24] defenderList;
    // Damage list. (The damage given to the defender.)
    uint32[24] damageList;
    // Heroes&#39; original Exps.
    uint32[4] originalExps;
  }

  // Progress contract.
  CryptoSagaArenaRecord private recordContract;

  // The hero contract.
  CryptoSagaHero private heroContract;

  // Corrected hero stats contract.
  CryptoSagaCorrectedHeroStats private correctedHeroContract;

  // Gold contract.
  Gold public goldContract;

  // Card contract.
  CryptoSagaCard public cardContract;

  // The location Id of this contract.
  // Will be used when calling deploy function of hero contract.
  uint32 public locationId = 100;

  // Hero cooldown time. (Default value: 60 mins.)
  uint256 public coolHero = 3600;

  // The exp reward for fighting in this arena.
  uint32 public expReward = 100;

  // The Gold reward when fighting in this arena.
  uint256 public goldReward = 1000000000000000000;

  // Should this contract save the turn data?
  bool public isTurnDataSaved = true;

  // Last game&#39;s record of the player.
  mapping(address => PlayRecord) public addressToPlayRecord;

  // Additional information on last game&#39;s record of the player.
  mapping(address => TurnInfo) public addressToTurnInfo;

  // Random seed.
  uint32 private seed = 0;

  // Event that is fired when a player fights in this arena.
  event TryArena(
    address indexed _by,
    address indexed _against,
    bool _didWin
  );

  // @dev Get previous game record.
  function getPlayRecord(address _address)
    external view
    returns (uint32, address, uint256[4], uint32[8], uint32[8], uint32, uint256, uint8, uint8[8], uint8[24], uint32[24])
  {
    PlayRecord memory _p = addressToPlayRecord[_address];
    TurnInfo memory _t = addressToTurnInfo[_address];
    return (
      _p.initialSeed,
      _p.enemyAddress,
      _p.tokenIds,
      _p.unitClassIds,
      _p.unitLevels,
      _p.expReward,
      _p.goldReward,
      _t.turnLength,
      _t.turnOrder,
      _t.defenderList,
      _t.damageList
    );
  }

  // @dev Get previous game record.
  function getPlayRecordNoTurnData(address _address)
    external view
    returns (uint32, address, uint256[4], uint32[8], uint32[8], uint32, uint256)
  {
    PlayRecord memory _p = addressToPlayRecord[_address];
    return (
      _p.initialSeed,
      _p.enemyAddress,
      _p.tokenIds,
      _p.unitClassIds,
      _p.unitLevels,
      _p.expReward,
      _p.goldReward
      );
  }

  // @dev Set location id.
  function setLocationId(uint32 _value)
    onlyOwner
    public
  {
    locationId = _value;
  }

  // @dev Set cooldown of heroes entered this arena.
  function setCoolHero(uint32 _value)
    onlyOwner
    public
  {
    coolHero = _value;
  }

  // @dev Set the Exp given to the player for fighting in this arena.
  function setExpReward(uint32 _value)
    onlyOwner
    public
  {
    expReward = _value;
  }

  // @dev Set the Golds given to the player for fighting in this arena.
  function setGoldReward(uint256 _value)
    onlyOwner
    public
  {
    goldReward = _value;
  }

  // @dev Set wether the turn data saved or not.
  function setIsTurnDataSaved(bool _value)
    onlyOwner
    public
  {
    isTurnDataSaved = _value;
  }

  // @dev Constructor.
  function CryptoSagaArenaVer1(
    address _recordContractAddress,
    address _heroContractAddress,
    address _correctedHeroContractAddress,
    address _cardContractAddress,
    address _goldContractAddress,
    address _firstPlayerAddress,
    uint32 _locationId,
    uint256 _coolHero,
    uint32 _expReward,
    uint256 _goldReward,
    bool _isTurnDataSaved)
    public
  {
    recordContract = CryptoSagaArenaRecord(_recordContractAddress);
    heroContract = CryptoSagaHero(_heroContractAddress);
    correctedHeroContract = CryptoSagaCorrectedHeroStats(_correctedHeroContractAddress);
    cardContract = CryptoSagaCard(_cardContractAddress);
    goldContract = Gold(_goldContractAddress);

    // Save first player&#39;s record.
    // This is for preventing errors.
    PlayRecord memory _playRecord;
    _playRecord.initialSeed = seed;
    _playRecord.enemyAddress = _firstPlayerAddress;
    _playRecord.tokenIds[0] = 1;
    _playRecord.tokenIds[1] = 2;
    _playRecord.tokenIds[2] = 3;
    _playRecord.tokenIds[3] = 4;
    addressToPlayRecord[_firstPlayerAddress] = _playRecord;
    
    locationId = _locationId;
    coolHero = _coolHero;
    expReward = _expReward;
    goldReward = _goldReward;
    
    isTurnDataSaved = _isTurnDataSaved;
  }
  
  // @dev Enter this arena.
  function enterArena(uint256[4] _tokenIds, address _enemyAddress)
    whenNotPaused
    public
  {

    // Shouldn&#39;t fight against self.
    require(msg.sender != _enemyAddress);

    // Each hero should be with different ids.
    require(_tokenIds[0] == 0 || (_tokenIds[0] != _tokenIds[1] && _tokenIds[0] != _tokenIds[2] && _tokenIds[0] != _tokenIds[3]));
    require(_tokenIds[1] == 0 || (_tokenIds[1] != _tokenIds[0] && _tokenIds[1] != _tokenIds[2] && _tokenIds[1] != _tokenIds[3]));
    require(_tokenIds[2] == 0 || (_tokenIds[2] != _tokenIds[0] && _tokenIds[2] != _tokenIds[1] && _tokenIds[2] != _tokenIds[3]));
    require(_tokenIds[3] == 0 || (_tokenIds[3] != _tokenIds[0] && _tokenIds[3] != _tokenIds[1] && _tokenIds[3] != _tokenIds[2]));

    // Check ownership and availability of the heroes.
    require(checkOwnershipAndAvailability(msg.sender, _tokenIds));

    // The play record of the enemy should exist.
    // The check is done with the enemy&#39;s enemy address, because the default value of it will be address(0).
    require(addressToPlayRecord[_enemyAddress].enemyAddress != address(0));

    // Set seed.
    seed += uint32(now);

    // Define play record here.
    PlayRecord memory _playRecord;
    _playRecord.initialSeed = seed;
    _playRecord.enemyAddress = _enemyAddress;
    _playRecord.tokenIds[0] = _tokenIds[0];
    _playRecord.tokenIds[1] = _tokenIds[1];
    _playRecord.tokenIds[2] = _tokenIds[2];
    _playRecord.tokenIds[3] = _tokenIds[3];

    // The information that can give additional information.
    TurnInfo memory _turnInfo;

    // Step 1: Retrieve Hero information (0 ~ 3) & Enemy information (4 ~ 7).

    uint32[5][8] memory _unitStats; // Stats of units for given levels and class ids.
    uint8[2][8] memory _unitTypesAuras; // 0: Types of units for given levels and class ids. 1: Auras of units for given levels and class ids.

    // Retrieve deployed hero information.
    if (_tokenIds[0] != 0) {
      _playRecord.unitClassIds[0] = heroContract.getHeroClassId(_tokenIds[0]);
      (_playRecord.unitLevels[0], _turnInfo.originalExps[0], _unitStats[0], , ) = correctedHeroContract.getCorrectedStats(_tokenIds[0]);
      (, , , , _unitTypesAuras[0][0], , _unitTypesAuras[0][1], , , ) = heroContract.getClassInfo(_playRecord.unitClassIds[0]);
    }
    if (_tokenIds[1] != 0) {
      _playRecord.unitClassIds[1] = heroContract.getHeroClassId(_tokenIds[1]);
      (_playRecord.unitLevels[1], _turnInfo.originalExps[1], _unitStats[1], , ) = correctedHeroContract.getCorrectedStats(_tokenIds[1]);
      (, , , , _unitTypesAuras[1][0], , _unitTypesAuras[1][1], , , ) = heroContract.getClassInfo(_playRecord.unitClassIds[1]);
    }
    if (_tokenIds[2] != 0) {
      _playRecord.unitClassIds[2] = heroContract.getHeroClassId(_tokenIds[2]);
      (_playRecord.unitLevels[2], _turnInfo.originalExps[2], _unitStats[2], , ) = correctedHeroContract.getCorrectedStats(_tokenIds[2]);
      (, , , , _unitTypesAuras[2][0], , _unitTypesAuras[2][1], , , ) = heroContract.getClassInfo(_playRecord.unitClassIds[2]);
    }
    if (_tokenIds[3] != 0) {
      _playRecord.unitClassIds[3] = heroContract.getHeroClassId(_tokenIds[3]);
      (_playRecord.unitLevels[3], _turnInfo.originalExps[3], _unitStats[3], , ) = correctedHeroContract.getCorrectedStats(_tokenIds[3]);
      (, , , , _unitTypesAuras[3][0], , _unitTypesAuras[3][1], , , ) = heroContract.getClassInfo(_playRecord.unitClassIds[3]);
    }

    // Retrieve enemy information.
    PlayRecord memory _enemyPlayRecord = addressToPlayRecord[_enemyAddress];
    if (_enemyPlayRecord.tokenIds[0] != 0) {
      _playRecord.unitClassIds[4] = heroContract.getHeroClassId(_enemyPlayRecord.tokenIds[0]);
      (_playRecord.unitLevels[4], , _unitStats[4], , ) = correctedHeroContract.getCorrectedStats(_enemyPlayRecord.tokenIds[0]);
      (, , , , _unitTypesAuras[4][0], , _unitTypesAuras[4][1], , , ) = heroContract.getClassInfo(_playRecord.unitClassIds[4]);
    }
    if (_enemyPlayRecord.tokenIds[1] != 0) {
      _playRecord.unitClassIds[5] = heroContract.getHeroClassId(_enemyPlayRecord.tokenIds[1]);
      (_playRecord.unitLevels[5], , _unitStats[5], , ) = correctedHeroContract.getCorrectedStats(_enemyPlayRecord.tokenIds[1]);
      (, , , , _unitTypesAuras[5][0], , _unitTypesAuras[5][1], , , ) = heroContract.getClassInfo(_playRecord.unitClassIds[5]);
    }
    if (_enemyPlayRecord.tokenIds[2] != 0) {
      _playRecord.unitClassIds[6] = heroContract.getHeroClassId(_enemyPlayRecord.tokenIds[2]);
      (_playRecord.unitLevels[6], , _unitStats[6], , ) = correctedHeroContract.getCorrectedStats(_enemyPlayRecord.tokenIds[2]);
      (, , , , _unitTypesAuras[6][0], , _unitTypesAuras[6][1], , , ) = heroContract.getClassInfo(_playRecord.unitClassIds[6]);
    }
    if (_enemyPlayRecord.tokenIds[3] != 0) {
      _playRecord.unitClassIds[7] = heroContract.getHeroClassId(_enemyPlayRecord.tokenIds[3]);
      (_playRecord.unitLevels[7], , _unitStats[7], , ) = correctedHeroContract.getCorrectedStats(_enemyPlayRecord.tokenIds[3]);
      (, , , , _unitTypesAuras[7][0], , _unitTypesAuras[7][1], , , ) = heroContract.getClassInfo(_playRecord.unitClassIds[7]);
    }

    // Step 2. Run the battle logic.
    
    // Firstly, we need to assign the unit&#39;s turn order with AGLs of the units.
    uint32[8] memory _unitAGLs;
    for (uint8 i = 0; i < 8; i ++) {
      _unitAGLs[i] = _unitStats[i][2];
    }
    _turnInfo.turnOrder = getOrder(_unitAGLs);
    
    // Fight for 24 turns. (8 units x 3 rounds.)
    _turnInfo.turnLength = 24;
    for (i = 0; i < 24; i ++) {
      if (_unitStats[4][4] == 0 && _unitStats[5][4] == 0 && _unitStats[6][4] == 0 && _unitStats[7][4] == 0) {
        _turnInfo.turnLength = i;
        break;
      } else if (_unitStats[0][4] == 0 && _unitStats[1][4] == 0 && _unitStats[2][4] == 0 && _unitStats[3][4] == 0) {
        _turnInfo.turnLength = i;
        break;
      }
      
      var _slotId = _turnInfo.turnOrder[(i % 8)];
      if (_slotId < 4 && _tokenIds[_slotId] == 0) {
        // This means the slot is empty.
        // Defender should be default value.
        _turnInfo.defenderList[i] = 127;
      } else if (_unitStats[_slotId][4] == 0) {
        // This means the unit on this slot is dead.
        // Defender should be default value.
        _turnInfo.defenderList[i] = 128;
      } else {
        // 1) Check number of attack targets that are alive.
        uint8 _targetSlotId = 255;
        if (_slotId < 4) {
          if (_unitStats[4][4] > 0)
            _targetSlotId = 4;
          else if (_unitStats[5][4] > 0)
            _targetSlotId = 5;
          else if (_unitStats[6][4] > 0)
            _targetSlotId = 6;
          else if (_unitStats[7][4] > 0)
            _targetSlotId = 7;
        } else {
          if (_unitStats[0][4] > 0)
            _targetSlotId = 0;
          else if (_unitStats[1][4] > 0)
            _targetSlotId = 1;
          else if (_unitStats[2][4] > 0)
            _targetSlotId = 2;
          else if (_unitStats[3][4] > 0)
            _targetSlotId = 3;
        }
        
        // Target is the defender.
        _turnInfo.defenderList[i] = _targetSlotId;
        
        // Base damage. (Attacker&#39;s ATK * 1.5 - Defender&#39;s DEF).
        uint32 _damage = 10;
        if ((_unitStats[_slotId][0] * 150 / 100) > _unitStats[_targetSlotId][1])
          _damage = max((_unitStats[_slotId][0] * 150 / 100) - _unitStats[_targetSlotId][1], 10);
        else
          _damage = 10;

        // Check miss / success.
        if ((_unitStats[_slotId][3] * 150 / 100) > _unitStats[_targetSlotId][2]) {
          if (min(max(((_unitStats[_slotId][3] * 150 / 100) - _unitStats[_targetSlotId][2]), 75), 99) <= random(100, 0))
            _damage = _damage * 0;
        }
        else {
          if (75 <= random(100, 0))
            _damage = _damage * 0;
        }

        // Is the attack critical?
        if (_unitStats[_slotId][3] > _unitStats[_targetSlotId][3]) {
          if (min(max((_unitStats[_slotId][3] - _unitStats[_targetSlotId][3]), 5), 75) > random(100, 0))
            _damage = _damage * 150 / 100;
        }
        else {
          if (5 > random(100, 0))
            _damage = _damage * 150 / 100;
        }

        // Is attacker has the advantageous Type?
        if (_unitTypesAuras[_slotId][0] == 0 && _unitTypesAuras[_targetSlotId][0] == 1) // Fighter > Rogue
          _damage = _damage * 125 / 100;
        else if (_unitTypesAuras[_slotId][0] == 1 && _unitTypesAuras[_targetSlotId][0] == 2) // Rogue > Mage
          _damage = _damage * 125 / 100;
        else if (_unitTypesAuras[_slotId][0] == 2 && _unitTypesAuras[_targetSlotId][0] == 0) // Mage > Fighter
          _damage = _damage * 125 / 100;

        // Is attacker has the advantageous Aura?
        if (_unitTypesAuras[_slotId][1] == 0 && _unitTypesAuras[_targetSlotId][1] == 1) // Water > Fire
          _damage = _damage * 150 / 100;
        else if (_unitTypesAuras[_slotId][1] == 1 && _unitTypesAuras[_targetSlotId][1] == 2) // Fire > Nature
          _damage = _damage * 150 / 100;
        else if (_unitTypesAuras[_slotId][1] == 2 && _unitTypesAuras[_targetSlotId][1] == 0) // Nature > Water
          _damage = _damage * 150 / 100;
        else if (_unitTypesAuras[_slotId][1] == 3 && _unitTypesAuras[_targetSlotId][1] == 4) // Light > Darkness
          _damage = _damage * 150 / 100;
        else if (_unitTypesAuras[_slotId][1] == 4 && _unitTypesAuras[_targetSlotId][1] == 3) // Darkness > Light
          _damage = _damage * 150 / 100;
        
        // Apply damage so that reduce hp of defender.
        if(_unitStats[_targetSlotId][4] > _damage)
          _unitStats[_targetSlotId][4] -= _damage;
        else
          _unitStats[_targetSlotId][4] = 0;

        // Save damage to play record.
        _turnInfo.damageList[i] = _damage;
      }
    }
    
    // Step 3. Apply the result of this battle.

    // Set heroes deployed.
    if (_tokenIds[0] != 0)
      heroContract.deploy(_tokenIds[0], locationId, coolHero);
    if (_tokenIds[1] != 0)
      heroContract.deploy(_tokenIds[1], locationId, coolHero);
    if (_tokenIds[2] != 0)
      heroContract.deploy(_tokenIds[2], locationId, coolHero);
    if (_tokenIds[3] != 0)
      heroContract.deploy(_tokenIds[3], locationId, coolHero);

    uint8 _deadHeroes = 0;
    uint8 _deadEnemies = 0;

    // Check result.
    if (_unitStats[0][4] == 0)
      _deadHeroes ++;
    if (_unitStats[1][4] == 0)
      _deadHeroes ++;
    if (_unitStats[2][4] == 0)
      _deadHeroes ++;
    if (_unitStats[3][4] == 0)
      _deadHeroes ++;
    if (_unitStats[4][4] == 0)
      _deadEnemies ++;
    if (_unitStats[5][4] == 0)
      _deadEnemies ++;
    if (_unitStats[6][4] == 0)
      _deadEnemies ++;
    if (_unitStats[7][4] == 0)
      _deadEnemies ++;
      
    if (_deadEnemies > _deadHeroes) { // Win
      // Fire TryArena event.
      TryArena(msg.sender, _enemyAddress, true);
      
      // Give reward.
      (_playRecord.expReward, _playRecord.goldReward) = giveReward(_tokenIds, true, _turnInfo.originalExps);

      // Save the record.
      recordContract.updateRecord(msg.sender, _enemyAddress, true);
    }
    else if (_deadEnemies < _deadHeroes) { // Lose
      // Fire TryArena event.
      TryArena(msg.sender, _enemyAddress, false);

      // Rewards.
      (_playRecord.expReward, _playRecord.goldReward) = giveReward(_tokenIds, false, _turnInfo.originalExps);

      // Save the record.
      recordContract.updateRecord(msg.sender, _enemyAddress, false);
    }
    else { // Draw
      // Fire TryArena event.
      TryArena(msg.sender, _enemyAddress, false);

      // Rewards.
      (_playRecord.expReward, _playRecord.goldReward) = giveReward(_tokenIds, false, _turnInfo.originalExps);
    }

    // Save the result of this gameplay.
    addressToPlayRecord[msg.sender] = _playRecord;

    // Save the turn data.
    // This is commented as this information can be reconstructed with intitial seed and date time.
    // By commenting this, we can reduce about 400k gas.
    if (isTurnDataSaved) {
      addressToTurnInfo[msg.sender] = _turnInfo;
    }
  }

  // @dev Check ownership.
  function checkOwnershipAndAvailability(address _playerAddress, uint256[4] _tokenIds)
    private view
    returns(bool)
  {
    if ((_tokenIds[0] == 0 || heroContract.ownerOf(_tokenIds[0]) == _playerAddress) && (_tokenIds[1] == 0 || heroContract.ownerOf(_tokenIds[1]) == _playerAddress) && (_tokenIds[2] == 0 || heroContract.ownerOf(_tokenIds[2]) == _playerAddress) && (_tokenIds[3] == 0 || heroContract.ownerOf(_tokenIds[3]) == _playerAddress)) {
      
      // Retrieve avail time of heroes.
      uint256[4] memory _heroAvailAts;
      if (_tokenIds[0] != 0)
        ( , , , , , _heroAvailAts[0], , , ) = heroContract.getHeroInfo(_tokenIds[0]);
      if (_tokenIds[1] != 0)
        ( , , , , , _heroAvailAts[1], , , ) = heroContract.getHeroInfo(_tokenIds[1]);
      if (_tokenIds[2] != 0)
        ( , , , , , _heroAvailAts[2], , , ) = heroContract.getHeroInfo(_tokenIds[2]);
      if (_tokenIds[3] != 0)
        ( , , , , , _heroAvailAts[3], , , ) = heroContract.getHeroInfo(_tokenIds[3]);

      if (_heroAvailAts[0] <= now && _heroAvailAts[1] <= now && _heroAvailAts[2] <= now && _heroAvailAts[3] <= now) {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  // @dev Give rewards.
  function giveReward(uint256[4] _heroes, bool _didWin, uint32[4] _originalExps)
    private
    returns (uint32 expRewardGiven, uint256 goldRewardGiven)
  {
    if (!_didWin) {
      // In case lost.
      // Give baseline gold reward.
      goldRewardGiven = goldReward / 10;
      expRewardGiven = expReward / 5;
    } else {
      // In case win.
      goldRewardGiven = goldReward;
      expRewardGiven = expReward;
    }

    // Give reward Gold.
    goldContract.mint(msg.sender, goldRewardGiven);
    
    // Give reward EXP.
    if(_heroes[0] != 0)
      heroContract.addExp(_heroes[0], uint32(2)**32 - _originalExps[0] + expRewardGiven);
    if(_heroes[1] != 0)
      heroContract.addExp(_heroes[1], uint32(2)**32 - _originalExps[1] + expRewardGiven);
    if(_heroes[2] != 0)
      heroContract.addExp(_heroes[2], uint32(2)**32 - _originalExps[2] + expRewardGiven);
    if(_heroes[3] != 0)
      heroContract.addExp(_heroes[3], uint32(2)**32 - _originalExps[3] + expRewardGiven);
  }

  // @dev Return a pseudo random number between lower and upper bounds
  function random(uint32 _upper, uint32 _lower)
    private
    returns (uint32)
  {
    require(_upper > _lower);

    seed = seed % uint32(1103515245) + 12345;
    return seed % (_upper - _lower) + _lower;
  }

  // @dev Retreive order based on given array _by.
  function getOrder(uint32[8] _by)
    private pure
    returns (uint8[8])
  {
    uint8[8] memory _order = [uint8(0), 1, 2, 3, 4, 5, 6, 7];
    for (uint8 i = 0; i < 8; i ++) {
      for (uint8 j = i + 1; j < 8; j++) {
        if (_by[i] < _by[j]) {
          uint32 tmp1 = _by[i];
          _by[i] = _by[j];
          _by[j] = tmp1;
          uint8 tmp2 = _order[i];
          _order[i] = _order[j];
          _order[j] = tmp2;
        }
      }
    }
    return _order;
  }

  // @return Bigger value of two uint32s.
  function max(uint32 _value1, uint32 _value2)
    private pure
    returns (uint32)
  {
    if(_value1 >= _value2)
      return _value1;
    else
      return _value2;
  }

  // @return Bigger value of two uint32s.
  function min(uint32 _value1, uint32 _value2)
    private pure
    returns (uint32)
  {
    if(_value2 >= _value1)
      return _value1;
    else
      return _value2;
  }

  // @return Square root of the given value.
  function sqrt(uint32 _value) 
    private pure
    returns (uint32) 
  {
    uint32 z = (_value + 1) / 2;
    uint32 y = _value;
    while (z < y) {
      y = z;
      z = (_value / z + z) / 2;
    }
    return y;
  }

}