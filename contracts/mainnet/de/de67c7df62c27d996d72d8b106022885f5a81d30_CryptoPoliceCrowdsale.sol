pragma solidity ^0.4.23;

// File: contracts/Utils/Math.sol

library MathUtils {
    function add(uint a, uint b) internal pure returns (uint) {
        uint result = a + b;

        if (a == 0 || b == 0) {
            return result;
        }

        require(result > a && result > b);

        return result;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(a >= b);

        return a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0 || b == 0) {
            return 0;
        }

        uint result = a * b;

        require(result / a == b);

        return result;
    }
}

// File: contracts/Utils/Ownable.sol

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function isOwner() view public returns (bool) {
        return msg.sender == owner;
    }

    modifier grantOwner {
        require(isOwner());
        _;
    }
}

// File: contracts/Crowdsale/CrowdsaleToken.sol

interface CrowdsaleToken {
    function transfer(address destination, uint amount) external returns (bool);
    function balanceOf(address account) external view returns (uint);
    function burn(uint amount) external;
}

// File: contracts/Crowdsale/CryptoPoliceCrowdsale.sol

contract CryptoPoliceCrowdsale is Ownable {
    using MathUtils for uint;
    
    enum CrowdsaleState {
        Pending, Started, Ended, Paused, SoldOut
    }

    struct ExchangeRate {
        uint tokens;
        uint price;
    }

    struct Participant {
        bool identified;
        uint processedDirectWeiAmount;
        uint processedExternalWeiAmount;
        uint suspendedDirectWeiAmount;
        uint suspendedExternalWeiAmount;
    }

    event ExternalPaymentReminder(uint weiAmount, bytes32 paymentChecksum);
    event PaymentSuspended(address participant);
    event PaymentProcessed(uint weiAmount, address participant, bytes32 paymentChecksum, uint tokenAmount);

    uint public constant THRESHOLD1 = 270000000e18;
    uint public constant THRESHOLD2 = 350000000e18;
    uint public constant THRESHOLD3 = 490000000e18;
    uint public constant THRESHOLD4 = 510000000e18;

    uint public constant RELEASE_THRESHOLD = 11111111e18;

    address public admin;

    /**
     * Amount of tokens sold in this crowdsale
     */
    uint public tokensSold;

    /**
     * Minimum number of Wei that can be exchanged for tokens
     */
    uint public minSale = 0.01 ether;
    
    /**
     * Amount of direct Wei paid to the contract that has not yet been processed
     */
    uint public suspendedPayments = 0;

    /**
     * Token that will be sold
     */
    CrowdsaleToken public token;
    
    /**
     * State in which the crowdsale is in
     */
    CrowdsaleState public state = CrowdsaleState.Pending;

    /**
     * List of exchange rates for each token volume
     */
    ExchangeRate[4] public exchangeRates;
    
    bool public crowdsaleEndedSuccessfully = false;

    /**
     * Number of Wei that can be paid without carrying out KYC process
     */
    uint public unidentifiedSaleLimit = 1.45 ether;

    /**
     * Crowdsale participants that have made payments
     */
    mapping(address => Participant) public participants;

    /**
     * Map external payment reference hash to that payment description
     */
    mapping(bytes32 => string) public externalPaymentDescriptions;

    /**
     * Map participants to list of their external payment reference hashes
     */
    mapping(address => bytes32[]) public participantExternalPaymentChecksums;

    mapping(address => bytes32[]) public participantSuspendedExternalPaymentChecksums;

    /**
     * Map external payment checksum to payment amount
     */
    mapping(bytes32 => uint) public suspendedExternalPayments;

    mapping(address => bool) public bannedParticipants;

    bool public revertSuspendedPayment = false;

    /**
     * 1) Process payment when crowdsale started by sending tokens in return
     * 2) Issue a refund when crowdsale ended unsuccessfully 
     */
    function () public payable {
        if (state == CrowdsaleState.Ended) {
            msg.sender.transfer(msg.value);
            refundParticipant(msg.sender);
        } else {
            require(state == CrowdsaleState.Started, "Crowdsale currently inactive");
            processPayment(msg.sender, msg.value, "");
        }
    }

    /**
     * Recursively caluclates number of tokens that can be exchanged for given payment 
     *
     * @param salePosition Number of tokens processed in crowdsale so far
     * @param _paymentReminder Number of Wei remaining from payment so far
     * @param _processedTokenCount Number of tokens that can be exchanged so far
     *
     * @return paymentReminder Number of Wei remaining from payment
     * @return processedTokenCount Number of tokens that can be exchanged
     * @return soldOut Indicates whether or not there would be no more tokens left after this exchange
     */
    function exchangeCalculator(uint salePosition, uint _paymentReminder, uint _processedTokenCount)
    internal view returns (uint paymentReminder, uint processedTokenCount, bool soldOut)
    {
        uint threshold = getTreshold(salePosition);
        ExchangeRate memory currentExchangeRate = getExchangeRate(threshold);

        // how many round number of portions are left for exchange
        uint availablePortions = (threshold - salePosition) / currentExchangeRate.tokens;

        // this indicates that there are no leftover tokens that can be exchanged
        // without stepping over threshold
        if (availablePortions == 0) {
            if (threshold == THRESHOLD4) {
                return (_paymentReminder, _processedTokenCount, true);
            }
            // move sale position to current threshold
            return exchangeCalculator(threshold, _paymentReminder, _processedTokenCount);
        }

        uint requestedPortions = _paymentReminder / currentExchangeRate.price;
        uint portions = requestedPortions > availablePortions ? availablePortions : requestedPortions;
        uint newProcessedTokenCount = _processedTokenCount + portions * currentExchangeRate.tokens;
        uint newPaymentReminder = _paymentReminder - portions * currentExchangeRate.price;
        uint newSalePosition = salePosition + newProcessedTokenCount;

        if (newPaymentReminder < currentExchangeRate.price) {
            return (newPaymentReminder, newProcessedTokenCount, false);
        }
        
        return exchangeCalculator(newSalePosition, newPaymentReminder, newProcessedTokenCount);
    }

    function processPayment(address participant, uint payment, bytes32 externalPaymentChecksum) internal {
        require(payment >= minSale, "Payment must be greather or equal to sale minimum");
        require(bannedParticipants[participant] == false, "Participant is banned");

        uint paymentReminder;
        uint processedTokenCount;
        bool soldOut;

        (paymentReminder, processedTokenCount, soldOut) = exchangeCalculator(tokensSold, payment, 0);

        // how much was actually spent from this payment
        uint spent = payment - paymentReminder;
        bool directPayment = externalPaymentChecksum == "";

        if (participants[participant].identified == false) {
            // how much participant has spent in crowdsale so far
            uint spendings = participants[participant].processedDirectWeiAmount
                .add(participants[participant].processedExternalWeiAmount).add(spent);

            bool hasSuspendedPayments = participants[participant].suspendedDirectWeiAmount > 0 || participants[participant].suspendedExternalWeiAmount > 0;

            // due to fluctuations of unidentified payment limit, it might not be reached
            // suspend current payment if participant currently has suspended payments or limit reached
            if (hasSuspendedPayments || spendings > unidentifiedSaleLimit) {
                require(revertSuspendedPayment == false, "Participant does not comply with KYC");

                suspendedPayments = suspendedPayments + payment;

                if (directPayment) {
                    participants[participant].suspendedDirectWeiAmount = participants[participant].suspendedDirectWeiAmount.add(payment);
                } else {
                    participantSuspendedExternalPaymentChecksums[participant].push(externalPaymentChecksum);
                    participants[participant].suspendedExternalWeiAmount = participants[participant].suspendedExternalWeiAmount.add(payment);
                    suspendedExternalPayments[externalPaymentChecksum] = payment;
                }

                emit PaymentSuspended(participant);

                return;
            }
        }

        // unspent reminder must be returned back to participant
        if (paymentReminder > 0) {
            if (directPayment) {
                participant.transfer(paymentReminder);
            } else {
                emit ExternalPaymentReminder(paymentReminder, externalPaymentChecksum);
            }
        }

        if (directPayment) {
            participants[participant].processedDirectWeiAmount = participants[participant].processedDirectWeiAmount.add(spent);
        } else {
            participants[participant].processedExternalWeiAmount = participants[participant].processedExternalWeiAmount.add(spent);
        }

        require(token.transfer(participant, processedTokenCount), "Failed to transfer tokens");
        
        if (soldOut) {
            state = CrowdsaleState.SoldOut;
        }
        
        tokensSold = tokensSold + processedTokenCount;

        emit PaymentProcessed(spent, participant, externalPaymentChecksum, processedTokenCount);
    }

    /**
     * Intended when other currencies are received and owner has to carry out exchange
     * for those payments aligned to Wei
     */
    function proxyExchange(address beneficiary, uint payment, string description, bytes32 checksum)
    public grantOwnerOrAdmin
    {
        require(beneficiary != address(0), "Beneficiary not specified");
        require(bytes(description).length > 0, "Description not specified");
        require(checksum.length > 0, "Checksum not specified");
        // make sure that payment has not been processed yet
        require(bytes(externalPaymentDescriptions[checksum]).length == 0, "Payment already processed");

        processPayment(beneficiary, payment, checksum);
        
        externalPaymentDescriptions[checksum] = description;
        participantExternalPaymentChecksums[beneficiary].push(checksum);
    }

    /**
     * Command for owner to start crowdsale
     */
    function startCrowdsale(address crowdsaleToken, address adminAddress) public grantOwner {
        require(state == CrowdsaleState.Pending);
        setAdmin(adminAddress);
        token = CrowdsaleToken(crowdsaleToken);
        require(token.balanceOf(address(this)) == 510000000e18);
        state = CrowdsaleState.Started;
    }

    function pauseCrowdsale() public grantOwnerOrAdmin {
        require(state == CrowdsaleState.Started);
        state = CrowdsaleState.Paused;
    }

    function unPauseCrowdsale() public grantOwnerOrAdmin {
        require(state == CrowdsaleState.Paused);
        state = CrowdsaleState.Started;
    }

    /**
     * Command for owner to end crowdsale
     */
    function endCrowdsale(bool success) public grantOwner notEnded {
        state = CrowdsaleState.Ended;
        crowdsaleEndedSuccessfully = success;

        uint balance = address(this).balance;

        if (success && balance > 0) {
            uint amount = balance.sub(suspendedPayments);
            owner.transfer(amount);
        }
    }

    function markParticipantIdentifiend(address participant) public grantOwnerOrAdmin notEnded {
        participants[participant].identified = true;

        if (participants[participant].suspendedDirectWeiAmount > 0) {
            processPayment(participant, participants[participant].suspendedDirectWeiAmount, "");
            suspendedPayments = suspendedPayments.sub(participants[participant].suspendedDirectWeiAmount);
            participants[participant].suspendedDirectWeiAmount = 0;
        }

        if (participants[participant].suspendedExternalWeiAmount > 0) {
            bytes32[] storage checksums = participantSuspendedExternalPaymentChecksums[participant];
            for (uint i = 0; i < checksums.length; i++) {
                processPayment(participant, suspendedExternalPayments[checksums[i]], checksums[i]);
                suspendedExternalPayments[checksums[i]] = 0;
            }
            participants[participant].suspendedExternalWeiAmount = 0;
            participantSuspendedExternalPaymentChecksums[participant] = new bytes32[](0);
        }
    }

    function unidentifyParticipant(address participant) public grantOwnerOrAdmin notEnded {
        participants[participant].identified = false;
    }

    function returnSuspendedPayments(address participant) public grantOwnerOrAdmin {
        returnDirectPayments(participant, false, true);
        returnExternalPayments(participant, false, true);
    }

    function updateUnidentifiedSaleLimit(uint limit) public grantOwnerOrAdmin notEnded {
        unidentifiedSaleLimit = limit;
    }

    function updateMinSale(uint weiAmount) public grantOwnerOrAdmin {
        minSale = weiAmount;
    }

    /**
     * Allow crowdsale participant to get refunded
     */
    function refundParticipant(address participant) internal {
        require(state == CrowdsaleState.Ended);
        require(crowdsaleEndedSuccessfully == false);
        
        returnDirectPayments(participant, true, true);
        returnExternalPayments(participant, true, true);
    }

    function refund(address participant) public grantOwner {
        refundParticipant(participant);
    }

    function burnLeftoverTokens(uint8 percentage) public grantOwner {
        require(state == CrowdsaleState.Ended);
        require(percentage <= 100 && percentage > 0);

        uint balance = token.balanceOf(address(this));

        if (balance > 0) {
            uint amount = balance / (100 / percentage);
            token.burn(amount);
        }
    }

    function updateExchangeRate(uint8 idx, uint tokens, uint price) public grantOwnerOrAdmin {
        require(tokens > 0 && price > 0);
        require(idx >= 0 && idx <= 3);

        exchangeRates[idx] = ExchangeRate({
            tokens: tokens,
            price: price
        });
    }

    function ban(address participant) public grantOwnerOrAdmin {
        bannedParticipants[participant] = true;
    }

    function unBan(address participant) public grantOwnerOrAdmin {
        bannedParticipants[participant] = false;
    }

    function getExchangeRate(uint threshold) internal view returns (ExchangeRate) {
        uint8 idx = exchangeRateIdx(threshold);

        ExchangeRate storage rate = exchangeRates[idx];

        require(rate.tokens > 0 && rate.price > 0, "Exchange rate not set");

        return rate;
    }

    function getTreshold(uint salePosition) internal pure returns (uint) {
        if (salePosition < THRESHOLD1) {
            return THRESHOLD1;
        }
        if (salePosition < THRESHOLD2) {
            return THRESHOLD2;
        }
        if (salePosition < THRESHOLD3) {
            return THRESHOLD3;
        }
        if (salePosition < THRESHOLD4) {
            return THRESHOLD4;
        }

        assert(false);
    }

    function exchangeRateIdx(uint threshold) internal pure returns (uint8) {
        if (threshold == THRESHOLD1) {
            return 0;
        }
        if (threshold == THRESHOLD2) {
            return 1;
        }
        if (threshold == THRESHOLD3) {
            return 2;
        }
        if (threshold == THRESHOLD4) {
            return 3;
        }

        assert(false);
    }

    function updateRevertSuspendedPayment(bool value) public grantOwnerOrAdmin {
        revertSuspendedPayment = value;
    }

    /**
     * Transfer Wei sent to the contract directly back to the participant
     *
     * @param participant Participant
     * @param processed Whether or not processed payments should be included
     * @param suspended Whether or not suspended payments should be included
     */
    function returnDirectPayments(address participant, bool processed, bool suspended) internal {
        if (processed && participants[participant].processedDirectWeiAmount > 0) {
            participant.transfer(participants[participant].processedDirectWeiAmount);
            participants[participant].processedDirectWeiAmount = 0;
        }

        if (suspended && participants[participant].suspendedDirectWeiAmount > 0) {
            participant.transfer(participants[participant].suspendedDirectWeiAmount);
            participants[participant].suspendedDirectWeiAmount = 0;
        }
    }

    /**
     * Signal that externally made payments should be returned back to the participant
     *
     * @param participant Participant
     * @param processed Whether or not processed payments should be included
     * @param suspended Whether or not suspended payments should be included
     */
    function returnExternalPayments(address participant, bool processed, bool suspended) internal {
        if (processed && participants[participant].processedExternalWeiAmount > 0) {
            participants[participant].processedExternalWeiAmount = 0;
        }
        
        if (suspended && participants[participant].suspendedExternalWeiAmount > 0) {
            participants[participant].suspendedExternalWeiAmount = 0;
        }
    }

    function setAdmin(address adminAddress) public grantOwner {
        admin = adminAddress;
        require(isAdminSet());
    }

    function transwerFunds(uint amount) public grantOwner {
        require(RELEASE_THRESHOLD <= tokensSold, "There are not enaugh tokens sold");
        
        uint transferAmount = amount;
        uint balance = address(this).balance;

        if (balance < amount) {
            transferAmount = balance;
        }

        owner.transfer(transferAmount);
    } 

    function isAdminSet() internal view returns(bool) {
        return admin != address(0);
    }

    function isAdmin() internal view returns(bool) {
        return isAdminSet() && msg.sender == admin;
    }

    function isCrowdsaleSuccessful() public view returns(bool) {
        return state == CrowdsaleState.Ended && crowdsaleEndedSuccessfully;
    }

    modifier notEnded {
        require(state != CrowdsaleState.Ended, "Crowdsale ended");
        _;
    }

    modifier grantOwnerOrAdmin() {
        require(isOwner() || isAdmin());
        _;
    }
}