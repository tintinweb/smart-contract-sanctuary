// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./IMaterials.sol";
import "./ICakeManual.sol";
import "./ReentrancyGuard.sol";

// standard interface of IERC20 token
// using this in this contract to receive LP tokens or transfer
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
    using SafeMath for uint256;
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
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

contract ClayFarm is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of Materials
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accMaterialPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accMaterialPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }
    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. Materials to distribute per block.
        uint256 lastRewardBlock; // Last block number that Materials distribution occurs.
        uint256 accMaterialPerShare; // Accumulated Materials per share, times 1e30. See below.
    }
    // main net:
    address private _materials = 0x04898c211e112e558def9f28B22640Ef814f56e6;
    // main net: 0x0E09FaBB73Bd3Ade0a17ECC321fD13a19e81cE82
    address private _cakeToken = 0xe725a57e41Fd82cEA060C7D7703FDd5C20dFda73;
    // main net: 0x73feaa1eE314F8c655E354234017bE2193C9E24E
    address private _cakeFarm = 0xb052DDa3245eC391Cb3625440969fC563a342790;
    // Material (ERC1155) contract address
    IMaterials public materials;
    // This contract is ClayFarm, and the clay's tokenId = 1
    uint256 public materialId = 1;
    // CAKE Token contract on BSC mainnet
    IERC20 public cakeToken;
    // Syrup Main Staking contract address on BSC mainnet:
    ICakeManual public cakeFarm;
    // record the pid==0 cake balance
    uint256 public cakePoolBalance = 0;
    // Dev address.
    address public devaddr;
    // MATERIAL tokens created per block.
    uint256 public materialPerBlock;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when MATERIAL mining starts.
    uint256 public startBlock;
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        address _devaddr,
        uint256 _materialPerBlock,
        uint256 _startBlock
    ) public {
        devaddr = _devaddr;
        materialPerBlock = _materialPerBlock;
        startBlock = _startBlock;
        
        materials = IMaterials(_materials);
        cakeToken = IERC20(_cakeToken);
        cakeFarm = ICakeManual(_cakeFarm);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    function checkPoolDuplicate(IERC20 _lpToken) public view {
        uint256 length = poolInfo.length;
        for(uint256 pid = 0; pid < length; ++pid) {
            require(poolInfo[pid].lpToken != _lpToken, "can not add existing pool");
        }
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(
        uint256 _allocPoint,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        checkPoolDuplicate(_lpToken);

        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                allocPoint: _allocPoint,
                lastRewardBlock: lastRewardBlock,
                accMaterialPerShare: 0
            })
        );
    }

    // Update the given pool's MATERIAL allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint
    ) public onlyOwner {
        massUpdatePools();

        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(
            _allocPoint
        );
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // View function to see pending Materials on frontend.
    function pendingMaterial(uint256 _pid, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accMaterialPerShare = pool.accMaterialPerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (_pid == 0) {
            lpSupply = cakePoolBalance;
        }
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 materialReward =(block.number.sub(pool.lastRewardBlock))
                    .mul(materialPerBlock).mul(pool.allocPoint).div(
                    totalAllocPoint
                );
            accMaterialPerShare = accMaterialPerShare.add(
                materialReward.mul(1e30).div(lpSupply)
            );
        }
        return user.amount.mul(accMaterialPerShare).div(1e30).sub(user.rewardDebt);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (_pid == 0) {
            lpSupply = cakePoolBalance;
        }
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 materialReward =(block.number.sub(pool.lastRewardBlock))
                .mul(materialPerBlock).mul(pool.allocPoint).div(
                totalAllocPoint
            );
            
        pool.accMaterialPerShare = pool.accMaterialPerShare.add(
            materialReward.mul(1e30).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    // Deposit tokens (not CAKE) to ClayFarm for CLAY allocation.
    // this contract must be assigned as MinterRole for the Material contract
    function deposit(uint256 _pid, uint256 _amount) public nonReentrant {
        require(_pid != 0, "can not stake CAKE in this pool");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accMaterialPerShare).div(1e30).sub(
                    user.rewardDebt
                );
            materials.mint(msg.sender, materialId, pending, "materialId minted!");
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
            );
            user.amount = user.amount.add(_amount);
        }

        user.rewardDebt = user.amount.mul(pool.accMaterialPerShare).div(1e30);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw tokens (not CAKE) and Harvest material from ClayFarm for CLAY allocation.
    // this contract must be assigned as MinterRole for the Material contract
    function withdraw(uint256 _pid, uint256 _amount) public nonReentrant {
        require(_pid != 0, "can not withdraw CAKE in this pool");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending =
            user.amount.mul(pool.accMaterialPerShare).div(1e30).sub(
                user.rewardDebt
            );
        if (pending > 0) {
            materials.mint(msg.sender, materialId, pending, "materialId minted");
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }

        user.rewardDebt = user.amount.mul(pool.accMaterialPerShare).div(1e30);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Deposit CAKE to ClayFarm for CLAY allocation.
    // this contract must be assigned as MinterRole for the Material contract
    function depositCAKE(uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        updatePool(0);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accMaterialPerShare).div(1e30).sub(
                    user.rewardDebt
                );
            if (pending > 0) {
                materials.mint(msg.sender, materialId, pending, "materialId minted!");
            }
        }
        if (_amount > 0) {
            // pool.lpToken == cakeToken
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            cakePoolBalance = cakePoolBalance.add(_amount);
            cakeToken.safeIncreaseAllowance(_cakeFarm, _amount);
            cakeFarm.enterStaking(_amount);

            user.amount = user.amount.add(_amount);
        }

        user.rewardDebt = user.amount.mul(pool.accMaterialPerShare).div(1e30);
        emit Deposit(msg.sender, 0, _amount);
    }

    // Withdraw CAKE and Harvest material from ClayFarm for CLAY allocation.
    // this contract must be assigned as MinterRole for the Material contract
    function withdrawCAKE(uint256 _amount) public nonReentrant {
        PoolInfo storage pool = poolInfo[0];
        UserInfo storage user = userInfo[0][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(0);
        uint256 pending =
            user.amount.mul(pool.accMaterialPerShare).div(1e30).sub(
                user.rewardDebt
            );
        if (pending > 0) {
            materials.mint(msg.sender, materialId, pending, "materialId minted");
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            // pool.lpToken == cakeToken
            cakeFarm.leaveStaking(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
            cakePoolBalance = cakePoolBalance.sub(_amount);
        }

        user.rewardDebt = user.amount.mul(pool.accMaterialPerShare).div(1e30);
        emit Withdraw(msg.sender, 0, _amount);
    }

    function withdrawBonus(uint256 _amount) public onlyOwner {
        uint256 cakeBal = cakeToken.balanceOf(address(this));
        require(_amount <= cakeBal && _amount > 0, "withdraw bonus exceeds contract's balance");

        cakeToken.safeTransfer(devaddr, _amount);
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }
}