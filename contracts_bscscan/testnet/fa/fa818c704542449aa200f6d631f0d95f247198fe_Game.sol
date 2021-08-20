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
	
	struct Game1 {
	    uint256 score;
	    uint256 secretCode1;
	    uint256 secretCode2;
	    uint256 lives;
	    uint256 timeStart1;
	    uint256 timeStart2;
	    uint256 timeEnd1;
	    uint256 timeEnd2;
	    uint256 timeEnd;
	    uint256 timeReal;
	    uint256 timeRequest;
	}
	
	struct Game2 {
	    uint256 score;
	    uint256 lives;
	    uint256 timeStart;
	    uint256 timeEnd;
	}
	
    address WBNB;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "";
    string constant _symbol = "";

    IDEXRouter router;
    address pair;
    
    uint256 feePerTicket;
    uint256 numberTicket = 3;
    uint256 numberPerRound = 10;
    
    uint256 scorePerTicket = 30;
    uint256 test = 0.005 ether;
    
    mapping(address => Game1) public game1s;
    mapping(address => Game2) public game2s;

    constructor () {
        // router = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        // WBNB = router.WETH();
        // pair = IDEXFactory(router.factory()).createPair(WBNB, address(this));
    }
    
    function buyTicket() public returns (
            bool canPlay,
            uint256 secretCode1,
            uint256 secretCode2
        ){
        // require(msg.value == test);
        address wallet = msg.sender;
        game1s[wallet].lives = 3;
        game1s[wallet].secretCode1 = 221;
        game1s[wallet].secretCode2 = 112;
        canPlay = true;
        secretCode1 = game1s[wallet].secretCode1;
        secretCode2 = game1s[wallet].secretCode2;
    }
    
    function play1(uint256 secretCode, uint256 timeStart, uint256 score, uint256 timeEnd) public returns (
            bool canPlay,
            address wallet
        ){
        wallet = msg.sender;
        if(game1s[wallet].lives >= 1){
            if(secretCode == game1s[wallet].secretCode1){
                game1s[wallet].timeStart1 = block.timestamp;
                game1s[wallet].timeStart2 = timeStart;
            }
            if(secretCode == game1s[wallet].secretCode2){
                game1s[wallet].lives--;
                game1s[wallet].timeEnd1 = block.timestamp;
                game1s[wallet].timeEnd2 = timeEnd;
                uint256 timePlay1 = game1s[wallet].timeEnd1 - game1s[wallet].timeStart1;
                uint256 timePlay2 = game1s[wallet].timeEnd2 - game1s[wallet].timeStart2;
                game1s[wallet].timeReal = timePlay1;
                game1s[wallet].timeRequest = timePlay2;
                if(timePlay2 - timePlay1 <= 60 seconds)
                    game1s[wallet].score = score > game1s[wallet].score ? score : game1s[wallet].score;
            }
            canPlay = true;
        }
        else{
            game2s[wallet].lives = game1s[wallet].score / scorePerTicket;
            game1s[wallet].score = 0;
            canPlay = false;
        }
    }
    
    function play2() public returns (
            bool canPlay,
            address wallet,
            uint256 lives
        ){
        wallet = msg.sender;
        if(game2s[wallet].lives > 0){
            game2s[wallet].timeStart = block.timestamp;
            lives = game2s[wallet].lives;
            game2s[wallet].lives--;
            canPlay = true;
        }
        canPlay = false;
    }
    
    function end2(
        uint256 score, 
        uint256 timeStart,
        uint256 Coins,
        uint256 Level,
        uint256 Arrows,
        uint256 Archers,
        uint256 Archer_1,
        uint256 Archer_2,
        uint256 Archer_3,
        uint256 FortressType,
        uint256 FreezeMagicType,
        uint256 FireMagicType,
        uint256 LightningMagicType,
        uint256 timeEnd
    ) public{
        // game1s[wallet].timeEnd = block.timestamp;
        // uint256 timePlay1 = timeEnd - timeStart;
        // uint256 timePlay2 = game1s[wallet].timeEnd - game1s[wallet].timeStart;
        // game1s[wallet].timeReal = timePlay1;
        // game1s[wallet].timeRequest = timePlay2;
        // game1s[wallet].score = score > game1s[wallet].score ? score : game1s[wallet].score;
    }
}