pragma solidity ^0.4.21;

interface token {
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
}

contract Crowdsale {
    address public owner;
    address public SSOTHEALTH_FUNDS_ADDRESS = 0x4F1Fa6F553AF4696f00FCad6f495D3F1eB1BE2fe;   // SSOT Health Funds address
    address public SEHR_WALLET_ADDRESS = 0xcA027bF2179325B9D31689cdbFbf242aF34c79DE;        // SEHR Main token wallet
    token public tokenReward = token(0xE8c881422CA4c2ab9a9bC9d58e75178e0e28eEd5);           // SEHR contract address
    uint public fundingGoal = 100000000 * 1 ether;  // 100,000,000 SEHRs softcap 
    uint public hardCap = 500000000 * 1 ether;      // 500,000,000 SEHRs hardcap
    uint public amountRaised = 0;
    uint public sehrRaised = 0;
    uint public startTime;
    uint public deadline;
    uint public price = 80 szabo;                   // 0.00008 ETH/SEHR  ; 1 szabo = 10^-6 Ether
    mapping(address => uint256) public balanceOf;
    
    bool public fundingGoalReached = false;
    bool public crowdsaleClosed = false;
    bool public checkDone = false;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

    /**
     * Constructor function
     *
     * Setup the owner
     */
    function Crowdsale() public
    {
        startTime = now;
        deadline = now + 62 days;
        owner = msg.sender;
    }
    
    modifier afterDeadline() { if (now >= deadline) _; }
    modifier beforeDeadline() { if (now < deadline) _; }
    modifier isCrowdsale() { if (!crowdsaleClosed) _; }
    modifier isCheckDone() { if (checkDone) _; }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () payable isCrowdsale beforeDeadline public {
        uint amount = msg.value;
        
        if(amount == 0 ) revert();   // Need to send some ether at least
        else if( amount < 250 finney) {
            if (sehrRaised < fundingGoal) {
                if(now < startTime + 31 days) revert();    // Need to invest at least 0.25 Ether during the pre-sale if the funding goal hasn&#39;t been reached yet
            }
        }
        
        uint tokenAmount = (amount / price) * 1 ether; // We compute the number of tokens to issue
        
        if(sehrRaised < fundingGoal) {  // Bonus available for any tokens bought before softcap is reached
            
            if(now < startTime + 10 days) {
                tokenAmount = (13 * tokenAmount) / 10; // 30% bonus during the first 10-day period
            }
            
            else if(now < startTime + 20 days) {
                tokenAmount = (12 * tokenAmount) / 10;     // 20% bonus during the second 10-day period
            }
            
            else if(now < startTime + 31 days) {
                tokenAmount = (11 * tokenAmount) / 10;     // 10% bonus during the third 10-day period
            }
        }
        
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        sehrRaised += tokenAmount;
        
        tokenReward.transferFrom(SEHR_WALLET_ADDRESS, msg.sender, tokenAmount); // will automatically throw is there are not enough funds remaining in the contract
        emit FundTransfer(msg.sender, amount, true);
    }


    /**
     * Check if goal was reached
     *
     * Checks if the goal or time limit has been reached and ends the campaign
     */
    function checkGoalReached() afterDeadline public {
        if (sehrRaised >= fundingGoal){
            fundingGoalReached = true;
            emit GoalReached(SSOTHEALTH_FUNDS_ADDRESS, amountRaised);
        }
        crowdsaleClosed = true;
        checkDone = true;
    }


    /**
     * Withdraw the funds
     *
     * Checks to see if goal or time limit has been reached, and if so, and the funding goal was reached,
     * sends the entire amount to the beneficiary. If goal was not reached, each contributor can withdraw
     * the amount they contributed.
     */
    function safeWithdrawal() afterDeadline isCheckDone public{
        if (!fundingGoalReached) {
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                    emit FundTransfer(msg.sender, amount, false);
                } else {
                    balanceOf[msg.sender] = amount;
                }
            }
        }

        if (fundingGoalReached && SSOTHEALTH_FUNDS_ADDRESS == msg.sender) {
            if (SSOTHEALTH_FUNDS_ADDRESS.send(amountRaised)) {
                emit FundTransfer(SSOTHEALTH_FUNDS_ADDRESS, amountRaised, false);
            } else {
                //If we fail to send the funds to beneficiary, unlock funders balance
                fundingGoalReached = false;
            }
        }
    }
    
    function hardCapReached() public {
        if(sehrRaised == hardCap) {
            deadline = now;
        }
        else revert();
    }
}