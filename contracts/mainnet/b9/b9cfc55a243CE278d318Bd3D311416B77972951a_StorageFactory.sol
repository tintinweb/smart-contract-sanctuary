// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./MinedUniswapLottery.sol";
import "./LotteryStub.sol";


/**
 *  The Factory contract, used to deploy new Lottery Storage contracts.
 *  Every Lottery must have exactly one Storage, which is used by the
 *  main Lottery token contract, to store holder data, and on ending, to
 *  execute the winner selection and prize distribution -
 *  these operations are done in LotteryStorage contract functions.
 */
contract UniLotteryStorageFactory
{
    // The Pool Address.
    address payable poolAddress;

    // The Delegate Logic contract, containing all code for
    // all LotteryStorage contracts to be deployed.
    address immutable delegateContract;

    // Pool-Only modifier.
    modifier poolOnly 
    {
        require( msg.sender == poolAddress );
        _;
    }

    // Constructor.
    // Deploy the Delegate Contract here.
    //
    constructor()       public
    {
        delegateContract = address( new LotteryStorage() );
    }

    // Initialization function.
    // Set the poolAddress as msg.sender, and lock it.
    function initialize()
                                                            external
    {
        require( poolAddress == address( 0 ) );

        // Set the Pool's Address.
        poolAddress = msg.sender;
    }

    /**
     * Deploy a new Lottery Storage Stub, to be used by it's corresponding
     * Lottery Stub, which will be created later, passing this Storage
     * we create here.
     *  @return newStorage - the Lottery Storage Stub contract just deployed.
     */
    function createNewStorage()
                                                            public
                                                            poolOnly
    returns( address newStorage )
    {
        return address( new LotteryStorageStub( delegateContract ) );
    }
}



