/**
 *Submitted for verification at BscScan.com on 2022-01-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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

contract HartGame {
    using SafeMath for uint256;
    address private owner;
    mapping(address => uint256) public usersAmount;
    mapping(address => uint256) public count_number;
    mapping (address => mapping(uint256 => uint256)) public usersBets;
    mapping (address => mapping(uint256 => uint256)) public numberArray;
    mapping(uint256 => uint256) public upPercentages;
    mapping(uint256 => uint256) public downPercentages;
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event startBet(
        address userAddress,
        uint256 amount,
        uint256 number
    );
    event upBet(
        address userAddress,
        uint256 number,
        bool flag
    );
    event downBet(
        address userAddress,
        uint256 amount,
        bool flag
    );
    event claim(
        address userAddress,
        uint256 amount
    );
    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    // modifier to check if caller is user
     modifier isUser() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        downPercentages[1] = 1300;
        downPercentages[2] = 650;
        downPercentages[3] = 433;
        downPercentages[4] = 325;
        downPercentages[5] = 260;
        downPercentages[6] = 216;
        downPercentages[7] = 185;
        downPercentages[8] = 162;
        downPercentages[9] = 144;
        downPercentages[10] = 130;
        downPercentages[11] = 118;
        downPercentages[12] = 108;
        downPercentages[13] = 100;

        upPercentages[1] = 100;
        upPercentages[2] = 108;
        upPercentages[3] = 118;
        upPercentages[4] = 130;
        upPercentages[5] = 144;
        upPercentages[6] = 162;
        upPercentages[7] = 185;
        upPercentages[8] = 216;
        upPercentages[9] = 260;
        upPercentages[10] = 325;
        upPercentages[11] = 433;
        upPercentages[12] = 650;
        upPercentages[13] = 1300;


        emit OwnerSet(address(0), owner);
    }
    //generate start bet id
    function start() external payable returns (uint256){
        uint256 _amount = msg.value;
        require(_amount > 0 , "amount is zero!");
        usersAmount[msg.sender] =  _amount;
        uint256 seed = uint256(keccak256(abi.encodePacked(
        block.timestamp + block.difficulty +
        (uint256(keccak256(abi.encodePacked(block.coinbase)))) +
        block.gaslimit + 
        (uint256(keccak256(abi.encodePacked(msg.sender)))) +
        block.number
        )));
        uint256 rand = (seed % 52).add(1);
        uint256 number = (rand % 13).add(1);
        count_number[msg.sender] =1;
        usersBets[msg.sender][1] = number;
        numberArray[msg.sender][1] = rand;
        count_number[msg.sender] = count_number[msg.sender].add(1);
        emit startBet(msg.sender, _amount, rand);
        return rand;
    }

    //generate up bet id
    function bull() external returns (uint256){
        bool flag_generate= false;
        uint256 rand = 0;
        do {                   // do while loop	
        uint256 seed = uint256(keccak256(abi.encodePacked(
        block.timestamp + block.difficulty +
        (uint256(keccak256(abi.encodePacked(block.coinbase)))) +
        block.gaslimit + 
        (uint256(keccak256(abi.encodePacked(msg.sender)))) +
        block.number
        )));
        rand = (seed % 52).add(1);
        for(uint8 i =1 ; i < count_number[msg.sender] ; i++){
            if(numberArray[msg.sender][i] == rand){
                flag_generate = true;
            }
        }
        uint256 number = (rand % 13).add(1);
        usersBets[msg.sender][count_number[msg.sender]] = number;
        numberArray[msg.sender][count_number[msg.sender]] = rand;
        if(number >= usersBets[msg.sender][count_number[msg.sender] - 1]){
            usersAmount[msg.sender] =upPercentages[usersBets[msg.sender][count_number[msg.sender] - 1]].mul(usersAmount[msg.sender]).div(100) ;
            count_number[msg.sender] = count_number[msg.sender].add(1);
            emit upBet(msg.sender, rand, true);
        }
        else {
            usersAmount[msg.sender] = 0;
            emit upBet(msg.sender, rand, false);
        }
      }
      while(flag_generate);
        return rand;

    }

    //generate down bet id
    function bear() external returns (uint256){
        bool flag_generate= false;
        uint256 rand = 0;
        do {                   // do while loop	
        uint256 seed = uint256(keccak256(abi.encodePacked(
        block.timestamp + block.difficulty +
        (uint256(keccak256(abi.encodePacked(block.coinbase)))) +
        block.gaslimit + 
        (uint256(keccak256(abi.encodePacked(msg.sender)))) +
        block.number
        )));
        rand = (seed % 52).add(1);
        for(uint8 i =1 ; i < count_number[msg.sender] ; i++){
            if(numberArray[msg.sender][i] == rand){
                flag_generate = true;
            }
        }
        uint256 number = (rand % 13).add(1);
        usersBets[msg.sender][count_number[msg.sender]] = number;
        numberArray[msg.sender][count_number[msg.sender]] = rand;
        if(number <= usersBets[msg.sender][count_number[msg.sender] - 1]){
            usersAmount[msg.sender] =upPercentages[usersBets[msg.sender][count_number[msg.sender] - 1]].mul(usersAmount[msg.sender]).div(100) ;
            count_number[msg.sender] = count_number[msg.sender].add(1);
            emit upBet(msg.sender, rand, true);
        }
        else {
            usersAmount[msg.sender] = 0;
            emit upBet(msg.sender, rand, false);
        }
      }
      while(flag_generate);
        return rand;
    }
    //claim requests
    function claimReward() external payable{
        require(usersAmount[msg.sender] > 0,"You losted already");
        uint256 claimAmount =  usersAmount[msg.sender];
        payable(msg.sender).transfer(claimAmount);
        emit claim(msg.sender, claimAmount);
    }
    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}