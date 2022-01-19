//"SPDX-License-Identifier: MIT"
pragma solidity ^0.6.12;
//Enable ABIEncoderV2 to use Structs as Function parameters solidity < 0.8
pragma experimental ABIEncoderV2;
// Imported OZ helper contracts
import "@openzeppelin/contracts/utils/Address.sol";
// Inherited allowing for ownership and tranfer ownership of contract
import "@openzeppelin/contracts/access/Ownable.sol";
// Interface for Lottery NFT to mint tokens
import "./interfaces/ILotteryNFT.sol";
// Allows for intergration with ChainLink VRF
import "./interfaces/IRandomGenerator.sol";

// Safe math
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./SafeMath16.sol";
import "./SafeMath8.sol";

import "./interfaces/IBEP20.sol";

contract LotteryMaster is Ownable {
    // Libraries
    // Safe math
    using SafeMath for uint256;
    using SafeMath16 for uint16;
    using SafeMath8 for uint8;
    // Address functionality
    using Address for address;

    IBEP20 internal payb_;
    
    ILotteryNFT internal nft_;
    // Storing of the randomness generator
    IRandomGenerator internal randomGenerator_;
    // Request ID for random number
    bytes32 internal requestId_;
    // Counter for lottery IDs
    uint256 private lotteryIdCounter_;

    // Max range of numbers of reopen lottery time
    uint16 private maxReopenLotteryTime_;
    uint16 public maxTicketPurchaseAllowed;
    //% buyback payb user can get 1%->100%;
    uint16 public rewardPoolShared_;
    uint16 public maxAddressBatchSend_;

    // Represents the status of the lottery
    enum Status {
        NotStarted, // The lottery has not started yet
        Open, // The lottery is open for ticket purchases
        Closed, // The lottery is no longer open for ticket purchases
        Completed, // The lottery has been closed and the numbers drawn
        Refund // The lottery is ready for refund user
    }
    // All the needed info around a lottery
    struct LotteryInfo {
        uint256 lotteryID; // ID for lotto
        uint256 nftID; // ID for nft
        uint256 paybNftPrice; // price of nft in payb at the time lottery is created
        uint256 ticketPricePerPayb; // how many ticket a nft can earn from
        uint256 expectedTicketsNum;
        uint256 startingTimestamp; // Block timestamp for star of lotto
        uint256 closingTimestamp; // Block timestamp for end of entries
        uint256 ticketCount;
        uint256 pricePool;
        Status lotteryStatus; // Status for lotto
        uint16 winningNumber; // The winning number
        uint16 openIndex; // open index
        address[] participants; // keep track of participants to refund
        address winner;
    }
    // address => lottery ID
    mapping(uint256 => mapping(address => bool)) public participants_;
    mapping(uint256 => mapping(address => bool)) public refunds_;
    //LotteryID => address => spend
    mapping(uint256 => mapping(address => uint256)) public userSpend_;
    //NFT ID => LotteryID
    mapping(uint256 => uint256) public nftLottery_;
    //NFTID => bool
    mapping(uint256 => bool) public nftLocker_;
    // Lottery ID's to info
    mapping(uint256 => LotteryInfo) public allLotteries_;
    

    //-------------------------------------------------------------------------
    // EVENTS
    //-------------------------------------------------------------------------

    event NewBatchMint(
        address indexed minter,
        uint256[] ticketIDs,
        uint256 totalCost
    );

    event RequestNumbers(uint256 lotteryId, bytes32 requestId);

    event UpdateMaxAddressBatchSend(address admin, uint8 maxAddressBatchSend);

    event UpdateMaxReopenLotteryTime(address admin, uint8 maxReopenLotteryTime);

    event UpdateMaxTicketPurchaseAllowed(address admin, uint8 maxTicketPurchaseAllowed);

    event UpdateRewardPoolShared(address admin, uint8 _rewardPoolShared);

    event LotteryOpen(uint256 lotteryId, uint256 ticketSupply);

    event LotteryClose(
        uint256 lotteryId,
        uint16 winningNumber,
        uint256 ticketSupply
    );

    event LotteryReopen(uint256 _lotteryId);
    
    event LotteryRefund(uint256 _lotteryId);

    event LotteryWinnerFound(uint256 lotteryID, address winner,uint256 tokenID, uint16 number);
    //-------------------------------------------------------------------------
    // MODIFIERS
    //-------------------------------------------------------------------------

    modifier onlyRandomGenerator() {
        require(
            msg.sender == address(randomGenerator_),
            "Only random generator"
        );
        _;
    }
    modifier notContract() {
        require(!address(msg.sender).isContract(), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
       _;
    }
    //-------------------------------------------------------------------------
    // CONSTRUCTOR
    //-------------------------------------------------------------------------

    constructor(address _payb_) public {
        maxReopenLotteryTime_ = 3;
        maxTicketPurchaseAllowed = 50;
        rewardPoolShared_ = 10;
        maxAddressBatchSend_ = 2000;
        require(_payb_ != address(0), "Address cannot be address 0");
        payb_ = IBEP20(_payb_);
    }

    function initialize(address _lotteryNFT, address _IRandomNumberGenerator)
        external
        onlyOwner
    {
        require(
            _lotteryNFT != address(0) && _IRandomNumberGenerator != address(0),
            "Contracts cannot be 0 address"
        );
        nft_ = ILotteryNFT(_lotteryNFT);
        randomGenerator_ = IRandomGenerator(_IRandomNumberGenerator);
    }

    //-------------------------------------------------------------------------
    // VIEW FUNCTIONS
    //-------------------------------------------------------------------------

    function totalLottery()
        external
        view
        returns(uint256)
    {
        return lotteryIdCounter_;
    }
    function ticketPrices(uint256 _lotteryId, uint256 _numberOfTickets)
        external
        view
        returns (uint256 totalCost)
    {
        uint256 pricePer = allLotteries_[_lotteryId].ticketPricePerPayb;
        totalCost = pricePer.mul(_numberOfTickets);
    }
    function isAllRefunded(uint256 _lotteryId)
        external
        view
        returns (bool)
    {
        address[] memory participants = allLotteries_[_lotteryId].participants;
        if(allLotteries_[_lotteryId].lotteryStatus == Status.Refund && participants.length > 0){
            for (uint256 i = 0; i < participants.length;i++){
                if(!refunds_[_lotteryId][participants[i]] ){
                    return false;
                }
            }
        }
        return true;
    }
    function getBasicLotteryInfo(uint256 _lotteryId)
        external
        view
        returns (LotteryInfo memory)
    {
        return (allLotteries_[_lotteryId]);
    }
    function getNewestLottery()
        external
        view
        returns (LotteryInfo memory)
    {
        return (allLotteries_[lotteryIdCounter_]);
    }
    function getNftLocks(uint256 nftID_)
        external
        view
        returns (bool)
    {
        return nftLocker_[nftID_];
    }
    function getnftLottery(uint256 nftID_)
        external
        view
        returns (uint256)
    {
        return nftLottery_[nftID_];
    }
    function getBuyBackPrice(uint256 lotteryID_)
        public 
        view
        returns (uint256)
    {
        return allLotteries_[lotteryID_].paybNftPrice
                .add(allLotteries_[lotteryID_].pricePool
                .mul(rewardPoolShared_).div(100));
    }
    //-------------------------------------------------------------------------
    // STATE MODIFYING FUNCTIONS
    //-------------------------------------------------------------------------

    function updateMaxReopenLotteryTime(uint8 _newSize) external onlyOwner {
        require(maxReopenLotteryTime_ != _newSize, "Cannot set to current");
        require(_newSize > 0, "maxReopenLotteryTime cannot be 0");
        maxReopenLotteryTime_ = _newSize;

        emit UpdateMaxReopenLotteryTime(msg.sender, _newSize);
    }
    function updateMaxTicketPurchaseAllowed(uint8 _newSize) external onlyOwner {
        require(maxTicketPurchaseAllowed != _newSize, "Cannot set to current");
        require(_newSize > 0, "maxTicketPurchaseAllowed cannot be 0");
        maxTicketPurchaseAllowed = _newSize;

        emit UpdateMaxTicketPurchaseAllowed(msg.sender, _newSize);
    }
    function updateRewardPoolShared(uint8 _newSize) external onlyOwner {
        require(rewardPoolShared_ != _newSize, "Cannot set to current");
        require(_newSize > 0, "rewardPoolShared_ cannot be 0");
        rewardPoolShared_ = _newSize;

        emit UpdateRewardPoolShared(msg.sender, _newSize);
    }
    function updateMaxAddressBatchSend(uint8 _newSize) external onlyOwner {
        require(maxAddressBatchSend_ != _newSize, "Cannot set to current");
        require(_newSize > 0, "maxAddressBatchSend cannot be 0");
        maxAddressBatchSend_ = _newSize;

        emit UpdateMaxAddressBatchSend(msg.sender, _newSize);
    }
    function buyBack(uint256 nftID) public{

        uint256 lID = nftLottery_[nftID];
        require(lotteryIdCounter_ == lID, "Buy back only for current lottery!");
        require(allLotteries_[lID].lotteryStatus == Status.Completed, "Cannot perform buy back!");
        require(allLotteries_[lID].nftID == nftID,"NFT not match!");
        require(!nftLocker_[nftID], "NFT locked!");
        require(participants_[lID][msg.sender],"Not a participants!");
        require(allLotteries_[lID].winner == msg.sender,"You are not the winner!");

        //buyBack price = 100% NFT price + rewardPoolShared_ (default 10%) price pool
        uint256 amount = allLotteries_[lID].paybNftPrice
                        .add(allLotteries_[lID].pricePool
                        .mul(rewardPoolShared_).div(100));

        nft_.safeTransferFrom(msg.sender, address(nft_), allLotteries_[lID].nftID, "");

        payb_.transfer(msg.sender, amount);
    }

    function processLottery(uint256 _lotteryId) external onlyOwner {
        // Checks that the lottery is past the closing block
        require(
            allLotteries_[_lotteryId].closingTimestamp <= block.timestamp,
            "Lottery exceed time"
        );

        // Checks lottery numbers have not already been drawn
        require(
            allLotteries_[_lotteryId].lotteryStatus == Status.Open,
            "Lottery State incorrect for process"
        );

        uint256 count = nft_.getTicketCountOfLottery(_lotteryId);

        //If user bought enough tickets
        if (count >= allLotteries_[_lotteryId].expectedTicketsNum) {
            // Sets lottery status to closed
            allLotteries_[_lotteryId].lotteryStatus = Status.Closed;
            // Requests a random number from the generator
            requestId_ = randomGenerator_.getRandomNumber(
                _lotteryId
            );
            // Emits that random number has been requested
            emit RequestNumbers(_lotteryId, requestId_);
        } else {
            // If not exceeds the max reopen time then start lottery again
            if (allLotteries_[_lotteryId].openIndex < maxReopenLotteryTime_) {
                uint256 span = allLotteries_[_lotteryId].closingTimestamp.sub(
                    allLotteries_[_lotteryId].startingTimestamp
                );
                require(span > 0, "Lottery config invalid");
                allLotteries_[_lotteryId].startingTimestamp = block.timestamp;
                allLotteries_[_lotteryId].closingTimestamp = block
                    .timestamp
                    .add(span);
                allLotteries_[_lotteryId].lotteryStatus = Status.Open;
                allLotteries_[_lotteryId].openIndex = allLotteries_[_lotteryId]
                    .openIndex
                    .add(1);
                emit LotteryReopen(_lotteryId);
            }
            //Exceeds so do the refund
            else {
                allLotteries_[_lotteryId].lotteryStatus = Status.Refund;
                unlockNft(allLotteries_[_lotteryId].nftID);
                emit LotteryRefund(_lotteryId);
            }
        }
    }

    function batchRefundUsers(uint256 lotteryID_) public onlyOwner {

        require(allLotteries_[lotteryID_].lotteryStatus == Status.Refund, "Lottery is not ready for refund!");

        require(allLotteries_[lotteryID_].participants.length > 0, "No participants");

        address[] memory participants = allLotteries_[lotteryID_].participants;

        uint256 currentExecutionTime = 0;
        for (uint256 i = 0; i < participants.length;i++){
            address user_ = participants[i];
            //If exceed maxAddressBatchSend, end this transaction and process another batchRefundUsers to continue refund the rest
            if(!refunds_[lotteryID_][user_] && currentExecutionTime <= maxAddressBatchSend_){

                // payb_ updates it's balance cost more gas
                refunds_[lotteryID_][user_] = payb_.transfer(user_, userSpend_[lotteryID_][user_]);
                
                currentExecutionTime += 1;
            }
        }
        
     }

    function numbersDrawn(
        uint256 _lotteryId,
        bytes32 _requestId,
        uint256 _randomNumber
    ) external onlyRandomGenerator {
        require(
            allLotteries_[_lotteryId].lotteryStatus == Status.Closed,
            "Draw numbers first"
        );

        if (requestId_ == _requestId) {
            uint256 count = nft_.getTicketCountOfLottery(_lotteryId);
            allLotteries_[_lotteryId].lotteryStatus = Status.Completed;
            allLotteries_[_lotteryId].winningNumber = _processRandom(
                _randomNumber,
                count
            );
        }

        emit LotteryClose(
            _lotteryId,
            allLotteries_[_lotteryId].winningNumber,
            nft_.getTotalSupply()
        );
    }

    /**
     * @param   _startingTimestamp The block timestamp for the beginning of the
     *          lottery.
     * @param   _closingTimestamp The block timestamp after which no more tickets
     *          will be sold for the lottery. Note that this timestamp MUST
     *          be after the starting block timestamp.
     */
    function createNewLottery(
        uint256 _nftID,
        uint256 _paybNftPrice,
        uint256 _costPerTicket,
        uint256 _expectedTicketNum,
        uint256 _startingTimestamp,
        uint256 _closingTimestamp
    ) external onlyOwner returns (uint256 lotteryId) {
        // Incrementing lottery ID
        require(
            _costPerTicket != 0,
            "Cost cannot be 0"
        );
        require(
            _startingTimestamp != 0 &&
            _startingTimestamp < _closingTimestamp &&
            _closingTimestamp >= block.timestamp,
            "Timestamps for lottery invalid"
        );
        require(
            _expectedTicketNum != 0,
            "Expected ticket cannot be 0"
        );
        require(
            _paybNftPrice != 0,
            "NFT price in payb cannot be 0"
        );
        require(nft_.ownerOf(_nftID) == address(nft_), "Lottery does not own the NFT");
        

        lotteryIdCounter_ = lotteryIdCounter_.add(1);
        lotteryId = lotteryIdCounter_;

        require(!nftLocker_[_nftID], "NFT is being used and locked");

        Status lotteryStatus;
        if (_startingTimestamp >= block.timestamp) {
            lotteryStatus = Status.NotStarted;
        }
        lotteryStatus = Status.Open;
        // Saving data in struct
        LotteryInfo memory newLottery = LotteryInfo(
            lotteryId,
            _nftID,
            _paybNftPrice,
            _costPerTicket,
            _expectedTicketNum,
            _startingTimestamp,
            _closingTimestamp,
            0,
            0,
            lotteryStatus,
            0,
            1,
            new address[](0),
            address(0)
        );
        allLotteries_[lotteryId] = newLottery;
        //keep track nft in lottery
        nftLottery_[_nftID] = lotteryId;
        //lock NFT
        lockNft(_nftID);
        // Emitting important information around new lottery.
        emit LotteryOpen(lotteryId, nft_.getTotalSupply());
    }
    function lockNft(uint256 tokenID) internal{
        nftLocker_[tokenID] = true;
    }
    function unlockNft(uint256 tokenID) internal{
        nftLocker_[tokenID]= false;
    }
    function emergencyUnlockNft(uint256 tokenID) public onlyOwner{
        unlockNft(tokenID);
    }
    function withdrawToken(uint256 _amount, address recipient) external onlyOwner {
        require(recipient != address(0),"Recipient cannot be address(0)");
        require(payb_.balanceOf(address(this)) > _amount,"Not enough Payb");
        payb_.transfer(recipient, _amount);
    }

    //-------------------------------------------------------------------------
    // General Access Functions

    function batchBuyLotteryTicket(uint256 _lotteryId, uint8 _numberOfTickets)
        external
        notContract()
    {
        // Ensuring the lottery is within a valid time
        require(
            block.timestamp >= allLotteries_[_lotteryId].startingTimestamp,
            "Invalid time for mint:start"
        );
        require(
            block.timestamp < allLotteries_[_lotteryId].closingTimestamp,
            "Invalid time for mint:end"
        );
        if (allLotteries_[_lotteryId].lotteryStatus == Status.NotStarted) {
            if (allLotteries_[_lotteryId].startingTimestamp <= block.timestamp) {
                allLotteries_[_lotteryId].lotteryStatus = Status.Open;
            }
        }
        require(
            allLotteries_[_lotteryId].lotteryStatus == Status.Open,
            "Lottery not in state for mint"
        );
        require(_numberOfTickets <= maxTicketPurchaseAllowed, "Batch mint too large");

        // Getting the cost for the token purchase
        uint256 totalCost = this.ticketPrices(_lotteryId, _numberOfTickets);
        // Transfers the required payb_ to this contract

        payb_.transferFrom(msg.sender, address(this), totalCost);

        userSpend_[_lotteryId][msg.sender] = userSpend_[_lotteryId][msg.sender].add(totalCost);

        allLotteries_[_lotteryId].pricePool = allLotteries_[_lotteryId]
            .pricePool
            .add(totalCost);
        allLotteries_[_lotteryId].ticketCount += _numberOfTickets;
        // Batch mints the user their tickets
        uint256[] memory ticketIds = nft_.batchMint(
            msg.sender,
            _lotteryId,
            _numberOfTickets
        );
        if (!participants_[_lotteryId][msg.sender]) {
            allLotteries_[_lotteryId].participants.push(msg.sender);
            participants_[_lotteryId][msg.sender] = true;
        }

        // Emitting event with all information
        emit NewBatchMint(msg.sender, ticketIds, totalCost);
    }

    function claimReward(
        uint256 _lotteryId,
        uint256 _ticketId
    ) 
    external
    notContract()
     {
        // Checking the lottery is in a valid time for claiming
        require(
            allLotteries_[_lotteryId].closingTimestamp <= block.timestamp,
            "Wait till end to claim"
        );

        // Checks the lottery winning numbers are available
        require(
            allLotteries_[_lotteryId].lotteryStatus == Status.Completed,
            "Winning Numbers not chosen yet or lottery is being refunded"
        );
        require(
            nft_.getOwnerOfTicket(_ticketId) == msg.sender,
            "Only the owner can claim"
        );
        // Sets the claim of the ticket to true (if claimed, will revert)
        require(
            nft_.claimTicket(_ticketId, _lotteryId),
            "Numbers for ticket invalid"
        );
        address winner = nft_.ntfHarvestSingle(
            allLotteries_[_lotteryId].winningNumber,
            _lotteryId,
            _ticketId,
            allLotteries_[_lotteryId].nftID,
            msg.sender
        );
        if(winner != address(0) && winner == msg.sender){
            allLotteries_[_lotteryId].winner = msg.sender;
             unlockNft(allLotteries_[_lotteryId].nftID);
        }
    }
    
    function batchClaimRewards(uint256 _lotteryId, uint256[] calldata _ticketIds)
        external
        notContract()
    {
        require(_ticketIds.length <= maxTicketPurchaseAllowed, "Batch claim too large");
        // Checking the lottery is in a valid time for claiming
        require(
            allLotteries_[_lotteryId].closingTimestamp <= block.timestamp,
            "Wait till end to claim"
        );
        // Checks the lottery winning numbers are available
        require(
            allLotteries_[_lotteryId].lotteryStatus == Status.Completed,
            "Winning Numbers not chosen yet"
        );
        // Creates a storage for all winnings
        // Loops through each submitted token
        for (uint256 i = 0; i < _ticketIds.length; i++) {
            // Checks user is owner (will revert entire call if not)
            require(
                nft_.getOwnerOfTicket(_ticketIds[i]) == msg.sender,
                "Only the owner can claim"
            );
            // If token has already been claimed, skip token
            if (nft_.getTicketClaimStatus(_ticketIds[i])) {
                continue;
            }
            // Claims the ticket (will only revert if numbers invalid)
            require(
                nft_.claimTicket(_ticketIds[i], _lotteryId),
                "Numbers for ticket invalid"
            );

            address winner = nft_.ntfHarvestSingle(
                allLotteries_[_lotteryId].winningNumber,
                _lotteryId,
                _ticketIds[i],
                allLotteries_[_lotteryId].nftID,
                msg.sender
            );
             
            if(winner != address(0) && winner == msg.sender){
                allLotteries_[_lotteryId].winner = msg.sender;
                unlockNft(allLotteries_[_lotteryId].nftID);
                emit LotteryWinnerFound(_lotteryId,winner,allLotteries_[_lotteryId].nftID,allLotteries_[_lotteryId].winningNumber);
            }
        }
    }

    //-------------------------------------------------------------------------
    // INTERNAL FUNCTIONS
    //-------------------------------------------------------------------------

    function _getNumberOfMatching(
        uint16[] memory _usersNumbers,
        uint16[] memory _winningNumbers
    ) internal pure returns (uint8 noOfMatching) {
        // Loops through all winning numbers
        for (uint256 i = 0; i < _winningNumbers.length; i++) {
            // If the winning numbers and user numbers match
            if (_usersNumbers[i] == _winningNumbers[i]) {
                // The number of matching numbers increases
                noOfMatching += 1;
            }
        }
    }

    function _processRandom(uint256 _randomNumber, uint256 currentTicketCount)
        internal
        pure
        returns (uint16)
    {
        bytes32 hashOfRandom = keccak256(abi.encodePacked(_randomNumber));
        // Casts random number hash into uint256
        uint256 numberRepresentation = uint256(hashOfRandom);
        // Sets the winning number position to a uint16 of random hash number
        return uint16(numberRepresentation.mod(currentTicketCount));
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

//"SPDX-License-Identifier: MIT"
pragma solidity ^0.6.12;

interface ILotteryNFT {

    //-------------------------------------------------------------------------
    // VIEW FUNCTIONS
    //-------------------------------------------------------------------------

    function getTotalSupply() external view returns(uint256);
    function balanceOf(address owner, uint256 tokenID) external view returns(uint256);
    function ownerOf(uint256 tokenId) external view returns(address);

    function getTicketCountOfLottery(uint256 _lotteryID) external view returns(uint256);
    function getTokenPrice(uint256 token) external view returns(uint256);


    function getUserTickets(
        uint256 _lotteryID,
        address _user
    ) 
        external 
        view 
        returns(uint256[] memory);

    function getTicketNumbers(
        uint256 _ticketID
    ) 
        external 
        view 
        returns(uint16[] memory);

    function getOwnerOfTicket(
        uint256 _ticketID
    ) 
        external 
        view 
        returns(address);

    function getTicketClaimStatus(
        uint256 _ticketID
    ) 
        external 
        view
        returns(bool);

    

    //-------------------------------------------------------------------------
    // STATE MODIFYING FUNCTIONS 
    //-------------------------------------------------------------------------
    // batch mint more than 1 token
    function batchMint(
        address _to,
        uint256 _lottoID,
        uint8 _numberOfTickets
    )
        external
        returns(uint256[] memory);

    function ntfHarvestSingle(
        uint16 _winningNumber,
        uint256 _lotteryId,
        uint256 _ticketId,
        uint256 _nftID,
        address harvester
    ) external returns(address);
    
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external ;

    function claimTicket(uint256 _ticketId, uint256 _lotteryId) external returns(bool);
    
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) external;

}

//"SPDX-License-Identifier: MIT"
pragma solidity ^0.6.12;

interface IRandomGenerator {
    function getRandomNumber(
        uint256 lotteryId
    ) 
        external 
        returns (bytes32 requestId);
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
pragma solidity ^0.6.12;

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
 *
 * This library is a version of Open Zeppelin's SafeMath, modified to support
 * unsigned 32 bit integers.
 */
library SafeMath16 {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(uint16 a, uint16 b) internal pure returns (uint16) {
    uint16 c = a + b;
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
  function sub(uint16 a, uint16 b) internal pure returns (uint16) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint16 c = a - b;

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
  function mul(uint16 a, uint16 b) internal pure returns (uint16) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint16 c = a * b;
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
  function div(uint16 a, uint16 b) internal pure returns (uint16) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint16 c = a / b;
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
  function mod(uint16 a, uint16 b) internal pure returns (uint16) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

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
 *
 * This library is a version of Open Zeppelin's SafeMath, modified to support
 * unsigned 32 bit integers.
 */
library SafeMath8 {
  /**
    * @dev Returns the addition of two unsigned integers, reverting on
    * overflow.
    *
    * Counterpart to Solidity's `+` operator.
    *
    * Requirements:
    * - Addition cannot overflow.
    */
  function add(uint8 a, uint8 b) internal pure returns (uint8) {
    uint8 c = a + b;
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
  function sub(uint8 a, uint8 b) internal pure returns (uint8) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint8 c = a - b;

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
  function mul(uint8 a, uint8 b) internal pure returns (uint8) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint8 c = a * b;
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
  function div(uint8 a, uint8 b) internal pure returns (uint8) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath: division by zero");
    uint8 c = a / b;
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
  function mod(uint8 a, uint8 b) internal pure returns (uint8) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

//"SPDX-License-Identifier: MIT"
pragma solidity ^0.6.12;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
    * @dev Returns the token name.
    */
    function name() external view returns (string memory);

    /**
    * @dev Returns the bep token owner.
    */
    function getOwner() external view returns (address);

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