pragma solidity ^0.4.24;

// File: node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol

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

// File: node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

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

// File: node_modules/openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: contracts/Ownable.sol

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
    require(msg.sender == owner, "msg.sender not owner");
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
    require(_newOwner != address(0), "_newOwner == 0");
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: contracts/Pausable.sol

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
    require(!paused, "The contract is paused");
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused, "The contract is not paused");
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

// File: contracts/Destructible.sol

/**
 * @title Destructible
 * @dev Base contract that can be destroyed by owner. All funds in contract will be sent to the owner.
 */
contract Destructible is Ownable {
  /**
   * @dev Transfers the current balance to the owner and terminates the contract.
   */
  function destroy() public onlyOwner {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) public onlyOwner {
    selfdestruct(_recipient);
  }
}

// File: contracts/ERC20Supplier.sol

/**
 * @title ERC20Supplier.
 * @author Andrea Speziale <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="e9889a998c938088858ca98c808d8686c78086">[email&#160;protected]</a>>
 * @dev Distribute a fixed amount of ERC20 based on a rate rate from a ERC20 reserve to a _receiver for ETH.
 * Received ETH are redirected to a wallet.
 */
contract ERC20Supplier is
  Pausable,
  Destructible
{
  using SafeMath for uint;

  ERC20 public token;
  
  address public wallet;
  address public reserve;
  
  uint public rate;

  event LogWithdrawAirdrop(
    address indexed _from,
    address indexed _token,
    uint amount
  );
  event LogReleaseTokensTo(address indexed _from,
    address indexed _to,
    uint _amount
  );
  event LogSetWallet(address indexed _wallet);
  event LogSetReserve(address indexed _reserve);
  event LogSetToken(address indexed _token);
  event LogSetrate(uint _rate);

  /**
   * @dev Contract constructor.
   * @param _wallet Where the received ETH are transfered.
   * @param _reserve From where the ERC20 token are sent to the purchaser.
   * @param _token Deployed ERC20 token address.
   * @param _rate Purchase rate, how many ERC20 for the given ETH.
   */
  constructor(
    address _wallet,
    address _reserve,
    address _token,
    uint _rate
  )
    public
  {
    require(_wallet != address(0), "_wallet == address(0)");
    require(_reserve != address(0), "_reserve == address(0)");
    require(_token != address(0), "_token == address(0)");
    require(_rate != 0, "_rate == 0");
    wallet = _wallet;
    reserve = _reserve;
    token = ERC20(_token);
    rate = _rate;
  }

  function() public payable {
    releaseTokensTo(msg.sender);
  }

  /**
   * @dev Set wallet.
   * @param _wallet Where the ETH are redirected.
   */
  function setWallet(address _wallet) public onlyOwner returns (bool) {
    require(_wallet != address(0), "_wallet == 0");
    require(_wallet != wallet, "_wallet == wallet");
    wallet = _wallet;
    emit LogSetWallet(wallet);
    return true;
  }

  /**
   * @dev Set ERC20 reserve.
   * @param _reserve Where ERC20 are stored.
   */
  function setReserve(address _reserve) public onlyOwner returns (bool) {
    require(_reserve != address(0), "_reserve == 0");
    require(_reserve != reserve, "_reserve == reserve");
    reserve = _reserve;
    emit LogSetReserve(reserve);
    return true;
  }

  /**
   * @dev Set ERC20 token.
   * @param _token ERC20 token address.
   */
  function setToken(address _token) public onlyOwner returns (bool) {
    require(_token != address(0), "_token == 0");
    require(_token != address(token), "_token == token");
    token = ERC20(_token);
    emit LogSetToken(token);
    return true;
  }

  /**
   * @dev Set rate.
   * @param _rate Multiplier, how many ERC20 for the given ETH.
   */
  function setRate(uint _rate) public onlyOwner returns (bool) {
    require(_rate != 0, "_rate == 0");
    require(_rate != rate, "_rate == rate");
    rate = _rate;
    emit LogSetrate(rate);
    return true;
  }

  /**
   * @dev Eventually withdraw airdropped token.
   * @param _token ERC20 address to be withdrawed.
   */
  function withdrawAirdrop(ERC20 _token)
    public
    onlyOwner
    returns(bool)
  {
    require(address(_token) != 0, "_token address == 0");
    require(
      _token.balanceOf(this) > 0,
      "dropped token balance == 0"
    );
    uint256 airdroppedTokenAmount = _token.balanceOf(this);
    _token.transfer(msg.sender, airdroppedTokenAmount);
    emit LogWithdrawAirdrop(msg.sender, _token, airdroppedTokenAmount);
    return true;
  }

  /**
   * @dev Release purchased ERC20 to the buyer.
   * @param _receiver Where the ERC20 are transfered.
   */
  function releaseTokensTo(address _receiver)
    internal
    whenNotPaused
    returns (bool) 
  {
    uint amount = msg.value.mul(rate);
    wallet.transfer(msg.value);
    require(
      token.transferFrom(reserve, _receiver, amount),
      "transferFrom reserve to _receiver failed"
    );
    return true;
  }
}