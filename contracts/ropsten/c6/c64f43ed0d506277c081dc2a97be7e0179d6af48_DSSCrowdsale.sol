pragma solidity ^0.4.24;

contract owned{
    address public owner;
    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }

    function transferOwnerShip(address newOwer) public onlyOwner{
        owner = newOwer;
    }

}

interface token{
    function transfer(address _to,uint amount) external;
}

contract DSSCrowdsale is owned{

    uint public fundingGoal;
    uint public deadline;
    uint public price;
    token public tokenReward;
    address public beneficiary;

    event FundTransfer(address backer,uint amount);

    constructor (
        uint fundingGoalInEther,
        uint durationInMinutes,
        uint etherCostOfEachToken,
        address addressOfToken)public{

        fundingGoal = fundingGoalInEther *1 ether;
        deadline = now + durationInMinutes * 1 minutes;

        price = etherCostOfEachToken  * 1 wei ;
        tokenReward = token(addressOfToken);
        beneficiary = msg.sender;
        }
    function setPrice(uint newPrice) public onlyOwner{
      price = newPrice * 1 wei;

    }
    function () public payable {
        require(now < deadline);
        uint amount = msg.value;

        uint tokenAmount = amount * price ;

        tokenReward.transfer(msg.sender,tokenAmount);

        beneficiary.transfer(amount);

        emit FundTransfer(msg.sender,amount);
    }
}