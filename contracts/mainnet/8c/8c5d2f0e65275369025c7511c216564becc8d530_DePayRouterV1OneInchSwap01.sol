/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

// Dependency file: @openzeppelin/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

// pragma solidity >=0.6.0 <0.8.0;

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
     * // importANT: Beware that changing an allowance with this method brings the risk
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


// Dependency file: @openzeppelin/contracts/math/SafeMath.sol


// pragma solidity >=0.6.0 <0.8.0;

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


// Dependency file: contracts/interfaces/IOneSplitAudit.sol


// pragma solidity >=0.7.5 <0.8.0;

interface IOneSplitAudit {
    event ImplementationUpdated(address indexed newImpl);

    event Swapped(
        address indexed fromToken,
        address indexed destToken,
        uint256 fromTokenAmount,
        uint256 destTokenAmount,
        uint256 minReturn,
        uint256[] distribution,
        uint256[] flags,
        address referral,
        uint256 feePercent
    );

    function swap(
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 flags // See contants in IOneSplit.sol
    ) external payable returns (uint256);

    function getExpectedReturn(
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags // See contants in IOneSplit.sol
    ) external view returns (uint256 returnAmount, uint256[] memory distribution);

    function getExpectedReturnWithGas(
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 parts,
        uint256 flags, // See constants in IOneSplit.sol
        uint256 destTokenEthPriceTimesGasPrice
    )
        external
        view
        returns (
            uint256 returnAmount,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        );

    function getExpectedReturnWithGasMulti(
        address[] memory tokens,
        uint256 amount,
        uint256[] memory parts,
        uint256[] memory flags,
        uint256[] memory destTokenEthPriceTimesGasPrices
    )
        external
        view
        returns (
            uint256[] memory returnAmounts,
            uint256 estimateGasAmount,
            uint256[] memory distribution
        );

    function swapWithReferral(
        address fromToken,
        address destToken,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256 flags, // See contants in IOneSplit.sol
        address referral,
        uint256 feePercent
    ) external returns (uint256);

    function swapMulti(
        address[] memory tokens,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256[] memory flags
    ) external returns (uint256);

    function swapWithReferralMulti(
        address[] memory tokens,
        uint256 amount,
        uint256 minReturn,
        uint256[] memory distribution,
        uint256[] memory flags,
        address referral,
        uint256 feePercent
    ) external returns (uint256 returnAmount);
}


// Dependency file: contracts/libraries/Helper.sol

// Helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library Helper {
  function safeApprove(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('approve(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'Helper::safeApprove: approve failed'
    );
  }

  function safeTransfer(
    address token,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transfer(address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'Helper::safeTransfer: transfer failed'
    );
  }

  function safeTransferFrom(
    address token,
    address from,
    address to,
    uint256 value
  ) internal {
    // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(
      success && (data.length == 0 || abi.decode(data, (bool))),
      'Helper::transferFrom: transferFrom failed'
    );
  }

  function safeTransferETH(address to, uint256 value) internal {
    (bool success, ) = to.call{value: value}(new bytes(0));
    require(success, 'Helper::safeTransferETH: ETH transfer failed');
  }
}


// Root file: contracts/DePayRouterV1OneInchSwap01.sol


pragma solidity >=0.7.5 <0.8.0;
pragma abicoder v2;

// import '/Users/sebastian/Work/DePay/depay-ethereum-router/node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol';
// import '/Users/sebastian/Work/DePay/depay-ethereum-router/node_modules/@openzeppelin/contracts/math/SafeMath.sol';
// import 'contracts/interfaces/IOneSplitAudit.sol';
// import 'contracts/libraries/Helper.sol';

contract DePayRouterV1OneInchSwap01 {
  using SafeMath for uint256;

  // Address representating ETH (e.g. in payment routing paths)
  address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

  // MAXINT to be used only, to increase allowance from
  // payment protocol contract towards known
  // decentralized exchanges, not to dyanmically called contracts!!!
  uint256 public immutable MAXINT = type(uint256).max;

  // Address of OneSplitAudit
  address public immutable OneSplitAudit;

  // Indicates that this plugin requires delegate call
  bool public immutable delegate = true;

  // Pass _OneSplitAudit when deploying this contract.
  constructor(address _OneSplitAudit) {
    OneSplitAudit = _OneSplitAudit;
  }

  function _getDistribution(uint256[] calldata amounts) internal returns (uint256[] memory buf) {
    uint256 len = amounts.length - 3;
    buf = new uint256[](len);
    for (uint256 i = 0; i < len; i += 1) {
      buf[i] = amounts[3 + i];
    }
  }

  // Swap tokenA<>tokenB, ETH<>ERC20 or ERC20<>ETH on 1Inch.
  //  function swap(
  //      IERC20 fromToken,
  //      IERC20 destToken,
  //      uint256 amount,
  //      uint256 minReturn,
  //      uint256[] memory distribution,
  //      uint256 flags // See contants in IOneSplit.sol
  //  ) public returns (uint256);
  function execute(
    address[] calldata path,
    uint256[] calldata amounts,
    address[] calldata addresses,
    string[] calldata data
  ) external payable returns (bool) {
    // Make sure swapping the token within the payment protocol contract is approved on the OneSplitAudit.
    if ((path[0] != ETH) && IERC20(path[0]).allowance(address(this), OneSplitAudit) < amounts[0]) {
      // Allow OneSplitAudit transfer token
      Helper.safeApprove(path[0], OneSplitAudit, MAXINT);
    }

    IOneSplitAudit oneSplit = IOneSplitAudit(OneSplitAudit);

    // From token is ETH,
    if (path[0] == ETH) {
        address(OneSplitAudit).call{value: amounts[0]}(
            abi.encodeWithSelector(
                oneSplit.swap.selector,
                path[0],
                path[1],
                amounts[0],
                amounts[1],
                _getDistribution(amounts),
                amounts[2]
            )
        );
    } else {
        address(OneSplitAudit).call(
            abi.encodeWithSelector(
                oneSplit.swap.selector,
                path[0],
                path[1],
                amounts[0],
                amounts[1],
                _getDistribution(amounts),
                amounts[2]
            )
        );
    }
    return false;
  }
}