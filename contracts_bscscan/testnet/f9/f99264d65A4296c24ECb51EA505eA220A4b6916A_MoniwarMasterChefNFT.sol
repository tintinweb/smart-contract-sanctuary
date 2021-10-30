// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.6.0 <=0.8.0;
pragma abicoder v2;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./MowaCore.sol";
import "./IERC721.sol";

// MasterChef is the master of MOWA. He can make MOWA and he is a fair guy.
//
// Note that it's ownable and the owner wields tremendous power. The ownership
// will be transferred to a governance smart contract once MOWA is sufficiently
// distributed and the community can show to govern itself.
//
// Have fun reading it. Hopefully it's bug-free. God bless.
contract MoniwarMasterChefNFT is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        uint256 rewardLockedUp; // Reward locked up.
        uint256 hashRate; // hashrate = level * star
        uint256 lpStake; // LP user stake
        uint256 tokenId;
        address owner;
        //
        // We do some fancy math here. Basically, any point in time, the amount of MOWAs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accMowaPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accMowaPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 startBlock; // Start block
        uint256 endBlock; // End block
        uint256 lastRewardBlock; // Last block number that MOWAs distribution occurs.
        uint256 rewardPerBlock;
        uint256 accMowaPerShare; // Accumulated MOWAs per share, times 1e12. See below.
        uint256 totalLP;
        uint256 totalLPExHashRate;
        uint256 allocPoint;
    }

    // The MOWA TOKEN!
    IERC20 public mowa;
    // The MOWA NFT Core!
    MowaCore public mowaNFTCore;
    // The MOWA NFT!
    IERC721 public mowaNFT;

    uint256 public totalAllocPoint = 0;

    // Info of each pool.
    PoolInfo[] public mowaPoolInfoNFT;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Fee withdraw before expire
    uint256 feeWithdraw = 15;
    // Fee harvest
    uint256 feeHarvest = 10;
    address public feeWallet;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event DepositNFT(address indexed user, uint256 indexed pid, uint256 tokenId);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RewardsHarvested(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        IERC20 _mowa,
        MowaCore _mowaNFTCore,
        IERC721 _mowaNFT,
        address _feeWallet
    ) public {
        mowa = _mowa;
        mowaNFT = _mowaNFT;
        mowaNFTCore = MowaCore(_mowaNFTCore);
        feeWallet = _feeWallet;
    }

    function mowaPoolNFTLength() external view returns (uint256) {
        return mowaPoolInfoNFT.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        IERC20 _lpToken,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _rewardPerBlock
    ) public onlyOwner {
        uint256 lastRewardBlock = block.number > _startBlock
        ? block.number
        : _startBlock;
        mowaPoolInfoNFT.push(
            PoolInfo({
                lpToken : _lpToken,
                lastRewardBlock : lastRewardBlock,
                accMowaPerShare : 0,
                startBlock : _startBlock,
                endBlock : _endBlock,
                rewardPerBlock : _rewardPerBlock,
                totalLP : 0,
                totalLPExHashRate : 0,
                allocPoint : 100
            })
        );
    }

    // Update the given pool's MOWA allocation point and deposit fee. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _rewardPerBlock,
        bool _withUpdate
    ) public onlyOwner {
        if (_startBlock > 0) {
            mowaPoolInfoNFT[_pid].startBlock = _startBlock;
        }
        if (_endBlock > 0) {
            mowaPoolInfoNFT[_pid].endBlock = _endBlock;
        }
        if (_rewardPerBlock > 0) {
            mowaPoolInfoNFT[_pid].rewardPerBlock = _rewardPerBlock;
        }
        if (_withUpdate) {
            updatePool(_pid);
        }
    }

    function setLP(
        uint256 _pid,
        IERC20 _lpToken
    ) public onlyOwner {
        mowaPoolInfoNFT[_pid].lpToken = _lpToken;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256)
    {
        return _to.sub(_from);
    }

    // calculator
    function calculator(uint256 _pid, uint256 amount, uint256 hashrate, uint256 date) external view returns (uint256) {
        uint256 blockCal = 1;
        if(date != 0) {
            blockCal = date.mul(86400).div(3);
        }
        PoolInfo storage pool = mowaPoolInfoNFT[_pid];
        amount = amount.add(amount.mul(hashrate).div(100));
        uint256 amountTotal = amount.add(pool.totalLPExHashRate);
        uint256 accMowaPerShare = pool.accMowaPerShare;
        uint256 mowaReward = blockCal.mul(pool.rewardPerBlock);
        accMowaPerShare = accMowaPerShare.add(mowaReward.mul(1e12).div(amountTotal));
        return amount.mul(accMowaPerShare).div(1e12);
    }

    // View function to see pending MOWAs on frontend.
    function pendingRewards(uint256 _pid, address _user) external view returns (uint256)
    {
        PoolInfo storage pool = mowaPoolInfoNFT[_pid];
        UserInfo storage user = userInfo[_pid][_user];

        uint256 pending = user.rewardLockedUp;
        if (
            user.tokenId == 0 ||
            user.amount == 0 ||
            block.number < pool.lastRewardBlock ||
            block.number >= pool.endBlock
        ) {
            return pending;
        }
        uint256 accMowaPerShare = pool.accMowaPerShare;
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 mowaReward = multiplier.mul(pool.rewardPerBlock);
        accMowaPerShare = accMowaPerShare.add(mowaReward.mul(1e12).div(pool.totalLPExHashRate));
        pending = user.amount.mul(accMowaPerShare).div(1e12).sub(user.rewardDebt);
        return pending.add(user.rewardLockedUp);
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = mowaPoolInfoNFT[_pid];
        if (block.number < pool.lastRewardBlock) {
            return;
        }
        if (block.number >= pool.endBlock) {
            pool.rewardPerBlock = 0;
            return;
        }
        if (pool.totalLPExHashRate == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 mowaReward = multiplier.mul(pool.rewardPerBlock);
        pool.accMowaPerShare = pool.accMowaPerShare.add(mowaReward.mul(1e12).div(pool.totalLPExHashRate));
        pool.lastRewardBlock = block.number;
    }

    // Deposit LP tokens to MasterChef for MOWA allocation.
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        require(_amount > 0, "Deposit amount > 0");
        PoolInfo storage pool = mowaPoolInfoNFT[_pid];
        require(block.number >= pool.startBlock, "pool not start");
        require(block.number < pool.endBlock, "pool has ended");
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        payOrLockupPendingMowa(_pid);
        pool.lpToken.transferFrom(address(msg.sender), address(this), _amount);
        user.lpStake = user.lpStake.add(_amount);
        pool.totalLP = pool.totalLP.add(_amount);
        if (user.hashRate > 0) {
            if (user.amount > 0) {
                pool.totalLPExHashRate = pool.totalLPExHashRate.sub(user.amount);
            }
            uint256 amountWithHashrate = user.lpStake.add(user.lpStake.mul(user.hashRate).div(100));
            user.amount = amountWithHashrate;
            pool.totalLPExHashRate = pool.totalLPExHashRate.add(amountWithHashrate);
        }
        user.rewardDebt = user.amount.mul(pool.accMowaPerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Deposit NFT to MasterChef for MOWA allocation.
    function depositNFT(uint256 _pid, uint256 _tokenId) public nonReentrant {
        require(_tokenId > 0, "tokenID not NFT");
        PoolInfo storage pool = mowaPoolInfoNFT[_pid];
        require(block.number >= pool.startBlock, "pool not start");
        require(block.number < pool.endBlock, "pool has ended");
        require(mowaNFT.ownerOf(_tokenId) == msg.sender, "not own");
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.tokenId != _tokenId, "already stake this nft");
        updatePool(_pid);
        payOrLockupPendingMowa(_pid);
        uint256 levelNFT = mowaNFTCore.getNFT(_tokenId).level;
        uint256 starNFT = mowaNFTCore.getNFT(_tokenId).star;
        uint256 hashRate = levelNFT.mul(starNFT);
        user.tokenId = _tokenId;
        user.hashRate = hashRate;
        user.owner = msg.sender;
        mowaNFT.transferFrom(address(msg.sender), address(this), _tokenId);
        if (user.lpStake > 0) {
            uint256 amountWithHashrate = user.lpStake.add(user.lpStake.mul(hashRate).div(100));
            user.amount = amountWithHashrate;
            pool.totalLPExHashRate = pool.totalLPExHashRate.add(amountWithHashrate);
        }
        user.rewardDebt = user.amount.mul(pool.accMowaPerShare).div(1e12);
        emit DepositNFT(msg.sender, _pid, _tokenId);
    }

    // Withdraw LP tokens from MasterChef.
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        PoolInfo storage pool = mowaPoolInfoNFT[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(_amount > 0, "withdrawal amount must be greater than 0");
        require(user.lpStake >= _amount, "withdraw: not good");
        updatePool(_pid);
        payOrLockupPendingMowa(_pid);
        if (block.number < pool.endBlock) {
            uint256 withdrawFee = _amount.mul(feeWithdraw).div(1000);
            pool.lpToken.transfer(address(msg.sender), _amount.sub(withdrawFee));
            pool.lpToken.transfer(feeWallet, withdrawFee);
        } else {
            pool.lpToken.transfer(address(msg.sender), _amount);
        }
        user.lpStake = user.lpStake.sub(_amount);
        pool.totalLP = pool.totalLP.sub(_amount);
        if (user.amount > 0) {
            pool.totalLPExHashRate = pool.totalLPExHashRate.sub(user.amount);
        }
        if (user.hashRate > 0) {
            uint256 amountWithHashrate = user.lpStake.add(user.lpStake.mul(user.hashRate).div(100));
            user.amount = amountWithHashrate;
            pool.totalLPExHashRate = pool.totalLPExHashRate.add(amountWithHashrate);
        }
        user.rewardDebt = user.amount.mul(pool.accMowaPerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public nonReentrant {
        PoolInfo storage pool = mowaPoolInfoNFT[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.lpStake >= 0, "withdraw: not good");
        updatePool(_pid);
        uint256 amount = user.lpStake;

        if (block.number < pool.endBlock) {
            uint256 withdrawFee = amount.mul(feeWithdraw).div(1000);
            pool.lpToken.transfer(address(msg.sender), amount.sub(withdrawFee));
            pool.lpToken.transfer(feeWallet, withdrawFee);
        } else {
            pool.lpToken.transfer(address(msg.sender), amount);
        }

        pool.totalLP = pool.totalLP.sub(amount);
        pool.totalLPExHashRate = pool.totalLPExHashRate.sub(user.amount);

        if (user.tokenId != 0) {
            mowaNFT.transferFrom(address(this), msg.sender, user.tokenId);
        }

        user.rewardDebt = user.amount.mul(pool.accMowaPerShare).div(1e12);
        user.lpStake = 0;
        user.amount = 0;
        user.rewardDebt = 0;
        user.rewardLockedUp = 0;
        user.tokenId = 0;
        user.hashRate = 0;
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    //Harvest proceeds msg.sender
    function harvest(uint256 _pid) public nonReentrant {
        updatePool(_pid);
        PoolInfo storage pool = mowaPoolInfoNFT[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(block.number >= pool.lastRewardBlock, "pool not start");

        uint256 pending = 0;
        if (user.tokenId == 0 ||
            user.amount == 0
        ) {
            pending = user.rewardLockedUp;
        } else {
            pending = user.amount.mul(pool.accMowaPerShare).div(1e12).sub(user.rewardDebt);
            pending = pending.add(user.rewardLockedUp);
        }

        if (pending > 0) {
            uint256 harvestFee = pending.mul(feeHarvest).div(1000);
            safeMowaTransfer(msg.sender, pending.sub(harvestFee));
            safeMowaTransfer(feeWallet, harvestFee);
        }
        user.rewardLockedUp = 0;
        user.rewardDebt = user.amount.mul(pool.accMowaPerShare).div(1e12);
        emit RewardsHarvested(msg.sender, _pid, pending);
    }

    //Harvest proceeds msg.sender
    function unStake(uint256 _pid) public nonReentrant {
        updatePool(_pid);
        PoolInfo storage pool = mowaPoolInfoNFT[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.tokenId > 0, "NFT not stake");
        payOrLockupPendingMowa(_pid);
        mowaNFT.transferFrom(address(this), msg.sender, user.tokenId);
        if (user.amount > 0) {
            pool.totalLPExHashRate = pool.totalLPExHashRate.sub(user.amount);
        }
        user.rewardDebt = user.amount.mul(pool.accMowaPerShare).div(1e12);
        user.amount = 0;
        user.tokenId = 0;
        user.hashRate = 0;
    }

    // Pay or lockup pending MOWAs.
    function payOrLockupPendingMowa(uint256 _pid) internal {
        PoolInfo storage pool = mowaPoolInfoNFT[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(block.number >= pool.lastRewardBlock, "pool not start");
        uint256 pending = 0;
        if (pool.totalLPExHashRate > 0) {
            if (user.tokenId == 0 ||
                user.amount == 0
            ) {
                pending = user.rewardLockedUp;
            } else {
                pending = user.amount.mul(pool.accMowaPerShare).div(1e12).sub(user.rewardDebt);
                pending = pending.add(user.rewardLockedUp);
            }
        }
        user.rewardLockedUp = pending;
        user.rewardDebt = user.amount.mul(pool.accMowaPerShare).div(1e12);
    }

    // Safe mowa transfer function, just in case if rounding error causes pool to not have enough MOWAs.
    function safeMowaTransfer(address _to, uint256 _amount) internal {
        uint256 mowaBal = mowa.balanceOf(address(this));
        if (_amount > mowaBal) {
            mowa.transfer(_to, mowaBal);
        } else {
            mowa.transfer(_to, _amount);
        }
    }

    function setFeeWallet(address _addr) external onlyOwner {
        feeWallet = _addr;
    }

    function setFeeWithdraw(uint256 _fee) external onlyOwner {
        feeWithdraw = _fee;
    }

    function setFeeHarvest(uint256 _fee) external onlyOwner {
        feeHarvest = _fee;
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

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "./Context.sol";
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;
pragma abicoder v2;

    struct Mowa {
        uint256 tokenId;
        uint256 level;
        uint256 skill;
        uint256 star;
        uint256 character;
        uint256 class;
        uint256 bornTime;
    }

    struct User {
        Mowa[] mowas;
        address owner;
    }

interface MowaCore {
    function changeLevel(
        uint256 _tokenId,
        address _owner,
        uint256 _level
    ) external;

    function changeClass(
        uint256 _tokenId,
        address _owner,
        uint256 _class
    ) external;

    function changeSkill(
        uint256 _tokenId,
        address _owner,
        uint256 _skill
    ) external;

    function changeCharacter(
        uint256 _tokenId,
        address _owner,
        uint256 _character
    ) external;

    function changeStar(
        uint256 _tokenId,
        address _owner,
        uint256 _star
    ) external;

    function getNFT(uint256 _tokenId) external view returns (Mowa memory);

    function setNFTFactory(Mowa memory _mowa, uint256 _tokenId) external;

    function setNFTForUser(
        Mowa memory _mowa,
        uint256 _tokenId,
        address _userAddress
    ) external;

    function safeMintNFT(address _addr, uint256 tokenId) external;

    function getAllNFT(uint256 _fromTokenId, uint256 _toTokenId) external view returns (Mowa[] memory);

    function getUser(address _userAddress) external view returns (User memory userInfo);
    function getNextNFTId() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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