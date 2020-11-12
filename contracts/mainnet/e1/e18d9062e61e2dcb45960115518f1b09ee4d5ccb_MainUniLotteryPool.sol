// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.7.1;
pragma experimental ABIEncoderV2;

// Use OpenZeppelin ERC20 token implementation for Pool Token.
import "./ZeppelinERC20.sol";

// Import the Core UniLottery Settings, where core global constants
// are defined.
import "./CoreSettings.sol";

// The Uniswap Lottery Token implementation, where all lottery player
// interactions happen.
import "./MinedUniswapLottery.sol";

// Randomness provider, using Provable oracle service inside.
// We instantiate this provider only once here, and later, every
// lottery can use the provider services.
import "./RandomProvider.sol";

// Use a Lottery Factory to create new lotteries, without using
// "new" statements to deploy lotteries in the Pool, because that
// pattern makes the Pool's code size exdeed the 24 kB limit.
import "./LotteryFactory.sol";


/**
 *  UniLotteryPool version v0.1
 *
 *  This is the main UniLottery Pool DAO contract, which governs all 
 *  pool and lottery operations, and holds all poolholder funds.
 *  
 *  This contract uses ULPT tokens to track users share of the pool.
 *  Currently, this contract itself is an ULPT token - gas saving is
 *  a preference, given the current huge Ethereum gas fees, so better
 *  fit more inside a single contract.
 *
 *  This contract is responsible for launching new lotteries, 
 *  managing profits, and managing user fund contributions.
 *
 *  This is because the project is in early stage, and current version
 *  is by no means finalized. Some features will be implemented
 *  or decided not to be implemented later, after testing the concept
 *  with the initial version at first.
 *
 *  This version (v0.1) allows only basic pool functionality, targeted 
 *  mostly to the only-one-poolholder model, because most likely 
 *  only Owner is going to use this pool version.
 *
 *  =================================================
 *
 *  Who can transfer money to/from the pool?
 *
 *  There are 2 actors which could initiate money transfers:
 *  1. Pool shareholders - by providing/removing liquidity in
 *      exchange for ULPT.
 *  2. Lottery contracts - on start, pool provides them initial funds,
 *      and on finish, lottery returns initial funds + profits
 *      back to the pool.
 *
 *  -------------------------------------------------
 *
 *  In which functions the money transfers occur?
 *
 *  There are 4 functions which might transfer money to/from the pool:
 *
 *  1. [IN] The lotteryFinish() function. 
 *      Used by the finished lotteries to transfer initial funds 
 *      and profits back to the pool.
 *
 *  2. [IN] provideLiquidity() function. 
 *      Is called by users to provide ETH into the pool in exchange
 *      for ULPT pool share tokens - user become pool shareholders.
 *
 *  3. [OUT] removeLiquidity() function.
 *      Is called by users when they want to remove their liquidity
 *      share from the pool. ETH gets transfered from pool to 
 *      callers wallet, and corresponding ULPT get burned.
 *
 *  4. [OUT] launchLottery() function.
 *      This function deploys a new lottery contract, and transfers
 *      its initial funds from pool balance to the newly deployed 
 *      lottery contract.
 *      Note that lotteries can't finish with negative profits, so
 *      every lottery must return its initial profits back to the
 *      pool on finishing.
 */
contract UniLotteryPool is ERC20, CoreUniLotterySettings
{
    // =================== Structs & Enums =================== //

    /* Lottery running mode (Auto-Lottery, manual lottery).
     *
     * If Auto-Lottery feature is enabled, the new lotteries will start
     * automatically after the previous one finished, and will use
     * the default, agreed-upon config, which is set by voting.
     *
     * If Manual Lottery is enabled, the new lotteries are started
     * manually, by submitting and voting for a specific config.
     *
     * Both modes can have AVERAGE_CONFIG feature, when final lottery
     * config is not set by voting for one of several user-submitted 
     * configs, but final config is computed by averaging all the voted
     * configs, where each vote proposes a config.
     */
    enum LotteryRunMode {
        MANUAL,
        AUTO,
        MANUAL_AVERAGE_CONFIG,
        AUTO_AVERAGE_CONFIG
    }


    // ===================    Events    =================== //

    // Periodic stats event.
    event PoolStats(
        uint32 indexed lotteriesPerformed,
        uint indexed totalPoolFunds,
        uint indexed currentPoolBalance
    );

    // New poolholder joins and complete withdraws of a poolholder.
    event NewPoolholderJoin(
        address indexed poolholder,
        uint256 initialAmount
    );

    event PoolholderWithdraw(
        address indexed poolholder
    );

    // Current poolholder liquidity adds/removes.
    event AddedLiquidity(
        address indexed poolholder,
        uint256 indexed amount
    );

    event RemovedLiquidity(
        address indexed poolholder,
        uint256 indexed amount
    );

    
    // Lottery Run Mode change (for example, from Manual to Auto lottery).
    event LotteryRunModeChanged(
        LotteryRunMode previousMode,
        LotteryRunMode newMode
    );


    // Lottery configs proposed. In other words, it's a new lottery start 
    // initiation. If no config specified, then the default config for 
    // that lottery is used.
    event NewConfigProposed(
        address indexed initiator,
        Lottery.LotteryConfig cfg,
        uint configIndex
    );

    // Lottery started.
    event LotteryStarted(
        address indexed lottery,
        uint256 indexed fundsUsed,
        uint256 indexed poolPercentageUsed,
        Lottery.LotteryConfig config
    );

    // Lottery finished.
    event LotteryFinished(
        address indexed lottery,
        uint256 indexed totalReturn,
        uint256 indexed profitAmount
    );

    // Ether transfered into the fallback receive function.
    event EtherReceived(
        address indexed sender,
        uint256 indexed value
    );


    // ========= Constants ========= //

    // The Core Constants (OWNER_ADDRESS, Owner's max profit amount),
    // and also the percentage calculation-related constants,
    // are defined in the CoreUniLotterySettings contract, which this
    // contract inherits from.

    // ERC-20 token's public constants.
    string constant public name = "UniLottery Main Pool";
    string constant public symbol = "ULPT";
    uint256 constant public decimals = 18;


    // ========= State variables ========= //

    // --------- Slot --------- //

    // The debt to the Randomness Provider.
    // Incurred when we allow the Randomness Provider to execute
    // requests with higher price than we have given it funds for.
    // (of course, executed only when the Provider has enough balance
    // to execute it).
    // Paid back on next Randomness Provider request.
    uint80 randomnessProviderDebt;
    
    // Auto-Mode lottery parameters:
    uint32 public autoMode_nextLotteryDelay  = 1 days;
    uint16 public autoMode_maxNumberOfRuns   = 50;

    // When the last Auto-Mode lottery was started.
    uint32 public autoMode_lastLotteryStarted;
    
    // When the last Auto-Mode lottery has finished.
    // Used to compute the time until the next lottery.
    uint32 public autoMode_lastLotteryFinished;

    // Auto-Mode callback scheduled time.
    uint32 public autoMode_timeCallbackScheduled;

    // Iterations of current Auto-Lottery cycle.
    uint16 autoMode_currentCycleIterations = 0;

    // Is an Auto-Mode lottery currently ongoing?
    bool public autoMode_isLotteryCurrentlyOngoing = false;

    // Re-Entrancy Lock for Liquidity Provide/Remove functions.
    bool reEntrancyLock_Locked;


    // --------- Slot --------- //

    // The initial funds of all currently active lotteries.
    uint currentLotteryFunds;


    // --------- Slot --------- //

    // Most recently launched lottery.
    Lottery public mostRecentLottery;

    // Current lottery run-mode (Enum, so 1 byte).
    LotteryRunMode public lotteryRunMode = LotteryRunMode.MANUAL;

    // Last time when funds were manually sent to the Randomness Provider.
    uint32 lastTimeRandomFundsSend;


    // --------- Slot --------- //

    // The address of the Gas Oracle (our own service which calls our
    // gas price update function periodically).
    address gasOracleAddress;

    // --------- Slot --------- //

    // Stores all lotteries that have been performed 
    // (including currently ongoing ones ).
    Lottery[] public allLotteriesPerformed;

    // --------- Slot --------- //

    // Currently ongoing lotteries - a list, and a mapping.
    mapping( address => bool ) ongoingLotteries;

    // --------- Slot --------- //

    // Owner-approved addresses, which can call functions, marked with
    // modifier "ownerApprovedAddressOnly", on behalf of the Owner,
    // to initiate Owner-Only operations, such as setting next lottery
    // config, or moving specified part of Owner's liquidity pool share to
    // Owner's wallet address.
    // Note that this is equivalent of as if Owner had called the
    // removeLiquidity() function from OWNER_ADDRESS.
    //
    // These owner-approved addresses, able to call owner-only functions,
    // are used by Owner, to minimize risk of a hack in these ways:
    // - OWNER_ADDRESS wallet, which might hold significant ETH amounts,
    //   is used minimally, to have as little log-on risk in Metamask,
    //   as possible.
    // - The approved addresses can have very little Ether, so little
    //   risk of using them from Metamask.
    // - Periodic liquidity removes from the Pool can help to reduce
    //   losses, if Pool contract was hacked (which most likely
    //   wouldn't ever happen given our security measures, but 
    //   better be safe than sorry).
    //
    mapping( address => bool ) public ownerApprovedAddresses;

    // --------- Slot --------- //

    // The config to use for the next lottery that will be started.
    Lottery.LotteryConfig internal nextLotteryConfig;

    // --------- Slot --------- //

    // Randomness Provider address.
    UniLotteryRandomnessProvider immutable public randomnessProvider;

    // --------- Slot --------- //

    // The Lottery Factory that we're using to deploy NEW lotteries.
    UniLotteryLotteryFactory immutable public lotteryFactory;

    // --------- Slot --------- //

    // The Lottery Storage factory that we're using to deploy
    // new lottery storages. Used inside a Lottery Factory.
    address immutable public storageFactory;

    

    // ========= FUNCTIONS - METHODS ========= //

    // =========  Private Functions  ========= //


    // Owner-Only modifier (standard).
    modifier ownerOnly
    {
        require( msg.sender == OWNER_ADDRESS/*, "Function is Owner-Only!" */);
        _;
    }

    // Owner, or Owner-Approved address only.
    modifier ownerApprovedAddressOnly 
    {
        require( ownerApprovedAddresses[ msg.sender ]/*,
                 "Function can be called only by Owner-Approved addresses!"*/);
        _;
    }

    // Owner Approved addresses, and the Gas Oracle address.
    // Used when updating RandProv's gas price.
    modifier gasOracleAndOwnerApproved 
    {
        require( ownerApprovedAddresses[ msg.sender ] ||
                 msg.sender == gasOracleAddress/*,
                 "Function can only be called by Owner-Approved addrs, "
                 "and by the Gas Oracle!" */);
        _;
    }


    // Randomness Provider-Only modifier.
    modifier randomnessProviderOnly
    {
        require( msg.sender == address( randomnessProvider )/*,
                 "Function can be called only by the Randomness Provider!" */);
        _;
    }

    /**
     *  Modifier for checking if a caller is a currently ongoing
     *  lottery - that is, if msg.sender is one of addresses in
     *  ongoingLotteryList array, and present in ongoingLotteries.
     */
    modifier calledByOngoingLotteryOnly 
    {
        require( ongoingLotteries[ msg.sender ]/*,
                 "Function can be called only by ongoing lotteries!"*/);
        _;
    }


    /**
     *  Lock the function to protect from re-entrancy, using
     *  a Re-Entrancy Mutex Lock.
     */
    modifier mutexLOCKED
    {
        require( ! reEntrancyLock_Locked/*, "Re-Entrant Call Detected!" */);

        reEntrancyLock_Locked = true;
        _;
        reEntrancyLock_Locked = false;
    }



    // Emits a statistical event, summarizing current pool state.
    function emitPoolStats() 
                                                private 
    {
        (uint32 a, uint b, uint c) = getPoolStats();
        emit PoolStats( a, b, c );
    }


    /** PAYABLE [ OUT ] >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
     *
     *  Launch a new UniLottery Lottery, from specified Lottery Config.
     *  Perform all initialization procedures, including initial fund
     *  transfer, and random provider registration.
     *
     *  @return newlyLaunchedLottery - the Contract instance (address) of 
     *      the newly deployed and initialized lottery.
     */ 
    function launchLottery( 
            Lottery.LotteryConfig memory cfg ) 
                                                        private
                                                        mutexLOCKED
    returns( Lottery newlyLaunchedLottery )
    {
        // Check config fund requirement.
        // Lottery will need funds equal to: 
        // initial funds + gas required for randomness prov. callback.

        // Now, get the price of the random datasource query with
        // the above amount of callback gas, from randomness provider.
        uint callbackPrice = randomnessProvider
            .getPriceForRandomnessCallback( LOTTERY_RAND_CALLBACK_GAS );

        // Also take into account the debt that we might owe to the
        // Randomness Provider, if it previously executed requests
        // with price being higher than we have gave it funds for.
        //
        // This situation can occur because we transfer lottery callback
        // price funds before lottery starts, and when that lottery
        // finishes (which can happen after several weeks), then
        // the gas price might be higher than we have estimated
        // and given funds for on lottery start.
        // In this scenario, Randomness Provider would execute the 
        // request nonetheless, provided that it has enough funds in 
        // it's balance, to execute it.
        //
        // However, the Randomness Provider would notify us, that a
        // debt of X ethers have been incurred, so we would have
        // to transfer that debt's amount with next request's funds
        // to Randomness Provider - and that's precisely what we
        // are doing here, block.timestamp:

        // Compute total cost of this lottery - initial funds,
        // Randomness Provider callback cost, and debt from previous
        // callback executions.

        uint totalCost = cfg.initialFunds + callbackPrice +
                         randomnessProviderDebt;

        // Check if our balance is enough to pay the cost.
        // TODO: Implement more robust checks on minimum and maximum 
        //       allowed fund restrictions.
        require( totalCost <= address( this ).balance/*,
                 "Insufficient funds for this lottery start!" */);

        // Deploy the new lottery contract using Factory.
        Lottery lottery = Lottery( lotteryFactory.createNewLottery( 
                cfg, address( randomnessProvider ) ) );

        // Check if the lottery's pool address and owner address
        // are valid (same as ours).
        require( lottery.poolAddress() == address( this ) &&
                 lottery.OWNER_ADDRESS() == OWNER_ADDRESS/*,
                 "Lottery's pool or owner addresses are invalid!" */);

        // Transfer the Gas required for lottery end callback, and the
        // debt (if some exists), into the Randomness Provider.
        address( randomnessProvider ).transfer( 
                    callbackPrice + randomnessProviderDebt );

        // Clear the debt (if some existed) - it has been paid.
        randomnessProviderDebt = 0;

        // Notify the Randomness Provider about how much gas will be 
        // needed to run this lottery's ending callback, and how much
        // funds we have given for it.
        randomnessProvider.setLotteryCallbackGas( 
                address( lottery ), 
                LOTTERY_RAND_CALLBACK_GAS,
                uint160( callbackPrice )
        );

        // Initialize the lottery - start the active lottery stage!
        // Send initial funds to the lottery too.
        lottery.initialize{ value: cfg.initialFunds }();


        // Lottery was successfully initialized!
        // Now, add it to tracking arrays, and emit events.
        ongoingLotteries[ address(lottery) ] = true;
        allLotteriesPerformed.push( lottery );

        // Set is as the Most Recently Launched Lottery.
        mostRecentLottery = lottery;

        // Update current lottery funds.
        currentLotteryFunds += cfg.initialFunds;

        // Emit the apppproppppriate evenc.
        emit LotteryStarted( 
            address( lottery ), 
            cfg.initialFunds,
            ( (_100PERCENT) * totalCost ) / totalPoolFunds(),
            cfg
        );

        // Return the newly-successfully-started lottery.
        return lottery;
    }


    /** PAYABLE [ OUT ] >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
     *
     *  When AUTO run-mode is set, this function schedules a new lottery 
     *  to be started after the last Auto-Mode lottery has ended, after
     *  a specific time delay (by default, 1 day delay).
     *
     *  Also, it's used to bootstrap the Auto-Mode loop - because
     *  it schedules a callback to get called.
     *
     *  This function is called in 2 occasions:
     *
     *  1. When lotteryFinish() detects an AUTO run-mode, and so, a
     *      new Auto-Mode iteration needs to be performed.
     *
     *  2. When external actor bootstraps a new Auto-Mode cycle.
     *
     *  Notice, that this function doesn't use require()'s - that's
     *  because it's getting called from lotteryFinish() too, and
     *  we don't want that function to fail just because some user
     *  set run mode to other value than AUTO during the time before.
     *  The only require() is when we check for re-entrancy.
     *
     *  How Auto-Mode works?
     *  Everything is based on the Randomness Provider scheduled callback
     *  functionality, which is in turn based on Provable services.
     *  Basically, here we just schedule a scheduledCallback() to 
     *  get called after a specified amount of time, and the
     *  scheduledCallback() performs the new lottery launch from the
     *  current next-lottery config.
     *
     *  * What's payable?
     *    - We send funds to Randomness Provider, required to launch
     *      our callback later.
     */
    function scheduleAutoModeCallback()
                                            private
                                            mutexLOCKED
    returns( bool success )
    {
        // Firstly, check if mode is AUTO.
        if( lotteryRunMode != LotteryRunMode.AUTO ) {
            autoMode_currentCycleIterations = 0;
            return false;
        }

        // Start a scheduled callback using the Randomness Provider
        // service! But first, we gotta transfer the needed funds
        // to the Provider.

        // Get the price.
        uint callbackPrice = randomnessProvider
            .getPriceForScheduledCallback( AUTO_MODE_SCHEDULED_CALLBACK_GAS );

        // Add the debt, if exists.
        uint totalPrice = callbackPrice + randomnessProviderDebt;
        
        if( totalPrice > address(this).balance ) {
            return false;
        }

        // Send the required funds to the Rand.Provider.
        // Use the send() function, because it returns false upon failure,
        // and doesn't revert this transaction.
        if( ! address( randomnessProvider ).send( totalPrice ) ) {
            return false;
        }

        // Now, we've just paid the debt (if some existed).
        randomnessProviderDebt = 0;

        // Now, call the scheduling function of the Randomness Provider!
        randomnessProvider.schedulePoolCallback(
            autoMode_nextLotteryDelay,
            AUTO_MODE_SCHEDULED_CALLBACK_GAS,
            callbackPrice
        );

        // Set the time the callback was scheduled.
        autoMode_timeCallbackScheduled = uint32( block.timestamp );

        return true;
    }


    // ========= Public Functions ========= //

    /**
     *  Constructor.
     *  - Here, we deploy the ULPT token contract.
     *  - Also, we deploy the Provable-powered Randomness Provider
     *    contract, which lotteries will use to get random seed.
     *  - We assign our Lottery Factory contract address to the passed
     *    parameter - the Lottery Factory contract which was deployed
     *    before, but not yet initialize()'d.
     *
     *  Notice, that the msg.sender (the address who deployed the pool
     *  contract), doesn't play any special role in this nor any related
     *  contracts.
     */
    constructor( address _lotteryFactoryAddr,
                 address _storageFactoryAddr,
                 address payable _randProvAddr ) 
    {
        // Initialize the randomness provider.
        UniLotteryRandomnessProvider( _randProvAddr ).initialize();
        randomnessProvider = UniLotteryRandomnessProvider( _randProvAddr );

        // Set the Lottery Factory contract address, and initialize it!
        UniLotteryLotteryFactory _lotteryFactory = 
            UniLotteryLotteryFactory( _lotteryFactoryAddr );

        // Initialize the lottery factory, setting it to use the
        // specified Storage Factory.
        // After this point, factory states become immutable.
        _lotteryFactory.initialize( _storageFactoryAddr );

        // Assign the Storage Factory address.
        // Set the immutable variables to their temporary placeholders.
        storageFactory = _storageFactoryAddr;
        lotteryFactory = _lotteryFactory;

        // Set the first Owner-Approved address as the OWNER_ADDRESS
        // itself.
        ownerApprovedAddresses[ OWNER_ADDRESS ] = true;
    }


    /** PAYABLE [ IN ] <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
     *
     *  The "Receive Ether" function.
     *  Used to receive Ether from Lotteries, and from the
     *  Randomness Provider, when retrieving funds.
     */
    receive()   external payable
    {
        emit EtherReceived( msg.sender, msg.value );
    }



    /**
     *  Get total funds of the pool -- the pool balance, and all the
     *  initial funds of every currently-ongoing lottery.
     */
    function totalPoolFunds()                   public view
    returns( uint256 ) 
    {
        // Get All Active Lotteries initial funds.
        /*uint lotteryBalances = 0;
        for( uint i = 0; i < ongoingLotteryList.length; i++ ) {
            lotteryBalances += 
                ongoingLotteryList[ i ].getActiveInitialFunds();
        }*/

        return address(this).balance + currentLotteryFunds;
    }

    /**
     *  Get current pool stats - number of poolholders, 
     *  number of voters, etc.
     */
    function getPoolStats()
                                                public view
    returns( 
        uint32 _numberOfLotteriesPerformed,
        uint _totalPoolFunds,
        uint _currentPoolBalance )
    {
        _numberOfLotteriesPerformed = uint32( allLotteriesPerformed.length );
        _totalPoolFunds     = totalPoolFunds();
        _currentPoolBalance = address( this ).balance;
    }



    /** PAYABLE [ IN ] <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
     *
     *  Provide liquidity into the pool, and become a pool shareholder.
     *  - Function accepts Ether payments (No minimum deposit),
     *    and mints a proportionate number of ULPT tokens for the
     *    sender.
     */
    function provideLiquidity() 
                                    external 
                                    payable 
                                    ownerApprovedAddressOnly
                                    mutexLOCKED
    {
        // Check for minimum deposit.
        //require( msg.value > MIN_DEPOSIT/*, "Deposit amount too low!" */);

        // Compute the pool share that the user should obtain with
        // the amount he paid in this message -- that is, compute
        // percentage of the total pool funds (with new liquidity
        // added), relative to the ether transferred in this msg.

        // TotalFunds can't be zero, because currently transfered 
        // msg.value is already added to totalFunds.
        //
        // Also/*, "percentage" */can't exceed 100%, because condition
        // "totalPoolFunds() >= msg.value" is ALWAYS true, because
        // msg.value is already added to totalPoolFunds before 
        // execution of this function's body - transfers to 
        // "payable" functions are executed before the function's
        // body executes (Solidity docs).
        //
        uint percentage =   ( (_100PERCENT) * msg.value ) / 
                            ( totalPoolFunds() );

        // Now, compute the amount of new ULPT tokens (x) to mint 
        // for this new liquidity provided, according to formula,
        // whose explanation is provided below.
        //
        // Here, we assume variables:
        //
        //  uintFormatPercentage: the "percentage" Solidity variable,
        //      defined above, in (uint percentage = ...) statement.
        //
        //  x: the amount of ULPT tokens to mint for this liquidity 
        //      provider, to maintain "percentage" ratio with the
        //      ULPT's totalSupply after minting (newTotalSupply).
        //
        //  totalSupply: ULPT token's current total supply
        //      (as returned from totalSupply() function).
        //
        //  Let's start the formula:
        //
        // ratio = uintFormatPercentage / (_100PERCENT)
        // newTotalSupply = totalSupply + x
        //
        // x / newTotalSupply    = ratio
        // x / (totalSupply + x) = ratio
        // x = ratio * (totalSupply + x)
        // x = (ratio * totalSupply) + (ratio * x)
        // x - (ratio * x) = (ratio * totalSupply) 
        // (1 * x) - (ratio * x) = (ratio * totalSupply) 
        // ( 1 - ratio ) * x = (ratio * totalSupply) 
        // x = (ratio * totalSupply) / ( 1 - ratio )
        //
        //                  ratio * totalSupply
        // x = ------------------------------------------------
        //      1 - ( uintFormatPercentage / (_100PERCENT) )
        //
        //
        //                ratio * totalSupply * (_100PERCENT)
        // x = ---------------------------------------------------------------
        //     ( 1 - (uintFormatPercentage / (_100PERCENT)) )*(_100PERCENT)
        //
        // Let's abbreviate "_100PERCENT" to "100%".
        //
        //                      ratio * totalSupply * 100%
        // x = ---------------------------------------------------------
        //     ( 1 * 100% ) - ( uintFormatPercentage / (100%) ) * (100%)
        //
        //          ratio * totalSupply * 100%
        // x = -------------------------------------
        //          100% - uintFormatPercentage
        //
        //        (uintFormatPercentage / (100%)) * totalSupply * 100%
        // x = -------------------------------------------------------
        //          100% - uintFormatPercentage
        //
        //        (uintFormatPercentage / (100%)) * 100% * totalSupply
        // x = -------------------------------------------------------
        //          100% - uintFormatPercentage
        //
        //      uintFormatPercentage * totalSupply
        // x = ------------------------------------
        //         100% - uintFormatPercentage
        //
        // So, with our Solidity variables, that would be:
        // ==================================================== //
        //                                                      //
        //                     percentage * totalSupply         //
        //   amountToMint = ------------------------------      //
        //                   (_100PERCENT) - percentage       //
        //                                                      //
        // ==================================================== //
        //
        // We know that "percentage" is ALWAYS <= 100%, because
        // msg.value is already added to address(this).balance before
        // the payable function's body executes.
        //
        // However, notice that when "percentage" approaches 100%,
        // the denominator approaches 0, and that's not good.
        //
        // So, we must ensure that uint256 precision is enough to
        // handle such situations, and assign a "default" value for
        // amountToMint if such situation occurs.
        //
        // The most prominent case when this situation occurs, is on
        // the first-ever liquidity provide, when ULPT total supply is 
        // zero, and the "percentage" value is 100%, because pool's
        // balance was 0 before the operation.
        //
        // In such situation, we mint the 100 initial ULPT, which 
        // represent the pool share of the first ever pool liquidity 
        // provider, and that's 100% of the pool.
        // 
        // Also, we do the same thing (mint 100 ULPT tokens), on all
        // on all other situations when "percentage" is too close to 100%,
        // such as when there's a very tiny amount of liquidity left in
        // the pool.
        //
        // We check for those conditions based on precision of uint256
        // number type.
        // We know, that 256-bit uint can store up to roughly 10^74
        // base-10 values.
        //
        // Also, in our formula:
        // "totalSupply" can go to max. 10^30 (in extreme cases).
        // "percentage" up to 10^12 (with more-than-enough precision).
        // 
        // When multiplied, that's still only 10^(30+12) = 10^42 ,
        // and that's still a long way to go to 10^74.
        //
        // So, the denominator "(_100PERCENT) - percentage" can go down
        // to 1 safely, we must only ensure that it's not zero - 
        // and the uint256 type will take care of all precision needed.
        //

        if( balanceOf( msg.sender ) == 0 )
            emit NewPoolholderJoin( msg.sender, msg.value );


        // If percentage is below 100%, and totalSupply is NOT ZERO, 
        // work with the above formula.
        if( percentage < (_100PERCENT) &&
            totalSupply() != 0 )
        {
            // Compute the formula!
            uint256 amountToMint = 
                ( percentage * totalSupply() ) /
                (       (_100PERCENT) - percentage        );

            // Mint the computed amount.
            _mint( msg.sender, amountToMint );
        }

        // Else, if the newly-added liquidity percentage is 100% 
        // (pool's balance was Zero before this liquidity provide), then
        // just mint the initial 100 pool tokens.
        else
        {
            _mint( msg.sender, ( 100 * (uint( 10 ) ** decimals) ) );
        }


        // Emit corresponding event, that liquidity has been added.
        emit AddedLiquidity( msg.sender, msg.value );
        emitPoolStats();
    }


    /**
     *  Get the current pool share (percentage) of a specified
     *  address. Return the percentage, compute from ULPT data.
     */
    function getPoolSharePercentage( address holder ) 
                                                        public view
    returns ( uint percentage ) 
    {
        return  ( (_100PERCENT) * balanceOf( holder ) )
                / totalSupply();
    }


    /** PAYABLE [ OUT ] >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
     *
     *  Remove msg.sender's pool liquidity share, and transfer it
     *  back to msg.sender's wallet.
     *  Burn the ULPT tokens that represented msg.sender's share
     *  of the pool.
     *  Notice that no activelyManaged modifier is present, which
     *  means that users are able to withdraw their money anytime.
     *
     *  However, there's a caveat - if some lotteries are currently
     *  ongoing, the pool's current reserve balance might not be 
     *  enough to meet every withdrawer's needs.
     *  
     *  In such scenario, withdrawers have either have to (OR'd):
     *  - Wait for ongoing lotteries to finish and return their 
     *    funds back to the pool,
     *  - TODO: Vote for forceful termination of lotteries
     *    (vote can be done whether pool is active or not).
     *  - TODO: Wait for OWNER to forcefully terminate lotteries.
     *
     *  Notice that last 2 options aren't going to be implemented
     *  in this version, because, as the OWNER is going to be the 
     *  only pool shareholder in the begginning, lottery participants
     *  might see the forceful termination feature as an exit-scam 
     *  threat, and this would damage project's reputation.
     *
     *  The feature is going to be implemented in later versions,
     *  after security audits pass, pool is open to public,
     *  and a significant amount of wallets join a pool.
     */
    function removeLiquidity(
            uint256 ulptAmount ) 
                                                external
                                                ownerApprovedAddressOnly
                                                mutexLOCKED
    {
        // Find out the real liquidity owner of this call - 
        // Check if the msg.sender is an approved-address, which can
        // call this function on behalf of the true liquidity owner.
        // Currently, this feature is only supported for OWNER_ADDRESS.
        address payable liquidityOwner = OWNER_ADDRESS;


        // Condition "balanceOf( liquidityOwner ) > 1" automatically 
        // checks if totalSupply() of ULPT is not zero, so we don't have
        // to check it separately.
        require( balanceOf( liquidityOwner ) > 1 &&
                 ulptAmount != 0 &&
                 ulptAmount <= balanceOf( liquidityOwner )/*,
                 "Specified ULPT token amount is invalid!" */);

        // Now, compute share percentage, and send the appropriate
        // amount of Ether from pool's balance to liquidityOwner.
        uint256 percentage = ( (_100PERCENT) * ulptAmount ) / 
                             totalSupply();

        uint256 shareAmount = ( totalPoolFunds() * percentage ) /
                              (_100PERCENT);

        require( shareAmount <= address( this ).balance/*, 
                 "Insufficient pool contract balance!" */);

        // Burn the specified amount of ULPT, thus removing the 
        // holder's pool share.
        _burn( liquidityOwner, ulptAmount );


        // Transfer holder's fund share as ether to holder's wallet.
        liquidityOwner.transfer( shareAmount );


        // Emit appropriate events.
        if( balanceOf( liquidityOwner ) == 0 )
            emit PoolholderWithdraw( liquidityOwner );

        emit RemovedLiquidity( liquidityOwner, shareAmount );
        emitPoolStats();
    }


    // ======== Lottery Management Section ======== //

    // Check if lottery is currently ongoing.
    function isLotteryOngoing( address lotAddr ) 
                                                    external view
    returns( bool ) {
        return ongoingLotteries[ lotAddr ];
    }


    // Get length of all lotteries performed.
    function allLotteriesPerformed_length()
                                                    external view
    returns( uint )
    {
        return allLotteriesPerformed.length;
    }


    /** PAYABLE [ IN ] <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
     *
     *  Ongoing (not-yet-completed) lottery finalization function.
     *  - This function is called by a currently ongoing lottery, to
     *    notify the pool about it's finishing.
     *  - After lottery calls this function, lottery is removed from
     *    ongoing lottery tracking list, and set to inactive.
     *
     *  * Ether is transfered into our contract:
     *      Lottery transfers the pool profit share and initial funds 
     *      back to the pool when calling this function, so the
     */
    function lotteryFinish( 
                uint totalReturn, 
                uint profitAmount )
                                            external
                                            payable
                                            calledByOngoingLotteryOnly
    {
        // "De-activate" this lottery.
        //ongoingLotteries[ msg.sender ] = false;
        delete ongoingLotteries[ msg.sender ];  // implies "false"

        // We assume that totalReturn and profitAmount are valid,
        // because this function can be called only by Lottery, which
        // was deployed by us before.

        // Update current lottery funds - this one is no longer active,
        // so it's funds block.timestamp have been transfered to us.
        uint lotFunds = Lottery( msg.sender ).getInitialFunds();
        if( lotFunds < currentLotteryFunds )
            currentLotteryFunds -= lotFunds;
        else
            currentLotteryFunds = 0;

        // Emit approppriate events.
        emit LotteryFinished( msg.sender, totalReturn, profitAmount );

        // If AUTO-MODE is currently set, schedule a next lottery
        // start using the current AUTO-MODE parameters!
        // Ignore the return value, because AUTO-MODE params might be
        // invalid, and we don't want our finish function to fail
        // just because of that.

        if( lotteryRunMode == LotteryRunMode.AUTO )
        {
            autoMode_isLotteryCurrentlyOngoing = false;
            autoMode_lastLotteryFinished = uint32( block.timestamp );

            scheduleAutoModeCallback();
        }
    }


    /**
     *  The Callback function which Randomness Provider will call
     *  when executing the Scheduled Callback requests.
     *
     *  We use this callback for scheduling Auto-Mode lotteries - 
     *  when one lottery finishes, another one is scheduled to run
     *  after specified amount of time.
     *
     *  In this callback, we start the scheduled Auto-Mode lottery.
     */
    function scheduledCallback( uint256 /*requestID*/ ) 
                                                                public
    {
        // At first, check if mode is AUTO (not changed).
        if( lotteryRunMode != LotteryRunMode.AUTO )
            return;

        // Check if we're not X-Ceeding the number of auto-iterations.
        if( autoMode_currentCycleIterations >= autoMode_maxNumberOfRuns )
        {
            autoMode_currentCycleIterations = 0;
            return;
        }

        // Launch an auto-lottery using the currently set next
        // lottery config!
        // When this lottery finishes, and the mode is still AUTO,
        // one more lottery will be started.

        launchLottery( nextLotteryConfig );

        // Set the time started, and increment iterations.
        autoMode_isLotteryCurrentlyOngoing = true;
        autoMode_lastLotteryStarted = uint32( block.timestamp );
        autoMode_currentCycleIterations++;
    }


    /**
     *  The Randomness Provider-callable function, which is used to
     *  ask pool for permission to execute lottery ending callback 
     *  request with higher price than the pool-given funds for that
     *  specific lottery's ending request, when lottery was created.
     *
     *  The function notifies the pool about the new and 
     *  before-expected price, so the pool could compute a debt to
     *  be paid to the Randomnes Provider in next request.
     *
     *  Here, we update our debt variable, which is the difference
     *  between current and expected-before request price,
     *  and we'll transfer the debt to Randomness Provider on next
     *  request to Randomness Provider.
     *
     *  Notice, that we'll permit the execution of the lottery
     *  ending callback only if the new price is not more than 
     *  1.5x higher than before-expected price.
     *
     *  This is designed so, because the Randomness Provider will
     *  call this function only if it has enough funds to execute the 
     *  callback request, and just that the funds that we have transfered
     *  for this specific lottery's ending callback before, are lower
     *  than the current price of execution.
     *
     *  Why is this the issue? 
     *  Lottery can last for several weeks, and we give the callback
     *  execution funds for that specific lottery to Randomness Provider
     *  only on that lottery's initialization.
     *  So, after a few weeks, the Provable services might change the
     *  gas & fee prices, so the callback execution request price 
     *  might change.
     */
    function onLotteryCallbackPriceExceedingGivenFunds(
            address /*lottery*/, 
            uint currentRequestPrice,
            uint poolGivenExpectedRequestPrice )
                                                    external 
                                                    randomnessProviderOnly
    returns( bool callbackExecutionPermitted )
    {
        require( currentRequestPrice > poolGivenExpectedRequestPrice );
        uint difference = currentRequestPrice - poolGivenExpectedRequestPrice;

        // Check if the price difference is not bigger than the half
        // of the before-expected pool-given price.
        // Also, make sure that whole debt doesn't exceed 0.5 ETH.
        if( difference <= ( poolGivenExpectedRequestPrice / 2 ) &&
            ( randomnessProviderDebt + difference ) < ( (1 ether) / 2 ) )
        {
            // Update our debt, to pay back the difference later,
            // when we transfer funds for the next request.
            randomnessProviderDebt += uint80( difference );

            // Return true - the callback request execution is permitted.
            return true;
        }

        // The price difference is higher - deny the execution.
        return false;
    }


    // Below are the Owner-Callable voting-skipping functions, to set 
    // the next lottery config, lottery run mode, and other settings.
    //
    // When the final version is released, these functions will
    // be removed, and every governance operation will be done
    // through voting.

    /**
     *  Set the LotteryConfig to be used by the next lottery.
     *  Owner-only callable.
     */
    function setNextLotteryConfig(
            Lottery.LotteryConfig memory cfg )
                                                    public
                                                    ownerApprovedAddressOnly
    {
        nextLotteryConfig = cfg;

        emit NewConfigProposed( msg.sender, cfg, 0 );
        // emitPoolStats();
    }

    /**
     *  Set the Lottery Run Mode to be used for further lotteries.
     *  It can be AUTO, or MANUAL (more about it on their descriptions).
     */
    function setRunMode(
            LotteryRunMode runMode )
                                                    external
                                                    ownerApprovedAddressOnly
    {
        // Check if it's one of allowed run modes.
        require( runMode == LotteryRunMode.AUTO ||
                 runMode == LotteryRunMode.MANUAL/*,
                 "This Run Mode is not allowed in current state!" */);

        // Emit a change event, with old value and new value.
        emit LotteryRunModeChanged( lotteryRunMode, runMode );

        // Set the new run mode!
        lotteryRunMode = runMode;

        // emitPoolStats();
    }

    /**
     *  Start a manual mode lottery from the previously set up
     *  next lottery config!
     */
    function startManualModeLottery()
                                                    external
                                                    ownerApprovedAddressOnly
    {
        // Check if config is set - just check if initial funds
        // are a valid value.
        require( nextLotteryConfig.initialFunds != 0/*,
                 "Currently set next-lottery-config is invalid!" */);

        // Launch a lottery using our private launcher function!
        launchLottery( nextLotteryConfig );

        emitPoolStats();
    }


    /**
     *  Set an Auto-Mode lottery run mode parameters.
     *  The auto-mode is implemented using Randomness Provider 
     *  scheduled callback functionality, to schedule a lottery start
     *  on specific intervals.
     *
     *  @param nextLotteryDelay - amount of time, in seconds, to wait
     *      when last lottery finishes, to start the next lottery.
     *
     *  @param maxNumberOfRuns  - max number of lottery runs in this
     *      Auto-Mode cycle. When it's reached, mode will switch to
     *      MANUAL automatically.
     */
    function setAutoModeParameters(
            uint32 nextLotteryDelay,
            uint16 maxNumberOfRuns )
                                                    external
                                                    ownerApprovedAddressOnly
    {
        // Set params!
        autoMode_nextLotteryDelay = nextLotteryDelay;
        autoMode_maxNumberOfRuns = maxNumberOfRuns;

        // emitPoolStats();
    }

    /**
     *  Starts an Auto-Mode lottery running cycle with currently
     *  specified Auto-Mode parameters.
     *  Notice that we must be on Auto run-mode currently.
     */
    function startAutoModeCycle()
                                                    external
                                                    ownerApprovedAddressOnly
    {
        // Check that we're on the Auto-Mode block.timestamp.
        require( lotteryRunMode == LotteryRunMode.AUTO/*,
                 "Current Run Mode is not AUTO!" */);

        // Check if valid AutoMode params were specified.
        require( autoMode_maxNumberOfRuns != 0/*,
                 "Invalid Auto-Mode params set!" */);

        // Reset the cycle iteration counter.
        autoMode_currentCycleIterations = 0;

        // Start the Auto-Mode cycle using a scheduled callback!
        scheduledCallback( 0 );

        // emitPoolStats();
    }

    /**
     *  Set or Remove Owner-approved addresses.
     *  These addresses are used to call ownerOnly functions on behalf
     *  of the OWNER_ADDRESS (more detailed description above).
     */
    function owner_setOwnerApprovedAddress( address addr )
                                                                external
                                                                ownerOnly
    {
        ownerApprovedAddresses[ addr ] = true;
    }

    function owner_removeOwnerApprovedAddress( address addr )
                                                                external
                                                                ownerOnly
    {
        delete ownerApprovedAddresses[ addr ];
    }


    /**
     *  ABIEncoderV2 - compatible getter for the nextLotteryConfig,
     *  which will be retuned as byte array internally, then internally
     *  de-serialized on receive.
     */
    function getNextLotteryConfig()
                                                                external 
                                                                view
    returns( Lottery.LotteryConfig memory )
    {
        return nextLotteryConfig;
    }

    /** PAYABLE [ IN ] <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
     *
     *  Retrieve the UnClaimed Prizes of a completed lottery, if
     *  that lottery's prize claim deadline has already passed.
     *
     *  - What's payable? This function causes a specific Lottery to
     *      transfer Ether from it's contract balance, to our contract.
     */
    function retrieveUnclaimedLotteryPrizes(
            address payable lottery )
                                                    external
                                                    ownerApprovedAddressOnly
                                                    mutexLOCKED
    {
        // Just call that function - if the deadline hasn't passed yet,
        // that function will revert.
        Lottery( lottery ).getUnclaimedPrizes();
    }


    /** PAYABLE [ IN ] <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
     *
     *  Retrieve the specified amount of funds from the Randomness
     *  Provider.
     *
     *  WARNING: Future scheduled operations on randomness provider
     *           might FAIL if randomness provider won't have enough
     *           funds to execute that operation on that time!
     *
     *  - What's payable? This function causes the Randomness Provider to
     *      transfer Ether from it's contract balance, to our contract.
     */
    function retrieveRandomnessProviderFunds(
            uint etherAmount )
                                                    external
                                                    ownerApprovedAddressOnly
                                                    mutexLOCKED
    {
        randomnessProvider.sendFundsToPool( etherAmount );
    }

    /** PAYABLE [ OUT ] >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
     *
     *  Send specific amount of funds to Randomness Provider, from
     *  our contract's balance.
     *  This is useful in cases when gas prices change, and current
     *  funds inside randomness provider are not enough to execute
     *  operations on the new gas cost.
     *
     *  This operation is limited to 6 ethers once in 12 hours.
     *
     *  - What's payable?   We send Ether to the randomness provider.
     */
    function provideRandomnessProviderFunds(
            uint etherAmount )
                                                    external
                                                    ownerApprovedAddressOnly
                                                    mutexLOCKED
    {
        // Check if conditions apply!
        require( ( etherAmount <= 6 ether ) &&
                 ( block.timestamp - lastTimeRandomFundsSend > 12 hours )/*,
                 "Random Fund Provide Conditions are not satisfied!" */);

        // Set the last-time-funds-sent timestamp to block.timestamp.
        lastTimeRandomFundsSend = uint32( block.timestamp );

        // Transfer the funds.
        address( randomnessProvider ).transfer( etherAmount );
    }


    /**
     *  Set the Gas Price to use in the Randomness Provider.
     *  Used when very volatile gas prices are present during network
     *  congestions, when default is not enough.
     */
    function setGasPriceOfRandomnessProvider(
            uint gasPrice )
                                                external
                                                gasOracleAndOwnerApproved
    {
        randomnessProvider.setGasPrice( gasPrice );
    }


    /**
     *  Set the address of the so-called Gas Oracle, which is an
     *  automated script running on our server, and fetching gas prices.
     *
     *  The address used by this script should be able to call
     *  ONLY the "setGasPriceOfRandomnessProvider" function (above).
     *
     *  Here, we set that address.
     */
    function setGasOracleAddress( address addr )
                                                    external
                                                    ownerApprovedAddressOnly
    {
        gasOracleAddress = addr;
    }

}



