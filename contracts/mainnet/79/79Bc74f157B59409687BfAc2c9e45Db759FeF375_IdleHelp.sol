/**
 *Submitted for verification at Etherscan.io on 2019-07-11
*/

// File: contracts/interfaces/CERC20.sol

pragma solidity ^0.5.2;

interface CERC20 {
  function mint(uint256 mintAmount) external returns (uint256);
  function redeem(uint256 redeemTokens) external returns (uint256);
  function exchangeRateStored() external view returns (uint256);
  function supplyRatePerBlock() external view returns (uint256);
}

// File: contracts/interfaces/iERC20.sol

pragma solidity ^0.5.2;

interface iERC20 {
  function mint(
    address receiver,
    uint256 depositAmount)
    external
    returns (uint256 mintAmount);

  function burn(
    address receiver,
    uint256 burnAmount)
    external
    returns (uint256 loanAmountPaid);

  function tokenPrice()
    external
    view
    returns (uint256 price);

  function supplyInterestRate()
    external
    view
    returns (uint256);

  function claimLoanToken()
    external
    returns (uint256 claimedAmount);

  /* function burnToEther(
    address receiver,
    uint256 burnAmount)
    external
    returns (uint256 loanAmountPaid);


  function supplyInterestRate()
    external
    view
    returns (uint256);

  function assetBalanceOf(
    address _owner)
    external
    view
    returns (uint256);

  function claimLoanToken()
    external
    returns (uint256 claimedAmount); */
}

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * @dev Moves `amount` tokens from the caller&#39;s account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller&#39;s tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender&#39;s allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller&#39;s
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity&#39;s arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it&#39;s recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity&#39;s `+` operator.
     *
     * Requirements:
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
     * Counterpart to Solidity&#39;s `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity&#39;s `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
     * Counterpart to Solidity&#39;s `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity&#39;s `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: contracts/IdleHelp.sol

pragma solidity ^0.5.2;





library IdleHelp {
  using SafeMath for uint256;

  function getPriceInToken(address cToken, address iToken, address bestToken, uint256 totalSupply, uint256 poolSupply)
    public view
    returns (uint256 tokenPrice) {
      // 1Token = net_asset_value / total_Token_liquidity
      // net_asset_value = (rate of 1(cToken || iToken) in underlying_Token) * balanceOf((cToken || iToken))
      uint256 navPool;
      uint256 price;

      // rate
      if (bestToken == cToken) {
        // exchangeRateStored is the rate (in wei, 8 decimals) of 1cDAI in DAI * 10**18
        price = CERC20(cToken).exchangeRateStored(); // 202487304197710837666727644 ->
      } else {
        price = iERC20(iToken).tokenPrice(); // eg 1001495070730287403 -> 1iToken in wei = 1001495070730287403 Token
      }
      navPool = price.mul(poolSupply); // eg 43388429749999990000 in DAI
      tokenPrice = navPool.div(totalSupply); // idleToken price in token wei
  }
  function getAPRs(address cToken, address iToken, uint256 blocksInAYear)
    public view
    returns (uint256 cApr, uint256 iApr) {
      uint256 cRate = CERC20(cToken).supplyRatePerBlock(); // interest % per block
      cApr = cRate.mul(blocksInAYear).mul(100);
      iApr = iERC20(iToken).supplyInterestRate(); // APR in wei 18 decimals
  }
  function getBestRateToken(address cToken, address iToken, uint256 blocksInAYear)
    public view
    returns (address bestRateToken, uint256 bestRate, uint256 worstRate) {
      (uint256 cApr, uint256 iApr) = getAPRs(cToken, iToken, blocksInAYear);
      bestRateToken = cToken;
      bestRate = cApr;
      worstRate = iApr;
      if (iApr > cApr) {
        worstRate = cApr;
        bestRate = iApr;
        bestRateToken = iToken;
      }
  }
  function rebalanceCheck(address cToken, address iToken, address bestToken, uint256 blocksInAYear, uint256 minRateDifference)
    public view
    returns (bool shouldRebalance, address bestTokenAddr) {
      shouldRebalance = false;

      uint256 _bestRate;
      uint256 _worstRate;
      (bestTokenAddr, _bestRate, _worstRate) = getBestRateToken(cToken, iToken, blocksInAYear);
      if (
          bestToken == address(0) ||
          (bestTokenAddr != bestToken && (_worstRate.add(minRateDifference) < _bestRate))) {
        shouldRebalance = true;
        return (shouldRebalance, bestTokenAddr);
      }

      return (shouldRebalance, bestTokenAddr);
  }
}