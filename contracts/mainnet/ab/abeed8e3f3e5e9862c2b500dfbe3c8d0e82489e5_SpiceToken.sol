pragma solidity ^0.4.13;

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

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
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract LimitedTransferToken is ERC20 {

  /**
   * @dev Checks whether it can transfer or otherwise throws.
   */
  modifier canTransfer(address _sender, uint256 _value) {
   require(_value <= transferableTokens(_sender, uint64(now)));
   _;
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
   * @dev Default transferable tokens function returns all tokens for a holder (no limit).
   * @dev Overwriting transferableTokens(address holder, uint64 time) is the way to provide the
   * specific logic for limiting token transferability for a holder over time.
   */
  function transferableTokens(address holder, uint64 /*time*/) public constant returns (uint256) {
    return balanceOf(holder);
  }
}

library Math {
  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

  /**
   * @dev Reclaim all ERC20Basic compatible tokens
   * @param token ERC20Basic The address of the token contract
   */
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
  }

}

contract HasNoEther is Ownable {

  /**
  * @dev Constructor that rejects incoming Ether
  * @dev The `payable` flag is added so we can access `msg.value` without compiler warning. If we
  * leave out payable, then Solidity will allow inheriting contracts to implement a payable
  * constructor. By doing it this way we prevent a payable constructor from working. Alternatively
  * we could use assembly to access msg.value.
  */
  function HasNoEther() payable {
    require(msg.value == 0);
  }

  /**
   * @dev Disallows direct send by settings a default function without the `payable` flag.
   */
  function() external {
  }

  /**
   * @dev Transfer all Ether held by the contract to the owner.
   */
  function reclaimEther() external onlyOwner {
    assert(owner.send(this.balance));
  }
}

contract HasNoTokens is CanReclaimToken {

 /**
  * @dev Reject all ERC23 compatible tokens
    **/
  function tokenFallback(address /*from_*/, uint256 /*value_*/, bytes /*data_*/) external {
    revert();
  }

}

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

library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
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
      require(_value == 0 || allowed[msg.sender][_spender] == 0);
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
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
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

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract RegulatedToken is StandardToken, PausableToken, LimitedTransferToken, HasNoEther, HasNoTokens {

    using SafeMath for uint256;
    using SafeERC20 for ERC20Basic;
    uint256 constant MAX_LOCKS_PER_ADDRESS = 20;

    enum RedeemReason{RegulatoryRedemption, Buyback, Other}
    enum LockReason{PreICO, Vesting, USPerson, FundOriginated, Other}

    struct TokenLock {
        uint64 id;
        LockReason reason;
        uint256 value;
        uint64 autoReleaseTime;       //May be 0, for no release time
    }

    struct TokenRedemption {
        uint64 redemptionId;
        RedeemReason reason;
        uint256 value;
    }

    uint256 public totalInactive;
    uint64 private lockCounter = 1;

    //token admins
    mapping(address => bool) private admins;

    //locks
    mapping(address => TokenLock[]) private locks;

    //burn wallets
    mapping(address => bool) private burnWallets;

    //Redemptions made for users
    mapping(address => TokenRedemption[]) private tokenRedemptions;

    event Issued(address indexed to, uint256 value, uint256 valueLocked);
    event Locked(address indexed who, uint256 value, LockReason reason, uint releaseTime, uint64 lockId);
    event Unlocked(address indexed who, uint256 value, uint64 lockId);
    event AddedBurnWallet(address indexed burnWallet);
    event Redeemed(address indexed from, address indexed burnWallet, uint256 value, RedeemReason reason, uint64 indexed redemptionId);
    event Burned(address indexed burnWallet, uint256 value);
    event Destroyed();
    event AdminAdded(address admin);
    event AdminRemoved(address admin);



    /**
    * @dev destroys the token
    * Only works from the owner, and when the total balance of all users is 0 (nobody has tokens).
    */
    function destroy() onlyOwner public {
        require(totalSupply == 0);
        Destroyed();
        selfdestruct(owner);
    }

    /*******************************
        CONTRACT ADMIN

        The contract can have 0 or more admins
        some functions are accessible on the admin level rather than the owner level
        the owner is always an admin
    ********************************/

    function addAdmin(address _address) onlyOwner public{
        admins[_address] = true;
        AdminAdded(_address);
    }

    function removeAdmin(address _address) onlyOwner public{
        admins[_address] = false;
        AdminRemoved(_address);
    }
    /**
    * @dev Throws if called by any account other than an admin.
    */
    modifier onlyAdmin() {
        require(msg.sender == owner || admins[msg.sender] == true);
        _;
    }


    /******************************
         TOKEN ISSUING
     *******************************/


    /**
    * @dev Issues unlocked tokens
    * @param _to address The address which is going to receive the newly issued tokens
    * @param _value uint256 the value of tokens to issue
    * @return true if successful
    */

    function issueTokens(address _to, uint256 _value) onlyAdmin public returns (bool){
        issueTokensWithLocking(_to, _value, 0, LockReason.Other, 0);
    }

    /**
    * @dev Issuing tokens from the fund
    * @param _to address The address which is going to receive the newly issued tokens
    * @param _value uint256 the value of tokens to issue
    * @param _valueLocked uint256 value of tokens, from those issued, to lock immediately.
    * @param _why reason for token locking
    * @param _releaseTime timestamp to release the lock (or 0 for locks which can only released by an unlockTokens call)
    * @return true if successful
    */
    function issueTokensWithLocking(address _to, uint256 _value, uint256 _valueLocked, LockReason _why, uint64 _releaseTime) onlyAdmin public returns (bool){

        //Check input values
        require(_to != address(0));
        require(_value > 0);
        require(_valueLocked >= 0 && _valueLocked <= _value);

        //Make sure we have enough inactive tokens to issue
        require(totalInactive >= _value);

        //Adding and subtracting is done through safemath
        totalSupply = totalSupply.add(_value);
        totalInactive = totalInactive.sub(_value);
        balances[_to] = balances[_to].add(_value);

        Issued(_to, _value, _valueLocked);
        Transfer(0x0, _to, _value);

        if (_valueLocked > 0) {
            lockTokens(_to, _valueLocked, _why, _releaseTime);
        }
    }



    /******************************
        TOKEN LOCKING

        Locking tokens means freezing a number of tokens belonging to an address.
        Locked tokens can not be transferred by the user to any other address.
        The contract owner (the fund) may still redeem those tokens, or unfreeze them.
        The token lock may expire automatically at a certain timestamp, or exist forever until the owner unlocks it.

    *******************************/


    /**
    * @dev lock tokens
    * @param _who address to lock the tokens at
    * @param _value value of tokens to lock
    * @param _reason reason for lock
    * @param _releaseTime timestamp to release the lock (or 0 for locks which can only released by an unlockTokens call)
    * @return A unique id for the newly created lock.
    * Note: The user MAY have at a certain time more locked tokens than actual tokens
    */
    function lockTokens(address _who, uint _value, LockReason _reason, uint64 _releaseTime) onlyAdmin public returns (uint64){
        require(_who != address(0));
        require(_value > 0);
        require(_releaseTime == 0 || _releaseTime > uint64(now));
        //Only allow 20 locks per address, to prevent out-of-gas at transfer scenarios
        require(locks[_who].length < MAX_LOCKS_PER_ADDRESS);

        uint64 lockId = lockCounter++;

        //Create the lock
        locks[_who].push(TokenLock(lockId, _reason, _value, _releaseTime));
        Locked(_who, _value, _reason, _releaseTime, lockId);

        return lockId;
    }

    /**
    * @dev Releases a specific token lock
    * @param _who address to release the tokens for
    * @param _lockId the unique lock-id to release
    *
    * note - this may change the order of the locks on an address, so if iterating the iteration should be restarted.
    * @return true on success
    */
    function unlockTokens(address _who, uint64 _lockId) onlyAdmin public returns (bool) {
        require(_who != address(0));
        require(_lockId > 0);

        for (uint8 i = 0; i < locks[_who].length; i++) {
            if (locks[_who][i].id == _lockId) {
                Unlocked(_who, locks[_who][i].value, _lockId);
                delete locks[_who][i];
                locks[_who][i] = locks[_who][locks[_who].length.sub(1)];
                locks[_who].length -= 1;

                return true;
            }
        }
        return false;
    }

    /**
    * @dev Get number of locks currently associated with an address
    * @param _who address to get token lock for
    *
    * @return number of locks
    *
    * Note - a lock can be inactive (due to its time expired) but still exists for a specific address
    */
    function lockCount(address _who) public constant returns (uint8){
        require(_who != address(0));
        return uint8(locks[_who].length);
    }

    /**
    * @dev Get details of a specific lock associated with an address
    * can be used to iterate through the locks of a user
    * @param _who address to get token lock for
    * @param _index the 0 based index of the lock.
    * @return id the unique lock id
    * @return reason the reason for the lock
    * @return value the value of tokens locked
    * @return the timestamp in which the lock will be inactive (or 0 if it&#39;s always active until removed)
    *
    * Note - a lock can be inactive (due to its time expired) but still exists for a specific address
    */
    function lockInfo(address _who, uint64 _index) public constant returns (uint64 id, uint8 reason, uint value, uint64 autoReleaseTime){
        require(_who != address(0));
        require(_index < locks[_who].length);
        id = locks[_who][_index].id;
        reason = uint8(locks[_who][_index].reason);
        value = locks[_who][_index].value;
        autoReleaseTime = locks[_who][_index].autoReleaseTime;
    }

    /**
    * @dev Get the total number of transferable (not locked) tokens the user has at a specific time
    * used by the LimitedTransferToken base class to block ERC20 transfer for locked tokens
    * @param holder address to get transferable count for
    * @param time block timestamp to check time-locks with.
    * @return total number of unlocked, transferable tokens
    *
    * Note - the timestamp is only used to check time-locks, the base balance used to check is always the current one.
    */
    function transferableTokens(address holder, uint64 time) public constant returns (uint256) {
        require(time > 0);

        //If it&#39;s a burn wallet, tokens cannot be moved out
        if (isBurnWallet(holder)){
            return 0;
        }

        uint8 holderLockCount = uint8(locks[holder].length);

        //No locks, go to base class implementation
        if (holderLockCount == 0) return super.transferableTokens(holder, time);

        uint256 totalLockedTokens = 0;
        for (uint8 i = 0; i < holderLockCount; i ++) {

            if (locks[holder][i].autoReleaseTime == 0 || locks[holder][i].autoReleaseTime > time) {
                totalLockedTokens = SafeMath.add(totalLockedTokens, locks[holder][i].value);
            }
        }
        uint balanceOfHolder = balanceOf(holder);

        //there may be more locked tokens than actual tokens, so the minimum between the two
        uint256 transferable = SafeMath.sub(balanceOfHolder, Math.min256(totalLockedTokens, balanceOfHolder));

        //Check with super implementation for further reductions
        return Math.min256(transferable, super.transferableTokens(holder, time));
    }

    /******************************
        REDEMPTION AND BURNING

        Redeeming tokens involves removing them from an address&#39;s wallet and moving them to a (one or more)
        specially designed "burn wallets".
        The process is implemented such as the owner can choose to burn or not to burn the tokens after redeeming them,
        which is legally necessary on some buy-back scenarios
        Each redemption is associated with a global "redemption event" (a unique id, supplied by the owner),
        which can later be used to query the total value redeemed for the user in this event (and on the owner&#39;s
        backend, through event logs processing, the total value redeemed for all users in this event)
    *******************************/


    /**
    * @dev designates an address as a burn wallet (there can be an unlimited number of burn wallets).
    * a burn wallet can only burn tokens - tokens may not be transferred out of it, and tokens do not participate
    * in redemptions
    * @param _burnWalletAddress the address to add to the burn wallet list
    */
    function addBurnWallet(address _burnWalletAddress) onlyAdmin {
        require(_burnWalletAddress != address(0));
        burnWallets[_burnWalletAddress] = true;
        AddedBurnWallet(_burnWalletAddress);
    }

    /**
    * @dev redeems (removes) tokens for an address and moves to to a burn wallet
    * @param _from the address to redeem tokens from
    * @param _burnWallet the burn wallet to move the tokens to
    * @param _reason the reason for the redemption
    * @param _redemptionId a redemptionId, supplied by the contract owner. usually assigned to a single global
    * redemption event (token buyback, or such).
    */
    function redeemTokens(address _from, address _burnWallet, uint256 _value, RedeemReason _reason, uint64 _redemptionId) onlyAdmin {
        require(_from != address(0));
        require(_redemptionId > 0);
        require(isBurnWallet(_burnWallet));
        require(balances[_from] >= _value);
        balances[_from] = balances[_from].sub(_value);
        balances[_burnWallet] = balances[_burnWallet].add(_value);
        tokenRedemptions[_from].push(TokenRedemption(_redemptionId, _reason, _value));
        Transfer(_from, _burnWallet, _value);
        Redeemed(_from, _burnWallet, _value, _reason, _redemptionId);
    }

    /**
    * @dev Burns tokens inside a burn wallet
    * The total number of inactive token is NOT increased
    * this means there is a finite number amount that can ever exist of this token
    * @param _burnWallet the address of the burn wallet
    * @param _value value of tokens to burn
    */
    function burnTokens(address _burnWallet, uint256 _value) onlyAdmin {
        require(_value > 0);
        require(isBurnWallet(_burnWallet));
        require(balances[_burnWallet] >= _value);
        balances[_burnWallet] = balances[_burnWallet].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burned(_burnWallet, _value);
        Transfer(_burnWallet,0x0,_value);
    }

    /**
    * @dev checks if a wallet is a burn wallet
    * @param _burnWalletAddress address to check
    */
    function isBurnWallet(address _burnWalletAddress) constant public returns (bool){
        return burnWallets[_burnWalletAddress];
    }

    /**
    * @dev gets number of redemptions done on a specific address
    * @param _who address to check
    */
    function redemptionCount(address _who) public constant returns (uint64){
        require(_who != address(0));
        return uint64(tokenRedemptions[_who].length);
    }

    /**
    * @dev gets data about a specific redemption done on a specific address
    * @param _who address to check
    * @param _index zero based index of the redemption
    * @return redemptionId the global redemptionId associated with this redemption
    * @return reason the reason for the redemption
    * @return value the value for the redemption
    */
    function redemptionInfo(address _who, uint64 _index) public constant returns (uint64 redemptionId, uint8 reason, uint value){
        require(_who != address(0));
        require(_index < tokenRedemptions[_who].length);
        redemptionId = tokenRedemptions[_who][_index].redemptionId;
        reason = uint8(tokenRedemptions[_who][_index].reason);
        value = tokenRedemptions[_who][_index].value;
    }

    /**
    * @dev gets the total value redemeed from a specific address, for a single global redemption event
    * @param _who address to check
    * @param _redemptionId the global redemption event id
    * @return the total value associated with the redemption event
    */

    function totalRedemptionIdValue(address _who, uint64 _redemptionId) public constant returns (uint256){
        require(_who != address(0));
        uint256 total = 0;
        uint64 numberOfRedemptions = redemptionCount(_who);
        for (uint64 i = 0; i < numberOfRedemptions; i++) {
            if (tokenRedemptions[_who][i].redemptionId == _redemptionId) {
                total = SafeMath.add(total, tokenRedemptions[_who][i].value);
            }
        }
        return total;
    }

}

contract SpiceToken is RegulatedToken {

    string public constant name = "SPiCE VC Token";
    string public constant symbol = "SPICE";
    uint8 public constant decimals = 8;
    uint256 private constant INITIAL_INACTIVE_TOKENS = 130 * 1000000 * (10 ** uint256(decimals));  //130 million tokens


    function SpiceToken() RegulatedToken() {
        totalInactive = INITIAL_INACTIVE_TOKENS;
        totalSupply = 0;
    }

}