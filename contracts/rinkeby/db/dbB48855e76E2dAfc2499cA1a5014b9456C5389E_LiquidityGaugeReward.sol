pragma solidity ^0.6.0;


interface IController {
    function period() external view returns(int128);
    function periodWrite() external returns(int128);
    function periodTimestamp(int128 p) external view returns(uint256);
    function gaugeRelativeWeight(address addr, uint256 time) external view returns(uint256);
    function votingEscrow() external view returns(address);
    function checkpoint() external;
    function checkpointGauge(address addr) external;
}

pragma solidity ^0.6.0;


interface IMinter {
    function token() external view returns(address);
    function controller() external view returns(address);
    function minted(address user, address gauge) external view returns(uint256);
}

pragma solidity ^0.6.0;


interface IRewards {
    function stake(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function getReward() external;
    function earned(address addr) external view returns(uint256);
}

pragma solidity ^0.6.0;

interface IVotingEscrow {
    function getLastUserSlope(address addr) external view returns(int128);
    function lockedEnd(address addr) external view returns(uint256);
    function userPointEpoch(address addr) external view returns(uint256);
    function userPointHistoryTs(address addr, uint256 epoch) external view returns(uint256);
    function balanceOfAt(address addr, uint256 _block) external view returns(uint256);
    function lockStarts(address addr) external view returns(uint256);
}

pragma solidity ^0.6.0;


interface IXBEInflation {
    function futureEpochTimeWrite() external returns(uint256);
    function rate() external view returns(uint256);
}

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "../interfaces/IMinter.sol";
import "../interfaces/IRewards.sol";
import "../interfaces/IXBEInflation.sol";
import "../interfaces/IController.sol";
import "../interfaces/IVotingEscrow.sol";


contract LiquidityGaugeReward is Initializable, ReentrancyGuard {

    event Deposit(address indexed provider, uint256 value);
    event Withdraw(address indexed provider, uint256 value);
    event UpdateLiquidityLimit(
        address user,
        uint256 originalBalance,
        uint256 originalSupply,
        uint256 workingBalance,
        uint256 workingSupply
    );
    event CommitOwnership(address admin);
    event ApplyOwnership(address admin);
    event Kicked(address addr);

    uint256 public constant TOKENLESS_PRODUCTION = 40;
    uint256 public constant WEEK = 604800;

    uint256 public boostWarmup; //= 2 * 7 * 86400;
    address public minter;
    address public xbeInflation;
    address public lpToken;
    address public controller;
    address public votingEscrow;

    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;
    uint256 public futureEpochTime;

    // # caller -> recipient -> can deposit?
    mapping(address => mapping(address => bool)) public approvedToDeposit;

    mapping(address => uint256) public workingBalances;
    uint256 public workingSupply;

    // # The goal is to be able to calculate ∫(rate * balance / totalSupply dt) from 0 till checkpoint
    // # All values are kept in units of being multiplied by 1e18
    int128 public period;

    // uint256[100000000000000000000000000000]
    mapping(uint256 => uint256) public periodTimestamp;

    // # 1e18 * ∫(rate(t) / totalSupply(t) dt) from 0 till checkpoint
    // uint256[100000000000000000000000000000]
    mapping(uint256 => uint256) public integrateInvSupply; // # bump epoch when rate() changes

    // # 1e18 * ∫(rate(t) / totalSupply(t) dt) from (last_action) till checkpoint
    mapping(address => uint256) public integrateInvSupplyOf;
    mapping(address => uint256) public integrateCheckpointOf;

    // # ∫(balance * rate(t) / totalSupply(t) dt) from 0 till checkpoint
    // # Units: rate * t = already number of coins per address to issue
    mapping(address => uint256) public integrateFraction; // amounts to mint to user

    uint256 public inflationRate;

    // # For tracking external rewards
    address public rewardContract;
    address public rewardedToken;

    uint256 public rewardIntegral;
    mapping(address => uint256) public rewardIntegralFor;
    mapping(address => uint256) public rewardsFor;
    mapping(address => uint256) public claimedRewardsFor;

    address public admin;
    address public futureAdmin;
    bool public isKilled;
    bool public isClaimingRewards;


    // """
    // @notice Contract constructor
    // @param lp_addr Liquidity Pool contract address
    // @param _minter Minter contract address
    // @param _reward_contract Synthetix reward contract address
    // @param _rewarded_token Received synthetix token contract address
    // @param _admin Admin who can kill the gauge
    // """
    function initialize(
        address lpAddr,
        address _minter,
        address _rewardContract,
        address _rewardedToken,
        address _admin,
        uint256 _boostWarmup
    ) external initializer {
        require(lpAddr != address(0), "lpIsZero");
        require(_minter != address(0), "minterIsZero");
        require(_rewardContract != address(0), "rewardContractIsZero");

        boostWarmup = _boostWarmup;
        lpToken = lpAddr;
        minter = _minter;
        address xbeInflationAddr = IMinter(_minter).token();
        xbeInflation = xbeInflationAddr;
        address controllerAddr = IMinter(_minter).controller();
        controller = controllerAddr;
        votingEscrow = IController(controllerAddr).votingEscrow();
        periodTimestamp[0] = block.timestamp;
        IXBEInflation xbeInflationContract = IXBEInflation(xbeInflationAddr);
        inflationRate = xbeInflationContract.rate();
        futureEpochTime = xbeInflationContract.futureEpochTimeWrite();
        rewardContract = _rewardContract;
        require(IERC20(lpAddr).approve(_rewardContract, uint256(-1)), "!approve");
        rewardedToken = _rewardedToken;
        admin = _admin;
        isClaimingRewards = true;
    }

    // """
    // @notice Calculate limits which depend on the amount of CRV token per-user.
    //         Effectively it calculates working balances to apply amplification
    //         of CRV production by CRV
    // @param addr User address
    // @param l User's amount of liquidity (LP tokens)
    // @param L Total amount of liquidity (LP tokens)
    // """
    function _updateLiquidityLimit(address addr, uint256 l, uint256 L) internal {
        // # To be called after totalSupply is updated
        address _votingEscrow = votingEscrow;
        uint256 votingBalance = IERC20(_votingEscrow).balanceOf(addr);
        uint256 votingTotal = IERC20(_votingEscrow).totalSupply();

        uint256 lim = l * TOKENLESS_PRODUCTION / 100;
        if (votingTotal > 0 && block.timestamp > periodTimestamp[0] + boostWarmup) {
            lim += L * votingBalance / votingTotal * (100 - TOKENLESS_PRODUCTION) / 100;
        }

        lim = Math.min(l, lim);
        uint256 oldBal = workingBalances[addr];
        workingBalances[addr] = lim;
        uint256 _workingSupply = workingSupply + lim - oldBal;
        workingSupply = _workingSupply;

        emit UpdateLiquidityLimit(addr, l, L, lim, _workingSupply);
    }


    // """
    // @notice Calculate limits which depend on the amount of CRV token per-user.
    //         Effectively it calculates working balances to apply amplification
    //         of CRV production by CRV
    // @param addr User address
    // @param l User's amount of liquidity (LP tokens)
    // @param L Total amount of liquidity (LP tokens)
    // """
    function _checkpointRewards(address addr, bool claimRewards) internal {
        // # Update reward integrals (no gauge weights involved: easy)
        address _rewardedToken = rewardedToken;

        uint256 dReward = 0;
        if (claimRewards) {
            dReward = IERC20(_rewardedToken).balanceOf(address(this));
            IRewards(rewardContract).getReward();
            dReward = IERC20(_rewardedToken).balanceOf(address(this)) - dReward;
        }

        uint256 userBalance = balanceOf[addr];
        uint256 totalBalance = totalSupply;
        uint256 dI = 0;
        if (totalBalance > 0) {
            dI = 10 ** 18 * dReward / totalBalance;
        }
        uint256 I = rewardIntegral + dI;
        rewardIntegral = I;
        rewardsFor[addr] += userBalance * (I - rewardIntegralFor[addr]) / 10 ** 18;
        rewardIntegralFor[addr] = I;
    }

    // """
    // @notice Checkpoint for a user
    // @param addr User address
    // """
    function _checkpoint(address addr, bool claimRewards) internal {

        address _token = xbeInflation;
        address _controller = controller;
        int128 _period = period;
        require(_period >= 0, "cannotCastPeriodToUint256");
        uint256 _periodTime = periodTimestamp[uint256(_period)];
        uint256 _integrateInvSupply = integrateInvSupply[(uint256(_period))];
        uint256 rate = inflationRate;
        uint256 newRate = rate;
        uint256 prevFutureEpoch = futureEpochTime;
        if (prevFutureEpoch >= _periodTime) {
            futureEpochTime = IXBEInflation(_token).futureEpochTimeWrite();
            newRate = IXBEInflation(_token).rate();
            inflationRate = newRate;
        }
        IController(_controller).checkpointGauge(address(this));

        uint256 _workingBalance = workingBalances[addr];
        uint256 _workingSupply = workingSupply;

        if (isKilled) {
            rate = 0;
        }

        // # Update integral of 1/supply
        if (block.timestamp > _periodTime) {
            uint256 prevWeekTime = _periodTime;
            uint256 weekTime = Math.min((_periodTime + WEEK) / WEEK * WEEK, block.timestamp);

            for (uint256 i = 0; i < 500; i++) {
                uint256 dt = weekTime - prevWeekTime;
                uint256 w = IController(_controller).gaugeRelativeWeight(address(this), prevWeekTime / WEEK * WEEK);

                if (_workingSupply > 0) {
                    if (prevFutureEpoch >= prevWeekTime && prevFutureEpoch < weekTime) {
                        // # If we went across one or multiple epochs, apply the rate
                        // # of the first epoch until it ends, and then the rate of
                        // # the last epoch.
                        // # If more than one epoch is crossed - the gauge gets less,
                        // # but that'd meen it wasn't called for more than 1 year
                        _integrateInvSupply += rate * w * (prevFutureEpoch - prevWeekTime) / _workingSupply;
                        rate = newRate;
                        _integrateInvSupply += rate * w * (weekTime - prevFutureEpoch) / workingSupply;
                    } else {
                        _integrateInvSupply += rate * w * dt / _workingSupply;
                    }
                    // # On precisions of the calculation
                    // # rate ~= 10e18
                    // # last_weight > 0.01 * 1e18 = 1e16 (if pool weight is 1%)
                    // # _working_supply ~= TVL * 1e18 ~= 1e26 ($100M for example)
                    // # The largest loss is at dt = 1
                    // # Loss is 1e-9 - acceptable
                }

                if (weekTime == block.timestamp) {
                    break;
                }
                prevWeekTime = weekTime;
                weekTime = Math.min(weekTime + WEEK, block.timestamp);
            }
        }

        _period += 1;
        period = _period;
        periodTimestamp[uint256(_period)] = block.timestamp;
        integrateInvSupply[uint256(_period)] = _integrateInvSupply;

        // # Update user-specific integrals
        integrateFraction[addr] += _workingBalance * (_integrateInvSupply - integrateInvSupplyOf[addr]) / 10 ** 18;
        integrateInvSupplyOf[addr] = _integrateInvSupply;
        integrateCheckpointOf[addr] = block.timestamp;

        _checkpointRewards(addr, claimRewards);
    }

    // """
    // @notice Record a checkpoint for `addr`
    // @param addr User address
    // @return bool success
    // """
    function userCheckpoint(address addr) external returns(bool) {
        require(msg.sender == addr || msg.sender == minter, "unauthorized");
        _checkpoint(addr, isClaimingRewards);
        _updateLiquidityLimit(addr, balanceOf[addr], totalSupply);
        return true;
    }

    // """
    // @notice Get the number of claimable tokens per user
    // @dev This function should be manually changed to "view" in the ABI
    // @return uint256 number of claimable tokens per user
    // """
    function claimableTokens(address addr) external returns(uint256) {
        _checkpoint(addr, true);
        return integrateFraction[addr] - IMinter(minter).minted(addr, address(this));
    }

    // """
    // @notice Get the number of claimable reward tokens for a user
    // @param addr Account to get reward amount for
    // @return uint256 Claimable reward token amount
    // """
    function claimableReward(address addr) external view returns(uint256) {
        uint256 dReward = IRewards(rewardContract).earned(address(this));
        uint256 userBalance = balanceOf[addr];
        uint256 totalBalance = totalSupply;
        uint256 dI = 0;
        if (totalBalance > 0) {
            dI = 10 ** 18 * dReward / totalBalance;
        }
        uint256 I = rewardIntegral + dI;
        return rewardsFor[addr] + userBalance * (I - rewardIntegralFor[addr]) / 10 ** 18;
    }

    // """
    // @notice Kick `addr` for abusing their boost
    // @dev Only if either they had another voting event, or their voting escrow lock expired
    // @param addr Address to kick
    // """
    function kick(address addr) external {
        address _votingEscrow = votingEscrow;
        uint256 tLast = integrateCheckpointOf[addr];
        uint256 tVe = IVotingEscrow(_votingEscrow).userPointHistoryTs(
            addr, IVotingEscrow(_votingEscrow).userPointEpoch(addr)
        );
        uint256 _balance = balanceOf[addr];

        require(IERC20(votingEscrow).balanceOf(addr) == 0 || tVe > tLast, "kickNotAllowed"); // # dev: kick not allowed
        require(workingBalances[addr] > (_balance * TOKENLESS_PRODUCTION) / 100, "kickNotNeeded"); // kick not needed

        _checkpoint(addr, isClaimingRewards);
        _updateLiquidityLimit(addr, _balance, totalSupply);
        emit Kicked(addr);
    }

    // """
    // @notice Set whether `addr` can deposit tokens for `msg.sender`
    // @param addr Address to set approval on
    // @param can_deposit bool - can this account deposit for `msg.sender`?
    // """
    function setApproveDeposit(address addr, bool canDeposit) external {
        approvedToDeposit[addr][msg.sender] = canDeposit;
    }

    // """
    // @notice Deposit `_value` LP tokens
    // @param _value Number of tokens to deposit
    // @param addr Address to deposit for
    // """
    function deposit(uint256 _value, address addr) public nonReentrant {
        if (addr != msg.sender) {
            require(approvedToDeposit[msg.sender][addr], "notApproved");
        }

        _checkpoint(addr, true);

        if (_value != 0) {
            uint256 _balance = balanceOf[addr] + _value;
            uint256 _supply = totalSupply + _value;
            balanceOf[addr] = _balance;
            totalSupply = _supply;

            _updateLiquidityLimit(addr, _balance, _supply);

            require(IERC20(lpToken).transferFrom(addr, address(this), _value), "!transferFrom");
            IRewards(rewardContract).stake(_value);
        }

        emit Deposit(addr, _value);
    }

    function deposit(uint256 _value) external {
        deposit(_value, msg.sender);
    }

    // """
    // @notice Withdraw `_value` LP tokens
    // @param _value Number of tokens to withdraw
    // """
    function withdraw(uint256 _value, bool claimRewards) public nonReentrant {
        _checkpoint(msg.sender, claimRewards);

        uint256 _balance = balanceOf[msg.sender] - _value;
        uint256 _supply = totalSupply - _value;
        balanceOf[msg.sender] = _balance;
        totalSupply = _supply;

        _updateLiquidityLimit(msg.sender, _balance, _supply);

        if (_value > 0) {
            IRewards(rewardContract).withdraw(_value);
            require(IERC20(lpToken).transfer(msg.sender, _value));
        }

        emit Withdraw(msg.sender, _value);
    }

    function withdraw(uint256 _value) external {
        withdraw(_value, true);
    }

    function claimRewards(address addr) external nonReentrant {
        _checkpointRewards(addr, true);
        uint256 _rewardsFor = rewardsFor[addr];
        require(IERC20(rewardedToken).transfer(
          addr, _rewardsFor - claimedRewardsFor[addr]
        ), "!transfer");
        claimedRewardsFor[addr] = _rewardsFor;
    }

    function integrateCheckpoint() external view returns(uint256) {
        require(period >= 0, "cannotCastPeriodToUint256");
        return periodTimestamp[uint256(period)];
    }

    function killMe() external {
        require(msg.sender == admin, "!admin");
        isKilled = !isKilled;
    }

    // """
    // @notice Transfer ownership of GaugeController to `addr`
    // @param addr Address to have ownership transferred to
    // """
    function commitTransferOwnership(address addr) external {
        require(msg.sender == admin, "!admin");
        futureAdmin = addr;
        emit CommitOwnership(addr);
    }

    // """
    // @notice Apply pending ownership transfer
    // """
    function applyTransferOwnership() external {
        require(msg.sender == admin, "!admin");
        address _admin = futureAdmin;
        require(_admin != address(0), "!zeroAdmin");
        admin = _admin;
        emit ApplyOwnership(_admin);
    }

    // """
    // @notice Switch claiming rewards on/off.
    //         This is to prevent a malicious rewards contract from preventing CRV claiming
    // """
    function toggleExternalRewardsClaim(bool val) external {
        require(msg.sender == admin, "!admin");
        isClaimingRewards = val;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
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

pragma solidity >=0.6.2 <0.8.0;

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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 1
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}