/**
 *Submitted for verification at BscScan.com on 2021-11-13
*/

pragma solidity 0.4.25;

contract Ownable {

    address public ownerField;

    constructor() public {
        ownerField = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == ownerField, "Calling address not an owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        ownerField = newOwner;
    }

    function owner() public view returns(address) {
        return ownerField;
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
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);
    return c;

  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;

  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;
    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
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

interface IERC20 {

  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);

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

contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param owner The address to query the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param owner address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */

  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

  /**
  * @dev Transfer token for a specified address
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param from address The address which you want to send tokens from
   * @param to address The address which you want to transfer to
   * @param value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);

    return true;

  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)

  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);

    return true;
  }

  /**
  * @dev Transfer token for a specified addresses
  * @param from The address to transfer from.
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */

  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from], "Insignificant balance in from address");
    require(to != address(0), "Invalid to address specified [0x0]");

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);

    emit Transfer(from, to, value);
  }

  /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param account The account that will receive the created tokens.
   * @param value The amount that will be created.
   */
  function _mint(address account, uint256 value) internal {
    require(account != 0);

    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);

    emit Transfer(address(0), account, value);
  }



  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burn(address account, uint256 value) internal {
    require(account != 0);
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);

    emit Transfer(account, address(0), value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender's allowance for said account. Uses the
   * internal burn function.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */

  function _burnFrom(address account, uint256 value) internal {

    require(value <= _allowed[account][msg.sender]);

    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }

}

contract Pausable is Ownable {
    bool public paused;

    modifier ifNotPaused {
        require(!paused, "Contract is paused");
        _;
    }

    modifier ifPaused {
        require(paused, "Contract is not paused");
        _;
    }

    // Called by the owner on emergency, triggers paused state
    function pause() external onlyOwner {
        paused = true;
    }

    // Called by the owner on end of emergency, returns to normal state
    function resume() external onlyOwner ifPaused {
        paused = false;
    }
}

contract AirDropWinners is Ownable, Pausable {
using SafeMath for uint256;

  struct Contribution {  
    uint256 tokenAmount;
    bool    wasClaimed;
    bool    isValid;
  }


  address public tokenAddress;       //Smartcontract Address  
  uint256 public totalTokensClaimed; // Totaltokens claimed by winners (you do not set this the contract does as tokens are claimed)
  uint256 public startTime;          // airDrop Start time 
   

  mapping (address => Contribution) contributions;

  constructor (address _token) 
  Ownable() 
  public {
    tokenAddress = _token;
    startTime = now;
  }

  /**
   * @dev getTotalTokensRemaining() provides the function of returning the number of
   * tokens currently left in the airdrop balance
   */
  function getTotalTokensRemaining()
  ifNotPaused
  public
  view
  returns (uint256)
  {
    return ERC20(tokenAddress).balanceOf(0x29f87cc4b753ce18e55428ef9b2639359bf5cc38);
  }

  /**
   * @dev isAddressInAirdropList() provides the function of testing if the 
   * specified address is in fact valid in the airdrop list
   */
  function isAddressInAirdropList(address _addressToLookUp)
  ifNotPaused
  public
  view
  returns (bool)
  {
    Contribution storage contrib = contributions[_addressToLookUp];
    return contrib.isValid;
  }

  /**
   * @dev _bulkAddAddressesToAirdrop provides the function of adding addresses 
   * to the airdrop list with the default of 30 sparkle
   */
  function bulkAddAddressesToAirDrop(address[] _addressesToAdd)
  ifNotPaused
  public
  {
    require(_addressesToAdd.length > 0);
    for (uint i = 0; i < _addressesToAdd.length; i++) {
      _addAddressToAirDrop(_addressesToAdd[i]);
    }
    
  }

  /**
   * @dev _bulkAddAddressesToAirdropWithAward provides the function of adding addresses 
   * to the airdrop list with a specific number of tokens
   */
  function bulkAddAddressesToAirDropWithAward(address[] _addressesToAdd, uint256 _tokenAward)
  ifNotPaused
  public
  {
    require(_addressesToAdd.length > 0);
    require(_tokenAward > 0);
    for (uint i = 0; i < _addressesToAdd.length; i++) {
      _addAddressToAirdropWithAward(_addressesToAdd[i], _tokenAward);
    }
    
  }

  /**
   * @dev _addAddressToAirdropWithAward provides the function of adding an address to the
   * airdrop list with a specific number of tokens opposed to the default of  
   * 30 Sparkle
   * @dev NOTE: _tokenAward will be converted so value only needs to be whole number
   * Ex: 30 opposed to 30 * (10e7)
   */
  function _addAddressToAirdropWithAward(address _addressToAdd, uint256 _tokenAward)
  onlyOwner
  internal
  {
      require(_addressToAdd != 0);
      require(!isAddressInAirdropList(_addressToAdd));
      require(_tokenAward > 0);
      Contribution storage contrib = contributions[_addressToAdd];
      contrib.tokenAmount = _tokenAward.mul(10e7);
      contrib.wasClaimed = false;
      contrib.isValid = true;
  }

  /**
   * @dev _addAddressToAirdrop provides the function of adding an address to the
   * airdrop list with the default of 30 sparkle
   */
  function _addAddressToAirDrop(address _addressToAdd)
  onlyOwner
  internal
  {
      require(_addressToAdd != 0);
      require(!isAddressInAirdropList(_addressToAdd));
      Contribution storage contrib = contributions[_addressToAdd];
      contrib.tokenAmount = 98948000000000000000000000;
      contrib.wasClaimed = false;
      contrib.isValid = true;
  }

  /**
   * @dev bulkRemoveAddressesFromAirDrop provides the function of removing airdrop 
   * addresses from the airdrop list
   */
  function bulkRemoveAddressesFromAirDrop(address[] _addressesToRemove)
  ifNotPaused
  public
  {
    require(_addressesToRemove.length > 0);
    for (uint i = 0; i < _addressesToRemove.length; i++) {
      _removeAddressFromAirDrop(_addressesToRemove[i]);
    }

  }

  /**
   * @dev _removeAddressFromAirDrop provides the function of removing an address from 
   * the airdrop
   */
  function _removeAddressFromAirDrop(address _addressToRemove)
  onlyOwner
  internal
  {
      require(_addressToRemove != 0);
      require(isAddressInAirdropList(_addressToRemove));
      Contribution storage contrib = contributions[_addressToRemove];
      contrib.tokenAmount = 0;
      contrib.wasClaimed = false;
      contrib.isValid = false;
  }

function setAirdropAddressWasClaimed(address _addressToChange, bool _newWasClaimedValue)
  ifNotPaused
  onlyOwner
  public
  {
    require(_addressToChange != 0);
    require(isAddressInAirdropList(_addressToChange));
    Contribution storage contrib = contributions[ _addressToChange];
    require(contrib.isValid);
    contrib.wasClaimed = _newWasClaimedValue;
  }

  /**
   * @dev claimTokens() provides airdrop winners the function of collecting their tokens
   */
  function claimTokens() 
  ifNotPaused
  public {
    Contribution storage contrib = contributions[msg.sender];
    require(contrib.isValid, "Address not found in airdrop list");
    require(contrib.tokenAmount > 0, "There are currently no tokens to claim.");
    uint256 tempPendingTokens = contrib.tokenAmount;
    contrib.tokenAmount = 0;
    totalTokensClaimed = totalTokensClaimed.add(tempPendingTokens);
    contrib.wasClaimed = true;
    ERC20(tokenAddress).transfer(msg.sender, tempPendingTokens);
  }

  /**
   * @dev () is the default payable function. Since this contract should not accept
   * revert the transaction best as possible.
   */
  function() payable public {
    revert("ETH not accepted");
  }

}

contract SparkleAirDrop is AirDropWinners {
  using SafeMath for uint256;

  address initTokenContractAddress = 0xb778287b81002b7e9589ddf912ff45897e83df10;
  
  constructor()
  AirDropWinners(initTokenContractAddress)
  public  
  {}

}