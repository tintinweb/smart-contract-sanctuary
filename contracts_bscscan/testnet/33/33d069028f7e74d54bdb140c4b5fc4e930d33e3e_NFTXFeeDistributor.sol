// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interface/INFTXLPStaking.sol";
import "./interface/INFTXFeeDistributor.sol";
import "./interface/INFTXVaultFactory.sol";
import "./token/IERC20Upgradeable.sol";
import "./util/SafeERC20Upgradeable.sol";
import "./util/SafeMathUpgradeable.sol";
import "./util/PausableUpgradeable.sol";
import "./util/ReentrancyGuardUpgradeable.sol";

contract NFTXFeeDistributor is INFTXFeeDistributor, ReentrancyGuardUpgradeable, PausableUpgradeable {
  using SafeERC20Upgradeable for IERC20Upgradeable;

  bool public distributionPaused;

  address public override nftxVaultFactory;
  address public override lpStaking;
  address public override treasury;
  uint256 private constant threshold = 10**9;
  uint256 public override defaultTreasuryAlloc;
  uint256 public override defaultLPAlloc;

  // Total allocation points per vault. 
  mapping(uint256 => uint256) public override allocTotal;
  // Vault-specific treasury allocations.
  mapping(uint256 => uint256) public override specificTreasuryAlloc;
  mapping(uint256 => FeeReceiver[]) feeReceivers;

  event UpdateDefaultLPAlloc(uint256 newLPAlloc);
  event UpdateDefaultTreasuryAlloc(uint256 newTreasuryAlloc);
  event UpdateSpecificTreasuryAlloc(uint256 vaultId, uint256 newSpecificAlloc);

  event UpdateTreasuryAddress(address newTreasury);
  event UpdateLPStakingAddress(address newLPStaking);
  event UpdateNFTXVaultFactory(address factory);
  event PauseDistribution(bool paused); 

  event AddFeeReceiver(uint256 vaultId, address receiver, uint256 allocPoint);
  event UpdateFeeReceiverAlloc(uint256 vaultId, address receiver, uint256 allocPoint);
  event UpdateFeeReceiverAddress(uint256 vaultId, address oldReceiver, address newReceiver);
  event RemoveFeeReceiver(uint256 vaultId, address receiver);
  
  function __FeeDistributor__init__(address _lpStaking, address _treasury) public override initializer {
    __Pausable_init();
    setTreasuryAddress(_treasury);
    setDefaultTreasuryAlloc(0);
    setLPStakingAddress(_lpStaking);
    setDefaultLPAlloc(0.5 ether);
  }

  function distribute(uint256 vaultId) external override virtual nonReentrant {
    require(nftxVaultFactory != address(0));
    address _vault = INFTXVaultFactory(nftxVaultFactory).vault(vaultId);

    uint256 tokenBalance = IERC20Upgradeable(_vault).balanceOf(address(this));

    if (distributionPaused) {
      IERC20Upgradeable(_vault).safeTransfer(treasury, tokenBalance);
      return;
    } 

    if (tokenBalance <= threshold) {
      return;
    }
    // Leave some balance for dust since we know we have more than 10**9.
    tokenBalance -= 1000;
    
    uint256 _treasuryAlloc = specificTreasuryAlloc[vaultId];
    if (_treasuryAlloc == 0) {
      _treasuryAlloc = defaultTreasuryAlloc;
    }

    uint256 _allocTotal = allocTotal[vaultId] + _treasuryAlloc;
    uint256 amountToSend = tokenBalance * _treasuryAlloc / _allocTotal;
    amountToSend = amountToSend > tokenBalance ? tokenBalance : amountToSend;
    IERC20Upgradeable(_vault).safeTransfer(treasury, amountToSend);

    FeeReceiver[] memory _feeReceivers = feeReceivers[vaultId];
    for (uint256 i = 0; i < _feeReceivers.length; i++) {
      _sendForReceiver(_feeReceivers[i], vaultId, _vault, tokenBalance, _allocTotal);
    } 
  }

  function addReceiver(uint256 _vaultId, uint256 _allocPoint, address _receiver, bool _isContract) external override virtual onlyOwner  {
    _addReceiver(_vaultId, _allocPoint, _receiver, _isContract);
  }

  function initializeVaultReceivers(uint256 _vaultId) external override {
    require(msg.sender == nftxVaultFactory, "FeeReceiver: not factory");
    _addReceiver(_vaultId, defaultLPAlloc, lpStaking, true);
    INFTXLPStaking(lpStaking).addPoolForVault(_vaultId);
  }

  function changeMultipleReceiverAlloc(
    uint256[] memory _vaultIds, 
    uint256[] memory _receiverIdxs, 
    uint256[] memory allocPoints
  ) public override virtual onlyOwner {
    require(_vaultIds.length == _receiverIdxs.length, "Lengths not equal");
    require(allocPoints.length == _receiverIdxs.length, "Lengths not equal");
    for (uint256 i = 0; i < _vaultIds.length; i++) {
      changeReceiverAlloc(_vaultIds[i], _receiverIdxs[i], allocPoints[i]);
    }
  }

  function changeReceiverAlloc(uint256 _vaultId, uint256 _receiverIdx, uint256 _allocPoint) public override virtual onlyOwner {
    FeeReceiver storage feeReceiver = feeReceivers[_vaultId][_receiverIdx];
    allocTotal[_vaultId] -= feeReceiver.allocPoint;
    feeReceiver.allocPoint = _allocPoint;
    allocTotal[_vaultId] += _allocPoint;
    emit UpdateFeeReceiverAlloc(_vaultId, feeReceiver.receiver, _allocPoint);
  }

  function changeMultipleReceiverAddress(
    uint256[] memory _vaultIds, 
    uint256[] memory _receiverIdxs, 
    address[] memory addresses, 
    bool[] memory isContracts
  ) public override virtual onlyOwner {
    require(_vaultIds.length == _receiverIdxs.length, "Lengths not equal");
    require(addresses.length == _receiverIdxs.length, "Lengths not equal");
    require(addresses.length == isContracts.length, "Lengths not equal");
    for (uint256 i = 0; i < _vaultIds.length; i++) {
      changeReceiverAddress(_vaultIds[i], _receiverIdxs[i], addresses[i], isContracts[i]);
    }
  }

  function changeReceiverAddress(uint256 _vaultId, uint256 _receiverIdx, address _address, bool _isContract) public override virtual onlyOwner {
    FeeReceiver storage feeReceiver = feeReceivers[_vaultId][_receiverIdx];
    address oldReceiver = feeReceiver.receiver;
    feeReceiver.receiver = _address;
    feeReceiver.isContract = _isContract;
    emit UpdateFeeReceiverAddress(_vaultId, oldReceiver, _address);
  }

  function removeReceiver(uint256 _vaultId, uint256 _receiverIdx) external override virtual onlyOwner {
    FeeReceiver[] storage feeReceiversForVault = feeReceivers[_vaultId];
    uint256 arrLength = feeReceiversForVault.length;
    require(_receiverIdx < arrLength, "FeeDistributor: Out of bounds");
    emit RemoveFeeReceiver(_vaultId, feeReceiversForVault[_receiverIdx].receiver);
    allocTotal[_vaultId] -= feeReceiversForVault[_receiverIdx].allocPoint;
    // Copy the last element to what is being removed and remove the last element.
    feeReceiversForVault[_receiverIdx] = feeReceiversForVault[arrLength-1];
    feeReceiversForVault.pop();
  }

  function setTreasuryAddress(address _treasury) public override onlyOwner {
    require(_treasury != address(0), "Treasury != address(0)");
    treasury = _treasury;
    emit UpdateTreasuryAddress(_treasury);
  }

  function setDefaultTreasuryAlloc(uint256 _allocPoint) public override onlyOwner {
    defaultTreasuryAlloc = _allocPoint;
    emit UpdateDefaultTreasuryAlloc(_allocPoint);
  }

  function setSpecificTreasuryAlloc(uint256 vaultId, uint256 _allocPoint) external override onlyOwner {
    specificTreasuryAlloc[vaultId] = _allocPoint;
    emit UpdateSpecificTreasuryAlloc(vaultId, _allocPoint);
  }

  function setLPStakingAddress(address _lpStaking) public override onlyOwner {
    require(_lpStaking != address(0), "LPStaking != address(0)");
    lpStaking = _lpStaking;
    emit UpdateLPStakingAddress(_lpStaking);
  }

  function setDefaultLPAlloc(uint256 _allocPoint) public override onlyOwner {
    defaultLPAlloc = _allocPoint;
    emit UpdateDefaultLPAlloc(_allocPoint);
  }

  function setNFTXVaultFactory(address _factory) external override onlyOwner {
    nftxVaultFactory = _factory;
    emit UpdateNFTXVaultFactory(_factory);
  }

  function pauseFeeDistribution(bool pause) external onlyOwner {
    distributionPaused = pause;
    emit PauseDistribution(pause);
  }

  function rescueTokens(address _address) external override onlyOwner {
    uint256 balance = IERC20Upgradeable(_address).balanceOf(address(this));
    IERC20Upgradeable(_address).safeTransfer(msg.sender, balance);
  }

  function _addReceiver(uint256 _vaultId, uint256 _allocPoint, address _receiver, bool _isContract) internal virtual {
    allocTotal[_vaultId] += _allocPoint;
    FeeReceiver memory _feeReceiver = FeeReceiver(_allocPoint, _receiver, _isContract);
    feeReceivers[_vaultId].push(_feeReceiver);
    emit AddFeeReceiver(_vaultId, _receiver, _allocPoint);
  }

  function _sendForReceiver(FeeReceiver memory _receiver, uint256 _vaultId, address _vault, uint256 _tokenBalance, uint256 _allocTotal) internal virtual {
    uint256 amountToSend = _tokenBalance * _receiver.allocPoint / _allocTotal;
    // If we're at this point we know we have more than enough to perform this safely.
    uint256 balance = IERC20Upgradeable(_vault).balanceOf(address(this)) - 1000;
    amountToSend = amountToSend > balance ? balance : amountToSend;

    if (_receiver.isContract) {
      IERC20Upgradeable(_vault).approve(_receiver.receiver, amountToSend);
      // If the receive is not properly processed, send it to the treasury instead.
       
      bytes memory payload = abi.encodeWithSelector(INFTXLPStaking.receiveRewards.selector, _vaultId, amountToSend);
      (bool success, ) = address(_receiver.receiver).call(payload);

      // If the allowance has not been spent, it means we can pass it through the treasury instead.
      if (!success || IERC20Upgradeable(_vault).allowance(address(this), _receiver.receiver) > 0) {
        IERC20Upgradeable(_vault).safeTransfer(treasury, amountToSend);
        IERC20Upgradeable(_vault).approve(_receiver.receiver, 0);
      }
    } else {
      IERC20Upgradeable(_vault).safeTransfer(_receiver.receiver, amountToSend);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INFTXLPStaking {
    function nftxVaultFactory() external view returns (address);
    function rewardDistTokenImpl() external view returns (address);
    function stakingTokenProvider() external view returns (address);
    function vaultToken(address _stakingToken) external view returns (address);
    function stakingToken(address _vaultToken) external view returns (address);
    function rewardDistributionToken(uint256 vaultId) external view returns (address);
    function newRewardDistributionToken(uint256 vaultId) external view returns (address);
    function oldRewardDistributionToken(uint256 vaultId) external view returns (address);
    function unusedRewardDistributionToken(uint256 vaultId) external view returns (address);
    function rewardDistributionTokenAddr(address stakingToken, address rewardToken) external view returns (address);
    
    // Write functions.
    function __NFTXLPStaking__init(address _stakingTokenProvider) external;
    function setNFTXVaultFactory(address newFactory) external;
    function setStakingTokenProvider(address newProvider) external;
    function addPoolForVault(uint256 vaultId) external;
    function updatePoolForVault(uint256 vaultId) external;
    function updatePoolForVaults(uint256[] calldata vaultId) external;
    function receiveRewards(uint256 vaultId, uint256 amount) external returns (bool);
    function deposit(uint256 vaultId, uint256 amount) external;
    function timelockDepositFor(uint256 vaultId, address account, uint256 amount, uint256 timelockLength) external;
    function exit(uint256 vaultId, uint256 amount) external;
    function rescue(uint256 vaultId) external;
    function withdraw(uint256 vaultId, uint256 amount) external;
    function claimRewards(uint256 vaultId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface INFTXFeeDistributor {
  
  struct FeeReceiver {
    uint256 allocPoint;
    address receiver;
    bool isContract;
  }

  function nftxVaultFactory() external returns (address);
  function lpStaking() external returns (address);
  function treasury() external returns (address);
  function defaultTreasuryAlloc() external returns (uint256);
  function defaultLPAlloc() external returns (uint256);
  function allocTotal(uint256 vaultId) external returns (uint256);
  function specificTreasuryAlloc(uint256 vaultId) external returns (uint256);

  // Write functions.
  function __FeeDistributor__init__(address _lpStaking, address _treasury) external;
  function rescueTokens(address token) external;
  function distribute(uint256 vaultId) external;
  function addReceiver(uint256 _vaultId, uint256 _allocPoint, address _receiver, bool _isContract) external;
  function initializeVaultReceivers(uint256 _vaultId) external;
  function changeMultipleReceiverAlloc(
    uint256[] memory _vaultIds, 
    uint256[] memory _receiverIdxs, 
    uint256[] memory allocPoints
  ) external;

  function changeMultipleReceiverAddress(
    uint256[] memory _vaultIds, 
    uint256[] memory _receiverIdxs, 
    address[] memory addresses, 
    bool[] memory isContracts
  ) external;
  function changeReceiverAlloc(uint256 _vaultId, uint256 _idx, uint256 _allocPoint) external;
  function changeReceiverAddress(uint256 _vaultId, uint256 _idx, address _address, bool _isContract) external;
  function removeReceiver(uint256 _vaultId, uint256 _receiverIdx) external;

  // Configuration functions.
  function setTreasuryAddress(address _treasury) external;
  function setDefaultTreasuryAlloc(uint256 _allocPoint) external;
  function setSpecificTreasuryAlloc(uint256 _vaultId, uint256 _allocPoint) external;
  function setLPStakingAddress(address _lpStaking) external;
  function setNFTXVaultFactory(address _factory) external;
  function setDefaultLPAlloc(uint256 _allocPoint) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../proxy/IBeacon.sol";

interface INFTXVaultFactory is IBeacon {
  // Read functions.
  function numVaults() external view returns (uint256);
  function zapContract() external view returns (address);
  function feeDistributor() external view returns (address);
  function eligibilityManager() external view returns (address);
  function vault(uint256 vaultId) external view returns (address);
  function vaultsForAsset(address asset) external view returns (address[] memory);
  function isLocked(uint256 id) external view returns (bool);
  function excludedFromFees(address addr) external view returns (bool);

  event NewFeeDistributor(address oldDistributor, address newDistributor);
  event NewZapContract(address oldZap, address newZap);
  event FeeExclusion(address feeExcluded, bool excluded);
  event NewEligibilityManager(address oldEligManager, address newEligManager);
  event NewVault(uint256 indexed vaultId, address vaultAddress, address assetAddress);

  // Write functions.
  function __NFTXVaultFactory_init(address _vaultImpl, address _feeDistributor) external;
  function createVault(
      string calldata name,
      string calldata symbol,
      address _assetAddress,
      bool is1155,
      bool allowAllItems
  ) external returns (uint256);
  function setFeeDistributor(address _feeDistributor) external;
  function setEligibilityManager(address _eligibilityManager) external;
  function setZapContract(address _zapContract) external;
  function setFeeExclusion(address _excludedAddr, bool excluded) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../token/IERC20Upgradeable.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using Address for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
library SafeMathUpgradeable {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "./SafeMathUpgradeable.sol";

contract PausableUpgradeable is OwnableUpgradeable {

    function __Pausable_init() internal initializer {
        __Ownable_init();
    }

    event SetPaused(uint256 lockId, bool paused);
    event SetIsGuardian(address addr, bool isGuardian);

    mapping(address => bool) public isGuardian;
    mapping(uint256 => bool) public isPaused;
    // 0 : createVault
    // 1 : mint
    // 2 : redeem
    // 3 : swap
    // 4 : flashloan

    function onlyOwnerIfPaused(uint256 lockId) public view virtual {
        require(!isPaused[lockId] || msg.sender == owner(), "Paused");
    }

    function unpause(uint256 lockId)
        public
        virtual
        onlyOwner
    {
        isPaused[lockId] = false;
        emit SetPaused(lockId, false);
    }

    function pause(uint256 lockId) public virtual {
        require(isGuardian[msg.sender], "Can't pause");
        isPaused[lockId] = true;
        emit SetPaused(lockId, true);
    }

    function setIsGuardian(address addr, bool _isGuardian) public virtual onlyOwner {
        isGuardian[addr] = _isGuardian;
        emit SetIsGuardian(addr, _isGuardian);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function childImplementation() external view returns (address);
    function upgradeChildTo(address newImplementation) external;
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

pragma solidity ^0.8.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

