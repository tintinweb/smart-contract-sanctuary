// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./CoinvestingDeFiToken.sol";
import "./Ownable.sol";

contract CoinvestingDeFiTokenSale is Ownable {
    // Public variables
    CoinvestingDeFiToken public tokenContract;
    uint public bonusLevelOne = 50;
    uint public bonusLevelTwo = 35;
    uint public bonusLevelThree = 20;
    uint public bonusLevelFour = 5;
    uint public calculatedBonus;    
    uint public levelOneDate;
    uint public levelTwoDate;
    uint public levelThreeDate;
    uint public levelFourDate;
    uint public tokenBonus;
    uint public tokenPrice;
    uint public tokenSale;
    uint public tokensSold;
    
    // Internal variables
    bool internal contractSeted = false;

    // Events
    event Received(address, uint);
    event Sell(address _buyer, uint _amount);
    event SetPercents(uint _bonusLevelOne, uint _bonusLevelTwo, uint _bonusLevelThree, uint _bonusLevelFour);
    
    // Modifiers
    modifier canContractSet() {
        require(!contractSeted, "Set contract token is not allowed!");
        _;
    }

    // Constructor
    constructor(uint _levelOneDate, uint _levelTwoDate, uint _levelThreeDate, uint _levelFourDate) payable {
        levelOneDate = _levelOneDate * 1 seconds;
        levelTwoDate = _levelTwoDate * 1 days;
        levelThreeDate = _levelThreeDate * 1 days;
        levelFourDate = _levelFourDate * 1 days;
    }

    // Receive function
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    // External functions
    function endSale() external onlyOwner {
        require(
            tokenContract.transfer(
                msg.sender,
                tokenContract.balanceOf(address(this))
            ),
            "Unable to transfer tokens to admin!"
        );
        // destroy contract
        payable(msg.sender).transfer(address(this).balance);
        contractSeted = false;
    }

    function setTokenContract(CoinvestingDeFiToken _tokenContract) external onlyOwner canContractSet {
        tokenContract = _tokenContract;
        contractSeted = true;
        tokenBonus = tokenContract.balanceOf(address(this)) / 3;
        tokenSale = tokenContract.balanceOf(address(this)) - tokenBonus;        
    }

    function setPercents(
        uint _bonusLevelOne,
        uint _bonusLevelTwo,
        uint _bonusLevelThree,
        uint _bonusLevelFour
    ) 
    external 
    onlyOwner {
        require(_bonusLevelOne <= 50, "L1 - Maximum 50 %.");
        require(_bonusLevelTwo <= bonusLevelOne, "L2 - The maximum value must be the current L1.");
        require(_bonusLevelThree <= bonusLevelTwo, "L3 - The maximum value must be the current L2.");
        require(_bonusLevelFour <= bonusLevelThree, "L4 - The maximum value must be the current L3.");
        bonusLevelOne = _bonusLevelOne;
        bonusLevelTwo = _bonusLevelTwo;
        bonusLevelThree = _bonusLevelThree;
        bonusLevelFour = _bonusLevelFour;
        emit SetPercents(bonusLevelOne, bonusLevelTwo, bonusLevelThree, bonusLevelFour);
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "Insuficient funds!");
        uint amount = address(this).balance;
        // sending to prevent re-entrancy attacks
        address(this).balance - amount;
        payable(msg.sender).transfer(amount);
    }

    // External functions that are view
    function getBalance() external view returns(uint) {
        return address(this).balance;
    }

    function getTokenBonusBalance() external view returns(uint) {
        return tokenBonus;
    }

    function getTokenSaleBalance() external view returns(uint) {
        return tokenSale;
    }

    function getPercents() 
    external 
    view 
    returns(
        uint levelOne,
        uint levelTwo,
        uint levelThree,
        uint levelFour)
    {
        levelOne = bonusLevelOne;
        levelTwo = bonusLevelTwo;
        levelThree = bonusLevelThree;
        levelFour = bonusLevelFour;
    }

    // Public functions
    function buyTokens(uint _numberOfTokens, uint _tokenPrice) public payable {
        if (block.timestamp <= levelOneDate + levelTwoDate) {
            calculatedBonus = _numberOfTokens * bonusLevelOne / 100;
        }
        else if (block.timestamp <= levelOneDate + levelTwoDate + levelThreeDate) {
            calculatedBonus = _numberOfTokens * bonusLevelTwo / 100;
        }
        else if (block.timestamp <= levelOneDate + levelTwoDate + levelThreeDate + levelFourDate) {
            calculatedBonus = _numberOfTokens * bonusLevelThree / 100;
        }
        else {
            calculatedBonus = _numberOfTokens * bonusLevelFour / 100;
        }

        require(
            msg.value == _numberOfTokens * _tokenPrice,
            "Number of tokens does not match with the value!"
        );
            
        uint scaledAmount = (calculatedBonus + _numberOfTokens) * 10 ** tokenContract.decimals();
        require(
            tokenSale >= _numberOfTokens * 10 ** tokenContract.decimals(),
            "The contract does not have enough TOKENS!"
        );

        require(
            tokenBonus >= calculatedBonus * 10 ** tokenContract.decimals(),
            "The contract does not have enough BONUS tokens!"
        );

        tokensSold += _numberOfTokens;
        tokenSale -= _numberOfTokens * 10 ** tokenContract.decimals();
        tokenBonus -= calculatedBonus * 10 ** tokenContract.decimals();
        emit Sell(msg.sender, _numberOfTokens);
        require(
            tokenContract.transfer(payable(msg.sender), scaledAmount),
            "Some problem with token transfer!"
        );        
    }
}