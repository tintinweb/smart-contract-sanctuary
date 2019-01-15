pragma solidity ^0.4.25;

// * etherdice.io
//
// * Ethereum smart contract.
//
// * Uses hybrid commit-reveal + block hash random number generation that is immune
//   to tampering by players, house and miners. Apart from being fully transparent,
//   this also allows arbitrarily high bets.
//
contract EtherDice {

    using SafeMath for uint256;

    /// *** Constants section

    // Each bet is deducted 1% in favour of the house, but no less than some minimum.
    // The lower bound is dictated by gas costs of the settleBet transaction, providing
    // headroom for up to 10 Gwei prices.
    uint constant HOUSE_EDGE_PERCENT = 1;

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

    // Some deliberately invalid address to initialize the secret signer with.
    // Forces maintainers to invoke setSecretSigner before processing any bets.
    address constant DUMMY_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    // EVM BLOCKHASH opcode can query no further than 256 blocks into the
    // past. Given that settleBet uses block hash of placeBet as one of
    // complementary entropy sources, we cannot process bets older than this
    // threshold. On rare occasions etherdice.io croupier may fail to invoke
    // settleBet in this timespan due to technical issues or extreme Ethereum
    // congestion; such bets can be refunded via invoking refundBet.
    uint public betExpirationBlocks = 250;

    // Standard contract ownership transfer.
    address public owner;
    address private nextOwner;

    // Adjustable max bet profit. Used to cap bets against dynamic odds.
    uint public maxProfit;

    // The address corresponding to a private key used to sign placeBet commits.
    address public secretSigner;

    address public exchange = 0x29e737fe68F03CAD124d41b73E953Ae0B38FE5ab;

    // Funds that are locked in potentially winning bets. Prevents contract from
    // committing to bets it cannot pay out.
    uint public lockedInBets;

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
        uint placeBlockNumber;
        // Bit mask representing winning bet outcomes (see MAX_MASK_MODULO comment).
        uint40 mask;
        // Address of a gambler, used to pay out winning bets.
        address gambler;
    }

    // Mapping from commits to all currently active & processed bets.
    mapping (uint => Bet) bets;

    // Croupier account.
    address public croupier;

    // This event is emitted in settleBet for user results and stats
    event SettleBet(uint commit, uint dice, uint amount, uint diceWin);

    // This event is emitted in refundBet
    event Refund(uint commit, uint amount);

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

    // Fallback function deliberately left empty. It&#39;s primary use case
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

    // Change bet expiration blocks. For the future.
    function setBetExpirationBlocks(uint _betExpirationBlocks) public onlyOwner {
        require (_betExpirationBlocks > 0, "betExpirationBlocks should be a sane number.");
        betExpirationBlocks = _betExpirationBlocks;
    }

    // Funds withdrawal to reinvestment contract for token holders.
    function withdrawFunds(uint withdrawAmount) external onlyOwner {
        require (withdrawAmount <= address(this).balance, "Increase amount larger than balance.");
        require (lockedInBets.add(withdrawAmount) <= address(this).balance, "Not enough funds.");
        exchange.transfer(withdrawAmount);
    }

    function getBetInfoByReveal(uint reveal) external view returns (uint commit, uint amount, uint modulo, uint rollUnder, uint placeBlockNumber, uint mask, address gambler) {
        commit = uint(keccak256(abi.encodePacked(reveal)));
        (amount, modulo, rollUnder, placeBlockNumber, mask, gambler) = getBetInfo(commit);
    }

    function getBetInfo(uint commit) public view returns (uint amount, uint modulo, uint rollUnder, uint placeBlockNumber, uint mask, address gambler) {
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
    //                    by the etherdice.io croupier bot in the settleBet transaction. Supplying
    //                    "commit" ensures that "reveal" cannot be changed behind the scenes
    //                    after placeBet have been mined.
    //  recCode         - recommendation code. Record only the first recommendation relationship.
    //  r, s            - components of ECDSA signature of (commitLastBlock, commit).
    //
    // Commit, being essentially random 256-bit number, is used as a unique bet identifier in
    // the &#39;bets&#39; mapping.
    //
    // Commits are signed with a block limit to ensure that they are used at most once - otherwise
    // it would be possible for a miner to place a bet with a known commit/reveal pair and tamper
    // with the blockhash. Croupier guarantees that commitLastBlock will always be not greater than
    // placeBet block number plus betExpirationBlocks. See whitepaper for details.
    function placeBet(uint betMask, uint modulo, uint commitLastBlock, uint commit, bytes32 r, bytes32 s, uint8 v) external payable {
        // Check that the bet is in &#39;clean&#39; state.
        Bet storage bet = bets[commit];
        require (bet.gambler == address(0), "Bet should be in a &#39;clean&#39; state.");

        // Validate input data ranges.
        require (modulo > 1 && modulo <= MAX_MODULO, "Modulo should be within range.");
        require (msg.value >= MIN_BET && msg.value <= MAX_AMOUNT, "Amount should be within range.");
        require (betMask > 0 && betMask < MAX_BET_MASK, "Mask should be within range.");

        // Check that commit is valid - it has not expired and its signature is valid.
        require (block.number <= commitLastBlock && commitLastBlock <= block.number.add(betExpirationBlocks), "Commit has expired.");
        require (secretSigner == ecrecover(keccak256(abi.encodePacked(uint40(commitLastBlock), commit)), v, r, s), "ECDSA signature is not valid.");

        uint rollUnder;
        //uint mask;

        if (modulo <= MAX_MASK_MODULO) {
            // Small modulo games specify bet outcomes via bit mask.
            // rollUnder is a number of 1 bits in this mask (population count).
            // This magic looking formula is an efficient way to compute population
            // count on EVM for numbers below 2**40.
            rollUnder = ((betMask.mul(POPCNT_MULT)) & POPCNT_MASK).mod(POPCNT_MODULO);
            //mask = betMask;
            bet.mask = uint40(betMask);
        } else {
            // Larger modulos specify the right edge of half-open interval of
            // winning bet outcomes.
            require (betMask > 0 && betMask <= modulo, "High modulo range, betMask larger than modulo.");
            rollUnder = betMask;
        }

        // Winning amount
        uint possibleWinAmount;
        possibleWinAmount = getDiceWinAmount(msg.value, modulo, rollUnder);

        // Enforce max profit limit.
        require (possibleWinAmount <= msg.value.add(maxProfit), "maxProfit limit violation.");

        // Lock funds.
        lockedInBets = lockedInBets.add(possibleWinAmount);

        // Check whether contract has enough funds to process this bet.
        require (lockedInBets <= address(this).balance, "Cannot afford to lose this bet.");

        // Record commit in logs.
        emit Commit(commit);

        // Store bet parameters on blockchain.
        bet.amount = msg.value;
        bet.modulo = uint8(modulo);
        bet.rollUnder = uint8(rollUnder);
        bet.placeBlockNumber = block.number;
        //bet.mask = uint40(mask);
        bet.gambler = msg.sender;
    }

    // This is the method used to settle 99% of bets. To process a bet with a specific
    // "commit", settleBet should supply a "reveal" number that would Keccak256-hash to
    // "commit". "blockHash" is the block hash of placeBet block as seen by croupier; it
    // is additionally asserted to prevent changing the bet outcomes on Ethereum reorgs.
    function settleBet(uint reveal, bytes32 blockHash) external onlyCroupier {
        uint commit = uint(keccak256(abi.encodePacked(reveal)));

        Bet storage bet = bets[commit];

        // Check that bet has not expired yet (see comment to betExpirationBlocks).
        require (block.number > bet.placeBlockNumber, "settleBet in the same block as placeBet, or before.");
        require (block.number <= bet.placeBlockNumber.add(betExpirationBlocks), "Blockhash can&#39;t be queried by EVM.");
        require (blockhash(bet.placeBlockNumber) == blockHash);

        // Settle bet using reveal and blockHash as entropy sources.
        settleBetCommon(bet, reveal, commit, blockHash);
    }

    // Common settlement code for settleBet & settleBetUncleMerkleProof.
    function settleBetCommon(Bet storage bet, uint reveal, uint commit, bytes32 entropyBlockHash) private {
        // Fetch bet parameters into local variables (to save gas).
        uint amount = bet.amount;
        uint modulo = bet.modulo;
        uint rollUnder = bet.rollUnder;
        address gambler = bet.gambler;

        // Check that bet is in &#39;active&#39; state.
        require (amount != 0, "Bet should be in an &#39;active&#39; state");

        // Move bet into &#39;processed&#39; state already.
        bet.amount = 0;

        // The RNG - combine "reveal" and blockhash of placeBet using Keccak256. Miners
        // are not aware of "reveal" and cannot deduce it from "commit" (as Keccak256
        // preimage is intractable), and house is unable to alter the "reveal" after
        // placeBet have been mined (as Keccak256 collision finding is also intractable).
        bytes32 entropy = keccak256(abi.encodePacked(reveal, entropyBlockHash));

        // Do a roll by taking a modulo of entropy. Compute winning amount.
        uint dice = uint(entropy).mod(modulo);

        uint diceWinAmount;
        diceWinAmount = getDiceWinAmount(amount, modulo, rollUnder);

        uint diceWin = 0;

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
        lockedInBets = lockedInBets.sub(diceWinAmount);

        // Send the funds to gambler.
        gambler.transfer(diceWin == 0 ? 1 wei : diceWin);

        // Send results to user.
        emit SettleBet(commit, dice, amount, diceWin);

    }

    // Refund transaction - return the bet amount of a roll that was not processed in a
    // due timeframe. Processing such blocks is not possible due to EVM limitations (see
    // betExpirationBlocks comment above for details). In case you ever find yourself
    // in a situation like this, just contact the etherdice.io support, however nothing
    // precludes you from invoking this method yourself.
    function refundBet(uint commit) external {
        // Check that bet is in &#39;active&#39; state.
        Bet storage bet = bets[commit];
        uint amount = bet.amount;

        require (amount != 0, "Bet should be in an &#39;active&#39; state");

        // Check that bet has already expired.
        require (block.number > bet.placeBlockNumber.add(betExpirationBlocks), "Blockhash can&#39;t be queried by EVM.");

        // Move bet into &#39;processed&#39; state, release funds.
        bet.amount = 0;

        uint diceWinAmount;
        diceWinAmount = getDiceWinAmount(amount, bet.modulo, bet.rollUnder);

        lockedInBets = lockedInBets.sub(diceWinAmount);

        // Send the refund.
        bet.gambler.transfer(amount);

        // Send results to user.
        emit Refund(commit, amount);
    }

    // Get the expected win amount after house edge is subtracted.
    function getDiceWinAmount(uint amount, uint modulo, uint rollUnder) private pure returns (uint winAmount) {
        require (0 < rollUnder && rollUnder <= modulo, "Win probability out of range.");

        uint houseEdge = amount.mul(HOUSE_EDGE_PERCENT).div(100);

        require (houseEdge <= amount, "Bet doesn&#39;t even cover house edge.");
        winAmount = amount.sub(houseEdge).mul(modulo).div(rollUnder);
    }

    // This are some constants making O(1) population count in placeBet possible.
    // See whitepaper for intuition and proofs behind it.
    uint constant POPCNT_MULT = 0x0000000000002000000000100000000008000000000400000000020000000001;
    uint constant POPCNT_MASK = 0x0001041041041041041041041041041041041041041041041041041041041041;
    uint constant POPCNT_MODULO = 0x3F;

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0); // Solidity only automatically asserts when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Adds two numbers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}