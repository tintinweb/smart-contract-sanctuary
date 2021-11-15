// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";

contract Daxiao is VRFConsumerBase {
    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 public randomResult;
    uint256 public dice1;
    uint256 public dice2;
    uint256 public dice3;

    address public admin;
    uint256 public gameId;
    uint256 public lastGameId;
    uint256 minVault;
    uint256[] betTypeValueRange;
    uint256[] betPayouts;
    mapping(uint256 => Game) public games;

    struct Game {
        uint256 id;
        uint256 betType;
        uint256 betValue;
        //uint256 seed;
        bytes32 requestId;
        uint256 amount;
        address player;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the Admin can call this function");
        _;
    }

    // Events
    event Withdraw(address admin, uint256 amount);
    event Received(address indexed sender, uint256 amount);
    event Result(
        uint256 id,
        uint256 betType,
        uint256 betValue,
        bytes32 requestId,
        uint256 amount,
        address player,
        uint256 winAmount,
        uint256 randomResult,
        uint256 time
    );

    constructor()
        public
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709 // LINK Token
        )
    {
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10**18; // 0.1 LINK (Varies by network)

        admin = msg.sender;
        betTypeValueRange = [1, 5, 5, 0, 14, 5, 13];
        betPayouts = [2, 181, 12, 31, 7, 0, 0];
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function startGame(uint256 betType, uint256 betValue) public payable {
        require(
            betType >= 0 && betType <= 6,
            "Bet must be between 0 and 6 inclusive"
        );
        require(
            betValue >= 0 && betValue <= betTypeValueRange[betType],
            "Invalid bet value"
        );

        // Checking if sufficient vault funds
        uint256 betPayout = betPayouts[betType];
        if (betType == 5) {
            betPayout = 4;
        } else if (betType == 6) {
            betPayout = 61;
        }
        uint256 payout = betPayout * msg.value;

        uint256 provisionalBalance = minVault + payout;
        require(
            provisionalBalance < address(this).balance,
            "Insufficent vault funds"
        );
        minVault += payout;

        // Oracle: Get a Random Number
        bytes32 requestId = getRandomNumber();

        // Save the game
        games[gameId] = Game(
            gameId,
            betType,
            betValue,
            //seed,
            requestId,
            msg.value,
            msg.sender
        );

        // Increase gameId for the next game
        gameId = gameId + 1;
    }

    function endGame(
        bytes32 requestId,
        uint256 random1,
        uint256 random2,
        uint256 random3
    ) internal {
        uint256 sumDice = random1 + random2 + random3;

        // Check each bet from last betting round
        for (uint256 i = lastGameId; i < gameId; i++) {
            // Reset winAmount for current user
            uint256 winAmount = 0;
            uint256 betPayout = betPayouts[games[i].betType];

            // Check if the requestId is the same
            if (games[i].requestId == requestId) {
                bool won = false;

                if (games[i].betType == 0) {
                    // small or big
                    if (games[i].betValue == 0) {
                        if (sumDice >= 4 && sumDice <= 10) {
                            won = true;
                        }
                    } else if (games[i].betValue == 1) {
                        if (sumDice >= 10 && sumDice <= 17) {
                            won = true;
                        }
                    }
                } else if (games[i].betType == 1) {
                    // specific triples
                    if ((random1 == random2) && (random2 == random3)) {
                        if ((games[i].betValue + 1) == random1) {
                            won = true;
                        }
                    }
                } else if (games[i].betType == 2) {
                    // specific doubles
                    if (random1 == random2) {
                        if ((games[i].betValue + 1) == random1) {
                            won = true;
                        }
                    } else if (random2 == random3) {
                        if ((games[i].betValue + 1) == random2) {
                            won = true;
                        }
                    } else if (random1 == random3) {
                        if ((games[i].betValue + 1) == random1) {
                            won = true;
                        }
                    }
                } else if (games[i].betType == 3) {
                    // any triples
                    if ((random1 == random2) && (random2 == random3)) {
                        won = true;
                    }
                } else if (games[i].betType == 4) {
                    if (games[i].betValue <= 4) {
                        if (
                            random1 == 1 && random2 == (games[i].betValue + 2)
                        ) {
                            won = true;
                        } else if (
                            random2 == 1 && random3 == (games[i].betValue + 2)
                        ) {
                            won = true;
                        }
                    } else if (games[i].betValue <= 8) {
                        if (
                            random1 == 2 && random2 == (games[i].betValue - 2)
                        ) {
                            won = true;
                        } else if (
                            random2 == 2 && random3 == (games[i].betValue - 2)
                        ) {
                            won = true;
                        }
                    } else if (games[i].betValue <= 11) {
                        if (
                            random1 == 3 && random2 == (games[i].betValue - 5)
                        ) {
                            won = true;
                        } else if (
                            random2 == 3 && random3 == (games[i].betValue - 5)
                        ) {
                            won = true;
                        }
                    } else if (games[i].betValue <= 13) {
                        if (
                            random1 == 4 && random2 == (games[i].betValue - 7)
                        ) {
                            won = true;
                        } else if (
                            random2 == 4 && random3 == (games[i].betValue - 7)
                        ) {
                            won = true;
                        }
                    } else if (games[i].betValue == 14) {
                        if (random1 == 5 && random2 == 6) {
                            won = true;
                        } else if (random2 == 5 && random3 == 6) {
                            won = true;
                        }
                    }
                } else if (games[i].betType == 5) {
                    betPayout = 1;
                    if (random1 == games[i].betValue + 1) {
                        won = true;
                        betPayout++;
                    }
                    if (random2 == games[i].betValue + 1) {
                        won = true;
                        betPayout++;
                    }
                    if (random3 == games[i].betValue + 1) {
                        won = true;
                        betPayout++;
                    }
                } else if (games[i].betType == 6) {
                    if (games[i].betValue + 4 == sumDice) {
                        won = true;
                        if (sumDice == 4 || sumDice == 17) {
                            betPayout = 61;
                        } else if (sumDice == 5 || sumDice == 16) {
                            betPayout = 31;
                        } else if (sumDice == 6 || sumDice == 15) {
                            betPayout = 19;
                        } else if (sumDice == 7 || sumDice == 14) {
                            betPayout = 13;
                        } else if (sumDice == 8 || sumDice == 13) {
                            betPayout = 9;
                        } else if (sumDice == 9 || sumDice == 12) {
                            betPayout = 8;
                        } else if (sumDice == 10 || sumDice == 11) {
                            betPayout = 7;
                        }
                    }
                }

                if (won) {
                    winAmount = betPayout * games[i].amount;
                    payable(games[i].player).transfer(winAmount);
                }

                minVault = 0;

                emit Result(
                    games[i].id,
                    games[i].betType,
                    games[i].betValue,
                    games[i].requestId,
                    games[i].amount,
                    games[i].player,
                    winAmount,
                    randomResult,
                    block.timestamp
                );
            }
        }
        //save current gameId to lastGameId for the next betting round
        lastGameId = gameId;
    }

    function getRandomNumber() public returns (bytes32 requestId) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        uint256 random1 = (randomness % 6) + 1;
        uint256 random2 = ((randomness / 10) % 6) + 1;
        uint256 random3 = ((randomness / 100) % 6) + 1;

        // sort from small to large for easier computation for outcome
        if (random2 < random1) {
            if (random3 < random2) {
                // random3 is smallest;
                uint256 temp = random1;
                random1 = random3;
                random3 = temp;
            } else {
                uint256 temp = random1;
                random1 = random2;
                random2 = temp;
            }
        }

        if (random3 < random2) {
            uint256 temp = random3;
            random3 = random2;
            random2 = temp;
        }
        dice1 = random1;
        dice2 = random2;
        dice3 = random3;

        randomResult = randomness;

        // End the game
        endGame(requestId, random1, random2, random3);
    }

    function withdrawLink(uint256 amount) external onlyAdmin {
        require(LINK.transfer(msg.sender, amount), "Error, unable to transfer");
    }

    function withdrawEther(uint256 amount) external payable onlyAdmin {
        require(
            address(this).balance >= amount,
            "Error, contract has insufficent balance"
        );
        payable(admin).transfer(amount);

        emit Withdraw(admin, amount);
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

