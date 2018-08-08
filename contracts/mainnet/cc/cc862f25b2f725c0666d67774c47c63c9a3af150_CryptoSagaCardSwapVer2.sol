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
 * @title CryptoSagaCardSwapVer2
 * @dev This directly summons hero.
 */
contract CryptoSagaCardSwapVer2 is CryptoSagaCardSwap, Pausable{

  // Eth will be sent to this wallet.
  address public wallet;

  // The hero contract.
  CryptoSagaHero public heroContract;

  // Gold contract.
  Gold public goldContract;

  // Eth-Summon price.
  uint256 public ethPrice = 20000000000000000; // 0.02 eth.

  // Gold-Summon price.
  uint256 public goldPrice = 100000000000000000000; // 100 G. Should worth around 0.00004 eth at launch.

  // Mileage Point Summon price.
  uint256 public mileagePointPrice = 100;

  // Blacklisted heroes.
  // This is needed in order to protect players, in case there exists any hero with critical issues.
  // We promise we will use this function carefully, and this won&#39;t be used for balancing the OP heroes.
  mapping(uint32 => bool) public blackList;

  // Mileage points of each player.
  mapping(address => uint256) public addressToMileagePoint;

  // Last timestamp of summoning a free hero.
  mapping(address => uint256) public addressToFreeSummonTimestamp;

  // Random seed.
  uint32 private seed = 0;

  // @dev Get the mileage points of given address.
  function getMileagePoint(address _address)
    public view
    returns (uint256)
  {
    return addressToMileagePoint[_address];
  }

  // @dev Get the summon timestamp of given address.
  function getFreeSummonTimestamp(address _address)
    public view
    returns (uint256)
  {
    return addressToFreeSummonTimestamp[_address];
  }

  // @dev Set the price of summoning a hero with Eth.
  function setEthPrice(uint256 _value)
    onlyOwner
    public
  {
    ethPrice = _value;
  }

  // @dev Set the price of summoning a hero with Gold.
  function setGoldPrice(uint256 _value)
    onlyOwner
    public
  {
    goldPrice = _value;
  }

  // @dev Set the price of summong a hero with Mileage Points.
  function setMileagePointPrice(uint256 _value)
    onlyOwner
    public
  {
    mileagePointPrice = _value;
  }

  // @dev Set blacklist.
  function setBlacklist(uint32 _classId, bool _value)
    onlyOwner
    public
  {
    blackList[_classId] = _value;
  }

  // @dev Increment mileage points.
  function addMileagePoint(address _beneficiary, uint256 _point)
    onlyOwner
    public
  {
    require(_beneficiary != address(0));

    addressToMileagePoint[_beneficiary] += _point;
  }

  // @dev Contructor.
  function CryptoSagaCardSwapVer2(address _heroAddress, address _goldAddress, address _cardAddress, address _walletAddress)
    public
  {
    require(_heroAddress != address(0));
    require(_goldAddress != address(0));
    require(_cardAddress != address(0));
    require(_walletAddress != address(0));
    
    wallet = _walletAddress;

    heroContract = CryptoSagaHero(_heroAddress);
    goldContract = Gold(_goldAddress);
    setCardContract(_cardAddress);
  }

  // @dev Swap a card for a hero.
  function swapCardForReward(address _by, uint8 _rank)
    onlyCard
    whenNotPaused
    public
    returns (uint256)
  {
    // This is becaue we need to use tx.origin here.
    // _by should be the beneficiary, but due to the bug that is already exist with CryptoSagaCard.sol,
    // tx.origin is used instead of _by.
    require(tx.origin != _by && tx.origin != msg.sender);

    // Get value 0 ~ 9999.
    var _randomValue = random(10000, 0);

    // We hard-code this in order to give credential to the players. 
    uint8 _heroRankToMint = 0; 

    if (_rank == 0) { // Origin Card. 85% Heroic, 15% Legendary.
      if (_randomValue < 8500) {
        _heroRankToMint = 3;
      } else {
        _heroRankToMint = 4;
      }
    } else if (_rank == 3) { // Dungeon Chest card.
      if (_randomValue < 6500) {
        _heroRankToMint = 1;
      } else if (_randomValue < 9945) {
        _heroRankToMint = 2;
      }  else if (_randomValue < 9995) {
        _heroRankToMint = 3;
      } else {
        _heroRankToMint = 4;
      }
    } else { // Do nothing here.
      _heroRankToMint = 0;
    }
    
    // Summon the hero.
    return summonHero(tx.origin, _heroRankToMint);

  }

  // @dev Pay with Eth.
  function payWithEth(uint256 _amount, address _referralAddress)
    whenNotPaused
    public
    payable
  {
    require(msg.sender != address(0));
    // Referral address shouldn&#39;t be the same address.
    require(msg.sender != _referralAddress);
    // Up to 5 purchases at once.
    require(_amount >= 1 && _amount <= 5);

    var _priceOfBundle = ethPrice * _amount;

    require(msg.value >= _priceOfBundle);

    // Send the raised eth to the wallet.
    wallet.transfer(_priceOfBundle);

    for (uint i = 0; i < _amount; i ++) {
      // Get value 0 ~ 9999.
      var _randomValue = random(10000, 0);
      
      // We hard-code this in order to give credential to the players. 
      uint8 _heroRankToMint = 0; 

      if (_randomValue < 5000) {
        _heroRankToMint = 1;
      } else if (_randomValue < 9550) {
        _heroRankToMint = 2;
      }  else if (_randomValue < 9950) {
        _heroRankToMint = 3;
      } else {
        _heroRankToMint = 4;
      }

      // Summon the hero.
      summonHero(msg.sender, _heroRankToMint);

      // In case there exists referral address...
      if (_referralAddress != address(0)) {
        // Add mileage to the referral address.
        addressToMileagePoint[_referralAddress] += 5;
        addressToMileagePoint[msg.sender] += 3;
      }
    }
  }

  // @dev Pay with Gold.
  function payWithGold(uint256 _amount)
    whenNotPaused
    public
  {
    require(msg.sender != address(0));
    // Up to 5 purchases at once.
    require(_amount >= 1 && _amount <= 5);

    var _priceOfBundle = goldPrice * _amount;

    require(goldContract.allowance(msg.sender, this) >= _priceOfBundle);

    if (goldContract.transferFrom(msg.sender, this, _priceOfBundle)) {
      for (uint i = 0; i < _amount; i ++) {
        // Get value 0 ~ 9999.
        var _randomValue = random(10000, 0);
        
        // We hard-code this in order to give credential to the players. 
        uint8 _heroRankToMint = 0; 

        if (_randomValue < 3000) {
          _heroRankToMint = 0;
        } else if (_randomValue < 7500) {
          _heroRankToMint = 1;
        } else if (_randomValue < 9945) {
          _heroRankToMint = 2;
        } else if (_randomValue < 9995) {
          _heroRankToMint = 3;
        } else {
          _heroRankToMint = 4;
        }

        // Summon the hero.
        summonHero(msg.sender, _heroRankToMint);
      }
    }
  }

  // @dev Pay with Mileage.
  function payWithMileagePoint(uint256 _amount)
    whenNotPaused
    public
  {
    require(msg.sender != address(0));
    // Up to 5 purchases at once.
    require(_amount >= 1 && _amount <= 5);

    var _priceOfBundle = mileagePointPrice * _amount;

    require(addressToMileagePoint[msg.sender] >= _priceOfBundle);

    // Decrement mileage point.
    addressToMileagePoint[msg.sender] -= _priceOfBundle;

    for (uint i = 0; i < _amount; i ++) {
      // Get value 0 ~ 9999.
      var _randomValue = random(10000, 0);
      
      // We hard-code this in order to give credential to the players. 
      uint8 _heroRankToMint = 0; 

      if (_randomValue < 5000) {
        _heroRankToMint = 1;
      } else if (_randomValue < 9050) {
        _heroRankToMint = 2;
      }  else if (_randomValue < 9950) {
        _heroRankToMint = 3;
      } else {
        _heroRankToMint = 4;
      }

      // Summon the hero.
      summonHero(msg.sender, _heroRankToMint);
    }
  }

  // @dev Free daily summon.
  function payWithDailyFreePoint()
    whenNotPaused
    public
  {
    require(msg.sender != address(0));
    // Only once a day.
    require(now > addressToFreeSummonTimestamp[msg.sender] + 1 days);
    addressToFreeSummonTimestamp[msg.sender] = now;

    // Get value 0 ~ 9999.
    var _randomValue = random(10000, 0);
    
    // We hard-code this in order to give credential to the players. 
    uint8 _heroRankToMint = 0; 

    if (_randomValue < 5500) {
      _heroRankToMint = 0;
    } else if (_randomValue < 9850) {
      _heroRankToMint = 1;
    } else {
      _heroRankToMint = 2;
    }

    // Summon the hero.
    summonHero(msg.sender, _heroRankToMint);

  }

  // @dev Summon a hero.
  // 0: Common, 1: Uncommon, 2: Rare, 3: Heroic, 4: Legendary
  function summonHero(address _to, uint8 _heroRankToMint)
    private
    returns (uint256)
  {

    // Get the list of hero classes.
    uint32 _numberOfClasses = heroContract.numberOfHeroClasses();
    uint32[] memory _candidates = new uint32[](_numberOfClasses);
    uint32 _count = 0;
    for (uint32 i = 0; i < _numberOfClasses; i ++) {
      if (heroContract.getClassRank(i) == _heroRankToMint && blackList[i] != true) {
        _candidates[_count] = i;
        _count++;
      }
    }

    require(_count != 0);
    
    return heroContract.mint(_to, _candidates[random(_count, 0)]);
  }

  // @dev return a pseudo random number between lower and upper bounds
  function random(uint32 _upper, uint32 _lower)
    private
    returns (uint32)
  {
    require(_upper > _lower);

    seed = uint32(keccak256(keccak256(block.blockhash(block.number - 1), seed), now));
    return seed % (_upper - _lower) + _lower;
  }

}