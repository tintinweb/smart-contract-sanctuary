pragma solidity ^0.4.13;


contract BM_MasterClass_Reserved {
    mapping (address => uint256) public holders;
    uint256 public amount_investments = 0;
    uint256 public countHolders = 0;

    uint256 public dtStart = 1502737200; //14.08.2017 22:00 MSK
    uint256 public dtEnd = 1502910000; //16.08.2017 22:00 MSK

    uint256 public minSizeInvest = 100 finney;

    address public owner;

    event Investment(address holder, uint256 value);

    function BM_MasterClass_Reserved(){
        owner = msg.sender;
    }

    modifier isOwner()
    {
        assert(msg.sender == owner);
        _;
    }

    function changeOwner(address new_owner) isOwner {
        assert(new_owner!=address(0x0));
        assert(new_owner!=address(this));
        owner = new_owner;
    }

    function getDataHolders(address holder) external constant returns(uint256)
    {
        return holders[holder];
    }

    function sendInvestmentsToOwner() isOwner {
        assert(now >= dtEnd);
        owner.transfer(this.balance);
    }

    function () payable {
        assert(now < dtEnd);
        assert(now >= dtStart);
        assert(msg.value>=minSizeInvest);

        if(holders[msg.sender] == 0){
            countHolders += 1;
        }
        holders[msg.sender] += msg.value;
        amount_investments += msg.value;
        Investment(msg.sender, msg.value);
    }
}