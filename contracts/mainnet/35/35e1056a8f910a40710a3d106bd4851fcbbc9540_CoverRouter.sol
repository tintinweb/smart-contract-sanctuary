// SPDX-License-Identifier: None
pragma solidity ^0.7.5;

import "./interfaces/IBFactory.sol";
import "./interfaces/IBPool.sol";
import "./interfaces/ICover.sol";
import "./interfaces/ICoverERC20.sol";
import "./interfaces/ICoverRouter.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IProtocol.sol";
import "./utils/Ownable.sol";
import "./utils/SafeERC20.sol";
import "./utils/SafeMath.sol";
import "./Rollover.sol";

/**
 * @title CoverRouter for Cover Protocol, handles balancer activities
 * @author [email protected] + Kiwi
 */
contract CoverRouter is ICoverRouter, Ownable, Rollover {
  using SafeERC20 for IERC20;
  using SafeERC20 for IBPool;
  using SafeMath for uint256;

  address public protocolFactory;
  IBFactory public bFactory;

  uint256 public constant TOTAL_WEIGHT = 50 ether;
  uint256 public claimCovTokenWeight = 40 ether;
  uint256 public noclaimCovTokenWeight = 49 ether;
  uint256 public claimSwapFee = 0.01 ether;
  uint256 public noclaimSwapFee = 0.01 ether;

  mapping(bytes32 => address) private pools;

  event PoolSet(address indexed covtoken, address indexed pairedToken, address indexed poolAddr);

  constructor(address _protocolFactory, IBFactory _bFactory) Ownable() {
    protocolFactory = _protocolFactory;
    bFactory = _bFactory;
  }

  function poolForPair(address _covToken, address _pairedToken) external override view returns (address) {
    bytes32 pairKey = _pairKeyForPair(_covToken, _pairedToken);
    return pools[pairKey];
  }

  /// @dev add buffer support (1%) as suggested by balancer doc to help get tx through. https://docs.balancer.finance/smart-contracts/core-contracts/api#joinpool
  function provideLiquidity(
    address _covToken,
    uint256 _covTokenAmount,
    address _pairedToken,
    uint256 _pairedTokenAmount,
    bool _addBuffer
  ) external override {
    IERC20 covToken = IERC20(_covToken);
    IERC20 pairedToken = IERC20(_pairedToken);
    require(covToken.balanceOf(msg.sender) >= _covTokenAmount, "CoverRouter: insufficient covToken");
    require(pairedToken.balanceOf(msg.sender) >= _pairedTokenAmount, "CoverRouter: insufficient pairedToken");
    address poolAddr = pools[_pairKeyForPair(_covToken, _pairedToken)];
    require(poolAddr != address(0), "CoverRouter: pool not found");

    IBPool pool = IBPool(poolAddr);
    (uint256 bptAmountOut, uint256[] memory maxAmountsIn) = _getBptAmountOut(pool, _covToken, _covTokenAmount, _pairedToken, _pairedTokenAmount, _addBuffer);

    covToken.safeTransferFrom(msg.sender, address(this), _covTokenAmount);
    pairedToken.safeTransferFrom(msg.sender, address(this), _pairedTokenAmount);
    _approve(covToken, poolAddr, _covTokenAmount);
    _approve(pairedToken, poolAddr, _pairedTokenAmount);
    pool.joinPool(bptAmountOut, maxAmountsIn);

    IERC20 bpt = IERC20(poolAddr);
    bpt.safeTransfer(msg.sender, bpt.balanceOf(address(this)));
    uint256 remainCovToken = covToken.balanceOf(address(this));
    if (remainCovToken > 0) {
      covToken.safeTransfer(msg.sender, remainCovToken);
    }
    uint256 remainPairedToken = pairedToken.balanceOf(address(this));
    if (remainPairedToken > 0) {
      pairedToken.safeTransfer(msg.sender, remainPairedToken);
    }
  }

  function removeLiquidity(
    address _covToken,
    address _pairedToken,
    uint256 _bptAmount
  ) external override {
    require(_bptAmount > 0, "CoverRouter: insufficient covToken");
    bytes32 pairKey = _pairKeyForPair(_covToken, _pairedToken);
    address poolAddr = pools[pairKey];
    require(poolAddr != address(0), "CoverRouter: pool not found");

    uint256[] memory minAmountsOut = new uint256[](2);
    minAmountsOut[0] = 0;
    minAmountsOut[1] = 0;

    IERC20(poolAddr).safeTransferFrom(msg.sender, address(this), _bptAmount);
    IBPool(poolAddr).exitPool(IERC20(poolAddr).balanceOf(address(this)), minAmountsOut);

    IERC20 covToken = IERC20(_covToken);
    IERC20 pairedToken = IERC20(_pairedToken);
    covToken.safeTransfer(msg.sender, covToken.balanceOf(address(this)));
    pairedToken.safeTransfer(msg.sender, pairedToken.balanceOf(address(this)));
  }

  function setPoolForPair(address _covToken, address _pairedToken, address _newPool) public override onlyOwner {
    _validCovToken(_covToken);
    _validBalPoolTokens(_covToken, _pairedToken, IBPool(_newPool));

    bytes32 pairKey = _pairKeyForPair(_covToken, _pairedToken);
    pools[pairKey] = _newPool;
    emit PoolSet(_covToken, _pairedToken, _newPool);
  }

  function createNewPoolForPair(address _covToken, uint256 _covTokenAmount, address _pairedToken, uint256 _pairedTokenAmount) external override returns (address) {
    require(_pairedToken != _covToken, "CoverRouter: same token");
    bytes32 pairKey = _pairKeyForPair(_covToken, _pairedToken);
    require(pools[pairKey] == address(0), "CoverRouter: pool already exists");
    _validCovToken(_covToken);

    // Get the Cover contract from the token to check if its the claim or noclaim.
    ICover cover = ICover(ICoverERC20(_covToken).owner());
    bool isClaimPair = address(cover.claimCovToken()) == _covToken;

    IERC20(_covToken).safeTransferFrom(msg.sender, address(this), _covTokenAmount);
    IERC20(_pairedToken).safeTransferFrom(msg.sender, address(this), _pairedTokenAmount);
    address pool = _createBalPool(_covToken, _pairedToken, _covTokenAmount, _pairedTokenAmount, isClaimPair);

    pools[pairKey] = pool;
    emit PoolSet(_covToken, _pairedToken, pool);
    return pool;
  }

  function setPoolsForPairs(address[] memory _covTokens, address[] memory _pairedTokens, address[] memory _newPools) external override onlyOwner {
    require(_covTokens.length == _pairedTokens.length, "CoverRouter: Paired tokens length not equal");
    require(_covTokens.length == _newPools.length, "CoverRouter: Pools length not equal");

    for (uint256 i = 0; i < _covTokens.length; i++) {
      setPoolForPair(_covTokens[i], _pairedTokens[i], _newPools[i]);
    }
  }

  function setSwapFee(uint256 _claimSwapFees, uint256 _noclaimSwapFees) external override onlyOwner {
    require(_claimSwapFees > 0 && _noclaimSwapFees > 0, "CoverRouter: invalid fees");
    claimSwapFee = _claimSwapFees;
    noclaimSwapFee = _noclaimSwapFees;
  }

  function setCovTokenWeights(uint256 _claimCovTokenWeight, uint256 _noclaimCovTokenWeight) external override onlyOwner {
    require(_claimCovTokenWeight < TOTAL_WEIGHT, "CoverRouter: invalid claim weight");
    require(_noclaimCovTokenWeight < TOTAL_WEIGHT, "CoverRouter: invalid noclaim weight");
    claimCovTokenWeight = _claimCovTokenWeight;
    noclaimCovTokenWeight = _noclaimCovTokenWeight;
  }

  function _pairKeyForPair(address _covToken, address _pairedToken) internal view returns (bytes32) {
    (address token0, address token1) = _covToken < _pairedToken ? (_covToken, _pairedToken) : (_pairedToken, _covToken);
    bytes32 pairKey = keccak256(abi.encodePacked(
      protocolFactory,
      token0,
      token1
    ));
    return pairKey;
  }

  /// @notice make covToken is from Cover Protocol Factory
  function _validCovToken(address _covToken) private view {
    require(_covToken != address(0), "CoverRouter: covToken is 0 address");

    ICover cover = ICover(ICoverERC20(_covToken).owner());
    address tokenProtocolFactory = IProtocol(cover.owner()).owner();
    require(tokenProtocolFactory == protocolFactory, "CoverRouter: wrong factory");
  }

  function _getBptAmountOut(
    IBPool pool,
    address _covToken,
    uint256 _covTokenAmount,
    address _pairedToken,
    uint256 _pairedTokenAmount,
    bool _addBuffer
  ) internal view returns (uint256 bptAmountOut, uint256[] memory maxAmountsIn) {
    uint256 poolAmountOutInCov = _covTokenAmount.mul(pool.totalSupply()).div(pool.getBalance(_covToken));
    uint256 poolAmountOutInPaired = _pairedTokenAmount.mul(pool.totalSupply()).div(pool.getBalance(_pairedToken));
    bptAmountOut = poolAmountOutInCov > poolAmountOutInPaired ? poolAmountOutInPaired : poolAmountOutInCov;
    bptAmountOut = _addBuffer ? bptAmountOut.mul(99).div(100) : bptAmountOut;

    address[] memory tokens = pool.getFinalTokens();
    maxAmountsIn = new uint256[](2);
    maxAmountsIn[0] =  _covTokenAmount;
    maxAmountsIn[1] = _pairedTokenAmount;
    if (tokens[1] == _covToken) {
      maxAmountsIn[0] =  _pairedTokenAmount;
      maxAmountsIn[1] = _covTokenAmount;
    }
  }

  function _validBalPoolTokens(address _covToken, address _pairedToken, IBPool _pool) private view {
    require(_pairedToken != _covToken, "CoverRouter: same token");
    address[] memory tokens = _pool.getFinalTokens();
    require(tokens.length == 2, "CoverRouter: Too many tokens in pool");
    require((_covToken == tokens[0] && _pairedToken == tokens[1]) || (_pairedToken == tokens[0] && _covToken == tokens[1]), "CoverRouter: tokens don't match");
  }

  function _createBalPool(address _covToken, address _pairedToken, uint256 _covTokenAmount, uint256 _pairedTokenAmount, bool _isClaimPair) private returns (address _poolAddr) {
    IBPool pool = bFactory.newBPool();
    _poolAddr = address(pool);
    uint256 _covTokenSwapFee = _isClaimPair ? claimSwapFee : noclaimSwapFee;
    pool.setSwapFee(_covTokenSwapFee);

    uint256 _covTokenWeight = _isClaimPair ? claimCovTokenWeight : noclaimCovTokenWeight;
    _approve(IERC20(_covToken), _poolAddr, _covTokenAmount);
    pool.bind(_covToken, _covTokenAmount, _covTokenWeight);
    _approve(IERC20(_pairedToken), _poolAddr, _pairedTokenAmount);
    pool.bind(_pairedToken, _pairedTokenAmount, TOTAL_WEIGHT.sub(_covTokenWeight));

    pool.finalize();
    pool.setController(address(0)); // We burn controller since it's useless after finalizing.
    uint256 bptBal = pool.balanceOf(address(this));
    pool.safeTransfer(msg.sender, bptBal);
  }
}

// SPDX-License-Identifier: None

pragma solidity ^0.7.5;

import "./IBPool.sol";

interface IBFactory {
  function newBPool() external returns (IBPool);
}

// SPDX-License-Identifier: None

pragma solidity ^0.7.5;

import "./IERC20.sol";

interface IBPool is IERC20 {
    function getFinalTokens() external view returns(address[] memory);
    function getDenormalizedWeight(address token) external view returns (uint256);
    function setSwapFee(uint256 swapFee) external;
    function setController(address controller) external;
    function finalize() external;
    function bind(address token, uint256 balance, uint256 denorm) external;
    function getBalance(address token) external view returns (uint);
    function joinPool(uint256 poolAmountOut, uint256[] calldata maxAmountsIn) external;
    function exitPool(uint256 poolAmountIn, uint256[] calldata minAmountsOut) external;
}

// SPDX-License-Identifier: No License

pragma solidity ^0.7.3;

import "./IERC20.sol";

/**
 * @title Cover contract interface. See {Cover}.
 * @author [email protected]
 */
interface ICover {
  function owner() external view returns (address);
  function expirationTimestamp() external view returns (uint48);
  function collateral() external view returns (address);
  function claimCovToken() external view returns (IERC20);
  function noclaimCovToken() external view returns (IERC20);
  function claimNonce() external view returns (uint256);

  function redeemClaim() external;
  function redeemNoclaim() external;
  function redeemCollateral(uint256 _amount) external;
}

// SPDX-License-Identifier: None

pragma solidity ^0.7.5;

import "./IERC20.sol";

interface ICoverERC20 is IERC20 {
  function owner() external view returns (address);
}

// SPDX-License-Identifier: None
pragma solidity ^0.7.5;

/**
 * @title CoverRouter interface
 * @author [email protected]
 */
interface ICoverRouter {
  function poolForPair(address _covToken, address _pairedToken) external view returns (address);

  function createNewPoolForPair(address _covToken, uint256 _covAmount, address _pairedToken, uint256 _pairedAmount) external returns (address);

  // owner only
  function setPoolForPair(address _covToken, address _pairedToken, address _newPool) external;
  function setPoolsForPairs(address[] memory _covTokens, address[] memory _pairedTokens, address[] memory _newPools) external;
  function setCovTokenWeights(uint256 _claimCovTokenWeight, uint256 _noclaimCovTokenWeight) external;
  function setSwapFee(uint256 _claimSwapFees, uint256 _noclaimSwapFees) external;

  function removeLiquidity(address _covToken, address _pairedToken, uint256 _btpAmount) external;
  function provideLiquidity(
    address _covToken,
    uint256 _covTokenAmount,
    address _pairedToken,
    uint256 _pairedTokenAmount,
    bool _addBuffer
  ) external;
}

// SPDX-License-Identifier: None

pragma solidity ^0.7.4;

/**
 * @title Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: No License

pragma solidity ^0.7.3;

/**
 * @dev Protocol contract interface. See {Protocol}.
 * @author [email protected]
 */
interface IProtocol {
  function owner() external view returns (address);
  function active() external view returns (bool);
  function name() external view returns (bytes32);
  function claimNonce() external view returns (uint256);
  /// @notice delay # of seconds for redeem with accepted claim, redeemCollateral is not affected
  function claimRedeemDelay() external view returns (uint256);
  /// @notice delay # of seconds for redeem without accepted claim, redeemCollateral is not affected
  function noclaimRedeemDelay() external view returns (uint256);
  function activeCovers(uint256 _index) external view returns (address);
  function claimDetails(uint256 _claimNonce) external view returns (uint16 _payoutNumerator, uint16 _payoutDenominator, uint48 _incidentTimestamp, uint48 _timestamp);
  function collateralStatusMap(address _collateral) external view returns (uint8 _status);
  function expirationTimestampMap(uint48 _expirationTimestamp) external view returns (bytes32 _name, uint8 _status);
  function coverMap(address _collateral, uint48 _expirationTimestamp) external view returns (address);

  function collaterals(uint256 _index) external view returns (address);
  function collateralsLength() external view returns (uint256);
  function expirationTimestamps(uint256 _index) external view returns (uint48);
  function expirationTimestampsLength() external view returns (uint256);
  function activeCoversLength() external view returns (uint256);
  function claimsLength() external view returns (uint256);
  function addCover(address _collateral, uint48 _timestamp, uint256 _amount)
    external returns (bool);
}

// SPDX-License-Identifier: None

pragma solidity ^0.7.4;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 * @author [email protected]
 *
 * By initialization, the owner account will be the one that called initializeOwner. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev COVER: Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
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
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
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

pragma solidity ^0.7.5;

import "./SafeMath.sol";
import "./Address.sol";
import "../interfaces/IERC20.sol";

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

// SPDX-License-Identifier: None

pragma solidity ^0.7.4;

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

// SPDX-License-Identifier: None
pragma solidity ^0.7.5;

import "./interfaces/ICover.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IProtocol.sol";
import "./interfaces/IRollover.sol";
import "./utils/SafeERC20.sol";
import "./utils/SafeMath.sol";

/**
 * @title Rollover zap for Cover Protocol that auto redeems and rollover the coverage to the next cover, it does not sell or buy tokens for sender
 * @author [email protected]
 */
contract Rollover is IRollover {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  /// @notice rollover for sender
  function rollover(address _cover, uint48 _newTimestamp) external override {
    rolloverAccount(_cover, _newTimestamp, msg.sender);
  }

  /// @notice rollover for a different account (from sender)
  function rolloverAccount(
    address _cover,
    uint48 _newTimestamp,
    address _account
  ) public override {
    ICover cover = ICover(_cover);
    uint48 expirationTimestamp = cover.expirationTimestamp();
    require(expirationTimestamp != _newTimestamp && block.timestamp < _newTimestamp, "Rollover: invalid expiry");

    IProtocol protocol = IProtocol(cover.owner());
    bool acceptedClaim = cover.claimNonce() != protocol.claimNonce();
    require(!acceptedClaim, "Rollover: there is an accepted claim");

    (, uint8 expirationStatus) = protocol.expirationTimestampMap(_newTimestamp);
    require(expirationStatus == 1, "Rollover: new timestamp is not active");

    if (block.timestamp < expirationTimestamp) {
      _rolloverBeforeExpire(protocol, cover, _newTimestamp, _account);
    } else {
      require(block.timestamp >= uint256(expirationTimestamp).add(protocol.noclaimRedeemDelay()), "Rollover: not ready");
      _rolloverAfterExpire(protocol, cover, _newTimestamp, _account);
    }
  }

  function _rolloverBeforeExpire(
    IProtocol protocol,
    ICover cover,
    uint48 _newTimestamp,
    address _account
  ) internal {
    // transfer CLAIM and NOCLAIM to contract
    IERC20 claimCovToken = cover.claimCovToken();
    IERC20 noclaimCovToken = cover.noclaimCovToken();
    uint256 claimCovTokenBal = claimCovToken.balanceOf(_account);
    uint256 noclaimCovTokenBal = noclaimCovToken.balanceOf(_account);
    uint256 amount = (claimCovTokenBal > noclaimCovTokenBal) ? noclaimCovTokenBal : claimCovTokenBal;
    require(amount > 0, "Rollover: insufficient covTokens");

    claimCovToken.safeTransferFrom(_account, address(this), amount);
    noclaimCovToken.safeTransferFrom(_account, address(this), amount);

    // redeem collateral back to contract with CLAIM and NOCLAIM tokens
    IERC20 collateral = IERC20(cover.collateral());
    cover.redeemCollateral(amount);
    uint256 redeemedAmount = collateral.balanceOf(address(this));

    _approve(collateral, address(protocol), redeemedAmount);
    protocol.addCover(address(collateral), _newTimestamp, redeemedAmount);
    _sendCovTokensToAccount(protocol, address(collateral), _newTimestamp, _account);
  }

  function _rolloverAfterExpire(
    IProtocol protocol,
    ICover cover,
    uint48 _newTimestamp,
    address _account
  ) internal {
    // transfer CLAIM and NOCLAIM to contract
    IERC20 noclaimCovToken = cover.noclaimCovToken();
    uint256 amount = noclaimCovToken.balanceOf(_account);
    noclaimCovToken.safeTransferFrom(_account, address(this), amount);

    // redeem collateral back to contract with NOCLAIM tokens
    IERC20 collateral = IERC20(cover.collateral());
    cover.redeemNoclaim();
    uint256 redeemedAmount = collateral.balanceOf(address(this));

    _approve(collateral, address(protocol), redeemedAmount);
    protocol.addCover(address(collateral), _newTimestamp, redeemedAmount);
    _sendCovTokensToAccount(protocol, address(collateral), _newTimestamp, _account);
  }

  function _approve(IERC20 _token, address _spender, uint256 _amount) internal {
    if (_token.allowance(address(this), _spender) < _amount) {
      _token.approve(_spender, uint256(-1));
    }
  }

  function _sendCovTokensToAccount(
    IProtocol protocol,
    address _collateral,
    uint48 _timestamp,
    address _account
  ) internal {
    ICover newCover = ICover(protocol.coverMap(_collateral, _timestamp));

    IERC20 newClaimCovToken = newCover.claimCovToken();
    IERC20 newNoclaimCovToken = newCover.noclaimCovToken();

    newClaimCovToken.safeTransfer(_account, newClaimCovToken.balanceOf(address(this)));
    newNoclaimCovToken.safeTransfer(_account, newNoclaimCovToken.balanceOf(address(this)));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// SPDX-License-Identifier: None
pragma solidity ^0.7.5;

interface IRollover {
  function rollover(address _cover, uint48 _newTimestamp) external;
  function rolloverAccount(address _cover, uint48 _newTimestamp, address _account) external;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}