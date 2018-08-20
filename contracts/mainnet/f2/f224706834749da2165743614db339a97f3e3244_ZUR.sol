pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/BasicToken.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol

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

// File: contracts/ZUR.sol

/**
 * Holders of ZUR can claim COE as it is mined using the claimTokens()
 * function. This contract will be fed COE automatically by the COE ERC20
 * contract.
 */
contract ZUR is MintableToken {
  using SafeMath for uint;

  string public constant name = "ZUR Cheque by Zurcoin Core";
  string public constant symbol = "ZUR";
  uint8 public constant decimals = 0;

  address public admin;
  uint public cap = 35*10**13;
  uint public totalEthReleased = 0;

  mapping(address => uint) public ethReleased;
  address[] public trackedTokens;
  mapping(address => bool) public isTokenTracked;
  mapping(address => uint) public totalTokensReleased;
  mapping(address => mapping(address => uint)) public tokensReleased;

  constructor() public {
    owner = this;
    admin = msg.sender;
  }

  function () public payable {}

  modifier onlyAdmin() {
    require(msg.sender == admin);
    _;
  }

  function changeAdmin(address _receiver) onlyAdmin public {
    admin = _receiver;
  }

  /**
   * Claim your eth.
   */
  function claimEth() public {
    claimEthFor(msg.sender);
  }

  // Claim eth for address
  function claimEthFor(address payee) public {
    require(balances[payee] > 0);

    uint totalReceived = address(this).balance.add(totalEthReleased);
    uint payment = totalReceived.mul(
      balances[payee]).div(
        cap).sub(
          ethReleased[payee]
    );

    require(payment != 0);
    require(address(this).balance >= payment);

    ethReleased[payee] = ethReleased[payee].add(payment);
    totalEthReleased = totalEthReleased.add(payment);

    payee.transfer(payment);
  }

  // Claim your tokens
  function claimMyTokens() public {
    claimTokensFor(msg.sender);
  }

  // Claim on behalf of payee address
  function claimTokensFor(address payee) public {
    require(balances[payee] > 0);

    for (uint16 i = 0; i < trackedTokens.length; i++) {
      claimToken(trackedTokens[i], payee);
    }
  }

  /**
   * Transfers the unclaimed token amount for the given token and address
   * @param _tokenAddr The address of the ERC20 token
   * @param _payee The address of the payee (ZUR holder)
   */
  function claimToken(address _tokenAddr, address _payee) public {
    require(balances[_payee] > 0);
    require(isTokenTracked[_tokenAddr]);

    uint payment = getUnclaimedTokenAmount(_tokenAddr, _payee);
    if (payment == 0) {
      return;
    }

    ERC20 Token = ERC20(_tokenAddr);
    require(Token.balanceOf(address(this)) >= payment);
    tokensReleased[address(Token)][_payee] = tokensReleased[address(Token)][_payee].add(payment);
    totalTokensReleased[address(Token)] = totalTokensReleased[address(Token)].add(payment);
    Token.transfer(_payee, payment);
  }

  /**
   * Returns the amount of a token (tokenAddr) that payee can claim
   * @param tokenAddr The address of the ERC20 token
   * @param payee The address of the payee
   */
  function getUnclaimedTokenAmount(address tokenAddr, address payee) public view returns (uint) {
    ERC20 Token = ERC20(tokenAddr);
    uint totalReceived = Token.balanceOf(address(this)).add(totalTokensReleased[address(Token)]);
    uint payment = totalReceived.mul(
      balances[payee]).div(
        cap).sub(
          tokensReleased[address(Token)][payee]
    );
    return payment;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(msg.sender != _to);
    uint startingBalance = balances[msg.sender];
    require(super.transfer(_to, _value));

    transferCheques(msg.sender, _to, _value, startingBalance);
    return true;
  }

  function transferCheques(address from, address to, uint cheques, uint startingBalance) internal {

    // proportional amount of eth released already
    uint claimedEth = ethReleased[from].mul(
      cheques).div(
        startingBalance
    );

    // increment to&#39;s released eth
    ethReleased[to] = ethReleased[to].add(claimedEth);

    // decrement from&#39;s released eth
    ethReleased[from] = ethReleased[from].sub(claimedEth);

    for (uint16 i = 0; i < trackedTokens.length; i++) {
      address tokenAddr = trackedTokens[i];

      // proportional amount of token released already
      uint claimed = tokensReleased[tokenAddr][from].mul(
        cheques).div(
          startingBalance
      );

      // increment to&#39;s released token
      tokensReleased[tokenAddr][to] = tokensReleased[tokenAddr][to].add(claimed);

      // decrement from&#39;s released token
      tokensReleased[tokenAddr][from] = tokensReleased[tokenAddr][from].sub(claimed);
    }
  }

  /**
   * @dev Add a new payee to the contract.
   * @param _payees The addresses of the payees to add.
   * @param _cheques The array of number of cheques owned by the payee.
   */
  function addPayees(address[] _payees, uint[] _cheques) onlyAdmin external {
    require(_payees.length == _cheques.length);
    require(_payees.length > 0);

    for (uint i = 0; i < _payees.length; i++) {
      addPayee(_payees[i], _cheques[i]);
    }

  }

  /**
   * @dev Add a new payee to the contract.
   * @param _payee The address of the payee to add.
   * @param _cheques The number of _cheques owned by the payee.
   */
  function addPayee(address _payee, uint _cheques) onlyAdmin canMint public {
    require(_payee != address(0));
    require(_cheques > 0);
    require(balances[_payee] == 0);

    MintableToken(this).mint(_payee, _cheques);
  }

  // irreversibly close the adding of cheques
  function finishedLoading() onlyAdmin canMint public {
    MintableToken(this).finishMinting();
  }

  function trackToken(address _addr) onlyAdmin public {
    require(_addr != address(0));
    require(!isTokenTracked[_addr]);
    trackedTokens.push(_addr);
    isTokenTracked[_addr] = true;
  }

  /*
   * However unlikely, it is possible that the number of tracked tokens
   * reaches the point that would make the gas cost of transferring ZUR
   * exceed the block gas limit. This function allows the admin to remove
   * a token from the tracked token list thus reducing the number of loops
   * required in transferCheques, lowering the gas cost of transfer. The
   * remaining balance of this token is sent back to the token&#39;s contract.
   *
   * Removal is irreversible.
   *
   * @param _addr The address of the ERC token to untrack
   * @param _position The index of the _addr in the trackedTokens array.
   * Use web3 to cycle through and find the index position.
   */
  function unTrackToken(address _addr, uint16 _position) onlyAdmin public {
    require(isTokenTracked[_addr]);
    require(trackedTokens[_position] == _addr);

    ERC20(_addr).transfer(_addr, ERC20(_addr).balanceOf(address(this)));
    trackedTokens[_position] = trackedTokens[trackedTokens.length-1];
    delete trackedTokens[trackedTokens.length-1];
    trackedTokens.length--;
  }
}