// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IFarmUser.sol";
import "./interfaces/IAppData.sol";
import "./interfaces/IPancake.sol";
import "./libs/Initializable.sol";

import "./FarmHashrate.sol";
import "./Model.sol";

contract FarmUser is FarmHashrate, IFarmUser, Initializable, Ownable {
    using SafeERC20 for IERC20;

    // 邀请关系, useraddr -> inviterAddr
    mapping(address => address) inviteMap;
    // 邀请列表
    mapping(address => address[]) invitationMap;
    
    // 升级事件, useraddr -> old level -> new level -> deltaprice -> hashrate
    event UpgradeLevel(address, uint8, uint8, uint256, uint256);

    mapping(address => Model.User) public userMap;
    Model.User[] public allUsers;
    uint256 public userCount;

    address public usdtToken;
    uint8 public usdtDecimals;

    mapping(address => uint256) public levelHashrateMap;

    IAppData appData;
    IPancake pancake;

    // 初始化
    function init(IAppData _appData, IPancake _pancake) public onlyOwner {
        appData = _appData;
        pancake = _pancake;

        usdtToken = pancake.getUsdtToken();
        usdtDecimals = pancake.getUsdtDecimals();

        inviteMap[appData.getRootInviter()] = appData.getRootInviter();
        userMap[appData.getRootInviter()] = Model.User({
            addr: appData.getRootInviter(),
            inviterAddr: appData.getRootInviter(),
            levelNo: 0
        });
        allUsers.push(userMap[appData.getRootInviter()]);
        userCount = SafeMath.add(userCount, 1);

        initialized = true;
    }

    function getInviter() public override view returns(address) {
        return inviteMap[_msgSender()];
    }

    function getInviterUser(address userAddr) public view override returns(address, address, uint8) {
        Model.User memory user = userMap[inviteMap[userAddr]];
        return (user.addr, user.inviterAddr, user.levelNo);
    }

    function bindInviter(address inviterAddr) public override needInit {
        require(_msgSender() != inviterAddr, "Can not invite self");
        require(inviteMap[_msgSender()] == address(0), "Can only bind once.");
        require(inviteMap[inviterAddr] != address(0), "Inviter not exists.");

        inviteMap[_msgSender()] = inviterAddr;
        userMap[_msgSender()] = Model.User({
            addr: _msgSender(),
            inviterAddr: inviterAddr,
            levelNo: 0
        });
        allUsers.push(userMap[_msgSender()]);

        invitationMap[inviterAddr].push(_msgSender());
        userCount = SafeMath.add(userCount, 1);
    }

    // 升级级别
    function upgradeLevel(uint8 levelNo) public override needInit {
        Model.HashrateConf memory hc = appData.getHashrateConf(Model.CATEGORY_LEVEL);
        if (hc.invited == 1) {
            require(existUser(_msgSender()), "user not exists");
        }

        Model.Level memory newLevel = appData.getLevel(levelNo);
        require(newLevel.levelNo > 0, "can not found level.");

        Model.User storage user = userMap[_msgSender()];
        Model.Level memory currentLevel = appData.getLevel(user.levelNo);

        uint256 deltaAmount = SafeMath.sub(newLevel.price, currentLevel.price);
        require(deltaAmount > 0, "delta price must great than 0");

        uint256 usdtBalance = IERC20(usdtToken).balanceOf(user.addr);
        uint256 allowanceBalance = IERC20(usdtToken).allowance(user.addr, address(this));
        require(usdtBalance >= deltaAmount && allowanceBalance >= deltaAmount, "balance or allowance insufficient");

        uint256 hashrate = SafeMath.div(SafeMath.mul(deltaAmount, appData.getLevelMultiple()), 100 * (10 ** usdtDecimals));
        levelHashrateMap[user.addr] = SafeMath.add(levelHashrateMap[user.addr], hashrate);
        totalHashrate = SafeMath.add(totalHashrate, hashrate);

        uint256 totalUsdtCommision = 0;
        Model.User storage genUser = userMap[inviteMap[user.addr]];

        // USDT及算力返佣
        for (uint8 gen = 1; gen <= 20; gen++) {
            if (genUser.addr == appData.getRootInviter()) {
                break;
            }

            uint256 commissionRate = appData.getLevelCommissionRate(genUser.levelNo, gen);
            if (commissionRate == 0) {
                continue;
            }

            // USDT返佣
            if (genUser.levelNo > 0 && hc.usdtRebate == 1) {
                uint256 usdtCommission = SafeMath.div(SafeMath.mul(deltaAmount, commissionRate), 100);  
                IERC20(usdtToken).safeTransferFrom(user.addr, genUser.addr, usdtCommission);      
                totalUsdtCommision = SafeMath.add(totalUsdtCommision, usdtCommission);    
            }

            // 算力返佣
            if (hc.rebate == 1) {
                uint256 hashrateCommission = SafeMath.div(SafeMath.mul(deltaAmount, commissionRate), 100 * (10 ** usdtDecimals)); 
                if (hashrateCommission == 0)  {
                    genUser = userMap[genUser.inviterAddr];
                    continue;
                }

                levelHashrateMap[genUser.addr] = SafeMath.add(levelHashrateMap[genUser.addr], hashrateCommission);
                userHashrateRecords[genUser.addr].push(Model.HashrateRecord({
                    category: Model.CATEGORY_LEVEL,
                    blockNumber: block.number,
                    timestamp: block.timestamp,
                    totalHashrate: levelHashrateMap[genUser.addr]
                }));
                totalHashrate = SafeMath.add(totalHashrate, hashrateCommission);
            }
            
            genUser = userMap[genUser.inviterAddr];
        }

        // 记录算力
        userHashrateRecords[user.addr].push(Model.HashrateRecord({
            category:Model. CATEGORY_LEVEL,
            blockNumber: block.number,
            timestamp: block.timestamp,
            totalHashrate: levelHashrateMap[user.addr]
        }));
        totalHashrateRecords.push(Model.HashrateRecord({
            category: Model.CATEGORY_LEVEL,
            blockNumber: block.number,
            timestamp: block.timestamp,
            totalHashrate: totalHashrate
        }));

        IERC20(usdtToken).safeTransferFrom(user.addr, appData.getCoolAddr(), SafeMath.sub(deltaAmount, totalUsdtCommision));
        user.levelNo = newLevel.levelNo;

        emit UpgradeLevel(user.addr, user.levelNo, newLevel.levelNo, deltaAmount, hashrate);
    }

    function getUserInfo() public view override returns(address, address, uint8) {
        return getUserByAddr(_msgSender());
    }

    function getUserByAddr(address userAddr) public override view returns(address, address, uint8) {
        return (userMap[userAddr].addr, userMap[userAddr].inviterAddr, userMap[userAddr].levelNo);
    }

    function genCommission(Model.User storage genUser, uint8 gen, uint256 baseAmount) private view returns(uint256) {
        uint256 commissionRate = appData.getLevelCommissionRate(genUser.levelNo, gen);
        if (genUser.levelNo == 0 || commissionRate == 0) {
            return 0;               
        }

        return SafeMath.div(SafeMath.mul(baseAmount, commissionRate), 100);     
    }

    function existUser(address userAddr) public override view returns(bool) {
        return userMap[userAddr].addr == userAddr && userAddr != address(0);
    }

    function setUserLevel(address userAddr, uint8 levelNo) public onlyOwner {
        Model.Level memory level = appData.getLevel(levelNo);
        userMap[userAddr].levelNo = level.levelNo;
        levelHashrateMap[userAddr] = level.price;
    }

    function importUser(address userAddr, uint8 levelNo, address inviterAddr) public onlyOwner {
        Model.Level memory level = appData.getLevel(levelNo);
        inviteMap[userAddr] = inviterAddr;
        userMap[userAddr] = Model.User({
            addr: userAddr,
            inviterAddr: inviterAddr,
            levelNo: level.levelNo
        });
        levelHashrateMap[userAddr] = level.price;
        invitationMap[inviterAddr].push(userAddr);
        totalHashrate = SafeMath.add(totalHashrate, levelHashrateMap[userAddr]);

        // 记录算力
        userHashrateRecords[userAddr].push(Model.HashrateRecord({
            category:Model. CATEGORY_LEVEL,
            blockNumber: block.number,
            timestamp: block.timestamp,
            totalHashrate: levelHashrateMap[userAddr]
        }));
        totalHashrateRecords.push(Model.HashrateRecord({
            category: Model.CATEGORY_LEVEL,
            blockNumber: block.number,
            timestamp: block.timestamp,
            totalHashrate: totalHashrate
        }));
    }
 
    function invitation() public view returns(address[] memory) {
        return invitation(_msgSender());
    }

    function invitation(address inviterAddr) public view returns(address[] memory) {
        return invitationMap[inviterAddr];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IFarmHashrate.sol";

interface IFarmUser is IFarmHashrate {
    function getInviter() external view returns(address);
    function getInviterUser(address userAddr) external view returns(address, address, uint8);
    function bindInviter(address inviterAddr) external;
    function upgradeLevel(uint8 levelNo) external;
    function getUserInfo() external view returns(address, address, uint8);
    function getUserByAddr(address userAddr) external view returns(address, address, uint8);
    function existUser(address userAddr) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Model.sol";

interface IAppData {
    function validPair(address token0, address token1) external view returns(bool);    
    function getScaleMultiple(uint8 scaleType) external view returns(uint256);
    function getLevelCommissionRate(uint8 levelNo, uint8 gen) external view returns(uint256);
    function getLevel(uint8 levelNo) external view returns(Model.Level memory);
    function getLevelMultiple() external view returns(uint256);
    function getCoolAddr() external view returns(address);
    function getRootInviter() external view returns(address);
    function getLPMultiple() external view returns(uint256);
    function getRewardAddr() external view returns(address);
    function getHashrateConf(uint8 category) external view returns(Model.HashrateConf memory);
    function getQuoteDiscount() external view returns(uint256);
    function getRewardBlockCount() external view returns(uint256);
    function getBurnAddr() external view returns(address);
    function getBurnRate() external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPancake {
    function getUsdtDecimals() external view returns (uint8);
    function getUsdtToken() external view returns (address);
    function getQuoteToken() external view returns (address);
    function getPriceBaseUsdt(address token) external view returns (uint256);
    function getUsdtLPToken() external view returns (address);
    function getLPToken(address token0, address token1) external view returns (address);
    function getUsdtLPTokenAmounts() external view returns(uint112, uint112);
    function getUsdtLPTokenAmounts(uint256 liqidity) external view returns(uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// 可被主合约调用的
abstract contract Initializable {
    // 是否已初始化
    bool public initialized = false;

    modifier needInit() {
        require(initialized, "Contract not init.");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./interfaces/IFarmHashrate.sol";
import "./Model.sol";

abstract contract FarmHashrate is IFarmHashrate {

    // 最新全网算力
    uint256 public totalHashrate = 0;

    // 个人算力历史记录 useraddr -> record
    mapping(address => Model.HashrateRecord[]) public userHashrateRecords;

    // 全网算力历史记录
    Model.HashrateRecord[] public totalHashrateRecords;

    function getTotalHashrate() public view override returns(uint256) {
        return totalHashrate;
    }

    function getTotalHashrateRecords() public view override returns(Model.HashrateRecord[] memory) {
        return totalHashrateRecords;
    }

    function getUserHashrate(address userAddr) public view override returns(uint256, uint256) {
        Model.HashrateRecord[] storage records = userHashrateRecords[userAddr];
        if (records.length == 0) {
            return (0, 0);
        }

        return (records[records.length - 1].totalHashrate, records[records.length - 1].blockNumber);
    }

    function getUserHashrateRecords(address userAddr) public view override returns(Model.HashrateRecord[] memory) {
        return userHashrateRecords[userAddr];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Model {

    uint8 constant CATEGORY_LEVEL = 1;
    uint8 constant CATEGORY_LP = 2;
    uint8 constant CATEGORY_PAIR = 3;

    uint8 constant SCALE_TYPE_UNKNOWN = 0;
    uint8 constant SCALE_TYPE_82 = 1;
    uint8 constant SCALE_TYPE_73 = 2;
    uint8 constant SCALE_TYPE_55 = 3;
    uint8 constant SCALE_TYPE_100 = 4;

    struct User {
        address addr;
        address inviterAddr;
        uint8 levelNo;
    }

    // 级别
    struct Level  {
        string name; // 名称
        uint8 levelNo; // 级别号
        uint8 commissionGen; // 佣金代数
        uint256 price; // 需要的usdt数量
    }

    struct HashrateConf {
        uint256 baseAmount; // 基数
        uint256 minTotalHashrate; // 全网最小算力
        uint256 maxTotalHashrate; // 全网最大算力, 超过最高算力后代币产值减半
        uint256 maxReward; // 全网最大奖励
        uint8 rebate; // 算力返佣, 0=不返佣, 1=返佣
        uint8 usdtRebate; // usdt返佣, 0=不返佣, 1=返佣
        uint8 invited; // 是否需要绑定邀请关系, 0=不需要, 1=需要
    }

    // 算力记录
    struct HashrateRecord {
        uint8 category; // 0=all, 1=level, 2=lp, 3=pair
        uint256 blockNumber;
        uint256 timestamp;
        uint256 totalHashrate;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../Model.sol";

interface IFarmHashrate {
    function getTotalHashrate() external view returns(uint256);
    function getTotalHashrateRecords() external view returns(Model.HashrateRecord[] memory);
    function getUserHashrate(address userAddr) external view returns(uint256, uint256);
    function getUserHashrateRecords(address userAddr) external view returns(Model.HashrateRecord[] memory);
}