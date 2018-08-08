pragma solidity ^0.4.18;

// File: zeppelin-solidity/contracts/math/SafeMath.sol

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

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: zeppelin-solidity/contracts/token/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: zeppelin-solidity/contracts/token/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
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

// File: zeppelin-solidity/contracts/token/BurnableToken.sol

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}

// File: contracts/Distribution.sol

/**
 * @title Distribution contract
 * @dev see https://send.sd/distribution
 */
contract Distribution is Ownable {
  using SafeMath for uint256;

  uint16 public stages;
  uint256 public stageDuration;
  uint256 public startTime;

  uint256 public soldTokens;
  uint256 public bonusClaimedTokens;
  uint256 public raisedETH;
  uint256 public raisedUSD;

  uint256 public weiUsdRate;

  BurnableToken public token;

  bool public isActive;
  uint256 public cap;
  uint256 public stageCap;

  mapping (address => mapping (uint16 => uint256)) public contributions;
  mapping (uint16 => uint256) public sold;
  mapping (uint16 => bool) public burned;
  mapping (address => mapping (uint16 => bool)) public claimed;

  event NewPurchase(
    address indexed purchaser,
    uint256 sdtAmount,
    uint256 usdAmount,
    uint256 ethAmount
  );

  event NewBonusClaim(
    address indexed purchaser,
    uint256 sdtAmount
  );

  function Distribution(
      uint16 _stages,
      uint256 _stageDuration,
      address _token
  ) public {
    stages = _stages;
    stageDuration = _stageDuration;
    isActive = false;
    token = BurnableToken(_token);
  }

  /**
   * @dev contribution function
   */
  function () external payable {
    require(isActive);
    require(weiUsdRate > 0);
    require(getStage() < stages);

    uint256 usd = msg.value / weiUsdRate;
    uint256 tokens = computeTokens(usd);
    uint16 stage = getStage();

    sold[stage] = sold[stage].add(tokens);
    require(sold[stage] < stageCap);

    contributions[msg.sender][stage] = contributions[msg.sender][stage].add(tokens);
    soldTokens = soldTokens.add(tokens);
    raisedETH = raisedETH.add(msg.value);
    raisedUSD = raisedUSD.add(usd);

    NewPurchase(msg.sender, tokens, usd, msg.value);
    token.transfer(msg.sender, tokens);
  }

  /**
   * @dev Initialize distribution
   * @param _cap uint256 The amount of tokens for distribution
   */
  function init(uint256 _cap, uint256 _startTime) public onlyOwner {
    require(!isActive);
    require(token.balanceOf(this) == _cap);
    require(_startTime > block.timestamp);

    startTime = _startTime;
    cap = _cap;
    stageCap = cap / stages;
    isActive = true;
  }

  /**
   * @dev retrieve bonus from specified stage
   * @param _stage uint16 The stage
   */
  function claimBonus(uint16 _stage) public {
    require(!claimed[msg.sender][_stage]);
    require(getStage() > _stage);

    if (!burned[_stage]) {
      token.burn(stageCap.sub(sold[_stage]).sub(sold[_stage].mul(computeBonus(_stage)).div(1 ether)));
      burned[_stage] = true;
    }

    uint256 tokens = computeAddressBonus(_stage);
    token.transfer(msg.sender, tokens);
    bonusClaimedTokens = bonusClaimedTokens.add(tokens);
    claimed[msg.sender][_stage] = true;

    NewBonusClaim(msg.sender, tokens);
  }

  /**
   * @dev set an exchange rate in wei
   * @param _rate uint256 The new exchange rate
   */
  function setWeiUsdRate(uint256 _rate) public onlyOwner {
    require(_rate > 0);
    weiUsdRate = _rate;
  }

  /**
   * @dev retrieve ETH
   * @param _amount uint256 The new exchange rate
   * @param _address address The address to receive ETH
   */
  function forwardFunds(uint256 _amount, address _address) public onlyOwner {
    _address.transfer(_amount);
  }

  /**
   * @dev compute tokens given a USD value
   * @param _usd uint256 Value in USD
   */
  function computeTokens(uint256 _usd) public view returns(uint256) {
    return _usd.mul(1000000000000000000 ether).div(
      soldTokens.mul(19800000000000000000).div(cap).add(200000000000000000)
    );
  }

  /**
   * @dev current stage
   */
  function getStage() public view returns(uint16) {
    require(block.timestamp >= startTime);
    return uint16(uint256(block.timestamp).sub(startTime).div(stageDuration));
  }

  /**
   * @dev compute bonus (%) for a specified stage
   * @param _stage uint16 The stage
   */
  function computeBonus(uint16 _stage) public view returns(uint256) {
    return uint256(100000000000000000).sub(sold[_stage].mul(100000).div(441095890411));
  }

  /**
   * @dev compute for a specified stage
   * @param _stage uint16 The stage
   */
  function computeAddressBonus(uint16 _stage) public view returns(uint256) {
    return contributions[msg.sender][_stage].mul(computeBonus(_stage)).div(1 ether);
  }

  //////////
  // Safety Methods
  //////////
  /// @notice This method can be used by the controller to extract mistakenly
  ///  sent tokens to this contract.
  /// @param _token The address of the token contract that you want to recover
  ///  set to 0 in case you want to extract ether.
  function claimTokens(address _token) public onlyOwner {
    // owner can claim any token but SDT
    require(_token != address(token));
    if (_token == 0x0) {
      owner.transfer(this.balance);
      return;
    }

    ERC20Basic erc20token = ERC20Basic(_token);
    uint256 balance = erc20token.balanceOf(this);
    erc20token.transfer(owner, balance);
    ClaimedTokens(_token, owner, balance);
  }

  event ClaimedTokens(
    address indexed _token,
    address indexed _controller,
    uint256 _amount
  );
}