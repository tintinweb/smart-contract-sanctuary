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
    Token public blurToken;
    address public owner;

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    /**
     * Constrctor function
     *
     * Setup the owner
     */
    constructor(address _beneficiary, address _token, uint _startTime, uint _endTime) public {
        beneficiary = _beneficiary;
        startTime = _startTime;
        endTime = _endTime;
        price = 80000;
        blurToken = Token(_token);
        owner = msg.sender;
    }



    function isActive() public view returns (bool) {

        return (
            now >= startTime && // Must be after the START date
            now <= endTime // Must be before the end date
            );
    }

    function changePrice(uint _newPrice) public onlyOwner{ 
        require(_newPrice > 0);
        price = _newPrice;
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    event FundTransfer(address backer, uint amount, bool isContribution);

    function () public payable {
        require(isActive());
        uint amount = msg.value;
        amountRaised += amount;
        uint TokenAmount = uint((msg.value * price));
        blurToken.transfer(msg.sender, TokenAmount);
        beneficiary.transfer(msg.value);
        emit FundTransfer(msg.sender, amount, true);
    }

    event CrowdsaleFinished(uint amount, address beneficiary);
    
    function finish() public {
        require(now > endTime);
        uint balance = blurToken.balanceOf(address(this));
        if(balance > 0){
            emit CrowdsaleFinished(balance, beneficiary);
            blurToken.transfer(beneficiary, balance);
        }
    }

}