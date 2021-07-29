/**
 *Submitted for verification at polygonscan.com on 2021-07-28
*/

pragma solidity ^0.7.0;

interface AggregatorV3Interface {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint256 _roundId)
    external
    view
    returns (
      uint256 roundId,
      uint256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint256 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint256 roundId,
      uint256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint256 answeredInRound
    );

}

interface TokenInterface {
    function approve(address, uint256) external;
    function allowance(address, address) external returns (uint256);
    function transfer(address, uint) external;
    function transferFrom(address, address, uint) external;
    function deposit() external payable;
    function withdraw(uint) external;
    function balanceOf(address) external view returns (uint);
    function decimals() external view returns (uint);
}





/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}




contract DSMath {
  uint constant WAD = 10 ** 18;
  uint constant RAY = 10 ** 27;

  function add(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(x, y);
  }

  function sub(uint x, uint y) internal virtual pure returns (uint z) {
    z = SafeMath.sub(x, y);
  }

  function mul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.mul(x, y);
  }

  function div(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.div(x, y);
  }

  function wmul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, y), WAD / 2) / WAD;
  }

  function wdiv(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, WAD), y / 2) / y;
  }

  function rdiv(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, RAY), y / 2) / y;
  }

  function rmul(uint x, uint y) internal pure returns (uint z) {
    z = SafeMath.add(SafeMath.mul(x, y), RAY / 2) / RAY;
  }

  function toInt(uint x) internal pure returns (int y) {
    y = int(x);
    require(y >= 0, "int-overflow");
  }

  function toRad(uint wad) internal pure returns (uint rad) {
    rad = mul(wad, 10 ** 27);
  }

}


// File: @chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol
// File: betting_main.sol
// SPDX-License-Identifier: GPL-3.0
contract BettingContract is DSMath{

    TokenInterface constant token = TokenInterface(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2); //for ethhh 

    AggregatorV3Interface internal priceFeed;

    mapping(address => address[]) registerToken; 
    mapping (address => uint256) initialState;   
    address[] participants;
    uint256 length = participants.length;
    mapping(uint256 => bet) bets;
    address[] tokenArray;
    address[] selectedToken;
    uint256 counter;
    uint256 initialValue;
    uint256 percentage;
    uint256 newSum;
    uint256 highest;
    address highestScorer;
    //
    uint256 lastUpdateTimeStamp;
    mapping(uint256 => uint256) dayPrice;

    struct bet{
        uint creationTime;
        uint endTime;
        uint betAmount;
        address userUp;
        address userDown;
        uint256 prediction;
        bool open;
    }

    modifier updatePrices(){
        if((block.timestamp-lastUpdateTimeStamp)/60/60 > 1){
            uint256 price = getThePrice();
            if(dayPrice[block.timestamp/86400]==0){
                dayPrice[block.timestamp/86400] = price;
            }
        lastUpdateTimeStamp = block.timestamp;
        }
        _;
    }

    function getThePrice()internal view returns (uint256) {
        (
            uint256 roundID, 
            uint256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint256 answeredInRound
        ) = priceFeed.latestRoundData();
        return price/1000000000000000000;
      }
    
    receive() external payable {
        
    }

    function cancelBet(uint256 betId) updatePrices public{
        require(bets[betId].open==true, 'Bet has oponent');
        require(bets[betId].userUp==msg.sender || bets[betId].userDown==msg.sender, 'Not your bet!');
    
        payable(msg.sender).transfer(bets[betId].betAmount);
        bets[betId].betAmount=0;
        
    }


    function createBet(uint256 betId, address token1, address token2, address token3, uint256 prediction, bool trueIfUp, uint256 endTime) updatePrices public payable{
        require(bets[betId].creationTime!=0,'Bet Does not Exist');
        require(bets[betId].endTime>block.timestamp,'Bet ended');
        require(bets[betId].open==true,'Bet is full');
        require(msg.value==bets[betId].betAmount,'BetAmount does not match');
        
        if(bets[betId].userUp==address(0x0)){
            bets[betId].userUp = msg.sender;
        }
        else{
            bets[betId].userDown = msg.sender;
        }
        bets[betId].open = false;

        registerToken[msg.sender].push();
        tokenArray = [token1, token2, token3]; 
        participants.push(msg.sender);
        
        require(msg.value>0,'Bet cannot be of 0 Amount');
        token.transferFrom(msg.sender, address(this), msg.value);
        counter += 1;
        
        if(trueIfUp==true){
            bet memory newBet = bet(block.timestamp, endTime, msg.value, msg.sender, address(0x0), prediction, true);
            bets[counter] = newBet;
        }
        else{
            bet memory newBet = bet(block.timestamp, endTime, msg.value, address(0x0), msg.sender, prediction, true);
            bets[counter] = newBet;
        }

        calculatePrice(msg.sender); 

    }


    function calculatePrice(address user) internal {
        uint256 sum = 0;

        for (uint256 i = 0; i < 3; i = i++) {  //for loop
            if(i == 0){
                priceFeed = AggregatorV3Interface(tokenArray[0]); // btc
                uint256 a = mul(getThePrice(), 1);
                sum = add(sum , a);
            }
            if(i == 1){
                priceFeed = AggregatorV3Interface(tokenArray[1]); // btc
                uint256 b = mul(getThePrice(), div(75, 100));
                sum = add(sum , b);
            }
            if(i == 2){
                priceFeed = AggregatorV3Interface(tokenArray[2]); // btc
                uint256 c = mul(getThePrice(), div(50, 100));
                sum = add(sum , c);
            }
        }
        initialState[user]=sum;
    }

    function finalize () internal {

        for (uint256 i=0; i<length; i++) {
            initialValue = initialState[participants[i]];
            selectedToken = registerToken[participants[i]];

            for (uint256 j = 0; j < 3; j = j++) {  //for loop
                if(j == 0){
                    priceFeed = AggregatorV3Interface(selectedToken[0]); 
                    uint256 a = mul(getThePrice(), 1);
                    newSum = add(newSum , a);
                }
                if(j == 1){
                    priceFeed = AggregatorV3Interface(selectedToken[1]); 
                    uint256 b = mul(getThePrice(), div(75, 100));
                    newSum = add(newSum , b);
                }
                if(j == 2){
                    priceFeed = AggregatorV3Interface(selectedToken[2]); 
                    uint256 c = mul(getThePrice(), div(50, 100));
                    newSum = add(newSum , c);
                }
            }

        percentage = mul( div ( sub(newSum, initialValue), newSum), 100); //(b-a)/b*100

        if( highest < percentage) {
        highest = percentage;
        highestScorer = participants[i];
        }
        } 

    }
}