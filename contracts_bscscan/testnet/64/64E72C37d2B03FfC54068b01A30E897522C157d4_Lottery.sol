/**
 *Submitted for verification at BscScan.com on 2021-10-23
*/

// File: openzeppelin-solidity/contracts/utils/Context.sol



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

// File: openzeppelin-solidity/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


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

// File: contracts/interfaces/IBEP20.sol


pragma solidity ^0.8.0;

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
    function allowance(address _owner, address spender) external view returns (uint256);

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

// File: contracts/interfaces/ILottery.sol


pragma solidity ^0.8.0;

interface ILottery {
    /**
     * @notice View current game id
     */
    function viewCurrentGameId() external returns (uint256);
}

// File: contracts/interfaces/IRandomNumberGenerator.sol


pragma solidity ^0.8.0;

interface IRandomNumberGenerator {
    /**
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber(uint256 _seed) external;

    /**
     * View latest gameId
     */
    function viewLatestGameId() external view returns (uint256);

    /**
     * Views random result
     */
    function viewRandomResult() external view returns (uint256);
}

// File: contracts/Lottery.sol

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;





/**
 * @title Lottery on Chains
 * @author maxdanify
 * @notice Contract implements a lottery game with only one winner
 */
contract Lottery is ILottery, Ownable {
    /// @dev (Open) -> closeGame -> (Close) -> endGame -> (Open)
    /// @dev Game can be closed only if the time is over,
    /// @dev at this point players can't buy a new tickets
    /// @dev So this time is used to generate a random number,
    /// @dev thereby choose a winner ticket.
    /// @dev Once it is done state changes to Close
    enum State {
        Open,
        Close
    }
    State public state = State.Open;

    // Contains all game parameters and rules
    struct Game {
        // Ticket price in wei
        uint256 ticketPrice;
        // Game time period
        uint256 gameTime;
        // The percentage of sales returned to the players in the form of prize
        uint256 prizePayout;
        // The money from sales that will be used to pay prize
        uint256 prizePool;
        // Prediction fee
        uint8 predictionFee;
        // discount for bulk of tickets
        uint256 discountDivisor;
    }

    // Partnership with a lottery
    address public partner;
    // The percentage of sales provided to a lottery partner
    uint256 public commission;

    // Parameters for the current and next games.
    // Owner can only change the rules for the next game
    // current game rules are immutable
    Game public next;
    Game public current;

    // Allowed withdrawals of previous lottery winners
    mapping(address => uint256) public unclaimedPrizes;
    uint256 unclaimedPrizesTotal = 0;

    // Participant info
    struct Participant {
        // Unique id assigned on first buy
        uint256 id;
        // Number of tickets
        uint32 tickets;
        // Choosen number for the game
        uint8 number;
    }

    // Participants of the current game
    address[] participantAddresses;
    mapping(address => Participant) public participants;

    uint8[] predictions;
    mapping(uint8 => address[]) public predictionsMap;

    // Sold tickets
    address[] tickets;
    // Number of sold tickets in current game
    uint32 public soldTickets = 0;
    // The date when the current game will end and the new will be started
    uint256 public gameEndTime;

    uint32 public currentGameId;

    uint256 public maxNumberTicketsPerBuy = 100;

    uint256 public constant MIN_GAME_DURATION = 1 hours;
    uint256 public constant MAX_GAME_DURATION = 30 days;
    uint256 public constant MIN_DISCOUNT_DIVISOR = 200;

    IBEP20 public SORT;
    IRandomNumberGenerator public randomGenerator;

    /// Game ends and winner is defined
    event Win(uint32 indexed gameId, address indexed winner, uint256 prize);

    /**
     * Emitted when the game is closed
     */
    event GameClosed(uint32 indexed gameId);

    /// Game ends with number of winners correctly predicted
    event PredictionsResult(
        uint32 indexed gameId,
        uint8 _number,
        uint256 _winners,
        uint256 _staked
    );

    /**
     * @dev Emitted when a tickets purchase is happened
     */
    event TicketsPurchase(
        address indexed buyer,
        uint256 indexed gameId,
        uint32 ticketsNumber
    );

    /**
     * @dev Emitted when a new random geenrator contract is set
     */
    event NewRandomGenerator(address indexed randomGenerator);

    /**
     * @dev Emitted when prize pool of lottery was increased
     */
    event PrizePoolIncreased(uint256 indexed gameId, uint256 increasedAmount);

    /// Claim rewards
    event Claim(address indexed claimer, uint256 amount);

    /// New partnership is established
    event Partnership(address indexed partner, uint256 commission);

    /**
     * @dev Set contract deployer as owner
     * @param _sortTokenAddress address of the SORT token
     * @param _randomGeneratorAddress address of the RandomGenerator contract
     */
    constructor(address _sortTokenAddress, address _randomGeneratorAddress) {
        SORT = IBEP20(_sortTokenAddress);
        randomGenerator = IRandomNumberGenerator(_randomGeneratorAddress);

        current = Game(
            10_000_000_000_000_000,
            5 minutes,
            90,
            0,
            50,
            MIN_DISCOUNT_DIVISOR
        );
        next = current;
        gameEndTime = block.timestamp + current.gameTime;
    }

    receive() external payable {}

    /**
     * @notice View current lottery id
     */
    function viewCurrentGameId() external view override returns (uint256) {
        return currentGameId;
    }

    /**
     * @notice Set max number of tickets per buy
     */
    function setMaxNumberTicketsPerBuy(uint256 _maxNumberTicketsPerBuy) external onlyOwner {
        require(_maxNumberTicketsPerBuy != 0, "Must be > 0");
        maxNumberTicketsPerBuy= _maxNumberTicketsPerBuy;
    }

    /**
     * @notice Change the random generator
     * @param _randomGeneratorAddress address of the new random generator
     */
    function setRandomGenerator(address _randomGeneratorAddress)
        external
        onlyOwner
    {
        randomGenerator = IRandomNumberGenerator(_randomGeneratorAddress);
        emit NewRandomGenerator(_randomGeneratorAddress);
    }

    /// @notice owner can set the new ticket price for the next game
    /// @param _ticketPrice new ticket price in wei
    function setTicketPrice(uint256 _ticketPrice) public onlyOwner {
        next.ticketPrice = _ticketPrice;
    }

    /// @notice owner can change the time period for the next game
    /// @param _gameTime new time period for next game
    function setGameTime(uint256 _gameTime) public onlyOwner {
        require(
            _gameTime >= MIN_GAME_DURATION && _gameTime <= MAX_GAME_DURATION,
            "Game duration outside of range"
        );
        next.gameTime = _gameTime;
    }

    /// @notice owner can change the prize payout for the next game
    /// @param _prizePayout new prize payout (% received by players) for next game
    function setPrizePayout(uint256 _prizePayout) public onlyOwner {
        require(_prizePayout <= 100);
        next.prizePayout = _prizePayout;
    }

    /**
     * @notice Set the prize pool percentage for the prediction number game.
     * @param _fee part of the prize pool used in a prediction game.
     */
    function setPredictionFee(uint8 _fee) public onlyOwner {
        require(_fee <= 100);
        next.predictionFee = _fee;
    }

    /// @notice owner can set the partner and his commission
    /// @param _partner address
    /// @param _commission partner commission in %
    function setPartner(address _partner, uint256 _commission)
        public
        onlyOwner
    {
        require(_commission <= 100);
        partner = _partner;
        commission = _commission;
        emit Partnership(partner, commission);
    }

    /**
     * @notice Increase the current prize pool by the transfered value.
     */
    function increasePrizePool() external payable onlyOwner {
        require(state == State.Open, "Game not open");
        current.prizePool += msg.value;
        emit PrizePoolIncreased(currentGameId, msg.value);
    }

    /// @notice owner can take the profit
    /// @param _address address where to transfer profit
    function withdrawProfit(address _address) public onlyOwner {
        require(profit() > 0);
        payable(_address).transfer(profit());
    }

    /// @return current owner profit
    function profit() public view returns (uint256) {
        if (address(this).balance - withholdings() < 0) {
            return 0;
        }
        return address(this).balance - withholdings();
    }

    /// @notice Returns the amounts required to be subtracted from a balance
    /// @notice to cover payments
    ///
    /// @return withholdings
    function withholdings() internal view returns (uint256) {
        return current.prizePool + next.prizePool + unclaimedPrizesTotal;
    }

    /**
     * @notice Player can choose the bonus number in range [1, 99].
     * @notice The number can be choosen once per game.
     * @notice Player have to buy at least 1 ticket before choosing.
     * @param _number bonus number
     */
    function chooseNumber(uint8 _number) public {
        require(state == State.Open, "Game is not open");
        require(
            _number > 0 && _number < 100,
            "Number should be in range [1, 99]"
        );
        require(participants[msg.sender].id != 0);
        require(
            participants[msg.sender].number == 0,
            "You already chose a number in the current game"
        );
        require(
            SORT.balanceOf(msg.sender) > 0,
            "Account does not have SORT tokens on a balance"
        );

        participants[msg.sender].number = _number;
        if (predictionsMap[_number].length == 0) {
            predictions.push(_number);
        }
        predictionsMap[_number].push(msg.sender);
    }

    /// @notice Buy a tickets. You can't buy tickets if the game is closed.
    /// @notice The price of ticket is defined by the `ticketBulkPrice` method
    /// @notice if there are more than 1 ticket in the buy.
    /// @param _amount amount of tickets to buy
    function buyTickets(uint32 _amount) public payable {
        require(_amount != 0 && _amount <= maxNumberTicketsPerBuy, "Too many tickets");
        require(state == State.Open, "Game is not open");
        require(block.timestamp < gameEndTime, "Game is over");

        uint256 totalPrice = calculatePriceForBulkTickets(
            current.ticketPrice,
            _amount,
            current.discountDivisor
        ) * _amount;
        require(msg.value >= totalPrice, "Insufficient amount");

        // refund excessive values
        if (msg.value > totalPrice) {
            uint256 refund = msg.value - totalPrice;
            payable(msg.sender).transfer(refund);
        }

        Participant storage participant = participants[msg.sender];

        // register new participant if he/she does not exist
        if (participant.id == 0) {
            participantAddresses.push(msg.sender);
            participant.id = participantAddresses.length;
            participant.tickets = 0;
        }

        participant.tickets += _amount;

        for (uint32 i = 0; i < _amount; i++) {
            tickets.push(msg.sender);
            soldTickets++;
        }

        uint256 payout = (totalPrice * current.prizePayout) / 100;
        if (partner != address(0)) {
            // partner gets % (commission) of the profit
            uint256 incentives = ((totalPrice - payout) * commission) / 100;
            unclaimedPrizes[partner] += incentives;
            unclaimedPrizesTotal += incentives;
        }

        uint256 nextPayout = (payout * 10) / 100;
        current.prizePool += payout - nextPayout;
        next.prizePool += nextPayout;

        emit TicketsPurchase(msg.sender, currentGameId, _amount);
    }

    function setDiscountDivisor(uint256 _discountDivisor) public onlyOwner {
        require(
            _discountDivisor >= MIN_DISCOUNT_DIVISOR,
            "Must be >= MIN_DISCOUNT_DIVISOR"
        );
        next.discountDivisor = _discountDivisor;
    }

    /**
     * @notice Calculates ticket price for bulk of tickets
     * @param _ticketPrice price of a ticket
     * @param _numberTickets number of tickets purchased
     * @param _discountDivisor divisor for the discount
     */
    function calculatePriceForBulkTickets(
        uint256 _ticketPrice,
        uint32 _numberTickets,
        uint256 _discountDivisor
    ) public pure returns (uint256) {
        require(
            _discountDivisor >= MIN_DISCOUNT_DIVISOR,
            "Must be >= MIN_DISCOUNT_DIVISOR"
        );
        require(_numberTickets != 0, "Number of tickets must be > 0");
        return
            (_ticketPrice * (_discountDivisor + 1 - _numberTickets)) /
            _discountDivisor;
    }

    function closeGame() public {
        require(block.timestamp > gameEndTime, "Game not over");
        require(state == State.Open, "Game not open");

        randomGenerator.getRandomNumber(seed());
        state = State.Close;
        emit GameClosed(currentGameId);
    }

    /// @notice anyone can end the game, but only if the game is closed
    function endGame() public {
        require(
            currentGameId == randomGenerator.viewLatestGameId(),
            "Numbers not drawn"
        );
        require(state == State.Close, "Game not close");

        if (participantAddresses.length > 0) {
            address winner = draw();

            // if someone choose the number
            uint8 number = drawNumber();
            uint256 pTotal = 0;
            address[] storage winners = predictionsMap[number];
            uint256 predictionGamePrize = (current.prizePool *
                current.predictionFee) / 100;
            current.prizePool -= predictionGamePrize;
            if (predictionsMap[number].length > 0) {
                for (uint32 i = 0; i < winners.length; i++) {
                    pTotal += SORT.balanceOf(winners[i]);
                }

                for (uint32 i = 0; i < winners.length; i++) {
                    uint256 curPredictionPrize = (predictionGamePrize *
                        SORT.balanceOf(winners[i])) / pTotal;
                    unclaimedPrizes[winners[i]] += curPredictionPrize;
                    predictionGamePrize -= curPredictionPrize;
                }
            } else {
                next.prizePool += predictionGamePrize;
            }
            emit PredictionsResult(
                currentGameId,
                number,
                winners.length,
                pTotal
            );

            unclaimedPrizes[winner] += current.prizePool;
            unclaimedPrizesTotal += current.prizePool;
            emit Win(currentGameId, winner, current.prizePool);
        } else {
            next.prizePool += current.prizePool;
        }

        current = next;
        next.prizePool = 0;

        gameEndTime = block.timestamp + current.gameTime;
        state = State.Open;

        for (uint32 i = 0; i < participantAddresses.length; i++) {
            delete participants[participantAddresses[i]];
        }
        delete participantAddresses;
        // all tickets are burned after game is ended
        delete tickets;
        delete soldTickets;

        for (uint8 i = 0; i < predictions.length; i++) {
            delete predictionsMap[predictions[i]];
        }
        delete predictions;

        currentGameId += 1;
    }

    /// @notice Players can claim prize if they have a winner tickets
    function claim() public returns (bool) {
        uint256 prize = unclaimedPrizes[msg.sender];
        if (prize > 0) {
            // It is important to set this to zero because the recipient
            // can call this function again as part of the receivin.g call
            // before `send` returns.
            unclaimedPrizes[msg.sender] = 0;
            unclaimedPrizesTotal -= prize;

            if (!payable(msg.sender).send(prize)) {
                // No need to call throw here, just reset the amount owing
                unclaimedPrizes[msg.sender] = prize;
                unclaimedPrizesTotal += prize;
                return false;
            }

            emit Claim(msg.sender, prize);
        }
        return true;
    }

    /// @notice Select winner
    function draw() internal view returns (address) {
        uint256 luckyTicket = randomGenerator.viewRandomResult() % soldTickets;
        return tickets[luckyTicket];
    }

    /**
     * @dev Draw random number in [1, 99]
     */
    function drawNumber() internal view returns (uint8) {
        return (uint8)((randomGenerator.viewRandomResult() % 99) + 1);
    }

    /// @notice Generate seed for random generator
    function seed() internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.difficulty,
                        block.timestamp,
                        participantAddresses
                    )
                )
            );
    }
}