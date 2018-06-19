pragma solidity ^0.4.19;

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

    event FundTransfer(address backer, uint amount, uint price, bool isContribution);

    /**
     * Constrctor function
     *
     * Setup the owner
     */
    function Crowdsale() {
        beneficiary = msg.sender;
        tokenReward = token(0x745Fa4002332C020f6a05B3FE04BCCf060e36dD3);
    }

    modifier onlyOwner {
        require(msg.sender == beneficiary);
        _;
    }

    /**
     * Check ownership
     */
    function checkAdmin() onlyOwner {
        adminVer = true;
    }

    /**
     * Change crowdsale discount stage
     */
    function changeStage(uint stage) onlyOwner {
        saleStage = stage;
    }

    /**
     * Return unsold tokens to beneficiary address
     */
    function getUnsoldTokens(uint val_) onlyOwner {
        tokenReward.transfer(beneficiary, val_);
    }

    /**
     * Return unsold tokens to beneficiary address with decimals
     */
    function getUnsoldTokensWithDecimals(uint val_, uint dec_) onlyOwner {
        val_ = val_ * 10 ** dec_;
        tokenReward.transfer(beneficiary, val_);
    }

    /**
     * Close/Open crowdsale
     */
    function closeCrowdsale(bool closeType) onlyOwner {
        crowdsaleClosed = closeType;
    }

    /**
     * Return current token price
     *
     * The price depends on `saleStage` and `amountRaised`
     */
    function getPrice() returns (uint) {
        if (saleStage == 4) {
            return 0.0002000 ether;
        } else if (saleStage == 3) {
            return 0.0001667 ether;
        } else if (saleStage == 2) {
            return 0.0001429 ether;
        }
        return 0.000125 ether;
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () payable {
        require(!crowdsaleClosed);                                                         
        price = getPrice();                                                                //get current token price
        uint amount = msg.value;                                                           //save users eth value
        balanceOf[msg.sender] += amount;                                                   //save users eth value in balance list 
        amountRaised += amount;                                                            //update total amount of crowdsale
        uint sendTokens = (amount / price) * 10 ** uint256(18);                            //calculate user&#39;s tokens
        tokenReward.transfer(msg.sender, sendTokens);                                      //send tokens to user
        soldTokensCounter += sendTokens;                                                   //update total sold tokens counter
        FundTransfer(msg.sender, amount, price, true);                                     //pin transaction data in blockchain
        if (beneficiary.send(amount)) { FundTransfer(beneficiary, amount, price, false); } //send users amount to beneficiary
    }
}