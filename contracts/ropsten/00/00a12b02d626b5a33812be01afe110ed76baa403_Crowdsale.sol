pragma solidity ^0.4.24;

interface token {
    function transfer(address receiver, uint amount) external;
    function balanceOf(address tokenOwner) external;
}

contract Crowdsale {
    address public beneficiary;
    uint public fundingGoal;
    uint public amountRaised;
    uint public deadline;
    uint public price;
    token public tokenReward;
    mapping(address => uint256) public ethBalanceOf;
    mapping(address => uint256) public tokenOf;
    mapping(uint => address) public tokenOwner;
    uint totalOwner;
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    event FundingGoalReached(bool reached);
    event TokensFor(address tokenOwner, uint tokens);
    event TransferTokens(address receiver, uint tokens);

    /**
     * Constructor function
     *
     * Setup the owner
     */
     constructor (
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint etherCostOfEachToken,
        address addressOfTokenUsedAsReward
    ) public {
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers * 1 ether;
        deadline = now + durationInMinutes * 1 minutes;
        price = etherCostOfEachToken * 1 ether;
        price = price / 1000;
        tokenReward = token(addressOfTokenUsedAsReward);
        
        totalOwner = 0;
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () payable public {
        require(!crowdsaleClosed);
        uint amount = msg.value;
        ethBalanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokenOf[msg.sender] = amount / price;
        totalOwner++;
        tokenOwner[totalOwner] = msg.sender;
        emit TokensFor(msg.sender, amount / price);
        //tokenReward.transfer(msg.sender, amount / price);
        //emit FundTransfer(msg.sender, amount, true);
    }

    modifier afterDeadline() { if (now >= deadline) _; }

    /**
     * Check if goal was reached
     *
     * Checks if the goal or time limit has been reached and ends the campaign
     */
    function checkGoalReached() public afterDeadline {
        if (amountRaised >= fundingGoal){
            fundingGoalReached = true;
            emit GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
        emit FundingGoalReached(fundingGoalReached);
    }


    /**
     * Withdraw the funds
     *
     * Checks to see if goal or time limit has  been reached, and if so, and the funding goal was reached,
     * sends the entire amount to the beneficiary. If goal was not reached, each contributor can withdraw
     * the amount they contributed.
     */
    function safeWithdrawal() public afterDeadline {
        if (!fundingGoalReached) {
            uint amount = ethBalanceOf[msg.sender];
            if (amount > 0) {
                if (msg.sender.send(amount)) {
                   emit FundTransfer(msg.sender, amount, false);
                   //Hole Tokens zur�ck
                   //uint tokensRefund = balanceOf[msg.sender] * price;
                   //tokenReward.transfer(address(msg.sender), tokensRefund);
                   
                   //emit FundTransfer(address(msg.sender), tokensRefund, false);
                   
                } else {
                    ethBalanceOf[msg.sender] = amount;
                }
            }
        }
        //Token Transfer muss bearbeitet werden - token transfer auch wenn Crowdfunding fehlschl�gt und r�ckerstattung eintritt
        if (fundingGoalReached && beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
               emit FundTransfer(beneficiary, amountRaised, false);
               tokenReward.transfer(beneficiary, address(this).balance);
               emit FundTransfer(beneficiary, address(this).balance, false);
            } else {
                //If we fail to send the funds to beneficiary, unlock funders balance
                fundingGoalReached = false;
                emit FundingGoalReached(fundingGoalReached);
            }
        }
        /*
        address test;
        if(tokenReward.balanceOf(test) > 0) {
            //Schicke restliche Tokens zur&#252;ck
            
            address addresse = address(this);
            uint amountToken = tokenReward.balanceOf(addresse);
            tokenReward.transfer(beneficiary, amountToken);
            emit TransferTokens(beneficiary, balanceOfCall(address(this)));
            
        }
*/
    }
    
    function refundTokens() public afterDeadline{
        if(fundingGoalReached) {
            for(uint i = 0; i <= totalOwner; i++) {
                tokenReward.transfer(tokenOwner[i], tokenOf[tokenOwner[i]]);
                emit FundTransfer(tokenOwner[i], tokenOf[tokenOwner[i]], false);
                tokenOf[tokenOwner[i]] = 0;
                tokenOwner[i] = 0;
            }
            totalOwner = 0;
        }
    }
}