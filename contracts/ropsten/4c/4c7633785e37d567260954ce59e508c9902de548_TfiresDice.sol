pragma solidity ^0.4.25;


contract TfiresDice {
    /// *** Constants section

    // Each bet is deducted 1% in favour of the house, but no less than some minimum.
    // The lower bound is dictated by gas costs of the settleBet transaction, providing
    // headroom for up to 10 Gwei prices.
    uint public HOUSE_EDGE_PERCENT = 1;
    uint public HOUSE_EDGE_MINIMUM_AMOUNT = 0.0003 ether;

    // Bets lower than this amount do not participate in jackpot rolls (and are
    // not deducted JACKPOT_FEE).
    uint public MIN_JACKPOT_BET = 0.1 ether;

    // Chance to win jackpot (currently 0.1%) and fee deducted into jackpot fund.
    uint public JACKPOT_MODULO = 1000;
    uint public JACKPOT_FEE = 0.001 ether;


    // There is minimum and maximum bets.
    uint constant MIN_BET = 0.01 ether;
    uint constant MAX_AMOUNT = 300000 ether;

    uint constant MAX_MODULO = 100;


    uint constant MAX_MASK_MODULO = 40;

    // This is a check on bet mask overflow.
    uint constant MAX_BET_MASK = 2 ** MAX_MASK_MODULO;

    uint constant BET_EXPIRATION_BLOCKS = 250;

    address public owner1;
    address public owner2;
    //    address private nextOwner;

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
    mapping(uint => Bet) bets;

    // Croupier account.
    address public croupier;

    // Events that are issued to make statistic recovery easier.
    event FailedPayment(address indexed beneficiary, uint amount);
    event Payment(address indexed beneficiary, uint amount);
    event JackpotPayment(address indexed beneficiary, uint amount);

    // This event is emitted in placeBet to record commit in the logs.
    event Commit(uint commit);

    // Constructor.
    constructor (address _owner1, address _owner2,
        address _secretSigner, address _croupier, uint _maxProfit
    ) public payable {
        owner1 = _owner1;
        owner2 = _owner2;
        secretSigner = _secretSigner;
        croupier = _croupier;
        require(_maxProfit < MAX_AMOUNT, "maxProfit should be a sane number.");
        maxProfit = _maxProfit;
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


    // Fallback function deliberately left empty. It&#39;s primary use case
    // is to top up the bank roll.
    function() public payable {
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
    function setMaxProfit(uint _maxProfit) public onlyOwner {
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
    function withdrawFunds(address beneficiary, uint withdrawAmount) external onlyOwner {
        require(withdrawAmount <= address(this).balance, "Increase amount larger than balance.");
        require(jackpotSize + lockedInBets + withdrawAmount <= address(this).balance, "Not enough funds.");
        sendFunds(beneficiary, withdrawAmount, withdrawAmount);
    }

    // Contract may be destroyed only when there are no ongoing bets,
    // either settled or refunded. All funds are transferred to contract owner.
    function kill() external onlyOwner {
        require(lockedInBets == 0, "All bets should be processed (settled or refunded) before self-destruct.");
        selfdestruct(owner1);
    }

    function getBetInfo(uint commit) external view returns (uint amount, uint8 modulo, uint8 rollUnder, uint40 placeBlockNumber, uint40 mask, address gambler) {
        Bet storage bet = bets[commit];
        amount = bet.amount;
        modulo = bet.modulo;
        rollUnder = bet.rollUnder;
        placeBlockNumber = bet.placeBlockNumber;
        mask = bet.mask;
        gambler = bet.gambler;
    }

    
    // placeBet block number plus BET_EXPIRATION_BLOCKS. See whitepaper for details.
    function placeBet(uint betMask, uint modulo, uint commitLastBlock, uint commit, bytes32 r, bytes32 s) external payable {
        // Check that the bet is in &#39;clean&#39; state.
        Bet storage bet = bets[commit];
        require(bet.gambler == address(0), "Bet should be in a &#39;clean&#39; state.");

        // Validate input data ranges.
        uint amount = msg.value;
        require(modulo > 1 && modulo <= MAX_MODULO, "Modulo should be within range.");
        require(amount >= MIN_BET && amount <= MAX_AMOUNT, "Amount should be within range.");
        require(betMask > 0 && betMask < MAX_BET_MASK, "Mask should be within range.");

        // Check that commit is valid - it has not expired and its signature is valid.
        require(block.number <= commitLastBlock, "Commit has expired.");
        bytes32 signatureHash = keccak256(abi.encodePacked(commitLastBlock, commit));
        require(secretSigner == ecrecover(signatureHash, 27, r, s), "ECDSA signature is not valid.");

        uint rollUnder;
        uint mask;

        if (modulo <= MAX_MASK_MODULO) {
            
            rollUnder = ((betMask * POPCNT_MULT) & POPCNT_MASK) % POPCNT_MODULO;
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
        (possibleWinAmount, jackpotFee) = getDiceWinAmount(amount, modulo, rollUnder);

        // Enforce max profit limit.
        require(possibleWinAmount <= amount + maxProfit, "maxProfit limit violation.");

        // Lock funds.
        lockedInBets += uint128(possibleWinAmount);
        jackpotSize += uint128(jackpotFee);

        // Check whether contract has enough funds to process this bet.
        require(jackpotSize + lockedInBets <= address(this).balance, "Cannot afford to lose this bet.");

        // Record commit in logs.
        emit Commit(commit);

        // Store bet parameters on blockchain.
        bet.amount = amount;
        bet.modulo = uint8(modulo);
        bet.rollUnder = uint8(rollUnder);
        bet.placeBlockNumber = uint40(block.number);
        bet.mask = uint40(mask);
        bet.gambler = msg.sender;
        //        emit DebugUint("placeBet-placeBlockNumber", bet.placeBlockNumber);
    }

    // This is the method used to settle 99% of bets. To process a bet with a specific
    // "commit", settleBet should supply a "reveal" number that would Keccak256-hash to
    // "commit". "blockHash" is the block hash of placeBet block as seen by croupier; it
    // is additionally asserted to prevent changing the bet outcomes on Ethereum reorgs.
    function settleBet(bytes20 reveal1, bytes20 reveal2, bytes32 blockHash) external onlyCroupier {
        uint commit = uint(keccak256(abi.encodePacked(reveal1, reveal2)));

        Bet storage bet = bets[commit];
        uint placeBlockNumber = bet.placeBlockNumber;

        //         emit DebugBytes32("settleBet-placeBlockhash", blockhash(placeBlockNumber));
        //         emit DebugUint("settleBet-placeBlockNumber", bet.placeBlockNumber);

        // Check that bet has not expired yet (see comment to BET_EXPIRATION_BLOCKS).
        require(block.number > placeBlockNumber, "settleBet in the same block as placeBet, or before.");
        require(block.number <= placeBlockNumber + BET_EXPIRATION_BLOCKS, "Blockhash can&#39;t be queried by EVM.");
        require(blockhash(placeBlockNumber) == blockHash, "blockHash invalid");

        // Settle bet using reveal and blockHash as entropy sources.
        settleBetCommon(bet, reveal1, reveal2, blockHash);
    }

    // Debug events
    //    event DebugBytes32(string name, bytes32 data);
    //    event DebugUint(string name, uint data);

    // Common settlement code for settleBet.
    function settleBetCommon(Bet storage bet, bytes20 reveal1, bytes20 reveal2, bytes32 entropyBlockHash) private {
        // Fetch bet parameters into local variables (to save gas).
        uint amount = bet.amount;
        uint modulo = bet.modulo;
        uint rollUnder = bet.rollUnder;
        address gambler = bet.gambler;

        // Check that bet is in &#39;active&#39; state.
        require(amount != 0, "Bet should be in an &#39;active&#39; state");

        // Move bet into &#39;processed&#39; state already.
        bet.amount = 0;
        
        bytes32 entropy = keccak256(abi.encodePacked(reveal1, entropyBlockHash, reveal2));
        //emit DebugBytes32("entropy", entropy);

        // Do a roll by taking a modulo of entropy. Compute winning amount.
        uint dice = uint(entropy) % modulo;

        uint diceWinAmount;
        uint _jackpotFee;
        (diceWinAmount, _jackpotFee) = getDiceWinAmount(amount, modulo, rollUnder);

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

        // Log jackpot win.
        if (jackpotWin > 0) {
            emit JackpotPayment(gambler, jackpotWin);
        }

        // Send the funds to gambler.
        sendFunds(gambler, diceWin + jackpotWin == 0 ? 1 wei : diceWin + jackpotWin, diceWin);
    }

    // Refund transaction - return the bet amount of a roll that was not processed in a
    // due timeframe. Processing such blocks is not possible due to EVM limitations (see
    // BET_EXPIRATION_BLOCKS comment above for details). In case you ever find yourself
    // in a situation like this, just contact the fck.com support, however nothing
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
        jackpotSize -= uint128(jackpotFee);

        // Send the refund.
        sendFunds(bet.gambler, amount, amount);
    }

    // Get the expected win amount after house edge is subtracted.
    function getDiceWinAmount(uint amount, uint modulo, uint rollUnder) private view returns (uint winAmount, uint jackpotFee) {
        require(0 < rollUnder && rollUnder <= modulo, "Win probability out of range.");

        jackpotFee = amount >= MIN_JACKPOT_BET ? JACKPOT_FEE : 0;

        uint houseEdge = amount * HOUSE_EDGE_PERCENT / 100;

        if (houseEdge < HOUSE_EDGE_MINIMUM_AMOUNT) {
            houseEdge = HOUSE_EDGE_MINIMUM_AMOUNT;
        }

        require(houseEdge + jackpotFee <= amount, "Bet doesn&#39;t even cover house edge.");

        winAmount = (amount - houseEdge - jackpotFee) * modulo / rollUnder;
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
    uint constant POPCNT_MULT = 0x0000000000002000000000100000000008000000000400000000020000000001;
    uint constant POPCNT_MASK = 0x0001041041041041041041041041041041041041041041041041041041041041;
    uint constant POPCNT_MODULO = 0x3F;
}