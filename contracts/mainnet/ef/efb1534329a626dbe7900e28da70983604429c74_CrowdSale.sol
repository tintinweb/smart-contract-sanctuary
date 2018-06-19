pragma solidity 0.4.11;

contract token { function transfer(address receiver, uint amount);
                 function mintToken(address target, uint mintedAmount);
                }

contract CrowdSale {
    enum State {
        Fundraising,
        Failed,
        Successful,
        Closed
    }
    State public state = State.Fundraising;

    struct Contribution {
        uint amount;
        address contributor;
    }
    Contribution[] contributions;

    
    
    uint public totalRaised;
    uint public currentBalance;
    uint public deadline;
    uint public completedAt;
    uint public priceInWei;
    uint public fundingMinimumTargetInWei; 
    uint public fundingMaximumTargetInWei; 
    token public tokenReward;
    address public creator;
    address public beneficiary; 
    string campaignUrl;
    byte constant version = 1;

    
    event LogFundingReceived(address addr, uint amount, uint currentTotal);
    event LogWinnerPaid(address winnerAddress);
    event LogFundingSuccessful(uint totalRaised);
    event LogFunderInitialized(
        address creator,
        address beneficiary,
        string url,
        uint _fundingMaximumTargetInEther, 
        uint256 deadline);


    modifier inState(State _state) {
        if (state != _state) throw;
        _;
    }

     modifier isMinimum() {
        if(msg.value < priceInWei) throw;
        _;
    }



    modifier isCreator() {
        if (msg.sender != creator) throw;
        _;
    }

    
    modifier atEndOfLifecycle() {
        if(!((state == State.Failed || state == State.Successful) && completedAt + 1 hours < now)) {
            throw;
        }
        _;
    }

    
    function CrowdSale(
        uint _timeInMinutesForFundraising,
        string _campaignUrl,
        address _ifSuccessfulSendTo,
        uint _fundingMinimumTargetInEther,
        uint _fundingMaximumTargetInEther,
        token _addressOfTokenUsedAsReward,
        uint _etherCostOfEachToken)
    {
        creator = msg.sender;
        beneficiary = _ifSuccessfulSendTo;
        campaignUrl = _campaignUrl;
        fundingMinimumTargetInWei = _fundingMinimumTargetInEther * 1 ether; 
        fundingMaximumTargetInWei = _fundingMaximumTargetInEther * 1 ether; 
        deadline = now + (_timeInMinutesForFundraising * 1 minutes);
        currentBalance = 0;
        tokenReward = token(_addressOfTokenUsedAsReward);
        priceInWei = _etherCostOfEachToken ;
        LogFunderInitialized(
            creator,
            beneficiary,
            campaignUrl,
            fundingMaximumTargetInWei,
            deadline);
    }

    function contribute()
    public
    inState(State.Fundraising) isMinimum() payable returns (uint256)
    {
        uint256 amountInWei = msg.value;

        
        contributions.push(
            Contribution({
                amount: msg.value,
                contributor: msg.sender
                }) 
            );

        totalRaised += msg.value;
        currentBalance = totalRaised;


        if(fundingMaximumTargetInWei != 0){
            
            tokenReward.transfer(msg.sender, amountInWei * 1000000000000000000 / priceInWei);
        }
        else{
            tokenReward.mintToken(msg.sender, amountInWei * 1000000000000000000 / priceInWei);
        }

        LogFundingReceived(msg.sender, msg.value, totalRaised);

        

        checkIfFundingCompleteOrExpired();
        return contributions.length - 1; 
    }

    function checkIfFundingCompleteOrExpired() {
        
       
        if (fundingMaximumTargetInWei != 0 && totalRaised > fundingMaximumTargetInWei) {
            state = State.Successful;
            LogFundingSuccessful(totalRaised);
            payOut();
            completedAt = now;
            
            } else if ( now > deadline )  {
                if(totalRaised >= fundingMinimumTargetInWei){
                    state = State.Successful;
                    LogFundingSuccessful(totalRaised);
                    payOut();  
                    completedAt = now;
                }
                else{
                    state = State.Failed; 
                    completedAt = now;
                }
            } 
        
    }

        function payOut()
        public
        inState(State.Successful)
        {
            
            if(!beneficiary.send(this.balance)) {
                throw;
            }

            state = State.Closed;
            currentBalance = 0;
            LogWinnerPaid(beneficiary);
        }

        function getRefund()
        public
        inState(State.Failed) 
        returns (bool)
        {
            for(uint i=0; i<=contributions.length; i++)
            {
                if(contributions[i].contributor == msg.sender){
                    uint amountToRefund = contributions[i].amount;
                    contributions[i].amount = 0;
                    if(!contributions[i].contributor.send(amountToRefund)) {
                        contributions[i].amount = amountToRefund;
                        return false;
                    }
                    else{
                        totalRaised -= amountToRefund;
                        currentBalance = totalRaised;
                    }
                    return true;
                }
            }
            return false;
        }

        function removeContract()
        public
        isCreator()
        atEndOfLifecycle()
        {
            selfdestruct(msg.sender);
            
        }

        function () { throw; }
}