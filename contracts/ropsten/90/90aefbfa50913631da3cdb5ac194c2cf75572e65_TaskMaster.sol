pragma solidity ^0.4.17;


contract TaskMaster {
    mapping (address => uint) public balances; // balances of everyone
    address public owner; // owner of the contract

    constructor() public {
        owner = msg.sender;
        balances[msg.sender] = 10000;
    }

    function reward(address doer, uint rewardAmount)
        public
        isOwner()
        hasSufficientFunds(rewardAmount)
        returns(bool sufficientFunds)
    {
        balances[msg.sender] -= rewardAmount;
        balances[doer] += rewardAmount;
        return sufficientFunds;
    }

    function getBalance(address addr) public view returns(uint) {
        return balances[addr];
    }

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier hasSufficientFunds(uint rewardAmount) {
        require(balances[msg.sender] >= rewardAmount);
        _;
    }
}