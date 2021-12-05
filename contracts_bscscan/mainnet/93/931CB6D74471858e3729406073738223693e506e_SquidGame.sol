// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./dependencies/@uniswap/v2-periphery/interfaces/IUniswapV2Router02.sol";
import "./dependencies/@chainlink/v0.8/VRFConsumerBase.sol";
import "./dependencies/@openzeppelin/utils/Address.sol";
import "./dependencies/@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "./dependencies/@openzeppelin/access/Ownable.sol";
import "./dependencies/@openzeppelin/security/ReentrancyGuard.sol";
import "./dependencies/@openzeppelin/proxy/utils/Initializable.sol";
import "./interfaces/ISQM.sol";
import "./interfaces/oracle/IOracle.sol";

contract SquidGame is ReentrancyGuard, Ownable, VRFConsumerBase {
    using SafeERC20 for IERC20;
    using SafeERC20 for ISQM;

    IERC20 public constant usdt = IERC20(0x55d398326f99059fF775485246999027B3197955);
    ISQM public constant squid = ISQM(0x2766CC2537538aC68816B6B5a393fA978A4a8931);
    IUniswapV2Router02 public constant router = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);

    uint256 public constant ORACLE_PERIOD = 2 hours;

    address public constant LINK_TOKEN = 0x404460C6A5EdE2D891e8297795264fDe62ADBB75;
    address public constant VFR_COORDINATOR = 0x747973a5A2a4Ae1D3a8fDF5479f1514F65Db9C31;
    bytes32 public constant CHAINLINK_KEY_HASH = 0xc251acd21ec4fb7f31bb8868288bfdbaeb4fbfec2df3735ddbd4f7dc8d60103c;
    uint256 public constant CHAINLINK_FEE = 0.2 ether;

    uint256 public constant TOP_WINNERS_PERCENT = 8e16; // 8%
    uint256 public constant WINNER_TAX = 5e16; // 5%
    uint256 public constant NONE_PROBABILITY = 10; // 10%

    uint256 public constant TOP_WINNERS_REWARD_SHARE = 8e17; // 80%
    uint256 public constant DEVS_REWARD_SHARE = 2e17; // 20%

    enum BetOutcome {
        PENDING,
        NONE,
        EVEN,
        ODD
    }

    IOracle public oracle;
    uint256 public swapSlippage;
    address public devsWallet;
    uint256 public start;
    uint256 public end;
    uint256 public prizeBoost;
    bool public distributed;

    struct Bet {
        address player;
        BetOutcome bet;
        uint256 bnbAmount;
        BetOutcome result;
    }
    mapping(bytes32 => Bet) public bets;

    // A winner is a user that won at least one bet
    struct Winner {
        address player;
        uint256 score; // Total amount of BNB from winner bets
        uint256 reward;
        bool claimed;
    }
    mapping(address => uint256) public winnerId;
    Winner[] public winners;

    event BetPlaced(bytes32 betId, address player, uint256 bnbAmount, BetOutcome bet);
    event BetResolved(bytes32 betId, BetOutcome _result);
    event RewardDistribuited(address player, uint256 reward);

    modifier onlyIfActive() {
        require(block.timestamp >= start && block.timestamp < end, "SquidGame: The game is over");
        _;
    }

    modifier onlyIfIsOver() {
        require(block.timestamp >= end, "SquidGame: The game is still active");
        _;
    }

    function initialize(
        IOracle _oracle,
        address _devsWallet,
        uint256 _start,
        uint256 _end
    ) public initializer {
        require(_devsWallet != address(0), "SquidGame: devs wallet is null");
        require(_end > _start, "SquidGame: Invalid end date");
        require(_start >= block.timestamp + ORACLE_PERIOD, "SquidGame: Invalid start date");

        _initializeReentrancyGuard();
        _initializeOwnable();
        _initalizeVRFConsumerBase(VFR_COORDINATOR, LINK_TOKEN);

        oracle = _oracle;
        swapSlippage = 0.2 ether; // 20 %
        start = _start;
        end = _end;
        devsWallet = _devsWallet;
        prizeBoost = 0;
    }

    receive() external payable {}

    function placeBet(BetOutcome _bet) external payable nonReentrant onlyIfActive {
        require(LINK.balanceOf(address(this)) >= CHAINLINK_FEE, "SquidGame: Not enough LINK");
        require(_bet == BetOutcome.EVEN || _bet == BetOutcome.ODD, "SquidGame: Incorrect bet");

        require(
            msg.value == 0.002 ether || msg.value == 0.004 ether || msg.value == 0.006 ether,
            "SquidGame: Incorrect bet value"
        );

        bytes32 _betId = requestRandomness(CHAINLINK_KEY_HASH, CHAINLINK_FEE);

        address _player = _msgSender();

        bets[_betId] = Bet({ player: _player, bet: _bet, bnbAmount: msg.value, result: BetOutcome.PENDING });

        emit BetPlaced(_betId, _player, msg.value, _bet);
    }

    function _amountOutAfterSlippage(uint256 _amountIn, uint256 _slippage) private pure returns (uint256 _amountOut) {
        _amountOut = (_amountIn * (1e18 - _slippage)) / (1e18);
    }

    function _amountInAfterSlippage(uint256 _amountOut, uint256 _slippage) private pure returns (uint256 _amountIn) {
        _amountIn = (_amountOut * (1e18 + _slippage)) / (1e18);
    }

    function _chainlinkFeeInBnb() private returns (uint256) {
        return oracle.consultLinkForBnb(CHAINLINK_FEE);
    }

    function _swapBnbForSquid(uint256 _amountIn) private returns (uint256 _amountOut) {
        address[] memory path = new address[](3);
        path[0] = router.WETH();
        path[1] = address(usdt);
        path[2] = address(squid);

        uint256 amountOut = oracle.consultBnbForSqm(_amountIn);
        uint256 amountOutMin = _amountOutAfterSlippage(amountOut, swapSlippage);

        uint256 sqmBefore = squid.balanceOf(address(this));
        router.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: _amountIn }(
            amountOutMin,
            path,
            address(this),
            type(uint256).max
        );
        uint256 sqmAfter = squid.balanceOf(address(this));
        return sqmAfter - sqmBefore;
    }

    function _swapBnbForUsdt(uint256 _amountIn) private returns (uint256 _amountOut) {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(usdt);

        uint256 amountOut = oracle.consultBnbForUsdt(_amountIn);
        uint256 amountOutMin = _amountOutAfterSlippage(amountOut, swapSlippage);

        uint256[] memory amounts = router.swapExactETHForTokens{ value: _amountIn }(
            amountOutMin,
            path,
            address(this),
            type(uint256).max
        );
        return amounts[1];
    }

    // We take 50% the users bet in BNB
    // From that net amount we add 50% of BNB to reward pool and 50% to buy SQM and add liquidity
    function _resolveNone(Bet memory _bet) private {
        uint256 _toPlayer = _bet.bnbAmount / 2 - _chainlinkFeeInBnb(); // ~50%
        uint256 _toPrize = _bet.bnbAmount / 4; // 25%
        uint256 _toLiquidity = _bet.bnbAmount / 4; // 25%
        Address.sendValue(payable(_bet.player), _toPlayer);

        uint256 _squidBought = _swapBnbForSquid(_toPrize + _toLiquidity / 2); // 36.5%

        uint256 _squidToAdd = (_squidBought * 333333333333333333) / 1e18; // 12.5%
        uint256 _usdtToAdd = _swapBnbForUsdt(_toLiquidity / 2); // 12.5%
        squid.approve(address(router), _squidToAdd);
        usdt.approve(address(router), _usdtToAdd);
        router.addLiquidity(address(squid), address(usdt), _squidToAdd, _usdtToAdd, 1, 1, owner(), type(uint256).max);
    }

    function _isWinnerExists(address _address) private view returns (bool) {
        return winners.length > 0 && winners[winnerId[_address]].player == _address;
    }

    // Increment winner's score or create a new one
    function _createOrUpdateWinner(address _address, uint256 _score) private {
        if (!_isWinnerExists(_address)) {
            uint256 _id = winners.length;
            winners.push(Winner({ player: _address, score: _score, reward: 0, claimed: false }));
            winnerId[_address] = _id;
        } else {
            for (uint256 i = 0; i < winners.length; ++i) {
                if (winners[i].player == _address) {
                    winners[i] = Winner({
                        player: _address,
                        score: winners[i].score + _score,
                        reward: 0,
                        claimed: false
                    });
                    break;
                }
            }
        }
    }

    function _mintSquidWorthOfBnb(address _to, uint256 _bnbAmount) private {
        address[] memory path = new address[](3);
        path[0] = address(squid);
        path[1] = address(usdt);
        path[2] = router.WETH();

        uint256[] memory amountsIn = router.getAmountsIn(_bnbAmount, path);
        uint256 _toMint = amountsIn[0];

        uint256 amountOut = oracle.consultBnbForSqm(_bnbAmount);
        uint256 maxToMint = _amountInAfterSlippage(amountOut, swapSlippage);

        require(_toMint <= maxToMint, "SquidGame: Invalid amount to mint");

        squid.mint(_to, _toMint);
    }

    // We take 5% tax from bet in BNB and add to reward pool
    // Return 95% of bet in BNB and mint SQM equal to 95% their initial bet
    function _resolveWin(Bet memory _bet) private {
        _createOrUpdateWinner(_bet.player, _bet.bnbAmount);
        uint256 _winnerTaxAmount = (_bet.bnbAmount * WINNER_TAX) / 1e18;
        uint256 _paybackAmount = _bet.bnbAmount - _winnerTaxAmount - _chainlinkFeeInBnb();

        Address.sendValue(payable(_bet.player), _paybackAmount);
        _mintSquidWorthOfBnb(_bet.player, _paybackAmount);
        _swapBnbForSquid(_winnerTaxAmount);
    }

    // LOSE: We take full bet in BNB to buy SQM from DEX and burn it.
    function _resolveLost(Bet memory _bet) private {
        uint256 _amountBought = _swapBnbForSquid(_bet.bnbAmount - _chainlinkFeeInBnb());
        squid.burn(address(this), _amountBought);
    }

    // Update a pending bet with the result
    function _resolveBet(bytes32 _betId, BetOutcome _result) private {
        Bet storage _bet = bets[_betId];

        if (_bet.result != BetOutcome.PENDING) {
            return;
        }

        _bet.result = _result;

        if (_result == BetOutcome.NONE) {
            _resolveNone(_bet);
        } else if (_result == _bet.bet) {
            _resolveWin(_bet);
        } else {
            _resolveLost(_bet);
        }

        emit BetResolved(_betId, _result);
    }

    // Function called when Chainlink returns randomness
    // There are 3 possibilities for the result
    // NONE: Probability is set by `NONE_PROBABILITY` var
    // EVEN/ODD: Both have the same probability (100% - NONE_PROBABILITY)/2 each
    function fulfillRandomness(bytes32 _betId, uint256 randomness) internal override {
        uint256 _random = randomness % 100; // random is a 0..99 number

        BetOutcome _result;

        if (_random < NONE_PROBABILITY) {
            _result = BetOutcome.NONE;
        } else if (_random < (((100 - NONE_PROBABILITY) / 2) + NONE_PROBABILITY)) {
            _result = BetOutcome.EVEN;
        } else {
            _result = BetOutcome.ODD;
        }

        _resolveBet(_betId, _result);
    }

    // Sort desc based on score
    function _quickSort(
        Winner[] memory arr,
        int256 left,
        int256 right
    ) private view {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        Winner memory pivot = arr[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint256(i)].score > pivot.score) i++;
            while (pivot.score > arr[uint256(j)].score) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                i++;
                j--;
            }
        }
        if (left < j) _quickSort(arr, left, j);
        if (i < right) _quickSort(arr, i, right);
    }

    // Sort winners
    function _sort(Winner[] memory data) private view returns (Winner[] memory) {
        _quickSort(data, int256(0), int256(data.length - 1));
        return data;
    }

    // Distribuite rewards
    // This function will use all SQUID that its hold to buy BNB that will be used as pot
    // The pool will be splitted among 1) Top winners, 2) A few bottom winners and 3) Devs
    // Note: Top winners rewards will be distribuited score weighted
    // Note: Only owner can call this to have enough to set prize boost properly
    function distribute() external onlyOwner nonReentrant onlyIfIsOver {
        require(distributed == false, "SquidGame: rewards have already been distributed");

        distributed = true;

        // 0. Return Chainlink-related assets to owner
        uint256 _linkBalance = LINK.balanceOf(address(this));
        if (_linkBalance > 0) {
            IERC20(address(LINK)).safeTransfer(owner(), _linkBalance);
        }
        uint256 _bnbBalance = address(this).balance;
        if (_bnbBalance > 0) {
            Address.sendValue(payable(owner()), _bnbBalance);
        }

        // 1. Use all squid held by contract
        if (prizeBoost > 0) {
            squid.mint(address(this), prizeBoost);
        }
        uint256 _totalSquid = squid.balanceOf(address(this));

        // 2. Sort winner list by score desc
        uint256 _winnersLength = winners.length;
        Winner[] memory orderedWinners = _sort(winners);
        uint256 _topWinnersLength = (_winnersLength * TOP_WINNERS_PERCENT) / 1e18;

        if (_topWinnersLength == 0) {
            squid.safeTransfer(devsWallet, _totalSquid);
            return;
        }

        // 3. Get total score from top winners
        uint256 _totalTopWinnersScore;
        for (uint256 i = 0; i < _topWinnersLength; ++i) {
            _totalTopWinnersScore += orderedWinners[i].score;
        }

        // 4. Split all BNB in 3 parts A) 80% to top winner B) 10% to devs and C) 10% to further distribution
        uint256 _toTopWinners = (_totalSquid * TOP_WINNERS_REWARD_SHARE) / 1e18;
        uint256 _toDevs = (_totalSquid * DEVS_REWARD_SHARE) / 1e18;

        // 5. Set score weighted rewards for the top 9% winners
        for (uint256 i = 0; i < _topWinnersLength; ++i) {
            uint256 _id = winnerId[orderedWinners[i].player];
            winners[_id].reward = (_toTopWinners * winners[_id].score) / _totalTopWinnersScore;
            emit RewardDistribuited(winners[_id].player, winners[_id].reward);
        }

        // 6. Send devs' share
        squid.safeTransfer(devsWallet, _toDevs);
    }

    // Claim reward
    function claim() external nonReentrant {
        require(distributed, "SquidGame: rewards have not been distributed");
        require(_isWinnerExists(_msgSender()), "SquidGame: Nothing to claim");

        uint256 _winnerId = winnerId[_msgSender()];
        Winner storage _winner = winners[_winnerId];

        require(_winner.reward > 0, "SquidGame: Nothing to claim");
        require(!_winner.claimed, "SquidGame: Already claimed");

        _winner.claimed = true;

        squid.safeTransfer(_msgSender(), _winner.reward);
    }

    function updateEnd(uint256 _newEnd) external onlyOwner {
        end = _newEnd;
    }

    function updatePrizeBoost(uint256 _newPrizeBoost) external onlyOwner {
        prizeBoost = _newPrizeBoost;
    }

    function updateSwapSlippage(uint256 _newSlippage) external onlyOwner {
        swapSlippage = _newSlippage;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "../../@openzeppelin/proxy/utils/Initializable.sol";

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
abstract contract VRFConsumerBase is Initializable, VRFRequestIDBase {
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

    LinkTokenInterface internal LINK;
    address private vrfCoordinator;

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
    function _initalizeVRFConsumerBase(address _vrfCoordinator, address _link) internal initializer {
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

import "../utils/Context.sol";

import "../proxy/utils/Initializable.sol";

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
abstract contract Ownable is Context, Initializable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function _initializeOwnable() internal initializer {
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
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function _initializeReentrancyGuard() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/@openzeppelin/token/ERC20/IERC20.sol";

interface ISQM is IERC20 {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    function transferFee() external view returns (uint256);

    function addToMinters(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IOracle {
    function consultBnbForSqm(uint256 amountIn) external returns (uint256 amountOut);

    function consultBnbForUsdt(uint256 amountIn) external returns (uint256 amountOut);

    function consultLinkForBnb(uint256 amountIn) external returns (uint256 amountOut);
}