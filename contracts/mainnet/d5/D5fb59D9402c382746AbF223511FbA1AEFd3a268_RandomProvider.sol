// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity = 0.6.11;

// Import Provable base API contract.
import "./provableAPI_0.6.sol";


// ------------         TESTING ENVIRONMENT         ------------ //

// As Provable services are not available in private testnets,
// we need to simulate Provable offchain services behavior 
// locally, by calling the TEST_executeRequest() function from
// local web3 Provable emulator.

/*abstract contract usingProvable
{
    // Ledger proof type constant.
    uint constant proofType_Ledger = 1;

    // Default gas price. TODO: don't use this, get from Provable.
    uint public TEST_DEFAULT_GAS_PRICE = 20 * (10 ** 9); // 20 GWei

    // Number of requests processed since the deployment.
    // Also used as an ID for next request.
    uint TEST_requestCount = 1;

    // TEST-ONLY Provable function stub-plementations.

    // Return Local Provable Emulator address (on our Ganache network).
    function provable_cbAddress()
                                                            internal pure
    returns( address )
    {
        return address( 0x3EA4e2F6922FCAd09C08413cB7E1E7B786030657 );
    }

    function provable_setProof( uint ) internal pure {}

    function provable_getPrice( 
            string memory datasource, uint gasLimit )
                                                            internal view
    returns( uint totalPrice )
    {
        return TEST_DEFAULT_GAS_PRICE * gasLimit;
    }

    function provable_query( 
            uint timeout, string memory datasource,
            string memory query, uint gasLimit )
                                                            internal
    returns( bytes32 queryId )
    {
        return bytes32( TEST_requestCount++ );
    }

    function provable_newRandomDSQuery( uint delay, 
                    uint numBytes, uint gasLimit )
                                                            internal
    returns( bytes32 queryId )
    {
        return bytes32( TEST_requestCount++ );
    }

    function provable_randomDS_proofVerify__returnCode(
                    bytes32 _queryId, string memory _result, 
                    bytes memory _proof )
                                                            internal pure
    returns( uint )
    {
        // Proof is always valid.
        return 0;
    }

    // Set custom gas price.
    function provable_setCustomGasPrice( uint _gasPrice )
                                                            internal
    {
        TEST_DEFAULT_GAS_PRICE = _gasPrice;
    }

    // Provable's default callback.
    function __callback(
            bytes32 _queryId,
            string memory _result,
            bytes memory _proof )
                                            public
                                            virtual ;
}*/

// ------------ [ END ] TESTING ENVIRONMENT [ END ] ------------ //



// Main UniLottery Pool Interface.
interface IMainUniLotteryPool
{
    function isLotteryOngoing( address lotAddr ) 
        external view returns( bool );

    function scheduledCallback( uint256 requestID ) 
        external;

    function onLotteryCallbackPriceExceedingGivenFunds(
                address lottery, uint currentRequestPrice,
                uint poolGivenPastRequestPrice )
        external returns( bool );
}

// Lottery Interface.
interface ILottery
{
    function finish_randomnessProviderCallback( 
            uint256 randomSeed, uint256 requestID ) external;
}


/**
 *  This is the Randomness Provider contract, which is being used
 *  by the UniLottery Lottery contract instances, and by the
 *  Main UniLottery Pool.
 *
 *  This is the wrapper contract over the Provable (Oraclize) oracle
 *  service, which is being used to obtain true random seeds, and
 *  to schedule function callbacks.
 *
 *  This contract is being used in these cases:
 *
 *  1. Lottery instance requests a random seed, to be used when choosing
 *      winners in the Winner Selection Algorithm, on the lottery's ending.
 *
 *  2. Main UniLottery Pool is using this contract as a scheduler, to
 *      schedule the next AutoLottery start on specific time interval.
 *
 *  This contract is using Provable services to accompish these goals,
 *  and that means that this contract must pay the gas costs and fees
 *  from it's own balance.
 *
 *  So, in order to use it, the Main Pool must transfer enough Ether
 *  to this contract's address, to cover all fees which Provable
 *  services will charge for request & callback execution.
 */

contract UniLotteryRandomnessProvider is usingProvable
{
    // =============== E-Vent Section =============== //

    // New Lottery Random Seed Request made.
    event LotteryRandomSeedRequested(
        uint id,
        address lotteryAddress,
        uint gasLimit,
        uint totalEtherGiven
    );

    // Random seed obtained, and callback successfully completed.
    event LotteryRandomSeedCallbackCompleted(
        uint id
    );

    // UniLottery Pool scheduled a call.
    event PoolCallbackScheduled(
        uint id,
        address poolAddress,
        uint timeout,
        uint gasLimit,
        uint totalEtherGiven
    );

    // Pool scheduled callback successfully completed.
    event PoolCallbackCompleted(
        uint id
    );

    // Ether transfered into fallback.
    event EtherTransfered(
        address sender,
        uint value
    );


    // =============== Structs & Enums =============== //

    // Enum - type of the request.
    enum RequestType {
        LOTTERY_RANDOM_SEED,
        POOL_SCHEDULED_CALLBACK
    }

    // Call Request Structure.
    struct CallRequestData
    {
        // -------- Slot -------- //

        // The ID of the request.
        uint256 requestID;

        // -------- Slot -------- //

        // Requester address. Can be pool, or an ongoing lottery.
        address requesterAddress;

        // The Type of request (Random Seed or Pool Scheduled Callback).
        RequestType reqType;
    }

    // Lottery request config - specifies gas limits that must
    // be used for that specific lottery's callback.
    // Must be set separately from CallRequest, because gas required
    // is specified and funds are transfered by The Pool, before starting
    // a lottery, and when that lottery ends, it just calls us, expecting
    // it's gas cost funds to be already sent to us.
    struct LotteryGasConfig
    {
        // -------- Slot -------- //

        // The total ether funds that the pool has transfered to
        // our contract for execution of this lottery's callback.
        uint160 etherFundsTransferedForGas;

        // The gas limit provided for that callback.
        uint64 gasLimit;
    }


    // =============== State Variables =============== //

    // -------- Slot -------- //

    // Mapping of all currently pending or on-process requests
    // from their Query IDs.
    mapping( uint256 => CallRequestData ) pendingRequests;

    // -------- Slot -------- //

    // A mapping of Pool-specified-before-their-start lottery addresses,
    // to their corresponding Gas Configs, which will be used for
    // their end callbacks.
    mapping( address => LotteryGasConfig ) lotteryGasConfigs;

    // -------- Slot -------- //

    // The Pool's address. We receive funds from it, and use it
    // to check whether the requests are coming from ongoing lotteries.
    address payable poolAddress;


    // ============ Private/Internal Functions ============ //

    // Pool-Only modifier.
    modifier poolOnly 
    {
        require( msg.sender == poolAddress );
        _;
    }

    // Ongoing Lottery Only modifier.
    // Data must be fetch'd from the Pool.
    modifier ongoingLotteryOnly
    {
        require( IMainUniLotteryPool( poolAddress )
                 .isLotteryOngoing( msg.sender ) );
        _;
    }

    // ================= Public Functions ================= //

    /**
     *  Constructor.
     *  Here, we specify the Provable proof type, to use for
     *  Random Datasource queries.
     */
    constructor()   public
    {
        // Set the Provable proof type for Random Queries - Ledger.
        provable_setProof( proofType_Ledger );
    }

    /**
     *  Initialization function.
     *  Called by the Pool, on Pool's constructor, to initialize this
     *  randomness provider.
     */
    function initialize()       external
    {
        // Check if we were'nt initialized yet (pool address not set yet).
        require( poolAddress == address( 0 ) );

        poolAddress = msg.sender;
    }


    /**
     *  The Payable Fallback function.
     *  This function is used by the Pool, to transfer the required
     *  funds to us, to be able to pay for Provable gas & fees.
     */
    receive ()    external payable
    {
        emit EtherTransfered( msg.sender, msg.value );
    }


    /**
     *  Get the total Ether price for a request to specific
     *  datasource with specific gas limit.
     *  It just calls the Provable's internal getPrice function.
     */
    // Random datasource.
    function getPriceForRandomnessCallback( uint gasLimit )
                                                                external
    returns( uint totalEtherPrice )
    {
        return provable_getPrice( "random", gasLimit );
    }

    // URL datasource (for callback scheduling).
    function getPriceForScheduledCallback( uint gasLimit )
                                                                external
    returns( uint totalEtherPrice )
    {
        return provable_getPrice( "URL", gasLimit );
    }


    /**
     *  Set the gas limit which should be used by the lottery deployed
     *  on address "lotteryAddr", when that lottery finishes and
     *  requests us to call it's ending callback with random seed
     *  provided.
     *  Also, specify the amount of Ether that the pool has transfered
     *  to us for the execution of this lottery's callback.
     */
    function setLotteryCallbackGas(
            address lotteryAddr,
            uint64 callbackGasLimit,
            uint160 totalEtherTransferedForThisOne )
                                                        external
                                                        poolOnly
    {
        LotteryGasConfig memory gasConfig;

        gasConfig.gasLimit = callbackGasLimit;
        gasConfig.etherFundsTransferedForGas = totalEtherTransferedForThisOne;

        // Set the mapping entry for this lottery address.
        lotteryGasConfigs[ lotteryAddr ] = gasConfig;
    }


    /**
     *  The Provable Callback, which will get called from Off-Chain
     *  Provable service, when it completes execution of our request,
     *  made before previously with provable_query variant.
     *
     *  Here, we can perform 2 different tasks, based on request type
     *  (we get the CallRequestData from the ID passed by Provable).
     *
     *  The different tasks are:
     *  1. Pass Random Seed to Lottery Ending Callback.
     *  2. Call a Pool's Scheduled Callback.
     */
    function __callback(
            bytes32 _queryId,
            string memory _result,
            bytes memory _proof )
                                            public
                                            override
    {
        // Check that the sender is Provable Services.
        require( msg.sender == provable_cbAddress() );

        // Get the Request Data storage pointer, and check if it's Set.
        CallRequestData storage reqData = 
            pendingRequests[ uint256( _queryId ) ];

        require( reqData.requestID != 0 );

        // Check the Request Type - if it's a lottery asking for a 
        // random seed, or a Pool asking to call it's scheduled callback.

        if( reqData.reqType == RequestType.LOTTERY_RANDOM_SEED )
        {
            // It's a lottery asking for a random seed.
            // Check if Proof is valid, using the Base Contract's built-in
            // checking functionality.
            require( provable_randomDS_proofVerify__returnCode(
                        _queryId, _result, _proof ) == 0 );
                
            // Get the Random Number by keccak'ing the random bytes passed.
            uint256 randomNumber = uint256( 
                    keccak256( abi.encodePacked( _result ) ) );

            // Pass this Random Number as a Seed to the requesting lottery!
            ILottery( reqData.requesterAddress )
                    .finish_randomnessProviderCallback( 
                            randomNumber, uint( _queryId ) );

            // Emit appropriate events.
            emit LotteryRandomSeedCallbackCompleted( uint( _queryId ) );
        }

        // It's a pool, asking to call it's callback, that it scheduled
        // to get called in some time before.
        else if( reqData.reqType == RequestType.POOL_SCHEDULED_CALLBACK )
        {
            IMainUniLotteryPool( poolAddress )
                    .scheduledCallback( uint( _queryId ) );

            // Emit appropriate events.
            emit PoolCallbackCompleted( uint( _queryId ) );
        }

        // We're finished! Remove the request data from the pending
        // requests mapping.
        delete pendingRequests[ uint256( _queryId ) ];
    }


    /**
     *  This is the function through which the Lottery requests a
     *  Random Seed for it's ending callback.
     *  The gas funds needed for that callback's execution were already
     *  transfered to us from The Pool, at the moment the Pool created
     *  and deployed that lottery.
     *  The gas specifications are set in the LotteryGasConfig of that
     *  specific lottery.
     *  TODO: Also set the custom gas price.
     */
    function requestRandomSeedForLotteryFinish()
                                                    external
                                                    ongoingLotteryOnly
    returns( uint256 requestId )
    {
        // Check if gas limit (amount of gas) for this lottery was set.
        require( lotteryGasConfigs[ msg.sender ].gasLimit != 0 );

        // Check if the currently estimated price for this request
        // is not higher than the one that the pool transfered funds for.
        uint transactionPrice = provable_getPrice( "random", 
                    lotteryGasConfigs[ msg.sender ].gasLimit );

        if( transactionPrice >
            lotteryGasConfigs[ msg.sender ].etherFundsTransferedForGas )
        {
            // If our balance is enough to execute the transaction, then
            // ask pool if it agrees that we execute this transaction
            // with higher price than pool has given funds to us for.
            if( address(this).balance >= transactionPrice )
            {
                bool response = IMainUniLotteryPool( poolAddress )
                .onLotteryCallbackPriceExceedingGivenFunds(
                    msg.sender, 
                    transactionPrice,
                    lotteryGasConfigs[msg.sender].etherFundsTransferedForGas
                );

                require( response );
            }
            // If price absolutely exceeds our contract's balance:
            else {
                require( false );
            }
        }

        // Set the Provable Query parameters.
        // Execute the query as soon as possible.
        uint256 QUERY_EXECUTION_DELAY = 0;

        // Set the gas amount to the previously specified gas limit.
        uint256 GAS_FOR_CALLBACK = lotteryGasConfigs[ msg.sender ].gasLimit;

        // Request 8 random bytes (that's enough randomness with keccak).
        uint256 NUM_RANDOM_BYTES_REQUESTED = 8;

        // Execute the Provable Query!
        uint256 queryId = uint256( provable_newRandomDSQuery(
            QUERY_EXECUTION_DELAY,
            NUM_RANDOM_BYTES_REQUESTED,
            GAS_FOR_CALLBACK
        ) );

        // Populate & Add the pending requests mapping entry.
        CallRequestData memory requestData;

        requestData.requestID = queryId;
        requestData.reqType = RequestType.LOTTERY_RANDOM_SEED;
        requestData.requesterAddress = msg.sender;

        pendingRequests[ queryId ] = requestData;

        // Emit an event - lottery just requested a random seed.
        emit LotteryRandomSeedRequested( 
            queryId, msg.sender, 
            lotteryGasConfigs[ msg.sender ].gasLimit,
            lotteryGasConfigs[ msg.sender ].etherFundsTransferedForGas
        );

        // Remove the just-used Lottery Gas Configs mapping entry.
        delete lotteryGasConfigs[ msg.sender ];

        // Return the ID of the query.
        return queryId;
    }


    /**
     *  Schedule a call for the pool, using specified amount of gas,
     *  and executing after specified amount of time.
     *  Accomplished using an empty URL query, and setting execution
     *  delay to the specified timeout.
     *  On execution, __callback() calls the Pool's scheduledCallback()
     *  function.
     *
     *  @param timeout - how much time to delay the execution of callback.
     *  @param gasLimit - gas limit to use for the callback's execution.
     *  @param etherFundsTransferedForGas - how much Ether has the Pool
     *      transfered to our contract before calling this function,
     *      to be used only for this operation.
     */
    function schedulePoolCallback( 
                uint timeout, 
                uint gasLimit,
                uint etherFundsTransferedForGas )
                                                    external
                                                    poolOnly
    returns( uint256 requestId )
    {
        // Price exceeding transfered funds doesn't need to be checked
        // here, because pool transfers required funds just before
        // calling this function, so price can't change between transfer
        // and this function's call.

        // Execute the query on specified timeout, with a 
        // specified Gas Limit.
        uint queryId = uint( 
                provable_query( timeout, "URL", "", gasLimit ) 
        );

        // Populate & Add the pending requests mapping entry.
        CallRequestData memory requestData;

        requestData.requestID = queryId;
        requestData.reqType = RequestType.POOL_SCHEDULED_CALLBACK;
        requestData.requesterAddress = msg.sender;

        pendingRequests[ queryId ] = requestData;

        // Emit an event - lottery just requested a random seed.
        emit PoolCallbackScheduled( queryId, poolAddress, timeout, gasLimit,
                                    etherFundsTransferedForGas );

        // Return a query ID.
        return queryId;
    }


    /** PAYABLE [ OUT ] >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
     *
     *  Sends the specified amount of Ether back to the Pool.
     *  WARNING: Future Provable requests might fail due to insufficient
     *           funds! No checks are made to ensure sufficiency.
     */
    function sendFundsToPool( uint etherAmount )
                                                        external
                                                        poolOnly
    {
        poolAddress.transfer( etherAmount );
    }


    /**
     *  Set the gas price to be used for future Provable queries.
     *  Used to change the default gas in times of congested networks.
     */
    function setGasPrice( uint _gasPrice )
                                                        external
                                                        poolOnly
    {
        // Limit gas price to 600 GWei.
        require( _gasPrice <= 600 * (10 ** 9) );

        provable_setCustomGasPrice( _gasPrice );
    }

}



