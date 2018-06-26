pragma solidity ^0.4.24;

/******************************************/
/*      Netkiller Crowdsale Contract      */
/******************************************/
/* Author netkiller <netkiller@msn.com>   */
/* Home http://www.netkiller.cn           */
/* Version 2018-06-07 - Solc ver: 0.4.24  */
/******************************************/

interface token {
    function transfer(address receiver, uint amount) external;
}

contract NetkillerExchange {
    address owner;
    uint public price;
    token public tokenContract;

    //event GoalReached(address recipient, uint totalAmountRaised);
    //event FundTransfer(address backer, uint amount, bool isContribution);

    /**
     * Constructor function
     *
     * Setup the owner
     */
    constructor(
        address _owner,
        address _token
    ) public {
        //price = etherCostOfEachToken * 1 ether;
        owner = _owner;
        tokenContract = token(_token);
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () payable public{
        //require(!crowdsaleClosed);
        uint amount = msg.value;
        owner.transfer(amount);
        //balanceOf[msg.sender] += amount;
        //amountRaised += amount;
        //tokenContract.transfer(msg.sender, amount / price);
        tokenContract.transfer(msg.sender, 10000);
        //emit FundTransfer(msg.sender, amount, true);
    }
}