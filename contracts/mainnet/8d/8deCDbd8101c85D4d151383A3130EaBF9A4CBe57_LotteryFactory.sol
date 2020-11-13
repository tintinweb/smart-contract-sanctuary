// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./MinedUniswapLottery.sol";
import "./StorageFactory.sol";
import "./LotteryStub.sol";


/**
 *  Little contract to use in testing environments, to get the
 *  ABIEncoderV2-encoded js object representing LotteryConfig.
 */
contract UniLotteryConfigGenerator
{
    function getConfig()
                                                    external pure
    returns( Lottery.LotteryConfig memory cfg )
    {
        cfg.initialFunds = 10 ether;
    }
}


/**
 *  This is the Lottery Factory contract, which is used as an intermediate
 *  for deploying new lotteries from the UniLottery main pool.
 *  
 *  This pattern was chosen to avoid the code bloat of the Main Pool
 *  contract - this way, the "new Lottery()" huge bloat statements would
 *  be executed in this Factory, not in the Main Pool.
 *  So, the Main Pool would stay in the 24 kB size limit.
 *
 *  The only drawback, is that 2 contracts would need to be manually
 *  deployed at the start - firstly, this Factory, and secondly, the
 *  Main Pool, passing this Factory instance's address to it's constructor.
 *
 *  The deployment sequence should go like this:
 *  1. Deploy UniLotteryLotteryFactory.
 *  2. Deploy MainUniLotteryPool, passing instance address from step (1)
 *      to it's constructor.
 *  3. [internal operation] MainUniLotteryPool's constructor calls
 *      the initialize() function of the Factory instance it got,
 *      and the Factory instance sets it's pool address and locks it
 *      with initializationFinished boolean.
 */
contract UniLotteryLotteryFactory
{
    // Uniswap Router address on this network - passed to Lotteries on
    // construction.
    //ddress payable immutable uniRouterAddress;

    // Delegate Contract for the Lottery, containing all logic code
    // needed for deploying LotteryStubs.
    // Deployed only once, on construction.
    address payable immutable delegateContract;

    // The Pool Address.
    address payable poolAddress;

    // The Lottery Storage Factory address, that the Lottery contracts use.
    UniLotteryStorageFactory lotteryStorageFactory;


    // Pool-Only modifier.
    modifier poolOnly 
    {
        require( msg.sender == poolAddress );
        _;
    }

    // Constructor.
    // Set the Uniswap Address, and deploy&lock the Delegate Code contract.
    //
    constructor( /*address payable _uniRouter*/ )       public
    {
        //uniRouterAddress = _uniRouter;
        delegateContract = address( uint160( address( new Lottery() ) ) );
    }

    // Initialization function.
    // Set the poolAddress as msg.sender, and lock it.
    // Also, set the Lottery Storage Factory contract instance address.
    function initialize( address _storageFactoryAddress )
                                                            external
    {
        require( poolAddress == address( 0 ) );

        // Set the Pool's Address.
        // Lock it. No more calls to this function will be executed.
        poolAddress = msg.sender;

        // Set the Storage Factory, and initialize it!
        lotteryStorageFactory = 
            UniLotteryStorageFactory( _storageFactoryAddress );

        lotteryStorageFactory.initialize();
    }

    /**
     * Deploy a new Lottery Stub from the specified config.
     *  @param config - Lottery Config to be used (passed by the pool).
     *  @return newLottery - the newly deployed lottery stub.
     */
    function createNewLottery( 
            Lottery.LotteryConfig memory config,
            address randomnessProvider )
                                                            public
                                                            poolOnly
    returns( address payable newLottery )
    {
        // Create new Lottery Storage, using storage factory.
        // Populate the stub, by calling the "construct" function.
        LotteryStub stub = new LotteryStub( delegateContract );

        Lottery( address( stub ) ).construct(
                config, poolAddress, randomnessProvider,
                lotteryStorageFactory.createNewStorage() );

        return address( stub );
    }

}



