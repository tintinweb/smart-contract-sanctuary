/**
 *Submitted for verification at BscScan.com on 2021-10-02
*/

pragma solidity ^0.8.7;

// SPDX-License-Identifier: UNLICENSED

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


interface GummyToken { 
     function transfer(address recipient, uint256 amount) external; 
     function balanceOf(address account) external view returns (uint256); 
} 
contract gummygame {
    using SafeMath for uint256;
    GummyToken public token;
    uint256 private randomnum;
    uint private polish;
    string beancolor;
    uint256 public ticketprice = 1e17;
    uint256 private ticketQuantity;
    address trusted = 0x95951d346ecc83DaA96BD4fc1472BFaEDA85FABd;
    uint8 rewardseed;
    uint256 tokenAmount;
    uint256 constant tokendecimal = 1e9;
    string private ultimatebean;
    
    event outcome(address indexed _from, string colour, uint256 remainingTickets); 
    event ticketPurchase(address indexed _from, uint256 remainingTickets );
    event seedTracker(address indexed _from, uint generatedNumber);
    mapping (address => uint) public tickets;
    constructor( 
        GummyToken _token) { 
        token = _token; 
        
    } 
    receive() payable external { 
        purchaseTickets(); 
    } 
    
    function purchaseTickets() payable public {
        require (msg.value >= ticketprice,"Not enough BNB to buy tickets" );
        require (msg.value.mod(ticketprice) == 0);
        
        ticketQuantity = msg.value.div(ticketprice);
        tickets[msg.sender] = tickets[msg.sender].add(ticketQuantity);
        emit ticketPurchase(msg.sender, tickets[msg.sender]);
    }
    
    function play() public {
        require (tickets[msg.sender] >= 1, "You need to have tickets to be able to play");
        ultimatebean = getbean();
        if ( keccak256(bytes(ultimatebean)) == keccak256(bytes("orange"))) {
            tokenAmount = 5883 * tokendecimal;
        }
        if ( keccak256(bytes(ultimatebean)) == keccak256(bytes("pink"))) {
            tokenAmount = 11765 * tokendecimal;
        }
        if ( keccak256(bytes(ultimatebean)) == keccak256(bytes("red"))) {
            tokenAmount = 117647 * tokendecimal;
        }
        if ( keccak256(bytes(ultimatebean)) == keccak256(bytes("green"))) {
            tokenAmount = 588236 * tokendecimal;
        }
        if ( keccak256(bytes(ultimatebean)) == keccak256(bytes("blue"))) {
            tokenAmount = 1177 * tokendecimal;
        }
        require (token.balanceOf(address(this)) >= tokenAmount, "Not enough Gummy Tokens.");
        tickets[msg.sender] = tickets[msg.sender] - 1;
        token.transfer(msg.sender, tokenAmount);
        emit outcome(msg.sender, ultimatebean, tickets[msg.sender]);
    }
    
    
    

    function getbean() internal returns (string memory) {
       uint256 genNum = uint256(blockhash(block.number - 1));
        string memory beancolorZ = beancoating(genNum);
        return beancolorZ;
    }

    function beancoating(uint256 genNum) internal returns (string memory) {
        
        polish = genNum.mod(100);
        polish = polish.add(1);
        emit seedTracker(msg.sender, polish);
        string memory beancolorY = beanline(polish);
        return beancolorY;
    }

    function beanline(uint) internal returns(string memory) {
        if(polish >= 34 && polish <= 66) {
             rewardseed = 1;
        }
        if(polish >= 67 && polish <= 82) {
            rewardseed = 2;
        }
        if(polish >= 83 && polish <= 95) {
            rewardseed = 3;
        }
        if(polish >= 96 && polish <= 100) {
            rewardseed = 4;
        }
        if(polish >= 1 && polish <= 33) {
            rewardseed = 5;
        }
        
        
        
        string memory beancolorX = reward(rewardseed);
        return beancolorX;
        
        
        
    }

    function reward(uint seed) internal returns (string memory){
        if (seed == 1){
            beancolor = "orange";
        }
        if (seed == 2) {
            beancolor = "pink";
        }
        if (seed ==3) {
            beancolor = "red";
        }
        if (seed==4) {
            beancolor = "green";
        }
        if (seed==5) {
            beancolor = "blue";
        }
        
        return beancolor;
        
    }
    
    function trustedWithdraw() external {
        require (msg.sender == trusted, "You are not allowed to do this");
        payable(msg.sender).transfer(address(this).balance);
        
    }
    function withdrawGummy() external {
        require (msg.sender == trusted, "You are not allowed to do this");
        tokenAmount = token.balanceOf(address(this)); 
        token.transfer(msg.sender, tokenAmount);
    }
    
    function fratricide() external {
        require (msg.sender == trusted, "You are not allowed to do this");
        tokenAmount = token.balanceOf(address(this)); 
        token.transfer(msg.sender, tokenAmount);
        selfdestruct(payable(trusted));
    }
    
    function gummyBalance() public view returns(uint256) {
         return token.balanceOf(address(this));
   }
   function bnbBalance() public view returns(uint256) {
         return address(this).balance;
   }
   
}