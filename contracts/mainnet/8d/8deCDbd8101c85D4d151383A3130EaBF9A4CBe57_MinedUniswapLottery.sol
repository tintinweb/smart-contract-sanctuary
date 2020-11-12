// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

// implement OpenZeppelin's ERC20 token.
import "./ZeppelinERC20.sol";

// Use the Uniswap Interfaces.
import "./IUniswap.sol";

// Use Core Settings.
import "./CoreSettings.sol";

// Interface of the Main Pool Contract, with the functions that we'll
// be calling from our contract.
interface IUniLotteryPool
{
    function lotteryFinish( uint totalReturn, uint profitAmount )
    external payable;
}

// The Randomness Provider interface.
interface IRandomnessProvider
{
    function requestRandomSeedForLotteryFinish()    external;
}


/**
 *  Simple, gas-efficient lottery, which uses Uniswap as liquidity provider,
 *  and determines the lottery winners through a 3 different approaches
 *  (explained in detail on EndingAlgoType documentation).
 *
 *  This contract contains all code of the lottery contract, and 
 *  lotteries themselves are just storage-container stubs, which use
 *  DelegateCall mechanism to execute this actual lottery code on
 *  their behalf.
 *
 *  Lottery workflow consists of these consecutive stages:
 *
 *  1. Initialization stage: Main Pool deploys this lottery contract,
 *      and calls initialize() with initial Ether funds provided.
 *      Lottery mints initial token supply and provides the liquidity
 *      to Uniswap, with whole token supply and initial Ether funds.
 *      Then, lottery becomes Active - trading tokens becomes allowed.
 *
 *  2. Active Stage:    Token transfers occurs on this stage, and 
 *      finish probability is Zero. Our ETH funds in Uniswap increases
 *      in this stage.
 *      When certain criteria of holder count and fund gains are met,
 *      the Finishing stage begins.
 *  
 *  3. Finishing Stage:     It can be considered a second part of
 *      an Active stage, because all token transfers and Uniswap trading
 *      are still allowed and occur actively.
 *      However, on this stage, for every transfer, a pseudo-random
 *      number is rolled, and if that rolled number is below a specific
 *      threshold, lottery de-activates, and Ending stage begins, when
 *      token transfers are denied.
 *      The threshold is determined by Finish Probability, which
 *      increases on every transfer on this stage.
 *
 *      However, notice that if Finishing Criteria (holder count and
 *      fund gains) are no-longer met, Finishing Stage pauses, and
 *      we get back to Active Stage.
 *
 *  4. Ending-Mining Stage - Step One:
 *      On this stage, we Remove our contract's liquidity share
 *      from Uniswap, then transfer the profits to the Pool and
 *      the Owner addresses.
 *
 *      Then, we call the Randomness Provider, requesting the Random Seed,
 *      which later should be passed to us by calling our callback
 *      (finish_randomnessProviderCallback).
 *
 *      Miner, who completes this step, gets portion of Mining Rewards,
 *      which are a dedicated profit share to miners.
 *
 *  5. Ending-Mining Stage - Step Two:  On this stage, if  *
 *      However, if Randomness Provider hasn't given us a seed after
 *      specific amount of time, on this step, before starting the
 *      Winner Selection Algorithm, an Alternative Seed Generation
 *      is performed, where the pseudo-random seed is generated based
 *      on data in our and Storage contracts (transfer hash, etc.).
 *
 *      If we're using MinedWinnerSelection ending algorithm type, then
 *      on this step the miner performs the gas-intensive Winner Selection 
 *      Algorithm, which involves complex score calculations in a loop, and
 *      then sorting the selected winners array.
 *
 *      Miner who successfully completes this step, gets a portion of
 *      the Mining Rewards.
 *
 *  6. Completion Stage (Winner Prize Claiming stage):  On this stage,
 *      the Lottery Winners can finally claim their Lottery Prizes,
 *      by calling a prize claim function on our contract.
 *
 *      If we're using WinnerSelfValidation ending algorithm, winner
 *      computes and validates his final score on this function by
 *      himself, so the prize claim transaction can be gas-costly.
 *
 *      However, is RolledRandomness or MinedWinnerSelection algorithms
 *      are used, this function is cheap in terms of gas.
 *
 *      However, if some of winners fail to claim their prizes after
 *      a specific amount of time (specified in config), then those
 *      prizes can then be claimed by Lottery Main Pool too.
 */
contract Lottery is ERC20, CoreUniLotterySettings
{
    // ===================== Events ===================== //

    // After initialize() function finishes.
    event LotteryInitialized();

    // Emitted when lottery active stage ends (Mining Stage starts),
    // on Mining Stage Step 1, after transferring profits to their
    // respective owners (pool and OWNER_ADDRESS).
    event LotteryEnd(
        uint128 totalReturn,
        uint128 profitAmount
    );

    // Emitted when on final finish, we call Randomness Provider
    // to callback us with random value.
    event RandomnessProviderCalled();

    // Requirements for finishing stage start have been reached - 
    // finishing stage has started.
    event FinishingStageStarted();

    // We were currently on the finishing stage, but some requirement
    // is no longer met. We must stop the finishing stage.
    event FinishingStageStopped();

    // New Referral ID has been generated.
    event ReferralIDGenerated(
        address referrer,
        uint256 id
    );

    // New referral has been registered with a valid referral ID.
    event ReferralRegistered(
        address referree,
        address referrer,
        uint256 id
    );

    // Fallback funds received.
    event FallbackEtherReceiver(
        address sender,
        uint value
    );


    // ======================  Structs & Enums  ====================== //

    // Lottery Stages. 
    // Described in more detail above, on contract's main doc.
    enum STAGE
    {
        // Initial stage - before the initialize() function is called.
        INITIAL,

        // Active Stage: On this stage, all token trading occurs.
        ACTIVE,

        // Finishing stage:
        // This is when all finishing criteria are met, and for every
        // transfer, we're rolling a pseudo-random number to determine
        // if we should end the lottery (move to Ending stage).
        FINISHING,

        // Ending - Mining Stage:
        // This stage starts after we lottery is no longer active,
        // finishing stage ends. On this stage, Miners perform the
        // Ending Algorithm and other operations.
        ENDING_MINING,

        // Lottery is completed - this is set after the Mining Stage ends.
        // In this stage, Lottery Winners can claim their prizes.
        COMPLETION,

        // DISABLED stage. Used when we want a lottery contract to be
        // absolutely disabled - so no state-modifying functions could
        // be called.
        // This is used in DelegateCall scenarios, where state-contract
        // delegate-calls code contract, to save on deployment costs.
        DISABLED
    }


    // Ending algorithm types enum.
    enum EndingAlgoType
    {
        // 1. Mined Winner Selection Algorithm.
        //  This algorithm is executed by a Lottery Miner in a single
        //  transaction, on Mining Step 2.
        //
        //  On that single transaction, all ending scores for all
        //  holders are computed, and a sorted winner array is formed,
        //  which is written onto the LotteryStorage state.
        //  Thus, it's gas expensive, and suitable only for small
        //  holder numbers (up to 300).
        //
        // Pros:
        //  + Guaranteed deterministically specifiable winner prize
        //    distribution - for example, if we specify that there
        //    must be 2 winners, of which first gets 60% of prize funds,
        //    and second gets 40% of prize funds, then it's
        //    guarateed that prize funds will be distributed just
        //    like that.
        //
        //  + Low gas cost of prize claims - only ~ 40,000 gas for
        //    claiming a prize.
        //
        // Cons:
        //  - Not scaleable - as the Winner Selection Algorithm is
        //    executed in a single transaction, it's limited by 
        //    block gas limit - 12,500,000 on the MainNet.
        //    Thus, the lottery is limited to ~300 holders, and
        //    max. ~200 winners of those holders.
        //    So, it's suitable for only express-lotteries, where
        //    a lottery runs only until ~300 holders are reached.
        //
        //  - High mining costs - if lottery has 300 holders,
        //    mining transaction takes up whole block gas limit.
        //
        MinedWinnerSelection,

        // 2. Winner Self-Validation Algorithm.
        //
        //  This algorithm does no operations during the Mining Stage
        //  (except for setting up a Random Seed in Lottery Storage) -
        //  the winner selection (obtaining a winner rank) is done by
        //  the winners themselves, when calling the prize claim
        //  functions.
        //
        //  This algorithm relies on a fact that by the time that
        //  random seed is obtained, all data needed for winner selection
        //  is already there - the holder scores of the Active Stage
        //  (ether contributed, time factors, token balance), and
        //  the Random Data (random seed + nonce (holder's address)),
        //  so, there is no need to compute and sort the scores for the
        //  whole holder array.
        //
        //  It's done like this: the holder checks if he's a winner, using
        //  a view-function off-chain, and if so, he calls the 
        //  claimWinnerPrize() function, which obtains his winner rank
        //  on O(n) time, and does no writing to contract states,
        //  except for prize transfer-related operations.
        //
        //  When computing the winner's rank on LotteryStorage,
        //  O(n) time is needed, as we loop through the holders array,
        //  computing ending scores for each holder, using already-known
        //  data. 
        //  However that means that for every prize claim, all scores of
        //  all holders must be re-computed.
        //  Computing a score for a single holder takes roughly 1500 gas
        //  (400 for 3 slots SLOAD, and ~300 for arithmetic operations).
        //
        //  So, this algorithm makes prize claims more expensive for
        //  every lottery holder.
        //  If there's 1000 holders, prize claim takes up 1,500,000 gas,
        //  so, this algorithm is not suitable for small prizes,
        //  because gas fee would be higher than the prize amount won.
        //
        // Pros:
        //  + Guaranteed deterministically specifiable winner prize
        //    distribution (same as for algorithm 1).
        //
        //  + No mining costs for winner selection algorithm.
        //
        //  + More scalable than algorithm 1.
        //
        // Cons:
        //  - High gas costs of prize claiming, rising with the number
        //    of lottery holders - 1500 for every lottery holder.
        //    Thus, suitable for only large prize amounts.
        //
        WinnerSelfValidation,

        // 3. Rolled-Randomness algorithm.
        //
        //  This algorithm is the most cheapest in terms of gas, but
        //  the winner prize distribution is non-deterministic.
        //
        //  This algorithm doesn't employ miners (no mining costs),
        //  and doesn't require to compute scores for every holder
        //  prior to getting a winner's rank, thus is the most scalable.
        //
        //  It works like this: a holder checks his winner status by
        //  computing only his own randomized score (rolling a random
        //  number from the random seed, and multiplying it by holder's
        //  Active Stage score), and computing this randomized-score's
        //  ratio relative to maximum available randomized score.
        //  The higher the ratio, the higher the winner rank is.
        //
        //  However, many players can roll very high or low scores, and
        //  get the same prizes, so it's difficult to make a fair and
        //  efficient deterministic prize distribution mechanism, so
        //  we have to fallback to specific heuristic workarounds.
        //
        // Pros:
        //  + Scalable: O(1) complexity for computing a winner rank,
        //      so there can be an unlimited amount of lottery holders,
        //      and gas costs for winner selection and prize claim would
        //      still be constant & low.
        //
        //  + Gas-efficient: gas costs for all winner-related operations
        //      are constant and low, because only single holder's score
        //      is computed.
        //
        //  + Doesn't require mining - even more gas savings.
        //
        // Cons:
        //  + Hard to make a deterministic and fair prize distribution
        //      mechanism, because of un-known environment - as only
        //      single holder's score is compared to max-available
        //      random score, not taking into account other holder
        //      scores.
        //
        RolledRandomness
    }


    /**
     *  Gas-efficient, minimal config, which specifies only basic,
     *  most-important and most-used settings.
     */
    struct LotteryConfig
    {
        // ================ Misc Settings =============== //

        // --------- Slot --------- //

        // Initial lottery funds (initial market cap).
        // Specified by pool, and is used to check if initial funds 
        // transferred to fallback are correct - equal to this value.
        uint initialFunds;


        // --------- Slot --------- //

        // The minimum ETH value of lottery funds, that, once
        // reached on an exchange liquidity pool (Uniswap, or our
        // contract), must be guaranteed to not shrink below this value.
        // 
        // This is accomplished in _transfer() function, by denying 
        // all sells that would drop the ETH amount in liquidity pool
        // below this value.
        // 
        // But on initial lottery stage, before this minimum requirement
        // is reached for the first time, all sells are allowed.
        //
        // This value is expressed in ETH - total amount of ETH funds
        // that we own in Uniswap liquidity pair.
        //
        // So, if initial funds were 10 ETH, and this is set to 100 ETH,
        // after liquidity pool's ETH value reaches 100 ETH, all further
        // sells which could drop the liquidity amount below 100 ETH,
        // would be denied by require'ing in _transfer() function
        // (transactions would be reverted).
        //
        uint128 fundRequirement_denySells;

        // ETH value of our funds that we own in Uniswap Liquidity Pair,
        // that's needed to start the Finishing Stage.
        uint128 finishCriteria_minFunds;


        // --------- Slot --------- //

        // Maximum lifetime of a lottery - maximum amount of time 
        // allowed for lottery to stay active.
        // By default, it's two weeks.
        // If lottery is still active (hasn't returned funds) after this
        // time, lottery will stop on the next token transfer.
        uint32 maxLifetime;

        // Maximum prize claiming time - for how long the winners
        // may be able to claim their prizes after lottery ending.
        uint32 prizeClaimTime;

        // Token transfer burn rates for buyers, and a default rate for
        // sells and non-buy-sell transfers.
        uint32 burn_buyerRate;
        uint32 burn_defaultRate;

        // Maximum amount of tokens (in percentage of initial supply)
        // to be allowed to own by a single wallet.
        uint32 maxAmountForWallet_percentageOfSupply;

        // The required amount of time that must pass after
        // the request to Randomness Provider has been made, for
        // external actors to be able to initiate alternative
        // seed generation algorithm.
        uint32 REQUIRED_TIME_WAITING_FOR_RANDOM_SEED;
        
        
        // ================ Profit Shares =============== //

        // "Mined Uniswap Lottery" ending Ether funds, which were obtained
        // by removing token liquidity from Uniswap, are transfered to
        // these recipient categories:
        //
        //  1. The Main Pool:   Initial funds, plus Pool's profit share.
        //  2. The Owner:       Owner's profit share.
        //
        //  3. The Miners:      Miner rewards for executing the winner
        //      selection algorithm stages.
        //      The more holders there are, the more stages the 
        //      winner selection algorithm must undergo.
        //      Each Miner, who successfully completed an algorithm
        //      stage, will get ETH reward equal to:
        //      (minerProfitShare / totalAlgorithmStages).
        //
        //  4. The Lottery Winners:     All remaining funds are given to
        //      Lottery Winners, which were determined by executing
        //      the Winner Selection Algorithm at the end of the lottery
        //      (Miners executed it).
        //      The Winners can claim their prizes by calling a 
        //      dedicated function in our contract.
        //
        //  The profit shares of #1 and #2 have controlled value ranges 
        //  specified in CoreUniLotterySettings.
        //
        //  All these shares are expressed as percentages of the
        //  lottery profit amount (totalReturn - initialFunds).
        //  Percentages are expressed using the PERCENT constant, 
        //  defined in CoreUniLotterySettings.
        //
        //  Here we specify profit shares of Pool, Owner, and the Miners.
        //  Winner Prize Fund is all that's left (must be more than 50%
        //  of all profits).
        //

        uint32 poolProfitShare;
        uint32 ownerProfitShare;

        // --------- Slot --------- //

        uint32 minerProfitShare;
        
        
        // =========== Lottery Finish criteria =========== //

        // Lottery finish by design is a whole soft stage, that
        // starts when criteria for holders and fund gains are met.
        // During this stage, for every token transfer, a pseudo-random
        // number will be rolled for lottery finish, with increasing 
        // probability.
        //
        // There are 2 ways that this probability increase is 
        // implemented:
        // 1. Increasing on every new holder.
        // 2. Increasing on every transaction after finish stage
        //    was initiated.
        //
        // On every new holder, probability increases more than on
        // new transactions.
        //
        // However, if during this stage some criteria become 
        // no-longer-met, the finish stage is cancelled.
        // This cancel can be implemented by setting finish probability
        // to zero, or leaving it as it was, but pausing the finishing
        // stage.
        // This is controlled by finish_resetProbabilityOnStop flag -
        // if not set, probability stays the same, when the finishing
        // stage is discontinued. 

        // ETH value of our funds that we own in Uniswap Liquidity Pair,
        // that's needed to start the Finishing Stage.
        //
        // LOOK ABOVE - arranged for tight-packing.

        // Minimum number of token holders required to start the
        // finishing stage.
        uint32 finishCriteria_minNumberOfHolders;

        // Minimum amount of time that lottery must be active.
        uint32 finishCriteria_minTimeActive;

        // Initial finish probability, when finishing stage was
        // just initiated.
        uint32 finish_initialProbability;

        // Finishing probability increase steps, for every new 
        // transaction and every new holder.
        // If holder number decreases, probability decreases.
        uint32 finish_probabilityIncreaseStep_transaction;
        uint32 finish_probabilityIncreaseStep_holder;


        // =========== Winner selection config =========== //

        // Winner selection algorithm settings.
        //
        // Algorithm is based on score, which is calculated for 
        // every holder on lottery finish, and is comprised of
        // the following parts.
        // Each part is normalized to range ( 0 - scorePoints ), 
        // from smallest to largest value of each holder;
        //
        // After scores are computed, they are multiplied by 
        // holder count factor (holderCount / holderCountDivisor),
        // and finally, multiplied by safely-generated random values,
        // to get end winning scores.
        // The top scorers win prizes.
        //
        // By default setting, max score is 40 points, and it's
        // comprised of the following parts:
        //
        // 1. Ether contributed (when buying from Uniswap or contract). 
        //    Gets added when buying, and subtracted when selling.
        //      Default: 10 points.
        //
        // 2. Amount of lottery tokens holder has on finish.
        //      Default: 5 points.
        //
        // 3. Ether contributed, multiplied by the relative factor
        //      of time - that is, "now" minus "lotteryStartTime".
        //      This way, late buyers can get more points even if
        //      they get little tokens and don't spend much ether.
        //      Default: 5 points.
        //
        // 4. Refferrer bonus. For every player that joined with
        //      your referral ID, you get (that player's score) / 10 
        //      points! This goes up to specified max score.
        //      Also, every player who provides a valid referral ID,
        //      gets 2 points for free!
        //      Default max bonus: 20 points.
        //
        int16 maxPlayerScore_etherContributed;
        int16 maxPlayerScore_tokenHoldingAmount;
        int16 maxPlayerScore_timeFactor;
        int16 maxPlayerScore_refferalBonus;

        // --------- Slot --------- //

        // Score-To-Random ration data (as a rational ratio number).
        // For example if 1:5, then scorePart = 1, and randPart = 5.
        uint16 randRatio_scorePart;
        uint16 randRatio_randPart;

        // Time factor divisor - interval of time, in seconds, after
        // which time factor is increased by one.
        uint16 timeFactorDivisor;

        // Bonus score a player should get when registering a valid
        // referral code obtained from a referrer.
        int16 playerScore_referralRegisteringBonus;


        // Are we resetting finish probability when finishing stage
        // stops, if some criteria are no longer met?
        bool finish_resetProbabilityOnStop;


        // =========== Winner Prize Fund Settings =========== //

        // There are 2 available modes that we can use to distribute
        // winnings: a computable sequence (geometrical progression),
        // or an array of winner prize fund share percentages.

        // More gas efficient is to use a computable sequence, 
        // where each winner gets a share equal to (factor * fundsLeft).
        // Factor is in range [0.01 - 1.00] - simulated as [1% - 100%].
        //
        // For example:
        // Winner prize fund is 100 ethers, Factor is 1/4 (25%), and 
        // there are 5 winners total (winnerCount), and sequenced winner
        // count is 2 (sequencedWinnerCount).
        //
        // So, we pre-compute the upper shares, till we arrive to the
        // sequenced winner count, in a loop:
        // - Winner 1: 0.25 * 100 = 25 eth; 100 - 25 = 75 eth left.
        // - Winner 2: 0.25 * 75 ~= 19 eth; 75  - 19 = 56 eth left.
        //
        // Now, we compute the left-over winner shares, which are
        // winners that get their prizes from the funds left after the
        // sequence winners.
        //
        // So, we just divide the leftover funds (56 eth), by 3,
        // because winnerCount - sequencedWinnerCount = 3.
        // - Winner 3 = 56 / 3 = 18 eth;
        // - Winner 4 = 56 / 3 = 18 eth;
        // - Winner 5 = 56 / 3 = 18 eth;
        //

        // If this value is 0, then we'll assume that array-mode is
        // to be used.
        uint32 prizeSequenceFactor;

        // Maximum number of winners that the prize sequence can yield,
        // plus the leftover winners, which will get equal shares of
        // the remainder from the first-prize sequence.
        
        uint16 prizeSequence_winnerCount;

        // How many winners would get sequence-computed prizes.
        // The left-over winners
        // This is needed because prizes in sequence tend to zero, so
        // we need to limit the sequence to avoid very small prizes,
        // and to avoid the remainder.
        uint16 prizeSequence_sequencedWinnerCount;

        // Initial token supply (without decimals).
        uint48 initialTokenSupply;

        // Ending Algorithm type.
        // More about the 3 algorithm types above.
        uint8 endingAlgoType;


        // --------- Slot --------- //

        // Array mode: The winner profit share percentages array. 
        // For example, lottery profits can be distributed this way:
        //
        // Winner profit shares (8 winners):
        // [ 20%, 15%, 10%, 5%, 4%, 3%, 2%, 1% ] = 60% of profits.
        // Owner profits: 10%
        // Pool profits:  30%
        //
        // Pool profit share is not defined explicitly in the config, so
        // when we internally validate specified profit shares, we 
        // assume the pool share to be the left amount until 100% ,
        // but we also make sure that this amount is at least equal to
        // MIN_POOL_PROFITS, defined in CoreSettings.
        //
        uint32[] winnerProfitShares;

    }


    // ========================= Constants ========================= //


    // The Miner Profits - max/min values.
    // These aren't defined in Core Settings, because Miner Profits
    // are only specific to this lottery type.

    uint32 constant MIN_MINER_PROFITS = 1 * PERCENT;
    uint32 constant MAX_MINER_PROFITS = 10 * PERCENT;


    // Uniswap Router V2 contract instance.
    // Address is the same for MainNet, and all public testnets.
    IUniswapRouter constant uniswapRouter = IUniswapRouter(
        address( 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D ) );


    // Public-accessible ERC20 token specific constants.
    string constant public name = "UniLottery Token";
    string constant public symbol = "ULT";
    uint256 constant public decimals = 18;


    // =================== State Variables =================== //

    // ------- Initial Slots ------- //

    // The config which is passed to constructor.
    LotteryConfig internal cfg;

    // ------- Slot ------- //

    // The Lottery Storage contract, which stores all holder data,
    // such as scores, referral tree data, etc.
    LotteryStorage public lotStorage;

    // ------- Slot ------- //

    // Pool address. Set on constructor from msg.sender.
    address payable public poolAddress;

    // ------- Slot ------- //
    
    // Randomness Provider address.
    address public randomnessProvider;

    // ------- Slot ------- //

    // Exchange address. In Uniswap mode, it's the Uniswap liquidity 
    // pair's address, where trades execute.
    address public exchangeAddress;

    // Start date.
    uint32 public startDate;

    // Completion (Mining Phase End) date.
    uint32 public completionDate;
    
    // The date when Randomness Provider was called, requesting a
    // random seed for the lottery finish.
    // Also, when this variable becomes Non-Zero, it indicates that we're
    // on Ending Stage Part One: waiting for the random seed.
    uint32 finish_timeRandomSeedRequested;

    // ------- Slot ------- //

    // WETH address. Set by calling Router's getter, on constructor.
    address WETHaddress;

    // Is the WETH first or second token in our Uniswap Pair?
    bool uniswap_ethFirst;

    // If we are, or were before, on finishing stage, this is the
    // probability of lottery going to Ending Stage on this transaction.
    uint32 finishProbablity;
    
    // Re-Entrancy Lock (Mutex).
    // We protect for reentrancy in the Fund Transfer functions.
    bool reEntrancyMutexLocked;
    
    // On which stage we are currently.
    uint8 public lotteryStage;
    
    // Indicator for whether the lottery fund gains have passed a 
    // minimum fund gain requirement.
    // After that time point (when this bool is set), the token sells
    // which could drop the fund value below the requirement, would
    // be denied.
    bool fundGainRequirementReached;
    
    // The current step of the Mining Stage.
    uint16 miningStep;

    // If we're currently on Special Transfer Mode - that is, we allow
    // direct transfers between parties even in NON-ACTIVE state.
    bool specialTransferModeEnabled;


    // ------- Slot ------- //
    
    // Per-Transaction Pseudo-Random hash value (transferHashValue).
    // This value is computed on every token transfer, by keccak'ing
    // the last (current) transferHashValue, msg.sender, now, and 
    // transaction count.
    //
    // This is used on Finishing Stage, as a pseudo-random number,
    // which is used to check if we should end the lottery (move to
    // Ending Stage).
    uint256 transferHashValue;

    // ------- Slot ------- //

    // On lottery end, get & store the lottery total ETH return
    // (including initial funds), and profit amount.
    uint128 public ending_totalReturn;
    uint128 public ending_profitAmount;

    // ------- Slot ------- //

    // The mapping that contains TRUE for addresses that already claimed
    // their lottery winner prizes.
    // Used only in COMPLETION, on claimWinnerPrize(), to check if
    // msg.sender has already claimed his prize.
    mapping( address => bool ) public prizeClaimersAddresses;


    // ============= Private/internal functions ============= //


    // Pool Only modifier.
    modifier poolOnly {
        require( msg.sender == poolAddress );
        _;
    }

    // Only randomness provider allowed modifier.
    modifier randomnessProviderOnly {
        require( msg.sender == randomnessProvider );
        _;
    }

    // Execute function only on specific lottery stage.
    modifier onlyOnStage( STAGE _stage ) 
    {
        require( lotteryStage == uint8( _stage ) );
        _;
    }

    // Modifier for protecting the function from re-entrant calls,
    // by using a locked Re-Entrancy Lock (Mutex).
    modifier mutexLOCKED
    {
        require( ! reEntrancyMutexLocked );

        reEntrancyMutexLocked = true;
        _;
        reEntrancyMutexLocked = false;
    }


    // Check if we're currently on a specific stage.
    function onStage( STAGE _stage )
                                                internal view
    returns( bool )
    {
        return ( lotteryStage == uint8( _stage ) );
    }


    /**
     *  Check if token transfer to specific wallet won't exceed 
     *  maximum token amount allowed to own by a single wallet.
     *
     *  @return true, if holder's balance with "amount" added,
     *      would exceed the max allowed single holder's balance
     *      (by default, that is 5% of total supply).
     */
    function transferExceedsMaxBalance( 
            address holder, uint amount )
                                                internal view
    returns( bool )
    {
        uint maxAllowedBalance = 
            ( totalSupply() * cfg.maxAmountForWallet_percentageOfSupply ) /
            ( _100PERCENT );

        return ( ( balanceOf( holder ) + amount ) > maxAllowedBalance );
    }


    /**
     *  Update holder data.
     *  This function is called by _transfer() function, just before
     *  transfering final amount of tokens directly from sender to
     *  receiver.
     *  At this point, all burns/mints have been done, and we're sure
     *  that this transfer is valid and must be successful.
     *
     *  In all modes, this function is used to update the holder array.
     *
     *  However, on external exchange modes (e.g. on Uniswap mode),
     *  it is also used to track buy/sell ether value, to update holder
     *  scores, when token buys/sells cannot be tracked directly.
     *
     *  If, however, we use Standalone mode, we are the exchange,
     *  so on _transfer() we already know the ether value, which is
     *  set to currentBuySellEtherValue variable.
     *
     *  @param amountSent - the token amount that is deducted from
     *      sender's balance. This includes burn, and owner fee.
     *
     *  @param amountReceived - the token amount that receiver 
     *      actually receives, after burns and fees.
     *
     *  @return holderCountChanged - indicates whether holder count
     *      changes during this transfer - new holder joins or leaves
     *      (true), or no change occurs (false).
     */
    function updateHolderData_preTransfer(
            address sender,
            address receiver,
            uint256 amountSent,
            uint256 amountReceived )
                                                internal
    returns( bool holderCountChanged )
    {
        // Update holder array, if new token holder joined, or if
        // a holder transfered his whole balance.
        holderCountChanged = false;

        // Sender transferred his whole balance - no longer a holder.
        if( balanceOf( sender ) == amountSent ) 
        {
            lotStorage.removeHolder( sender );
            holderCountChanged = true;
        }

        // Receiver didn't have any tokens before - add it to holders.
        if( balanceOf( receiver ) == 0 && amountReceived > 0 )
        {
            lotStorage.addHolder( receiver );
            holderCountChanged = true;
        }

        // Update holder score factors: if buy/sell occured, update
        // etherContributed and timeFactors scores,
        // and also propagate the scores through the referral chain
        // to the parent referrers (this is done in Storage contract).

        // This lottery operates only on external exchange (Uniswap)
        // mode, so we have to find out the buy/sell Ether value by 
        // calling the external exchange (Uniswap pair) contract.

        // Temporary variable to store current transfer's buy/sell
        // value in Ethers.
        int buySellValue;

        // Sender is an exchange - buy detected.
        if( sender == exchangeAddress && receiver != exchangeAddress ) 
        {
            // Use the Router's functionality.
            // Set the exchange path to WETH -> ULT
            // (ULT is Lottery Token, and it's address is our address).
            address[] memory path = new address[]( 2 );
            path[ 0 ] = WETHaddress;
            path[ 1 ] = address(this);

            uint[] memory ethAmountIn = uniswapRouter.getAmountsIn(
                amountSent,     // uint amountOut, 
                path            // address[] path
            );

            buySellValue = int( ethAmountIn[ 0 ] );
            
            // Compute time factor value for the current ether value.
            // buySellValue is POSITIVE.
            // When computing Time Factors, leave only 6 ether decimals.
            int timeFactorValue = ( buySellValue / (10 ** 12) ) * 
                int( (now - startDate) / cfg.timeFactorDivisor );

            // Update and propagate the buyer (receiver) scores.
            lotStorage.updateAndPropagateScoreChanges(
                    receiver,
                    int80( buySellValue ),
                    int80( timeFactorValue ),
                    int80( amountReceived ) );
        }

        // Receiver is an exchange - sell detected.
        else if( sender != exchangeAddress && receiver == exchangeAddress )
        {
            // Use the Router's functionality.
            // Set the exchange path to ULT -> WETH
            // (ULT is Lottery Token, and it's address is our address).
            address[] memory path = new address[]( 2 );
            path[ 0 ] = address(this);
            path[ 1 ] = WETHaddress;

            uint[] memory ethAmountOut = uniswapRouter.getAmountsOut(
                amountReceived,     // uint amountIn
                path                // address[] path
            );

            // It's a sell (ULT -> WETH), so set value to NEGATIVE.
            buySellValue = int( -1 ) * int( ethAmountOut[ 1 ] );
            
            // Compute time factor value for the current ether value.
            // buySellValue is NEGATIVE.
            int timeFactorValue = ( buySellValue / (10 ** 12) ) * 
                int( (now - startDate) / cfg.timeFactorDivisor );

            // Update and propagate the seller (sender) scores.
            lotStorage.updateAndPropagateScoreChanges(
                    sender,
                    int80( buySellValue ),
                    int80( timeFactorValue ),
                    -1 * int80( amountSent ) );
        }

        // Neither Sender nor Receiver are exchanges - default transfer.
        // Tokens just got transfered between wallets, without 
        // exchanging for ETH - so etherContributed_change = 0. 
        // On this case, update both sender's & receiver's scores.
        //
        else {
            buySellValue = 0;

            lotStorage.updateAndPropagateScoreChanges( sender, 0, 0, 
                                            -1 * int80( amountSent ) );

            lotStorage.updateAndPropagateScoreChanges( receiver, 0, 0, 
                                            int80( amountReceived ) );
        }

        // Check if lottery liquidity pool funds have already
        // reached a minimum required ETH value.
        uint ethFunds = getCurrentEthFunds();

        if( !fundGainRequirementReached &&
            ethFunds >= cfg.fundRequirement_denySells )
        {
            fundGainRequirementReached = true;
        }

        // Check whether this token transfer is allowed if it's a sell
        // (if buySellValue is negative):
        //
        // If we've already reached the minimum fund gain requirement,
        // and this sell would shrink lottery liquidity pool's ETH funds
        // below this requirement, then deny this sell, causing this 
        // transaction to fail.

        if( fundGainRequirementReached &&
            buySellValue < 0 &&
            ( uint( -1 * buySellValue ) >= ethFunds ||
              ethFunds - uint( -1 * buySellValue ) < 
                cfg.fundRequirement_denySells ) )
        {
            require( false );
        }
    }
    
    
    /**
     *  Check for finishing stage start conditions.
     *  - If some conditions are met, start finishing stage!
     *    Do it by setting "onFinishingStage" bool.
     *  - If we're currently on finishing stage, and some condition
     *    is no longer met, then stop the finishing stage.
     */
    function checkFinishingStageConditions()
                                                    internal
    {
        // Firstly, check if lottery hasn't exceeded it's maximum lifetime.
        // If so, don't check anymore, just set finishing stage, and
        // end the lottery on further call of checkForEnding().
        if( (now - startDate) > cfg.maxLifetime ) 
        {
            lotteryStage = uint8( STAGE.FINISHING );
            return;
        }

        // Compute & check the finishing criteria.

        // Notice that we adjust the config-specified fund gain
        // percentage increase to uint-mode, by adding 100 percents,
        // because we don't deal with negative percentages, and here
        // we represent loss as a percentage below 100%, and gains
        // as percentage above 100%.
        // So, if in regular gains notation, it's said 10% gain,
        // in uint mode, it's said 110% relative increase.
        //
        // (Also, remember that losses are impossible in our lottery
        //  working scheme).

        if( lotStorage.getHolderCount() >= cfg.finishCriteria_minNumberOfHolders
            &&
            getCurrentEthFunds() >= cfg.finishCriteria_minFunds
            &&
            (now - startDate) >= cfg.finishCriteria_minTimeActive )
        {
            if( onStage( STAGE.ACTIVE ) )
            {
                // All conditions are met - start the finishing stage.
                lotteryStage = uint8( STAGE.FINISHING );

                emit FinishingStageStarted();
            }
        }

        else if( onStage( STAGE.FINISHING ) )
        {
            // However, what if some condition was not met, but we're
            // already on the finishing stage?
            // If so, we must stop the finishing stage.
            // But what to do with the finishing probability?
            // Config specifies if it should be reset or maintain it's
            // value until the next time finishing stage is started.

            lotteryStage = uint8( STAGE.ACTIVE );

            if( cfg.finish_resetProbabilityOnStop )
                finishProbablity = cfg.finish_initialProbability;

            emit FinishingStageStopped();
        }
    }


    /**
     *  We're currently on finishing stage - so let's check if
     *  we should end the lottery now!
     *
     *  This function is called from _transfer(), only if we're sure
     *  that we're currently on finishing stage (onFinishingStage
     *  variable is set).
     *
     *  Here, we compute the pseudo-random number from hash of
     *  current message's sender, now, and other values,
     *  and modulo it to the current finish probability.
     *  If it's equal to 1, then we end the lottery!
     *
     *  Also, here we update the finish probability according to
     *  probability update criteria - holder count, and tx count.
     *
     *  @param holderCountChanged - indicates whether Holder Count
     *      has changed during this transfer (new holder joined, or
     *      a holder sold all his tokens).
     */
    function checkForEnding( bool holderCountChanged )
                                                            internal
    {
        // At first, check if lottery max lifetime is exceeded.
        // If so, start ending procedures right now.
        if( (now - startDate) > cfg.maxLifetime )
        {
            startEndingStage();
            return;
        }

        // Now, we know that lottery lifetime is still OK, and we're
        // currently on Finishing Stage (because this function is
        // called only when onFinishingStage is set).
        //
        // Now, check if we should End the lottery, by computing
        // a modulo on a pseudo-random number, which is a transfer
        // hash, computed for every transfer on _transfer() function.
        //
        // Get the modulo amount according to current finish 
        // probability.
        // We use precision of 0.01% - notice the "10000 *" before
        // 100 PERCENT.
        // Later, when modulo'ing, we'll check if value is below 10000.
        //
        uint prec = 10000;
        uint modAmount = (prec * _100PERCENT) / finishProbablity;

        if( ( transferHashValue % modAmount ) <= prec )
        {
            // Finish probability is met! Commence lottery end - 
            // start Ending Stage.
            startEndingStage();
            return;
        }

        // Finish probability wasn't met.
        // Update the finish probability, by increasing it!

        // Transaction count criteria.
        // As we know that this function is called on every new 
        // transfer (transaction), we don't check if transactionCount
        // increased or not - we just perform probability update.

        finishProbablity += cfg.finish_probabilityIncreaseStep_transaction;

        // Now, perform holder count criteria update.
        // Finish probability increases, no matter if holder count
        // increases or decreases.
        if( holderCountChanged )
            finishProbablity += cfg.finish_probabilityIncreaseStep_holder;
    }


    /**
     *  Start the Ending Stage, by De-Activating the lottery,
     *  to deny all further token transfers (excluding the one when
     *  removing liquidity from Uniswap), and transition into the 
     *  Mining Phase - set the lotteryStage to MINING.
     */
    function startEndingStage()
                                                internal
    {
        lotteryStage = uint8( STAGE.ENDING_MINING );
    }


    /**
     *  Execute the first step of the Mining Stage - request a 
     *  Random Seed from the Randomness Provider.
     *
     *  Here, we call the Randomness Provider, asking for a true random seed
     *  to be passed to us into our callback, named 
     *  "finish_randomnessProviderCallback()".
     *
     *  When that callback will be called, our storage's random seed will
     *  be set, and we'll be able to start the Ending Algorithm on
     *  further mining steps.
     *
     *  Notice that Randomness Provider must already be funded, to
     *  have enough Ether for Provable fee and the gas costs of our
     *  callback function, which are quite high, because of winner
     *  selection algorithm, which is computationally expensive.
     *
     *  The Randomness Provider is always funded by the Pool,
     *  right before the Pool deploys and starts a new lottery, so
     *  as every lottery calls the Randomness Provider only once,
     *  the one-call-fund method for every lottery is sufficient.
     *
     *  Also notice, that Randomness Provider might fail to call
     *  our callback due to some unknown reasons!
     *  Then, the lottery profits could stay locked in this 
     *  lottery contract forever ?!!
     *
     *  No! We've thought about that - we've implemented the
     *  Alternative Ending mechanism, where, if specific time passes 
     *  after we've made a request to Randomness Provider, and
     *  callback hasn't been called yet, we allow external actor to
     *  execute the Alternative ending, which basically does the
     *  same things as the default ending, just that the Random Seed
     *  will be computed locally in our contract, using the
     *  Pseudo-Random mechanism, which could compute a reasonably
     *  fair and safe value using data from holder array, and other
     *  values, described in more detail on corresponding function's
     *  description.
     */
    function mine_requestRandomSeed()
                                                internal
    {
        // We're sure that the Randomness Provider has enough funds.
        // Execute the random request, and get ready for Ending Algorithm.

        IRandomnessProvider( randomnessProvider )
            .requestRandomSeedForLotteryFinish();

        // Store the time when random seed has been requested, to
        // be able to alternatively handle the lottery finish, if
        // randomness provider doesn't call our callback for some
        // reason.
        finish_timeRandomSeedRequested = uint32( now );

        // Emit appropriate events.
        emit RandomnessProviderCalled();
    }


    /** PAYABLE [ OUT ] >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
     *
     *  Transfer the Owner & Pool profit shares, when lottery ends.
     *  This function is the first one that's executed on the Mining
     *  Stage.
     *  This is the first step of Mining. So, the Miner who executes this
     *  function gets the mining reward.
     *
     *  This function's job is to Gather the Profits & Initial Funds,
     *  and Transfer them to Profiters - that is, to The Pool, and
     *  to The Owner.
     *
     *  The Miners' profit share and Winner Prize Fund stay in this
     *  contract.
     *
     *  On this function, we (in this order):
     *
     *  1. Remove all liquidity from Uniswap (if using Uniswap Mode),
     *      pulling it to our contract's wallet.
     *
     *  2. Transfer the Owner and the Pool ETH profit shares to
     *      Owner and Pool addresses.
     *
     *  * This function transfers Ether out of our contract:
     *      - We transfer the Profits to Pool and Owner addresses.
     */
    function mine_removeUniswapLiquidityAndTransferProfits()
                                                                internal
                                                                mutexLOCKED
    {
        // We've already approved our token allowance to Router.
        // Now, approve Uniswap liquidity token's Router allowance.
        ERC20( exchangeAddress ).approve( address(uniswapRouter), uint(-1) );

        // Enable the SPECIAL-TRANSFER mode, to allow Uniswap to transfer
        // the tokens from Pair to Router, and then from Router to us.
        specialTransferModeEnabled = true;

        // Remove liquidity!
        uint amountETH = uniswapRouter
            .removeLiquidityETHSupportingFeeOnTransferTokens(
                address(this),          // address token,
                ERC20( exchangeAddress ).balanceOf( address(this) ),
                0,                      // uint amountTokenMin,
                0,                      // uint amountETHMin,
                address(this),          // address to,
                (now + 10000000)        // uint deadline
            );

        // Tokens are transfered. Disable the special transfer mode.
        specialTransferModeEnabled = false;

        // Check that we've got a correct amount of ETH.
        require( address(this).balance >= amountETH &&
                 address(this).balance >= cfg.initialFunds );


        // Compute the Profit Amount (current balance - initial funds).
        ending_totalReturn = uint128( address(this).balance );
        ending_profitAmount = ending_totalReturn - uint128( cfg.initialFunds );

        // Compute, and Transfer Owner's profit share and 
        // Pool's profit share to their respective addresses.

        uint poolShare = ( ending_profitAmount * cfg.poolProfitShare ) /
                         ( _100PERCENT );

        uint ownerShare = ( ending_profitAmount * cfg.ownerProfitShare ) /
                          ( _100PERCENT );

        // To pool, transfer it's profit share plus initial funds.
        IUniLotteryPool( poolAddress ).lotteryFinish
            { value: poolShare + cfg.initialFunds }
            ( ending_totalReturn, ending_profitAmount );

        // Transfer Owner's profit share.
        OWNER_ADDRESS.transfer( ownerShare );

        // Emit ending event.
        emit LotteryEnd( ending_totalReturn, ending_profitAmount );
    }


    /**
     *  Executes a single step of the Winner Selection Algorithm
     *  (the Ending Algorithm).
     *  The algorithm itself is being executed in the Storage contract.
     *
     *  On current design, whole algorithm is executed in a single step.
     *
     *  This function is executed only in the Mining stage, and
     *  accounts for most of the gas spent during mining.
     */
    function mine_executeEndingAlgorithmStep()
                                                            internal
    {
        // Launch the winner algorithm, to execute the next step.
        lotStorage.executeWinnerSelectionAlgorithm();
    }



    // =============== Public functions =============== //


    /**
     *  Constructor of this delegate code contract.
     *  Here, we set OUR STORAGE's lotteryStage to DISABLED, because
     *  we don't want anybody to call this contract directly.
     */
    constructor()       public
    {
        lotteryStage = uint8( STAGE.DISABLED );
    }


    /**
     *  Construct the lottery contract which is delegating it's
     *  call to us.
     *
     *  @param config - LotteryConfig structure to use in this lottery.
     *
     *      Future approach: ABI-encoded Lottery Config 
     *      (different implementations might use different config 
     *      structures, which are ABI-decoded inside the implementation).
     *
     *      Also, this "config" includes the ABI-encoded temporary values, 
     *      which are not part of persisted LotteryConfig, but should
     *      be used only in constructor - for example, values to be
     *      assigned to storage variables, such as ERC20 token's
     *      name, symbol, and decimals.
     *
     *  @param _poolAddress - Address of the Main UniLottery Pool, which
     *      provides initial funds, and receives it's profit share.
     *
     *  @param _randomProviderAddress - Address of a Randomness Provider,
     *      to use for obtaining random seeds.
     *
     *  @param _storageAddress  - Address of a Lottery Storage.
     *      Storage contract is a separate contract which holds all 
     *      lottery token holder data, such as intermediate scores.
     *
     */
    function construct( 
            LotteryConfig memory config,
            address payable _poolAddress,
            address _randomProviderAddress,
            address _storageAddress )
                                                        external
    {
        // Check if contract wasn't already constructed!
        require( poolAddress == address( 0 ) );

        // Set the Pool's Address - notice that it's not the
        // msg.sender, because lotteries aren't created directly
        // by the Pool, but by the Lottery Factory!
        poolAddress = _poolAddress;

        // Set the Randomness Provider address.
        randomnessProvider = _randomProviderAddress;


        // Check the minimum & maximum requirements for config
        // profit & lifetime parameters.

        require( config.maxLifetime <= MAX_LOTTERY_LIFETIME );

        require( config.poolProfitShare >= MIN_POOL_PROFITS &&
                 config.poolProfitShare <= MAX_POOL_PROFITS );

        require( config.ownerProfitShare >= MIN_OWNER_PROFITS &&
                 config.ownerProfitShare <= MAX_OWNER_PROFITS );

        require( config.minerProfitShare >= MIN_MINER_PROFITS &&
                 config.minerProfitShare <= MAX_MINER_PROFITS );

        // Check if winner profit share is good.
        uint32 totalWinnerShare = 
            (_100PERCENT) - config.poolProfitShare
                            - config.ownerProfitShare
                            - config.minerProfitShare;

        require( totalWinnerShare >= MIN_WINNER_PROFIT_SHARE );

        // Check if ending algorithm params are good.
        require( config.randRatio_scorePart != 0    &&
                 config.randRatio_randPart  != 0    &&
                 ( config.randRatio_scorePart + 
                   config.randRatio_randPart    ) < 10000 );

        require( config.endingAlgoType == 
                    uint8( EndingAlgoType.MinedWinnerSelection ) ||
                 config.endingAlgoType == 
                    uint8( EndingAlgoType.WinnerSelfValidation ) ||
                 config.endingAlgoType == 
                    uint8( EndingAlgoType.RolledRandomness ) );

        // Set the number of winners (winner count).
        // If using Computed Sequence winner prize shares, set that
        // value, and if it's zero, then we're using the Array-Mode
        // prize share specification.
        if( config.prizeSequence_winnerCount == 0 &&
            config.winnerProfitShares.length != 0 )
            config.prizeSequence_winnerCount = 
                uint16( config.winnerProfitShares.length );


        // Setup our Lottery Storage - initialize, and set the
        // Algorithm Config.

        LotteryStorage _lotStorage = LotteryStorage( _storageAddress );

        // Setup a Winner Score Config for the winner selection algo,
        // to be used in the Lottery Storage.
        LotteryStorage.WinnerAlgorithmConfig memory winnerConfig;

        // Algorithm type.
        winnerConfig.endingAlgoType = config.endingAlgoType;

        // Individual player max score parts.
        winnerConfig.maxPlayerScore_etherContributed =
            config.maxPlayerScore_etherContributed;

        winnerConfig.maxPlayerScore_tokenHoldingAmount =
            config.maxPlayerScore_tokenHoldingAmount;

        winnerConfig.maxPlayerScore_timeFactor =
            config.maxPlayerScore_timeFactor;

        winnerConfig.maxPlayerScore_refferalBonus =
            config.maxPlayerScore_refferalBonus;

        // Score-To-Random ratio parts.
        winnerConfig.randRatio_scorePart = config.randRatio_scorePart;
        winnerConfig.randRatio_randPart = config.randRatio_randPart;

        // Set winner count (no.of winners).
        winnerConfig.winnerCount = config.prizeSequence_winnerCount;


        // Initialize the storage (bind it to our contract).
        _lotStorage.initialize( winnerConfig );

        // Set our immutable variable.
        lotStorage = _lotStorage;


        // Now, set our config to the passed config.
        cfg = config;

        // Might be un-needed (can be replaced by Constant on the MainNet):
        WETHaddress = uniswapRouter.WETH();
    }


    /** PAYABLE [ IN  ] <<<<<<<<<<<<<<<<<<<<<<<<<<<<
     *
     *  Fallback Receive Ether function.
     *  Used to receive ETH funds back from Uniswap, on lottery's end,
     *  when removing liquidity.
     */
    receive()       external payable
    {
        emit FallbackEtherReceiver( msg.sender, msg.value );
    }



    /** PAYABLE [ IN  ] <<<<<<<<<<<<<<<<<<<<<<<<<<<<
     *  PAYABLE [ OUT ] >>>>>>>>>>>>>>>>>>>>>>>>>>>>
     *
     *  Initialization function.
     *  Here, the most important startup operations are made - 
     *  such as minting initial token supply and transfering it to
     *  the Uniswap liquidity pair, in exchange for UNI-v2 tokens.
     *
     *  This function is called by the pool, when transfering
     *  initial funds to this contract.
     *
     *  What's payable?
     *  - Pool transfers initial funds to our contract.
     *  - We transfer that initial fund Ether to Uniswap liquidity pair
     *    when creating/providing it.
     */
    function initialize()   
                                        external
                                        payable
                                        poolOnly
                                        mutexLOCKED
                                        onlyOnStage( STAGE.INITIAL )
    {
        // Check if pool transfered correct amount of funds.
        require( address( this ).balance == cfg.initialFunds );

        // Set start date.
        startDate = uint32( now );

        // Set the initial transfer hash value.
        transferHashValue = uint( keccak256( 
                abi.encodePacked( msg.sender, now ) ) );

        // Set initial finish probability, to be used when finishing
        // stage starts.
        finishProbablity = cfg.finish_initialProbability;
        
        
        // ===== Active operations - mint & distribute! ===== //

        // Mint full initial supply of tokens to our contract address!
        _mint( address(this), 
               uint( cfg.initialTokenSupply ) * (10 ** decimals) );

        // Now - prepare to create a new Uniswap Liquidity Pair,
        // with whole our total token supply and initial funds ETH
        // as the two liquidity reserves.
        
        // Approve Uniswap Router to allow it to spend our tokens.
        // Set maximum amount available.
        _approve( address(this), address( uniswapRouter ), uint(-1) );

        // Provide liquidity - the Router will automatically
        // create a new Pair.
        
        uniswapRouter.addLiquidityETH 
        { value: address(this).balance }
        (
            address(this),          // address token,
            totalSupply(),          // uint amountTokenDesired,
            totalSupply(),          // uint amountTokenMin,
            address(this).balance,  // uint amountETHMin,
            address(this),          // address to,
            (now + 1000)            // uint deadline
        );

        // Get the Pair address - that will be the exchange address.
        exchangeAddress = IUniswapFactory( uniswapRouter.factory() )
            .getPair( WETHaddress, address(this) );

        // We assume that the token reserves of the pair are good,
        // and that we own the full amount of liquidity tokens.

        // Find out which of the pair tokens is WETH - is it the 
        // first or second one. Use it later, when getting our share.
        if( IUniswapPair( exchangeAddress ).token0() == WETHaddress )
            uniswap_ethFirst = true;
        else
            uniswap_ethFirst = false;


        // Move to ACTIVE lottery stage.
        // Now, all token transfers will be allowed.
        lotteryStage = uint8( STAGE.ACTIVE );

        // Lottery is initialized. We're ready to emit event.
        emit LotteryInitialized();
    }


    // Return this lottery's initial funds, as were specified in the config.
    //
    function getInitialFunds()          external view
    returns( uint )
    {
        return cfg.initialFunds;
    }

    // Return active (still not returned to pool) initial fund value.
    // If no-longer-active, return 0 (default) - because funds were 
    // already returned back to the pool.
    //
    function getActiveInitialFunds()    external view
    returns( uint )
    {
        if( onStage( STAGE.ACTIVE ) )
            return cfg.initialFunds;
        return 0;
    }


    /**
     *  Get current Exchange's Token and ETH reserves.
     *  We're on Uniswap mode, so get reserves from Uniswap.
     */
    function getReserves() 
                                                        external view
    returns( uint _ethReserve, uint _tokenReserve )
    {
        // Use data from Uniswap pair contract.
        ( uint112 res0, uint112 res1, ) = 
            IUniswapPair( exchangeAddress ).getReserves();

        if( uniswap_ethFirst )
            return ( res0, res1 );
        else
            return ( res1, res0 );
    }


    /**
     *  Get our share (ETH amount) of the Uniswap Pair ETH reserve,
     *  of our Lottery tokens ULT-WETH liquidity pair.
     */
    function getCurrentEthFunds()
                                                        public view
    returns( uint ethAmount )
    {
        IUniswapPair pair = IUniswapPair( exchangeAddress );
        
        ( uint112 res0, uint112 res1, ) = pair.getReserves();
        uint resEth = uint( uniswap_ethFirst ? res0 : res1 );

        // Compute our amount of the ETH reserve, based on our
        // percentage of our liquidity token balance to total supply.
        uint liqTokenPercentage = 
            ( pair.balanceOf( address(this) ) * (_100PERCENT) ) /
            ( pair.totalSupply() );

        // Compute and return the ETH reserve.
        return ( resEth * liqTokenPercentage ) / (_100PERCENT);
    }


    /**
     *  Get current finish probability.
     *  If it's ACTIVE stage, return 0 automatically.
     */
    function getFinishProbability()
                                                        external view
    returns( uint32 )
    {
        if( onStage( STAGE.FINISHING ) )
            return finishProbablity;
        return 0;
    }


    
    /**
     *  Generate a referral ID for msg.sender, who must be a token holder.
     *  Referral ID is used to refer other wallets into playing our
     *  lottery.
     *  - Referrer gets bonus points for every wallet that bought 
     *    lottery tokens and specified his referral ID.
     *  - Referrees (wallets who got referred by registering a valid
     *    referral ID, corresponding to some referrer), get some
     *    bonus points for specifying (registering) a referral ID.
     *
     *  Referral ID is a uint256 number, which is generated by
     *  keccak256'ing the holder's address, holder's current
     *  token ballance, and current time.
     */
    function generateReferralID()
                                        external
                                        onlyOnStage( STAGE.ACTIVE )
    {
        uint256 refID = lotStorage.generateReferralID( msg.sender );

        // Emit approppriate events.
        emit ReferralIDGenerated( msg.sender, refID );
    }


    /**
     *  Register a referral for a msg.sender (must be token holder),
     *  using a valid referral ID got from a referrer.
     *  This function is called by a referree, who obtained a
     *  valid referral ID from some referrer, who previously
     *  generated it using generateReferralID().
     *
     *  You can only register a referral once!
     *  When you do so, you get bonus referral points!
     */
    function registerReferral( 
            uint256 referralID )
                                        external
                                        onlyOnStage( STAGE.ACTIVE )
    {
        address referrer = lotStorage.registerReferral( 
                msg.sender,
                cfg.playerScore_referralRegisteringBonus,
                referralID );

        // Emit approppriate events.
        emit ReferralRegistered( msg.sender, referrer, referralID );
    }


    /**
     *  The most important function of this contract - Transfer Function.
     *
     *  Here, all token burning, intermediate score tracking, and 
     *  finish condition checking is performed, according to the 
     *  properties specified in config.
     */
    function _transfer( address sender,
                        address receiver,
                        uint256 amount )
                                            internal
                                            override
    {
        // Check if transfers are allowed in current state.
        // On Non-Active stage, transfers are allowed only from/to
        // our contract.
        // As we don't have Standalone Mode on this lottery variation,
        // that means that tokens to/from our contract are travelling
        // only when we transfer them to Uniswap Pair, and when
        // Uniswap transfers them back to us, on liquidity remove.
        //
        // On this state, we also don't perform any burns nor
        // holding trackings - just transfer and return.

        if( !onStage( STAGE.ACTIVE )    &&
            !onStage( STAGE.FINISHING ) &&
            ( sender == address(this) || receiver == address(this) ||
              specialTransferModeEnabled ) )
        {
            super._transfer( sender, receiver, amount );
            return;
        }

        // Now, we know that we're NOT on special mode.
        // Perform standard checks & brecks.
        require( ( onStage( STAGE.ACTIVE ) || 
                   onStage( STAGE.FINISHING ) ) );
                 
        // Can't transfer zero tokens, or use address(0) as sender.
        require( amount != 0 && sender != address(0) );


        // Compute the Burn Amount - if buying tokens from an exchange,
        // we use a lower burn rate - to incentivize buying!
        // Otherwise (if selling or just transfering between wallets),
        // we use a higher burn rate.
        uint burnAmount;

        // It's a buy - sender is an exchange.
        if( sender == exchangeAddress )
            burnAmount = ( amount * cfg.burn_buyerRate ) / (_100PERCENT);
        else
            burnAmount = ( amount * cfg.burn_defaultRate ) / (_100PERCENT);
        
        // Now, compute the final amount to be gotten by the receiver.
        uint finalAmount = amount - burnAmount;

        // Check if receiver's balance won't exceed the max-allowed!
        // Receiver must not be an exchange.
        if( receiver != exchangeAddress )
        {
            require( !transferExceedsMaxBalance( receiver, finalAmount ) );
        }

        // Now, update holder data array accordingly.
        bool holderCountChanged = updateHolderData_preTransfer( 
                sender, 
                receiver, 
                amount,             // Amount Sent (Pre-Fees)
                finalAmount         // Amount Received (Post-Fees).
        );

        // All is ok - perform the burn and token transfers now.

        // Burn token amount from sender's balance.
        super._burn( sender, burnAmount );

        // Finally, transfer the final amount from sender to receiver.
        super._transfer( sender, receiver, finalAmount );


        // Compute new Pseudo-Random transfer hash, which must be
        // computed for every transfer, and is used in the
        // Finishing Stage as a pseudo-random unique value for 
        // every transfer, by which we determine whether lottery
        // should end on this transfer.
        //
        // Compute it like this: keccak the last (current) 
        // transferHashValue, msg.sender, sender, receiver, amount.

        transferHashValue = uint( keccak256( abi.encodePacked(
            transferHashValue, msg.sender, sender, receiver, amount ) ) );


        // Check if we should be starting a finishing stage now.
        checkFinishingStageConditions();

        // If we're on finishing stage, check for ending conditions.
        // If ending check is satisfied, the checkForEnding() function
        // starts ending operations.
        if( onStage( STAGE.FINISHING ) )
            checkForEnding( holderCountChanged );
    }


    /**
     *  Callback function, which is called from Randomness Provider,
     *  after it obtains a random seed to be passed to us, after
     *  we have initiated The Ending Stage, on which random seed
     *  is used to generate random factors for Winner Selection
     *  algorithm.
     */ 
    function finish_randomnessProviderCallback(
            uint256 randomSeed,
            uint256 /*callID*/ )
                                                external
                                                randomnessProviderOnly
    {
        // Set the random seed in the Storage Contract.
        lotStorage.setRandomSeed( randomSeed );

        // If algo-type is not Mined Winner Selection, then by now
        // we assume lottery as COMPL3T3D.
        if( cfg.endingAlgoType != uint8(EndingAlgoType.MinedWinnerSelection) )
        {
            lotteryStage = uint8( STAGE.COMPLETION );
            completionDate = uint32( now );
        }
    }


    /**
     *  Function checks if we can initiate Alternative Seed generation.
     *
     *  Alternative approach to Lottery Random Seed is used only when
     *  Randomness Provider doesn't work, and doesn't call the
     *  above callback.
     *
     *  This alternative approach can be initiated by Miners, when
     *  these conditions are met:
     *  - Lottery is on Ending (Mining) stage.
     *  - Request to Randomness Provider was made at least X time ago,
     *    and our callback hasn't been called yet.
     *
     *  If these conditions are met, we can initiate the Alternative
     *  Random Seed generation, which generates a seed based on our
     *  state.
     */
    function alternativeSeedGenerationPossible()
                                                        internal view
    returns( bool )
    {
        return ( onStage( STAGE.ENDING_MINING ) &&
                 ( (now - finish_timeRandomSeedRequested) >
                   cfg.REQUIRED_TIME_WAITING_FOR_RANDOM_SEED ) );
    }


    /**
     *  Return this lottery's config, using ABIEncoderV2.
     */
    /*function getLotteryConfig()
                                                    external view
    returns( LotteryConfig memory ourConfig )
    {
        return cfg;
    }*/


    /**
     *  Checks if Mining is currently available.
     */
    function isMiningAvailable()
                                                    external view
    returns( bool )
    {
        return onStage( STAGE.ENDING_MINING ) && 
               ( miningStep == 0 || 
                 ( miningStep == 1 && 
                   ( lotStorage.getRandomSeed() != 0 ||
                     alternativeSeedGenerationPossible() )
                 ) );
    }


    /** PAYABLE [ OUT ] >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
     *
     *  Mining function, to be executed on Ending (Mining) stage.
     *
     *  "Mining" approach is used in this lottery, to use external
     *  actors for executing the gas-expensive Ending Algorithm,
     *  and other ending operations, such as profit transfers.
     *
     *  "Miners" can be any external actors who call this function.
     *  When Miner successfully completes a Mining Step, he gets 
     *  a Mining Reward, which is a certain portion of lottery's profit
     *  share, dedicated to Miners.
     *
     *  NOT-IMPLEMENTED APPROACH:
     *
     *  All these operations are divided into "mining steps", which are
     *  smaller components, which fit into reasonable gas limits.
     *  All "steps" are designed to take up similar amount of gas.
     *
     *  For example, if total lottery profits (total ETH got from
     *  pulling liquidity out of Uniswap, minus initial funds),
     *  is 100 ETH, Miner Profit Share is 10%, and there are 5 mining
     *  steps total, then for a singe step executed, miner will get:
     *
     *  (100 * 0.1) / 5 = 2 ETH.
     *
     *  ---------------------------------
     *
     *  CURRENTLY IMPLEMENTED APPROACH:
     *
     *  As the above-defined approach would consume very much gas for
     *  inter-step intermediate state storage, we have thought that
     *  for now, it's better to have only 2 mining steps, the second of
     *  which performs the whole Winner Selection Algorithm.
     *
     *  This is because performing the whole algorithm at once would save
     *  us up to 10x more gas in total, than executing it in steps.
     *
     *  However, this solution is not scalable, because algorithm has
     *  to fit into block gas limit (10,000,000 gas), so we are limited
     *  to a certain safe maximum number of token holders, which is
     *  empirically determined during testing, and defined in the
     *  MAX_SAFE_NUMBER_OF_HOLDERS constant, which is checked against the
     *  config value "finishCriteria_minNumberOfHolders" in constructor.
     *
     *  So, in this approach, there are only 2 mining steps:
     *
     *  1. Remove liquidity from Uniswap, transfer profit shares to
     *      the Pool and the Owner Address, and request Random Seed
     *      from the Randomness Provider.
     *      Reward: 25% of total Mining Rewards.
     *
     *  2. Perform the whole Winner Selection Algorithm inside the
     *      Lottery Storage contract.
     *      Reward: 75% of total Mining Rewards.
     *
     *  * Function transfers Ether out of our contract:
     *    - Transfers the current miner's reward to msg.sender.
     */
    function mine()
                                external
                                onlyOnStage( STAGE.ENDING_MINING )
    {
        uint currentStepReward;

        // Perform different operations on different mining steps.

        // Step 0:  Remove liquidity from Uniswap, transfer profits to
        //          Pool and Owner addresses. Also, request a Random Seed
        //          from the Randomness Provider.
        if( miningStep == 0 )
        {
            mine_requestRandomSeed();
            mine_removeUniswapLiquidityAndTransferProfits();

            // Compute total miner reward amount, then compute this 
            // step's reward later.
            uint totalMinerRewards = 
                ( ending_profitAmount * cfg.minerProfitShare ) / 
                ( _100PERCENT );

            // Step 0 reward is 10% for Algo type 1.
            if( cfg.endingAlgoType == uint8(EndingAlgoType.MinedWinnerSelection) )
            {
                currentStepReward = ( totalMinerRewards * (10 * PERCENT) ) /
                                    ( _100PERCENT );
            }
            // If other algo-types, second step is not normally needed,
            // so here we take 80% of miner rewards.
            // If Randomness Provider won't give us a seed after
            // specific amount of time, we'll initiate a second step,
            // with remaining 20% of miner rewords.
            else
            {
                currentStepReward = ( totalMinerRewards * (80 * PERCENT) ) /
                                    ( _100PERCENT );
            }

            require( currentStepReward <= totalMinerRewards );
        }

        // Step 1:
        //  If we use MinedWinnerSelection algo-type, then execute the 
        //  winner selection algorithm.
        //  Otherwise, check if Random Provider hasn't given us a
        //  random seed long enough, so that we have to generate a
        //  seed locally.
        else
        {
            // Check if we can go into this step when using specific
            // ending algorithm types.
            if( cfg.endingAlgoType != uint8(EndingAlgoType.MinedWinnerSelection) )
            {
                require( lotStorage.getRandomSeed() == 0 &&
                         alternativeSeedGenerationPossible() );
            }

            // Compute total miner reward amount, then compute this 
            // step's reward later.
            uint totalMinerRewards = 
                ( ending_profitAmount * cfg.minerProfitShare ) / 
                ( _100PERCENT );

            // Firstly, check if random seed is already obtained.
            // If not, check if we should generate it locally.
            if( lotStorage.getRandomSeed() == 0 )
            {
                if( alternativeSeedGenerationPossible() )
                {
                    // Set random seed inside the Storage Contract,
                    // but using our contract's transferHashValue as the
                    // random seed.
                    // We believe that this hash has enough randomness
                    // to be considered a fairly good random seed,
                    // because it has beed chain-computed for every
                    // token transfer that has occured in ACTIVE stage.
                    //
                    lotStorage.setRandomSeed( transferHashValue );

                    // If using Non-Mined algorithm types, reward for this
                    // step is 20% of miner funds.
                    if( cfg.endingAlgoType != 
                        uint8(EndingAlgoType.MinedWinnerSelection) )
                    {
                        currentStepReward = 
                            ( totalMinerRewards * (20 * PERCENT) ) /
                            ( _100PERCENT );
                    }
                }
                else
                {
                    // If alternative seed generation is not yet possible
                    // (not enough time passed since the rand.provider
                    // request was made), then mining is not available
                    // currently.
                    require( false );
                }
            }

            // Now, we know that  Random Seed is obtained.
            // If we use this algo-type, perform the actual
            // winner selection algorithm.
            if( cfg.endingAlgoType == uint8(EndingAlgoType.MinedWinnerSelection) )
            {
                mine_executeEndingAlgorithmStep();

                // Set the prize amount to SECOND STEP prize amount (90%).
                currentStepReward = ( totalMinerRewards * (90 * PERCENT) ) /
                                    ( _100PERCENT );
            }

            // Now we've completed both Mining Steps, it means MINING stage
            // is finally completed!
            // Transition to COMPLETION stage, and set lottery completion
            // time to NOW.

            lotteryStage = uint8( STAGE.COMPLETION );
            completionDate = uint32( now );

            require( currentStepReward <= totalMinerRewards );
        }

        // Now, transfer the reward to miner!
        // Check for bugs too - if the computed amount doesn't exceed.

        // Increment the mining step - move to next step (if there is one).
        miningStep++;

        // Check & Lock the Re-Entrancy Lock for transfers.
        require( ! reEntrancyMutexLocked );
        reEntrancyMutexLocked = true;

        // Finally, transfer the reward to message sender!
        msg.sender.transfer( currentStepReward );

        // UnLock ReEntrancy Lock.
        reEntrancyMutexLocked = false;
    }


    /**
     *  Function computes winner prize amount for winner at rank #N.
     *  Prerequisites: Must be called only on STAGE.COMPLETION stage,
     *  because we use the final profits amount here, and that value
     *  (ending_profitAmount) is known only on COMPLETION stage.
     *
     *  @param rankingPosition - ranking position of a winner.
     *  @return finalPrizeAmount - prize amount, in Wei, of this winner.
     */
    function getWinnerPrizeAmount(
            uint rankingPosition )
                                                        public view
    returns( uint finalPrizeAmount )
    {
        // Calculate total winner prize fund profit percentage & amount.
        uint winnerProfitPercentage = 
            (_100PERCENT) - cfg.poolProfitShare - 
            cfg.ownerProfitShare - cfg.minerProfitShare;

        uint totalPrizeAmount =
            ( ending_profitAmount * winnerProfitPercentage ) /
            ( _100PERCENT );


        // We compute the prize amounts differently for the algo-type
        // RolledRandomness, because distribution of these prizes is
        // non-deterministic - multiple holders could fall onto the
        // same ranking position, due to randomness of rolled score.
        //
        if( cfg.endingAlgoType == uint8(EndingAlgoType.RolledRandomness) )
        {
            // Here, we'll use Prize Sequence Factor approach differently.
            // We'll use the prizeSequenceFactor value not to compute
            // a geometric progression, but to compute an arithmetic
            // progression, where each ranking position will get a
            // prize equal to 
            // "totalPrizeAmount - rankingPosition * singleWinnerShare"
            //
            // singleWinnerShare is computed as a value corresponding
            // to single-winner's share of total prize amount.
            //
            // Using such an approach, winner at rank 0 would get a
            // prize equal to whole totalPrizeAmount, but, as the
            // scores are rolled using random factor, it's very unlikely
            // to get a such high score, so most likely such prize
            // won't ever be claimed, but it is a possibility.
            //
            // Most of the winners in this approach are likely to
            // roll scores in the middle, so would get prizes equal to
            // 1-10% of total prize funds.

            uint singleWinnerShare = totalPrizeAmount / 
                                     cfg.prizeSequence_winnerCount;

            return totalPrizeAmount - rankingPosition * singleWinnerShare;
        }

        // Now, we know that ending algorithm is normal (deterministic).
        // So, compute the prizes in a standard way.

        // If using Computed Sequence: loop for "rankingPosition"
        // iterations, while computing the prize shares.
        // If "rankingPosition" is larger than sequencedWinnerCount,
        // then compute the prize from sequence-leftover amount.
        if( cfg.prizeSequenceFactor != 0 )
        {
            require( rankingPosition < cfg.prizeSequence_winnerCount );

            // Leftover: If prizeSequenceFactor is 25%, it's 75%.
            uint leftoverPercentage = 
                (_100PERCENT) - cfg.prizeSequenceFactor;

            // Loop until the needed iteration.
            uint loopCount = ( 
                rankingPosition >= cfg.prizeSequence_sequencedWinnerCount ?
                cfg.prizeSequence_sequencedWinnerCount :
                rankingPosition
            );

            for( uint i = 0; i < loopCount; i++ )
            {
                totalPrizeAmount = 
                    ( totalPrizeAmount * leftoverPercentage ) /
                    ( _100PERCENT );
            }

            // Get end prize amount - sequenced, or leftover.
            // Leftover-mode.
            if( loopCount == cfg.prizeSequence_sequencedWinnerCount &&
                cfg.prizeSequence_winnerCount > 
                cfg.prizeSequence_sequencedWinnerCount )
            {
                // Now, totalPrizeAmount equals all leftover-group winner
                // prize funds.
                // So, just divide it by number of leftover winners.
                finalPrizeAmount = 
                    ( totalPrizeAmount ) /
                    ( cfg.prizeSequence_winnerCount -
                      cfg.prizeSequence_sequencedWinnerCount );
            }
            // Sequenced-mode
            else
            {
                finalPrizeAmount = 
                    ( totalPrizeAmount * cfg.prizeSequenceFactor ) /
                    ( _100PERCENT );
            }
        }

        // Else, if we're using Pre-Specified Array of winner profit
        // shares, just get the share at the corresponding index.
        else
        {
            require( rankingPosition < cfg.winnerProfitShares.length );

            finalPrizeAmount = 
                ( totalPrizeAmount *
                  cfg.winnerProfitShares[ rankingPosition ] ) /
                ( _100PERCENT );
        }
    }


    /**
     *  After lottery has completed, this function returns if msg.sender
     *  is one of lottery winners, and the position in winner rankings.
     *  
     *  Function must be used to obtain the ranking position before
     *  calling claimWinnerPrize().
     *
     *  @param addr - address whose status to check.
     */
    function getWinnerStatus( address addr )
                                                        external view
    returns( bool isWinner, uint32 rankingPosition, 
             uint prizeAmount )
    {
        if( !onStage( STAGE.COMPLETION ) || balanceOf( addr ) == 0 )
            return (false , 0, 0);

        ( isWinner, rankingPosition ) =
            lotStorage.getWinnerStatus( addr );

        if( isWinner )
        {
            prizeAmount = getWinnerPrizeAmount( rankingPosition );
            if( prizeAmount > address(this).balance )
                prizeAmount = address(this).balance;
        }
    }


    /**
     *  Compute the intermediate Active Stage player score.
     *  This score is Player Score, not randomized.
     *  @param addr - address to check.
     */
    function getPlayerIntermediateScore( address addr )
                                                        external view
    returns( uint )
    {
        return lotStorage.getPlayerActiveStageScore( addr );
    }


    /** PAYABLE [ OUT ] >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
     *
     *  Claim the winner prize of msg.sender, if he is one of the winners.
     *
     *  This function must be provided a ranking position of msg.sender,
     *  which must be obtained using the function above.
     *  
     *  The Lottery Storage then just checks if holder address in the
     *  winner array element at position rankingPosition is the same
     *  as msg.sender's.
     *
     *  If so, then claim request is valid, and we can give the appropriate
     *  prize to that winner.
     *  Prize can be determined by a computed factor-based sequence, or
     *  from the pre-specified winner array.
     *
     *  * This function transfers Ether out of our contract:
     *    - Sends the corresponding winner prize to the msg.sender.
     *
     *  @param rankingPosition - the position of Winner Array, that
     *      msg.sender says he is in (obtained using getWinnerStatus).
     */
    function claimWinnerPrize(
            uint32 rankingPosition )
                                    external
                                    onlyOnStage( STAGE.COMPLETION )
                                    mutexLOCKED
    {
        // Check if msg.sender hasn't already claimed his prize.
        require( ! prizeClaimersAddresses[ msg.sender ] );

        // msg.sender must have at least some of UniLottery Tokens.
        require( balanceOf( msg.sender ) != 0 );

        // Check if there are any prize funds left yet.
        require( address(this).balance != 0 );

        // If using Mined Selection Algo, check if msg.sender is 
        // really on that ranking position - algo was already executed.
        if( cfg.endingAlgoType == uint8(EndingAlgoType.MinedWinnerSelection) )
        {
            require( lotStorage.minedSelection_isAddressOnWinnerPosition(
                            msg.sender, rankingPosition ) );
        }
        // For other algorithms, get ranking position by executing
        // a specific algorithm of that algo-type.
        else
        {
            bool isWinner;
            ( isWinner, rankingPosition ) =
                lotStorage.getWinnerStatus( msg.sender );

            require( isWinner );
        }

        // Compute the prize amount, using our internal function.
        uint finalPrizeAmount = getWinnerPrizeAmount( rankingPosition ); 

        // If prize is small and computation precision errors occured,
        // leading it to be larger than our balance, fix it.
        if( finalPrizeAmount > address(this).balance )
            finalPrizeAmount = address(this).balance;


        // Transfer the Winning Prize to msg.sender!
        msg.sender.transfer( finalPrizeAmount );


        // Mark msg.sender as already claimed his prize.
        prizeClaimersAddresses[ msg.sender ] = true;
    }


    /** PAYABLE [ OUT ] >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
     *
     *  Transfer the leftover Winner Prize Funds of this contract to the
     *  Main UniLottery Pool, if prize claim deadline has been exceeded.
     *
     *  Function can only be called from the Main Pool, and if some
     *  winners haven't managed to claim their prizes on time, their
     *  prizes will go back to UniLottery Pool.
     *
     *  * Function transfers Ether out of our contract:
     *    - Transfer the leftover funds to the Pool (msg.sender).
     */
    function getUnclaimedPrizes()
                                        external
                                        poolOnly
                                        onlyOnStage( STAGE.COMPLETION )
                                        mutexLOCKED
    {
        // Check if prize claim deadline has passed.
        require( completionDate != 0 &&
                 ( now - completionDate ) > cfg.prizeClaimTime );

        // Just transfer it all to the Pool.
        poolAddress.transfer( address(this).balance );
    }

}



/**
 *  The Lottery Storage contract.
 *
 *  This contract is used to store all Holder Data of a specific lottery
 *  contract - that includes lottery token holders list, and every
 *  holder's intermediate scores (HolderData structure).
 *
 *  When the lottery, that this storage belongs to, ends, then 
 *  this Storage contract also performs the whole winner selection
 *  algorithm.
 *
 *  Also, one of this contract's purposes is to split code,
 *  to avoid the 24kb code size limit error.
 *
 *  Notice, that Lottery and LotteryStorage contracts must have a
 *  1:1 relationship - every Lottery has only one Storage, and
 *  every Storage belongs to only one Lottery.
 *
 *  The LotteryStorage contracts are being created from the 
 *  LotteryStorageFactory contract, and only after that, the parent
 *  Lottery is created, so Lottery must initialize it's Storage,
 *  by calling initialize() function on freshly-created Storage,
 *  which set's the Lottery address, and locks it.
 */
contract LotteryStorage is CoreUniLotterySettings
{
    // ==================== Structs & Constants ==================== //

    // Struct of holder data & scores.
    struct HolderData 
    {
        // --------- Slot --------- //

        // If this holder has generated his own referral ID, this is
        // that ID. If he hasn't generated an ID, this is zero.
        uint256 referralID;

        // --------- Slot --------- //

        // If this holder provided a valid referral ID, this is the 
        // address of a referrer - the user who generated the said
        // referral ID.
        address referrer;

        // --------- Slot --------- //

        // The intermediate score factor variables.
        // Ether contributed: ( buys - sells ). Can be negative.
        int80 etherContributed;

        // Time x ether factor: (relativeTxTime * etherAmount).
        int80 timeFactors;

        // Token balance score factor of this holder - we use int,
        // for easier computation of player scores in our algorithms.
        int80 tokenBalance;

        // Number of all child referrees, including multi-level ones.
        // Updated by traversing child->parent way, incrementing
        // every node's counter by one.
        // Used in Winner Selection Algorithm, to determine how much
        // to divide the accumulated referree scores by.
        uint16 referreeCount;


        // --------- Slot --------- //

        // Accumulated referree score factors - ether contributed by
        // all referrees, time factors, and token balances of all
        // referrees.
        // Can be negative!
        int80 referree_etherContributed;
        int80 referree_timeFactors;
        int80 referree_tokenBalance;

        // Bonus score points, which can be given in certain events,
        // such as when player registers a valid referral ID.
        int16 bonusScore;
    }


    // Final Score (end lottery score * randomValue) structure.
    struct FinalScore 
    {
        address addr;           // 20 bytes \
        uint16 holderIndex;     // 2 bytes  | = 30 bytes => 1 slot.
        uint64 score;           // 8 bytes  /
    }


    // Winner Indexes structure - used to efficiently store Winner
    // indexes in holder's array, after completing the Winner Selection
    // Algorithm.
    // To save Space, we store these in a struct, with uint16 array
    // with 16 items - so this struct takes up excactly 1 slot.
    struct WinnerIndexStruct
    {
        uint16[ 16 ] indexes;
    }


    // A structure which is used by Winner Selection algorithm,
    // which is a subset of the LotteryConfig structure, containing
    // only items necessary for executing the Winner Selection algorigm.
    // More detailed member description can be found in LotteryConfig
    // structure description.
    // Takes up only one slot!
    struct WinnerAlgorithmConfig
    {
        // --------- Slot --------- //

        // Individual player max score parts.
        int16 maxPlayerScore_etherContributed;
        int16 maxPlayerScore_tokenHoldingAmount;
        int16 maxPlayerScore_timeFactor;
        int16 maxPlayerScore_refferalBonus;

        // Number of lottery winners.
        uint16 winnerCount;

        // Score-To-Random ration data (as a rational ratio number).
        // For example if 1:5, then scorePart = 1, and randPart = 5.
        uint16 randRatio_scorePart;
        uint16 randRatio_randPart;

        // The Ending Algorithm type.
        uint8 endingAlgoType;
    }


    // Structure containing the minimum and maximum values of
    // holder intermediate scores.
    // These values get updated on transfers during ACTIVE stage,
    // when holders buy/sell tokens.
    // Structure takes up only 2 slots!
    //
    struct MinMaxHolderScores
    {
        // --------- Slot --------- //

        // Minimum & maximum values for each score factor.
        // Updated for holders when they transfer tokens.
        // Used in winner selection algorithm, to normalize the scores in
        // a single loop, to avoid looping additional time to find min/max.
        int80 holderScore_etherContributed_min;
        int80 holderScore_etherContributed_max;

        int80 holderScore_timeFactors_min;

        // --------- Slot --------- //

        int80 holderScore_timeFactors_max;

        int80 holderScore_tokenBalance_min;
        int80 holderScore_tokenBalance_max;
    }

    // ROOT_REFERRER constant.
    // Used to prevent cyclic dependencies on referral tree.
    address constant ROOT_REFERRER = address( 1 );

    // Precision of division operations.
    int constant PRECISION = 10000;

    // Random number modulo to use when obtaining random numbers from
    // the random seed + nonce, using keccak256.
    // This is the maximum available Score Random Factor, plus one.
    // By default, 10^9 (one billion).
    //
    uint constant RANDOM_MODULO = (10 ** 9);

    // Maximum number of holders that the MinedWinnerSelection algorithm
    // can process. Related to block gas limit.
    uint constant MINEDSELECTION_MAX_NUMBER_OF_HOLDERS = 300;

    // Maximum number of holders that the WinnerSelfValidation algorithm
    // can process. Related to block gas limit.
    uint constant SELFVALIDATION_MAX_NUMBER_OF_HOLDERS = 1200;


    // ==================== State Variables ==================== //

    // --------- Slot --------- //

    // The Lottery address that this storage belongs to.
    // Is set by the "initialize()", called by corresponding Lottery.
    address lottery;

    // The Random Seed, that was passed to us from Randomness Provider,
    // or generated alternatively.
    uint64 randomSeed;

    // The actual number of winners that there will be. Set after
    // completing the Winner Selection Algorithm.
    uint16 numberOfWinners;

    // Bool indicating if Winner Selection Algorithm has been executed.
    bool algorithmCompleted;


    // --------- Slot --------- //

    // Winner Algorithm config. Specified in Initialization().
    WinnerAlgorithmConfig algConfig;

    // --------- Slot --------- //

    // The Min-Max holder score storage.
    MinMaxHolderScores public minMaxScores;

    // --------- Slot --------- //

    // Array of holders.
    address[] public holders;

    // --------- Slot --------- //

    // Holder array indexes mapping, for O(1) array element access.
    mapping( address => uint ) holderIndexes;

    // --------- Slot --------- //

    // Mapping of holder data.
    mapping( address => HolderData ) public holderData;

    // --------- Slot --------- //

    // Mapping of referral IDs to addresses of holders who generated
    // those IDs.
    mapping( uint256 => address ) referrers;

    // --------- Slot --------- //

    // The array of final-sorted winners (set after Winner Selection
    // Algorithm completes), that contains the winners' indexes
    // in the "holders" array, to save space.
    //
    // Notice that by using uint16, we can fit 16 items into one slot!
    // So, if there are 160 winners, we only take up 10 slots, so
    // only 20,000 * 10 = 200,000 gas gets consumed!
    //
    WinnerIndexStruct[] sortedWinnerIndexes;



    // ==============       Internal (Private) Functions    ============== //

    // Lottery-Only modifier.
    modifier lotteryOnly
    {
        require( msg.sender == address( lottery ) );
        _;
    }


    // ============== [ BEGIN ] LOTTERY QUICKSORT FUNCTIONS ============== //

    /**
     *  QuickSort and QuickSelect algorithm functionality code.
     *
     *  These algorithms are used to find the lottery winners in
     *  an array of final random-factored scores.
     *  As the highest-scorers win, we need to sort an array to
     *  identify them.
     *
     *  For this task, we use QuickSelect to partition array into
     *  winner part (elements with score larger than X, where X is
     *  n-th largest element, where n is number of winners),
     *  and others (non-winners), who are ignored to save computation
     *  power.
     *  Then we sort the winner part only, using QuickSort, and
     *  distribute prizes to winners accordingly.
     */

    // Swap function used in QuickSort algorithms.
    //
    function QSort_swap( FinalScore[] memory list, 
                         uint a, uint b )               
                                                        internal pure
    {
        FinalScore memory tmp = list[ a ];
        list[ a ] = list[ b ];
        list[ b ] = tmp;
    }

    // Standard Hoare's partition scheme function, used for both
    // QuickSort and QuickSelect.
    //
    function QSort_partition( 
            FinalScore[] memory list, 
            int lo, int hi )
                                                        internal pure
    returns( int newPivotIndex )
    {
        uint64 pivot = list[ uint( hi + lo ) / 2 ].score;
        int i = lo - 1;
        int j = hi + 1;

        while( true ) 
        {
            do {
                i++;
            } while( list[ uint( i ) ].score > pivot ) ;

            do {
                j--;
            } while( list[ uint( j ) ].score < pivot ) ;

            if( i >= j )
                return j;

            QSort_swap( list, uint( i ), uint( j ) );
        }
    }

    // QuickSelect's Lomuto partition scheme.
    //
    function QSort_LomutoPartition(
            FinalScore[] memory list,
            uint left, uint right, uint pivotIndex )
                                                        internal pure
    returns( uint newPivotIndex )
    {
        uint pivotValue = list[ pivotIndex ].score;
        QSort_swap( list, pivotIndex, right );  // Move pivot to end
        uint storeIndex = left;
        
        for( uint i = left; i < right; i++ )
        {
            if( list[ i ].score > pivotValue ) {
                QSort_swap( list, storeIndex, i );
                storeIndex++;
            }
        }

        // Move pivot to its final place, and return the pivot's index.
        QSort_swap( list, right, storeIndex );
        return storeIndex;
    }

    // QuickSelect algorithm (iterative).
    //
    function QSort_QuickSelect(
            FinalScore[] memory list,
            int left, int right, int k )
                                                        internal pure
    returns( int indexOfK )
    {
        while( true ) {
            if( left == right )
                return left;

            int pivotIndex = int( QSort_LomutoPartition( list, 
                    uint(left), uint(right), uint(right) ) );

            if( k == pivotIndex )
                return k;
            else if( k < pivotIndex )
                right = pivotIndex - 1;
            else
                left = pivotIndex + 1;
        }
    }

    // Standard QuickSort function.
    //
    function QSort_QuickSort(
            FinalScore[] memory list,
            int lo, int hi )
                                                        internal pure
    {
        if( lo < hi ) {
            int p = QSort_partition( list, lo, hi );
            QSort_QuickSort( list, lo, p );
            QSort_QuickSort( list, p + 1, hi );
        }
    }

    // ============== [ END ]   LOTTERY QUICKSORT FUNCTIONS ============== //

    // ------------ Ending Stage - Winner Selection Algorithm ------------ //

    /**
     *  Compute the individual player score factors for a holder.
     *  Function split from the below one (ending_Stage_2), to avoid
     *  "Stack too Deep" errors.
     */
    function computeHolderIndividualScores( 
            WinnerAlgorithmConfig memory cfg,
            MinMaxHolderScores memory minMax,
            HolderData memory hdata )
                                                        internal pure
    returns( int individualScore )
    {
        // Normalize the scores, by subtracting minimum and dividing
        // by maximum, to get the score values specified in cfg.
        // Use precision of 100, then round.
        //
        // Notice that we're using int arithmetics, so division 
        // truncates. That's why we use PRECISION, to simulate
        // rounding.
        //
        // This formula is better explained in example.
        // In this example, we use variable abbreviations defined
        // below, on formula's right side comments.
        //
        // Say, values are these in our example:
        // e = 4, eMin = 1, eMax = 8, MS = 5, P = 10.
        //
        // So, let's calculate the score using the formula:
        // ( ( ( (4 - 1) * 10 * 5 ) / (8 - 1) ) + (10 / 2) ) / 10 =
        // ( ( (    3    * 10 * 5 ) /    7    ) +     5    ) / 10 =
        // ( (         150          /    7    ) +     5    ) / 10 =
        // ( (         150          /    7    ) +     5    ) / 10 =
        // (                    20              +     5    ) / 10 =
        //                          25                       / 10 =
        //                        [ 2.5 ]                         = 2
        //
        // So, with truncation, we see that for e = 4, the score
        // is 2 out of 5 maximum.
        // That's because the minimum ether contributed was 1, and
        // maximum was 8.
        // So, 4 stays below the middle, and gets a nicely rounded 
        // score of 2.

        // Compute etherContributed.
        int score_etherContributed = ( (
            ( ( hdata.etherContributed -                            // e
                minMax.holderScore_etherContributed_min )           // eMin
              * PRECISION * cfg.maxPlayerScore_etherContributed )   // P * MS
            / ( minMax.holderScore_etherContributed_max -           // eMax
                minMax.holderScore_etherContributed_min )           // eMin
        ) + (PRECISION / 2) ) / PRECISION;

        // Compute timeFactors.
        int score_timeFactors = ( (
            ( ( hdata.timeFactors -                             // e
                minMax.holderScore_timeFactors_min )            // eMin
              * PRECISION * cfg.maxPlayerScore_timeFactor )     // P * MS
            / ( minMax.holderScore_timeFactors_max -            // eMax
                minMax.holderScore_timeFactors_min )            // eMin
        ) + (PRECISION / 2) ) / PRECISION;

        // Compute tokenBalance.
        int score_tokenBalance = ( (
            ( ( hdata.tokenBalance -                                 // e
                minMax.holderScore_tokenBalance_min )                // eMin
              * PRECISION * cfg.maxPlayerScore_tokenHoldingAmount )
            / ( minMax.holderScore_tokenBalance_max -                // eMax
                minMax.holderScore_tokenBalance_min )                // eMin
        ) + (PRECISION / 2) ) / PRECISION;

        // Return the accumulated individual score (excluding referrees).
        return score_etherContributed + score_timeFactors +
               score_tokenBalance;
    }


    /**
     *  Split-function, to avoid "Stack-2-Deep" errors.
     *  Computes a single component of a Referree Score.
     */
    /*function priv_computeSingleReferreeComponent(
            int _referreeScore_,
            int _maxPlayerScore_,
            int _holderScore_min_x_refCount,
            int _holderScore_max_x_refCount )
                                                        internal pure
    returns( int score )
    {
        score = (
            ( PRECISION * _maxPlayerScore_ * 
              ( _referreeScore_ - _holderScore_min_x_refCount ) )
            /
            ( _holderScore_max_x_refCount - _holderScore_min_x_refCount )
        );
    }*/

    /**
     *  Compute the unified Referree-Score of a player, who's got
     *  the accumulated factor-scores of all his referrees in his 
     *  holderData structure.
     *
     *  @param individualToReferralRatio - an int value, computed 
     *      before starting the winner score computation loop, in 
     *      the ending_Stage_2 initial part, to save computation
     *      time later.
     *      This is the ratio of the maximum available referral score,
     *      to the maximum available individual score, as defined in
     *      the config (for example, if max.ref.score is 20, and 
     *      max.ind.score is 40, then the ratio is 20/40 = 0.5).
     *      
     *      We use this ratio to transform the computed accumulated
     *      referree individual scores to the standard referrer's
     *      score, by multiplying by that ratio.
     */
    function computeReferreeScoresForHolder( 
            int individualToReferralRatio,
            WinnerAlgorithmConfig memory cfg,
            MinMaxHolderScores memory minMax,
            HolderData memory hdata )
                                                        internal pure
    returns( int unifiedReferreeScore )
    {
        // If number of referrees of this HODLer is Zero, then
        // his referree score is also zero.
        if( hdata.referreeCount == 0 )
            return 0;

        // Now, compute the Referree's Accumulated Scores.
        //
        // Here we use the same formula as when computing individual
        // scores (in the function above), but we multiply the
        // Min & Max known score value by the referree count, because
        // the "referree_..." scores are accumulated scores of all
        // referrees that that holder has.
        // This way, we reach the uniform averaged score of all referrees,
        // just like we do with individual scores.
        //
        // Also, we don't divide them by PRECISION, to accumulate and use
        // the max-score-options in the main score computing function.

        int refCount = int( hdata.referreeCount );

        // Compute etherContributed.
        int referreeScore_etherContributed = (
            ( ( hdata.referree_etherContributed -
                minMax.holderScore_etherContributed_min * refCount )
              * PRECISION * cfg.maxPlayerScore_etherContributed )
            / ( minMax.holderScore_etherContributed_max * refCount -
                minMax.holderScore_etherContributed_min * refCount )
        );

        // Compute timeFactors.
        int referreeScore_timeFactors = (
            ( ( hdata.referree_timeFactors -
                minMax.holderScore_timeFactors_min * refCount )
              * PRECISION * cfg.maxPlayerScore_timeFactor )
            / ( minMax.holderScore_timeFactors_max * refCount -
                minMax.holderScore_timeFactors_min * refCount )
        );

        // Compute tokenBalance.
        int referreeScore_tokenBalance = (
            ( ( hdata.referree_tokenBalance -
                minMax.holderScore_tokenBalance_min * refCount )
              * PRECISION * cfg.maxPlayerScore_tokenHoldingAmount )
            / ( minMax.holderScore_tokenBalance_max * refCount -
                minMax.holderScore_tokenBalance_min * refCount )
        );


        // Accumulate 'em all !
        // Then, multiply it by the ratio of all individual max scores
        // (maxPlayerScore_etherContributed, timeFactor, tokenBalance),
        // to the maxPlayerScore_refferalBonus.
        // Use the same precision.
        unifiedReferreeScore = int( ( (
                ( ( referreeScore_etherContributed +
                    referreeScore_timeFactors +
                    referreeScore_tokenBalance ) + (PRECISION / 2)
                ) / PRECISION
            ) * individualToReferralRatio
        ) / PRECISION );
    }


    // =================== PUBLIC FUNCTIONS =================== //


    /**
     *  Update current holder's score with given change values, and
     *  Propagate the holder's current transfer's score changes
     *  through the referral chain, updating every parent referrer's
     *  accumulated referree scores, until the ROOT_REFERRER or zero
     *  address referrer is encountered.
     */
    function updateAndPropagateScoreChanges(
            address holder,
            int80 etherContributed_change,
            int80 timeFactors_change,
            int80 tokenBalance_change )
                                                        public
                                                        lotteryOnly
    {
        // Update current holder's score.
        holderData[ holder ].etherContributed += etherContributed_change;
        holderData[ holder ].timeFactors += timeFactors_change;
        holderData[ holder ].tokenBalance += tokenBalance_change;

        // Check if scores are exceeding current min/max scores, 
        // and if so, update the min/max scores.

        // etherContributed:
        if( holderData[ holder ].etherContributed > 
            minMaxScores.holderScore_etherContributed_max )
            minMaxScores.holderScore_etherContributed_max = 
                holderData[ holder ].etherContributed;

        if( holderData[ holder ].etherContributed <
            minMaxScores.holderScore_etherContributed_min )
            minMaxScores.holderScore_etherContributed_min = 
                holderData[ holder ].etherContributed;

        // timeFactors:
        if( holderData[ holder ].timeFactors > 
            minMaxScores.holderScore_timeFactors_max )
            minMaxScores.holderScore_timeFactors_max = 
                holderData[ holder ].timeFactors;

        if( holderData[ holder ].timeFactors <
            minMaxScores.holderScore_timeFactors_min )
            minMaxScores.holderScore_timeFactors_min = 
                holderData[ holder ].timeFactors;

        // tokenBalance:
        if( holderData[ holder ].tokenBalance > 
            minMaxScores.holderScore_tokenBalance_max )
            minMaxScores.holderScore_tokenBalance_max = 
                holderData[ holder ].tokenBalance;

        if( holderData[ holder ].tokenBalance <
            minMaxScores.holderScore_tokenBalance_min )
            minMaxScores.holderScore_tokenBalance_min = 
                holderData[ holder ].tokenBalance;


        // Propagate the score through the referral chain.
        // Dive at maximum to the depth of 10, to avoid "Outta Gas"
        // errors.
        uint MAX_REFERRAL_DEPTH = 10;

        uint depth = 0;
        address referrerAddr = holderData[ holder ].referrer;

        while( referrerAddr != ROOT_REFERRER && 
               referrerAddr != address( 0 )  &&
               depth < MAX_REFERRAL_DEPTH )
        {
            // Update this referrer's accumulated referree scores.
            holderData[ referrerAddr ].referree_etherContributed +=
                etherContributed_change;

            holderData[ referrerAddr ].referree_timeFactors +=
                timeFactors_change;

            holderData[ referrerAddr ].referree_tokenBalance +=
                tokenBalance_change;

            // Move to the higher-level referrer.
            referrerAddr = holderData[ referrerAddr ].referrer;
            depth++;
        }
    }


    /** 
     *  Function executes the Lottery Winner Selection Algorithm,
     *  and writes the final, sorted array, containing winner rankings.
     *
     *  This function is called from the Lottery's Mining Stage Step 2,
     *
     *  This is the final function that lottery performs actively - 
     *  and arguably the most important - because it determines 
     *  lottery winners through Winner Selection Algorithm.
     *
     *  The random seed must be already set, before calling this function.
     */
    function executeWinnerSelectionAlgorithm()
                                                        public
                                                        lotteryOnly
    {
        // Copy the Winner Algo Config into memory, to avoid using
        // 400-gas costing SLOAD every time we need to load something.
        WinnerAlgorithmConfig memory cfg = algConfig;

        // Can only be performed if algorithm is MinedWinnerSelection!
        require( cfg.endingAlgoType ==
                 uint8(Lottery.EndingAlgoType.MinedWinnerSelection) );

        // Now, we gotta find the winners using a Randomized Score-Based
        // Winner Selection Algorithm.
        //
        // During transfers, all player intermediate scores 
        // (etherContributed, timeFactors, and tokenBalances) were
        // already set in every holder's HolderData structure,
        // during operations of updateHolderData_preTransfer() function.
        //
        // Minimum and maximum values are also known, so normalization
        // will be easy.
        // All referral tree score data were also properly propagated
        // during operations of updateAndPropagateScoreChanges() function.
        //
        // All we now have to do, is loop through holder array, and
        // compute randomized final scores for every holder, into
        // the Final Score array.

        // Declare the Final Score array - computed for all holders.
        uint ARRLEN = 
            ( holders.length > MINEDSELECTION_MAX_NUMBER_OF_HOLDERS ?
              MINEDSELECTION_MAX_NUMBER_OF_HOLDERS : holders.length );

        FinalScore[] memory finalScores = new FinalScore[] ( ARRLEN );

        // Compute the precision-adjusted constant ratio of 
        // referralBonus max score to the player individual max scores.

        int individualToReferralRatio = 
            ( PRECISION * cfg.maxPlayerScore_refferalBonus ) /
            ( int( cfg.maxPlayerScore_etherContributed ) + 
              int( cfg.maxPlayerScore_timeFactor ) +
              int( cfg.maxPlayerScore_tokenHoldingAmount ) );

        // Max available player score.
        int maxAvailablePlayerScore = int(
                cfg.maxPlayerScore_etherContributed + 
                cfg.maxPlayerScore_timeFactor +
                cfg.maxPlayerScore_tokenHoldingAmount +
                cfg.maxPlayerScore_refferalBonus );


        // Random Factor of scores, to maintain random-to-determined
        // ratio equal to specific value (1:5 for example - 
        // "randPart" == 5, "scorePart" == 1).
        //
        // maxAvailablePlayerScore * FACT   ---   scorePart
        // RANDOM_MODULO                    ---   randPart
        //
        //                                  RANDOM_MODULO * scorePart
        // maxAvailablePlayerScore * FACT = -------------------------
        //                                          randPart
        //
        //              RANDOM_MODULO * scorePart
        // FACT = --------------------------------------
        //          randPart * maxAvailablePlayerScore

        int SCORE_RAND_FACT =
            ( PRECISION * int(RANDOM_MODULO * cfg.randRatio_scorePart) ) /
            ( int(cfg.randRatio_randPart) * maxAvailablePlayerScore );


        // Fix Min-Max scores, to avoid division by zero, if min == max.
        // If min == max, make the difference equal to 1.
        MinMaxHolderScores memory minMaxCpy = minMaxScores;

        if( minMaxCpy.holderScore_etherContributed_min ==
            minMaxCpy.holderScore_etherContributed_max )
            minMaxCpy.holderScore_etherContributed_max =
            minMaxCpy.holderScore_etherContributed_min + 1;

        if( minMaxCpy.holderScore_timeFactors_min ==
            minMaxCpy.holderScore_timeFactors_max )
            minMaxCpy.holderScore_timeFactors_max =
            minMaxCpy.holderScore_timeFactors_min + 1;

        if( minMaxCpy.holderScore_tokenBalance_min ==
            minMaxCpy.holderScore_tokenBalance_max )
            minMaxCpy.holderScore_tokenBalance_max =
            minMaxCpy.holderScore_tokenBalance_min + 1;


        // Loop through all the holders.
        for( uint i = 0; i < ARRLEN; i++ )
        {
            // Fetch the needed holder data to in-memory hdata variable,
            // to save gas on score part computing functions.
            HolderData memory hdata;

            // Slot 1:
            hdata.etherContributed =
                holderData[ holders[ i ] ].etherContributed;
            hdata.timeFactors =
                holderData[ holders[ i ] ].timeFactors;
            hdata.tokenBalance =
                holderData[ holders[ i ] ].tokenBalance;
            hdata.referreeCount =
                holderData[ holders[ i ] ].referreeCount;

            // Slot 2:
            hdata.referree_etherContributed =
                holderData[ holders[ i ] ].referree_etherContributed;
            hdata.referree_timeFactors =
                holderData[ holders[ i ] ].referree_timeFactors;
            hdata.referree_tokenBalance =
                holderData[ holders[ i ] ].referree_tokenBalance;
            hdata.bonusScore =
                holderData[ holders[ i ] ].bonusScore;


            // Now, add bonus score, and compute total player's score:
            // Bonus part, individual score part, and referree score part.
            int totalPlayerScore = 
                    hdata.bonusScore
                    +
                    computeHolderIndividualScores(
                        cfg, minMaxCpy, hdata )
                    +
                    computeReferreeScoresForHolder( 
                        individualToReferralRatio, cfg, 
                        minMaxCpy, hdata );


            // Check if total player score <= 0. If so, make it equal
            // to 1, because otherwise randomization won't be possible.
            if( totalPlayerScore <= 0 )
                totalPlayerScore = 1;

            // Now, check if it's not more than max! If so, lowerify.
            // This could have happen'd because of bonus.
            if( totalPlayerScore > maxAvailablePlayerScore )
                totalPlayerScore = maxAvailablePlayerScore;


            // Multiply the score by the Random Modulo Adjustment
            // Factor, to get fairer ratio of random-to-determined data.
            totalPlayerScore =  ( totalPlayerScore * SCORE_RAND_FACT ) /
                                ( PRECISION );

            // Score is computed!
            // Now, randomize it, and add to Final Scores Array.
            // We use keccak to generate a random number from random seed,
            // using holder's address as a nonce.

            uint modulizedRandomNumber = uint(
                keccak256( abi.encodePacked( randomSeed, holders[ i ] ) )
            ) % RANDOM_MODULO;

            // Add the random number, to introduce the random factor.
            // Ratio of (current) totalPlayerScore to modulizedRandomNumber
            // is the same as ratio of randRatio_scorePart to 
            // randRatio_randPart.

            uint endScore = uint( totalPlayerScore ) + modulizedRandomNumber;

            // Finally, set this holder's final score data.
            finalScores[ i ].addr = holders[ i ];
            finalScores[ i ].holderIndex = uint16( i );
            finalScores[ i ].score = uint64( endScore );
        }

        // All final scores are now computed.
        // Sort the array, to find out the highest scores!

        // Firstly, partition an array to only work on top K scores,
        // where K is the number of winners.
        // There can be a rare case where specified number of winners is
        // more than lottery token holders. We got that covered.

        require( finalScores.length > 0 );

        uint K = cfg.winnerCount - 1;
        if( K > finalScores.length-1 )
            K = finalScores.length-1;   // Must be THE LAST ELEMENT's INDEX.

        // Use QuickSelect to do this.
        QSort_QuickSelect( finalScores, 0, 
            int( finalScores.length - 1 ), int( K ) );

        // Now, QuickSort only the first K items, because the rest
        // item scores are not high enough to become winners.
        QSort_QuickSort( finalScores, 0, int( K ) );

        // Now, the winner array is sorted, with the highest scores
        // sitting at the first positions!
        // Let's set up the winner indexes array, where we'll store
        // the winners' indexes in the holders array.
        // So, if this array is [8, 2, 3], that means that
        // Winner #1 is holders[8], winner #2 is holders[2], and
        // winner #3 is holders[3].

        // Set the Number Of Winners variable.
        numberOfWinners = uint16( K + 1 );

        // Now, we can loop through the first numberOfWinners elements, to set
        // the holder indexes!
        // Loop through 16 elements at a time, to fill the structs.
        for( uint offset = 0; offset < numberOfWinners; offset += 16 )
        {
            WinnerIndexStruct memory windStruct;
            uint loopStop = ( offset + 16 > numberOfWinners ?
                              numberOfWinners : offset + 16 );

            for( uint i = offset; i < loopStop; i++ )
            {
                windStruct.indexes[ i - offset ] =finalScores[ i ].holderIndex;
            }

            // Push this now-filled struct to the storage array!
            sortedWinnerIndexes.push( windStruct );
        }

        // That's it! We're done!
        algorithmCompleted = true;
    }


    /**
     *  Add a holder to holders array.
     *  @param holder   - address of a holder to add.
     */
    function addHolder( address holder )
                                                        public
                                                        lotteryOnly
    {
        // Add it to list, and set index in the mapping.
        holders.push( holder );
        holderIndexes[ holder ] = holders.length - 1;
    }

    /**
     *  Removes the holder 'sender' from the Holders Array.
     *  However, this holder's HolderData structure persists!
     *
     *  Notice that no index validity checks are performed, so, if
     *  'sender' is not present in "holderIndexes" mapping, this
     *  function will remove the 0th holder instead!
     *  This is not a problem for us, because Lottery calls this
     *  function only when it's absolutely certain that 'sender' is
     *  present in the holders array.
     *
     *  @param sender   - address of a holder to remove.
     *      Named 'sender', because when token sender sends away all
     *      his tokens, he must then be removed from holders array.
     */
    function removeHolder( address sender )
                                                        public
                                                        lotteryOnly
    {
        // Get index of the sender address in the holders array.
        uint index = holderIndexes[ sender ];

        // Remove the sender from array, by copying last element's
        // value into the index'th element, where sender was before.
        holders[ index ] = holders[ holders.length - 1 ];

        // Remove the last element of array, which we've just copied.
        holders.pop();

        // Update indexes: remove the sender's index from the mapping,
        // and change the previoulsy-last element's index to the
        // one where we copied it - where sender was before.
        delete holderIndexes[ sender ];
        holderIndexes[ holders[ index ] ] = index;
    }


    /**
     *  Get holder array length.
     */
    function getHolderCount()
                                                    public view
    returns( uint )
    {
        return holders.length;
    }


    /**
     *  Generate a referral ID for a token holder.
     *  Referral ID is used to refer other wallets into playing our
     *  lottery.
     *  - Referrer gets bonus points for every wallet that bought 
     *    lottery tokens and specified his referral ID.
     *  - Referrees (wallets who got referred by registering a valid
     *    referral ID, corresponding to some referrer), get some
     *    bonus points for specifying (registering) a referral ID.
     *
     *  Referral ID is a uint256 number, which is generated by
     *  keccak256'ing the holder's address, holder's current
     *  token ballance, and current time.
     */
    function generateReferralID( address holder )
                                                            public
                                                            lotteryOnly
    returns( uint256 referralID )
    {
        // Check if holder has some tokens, and doesn't
        // have his own referral ID yet.
        require( holderData[ holder ].tokenBalance != 0 );

        require( holderData[ holder ].referralID == 0 );

        // Generate a referral ID with keccak.
        uint256 refID = uint256( keccak256( abi.encodePacked( 
                holder, holderData[ holder ].tokenBalance, now ) ) );

        // Specify the ID as current ID of this holder.
        holderData[ holder ].referralID = refID;

        // If this holder wasn't referred by anyone (his referrer is
        // not set), and he's now generated his own ID, he won't
        // be able to register as a referree of someone else 
        // from now on.
        // This is done to prevent circular dependency in referrals.
        // Do it by setting a referrer to ROOT_REFERRER address,
        // which is an invalid address (address(1)).
        if( holderData[ holder ].referrer == address( 0 ) )
            holderData[ holder ].referrer = ROOT_REFERRER;

        // Create a new referrer with this ID.
        referrers[ refID ] = holder;
        
        return refID;
    }


    /**
     *  Register a referral for a token holder, using a valid
     *  referral ID got from a referrer.
     *  This function is called by a referree, who obtained a
     *  valid referral ID from some referrer, who previously
     *  generated it using generateReferralID().
     *
     *  You can only register a referral once!
     *  When you do so, you get bonus referral points!
     */
    function registerReferral(
            address holder,
            int16 referralRegisteringBonus,
            uint256 referralID )
                                                            public
                                                            lotteryOnly
    returns( address _referrerAddress )
    {
        // Check if this holder has some tokens, and if he hasn't
        // registered a referral yet.
        require( holderData[ holder ].tokenBalance != 0 );

        require( holderData[ holder ].referrer == address( 0 ) );

        // Get the referrer's address from his ID, and specify
        // it as a referrer of holder.
        holderData[ holder ].referrer = referrers[ referralID ];

        // Bonus points are added to this holder's score for
        // registering a referral!
        holderData[ holder ].bonusScore = referralRegisteringBonus;

        // Increment number of referrees for every parent referrer,
        // by traversing a referral tree child->parent way.
        address referrerAddr = holderData[ holder ].referrer;

        // Set the return value.
        _referrerAddress = referrerAddr;

        // Traverse a tree.
        while( referrerAddr != ROOT_REFERRER && 
               referrerAddr != address( 0 ) )
        {
            // Increment referree count for this referrrer.
            holderData[ referrerAddr ].referreeCount++;

            // Update the Referrer Scores of the referrer, adding this
            // referree's scores to it's current values.
            holderData[ referrerAddr ].referree_etherContributed +=
                holderData[ holder ].etherContributed;

            holderData[ referrerAddr ].referree_timeFactors +=
                holderData[ holder ].timeFactors;

            holderData[ referrerAddr ].referree_tokenBalance +=
                holderData[ holder ].tokenBalance;

            // Move to the higher-level referrer.
            referrerAddr = holderData[ referrerAddr ].referrer;
        }

        return _referrerAddress;
    }


    /**
     *  Sets our random seed to some value.
     *  Should be called from Lottery, after obtaining random seed from
     *  the Randomness Provider.
     */
    function setRandomSeed( uint _seed )
                                                    external
                                                    lotteryOnly
    {
        randomSeed = uint64( _seed );
    }


    /**
     *  Initialization function.
     *  Here, we bind our contract to the Lottery contract that 
     *  this Storage belongs to.
     *  The parent lottery must call this function - hence, we set
     *  "lottery" to msg.sender.
     *
     *  When this function is called, our contract must be not yet
     *  initialized - "lottery" address must be Zero!
     *
     *  Here, we also set our Winner Algorithm config, which is a
     *  subset of LotteryConfig, fitting into 1 storage slot.
     */
    function initialize(
            WinnerAlgorithmConfig memory _wcfg )
                                                        public
    {
        require( address( lottery ) == address( 0 ) );

        // Set the Lottery address (msg.sender can't be zero),
        // and thus, set our contract to initialized!
        lottery = msg.sender;

        // Set the Winner-Algo-Config.
        algConfig = _wcfg;

        // NOT-NEEDED: Set initial min-max scores: min is INT_MAX.
        /*minMaxScores.holderScore_etherContributed_min = int80( 2 ** 78 );
        minMaxScores.holderScore_timeFactors_min    = int80( 2 ** 78 );
        minMaxScores.holderScore_tokenBalance_min   = int80( 2 ** 78 );
        */
    }


    // ==================== Views ==================== //


    // Returns the current random seed.
    // If the seed hasn't been set yet (or set to 0), returns 0.
    //
    function getRandomSeed()
                                                    external view
    returns( uint )
    {
        return randomSeed;
    }


    // Check if Winner Selection Algorithm has beed executed.
    //
    function minedSelection_algorithmAlreadyExecuted()
                                                        external view
    returns( bool )
    {
        return algorithmCompleted;
    }

    /**
     *  After lottery has completed, this function returns if "addr"
     *  is one of lottery winners, and the position in winner rankings.
     *  Function is used to obtain the ranking position before
     *  calling claimWinnerPrize() on Lottery.
     *
     *  This function should be called off-chain, and then using the
     *  retrieved data, one can call claimWinnerPrize().
     */
    function minedSelection_getWinnerStatus(
            address addr )
                                                        public view
    returns( bool isWinner, 
             uint32 rankingPosition )
    {
        // Loop through the whole winner indexes array, trying to
        // find if "addr" is one of the winner addresses.
        for( uint16 i = 0; i < numberOfWinners; i++ )
        {
            // Check if holder on this winner ranking's index position
            // is addr, if so, good!
            uint pos = sortedWinnerIndexes[ i / 16 ].indexes[ i % 16 ];

            if( holders[ pos ] == addr )
            {
                return ( true, i );
            }
        }

        // The "addr" is not a winner.
        return ( false, 0 );
    }

    /**
     *  Checks if address is on specified winner ranking position.
     *  Used in Lottery, to check if msg.sender is really the 
     *  winner #rankingPosition, as he claims to be.
     */
    function minedSelection_isAddressOnWinnerPosition( 
            address addr,
            uint32  rankingPosition )
                                                    external view
    returns( bool )
    {
        if( rankingPosition >= numberOfWinners )
            return false;

        // Just check if address at "holders" array 
        // index "sortedWinnerIndexes[ position ]" is really the "addr".
        uint pos = sortedWinnerIndexes[ rankingPosition / 16 ]
                    .indexes[ rankingPosition % 16 ];

        return ( holders[ pos ] == addr );
    }


    /**
     *  Returns an array of all winner addresses, sorted by their
     *  ranking position (winner #1 first, #2 second, etc.).
     */
    function minedSelection_getAllWinners()
                                                    external view
    returns( address[] memory )
    {
        address[] memory winners = new address[] ( numberOfWinners );

        for( uint i = 0; i < numberOfWinners; i++ )
        {
            uint pos = sortedWinnerIndexes[ i / 16 ].indexes[ i % 16 ];
            winners[ i ] = holders[ pos ];
        }

        return winners;
    }


    /**
     *  Compute the Lottery Active Stage Score of a token holder.
     *
     *  This function computes the Active Stage (pre-randomization)
     *  player score, and should generally be used to compute player
     *  intermediate scores - while lottery is still active or on
     *  finishing stage, before random random seed is obtained.
     */
    function getPlayerActiveStageScore( address holderAddr )
                                                            external view
    returns( uint playerScore )
    {
        // Copy the Winner Algo Config into memory, to avoid using
        // 400-gas costing SLOAD every time we need to load something.
        WinnerAlgorithmConfig memory cfg = algConfig;

        // Check if holderAddr is a holder at all!
        if( holders[ holderIndexes[ holderAddr ] ] != holderAddr )
            return 0;

        // Compute the precision-adjusted constant ratio of 
        // referralBonus max score to the player individual max scores.

        int individualToReferralRatio = 
            ( PRECISION * cfg.maxPlayerScore_refferalBonus ) /
            ( int( cfg.maxPlayerScore_etherContributed ) + 
              int( cfg.maxPlayerScore_timeFactor ) +
              int( cfg.maxPlayerScore_tokenHoldingAmount ) );

        // Max available player score.
        int maxAvailablePlayerScore = int(
                cfg.maxPlayerScore_etherContributed + 
                cfg.maxPlayerScore_timeFactor +
                cfg.maxPlayerScore_tokenHoldingAmount +
                cfg.maxPlayerScore_refferalBonus );

        // Fix Min-Max scores, to avoid division by zero, if min == max.
        // If min == max, make the difference equal to 1.
        MinMaxHolderScores memory minMaxCpy = minMaxScores;

        if( minMaxCpy.holderScore_etherContributed_min ==
            minMaxCpy.holderScore_etherContributed_max )
            minMaxCpy.holderScore_etherContributed_max =
            minMaxCpy.holderScore_etherContributed_min + 1;

        if( minMaxCpy.holderScore_timeFactors_min ==
            minMaxCpy.holderScore_timeFactors_max )
            minMaxCpy.holderScore_timeFactors_max =
            minMaxCpy.holderScore_timeFactors_min + 1;

        if( minMaxCpy.holderScore_tokenBalance_min ==
            minMaxCpy.holderScore_tokenBalance_max )
            minMaxCpy.holderScore_tokenBalance_max =
            minMaxCpy.holderScore_tokenBalance_min + 1;


        // Now, add bonus score, and compute total player's score:
        // Bonus part, individual score part, and referree score part.
        int totalPlayerScore = 
                holderData[ holderAddr ].bonusScore
                +
                computeHolderIndividualScores(
                    cfg, minMaxCpy, holderData[ holderAddr ] )
                +
                computeReferreeScoresForHolder( 
                    individualToReferralRatio, cfg, 
                    minMaxCpy, holderData[ holderAddr ] );


        // Check if total player score <= 0. If so, make it equal
        // to 1, because otherwise randomization won't be possible.
        if( totalPlayerScore <= 0 )
            totalPlayerScore = 1;

        // Now, check if it's not more than max! If so, lowerify.
        // This could have happen'd because of bonus.
        if( totalPlayerScore > maxAvailablePlayerScore )
            totalPlayerScore = maxAvailablePlayerScore;

        // Return the score!
        return uint( totalPlayerScore );
    }



    /**
     *  Internal sub-procedure of the function below, used to obtain
     *  a final, randomized score of a Single Holder.
     */
    function priv_getSingleHolderScore(
            address hold3r,
            int individualToReferralRatio,
            int maxAvailablePlayerScore,
            int SCORE_RAND_FACT,
            WinnerAlgorithmConfig memory cfg,
            MinMaxHolderScores memory minMaxCpy )
                                                        internal view
    returns( uint endScore )
    {
        // Fetch the needed holder data to in-memory hdata variable,
        // to save gas on score part computing functions.
        HolderData memory hdata;

        // Slot 1:
        hdata.etherContributed =
            holderData[ hold3r ].etherContributed;
        hdata.timeFactors =
            holderData[ hold3r ].timeFactors;
        hdata.tokenBalance =
            holderData[ hold3r ].tokenBalance;
        hdata.referreeCount =
            holderData[ hold3r ].referreeCount;

        // Slot 2:
        hdata.referree_etherContributed =
            holderData[ hold3r ].referree_etherContributed;
        hdata.referree_timeFactors =
            holderData[ hold3r ].referree_timeFactors;
        hdata.referree_tokenBalance =
            holderData[ hold3r ].referree_tokenBalance;
        hdata.bonusScore =
            holderData[ hold3r ].bonusScore;


        // Now, add bonus score, and compute total player's score:
        // Bonus part, individual score part, and referree score part.
        int totalPlayerScore = 
                hdata.bonusScore
                +
                computeHolderIndividualScores(
                    cfg, minMaxCpy, hdata )
                +
                computeReferreeScoresForHolder( 
                    individualToReferralRatio, cfg, 
                    minMaxCpy, hdata );


        // Check if total player score <= 0. If so, make it equal
        // to 1, because otherwise randomization won't be possible.
        if( totalPlayerScore <= 0 )
            totalPlayerScore = 1;

        // Now, check if it's not more than max! If so, lowerify.
        // This could have happen'd because of bonus.
        if( totalPlayerScore > maxAvailablePlayerScore )
            totalPlayerScore = maxAvailablePlayerScore;


        // Multiply the score by the Random Modulo Adjustment
        // Factor, to get fairer ratio of random-to-determined data.
        totalPlayerScore =  ( totalPlayerScore * SCORE_RAND_FACT ) /
                            ( PRECISION );

        // Score is computed!
        // Now, randomize it, and add to Final Scores Array.
        // We use keccak to generate a random number from random seed,
        // using holder's address as a nonce.

        uint modulizedRandomNumber = uint(
            keccak256( abi.encodePacked( randomSeed, hold3r ) )
        ) % RANDOM_MODULO;

        // Add the random number, to introduce the random factor.
        // Ratio of (current) totalPlayerScore to modulizedRandomNumber
        // is the same as ratio of randRatio_scorePart to 
        // randRatio_randPart.

        return uint( totalPlayerScore ) + modulizedRandomNumber;
    }


    /**
     *  Winner Self-Validation algo-type main function.
     *  Here, we compute scores for all lottery holders iteratively
     *  in O(n) time, and thus get the winner ranking position of
     *  the holder in question.
     *
     *  This function performs essentialy the same steps as the
     *  Mined-variant (executeWinnerSelectionAlgorithm), but doesn't
     *  write anything to blockchain.
     *
     *  @param holderAddr - address of a holder whose rank we want to find.
     */
    function winnerSelfValidation_getWinnerStatus(
            address holderAddr )
                                                        internal view
    returns( bool isWinner, uint rankingPosition )
    {
        // Copy the Winner Algo Config into memory, to avoid using
        // 400-gas costing SLOAD every time we need to load something.
        WinnerAlgorithmConfig memory cfg = algConfig;

        // Can only be performed if algorithm is WinnerSelfValidation!
        require( cfg.endingAlgoType ==
                 uint8(Lottery.EndingAlgoType.WinnerSelfValidation) );

        // Check if holderAddr is a holder at all!
        require( holders[ holderIndexes[ holderAddr ] ] == holderAddr );

        // Now, we gotta find the winners using a Randomized Score-Based
        // Winner Selection Algorithm.
        //
        // During transfers, all player intermediate scores 
        // (etherContributed, timeFactors, and tokenBalances) were
        // already set in every holder's HolderData structure,
        // during operations of updateHolderData_preTransfer() function.
        //
        // Minimum and maximum values are also known, so normalization
        // will be easy.
        // All referral tree score data were also properly propagated
        // during operations of updateAndPropagateScoreChanges() function.
        //
        // All we now have to do, is loop through holder array, and
        // compute randomized final scores for every holder.

        // Compute the precision-adjusted constant ratio of 
        // referralBonus max score to the player individual max scores.

        int individualToReferralRatio = 
            ( PRECISION * cfg.maxPlayerScore_refferalBonus ) /
            ( int( cfg.maxPlayerScore_etherContributed ) + 
              int( cfg.maxPlayerScore_timeFactor ) +
              int( cfg.maxPlayerScore_tokenHoldingAmount ) );

        // Max available player score.
        int maxAvailablePlayerScore = int(
                cfg.maxPlayerScore_etherContributed + 
                cfg.maxPlayerScore_timeFactor +
                cfg.maxPlayerScore_tokenHoldingAmount +
                cfg.maxPlayerScore_refferalBonus );


        // Random Factor of scores, to maintain random-to-determined
        // ratio equal to specific value (1:5 for example - 
        // "randPart" == 5, "scorePart" == 1).
        //
        // maxAvailablePlayerScore * FACT   ---   scorePart
        // RANDOM_MODULO                    ---   randPart
        //
        //                                  RANDOM_MODULO * scorePart
        // maxAvailablePlayerScore * FACT = -------------------------
        //                                          randPart
        //
        //              RANDOM_MODULO * scorePart
        // FACT = --------------------------------------
        //          randPart * maxAvailablePlayerScore

        int SCORE_RAND_FACT =
            ( PRECISION * int(RANDOM_MODULO * cfg.randRatio_scorePart) ) /
            ( int(cfg.randRatio_randPart) * maxAvailablePlayerScore );


        // Fix Min-Max scores, to avoid division by zero, if min == max.
        // If min == max, make the difference equal to 1.
        MinMaxHolderScores memory minMaxCpy = minMaxScores;

        if( minMaxCpy.holderScore_etherContributed_min ==
            minMaxCpy.holderScore_etherContributed_max )
            minMaxCpy.holderScore_etherContributed_max =
            minMaxCpy.holderScore_etherContributed_min + 1;

        if( minMaxCpy.holderScore_timeFactors_min ==
            minMaxCpy.holderScore_timeFactors_max )
            minMaxCpy.holderScore_timeFactors_max =
            minMaxCpy.holderScore_timeFactors_min + 1;

        if( minMaxCpy.holderScore_tokenBalance_min ==
            minMaxCpy.holderScore_tokenBalance_max )
            minMaxCpy.holderScore_tokenBalance_max =
            minMaxCpy.holderScore_tokenBalance_min + 1;


        // How many holders had higher scores than "holderAddr".
        // Used to obtain the final winner rank of "holderAddr".
        uint numOfHoldersHigherThan = 0;

        // The final (randomized) score of "holderAddr".
        uint holderAddrsFinalScore = priv_getSingleHolderScore(
            holderAddr,
            individualToReferralRatio,
            maxAvailablePlayerScore,
            SCORE_RAND_FACT,
            cfg, minMaxCpy );

        // Index of holderAddr.
        uint holderAddrIndex = holderIndexes[ holderAddr ];


        // Loop through all the allowed holders.
        for( uint i = 0; 
             i < ( holders.length < SELFVALIDATION_MAX_NUMBER_OF_HOLDERS ? 
                   holders.length : SELFVALIDATION_MAX_NUMBER_OF_HOLDERS );
             i++ )
        {
            // Skip the holderAddr's index.
            if( i == holderAddrIndex )
                continue;

            // Compute the score using helper function.
            uint endScore = priv_getSingleHolderScore(
                holders[ i ],
                individualToReferralRatio,
                maxAvailablePlayerScore,
                SCORE_RAND_FACT,
                cfg, minMaxCpy );

            // Check if score is higher than HolderAddr's, and if so, check.
            if( endScore > holderAddrsFinalScore )
                numOfHoldersHigherThan++;
        }

        // All scores are checked!
        // Now, we can obtain holderAddr's winner rank based on how
        // many scores were above holderAddr's score!

        isWinner = ( numOfHoldersHigherThan < cfg.winnerCount ); 
        rankingPosition = numOfHoldersHigherThan;
    }



    /**
     *  Rolled-Randomness algo-type main function.
     *  Here, we only compute the score of the holder in question,
     *  and compare it to maximum-available final score, divided
     *  by no-of-winners.
     *
     *  @param holderAddr - address of a holder whose rank we want to find.
     */
    function rolledRandomness_getWinnerStatus(
            address holderAddr )
                                                        internal view
    returns( bool isWinner, uint rankingPosition )
    {
        // Copy the Winner Algo Config into memory, to avoid using
        // 400-gas costing SLOAD every time we need to load something.
        WinnerAlgorithmConfig memory cfg = algConfig;

        // Can only be performed if algorithm is RolledRandomness!
        require( cfg.endingAlgoType ==
                 uint8(Lottery.EndingAlgoType.RolledRandomness) );

        // Check if holderAddr is a holder at all!
        require( holders[ holderIndexes[ holderAddr ] ] == holderAddr );

        // Now, we gotta find the winners using a Randomized Score-Based
        // Winner Selection Algorithm.
        //
        // During transfers, all player intermediate scores 
        // (etherContributed, timeFactors, and tokenBalances) were
        // already set in every holder's HolderData structure,
        // during operations of updateHolderData_preTransfer() function.
        //
        // Minimum and maximum values are also known, so normalization
        // will be easy.
        // All referral tree score data were also properly propagated
        // during operations of updateAndPropagateScoreChanges() function.
        //
        // All we now have to do, is loop through holder array, and
        // compute randomized final scores for every holder.

        // Compute the precision-adjusted constant ratio of 
        // referralBonus max score to the player individual max scores.

        int individualToReferralRatio = 
            ( PRECISION * cfg.maxPlayerScore_refferalBonus ) /
            ( int( cfg.maxPlayerScore_etherContributed ) + 
              int( cfg.maxPlayerScore_timeFactor ) +
              int( cfg.maxPlayerScore_tokenHoldingAmount ) );

        // Max available player score.
        int maxAvailablePlayerScore = int(
                cfg.maxPlayerScore_etherContributed + 
                cfg.maxPlayerScore_timeFactor +
                cfg.maxPlayerScore_tokenHoldingAmount +
                cfg.maxPlayerScore_refferalBonus );


        // Random Factor of scores, to maintain random-to-determined
        // ratio equal to specific value (1:5 for example - 
        // "randPart" == 5, "scorePart" == 1).
        //
        // maxAvailablePlayerScore * FACT   ---   scorePart
        // RANDOM_MODULO                    ---   randPart
        //
        //                                  RANDOM_MODULO * scorePart
        // maxAvailablePlayerScore * FACT = -------------------------
        //                                          randPart
        //
        //              RANDOM_MODULO * scorePart
        // FACT = --------------------------------------
        //          randPart * maxAvailablePlayerScore

        int SCORE_RAND_FACT =
            ( PRECISION * int(RANDOM_MODULO * cfg.randRatio_scorePart) ) /
            ( int(cfg.randRatio_randPart) * maxAvailablePlayerScore );


        // Fix Min-Max scores, to avoid division by zero, if min == max.
        // If min == max, make the difference equal to 1.
        MinMaxHolderScores memory minMaxCpy = minMaxScores;

        if( minMaxCpy.holderScore_etherContributed_min ==
            minMaxCpy.holderScore_etherContributed_max )
            minMaxCpy.holderScore_etherContributed_max =
            minMaxCpy.holderScore_etherContributed_min + 1;

        if( minMaxCpy.holderScore_timeFactors_min ==
            minMaxCpy.holderScore_timeFactors_max )
            minMaxCpy.holderScore_timeFactors_max =
            minMaxCpy.holderScore_timeFactors_min + 1;

        if( minMaxCpy.holderScore_tokenBalance_min ==
            minMaxCpy.holderScore_tokenBalance_max )
            minMaxCpy.holderScore_tokenBalance_max =
            minMaxCpy.holderScore_tokenBalance_min + 1;


        // The final (randomized) score of "holderAddr".
        uint holderAddrsFinalScore = priv_getSingleHolderScore(
            holderAddr,
            individualToReferralRatio,
            maxAvailablePlayerScore,
            SCORE_RAND_FACT,
            cfg, minMaxCpy );

        // Now, compute the Max-Final-Random Score, divide it
        // by the Holder Count, and get the ranking by placing this
        // holder's score in it's corresponding part.
        //
        // In this approach, we assume linear randomness distribution.
        // In practice, distribution might be a bit different, but this
        // approach is the most efficient.
        //
        // Max-Final-Score (randomized) is the highest available score
        // that can be achieved, and is made by adding together the
        // maximum availabe Player Score Part and maximum available
        // Random Part (equals RANDOM_MODULO).
        // These parts have a ratio equal to config-specified
        // randRatio_scorePart to randRatio_randPart.
        //
        // So, if player's active stage's score is low (1), but rand-part
        // in ratio is huge, then the score is mostly random, so 
        // maxFinalScore is close to the RANDOM_MODULO - maximum random
        // value that can be rolled.
        //
        // If, however, we use 1:1 playerScore-to-Random Ratio, then
        // playerScore and RandomScore make up equal parts of end score,
        // so the maxFinalScore is actually two times larger than
        // RANDOM_MODULO, so player needs to score more
        // player-points to get larger prizes.
        //
        // In default configuration, playerScore-to-random ratio is 1:3,
        // so there's a good randomness factor, so even the low-scoring
        // players can reasonably hope to get larger prizes, but
        // the higher is player's active stage score, the more
        // chances of scoring a high final score a player gets, with
        // the higher-end of player scores basically guaranteeing
        // themselves a specific prize amount, if winnerCount is
        // big enough to overlap.

        int maxRandomPart      = int( RANDOM_MODULO - 1 );
        int maxPlayerScorePart = ( SCORE_RAND_FACT * maxAvailablePlayerScore )
                                 / PRECISION;

        uint maxFinalScore = uint( maxRandomPart + maxPlayerScorePart );

        // Compute the amount that single-holder's virtual part
        // might take up in the max-final score.
        uint singleHolderPart = maxFinalScore / holders.length;

        // Now, compute how many single-holder-parts are there in
        // this holder's score.
        uint holderAddrScorePartCount = holderAddrsFinalScore /
                                        singleHolderPart;

        // The ranking is that number, minus holders length.
        // If very high score is scored, default to position 0 (highest).
        rankingPosition = (
            holderAddrScorePartCount < holders.length ?
            holders.length - holderAddrScorePartCount : 0
        );

        isWinner = ( rankingPosition < cfg.winnerCount );
    }


    /**
     *  Genericized, algorithm type-dependent getWinnerStatus function.
     */
    function getWinnerStatus(
            address addr )
                                                        external view
    returns( bool isWinner, uint32 rankingPosition )
    {
        bool _isW;
        uint _rp;

        if( algConfig.endingAlgoType == 
            uint8(Lottery.EndingAlgoType.RolledRandomness) )
        {
            (_isW, _rp) = rolledRandomness_getWinnerStatus( addr );
            return ( _isW, uint32( _rp ) );
        }

        if( algConfig.endingAlgoType ==
            uint8(Lottery.EndingAlgoType.WinnerSelfValidation) )
        {
            (_isW, _rp) = winnerSelfValidation_getWinnerStatus( addr );
            return ( _isW, uint32( _rp ) );
        }

        if( algConfig.endingAlgoType ==
            uint8(Lottery.EndingAlgoType.MinedWinnerSelection) )
        {
            (_isW, _rp) = minedSelection_getWinnerStatus( addr );
            return ( _isW, uint32( _rp ) );
        }
    }

}




