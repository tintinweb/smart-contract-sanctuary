pragma solidity ^0.4.24;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
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

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


library SafeMath16 {
  function mul(uint16 a, uint16 b) internal pure returns (uint16) {
    if (a == 0) {
      return 0;
    }
    uint16 c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint16 a, uint16 b) internal pure returns (uint16) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint16 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn’t hold
    return c;
  }
  function sub(uint16 a, uint16 b) internal pure returns (uint16) {
    assert(b <= a);
    return a - b;
  }
  function add(uint16 a, uint16 b) internal pure returns (uint16) {
    uint16 c = a + b;
    assert(c >= a);
    return c;
  }
}








/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}



/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}
/*****************************************************************
 * Core contract of the Million Dollar Decentralized Application *
 *****************************************************************/






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







/**
 * @title Contracts that should not own Ether
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="c6b4a3aba5a986f4">[email&#160;protected]</a>π.com>
 * @dev This tries to block incoming ether to prevent accidental loss of Ether. Should Ether end up
 * in the contract, it will allow the owner to reclaim this Ether.
 * @notice Ether can still be sent to this contract by:
 * calling functions labeled `payable`
 * `selfdestruct(contract_address)`
 * mining directly to the contract address
 */
contract HasNoEther is Ownable {

  /**
  * @dev Constructor that rejects incoming Ether
  * The `payable` flag is added so we can access `msg.value` without compiler warning. If we
  * leave out payable, then Solidity will allow inheriting contracts to implement a payable
  * constructor. By doing it this way we prevent a payable constructor from working. Alternatively
  * we could use assembly to access msg.value.
  */
  constructor() public payable {
    require(msg.value == 0);
  }

  /**
   * @dev Disallows direct send by setting a default function without the `payable` flag.
   */
  function() external {
  }

  /**
   * @dev Transfer all Ether held by the contract to the owner.
   */
  function reclaimEther() external onlyOwner {
    owner.transfer(address(this).balance);
  }
}








/**
 * @title Contracts that should be able to recover tokens
 * @author SylTi
 * @dev This allow a contract to recover any ERC20 token received in a contract by transferring the balance to the contract owner.
 * This will prevent any accidental loss of tokens.
 */
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

  /**
   * @dev Reclaim all ERC20Basic compatible tokens
   * @param _token ERC20Basic The address of the token contract
   */
  function reclaimToken(ERC20Basic _token) external onlyOwner {
    uint256 balance = _token.balanceOf(this);
    _token.safeTransfer(owner, balance);
  }

}















/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
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
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}




/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


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

}




/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}




/**
 * @title MDAPPToken
 * @dev Token for the Million Dollar Decentralized Application (MDAPP).
 * Once a holder uses it to claim pixels the appropriate tokens are burned (1 Token <=> 10x10 pixel).
 * If one releases his pixels new tokens are generated and credited to ones balance. Therefore, supply will
 * vary between 0 and 10,000 tokens.
 * Tokens are transferable once minting has finished.
 * @dev Owned by MDAPP.sol
 */
contract MDAPPToken is MintableToken {
  using SafeMath16 for uint16;
  using SafeMath for uint256;

  string public constant name = "MillionDollarDapp";
  string public constant symbol = "MDAPP";
  uint8 public constant decimals = 0;

  mapping (address => uint16) locked;

  bool public forceTransferEnable = false;

  /*********************************************************
   *                                                       *
   *                       Events                          *
   *                                                       *
   *********************************************************/

  // Emitted when owner force-allows transfers of tokens.
  event AllowTransfer();

  /*********************************************************
   *                                                       *
   *                      Modifiers                        *
   *                                                       *
   *********************************************************/

  modifier hasLocked(address _account, uint16 _value) {
    require(_value <= locked[_account], "Not enough locked tokens available.");
    _;
  }

  modifier hasUnlocked(address _account, uint16 _value) {
    require(balanceOf(_account).sub(uint256(locked[_account])) >= _value, "Not enough unlocked tokens available.");
    _;
  }

  /**
   * @dev Checks whether it can transfer or otherwise throws.
   */
  modifier canTransfer(address _sender, uint256 _value) {
    require(_value <= transferableTokensOf(_sender), "Not enough unlocked tokens available.");
    _;
  }


  /*********************************************************
   *                                                       *
   *                Limited Transfer Logic                 *
   *            Taken from openzeppelin 1.3.0              *
   *                                                       *
   *********************************************************/

  function lockToken(address _account, uint16 _value) onlyOwner hasUnlocked(_account, _value) public {
    locked[_account] = locked[_account].add(_value);
  }

  function unlockToken(address _account, uint16 _value) onlyOwner hasLocked(_account, _value) public {
    locked[_account] = locked[_account].sub(_value);
  }

  /**
   * @dev Checks modifier and allows transfer if tokens are not locked.
   * @param _to The address that will receive the tokens.
   * @param _value The amount of tokens to be transferred.
   */
  function transfer(address _to, uint256 _value) canTransfer(msg.sender, _value) public returns (bool) {
    return super.transfer(_to, _value);
  }

  /**
  * @dev Checks modifier and allows transfer if tokens are not locked.
  * @param _from The address that will send the tokens.
  * @param _to The address that will receive the tokens.
  * @param _value The amount of tokens to be transferred.
  */
  function transferFrom(address _from, address _to, uint256 _value) canTransfer(_from, _value) public returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  /**
   * @dev Allow the holder to transfer his tokens only if every token in
   * existence has already been distributed / minting is finished.
   * Tokens which are locked for a claimed space cannot be transferred.
   */
  function transferableTokensOf(address _holder) public view returns (uint16) {
    if (!mintingFinished && !forceTransferEnable) return 0;

    return uint16(balanceOf(_holder)).sub(locked[_holder]);
  }

  /**
   * @dev Get the number of pixel-locked tokens.
   */
  function lockedTokensOf(address _holder) public view returns (uint16) {
    return locked[_holder];
  }

  /**
   * @dev Get the number of unlocked tokens usable for claiming pixels.
   */
  function unlockedTokensOf(address _holder) public view returns (uint256) {
    return balanceOf(_holder).sub(uint256(locked[_holder]));
  }

  // Allow transfer of tokens even if minting is not yet finished.
  function allowTransfer() onlyOwner public {
    require(forceTransferEnable == false, &#39;Transfer already force-allowed.&#39;);

    forceTransferEnable = true;
    emit AllowTransfer();
  }
}




/**
 * @title MDAPP
 */
contract MDAPP is Ownable, HasNoEther, CanReclaimToken {
  using SafeMath for uint256;
  using SafeMath16 for uint16;

  // The tokens contract.
  MDAPPToken public token;

  // The sales contracts address. Only it is allowed to to call the public mint function.
  address public sale;

  // When are presale participants allowed to place ads?
  uint256 public presaleAdStart;

  // When are all token owners allowed to place ads?
  uint256 public allAdStart;

  // Quantity of tokens bought during presale.
  mapping (address => uint16) presales;

  // Indicates whether a 10x10px block is claimed or not.
  bool[80][125] grid;

  // Struct that represents an ad.
  struct Ad {
    address owner;
    Rect rect;
  }

  // Struct describing an rectangle area.
  struct Rect {
    uint16 x;
    uint16 y;
    uint16 width;
    uint16 height;
  }

  // Don&#39;t store ad details on blockchain. Use events as storage as they are significantly cheaper.
  // ads are stored in an array, the id of an ad is its index in this array.
  Ad[] ads;

  // The following holds a list of currently active ads (without holes between the indexes)
  uint256[] adIds;

  // Holds the mapping from adID to its index in the above adIds array. If an ad gets released, we know which index to
  // delete and being filled with the last element instead.
  mapping (uint256 => uint256) adIdToIndex;


  /*********************************************************
   *                                                       *
   *                       Events                          *
   *                                                       *
   *********************************************************/

  /*
   * Event for claiming pixel blocks.
   * @param id ID of the new ad
   * @param owner Who owns the used tokens
   * @param x Upper left corner x coordinate
   * @param y Upper left corner y coordinate
   * @param width Width of the claimed area
   * @param height Height of the claimed area
   */
  event Claim(uint256 indexed id, address indexed owner, uint16 x, uint16 y, uint16 width, uint16 height);

  /*
   * Event for releasing pixel blocks.
   * @param id ID the fading ad
   * @param owner Who owns the claimed blocks
   */
  event Release(uint256 indexed id, address indexed owner);

  /*
   * Event for editing an ad.
   * @param id ID of the ad
   * @param owner Who owns the ad
   * @param link A link
   * @param title Title of the ad
   * @param text Description of the ad
   * @param NSFW Whether the ad is safe for work
   * @param digest IPFS hash digest
   * @param hashFunction IPFS hash function
   * @param size IPFS length of digest
   * @param storageEngine e.g. ipfs or swrm (swarm)
   */
  event EditAd(uint256 indexed id, address indexed owner, string link, string title, string text, string contact, bool NSFW, bytes32 indexed digest, bytes2 hashFunction, uint8 size, bytes4 storageEngine);

  event ForceNSFW(uint256 indexed id);


  /*********************************************************
   *                                                       *
   *                      Modifiers                        *
   *                                                       *
   *********************************************************/

  modifier coordsValid(uint16 _x, uint16 _y, uint16 _width, uint16 _height) {
    require((_x + _width - 1) < 125, "Invalid coordinates.");
    require((_y + _height - 1) < 80, "Invalid coordinates.");

    _;
  }

  modifier onlyAdOwner(uint256 _id) {
    require(ads[_id].owner == msg.sender, "Access denied.");

    _;
  }

  modifier enoughTokens(uint16 _width, uint16 _height) {
    require(uint16(token.unlockedTokensOf(msg.sender)) >= _width.mul(_height), "Not enough unlocked tokens available.");

    _;
  }

  modifier claimAllowed(uint16 _width, uint16 _height) {
    require(_width > 0 &&_width <= 125 && _height > 0 && _height <= 80, "Invalid dimensions.");
    require(now >= presaleAdStart, "Claim period not yet started.");

    if (now < allAdStart) {
      // Sender needs enough presale tokens to claim at this point.
      uint16 tokens = _width.mul(_height);
      require(presales[msg.sender] >= tokens, "Not enough unlocked presale tokens available.");

      presales[msg.sender] = presales[msg.sender].sub(tokens);
    }

    _;
  }

  modifier onlySale() {
    require(msg.sender == sale);
    _;
  }

  modifier adExists(uint256 _id) {
    uint256 index = adIdToIndex[_id];
    require(adIds[index] == _id, "Ad does not exist.");

    _;
  }

  /*********************************************************
   *                                                       *
   *                   Initialization                      *
   *                                                       *
   *********************************************************/

  constructor(uint256 _presaleAdStart, uint256 _allAdStart, address _token) public {
    require(_presaleAdStart >= now);
    require(_allAdStart > _presaleAdStart);

    presaleAdStart = _presaleAdStart;
    allAdStart = _allAdStart;
    token = MDAPPToken(_token);
  }

  function setMDAPPSale(address _mdappSale) onlyOwner external {
    require(sale == address(0));
    sale = _mdappSale;
  }

  /*********************************************************
   *                                                       *
   *                       Logic                           *
   *                                                       *
   *********************************************************/

  // Proxy function to pass minting from sale contract to token contract.
  function mint(address _beneficiary, uint256 _tokenAmount, bool isPresale) onlySale external {
    if (isPresale) {
      presales[_beneficiary] = presales[_beneficiary].add(uint16(_tokenAmount));
    }
    token.mint(_beneficiary, _tokenAmount);
  }

  // Proxy function to pass finishMinting() from sale contract to token contract.
  function finishMinting() onlySale external {
    token.finishMinting();
  }


  // Public function proxy to forward single parameters as a struct.
  function claim(uint16 _x, uint16 _y, uint16 _width, uint16 _height)
    claimAllowed(_width, _height)
    coordsValid(_x, _y, _width, _height)
    external returns (uint)
  {
    Rect memory rect = Rect(_x, _y, _width, _height);
    return claimShortParams(rect);
  }

  // Claims pixels and requires to have the sender enough unlocked tokens.
  // Has a modifier to take some of the "stack burden" from the proxy function.
  function claimShortParams(Rect _rect)
    enoughTokens(_rect.width, _rect.height)
    internal returns (uint id)
  {
    token.lockToken(msg.sender, _rect.width.mul(_rect.height));

    // Check affected pixelblocks.
    for (uint16 i = 0; i < _rect.width; i++) {
      for (uint16 j = 0; j < _rect.height; j++) {
        uint16 x = _rect.x.add(i);
        uint16 y = _rect.y.add(j);

        if (grid[x][y]) {
          revert("Already claimed.");
        }

        // Mark block as claimed.
        grid[x][y] = true;
      }
    }

    // Create placeholder ad.
    id = createPlaceholderAd(_rect);

    emit Claim(id, msg.sender, _rect.x, _rect.y, _rect.width, _rect.height);
    return id;
  }

  // Delete an ad, unclaim pixelblocks and unlock tokens.
  function release(uint256 _id) adExists(_id) onlyAdOwner(_id) external {
    uint16 tokens = ads[_id].rect.width.mul(ads[_id].rect.height);

    // Mark blocks as unclaimed.
    for (uint16 i = 0; i < ads[_id].rect.width; i++) {
      for (uint16 j = 0; j < ads[_id].rect.height; j++) {
        uint16 x = ads[_id].rect.x.add(i);
        uint16 y = ads[_id].rect.y.add(j);

        // Mark block as unclaimed.
        grid[x][y] = false;
      }
    }

    // Delete ad
    delete ads[_id];
    // Reorganize index array and map
    uint256 key = adIdToIndex[_id];
    // Fill gap with last element of adIds
    adIds[key] = adIds[adIds.length - 1];
    // Update adIdToIndex
    adIdToIndex[adIds[key]] = key;
    // Decrease length of adIds array by 1
    adIds.length--;

    // Unlock tokens
    if (now < allAdStart) {
      // The ad must have locked presale tokens.
      presales[msg.sender] = presales[msg.sender].add(tokens);
    }
    token.unlockToken(msg.sender, tokens);

    emit Release(_id, msg.sender);
  }

  // The image must be an URL either of bzz, ipfs or http(s).
  function editAd(uint _id, string _link, string _title, string _text, string _contact, bool _NSFW, bytes32 _digest, bytes2 _hashFunction, uint8 _size, bytes4 _storageEnginge) adExists(_id) onlyAdOwner(_id) public {
    emit EditAd(_id, msg.sender, _link, _title, _text, _contact, _NSFW, _digest, _hashFunction, _size,  _storageEnginge);
  }

  // Allows contract owner to set the NSFW flag for a given ad.
  function forceNSFW(uint256 _id) onlyOwner adExists(_id) external {
    emit ForceNSFW(_id);
  }

  // Helper function for claim() to avoid a deep stack.
  function createPlaceholderAd(Rect _rect) internal returns (uint id) {
    Ad memory ad = Ad(msg.sender, _rect);
    id = ads.push(ad) - 1;
    uint256 key = adIds.push(id) - 1;
    adIdToIndex[id] = key;
    return id;
  }

  // Returns remaining balance of tokens purchased during presale period qualifying for earlier claims.
  function presaleBalanceOf(address _holder) public view returns (uint16) {
    return presales[_holder];
  }

  // Returns all currently active adIds.
  function getAdIds() external view returns (uint256[]) {
    return adIds;
  }

  /*********************************************************
   *                                                       *
   *                       Other                           *
   *                                                       *
   *********************************************************/

  // Allow transfer of tokens even if minting is not yet finished.
  function allowTransfer() onlyOwner external {
    token.allowTransfer();
  }
}