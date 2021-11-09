//SourceUnit: ComanagedAccount.sol

pragma solidity ^0.5.16;
pragma experimental ABIEncoderV2;

/*
    This contract is used for contractual payment co management of usdt.
    Payment can be successful only if the co manager reaches a certain weight.
*/


interface ITRC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
    constructor() internal {
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ComanagedAccountContract is Context, Ownable {
    using SafeMath for uint256;
    
    struct User {
        address account;
        uint256 allocPoint;
    }
    
    struct PayOrder {
        uint256 payID;
        address applicant;
        address recipient;
        uint256 amount;
        uint256 approvedPoint;
        uint256 disapprovedPoint;
        address[] votedList;
    }

    mapping(uint256 => PayOrder) payOrders;
    uint256[] public orderIDs;
    uint256 public totalAllocPoint;
    
    mapping(address => User) public users;
    
    uint256 public agreedThreshold;   // to agree the payorder, all approved user's approvedPoint must be greater than this value

    uint256 frozenAmount;
    uint256 incOrderID;  // ++
    address public USDTToken;
    
    
    constructor(address _USDTToken) public {
        USDTToken = _USDTToken;
    }
    
    function addUser(address account, uint256 allocPoint) public onlyOwner {
        require(account != address(0), "ComanagedAccountContract: User's address can't set to zero address");
        require(allocPoint > 0, "ComanagedAccountContract: The allocPoint must be greater than 0");
        require(users[account].account == address(0), "ComanagedAccountContract: The user account has been added to the contract");
        users[account] = User(account,allocPoint);
        totalAllocPoint += allocPoint;
    }
    
    function setAgreedThreshold(uint256 _agreedThreshold) public onlyOwner {
        agreedThreshold = _agreedThreshold;
    }
    
    function updateUserAllocPoint(address account, uint256 allocPoint) public onlyOwner {
        require(users[account].account != address(0), "ComanagedAccountContract: The user account is not in the contract");
        
        totalAllocPoint -= users[account].allocPoint;
        users[account].allocPoint = allocPoint;
        totalAllocPoint += allocPoint;
    }
    
    function transferUserAddress(address newAccount) public {
        require(newAccount != address(0), "ComanagedAccountContract: user can't set to zero address");
        require(users[msg.sender].account != address(0), "ComanagedAccountContract: The user account is not in the contract");
        require(users[newAccount].account == address(0), "ComanagedAccountContract: The user account has been added to the contract");       

        users[newAccount].account = newAccount;
        users[newAccount].allocPoint = users[msg.sender].allocPoint;
        delete(users[msg.sender]);
    }
    
    function applyPay(address recipient, uint256 amount) public returns(uint256 orderID){
        require(users[msg.sender].account != address(0), "ComanagedAccountContract: The caller is not in the contract");
        require(recipient != address(0), "ComanagedAccountContract: recipient can't set to zero address");
        require(ITRC20(USDTToken).balanceOf(address(this)) >= amount.add(frozenAmount), "ComanagedAccountContract: Insufficient balance");

        if(users[msg.sender].allocPoint >= agreedThreshold) {
            ITRC20(USDTToken).transfer(recipient, amount);
            orderID = 0;
        }else {
            incOrderID++;
            payOrders[incOrderID] = PayOrder(incOrderID,msg.sender,recipient,amount,users[msg.sender].allocPoint,0,new address[](0));
            payOrders[incOrderID].votedList.push(msg.sender);
            frozenAmount += amount;
            orderIDs.push(incOrderID);
            orderID = incOrderID;
        }
    }
    
    function approvePayment(uint256 orderID, bool decision) public {
        require(users[msg.sender].account != address(0), "ComanagedAccountContract: The caller is not in the contract");
        require(!isVoted(orderID,msg.sender), "ComanagedAccountContract: You have voted");
        require(payOrders[orderID].payID != 0, "ComanagedAccountContract: Invalid order ID");  
        
        if(decision) {
            if(users[msg.sender].allocPoint.add(payOrders[orderID].approvedPoint) >= agreedThreshold) {
                ITRC20(USDTToken).transfer(payOrders[orderID].recipient, payOrders[orderID].amount);
                frozenAmount -= payOrders[orderID].amount;
                delete(payOrders[orderID]);
                
                for (uint256 i = 0; i < orderIDs.length; i++) {
                    if(orderID == orderIDs[i]){
                        orderIDs[i] = orderIDs[orderIDs.length-1];
                        orderIDs.pop();
                    }
                }
            } else {
                payOrders[orderID].approvedPoint += users[msg.sender].allocPoint;
                payOrders[orderID].votedList.push(msg.sender);
            }
        } else {
            if(users[msg.sender].allocPoint.add(payOrders[orderID].disapprovedPoint) > totalAllocPoint.sub(agreedThreshold)) {
                frozenAmount -= payOrders[orderID].amount;
                delete(payOrders[orderID]);
                
                for (uint256 i = 0; i < orderIDs.length; i++) {
                    if(orderID == orderIDs[i]){
                        orderIDs[i] = orderIDs[orderIDs.length-1];
                        orderIDs.pop();
                    }
                }
            } else {
                payOrders[orderID].disapprovedPoint += users[msg.sender].allocPoint;
                payOrders[orderID].votedList.push(msg.sender);
            }
        }
        
    }
    
    function isVoted(uint256 orderID, address account) public view returns (bool) {
        for(uint256 i; i < payOrders[orderID].votedList.length; i++) {
            if(payOrders[orderID].votedList[i] == account ) {
                return true;
            }
        }
        return false;
    }
    
    function getOrder(uint256 orderID) public view returns (
        uint256 payID,
        address applicant,
        address recipient,
        uint256 amount,
        uint256 approvedPoint,
        uint256 disapprovedPoint        
        ) {

        payID = payOrders[orderID].payID;
        applicant = payOrders[orderID].applicant;
        recipient = payOrders[orderID].recipient;
        amount = payOrders[orderID].amount;
        approvedPoint = payOrders[orderID].approvedPoint;
        disapprovedPoint = payOrders[orderID].disapprovedPoint;
    }
}