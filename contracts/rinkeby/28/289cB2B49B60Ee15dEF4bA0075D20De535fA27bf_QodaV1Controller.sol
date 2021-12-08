// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
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
library SafeMath {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract ErrorCode {

  enum Error {
              NO_ERROR,
              UNAUTHORIZED,
              SIGNATURE_MISMATCH,
              INVALID_PRINCIPAL,
              INVALID_ENDBLOCK,
              INVALID_SIDE,
              INVALID_NONCE,
              INVALID_QUOTE_EXPIRY_BLOCK,
              TOKEN_INSUFFICIENT_BALANCE,
              TOKEN_INSUFFICIENT_ALLOWANCE,
              MAX_RATE_PER_BLOCK_EXCEEDED,
              QUOTE_EXPIRED,
              LOAN_CONTRACT_NOT_FOUND,
              ASSET_NOT_SUPPORTED
  }

  /// @notice Emitted when a failure occurs
  event Failure(uint error);


  /// @notice Emits a failure and returns the error code. WARNING: This function 
  /// returns failure without reverting causing non-atomic transactions. Be sure
  /// you are using the checks-effects-interaction pattern properly with this.
  /// @param err Error code as enum
  /// @return uint Error code cast as uint
  function fail(Error err) internal returns (uint){
    emit Failure(uint(err));
    return uint(err);
  }
  
  /// @notice Emits a failure and returns the error code. WARNING: This function 
  /// returns failure without reverting causing non-atomic transactions. Be sure
  /// you are using the checks-effects-interaction pattern properly with this.
  /// @param err Error code as enum
  /// @return uint Error code cast as uint
  function fail(uint err) internal returns (uint) {
    emit Failure(err);
    return err;
  }
  
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/chainlink/AggregatorV3Interface.sol";
import "./interfaces/IERC20.sol";
import "./ErrorCode.sol";


contract QodaV1Controller is ErrorCode {

  using SafeMath for uint;

  address admin;
  
  struct Asset {
    bool isListed;
    address oracleFeed;
    // @notice mapping from account to whether it has collateral in this asset
    mapping(address => bool) accountMembership;
  }
  
  /// @notice Mapping from token address to its Asset
  mapping(address => Asset) public assets;
  
  /// @notice Mapping from account to collateral token address to collateral balance
  /// Use this for quick lookups of balances
  mapping(address => mapping(address => uint)) public accountBalances;

  /// @notice Mapping from account to list of token addresses which the account has
  /// collateral in. Use this when calculating total balances for liquidity considerations
  mapping(address => address[]) public accountAssets;

  constructor() public {
    admin = msg.sender;
  }

  //TODO: Need a better mechanism than this
  function addAsset(address tokenAddress, address _oracleFeed) public returns(uint){
    if(msg.sender != admin){
      fail(Error.UNAUTHORIZED);
    }
    
    Asset storage asset = assets[tokenAddress];
    asset.isListed = true;
    asset.oracleFeed = _oracleFeed;

    return uint(Error.NO_ERROR);
  }
  
  function depositCollateral(address tokenAddress, uint amount) external returns(uint){
    if(!_checkApproval(msg.sender, tokenAddress, amount)){
      return fail(Error.TOKEN_INSUFFICIENT_ALLOWANCE);
    }
    
    if(!_checkBalance(msg.sender, tokenAddress, amount)){
      return fail(Error.TOKEN_INSUFFICIENT_BALANCE);
    }
    
    Asset storage asset = assets[tokenAddress];

    if(!asset.isListed){
      return fail(Error.ASSET_NOT_SUPPORTED);
    }
    
    /// Record that the sender now has assets deposited for this token
    if(!asset.accountMembership[msg.sender]){
      accountAssets[msg.sender].push(tokenAddress);
      asset.accountMembership[msg.sender] = true;
    }

    _transferFrom(tokenAddress, msg.sender, address(this), amount);
    
    accountBalances[msg.sender][tokenAddress] += amount;

    return uint(Error.NO_ERROR);
  }


  /** USER INTERFACE **/
  function getAccountLiquidity(address account) external view returns(uint){
    return _getAccountLiquidity(account);
  }

  function getPriceFeed(address oracleFeed) external view returns(uint256, uint8){
    return _getPriceFeed(oracleFeed);
  }




  





  /// @notice Handles the transferFrom function for any token. Use requires here so that
  /// function reverts if any failure.
  /// @param tokenAddress Address of the token to transfer
  /// @param from Address of the sender
  /// @param to Adress of the receiver
  /// @param amount Amount of tokens to transfer
  function _transferFrom(
                        address tokenAddress,
                        address from,
                        address to,
                        uint amount
                        ) internal {
    //require(_checkApproval(tokenAddress, from, amount), "insufficient allowance");
    //require(_checkBalance(tokenAddress, from, amount), "insufficient balance");
    IERC20 token = IERC20(tokenAddress);
    token.transferFrom(from, to, amount);
  }
  

  /** INTERNAL FUNCTIONS **/
  

  function _getAccountLiquidity(address account) internal view returns(uint){
    uint value = 0;
    for(uint i=0; i<accountAssets[account].length; i++){
      
      // Get the token address in the i'th slot of `accountAssets[account]` array
      address tokenAddress = accountAssets[account][i];
      
      // Get the `Asset` struct associated to this token
      Asset storage asset = assets[tokenAddress];
      
      // Get the token balance of the account for the given `tokenAddress`
      uint balanceInLocal = accountBalances[account][tokenAddress];
      
      if(asset.oracleFeed == address(0)){
        //If oracleFeed = 0x000..., assume that the asset is USD
        value += balanceInLocal;
      }else {
        (uint exchangeRate, uint8 decimals) = _getPriceFeed(asset.oracleFeed);
        value += balanceInLocal.mul(exchangeRate).div(decimals);
      }
    }
    return value;
  }







  
  /// @notice Convenience function for getting price feed from Chainlink oracle
  /// @param oracleFeed Address of the chainlink oracle feed.
  /// @return answer uint256, decimals uint8
  function _getPriceFeed(address oracleFeed) internal view returns(uint256, uint8){
    AggregatorV3Interface aggregator = AggregatorV3Interface(oracleFeed);
    (, int256 answer,,,) =  aggregator.latestRoundData();
    uint8 decimals = aggregator.decimals();
    return (uint(answer), decimals);
  }






  










  /// @notice Verify if the user has enough token balance
  /// @param tokenAddress Address of the ERC20 token
  /// @param userAddress Address of the account to check
  /// @param amount Balance must be greater than or equal to this amount
  /// @return bool true if sufficient balance otherwise false
  function _checkBalance(
                         address tokenAddress,
                         address userAddress,
                         uint256 amount
                         ) internal view returns(bool){
    if(IERC20(tokenAddress).balanceOf(userAddress) >= amount) {
      return true;
    }
    return false;
  }

  /// @notice Verify if the user has approved the smart contract for spend
  /// @param userAddress Address of the account to check
  /// @param tokenAddress Address of the ERC20 token
  /// @param amount Allowance  must be greater than or equal to this amount
  /// @return bool true if sufficient allowance otherwise false
  function _checkApproval(
                          address tokenAddress,
                          address userAddress,
                          uint256 amount
                          ) internal view returns(bool) {
    if(IERC20(tokenAddress).allowance(userAddress, address(this)) > amount){
      return true;
    }
    return false;
  } 
}

pragma solidity ^0.8.9;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

pragma solidity ^0.8.9;

interface AggregatorV3Interface {
    /**
     * Returns the decimals to offset on the getLatestPrice call
     */
    function decimals() external view returns (uint8);

    /**
     * Returns the description of the underlying price feed aggregator
     */
    function description() external view returns (string memory);

    /**
     * Returns the version number representing the type of aggregator the proxy points to
     */
    function version() external view returns (uint256);

    /**
     * Returns price data about a specific round
     */
    function getRoundData(uint80 _roundId) external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);

    /**
     * Returns price data from the latest round
     */
    function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}