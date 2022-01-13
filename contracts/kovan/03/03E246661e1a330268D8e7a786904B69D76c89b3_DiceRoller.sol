// SPDX-License-Identifier: MIT
// pragma solidity ^0.8.4;

// pragma solidity ^0.6.6;
// pragma experimental ABIEncoderV2;
pragma solidity >=0.6.6 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

/*
    https://docs.chain.link/docs/vrf-contracts/
    Testnet LINK are available from https://faucets.chain.link/kovan
    Kovan deploy values:
    const contract = await contractFactory.deploy(
        0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRFCOORDINATOR
        0xa36085F69e2889c224210F603D836748e7dC0088, // LINK
        0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4,  // KEYHASH
        100000000000000000 // FEE = 0.1 LINK
    ); 
*/
contract DiceRoller is VRFConsumerBase, Pausable, Ownable {
    /// Using these values to manipulate the random value on each die roll.
    /// The goal is an attempt to further randomize randomness for each die rolled.
    /**
    * 77194726158210796949047323339125271902179989777093709359638389338608753093290
    * 0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    * 10101010101010101010101010101...
    */
    uint constant MODIFIER_VALUE_1 = 77194726158210796949047323339125271902179989777093709359638389338608753093290;

    /**
    * 38597363079105398474523661669562635951089994888546854679819194669304376546645
    * 0x55555555555555555555555555555555555555555555555555555555555555555
    * 0101010101...
    */
    uint constant MODIFIER_VALUE_2 = 38597363079105398474523661669562635951089994888546854679819194669304376546645;
    uint8 constant MAX_DICE_ALLOWED = 10;
    uint8 constant MAX_DIE_SIZE_ALLOWED = 100;
    int8 constant MAX_ADJUSTMENT_ALLOWED = 20;
    int8 private constant ROLL_IN_PROGRESS = 42;

    bytes32 private chainLinkKeyHash;
    uint256 private chainlinkVRFFee;

    struct DiceRollee {
        address rollee;
        uint256 timestamp; // When the die were rolled
        uint256 randomness; // Stored to help verify/debug results
        uint16 numberOfDie; // 1 = roll once, 4 = roll four die
        uint16 dieSize; // 6 = 6 sided die, 20 = 20 sided die
        int16 adjustment; // Can be a positive or negative value
        int16 result; // Result of all die rolls and adjustment. Can be negative because of a negative adjustment.
        // Max value can be 1000 (10 * 100 sided die rolled)
        uint8[] rolledValues; // array of individual rolls. These can only be positive.
    }

    /**
    * Mapping between the requestID (returned when a request is made), 
    * and the address of the roller. This is so the contract can keep track of 
    * who to assign the result to when it comes back.
    */
    mapping(bytes32 => address) private rollersRandomRequest;

    /// Used to indicate if an address has ever rolled.
    mapping(address => bool) private rollers;

    /// stores the roller and the state of their current die roll.
    mapping(address => DiceRollee) private currentRoll;

    /// users can have multiple die rolls
    mapping (address => DiceRollee[]) rollerHistory;

    /// keep list of user addresses for fun/stats
    /// can iterate over them later.
    address[] internal rollerAddresses;

    /// Emit this when either of the rollDice functions are called.
    /// Used to notify soem front end that we are waiting for response from
    /// chainlink VRF.
    event DiceRolled(bytes32 indexed requestId, address indexed roller);

    /// Emitted when fulfillRandomness is called by Chainlink VRF to provide the random value.
    event DiceLanded(
        bytes32 indexed requestId, 
        address indexed roller, 
        uint8[] rolledvalues, 
        int16 adjustment, 
        int16 result
        );

    modifier validateNumberOfDie(uint8 _numberOfDie) {
        require(_numberOfDie <= MAX_DICE_ALLOWED, "Too many dice!");
        _;
    }

    modifier validateDieSize(uint8 _dieSize) {
        require(_dieSize <= MAX_DIE_SIZE_ALLOWED, "100 sided die is the max allowed.");
        _;
    }

    modifier validateAdjustment(int8 _adjustment) {
        int8 tempAdjustment = _adjustment >= 0 ? _adjustment : -_adjustment; // convert to positive value and test that.
        require(tempAdjustment <= MAX_ADJUSTMENT_ALLOWED, "Adjustment is too large.");
        _;
    }

    constructor(address _vrfCoordinator, address _link, bytes32 _keyHash, uint256 _fee)
        VRFConsumerBase(_vrfCoordinator, _link)
    {
        chainLinkKeyHash = _keyHash;
        chainlinkVRFFee = _fee;
    }

    fallback() external payable {}
    receive() external payable {}

    function refundTokens() public payable {
        LINK.transfer(payable(owner()), getLINKBalance());
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() external virtual onlyOwner whenNotPaused {
       _pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() external virtual onlyOwner whenPaused {
        _unpause();
    }

    /**
    * When the contract is killed, make sure to return all unspent tokens back to my wallet.
    */
    function kill() external {
        LINK.transfer(owner(), getLINKBalance());
        selfdestruct(payable(owner()));
    }

    /// Used to perform specific logic based on if user has rolled previoulsy or not.
    function hasRolledBefore(address _member) public view returns(bool) {
        return (rollers[_member]);
    }

    /**
    * Called by the front end if user wants to use the front end to 
    * generate the random values. We just use this to store the result of the roll on the blockchain.
    *
    * @param _numberOfDie how many dice are rolled
    * @param _dieSize the type of die rolled (4 = 4 sided, 6 = six sided, etc.)
    * @param _adjustment the modifier to add after all die have been rolled. Can be negative.
    * @param _result can be negative if you have a low enough dice roll and larger negative adjustment.
    * Example, rolled 2 4 sided die with -4 adjustment.
    */
    function hasRolled(uint8 _numberOfDie, uint8 _dieSize, int8 _adjustment, int8 _result) 
        public 
        whenNotPaused
        validateNumberOfDie(_numberOfDie)
        validateDieSize(_dieSize)
        validateAdjustment(_adjustment)
    {
        DiceRollee memory diceRollee = DiceRollee({
                rollee: msg.sender, 
                timestamp: block.timestamp,
                randomness: 0, 
                numberOfDie: _numberOfDie, 
                dieSize: _dieSize, 
                adjustment: _adjustment, 
                result: _result, 
                rolledValues: new uint8[](0)
        });

        rollerHistory[msg.sender].push(diceRollee);

        /// Only add roller to this list once.
        if (! hasRolledBefore(msg.sender)) {
            rollers[msg.sender] = true;
            rollerAddresses.push(msg.sender);
        }
    }
    

    /**
     * @notice Requests randomness from Chainlink.
     *
     * @param _numberOfDie how many dice are rolled
     * @param _dieSize the type of die rolled (4 = 4 sided, 6 = six sided, etc.)
     * @param _adjustment the modifier to add after all die have been rolled. Can be negative.
     */
    function rollDice(
        uint8 _numberOfDie, 
        uint8 _dieSize, 
        int8 _adjustment) 
        public 
        whenNotPaused
        validateNumberOfDie(_numberOfDie)
        validateDieSize(_dieSize)
        validateAdjustment(_adjustment)
        returns (bytes32 requestId) 
    {
        /// checking LINK balance to make sure we can call the Chainlink VRF.
        require(LINK.balanceOf(address(this)) >= chainlinkVRFFee, "Not enough LINK to pay fee");

        /// Call to Chainlink VRF for randomness
        requestId = requestRandomness(chainLinkKeyHash, chainlinkVRFFee);
        // requestId = keccak256(abi.encodePacked(chainLinkKeyHash, block.timestamp));
        rollersRandomRequest[requestId] = msg.sender;

        DiceRollee memory diceRollee = DiceRollee({
                rollee: msg.sender, 
                timestamp: block.timestamp,
                randomness: 0, 
                numberOfDie: _numberOfDie, 
                dieSize: _dieSize, 
                adjustment: _adjustment, 
                result: ROLL_IN_PROGRESS, 
                rolledValues: new uint8[](_numberOfDie)
        });

        /// Only add roller to this list once.
        if (! hasRolledBefore(msg.sender)) {
            rollers[msg.sender] = true;
            rollerAddresses.push(msg.sender);
        }

        currentRoll[msg.sender] = diceRollee;
        emit DiceRolled(requestId, msg.sender);
    }


    /**
     * @notice Uses psuedo randomness based on blockchain data. This function is used to 
     * compare speed of getting some sort of randomness straight from the blockchain 
     * instead of waiting for Chainlink VRF to return a random value.
     *
     * @param _numberOfDie how many dice are rolled
     * @param _dieSize the type of die rolled (4 = 4 sided, 6 = six sided, etc.)
     * @param _adjustment the modifier to add after all die have been rolled. Can be negative.
     */
    function rollDiceFast(
        uint8 _numberOfDie, 
        uint8 _dieSize, 
        int8 _adjustment) 
        public 
        whenNotPaused
        validateNumberOfDie(_numberOfDie)
        validateDieSize(_dieSize)
        validateAdjustment(_adjustment)
        returns (bytes32 requestId) 
    {
        /// Simple hacky way to generate a requestId.
        requestId = keccak256(abi.encodePacked(chainLinkKeyHash, block.timestamp));
        rollersRandomRequest[requestId] = msg.sender;

        DiceRollee memory diceRollee = DiceRollee({
                rollee: msg.sender, 
                timestamp: block.timestamp,
                randomness: 0, 
                numberOfDie: _numberOfDie, 
                dieSize: _dieSize, 
                adjustment: _adjustment, 
                result: ROLL_IN_PROGRESS, 
                rolledValues: new uint8[](_numberOfDie)
        });

        currentRoll[msg.sender] = diceRollee;

        /// Only add roller to this list once.
        if (! hasRolledBefore(msg.sender)) {
            rollers[msg.sender] = true;
            rollerAddresses.push(msg.sender);
        }

        emit DiceRolled(requestId, msg.sender);
        uint256 randomness = (block.timestamp + block.difficulty);
        fulfillRandomness(requestId, randomness);
    }

    /// returns historic data for specific address/user
    function getUserRolls(address _address) public view returns (DiceRollee[] memory) {
        return rollerHistory[_address];
    }

    /// How many times someone rolled.
    function getUserRollsCount(address _address) public view returns (uint) {
        return rollerHistory[_address].length;
    }

    /// only allow the contract owner (me) to access this.
    function getAllUsers() public view returns (address[] memory) {
        return rollerAddresses;
    }

    function getAllUsersCount() public view returns (uint) {
        return rollerAddresses.length;
    }

    function getRoller(address _roller) view public returns (DiceRollee memory) {
        return currentRoll[_roller];
    }

    function getBalance() view public returns (uint256) {
        return address(this).balance;
    }

    // https://medium.com/@blockchain101/calling-the-function-of-another-contract-in-solidity-f9edfa921f4c
    // https://medium.com/coinmonks/get-token-balance-for-any-eth-address-by-using-smart-contracts-in-js-b603fef2061c
    // returns the amount of LINK tokens this contract has.
    function getLINKBalance() view public returns (uint256) {
       return LINK.balanceOf(address(this));
    }

    /**
     * @notice Callback function used by VRF Coordinator to return the random number
     * to this contract.
     *
     * This is the core function where we try to generate random values from a single
     * random value provided. For each die to roll, we use the passed inrandom value
     * perform some calculation on it to generate a new "random" value that we then
     * perform the mod on. Goal is if you are rolling x 10 sided die, each roll 
     * generates a different value.
     *
     * @param _requestId bytes32
     * @param _randomness The random result returned by the oracle
     */
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override{
        /// Associate the random value with the roller based on requestId.
        DiceRollee storage rollee = currentRoll[rollersRandomRequest[_requestId]];
        delete rollee.rolledValues;
        rollee.randomness = _randomness;

        uint counter; /// Tracks how many die have been rolled.
        int calculatedValue;

        /// iterate over each die to be rolled and calc the value based on a sort of randomness.
        while (counter < rollee.numberOfDie) {
            uint curValue;
            uint v = _randomness;
            
            /**
             *   This code attempts to force enough chnge in the passed random value
             *   so that can look like it generates multiple random numbers.
            */
            if (counter % 2 == 0) {
                if (counter > 0){
                    v = _randomness / (100*counter);
                }
                /// Add 1 to prevent returning 0
                curValue = addmod(v, MODIFIER_VALUE_1, rollee.dieSize) + 1;
            } else {
                if (counter > 0) {
                    v = _randomness / (99*counter);
                }
                /// Add 1 to prevent returning 0
                curValue = mulmod(v, MODIFIER_VALUE_2, rollee.dieSize) + 1;
            }

            calculatedValue += int(curValue);
            rollee.rolledValues.push( uint8(curValue) );
            ++counter;
        }// while

        calculatedValue += rollee.adjustment;
        rollee.result = int16(calculatedValue);
        address rollerAdress = rollersRandomRequest[_requestId];
        currentRoll[rollerAdress] = rollee;
        rollerHistory[rollerAdress].push(rollee);
        emit DiceLanded(_requestId, rollee.rollee, rollee.rolledValues, rollee.adjustment, rollee.result);
    }


    function isOwner() internal view virtual returns (bool) {
        return msg.sender == owner();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
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
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

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
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

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
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
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