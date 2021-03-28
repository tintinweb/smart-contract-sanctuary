/**
 *Submitted for verification at Etherscan.io on 2021-03-28
*/

// Sources flattened with hardhat v2.1.1 https://hardhat.org

// File contracts/SafeMathChainlink.sol

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


// File contracts/LinkTokenInterface.sol

pragma solidity ^0.7.0;

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


// File contracts/VRFRequestIDBase.sol

pragma solidity ^0.7.0;

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


// File contracts/VRFConsumerBase.sol

pragma solidity ^0.7.0;

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


// File contracts/ID3.sol

pragma experimental ABIEncoderV2;

interface ERC20Interface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
}

contract ID3 is VRFConsumerBase {
    uint public THRESHOLD = 11;
    uint constant MEMBERS = 16;


    struct CommitteeMember {
        address node;
        uint[MEMBERS] votes;
    }

    struct Burn {
        address burner;
        uint256 amount;
    }


    uint256 public latestSeed;
    uint256 public currentEpoch;
    ERC20Interface zipt;

    bytes32 internal keyHash;
    uint256 internal chainLinkFee;

    mapping (address => bytes) public publicKeys;
    mapping (address => bytes) public endpointDescriptors;

    // epoch number to burn
    mapping (uint256 => Burn[]) public epochBurners;
    mapping (uint256 => uint256) public epochTotalBurnt;
    
    mapping (uint256 => CommitteeMember[]) public committees;


    event NewSeed(uint256 seed, uint256 epoch);

    constructor() VRFConsumerBase(
            0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
            0xa36085F69e2889c224210F603D836748e7dC0088  // LINK Token
        ) {
        for (uint256 i = 0; i < MEMBERS; i++) {
            committees[0].push();
        }
    }

    function setPubkeyAndEndPoint(bytes calldata pubkey, bytes calldata endpoint) external {
        require(publicKeys[msg.sender].length == 0);
        require(pubkey.length == 65);
        publicKeys[msg.sender] = pubkey;
        endpointDescriptors[msg.sender] = endpoint;
    }

    function enlistToEpoch(uint256 amount) external {
        require(amount > 0);
        // can't enlist twice in an epoch with same address
        for (uint256 i = 0; i < epochBurners[currentEpoch+1].length; i++) {
            require (epochBurners[currentEpoch+1][i].burner != msg.sender, 'B');
        }

        require(zipt.transferFrom(msg.sender, address(this), amount), 'A');
        Burn memory burn;
        burn.burner = msg.sender;
        burn.amount = amount;

        epochBurners[currentEpoch+1].push(burn);
        epochTotalBurnt[currentEpoch+1] = epochTotalBurnt[currentEpoch+1] + amount; 
    }

    function vote(uint[] calldata nodeSlots, bool[] calldata nodeVotes, uint myCommitteeSlot) public {
        if (committees[currentEpoch].length == 0) {
            CommitteeMember[] memory c = getProposedCommittee();
            for (uint i = 0; i < c.length; i++) {
                committees[currentEpoch].push(c[i]);
            }
        }

        require(committees[currentEpoch][myCommitteeSlot].node == msg.sender);
        require(nodeSlots.length == nodeVotes.length);
        for (uint i = 0; i < nodeSlots.length; i++) {
            require(committees[currentEpoch][nodeSlots[i]].votes[myCommitteeSlot] == 0);
            if (nodeVotes[i]) {
                committees[currentEpoch][nodeSlots[i]].votes[myCommitteeSlot] = 1;
            } else {
                committees[currentEpoch][nodeSlots[i]].votes[myCommitteeSlot] = 2;
            }
        }

        uint yesVotes = 0;

        for (uint i = 0; i < MEMBERS; i++) {
            uint against;

            for (uint j = 0; j < MEMBERS; j++) {
                if (committees[currentEpoch][i].votes[j] == 2) {
                    against = against + 1;
                } else if (committees[currentEpoch][i].votes[j] == 1) {
                    yesVotes = yesVotes + 1;
                }
            }

            if (against > THRESHOLD) { 
                // slash members' deposit if it's not already
            }
        }
        if (yesVotes == (MEMBERS*(MEMBERS-1))) {

        }
    }

    function reusePreviousBurnedToEpoch(uint256 epoch, uint256 amount) public {

    }

    function withdrawFromOldEpoch(uint256 epoch, uint256 amount) public {

    }

    function startEpoch() public {
        // doable if the epoch cannot be used to generate a member list, too few burners; generates a new epoch
        // also used to start the first epoch
    }

    function getProposedCommittee() public view returns (CommitteeMember[] memory commitee) {
        CommitteeMember[] memory previousCommittee = committees[currentEpoch-1];

        require(epochBurners[currentEpoch].length >= MEMBERS);

        uint thrownOut = getPersonToThrowOutFromCommitee();

        previousCommittee[thrownOut].node = address(0x0);
        for (uint256 i = 0; i < MEMBERS; i++) {
            previousCommittee[thrownOut].votes[i] = 0;
        }

        for (uint256 i = 0; i < previousCommittee.length; i++) {
            if (previousCommittee[i].node == address(0x0)) {
                uint multiplier = 1;
                while (previousCommittee[i].node == address(0x0)) {
                    address picked = getSelected(latestSeed * multiplier);
                    uint j; 
                    for (j = 0; j < previousCommittee.length; j++) {
                        if (picked == previousCommittee[j].node)
                            break;
                    }
                    if (j == previousCommittee.length) {
                        previousCommittee[i].node = picked; 
                        for (uint256 k = 0; k < MEMBERS;k++) {
                            previousCommittee[i].votes[k] = 0;
                        }
                        break;
                    } else {
                        multiplier = multiplier + 1;
                    }
                }
            }
        }
        return previousCommittee;
    }

    function getPersonToThrowOutFromCommitee() internal view returns (uint slot) {
        uint256 selector = latestSeed % MEMBERS;
        return selector;
    }

    function getSelected(uint256 seed) internal view returns (address burner) {
        uint256 selector = seed % epochTotalBurnt[currentEpoch];
        uint256 last_end = 0;
        uint i;

        for (i = 0; i < epochBurners[currentEpoch].length; i++) { 
            if (last_end + epochBurners[currentEpoch][i].amount > selector) {
                return epochBurners[currentEpoch][i].burner;
            }
            last_end = last_end + epochBurners[currentEpoch][i].amount;
        }
        // this shouldn't happen
        require(false);
    }

    function internalRequestRandomness() internal {
        require(LINK.balanceOf(address(this)) >= chainLinkFee, "Not enough LINK - fill contract with faucet");
        requestRandomness(keyHash, chainLinkFee, 0x0);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        requestId;
        latestSeed = randomness;
        currentEpoch = currentEpoch + 1;
        emit NewSeed(latestSeed, currentEpoch);
    }
}