// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./Pipe.sol";
import "./../../../../third_party/qidao/IErc20Stablecoin.sol";
import "../../../interface/IMaiStablecoinPipe.sol";

/// @title Mai Stablecoin Pipe Contract
/// @author bogdoslav
contract MaiStablecoinPipe is Pipe, IMaiStablecoinPipe {
  using SafeERC20 for IERC20;

  struct MaiStablecoinPipeData {
    address sourceToken;
    address stablecoin; //Erc20Stablecoin contract address
    // borrowing
    address borrowToken; // mai (miMATIC) for example
    uint256 targetPercentage; // Collateral to Debt target percentage
    uint256 maxImbalance;     // Maximum Imbalance in percents
    address rewardToken;
    uint256 collateralNumerator; // 1 for all tokens except 10*10 for WBTC erc20Stablecoin-cam-wbtc.sol at mai-qidao as it have only 8 decimals
  }

  MaiStablecoinPipeData public pipeData;
  IErc20Stablecoin private _stablecoin;
  uint256 private vaultID;

  event Rebalanced(uint256 borrowed, uint256 repaid);
  event Borrowed(uint256 amount);
  event Repaid(uint256 amount);

  constructor(MaiStablecoinPipeData memory _d) Pipe(
    'MaiStablecoinPipe',
    _d.sourceToken,
    _d.borrowToken
  ) {
    require(_d.stablecoin != address(0), "Zero stablecoin");
    require(_d.rewardToken != address(0), "Zero reward token");

    pipeData = _d;
    rewardTokens.push(_d.rewardToken);
    _stablecoin = IErc20Stablecoin(pipeData.stablecoin);
    vaultID = IErc20Stablecoin(pipeData.stablecoin).createVault();
  }


  // ***************************************
  // ************** EXTERNAL VIEWS *********
  // ***************************************

  /// @dev Gets available MAI (miMATIC) to borrow at the Mai Stablecoin contract.
  /// @return miMatic borrow token Stablecoin supply
  function availableMai() external view override returns (uint256) {
    return IERC20(pipeData.borrowToken).balanceOf(address(_stablecoin));
  }

  /// @dev Returns price of source token (cam), when vault will be liquidated, based on _minimumCollateralPercentage
  ///      collateral to debt percentage. Returns 0 when no debt or collateral
  function liquidationPrice()
  external view override returns (uint256 price) {
    uint256 borrowedAmount = _stablecoin.vaultDebt(vaultID);
    if (borrowedAmount == 0) {
      return 0;
    }
    uint256 collateral = _stablecoin.vaultCollateral(vaultID);
    if (collateral == 0) {
      return 0;
    }
    uint256 tokenPriceSource = _stablecoin.getTokenPriceSource();
    price = (borrowedAmount * tokenPriceSource * _stablecoin._minimumCollateralPercentage())
    / (collateral * 100 * pipeData.collateralNumerator);
  }

  /// @dev Returns maximal possible deposit of amToken, based on available mai and target percentage.
  /// @return max camToken maximum deposit
  function maxDeposit() external view override returns (uint256 max) {
    uint256 _availableMai = IERC20(pipeData.borrowToken).balanceOf(address(_stablecoin));
    uint256 tokenPriceSource = _stablecoin.getTokenPriceSource();
    uint256 amPrice = _stablecoin.getEthPriceSource();
    max = _availableMai * tokenPriceSource * pipeData.targetPercentage / (amPrice * 100 * pipeData.collateralNumerator);
  }

  /// @dev Gets targetPercentage
  /// @return target collateral to debt percentage
  function targetPercentage() external view override returns (uint256) {
    return pipeData.targetPercentage;
  }

  /// @dev Gets maxImbalance
  /// @return maximum imbalance (+/-%) to do re-balance
  function maxImbalance() external view override returns (uint256) {
    return pipeData.maxImbalance;
  }

  /// @dev Gets collateralPercentage
  /// @return current collateral to debt percentage
  function collateralPercentage() external view override returns (uint256) {
    return _stablecoin.checkCollateralPercentage(vaultID);
  }

  /// @dev Returns true when rebalance needed
  function needsRebalance() override external view returns (bool){
    uint256 currentPercentage = _stablecoin.checkCollateralPercentage(vaultID);
    if (currentPercentage == 0) {
      // no debt or collateral
      return false;
    }
    return ((currentPercentage + pipeData.maxImbalance) < pipeData.targetPercentage)
    || (currentPercentage > (uint256(pipeData.targetPercentage) + pipeData.maxImbalance));
  }

  // ***************************************
  // ************** EXTERNAL ***************
  // ***************************************


  /// @dev Sets maxImbalance
  /// @param _maxImbalance - maximum imbalance deviation (+/-%)
  function setMaxImbalance(uint256 _maxImbalance) onlyPipeline override external {
    pipeData.maxImbalance = _maxImbalance;
  }

  /// @dev Sets targetPercentage
  /// @param _targetPercentage - target collateral to debt percentage
  function setTargetPercentage(uint256 _targetPercentage) onlyPipeline override external {
    pipeData.targetPercentage = _targetPercentage;
  }

  /// @dev function for depositing to collateral then borrowing
  /// @param amount in source units
  /// @return output in underlying units
  function put(uint256 amount) override onlyPipeline external returns (uint256 output) {
    amount = maxSourceAmount(amount);
    if (amount != 0) {
      depositCollateral(amount);
      uint256 borrowAmount = _canSafelyBorrowMore();
      borrow(borrowAmount);
    }
    output = _erc20Balance(outputToken);
    _transferERC20toNextPipe(pipeData.borrowToken, output);
    emit Put(amount, output);
  }

  /// @dev function for repaying debt then withdrawing from collateral
  /// @param amount in underlying units
  /// @return output in source units
  function get(uint256 amount) override onlyPipeline external returns (uint256 output) {
    amount = maxOutputAmount(amount);
    if (amount != 0) {
      uint256 debt = _stablecoin.vaultDebt(vaultID);
      repay(amount);
      // repay subtracts fee from the collateral, so we get collateral after fees applied
      uint256 collateral = _stablecoin.vaultCollateral(vaultID);
      uint256 debtAfterRepay = _stablecoin.vaultDebt(vaultID);

      uint256 withdrawAmount = (debtAfterRepay == 0)
        ? collateral
        : (amount * collateral) / debt;
      withdrawCollateral(withdrawAmount);
    }
    output = _erc20Balance(sourceToken);
    _transferERC20toPrevPipe(sourceToken, output);
    emit Get(amount, output);

  }

  /// @dev function for re balancing. When rebalance
  /// @return imbalance in underlying units
  /// @return deficit - when true, then asks to receive underlying imbalance amount, when false - put imbalance to next pipe,
  function rebalance() override onlyPipeline
  external returns (uint256 imbalance, bool deficit) {
    uint256 currentPercentage = _stablecoin.checkCollateralPercentage(vaultID);
    if (currentPercentage == 0) {
      // no debt or collateral
      return (0, false);
    }

    if ((currentPercentage + pipeData.maxImbalance) < pipeData.targetPercentage) {
      // we have deficit
      uint256 targetBorrow = _canSafelyBorrowTotal();
      uint256 debt = _stablecoin.vaultDebt(vaultID);
      uint256 repayAmount = debt - targetBorrow;

      uint256 available = _erc20Balance(pipeData.borrowToken);
      uint256 paidAmount = Math.min(repayAmount, available);
      if (paidAmount > 0) {
        repay(paidAmount);
      }

      uint256 change = _erc20Balance(pipeData.borrowToken);
      if (change > 0) {
        _transferERC20toNextPipe(pipeData.borrowToken, change);
        return (change, false);
      } else {
        return (repayAmount - paidAmount, true);
      }

    } else if (currentPercentage > (uint256(pipeData.targetPercentage) + pipeData.maxImbalance)) {
      // we have excess
      uint256 targetBorrow = _canSafelyBorrowTotal();
      uint256 debt = _stablecoin.vaultDebt(vaultID);
      if (debt < targetBorrow) {
        borrow(targetBorrow - debt);
      }
      uint256 excess = _erc20Balance(pipeData.borrowToken);
      _transferERC20toNextPipe(pipeData.borrowToken, excess);
      return (excess, false);
    }

    return (0, false);
    // in balance
  }

  // ***************************************
  // ************** PRIVATE VIEWS **********
  // ***************************************

  /// @dev base function for all calculations below is: (each side in borrow token price * 100)
  /// collateral * collateralNumerator * ethPrice * 100 = borrow * tokenPrice * percentage

  /// @dev Returns how much we can safely borrow total (based on percentage)
  /// @return borrowAmount amount of borrow token for target percentage
  function _canSafelyBorrowTotal()
  private view returns (uint256 borrowAmount) {
    uint256 collateral = _stablecoin.vaultCollateral(vaultID);
    if (collateral == 0) {
      return 0;
    }

    uint256 ethPrice = _stablecoin.getEthPriceSource();
    uint256 tokenPriceSource = _stablecoin.getTokenPriceSource();
    if (pipeData.targetPercentage == 0 || tokenPriceSource == 0) {
      borrowAmount = 0;
    } else {
      borrowAmount = (collateral * pipeData.collateralNumerator * ethPrice * 100)
      / (tokenPriceSource * pipeData.targetPercentage);
    }
  }

  /// @dev Returns how much more we can safely borrow (based on percentage)
  function _canSafelyBorrowMore()
  private view returns (uint256) {
    uint256 canBorrowTotal = _canSafelyBorrowTotal();
    uint256 borrowed = _stablecoin.vaultDebt(vaultID);

    if (borrowed >= canBorrowTotal) {
      return 0;
    } else {
      return canBorrowTotal - borrowed;
    }
  }

  // ***************************************
  // ************** PRIVATE ****************
  // ***************************************

  /// @dev function for investing, deposits, entering, borrowing
  /// @param amount in source units
  function depositCollateral(uint256 amount) private {
    if (amount != 0) {
      _erc20Approve(pipeData.sourceToken, pipeData.stablecoin, amount);
      _stablecoin.depositCollateral(vaultID, amount);
    }
  }

  /// @dev function for de-vesting, withdrawals, leaves, paybacks
  /// @param amount in underlying units
  function withdrawCollateral(uint256 amount) private {
    if (amount != 0) {
      _stablecoin.withdrawCollateral(vaultID, amount);
    }
  }

  /// @dev Borrow tokens
  /// @param amount to borrow in underlying units
  function borrow(uint256 amount) private {
    if (amount != 0) {
      _stablecoin.borrowToken(vaultID, amount);
      emit Borrowed(amount);
    }
  }

  /// @dev Repay borrowed tokens
  /// @param amount in borrowed tokens
  /// @return repaid in borrowed tokens
  function repay(uint256 amount) private returns (uint256) {
    uint256 repayAmount = Math.min(amount, _stablecoin.vaultDebt(vaultID));
    if (repayAmount != 0) {
      _erc20Approve(pipeData.borrowToken, pipeData.stablecoin, repayAmount);
      _stablecoin.payBackToken(vaultID, repayAmount);
    }
    emit Repaid(repayAmount);
    return repayAmount;
  }

}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../../interface/IPipe.sol";
import "./PipeLib.sol";

/// @title Pipe Base Contract
/// @author bogdoslav
abstract contract Pipe is IPipe {
  using SafeERC20 for IERC20;

  /// @notice Address of the master pipeline
  /// @dev After adding the pipe to a pipeline it should be immediately initialized
  address public override pipeline = address(0);

  /// @notice Pipe name for statistical purposes only
  /// @dev initialize it in constructor
  string public override name;
  /// @notice Source token address type
  /// @dev initialize it in constructor, for ether (bnb, matic) use _ETHER
  address public immutable override sourceToken;
  /// @notice Output token address type
  /// @dev initialize it in constructor, for ether (bnb, matic) use _ETHER
  address public immutable override outputToken;

  /// @notice Reward token address for claiming
  /// @dev initialize it in constructor
  address[] public override rewardTokens;

  /// @notice Next pipe in pipeline
  address public override prevPipe;
  /// @notice Previous pipe in pipeline
  address public override nextPipe;

  event Get(uint256 amount, uint256 output);
  event Put(uint256 amount, uint256 output);

  constructor (
    string memory _name,
    address _sourceToken,
    address _outputToken
  ) {
    require(_sourceToken != address(0), "Zero source token");
    require(_outputToken != address(0), "Zero output token");

    name = _name;
    sourceToken = _sourceToken;
    outputToken = _outputToken;
  }

  modifier onlyPipeline() {
    require(
      pipeline == msg.sender || pipeline == address(this),
      "PIPE: caller is not the pipeline"
    );
    _;
  }

  /// @dev Replaces MAX constant to source token balance. Should be used at put() function start
  function maxSourceAmount(uint256 amount) internal view returns (uint256) {
    if (amount == PipeLib.MAX_AMOUNT) {
      return sourceBalance();
    } else {
      return amount;
    }
  }

  /// @dev Replaces MAX constant to output token balance. Should be used at get() function start
  function maxOutputAmount(uint256 amount) internal view returns (uint256) {
    if (amount == PipeLib.MAX_AMOUNT) {
      return outputBalance();
    } else {
      return amount;
    }
  }

  /// @dev After adding the pipe to a pipeline it should be immediately initialized
  function setPipeline(address _pipeline) external override {
    require(pipeline == address(0), "PIPE: Already init");
    pipeline = _pipeline;
  }

  /// @dev Size of reward tokens array
  function rewardTokensLength() external view override returns (uint) {
    return rewardTokens.length;
  }

  /// @dev function for investing, deposits, entering, borrowing
  /// @param _nextPipe - next pipe in pipeline
  function setNextPipe(address _nextPipe) onlyPipeline override external {
    nextPipe = _nextPipe;
  }

  /// @dev function for investing, deposits, entering, borrowing
  /// @param _prevPipe - next pipe in pipeline
  function setPrevPipe(address _prevPipe) onlyPipeline override external {
    prevPipe = _prevPipe;
  }

  /// @dev function for investing, deposits, entering, borrowing. Do not forget to transfer assets to next pipe
  /// @dev In almost all cases overrides should have maxSourceAmount(amount)modifier
  /// @param amount in source units
  /// @return output in underlying units
  function put(uint256 amount) virtual override external returns (uint256 output);

  /// @dev function for de-vesting, withdrawals, leaves, paybacks. Amount in underlying units. Do not forget to transfer assets to prev pipe
  /// @dev In almost all cases overrides should have maxOutputAmount(amount)modifier
  /// @param amount in underlying units
  /// @return output in source units
  function get(uint256 amount) virtual override external returns (uint256 output);

  /// @dev function for re balancing. Mark it as onlyPipeline when override
  /// @return imbalance in underlying units
  /// @return deficit - when true, then ask to receive underlying imbalance amount, when false - put imbalance to next pipe,
  function rebalance() virtual override external returns (uint256 imbalance, bool deficit) {
    // balanced, no deficit by default
    return (0, false);
  }

  /// @dev Returns true when rebalance needed
  function needsRebalance() virtual override external view returns (bool){
    // balanced, no deficit by default
    return false;
  }

  /// @dev function for claiming rewards
  function claim() onlyPipeline virtual override external {
    for (uint i = 0; i < rewardTokens.length; i++) {
      address rewardToken = rewardTokens[i];
      if (rewardToken == address(0)) {
        return;
      }
      require(pipeline != address(0));

      uint256 amount = _erc20Balance(rewardToken);
      if (amount > 0) {
        IERC20(rewardToken).safeTransfer(pipeline, amount);
      }
    }
  }

  /// @dev available source balance (tokens, matic etc).
  /// @return balance in source units
  function sourceBalance() public view virtual override returns (uint256) {
    return _erc20Balance(sourceToken);
  }

  /// @dev underlying balance (LP tokens, collateral etc).
  /// @return balance in underlying units
  function outputBalance() public view virtual override returns (uint256) {
    return _erc20Balance(outputToken);
  }

  /// @notice Pipeline can claim coins that are somehow transferred into the contract
  /// @param recipient Recipient address
  /// @param recipient Token address
  function salvageFromPipe(address recipient, address token) external virtual override onlyPipeline {
    // To make sure that governance cannot come in and take away the coins
    // checking first and last pipes only to have ability salvage tokens from inside pipeline
    if ((!hasPrevPipe() || !hasNextPipe())
      && (sourceToken == token || outputToken == token)) {
      return;
    }

    uint256 amount = _erc20Balance(token);
    if (amount > 0) {
      IERC20(token).safeTransfer(recipient, amount);
    }
  }

  // ***************************************
  // ************** INTERNAL HELPERS *******
  // ***************************************

  /// @dev Checks is pipe have next pipe connected
  /// @return true when connected
  function hasNextPipe() internal view returns (bool) {
    return nextPipe != address(0);
  }

  /// @dev Checks is pipe have previous pipe connected
  /// @return true when connected
  function hasPrevPipe() internal view returns (bool) {
    return prevPipe != address(0);
  }

  /// @dev Transfers ERC20 token to next pipe when its exists
  /// @param _token ERC20 token address
  /// @param amount to transfer
  function _transferERC20toNextPipe(address _token, uint256 amount) internal {
    if (amount != 0 && hasNextPipe()) {
      IERC20(_token).safeTransfer(nextPipe, amount);
    }
  }

  /// @dev Transfers ERC20 token to previous pipe when its exists
  /// @param _token ERC20 token address
  /// @param amount to transfer
  function _transferERC20toPrevPipe(address _token, uint256 amount) internal {
    if (amount != 0 && hasPrevPipe()) {
      IERC20(_token).safeTransfer(prevPipe, amount);
    }
  }

  /// @dev returns ERC20 token balance
  /// @param _token ERC20 token address
  /// @return balance for address(this)
  function _erc20Balance(address _token) internal view returns (uint256){
    return IERC20(_token).balanceOf(address(this));
  }

  /// @dev Approve to spend ERC20 token amount for spender
  /// @param _token ERC20 token address
  /// @param spender address
  /// @param amount to spend
  function _erc20Approve(address _token, address spender, uint256 amount) internal {
    IERC20(_token).safeApprove(spender, 0);
    IERC20(_token).safeApprove(spender, amount);
  }

}

// SPDX-License-Identifier: ISC
//https://github.com/0xlaozi/qidao/blob/main/contracts/erc20Stablecoin/erc20Stablecoin.sol
pragma solidity 0.8.4;

interface IErc20Stablecoin {
//    PriceSource external ethPriceSource;
    function ethPriceSource() external view returns (address);
//
//    uint256 external _minimumCollateralPercentage;
    function _minimumCollateralPercentage() external view returns (uint256);
//    uint256 external vaultCount;
//    uint256 external closingFee;
    function closingFee() external view returns (uint256);
//    uint256 external openingFee;
    function openingFee() external view returns (uint256);
//
//    uint256 external treasury;
//    uint256 external tokenPeg;
//
//    mapping(uint256 => uint256) external vaultCollateral;
    function vaultCollateral(uint256 vaultID) external view returns (uint256);
//    mapping(uint256 => uint256) external vaultDebt;
    function vaultDebt(uint256 vaultID) external view returns (uint256);
//
//    uint256 external debtRatio;
//    uint256 external gainRatio;
//
//    address external stabilityPool;
//
//    ERC20Detailed external collateral;
    function collateral() external view returns (address);
//
//    ERC20Detailed external mai;
    function mai() external view returns (address);
//
//    uint8 external priceSourceDecimals;

//    mapping(address => uint256) external maticDebt;


    function getDebtCeiling() external view returns (uint256);

    function exists(uint256 vaultID) external view returns (bool);

    function getClosingFee() external view returns (uint256);

    function getOpeningFee() external view returns (uint256);

    function getTokenPriceSource() external view returns (uint256);

    function getEthPriceSource() external view returns (uint256);

    function createVault() external returns (uint256);

    function destroyVault(uint256 vaultID) external;

    function depositCollateral(uint256 vaultID, uint256 amount) external;

    function withdrawCollateral(uint256 vaultID, uint256 amount) external;

    function borrowToken(uint256 vaultID, uint256 amount) external;

    function payBackToken(uint256 vaultID, uint256 amount) external;

    function getPaid() external;

    function checkCost(uint256 vaultID) external view returns (uint256);

    function checkExtract(uint256 vaultID) external view returns (uint256);

    function checkCollateralPercentage(uint256 vaultID) external view returns(uint256);

    function checkLiquidation(uint256 vaultID) external view returns (bool);

    function liquidateVault(uint256 vaultID) external;

    function ownerOf(uint256 vaultID) external view returns (address);
}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IMaiStablecoinPipe {

  function setMaxImbalance(uint256 _maxImbalance) external;

  function maxImbalance() external view returns (uint256);

  function setTargetPercentage(uint256 _targetPercentage) external;

  function targetPercentage() external view returns (uint256);

  function collateralPercentage() external view returns (uint256);

  function liquidationPrice() external view returns (uint256);

  function availableMai() external view returns (uint256);

  function maxDeposit() external view returns (uint256);

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

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

interface IPipe {

  function pipeline() external view returns (address);

  function name() external view returns (string memory);

  function sourceToken() external view returns (address);

  function outputToken() external view returns (address);

  function rewardTokens(uint index) external view returns (address);

  function rewardTokensLength() external view returns (uint);

  function prevPipe() external view returns (address);

  function nextPipe() external view returns (address);

  function setPipeline(address _pipeline) external;

  function setNextPipe(address _nextPipe) external;

  function setPrevPipe(address _prevPipe) external;

  function put(uint256 amount) external returns (uint256 output);

  function get(uint256 amount) external returns (uint256 output);

  function rebalance() external returns (uint256 imbalance, bool deficit);

  function needsRebalance() external view returns (bool);

  function claim() external;

  function sourceBalance() external view returns (uint256);

  function outputBalance() external view returns (uint256);

  function salvageFromPipe(address recipient, address token) external;

}

// SPDX-License-Identifier: ISC
/**
* By using this software, you understand, acknowledge and accept that Tetu
* and/or the underlying software are provided “as is” and “as available”
* basis and without warranties or representations of any kind either expressed
* or implied. Any use of this open source software released under the ISC
* Internet Systems Consortium license is done at your own risk to the fullest
* extent permissible pursuant to applicable law any and all liability as well
* as all warranties, including any fitness for a particular purpose with respect
* to Tetu and/or the underlying software and the use thereof are disclaimed.
*/

pragma solidity 0.8.4;

library PipeLib {

  /// @dev Constant value to get or put all available token amount
  uint256 public constant MAX_AMOUNT = type(uint).max;

}