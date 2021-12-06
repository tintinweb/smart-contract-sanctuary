/**
 *Submitted for verification at BscScan.com on 2021-12-05
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;


/** 
 * 0xFd616b457D1ce7Eb2C765C56E715c98530a080D6
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


contract TBLottery {
    
    using SafeMath for uint256;
    
    //list of players registered in lotery
    address payable[] public players;
    address public admin;
    address payable public winner1;
    address payable public winner2;
    address payable public winner3;
    uint256 public numTicket;
        uint256 public prize1;
        uint256 public prize2;
        uint256 public prize3;
    
    /**
     * @dev makes 'admin' of the account at point of deployement
     */ 
    constructor() {
        admin = msg.sender;
        //automatically adds admin on deployment
        //players.push(payable(admin));
    }
    
    modifier onlyOwner() {
        require(admin == msg.sender, "You are not the owner");
        _;
    }
    
    
    /**
     * @dev requires the deposit of 0.1 ether and if met pushes on address on list
     */ 
    receive() external payable {
        //require that the transaction value to the contract is 0.1 ether
        require(msg.value == 0.1 ether , "Must send 0.1 ether amount");
        
        //makes sure that the admin can not participate in lottery
        require(msg.sender != admin);
        
        // pushing the account conducting the transaction onto the players array as a payable adress
        players.push(payable(msg.sender));
        numTicket=players.length;
    }
    
    /**
     * @dev gets the contracts balance
     * @return contract balance
    */ 
    function getBalance() public view onlyOwner returns(uint256){
        // returns the contract balance 
        return address(this).balance;
    }
    
    /**
     * @dev generates random int *WARNING* -> Not safe for public use, vulnerbility detected
     * @return random uint
     */ 
    function random() public view returns(uint256){
       return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }
     function randomNum() public view returns(uint256){
       return random().mod(players.length);
    }
    /** 
     * @dev picks a winner from the lottery, and grants winner the balance of contract
     */ 
    
        function pickWinner1() public onlyOwner {
        uint256 ind;
        //makes sure that we have enough players in the lottery  
        require(players.length >= 3 , "Not enough players in the lottery");
               
        //selects the winners with random number
        ind = random().mod(players.length);
        winner1 = players[ind];

          //transfers balance to winner
        prize1= getBalance().mul(50).div(100);
        prize2= getBalance().mul(30).div(100);
        prize3= getBalance().mul(10).div(100);
        winner1.transfer(prize1);
        winner2.transfer(prize2); 
        winner3.transfer(prize3); //

        payable(admin).transfer(getBalance());
        
        
    }
    
    function pickWinner2() public onlyOwner {

        uint256 ind;

        //makes sure that we have enough players in the lottery  
        require(players.length >= 3 , "Not enough players in the lottery");
        
     
        ind = random().mod(players.length);
        winner2 = players[ind];

        //transfers balance to winner

        
        
    }

    function pickWinner3andPay() public onlyOwner {

        uint256 ind;

        

        //makes sure that we have enough players in the lottery  
        require(players.length >= 3 , "Not enough players in the lottery");
        

         ind = random().mod(players.length);
        winner3 = players[ind];
        
       //gets remaining amount AKA 10% -> must make admin a payable account
        
    }
    
    /**
     * @dev resets the lottery
     */ 
    function resetLottery() public onlyOwner {
        players = new address payable[](0);
        winner1=payable(address(0));
        winner2=payable(address(0));
        winner3=payable(address(0));

        prize1=0;
        prize2=0;
        prize3=0;
    }

}