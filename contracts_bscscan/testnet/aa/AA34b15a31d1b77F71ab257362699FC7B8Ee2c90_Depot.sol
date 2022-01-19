/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       Depot.sol
version:    3.0
author:     Kevin Brown
date:       2018-10-23

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

Depot contract. The Depot provides
a way for users to acquire synths (Synth.sol) and SNX
(Synthetix.sol) by paying ETH and a way for users to acquire SNX
(Synthetix.sol) by paying synths. Users can also deposit their synths
and allow other users to purchase them with ETH. The ETH is sent
to the user who offered their synths for sale.

This smart contract contains a balance of each token, and
allows the owner of the contract (the Synthetix Foundation) to
manage the available balance of synthetix at their discretion, while
users are allowed to deposit and withdraw their own synth deposits
if they have not yet been taken up by another user.

-----------------------------------------------------------------
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./SelfDestructible.sol";
import "./Pausable.sol";
import "./SafeDecimalMath.sol";
import "./ISynthetix.sol";
import "./ISynth.sol";
import "./IFeePool.sol";

/**
 * @title Depot Contract.
 */
contract Depot is SelfDestructible, Pausable {
    using SafeMath for uint;
    using SafeDecimalMath for uint;

    /* ========== STATE VARIABLES ========== */
    ISynthetix public synthetix;
    ISynth public synth;
    IFeePool public feePool;

    // Address where the ether and Synths raised for selling SNX is transfered to
    // Any ether raised for selling Synths gets sent back to whoever deposited the Synths,
    // and doesn't have anything to do with this address.
    address public fundsWallet;

    /* The address of the oracle which pushes the USD price SNX and ether to this contract */
    address public oracle;
    /* Do not allow the oracle to submit times any further forward into the future than
       this constant. */
    uint public constant ORACLE_FUTURE_LIMIT = 10 minutes;

    /* How long will the contract assume the price of any asset is correct */
    uint public priceStalePeriod = 3 hours;

    /* The time the prices were last updated */
    uint public lastPriceUpdateTime;
    /* The USD price of SNX denominated in UNIT */
    uint public usdToSnxPrice;
    /* The USD price of ETH denominated in UNIT */
    uint public usdToEthPrice;

    /* Stores deposits from users. */
    struct synthDeposit {
        // The user that made the deposit
        address user;
        // The amount (in Synths) that they deposited
        uint amount;
    }

    /* User deposits are sold on a FIFO (First in First out) basis. When users deposit
       synths with us, they get added this queue, which then gets fulfilled in order.
       Conceptually this fits well in an array, but then when users fill an order we
       end up copying the whole array around, so better to use an index mapping instead
       for gas performance reasons.

       The indexes are specified (inclusive, exclusive), so (0, 0) means there's nothing
       in the array, and (3, 6) means there are 3 elements at 3, 4, and 5. You can obtain
       the length of the "array" by querying depositEndIndex - depositStartIndex. All index
       operations use safeAdd, so there is no way to overflow, so that means there is a
       very large but finite amount of deposits this contract can handle before it fills up. */
    mapping(uint => synthDeposit) public deposits;
    // The starting index of our queue inclusive
    uint public depositStartIndex;
    // The ending index of our queue exclusive
    uint public depositEndIndex;

    /* This is a convenience variable so users and dApps can just query how much sUSD
       we have available for purchase without having to iterate the mapping with a
       O(n) amount of calls for something we'll probably want to display quite regularly. */
    uint public totalSellableDeposits;

    // The minimum amount of sUSD required to enter the FiFo queue
    uint public minimumDepositAmount = 50 * SafeDecimalMath.unit();

    // If a user deposits a synth amount < the minimumDepositAmount the contract will keep
    // the total of small deposits which will not be sold on market and the sender
    // must call withdrawMyDepositedSynths() to get them back.
    mapping(address => uint) public smallDeposits;


    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev Constructor
     * @param _owner The owner of this contract.
     * @param _fundsWallet The recipient of ETH and Synths that are sent to this contract while exchanging.
     * @param _synthetix The Synthetix contract we'll interact with for balances and sending.
     * @param _synth The Synth contract we'll interact with for balances and sending.
     * @param _oracle The address which is able to update price information.
     * @param _usdToEthPrice The current price of ETH in USD, expressed in UNIT.
     * @param _usdToSnxPrice The current price of Synthetix in USD, expressed in UNIT.
     */
    constructor(
        // Ownable
        address _owner,

        // Funds Wallet
        address _fundsWallet,

        // Other contracts needed
        ISynthetix _synthetix,
        ISynth _synth,
		IFeePool _feePool,

        // Oracle values - Allows for price updates
        address _oracle,
        uint _usdToEthPrice,
        uint _usdToSnxPrice
    )
        /* Owned is initialised in SelfDestructible */
        SelfDestructible(_owner)
        Pausable()
    {
        fundsWallet = _fundsWallet;
        synthetix = _synthetix;
        synth = _synth;
        feePool = _feePool;
        oracle = _oracle;
        usdToEthPrice = _usdToEthPrice;
        usdToSnxPrice = _usdToSnxPrice;
        lastPriceUpdateTime = block.timestamp;
    }

    /* ========== SETTERS ========== */

    /**
     * @notice Set the funds wallet where ETH raised is held
     * @param _fundsWallet The new address to forward ETH and Synths to
     */
    function setFundsWallet(address _fundsWallet)
        external
        onlyOwner
    {
        fundsWallet = _fundsWallet;
        emit FundsWalletUpdated(fundsWallet);
    }

    /**
     * @notice Set the Oracle that pushes the synthetix price to this contract
     * @param _oracle The new oracle address
     */
    function setOracle(address _oracle)
        external
        onlyOwner
    {
        oracle = _oracle;
        emit OracleUpdated(oracle);
    }

    /**
     * @notice Set the Synth contract that the issuance controller uses to issue Synths.
     * @param _synth The new synth contract target
     */
    function setSynth(ISynth _synth)
        external
        onlyOwner
    {
        synth = _synth;
        emit SynthUpdated(_synth);
    }

    /**
     * @notice Set the Synthetix contract that the issuance controller uses to issue SNX.
     * @param _synthetix The new synthetix contract target
     */
    function setSynthetix(ISynthetix _synthetix)
        external
        onlyOwner
    {
        synthetix = _synthetix;
        emit SynthetixUpdated(_synthetix);
    }

    /**
     * @notice Set the stale period on the updated price variables
     * @param _time The new priceStalePeriod
     */
    function setPriceStalePeriod(uint _time)
        external
        onlyOwner
    {
        priceStalePeriod = _time;
        emit PriceStalePeriodUpdated(priceStalePeriod);
    }

    /**
     * @notice Set the minimum deposit amount required to depoist sUSD into the FIFO queue
     * @param _amount The new new minimum number of sUSD required to deposit
     */
    function setMinimumDepositAmount(uint _amount)
        external
        onlyOwner
    {
        // Do not allow us to set it less than 1 dollar opening up to fractional desposits in the queue again
        require(_amount > SafeDecimalMath.unit(), "Minimum deposit amount must be greater than UNIT");
        minimumDepositAmount = _amount;
        emit MinimumDepositAmountUpdated(minimumDepositAmount);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    /**
     * @notice Access point for the oracle to update the prices of SNX / eth.
     * @param newEthPrice The current price of ether in USD, specified to 18 decimal places.
     * @param newSynthetixPrice The current price of SNX in USD, specified to 18 decimal places.
     * @param timeSent The timestamp from the oracle when the transaction was created. This ensures we don't consider stale prices as current in times of heavy network congestion.
     */
    function updatePrices(uint newEthPrice, uint newSynthetixPrice, uint timeSent)
        external
        onlyOracle
    {
        /* Must be the most recently sent price, but not too far in the future.
         * (so we can't lock ourselves out of updating the oracle for longer than this) */
        require(lastPriceUpdateTime < timeSent, "Time must be later than last update");
        require(timeSent < (block.timestamp + ORACLE_FUTURE_LIMIT), "Time must be less than now + ORACLE_FUTURE_LIMIT");

        usdToEthPrice = newEthPrice;
        usdToSnxPrice = newSynthetixPrice;
        lastPriceUpdateTime = timeSent;

        emit PricesUpdated(usdToEthPrice, usdToSnxPrice, lastPriceUpdateTime);
    }

    /**
     * @notice Fallback function (exchanges ETH to sUSD)
     */
    fallback()
        external
        payable
    {
        exchangeEtherForSynths();
    }

    /**
     * @notice Exchange ETH to sUSD.
     */
    function exchangeEtherForSynths()
        public
        payable
        pricesNotStale
        notPaused
        returns (uint) // Returns the number of Synths (sUSD) received
    {
        uint ethToSend;

        // The multiplication works here because usdToEthPrice is specified in
        // 18 decimal places, just like our currency base.
        uint requestedToPurchase = msg.value.multiplyDecimal(usdToEthPrice);
        uint remainingToFulfill = requestedToPurchase;

        // Iterate through our outstanding deposits and sell them one at a time.
        for (uint i = depositStartIndex; remainingToFulfill > 0 && i < depositEndIndex; i++) {
            synthDeposit memory deposit = deposits[i];

            // If it's an empty spot in the queue from a previous withdrawal, just skip over it and
            // update the queue. It's already been deleted.
            if (deposit.user == address(0)) {

                depositStartIndex = depositStartIndex.add(1);
            } else {
                // If the deposit can more than fill the order, we can do this
                // without touching the structure of our queue.
                if (deposit.amount > remainingToFulfill) {

                    // Ok, this deposit can fulfill the whole remainder. We don't need
                    // to change anything about our queue we can just fulfill it.
                    // Subtract the amount from our deposit and total.
                    uint newAmount = deposit.amount.sub(remainingToFulfill);
                    deposits[i] = synthDeposit({ user: deposit.user, amount: newAmount});

                    totalSellableDeposits = totalSellableDeposits.sub(remainingToFulfill);

                    // Transfer the ETH to the depositor. Send is used instead of transfer
                    // so a non payable contract won't block the FIFO queue on a failed
                    // ETH payable for synths transaction. The proceeds to be sent to the
                    // synthetix foundation funds wallet. This is to protect all depositors
                    // in the queue in this rare case that may occur.
                    ethToSend = remainingToFulfill.divideDecimal(usdToEthPrice);

                    // We need to use send here instead of transfer because transfer reverts
                    // if the recipient is a non-payable contract. Send will just tell us it
                    // failed by returning false at which point we can continue.
                    // solium-disable-next-line security/no-send
                    if(!payable(deposit.user).send(ethToSend)) {
                        payable(fundsWallet).transfer(ethToSend);
                        emit NonPayableContract(deposit.user, ethToSend);
                    } else {
                        emit ClearedDeposit(msg.sender, deposit.user, ethToSend, remainingToFulfill, i);
                    }

                    // And the Synths to the recipient.
                    // Note: Fees are calculated by the Synth contract, so when
                    //       we request a specific transfer here, the fee is
                    //       automatically deducted and sent to the fee pool.
                    synth.transfer(msg.sender, remainingToFulfill);

                    // And we have nothing left to fulfill on this order.
                    remainingToFulfill = 0;
                } else if (deposit.amount <= remainingToFulfill) {
                    // We need to fulfill this one in its entirety and kick it out of the queue.
                    // Start by kicking it out of the queue.
                    // Free the storage because we can.
                    delete deposits[i];
                    // Bump our start index forward one.
                    depositStartIndex = depositStartIndex.add(1);
                    // We also need to tell our total it's decreased
                    totalSellableDeposits = totalSellableDeposits.sub(deposit.amount);

                    // Now fulfill by transfering the ETH to the depositor. Send is used instead of transfer
                    // so a non payable contract won't block the FIFO queue on a failed
                    // ETH payable for synths transaction. The proceeds to be sent to the
                    // synthetix foundation funds wallet. This is to protect all depositors
                    // in the queue in this rare case that may occur.
                    ethToSend = deposit.amount.divideDecimal(usdToEthPrice);

                    // We need to use send here instead of transfer because transfer reverts
                    // if the recipient is a non-payable contract. Send will just tell us it
                    // failed by returning false at which point we can continue.
                    // solium-disable-next-line security/no-send
                    if(!payable(deposit.user).send(ethToSend)) {
                        payable(fundsWallet).transfer(ethToSend);
                        emit NonPayableContract(deposit.user, ethToSend);
                    } else {
                        emit ClearedDeposit(msg.sender, deposit.user, ethToSend, deposit.amount, i);
                    }

                    // And the Synths to the recipient.
                    // Note: Fees are calculated by the Synth contract, so when
                    //       we request a specific transfer here, the fee is
                    //       automatically deducted and sent to the fee pool.
                    synth.transfer(msg.sender, deposit.amount);

                    // And subtract the order from our outstanding amount remaining
                    // for the next iteration of the loop.
                    remainingToFulfill = remainingToFulfill.sub(deposit.amount);
                }
            }
        }

        // Ok, if we're here and 'remainingToFulfill' isn't zero, then
        // we need to refund the remainder of their ETH back to them.
        if (remainingToFulfill > 0) {
            payable(msg.sender).transfer(remainingToFulfill.divideDecimal(usdToEthPrice));
        }

        // How many did we actually give them?
        uint fulfilled = requestedToPurchase.sub(remainingToFulfill);

        if (fulfilled > 0) {
            // Now tell everyone that we gave them that many (only if the amount is greater than 0).
            emit Exchange("ETH", msg.value, "sUSD", fulfilled);
        }

        return fulfilled;
    }

    /**
     * @notice Exchange ETH to sUSD while insisting on a particular rate. This allows a user to
     *         exchange while protecting against frontrunning by the contract owner on the exchange rate.
     * @param guaranteedRate The exchange rate (ether price) which must be honored or the call will revert.
     */
    function exchangeEtherForSynthsAtRate(uint guaranteedRate)
        public
        payable
        pricesNotStale
        notPaused
        returns (uint) // Returns the number of Synths (sUSD) received
    {
        require(guaranteedRate == usdToEthPrice, "Guaranteed rate would not be received");

        return exchangeEtherForSynths();
    }


    /**
     * @notice Exchange ETH to SNX.
     */
    function exchangeEtherForSynthetix()
        public
        payable
        pricesNotStale
        notPaused
        returns (uint) // Returns the number of SNX received
    {
        // How many SNX are they going to be receiving?
        uint synthetixToSend = synthetixReceivedForEther(msg.value);

        // Store the ETH in our funds wallet
        payable(fundsWallet).transfer(msg.value);

        // And send them the SNX.
        synthetix.transfer(msg.sender, synthetixToSend);

        emit Exchange("ETH", msg.value, "SNX", synthetixToSend);

        return synthetixToSend;
    }

    /**
     * @notice Exchange ETH to SNX while insisting on a particular set of rates. This allows a user to
     *         exchange while protecting against frontrunning by the contract owner on the exchange rates.
     * @param guaranteedEtherRate The ether exchange rate which must be honored or the call will revert.
     * @param guaranteedSynthetixRate The synthetix exchange rate which must be honored or the call will revert.
     */
    function exchangeEtherForSynthetixAtRate(uint guaranteedEtherRate, uint guaranteedSynthetixRate)
        public
        payable
        pricesNotStale
        notPaused
        returns (uint) // Returns the number of SNX received
    {
        require(guaranteedEtherRate == usdToEthPrice, "Guaranteed ether rate would not be received");
        require(guaranteedSynthetixRate == usdToSnxPrice, "Guaranteed synthetix rate would not be received");

        return exchangeEtherForSynthetix();
    }


    /**
     * @notice Exchange sUSD for SNX
     * @param synthAmount The amount of synths the user wishes to exchange.
     */
    function exchangeSynthsForSynthetix(uint synthAmount)
        public
        pricesNotStale
        notPaused
        returns (uint) // Returns the number of SNX received
    {
        // How many SNX are they going to be receiving?
        uint synthetixToSend = synthetixReceivedForSynths(synthAmount);

        // Ok, transfer the Synths to our funds wallet.
        // These do not go in the deposit queue as they aren't for sale as such unless
        // they're sent back in from the funds wallet.
        synth.transferFrom(msg.sender, fundsWallet, synthAmount);

        // And send them the SNX.
        synthetix.transfer(msg.sender, synthetixToSend);

        emit Exchange("sUSD", synthAmount, "SNX", synthetixToSend);

        return synthetixToSend;
    }

    /**
     * @notice Exchange sUSD for SNX while insisting on a particular rate. This allows a user to
     *         exchange while protecting against frontrunning by the contract owner on the exchange rate.
     * @param synthAmount The amount of synths the user wishes to exchange.
     * @param guaranteedRate A rate (synthetix price) the caller wishes to insist upon.
     */
    function exchangeSynthsForSynthetixAtRate(uint synthAmount, uint guaranteedRate)
        public
        pricesNotStale
        notPaused
        returns (uint) // Returns the number of SNX received
    {
        require(guaranteedRate == usdToSnxPrice, "Guaranteed rate would not be received");

        return exchangeSynthsForSynthetix(synthAmount);
    }

    /**
     * @notice Allows the owner to withdraw SNX from this contract if needed.
     * @param amount The amount of SNX to attempt to withdraw (in 18 decimal places).
     */
    function withdrawSynthetix(uint amount)
        external
        onlyOwner
    {
        synthetix.transfer(owner, amount);

        // We don't emit our own events here because we assume that anyone
        // who wants to watch what the Issuance Controller is doing can
        // just watch ERC20 events from the Synth and/or Synthetix contracts
        // filtered to our address.
    }

    /**
     * @notice Allows a user to withdraw all of their previously deposited synths from this contract if needed.
     *         Developer note: We could keep an index of address to deposits to make this operation more efficient
     *         but then all the other operations on the queue become less efficient. It's expected that this
     *         function will be very rarely used, so placing the inefficiency here is intentional. The usual
     *         use case does not involve a withdrawal.
     */
    function withdrawMyDepositedSynths()
        external
    {
        uint synthsToSend = 0;

        for (uint i = depositStartIndex; i < depositEndIndex; i++) {
            synthDeposit memory deposit = deposits[i];

            if (deposit.user == msg.sender) {
                // The user is withdrawing this deposit. Remove it from our queue.
                // We'll just leave a gap, which the purchasing logic can walk past.
                synthsToSend = synthsToSend.add(deposit.amount);
                delete deposits[i];
                //Let the DApps know we've removed this deposit
                emit SynthDepositRemoved(deposit.user, deposit.amount, i);
            }
        }

        // Update our total
        totalSellableDeposits = totalSellableDeposits.sub(synthsToSend);

        // Check if the user has tried to send deposit amounts < the minimumDepositAmount to the FIFO
        // queue which would have been added to this mapping for withdrawal only
        synthsToSend = synthsToSend.add(smallDeposits[msg.sender]);
        smallDeposits[msg.sender] = 0;

        // If there's nothing to do then go ahead and revert the transaction
        require(synthsToSend > 0, "You have no deposits to withdraw.");

        // Send their deposits back to them (minus fees)
        synth.transfer(msg.sender, synthsToSend);

        emit SynthWithdrawal(msg.sender, synthsToSend);
    }

    /**
     * @notice depositSynths: Allows users to deposit synths via the approve / transferFrom workflow
     *         if they'd like. You can equally just transfer synths to this contract and it will work
     *         exactly the same way but with one less call (and therefore cheaper transaction fees)
     * @param amount The amount of sUSD you wish to deposit (must have been approved first)
     */
    function depositSynths(uint amount)
        external
    {
        // Grab the amount of synths
        synth.transferFrom(msg.sender, payable(this), amount);

        // Note, we don't need to add them to the deposit list below, as the Synth contract itself will
        // call tokenFallback when the transfer happens, adding their deposit to the queue.
    }

    /**
     * @notice Triggers when users send us SNX or sUSD, but the modifier only allows sUSD calls to proceed.
     * @param from The address sending the sUSD
     * @param amount The amount of sUSD
     */
    function tokenFallback(address from, uint amount, bytes memory data)
        external
        onlySynth
        returns (bool)
    {
        // A minimum deposit amount is designed to protect purchasers from over paying
        // gas for fullfilling multiple small synth deposits
        if (amount < minimumDepositAmount) {
            // We cant fail/revert the transaction or send the synths back in a reentrant call.
            // So we will keep your synths balance seperate from the FIFO queue so you can withdraw them
            smallDeposits[from] = smallDeposits[from].add(amount);

            emit SynthDepositNotAccepted(from, amount, minimumDepositAmount);
        } else {
            // Ok, thanks for the deposit, let's queue it up.
            deposits[depositEndIndex] = synthDeposit({ user: from, amount: amount });
            emit SynthDeposit(from, amount, depositEndIndex);

            // Walk our index forward as well.
            depositEndIndex = depositEndIndex.add(1);

            // And add it to our total.
            totalSellableDeposits = totalSellableDeposits.add(amount);
        }
    }

    /* ========== VIEWS ========== */
    /**
     * @notice Check if the prices haven't been updated for longer than the stale period.
     */
    function pricesAreStale()
        public
        view
        returns (bool)
    {
        return lastPriceUpdateTime.add(priceStalePeriod) < block.timestamp;
    }

    /**
     * @notice Calculate how many SNX you will receive if you transfer
     *         an amount of synths.
     * @param amount The amount of synths (in 18 decimal places) you want to ask about
     */
    function synthetixReceivedForSynths(uint amount)
        public
        view
        returns (uint)
    {
        // How many synths would we receive after the transfer fee?
        uint synthsReceived = feePool.amountReceivedFromTransfer(amount);

        // And what would that be worth in SNX based on the current price?
        return synthsReceived.divideDecimal(usdToSnxPrice);
    }

    /**
     * @notice Calculate how many SNX you will receive if you transfer
     *         an amount of ether.
     * @param amount The amount of ether (in wei) you want to ask about
     */
    function synthetixReceivedForEther(uint amount)
        public
        view
        returns (uint)
    {
        // How much is the ETH they sent us worth in sUSD (ignoring the transfer fee)?
        uint valueSentInSynths = amount.multiplyDecimal(usdToEthPrice);

        // Now, how many SNX will that USD amount buy?
        return synthetixReceivedForSynths(valueSentInSynths);
    }

    /**
     * @notice Calculate how many synths you will receive if you transfer
     *         an amount of ether.
     * @param amount The amount of ether (in wei) you want to ask about
     */
    function synthsReceivedForEther(uint amount)
        public
        view
        returns (uint)
    {
        // How many synths would that amount of ether be worth?
        uint synthsTransferred = amount.multiplyDecimal(usdToEthPrice);

        // And how many of those would you receive after a transfer (deducting the transfer fee)
        return feePool.amountReceivedFromTransfer(synthsTransferred);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyOracle
    {
        require(msg.sender == oracle, "Only the oracle can perform this action");
        _;
    }

    modifier onlySynth
    {
        // We're only interested in doing anything on receiving sUSD.
        require(msg.sender == address(synth), "Only the synth contract can perform this action");
        _;
    }

    modifier pricesNotStale
    {
        require(!pricesAreStale(), "Prices must not be stale to perform this action");
        _;
    }

    /* ========== EVENTS ========== */

    event FundsWalletUpdated(address newFundsWallet);
    event OracleUpdated(address newOracle);
    event SynthUpdated(ISynth newSynthContract);
    event SynthetixUpdated(ISynthetix newSynthetixContract);
    event PriceStalePeriodUpdated(uint priceStalePeriod);
    event PricesUpdated(uint newEthPrice, uint newSynthetixPrice, uint timeSent);
    event Exchange(string fromCurrency, uint fromAmount, string toCurrency, uint toAmount);
    event SynthWithdrawal(address user, uint amount);
    event SynthDeposit(address indexed user, uint amount, uint indexed depositIndex);
    event SynthDepositRemoved(address indexed user, uint amount, uint indexed depositIndex);
    event SynthDepositNotAccepted(address user, uint amount, uint minimum);
    event MinimumDepositAmountUpdated(uint amount);
    event NonPayableContract(address indexed receiver, uint amount);
    event ClearedDeposit(address indexed fromAddress, address indexed toAddress, uint fromETHAmount, uint toAmount, uint indexed depositIndex);
}

/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       SelfDestructible.sol
version:    1.2
author:     Anton Jurisevic

date:       2018-05-29

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

This contract allows an inheriting contract to be destroyed after
its owner indicates an intention and then waits for a period
without changing their mind. All ether contained in the contract
is forwarded to a nominated beneficiary upon destruction.

-----------------------------------------------------------------
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import "./Owned.sol";


/**
 * @title A contract that can be destroyed by its owner after a delay elapses.
 */
contract SelfDestructible is Owned {
    
    uint public initiationTime;
    bool public selfDestructInitiated;
    address public selfDestructBeneficiary;
    uint public constant SELFDESTRUCT_DELAY = 4 weeks;

    /**
     * @dev Constructor
     * @param _owner The account which controls this contract.
     */
    constructor(address _owner)
        Owned(_owner)
    {
        require(_owner != address(0), "Owner must not be the zero address");
        selfDestructBeneficiary = _owner;
        emit SelfDestructBeneficiaryUpdated(_owner);
    }

    /**
     * @notice Set the beneficiary address of this contract.
     * @dev Only the contract owner may call this. The provided beneficiary must be non-null.
     * @param _beneficiary The address to pay any eth contained in this contract to upon self-destruction.
     */
    function setSelfDestructBeneficiary(address _beneficiary)
        external
        onlyOwner
    {
        require(_beneficiary != address(0), "Beneficiary must not be the zero address");
        selfDestructBeneficiary = _beneficiary;
        emit SelfDestructBeneficiaryUpdated(_beneficiary);
    }

    /**
     * @notice Begin the self-destruction counter of this contract.
     * Once the delay has elapsed, the contract may be self-destructed.
     * @dev Only the contract owner may call this.
     */
    function initiateSelfDestruct()
        external
        onlyOwner
    {
        initiationTime = block.timestamp;
        selfDestructInitiated = true;
        emit SelfDestructInitiated(SELFDESTRUCT_DELAY);
    }

    /**
     * @notice Terminate and reset the self-destruction timer.
     * @dev Only the contract owner may call this.
     */
    function terminateSelfDestruct()
        external
        onlyOwner
    {
        initiationTime = 0;
        selfDestructInitiated = false;
        emit SelfDestructTerminated();
    }

    /**
     * @notice If the self-destruction delay has elapsed, destroy this contract and
     * remit any ether it owns to the beneficiary address.
     * @dev Only the contract owner may call this.
     */
    function selfDestruct()
        external
        onlyOwner
    {
        require(selfDestructInitiated, "Self destruct has not yet been initiated");
        require(initiationTime + SELFDESTRUCT_DELAY < block.timestamp, "Self destruct delay has not yet elapsed");
        address beneficiary = selfDestructBeneficiary;
        emit SelfDestructed(beneficiary);
        selfdestruct(payable(beneficiary));
    }

    event SelfDestructTerminated();
    event SelfDestructed(address beneficiary);
    event SelfDestructInitiated(uint selfDestructDelay);
    event SelfDestructBeneficiaryUpdated(address newBeneficiary);
}

/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       Pausable.sol
version:    1.0
author:     Kevin Brown

date:       2018-05-22

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

This contract allows an inheriting contract to be marked as
paused. It also defines a modifier which can be used by the
inheriting contract to prevent actions while paused.

-----------------------------------------------------------------
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


import "./Owned.sol";


/**
 * @title A contract that can be paused by its owner
 */
abstract contract Pausable is Owned {
    
    uint public lastPauseTime;
    bool public paused;

    /**
     * @dev Constructor
     */
    constructor()
    {
        // This contract is abstract, and thus cannot be instantiated directly
        require(owner != address(0), "Owner must be set");
        // Paused will be false, and lastPauseTime will be 0 upon initialisation
    }

    /**
     * @notice Change the paused state of the contract
     * @dev Only the contract owner may call this.
     */
    function setPaused(bool _paused)
        external
        onlyOwner
    {
        // Ensure we're actually changing the state before we do anything
        if (_paused == paused) {
            return;
        }

        // Set our paused state.
        paused = _paused;
        
        // If applicable, set the last pause time.
        if (paused) {
            lastPauseTime = block.timestamp;
        }

        // Let everyone know that our pause state has changed.
        emit PauseChanged(paused);
    }

    event PauseChanged(bool isPaused);

    modifier notPaused {
        require(!paused, "This action cannot be performed while the contract is paused");
        _;
    }
}

/*

-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       SafeDecimalMath.sol
version:    2.0
author:     Kevin Brown
            Gavin Conway
date:       2018-10-18

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

A library providing safe mathematical operations for division and
multiplication with the capability to round or truncate the results
to the nearest increment. Operations can return a standard precision
or high precision decimal. High precision decimals are useful for
example when attempting to calculate percentages or fractions
accurately.

-----------------------------------------------------------------
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Safely manipulate unsigned fixed-point decimals at a given precision level.
 * @dev Functions accepting uints in this contract and derived contracts
 * are taken to be such fixed point decimals of a specified precision (either standard
 * or high).
 */
library SafeDecimalMath {

    using SafeMath for uint;

    /* Number of decimal places in the representations. */
    uint8 public constant decimals = 18;
    uint8 public constant highPrecisionDecimals = 27;

    /* The number representing 1.0. */
    uint public constant UNIT = 10 ** uint(decimals);

    /* The number representing 1.0 for higher fidelity numbers. */
    uint public constant PRECISE_UNIT = 10 ** uint(highPrecisionDecimals);
    uint private constant UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR = 10 ** uint(highPrecisionDecimals - decimals);

    /** 
     * @return Provides an interface to UNIT.
     */
    function unit()
        external
        pure
        returns (uint)
    {
        return UNIT;
    }

    /** 
     * @return Provides an interface to PRECISE_UNIT.
     */
    function preciseUnit()
        external
        pure 
        returns (uint)
    {
        return PRECISE_UNIT;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     * 
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(uint x, uint y)
        internal
        pure
        returns (uint)
    {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y) / UNIT;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of the specified precision unit.
     *
     * @dev The operands should be in the form of a the specified unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function _multiplyDecimalRound(uint x, uint y, uint precisionUnit)
        private
        pure
        returns (uint)
    {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        uint quotientTimesTen = x.mul(y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a precise unit.
     *
     * @dev The operands should be in the precise unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRoundPrecise(uint x, uint y)
        internal
        pure
        returns (uint)
    {
        return _multiplyDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a standard unit.
     *
     * @dev The operands should be in the standard unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRound(uint x, uint y)
        internal
        pure
        returns (uint)
    {
        return _multiplyDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     * 
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(uint x, uint y)
        internal
        pure
        returns (uint)
    {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * decimal in the precision unit specified in the parameter.
     *
     * @dev y is divided after the product of x and the specified precision unit
     * is evaluated, so the product of x and the specified precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function _divideDecimalRound(uint x, uint y, uint precisionUnit)
        private
        pure
        returns (uint)
    {
        uint resultTimesTen = x.mul(precisionUnit * 10).div(y);

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * standard precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and the standard precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRound(uint x, uint y)
        internal
        pure
        returns (uint)
    {
        return _divideDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * high precision decimal.
     *
     * @dev y is divided after the product of x and the high precision unit
     * is evaluated, so the product of x and the high precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRoundPrecise(uint x, uint y)
        internal
        pure
        returns (uint)
    {
        return _divideDecimalRound(x, y, PRECISE_UNIT);
    }

    /**
     * @dev Convert a standard decimal representation to a high precision one.
     */
    function decimalToPreciseDecimal(uint i)
        internal
        pure
        returns (uint)
    {
        return i.mul(UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR);
    }

    /**
     * @dev Convert a high precision decimal to a standard decimal representation.
     */
    function preciseDecimalToDecimal(uint i)
        internal
        pure
        returns (uint)
    {
        uint quotientTimesTen = i / (UNIT_TO_HIGH_PRECISION_CONVERSION_FACTOR / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
 * @title Synthetix interface contract
 * @dev pseudo interface, actually declared as contract to hold the public getters 
 */
import "./ISynthetixState.sol";
import "./ISynth.sol";
import "./ISynthetixEscrow.sol";
import "./IFeePool.sol";
import "./IExchangeRates.sol";

abstract contract ISynthetix {

    // ========== PUBLIC STATE VARIABLES ==========

    IFeePool public feePool;
    ISynthetixEscrow public escrow;
    ISynthetixEscrow public rewardEscrow;
    ISynthetixState public synthetixState;
    IExchangeRates public exchangeRates;

    // ========== PUBLIC FUNCTIONS ==========

    function balanceOf(address account) public virtual view returns (uint);
    function transfer(address to, uint value) public virtual returns (bool);
    function effectiveValue(bytes4 sourceCurrencyKey, uint sourceAmount, bytes4 destinationCurrencyKey) public virtual view returns (uint);

    function synthInitiatedFeePayment(address from, bytes4 sourceCurrencyKey, uint sourceAmount) external virtual returns (bool);
    function synthInitiatedExchange(
        address from,
        bytes4 sourceCurrencyKey,
        uint sourceAmount,
        bytes4 destinationCurrencyKey,
        address destinationAddress) external virtual returns (bool);
    function collateralisationRatio(address issuer) public virtual view returns (uint);
    function totalIssuedSynths(bytes4 currencyKey)
        public virtual
        view
        returns (uint);
    function getSynth(bytes4 currencyKey) public virtual view returns (ISynth);
    function debtBalanceOf(address issuer, bytes4 currencyKey) public virtual view returns (uint);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface ISynth {
  function burn(address account, uint amount) external;
  function issue(address account, uint amount) external;
  function transfer(address to, uint value) external returns (bool);
  function triggerTokenFallbackIfNeeded(address sender, address recipient, uint amount) external;
  function transferFrom(address from, address to, uint value) external returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

abstract contract IFeePool {
    address public FEE_ADDRESS;
    function amountReceivedFromExchange(uint value) external virtual view returns (uint);
    function amountReceivedFromTransfer(uint value) external virtual view returns (uint);
    function feePaid(bytes4 currencyKey, uint amount) external virtual;
    function appendAccountIssuanceRecord(address account, uint lockedAmount, uint debtEntryIndex) external virtual;
    function rewardsMinted(uint amount) external virtual;
    function transferFeeIncurred(uint value) public virtual view returns (uint);
}

/*
-----------------------------------------------------------------
FILE INFORMATION
-----------------------------------------------------------------

file:       Owned.sol
version:    1.1
author:     Anton Jurisevic
            Dominic Romanowski

date:       2018-2-26

-----------------------------------------------------------------
MODULE DESCRIPTION
-----------------------------------------------------------------

An Owned contract, to be inherited by other contracts.
Requires its owner to be explicitly set in the constructor.
Provides an onlyOwner access modifier.

To change owner, the current owner must nominate the next owner,
who then has to accept the nomination. The nomination can be
cancelled before it is accepted by the new owner by having the
previous owner change the nomination (setting it to 0).

-----------------------------------------------------------------
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
 * @title A contract with an owner.
 * @notice Contract ownership can be transferred by first nominating the new owner,
 * who must then accept the ownership, which prevents accidental incorrect ownership transfers.
 */
contract Owned {
    address public owner;
    address public nominatedOwner;

    /**
     * @dev Owned Constructor
     */
    constructor(address _owner)
    {
        require(_owner != address(0), "Owner address cannot be 0");
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    /**
     * @notice Nominate a new owner of this contract.
     * @dev Only the current owner may nominate a new owner.
     */
    function nominateNewOwner(address _owner)
        external
        onlyOwner
    {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    /**
     * @notice Accept the nomination to be owner.
     */
    function acceptOwnership()
        external
    {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    modifier onlyOwner
    {
        require(msg.sender == owner, "Only the contract owner may perform this action");
        _;
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

abstract contract ISynthetixState {
    // A struct for handing values associated with an individual user's debt position
    struct IssuanceData {
        // Percentage of the total debt owned at the time
        // of issuance. This number is modified by the global debt
        // delta array. You can figure out a user's exit price and
        // collateralisation ratio using a combination of their initial
        // debt and the slice of global debt delta which applies to them.
        uint initialDebtOwnership;
        // This lets us know when (in relative terms) the user entered
        // the debt pool so we can calculate their exit price and
        // collateralistion ratio
        uint debtEntryIndex;
    }

    uint[] public debtLedger;
    uint public issuanceRatio;
    mapping(address => IssuanceData) public issuanceData;

    function debtLedgerLength() external virtual view returns (uint);
    function hasIssued(address account) external virtual view returns (bool);
    function incrementTotalIssuerCount() external virtual;
    function decrementTotalIssuerCount() external virtual;
    function setCurrentIssuanceData(address account, uint initialDebtOwnership) external virtual;
    function lastDebtLedgerEntry() external virtual view returns (uint);
    function appendDebtLedgerValue(uint value) external virtual;
    function clearIssuanceData(address account) external virtual;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
 * @title SynthetixEscrow interface
 */
interface ISynthetixEscrow {
    function balanceOf(address account) external view returns (uint);
    function appendVestingEntry(address account, uint quantity) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
 * @title ExchangeRates interface
 */
interface IExchangeRates {
    function effectiveValue(bytes4 sourceCurrencyKey, uint sourceAmount, bytes4 destinationCurrencyKey) external view returns (uint);

    function rateForCurrency(bytes4 currencyKey) external view returns (uint);

    function anyRateIsStale(bytes4[] memory currencyKeys) external view returns (bool);

    function rateIsStale(bytes4 currencyKey) external view returns (bool);
}