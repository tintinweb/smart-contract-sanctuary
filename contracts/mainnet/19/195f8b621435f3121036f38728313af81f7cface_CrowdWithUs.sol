pragma solidity 0.4.11;

contract CrowdWithUs {
    
    address public creator;
    address public fundRecipient; // creator may be different than recipient
    uint public minimumToRaise; // required to reach at least this much, else everyone gets refund
    string campaignUrl; 
    byte constant version = 1;

    // Data structures
    enum State {
        Fundraising,
        ExpiredRefund,
        Successful,
        Closed
    }

    struct Contribution {
        uint amount;
        address contributor;
    }

    // State variables
    State public state = State.Fundraising; // initialize on create
    uint public totalRaised;
    uint public currentBalance;
    uint public raiseBy;
    uint public completeAt;
    Contribution[] contributions;

    event LogFundingReceived(address addr, uint amount, uint currentTotal);
    event LogWinnerPaid(address winnerAddress);
    event LogFunderInitialized(
        address creator,
        address fundRecipient,
        string url,
        uint _minimumToRaise, 
        uint256 raiseby
    );

    modifier inState(State _state) {
        if (state != _state) throw;
        _;
    }

    modifier isCreator() {
        if (msg.sender != creator) throw;
        _;
    }

    // Wait 1 hour after final contract state before allowing contract destruction
    modifier atEndOfLifecycle() {
        if(!((state == State.ExpiredRefund || state == State.Successful) && completeAt + 1 hours < now)) {
            throw;
        }
        _;
    }

    function CrowdWithUs(
        uint timeInHoursForFundraising,
        string _campaignUrl,
        address _fundRecipient,
        uint _minimumToRaise)
    {
        creator = msg.sender;
        fundRecipient = _fundRecipient;
        campaignUrl = _campaignUrl;
        minimumToRaise = _minimumToRaise * 1 ether; //convert to wei
        raiseBy = now + (timeInHoursForFundraising * 1 hours);
        currentBalance = 0;
        LogFunderInitialized(
            creator,
            fundRecipient,
            campaignUrl,
            minimumToRaise,
            raiseBy);
    }

    function contribute()
    public
    inState(State.Fundraising) payable returns (uint256)
    {
        contributions.push(
            Contribution({
                amount: msg.value,
                contributor: msg.sender
                }) // use array, so can iterate
            );
        totalRaised += msg.value;
        currentBalance = totalRaised;
        LogFundingReceived(msg.sender, msg.value, totalRaised);

        checkIfFundingCompleteOrExpired();
        return contributions.length - 1; // return id
    }

    function checkIfFundingCompleteOrExpired() {
        if (totalRaised > minimumToRaise) {
            state = State.Successful;
            payOut();

            // could incentivize sender who initiated state change here
            } else if ( now > raiseBy )  {
                state = State.ExpiredRefund; // backers can now collect refunds by calling getRefund(id)
            }
            completeAt = now;
        }

        function payOut()
        public
        inState(State.Successful)
        {
            if(!fundRecipient.send(this.balance)) {
                throw;
            }
            state = State.Closed;
            currentBalance = 0;
            LogWinnerPaid(fundRecipient);
        }

        function getRefund(uint256 id)
        public
        inState(State.ExpiredRefund) 
        returns (bool)
        {
            if (contributions.length <= id || id < 0 || contributions[id].amount == 0 ) {
                throw;
            }

            uint amountToRefund = contributions[id].amount;
            contributions[id].amount = 0;

            if(!contributions[id].contributor.send(amountToRefund)) {
                contributions[id].amount = amountToRefund;
                return false;
            }
            else{
                totalRaised -= amountToRefund;
                currentBalance = totalRaised;
            }

            return true;
        }

        function removeContract()
        public
        isCreator()
        atEndOfLifecycle()
        {
            selfdestruct(msg.sender);
            // creator gets all money that hasn&#39;t be claimed


        }

        function () { throw; }
    }