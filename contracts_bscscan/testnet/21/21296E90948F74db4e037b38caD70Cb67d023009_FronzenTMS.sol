/**
 *Submitted for verification at BscScan.com on 2021-12-24
*/

pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;

interface IBEP20 {
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract FronzenTMS is Context, Ownable {
    using SafeMath for uint256;

    uint256 constant ONEYEAR = 10512000;
    uint256 constant TENTHOUSANDTH = 10000;

    struct User {
        address currentAddress;
        uint256 frozenAmount;
        address historyAddress;
    }
    User[] users;

    uint256 public unfreezeBlock;  // Unfreeze the remaining amount until the height of this block is reached
    address public TMSToken;
    
    constructor(address _TMSToken) public {
        TMSToken = _TMSToken;
    }

    /**
     * @dev Start freezing TMS and release it for the first time
     * `rate` need divide by `_tenThousandth`
     * set unfreeze block number. 
     */
    function startFreeze(uint256 rate) public onlyOwner {
        require(unfreezeBlock == 0, "FronzenTMS: you have already done");
        require(rate <= TENTHOUSANDTH, "FronzenTMS: rate invalid");
        require(IBEP20(TMSToken).balanceOf(address(this)) >= getUserFreezeAmountTotal(), "FronzenTMS: freeze amount exceeds allowance");
        
        if (rate > 0) {
            for (uint256 i = 0; i < users.length; i++) {
                User memory user = users[i];
                uint256 releaseAmount = user.frozenAmount.mul(rate).div(TENTHOUSANDTH);
                release(users[i], releaseAmount);
            }
        }
        unfreezeBlock = block.number.add(ONEYEAR);
    }

    /**
     * @dev add user address and amount
     */
    function addUser(address user, uint256 amount) public onlyOwner {
        require(unfreezeBlock == 0, "FronzenTMS: The contract has been frozen and started, no more user data can be added");
        require(user != address(0), "FronzenTMS: Can't set  the zero address");
        
        for (uint256 i = 0; i < users.length; i++) {
            if(user == users[i].currentAddress){
                users[i].frozenAmount += amount;
                return;
            }
        }
        
        users.push(User(user, amount, address(0)));
    }
    
    /**
     * @dev update user's frozenAmount
     */
    function updateUserAmount(address user, uint256 newAmount) public onlyOwner returns(bool){
        require(unfreezeBlock == 0, "FronzenTMS: The contract has been frozen and started, can't update user's amount");
        require(user != address(0), "FronzenTMS: Can't set  the zero address");        

        for (uint256 i = 0; i < users.length; i++) {
            if(user == users[i].currentAddress){
                users[i].frozenAmount = newAmount;
                return true;
            }
        }
        
        return false;
    }

    /**
     * @dev delete user
     */
    function deleteUser(address user) public onlyOwner returns(bool){
        require(unfreezeBlock == 0, "FronzenTMS: The contract has been frozen and started, can't delete user");
        require(user != address(0), "FronzenTMS: Can't set  the zero address");        

        for (uint256 i = 0; i < users.length; i++) {
            if(user == users[i].currentAddress){
                users[i] = users[users.length-1];
                users.pop();
                return true;
            }
        }
        
        return false;
    }


    /**
     * @dev change old address msg.sender to a new address (`newAddress`).
     */
    function changeUserAddress(address newUserAddress) public {
        require(newUserAddress != address(0), "FronzenTMS: Can't set  the zero address");  
        
        _changeUserAddress(msg.sender,newUserAddress);
    }

    /**
     * @dev change old account (`oldUserAddress`) to a new account (`newUserAddress`).
     */
    function changeUserAddress(address oldUserAddress, address newUserAddress)
        public
        onlyOwner
    {
        require(newUserAddress != address(0), "FronzenTMS: Can't set  the zero address"); 
        
        _changeUserAddress(oldUserAddress,newUserAddress);
    }
    
    /**
     * @dev anyone can claim
     */
    function claimAll() public {
        require(block.number >= unfreezeBlock && unfreezeBlock != 0, "FronzenTMS: claim not yet time");
        
        for (uint256 i = 0; i < users.length; i++) {
            release(users[i], users[i].frozenAmount);
        }
    }
    
    function getUserList(uint256 page) public view returns (User[20] memory userList, uint256 lastPage) {
        uint256 i = page.sub(1).mul(20);
        lastPage = users.length.div(20).add(1);
        
        if(page > 0 && users.length > 0) {
            uint256 ii;
            for(i ; i < users.length; i++) {
                userList[ii] = users[i];
                ii++;
                if(ii >= 20) {
                    break;
                }
            }
        }
    }
    
    function release(User storage user, uint256 amount) internal {
        IBEP20(TMSToken).transfer(user.currentAddress,amount);
        user.frozenAmount -= amount;
    }

    function _changeUserAddress(address oldUserAddress, address newUserAddress)
        internal
    {
        for(uint256 i = 0; i < users.length; i++) {
            User memory user = users[i];
            if(user.currentAddress == oldUserAddress) {
                users[i] = User(newUserAddress, user.frozenAmount, oldUserAddress);
                break;
            }
        }
    }
    
    function getUser(address user) public view returns(address currentAddress,uint256 frozenAmount,address historyAddress) {
        require(user != address(0),"address invalid");
        for(uint256 i; i < users.length; i++) {
            if(users[i].currentAddress == user) {
                currentAddress = users[i].currentAddress;
                frozenAmount = users[i].frozenAmount;
                historyAddress = users[i].historyAddress;
                break;
            }
        }
    }
    
    function getUserFreezeTotal() public view returns(uint256 userTotal,uint256 frozenAmountTotal) {
        userTotal = users.length;
        frozenAmountTotal = getUserFreezeAmountTotal();
    }
    
    function getUserFreezeAmountTotal() internal view returns(uint256 total) {
        for(uint256 i; i < users.length; i++) {
            total = total.add(users[i].frozenAmount);
        }
    }
}