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

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import './libraries/WadRayMath.sol';
import './libraries/Math.sol';
import './libraries/Errors.sol';
import './interfaces/IDToken.sol';
import './interfaces/IMoneyPool.sol';
import '@openzeppelin/contracts/utils/Context.sol';

/**
 * @title DToken
 * @notice The DToken balance of borrower is the amount of money that the borrower
 * would be required to repay and seize the collateralized asset bond token.
 *
 * @author Aave
 **/
contract DToken is IDToken, Context {
  using WadRayMath for uint256;

  uint256 internal _totalAverageRealAssetBorrowRate;
  mapping(address => uint256) internal _userLastUpdateTimestamp;
  mapping(address => uint256) internal _userAverageRealAssetBorrowRate;
  uint256 internal _lastUpdateTimestamp;

  uint256 internal _totalSupply;
  mapping(address => uint256) internal _balances;

  string private _name;
  string private _symbol;

  IMoneyPool internal _moneyPool;
  address internal _underlyingAsset;

  constructor(
    IMoneyPool moneyPool,
    address underlyingAsset_,
    string memory name_,
    string memory symbol_
  ) {
    _moneyPool = moneyPool;
    _underlyingAsset = underlyingAsset_;

    _name = name_;
    _symbol = symbol_;
  }

  /**
   * @dev Returns the name of the token.
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev Returns the symbol of the token, usually a shorter version of the
   * name.
   */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev Returns the decimals of the token.
   */
  function decimals() public view virtual override returns (uint8) {
    return 18;
  }

  function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
    recipient;
    amount;
    revert TokenErrors.DTokenTransferNotAllowed();
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) public virtual override returns (bool) {
    sender;
    recipient;
    amount;
    revert TokenErrors.DTokenTransferFromNotAllowed();
  }

  function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
  {
    owner;
    spender;
    revert TokenErrors.DTokenAllowanceNotAllowed();
  }

  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    spender;
    amount;
    revert TokenErrors.DTokenApproveNotAllowed();
  }

  /**
   * @dev Returns the average stable rate across all the stable rate debt
   * @return the average stable rate
   **/
  function getTotalAverageRealAssetBorrowRate() external view virtual override returns (uint256) {
    return _totalAverageRealAssetBorrowRate;
  }

  /**
   * @dev Returns the timestamp of the last account action
   * @return The last update timestamp
   **/
  function getUserLastUpdateTimestamp(address account)
    external
    view
    virtual
    override
    returns (uint256)
  {
    return _userLastUpdateTimestamp[account];
  }

  /**
   * @dev Returns the stable rate of the account
   * @param account The address of the account
   * @return The stable rate of account
   **/
  function getUserAverageRealAssetBorrowRate(address account)
    external
    view
    virtual
    override
    returns (uint256)
  {
    return _userAverageRealAssetBorrowRate[account];
  }

  /**
   * @dev Calculates the current account debt balance
   * @return The accumulated debt of the account
   **/
  function balanceOf(address account) public view virtual override returns (uint256) {
    uint256 accountBalance = _balances[account];
    uint256 stableRate = _userAverageRealAssetBorrowRate[account];
    if (accountBalance == 0) {
      return 0;
    }
    uint256 cumulatedInterest = Math.calculateCompoundedInterest(
      stableRate,
      _userLastUpdateTimestamp[account],
      block.timestamp
    );
    return accountBalance.rayMul(cumulatedInterest);
  }

  struct MintLocalVars {
    uint256 previousSupply;
    uint256 nextSupply;
    uint256 amountInRay;
    uint256 newStableRate;
    uint256 currentAvgStableRate;
  }

  /**
   * @dev Mints debt token to the `receiver` address.
   * -  Only callable by the LendingPool
   * - The resulting rate is the weighted average between the rate of the new debt
   * and the rate of the principal debt
   * @param account The address receiving the borrowed underlying, being the delegatee in case
   * of credit delegate, or same as `receiver` otherwise
   * @param receiver The address receiving the debt tokens
   * @param amount The amount of debt tokens to mint
   * @param rate The rate of the debt being minted
   **/
  function mint(
    address account,
    address receiver,
    uint256 amount,
    uint256 rate
  ) external override onlyMoneyPool returns (bool) {
    MintLocalVars memory vars;

    (, uint256 currentBalance, uint256 balanceIncrease) = _calculateBalanceIncrease(receiver);

    vars.previousSupply = totalSupply();
    vars.currentAvgStableRate = _totalAverageRealAssetBorrowRate;
    vars.nextSupply = _totalSupply = vars.previousSupply + amount;

    vars.amountInRay = amount.wadToRay();

    (, vars.newStableRate) = Math.calculateRateInIncreasingBalance(
      _userAverageRealAssetBorrowRate[receiver],
      currentBalance,
      amount,
      rate
    );

    _userAverageRealAssetBorrowRate[receiver] = vars.newStableRate;

    //solium-disable-next-line
    _lastUpdateTimestamp = _userLastUpdateTimestamp[receiver] = block.timestamp;

    // Calculates the updated average stable rate
    (, vars.currentAvgStableRate) = Math.calculateRateInIncreasingBalance(
      vars.currentAvgStableRate,
      vars.previousSupply,
      amount,
      rate
    );

    _totalAverageRealAssetBorrowRate = vars.currentAvgStableRate;

    _mint(receiver, amount + balanceIncrease);

    emit Transfer(address(0), receiver, amount);

    emit Mint(
      account,
      receiver,
      amount + balanceIncrease,
      currentBalance,
      balanceIncrease,
      vars.newStableRate,
      vars.currentAvgStableRate,
      vars.nextSupply
    );

    return currentBalance == 0;
  }

  /**
   * @dev Burns debt of `account`
   * @param account The address of the account getting his debt burned
   * @param amount The amount of debt tokens getting burned
   **/
  function burn(address account, uint256 amount) external override onlyMoneyPool {
    (, uint256 currentBalance, uint256 balanceIncrease) = _calculateBalanceIncrease(account);

    uint256 previousSupply = totalSupply();
    uint256 newAvgStableRate = 0;
    uint256 nextSupply = 0;
    uint256 userStableRate = _userAverageRealAssetBorrowRate[account];

    // Since the total supply and each single account debt accrue separately,
    // there might be accumulation errors so that the last borrower repaying
    // mght actually try to repay more than the available debt supply.
    // In this case we simply set the total supply and the avg stable rate to 0
    if (previousSupply <= amount) {
      _totalAverageRealAssetBorrowRate = 0;
      _totalSupply = 0;
    } else {
      nextSupply = _totalSupply = previousSupply - amount;
      uint256 firstTerm = _totalAverageRealAssetBorrowRate.rayMul(previousSupply.wadToRay());
      uint256 secondTerm = userStableRate.rayMul(amount.wadToRay());

      // For the same reason described above, when the last account is repaying it might
      // happen that account rate * account balance > avg rate * total supply. In that case,
      // we simply set the avg rate to 0
      if (secondTerm >= firstTerm) {
        newAvgStableRate = _totalAverageRealAssetBorrowRate = _totalSupply = 0;
      } else {
        newAvgStableRate = _totalAverageRealAssetBorrowRate = (firstTerm - secondTerm).rayDiv(
          nextSupply.wadToRay()
        );
      }
    }

    if (amount == currentBalance) {
      _userAverageRealAssetBorrowRate[account] = 0;
      _userLastUpdateTimestamp[account] = 0;
    } else {
      //solium-disable-next-line
      _userLastUpdateTimestamp[account] = block.timestamp;
    }
    //solium-disable-next-line
    _lastUpdateTimestamp = block.timestamp;

    if (balanceIncrease > amount) {
      uint256 amountToMint = balanceIncrease - amount;
      _mint(account, amountToMint);
      emit Mint(
        account,
        account,
        amountToMint,
        currentBalance,
        balanceIncrease,
        userStableRate,
        newAvgStableRate,
        nextSupply
      );
    } else {
      uint256 amountToBurn = amount - balanceIncrease;
      _burn(account, amountToBurn);
      emit Burn(
        account,
        amountToBurn,
        currentBalance,
        balanceIncrease,
        newAvgStableRate,
        nextSupply
      );
    }

    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev Calculates the increase in balance since the last account interaction
   * @param account The address of the account for which the interest is being accumulated
   * @return The principal principal balance, the new principal balance and the balance increase
   **/
  function _calculateBalanceIncrease(address account)
    internal
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    uint256 previousPrincipalBalance = _balances[account];

    if (previousPrincipalBalance == 0) {
      return (0, 0, 0);
    }

    // Calculation of the accrued interest since the last accumulation
    uint256 balanceIncrease = balanceOf(account) - previousPrincipalBalance;

    return (previousPrincipalBalance, previousPrincipalBalance + balanceIncrease, balanceIncrease);
  }

  /**
   * @dev Returns the principal and total supply, the average borrow rate and the last supply update timestamp
   **/
  function getDTokenData()
    public
    view
    override
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    uint256 avgRate = _totalAverageRealAssetBorrowRate;
    return (_totalSupply, _calcTotalSupply(avgRate), avgRate, _lastUpdateTimestamp);
  }

  /**
   * @dev Returns the the total supply and the average stable rate
   **/
  function getTotalSupplyAndAvgRate() public view override returns (uint256, uint256) {
    uint256 avgRate = _totalAverageRealAssetBorrowRate;
    return (_calcTotalSupply(avgRate), avgRate);
  }

  /**
   * @dev Returns the total supply
   **/
  function totalSupply() public view override returns (uint256) {
    return _calcTotalSupply(_totalAverageRealAssetBorrowRate);
  }

  /**
   * @dev Returns the timestamp at which the total supply was updated
   **/
  function getTotalSupplyLastUpdated() public view override returns (uint256) {
    return _lastUpdateTimestamp;
  }

  /**
   * @dev Returns the principal debt balance of the account from
   * @param account The account's address
   * @return The debt balance of the account since the last burn/mint action
   **/
  function principalBalanceOf(address account) external view virtual override returns (uint256) {
    return _balances[account];
  }

  /**
   * @dev Returns the address of the lending pool where this aToken is used
   **/
  function POOL() public view returns (IMoneyPool) {
    return _moneyPool;
  }

  /**
   * @dev For internal usage in the logic of the parent contracts
   **/
  function _getMoneyPool() internal view returns (IMoneyPool) {
    return _moneyPool;
  }

  /**
   * @dev Calculates the total supply
   * @param avgRate The average rate at which the total supply increases
   * @return The debt balance of the account since the last burn/mint action
   **/
  function _calcTotalSupply(uint256 avgRate) internal view virtual returns (uint256) {
    uint256 principalSupply = _totalSupply;

    if (principalSupply == 0) {
      return 0;
    }

    uint256 cumulatedInterest = Math.calculateCompoundedInterest(
      avgRate,
      _lastUpdateTimestamp,
      block.timestamp
    );

    return principalSupply.rayMul(cumulatedInterest);
  }

  /**
   * @dev Mints stable debt tokens to an account
   * @param account The account receiving the debt tokens
   * @param amount The amount being minted
   **/
  function _mint(address account, uint256 amount) internal {
    uint256 oldAccountBalance = _balances[account];
    _balances[account] = oldAccountBalance + amount;
  }

  /**
   * @dev Burns stable debt tokens of an account
   * @param account The account getting his debt burned
   * @param amount The amount being burned
   **/
  function _burn(address account, uint256 amount) internal {
    uint256 oldAccountBalance = _balances[account];
    _balances[account] = oldAccountBalance - amount;
  }

  modifier onlyMoneyPool {
    if (_msgSender() != address(_moneyPool)) revert TokenErrors.OnlyMoneyPool();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

interface IDToken is IERC20Metadata {
  /**
   * @dev Emitted when new stable debt is minted
   * @param account The address of the account who triggered the minting
   * @param receiver The recipient of stable debt tokens
   * @param amount The amount minted
   * @param currentBalance The current balance of the account
   * @param balanceIncrease The increase in balance since the last action of the account
   * @param newRate The rate of the debt after the minting
   * @param avgStableRate The new average stable rate after the minting
   * @param newTotalSupply The new total supply of the stable debt token after the action
   **/
  event Mint(
    address indexed account,
    address indexed receiver,
    uint256 amount,
    uint256 currentBalance,
    uint256 balanceIncrease,
    uint256 newRate,
    uint256 avgStableRate,
    uint256 newTotalSupply
  );

  /**
   * @dev Emitted when new stable debt is burned
   * @param account The address of the account
   * @param amount The amount being burned
   * @param currentBalance The current balance of the account
   * @param balanceIncrease The the increase in balance since the last action of the account
   * @param avgStableRate The new average stable rate after the burning
   * @param newTotalSupply The new total supply of the stable debt token after the action
   **/
  event Burn(
    address indexed account,
    uint256 amount,
    uint256 currentBalance,
    uint256 balanceIncrease,
    uint256 avgStableRate,
    uint256 newTotalSupply
  );

  /**
   * @dev Mints debt token to the `receiver` address.
   * - The resulting rate is the weighted average between the rate of the new debt
   * and the rate of the previous debt
   * @param account The address receiving the borrowed underlying, being the delegatee in case
   * of credit delegate, or same as `receiver` otherwise
   * @param receiver The address receiving the debt tokens
   * @param amount The amount of debt tokens to mint
   * @param rate The rate of the debt being minted
   **/
  function mint(
    address account,
    address receiver,
    uint256 amount,
    uint256 rate
  ) external returns (bool);

  /**
   * @dev Burns debt of `account`
   * - The resulting rate is the weighted average between the rate of the new debt
   * and the rate of the previous debt
   * @param account The address of the account getting his debt burned
   * @param amount The amount of debt tokens getting burned
   **/
  function burn(address account, uint256 amount) external;

  /**
   * @dev Returns the average rate of all the stable rate loans.
   * @return The average stable rate
   **/
  function getTotalAverageRealAssetBorrowRate() external view returns (uint256);

  /**
   * @dev Returns the stable rate of the account debt
   * @return The stable rate of the account
   **/
  function getUserAverageRealAssetBorrowRate(address account) external view returns (uint256);

  /**
   * @dev Returns the timestamp of the last update of the account
   * @return The timestamp
   **/
  function getUserLastUpdateTimestamp(address account) external view returns (uint256);

  /**
   * @dev Returns the principal, the total supply and the average stable rate
   **/
  function getDTokenData()
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256
    );

  /**
   * @dev Returns the timestamp of the last update of the total supply
   * @return The timestamp
   **/
  function getTotalSupplyLastUpdated() external view returns (uint256);

  /**
   * @dev Returns the total supply and the average stable rate
   **/
  function getTotalSupplyAndAvgRate() external view returns (uint256, uint256);

  /**
   * @dev Returns the principal debt balance of the account
   * @return The debt balance of the account since the last burn/mint action
   **/
  function principalBalanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import '../libraries/DataStruct.sol';

interface IMoneyPool {
  event NewReserve(
    address indexed asset,
    address lToken,
    address dToken,
    address interestModel,
    address tokenizer,
    address incentivePool,
    uint256 moneyPoolFactor
  );

  event Deposit(address indexed asset, address indexed account, uint256 amount);

  event Withdraw(
    address indexed asset,
    address indexed account,
    address indexed to,
    uint256 amount
  );

  event Borrow(
    address indexed asset,
    address indexed collateralServiceProvider,
    address indexed borrower,
    uint256 tokenId,
    uint256 borrowAPY,
    uint256 borrowAmount
  );

  event Repay(
    address indexed asset,
    address indexed borrower,
    uint256 tokenId,
    uint256 userDTokenBalance,
    uint256 feeOnCollateralServiceProvider
  );

  event Liquidation(
    address indexed asset,
    address indexed borrower,
    uint256 tokenId,
    uint256 userDTokenBalance,
    uint256 feeOnCollateralServiceProvider
  );

  function deposit(
    address asset,
    address account,
    uint256 amount
  ) external;

  function withdraw(
    address asset,
    address account,
    uint256 amount
  ) external;

  function borrow(address asset, uint256 tokenID) external;

  function repay(address asset, uint256 tokenId) external;

  function liquidate(address asset, uint256 tokenId) external;

  function getLTokenInterestIndex(address asset) external view returns (uint256);

  function getReserveData(address asset) external view returns (DataStruct.ReserveData memory);

  function addNewReserve(
    address asset,
    address lToken,
    address dToken,
    address interestModel,
    address tokenizer,
    address incentivePool,
    uint256 moneyPoolFactor_
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

library DataStruct {
  /**
    @notice The main reserve data struct.
   */
  struct ReserveData {
    uint256 moneyPoolFactor;
    uint256 lTokenInterestIndex;
    uint256 borrowAPY;
    uint256 depositAPY;
    uint256 totalDepositedAssetBondCount;
    uint256 lastUpdateTimestamp;
    address lTokenAddress;
    address dTokenAddress;
    address interestModelAddress;
    address tokenizerAddress;
    uint8 id;
    bool isPaused;
    bool isActivated;
  }

  /**
   * @notice The asset bond data struct.
   * @param ipfsHash The IPFS hash that contains the informations and contracts
   * between Collateral Service Provider and lender.
   * @param maturityTimestamp The amount of time measured in seconds that can elapse
   * before the NPL company liquidate the loan and seize the asset bond collateral.
   * @param borrower The address of the borrower.
   */
  struct AssetBondData {
    AssetBondState state;
    address borrower;
    address signer;
    address collateralServiceProvider;
    uint256 principal;
    uint256 debtCeiling;
    uint256 couponRate;
    uint256 interestRate;
    uint256 overdueInterestRate;
    uint256 loanStartTimestamp;
    uint256 collateralizeTimestamp;
    uint256 maturityTimestamp;
    uint256 liquidationTimestamp;
    string ipfsHash; // refactor : gas
    string signerOpinionHash;
  }

  struct AssetBondIdData {
    uint256 nonce;
    uint256 countryCode;
    uint256 collateralServiceProviderIdentificationNumber;
    uint256 collateralLatitude;
    uint256 collateralLatitudeSign;
    uint256 collateralLongitude;
    uint256 collateralLongitudeSign;
    uint256 collateralDetail;
    uint256 collateralCategory;
    uint256 productNumber;
  }

  /**
    @notice The states of asset bond
    * EMPTY: After
    * SETTLED:
    * CONFIRMED:
    * COLLATERALIZED:
    * MATURED:
    * REDEEMED:
    * NOT_PERFORMED:
   */
  enum AssetBondState {
    EMPTY,
    SETTLED,
    CONFIRMED,
    COLLATERALIZED,
    MATURED,
    REDEEMED,
    NOT_PERFORMED
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// Todo. add new arguements: We're waiting for hardhat team's working on custom error issue.

/**
 * @title Errors library
 * @author ELYSIA
 * @dev Custom error messages
 */
library MoneyPoolErrors {
  error DigitalAssetAlreadyAdded(address asset);
  error MaxDigitalAssetCountExceeded();
  error MaxReserveCountExceeded();
  error ReservePaused();
  error ReserveInactivated();
  error InvalidAmount(uint256 amount);
  error WithdrawInsufficientBalance(uint256 amount, uint256 userLTokenBalance);
  error MaturedAssetBond();
  error NotDepositedAssetBond();
  error NotSettledAssetBond(uint256 id);
  error NotSignedAssetBond(uint256 id);
  error LTokenTransferNotAllowed(address from, address to);
  error OnlyLToken();
  error OnlySignedTokenBorrowAllowed();
  error OnlyAssetBondOwnerBorrowAllowed();
  error PartialRepaymentNotAllowed(uint256 amount, uint256 totalRetrieveAmount);
  error NotEnoughLiquidityToLoan();
  error NotTimeForLoanStart();
  error LoanExpired();
  error OnlyCollateralServiceProvider();
  error OnlyCouncil();
  error OnlyMoneyPoolAdmin();
  error TimeOutForCollateralize();
}

library TokenErrors {
  error OnlyMoneyPool();
  error LTokenInvalidMintAmount(uint256 implicitBalance);
  error LTokenInvalidBurnAmount(uint256 implicitBalance);
  error DTokenTransferFromNotAllowed();
  error DTokenAllowanceNotAllowed();
  error DTokenApproveNotAllowed();
  error DTokenTransferNotAllowed();
}

library TokenizerErrors {
  error OnlyMoneyPool();
  error OnlyCollateralServiceProvider();
  error OnlyCouncil();
  error AssetBondIDAlreadyExists(uint256 tokenId);
  error MintedAssetBondReceiverNotAllowed(uint256 tokenId); // add `address receiver`
  error OnlyOwnerHasAuthrotyToSettle(uint256 tokenId); // and `address minter` |
  error AssetBondAlreadySettled(uint256 tokenId);
  error SettledLoanStartTimestampInvalid();
  error LoanDurationInvalid();
  error OnlySettledTokenSignAllowed();
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import './WadRayMath.sol';
import './TimeConverter.sol';

library Math {
  using WadRayMath for uint256;

  uint256 internal constant SECONDSPERYEAR = 365 days;

  function calculateLinearInterest(
    uint256 rate,
    uint256 lastUpdateTimestamp,
    uint256 currentTimestamp
  ) internal pure returns (uint256) {
    uint256 timeDelta = currentTimestamp - uint256(lastUpdateTimestamp);

    return ((rate * timeDelta) / SECONDSPERYEAR) + WadRayMath.ray();
  }

  /**
   * @notice Author : AAVE
   * @dev Function to calculate the interest using a compounded interest rate formula
   * To avoid expensive exponentiation, the calculation is performed using a binomial approximation:
   *  (1+x)^n = 1+n*x+[n/2*(n-1)]*x^2+[n/6*(n-1)*(n-2)*x^3...
   *
   * The approximation slightly underpays liquidity providers and undercharges borrowers, with the advantage of great gas cost reductions
   * The whitepaper contains reference to the approximation and a table showing the margin of error per different time periods
   *
   * @param rate The interest rate, in ray
   * @param lastUpdateTimestamp The timestamp of the last update of the interest
   * @return The interest rate compounded during the timeDelta, in ray
   **/
  function calculateCompoundedInterest(
    uint256 rate,
    uint256 lastUpdateTimestamp,
    uint256 currentTimestamp
  ) internal pure returns (uint256) {
    //solium-disable-next-line
    uint256 exp = currentTimestamp - uint256(lastUpdateTimestamp);

    if (exp == 0) {
      return WadRayMath.ray();
    }

    uint256 expMinusOne = exp - 1;

    uint256 expMinusTwo = exp > 2 ? exp - 2 : 0;

    uint256 ratePerSecond = rate / SECONDSPERYEAR;

    uint256 basePowerTwo = ratePerSecond.rayMul(ratePerSecond);
    uint256 basePowerThree = basePowerTwo.rayMul(ratePerSecond);

    uint256 secondTerm = (exp * expMinusOne * basePowerTwo) / 2;
    uint256 thirdTerm = (exp * expMinusOne * expMinusTwo * basePowerThree) / 6;

    return WadRayMath.ray() + (ratePerSecond * exp) + secondTerm + thirdTerm;
  }

  function calculateRateInIncreasingBalance(
    uint256 averageRate,
    uint256 totalBalance,
    uint256 amountIn,
    uint256 rate
  ) internal pure returns (uint256, uint256) {
    uint256 weightedAverageRate = totalBalance.wadToRay().rayMul(averageRate);
    uint256 weightedAmountRate = amountIn.wadToRay().rayMul(rate);

    uint256 newTotalBalance = totalBalance + amountIn;
    uint256 newAverageRate =
      (weightedAverageRate + weightedAmountRate).rayDiv(newTotalBalance.wadToRay());

    return (newTotalBalance, newAverageRate);
  }

  function calculateRateInDecreasingBalance(
    uint256 averageRate,
    uint256 totalBalance,
    uint256 amountOut,
    uint256 rate
  ) internal pure returns (uint256, uint256) {
    // if decreasing amount exceeds totalBalance,
    // overall rate and balacne would be set 0
    if (totalBalance <= amountOut) {
      return (0, 0);
    }

    uint256 weightedAverageRate = totalBalance.wadToRay().rayMul(averageRate);
    uint256 weightedAmountRate = amountOut.wadToRay().rayMul(rate);

    if (weightedAverageRate <= weightedAmountRate) {
      return (0, 0);
    }

    uint256 newTotalBalance = totalBalance - amountOut;

    uint256 newAverageRate =
      (weightedAverageRate - weightedAmountRate).rayDiv(newTotalBalance.wadToRay());

    return (newTotalBalance, newAverageRate);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @title Ethereum timestamp conversion library
 * @author ethereum-datatime
 */
library TimeConverter {
  struct DateTime {
    uint16 year;
    uint8 month;
    uint8 day;
    uint8 hour;
    uint8 minute;
    uint8 second;
    uint8 weekday;
  }

  uint256 constant DAY_IN_SECONDS = 86400;
  uint256 constant YEAR_IN_SECONDS = 31536000;
  uint256 constant LEAP_YEAR_IN_SECONDS = 31622400;

  uint256 constant HOUR_IN_SECONDS = 3600;
  uint256 constant MINUTE_IN_SECONDS = 60;

  uint16 constant ORIGIN_YEAR = 1970;

  function isLeapYear(uint16 year) internal pure returns (bool) {
    if (year % 4 != 0) {
      return false;
    }
    if (year % 100 != 0) {
      return true;
    }
    if (year % 400 != 0) {
      return false;
    }
    return true;
  }

  function leapYearsBefore(uint256 year) internal pure returns (uint256) {
    year -= 1;
    return year / 4 - year / 100 + year / 400;
  }

  function getDaysInMonth(uint8 month, uint16 year) internal pure returns (uint8) {
    if (
      month == 1 ||
      month == 3 ||
      month == 5 ||
      month == 7 ||
      month == 8 ||
      month == 10 ||
      month == 12
    ) {
      return 31;
    } else if (month == 4 || month == 6 || month == 9 || month == 11) {
      return 30;
    } else if (isLeapYear(year)) {
      return 29;
    } else {
      return 28;
    }
  }

  function parseTimestamp(uint256 timestamp) internal pure returns (DateTime memory dateTime) {
    uint256 secondsAccountedFor = 0;
    uint256 buf;
    uint8 i;

    // Year
    dateTime.year = getYear(timestamp);
    buf = leapYearsBefore(dateTime.year) - leapYearsBefore(ORIGIN_YEAR);

    secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
    secondsAccountedFor += YEAR_IN_SECONDS * (dateTime.year - ORIGIN_YEAR - buf);

    // Month
    uint256 secondsInMonth;
    for (i = 1; i <= 12; i++) {
      secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dateTime.year);
      if (secondsInMonth + secondsAccountedFor > timestamp) {
        dateTime.month = i;
        break;
      }
      secondsAccountedFor += secondsInMonth;
    }

    // Day
    for (i = 1; i <= getDaysInMonth(dateTime.month, dateTime.year); i++) {
      if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
        dateTime.day = i;
        break;
      }
      secondsAccountedFor += DAY_IN_SECONDS;
    }

    // Hour
    dateTime.hour = getHour(timestamp);
    // Minute
    dateTime.minute = getMinute(timestamp);
    // Second
    dateTime.second = getSecond(timestamp);
    // Day of week.
    dateTime.weekday = getWeekday(timestamp);
  }

  function getYear(uint256 timestamp) internal pure returns (uint16) {
    uint256 secondsAccountedFor = 0;
    uint16 year;
    uint256 numLeapYears;

    // Year
    year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
    numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

    secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
    secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

    while (secondsAccountedFor > timestamp) {
      if (isLeapYear(uint16(year - 1))) {
        secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
      } else {
        secondsAccountedFor -= YEAR_IN_SECONDS;
      }
      year -= 1;
    }
    return year;
  }

  function getMonth(uint256 timestamp) internal pure returns (uint8) {
    return parseTimestamp(timestamp).month;
  }

  function getDay(uint256 timestamp) internal pure returns (uint8) {
    return parseTimestamp(timestamp).day;
  }

  function getHour(uint256 timestamp) internal pure returns (uint8) {
    return uint8((timestamp / 60 / 60) % 24);
  }

  function getMinute(uint256 timestamp) internal pure returns (uint8) {
    return uint8((timestamp / 60) % 60);
  }

  function getSecond(uint256 timestamp) internal pure returns (uint8) {
    return uint8(timestamp % 60);
  }

  function getWeekday(uint256 timestamp) internal pure returns (uint8) {
    return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
  }

  function toTimestamp(
    uint16 year,
    uint8 month,
    uint8 day
  ) internal pure returns (uint256 timestamp) {
    return toTimestamp(year, month, day, 0, 0, 0);
  }

  function toTimestamp(
    uint16 year,
    uint8 month,
    uint8 day,
    uint8 hour
  ) internal pure returns (uint256 timestamp) {
    return toTimestamp(year, month, day, hour, 0, 0);
  }

  function toTimestamp(
    uint16 year,
    uint8 month,
    uint8 day,
    uint8 hour,
    uint8 minute
  ) internal pure returns (uint256 timestamp) {
    return toTimestamp(year, month, day, hour, minute, 0);
  }

  function toTimestamp(
    uint16 year,
    uint8 month,
    uint8 day,
    uint8 hour,
    uint8 minute,
    uint8 second
  ) internal pure returns (uint256 timestamp) {
    uint16 i;

    // Year
    for (i = ORIGIN_YEAR; i < year; i++) {
      if (isLeapYear(i)) {
        timestamp += LEAP_YEAR_IN_SECONDS;
      } else {
        timestamp += YEAR_IN_SECONDS;
      }
    }

    // Month
    uint8[12] memory monthDayCounts;
    monthDayCounts[0] = 31;
    if (isLeapYear(year)) {
      monthDayCounts[1] = 29;
    } else {
      monthDayCounts[1] = 28;
    }
    monthDayCounts[2] = 31;
    monthDayCounts[3] = 30;
    monthDayCounts[4] = 31;
    monthDayCounts[5] = 30;
    monthDayCounts[6] = 31;
    monthDayCounts[7] = 31;
    monthDayCounts[8] = 30;
    monthDayCounts[9] = 31;
    monthDayCounts[10] = 30;
    monthDayCounts[11] = 31;

    for (i = 1; i < month; i++) {
      timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
    }

    // Day
    timestamp += DAY_IN_SECONDS * (day - 1);
    // Hour
    timestamp += HOUR_IN_SECONDS * (hour);
    // Minute
    timestamp += MINUTE_IN_SECONDS * (minute);
    // Second
    timestamp += second;

    return timestamp;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @title WadRayMath library
 * @author Aave
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 **/

library WadRayMath {
  uint256 internal constant WAD = 1e18;
  uint256 internal constant halfWAD = WAD / 2;

  uint256 internal constant RAY = 1e27;
  uint256 internal constant halfRAY = RAY / 2;

  uint256 internal constant WAD_RAY_RATIO = 1e9;

  /**
   * @return One ray, 1e27
   **/
  function ray() internal pure returns (uint256) {
    return RAY;
  }

  /**
   * @return One wad, 1e18
   **/

  function wad() internal pure returns (uint256) {
    return WAD;
  }

  /**
   * @return Half ray, 1e27/2
   **/
  function halfRay() internal pure returns (uint256) {
    return halfRAY;
  }

  /**
   * @return Half ray, 1e18/2
   **/
  function halfWad() internal pure returns (uint256) {
    return halfWAD;
  }

  /**
   * @dev Multiplies two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a*b, in wad
   **/
  function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }
    return (a * b + halfWAD) / WAD;
  }

  /**
   * @dev Divides two wad, rounding half up to the nearest wad
   * @param a Wad
   * @param b Wad
   * @return The result of a/b, in wad
   **/
  function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, 'Division by Zero');
    uint256 halfB = b / 2;
    return (a * WAD + halfB) / b;
  }

  /**
   * @dev Multiplies two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a*b, in ray
   **/
  function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0) {
      return 0;
    }
    return (a * b + halfRAY) / RAY;
  }

  /**
   * @dev Divides two ray, rounding half up to the nearest ray
   * @param a Ray
   * @param b Ray
   * @return The result of a/b, in ray
   **/
  function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, 'Division by Zero');
    uint256 halfB = b / 2;
    return (a * RAY + halfB) / b;
  }

  /**
   * @dev Casts ray down to wad
   * @param a Ray
   * @return a casted to wad, rounded half up to the nearest wad
   **/
  function rayToWad(uint256 a) internal pure returns (uint256) {
    uint256 halfRatio = WAD_RAY_RATIO / 2;
    uint256 result = halfRatio + a;
    return result / WAD_RAY_RATIO;
  }

  /**
   * @dev Converts wad up to ray
   * @param a Wad
   * @return a converted in ray
   **/
  function wadToRay(uint256 a) internal pure returns (uint256) {
    uint256 result = a * WAD_RAY_RATIO;
    return result;
  }
}

