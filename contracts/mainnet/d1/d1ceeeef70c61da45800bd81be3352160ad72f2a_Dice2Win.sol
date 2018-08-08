pragma solidity ^0.4.23;

contract Dice2Win {

    /// Constants

    // Chance to win jackpot - currently 0.1%
    uint256 constant JACKPOT_MODULO = 1000;

    // Each bet is deducted 2% amount - 1% is house edge, 1% goes to jackpot fund.
    uint256 constant HOUSE_EDGE_PERCENT = 2;
    uint256 constant JACKPOT_FEE_PERCENT = 50;

    // Minimum supported bet is 0.02 ETH, made possible by optimizing gas costs
    // compared to our competitors.
    uint256 constant MIN_BET = 0.02 ether;

    // Only bets higher that 0.1 ETH have a chance to win jackpot.
    uint256 constant MIN_JACKPOT_BET = 0.1 ether;

    // Random number generation is provided by the hashes of future blocks.
    // Two blocks is a good compromise between responsive gameplay and safety from miner attacks.
    uint256 constant BLOCK_DELAY = 2;

    // Bets made more than 100 blocks ago are considered failed - this has to do
    // with EVM limitations on block hashes that are queryable. Settlement failure
    // is most probably due to croupier bot failure, if you ever end in this situation
    // ask dice2.win support for a refund!
    uint256 constant BET_EXPIRATION_BLOCKS = 100;

    /// Contract storage.

    // Changing ownership of the contract safely
    address public owner;
    address public nextOwner;

    // Max bet limits for coin toss/single dice and double dice respectively.
    // Setting these values to zero effectively disables the respective games.
    uint256 public maxBetCoinDice;
    uint256 public maxBetDoubleDice;

    // Current jackpot size.
    uint128 public jackpotSize;

    // Amount locked in ongoing bets - this is to be sure that we do not commit to bets
    // that we cannot fulfill in case of win.
    uint128 public lockedInBets;

    /// Enum representing games

    enum GameId {
        CoinFlip,
        SingleDice,
        DoubleDice,

        MaxGameId
    }

    uint256 constant MAX_BLOCK_NUMBER = 2 ** 56;
    uint256 constant MAX_BET_MASK = 2 ** 64;
    uint256 constant MAX_AMOUNT = 2 ** 128;

    // Struct is tightly packed into a single 256-bit by Solidity compiler.
    // This is made to reduce gas costs of placing & settlement transactions.
    struct ActiveBet {
        // A game that was played.
        GameId gameId;
        // Block number in which bet transaction was mined.
        uint56 placeBlockNumber;
        // A binary mask with 1 for each option.
        // For example, if you play dice, the mask ranges from 000001 in binary (betting on one)
        // to 111111 in binary (betting on all dice outcomes at once).
        uint64 mask;
        // Bet amount in wei.
        uint128 amount;
    }

    mapping (address => ActiveBet) activeBets;

    // Events that are issued to make statistic recovery easier.
    event FailedPayment(address indexed _beneficiary, uint256 amount);
    event Payment(address indexed _beneficiary, uint256 amount);
    event JackpotPayment(address indexed _beneficiary, uint256 amount);

    /// Contract governance.

    constructor () public {
        owner = msg.sender;
        // all fields are automatically initialized to zero, which is just what&#39;s needed.
    }

    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }

    // This is pretty standard ownership change routine.

    function approveNextOwner(address _nextOwner) public onlyOwner {
        require (_nextOwner != owner);
        nextOwner = _nextOwner;
    }

    function acceptNextOwner() public {
        require (msg.sender == nextOwner);
        owner = nextOwner;
    }

    // Contract may be destroyed only when there are no ongoing bets,
    // either settled or refunded. All funds are transferred to contract owner.

    function kill() public onlyOwner {
        require (lockedInBets == 0);
        selfdestruct(owner);
    }

    // Fallback function deliberately left empty. It&#39;s primary use case
    // is to top up the bank roll.
    function () public payable {
    }

    // Helper routines to alter the respective max bet limits.
    function changeMaxBetCoinDice(uint256 newMaxBetCoinDice) public onlyOwner {
        maxBetCoinDice = newMaxBetCoinDice;
    }

    function changeMaxBetDoubleDice(uint256 newMaxBetDoubleDice) public onlyOwner {
        maxBetDoubleDice = newMaxBetDoubleDice;
    }

    // Ability to top up jackpot faster than it&#39;s natural growth by house fees.
    function increaseJackpot(uint256 increaseAmount) public onlyOwner {
        require (increaseAmount <= address(this).balance);
        require (jackpotSize + lockedInBets + increaseAmount <= address(this).balance);
        jackpotSize += uint128(increaseAmount);
    }

    // Funds withdrawal to cover costs of dice2.win operation.
    function withdrawFunds(address beneficiary, uint256 withdrawAmount) public onlyOwner {
        require (withdrawAmount <= address(this).balance);
        require (jackpotSize + lockedInBets + withdrawAmount <= address(this).balance);
        sendFunds(beneficiary, withdrawAmount, withdrawAmount);
    }

    /// Betting logic

    // Bet transaction - issued by player. Contains the desired game id and betting options
    // mask. Wager is the value in ether attached to the transaction.
    function placeBet(GameId gameId, uint256 betMask) public payable {
        // Check that there is no ongoing bet already - we support one game at a time
        // from single address.
        ActiveBet storage bet = activeBets[msg.sender];
        require (bet.amount == 0);

        // Check that the values passed fit into respective limits.
        require (gameId < GameId.MaxGameId);
        require (msg.value >= MIN_BET && msg.value <= getMaxBet(gameId));
        require (betMask < MAX_BET_MASK);

        // Determine roll parameters.
        uint256 rollModulo = getRollModulo(gameId);
        uint256 rollUnder = getRollUnder(rollModulo, betMask);

        // Check whether contract has enough funds to process this bet.
        uint256 reservedAmount = getDiceWinAmount(msg.value, rollModulo, rollUnder);
        uint256 jackpotFee = getJackpotFee(msg.value);
        require (jackpotSize + lockedInBets + reservedAmount + jackpotFee <= address(this).balance);

        // Update reserved amounts.
        lockedInBets += uint128(reservedAmount);
        jackpotSize += uint128(jackpotFee);

        // Store the bet parameters on blockchain.
        bet.gameId = gameId;
        bet.placeBlockNumber = uint56(block.number);
        bet.mask = uint64(betMask);
        bet.amount = uint128(msg.value);
    }

    // Settlement transaction - can be issued by anyone, but is designed to be handled by the
    // dice2.win croupier bot. However nothing prevents you from issuing it yourself, or anyone
    // issuing the settlement transaction on your behalf - that does not affect the bet outcome and
    // is in fact encouraged in the case the croupier bot malfunctions.
    function settleBet(address gambler) public {
        // Check that there is already a bet for this gambler.
        ActiveBet storage bet = activeBets[gambler];
        require (bet.amount != 0);

        // Check that the bet is neither too early nor too late.
        require (block.number > bet.placeBlockNumber + BLOCK_DELAY);
        require (block.number <= bet.placeBlockNumber + BET_EXPIRATION_BLOCKS);

        // The RNG - use hash of the block that is unknown at the time of placing the bet,
        // SHA3 it with gambler address. The latter step is required to make the outcomes of
        // different settlement transactions mined into the same block different.
        bytes32 entropy = keccak256(gambler, blockhash(bet.placeBlockNumber + BLOCK_DELAY));

        uint256 diceWin = 0;
        uint256 jackpotWin = 0;

        // Determine roll parameters, do a roll by taking a modulo of entropy.
        uint256 rollModulo = getRollModulo(bet.gameId);
        uint256 dice = uint256(entropy) % rollModulo;

        uint256 rollUnder = getRollUnder(rollModulo, bet.mask);
        uint256 diceWinAmount = getDiceWinAmount(bet.amount, rollModulo, rollUnder);

        // Check the roll result against the bet bit mask.
        if ((2 ** dice) & bet.mask != 0) {
            diceWin = diceWinAmount;
        }

        // Unlock the bet amount, regardless of the outcome.
        lockedInBets -= uint128(diceWinAmount);

        // Roll for a jackpot (if eligible).
        if (bet.amount >= MIN_JACKPOT_BET) {
            // The second modulo, statistically independent from the "main" dice roll.
            // Effectively you are playing two games at once!
            uint256 jackpotRng = (uint256(entropy) / rollModulo) % JACKPOT_MODULO;

            // Bingo!
            if (jackpotRng == 0) {
                jackpotWin = jackpotSize;
                jackpotSize = 0;
            }
        }

        // Remove the processed bet from blockchain storage.
        delete activeBets[gambler];

        // Tally up the win.
        uint256 totalWin = diceWin + jackpotWin;

        if (totalWin == 0) {
            totalWin = 1 wei;
        }

        if (jackpotWin > 0) {
            emit JackpotPayment(gambler, jackpotWin);
        }

        // Send the funds to gambler.
        sendFunds(gambler, totalWin, diceWin);
    }

    // Refund transaction - return the bet amount of a roll that was not processed
    // in due timeframe (100 Ethereum blocks). Processing such bets is not possible,
    // because EVM does not have access to the hashes further than 256 blocks ago.
    //
    // Like settlement, this transaction may be issued by anyone, but if you ever
    // find yourself in situation like this, just contact the dice2.win support!
    function refundBet(address gambler) public {
        // Check that there is already a bet for this gambler.
        ActiveBet storage bet = activeBets[gambler];
        require (bet.amount != 0);

        // The bet should be indeed late.
        require (block.number > bet.placeBlockNumber + BET_EXPIRATION_BLOCKS);

        // Determine roll parameters to calculate correct amount of funds locked.
        uint256 rollModulo = getRollModulo(bet.gameId);
        uint256 rollUnder = getRollUnder(rollModulo, bet.mask);

        lockedInBets -= uint128(getDiceWinAmount(bet.amount, rollModulo, rollUnder));

        // Delete the bet from the blockchain.
        uint256 refundAmount = bet.amount;
        delete activeBets[gambler];

        // Refund the bet.
        sendFunds(gambler, refundAmount, refundAmount);
    }

    /// Helper routines.

    // Number of bet options for specific game.
    function getRollModulo(GameId gameId) pure private returns (uint256) {
        if (gameId == GameId.CoinFlip) {
            // Heads/tails
            return 2;

        } else if (gameId == GameId.SingleDice) {
            // One through six.
            return 6;

        } else if (gameId == GameId.DoubleDice) {
            // 6*6=36 possible outcomes.
            return 36;

        }
    }

    // Max bet amount for a specific game.
    function getMaxBet(GameId gameId) view private returns (uint256) {
        if (gameId == GameId.CoinFlip) {
            return maxBetCoinDice;

        } else if (gameId == GameId.SingleDice) {
            return maxBetCoinDice;

        } else if (gameId == GameId.DoubleDice) {
            return maxBetDoubleDice;

        }
    }

    // Count 1 bits in the bet bit mask to find the total number of bet options
    function getRollUnder(uint256 rollModulo, uint256 betMask) pure private returns (uint256) {
        uint256 rollUnder = 0;
        uint256 singleBitMask = 1;
        for (uint256 shift = 0; shift < rollModulo; shift++) {
            if (betMask & singleBitMask != 0) {
                rollUnder++;
            }

            singleBitMask *= 2;
        }

        return rollUnder;
    }

    // Get the expected win amount after house edge is subtracted.
    function getDiceWinAmount(uint256 amount, uint256 rollModulo, uint256 rollUnder) pure private
      returns (uint256) {
        require (0 < rollUnder && rollUnder <= rollModulo);
        return amount * rollModulo / rollUnder * (100 - HOUSE_EDGE_PERCENT) / 100;
    }

    // Get the portion of bet amount that is to be accumulated in the jackpot.
    function getJackpotFee(uint256 amount) pure private returns (uint256) {
        return amount * HOUSE_EDGE_PERCENT / 100 * JACKPOT_FEE_PERCENT / 100;
    }

    // Helper routine to process the payment.
    function sendFunds(address beneficiary, uint256 amount, uint256 successLogAmount) private {
        if (beneficiary.send(amount)) {
            emit Payment(beneficiary, successLogAmount);
        } else {
            emit FailedPayment(beneficiary, amount);
        }
    }

}