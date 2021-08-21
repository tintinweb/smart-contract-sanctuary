/**
 *Submitted for verification at BscScan.com on 2021-08-20
*/

/**
 *Submitted for verification at BscScan.com on 2021-08-20
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}


contract Game {
    using SafeMath for uint256;
	
	struct WalletGame {
	    uint256 LastClaim;
        uint256 FinalDefense_Coins;
        uint256 FinalDefense_Score;
        uint256 FinalDefense_Level;
        uint256 FinalDefense_Life;
        uint256 FinalDefense_Arrows;
        uint256 FinalDefense_Archers;
        uint256 FinalDefense_Archer_1;
        uint256 FinalDefense_Archer_2;
        uint256 FinalDefense_Archer_3;
        uint256 FinalDefense_FortressType;
        uint256 FinalDefense_FreezeMagicType;
        uint256 FinalDefense_FireMagicType;
        uint256 FinalDefense_LightningMagicType;
	}
	
    uint256 timeBetweenClaim = 3 hours;
    uint256 lifeOneClaim = 3;
    mapping(address => WalletGame) public walletGames;

    constructor () {
    }
    
    function buyTicket() public returns (bool success){
        // require(msg.value == ticketPrice);
        address player = msg.sender;
        require(walletGames[player].LastClaim + timeBetweenClaim < block.timestamp);
        walletGames[player].LastClaim = block.timestamp;
        walletGames[player].FinalDefense_Life += lifeOneClaim;
        success = true;
    }
    
    function GetInfoWalletGame(
        uint256 timeStart
    ) public view returns (
        uint256 FinalDefense_Coins,
        uint256 FinalDefense_Score,
        uint256 FinalDefense_Level,
        uint256 FinalDefense_Life
    ){
        address player = msg.sender;
        FinalDefense_Coins = walletGames[player].FinalDefense_Coins;
        FinalDefense_Score = walletGames[player].FinalDefense_Score;
        FinalDefense_Level = walletGames[player].FinalDefense_Level;
        FinalDefense_Life = walletGames[player].FinalDefense_Life;
    }
    
    function Play(
        uint256 timeStart
    ) public returns (
        uint256 FinalDefense_Coins,
        uint256 FinalDefense_Score,
        uint256 FinalDefense_Level,
        uint256 FinalDefense_NumLife,
        bool CanPlay
    ){
        address player = msg.sender;
        if(walletGames[player].FinalDefense_Life > 0){
            FinalDefense_Coins = walletGames[player].FinalDefense_Coins;
            FinalDefense_Score = walletGames[player].FinalDefense_Score;
            FinalDefense_Level = walletGames[player].FinalDefense_Level;
            FinalDefense_NumLife = walletGames[player].FinalDefense_Life;
            walletGames[player].FinalDefense_Life = 0;
            CanPlay = true;
        }
        else
            CanPlay = false;
    }
    
    function storeValue(
        uint256 FinalDefense_Coins,
        uint256 FinalDefense_Score,
        uint256 FinalDefense_Level,
        uint256 FinalDefense_Life,
        uint256 FinalDefense_Arrows,
        uint256 FinalDefense_Archers,
        uint256 FinalDefense_Archer_1,
        uint256 FinalDefense_Archer_2,
        uint256 FinalDefense_Archer_3,
        uint256 FinalDefense_FortressType,
        uint256 FinalDefense_FreezeMagicType,
        uint256 FinalDefense_FireMagicType,
        uint256 FinalDefense_LightningMagicType
    ) public returns (bool success)
    {
        address player = msg.sender;
        walletGames[player].FinalDefense_Coins = FinalDefense_Coins;
        walletGames[player].FinalDefense_Score = FinalDefense_Score;
        walletGames[player].FinalDefense_Level = FinalDefense_Level;
        walletGames[player].FinalDefense_Life = FinalDefense_Life;
        walletGames[player].FinalDefense_Arrows = FinalDefense_Arrows;
        walletGames[player].FinalDefense_Archers = FinalDefense_Archers;
        walletGames[player].FinalDefense_Archer_1 = FinalDefense_Archer_1;
        walletGames[player].FinalDefense_Archer_2 = FinalDefense_Archer_2;
        walletGames[player].FinalDefense_Archer_3 = FinalDefense_Archer_3;
        walletGames[player].FinalDefense_FortressType = FinalDefense_FortressType;
        walletGames[player].FinalDefense_FreezeMagicType = FinalDefense_FreezeMagicType;
        walletGames[player].FinalDefense_FireMagicType = FinalDefense_FireMagicType;
        walletGames[player].FinalDefense_LightningMagicType = FinalDefense_LightningMagicType;
        success = true;
    }
}