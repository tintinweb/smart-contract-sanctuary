/**
 *Submitted for verification at Etherscan.io on 2021-03-09
*/

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



pragma solidity >=0.6.0 <0.8.0;


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

// File: contracts/interface/ICoinVault.sol

pragma solidity ^0.6.12;

interface ICoinVault {
    function safeTokenTransfer(address _to, uint256 _amount) external;
}



pragma solidity >=0.6.0 <0.8.0;


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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


pragma solidity >=0.6.0 <0.8.0;

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




pragma solidity ^0.6.12;

contract InviteRelation is Ownable {
    using SafeMath for uint256;
    // 用户信息
    mapping(address => User) public userInfo;
    // 金库信息
    address public vault;
    // 权限判断
    mapping(address => bool) public authOf;
    // 代币 IERC20
    IERC20 public token;

    // 用户信息
    struct User {
        address superUser; // 上级
        uint256 inviteNum; // 邀请人数
        uint256 totalReward;
        uint256 reward;
    }

    constructor (IERC20 _token) public {
        token = _token;
    }

    // 设置 token
    function setToken(IERC20 _token) public onlyOwner {
        token = _token;
    }

    // 添加可操作金库的地址
    function addAuth(address _addr) public onlyOwner {
        require(_addr != address(0), "addr can not be 0");
        authOf[_addr] = true;
    }

    // 移除权限
    function removeAuth(address _addr) public onlyOwner {
        authOf[_addr] = false;
    }

    // 鉴权
    function auth() internal view {
        require(authOf[msg.sender] || msg.sender == owner(), "no auth");
    }

    // 设置金库地址
    function setVault(address _vault) public onlyOwner {
        require(_vault != address(0), "address can not be 0");
        vault = _vault;
    }

    //绑定关系
    function bind(address _superUser) public {
        require(msg.sender != address(0) || _superUser != address(0), "0x0 not allowed");
        require(userInfo[msg.sender].superUser == address(0), "already bind");
        require(msg.sender != _superUser, "do not bind yourself");
        //上级邀请人必须已绑定上级（创世地址除外）
        if (_superUser != address(this)) {
            require(userInfo[_superUser].superUser != address(0), "invalid inviter");
        }

        userInfo[msg.sender].superUser = _superUser;
        address parent = _superUser;
        // 给上级15代人数加1
        for (uint256 i = 0; i < 15; i++) {
            if (parent == address(0) || parent == address(this)) {
                break;
            }
            userInfo[parent].inviteNum = userInfo[parent].inviteNum.add(1);
            parent = userInfo[parent].superUser;
        }
    }

    //从激励池转出token给用户
    function sendReward(address _to, uint256 _amount) public {
        auth();
        require(vault != address(0), "address can not be 0");
        if (token.balanceOf(vault) == 0 || _amount == 0) {
            return;
        }
        if(_to == address(this)) {
            return;
        }
        if (token.balanceOf(vault) < _amount) {
            _amount = token.balanceOf(vault);
        }
        // 用户待领取数值
        userInfo[_to].reward = userInfo[_to].reward.add(_amount);
        // 累计邀请收益
        userInfo[_to].totalReward = userInfo[_to].totalReward.add(_amount);
    }

    // 领取奖励
    function harvest() public {
        uint256 pending = userInfo[msg.sender].reward;
        require(pending > 0, "none reward");
        require(vault != address(0), "address can not be 0");
        // 金库没钱了，直接不给领了
        if (token.balanceOf(vault) == 0) {
            return;
        }
        // 金库不足，将金库剩余资金发放
        if (token.balanceOf(vault) < pending) {
            pending = token.balanceOf(vault);
        }
        ICoinVault(vault).safeTokenTransfer(msg.sender, pending);
        userInfo[msg.sender].reward = 0;
    }

    // 获取金库余额
    function getVaultBalance() public view returns (uint256) {
        return token.balanceOf(vault);
    }

    // 获取上级
    function getSuperUser(address _addr) public view returns (address) {
        return userInfo[_addr].superUser;
    }

    // 获取用户信息
    function getUserInfo(address _addr) public view returns (
        address superUser,
        uint256 inviteNum,
        uint256 totalReward,
        uint256 reward
    ) {
        superUser = userInfo[_addr].superUser;
        inviteNum = userInfo[_addr].inviteNum;
        totalReward = userInfo[_addr].totalReward;
        reward = userInfo[_addr].reward;
        return (superUser, inviteNum, totalReward, reward);
    }
}