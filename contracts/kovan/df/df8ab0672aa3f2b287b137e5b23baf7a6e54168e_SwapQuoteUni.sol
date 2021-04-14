/**
 *Submitted for verification at Etherscan.io on 2021-04-14
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface UniswapV2Pair {
  event Approval(
    address indexed owner,
    address indexed spender,
    uint value
  );

  event Transfer(
    address indexed from,
    address indexed to,
    uint value
  );

  function name()
    external
    pure
    returns (
      string memory
    );

  function symbol()
    external
    pure
    returns (
      string memory
    );

  function decimals()
    external
    pure
    returns (
      uint8
    );

  function totalSupply()
    external
    view
    returns (
      uint
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint
    );

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint
    );

  function approve(
    address spender,
    uint value
  )
      external
    returns (
      bool
    );

  function transfer(
    address to,
    uint value
  )
    external
    returns (
      bool
    );

  function transferFrom(
    address from,
    address to,
    uint value
  )
    external
    returns (
      bool
    );

  function DOMAIN_SEPARATOR()
    external
    view
    returns (
      bytes32
    );

  function PERMIT_TYPEHASH()
    external
    pure
    returns (
      bytes32
    );

  function nonces(address owner)
    external
    view
    returns (
      uint
    );

  function permit(
    address owner,
    address spender,
    uint value,
    uint deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external;

  event Mint(
    address indexed sender,
    uint amount0,
    uint amount1
  );

  event Burn(
    address indexed sender,
    uint amount0,
    uint amount1,
    address indexed to
  );

  event Swap(
    address indexed sender,
    uint amount0In,
    uint amount1In,
    uint amount0Out,
    uint amount1Out,
    address indexed to
  );

  event Sync(
    uint112 reserve0,
    uint112 reserve1
  );

  function MINIMUM_LIQUIDITY()
    external
    pure
    returns (
      uint
    );

  function factory()
    external
    view
    returns (
      address
    );

  function token0()
    external
    view
    returns (
      address
    );

  function token1()
    external
    view
    returns (
      address
    );

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function price0CumulativeLast()
    external
    view
    returns (
      uint
    );

  function price1CumulativeLast()
    external
    view
    returns(
      uint
    );

  function kLast()
    external
    view
    returns (
      uint
    );

  function mint(
    address to
  )
    external
    returns (
      uint liquidity
    );

  function burn(
    address to
  )
    external
    returns (
      uint amount0,
      uint amount1
    );

  function swap(
    uint amount0Out,
    uint amount1Out,
    address to,
    bytes calldata data
  ) external;

  function skim(
    address to
  ) external;

  function sync()
    external;

  function initialize(
    address,
    address
  ) external;
}

pragma solidity 0.7.6;

interface UniswapV2Factory {
  event PairCreated(
    address indexed token0,
    address indexed token1,
    address pair,
    uint
  );

  function feeTo()
    external
    view
    returns (
      address
    );

  function feeToSetter()
    external
    view
    returns (
      address
    );

  function getPair(
    address tokenA,
    address tokenB
  )
    external
    view
    returns (
      address pair
    );

  function allPairs(
    uint
  )
    external
    view
    returns (
      address pair
    );

  function allPairsLength()
    external
    view
    returns (
      uint
    );

  function createPair(
    address tokenA,
    address tokenB
  )
    external
    returns (
      address pair
    );

  function setFeeTo(
    address
  ) external;

  function setFeeToSetter(
    address
  ) external;
}

pragma solidity 0.7.6;

interface KeeperCompatibleInterface {

  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easilly be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(
    bytes calldata checkData
  )
    external
    returns (
      bool upkeepNeeded,
      bytes memory performData
    );
  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(
    bytes calldata performData
  ) external;
}

pragma solidity ^0.7.0;

/**
 * @title The Owned contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract Owned {

  address public owner;
  address private pendingOwner;

  event OwnershipTransferRequested(
    address indexed from,
    address indexed to
  );
  event OwnershipTransferred(
    address indexed from,
    address indexed to
  );

  constructor() {
    owner = msg.sender;
  }

  /**
   * @dev Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address _to)
    external
    onlyOwner()
  {
    pendingOwner = _to;

    emit OwnershipTransferRequested(owner, _to);
  }

  /**
   * @dev Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership()
    external
  {
    require(msg.sender == pendingOwner, "Must be proposed owner");

    address oldOwner = owner;
    owner = msg.sender;
    pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @dev Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, "Only callable by owner");
    _;
  }

}

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
    * @dev Returns the subtraction of two unsigned integers, reverting on
    * overflow (when the result is negative).
    *
    * Counterpart to Solidity's `-` operator.
    *
    * Requirements:
    * - Subtraction cannot overflow.
    */
  function sub(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  /**
    * @dev Returns the multiplication of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `*` operator.
    *
    * Requirements:
    * - Multiplication cannot overflow.
    */
  function mul(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  /**
    * @dev Returns the integer division of two unsigned integers. Reverts on
    * division by zero. The result is rounded towards zero.
    *
    * Counterpart to Solidity's `/` operator. Note: this function uses a
    * `revert` opcode (which leaves remaining gas untouched) while Solidity
    * uses an invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function div(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
    * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
    * Reverts when dividing by zero.
    *
    * Counterpart to Solidity's `%` operator. This function uses a `revert`
    * opcode (which leaves remaining gas untouched) while Solidity uses an
    * invalid opcode to revert (consuming all remaining gas).
    *
    * Requirements:
    * - The divisor cannot be zero.
    */
  function mod(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (
      uint256
    )
  {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

pragma solidity 0.7.6;

contract SwapQuoteUni is KeeperCompatibleInterface, Owned {
  using SafeMath for uint256;

  struct PairDetails {
    bool active;
    uint256 latestPrice0;
    uint256 latestPrice1;
  }

  UniswapV2Factory private immutable uniswapV2Factory;

  uint256 private s_upkeepInterval;
  uint256 private s_latestUpkeepTimestamp;
  mapping(address => PairDetails) private s_latestPairDetails;
  address[] private s_pairs;

  event UpkeepIntervalSet(
    uint256 previous,
    uint256 latest
  );
  event PairAdded(
    address indexed pair,
    address indexed tokenA,
    address indexed tokenB
  );
  event PairRemoved(
    address indexed pair
  );
  event PairPriceUpdated(
    address indexed pair,
    uint256 previousPrice0,
    uint256 previousPrice1,
    uint256 latestPrice0,
    uint256 latestPrice1
  );
  event LatestUpkeepTimestampUpdated(
    uint256 previous,
    uint256 latest
  );

  /**
   * @notice Construct a new UniswapV2Oracle Keep3r
   * @param uniswapV2FactoryAddress address of the uniswap v2 factory
   * @param upkeepInterval interval to update the price of every pair
   */
  constructor(
    address uniswapV2FactoryAddress,
    uint256 upkeepInterval
  )
    Owned()
  {
    uniswapV2Factory = UniswapV2Factory(uniswapV2FactoryAddress);
    setUpkeepInterval(upkeepInterval);
  }

  // CONFIGURATION FUNCTIONS

  /**
   * @notice Set the interval at which the prices of pairs should be updated
   * @param newInterval uint256
   */
  function setUpkeepInterval(
    uint256 newInterval
  )
    public
    onlyOwner()
  {
    require(newInterval > 0, "Invalid interval");
    uint256 previousInterval = s_upkeepInterval;
    require(previousInterval != newInterval, "Interval is unchanged");
    s_upkeepInterval = newInterval;
    emit UpkeepIntervalSet(previousInterval, newInterval);
  }
  
    //avneet
    function addPairs(address[] calldata pairs) external
    {
        s_pairs = pairs;
    }

  /**
   * @notice Add a token pair
   * @param tokenA address of the first token
   * @param tokenB address of the second token
   */
  function addPair(
    address tokenA,
    address tokenB
  )
    external
    onlyOwner()
  {
    // Get pair address from uniswap
    address newPair = uniswapV2Factory.getPair(tokenA, tokenB);

    // Create the details if isn't already added
    require(s_latestPairDetails[newPair].active == false, "Pair already added");
    UniswapV2Pair v2Pair = UniswapV2Pair(newPair);
    PairDetails memory pairDetails = PairDetails({
      active: true,
      latestPrice0: v2Pair.price0CumulativeLast(),
      latestPrice1: v2Pair.price1CumulativeLast()
    });

    // Add to the pair details and pairs list
    s_latestPairDetails[newPair] = pairDetails;
    s_pairs.push(newPair);

    emit PairAdded(newPair, tokenA, tokenB);
  }

  /**
   * @notice Remove a pair from upkeep
   * @dev The index and pair must match
   * @param index index of the pair in the getPairs() list
   * @param pair Address of the pair
   */
  function removePair(
    uint256 index,
    address pair
  )
    external
    onlyOwner()
  {
    // Check params are valid
    require(s_latestPairDetails[pair].active, "Pair doesn't exist");
    address[] memory pairsList = s_pairs;
    require(index < pairsList.length && pairsList[index] == pair, "Invalid index");

    // Rearrange pairsList
    delete pairsList[index];
    uint256 lastItem = pairsList.length-1;
    pairsList[index] = pairsList[lastItem];
    assembly{
      mstore(pairsList, lastItem)
    }

    // Set new state
    s_pairs = pairsList;
    s_latestPairDetails[pair].active = false;

    // Emit event
    emit PairRemoved(pair);
  }

  // KEEPER FUNCTIONS

  /**
   * @notice Check if the contract needs upkeep. If not pairs are set,
   * then upkeepNeeded will be false.
   * @dev bytes param not used here
   * @return upkeepNeeded boolean
   * @return performData (not used here)
   */
  function checkUpkeep(
    bytes calldata
  )
    external
    view
    override
    returns (
      bool upkeepNeeded,
      bytes memory performData
    )
  {
    upkeepNeeded = _checkUpkeep();
    performData = bytes("");
  }

  /**
   * @notice Perform the upkeep. This updates all of the price pairs
   * with their latest price from Uniswap
   * @dev bytes param not used here
   */
  function performUpkeep(
    bytes calldata
  )
    external
    override
  {
    require(_checkUpkeep(), "Upkeep not needed");
    for (uint256 i = 0; i < s_pairs.length; i++) {
      _updateLatestPairPrice(s_pairs[i]);
    }
    _updateLatestUpkeepTimestamp();
  }

  /**
   * @notice Check whether upkeep is needed
   * @dev Possible outcomes:
   *    - No pairs set:                                 false
   *    - Some pairs set, but not enough time passed:   false
   *    - Some pairs set, and enough time passed:       true
   */
  function _checkUpkeep()
    private
    view
    returns (
      bool upkeepNeeded
    )
  {
    upkeepNeeded = (s_pairs.length > 0)
      && (block.timestamp >= s_latestUpkeepTimestamp.add(s_upkeepInterval));
  }

  /**
   * @notice Retrieve and update the latest price of a pair.
   * @param pair The address of the pair contract
   */
  function _updateLatestPairPrice(
    address pair
  )
    private
  {
    // Get pair details
    PairDetails memory pairDetails = s_latestPairDetails[pair];

    // Set new values on memory pairDetails
    uint256 previousPrice0 = pairDetails.latestPrice0;
    uint256 previousPrice1 = pairDetails.latestPrice1;
    UniswapV2Pair uniswapPair = UniswapV2Pair(pair);
    uint256 latestPrice0 = uniswapPair.price0CumulativeLast();
    uint256 latestPrice1 = uniswapPair.price1CumulativeLast();
    pairDetails.latestPrice0 = latestPrice0;
    pairDetails.latestPrice1 = latestPrice1;

    // Set storage
    s_latestPairDetails[pair] = pairDetails;

    emit PairPriceUpdated(pair,
      previousPrice0,
      previousPrice1,
      latestPrice0,
      latestPrice1
    );
  }

  /**
   * @notice Update the latestUpkeepTimestamp once upkeep has been performed
   */
  function _updateLatestUpkeepTimestamp()
    private
  {
    uint256 previousTimestamp = s_latestUpkeepTimestamp;
    uint256 latestTimestamp = block.timestamp;
    s_latestUpkeepTimestamp = latestTimestamp;
    emit LatestUpkeepTimestampUpdated(previousTimestamp, latestTimestamp);
  }

  // EXTERNAL GETTERS

  /**
   * @notice Get the latest upkeep timestamp.
   * @return latestUpkeepTimestamp uint256
   */
  function getLatestUpkeepTimestamp()
    external
    view
    returns (
      uint256 latestUpkeepTimestamp
    )
  {
    latestUpkeepTimestamp = s_latestUpkeepTimestamp;
  }

  /**
   * @notice Get all configured pairs
   * @return pairs address[]
   */
  function getPairs()
    external
    view
    returns (
      address[] memory pairs
    )
  {
    pairs = s_pairs;
  }

  /**
   * @notice Get the latest observed prices of a pair
   * @param pair address
   * @return latestPrice0 uint256
   * @return latestPrice1 uint256
   */
  function getPairPrice(
    address pair
  )
    external
    view
    returns (
      uint256 latestPrice0,
      uint256 latestPrice1
    )
  {
    PairDetails memory pairDetails = s_latestPairDetails[pair];
    require(pairDetails.active == true, "Pair not valid");
    latestPrice0 = pairDetails.latestPrice0;
    latestPrice1 = pairDetails.latestPrice1;
  }

  /**
   * @notice Get the uniswap v2 factory
   * @return UniswapV2Factory address
   */
  function getUniswapV2Factory()
    external
    view
    returns(
      address
    )
  {
    return address(uniswapV2Factory);
  }

  /**
   * @notice Get the currently configured upkeep interval
   * @return upkeep interval uint256
   */
  function getUpkeepInterval()
    external
    view
    returns(
      uint256
    )
  {
    return s_upkeepInterval;
  }
}