// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.6.11;
pragma experimental ABIEncoderV2;

import "./MinedUniswapLottery.sol";


/**
 *  This is a storage-stub contract of the Lottery Token, which contains
 *  only the state (storage) of a Lottery Token, and delegates all logic
 *  to the actual code implementation.
 *  This approach is very gas-efficient for deploying new lotteries.
 */
contract LotteryStub 
{
    // ============ ERC20 token contract's storage ============ //

    // ------- Slot ------- //

    // Balances of token holders.
    mapping (address => uint256) private _balances;

    // ------- Slot ------- //

    // Allowances of spenders for a specific token owner.
    mapping (address => mapping (address => uint256)) private _allowances;

    // ------- Slot ------- //

    // Total supply of the token.
    uint256 private _totalSupply;


    // ============== Lottery contract's storage ============== //

    // ------- Initial Slots ------- //

    // The config which is passed to constructor.
    Lottery.LotteryConfig internal cfg;

    // ------- Slot ------- //

    // The Lottery Storage contract, which stores all holder data,
    // such as scores, referral tree data, etc.
    LotteryStorage /*public*/ lotStorage;

    // ------- Slot ------- //

    // Pool address. Set on constructor from msg.sender.
    address payable /*public*/ poolAddress;

    // ------- Slot ------- //
    
    // Randomness Provider address.
    address /*public*/ randomnessProvider;

    // ------- Slot ------- //

    // Exchange address. In Uniswap mode, it's the Uniswap liquidity 
    // pair's address, where trades execute.
    address /*public*/ exchangeAddress;

    // Start date.
    uint32 /*public*/ startDate;

    // Completion (Mining Phase End) date.
    uint32 /*public*/ completionDate;
    
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
    uint8 /*public*/ lotteryStage;
    
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
    uint128 /*public*/ ending_totalReturn;
    uint128 /*public*/ ending_profitAmount;

    // ------- Slot ------- //

    // The mapping that contains TRUE for addresses that already claimed
    // their lottery winner prizes.
    // Used only in COMPLETION, on claimWinnerPrize(), to check if
    // msg.sender has already claimed his prize.
    mapping( address => bool ) /*public*/ prizeClaimersAddresses;



    // =================== OUR CONTRACT'S OWN STORAGE =================== //

    // The address of the delegate contract, containing actual logic.
    address payable immutable public __delegateContract;


    // ===================          Functions         =================== //

    // Constructor.
    // Just set the delegate's address.
    constructor( address payable _delegateAddr )
                                                        public
    {
        __delegateContract = _delegateAddr;
    }

    // Fallback payable function, which delegates any call to our
    // contract, into the delegate contract.
    fallback()
                external payable 
    {
        // DelegateCall the delegate code contract.
        ( bool success, bytes memory data ) =
            __delegateContract.delegatecall( msg.data );

        // Use inline assembly to be able to return value from the fallback.
        // (by default, returning a value from fallback is not possible,
        // but it's still possible to manually copy data to the
        // return buffer.
        assembly
        {
            // delegatecall returns 0 (false) on error.
            // Add 32 bytes to "data" pointer, because first slot (32 bytes)
            // contains the length, and we use return value's length
            // from returndatasize() opcode.
            switch success
                case 0  { revert( add( data, 32 ), returndatasize() ) }
                default { return( add( data, 32 ), returndatasize() ) }
        }
    }

    // Receive ether function.
    receive()   external payable
    { }

}


/**
 *  LotteryStorage contract's storage-stub.
 *  Uses delagate calls to execute actual code on this contract's behalf.
 */
contract LotteryStorageStub
{
    // =============== LotteryStorage contract's storage ================ //

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
    LotteryStorage.WinnerAlgorithmConfig algConfig;

    // --------- Slot --------- //

    // The Min-Max holder score storage.
    LotteryStorage.MinMaxHolderScores minMaxScores;

    // --------- Slot --------- //

    // Array of holders.
    address[] /*public*/ holders;

    // --------- Slot --------- //

    // Holder array indexes mapping, for O(1) array element access.
    mapping( address => uint ) holderIndexes;

    // --------- Slot --------- //

    // Mapping of holder data.
    mapping( address => LotteryStorage.HolderData ) /*public*/ holderData;

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
    LotteryStorage.WinnerIndexStruct[] sortedWinnerIndexes;


    // =================== OUR CONTRACT'S OWN STORAGE =================== //

    // The address of the delegate contract, containing actual logic.
    address immutable public __delegateContract;


    // ===================          Functions         =================== //

    // Constructor.
    // Just set the delegate's address.
    constructor( address _delegateAddr )
                                                        public
    {
        __delegateContract = _delegateAddr;
    }

    // Fallback function, which delegates any call to our
    // contract, into the delegate contract.
    fallback()
                external
    {
        // DelegateCall the delegate code contract.
        ( bool success, bytes memory data ) =
            __delegateContract.delegatecall( msg.data );

        // Use inline assembly to be able to return value from the fallback.
        // (by default, returning a value from fallback is not possible,
        // but it's still possible to manually copy data to the
        // return buffer.
        assembly
        {
            // delegatecall returns 0 (false) on error.
            // Add 32 bytes to "data" pointer, because first slot (32 bytes)
            // contains the length, and we use return value's length
            // from returndatasize() opcode.
            switch success
                case 0  { revert( add( data, 32 ), returndatasize() ) }
                default { return( add( data, 32 ), returndatasize() ) }
        }
    }
}



