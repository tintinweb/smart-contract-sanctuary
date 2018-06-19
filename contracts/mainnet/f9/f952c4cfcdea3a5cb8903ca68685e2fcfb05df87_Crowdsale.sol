pragma solidity ^0.4.23;

interface token {
    function transfer(address receiver, uint amount);
}

contract Crowdsale {
    address public beneficiary;
    uint public amountRaised;
    token public tokenReward;
    uint256 public soldTokensCounter;
    uint public price;
    uint public saleStage = 1;
    bool public crowdsaleClosed = false;
    bool public adminVer = false;
    mapping(address => uint256) public balanceOf;


    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, uint price, bool isContribution);

    function Crowdsale() {
        beneficiary = 0x35DCD7055D7586E1C6d67307EefDADDdc194f000;
        tokenReward = token(0xde744F433567d45701E7D6963F799E5cdDA12F5e);
    }

    modifier onlyOwner {
        require(msg.sender == beneficiary);
        _;
    }

    function checkAdmin() onlyOwner {
        adminVer = true;
    }

    function changeStage(uint stage) onlyOwner {
        saleStage = stage;
    }

    function getUnsoldTokens(uint val_) onlyOwner {
        tokenReward.transfer(beneficiary, val_);
    }

    function getUnsoldTokensWithDecimals(uint val_, uint dec_) onlyOwner {
        val_ = val_ * 10 ** dec_;
        tokenReward.transfer(beneficiary, val_);
    }

    function closeCrowdsale(bool closeType) onlyOwner {
        crowdsaleClosed = closeType;
    }

    function getPrice() returns (uint) {
        if (amountRaised > 8000 ether || saleStage == 4) {
            return 0.000066667 ether;
        } else if (amountRaised > 6000 ether || saleStage == 3) {
            return 0.000057143 ether;
        } else if (amountRaised > 3000 ether || saleStage == 2) {
            return 0.000050000 ether;
        }
        return 0.000044444 ether;
    }

    function () payable {
        require(!crowdsaleClosed && msg.value >= 0.01 ether);
        price = getPrice();
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        uint sendTokens = (amount / price) * 10 ** uint256(18);
        tokenReward.transfer(msg.sender, sendTokens);
        soldTokensCounter += sendTokens;
        FundTransfer(msg.sender, amount, price, true);
        if (beneficiary.send(amount)) { FundTransfer(beneficiary, amount, price, false); }
    }
}