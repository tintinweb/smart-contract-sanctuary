/**
 *Submitted for verification at BscScan.com on 2021-10-02
*/

pragma solidity ^0.4.24;

contract DiceGame {
    /// *** Constants section
    // Each bet is deducted 1% in favour of the house, but no less than some minimum.
    // The lower bound is dictated by gas costs of the settleBet transaction, providing
    // headroom for up to 10 Gwei prices.
    uint constant HOUSE_EDGE_PERCENT = 1;
    uint constant HOUSE_EDGE_MINIMUM_AMOUNT = 0.0003 ether;
    // Bets lower than this amount do not participate in jackpot rolls (and are
    // not deducted JACKPOT_FEE).
    uint constant MIN_JACKPOT_BET = 0.1 ether;
    // Chance to win jackpot (currently 0.1%) and fee deducted into jackpot fund.
    uint constant JACKPOT_MODULO = 1000;
    uint constant JACKPOT_FEE = 0.001 ether;
    // There is minimum and maximum bets.
    uint constant MIN_BET = 0.01 ether;
    uint constant MAX_AMOUNT = 300000 ether;
    // Modulo is a number of equiprobable outcomes in a game:
    //  - 2 for coin flip
    //  - 6 for dice
    //  - 6*6 = 36 for double dice
    //  - 100 for etheroll
    //  - 37 for roulette
    //  etc.
    // It's called so because 256-bit entropy is treated like a huge integer and
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

    // Croupier account.
    address public croupier;

    // Events that are issued to make statistic recovery easier.
    event FailedPayment(address indexed beneficiary, uint amount);
    event Payment(address indexed beneficiary, uint amount);
    event JackpotPayment(address indexed beneficiary, uint amount);
    // This event is emitted in placeBet to record commit in the logs.
    event Commit(uint commit);
    // Constructor. Deliberately does not take any parameters.
    constructor () public {
        owner = msg.sender;
        secretSigner = DUMMY_ADDRESS;
        croupier = DUMMY_ADDRESS;
    }

    // Standard modifier on methods invokable only by contract owner.
    modifier onlyOwner {
        require (msg.sender == owner, "OnlyOwner methods called by non-owner.");
        _;
    }

    // Standard modifier on methods invokable only by contract owner.
    modifier onlyCroupier {
        require (msg.sender == croupier, "OnlyCroupier methods called by non-croupier.");
        _;
    }

    // Standard contract ownership transfer implementation,
    function approveNextOwner(address _nextOwner) external onlyOwner {
        require (_nextOwner != owner, "Cannot approve current owner.");
        nextOwner = _nextOwner;
    }
    function acceptNextOwner() external {
        require (msg.sender == nextOwner, "Can only accept preapproved new owner.");
        owner = nextOwner;
    }
    // Fallback function deliberately left empty. It's primary use case
    // is to top up the bank roll.
    function () public payable {
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
        require (_maxProfit < MAX_AMOUNT, "maxProfit should be a sane number.");
        maxProfit = _maxProfit;
    }
    // This function is used to bump up the jackpot fund. Cannot be used to lower it.
    function increaseJackpot(uint increaseAmount) external onlyOwner {
        require (increaseAmount <= address(this).balance, "Increase amount larger than balance.");
        require (jackpotSize + lockedInBets + increaseAmount <= address(this).balance, "Not enough funds.");
        jackpotSize += uint128(increaseAmount);
    }
    // Funds withdrawal to cover costs of dice2.win operation.
    function withdrawFunds(address beneficiary, uint withdrawAmount) external onlyOwner {
        require (withdrawAmount <= address(this).balance, "Increase amount larger than balance.");
        require (jackpotSize + lockedInBets + withdrawAmount <= address(this).balance, "Not enough funds.");
        sendFunds(beneficiary, withdrawAmount, withdrawAmount);
    }
    // Contract may be destroyed only when there are no ongoing bets,
    // either settled or refunded. All funds are transferred to contract owner.
    function kill() external onlyOwner {
        require (lockedInBets == 0, "All bets should be processed (settled or refunded) before self-destruct.");
        selfdestruct(owner);
    }
    /// *** Betting logic
    // Bet states:
    //  amount == 0 && gambler == 0 - 'clean' (can place a bet)
    //  amount != 0 && gambler != 0 - 'active' (can be settled or refunded)
    //  amount == 0 && gambler != 0 - 'processed' (can clean storage)
    //
    //  NOTE: Storage cleaning is not implemented in this contract version; it will be added
    //        with the next upgrade to prevent polluting Ethereum state with expired bets.
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
    // the 'bets' mapping.
    //
    // Commits are signed with a block limit to ensure that they are used at most once - otherwise
    // it would be possible for a miner to place a bet with a known commit/reveal pair and tamper
    // with the blockhash. Croupier guarantees that commitLastBlock will always be not greater than
    // placeBet block number plus BET_EXPIRATION_BLOCKS. See whitepaper for details.
    function placeBet(uint betMask, uint modulo, uint commitLastBlock, uint commit, bytes32 r, bytes32 s) external payable {
        // Check that the bet is in 'clean' state.
        Bet storage bet = bets[commit];
        require (bet.gambler == address(0), "Bet should be in a 'clean' state.");
        // Validate input data ranges.
        uint amount = msg.value;
        require (modulo > 1 && modulo <= MAX_MODULO, "Modulo should be within range.");
        require (amount >= MIN_BET && amount <= MAX_AMOUNT, "Amount should be within range.");
        require (betMask > 0 && betMask < MAX_BET_MASK, "Mask should be within range.");
        // Check that commit is valid - it has not expired and its signature is valid.
        require (block.number <= commitLastBlock, "Commit has expired.");
        bytes32 signatureHash = keccak256(abi.encodePacked(uint40(commitLastBlock), commit));
        require (secretSigner == ecrecover(signatureHash, 27, r, s), "ECDSA signature is not valid.");
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
            require (betMask > 0 && betMask <= modulo, "High modulo range, betMask larger than modulo.");
            rollUnder = betMask;
        }
        // Winning amount and jackpot increase.
        uint possibleWinAmount;
        uint jackpotFee;
        (possibleWinAmount, jackpotFee) = getDiceWinAmount(amount, modulo, rollUnder);
        // Enforce max profit limit.
        require (possibleWinAmount <= amount + maxProfit, "maxProfit limit violation.");
        // Lock funds.
        lockedInBets += uint128(possibleWinAmount);
        jackpotSize += uint128(jackpotFee);
        // Check whether contract has enough funds to process this bet.
        require (jackpotSize + lockedInBets <= address(this).balance, "Cannot afford to lose this bet.");
        // Record commit in logs.
        emit Commit(commit);
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
    // This is the method used to settle 99% of bets. To process a bet with a specific
    // "commit", settleBet should supply a "reveal" number that would Keccak256-hash to
    // "commit". "blockHash" is the block hash of placeBet block as seen by croupier; it
    // is additionally asserted to prevent changing the bet outcomes on Ethereum reorgs.
    function settleBet(uint reveal, bytes32 blockHash) external onlyCroupier {
        uint commit = uint(keccak256(abi.encodePacked(reveal)));

        Bet storage bet = bets[commit];
        uint placeBlockNumber = bet.placeBlockNumber;
        // Check that bet has not expired yet (see comment to BET_EXPIRATION_BLOCKS).
        require (block.number > placeBlockNumber, "settleBet in the same block as placeBet, or before.");
        require (block.number <= placeBlockNumber + BET_EXPIRATION_BLOCKS, "Blockhash can't be queried by EVM.");
        require (blockhash(placeBlockNumber) == blockHash);
        // Settle bet using reveal and blockHash as entropy sources.
        settleBetCommon(bet, reveal, blockHash);
    }
    // This method is used to settle a bet that was mined into an uncle block. At this
    // point the player was shown some bet outcome, but the blockhash at placeBet height
    // is different because of Ethereum chain reorg. We supply a full merkle proof of the
    // placeBet transaction receipt to provide untamperable evidence that uncle block hash
    // indeed was present on-chain at some point.
    function settleBetUncleMerkleProof(uint reveal, uint40 canonicalBlockNumber) external onlyCroupier {
        // "commit" for bet settlement can only be obtained by hashing a "reveal".
        uint commit = uint(keccak256(abi.encodePacked(reveal)));

        Bet storage bet = bets[commit];
        // Check that canonical block hash can still be verified.
        require (block.number <= canonicalBlockNumber + BET_EXPIRATION_BLOCKS, "Blockhash can't be queried by EVM.");
        // Verify placeBet receipt.
        requireCorrectReceipt(4 + 32 + 32 + 4);
        // Reconstruct canonical & uncle block hashes from a receipt merkle proof, verify them.
        bytes32 canonicalHash;
        bytes32 uncleHash;
        (canonicalHash, uncleHash) = verifyMerkleProof(commit, 4 + 32 + 32);
        require (blockhash(canonicalBlockNumber) == canonicalHash);
        // Settle bet using reveal and uncleHash as entropy sources.
        settleBetCommon(bet, reveal, uncleHash);
    }
    // Common settlement code for settleBet & settleBetUncleMerkleProof.
    function settleBetCommon(Bet storage bet, uint reveal, bytes32 entropyBlockHash) private {
        // Fetch bet parameters into local variables (to save gas).
        uint amount = bet.amount;
        uint modulo = bet.modulo;
        uint rollUnder = bet.rollUnder;
        address gambler = bet.gambler;
        // Check that bet is in 'active' state.
        require (amount != 0, "Bet should be in an 'active' state");
        // Move bet into 'processed' state already.
        bet.amount = 0;
        // The RNG - combine "reveal" and blockhash of placeBet using Keccak256. Miners
        // are not aware of "reveal" and cannot deduce it from "commit" (as Keccak256
        // preimage is intractable), and house is unable to alter the "reveal" after
        // placeBet have been mined (as Keccak256 collision finding is also intractable).
        bytes32 entropy = keccak256(abi.encodePacked(reveal, entropyBlockHash));
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
    // in a situation like this, just contact the dice2.win support, however nothing
    // precludes you from invoking this method yourself.
    function refundBet(uint commit) external {
        // Check that bet is in 'active' state.
        Bet storage bet = bets[commit];
        uint amount = bet.amount;
        require (amount != 0, "Bet should be in an 'active' state");
        // Check that bet has already expired.
        require (block.number > bet.placeBlockNumber + BET_EXPIRATION_BLOCKS, "Blockhash can't be queried by EVM.");
        // Move bet into 'processed' state, release funds.
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
    function getDiceWinAmount(uint amount, uint modulo, uint rollUnder) private pure returns (uint winAmount, uint jackpotFee) {
        require (0 < rollUnder && rollUnder <= modulo, "Win probability out of range.");
        jackpotFee = amount >= MIN_JACKPOT_BET ? JACKPOT_FEE : 0;
        uint houseEdge = amount * HOUSE_EDGE_PERCENT / 100;
        if (houseEdge < HOUSE_EDGE_MINIMUM_AMOUNT) {
            houseEdge = HOUSE_EDGE_MINIMUM_AMOUNT;
        }
        require (houseEdge + jackpotFee <= amount, "Bet doesn't even cover house edge.");
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
    // *** Merkle proofs.
    // This helpers are used to verify cryptographic proofs of placeBet inclusion into
    // uncle blocks. They are used to prevent bet outcome changing on Ethereum reorgs without
    // compromising the security of the smart contract. Proof data is appended to the input data
    // in a simple prefix length format and does not adhere to the ABI.
    // Invariants checked:
    //  - receipt trie entry contains a (1) successful transaction (2) directed at this smart
    //    contract (3) containing commit as a payload.
    //  - receipt trie entry is a part of a valid merkle proof of a block header
    //  - the block header is a part of uncle list of some block on canonical chain
    // The implementation is optimized for gas cost and relies on the specifics of Ethereum internal data structures.
    // Read the whitepaper for details.
    // Helper to verify a full merkle proof starting from some seedHash (usually commit). "offset" is the location of the proof
    // beginning in the calldata.
    function verifyMerkleProof(uint seedHash, uint offset) pure private returns (bytes32 blockHash, bytes32 uncleHash) {
        // (Safe) assumption - nobody will write into RAM during this method invocation.
        uint scratchBuf1;  assembly { scratchBuf1 := mload(0x40) }
        uint uncleHeaderLength; uint blobLength; uint shift; uint hashSlot;
        // Verify merkle proofs up to uncle block header. Calldata layout is:
        //  - 2 byte big-endian slice length
        //  - 2 byte big-endian offset to the beginning of previous slice hash within the current slice (should be zeroed)
        //  - followed by the current slice verbatim
        for (;; offset += blobLength) {
            assembly { blobLength := and(calldataload(sub(offset, 30)), 0xffff) }
            if (blobLength == 0) {
                // Zero slice length marks the end of uncle proof.
                break;
            }

            assembly { shift := and(calldataload(sub(offset, 28)), 0xffff) }
            require (shift < blobLength, "Shift bounds check.");
            require (shift + 32 <= blobLength, "Shift bounds check.");

            offset += 4;
            assembly { hashSlot := calldataload(add(offset, shift)) }
            require (hashSlot == 0, "Non-empty hash slot.");
            assembly {
                calldatacopy(scratchBuf1, offset, blobLength)
                mstore(add(scratchBuf1, shift), seedHash)
                seedHash := sha3(scratchBuf1, blobLength)
                uncleHeaderLength := blobLength
            }
        }
        // At this moment the uncle hash is known.
        uncleHash = bytes32(seedHash);
        // Construct the uncle list of a canonical block.
        uint scratchBuf2 = scratchBuf1 + uncleHeaderLength;
        uint unclesLength; assembly { unclesLength := and(calldataload(sub(offset, 28)), 0xffff) }
        uint unclesShift;  assembly { unclesShift := and(calldataload(sub(offset, 26)), 0xffff) }
        require (unclesShift < unclesLength, "Shift bounds check.");
        require (unclesShift + uncleHeaderLength <= unclesLength, "Shift bounds check.");

        offset += 6;
        assembly { calldatacopy(scratchBuf2, offset, unclesLength) }
        memcpy(scratchBuf2 + unclesShift, scratchBuf1, uncleHeaderLength);
        assembly { seedHash := sha3(scratchBuf2, unclesLength) }
        offset += unclesLength;
        // Verify the canonical block header using the computed sha3Uncles.
        assembly {
            blobLength := and(calldataload(sub(offset, 30)), 0xffff)
            shift := and(calldataload(sub(offset, 28)), 0xffff)
        }
        require (shift < blobLength, "Shift bounds check.");
        require (shift + 32 <= blobLength, "Shift bounds check.");

        offset += 4;
        assembly { hashSlot := calldataload(add(offset, shift)) }
        require (hashSlot == 0, "Non-empty hash slot.");
        assembly {
            calldatacopy(scratchBuf1, offset, blobLength)
            mstore(add(scratchBuf1, shift), seedHash)
            // At this moment the canonical block hash is known.
            blockHash := sha3(scratchBuf1, blobLength)
        }
    }
    // Helper to check the placeBet receipt. "offset" is the location of the proof beginning in the calldata.
    // RLP layout: [triePath, str([status, cumGasUsed, bloomFilter, [[address, [topics], data]])]
    function requireCorrectReceipt(uint offset) view private {
        uint leafHeaderByte; assembly { leafHeaderByte := byte(0, calldataload(offset)) }
        require (leafHeaderByte >= 0xf7, "Receipt leaf longer than 55 bytes.");
        offset += leafHeaderByte - 0xf6;
        uint pathHeaderByte; assembly { pathHeaderByte := byte(0, calldataload(offset)) }
        if (pathHeaderByte <= 0x7f) {
            offset += 1;
        } else {
            require (pathHeaderByte >= 0x80 && pathHeaderByte <= 0xb7, "Path is an RLP string.");
            offset += pathHeaderByte - 0x7f;
        }
        uint receiptStringHeaderByte; assembly { receiptStringHeaderByte := byte(0, calldataload(offset)) }
        require (receiptStringHeaderByte == 0xb9, "Receipt string is always at least 256 bytes long, but less than 64k.");
        offset += 3;
        uint receiptHeaderByte; assembly { receiptHeaderByte := byte(0, calldataload(offset)) }
        require (receiptHeaderByte == 0xf9, "Receipt is always at least 256 bytes long, but less than 64k.");
        offset += 3;
        uint statusByte; assembly { statusByte := byte(0, calldataload(offset)) }
        require (statusByte == 0x1, "Status should be success.");
        offset += 1;
        uint cumGasHeaderByte; assembly { cumGasHeaderByte := byte(0, calldataload(offset)) }
        if (cumGasHeaderByte <= 0x7f) {
            offset += 1;
        } else {
            require (cumGasHeaderByte >= 0x80 && cumGasHeaderByte <= 0xb7, "Cumulative gas is an RLP string.");
            offset += cumGasHeaderByte - 0x7f;
        }
        uint bloomHeaderByte; assembly { bloomHeaderByte := byte(0, calldataload(offset)) }
        require (bloomHeaderByte == 0xb9, "Bloom filter is always 256 bytes long.");
        offset += 256 + 3;
        uint logsListHeaderByte; assembly { logsListHeaderByte := byte(0, calldataload(offset)) }
        require (logsListHeaderByte == 0xf8, "Logs list is less than 256 bytes long.");
        offset += 2;
        uint logEntryHeaderByte; assembly { logEntryHeaderByte := byte(0, calldataload(offset)) }
        require (logEntryHeaderByte == 0xf8, "Log entry is less than 256 bytes long.");
        offset += 2;
        uint addressHeaderByte; assembly { addressHeaderByte := byte(0, calldataload(offset)) }
        require (addressHeaderByte == 0x94, "Address is 20 bytes long.");
        uint logAddress; assembly { logAddress := and(calldataload(sub(offset, 11)), 0xffffffffffffffffffffffffffffffffffffffff) }
        require (logAddress == uint(address(this)));
    }
    // Memory copy.
    function memcpy(uint dest, uint src, uint len) pure private {
        // Full 32 byte words
        for(; len >= 32; len -= 32) {
            assembly { mstore(dest, mload(src)) }
            dest += 32; src += 32;
        }
        // Remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }
}