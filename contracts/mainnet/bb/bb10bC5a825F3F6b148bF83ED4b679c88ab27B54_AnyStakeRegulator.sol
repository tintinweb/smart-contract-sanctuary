// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "./lib/@defiat-crypto/interfaces/IDeFiatPoints.sol";
import "./interfaces/IAnyStakeMigrator.sol";
import "./interfaces/IAnyStakeRegulator.sol";
import "./interfaces/IAnyStakeVault.sol";
import "./utils/AnyStakeUtils.sol";

contract AnyStakeRegulator is IAnyStakeRegulator, AnyStakeUtils {
    using SafeMath for uint256;

    event Initialized(address indexed user, address vault);
    event Claim(address indexed user, uint256 amount);
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Migrate(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event StakingFeeUpdated(address indexed user, uint256 stakingFee);
    event BuybackRateUpdated(address indexed user, uint256 buybackRate);
    event PriceMultiplierUpdated(address indexed user, uint256 amount);
    event MigratorUpdated(address indexed user, address migrator);
    event VaultUpdated(address indexed user, address vault);
    event RegulatorActive(address indexed user, bool active);

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 lastRewardBlock;
    }

    mapping (address => UserInfo) public userInfo;
    
    address public migrator;
    address public vault;

    bool public active; // staking is active
    bool public initialized; // contract has been initialized
    uint256 public stakingFee; // fee taken on withdrawals
    uint256 public priceMultiplier; // price peg control, DFT_PRICE = (DFTP_PRICE * priceMultiplier) / 1000
    uint256 public lastRewardBlock; // last block that rewards were received
    uint256 public buybackBalance; // total pending DFT awaiting stabilization
    uint256 public buybackRate; // rate of rewards stockpiled for stabilization
    uint256 public rewardsPerShare; // DFT rewards per DFTP, times 1e18 to prevent underflow
    uint256 public pendingRewards; // total pending DFT rewards
    uint256 public totalShares; // total staked shares

    modifier NoReentrant(address user) {
        require(
            block.number > userInfo[user].lastRewardBlock,
            "Regulator: Must wait 1 block"
        );
        _;
    }

    modifier onlyVault() {
        require(msg.sender == vault, "AnyStake: Only Vault allowed");
        _;
    }

    modifier activated() {
        require(initialized, "Regulator: Not initialized yet");
        _;
    }

    constructor(address _router, address _gov, address _points, address _token) 
        public 
        AnyStakeUtils(_router, _gov, _points, _token)
    {
        priceMultiplier = 10000; // 10000 / 1000 = 10:1
        stakingFee = 100; // 10%
        buybackRate = 300; // 30%
    }

    function initialize(address _vault) external onlyGovernor {
        require(_vault != address(0), "Initialize: Must pass in Vault");
        require(!initialized, "Initialize: Regulator already initialized");

        vault = _vault;
        active = true;
        initialized = true;
        emit Initialized(msg.sender, vault);
    }

    function stabilize(uint256 amount) internal {
        if (isAbovePeg()) {
            // Above Peg: sell DFTP, buy DFT, add to rewards

            IERC20(DeFiatPoints).transfer(vault, amount);
            IAnyStakeVault(vault).buyDeFiatWithTokens(DeFiatPoints, amount);
        } else {
            // Below Peg: sell DFT, buy DFTP, burn all proceeds (deflationary)

            IAnyStakeVault(vault).buyPointsWithTokens(DeFiatToken, buybackBalance);
            IDeFiatPoints(DeFiatPoints).burn(amount);
            IDeFiatPoints(DeFiatPoints).overrideLoyaltyPoints(vault, 0);
            buybackBalance = 0;
        }
    }

    // Pool - Add rewards
    function addReward(uint256 amount) external override onlyVault {
        if (amount == 0) {
            return;
        }

        uint256 buybackAmount = amount.mul(buybackRate).div(1000);
        uint256 rewardAmount = amount.sub(buybackAmount);

        if (buybackAmount > 0) {
            buybackBalance = buybackBalance.add(buybackAmount);
        }

        if (rewardAmount > 0) {
            pendingRewards = pendingRewards.add(rewardAmount);
        }
    }

    // Pool - Update pool rewards, pull from Vault
    function updatePool() external override {
        _updatePool();
    }

    // Pool - Update pool internal
    function _updatePool() internal {
        if (totalShares == 0 || block.number <= lastRewardBlock || !active) {
            return;
        }

        // calculate rewards, calls addReward()
        IAnyStakeVault(vault).calculateRewards();

        // update rewardsPerShare            
        rewardsPerShare = rewardsPerShare.add(pendingRewards.mul(1e18).div(totalShares));
        lastRewardBlock = block.number;
        pendingRewards = 0;
    }

    function claim() external override activated NoReentrant(msg.sender) {
        _updatePool();
        _claim(msg.sender);
    }

    // Pool - Claim internal
    function _claim(address _user) internal {
        // get pending rewards
        UserInfo storage user = userInfo[_user];
        uint256 rewards = pending(_user);
        if (rewards == 0) {
            return;
        }

        // update pool / user metrics
        user.rewardDebt = user.amount.mul(rewardsPerShare).div(1e18);
        user.lastRewardBlock = block.number;
        
        // transfer
        IAnyStakeVault(vault).distributeRewards(_user, rewards);
        emit Claim(_user, rewards);
    }

    // Pool - Deposit DeFiat Points (DFTP) to earn DFT and stablize token prices
    function deposit(uint256 amount) external override activated NoReentrant(msg.sender) {
        _updatePool();
        _deposit(msg.sender, amount);
    }

    // Pool - deposit internal, perform the stablization
    function _deposit(address _user, uint256 _amount) internal {
        UserInfo storage user = userInfo[_user];
        require(_amount > 0, "Deposit: Cannot deposit zero tokens");

        _claim(_user);

        // update pool / user metrics
        totalShares = totalShares.add(_amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(rewardsPerShare).div(1e18);

        IERC20(DeFiatPoints).transferFrom(_user, address(this), _amount);
        emit Deposit(_user, _amount);
    }

    // Pool - Withdraw function, currently unused
    function withdraw(uint256 amount) external override NoReentrant(msg.sender) {
        _updatePool();
        _withdraw(msg.sender, amount); // internal, unused
    }

    // Pool - Withdraw internal, unused
    function _withdraw(address _user, uint256 _amount) internal {
        UserInfo storage user = userInfo[_user];
        require(_amount <= user.amount, "Withdraw: Not enough staked");

        _claim(_user);

        uint256 feeAmount = _amount.mul(stakingFee).div(1000);
        uint256 remainingUserAmount = _amount.sub(feeAmount);

        if (feeAmount > 0) {
            stabilize(feeAmount);
        }

        totalShares = totalShares.sub(_amount);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(rewardsPerShare).div(1e18);

        IERC20(DeFiatPoints).transfer(_user, remainingUserAmount);
        emit Withdraw(_user, remainingUserAmount);
    }

    function migrate() external override NoReentrant(msg.sender) {
        _updatePool();
        _migrate(msg.sender);
    }

    function _migrate(address _user) internal {
        UserInfo storage user = userInfo[_user];
        uint256 balance = user.amount;

        require(migrator != address(0), "Migrate: No migrator set");
        require(balance > 0, "Migrate: No tokens to migrate");

        IERC20(DeFiatPoints).approve(migrator, balance);
        IAnyStakeMigrator(migrator).migrateTo(_user, DeFiatPoints, balance);
        emit Migrate(_user, balance);
    }

    // Emergency withdraw all basis, burn the staking fee
    function emergencyWithdraw() external NoReentrant(msg.sender) {
        UserInfo storage user = userInfo[msg.sender];

        require(user.amount > 0, "EmergencyWithdraw: user amount insufficient");

        uint256 feeAmount = user.amount.mul(stakingFee).div(1000);
        uint256 remainingUserAmount = user.amount.sub(feeAmount);
        totalShares = totalShares.sub(user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        user.lastRewardBlock = block.number;

        IDeFiatPoints(DeFiatPoints).burn(feeAmount);
        safeTokenTransfer(msg.sender, DeFiatPoints, remainingUserAmount);
        emit EmergencyWithdraw(msg.sender, remainingUserAmount);
    }

    function isAbovePeg() public view returns (bool) {
        uint256 tokenPrice = IAnyStakeVault(vault).getTokenPrice(DeFiatToken, DeFiatTokenLp);
        uint256 pointsPrice = IAnyStakeVault(vault).getTokenPrice(DeFiatPoints, DeFiatPointsLp);
        
        return pointsPrice.mul(priceMultiplier).div(1000) > tokenPrice;
    }

    // View - Pending DFT Rewards for user in pool
    function pending(address _user)
        public
        view
        returns (uint256)
    {
        UserInfo memory user = userInfo[_user];
        return user.amount.mul(rewardsPerShare).div(1e18).sub(user.rewardDebt);
    }


    // Governance - Set Staking Fee
    function setStakingFee(uint256 _stakingFee) external onlyGovernor {
        require(_stakingFee != stakingFee, "SetFee: No fee change");
        require(_stakingFee <= 1000, "SetFee: Fee cannot exceed 100%");

        stakingFee = _stakingFee;
        emit StakingFeeUpdated(msg.sender, stakingFee);
    }

    // Governance - Set Buyback Rate
    function setBuybackRate(uint256 _buybackRate) external onlyGovernor {
        require(_buybackRate != buybackRate, "SetBuybackRate: No rate change");
        require(_buybackRate <= 1000, "SetBuybackRate: Cannot exceed 100%");

        buybackRate = _buybackRate;
        emit BuybackRateUpdated(msg.sender, buybackRate);
    }

    // Governance - Set DeFiat Points price multiplier
    function setPriceMultiplier(uint256 _priceMultiplier) external onlyGovernor {
        require(_priceMultiplier != priceMultiplier, "SetMultiplier: No multiplier change");
        require(_priceMultiplier > 0, "SetMultiplier: Must be greater than zero");

        priceMultiplier = _priceMultiplier;
        emit PriceMultiplierUpdated(msg.sender, priceMultiplier);
    }

    // Governance - Set Migrator
    function setMigrator(address _migrator) external onlyGovernor {
        require(_migrator != address(0), "SetMigrator: No migrator change");

        migrator = _migrator;
        emit MigratorUpdated(msg.sender, _migrator);
    }
    
    // Governance - Set Vault
    function setVault(address _vault) external onlyGovernor {
        require(_vault != address(0), "SetVault: No migrator change");

        vault = _vault;
        emit VaultUpdated(msg.sender, vault);
    }

    // Governance - Set Pool Deposits active
    function setActive(bool _active) external onlyGovernor {
        require(_active != active, "SetActive: No active change");
        
        active = _active;
        emit RegulatorActive(msg.sender, active);
    }
}

// SPDX-License-Identifier: MIT


pragma solidity 0.6.6;

interface IAnyStakeMigrator {
    function migrateTo(address user, address token, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

interface IAnyStakeRegulator {
    function addReward(uint256 amount) external;
    function claim() external;
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function migrate() external;
    function updatePool() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

interface IAnyStakeVault {
    function buyDeFiatWithTokens(address token, uint256 amount) external;
    function buyPointsWithTokens(address token, uint256 amount) external;

    function calculateRewards() external;
    function distributeRewards(address recipient, uint256 amount) external;
    function getTokenPrice(address token, address lpToken) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

interface IDeFiatGov {
    function mastermind() external view returns (address);
    function viewActorLevelOf(address _address) external view returns (uint256);
    function viewFeeDestination() external view returns (address);
    function viewTxThreshold() external view returns (uint256);
    function viewBurnRate() external view returns (uint256);
    function viewFeeRate() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

interface IDeFiatPoints {
    function viewDiscountOf(address _address) external view returns (uint256);
    function viewEligibilityOf(address _address) external view returns (uint256 tranche);
    function discountPointsNeeded(uint256 _tranche) external view returns (uint256 pointsNeeded);
    function viewTxThreshold() external view returns (uint256);
    function viewRedirection(address _address) external view returns (bool);

    function overrideLoyaltyPoints(address _address, uint256 _points) external;
    function addPoints(address _address, uint256 _txSize, uint256 _points) external;
    function burn(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "./DeFiatUtils.sol";
import "../interfaces/IDeFiatGov.sol";

abstract contract DeFiatGovernedUtils is DeFiatUtils {
    event GovernanceUpdated(address indexed user, address governance);

    address public governance;

    modifier onlyMastermind {
        require(
            msg.sender == IDeFiatGov(governance).mastermind() || msg.sender == owner(),
            "Gov: Only Mastermind"
        );
        _;
    }

    modifier onlyGovernor {
        require(
            IDeFiatGov(governance).viewActorLevelOf(msg.sender) >= 2 || msg.sender == owner(),
            "Gov: Only Governors"
        );
        _;
    }

    modifier onlyPartner {
        require(
            IDeFiatGov(governance).viewActorLevelOf(msg.sender) >= 1 || msg.sender == owner(),
            "Gov: Only Partners"
        );
        _;
    }

    function _setGovernance(address _governance) internal {
        require(_governance != governance, "SetGovernance: No governance change");

        governance = _governance;
        emit GovernanceUpdated(msg.sender, governance);
    }

    function setGovernance(address _governance) external onlyGovernor {
        _setGovernance(_governance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "../../@openzeppelin/token/ERC20/IERC20.sol";
import "../../@openzeppelin/access/Ownable.sol";

abstract contract DeFiatUtils is Ownable {
    event TokenSweep(address indexed user, address indexed token, uint256 amount);

    // Sweep any tokens/ETH accidentally sent or airdropped to the contract
    function sweep(address token) public virtual onlyOwner {
        uint256 amount = IERC20(token).balanceOf(address(this));
        require(amount > 0, "Sweep: No token balance");

        IERC20(token).transfer(msg.sender, amount); // use of the ERC20 traditional transfer

        if (address(this).balance > 0) {
            payable(msg.sender).transfer(address(this).balance);
        }

        emit TokenSweep(msg.sender, token, amount);
    }

    // Self-Destruct contract to free space on-chain, sweep any ETH to owner
    function kill() external onlyOwner {
        selfdestruct(payable(msg.sender));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

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

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

interface IERC20 {
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);

    // Standard
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

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
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
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

pragma solidity 0.6.6;

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

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.6;

import "../lib/@defiat-crypto/utils/DeFiatUtils.sol";
import "../lib/@defiat-crypto/utils/DeFiatGovernedUtils.sol";
import "../lib/@openzeppelin/token/ERC20/SafeERC20.sol";
import "../lib/@uniswap/interfaces/IUniswapV2Factory.sol";
import "../lib/@uniswap/interfaces/IUniswapV2Router02.sol";

abstract contract AnyStakeUtils is DeFiatGovernedUtils {
    using SafeERC20 for IERC20;

    event PointsUpdated(address indexed user, address points);
    event TokenUpdated(address indexed user, address token);
    event UniswapUpdated(address indexed user, address router, address weth, address factory);
  
    address public router;
    address public factory;
    address public weth;
    address public DeFiatToken;
    address public DeFiatPoints;
    address public DeFiatTokenLp;
    address public DeFiatPointsLp;

    mapping (address => bool) internal _blacklistedAdminWithdraw;

    constructor(address _router, address _gov, address _points, address _token) public {
        _setGovernance(_gov);

        router = _router;
        DeFiatPoints = _points;
        DeFiatToken = _token;
         
        weth = IUniswapV2Router02(router).WETH();
        factory = IUniswapV2Router02(router).factory();
        DeFiatTokenLp = IUniswapV2Factory(factory).getPair(_token, weth);
        DeFiatPointsLp = IUniswapV2Factory(factory).getPair(_points, weth);
    }

    function sweep(address _token) public override onlyOwner {
        require(!_blacklistedAdminWithdraw[_token], "Sweep: Cannot withdraw blacklisted token");

        DeFiatUtils.sweep(_token);
    }

    function isBlacklistedAdminWithdraw(address _token)
        external
        view
        returns (bool)
    {
        return _blacklistedAdminWithdraw[_token];
    }

    // Method to avoid underflow on token transfers
    function safeTokenTransfer(address user, address token, uint256 amount) internal {
        if (amount == 0) {
            return;
        }

        uint256 tokenBalance = IERC20(token).balanceOf(address(this));
        if (amount > tokenBalance) {
            IERC20(token).safeTransfer(user, tokenBalance);
        } else {
            IERC20(token).safeTransfer(user, amount);
        }
    }

    function setToken(address _token) external onlyGovernor {
        require(_token != DeFiatToken, "SetToken: No token change");
        require(_token != address(0), "SetToken: Must set token value");

        DeFiatToken = _token;
        DeFiatTokenLp = IUniswapV2Factory(factory).getPair(_token, weth);
        emit TokenUpdated(msg.sender, DeFiatToken);
    }

    function setPoints(address _points) external onlyGovernor {
        require(_points != DeFiatPoints, "SetPoints: No points change");
        require(_points != address(0), "SetPoints: Must set points value");

        DeFiatPoints = _points;
        DeFiatPointsLp = IUniswapV2Factory(factory).getPair(_points, weth);
        emit PointsUpdated(msg.sender, DeFiatPoints);
    }

    function setUniswap(address _router) external onlyGovernor {
        require(_router != router, "SetUniswap: No uniswap change");
        require(_router != address(0), "SetUniswap: Must set uniswap value");

        router = _router;
        weth = IUniswapV2Router02(router).WETH();
        factory = IUniswapV2Router02(router).factory();
        emit UniswapUpdated(msg.sender, router, weth, factory);
    }
}

