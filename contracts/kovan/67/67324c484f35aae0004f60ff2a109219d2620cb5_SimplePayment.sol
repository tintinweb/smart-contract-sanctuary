/**
 *Submitted for verification at Etherscan.io on 2021-09-16
*/

pragma solidity ^0.8.0;

contract SimplePayment {
    using SafeMath for uint256;

    address public owner;
    mapping (address => uint256) private balances;
    
    address recipient = 0x7eBA52e195245B71c0DC9246d70EFF4ddd11D946;
    
    struct Product {
        string id;
        string name;
        string description;
        string imageUrl;
        uint256 price;
    }
    Product[] private products;
    
    struct Order {
        string no;
        uint256 totalPrice;
        uint256 totalETH;
        uint256 dateTime;
    }
    mapping (address => Order[]) private orders;
    
    // Events - publicize actions to external listeners
    
    event PurchaseMade(address accountAddress, string no);
     
    constructor() { 
        owner = msg.sender; 
    }
    
    function addProduct(string memory id, string memory name, string memory description, string memory imageUrl, uint256 price)
    public {
        Product memory product = Product(id, name, description, imageUrl, price);
        products.push(product);
    }
    
    function getAllProduct()
    public view returns (Product[] memory) {
        return products;
    }
    
    function purchase(string memory no, uint256 total)
    public payable {
        Order memory order = Order(no, total, msg.value, block.timestamp);
        orders[msg.sender].push(order);
        
        //  Add balances
        balances[recipient] = balances[recipient].add(msg.value);
        
        //  Transfer
        payable(recipient).transfer(msg.value);
        
        //  Emit event
        emit PurchaseMade(msg.sender, no);
    }
    
    function getAllOrder(address userAddress)
    public view returns (Order[] memory) {
        return orders[userAddress];
    }
    
    
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}