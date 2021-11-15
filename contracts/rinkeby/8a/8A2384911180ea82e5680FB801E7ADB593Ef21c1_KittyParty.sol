// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract KittyParty is VRFConsumerBase {
    bytes32 internal keyHash;
    uint256 internal fee;

    struct AddressList {
        address[] array; // An unordered list of unique values
        mapping(address => bool) won;
        address[] possible_winners;
        mapping(address => bool) exists; // Tracks if a given value exists in the list
        mapping(address => uint256) index; // Tracks the index of a value
        mapping(address => uint256) balance; //Tracks the  pendingWithdrawals
    }
    // The member list keeps strack of all the memebers, their respective balances in the kitty party contract.
    // Members include the kittens + kitty kreator
    // The kitty kreator would be the first member in the list
    // The number of rounds in the kitty party hence would be equivalent to number of members - 1

    struct StakeInfo {
        uint256 kreatorSecurity;
        uint256 kittenPool;
    }

    enum KittyPartyState {
        Verification,
        Collection,
        Staking,
        Payout,
        Completed,
        Trap
    } //Set of valid states for the kitty party contract
    //Verification: The Pre-Round verification is ongoing
    //Collection: Pre-Round verification completed, collection criteria can be checked for
    //Staking: The colection has been completed successfully, the asset can now be staked on respective protocols
    //Payout: The assets are withdrawn from the repective contracts, a winner is chosen at random
    //Completed: THe kitty-party is over
    //Trap: INVALID STATE!!
    KittyPartyState currentState = KittyPartyState.Verification;
    //initial state is verification state

    uint256 public roundDuration; //Duration of round in days
    uint256 public amountPerRound; //Amount of eth to be pooled by the kittens
    uint256 public currentRound = 0; //Counter to keep track of the rounds
    bool public staked = false;
    address public winnerAddress;
    uint256 public amountWon;

    AddressList internal memberList;
    StakeInfo internal stakeDetail;

    event Deposit(address indexed _from, uint256 _value);

    event Withdraw(address indexed _to, uint256 _value);

    event Verified(bool verificationState, uint256 indexed roundNumber);

    event Completed(bool completedState);

    event CollectedFromKitten(
        address indexed kittenAddress,
        uint256 amount,
        uint256 roundNumber
    );

    event Staked(StakeInfo stakeDetails, uint256 roundNumber);

    event WithdrawnFromStaking(uint256 amount, uint256 roundNumber);

    event LotteryWinner(
        address indexed winner,
        uint256 amountWon,
        uint256 roundNumber
    );

    constructor()
        public
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709 // LINK Token
        )
    {
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10**18; // 0.1 LINK (varies by network)
    }

    function initialize(address[] memory memberAddress, uint256 _amountPerRound)
        public
    {
        for (uint256 i = 0; i < memberAddress.length; i++) {
            add(memberAddress[i]);
        }
        amountPerRound = _amountPerRound;
    }

    function add(address value) public returns (bool success) {
        // Only add 'value' if it does not exist in the list
        if (memberList.exists[value]) return false;

        memberList.index[value] = memberList.array.length;
        memberList.exists[value] = true;
        memberList.array.push(value);
        memberList.possible_winners.push(value);

        return true;
    }

    function getList() public view returns (address[] memory) {
        return memberList.array;
    }

    function getLength() public view returns (uint256) {
        return memberList.array.length;
    }

    function getValueAt(uint256 i) public view returns (address) {
        return memberList.array[i];
    }

    function getIndex(address ad) public view returns (uint256) {
        return memberList.index[ad];
    }

    function isKittyPartyActive() public returns (bool) {
        if (
            currentState == KittyPartyState.Trap ||
            currentState == KittyPartyState.Completed
        ) return false;
        return true;
    }

    function completeKittyParty() public {
        currentState = KittyPartyState.Completed;
    }

    function verify() public {
        require(
            memberList.balance[getValueAt(0)] >= amountPerRound,
            "Insufficient Funds, kindly top up the smart contract"
        );
        require(isKittyPartyActive(), "Kitty Party is not Active");
        if (currentRound == getLength()) {
            completeKittyParty();
        }
        currentState = KittyPartyState.Collection;
        emit Verified(true, currentRound);
    }

    function deposit() public payable {
        require(
            memberList.exists[msg.sender],
            "User not registered with the kitty party contract, kindly check with your kitty kreator"
        );
        memberList.balance[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public {
        uint256 currentBalance = memberList.balance[msg.sender];
        require(amount <= currentBalance, "Insufficient Balance");
        memberList.balance[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    function withdrawAll() public {
        uint256 currentBalance = memberList.balance[msg.sender];
        memberList.balance[msg.sender] = 0;
        payable(msg.sender).transfer(currentBalance);
        emit Withdraw(msg.sender, currentBalance);
    }

    function collectFromKittens() public returns (uint256 amountCollected) {
        uint256 amountToBeCollectedFromKitten =
            amountPerRound / getLength() - 1;
        for (uint256 i = 1; i < getLength(); i++) {
            address kittenAddress = getValueAt(i);
            if (
                memberList.balance[kittenAddress] >=
                amountToBeCollectedFromKitten
            ) {
                amountCollected += amountToBeCollectedFromKitten;
                emit CollectedFromKitten(
                    kittenAddress,
                    amountCollected,
                    currentRound
                );
                memberList.balance[
                    kittenAddress
                ] -= amountToBeCollectedFromKitten;
            } else {
                amountCollected += memberList.balance[kittenAddress];
                emit CollectedFromKitten(
                    kittenAddress,
                    amountCollected,
                    currentRound
                );
                memberList.balance[kittenAddress] = 0;
            }
        }
        return amountCollected;
    }

    function collection() public {
        require(
            currentState == KittyPartyState.Collection,
            "Not in collection state"
        );
        stakeDetail.kittenPool = memberList.balance[getValueAt(0)];
        stakeDetail.kreatorSecurity = collectFromKittens();
        memberList.balance[getValueAt(0)] = 0;
        //stake(amountToBeStaked)
        emit Staked(stakeDetail, currentRound);
        currentState = KittyPartyState.Staking;
        staked = true;
    }

    function withdrawFromStaking() public {
        //call the lp contract, transfer the asset back to address(this)
        staked = false;
        //sendToPlatform
        emit WithdrawnFromStaking(amountWon, currentRound);
        if (stakeDetail.kittenPool > stakeDetail.kreatorSecurity) {
            //send .02*amountPerRound to platform
        } else {
            memberList.balance[getValueAt(0)] =
                (2 * amountPerRound) /
                100 +
                stakeDetail.kreatorSecurity;
        }
        amountWon -= ((2 * amountPerRound) / 100 + stakeDetail.kreatorSecurity);
        currentState = KittyPartyState.Payout;
    }

    function completeRound() internal {
        currentRound += 1;
    }

    function sendMoneyToWinner() public {
        memberList.balance[winnerAddress] += amountWon;
        memberList.won[winnerAddress] = true;
        delete memberList.possible_winners[getIndex(winnerAddress)];
        emit LotteryWinner(winnerAddress, amountWon, currentRound);
        completeRound();
    }

    function getRandomNumber(uint256 userProvidedSeed)
        public
        returns (bytes32 requestId)
    {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        return requestRandomness(keyHash, fee, userProvidedSeed);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        uint256 winnerPoolLength = getLength() - currentRound;
        uint256 randomResult = (randomness % winnerPoolLength) + 1;
        winnerAddress = memberList.possible_winners[randomResult];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./vendor/SafeMathChainlink.sol";

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
   * @param _seed seed mixed into the input of the VRF.
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee, uint256 _seed)
    internal returns (bytes32 requestId)
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, _seed));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, _seed, address(this), nonces[_keyHash]);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

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

