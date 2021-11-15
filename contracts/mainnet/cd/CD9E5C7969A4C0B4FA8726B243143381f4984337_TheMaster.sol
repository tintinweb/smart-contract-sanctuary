// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./uniswapv2/interfaces/IUniswapV2ERC20.sol";
import "./interfaces/ITheMaster.sol";
import "./libraries/MasterChefModule.sol";

contract TheMaster is Ownable, MasterChefModule, ITheMaster {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        address addr;
        bool delegate;
        ISupportable supportable;
        uint8 supportingRatio; //out of 100
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accRewardPerShare;
        uint256 supply;
    }

    uint256 private constant PRECISION = 1e20;

    uint256 public immutable override initialRewardPerBlock;
    uint256 public immutable override decreasingInterval;
    uint256 public immutable override startBlock;

    IMaidCoin public immutable override maidCoin;
    IRewardCalculator public override rewardCalculator;

    PoolInfo[] public override poolInfo;
    mapping(uint256 => mapping(uint256 => UserInfo)) public override userInfo;
    mapping(uint256 => mapping(address => uint256)) private sushiRewardDebt;
    mapping(address => bool) public override mintableByAddr;
    uint256 public override totalAllocPoint;

    constructor(
        uint256 _initialRewardPerBlock,
        uint256 _decreasingInterval,
        uint256 _startBlock,
        IMaidCoin _maidCoin,
        IUniswapV2Pair _lpToken,
        IERC20 _sushi
    ) MasterChefModule(_lpToken, _sushi) {
        initialRewardPerBlock = _initialRewardPerBlock;
        decreasingInterval = _decreasingInterval;
        startBlock = _startBlock;
        maidCoin = _maidCoin;
    }

    function poolCount() external view override returns (uint256) {
        return poolInfo.length;
    }

    function pendingReward(uint256 pid, uint256 userId) external view override returns (uint256) {
        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][userId];
        (uint256 accRewardPerShare, uint256 supply) = (pool.accRewardPerShare, pool.supply);
        uint256 _lastRewardBlock = pool.lastRewardBlock;
        if (block.number > _lastRewardBlock && supply != 0) {
            uint256 reward = ((block.number - _lastRewardBlock) * rewardPerBlock() * pool.allocPoint) / totalAllocPoint;
            accRewardPerShare = accRewardPerShare + (reward * PRECISION) / supply;
        }
        uint256 pending = ((user.amount * accRewardPerShare) / PRECISION) - user.rewardDebt;
        uint256 _supportingRatio = pool.supportingRatio;
        if (_supportingRatio == 0) {
            return pending;
        } else {
            return pending - ((pending * _supportingRatio) / 100);
        }
    }

    function rewardPerBlock() public view override returns (uint256) {
        if (address(rewardCalculator) != address(0)) {
            return rewardCalculator.rewardPerBlock();
        }
        uint256 era = (block.number - startBlock) / decreasingInterval;
        return initialRewardPerBlock / (era + 1);
    }

    function changeRewardCalculator(address addr) external override onlyOwner {
        rewardCalculator = IRewardCalculator(addr);
        emit ChangeRewardCalculator(addr);
    }

    function add(
        address addr,
        bool delegate,
        bool mintable,
        address supportable,
        uint8 supportingRatio,
        uint256 allocPoint
    ) external override onlyOwner {
        if (supportable != address(0)) {
            require(supportingRatio > 0 && supportingRatio <= 80, "TheMaster: Outranged supportingRatio");
        } else {
            require(supportingRatio == 0, "TheMaster: Not supportable pool");
        }
        massUpdatePools();
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint += allocPoint;
        uint256 pid = poolInfo.length;
        poolInfo.push(
            PoolInfo(addr, delegate, ISupportable(supportable), supportingRatio, allocPoint, lastRewardBlock, 0, 0)
        );
        if (mintable) {
            mintableByAddr[addr] = true;
        }
        emit Add(pid, addr, delegate, mintableByAddr[addr], supportable, supportingRatio, allocPoint);
    }

    function set(uint256[] calldata pids, uint256[] calldata allocPoints) external override onlyOwner {
        massUpdatePools();
        for (uint256 i = 0; i < pids.length; i += 1) {
            totalAllocPoint = totalAllocPoint - poolInfo[pids[i]].allocPoint + allocPoints[i];
            poolInfo[pids[i]].allocPoint = allocPoints[i];
            emit Set(pids[i], allocPoints[i]);
        }
    }

    function updatePool(PoolInfo storage pool) internal {
        uint256 _lastRewardBlock = pool.lastRewardBlock;
        if (block.number <= _lastRewardBlock) {
            return;
        }
        uint256 supply = pool.supply;
        if (supply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 reward = ((block.number - _lastRewardBlock) * rewardPerBlock() * pool.allocPoint) / totalAllocPoint;
        maidCoin.mint(address(this), reward);
        pool.accRewardPerShare = pool.accRewardPerShare + (reward * PRECISION) / supply;
        pool.lastRewardBlock = block.number;
    }

    function massUpdatePools() internal {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(poolInfo[pid]);
        }
    }

    function deposit(
        uint256 pid,
        uint256 amount,
        uint256 userId
    ) public override {
        PoolInfo storage pool = poolInfo[pid];
        require(address(pool.supportable) == address(0), "TheMaster: Use support func");
        UserInfo storage user = userInfo[pid][userId];
        if (pool.delegate) {
            require(pool.addr == msg.sender, "TheMaster: Not called by delegate");
            _deposit(pid, pool, user, amount, false);
        } else {
            require(address(uint160(userId)) == msg.sender, "TheMaster: Deposit to your address");
            _deposit(pid, pool, user, amount, true);
        }
        emit Deposit(userId, pid, amount);
    }

    function _deposit(
        uint256 pid,
        PoolInfo storage pool,
        UserInfo storage user,
        uint256 amount,
        bool tokenTransfer
    ) internal {
        updatePool(pool);
        uint256 _accRewardPerShare = pool.accRewardPerShare;
        uint256 _amount = user.amount;
        if (_amount > 0) {
            uint256 pending = ((_amount * _accRewardPerShare) / PRECISION) - user.rewardDebt;
            if (pending > 0) safeRewardTransfer(msg.sender, pending);
        }
        if (amount > 0) {
            if (tokenTransfer) {
                IERC20(pool.addr).safeTransferFrom(msg.sender, address(this), amount);
                uint256 _mcPid = masterChefPid;
                if (_mcPid > 0 && pool.addr == address(lpToken)) {
                    sushiRewardDebt[pid][msg.sender] = _depositModule(
                        _mcPid,
                        amount,
                        _amount,
                        sushiRewardDebt[pid][msg.sender]
                    );
                }
            }
            pool.supply += amount;
            _amount += amount;
            user.amount = _amount;
        }
        user.rewardDebt = (_amount * _accRewardPerShare) / PRECISION;
    }

    function depositWithPermit(
        uint256 pid,
        uint256 amount,
        uint256 userId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        IUniswapV2ERC20(poolInfo[pid].addr).permit(msg.sender, address(this), amount, deadline, v, r, s);
        deposit(pid, amount, userId);
    }

    function depositWithPermitMax(
        uint256 pid,
        uint256 amount,
        uint256 userId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        IUniswapV2ERC20(poolInfo[pid].addr).permit(msg.sender, address(this), type(uint256).max, deadline, v, r, s);
        deposit(pid, amount, userId);
    }

    function withdraw(
        uint256 pid,
        uint256 amount,
        uint256 userId
    ) public override {
        PoolInfo storage pool = poolInfo[pid];
        require(address(pool.supportable) == address(0), "TheMaster: Use desupport func");
        UserInfo storage user = userInfo[pid][userId];
        if (pool.delegate) {
            require(pool.addr == msg.sender, "TheMaster: Not called by delegate");
            _withdraw(pid, pool, user, amount, false);
        } else {
            require(address(uint160(userId)) == msg.sender, "TheMaster: Not called by user");
            _withdraw(pid, pool, user, amount, true);
        }
        emit Withdraw(userId, pid, amount);
    }

    function _withdraw(
        uint256 pid,
        PoolInfo storage pool,
        UserInfo storage user,
        uint256 amount,
        bool tokenTransfer
    ) internal {
        uint256 _amount = user.amount;
        require(_amount >= amount, "TheMaster: Insufficient amount");
        updatePool(pool);
        uint256 _accRewardPerShare = pool.accRewardPerShare;
        uint256 pending = ((_amount * _accRewardPerShare) / PRECISION) - user.rewardDebt;
        if (pending > 0) safeRewardTransfer(msg.sender, pending);
        if (amount > 0) {
            pool.supply -= amount;
            _amount -= amount;
            user.amount = _amount;
            if (tokenTransfer) {
                uint256 _mcPid = masterChefPid;
                if (_mcPid > 0 && pool.addr == address(lpToken)) {
                    sushiRewardDebt[pid][msg.sender] = _withdrawModule(
                        _mcPid,
                        amount,
                        _amount + amount,
                        sushiRewardDebt[pid][msg.sender]
                    );
                }

                IERC20(pool.addr).safeTransfer(msg.sender, amount);
            }
        }
        user.rewardDebt = (_amount * _accRewardPerShare) / PRECISION;
    }

    function emergencyWithdraw(uint256 pid) external override {
        PoolInfo storage pool = poolInfo[pid];
        require(address(pool.supportable) == address(0), "TheMaster: Use desupport func");
        require(!pool.delegate, "TheMaster: Pool should be non-delegate");
        UserInfo storage user = userInfo[pid][uint256(uint160(msg.sender))];
        uint256 amounts = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.supply -= amounts;

        uint256 _mcPid = masterChefPid;
        if (_mcPid > 0 && pool.addr == address(lpToken)) {
            sushiRewardDebt[pid][msg.sender] = _withdrawModule(
                _mcPid,
                amounts,
                amounts,
                sushiRewardDebt[pid][msg.sender]
            );
        }

        IERC20(pool.addr).safeTransfer(msg.sender, amounts);
        emit EmergencyWithdraw(msg.sender, pid, amounts);
    }

    function support(
        uint256 pid,
        uint256 amount,
        uint256 supportTo
    ) public override {
        PoolInfo storage pool = poolInfo[pid];
        ISupportable supportable = pool.supportable;
        require(address(supportable) != address(0), "TheMaster: Use deposit func");
        UserInfo storage user = userInfo[pid][uint256(uint160(msg.sender))];
        updatePool(pool);
        uint256 _accRewardPerShare = pool.accRewardPerShare;
        uint256 _amount = user.amount;
        if (_amount > 0) {
            uint256 pending = ((_amount * _accRewardPerShare) / PRECISION) - user.rewardDebt;
            if (pending > 0) {
                (address to, uint256 amounts) = supportable.shareRewards(pending, msg.sender, pool.supportingRatio);
                if (amounts > 0) safeRewardTransfer(to, amounts);
                safeRewardTransfer(msg.sender, pending - amounts);
            }
        }
        if (amount > 0) {
            if (_amount == 0) {
                supportable.setSupportingTo(msg.sender, supportTo, amount);
            } else {
                supportable.changeSupportedPower(msg.sender, int256(amount));
            }
            IERC20(pool.addr).safeTransferFrom(msg.sender, address(this), amount);

            uint256 _mcPid = masterChefPid;
            if (_mcPid > 0 && pool.addr == address(lpToken)) {
                sushiRewardDebt[pid][msg.sender] = _depositModule(
                    _mcPid,
                    amount,
                    _amount,
                    sushiRewardDebt[pid][msg.sender]
                );
            }

            pool.supply += amount;
            _amount += amount;
            user.amount = _amount;
        }
        user.rewardDebt = (_amount * _accRewardPerShare) / PRECISION;
        emit Support(msg.sender, pid, amount);
    }

    function supportWithPermit(
        uint256 pid,
        uint256 amount,
        uint256 supportTo,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        IUniswapV2ERC20(poolInfo[pid].addr).permit(msg.sender, address(this), amount, deadline, v, r, s);
        support(pid, amount, supportTo);
    }

    function supportWithPermitMax(
        uint256 pid,
        uint256 amount,
        uint256 supportTo,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        IUniswapV2ERC20(poolInfo[pid].addr).permit(msg.sender, address(this), type(uint256).max, deadline, v, r, s);
        support(pid, amount, supportTo);
    }

    function desupport(uint256 pid, uint256 amount) external override {
        PoolInfo storage pool = poolInfo[pid];
        ISupportable supportable = pool.supportable;
        require(address(supportable) != address(0), "TheMaster: Use withdraw func");
        UserInfo storage user = userInfo[pid][uint256(uint160(msg.sender))];
        uint256 _amount = user.amount;
        require(_amount >= amount, "TheMaster: Insufficient amount");
        updatePool(pool);
        uint256 _accRewardPerShare = pool.accRewardPerShare;
        uint256 pending = ((_amount * _accRewardPerShare) / PRECISION) - user.rewardDebt;
        if (pending > 0) {
            (address to, uint256 amounts) = supportable.shareRewards(pending, msg.sender, pool.supportingRatio);
            if (amounts > 0) safeRewardTransfer(to, amounts);
            safeRewardTransfer(msg.sender, pending - amounts);
        }
        if (amount > 0) {
            supportable.changeSupportedPower(msg.sender, -int256(amount));

            uint256 _mcPid = masterChefPid;
            if (_mcPid > 0 && pool.addr == address(lpToken)) {
                sushiRewardDebt[pid][msg.sender] = _withdrawModule(
                    _mcPid,
                    amount,
                    _amount,
                    sushiRewardDebt[pid][msg.sender]
                );
            }

            pool.supply -= amount;
            _amount -= amount;
            user.amount = _amount;
            IERC20(pool.addr).safeTransfer(msg.sender, amount);
        }
        user.rewardDebt = (_amount * _accRewardPerShare) / PRECISION;
        emit Desupport(msg.sender, pid, amount);
    }

    function emergencyDesupport(uint256 pid) external override {
        PoolInfo storage pool = poolInfo[pid];
        ISupportable supportable = pool.supportable;
        require(address(supportable) != address(0), "TheMaster: Use emergencyWithdraw func");
        UserInfo storage user = userInfo[pid][uint256(uint160(msg.sender))];
        uint256 amounts = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.supply -= amounts;
        supportable.changeSupportedPower(msg.sender, -int256(amounts));

        uint256 _mcPid = masterChefPid;
        if (_mcPid > 0 && pool.addr == address(lpToken)) {
            sushiRewardDebt[pid][msg.sender] = _withdrawModule(
                _mcPid,
                amounts,
                amounts,
                sushiRewardDebt[pid][msg.sender]
            );
        }

        IERC20(pool.addr).safeTransfer(msg.sender, amounts);
        emit EmergencyDesupport(msg.sender, pid, amounts);
    }

    function mint(address to, uint256 amount) external override {
        require(mintableByAddr[msg.sender], "TheMaster: Called from un-mintable");
        maidCoin.mint(to, amount);
    }

    function safeRewardTransfer(address to, uint256 amount) internal {
        uint256 balance = maidCoin.balanceOf(address(this));
        if (amount > balance) {
            maidCoin.transfer(to, balance);
        } else {
            maidCoin.transfer(to, amount);
        }
    }

    function pendingSushiReward(uint256 pid) external view override returns (uint256) {
        return
            _pendingSushiReward(userInfo[pid][uint256(uint160(msg.sender))].amount, sushiRewardDebt[pid][msg.sender]);
    }

    function claimSushiReward(uint256 pid) public override {
        PoolInfo storage pool = poolInfo[pid];
        require(pool.addr == address(lpToken) && !pool.delegate, "TheMaster: Invalid pid");

        sushiRewardDebt[pid][msg.sender] = _claimSushiReward(
            userInfo[pid][uint256(uint160(msg.sender))].amount,
            sushiRewardDebt[pid][msg.sender]
        );
    }

    function claimAllReward(uint256 pid) public {
        PoolInfo storage pool = poolInfo[pid];
        require(pool.addr == address(lpToken) && !pool.delegate, "TheMaster: Invalid pid");

        UserInfo storage user = userInfo[pid][uint256(uint160(msg.sender))];
        uint256 amount = user.amount;
        require(amount > 0, "TheMaster: Nothing can be claimed");
        sushiRewardDebt[pid][msg.sender] = _claimSushiReward(amount, sushiRewardDebt[pid][msg.sender]);

        updatePool(pool);
        ISupportable supportable = pool.supportable;

        if (address(supportable) == address(0)) {
            uint256 _accRewardPerShare = pool.accRewardPerShare;
            uint256 pending = ((amount * _accRewardPerShare) / PRECISION) - user.rewardDebt;
            if (pending > 0) safeRewardTransfer(msg.sender, pending);
            user.rewardDebt = (amount * _accRewardPerShare) / PRECISION;
        } else {
            uint256 _accRewardPerShare = pool.accRewardPerShare;
            uint256 pending = ((amount * _accRewardPerShare) / PRECISION) - user.rewardDebt;
            if (pending > 0) {
                (address to, uint256 amounts) = supportable.shareRewards(pending, msg.sender, pool.supportingRatio);
                if (amounts > 0) safeRewardTransfer(to, amounts);
                safeRewardTransfer(msg.sender, pending - amounts);
            }
            user.rewardDebt = (amount * _accRewardPerShare) / PRECISION;
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
    constructor () {
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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IUniswapV2ERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "./IMaidCoin.sol";
import "./IRewardCalculator.sol";
import "./ISupportable.sol";
import "./IMasterChefModule.sol";

interface ITheMaster is IMasterChefModule {
    event ChangeRewardCalculator(address addr);

    event Add(
        uint256 indexed pid,
        address addr,
        bool indexed delegate,
        bool indexed mintable,
        address supportable,
        uint8 supportingRatio,
        uint256 allocPoint
    );

    event Set(uint256 indexed pid, uint256 allocPoint);
    event Deposit(uint256 indexed userId, uint256 indexed pid, uint256 amount);
    event Withdraw(uint256 indexed userId, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    event Support(address indexed supporter, uint256 indexed pid, uint256 amount);
    event Desupport(address indexed supporter, uint256 indexed pid, uint256 amount);
    event EmergencyDesupport(address indexed user, uint256 indexed pid, uint256 amount);

    event SetIsSupporterPool(uint256 indexed pid, bool indexed status);

    function initialRewardPerBlock() external view returns (uint256);

    function decreasingInterval() external view returns (uint256);

    function startBlock() external view returns (uint256);

    function maidCoin() external view returns (IMaidCoin);

    function rewardCalculator() external view returns (IRewardCalculator);

    function poolInfo(uint256 pid)
        external
        view
        returns (
            address addr,
            bool delegate,
            ISupportable supportable,
            uint8 supportingRatio,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accRewardPerShare,
            uint256 supply
        );

    function poolCount() external view returns (uint256);

    function userInfo(uint256 pid, uint256 user) external view returns (uint256 amount, uint256 rewardDebt);

    function mintableByAddr(address addr) external view returns (bool);

    function totalAllocPoint() external view returns (uint256);

    function pendingReward(uint256 pid, uint256 userId) external view returns (uint256);

    function rewardPerBlock() external view returns (uint256);

    function changeRewardCalculator(address addr) external;

    function add(
        address addr,
        bool delegate,
        bool mintable,
        address supportable,
        uint8 supportingRatio,
        uint256 allocPoint
    ) external;

    function set(uint256[] calldata pid, uint256[] calldata allocPoint) external;

    function deposit(
        uint256 pid,
        uint256 amount,
        uint256 userId
    ) external;

    function depositWithPermit(
        uint256 pid,
        uint256 amount,
        uint256 userId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function depositWithPermitMax(
        uint256 pid,
        uint256 amount,
        uint256 userId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function withdraw(
        uint256 pid,
        uint256 amount,
        uint256 userId
    ) external;

    function emergencyWithdraw(uint256 pid) external;

    function support(
        uint256 pid,
        uint256 amount,
        uint256 supportTo
    ) external;

    function supportWithPermit(
        uint256 pid,
        uint256 amount,
        uint256 supportTo,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function supportWithPermitMax(
        uint256 pid,
        uint256 amount,
        uint256 supportTo,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function desupport(uint256 pid, uint256 amount) external;

    function emergencyDesupport(uint256 pid) external;

    function mint(address to, uint256 amount) external;

    function claimSushiReward(uint256 id) external;

    function pendingSushiReward(uint256 id) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IMasterChefModule.sol";

abstract contract MasterChefModule is Ownable, IMasterChefModule {
    IUniswapV2Pair public immutable override lpToken;

    IERC20 public immutable override sushi;
    IMasterChef public override sushiMasterChef;
    uint256 public override masterChefPid;
    uint256 public override sushiLastRewardBlock;
    uint256 public override accSushiPerShare;
    bool private initialDeposited;

    constructor(IUniswapV2Pair _lpToken, IERC20 _sushi) {
        lpToken = _lpToken;
        sushi = _sushi;
    }

    function _depositModule(
        uint256 _pid,
        uint256 depositAmount,
        uint256 supportedLPTokenAmount,
        uint256 sushiRewardDebt
    ) internal returns (uint256 newRewardDebt) {
        uint256 _totalSupportedLPTokenAmount = sushiMasterChef.userInfo(_pid, address(this)).amount;
        uint256 _accSushiPerShare = _depositToSushiMasterChef(_pid, depositAmount, _totalSupportedLPTokenAmount);
        uint256 pending = (supportedLPTokenAmount * _accSushiPerShare) / 1e18 - sushiRewardDebt;
        if (pending > 0) safeSushiTransfer(msg.sender, pending);
        return ((supportedLPTokenAmount + depositAmount) * _accSushiPerShare) / 1e18;
    }

    function _withdrawModule(
        uint256 _pid,
        uint256 withdrawalAmount,
        uint256 supportedLPTokenAmount,
        uint256 sushiRewardDebt
    ) internal returns (uint256 newRewardDebt) {
        uint256 _totalSupportedLPTokenAmount = sushiMasterChef.userInfo(_pid, address(this)).amount;
        uint256 _accSushiPerShare = _withdrawFromSushiMasterChef(_pid, withdrawalAmount, _totalSupportedLPTokenAmount);
        uint256 pending = (supportedLPTokenAmount * _accSushiPerShare) / 1e18 - sushiRewardDebt;
        if (pending > 0) safeSushiTransfer(msg.sender, pending);
        return ((supportedLPTokenAmount - withdrawalAmount) * _accSushiPerShare) / 1e18;
    }

    function _claimSushiReward(uint256 supportedLPTokenAmount, uint256 sushiRewardDebt)
        internal
        returns (uint256 newRewardDebt)
    {
        uint256 _pid = masterChefPid;
        require(_pid > 0, "MasterChefModule: Unclaimable");

        uint256 _totalSupportedLPTokenAmount = sushiMasterChef.userInfo(_pid, address(this)).amount;
        uint256 _accSushiPerShare = _depositToSushiMasterChef(_pid, 0, _totalSupportedLPTokenAmount);
        uint256 pending = (supportedLPTokenAmount * _accSushiPerShare) / 1e18 - sushiRewardDebt;
        require(pending > 0, "MasterChefModule: Nothing can be claimed");
        safeSushiTransfer(msg.sender, pending);
        return (supportedLPTokenAmount * _accSushiPerShare) / 1e18;
    }

    function _pendingSushiReward(uint256 supportedLPTokenAmount, uint256 sushiRewardDebt)
        internal
        view
        returns (uint256)
    {
        uint256 _pid = masterChefPid;
        if (_pid == 0) return 0;
        uint256 _totalSupportedLPTokenAmount = sushiMasterChef.userInfo(_pid, address(this)).amount;

        uint256 _accSushiPerShare = accSushiPerShare;
        if (block.number > sushiLastRewardBlock && _totalSupportedLPTokenAmount != 0) {
            uint256 reward = sushiMasterChef.pendingSushi(masterChefPid, address(this));
            _accSushiPerShare += ((reward * 1e18) / _totalSupportedLPTokenAmount);
        }

        return (supportedLPTokenAmount * _accSushiPerShare) / 1e18 - sushiRewardDebt;
    }

    function setSushiMasterChef(IMasterChef _masterChef, uint256 _pid) external onlyOwner {
        require(address(_masterChef.poolInfo(_pid).lpToken) == address(lpToken), "MasterChefModule: Invalid pid");
        if (!initialDeposited) {
            initialDeposited = true;
            lpToken.approve(address(_masterChef), type(uint256).max);

            sushiMasterChef = _masterChef;
            masterChefPid = _pid;
            _depositToSushiMasterChef(_pid, lpToken.balanceOf(address(this)), 0);
        } else {
            IMasterChef oldChef = sushiMasterChef;
            uint256 oldpid = masterChefPid;
            _withdrawFromSushiMasterChef(oldpid, oldChef.userInfo(oldpid, address(this)).amount, 0);
            if (_masterChef != oldChef) {
                lpToken.approve(address(oldChef), 0);
                lpToken.approve(address(_masterChef), type(uint256).max);
            }

            sushiMasterChef = _masterChef;
            masterChefPid = _pid;
            _depositToSushiMasterChef(_pid, lpToken.balanceOf(address(this)), 0);
        }
    }

    function _depositToSushiMasterChef(
        uint256 _pid,
        uint256 _amount,
        uint256 _totalSupportedLPTokenAmount
    ) internal returns (uint256 _accSushiPerShare) {
        return _toSushiMasterChef(true, _pid, _amount, _totalSupportedLPTokenAmount);
    }

    function _withdrawFromSushiMasterChef(
        uint256 _pid,
        uint256 _amount,
        uint256 _totalSupportedLPTokenAmount
    ) internal returns (uint256 _accSushiPerShare) {
        return _toSushiMasterChef(false, _pid, _amount, _totalSupportedLPTokenAmount);
    }

    function _toSushiMasterChef(
        bool deposit,
        uint256 _pid,
        uint256 _amount,
        uint256 _totalSupportedLPTokenAmount
    ) internal returns (uint256) {
        uint256 reward;
        if (block.number <= sushiLastRewardBlock) {
            if (deposit) sushiMasterChef.deposit(_pid, _amount);
            else sushiMasterChef.withdraw(_pid, _amount);
            return accSushiPerShare;
        } else {
            uint256 balance0 = sushi.balanceOf(address(this));
            if (deposit) sushiMasterChef.deposit(_pid, _amount);
            else sushiMasterChef.withdraw(_pid, _amount);
            uint256 balance1 = sushi.balanceOf(address(this));
            reward = balance1 - balance0;
        }
        sushiLastRewardBlock = block.number;
        if (_totalSupportedLPTokenAmount > 0 && reward > 0) {
            uint256 _accSushiPerShare = accSushiPerShare + ((reward * 1e18) / _totalSupportedLPTokenAmount);
            accSushiPerShare = _accSushiPerShare;
            return _accSushiPerShare;
        } else {
            return accSushiPerShare;
        }
    }

    function safeSushiTransfer(address _to, uint256 _amount) internal {
        uint256 sushiBal = sushi.balanceOf(address(this));
        if (_amount > sushiBal) {
            sushi.transfer(_to, sushiBal);
        } else {
            sushi.transfer(_to, _amount);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
pragma solidity >=0.5.0;

interface IMaidCoin {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function INITIAL_SUPPLY() external pure returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IRewardCalculator {
    function rewardPerBlock() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface ISupportable {
    event SupportTo(address indexed supporter, uint256 indexed to);
    event ChangeSupportingRoute(uint256 indexed from, uint256 indexed to);
    event ChangeSupportedPower(uint256 indexed id, int256 power);
    event TransferSupportingRewards(address indexed supporter, uint256 indexed id, uint256 amounts);

    function supportingRoute(uint256 id) external view returns (uint256);

    function supportingTo(address supporter) external view returns (uint256);

    function supportedPower(uint256 id) external view returns (uint256);

    function totalRewardsFromSupporters(uint256 id) external view returns (uint256);

    function setSupportingTo(
        address supporter,
        uint256 to,
        uint256 amounts
    ) external;

    function checkSupportingRoute(address supporter) external returns (address, uint256);

    function changeSupportedPower(address supporter, int256 power) external;

    function shareRewards(
        uint256 pending,
        address supporter,
        uint8 supportingRatio
    ) external returns (address nurseOwner, uint256 amountToNurseOwner);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "./IMasterChef.sol";
import "../uniswapv2/interfaces/IUniswapV2Pair.sol";

interface IMasterChefModule {
    function lpToken() external view returns (IUniswapV2Pair);

    function sushi() external view returns (IERC20);

    function sushiMasterChef() external view returns (IMasterChef);

    function masterChefPid() external view returns (uint256);

    function sushiLastRewardBlock() external view returns (uint256);

    function accSushiPerShare() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMasterChef {
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. SUSHI to distribute per block.
        uint256 lastRewardBlock; // Last block number that SUSHI distribution occurs.
        uint256 accSushiPerShare; // Accumulated SUSHI per share, times 1e12. See below.
    }

    function poolInfo(uint256 pid) external view returns (IMasterChef.PoolInfo memory);

    function userInfo(uint256 pid, address user) external view returns (IMasterChef.UserInfo memory);

    function pendingSushi(uint256 _pid, address _user) external view returns (uint256);

    function deposit(uint256 _pid, uint256 _amount) external;

    function withdraw(uint256 _pid, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

