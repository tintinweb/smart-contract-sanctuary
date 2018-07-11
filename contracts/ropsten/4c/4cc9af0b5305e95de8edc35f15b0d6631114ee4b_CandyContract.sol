pragma solidity ^0.4.18;

interface token {
    function transfer(address receiver, uint amount) external;
}

contract CandyContract {

    token public tokenReward;
    uint public totalCandyNo;
    mapping(address => uint256) public balanceOf;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

    /**
     * Constructor function
     */
    constructor(
        address addressOfTokenUsedAsReward
    ) public {
        totalCandyNo = 1e8;
        tokenReward = token(addressOfTokenUsedAsReward);
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () payable public {
        require(totalCandyNo > 0);
        uint amount = getCurrentCandyAmount();
        require(amount > 0); 
        require(balanceOf[msg.sender] == 0);

        totalCandyNo -= amount;
        balanceOf[msg.sender] = amount;

        tokenReward.transfer(msg.sender, amount);
        emit FundTransfer(msg.sender, amount, true);
    }

    function getCurrentCandyAmount() private view returns (uint amount){

        if (totalCandyNo >= 7.5e7){
            return 2000;
        }else if (totalCandyNo >= 5e7){
            return 1500;
        }else if (totalCandyNo >= 2.5e7){
            return 1000;
        }else if (totalCandyNo >= 500){
            return 500;
        }else{
            return 0;
        }
    }
}