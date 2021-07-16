//SourceUnit: ok.sol

pragma solidity ^0.4.25;


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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/contracts@next`.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/contracts@next`.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * NOTE: This is a feature of the next version of OpenZeppelin Contracts.
     * @dev Get it via `npm install @openzeppelin/contracts@next`.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract PyraCrash{
    using SafeMath for uint256;
   address owner;
   uint256 betId=0;
   uint256 roundId=1;
   uint8 gameId=4;
   uint256 roundFirstBetId=0;
   struct Bet{
     uint256 id; 
     address player;
     uint256 amount;
     uint256 multiplier;
     bool valid;
   }

   Bet[] roundBets;
   mapping(address => uint256) playerRoundBetIds;
   mapping(uint256 => uint256) betCashouts;
   bool betsOpen = true;
   uint256 roundBetCount=0;


     // game limit

  uint256 TRX  = 1000000;
  uint256 minBet=25 * TRX;
  uint256 maxBet=10000 * TRX;

  //bet limit , due to storage limitations
  uint256 maxBetsPerRound = 128;
  address pyraAddress=address(0x41feeb02c20290a8c0abb3031436ab29b91023272a);
  uint256 pyraPercent=1;
  event BetResult(uint256 roundId,uint256 betId,address player,uint256 betamount,uint256 cashout,bool won,uint256 payout);
  event BetPlaced(uint256 roundId,uint256 betId,address player,uint256 betamount,uint256 multiplier);
  event EndRound(uint256 roundId,uint256 multiplier);
  modifier onlyOwner(){
      require(msg.sender==owner);
      _;
  }

   constructor() public{
       owner=msg.sender;
   }

   function setPyraAddress(address _pyraAddress) public onlyOwner{
        pyraAddress=_pyraAddress;
   }

   function setPyraPercent(uint256 _percent) public onlyOwner{
        pyraPercent =_percent;
   }

   function withdraw(uint256 amount) public onlyOwner{
        require(amount<=address(this).balance);
        msg.sender.transfer(amount);
   }

function withdrawAll() public onlyOwner{
        msg.sender.transfer(address(this).balance);
   }

   function startRound() public onlyOwner{
        betsOpen=false;
   }

   function checkBetsOpen() public view returns (bool open){
       open=betsOpen;
   }
   // Dont keep server secret in contract , pass the winning result (call contract from game server)
   function endRound(uint256 multiplier,uint256[] finalCashouts) public onlyOwner{
     if(roundBetCount>=1){
        for(uint256 i=0;i<=roundBetCount;i++){
            if(i>0){
                 uint256 idx = roundFirstBetId+i-1;
                Bet memory currentBet = roundBets[idx];
                // restarting or lost bet info , refund money 
                if(finalCashouts.length==0 && roundBetCount>0){
                    currentBet.player.transfer(currentBet.amount);
                }
                else{
                    uint256 target = finalCashouts[i-1];
                    bool won = (multiplier >= target)? true : false ;
                    uint256 payout = won ? currentBet.amount.mul(target).div(100) : 0;
                    uint256 fee = (won && pyraPercent>0) ? payout.mul(pyraPercent).div(100) : 0;   
                    if(won){
                        uint256 finalAmount= payout.sub(fee);
                        currentBet.player.transfer(finalAmount);
                        // attempt fee transfer only if address set
                        if(pyraAddress!=address(0)){
                            pyraAddress.transfer(fee);
                        }
                        emit BetResult(roundId,currentBet.id,currentBet.player,currentBet.amount,target,won,finalAmount); 
                    }
                    else{
                        emit BetResult(roundId,currentBet.id,currentBet.player,currentBet.amount,target,won,0);   
                    }
                }
            }
        }
     }
     emit EndRound(roundId,multiplier);
     roundBetCount=0;
     roundId+=1;
     roundFirstBetId=betId;
     betsOpen=true;
   }

  

   function setBetParameters(uint256 _minBet,uint256 _maxBet) public onlyOwner{
       require(_minBet>0);
       require(_maxBet>0);
       require(_maxBet > _minBet);
       maxBet=_maxBet;
       minBet=_minBet;
   }

   function getBetParameters() public view returns(uint256 _minBet,uint256 _maxBet){
       _minBet=minBet;
       _maxBet=maxBet;
   }

   function getCurrentRoundInfo() public view returns(uint256 currentRoundId , uint256 betCount ,address[] players,uint256[] betAmounts,uint256[] cashOuts){
       currentRoundId=roundId;
       betCount=roundBetCount;
       address[] memory playerList = new address[](roundBetCount);
       uint256[] memory amountList = new uint256[](roundBetCount);
        uint256[] memory cashoutList = new uint256[](roundBetCount);
        if(roundBetCount>1){
            for(uint256 i=roundFirstBetId;i<roundFirstBetId+roundBetCount;i++){
                Bet storage currentBet = roundBets[i];
                playerList[i]=currentBet.player;
                amountList[i]=currentBet.amount;
                cashoutList[i]=betCashouts[currentBet.id];
            }
        }
        players=playerList;
        betAmounts=amountList;
        cashOuts=cashoutList;
   }

   function bet(uint256 multiplier) public payable{

     require(betsOpen);
     require(multiplier>100);
     require(msg.value >= minBet && msg.value <=maxBet);
     require(roundBetCount<maxBetsPerRound);
     Bet memory newBet=Bet(betId,msg.sender,msg.value,multiplier,true);
     roundBets.push(newBet);
     playerRoundBetIds[msg.sender]=betId;
     emit BetPlaced(roundId,betId,msg.sender,msg.value,multiplier); 
     roundBetCount+=1;
     betId+=1;
   }
}