pragma solidity ^0.4.18;
// This contract has the burn option
interface token {
    function transfer(address receiver, uint amount);
    function burn(uint256 _value) returns (bool);
    function balanceOf(address _address) returns (uint256);
}
contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract SafeMath {
    //internals

    function safeMul(uint a, uint b) internal returns(uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns(uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns(uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

}

contract Crowdsale is owned, SafeMath {
    address public beneficiary;
    uint public fundingGoal;
    uint public amountRaised;  //The amount being raised by the crowdsale
    uint public deadline; /* the end date of the crowdsale*/
    uint public rate; //rate for the crowdsale
    uint public tokenDecimals;
    token public tokenReward; //UZZZ
    uint public tokensSold = 0;  //the amount of UzmanbuCoin sold  
    uint public start; /* the start date of the crowdsale*/
    uint public bonusEndDate;
    mapping(address => uint256) public balanceOf;  //Ether deposited by the investor
    bool crowdsaleClosed = false; //It will be true when the crowsale gets closed

    event GoalReached(address beneficiary, uint capital);
    event FundTransfer(address backer, uint amount, bool isContribution);

    /**
     * Constrctor function
     *
     * Setup the owner
     */
    function Crowdsale( ) {
        beneficiary = 0x071ED6F131Fb63958504eb3ebdeE9aeD07cF9187;
        rate = 80000; // 8.000.000 UZZZ/Ether (UZZZ has 8 decimals and ETH has 18)
        tokenDecimals=8;
        fundingGoal = 2500000000 * (10 ** tokenDecimals); 
        start = 1536359340; //      12/11/2017 @ 2:00pm (UTC)
        deadline = 1537655340; //    01/10/2018 @ 11:59pm (UTC)
        bonusEndDate =1537482540;
        tokenReward = token(0x07c3a656a937d6890320937914e8bb5e7cfa456d); //Token address. Modify by the current token address
    }    

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
     /*
   
     */
    function () payable {
        uint amount = msg.value;  //amount received by the contract
        uint numTokens; //number of token which will be send to the investor
        numTokens = getNumTokens(amount);   //It will be true if the soft capital was reached
        require(numTokens>0 && !crowdsaleClosed && now > start && now < deadline);
        balanceOf[msg.sender] = safeAdd(balanceOf[msg.sender], amount);
        amountRaised = safeAdd(amountRaised, amount); //Amount raised increments with the amount received by the investor
        tokensSold += numTokens; //Tokens sold increased too
        tokenReward.transfer(msg.sender, numTokens); //The contract sends the corresponding tokens to the investor
        beneficiary.transfer(amount);               //Forward ether to beneficiary
        FundTransfer(msg.sender, amount, true);
    }
    /*
    It calculates the amount of tokens to send to the investor 
    */
    function getNumTokens(uint _value) internal returns(uint numTokens) {
        require(_value>=10000000000000000 * 1 wei); //Min amount to invest: 0.01 ETH
        numTokens = safeMul(_value,rate)/(10 ** tokenDecimals); //Number of tokens to give is equal to the amount received by the rate 
        
        if(now <= bonusEndDate){
            if(_value>= 1 ether && _value< 5 * 1 ether){ // +15% tokens
                numTokens += safeMul(numTokens,15)/100;
            }else if(_value>=5 * 1 ether){              // +35% tokens
                numTokens += safeMul(numTokens,35)/100;
            }
        }

        return numTokens;
    }

    function changeBeneficiary(address newBeneficiary) onlyOwner {
        beneficiary = newBeneficiary;
    }

    modifier afterDeadline() { if (now >= deadline) _; }

    /**
     * Check if goal was reached
     *
     * Checks if the goal or time limit has been reached and ends the campaign and burn the tokens
     */
    function checkGoalReached() afterDeadline {
        require(msg.sender == owner); //Checks if the one who executes the function is the owner of the contract
        if (tokensSold >=fundingGoal){
            GoalReached(beneficiary, amountRaised);
        }
        tokenReward.burn(tokenReward.balanceOf(this)); //Burns all the remaining tokens in the contract 
        crowdsaleClosed = true; //The crowdsale gets closed if it has expired
    }



}