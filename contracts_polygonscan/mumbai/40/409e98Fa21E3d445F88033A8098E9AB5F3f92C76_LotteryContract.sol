pragma solidity ^0.6.0;

import "./interfaces/IERC20.sol";
import "./VRFConsumerBase.sol";
import "@openzeppelin/contracts/utils/Address.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract LotteryContract is VRFConsumerBase, ReentrancyGuard, Ownable {
    using Address for address;
    using SafeMath for uint256;

    struct LotteryConfig {
        uint256 numOfWinners;
        uint256 playersLimit;
        uint256 registrationAmount;
        uint256 adminFeePercentage;
        uint256 randomSeed;
        uint256 startedAt;
    }

    address[] public lotteryPlayers;
    address public feeAddress;
    enum LotteryStatus {
        NOTSTARTED,
        INPROGRESS,
        CLOSED
    }
    mapping(uint256 => address) public winnerAddresses;
    uint256[] public winnerIndexes;
    uint256 public totalLotteryPool;
    uint256 public adminFeesAmount;
    uint256 public rewardPoolAmount;

    IERC20 public lotteryToken;
    IERC20 public buyToken;
    LotteryStatus public lotteryStatus;
    LotteryConfig public lotteryConfig;

    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 internal randomResult;
    bool internal areWinnersGenerated;
    bool internal isRandomNumberGenerated;

    bool public pauseLottery;

    uint256 public loserLotteryAmount;
    // event MaxParticipationCompleted(address indexed _from);

    event RandomNumberGenerated(uint256 indexed randomness);

    event WinnersGenerated(uint256[] winnerIndexes);

    event LotterySettled(
        uint256 _rewardPoolAmount,
        uint256 _players,
        uint256 _adminFees
    );

    event LotteryPaused();

    event LotteryUnPaused();

    event EmergencyWithdrawn();

    // LotterySettled(rewardPoolAmount, players, adminFeesAmount);

    event LotteryStarted(
        uint256 playersLimit,
        uint256 numOfWinners,
        uint256 registrationAmount,
        uint256 startedAt
    );

    event LotteryReset();

    /**
     * @dev Sets the value for adminAddress which establishes the Admin of the contract
     * Only the adminAddress will be able to set the lottery configuration,
     * start the lottery and reset the lottery.
     *
     * It also sets the required fees, keyHash etc. for the ChainLink Oracle RNG
     *
     * Also initializes the LOT ERC20 TOKEN that is minted/burned by the participating lottery players.
     *
     * The adminAdress value is immutable along with the initial
     * configuration of VRF Smart Contract. They can only be set once during
     * construction.
     */
    constructor(
        IERC20 _buyToken,
        IERC20 _lotteryToken,
        address _feeAddress,
        address _vrfCoordinator,
        address _link,
        bytes32 _keyHash
    )
        public
        VRFConsumerBase(
            _vrfCoordinator, // VRF Coordinator
            _link // LINK Token
        )
        Ownable()
    {
        feeAddress = _feeAddress;
        lotteryStatus = LotteryStatus.NOTSTARTED;
        totalLotteryPool = 0;
        keyHash = _keyHash;
        fee = 0.0001 * 10**18; // 0.0001 LINK
        areWinnersGenerated = false;
        isRandomNumberGenerated = false;
        buyToken = _buyToken; // ERC20 contract
        lotteryToken = _lotteryToken; // ERC20 contract
        // isOnlyETHAccepted = _isOnlyETHAccepted;
    }

    function pauseNextLottery() public onlyOwner {
        // require(
        //     msg.sender == adminAddress,
        //     "Starting the Lottery requires Admin Access"
        // );
        pauseLottery = true;
        emit LotteryPaused();
    }

    function unPauseNextLottery() public onlyOwner {
        // require(
        //     msg.sender == adminAddress,
        //     "Starting the Lottery requires Admin Access"
        // );
        pauseLottery = false;
        emit LotteryUnPaused();
        // resetLottery();
    }

    function withdrawLink() external onlyOwner {
        LINK.transfer(owner(), LINK.balanceOf(address(this)));
    }

    function changeFeeAddress(address _feeAddress) public onlyOwner {
        require(_feeAddress != address(0), "Incorrect fee address");
        feeAddress = _feeAddress;
    }

    /**
     * @dev Calls ChainLink Oracle's inherited function for
     * Random Number Generation.
     *
     * Requirements:
     *
     * - the contract must have a balance of at least `fee` required for VRF.
     */
    function getRandomNumber(uint256 userProvidedSeed)
        internal
        returns (bytes32 requestId)
    {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        isRandomNumberGenerated = false;
        return requestRandomness(keyHash, fee, userProvidedSeed);
    }

    /**
     * @dev The callback function of ChainLink Oracle when the
     * Random Number Generation is completed. An event is fired
     * to notify the same and the randomResult is saved.
     *
     * Emits an {RandomNumberGenerated} event indicating the random number is
     * generated by the Oracle.
     *
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        randomResult = randomness;
        isRandomNumberGenerated = true;
        emit RandomNumberGenerated(randomness);
    }

    /**
     * @dev Sets the Lottery Config, initializes an instance of
     * ERC20 contract that the lottery is based on and starts the lottery.
     *
     * Emits an {LotteryStarted} event indicating the Admin has started the Lottery.
     *
     * Requirements:
     *
     * - Cannot be called if the lottery is in progress.
     * - Only the address set at `adminAddress` can call this function.
     * - Number of winners `numOfWinners` should be less than or equal to half the number of
     *   players `playersLimit`.
     */
    function setLotteryRules(
        uint256 numOfWinners,
        uint256 playersLimit,
        uint256 registrationAmount,
        uint256 adminFeePercentage,
        uint256 randomSeed
    ) public onlyOwner {
        // require(
        //     msg.sender == adminAddress,
        //     "Starting the Lottery requires Admin Access"
        // );
        require(
            lotteryStatus == LotteryStatus.NOTSTARTED,
            "Error: An existing lottery is in progress"
        );
        require(
            numOfWinners <= playersLimit.div(2),
            "Number of winners should be less than or equal to half the number of players"
        );
        lotteryConfig = LotteryConfig(
            numOfWinners,
            playersLimit,
            registrationAmount,
            adminFeePercentage,
            // lotteryTokenAddress,
            randomSeed,
            block.timestamp
        );
        lotteryStatus = LotteryStatus.INPROGRESS;

        loserLotteryAmount = (registrationAmount.mul(1e18)).div(
            10**buyToken.decimals()
        );

        emit LotteryStarted(
            // lotteryTokenAddress,
            playersLimit,
            numOfWinners,
            registrationAmount,
            block.timestamp
        );
    }

    /**
     * @dev Player enters the lottery and the registration amount is
     * transferred from the player to the contract.
     *
     * Returns participant's index. This is similar to unique registration id.
     * Emits an {MaxParticipationCompleted} event indicating that all the required players have entered the lottery.
     *
     * The participant is also issued an equal amount of LOT tokens once he registers for the lottery.
     * This LOT tokens are fundamental to the lottery contract and are used internally.
     * The winners will need to burn their LOT tokens to claim the lottery winnings.
     * The other participants of the lottery can keep hold of these tokens and use for other applications.
     *
     * Requirements:
     *
     * - The player has set the necessary allowance to the Contract.
     * - The Lottery is in progress.
     * - Number of players allowed to enter in the lottery should be
     *   less than or equal to the allowed players `lotteryConfig.playersLimit`.
     */
    function enterLottery() public returns (uint256) {
        require(
            lotteryPlayers.length < lotteryConfig.playersLimit,
            "Max Participation for the Lottery Reached"
        );

        // require(
        //     lotteryPlayers.length == 0 && !pauseLottery,
        //     "Lottery is paused"
        // );

        if (lotteryPlayers.length == 0) {
            require(!pauseLottery, "Lottery is paused");
        }

        require(
            lotteryStatus == LotteryStatus.INPROGRESS,
            "The Lottery is not started or closed"
        );
        lotteryPlayers.push(msg.sender);

        buyToken.transferFrom(
            msg.sender,
            address(this),
            lotteryConfig.registrationAmount
        );

        totalLotteryPool = totalLotteryPool.add(
            lotteryConfig.registrationAmount
        );
        // call _mint from constructor ERC20
        // Not giving loser lottery tokens !!
        // lotteryToken.mint(msg.sender, lotteryConfig.registrationAmount);

        if (lotteryPlayers.length == lotteryConfig.playersLimit) {
            // emit MaxParticipationCompleted(msg.sender); // this is not needed now
            getRandomNumber(lotteryConfig.randomSeed);
        }
        return (lotteryPlayers.length).sub(1);
    }

    /**
     * @dev Settles the lottery, the winners are calculated based on
     * the random number generated. The Admin fee is calculated and
     * transferred back to Admin `adminAddress`.
     *
     * Emits an {WinnersGenerated} event indicating that the winners for the lottery have been generated.
     * Emits {LotterySettled} event indicating that the winnings have been transferred to the Admin and the Lottery is closed.
     *
     * Requirements:
     *
     * - The random number has been generated
     * - The Lottery is in progress.
     */
    function settleLottery() external {
        require(
            isRandomNumberGenerated,
            "Lottery Configuration still in progress. Please try in a short while"
        );
        require(
            lotteryStatus == LotteryStatus.INPROGRESS,
            "The Lottery is not started or closed"
        );
        for (uint256 i = 0; i < lotteryConfig.numOfWinners; i = i.add(1)) {
            uint256 winningIndex = randomResult.mod(lotteryConfig.playersLimit);
            uint256 counter = 0;
            while (winnerAddresses[winningIndex] != address(0)) {
                randomResult = getRandomNumberBlockchain(i, randomResult);
                winningIndex = randomResult.mod(lotteryConfig.playersLimit);
                counter = counter.add(1);
                if (counter == lotteryConfig.playersLimit) {
                    while (winnerAddresses[winningIndex] != address(0)) {
                        winningIndex = (winningIndex.add(1)).mod(
                            lotteryConfig.playersLimit
                        );
                    }
                    counter = 0;
                }
            }
            winnerAddresses[winningIndex] = lotteryPlayers[winningIndex];
            winnerIndexes.push(winningIndex);
            randomResult = getRandomNumberBlockchain(i, randomResult);
        }
        areWinnersGenerated = true;
        emit WinnersGenerated(winnerIndexes);
        adminFeesAmount = (
            (totalLotteryPool.mul(lotteryConfig.adminFeePercentage)).div(100)
        );
        rewardPoolAmount = (totalLotteryPool.sub(adminFeesAmount)).div(
            lotteryConfig.numOfWinners
        );
        lotteryStatus = LotteryStatus.CLOSED;

        // if (isOnlyETHAccepted) {
        //     (bool status, ) = payable(adminAddress).call{
        //         value: adminFeesAmount
        //     }("");
        //     require(status, "Admin fees not transferred");
        // } else {
        buyToken.transfer(feeAddress, adminFeesAmount);
        // }

        emit LotterySettled(
            rewardPoolAmount,
            lotteryConfig.numOfWinners,
            adminFeesAmount
        );
        collectRewards();
    }

    function getWinningAmount() public view returns (uint256) {
        uint256 expectedTotalLotteryPool = lotteryConfig.playersLimit.mul(
            lotteryConfig.registrationAmount
        );
        uint256 adminFees = (
            (expectedTotalLotteryPool.mul(lotteryConfig.adminFeePercentage))
                .div(100)
        );
        uint256 rewardPool = (expectedTotalLotteryPool.sub(adminFees)).div(
            lotteryConfig.numOfWinners
        );

        return rewardPool;
    }

    function getCurrentlyActivePlayers() public view returns (uint256) {
        return lotteryPlayers.length;
    }

    /**
     * @dev The winners of the lottery can call this function to transfer their winnings
     * from the lottery contract to their own address. The winners will need to burn their
     * LOT tokens to claim the lottery rewards. This is executed by the lottery contract itself.
     *
     *
     * Requirements:
     *
     * - The Lottery is settled i.e. the lotteryStatus is CLOSED.
     */
    /**
     * @dev The winners of the lottery can call this function to transfer their winnings
     * from the lottery contract to their own address. The winners will need to burn their
     * LOT tokens to claim the lottery rewards. This is executed by the lottery contract itself.
     *
     *
     * Requirements:
     *
     * - The Lottery is settled i.e. the lotteryStatus is CLOSED.
     */
    function collectRewards() private nonReentrant {
        // require(
        //     lotteryStatus == LotteryStatus.CLOSED,
        //     "The Lottery is not settled. Please try in a short while."
        // );

        bool isWinner = false;

        for (uint256 i = 0; i < lotteryConfig.playersLimit; i = i.add(1)) {
            address player = lotteryPlayers[i];
            // if (address(msg.sender) == winnerAddresses[winnerIndexes[i]]) {
            for (uint256 j = 0; j < lotteryConfig.numOfWinners; j = j.add(1)) {
                address winner = winnerAddresses[winnerIndexes[j]];

                if (winner != address(0) && winner == player) {
                    isWinner = true;
                    winnerAddresses[winnerIndexes[j]] = address(0);
                    break;
                }
            }

            if (isWinner) {
                // _burn(address(msg.sender), lotteryConfig.registrationAmount);
                // lotteryToken.burnFrom(msg.sender, lotteryConfig.registrationAmount);
                // if (isOnlyETHAccepted) {
                //     (bool status, ) = payable(player).call{
                //         value: rewardPoolAmount
                //     }("");
                //     require(status, "Amount not transferred to winner");
                // } else {
                buyToken.transfer(address(player), rewardPoolAmount);
                // }
            } else {
                lotteryToken.mint(player, loserLotteryAmount);
            }

            isWinner = false;
        }

        resetLottery();
    }

    /**
     * @dev Generates a random number based on the blockHash and random offset
     */
    function getRandomNumberBlockchain(uint256 offset, uint256 randomness)
        internal
        view
        returns (uint256)
    {
        bytes32 offsetBlockhash = blockhash(block.number.sub(offset));
        uint256 randomBlockchainNumber = uint256(offsetBlockhash);
        uint256 finalRandomNumber = randomness + randomBlockchainNumber;
        if (finalRandomNumber >= randomness) {
            return finalRandomNumber;
        } else {
            if (randomness >= randomBlockchainNumber) {
                return randomness.sub(randomBlockchainNumber);
            }
            return randomBlockchainNumber.sub(randomness);
        }
    }

    /**
     * It can be called by admin to withdraw all the amount in case of
     * any failure to play lottery. It will be distributed later on amongst the
     * participants.
     */
    function emergencyWithdraw() external onlyOwner {
        buyToken.transfer(msg.sender, buyToken.balanceOf(address(this)));
        emit EmergencyWithdrawn();
    }

    /**
     * @dev Resets the lottery, clears the existing state variable values and the lottery
     * can be initialized again.
     *
     * Emits {LotteryReset} event indicating that the lottery config and contract state is reset.
     *
     * Requirements:
     *
     * - Only the address set at `adminAddress` can call this function.
     * - The Lottery has closed.
     */
    function resetLottery() private {
        // require(
        //     msg.sender == adminAddress,
        //     "Resetting the Lottery requires Admin Access"
        // );
        // require(
        //     lotteryStatus == LotteryStatus.CLOSED,
        //     "Lottery Still in Progress"
        // );
        uint256 tokenBalance = buyToken.balanceOf(address(this));
        if (tokenBalance > 0) {
            buyToken.transfer(feeAddress, tokenBalance);
        }
        // delete lotteryConfig;
        delete randomResult;
        lotteryStatus = LotteryStatus.INPROGRESS;
        delete totalLotteryPool;
        delete adminFeesAmount;
        delete rewardPoolAmount;
        for (uint256 i = 0; i < lotteryPlayers.length; i = i.add(1)) {
            delete winnerAddresses[i];
        }
        isRandomNumberGenerated = false;
        areWinnersGenerated = false;
        delete winnerIndexes;
        delete lotteryPlayers;
        emit LotteryReset();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

    function mint(address receipient, uint256 amount) external returns (bool);

    function burnFrom(address from, uint256 amount) external;

    function decimals() external view returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@openzeppelin/contracts/math/SafeMath.sol";

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

  using SafeMath for uint256;

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

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
abstract contract ReentrancyGuard {
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

    constructor () internal {
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

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}