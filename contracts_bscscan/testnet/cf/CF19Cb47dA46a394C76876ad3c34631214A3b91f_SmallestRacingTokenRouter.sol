// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
// Custom interfaces
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Pair.sol';
import './interfaces/IUniswapV2Router01.sol';
import './interfaces/IUniswapV2Router02.sol';
import './interfaces/IWETH.sol';
import './interfaces/IRacingTokenRouter.sol';
import './interfaces/IRacingTokenCreateFactory.sol';
import './libraries/ConcatStrings.sol';
import './interfaces/IRandomNumberGenerator.sol';

contract SmallestRacingTokenRouter is ReentrancyGuard,Ownable,IRacingTokenRouter {
  
    using SafeMath for uint;
    using ConcatStrings for string;
    mapping(address => uint256) private _balances;
    mapping(uint256 => Race) race;
    mapping(uint32 => mapping(uint32 => RaceTicket)) racePlayerIndex;
    mapping(uint32 => mapping(address => RaceTicket)) racePlayer;
    mapping (uint32 => string) raceAuthKeys;
    uint public minAndMaxParticipationFeeAmount = 0.15 ether;
    uint public maxDepositAmount = 1 ether;    
    uint256 public platformFee = 10;
    uint32 public totalParticipants = 3; //10
    string private name="Smallest Race";
    string private symbol="SRC";
    uint256 public raceTokenTotalSupply = 10000000000000000000000000;
    address private currentRaceTokenAddress;
    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2RouterAddress = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    address public racingTokenFactory = 0xb348931829C2baf8775d21f6eD28d7393Ce6Aee4;
    address public wethAddress = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
    address private uniswapV2Pair;
    uint32  currentRaceId;
    uint64[] private lastWinnerRaceTicketNumber;
    uint256 public maxLenghtRace = 5 minutes; // 4 hours
    IERC20 public weth = IERC20(wethAddress);
    IRandomNumberGenerator public randomGenerator;
    
    constructor(address _randomGeneratorAddress,address _racingTokenFactory) {
        randomGenerator = IRandomNumberGenerator(_randomGeneratorAddress);
        racingTokenFactory = _racingTokenFactory;
        currentRaceId=0;        
    }
    
    
    function forcedReboot(uint32 raceId) external onlyOwner() {
        require(race[raceId].status == Status.Close,"You cannot start over before the race is over.");
        require(block.timestamp >= race[raceId].endTime, "The race not over");
        require(calculateWinner(raceId) == 0, "There are winners");
        randomGenerator.getRandomNumber(uint256(keccak256(abi.encodePacked(raceId, getSeed()))));
    }
    
    
    function accountBalance() external override view returns(uint) {
        return address(this).balance;
    }
    

    function raceBalance(address raceAddress) external override view returns(uint256) {
        return IERC20(raceAddress).balanceOf(address(this));
    } 
    
    
    function setMaxDepositAmount(uint _maxDepositAmount) external override onlyOwner() {
        emit MaxDepositAmountUpdated(maxDepositAmount, _maxDepositAmount);
        maxDepositAmount=_maxDepositAmount;
    }
    

    function setMinAndMaxParticipationFee(uint _minAndMaxParticipationFeeAmount) external override onlyOwner() {
        emit MinAndMaxParticipationFee(minAndMaxParticipationFeeAmount,_minAndMaxParticipationFeeAmount);
        minAndMaxParticipationFeeAmount=_minAndMaxParticipationFeeAmount;
    }
    
    
    function setPlatformFee(uint256 _platformFee) external override onlyOwner() {
        require(_platformFee <= 10);
        emit PlatformFeeUpdated(platformFee,_platformFee);
        platformFee=_platformFee;
    }
    
    
    function setMaxLenghtRace(uint32 _raceId,uint256 _maxLenghtRace) external override onlyOwner() {
        require(race[_raceId].status == Status.Close,"You cannot change the time until the race is over.");
        emit UpdateMaxLenghtRace(maxLenghtRace,_maxLenghtRace);
        maxLenghtRace = _maxLenghtRace;
    }
    

    function setTotalParticipants(uint32 _totalParticipants) external override onlyOwner() {
        emit UpdateTotalParticipants(totalParticipants, _totalParticipants);
        totalParticipants=_totalParticipants;
    }
    

    function setRaceTokenTotalSupply(uint256 _raceTokenTotalSupply) external override onlyOwner() {
        emit UpdateRaceTokenTotalSupply(raceTokenTotalSupply, _raceTokenTotalSupply);
        raceTokenTotalSupply=_raceTokenTotalSupply;
    }
    

    function calculatePlatformFee(uint256 _amount) private view returns(uint256) {
        return _amount.mul(platformFee).div(
            10**2
        );
    } 
    

    function approveRace(address raceTokenAddress) private {
        IERC20(raceTokenAddress).approve(uniswapV2RouterAddress, type(uint).max);
    }
    

    function approveRemoveRace() private {
         uint256 liquidty = IERC20(uniswapV2Pair).balanceOf(address(this));    
         IERC20(uniswapV2Pair).approve(uniswapV2RouterAddress,liquidty);
    }
    
    
    function lastPlayerIndex(uint32 raceId) private view returns(uint32) {
        uint32 last = 0;
        for(uint8 i=0;i<=totalParticipants;i++) {
             if(last < racePlayerIndex[raceId][i].playerIndex) {
               last = racePlayerIndex[raceId][i].playerIndex;
             }
        }
        return last;
    }
    
   
    function startRace(uint32 _raceId,string memory _raceAuthKey) external override onlyOwner()  {
      require(race[currentRaceId].status != Status.Open,"You can't start the race"); 
      require(race[_raceId].status == Status.Pending,"Not time to start race");

      raceAuthKeys[_raceId]=_raceAuthKey;
      currentRaceId=_raceId;
      
       race[_raceId] = Race({
           raceId:_raceId,
           status:Status.Open,
           startTime:0,
           endTime:0,
           participationFeeAmountEther:minAndMaxParticipationFeeAmount,
           winnerNumber:[uint64(0), uint64(0), uint64(0), uint64(0), uint64(0), uint64(0), uint64(0),uint64(0),uint64(0),uint64(0)]
       });
    }
    
    function openTrade() external onlyOwner() {
        require(race[currentRaceId].status == Status.Open,"Not time to open trade");
        require(lastPlayerIndex(currentRaceId) == totalParticipants,"Not all players joined in race");
         race[currentRaceId].startTime=block.timestamp;
         race[currentRaceId].endTime=block.timestamp+maxLenghtRace;    
         currentRaceTokenAddress = IRacingTokenCreateFactory(racingTokenFactory).startRacingToken(
           name.concat(Strings.toString(currentRaceId)),
           symbol.concat(Strings.toString(currentRaceId)),
           raceTokenTotalSupply,
           currentRaceId);
           
        approveRace(currentRaceTokenAddress);
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(uniswapV2RouterAddress);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(currentRaceTokenAddress), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(currentRaceTokenAddress),
            IERC20(currentRaceTokenAddress).balanceOf(address(this)),
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp + 360
        );
        

    }
    
    function calculateFinalNumber() private {
            uint64 finalNumber = randomGenerator.viewRandomResult();
            uint8 count=0;
            while(finalNumber>0 && count<10) {
                 lastWinnerRaceTicketNumber.push(finalNumber % 10);
                 finalNumber = finalNumber / 10;
                 count++;
            }            
    }
    
    function finishRace(uint32 raceId) external override onlyOwner() nonReentrant {
         require(race[raceId].status == Status.Open, "The race not started");
         require(block.timestamp >= race[raceId].endTime, "The race not over");
         require(currentRaceId == raceId, "You can't finish this race");
         approveRemoveRace();
         IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(uniswapV2RouterAddress);     
        _uniswapV2Router.removeLiquidity(            
            address(currentRaceTokenAddress),
            address(wethAddress),
            IERC20(uniswapV2Pair).balanceOf(address(this)),
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp + 360
        );        
        IWETH(wethAddress).withdraw(weth.balanceOf(address(this))); 
        uint256 tFee = calculatePlatformFee(address(this).balance);
        uint256 tTransferAmount = address(this).balance.sub(tFee);
        payable(address(owner())).transfer(address(this).balance.sub(tTransferAmount)); 
        randomGenerator.getRandomNumber(uint256(keccak256(abi.encodePacked(raceId, getSeed()))));
        race[raceId].status=Status.Close;
    }
    
    function calculateWinnerNumbers(uint64[] memory numbers) private view returns (uint8) {
        uint8 times = 0;
        for(uint8 i= 0; i < numbers.length; i++) 
        {
            if(numbers[i] == lastWinnerRaceTicketNumber[i]) {
                times++;
            }
        }
        return times;
    } 
    function calculateWinner(uint32 raceId) private returns(uint32) {
      uint32 store_var = 0;
      uint32 winnerCount=0;
      for(uint8 i=0; i<= totalParticipants;i++) {
          if(racePlayerIndex[raceId][i].raceId == raceId) {
              
             racePlayerIndex[raceId][i].countWinnersNumber = calculateWinnerNumbers(racePlayerIndex[raceId][i].raceTicketNumber);
               if(store_var < racePlayerIndex[raceId][i].countWinnersNumber) {
               store_var = racePlayerIndex[raceId][i].countWinnersNumber;
             }
          }
      }
      
      for(uint8 j=0; j<= totalParticipants; j++) {
          if(racePlayerIndex[raceId][j].raceId == raceId) 
            if(store_var == racePlayerIndex[raceId][j].countWinnersNumber)
            {
                winnerCount++;
                racePlayerIndex[raceId][j].winner=true;
                racePlayer[raceId][racePlayerIndex[raceId][j].player].winner=true;
            }
      }     
      return winnerCount;
    } 
    
    function drawClaimable(uint32 _raceId) external override onlyOwner() nonReentrant {
        require(race[_raceId].status == Status.Close, "The race not closed"); 
        calculateFinalNumber();
        uint32 winnerCount =calculateWinner(_raceId);
        require(winnerCount !=0,"You need to do a forced reboot");
        uint256 tTransferAmount=0;
        if(winnerCount == 1)
         tTransferAmount = address(this).balance;
        else
         tTransferAmount = address(this).balance.sub(winnerCount); 
         
         for (uint8 i = 0; i <= totalParticipants; i++) {
             if(racePlayerIndex[_raceId][i].winner == true)
                payable(address(racePlayerIndex[_raceId][i].player)).transfer(tTransferAmount);
        }
        race[_raceId].status == Status.Claimable;
    }
    
    function joinRace(uint32 _raceId,string memory _raceAuthKey,uint64[] calldata _raceTicket) external override payable nonReentrant {
        require(keccak256(abi.encodePacked(_raceAuthKey)) == keccak256(abi.encodePacked(raceAuthKeys[_raceId])), "Wrong auth key");
        require(race[_raceId].status == Status.Open, "The race not started");
        require(racePlayer[_raceId][msg.sender].player != msg.sender, "You can't join again same race");
        require(lastPlayerIndex(_raceId) <= totalParticipants,"No more players can join");
        require(msg.value == minAndMaxParticipationFeeAmount,"Not enough fee");
        require(_raceTicket.length != 9, "No race ticket specified");   
        uint32 lastPlayer=lastPlayerIndex(_raceId)+1;
        
        racePlayerIndex[_raceId][lastPlayer] = RaceTicket({
            raceTicketNumber:_raceTicket,
            raceId:_raceId,
            player:msg.sender,
            countWinnersNumber:0,
            playerIndex:lastPlayer,
            winner:false
        }); 
        racePlayer[_raceId][msg.sender] =racePlayerIndex[_raceId][lastPlayer];            
    }
    
    function setUniswapV2Router(address newAddress) external override onlyOwner() {
        require(race[currentRaceId].status == Status.Close,"The race not closed");
        emit UpdateUniswapV2Router(newAddress, uniswapV2RouterAddress);
        uniswapV2RouterAddress=newAddress;
    }
    
    function setRacingTokenFactoryAddress(address newFactoryAddress) external override onlyOwner() {
        require(race[currentRaceId].status == Status.Close,"The race not closed");
        emit UpdateRacingTokenFactoryAddress(newFactoryAddress, racingTokenFactory);
        racingTokenFactory=newFactoryAddress;
    }
    
    function setRandomNumberGeneratorAddress(address newGeneratorAddress) external override onlyOwner() {
        require(race[currentRaceId].status == Status.Close,"The race not closed");
        randomGenerator = IRandomNumberGenerator(newGeneratorAddress);
    }
    
    function viewCurrentRaceId() external override view returns(uint32) {
        return currentRaceId;
    }

    function getSeed() internal virtual view returns (uint256 seed) {
        return uint256(blockhash(block.number - 1));
    }
    
    function getLastWinnerRaceTicketNumber() public view returns(uint64[] memory) {
        return lastWinnerRaceTicketNumber;
    }
    
      
    function getJoinedPlayer(uint32 _raceId,address player) public view returns(bool) {
        if(racePlayer[_raceId][player].player == player)
            return true;
        else 
            return false;
    }
    
    function getWinnerPlayer(uint32 _raceId,address player) public view returns(bool) {
       return racePlayer[_raceId][player].winner;
    }
    
    function getCurrentRaceTokenAddress() public view returns(address) {
        return currentRaceTokenAddress;
    }

    function getRaceEndTime(uint32 _raceId) public view returns(uint256) {
        return race[_raceId].startTime - race[_raceId].endTime;
    }

    fallback() external payable {}
    receive() external payable {}

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


library ConcatStrings {

    function concat(string memory _base, string memory _value) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        string memory _tmpValue = new string(_baseBytes.length + _valueBytes.length);
        bytes memory _newValue = bytes(_tmpValue);

        uint i;
        uint j;

        for(i=0; i<_baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for(i=0; i<_valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i];
        }

        return string(_newValue);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
     function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IUniswapV2Factory {    
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IRandomNumberGenerator {
    /**
     * Requests randomness from a user-provided seed
     */
    function getRandomNumber(uint256 _seed) external;

    /**
     * View latest race number
     */
    function viewLatestRaceId() external view returns (uint256);

    /**
     * Views random result
     */
    function viewRandomResult() external view returns (uint64);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


interface IRacingTokenRouter {
    enum Status {
        Pending,
        Open,
        Close,
        Claimable
    }
    struct Race {  
        uint32 raceId;
        Status status;        
        uint256 startTime;
        uint256 endTime;
        uint participationFeeAmountEther;
        uint64[10] winnerNumber;                
    }
    
    struct RaceTicket {
        uint64[] raceTicketNumber;
        address player;
        uint32 raceId;
        uint32 countWinnersNumber;
        uint32 playerIndex;
        bool winner;
    }
  
    function accountBalance() external view returns(uint);    

    function raceBalance(address raceTokenAddress) external view returns(uint256);    

    function setMaxDepositAmount(uint _maxDepositAmount) external;

    function setMinAndMaxParticipationFee(uint _minAndMaxParticipationFeeAmount) external;

    function setPlatformFee(uint256 _platformFee) external;
    
    function setMaxLenghtRace(uint32 _raceId,uint256 _maxLenght) external;

    function setTotalParticipants(uint32 _totalParticipants) external;

    function setRaceTokenTotalSupply(uint256 _raceTokenTotalSupply) external;

    function startRace(uint32 _raceId,string calldata _raceAuthKey) external;
    
    function finishRace(uint32 raceId) external;
    /**
     * @notice Buy race tickets for the current race
     * @param _raceId: raceId
     * @param _raceTicket:_raceTicket
     * @dev Callable by users
     */
    function joinRace(uint32 _raceId,string memory _raceAuthKey,uint64[] calldata _raceTicket) external payable;
    
    function drawClaimable(uint32 _raceId) external;

    function setUniswapV2Router(address newAddress) external;

    function setRacingTokenFactoryAddress(address newFactoryAddress) external;
    
    function setRandomNumberGeneratorAddress(address newGeneratorAddress) external;
    
    function viewCurrentRaceId () external view returns(uint32);
    
    event MaxDepositAmountUpdated(uint oldAmount, uint newAmount);

    event MinAndMaxParticipationFee(uint oldAmount, uint newAmount);

    event PlatformFeeUpdated(uint256 oldFee, uint256 newFee);  
    
    event UpdateMaxLenghtRace(uint256 oldLenght, uint256 newLenght);

    event UpdateTotalParticipants(uint32 oldTotalParticipants,uint32 newTotalParticipants);

    event UpdateRaceTokenTotalSupply(uint256 oldRaceTokenTotalSupply,uint256 newRaceTokenTotalSupply);

    event UpdateUniswapV2Router(address indexed newAddress, address indexed oldAddress);    

    event UpdateRacingTokenFactoryAddress(address indexed newAddress, address indexed oldAddress);
  
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IRacingTokenCreateFactory {
    
    function startRacingToken (string memory name,string memory symbol, uint totalSupply,uint32 id)  external returns(address);
    
    function showCurrentRaceId() external view returns(uint32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}