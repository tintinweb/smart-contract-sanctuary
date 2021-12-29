// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Owned.sol";
import "./interfaces/vesper/IVesperPool.sol";
import "./interfaces/vesper/IStrategy.sol";
import "./interfaces/vesper/IPoolRewards.sol";
import "../sol-address-list/contracts/interfaces/IAddressList.sol";
import "../sol-address-list/contracts/interfaces/IAddressListFactory.sol";

contract Controller is Owned {
    using SafeMath for uint256;

    // Pool specific params
    mapping(address => uint256) public withdrawFee;
    mapping(address => uint256) public interestFee;
    mapping(address => address) public feeCollector;
    mapping(address => uint256) public rebalanceFriction;
    mapping(address => address) public strategy;
    mapping(address => address) public poolRewards;
    uint16 public aaveReferralCode;
    address public founderVault;
    uint256 public founderFee = 5e16;
    address public treasuryPool;
    address public uniswapRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IAddressList public immutable pools;

    constructor() public {
        IAddressListFactory addressFactory =
            //IAddressListFactory(0xD57b41649f822C51a73C44Ba0B3da4A880aF0029); // mainnet
            IAddressListFactory(0x2A62975b1Dc4f6F8201E15C97E400f51724C8158); // kovan
        pools = IAddressList(addressFactory.createList());
    }

    modifier validPool(address pool) {
        require(pools.contains(pool), "Not a valid pool");
        _;
    }

    /**
     * @dev Add new pool in vesper system
     * @param _pool Address of new pool
     */
    function addPool(address _pool) external onlyOwner {
        require(_pool != address(0), "invalid-pool");
        IERC20 pool = IERC20(_pool);
        require(pool.totalSupply() == 0, "Zero supply required");
        pools.add(_pool);
    }

    /**
     * @dev Remove pool from vesper system
     * @param _pool Address of pool to be removed
     */
    function removePool(address _pool) external onlyOwner {
        IERC20 pool = IERC20(_pool);
        require(pool.totalSupply() == 0, "Zero supply required");
        pools.remove(_pool);
    }

    /**
     * @dev Execute transaction in given target contract
     * @param target Address of target contract
     * @param value Ether amount to transfer
     * @param signature Signature of function in target contract
     * @param data Encoded data for function call
     */
    function executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data
    ) external payable onlyOwner returns (bytes memory) {
        return _executeTransaction(target, value, signature, data);
    }

    /// @dev Execute multiple transactions.
    function executeTransactions(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas
    ) external payable onlyOwner {
        require(targets.length != 0, "Must provide actions");
        require(
            targets.length == values.length &&
                targets.length == signatures.length &&
                targets.length == calldatas.length,
            "Transaction data mismatch"
        );

        for (uint256 i = 0; i < targets.length; i++) {
            _executeTransaction(targets[i], values[i], signatures[i], calldatas[i]);
        }
    }

    function updateAaveReferralCode(uint16 referralCode) external onlyOwner {
        aaveReferralCode = referralCode;
    }

    function updateFeeCollector(address _pool, address _collector)
        external
        onlyOwner
        validPool(_pool)
    {
        require(_collector != address(0), "invalid-collector");
        require(feeCollector[_pool] != _collector, "same-collector");
        feeCollector[_pool] = _collector;
    }

    function updateFounderVault(address _founderVault) external onlyOwner {
        founderVault = _founderVault;
    }

    function updateFounderFee(uint256 _founderFee) external onlyOwner {
        require(founderFee != _founderFee, "same-founderFee");
        require(_founderFee <= 1e18, "founderFee-above-100%");
        founderFee = _founderFee;
    }

    function updateInterestFee(address _pool, uint256 _interestFee)
        external
        onlyOwner
        validPool(_pool)
    {
        require(_interestFee <= 1e18, "Fee limit reached");
        require(feeCollector[_pool] != address(0), "FeeCollector not set");
        interestFee[_pool] = _interestFee;
    }

    function updateStrategy(address _pool, address _newStrategy)
        external
        onlyOwner
        validPool(_pool)
    {
        require(_newStrategy != address(0), "invalid-strategy-address");
        address currentStrategy = strategy[_pool];
        require(currentStrategy != _newStrategy, "same-pool-strategy");
        require(IStrategy(_newStrategy).pool() == _pool, "wrong-pool");
        IVesperPool vpool = IVesperPool(_pool);
        if (currentStrategy != address(0)) {
            require(IStrategy(currentStrategy).isUpgradable(), "strategy-is-not-upgradable");
            vpool.resetApproval();
        }
        strategy[_pool] = _newStrategy;
        vpool.approveToken();
    }

    function updateRebalanceFriction(address _pool, uint256 _f)
        external
        onlyOwner
        validPool(_pool)
    {
        require(rebalanceFriction[_pool] != _f, "same-friction");
        rebalanceFriction[_pool] = _f;
    }

    function updatePoolRewards(address _pool, address _poolRewards)
        external
        onlyOwner
        validPool(_pool)
    {
        require(IPoolRewards(_poolRewards).pool() == _pool, "wrong-pool");
        poolRewards[_pool] = _poolRewards;
    }

    function updateTreasuryPool(address _pool) external onlyOwner validPool(_pool) {
        treasuryPool = _pool;
    }

    function updateUniswapRouter(address _uniswapRouter) external onlyOwner {
        uniswapRouter = _uniswapRouter;
    }

    function updateWithdrawFee(address _pool, uint256 _newWithdrawFee)
        external
        onlyOwner
        validPool(_pool)
    {
        require(_newWithdrawFee <= 1e18, "withdraw-fee-limit-reached");
        require(withdrawFee[_pool] != _newWithdrawFee, "same-withdraw-fee");
        require(feeCollector[_pool] != address(0), "FeeCollector-not-set");
        withdrawFee[_pool] = _newWithdrawFee;
    }

    function isPool(address _pool) external view returns (bool) {
        return pools.contains(_pool);
    }

    function _executeTransaction(
        address target,
        uint256 value,
        string memory signature,
        bytes memory data
    ) internal onlyOwner returns (bytes memory) {
        bytes memory callData;
        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = target.call{value: value}(callData);
        require(success, "Transaction execution reverted.");
        return returnData;
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

pragma solidity 0.6.12;

import "@openzeppelin/contracts/GSN/Context.sol";

// Requried one small change in openzeppelin version of ownable, so imported
// source code here. Notice line 26 for change.

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
contract Ownable is Context {
    /**
     * @dev Changed _owner from 'private' to 'internal'
     */
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
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
        require(newOwner != address(0), "Ownable: zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

/**
 * @dev Contract module extends Ownable and provide a way for safe transfer ownership.
 * Proposed owner has to call acceptOwnership in order to complete ownership trasnfer.
 */
contract Owned is Ownable {
    address private _proposedOwner;

    /**
     * @dev Initiate transfer ownership of the contract to a new account (`proposedOwner`).
     * Can only be called by the current owner. Current owner will still be owner until
     * proposed owner accept ownership.
     * @param proposedOwner proposed owner address
     */
    function transferOwnership(address proposedOwner) public override onlyOwner {
        //solhint-disable-next-line reason-string
        require(proposedOwner != address(0), "Proposed owner is the zero address");
        _proposedOwner = proposedOwner;
    }

    /// @dev Allows proposed owner to accept ownership of the contract.
    function acceptOwnership() public {
        require(msg.sender == _proposedOwner, "Caller is not the proposed owner");
        emit OwnershipTransferred(_owner, _proposedOwner);
        _owner = _proposedOwner;
        _proposedOwner = address(0);
    }

    function renounceOwnership() public override onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
        _proposedOwner = address(0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVesperPool is IERC20 {
    function approveToken() external;

    function deposit() external payable;

    function deposit(uint256) external;

    function multiTransfer(uint256[] memory) external returns (bool);

    function permit(
        address,
        address,
        uint256,
        uint256,
        uint8,
        bytes32,
        bytes32
    ) external;

    function rebalance() external;

    function resetApproval() external;

    function sweepErc20(address) external;

    function withdraw(uint256) external;

    function withdrawETH(uint256) external;

    function withdrawByStrategy(uint256) external;

    function feeCollector() external view returns (address);

    function getPricePerShare() external view returns (uint256);

    function token() external view returns (address);

    function tokensHere() external view returns (uint256);

    function totalValue() external view returns (uint256);

    function withdrawFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IStrategy {
    function rebalance() external;

    function deposit(uint256 amount) external;

    function beforeWithdraw() external;

    function withdraw(uint256 amount) external;

    function withdrawAll() external;

    function isUpgradable() external view returns (bool);

    function isReservedToken(address _token) external view returns (bool);

    function token() external view returns (address);

    function pool() external view returns (address);

    function totalLocked() external view returns (uint256);

    //Lifecycle functions
    function pause() external;

    function unpause() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IPoolRewards {
    function notifyRewardAmount(uint256) external;

    function claimReward(address) external;

    function updateReward(address) external;

    function rewardForDuration() external view returns (uint256);

    function claimable(address) external view returns (uint256);

    function pool() external view returns (address);

    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

interface IAddressList {
    event AddressUpdated(address indexed a, address indexed sender);
    event AddressRemoved(address indexed a, address indexed sender);

    function add(address a) external returns (bool);

    function addValue(address a, uint256 v) external returns (bool);

    function addMulti(address[] calldata addrs) external returns (uint256);

    function addValueMulti(address[] calldata addrs, uint256[] calldata values) external returns (uint256);

    function remove(address a) external returns (bool);

    function removeMulti(address[] calldata addrs) external returns (uint256);

    function get(address a) external view returns (uint256);

    function contains(address a) external view returns (bool);

    function at(uint256 index) external view returns (address, uint256);

    function length() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

interface IAddressListFactory {
    event ListCreated(address indexed _sender, address indexed _newList);

    function ours(address a) external view returns (bool);

    function listCount() external view returns (uint256);

    function listAt(uint256 idx) external view returns (address);

    function createList() external returns (address listaddr);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";

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

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../Pausable.sol";
import "../interfaces/vesper/IController.sol";
import "../interfaces/vesper/IVesperPool.sol";
import "../interfaces/bloq/ISwapManager.sol";
import "../../sol-address-list/contracts/interfaces/IAddressListExt.sol";
import "../../sol-address-list/contracts/interfaces/IAddressListFactory.sol";

contract VSPStrategy is Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public lastRebalanceBlock;
    IController public immutable controller;
    IVesperPool public immutable vvsp;
    IAddressListExt public immutable keepers;
    ISwapManager public swapManager = ISwapManager(0xe382d9f2394A359B01006faa8A1864b8a60d2710);
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 public nextPoolIdx;
    address[] public pools;
    uint256[] public liquidationLimit;
    string public constant NAME = "Strategy-VSP";
    string public constant VERSION = "2.0.3";

    event UpdatedSwapManager(address indexed previousSwapManager, address indexed newSwapManager);

    constructor(address _controller, address _vvsp) public {
        vvsp = IVesperPool(_vvsp);
        controller = IController(_controller);
        IAddressListFactory factory =
            IAddressListFactory(0xD57b41649f822C51a73C44Ba0B3da4A880aF0029);
        IAddressListExt _keepers = IAddressListExt(factory.createList());
        _keepers.grantRole(keccak256("LIST_ADMIN"), _controller);
        keepers = _keepers;
    }

    modifier onlyKeeper() {
        require(keepers.contains(_msgSender()), "caller-is-not-keeper");
        _;
    }

    modifier onlyController() {
        require(_msgSender() == address(controller), "Caller is not the controller");
        _;
    }

    function pause() external onlyController {
        _pause();
    }

    function unpause() external onlyController {
        _unpause();
    }

    /**
     * @notice Update swap manager address
     * @param _swapManager swap manager address
     */
    function updateSwapManager(address _swapManager) external onlyController {
        require(_swapManager != address(0), "sm-address-is-zero");
        require(_swapManager != address(swapManager), "sm-is-same");
        emit UpdatedSwapManager(address(swapManager), _swapManager);
        swapManager = ISwapManager(_swapManager);
    }

    function updateLiquidationQueue(address[] calldata _pools, uint256[] calldata _limit)
        external
        onlyController
    {
        for (uint256 i = 0; i < _pools.length; i++) {
            require(controller.isPool(_pools[i]), "Not a valid pool");
            require(_limit[i] != 0, "Limit cannot be zero");
        }
        pools = _pools;
        liquidationLimit = _limit;
        nextPoolIdx = 0;
    }

    function isUpgradable() external view returns (bool) {
        return IERC20(vvsp.token()).balanceOf(address(this)) == 0;
    }

    function pool() external view returns (address) {
        return address(vvsp);
    }

    /**
        withdraw Vtoken from vvsp => Deposit vpool => withdraw collateral => swap in uni for VSP => transfer vsp to vvsp pool
        PETH => ETH => VSP
     */
    function rebalance() external whenNotPaused onlyKeeper {
        require(
            block.number - lastRebalanceBlock >= controller.rebalanceFriction(address(vvsp)),
            "Can not rebalance"
        );
        lastRebalanceBlock = block.number;

        if (nextPoolIdx == pools.length) {
            nextPoolIdx = 0;
        }

        IVesperPool _poolToken = IVesperPool(pools[nextPoolIdx]);
        uint256 _balance = _poolToken.balanceOf(address(vvsp));
        if (_balance != 0 && address(_poolToken) != address(vvsp)) {
            if (_balance > liquidationLimit[nextPoolIdx]) {
                _balance = liquidationLimit[nextPoolIdx];
            }
            _rebalanceEarned(_poolToken, _balance);
        }
        nextPoolIdx++;
    }

    /// @dev sweep given token to vsp pool
    function sweepErc20(address _fromToken) external {
        uint256 amount = IERC20(_fromToken).balanceOf(address(this));
        IERC20(_fromToken).safeTransfer(address(vvsp), amount);
    }

    function _rebalanceEarned(IVesperPool _poolToken, uint256 _amt) internal {
        IERC20(address(_poolToken)).safeTransferFrom(address(vvsp), address(this), _amt);
        _poolToken.withdrawByStrategy(_amt);
        IERC20 from = IERC20(_poolToken.token());
        IERC20 vsp = IERC20(vvsp.token());
        (address[] memory path, uint256 amountOut, uint256 rIdx) =
            swapManager.bestOutputFixedInput(
                address(from),
                address(vsp),
                from.balanceOf(address(this))
            );
        if (amountOut != 0) {
            from.safeApprove(address(swapManager.ROUTERS(rIdx)), 0);
            from.safeApprove(address(swapManager.ROUTERS(rIdx)), from.balanceOf(address(this)));
            swapManager.ROUTERS(rIdx).swapExactTokensForTokens(
                from.balanceOf(address(this)),
                1,
                path,
                address(this),
                now + 30
            );
            vsp.safeTransfer(address(vvsp), vsp.balanceOf(address(this)));
        }
    }
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

pragma solidity 0.6.12;

import "@openzeppelin/contracts/GSN/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 */
contract Pausable is Context {
    event Paused(address account);
    event Shutdown(address account);
    event Unpaused(address account);
    event Open(address account);

    bool public paused;
    bool public stopEverything;

    modifier whenNotPaused() {
        require(!paused, "Pausable: paused");
        _;
    }
    modifier whenPaused() {
        require(paused, "Pausable: not paused");
        _;
    }

    modifier whenNotShutdown() {
        require(!stopEverything, "Pausable: shutdown");
        _;
    }

    modifier whenShutdown() {
        require(stopEverything, "Pausable: not shutdown");
        _;
    }

    /// @dev Pause contract operations, if contract is not paused.
    function _pause() internal virtual whenNotPaused {
        paused = true;
        emit Paused(_msgSender());
    }

    /// @dev Unpause contract operations, allow only if contract is paused and not shutdown.
    function _unpause() internal virtual whenPaused whenNotShutdown {
        paused = false;
        emit Unpaused(_msgSender());
    }

    /// @dev Shutdown contract operations, if not already shutdown.
    function _shutdown() internal virtual whenNotShutdown {
        stopEverything = true;
        paused = true;
        emit Shutdown(_msgSender());
    }

    /// @dev Open contract operations, if contract is in shutdown state
    function _open() internal virtual whenShutdown {
        stopEverything = false;
        emit Open(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IController {
    function aaveReferralCode() external view returns (uint16);

    function feeCollector(address) external view returns (address);

    function founderFee() external view returns (uint256);

    function founderVault() external view returns (address);

    function interestFee(address) external view returns (uint256);

    function isPool(address) external view returns (bool);

    function pools() external view returns (address);

    function strategy(address) external view returns (address);

    function rebalanceFriction(address) external view returns (uint256);

    function poolRewards(address) external view returns (address);

    function treasuryPool() external view returns (address);

    function uniswapRouter() external view returns (address);

    function withdrawFee(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../uniswap/IUniswapV2Router02.sol";

/* solhint-disable func-name-mixedcase */

interface ISwapManager {
    event OracleCreated(address indexed _sender, address indexed _newOracle, uint256 _period);

    function N_DEX() external view returns (uint256);

    function ROUTERS(uint256 i) external view returns (IUniswapV2Router02);

    function bestOutputFixedInput(
        address _from,
        address _to,
        uint256 _amountIn
    )
        external
        view
        returns (
            address[] memory path,
            uint256 amountOut,
            uint256 rIdx
        );

    function bestPathFixedInput(
        address _from,
        address _to,
        uint256 _amountIn,
        uint256 _i
    ) external view returns (address[] memory path, uint256 amountOut);

    function bestInputFixedOutput(
        address _from,
        address _to,
        uint256 _amountOut
    )
        external
        view
        returns (
            address[] memory path,
            uint256 amountIn,
            uint256 rIdx
        );

    function bestPathFixedOutput(
        address _from,
        address _to,
        uint256 _amountOut,
        uint256 _i
    ) external view returns (address[] memory path, uint256 amountIn);

    function safeGetAmountsOut(
        uint256 _amountIn,
        address[] memory _path,
        uint256 _i
    ) external view returns (uint256[] memory result);

    function unsafeGetAmountsOut(
        uint256 _amountIn,
        address[] memory _path,
        uint256 _i
    ) external view returns (uint256[] memory result);

    function safeGetAmountsIn(
        uint256 _amountOut,
        address[] memory _path,
        uint256 _i
    ) external view returns (uint256[] memory result);

    function unsafeGetAmountsIn(
        uint256 _amountOut,
        address[] memory _path,
        uint256 _i
    ) external view returns (uint256[] memory result);

    function comparePathsFixedInput(
        address[] memory pathA,
        address[] memory pathB,
        uint256 _amountIn,
        uint256 _i
    ) external view returns (address[] memory path, uint256 amountOut);

    function comparePathsFixedOutput(
        address[] memory pathA,
        address[] memory pathB,
        uint256 _amountOut,
        uint256 _i
    ) external view returns (address[] memory path, uint256 amountIn);

    function ours(address a) external view returns (bool);

    function oracleCount() external view returns (uint256);

    function oracleAt(uint256 idx) external view returns (address);

    function getOracle(
        address _tokenA,
        address _tokenB,
        uint256 _period,
        uint256 _i
    ) external view returns (address);

    function createOrUpdateOracle(
        address _tokenA,
        address _tokenB,
        uint256 _period,
        uint256 _i
    ) external returns (address oracleAddr);

    function consultForFree(
        address _from,
        address _to,
        uint256 _amountIn,
        uint256 _period,
        uint256 _i
    ) external view returns (uint256 amountOut, uint256 lastUpdatedAt);

    /// get the data we want and pay the gas to update
    function consult(
        address _from,
        address _to,
        uint256 _amountIn,
        uint256 _period,
        uint256 _i
    )
        external
        returns (
            uint256 amountOut,
            uint256 lastUpdatedAt,
            bool updated
        );

    function updateOracles() external returns (uint256 updated, uint256 expected);

    function updateOracles(address[] memory _oracleAddrs)
        external
        returns (uint256 updated, uint256 expected);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "./IAddressList.sol";

interface IAddressListExt is IAddressList {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);

    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
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

pragma solidity 0.6.12;

import "./IUniswapV2Router01.sol";

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../Pausable.sol";
import "../interfaces/vesper/IController.sol";
import "../interfaces/vesper/IVesperPool.sol";
import "../interfaces/bloq/ISwapManager.sol";
import "../interfaces/bloq/IDescendingPriceAuction.sol";
import "../../sol-address-list/contracts/interfaces/IAddressListExt.sol";
import "../../sol-address-list/contracts/interfaces/IAddressListFactory.sol";

contract VSPAuctionStrategy is Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public lastRebalanceBlock;
    IController public immutable controller;
    IVesperPool public immutable vvsp;
    IAddressListExt public immutable keepers;
    ISwapManager public swapManager = ISwapManager(0xe382d9f2394A359B01006faa8A1864b8a60d2710);
    IDescendingPriceAuction public auctionManager;
    uint256 public auctionCollectionId;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 internal constant ORACLE_PERIOD = 3600;

    // Auction Config
    uint256 internal auctionDuration = 600; // 600 Blocks at 12s / block -> ~2hr
    uint256 internal auctionCeilingBuffer = 2500; // as BP * 10**2
    uint256 internal auctionFloorBuffer = 2500; // as BP * 10**2
    uint256 internal acceptableSlippage = 500; // as BP * 10**2
    address internal auctionPayee;

    uint256 public nextPoolIdx;
    address[] public pools;
    uint256[] public liquidationLimit;
    string public constant NAME = "Strategy-VSP-Auctions";
    string public constant VERSION = "2.0.0";

    event UpdatedSwapManager(address indexed previousSwapManager, address indexed newSwapManager);
    event UpdatedAuctionManager(
        address indexed previousAuctionManager,
        address indexed newAuctionManager
    );
    event UpdatedAuctionPayee(
        address indexed previousAuctionPayee,
        address indexed newAuctionPayee
    );
    event UpdatedAuctionConfig(
        uint256 ceilingBuffer,
        uint256 floorBuffer,
        uint256 duration,
        uint256 previousCeilingBuffer,
        uint256 previousFloorBuffer,
        uint256 previousDuration
    );
    event UpdatedCollectionId(uint256 previousCollectionId, uint256 newCollectionId);
    event UpdatedAcceptableSlippage(uint256 previousSlippage, uint256 newSlippage);

    constructor(
        address _controller,
        address _vvsp,
        address _pfDpa
    ) public {
        vvsp = IVesperPool(_vvsp);
        controller = IController(_controller);
        IAddressListFactory factory =
            IAddressListFactory(0xD57b41649f822C51a73C44Ba0B3da4A880aF0029);
        IAddressListExt _keepers = IAddressListExt(factory.createList());
        _keepers.grantRole(keccak256("LIST_ADMIN"), _controller);
        keepers = _keepers;
        auctionManager = IDescendingPriceAuction(_pfDpa);
        auctionCollectionId = auctionManager.createCollection();
        auctionPayee = address(this);
    }

    modifier onlyKeeper() {
        require(keepers.contains(_msgSender()), "caller-is-not-keeper");
        _;
    }

    modifier onlyController() {
        require(_msgSender() == address(controller), "Caller is not the controller");
        _;
    }

    function pause() external onlyController {
        _pause();
    }

    function unpause() external onlyController {
        _unpause();
    }

    /**
     * @notice Update swap manager address
     * @param _swapManager swap manager address
     */
    function updateSwapManager(address _swapManager) external onlyController {
        require(_swapManager != address(0x0), "sm-address-is-zero");
        require(_swapManager != address(swapManager), "sm-is-same");
        emit UpdatedSwapManager(address(swapManager), _swapManager);
        swapManager = ISwapManager(_swapManager);
    }

    function updateAuctionManager(address _auctionManager) external onlyController {
        require(_auctionManager != address(0x0), "am-address-is-zero");
        require(_auctionManager != address(_auctionManager), "am-is-same");
        emit UpdatedAuctionManager(address(_auctionManager), _auctionManager);
        auctionManager = IDescendingPriceAuction(_auctionManager);
        auctionCollectionId = auctionManager.createCollection();
    }

    // use this to send auction proceeds directly to drip address
    function updateAuctionPayee(address _payee) external onlyController {
        require(_payee != address(0x0), "payee-address-is-zero");
        require(_payee != auctionPayee, "payee-is-same");
        emit UpdatedAuctionPayee(auctionPayee, _payee);
        auctionPayee = _payee;
    }

    function updateAuctionCollectionId() external onlyController {
        uint256 newCollectionId = auctionManager.createCollection();
        emit UpdatedCollectionId(auctionCollectionId, newCollectionId);
        auctionCollectionId = newCollectionId;
    }

    function updateAuctionCollectionId(uint256 _collectionId) external onlyController {
        // DPA does not support checking collection ownership
        emit UpdatedCollectionId(auctionCollectionId, _collectionId);
        auctionCollectionId = _collectionId;
    }

    function updateAcceptableSlippage(uint256 _slippage) external onlyController {
        require(_slippage < 10000, "invalid-slippage");
        emit UpdatedAcceptableSlippage(acceptableSlippage, _slippage);
        acceptableSlippage = _slippage;
    }

    function updateAuctionConfig(
        uint256 ceilingBuffer,
        uint256 floorBuffer,
        uint256 duration
    ) external onlyController {
        require(duration != 0, "duration-is-zero");
        require(floorBuffer < 6667, "invalid-floor-buffer"); // No greater than 67% drawdown
        require(ceilingBuffer < 30000, "invalid-ceil-buffer"); // No greater than 300% upside
        emit UpdatedAuctionConfig(
            ceilingBuffer,
            floorBuffer,
            duration,
            auctionCeilingBuffer,
            auctionFloorBuffer,
            auctionDuration
        );
        auctionCeilingBuffer = ceilingBuffer;
        auctionFloorBuffer = floorBuffer;
        auctionDuration = duration;
    }

    function _stopAndSwap(DPA memory auction) internal {
        address[] memory tokens = auction.tokens;
        auctionManager.stopAuction(auction.id);
        for (uint256 i = 0; i < tokens.length; i++) {
            _safeSwapToVsp(tokens[i]);
        }
    }

    function _getAuctionsOfCollection() internal view returns (uint256[] memory auctions) {
        uint256 totalAuctions = auctionManager.collectionLength(auctionCollectionId);
        auctions = new uint256[](totalAuctions);
        for (uint256 i = 0; i < totalAuctions; i++) {
            auctions[i] = auctionManager.auctionOfCollByIndex(auctionCollectionId, i);
        }
    }

    function _createAuction(IVesperPool _poolToken, uint256 _poolTokenAmount) internal {
        // unwrap poolTokens to Tokens ie pWBTC -> WBTC
        _poolToken.withdrawByStrategy(_poolTokenAmount);
        address[] memory _tokens = new address[](1);
        _tokens[0] = _poolToken.token();
        uint256[] memory _tokenAmounts = new uint256[](1);
        _tokenAmounts[0] = IERC20(_tokens[0]).balanceOf(address(this));

        address vsp = vvsp.token();
        // calculate ceiling and floor values
        (uint256 c, uint256 f) = _getAuctionValues(_tokens, _tokenAmounts, vsp);
        DPAConfig memory _auction =
            DPAConfig({
                ceiling: c,
                floor: f,
                collectionId: auctionCollectionId,
                paymentToken: vsp,
                payee: auctionPayee,
                endBlock: block.number + auctionDuration,
                tokens: _tokens,
                tokenAmounts: _tokenAmounts
            });
        auctionManager.createAuction(_auction);
    }

    // This should get smarter (use oracles)
    function _getAuctionValues(
        address[] memory _tokens,
        uint256[] memory _tokenAmounts,
        address _outputToken
    ) internal returns (uint256 ceiling, uint256 floor) {
        require(_tokens.length == _tokenAmounts.length, "invalid-token-list");
        uint256 sum;
        for (uint256 i = 0; i < _tokens.length; i++) {
            (uint256 amountOut, bool validRate) =
                _getCompoundOracleRate(_tokens[i], _outputToken, _tokenAmounts[i]);
            require(validRate, "stale-oracle-rate");
            IERC20(_tokens[i]).approve(address(auctionManager), 0);
            IERC20(_tokens[i]).approve(address(auctionManager), _tokenAmounts[i]);
            sum += amountOut;
        }
        require(sum != 0, "cannot-calc-auction-value");
        ceiling = sum + ((sum * auctionCeilingBuffer) / 10000);
        floor = sum - ((sum * auctionFloorBuffer) / 10000);
    }

    function _safeSwapToVsp(address _fromToken) internal {
        IERC20 from = IERC20(_fromToken);
        IERC20 vsp = IERC20(vvsp.token());
        (address[] memory path, uint256 amountOut, uint256 rIdx) =
            swapManager.bestOutputFixedInput(
                _fromToken,
                address(vsp),
                from.balanceOf(address(this))
            );
        (uint256 expectedAmountOut, bool validRate) =
            _getCompoundOracleRate(_fromToken, vvsp.token(), from.balanceOf(address(this)));
        require(validRate, "stale-oracle-rate");
        expectedAmountOut = _calculateSlippage(expectedAmountOut, acceptableSlippage);
        if (amountOut != 0) {
            from.safeApprove(address(swapManager.ROUTERS(rIdx)), 0);
            from.safeApprove(address(swapManager.ROUTERS(rIdx)), from.balanceOf(address(this)));
            swapManager.ROUTERS(rIdx).swapExactTokensForTokens(
                from.balanceOf(address(this)),
                1,
                path,
                address(this),
                now + 30
            );
        }
    }

    function _getCompoundOracleRate(
        address _from,
        address _to,
        uint256 _amt
    ) internal returns (uint256, bool) {
        if (_from == WETH || _to == WETH) return _consultOracle(_from, _to, _amt);
        (uint256 fAmtOut, bool fValid) = _consultOracle(_from, WETH, _amt);
        (uint256 bRate, bool bValid) = _consultOracle(WETH, _to, fAmtOut);
        return (bRate, (fValid && bValid));
    }

    function _consultOracle(
        address _from,
        address _to,
        uint256 _amt
    ) internal returns (uint256, bool) {
        // from, to, amountIn, period, router
        (uint256 rate, uint256 lastUpdate, ) =
            swapManager.consult(_from, _to, _amt, ORACLE_PERIOD, 0);
        // We're looking at a TWAP ORACLE with a 1 hr Period that has been updated within the last hour
        if ((lastUpdate > (block.timestamp - ORACLE_PERIOD)) && (rate != 0)) return (rate, true);
        return (0, false);
    }

    function _calculateSlippage(uint256 _amount, uint256 _slippage)
        internal
        pure
        returns (uint256)
    {
        return (_amount.mul(uint256(10000).sub(_slippage)).div(10000)).add(1);
    }

    function killAllAuctions() external onlyController {
        uint256[] memory auctions = _getAuctionsOfCollection();
        for (uint256 i = 0; i < auctions.length; i++) {
            DPA memory a = auctionManager.getAuction(auctions[i]);
            if (a.winningBlock == 0 && !a.stopped) {
                _stopAndSwap(a);
            }
        }
    }

    function killAuction(uint256 _auctionId) external onlyController {
        _stopAndSwap(auctionManager.getAuction(_auctionId));
    }

    function updateLiquidationQueue(address[] calldata _pools, uint256[] calldata _limit)
        external
        onlyController
    {
        swapManager.createOrUpdateOracle(vvsp.token(), WETH, ORACLE_PERIOD, 0);
        for (uint256 i = 0; i < _pools.length; i++) {
            require(controller.isPool(_pools[i]), "Not a valid pool");
            require(_limit[i] != 0, "Limit cannot be zero");
            if (IVesperPool(_pools[i]).token() != WETH) {
                swapManager.createOrUpdateOracle(
                    IVesperPool(_pools[i]).token(),
                    WETH,
                    ORACLE_PERIOD,
                    0
                );
            }
        }
        pools = _pools;
        liquidationLimit = _limit;
        nextPoolIdx = 0;
    }

    function isUpgradable() external view returns (bool) {
        return IERC20(vvsp.token()).balanceOf(address(this)) == 0;
    }

    function pool() external view returns (address) {
        return address(vvsp);
    }

    function rebalance() external whenNotPaused onlyKeeper {
        require(
            block.number - lastRebalanceBlock >= controller.rebalanceFriction(address(vvsp)),
            "Can not rebalance"
        );
        lastRebalanceBlock = block.number;

        // // if any of our auction have hit their floor without being bought, market swap them
        uint256[] memory auctions = _getAuctionsOfCollection();
        for (uint256 i = 0; i < auctions.length; i++) {
            DPA memory a = auctionManager.getAuction(auctions[i]);
            if (block.number >= a.endBlock && a.winningBlock == 0 && !a.stopped) _stopAndSwap(a);
        }

        // First, send back any VSP we have received from auctions being completed
        uint256 vspBalance = IERC20(vvsp.token()).balanceOf(address(this));
        IERC20(vvsp.token()).safeTransfer(address(vvsp), vspBalance);

        if (nextPoolIdx == pools.length) {
            nextPoolIdx = 0;
        }

        IVesperPool _poolToken = IVesperPool(pools[nextPoolIdx]);
        uint256 _balance = _poolToken.balanceOf(address(vvsp));
        if (_balance != 0 && address(_poolToken) != address(vvsp)) {
            if (_balance > liquidationLimit[nextPoolIdx]) {
                _balance = liquidationLimit[nextPoolIdx];
            }
            IERC20(address(_poolToken)).safeTransferFrom(address(vvsp), address(this), _balance);
            _createAuction(_poolToken, _balance);
        }
        nextPoolIdx++;
    }

    /// @dev sweep given token to vsp pool
    function sweepErc20(address _fromToken) external {
        uint256 amount = IERC20(_fromToken).balanceOf(address(this));
        IERC20(_fromToken).safeTransfer(address(vvsp), amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

struct DPAConfig {
    uint256 ceiling;
    uint256 floor;
    uint256 collectionId;
    address paymentToken;
    address payee;
    uint256 endBlock;
    address[] tokens;
    uint256[] tokenAmounts;
}

struct DPA {
    uint256 id;
    uint256 ceiling;
    uint256 floor;
    uint256 absoluteDecay;
    uint256 collectionId;
    address paymentToken;
    address payee;
    uint256 startBlock;
    uint256 endBlock;
    bool stopped;
    address winner;
    uint256 winningBlock;
    uint256 winningPrice;
    address[] tokens;
    uint256[] tokenAmounts;
}

interface IDescendingPriceAuction {
    event AuctionCreated(uint256 id, uint256 collectionId, address auctioneer);
    event CollectionCreated(uint256 id, address owner);
    event CollectionTransfer(uint256 id, address from, address to);
    event AuctionStopped(uint256 id);
    event AuctionWon(uint256 id, uint256 price, address paymentToken, address winner);

    function getAuction(uint256 _id) external view returns (DPA memory);

    function totalAuctions() external view returns (uint256);

    function totalCollections() external view returns (uint256);

    function collectionLength(uint256 _id) external view returns (uint256);

    function neerGroupLength(address _neer) external view returns (uint256);

    function auctionOfNeerByIndex(address _neer, uint256 i) external view returns (uint256);

    function auctionOfCollByIndex(uint256 _id, uint256 i) external view returns (uint256);

    function createAuction(DPAConfig memory _auction) external returns (uint256);

    function stopAuction(uint256 _id) external;

    function bid(uint256 _id) external;

    function getCurrentPrice(uint256 _id) external view returns (uint256);

    function createCollection() external returns (uint256);

    function transferCollection(address _to, uint256 _id) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/EnumerableMap.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/bloq/IDescendingPriceAuction.sol";

contract DescendingPriceAuction is IDescendingPriceAuction {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    mapping(uint256 => DPA) private auctions;
    EnumerableMap.UintToAddressMap private collections;
    EnumerableMap.UintToAddressMap private auctioneers;
    Counters.Counter private collectionCount;
    Counters.Counter private auctionCount;

    // Mapping from aucitoneer address to their (enumerable) set of auctions
    mapping(address => EnumerableSet.UintSet) private _byNeer;

    // Mapping from collectionId to its (enumerable) set of auctions
    mapping(uint256 => EnumerableSet.UintSet) private _byColl;

    constructor() public {
        // Start the counts at 1
        // the 0th collection is available to all
        auctionCount.increment();
        collectionCount.increment();
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    modifier onlyAuctioneer(uint256 _id) {
        (bool success, address neer) = auctioneers.tryGet(_id);
        require(success, "non-existent-auction");
        require(_msgSender() == neer, "caller-not-auctioneer");
        _;
    }

    modifier onlyCollectionOwner(uint256 _id) {
        // anyone can create an auction in the 0th collection
        if (_id != 0) {
            (bool success, address owner) = collections.tryGet(_id);
            require(success, "non-existent-collection");
            require(_msgSender() == owner, "caller-not-collection-owner");
        }
        _;
    }

    function getAuction(uint256 _id) external view override returns (DPA memory) {
        return auctions[_id];
    }

    function totalAuctions() external view override returns (uint256) {
        return auctioneers.length();
    }

    function totalCollections() external view override returns (uint256) {
        return collections.length();
    }

    function collectionLength(uint256 _id) external view override returns (uint256) {
        return _byColl[_id].length();
    }

    function neerGroupLength(address _neer) external view override returns (uint256) {
        return _byNeer[_neer].length();
    }

    // return AuctionId
    function auctionOfNeerByIndex(address _neer, uint256 i)
        external
        view
        override
        returns (uint256)
    {
        return _byNeer[_neer].at(i);
    }

    // return AuctionId
    function auctionOfCollByIndex(uint256 _id, uint256 i) external view override returns (uint256) {
        return _byColl[_id].at(i);
    }

    function _auctionExists(uint256 _auctionId) internal view virtual returns (bool) {
        return auctioneers.contains(_auctionId);
    }

    function createAuction(DPAConfig memory _auction)
        external
        override
        onlyCollectionOwner(_auction.collectionId)
        returns (uint256)
    {
        require(_auction.endBlock > block.number, "end-block-passed");
        require(_auction.ceiling != 0, "start-price-zero");
        require(_auction.ceiling >= _auction.floor, "invalid-pricing");
        require(_auction.paymentToken != address(0x0), "invalid-payment-token");
        require(_auction.payee != address(0x0), "invalid-payee");
        require(_auction.tokens.length != 0, "no-line-items");
        require(_auction.tokens.length == _auction.tokenAmounts.length, "improper-line-items");
        require(_auction.tokens.length < 8, "too-many-line-items");
        return _createAuction(_auction);
    }

    function _createAuction(DPAConfig memory _auction) internal returns (uint256) {
        _pullTokens(_auction.tokens, _auction.tokenAmounts);
        uint256 id = auctionCount.current();
        uint256 decay =
            _calulateAbsoluteDecay(
                _auction.ceiling,
                _auction.floor,
                block.number,
                _auction.endBlock
            );
        auctions[id] = DPA({
            id: id,
            ceiling: _auction.ceiling,
            floor: _auction.floor,
            absoluteDecay: decay,
            collectionId: _auction.collectionId,
            paymentToken: _auction.paymentToken,
            payee: _auction.payee,
            startBlock: block.number,
            endBlock: _auction.endBlock,
            stopped: false,
            winner: address(0x0),
            winningBlock: 0,
            winningPrice: 0,
            tokens: _auction.tokens,
            tokenAmounts: _auction.tokenAmounts
        });
        address neer = _msgSender();
        auctioneers.set(id, neer);
        _byNeer[neer].add(id);
        _byColl[_auction.collectionId].add(id);
        auctionCount.increment();
        emit AuctionCreated(id, _auction.collectionId, neer);
        return id;
    }

    function _pullTokens(address[] memory tokens, uint256[] memory amounts) internal {
        for (uint256 i = 0; i < tokens.length; i++) {
            _pullToken(tokens[i], amounts[i]);
        }
    }

    function _pullToken(address _token, uint256 _amount) internal {
        require(_amount != 0, "invalid-token-amount");
        _safeTransferFromExact(_token, _msgSender(), address(this), _amount);
    }

    function _sendTokens(
        address recipient,
        address[] memory tokens,
        uint256[] memory amounts
    ) internal {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20(tokens[i]).safeTransfer(recipient, amounts[i]);
        }
    }

    function stopAuction(uint256 _id) external override onlyAuctioneer(_id) {
        DPA memory auction = auctions[_id];
        require(auction.winner == address(0x0) && !auction.stopped, "cant-be-stopped");
        _sendTokens(auctioneers.get(_id), auction.tokens, auction.tokenAmounts);
        auctions[_id].stopped = true;
        emit AuctionStopped(_id);
    }

    function bid(uint256 _id) external override {
        require(_auctionExists(_id), "no-such-auction-id");
        DPA memory auction = auctions[_id];
        require(auction.winner == address(0x0), "auction-has-ended");
        require(!auction.stopped, "auction-has-been-stopped");
        uint256 price =
            _getCurrentPrice(auction.absoluteDecay, auction.floor, auction.endBlock, block.number);
        address bidder = _msgSender();
        _safeTransferFromExact(auction.paymentToken, bidder, auction.payee, price);
        _sendTokens(bidder, auction.tokens, auction.tokenAmounts);
        auction.stopped = true;
        auction.winner = bidder;
        auction.winningBlock = block.number;
        auction.winningPrice = price;
        auctions[_id] = auction;
        emit AuctionWon(_id, price, auction.paymentToken, bidder);
    }

    function getCurrentPrice(uint256 _id) external view override returns (uint256) {
        require(_auctionExists(_id), "no-such-auction-id");
        DPA memory a = auctions[_id];
        return _getCurrentPrice(a.absoluteDecay, a.floor, a.endBlock, block.number);
    }

    function _getCurrentPrice(
        uint256 m,
        uint256 f,
        uint256 e,
        uint256 t
    ) internal pure returns (uint256 p) {
        if (t > e) return f;
        if (m == 0) return f;
        // we know m is actually negative, so we're solving y=-mx+b (p = -(m * t) + b)
        uint256 b = f + ((m * e) / 1e18);
        p = b - ((m * t) / 1e18);
    }

    function _calulateAbsoluteDecay(
        uint256 c,
        uint256 f,
        uint256 s,
        uint256 e
    ) internal pure returns (uint256) {
        require(e > s, "invalid-ramp");
        require(c >= f, "price-not-descending-or-const");
        return ((c - f) * 1e18) / (e - s);
    }

    function _safeTransferFromExact(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        IERC20 token = IERC20(_token);
        uint256 before = token.balanceOf(_to);
        token.safeTransferFrom(_from, _to, _amount);
        require(token.balanceOf(_to) - before == _amount, "not-enough-transferred");
    }

    function createCollection() external override returns (uint256) {
        uint256 id = collectionCount.current();
        address owner = _msgSender();
        collections.set(id, owner);
        collectionCount.increment();
        emit CollectionCreated(id, owner);
        return id;
    }

    function transferCollection(address _to, uint256 _id)
        external
        override
        onlyCollectionOwner(_id)
    {
        collections.set(_id, _to);
        emit CollectionTransfer(_id, _msgSender(), _to);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/vesper/IController.sol";
import "./Strategy.sol";
import "../interfaces/bloq/ISwapManager.sol";
import "../interfaces/vesper/IVesperPoolV3.sol";
import "../interfaces/vesper/IStrategyV3.sol";
import "../interfaces/vesper/IPoolRewardsV3.sol";

/// @title This strategy will deposit collateral token in VesperV3 and earn interest.
abstract contract VesperV3Strategy is Strategy {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IVesperPoolV3 internal immutable vToken;

    constructor(
        address _controller,
        address _pool,
        address _receiptToken
    ) public Strategy(_controller, _pool, _receiptToken) {
        vToken = IVesperPoolV3(_receiptToken);
    }

    /**
     * @notice Migrate tokens from pool to this address
     * @dev Any working VesperV3 strategy has vTokens in strategy contract.
     * @dev There can be scenarios when pool already has vTokens and new
     * strategy will have to move those tokens from pool to self address.
     * @dev Only valid pool strategy is allowed to move tokens from pool.
     */
    function _migrateIn() internal override {
        require(controller.isPool(pool), "not-a-valid-pool");
        require(controller.strategy(pool) == address(this), "not-a-valid-strategy");
        IERC20(vToken).safeTransferFrom(pool, address(this), vToken.balanceOf(pool));
    }

    /**
     * @notice Migrate tokens out to pool.
     * @dev There can be scenarios when we want to use new strategy without
     * calling withdrawAll(). We can achieve this by moving tokens in pool
     * and new strategy will take care from there.
     * @dev Pause this strategy and move tokens out.
     */
    function _migrateOut() internal override {
        require(controller.isPool(pool), "not-a-valid-pool");
        _pause();
        IERC20(vToken).safeTransfer(pool, vToken.balanceOf(address(this)));
    }

    /// @notice Vesper pools are using this function so it should exist in all strategies.
    //solhint-disable-next-line no-empty-blocks
    function beforeWithdraw() external override onlyPool {}

    /**
     * @dev Calculate interest fee on earning from VesperV3 and transfer fee to fee collector.
     * Deposit available collateral from pool into VesperV3.
     * Anyone can call it except when paused.
     */
    function rebalance() external override whenNotPaused onlyKeeper {
        _claimReward();
        uint256 balance = collateralToken.balanceOf(pool);
        if (balance != 0) {
            _deposit(balance);
        }
    }

    /**
     * @notice Returns interest earned since last rebalance.
     */
    function interestEarned() public view override returns (uint256 collateralEarned) {
        // V3 Pool rewardToken can change over time so we don't store it in contract
        address _poolRewards = vToken.poolRewards();
        if (_poolRewards != address(0)) {
            address _rewardToken = IPoolRewardsV3(_poolRewards).rewardToken();
            uint256 _claimableRewards = IPoolRewardsV3(_poolRewards).claimable(address(this));
            // if there's any reward earned we add that to collateralEarned
            if (_claimableRewards != 0) {
                (, collateralEarned, ) = swapManager.bestOutputFixedInput(
                    _rewardToken,
                    address(collateralToken),
                    _claimableRewards
                );
            }
        }

        address[] memory _strategies = vToken.getStrategies();
        uint256 _len = _strategies.length;
        uint256 _unrealizedGain;

        for (uint256 i = 0; i < _len; i++) {
            uint256 _totalValue = IStrategyV3(_strategies[i]).totalValue();
            uint256 _debt = vToken.totalDebtOf(_strategies[i]);
            if (_totalValue > _debt) {
                _unrealizedGain = _unrealizedGain.add(_totalValue.sub(_debt));
            }
        }

        if (_unrealizedGain != 0) {
            // collateralEarned = rewards + unrealizedGain proportional to v2 share in v3
            collateralEarned = collateralEarned.add(
                _unrealizedGain.mul(vToken.balanceOf(address(this))).div(vToken.totalSupply())
            );
        }
    }

    /// @notice Returns true if strategy can be upgraded.
    /// @dev If there are no vTokens in strategy then it is upgradable
    function isUpgradable() external view override returns (bool) {
        return vToken.balanceOf(address(this)) == 0;
    }

    /// @notice This method is deprecated and will be removed from Strategies in next release
    function isReservedToken(address _token) public view override returns (bool) {
        address _poolRewards = vToken.poolRewards();
        return
            _token == address(vToken) ||
            (_poolRewards != address(0) && _token == IPoolRewardsV3(_poolRewards).rewardToken());
    }

    function _approveToken(uint256 _amount) internal override {
        collateralToken.safeApprove(pool, _amount);
        collateralToken.safeApprove(address(vToken), _amount);
        address _poolRewards = vToken.poolRewards();
        if (_poolRewards != address(0)) {
            address _rewardToken = IPoolRewardsV3(_poolRewards).rewardToken();
            for (uint256 i = 0; i < swapManager.N_DEX(); i++) {
                IERC20(_rewardToken).safeApprove(address(swapManager.ROUTERS(i)), _amount);
            }
        }
    }

    /**
     * @dev Converts rewardToken from V3 Pool to collateralToken
     * @notice V3 Pools will claim rewardToken onbehalf of caller on every withdraw/deposit
     */
    function _claimReward() internal override {
        // V3 Pool rewardToken can change over time so we don't store it in contract
        address _poolRewards = vToken.poolRewards();
        if (_poolRewards != address(0)) {
            IERC20 _rewardToken = IERC20(IPoolRewardsV3(_poolRewards).rewardToken());
            uint256 _rewardAmount = _rewardToken.balanceOf(address(this));
            if (_rewardAmount != 0)
                _safeSwap(address(_rewardToken), address(collateralToken), _rewardAmount);
        }
    }

    /**
     * @notice Total collateral locked in VesperV3.
     * @return Return value will be in collateralToken defined decimal.
     */
    function totalLocked() public view override returns (uint256) {
        uint256 _totalVTokens = vToken.balanceOf(pool).add(vToken.balanceOf(address(this)));
        return _convertToCollateral(_totalVTokens);
    }

    function _deposit(uint256 _amount) internal virtual override {
        collateralToken.safeTransferFrom(pool, address(this), _amount);
        vToken.deposit(_amount);
    }

    function _withdraw(uint256 _amount) internal override {
        _safeWithdraw(_convertToShares(_amount));
        collateralToken.safeTransfer(pool, collateralToken.balanceOf(address(this)));
    }

    /**
     * @dev V3 Pools may withdraw a partial amount of requested shares
     * Resulting in more burnt shares than actual collateral in V2
     * We make sure burnt shares equals to our expected value
     */
    function _safeWithdraw(uint256 _shares) internal {
        uint256 _maxShares = vToken.balanceOf(address(this));

        if (_shares != 0) {
            vToken.withdraw(_shares);

            require(
                vToken.balanceOf(address(this)) == _maxShares.sub(_shares),
                "Not enough shares withdrawn"
            );
        }
    }

    function _withdrawAll() internal override {
        _safeWithdraw(vToken.balanceOf(address(this)));
        _claimReward();
        collateralToken.safeTransfer(pool, collateralToken.balanceOf(address(this)));
    }

    function _convertToCollateral(uint256 _vTokenAmount) internal view returns (uint256) {
        uint256 _totalSupply = vToken.totalSupply();
        // avoids division by zero error when pool is empty
        return (_totalSupply != 0) ? vToken.totalValue().mul(_vTokenAmount).div(_totalSupply) : 0;
    }

    function _convertToShares(uint256 _collateralAmount) internal view returns (uint256) {
        return _collateralAmount.mul(vToken.totalSupply()).div(vToken.totalValue());
    }

    /**
     * @notice Returns interest earned since last rebalance.
     * @dev Empty implementation because V3 Strategies should collect pending interest fee
     */
    //solhint-disable-next-line no-empty-blocks
    function _updatePendingFee() internal override {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../Pausable.sol";
import "../interfaces/bloq/ISwapManager.sol";
import "../interfaces/vesper/IController.sol";
import "../interfaces/vesper/IStrategy.sol";
import "../interfaces/vesper/IVesperPool.sol";
import "../../sol-address-list/contracts/interfaces/IAddressListExt.sol";
import "../../sol-address-list/contracts/interfaces/IAddressListFactory.sol";

abstract contract Strategy is IStrategy, Pausable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    // solhint-disable-next-line
    ISwapManager public swapManager = ISwapManager(0xe382d9f2394A359B01006faa8A1864b8a60d2710);
    IController public immutable controller;
    IERC20 public immutable collateralToken;
    address public immutable receiptToken;
    address public immutable override pool;
    IAddressListExt public keepers;
    address internal constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    uint256 internal constant MAX_UINT_VALUE = type(uint256).max;

    event UpdatedSwapManager(address indexed previousSwapManager, address indexed newSwapManager);

    constructor(
        address _controller,
        address _pool,
        address _receiptToken
    ) public {
        require(_controller != address(0), "controller-address-is-zero");
        require(IController(_controller).isPool(_pool), "not-a-valid-pool");
        controller = IController(_controller);
        pool = _pool;
        collateralToken = IERC20(IVesperPool(_pool).token());
        receiptToken = _receiptToken;
    }

    modifier onlyAuthorized() {
        require(
            _msgSender() == address(controller) || _msgSender() == pool,
            "caller-is-not-authorized"
        );
        _;
    }

    modifier onlyController() {
        require(_msgSender() == address(controller), "caller-is-not-the-controller");
        _;
    }

    modifier onlyKeeper() {
        require(keepers.contains(_msgSender()), "caller-is-not-keeper");
        _;
    }

    modifier onlyPool() {
        require(_msgSender() == pool, "caller-is-not-the-pool");
        _;
    }

    function pause() external override onlyController {
        _pause();
    }

    function unpause() external override onlyController {
        _unpause();
    }

    /// @dev Approve all required tokens
    function approveToken() external onlyController {
        _approveToken(0);
        _approveToken(MAX_UINT_VALUE);
    }

    /// @dev Reset approval of all required tokens
    function resetApproval() external onlyController {
        _approveToken(0);
    }

    /**
     * @notice Create keeper list
     * @dev Create keeper list
     * NOTE: Any function with onlyKeeper modifier will not work until this function is called.
     * NOTE: Due to gas constraint this function cannot be called in constructor.
     */
    function createKeeperList() external onlyController {
        require(address(keepers) == address(0), "keeper-list-already-created");
        IAddressListFactory factory =
            IAddressListFactory(0xD57b41649f822C51a73C44Ba0B3da4A880aF0029);
        keepers = IAddressListExt(factory.createList());
        keepers.grantRole(keccak256("LIST_ADMIN"), _msgSender());
    }

    /**
     * @notice Update swap manager address
     * @param _swapManager swap manager address
     */
    function updateSwapManager(address _swapManager) external onlyController {
        require(_swapManager != address(0), "sm-address-is-zero");
        require(_swapManager != address(swapManager), "sm-is-same");
        emit UpdatedSwapManager(address(swapManager), _swapManager);
        swapManager = ISwapManager(_swapManager);
    }

    /**
     * @dev Deposit collateral token into lending pool.
     * @param _amount Amount of collateral token
     */
    function deposit(uint256 _amount) public override onlyKeeper {
        _updatePendingFee();
        _deposit(_amount);
    }

    /**
     * @notice Deposit all collateral token from pool to other lending pool.
     * Anyone can call it except when paused.
     */
    function depositAll() external virtual onlyKeeper {
        deposit(collateralToken.balanceOf(pool));
    }

    /**
     * @dev Withdraw collateral token from lending pool.
     * @param _amount Amount of collateral token
     */
    function withdraw(uint256 _amount) external override onlyAuthorized {
        _updatePendingFee();
        _withdraw(_amount);
    }

    /**
     * @dev Withdraw all collateral. No rebalance earning.
     * Controller only function, called when migrating strategy.
     */
    function withdrawAll() external override onlyController {
        _withdrawAll();
    }

    /**
     * @dev sweep given token to vesper pool
     * @param _fromToken token address to sweep
     */
    function sweepErc20(address _fromToken) external onlyKeeper {
        require(!isReservedToken(_fromToken), "not-allowed-to-sweep");
        if (_fromToken == ETH) {
            Address.sendValue(payable(pool), address(this).balance);
        } else {
            uint256 _amount = IERC20(_fromToken).balanceOf(address(this));
            IERC20(_fromToken).safeTransfer(pool, _amount);
        }
    }

    /// @dev Returns true if strategy can be upgraded.
    function isUpgradable() external view virtual override returns (bool) {
        return totalLocked() == 0;
    }

    /// @dev Returns address of token correspond to collateral token
    function token() external view override returns (address) {
        return address(collateralToken);
    }

    /// @dev Convert from 18 decimals to token defined decimals. Default no conversion.
    function convertFrom18(uint256 amount) public pure virtual returns (uint256) {
        return amount;
    }

    /// @dev report the interest earned since last rebalance
    function interestEarned() external view virtual returns (uint256);

    /// @dev Check whether given token is reserved or not. Reserved tokens are not allowed to sweep.
    function isReservedToken(address _token) public view virtual override returns (bool);

    /// @dev Returns total collateral locked here
    function totalLocked() public view virtual override returns (uint256);

    /// @dev For moving between versions of similar strategies
    function migrateIn() external onlyController {
        _migrateIn();
    }

    /// @dev For moving between versions of similar strategies
    function migrateOut() external onlyController {
        _migrateOut();
    }

    /**
     * @notice Handle earned interest fee
     * @dev Earned interest fee will go to the fee collector. We want fee to be in form of Vepseer
     * pool tokens not in collateral tokens so we will deposit fee in Vesper pool and send vTokens
     * to fee collactor.
     * @param _fee Earned interest fee in collateral token.
     */
    function _handleFee(uint256 _fee) internal virtual {
        if (_fee != 0) {
            IVesperPool(pool).deposit(_fee);
            uint256 _feeInVTokens = IERC20(pool).balanceOf(address(this));
            IERC20(pool).safeTransfer(controller.feeCollector(pool), _feeInVTokens);
        }
    }

    /**
     * @notice Safe swap via Uniswap
     * @dev There are many scenarios when token swap via Uniswap can fail, so this
     * method will wrap Uniswap call in a 'try catch' to make it fail safe.
     * @param _from address of from token
     * @param _to address of to token
     * @param _amount Amount to be swapped
     */
    function _safeSwap(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        (address[] memory _path, uint256 amountOut, uint256 rIdx) =
            swapManager.bestOutputFixedInput(_from, _to, _amount);
        if (amountOut != 0) {
            swapManager.ROUTERS(rIdx).swapExactTokensForTokens(
                _amount,
                1,
                _path,
                address(this),
                block.timestamp + 30
            );
        }
    }

    function _deposit(uint256 _amount) internal virtual;

    function _withdraw(uint256 _amount) internal virtual;

    function _approveToken(uint256 _amount) internal virtual;

    function _updatePendingFee() internal virtual;

    function _withdrawAll() internal virtual;

    function _migrateIn() internal virtual;

    function _migrateOut() internal virtual;

    function _claimReward() internal virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVesperPoolV3 is IERC20 {
    function deposit() external payable;

    function deposit(uint256 _share) external;

    function governor() external returns (address);

    function keepers() external returns (address);

    function multiTransfer(address[] memory _recipients, uint256[] memory _amounts)
        external
        returns (bool);

    function excessDebt(address _strategy) external view returns (uint256);

    function permit(
        address,
        address,
        uint256,
        uint256,
        uint8,
        bytes32,
        bytes32
    ) external;

    function reportEarning(
        uint256 _profit,
        uint256 _loss,
        uint256 _payback
    ) external;

    function resetApproval() external;

    function sweepERC20(address _fromToken) external;

    function withdraw(uint256 _amount) external;

    function withdrawETH(uint256 _amount) external;

    function whitelistedWithdraw(uint256 _amount) external;

    function feeCollector() external view returns (address);

    function pricePerShare() external view returns (uint256);

    function token() external view returns (address);

    function tokensHere() external view returns (uint256);

    function totalDebtOf(address _strategy) external view returns (uint256);

    function totalValue() external view returns (uint256);

    function withdrawFee() external view returns (uint256);

    function poolRewards() external view returns (address);

    function getStrategies() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IStrategyV3 {
    function totalValue() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IPoolRewardsV3 {
    /// Emitted after reward added
    event RewardAdded(uint256 reward);
    /// Emitted whenever any user claim rewards
    event RewardPaid(address indexed user, uint256 reward);
    /// Emitted when reward is ended
    event RewardEnded(address indexed dustReceiver, uint256 dust);
    // Emitted when pool governor update reward end time
    event UpdatedRewardEndTime(uint256 previousRewardEndTime, uint256 newRewardEndTime);

    function claimReward(address) external;

    function notifyRewardAmount(uint256 rewardAmount, uint256 endTime) external;

    function updateRewardEndTime() external;

    function updateReward(address) external;

    function withdrawRemaining(address _toAddress) external;

    function claimable(address) external view returns (uint256);

    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardForDuration() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function rewardToken() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./VesperV3Strategy.sol";

//solhint-disable no-empty-blocks
contract VesperV3StrategyUSDC is VesperV3Strategy {
    string public constant NAME = "Strategy-VesperV3-USDC";
    string public constant VERSION = "2.0.2";

    constructor(
        address _controller,
        address _pool,
        address _receiptToken
    ) public VesperV3Strategy(_controller, _pool, _receiptToken) {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./VesperV3Strategy.sol";

//solhint-disable no-empty-blocks
contract VesperV3StrategyDAI is VesperV3Strategy {
    string public constant NAME = "Strategy-VesperV3-DAI";
    string public constant VERSION = "2.0.9";

    constructor(
        address _controller,
        address _pool,
        address _receiptToken
    ) public VesperV3Strategy(_controller, _pool, _receiptToken) {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../Pausable.sol";
import "../interfaces/bloq/ISwapManager.sol";
import "../interfaces/vesper/IController.sol";
import "../interfaces/vesper/IStrategy.sol";
import "../interfaces/vesper/IVesperPool.sol";
import "../../sol-address-list/contracts/interfaces/IAddressListExt.sol";
import "../../sol-address-list/contracts/interfaces/IAddressListFactory.sol";
import "./Strategy.sol";

contract MultiStrategy is Strategy {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address[] strategies;
    uint numStrategies;

    constructor(
        address _controller,
        address _pool,
        address _receiptToken
    ) public Strategy(_controller, _pool, _receiptToken) {
    }

    function addNewStrategy(address strategy) public {
        strategies.push(strategy);
        ++numStrategies;
    }

    function rebalance() external override {
        //Strategy(strategy);
    }

    function beforeWithdraw() external override {

    }

    function interestEarned() external view virtual override returns (uint256) {
        return 0;
    }

    function isReservedToken(address _token) public view virtual override returns (bool) {
        return false;
    }

    function totalLocked() public view virtual override returns (uint256) {
        return 0;
    }

    function _handleFee(uint256 _fee) internal virtual override {
    }

    function _deposit(uint256 _amount) internal virtual override {

    }

    function _withdraw(uint256 _amount) internal virtual override {

    }

    function _approveToken(uint256 _amount) internal virtual override {

    }

    function _updatePendingFee() internal virtual override {

    }

    function _withdrawAll() internal virtual override {

    }

    function _migrateIn() internal virtual override {

    }

    function _migrateOut() internal virtual override {

    }

    function _claimReward() internal virtual override {

    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/vesper/IVesperPool.sol";
import "./Strategy.sol";
import "./Crv3PoolMgr.sol";

/// @title This strategy will deposit collateral token in Curve and earn interest.
abstract contract Crv3PoolStrategy is Crv3PoolMgr, Strategy {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    mapping(address => bool) private reservedToken;
    address[] private oracles;

    uint256 public constant ORACLE_PERIOD = 3600; // 1h
    uint256 public usdRate;
    uint256 public usdRateTimestamp;
    uint256 public immutable collIdx;

    uint256 public prevLpRate;
    uint256 public pendingFee;

    uint256 public depositSlippage = 500; // 10000 is 100%
    event UpdatedDepositSlippage(uint256 oldSlippage, uint256 newSlippage);

    constructor(
        address _controller,
        address _pool,
        uint256 _collateralIdx
    ) public Strategy(_controller, _pool, THREECRV) Crv3PoolMgr() {
        require(_collateralIdx < COINS.length, "Invalid collateral for 3Pool");
        require(
            COIN_ADDRS[_collateralIdx] == IVesperPool(_pool).token(),
            "Collateral does not match"
        );
        reservedToken[THREECRV] = true;
        reservedToken[COIN_ADDRS[_collateralIdx]] = true;
        reservedToken[CRV] = true;
        collIdx = _collateralIdx;
        _setupOracles();
    }

    function updateDepositSlippage(uint256 _newSlippage) external onlyController {
        require(_newSlippage != depositSlippage, "same-slippage");
        require(_newSlippage < 10000, "invalid-slippage-value");
        emit UpdatedDepositSlippage(depositSlippage, _newSlippage);
        depositSlippage = _newSlippage;
    }

    function _setupOracles() internal {
        oracles.push(swapManager.createOrUpdateOracle(CRV, WETH, ORACLE_PERIOD, 0));
        for (uint256 i = 0; i < COIN_ADDRS.length; i++) {
            oracles.push(swapManager.createOrUpdateOracle(COIN_ADDRS[i], WETH, ORACLE_PERIOD, 0));
        }
    }

    function _estimateSlippage(uint256 _amount, uint256 _slippage) internal pure returns (uint256) {
        return _amount.mul(10000 - _slippage).div(10000);
    }

    function _consultOracle(
        address _from,
        address _to,
        uint256 _amt
    ) internal returns (uint256, bool) {
        // from, to, amountIn, period, router
        uint256 rate;
        uint256 lastUpdate;
        (rate, lastUpdate, ) = swapManager.consult(_from, _to, _amt, ORACLE_PERIOD, 0);
        // We're looking at a TWAP ORACLE with a 1 hr Period that has been updated within the last hour
        if ((lastUpdate > (block.timestamp - ORACLE_PERIOD)) && (rate != 0)) return (rate, true);
        return (0, false);
    }

    function _consultOracleFree(
        address _from,
        address _to,
        uint256 _amt
    ) internal view returns (uint256, bool) {
        // from, to, amountIn, period, router
        uint256 rate;
        uint256 lastUpdate;
        (rate, lastUpdate) = swapManager.consultForFree(_from, _to, _amt, ORACLE_PERIOD, 0);
        // We're looking at a TWAP ORACLE with a 1 hr Period that has been updated within the last hour
        if ((lastUpdate > (block.timestamp - ORACLE_PERIOD)) && (rate != 0)) return (rate, true);
        return (0, false);
    }

    // given the rates of 3 stablecoins compared with a common denominator
    // return the lowest divided by the highest
    function _getSafeUsdRate() internal returns (uint256) {
        // use a stored rate if we've looked it up recently
        if (usdRateTimestamp > block.timestamp - ORACLE_PERIOD && usdRate != 0) return usdRate;
        // otherwise, calculate a rate and store it.
        uint256 lowest;
        uint256 highest;
        for (uint256 i = 0; i < COIN_ADDRS.length; i++) {
            // get the rate for $1
            (uint256 rate, bool isValid) = _consultOracle(COIN_ADDRS[i], WETH, 10**DECIMALS[i]);
            if (isValid) {
                if (lowest == 0 || rate < lowest) {
                    lowest = rate;
                }
                if (highest < rate) {
                    highest = rate;
                }
            }
        }
        // We only need to check one of them because if a single valid rate is returned,
        // highest == lowest and highest > 0 && lowest > 0
        require(lowest != 0, "no-oracle-rates");
        usdRateTimestamp = block.timestamp;
        usdRate = (lowest * 1e18) / highest;
        return usdRate;
    }

    function _getSafeUsdRateFree() internal view returns (uint256) {
        // use a stored rate if we've looked it up recently
        if (usdRateTimestamp > block.timestamp - ORACLE_PERIOD && usdRate != 0) return usdRate;
        // otherwise, calculate a rate and store it.
        uint256 lowest;
        uint256 highest;
        for (uint256 i = 0; i < COIN_ADDRS.length; i++) {
            // get the rate for $1
            (uint256 rate, bool isValid) = _consultOracleFree(COIN_ADDRS[i], WETH, 10**DECIMALS[i]);
            if (isValid) {
                if (lowest == 0 || rate < lowest) {
                    lowest = rate;
                }
                if (highest < rate) {
                    highest = rate;
                }
            }
        }
        // We only need to check one of them because if a single valid rate is returned,
        // highest == lowest and highest > 0 && lowest > 0
        require(lowest != 0, "no-oracle-rates");
        uint256 rate = (lowest * 1e18) / highest;
        return rate;
    }

    function interestEarned() external view override returns (uint256 collAmt) {
        uint256 crvAccrued = claimableRewards();
        if (crvAccrued != 0) {
            (, collAmt, ) = swapManager.bestOutputFixedInput(
                CRV,
                address(collateralToken),
                crvAccrued
            );
        }
        uint256 currentRate = _minimumLpPrice(_getSafeUsdRateFree());
        if (currentRate > prevLpRate) {
            collAmt = collAmt.add(
                convertFrom18(totalLp().mul(currentRate.sub(prevLpRate)).div(1e18))
            );
        }
    }

    function _updatePendingFee() internal override {
        uint256 currLpRate = _minimumLpPrice(_getSafeUsdRate());
        if (prevLpRate != 0) {
            if (currLpRate > prevLpRate) {
                pendingFee = pendingFee.add(
                    convertFrom18(
                        currLpRate
                            .sub(prevLpRate)
                            .mul(totalLp())
                            .mul(controller.interestFee(pool))
                            .div(1e36)
                    )
                );
            } else {
                // don't take fees if we're not making money
                return;
            }
        }
        prevLpRate = currLpRate;
    }

    function rebalance() external override whenNotPaused {
        // Check for LP appreciation and withdraw fees
        _updatePendingFee();
        uint256 fee = pendingFee;
        // Get CRV rewards and convert to Collateral
        // collect fees on profit from reward
        _claimCrv();
        uint256 earnedCollateral = _swapCrvToCollateral();
        if (earnedCollateral != 0) {
            fee = fee.add(earnedCollateral.mul(controller.interestFee(pool)).div(1e18));
        }
        if (fee != 0) {
            if (fee > earnedCollateral) {
                _unstakeAndWithdrawAsCollateral(fee.sub(earnedCollateral));
            }
            _handleFee(fee);
            pendingFee = 0;
        }
        // make any relevant deposits
        _deposit(collateralToken.balanceOf(pool));
    }

    /// Not needed for this strategy
    // solhint-disable-next-line no-empty-blocks
    function beforeWithdraw() external override {}

    /// @dev Check whether given token is reserved or not. Reserved tokens are not allowed to sweep.
    function isReservedToken(address _token) public view override returns (bool) {
        return reservedToken[_token];
    }

    /// @notice Returns true if strategy can be upgraded.
    /// @dev If there are no cTokens in strategy then it is upgradable
    function isUpgradable() external view override returns (bool) {
        return (totalLp() == 0) && (collateralToken.balanceOf(address(this)) == 0);
    }

    /// @dev Returns total collateral locked here
    function totalLocked() public view override returns (uint256) {
        return
            collateralToken
                .balanceOf(address(this))
                .add(getLpValueAs(totalLp().add(IERC20(crvLp).balanceOf(pool)), collIdx))
                .sub(pendingFee);
    }

    function _deposit(uint256 _amount) internal override {
        // get deposits from pool
        if (_amount != 0) {
            collateralToken.safeTransferFrom(pool, address(this), _amount);
        }
        // if we have any collateral left here from other operations, that should go too
        uint256[3] memory depositAmounts;
        depositAmounts[collIdx] = collateralToken.balanceOf(address(this));
        uint256 minLpAmount =
            _estimateSlippage(
                (depositAmounts[collIdx].mul(1e18)).div(_minimumLpPrice(_getSafeUsdRate())),
                depositSlippage
            );
        THREEPOOL.add_liquidity(depositAmounts, minLpAmount);
        _stakeAllLpToGauge();
    }

    function _withdraw(uint256 _amount) internal override {
        _unstakeAndWithdrawAsCollateral(_amount);
        collateralToken.safeTransfer(pool, IERC20(collateralToken).balanceOf(address(this)));
    }

    function _approveToken(uint256 _amount) internal override {
        collateralToken.safeApprove(pool, _amount);
        collateralToken.safeApprove(crvPool, _amount);
        for (uint256 i = 0; i < swapManager.N_DEX(); i++) {
            IERC20(CRV).safeApprove(address(swapManager.ROUTERS(i)), _amount);
        }
        IERC20(crvLp).safeApprove(crvGauge, _amount);
    }

    function _withdrawAll() internal override {
        pendingFee = 0;
        _unstakeAllLpFromGauge();
        _withdrawAllAs(collIdx);
        collateralToken.safeTransfer(pool, collateralToken.balanceOf(address(this)));
    }

    /// dev this function would only be a single line, so its omitted to save gas
    // solhint-disable-next-line no-empty-blocks
    function _claimReward() internal override {}

    function _unstakeAndWithdrawAsCollateral(uint256 _amount) internal {
        (uint256 lpToWithdraw, uint256 unstakeAmt) = calcWithdrawLpAs(_amount, collIdx);
        _unstakeLpFromGauge(unstakeAmt);
        uint256 minAmtOut =
            (convertFrom18(_minimumLpPrice(_getSafeUsdRate())) * lpToWithdraw) / 1e18;

        _withdrawAsFromCrvPool(lpToWithdraw, minAmtOut, collIdx);
    }

    function _swapCrvToCollateral() internal returns (uint256 collateralAmt) {
        uint256 amt = IERC20(CRV).balanceOf(address(this));
        if (amt != 0) {
            (address[] memory path, uint256 amountOut, uint256 rIdx) =
                swapManager.bestOutputFixedInput(CRV, address(collateralToken), amt);
            if (amountOut != 0) {
                collateralAmt = swapManager.ROUTERS(rIdx).swapExactTokensForTokens(
                    amt,
                    1,
                    path,
                    address(this),
                    block.timestamp
                )[path.length - 1];
            }
        }
    }

    function _migrateOut() internal override {
        require(controller.isPool(pool), "not-a-valid-pool");
        _pause();
        pendingFee = 0;
        _unstakeAllLpFromGauge();
        IERC20(crvLp).safeTransfer(pool, IERC20(crvLp).balanceOf(address(this)));
    }

    function _migrateIn() internal override {
        require(controller.isPool(pool), "not-a-valid-pool");
        require(controller.strategy(pool) == address(this), "not-a-valid-strategy");
        IERC20(crvLp).safeTransferFrom(pool, address(this), IERC20(crvLp).balanceOf(pool));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./CrvPoolMgrBase.sol";
import "../interfaces/curve/IStableSwap3Pool.sol";

contract Crv3PoolMgr is CrvPoolMgrBase {
    using SafeMath for uint256;

    IStableSwap3Pool public constant THREEPOOL =
        IStableSwap3Pool(0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7);
    address public constant THREECRV = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address public constant GAUGE = 0xbFcF63294aD7105dEa65aA58F8AE5BE2D9d0952A;

    /* solhint-disable var-name-mixedcase */
    string[3] public COINS = ["DAI", "USDC", "USDT"];

    address[3] public COIN_ADDRS = [
        0x6B175474E89094C44Da98b954EedeAC495271d0F, // DAI
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, // USDC
        0xdAC17F958D2ee523a2206206994597C13D831ec7 // USDT
    ];

    uint256[3] public DECIMALS = [18, 6, 6];

    /* solhint-enable */

    // solhint-disable-next-line no-empty-blocks
    constructor() public CrvPoolMgrBase(address(THREEPOOL), THREECRV, GAUGE) {}

    function _minimumLpPrice(uint256 _safeRate) internal view returns (uint256) {
        return ((THREEPOOL.get_virtual_price() * _safeRate) / 1e18);
    }

    function _depositToCrvPool(
        uint256 _daiAmount,
        uint256 _usdcAmount,
        uint256 _usdtAmount
    ) internal {
        uint256[3] memory depositAmounts = [_daiAmount, _usdcAmount, _usdtAmount];
        // using 1 for min_mint_amount, but we may want to improve this logic
        THREEPOOL.add_liquidity(depositAmounts, 1);
    }

    function _depositDaiToCrvPool(uint256 _daiAmount, bool _stake) internal {
        if (_daiAmount != 0) {
            THREEPOOL.add_liquidity([_daiAmount, 0, 0], 1);
            if (_stake) {
                _stakeAllLpToGauge();
            }
        }
    }

    function _withdrawAsFromCrvPool(
        uint256 _lpAmount,
        uint256 _minAmt,
        uint256 i
    ) internal {
        THREEPOOL.remove_liquidity_one_coin(_lpAmount, int128(i), _minAmt);
    }

    function _withdrawAllAs(uint256 i) internal {
        uint256 lpAmt = IERC20(crvLp).balanceOf(address(this));
        if (lpAmt != 0) {
            THREEPOOL.remove_liquidity_one_coin(lpAmt, int128(i), 0);
        }
    }

    function calcWithdrawLpAs(uint256 _amtNeeded, uint256 i)
        public
        view
        returns (uint256 lpToWithdraw, uint256 unstakeAmt)
    {
        uint256 lp = IERC20(crvLp).balanceOf(address(this));
        uint256 tlp = lp.add(IERC20(crvGauge).balanceOf(address(this)));
        lpToWithdraw = _amtNeeded.mul(tlp).div(getLpValueAs(tlp, i));
        lpToWithdraw = (lpToWithdraw > tlp) ? tlp : lpToWithdraw;
        if (lpToWithdraw > lp) {
            unstakeAmt = lpToWithdraw.sub(lp);
        }
    }

    function getLpValueAs(uint256 _lpAmount, uint256 i) public view returns (uint256) {
        return (_lpAmount != 0) ? THREEPOOL.calc_withdraw_one_coin(_lpAmount, int128(i)) : 0;
    }

    function estimateFeeImpact(uint256 _amount) public view returns (uint256) {
        return _amount.mul(uint256(1e10).sub(estimatedFees())).div(1e10);
    }

    function estimatedFees() public view returns (uint256) {
        return THREEPOOL.fee().mul(3);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces/curve/ILiquidityGaugeV2.sol";
import "../interfaces/curve/ITokenMinter.sol";

abstract contract CrvPoolMgrBase {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address public immutable crvPool;
    address public immutable crvLp;
    address public immutable crvGauge;
    address public constant CRV_MINTER = 0xd061D61a4d941c39E5453435B6345Dc261C2fcE0;
    address public constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;

    constructor(
        address _pool,
        address _lp,
        address _gauge
    ) public {
        require(_pool != address(0x0), "CRVMgr: invalid curve pool");
        require(_lp != address(0x0), "CRVMgr: invalid lp token");
        require(_gauge != address(0x0), "CRVMgr: invalid gauge");

        crvPool = _pool;
        crvLp = _lp;
        crvGauge = _gauge;
    }

    // requires that gauge has approval for lp token
    function _stakeAllLpToGauge() internal {
        uint256 balance = IERC20(crvLp).balanceOf(address(this));
        if (balance != 0) {
            ILiquidityGaugeV2(crvGauge).deposit(balance);
        }
    }

    function _unstakeAllLpFromGauge() internal {
        _unstakeLpFromGauge(IERC20(crvGauge).balanceOf(address(this)));
    }

    function _unstakeLpFromGauge(uint256 _amount) internal {
        if (_amount != 0) {
            ILiquidityGaugeV2(crvGauge).withdraw(_amount);
        }
    }

    function _claimCrv() internal {
        ITokenMinter(CRV_MINTER).mint(crvGauge);
    }

    function _setCheckpoint() internal {
        ILiquidityGaugeV2(crvGauge).user_checkpoint(address(this));
    }

    function claimableRewards() public view returns (uint256) {
        //Total Mintable - Previously minted
        return
            ILiquidityGaugeV2(crvGauge).integrate_fraction(address(this)).sub(
                ITokenMinter(CRV_MINTER).minted(address(this), crvGauge)
            );
    }

    function totalLp() public view returns (uint256 total) {
        total = IERC20(crvLp).balanceOf(address(this)).add(
            IERC20(crvGauge).balanceOf(address(this))
        );
    }
}

// SPDX-License-Identifier: MIT
/* solhint-disable */
pragma solidity 0.6.12;

// Not a complete interface, but should have what we need
interface IStableSwap3Pool {
    function coins() external view returns (address[] memory);

    function fee() external view returns (uint256); // fee * 1e10

    function lp_token() external view returns (address);

    function A() external view returns (uint256);

    function A_precise() external view returns (uint256);

    function balances(uint256 i) external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function calc_token_amount(uint256[3] memory _amounts, bool is_deposit)
        external
        view
        returns (uint256);

    function add_liquidity(uint256[3] memory _amounts, uint256 _min_mint_amount) external;

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function remove_liquidity(uint256 _amount, uint256[3] memory _min_amounts) external;

    function remove_liquidity_imbalance(uint256[3] memory _amounts, uint256 _max_burn_amount)
        external
        returns (uint256);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i)
        external
        view
        returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 _min_amount
    ) external;
}
/* solhint-enable */

// SPDX-License-Identifier: MIT
/* solhint-disable */
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Not a complete interface, but should have what we need
interface ILiquidityGaugeV2 is IERC20 {
    function deposit(uint256 _value) external;

    function withdraw(uint256 _value) external;

    function claimable_tokens(address addr) external returns (uint256);

    function integrate_fraction(address addr) external view returns (uint256);

    function user_checkpoint(address addr) external returns (bool);
}
/* solhint-enable */

// SPDX-License-Identifier: MIT
/* solhint-disable */
pragma solidity 0.6.12;

// Not a complete interface, but should have what we need
interface ITokenMinter {
    function minted(address arg0, address arg1) external view returns (uint256);

    function mint(address gauge_addr) external;
}
/* solhint-enable */

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./Crv3PoolStrategy.sol";

//solhint-disable no-empty-blocks
contract Crv3PoolStrategyUSDC is Crv3PoolStrategy {
    using SafeMath for uint256;

    string public constant NAME = "Strategy-Curve-3pool-USDC";
    string public constant VERSION = "1.0.0";

    constructor(address _controller, address _pool)
        public
        Crv3PoolStrategy(_controller, _pool, 1)
    {}

    function convertFrom18(uint256 amount) public pure override returns (uint256) {
        return amount.div(10**12);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

/**
 * @title PaymentSplitter
 * @dev This contract allows to split ERC20 and Ether tokens among a group of accounts. The sender does not need to be aware
 * that the token(s) (payment) will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the payment(s) that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release} or {releaseEther}
 * function.
 */
contract PaymentSplitter is Context {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    event PayeeAdded(address indexed payee, uint256 share);
    event PaymentReleased(address indexed payee, address indexed asset, uint256 tokens);

    // Total share.
    uint256 public totalShare;
    // Total released for an asset.
    mapping(address => uint256) public totalReleased;
    // Payee's share
    mapping(address => uint256) public share;
    // Payee's share released for an asset
    mapping(address => mapping(address => uint256)) public released;
    // list of payees
    address[] public payees;
    address public veth;
    address private constant ETHER_ASSET = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant VESPER_DEPLOYER = 0xB5AbDABE50b5193d4dB92a16011792B22bA3Ef51;
    uint256 public constant HIGH = 20e18; // 20 Ether
    uint256 public constant LOW = 5e18; // 5 Ether

    /**
     * @dev Creates an instance of `PaymentSplitter` where each account in `_payees` is assigned token(s) at
     * the matching position in the `_share` array.
     *
     * All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
     * duplicates in `payees`.
     * @param _payees -  address(es) of payees eligible to receive token(s)
     * @param _share - list of shares, transferred to payee in provided ratio.
     * @param _veth - pETH address, used for vesper deployer top up
     */
    constructor(
        address[] memory _payees,
        uint256[] memory _share,
        address _veth
    ) public {
        // solhint-disable-next-line max-line-length
        require(_payees.length == _share.length, "payees-and-share-length-mismatch");
        require(_payees.length > 0, "no-payees");
        require(_veth != address(0), "invalid-veth");
        veth = _veth;

        for (uint256 i = 0; i < _payees.length; i++) {
            _addPayee(_payees[i], _share[i]);
        }
    }

    //solhint-disable no-empty-blocks
    receive() external payable {}

    /**
     * @dev Transfer of ERC20 token(s) to `payee` based on share and their previous withdrawals.
     * @param _payee - payee's address to receive token(s)
     * @param _asset - ERC20 token's address
     */
    function release(address _payee, address _asset) external {
        require(share[_payee] > 0, "payee-does-not-have-share");
        _topUp();
        uint256 totalReceived = IERC20(_asset).balanceOf(address(this)).add(totalReleased[_asset]);
        uint256 tokens = _calculateAndUpdateReleasedTokens(_payee, _asset, totalReceived);
        IERC20(_asset).safeTransfer(_payee, tokens);
        emit PaymentReleased(_payee, _asset, tokens);
    }

    /**
     * @dev Transfer of ether to `payee` based on share and their previous withdrawals.
     * @param _payee - payee's address to receive ether
     */
    function releaseEther(address payable _payee) external {
        require(share[_payee] > 0, "payee-does-not-have-share");
        uint256 totalReceived = address(this).balance.add(totalReleased[ETHER_ASSET]);
        // find total received amount
        uint256 amount = _calculateAndUpdateReleasedTokens(_payee, ETHER_ASSET, totalReceived);
        // Transfer Ether to Payee.
        Address.sendValue(_payee, amount);
        emit PaymentReleased(_payee, ETHER_ASSET, amount);
    }

    /// @notice Top up Vesper deployer address
    function topUp() external {
        _topUp();
    }

    /// @dev Top up Vesper deployer address when balance goes below low mark.
    function _topUp() internal {
        uint256 totalEthBalance =
            VESPER_DEPLOYER.balance.add(IERC20(WETH).balanceOf(VESPER_DEPLOYER)).add(
                IERC20(veth).balanceOf(VESPER_DEPLOYER)
            );
        // transfer only when balance is < low mark
        if (totalEthBalance < LOW) {
            uint256 amount =
                IERC20(veth).balanceOf(address(this)) > (HIGH.sub(totalEthBalance))
                    ? (HIGH.sub(totalEthBalance))
                    : IERC20(veth).balanceOf(address(this));
            IERC20(veth).safeTransfer(VESPER_DEPLOYER, amount);
        }
    }

    /**
     * @dev Calculate token(s) for `payee` based on share and their previous withdrawals.
     * @param _payee - payee's address
     * @param _asset - token's address
     * return token(s)/ ether to be released
     */
    function _calculateAndUpdateReleasedTokens(
        address _payee,
        address _asset,
        uint256 _totalReceived
    ) private returns (uint256 tokens) {
        // find eligible token(s)/ether for a payee
        uint256 releasedTokens = released[_payee][_asset];
        tokens = _totalReceived.mul(share[_payee]).div(totalShare).sub(releasedTokens);
        require(tokens != 0, "payee-is-not-due-for-tokens");
        // update released token(s)
        released[_payee][_asset] = releasedTokens.add(tokens);
        totalReleased[_asset] = totalReleased[_asset].add(tokens);
    }

    /**
     * @dev Add a new payee to the contract.
     * @param _payee - payee address
     * @param _share -  payee's share
     */
    function _addPayee(address _payee, uint256 _share) private {
        require(_payee != address(0), "payee-is-zero-address");
        require(_share > 0, "payee-with-zero-share");
        require(share[_payee] == 0, "payee-exists-with-share");
        payees.push(_payee);
        share[_payee] = _share;
        totalShare = totalShare.add(_share);
        emit PayeeAdded(_payee, _share);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface TokenLikeTest is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;

    function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../Pausable.sol";
import "../interfaces/vesper/IController.sol";
import "../interfaces/vesper/IVesperPool.sol";
import "../interfaces/vesper/IPoolRewards.sol";
import "../../sol-address-list/contracts/interfaces/IAddressListExt.sol";
import "../../sol-address-list/contracts/interfaces/IAddressListFactory.sol";

/// @title Holding pool share token
// solhint-disable no-empty-blocks
abstract contract PoolShareToken is ERC20, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    IERC20 public immutable token;
    IAddressListExt public immutable feeWhiteList;
    IController public immutable controller;

    /// @dev The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    /// @dev The EIP-712 typehash for the permit struct used by the contract
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    bytes32 public immutable domainSeparator;

    uint256 internal constant MAX_UINT_VALUE = type(uint256).max;
    mapping(address => uint256) public nonces;
    event Deposit(address indexed owner, uint256 shares, uint256 amount);
    event Withdraw(address indexed owner, uint256 shares, uint256 amount);

    constructor(
        string memory _name,
        string memory _symbol,
        address _token,
        address _controller
    ) public ERC20(_name, _symbol) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        token = IERC20(_token);
        controller = IController(_controller);
        IAddressListFactory factory =
            //IAddressListFactory(0xD57b41649f822C51a73C44Ba0B3da4A880aF0029); // mainnet
            IAddressListFactory(0x2A62975b1Dc4f6F8201E15C97E400f51724C8158); // kovan
        IAddressListExt _feeWhiteList = IAddressListExt(factory.createList());
        _feeWhiteList.grantRole(keccak256("LIST_ADMIN"), _controller);
        feeWhiteList = _feeWhiteList;
        domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(_name)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    /**
     * @notice Deposit ERC20 tokens and receive pool shares depending on the current share price.
     * @param amount ERC20 token amount.
     */
    function deposit(uint256 amount) external virtual nonReentrant whenNotPaused {
        _deposit(amount);
    }

    /**
     * @notice Deposit ERC20 tokens with permit aka gasless approval.
     * @param amount ERC20 token amount.
     * @param deadline The time at which signature will expire
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function depositWithPermit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual nonReentrant whenNotPaused {
        IVesperPool(address(token)).permit(_msgSender(), address(this), amount, deadline, v, r, s);
        _deposit(amount);
    }

    /**
     * @notice Withdraw collateral based on given shares and the current share price.
     * Transfer earned rewards to caller. Withdraw fee, if any, will be deduced from
     * given shares and transferred to feeCollector. Burn remaining shares and return collateral.
     * @param shares Pool shares. It will be in 18 decimals.
     */
    function withdraw(uint256 shares) external virtual nonReentrant whenNotShutdown {
        _withdraw(shares);
    }

    /**
     * @notice Withdraw collateral based on given shares and the current share price.
     * Transfer earned rewards to caller. Burn shares and return collateral.
     * @dev No withdraw fee will be assessed when this function is called.
     * Only some white listed address can call this function.
     * @param shares Pool shares. It will be in 18 decimals.
     */
    function withdrawByStrategy(uint256 shares) external virtual nonReentrant whenNotShutdown {
        require(feeWhiteList.get(_msgSender()) != 0, "Not a white listed address");
        _withdrawByStrategy(shares);
    }

    /**
     * @notice Transfer tokens to multiple recipient
     * @dev Left 160 bits are the recipient address and the right 96 bits are the token amount.
     * @param bits array of uint
     * @return true/false
     */
    function multiTransfer(uint256[] memory bits) external returns (bool) {
        for (uint256 i = 0; i < bits.length; i++) {
            address a = address(bits[i] >> 96);
            uint256 amount = bits[i] & ((1 << 96) - 1);
            require(transfer(a, amount), "Transfer failed");
        }
        return true;
    }

    /**
     * @notice Triggers an approval from owner to spends
     * @param owner The address to approve from
     * @param spender The address to be approved
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(deadline >= block.timestamp, "Expired");
        bytes32 digest =
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    domainSeparator,
                    keccak256(
                        abi.encode(
                            PERMIT_TYPEHASH,
                            owner,
                            spender,
                            amount,
                            nonces[owner]++,
                            deadline
                        )
                    )
                )
            );
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0) && signatory == owner, "Invalid signature");
        _approve(owner, spender, amount);
    }

    /**
     * @notice Get price per share
     * @dev Return value will be in token defined decimals.
     */
    function getPricePerShare() external view returns (uint256) {
        if (totalSupply() == 0) {
            return convertFrom18(1e18);
        }
        return totalValue().mul(1e18).div(totalSupply());
    }

    /// @dev Convert to 18 decimals from token defined decimals. Default no conversion.
    function convertTo18(uint256 amount) public pure virtual returns (uint256) {
        return amount;
    }

    /// @dev Convert from 18 decimals to token defined decimals. Default no conversion.
    function convertFrom18(uint256 amount) public pure virtual returns (uint256) {
        return amount;
    }

    /// @dev Get fee collector address
    function feeCollector() public view virtual returns (address) {
        return controller.feeCollector(address(this));
    }

    /// @dev Returns the token stored in the pool. It will be in token defined decimals.
    function tokensHere() public view virtual returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @dev Returns sum of token locked in other contracts and token stored in the pool.
     * Default tokensHere. It will be in token defined decimals.
     */
    function totalValue() public view virtual returns (uint256) {
        return tokensHere();
    }

    /**
     * @notice Get withdraw fee for this pool
     * @dev Format: 1e16 = 1% fee
     */
    function withdrawFee() public view virtual returns (uint256) {
        return controller.withdrawFee(address(this));
    }

    /**
     * @dev Hook that is called just before burning tokens. To be used i.e. if
     * collateral is stored in a different contract and needs to be withdrawn.
     * @param share Pool share in 18 decimals
     */
    function _beforeBurning(uint256 share) internal virtual {}

    /**
     * @dev Hook that is called just after burning tokens. To be used i.e. if
     * collateral stored in a different/this contract needs to be transferred.
     * @param amount Collateral amount in collateral token defined decimals.
     */
    function _afterBurning(uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called just before minting new tokens. To be used i.e.
     * if the deposited amount is to be transferred from user to this contract.
     * @param amount Collateral amount in collateral token defined decimals.
     */
    function _beforeMinting(uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called just after minting new tokens. To be used i.e.
     * if the deposited amount is to be transferred to a different contract.
     * @param amount Collateral amount in collateral token defined decimals.
     */
    function _afterMinting(uint256 amount) internal virtual {}

    /**
     * @dev Calculate shares to mint based on the current share price and given amount.
     * @param amount Collateral amount in collateral token defined decimals.
     */
    function _calculateShares(uint256 amount) internal view returns (uint256) {
        require(amount != 0, "amount is 0");

        uint256 _totalSupply = totalSupply();
        uint256 _totalValue = convertTo18(totalValue());
        uint256 shares =
            (_totalSupply == 0 || _totalValue == 0)
                ? amount
                : amount.mul(_totalSupply).div(_totalValue);
        return shares;
    }

    /// @dev Deposit incoming token and mint pool token i.e. shares.
    function _deposit(uint256 amount) internal {
        uint256 shares = _calculateShares(convertTo18(amount));
        _beforeMinting(amount);
        _mint(_msgSender(), shares);
        _afterMinting(amount);
        emit Deposit(_msgSender(), shares, amount);
    }

    /// @dev Handle withdraw fee calculation and fee transfer to fee collector.
    function _handleFee(uint256 shares) internal returns (uint256 _sharesAfterFee) {
        if (withdrawFee() != 0) {
            uint256 _fee = shares.mul(withdrawFee()).div(1e18);
            _sharesAfterFee = shares.sub(_fee);
            _transfer(_msgSender(), feeCollector(), _fee);
        } else {
            _sharesAfterFee = shares;
        }
    }

    /// @dev Update pool reward of sender and receiver before transfer.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 /* amount */
    ) internal virtual override {
        address poolRewards = controller.poolRewards(address(this));
        if (poolRewards != address(0)) {
            if (from != address(0)) {
                IPoolRewards(poolRewards).updateReward(from);
            }
            if (to != address(0)) {
                IPoolRewards(poolRewards).updateReward(to);
            }
        }
    }

    /// @dev Burns shares and returns the collateral value, after fee, of those.
    function _withdraw(uint256 shares) internal {
        require(shares != 0, "share is 0");
        _beforeBurning(shares);
        uint256 sharesAfterFee = _handleFee(shares);
        uint256 amount =
            convertFrom18(sharesAfterFee.mul(convertTo18(totalValue())).div(totalSupply()));

        _burn(_msgSender(), sharesAfterFee);
        _afterBurning(amount);
        emit Withdraw(_msgSender(), shares, amount);
    }

    /// @dev Burns shares and returns the collateral value of those.
    function _withdrawByStrategy(uint256 shares) internal {
        require(shares != 0, "Withdraw must be greater than 0");
        _beforeBurning(shares);
        uint256 amount = convertFrom18(shares.mul(convertTo18(totalValue())).div(totalSupply()));
        _burn(_msgSender(), shares);
        _afterBurning(amount);
        emit Withdraw(_msgSender(), shares, amount);
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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/vesper/IController.sol";
import "../interfaces/vesper/IPoolRewards.sol";

contract PoolRewards is IPoolRewards, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    address public immutable override pool;
    IERC20 public immutable rewardToken;
    IController public immutable controller;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public constant REWARD_DURATION = 30 days;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    event RewardAdded(uint256 reward);

    constructor(
        address _pool,
        address _rewardToken,
        address _controller
    ) public {
        require(_controller != address(0), "Controller address is zero");
        controller = IController(_controller);
        rewardToken = IERC20(_rewardToken);
        pool = _pool;
    }

    event RewardPaid(address indexed user, uint256 reward);

    /**
     * @dev Notify that reward is added.
     * Also updates reward rate and reward earning period.
     */
    function notifyRewardAmount(uint256 rewardAmount) external override {
        _updateReward(address(0));
        require(msg.sender == address(controller), "Not authorized");
        require(address(rewardToken) != address(0), "Rewards token not set");
        if (block.timestamp >= periodFinish) {
            rewardRate = rewardAmount.div(REWARD_DURATION);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = rewardAmount.add(leftover).div(REWARD_DURATION);
        }

        uint256 balance = rewardToken.balanceOf(address(this));
        require(rewardRate <= balance.div(REWARD_DURATION), "Reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(REWARD_DURATION);
        emit RewardAdded(rewardAmount);
    }

    /// @dev Claim reward earned so far.
    function claimReward(address account) external override nonReentrant {
        _updateReward(account);
        uint256 reward = rewards[account];
        if (reward != 0) {
            rewards[account] = 0;
            rewardToken.safeTransfer(account, reward);
            emit RewardPaid(account, reward);
        }
    }

    /**
     * @dev Updated reward for given account. Only Pool can call
     */
    function updateReward(address _account) external override {
        require(msg.sender == pool, "Only pool can update reward");
        _updateReward(_account);
    }

    function rewardForDuration() external view override returns (uint256) {
        return rewardRate.mul(REWARD_DURATION);
    }

    /// @dev Returns claimable reward amount.
    function claimable(address account) public view override returns (uint256) {
        return
            IERC20(pool)
                .balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(1e18)
                .add(rewards[account]);
    }

    /// @dev Returns timestamp of last reward update
    function lastTimeRewardApplicable() public view override returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function rewardPerToken() public view override returns (uint256) {
        if (IERC20(pool).totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(
                    IERC20(pool).totalSupply()
                )
            );
    }

    function _updateReward(address _account) private {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (_account != address(0)) {
            rewards[_account] = claimable(_account);
            userRewardPerTokenPaid[_account] = rewardPerTokenStored;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "../interfaces//maker/IMakerDAO.sol";
import "../interfaces/vesper/ICollateralManager.sol";
import "../interfaces/vesper/IController.sol";

contract DSMath {
    uint256 internal constant RAY = 10**27;
    uint256 internal constant WAD = 10**18;

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "sub-overflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function toInt(uint256 x) internal pure returns (int256 y) {
        y = int256(x);
        require(y >= 0, "int-overflow");
    }

    function toRad(uint256 wad) internal pure returns (uint256 rad) {
        rad = mul(wad, RAY);
    }

    /**
     * @notice It will work only if _dec < 18
     */
    function convertTo18(uint256 _dec, uint256 _amt) internal pure returns (uint256 amt) {
        amt = mul(_amt, 10**(18 - _dec));
    }
}

contract CollateralManager is ICollateralManager, DSMath, ReentrancyGuard {
    using SafeERC20 for IERC20;
    mapping(uint256 => address) public override vaultOwner;
    mapping(bytes32 => address) public mcdGemJoin;
    mapping(uint256 => bytes32) public vaultType;
    address public constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public override mcdManager = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;
    address public mcdDaiJoin = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;
    address public mcdSpot = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address public mcdJug = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    uint256 internal constant MAX_UINT_VALUE = type(uint256).max;
    IController public immutable controller;

    modifier onlyVaultOwner(uint256 vaultNum) {
        require(msg.sender == vaultOwner[vaultNum], "Not a vault owner");
        _;
    }

    modifier onlyController() {
        require(msg.sender == address(controller), "Not a controller");
        _;
    }

    constructor(address _controller) public {
        require(_controller != address(0), "_controller is zero");
        controller = IController(_controller);
    }

    /**
     * @dev Add gemJoin adapter address from Maker in mapping
     * @param gemJoins Array of gem join addresses
     */
    function addGemJoin(address[] calldata gemJoins) external override onlyController {
        require(gemJoins.length != 0, "No gemJoin address");
        for (uint256 i; i < gemJoins.length; i++) {
            address gemJoin = gemJoins[i];
            bytes32 ilk = GemJoinLike(gemJoin).ilk();
            mcdGemJoin[ilk] = gemJoin;
        }
    }

    /**
     * @dev Store vault info.
     * @param vaultNum Vault number.
     * @param collateralType Collateral type of vault.
     */
    function registerVault(uint256 vaultNum, bytes32 collateralType) external override {
        require(msg.sender == ManagerLike(mcdManager).owns(vaultNum), "Not a vault owner");
        vaultOwner[vaultNum] = msg.sender;
        vaultType[vaultNum] = collateralType;
    }

    /**
     * @dev Update MCD addresses.
     */
    function updateMCDAddresses(
        address _mcdManager,
        address _mcdDaiJoin,
        address _mcdSpot,
        address _mcdJug
    ) external onlyController {
        mcdManager = _mcdManager;
        mcdDaiJoin = _mcdDaiJoin;
        mcdSpot = _mcdSpot;
        mcdJug = _mcdJug;
    }

    /**
     * @dev Deposit ERC20 collateral.
     * @param vaultNum Vault number.
     * @param amount ERC20 amount to deposit.
     */
    function depositCollateral(uint256 vaultNum, uint256 amount)
        external
        override
        nonReentrant
        onlyVaultOwner(vaultNum)
    {
        // Receives Gem amount, approve and joins it into the vat.
        // Also convert amount to 18 decimal
        amount = joinGem(mcdGemJoin[vaultType[vaultNum]], amount);

        ManagerLike manager = ManagerLike(mcdManager);
        // Locks Gem amount into the CDP
        VatLike(manager.vat()).frob(
            vaultType[vaultNum],
            manager.urns(vaultNum),
            address(this),
            address(this),
            toInt(amount),
            0
        );
    }

    /**
     * @dev Withdraw collateral.
     * @param vaultNum Vault number.
     * @param amount Collateral amount to withdraw.
     */
    function withdrawCollateral(uint256 vaultNum, uint256 amount)
        external
        override
        nonReentrant
        onlyVaultOwner(vaultNum)
    {
        ManagerLike manager = ManagerLike(mcdManager);
        GemJoinLike gemJoin = GemJoinLike(mcdGemJoin[vaultType[vaultNum]]);

        uint256 amount18 = convertTo18(gemJoin.dec(), amount);

        // Unlocks Gem amount18 from the CDP
        manager.frob(vaultNum, -toInt(amount18), 0);

        // Moves Gem amount18 from the CDP urn to this address
        manager.flux(vaultNum, address(this), amount18);

        // Exits Gem amount to this address as a token
        gemJoin.exit(address(this), amount);

        // Send Gem to pool's address
        IERC20(gemJoin.gem()).safeTransfer(vaultOwner[vaultNum], amount);
    }

    /**
     * @dev Payback borrowed DAI.
     * @param vaultNum Vault number.
     * @param amount Dai amount to payback.
     */
    function payback(uint256 vaultNum, uint256 amount) external override onlyVaultOwner(vaultNum) {
        ManagerLike manager = ManagerLike(mcdManager);
        address urn = manager.urns(vaultNum);
        address vat = manager.vat();
        bytes32 ilk = vaultType[vaultNum];

        // Calculate dai debt
        uint256 _daiDebt = _getVaultDebt(ilk, urn, vat);
        require(_daiDebt >= amount, "paying-excess-debt");

        // Approve and join dai in vat
        joinDai(urn, amount);
        manager.frob(vaultNum, 0, _getWipeAmount(ilk, urn, vat));
    }

    /**
     * @notice Borrow DAI.
     * @dev In edge case, when we hit DAI mint limit, we might end up borrowing
     * less than what is being asked.
     * @param vaultNum Vault number.
     * @param amount Dai amount to borrow. Actual borrow amount may be less than "amount"
     */
    function borrow(uint256 vaultNum, uint256 amount) external override onlyVaultOwner(vaultNum) {
        ManagerLike manager = ManagerLike(mcdManager);
        address vat = manager.vat();
        // Safety check in scenario where current debt and request borrow will exceed max dai limit
        uint256 _maxAmount = maxAvailableDai(vat, vaultNum);
        if (amount > _maxAmount) {
            amount = _maxAmount;
        }

        // Generates debt in the CDP
        manager.frob(vaultNum, 0, _getBorrowAmount(vat, manager.urns(vaultNum), vaultNum, amount));
        // Moves the DAI amount (balance in the vat in rad) to pool's address
        manager.move(vaultNum, address(this), toRad(amount));
        // Allows adapter to access to pool's DAI balance in the vat
        if (VatLike(vat).can(address(this), mcdDaiJoin) == 0) {
            VatLike(vat).hope(mcdDaiJoin);
        }
        // Exits DAI as a token to user's address
        DaiJoinLike(mcdDaiJoin).exit(msg.sender, amount);
    }

    /// @dev sweep given ERC20 token to treasury pool
    function sweepErc20(address fromToken) external {
        uint256 amount = IERC20(fromToken).balanceOf(address(this));
        address treasuryPool = controller.treasuryPool();
        IERC20(fromToken).safeTransfer(treasuryPool, amount);
    }

    /**
     * @dev Get current dai debt of vault.
     * @param vaultNum Vault number.
     */
    function getVaultDebt(uint256 vaultNum) external view override returns (uint256 daiDebt) {
        address urn = ManagerLike(mcdManager).urns(vaultNum);
        address vat = ManagerLike(mcdManager).vat();
        bytes32 ilk = vaultType[vaultNum];

        daiDebt = _getVaultDebt(ilk, urn, vat);
    }

    /**
     * @dev Get current collateral balance of vault.
     * @param vaultNum Vault number.
     */
    function getVaultBalance(uint256 vaultNum)
        external
        view
        override
        returns (uint256 collateralLocked)
    {
        address vat = ManagerLike(mcdManager).vat();
        address urn = ManagerLike(mcdManager).urns(vaultNum);
        (collateralLocked, ) = VatLike(vat).urns(vaultType[vaultNum], urn);
    }

    /**
     * @dev Calculate state based on withdraw amount.
     * @param vaultNum Vault number.
     * @param amount Collateral amount to withraw.
     */
    function whatWouldWithdrawDo(uint256 vaultNum, uint256 amount)
        external
        view
        override
        returns (
            uint256 collateralLocked,
            uint256 daiDebt,
            uint256 collateralUsdRate,
            uint256 collateralRatio,
            uint256 minimumDebt
        )
    {
        (collateralLocked, daiDebt, collateralUsdRate, collateralRatio, minimumDebt) = getVaultInfo(
            vaultNum
        );

        GemJoinLike gemJoin = GemJoinLike(mcdGemJoin[vaultType[vaultNum]]);
        uint256 amount18 = convertTo18(gemJoin.dec(), amount);
        require(amount18 <= collateralLocked, "insufficient collateral locked");
        collateralLocked = sub(collateralLocked, amount18);
        collateralRatio = getCollateralRatio(collateralLocked, collateralUsdRate, daiDebt);
    }

    /**
     * @dev Get vault info
     * @param vaultNum Vault number.
     */
    function getVaultInfo(uint256 vaultNum)
        public
        view
        override
        returns (
            uint256 collateralLocked,
            uint256 daiDebt,
            uint256 collateralUsdRate,
            uint256 collateralRatio,
            uint256 minimumDebt
        )
    {
        (collateralLocked, collateralUsdRate, daiDebt, minimumDebt) = _getVaultInfo(vaultNum);
        collateralRatio = getCollateralRatio(collateralLocked, collateralUsdRate, daiDebt);
    }

    /**
     * @dev Get available DAI amount based on current DAI debt and limit for given vault type.
     * @param vat Vat address
     * @param vaultNum Vault number.
     */
    function maxAvailableDai(address vat, uint256 vaultNum) public view returns (uint256) {
        // Get stable coin Art(debt) [wad], rate [ray], line [rad]
        //solhint-disable-next-line var-name-mixedcase
        (uint256 Art, uint256 rate, , uint256 line, ) = VatLike(vat).ilks(vaultType[vaultNum]);
        // Calculate total issued debt is Art * rate [rad]
        // Calcualte total available dai [wad]
        uint256 _totalAvailableDai = sub(line, mul(Art, rate)) / RAY;
        // For safety reason, return 99% of available
        return mul(_totalAvailableDai, 99) / 100;
    }

    function joinDai(address urn, uint256 amount) internal {
        DaiJoinLike daiJoin = DaiJoinLike(mcdDaiJoin);
        // Transfer Dai from strategy or pool to here
        IERC20(DAI).safeTransferFrom(msg.sender, address(this), amount);
        // Approves adapter to move dai.
        IERC20(DAI).safeApprove(mcdDaiJoin, 0);
        IERC20(DAI).safeApprove(mcdDaiJoin, amount);
        // Joins DAI into the vat
        daiJoin.join(urn, amount);
    }

    function joinGem(address adapter, uint256 amount) internal returns (uint256) {
        GemJoinLike gemJoin = GemJoinLike(adapter);

        IERC20 token = IERC20(gemJoin.gem());
        // Transfer token from strategy or pool to here
        token.safeTransferFrom(msg.sender, address(this), amount);
        // Approves adapter to take the Gem amount
        token.safeApprove(adapter, 0);
        token.safeApprove(adapter, amount);
        // Joins Gem collateral into the vat
        gemJoin.join(address(this), amount);
        // Convert amount to 18 decimal
        return convertTo18(gemJoin.dec(), amount);
    }

    /**
     * @dev Get borrow dai amount.
     */
    function _getBorrowAmount(
        address vat,
        address urn,
        uint256 vaultNum,
        uint256 wad
    ) internal returns (int256 amount) {
        // Updates stability fee rate
        uint256 rate = JugLike(mcdJug).drip(vaultType[vaultNum]);

        // Gets DAI balance of the urn in the vat
        uint256 dai = VatLike(vat).dai(urn);

        // If there was already enough DAI in the vat balance, just exits it without adding more debt
        if (dai < mul(wad, RAY)) {
            // Calculates the needed amt so together with the existing dai in the vat is enough to exit wad amount of DAI tokens
            amount = toInt(sub(mul(wad, RAY), dai) / rate);
            // This is neeeded due lack of precision. It might need to sum an extra amt wei (for the given DAI wad amount)
            amount = mul(uint256(amount), rate) < mul(wad, RAY) ? amount + 1 : amount;
        }
    }

    /**
     * @dev Get collateral ratio
     */
    function getCollateralRatio(
        uint256 collateralLocked,
        uint256 collateralRate,
        uint256 daiDebt
    ) internal pure returns (uint256) {
        if (collateralLocked == 0) {
            return 0;
        }

        if (daiDebt == 0) {
            return MAX_UINT_VALUE;
        }

        require(collateralRate != 0, "Collateral rate is zero");
        return wdiv(wmul(collateralLocked, collateralRate), daiDebt);
    }

    /**
     * @dev Get Vault Debt Amount.
     */
    function _getVaultDebt(
        bytes32 ilk,
        address urn,
        address vat
    ) internal view returns (uint256 wad) {
        // Get normalised debt [wad]
        (, uint256 art) = VatLike(vat).urns(ilk, urn);
        // Get stable coin rate [ray]
        (, uint256 rate, , , ) = VatLike(vat).ilks(ilk);
        // Get balance from vat [rad]
        uint256 dai = VatLike(vat).dai(urn);

        wad = _getVaultDebt(art, rate, dai);
    }

    function _getVaultDebt(
        uint256 art,
        uint256 rate,
        uint256 dai
    ) internal pure returns (uint256 wad) {
        if (dai < mul(art, rate)) {
            uint256 rad = sub(mul(art, rate), dai);
            wad = rad / RAY;
            wad = mul(wad, RAY) < rad ? wad + 1 : wad;
        } else {
            wad = 0;
        }
    }

    function _getVaultInfo(uint256 vaultNum)
        internal
        view
        returns (
            uint256 collateralLocked,
            uint256 collateralUsdRate,
            uint256 daiDebt,
            uint256 minimumDebt
        )
    {
        address urn = ManagerLike(mcdManager).urns(vaultNum);
        address vat = ManagerLike(mcdManager).vat();
        bytes32 ilk = vaultType[vaultNum];

        // Get minimum liquidation ratio [ray]
        (, uint256 mat) = SpotterLike(mcdSpot).ilks(ilk);

        // Get collateral locked and normalised debt [wad] [wad]
        (uint256 ink, uint256 art) = VatLike(vat).urns(ilk, urn);
        // Get stable coin and collateral rate  and min debt [ray] [ray] [rad]
        (, uint256 rate, uint256 spot, , uint256 dust) = VatLike(vat).ilks(ilk);
        // Get balance from vat [rad]

        collateralLocked = ink;
        daiDebt = _getVaultDebt(art, rate, VatLike(vat).dai(urn));
        minimumDebt = dust / RAY;
        // Calculate collateral rate in 18 decimals
        collateralUsdRate = rmul(mat, spot) / 10**9;
    }

    /**
     * @dev Get Payback amount.
     * @notice We need to fetch latest art, rate and dai to calcualte payback amount.
     */
    function _getWipeAmount(
        bytes32 ilk,
        address urn,
        address vat
    ) internal view returns (int256 amount) {
        // Get normalize debt, rate and dai balance from Vat
        (, uint256 art) = VatLike(vat).urns(ilk, urn);
        (, uint256 rate, , , ) = VatLike(vat).ilks(ilk);
        uint256 dai = VatLike(vat).dai(urn);

        // Uses the whole dai balance in the vat to reduce the debt
        amount = toInt(dai / rate);
        // Checks the calculated amt is not higher than urn.art (total debt), otherwise uses its value
        amount = uint256(amount) <= art ? -amount : -toInt(art);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ManagerLike {
    function cdpCan(
        address,
        uint256,
        address
    ) external view returns (uint256);

    function ilks(uint256) external view returns (bytes32);

    function owns(uint256) external view returns (address);

    function urns(uint256) external view returns (address);

    function vat() external view returns (address);

    function open(bytes32, address) external returns (uint256);

    function give(uint256, address) external;

    function cdpAllow(
        uint256,
        address,
        uint256
    ) external;

    function urnAllow(address, uint256) external;

    function frob(
        uint256,
        int256,
        int256
    ) external;

    function flux(
        uint256,
        address,
        uint256
    ) external;

    function move(
        uint256,
        address,
        uint256
    ) external;

    function exit(
        address,
        uint256,
        address,
        uint256
    ) external;

    function quit(uint256, address) external;

    function enter(address, uint256) external;

    function shift(uint256, uint256) external;
}

interface VatLike {
    function can(address, address) external view returns (uint256);

    function ilks(bytes32)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function dai(address) external view returns (uint256);

    function urns(bytes32, address) external view returns (uint256, uint256);

    function frob(
        bytes32,
        address,
        address,
        address,
        int256,
        int256
    ) external;

    function hope(address) external;

    function nope(address) external;

    function move(
        address,
        address,
        uint256
    ) external;
}

interface GemJoinLike {
    function dec() external view returns (uint256);

    function gem() external view returns (address);

    function ilk() external view returns (bytes32);

    function join(address, uint256) external payable;

    function exit(address, uint256) external;
}

interface DaiJoinLike {
    function vat() external returns (VatLike);

    function dai() external view returns (address);

    function join(address, uint256) external payable;

    function exit(address, uint256) external;
}

interface JugLike {
    function drip(bytes32) external returns (uint256);
}

interface SpotterLike {
    function ilks(bytes32) external view returns (address, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ICollateralManager {
    function addGemJoin(address[] calldata gemJoins) external;

    function mcdManager() external view returns (address);

    function borrow(uint256 vaultNum, uint256 amount) external;

    function depositCollateral(uint256 vaultNum, uint256 amount) external;

    function getVaultBalance(uint256 vaultNum) external view returns (uint256 collateralLocked);

    function getVaultDebt(uint256 vaultNum) external view returns (uint256 daiDebt);

    function getVaultInfo(uint256 vaultNum)
        external
        view
        returns (
            uint256 collateralLocked,
            uint256 daiDebt,
            uint256 collateralUsdRate,
            uint256 collateralRatio,
            uint256 minimumDebt
        );

    function payback(uint256 vaultNum, uint256 amount) external;

    function registerVault(uint256 vaultNum, bytes32 collateralType) external;

    function vaultOwner(uint256 vaultNum) external returns (address owner);

    function whatWouldWithdrawDo(uint256 vaultNum, uint256 amount)
        external
        view
        returns (
            uint256 collateralLocked,
            uint256 daiDebt,
            uint256 collateralUsdRate,
            uint256 collateralRatio,
            uint256 minimumDebt
        );

    function withdrawCollateral(uint256 vaultNum, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./Strategy.sol";
import "../interfaces/vesper/ICollateralManager.sol";
import "../interfaces/uniswap/IUniswapV2Router02.sol";

interface ManagerInterface {
    function vat() external view returns (address);

    function open(bytes32, address) external returns (uint256);

    function cdpAllow(
        uint256,
        address,
        uint256
    ) external;
}

interface VatInterface {
    function hope(address) external;

    function nope(address) external;
}

/// @dev This strategy will deposit collateral token in Maker, borrow Dai and
/// deposit borrowed DAI in other lending pool to earn interest.
abstract contract MakerStrategy is Strategy {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    ICollateralManager public immutable cm;
    bytes32 public immutable collateralType;
    uint256 public immutable vaultNum;
    uint256 public lastRebalanceBlock;
    uint256 public highWater;
    uint256 public lowWater;
    uint256 private constant WAT = 10**16;

    constructor(
        address _controller,
        address _pool,
        address _cm,
        address _receiptToken,
        bytes32 _collateralType
    ) public Strategy(_controller, _pool, _receiptToken) {
        collateralType = _collateralType;
        vaultNum = _createVault(_collateralType, _cm);
        cm = ICollateralManager(_cm);
    }

    /**
     * @dev Called during withdrawal process.
     * Initial plan was to not allowed withdraw if pool in underwater. BUT as 1 of
     * audit suggested we should not use resurface during withdraw, hence removed logic.
     */
    //solhint-disable-next-line no-empty-blocks
    function beforeWithdraw() external override onlyPool {}

    /**
     * @dev Rebalance earning and withdraw all collateral.
     * Controller only function, called when migrating strategy.
     */
    function withdrawAllWithRebalance() external onlyController {
        _rebalanceEarned();
        _withdrawAll();
    }

    /**
     * @dev Wrapper function for rebalanceEarned and rebalanceCollateral
     * Anyone can call it except when paused.
     */
    function rebalance() external override onlyKeeper {
        _rebalanceEarned();
        _rebalanceCollateral();
    }

    /**
     * @dev Rebalance collateral and debt in Maker.
     * Based on defined risk parameter either borrow more DAI from Maker or
     * payback some DAI in Maker. It will try to mitigate risk of liquidation.
     * Anyone can call it except when paused.
     */
    function rebalanceCollateral() external onlyKeeper {
        _rebalanceCollateral();
    }

    /**
     * @dev Convert earned DAI to collateral token
     * Also calculate interest fee on earning and transfer fee to fee collector.
     * Anyone can call it except when paused.
     */
    function rebalanceEarned() external onlyKeeper {
        _rebalanceEarned();
    }

    /**
     * @dev If pool is underwater this function will resolve underwater condition.
     * If Debt in Maker is greater than Dai balance in lender pool then pool in underwater.
     * Lowering DAI debt in Maker will resolve underwater condtion.
     * Resolve: Calculate required collateral token to lower DAI debt. Withdraw required
     * collateral token from pool and/or Maker and convert those to DAI via Uniswap.
     * Finally payback debt in Maker using DAI.
     */
    function resurface() external onlyKeeper {
        _resurface();
    }

    /**
     * @notice Update balancing factors aka high water and low water values.
     * Water mark values represent Collateral Ratio in Maker. For example 300 as high water
     * means 300% collateral ratio.
     * @param _highWater Value for high water mark.
     * @param _lowWater Value for low water mark.
     */
    function updateBalancingFactor(uint256 _highWater, uint256 _lowWater) external onlyController {
        require(_lowWater != 0, "lowWater-is-zero");
        require(_highWater > _lowWater, "highWater-less-than-lowWater");
        highWater = _highWater.mul(WAT);
        lowWater = _lowWater.mul(WAT);
    }

    /**
     * @notice Returns interest earned since last rebalance.
     * @dev Make sure to return value in collateral token and in order to do that
     * we are using Uniswap to get collateral amount for earned DAI.
     */
    function interestEarned() public view virtual override returns (uint256 amountOut) {
        uint256 _daiBalance = _getDaiBalance();
        uint256 _debt = cm.getVaultDebt(vaultNum);
        if (_daiBalance > _debt) {
            (, amountOut, ) = swapManager.bestOutputFixedInput(
                DAI,
                address(collateralToken),
                _daiBalance.sub(_debt)
            );
        }
    }

    /// @dev Check whether given token is reserved or not. Reserved tokens are not allowed to sweep.
    function isReservedToken(address _token) public view virtual override returns (bool) {
        return _token == receiptToken;
    }

    /**
     * @notice Returns true if pool is underwater.
     * @notice Underwater - If debt is greater than earning of pool.
     * @notice Earning - Sum of DAI balance and DAI from accured reward, if any, in lending pool.
     */
    function isUnderwater() public view virtual returns (bool) {
        return cm.getVaultDebt(vaultNum) > _getDaiBalance();
    }

    /// @dev Returns total collateral locked via this strategy
    function totalLocked() public view virtual override returns (uint256) {
        return convertFrom18(cm.getVaultBalance(vaultNum));
    }

    /// @dev Create new Maker vault
    function _createVault(bytes32 _collateralType, address _cm) internal returns (uint256 vaultId) {
        address mcdManager = ICollateralManager(_cm).mcdManager();
        ManagerInterface manager = ManagerInterface(mcdManager);
        vaultId = manager.open(_collateralType, address(this));
        manager.cdpAllow(vaultId, address(this), 1);

        //hope and cpdAllow on vat for collateralManager's address
        VatInterface(manager.vat()).hope(_cm);
        manager.cdpAllow(vaultId, _cm, 1);

        //Register vault with collateral Manager
        ICollateralManager(_cm).registerVault(vaultId, _collateralType);
    }

    function _approveToken(uint256 _amount) internal virtual override {
        IERC20(DAI).safeApprove(address(cm), _amount);
        IERC20(DAI).safeApprove(address(receiptToken), _amount);
        collateralToken.safeApprove(address(cm), _amount);
        collateralToken.safeApprove(pool, _amount);
        for (uint256 i = 0; i < swapManager.N_DEX(); i++) {
            IERC20(DAI).safeApprove(address(swapManager.ROUTERS(i)), _amount);
            collateralToken.safeApprove(address(swapManager.ROUTERS(i)), _amount);
        }
    }

    function _deposit(uint256 _amount) internal override {
        collateralToken.safeTransferFrom(pool, address(this), _amount);
        cm.depositCollateral(vaultNum, _amount);
    }

    function _depositDaiToLender(uint256 _amount) internal virtual;

    function _moveDaiToMaker(uint256 _amount) internal {
        if (_amount != 0) {
            _withdrawDaiFromLender(_amount);
            cm.payback(vaultNum, _amount);
        }
    }

    function _moveDaiFromMaker(uint256 _amount) internal virtual {
        cm.borrow(vaultNum, _amount);
        _amount = IERC20(DAI).balanceOf(address(this));
        _depositDaiToLender(_amount);
    }

    function _swapBalanceToCollateral(address _from) internal {
        uint256 amt = IERC20(_from).balanceOf(address(this));
        if (amt != 0) {
            _safeSwap(_from, address(collateralToken), amt);
        }
    }

    function _rebalanceCollateral() internal virtual {
        _deposit(collateralToken.balanceOf(pool));
        (
            uint256 collateralLocked,
            uint256 debt,
            uint256 collateralUsdRate,
            uint256 collateralRatio,
            uint256 minimumDebt
        ) = cm.getVaultInfo(vaultNum);
        uint256 maxDebt = collateralLocked.mul(collateralUsdRate).div(highWater);
        if (maxDebt < minimumDebt) {
            // Dusting scenario. Payback all DAI
            _moveDaiToMaker(debt);
        } else {
            if (collateralRatio > highWater) {
                require(!isUnderwater(), "pool-is-underwater");
                _moveDaiFromMaker(maxDebt.sub(debt));
            } else if (collateralRatio < lowWater) {
                // Redeem DAI from Lender and deposit in maker
                _moveDaiToMaker(debt.sub(maxDebt));
            }
        }
    }

    function _rebalanceEarned() internal virtual {
        require(
            (block.number - lastRebalanceBlock) >= controller.rebalanceFriction(pool),
            "can-not-rebalance"
        );
        lastRebalanceBlock = block.number;
        _claimReward();
        _rebalanceDaiInLender();
        _swapBalanceToCollateral(DAI);
        uint256 collateralBalance = collateralToken.balanceOf(address(this));
        if (collateralBalance != 0) {
            uint256 fee = collateralBalance.mul(controller.interestFee(pool)).div(1e18);
            collateralToken.safeTransfer(pool, collateralBalance.sub(fee));
            _handleFee(fee);
        }
    }

    function _resurface() internal {
        uint256 earnBalance = _getDaiBalance();
        uint256 debt = cm.getVaultDebt(vaultNum);
        require(debt > earnBalance, "pool-is-above-water");
        uint256 shortAmount = debt.sub(earnBalance);
        _paybackShortAmount(shortAmount);
    }

    function _paybackShortAmount(uint256 shortAmount) internal virtual {
        (address[] memory path, uint256 collateralNeeded, uint256 rIdx) =
            swapManager.bestInputFixedOutput(address(collateralToken), DAI, shortAmount);
        if (collateralNeeded != 0) {
            uint256 balance = collateralToken.balanceOf(pool);

            // If pool has more balance than tokenNeeded, get what needed from pool
            // else get pool balance from pool and remaining from Maker vault
            if (balance >= collateralNeeded) {
                collateralToken.safeTransferFrom(pool, address(this), collateralNeeded);
            } else {
                cm.withdrawCollateral(vaultNum, collateralNeeded.sub(balance));
                collateralToken.safeTransferFrom(pool, address(this), balance);
            }
            swapManager.ROUTERS(rIdx).swapExactTokensForTokens(
                collateralNeeded,
                1,
                path,
                address(this),
                block.timestamp
            );
            uint256 daiBalance = IERC20(DAI).balanceOf(address(this));
            cm.payback(vaultNum, daiBalance);
        }

        // If any collateral dust then send it to pool
        uint256 _collateralbalance = collateralToken.balanceOf(address(this));
        if (_collateralbalance != 0) {
            collateralToken.safeTransfer(pool, _collateralbalance);
        }
    }

    function _withdraw(uint256 _amount) internal override {
        (
            uint256 collateralLocked,
            uint256 debt,
            uint256 collateralUsdRate,
            uint256 collateralRatio,
            uint256 minimumDebt
        ) = cm.whatWouldWithdrawDo(vaultNum, _amount);
        if (debt != 0 && collateralRatio < lowWater) {
            // If this withdraw results in Low Water scenario.
            uint256 maxDebt = collateralLocked.mul(collateralUsdRate).div(highWater);
            if (maxDebt < minimumDebt) {
                // This is Dusting scenario
                _moveDaiToMaker(debt);
            } else if (maxDebt < debt) {
                _moveDaiToMaker(debt.sub(maxDebt));
            }
        }
        cm.withdrawCollateral(vaultNum, _amount);
        collateralToken.safeTransfer(pool, collateralToken.balanceOf(address(this)));
    }

    function _withdrawAll() internal override {
        _moveDaiToMaker(cm.getVaultDebt(vaultNum));
        require(cm.getVaultDebt(vaultNum) == 0, "debt-should-be-0");
        cm.withdrawCollateral(vaultNum, totalLocked());
        collateralToken.safeTransfer(pool, collateralToken.balanceOf(address(this)));
    }

    function _withdrawDaiFromLender(uint256 _amount) internal virtual;

    function _rebalanceDaiInLender() internal virtual {
        uint256 debt = cm.getVaultDebt(vaultNum);
        uint256 balance = _getDaiBalance();
        if (balance > debt) {
            _withdrawDaiFromLender(balance.sub(debt));
        }
    }

    function _getDaiBalance() internal view virtual returns (uint256);

    /// Calculating pending fee is not required for Maker strategy
    // solhint-disable-next-line no-empty-blocks
    function _updatePendingFee() internal virtual override {}

    //solhint-disable-next-line no-empty-blocks
    function _claimReward() internal virtual override {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./MakerStrategy.sol";

/// @dev This strategy will deposit collateral token in Maker, borrow Dai and
/// deposit borrowed DAI in Vesper DAI pool to earn interest.
abstract contract VesperMakerStrategy is MakerStrategy {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    constructor(
        address _controller,
        address _pool,
        address _cm,
        address _vPool,
        bytes32 _collateralType
    ) public MakerStrategy(_controller, _pool, _cm, _vPool, _collateralType) {
        require(IController(_controller).isPool(_vPool), "not-a-valid-vPool");
        require(IVesperPool(_vPool).token() == DAI, "not-a-valid-dai-pool");
    }

    function _getDaiBalance() internal view override returns (uint256) {
        return
            (IVesperPool(receiptToken).getPricePerShare())
                .mul(IVesperPool(receiptToken).balanceOf(address(this)))
                .div(1e18);
    }

    function _depositDaiToLender(uint256 _amount) internal override {
        IVesperPool(receiptToken).deposit(_amount);
    }

    function _withdrawDaiFromLender(uint256 _amount) internal override {
        uint256 vAmount = _amount.mul(1e18).div(IVesperPool(receiptToken).getPricePerShare());
        IVesperPool(receiptToken).withdrawByStrategy(vAmount);
    }

    /// dev these functions are not implemented for this strategy
    // solhint-disable-next-line no-empty-blocks
    function _migrateIn() internal override {}

    // solhint-disable-next-line no-empty-blocks
    function _migrateOut() internal override {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./VesperMakerStrategy.sol";

//solhint-disable no-empty-blocks
contract VesperMakerStrategyLINK is VesperMakerStrategy {
    string public constant NAME = "Strategy-Vesper-Maker-LINK";
    string public constant VERSION = "2.0.4";

    constructor(
        address _controller,
        address _pool,
        address _cm,
        address _vPool
    ) public VesperMakerStrategy(_controller, _pool, _cm, _vPool, "LINK-A") {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./VesperMakerStrategy.sol";

//solhint-disable no-empty-blocks
contract VesperMakerStrategyETH is VesperMakerStrategy {
    string public constant NAME = "Strategy-Vesper-Maker-ETH";
    string public constant VERSION = "2.0.3";

    constructor(
        address _controller,
        address _pool,
        address _cm,
        address _vPool
    ) public VesperMakerStrategy(_controller, _pool, _cm, _vPool, "ETH-A") {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./MakerStrategy.sol";
import "../interfaces/compound/ICompound.sol";

/// @dev This strategy will deposit collateral token in Maker, borrow Dai and
/// deposit borrowed DAI in Compound to earn interest.
abstract contract CompoundMakerStrategy is MakerStrategy {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    address internal immutable rewardToken;
    CToken internal immutable cToken;
    Comptroller internal immutable comptroller;

    constructor(
        address _controller,
        address _pool,
        address _cm,
        address _receiptToken,
        bytes32 _collateralType,
        address _rewardToken,
        address _comptroller
    ) public MakerStrategy(_controller, _pool, _cm, _receiptToken, _collateralType) {
        require(_rewardToken != address(0), "reward-token-address-is-zero");
        require(_receiptToken != address(0), "cToken-address-is-zero");
        require(_comptroller != address(0), "comptroller-address-is-zero");

        rewardToken = _rewardToken;
        cToken = CToken(_receiptToken);
        comptroller = Comptroller(_comptroller);
    }

    /**
     * @notice Returns earning from COMP and DAI since last rebalance.
     * @dev Make sure to return value in collateral token and in order to do that
     * we are using Uniswap to get collateral amount for earned CMOP and DAI.
     */
    function interestEarned() public view override returns (uint256 collateralEarned) {
        uint256 _daiBalanceHere = _getDaiBalance();
        uint256 _debt = cm.getVaultDebt(vaultNum);

        if (_daiBalanceHere > _debt) {
            (, collateralEarned, ) = swapManager.bestOutputFixedInput(
                DAI,
                address(collateralToken),
                _daiBalanceHere.sub(_debt)
            );
        }

        uint256 _compAccrued = comptroller.compAccrued(address(this));
        if (_compAccrued != 0) {
            (, uint256 accruedCollateral, ) =
                swapManager.bestOutputFixedInput(
                    rewardToken,
                    address(collateralToken),
                    _compAccrued
                );
            collateralEarned = collateralEarned.add(accruedCollateral);
        }
    }

    /// @dev Check whether given token is reserved or not. Reserved tokens are not allowed to sweep.
    function isReservedToken(address _token) public view override returns (bool) {
        return _token == receiptToken || _token == rewardToken;
    }

    /**
     * @notice Returns true if pool is underwater.
     * @notice Underwater - If debt is greater than earning of pool.
     * @notice Earning - Sum of DAI balance and DAI from accured reward, if any, in lending pool.
     * @dev There can be a scenario when someone calls claimComp() periodically which will
     * leave compAccrued = 0 and pool might be underwater. Call rebalance() to liquidate COMP.
     */
    function isUnderwater() public view override returns (bool) {
        uint256 _compAccrued = comptroller.compAccrued(address(this));
        uint256 _daiEarned;
        if (_compAccrued != 0) {
            (, _daiEarned, ) = swapManager.bestOutputFixedInput(rewardToken, DAI, _compAccrued);
        }
        return cm.getVaultDebt(vaultNum) > _getDaiBalance().add(_daiEarned);
    }

    function _approveToken(uint256 _amount) internal override {
        super._approveToken(_amount);
        for (uint256 i = 0; i < swapManager.N_DEX(); i++) {
            IERC20(rewardToken).safeApprove(address(swapManager.ROUTERS(i)), _amount);
        }
    }

    /// @notice Claim rewardToken from lender and convert it into DAI
    function _claimReward() internal override {
        address[] memory _markets = new address[](1);
        _markets[0] = address(cToken);
        comptroller.claimComp(address(this), _markets);

        uint256 _rewardAmount = IERC20(rewardToken).balanceOf(address(this));
        if (_rewardAmount != 0) {
            _safeSwap(rewardToken, DAI, _rewardAmount);
        }
    }

    function _depositDaiToLender(uint256 _amount) internal override {
        require(cToken.mint(_amount) == 0, "deposit-in-compound-failed");
    }

    function _getDaiBalance() internal view override returns (uint256) {
        return cToken.balanceOf(address(this)).mul(cToken.exchangeRateStored()).div(1e18);
    }

    /**
     * @dev Rebalance DAI in lender. If lender has more DAI than DAI debt in Maker
     * then withdraw excess DAI from lender. If lender is short on DAI, underwater,
     * then deposit DAI to lender.
     * @dev There may be a scenario where we do not have enough DAI to deposit to
     * lender, in that case pool will be underwater even after rebalanceDai.
     */
    function _rebalanceDaiInLender() internal override {
        uint256 _daiDebtInMaker = cm.getVaultDebt(vaultNum);
        uint256 _daiInLender = _getDaiBalance();
        if (_daiInLender > _daiDebtInMaker) {
            _withdrawDaiFromLender(_daiInLender.sub(_daiDebtInMaker));
        } else if (_daiInLender < _daiDebtInMaker) {
            uint256 _daiBalanceHere = IERC20(DAI).balanceOf(address(this));
            uint256 _daiNeeded = _daiDebtInMaker.sub(_daiInLender);
            if (_daiBalanceHere > _daiNeeded) {
                _depositDaiToLender(_daiNeeded);
            } else {
                _depositDaiToLender(_daiBalanceHere);
            }
        }
    }

    function _withdrawDaiFromLender(uint256 _amount) internal override {
        require(cToken.redeemUnderlying(_amount) == 0, "withdraw-from-compound-failed");
    }

    /// dev these functions are not implemented for this strategy
    // solhint-disable-next-line no-empty-blocks
    function _migrateIn() internal override {}

    // solhint-disable-next-line no-empty-blocks
    function _migrateOut() internal override {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface CToken is IERC20 {
    function accrueInterest() external returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function mint() external payable; // For ETH

    function mint(uint256 mintAmount) external returns (uint256); // For ERC20

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
}

interface Comptroller {
    function claimComp(address holder, address[] memory) external;

    function compAccrued(address holder) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./CompoundMakerStrategy.sol";
import "../interfaces/token/IToken.sol";

//solhint-disable no-empty-blocks
contract CompoundMakerStrategyETH is CompoundMakerStrategy {
    string public constant NAME = "Compound-Maker-Strategy-ETH";
    string public constant VERSION = "2.0.3";

    constructor(
        address _controller,
        address _pool,
        address _cm
    )
        public
        CompoundMakerStrategy(
            _controller,
            _pool,
            _cm,
            0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643, // cDAI
            "ETH-A",
            0xc00e94Cb662C3520282E6f5717214004A7f26888, // COMP
            0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B // Comptroller
        )
    {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface TokenLike {
    function approve(address, uint256) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function deposit() external payable;

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./CompoundStrategy.sol";
import "../interfaces/token/IToken.sol";

//solhint-disable no-empty-blocks
contract CompoundStrategyWBTC is CompoundStrategy {
    string public constant NAME = "Strategy-Compound-WBTC";
    string public constant VERSION = "2.0.3";

    constructor(address _controller, address _pool)
        public
        CompoundStrategy(
            _controller,
            _pool,
            0xccF4429DB6322D5C611ee964527D42E5d685DD6a,
            0xc00e94Cb662C3520282E6f5717214004A7f26888,
            0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B
        )
    {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./Strategy.sol";
import "../interfaces/compound/ICompound.sol";
import "../interfaces/vesper/IVesperPool.sol";

/// @title This strategy will deposit collateral token in Compound and earn interest.
abstract contract CompoundStrategy is Strategy {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public pendingFee;

    CToken internal immutable cToken;
    address internal immutable rewardToken;
    Comptroller internal immutable comptroller;
    uint256 internal exchangeRateStored;

    constructor(
        address _controller,
        address _pool,
        address _receiptToken,
        address _rewardToken,
        address _comptroller
    ) public Strategy(_controller, _pool, _receiptToken) {
        require(_rewardToken != address(0), "RewardToken address is zero");
        cToken = CToken(_receiptToken);
        rewardToken = _rewardToken;
        comptroller = Comptroller(_comptroller);
    }

    /// @notice Vesper pools are using this function so it should exist in all strategies.
    //solhint-disable-next-line no-empty-blocks
    function beforeWithdraw() external override onlyPool {}

    /**
     * @dev Calculate interest fee on earning from Compound and transfer fee to fee collector.
     * Deposit available collateral from pool into Compound.
     * Anyone can call it except when paused.
     */
    function rebalance() external override onlyKeeper {
        _rebalanceEarned();
        uint256 balance = collateralToken.balanceOf(pool);
        if (balance != 0) {
            _deposit(balance);
        }
    }

    /// @notice Returns true if strategy can be upgraded.
    /// @dev If there are no cTokens in strategy then it is upgradable
    function isUpgradable() external view override returns (bool) {
        return cToken.balanceOf(address(this)) == 0;
    }

    /**
     * @notice Returns interest earned in COMP since last rebalance.
     * @dev Make sure to return value in collateral token
     */
    function interestEarned() public view override returns (uint256 collateralEarned) {
        uint256 compAccrued = comptroller.compAccrued(address(this));
        if (compAccrued != 0) {
            (, collateralEarned, ) = swapManager.bestOutputFixedInput(
                rewardToken,
                address(collateralToken),
                compAccrued
            );
        }
    }

    /// @notice This method is deprecated and will be removed from Strategies in next release
    function isReservedToken(address _token) public view override returns (bool) {
        return _token == address(cToken) || _token == rewardToken;
    }

    /**
     * @notice Total collateral locked in Compound.
     * @dev This value will be used in pool share calculation, so true totalLocked
     * will be balance in Compound minus any pending fee to collect.
     * @return Return value will be in collateralToken defined decimal.
     */
    function totalLocked() public view override returns (uint256) {
        uint256 _totalCTokens = cToken.balanceOf(pool).add(cToken.balanceOf(address(this)));
        return _convertToCollateral(_totalCTokens).sub(_calculatePendingFee());
    }

    function _approveToken(uint256 _amount) internal override {
        collateralToken.safeApprove(pool, _amount);
        collateralToken.safeApprove(address(cToken), _amount);
        for (uint256 i = 0; i < swapManager.N_DEX(); i++) {
            IERC20(rewardToken).safeApprove(address(swapManager.ROUTERS(i)), _amount);
        }
    }

    /**
     * @dev Claim rewardToken and convert rewardToken into collateral token.
     * Calculate interest fee on earning from rewardToken and transfer balance minus
     * fee to pool.
     * @dev Transferring collateral to pool will increase pool share price.
     */
    function _claimReward() internal override {
        address[] memory markets = new address[](1);
        markets[0] = address(cToken);
        comptroller.claimComp(address(this), markets);

        uint256 _rewardAmount = IERC20(rewardToken).balanceOf(address(this));
        if (_rewardAmount > 0) {
            _safeSwap(rewardToken, address(collateralToken), _rewardAmount);
            uint256 _collateralEarned = collateralToken.balanceOf(address(this));
            uint256 _fee = _collateralEarned.mul(controller.interestFee(pool)).div(1e18);
            collateralToken.safeTransfer(pool, _collateralEarned.sub(_fee));
        }
    }

    function _deposit(uint256 _amount) internal virtual override {
        collateralToken.safeTransferFrom(pool, address(this), _amount);
        require(cToken.mint(_amount) == 0, "deposit-failed");
    }

    /**
     * @notice Migrate tokens from pool to this address
     * @dev Any working Compound strategy has cTokens in strategy contract.
     * @dev There can be scenarios when pool already has cTokens and new
     * strategy will have to move those tokens from pool to self address.
     * @dev Only valid pool strategy is allowed to move tokens from pool.
     */
    function _migrateIn() internal override {
        require(controller.isPool(pool), "not-a-valid-pool");
        require(controller.strategy(pool) == address(this), "not-a-valid-strategy");
        IERC20(cToken).safeTransferFrom(pool, address(this), cToken.balanceOf(pool));
    }

    /**
     * @notice Migrate tokens out to pool.
     * @dev There can be scenarios when we want to use new strategy without
     * calling withdrawAll(). We can achieve this by moving tokens in pool
     * and new strategy will take care from there.
     * @dev Pause this strategy, set pendingFee to zero and move tokens out.
     */
    function _migrateOut() internal override {
        require(controller.isPool(pool), "not-a-valid-pool");
        _pause();
        pendingFee = 0;
        IERC20(cToken).safeTransfer(pool, cToken.balanceOf(address(this)));
    }

    /**
     * @dev Calculate interest fee earning and transfer it to fee collector.
     * RebalanceEarned completes in following steps,
     *      Claim rewardToken and earn fee.
     *      Update pending fee.
     *      Withdraw collateral equal to pendingFee from compound.
     *      Now we have collateral equal to pendingFee + fee earning from rewardToken.
     *      Deposit collateral in Pool and get shares.
     *      Transfer shares to feeCollector.
     */
    function _rebalanceEarned() internal {
        _claimReward();
        _updatePendingFee();
        // Read state variable once to save gas
        uint256 _pendingFee = pendingFee;
        uint256 _cTokenAmount = _convertToCToken(_pendingFee);
        if (_cTokenAmount != 0) {
            require(cToken.redeemUnderlying(_pendingFee) == 0, "rebalanceEarned::withdraw-failed");
            // Update state variable
            pendingFee = 0;
            _afterRedeem();
        }
        _handleFee(collateralToken.balanceOf(address(this)));
    }

    function _withdraw(uint256 _amount) internal override {
        require(cToken.redeemUnderlying(_amount) == 0, "withdraw-failed");
        _afterRedeem();
        collateralToken.safeTransfer(pool, collateralToken.balanceOf(address(this)));
    }

    function _withdrawAll() internal override {
        pendingFee = 0;
        require(cToken.redeem(cToken.balanceOf(address(this))) == 0, "withdraw-all-failed");
        _afterRedeem();
        collateralToken.safeTransfer(pool, collateralToken.balanceOf(address(this)));
    }

    /// @dev Hook to call after collateral is redeemed from Compound
    /// @notice We did empty implementation as not all derived are going to implement it.
    //solhint-disable-next-line no-empty-blocks
    function _afterRedeem() internal virtual {}

    function _convertToCToken(uint256 _collateralAmount) internal view returns (uint256) {
        return _collateralAmount.mul(1e18).div(cToken.exchangeRateStored());
    }

    function _convertToCollateral(uint256 _cTokenAmount) internal view returns (uint256) {
        return _cTokenAmount.mul(cToken.exchangeRateStored()).div(1e18);
    }

    function _calculatePendingFee() internal view returns (uint256) {
        uint256 interest =
            cToken
                .exchangeRateStored()
                .sub(exchangeRateStored)
                .mul(cToken.balanceOf(address(this)))
                .div(1e18);
        uint256 fee = interest.mul(controller.interestFee(pool)).div(1e18);
        return pendingFee.add(fee);
    }

    function _updatePendingFee() internal override {
        pendingFee = _calculatePendingFee();
        exchangeRateStored = cToken.exchangeRateStored();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./CompoundStrategy.sol";
import "../interfaces/token/IToken.sol";

//solhint-disable no-empty-blocks
contract CompoundStrategyUSDC is CompoundStrategy {
    string public constant NAME = "Strategy-Compound-USDC";
    string public constant VERSION = "2.0.2";

    constructor(address _controller, address _pool)
        public
        CompoundStrategy(
            _controller,
            _pool,
            0x39AA39c021dfbaE8faC545936693aC917d5E7563,
            0xc00e94Cb662C3520282E6f5717214004A7f26888,
            0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B
        )
    {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./CompoundStrategy.sol";
import "../interfaces/token/IToken.sol";

//solhint-disable no-empty-blocks
contract CompoundStrategyETH is CompoundStrategy {
    string public constant NAME = "Strategy-Compound-ETH";
    string public constant VERSION = "2.0.3";

    constructor(address _controller, address _pool)
        public
        CompoundStrategy(
            _controller,
            _pool,
            0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5,
            0xc00e94Cb662C3520282E6f5717214004A7f26888,
            0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B
        )
    {}

    receive() external payable {
        require(msg.sender == address(cToken) || msg.sender == WETH, "Not allowed to send ether");
    }

    /// @dev Hool to call after collateral is redeemed from Compound
    function _afterRedeem() internal override {
        TokenLike(WETH).deposit{value: address(this).balance}();
    }

    function _deposit(uint256 _amount) internal override {
        collateralToken.safeTransferFrom(pool, address(this), _amount);
        TokenLike(WETH).withdraw(_amount);
        cToken.mint{value: _amount}();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./CompoundStrategy.sol";
import "../interfaces/token/IToken.sol";

//solhint-disable no-empty-blocks
contract CompoundStrategyDAI is CompoundStrategy {
    string public constant NAME = "Strategy-Compound-DAI";
    string public constant VERSION = "2.0.2";

    constructor(address _controller, address _pool)
        public
        CompoundStrategy(
            _controller,
            _pool,
            0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643,
            0xc00e94Cb662C3520282E6f5717214004A7f26888,
            0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B
        )
    {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./Strategy.sol";
import "./AaveRewards.sol";
import "../interfaces/aave/IAaveV2.sol";
import "../interfaces/vesper/IVesperPool.sol";

/// @dev This strategy will deposit collateral token in Aave and earn interest.
abstract contract AaveV2Strategy is Strategy, AaveRewards {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    //solhint-disable-next-line const-name-snakecase
    AaveLendingPoolAddressesProvider public constant aaveAddressesProvider =
        AaveLendingPoolAddressesProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);

    uint256 public pendingFee;
    IERC20 internal immutable aToken;
    uint256 internal collateralLocked;

    constructor(
        address _controller,
        address _pool,
        address _receiptToken
    ) public Strategy(_controller, _pool, _receiptToken) {
        aToken = IERC20(_receiptToken);
    }

    //solhint-disable no-empty-blocks
    function beforeWithdraw() external override onlyPool {}

    /**
     * @notice Returns interest earned since last rebalance.
     * @dev Make sure to return value in collateral token
     */
    function interestEarned() external view override returns (uint256 collateralEarned) {
        uint256 _aaveAmount = stkAAVE.getTotalRewardsBalance(address(this));
        if (_aaveAmount != 0) {
            (, collateralEarned, ) = swapManager.bestOutputFixedInput(
                AAVE,
                address(collateralToken),
                _aaveAmount
            );
        }
    }

    /// @notice Initiate cooldown to unstake aave.
    function startCooldown() external onlyKeeper returns (bool) {
        return _startCooldown();
    }

    /// @notice Unstake Aave from stakedAave contract
    function unstakeAave() external onlyKeeper {
        _unstakeAave();
    }

    /**
     * @dev Deposit available collateral from pool into Aave.
     * Also calculate interest fee on earning from Aave and transfer fee to fee collector.
     * Anyone can call it except when paused.
     */
    function rebalance() external override onlyKeeper {
        _rebalanceEarned();
        uint256 balance = collateralToken.balanceOf(pool);
        if (balance != 0) {
            _deposit(balance);
        }
    }

    /// @dev Returns true if strategy can be upgraded.
    /// @dev If there are no aTokens in strategy then it is upgradable
    function isUpgradable() external view override returns (bool) {
        return aToken.balanceOf(address(this)) == 0;
    }

    function isReservedToken(address _token) public view override returns (bool) {
        return _token == receiptToken || _token == AAVE || _token == address(stkAAVE);
    }

    /**
     * @notice Total collateral locked in Aave.
     * @dev This value will be used in pool share calculation, so true totalLocked
     * will be balance in Aave minus any pending fee to collect.
     * @return Return value will be in collateralToken defined decimal.
     */
    function totalLocked() public view override returns (uint256) {
        uint256 balance = aToken.balanceOf(pool).add(aToken.balanceOf(address(this)));
        return balance.sub(_calculatePendingFee(balance));
    }

    /// @notice Large approval of token
    function _approveToken(uint256 _amount) internal override {
        collateralToken.safeApprove(pool, _amount);
        collateralToken.safeApprove(aaveAddressesProvider.getLendingPool(), _amount);
        for (uint256 i = 0; i < swapManager.N_DEX(); i++) {
            IERC20(AAVE).safeApprove(address(swapManager.ROUTERS(i)), _amount);
        }
    }

    /**
     * @dev Claim Aave and convert it into collateral token.
     * Calculate interest fee on earning from Aave and transfer balance minus
     * fee to pool.
     * @dev Transferring collateral to pool will increase pool share price.
     */
    function _claimReward() internal override {
        uint256 _aaveAmount = _claimAave();
        if (_aaveAmount != 0) {
            _safeSwap(AAVE, address(collateralToken), _aaveAmount);
            uint256 _collateralEarned = collateralToken.balanceOf(address(this));
            uint256 _fee = _collateralEarned.mul(controller.interestFee(pool)).div(1e18);
            collateralToken.safeTransfer(pool, _collateralEarned.sub(_fee));
        }
    }

    function _deposit(uint256 _amount) internal virtual override {
        collateralToken.safeTransferFrom(pool, address(this), _amount);
        address _aaveLendingPool = aaveAddressesProvider.getLendingPool();

        AaveLendingPool(_aaveLendingPool).deposit(
            address(collateralToken),
            _amount,
            address(this),
            0
        );
        _updateCollateralLocked();
    }

    /**
     * @notice Migrate tokens from pool to this address
     * @dev Any working Aave strategy has aToken in strategy contract.
     * @dev There can be scenarios when pool already has aTokens and new
     * strategy will have to move those tokens from pool to self address.
     * @dev Only valid pool strategy is allowed to move tokens from pool.
     */
    function _migrateIn() internal override {
        require(controller.isPool(pool), "not-a-valid-pool");
        require(controller.strategy(pool) == address(this), "not-a-valid-strategy");
        aToken.safeTransferFrom(pool, address(this), aToken.balanceOf(pool));
    }

    /**
     * @notice Migrate tokens out to pool.
     * @dev There can be scenarios when we want to use new strategy without
     * calling withdrawAll(). We can achieve this by moving tokens in pool
     * and new strategy will take care from there.
     * @dev Pause this strategy, set pendingFee to zero and move tokens out.
     */
    function _migrateOut() internal override {
        require(controller.isPool(pool), "not-a-valid-pool");
        _pause();
        pendingFee = 0;
        aToken.safeTransfer(pool, aToken.balanceOf(address(this)));
        IERC20(stkAAVE).safeTransfer(pool, stkAAVE.balanceOf(address(this)));
    }

    /**
     * @dev Calcualte earning from Aave and also calculate interest fee.
     * Deposit fee into Vesper pool to get Vesper pool shares.
     * Transfer fee, Vesper pool shares, to fee collector
     */
    function _rebalanceEarned() internal {
        _updatePendingFee();
        _claimReward();
        if (pendingFee != 0) {
            // Withdraw pendingFee worth collateral from Aave
            _withdraw(pendingFee, address(this));
            pendingFee = 0;
        }
        _handleFee(collateralToken.balanceOf(address(this)));
    }

    /**
     * @dev Withdraw collateral token from Aave.
     * @param _amount Amount of collateral token
     */
    function _withdraw(uint256 _amount) internal override {
        _withdraw(_amount, pool);
    }

    /**
     * @dev Withdraw amount from Aave to given address
     * @param _amount Amount of aToken to withdraw
     * @param _to Address where you want receive collateral
     */
    function _withdraw(uint256 _amount, address _to) internal virtual {
        address aavePool = aaveAddressesProvider.getLendingPool();
        require(
            AaveLendingPool(aavePool).withdraw(address(collateralToken), _amount, _to) == _amount,
            "withdrawn-amount-is-not-correct"
        );
        _updateCollateralLocked();
    }

    /**
     * @dev Withdraw all collateral from Aave and deposit into pool.
     * Controller only function, called when migrating strategy.
     */
    function _withdrawAll() internal override {
        uint256 _balance = aToken.balanceOf(address(this));
        if (_balance != 0) {
            pendingFee = 0;
            _withdraw(_balance, pool);
        }
    }

    function _updateCollateralLocked() internal {
        collateralLocked = aToken.balanceOf(address(this));
    }

    function _updatePendingFee() internal override {
        pendingFee = _calculatePendingFee(aToken.balanceOf(address(this)));
    }

    function _calculatePendingFee(uint256 aTokenBalance) internal view returns (uint256) {
        uint256 interest = aTokenBalance.sub(collateralLocked);
        uint256 fee = interest.mul(controller.interestFee(pool)).div(1e18);
        return pendingFee.add(fee);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../interfaces/aave/IAaveV2.sol";

/// @title This contract provide utility functions to claim Aave rewards
abstract contract AaveRewards {
    //solhint-disable-next-line const-name-snakecase
    StakedAave public constant stkAAVE = StakedAave(0x4da27a545c0c5B758a6BA100e3a049001de870f5);
    address public constant AAVE = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9;

    /// @notice Returns true if Aave can be unstaked
    function canUnstake() external view returns (bool) {
        (, uint256 _cooldownEnd, uint256 _unstakeEnd) = cooldownData();
        return _canUnstake(_cooldownEnd, _unstakeEnd);
    }

    /// @notice Returns true if we should start cooldown
    function canStartCooldown() public view returns (bool) {
        (uint256 _cooldownStart, , uint256 _unstakeEnd) = cooldownData();
        return _canStartCooldown(_cooldownStart, _unstakeEnd);
    }

    /// @notice Return cooldown related timestamps
    function cooldownData()
        public
        view
        returns (
            uint256 _cooldownStart,
            uint256 _cooldownEnd,
            uint256 _unstakeEnd
        )
    {
        _cooldownStart = stkAAVE.stakersCooldowns(address(this));
        _cooldownEnd = _cooldownStart + stkAAVE.COOLDOWN_SECONDS();
        _unstakeEnd = _cooldownEnd + stkAAVE.UNSTAKE_WINDOW();
    }

    /**
     * @notice Claim Aave. Also unstake all Aave if favorable condition exits or start cooldown.
     * @dev If we unstake all Aave, we can't start cooldown because it requires StakedAave balance.
     * @dev DO NOT convert 'if else' to 2 'if's as we are reading cooldown state once to save gas.
     */
    function _claimAave() internal returns (uint256) {
        (uint256 _cooldownStart, uint256 _cooldownEnd, uint256 _unstakeEnd) = cooldownData();

        if (_canUnstake(_cooldownEnd, _unstakeEnd)) {
            stkAAVE.redeem(address(this), type(uint256).max);
        } else if (_canStartCooldown(_cooldownStart, _unstakeEnd)) {
            stkAAVE.cooldown();
        }

        stkAAVE.claimRewards(address(this), type(uint256).max);
        return IERC20(AAVE).balanceOf(address(this));
    }

    /**
     * @notice Initiate cooldown to unstake aave.
     * @dev We only want to call this function when cooldown is expired and
     * that's the reason we have 'if' condition.
     */
    function _startCooldown() internal returns (bool) {
        if (canStartCooldown()) {
            stkAAVE.cooldown();
            return true;
        }
        return false;
    }

    /**
     * @notice Unstake Aave from stakedAave contract
     * @dev We want to unstake as soon as favorable condition exit
     * @dev No guarding condtion thus this call can fail, if we can't unstake.
     */
    function _unstakeAave() internal {
        stkAAVE.redeem(address(this), type(uint256).max);
    }

    /**
     * @dev Return true, only if we have StakedAave balance and either cooldown expired or cooldown is zero
     * @dev If we are in cooldown period we cannot unstake Aave. But our cooldown is still valid so we do
     * not want to reset/start cooldown.
     */
    function _canStartCooldown(uint256 _cooldownStart, uint256 _unstakeEnd)
        internal
        view
        returns (bool)
    {
        return
            stkAAVE.balanceOf(address(this)) != 0 &&
            (_cooldownStart == 0 || block.timestamp > _unstakeEnd);
    }

    /// @dev Return true, if cooldown is over and we are in unstake window.
    function _canUnstake(uint256 _cooldownEnd, uint256 _unstakeEnd) internal view returns (bool) {
        return block.timestamp > _cooldownEnd && block.timestamp <= _unstakeEnd;
    }

    /// @dev Check whether given token is reserved or not. Reserved tokens are not allowed to sweep.
    function _isReservedToken(address _token) internal pure returns (bool) {
        return _token == AAVE || _token == address(stkAAVE);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface AaveLendingPoolAddressesProvider {
    function getLendingPool() external view returns (address);

    function getAddress(bytes32 id) external view returns (address);
}

interface AaveLendingPool {
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
}

interface AaveProtocolDataProvider {
    function getReserveTokensAddresses(address asset)
        external
        view
        returns (
            address aTokenAddress,
            address stableDebtTokenAddress,
            address variableDebtTokenAddress
        );
}

//solhint-disable func-name-mixedcase
interface StakedAave is IERC20 {
    function claimRewards(address to, uint256 amount) external;

    function cooldown() external;

    function redeem(address to, uint256 amount) external;

    function getTotalRewardsBalance(address staker) external view returns (uint256);

    function stakersCooldowns(address staker) external view returns (uint256);

    function COOLDOWN_SECONDS() external view returns (uint256);

    function UNSTAKE_WINDOW() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./AaveV2Strategy.sol";

//solhint-disable no-empty-blocks
contract AaveV2StrategyWBTC is AaveV2Strategy {
    string public constant NAME = "Strategy-AaveV2-WBTC";
    string public constant VERSION = "2.0.3";

    constructor(address _controller, address _pool)
        public
        AaveV2Strategy(_controller, _pool, 0x9ff58f4fFB29fA2266Ab25e75e2A8b3503311656) // aWBTC
    {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./AaveV2Strategy.sol";

//solhint-disable no-empty-blocks
contract AaveV2StrategyUSDC is AaveV2Strategy {
    string public constant NAME = "Strategy-AaveV2-USDC";
    string public constant VERSION = "2.0.2";

    constructor(address _controller, address _pool)
        public
        AaveV2Strategy(_controller, _pool, 0xBcca60bB61934080951369a648Fb03DF4F96263C) //aUSDC
    {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./AaveV2Strategy.sol";

//solhint-disable no-empty-blocks
contract AaveV2StrategyLINK is AaveV2Strategy {
    string public constant NAME = "Strategy-AaveV2-LINK";
    string public constant VERSION = "2.0.3";

    constructor(address _controller, address _pool)
        public
        AaveV2Strategy(_controller, _pool, 0xa06bC25B5805d5F8d82847D191Cb4Af5A3e873E0) //aLink
    {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./AaveV2Strategy.sol";
import "../interfaces/token/IToken.sol";

//solhint-disable no-empty-blocks
contract AaveV2StrategyETH is AaveV2Strategy {
    string public constant NAME = "Strategy-AaveV2-ETH";
    string public constant VERSION = "2.0.3";

    constructor(address _controller, address _pool)
        public
        AaveV2Strategy(_controller, _pool, 0x030bA81f1c18d280636F32af80b9AAd02Cf0854e) // aWETH
    {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./AaveV2Strategy.sol";

//solhint-disable no-empty-blocks
contract AaveV2StrategyDAI is AaveV2Strategy {
    string public constant NAME = "Strategy-AaveV2-DAI";
    string public constant VERSION = "2.0.3";

    constructor(address _controller, address _pool)
        public
        AaveV2Strategy(_controller, _pool, 0x028171bCA77440897B824Ca71D1c56caC55b68A3) //aDAI
    {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./MakerStrategy.sol";
import "./AaveRewards.sol";
import "../interfaces/aave/IAaveV2.sol";

/// @dev This strategy will deposit collateral token in Maker and borrow DAI
/// and deposit borrowed DAI in Aave to earn interest on it.
abstract contract AaveV2MakerStrategy is MakerStrategy, AaveRewards {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    //solhint-disable-next-line const-name-snakecase
    AaveLendingPoolAddressesProvider public constant aaveAddressesProvider =
        AaveLendingPoolAddressesProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);

    uint256 private constant WAT = 10**16;
    IERC20 private immutable aToken;
    mapping(address => bool) private reservedToken;

    constructor(
        address _controller,
        address _pool,
        address _cm,
        address _receiptToken,
        bytes32 _collateralType
    ) public MakerStrategy(_controller, _pool, _cm, _receiptToken, _collateralType) {
        aToken = IERC20(_receiptToken);
    }

    /// @notice Initiate cooldown to unstake aave.
    function startCooldown() external onlyKeeper returns (bool) {
        return _startCooldown();
    }

    /// @notice Unstake Aave from stakedAave contract
    function unstakeAave() external onlyKeeper {
        _unstakeAave();
    }

    /// @notice Returns interest earned since last rebalance.
    function interestEarned() public view virtual override returns (uint256 collateralEarned) {
        collateralEarned = super.interestEarned();
        uint256 _aaveAmount = stkAAVE.getTotalRewardsBalance(address(this));
        if (_aaveAmount != 0) {
            (, uint256 _amountOut, ) =
                swapManager.bestOutputFixedInput(AAVE, address(collateralToken), _aaveAmount);
            collateralEarned = collateralEarned.add(_amountOut);
        }
    }

    /// @dev Check whether given token is reserved or not. Reserved tokens are not allowed to sweep.
    function isReservedToken(address _token) public view override returns (bool) {
        return _token == receiptToken || _token == AAVE || _token == address(stkAAVE);
    }

    /// @dev Approve Dai and collateralToken to collateral manager
    function _approveToken(uint256 _amount) internal override {
        super._approveToken(_amount);
        IERC20(DAI).safeApprove(aaveAddressesProvider.getLendingPool(), _amount);
        for (uint256 i = 0; i < swapManager.N_DEX(); i++) {
            IERC20(AAVE).safeApprove(address(swapManager.ROUTERS(i)), _amount);
        }
    }

    function _claimReward() internal override {
        uint256 _aaveAmount = _claimAave();
        if (_aaveAmount != 0) {
            _safeSwap(AAVE, address(collateralToken), _aaveAmount);
        }
    }

    function _depositDaiToLender(uint256 _amount) internal override {
        address _aaveLendingPool = aaveAddressesProvider.getLendingPool();
        AaveLendingPool(_aaveLendingPool).deposit(DAI, _amount, address(this), 0);
    }

    function _getDaiBalance() internal view override returns (uint256) {
        return aToken.balanceOf(address(this));
    }

    function _withdrawDaiFromLender(uint256 _amount) internal override {
        address _aaveLendingPool = aaveAddressesProvider.getLendingPool();
        require(
            AaveLendingPool(_aaveLendingPool).withdraw(DAI, _amount, address(this)) == _amount,
            "withdrawn-amount-is-not-correct"
        );
    }

    /// dev these functions are not implemented for this strategy
    // solhint-disable-next-line no-empty-blocks
    function _migrateIn() internal override {}

    // solhint-disable-next-line no-empty-blocks
    function _migrateOut() internal override {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./AaveV2MakerStrategy.sol";

//solhint-disable no-empty-blocks
contract AaveV2MakerStrategyETH is AaveV2MakerStrategy {
    string public constant NAME = "AaveV2Maker-Strategy-ETH";
    string public constant VERSION = "2.0.3";

    constructor(
        address _controller,
        address _pool,
        address _cm
    )
        public
        AaveV2MakerStrategy(
            _controller,
            _pool,
            _cm,
            0x028171bCA77440897B824Ca71D1c56caC55b68A3, //aDAI
            "ETH-A"
        )
    {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./PTokenBase.sol";
import "../interfaces/token/IToken.sol";

contract PETH is PTokenBase {
    TokenLike public immutable weth;
    bool internal shouldDeposit = true;

    constructor(address _controller)
        public
        PTokenBase("pETH Pool", "pETH", 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, _controller)
    {
        weth = TokenLike(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    }

    /// @dev Handle incoming ETH to the contract address.
    receive() external payable {
        if (shouldDeposit) {
            deposit();
        }
    }

    /// @dev Burns tokens/shares and returns the ETH value, after fee, of those.
    function withdrawETH(uint256 shares) external whenNotShutdown nonReentrant {
        require(shares != 0, "Withdraw must be greater than 0");
        _beforeBurning(shares);
        uint256 sharesAfterFee = _handleFee(shares);
        uint256 amount = sharesAfterFee.mul(totalValue()).div(totalSupply());
        _burn(_msgSender(), sharesAfterFee);

        uint256 balanceHere = tokensHere();
        if (balanceHere < amount) {
            _withdrawCollateral(amount.sub(balanceHere));
            balanceHere = tokensHere();
            amount = balanceHere < amount ? balanceHere : amount;
        }
        // Unwrap WETH to ETH
        shouldDeposit = false;
        weth.withdraw(amount);
        shouldDeposit = true;
        Address.sendValue(_msgSender(), amount);

        emit Withdraw(_msgSender(), shares, amount);
    }

    /**
     * @dev Receives ETH and grants new tokens/shares to the sender depending
     * on the value of pool's share.
     */
    function deposit() public payable whenNotPaused nonReentrant {
        uint256 shares = _calculateShares(msg.value);
        // Wraps ETH in WETH
        weth.deposit{value: msg.value}();
        _mint(_msgSender(), shares);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./PoolShareToken.sol";
import "../interfaces/uniswap/IUniswapV2Router02.sol";
import "../interfaces/vesper/IStrategy.sol";

abstract contract PTokenBase is PoolShareToken {
    address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    constructor(
        string memory name,
        string memory symbol,
        address _token,
        address _controller
    ) public PoolShareToken(name, symbol, _token, _controller) {
        require(_controller != address(0), "Controller address is zero");
    }

    modifier onlyController() {
        require(address(controller) == _msgSender(), "Caller is not the controller");
        _;
    }

    function pause() external onlyController {
        _pause();
    }

    function unpause() external onlyController {
        _unpause();
    }

    function shutdown() external onlyController {
        _shutdown();
    }

    function open() external onlyController {
        _open();
    }

    /// @dev Approve strategy to spend collateral token and strategy token of pool.
    function approveToken() external virtual onlyController {
        address strategy = controller.strategy(address(this));
        token.safeApprove(strategy, MAX_UINT_VALUE);
        //IERC20(IStrategy(strategy).token()).safeApprove(strategy, MAX_UINT_VALUE); // DEBUG kovan
        //IERC20(0xe22da380ee6B445bb8273C81944ADEB6E8450422).safeApprove(strategy, MAX_UINT_VALUE); // DEBUG kovan
    }

    /// @dev Reset token approval of strategy. Called when updating strategy.
    function resetApproval() external virtual onlyController {
        address strategy = controller.strategy(address(this));
        token.safeApprove(strategy, 0);
        //IERC20(IStrategy(strategy).token()).safeApprove(strategy, 0); // DEBUG kovan
    }

    /**
     * @dev Rebalance invested collateral to mitigate liquidation risk, if any.
     * Behavior of rebalance is driven by risk parameters defined in strategy.
     */
    function rebalance() external virtual {
        IStrategy strategy = IStrategy(controller.strategy(address(this)));
        strategy.rebalance();
    }

    /**
     * @dev Convert given ERC20 token into collateral token via Uniswap
     * @param _erc20 Token address
     */
    function sweepErc20(address _erc20) external virtual {
        _sweepErc20(_erc20);
    }

    /// @dev Returns collateral token locked in strategy
    function tokenLocked() public view virtual returns (uint256) {
        IStrategy strategy = IStrategy(controller.strategy(address(this)));
        return strategy.totalLocked();
    }

    /// @dev Returns total value of vesper pool, in terms of collateral token
    function totalValue() public view override returns (uint256) {
        return tokenLocked().add(tokensHere());
    }

    /**
     * @dev After burning hook, it will be called during withdrawal process.
     * It will withdraw collateral from strategy and transfer it to user.
     */
    function _afterBurning(uint256 _amount) internal override {
        uint256 balanceHere = tokensHere();
        if (balanceHere < _amount) {
            _withdrawCollateral(_amount.sub(balanceHere));
            balanceHere = tokensHere();
            _amount = balanceHere < _amount ? balanceHere : _amount;
        }
        token.safeTransfer(_msgSender(), _amount);
    }

    /**
     * @dev Before burning hook.
     * Some actions, like resurface(), can impact share price and has to be called before withdraw.
     */
    function _beforeBurning(
        uint256 /* shares */
    ) internal override {
        IStrategy strategy = IStrategy(controller.strategy(address(this)));
        strategy.beforeWithdraw();
    }

    function _beforeMinting(uint256 amount) internal override {
        token.safeTransferFrom(_msgSender(), address(this), amount);
    }

    function _withdrawCollateral(uint256 amount) internal virtual {
        IStrategy strategy = IStrategy(controller.strategy(address(this)));
        strategy.withdraw(amount);
    }

    function _sweepErc20(address _from) internal {
        IStrategy strategy = IStrategy(controller.strategy(address(this)));
        require(
            _from != address(token) && _from != address(this) && !strategy.isReservedToken(_from),
            "Not allowed to sweep"
        );
        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(controller.uniswapRouter());
        uint256 amt = IERC20(_from).balanceOf(address(this));
        IERC20(_from).safeApprove(address(uniswapRouter), 0);
        IERC20(_from).safeApprove(address(uniswapRouter), amt);
        address[] memory path;
        if (address(token) == WETH) {
            path = new address[](2);
            path[0] = _from;
            path[1] = address(token);
        } else {
            path = new address[](3);
            path[0] = _from;
            path[1] = WETH;
            path[2] = address(token);
        }
        uniswapRouter.swapExactTokensForTokens(amt, 1, path, address(this), now + 30);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./PTokenBase.sol";

//solhint-disable no-empty-blocks
contract PWBTC is PTokenBase {
    constructor(address _controller)
        public
        PTokenBase("pWBTC Pool", "pWBTC", 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599, _controller)
    {}

    /// @dev Convert to 18 decimals from token defined decimals.
    function convertTo18(uint256 _value) public pure override returns (uint256) {
        return _value.mul(10**10);
    }

    /// @dev Convert from 18 decimals to token defined decimals.
    function convertFrom18(uint256 _value) public pure override returns (uint256) {
        return _value.div(10**10);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./PTokenBase.sol";

//solhint-disable no-empty-blocks
contract PUSDC is PTokenBase {
    constructor(address _controller)
        public
        //PTokenBase("pUSDC Pool", "pUSDC", 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, _controller) // mainnet
        PTokenBase("pUSDC Pool", "pUSDC", 0xe22da380ee6B445bb8273C81944ADEB6E8450422, _controller) // kovan
    {}

    /// @dev Convert to 18 decimals from token defined decimals.
    function convertTo18(uint256 _value) public pure override returns (uint256) {
        return _value.mul(10**12);
    }

    /// @dev Convert from 18 decimals to token defined decimals.
    function convertFrom18(uint256 _value) public pure override returns (uint256) {
        return _value.div(10**12);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./PTokenBase.sol";

//solhint-disable no-empty-blocks
contract PLINK is PTokenBase {
    constructor(address _controller)
        public
        PTokenBase("pLINK Pool", "pLINK", 0x514910771AF9Ca656af840dff83E8264EcF986CA, _controller)
    {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./PTokenBase.sol";

//solhint-disable no-empty-blocks
contract PDAI is PTokenBase {
    constructor(address _controller)
        public
        PTokenBase("pDAI Pool", "pDAI", 0x6B175474E89094C44Da98b954EedeAC495271d0F, _controller)
    {}
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Pausable.sol';
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/SignedSafeMath.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";


/// @title Staking Contract
/// @notice You can use this contract for staking tokens and distribute rewards
/// @dev All function calls are currently implemented without side effects
contract Staking is ReentrancyGuard, Pausable, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SignedSafeMath for int256;
    using SafeCast for int256;
    using SafeCast for uint256;

    /// @notice Info of each user.
    /// `amount` LP token amount the user has provided.
    /// `rewardDebt` The amount of reward entitled to user.
    /// `lastDepositedAt` The timestamp of the last deposit.
    /// `accRewardPerShare` reward amount allocated per LP token.
    /// `lastRewardTime` Last time that the reward is calculated.
    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
        uint256 lastDepositedAt;
        uint256 accRewardPerShare;
        uint256 lastRewardTime;
    }

    uint256 public constant APY_ACCURACY = 1e4;

    uint256 private constant ACC_REWARD_PRECISION = 1e12;

    /// @notice Address of reward contract.
    IERC20 public rewardToken;

    /// @notice Address of the LP token.
    IERC20 public lpToken;

    /// @notice Reward treasury
    address public rewardTreasury;

    /// @notice APY.
    uint256 public baseAPY;

    /// @notice Info of each user that stakes LP tokens.
    mapping(address => UserInfo) public userInfo;

    event Deposit(address indexed user, uint256 amount, address indexed to);
    event Withdraw(address indexed user, uint256 amount, address indexed to);
    event Claim(address indexed user, uint256 amount);
    event EmergencyWithdraw(
        address indexed user,
        uint256 amount,
        address indexed to
    );

    event LogUpdate(
        address indexed user,
        uint256 lastRewardTime,
        uint256 amount,
        uint256 accRewardPerShare
    );
    event LogRewardTreasury(address indexed wallet);

    /**
     * @param _rewardToken The reward token contract address.
     * @param _lpToken The staking contract address.
     * @param _rewardTreasury The reward treasury contract address.
     * @param _baseAPY The APY of reward to be distributed per second.
     */
    constructor(
        IERC20 _rewardToken, 
        IERC20 _lpToken, 
        address _rewardTreasury, 
        uint256 _baseAPY
    ) public {
        rewardToken = _rewardToken;
        lpToken = _lpToken;
        rewardTreasury = _rewardTreasury;
        baseAPY = _baseAPY;
    }

    /**
     * @notice Sets the reward per second to be distributed. Can only be called by the owner.
     * @dev Its decimals count is ACC_REWARD_PRECISION
     * @param _baseAPY The amount of reward to be distributed per second.
     */
    function setBaseAPY(uint256 _baseAPY) public onlyOwner {
        baseAPY = _baseAPY;
    }

    /**
     * @notice set reward wallet
     * @param _wallet address that contains the rewards
     */
    function setRewardTreasury(address _wallet) external onlyOwner {
        rewardTreasury = _wallet;
        emit LogRewardTreasury(_wallet);
    }

    /**
     * @notice return available reward amount
     * @return rewardInTreasury reward amount in treasury
     * @return rewardAllowedForThisPool allowed reward amount to be spent by this pool
     */
    function availableReward()
        public
        view
        returns (uint256 rewardInTreasury, uint256 rewardAllowedForThisPool)
    {
        rewardInTreasury = rewardToken.balanceOf(rewardTreasury);
        rewardAllowedForThisPool = rewardToken.allowance(
            rewardTreasury,
            address(this)
        );
    }

    /**
     * @notice Caclulates the reward apy of the user
     * @return APY
     */
    function rewardAPY(address _user) public view returns (uint256) {
        uint256 tierFactor = _tierFactor(_user);
        return baseAPY.mul(tierFactor).div(10);
    }

    /**
     * @notice Caclulates the tier factor of the user that affects 
     * @return Tier factor of the user - accuracy: 10
     */
    function _tierFactor(address _user) internal view returns (uint256) {
        // PCR decimals: 18
        UserInfo memory user = userInfo[_user];
        if (user.amount < 5000 * 10**18) return 0;
        if (user.amount < 15000 * 10**18) return 5;
        if (user.amount < 35000 * 10**18) return 10;
        if (user.amount < 100000 * 10**18) return 15;
        return 20; 
    }

    /**
     * @notice View function to see pending reward on frontend.
     * @dev It doens't update accRewardPerShare, it's just a view function.
     * @param _user Address of user.
     * @return pending reward for a given user.
     */
    function pendingReward(address _user)
        external
        view
        returns (uint256 pending)
    {
        UserInfo memory user = userInfo[_user];
        uint256 accRewardPerShare_ = user.accRewardPerShare;
        uint256 apy = rewardAPY(_user);

        if (block.timestamp > user.lastRewardTime && user.amount != 0) {
            uint256 time = block.timestamp.sub(user.lastRewardTime);
            uint256 timeReward = user.amount.mul(time).mul(ACC_REWARD_PRECISION).mul(apy).div(APY_ACCURACY).div(365 days);
            accRewardPerShare_ = accRewardPerShare_.add(timeReward / user.amount);
        }
        pending = ((user.amount.mul(accRewardPerShare_).div(ACC_REWARD_PRECISION)).toInt256().sub(user.rewardDebt)).toUint256();
    }

    /**
     * @notice Update reward variables.
     * @dev Updates accRewardPerShare and lastRewardTime.
     */
    function update(address _user) public {
        UserInfo storage user = userInfo[_user];
        uint256 apy = rewardAPY(_user);
        if (block.timestamp > user.lastRewardTime) {
            if (user.amount > 0) {
                uint256 time = block.timestamp.sub(user.lastRewardTime);
                uint256 timeReward = user.amount.mul(time).mul(ACC_REWARD_PRECISION).mul(apy).div(APY_ACCURACY).div(365 days);
                user.accRewardPerShare = user.accRewardPerShare.add(timeReward.div(user.amount));
            }
            user.lastRewardTime = block.timestamp;
            emit LogUpdate(_user, user.lastRewardTime, user.amount, user.accRewardPerShare);
        }
    }

    /**
     * @notice Deposit LP tokens for reward allocation.
     * @param amount LP token amount to deposit.
     * @param to The receiver of `amount` deposit benefit.
     */
    function deposit(uint256 amount, address to) public nonReentrant whenNotPaused {
        update(to);
        UserInfo storage user = userInfo[to];

        // Effects
        user.lastDepositedAt = block.timestamp;
        user.amount = user.amount.add(amount);
        user.rewardDebt = user.rewardDebt.add(
            int256(amount.mul(user.accRewardPerShare) / ACC_REWARD_PRECISION)
        );

        lpToken.safeTransferFrom(msg.sender, address(this), amount);

        emit Deposit(msg.sender, amount, to);
    }

    /**
     * @notice Withdraw LP tokens and harvest rewards to `to`.
     * @param amount LP token amount to withdraw.
     * @param to Receiver of the LP tokens and rewards.
     */
    function withdraw(uint256 amount, address to) public nonReentrant whenNotPaused {
        update(to);
        UserInfo storage user = userInfo[msg.sender];
        int256 accumulatedReward = int256(
            user.amount.mul(user.accRewardPerShare) / ACC_REWARD_PRECISION
        );
        uint256 _pendingReward = accumulatedReward
            .sub(user.rewardDebt)
            .toUint256();

        // Effects
        user.rewardDebt = accumulatedReward.sub(
            int256(amount.mul(user.accRewardPerShare) / ACC_REWARD_PRECISION)
        );
        user.amount = user.amount.sub(amount);

        rewardToken.safeTransferFrom(rewardTreasury, to, _pendingReward);
        lpToken.safeTransfer(to, amount);

        emit Withdraw(msg.sender, amount, to);
        emit Claim(msg.sender, _pendingReward);
    }

    /**
     * @notice Claim rewards and send to `to`.
     * @dev Here comes the formula to calculate reward token amount
     * @param to Receiver of rewards.
     */
    function claim(address to) public nonReentrant whenNotPaused {
        update(to);
        UserInfo storage user = userInfo[msg.sender];
        int256 accumulatedReward = int256(
            user.amount.mul(user.accRewardPerShare) / ACC_REWARD_PRECISION
        );
        uint256 _pendingReward = accumulatedReward
            .sub(user.rewardDebt)
            .toUint256();

        // Effects
        user.rewardDebt = accumulatedReward;

        // Interactions
        if (_pendingReward != 0) {
            rewardToken.safeTransferFrom(rewardTreasury, to, _pendingReward);
        }

        emit Claim(msg.sender, _pendingReward);
    }

    /**
     * @notice Withdraw without caring about rewards. EMERGENCY ONLY.
     * @param to Receiver of the LP tokens.
     */
    function emergencyWithdraw(address to) public nonReentrant whenNotPaused {
        UserInfo storage user = userInfo[msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        // Note: transfer can fail or succeed if `amount` is zero.
        lpToken.safeTransfer(to, amount);
        emit EmergencyWithdraw(msg.sender, amount, to);
    }

    function renounceOwnership() public override onlyOwner {
        revert();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
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
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "SafeCast: value doesn\'t fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value < 2**64, "SafeCast: value doesn\'t fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value < 2**32, "SafeCast: value doesn\'t fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value < 2**16, "SafeCast: value doesn\'t fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "SafeCast: value doesn\'t fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= -2**127 && value < 2**127, "SafeCast: value doesn\'t fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= -2**63 && value < 2**63, "SafeCast: value doesn\'t fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= -2**31 && value < 2**31, "SafeCast: value doesn\'t fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= -2**15 && value < 2**15, "SafeCast: value doesn\'t fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= -2**7 && value < 2**7, "SafeCast: value doesn\'t fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        require(value < 2**255, "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20Capped.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract PaycerToken is ERC20Capped, Ownable {

    /**
     * @dev Sets the values for {_initialSupply} and {_totalSupply}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(uint256 _initialSupply, uint256 _totalSupply) public ERC20('PaycerToken', 'PCR') ERC20Capped(_totalSupply) {
        ERC20._mint(msg.sender, _initialSupply);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }


    function getChainId() external view returns (uint256) {
        uint256 chainId;
        
        assembly {
            chainId := chainid()
        }

        return chainId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20.sol";

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 */
abstract contract ERC20Capped is ERC20 {
    using SafeMath for uint256;

    uint256 private _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor (uint256 cap_) internal {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - minted tokens must not cause the total supply to go over the cap.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        if (from == address(0)) { // When minting tokens
            require(totalSupply().add(amount) <= cap(), "ERC20Capped: cap exceeded");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "../strategies/Crv3PoolMgr.sol";

contract Crv3PoolMock is Crv3PoolMgr {
    /* solhint-disable */
    constructor() public Crv3PoolMgr() {}

    /* solhint-enable */

    function depositToCrvPool(
        uint256 _daiAmount,
        uint256 _usdcAmount,
        uint256 _usdtAmount
    ) external {
        _depositToCrvPool(_daiAmount, _usdcAmount, _usdtAmount);
    }

    function depositDaiToCrvPool(uint256 _daiAmount, bool _stake) external {
        _depositDaiToCrvPool(_daiAmount, _stake);
    }

    function withdrawAsFromCrvPool(
        uint256 _lpAmount,
        uint256 _minDai,
        uint256 i
    ) external {
        _withdrawAsFromCrvPool(_lpAmount, _minDai, i);
    }

    function withdrawAllAs(uint256 i) external {
        _withdrawAllAs(i);
    }

    function stakeAllLpToGauge() external {
        _stakeAllLpToGauge();
    }

    function unstakeAllLpFromGauge() external {
        _unstakeAllLpFromGauge();
    }

    function unstakeLpFromGauge(uint256 _amount) external {
        _unstakeLpFromGauge(_amount);
    }

    function claimCrv() external {
        _claimCrv();
    }

    function setCheckpoint() external {
        _setCheckpoint();
    }

    // if using this contract on its own.
    function approveLpForGauge() external {
        IERC20(crvLp).safeApprove(crvGauge, 0);
        IERC20(crvLp).safeApprove(crvGauge, type(uint256).max);
    }

    // if using this contract on its own.
    function approveTokenForPool(address _token) external {
        IERC20(_token).safeApprove(crvPool, 0);
        IERC20(_token).safeApprove(crvPool, type(uint256).max);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./Crv3PoolStrategy.sol";

//solhint-disable no-empty-blocks
contract Crv3PoolStrategyDAI is Crv3PoolStrategy {
    string public constant NAME = "Strategy-Curve-3pool-DAI";
    string public constant VERSION = "1.0.0";

    constructor(address _controller, address _pool)
        public
        Crv3PoolStrategy(_controller, _pool, 0)
    {}
}