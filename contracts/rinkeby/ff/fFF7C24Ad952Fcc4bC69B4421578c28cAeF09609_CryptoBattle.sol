// SPDX-License-Identifier: UNLICENSED
/**
*
* 
*   CRYPTO BATTEL 1
*
*
*
**/

pragma solidity ^0.7.4;

import './Context.sol';
import './Ownable.sol';
import './SafeMath.sol';
import './ChainLinkTokenPrice.sol';

abstract contract DateTimeAPI {
    /*
    *  Abstract contract for interfacing with the DateTime contract.
    *
    */
    function isLeapYear(uint16 year) public virtual pure returns (bool);    
    function toTimestamp(uint16 year, uint8 month, uint8 day) public virtual pure returns (uint256 timestamp);    
    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) public virtual pure returns (uint256 timestamp);
}

interface ICryptoWallet {
    function isUserExists(address user) external view returns (bool);
    function getUserId(address user) external view returns (uint256);    
    function purchaseBattle(address userAddress, uint256 amount) external; 
    function endBattle(address[] memory winners, uint256[] memory winnerAmounts, uint256 totalAmount) external;
}

// Standard(Scheduled) / Dynamic *on-demand
// Scheduled, precise price mode
contract CryptoBattle is Ownable {
    using SafeMath for uint256;

    ChainLinkTokenPrice public priceContract;
     
    string public name = "ETH 15 min battle";
    ICryptoWallet public wallet;
    uint32 public betTimeSize;
    uint32 public idleTimeSize;
    uint32 public validationTimeSize;
    uint256 public betAmount = 0.05 ether;
    uint256 public rewardLimit = 10 ether;
    uint256 public accuracyUnit = 1e7; //0.1
    uint256 public battleLimit;
    // uint8 public battleMode;    //0: min, 1: max, 2: precise

    // struct NumberOfWinners {
    //     uint32 minUsers;
    //     uint32 maxUsers;
    //     uint32 numOfWinners;
    // }
    // NumberOfWinners[] public numberOfUsers;
    
    enum StatusType {Ready, Started, Ended}
    StatusType status = StatusType.Ready;

    uint256 public battleNo;
    uint256 public startTime = 0;
    uint256 public endTime = 0;
        
    struct Player {
        uint256 price;  //decimal 8
        uint8 mode;     //precise 2
        uint256 time;
        address addr;
    }

    Player[] queue;
    mapping(uint256 => mapping(address => uint256)) queueIndex; 

    uint256 public endPrice;
    uint256 public winPrice;
    Player[] public winnerList;
    uint256[] public winnerRewardList;

    event EventStatus(string message);
    event LogTokenMultiSent(address token, uint256 total);

    constructor()
    {        
    //   battleMode = 2;
        priceContract = new ChainLinkTokenPrice();
        battleNo = 1;
    }

    modifier battleLimitExceeded() {
        require(battleLimit == 0 || battleLimit == 0 && queue.length < battleLimit, "CryptoBattle: limit exceeded.");
        _;
    }

    modifier endAvailable() {
        //check if ended
        require(!isContract(msg.sender), "Contract is not allowed.");
        
        uint256 currentTime = block.timestamp;       
        uint256 passTime = currentTime.sub(startTime);
        require(passTime >= betTimeSize + idleTimeSize + validationTimeSize, "Not finished yet.");

        _;
    }

    function setWalletAddress(address walletAddress) public onlyOwner {
      wallet = ICryptoWallet(walletAddress);
    }

    //second
    function setTimeSize(uint32 _betTimeSize, uint32 _idleTimeSize, uint32 _validationTimeSize) public onlyOwner {       
        require(queue.length == 0, "Game is running.");
        betTimeSize = _betTimeSize;
        idleTimeSize = _idleTimeSize;
        validationTimeSize = _validationTimeSize;
    }
    
    // function setBattleMode(uint8 _battleMode) public onlyOwner {
    //     battleMode = _battleMode;
    // }

    function setStartTime(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) public onlyOwner {
        require(queue.length == 0, "Game is running.");
        startTime = toTimestamp(year, month, day, hour, minute, second);
    }

    function setStartTime(uint256 timestamp) public onlyOwner {
        startTime = timestamp;
    } 

    /////////////////////////////////////
    function setBattleLimit(uint256 _battleLimit) public onlyOwner {
        battleLimit = _battleLimit;
    } 

    function setBetAmount(uint256 amount) public onlyOwner {
      betAmount = amount;
    }
    
    function setAccuracyUnit(uint256 _accuracyUnit) public onlyOwner {
        accuracyUnit = _accuracyUnit;
    }

    function isJoined(address userAddress) public view returns (bool) {
        return queueIndex[battleNo][userAddress] > 0;
    }

    // price decimal is 8, accuracyUnit = 1e7; 0.1
	function joinBattle(uint256 price, uint8 mode) public battleLimitExceeded {
        require(!isContract(msg.sender), "Contract is not allowed.");
        require(adjustAccuracy(price) == price, "Price is not valid.");
       
        require(betTimeSize > 0, "Bet time size was not set yet.");
        require(idleTimeSize > 0, "Idle time size was not set yet.");
        require(startTime > 0, "Start time was not set yet.");

        uint256 currentTime = block.timestamp;
        require(startTime <= currentTime, "Game will start soon.");
        
        uint256 passTime = currentTime.sub(startTime);
        require(passTime <= betTimeSize, "Bet time ended. Please try the next battle.");
        require(queueIndex[battleNo][msg.sender] == 0, "Already queued.");
        require(wallet.isUserExists(msg.sender), "The user does not exist");

        wallet.purchaseBattle(msg.sender, betAmount);
    
        Player memory player = Player({
          price: price,
          mode: mode,
          time: currentTime,
          addr: msg.sender
        });
    
        queue.push(player);
        queueIndex[battleNo][msg.sender] = queue.length;
	}

    function adjustAccuracy(uint256 price) public view returns (uint256) {
        return price.sub(price.mod(accuracyUnit));
    }

    function endBattle() public endAvailable returns (uint256) {
        uint256 size = 0;
        uint256 _winPrice;
        if( endPrice > 0 ) {
            _winPrice = endPrice;
            endPrice = 0;
        }
        else {
            _winPrice = 2100e18;
            // _winPrice = getETHPriceInUSD();
        }
        
        if( queue.length == 0 ) {      
            delete winnerList;
            delete winnerRewardList;            
        }
        else {
            uint256 totalAmount = betAmount.mul(queue.length);
            uint32 numWinners = getNumberOfWinners(queue.length);
            
            //Rank winners
            address[] memory winners = new address[](numWinners);
            uint32 lastWinnerIndex = 0;
            winners[0] = queue[0].addr;
            
            for( uint256 i = 1; i < queue.length; i ++ ) {
                Player memory player = queue[i];
                
                bool isWinner = false;
                for(uint32 j = 0; !isWinner && j <= lastWinnerIndex; j ++ ) {
                    Player memory winner = queue[queueIndex[battleNo][winners[j]]-1];
                    if(compareRank(_winPrice, player, winner)) {
                        if( lastWinnerIndex < numWinners - 1 )
                            lastWinnerIndex ++;
                        for(uint32 k = lastWinnerIndex; k > j; k -- ) {
                            winners[k] = winners[k-1];
                        }
                        
                        winners[j] = player.addr;
                        isWinner = true;
                    }
                }
                
                if(!isWinner &&  lastWinnerIndex < numWinners - 1 ) {
                    lastWinnerIndex ++;
                    winners[lastWinnerIndex] = player.addr;
                }
            }
            

            uint32[] memory distributionRate = rewardDistributions(numWinners);
            uint256[] memory rewardAmounts = new uint256[](numWinners);
            delete winnerList;

            for( uint32 i = 0; i < numWinners; i ++ ) {
                uint256 amount = totalAmount.mul(distributionRate[i]).div(100);
                uint256 limit = rewardLimit.mul(100 - 4 * i).div(100);
                if( amount > limit ) 
                    amount = limit;
                rewardAmounts[i] = amount;

                Player memory winner = queue[queueIndex[battleNo][winners[i]] - 1];
                winnerList.push(winner);
            }
            
            wallet.endBattle(winners, rewardAmounts, totalAmount);
            
            size = queue.length;
            delete queue;            
            winPrice = _winPrice;
            winnerRewardList = rewardAmounts;            
        }        
        
        endTime = block.timestamp;
        startTime = block.timestamp;                
        battleNo = battleNo.add(1);

        return size;
    }
    
    function getETHPriceInUSD() public view returns(uint256) {
        return uint256(priceContract.getLatestPrice());
    }

    //When failed endBattle, it will keep the correct price at the endtime.
    function setEndPrice() public endAvailable {
        require(endPrice == 0, "Price already has been set.");
        endPrice = getETHPriceInUSD();
    }

    function compareRank(uint256 _winPrice, Player memory player1, Player memory player2) private pure returns (bool) {
        uint256 delta1 = calcDelta(_winPrice, player1.price);
        uint256 delta2 = calcDelta(_winPrice, player2.price);
        
        if( delta1 < delta2 || ( delta1 == delta2 && player1.time < player2.time ) ){
            return true;
        }
        
        return false;
    }
    
    function calcDelta(uint256 _winPrice, uint256 price) public pure returns (uint256) {
        if(_winPrice >= price)
            return _winPrice.sub(price);
        else 
            return price.sub(_winPrice);
    }
    
    function getNumberOfWinners(uint256 numberOfUsers) public pure returns (uint32) {
        uint32 numWinners = 0;

        if( numberOfUsers == 1 ) numWinners = 1;
        else if( numberOfUsers >= 2 && numberOfUsers <= 4 ) numWinners = 1;
        else if( numberOfUsers >= 5 && numberOfUsers <= 10 ) numWinners = 2;
        else if( numberOfUsers >= 11 && numberOfUsers <= 30 ) numWinners = 5;
        else if( numberOfUsers >= 31 && numberOfUsers <= 60 ) numWinners = 10;
        else if( numberOfUsers >= 61 && numberOfUsers <= 100 ) numWinners = 15;
        else if( numberOfUsers >= 101 && numberOfUsers <= 2000 ) numWinners = 20;
        else if( numberOfUsers >= 2001 ) numWinners = 20;
        
        return numWinners;
    }

    function numberOfPlayers()  public view returns(uint256) {
        return queue.length;
    }

    function rewardDistributions(uint32 numWinners) public pure returns (uint32[] memory) {
        uint32[] memory distributions = new uint32[](numWinners);
        
        if( numWinners == 1 ) {
            distributions[0] = 70;
        }
        else if( numWinners == 2 ) {
            distributions[0] = 40;
            distributions[1] = 30;
        }
        else if( numWinners == 5 ) {
            distributions[0] = 20;
            distributions[1] = 15;
            distributions[2] = 13;
            distributions[3] = 12;
            distributions[4] = 10;
        }
        else if( numWinners == 10 ) {
            distributions[0] = 12;
            distributions[1] = 11;
            distributions[2] = 9;
            distributions[3] = 8;
            distributions[4] = 7;
            distributions[5] = 6;
            distributions[6] = 5;
            distributions[7] = 4;
            distributions[8] = 4;
            distributions[9] = 4;
        }
        else if( numWinners == 15 ) {
            distributions[0] = 13;
            distributions[1] = 10;
            distributions[2] = 8;
            distributions[3] = 6;
            distributions[4] = 6;
            distributions[5] = 5;
            distributions[6] = 5;
            distributions[7] = 4;
            distributions[8] = 4;
            distributions[9] = 4;
            distributions[10] = 3;
            distributions[11] = 3;
            distributions[12] = 3;
            distributions[13] = 3;
            distributions[14] = 3;
        }
        else if( numWinners == 20 ) {
            distributions[0] = 8;
            distributions[1] = 6;
            distributions[2] = 5;
            distributions[3] = 5;
            distributions[4] = 4;
            distributions[5] = 4;
            distributions[6] = 4;
            distributions[7] = 4;
            distributions[8] = 3;
            distributions[9] = 3;
            distributions[10] = 3;
            distributions[11] = 3;
            distributions[12] = 3;
            distributions[13] = 3;
            distributions[14] = 2;
            distributions[15] = 2;
            distributions[16] = 2;
            distributions[17] = 2;
            distributions[18] = 2;
            distributions[19] = 2;

        }

        return distributions;
    }

    /** 
     * Utils
     */
    //////////////////////////////////////////////////////////////////
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
    
    function isLeapYear(uint16 year) private pure returns (bool) {
		if (year % 4 != 0) {
				return false;
		}
		if (year % 100 != 0) {
				return true;
		}
		if (year % 400 != 0) {
				return false;
		}
		return true;
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day) private pure returns (uint256 timestamp) {
			return toTimestamp(year, month, day, 0, 0, 0);
    }

    
  function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) private pure returns (uint256 timestamp) {
        uint32 DAY_IN_SECONDS = 86400;
        uint32 YEAR_IN_SECONDS = 31536000;
        uint32 LEAP_YEAR_IN_SECONDS = 31622400;
    
        uint32 HOUR_IN_SECONDS = 3600;
        uint32 MINUTE_IN_SECONDS = 60;
    
        uint16 ORIGIN_YEAR = 1970;
        
		uint16 i;

		// Year
		for (i = ORIGIN_YEAR; i < year; i++) {
				if (isLeapYear(i)) {
						timestamp += LEAP_YEAR_IN_SECONDS;
				}
				else {
						timestamp += YEAR_IN_SECONDS;
				}
		}

		// Month
		uint8[12] memory monthDayCounts;
		monthDayCounts[0] = 31;
		if (isLeapYear(year)) {
				monthDayCounts[1] = 29;
		}
		else {
				monthDayCounts[1] = 28;
		}
		monthDayCounts[2] = 31;
		monthDayCounts[3] = 30;
		monthDayCounts[4] = 31;
		monthDayCounts[5] = 30;
		monthDayCounts[6] = 31;
		monthDayCounts[7] = 31;
		monthDayCounts[8] = 30;
		monthDayCounts[9] = 31;
		monthDayCounts[10] = 30;
		monthDayCounts[11] = 31;

		for (i = 1; i < month; i++) {
				timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
		}

		// Day
		timestamp += DAY_IN_SECONDS * (day - 1);

		// Hour
		timestamp += HOUR_IN_SECONDS * (hour);

		// Minute
		timestamp += MINUTE_IN_SECONDS * (minute);

		// Second
		timestamp += second;

		return timestamp;
  }
}