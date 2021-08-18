/**
 *Submitted for verification at BscScan.com on 2021-08-17
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
}

contract Context {
    constructor() {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface LSCToken {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IPancakeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IPancakeFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

contract LottoGame is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    event OnPayout(bool status, address recipient, uint256 amount);
    event OnStartRound();
    event OnEndRound();
    event OnGetBNB(uint256 amount);
    event OnBuyTicket(uint256 amount);

    address[5] winners; //payable[]  public  winners;
    uint256 public numWinners;
    bool terminator; //flag for stopping the game in its tracks
    uint256 perTicketPrice;
    uint256 public potRemaining;

    mapping(address => uint256) public ticketBalance;

    mapping(address => uint256) public profits;

    uint256 public totalTickets;

    uint256 public amountToSendToNextRound;
    uint256 amountToMarketingAddress;
    uint256 amountToSendToLiquidity;

    //uint public timeLeft;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public roundNumber; // to keep track of the active round of play

    address public liqudityPairAddress;

    LSCToken public token;

    IPancakeRouter02 public pancakeswapV2Router;
    uint256 minimumBuy; //minimum buy to be eligible to win share of the pot
    uint256 tokensToAddOneSecond; //number of tokens that will add one second to the timer
    uint256 maxTimeLeft; //maximum number of seconds the timer can be
    uint256 maxWinners; //number of players eligible for winning share of the pot
    uint256 potPayoutPercent; // what percent of the pot is paid out
    uint256 potLeftoverPercent; // what percent is leftover
    uint256 maxTickets; // max amount of tickets a player can hold

    uint256[5] winnerProfits;
    uint256[5] bnbProfits;

    //optional stuff for fixing code later
    address public _marketingAddress;

    struct GameSettings {
        uint256 ticketPrice;
        uint256 oneMinutePrice;
        uint256 minimumBuyAmount;
        uint256 maxRoundTime;
        uint256 maxTicketsAmount;
        uint256 maxWinners;
    }

    struct PlayerInfo {
        uint256 totalBoughtAmount;
        uint256 tickets;
    }

    struct GameInfo {
        uint256 currenRound;
        uint256 startTime;
        uint256 endTime;
        uint256 roundNumber;
        bool gameInProgress;
    }

    address[] players;
    mapping(address => PlayerInfo) playersInfo;

    GameSettings private gameSettings;
    GameInfo private gameInfo;

    constructor(address _tokenAddress, address _pancakeRouterAddress) {
        token = LSCToken(_tokenAddress);

        pancakeswapV2Router = IPancakeRouter02(_pancakeRouterAddress);

        liqudityPairAddress = IPancakeFactory(pancakeswapV2Router.factory())
            .getPair(address(token), pancakeswapV2Router.WETH());

        GameSettings memory _gameSettings;
        _gameSettings.ticketPrice = 100_000 * (10**token.decimals());
        _gameSettings.oneMinutePrice = 1000 * (10**token.decimals());
        _gameSettings.maxWinners = 5;
        _gameSettings.maxRoundTime = 5 minutes;
        _gameSettings.maxTicketsAmount = 10;

        gameSettings = _gameSettings;
        //set initial game gameSettings
        // minimumBuy = 100000 * 10**9;
        // tokensToAddOneSecond = 1000 * 10**9;
        // maxTimeLeft = 300 seconds;
        // maxWinners = 5;
        // potPayoutPercent = 60;
        // potLeftoverPercent = 40;
        // maxTickets = 10;
    }

    receive() external payable {
        //to be able to receive eth/bnb
    }

    // 1 - Game Ended
    // 2 - Game In Progress
    function getGameStatus() public view returns (uint256) {
        if (block.timestamp >= gameInfo.endTime) {
            return 1;
        }
        return 2;
    }

    function getGameInfo() public view returns (GameInfo memory) {
        return gameInfo;
    }

    function getGameSettings() public view returns (GameSettings memory) {
        return gameSettings;
    }

    function checkGameStatus() private {
        if (getGameStatus() == 1 && gameInfo.gameInProgress) {
            endGame();
            startGame();
        } else if (!gameInfo.gameInProgress) {
            startGame();
        }
    }

    function buyTicket(uint256 amount) public nonReentrant {
        checkGameStatus();
        require(amount >= gameSettings.ticketPrice, "NOT ENOUGH FOR TICKET");
        require(
            amount / gameSettings.ticketPrice < gameSettings.maxTicketsAmount,
            "CANT BUY MORE THAN MAX"
        );
        require(!isInLeaderboard(msg.sender), "ALREADY IN LEADERBOARD");
        require(
            playersInfo[msg.sender].tickets < gameSettings.maxTicketsAmount,
            "TOO MANY TICKETS"
        );

        token.transferFrom(msg.sender, address(this), amount);

        players.push(msg.sender);
        playersInfo[msg.sender].tickets += amount / gameSettings.ticketPrice;
        playersInfo[msg.sender].totalBoughtAmount += amount;

//        uint256 timeToAdd = amount / gameSettings.oneMinutePrice;
//
  //      if (
  //          (gameInfo.endTime + (timeToAdd * 1 minutes)) - gameInfo.startTime <
  //          gameSettings.maxRoundTime
  //      ) {
  //          gameInfo.endTime += (timeToAdd * 1 minutes);
  //      }

        emit OnBuyTicket(amount);
    }

    function startGame() internal {
        gameInfo.currenRound++;
        gameInfo.startTime = block.timestamp;
        gameInfo.endTime = block.timestamp + 1 minutes;
        gameInfo.gameInProgress = true;
        emit OnStartRound();
    }

    function swapToBnB(uint256 amount) internal returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = pancakeswapV2Router.WETH();

        token.approve(address(pancakeswapV2Router), amount);
        uint256 startingAmount = address(this).balance;

        // make the swap
        pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp + 10 seconds
        );

        emit OnGetBNB(address(this).balance - startingAmount);

        return address(this).balance - startingAmount;
    }

    function endGame() internal {
        require(
            token.balanceOf(address(this)) > 0,
            "NOT ENOUGH TO PAY WINNERS"
        );
        uint256 contractBalance = token.balanceOf(address(this));

        uint256 liqudityAmount = contractBalance.mul(5).div(100);
        swapAndAddLiquidity(liqudityAmount);

        uint256 marketAmount = contractBalance.mul(10).div(100);
        token.transfer(_marketingAddress, marketAmount);

        uint256 potAmount = contractBalance.mul(60).div(100);
        uint256 potAmountInBNB = swapToBnB(potAmount);
        uint256 numOfTickets = getTotalNumOfTickets();

        uint256 i = players.length - 1;
        for (i; i > players.length - gameSettings.maxWinners + 1; i--) {
            uint256 payout = potAmountInBNB.mul(
                (playersInfo[players[i]].tickets).div(numOfTickets)
            );

            (bool status, ) = payable(players[i]).call{value: payout}("");

            emit OnPayout(status, players[i], payout);
        }

        emit OnEndRound();
    }

    function isInLeaderboard(address _address) public view returns (bool) {
        uint256 i = players.length - 1;
        for (i; i > players.length - gameSettings.maxWinners + 1; i--) {
            if (players[i] == _address) {
                return true;
            }
        }
        return false;
    }

    function getTotalNumOfTickets() public view returns (uint256) {
        uint256 total;
        uint256 i = players.length - 1;

        for (i; i > players.length - gameSettings.maxWinners + 1; i--) {
            total += playersInfo[players[i]].tickets;
        }

        return total;
    }

    function getWinners()
        public
        view
        returns (
            address,
            address,
            address,
            address,
            address
        )
    {
        return (
            players[players.length - 1],
            players[players.length - 2],
            players[players.length - 3],
            players[players.length - 4],
            players[players.length - 4]
        );
    }

    function forceEndGame() external onlyOwner {
        gameInfo.endTime = 0;
        gameInfo.gameInProgress = false;
    }

    //Send liquidity
    function swapAndAddLiquidity(uint256 amount) private {
        //sell half for bnb
        //first swap half for BNB
        address[] memory path = new address[](2);
        path[0] = address(token);
        //path[0] = payable(address(this));
        path[1] = pancakeswapV2Router.WETH();

        uint256 firstHalf = amount.div(2);
        uint256 secondHalf = amount.sub(firstHalf);

        uint256 bnbAmount = swapToBnB(firstHalf);

        token.approve(address(pancakeswapV2Router), secondHalf);

        pancakeswapV2Router.addLiquidityETH{value: bnbAmount}(
            address(token), //token address
            secondHalf, //amount to send
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            liqudityPairAddress, // where to send the liqduity tokens
            block.timestamp + 30 seconds //deadline
        );
    }

    // function getGameSettings()
    //     public
    //     view
    //     returns (
    //         uint256,
    //         uint256,
    //         uint256,
    //         uint256,
    //         uint256
    //     )
    // {
    //     return (
    //         minimumBuy,
    //         tokensToAddOneSecond,
    //         maxTimeLeft,
    //         maxWinners,
    //         potPayoutPercent
    //     );
    // }

    // function adjustBuyInAmount(uint256 newBuyInAmount) external onlyOwner {
    //     //add new buy in amount with 9 extra zeroes when calling this function (your token has 9 decimals)
    //     minimumBuy = newBuyInAmount;
    // }

    // function changeLiqduidityTokenRecipient(address newRecipient)
    //     public
    //     onlyOwner
    // {
    //     require(
    //         newRecipient != address(0),
    //         "Address of recipient cannot be zero."
    //     );
    //     liqudityPairAddress = newRecipient;
    // }

    // function buyTicket(address payable buyer, uint256 amount)
    //     public
    //     nonReentrant
    // {
    //     require(endTime != 0, "Game is not active!"); // will set when owner starts the game with initializeAndStart()
    //     require(
    //         amount >= minimumBuy,
    //         "You must bet a minimum of 100,000 tokens."
    //     );
    //     require(
    //         amount.div(minimumBuy * 10) <= maxTickets,
    //         "You may only purchase 10 tickets per play"
    //     );
    //     require(
    //         token.balanceOf(msg.sender) >= amount,
    //         "You don't have enough tokens"
    //     ); //check the owners wallet to make sure they have enough
    //     //note this function will throw unless a ticket is purchased!!

    //     // start a new round if needed
    //     uint256 startflag = getTimeLeft();
    //     // getTimeLeft() returns 0 if the game has ended
    //     if (startflag == 0) {
    //         endGame();
    //     } else {
    //         //if startflag is NOT equal to zero, game carries on
    //         bool alreadyPlayed = false; //set this as a flag inside of the if
    //         for (uint256 i = 0; i < numWinners; i++) {
    //             //scroll through the winners list
    //             if (buyer == winners[i]) {
    //                 alreadyPlayed = true;
    //             }
    //         }
    //         //This statement is the whole point of the ELSE block, just make sure they aren't on the board
    //         //If you need to remove their previous bet and add a new one, do it here.
    //         //add a flag above for the index and squish it.
    //         require(
    //             alreadyPlayed == false,
    //             "You can only buy tickets if you don't have a valid bid on the board"
    //         );
    //     }

    //     ticketBalance[buyer] += amount.div(100000 * 10**9);
    //     require(ticketBalance[buyer] >= 1, "Not enough for a ticket");

    //     if (numWinners < maxWinners) {
    //         // Only 5 winners allowed on the board, so if we haven't met that limit then add to the stack
    //         winners[numWinners] = payable(buyer);
    //         numWinners++;
    //     } else {
    //         //add new buyer and remove the first from the stack
    //         ticketBalance[winners[0]] = 0;
    //         for (uint256 i = 0; i < (maxWinners - 1); i++) {
    //             //note the -1, we only want the leading values
    //             winners[i] = winners[i + 1];
    //         }
    //         winners[numWinners - 1] = payable(buyer); //now we add the stake to the top
    //     }

    //     uint256 timeToAdd = amount.div(tokensToAddOneSecond);
    //     addTime(timeToAdd);

    //     // Transfer Approval is handled by Web 3 before sending
    //     // approve(this contract, amount)
    //     token.transferFrom(msg.sender, payable(address(this)), amount);
    // }

    // function getTimeLeft() public view returns (uint256) {
    //     if (block.timestamp >= endTime) {
    //         //endGame(); This would cost gas for the calling wallet or function, not good, but it would be an auto-start not requiring a new bid
    //         // IF this returns 0, then you can add the "Buy ticket to start next round" and the gas from that ticket will start the next round
    //         // see buyTicket for details
    //         return 0;
    //     } else return endTime - block.timestamp;
    // }

    // function addTime(uint256 timeAmount) private {
    //     endTime += timeAmount;
    //     if ((endTime - block.timestamp) > maxTimeLeft) {
    //         endTime = block.timestamp + maxTimeLeft;
    //     }
    // }

    // function initializeAndStart() external onlyOwner {
    //     roundNumber = 0;
    //     startGame();
    // }

    // function startGame() private {
    //     require(
    //         block.timestamp >= endTime,
    //         "Stop spamming the start button please."
    //     );
    //     roundNumber++;
    //     startTime = block.timestamp;
    //     endTime = block.timestamp + maxTimeLeft;
    //     winners = [address(0), address(0), address(0), address(0), address(0)];
    //     numWinners = 0;

    //     emit OnStartRound();
    // }

    // function endGame() private {
    //     require(block.timestamp >= endTime, "Game is still active");
    //     potRemaining = setPayoutAmount(); //does not change pot Value
    //     require(potRemaining > 0, "potRemaining is 0!");
    //     dealWithLeftovers(potRemaining);
    //     sendProfitsInBNB();
    //     swapAndAddLiqduidity();

    //     if (amountToMarketingAddress > 0) {
    //         // token.transfer(payable(_marketingAddress), (amountToMarketingAddress));
    //         token.transfer(_marketingAddress, amountToMarketingAddress);
    //     }

    //     for (uint256 i = 0; i < numWinners; i++) {
    //         ticketBalance[winners[i]] = 0;
    //         winners[i] = address(0);
    //     }

    //     if (terminator == false) {
    //         startGame();
    //     } else {
    //         terminator = false;
    //     }

    //     emit OnEndRound();
    // }

    // function setPayoutAmount() private returns (uint256) {
    //     //get number of tickets held by each winner in the array
    //     //only run once per round or tickets will be incorrectly counted
    //     //this is handled by endGame(), do not call outside of that pls and thnx
    //     totalTickets = 0; //reset before you start counting
    //     for (uint256 i = 0; i < numWinners; i++) {
    //         totalTickets += ticketBalance[winners[i]];
    //     }
    //     //require (totalTickets > 0, "Total Tickets is 0!");
    //     //uint perTicketPrice;
    //     uint256 top = (potValue().mul(potPayoutPercent));
    //     uint256 bottom = (totalTickets.mul(100));

    //     //require(bottom > 0, "Something has gone horribly wrong.");
    //     if (bottom > 0) {
    //         perTicketPrice = top / bottom;
    //     }

    //     uint256 tally = 0;
    //     //calculate the winnings based on how many tickets held by each winner

    //     for (uint256 i; i < numWinners; i++) {
    //         winnerProfits[i] = perTicketPrice * ticketBalance[winners[i]];
    //         tally += winnerProfits[i];
    //         if (winnerProfits[i] > 0) {
    //             bnbProfits[i] = swapProfitsForBNB(winnerProfits[i]);
    //         }
    //     }

    //     require(tally < potValue(), "Tally is bigger than the pot!");
    //     return (potValue() - tally);
    // }

    // function potValue() public view returns (uint256) {
    //     return token.balanceOf(address(this));
    // }

    // function swapProfitsForBNB(uint256 amount) private returns (uint256) {
    //     address[] memory path = new address[](2);
    //     path[0] = address(token);
    //     //path[0] = address(this);
    //     path[1] = pancakeswapV2Router.WETH();

    //     //token.gameApprove(address(this), address(pancakeswapV2Router), amount);
    //     token.approve(address(pancakeswapV2Router), amount);
    //     uint256 startingAmount = address(this).balance;

    //     // make the swap
    //     pancakeswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
    //         amount,
    //         0, // accept any amount of ETH
    //         path,
    //         //_tokenAddress,
    //         payable(address(this)),
    //         block.timestamp
    //     );
    //     emit OnGetBNB(address(this).balance - startingAmount);

    //     return address(this).balance - startingAmount;
    // }

    // //send bnb amount
    // function sendProfitsInBNB() private {
    //     for (uint256 i; i < numWinners; i++) {
    //         (bool succes, ) = payable(winners[i]).call{value: bnbProfits[i]}(
    //             ""
    //         );

    //         emit OnPayout(succes, winners[i], bnbProfits[i]);
    //     }
    // }

    // function dealWithLeftovers(uint256 leftovers) private {
    //     require(leftovers > 100, "no leftovers to spend");
    //     require(potRemaining > 100, "no leftovers to spend");
    //     uint256 nextRoundPot = 25;
    //     uint256 liquidityAmount = 5;
    //     uint256 marketingAddress = 10;

    //     //There could potentially be some rounding error issues with this, but the sheer number of tokens
    //     //should keep any problems to a minium.
    //     // Fractions are set up as parts from the leftover 40%
    //     amountToSendToNextRound = (potRemaining * nextRoundPot);
    //     amountToSendToNextRound = amountToSendToNextRound.div(40);
    //     amountToSendToLiquidity = (potRemaining * liquidityAmount);
    //     amountToSendToLiquidity = amountToSendToLiquidity.div(40);
    //     amountToMarketingAddress = (potRemaining * marketingAddress);
    //     amountToMarketingAddress = amountToMarketingAddress.div(40);
    // }

    // //Send liquidity
    // function swapAndAddLiqduidity() private {
    //     //sell half for bnb
    //     uint256 halfOfLiqduidityAmount = amountToSendToLiquidity.div(2);

    //     //first swap half for BNB
    //     address[] memory path = new address[](2);
    //     path[0] = address(token);
    //     //path[0] = payable(address(this));
    //     path[1] = pancakeswapV2Router.WETH();

    //     //approve pancakeswap to spend tokens
    //     token.approve(address(pancakeswapV2Router), halfOfLiqduidityAmount);

    //     //get the initial contract balance
    //     uint256 ethAmount = address(this).balance;

    //     //swap if there is money to Send
    //     if (amountToSendToLiquidity > 0) {
    //         pancakeswapV2Router
    //             .swapExactTokensForETHSupportingFeeOnTransferTokens(
    //                 halfOfLiqduidityAmount,
    //                 0, // accept any amount of BNB
    //                 path,
    //                 //_tokenAddress, //tokens get swapped to this contract so it has BNB to add liquidity
    //                 payable(address(this)),
    //                 block.timestamp + 30 seconds //30 second limit for the swap
    //             );

    //         ethAmount = address(this).balance - ethAmount;

    //         //now we have BNB, we can add liquidity to the pool
    //         token.approve(address(pancakeswapV2Router), halfOfLiqduidityAmount);

    //         pancakeswapV2Router.addLiquidityETH{value: ethAmount}(
    //             address(token), //token address
    //             halfOfLiqduidityAmount, //amount to send
    //             0, // slippage is unavoidable
    //             0, // slippage is unavoidable
    //             liqudityPairAddress, // where to send the liqduity tokens
    //             block.timestamp + 30 seconds //deadline
    //         );
    //     }
    // }

    // // Fallback function is called when msg.data is not empty
    // fallback() external payable {}

    // function getRound() external view returns (uint256) {
    //     return roundNumber;
    // }

    // function getWinners()
    //     external
    //     view
    //     returns (
    //         address,
    //         address,
    //         address,
    //         address,
    //         address
    //     )
    // {
    //     return (winners[0], winners[1], winners[2], winners[3], winners[4]);
    // }

    // function getTicketsPerWinner()
    //     external
    //     view
    //     returns (
    //         uint256,
    //         uint256,
    //         uint256,
    //         uint256,
    //         uint256
    //     )
    // {
    //     //the ratio of payout is contingent on how many tickets that winner is holding vs the rest
    //     return (
    //         ticketBalance[winners[0]],
    //         ticketBalance[winners[1]],
    //         ticketBalance[winners[2]],
    //         ticketBalance[winners[3]],
    //         ticketBalance[winners[4]]
    //     );
    // }

    // function setTokenAddress(address _newTokenAddress) external onlyOwner {
    //     token = LSCToken(_newTokenAddress);
    // }

    // function getEndTime() external view returns (uint256) {
    //     //Return the end time for the game in UNIX time
    //     return endTime;
    // }

    // function updatePancakeRouterInfo(address _pancakeAddress)
    //     external
    //     onlyOwner
    // {
    //     pancakeswapV2Router = IPancakeRouter02(_pancakeAddress);
    // }

    // function setMarketingAddress(address _newAddress) external onlyOwner {
    //     _marketingAddress = _newAddress;
    // }

    // function terminateGame() external onlyOwner {
    //     terminator = true;
    //     endGame();
    // }
}