pragma solidity 0.4.24;

contract Token {
    function transfer(address receiver, uint amount) public;
    function balanceOf(address _address) public returns(uint);
}

contract Crowdsale {

    address public beneficiary;
    uint public amountRaised;
    uint public startTime;
    uint public endTime;
    uint public price;
    Token public tokenReward;
    address public owner;

    event FundTransfer(address backer, uint amount, bool isContribution);

    /**
     * Constrctor function
     *
     * Setup the owner
     */
    function Crowdsale() public {
        beneficiary = address(0x02063eFBC5653989BdDeddaCD3949260aC451ee2);
        startTime = 1530403200;
        endTime = 1533081599;
        price = 5000;
        tokenReward = Token(0xa5982ff8a26818d6a78a0bc49f080d4a96dd0491);
    }



    function isActive() constant returns (bool) {

        return (
            now >= startTime && // Must be after the START date
            now <= endTime // Must be before the end date
            
            );
    }


    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () public payable {
        require(isActive());
        uint amount = msg.value;
        amountRaised += amount;
        uint TokenAmount = uint((msg.value/(10 ** 10)) * price);
        tokenReward.transfer(msg.sender, TokenAmount);
        beneficiary.transfer(msg.value);
        FundTransfer(msg.sender, amount, true);
    }

    function finish() public {
        require(now > endTime);
        uint balance = tokenReward.balanceOf(address(this));
        if(balance > 0){
            tokenReward.transfer(address(0x02063eFBC5653989BdDeddaCD3949260aC451ee2), balance);
        }
    }

}