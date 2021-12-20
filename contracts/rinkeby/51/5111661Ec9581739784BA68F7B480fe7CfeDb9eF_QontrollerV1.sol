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

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/chainlink/AggregatorV3Interface.sol";
import "./interfaces/IEIP20.sol";
import "./libraries/QConst.sol";
import "./libraries/QTypes.sol";

contract QontrollerV1 {

  using SafeMath for uint;

  /// @notice Only admin may perform admin functions
  address public admin;

  /// @notice All enabled Assets
  /// tokenAddress => Asset
  mapping(address => QTypes.Asset) public assets;
  
  /// @notice Use this for quick lookups of balances by asset
  /// account => tokenAddress => balanceLocal
  mapping(address => mapping(address => uint)) public accountBalances;

  /// @notice Iterable list of all assets which an account has nonzero balance.
  /// Use this when calculating total balances for liquidity considerations
  /// account => tokenAddresses[]
  mapping(address => address[]) public accountAssets;
  
  constructor() public {
    admin = msg.sender;
  }




  /** ADMIN FUNCTIONS **/

  /// @notice Admin function for adding new Assets. An Asset must be added before it
  /// can be used as collateral.
  /// @param _tokenAddress Address of the token corresponding to the Asset
  /// @param _oracleFeed Chainlink price feed address
  /// @param _riskFactor Value from 0.0 to 1.0 (scaled to 1e8) for discounting risky assets
  function _addAsset(
                      address _tokenAddress,
                      address _oracleFeed,
                      uint _riskFactor
                      ) public {

    // Only `admin` may call this function
    require(msg.sender == admin, "unauthorized");

    // Cannot add the same asset twice
    require(!assets[_tokenAddress].isEnabled, "asset already exists");

    // Risk factor must be between .05 and .95
    require(_riskFactor > QConst.MIN_RISK_FACTOR &&
            _riskFactor < QConst.MAX_RISK_FACTOR,
            "invalid risk factor");

    // Initialize the Asset with the given parameters
    QTypes.Asset storage asset = assets[_tokenAddress];
    asset.isEnabled = true;
    asset.oracleFeed = _oracleFeed;
    asset.riskFactor = _riskFactor;
  }

  












  


  /** USER INTERFACE **/

  /// @notice Users call this to deposit collateral to fund their borrows
  /// @param tokenAddress Address of the token the collateral will be denominated in
  /// @param amount Amount to deposit (in local ccy)
  function depositCollateral(address tokenAddress, uint amount) external {

    // Sender must give approval to Qontroller for spend
    require(_checkApproval(tokenAddress, msg.sender, amount), "insufficient_allowance");
    
    // Sender must have enough balance for deposit
    require(_checkBalance(tokenAddress, msg.sender, amount), "insufficient balance");

    QTypes.Asset storage asset = assets[tokenAddress];

    // Only enabled assets are supported as collateral
    require(asset.isEnabled, "asset not supported");

    // Record that sender now has collateral deposited in this Asset
    if(!asset.accountMembership[msg.sender]){
      accountAssets[msg.sender].push(tokenAddress);
      asset.accountMembership[msg.sender] = true;
    }

    _transferFrom(tokenAddress, msg.sender, address(this), amount);

    accountBalances[msg.sender][tokenAddress] += amount;
  }

  /// @notice get the unweighted value (in USD) of all the collateral deposited
  /// for an account
  /// @param account Account to query
  /// @return uint Total value of account in USD
  function getTotalCollateralValue(address account) external view returns(uint){
    return _getTotalCollateralValue(account, false);
  }
  
  /// @notice get the `riskFactor` weighted value (in USD) of all the collateral
  /// deposited for an account
  /// @param account Account to query
  /// @return uint Total value of account in USD
  function getTotalCollateralValueWeighted(address account) external view returns(uint){
    return _getTotalCollateralValue(account, true);
  }
  
  /// @notice Convenience function for getting price feed from Chainlink oracle
  /// @param oracleFeed Address of the chainlink oracle feed.
  /// @return answer uint256, decimals uint8
  function getPriceFeed(address oracleFeed) external view returns(uint256, uint8){
    return _getPriceFeed(oracleFeed);
  }





  /** INTERNAL FUNCTIONS **/

  /// @notice Get the value (in USD) of all the collateral for an account. Can
  /// be weighted or unweighted.
  /// deposited for an account
  /// @param account Account to query
  /// @param applyRiskFactor True to get the `riskFactor` weighted value, false otherwise
  /// @return uint Total value of account in USD
  function _getTotalCollateralValue(
                                    address account,
                                    bool applyRiskFactor
                                    ) internal view returns(uint){
    uint totalValueUSD = 0;
    for(uint i=0; i<accountAssets[account].length; i++){

      // Get the token address in the i'th slot of the `accountAssets[account]` array
      address tokenAddress = accountAssets[account][i];

      totalValueUSD += _getCollateralValue(tokenAddress, account, applyRiskFactor);
    }
    return totalValueUSD;
  }

  /// @notice Get the value (in USD) of the collateral deposited for an account
  /// for a given `tokenAddress`. Can be weighted or unweighted.
  /// @param tokenAddress Address of ERC20 token
  /// @param account Account to query
  /// @param applyRiskFactor True to get the `riskFactor` weighted value, false otherwise
  /// @return uint Total value of account in USD
  function _getCollateralValue(
                               address tokenAddress,
                               address account,
                               bool applyRiskFactor
                               ) internal view returns(uint){
    
    // Get the `Asset` associated to this token
    QTypes.Asset storage asset = assets[tokenAddress];

    // Value of collateral in any unsupported `Asset` is zero
    if(!asset.isEnabled){
      return 0;
    }

    // Get the local balance of the account for the given `tokenAddress`
    uint balanceLocal = accountBalances[account][tokenAddress];
    
    // There are no oracles for stablecoin/USDC, so the oracle feed address
    // for that is assumed to be 0x000...Otherwise, convert the balance
    // from local to USD.
    if(asset.oracleFeed == address(0)){
      
      // valueLocal = valueUsd for stablecoins
      uint valueUSD = balanceLocal;
      
      if(applyRiskFactor){
        // Apply the risk factor to get the discounted value of the asset
        valueUSD = valueUSD.mul(asset.riskFactor).div(QConst.MANTISSA_RISK_FACTOR);
      }

      return valueUSD;
    }else {

      // Convert the local balance to USD
      uint valueUSD = _getValueUSD(tokenAddress, asset.oracleFeed, balanceLocal);

      if(applyRiskFactor){
        // Apply the risk factor to get the discounted value of the asset       
        valueUSD = valueUSD.mul(asset.riskFactor).div(QConst.MANTISSA_RISK_FACTOR);
      }
      
      return valueUSD;
    }
  }

  /// @notice Converts any local value into its value in USD using oracle feed price
  /// @param tokenAddress Address of the ERC20 token
  /// @param oracleFeed Address of the chainlink oracle feed
  /// @param valueLocal Amount, denominated in terms of the ERC20 token
  function _getValueUSD(
                          address tokenAddress,
                          address oracleFeed,
                          uint valueLocal
                          ) internal view returns(uint){
    
    IEIP20 token = IEIP20(tokenAddress);
    
    (uint exchRate, uint8 exchDecimals) = _getPriceFeed(oracleFeed);

    // Initialize all the necessary mantissas first
    uint exchRateMantissa = 10 ** exchDecimals;
    uint tokenMantissa = 10 ** token.decimals();

    // Convert `valueLocal` to USD
    uint valueUSD = valueLocal.mul(exchRate).mul(QConst.MANTISSA_STABLECOIN);

    // Divide by mantissas last for maximum precision
    valueUSD = valueUSD.div(tokenMantissa).div(exchRateMantissa);

    return valueUSD;
  }

  /// @notice Convenience function for getting price feed from Chainlink oracle
  /// @param oracleFeed Address of the chainlink oracle feed
  /// @return answer uint256, decimals uint8
  function _getPriceFeed(address oracleFeed) internal view returns(uint256, uint8){
    AggregatorV3Interface aggregator = AggregatorV3Interface(oracleFeed);
    (, int256 answer,,,) =  aggregator.latestRoundData();
    uint8 decimals = aggregator.decimals();
    return (uint(answer), decimals);
  }
  
  /// @notice Handles the transferFrom function for a token.
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
    require(_checkApproval(tokenAddress, from, amount), "insufficient allowance");
    require(_checkBalance(tokenAddress, from, amount), "insufficient balance");
    IEIP20 token = IEIP20(tokenAddress);
    token.transferFrom(from, to, amount);
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
    if(IEIP20(tokenAddress).balanceOf(userAddress) >= amount) {
      return true;
    }
    return false;
  }

  /// @notice Verify if the user has approved the smart contract for spend
  /// @param tokenAddress Address of the ERC20 token
  /// @param userAddress Address of the account to check
  /// @param amount Allowance  must be greater than or equal to this amount
  /// @return bool true if sufficient allowance otherwise false
  function _checkApproval(
                          address tokenAddress,
                          address userAddress,
                          uint256 amount
                          ) internal view returns(bool) {
    if(IEIP20(tokenAddress).allowance(userAddress, address(this)) > amount){
      return true;
    }
    return false;
  } 
}

pragma solidity ^0.8.9;

interface IEIP20 {
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

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library QConst {
  
  /// @notice Generic mantissa corresponding to ETH decimals
  uint internal constant MANTISSA_DEFAULT = 1e18;

  /// @notice Mantissa for stablecoins
  uint internal constant MANTISSA_STABLECOIN = 1e6;
  
  /// @notice `riskFactor` has up to 8 decimal places precision
  uint internal constant MANTISSA_RISK_FACTOR = 1e8;

  /// @notice `riskFactor` cannot be below .05
  uint internal constant MIN_RISK_FACTOR = .05e8;

  /// @notice `riskFactor` cannot be above .95
  uint internal constant MAX_RISK_FACTOR = .95e8;
  
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library QTypes {

  /// @notice Contains all the details of an Asset. Assets  must be defined
  /// before they can be used as collateral.
  /// @member isEnabled True if a asset is defined, false otherwise
  /// @member oracleFeed Address of the corresponding chainlink oracle feed
  /// @member riskFactor Value from 0.0 to 1.0 (scaled to 1e8) for discounting risky assets
  /// @member accountMembership account => (account has collateral in this asset?)
  struct Asset {
    bool isEnabled;
    address oracleFeed;
    uint riskFactor;
    mapping(address => bool) accountMembership;
  }
  
  /// @notice Contains all the fields of a FixedRateLoan agreement
  /// @member startTime Starting timestamp  when the loan is instantiated
  /// @member maturity Ending timestamp when the loan terminates
  /// @member principal Size of the loan
  /// @member principalPlusInterest Final amount that must be paid by borrower
  /// @member amountRepaid Current total amount repaid so far by borrower
  /// @member lender Account of the lender
  /// @member borrower Account of the borrower
  struct FixedRateLoan {
    uint startTime;
    uint maturity;
    uint principal;
    uint principalPlusInterest;
    uint amountRepaid;
    address lender;
    address borrower;
  }

  /// @notice Contains all the fields of a published Quote
  /// @param principalTokenAddress Address of token which the loan will be denominated
  /// @param quoter Account of the Quoter
  /// @param side 0 if Quoter is borrowing, 1 if Quoter is lending
  /// @param quoteExpiryTime Timestamp after which the quote is no longer valid
  /// @param maturity Ending timestamp when the loan terminates
  /// @param principal Initial size of the loan
  /// @param principalPlusInterest Final amount that must be paid by borrower
  /// @param nonce For uniqueness of signature
  /// @param signature signed hash of the Quote message
  struct Quote {
    address principalTokenAddress;
    address quoter;
    uint8 side;
    uint quoteExpiryTime;
    uint maturity;
    uint principal;
    uint principalPlusInterest;
    uint nonce;
    bytes signature;
  }
  
}