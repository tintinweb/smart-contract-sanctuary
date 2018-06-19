pragma solidity ^0.4.18;
interface token {
    function transfer(address receiver, uint amount) public;                                    // Transfer function for transferring tokens
    function getBalanceOf(address _owner) public constant returns (uint256 balance);            // Getting the balance from the main contract
}
contract Presale {
    address public beneficiary;                     // Who is the beneficiary of this contract
    uint public fundingLimit;                       // The maximum ether allowed in this sale
    uint public amountRaised;                       // The total amount raised during presale
    uint public deadline;                           // The deadline for this contract
    uint public tokensPerEther;                     // Tokens received as a reward of participating in this pre sale
    uint public minFinnRequired;                    // Minimum Finney needed to participate in this pre sale
    uint public startTime;                          // StartTime for the presale
    token public tokenReward;                       // The token contract it refers too
    
    mapping(address => uint256) public balanceOf;   // Mapping of all balances in this contract
    event FundTransfer(address backer, uint amount, bool isContribution);   // Event of fund transfer to show each transaction
    /**
     * Constrctor function
     *
     * Setup the owner
     */
    function Presale(
        address ifSuccessfulSendTo,
        uint fundingLimitInEthers,
        uint durationInMinutes,
        uint tokensPerEthereum,
        uint minFinneyRequired,
        uint presaleStartTime,
        address addressOfTokenUsedAsReward
    ) public {
        beneficiary = ifSuccessfulSendTo;
        fundingLimit = fundingLimitInEthers * 1 ether;
        deadline = presaleStartTime + durationInMinutes * 1 minutes;
        tokensPerEther = tokensPerEthereum;
        minFinnRequired = minFinneyRequired * 1 finney;
        startTime = presaleStartTime;
        tokenReward = token(addressOfTokenUsedAsReward);
    }
    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () payable public {
        require(startTime <= now);
        require(amountRaised < fundingLimit);
        require(msg.value >= minFinnRequired);
        
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokenReward.transfer(msg.sender, amount * tokensPerEther);
        FundTransfer(msg.sender, amount, true);
    }
    /**
     * Withdraw the funds
     *
     * Checks to see if goal or time limit has been reached, and if so, and the funding goal was reached,
     * sends the entire amount to the beneficiary. If goal was not reached, each contributor can withdraw
     * the amount they contributed.
     */
    function withdrawFundBeneficiary() public {
        require(now >= deadline);
        require(beneficiary == msg.sender);
        uint remaining = tokenReward.getBalanceOf(this);
        if(remaining > 0) {
            tokenReward.transfer(beneficiary, remaining);
        }
        if (beneficiary.send(amountRaised)) {
            FundTransfer(beneficiary, amountRaised, false);
        } else {
            revert();
        }
    }
}