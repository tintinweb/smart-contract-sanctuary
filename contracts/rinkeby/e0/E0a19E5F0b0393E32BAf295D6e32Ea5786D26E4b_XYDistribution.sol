// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@unification-com/xfund-vor/contracts/VORConsumerBase.sol";

/** ****************************************************************************
 * @notice Extremely simple Distrubution using VOR
 * *****************************************************************************
 *
 */
contract XYDistribution is Ownable, VORConsumerBase {
    using SafeMath for uint256;

    // keep track of the monsters
    uint256 public nextDistributionId;

    enum DataType { ZERO, ONE_TO_ONE_MAPPING, X_FROM_Y }
    
    // user request
    struct Distribution {
        string ipfs;
        uint256 sourceCount;
        uint256 destCount;
        DataType dataType;
        bytes32 keyHash;
        uint256 fee;
        uint256 seed;
        uint256 result;
    }

    // distribution held in the contract
    mapping (uint256 => Distribution) public distributions;

    // map request IDs to distribution IDs
    mapping(bytes32 => uint256) public requestIdToDistributionId;
    mapping(bytes32 => address) public requestIdToAddress;
    mapping(address => string) public monikers;
    
    // Some useful events to track
    event NewMoniker(address requester, string moniker);
    event StartingDistribute(uint256 distID, bytes32 requestID, address sender, string ipfs, uint256 sourceCount, uint256 destCount, DataType dataType, uint256 seed, bytes32 keyHash, uint256 fee);
    event DistributeResult(uint256 distID, bytes32 requestID, address sender, uint256 beginIndex, uint256 sourceCount, uint256 destCount, DataType dataType);

    /**
    * @notice Constructor inherits VORConsumerBase
    *
    * @param _vorCoordinator address of the VOR Coordinator
    * @param _xfund address of the xFUND token
    */
    constructor(address _vorCoordinator, address _xfund)
    public
    VORConsumerBase(_vorCoordinator, _xfund) {
        nextDistributionId = 1;
    }

    /**
    * @notice startDistribute anyone can call to distribute x items to y items. Caller (msg.sender)
    * pays the xFUND fees for the request.
    *
    * @param _ipfs string of the IPFS ID
    * @param _sourceCount uint256 of source count
    * @param _destCount uint256 of dest count
    * @param _dataType uint256 of distribution type
    * @param _seed uint256 seed for the randomness request. Gets mixed in with the blockhash of the block this Tx is in
    * @param _keyHash bytes32 key hash of the provider caller wants to fulfil the request
    * @param _fee uint256 required fee amount for the request
    */
    function startDistribute(string memory _ipfs, uint256 _sourceCount, uint256 _destCount, DataType _dataType, uint256 _seed, bytes32 _keyHash, uint256 _fee) external returns (bytes32 requestId) {
        require(bytes(monikers[msg.sender]).length != 0, "not registered address");
        require(_sourceCount > 0, "invalid source count");
        require(_destCount > 0, "invalid destination count");
        require(_dataType == DataType.ONE_TO_ONE_MAPPING || _dataType == DataType.X_FROM_Y, "invalid dataType");
        distributions[nextDistributionId].ipfs = _ipfs;
        distributions[nextDistributionId].sourceCount = _sourceCount;
        distributions[nextDistributionId].destCount = _destCount;
        distributions[nextDistributionId].dataType = _dataType;
        distributions[nextDistributionId].fee = _fee;
        distributions[nextDistributionId].keyHash = _keyHash;
        distributions[nextDistributionId].seed = _seed;
        // Note - caller must have increased xFUND allowance for this contract first.
        // Fee is transferred from msg.sender to this contract. The VORCoordinator.requestRandomness
        // function will then transfer from this contract to itself.
        // This contract's owner must have increased the VORCoordnator's allowance for this contract.
        xFUND.transferFrom(msg.sender, address(this), _fee);
        requestId = requestRandomness(_keyHash, _fee, _seed);
        emit StartingDistribute(nextDistributionId, requestId, msg.sender, _ipfs, _sourceCount, _destCount, _dataType, _seed, _keyHash, _fee);
        requestIdToAddress[requestId] = msg.sender;
        requestIdToDistributionId[requestId] = nextDistributionId;
        nextDistributionId = nextDistributionId.add(1);
        return requestId;
    }

    /**
     * @notice Callback function used by VOR Coordinator to return the random number
     * to this contract.
     * @dev The random number is used to simulate distribution starting index. Result is emitted as follows:
     *
     * @param _requestId bytes32
     * @param _randomness The random result returned by the oracle
     */
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
        uint256 distId = requestIdToDistributionId[_requestId];
        address player = requestIdToAddress[_requestId];
        Distribution memory dist = distributions[distId];
        uint256 sourceCount = dist.sourceCount;
        uint256 beginIndex = _randomness.mod(sourceCount);
        distributions[distId].result = beginIndex;
        emit DistributeResult(distId, _requestId, player, beginIndex, dist.sourceCount, dist.destCount, dist.dataType);

        // clean up
        delete requestIdToDistributionId[_requestId];
        delete requestIdToAddress[_requestId];
    }

    /**
     * @notice register moniker of each address
     * emits the NewMoniker event
     * @param _moniker string moniker to be registered max 32 characters
     */
    function registerMoniker(string memory _moniker) external {
        require(bytes(_moniker).length <= 32, "can't exceed 32 characters");
        monikers[msg.sender] = _moniker;
        emit NewMoniker(msg.sender, _moniker);
    }

    /**
     * @notice get moniker of sender
     */
    function getMoniker() external view returns (string memory)  {
        return monikers[msg.sender];
    }

    /**
     * @notice Example wrapper function for the VORConsumerBase increaseVorCoordinatorAllowance function.
     * @dev Wrapped around an Ownable modifier to ensure only the contract owner can call it.
     * @dev Allows contract owner to increase the xFUND allowance for the VORCoordinator contract
     * @dev enabling it to pay request fees on behalf of this contract.
     *
     * @param _amount uint256 amount to increase allowance by
     */
    function increaseVorAllowance(uint256 _amount) external onlyOwner {
        _increaseVorCoordinatorAllowance(_amount);
    }

    /**
     * @notice Example wrapper function for the VORConsumerBase withdrawXFUND function.
     * Wrapped around an Ownable modifier to ensure only the contract owner can call it.
     * Allows contract owner to withdraw any xFUND currently held by this contract
     */
    function withdrawToken(address to, uint256 value) external onlyOwner {
        require(xFUND.transfer(to, value), "Not enough xFUND");
    }

    /**
     * @notice Example wrapper function for the VORConsumerBase _setVORCoordinator function.
     * Wrapped around an Ownable modifier to ensure only the contract owner can call it.
     * Allows contract owner to change the VORCoordinator address in the event of a network
     * upgrade.
     */
    function setVORCoordinator(address _vorCoordinator) external onlyOwner {
        _setVORCoordinator(_vorCoordinator);
    }

    /**
     * @notice returns the current VORCoordinator contract address
     * @return vorCoordinator address
     */
    function getVORCoordinator() external view returns (address) {
        return vorCoordinator;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
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
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./vendor/VORSafeMath.sol";
import "./interfaces/IERC20_Ex.sol";
import "./interfaces/IVORCoordinator.sol";
import "./VORRequestIDBase.sol";

/**
 * @title VORConsumerBase
 * @notice Interface for contracts using VOR randomness
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * to Vera the verifier in such a way that Vera can be sure he's not
 * making his output up to suit himself. Reggie provides Vera a public key
 * to which he knows the secret key. Each time Vera provides a seed to
 * Reggie, he gives back a value which is computed completely
 * deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * correctly computed once Reggie tells it to her, but without that proof,
 * the output is indistinguishable to her from a uniform random sample
 * from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * to talk to Vera the verifier about the work Reggie is doing, to provide
 * simple access to a verifiable source of randomness.
 *
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VORConsumerBase, and can
 * initialize VORConsumerBase's attributes in their constructor as
 * shown:
 *
 * ```
 *   contract VORConsumer {
 *     constuctor(<other arguments>, address _vorCoordinator, address _xfund)
 *       VORConsumerBase(_vorCoordinator, _xfund) public {
 *         <initialization with other arguments goes here>
 *       }
 *   }
 * ```
 * @dev The oracle will have given you an ID for the VOR keypair they have
 * committed to (let's call it keyHash), and have told you the minimum xFUND
 * price for VOR service. Make sure your contract has sufficient xFUND, and
 * call requestRandomness(keyHash, fee, seed), where seed is the input you
 * want to generate randomness from.
 *
 * @dev Once the VORCoordinator has received and validated the oracle's response
 * to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * makeRequestId(keyHash, seed). If your contract could have concurrent
 * requests open, you can use the requestId to track which seed is
 * associated with which randomness. See VORRequestIDBase.sol for more
 * details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * differ. (Which is critical to making unpredictable randomness! See the
 * next section.)
 *
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * could spoof a VOR response with any random value, so it's critical that
 * it cannot be directly called by anything other than this base contract
 * (specifically, by the VORConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * from malicious interference, it's best if you can write it so that all
 * behaviors implied by a VOR response are executed *during* your
 * fulfillRandomness method. If your contract must store the response (or
 * anything derived from it) and use it later, you must ensure that any
 * user-significant behavior which depends on that stored value cannot be
 * manipulated by a subsequent VOR request.
 *
 * @dev Similarly, both miners and the VOR oracle itself have some influence
 * over the order in which VOR responses appear on the blockchain, so if
 * your contract could have multiple VOR requests in flight simultaneously,
 * you must ensure that the order in which the VOR responses arrive cannot
 * be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VOR is mixed with the block hash of the
 * block in which the request is made, user-provided seeds have no impact
 * on its economic security properties. They are only included for API
 * compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * call is mixed into the input to the VOR *last*, a sufficiently powerful
 * miner could, in principle, fork the blockchain to evict the block
 * containing the request, forcing the request to be included in a
 * different block with a different hash, and therefore a different input
 * to the VOR. However, such an attack would incur a substantial economic
 * cost. This cost scales with the number of blocks the VOR oracle waits
 * until it calls responds to a request.
 */
abstract contract VORConsumerBase is VORRequestIDBase {
    using VORSafeMath for uint256;

    /**
     * @notice fulfillRandomness handles the VOR response. Your contract must
     * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
     * @notice principles to keep in mind when implementing your fulfillRandomness
     * @notice method.
     *
     * @dev VORConsumerBase expects its subcontracts to have a method with this
     * signature, and will call it once it has verified the proof
     * associated with the randomness. (It is triggered via a call to
     * rawFulfillRandomness, below.)
     *
     * @param requestId The Id initially returned by requestRandomness
     * @param randomness the VOR output
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

    /**
     * @notice requestRandomness initiates a request for VOR output given _seed
     *
     * @dev The fulfillRandomness method receives the output, once it's provided
     * by the Oracle, and verified by the vorCoordinator.
     *
     * @dev The _keyHash must already be registered with the VORCoordinator, and
     * the _fee must exceed the fee specified during registration of the
     * _keyHash.
     *
     * @dev The _seed parameter is vestigial, and is kept only for API
     * compatibility with older versions. It can't *hurt* to mix in some of
     * your own randomness, here, but it's not necessary because the VOR
     * oracle will mix the hash of the block containing your request into the
     * VOR seed it ultimately uses.
     *
     * @param _keyHash ID of public key against which randomness is generated
     * @param _fee The amount of xFUND to send with the request
     * @param _seed seed mixed into the input of the VOR.
     *
     * @return requestId unique ID for this request
     *
     * The returned requestId can be used to distinguish responses to
     * concurrent requests. It is passed as the first argument to
     * fulfillRandomness.
     */
    function requestRandomness(bytes32 _keyHash, uint256 _fee, uint256 _seed) internal returns (bytes32 requestId) {
        IVORCoordinator(vorCoordinator).randomnessRequest(_keyHash, _seed, _fee);
        // This is the seed passed to VORCoordinator. The oracle will mix this with
        // the hash of the block containing this request to obtain the seed/input
        // which is finally passed to the VOR cryptographic machinery.
        uint256 vORSeed = makeVORInputSeed(_keyHash, _seed, address(this), nonces[_keyHash]);
        // nonces[_keyHash] must stay in sync with
        // VORCoordinator.nonces[_keyHash][this], which was incremented by the above
        // successful VORCoordinator.randomnessRequest.
        // This provides protection against the user repeating their input seed,
        // which would result in a predictable/duplicate output, if multiple such
        // requests appeared in the same block.
        nonces[_keyHash] = nonces[_keyHash].safeAdd(1);
        return makeRequestId(_keyHash, vORSeed);
    }

    /**
     * @notice _increaseVorCoordinatorAllowance is a helper function to increase token allowance for
     * the VORCoordinator
     * Allows this contract to increase the xFUND allowance for the VORCoordinator contract
     * enabling it to pay request fees on behalf of this contract.
     * NOTE: it is hightly recommended to wrap this around a function that uses,
     * for example, OpenZeppelin's onlyOwner modifier
     *
     * @param _amount uint256 amount to increase allowance by
     */
    function _increaseVorCoordinatorAllowance(uint256 _amount) internal returns (bool) {
        require(xFUND.increaseAllowance(vorCoordinator, _amount), "failed to increase allowance");
        return true;
    }

    /**
     * @notice _setVORCoordinator is a helper function to enable setting the VORCoordinator address
     * NOTE: it is hightly recommended to wrap this around a function that uses,
     * for example, OpenZeppelin's onlyOwner modifier
     *
     * @param _vorCoordinator address new VORCoordinator address
     */
    function _setVORCoordinator(address _vorCoordinator) internal {
        vorCoordinator = _vorCoordinator;
    }

    IERC20_Ex internal immutable xFUND;
    address internal vorCoordinator;

    // Nonces for each VOR key from which randomness has been requested.
    //
    // Must stay in sync with VORCoordinator[_keyHash][this]
    /* keyHash */
    /* nonce */
    mapping(bytes32 => uint256) private nonces;

    /**
     * @param _vorCoordinator address of VORCoordinator contract
     * @param _xfund address of xFUND token contract
     */
    constructor(address _vorCoordinator, address _xfund) public {
        vorCoordinator = _vorCoordinator;
        xFUND = IERC20_Ex(_xfund);
    }

    /**
     * @notice rawFulfillRandomness is called by VORCoordinator when it receives a valid VOR
     * proof. rawFulfillRandomness then calls fulfillRandomness, after validating
     * the origin of the call
     */
    function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
        require(msg.sender == vorCoordinator, "Only VORCoordinator can fulfill");
        fulfillRandomness(requestId, randomness);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @title VORRequestIDBase
 */
contract VORRequestIDBase {
    /**
     * @notice returns the seed which is actually input to the VOR coordinator
     *
     * @dev To prevent repetition of VOR output due to repetition of the
     * @dev user-supplied seed, that seed is combined in a hash with the
     * @dev user-specific nonce, and the address of the consuming contract. The
     * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
     * @dev the final seed, but the nonce does protect against repetition in
     * @dev requests which are included in a single block.
     *
     * @param _userSeed VOR seed input provided by user
     * @param _requester Address of the requesting contract
     * @param _nonce User-specific nonce at the time of the request
     */
    function makeVORInputSeed(
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
     * @param _vORInputSeed The seed to be passed directly to the VOR
     * @return The id for this request
     *
     * @dev Note that _vORInputSeed is not the seed passed by the consuming
     * @dev contract, but the one generated by makeVORInputSeed
     */
    function makeRequestId(bytes32 _keyHash, uint256 _vORInputSeed) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_keyHash, _vORInputSeed));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20_Ex {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IVORCoordinator {
    function getProviderAddress(bytes32 _keyHash) external view returns (address);
    function getProviderFee(bytes32 _keyHash) external view returns (uint96);
    function getProviderGranularFee(bytes32 _keyHash, address _consumer) external view returns (uint96);
    function randomnessRequest(bytes32 keyHash, uint256 consumerSeed, uint256 feePaid) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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
library VORSafeMath {
     /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
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
     *
     * - Subtraction cannot overflow.
     */
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function saveDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function safeMod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

