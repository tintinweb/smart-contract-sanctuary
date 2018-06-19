contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MultistageCrowdsale {
  using SafeMath for uint256;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);

  struct Stage {
    uint32 time;
    uint64 rate;
  }

  Stage[] stages;

  address wallet;
  address token;
  address signer;
  uint32 saleEndTime;

  /**
   * @dev The constructor that takes all parameters
   * @param _timesAndRates An array that defines the stages of the contract. the first entry being the start time of the sale, followed by pairs of rates ond close times of consequitive stages.
   *       Example 1: [10000, 99, 12000]
   *         A single stage sale that starts at unix time 10000 and ends 2000 seconds later.
   *         This sale gives 99 tokens for each Gwei invested.
   *       Example 2: [10000, 99, 12000, 88, 14000]
   *         A 2 stage sale that starts at unix time 10000 and ends 4000 seconds later.
   *         The sale reduces the rate at mid time
   *         This sale gives 99 tokens for each Gwei invested in first stage.
   *         The sale gives 88 tokens for each Gwei invested in second stage.
   * @param _wallet The address of the wallet where invested Ether will be send to
   * @param _token The tokens that the investor will receive
   * @param _signer The address of the key that whitelists investor (operator key)
   */
  constructor(
    uint256[] _timesAndRates,
    address _wallet,
    address _token,
    address _signer
  )
    public
  {
    require(_wallet != address(0));
    require(_token != address(0));

    storeStages(_timesAndRates);

    saleEndTime = uint32(_timesAndRates[_timesAndRates.length - 1]);
    // check sale ends after last stage opening time
    require(saleEndTime > stages[stages.length - 1].time);

    wallet = _wallet;
    token = _token;
    signer = _signer;
  }

  /**
   * @dev called by investors to purchase tokens
   * @param _r part of receipt signature
   * @param _s part of receipt signature
   * @param _payload payload of signed receipt.
   *   The receipt commits to the follwing inputs:
   *     160 bits - beneficiary address - address whitelisted to receive tokens
   *     32 bits - time - when receipt was signed
   *     56 bits - sale contract address, to prevent replay of receipt
   *     8 bits - v-part of receipt signature
   */
  function purchase(bytes32 _r, bytes32 _s, bytes32 _payload) public payable {
    // parse inputs
    uint32 time = uint32(_payload >> 160);
    address beneficiary = address(_payload);
    // verify inputs
    require(uint56(_payload >> 192) == uint56(this));
    /* solium-disable-next-line arg-overflow */
    require(ecrecover(keccak256(uint8(0), uint56(_payload >> 192), time, beneficiary), uint8(_payload >> 248), _r, _s) == signer);
    require(beneficiary != address(0));

    // calculate token amount to be created
    uint256 rate = getRateAt(now); // solium-disable-line security/no-block-members
    // at the time of signing the receipt the rate should have been the same as now
    require(rate == getRateAt(time));
    // multiply rate with Gwei of investment
    uint256 tokens = rate.mul(msg.value).div(1000000000);
    // check that msg.value > 0
    require(tokens > 0);

    // pocket Ether
    wallet.transfer(msg.value);

    // do token transfer
    ERC20(token).transferFrom(wallet, beneficiary, tokens);
    emit TokenPurchase(beneficiary, msg.value, tokens);
  }

  function getParams() view public returns (uint256[] _times, uint256[] _rates, address _wallet, address _token, address _signer) {
    _times = new uint256[](stages.length + 1);
    _rates = new uint256[](stages.length);
    for (uint256 i = 0; i < stages.length; i++) {
      _times[i] = stages[i].time;
      _rates[i] = stages[i].rate;
    }
    _times[stages.length] = saleEndTime;
    _wallet = wallet;
    _token = token;
    _signer = signer;
  }

  function storeStages(uint256[] _timesAndRates) internal {
    // check odd amount of array elements, tuples of rate and time + saleEndTime
    require(_timesAndRates.length % 2 == 1);
    // check that at least 1 stage provided
    require(_timesAndRates.length >= 3);

    for (uint256 i = 0; i < _timesAndRates.length / 2; i++) {
      stages.push(Stage(uint32(_timesAndRates[i * 2]), uint64(_timesAndRates[(i * 2) + 1])));
      if (i > 0) {
        // check that each time higher than previous time
        require(stages[i-1].time < stages[i].time);
        // check that each rate is lower than previous rate
        require(stages[i-1].rate > stages[i].rate);
      }
    }

    // check that opening time in the future
    require(stages[0].time > now); // solium-disable-line security/no-block-members

    // check final rate > 0
    require(stages[stages.length - 1].rate > 0);
  }

  function getRateAt(uint256 _now) view internal returns (uint256 rate) {
    // if before first stage, return 0
    if (_now < stages[0].time) {
      return 0;
    }

    for (uint i = 1; i < stages.length; i++) {
      if (_now < stages[i].time)
        return stages[i - 1].rate;
    }

    // handle last stage
    if (_now < saleEndTime)
      return stages[stages.length - 1].rate;

    // sale already closed
    return 0;
  }

}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}