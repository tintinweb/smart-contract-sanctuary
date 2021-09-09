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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract BettingContract{

    using SafeMath for uint256;
    
    uint256 numberOfBets;

    enum State{ await_approval, await_funds, await_decision, completed }

    struct Bet {
        string betReason;
        uint256 amountToBet;
        address payable firstBetter;
        address payable secondBetter;
        address payable thirdParty;
        uint256 betId;
        State state;
        uint256 addressWhichApproved;
        uint256 addressWhichFunded;
    }
    

    mapping (uint => Bet) betList;

    mapping (uint256 => address[]) betIdToApprove;
    mapping (uint256 => address[]) adressFundedBet;

    constructor() public {
        numberOfBets = 0;
    }

    modifier checkPartOfBet(uint256 betId){ 
        require(betList[betId].firstBetter == msg.sender || betList[betId].secondBetter == msg.sender || betList[betId].thirdParty == msg.sender, "You are  not part of this bet");
        _;
    }

    modifier checkIntergerOnly (uint256 integerToCheck) {
        require(integerToCheck.mod(1) == 0,"The number is not an integer");
        _;
    }


    function createBet(string memory _betReason,uint256 _amount, address payable _firstAddress, address payable _secondAddress, address payable _thirdParty ) public  checkIntergerOnly (_amount) returns(uint256){

        require(_firstAddress != _secondAddress && _secondAddress!= _thirdParty && _firstAddress!= _thirdParty, "All three address participating in the bet must be different addresses.");

        uint256 betId = numberOfBets;
        address[3] memory adressesToApprove;
        address[2] memory addressesToFund;
        
        betList[betId] = Bet(_betReason,_amount, _firstAddress, _secondAddress, _thirdParty, betId, State.await_approval, 0, 0);
        betIdToApprove[betId] = adressesToApprove;
        adressFundedBet[betId] = addressesToFund;
        numberOfBets++;
        return betId;
    }

    
    function approveBet(uint256 betId) external checkPartOfBet(betId) {
        require(betList[betId].firstBetter == msg.sender || betList[betId].secondBetter == msg.sender || betList[betId].thirdParty == msg.sender, "You are  not part of this bet");

        for(uint256 i = 0; i < betIdToApprove[betId].length; i++){

            if(betIdToApprove[betId][i] == msg.sender){
                revert("You have already approved the bet");
            }
        }

        betIdToApprove[betId].push(msg.sender);
        betList[betId].addressWhichApproved = betList[betId].addressWhichApproved.add(1);

        //Hard coded because for some reason when I put betIdToApprove[IdBet].length, it does not work, the length of the array is  supposed to be 3 because there are only  3 different participants in a bet
        if(betList[betId].addressWhichApproved == 3 ){
            betList[betId].state = State.await_funds;
        } 
    }


    function transferFundsForBet(uint256 betId) external payable checkPartOfBet(betId) {
        require(msg.sender != betList[betId].thirdParty, "You are the third party. You are not allowed to bet");
        require(betList[betId].state == State.await_funds, "The bet is still in process of being approved");

        for(uint256 i = 0; i< adressFundedBet[betId].length; i++){

            if(adressFundedBet[betId][i] == msg.sender){

                revert("You have already funded the bet");

            }
        }
        
        require(msg.value == betList[betId].amountToBet, "The amount inputted is not equal to the amount you are supposed to bet with");

        (bool success, ) = betList[betId].thirdParty.call{value: msg.value}("");
        require(success, "Transaction failed");

        adressFundedBet[betId].push(msg.sender);
        betList[betId].addressWhichFunded = betList[betId].addressWhichFunded.add(1);
        
        //Hard coded because for some reason when I put adressFundedBet[betId].length, it does not work, the number of participants that will transfer funds in a bet is 2, that is why I put == to 2
        if(betList[betId].addressWhichFunded == 2){
            betList[betId].state = State.await_decision;
        }
    }

    function performBetDecision(uint betId, address payable winner) external payable {
        require(msg.sender == betList[betId].thirdParty,"You are not the third party, you are not allowed to perform a decision on the bet");
        require(betList[betId].state == State.await_decision, "The bet has either already been completed, or is not approved by all participants yet, or not all participants have transferred funds yet.");
        require(winner == betList[betId].firstBetter || winner == betList[betId].secondBetter, "The provided address is not a better of this bet");

        require(msg.value == betList[betId].amountToBet.mul(2), "The value inputted is not the ammount to give to the winner");

        (bool success, ) = winner.call{value: msg.value}("");
        require(success, "Transaction failed");

        betList[betId].state = State.completed;
        
    }

    //--------------------- view functions ---------------------


    function getBetReason(uint256 betId) external view returns(string memory){

        return betList[betId].betReason;

    }

    function getBetAmount(uint256 betId) external view returns(uint256){

        return betList[betId].amountToBet;

    }

    function getBetFirstBetter(uint256 betId) external view returns(address){

        return betList[betId].firstBetter;

    }
    
    function getBetSecondtBetter(uint256 betId) external view returns(address){

        return betList[betId].secondBetter;

    }

    function getBetThirdParty(uint256 betId) external view returns(address){

        return betList[betId].thirdParty;

    }

    function getLastBetId()external view returns(uint256){
        return numberOfBets;
    }

}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "london",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}