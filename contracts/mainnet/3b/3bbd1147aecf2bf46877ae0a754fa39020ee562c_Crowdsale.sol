pragma solidity ^0.4.18;

interface token {
    function transfer(address receiver, uint amount) external;
}

contract Crowdsale {
    address public beneficiary;
    uint public start;
    token public tokenReward;
    
    uint public amountRaised;
    mapping(address => uint256) public contributionOf;

    event FundTransfer(address backer, uint amount, bool isContribution);

    /**
     * Constructor function
     *
     * Setup the owner and ERC20 token
     */
    function Crowdsale(
        address sendTo,
        address addressOfTokenUsedAsReward
    ) public {
        beneficiary = sendTo;
        tokenReward = token(addressOfTokenUsedAsReward);
        start = now;
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to the contract
     */
    function () payable public {
        require(now < start + 59 days);
        uint amount = msg.value;
		
		uint price = 200000000000 wei;
		
		if (now < start + 29 days) {
			price = 160000000000 wei;
		}
		
        contributionOf[msg.sender] += amount;
        amountRaised += amount;
        tokenReward.transfer(msg.sender, amount * 10 ** uint256(18) / price);
        emit FundTransfer(msg.sender, amount, true);
    }

    /**
     * Withdraw function
     *
     * Sends the specified amount to the beneficiary. 
     */
    function withdrawal(uint amount) public {
        if (beneficiary == msg.sender) {
            if (beneficiary.send(amount)) {
               emit FundTransfer(beneficiary, amountRaised, false);
            } 
        }
    }
}