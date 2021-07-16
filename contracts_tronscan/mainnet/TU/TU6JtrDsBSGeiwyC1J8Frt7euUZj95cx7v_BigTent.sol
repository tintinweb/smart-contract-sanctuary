//SourceUnit: BigTent.sol

pragma solidity 0.5.15;

import "./Hourglass.sol";

contract BigTent {

    /*=================================
    =            MODIFIERS            =
    =================================*/
    modifier onlyAdministrator() {
        address _customerAddress = msg.sender;
        require(
            administrators[_customerAddress],
            "Only administrators can call this function"
        );
        _;
    }

    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    address payable internal constant CETO_CONTRACT_ADDRESS =
        0x0b84765BdCf9e29777e2444F7aAE6BD5921DE20b;
    Hourglass internal CETO = Hourglass(CETO_CONTRACT_ADDRESS);

    uint256 public ticketPrice;
    address public partner;
    uint256 public initialGuaranteedPrizePool;
    uint256 public period;
    uint256 public startDate;

    uint256 public countdownStartedAt = 0;
    address[] public participants;
    uint256 public participantsCount = 0;
    bool public gameStarted = false;
    bool public resultDeclared = false;

    uint256 internal firstWinnerIndex;
    uint256 internal secondWinnerIndex;
    uint256 internal thirdWinnerIndex;
    uint256 internal firstPrizeProportion;
    uint256 internal secondPrizeProportion;
    uint256 internal thirdPrizeProportion;

    uint256 internal commit = 0;
    uint256 constant BET_EXPIRATION_BLOCKS = 250;
    uint256 constant MIN_CETO = 871;
    uint40 internal commitBlockNumber;
    uint256 public startingTronBalance;

    // to keep track of the CETO collected for a particular game
    uint256 internal totalCETOCollected;

    // REBATE TRACKING

    // amount of ceto sent with their buy timestamp for each address
    struct TimestampedCETODeposit {
        uint256 value;
        uint256 gameNumber;
        uint256 valueSold;
    }

    mapping(address => TimestampedCETODeposit[]) internal cetoTimestampedLedger;

    // The start and end index of the unsold timestamped transactions list
    struct DepositCursor {
        uint256 start;
        uint256 end;
    }

    mapping(address => DepositCursor) internal cetoTimestampedCursor;

    // The game number
    // Increment this number every time a new game is started
    uint256 public gameNumber = 0;

    // Mapping to keep track of The dividend collected and the total amount deposited for each game
    struct GameResult {
        uint256 dividendCollected;
        uint256 totalCetoDeposited;
    }
    mapping(uint256 => GameResult) internal gameResults;

    // Mapping to store ticket count of every user
    mapping(uint256 => mapping(address => uint256))
        internal TicketsPerAddressForGame;

    function getEquivalentTron(TimestampedCETODeposit storage _deposit)
        private
        view
        returns (uint256)
    {
        // Check if the gameNumber is associated with the ongoing game
        if (_deposit.gameNumber == gameNumber && gameStarted) {
            return uint256(0);
        }

        GameResult storage _gameResult = gameResults[_deposit.gameNumber];
        uint256 equivalentTron =
            mulDiv(
                SafeMath.sub(_deposit.value, _deposit.valueSold),
                _gameResult.dividendCollected,
                _gameResult.totalCetoDeposited
            );
        return equivalentTron;
    }

    function withdrawRebate(uint256 tronToWithdraw) public {

        // Check if the balance is enough
        uint256 rebateBalance = getRebateBalance();
        require(rebateBalance >= tronToWithdraw, "Don't have enough balance");

        // Starting the from the first block on cetoTimestampedLedger keep moving forward
        // until the until sum of value available is enough to cover the withdrawal amount
        uint256 tronFound = 0;
        address _customerAddress = msg.sender;

        // Update the ledger
        DepositCursor storage _customerCursor = cetoTimestampedCursor[_customerAddress];
        uint256 counter = _customerCursor.start;

        while (counter <= _customerCursor.end) {
            TimestampedCETODeposit storage _deposit =
                cetoTimestampedLedger[_customerAddress][counter];
            uint256 tronAvailable = getEquivalentTron(_deposit);
            uint256 tronRequired = SafeMath.sub(tronToWithdraw, tronFound);

            if (tronAvailable < tronRequired) {
                tronFound += tronAvailable;
                delete cetoTimestampedLedger[_customerAddress][counter];
            } else if (tronAvailable == tronRequired) {
                delete cetoTimestampedLedger[_customerAddress][counter];
                _customerCursor.start = counter + 1;
                break;
            } else {
                GameResult storage _gameResult =
                    gameResults[_deposit.gameNumber];
                _deposit.valueSold += mulDiv(
                    tronRequired,
                    _gameResult.totalCetoDeposited,
                    _gameResult.dividendCollected
                );
                _customerCursor.start = counter;
                break;
            }
            counter += 1;
        }

        // Buy rebate CETO
        uint256 cetoBought = CETO.calculateTokensReceived(tronToWithdraw);

        CETO.buy.value(tronToWithdraw)(address(this));
        bool transferSuccess = CETO.transfer(_customerAddress, cetoBought);
        require(transferSuccess, "Unable to buy rebate CETO");
    }

    function getRebateBalance() public view returns (uint256) {
        // Calculate the balance by iterating through the cetoTimestampedLedger
        address _customerAddress = msg.sender;
        DepositCursor storage customerCursor =
            cetoTimestampedCursor[_customerAddress];
        uint256 _rebateBalance = 0;

        for (uint256 i = customerCursor.start; i < customerCursor.end; i++) {
            _rebateBalance += getEquivalentTron(
                cetoTimestampedLedger[_customerAddress][i]
            );
        }
        return _rebateBalance;
    }

    function getCETORebateBalance() public view returns (uint256) {
        uint256 rebateBalance = getRebateBalance();
        uint256 cetoBought = CETO.calculateTokensReceived(rebateBalance);

        // Reduce 10% transaction fee for transfer
        uint256 taxedCETO =
            SafeMath.sub(cetoBought, SafeMath.div(cetoBought, 10));

        return taxedCETO;
    }

    /************mappings************/
    mapping(address => bool) public administrators;

    /*==============================
    =            EVENTS            =
    ==============================*/
    event onTicketPurchase(
        address indexed customerAddress,
        uint8 numberOfTickets
    );
    
    event onGameEnd(
        uint256 gameNumber,
        address firstWinner,
        address secondtWinner,
        address thirdWinner,
        uint256 firstPrize,
        uint256 secondPrize,
        uint256 thirdPrize
    );
    
    event onGameStart(uint256 countdownStartedAt);

    constructor() public {
        address owner = msg.sender;
        administrators[owner] = true;
    }

    /**
     * Fallback function to handle tron that was send straight to the contract
     * Return it.
     */
    function() external payable {
        if (msg.sender != CETO_CONTRACT_ADDRESS) {
            revert("Unauthorized sender");
        }
    }

    // Method for admin to start the game
    function startGame(
        uint256 ticketPrice_,
        address partner_,
        uint256 initialGuaranteedPrizePool_,
        uint256 period_,
        uint256 startDate_,
        uint256 firstPrizeProportion_,
        uint256 secondPrizeProportion_,
        uint256 thirdPrizeProportion_
    ) external onlyAdministrator() {
        require(!gameStarted, "Game has already been started");

        ticketPrice = ticketPrice_;
        partner = partner_;
        initialGuaranteedPrizePool = initialGuaranteedPrizePool_;
        period = period_;
        startDate = startDate_;
        gameStarted = true;
        resultDeclared = false;
        delete participants;
        firstPrizeProportion = firstPrizeProportion_;
        secondPrizeProportion = secondPrizeProportion_;
        thirdPrizeProportion = thirdPrizeProportion_;
        startingTronBalance = updateAndFetchTronBalance();
        // Increment the game number by one
        gameNumber += 1;
    }

    // This is the method for user to buy tickets for the raffle
    function buyTicketWithTron(uint8 numberOfTickets) external payable {
        uint256 tronAmountSent = msg.value;
        address _customerAddress = msg.sender;

        uint256 cetoBought = CETO.calculateTokensReceived(tronAmountSent);

        uint256 cetoCostOfTickets =
            SafeMath.mul(ticketPrice, uint256(numberOfTickets));

        require(
            cetoBought >= cetoCostOfTickets,
            "Can't buy enough CETO to cover the ticket cost"
        );

        // Buy the CETO
        CETO.buy.value(tronAmountSent)(address(this));

        if (cetoBought > cetoCostOfTickets) {
            // Send the excess CETO back
            uint256 amountToRefund = SafeMath.sub(cetoBought, cetoCostOfTickets);
            bool transferSuccess = CETO.transfer(_customerAddress, amountToRefund);
            require(transferSuccess, "Unable to transfer excess CETO");
        }

        _allocateTickets(_customerAddress, numberOfTickets);
    }

    // This is the method for user to buy tickets for the raffle
    function buyTicket(uint8 numberOfTickets) external {
        address _customerAddress = msg.sender;
        uint256 cetoCostOfTickets =
            SafeMath.mul(ticketPrice, uint256(numberOfTickets));

        bool success =
            CETO.transferFrom(
                _customerAddress,
                address(this),
                cetoCostOfTickets
            );

        if (!success) {
            revert("Transfer Failed");
        }
        _allocateTickets(_customerAddress, numberOfTickets);
    }

    function _allocateTickets(address _customerAddress, uint8 numberOfTickets)
        internal
    {
        // Maintain a list of participants
        // Run a for loop for multiple entries
        for (uint8 i = 0; i < numberOfTickets; i++) {
            participants.push(_customerAddress);
        }
        participantsCount += numberOfTickets;

        uint256 cetoCostOfTickets = SafeMath.mul(ticketPrice, uint256(numberOfTickets));
        totalCETOCollected = SafeMath.add(totalCETOCollected, cetoCostOfTickets);

        // Store this buy in the deposit ledger
        cetoTimestampedLedger[_customerAddress].push(
            TimestampedCETODeposit(cetoCostOfTickets, gameNumber, 0)
        );
        cetoTimestampedCursor[_customerAddress].end += 1;

        TicketsPerAddressForGame[gameNumber][_customerAddress] += uint256(
            numberOfTickets
        );

        // Check if totalCetoBalance is greater than or equal to GPP and the countdown hasn't been set yet
        if (
            getCurrentCETOBalance() >= initialGuaranteedPrizePool &&
            countdownStartedAt == 0
        ) {
            countdownStartedAt = block.timestamp;

            emit onGameStart(countdownStartedAt);
        }

        emit onTicketPurchase(_customerAddress, numberOfTickets);
    }

    // This is an admin only function to set commit.
    // Commits are the Keccak256 hash of some secret "reveal" random number, to be supplied
    // by the bot in the declareResult transaction. Supplying
    // "commit" ensures that "reveal" cannot be changed behind the scenes
    // after setCommit has been mined.
    function setCommit(uint256 commit_) external onlyAdministrator() {
        commit = commit_;
        commitBlockNumber = uint40(block.number);
    }

    // This is the method used to settle bets. declareResult should supply a "reveal" number
    // that would Keccak256-hash to "commit". "blockHash" is the block hash
    // of setCommit block as seen by croupier; it is additionally asserted to
    // prevent changing the bet outcomes on Ethereum reorgs.
    function declareResult(uint256 reveal)
        external
        onlyAdministrator
        returns (uint256)
    {
        // Check if the reveal is valid
        uint256 commit_ = uint256(keccak256(abi.encodePacked(reveal)));
        require(commit_ == commit, "Invaild reveal");

        require(gameStarted, "A game isn't running right now");
        require(!resultDeclared, "Result is already declared");

        require(participantsCount > 2, "Insufficient participants");

        require(
            countdownStartedAt + period <= block.timestamp,
            "Countdown hasn't finished yet"
        );

        require(
            getCurrentCETOBalance() >= mulDiv(initialGuaranteedPrizePool, 2, 3),
            "Insufficient amount"
        );

        // Check that bet has not expired yet (see comment to BET_EXPIRATION_BLOCKS).
        require(
            block.number >= commitBlockNumber,
            "declareResult in the same block as setCommit, or before."
        );
        require(
            block.number < commitBlockNumber + BET_EXPIRATION_BLOCKS,
            "Blockhash can't be queried by EVM."
        );

        // The RNG - combine "reveal" and blockhash of setCommit using Keccak256. Miners
        // are not aware of "reveal" and cannot deduce it from "commit",
        // and house is unable to alter the "reveal" after setCommit has been mined.
        bytes32 firstEntropy =
            keccak256(abi.encodePacked(reveal, blockhash(commitBlockNumber)));
        firstWinnerIndex = uint256(firstEntropy) % participantsCount;
        address firstWinner = participants[firstWinnerIndex];

        bytes32 secondEntropy = keccak256(abi.encodePacked(firstEntropy));
        secondWinnerIndex = (uint256(secondEntropy) % (participantsCount - 1));
        secondWinnerIndex = secondWinnerIndex < firstWinnerIndex
            ? secondWinnerIndex
            : secondWinnerIndex + 1;
        address secondWinner = participants[secondWinnerIndex];

        bytes32 thirdEntropy = keccak256(abi.encodePacked(secondEntropy));
        thirdWinnerIndex = uint256(thirdEntropy) % (participantsCount - 2);
        thirdWinnerIndex = thirdWinnerIndex <
            min(secondWinnerIndex, firstWinnerIndex)
            ? thirdWinnerIndex
            : thirdWinnerIndex < (max(secondWinnerIndex, firstWinnerIndex) - 1)
            ? thirdWinnerIndex + 1
            : thirdWinnerIndex + 2;
        address thirdWinner = participants[thirdWinnerIndex];

        // Calculate the prize money
        uint256 firstPrize;
        uint256 secondPrize;
        uint256 thirdPrize;
        (firstPrize, secondPrize, thirdPrize) = getPrizes();
        uint256 partnerPoolFunds = getPartnerPoolFunds();

        // Send/Assign the prize money to the winners
        bool success;
        success = CETO.transfer(firstWinner, firstPrize);
        if (!success) {
            revert("First prize distribution failed");
        }
        success = CETO.transfer(secondWinner, secondPrize);
        if (!success) {
            revert("Second prize distribution failed");
        }
        success = CETO.transfer(thirdWinner, thirdPrize);
        if (!success) {
            revert("Third prize distribution failed");
        }

        // Assign/Payout out the promotional partner
        if (partner != address(0)) {
            success = CETO.transfer(partner, partnerPoolFunds);
            if (!success) {
                revert("Partner pool funds distribution failed");
            }
        }

        // Calculate the dividend collected
        uint256 tronCollected =
            updateAndFetchTronBalance() - startingTronBalance;
        gameResults[gameNumber] = GameResult(tronCollected, totalCETOCollected);

        resultDeclared = true;

        emit onGameEnd(
            gameNumber,
            participants[firstWinnerIndex],
            participants[secondWinnerIndex],
            participants[thirdWinnerIndex],
            firstPrize,
            secondPrize,
            thirdPrize
        );
    }

    function updateAndFetchTronBalance() public returns (uint256) {
        if (CETO.myDividends(true) > 0) {
            CETO.withdraw();
        }
        uint256 tronBalance = address(this).balance;
        return tronBalance;
    }

    function totalTronBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function resetGame() external onlyAdministrator() {
        require(gameStarted, "A game isn't running right now");
        require(resultDeclared, "Result isn't declared yet");

        // Resetting the data
        ticketPrice = 0;
        partner = address(0);
        initialGuaranteedPrizePool = 0;
        period = 0;
        startDate = 0;
        countdownStartedAt = 0;
        participantsCount = 0;

        gameStarted = false;

        totalCETOCollected = 0;
    }

    // TEST
    function setParticipantsCount(uint256 participants_)
        external
        onlyAdministrator()
    {
        participantsCount = participants_;
    }

    /*----------  READ ONLY FUNCTIONS  ----------*/

    function getCursor() public view returns (uint256, uint256) {
        address _customerAddress = msg.sender;
        DepositCursor storage cursor = cetoTimestampedCursor[_customerAddress];

        return (cursor.start, cursor.end);
    }

    function TimestampedCETODeposits(uint256 counter)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        address _customerAddress = msg.sender;
        TimestampedCETODeposit storage transaction =
            cetoTimestampedLedger[_customerAddress][counter];
        return (
            transaction.value,
            transaction.gameNumber,
            transaction.valueSold
        );
    }

    function getCurrentCETOBalance() public view returns (uint256) {
        return CETO.myTokens();
    }

    function getTokenFee(uint256 _amount) public view returns (uint256) {
        uint256 cetoBought = CETO.calculateTokensReceived(_amount);
        uint256 _tokenFee = SafeMath.div(cetoBought, 10);

        return _tokenFee;
    }

    function getUserTickets() public view returns (uint256) {
        return TicketsPerAddressForGame[gameNumber][msg.sender];
    }

    function getGameResult(uint256 game)
        public
        view
        returns (uint256, uint256)
    {
        GameResult storage gameResult = gameResults[game];

        return (gameResult.dividendCollected, gameResult.totalCetoDeposited);
    }

    function getEventData()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            bool,
            bool,
            uint256
        )
    {
        return (
            ticketPrice,
            participantsCount,
            initialGuaranteedPrizePool,
            startDate,
            countdownStartedAt,
            period,
            gameStarted,
            resultDeclared,
            gameNumber
        );
    }

    function getPrizes()
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 currentPoolFunds = getFunds();
        uint256 totalProportion =
            firstPrizeProportion + secondPrizeProportion + thirdPrizeProportion;

        // Calculate the prize money
        if (totalProportion != 0) {
            
            uint256 firstPrize =
                mulDiv(
                    currentPoolFunds,
                    firstPrizeProportion,
                    totalProportion
                );
            
            uint256 secondPrize =
                mulDiv(
                    currentPoolFunds,
                    secondPrizeProportion,
                    totalProportion
                );
            
            uint256 thirdPrize =
                mulDiv(
                    currentPoolFunds,
                    thirdPrizeProportion,
                    totalProportion
                );
            
            return (firstPrize, secondPrize, thirdPrize);
        } else {
            return (0, 0, 0);
        }
    }

    function getWinners()
        external
        view
        returns (
            address,
            address,
            address
        )
    {
        return (
            participants[firstWinnerIndex],
            participants[secondWinnerIndex],
            participants[thirdWinnerIndex]
        );
    }

    function getWinnersIndex()
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (firstWinnerIndex, secondWinnerIndex, thirdWinnerIndex);
    }

    function getPartnerPoolFunds() public view returns (uint256) {
        uint256 partnerPoolFunds_ = 0;
        uint256 currentCETOBalance = getCurrentCETOBalance();

        // Calculate 67% of the amout collected
        uint256 minimumRequiredAmount =
            mulDiv(initialGuaranteedPrizePool, 2, 3);

        if (partner != address(0)) {
            // Check if the amount collected is atleast 67% of the initial GPP
            // if amount collected is less than 67% then the partner gets nothing
            // and all the amount goes to the prize pool
            // else 67% goes to the prize pool and the remaining goes to the partner pool
            if (currentCETOBalance > minimumRequiredAmount && currentCETOBalance <= initialGuaranteedPrizePool) {
                partnerPoolFunds_ = SafeMath.sub(currentCETOBalance, minimumRequiredAmount);
            }
            else if(currentCETOBalance > initialGuaranteedPrizePool){
                // Check if the amount collected is greater than the initial GPP
                // if yes then additionally 50% of the difference amount goes to the partner pool

                uint256 differenceAmount = currentCETOBalance - initialGuaranteedPrizePool;

                partnerPoolFunds_ = SafeMath.add(
                    SafeMath.sub(initialGuaranteedPrizePool, minimumRequiredAmount),
                    SafeMath.div(differenceAmount, 2)
                );

            }
        }

        return partnerPoolFunds_;
    }

    function getFunds() public view returns (uint256) {
        uint256 currentPrizePool;
        uint256 differenceAmount;
        uint256 currentCETOBalance = getCurrentCETOBalance();

        // Calculate 67% of the amout collected
        uint256 minimumRequiredAmount = mulDiv(initialGuaranteedPrizePool, 2, 3);

        // Calculate the difference amount if amount collected is greater than the initial gpp
        if (currentCETOBalance > initialGuaranteedPrizePool) {
            differenceAmount = SafeMath.sub(currentCETOBalance, initialGuaranteedPrizePool);
        }

        if (partner == address(0)) {

            // Check if the amount collected is greater than the initial GPP
            // if yes than 50% of the difference amount goes to the current prize pool
            // and 50% to the next prize pool
            
            if (currentCETOBalance > initialGuaranteedPrizePool) {
                currentPrizePool = SafeMath.add(
                    initialGuaranteedPrizePool,
                    SafeMath.div(differenceAmount, 2)
                );
            }
            else {
                currentPrizePool = initialGuaranteedPrizePool;
            }

        } 
        else {

            // If amount collected is less than equal to 67% of initialGuaranteedPrizePool 
            // then entire collected amount goes to the current prize pool.
            // else 67% of initialGuaranteedPrizePool goes to the current prize pool

            if (currentCETOBalance <= minimumRequiredAmount) {
                currentPrizePool = currentCETOBalance;
            } 

            else if (currentCETOBalance <= initialGuaranteedPrizePool){
                currentPrizePool = minimumRequiredAmount;
            }

            // Check if the amount collected is greater than the initial GPP
            // if yes then 50% of the difference amount goes to partner pool,
            // 25% to the current prize pool and 25% to the next prize pool

            else {
                currentPrizePool = SafeMath.add(
                    minimumRequiredAmount,
                    SafeMath.div(differenceAmount, 4)
                );
            }

        }

        return currentPrizePool;
    }

    /*----------  ADMINISTRATOR ONLY FUNCTIONS  ----------*/

    function setAdministrator(address _identifier, bool _status)
        external
        onlyAdministrator()
    {
        require(
            msg.sender != _identifier,
            "The Admin cant change the status for themselves"
        );
        administrators[_identifier] = _status;
    }

    // Function to transfer the remaining funds to administrator when the game
    // has ended and the admin wishes to replace this contract with another
    // upgraded contract
    function transferFunds() external onlyAdministrator() {
        require(!gameStarted, "Game has already been started");

        address administrator_ = msg.sender;

        address payable administrator_payable = address(uint160(administrator_));

        administrator_payable.transfer(address(this).balance);

        bool success = CETO.transfer(administrator_, getCurrentCETOBalance());
        if (!success) {
            revert("Transfer failed");
        }
    }

    /*----------  HELPERS AND CALCULATORS  ----------*/

    /**
     * @dev calculates x*y and outputs a emulated 512bit number as l being the lower 256bit half and h the upper 256bit half.
     */
    function fullMul(uint256 x, uint256 y)
        public
        pure
        returns (uint256 l, uint256 h)
    {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) {
            h -= 1;
        }
    }

    /**
     * @dev calculates max.
     */
    function max(uint256 x, uint256 y) public pure returns (uint256) {
        return x > y ? x : y;
    }

    /**
     * @dev calculates min.
     */
    function min(uint256 x, uint256 y) public pure returns (uint256) {
        return x < y ? x : y;
    }

    /**
     * @dev calculates x*y/z taking care of phantom overflows.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) public pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);
        require(h < z);
        uint256 mm = mulmod(x, y, z);
        if (mm > l) h -= 1;
        l -= mm;
        uint256 pow2 = z & -z;
        z /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        return l * r;
    }
}

/**
 * @title SafeMath_
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath_ {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
     * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

//SourceUnit: Hourglass.sol

pragma solidity 0.5.15;

/*
:'######::'########:'########::'#######::
'##... ##: ##.....::... ##..::'##.... ##:
 ##:::..:: ##:::::::::: ##:::: ##:::: ##:
 ##::::::: ######:::::: ##:::: ##:::: ##:
 ##::::::: ##...::::::: ##:::: ##:::: ##:
 ##::: ##: ##:::::::::: ##:::: ##:::: ##:
. ######:: ########:::: ##::::. #######::
:......:::........:::::..::::::.......:::

Creator: 773d62b24a9d49e1f990b22e3ef1a9903f44ee809a12d73e660c66c1772c47dd

CETO v2: v1 faced the bug https://github.com/ceto-code/ceto-contract/blob/main/BugReport.md
*/

contract Hourglass {
    /*=================================
    =            MODIFIERS            =
    =================================*/
    // only people with tokens
    modifier onlyBagholders() {
        require(myTokens() > 0);
        _;
    }

    // administrators can:
    // -> change the name of the contract
    // -> change the name of the token
    // -> change the PoS difficulty (How many tokens it costs to hold a masternode, in case it gets crazy high later)
    // they CANNOT:
    // -> take funds
    // -> disable withdrawals
    // -> kill the contract
    // -> change the price of tokens
    modifier onlyAdministrator() {
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress], "This address is not an admin");
        _;
    }

    bool public adminCanChangeState = true;

    modifier onlyAdministratorIntialStage() {
        address _customerAddress = msg.sender;
        require(administrators[_customerAddress], "This address is not an admin");
        require(adminCanChangeState, "Admin can't change the contract state now");
        _;
    }

    /*==============================
    =            EVENTS            =
    ==============================*/
    event onTokenPurchase(
        address indexed customerAddress,
        uint256 incomingTron,
        uint256 tokensMinted,
        address indexed referredBy
    );

    event onTokenSell(
        address indexed customerAddress,
        uint256 tokensBurned,
        uint256 tronEarned
    );

    event onReinvestment(
        address indexed customerAddress,
        uint256 tronReinvested,
        uint256 tokensMinted
    );

    event onWithdraw(address indexed customerAddress, uint256 tronWithdrawn);

    // TRC20
    event Transfer(address indexed from, address indexed to, uint256 tokens);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // When a customer sets up AutoReinvestment
    event onAutoReinvestmentEntry(
        address indexed customerAddress,
        uint256 nextExecutionTime,
        uint256 rewardPerInvocation,
        uint24 period,
        uint256 minimumDividendValue
    );

    // When a customer stops AutoReinvestment
    event onAutoReinvestmentStop(address indexed customerAddress);

    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    string public name = "Crystal Elephant Token";
    string public symbol = "CETO";
    uint8 public constant decimals = 6;
    uint8 internal constant dividendFee_ = 10;
    uint256 internal constant tokenPriceInitial_ = 1000; // unit: sun
    uint256 internal constant tokenPriceIncremental_ = 100; // unit: sun
    uint256 internal constant magnitude = 2**64;

    // requirement for earning a referral bonus (defaults at 100 tokens)
    uint256 public stakingRequirement = 100e6;

    /*================================
    =            DATASETS            =
    ================================*/
    // amount of tokens for each address (scaled number)
    mapping(address => uint256) internal tokenBalanceLedger_;

    // amount of tokens bought with their buy timestamp for each address
    struct TimestampedBalance {
        uint256 value;
        uint256 timestamp;
        uint256 valueSold;
    }

    mapping(address => TimestampedBalance[])
        internal tokenTimestampedBalanceLedger_;

    // The start and end index of the unsold timestamped transactions list
    struct Cursor {
        uint256 start;
        uint256 end;
    }

    mapping(address => Cursor) internal tokenTimestampedBalanceCursor;

    // mappings to and from referral address
    mapping(address => bytes32) public referralMapping;
    mapping(bytes32 => address) public referralReverseMapping;

    // The current referral balance
    mapping(address => uint256) public referralBalance_;
    // All time referrals earnings
    mapping(address => uint256) public referralIncome_;

    mapping(address => int256) internal payoutsTo_;
    uint256 internal tokenSupply_ = 0;
    uint256 internal profitPerShare_;

    // administrator list (see above on what they can do)
    mapping(address => bool) public administrators;

    /*=======================================
    =            PUBLIC FUNCTIONS            =
    =======================================*/
    /*
     * -- APPLICATION ENTRY POINTS --
     */
    constructor() public {
        address owner = msg.sender;
        administrators[owner] = true;

        // Set the old state of the v1 contract(TLqB1kuXuKeKzeGkvrZjpLA6Kz6pN2LHj5)
        referralBalance_[0x45De5dFb0E13d6933Afed37870BE6eaf87b4cDEe] = 53333333;
        referralIncome_[0x45De5dFb0E13d6933Afed37870BE6eaf87b4cDEe] = 54999999;

        tokenSupply_ = 151491878936;
        profitPerShare_ = 24868580456951773446;

        tokenBalanceLedger_[0x5716d088a6E3f30FdC8c08eA5c519C103D2BBC24] = 57883882539;
        tokenBalanceLedger_[0x977C7C7356bB046c66d42977da76FdD919B13968] = 5015050398;
        tokenBalanceLedger_[0xfafAa13890452fA444959798302ff8A2d207915d] = 11276741563;
        tokenBalanceLedger_[0xc5f6Bb13B0C2B293391195D04945c6c85708C61a] = 642713425;
        tokenBalanceLedger_[0xc0c6B3d8F93C348474Aee5328d7aB9BECB7dAeAc] = 8953079794;
        tokenBalanceLedger_[0x0Fc480eB1fC590a37647275529B875417C1e4f06] = 4444456768;
        tokenBalanceLedger_[0xdafD17E58f48D462BC7F271A3eee7486B419A632] = 5792729461;
        tokenBalanceLedger_[0x0Cfc783943553a0c91A68d46f9c971128D7d8Aee] = 241572748;
        tokenBalanceLedger_[0x47f06D6269B2fca8238326C26Ef8D5663A2DEde8] = 950502624;
        tokenBalanceLedger_[0x7C6E870fBD73c4404a2aBb14758154CB75D83732] = 236912348;
        tokenBalanceLedger_[0x1e8fD2c59794DCC4Da828A3bCdb60d89299E3cF9] = 1052830363;
        tokenBalanceLedger_[0x6035B5d20d199048E3506C39FedA2884C22A8310] = 2487705468;
        tokenBalanceLedger_[0x0405d13F31a23E551Cc090BAb668C30C37979986] = 1827355259;
        tokenBalanceLedger_[0x8f00412B7DecB40b09A2be04EB0176104BDa6345] = 856616103;
        tokenBalanceLedger_[0x0E8316560ADa85933601C4Ca174E1b4846B8893e] = 850807572;
        tokenBalanceLedger_[0xB0d88b3eC207239Da648789cc23ECFda8906850d] = 4094486753;
        tokenBalanceLedger_[0x9814FF84B339A05eD9012669f3c83cD06B51c863] = 3458425180;
        tokenBalanceLedger_[0x1ECE8b43D8Bf4F191Db604830c2d53476BE5e8e0] = 5131417222;
        tokenBalanceLedger_[0xb38Ba721f92655701717Ae41DD73597a3D89F992] = 716335014;
        tokenBalanceLedger_[0xe124df636bB848e2A861Ee9B39Ea10AB91fc7d0a] = 171075007;
        tokenBalanceLedger_[0x1e91F0263b09049F1C940663781b5FB2162728C8] = 3448791131;
        tokenBalanceLedger_[0x45De5dFb0E13d6933Afed37870BE6eaf87b4cDEe] = 607987747;
        tokenBalanceLedger_[0x31cc9E04D9E53ba0b30Abb39c66496CeA879A90f] = 95124572;
        tokenBalanceLedger_[0x2Ea8C9bcB691B5b0286Af71Bc8C3d7083EF59b53] = 174312696;
        tokenBalanceLedger_[0xC514D37EA3f613aa669dD6f4B6daa8795751006F] = 12633124256;
        tokenBalanceLedger_[0x84A3048C863aa9bf7b58e1D754AA27911bEbCDC7] = 18917867;
        tokenBalanceLedger_[0xe974cB98FBd4980F27C80fb6Dc27067F6B04b1C7] = 588345415;
        tokenBalanceLedger_[0xEa58c4810fA0c2328489254B70D43EBEC578dC5c] = 2909600051;
        tokenBalanceLedger_[0x76d7cBe6D51c5Aea8147DC11Fe474a840fc71Ce2] = 723272079;
        tokenBalanceLedger_[0xcBf2B91779a3e2C82026D3575A9C1E0aAAa99a9D] = 125202208;
        tokenBalanceLedger_[0xdd69F5609Bd36161Ac0793Cb92B4c0BaE9993e72] = 43362371;
        tokenBalanceLedger_[0xC4E0789750295C70cdaf5d7e0006cC3d597Cd310] = 1706463986;
        tokenBalanceLedger_[0x82305e850f648D11401738BC94Bee7ffDAC49102] = 13168548;
        tokenBalanceLedger_[0x860a07bD229ba784aBb28ADC7fCcC796C93B49DA] = 121318686;
        tokenBalanceLedger_[0xd0E675469aDEd5f0287Bbbf3e295807793F39bD8] = 47893518;
        tokenBalanceLedger_[0x4CB1bA572Eb406b2F9040CDC37F380923c7e4030] = 711026551;
        tokenBalanceLedger_[0xB4D32A4B1f1Fd35aCd0feBdE172103788f3aA8C4] = 15064176;
        tokenBalanceLedger_[0x5D91eA5236c4C9f8615187e2909fe6137cCfA9A6] = 133103392;
        tokenBalanceLedger_[0x23e5A169DFEBD287Ff0DF8a022d23E84E05bd97c] = 130176593;
        tokenBalanceLedger_[0x138b8FcfCDce162CDc46C9408dcC060C74275034] = 38694503;
        tokenBalanceLedger_[0x1D74Ce35aaa4522afB1A92eF71483656Ba9CaFc8] = 131259876;
        tokenBalanceLedger_[0x049d9B4A5F56A2423362eEa9a3D38D8361A1FEDA] = 345536862;
        tokenBalanceLedger_[0x4e642898D58Fa6d0EaCD689a7c1d04124848240b] = 131318679;
        tokenBalanceLedger_[0xF7e5e236A64b09Ae9e23568B44c0607FA7682bA4] = 300852704;
        tokenBalanceLedger_[0xb4514C4332f793619f83E854c18D208e2a10dAF4] = 160374778;
        tokenBalanceLedger_[0x0Abc1fDb38AD29c788412d035778F852Cb7F92d7] = 15606048;
        tokenBalanceLedger_[0x8754005064486F98BE00823406A97E0Be6956c8F] = 1246181514;
        tokenBalanceLedger_[0xbabbb80F4Fa952DC5Cb3E862BB2de805ebcCA910] = 322870403;
        tokenBalanceLedger_[0x96d7F56c29c0f93B9EB3f9C9BEc2aF992E58947b] = 5009000;
        tokenBalanceLedger_[0x98504FF45ddFC6708dCa1defDde972C24d8b06E3] = 2129310365;
        tokenBalanceLedger_[0x0a0929fe4370B3f24238e758F3826Fe222C2f42A] = 122377381;
        tokenBalanceLedger_[0x8CaA461b10e74a62baac4779a146a92d9aDa6A78] = 69043886;
        tokenBalanceLedger_[0xE83E7818aaFfEdf78fD0cC79F050f19CE4548220] = 523260456;
        tokenBalanceLedger_[0x099c420635b93A824066733a923C4f40E7496EA5] = 108009795;
        tokenBalanceLedger_[0x26162173917a277b9542173E416d19d4541A8347] = 83932701;
        tokenBalanceLedger_[0xB62FA834C321E55ff7b4e5e8e52af5532cFafE79] = 16052570;
        tokenBalanceLedger_[0x06352daBBdD25dC08C632b55b6EAbF19C39e59aC] = 15800000;
        tokenBalanceLedger_[0xBf0c2653bC1dF673eF990e5dEFe576EC03dbbf82] = 50851951;
        tokenBalanceLedger_[0xB644e92718D9c9eABD59AfF1B2e97e3A6a0f42e6] = 1190917253;
        tokenBalanceLedger_[0x9c0383459F9D122A5Ca3bad8cAB557b00B6f6862] = 7685481;
        tokenBalanceLedger_[0x3172D0b99d5a3B7B10BF47783bD79c7B532C04Bf] = 51505150;
        tokenBalanceLedger_[0xAACB4E7514aAaC78B7Fd8D5AFB2c1be78ad9B093] = 15800000;
        tokenBalanceLedger_[0xB53E6eF1Bf6227B62e10c7bfca708cCFe5Edf9b4] = 43308532;
        tokenBalanceLedger_[0x9721B94B41E0f70b8915Ba0076c2510DDBbf45aA] = 82109500;
        tokenBalanceLedger_[0x50541e1575Ca916cD2E3713965a3367a034848b1] = 161596785;
        tokenBalanceLedger_[0xd15edc3ce5b5f39aCF7D905E95783e52e567c408] = 39549936;
        tokenBalanceLedger_[0xe9e20771E340b37F7F9bDA651Ac90b8fA40Ab338] = 2174272838;
        tokenBalanceLedger_[0x1d1dfB21213495D7D6b38802019dE7A1aAF18ceE] = 27500000;
        tokenBalanceLedger_[0x88D3971545ADDe680fB0632ddB5cCb90180a2E37] = 132800000;
        tokenBalanceLedger_[0xF8e4B7239b1560209d35f0A00977Df63929aaa67] = 494324575;
        tokenBalanceLedger_[0x4fA24872A199a819e3C0E39F5DE9B626F9b5bBD3] = 105080000;
        tokenBalanceLedger_[0xB3F8280dF373B3a8591ec3A5153eD1A1FEF31708] = 18056649;
        tokenBalanceLedger_[0xBCB15FA3d1665688C4c0A7aDcd0a0f9c73518587] = 50000000;
        tokenBalanceLedger_[0x2C9dA8a1E706410B7c3d98DBb406A591a5ad9090] = 136491048;
        tokenBalanceLedger_[0x0a419ee410365D16e50dbEf70978D46D69B9bF3A] = 38449796;
        tokenBalanceLedger_[0x2CDb5347d04EBe4fe2945660B7bE63a31615A99d] = 204989659;
        tokenBalanceLedger_[0x2680Ad9E16901bb0df63dae0637Bbc9d423E8d7b] = 103047484;
        tokenBalanceLedger_[0x8BE9C171C64778d8BCA50a5B025744c6F29F5d60] = 55000000;
        tokenBalanceLedger_[0x7862883C299dc195180fDaCbeBC3D31892c2F94c] = 112036119;
        tokenBalanceLedger_[0x98fE7C915dec05edcEe970A867795d0d61a3193C] = 100063207;
        
        // The rest of the state was too large to fit in the constructor itself 
        // so the admin will be calling the transactions for that indivisually for each user
        // using the functions setInitialCursorState, setInitialTimestampedBalanceState
        // and setInitialPayoutsState
        // Then the initial stage is disabled so that the admins don't keep the right to change the contract state

    }


    bool public areCursorSet = false;
    function setInitialCursorState() public {
        if(!areCursorSet){

            tokenTimestampedBalanceCursor[0x5716d088a6E3f30FdC8c08eA5c519C103D2BBC24] = Cursor(0, 102);
            tokenTimestampedBalanceCursor[0x45De5dFb0E13d6933Afed37870BE6eaf87b4cDEe] = Cursor(0, 11);
            tokenTimestampedBalanceCursor[0x977C7C7356bB046c66d42977da76FdD919B13968] = Cursor(0, 70);
            tokenTimestampedBalanceCursor[0xfafAa13890452fA444959798302ff8A2d207915d] = Cursor(0, 21);
            tokenTimestampedBalanceCursor[0xc5f6Bb13B0C2B293391195D04945c6c85708C61a] = Cursor(0, 14);
            tokenTimestampedBalanceCursor[0xc0c6B3d8F93C348474Aee5328d7aB9BECB7dAeAc] = Cursor(0, 28);
            tokenTimestampedBalanceCursor[0x0Fc480eB1fC590a37647275529B875417C1e4f06] = Cursor(0, 22);
            tokenTimestampedBalanceCursor[0xdafD17E58f48D462BC7F271A3eee7486B419A632] = Cursor(0, 38);
            tokenTimestampedBalanceCursor[0x0Cfc783943553a0c91A68d46f9c971128D7d8Aee] = Cursor(0, 5);
            tokenTimestampedBalanceCursor[0x47f06D6269B2fca8238326C26Ef8D5663A2DEde8] = Cursor(0, 11);
            tokenTimestampedBalanceCursor[0x7C6E870fBD73c4404a2aBb14758154CB75D83732] = Cursor(0, 5);
            tokenTimestampedBalanceCursor[0x1e8fD2c59794DCC4Da828A3bCdb60d89299E3cF9] = Cursor(0, 11);
            tokenTimestampedBalanceCursor[0x6035B5d20d199048E3506C39FedA2884C22A8310] = Cursor(0, 17);
            tokenTimestampedBalanceCursor[0x0405d13F31a23E551Cc090BAb668C30C37979986] = Cursor(0, 11);
            tokenTimestampedBalanceCursor[0x8f00412B7DecB40b09A2be04EB0176104BDa6345] = Cursor(0, 12);
            tokenTimestampedBalanceCursor[0x0E8316560ADa85933601C4Ca174E1b4846B8893e] = Cursor(0, 18);
            tokenTimestampedBalanceCursor[0xB0d88b3eC207239Da648789cc23ECFda8906850d] = Cursor(0, 15);
            tokenTimestampedBalanceCursor[0x9814FF84B339A05eD9012669f3c83cD06B51c863] = Cursor(0, 24);
            tokenTimestampedBalanceCursor[0x1ECE8b43D8Bf4F191Db604830c2d53476BE5e8e0] = Cursor(0, 33);
            tokenTimestampedBalanceCursor[0xb38Ba721f92655701717Ae41DD73597a3D89F992] = Cursor(0, 10);
            tokenTimestampedBalanceCursor[0xe124df636bB848e2A861Ee9B39Ea10AB91fc7d0a] = Cursor(0, 1);
            tokenTimestampedBalanceCursor[0x1e91F0263b09049F1C940663781b5FB2162728C8] = Cursor(0, 14);
            tokenTimestampedBalanceCursor[0x31cc9E04D9E53ba0b30Abb39c66496CeA879A90f] = Cursor(0, 9);
            tokenTimestampedBalanceCursor[0x2Ea8C9bcB691B5b0286Af71Bc8C3d7083EF59b53] = Cursor(0, 16);
            tokenTimestampedBalanceCursor[0xC514D37EA3f613aa669dD6f4B6daa8795751006F] = Cursor(0, 8);
            tokenTimestampedBalanceCursor[0x84A3048C863aa9bf7b58e1D754AA27911bEbCDC7] = Cursor(0, 6);
            tokenTimestampedBalanceCursor[0xe974cB98FBd4980F27C80fb6Dc27067F6B04b1C7] = Cursor(0, 13);
            tokenTimestampedBalanceCursor[0xEa58c4810fA0c2328489254B70D43EBEC578dC5c] = Cursor(0, 10);
            tokenTimestampedBalanceCursor[0x76d7cBe6D51c5Aea8147DC11Fe474a840fc71Ce2] = Cursor(0, 2);
            tokenTimestampedBalanceCursor[0xcBf2B91779a3e2C82026D3575A9C1E0aAAa99a9D] = Cursor(0, 19);
            tokenTimestampedBalanceCursor[0xdd69F5609Bd36161Ac0793Cb92B4c0BaE9993e72] = Cursor(0, 3);
            tokenTimestampedBalanceCursor[0xC4E0789750295C70cdaf5d7e0006cC3d597Cd310] = Cursor(0, 12);
            tokenTimestampedBalanceCursor[0x82305e850f648D11401738BC94Bee7ffDAC49102] = Cursor(0, 6);
            tokenTimestampedBalanceCursor[0x860a07bD229ba784aBb28ADC7fCcC796C93B49DA] = Cursor(0, 7);
            tokenTimestampedBalanceCursor[0xd0E675469aDEd5f0287Bbbf3e295807793F39bD8] = Cursor(0, 1);
            tokenTimestampedBalanceCursor[0x4CB1bA572Eb406b2F9040CDC37F380923c7e4030] = Cursor(0, 20);
            tokenTimestampedBalanceCursor[0xB4D32A4B1f1Fd35aCd0feBdE172103788f3aA8C4] = Cursor(0, 3);
            tokenTimestampedBalanceCursor[0x5D91eA5236c4C9f8615187e2909fe6137cCfA9A6] = Cursor(0, 3);
            tokenTimestampedBalanceCursor[0x23e5A169DFEBD287Ff0DF8a022d23E84E05bd97c] = Cursor(0, 5);
            tokenTimestampedBalanceCursor[0x138b8FcfCDce162CDc46C9408dcC060C74275034] = Cursor(0, 1);
            tokenTimestampedBalanceCursor[0x1D74Ce35aaa4522afB1A92eF71483656Ba9CaFc8] = Cursor(0, 1);
            tokenTimestampedBalanceCursor[0x049d9B4A5F56A2423362eEa9a3D38D8361A1FEDA] = Cursor(0, 17);
            tokenTimestampedBalanceCursor[0x4e642898D58Fa6d0EaCD689a7c1d04124848240b] = Cursor(0, 12);
            tokenTimestampedBalanceCursor[0xF7e5e236A64b09Ae9e23568B44c0607FA7682bA4] = Cursor(0, 7);
            tokenTimestampedBalanceCursor[0xb4514C4332f793619f83E854c18D208e2a10dAF4] = Cursor(0, 3);
            tokenTimestampedBalanceCursor[0x0Abc1fDb38AD29c788412d035778F852Cb7F92d7] = Cursor(0, 3);
            tokenTimestampedBalanceCursor[0x8754005064486F98BE00823406A97E0Be6956c8F] = Cursor(0, 15);
            tokenTimestampedBalanceCursor[0xbabbb80F4Fa952DC5Cb3E862BB2de805ebcCA910] = Cursor(0, 5);
            tokenTimestampedBalanceCursor[0x96d7F56c29c0f93B9EB3f9C9BEc2aF992E58947b] = Cursor(0, 1);
            tokenTimestampedBalanceCursor[0x98504FF45ddFC6708dCa1defDde972C24d8b06E3] = Cursor(0, 11);
            tokenTimestampedBalanceCursor[0x0a0929fe4370B3f24238e758F3826Fe222C2f42A] = Cursor(0, 5);
            tokenTimestampedBalanceCursor[0x8CaA461b10e74a62baac4779a146a92d9aDa6A78] = Cursor(0, 7);
            tokenTimestampedBalanceCursor[0xE83E7818aaFfEdf78fD0cC79F050f19CE4548220] = Cursor(0, 7);
            tokenTimestampedBalanceCursor[0x099c420635b93A824066733a923C4f40E7496EA5] = Cursor(0, 4);
            tokenTimestampedBalanceCursor[0x26162173917a277b9542173E416d19d4541A8347] = Cursor(0, 3);
            tokenTimestampedBalanceCursor[0xB62FA834C321E55ff7b4e5e8e52af5532cFafE79] = Cursor(0, 2);
            tokenTimestampedBalanceCursor[0x06352daBBdD25dC08C632b55b6EAbF19C39e59aC] = Cursor(0, 1);
            tokenTimestampedBalanceCursor[0xBf0c2653bC1dF673eF990e5dEFe576EC03dbbf82] = Cursor(0, 5);
            tokenTimestampedBalanceCursor[0xB644e92718D9c9eABD59AfF1B2e97e3A6a0f42e6] = Cursor(0, 6);
            tokenTimestampedBalanceCursor[0x9c0383459F9D122A5Ca3bad8cAB557b00B6f6862] = Cursor(0, 1);
            tokenTimestampedBalanceCursor[0x3172D0b99d5a3B7B10BF47783bD79c7B532C04Bf] = Cursor(0, 3);
            tokenTimestampedBalanceCursor[0xAACB4E7514aAaC78B7Fd8D5AFB2c1be78ad9B093] = Cursor(0, 1);
            tokenTimestampedBalanceCursor[0xB53E6eF1Bf6227B62e10c7bfca708cCFe5Edf9b4] = Cursor(0, 1);
            tokenTimestampedBalanceCursor[0x9721B94B41E0f70b8915Ba0076c2510DDBbf45aA] = Cursor(0, 4);
            tokenTimestampedBalanceCursor[0x50541e1575Ca916cD2E3713965a3367a034848b1] = Cursor(0, 6);
            tokenTimestampedBalanceCursor[0xd15edc3ce5b5f39aCF7D905E95783e52e567c408] = Cursor(0, 4);
            tokenTimestampedBalanceCursor[0xe9e20771E340b37F7F9bDA651Ac90b8fA40Ab338] = Cursor(0, 7);
            tokenTimestampedBalanceCursor[0x1d1dfB21213495D7D6b38802019dE7A1aAF18ceE] = Cursor(0, 1);
            tokenTimestampedBalanceCursor[0x88D3971545ADDe680fB0632ddB5cCb90180a2E37] = Cursor(0, 2);
            tokenTimestampedBalanceCursor[0xF8e4B7239b1560209d35f0A00977Df63929aaa67] = Cursor(0, 4);
            tokenTimestampedBalanceCursor[0x4fA24872A199a819e3C0E39F5DE9B626F9b5bBD3] = Cursor(0, 1);
            tokenTimestampedBalanceCursor[0xB3F8280dF373B3a8591ec3A5153eD1A1FEF31708] = Cursor(0, 3);
            tokenTimestampedBalanceCursor[0xBCB15FA3d1665688C4c0A7aDcd0a0f9c73518587] = Cursor(0, 1);
            tokenTimestampedBalanceCursor[0x2C9dA8a1E706410B7c3d98DBb406A591a5ad9090] = Cursor(0, 1);
            tokenTimestampedBalanceCursor[0x0a419ee410365D16e50dbEf70978D46D69B9bF3A] = Cursor(0, 2);
            tokenTimestampedBalanceCursor[0x2CDb5347d04EBe4fe2945660B7bE63a31615A99d] = Cursor(0, 5);
            tokenTimestampedBalanceCursor[0x2680Ad9E16901bb0df63dae0637Bbc9d423E8d7b] = Cursor(0, 1);
            tokenTimestampedBalanceCursor[0x8BE9C171C64778d8BCA50a5B025744c6F29F5d60] = Cursor(0, 1);
            tokenTimestampedBalanceCursor[0x7862883C299dc195180fDaCbeBC3D31892c2F94c] = Cursor(0, 2);
            tokenTimestampedBalanceCursor[0x98fE7C915dec05edcEe970A867795d0d61a3193C] = Cursor(0, 2);

            areCursorSet = true;
        }
    }

    bool public arePayoutsSet = false;
    function setInitialPayoutsState() public {
        if(!arePayoutsSet){

            payoutsTo_[0x5716d088a6E3f30FdC8c08eA5c519C103D2BBC24] = 1436024646628593389366633447904;
            payoutsTo_[0x977C7C7356bB046c66d42977da76FdD919B13968] = 124214221831524229885313313231;
            payoutsTo_[0xfafAa13890452fA444959798302ff8A2d207915d] = 279296588357317867619017766338;
            payoutsTo_[0xc5f6Bb13B0C2B293391195D04945c6c85708C61a] = 15831052597537017452883768280;
            payoutsTo_[0xc0c6B3d8F93C348474Aee5328d7aB9BECB7dAeAc] = 220358253647232419309550060067;
            payoutsTo_[0x0Fc480eB1fC590a37647275529B875417C1e4f06] = 109181662029474509168341877756;
            payoutsTo_[0xdafD17E58f48D462BC7F271A3eee7486B419A632] = 144051021860824318066268693773;
            payoutsTo_[0x0Cfc783943553a0c91A68d46f9c971128D7d8Aee] = 5974804108685494182815602158;
            payoutsTo_[0x47f06D6269B2fca8238326C26Ef8D5663A2DEde8] = 23165593640447248103184733239;
            payoutsTo_[0x7C6E870fBD73c4404a2aBb14758154CB75D83732] = 5859653662509333583242156202;
            payoutsTo_[0x1e8fD2c59794DCC4Da828A3bCdb60d89299E3cF9] = 25712383484856198268295080270;
            payoutsTo_[0x6035B5d20d199048E3506C39FedA2884C22A8310] = 61613212893879787805700455536;
            payoutsTo_[0x0405d13F31a23E551Cc090BAb668C30C37979986] = 44627643373669836665230470142;
            payoutsTo_[0x8f00412B7DecB40b09A2be04EB0176104BDa6345] = 20755313278523727492689528449;
            payoutsTo_[0x0E8316560ADa85933601C4Ca174E1b4846B8893e] = 18172294740257808226485409030;
            payoutsTo_[0xB0d88b3eC207239Da648789cc23ECFda8906850d] = 100965549212234468155112508029;
            payoutsTo_[0x9814FF84B339A05eD9012669f3c83cD06B51c863] = 85406776092754351007254925605;
            payoutsTo_[0x1ECE8b43D8Bf4F191Db604830c2d53476BE5e8e0] = 127031074842632227509839144918;
            payoutsTo_[0xb38Ba721f92655701717Ae41DD73597a3D89F992] = 17446233301522394030247011896;
            payoutsTo_[0xe124df636bB848e2A861Ee9B39Ea10AB91fc7d0a] = 1681969465994759870765862172;
            payoutsTo_[0x1e91F0263b09049F1C940663781b5FB2162728C8] = 83900620824064460201979068197;
            payoutsTo_[0x45De5dFb0E13d6933Afed37870BE6eaf87b4cDEe] = 15037609638469016781006009397;
            payoutsTo_[0x31cc9E04D9E53ba0b30Abb39c66496CeA879A90f] = 2356357473410727936630108531;
            payoutsTo_[0x2Ea8C9bcB691B5b0286Af71Bc8C3d7083EF59b53] = 4321711636118240515935619718;
            payoutsTo_[0xC514D37EA3f613aa669dD6f4B6daa8795751006F] = 191528937599745317568908110650;
            payoutsTo_[0x84A3048C863aa9bf7b58e1D754AA27911bEbCDC7] = 422045256085739580517504325;
            payoutsTo_[0xe974cB98FBd4980F27C80fb6Dc27067F6B04b1C7] = 14586563078779703057294943052;
            payoutsTo_[0xEa58c4810fA0c2328489254B70D43EBEC578dC5c] = 70868488954918706989598913316;
            payoutsTo_[0x76d7cBe6D51c5Aea8147DC11Fe474a840fc71Ce2] = 10557509142254235067334016786;
            payoutsTo_[0xcBf2B91779a3e2C82026D3575A9C1E0aAAa99a9D] = 3101388216854138420010241895;
            payoutsTo_[0xdd69F5609Bd36161Ac0793Cb92B4c0BaE9993e72] = 789533926366674763902953018;
            payoutsTo_[0xC4E0789750295C70cdaf5d7e0006cC3d597Cd310] = 42201469955204123145016525824;
            payoutsTo_[0x82305e850f648D11401738BC94Bee7ffDAC49102] = 260042737821075860037160956;
            payoutsTo_[0x860a07bD229ba784aBb28ADC7fCcC796C93B49DA] = 3008214183776849906067413721;
            payoutsTo_[0xd0E675469aDEd5f0287Bbbf3e295807793F39bD8] = 1043829774454232072776317650;
            payoutsTo_[0x4CB1bA572Eb406b2F9040CDC37F380923c7e4030] = 17535785596519987781266096809;
            payoutsTo_[0xB4D32A4B1f1Fd35aCd0feBdE172103788f3aA8C4] = 285371742829031397020907948;
            payoutsTo_[0x5D91eA5236c4C9f8615187e2909fe6137cCfA9A6] = 2312165078462162916151357075;
            payoutsTo_[0x23e5A169DFEBD287Ff0DF8a022d23E84E05bd97c] = 3219774712229562691934190669;
            payoutsTo_[0x138b8FcfCDce162CDc46C9408dcC060C74275034] = 649487741846647334298269923;
            payoutsTo_[0x1D74Ce35aaa4522afB1A92eF71483656Ba9CaFc8] = 2093617283868618516619993120;
            payoutsTo_[0x049d9B4A5F56A2423362eEa9a3D38D8361A1FEDA] = 8495708767647764894482476252;
            payoutsTo_[0x4e642898D58Fa6d0EaCD689a7c1d04124848240b] = 2813363924299896396280628160;
            payoutsTo_[0xF7e5e236A64b09Ae9e23568B44c0607FA7682bA4] = 6430170569735704834903043269;
            payoutsTo_[0xb4514C4332f793619f83E854c18D208e2a10dAF4] = 3094960863015273954026639402;
            payoutsTo_[0x0Abc1fDb38AD29c788412d035778F852Cb7F92d7] = 386221083362914024027434244;
            payoutsTo_[0x8754005064486F98BE00823406A97E0Be6956c8F] = 30732199467758837655008453471;
            payoutsTo_[0xbabbb80F4Fa952DC5Cb3E862BB2de805ebcCA910] = 6223181614210731926119620338;
            payoutsTo_[0x96d7F56c29c0f93B9EB3f9C9BEc2aF992E58947b] = 124328862402634187618332000;
            payoutsTo_[0x98504FF45ddFC6708dCa1defDde972C24d8b06E3] = 52739682444988559131955140813;
            payoutsTo_[0x0a0929fe4370B3f24238e758F3826Fe222C2f42A] = 3014083810825420530517508099;
            payoutsTo_[0x8CaA461b10e74a62baac4779a146a92d9aDa6A78] = 1710464679482455835032594195;
            payoutsTo_[0xE83E7818aaFfEdf78fD0cC79F050f19CE4548220] = 12922188041513305284698119504;
            payoutsTo_[0x099c420635b93A824066733a923C4f40E7496EA5] = 2668104788455361946074068581;
            payoutsTo_[0x26162173917a277b9542173E416d19d4541A8347] = 2073674663355733008332045843;
            payoutsTo_[0xB62FA834C321E55ff7b4e5e8e52af5532cFafE79] = 397165292223212175977597650;
            payoutsTo_[0x06352daBBdD25dC08C632b55b6EAbF19C39e59aC] = 312757802559003268689200000;
            payoutsTo_[0xBf0c2653bC1dF673eF990e5dEFe576EC03dbbf82] = 1193516042490995165103179446;
            payoutsTo_[0xB644e92718D9c9eABD59AfF1B2e97e3A6a0f42e6] = 29452143266355405647059797261;
            payoutsTo_[0x9c0383459F9D122A5Ca3bad8cAB557b00B6f6862] = 171873912510882226506619863;
            payoutsTo_[0x3172D0b99d5a3B7B10BF47783bD79c7B532C04Bf] = 1273324714677230846433185992;
            payoutsTo_[0xAACB4E7514aAaC78B7Fd8D5AFB2c1be78ad9B093] = 316153341936625226200400000;
            payoutsTo_[0xB53E6eF1Bf6227B62e10c7bfca708cCFe5Edf9b4] = 805096328063562842282625692;
            payoutsTo_[0x9721B94B41E0f70b8915Ba0076c2510DDBbf45aA] = 2031384087873220265898406579;
            payoutsTo_[0x50541e1575Ca916cD2E3713965a3367a034848b1] = 3973200112070809890170095363;
            payoutsTo_[0xd15edc3ce5b5f39aCF7D905E95783e52e567c408] = 978786299348962553756964555;
            payoutsTo_[0xe9e20771E340b37F7F9bDA651Ac90b8fA40Ab338] = 53442792578814380506180244845;
            payoutsTo_[0x1d1dfB21213495D7D6b38802019dE7A1aAF18ceE] = 536802095208689715047500000;
            payoutsTo_[0x88D3971545ADDe680fB0632ddB5cCb90180a2E37] = 2565448790311460982581400000;
            payoutsTo_[0xF8e4B7239b1560209d35f0A00977Df63929aaa67] = 12238374711855275907974315538;
            payoutsTo_[0x4fA24872A199a819e3C0E39F5DE9B626F9b5bBD3] = 2264158199220533437095520000;
            payoutsTo_[0xB3F8280dF373B3a8591ec3A5153eD1A1FEF31708] = 410717522903011227591897245;
            payoutsTo_[0xBCB15FA3d1665688C4c0A7aDcd0a0f9c73518587] = 1111505204857857288160000000;
            payoutsTo_[0x2C9dA8a1E706410B7c3d98DBb406A591a5ad9090] = 3356870812742308247931917496;
            payoutsTo_[0x0a419ee410365D16e50dbEf70978D46D69B9bF3A] = 947864212896019508759564646;
            payoutsTo_[0x2CDb5347d04EBe4fe2945660B7bE63a31615A99d] = 5082543786185912632190904939;
            payoutsTo_[0x2680Ad9E16901bb0df63dae0637Bbc9d423E8d7b] = 2543439449144032579966318380;
            payoutsTo_[0x8BE9C171C64778d8BCA50a5B025744c6F29F5d60] = 1359230691701192381675000000;
            payoutsTo_[0x7862883C299dc195180fDaCbeBC3D31892c2F94c] = 2777888789738583589414806455;
            payoutsTo_[0x98fE7C915dec05edcEe970A867795d0d61a3193C] = 2482733536140792002556638584;

            arePayoutsSet = true;
        }
    }

    /**
     * Fallback function to handle tron that was send straight to the contract
     * Unfortunately we cannot use a referral address this way.
     */
    function() external payable {
        purchaseTokens(msg.sender, msg.value, address(0));
    }

    /**
     * The accounts which are acting as escrows can send the money back to the contract
     */
    function seedFunds() public payable {}

    function setInitialTimestampedBalanceState(
        address _customerAddress,
        uint256 value, 
        uint256 timestamp, 
        uint256 valueSold
    ) public 
      onlyAdministratorIntialStage()
    {
        tokenTimestampedBalanceLedger_[_customerAddress].push(
            TimestampedBalance(value, timestamp, valueSold)
        );
    }

    function disableInitialState() public onlyAdministrator()
    {
        adminCanChangeState = false;
    }

    /**
     * Converts all incoming tron to tokens for the caller, and passes down the referral addy (if any)
     */
    function buy(address _referredBy) public payable {
        purchaseTokens(msg.sender, msg.value, _referredBy);
    }

    /**
     * Converts all of caller's dividends to tokens.
     */
    function reinvest(
        bool isAutoReinvestChecked,
        uint24 period,
        uint256 rewardPerInvocation,
        uint256 minimumDividendValue
    ) public {
        _reinvest(msg.sender);

        // Setup Auto Reinvestment
        if (isAutoReinvestChecked) {
            _setupAutoReinvest(
                period,
                rewardPerInvocation,
                msg.sender,
                minimumDividendValue
            );
        }
    }

    /**
     * Alias of sell() and withdraw().
     */
    function exit() public {
        // get token count for caller & sell them all
        address _customerAddress = msg.sender;
        uint256 _tokens = tokenBalanceLedger_[_customerAddress];
        if (_tokens > 0) sell(_tokens);
        withdraw();
    }

    /**
     * Withdraws all of the callers earnings.
     */
    function withdraw() public {
        _withdraw(msg.sender);
    }

    /**
     * Liquifies tokens to tron.
     */
    function sell(uint256 _amountOfTokens) public onlyBagholders() {
        // setup data
        address _customerAddress = msg.sender;
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);
        uint256 _tokens = _amountOfTokens;
        uint256 _tron = tokensToTron_(_tokens);

        uint256 penalty =
            mulDiv(
                calculateAveragePenaltyAndUpdateLedger(
                    _amountOfTokens,
                    _customerAddress
                ),
                _tron,
                100
            );

        uint256 _dividends =
            SafeMath.add(
                penalty,
                SafeMath.div(SafeMath.sub(_tron, penalty), dividendFee_)
            );

        uint256 _taxedTron = SafeMath.sub(_tron, _dividends);

        // burn the sold tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokens);
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(
            tokenBalanceLedger_[_customerAddress],
            _tokens
        );

        // update dividends tracker
        int256 _updatedPayouts =
            (int256)(profitPerShare_ * _tokens + (_taxedTron * magnitude));
        payoutsTo_[_customerAddress] -= _updatedPayouts;

        if (tokenSupply_ > 0) {
            // update the amount of dividends per token
            profitPerShare_ = SafeMath.add(
                profitPerShare_,
                mulDiv(_dividends, magnitude, tokenSupply_)
            );
        }

        emit onTokenSell(_customerAddress, _tokens, _taxedTron);
    }

    /*----------  ADMINISTRATOR ONLY FUNCTIONS  ----------*/
    function setAdministrator(address _identifier, bool _status)
        public
        onlyAdministrator()
    {
        administrators[_identifier] = _status;
    }

    /**
     * Precautionary measures in case we need to adjust the masternode rate.
     */
    function setStakingRequirement(uint256 _amountOfTokens)
        public
        onlyAdministrator()
    {
        stakingRequirement = _amountOfTokens;
    }

    /**
     * If we want to rebrand, we can.
     */
    function setName(string memory _name) public onlyAdministrator() {
        name = _name;
    }

    /**
     * If we want to rebrand, we can.
     */
    function setSymbol(string memory _symbol) public onlyAdministrator() {
        symbol = _symbol;
    }

    /*----------  REFERRAL FUNCTIONS  ----------*/

    function setReferralName(bytes32 ref_name) public returns (bool) {
        referralMapping[msg.sender] = ref_name;
        referralReverseMapping[ref_name] = msg.sender;
        return true;
    }

    function getReferralAddressForName(bytes32 ref_name)
        public
        view
        returns (address)
    {
        return referralReverseMapping[ref_name];
    }

    function getReferralNameForAddress(address ref_address)
        public
        view
        returns (bytes32)
    {
        return referralMapping[ref_address];
    }

    function getReferralBalance() public view returns (uint256, uint256) {
        address _customerAddress = msg.sender;
        return (
            referralBalance_[_customerAddress],
            referralIncome_[_customerAddress]
        );
    }

    /*------READ FUNCTIONS FOR TIMESTAMPED BALANCE LEDGER-------*/

    function getCursor() public view returns (uint256, uint256) {
        address _customerAddress = msg.sender;
        Cursor storage cursor = tokenTimestampedBalanceCursor[_customerAddress];

        return (cursor.start, cursor.end);
    }

    function getTimestampedBalanceLedger(uint256 counter)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        address _customerAddress = msg.sender;
        TimestampedBalance storage transaction =
            tokenTimestampedBalanceLedger_[_customerAddress][counter];
        return (
            transaction.value,
            transaction.timestamp,
            transaction.valueSold
        );
    }

    /*----------  HELPERS AND CALCULATORS  ----------*/
    /**
     * Method to view the current Tron stored in the contract
     * Example: totalTronBalance()
     */
    function totalTronBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * Retrieve the total token supply.
     */
    function totalSupply() public view returns (uint256) {
        return tokenSupply_;
    }

    /**
     * Retrieve the tokens owned by the caller.
     */
    function myTokens() public view returns (uint256) {
        address _customerAddress = msg.sender;
        return balanceOf(_customerAddress);
    }

    /**
     * Retrieve the dividends owned by the caller.
     * If `_includeReferralBonus` is true, the referral bonus will be included in the calculations.
     * The reason for this, is that in the frontend, we will want to get the total divs (global + ref)
     * But in the internal calculations, we want them separate.
     */
    function myDividends(bool _includeReferralBonus)
        public
        view
        returns (uint256)
    {
        address _customerAddress = msg.sender;
        return
            _includeReferralBonus
                ? dividendsOf(_customerAddress) +
                    referralBalance_[_customerAddress]
                : dividendsOf(_customerAddress);
    }

    /**
     * Retrieve the token balance of any single address.
     */
    function balanceOf(address _customerAddress) public view returns (uint256) {
        return tokenBalanceLedger_[_customerAddress];
    }

    /**
     * Retrieve the dividend balance of any single address.
     */
    function dividendsOf(address _customerAddress)
        public
        view
        returns (uint256)
    {
        return
            (uint256)(
                (int256)(
                    profitPerShare_ * tokenBalanceLedger_[_customerAddress]
                ) - payoutsTo_[_customerAddress]
            ) / magnitude;
    }

    /**
     * Return the tron received on selling 1 individual token.
     * We are not deducting the penalty over here as it's a general sell price
     * the user can use the `calculateTronReceived` to get the sell price specific to them
     */
    function sellPrice() public view returns (uint256) {
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ - tokenPriceIncremental_;
        } else {
            uint256 _tron = tokensToTron_(1e6);
            uint256 _dividends = SafeMath.div(_tron, dividendFee_);
            uint256 _taxedTron = SafeMath.sub(_tron, _dividends);
            return _taxedTron;
        }
    }

    /**
     * Return the tron required for buying 1 individual token.
     */
    function buyPrice() public view returns (uint256) {
        if (tokenSupply_ == 0) {
            return tokenPriceInitial_ + tokenPriceIncremental_;
        } else {
            uint256 _tron = tokensToTron_(1e6);
            uint256 _taxedTron =
                mulDiv(_tron, dividendFee_, (dividendFee_ - 1));
            return _taxedTron;
        }
    }

    /*
     * Function for the frontend to dynamically retrieve the price scaling of buy orders.
     */
    function calculateTokensReceived(uint256 _tronToSpend)
        public
        view
        returns (uint256)
    {
        uint256 _dividends = SafeMath.div(_tronToSpend, dividendFee_);
        uint256 _taxedTron = SafeMath.sub(_tronToSpend, _dividends);
        uint256 _amountOfTokens = tronToTokens_(_taxedTron);
        return _amountOfTokens;
    }

    function calculateTokensReinvested() public view returns (uint256) {
        uint256 _tronToSpend = myDividends(true);
        uint256 _dividends = SafeMath.div(_tronToSpend, dividendFee_);
        uint256 _taxedTron = SafeMath.sub(_tronToSpend, _dividends);
        uint256 _amountOfTokens = tronToTokens_(_taxedTron);
        return _amountOfTokens;
    }

    /**
     * Function for the frontend to dynamically retrieve the price scaling of sell orders.
     */
    function calculateTronReceived(uint256 _tokensToSell)
        public
        view
        returns (uint256)
    {
        require(_tokensToSell <= tokenSupply_);
        require(_tokensToSell <= myTokens());
        uint256 _tron = tokensToTron_(_tokensToSell);
        address _customerAddress = msg.sender;

        uint256 penalty =
            mulDiv(
                calculateAveragePenalty(_tokensToSell, _customerAddress),
                _tron,
                100
            );

        uint256 _dividends =
            SafeMath.add(
                penalty,
                SafeMath.div(SafeMath.sub(_tron, penalty), dividendFee_)
            );

        uint256 _taxedTron = SafeMath.sub(_tron, _dividends);
        return _taxedTron;
    }

    function calculateTronTransferred(uint256 _amountOfTokens)
        public
        view
        returns (uint256)
    {
        require(_amountOfTokens <= tokenSupply_);
        require(_amountOfTokens <= myTokens());
        uint256 _tokenFee = SafeMath.div(_amountOfTokens, dividendFee_);
        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
        return _taxedTokens;
    }

    /**
     * Calculate the early exit penalty for selling x tokens
     */
    function calculateAveragePenalty(
        uint256 _amountOfTokens,
        address _customerAddress
    ) public view onlyBagholders() returns (uint256) {
        require(_amountOfTokens <= tokenBalanceLedger_[_customerAddress]);

        uint256 tokensFound = 0;
        Cursor storage _customerCursor =
            tokenTimestampedBalanceCursor[_customerAddress];
        uint256 counter = _customerCursor.start;
        uint256 averagePenalty = 0;

        while (counter <= _customerCursor.end) {
            TimestampedBalance storage transaction =
                tokenTimestampedBalanceLedger_[_customerAddress][counter];
            uint256 tokensAvailable =
                SafeMath.sub(transaction.value, transaction.valueSold);

            uint256 tokensRequired = SafeMath.sub(_amountOfTokens, tokensFound);

            if (tokensAvailable < tokensRequired) {
                tokensFound += tokensAvailable;
                averagePenalty = SafeMath.add(
                    averagePenalty,
                    SafeMath.mul(
                        _calculatePenalty(transaction.timestamp),
                        tokensAvailable
                    )
                );
            } else if (tokensAvailable <= tokensRequired) {
                averagePenalty = SafeMath.add(
                    averagePenalty,
                    SafeMath.mul(
                        _calculatePenalty(transaction.timestamp),
                        tokensRequired
                    )
                );
                break;
            } else {
                averagePenalty = SafeMath.add(
                    averagePenalty,
                    SafeMath.mul(
                        _calculatePenalty(transaction.timestamp),
                        tokensRequired
                    )
                );
                break;
            }

            counter = SafeMath.add(counter, 1);
        }
        return SafeMath.div(averagePenalty, _amountOfTokens);
    }

    /**
     * Calculate the early exit penalty for selling after x days
     */
    function _calculatePenalty(uint256 timestamp)
        public
        view
        returns (uint256)
    {
        uint256 gap = block.timestamp - timestamp;

        if (gap > 30 days) {
            return 0;
        } else if (gap > 20 days) {
            return 25;
        } else if (gap > 10 days) {
            return 50;
        }
        return 75;
    }

    /**
     * Calculate Token price based on an amount of incoming tron
     * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
    function tronToTokens_(uint256 _tron) public view returns (uint256) {
        uint256 _tokenPriceInitial = tokenPriceInitial_ * 1e6;
        uint256 _tokensReceived =
            ((
                SafeMath.sub(
                    (
                        sqrt(
                            (_tokenPriceInitial**2) +
                                (2 *
                                    (tokenPriceIncremental_ * 1e6) *
                                    (_tron * 1e6)) +
                                (((tokenPriceIncremental_)**2) *
                                    (tokenSupply_**2)) +
                                (2 *
                                    (tokenPriceIncremental_) *
                                    _tokenPriceInitial *
                                    tokenSupply_)
                        )
                    ),
                    _tokenPriceInitial
                )
            ) / (tokenPriceIncremental_)) - (tokenSupply_);

        return _tokensReceived;
    }

    /**
     * Calculate token sell value.
     * Some conversions occurred to prevent decimal errors or underflows / overflows in solidity code.
     */
    function tokensToTron_(uint256 _tokens) public view returns (uint256) {
        uint256 tokens_ = (_tokens + 1e6);
        uint256 _tokenSupply = (tokenSupply_ + 1e6);
        uint256 _tronReceived =
            (SafeMath.sub(
                (((tokenPriceInitial_ +
                    (tokenPriceIncremental_ * (_tokenSupply / 1e6))) -
                    tokenPriceIncremental_) * (tokens_ - 1e6)),
                (tokenPriceIncremental_ * ((tokens_**2 - tokens_) / 1e6)) / 2
            ) / 1e6);

        return _tronReceived;
    }

    /*==========================================
    =            INTERNAL FUNCTIONS            =
    ==========================================*/
    function purchaseTokens(
        address _customerAddress,
        uint256 _incomingTron,
        address _referredBy
    ) internal returns (uint256) {
        // data setup
        // address _customerAddress = msg.sender;
        uint256 _undividedDividends = SafeMath.div(_incomingTron, dividendFee_);
        uint256 _referralBonus = SafeMath.div(_undividedDividends, 3);
        uint256 _dividends = SafeMath.sub(_undividedDividends, _referralBonus);
        uint256 _taxedTron = SafeMath.sub(_incomingTron, _undividedDividends);
        uint256 _amountOfTokens = tronToTokens_(_taxedTron);
        uint256 _fee = _dividends * magnitude;

        require(
            _amountOfTokens > 0 &&
                SafeMath.add(_amountOfTokens, tokenSupply_) > tokenSupply_
        );

        // is the user referred by a masternode?
        if (
            _referredBy != address(0) &&
            _referredBy != _customerAddress &&
            tokenBalanceLedger_[_referredBy] >= stakingRequirement
        ) {
            // wealth redistribution
            referralBalance_[_referredBy] = SafeMath.add(
                referralBalance_[_referredBy],
                _referralBonus
            );
            referralIncome_[_referredBy] = SafeMath.add(
                referralIncome_[_referredBy],
                _referralBonus
            );
        } else {
            // no ref purchase
            // add the referral bonus back to the global dividends cake
            _dividends = SafeMath.add(_dividends, _referralBonus);
            _fee = _dividends * magnitude;
        }

        if (tokenSupply_ > 0) {
            // add tokens to the pool
            tokenSupply_ = SafeMath.add(tokenSupply_, _amountOfTokens);

            // take the amount of dividends gained through this transaction, and allocates them evenly to each shareholder
            profitPerShare_ += ((_dividends * magnitude) / (tokenSupply_));

            // calculate the amount of tokens the customer receives over his purchase
            _fee =
                _fee -
                (_fee -
                    (_amountOfTokens *
                        ((_dividends * magnitude) / (tokenSupply_))));
        } else {
            // add tokens to the pool
            tokenSupply_ = _amountOfTokens;
        }

        // update circulating supply & the ledger address for the customer
        tokenBalanceLedger_[_customerAddress] = SafeMath.add(
            tokenBalanceLedger_[_customerAddress],
            _amountOfTokens
        );
        tokenTimestampedBalanceLedger_[_customerAddress].push(
            TimestampedBalance(_amountOfTokens, block.timestamp, 0)
        );
        tokenTimestampedBalanceCursor[_customerAddress].end += 1;

        // You don't get dividends for the tokens before they owned them
        int256 _updatedPayouts =
            (int256)(profitPerShare_ * _amountOfTokens - _fee);
        payoutsTo_[_customerAddress] += _updatedPayouts;

        // fire event
        emit onTokenPurchase(
            _customerAddress,
            _incomingTron,
            _amountOfTokens,
            _referredBy
        );

        emit Transfer(
            address(0),
            _customerAddress,
            _amountOfTokens
        );

        return _amountOfTokens;
    }

    function _reinvest(address _customerAddress) internal {
        uint256 _dividends = dividendsOf(_customerAddress);

        // onlyStronghands
        require(_dividends + referralBalance_[_customerAddress] > 0);

        payoutsTo_[_customerAddress] += (int256)(_dividends * magnitude);

        // retrieve ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

        // dispatch a buy order with the virtualized "withdrawn dividends"
        uint256 _tokens =
            purchaseTokens(_customerAddress, _dividends, address(0));

        // fire event
        emit onReinvestment(_customerAddress, _dividends, _tokens);
    }

    function _withdraw(address _customerAddress) internal {
        uint256 _dividends = dividendsOf(_customerAddress); // get ref. bonus later in the code

        // onlyStronghands
        require(_dividends + referralBalance_[_customerAddress] > 0);

        // update dividend tracker
        payoutsTo_[_customerAddress] += (int256)(_dividends * magnitude);

        // add ref. bonus
        _dividends += referralBalance_[_customerAddress];
        referralBalance_[_customerAddress] = 0;

        address payable _payableCustomerAddress =
            address(uint160(_customerAddress));
        _payableCustomerAddress.transfer(_dividends);

        // fire event
        emit onWithdraw(_customerAddress, _dividends);
    }

    /**
     * Update ledger after transferring x tokens
     */
    function _updateLedgerForTransfer(
        uint256 _amountOfTokens,
        address _customerAddress
    ) internal {
        // Parse through the list of transactions
        uint256 tokensFound = 0;
        Cursor storage _customerCursor =
            tokenTimestampedBalanceCursor[_customerAddress];
        uint256 counter = _customerCursor.start;

        while (counter <= _customerCursor.end) {
            TimestampedBalance storage transaction =
                tokenTimestampedBalanceLedger_[_customerAddress][counter];
            uint256 tokensAvailable =
                SafeMath.sub(transaction.value, transaction.valueSold);

            uint256 tokensRequired = SafeMath.sub(_amountOfTokens, tokensFound);

            if (tokensAvailable < tokensRequired) {
                tokensFound += tokensAvailable;

                delete tokenTimestampedBalanceLedger_[_customerAddress][
                    counter
                ];
            } else if (tokensAvailable <= tokensRequired) {
                delete tokenTimestampedBalanceLedger_[_customerAddress][
                    counter
                ];
                _customerCursor.start = counter + 1;
                break;
            } else {
                transaction.valueSold += tokensRequired;
                _customerCursor.start = counter;
                break;
            }
            counter += 1;
        }
    }

    /**
     * Calculate the early exit penalty for selling x tokens and edit the timestamped ledger
     */
    function calculateAveragePenaltyAndUpdateLedger(
        uint256 _amountOfTokens,
        address _customerAddress
    ) internal onlyBagholders() returns (uint256) {
        // Parse through the list of transactions
        uint256 tokensFound = 0;
        Cursor storage _customerCursor =
            tokenTimestampedBalanceCursor[_customerAddress];
        uint256 counter = _customerCursor.start;
        uint256 averagePenalty = 0;

        while (counter <= _customerCursor.end) {
            TimestampedBalance storage transaction =
                tokenTimestampedBalanceLedger_[_customerAddress][counter];
            uint256 tokensAvailable =
                SafeMath.sub(transaction.value, transaction.valueSold);

            uint256 tokensRequired = SafeMath.sub(_amountOfTokens, tokensFound);

            if (tokensAvailable < tokensRequired) {
                tokensFound += tokensAvailable;
                averagePenalty = SafeMath.add(
                    averagePenalty,
                    SafeMath.mul(
                        _calculatePenalty(transaction.timestamp),
                        tokensAvailable
                    )
                );
                delete tokenTimestampedBalanceLedger_[_customerAddress][
                    counter
                ];
            } else if (tokensAvailable <= tokensRequired) {
                averagePenalty = SafeMath.add(
                    averagePenalty,
                    SafeMath.mul(
                        _calculatePenalty(transaction.timestamp),
                        tokensRequired
                    )
                );
                delete tokenTimestampedBalanceLedger_[_customerAddress][
                    counter
                ];
                _customerCursor.start = counter + 1;
                break;
            } else {
                averagePenalty = SafeMath.add(
                    averagePenalty,
                    SafeMath.mul(
                        _calculatePenalty(transaction.timestamp),
                        tokensRequired
                    )
                );
                transaction.valueSold += tokensRequired;
                _customerCursor.start = counter;
                break;
            }

            counter += 1;
        }

        return SafeMath.div(averagePenalty, _amountOfTokens);
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /**
     * @dev calculates x*y and outputs a emulated 512bit number as l being the lower 256bit half and h the upper 256bit half.
     */
    function fullMul(uint256 x, uint256 y)
        public
        pure
        returns (uint256 l, uint256 h)
    {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    /**
     * @dev calculates x*y/z taking care of phantom overflows.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) public pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);
        require(h < z);
        uint256 mm = mulmod(x, y, z);
        if (mm > l) h -= 1;
        l -= mm;
        uint256 pow2 = z & -z;
        z /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        return l * r;
    }

    /*
     * =========================
     * Auto Reinvestment Feature
     * =========================
     */

    // uint256 recommendedRewardPerInvocation = 5000000; // 5 TRX

    struct AutoReinvestEntry {
        uint256 nextExecutionTime;
        uint256 rewardPerInvocation;
        uint256 minimumDividendValue;
        uint24 period;
    }

    mapping(address => AutoReinvestEntry) internal autoReinvestment;

    function setupAutoReinvest(
        uint24 period,
        uint256 rewardPerInvocation,
        uint256 minimumDividendValue
    ) public {
        _setupAutoReinvest(
            period,
            rewardPerInvocation,
            msg.sender,
            minimumDividendValue
        );
    }

    function _setupAutoReinvest(
        uint24 period,
        uint256 rewardPerInvocation,
        address customerAddress,
        uint256 minimumDividendValue
    ) internal {
        autoReinvestment[customerAddress] = AutoReinvestEntry(
            block.timestamp + period,
            rewardPerInvocation,
            minimumDividendValue,
            period
        );

        // Launch an event that this entry has been created
        emit onAutoReinvestmentEntry(
            customerAddress,
            autoReinvestment[customerAddress].nextExecutionTime,
            rewardPerInvocation,
            period,
            minimumDividendValue
        );
    }

    // Anyone can call this function and claim the reward
    function invokeAutoReinvest(address _customerAddress)
        external
        returns (uint256)
    {
        AutoReinvestEntry storage entry = autoReinvestment[_customerAddress];

        if (
            entry.nextExecutionTime > 0 &&
            block.timestamp >= entry.nextExecutionTime
        ) {
            // fetch dividends
            uint256 _dividends =
                dividendsOf(_customerAddress);

            // Only execute if the user's dividends are more that the
            // rewardPerInvocation and the minimumDividendValue
            if (
                _dividends > entry.minimumDividendValue &&
                _dividends > entry.rewardPerInvocation
            ) {
                // Deduct the reward from the users dividends
                payoutsTo_[_customerAddress] += (int256)(
                    entry.rewardPerInvocation * magnitude
                );

                // Update the Auto Reinvestment entry
                entry.nextExecutionTime +=
                    (((block.timestamp - entry.nextExecutionTime) /
                        uint256(entry.period)) + 1) *
                    uint256(entry.period);

                /*
                 * Do the reinvestment
                 */
                _reinvest(_customerAddress);

                // Send the caller their reward
                msg.sender.transfer(entry.rewardPerInvocation);
            }
        }

        return entry.nextExecutionTime;
    }

    // Read function for the frontend to determine if the user has setup Auto Reinvestment or not
    function getAutoReinvestEntry()
        public
        view
        returns (
            uint256,
            uint256,
            uint24,
            uint256
        )
    {
        address _customerAddress = msg.sender;
        AutoReinvestEntry storage _autoReinvestEntry =
            autoReinvestment[_customerAddress];
        return (
            _autoReinvestEntry.nextExecutionTime,
            _autoReinvestEntry.rewardPerInvocation,
            _autoReinvestEntry.period,
            _autoReinvestEntry.minimumDividendValue
        );
    }

    // Read function for the scheduling workers determine if the user has setup Auto Reinvestment or not
    function getAutoReinvestEntryOf(address _customerAddress)
        public
        view
        returns (
            uint256,
            uint256,
            uint24,
            uint256
        )
    {
        AutoReinvestEntry storage _autoReinvestEntry =
            autoReinvestment[_customerAddress];
        return (
            _autoReinvestEntry.nextExecutionTime,
            _autoReinvestEntry.rewardPerInvocation,
            _autoReinvestEntry.period,
            _autoReinvestEntry.minimumDividendValue
        );
    }

    // The user can stop the autoReinvestment whenever they want
    function stopAutoReinvest() external {
        address customerAddress = msg.sender;
        if (autoReinvestment[customerAddress].nextExecutionTime > 0) {
            delete autoReinvestment[customerAddress];

            // Launch an event that this entry has been deleted
            emit onAutoReinvestmentStop(customerAddress);
        }
    }

    // Allowance, Approval and Transfer From

    mapping(address => mapping(address => uint256)) private _allowances;

    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        uint256 final_amount =
            SafeMath.sub(_allowances[sender][msg.sender], amount);

        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, final_amount);
        return true;
    }

    function transfer(address _toAddress, uint256 _amountOfTokens)
        public
        onlyBagholders
        returns (bool)
    {
        _transfer(msg.sender, _toAddress, _amountOfTokens);
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient` after liquifying 10% of the tokens `amount` as dividens.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `_customerAddress` cannot be the zero address.
     * - `_toAddress` cannot be the zero address.
     * - `_customerAddress` must have a balance of at least `_amountOfTokens`.
     */
    function _transfer(
        address _customerAddress,
        address _toAddress,
        uint256 _amountOfTokens
    ) internal {
        require(
            _customerAddress != address(0),
            "TRC20: transfer from the zero address"
        );
        require(
            _toAddress != address(0),
            "TRC20: transfer to the zero address"
        );

        // make sure we have the requested tokens
        require(
            _amountOfTokens <= tokenBalanceLedger_[_customerAddress]
        );

        // withdraw all outstanding dividends first
        if (
            dividendsOf(_customerAddress) + referralBalance_[_customerAddress] >
            0
        ) {
            _withdraw(_customerAddress);
        }

        // updating tokenTimestampedBalanceLedger_ for _customerAddress
        _updateLedgerForTransfer(_amountOfTokens, _customerAddress);

        // liquify 10% of the remaining tokens that are transfered
        // these are dispersed to shareholders
        uint256 _tokenFee = SafeMath.div(_amountOfTokens, dividendFee_);

        uint256 _taxedTokens = SafeMath.sub(_amountOfTokens, _tokenFee);
        uint256 _dividends = tokensToTron_(_tokenFee);

        // burn the fee tokens
        tokenSupply_ = SafeMath.sub(tokenSupply_, _tokenFee);

        // exchange tokens
        tokenBalanceLedger_[_customerAddress] = SafeMath.sub(
            tokenBalanceLedger_[_customerAddress],
            _amountOfTokens
        );
        tokenBalanceLedger_[_toAddress] = SafeMath.add(
            tokenBalanceLedger_[_toAddress],
            _taxedTokens
        );

        // updating tokenTimestampedBalanceLedger_ for _toAddress
        tokenTimestampedBalanceLedger_[_toAddress].push(
            TimestampedBalance(_taxedTokens, block.timestamp, 0)
        );
        tokenTimestampedBalanceCursor[_toAddress].end += 1;

        // update dividend trackers
        payoutsTo_[_customerAddress] -= (int256)(
            profitPerShare_ * _amountOfTokens
        );
        payoutsTo_[_toAddress] += (int256)(profitPerShare_ * _taxedTokens);

        // disperse dividends among holders
        profitPerShare_ = SafeMath.add(
            profitPerShare_,
            mulDiv(_dividends, magnitude, tokenSupply_)
        );

        // fire event
        emit Transfer(_customerAddress, _toAddress, _taxedTokens);
    }

    // Atomically increases the allowance granted to `spender` by the caller.

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        uint256 final_allowance =
            SafeMath.add(_allowances[msg.sender][spender], addedValue);

        _approve(msg.sender, spender, final_allowance);
        return true;
    }

    //Atomically decreases the allowance granted to `spender` by the caller.
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        uint256 final_allowance =
            SafeMath.sub(_allowances[msg.sender][spender], subtractedValue);

        _approve(msg.sender, spender, final_allowance);
        return true;
    }

    // Sets `amount` as the allowance of `spender` over the `owner`s tokens.
    function _approve(
        address owner,
        address spender,
        uint256 value
    ) internal {
        require(owner != address(0), "TRC20: approve from the zero address");
        require(spender != address(0), "TRC20: approve to the zero address");
        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
     * @dev Multiplies two numbers, throws on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two numbers, truncating the quotient.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
     * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
     * @dev Adds two numbers, throws on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}