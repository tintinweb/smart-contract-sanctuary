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
      emit Execution(destination, value, data);
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

    uint public weiPerFEE; // Wei for each Fee token
    Token public LEV;
    Fee public FEE;
    address public wallet;
    uint public interval;
    uint public deployedBlock;

    // events
    event StakeEvent(address indexed user, uint levs, uint startBlock, uint endBlock, uint intervalId);
    event ReStakeEvent(address indexed user, uint levs, uint startBlock, uint endBlock, uint intervalId);
    event RedeemEvent(address indexed user, uint levs, uint feeEarned, uint startBlock, uint endBlock, uint intervalId);
    event FeeCalculated(uint feeCalculated, uint feeReceived, uint weiReceived, uint startBlock, uint endBlock, uint intervalId);
    event Block(uint start, uint end, uint intervalId);
    event Log(int signedQuantity, uint unsignedQuantity, uint lev, uint withdrawLev); //todo: remove before prod.
    //account
    struct UserStake {uint interval; uint lev; uint levBlock;}

    mapping(address => UserStake) public stakes;

    function getStake(address account) external constant returns (uint, uint, uint){
        UserStake storage userStake = stakes[account];
        return (userStake.interval, userStake.lev, userStake.levBlock);
    }

    // per staking interval data
    mapping(uint => uint) public totalLevBlocks;
    mapping(uint => uint) public FEEGenerated;
    mapping(uint => uint) public start;
    mapping(uint => uint) public end;
    mapping(uint => bool) public FEECalculated;

    // user specific
    uint public latest;

    modifier isAllowed{require(isOwner[msg.sender]);
        _;}

    function() public payable {}

    /// @notice Constructor to set all the default values for the owner, wallet,
    /// weiPerFee, tokenID and endBlock
    constructor(address[] _owners, address _operator, address _wallet, uint _weiPerFee, address _levToken, address _feeToken, uint _interval)
    public validAddress(_wallet) validAddress(_operator) validAddress(_levToken) validAddress(_feeToken) notZero(_weiPerFee) notZero(_interval){

        setOwners(_owners);
        operator = _operator;
        wallet = _wallet;
        weiPerFEE = _weiPerFee;
        LEV = Token(_levToken);
        interval = _interval;
        FEE = Fee(_feeToken);
        deployedBlock = block.number;
        latest = 1;
        start[latest] = deployedBlock;
        end[latest] = start[latest] + interval - 1;
    }

    /// @notice To set the wallet address by the owner only
    /// @param _wallet The wallet address
    function setWallet(address _wallet) external validAddress(_wallet) onlyOwner {
        wallet = _wallet;
    }

    function setInterval(uint _interval) external notZero(_interval) onlyOwner {
        interval = _interval;
    }

    function getCurrentStakingPeriod() external constant returns (uint _start, uint _end){
        uint diff = (block.number - deployedBlock) % interval;
        _start = block.number - diff;
        _end = _start + interval - 1;
    }

    //create interval if not there
    function ensureInterval() public {
        if (end[latest] > block.number) return;
        calculateFEE2Distribute();
        uint diff = (block.number - end[latest]) % interval;
        latest = latest + 1;
        start[latest] = end[latest - 1] + 1;
        end[latest] = block.number - diff + interval;
        emit Block(start[latest], end[latest], latest);
    }

    //calculate fee for previous interval if not calculated
    function calculateFEE2Distribute() private {
        if (FEECalculated[latest] || end[latest] > block.number) return;
        uint feeReceived = FEE.balanceOf(this);
        FEEGenerated[latest] = feeReceived.add(address(this).balance.div(weiPerFEE));
        FEECalculated[latest] = true;
        emit FeeCalculated(FEEGenerated[latest], feeReceived, address(this).balance, start[latest], end[latest], latest);
        if (feeReceived > 0) FEE.burnTokens(feeReceived);
        if (address(this).balance > 0) wallet.transfer(address(this).balance);
    }

    function restake(int _signedQuantity) private {
        UserStake storage userStake = stakes[msg.sender];
        if (userStake.interval == latest || userStake.interval == 0) return;
        uint lev = userStake.lev;
        uint withdrawLev = _signedQuantity >= 0 ? 0 : uint(_signedQuantity * - 1) >= userStake.lev ? userStake.lev : uint(_signedQuantity * - 1);
        _withdraw(withdrawLev);
        userStake.lev = lev.sub(withdrawLev);
        if (userStake.lev == 0) {
            delete stakes[msg.sender];
            return;
        }
        userStake.interval = latest;
        userStake.levBlock = userStake.lev.mul(interval);
        totalLevBlocks[latest] = totalLevBlocks[latest].add(userStake.levBlock);
        emit ReStakeEvent(msg.sender, userStake.lev, start[latest], end[latest], latest);
    }

    function stake(int _signedQuantity) external {
        ensureInterval();
        restake(_signedQuantity);
        if (_signedQuantity <= 0) return;
        stakeWithCurrentPeriod(uint(_signedQuantity));
    }

    function stakeWithCurrentPeriod(uint _quantity) private {
        require(LEV.allowance(msg.sender, this) >= _quantity, "Approve LEV tokens first");
        UserStake storage userStake = stakes[msg.sender];
        userStake.interval = latest;
        userStake.levBlock = userStake.levBlock.add(_quantity.mul(end[latest].sub(block.number)));
        userStake.lev = userStake.lev.add(_quantity);
        totalLevBlocks[latest] = totalLevBlocks[latest].add(_quantity.mul(end[latest].sub(block.number)));
        require(LEV.transferFrom(msg.sender, this, _quantity), "LEV token transfer was not successful");
        emit StakeEvent(msg.sender, _quantity, start[latest], end[latest], latest);
    }

    function withdraw() external {
        ensureInterval();
        UserStake storage userStake = stakes[msg.sender];
        if (userStake.interval == 0 || userStake.interval == latest) return;
        _withdraw(userStake.lev);
    }

    function _withdraw(uint lev) private {
        UserStake storage userStake = stakes[msg.sender];
        uint _interval = userStake.interval;
        uint feeEarned = userStake.levBlock.mul(FEEGenerated[_interval]).div(totalLevBlocks[_interval]);
        delete stakes[msg.sender];
        if (feeEarned > 0) FEE.sendTokens(msg.sender, feeEarned);
        if (lev > 0) require(LEV.transfer(msg.sender, lev));
        emit RedeemEvent(msg.sender, lev, feeEarned, start[_interval], end[_interval], _interval);
    }
}