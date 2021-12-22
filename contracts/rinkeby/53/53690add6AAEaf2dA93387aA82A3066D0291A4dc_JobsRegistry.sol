pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IWorkEvaluator.sol";
import "./interfaces/IBonder.sol";
import "./interfaces/IERC20Permit.sol";
import "./interfaces/ILiquidityWeightCalculator.sol";
import "./interfaces/IJobsRegistry.sol";

error InvalidFee();
error InvalidContentHash();
error InvalidLiquidityTokenPremium();
error ZeroAddressNativeToken();
error ZeroAddressLiquidity();
error ZeroAddressMaster();
error ZeroAddressBonder();
error ZeroAddressFeeReceiver();
error ZeroAddressLiquidityWeightCalculator();
error ZeroAddressJobsCreator();
error NotEnoughCredit();
error Forbidden();
error NonExistentJob();
error JobAlreadyAdded();
error InvalidLiquidity();

/**
 * @title JobsRegistry
 * @dev JobsRegistry contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
contract JobsRegistry is IJobsRegistry, Ownable {
    using SafeERC20 for IERC20;

    uint256 private immutable BASE = 10000;

    mapping(address => Job) internal job;
    mapping(address => address) public liquidityWeightCalculator;
    mapping(address => bool) public jobsCreator;
    uint16 public fee;
    uint16 public liquidityTokenPremium;
    address public nativeToken;
    address public master;
    address public bonder;
    address public feeReceiver;

    constructor(
        uint16 _fee,
        uint16 _liquidityTokenPremium,
        address _nativeToken,
        address _master,
        address _bonder,
        address _feeReceiver
    ) {
        if (_fee >= BASE) revert InvalidFee();
        if (_liquidityTokenPremium >= BASE)
            revert InvalidLiquidityTokenPremium();
        if (_nativeToken == address(0)) revert ZeroAddressNativeToken();
        if (_master == address(0)) revert ZeroAddressMaster();
        if (_bonder == address(0)) revert ZeroAddressBonder();
        if (_feeReceiver == address(0)) revert ZeroAddressFeeReceiver();
        nativeToken = _nativeToken;
        fee = _fee;
        master = _master;
        bonder = _bonder;
        feeReceiver = _feeReceiver;
    }

    function allowLiquidity(address _liquidity, address _weightCalculator)
        external
        override
    {
        if (msg.sender != owner()) revert Forbidden();
        if (_liquidity == address(0)) revert ZeroAddressLiquidity();
        if (_weightCalculator == address(0))
            revert ZeroAddressLiquidityWeightCalculator();
        liquidityWeightCalculator[_liquidity] = _weightCalculator;
        emit AllowLiquidity(_liquidity, _weightCalculator);
    }

    function disallowLiquidity(address _liquidity) external override {
        if (msg.sender != owner()) revert Forbidden();
        if (_liquidity == address(0)) revert ZeroAddressLiquidity();
        liquidityWeightCalculator[_liquidity] = address(0);
        emit DisallowLiquidity(_liquidity);
    }

    function allowJobCreator(address _creator) external override {
        if (msg.sender != owner()) revert Forbidden();
        if (_creator == address(0)) revert ZeroAddressJobsCreator();
        jobsCreator[_creator] = true;
        emit AllowJobsCreator(_creator);
    }

    function disallowJobCreator(address _creator) external override {
        if (msg.sender != owner()) revert Forbidden();
        jobsCreator[_creator] = false;
        emit DisallowJobsCreator(_creator);
    }

    function addJob(address _job, string calldata _contentHash)
        external
        override
    {
        if (msg.sender != owner() && !jobsCreator[msg.sender])
            revert Forbidden();
        if (bytes(_contentHash).length == 0) revert InvalidContentHash();
        Job storage _jobFromStorage = job[_job];
        if (_jobFromStorage.exists) revert JobAlreadyAdded();
        _jobFromStorage.exists = true;
        _jobFromStorage.contentHash = _contentHash;
        emit AddJob(_job, _contentHash);
    }

    // FIXME: any credit previously applied to the job gets lost. Should we do something about it?
    function removeJob(address _job) external override {
        if (msg.sender != owner()) revert Forbidden();
        job[_job].exists = false;
        job[_job].contentHash = "";
        emit RemoveJob(_job);
    }

    function addCredit(
        address _job,
        address _token,
        uint256 _amount
    ) external override {
        _addCredit(_job, _token, _amount);
    }

    function addCreditWithPermit(
        address _job,
        address _token,
        uint256 _amount,
        uint256 _permittedAmount, // can be used for infinite approvals
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override {
        IERC20Permit(nativeToken).permit(
            msg.sender,
            address(this),
            _permittedAmount,
            block.timestamp,
            _v,
            _r,
            _s
        );
        _addCredit(_job, _token, _amount);
    }

    function _addCredit(
        address _job,
        address _token,
        uint256 _amount
    ) internal {
        Job storage _jobFromStorage = job[_job];
        if (!_jobFromStorage.exists) revert NonExistentJob();
        uint256 _fee = (_amount * fee) / BASE;
        _jobFromStorage.credit[_token] += _amount - _fee;
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(_token).safeTransfer(feeReceiver, _fee);
        emit AddCredit(_job, _amount);
    }

    // TODO: consider giving credit at a discount and retaining all the LP token
    function addLiquidityCredit(
        address _job,
        address _liquidity,
        uint256 _amount
    ) external override {
        address _liquidityWeightCalculator = liquidityWeightCalculator[
            _liquidity
        ];
        if (_liquidityWeightCalculator == address(0)) revert InvalidLiquidity();
        Job storage _jobFromStorage = job[_job];
        if (!_jobFromStorage.exists) revert NonExistentJob();
        uint256 _fee = (_amount * fee) / BASE;
        uint256 _nativeTokenLiquidity = ILiquidityWeightCalculator(
            _liquidityWeightCalculator
        ).calculate(_liquidity, _amount - _fee);
        uint256 _nativeTokenCredit = (_nativeTokenLiquidity *
            (BASE + liquidityTokenPremium)) / BASE;
        _jobFromStorage.credit[nativeToken] += _nativeTokenCredit;
        IERC20(nativeToken).safeTransferFrom(
            owner(),
            address(this),
            _nativeTokenCredit
        );
        IERC20(_liquidity).safeTransferFrom(msg.sender, feeReceiver, _amount);
        emit AddLiquidityCredit(_job, _liquidity, _amount);
    }

    function registerWork(
        address _job,
        address _token,
        address _worker,
        uint256 _usedCredit,
        uint256 _usedGas
    ) external override {
        if (msg.sender != master) revert Forbidden();
        Job storage _jobFromStorage = job[_job];
        if (!_jobFromStorage.exists) revert NonExistentJob();
        if (_jobFromStorage.credit[_token] < _usedCredit)
            revert NotEnoughCredit();
        _jobFromStorage.credit[_token] -= _usedCredit;
        // inifinite approval to optimize gas costs
        if (IERC20(_token).allowance(address(this), bonder) < _usedCredit)
            IERC20(_token).approve(
                bonder,
                0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            );
        IBonder(bonder).accrueReward(_worker, _token, _usedCredit);
        emit RegisterWork(_job, _worker, _token, _usedCredit, _usedGas);
    }

    function exists(address _job) external view returns (bool) {
        return job[_job].exists;
    }

    function credit(address _job, address _token)
        external
        view
        override
        returns (uint256)
    {
        return job[_job].credit[_token];
    }

    function setFee(uint16 _fee) external override {
        if (msg.sender != owner()) revert Forbidden();
        if (_fee >= BASE) revert InvalidFee();
        fee = _fee;
        emit SetFee(_fee);
    }

    function setLiquidityTokenPremium(uint16 _liquidityTokenPremium)
        external
        override
    {
        if (msg.sender != owner()) revert Forbidden();
        if (_liquidityTokenPremium >= BASE)
            revert InvalidLiquidityTokenPremium();
        liquidityTokenPremium = _liquidityTokenPremium;
        emit SetLiquidityTokenPremium(_liquidityTokenPremium);
    }

    function setNativeToken(address _nativeToken) external override {
        if (msg.sender != owner()) revert Forbidden();
        if (_nativeToken == address(0)) revert ZeroAddressNativeToken();
        nativeToken = _nativeToken;
        emit SetNativeToken(_nativeToken);
    }

    function setMaster(address _master) external override {
        if (msg.sender != owner()) revert Forbidden();
        if (_master == address(0)) revert ZeroAddressMaster();
        master = _master;
        emit SetMaster(_master);
    }

    function setBonder(address _bonder) external override {
        if (msg.sender != owner()) revert Forbidden();
        if (_bonder == address(0)) revert ZeroAddressBonder();
        bonder = _bonder;
        emit SetBonder(_bonder);
    }

    function setFeeReceiver(address _feeReceiver) external override {
        if (msg.sender != owner()) revert Forbidden();
        if (_feeReceiver == address(0)) revert ZeroAddressFeeReceiver();
        feeReceiver = _feeReceiver;
        emit SetFeeReceiver(_feeReceiver);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity >=0.8.10;

/**
 * @title IWorkEvaluator
 * @dev IWorkEvaluator contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
interface IWorkEvaluator {
    function evaluateCost(address _worker, uint256 _gasUsed)
        external
        returns (uint256);
}

pragma solidity ^0.8.10;

/**
 * @title IBonder
 * @dev IBonder contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
interface IBonder {
    struct Worker {
        bool disallowed;
        uint256 bonded;
        uint256 earned;
        uint256 bonding;
        uint256 bondingTimestamp;
        uint256 unbonding;
        uint256 unbondingTimestamp;
        uint256 activationTimestamp;
    }

    event SetBondingTime(uint32 bondingTime);
    event SetUnbondingTime(uint32 unbondingTime);
    event SetNativeToken(address nativeToken);
    event Bond(address worker, uint256 amount);
    event ConsolidateBond(address worker, uint256 amount);
    event CancelBonding(address worker, uint256 refundedAmount);
    event AccrueReward(address worker, address token, uint256 amount);
    event Unbond(address worker, uint256 amount);
    event ConsolidateUnbonding(address worker, uint256 amount);
    event CancelUnbonding(address worker, uint256 refundedAmount);
    event Slash(address worker, uint256 amount);
    event Disallow(address worker);

    function totalBonded() external view returns (uint256);

    function bondingTime() external view returns (uint32);

    function unbondingTime() external view returns (uint32);

    function nativeToken() external view returns (address);

    function jobsRegistry() external view returns (address);

    function setBondingTime(uint32 _bondingTime) external;

    function setUnbondingTime(uint32 _unbondingTime) external;

    function setNativeToken(address _nativeToken) external;

    function bond(uint256 _amount) external;

    function bondWithPermit(
        uint256 _amount,
        uint256 _permittedAmount, // can be used for infinite approvals
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function consolidateBond() external;

    function cancelBonding() external;

    function accrueReward(
        address _address,
        address _token,
        uint256 _amount
    ) external;

    function unbond(uint256 _amount) external;

    function consolidateUnbonding() external;

    function cancelUnbonding() external;

    function slash(address _worker, uint256 _amount) external;

    function disallow(address _worker) external;

    function bonded(address _address) external view returns (uint256);

    function earned(address _address) external view returns (uint256);

    function disallowed(address _address) external view returns (bool);

    function activationTimestamp(address _address)
        external
        view
        returns (uint256);
}

pragma solidity >=0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IERC20Permit
 * @dev IERC20Permit contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
interface IERC20Permit is IERC20 {
    function mint(address _to, uint256 _amount) external;

    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;
}

pragma solidity >=0.8.10;

/**
 * @title ILiquidityWeightCalculator
 * @dev ILiquidityWeightCalculator contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
interface ILiquidityWeightCalculator {
    function calculate(address _liquidity, uint256 _amount)
        external
        view
        returns (uint256);
}

pragma solidity ^0.8.10;

/**
 * @title IJobsRegistry
 * @dev IJobsRegistry contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
interface IJobsRegistry {
    struct Job {
        bool exists;
        string contentHash;
        mapping(address => uint256) credit;
    }

    event AllowLiquidity(address liquidity, address weightCalculator);
    event DisallowLiquidity(address liquidity);
    event AllowJobsCreator(address creator);
    event DisallowJobsCreator(address creator);
    event AddJob(address job, string contentHash);
    event RemoveJob(address job);
    event AddCredit(address job, uint256 amount);
    event AddLiquidityCredit(address job, address liquidity, uint256 amount);
    event RegisterWork(
        address job,
        address worker,
        address token,
        uint256 reward,
        uint256 usedGas
    );
    event SetFee(uint16 fee);
    event SetLiquidityTokenPremium(uint16 fee);
    event SetNativeToken(address nativeToken);
    event SetMaster(address master);
    event SetBonder(address bonder);
    event SetFeeReceiver(address feeReceiver);

    function liquidityWeightCalculator(address _liquidityToken)
        external
        returns (address);

    function jobsCreator(address _jobsCreator) external returns (bool);

    function fee() external returns (uint16);

    function liquidityTokenPremium() external returns (uint16);

    function nativeToken() external returns (address);

    function master() external returns (address);

    function bonder() external returns (address);

    function feeReceiver() external returns (address);

    function allowLiquidity(address _liquidity, address _weightCalculator)
        external;

    function disallowLiquidity(address _liquidity) external;

    function allowJobCreator(address _creator) external;

    function disallowJobCreator(address _creator) external;

    function addJob(address _job, string calldata _contentHash) external;

    function removeJob(address _job) external;

    function addCredit(
        address _job,
        address _token,
        uint256 _amount
    ) external;

    function addCreditWithPermit(
        address _job,
        address _token,
        uint256 _amount,
        uint256 _permittedAmount, // can be used for infinite approvals
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function addLiquidityCredit(
        address _liquidity,
        address _job,
        uint256 _amount
    ) external;

    function registerWork(
        address _job,
        address _token,
        address _worker,
        uint256 _usedCredit,
        uint256 _usedGas
    ) external;

    function exists(address _job) external view returns (bool);

    function credit(address _job, address _token)
        external
        view
        returns (uint256);

    function setFee(uint16 _fee) external;

    function setLiquidityTokenPremium(uint16 _fee) external;

    function setNativeToken(address _nativeToken) external;

    function setMaster(address _master) external;

    function setBonder(address _bonder) external;

    function setFeeReceiver(address _feeReceiver) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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