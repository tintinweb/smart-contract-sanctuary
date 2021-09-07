/**
 *Submitted for verification at BscScan.com on 2021-09-07
*/

// File: @openzeppelin/contracts/GSN/Context.sol
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


pragma solidity ^0.6.0;

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
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
     *
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
     *
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
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: @openzeppelin/contracts/utils/Address.sol



pragma solidity ^0.6.0;

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
contract Ownable is Context {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


pragma solidity 0.6.12;

interface ERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
     function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function balanceOf(address user) external view returns (uint);
    function decimals() external view returns (uint8);

    // don't need to define other functions, only using `transfer()` in this case
}





pragma solidity 0.6.12;
/**
 * @author 0mllwntrmt3
 * @title Octi BNB Liquidity Pool
 * @notice Accumulates liquidity in BNB from LPs and distributes P&L in BNB
 */
contract OctiStakeingPool is
    Ownable
{
    event Unstake(address indexed User,uint indexed amount);
    event Stake(address indexed User,uint indexed amount);
    
    mapping(address=>uint256) public stakeOfUser;
    mapping(address=>uint256) public earnOfUser;
    uint256 public octiPriceForPool;
    ERC20 token  = ERC20(0x6c1dE9907263F0c12261d88b65cA18F31163F29D);
    
    receive() external payable {
        
    }
    
    function getOctiDecimals() public view returns(uint256){
        return ERC20(token).decimals();
    }
    
    function getOctiPriceForPool() external view returns(uint256){
        return octiPriceForPool;
    }
    
    function stake(uint amount) public {
        require(amount>0,'Stake amount too low');
        sendOctiDividends(msg.sender, address(this),amount);
        uint256 userStake = stakeOfUser[msg.sender];
        stakeOfUser[msg.sender] = userStake + amount;
        
        if(address(this).balance>0){
            octiPriceForPool = (token.balanceOf(address(this))/address(this).balance);
        }
        
        
        emit Stake(msg.sender,amount);
    } 

    function unstake(uint amount) public {
        require(stakeOfUser[msg.sender] >= amount,'Insufficient stake amount');
        uint price;
        if(address(this).balance>0){
            price = (token.balanceOf(address(this))/address(this).balance);
        }
        ERC20(token).transfer(msg.sender,amount);
        uint256 userStake = stakeOfUser[msg.sender];
        if(userStake == amount){
            stakeOfUser[msg.sender] = 0;
        }else{
            stakeOfUser[msg.sender] = userStake - amount;
        }
        
        if(address(this).balance>0 && price>0){
            uint bonus = amount/price;
            sendBNBDividends(msg.sender,bonus);
            octiPriceForPool = (token.balanceOf(address(this))/address(this).balance);
            if(earnOfUser[msg.sender] == 0){
                earnOfUser[msg.sender] = bonus;
            }else{
                earnOfUser[msg.sender] = earnOfUser[msg.sender] + bonus;
            }
        }
        
        emit Unstake(msg.sender,amount);
    } 
   
    
    function sendOctiDividends(address sender,address receiver,uint amount ) private {
             ERC20(token).transferFrom(sender,receiver, amount);
    }
    
    function sendBNBDividends(address receiver, uint256 amount) private {
        if (!address(uint160(receiver)).send(amount)) {
            return address(uint160(receiver)).transfer(address(this).balance);
        }
    }
    
    
    function deposit() external payable returns(uint) {
        return address(this).balance;
    }
    
    function withdraw() public {
        require(msg.sender == _owner, "Can not send without owner");
        msg.sender.transfer(address(this).balance);
    }
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }


    function getOctiBalance() public view returns(uint) {
        return token.balanceOf(address(this));
    }

    function withdrawOCTIToken(uint amount) public {
        require(msg.sender == _owner, "Can not send without owner");
        sendOctiDividends(address(this),msg.sender,amount);
    }
    
}