// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;
/*
██████╗ ███████╗ █████╗ ██╗     ██╗████████╗██╗   ██╗ ██████╗ █████╗ ██████╗ ██████╗ ███████╗
██╔══██╗██╔════╝██╔══██╗██║     ██║╚══██╔══╝╚██╗ ██╔╝██╔════╝██╔══██╗██╔══██╗██╔══██╗██╔════╝
██████╔╝█████╗  ███████║██║     ██║   ██║    ╚████╔╝ ██║     ███████║██████╔╝██║  ██║███████╗
██╔══██╗██╔══╝  ██╔══██║██║     ██║   ██║     ╚██╔╝  ██║     ██╔══██║██╔══██╗██║  ██║╚════██║
██║  ██║███████╗██║  ██║███████╗██║   ██║      ██║   ╚██████╗██║  ██║██║  ██║██████╔╝███████║
╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝╚═╝   ╚═╝      ╚═╝    ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝ 
*/
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "hardhat/console.sol";
import "./interfaces/IRealitio.sol";
import "./interfaces/IRCFactory.sol";
import "./interfaces/IRCLeaderboard.sol";
import "./interfaces/IRCTreasury.sol";
import "./interfaces/IRCMarket.sol";
import "./interfaces/IRCNftHubL2.sol";
import "./interfaces/IRCOrderbook.sol";
import "./lib/NativeMetaTransaction.sol";

/// @title Reality Cards Market
/// @author Andrew Stanger & Daniel Chilvers
/// @notice If you have found a bug, please contact [email protected] no hack pls!!
contract RCMarket is Initializable, NativeMetaTransaction, IRCMarket {
    /*╔═════════════════════════════════╗
      ║            VARIABLES            ║
      ╚═════════════════════════════════╝*/

    // CONTRACT SETUP
    uint256 public constant PER_MILLE = 1000; // in MegaBip so (1000 = 100%)
    /// @dev minimum rental value per day, setting to 24mil means 1 USDC/hour
    uint256 public constant MIN_RENTAL_VALUE = 24_000_000;
    /// @dev the number of cards in this market
    uint256 public override numberOfCards;
    /// @dev current market state, Closed -> Open -> Locked -> Withdraw
    States public override state;
    /// @dev type of event.
    Mode public override mode;
    /// @dev so the Factory can check it's a market
    bool public constant override isMarket = true;
    /// @dev how many nfts to award to the leaderboard
    uint256 public override nftsToAward;
    /// @dev the unique token id for each card
    uint256[] public tokenIds;

    // CONTRACT VARIABLES
    IRCTreasury public override treasury;
    IRCFactory public override factory;
    IRCNftHubL2 public override nfthub;
    IRCOrderbook public override orderbook;
    IRCLeaderboard public override leaderboard;
    IRealitio public override realitio;

    // PRICE, DEPOSITS, RENT
    /// @dev keeps track of all the rent paid by each user. So that it can be returned in case of an invalid market outcome.
    mapping(address => uint256) public override rentCollectedPerUser;
    /// @dev keeps track of the rent each user has paid for each card, for Safe mode payout
    mapping(address => mapping(uint256 => uint256))
        public
        override rentCollectedPerUserPerCard;
    /// @dev an easy way to track the above across all cards
    uint256 public override totalRentCollected;
    /// @dev prevents user from exiting and re-renting in the same block (limits troll attacks)
    mapping(address => uint256) public override exitedTimestamp;

    // PARAMETERS
    /// @dev read from the Factory upon market creation, can not be changed for existing market
    /// @dev the minimum required price increase in %
    uint256 public override minimumPriceIncreasePercent;
    /// @dev minimum rental duration (1 day divisor: i.e. 24 = 1 hour, 48 = 30 mins)
    uint256 public override minRentalDayDivisor;
    /// @dev maximum number of times to calculate rent in one transaction
    uint256 public override maxRentIterations;
    /// @dev maximum number of times to calculate rent and continue locking the market
    uint256 public maxRentIterationsToLockMarket;

    struct Card {
        /// @dev how many seconds each user has held each card for, for determining winnings
        mapping(address => uint256) timeHeld;
        /// @dev sums all the timeHelds for each. Used when paying out. Should always increment at the same time as timeHeld
        uint256 totalTimeHeld;
        /// @dev used to determine the rent due. Rent is due for the period (now - timeLastCollected), at which point timeLastCollected is set to now.
        uint256 timeLastCollected;
        /// @dev to track who has owned it the most (for giving NFT to winner)
        address longestOwner;
        /// @dev to track the card timeHeldLimit for the current owner
        uint256 cardTimeLimit;
        /// @dev card price in wei
        uint256 cardPrice;
        /// @dev keeps track of all the rent paid for each card, for card specific affiliate payout
        uint256 rentCollectedPerCard;
        /// @dev prevent users claiming twice
        mapping(address => bool) userAlreadyClaimed; // cardID // user // bool
        /// @dev has this card affiliate been paid
        bool cardAffiliatePaid;
    }
    mapping(uint256 => Card) public override card;

    // TIMESTAMPS
    /// @dev when the market opens
    uint32 public override marketOpeningTime;
    /// @dev when the market locks
    uint32 public override marketLockingTime;
    /// @dev when the question can be answered on realitio
    uint32 public override oracleResolutionTime;

    // PAYOUT VARIABLES
    /// @dev the winning card if known, otherwise type(uint256).max
    uint256 public override winningOutcome;
    /// @dev prevent users withdrawing twice
    mapping(address => bool) public override userAlreadyWithdrawn;
    /// @dev the artist
    address public override artistAddress;
    uint256 public override artistCut;
    bool public override artistPaid;
    /// @dev the affiliate
    address public override affiliateAddress;
    uint256 public override affiliateCut;
    bool public override affiliatePaid;
    /// @dev the winner
    uint256 public override winnerCut;
    /// @dev the market creator
    address public override marketCreatorAddress;
    uint256 public override creatorCut;
    bool public override creatorPaid;
    /// @dev card specific recipients
    address[] public override cardAffiliateAddresses;
    uint256 public override cardAffiliateCut;
    /// @dev keeps track of which card is next to complete the
    /// @dev .. accounting for when locking the market
    uint256 public override cardAccountingIndex;
    /// @dev has the market locking accounting been completed yet
    bool public override accountingComplete;
    /// @dev if true then copies of the NFT can only be minted for the winning outcome.
    bool limitNFTsToWinners;

    // ORACLE VARIABLES
    bytes32 public override questionId;
    address public override arbitrator;
    uint32 public override timeout; // the time allowed for the answer to be corrected

    /*╔═════════════════════════════════╗
      ║             EVENTS              ║
      ╚═════════════════════════════════╝*/

    event LogNewOwner(uint256 indexed cardId, address indexed newOwner);
    event LogRentCollection(
        uint256 rentCollected,
        uint256 indexed newTimeHeld,
        uint256 indexed cardId,
        address indexed owner
    );
    event LogContractLocked(bool indexed didTheEventFinish);
    event LogWinnerKnown(uint256 indexed winningOutcome);
    event LogWinningsPaid(address indexed paidTo, uint256 indexed amountPaid);
    event LogStakeholderPaid(
        address indexed paidTo,
        uint256 indexed amountPaid
    );
    event LogRentReturned(
        address indexed returnedTo,
        uint256 indexed amountReturned
    );
    event LogStateChange(uint256 indexed newState);
    event LogUpdateTimeHeldLimit(
        address indexed owner,
        uint256 newLimit,
        uint256 cardId
    );
    event LogSponsor(address indexed sponsor, uint256 indexed amount);
    event LogPayoutDetails(
        address indexed artistAddress,
        address marketCreatorAddress,
        address affiliateAddress,
        address[] cardAffiliateAddresses,
        uint256 indexed artistCut,
        uint256 winnerCut,
        uint256 creatorCut,
        uint256 affiliateCut,
        uint256 cardAffiliateCut
    );
    event LogSettings(
        uint256 minRentalDayDivisor,
        uint256 minimumPriceIncreasePercent,
        uint256 nftsToAward,
        bool nftsToWinningOutcomeOnly
    );
    event LogLongestOwner(uint256 cardId, address longestOwner);
    event LogQuestionPostedToOracle(
        address indexed marketAddress,
        bytes32 indexed questionId
    );

    /*╔═════════════════════════════════╗
      ║           CONSTRUCTOR           ║
      ╚═════════════════════════════════╝*/

    /// @param _mode 0 = normal, 1 = winner takes all, 2 = Safe Mode
    /// @param _timestamps for market opening, locking, and oracle resolution
    /// @param _numberOfCards how many Cards in this market
    /// @param _artistAddress where to send artist's cut, if any (zero address is valid)
    /// @param _affiliateAddress where to send affiliate's cut, if any (zero address is valid)
    /// @param _cardAffiliateAddresses where to send card specific affiliate's cut, if any (zero address is valid)
    /// @param _marketCreatorAddress where to send market creator's cut, if any (zero address is valid)
    /// @param _realitioQuestion the question posted to the Oracle
    function initialize(
        Mode _mode,
        uint32[] memory _timestamps,
        uint256 _numberOfCards,
        address _artistAddress,
        address _affiliateAddress,
        address[] memory _cardAffiliateAddresses,
        address _marketCreatorAddress,
        string calldata _realitioQuestion,
        uint256 _nftsToAward
    ) external override initializer {
        mode = Mode(_mode);

        // initialise MetaTransactions
        _initializeEIP712("RealityCardsMarket", "1");

        // external contract variables:
        factory = IRCFactory(msgSender());
        treasury = factory.treasury();
        nfthub = factory.nfthub();
        orderbook = factory.orderbook();
        leaderboard = factory.leaderboard();

        // get adjustable parameters from the factory/treasury
        uint256[5] memory _potDistribution = factory.getPotDistribution();
        minRentalDayDivisor = treasury.minRentalDayDivisor();
        (
            minimumPriceIncreasePercent,
            maxRentIterations,
            maxRentIterationsToLockMarket,
            limitNFTsToWinners
        ) = factory.getMarketSettings();

        // Initialize!
        winningOutcome = type(uint256).max; // default invalid

        // assign arguments to public variables
        numberOfCards = _numberOfCards;
        nftsToAward = _nftsToAward;
        marketOpeningTime = _timestamps[0];
        marketLockingTime = _timestamps[1];
        oracleResolutionTime = _timestamps[2];
        artistAddress = _artistAddress;
        marketCreatorAddress = _marketCreatorAddress;
        affiliateAddress = _affiliateAddress;
        cardAffiliateAddresses = _cardAffiliateAddresses;
        artistCut = _potDistribution[0];
        winnerCut = _potDistribution[1];
        creatorCut = _potDistribution[2];
        affiliateCut = _potDistribution[3];
        cardAffiliateCut = _potDistribution[4];
        (realitio, arbitrator, timeout) = factory.getOracleSettings();
        for (uint256 i = 0; i < _numberOfCards; i++) {
            tokenIds.push(type(uint256).max);
        }

        // reduce artist cut to zero if zero address set
        if (_artistAddress == address(0)) {
            artistCut = 0;
        }

        // reduce affiliate cut to zero if zero address set
        if (_affiliateAddress == address(0)) {
            affiliateCut = 0;
        }

        // check the validity of card affiliate array.
        // if not valid, reduce payout to zero
        if (_cardAffiliateAddresses.length == _numberOfCards) {
            for (uint256 i = 0; i < _numberOfCards; i++) {
                if (_cardAffiliateAddresses[i] == address(0)) {
                    cardAffiliateCut = 0;
                    break;
                }
            }
        } else {
            cardAffiliateCut = 0;
        }

        // if winner takes all mode, set winnerCut to max
        if (_mode == Mode.WINNER_TAKES_ALL) {
            winnerCut =
                (((uint256(PER_MILLE) - artistCut) - creatorCut) -
                    affiliateCut) -
                cardAffiliateCut;
        }

        // post question to Oracle
        _postQuestionToOracle(_realitioQuestion, _timestamps[2]);

        // move to OPEN immediately if market opening time in the past
        if (marketOpeningTime <= block.timestamp) {
            _incrementState();
        }

        emit LogPayoutDetails(
            _artistAddress,
            _marketCreatorAddress,
            _affiliateAddress,
            cardAffiliateAddresses,
            artistCut,
            winnerCut,
            creatorCut,
            affiliateCut,
            cardAffiliateCut
        );
        emit LogSettings(
            minRentalDayDivisor,
            minimumPriceIncreasePercent,
            nftsToAward,
            limitNFTsToWinners
        );
    }

    /*╔═════════════════════════════════╗
      ║            MODIFIERS            ║
      ╚═════════════════════════════════╝*/

    /// @notice automatically opens market if appropriate
    modifier autoUnlock() {
        if (marketOpeningTime <= block.timestamp && state == States.CLOSED) {
            _incrementState();
        }
        _;
    }

    /// @notice automatically locks market if appropriate
    modifier autoLock() {
        if (marketLockingTime <= block.timestamp) {
            lockMarket();
        }
        _;
    }

    /*╔═════════════════════════════════╗
      ║     NFT HUB CONTRACT CALLS      ║
      ╚═════════════════════════════════╝*/

    /// @notice gets the owner of the NFT via their Card Id
    function ownerOf(uint256 _cardId) public view override returns (address) {
        require(_cardId < numberOfCards, "Card does not exist");
        if (tokenExists(_cardId)) {
            uint256 _tokenId = getTokenId(_cardId);
            return nfthub.ownerOf(_tokenId);
        } else {
            return address(this);
        }
    }

    /// @notice transfer ERC 721 between users
    function _transferCard(
        address _from,
        address _to,
        uint256 _cardId
    ) internal {
        require(
            _from != address(0) && _to != address(0),
            "Cannot send to/from zero address"
        );
        uint256 _tokenId = getTokenId(_cardId);

        nfthub.transferNft(_from, _to, _tokenId);
        emit LogNewOwner(_cardId, _to);
    }

    /// @notice transfer ERC 721 between users
    /// @dev called externally by Orderbook
    function transferCard(
        address _from,
        address _to,
        uint256 _cardId,
        uint256 _price,
        uint256 _timeLimit
    ) external override {
        require(msgSender() == address(orderbook), "Not orderbook");
        _checkState(States.OPEN);
        if (_to != _from) {
            _transferCard(_from, _to, _cardId);
        }
        card[_cardId].cardTimeLimit = _timeLimit;
        card[_cardId].cardPrice = _price;
    }

    /*╔═════════════════════════════════╗
      ║        ORACLE FUNCTIONS         ║
      ╚═════════════════════════════════╝*/

    /// @dev called within initializer only
    function _postQuestionToOracle(
        string calldata _question,
        uint32 _oracleResolutionTime
    ) internal {
        uint256 templateId = 2; //template 2 works for all RealityCards questions
        uint256 nonce = 0; // We don't need to ask it again, always use 0
        bytes32 questionHash = keccak256(
            abi.encodePacked(templateId, _oracleResolutionTime, _question)
        );
        questionId = keccak256(
            abi.encodePacked(
                questionHash,
                arbitrator,
                timeout,
                address(this),
                nonce
            )
        );
        if (realitio.getContentHash(questionId) != questionHash) {
            // check if our questionHash matches an existing questionId
            // otherwise ask the question.
            questionId = realitio.askQuestion(
                templateId,
                _question,
                arbitrator,
                timeout,
                _oracleResolutionTime,
                nonce
            );
        }
        emit LogQuestionPostedToOracle(address(this), questionId);
    }

    /// @notice has the oracle finalised
    function isFinalized() public view override returns (bool) {
        bool _isFinalized = realitio.isFinalized(questionId);
        return _isFinalized;
    }

    /// @dev sets the winning outcome
    /// @dev market.setWinner() will revert if done twice, because wrong state
    function getWinnerFromOracle() external override {
        require(isFinalized(), "Oracle not finalised");
        // check market state to prevent market closing early
        require(marketLockingTime <= block.timestamp, "Market not finished");
        bytes32 _winningOutcome = realitio.resultFor(questionId);
        // call the market
        setWinner(uint256(_winningOutcome));
    }

    /// @dev admin override of the oracle
    function setAmicableResolution(uint256 _winningOutcome) external override {
        require(
            treasury.checkPermission(keccak256("OWNER"), msgSender()),
            "Not authorised"
        );
        setWinner(_winningOutcome);
    }

    /*╔═════════════════════════════════╗
      ║  MARKET RESOLUTION FUNCTIONS    ║
      ╚═════════════════════════════════╝*/

    /// @notice Checks whether the competition has ended, if so moves to LOCKED state
    /// @notice May require multiple calls as all accounting must be completed before
    /// @notice the market should be locked.
    /// @dev can be called by anyone
    /// @dev public because called within autoLock modifier & setWinner
    function lockMarket() public override {
        _checkState(States.OPEN);
        require(
            uint256(marketLockingTime) <= block.timestamp,
            "Market has not finished"
        );

        bool _cardAccountingComplete = false;
        uint256 _rentIterationCounter = 0;
        // do a final rent collection before the contract is locked down
        while (cardAccountingIndex < numberOfCards && !accountingComplete) {
            (_cardAccountingComplete, _rentIterationCounter) = _collectRent(
                cardAccountingIndex,
                _rentIterationCounter
            );
            if (_cardAccountingComplete) {
                _cardAccountingComplete = false;
                cardAccountingIndex++;
            }
            if (cardAccountingIndex == numberOfCards) {
                accountingComplete = true;
                break;
            }
            if (_rentIterationCounter >= maxRentIterations) {
                break;
            }
        }
        // check the accounting is complete but only continue if we haven't used much gas so far
        /// @dev using gasleft() would be nice, but it causes problems with tx gas estimations
        if (
            accountingComplete &&
            _rentIterationCounter < maxRentIterationsToLockMarket
        ) {
            // and check that the orderbook has shut the market
            if (orderbook.closeMarket()) {
                // now lock the market
                _incrementState();

                for (uint256 i = 0; i < numberOfCards; i++) {
                    if (tokenExists(i)) {
                        // bring the cards back to the market so the winners get the satisfaction of claiming them
                        _transferCard(ownerOf(i), address(this), i);
                    }
                    emit LogLongestOwner(i, card[i].longestOwner);
                }
                emit LogContractLocked(true);
            }
        }
    }

    /// @notice called by getWinnerFromOracle, sets the winner
    /// @param _winningOutcome the index of the winning card
    function setWinner(uint256 _winningOutcome) internal {
        if (state == States.OPEN) {
            // change the locking time to allow lockMarket to lock
            /// @dev implementing our own SafeCast as this is the only place we need it
            require(block.timestamp <= type(uint32).max, "Overflow");
            marketLockingTime = uint32(block.timestamp);
            lockMarket();
        }
        if (state == States.LOCKED) {
            // get the winner. This will revert if answer is not resolved.
            winningOutcome = _winningOutcome;
            _incrementState();
            emit LogWinnerKnown(_winningOutcome);
        }
    }

    /// @notice pays out winnings, or returns funds
    function withdraw() external override {
        _checkState(States.WITHDRAW);
        require(!userAlreadyWithdrawn[msgSender()], "Already withdrawn");
        userAlreadyWithdrawn[msgSender()] = true;
        if (card[winningOutcome].totalTimeHeld > 0) {
            _payoutWinnings();
        } else {
            _returnRent();
        }
    }

    /// @notice the longest owner of each NFT gets to keep it
    /// @notice users on the leaderboard can make a copy of it
    /// @dev LOCKED or WITHDRAW states are fine- does not need to wait for winner to be known
    /// @param _card the id of the card, the index
    function claimCard(uint256 _card) external override {
        _checkState(States.WITHDRAW);
        require(
            !treasury.marketPaused(address(this)) && !treasury.globalPause(),
            "Market is Paused"
        );
        address _user = msgSender();
        uint256 _tokenId = getTokenId(_card);
        bool _winner = _card == winningOutcome; // invalid outcome defaults to losing
        require(!card[_card].userAlreadyClaimed[_user], "Already claimed");
        card[_card].userAlreadyClaimed[_user] = true;
        if (_user == card[_card].longestOwner) {
            factory.updateTokenOutcome(_card, _tokenId, _winner);
            _transferCard(ownerOf(_card), card[_card].longestOwner, _card);
        } else {
            if (limitNFTsToWinners) {
                require(_winner, "Not winning outcome");
            }
            leaderboard.claimNFT(_user, _card);
            factory.mintCopyOfNFT(_user, _card, _tokenId, _winner);
        }
    }

    /// @notice pays winnings
    function _payoutWinnings() internal {
        uint256 _winningsToTransfer = 0;
        uint256 _remainingCut = ((((uint256(PER_MILLE) - artistCut) -
            affiliateCut) - cardAffiliateCut) - winnerCut) - creatorCut;
        address _msgSender = msgSender();
        // calculate longest owner's extra winnings, if relevant
        if (card[winningOutcome].longestOwner == _msgSender && winnerCut > 0) {
            _winningsToTransfer =
                (totalRentCollected * winnerCut) /
                (PER_MILLE);
        }
        uint256 _remainingPot = 0;
        if (mode == Mode.SAFE_MODE) {
            // return all rent paid on winning card
            _remainingPot =
                ((totalRentCollected -
                    card[winningOutcome].rentCollectedPerCard) *
                    _remainingCut) /
                PER_MILLE;
            _winningsToTransfer +=
                (rentCollectedPerUserPerCard[_msgSender][winningOutcome] *
                    _remainingCut) /
                PER_MILLE;
        } else {
            // calculate normal winnings, if any
            _remainingPot = (totalRentCollected * _remainingCut) / (PER_MILLE);
        }
        uint256 _winnersTimeHeld = card[winningOutcome].timeHeld[_msgSender];
        uint256 _numerator = _remainingPot * _winnersTimeHeld;
        _winningsToTransfer += (_numerator /
            card[winningOutcome].totalTimeHeld);
        require(_winningsToTransfer > 0, "Not a winner");
        _payout(_msgSender, _winningsToTransfer);
        emit LogWinningsPaid(_msgSender, _winningsToTransfer);
    }

    /// @notice returns all funds to users in case of invalid outcome
    function _returnRent() internal {
        // deduct artist share and card specific share if relevant but NOT market creator share or winner's share (no winner, market creator does not deserve)
        uint256 _remainingCut = ((uint256(PER_MILLE) - artistCut) -
            affiliateCut) - cardAffiliateCut;
        uint256 _rentCollected = rentCollectedPerUser[msgSender()];
        require(_rentCollected > 0, "Paid no rent");
        uint256 _rentCollectedAdjusted = (_rentCollected * _remainingCut) /
            (PER_MILLE);
        _payout(msgSender(), _rentCollectedAdjusted);
        emit LogRentReturned(msgSender(), _rentCollectedAdjusted);
    }

    /// @notice all payouts happen through here
    function _payout(address _recipient, uint256 _amount) internal {
        treasury.payout(_recipient, _amount);
    }

    /// @dev the below functions pay stakeholders (artist, creator, affiliate, card specific affiliates)
    /// @dev they are not called within setWinner() because of the risk of an
    /// @dev ....  address being a contract which refuses payment, then nobody could get winnings
    /// @dev [hangover from when ether was native currency, keeping in case we return to this]

    /// @notice pay artist
    function payArtist() external override {
        _checkState(States.WITHDRAW);
        require(!artistPaid, "Artist already paid");
        artistPaid = true;
        _processStakeholderPayment(artistCut, artistAddress);
    }

    /// @notice pay market creator
    function payMarketCreator() external override {
        _checkState(States.WITHDRAW);
        require(card[winningOutcome].totalTimeHeld > 0, "No winner");
        require(!creatorPaid, "Creator already paid");
        creatorPaid = true;
        _processStakeholderPayment(creatorCut, marketCreatorAddress);
    }

    /// @notice pay affiliate
    function payAffiliate() external override {
        _checkState(States.WITHDRAW);
        require(!affiliatePaid, "Affiliate already paid");
        affiliatePaid = true;
        _processStakeholderPayment(affiliateCut, affiliateAddress);
    }

    /// @notice pay card affiliate
    /// @dev does not call _processStakeholderPayment because it works differently
    function payCardAffiliate(uint256 _card) external override {
        _checkState(States.WITHDRAW);
        require(!card[_card].cardAffiliatePaid, "Card affiliate already paid");
        card[_card].cardAffiliatePaid = true;
        uint256 _cardAffiliatePayment = (card[_card].rentCollectedPerCard *
            cardAffiliateCut) / (PER_MILLE);
        if (_cardAffiliatePayment > 0) {
            _payout(cardAffiliateAddresses[_card], _cardAffiliatePayment);
            emit LogStakeholderPaid(
                cardAffiliateAddresses[_card],
                _cardAffiliatePayment
            );
        }
    }

    function _processStakeholderPayment(uint256 _cut, address _recipient)
        internal
    {
        if (_cut > 0) {
            uint256 _payment = (totalRentCollected * _cut) / (PER_MILLE);
            _payout(_recipient, _payment);
            emit LogStakeholderPaid(_recipient, _payment);
        }
    }

    /*╔═════════════════════════════════╗
      ║         CORE FUNCTIONS          ║
      ╠═════════════════════════════════╣
      ║             EXTERNAL            ║
      ╚═════════════════════════════════╝*/

    /// @dev basically functions that have _checkState(States.OPEN) on first line

    /// @notice collects rent a specific card
    function collectRent(uint256 _cardId) external override returns (bool) {
        _checkState(States.OPEN);
        bool _success;
        (_success, ) = _collectRent(_cardId, 0);
        if (_success) {
            return true;
        }
        return false;
    }

    /// @notice rent every Card at the minimum price
    /// @param _maxSumOfPrices a limit to the sum of the bids to place
    function rentAllCards(uint256 _maxSumOfPrices) external override {
        _checkState(States.OPEN);
        // check that not being front run
        uint256 _actualSumOfPrices = 0;
        address _user = msgSender();
        for (uint256 i = 0; i < numberOfCards; i++) {
            if (ownerOf(i) != _user) {
                _actualSumOfPrices += minPriceIncreaseCalc(card[i].cardPrice);
            }
        }

        require(_actualSumOfPrices <= _maxSumOfPrices, "Prices too high");

        for (uint256 i = 0; i < numberOfCards; i++) {
            if (ownerOf(i) != _user) {
                uint256 _newPrice = minPriceIncreaseCalc(card[i].cardPrice);
                newRental(_newPrice, 0, address(0), i);
            }
        }
    }

    /// @notice to rent a Card
    /// @param _newPrice the price to rent the card for
    /// @param _timeHeldLimit an optional time limit to rent the card for
    /// @param _startingPosition where to start looking to insert the bid into the orderbook
    /// @param _card the index of the card to update
    function newRental(
        uint256 _newPrice,
        uint256 _timeHeldLimit,
        address _startingPosition,
        uint256 _card
    ) public override autoUnlock autoLock {
        // if the market isn't open then don't do anything else, not reverting
        // .. will allow autoLock to process the accounting to lock the market
        if (state == States.OPEN && !accountingComplete) {
            require(_newPrice >= MIN_RENTAL_VALUE, "Price below min");
            require(_card < numberOfCards, "Card does not exist");

            // if the NFT hasn't been minted, we should probably do that
            if (!tokenExists(_card)) {
                tokenIds[_card] = nfthub.totalSupply();
                factory.mintMarketNFT(_card);
            }

            address _user = msgSender();

            // prevent re-renting, this limits (but doesn't eliminate) a frontrunning attack
            require(
                exitedTimestamp[_user] != block.timestamp,
                "Cannot lose and re-rent in same block"
            );
            require(
                !treasury.marketPaused(address(this)) &&
                    !treasury.globalPause(),
                "Rentals are disabled"
            );
            // restrict certain markets to specific whitelists
            require(
                treasury.marketWhitelistCheck(_user),
                "Not approved for this market"
            );

            // if the user is foreclosed then delete some old bids
            // .. this could remove their foreclosure
            if (treasury.isForeclosed(_user)) {
                orderbook.removeUserFromOrderbook(_user);
            }
            require(
                !treasury.isForeclosed(_user),
                "Can't rent while foreclosed"
            );
            if (ownerOf(_card) == _user) {
                // the owner may only increase by more than X% or reduce their price
                uint256 _requiredPrice = (card[_card].cardPrice *
                    (minimumPriceIncreasePercent + 100)) / (100);
                require(
                    _newPrice >= _requiredPrice ||
                        _newPrice < card[_card].cardPrice,
                    "Invalid price"
                );
            }

            // do some cleaning up before we collect rent or check their bidRate
            orderbook.removeOldBids(_user);

            /// @dev ignore the return value and let the user post the bid for the sake of UX
            _collectRent(_card, 0);

            // check sufficient deposit
            treasury.collectRentUser(_user, block.timestamp);
            uint256 _userTotalBidRate = (treasury.userTotalBids(_user) -
                orderbook.getBidValue(_user, _card)) + _newPrice;
            require(
                treasury.userDeposit(_user) >=
                    _userTotalBidRate / minRentalDayDivisor,
                "Insufficient deposit"
            );

            _checkTimeHeldLimit(_timeHeldLimit);

            orderbook.addBidToOrderbook(
                _user,
                _card,
                _newPrice,
                _timeHeldLimit,
                _startingPosition
            );

            treasury.updateLastRentalTime(_user);
        }
    }

    /// @notice to change your timeHeldLimit without having to re-rent
    /// @param _timeHeldLimit an optional time limit to rent the card for
    /// @param _card the index of the card to update
    function updateTimeHeldLimit(uint256 _timeHeldLimit, uint256 _card)
        external
        override
    {
        _checkState(States.OPEN);
        address _user = msgSender();
        bool rentCollected;
        (rentCollected, ) = _collectRent(_card, 0);
        if (rentCollected) {
            _checkTimeHeldLimit(_timeHeldLimit);

            orderbook.setTimeHeldlimit(_user, _card, _timeHeldLimit);

            if (ownerOf(_card) == _user) {
                card[_card].cardTimeLimit = _timeHeldLimit;
            }

            emit LogUpdateTimeHeldLimit(_user, _timeHeldLimit, _card);
        }
    }

    /// @notice stop renting all cards
    function exitAll() external override {
        for (uint256 i = 0; i < numberOfCards; i++) {
            exit(i);
        }
    }

    /// @notice stop renting a card and/or remove from orderbook
    /// @dev public because called by exitAll()
    /// @dev doesn't need to be current owner so user can prevent ownership returning to them
    /// @dev does not apply minimum rental duration, because it returns ownership to the next user
    /// @dev doesn't revert if non-existant bid because user might be trying to exitAll()
    /// @param _card The card index to exit
    function exit(uint256 _card) public override {
        _checkState(States.OPEN);
        address _msgSender = msgSender();

        // collectRent first
        /// @dev ignore the return value and let the user exit the bid for the sake of UX
        _collectRent(_card, 0);

        if (ownerOf(_card) == _msgSender) {
            // block frontrunning attack
            exitedTimestamp[_msgSender] = block.timestamp;

            // if current owner, find a new one
            orderbook.findNewOwner(_card, block.timestamp);
            assert(!orderbook.bidExists(_msgSender, address(this), _card));
        } else {
            // if not owner, just delete from orderbook
            if (orderbook.bidExists(_msgSender, address(this), _card)) {
                // block frontrunning attack
                exitedTimestamp[_msgSender] = block.timestamp;

                orderbook.removeBidFromOrderbook(_msgSender, _card);
            }
        }
    }

    /// @notice ability to add liquidity to the pot without being able to win.
    /// @dev called by user, sponsor is msgSender
    function sponsor(uint256 _amount) external override {
        address _creator = msgSender();
        _sponsor(_creator, _amount);
    }

    /// @notice ability to add liquidity to the pot without being able to win.
    /// @dev called by Factory during market creation
    /// @param _sponsorAddress the msgSender of createMarket in the Factory
    function sponsor(address _sponsorAddress, uint256 _amount)
        external
        override
    {
        address _msgSender = msgSender();
        if (_msgSender != address(factory)) {
            _sponsorAddress = _msgSender;
        }
        _sponsor(_sponsorAddress, _amount);
    }

    /*╔═════════════════════════════════╗
      ║         CORE FUNCTIONS          ║
      ╠═════════════════════════════════╣
      ║             INTERNAL            ║
      ╚═════════════════════════════════╝*/

    /// @dev actually processes the sponsorship
    function _sponsor(address _sponsorAddress, uint256 _amount) internal {
        _checkNotState(States.LOCKED);
        _checkNotState(States.WITHDRAW);
        require(_amount > 0, "Must send something");
        // send tokens to the Treasury
        treasury.sponsor(_sponsorAddress, _amount);
        totalRentCollected = totalRentCollected + _amount;
        // just so user can get it back if invalid outcome
        rentCollectedPerUser[_sponsorAddress] =
            rentCollectedPerUser[_sponsorAddress] +
            _amount;
        // allocate equally to each card, in case card specific affiliates
        for (uint256 i = 0; i < numberOfCards; i++) {
            card[i].rentCollectedPerCard =
                card[i].rentCollectedPerCard +
                (_amount / numberOfCards);
        }
        emit LogSponsor(_sponsorAddress, _amount);
    }

    function _checkTimeHeldLimit(uint256 _timeHeldLimit) internal view {
        if (_timeHeldLimit != 0) {
            uint256 _minRentalTime = uint256(1 days) / minRentalDayDivisor;
            require(_timeHeldLimit >= _minRentalTime, "Limit too low");
        }
    }

    /// @dev _collectRentAction goes back one owner at a time, this function repeatedly calls
    /// @dev ... _collectRentAction until the backlog of next owners has been processed, or maxRentIterations hit
    /// @param _card the card id to collect rent for
    /// @return true if the rent collection was completed, (ownership updated to the current time)
    function _collectRent(uint256 _card, uint256 _counter)
        internal
        returns (bool, uint256)
    {
        bool shouldContinue = true;
        while (_counter < maxRentIterations && shouldContinue) {
            shouldContinue = _collectRentAction(_card);
            _counter++;
        }
        return (!shouldContinue, _counter);
    }

    /// @notice collects rent for a specific card
    /// @dev also calculates and updates how long the current user has held the card for
    /// @dev is not a problem if called externally, but making internal over public to save gas
    /// @param _card the card id to collect rent for
    /// @return true if we should repeat the rent collection
    function _collectRentAction(uint256 _card) internal returns (bool) {
        address _user = ownerOf(_card);
        uint256 _timeOfThisCollection = block.timestamp;

        // don't collect rent beyond the locking time
        if (marketLockingTime <= block.timestamp) {
            _timeOfThisCollection = marketLockingTime;
        }

        //only collect rent if the card is owned (ie, if owned by the contract this implies unowned)
        // AND if the last collection was in the past (ie, don't do 2+ rent collections in the same block)
        if (
            _user != address(this) &&
            card[_card].timeLastCollected < _timeOfThisCollection
        ) {
            // User rent collect and fetch the time the user foreclosed, 0 means they didn't foreclose yet
            uint256 _timeUserForeclosed = treasury.collectRentUser(
                _user,
                block.timestamp
            );

            // Calculate the card timeLimitTimestamp
            uint256 _cardTimeLimitTimestamp = card[_card].timeLastCollected +
                card[_card].cardTimeLimit;

            // input bools
            bool _foreclosed = _timeUserForeclosed != 0;
            bool _limitHit = card[_card].cardTimeLimit != 0 &&
                _cardTimeLimitTimestamp < block.timestamp;
            bool _marketLocked = marketLockingTime <= block.timestamp;

            // outputs
            bool _newOwner = false;
            uint256 _refundTime = 0; // seconds of rent to refund the user

            /* Permutations of the events: Foreclosure, Time limit and Market Locking
            ┌───────────┬─┬─┬─┬─┬─┬─┬─┬─┐
            │Case       │1│2│3│4│5│6│7│8│
            ├───────────┼─┼─┼─┼─┼─┼─┼─┼─┤
            │Foreclosure│0│0│0│0│1│1│1│1│
            │Time Limit │0│0│1│1│0│0│1│1│
            │Market Lock│0│1│0│1│0│1│0│1│
            └───────────┴─┴─┴─┴─┴─┴─┴─┴─┘
            */

            if (!_foreclosed && !_limitHit && !_marketLocked) {
                // CASE 1
                // didn't foreclose AND
                // didn't hit time limit AND
                // didn't lock market
                // THEN simple rent collect, same owner
                _timeOfThisCollection = _timeOfThisCollection;
                _newOwner = false;
                _refundTime = 0;
            } else if (!_foreclosed && !_limitHit && _marketLocked) {
                // CASE 2
                // didn't foreclose AND
                // didn't hit time limit AND
                // did lock market
                // THEN refund rent between locking and now
                _timeOfThisCollection = marketLockingTime;
                _newOwner = false;
                _refundTime = block.timestamp - marketLockingTime;
            } else if (!_foreclosed && _limitHit && !_marketLocked) {
                // CASE 3
                // didn't foreclose AND
                // did hit time limit AND
                // didn't lock market
                // THEN refund rent between time limit and now
                _timeOfThisCollection = _cardTimeLimitTimestamp;
                _newOwner = true;
                _refundTime = block.timestamp - _cardTimeLimitTimestamp;
            } else if (!_foreclosed && _limitHit && _marketLocked) {
                // CASE 4
                // didn't foreclose AND
                // did hit time limit AND
                // did lock market
                // THEN refund rent between the earliest event and now
                if (_cardTimeLimitTimestamp < marketLockingTime) {
                    // time limit hit before market locked
                    _timeOfThisCollection = _cardTimeLimitTimestamp;
                    _newOwner = true;
                    _refundTime = block.timestamp - _cardTimeLimitTimestamp;
                } else {
                    // market locked before time limit hit
                    _timeOfThisCollection = marketLockingTime;
                    _newOwner = false;
                    _refundTime = block.timestamp - marketLockingTime;
                }
            } else if (_foreclosed && !_limitHit && !_marketLocked) {
                // CASE 5
                // did foreclose AND
                // didn't hit time limit AND
                // didn't lock market
                // THEN rent OK, find new owner
                _timeOfThisCollection = _timeUserForeclosed;
                _newOwner = true;
                _refundTime = 0;
            } else if (_foreclosed && !_limitHit && _marketLocked) {
                // CASE 6
                // did foreclose AND
                // didn't hit time limit AND
                // did lock market
                // THEN if foreclosed first rent ok, otherwise refund after locking
                if (_timeUserForeclosed < marketLockingTime) {
                    // user foreclosed before market locked
                    _timeOfThisCollection = _timeUserForeclosed;
                    _newOwner = true;
                    _refundTime = 0;
                } else {
                    // market locked before user foreclosed
                    _timeOfThisCollection = marketLockingTime;
                    _newOwner = false;
                    _refundTime = _timeUserForeclosed - marketLockingTime;
                }
            } else if (_foreclosed && _limitHit && !_marketLocked) {
                // CASE 7
                // did foreclose AND
                // did hit time limit AND
                // didn't lock market
                // THEN if foreclosed first rent ok, otherwise refund after limit
                if (_timeUserForeclosed < _cardTimeLimitTimestamp) {
                    // user foreclosed before time limit
                    _timeOfThisCollection = _timeUserForeclosed;
                    _newOwner = true;
                    _refundTime = 0;
                } else {
                    // time limit hit before user foreclosed
                    _timeOfThisCollection = _cardTimeLimitTimestamp;
                    _newOwner = true;
                    _refundTime = _timeUserForeclosed - _cardTimeLimitTimestamp;
                }
            } else {
                // CASE 8
                // did foreclose AND
                // did hit time limit AND
                // did lock market
                // THEN (╯°益°)╯彡┻━┻
                if (
                    _timeUserForeclosed <= _cardTimeLimitTimestamp &&
                    _timeUserForeclosed < marketLockingTime
                ) {
                    // user foreclosed first (or at same time as time limit)
                    _timeOfThisCollection = _timeUserForeclosed;
                    _newOwner = true;
                    _refundTime = 0;
                } else if (
                    _cardTimeLimitTimestamp < _timeUserForeclosed &&
                    _cardTimeLimitTimestamp < marketLockingTime
                ) {
                    // time limit hit first
                    _timeOfThisCollection = _cardTimeLimitTimestamp;
                    _newOwner = true;
                    _refundTime = _timeUserForeclosed - _cardTimeLimitTimestamp;
                } else {
                    // market locked first
                    _timeOfThisCollection = marketLockingTime;
                    _newOwner = false;
                    _refundTime = _timeUserForeclosed - marketLockingTime;
                }
            }
            if (_refundTime != 0) {
                uint256 _refundAmount = (_refundTime * card[_card].cardPrice) /
                    1 days;
                treasury.refundUser(_user, _refundAmount);
            }
            _processRentCollection(_user, _card, _timeOfThisCollection); // where the rent collection actually happens

            if (_newOwner) {
                orderbook.findNewOwner(_card, _timeOfThisCollection);
                return true;
            }
        } else {
            // timeLastCollected is updated regardless of whether the card is owned, so that the clock starts ticking
            // ... when the first owner buys it, because this function is run before ownership changes upon calling newRental
            card[_card].timeLastCollected = _timeOfThisCollection;
        }
        return false;
    }

    /// @dev processes actual rent collection and updates the state
    function _processRentCollection(
        address _user,
        uint256 _card,
        uint256 _timeOfCollection
    ) internal {
        uint256 _timeHeldToIncrement = (_timeOfCollection -
            card[_card].timeLastCollected);
        uint256 _rentOwed = (card[_card].cardPrice * _timeHeldToIncrement) /
            1 days;

        // if the user has a timeLimit, adjust it as necessary
        if (card[_card].cardTimeLimit != 0) {
            orderbook.reduceTimeHeldLimit(_user, _card, _timeHeldToIncrement);
            card[_card].cardTimeLimit -= _timeHeldToIncrement;
        }

        // update time
        card[_card].timeHeld[_user] += _timeHeldToIncrement;
        card[_card].totalTimeHeld += _timeHeldToIncrement;
        card[_card].timeLastCollected = _timeOfCollection;

        // longest owner tracking
        if (
            card[_card].timeHeld[_user] >
            card[_card].timeHeld[card[_card].longestOwner]
        ) {
            card[_card].longestOwner = _user;
        }

        // update amounts
        /// @dev get back the actual rent collected, it may be less than owed
        uint256 _rentCollected = treasury.payRent(_rentOwed);
        card[_card].rentCollectedPerCard += _rentCollected;
        rentCollectedPerUserPerCard[_user][_card] += _rentCollected;
        rentCollectedPerUser[_user] += _rentCollected;
        totalRentCollected += _rentCollected;

        leaderboard.updateLeaderboard(
            _user,
            _card,
            card[_card].timeHeld[_user]
        );
        emit LogRentCollection(
            _rentCollected,
            _timeHeldToIncrement,
            _card,
            _user
        );
    }

    function _checkState(States currentState) internal view {
        require(state == currentState, "Incorrect state");
    }

    function _checkNotState(States currentState) internal view {
        require(state != currentState, "Incorrect state");
    }

    /// @dev should only be called thrice
    function _incrementState() internal {
        state = States(uint256(state) + 1);
        emit LogStateChange(uint256(state));
    }

    /// @notice returns the tokenId (the unique NFT index) given the cardId (the market specific index)
    /// @param _card the market specific index of the card
    /// @return _tokenId the unique NFT index
    function getTokenId(uint256 _card)
        public
        view
        override
        returns (uint256 _tokenId)
    {
        require(tokenExists(_card));
        return tokenIds[_card];
    }

    function minPriceIncreaseCalc(uint256 _oldPrice)
        internal
        view
        returns (uint256 _newPrice)
    {
        if (_oldPrice == 0) {
            return MIN_RENTAL_VALUE;
        } else {
            return (_oldPrice * (minimumPriceIncreasePercent + 100)) / 100;
        }
    }

    /*╔═════════════════════════════════╗
      ║       VIEW FUNCTIONS            ║
      ╚═════════════════════════════════╝*/

    /// @notice Check if the NFT has been minted yet
    /// @param _card the market specific index of the card
    /// @return true if the NFT has been minted
    function tokenExists(uint256 _card) internal view returns (bool) {
        if (_card >= numberOfCards) return false;
        return tokenIds[_card] != type(uint256).max;
    }

    /// @dev a simple getter for the time a user has held a given card
    function timeHeld(uint256 _card, address _user)
        external
        view
        override
        returns (uint256)
    {
        return card[_card].timeHeld[_user];
    }

    /// @dev a simple getter for the time a card last had rent collected
    function timeLastCollected(uint256 _card)
        external
        view
        override
        returns (uint256)
    {
        return card[_card].timeLastCollected;
    }

    /// @dev a simple getter for the longest owner of a card
    function longestOwner(uint256 _card)
        external
        view
        override
        returns (address)
    {
        return card[_card].longestOwner;
    }

    /*╔═════════════════════════════════╗
      ║          BACKUP MODE            ║
      ╚═════════════════════════════════╝*/
    /// @dev in the event of failures in the UI we need a simple reliable way to poll
    /// @dev ..the contracts for relevant info, this view function helps facilitate this.

    /// @dev quick and easy view function to get all market data relevant to the UI
    // function getMarketInfo()
    //     external
    //     view
    //     returns (
    //         States,
    //         string memory,
    //         uint256,
    //         uint256,
    //         address[] memory,
    //         uint256[] memory
    //     )
    // {
    //     address[] memory _owners = new address[](numberOfCards);
    //     uint256[] memory _prices = new uint256[](numberOfCards);
    //     for (uint256 i = 0; i < numberOfCards; i++) {
    //         _owners[i] = ownerOf(i);
    //         _prices[i] = card[i].cardPrice;
    //     }
    //     return (
    //         state,
    //         factory.ipfsHash(address(this)),
    //         winningOutcome,
    //         totalRentCollected,
    //         _owners,
    //         _prices
    //     );
    // }

    /*
         ▲  
        ▲ ▲ 
              */
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
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

/// @title Realit.io contract interface
interface IRealitio {
    function askQuestion(
        uint256 template_id,
        string calldata question,
        address arbitrator,
        uint32 timeout,
        uint32 opening_ts,
        uint256 nonce
    ) external payable returns (bytes32);

    function resultFor(bytes32 question_id) external view returns (bytes32);

    function isFinalized(bytes32 question_id) external view returns (bool);

    function getContentHash(bytes32 question_id)
        external
        view
        returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./IRealitio.sol";
import "./IRCTreasury.sol";
import "./IRCMarket.sol";
import "./IRCNftHubL2.sol";
import "./IRCOrderbook.sol";
import "./IRCLeaderboard.sol";

interface IRCFactory {
    function createMarket(
        uint32 _mode,
        string memory _ipfsHash,
        string memory _slug,
        uint32[] memory _timestamps,
        string[] memory _tokenURIs,
        address _artistAddress,
        address _affiliateAddress,
        address[] memory _cardAffiliateAddresses,
        string calldata _realitioQuestion,
        uint256 _sponsorship
    ) external returns (address);

    function mintCopyOfNFT(
        address _user,
        uint256 _cardId,
        uint256 _tokenId,
        bool _winner
    ) external;

    function updateTokenOutcome(
        uint256 _cardId,
        uint256 _tokenId,
        bool _winner
    ) external;

    // view functions

    function getMarketSettings()
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            bool
        );

    function getMarketInfo(
        IRCMarket.Mode _mode,
        uint256 _state,
        uint256 _results,
        uint256 _skipResults
    )
        external
        view
        returns (
            address[] memory,
            string[] memory,
            string[] memory,
            uint256[] memory
        );

    function nfthub() external view returns (IRCNftHubL2);

    function ipfsHash(address) external view returns (string memory);

    function slugToAddress(string memory) external view returns (address);

    function addressToSlug(address) external view returns (string memory);

    function treasury() external view returns (IRCTreasury);

    function orderbook() external view returns (IRCOrderbook);

    function leaderboard() external view returns (IRCLeaderboard);

    function realitio() external view returns (IRealitio);

    function getAllMarkets(IRCMarket.Mode _mode)
        external
        view
        returns (address[] memory);

    function getMostRecentMarket(IRCMarket.Mode _mode)
        external
        view
        returns (address);

    function referenceContractAddress() external view returns (address);

    function referenceContractVersion() external view returns (uint256);

    function sponsorshipRequired() external view returns (uint256);

    function advancedWarning() external view returns (uint32);

    function maximumDuration() external view returns (uint32);

    function minimumDuration() external view returns (uint32);

    function marketCreationGovernorsOnly() external view returns (bool);

    function approvedAffiliatesOnly() external view returns (bool);

    function approvedArtistsOnly() external view returns (bool);

    function arbitrator() external view returns (address);

    function timeout() external view returns (uint32);

    function cardLimit() external view returns (uint256);

    function getPotDistribution() external view returns (uint256[5] memory);

    function minimumPriceIncreasePercent() external view returns (uint256);

    function nftsToAward() external view returns (uint256);

    function isMarketApproved(address) external view returns (bool);

    function marketPausedDefaultState() external view returns (bool);

    function mintMarketNFT(uint256 _card) external;

    function getOracleSettings()
        external
        view
        returns (
            IRealitio oracle,
            address arbitratorAddress,
            uint32 _timeout
        );

    // only Governors
    function changeMarketApproval(address _market) external;

    // only Owner
    function setLimitNFTsToWinners(bool _limitEnabled) external;

    function setMarketPausedDefaultState(bool _state) external;

    function setTimeout(uint32 _newTimeout) external;

    function setMaxRentIterations(uint256 _rentLimit, uint256 _rentLimitLocking)
        external;

    function setArbitrator(address _newAddress) external;

    function setRealitioAddress(address _newAddress) external;

    function maxRentIterations() external view returns (uint256);

    function maxRentIterationsToLockMarket() external view returns (uint256);

    function setCardLimit(uint256 _cardLimit) external;

    function setMinimumPriceIncreasePercent(uint256 _percentIncrease) external;

    function setNumberOfNFTsToAward(uint256 _NFTsToAward) external;

    function updateTokenURI(
        address _market,
        uint256 _cardId,
        string[] calldata _newTokenURIs
    ) external;

    function setPotDistribution(
        uint256 _artistCut,
        uint256 _winnerCut,
        uint256 _creatorCut,
        uint256 _affiliateCut,
        uint256 _cardAffiliateCut
    ) external;

    function changeMarketCreationGovernorsOnly() external;

    function changeApprovedArtistsOnly() external;

    function changeApprovedAffiliatesOnly() external;

    function setSponsorshipRequired(uint256 _amount) external;

    function setMarketTimeRestrictions(
        uint32 _newAdvancedWarning,
        uint32 _newMinimumDuration,
        uint32 _newMaximumDuration
    ) external;

    // only UberOwner
    function setReferenceContractAddress(address _newAddress) external;

    function setOrderbookAddress(IRCOrderbook _newAddress) external;

    function setLeaderboardAddress(IRCLeaderboard _newAddress) external;

    function setNftHubAddress(IRCNftHubL2 _newAddress) external;

    function setTreasuryAddress(IRCTreasury _newTreasury) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./IRCTreasury.sol";
import "./IRCMarket.sol";

interface IRCLeaderboard {
    function treasury() external view returns (IRCTreasury);

    function NFTsToAward(address _market) external view returns (uint256);

    function setTreasuryAddress(address _newTreasury) external;

    function updateLeaderboard(
        address _user,
        uint256 _card,
        uint256 _timeHeld
    ) external;

    function claimNFT(address _user, uint256 _card) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IRCOrderbook.sol";
import "./IRCLeaderboard.sol";
import "./IRCFactory.sol";

interface IRCTreasury {
    function setTokenAddress(address _newToken) external;

    function grantRoleString(string memory role, address account) external;

    function grantRole(bytes32, address) external;

    function revokeRoleString(string memory role, address account) external;

    function revokeRole(bytes32, address) external;

    function collectRentUser(address _user, uint256 _timeToCollectTo)
        external
        returns (uint256 newTimeLastCollectedOnForeclosure);

    function topupMarketBalance(uint256 _amount) external;

    function assessForeclosure(address _user) external;

    // view functions
    function foreclosureTimeUser(
        address _user,
        uint256 _newBid,
        uint256 _timeOfNewBid
    ) external view returns (uint256);

    function checkRole(string memory role, address account)
        external
        view
        returns (bool);

    function uberOwnerCheckTime() external view returns (uint256);

    function bridgeAddress() external view returns (address);

    function checkPermission(bytes32, address) external view returns (bool);

    function erc20() external view returns (IERC20);

    function factory() external view returns (IRCFactory);

    function orderbook() external view returns (IRCOrderbook);

    function leaderboard() external view returns (IRCLeaderboard);

    function isForeclosed(address) external view returns (bool);

    function userTotalBids(address) external view returns (uint256);

    function userDeposit(address) external view returns (uint256);

    function totalDeposits() external view returns (uint256);

    function marketPot(address) external view returns (uint256);

    function totalMarketPots() external view returns (uint256);

    function marketBalance() external view returns (uint256);

    function marketBalanceTopup() external view returns (uint256);

    function minRentalDayDivisor() external view returns (uint256);

    function maxContractBalance() external view returns (uint256);

    function globalPause() external view returns (bool);

    function addMarket(address _market, bool paused) external;

    function marketPaused(address) external view returns (bool);

    function batchWhitelist(address[] calldata _users, bool add) external;

    function marketWhitelistCheck(address _user) external returns (bool);

    function lockMarketPaused(address _market) external view returns (bool);

    function setBridgeAddress(address _newAddress) external;

    function setOrderbookAddress(address _newAddress) external;

    function setLeaderboardAddress(address _newAddress) external;

    function setFactoryAddress(address _newFactory) external;

    function uberOwnerTest() external;

    function deposit(uint256 _amount, address _user) external returns (bool);

    function withdrawDeposit(uint256 _amount, bool _localWithdrawal) external;

    function checkSponsorship(address sender, uint256 _amount) external view;

    //only orderbook
    function increaseBidRate(address _user, uint256 _price) external;

    function decreaseBidRate(address _user, uint256 _price) external;

    function updateRentalRate(
        address _oldOwner,
        address _newOwner,
        uint256 _oldPrice,
        uint256 _newPrice,
        uint256 _timeOwnershipChanged
    ) external;

    // only owner
    function setMinRental(uint256 _newDivisor) external;

    function setMaxContractBalance(uint256) external;

    function changeGlobalPause() external;

    function changePauseMarket(address _market, bool _paused) external;

    function toggleWhitelist() external;

    // only factory
    function unPauseMarket(address _market) external;

    // only markets
    function payRent(uint256) external returns (uint256);

    function payout(address, uint256) external returns (bool);

    function refundUser(address _user, uint256 _refund) external;

    function sponsor(address _sponsor, uint256 _amount) external;

    function updateLastRentalTime(address) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./IRCNftHubL2.sol";
import "./IRCTreasury.sol";
import "./IRCFactory.sol";
import "./IRCLeaderboard.sol";
import "./IRealitio.sol";
import "./IRCOrderbook.sol";

interface IRCMarket {
    enum States {
        CLOSED,
        OPEN,
        LOCKED,
        WITHDRAW
    }
    enum Mode {
        CLASSIC,
        WINNER_TAKES_ALL,
        SAFE_MODE
    }

    function getWinnerFromOracle() external;

    function setAmicableResolution(uint256 _winningOutcome) external;

    function lockMarket() external;

    function claimCard(uint256 _card) external;

    function rentAllCards(uint256 _maxSumOfPrices) external;

    function newRental(
        uint256 _newPrice,
        uint256 _timeHeldLimit,
        address _startingPosition,
        uint256 _card
    ) external;

    function updateTimeHeldLimit(uint256 _timeHeldLimit, uint256 _card)
        external;

    function collectRent(uint256 _cardId) external returns (bool);

    function exitAll() external;

    function exit(uint256) external;

    function sponsor(address _sponsor, uint256 _amount) external;

    function sponsor(uint256 _amount) external;

    // payouts
    function withdraw() external;

    function payArtist() external;

    function payMarketCreator() external;

    function payAffiliate() external;

    function payCardAffiliate(uint256) external;

    // view functions
    function nfthub() external view returns (IRCNftHubL2);

    function treasury() external view returns (IRCTreasury);

    function factory() external view returns (IRCFactory);

    function leaderboard() external view returns (IRCLeaderboard);

    function orderbook() external view returns (IRCOrderbook);

    function realitio() external view returns (IRealitio);

    function mode() external view returns (Mode);

    function isMarket() external view returns (bool);

    function numberOfCards() external view returns (uint256);

    function nftsToAward() external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);

    function state() external view returns (States);

    function getTokenId(uint256 _card) external view returns (uint256 _tokenId);

    function cardAccountingIndex() external view returns (uint256);

    function accountingComplete() external view returns (bool);

    function card(uint256)
        external
        view
        returns (
            uint256 totalTimeheld,
            uint256 timeLastCollected,
            address longestOwner,
            uint256 cardTimeLimit,
            uint256 cardPrice,
            uint256 rentCollectedPerCard,
            bool cardAffiliatePaid
        );

    // prices, deposits, rent

    function rentCollectedPerUser(address) external view returns (uint256);

    function rentCollectedPerUserPerCard(address, uint256)
        external
        view
        returns (uint256);

    function totalRentCollected() external view returns (uint256);

    function exitedTimestamp(address) external view returns (uint256);

    //parameters

    function minimumPriceIncreasePercent() external view returns (uint256);

    function minRentalDayDivisor() external view returns (uint256);

    function maxRentIterations() external view returns (uint256);

    // time
    function timeHeld(uint256 _card, address _user)
        external
        view
        returns (uint256);

    function timeLastCollected(uint256 _card) external view returns (uint256);

    function longestOwner(uint256 _card) external view returns (address);

    function marketOpeningTime() external view returns (uint32);

    function marketLockingTime() external view returns (uint32);

    function oracleResolutionTime() external view returns (uint32);

    // payout settings
    function winningOutcome() external view returns (uint256);

    function userAlreadyWithdrawn(address) external view returns (bool);

    function artistAddress() external view returns (address);

    function artistCut() external view returns (uint256);

    function artistPaid() external view returns (bool);

    function affiliateAddress() external view returns (address);

    function affiliateCut() external view returns (uint256);

    function affiliatePaid() external view returns (bool);

    function winnerCut() external view returns (uint256);

    function marketCreatorAddress() external view returns (address);

    function creatorCut() external view returns (uint256);

    function creatorPaid() external view returns (bool);

    function cardAffiliateAddresses(uint256) external view returns (address);

    function cardAffiliateCut() external view returns (uint256);

    // oracle

    function questionId() external view returns (bytes32);

    function arbitrator() external view returns (address);

    function timeout() external view returns (uint32);

    function isFinalized() external view returns (bool);

    // setup
    function initialize(
        Mode _mode,
        uint32[] calldata _timestamps,
        uint256 _numberOfCards,
        address _artistAddress,
        address _affiliateAddress,
        address[] calldata _cardAffiliateAddresses,
        address _marketCreatorAddress,
        string calldata _realitioQuestion,
        uint256 _nftsToAward
    ) external;

    function transferCard(
        address _oldOwner,
        address _newOwner,
        uint256 _token,
        uint256 _price,
        uint256 _timeLimit
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

interface IRCNftHubL2 {
    function marketTracker(uint256) external view returns (address);

    function ownerOf(uint256) external view returns (address);

    function tokenURI(uint256) external view returns (string memory);

    function totalSupply() external view returns (uint256 nftCount);

    function mint(
        address,
        uint256,
        string calldata
    ) external;

    function transferNft(
        address,
        address,
        uint256
    ) external;

    function deposit(address user, bytes calldata depositData) external;

    function withdraw(uint256 tokenId) external;

    function withdrawWithMetadata(uint256 tokenId) external;

    function setTokenURI(uint256 _tokenId, string calldata _tokenURI) external;

    function mintCount() external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "./IRCTreasury.sol";

interface IRCOrderbook {
    struct Bid {
        address market;
        address next;
        address prev;
        uint64 card;
        uint128 price;
        uint64 timeHeldLimit;
    }

    function index(
        address _market,
        address _user,
        uint256 _token
    ) external view returns (uint256);

    function ownerOf(address, uint256) external view returns (address);

    function closedMarkets(uint256) external view returns (address);

    function userClosedMarketIndex(address) external view returns (uint256);

    function treasury() external view returns (IRCTreasury);

    function maxSearchIterations() external view returns (uint256);

    function maxDeletions() external view returns (uint256);

    function cleaningLoops() external view returns (uint256);

    function marketCloseLimit() external view returns (uint256);

    function nonce() external view returns (uint256);

    function cleanWastePile() external;

    function getBid(
        address _market,
        address _user,
        uint256 _card
    ) external view returns (Bid memory);

    function setTreasuryAddress(address _newTreasury) external;

    function addBidToOrderbook(
        address _user,
        uint256 _token,
        uint256 _price,
        uint256 _timeHeldLimit,
        address _prevUserAddress
    ) external;

    function removeBidFromOrderbook(address _user, uint256 _token) external;

    function closeMarket() external returns (bool);

    function findNewOwner(uint256 _token, uint256 _timeOwnershipChanged)
        external;

    function getBidValue(address _user, uint256 _token)
        external
        view
        returns (uint256);

    function getTimeHeldlimit(address _user, uint256 _token)
        external
        returns (uint256);

    function bidExists(
        address _user,
        address _market,
        uint256 _card
    ) external view returns (bool);

    function setTimeHeldlimit(
        address _user,
        uint256 _token,
        uint256 _timeHeldLimit
    ) external;

    function removeUserFromOrderbook(address _user) external;

    function removeOldBids(address _user) external;

    function reduceTimeHeldLimit(
        address _user,
        uint256 _token,
        uint256 _timeToReduce
    ) external;

    function setDeletionLimit(uint256 _deletionLimit) external;

    function setCleaningLimit(uint256 _cleaningLimit) external;

    function setSearchLimit(uint256 _searchLimit) external;

    function setMarketCloseLimit(uint256 _marketCloseLimit) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import {EIP712Base} from "./EIP712Base.sol";

contract NativeMetaTransaction is EIP712Base {
    bytes32 private constant META_TRANSACTION_TYPEHASH =
        keccak256(
            bytes(
                "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
            )
        );
    event MetaTransactionExecuted(
        address userAddress,
        address relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress] + (1);

        emit MetaTransactionExecuted(
            userAddress,
            msg.sender,
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }

    function msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            bytes(
                "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
            )
        );
    bytes32 internal domainSeperator;
    uint256 private cachedChainId;
    string private cachedName;
    string private cachedVersion;

    // supposed to be called once while initializing.
    // one of the contractsa that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(string memory name, string memory version)
        internal
        initializer
    {
        cachedChainId = getChainId();
        cachedName = name;
        cachedVersion = version;
        _setDomainSeperator(name, version);
    }

    function _setDomainSeperator(string memory name, string memory version)
        internal
    {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        if (getChainId() == cachedChainId) {
            return domainSeperator;
        } else {
            return
                keccak256(
                    abi.encode(
                        EIP712_DOMAIN_TYPEHASH,
                        keccak256(bytes(cachedName)),
                        keccak256(bytes(cachedVersion)),
                        address(this),
                        bytes32(getChainId())
                    )
                );
        }
    }

    function getChainId() public view returns (uint256) {
        return block.chainid;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}