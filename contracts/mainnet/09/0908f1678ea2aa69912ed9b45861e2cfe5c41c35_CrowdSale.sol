pragma solidity ^0.4.11;
/*
Original Code from Toshendra Sharma Course at UDEMY
Personalization and modifications by Fares Akel - <span class="__cf_email__" data-cfemail="096f2768677d666760662768626c65496e64686065276a6664">[email&#160;protected]</span>
*/
contract token { function transfer(address receiver, uint amount);
                 function balanceOf(address addr);
                }
contract CrowdSale {
    enum State {
        Fundraising,
        Successful
    }
    State public state = State.Fundraising;
    
    mapping (address => uint) balances;
    address[] contributors;
    uint public totalRaised;
    uint public currentBalance;
    uint public deadline;
    uint public completedAt;
    token public tokenReward;
    address public creator;
    address public beneficiary; 
    string campaignUrl;
    uint constant version = 1;

    event LogFundingReceived(address addr, uint amount, uint currentTotal);
    event LogWinnerPaid(address winnerAddress);
    event LogFundingSuccessful(uint totalRaised);
    event LogFunderInitialized(
        address creator,
        address beneficiary,
        string url,
        uint256 deadline);
    event LogContributorsContributed(address addr, uint amount, uint id);
    event LogContributorsPayout(address addr, uint amount);

    modifier inState(State _state) {
        if (state != _state) revert();
        _;
    }
    modifier isCreator() {
        if (msg.sender != creator) revert();
        _;
    }
    modifier atEndOfLifecycle() {
        if(!(state == State.Successful && completedAt + 1 hours < now)) {
            revert();
        }
        _;
    }
    function CrowdSale(
        uint _timeInMinutesForFundraising,
        string _campaignUrl,
        address _ifSuccessfulSendTo,
        token _addressOfTokenUsedAsReward)
    {
        creator = msg.sender;
        beneficiary = _ifSuccessfulSendTo;
        campaignUrl = _campaignUrl;
        deadline = now + (_timeInMinutesForFundraising * 1 minutes);
        currentBalance = 0;
        tokenReward = token(_addressOfTokenUsedAsReward);
        LogFunderInitialized(
            creator,
            beneficiary,
            campaignUrl,
            deadline);
    }
    function contribute()
    public
    inState(State.Fundraising) payable returns (uint256)
    {
        uint id;

        if(contributors.length == 0){
            contributors.push(msg.sender);
            id=0;
        }
        else{
            for(uint i = 0; i < contributors.length; i++)
            {
                if(contributors[i]==msg.sender)
                {
                    id = i;
                    break;
                }
                else if(i == contributors.length - 1)
                {
                    contributors.push(msg.sender);
                    id = i+1;
                }
            }
        }
        balances[msg.sender]+=msg.value;
        totalRaised += msg.value;
        currentBalance = totalRaised;

        LogContributorsContributed (msg.sender, balances[msg.sender], id);
        LogFundingReceived(msg.sender, msg.value, totalRaised);
        checkIfFundingCompleteOrExpired();

        return contributors.length - 1; 
    }

    function checkIfFundingCompleteOrExpired() {
        if ( now > deadline ) {
            state = State.Successful;
            LogFundingSuccessful(totalRaised);
            finished();  
            completedAt = now;
        }
    }

    function payOut()
    public
    inState(State.Successful)
    {
        if (msg.sender == creator){

            if(!beneficiary.send(this.balance)) {
            revert();

            }

        currentBalance = 0;
        LogWinnerPaid(beneficiary);

        }
        else
        {

            uint amount = 0;
            address add;

            for(uint i=0; i<contributors.length ;i++){
                if (contributors[i]==msg.sender){
                    add = contributors[i];
                    amount = balances[add]*9000000/totalRaised;
                    balances[add] = 0;
                    tokenReward.transfer(add, amount);
                    LogContributorsPayout(add, amount);
                    amount = 0;
                }
            }
        }
    }

    function finished()
    inState(State.Successful)
    {
        if(!beneficiary.send(this.balance)) {
            revert();
        }
        currentBalance = 0;

        LogWinnerPaid(beneficiary);
    }

    function removeContract()
    public
    isCreator()
    atEndOfLifecycle()
    {
        selfdestruct(msg.sender);
    }

    function () payable {
        if (msg.value > 0){
            contribute();
        }
        else revert();
    }
}