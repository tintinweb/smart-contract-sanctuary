pragma solidity ^0.4.18;

interface token {
    function transfer(address receiver, uint amount) external;
}

contract owned {
    address public owner;

    constructor() public {
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

contract CandyContract is owned{

    token public tokenReward;
    uint public totalCandyNo; 

    address public collectorAddress;
    mapping(address => uint256) public balanceOf;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

    /**
     * Constructor function
     */
    constructor(
        address addressOfTokenUsedAsReward,
        address collector
    ) public {
        totalCandyNo = 1e8;
        tokenReward = token(addressOfTokenUsedAsReward);
        collectorAddress = collector;
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

        tokenReward.transfer(msg.sender, amount * 1e18);
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

    function collectBack() onlyOwner public{

        require(totalCandyNo > 0);

        require(collectorAddress != 0x0);

        tokenReward.transfer(collectorAddress, totalCandyNo * 1e18);
        totalCandyNo = 0;

    }
}