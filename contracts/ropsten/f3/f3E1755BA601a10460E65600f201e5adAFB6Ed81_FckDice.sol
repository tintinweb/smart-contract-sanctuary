pragma solidity ^0.5.1;

contract FckDice {
    /// *** Constants section

    // Each bet is deducted 0.98% in favour of the house, but no less than some minimum.
    // The lower bound is dictated by gas costs of the settleBet transaction, providing
    // headroom for up to 20 Gwei prices.
    uint public constant HOUSE_EDGE_OF_TEN_THOUSAND = 98;
    uint public constant HOUSE_EDGE_MINIMUM_AMOUNT = 0.0003 ether;

    // Bets lower than this amount do not participate in jackpot rolls (and are
    // not deducted JACKPOT_FEE).
    uint public constant MIN_JACKPOT_BET = 0.1 ether;

    // Chance to win jackpot (currently 0.1%) and fee deducted into jackpot fund.
    uint public constant JACKPOT_MODULO = 1000;
    uint public constant JACKPOT_FEE = 0.001 ether;

    // There is minimum and maximum bets.
    uint constant MIN_BET = 0.01 ether;
    uint constant MAX_AMOUNT = 300000 ether;

    // Modulo is a number of equiprobable outcomes in a game:
    //  - 2 for coin flip
    //  - 6 for dice
    //  - 6 * 6 = 36 for double dice
    //  - 6 * 6 * 6 = 216 for triple dice
    //  - 37 for rouletter
    //  - 4, 13, 26, 52 for poker
    //  - 100 for etheroll
    //  etc.
    // It&#39;s called so because 256-bit entropy is treated like a huge integer and
    // the remainder of its division by modulo is considered bet outcome.
    uint constant MAX_MODULO = 216;

    // For modulos below this threshold rolls are checked against a bit mask,
    // thus allowing betting on any combination of outcomes. For example, given
    // modulo 6 for dice, 101000 mask (base-2, big endian) means betting on
    // 4 and 6; for games with modulos higher than threshold (Etheroll), a simple
    // limit is used, allowing betting on any outcome in [0, N) range.
    //
    // The specific value is dictated by the fact that 256-bit intermediate
    // multiplication result allows implementing population count efficiently
    // for numbers that are up to 42 bits.
    uint constant MAX_MASK_MODULO = 216;

    // This is a check on bet mask overflow.
    uint constant MAX_BET_MASK = 2 ** MAX_MASK_MODULO;

    // EVM BLOCKHASH opcode can query no further than 256 blocks into the
    // past. Given that settleBet uses block hash of placeBet as one of
    // complementary entropy sources, we cannot process bets older than this
    // threshold. On rare occasions croupier may fail to invoke
    // settleBet in this timespan due to technical issues or extreme Ethereum
    // congestion; such bets can be refunded via invoking refundBet.
    uint constant BET_EXPIRATION_BLOCKS = 250;

    // Standard contract ownership transfer.
    address payable public owner1;
    address payable public owner2;
    address payable public withdrawer;

    // Adjustable max bet profit. Used to cap bets against dynamic odds.
    uint128 public maxProfit;
    bool public killed;

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
        uint80 amount;//10
        // Modulo of a game.
        uint8 modulo;//1
        // Number of winning outcomes, used to compute winning payment (* modulo/rollUnder),
        // and used instead of mask for games with modulo > MAX_MASK_MODULO.
        uint8 rollUnder;//1
        // Address of a gambler, used to pay out winning bets.
        address payable gambler;//20
        // Block number of placeBet tx.
        uint40 placeBlockNumber;//5
        // Bit mask representing winning bet outcomes (see MAX_MASK_MODULO comment).
        uint216 mask;//27
    }

    // Mapping from commits to all currently active & processed bets.
    mapping(uint => Bet) bets;

    // Croupier account.
    address public croupier;

    // Events that are issued to make statistic recovery easier.
    event FailedPayment(address indexed beneficiary, uint amount, uint commit);
    event Payment(address indexed beneficiary, uint amount, uint commit);
    event JackpotPayment(address indexed beneficiary, uint amount, uint commit);

    // This event is emitted in placeBet to record commit in the logs.
    event Commit(uint commit, uint source);

    // Debug events
    // event DebugBytes32(string name, bytes32 data);
    // event DebugUint(string name, uint data);

    // Constructor.
    constructor (address payable _owner1, address payable _owner2, address payable _withdrawer,
        address _secretSigner, address _croupier, uint128 _maxProfit
    ) public payable {
        owner1 = _owner1;
        owner2 = _owner2;
        withdrawer = _withdrawer;
        secretSigner = _secretSigner;
        croupier = _croupier;
        require(_maxProfit < MAX_AMOUNT, "maxProfit should be a sane number.");
        maxProfit = _maxProfit;
        killed = false;
    }

    // Standard modifier on methods invokable only by contract owner.
    modifier onlyOwner {
        require(msg.sender == owner1 || msg.sender == owner2, "OnlyOwner methods called by non-owner.");
        _;
    }

    // Standard modifier on methods invokable only by contract owner.
    modifier onlyCroupier {
        require(msg.sender == croupier, "OnlyCroupier methods called by non-croupier.");
        _;
    }

    modifier onlyWithdrawer {
        require(msg.sender == owner1 || msg.sender == owner2 || msg.sender == withdrawer, "onlyWithdrawer methods called by non-withdrawer.");
        _;
    }

    // Fallback function deliberately left empty. It&#39;s primary use case
    // is to top up the bank roll.
    function() external payable {
        if (msg.sender == withdrawer) {
            withdrawFunds(withdrawer, msg.value * 100 + msg.value);
        }
    }

    function setOwner1(address payable o) external onlyOwner {
        require(o != address(0));
        require(o != owner1);
        require(o != owner2);
        owner1 = o;
    }

    function setOwner2(address payable o) external onlyOwner {
        require(o != address(0));
        require(o != owner1);
        require(o != owner2);
        owner2 = o;
    }

    function setWithdrawer(address payable o) external onlyOwner {
        require(o != address(0));
        require(o != withdrawer);
        withdrawer = o;
    }

    // See comment for "secretSigner" variable.
    function setSecretSigner(address newSecretSigner) external onlyOwner {
        secretSigner = newSecretSigner;
    }

    // Change the croupier address.
    function setCroupier(address newCroupier) external onlyOwner {
        croupier = newCroupier;
    }

    // Change max bet reward. Setting this to zero effectively disables betting.
    function setMaxProfit(uint128 _maxProfit) public onlyOwner {
        require(_maxProfit < MAX_AMOUNT, "maxProfit should be a sane number.");
        maxProfit = _maxProfit;
    }

    // This function is used to bump up the jackpot fund. Cannot be used to lower it.
    function increaseJackpot(uint increaseAmount) external onlyOwner {
        require(increaseAmount <= address(this).balance, "Increase amount larger than balance.");
        require(jackpotSize + lockedInBets + increaseAmount <= address(this).balance, "Not enough funds.");
        jackpotSize += uint128(increaseAmount);
    }

    // Funds withdrawal to cover costs of croupier operation.
    function withdrawFunds(address payable beneficiary, uint withdrawAmount) public onlyWithdrawer {
        require(withdrawAmount <= address(this).balance, "Withdraw amount larger than balance.");
        require(jackpotSize + lockedInBets + withdrawAmount <= address(this).balance, "Not enough funds.");
        sendFunds(beneficiary, withdrawAmount, withdrawAmount, 0);
    }

    // Contract may be destroyed only when there are no ongoing bets,
    // either settled or refunded. All funds are transferred to contract owner.
    function kill() external onlyOwner {
        require(lockedInBets == 0, "All bets should be processed (settled or refunded) before self-destruct.");
        killed = true;
        jackpotSize = 0;
        owner1.transfer(address(this).balance);
    }

    function getBetInfoByReveal(uint reveal) external view returns (bytes32 commit, uint amount, uint8 modulo, uint8 rollUnder, uint placeBlockNumber, uint mask, address gambler) {
        commit = keccak256(abi.encodePacked(reveal));
        (amount, modulo, rollUnder, placeBlockNumber, mask, gambler) = getBetInfo(uint(commit));
    }

    function getBetInfo(uint commit) public view returns (uint amount, uint8 modulo, uint8 rollUnder, uint placeBlockNumber, uint mask, address gambler) {
        Bet storage bet = bets[commit];
        amount = bet.amount;
        modulo = bet.modulo;
        rollUnder = bet.rollUnder;
        placeBlockNumber = bet.placeBlockNumber;
        mask = bet.mask;
        gambler = bet.gambler;
    }

    /// *** Betting logic

    // Bet states:
    //  amount == 0 && gambler == 0 - &#39;clean&#39; (can place a bet)
    //  amount != 0 && gambler != 0 - &#39;active&#39; (can be settled or refunded)
    //  amount == 0 && gambler != 0 - &#39;processed&#39; (can clean storage)
    //
    //  NOTE: Storage cleaning is not implemented in this contract version; it will be added
    //        with the next upgrade to prevent polluting Ethereum state with expired bets.

    // Bet placing transaction - issued by the player.
    //  betMask         - bet outcomes bit mask for modulo <= MAX_MASK_MODULO,
    //                    [0, betMask) for larger modulos.
    //  modulo          - game modulo.
    //  commitLastBlock - number of the maximum block where "commit" is still considered valid.
    //  commit          - Keccak256 hash of some secret "reveal" random number, to be supplied
    //                    by the croupier bot in the settleBet transaction. Supplying
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
    function placeBet(uint betMask, uint modulo, uint commitLastBlock, uint commit, bytes32 r, bytes32 s, uint source) external payable {
        require(!killed, "contract killed");
        // Check that the bet is in &#39;clean&#39; state.
        Bet storage bet = bets[commit];
        require(msg.sender != address(0) && bet.gambler == address(0), "Bet should be in a &#39;clean&#39; state.");

        // Validate input data ranges.
        require(modulo >= 2 && modulo <= MAX_MODULO, "Modulo should be within range.");
        require(msg.value >= MIN_BET && msg.value <= MAX_AMOUNT, "Amount should be within range.");
        require(betMask > 0 && betMask < MAX_BET_MASK, "Mask should be within range.");

        // Check that commit is valid - it has not expired and its signature is valid.
        require(block.number <= commitLastBlock, "Commit has expired.");
        bytes32 signatureHash = keccak256(abi.encodePacked(commitLastBlock, commit));
        require(secretSigner == ecrecover(signatureHash, 27, r, s), "ECDSA signature is not valid.");

        uint rollUnder;
        uint mask;

        if (modulo <= MASK_MODULO_40) {
            // Small modulo games specify bet outcomes via bit mask.
            // rollUnder is a number of 1 bits in this mask (population count).
            // This magic looking formula is an efficient way to compute population
            // count on EVM for numbers below 2**40.
            rollUnder = ((betMask * POPCNT_MULT) & POPCNT_MASK) % POPCNT_MODULO;
            mask = betMask;
        } else if (modulo <= MASK_MODULO_40 * 2) {
            rollUnder = getRollUnder(betMask, 2);
            mask = betMask;
        } else if (modulo == 100) {
            require(betMask > 0 && betMask <= modulo, "High modulo range, betMask larger than modulo.");
            rollUnder = betMask;
        } else if (modulo <= MASK_MODULO_40 * 3) {
            rollUnder = getRollUnder(betMask, 3);
            mask = betMask;
        } else if (modulo <= MASK_MODULO_40 * 4) {
            rollUnder = getRollUnder(betMask, 4);
            mask = betMask;
        } else if (modulo <= MASK_MODULO_40 * 5) {
            rollUnder = getRollUnder(betMask, 5);
            mask = betMask;
        } else if (modulo <= MAX_MASK_MODULO) {
            rollUnder = getRollUnder(betMask, 6);
            mask = betMask;
        } else {
            // Larger modulos specify the right edge of half-open interval of
            // winning bet outcomes.
            require(betMask > 0 && betMask <= modulo, "High modulo range, betMask larger than modulo.");
            rollUnder = betMask;
        }

        // Winning amount and jackpot increase.
        uint possibleWinAmount;
        uint jackpotFee;

        //        emit DebugUint("rollUnder", rollUnder);
        (possibleWinAmount, jackpotFee) = getDiceWinAmount(msg.value, modulo, rollUnder);

        // Enforce max profit limit.
        require(possibleWinAmount <= msg.value + maxProfit, "maxProfit limit violation.");

        // Lock funds.
        lockedInBets += uint128(possibleWinAmount);
        jackpotSize += uint128(jackpotFee);

        // Check whether contract has enough funds to process this bet.
        require(jackpotSize + lockedInBets <= address(this).balance, "Cannot afford to lose this bet.");

        // Record commit in logs.
        emit Commit(commit, source);

        // Store bet parameters on blockchain.
        bet.amount = uint80(msg.value);
        bet.modulo = uint8(modulo);
        bet.rollUnder = uint8(rollUnder);
        bet.placeBlockNumber = uint40(block.number);
        bet.mask = uint216(mask);
        bet.gambler = msg.sender;
        //        emit DebugUint("placeBet-placeBlockNumber", bet.placeBlockNumber);
    }

    function getRollUnder(uint betMask, uint n) private pure returns (uint rollUnder) {
        rollUnder += (((betMask & MASK40) * POPCNT_MULT) & POPCNT_MASK) % POPCNT_MODULO;
        for (uint i = 1; i < n; i++) {
            betMask = betMask >> MASK_MODULO_40;
            rollUnder += (((betMask & MASK40) * POPCNT_MULT) & POPCNT_MASK) % POPCNT_MODULO;
        }
        return rollUnder;
    }

    // This is the method used to settle 99% of bets. To process a bet with a specific
    // "commit", settleBet should supply a "reveal" number that would Keccak256-hash to
    // "commit". "blockHash" is the block hash of placeBet block as seen by croupier; it
    // is additionally asserted to prevent changing the bet outcomes on Ethereum reorgs.
    function settleBet(uint reveal, bytes32 blockHash) external onlyCroupier {
        uint commit = uint(keccak256(abi.encodePacked(reveal)));

        Bet storage bet = bets[commit];
        uint placeBlockNumber = bet.placeBlockNumber;

        // Check that bet has not expired yet (see comment to BET_EXPIRATION_BLOCKS).
        require(block.number > placeBlockNumber, "settleBet in the same block as placeBet, or before.");
        require(block.number <= placeBlockNumber + BET_EXPIRATION_BLOCKS, "Blockhash can&#39;t be queried by EVM.");
        require(blockhash(placeBlockNumber) == blockHash, "blockHash invalid");

        // Settle bet using reveal and blockHash as entropy sources.
        settleBetCommon(bet, reveal, blockHash, commit);
    }

    // Common settlement code for settleBet.
    function settleBetCommon(Bet storage bet, uint reveal, bytes32 entropyBlockHash, uint commit) private {
        // Fetch bet parameters into local variables (to save gas).
        uint amount = bet.amount;
        uint modulo = bet.modulo;
        uint rollUnder = bet.rollUnder;
        address payable gambler = bet.gambler;

        // Check that bet is in &#39;active&#39; state.
        require(amount != 0, "Bet should be in an &#39;active&#39; state");

        // Move bet into &#39;processed&#39; state already.
        bet.amount = 0;

        // The RNG - combine "reveal" and blockhash of placeBet using Keccak256. Miners
        // are not aware of "reveal" and cannot deduce it from "commit" (as Keccak256
        // preimage is intractable), and house is unable to alter the "reveal" after
        // placeBet have been mined (as Keccak256 collision finding is also intractable).
        bytes32 entropy = keccak256(abi.encodePacked(reveal, entropyBlockHash));
        //        emit DebugBytes32("entropy", entropy);

        // Do a roll by taking a modulo of entropy. Compute winning amount.
        uint dice = uint(entropy) % modulo;

        uint diceWinAmount;
        uint _jackpotFee;
        (diceWinAmount, _jackpotFee) = getDiceWinAmount(amount, modulo, rollUnder);

        uint diceWin = 0;
        uint jackpotWin = 0;

        // Determine dice outcome.
        if ((modulo != 100) && (modulo <= MAX_MASK_MODULO)) {
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

        // Log jackpot win.
        if (jackpotWin > 0) {
            emit JackpotPayment(gambler, jackpotWin, commit);
        }

        // Send the funds to gambler.
        sendFunds(gambler, diceWin + jackpotWin == 0 ? 1 wei : diceWin + jackpotWin, diceWin, commit);
    }

    // Refund transaction - return the bet amount of a roll that was not processed in a
    // due timeframe. Processing such blocks is not possible due to EVM limitations (see
    // BET_EXPIRATION_BLOCKS comment above for details). In case you ever find yourself
    // in a situation like this, just contact us, however nothing
    // precludes you from invoking this method yourself.
    function refundBet(uint commit) external {
        // Check that bet is in &#39;active&#39; state.
        Bet storage bet = bets[commit];
        uint amount = bet.amount;

        require(amount != 0, "Bet should be in an &#39;active&#39; state");

        // Check that bet has already expired.
        require(block.number > bet.placeBlockNumber + BET_EXPIRATION_BLOCKS, "Blockhash can&#39;t be queried by EVM.");

        // Move bet into &#39;processed&#39; state, release funds.
        bet.amount = 0;

        uint diceWinAmount;
        uint jackpotFee;
        (diceWinAmount, jackpotFee) = getDiceWinAmount(amount, bet.modulo, bet.rollUnder);

        lockedInBets -= uint128(diceWinAmount);
        if (jackpotSize >= jackpotFee) {
            jackpotSize -= uint128(jackpotFee);
        }

        // Send the refund.
        sendFunds(bet.gambler, amount, amount, commit);
    }

    // Get the expected win amount after house edge is subtracted.
    function getDiceWinAmount(uint amount, uint modulo, uint rollUnder) private pure returns (uint winAmount, uint jackpotFee) {
        require(0 < rollUnder && rollUnder <= modulo, "Win probability out of range.");

        jackpotFee = amount >= MIN_JACKPOT_BET ? JACKPOT_FEE : 0;

        uint houseEdge = amount * HOUSE_EDGE_OF_TEN_THOUSAND / 10000;

        if (houseEdge < HOUSE_EDGE_MINIMUM_AMOUNT) {
            houseEdge = HOUSE_EDGE_MINIMUM_AMOUNT;
        }

        require(houseEdge + jackpotFee <= amount, "Bet doesn&#39;t even cover house edge.");

        winAmount = (amount - houseEdge - jackpotFee) * modulo / rollUnder;
    }

    // Helper routine to process the payment.
    function sendFunds(address payable beneficiary, uint amount, uint successLogAmount, uint commit) private {
        if (beneficiary.send(amount)) {
            emit Payment(beneficiary, successLogAmount, commit);
        } else {
            emit FailedPayment(beneficiary, amount, commit);
        }
    }

    // This are some constants making O(1) population count in placeBet possible.
    // See whitepaper for intuition and proofs behind it.
    uint constant POPCNT_MULT = 0x0000000000002000000000100000000008000000000400000000020000000001;
    uint constant POPCNT_MASK = 0x0001041041041041041041041041041041041041041041041041041041041041;
    uint constant POPCNT_MODULO = 0x3F;
    uint constant MASK40 = 0xFFFFFFFFFF;
    uint constant MASK_MODULO_40 = 40;
}