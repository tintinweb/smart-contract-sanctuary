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

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract Game {
    using SafeMath for uint256;
	
	struct WalletGame {
	    uint256 GamePlaying;
        uint256 FinalDefense_Coins;
        uint256 FinalDefense_Score;
        uint256 FinalDefense_Level;
        uint256 FinalDefense_Life;
        uint256 Point;
        uint256 Timer;
        uint256 TimeStart1;
        uint256 TimeStart2;
        bool IsCheating;
	}
	

    IDEXRouter router;
    address pair;
    
    uint256 feePerTicket;
    uint256 numberTicket = 3;
    uint256 numberPerRound = 10;
    
    uint256 scorePerTicket = 30;
    uint256 ticketPrice = 0.005 ether;
    
    mapping(address => WalletGame) public walletGames;

    constructor () {
        
        walletGames[address(0x93CFe1c3fdF394b2EB4D68CCB42b3Ac3b1D86488)].FinalDefense_Life = 3;
    }
    
    function buyTicket(address user) public returns (bool success){
        // require(msg.value == ticketPrice);
        address player = msg.sender;
        walletGames[user].FinalDefense_Life = 3;
        success = true;
    }
    
    function GetInfoWalletGame(
        // uint256 gamePlaying,
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
        // uint256 gamePlaying,
        uint256 timeStart
    ) public returns (
        uint256 FinalDefense_Coins,
        uint256 FinalDefense_Score,
        uint256 FinalDefense_Level,
        uint256 FinalDefense_Life
    ){
        address player = msg.sender;
        walletGames[player].TimeStart1 = block.timestamp;
        walletGames[player].TimeStart2 = timeStart;
        FinalDefense_Coins = walletGames[player].FinalDefense_Coins;
        FinalDefense_Score = walletGames[player].FinalDefense_Score;
        FinalDefense_Level = walletGames[player].FinalDefense_Level;
        FinalDefense_Life = walletGames[player].FinalDefense_Life;
    }
    
    function storeValue(
        uint256 TimeEnd,
        uint256 FinalDefense_Coins,
        uint256 FinalDefense_Score,
        uint256 FinalDefense_Level,
        uint256 FinalDefense_Life
    ) public returns (bool success)
    {
        address player = msg.sender;
        uint256 timeRequest =  block.timestamp - walletGames[player].TimeStart1;
        uint256 timeUser =  TimeEnd - walletGames[player].TimeStart2;
        if(timeUser - timeRequest < 60){
            walletGames[player].FinalDefense_Coins = FinalDefense_Coins;
            walletGames[player].FinalDefense_Score = FinalDefense_Score;
            walletGames[player].FinalDefense_Level = FinalDefense_Level;
            walletGames[player].FinalDefense_Life = 0; 
            success = true;
        }
        else{
            walletGames[player].IsCheating = true;
            success = false;
        }
    }
}