// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

abstract contract IMasterMex is Ownable, ReentrancyGuard {
    enum GroupType { Up, Down }

    struct UserInfo {
        uint256 amount;                 // Deposit amount of user
        uint256 profitDebt;             // Profit Debt amount of user
        uint256 lossDebt;               // Loss Debt amount of user
        GroupType voteGroup;            // Group where the user bets
    }

    struct GroupInfo {
        uint256 deposit;                // Deposited ETH amount into the group
        uint256 holding;                // Currently holding ETH amount
        uint256 shareProfitPerETH;
        uint256 shareLossPerETH;
    }

    struct PoolInfo {
        address tokenPair;
        uint256 prevReserved;
        uint256 maxChangeRatio;
        uint256 minFund;
    }

    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 public decimals = 12;
    address payable STAKING_VAULT;
    address payable TREASURY_VAULT;
    address payable BUYBACK_VAULT;
    uint256 public STAKING_FEE;
    uint256 public TREASURY_FEE;
    uint256 public BUYBACK_FEE;

    PoolInfo[] public poolInfo;
    mapping(address => UserInfo) public pendingUserInfo;
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(uint256 => mapping(GroupType => GroupInfo)) public groupInfo;
}

// SPDX-License-Identifier: MIT
/**
 *  DexMex Prediction Pool
 * 

           ,-.
       ,--' ~.).
     ,'         `.
    ; (((__   __)))
    ;  ( (#) ( (#)
    |   \_/___\_/|
   ,"  ,-'    `__".
  (   ( ._   ____`.)--._        _
   `._ `-.`-' \(`-'  _  `-. _,-' `-/`.
    ,')   `.`._))  ,' `.   `.  ,','  ;
  .'  .     `--'  /     ).   `.      ;
 ;     `-  1ucky /     '  )         ;
 \                       ')       ,'
  \                     ,'       ;
   \               `~~~'       ,'
    `.                      _,'
      `.                ,--'
        `-._________,--'
  *
*/

pragma solidity ^0.7.0;

import "./interfaces/IUniswapV2Pair.sol";
import "./IMasterMex.sol";

contract MasterMex is IMasterMex {
    using SafeMath for uint256;

    event Deposit(address indexed sender, uint256 poolId, uint256 amount);
    event Withdraw(address indexed sender, uint256 poolId, uint256 amount);
    event FundAdded(address indexed user, uint256 amount);
    event FundRemoved(address indexed user, uint256 amount);
    event Profit(address indexed receiver, uint256 amount);
    event Loss(address indexed receiver, uint256 amount);

    constructor(
        address payable stakingVault,
        address payable treasuryVault,
        address payable buybackVault,
        uint256 stakeFee,
        uint256 treasuryFee,
        uint256 buybackFee
    ) {
        STAKING_VAULT = stakingVault;
        TREASURY_VAULT = treasuryVault;
        BUYBACK_VAULT = buybackVault;

        TREASURY_FEE = treasuryFee;
        STAKING_FEE = stakeFee;
        BUYBACK_FEE = buybackFee;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function setPool(address uniPair, uint256 maxChangeRatio, uint256 minFund) external onlyOwner {
        poolInfo.push(PoolInfo({
            tokenPair: uniPair,
            prevReserved: 0,
            maxChangeRatio: maxChangeRatio,
            minFund: minFund
        }));

        uint256 length = poolInfo.length;

        groupInfo[length - 1][GroupType.Up] = GroupInfo({
            deposit: 0,
            holding: 0,
            shareProfitPerETH: 0,
            shareLossPerETH: 0
        });
        groupInfo[length - 1][GroupType.Down] = GroupInfo({
            deposit: 0,
            holding: 0,
            shareProfitPerETH: 0,
            shareLossPerETH: 0
        });
    }

    function setFeeDistribution(
        address payable stakingVault,
        address payable treasuryVault,
        address payable buybackVault,
        uint256 stakeFee,
        uint256 treasuryFee,
        uint256 buybackFee
    ) external onlyOwner {
        STAKING_VAULT = stakingVault;
        TREASURY_VAULT = treasuryVault;
        BUYBACK_VAULT = buybackVault;

        TREASURY_FEE = treasuryFee;
        STAKING_FEE = stakeFee;
        BUYBACK_FEE = buybackFee;
    }

    receive() external payable {
        _registerPendingUser(msg.value);
    }

    function _registerPendingUser(uint256 amount) internal {
        require(msg.sender != address(0));
        UserInfo storage user = pendingUserInfo[msg.sender];

        user.amount = user.amount.add(amount);
        user.voteGroup = GroupType.Up;
        emit FundAdded(msg.sender, amount);
    }

    function setPendingUserGroup(GroupType voteGroup) external {
        UserInfo storage user = pendingUserInfo[msg.sender];
        require(user.amount > 0, "No pending amount");

        user.voteGroup = voteGroup;
    }

    function withdrawPendingAmount(uint256 amount) external nonReentrant {
        require(msg.sender != address(0));
        UserInfo storage user = pendingUserInfo[msg.sender];
        require(user.amount >= amount, "Insufficient pending amount");
        
        user.amount = user.amount.sub(amount);
        _safeEthTransfer(msg.sender, amount);
        emit FundRemoved(msg.sender, amount);
    }

    function depositIntoPool(uint256 poolId, uint256 amount) external  {
        require(poolId < poolInfo.length, "No pool");
        UserInfo storage pendingUser = pendingUserInfo[msg.sender];
        require(pendingUser.amount >= amount, "Insufficient pending amount");

        UserInfo storage user = userInfo[poolId][msg.sender];
        if (user.amount > 0 && user.voteGroup != pendingUser.voteGroup) {
            return;
        }
        user.voteGroup = pendingUser.voteGroup;
        pendingUser.amount = pendingUser.amount.sub(amount);
        GroupInfo storage group = groupInfo[poolId][user.voteGroup];

        updatePool(poolId);

        if (user.amount > 0) {
            _claim(poolId);
        }

        user.amount = user.amount.add(amount);
        group.deposit = group.deposit.add(amount);
        group.holding = group.holding.add(amount);
        user.profitDebt = user.amount.mul(group.shareProfitPerETH).div(10**decimals);
        user.lossDebt = user.amount.mul(group.shareLossPerETH).div(10**decimals);
        emit Deposit(msg.sender, poolId, amount);
    }

    function withdrawFromPool(uint256 poolId, uint256 amount) external nonReentrant {
        require(poolId < poolInfo.length, "No pool");
        UserInfo storage user = userInfo[poolId][msg.sender];
        GroupInfo storage group = groupInfo[poolId][user.voteGroup];
        require(user.amount >= amount, "Withdraw over than deposit");

        updatePool(poolId);
        _claim(poolId);

        if (amount > 0) {
            if (user.amount < amount) {
                amount = user.amount;
            }
            user.amount = user.amount.sub(amount);
            group.deposit = group.deposit.sub(amount);
            group.holding = group.holding.sub(amount);
            _safeEthTransfer(msg.sender, amount);
        }
        user.profitDebt = user.amount.mul(group.shareProfitPerETH).div(10**decimals);
        user.lossDebt = user.amount.mul(group.shareLossPerETH).div(10**decimals);
        emit Withdraw(msg.sender, poolId, amount);
    }

    function claim(uint256 poolId) external nonReentrant {
        require(poolId < poolInfo.length, "No pool");
        updatePool(poolId);
        _claim(poolId);
    }

    function updatePool(uint256 poolId) public {
        require(poolId < poolInfo.length, "No pool");

        PoolInfo storage pool = poolInfo[poolId];
        GroupInfo storage upGroup = groupInfo[poolId][GroupType.Up];
        GroupInfo storage downGroup = groupInfo[poolId][GroupType.Down];
        uint256 reserved = _getPrice(pool.tokenPair);

        if (upGroup.holding >= pool.minFund && downGroup.holding >= pool.minFund) {
            uint256 rewardAmt = 0;
            uint256 lossAmt = 0;
            uint256 fee = 0;
            uint256 changedRatio = 0;
            uint256 changedReserved = 0;
            if (reserved > pool.prevReserved) {
                changedReserved = reserved.sub(pool.prevReserved);
                changedRatio = changedReserved.mul(10**decimals).div(pool.prevReserved);

                if (changedRatio > pool.maxChangeRatio) {
                    changedRatio = pool.maxChangeRatio;
                }
                lossAmt = changedRatio.mul(downGroup.holding);
                fee = _distributeFee(lossAmt);
                rewardAmt = lossAmt.sub(fee);
                
                _updateGroup(poolId, GroupType.Up, rewardAmt, false);
                _updateGroup(poolId, GroupType.Down, lossAmt, true);
            } else {
                changedReserved = pool.prevReserved.sub(reserved);
                changedRatio = changedReserved.mul(10**decimals).div(pool.prevReserved);

                if (changedRatio > pool.maxChangeRatio) {
                    changedRatio = pool.maxChangeRatio;
                }

                lossAmt = changedRatio.mul(upGroup.holding);
                fee = _distributeFee(lossAmt);
                rewardAmt = lossAmt.sub(fee);

                _updateGroup(poolId, GroupType.Down, rewardAmt, false);
                _updateGroup(poolId, GroupType.Up, lossAmt, true);
            }
        }
        pool.prevReserved = reserved;
    }

    function _getPrice(address tokenPair) internal view returns(uint256) {
        (uint256 reserve0, uint256 reserve1,) = IUniswapV2Pair(tokenPair).getReserves();
        address token0 = IUniswapV2Pair(tokenPair).token0();

        uint256 ratio = 0;
        if (token0 == WETH) {
            ratio = reserve0.mul(10**decimals).div(reserve1);
        } else {
            ratio = reserve1.mul(10**decimals).div(reserve0);
        }

        return ratio;
    }

    function _safeEthTransfer(address to, uint256 amount) internal {
        uint256 remain = address(this).balance;
        if (remain < amount) {
            amount = remain;
        }
        payable(to).transfer(amount);
    }

    function _updateGroup(uint256 poolId, GroupType groupType, uint256 amount, bool loss) internal {
        GroupInfo storage group = groupInfo[poolId][groupType];
        uint256 volumeSharePerETH = amount.div(group.deposit);
        amount = amount.div(10**decimals);
        if (loss) {
            group.holding = group.holding.sub(amount);
            group.shareLossPerETH = group.shareLossPerETH.add(volumeSharePerETH);
        } else {
            group.holding = group.holding.add(amount);
            group.shareProfitPerETH = group.shareProfitPerETH.add(volumeSharePerETH);
        }
    }

    function _claim(uint256 poolId) internal {
        UserInfo storage user = userInfo[poolId][msg.sender];
        GroupInfo storage group = groupInfo[poolId][user.voteGroup];
        
        uint256 pendingProfit = 0;
        uint256 pendingLoss = 0;
        if (user.amount > 0) {
            pendingProfit = user.amount.mul(group.shareProfitPerETH).div(10**decimals).sub(user.profitDebt);

            pendingLoss = user.amount.mul(group.shareLossPerETH).div(10**decimals).sub(user.lossDebt);
        }

        user.amount = user.amount.add(pendingProfit);
        user.amount = user.amount.sub(pendingLoss);

        if (pendingProfit > pendingLoss) {
            uint256 volume = pendingProfit.sub(pendingLoss);
            group.holding = group.holding.sub(volume);
            _safeEthTransfer(msg.sender, volume);
            emit Profit(msg.sender, volume);
        } else if (pendingProfit < pendingLoss) {
            uint256 volume = pendingLoss.sub(pendingProfit);
            group.deposit = group.deposit.sub(volume);
            emit Loss(msg.sender, volume);
        }
    }

    function _distributeFee(uint256 amount) internal returns(uint256) {
        uint256 totalFee = STAKING_FEE.add(TREASURY_FEE).add(BUYBACK_FEE);
        uint256 feeAmt = amount.mul(totalFee).div(10**decimals);

        uint256 partialFeeAmt = feeAmt.mul(STAKING_FEE).div(totalFee).div(10**decimals);
        _safeEthTransfer(STAKING_VAULT, partialFeeAmt);

        partialFeeAmt = feeAmt.mul(TREASURY_FEE).div(totalFee).div(10**decimals);
        _safeEthTransfer(TREASURY_VAULT, partialFeeAmt);
        
        partialFeeAmt = feeAmt.mul(BUYBACK_FEE).div(totalFee).div(10**decimals);
        _safeEthTransfer(BUYBACK_VAULT, partialFeeAmt);

        return feeAmt;
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}