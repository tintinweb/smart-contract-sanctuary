/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

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
    
    function mint(address to, uint256 amount) external;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

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

contract vEmpireGame is Ownable {
    using SafeMath for uint256;
    
    struct BattleInfo {
        address player1;
        address player2;
        uint256 poolAmount;
        uint256 riskPercent;
        uint256 roomId;
        address winnerAddress;
    }
    
    struct UserInfo {
        address player2;
        uint256 roomId;
        bool xVempLockStatus;
    }
    
    // Info of each Battle
    mapping (uint256 => BattleInfo) public battleInfo;
    
    // Info of each user that participate in Battle.
    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    
    // xVemp token address
    address public xVemp;
    
    // ddao ddaoPercent
    uint256 public daoPercent;
    
    // min xVemp tokens to participate into the pool
    uint256 public minBattleTokens = 0;
    
    // Admin list
    mapping (address => bool) public adminStatus;
    
    // losers List for lottery airdrop rewards
    address[] public losers;
    
    mapping(uint256 => address) public loser;
        
    constructor(address _xVemp, uint256 _ddaoPercent) public {
        xVemp = _xVemp;
        daoPercent = _ddaoPercent;
    }
    
    modifier onlyAdmin() {
        require(adminStatus[_msgSender()], "Caller is not admin");
        _;
    }
    
    function battleLockTokens(uint256 _poolAmount, uint256 _riskPercent, uint256 _roomId) external {
        require(_poolAmount != 0 || _riskPercent != 0 || _roomId != 0, "Inalid data");
        require(_poolAmount >= minBattleTokens, "pool amount can not less than min battle tokens");
        
        BattleInfo storage battle = battleInfo[_roomId];
        UserInfo storage user = userInfo[_roomId][msg.sender];
        
        if(battle.player1 != address(0)) {
            require(battle.roomId == _roomId, "Invalid room id data");
            UserInfo storage user2 = userInfo[_roomId][battle.player1];
            battle.player2 = msg.sender;
            user2.player2 = msg.sender;
            user.player2 = battle.player1;
            user.roomId = _roomId;
            user.xVempLockStatus = false;
        } else {
            battle.player1 = msg.sender;
            battle.player2 = address(0);
            battle.poolAmount = _poolAmount;
            battle.riskPercent = _riskPercent;
            battle.roomId = _roomId;
            battle.winnerAddress = address(0);
            
            user.player2 = address(0);
            user.roomId = _roomId;
            user.xVempLockStatus = false;
        }
        
        if(!user.xVempLockStatus) {
            IERC20(xVemp).transferFrom(msg.sender, address(this), _poolAmount);
            user.xVempLockStatus = true;
        }
    }
    
    function updateWinnerAddress(address _winnerAddress, uint256 _roomId) public onlyAdmin {
        BattleInfo storage battle = battleInfo[_roomId];
        UserInfo storage user1 = userInfo[_roomId][battle.player1];
        UserInfo storage user2 = userInfo[_roomId][battle.player2];
        
        require(_winnerAddress != address(0) || _winnerAddress != battle.player1 || _winnerAddress != battle.player2, "Invalid Winner Address");
        require(battle.player1 != address(0) && battle.player2 != address(0), "Invalid players");
        require(user1.xVempLockStatus != false && user2.xVempLockStatus != false, "Invalid users lock status");
        battle.winnerAddress = _winnerAddress;
        
        address _loser = _winnerAddress == battle.player1 ? battle.player2 : battle.player1;
        losers.push(_loser);
        loser[_roomId] = _loser;
    }
    
    function claimBattleRewards(uint256 _roomId) public {
        BattleInfo storage battle = battleInfo[_roomId];
        UserInfo storage user = userInfo[_roomId][msg.sender];
        
        require(battle.player1 != address(0) && battle.player2 != address(0), "Invalid players address");
        require(battle.winnerAddress != address(0), "Battle result in pending");
        require(battle.winnerAddress == _msgSender(), "Only winner can call this method");
        require(user.xVempLockStatus != false, "Invalid users lock status");
        
        uint256 winnerShare = 100;
        IERC20(xVemp).transfer(msg.sender, battle.poolAmount.mul(2).mul(winnerShare.sub(daoPercent)).div(100));
    }
    
    function updateAdmin(address _admin, bool _status) public onlyOwner {
        require(adminStatus[_admin] != _status, "Already in same status");
        adminStatus[_admin] = _status;
    }
    
    function updateMinBattleTokens(uint256 _minBattleTokens) public onlyOwner {
        minBattleTokens = _minBattleTokens;
    }
    
    // Safe xVemp transfer function to admin.
    function emergencyWithdrawxVempTokens(address _to, uint256 _amount) public onlyOwner {
        uint256 vempBal = IERC20(xVemp).balanceOf(address(this));
        require(vempBal >= _amount, "Insufficiently amount");
        IERC20(xVemp).transfer(_to, _amount);
    }
}