/**
 *Submitted for verification at Etherscan.io on 2021-10-12
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.6.12;



// Part: OpenZeppelin/[email protected]/Context

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// Part: smartcontractkit/[email protected]/AggregatorV3Interface

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}

// Part: smartcontractkit/[email protected]/LinkTokenInterface

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

// Part: smartcontractkit/[email protected]/SafeMathChainlink

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
library SafeMathChainlink {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
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
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
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
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
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
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

// Part: smartcontractkit/[email protected]/VRFRequestIDBase

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(bytes32 _keyHash, uint256 _userSeed,
    address _requester, uint256 _nonce)
    internal pure returns (uint256)
  {
    return  uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// Part: OpenZeppelin/[email protected]/Ownable

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// Part: smartcontractkit/[email protected]/VRFConsumerBase

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  using SafeMathChainlink for uint256;

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness)
    internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee)
    internal returns (bytes32 requestId)
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash].add(1);
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) public {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// File: Lottery.sol

// 
// DEFINING Contract.
//


// Inheriting it from @openzeppelin/contracts/access/Ownable.sol 
// and @chainlink/contracts/src/v0.6/VRFConsumerBase.sol contracts.
contract Lottery is VRFConsumerBase, Ownable {
    

    //
    // DECLARING types and state variables.
    //


    // Keeping track of all different players that are entering the lottery
    // by paying the entrance fee.
    address payable[] public players;
    // Declaring a recent winner and letting him/her to recieve the reward.
    address payable public recentWinner;
   
    // ???
    uint256 public randomness;
    // Declaring the entry fee in USD.
    uint256 public usdEntryFee;
    // Declaring the fee (in LINK token) of how much we will pay to a Chainlink node for its services to giving us a randomness.
    // Chainlink Node Fees: https://docs.chain.link/docs/vrf-contracts/
    uint256 public fee;
    
    // Uniquely identifies Verified Randomness Function (VRF) of the Chainlink node that we are gonna use.
    bytes32 public keyhash;

    /**
     * Declaring an event.
     *
     * Events are a way for your contract to communicate that something happened on the blockchain to your app front-end, 
     * which can be 'listening' for certain events and take action when they happen.
     *
     * // declare the event
     * event IntegersAdded(uint x, uint y, uint result);
     * 
     * function add(uint _x, uint _y) public returns (uint) {
     *     uint result = _x + _y;
     *     // fire an event to let the app know the function was called:
     *     emit IntegersAdded(_x, _y, result);
     *     return result;
     * }
     *
     * More info: 'https://cryptozombies.io/en/lesson/1/chapter/13'
     *
     */
    event RequestedRandomness(bytes32 requestId);

    // We can interact with other contracts by declaring its interface.
    // Declaring the price feed of ETH in USD that can only be called within the contract itself and any derived contracts.
    // Internal and Private: 'https://ethereum.stackexchange.com/questions/631/internal-keyword-in-a-function-definition-in-solidity'
    AggregatorV3Interface internal ethUsdPriceFeed;
    
    /**
     * Defining a new type called LOTTERY_STATE to keep a track of a state of the lottery.
     * We wanna make sure that the lottery not ends before the lottery starts and ended before even it began.
     * Enums are one way to create a user-defined type in Solidity. They are explicitly convertible to and from all integer types but impicit conversion is not allowed.
     */
    enum LOTTERY_STATE {
        OPEN,               // == 0
        CLOSED,             // == 1
        CALCULATING_WINNER  // == 2
    }
    LOTTERY_STATE public lottery_state;
    

    //
    // DECLARING Constructor.
    //


    /**
     * Running the constructor (actually 2 constr.) immediatly when the contract is deployed.
     * 
     * We passing the parameters from AggregatorV3Interface, VRFConsumerBase-constructor()
     * 
     * 1. _priceFeedAddress is an address of our aggregator (e.i. ETH/USD) 
     * that we are putting to AggregatorV3Interface in order to know the current price of i.e. ETH in USD.
     * Docs: 'https://docs.chain.link/docs/get-the-latest-price/#solidity'
     * Eth.addresses: 'https://docs.chain.link/docs/ethereum-addresses/'
     *
     * 2. _vrfCoordinator is an address of chain contract wherein gonna be deployed and verify and insure that a returned number is trully random.
     * Docs: 'https://docs.chain.link/docs/get-a-random-number/#random-number-consumer'
     *
     * 3. _link is an address of the chainlink node whereto we pay some LINK-tokens for its services.
     * In this case for providing to us a randomness.
     * Docs: 'https://docs.chain.link/docs/get-a-random-number/#random-number-consumer'
     * 
     * 4. _fee is how much link we are actually pay to the chainlink node for delivering us its services.
     * Docs: 'https://docs.chain.link/docs/get-a-random-number/#random-number-consumer'
     *
     * We pay always some sort of comission:
     * ETH -> Pay ETH gas (or transaction gas)
     * LINK - > Pay some LINK gas (or oracle gas), for providing some data etc.
     * Whereas for AggregatorV3Interface PriceFeed is somebody already payed (sponsors). https://data.chain.link/ethereum/mainnet/crypto-usd/eth-usd

     * 5. _keyhash uniquely identifies VRF of the Chainlink node that we are gonna use.
     * Docs: 'https://docs.chain.link/docs/get-a-random-number/#random-number-consumer'
     */
    constructor(
        address _priceFeedAddress, 
        address _vrfCoordinator, 
        address _link, 
        uint256 _fee,
        bytes32 _keyhash
    ) public VRFConsumerBase(_vrfCoordinator, _link) {
        // Setting up the entry fee for the players. 50 USD and converting it to wei since 1 ETH is 10**18 wei.
        // Converter: 'https://eth-converter.com/'
        usdEntryFee = 50 * (10**18); // Has 18 decimals. 
        // Getting the latest price of 1 ETH in USD.
        // Now 'ethUsdPriceFeed' is pointing to the other contract (_priceFeedAddress) and we can intract with its functions.
        // Returns 8 decimal number (f.e. $3500 * 10**8 = 350000000000).
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        // Declaring that lottery state is closed.
        lottery_state = LOTTERY_STATE.CLOSED; // the same as lottery_state = 1;
        // Declaring the fee to pay to a Chainlink node for its services.
        fee = _fee;
        // VRF identifier of the Chainlink node.
        keyhash = _keyhash;
    }


    //
    // DEFINING Functions.
    //


    /**
     * Our Lottery Contract has 4 main functions:
     * 
     * 1. startLottery()
     * Starting the Lottery.
     * 
     * 2. enter()
     * Entry Point of the Lottery.
     *
     * 3. getEntranceFee()
     * Converting usdEntryFee into ETH amount.
     *
     * 4. endLottery()
     * Ending the Lottery by requiesting the randomness from a Chainlink node to define a winner.
     *
     * Only the VRFCoordinator can be the one to call and return this function fulfillRandomness() (internal).
     * Here we recieve the randomness thus we defining our random winner and rewarding.
     *
     */

    // 
    // STEP 1.
    //
    
    // Start the lottery. Can be called only by admin (owner of the contract or the one who first deploy it).
    function startLottery() public onlyOwner {
        // We can only start the lottery if the lottery is closed otherwise return a failure function.
        require(lottery_state == LOTTERY_STATE.CLOSED, "Can't start a new lottery yet!");
        // If lottery state is closed, make it open and we will be able to enter into it.
        lottery_state = LOTTERY_STATE.OPEN;
    }

    //
    // STEP 2.
    //

    // Since we want them to pay an entry fee using this entry function in ETH, we need to make this function payable.
    function enter() public payable { 
        // We can only enter if the admin started this lottery.
        require(lottery_state == LOTTERY_STATE.OPEN); // If True, continue
        // Require that the player pays more or equal to of entry fee and if it is not True return the string.
        require(msg.value >= getEntranceFee(), "Not enough ETH!");
        // Adding the player (player's address) to the list with all different players.
        players.push(msg.sender);
    }

    // Getting an updated Entrance Fee in ETH using AggregatorV3Interface.
    function getEntranceFee() public view returns (uint256) {
        // Getting the latest price of ETH in USD with 18 decimals.
        // 'https://github.com/smartcontractkit/chainlink/blob/master/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol'
        // 'https://docs.chain.link/docs/get-the-latest-price/#solidity'
        (, int price, , , ) = ethUsdPriceFeed.latestRoundData(); // returns with 18 decimals.
        // Since we know that we gonna use ETH / USD 'https://docs.chain.link/docs/ethereum-addresses/'
        // price feed that has 8 decimals lets also add 10 more decimals as well.
        uint256 adjustedPrice = uint256(price) * 10 ** 10; // 10 + 8 = 18 decimals
        // $50, $3500/ETH
        // Getting ETH $50 / 3500 (Solidity does not work with decimals!).
        // This is what we should do: 
        // 50 * <some big number> / 3500
        uint256 costToEnter = (usdEntryFee * 10 ** 18) / adjustedPrice; // Matching units of measure.
        return costToEnter;
    }

    //
    // STEP 3.
    //
    
    /**
     * Getting a trully random number in a deterministic system (like Blockchain) is actually impossible, 
     * because each node will generate an own random number.
     *
     * Having exploitable randomness will doom you! Espesially working with a financial system.
     * Example of malicious bug: 'forum.openzeppelin.com/t/understanding-the-meebits-exploit/8281/2'
     *
     * One of the solution to this problem is to using an unit of randomness and translate it into a hash.
     *
     * Pseudorandom numbers.
     * https://docs.soliditylang.org/en/v0.8.6/units-and-global-variables.html#block-and-transaction-properties
     * msg.value and msg.sender are some examples of globally available variables.
     *
     * Here we are defining the difficulty of our random number.
     * Basically what we are gonna do here is taking a bunch of random numbers, mash them all together 
     * in a hashing function and then say "yeah it's pretty random". But (everything in there is predictable)...
     * This is not an effective way to get a random number. Example of this ineffectiveness:
     *
     *
     * uint256(                         // 256 because we wanna return then the index of our winner from players array.
     *     keccack256(                  // keccak256 is a hashing algorithm.
     *         abi.encodePacked(        // abi is for low level code.
     *             nonce,               // nonce is predicable (aka, transaction number)
     *             msg.sender,          // msg.sender is also predictable.
     *             block.difficulty,    // difficulty can actually be manipulated by the miners!
     *             block.timestamp      // timestamp is predictable.
     *         )
     *     )
     * ) % player.length;
     *
     *
     * -> TO GET A TRULLY RANDOM NUMBER WE ARE GOING TO USE CHAINLINK VRF. <-
     *
     *
     * In order to get a true random number we are gonna look outside of the Blockchain.
     * Blockchain by itself is a deterministic system.
     * We will use the Chainlink VRF (Verifiable Randomness Function) (an API). https://docs.chain.link/docs/get-a-random-number/
     * 
     * What we did in Remix (https://remix.ethereum.org/#url=https://docs.chain.link/samples/VRF/RandomNumberConsumer.sol):
     * 
     * With the assistance of this contract we can generate a trully random number.
     * In order to do this we need to feed this contract with some LINK to interact with it.
     * 0. Deploy the contract (Kovan).
     * 1. Copy the contract address -> Pass to send section -> Enter minimum amount of LINK (0.1 LINK) and send it (Kovan net.).
     * 2. Then press getRandomNumber yellow button. Complete the transaction.
     * 3. After that press randomResult. It will return 0. The problem is as know as Request and Recieve. More about this:
     *    --> https://docs.chain.link/docs/architecture-request-model/
     * 4. So if we wait a little bit and we press randomResult now we get a random number.
     * We have to wait a little bit because there occur 2 transactions:
     *    1. getRandomNumber()
     *    2. fulfillRandomness()
     *
     * ... is what we gonna do here.
     */


    //
    // RANDOMNESS with Chainlink VRF.
    //
    

    // Requesting a randomness from a Chainlink node by assigning keyhash and paying fee.
    function endLottery() public onlyOwner {
   
        // Nobody can enter and start the lottery.
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;

        // Requesting a random number from VRFConsumerBase.sol.
        bytes32 requestId = requestRandomness(keyhash, fee);
        // For test purposes. Closing the event.
        emit RequestedRandomness(requestId);
    }

    // Recieving the randomness.
    // Only the VRFCoordinator can be the one to call and return this function (internal).
    // We also overriding the original declaration of fulfillRandomness function from VRFConsumerBase.sol.
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) 
        internal 
        override 
    {
        require(
            lottery_state == LOTTERY_STATE.CALCULATING_WINNER, 
            "You aren't there yet!"
        );
        require(_randomness > 0, "random-not-found");
        
        /**
         * Picking a random winner from our list with players with assistance of modulo % function.
         * 
         * Example:
         * 7 players
         * 22 is the random number.
         * 22 % 7 = 1
         * 7 * 3 = 21
         * 7 * 4 = 28
         *
         */

        uint256 indexOfWinner = _randomness % players.length;
        recentWinner = players[indexOfWinner];
        // Paying the reward.
        recentWinner.transfer(address(this).balance);
        // Reset the lottery.
        players = new address payable[](0); // new array with the size of zero.
        // Closing the lottery.
        lottery_state = LOTTERY_STATE.CLOSED;
        // ??? Why do we assigning the value to the variable if it's already ended ???
        randomness = _randomness;
    }
}