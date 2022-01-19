/***************************************************************************
 * NOTICE: THIS CONTRACT IS NOT PRODUCTION READY AND LIKELY CONTAINS BUGS
 *          CONTRACT HAS NOT BEEN AUDITED
 * !!! DO NOT USE IN PRODUCTION !!!
 ***************************************************************************/

/******************************************
 * DOUBLE EXPOSURE / ZWEIKARTENSPIEL
 * BJ checked on initial deal (Dealer Peek)
 * BJ 1:1 / BJ Tie 1:1 / Ties Push /
 * No Split / Double on any 2 /
 * Surrender on starting hand refunds 20%
 * Infinite decks - new deck for each card
 ******************************************/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract Blackjack is VRFConsumerBase {

    uint128 private currentGameId = 0;
    uint128 private lastGameId;
    uint256 private totalPendingPayouts;
    address payable private manager;

    bytes32 internal keyHash = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
    uint256 internal fee = 0.1 * 10 ** 15;
    address private LinkToken = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB;
    address private VRFCoordinator = 0x8C7382F9D8f56b33781fE506E897a4F1e2d17255;

    mapping(uint128 => Game) public games;
    mapping(address => uint256) public pendingPayouts;

    string[52] private CARD_CODES = [
        "AH", "AD", "AC", "AS",
        "2H", "2D", "2C", "2S",
        "3H", "3D", "3C", "3S",
        "4H", "4D", "4C", "4S",
        "5H", "5D", "5C", "5S",
        "6H", "6D", "6C", "6S",
        "7H", "7D", "7C", "7S",
        "8H", "8D", "8C", "8S",
        "9H", "9D", "9C", "9S",
        "0H", "0D", "0C", "0S",
        "JH", "JD", "JC", "JS",
        "QH", "QD", "QC", "QS",
        "KH", "KD", "KC", "KS"
    ];

    struct Game {
        uint128 id;
        address payable player;
        uint256 bet;
        uint256 payout;
        bytes32 oracle_req_id;
        mapping(uint8 => Card) player_cards;
        mapping(uint8 => Card) dealer_cards;
        uint8 playerCardCount;
        uint8 dealerCardCount;
        bool doubleDown;
        Player whos_turn;
        Winner winner;
    }

    struct Card {
        string code;
        uint8 value;
    }

    enum Player { Dealer, Player }

    enum Winner { Dealer, Player, Tie, Unknown }

    event NewGame (uint128 indexed game_id, address indexed player);
    event NewPlayerCardDealt (uint128 indexed game_id, Card player_card);
    event NewDealerCardDealt (uint128 indexed game_id, Card dealer_card);
    event GameWon (uint128 indexed game_id, Winner winner, uint256 payout);
    event Withdraw(address indexed player, uint256 amount);
    event VRFResponse(uint128 indexed game_id, bytes32 request_id, uint256 random_response, Player whos_turn);

    constructor() VRFConsumerBase(VRFCoordinator, LinkToken) public {
        manager = msg.sender;
    }

    receive() external payable {
        require(msg.sender == manager, "Must be manager");
    }

    function withdrawMatic(uint256 amount) external {
        require(msg.sender == manager, "Must be manager");
        require(amount <= address(this).balance - totalPendingPayouts, "Not enough available funds to withdraw");
        manager.transfer(amount);
    }

    function withdrawPayout() external {
        require(pendingPayouts[msg.sender] > 0, "There is no payout for this address");
        uint256 payAmount = pendingPayouts[msg.sender];
        pendingPayouts[msg.sender] = 0;
        totalPendingPayouts = totalPendingPayouts - payAmount;
        msg.sender.transfer(payAmount);
        emit Withdraw(msg.sender, payAmount);
    }

    function newGame() payable public {
        require(LINK.balanceOf(address(this)) >= (fee * 4), "Not enough LINK - fill contract with faucet");
        require(msg.value % 2 == 0, "Bet must be evenly divisible by 2");
        require(address(this).balance > (msg.value * 3) + totalPendingPayouts, "Dealer doesn't have enough MATIC");
        Game memory _newGame;
        _newGame.id = currentGameId;
        lastGameId = currentGameId;
        currentGameId = currentGameId + 1;
        _newGame.player = msg.sender;
        _newGame.bet = msg.value;
        _newGame.doubleDown = false;
        _newGame.whos_turn = Player.Player;
        _newGame.winner = Winner.Unknown;
        _newGame.oracle_req_id = drawCardRequest();
        emit NewGame(_newGame.id, _newGame.player);
        games[lastGameId] = _newGame;
    }

    function drawCardRequest() internal returns (bytes32) {
        return requestRandomness(keyHash, fee);
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        if (games[lastGameId].oracle_req_id == requestId) {
            emit VRFResponse(lastGameId, requestId, randomness, games[lastGameId].whos_turn);
            addCardToHand(lastGameId, CARD_CODES[randomness.mod(52)]);
        } else {
            for (uint128 i = 0; i < currentGameId; i++) {
                if (games[i].oracle_req_id == requestId) {
                    emit VRFResponse(i, requestId, randomness, games[i].whos_turn);
                    addCardToHand(i, CARD_CODES[randomness.mod(52)]);
                }
            }
        }
    }

    function addCardToHand(uint128 gameIndex, string memory cardCode) internal {
        string memory valueString = substring(cardCode, 0, 1);
        if (games[gameIndex].whos_turn == Player.Player) {
            games[gameIndex].player_cards[games[gameIndex].playerCardCount] = Card(cardCode, valueStringToValueUint(valueString));
            emit NewPlayerCardDealt(games[gameIndex].id, games[gameIndex].player_cards[games[gameIndex].playerCardCount]);
            games[gameIndex].playerCardCount = games[gameIndex].playerCardCount + 1;
            if (games[gameIndex].playerCardCount <= 2) {
                games[gameIndex].whos_turn = Player.Dealer;
                games[gameIndex].oracle_req_id = drawCardRequest();
            } else if (getTotalHandValue(gameIndex, Player.Player) > 21) {
                evaluateHands(gameIndex);
            } else if (games[gameIndex].playerCardCount >= 6 || getTotalHandValue(gameIndex, Player.Player) == 21 || games[gameIndex].doubleDown == true) {
                if (getTotalHandValue(gameIndex, Player.Dealer) < 17) {
                    games[gameIndex].whos_turn = Player.Dealer;
                    games[gameIndex].oracle_req_id = drawCardRequest();
                } else {
                    evaluateHands(gameIndex);
                }
            }
        } else if (games[gameIndex].whos_turn == Player.Dealer) {
            games[gameIndex].dealer_cards[games[gameIndex].dealerCardCount] = Card(cardCode, valueStringToValueUint(valueString));
            emit NewDealerCardDealt(games[gameIndex].id, games[gameIndex].dealer_cards[games[gameIndex].dealerCardCount]);
            games[gameIndex].dealerCardCount = games[gameIndex].dealerCardCount + 1;
            if (games[gameIndex].dealerCardCount < 2) {
                games[gameIndex].whos_turn = Player.Player;
                games[gameIndex].oracle_req_id = drawCardRequest();
            } else if (games[gameIndex].dealerCardCount == 2) {
                games[gameIndex].whos_turn = Player.Player;
                checkBlackjack(gameIndex);
            } else if (games[gameIndex].dealerCardCount < 6 && getTotalHandValue(gameIndex, Player.Dealer) < 17) {
                games[gameIndex].oracle_req_id = drawCardRequest();
            } else {
                evaluateHands(gameIndex);
            }
        }
    }

    function playerHit(uint128 gameIndex) external {
        require(games[gameIndex].winner == Winner.Unknown, "The winner has already been determined");
        require(games[gameIndex].whos_turn == Player.Player, "It's not your turn");
        require(games[gameIndex].playerCardCount >= 2 && games[gameIndex].dealerCardCount >= 2, "Starting cards have not been dealt yet");
        require(games[gameIndex].playerCardCount < 6, "You have reached the card limit");
        require(getTotalHandValue(gameIndex, Player.Player) != 21, "You already have blackjack");
        require(getTotalHandValue(gameIndex, Player.Player) < 21, "You have bust");
        games[gameIndex].oracle_req_id = drawCardRequest();
    }

    function playerStand(uint128 gameIndex) external {
        require(games[gameIndex].winner == Winner.Unknown, "The winner has already been determined");
        require(games[gameIndex].whos_turn == Player.Player, "It's not your turn");
        require(games[gameIndex].playerCardCount >= 2 && games[gameIndex].dealerCardCount >= 2, "Starting cards have not been dealt yet");
        require(games[gameIndex].playerCardCount < 6, "You have reached the card limit");
        require(getTotalHandValue(gameIndex, Player.Player) != 21, "You already have blackjack");
        require(getTotalHandValue(gameIndex, Player.Player) < 21, "You have bust");
        if (getTotalHandValue(gameIndex, Player.Dealer) < 17) {
            games[gameIndex].whos_turn = Player.Dealer;
            games[gameIndex].oracle_req_id = drawCardRequest();
        } else {
            evaluateHands(gameIndex);
        }
    }

    function playerDouble(uint128 gameIndex) external payable {
        require(games[gameIndex].winner == Winner.Unknown, "The winner has already been determined");
        require(games[gameIndex].whos_turn == Player.Player, "It's not your turn");
        require(games[gameIndex].playerCardCount == 2 && games[gameIndex].dealerCardCount == 2, "You can only play double on your first turn");
        require(games[gameIndex].playerCardCount < 6, "You have reached the card limit");
        require(getTotalHandValue(gameIndex, Player.Player) != 21, "You already have blackjack");
        require(getTotalHandValue(gameIndex, Player.Player) < 21, "You have bust");
        require(msg.value == games[gameIndex].bet, "You must send the same amount of MATIC as the initial bet");
        require(address(this).balance > (games[gameIndex].bet * 5) + totalPendingPayouts, "Dealer doesn't have enough MATIC");
        games[gameIndex].doubleDown = true;
        games[gameIndex].bet = games[gameIndex].bet + msg.value;
        games[gameIndex].oracle_req_id = drawCardRequest();
    }

    function playerSurrender(uint128 gameIndex) external {
        require(games[gameIndex].winner == Winner.Unknown, "The winner has already been determined");
        require(games[gameIndex].whos_turn == Player.Player, "It's not your turn");
        require(games[gameIndex].playerCardCount == 2 && games[gameIndex].dealerCardCount == 2, "No surrender after starting hand has been played");
        // require(games[gameIndex].playerCardCount < 6, "You have reached the card limit");
        require(getTotalHandValue(gameIndex, Player.Player) != 21, "You already have blackjack");
        require(getTotalHandValue(gameIndex, Player.Dealer) != 21, "Dealer already has blackjack");
        // require(getTotalHandValue(gameIndex, Player.Player) < 21, "You have bust");
        setWinner(gameIndex, Winner.Dealer, (games[gameIndex].bet / 4));
    }

    function getTotalHandValue(uint128 gameIndex, Player player) internal returns (uint8) {
        uint8 handTotal = 0;
        uint8 newHandTotal = 0;
        if (player == Player.Player) {
            for(uint8 i = 0; i < games[gameIndex].playerCardCount; i++) {
                handTotal = handTotal + games[gameIndex].player_cards[i].value;
            }
            if (handTotal > 21) {
                for(uint8 i = 0; i < games[gameIndex].playerCardCount; i++) {
                    if (equals(substring(games[gameIndex].player_cards[i].code, 0, 1), "A")) {
                        games[gameIndex].player_cards[i].value = uint8(1);
                        newHandTotal = newHandTotal + 1;
                    } else {
                        newHandTotal = newHandTotal + games[gameIndex].player_cards[i].value;
                    }
                }
                handTotal = newHandTotal;
            }
        } else if (player == Player.Dealer) {
            for(uint8 i = 0; i < games[gameIndex].dealerCardCount; i++) {
                handTotal = handTotal + games[gameIndex].dealer_cards[i].value;
            }
            if (handTotal > 21) {
                for(uint8 i = 0; i < games[gameIndex].dealerCardCount; i++) {
                    if (equals(substring(games[gameIndex].dealer_cards[i].code, 0, 1), "A")) {
                        games[gameIndex].dealer_cards[i].value = uint8(1);
                        newHandTotal = newHandTotal + 1;
                    } else {
                        newHandTotal = newHandTotal + games[gameIndex].dealer_cards[i].value;
                    }
                }
                handTotal = newHandTotal;
            }
        }
        return handTotal;
    }

    function checkBlackjack(uint128 gameIndex) internal {
        uint8 playerCardValueTotal = getTotalHandValue(gameIndex, Player.Player);
        uint8 dealerCardValueTotal = getTotalHandValue(gameIndex, Player.Dealer);
        if (playerCardValueTotal == 21 && dealerCardValueTotal == 21) {
            setWinner(gameIndex, Winner.Player, games[gameIndex].bet * 2);
        } else if (playerCardValueTotal == 21) {
            setWinner(gameIndex, Winner.Player, (games[gameIndex].bet * 2));
        } else if (dealerCardValueTotal == 21) {
            setWinner(gameIndex, Winner.Dealer, 0);
        } else {
            games[gameIndex].winner = Winner.Unknown;
        }
    }

    function evaluateHands(uint128 gameIndex) internal {
        uint8 playerCardValueTotal = getTotalHandValue(gameIndex, Player.Player);
        uint8 dealerCardValueTotal = getTotalHandValue(gameIndex, Player.Dealer);
        if (playerCardValueTotal > 21) {
            setWinner(gameIndex, Winner.Dealer, 0);
        } else if (dealerCardValueTotal > 21) {
            setWinner(gameIndex, Winner.Player, games[gameIndex].bet * 2);
        } else if (playerCardValueTotal == 21 && dealerCardValueTotal == 21) {
            setWinner(gameIndex, Winner.Tie, games[gameIndex].bet);
        } else if (playerCardValueTotal == 21) {
            setWinner(gameIndex, Winner.Player, games[gameIndex].bet * 2);
        } else if (dealerCardValueTotal == 21) {
            setWinner(gameIndex, Winner.Dealer, 0);
        } else if (playerCardValueTotal == dealerCardValueTotal) {
            setWinner(gameIndex, Winner.Tie, games[gameIndex].bet);
        } else if (playerCardValueTotal > dealerCardValueTotal) {
            setWinner(gameIndex, Winner.Player, games[gameIndex].bet * 2);
        } else if (dealerCardValueTotal > playerCardValueTotal) {
            setWinner(gameIndex, Winner.Dealer, 0);
        }
    }

    function setWinner(uint128 gameIndex, Winner winner, uint256 payout) internal {
        games[gameIndex].winner = winner;
        games[gameIndex].payout = payout;
        if (games[gameIndex].winner == Winner.Player || games[gameIndex].winner == Winner.Tie) {
            pendingPayouts[games[gameIndex].player] = pendingPayouts[games[gameIndex].player] + payout;
            totalPendingPayouts = totalPendingPayouts + payout;
        }
        emit GameWon(games[gameIndex].id, games[gameIndex].winner, games[gameIndex].payout);
    }

    function valueStringToValueUint(string memory _value) internal pure returns (uint8) {
        if (equals(_value, "J") || equals(_value, "Q") || equals(_value, "K") || equals(_value, "0")) {
            _value = "10";
        } else if (equals(_value, "A")) {
            _value = "11";
        }
        return uint8(stringToUint(_value));
    }

    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly { // solhint-disable-line no-inline-assembly
            result := mload(add(source, 32))
        }
    }

    function stringToUint(string memory s) internal pure returns (uint result) {
        bytes memory b = bytes(s);
        uint i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint8 c = uint8(b[i]);
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }

    function substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }

    function equals(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }

    // FOR TESTING PURPOSES ONLY: REMOVE FOR PRODUCTION
    function withdrawLink() public {
        require(msg.sender == manager, "Must be manager");
        LINK.transfer(manager, LINK.balanceOf(address(this)));
    }

    // FOR TESTING PURPOSES ONLY: REMOVE FOR PRODUCTION
    function destroy() public {
        require(msg.sender == manager, "Must be manager");
        selfdestruct(manager);
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