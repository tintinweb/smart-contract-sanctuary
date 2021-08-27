/**
 *Submitted for verification at Etherscan.io on 2021-08-27
*/

// File: @openzeppelin/contracts/utils/Context.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// File: @openzeppelin/contracts/access/Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// File: contracts/DunkVestingNew.sol

pragma solidity ^0.6.0;



interface IERC20 {

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract DunkVestingNew is Ownable {

    using SafeMath for uint;

    struct user {
        uint256 categoryIndex;
        string category;
        uint256 lockableAmount;
        bool isLocked;
        uint256 unlockedAmount;
        uint256 unlockedQuarters;
    }

    IERC20 public token;
    
    address[3] public addresses;

    uint256[8] public quarters;
    
    mapping (uint256 => mapping(uint256 => uint256)) public distributions;

    mapping (address => user) users;

    event Unlocked(address indexed to, uint256 value);

    constructor() public {
        
        string [3] memory categories = ["EARLY CONTRIBUTOR", "PRIVATE SALES", "TEAM ADVISOR"];

        //addresses = [0xC605ec0e73d8C417aF5e0bc612803E43A25f806b, 0x0E01469Cd57113AC853d7C10b112760d370c8676, 0x3c7DfF80805Ea2656E015Abbf6D4c55B87fB8C2E];
        addresses = [0xFF5Bf2307980530a477efaE5c0660A84241ebc16, 0xAE7CF01cF6fAd034b041131517d1AB0b79E98287, 0x55e4dcADb041CAF3d9B5A396739557CbE79E1F30];
        
        for (uint i = 0; i < addresses.length; i++) {
            
            users[addresses[i]].categoryIndex = i;

            users[addresses[i]].category = categories[i];
        }
        
        //users[addresses[0]].lockableAmount = 5_000_000_000_000_000_000_000_000;
        users[addresses[0]].lockableAmount = 5_000_000_000_000_000_000_000;
                
        //users[addresses[1]].lockableAmount = 12_000_000_000_000_000_000_000_000;
        users[addresses[1]].lockableAmount = 12_000_000_000_000_000_000_000;
        
        //users[addresses[2]].lockableAmount = 10_000_000_000_000_000_000_000_000;
        users[addresses[2]].lockableAmount = 10_000_000_000_000_000_000_000;
    }

    function init(address tokenAddress) public onlyOwner {
        
        token = IERC20(tokenAddress);
        initQuarters();
        initDistributions();
    }

    function initQuarters() internal {
        uint256 startTime = now;
        
        //uint256 quarterOfYear = 91 days;
        uint256 quarterOfYear = 10 minutes;

        //quarters[0] = startTime + 7 days;
        quarters[0] = startTime + 5 minutes;
        
        for (uint256 i = 1; i < 8; i++) {
            
            //quarters[i] = startTime + quarterOfYear*i + i.div(4).mul(1 days);
            quarters[i] = startTime + quarterOfYear*i + i.div(4).mul(1 minutes);
        }
    }

    function initDistributions() internal {
        
        distributions[0][0] = distributions[1][0] = 10;
        
        distributions[0][1] = distributions[1][1] = 0;
        
        for (uint256 j = 2; j < 8; j++) {
            
            distributions[0][j] = distributions[1][j] = 15;
        }
        
        for (uint256 k = 0; k < 8; k++) {
            
            distributions[2][k] = k.div(4).mul(25);
        }
    }
    
    function getAddress (address addr) public view returns (uint256, string memory, bool, uint256, uint256) {
        
        return (users[addr].categoryIndex, users[addr].category, users[addr].isLocked, users[addr].unlockedAmount, users[addr].unlockedQuarters);
    }

    function lock() public onlyOwner {

        uint256 totalLockableAmount = 0;

        for (uint8 i = 0 ; i < addresses.length; i++) {
            
            totalLockableAmount = totalLockableAmount.add(users[addresses[i]].lockableAmount);
        }

        uint256 allowance = token.allowance(msg.sender, address(this));
        
        require(allowance >= totalLockableAmount, "check the token allowance to contract");

        token.transferFrom(msg.sender, address(this), totalLockableAmount);

        for (uint8 i = 0; i < addresses.length; i++) {
            
            require(users[addresses[i]].isLocked == false, "already locked for given address");
        
            users[addresses[i]].isLocked = true;
        }
    }

    function getUnlockablePercent (uint256 categoryIndex, address addr) public view returns (uint256, uint256) {
        
        uint256 allowedPercent;

        uint256 unlockableQuarters = users[addr].unlockedQuarters;

        for (uint8 i = 0; i < quarters.length; i++) {
            
            if (users[addr].isLocked == true && users[addr].categoryIndex == categoryIndex && now >= quarters[i] && users[addr].unlockedQuarters <= i ) {
                
                allowedPercent += distributions[categoryIndex][i];
                
                unlockableQuarters = unlockableQuarters.add(1);
            }
        }

        return (allowedPercent, unlockableQuarters);
    }

    function unlock() public {
        
        require(users[msg.sender].isLocked == true, "not locked any amount");

        (uint256 availablePercent, uint unlockableQuarters) = getUnlockablePercent(users[msg.sender].categoryIndex, msg.sender);
        
        uint256 payableAmount = users[msg.sender].lockableAmount.mul(availablePercent).div(100);

        require(payableAmount > 0, "zero amount to unlock");

        users[msg.sender].unlockedAmount = users[msg.sender].unlockedAmount.add(payableAmount);

        users[msg.sender].unlockedQuarters = unlockableQuarters;
        
        token.transfer(msg.sender, payableAmount);

        emit Unlocked(msg.sender, payableAmount);
    }

    function returnTokens(address _tokenAddr, address _to, uint _amount) public onlyOwner {
        
        IERC20(_tokenAddr).transfer(_to, _amount);
    }
}