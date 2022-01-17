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

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';

import '../../managers/interfaces/IProtocolAddressProvider.sol';

pragma solidity ^0.8.4;

error NotAllowedAssetToken();

interface ICore is IERC721Receiver {
  event Deposit(address asset, address indexed account, uint256 amount);

  event Withdraw(address asset, address indexed account, address indexed receiver, uint256 amount);

  event Borrow(
    address asset,
    address collateral,
    address indexed borrower,
    address indexed receiver,
    uint256 tokenId,
    uint256 loanPrincipal,
    uint256 loanInterestRate,
    uint256 loanDuration,
    string description
  );

  event Repay(
    address asset,
    address collateral,
    address indexed borrower,
    address indexed repayer,
    uint256 tokenId,
    uint256 repayAmount,
    uint256 loanInterestRate,
    uint256 timestamp
  );

  event Liquidate(
    address asset,
    address collateral,
    address indexed borrower,
    address indexed liquidator,
    uint256 tokenId,
    uint256 repayAmount,
    uint256 loanInterestRate,
    uint256 timestamp
  );

  event UpdateInterestRateModel(address previousInterestRateModel, address interestRateModel);

  event ActivatePool(address asset, uint256 timestamp);

  event DeactivatePool(address asset, uint256 timestamp);

  event PausePool(address asset, uint256 timestamp);

  event UnpausePool(address asset, uint256 timestamp);

  event AddNewPool(address pool, address debtToken);

  event AllowAssetToken(address assetToken);

  /// @notice By depositing assets in the pool and supply liquidity, depositors can receive
  /// interest accruing from the pool. The return on the deposit arises from the interest on loans.
  /// MoneyPool depositors who deposit certain assets receives pool token equivalent to
  /// the deposit amount. Pool tokens are backed by assets deposited in the pool in a 1:1 ratio.
  /// @param asset The address of the underlying asset to deposit
  /// @param account The address that will receive the LToken
  /// @param amount Deposit amount
  function deposit(
    address asset,
    address account,
    uint256 amount
  ) external;

  /// @notice The depositors can seize their assets deposited in the pool whenever they wish.
  /// User can withdraw an amount of underlying asset from the pool and burn the corresponding pool tokens.
  /// @param asset The address of the underlying asset to withdraw
  /// @param receiver The address that will receive the underlying asset
  /// @param amount Withdrawl amount
  function withdraw(
    address asset,
    address receiver,
    uint256 amount
  ) external;

  /// @notice The user can take out a loan of value below to the principal
  /// recorded in the asset bond data. As asset token is deposited as collateral in the ...(TODO)
  /// and loans are made, financial services that link real assets and cryptoassets can be achieved.
  /// @param asset The address of the underlying asset to borrow
  /// @param collateral The address of the asset token collateralized for
  /// @param borrower The address of account who will collateralize asset token and begin the loan
  /// @param receiver The address of account who will receive the loan principal
  /// @param tokenId The id of the token to collateralize
  /// @param loanPrincipal The original sum of money transferred from lender to borrower at the beginning of the loan
  /// @param loanDuration The amount of time (measured in seconds) that can elapse before the lender can liquidate the loan and seize the underlying collateral NFT
  /// @param description Description for the loan
  function borrow(
    address asset,
    address collateral,
    address borrower,
    address receiver,
    uint256 tokenId,
    uint256 loanPrincipal,
    uint256 loanDuration,
    string memory description
  ) external;

  /// @notice Repay function
  /// @param asset The address of the underlying asset to repay
  /// @param collateral The address of the asset token collateralized for
  /// @param borrower The address of account who will collateralize asset token and begin the loan
  /// @param tokenId The id of the token to be collateralized
  /// @param descriptionHash Description hash for the loan
  function repay(
    address asset,
    address collateral,
    address borrower,
    uint256 tokenId,
    bytes32 descriptionHash
  ) external;

  /// @notice Liquidation function
  /// @param asset The address of the underlying asset to liquidate
  /// @param collateral The address of the asset token collateralized for
  /// @param borrower The address of account who will collateralize asset token and begin the loan
  /// @param tokenId The id of the token to be collateralized
  /// @param descriptionHash Description hash for the loan
  function liquidate(
    address asset,
    address collateral,
    address borrower,
    uint256 tokenId,
    bytes32 descriptionHash
  ) external;

  /// @notice This function accrues protocol treasury calculated based on the debt token data by minting pool token to treasury contract
  /// @param asset The address of the underlying asset of the pool
  function accrueProtocolTreasury(address asset) external;

  /// @notice This function can be called when new pool added
  /// Only callable by the core contract
  /// @param asset Underlying asset address to add
  /// @param incentiveAllocation Incentive allocation for the given pool in incentive pool
  function addNewPool(
    address asset,
    uint256 incentiveAllocation,
    uint256 poolFactor
  ) external;

  /// @notice This function updates the address of interestRateModel contract
  /// @param interestRateModel The address of interestRateModel contract
  function updateInterestRateModel(address interestRateModel) external;

  /// @notice Allow an asset token that can be used for collateral for the loan in the protocol
  /// @param assetToken The address of the asset token
  function allowAssetToken(address assetToken) external;

  /// @notice Activates a pool
  /// @param asset The address of the underlying asset of the pool
  function activatePool(address asset) external;

  /// @notice Deactivates a pool
  /// @param asset The address of the underlying asset of the pool
  function deactivatePool(address asset) external;

  /// @notice Pause a pool. A paused pool doesn't allow any new deposit, borrow or rate swap
  /// but allows repayments, liquidations, rate rebalances and withdrawals
  /// @param asset The address of the underlying asset of the pool
  function pausePool(address asset) external;

  /// @notice Unpause a pool
  /// @param asset The address of the underlying asset of the pool
  function unpausePool(address asset) external;

  /// @notice Returns the state and configuration of the pool
  /// @param asset Underlying asset address
  /// @return poolInterestIndex The poolInterestIndex recently updated and stored in. Not current index
  /// @return borrowAPY The current borrowAPY expressed in RAY
  /// @return depositAPY The current depositAPY expressed in RAY
  /// @return lastUpdateTimestamp The protocol last updated timestamp
  /// @return poolFactor The pool factor expressed in ray
  /// @return poolAddress The address of the pool contract
  /// @return debtTokenAddress The address of the debt token contract
  /// @return isPaused The pool is paused
  /// @return isActivated The pool is activated
  function getPoolData(address asset)
    external
    view
    returns (
      uint256 poolInterestIndex,
      uint256 borrowAPY,
      uint256 depositAPY,
      uint256 lastUpdateTimestamp,
      uint256 poolFactor,
      address poolAddress,
      address debtTokenAddress,
      bool isPaused,
      bool isActivated
    );

  /// @notice This function calculates and returns the current `poolInterestIndex`
  /// @param asset The address of the underlying asset of the pool
  /// @notice poolInterestIndex current poolInterestIndex calculated
  function getPoolInterestIndex(address asset) external view returns (uint256 poolInterestIndex);

  /// @notice This function returns the address of protocolAddressProvider contract
  /// @return protocolAddressProvider The instance of protocolAddressProvider contract
  function getProtocolAddressProvider() external view returns (address protocolAddressProvider);

  /// @notice This function returns the address of interestRateModel contract
  /// @return interestRateModel The address of `InterestRateModel` contract
  function getInterestRateModel() external view returns (address interestRateModel);

  /// @notice This function returns the address of protocol treasury contract
  /// @return protocolTreasury The address of `ProtocolTreasury` contract
  function getProtocolTreasury() external view returns (address protocolTreasury);

  /// @notice This function returns the address of interestRateModel contract
  /// @return allowed Whether the given assetToken address is allowed or not
  function getAssetTokenAllowed(address assetToken) external view returns (bool allowed);

  /// @notice This function return temporary storage slot in add new pool
  /// @return asset Returns the address of asset to added only in the `addNewPool` tx, Others, returns `address(0)`
  function getAssetAdded() external view returns (address asset);

  /// @notice This function calls an external view token contract method that returns name, and parses the output into a string
  /// @param asset The address of the token contract
  /// @return name the name of the token. If not exists, it generates randomly
  function getERC20NameSafe(address asset) external view returns (string memory name);

  /// @notice This function calls an external view token contract method that returns symbol, and parses the output into a string
  /// @param asset The address of the token contract
  /// @return symbol the symbol of the token. If not exists, it generates randomly
  function getERC20SymbolSafe(address asset) external view returns (string memory symbol);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import './interfaces/IProtocolDataPipeline.sol';
import '../core/interfaces/ICore.sol';
import '../pool/interfaces/IPool.sol';
import '../pool/interfaces/IDebtToken.sol';
import '../managers/interfaces/IProtocolAddressProvider.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title ProtocolDataPipeline
/// @notice The data pipeline contract is to help integrating the data of user and pool in the protocol.
contract ProtocolDataPipeline is IProtocolDataPipeline {
  IProtocolAddressProvider internal _protocolAddressProvider;

  constructor(IProtocolAddressProvider protocolAddressProvider) {
    _protocolAddressProvider = protocolAddressProvider;
  }

  /// @inheritdoc IProtocolDataPipeline
  function getProtocolAddresses()
    external
    view
    override
    returns (
      address guardian,
      address liquidationManager,
      address loanManager,
      address incentiveManager,
      address governance,
      address council,
      address core,
      address treasury,
      address interestRateModel
    )
  {
    guardian = _protocolAddressProvider.getGuardian();
    liquidationManager = _protocolAddressProvider.getLiquidationManager();
    loanManager = _protocolAddressProvider.getLoanManager();
    incentiveManager = _protocolAddressProvider.getIncentiveManager();
    governance = _protocolAddressProvider.getGovernance();
    council = _protocolAddressProvider.getCouncil();
    core = _protocolAddressProvider.getCore();
    treasury = _protocolAddressProvider.getProtocolTreasury();
    interestRateModel = ICore(core).getInterestRateModel();
  }

  /// @inheritdoc IProtocolDataPipeline
  function getUserData(address asset, address account)
    external
    view
    override
    returns (
      uint256 userAssetBalance,
      uint256 poolTokenBalance,
      uint256 implicitPoolTokenBalance,
      uint256 debtTokenBalance,
      uint256 principalDebtTokenBalance,
      uint256 averageBorrowRate,
      uint256 userDebtTokenLastUpdateTimestamp
    )
  {
    (, , , , , address poolAddress, address debtTokenAddress, , ) = ICore(
      _protocolAddressProvider.getCore()
    ).getPoolData(asset);

    userAssetBalance = IERC20(asset).balanceOf(account);
    poolTokenBalance = IPool(poolAddress).balanceOf(account);
    implicitPoolTokenBalance = IPool(poolAddress).implicitBalanceOf(account);
    debtTokenBalance = IDebtToken(debtTokenAddress).balanceOf(account);
    principalDebtTokenBalance = IDebtToken(debtTokenAddress).principalBalanceOf(account);
    averageBorrowRate = IDebtToken(debtTokenAddress).getUserAverageBorrowRate(account);
    userDebtTokenLastUpdateTimestamp = IDebtToken(debtTokenAddress).getUserLastUpdateTimestamp(
      account
    );
  }

  /// @inheritdoc IProtocolDataPipeline
  function getPoolData(address asset)
    external
    view
    override
    returns (
      uint256 poolRemainingLiquidity,
      uint256 implicitPoolTokenSupply,
      uint256 totalPoolTokenSupply,
      uint256 poolInterestIndex,
      uint256 principalDebtTokenSupply,
      uint256 totalDebtTokenSupply,
      uint256 averageBorrowRate,
      uint256 debtTokenLastUpdateTimestamp,
      uint256 borrowAPY,
      uint256 depositAPY,
      uint256 poolLastUpdateTimestamp
    )
  {
    address poolAddress;
    address debtTokenAddress;
    (
      poolInterestIndex,
      borrowAPY,
      depositAPY,
      poolLastUpdateTimestamp,
      ,
      poolAddress,
      debtTokenAddress,
      ,

    ) = ICore(_protocolAddressProvider.getCore()).getPoolData(asset);

    poolRemainingLiquidity = IERC20(asset).balanceOf(poolAddress);
    implicitPoolTokenSupply = IPool(poolAddress).implicitTotalSupply();
    totalPoolTokenSupply = IPool(poolAddress).totalSupply();

    (
      principalDebtTokenSupply,
      totalDebtTokenSupply,
      averageBorrowRate,
      debtTokenLastUpdateTimestamp
    ) = IDebtToken(debtTokenAddress).getDebtTokenData();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IProtocolDataPipeline {
  /// @notice This function aggregates protocol contracts address
  /// @return guardian guardian
  /// @return liquidationManager liquidationManager
  /// @return loanManager loanManager
  /// @return incentiveManager incentiveManager
  /// @return governance governance
  /// @return council council
  /// @return core core
  /// @return treasury treasury
  /// @return interestRateModel interestRateModel
  function getProtocolAddresses()
    external
    view
    returns (
      address guardian,
      address liquidationManager,
      address loanManager,
      address incentiveManager,
      address governance,
      address council,
      address core,
      address treasury,
      address interestRateModel
    );

  /// @notice This function aggregates protocol user data
  /// @param asset The address of underlying asset of the pool
  /// @param account The user address
  /// @return userAssetBalance The underlying asset balance of the user
  /// @return poolTokenBalance The pool token balance of the user
  /// @return implicitPoolTokenBalance The implicit pool token balance of the user
  /// @return debtTokenBalance The current debt token balance of the user
  /// @return principalDebtTokenBalance The principal debt token balance of the user
  /// @return averageBorrowRate The average stable borrow rate of the user
  /// @return userDebtTokenLastUpdateTimestamp The user last update timestamp for debt token
  function getUserData(address asset, address account)
    external
    view
    returns (
      uint256 userAssetBalance,
      uint256 poolTokenBalance,
      uint256 implicitPoolTokenBalance,
      uint256 debtTokenBalance,
      uint256 principalDebtTokenBalance,
      uint256 averageBorrowRate,
      uint256 userDebtTokenLastUpdateTimestamp
    );

  /// @notice This function aggregates protocol pool data for specific asset
  /// @param asset The address of underlying asset of the pool
  /// @return poolRemainingLiquidity poolRemainingLiquidity
  /// @return implicitPoolTokenSupply implicitPoolTokenSupply
  /// @return totalPoolTokenSupply totalPoolTokenSupply
  /// @return poolInterestIndex poolInterestIndex
  /// @return principalDebtTokenSupply principalDebtTokenSupply
  /// @return totalDebtTokenSupply totalDebtTokenSupply
  /// @return averageBorrowRate averageBorrowRate
  /// @return debtTokenLastUpdateTimestamp debtTokenLastUpdateTimestamp
  /// @return borrowAPY borrowAPY
  /// @return depositAPY depositAPY
  /// @return poolLastUpdateTimestamp poolLastUpdateTimestamp
  function getPoolData(address asset)
    external
    view
    returns (
      uint256 poolRemainingLiquidity,
      uint256 implicitPoolTokenSupply,
      uint256 totalPoolTokenSupply,
      uint256 poolInterestIndex,
      uint256 principalDebtTokenSupply,
      uint256 totalDebtTokenSupply,
      uint256 averageBorrowRate,
      uint256 debtTokenLastUpdateTimestamp,
      uint256 borrowAPY,
      uint256 depositAPY,
      uint256 poolLastUpdateTimestamp
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

error OnlyGovernance();
error OnlyGuardian();
error OnlyCouncil();
error OnlyCore();

interface IProtocolAddressProvider {
  /// @notice emitted when liquidationManager address updated
  event UpdateLiquidationManager(address liquidationManager);

  /// @notice emitted when loanManager address updated
  event UpdateLoanManager(address loanManager);

  /// @notice emitted when incentiveManager address updated
  event UpdateIncentiveManager(address incentiveManager);

  /// @notice emitted when governance address updated
  event UpdateGovernance(address governance);

  /// @notice emitted when council address updated
  event UpdateCouncil(address council);

  /// @notice emitted when core address updated
  event UpdateCore(address core);

  /// @notice emitted when treasury address updated
  event UpdateTreasury(address treasury);

  /// @notice emitted when protocol address provider initialized
  event ProtocolAddressProviderInitialized(
    address guardian,
    address liquidationManager,
    address loanManager,
    address incentiveManager,
    address governance,
    address council,
    address core,
    address treausury
  );

  /// @notice ProtocolAddressProvider should be initialized after deploying protocol contracts finished.
  /// @param guardian guardian
  /// @param liquidationManager liquidationManager
  /// @param loanManager loanManager
  /// @param incentiveManager incentiveManager
  /// @param governance governance
  /// @param council council
  /// @param core core
  /// @param treasury treasury
  function initialize(
    address guardian,
    address liquidationManager,
    address loanManager,
    address incentiveManager,
    address governance,
    address council,
    address core,
    address treasury
  ) external;

  /// @notice This function returns the address of the guardian
  /// @return guardian The address of the protocol guardian
  function getGuardian() external view returns (address guardian);

  /// @notice This function returns the address of liquidationManager contract
  /// @return liquidationManager The address of liquidationManager contract
  function getLiquidationManager() external view returns (address liquidationManager);

  /// @notice This function returns the address of LoanManager contract
  /// @return loanManager The address of LoanManager contract
  function getLoanManager() external view returns (address loanManager);

  /// @notice This function returns the address of incentiveManager contract
  /// @return incentiveManager The address of incentiveManager contract
  function getIncentiveManager() external view returns (address incentiveManager);

  /// @notice This function returns the address of governance contract
  /// @return governance The address of governance contract
  function getGovernance() external view returns (address governance);

  /// @notice This function returns the address of council contract
  /// @return council The address of council contract
  function getCouncil() external view returns (address council);

  /// @notice This function returns the address of core contract
  /// @return core The address of core contract
  function getCore() external view returns (address core);

  /// @notice This function returns the address of protocolTreasury contract
  /// @return protocolTreasury The address of protocolTreasury contract
  function getProtocolTreasury() external view returns (address protocolTreasury);

  /// @notice This function updates the address of liquidationManager contract
  /// @param liquidationManager The address of liquidationManager contract to update
  function updateLiquidationManager(address liquidationManager) external;

  /// @notice This function updates the address of LoanManager contract
  /// @param loanManager The address of LoanManager contract to update
  function updateLoanManager(address loanManager) external;

  /// @notice This function updates the address of incentiveManager contract
  /// @param incentiveManager The address of incentiveManager contract to update
  function updateIncentiveManager(address incentiveManager) external;

  /// @notice This function updates the address of governance contract
  /// @param governance The address of governance contract to update
  function updateGovernance(address governance) external;

  /// @notice This function updates the address of council contract
  /// @param council The address of council contract to update
  function updateCouncil(address council) external;

  /// @notice This function updates the address of core contract
  /// @param core The address of core contract to update
  function updateCore(address core) external;

  /// @notice This function updates the address of treasury contract
  /// @param treasury The address of treasury contract to update
  function updateTreasury(address treasury) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';

interface IDebtToken is IERC20Metadata {
  /// @notice Emitted when new debt token is minted
  /// @param account The address of the account who triggered the minting
  /// @param amount The amount minted
  /// @param currentBalance The current balance of the account
  /// @param balanceIncrease The increase in balance since the last action of the account
  /// @param newRate The rate of the debt after the minting
  /// @param averageBorrowRate The new average rate after the minting
  /// @param newTotalSupply The new total supply of the debt token after the action
  event Mint(
    address indexed account,
    uint256 amount,
    uint256 currentBalance,
    uint256 balanceIncrease,
    uint256 newRate,
    uint256 averageBorrowRate,
    uint256 newTotalSupply
  );

  /// @notice Emitted when new debt is burned
  /// @param account The address of the account
  /// @param amount The amount being burned
  /// @param currentBalance The current balance of the account
  /// @param balanceIncrease The the increase in balance since the last action of the account
  /// @param averageBorrowRate The new average rate after the burning
  /// @param newTotalSupply The new total supply of the debt token after the action
  event Burn(
    address indexed account,
    uint256 amount,
    uint256 currentBalance,
    uint256 balanceIncrease,
    uint256 averageBorrowRate,
    uint256 newTotalSupply
  );

  /// @notice Mints debt token to the `receiver` address.
  /// - The resulting rate is the weighted average between the rate of the new debt
  /// and the rate of the previous debt
  /// @param account The address receiving the borrowed underlying, being the delegatee in case
  /// of credit delegate, or same as `receiver` otherwise
  /// @param amount The amount of debt tokens to mint
  /// @param rate The borrow rate of the loan which is same as current pool borrowAPY
  function mint(
    address account,
    uint256 amount,
    uint256 rate
  ) external;

  /// @notice Burns debt of `account`
  /// - The resulting rate is the weighted average between the rate of the new debt
  /// and the rate of the previous debt
  /// @param account The address of the account getting his debt burned
  /// @param amount The amount of debt tokens getting burned
  function burn(address account, uint256 amount) external;

  /// @notice Returns the average rate of all the rate loans.
  /// @return totalAverageBorrowRate Total average borrow rate
  function getTotalAverageBorrowRate() external view returns (uint256 totalAverageBorrowRate);

  /// @notice Returns the rate of the account debt
  /// @return averageBorrowRate The rate of the account
  function getUserAverageBorrowRate(address account)
    external
    view
    returns (uint256 averageBorrowRate);

  /// @notice Returns the timestamp of the last update of the account
  /// @return userLastUpdateTimestamp User debt token last update timestamp
  function getUserLastUpdateTimestamp(address account)
    external
    view
    returns (uint256 userLastUpdateTimestamp);

  /// @notice Returns the principal, the total supply and the average rate
  function getDebtTokenData()
    external
    view
    returns (
      uint256 principalDebtTokenSupply,
      uint256 totalDebtTokenSupply,
      uint256 averageBorrowRate,
      uint256 debtTokenLastUpdateTimestamp
    );

  /// @notice Returns the timestamp of the last update of the total supply
  /// @return lastUpdateTimestamp The timestamp
  function getDebtTokenLastUpdateTimestamp() external view returns (uint256 lastUpdateTimestamp);

  /// @notice Returns the total supply and the average rate
  /// @return totalSupply The totalSupply
  /// @return averageBorrowRate The average borrow rate
  function getTotalSupplyAndAverageBorrowRate()
    external
    view
    returns (uint256 totalSupply, uint256 averageBorrowRate);

  /// @notice Returns the principal debt balance of the account
  /// @return principalBalance balance of the account since the last burn/mint action
  function principalBalanceOf(address account) external view returns (uint256 principalBalance);

  function updateDebtTokenState() external;

  function getAcrruedDebt() external view returns (uint256 accruedDebt);
}

// SPDX-License-Identifier: MIT

import './IPoolToken.sol';

pragma solidity ^0.8.4;

interface IPool is IPoolToken {
  /// @notice Mints pool tokens account `account`
  /// @param account The address of the user who will receive the pool tokens
  /// @param amount The amount being minted
  /// @param index The new interest index of the pool
  function mint(
    address account,
    uint256 amount,
    uint256 index
  ) external;

  /// @notice When user withdraw, pool contract burns pool tokens from `account`and transfer underlying asset to `receiver`
  /// This function is only callable by the core contract
  /// @param account The owner of the pool tokens
  /// @param receiver The address that will receive the underlying asset
  /// @param amountToBurn The amount being pool token burned
  /// @param amountToTransfer The amount being asset transferred
  /// @param poolInterestIndex The new interest index of the pool
  function burnAndTransferAsset(
    address account,
    address receiver,
    uint256 amountToBurn,
    uint256 amountToTransfer,
    uint256 poolInterestIndex
  ) external;

  /// @notice Transfers the underlying asset to receiver.
  /// @param receiver The recipient of the underlying asset
  /// @param amount The amount being transferred to receiver
  function transferAsset(address receiver, uint256 amount) external;

  /// @notice This function returns the underlying asset of this pool
  /// @return underlyingAsset The underlying asset of the pool
  function getUnderlyingAsset() external view returns (address underlyingAsset);

  /// @notice This function mints the `amount` of pool token to the `_protocolTreasury`
  /// @param amount Amount to mint
  /// @param index The current interest index of the pool
  function mintToProtocolTreasury(uint256 amount, uint256 index) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IPoolToken is IERC20 {
  /// @notice Emitted after pool tokens are minted
  /// @param account The receiver of minted pool token
  /// @param amount The amount being minted
  /// @param index The new interest index of the pool
  event Mint(address indexed account, uint256 amount, uint256 index);

  /// @notice Emitted after pool tokens are burned
  /// @param account The owner of the pool tokens, getting them burned
  /// @param receiver The address that will receive the underlying asset
  /// @param amount The amount being burned
  /// @param index The new interest index of the pool
  event Burn(address indexed account, address indexed receiver, uint256 amount, uint256 index);

  /// @notice Emitted during the transfer action
  /// @param account The account whose tokens are being transferred
  /// @param to The recipient
  /// @param amount The amount being transferred
  /// @param index The new interest index of the pool
  event BalanceTransfer(address indexed account, address indexed to, uint256 amount, uint256 index);

  /// @notice Returns the address of the underlying asset of this pool tokens (E.g. USDC for pool USDC token)
  /// @return implicitBalance Implicit balance of `account`
  function implicitBalanceOf(address account) external view returns (uint256 implicitBalance);

  /// @notice Returns the address of the underlying asset of this pool tokens (E.g. USDC for pool USDC token)
  /// @return implicitTotalSupply_ Implicit total supply of the pool token
  function implicitTotalSupply() external view returns (uint256 implicitTotalSupply_);
}