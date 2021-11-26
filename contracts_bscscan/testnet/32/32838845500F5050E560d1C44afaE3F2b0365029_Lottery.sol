/* SPDX-License-Identifier: UNLICENSED */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "../farming/FarmingFactory.sol";
import "../farming/LockFarming.sol";

contract Lottery is Ownable, VRFConsumerBase {
    using SafeMath for uint256;

    struct Prize {
        address winner;
        uint256 reward;
    }

    uint256 public currentRound;
    IERC20 public dfyContract;
    FarmingFactory public farmingFactory;
    uint256 public numWinners;
    uint256 public nextLotteryTime;
    uint256 private _totalLockedLPs;
    uint256 private _remainingPrizes;
    address private _rewardWallet;
    address[] private _players;
    Prize[] private _prizes;
    uint256 private _rewardAmount;
    bytes32 private _linkKeyHash;
    uint256 private _linkFee;
    mapping(address => bool) private _isPlayer;
    mapping(uint256 => Prize[]) private _prizeHistory;
    mapping(address => uint256) private _farmingAmountOf;
    mapping(address => uint8) private _weightOf;

    event Reward(uint256 round, address winner, uint256 rewardAmount);

    constructor(
        address dfyToken,
        address rewardWallet,
        address farmingFactory_,
        uint256 numWinners_
    )
        Ownable()
        VRFConsumerBase(
            0xa555fC018435bef5A13C6c6870a9d4C11DEC329C,
            0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06
        )
    {
        currentRound = 1;
        dfyContract = IERC20(dfyToken);
        _rewardWallet = rewardWallet;
        farmingFactory = FarmingFactory(farmingFactory_);
        numWinners = numWinners_;
        _remainingPrizes = numWinners_;
        nextLotteryTime = block.timestamp;
        _linkKeyHash = 0xcaf3c3727e033261d383b315559476f48034c13b18f8cafed4d871abe5049186;
        _linkFee = 10**17;
    }

    function getPrizeHistory(uint256 round)
        external
        view
        returns (Prize[] memory)
    {
        return _prizeHistory[round];
    }

    function getWeight(address lpToken) external view returns (uint8) {
        return _weightOf[lpToken];
    }

    function setWeight(address[] memory lpTokens, uint8[] memory weights)
        external
        onlyOwner
    {
        require(lpTokens.length == farmingFactory.getNumSupportedLpTokens());
        for (uint256 i = 0; i < lpTokens.length; i++) {
            require(farmingFactory.checkLpTokenStatus(lpTokens[i]));
            _weightOf[lpTokens[i]] = weights[i];
        }
    }

    function setNextLotteryTime(uint256 nextTime) external onlyOwner {
        nextLotteryTime = nextTime;
    }

    function setNumWinners(uint256 numWinners_) external onlyOwner {
        require(_remainingPrizes == numWinners);
        numWinners = numWinners_;
        _remainingPrizes = numWinners_;
    }

    function _createLotteryList() private {
        for (uint256 i = 0; i < _players.length; i++)
            delete _isPlayer[_players[i]];
        delete _players;
        delete _totalLockedLPs;
        uint256 numLpTokens = farmingFactory.getNumSupportedLpTokens();
        for (uint256 i = 0; i < numLpTokens; i++) {
            address lpToken = farmingFactory.lpTokens(i);
            uint8 numLockTypes = farmingFactory.getNumLockTypes(lpToken);
            for (uint8 j = 1; j <= numLockTypes; j++) {
                address lockFarmingAddr = farmingFactory.getLockFarmingContract(
                    lpToken,
                    j
                );
                LockFarming lockFarming = LockFarming(lockFarmingAddr);
                uint256 numParticipants = lockFarming.getNumParticipants();
                for (uint256 k = 0; k < numParticipants; k++) {
                    address participant = lockFarming.participants(k);
                    uint256 weightedFarmingAmount = lockFarming
                        .getValidLockAmount(participant)
                        .mul(_weightOf[lpToken]);
                    if (!_isPlayer[participant]) {
                        _players.push(participant);
                        _isPlayer[participant] = true;
                    }
                    _totalLockedLPs = _totalLockedLPs.add(
                        weightedFarmingAmount
                    );
                    _farmingAmountOf[participant] = _farmingAmountOf[
                        participant
                    ].add(weightedFarmingAmount);
                }
            }
        }
    }

    function spinReward(uint256 rewardAmount) external onlyOwner {
        require(block.timestamp > nextLotteryTime);
        if (_remainingPrizes == numWinners) _createLotteryList();
        require(_players.length > numWinners && numWinners > 0);
        require(dfyContract.balanceOf(_rewardWallet) >= rewardAmount);
        require(
            dfyContract.allowance(_rewardWallet, address(this)) >= rewardAmount
        );
        _rewardAmount = rewardAmount;
        _random();
    }

    function _random() private returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= _linkFee);
        return requestRandomness(_linkKeyHash, _linkFee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        address chosenPlayer = _players[0];
        uint256 randomNumber = randomness.mod(_totalLockedLPs);
        for (uint256 i = 0; i < _players.length; i++) {
            if (randomNumber < _farmingAmountOf[_players[i]]) {
                chosenPlayer = _players[i];
                delete _isPlayer[_players[i]];
                _totalLockedLPs = _totalLockedLPs.sub(
                    _farmingAmountOf[_players[i]]
                );
                _players[i] = _players[_players.length - 1];
                _players.pop();
                break;
            } else randomNumber -= _farmingAmountOf[_players[i]];
        }
        _prizes.push(Prize(chosenPlayer, _rewardAmount));
        dfyContract.transferFrom(_rewardWallet, chosenPlayer, _rewardAmount);
        if (_remainingPrizes > 0) _remainingPrizes--;
        if (_remainingPrizes == 0) {
            _prizeHistory[currentRound] = _prizes;
            currentRound++;
            _remainingPrizes = numWinners;
            delete _prizes;
        }
        emit Reward(currentRound, chosenPlayer, _rewardAmount);
    }

    function emergencyWithdraw() external onlyOwner {
        LINK.transfer(owner(), LINK.balanceOf(address(this)));
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

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

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
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
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
    nonces[_keyHash] = nonces[_keyHash] + 1;
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
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

/* SPDX-License-Identifier: UNLICENSED */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./SavingFarming.sol";
import "./LockFarming.sol";

contract FarmingFactory is Ownable {
    address[] public lpTokens;
    address public dfyToken;
    address private _rewardWallet;
    mapping(address => bool) private _isLpTokenSupported;
    mapping(address => address) private _savingFarmingOf;
    mapping(address => uint8) private _numLockTypesOf;
    mapping(address => mapping(uint8 => address)) private _lockFarmingOf;

    event NewSavingFarming(address lpToken, address savingFarmingContract);
    event NewLockFarming(
        address lpToken,
        uint256 duration,
        address lockFarmingContract
    );

    constructor(address dfyToken_, address rewardWallet) Ownable() {
        dfyToken = dfyToken_;
        _rewardWallet = rewardWallet;
    }

    function checkLpTokenStatus(address lpToken) external view returns (bool) {
        return _isLpTokenSupported[lpToken];
    }

    function getNumSupportedLpTokens() external view returns (uint256) {
        return lpTokens.length;
    }

    function getSavingFarmingContract(address lpToken)
        external
        view
        returns (address)
    {
        return _savingFarmingOf[lpToken];
    }

    function getNumLockTypes(address lpToken) external view returns (uint8) {
        return _numLockTypesOf[lpToken];
    }

    function getLockFarmingContract(address lpToken, uint8 lockType)
        external
        view
        returns (address)
    {
        require(lockType > 0 && lockType <= _numLockTypesOf[lpToken]);
        return _lockFarmingOf[lpToken][lockType];
    }

    function createSavingFarming(address lpToken, uint256 totalDFYPerMonth)
        external
        onlyOwner
    {
        require(_savingFarmingOf[lpToken] == address(0));
        SavingFarming newSavingContract = new SavingFarming(
            lpToken,
            dfyToken,
            _rewardWallet,
            totalDFYPerMonth,
            owner()
        );
        _savingFarmingOf[lpToken] = address(newSavingContract);
        if (!_isLpTokenSupported[lpToken]) {
            lpTokens.push(lpToken);
            _isLpTokenSupported[lpToken] = true;
        }
        emit NewSavingFarming(lpToken, address(newSavingContract));
    }

    function createLockFarming(
        address lpToken,
        uint256 duration,
        uint256 totalDFYPerMonth
    ) external onlyOwner {
        LockFarming newLockContract = new LockFarming(
            duration,
            lpToken,
            dfyToken,
            _rewardWallet,
            totalDFYPerMonth,
            owner()
        );
        if (!_isLpTokenSupported[lpToken]) {
            lpTokens.push(lpToken);
            _isLpTokenSupported[lpToken] = true;
        }
        _numLockTypesOf[lpToken]++;
        _lockFarmingOf[lpToken][_numLockTypesOf[lpToken]] = address(
            newLockContract
        );
        emit NewLockFarming(lpToken, duration, address(newLockContract));
    }
}

/* SPDX-License-Identifier: UNLICENSED */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./FarmingFactory.sol";

contract LockFarming is Ownable {
    using SafeMath for uint256;

    struct LockItem {
        uint256 amount;
        uint256 expiredAt;
        uint256 lastClaim;
    }

    address[] public participants;
    uint256 public duration;
    IERC20 public lpContract;
    IERC20 public dfyContract;
    FarmingFactory public farmingFactory;
    address private _rewardWallet;
    uint256 private _totalDFYPerMonth;
    mapping(address => LockItem[]) private _lockItemsOf;

    event ReceiveFromSavingFarming(
        address lpToken,
        address participant,
        uint256 amount
    );
    event Deposit(address lpToken, address participant, uint256 amount);
    event ClaimInterest(address lpToken, address participant, uint256 interest);
    event Withdraw(
        address lpToken,
        address participant,
        uint256 amount,
        uint256 interest
    );

    constructor(
        uint256 duration_,
        address lpToken,
        address dfyToken,
        address rewardWallet,
        uint256 totalDFYPerMonth,
        address owner_
    ) Ownable() {
        duration = duration_;
        lpContract = IERC20(lpToken);
        dfyContract = IERC20(dfyToken);
        _rewardWallet = rewardWallet;
        _totalDFYPerMonth = totalDFYPerMonth;
        farmingFactory = FarmingFactory(msg.sender);
        transferOwnership(owner_);
    }

    function getValidLockAmount(address participant)
        external
        view
        returns (uint256)
    {
        LockItem[] memory lockItems = _lockItemsOf[participant];
        uint256 lockAmount = 0;
        for (uint256 i = 0; i < lockItems.length; i++)
            if (block.timestamp < lockItems[i].expiredAt)
                lockAmount = lockAmount.add(lockItems[i].amount);
        return lockAmount;
    }

    function getNumParticipants() external view returns (uint256) {
        return participants.length;
    }

    function getLockItems(address participant)
        external
        view
        returns (LockItem[] memory)
    {
        return _lockItemsOf[participant];
    }

    function getCurrentInterest(address participant, uint256 index)
        public
        view
        returns (uint256)
    {
        require(index < _lockItemsOf[participant].length);
        LockItem memory item = _lockItemsOf[participant][index];
        uint256 farmingPeriod = block.timestamp - item.lastClaim;
        if (farmingPeriod > duration) farmingPeriod = duration;
        uint256 totalLpToken = lpContract.balanceOf(address(this));
        if (totalLpToken == 0) return 0;
        return
            item
                .amount
                .mul(_totalDFYPerMonth)
                .div(259200)
                .mul(farmingPeriod)
                .div(totalLpToken);
    }

    function setTotalDFYPerMonth(uint256 dfyAmount) external onlyOwner {
        _totalDFYPerMonth = dfyAmount;
    }

    function receiveLpFromSavingFarming(address participant, uint256 amount)
        external
    {
        address savingFarming = farmingFactory.getSavingFarmingContract(
            address(lpContract)
        );
        require(msg.sender == savingFarming);
        if (_lockItemsOf[participant].length == 0)
            participants.push(participant);
        _lockItemsOf[participant].push(
            LockItem(amount, block.timestamp.add(duration), block.timestamp)
        );
        emit ReceiveFromSavingFarming(address(lpContract), participant, amount);
    }

    function deposit(uint256 amount) external {
        require(lpContract.balanceOf(msg.sender) >= amount);
        require(lpContract.allowance(msg.sender, address(this)) >= amount);
        lpContract.transferFrom(msg.sender, address(this), amount);
        if (_lockItemsOf[msg.sender].length == 0) participants.push(msg.sender);
        _lockItemsOf[msg.sender].push(
            LockItem(amount, block.timestamp.add(duration), block.timestamp)
        );
        emit Deposit(address(lpContract), msg.sender, amount);
    }

    function claimInterest(uint256 index) external {
        uint256 numLockItems = _lockItemsOf[msg.sender].length;
        require(index < numLockItems);
        LockItem storage item = _lockItemsOf[msg.sender][index];
        require(block.timestamp < item.expiredAt);
        uint256 interest = getCurrentInterest(msg.sender, index);
        dfyContract.transferFrom(_rewardWallet, msg.sender, interest);
        item.lastClaim = block.timestamp;
        emit ClaimInterest(address(lpContract), msg.sender, interest);
    }

    function claimAllInterest() external {
        uint256 totalInterest = 0;
        for (uint256 i = 0; i < _lockItemsOf[msg.sender].length; i++) {
            LockItem storage item = _lockItemsOf[msg.sender][i];
            if (block.timestamp < item.expiredAt) {
                uint256 interest = getCurrentInterest(msg.sender, i);
                totalInterest = totalInterest.add(interest);
                item.lastClaim = block.timestamp;
            }
        }
        dfyContract.transferFrom(_rewardWallet, msg.sender, totalInterest);
        emit ClaimInterest(address(lpContract), msg.sender, totalInterest);
    }

    function withdraw(uint256 index) external {
        uint256 numLockItems = _lockItemsOf[msg.sender].length;
        require(index < numLockItems);
        LockItem storage item = _lockItemsOf[msg.sender][index];
        require(block.timestamp >= item.expiredAt);
        uint256 withdrawnAmount = item.amount;
        lpContract.transfer(msg.sender, withdrawnAmount);
        uint256 interest = getCurrentInterest(msg.sender, index);
        dfyContract.transferFrom(_rewardWallet, msg.sender, interest);
        item.amount = _lockItemsOf[msg.sender][numLockItems - 1].amount;
        item.expiredAt = _lockItemsOf[msg.sender][numLockItems - 1].expiredAt;
        item.lastClaim = _lockItemsOf[msg.sender][numLockItems - 1].lastClaim;
        _lockItemsOf[msg.sender].pop();
        if (numLockItems == 1) {
            for (uint256 i = 0; i < participants.length; i++)
                if (participants[i] == msg.sender) {
                    participants[i] = participants[participants.length - 1];
                    participants.pop();
                    break;
                }
        }
        emit Withdraw(
            address(lpContract),
            msg.sender,
            withdrawnAmount,
            interest
        );
    }

    function emergencyWithdraw() external onlyOwner {
        lpContract.transfer(owner(), lpContract.balanceOf(address(this)));
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

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
  )
    internal
    pure
    returns (
      uint256
    )
  {
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
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

/* SPDX-License-Identifier: UNLICENSED */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./LockFarming.sol";
import "./FarmingFactory.sol";

contract SavingFarming is Ownable {
    using SafeMath for uint256;

    struct FarmingInfo {
        uint256 startedAt;
        uint256 amount;
    }

    address[] public participants;
    IERC20 public lpContract;
    IERC20 public dfyContract;
    FarmingFactory public farmingFactory;
    address private _rewardWallet;
    uint256 private _totalDFYPerMonth;
    mapping(address => FarmingInfo) private _farmingInfoOf;

    event Deposit(address lpToken, address participant, uint256 amount);
    event Withdraw(address lpToken, address participant, uint256 amount);
    event TransferToLockFarming(
        address lpToken,
        address participant,
        uint256 amount
    );
    event Settle(address lpToken, address participant, uint256 interest);

    constructor(
        address lpToken,
        address dfyToken,
        address rewardWallet,
        uint256 totalDFYPerMonth,
        address owner_
    ) Ownable() {
        lpContract = IERC20(lpToken);
        dfyContract = IERC20(dfyToken);
        _rewardWallet = rewardWallet;
        _totalDFYPerMonth = totalDFYPerMonth;
        farmingFactory = FarmingFactory(msg.sender);
        transferOwnership(owner_);
    }

    function getNumParticipants() external view returns (uint256) {
        return participants.length;
    }

    function getFarmingAmount(address participant)
        external
        view
        returns (uint256)
    {
        return _farmingInfoOf[participant].amount;
    }

    function getCurrentInterest(address participant)
        public
        view
        returns (uint256)
    {
        FarmingInfo memory info = _farmingInfoOf[participant];
        uint256 farmingPeriod = block.timestamp - info.startedAt;
        uint256 totalLpToken = lpContract.balanceOf(address(this));
        if (totalLpToken == 0) return 0;
        return
            info
                .amount
                .mul(_totalDFYPerMonth)
                .div(259200)
                .mul(farmingPeriod)
                .div(totalLpToken);
    }

    function setTotalDFYPerMonth(uint256 dfyAmount) external onlyOwner {
        _totalDFYPerMonth = dfyAmount;
    }

    function deposit(uint256 amount) external {
        require(lpContract.balanceOf(msg.sender) >= amount);
        require(lpContract.allowance(msg.sender, address(this)) >= amount);
        _settle(msg.sender);
        lpContract.transferFrom(msg.sender, address(this), amount);
        if (_farmingInfoOf[msg.sender].amount == 0)
            participants.push(msg.sender);
        _farmingInfoOf[msg.sender].startedAt = block.timestamp;
        _farmingInfoOf[msg.sender].amount = _farmingInfoOf[msg.sender]
            .amount
            .add(amount);
        emit Deposit(address(lpContract), msg.sender, amount);
    }

    function claimInterest() external {
        _settle(msg.sender);
        _farmingInfoOf[msg.sender].startedAt = block.timestamp;
    }

    function withdraw(uint256 amount) external {
        require(_farmingInfoOf[msg.sender].amount >= amount);
        _settle(msg.sender);
        lpContract.transfer(msg.sender, amount);
        if (_farmingInfoOf[msg.sender].amount == amount)
            for (uint256 i = 0; i < participants.length; i++)
                if (participants[i] == msg.sender) {
                    participants[i] = participants[participants.length - 1];
                    participants.pop();
                    break;
                }
        _farmingInfoOf[msg.sender].startedAt = block.timestamp;
        _farmingInfoOf[msg.sender].amount = _farmingInfoOf[msg.sender]
            .amount
            .sub(amount);
        emit Withdraw(address(lpContract), msg.sender, amount);
    }

    function transferToLockFarming(uint256 amount, uint8 option) external {
        require(_farmingInfoOf[msg.sender].amount >= amount);
        uint8 numLockTypes = farmingFactory.getNumLockTypes(
            address(lpContract)
        );
        require(option > 0 && option <= numLockTypes);
        address lockFarming = farmingFactory.getLockFarmingContract(
            address(lpContract),
            option
        );
        require(lockFarming != address(0));
        _settle(msg.sender);
        lpContract.transfer(lockFarming, amount);
        LockFarming(lockFarming).receiveLpFromSavingFarming(msg.sender, amount);
        if (_farmingInfoOf[msg.sender].amount == amount)
            for (uint256 i = 0; i < participants.length; i++)
                if (participants[i] == msg.sender) {
                    participants[i] = participants[participants.length - 1];
                    participants.pop();
                    break;
                }
        _farmingInfoOf[msg.sender].startedAt = block.timestamp;
        _farmingInfoOf[msg.sender].amount = _farmingInfoOf[msg.sender]
            .amount
            .sub(amount);
        emit TransferToLockFarming(address(lpContract), msg.sender, amount);
    }

    function _settle(address participant) private {
        uint256 interest = getCurrentInterest(participant);
        require(dfyContract.balanceOf(_rewardWallet) >= interest);
        require(
            dfyContract.allowance(_rewardWallet, address(this)) >= interest
        );
        dfyContract.transferFrom(_rewardWallet, participant, interest);
        emit Settle(address(lpContract), participant, interest);
    }

    function emergencyWithdraw() external onlyOwner {
        lpContract.transfer(owner(), lpContract.balanceOf(address(this)));
    }
}