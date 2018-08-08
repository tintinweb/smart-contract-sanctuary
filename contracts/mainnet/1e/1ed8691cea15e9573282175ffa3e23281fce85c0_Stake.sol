pragma solidity ^0.4.19;

// File: contracts/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

// File: contracts/Owned.sol

contract Owned {
  event OwnerAddition(address indexed owner);

  event OwnerRemoval(address indexed owner);

  // owner address to enable admin functions
  mapping (address => bool) public isOwner;

  address[] public owners;

  address public operator;

  modifier onlyOwner {

    require(isOwner[msg.sender]);
    _;
  }

  modifier onlyOperator {
    require(msg.sender == operator);
    _;
  }

  function setOperator(address _operator) external onlyOwner {
    require(_operator != address(0));
    operator = _operator;
  }

  function removeOwner(address _owner) public onlyOwner {
    require(owners.length > 1);
    isOwner[_owner] = false;
    for (uint i = 0; i < owners.length - 1; i++) {
      if (owners[i] == _owner) {
        owners[i] = owners[SafeMath.sub(owners.length, 1)];
        break;
      }
    }
    owners.length = SafeMath.sub(owners.length, 1);
    OwnerRemoval(_owner);
  }

  function addOwner(address _owner) external onlyOwner {
    require(_owner != address(0));
    if(isOwner[_owner]) return;
    isOwner[_owner] = true;
    owners.push(_owner);
    OwnerAddition(_owner);
  }

  function setOwners(address[] _owners) internal {
    for (uint i = 0; i < _owners.length; i++) {
      require(_owners[i] != address(0));
      isOwner[_owners[i]] = true;
      OwnerAddition(_owners[i]);
    }
    owners = _owners;
  }

  function getOwners() public constant returns (address[])  {
    return owners;
  }

}

// File: contracts/Token.sol

// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20
pragma solidity ^0.4.19;

contract Token {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public constant returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// File: contracts/StandardToken.sol

/*
You should inherit from StandardToken or, for a token like you would want to
deploy in something like Mist, see HumanStandardToken.sol.
(This implements ONLY the standard functions and NOTHING else.
If you deploy this, you won&#39;t have anything useful.)

Implements ERC 20 Token standard: https://github.com/ethereum/EIPs/issues/20
.*/
pragma solidity ^0.4.19;


contract StandardToken is Token {

    function transfer(address _to, uint256 _value) public returns (bool success) {
        //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
        //Replace the if with this one instead.
        //require(balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        //same as above. Replace this line with the following if you want to protect against wrapping uints.
        //require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]);
        require(balances[_from] >= _value && allowed[_from][msg.sender] >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

// File: contracts/Validating.sol

contract Validating {

  modifier validAddress(address _address) {
    require(_address != address(0x0));
    _;
  }

  modifier notZero(uint _number) {
    require(_number != 0);
    _;
  }

  modifier notEmpty(string _string) {
    require(bytes(_string).length != 0);
    _;
  }

}

// File: contracts/Fee.sol

/**
  * @title FEE is an ERC20 token used to pay for trading on the exchange.
  * For deeper rational read https://leverj.io/whitepaper.pdf.
  * FEE tokens do not have limit. A new token can be generated by owner.
  */
contract Fee is Owned, Validating, StandardToken {

  /* This notifies clients about the amount burnt */
  event Burn(address indexed from, uint256 value);

  string public name;                   //fancy name: eg Simon Bucks
  uint8 public decimals;                //How many decimals to show. ie. There could 1000 base units with 3 decimals. Meaning 0.980 SBX = 980 base units. It&#39;s like comparing 1 wei to 1 ether.
  string public symbol;                 //An identifier: eg SBX
  string public version = &#39;F0.2&#39;;       //human 0.1 standard. Just an arbitrary versioning scheme.
  address public minter;

  modifier onlyMinter {
    require(msg.sender == minter);
    _;
  }

  /// @notice Constructor to set the owner, tokenName, decimals and symbol
  function Fee(
  address[] _owners,
  string _tokenName,
  uint8 _decimalUnits,
  string _tokenSymbol
  )
  public
  notEmpty(_tokenName)
  notEmpty(_tokenSymbol)
  {
    setOwners(_owners);
    name = _tokenName;
    decimals = _decimalUnits;
    symbol = _tokenSymbol;
  }

  /// @notice To set a new minter address
  /// @param _minter The address of the minter
  function setMinter(address _minter) external onlyOwner validAddress(_minter) {
    minter = _minter;
  }

  /// @notice To eliminate tokens and adjust the price of the FEE tokens
  /// @param _value Amount of tokens to delete
  function burnTokens(uint _value) public notZero(_value) {
    require(balances[msg.sender] >= _value);
    balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
    totalSupply = SafeMath.sub(totalSupply, _value);
    Burn(msg.sender, _value);
  }

  /// @notice To send tokens to another user. New FEE tokens are generated when
  /// doing this process by the minter
  /// @param _to The receiver of the tokens
  /// @param _value The amount o
  function sendTokens(address _to, uint _value) public onlyMinter validAddress(_to) notZero(_value) {
    balances[_to] = SafeMath.add(balances[_to], _value);
    totalSupply = SafeMath.add(totalSupply, _value);
    Transfer(0x0, _to, _value);
  }
}

// File: contracts/GenericCall.sol

contract GenericCall {

  /************************************ abstract **********************************/
  modifier isAllowed {_;}
  /********************************************************************************/

  event Execution(address destination, uint value, bytes data);

  function execute(address destination, uint value, bytes data) external isAllowed {
    if (destination.call.value(value)(data)) {
      Execution(destination, value, data);
    }
  }
}

// File: contracts/Stake.sol

/**
  * stake users levs
  * get fee from trading contract
  * get eth from trading contract
  * calculate fee tokens to be generated
  * distribute fee tokens and lev to users in chunks.
  * re-purpose it for next trading duration.
  * what happens to extra fee if not enough trading happened? destroy it.
  * Stake will have full control over FEE.sol
  */
pragma solidity ^0.4.19;








contract Stake is Owned, Validating, GenericCall {
  using SafeMath for uint;

  event StakeEvent(address indexed user, uint levs, uint startBlock, uint endBlock);

  event RedeemEvent(address indexed user, uint levs, uint feeEarned, uint startBlock, uint endBlock);

  event FeeCalculated(uint feeCalculated, uint feeReceived, uint weiReceived, uint startBlock, uint endBlock);

  event StakingInterval(uint startBlock, uint endBlock);

  // User address to (lev tokens)*(blocks left to end)
  mapping (address => uint) public levBlocks;

  // User address to lev tokens at stake
  mapping (address => uint) public stakes;

  uint public totalLevs;

  // Total lev blocks. this will be help not to iterate through full mapping
  uint public totalLevBlocks;

  // Wei for each Fee token
  uint public weiPerFee;

  // Total fee to be distributed
  uint public feeForTheStakingInterval;

  // Lev token reference
  Token public levToken; //revisit: is there a difference in storage versus using address?

  // FEE token reference
  Fee public feeToken; //revisit: is there a difference in storage versus using address?

  uint public startBlock;

  uint public endBlock;

  address public wallet;

  bool public feeCalculated = false;

  modifier isStaking {
    require(startBlock <= block.number && block.number < endBlock);
    _;
  }

  modifier isDoneStaking {
    require(block.number >= endBlock);
    _;
  }

  modifier isAllowed{
    require(isOwner[msg.sender]);
    _;
  }

  function() public payable {
  }

  /// @notice Constructor to set all the default values for the owner, wallet,
  /// weiPerFee, tokenID and endBlock
  function Stake(
  address[] _owners,
  address _operator,
  address _wallet,
  uint _weiPerFee,
  address _levToken
  ) public
  validAddress(_wallet)
  validAddress(_operator)
  validAddress(_levToken)
  notZero(_weiPerFee)
  {
    setOwners(_owners);
    operator = _operator;
    wallet = _wallet;
    weiPerFee = _weiPerFee;
    levToken = Token(_levToken);
  }

  function version() external pure returns (string) {
    return "1.0.0";
  }

  /// @notice To set the the address of the LEV token
  /// @param _levToken The token address
  function setLevToken(address _levToken) external validAddress(_levToken) onlyOwner {
    levToken = Token(_levToken);
  }

  /// @notice To set the FEE token address
  /// @param _feeToken The address of that token
  function setFeeToken(address _feeToken) external validAddress(_feeToken) onlyOwner {
    feeToken = Fee(_feeToken);
  }

  /// @notice To set the wallet address by the owner only
  /// @param _wallet The wallet address
  function setWallet(address _wallet) external validAddress(_wallet) onlyOwner {
    wallet = _wallet;
  }

  /// @notice Public function to stake tokens executable by any user.
  /// The user has to approve the staking contract on token before calling this function.
  /// Refer to the tests for more information
  /// @param _quantity How many LEV tokens to lock for staking
  function stakeTokens(uint _quantity) external isStaking notZero(_quantity) {
    require(levToken.allowance(msg.sender, this) >= _quantity);

    levBlocks[msg.sender] = levBlocks[msg.sender].add(_quantity.mul(endBlock.sub(block.number)));
    stakes[msg.sender] = stakes[msg.sender].add(_quantity);
    totalLevBlocks = totalLevBlocks.add(_quantity.mul(endBlock.sub(block.number)));
    totalLevs = totalLevs.add(_quantity);
    require(levToken.transferFrom(msg.sender, this, _quantity));
    StakeEvent(msg.sender, _quantity, startBlock, endBlock);
  }

  function revertFeeCalculatedFlag(bool _flag) external onlyOwner isDoneStaking {
    feeCalculated = _flag;
  }

  /// @notice To update the price of FEE tokens to the current value.
  /// Executable by the operator only
  function updateFeeForCurrentStakingInterval() external onlyOperator isDoneStaking {
    require(feeCalculated == false);
    uint feeReceived = feeToken.balanceOf(this);
    feeForTheStakingInterval = feeForTheStakingInterval.add(feeReceived.add(this.balance.div(weiPerFee)));
    feeCalculated = true;
    FeeCalculated(feeForTheStakingInterval, feeReceived, this.balance, startBlock, endBlock);
    if (feeReceived > 0) feeToken.burnTokens(feeReceived);
    if (this.balance > 0) wallet.transfer(this.balance);
  }

  /// @notice To unlock and recover your LEV and FEE tokens after staking and fee to any user
  function redeemLevAndFeeByStaker() external {
    redeemLevAndFee(msg.sender);
  }

  function redeemLevAndFeeToStakers(address[] _stakers) external onlyOperator {
    for (uint i = 0; i < _stakers.length; i++) redeemLevAndFee(_stakers[i]);
  }

  function redeemLevAndFee(address _staker) private validAddress(_staker) isDoneStaking {
    require(feeCalculated);
    require(totalLevBlocks > 0);

    uint levBlock = levBlocks[_staker];
    uint stake = stakes[_staker];
    require(stake > 0);

    uint feeEarned = levBlock.mul(feeForTheStakingInterval).div(totalLevBlocks);
    delete stakes[_staker];
    delete levBlocks[_staker];
    totalLevs = totalLevs.sub(stake);
    if (feeEarned > 0) feeToken.sendTokens(_staker, feeEarned);
    require(levToken.transfer(_staker, stake));
    RedeemEvent(_staker, stake, feeEarned, startBlock, endBlock);
  }

  /// @notice To start a new trading staking-interval where the price of the FEE will be updated
  /// @param _start The starting block.number of the new staking-interval
  /// @param _end When the new staking-interval ends in block.number
  function startNewStakingInterval(uint _start, uint _end)
  external
  notZero(_start)
  notZero(_end)
  onlyOperator
  isDoneStaking
  {
    require(totalLevs == 0);

    startBlock = _start;
    endBlock = _end;

    // reset
    totalLevBlocks = 0;
    feeForTheStakingInterval = 0;
    feeCalculated = false;
    StakingInterval(_start, _end);
  }

}