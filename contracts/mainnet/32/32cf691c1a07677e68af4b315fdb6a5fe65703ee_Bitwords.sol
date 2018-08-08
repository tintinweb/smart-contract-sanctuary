pragma solidity ^0.4.23;


/**
 * @title Ownable
 *
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    // A hashmap to help keep track of list of all owners
    mapping(address => uint) public allOwnersMap;


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () public {
        owner = msg.sender;
        allOwnersMap[msg.sender] = 1;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "You&#39;re not the owner!");
        _;
    }


    /**
     * @dev Throws if called by any account other than the all owners in the history of
     * the smart contract.
     */
    modifier onlyAnyOwners() {
        require(allOwnersMap[msg.sender] == 1, "You&#39;re not the owner or never were the owner!");
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;

        // Keep track of list of owners
        allOwnersMap[newOwner] = 1;
    }


    // transfer ownership event
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}









/**
 * @title Suicidable
 *
 * @dev Suicidable is special contract with functions to suicide. This is a security measure added in
 * incase Bitwords gets hacked.
 */
contract Suicidable is Ownable {
    bool public hasSuicided = false;


    /**
     * @dev Throws if called the contract has not yet suicided
     */
    modifier hasNotSuicided() {
        require(hasSuicided == false, "Contract has suicided!");
        _;
    }


    /**
     * @dev Suicides the entire smart contract
     */
    function suicideContract() public onlyAnyOwners {
        hasSuicided = true;
        emit SuicideContract(msg.sender);
    }


    // suicide contract event
    event SuicideContract(address indexed owner);
}



/**
 * @title Migratable
 *
 * @dev Migratable is special contract which allows the funds of a smart-contact to be migrated
 * to a new smart contract.
 */
contract Migratable is Suicidable {
    bool public hasRequestedForMigration = false;
    uint public requestedForMigrationAt = 0;
    address public migrationDestination;

    function() public payable {

    }

    /**
     * @dev Allows for a migration request to be created, all migrations requests
     * are timelocked by 7 days.
     *
     * @param destination   The destination to send the ether to.
     */
    function requestForMigration(address destination) public onlyOwner {
        hasRequestedForMigration = true;
        requestedForMigrationAt = now;
        migrationDestination = destination;

        emit MigrateFundsRequested(msg.sender, destination);
    }

    /**
     * @dev Cancels a migration
     */
    function cancelMigration() public onlyOwner hasNotSuicided {
        hasRequestedForMigration = false;
        requestedForMigrationAt = 0;

        emit MigrateFundsCancelled(msg.sender);
    }

    /**
     * @dev Approves a migration and suicides the entire smart contract
     */
    function approveMigration(uint gasCostInGwei) public onlyOwner hasNotSuicided {
        require(hasRequestedForMigration, "please make a migration request");
        require(requestedForMigrationAt + 604800 < now, "migration is timelocked for 7 days");
        require(gasCostInGwei > 0, "gas cost must be more than 0");
        require(gasCostInGwei < 20, "gas cost can&#39;t be more than 20");

        // Figure out how much ether to send
        uint gasLimit = 21000;
        uint gasPrice = gasCostInGwei * 1000000000;
        uint gasCost = gasLimit * gasPrice;
        uint etherToSend = address(this).balance - gasCost;

        require(etherToSend > 0, "not enough balance in smart contract");

        // Send the funds to the new smart contract
        emit MigrateFundsApproved(msg.sender, etherToSend);
        migrationDestination.transfer(etherToSend);

        // suicide the contract so that no more funds/actions can take place
        suicideContract();
    }

    // events
    event MigrateFundsCancelled(address indexed by);
    event MigrateFundsRequested(address indexed by, address indexed newSmartContract);
    event MigrateFundsApproved(address indexed by, uint amount);
}



/**
 * @title Bitwords
 *
 * @dev The Bitwords smart contract that allows advertisers and publishers to
 * safetly deposit/receive ether and interact with the Bitwords platform.
 *
 * TODO:
 *  - timelock all chargeAdvertiser requests
 *  - if suicide is called, then all timelocked requests need to be stopped and then later reversed
 */
contract Bitwords is Migratable {
    mapping(address => uint) public advertiserBalances;

    // This mapping overrides the default bitwords cut for a specific publisher.
    mapping(address => uint) public bitwordsCutOverride;

    // The bitwords address, where all the 30% cut is received ETH
    address public bitwordsWithdrawlAddress;

    // How much cut out of 100 Bitwords takes. By default 10%
    uint public bitwordsCutOutof100 = 10;

    // To store the advertiserChargeRequests
    // TODO: this needs to be used for the timelock
    struct advertiserChargeRequest {
        address advertiser;
        address publisher;
        uint amount;
        uint requestedAt;
        uint processAfter;
    }

    // How much days should each refund request be timelocked for
    uint public refundRequestTimelock = 7 days;

    // To store refund request
    struct refundRequest {
        address advertiser;
        uint amount;
        uint requestedAt;
        uint processAfter;
    }

    // An array of all the refund requests submitted by advertisers.
    refundRequest[] public refundQueue;

    // variables that help track where in the refund loop we are in.
    mapping(address => uint) private advertiserRefundRequestsIndex;
    uint private lastProccessedIndex = 0;


    /**
     * @dev The Bitwords constructor sets the address where all the withdrawals will
     * happen.
     */
    constructor () public {
        bitwordsWithdrawlAddress = msg.sender;
    }

    /**
     * Anybody who deposits ether to the smart contract will be considered as an
     * advertiser and will get that much ether debitted into his account.
     */
    function() public payable {
        advertiserBalances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value, advertiserBalances[msg.sender]);
    }

    /**
     * Used by the owner to set the withdrawal address for Bitwords. This address
     * is where Bitwords will receive all the cut from the advertisements.
     *
     * @param newAddress    the new withdrawal address
     */
    function setBitwordsWithdrawlAddress (address newAddress) hasNotSuicided onlyOwner public {
        bitwordsWithdrawlAddress = newAddress;

        emit BitwordsWithdrawlAddressChanged(msg.sender, newAddress);
    }

    /**
     * Change the cut that Bitwords takes.
     *
     * @param cut   the amount of cut that Bitwords takes.
     */
    function setBitwordsCut (uint cut) hasNotSuicided onlyOwner public {
        require(cut <= 30, "cut cannot be more than 30%");
        require(cut >= 0, "cut should be greater than 0%");
        bitwordsCutOutof100 = cut;

        emit BitwordsCutChanged(msg.sender, cut);
    }

    /**
     * Set the new timelock for refund reuqests
     *
     * @param newTimelock   the new timelock
     */
    function setRefundTimelock (uint newTimelock) hasNotSuicided onlyOwner public {
        require(newTimelock >= 0, "timelock has to be greater than 0");
        refundRequestTimelock = newTimelock;

        emit TimelockChanged(msg.sender, newTimelock);
    }

    /**
     * Process all the refund requests in the queue. This is called by the Bitwords
     * server ideally right after chargeAdvertisers has been called.
     *
     * This function will only process refunds that have passed it&#39;s timelock and
     * it will only refund maximum to how much the advertiser currently has in
     * his balance.
     */
    bool private inProcessRefunds = false;
    function processRefunds () onlyAnyOwners public {
        // prevent reentry bug
        require(!inProcessRefunds, "prevent reentry bug");
        inProcessRefunds = true;

        for (uint j = lastProccessedIndex; j < refundQueue.length; j++) {
            // If we haven&#39;t passed the timelock for this refund request, then
            // we stop the loop. Reaching here means that all the requests
            // in next iterations have also not reached their timelocks.
            if (refundQueue[j].processAfter > now) break;

            // Find the minimum that needs to be withdrawn. This is important
            // because since every call to chargeAdvertisers might update the
            // advertiser&#39;s balance, it is possible that the amount that the
            // advertiser requests for is small.
            uint cappedAmount = refundQueue[j].amount;
            if (advertiserBalances[refundQueue[j].advertiser] < cappedAmount)
                cappedAmount = advertiserBalances[refundQueue[j].advertiser];

            // This refund is now invalid, skip it
            if (cappedAmount <= 0) {
                lastProccessedIndex++;
                continue;
            }

            // deduct advertiser&#39;s balance and send the ether
            advertiserBalances[refundQueue[j].advertiser] -= cappedAmount;
            refundQueue[j].advertiser.transfer(cappedAmount);
            refundQueue[j].amount = 0;

            // Emit events
            emit RefundAdvertiserProcessed(refundQueue[j].advertiser, cappedAmount, advertiserBalances[refundQueue[j].advertiser]);

            // Increment the last proccessed index, effectively marking this
            // refund request as completed.
            lastProccessedIndex++;
        }

        inProcessRefunds = false;
    }

    /**
     * Anybody can credit ether on behalf of an advertiser
     *
     * @param advertiser    The advertiser to credit ether to
     */
    function creditAdvertiser (address advertiser) hasNotSuicided public payable {
        advertiserBalances[advertiser] += msg.value;
        emit Deposit(advertiser, msg.value, advertiserBalances[msg.sender]);
    }

    /**
     * Anybody can credit ether on behalf of an advertiser
     *
     * @param publisher    The address of the publisher
     * @param cut          How much cut should be taken from this publisher
     */
    function setPublisherCut (address publisher, uint cut) hasNotSuicided onlyOwner public {
        require(cut <= 30, "cut cannot be more than 30%");
        require(cut >= 0, "cut should be greater than 0%");

        bitwordsCutOverride[publisher] = cut;
        emit SetPublisherCut(publisher, cut);
    }

    /**
     * Charge the advertiser with whatever clicks have been served by the ad engine.
     *
     * @param advertisers           Array of address of the advertiser from whom we should debit ether
     * @param costs                 Array of the cost to be paid to publisher by advertisers
     * @param publishers            Array of address of the publisher from whom we should credit ether
     * @param publishersToCredit    Array of indices of publishers that need to be credited than debited.
     */
    bool private inChargeAdvertisers = false;
    function chargeAdvertisers (address[] advertisers, uint[] costs, address[] publishers, uint[] publishersToCredit) hasNotSuicided onlyOwner public {
        // Prevent re-entry bug
        require(!inChargeAdvertisers, "avoid rentry bug");
        inChargeAdvertisers = true;

        uint creditArrayIndex = 0;

        for (uint i = 0; i < advertisers.length; i++) {
            uint toWithdraw = costs[i];

            // First check if all advertisers have enough balance and cap it if needed
            if (advertiserBalances[advertisers[i]] <= 0) {
                emit InsufficientBalance(advertisers[i], advertiserBalances[advertisers[i]], costs[i]);
                continue;
            }
            if (advertiserBalances[advertisers[i]] < toWithdraw) toWithdraw = advertiserBalances[advertisers[i]];

            // Update the advertiser&#39;s balance
            advertiserBalances[advertisers[i]] -= toWithdraw;
            emit DeductFromAdvertiser(advertisers[i], toWithdraw, advertiserBalances[advertisers[i]]);

            // Calculate how much cut Bitwords should take
            uint bitwordsCut = bitwordsCutOutof100;
            if (bitwordsCutOverride[publishers[i]] > 0 && bitwordsCutOverride[publishers[i]] <= 30) {
                bitwordsCut = bitwordsCutOverride[publishers[i]];
            }

            // Figure out how much should go to Bitwords and to the publishers.
            uint publisherNetCut = toWithdraw * (100 - bitwordsCut) / 100;
            uint bitwordsNetCut = toWithdraw - publisherNetCut;

            // Send the ether to the publisher and to Bitwords
            // Either decide to credit the ether as an advertiser
            if (publishersToCredit.length > creditArrayIndex && publishersToCredit[creditArrayIndex] == i) {
                creditArrayIndex++;
                advertiserBalances[publishers[i]] += publisherNetCut;
                emit CreditPublisher(publishers[i], publisherNetCut, advertisers[i], advertiserBalances[publishers[i]]);
            } else { // or send it to the publisher.
                publishers[i].transfer(publisherNetCut);
                emit PayoutToPublisher(publishers[i], publisherNetCut, advertisers[i]);
            }

            // send bitwords it&#39;s cut
            bitwordsWithdrawlAddress.transfer(bitwordsNetCut);
            emit PayoutToBitwords(bitwordsWithdrawlAddress, bitwordsNetCut, advertisers[i]);
        }

        inChargeAdvertisers = false;
    }

    /**
     * Called by Bitwords to manually refund an advertiser.
     *
     * @param advertiser    The advertiser address to be refunded
     * @param amount        The amount the advertiser would like to withdraw
     */
    bool private inRefundAdvertiser = false;
    function refundAdvertiser (address advertiser, uint amount) onlyAnyOwners public {
        // Ensure that the advertiser has enough balance to refund the smart
        // contract
        require(amount > 0, "Amount should be greater than 0");
        require(advertiserBalances[advertiser] > 0, "Advertiser has no balance");
        require(advertiserBalances[advertiser] >= amount, "Insufficient balance to refund");

        // Prevent re-entry bug
        require(!inRefundAdvertiser, "avoid rentry bug");
        inRefundAdvertiser = true;

        // deduct balance and send the ether
        advertiserBalances[advertiser] -= amount;
        advertiser.transfer(amount);

        // Emit events
        emit RefundAdvertiserProcessed(advertiser, amount, advertiserBalances[advertiser]);

        inRefundAdvertiser = false;
    }

    /**
     * Called by Bitwords to invalidate a refund sent by an advertiser.
     */
    function invalidateAdvertiserRefund (uint refundIndex) hasNotSuicided onlyOwner public {
        require(refundIndex >= 0, "index should be greater than 0");
        require(refundQueue.length >=  refundIndex, "index is out of bounds");
        refundQueue[refundIndex].amount = 0;

        emit RefundAdvertiserCancelled(refundQueue[refundIndex].advertiser);
    }

    /**
     * Called by an advertiser when he/she would like to make a refund request.
     *
     * @param amount    The amount the advertiser would like to withdraw
     */
    function requestForRefund (uint amount) public {
        // Make sure that advertisers are requesting a refund for how much ever
        // ether they have.
        require(amount > 0, "Amount should be greater than 0");
        require(advertiserBalances[msg.sender] > 0, "You have no balance");
        require(advertiserBalances[msg.sender] >= amount, "Insufficient balance to refund");

        // push the refund request in a refundQueue so that it can be processed
        // later.
        refundQueue.push(refundRequest(msg.sender, amount, now, now + refundRequestTimelock));

        // Add the index into a hashmap for later use
        advertiserRefundRequestsIndex[msg.sender] = refundQueue.length - 1;

        // Emit events
        emit RefundAdvertiserRequested(msg.sender, amount, refundQueue.length - 1);
    }

    /**
     * Called by an advertiser when he/she wants to manually process a refund
     * that he/she has requested for earlier.
     *
     * This function will first find a refund request, check if it&#39;s valid (as
     * in, has it passed it&#39;s timelock?, is there enough balance? etc.) and
     * then process it, updating the advertiser&#39;s balance along the way.
     */
    mapping(address => bool) private inProcessMyRefund;
    function processMyRefund () public {
        // Check if a refund request even exists for this advertiser?
        require(advertiserRefundRequestsIndex[msg.sender] >= 0, "no refund request found");

        // Get the refund request details
        uint refundRequestIndex = advertiserRefundRequestsIndex[msg.sender];

        // Check if the refund has been proccessed
        require(refundQueue[refundRequestIndex].amount > 0, "refund already proccessed");

        // Check if the advertiser has enough balance to request for this refund?
        require(
            advertiserBalances[msg.sender] >= refundQueue[refundRequestIndex].amount,
            "advertiser balance is low; refund amount is invalid."
        );

        // Check the timelock
        require(
            now > refundQueue[refundRequestIndex].processAfter,
            "timelock for this request has not passed"
        );

        // Prevent reentry bug
        require(!inProcessMyRefund[msg.sender], "prevent re-entry bug");
        inProcessMyRefund[msg.sender] = true;

        // Send the amount
        uint amount = refundQueue[refundRequestIndex].amount;
        msg.sender.transfer(amount);

        // update the new balance and void this request.
        refundQueue[refundRequestIndex].amount = 0;
        advertiserBalances[msg.sender] -= amount;

        // reset the reentry flag
        inProcessMyRefund[msg.sender] = false;

        // Emit events
        emit SelfRefundAdvertiser(msg.sender, amount, advertiserBalances[msg.sender]);
        emit RefundAdvertiserProcessed(msg.sender, amount, advertiserBalances[msg.sender]);
    }

    /** Events */
    event BitwordsCutChanged(address indexed _to, uint _value);
    event BitwordsWithdrawlAddressChanged(address indexed _to, address indexed _from);
    event CreditPublisher(address indexed _to, uint _value, address indexed _from, uint _newBalance);
    event DeductFromAdvertiser(address indexed _to, uint _value, uint _newBalance);
    event Deposit(address indexed _to, uint _value, uint _newBalance);
    event InsufficientBalance(address indexed _to, uint _balance, uint _valueToDeduct);
    event PayoutToBitwords(address indexed _to, uint _value, address indexed _from);
    event PayoutToPublisher(address indexed _to, uint _value, address indexed _from);
    event RefundAdvertiserCancelled(address indexed _to);
    event RefundAdvertiserProcessed(address indexed _to, uint _value, uint _newBalance);
    event RefundAdvertiserRequested(address indexed _to, uint _value, uint requestIndex);
    event SelfRefundAdvertiser(address indexed _to, uint _value, uint _newBalance);
    event SetPublisherCut(address indexed _to, uint _value);
    event TimelockChanged(address indexed _to, uint _value);
}