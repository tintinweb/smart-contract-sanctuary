/**
 *Submitted for verification at BscScan.com on 2022-01-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma abicoder v2;

/** 
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 */
abstract contract Context {

    // Empty constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to contract functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract, setting the deployer as the initial owner.
     */
    constructor() {
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
        require(owner() == _msgSender(), "Ownable: Caller is not the owner");
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
        _owner = address(0);
        emit OwnershipTransferred(_owner, address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: New owner is the zero address");
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
    }
}


abstract contract RoundTimers is Ownable {
    uint256 private timeBetweenRounds = 2 hours;
    uint256 private timeUntilWinnerIsChosen = 5 minutes;

    uint256 public constant MIN_TIME_BETWEEN_ROUNDS = 1 hours;
    uint256 public constant MAX_TIME_BETWEEN_ROUNDS = 7 days;
    uint256 public constant MIN_TIME_UNTIL_WINNER_IS_CHOSEN = 5 minutes;
    uint256 public constant MAX_TIME_UNTIL_WINNER_IS_CHOSEN = 30 minutes;

    event TimersUpdated(uint256 timeBetweenRounds, uint256 timeUntilWinnerIsChosen);

    constructor() {}

    /**
     * @notice Get the time between rounds and time until winner is chosen in seconds
     */
    function getTimersForRound() public view virtual returns (uint256, uint256)  {
        return (timeBetweenRounds, timeUntilWinnerIsChosen);
    }

    /**
     * @notice Set time between rounds (when a new round can start after one just became claimable)
     * @dev Only callable by owner
     * @param _timeBetweenRounds: time between rounds
     */
    function setTimersForRound(uint256 _timeBetweenRounds, uint256 _timeUntilWinnerIsChosen) public virtual onlyOwner
    {
        require(
            _timeBetweenRounds >= MIN_TIME_BETWEEN_ROUNDS,
            "PottoPrizeDraw: timeBetweenRounds must be higher than MIN_TIME_BETWEEN_ROUNDS"
        );
        require(
            _timeBetweenRounds <= MAX_TIME_BETWEEN_ROUNDS,
            "PottoPrizeDraw: timeBetweenRounds must be lower than MAX_TIME_BETWEEN_ROUNDS"
        );
        require(
            _timeUntilWinnerIsChosen >= MIN_TIME_UNTIL_WINNER_IS_CHOSEN,
            "PottoPrizeDraw: timeUntilWinnerIsChosen must be higher than MIN_TIME_UNTIL_WINNER_IS_CHOSEN"
        );
        require(
            _timeUntilWinnerIsChosen <= MAX_TIME_UNTIL_WINNER_IS_CHOSEN,
            "PottoPrizeDraw: timeUntilWinnerIsChosen must be lower than MAX_TIME_UNTIL_WINNER_IS_CHOSEN"
        );

        timeBetweenRounds = _timeBetweenRounds;
        timeUntilWinnerIsChosen = _timeUntilWinnerIsChosen;

        emit TimersUpdated(timeBetweenRounds, timeUntilWinnerIsChosen);
    }
}

interface IRandomNumberGenerator {
    /**
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber(uint256 _seed) external;

    /**
     * View latest round Id
     */
    function viewLatestRoundId() external view returns (uint256);

    /**
     * View random result generated
     */
    function viewRandomResult() external view returns (uint32);
}


interface PottoPrizeDraw {
    /**
     * @notice Get current round id
     */
    function getCurrentRoundId() external view returns (uint256);

    /**
     * @notice Get prize draw jackpot = contract balance
     */
    function getPrizeDrawJackpot() external view returns (uint256);

    /**
     * @notice Set upper/lower price limit for tickets
     * @dev Only callable by owner
     * @param _minPriceTicket: minimum price of a ticket
     * @param _maxPriceTicket: maximum price of a ticket
     */
    function setMinAndMaxTicketPrice(uint256 _minPriceTicket, uint256 _maxPriceTicket) external;

    /**
     * @notice Set operator, treasury, and injector addresses
     * @dev Only callable by owner
     * @param _operatorAddress: address of the operator
     * @param _treasuryAddress: address of the treasury
     * @param _injectorAddress: address of the injector
     */
    function setOperatorAndTreasuryAndInjectorAddresses(
        address _operatorAddress,
        address _treasuryAddress,
        address _injectorAddress
    ) external;

    /**
     * @notice Start a new prize draw round
     * @dev Only callable by owner
     * @param _endTime: timestamp when the round should finish
     * @param _ticketPrice: the price of a ticket in wei
     * @param _treasuryFee: treasury fee percentage (10,000 = 100%, 2,000 = 20%, 100 = 1%)
     */
    function startNewRound(
        uint256 _endTime,
        uint256 _ticketPrice,
        uint256 _treasuryFee
    ) external;

    /**
     * @notice Close a draw round for a given round id
     * @dev Only callable by owner
     * @param _roundId: round id
     */
    function closeRound(uint256 _roundId) external;

    /**
     * @notice Make a round claimable, draw the winning number for round & send treasuryFee tax to treasury address
     * @dev Only callable by owner
     * @param _roundId: round id
     */
    function makeRoundClaimable(uint256 _roundId) external payable;

    /**
     * @notice Purchase tickets for a given opened round
     * @param _roundId: round id
     * @param _ticketNumbers: array of ticket numbers chosen by user
     */
    function buyTickets(uint256 _roundId, uint32[] calldata _ticketNumbers) external payable;

    /**
     * @notice Claim the reward for your purchased tickets if user purchased winning ticket
     * @param _roundId: round id
     * @param _ticketIds: array of ticket ids to check if they have the winning combination
     */
    function claimTickets(uint256 _roundId, uint256[] calldata _ticketIds) external payable;

    /**
     * @notice View ticket statuses and numbers for a given array of ticket ids
     * @dev Only callable by owner
     * @param _ticketIds: array of ticket ids
     */
    function viewNumbersAndStatusesForTicketIds(uint256[] calldata _ticketIds) external view returns (uint32[] memory, bool[] memory);

    /**
     * @notice Calculate total price for a number of tickets to be purchased
     * @param _ticketPrice: price of a ticket
     * @param _numberOfTickets: number of tickets to purchase
     */
    function calculateTotalPriceForMultipleTickets(
        uint256 _ticketPrice,
        uint256 _numberOfTickets
    ) external pure returns (uint256);

    /**
     * @notice Transfer funds out of the contract into a different prize draw contract
     * @param _targetAddress: address towards to send the contract balance
     */
    function transferJackpotToDifferentContract(address _targetAddress) external payable;

    /**
     * @notice Inject funds into a round
     * @dev Only callable by owner
     * @param _roundId: round id
     * @param _amountToInject: amount to inject
     */
    function injectFunds(uint256 _roundId, uint256 _amountToInject) external payable;

    /**
     * @notice Change the random generator
     * @dev The calls to functions are used to verify the new generator implements them properly.
     * It is necessary to wait for the VRF response before starting a round.
     * Callable only by the contract owner
     * @param _randomGeneratorAddress: address of the random generator
     */
    function changeRandomGenerator(address _randomGeneratorAddress) external;
}


contract PottoPrizeDrawBNB is PottoPrizeDraw, Ownable, RoundTimers {

    // ***** Variable declarations *****
    IRandomNumberGenerator public randomGenerator;

    address public operatorAddress;
    address public treasuryAddress;
    address public injectorAddress;
    
    uint256 public currentRoundId;
    uint256 public currentTicketId;

    uint256 public maxPriceTicket = 5 ether;
    uint256 public minPriceTicket = 0.0005 ether;
    uint256 public maxNrOfPurchasableOrClaimableTickets = 100;

    uint256 public constant MIN_LENGTH_ROUND = 0.1 hours - 5 minutes; // 5 minutes
    uint256 public constant MAX_LENGTH_ROUND = 7 days + 5 minutes; // 7 days
    uint256 public constant MAX_TREASURY_FEE = 2000; // 20%

    // ***** Enum declarations *****
    enum Status {
        Open,
        Close,
        Claimable
    }

    // ***** Struct + mapping declarations *****
    struct DrawRound {
        Status status;
        uint256 startTime;
        uint256 endTime;
        uint256 ticketPrice;
        uint256 jackpot;
        uint256 roundId;
        uint256 timeWhenRoundBecameClaimable;
        uint256 treasuryFee;
        uint256 firstTicketIdThisRound;
        uint256 firstTicketIdNextRound;
        uint256 amountCollected;
        uint32 winningNumber;
    }

    struct Ticket {
        uint256 ticketId;
        uint32 number;
        address owner;
        uint256 purchaseTime;
        uint256 roundId;
        bool claimed;
    }

    DrawRound[] roundsHistory;

    mapping(uint256 => DrawRound) private _drawRounds;
    mapping(uint256 => Ticket) private _tickets;

    // Tickets purchase history per user address
    mapping(address => uint256[]) private _purchaseHistory;

    // ***** Modifier declarations *****
    modifier onlyOwnerOrInjector() {
        require((msg.sender == owner()) || (msg.sender == injectorAddress), "PottoPrizeDraw: Caller not the owner or injector");
        _;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "PottoPrizeDraw: Contract addresses not allowed");
        require(msg.sender == tx.origin, "PottoPrizeDraw: Proxy contract addresses not allowed");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operatorAddress, "PottoPrizeDraw: Caller not the operator");
        _;
    }

    // ***** Event declarations *****
    event NewRandomGenerator(address indexed randomGenerator);
    event TicketsPurchased(address indexed buyerAddress, uint256 indexed roundId, uint256 numberOfTickets, uint256 purchaseTime, uint32[] ticketNumbers);
    event RoundClosed(uint256 indexed roundId, uint256 firstTicketIdNextRound);
    event RoundInjection(uint256 indexed roundId, uint256 injectedAmount);
    event RoundOpened(
        uint256 indexed roundId,
        uint256 startTime,
        uint256 endTime,
        uint256 ticketPrice,
        uint256 firstTicketIdThisRound
    );
    event TicketsClaimed(address indexed claimerAddress, bool isWinner, uint256 amountRewarded, uint256 indexed roundId, uint256 numberOfTickets);
    event RoundBecameClaimable(uint256 indexed roundId, uint256 winningNumber);
    event NewOperatorAndTreasuryAndInjectorAddresses(address operator, address treasury, address injector);

    /**
     * @notice ***** Constructor *****
     * @dev RandomNumberGenerator must be deployed prior to this contract
     * @param _randomGeneratorAddress: address of the RandomGenerator contract used to work with ChainLink VRF
     */
    constructor(address _randomGeneratorAddress) {
        randomGenerator = IRandomNumberGenerator(_randomGeneratorAddress);
    }

    // ***** Getter methods *****
    /**
     * @notice Get current round id
     */
    function getCurrentRoundId() external view override returns (uint256)  {
        return currentRoundId;
    }

    /**
     * @notice Get current round information
     */
    function getCurrentRoundDetails() external notContract view returns (DrawRound memory)  {
        return _drawRounds[currentRoundId];
    }

    /**
     * @notice Get details of the round with id equal to given roundId
     * @param _roundId: id of round
     */
    function getDetailsForRoundWithId(uint256 _roundId) external notContract view returns (DrawRound memory)  {
        return _drawRounds[_roundId];
    }

    /**
     * @notice Get prize draw jackpot = contract balance
     */
    function getPrizeDrawJackpot() external override notContract view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Get prize draw rounds history
     */
    function getRoundsHistory() external notContract view returns (DrawRound[] memory) {
        return roundsHistory;
    }

    // ***** Setter methods *****
    /**
     * @notice Set upper/lower price limit for tickets
     * @dev Only callable by owner
     * @param _minPriceTicket: minimum price of a ticket
     * @param _maxPriceTicket: maximum price of a ticket
     */
    function setMinAndMaxTicketPrice(uint256 _minPriceTicket, uint256 _maxPriceTicket)
        external
        override
        onlyOwner
    {
        require(_minPriceTicket <= _maxPriceTicket, "PottoPrizeDraw: _minPriceTicket must be <= _maxPriceTicket");

        minPriceTicket = _minPriceTicket;
        maxPriceTicket = _maxPriceTicket;
    }

    /**
     * @notice Set operator, treasury, and injector addresses
     * @dev Only callable by owner
     * @param _operatorAddress: address of the operator
     * @param _treasuryAddress: address of the treasury
     * @param _injectorAddress: address of the injector
     */
    function setOperatorAndTreasuryAndInjectorAddresses(
        address _operatorAddress,
        address _treasuryAddress,
        address _injectorAddress
    ) external override onlyOwner {
        require(_operatorAddress != address(0), "PottoPrizeDraw: _operatorAddress cannot be zero address");
        require(_treasuryAddress != address(0), "PottoPrizeDraw: _treasuryAddress cannot be zero address");
        require(_injectorAddress != address(0), "PottoPrizeDraw: _injectorAddress cannot be zero address");

        operatorAddress = _operatorAddress;
        treasuryAddress = _treasuryAddress;
        injectorAddress = _injectorAddress;

        emit NewOperatorAndTreasuryAndInjectorAddresses(_operatorAddress, _treasuryAddress, _injectorAddress);
    }

    // ***** Round specific methods *****
    /**
     * @notice Start a new prize draw round
     * @dev Only callable by owner
     * @param _endTime: timestamp when the round should finish
     * @param _ticketPrice: the price of a ticket in wei
     * @param _treasuryFee: treasury fee percentage (10,000 = 100%, 2,000 = 20%, 100 = 1%)
     */
    function startNewRound(
        uint256 _endTime,
        uint256 _ticketPrice,
        uint256 _treasuryFee
    ) external override onlyOperator {
        require(
            (currentRoundId == 0) || (_drawRounds[currentRoundId].status == Status.Claimable),
            "PottoPrizeDraw: Not the time to start a new round"
        );

        require(
            ((_endTime - block.timestamp) >= MIN_LENGTH_ROUND) && ((_endTime - block.timestamp) <= MAX_LENGTH_ROUND),
            "PottoPrizeDraw: Round length is outside of allowed range"
        );

        require(
            (_ticketPrice >= minPriceTicket) && (_ticketPrice <= maxPriceTicket),
            "PottoPrizeDraw: Tickets price is outside of allowed range"
        );

        require(_treasuryFee <= MAX_TREASURY_FEE, "PottoPrizeDraw: Treasury fee is too high");

        currentRoundId++;

        _drawRounds[currentRoundId] = DrawRound({
            status: Status.Open,
            roundId: currentRoundId,
            startTime: block.timestamp,
            endTime: _endTime,
            ticketPrice: _ticketPrice,
            timeWhenRoundBecameClaimable: _endTime,
            jackpot: address(this).balance,
            treasuryFee: _treasuryFee,
            firstTicketIdThisRound: currentTicketId,
            firstTicketIdNextRound: currentTicketId,
            amountCollected: 0,
            winningNumber: 0
        });

        emit RoundOpened(
            currentRoundId,
            block.timestamp,
            _endTime,
            _ticketPrice,
            currentTicketId
        );
    }

    /**
     * @notice Close a draw round for a given round id
     * @dev Only callable by owner
     * @param _roundId: round id
     */
    function closeRound(uint256 _roundId) external override onlyOperator {
        require(_drawRounds[_roundId].status == Status.Open, "PottoPrizeDraw: Round with given id is not started");
        require(block.timestamp >= _drawRounds[_roundId].endTime, "PottoPrizeDraw: Round with given id has not finished yet");

        _drawRounds[_roundId].firstTicketIdNextRound = currentTicketId;
        _drawRounds[_roundId].status = Status.Close;
        _drawRounds[_roundId].jackpot = address(this).balance;

        // Request a random number from the generator based on a seed
        randomGenerator.getRandomNumber(uint256(keccak256(abi.encodePacked(_roundId, currentTicketId))));

        emit RoundClosed(_roundId, currentTicketId);
    }

    /**
     * @notice Make a round claimable, draw the winning number for round & send treasuryFee tax to treasury address
     * @dev Only callable by owner
     * @param _roundId: round id
     */
    function makeRoundClaimable(uint256 _roundId) external override payable onlyOperator {
        require(_drawRounds[_roundId].status == Status.Close, "PottoPrizeDraw: Round with given id has not closed yet");
        require(_roundId == randomGenerator.viewLatestRoundId(), "PottoPrizeDraw: Winning number not drawn yet");

        // Get the winning number based on the randomResult generated by ChainLink's fallback
        uint32 winningNumber = randomGenerator.viewRandomResult();

        _drawRounds[_roundId].winningNumber = winningNumber;
        _drawRounds[_roundId].status = Status.Claimable;
        _drawRounds[_roundId].timeWhenRoundBecameClaimable = block.timestamp;
        _drawRounds[_roundId].jackpot = address(this).balance;

        roundsHistory.push(_drawRounds[_roundId]);

        // Calculate the amount to share after treasury fee was substracted
        uint256 amountToShareToWinner = (
            ((_drawRounds[_roundId].amountCollected) * (10000 - _drawRounds[_roundId].treasuryFee))
        ) / 10000;

        // Calculate the amount to withdraw to treasury
        uint256 amountToWithdrawToTreasury = (_drawRounds[_roundId].amountCollected - amountToShareToWinner);

        // Transfer amount to withdraw to treasury address
        payable(treasuryAddress).transfer(amountToWithdrawToTreasury);

        emit RoundBecameClaimable(currentRoundId, winningNumber);
    }

    // ***** Tickets specific methods *****
    /**
     * @notice Purchase tickets for a given opened round
     * @param _roundId: round id
     * @param _ticketNumbers: array of ticket numbers chosen by user
     */
    function buyTickets(uint256 _roundId, uint32[] calldata _ticketNumbers) public override payable {
        require(_ticketNumbers.length != 0, "PottoPrizeDraw: No ticket numbers provided");
        require(_ticketNumbers.length <= maxNrOfPurchasableOrClaimableTickets, "PottoPrizeDraw: Too many tickets to purchase");

        require(_drawRounds[_roundId].status == Status.Open, "PottoPrizeDraw: Round with given id is not started");
        require(block.timestamp <= _drawRounds[_roundId].endTime, "PottoPrizeDraw: Round with given id has already finished");

        uint256 totalTicketsCost = _calculateTotalPriceForMultipleTickets(
            _drawRounds[_roundId].ticketPrice,
            _ticketNumbers.length
        );

        // Increment the total amount collected for the draw round
        _drawRounds[_roundId].amountCollected += totalTicketsCost;

        for (uint256 i = 0; i < _ticketNumbers.length; i++) {
            uint32 thisTicketNumber = _ticketNumbers[i];

            require((thisTicketNumber >= 1000000) && (thisTicketNumber <= 1999999), "PottoPrizeDraw: Ticket numbers outside range");

            _tickets[currentTicketId] = Ticket({ number: thisTicketNumber, owner: msg.sender, purchaseTime: block.timestamp, roundId: _roundId, claimed: false, ticketId: currentTicketId });

            _purchaseHistory[msg.sender].push(currentTicketId);

            // Increase draw ticket number
            currentTicketId++;
        }

        assert(msg.value == totalTicketsCost);

        emit TicketsPurchased(msg.sender, _roundId, _ticketNumbers.length, block.timestamp, _ticketNumbers);
    }

    /**
     * @notice Claim the reward for your purchased tickets if user purchased winning ticket
     * @param _roundId: round id
     * @param _ticketIds: array of ticket ids to check if they have the winning combination
     */
    function claimTickets(uint256 _roundId, uint256[] calldata _ticketIds) external override payable {
        require(_ticketIds.length > 0, "PottoPrizeDraw: Cannot pass an empty array of ticket ids");
        require(_drawRounds[_roundId].status == Status.Claimable, "PottoPrizeDraw: Round with given id didn't become claimable yet");

        uint32 roundWinningNumber = _drawRounds[_roundId].winningNumber;
        bool isWinner = false;

        // Initializes the amountToTransferToWinner
        uint256 amountToTransferToWinner;
        uint256 i = 0;

        while (i < _ticketIds.length) {
            
            uint256 thisTicketId = _ticketIds[i];

            require(_tickets[thisTicketId].claimed != true, "PottoPrizeDraw: Ticket already claimed (flag check)");
            require(_tickets[thisTicketId].owner != address(0), "PottoPrizeDraw: Ticket already claimed (owner check)");
            require(msg.sender == _tickets[thisTicketId].owner, "PottoPrizeDraw: Ticket wasn't purchased by the caller");

            _tickets[thisTicketId].claimed = true;
            _tickets[thisTicketId].owner = address(0);

            uint32 userTicketNumber = _tickets[thisTicketId].number;
            
            if (userTicketNumber == roundWinningNumber) {
                uint256 rewardForWinningTicketId = _calculateRewardsForWinningTicketId(_roundId, thisTicketId);
                amountToTransferToWinner += rewardForWinningTicketId;
                isWinner = true;
            }

            i++;
        }

        if (isWinner && amountToTransferToWinner > 0) {
            _drawRounds[_roundId].amountCollected = 0;

            if (_roundId != currentRoundId) {
              _drawRounds[currentRoundId].amountCollected = 0;
            }

            address claimer = msg.sender;
            payable(claimer).transfer(amountToTransferToWinner);
        }

        emit TicketsClaimed(msg.sender, isWinner, amountToTransferToWinner, _roundId, _ticketIds.length); 
    }

    /**
     * @notice Calculate rewards for the winning ticket id
     * @param _roundId: round id
     * @param _ticketId: ticket id
     */
    function _calculateRewardsForWinningTicketId(uint256 _roundId, uint256 _ticketId) internal view returns (uint256) {
        // Retrieve the winning number combination
        uint32 roundWinningNumber = _drawRounds[_roundId].winningNumber;

        // Retrieve the user number combination from the ticketId
        uint32 userTicketNumber = _tickets[_ticketId].number;

        if (roundWinningNumber == userTicketNumber) {
            return address(this).balance;
        } else {
            return 0;
        }
    }

     /**
     * @notice View ticket numbers and statuses for a given array of ticket ids
     * @dev Only callable by owner
     * @param _ticketIds: array of ticket ids
     */
    function viewNumbersAndStatusesForTicketIds(uint256[] calldata _ticketIds)
        external
        override
        onlyOperator
        view
        returns (uint32[] memory, bool[] memory)
    {
        uint256 length = _ticketIds.length;
        uint32[] memory ticketNumbers = new uint32[](length);
        bool[] memory ticketStatuses = new bool[](length);

        for (uint256 i = 0; i < length; i++) {
            ticketNumbers[i] = _tickets[_ticketIds[i]].number;
            if (_tickets[_ticketIds[i]].owner == address(0)) {
                ticketStatuses[i] = true;
            } else {
                ticketStatuses[i] = false;
            }
        }

        return (ticketNumbers, ticketStatuses);
    }

    /**
     * @notice View purchased tickets history for a given buyer address
     * @param _buyerAddress: buyer address
     * @param _cursor: index from where to start getting tickets history
     * @param _size: number of tickets to fetch
     */
    function viewPurchasedTicketsHistoryForUser(
        address _buyerAddress,
        uint256 _cursor,
        uint256 _size
    )
        external
        view
        notContract
        returns (
            Ticket[] memory
        )
    {
        if (_purchaseHistory[_buyerAddress].length == 0) {
            return new Ticket[](0);
        }

        uint256 length = _size;
        uint256 nrOfPurchasedTickets = _purchaseHistory[_buyerAddress].length;

        if (length > (nrOfPurchasedTickets - _cursor)) {
            length = nrOfPurchasedTickets - _cursor;
        }

        uint256[] memory ticketIds = new uint256[](length);
        Ticket[] memory tickets = new Ticket[](length);

        for (uint256 i = 0; i < length; i++) {
            ticketIds[i] = _purchaseHistory[_buyerAddress][i + _cursor];
            tickets[i] = _tickets[ticketIds[i]];
        }

        return tickets;
    }

    /**
     * @notice Calculate total price for a number of tickets to be purchased
     * @param _ticketPrice: price of a ticket
     * @param _numberOfTickets: number of tickets to purchase
     */
    function calculateTotalPriceForMultipleTickets(
        uint256 _ticketPrice,
        uint256 _numberOfTickets
    ) external override pure returns (uint256) {
        require(_numberOfTickets > 0, "PottoPrizeDraw: Number of tickets must be > 0");

        return _calculateTotalPriceForMultipleTickets(_ticketPrice, _numberOfTickets);
    }

    /**
     * @notice Helper method to calculate total price for a given number of tickets
     * @param _ticketPrice: price of a ticket
     * @param _numberOfTickets: number of tickets to purchase
     */
    function _calculateTotalPriceForMultipleTickets(
        uint256 _ticketPrice,
        uint256 _numberOfTickets
    ) internal pure returns (uint256) {
        return (_ticketPrice * _numberOfTickets);
    }

    // ***** Miscellaneous methods *****
    /**
     * @notice Transfer funds out of the contract into a different prize draw contract
     * @dev Only callable by owner
     * @param targetAddress: address towards to send the contract balance
     */
    function transferJackpotToDifferentContract(address targetAddress) external override payable onlyOperator {
        payable(targetAddress).transfer(address(this).balance);
    }

    /**
     * @notice Helper method to check if the given address is a contract address
     * @param _addr: address to test if it is a contract address
     */
    function _isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    /**
     * @notice Inject funds into a round
     * @dev Callable by owner or injector address
     * @param _roundId: round id
     * @param _amountToInject: amount to inject
     */
    function injectFunds(uint256 _roundId, uint256 _amountToInject) external override payable onlyOwnerOrInjector {
        require(_drawRounds[_roundId].status == Status.Open, "PottoPrizeDraw: Round with given id has not started");

        assert(msg.value == _amountToInject);
        
        _drawRounds[_roundId].amountCollected += _amountToInject;
        _drawRounds[_roundId].jackpot += address(this).balance;

        emit RoundInjection(_roundId, _amountToInject);
    }

    /**
     * @notice Change the random generator
     * @dev The calls to functions are used to verify the new generator implements them properly.
     * It is necessary to wait for the VRF response before starting a round.
     * @dev Only callable by owner
     * @param _randomGeneratorAddress: address of the random generator
     */
    function changeRandomGenerator(address _randomGeneratorAddress) external override onlyOwner {
        require(_drawRounds[currentRoundId].status == Status.Claimable, "PottoPrizeDraw: Round with given id didn't become claimable yet");

        // Request a random number from the generator based on a seed
        IRandomNumberGenerator(_randomGeneratorAddress).getRandomNumber(
            uint256(keccak256(abi.encodePacked(currentRoundId, currentTicketId)))
        );

        // Calculate the winningNumber based on the randomResult generated by ChainLink's fallback
        IRandomNumberGenerator(_randomGeneratorAddress).viewRandomResult();

        randomGenerator = IRandomNumberGenerator(_randomGeneratorAddress);

        emit NewRandomGenerator(_randomGeneratorAddress);
    }
}