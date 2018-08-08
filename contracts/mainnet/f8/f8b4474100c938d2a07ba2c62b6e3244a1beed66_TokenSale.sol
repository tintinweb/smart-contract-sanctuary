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

// File: contracts/TokenVesting.sol

/**
 * @title Vesting contract for SDT
 * @dev see https://send.sd/token
 */
contract TokenVesting is Ownable {
  using SafeMath for uint256;

  address public ico;
  bool public initialized;
  bool public active;
  ERC20Basic public token;
  mapping (address => TokenGrant[]) public grants;

  uint256 public circulatingSupply = 0;

  struct TokenGrant {
    uint256 value;
    uint256 claimed;
    uint256 vesting;
    uint256 start;
  }

  event NewTokenGrant (
    address indexed to,
    uint256 value,
    uint256 start,
    uint256 vesting
  );

  event NewTokenClaim (
    address indexed holder,
    uint256 value
  );

  modifier icoResticted() {
    require(msg.sender == ico);
    _;
  }

  modifier isActive() {
    require(active);
    _;
  }

  function TokenVesting() public {
    active = false;
  }

  function init(address _token, address _ico) public onlyOwner {
    token = ERC20Basic(_token);
    ico = _ico;
    initialized = true;
    active = true;
  }

  function stop() public isActive onlyOwner {
    active = false;
  }

  function resume() public onlyOwner {
    require(!active);
    require(initialized);
    active = true;
  }

  /**
  * @dev Grant vested tokens.
  * @notice Only for ICO contract address.
  * @param _to Addres to grant tokens to.
  * @param _value Number of tokens granted.
  * @param _vesting Vesting finish timestamp.
  * @param _start Vesting start timestamp.
  */
  function grantVestedTokens(
      address _to,
      uint256 _value,
      uint256 _start,
      uint256 _vesting
  ) public icoResticted isActive {
    require(_value > 0);
    require(_vesting > _start);
    require(grants[_to].length < 10);

    TokenGrant memory grant = TokenGrant(_value, 0, _vesting, _start);
    grants[_to].push(grant);

    NewTokenGrant(_to, _value, _start, _vesting);
  }

  /**
  * @dev Claim all vested tokens up to current date for myself
  */
  function claimTokens() public {
    claim(msg.sender);
  }

  /**
  * @dev Claim all vested tokens up to current date in behaviour of an user
  * @param _to address Addres to claim tokens
  */
  function claimTokensFor(address _to) public onlyOwner {
    claim(_to);
  }

  /**
  * @dev Get claimable tokens
  */
  function claimableTokens() public constant returns (uint256) {
    address _to = msg.sender;
    uint256 numberOfGrants = grants[_to].length;

    if (numberOfGrants == 0) {
      return 0;
    }

    uint256 claimable = 0;
    uint256 claimableFor = 0;
    for (uint256 i = 0; i < numberOfGrants; i++) {
      claimableFor = calculateVestedTokens(
        grants[_to][i].value,
        grants[_to][i].vesting,
        grants[_to][i].start,
        grants[_to][i].claimed
      );
      claimable = claimable.add(claimableFor);
    }
    return claimable;
  }

  /**
  * @dev Get all veted tokens
  */
  function totalVestedTokens() public constant returns (uint256) {
    address _to = msg.sender;
    uint256 numberOfGrants = grants[_to].length;

    if (numberOfGrants == 0) {
      return 0;
    }

    uint256 claimable = 0;
    for (uint256 i = 0; i < numberOfGrants; i++) {
      claimable = claimable.add(
        grants[_to][i].value.sub(grants[_to][i].claimed)
      );
    }
    return claimable;
  }

  /**
  * @dev Calculate vested claimable tokens on current time
  * @param _tokens Number of tokens granted
  * @param _vesting Vesting finish timestamp
  * @param _start Vesting start timestamp
  * @param _claimed Number of tokens already claimed
  */
  function calculateVestedTokens(
      uint256 _tokens,
      uint256 _vesting,
      uint256 _start,
      uint256 _claimed
  ) internal constant returns (uint256) {
    uint256 time = block.timestamp;

    if (time < _start) {
      return 0;
    }

    if (time >= _vesting) {
      return _tokens.sub(_claimed);
    }

    uint256 vestedTokens = _tokens.mul(time.sub(_start)).div(
      _vesting.sub(_start)
    );

    return vestedTokens.sub(_claimed);
  }

  /**
  * @dev Claim all vested tokens up to current date
  */
  function claim(address _to) internal {
    uint256 numberOfGrants = grants[_to].length;

    if (numberOfGrants == 0) {
      return;
    }

    uint256 claimable = 0;
    uint256 claimableFor = 0;
    for (uint256 i = 0; i < numberOfGrants; i++) {
      claimableFor = calculateVestedTokens(
        grants[_to][i].value,
        grants[_to][i].vesting,
        grants[_to][i].start,
        grants[_to][i].claimed
      );
      claimable = claimable.add(claimableFor);
      grants[_to][i].claimed = grants[_to][i].claimed.add(claimableFor);
    }

    token.transfer(_to, claimable);
    circulatingSupply += claimable;

    NewTokenClaim(_to, claimable);
  }
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

// File: contracts/TokenSale.sol

/**
 * @title Crowdsale contract
 * @dev see https://send.sd/crowdsale
 */
contract TokenSale is Ownable {
  using SafeMath for uint256;

  /* Leave 10 tokens margin error in order to succedd
  with last pool allocation in case hard cap is reached */
  uint256 constant public HARD_CAP = 70000000 ether;
  uint256 constant public VESTING_TIME = 90 days;
  uint256 public weiUsdRate = 1;
  uint256 public btcUsdRate = 1;

  uint256 public vestingEnds;
  uint256 public startTime;
  uint256 public endTime;
  address public wallet;

  uint256 public vestingStarts;

  uint256 public soldTokens;
  uint256 public raised;

  bool public activated = false;
  bool public isStopped = false;
  bool public isFinalized = false;

  BurnableToken public token;
  TokenVesting public vesting;

  event NewBuyer(
    address indexed holder,
    uint256 sndAmount,
    uint256 usdAmount,
    uint256 ethAmount,
    uint256 btcAmount
  );

  event ClaimedTokens(
    address indexed _token,
    address indexed _controller,
    uint256 _amount
  );

  modifier validAddress(address _address) {
    require(_address != address(0x0));
    _;
  }

  modifier isActive() {
    require(activated);
    require(!isStopped);
    require(!isFinalized);
    require(block.timestamp >= startTime);
    require(block.timestamp <= endTime);
    _;
  }

  function TokenSale(
      uint256 _startTime,
      uint256 _endTime,
      address _wallet,
      uint256 _vestingStarts
  ) public validAddress(_wallet) {
    require(_startTime > block.timestamp - 60);
    require(_endTime > startTime);
    require(_vestingStarts > startTime);

    vestingStarts = _vestingStarts;
    vestingEnds = vestingStarts.add(VESTING_TIME);
    startTime = _startTime;
    endTime = _endTime;
    wallet = _wallet;
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
   * @dev set an exchange rate in satoshis
   * @param _rate uint256 The new exchange rate
   */
  function setBtcUsdRate(uint256 _rate) public onlyOwner {
    require(_rate > 0);
    btcUsdRate = _rate;
  }

  /**
   * @dev initialize the contract and set token
   */
  function initialize(
      address _sdt,
      address _vestingContract,
      address _icoCostsPool,
      address _distributionContract
  ) public validAddress(_sdt) validAddress(_vestingContract) onlyOwner {
    require(!activated);
    activated = true;

    token = BurnableToken(_sdt);
    vesting = TokenVesting(_vestingContract);

    // 1% reserve is released on deploy
    token.transfer(_icoCostsPool, 7000000 ether);
    token.transfer(_distributionContract, 161000000 ether);

    //early backers allocation
    uint256 threeMonths = vestingStarts.add(90 days);

    updateStats(0, 43387693 ether);
    grantVestedTokens(0x02f807E6a1a59F8714180B301Cba84E76d3B4d06, 22572063 ether, vestingStarts, threeMonths);
    grantVestedTokens(0x3A1e89dD9baDe5985E7Eb36E9AFd200dD0E20613, 15280000 ether, vestingStarts, threeMonths);
    grantVestedTokens(0xA61c9A0E96eC7Ceb67586fC8BFDCE009395D9b21, 250000 ether, vestingStarts, threeMonths);
    grantVestedTokens(0x26C9899eA2F8940726BbCC79483F2ce07989314E, 100000 ether, vestingStarts, threeMonths);
    grantVestedTokens(0xC88d5031e00BC316bE181F0e60971e8fEdB9223b, 1360000 ether, vestingStarts, threeMonths);
    grantVestedTokens(0x38f4cAD7997907741FA0D912422Ae59aC6b83dD1, 250000 ether, vestingStarts, threeMonths);
    grantVestedTokens(0x2b2992e51E86980966c42736C458e2232376a044, 105000 ether, vestingStarts, threeMonths);
    grantVestedTokens(0xdD0F60610052bE0976Cf8BEE576Dbb3a1621a309, 140000 ether, vestingStarts, threeMonths);
    grantVestedTokens(0xd61B4F33D3413827baa1425E2FDa485913C9625B, 740000 ether, vestingStarts, threeMonths);
    grantVestedTokens(0xE6D4a77D01C680Ebbc0c84393ca598984b3F45e3, 505630 ether, vestingStarts, threeMonths);
    grantVestedTokens(0x35D3648c29Ac180D5C7Ef386D52de9539c9c487a, 150000 ether, vestingStarts, threeMonths);
    grantVestedTokens(0x344a6130d187f51ef0DAb785e10FaEA0FeE4b5dE, 967500 ether, vestingStarts, threeMonths);
    grantVestedTokens(0x026cC76a245987f3420D0FE30070B568b4b46F68, 967500 ether, vestingStarts, threeMonths);
  }

  function finalize(
      address _poolA,
      address _poolB,
      address _poolC,
      address _poolD
  )
      public
      validAddress(_poolA)
      validAddress(_poolB)
      validAddress(_poolC)
      validAddress(_poolD)
      onlyOwner
  {
    grantVestedTokens(_poolA, 175000000 ether, vestingStarts, vestingStarts.add(7 years));
    grantVestedTokens(_poolB, 168000000 ether, vestingStarts, vestingStarts.add(7 years));
    grantVestedTokens(_poolC, 70000000 ether, vestingStarts, vestingStarts.add(7 years));
    grantVestedTokens(_poolD, 48999990 ether, vestingStarts, vestingStarts.add(4 years));

    token.burn(token.balanceOf(this));
  }

  function stop() public onlyOwner isActive returns(bool) {
    isStopped = true;
    return true;
  }

  function resume() public onlyOwner returns(bool) {
    require(isStopped);
    isStopped = false;
    return true;
  }

  function () public payable {
    uint256 usd = msg.value.div(weiUsdRate);
    doPurchase(usd, msg.value, 0, msg.sender, vestingEnds);
    forwardFunds();
  }

  function btcPurchase(
      address _beneficiary,
      uint256 _btcValue
  ) public onlyOwner validAddress(_beneficiary) {
    uint256 usd = _btcValue.div(btcUsdRate);
    doPurchase(usd, 0, _btcValue, _beneficiary, vestingEnds);
  }

  /**
  * @dev Number of tokens is given by:
  * usd * 100 ether / 14
  */
  function computeTokens(uint256 _usd) public pure returns(uint256) {
    return _usd.mul(100 ether).div(14);
  }

  //////////
  // Safety Methods
  //////////
  /// @notice This method can be used by the controller to extract mistakenly
  ///  sent tokens to this contract.
  /// @param _token The address of the token contract that you want to recover
  ///  set to 0 in case you want to extract ether.
  function claimTokens(address _token) public onlyOwner {
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

  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  /**
   * @notice The owner of this contract is the owner of token&#39;s contract
   * @param _usd amount invested in USD
   * @param _eth amount invested in ETH y contribution was made in ETH, 0 otherwise
   * @param _btc amount invested in BTC y contribution was made in BTC, 0 otherwise
   * @param _address Address to send tokens to
   * @param _vestingEnds vesting finish timestamp
   */
  function doPurchase(
      uint256 _usd,
      uint256 _eth,
      uint256 _btc,
      address _address,
      uint256 _vestingEnds
  )
      internal
      isActive
      returns(uint256)
  {
    require(_usd >= 10);

    uint256 soldAmount = computeTokens(_usd);

    updateStats(_usd, soldAmount);
    grantVestedTokens(_address, soldAmount, vestingStarts, _vestingEnds);
    NewBuyer(_address, soldAmount, _usd, _eth, _btc);

    return soldAmount;
  }

  /**
   * @dev Helper function to update collected and allocated tokens stats
   */
  function updateStats(uint256 usd, uint256 tokens) internal {
    raised = raised.add(usd);
    soldTokens = soldTokens.add(tokens);

    require(soldTokens <= HARD_CAP);
  }

  /**
   * @dev grant vested tokens
   * @param _to Adress to grant vested tokens
   * @param _value number of tokens to grant
   * @param _start vesting start timestamp
   * @param _vesting vesting finish timestamp
   */
  function grantVestedTokens(
      address _to,
      uint256 _value,
      uint256 _start,
      uint256 _vesting
  ) internal {
    token.transfer(vesting, _value);
    vesting.grantVestedTokens(_to, _value, _start, _vesting);
  }
}