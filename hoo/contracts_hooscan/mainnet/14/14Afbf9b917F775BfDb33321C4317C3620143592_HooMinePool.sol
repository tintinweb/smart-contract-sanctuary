/**
 *Submitted for verification at hooscan.com on 2021-08-30
*/

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: SimPL-2.0

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
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

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
    function allowance(address owner, address spender)
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

interface IController {
    function withdraw(address, uint256) external;

    function balanceOf(address) external view returns (uint256);

    function earn(address, uint256) external;

    function hasStrategy(address) external view returns (bool);
}

abstract contract ContractOwner {
    address public contractOwner = msg.sender;

    modifier ContractOwnerOnly() {
        require(msg.sender == contractOwner, "contract owner only");
        _;
    }
}

contract Manager is ContractOwner {
    mapping(string => address) public members;

    mapping(address => mapping(string => bool)) public userPermits;

    function setMember(string memory name, address member)
        external
        ContractOwnerOnly
    {
        members[name] = member;
    }

    function setUserPermit(
        address user,
        string memory permit,
        bool enable
    ) external ContractOwnerOnly {
        userPermits[user][permit] = enable;
    }

    function getTimestamp() external view returns (uint256) {
        return block.timestamp;
    }
}

abstract contract Member is ContractOwner {
    modifier CheckPermit(string memory permit) {
        require(manager.userPermits(msg.sender, permit), "no permit");
        _;
    }

    Manager public manager;

    function setManager(address addr) external ContractOwnerOnly {
        manager = Manager(addr);
    }

    mapping(address => bool) public blackList;
    modifier validUser(address addr) {
        require(blackList[addr] == false, "user is in blacklist");
        _;
    }

    function addBlackList(address addr, bool res) external ContractOwnerOnly {
        blackList[addr] = res;
    }
}

contract HooMinePool is Member {
    using SafeMath for uint256;

    mapping(address => address) public controllers;

    struct PoolInfo {
        address token;
        uint256 totalAmount;
    }
    PoolInfo[] public poolInfos;
    mapping(address => uint256) public LpOfPid;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
    }
    mapping(uint256 => mapping(address => UserInfo)) public userInfos;

    function add(address _token) public CheckPermit("Config") {
        poolInfos.push(PoolInfo({token: _token, totalAmount: 0}));
        LpOfPid[_token] = poolInfos.length - 1;
    }

    function setController(address token, address controller)
        external
        CheckPermit("Config")
    {
        controllers[token] = controller;
    }

    function getPools() public view returns (PoolInfo[] memory) {
        PoolInfo[] memory pools = new PoolInfo[](poolInfos.length);

        for (uint256 i = 0; i < poolInfos.length; i++) {
            pools[i] = poolInfos[i];
        }
        return pools;
    }

    function getUserInfos(address owner)
        public
        view
        returns (UserInfo[] memory)
    {
        UserInfo[] memory infos = new UserInfo[](poolInfos.length);

        for (uint256 i = 0; i < poolInfos.length; i++) {
            UserInfo storage user = userInfos[i][owner];
            infos[i] = UserInfo({amount: user.amount});
        }

        return infos;
    }

    function withdraw(address token, uint256 amount) external payable {
        uint256 pid = _getPid(token);

        PoolInfo storage pool = poolInfos[pid];
        pool.totalAmount = pool.totalAmount.sub(amount);

        UserInfo storage user = userInfos[pid][msg.sender];
        user.amount = user.amount.sub(amount);

        _withdrawController(token, amount);

        if (token == address(0)) {
            address payable owner = msg.sender;
            owner.transfer(amount);
        } else {
            require(
                IERC20(token).transfer(msg.sender, amount),
                "transfer money failed"
            );
        }
    }

    function deposit(address token, uint256 amount) external payable {
        if (token == address(0)) {
            require(msg.value == amount, "invalid money amount");
        } else {
            require(
                IERC20(token).transferFrom(
                    msg.sender,
                    address(this),
                    uint256(amount)
                ),
                "transfer money failed"
            );
        }
        uint256 pid = _getPid(token);

        PoolInfo storage pool = poolInfos[pid];
        pool.totalAmount = pool.totalAmount.add(amount);

        UserInfo storage user = userInfos[pid][msg.sender];
        user.amount = user.amount.add(amount);

        earn(token);
    }

    function _getPid(address token) internal view returns (uint256) {
        uint256 pid = LpOfPid[token];

        PoolInfo storage pool = poolInfos[pid];
        require(pool.token == token, "token invalid");
        return pid;
    }

    function available(address token) public view returns (uint256) {
        if (token == address(0)) {
            return address(this).balance;
        } else {
            return IERC20(token).balanceOf(address(this));
        }
    }

    function earn(address token) public {
        address controller = controllers[token];

        if (controller == address(0)) {
            return;
        }
        if (IController(controller).hasStrategy(token)) {
            uint256 _bal = available(token);
            if (token == address(0)) {
                if (_bal > 0) {
                    address payable sender = payable(controller);
                    sender.transfer(_bal);
                }
            } else {
                IERC20(token).transfer(controller, _bal);
            }
            IController(controller).earn(address(token), _bal);
        }
    }

    function _withdrawController(address token, uint256 amount) internal {
        address controller = controllers[token];
        if (controller == address(0)) {
            return;
        }
        if (IController(controller).hasStrategy(token)) {
            if (token != address(0)) {
                uint256 b = IERC20(token).balanceOf(address(this));
                if (b < amount) {
                    uint256 _amount = amount.sub(b);
                    IController(controller).withdraw(token, _amount);
                }
            } else {
                uint256 b = address(this).balance;
                if (b < amount) {
                    uint256 _amount = amount.sub(b);
                    IController(controller).withdraw(token, _amount);
                }
            }
        }
    }

    receive() external payable {}
}