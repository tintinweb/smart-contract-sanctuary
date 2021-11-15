//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Standards/ERC721/ERC721.sol";
import "./Interfaces/IFountainOfFortune.sol";
import "./Interfaces/IWETH.sol";
import "./Utils/Counters.sol";
import "./Chainlink/VRFConsumerBase.sol";

/**
 * @title Fountain Of Fortune
 * @author Myobu Devs
 */
contract FountainOfFortune is
    VRFConsumerBase(
        0xf0d54349aDdcf704F77AE15b96510dEA15cb7952,
        0x514910771AF9Ca656af840dff83E8264EcF986CA
    ),
    IFountainOfFortune,
    ERC721("Fountain of Fortune", "FOF")
{
    /// @dev Using counters for lottery ID's
    using Counters for Counters.Counter;

    /**
     * @dev
     * _myobu: The Myobu token contract
     * _WETH: The WETH contract used to wrap ETH
     * _chainlinkKeyHash: The chainlink key hash
     * _chainlinkFee: The amount of link to pay for random numbers
     * _feeReceiver: Where all the ticket sale fees will be sent to
     * _tokenID: Used to mint NFTs, increases for each NFT minted
     * _lastClaimedTokenID: Used to store the last tokenID that fees were claimed for
     * _rewardClaimed: Used to store if the reward has been claimed for the current lottery, resets per lottery
     * _inClaimReward: Used to store if its waiting for an oracle response, so claimReward() can't be called multiple times
     * and waste all the LINK in the contract
     * _lotteryID: A counter of how much lotteries there have been, increases by 1 each new lottery
     * _lottery: A mapping of Lottery ID => The lottery struct that stores information
     * _ticketsBought: A mapping of Address => Lottery ID => Amount of tickets bought
     */
    IERC20 private _myobu;
    // solhint-disable-next-line
    IWETH private _WETH;
    bytes32 private _chainlinkKeyHash;
    uint256 private _chainlinkFee;
    address private _feeReceiver;
    uint256 private _tokenID;
    uint256 private _lastClaimedTokenID;
    bool private _rewardClaimed;
    bool private _inClaimReward;
    Counters.Counter private _lotteryID;
    mapping(uint256 => Lottery) private _lottery;
    mapping(address => mapping(uint256 => uint256)) private _ticketsBought;

    /**
     * @dev Modifier that requires that there is no lottery ongoing (ended)
     */
    modifier onlyEnded {
        require(
            _lottery[_lotteryID.current()].endTimestamp <= block.timestamp,
            "FoF: Lottery needs to have ended for this"
        );
        _;
    }

    /**
     * @dev Modifier that requires that there is a lottery in progress (on)
     */
    modifier onlyOn {
        require(
            _lottery[_lotteryID.current()].endTimestamp > block.timestamp,
            "FoF: No lottery is on right now"
        );
        _;
    }

    /**
     * @dev Defines the Myobu and WETH token contracts, the chainlink fee and keyhash
     */
    constructor() {
        _myobu = IERC20(0x75D12E4F91Df721faFCae4c6cD1d5280381370AC);
        _feeReceiver = address(0xdD5FD50DcB8Db2B41357f8E655b941A04b566Cb5);
        _WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        _chainlinkKeyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        _chainlinkFee = 2e18;
        /// @dev So the owner can be able to start the lottery
        _rewardClaimed = true;
        /// @dev Start ID's at 1
        _tokenID = 1;
        _lastClaimedTokenID = 1;
    }

    /**
     * @dev Attempt to transfer ETH, if failed wrap the ETH and send WETH. So that the
     * transfer always succeeds
     * @param to: The address to send ETH to
     * @param amount: The amount to send
     */
    function transferOrWrapETH(address to, uint256 amount) internal {
        // solhint-disable-next-line
        if (!payable(to).send(amount)) {
            _WETH.deposit{value: amount}();
            _WETH.transfer(to, amount);
        }
    }

    /**
     * @dev Make the lottery tickets untransferable
     * So that nobody makes a new address, buys myobu and then sends the tickets to another address
     * And then sells the myobu. And if he wins the lottery, it won't count it.
     *
     * While it could transfer the ticketsBought, that would make it so anyone can buy tickets, and
     * send to someone else. And then if the person that it was sent to wins from their
     * old lottery tickets, they wouldn't get the reward because not enough myobu to cover
     * the new tickets that they have been sent
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256
    ) internal pure override {
        /// @dev Only mint or burn is allowed
        require(
            from == address(0) || to == address(0),
            "FoF: Cannot transfer tickets"
        );
    }

    /**
     * @return The amount of myobu that someone needs to hold to buy lottery tickets
     * @param user: The address
     * @param amount: The amount of tickets
     */
    function myobuNeededForTickets(address user, uint256 amount)
        public
        view
        override
        returns (uint256)
    {
        uint256 minimumMyobuBalance = _lottery[_lotteryID.current()]
        .minimumMyobuBalance;
        uint256 myobuNeededForEachTicket = _lottery[_lotteryID.current()]
        .myobuNeededForEachTicket;
        uint256 ticketsBought_ = _ticketsBought[user][_lotteryID.current()];
        uint256 totalTickets = (ticketsBought_ + amount) - 1;
        uint256 _myobuNeededForTickets = totalTickets * myobuNeededForEachTicket;
        return minimumMyobuBalance + _myobuNeededForTickets;
    }

    /**
     * @dev Buys tickets with ETH, requires that he has at least (myobuNeededForTickets()) myobu,
     * and then loops over how much tickets he needs and mints the ERC721 tokens
     * If there is too much ETH sent, refund unneeded ETH
     * Emits TicketsBought()
     */
    function buyTickets() external payable override onlyOn {
        uint256 ticketPrice = _lottery[_lotteryID.current()].ticketPrice;
        uint256 amountOfTickets = msg.value / ticketPrice;
        require(amountOfTickets != 0, "FoF: Not enough ETH");
        require(
            _myobu.balanceOf(_msgSender()) >=
                myobuNeededForTickets(_msgSender(), amountOfTickets),
            "FoF: You don't have enough $MYOBU"
        );
        uint256 neededETH = amountOfTickets * ticketPrice;
        /// @dev Refund unneeded eth
        if (msg.value > neededETH) {
            transferOrWrapETH(_msgSender(), msg.value - neededETH);
        }
        uint256 tokenID_ = _tokenID;
        _tokenID += amountOfTickets;
        _ticketsBought[_msgSender()][_lotteryID.current()] += amountOfTickets;
        for (uint256 i = tokenID_; i < amountOfTickets + tokenID_; i++) {
            _mint(_msgSender(), i);
        }
        emit TicketsBought(_msgSender(), amountOfTickets, ticketPrice);
    }

    /**
     * @dev Function to calculate how much fees that will be taken
     * @return The amount of fees that will be taken
     * @param currentTokenID: The latest tokenID
     * @param ticketPrice: The price of 1 ticket
     * @param ticketFee: The percentage of the ticket to take as a fee
     * @param lastClaimedTokenID_: The last token ID that fees have been claimed for
     */
    function calculateFees(
        uint256 currentTokenID,
        uint256 ticketPrice,
        uint256 ticketFee,
        uint256 lastClaimedTokenID_
    ) public pure override returns (uint256) {
        uint256 unclaimedTicketSales = currentTokenID - lastClaimedTokenID_;
        return ((unclaimedTicketSales * ticketPrice) * ticketFee) / 10000;
    }

    /**
     * @return The amount of unclaimed fees, can be claimed using claimFees()
     */
    function unclaimedFees() public view override returns (uint256) {
        return
            calculateFees(
                _tokenID,
                _lottery[_lotteryID.current()].ticketPrice,
                _lottery[_lotteryID.current()].ticketFee,
                _lastClaimedTokenID
            );
    }

    /**
     * @return The amount of fees taken for the current lottery
     */
    function claimedFees() public view override returns (uint256) {
        return
            calculateFees(
                _lastClaimedTokenID,
                _lottery[_lotteryID.current()].ticketPrice,
                _lottery[_lotteryID.current()].ticketFee,
                _lottery[_lotteryID.current()].startingTokenID
            );
    }

    /**
     * @dev Function that claims fees, saves gas so that its doesn't happen per ticket buy.
     * Emits FeesClaimed()
     */
    function claimFees() public override {
        uint256 fee = unclaimedFees();
        _lastClaimedTokenID = _tokenID;
        transferOrWrapETH(_feeReceiver, fee);
        emit FeesClaimed(fee, _msgSender());
    }

    /**
     * @dev Function that distributes the reward, requests for randomness, completes at fulfillRandomness()
     * If nobody bought a ticket, makes rewardsClaimed true and returns nothing
     * Checks for _inClaimReward so that its not called more than once, wasting LINK.
     */
    function claimReward()
        external
        override
        onlyEnded
        returns (bytes32 requestId)
    {
        require(!_rewardClaimed, "FoF: Reward already claimed");
        require(!_inClaimReward, "FoF: Reward is being claimed");
        /// @dev So it doesn't fail if nobody bought any tickets
        if (_lottery[_lotteryID.current()].startingTokenID == _tokenID) {
            _rewardClaimed = true;
            return 0;
        }
        require(
            LINK.balanceOf(address(this)) >= _chainlinkFee,
            "FoF: Put some LINK into the contract"
        );
        _inClaimReward = true;
        return requestRandomness(_chainlinkKeyHash, _chainlinkFee);
    }

    /**
     * @dev Gets a winner and sends him the jackpot, if he doesn't have myobu at the time of winning
     * send the _feeReceiver the jackpot
     * Emits LotteryWon();
     */
    function fulfillRandomness(bytes32, uint256 randomness) internal override {
        /// @dev Get a random number in range of the token IDs
        uint256 x = _lottery[_lotteryID.current()].startingTokenID;
        uint256 y = _tokenID;
        /// @dev The winning token ID
        uint256 resultInRange = x + (randomness % (y - x));
        address winner = ownerOf(resultInRange);
        uint256 amountWon = jackpot();
        uint256 myobuNeeded = myobuNeededForTickets(winner, 0);
        if (_myobu.balanceOf(winner) < myobuNeeded) {
            /// @dev He sold his myobu, give the jackpot to the fee receiver and deduct based on the percentage to keep
            uint256 amountToKeepForNextLottery = (amountWon *
                _lottery[_lotteryID.current()]
                .percentageToKeepOnNotEnoughMyobu) / 10000;
            amountWon -= amountToKeepForNextLottery;
            winner = _feeReceiver;
        }
        transferOrWrapETH(winner, amountWon);
        _rewardClaimed = true;
        delete _inClaimReward;
        emit LotteryWon(winner, amountWon, resultInRange);
    }

    /**
     * @dev Starts a new lottery, Can only be done by the owner.
     * Emits LotteryCreated()
     * @param lotteryLength: How long the lottery will be in seconds
     * @param ticketPrice: The price of a ticket in ETH
     * @param ticketFee: The percentage of the ticket price that is sent to the fee receiver
     * @param percentageToKeepForNextLottery: The percentage that will be kept as reward for the lottery after
     * @param minimumMyobuBalance: The minimum amount of myobu someone needs to buy tickets or get the reward
     * @param myobuNeededForEachTicket: The amount of myobu that someone needs to hold for each ticket they buy
     * @param percentageToKeepOnNotEnoughMyobu: If someone doesn't have myobu at the time of winning, this will define the
     * percentage of the reward that will be kept in the contract for the next lottery
     */
    function createLottery(
        uint256 lotteryLength,
        uint256 ticketPrice,
        uint256 ticketFee,
        uint256 percentageToKeepForNextLottery,
        uint256 minimumMyobuBalance,
        uint256 myobuNeededForEachTicket,
        uint256 percentageToKeepOnNotEnoughMyobu
    ) external onlyOwner onlyEnded {
        /// @dev Cannot execute it now, must be executed seperately
        require(
            _rewardClaimed,
            "FoF: Claim the reward before starting a new lottery"
        );
        require(
            percentageToKeepForNextLottery + ticketFee < 10000,
            "FoF: You can not take everything or more as a fee"
        );
        require(
            lotteryLength <= 2629744,
            "FoF: Must be under or equal to 1 month"
        );
        /// @dev Check if fees haven't been claimed, if they haven't claim them
        if (unclaimedFees() != 0) {
            claimFees();
        }
        /// @dev For the new lottery
        _lotteryID.increment();
        uint256 newLotteryID = _lotteryID.current();
        _lottery[newLotteryID] = Lottery(
            _tokenID,
            block.timestamp,
            block.timestamp + lotteryLength,
            ticketPrice,
            ticketFee,
            minimumMyobuBalance,
            percentageToKeepForNextLottery,
            myobuNeededForEachTicket,
            percentageToKeepOnNotEnoughMyobu
        );
        delete _rewardClaimed;
        emit LotteryCreated(
            newLotteryID,
            lotteryLength,
            ticketPrice,
            ticketFee,
            minimumMyobuBalance,
            percentageToKeepForNextLottery,
            myobuNeededForEachTicket,
            percentageToKeepOnNotEnoughMyobu
        );
    }

    /**
     * @dev Returns the amount of tokens to keep for the next lottery
     */
    function toNextLottery() public view override returns (uint256) {
        uint256 percentageToKeepForNextLottery = _lottery[_lotteryID.current()]
        .percentageToKeepForNextLottery;
        uint256 totalFees = claimedFees();
        return
            ((address(this).balance + totalFees) *
                percentageToKeepForNextLottery) / 10000;
    }

    /**
     * @return The current jackpot
     * @dev Balance - The percentage for the next lottery - Unclaimed Fees
     */
    function jackpot() public view override returns (uint256) {
        uint256 balance = address(this).balance;
        uint256 _unclaimedFees = unclaimedFees();
        uint256 amountToKeepForNextLottery = toNextLottery();
        return balance - amountToKeepForNextLottery - _unclaimedFees;
    }

    /**
     * @dev Function so that anyone can contribute to the jackpot when there is a lottery ongoing
     */
    // solhint-disable-next-line
    receive() external payable onlyOn {}

    /// @dev Getter functions : Start

    /**
     * @return The Myobu Token
     */
    function myobu() external view override returns (IERC20) {
        return _myobu;
    }

    /**
     * @return The amount of link to pay for a VRF call
     */
    function chainlinkFee() external view override returns (uint256) {
        return _chainlinkFee;
    }

    /**
     * @return Where all the ticket fees will be sent to
     */
    function feeReceiver() external view override returns (address) {
        return _feeReceiver;
    }

    /**
     * @return The current lottery ID
     */
    function currentLotteryID() external view override returns (uint256) {
        return _lotteryID.current();
    }

    /**
     * @dev The current token ID
     */
    function tokenID() external view override returns (uint256) {
        return _tokenID;
    }

    /**
     * @return The info of a lottery (A struct)
     * See the Lottery struct for more info
     * @param lotteryID: The ID of the lottery to get info for
     */
    function lottery(uint256 lotteryID)
        external
        view
        override
        returns (Lottery memory)
    {
        return _lottery[lotteryID];
    }

    /**
     * @return Returns if the reward has been claimed, can only be viewed when there is no
     * lottery in progress or will return false.
     */
    function rewardClaimed() external view override onlyEnded returns (bool) {
        return _rewardClaimed;
    }

    /**
     * @return The last token ID fees have been claimed on for the current lottery
     */
    function lastClaimedTokenID() external view override returns (uint256) {
        return _lastClaimedTokenID;
    }

    /**
     * @return The amount of tickets someone bought
     * @param user: The address
     * @param lotteryID: The ID of the lottery
     */
    function ticketsBought(address user, uint256 lotteryID)
        external
        view
        override
        returns (uint256)
    {
        return _ticketsBought[user][lotteryID];
    }

    /// @dev Getter functions : End

    /**
     * @dev If there is unneeded LINK in the contract, the owner can recover them using this function
     */
    function recoverLINK(uint256 amount) external onlyOwner {
        LINK.transfer(_msgSender(), amount);
    }

    /// @dev Optional functions, commented out by default

    /**
     * @dev In case the Myobu token gets changed later on, the owner can call this to change it
     * @param newMyobu: The new myobu token contract
    function setMyobu(IERC20 newMyobu) external onlyOwner {
        _myobu = newMyobu;
    }
     */


    /**
     * @dev Sets the address that receives all the fees
     * @param newFeeReceiver: The new address that will recieve all the fees
    function setFeeReceiver(address newFeeReceiver) external onlyOwner {
        _feeReceiver = newFeeReceiver;
    }
     */

    /**
     * @dev Changes the chainlink VRF oracle fee in case it needs to be changed later on
     * @param newChainlinkFee: The new amount of LINK to pay for a VRF Oracle call
     */
    function setChainlinkFee(uint256 newChainlinkFee) external onlyOwner {
        _chainlinkFee = newChainlinkFee;
    }

    /**
     * @dev Extends the duration of the current lottery and checks if its the new duration is over 1 month, reverts if it is
     * @param extraTime: The time in seconds to extend it by
     */
    function extendCurrentLottery(uint256 extraTime) external onlyOwner onlyOn {
        uint256 currentLotteryEnd = _lottery[_lotteryID.current()].endTimestamp;
        uint256 currentLotteryStart = _lottery[_lotteryID.current()]
        .startTimestamp;
        require(
            currentLotteryEnd + extraTime <= currentLotteryStart + 2629744,
            "FoF: Must be under or equal to 1 month"
        );
        _lottery[_lotteryID.current()].endTimestamp += extraTime;
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

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IERC20.sol";
import "../Chainlink/interfaces/LinkTokenInterface.sol";

/**
 * @title Myobu Lottery Interface
 * @author Myobu Devs
 */
interface IFountainOfFortune {
    /**
     * @dev Event emmited when tickets are bought
     * @param buyer: The address of the buyer
     * @param amount: The amount of tickets bought
     * @param price: The price of each ticket
     * */
    event TicketsBought(address buyer, uint256 amount, uint256 price);

    /**
     * @dev Event emmited when fees are claimed
     * @param amountClaimed: The amount of fees claimed in ETH
     * @param claimer: The address that claimed the fees
     */
    event FeesClaimed(uint256 amountClaimed, address claimer);

    /**
     * @dev Event emmited when a lottery is created
     * @param lotteryID: The ID of the lottery created
     * @param lotteryLength: How long the lottery will be in seconds
     * @param ticketPrice: The price of a ticket in ETH
     * @param ticketFee: The percentage of the ticket price that is sent to the fee receiver
     * @param minimumMyobuBalance: The minimum amount of Myobu someone needs to buy tickets or get rewarded
     * @param percentageToKeepForNextLottery: The percentage that will be kept as reward for the next lottery
     * @param myobuNeededForEachTicket: The amount of myobu that someone needs to hold for each ticket they buy
     * @param percentageToKeepOnNotEnoughMyobu: If someone doesn't have myobu at the time of winning, this will define the 
     * percentage of the reward that will be kept in the contract for the next lottery
     */
    event LotteryCreated(
        uint256 lotteryID,
        uint256 lotteryLength,
        uint256 ticketPrice,
        uint256 ticketFee,
        uint256 minimumMyobuBalance,
        uint256 percentageToKeepForNextLottery,
        uint256 myobuNeededForEachTicket,
        uint256 percentageToKeepOnNotEnoughMyobu
    );

    /**
     * @dev Event emmited when the someone wins the lottery
     * @param winner: The address of the the lottery winner
     * @param amountWon: The amount of ETH won
     * @param tokenID: The winning tokenID
     */
    event LotteryWon(address winner, uint256 amountWon, uint256 tokenID);

    /**
     * @dev Event emitted when the lottery is extended
     * @param extendedBy: The amount of seconds the lottery is extended by
     */
    event LotteryExtended(uint256 extendedBy);

    /**
     * @dev Struct of a lottery
     * @param startingTokenID: The token ID that the lottery starts at
     * @param startTimestamp: A timestamp of when the lottery started
     * @param endTimestamp: A timestamp of when the lottery will end
     * @param ticketPrice: The price of a ticket in ETH
     * @param ticketFee: The percentage of ticket sales that go to the _feeReceiver
     * @param minimumMyobuBalance: The minimum amount of myobu you need to buy tickets
     * @param percentageToKeepForNextLottery: The percentage of the jackpot to keep for the next lottery
     * @param myobuNeededForEachTicket: The amount of myobu that someone needs to hold for each ticket they buy
     * @param percentageToKeepOnNotEnoughMyobu: If someone doesn't have myobu at the time of winning, this will define the 
     * percentage of the reward that will be kept in the contract for the next lottery
     */
    struct Lottery {
        uint256 startingTokenID;
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 ticketPrice;
        uint256 ticketFee;
        uint256 minimumMyobuBalance;
        uint256 percentageToKeepForNextLottery;
        uint256 myobuNeededForEachTicket;
        uint256 percentageToKeepOnNotEnoughMyobu;
    }

    /**
     * @dev Buys lottery tickets with ETH
     */
    function buyTickets() external payable;

    function ticketsBought(address user, uint256 lotteryID)
        external
        view
        returns (uint256);

    /**
     * @return The amount of unclaimed fees, can be claimed using claimFees()
     */
    function unclaimedFees() external view returns (uint256);

    /**
     * @return The amount of fees claimed for the current lottery
     */
    function claimedFees() external view returns (uint256);

    /**
     * @dev Function to calculate the fees that will be taken
     * @return The amount of fees that will be taken
     * @param currentTokenID: The latest tokenID
     * @param ticketPrice: The price of 1 ticket
     * @param ticketFee: The percentage of the ticket to take as a fee
     * @param lastClaimedTokenID_: The last token ID that fees have been claimed for
     */
    function calculateFees(
        uint256 currentTokenID,
        uint256 ticketPrice,
        uint256 ticketFee,
        uint256 lastClaimedTokenID_
    ) external pure returns (uint256);

    /**
     * @dev Function that claims fees and sends to _feeReceiver.
     */
    function claimFees() external;

    /**
     * @return The amount of myobu that someone needs to hold to buy lottery tickets
     * @param user: The address
     * @param amount: The amount of tickets
     */
    function myobuNeededForTickets(address user, uint256 amount)
        external
        view
        returns (uint256);

    /**
     * @dev Function that gets a random winner and sends the reward
     */
    function claimReward() external returns (bytes32 requestId);

    /**
     * @dev Returns the amount of tokens to keep for the next lottery
     */
    function toNextLottery() external view returns (uint256);

    /**
     * @return The current jackpot
     */
    function jackpot() external view returns (uint256);

    /**
     * @return The current token being used
     */
    function myobu() external view returns (IERC20);

    /**
     * @return The amount of link to pay
     */
    function chainlinkFee() external view returns (uint256);

    /**
     * @return Where all the ticket sale fees will be sent to
     */
    function feeReceiver() external view returns (address);

    /**
     * @return A counter of how much lotteries there have been, increases by 1 each new lottery.
     */
    function currentLotteryID() external view returns (uint256);

    /**
     * @return The current token ID
     */
    function tokenID() external view returns (uint256);

    /**
     * @return The info of a lottery (The Lottery Struct)
     */
    function lottery(uint256 lotteryID) external view returns (Lottery memory);

    /**
     * @return Returns if the reward has been claimed for the current lottery
     */
    function rewardClaimed() external view returns (bool);

    /**
     * @return The last tokenID that fees have been claimed on for the current lottery
     */
    function lastClaimedTokenID() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
/// @dev Same openzeppelin contract but imported ownable here
pragma solidity ^0.8.0;
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../Utils/Address.sol";
import "../../Utils/Ownable.sol";
import "../../Utils/Strings.sol";
import "../../Utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
abstract contract ERC721 is Ownable, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../Utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

