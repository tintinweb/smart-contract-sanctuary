pragma solidity ^0.4.23;

// * dice2.win - fair games that pay Ether.
// * Ethereum smart contract, deployed at 0xD1CEeee3ecFff60d9532C37c9d24f68cA0E96453
// * Uses hybrid commit-reveal + block hash random number generation that is immune
//   to tampering by players, house and miners. Apart from being fully transparent,
//   this also allows arbitrarily high bets.
// * Refer to https://dice2.win/whitepaper.pdf for detailed description and proofs.

contract Dice2Win {
    /// *** Constants section

    // Chance to win jackpot - currently 0.1%
    uint constant JACKPOT_MODULO = 1000;

    // Each bet is deducted 2% amount - 1% is house edge, 1% goes to jackpot fund.
    uint constant HOUSE_EDGE_PERCENT = 2;
    uint constant JACKPOT_FEE_PERCENT = 50;

    // There is a minimum and maximum bets. Minimum is dictated by the gas usage
    // of settlement transactions, and maximum is just some safe & sane number.
    uint constant MIN_BET = 0.01 ether;
    uint constant MAX_AMOUNT = 300000 ether;

    // Bets lower than this amount do not participate in jackpot rolls.
    uint constant MIN_JACKPOT_BET = 0.1 ether;

    // Modulo is a number of equiprobable outcomes in a game:
    //  - 2 for coin flip
    //  - 6 for dice
    //  - 6*6 = 36 for double dice
    //  - 100 for etheroll
    //  - 37 for roulette
    //  etc.
    // It&#39;s called so because 256-bit entropy is treated like a huge integer and
    // the remainder of its division by modulo is considered bet outcome.
    uint constant MAX_MODULO = 100;

    // For modulos below this threshold rolls are checked against a bit mask,
    // thus allowing betting on any combination of outcomes. For example, given
    // modulo 6 for dice, 101000 mask (base-2, big endian) means betting on
    // 4 and 6; for games with modulos higher than threshold (Etheroll), a simple
    // limit is used, allowing betting on any outcome in [0, N) range.
    //
    // The specific value is dictated by the fact that 256-bit intermediate
    // multiplication result allows implementing population count efficiently
    // for numbers that are up to 42 bits, and 40 is the highest multiple of
    // eight below 42.
    uint constant MAX_MASK_MODULO = 40;

    // This is a check on bet mask overflow.
    uint constant MAX_BET_MASK = 2 ** MAX_MASK_MODULO;

    // EVM BLOCKHASH opcode can query no further than 256 blocks into the
    // past. Given that settleBet uses block hash of placeBet as one of
    // complementary entropy sources, we cannot process bets older than this
    // threshold. On rare occasions dice2.win croupier may fail to invoke
    // settleBet in this timespan due to technical issues or extreme Ethereum
    // congestion; such bets can be refunded via invoking refundBet.
    uint constant BET_EXPIRATION_BLOCKS = 250;

    // Some deliberately invalid address to initialize the secret signer with.
    // Forces maintainers to invoke setSecretSigner before processing any bets.
    address constant DUMMY_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // Standard contract ownership transfer.
    address public owner;
    address private nextOwner;

    // Adjustable max bet profit. Used to cap bets against dynamic odds.
    uint public maxProfit;

    // The address corresponding to a private key used to sign placeBet commits.
    address public secretSigner;

    // Accumulated jackpot fund.
    uint128 public jackpotSize;

    // Funds that are locked in potentially winning bets. Prevents contract from
    // committing to bets it cannot pay out.
    uint128 public lockedInBets;

    // A structure representing a single bet.
    struct Bet {
        // Wager amount in wei.
        uint amount;
        // Modulo of a game.
        uint8 modulo;
        // Number of winning outcomes, used to compute winning payment (* modulo/rollUnder),
        // and used instead of mask for games with modulo > MAX_MASK_MODULO.
        uint8 rollUnder;
        // Block number of placeBet tx.
        uint40 placeBlockNumber;
        // Bit mask representing winning bet outcomes (see MAX_MASK_MODULO comment).
        uint40 mask;
        // Address of a gambler, used to pay out winning bets.
        address gambler;
    }

    // Mapping from commits to all currently active & processed bets.
    mapping (uint => Bet) bets;

    // Events that are issued to make statistic recovery easier.
    event FailedPayment(address indexed _beneficiary, uint amount);
    event Payment(address indexed _beneficiary, uint amount);
    event JackpotPayment(address indexed _beneficiary, uint amount);

    // Constructor. Deliberately does not take any parameters.
    constructor () public {
        owner = msg.sender;
        secretSigner = DUMMY_ADDRESS;
    }

    // Standard modifier on methods invokable only by contract owner.
    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }

    // Standard contract ownership transfer implementation,
    function approveNextOwner(address _nextOwner) external onlyOwner {
        require (_nextOwner != owner);
        nextOwner = _nextOwner;
    }

    function acceptNextOwner() external {
        require (msg.sender == nextOwner);
        owner = nextOwner;
    }

    // Fallback function deliberately left empty. It&#39;s primary use case
    // is to top up the bank roll.
    function () public payable {
    }

    // See comment for "secretSigner" variable.
    function setSecretSigner(address newSecretSigner) external onlyOwner {
        secretSigner = newSecretSigner;
    }

    // Change max bet reward. Setting this to zero effectively disables betting.
    function setMaxProfit(uint newMaxProfit) public onlyOwner {
        require (newMaxProfit < MAX_AMOUNT);
        maxProfit = newMaxProfit;
    }

    // This function is used to bump up the jackpot fund. Cannot be used to lower it.
    function increaseJackpot(uint increaseAmount) external onlyOwner {
        require (increaseAmount <= address(this).balance);
        require (jackpotSize + lockedInBets + increaseAmount <= address(this).balance);
        jackpotSize += uint128(increaseAmount);
    }

    // Funds withdrawal to cover costs of dice2.win operation.
    function withdrawFunds(address beneficiary, uint withdrawAmount) external onlyOwner {
        require (withdrawAmount <= address(this).balance);
        require (jackpotSize + lockedInBets + withdrawAmount <= address(this).balance);
        sendFunds(beneficiary, withdrawAmount, withdrawAmount);
    }

    // Contract may be destroyed only when there are no ongoing bets,
    // either settled or refunded. All funds are transferred to contract owner.
    function kill() external onlyOwner {
        require (lockedInBets == 0);
        selfdestruct(owner);
    }

    /// *** Betting logic

    // Bet states:
    //  amount == 0 && gambler == 0 - &#39;clean&#39; (can place a bet)
    //  amount != 0 && gambler != 0 - &#39;active&#39; (can be settled or refunded)
    //  amount == 0 && gambler != 0 - &#39;processed&#39; (can clean storage)

    // Bet placing transaction - issued by the player.
    //  betMask         - bet outcomes bit mask for modulo <= MAX_MASK_MODULO,
    //                    [0, betMask) for larger modulos.
    //  modulo          - game modulo.
    //  commitLastBlock - number of the maximum block where "commit" is still considered valid.
    //  commit          - Keccak256 hash of some secret "reveal" random number, to be supplied
    //                    by the dice2.win croupier bot in the settleBet transaction. Supplying
    //                    "commit" ensures that "reveal" cannot be changed behind the scenes
    //                    after placeBet have been mined.
    //  r, s            - components of ECDSA signature of (commitLastBlock, commit). v is
    //                    guaranteed to always equal 27.
    //
    // Commit, being essentially random 256-bit number, is used as a unique bet identifier in
    // the &#39;bets&#39; mapping.
    //
    // Commits are signed with a block limit to ensure that they are used at most once - otherwise
    // it would be possible for a miner to place a bet with a known commit/reveal pair and tamper
    // with the blockhash. Croupier guarantees that commitLastBlock will always be not greater than
    // placeBet block number plus BET_EXPIRATION_BLOCKS. See whitepaper for details.
    function placeBet(uint betMask, uint modulo,
                      uint commitLastBlock, uint commit, bytes32 r, bytes32 s) external payable {
        // Check that the bet is in &#39;clean&#39; state.
        Bet storage bet = bets[commit];
        require (bet.gambler == address(0));

        // Validate input data ranges.
        uint amount = msg.value;
        require (modulo > 1 && modulo <= MAX_MODULO);
        require (amount >= MIN_BET && amount <= MAX_AMOUNT);
        require (betMask > 0 && betMask < MAX_BET_MASK);

        // Check that commit is valid - it has not expired and its signature is valid.
        require (block.number <= commitLastBlock);
        bytes32 signatureHash = keccak256(abi.encodePacked(uint40(commitLastBlock), commit));
        require (secretSigner == ecrecover(signatureHash, 27, r, s));

        uint rollUnder;
        uint mask;

        if (modulo <= MAX_MASK_MODULO) {
            // Small modulo games specify bet outcomes via bit mask.
            // rollUnder is a number of 1 bits in this mask (population count).
            // This magic looking formula is an efficient way to compute population
            // count on EVM for numbers below 2**40. For detailed proof consult
            // the dice2.win whitepaper.
            rollUnder = ((betMask * POPCNT_MULT) & POPCNT_MASK) % POPCNT_MODULO;
            mask = betMask;
        } else {
            // Larger modulos specify the right edge of half-open interval of
            // winning bet outcomes.
            require (betMask > 0 && betMask <= modulo);
            rollUnder = betMask;
        }

        // Winning amount and jackpot increase.
        uint possibleWinAmount = getDiceWinAmount(amount, modulo, rollUnder);
        uint jackpotFee = getJackpotFee(amount);

        // Enforce max profit limit.
        require (possibleWinAmount <= amount + maxProfit);

        // Lock funds.
        lockedInBets += uint128(possibleWinAmount);
        jackpotSize += uint128(jackpotFee);

        // Check whether contract has enough funds to process this bet.
        require (jackpotSize + lockedInBets <= address(this).balance);

        // Store bet parameters on blockchain.
        bet.amount = amount;
        bet.modulo = uint8(modulo);
        bet.rollUnder = uint8(rollUnder);
        bet.placeBlockNumber = uint40(block.number);
        bet.mask = uint40(mask);
        bet.gambler = msg.sender;
    }

    // Settlement transaction - can in theory be issued by anyone, but is designed to be
    // handled by the dice2.win croupier bot. To settle a bet with a specific "commit",
    // settleBet should supply a "reveal" number that would Keccak256-hash to
    // "commit". clean_commit is some previously &#39;processed&#39; bet, that will be moved into
    // &#39;clean&#39; state to prevent blockchain bloat and refund some gas.
    function settleBet(uint reveal, uint clean_commit) external {
        // "commit" for bet settlement can only be obtained by hashing a "reveal".
        uint commit = uint(keccak256(abi.encodePacked(reveal)));

        // Fetch bet parameters into local variables (to save gas).
        Bet storage bet = bets[commit];
        uint amount = bet.amount;
        uint modulo = bet.modulo;
        uint rollUnder = bet.rollUnder;
        uint placeBlockNumber = bet.placeBlockNumber;
        address gambler = bet.gambler;

        // Check that bet is in &#39;active&#39; state.
        require (amount != 0);

        // Check that bet has not expired yet (see comment to BET_EXPIRATION_BLOCKS).
        require (block.number > placeBlockNumber);
        require (block.number <= placeBlockNumber + BET_EXPIRATION_BLOCKS);

        // Move bet into &#39;processed&#39; state already.
        bet.amount = 0;

        // The RNG - combine "reveal" and blockhash of placeBet using Keccak256. Miners
        // are not aware of "reveal" and cannot deduce it from "commit" (as Keccak256
        // preimage is intractable), and house is unable to alter the "reveal" after
        // placeBet have been mined (as Keccak256 collision finding is also intractable).
        bytes32 entropy = keccak256(abi.encodePacked(reveal, blockhash(placeBlockNumber)));

        // Do a roll by taking a modulo of entropy. Compute winning amount.
        uint dice = uint(entropy) % modulo;
        uint diceWinAmount = getDiceWinAmount(amount, modulo, rollUnder);

        uint diceWin = 0;
        uint jackpotWin = 0;

        // Determine dice outcome.
        if (modulo <= MAX_MASK_MODULO) {
            // For small modulo games, check the outcome against a bit mask.
            if ((2 ** dice) & bet.mask != 0) {
                diceWin = diceWinAmount;
            }

        } else {
            // For larger modulos, check inclusion into half-open interval.
            if (dice < rollUnder) {
                diceWin = diceWinAmount;
            }

        }

        // Unlock the bet amount, regardless of the outcome.
        lockedInBets -= uint128(diceWinAmount);

        // Roll for a jackpot (if eligible).
        if (amount >= MIN_JACKPOT_BET) {
            // The second modulo, statistically independent from the "main" dice roll.
            // Effectively you are playing two games at once!
            uint jackpotRng = (uint(entropy) / modulo) % JACKPOT_MODULO;

            // Bingo!
            if (jackpotRng == 0) {
                jackpotWin = jackpotSize;
                jackpotSize = 0;
            }
        }

        // Tally up the win.
        uint totalWin = diceWin + jackpotWin;

        if (totalWin == 0) {
            totalWin = 1 wei;
        }

        // Log jackpot win.
        if (jackpotWin > 0) {
            emit JackpotPayment(gambler, jackpotWin);
        }

        // Send the funds to gambler.
        sendFunds(gambler, totalWin, diceWin);

        // Clear storage of some previous bet.
        if (clean_commit == 0) {
            return;
        }

        clearProcessedBet(clean_commit);
    }

    // Refund transaction - return the bet amount of a roll that was not processed in a
    // due timeframe. Processing such blocks is not possible due to EVM limitations (see
    // BET_EXPIRATION_BLOCKS comment above for details). In case you ever find yourself
    // in a situation like this, just contact the dice2.win support, however nothing
    // precludes you from invoking this method yourself.
    function refundBet(uint commit) external {
        // Check that bet is in &#39;active&#39; state.
        Bet storage bet = bets[commit];
        uint amount = bet.amount;

        require (amount != 0);

        // Check that bet has already expired.
        require (block.number > bet.placeBlockNumber + BET_EXPIRATION_BLOCKS);

        // Move bet into &#39;processed&#39; state, release funds.
        bet.amount = 0;
        lockedInBets -= uint128(getDiceWinAmount(amount, bet.modulo, bet.rollUnder));

        // Send the refund.
        sendFunds(bet.gambler, amount, amount);
    }

    // A helper routine to bulk clean the storage.
    function clearStorage(uint[] clean_commits) external {
        uint length = clean_commits.length;

        for (uint i = 0; i < length; i++) {
            clearProcessedBet(clean_commits[i]);
        }
    }

    // Helper routine to move &#39;processed&#39; bets into &#39;clean&#39; state.
    function clearProcessedBet(uint commit) private {
        Bet storage bet = bets[commit];

        // Do not overwrite active bets with zeros; additionally prevent cleanup of bets
        // for which commit signatures may have not expired yet (see whitepaper for details).
        if (bet.amount != 0 || block.number <= bet.placeBlockNumber + BET_EXPIRATION_BLOCKS) {
            return;
        }

        // Zero out the remaining storage (amount was zeroed before, delete would consume 5k
        // more gas).
        bet.modulo = 0;
        bet.rollUnder = 0;
        bet.placeBlockNumber = 0;
        bet.mask = 0;
        bet.gambler = address(0);
    }

    // Get the expected win amount after house edge is subtracted.
    function getDiceWinAmount(uint amount, uint modulo, uint rollUnder) pure private returns (uint) {
        require (0 < rollUnder && rollUnder <= modulo);
        return amount * modulo / rollUnder * (100 - HOUSE_EDGE_PERCENT) / 100;
    }

    // Get the portion of bet amount that is to be accumulated in the jackpot.
    function getJackpotFee(uint amount) pure private returns (uint) {
        return amount * HOUSE_EDGE_PERCENT / 100 * JACKPOT_FEE_PERCENT / 100;
    }

    // Helper routine to process the payment.
    function sendFunds(address beneficiary, uint amount, uint successLogAmount) private {
        if (beneficiary.send(amount)) {
            emit Payment(beneficiary, successLogAmount);
        } else {
            emit FailedPayment(beneficiary, amount);
        }
    }

    // This are some constants making O(1) population count in placeBet possible.
    // See whitepaper for intuition and proofs behind it.
    uint constant POPCNT_MULT = 1 + 2**41 + 2**(41*2) + 2**(41*3) + 2**(41*4) + 2**(41*5);
    uint constant POPCNT_MASK = 1 + 2**(6*1) + 2**(6*2) + 2**(6*3) + 2**(6*4) + 2**(6*5)
        + 2**(6*6) + 2**(6*7) + 2**(6*8) + 2**(6*9) + 2**(6*10) + 2**(6*11) + 2**(6*12)
        + 2**(6*13) + 2**(6*14) + 2**(6*15) + 2**(6*16) + 2**(6*17) + 2**(6*18) + 2**(6*19)
        + 2**(6*20) + 2**(6*21) + 2**(6*22) + 2**(6*23) + 2**(6*24) + 2**(6*25) + 2**(6*26)
        + 2**(6*27) + 2**(6*28) + 2**(6*29) + 2**(6*30) + 2**(6*31) + 2**(6*32) + 2**(6*33)
        + 2**(6*34) + 2**(6*35) + 2**(6*36) + 2**(6*37) + 2**(6*38) + 2**(6*39) + 2**(6*40);

    uint constant POPCNT_MODULO = 2**6 - 1;

}