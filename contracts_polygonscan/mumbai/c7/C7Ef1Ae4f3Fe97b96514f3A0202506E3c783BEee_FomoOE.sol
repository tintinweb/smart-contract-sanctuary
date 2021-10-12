/**
 *Submitted for verification at polygonscan.com on 2021-10-11
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract FomoOE {
    address developer;
    uint public developerOnePercent;
    uint public giveToDeveloper;
    uint public giveToJackpot;
    uint public startTime;
    uint public totalTime;
    uint public timeLeft;

    address winning;
    uint public balanceReceived;
    uint public keyPrice = 3366666666666000 wei;
    uint public increased_order = 3366666666666000;
    uint public keyPriceIncreaseBlockNumber;
    uint public multiplier = 100;


    uint public totalKeys;
    uint public keyPurchases;
    uint public divPool;
    uint public jackpot;

    struct Divvies {
        uint _keyBalance;
        uint _divBalance;
        uint _withdrawnAmount;
        bool _voted;
        bool _boughtKeys;
    }

    mapping(address => Divvies) public divTracker;
    event keysPurchased(uint _userKeyBalance, uint _totalKeys, uint _keyPrice, uint _divPool, uint _jackpot, address _winning);
    event userDivvies(uint _userDivvies);
    event contractBalance(uint _balanceReceived);
    event currentKeyPrice(uint keyPrice);
    

    constructor() {
        developer = msg.sender;
    }

    modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }
    // function restartGame() public {
    //     require(getTimeLeft() == 0, "game is still in play");
    //     require(msg.sender == winning, "you are not the winner");
    //     letTheGamesBegin();
    // }
    function letTheGamesBegin() private {
        totalTime = block.timestamp + 86400;
    }
    function getTimeLeft() public view returns(uint) {
        if (totalKeys == 0) {
            return 86400;
        }
        if (totalTime >= block.timestamp) {
            return totalTime - block.timestamp;
        } else {
            return 0;
        }
    }
    function purchaseKeys(uint _amount) public payable isHuman() {
        if (totalKeys == 0 || keyPurchases < 5) {
            letTheGamesBegin();
        } 
        require(getTimeLeft() > 0, "there is already a winner");
        if (msg.value >= keyPrice*_amount) {
            keyPriceIncreaseBlockNumber = block.number;
            uint numerator = keyPrice*multiplier;
            keyPrice = keyPrice + numerator/10000;
                if (keyPrice/increased_order >= 10 && multiplier >= 20) {
                    increased_order = keyPrice;
                    multiplier = multiplier - 10;
                }
            // if (keyPurchases < 500) {
            //     uint numerator = keyPrice*100;
            //     keyPrice = keyPrice + numerator/10000;
            // } else {
            //     uint numerator = keyPrice*50;
            //     keyPrice = keyPrice + numerator/10000;
            // }
        } else {
            uint numerator = keyPrice*multiplier;
            uint tempKeyPrice = keyPrice - numerator/10000;
            require(msg.value >= tempKeyPrice*_amount && block.number <= keyPriceIncreaseBlockNumber+1, "Not enough to buy the key(s): Key price is increasing quickly. Try refreshing the page and quickly submitting key purchase again.");
        }

        uint devShareNumerator = msg.value*100;
        uint devShare = devShareNumerator/10000;
        uint gameShare = msg.value - devShare;
        uint floor = gameShare/2;
        developerOnePercent += devShare;
        jackpot += floor;
        divPool += gameShare - floor; 
        divTracker[msg.sender]._keyBalance += _amount;
        divTracker[msg.sender]._boughtKeys = true;
        totalKeys += _amount;
        if (_amount*30 > 86400 - (totalTime-block.timestamp)) {
            letTheGamesBegin();
        } else {
            totalTime += _amount*30;
        }

        keyPurchases += 1;
        winning = msg.sender;
        emit keysPurchased(divTracker[msg.sender]._keyBalance, totalKeys, keyPrice, divPool, jackpot, winning);
    } 
    // function purchaseKeys(uint _amount) public payable {
    //     // require(msg.value >= keyPrice*_amount, "not enough to buy the key(s).");
    //     if (totalKeys == 0) {
    //         letTheGamesBegin();
    //     }
    //     require(getTimeLeft() > 0, "there is already a winner");

    //     // if (block.number <= blockNumberOfLastKeyPurchase) {
    //     //     prevKeyPrice = keyPrice;
    //     //     require(msg.value >= prevKeyPrice, "In the same block as another player, but you need to pay more.");
    //     // } else {
    //     //     uint numerator = keyPrice*100;
    //     //     keyPrice = keyPrice + numerator/10000;
    //     //     require(msg.value >= keyPrice, "In a later block, but you need to pay more.");
    //     // }
    //     keyPrices[0] = keyPrice;
    //     require(msg.value >= keyPrices[0]*_amount, "Not enough to buy the key(s).");
    //     uint devShareNumerator = msg.value*100;
    //     uint devShare = devShareNumerator/10000;
    //     uint gameShare = msg.value - devShare;
    //     uint floor = gameShare/2;
    //     developerOnePercent += devShare;
    //     jackpot += floor;
    //     divPool += gameShare - floor; 
    //     divTracker[msg.sender]._keyBalance += _amount;
    //     divTracker[msg.sender]._boughtKeys = true;
    //     totalKeys += _amount;
    //     if (_amount*30 > 86400 - (totalTime-block.timestamp)) {
    //         // totalTime = 86400 + block.timestamp;
    //         letTheGamesBegin();
    //     } else {
    //         totalTime += _amount*30;
    //     }
        
    //     if (keyPurchases < 500) {
    //         uint numerator = keyPrice*100;
    //         keyPrices[1] = keyPrice + numerator/10000;
    //     } else {
    //         uint numerator = keyPrice*50;
    //         keyPrices[1] = keyPrice + numerator/10000;
    //     }

    //     keyPurchases += 1;
    //     winning = msg.sender;
    //     emit keysPurchased(divTracker[msg.sender]._keyBalance, totalKeys, keyPrice, divPool, jackpot, winning);
    //     blockNumberOfLastKeyPurchase = block.number;   
    // } 

    function getWinner() public view returns(address) {
        return winning;
    }
    
    function updateDivvies(address _userAddress) public view returns(uint) {
        uint tempUserWithdrawAmount;
        uint tempNumerator;
        if (totalKeys == 0 ) {
            tempUserWithdrawAmount = 0;
        } else {
            // example to reference, but solidity can't do decimals
            // // tempUserKeyProportion = divTracker[_userAddress]._keyBalance/totalKeys;
            // // tempUserWithdrawAmount = tempUserKeyProportion*divPool - divTracker[_userAddress]._withdrawnAmount;

            tempNumerator = divTracker[_userAddress]._keyBalance * divPool;
            tempUserWithdrawAmount = tempNumerator/totalKeys - divTracker[_userAddress]._withdrawnAmount;  
        }  
        return tempUserWithdrawAmount;
    }
    
    function withdrawDivvies() public isHuman() {
        address payable to = payable(msg.sender);
        uint tempUserWithdrawAmount;
        uint tempNumerator;
        if (totalKeys == 0 ) {
            tempUserWithdrawAmount = 0;
        } else {
            // example to reference, but solidity can't do decimals
            // // tempUserKeyProportion = divTracker[_userAddress]._keyBalance/totalKeys;
            // // tempUserWithdrawAmount = tempUserKeyProportion*divPool - divTracker[_userAddress]._withdrawnAmount;

            tempNumerator = divTracker[msg.sender]._keyBalance * divPool;
            tempUserWithdrawAmount = tempNumerator/totalKeys - divTracker[msg.sender]._withdrawnAmount;
            divTracker[msg.sender]._withdrawnAmount += tempUserWithdrawAmount;
        }  
        require(tempUserWithdrawAmount > 0, "You have no divvies to claim");
        to.transfer(tempUserWithdrawAmount);
    }

    function jackpotPayout() public isHuman() {
        require(getTimeLeft() == 0, "game is still in play");
        require(jackpot > 0, "No money in jackpot");
        require(msg.sender == winning, "you are not the winner");
        address payable to = payable(winning);
        to.transfer(jackpot);
        jackpot = 0;
    }

    function whoWon(address _userAddress) public view returns(address winner){
        if (getTimeLeft() == 0 && _userAddress == winning) {
            winner = _userAddress;
            return winner;
        }
    }

    function developerOnePercentAllocation() public {
        require(msg.sender == developer, "you aren't the developer of this contract.");
        require(getTimeLeft() == 0, "game is still in play");
        if (giveToDeveloper >= giveToJackpot) {
            address payable to = payable(developer);
            to.transfer(developerOnePercent);
            
        } else {
            address payable to = payable(winning);
            to.transfer(developerOnePercent);
        }
        developerOnePercent = 0;
    }

    function voteForOnePercent(bool _vote) public isHuman() {
        require(divTracker[msg.sender]._boughtKeys == true, "you need to buy at least one key to vote.");
        require(divTracker[msg.sender]._voted == false, "you already voted.");
        divTracker[msg.sender]._voted = true;
        if (_vote == true) {
            giveToDeveloper += 1;
        } else {
            giveToJackpot += 1;
        }
    }

}