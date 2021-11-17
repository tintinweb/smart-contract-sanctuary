// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./RandomConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT WHICH USES HARDCODED VALUES FOR CLARITY.
 * PLEASE DO NOT USE THIS CODE IN PRODUCTION.
 */
contract RandomConsumer is RandomConsumerBase, Ownable {

    uint256 public lastRandomResult;
    bytes32 public lastRequestId;

    /**
     * Constructor inherits RandomConsumerBase
     */
    constructor(address _randomCoordinator) Ownable()
    {
        _setCoordinator(_randomCoordinator);
    }

    function setCoordinator(address _randomCoordinator) public onlyOwner {
        _setCoordinator(_randomCoordinator);
      }

    /**
     * Requests randomness
     */
    function getRandomNumber() public returns (bytes32 requestId) {
      return lastRequestId = requestRandomness();
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        lastRandomResult = randomness;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../IRandomCoordinator.sol";

/** ****************************************************************************
 * @notice Interface for contracts using randomness
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from RandomConsumerBase, and can
 * @dev initialize RandomConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract RandomConsumer {
 * @dev     constuctor(<other arguments>, address _RandomCoordinator, address _link)
 * @dev       RandomConsumerBase(_RandomCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the Random keypair they have
 * @dev price for Random service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the RandomCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See RandomRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 */
abstract contract RandomConsumerBase {
  /**
   * @notice fulfillRandomness handles the Random response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev RandomConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the Random output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;


  address private randomCoordinator;
  IRandomCoordinator internal COORDINATOR;

  /**
   * @param _randomCoordinator address of RandomCoordinator contract
   */
  function _setCoordinator(address _randomCoordinator) internal {
    randomCoordinator = _randomCoordinator;
    COORDINATOR = IRandomCoordinator(randomCoordinator);
  }

  /**
   * @notice requestRandomness initiates a request for Random output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the RandomCoordinator.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the Random
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev Random seed it ultimately uses.
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness() internal returns (bytes32 requestId) {
    return COORDINATOR.randomnessRequest(address(this), msg.sender);
  }

  // rawFulfillRandomness is called by RandomCoordinator when it receives a valid Random
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == randomCoordinator, "Only RandomCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IRandomCoordinator {
  function randomnessRequest(address _sender, address _requester) external returns (bytes32 requestId);
}

// SPDX-License-Identifier: MIT

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