pragma solidity ^0.4.25;

interface token {
    function transfer(address receiver, uint amount) external;
}

contract Owned {
    address public owner;
    constructor () public {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract TibaTokenCrowdSale is Owned{
    address public beneficiary;
    uint public fundingGoal;
    uint public amountRaised;
    uint256 tokenSold;
    string  Stage;
    uint public deadline;
    uint public price;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool public fundingGoalReached = false;
    bool public crowdsaleClosed = false;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    event DeadLine(uint _deadline, uint _price, string _Stage);
    event CrowdsaleState(address _sender,bool _crowdsaleClosed);
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
        deadline = (now + durationInMinutes) * 1 minutes;
        price = etherCostOfEachToken ;
        tokenReward = token(addressOfTokenUsedAsReward);
    }
    
    
    //0xBD1C6F6cDc89d03798E85983EEFA4536c558d7fE,2000,2000000,1000000000000,0x5b7524F732895978895e357FFb6242b8e5253CD4
    function ChangeDeadLine(uint durationInMinutes, uint newPrice, string newStage) onlyOwner public {
        
        deadline = (now + durationInMinutes) * 1 minutes;
        price = newPrice ;
        Stage = newStage;
        emit DeadLine( deadline, price, Stage);
    }
    
     function OpenClose(bool _crowdsaleClosed) onlyOwner public {
        
        crowdsaleClosed = _crowdsaleClosed;
       
        emit CrowdsaleState( msg.sender, crowdsaleClosed);
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () payable public {
       buy();
    }
    
    function buy()  payable public{
        require(!crowdsaleClosed);
        uint256 amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        uint256 tokenForSale = amount / price;
        tokenReward.transfer(msg.sender, tokenForSale);
      emit FundTransfer(msg.sender, amount, true);
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
    }


    /**
     * Withdraw the funds
     *
     * Checks to see if goal or time limit has been reached, and if so, and the funding goal was reached,
     * sends the entire amount to the beneficiary. If goal was not reached, each contributor can withdraw
     * the amount they contributed.
     */
    function safeWithdrawal() onlyOwner public afterDeadline {

        if ( beneficiary == msg.sender) {
            if (beneficiary.send(amountRaised)) {
               emit FundTransfer(beneficiary, amountRaised, false);
            } else {
                //If we fail to send the funds to beneficiary, unlock funders balance
                fundingGoalReached = false;
            }
        }
    }
}