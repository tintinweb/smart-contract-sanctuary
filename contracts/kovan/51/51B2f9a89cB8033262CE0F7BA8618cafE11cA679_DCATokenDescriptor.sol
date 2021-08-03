// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.6;
pragma abicoder v2;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '../interfaces/IDCAGlobalParameters.sol';
import '../interfaces/IDCAPair.sol';
import '../libraries/NFTDescriptor.sol';

/// @title Describes NFT token positions
/// @notice Produces a string containing the data URI for a JSON metadata string
contract DCATokenDescriptor is IDCATokenDescriptor {
  function tokenURI(IDCAPairPositionHandler _positionHandler, uint256 _tokenId) external view override returns (string memory) {
    IERC20Metadata _tokenA = _positionHandler.tokenA();
    IERC20Metadata _tokenB = _positionHandler.tokenB();
    IDCAGlobalParameters _globalParameters = _positionHandler.globalParameters();
    IDCAPairPositionHandler.UserPosition memory _userPosition = _positionHandler.userPosition(_tokenId);

    return
      NFTDescriptor.constructTokenURI(
        NFTDescriptor.ConstructTokenURIParams({
          tokenId: _tokenId,
          pair: address(_positionHandler),
          tokenA: address(_tokenA),
          tokenB: address(_tokenB),
          tokenADecimals: _tokenA.decimals(),
          tokenBDecimals: _tokenB.decimals(),
          tokenASymbol: _tokenA.symbol(),
          tokenBSymbol: _tokenB.symbol(),
          swapInterval: _globalParameters.intervalDescription(_userPosition.swapInterval),
          swapsExecuted: _userPosition.swapsExecuted,
          swapped: _userPosition.swapped,
          swapsLeft: _userPosition.swapsLeft,
          remaining: _userPosition.remaining,
          rate: _userPosition.rate,
          fromA: _userPosition.from == _tokenA
        })
      );
  }
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.6;

import './ITimeWeightedOracle.sol';
import './IDCATokenDescriptor.sol';

/// @title The interface for handling parameters the affect the whole DCA ecosystem
/// @notice This contract will manage configuration that affects all pairs, swappers, etc
interface IDCAGlobalParameters {
  /// @notice A compilation of all parameters that affect a swap
  struct SwapParameters {
    // The address of the fee recipient
    address feeRecipient;
    // Whether swaps are paused or not
    bool isPaused;
    // The swap fee
    uint32 swapFee;
    // The oracle contract
    ITimeWeightedOracle oracle;
  }

  /// @notice A compilation of all parameters that affect a loan
  struct LoanParameters {
    // The address of the fee recipient
    address feeRecipient;
    // Whether loans are paused or not
    bool isPaused;
    // The loan fee
    uint32 loanFee;
  }

  /// @notice Emitted when a new fee recipient is set
  /// @param _feeRecipient The address of the new fee recipient
  event FeeRecipientSet(address _feeRecipient);

  /// @notice Emitted when a new NFT descriptor is set
  /// @param _descriptor The new NFT descriptor contract
  event NFTDescriptorSet(IDCATokenDescriptor _descriptor);

  /// @notice Emitted when a new oracle is set
  /// @param _oracle The new oracle contract
  event OracleSet(ITimeWeightedOracle _oracle);

  /// @notice Emitted when a new swap fee is set
  /// @param _feeSet The new swap fee
  event SwapFeeSet(uint32 _feeSet);

  /// @notice Emitted when a new loan fee is set
  /// @param _feeSet The new loan fee
  event LoanFeeSet(uint32 _feeSet);

  /// @notice Emitted when new swap intervals are allowed
  /// @param _swapIntervals The new swap intervals
  /// @param _descriptions The descriptions for each swap interval
  event SwapIntervalsAllowed(uint32[] _swapIntervals, string[] _descriptions);

  /// @notice Emitted when some swap intervals are no longer allowed
  /// @param _swapIntervals The swap intervals that are no longer allowed
  event SwapIntervalsForbidden(uint32[] _swapIntervals);

  /// @notice Thrown when trying to set a fee higher than the maximum allowed
  error HighFee();

  /// @notice Thrown when trying to support new swap intervals, but the amount of descriptions doesn't match
  error InvalidParams();

  /// @notice Thrown when trying to support a new swap interval of value zero
  error ZeroInterval();

  /// @notice Thrown when trying a description for a new swap interval is empty
  error EmptyDescription();

  /// @notice Returns the address of the fee recipient
  /// @return _feeRecipient The address of the fee recipient
  function feeRecipient() external view returns (address _feeRecipient);

  /// @notice Returns fee charged on swaps
  /// @return _swapFee The fee itself
  function swapFee() external view returns (uint32 _swapFee);

  /// @notice Returns fee charged on loans
  /// @return _loanFee The fee itself
  function loanFee() external view returns (uint32 _loanFee);

  /// @notice Returns the NFT descriptor contract
  /// @return _nftDescriptor The contract itself
  function nftDescriptor() external view returns (IDCATokenDescriptor _nftDescriptor);

  /// @notice Returns the time-weighted oracle contract
  /// @return _oracle The contract itself
  function oracle() external view returns (ITimeWeightedOracle _oracle);

  /// @notice Returns the precision used for fees
  /// @dev Cannot be modified
  /// @return _precision The precision used for fees
  // solhint-disable-next-line func-name-mixedcase
  function FEE_PRECISION() external view returns (uint24 _precision);

  /// @notice Returns the max fee that can be set for either swap or loans
  /// @dev Cannot be modified
  /// @return _maxFee The maximum possible fee
  // solhint-disable-next-line func-name-mixedcase
  function MAX_FEE() external view returns (uint32 _maxFee);

  /// @notice Returns a list of all the allowed swap intervals
  /// @return _allowedSwapIntervals An array with all allowed swap intervals
  function allowedSwapIntervals() external view returns (uint32[] memory _allowedSwapIntervals);

  /// @notice Returns the description for a given swap interval
  /// @return _description The swap interval's description
  function intervalDescription(uint32 _swapInterval) external view returns (string memory _description);

  /// @notice Returns whether a swap interval is currently allowed
  /// @return _isAllowed Whether the given swap interval is currently allowed
  function isSwapIntervalAllowed(uint32 _swapInterval) external view returns (bool _isAllowed);

  /// @notice Returns whether swaps and loans are currently paused
  /// @return _isPaused Whether swaps and loans are currently paused
  function paused() external view returns (bool _isPaused);

  /// @notice Returns a compilation of all parameters that affect a swap
  /// @return _swapParameters All parameters that affect a swap
  function swapParameters() external view returns (SwapParameters memory _swapParameters);

  /// @notice Returns a compilation of all parameters that affect a loan
  /// @return _loanParameters All parameters that affect a loan
  function loanParameters() external view returns (LoanParameters memory _loanParameters);

  /// @notice Sets a new fee recipient address
  /// @dev Will revert with ZeroAddress if the zero address is passed
  /// @param _feeRecipient The new fee recipient address
  function setFeeRecipient(address _feeRecipient) external;

  /// @notice Sets a new swap fee
  /// @dev Will rever with HighFee if the fee is higher than the maximum
  /// @param _fee The new swap fee
  function setSwapFee(uint32 _fee) external;

  /// @notice Sets a new loan fee
  /// @dev Will rever with HighFee if the fee is higher than the maximum
  /// @param _fee The new loan fee
  function setLoanFee(uint32 _fee) external;

  /// @notice Sets a new NFT descriptor
  /// @dev Will revert with ZeroAddress if the zero address is passed
  /// @param _descriptor The new descriptor contract
  function setNFTDescriptor(IDCATokenDescriptor _descriptor) external;

  /// @notice Sets a new time-weighted oracle
  /// @dev Will revert with ZeroAddress if the zero address is passed
  /// @param _oracle The new oracle contract
  function setOracle(ITimeWeightedOracle _oracle) external;

  /// @notice Adds new swap intervals to the allowed list
  /// @dev Will revert with:
  /// InvalidParams if the amount of swap intervals is different from the amount of descriptions passed
  /// ZeroInterval if any of the swap intervals is zero
  /// EmptyDescription if any of the descriptions is empty
  /// @param _swapIntervals The new swap intervals
  /// @param _descriptions Their descriptions
  function addSwapIntervalsToAllowedList(uint32[] calldata _swapIntervals, string[] calldata _descriptions) external;

  /// @notice Removes some swap intervals from the allowed list
  /// @param _swapIntervals The swap intervals to remove
  function removeSwapIntervalsFromAllowedList(uint32[] calldata _swapIntervals) external;

  /// @notice Pauses all swaps and loans
  function pause() external;

  /// @notice Unpauses all swaps and loans
  function unpause() external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.6;

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import './IDCAGlobalParameters.sol';

/// @title The interface for all state related queries
/// @notice These methods allow users to read the pair's current values
interface IDCAPairParameters {
  /// @notice Returns the global parameters contract
  /// @dev Global parameters has information about swaps and pairs, like swap intervals, fees charged, etc.
  /// @return The Global Parameters contract
  function globalParameters() external view returns (IDCAGlobalParameters);

  /// @notice Returns the token A contract
  /// @return The contract for token A
  function tokenA() external view returns (IERC20Metadata);

  /// @notice Returns the token B contract
  /// @return The contract for token B
  function tokenB() external view returns (IERC20Metadata);

  /// @notice Returns how much will the amount to swap differ from the previous swap
  /// @dev f.e. if the returned value is -100, then the amount to swap will be 100 less than the swap just before it
  /// @param _swapInterval The swap interval to check
  /// @param _from The 'from' token of the deposits
  /// @param _swap The swap number to check
  /// @return _delta How much will the amount to swap differ, when compared to the swap just before this one
  function swapAmountDelta(
    uint32 _swapInterval,
    address _from,
    uint32 _swap
  ) external view returns (int256 _delta);

  /// @notice Returns if a certain swap interval is active or not
  /// @dev We consider a swap interval to be active if there is at least one active position on that interval
  /// @param _swapInterval The swap interval to check
  /// @return _isActive Whether the given swap interval is currently active
  function isSwapIntervalActive(uint32 _swapInterval) external view returns (bool _isActive);

  /// @notice Returns the amount of swaps executed for a certain interval
  /// @param _swapInterval The swap interval to check
  /// @return _swaps The amount of swaps performed on the given interval
  function performedSwaps(uint32 _swapInterval) external view returns (uint32 _swaps);
}

/// @title The interface for all position related matters in a DCA pair
/// @notice These methods allow users to create, modify and terminate their positions
interface IDCAPairPositionHandler is IDCAPairParameters {
  /// @notice The position of a certain user
  struct UserPosition {
    // The token that the user deposited and will be swapped in exchange for "to"
    IERC20Metadata from;
    // The token that the user will get in exchange for their "from" tokens in each swap
    IERC20Metadata to;
    // How frequently the position's swaps should be executed
    uint32 swapInterval;
    // How many swaps were executed since deposit, last modification, or last withdraw
    uint32 swapsExecuted;
    // How many "to" tokens can currently be withdrawn
    uint256 swapped;
    // How many swaps left the position has to execute
    uint32 swapsLeft;
    // How many "from" tokens there are left to swap
    uint256 remaining;
    // How many "from" tokens need to be traded in each swap
    uint160 rate;
  }

  /// @notice Emitted when a position is terminated
  /// @param _user The address of the user that terminated the position
  /// @param _dcaId The id of the position that was terminated
  /// @param _returnedUnswapped How many "from" tokens were returned to the caller
  /// @param _returnedSwapped How many "to" tokens were returned to the caller
  event Terminated(address indexed _user, uint256 _dcaId, uint256 _returnedUnswapped, uint256 _returnedSwapped);

  /// @notice Emitted when a position is created
  /// @param _user The address of the user that created the position
  /// @param _dcaId The id of the position that was created
  /// @param _fromToken The address of the "from" token
  /// @param _rate How many "from" tokens need to be traded in each swap
  /// @param _startingSwap The number of the swap when the position will be executed for the first time
  /// @param _swapInterval How frequently the position's swaps should be executed
  /// @param _lastSwap The number of the swap when the position will be executed for the last time
  event Deposited(
    address indexed _user,
    uint256 _dcaId,
    address _fromToken,
    uint160 _rate,
    uint32 _startingSwap,
    uint32 _swapInterval,
    uint32 _lastSwap
  );

  /// @notice Emitted when a user withdraws all swapped tokens from a position
  /// @param _user The address of the user that executed the withdraw
  /// @param _dcaId The id of the position that was affected
  /// @param _token The address of the withdrawn tokens. It's the same as the position's "to" token
  /// @param _amount The amount that was withdrawn
  event Withdrew(address indexed _user, uint256 _dcaId, address _token, uint256 _amount);

  /// @notice Emitted when a user withdraws all swapped tokens from many positions
  /// @param _user The address of the user that executed the withdraw
  /// @param _dcaIds The ids of the positions that were affected
  /// @param _swappedTokenA The total amount that was withdrawn in token A
  /// @param _swappedTokenB The total amount that was withdrawn in token B
  event WithdrewMany(address indexed _user, uint256[] _dcaIds, uint256 _swappedTokenA, uint256 _swappedTokenB);

  /// @notice Emitted when a position is modified
  /// @param _user The address of the user that modified the position
  /// @param _dcaId The id of the position that was modified
  /// @param _rate How many "from" tokens need to be traded in each swap
  /// @param _startingSwap The number of the swap when the position will be executed for the first time
  /// @param _lastSwap The number of the swap when the position will be executed for the last time
  event Modified(address indexed _user, uint256 _dcaId, uint160 _rate, uint32 _startingSwap, uint32 _lastSwap);

  /// @notice Thrown when a user tries to create a position with a token that is neither token A nor token B
  error InvalidToken();

  /// @notice Thrown when a user tries to create that a position with an unsupported swap interval
  error InvalidInterval();

  /// @notice Thrown when a user tries operate on a position that doesn't exist (it might have been already terminated)
  error InvalidPosition();

  /// @notice Thrown when a user tries operate on a position that they don't have access to
  error UnauthorizedCaller();

  /// @notice Thrown when a user tries to create or modify a position by setting the rate to be zero
  error ZeroRate();

  /// @notice Thrown when a user tries to create a position with zero swaps
  error ZeroSwaps();

  /// @notice Thrown when a user tries to add zero funds to their position
  error ZeroAmount();

  /// @notice Thrown when a user tries to modify the rate of a position that has already been completed
  error PositionCompleted();

  /// @notice Thrown when a user tries to modify a position that has too much swapped balance. This error
  /// is thrown so that the user doesn't lose any funds. The error indicates that the user must perform a withdraw
  /// before modifying their position
  error MandatoryWithdraw();

  /// @notice Returns a DCA position
  /// @param _dcaId The id of the position
  /// @return _position The position itself
  function userPosition(uint256 _dcaId) external view returns (UserPosition memory _position);

  /// @notice Creates a new position
  /// @dev Will revert:
  /// With InvalidToken if _tokenAddress is neither token A nor token B
  /// With ZeroRate if _rate is zero
  /// With ZeroSwaps if _amountOfSwaps is zero
  /// With InvalidInterval if _swapInterval is not a valid swap interval
  /// @param _tokenAddress The address of the token that will be deposited
  /// @param _rate How many "from" tokens need to be traded in each swap
  /// @param _amountOfSwaps How many swaps to execute for this position
  /// @param _swapInterval How frequently the position's swaps should be executed
  /// @return _dcaId The id of the created position
  function deposit(
    address _tokenAddress,
    uint160 _rate,
    uint32 _amountOfSwaps,
    uint32 _swapInterval
  ) external returns (uint256 _dcaId);

  /// @notice Withdraws all swapped tokens from a position
  /// @dev Will revert:
  /// With InvalidPosition if _dcaId is invalid
  /// With UnauthorizedCaller if the caller doesn't have access to the position
  /// @param _dcaId The position's id
  /// @return _swapped How much was withdrawn
  function withdrawSwapped(uint256 _dcaId) external returns (uint256 _swapped);

  /// @notice Withdraws all swapped tokens from many positions
  /// @dev Will revert:
  /// With InvalidPosition if any of the ids in _dcaIds is invalid
  /// With UnauthorizedCaller if the caller doesn't have access to any of the positions in _dcaIds
  /// @param _dcaIds The positions' ids
  /// @return _swappedTokenA How much was withdrawn in token A
  /// @return _swappedTokenB How much was withdrawn in token B
  function withdrawSwappedMany(uint256[] calldata _dcaIds) external returns (uint256 _swappedTokenA, uint256 _swappedTokenB);

  /// @notice Modifies the rate of a position. Could request more funds or return deposited funds
  /// depending on whether the new rate is greater than the previous one.
  /// @dev Will revert:
  /// With InvalidPosition if _dcaId is invalid
  /// With UnauthorizedCaller if the caller doesn't have access to the position
  /// With PositionCompleted if position has already been completed
  /// With ZeroRate if _newRate is zero
  /// With MandatoryWithdraw if the user must execute a withdraw before modifying their position
  /// @param _dcaId The position's id
  /// @param _newRate The new rate to set
  function modifyRate(uint256 _dcaId, uint160 _newRate) external;

  /// @notice Modifies the amount of swaps of a position. Could request more funds or return
  /// deposited funds depending on whether the new amount of swaps is greater than the swaps left.
  /// @dev Will revert:
  /// With InvalidPosition if _dcaId is invalid
  /// With UnauthorizedCaller if the caller doesn't have access to the position
  /// With MandatoryWithdraw if the user must execute a withdraw before modifying their position
  /// @param _dcaId The position's id
  /// @param _newSwaps The new amount of swaps
  function modifySwaps(uint256 _dcaId, uint32 _newSwaps) external;

  /// @notice Modifies both the rate and amount of swaps of a position. Could request more funds or return
  /// deposited funds depending on whether the new parameters require more or less than the the unswapped funds.
  /// @dev Will revert:
  /// With InvalidPosition if _dcaId is invalid
  /// With UnauthorizedCaller if the caller doesn't have access to the position
  /// With ZeroRate if _newRate is zero
  /// With MandatoryWithdraw if the user must execute a withdraw before modifying their position
  /// @param _dcaId The position's id
  /// @param _newRate The new rate to set
  /// @param _newSwaps The new amount of swaps
  function modifyRateAndSwaps(
    uint256 _dcaId,
    uint160 _newRate,
    uint32 _newSwaps
  ) external;

  /// @notice Takes the unswapped balance, adds the new deposited funds and modifies the position so that
  /// it is executed in _newSwaps swaps
  /// @dev Will revert:
  /// With InvalidPosition if _dcaId is invalid
  /// With UnauthorizedCaller if the caller doesn't have access to the position
  /// With ZeroAmount if _amount is zero
  /// With ZeroSwaps if _newSwaps is zero
  /// With MandatoryWithdraw if the user must execute a withdraw before modifying their position
  /// @param _dcaId The position's id
  /// @param _amount Amounts of funds to add to the position
  /// @param _newSwaps The new amount of swaps
  function addFundsToPosition(
    uint256 _dcaId,
    uint256 _amount,
    uint32 _newSwaps
  ) external;

  /// @notice Terminates the position and sends all unswapped and swapped balance to the caller
  /// @dev Will revert:
  /// With InvalidPosition if _dcaId is invalid
  /// With UnauthorizedCaller if the caller doesn't have access to the position
  /// @param _dcaId The position's id
  function terminate(uint256 _dcaId) external;
}

/// @title The interface for all swap related matters in a DCA pair
/// @notice These methods allow users to get information about the next swap, and how to execute it
interface IDCAPairSwapHandler {
  /// @notice Information about an available swap for a specific swap interval
  struct SwapInformation {
    // The affected swap interval
    uint32 interval;
    // The number of the swap that will be performed
    uint32 swapToPerform;
    // The amount of token A that needs swapping
    uint256 amountToSwapTokenA;
    // The amount of token B that needs swapping
    uint256 amountToSwapTokenB;
  }

  /// @notice All information about the next swap
  struct NextSwapInformation {
    // All swaps that can be executed
    SwapInformation[] swapsToPerform;
    // How many entries of the swapsToPerform array are valid
    uint8 amountOfSwaps;
    // How much can be borrowed in token A during a flash swap
    uint256 availableToBorrowTokenA;
    // How much can be borrowed in token B during a flash swap
    uint256 availableToBorrowTokenB;
    // How much 10**decimals(tokenB) is when converted to token A
    uint256 ratePerUnitBToA;
    // How much 10**decimals(tokenA) is when converted to token B
    uint256 ratePerUnitAToB;
    // How much token A will be sent to the platform in terms of fee
    uint256 platformFeeTokenA;
    // How much token B will be sent to the platform in terms of fee
    uint256 platformFeeTokenB;
    // The amount of tokens that need to be provided by the swapper
    uint256 amountToBeProvidedBySwapper;
    // The amount of tokens that will be sent to the swapper optimistically
    uint256 amountToRewardSwapperWith;
    // The token that needs to be provided by the swapper
    IERC20Metadata tokenToBeProvidedBySwapper;
    // The token that will be sent to the swapper optimistically
    IERC20Metadata tokenToRewardSwapperWith;
  }

  /// @notice Emitted when a swap is executed
  /// @param _sender The address of the user that initiated the swap
  /// @param _to The address that received the reward + loan
  /// @param _amountBorrowedTokenA How much was borrowed in token A
  /// @param _amountBorrowedTokenB How much was borrowed in token B
  /// @param _fee How much was charged as a swap fee to position owners
  /// @param _nextSwapInformation All information related to the swap
  event Swapped(
    address indexed _sender,
    address indexed _to,
    uint256 _amountBorrowedTokenA,
    uint256 _amountBorrowedTokenB,
    uint32 _fee,
    NextSwapInformation _nextSwapInformation
  );

  /// @notice Thrown when trying to execute a swap, but none is available
  error NoSwapsToExecute();

  /// @notice Returns when the next swap will be available for a given swap interval
  /// @param _swapInterval The swap interval to check
  /// @return _when The moment when the next swap will be available. Take into account that if the swap is already available, this result could
  /// be in the past
  function nextSwapAvailable(uint32 _swapInterval) external view returns (uint32 _when);

  /// @notice Returns the amount of tokens that needed swapping in the last swap, for all positions in the given swap interval that were deposited in the given token
  /// @param _swapInterval The swap interval to check
  /// @param _from The address of the token that all positions used to deposit
  /// @return _amount The amount that needed swapping in the last swap
  function swapAmountAccumulator(uint32 _swapInterval, address _from) external view returns (uint256);

  /// @notice Returns all information related to the next swap
  /// @return _nextSwapInformation The information about the next swap
  function getNextSwapInfo() external view returns (NextSwapInformation memory _nextSwapInformation);

  /// @notice Executes a swap
  /// @dev This method assumes that the required amount has already been sent. Will revert with:
  /// Paused if swaps are paused by protocol
  /// NoSwapsToExecute if there are no swaps to execute
  /// LiquidityNotReturned if the required tokens were not sent before calling the function
  function swap() external;

  /// @notice Executes a flash swap
  /// @dev Will revert with:
  /// Paused if swaps are paused by protocol
  /// NoSwapsToExecute if there are no swaps to execute
  /// InsufficientLiquidity if asked to borrow more than the actual reserves
  /// LiquidityNotReturned if the required tokens were not back during the callback
  /// @param _amountToBorrowTokenA How much to borrow in token A
  /// @param _amountToBorrowTokenB How much to borrow in token B
  /// @param _to Address to send the reward + the borrowed tokens
  /// @param _data Bytes to send to the caller during the callback. If this parameter is empty, the callback won't be executed
  function swap(
    uint256 _amountToBorrowTokenA,
    uint256 _amountToBorrowTokenB,
    address _to,
    bytes calldata _data
  ) external;

  /// @notice Returns how many seconds left until the next swap is available
  /// @return _secondsUntilNextSwap The amount of seconds until next swap. Returns 0 if a swap can already be executed
  function secondsUntilNextSwap() external view returns (uint32 _secondsUntilNextSwap);
}

/// @title The interface for all loan related matters in a DCA pair
/// @notice These methods allow users to ask how much is available for loans, and also to execute them
interface IDCAPairLoanHandler {
  /// @notice Emitted when a flash loan is executed
  /// @param _sender The address of the user that initiated the loan
  /// @param _to The address that received the loan
  /// @param _amountBorrowedTokenA How much was borrowed in token A
  /// @param _amountBorrowedTokenB How much was borrowed in token B
  /// @param _loanFee How much was charged as a fee
  event Loaned(address indexed _sender, address indexed _to, uint256 _amountBorrowedTokenA, uint256 _amountBorrowedTokenB, uint32 _loanFee);

  // @notice Thrown when trying to execute a flash loan but without actually asking for tokens
  error ZeroLoan();

  /// @notice Returns the amount of tokens that can be asked for during a flash loan
  /// @return _amountToBorrowTokenA The amount of token A that is available for borrowing
  /// @return _amountToBorrowTokenB The amount of token B that is available for borrowing
  function availableToBorrow() external view returns (uint256 _amountToBorrowTokenA, uint256 _amountToBorrowTokenB);

  /// @notice Executes a flash loan, sending the required amounts to the specified loan recipient
  /// @dev Will revert:
  /// With ZeroLoan if both _amountToBorrowTokenA & _amountToBorrowTokenB are 0
  /// With Paused if loans are paused by protocol
  /// With InsufficientLiquidity if asked for more that reserves
  /// @param _amountToBorrowTokenA The amount to borrow in token A
  /// @param _amountToBorrowTokenB The amount to borrow in token B
  /// @param _to Address that will receive the loan. This address should be a contract that implements IDCAPairLoanCallee
  /// @param _data Any data that should be passed through to the callback
  function loan(
    uint256 _amountToBorrowTokenA,
    uint256 _amountToBorrowTokenB,
    address _to,
    bytes calldata _data
  ) external;
}

interface IDCAPair is IDCAPairParameters, IDCAPairSwapHandler, IDCAPairPositionHandler, IDCAPairLoanHandler {}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.0;
pragma abicoder v2;

import '@openzeppelin/contracts/utils/Strings.sol';
import 'base64-sol/base64.sol';
import './NFTSVG.sol';

// Based on Uniswap's NFTDescriptor
library NFTDescriptor {
  using Strings for uint256;
  using Strings for uint32;

  struct ConstructTokenURIParams {
    address pair;
    address tokenA;
    address tokenB;
    uint8 tokenADecimals;
    uint8 tokenBDecimals;
    string tokenASymbol;
    string tokenBSymbol;
    string swapInterval;
    uint32 swapsExecuted;
    uint32 swapsLeft;
    uint256 tokenId;
    uint256 swapped;
    uint256 remaining;
    uint160 rate;
    bool fromA;
  }

  function constructTokenURI(ConstructTokenURIParams memory _params) internal pure returns (string memory) {
    string memory _name = _generateName(_params);

    string memory _description = _generateDescription(
      _params.tokenASymbol,
      _params.tokenBSymbol,
      addressToString(_params.pair),
      addressToString(_params.tokenA),
      addressToString(_params.tokenB),
      _params.swapInterval,
      _params.tokenId
    );

    string memory _image = Base64.encode(bytes(_generateSVGImage(_params)));

    return
      string(
        abi.encodePacked(
          'data:application/json;base64,',
          Base64.encode(
            bytes(
              abi.encodePacked(
                '{"name":"',
                _name,
                '", "description":"',
                _description,
                '", "image": "',
                'data:image/svg+xml;base64,',
                _image,
                '"}'
              )
            )
          )
        )
      );
  }

  function _escapeQuotes(string memory _symbol) private pure returns (string memory) {
    bytes memory symbolBytes = bytes(_symbol);
    uint8 quotesCount = 0;
    for (uint8 i = 0; i < symbolBytes.length; i++) {
      if (symbolBytes[i] == '"') {
        quotesCount++;
      }
    }
    if (quotesCount > 0) {
      bytes memory escapedBytes = new bytes(symbolBytes.length + (quotesCount));
      uint256 index;
      for (uint8 i = 0; i < symbolBytes.length; i++) {
        if (symbolBytes[i] == '"') {
          escapedBytes[index++] = '\\';
        }
        escapedBytes[index++] = symbolBytes[i];
      }
      return string(escapedBytes);
    }
    return _symbol;
  }

  function _generateDescription(
    string memory _tokenASymbol,
    string memory _tokenBSymbol,
    string memory _pairAddress,
    string memory _tokenAAddress,
    string memory _tokenBAddress,
    string memory _interval,
    uint256 _tokenId
  ) private pure returns (string memory) {
    string memory _part1 = string(
      abi.encodePacked(
        'This NFT represents a position in a Mean Finance DCA ',
        _escapeQuotes(_tokenASymbol),
        '-',
        _escapeQuotes(_tokenBSymbol),
        ' pair. ',
        'The owner of this NFT can modify or redeem the position.\\n',
        '\\nPair Address: ',
        _pairAddress,
        '\\n',
        _escapeQuotes(_tokenASymbol)
      )
    );
    string memory _part2 = string(
      abi.encodePacked(
        ' Address: ',
        _tokenAAddress,
        '\\n',
        _escapeQuotes(_tokenBSymbol),
        ' Address: ',
        _tokenBAddress,
        '\\nSwap interval: ',
        _interval,
        '\\nToken ID: ',
        _tokenId.toString(),
        '\\n\\n',
        unicode'⚠️ DISCLAIMER: Due diligence is imperative when assessing this NFT. Make sure token addresses match the expected tokens, as token symbols may be imitated.'
      )
    );
    return string(abi.encodePacked(_part1, _part2));
  }

  function _generateName(ConstructTokenURIParams memory _params) private pure returns (string memory) {
    return
      string(
        abi.encodePacked(
          'Mean Finance DCA - ',
          _params.swapInterval,
          ' - ',
          _escapeQuotes(_params.tokenASymbol),
          '/',
          _escapeQuotes(_params.tokenBSymbol)
        )
      );
  }

  struct DecimalStringParams {
    // significant figures of decimal
    uint256 sigfigs;
    // length of decimal string
    uint8 bufferLength;
    // ending index for significant figures (funtion works backwards when copying sigfigs)
    uint8 sigfigIndex;
    // index of decimal place (0 if no decimal)
    uint8 decimalIndex;
    // start index for trailing/leading 0's for very small/large numbers
    uint8 zerosStartIndex;
    // end index for trailing/leading 0's for very small/large numbers
    uint8 zerosEndIndex;
    // true if decimal number is less than one
    bool isLessThanOne;
  }

  function _generateDecimalString(DecimalStringParams memory params) private pure returns (string memory) {
    bytes memory buffer = new bytes(params.bufferLength);
    if (params.isLessThanOne) {
      buffer[0] = '0';
      buffer[1] = '.';
    }

    // add leading/trailing 0's
    for (uint256 zerosCursor = params.zerosStartIndex; zerosCursor < params.zerosEndIndex + 1; zerosCursor++) {
      buffer[zerosCursor] = bytes1(uint8(48));
    }
    // add sigfigs
    while (params.sigfigs > 0) {
      if (params.decimalIndex > 0 && params.sigfigIndex == params.decimalIndex) {
        buffer[params.sigfigIndex--] = '.';
      }
      uint8 charIndex = uint8(48 + (params.sigfigs % 10));
      buffer[params.sigfigIndex] = bytes1(charIndex);
      params.sigfigs /= 10;
      if (params.sigfigs > 0) {
        params.sigfigIndex--;
      }
    }
    return string(buffer);
  }

  function _sigfigsRounded(uint256 value, uint8 digits) private pure returns (uint256, bool) {
    bool extraDigit;
    if (digits > 5) {
      value = value / (10**(digits - 5));
    }
    bool roundUp = value % 10 > 4;
    value = value / 10;
    if (roundUp) {
      value = value + 1;
    }
    // 99999 -> 100000 gives an extra sigfig
    if (value == 100000) {
      value /= 10;
      extraDigit = true;
    }
    return (value, extraDigit);
  }

  function fixedPointToDecimalString(uint256 value, uint8 decimals) internal pure returns (string memory) {
    if (value == 0) {
      return '0.0000';
    }

    bool priceBelow1 = value < 10**decimals;

    // get digit count
    uint256 temp = value;
    uint8 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    // don't count extra digit kept for rounding
    digits = digits - 1;

    // address rounding
    (uint256 sigfigs, bool extraDigit) = _sigfigsRounded(value, digits);
    if (extraDigit) {
      digits++;
    }

    DecimalStringParams memory params;
    if (priceBelow1) {
      // 7 bytes ( "0." and 5 sigfigs) + leading 0's bytes
      params.bufferLength = uint8(digits >= 5 ? decimals - digits + 6 : decimals + 2);
      params.zerosStartIndex = 2;
      params.zerosEndIndex = uint8(decimals - digits + 1);
      params.sigfigIndex = uint8(params.bufferLength - 1);
    } else if (digits >= decimals + 4) {
      // no decimal in price string
      params.bufferLength = uint8(digits - decimals + 1);
      params.zerosStartIndex = 5;
      params.zerosEndIndex = uint8(params.bufferLength - 1);
      params.sigfigIndex = 4;
    } else {
      // 5 sigfigs surround decimal
      params.bufferLength = 6;
      params.sigfigIndex = 5;
      params.decimalIndex = uint8(digits - decimals + 1);
    }
    params.sigfigs = sigfigs;
    params.isLessThanOne = priceBelow1;

    return _generateDecimalString(params);
  }

  function addressToString(address _addr) internal pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint256 i = 0; i < 20; i++) {
      bytes1 b = bytes1(uint8(uint256(uint160(_addr)) / (2**(8 * (19 - i)))));
      bytes1 hi = bytes1(uint8(b) / 16);
      bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
      s[2 * i] = _char(hi);
      s[2 * i + 1] = _char(lo);
    }
    return string(abi.encodePacked('0x', string(s)));
  }

  function _char(bytes1 b) private pure returns (bytes1 c) {
    if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
    else return bytes1(uint8(b) + 0x57);
  }

  function _generateSVGImage(ConstructTokenURIParams memory _params) private pure returns (string memory svg) {
    string memory _fromSymbol;
    string memory _toSymbol;
    uint8 _fromDecimals;
    uint8 _toDecimals;
    if (_params.fromA) {
      _fromSymbol = _escapeQuotes(_params.tokenASymbol);
      _fromDecimals = _params.tokenADecimals;
      _toSymbol = _escapeQuotes(_params.tokenBSymbol);
      _toDecimals = _params.tokenBDecimals;
    } else {
      _fromSymbol = _escapeQuotes(_params.tokenBSymbol);
      _fromDecimals = _params.tokenBDecimals;
      _toSymbol = _escapeQuotes(_params.tokenASymbol);
      _toDecimals = _params.tokenADecimals;
    }
    NFTSVG.SVGParams memory _svgParams = NFTSVG.SVGParams({
      tokenId: _params.tokenId,
      tokenA: addressToString(_params.tokenA),
      tokenB: addressToString(_params.tokenB),
      tokenASymbol: _escapeQuotes(_params.tokenASymbol),
      tokenBSymbol: _escapeQuotes(_params.tokenBSymbol),
      interval: _params.swapInterval,
      swapsExecuted: _params.swapsExecuted,
      swapsLeft: _params.swapsLeft,
      swapped: string(abi.encodePacked(fixedPointToDecimalString(_params.swapped, _toDecimals), ' ', _toSymbol)),
      averagePrice: string(
        abi.encodePacked(
          fixedPointToDecimalString(_params.swapsExecuted > 0 ? _params.swapped / _params.swapsExecuted : 0, _toDecimals),
          ' ',
          _toSymbol
        )
      ),
      remaining: string(abi.encodePacked(fixedPointToDecimalString(_params.remaining, _fromDecimals), ' ', _fromSymbol)),
      rate: string(abi.encodePacked(fixedPointToDecimalString(_params.rate, _fromDecimals), ' ', _fromSymbol))
    });

    return NFTSVG.generateSVG(_svgParams);
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import '@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol';

/// @title The interface for an oracle that provies TWAP quotes
/// @notice These methods allow users to add support for pairs, and then ask for quotes
interface ITimeWeightedOracle {
  /// @notice Emitted when the oracle add supports for a new pair
  /// @param _tokenA One of the pair's tokens
  /// @param _tokenB The other of the pair's tokens
  event AddedSupportForPair(address _tokenA, address _tokenB);

  /// @notice Returns whether this oracle can support this pair of tokens
  /// @dev _tokenA and _tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
  /// @param _tokenA One of the pair's tokens
  /// @param _tokenB The other of the pair's tokens
  /// @return _canSupport Whether the given pair of tokens can be supported by the oracle
  function canSupportPair(address _tokenA, address _tokenB) external view returns (bool _canSupport);

  /// @notice Returns a quote, based on the given tokens and amount
  /// @param _tokenIn The token that will be provided
  /// @param _amountIn The amount that will be provided
  /// @param _tokenOut The token we would like to quote
  /// @return _amountOut How much _tokenOut will be returned in exchange for _amountIn amount of _tokenIn
  function quote(
    address _tokenIn,
    uint128 _amountIn,
    address _tokenOut
  ) external view returns (uint256 _amountOut);

  /// @notice Add support for a given pair to the contract. This function will let the oracle take some actions to
  /// configure the pair for future quotes. Could be called more than one in order to let the oracle re-configure for a new context.
  /// @dev Will revert if pair cannot be supported. _tokenA and _tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
  /// @param _tokenA One of the pair's tokens
  /// @param _tokenB The other of the pair's tokens
  function addSupportForPair(address _tokenA, address _tokenB) external;
}

/// @title An implementation of ITimeWeightedOracle that uses Uniswap V3 pool oracles
/// @notice This oracle will attempt to use all fee tiers of the same pair when calculating quotes
interface IUniswapV3OracleAggregator is ITimeWeightedOracle {
  /// @notice Emitted when a new fee tier is added
  /// @return _feeTier The added fee tier
  event AddedFeeTier(uint24 _feeTier);

  /// @notice Emitted when a new period is set
  /// @return _period The new period
  event PeriodChanged(uint32 _period);

  /// @notice Returns the Uniswap V3 Factory
  /// @return _factory The Uniswap V3 Factory
  function factory() external view returns (IUniswapV3Factory _factory);

  /// @notice Returns a list of all supported Uniswap V3 fee tiers
  /// @return _feeTiers An array of all supported fee tiers
  function supportedFeeTiers() external view returns (uint24[] memory _feeTiers);

  /// @notice Returns a list of all Uniswap V3 pools used for a given pair
  /// @dev _tokenA and _tokenB may be passed in either tokenA/tokenB or tokenB/tokenA order
  /// @return _pools An array with all pools used for quoting the given pair
  function poolsUsedForPair(address _tokenA, address _tokenB) external view returns (address[] memory _pools);

  /// @notice Returns the period used for the TWAP calculation
  /// @return _period The period used for the TWAP
  function period() external view returns (uint16 _period);

  /// @notice Returns minimum possible period
  /// @dev Cannot be modified
  /// @return The minimum possible period
  // solhint-disable-next-line func-name-mixedcase
  function MINIMUM_PERIOD() external view returns (uint16);

  /// @notice Returns maximum possible period
  /// @dev Cannot be modified
  /// @return The maximum possible period
  // solhint-disable-next-line func-name-mixedcase
  function MAXIMUM_PERIOD() external view returns (uint16);

  /// @notice Returns the minimum liquidity that a pool needs to have in order to be used for a pair's quote
  /// @dev This check is only performed when adding support for a pair. If the pool's liquidity then
  /// goes below the threshold, then it will still be used for the quote calculation
  /// @return The minimum liquidity threshold
  // solhint-disable-next-line func-name-mixedcase
  function MINIMUM_LIQUIDITY_THRESHOLD() external view returns (uint16);

  /// @notice Adds support for a new Uniswap V3 fee tier
  /// @dev Will revert if the provided fee tier is not supported by Uniswap V3
  /// @param _feeTier The new fee tier
  function addFeeTier(uint24 _feeTier) external;

  /// @notice Sets the period to be used for the TWAP calculation
  /// @dev Will revert it is lower than MINIMUM_PERIOD or greater than MAXIMUM_PERIOD
  /// WARNING: increasing the period could cause big problems, because Uniswap V3 pools might not support a TWAP so old.
  /// @param _period The new period
  function setPeriod(uint16 _period) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.6;

import './IDCAPair.sol';

/// @title The interface for generating a token's description
/// @notice Contracts that implement this interface must return a base64 JSON with the entire description
interface IDCATokenDescriptor {
  /// @notice Generates a token's description, both the JSON and the image inside
  /// @param _positionHandler The pair where the position was created
  /// @param _tokenId The token/position id
  /// @return _description The position's description
  function tokenURI(IDCAPairPositionHandler _positionHandler, uint256 _tokenId) external view returns (string memory _description);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title The interface for the Uniswap V3 Factory
/// @notice The Uniswap V3 Factory facilitates creation of Uniswap V3 pools and control over the protocol fees
interface IUniswapV3Factory {
    /// @notice Emitted when the owner of the factory is changed
    /// @param oldOwner The owner before the owner was changed
    /// @param newOwner The owner after the owner was changed
    event OwnerChanged(address indexed oldOwner, address indexed newOwner);

    /// @notice Emitted when a pool is created
    /// @param token0 The first token of the pool by address sort order
    /// @param token1 The second token of the pool by address sort order
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks
    /// @param pool The address of the created pool
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        uint24 indexed fee,
        int24 tickSpacing,
        address pool
    );

    /// @notice Emitted when a new fee amount is enabled for pool creation via the factory
    /// @param fee The enabled fee, denominated in hundredths of a bip
    /// @param tickSpacing The minimum number of ticks between initialized ticks for pools created with the given fee
    event FeeAmountEnabled(uint24 indexed fee, int24 indexed tickSpacing);

    /// @notice Returns the current owner of the factory
    /// @dev Can be changed by the current owner via setOwner
    /// @return The address of the factory owner
    function owner() external view returns (address);

    /// @notice Returns the tick spacing for a given fee amount, if enabled, or 0 if not enabled
    /// @dev A fee amount can never be removed, so this value should be hard coded or cached in the calling context
    /// @param fee The enabled fee, denominated in hundredths of a bip. Returns 0 in case of unenabled fee
    /// @return The tick spacing
    function feeAmountTickSpacing(uint24 fee) external view returns (int24);

    /// @notice Returns the pool address for a given pair of tokens and a fee, or address 0 if it does not exist
    /// @dev tokenA and tokenB may be passed in either token0/token1 or token1/token0 order
    /// @param tokenA The contract address of either token0 or token1
    /// @param tokenB The contract address of the other token
    /// @param fee The fee collected upon every swap in the pool, denominated in hundredths of a bip
    /// @return pool The pool address
    function getPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external view returns (address pool);

    /// @notice Creates a pool for the given two tokens and fee
    /// @param tokenA One of the two tokens in the desired pool
    /// @param tokenB The other of the two tokens in the desired pool
    /// @param fee The desired fee for the pool
    /// @dev tokenA and tokenB may be passed in either order: token0/token1 or token1/token0. tickSpacing is retrieved
    /// from the fee. The call will revert if the pool already exists, the fee is invalid, or the token arguments
    /// are invalid.
    /// @return pool The address of the newly created pool
    function createPool(
        address tokenA,
        address tokenB,
        uint24 fee
    ) external returns (address pool);

    /// @notice Updates the owner of the factory
    /// @dev Must be called by the current owner
    /// @param _owner The new owner of the factory
    function setOwner(address _owner) external;

    /// @notice Enables a fee amount with the given tickSpacing
    /// @dev Fee amounts may never be removed once enabled
    /// @param fee The fee amount to enable, denominated in hundredths of a bip (i.e. 1e-6)
    /// @param tickSpacing The spacing between ticks to be enforced for all pools created with the given fee amount
    function enableFeeAmount(uint24 fee, int24 tickSpacing) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)
            
            // prepare the lookup table
            let tablePtr := add(table, 1)
            
            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            
            // result ptr, jump over length
            let resultPtr := add(result, 32)
            
            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.6;

import '@openzeppelin/contracts/utils/Strings.sol';

/// @title NFTSVG
/// @notice Provides a function for generating an SVG associated with a DCA NFT. Based on Uniswap's NFTDescriptor. Background by bgjar.com
library NFTSVG {
  using Strings for uint256;
  using Strings for uint32;

  struct SVGParams {
    string tokenA;
    string tokenB;
    string tokenASymbol;
    string tokenBSymbol;
    string interval;
    uint32 swapsExecuted;
    uint32 swapsLeft;
    uint256 tokenId;
    string swapped;
    string averagePrice;
    string remaining;
    string rate;
  }

  function generateSVG(SVGParams memory params) internal pure returns (string memory svg) {
    return
      string(
        abi.encodePacked(
          _generateSVGDefs(),
          _generateSVGBorderText(params.tokenA, params.tokenB, params.tokenASymbol, params.tokenBSymbol),
          _generateSVGCardMantle(params.tokenASymbol, params.tokenBSymbol, params.interval),
          _generageSVGProgressArea(params.swapsExecuted, params.swapsLeft),
          _generateSVGPositionData(params.tokenId, params.swapped, params.averagePrice, params.remaining, params.rate),
          '</svg>'
        )
      );
  }

  function _generateSVGDefs() private pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        '<svg width="290" height="560" viewBox="0 0 290 560" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
        '<defs><linearGradient x1="118.1%" y1="10.5%" x2="-18.1%" y2="89.5%" gradientUnits="userSpaceOnUse" id="LinearGradient"><stop stop-color="rgba(13, 5, 20, 1)" offset="0"></stop><stop stop-color="rgba(47, 19, 66, 1)" offset="0.7"></stop><stop stop-color="rgba(35, 17, 51, 1)" offset="1"></stop></linearGradient><clipPath id="corners"><rect width="290" height="560" rx="40" ry="40" /></clipPath><path id="text-path-a" d="M40 12 H250 A28 28 0 0 1 278 40 V520 A28 28 0 0 1 250 548 H40 A28 28 0 0 1 12 520 V40 A28 28 0 0 1 40 12 z" /><mask id="none" maskContentUnits="objectBoundingBox"><rect width="1" height="1" fill="white" /></mask><linearGradient id="grad-symbol"><stop offset="0.8" stop-color="white" stop-opacity="1" /><stop offset=".95" stop-color="white" stop-opacity="0" /></linearGradient><mask id="fade-symbol" maskContentUnits="userSpaceOnUse"><rect width="290px" height="200px" fill="url(#grad-symbol)" /></mask></defs>',
        '<g clip-path="url(#corners)">',
        '<rect width="290" height="560" x="0" y="0" fill="url(#LinearGradient)"></rect>',
        '<path d="M290 0L248.61 0L290 61.48z" fill="rgba(255, 255, 255, .1)"></path>',
        '<path d="M248.61 0L290 61.48L290 189.35999999999999L200.75 0z" fill="rgba(255, 255, 255, .075)"></path>',
        '<path d="M200.75 0L290 189.35999999999999L290 294.91999999999996L112.52 0z" fill="rgba(255, 255, 255, .05)"></path>',
        '<path d="M112.51999999999998 0L290 294.91999999999996L290 357.79999999999995L32.78999999999998 0z" fill="rgba(255, 255, 255, .025)"></path>',
        '<path d="M0 560L40.27 560L0 402.35z" fill="rgba(0, 0, 0, .1)"></path>',
        '<path d="M0 402.35L40.27 560L137.96 560L0 221.89000000000001z" fill="rgba(0, 0, 0, .075)"></path>',
        '<path d="M0 221.89L137.96 560L153.85600000000002 560L0 183.92z" fill="rgba(0, 0, 0, .05)"></path>',
        '<path d="M0 183.91999999999996L153.85000000000002 560L156.66000000000003 560L0 151.61999999999995z" fill="rgba(0, 0, 0, .025)"></path>',
        '</g>'
      )
    );
  }

  function _generateSVGBorderText(
    string memory _tokenA,
    string memory _tokenB,
    string memory _tokenASymbol,
    string memory _tokenBSymbol
  ) private pure returns (string memory svg) {
    string memory _tokenAText = string(abi.encodePacked(_tokenA, unicode' • ', _tokenASymbol));
    string memory _tokenBText = string(abi.encodePacked(_tokenB, unicode' • ', _tokenBSymbol));
    svg = string(
      abi.encodePacked(
        '<text text-rendering="optimizeSpeed"><textPath startOffset="-100%" fill="white" font-family="\'Courier New\', monospace" font-size="10px" xlink:href="#text-path-a">',
        _tokenAText,
        '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /></textPath><textPath startOffset="0%" fill="white" font-family="\'Courier New\', monospace" font-size="10px" xlink:href="#text-path-a">',
        _tokenAText,
        '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /></textPath><textPath startOffset="50%" fill="white" font-family="\'Courier New\', monospace" font-size="10px" xlink:href="#text-path-a">',
        _tokenBText,
        '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /></textPath><textPath startOffset="-50%" fill="white" font-family="\'Courier New\', monospace" font-size="10px" xlink:href="#text-path-a">',
        _tokenBText,
        '<animate additive="sum" attributeName="startOffset" from="0%" to="100%" begin="0s" dur="30s" repeatCount="indefinite" /></textPath></text>'
      )
    );
  }

  function _generateSVGCardMantle(
    string memory _tokenASymbol,
    string memory _tokenBSymbol,
    string memory _interval
  ) private pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        '<g mask="url(#fade-symbol)">'
        '<rect fill="none" x="0px" y="0px" width="290px" height="200px" />'
        '<text y="70px" x="32px" fill="white" font-family="\'Courier New\', monospace" font-weight="200" font-size="35px">',
        _tokenASymbol,
        '/',
        _tokenBSymbol,
        '</text>',
        '<text y="115px" x="32px" fill="white" font-family="\'Courier New\', monospace" font-weight="200" font-size="28px">',
        _interval,
        '</text>'
        '</g>'
      )
    );
  }

  function _generageSVGProgressArea(uint32 _swapsExecuted, uint32 _swapsLeft) private pure returns (string memory svg) {
    uint256 _positionNow = 170 + ((314 - 170) / (_swapsExecuted + _swapsLeft)) * _swapsExecuted;
    svg = string(
      abi.encodePacked(
        '<rect x="16" y="16" width="258" height="528" rx="26" ry="26" fill="rgba(0,0,0,0)" stroke="rgba(255,255,255,0.2)" />',
        '<g mask="url(#none)" style="transform:translate(80px,169px)"><rect x="-16px" y="-16px" width="180px" height="180px" fill="none" /><path d="M1 1 L1 145" stroke="rgba(0,0,0,0.3)" stroke-width="32px" fill="none" stroke-linecap="round" /></g>',
        '<g mask="url(#none)" style="transform:translate(80px,169px)"><rect x="-16px" y="-16px" width="180px" height="180px" fill="none" /><path d="M1 1 L1 145" stroke="rgba(255,255,255,1)" fill="none" stroke-linecap="round" /></g>',
        '<circle cx="81px" cy="170px" r="4px" fill="#dddddd" />',
        '<circle cx="81px" cy="',
        _positionNow.toString(),
        'px" r="5px" fill="white" />',
        '<circle cx="81px" cy="314px" r="4px" fill="#dddddd" /><text x="100px" y="174px" font-family="\'Courier New\', monospace" font-size="12px" fill="white"><tspan fill="rgba(255,255,255,0.6)">Executed*: </tspan>',
        _swapsExecuted.toString(),
        ' swaps</text><text x="40px" y="',
        (_positionNow + 4).toString(),
        'px" font-family="\'Courier New\', monospace" font-size="12px" fill="white">Now</text><text x="100px" y="318px" font-family="\'Courier New\', monospace" font-size="12px" fill="white"><tspan fill="rgba(255,255,255,0.6)">Left: </tspan>',
        _swapsLeft.toString(),
        ' swaps</text>'
      )
    );
  }

  function _generateSVGPositionData(
    uint256 _tokenId,
    string memory _swapped,
    string memory _averagePrice,
    string memory _remaining,
    string memory _rate
  ) private pure returns (string memory svg) {
    svg = string(
      abi.encodePacked(
        _generateData('Id', _tokenId.toString(), 364),
        _generateData('Swapped*', _swapped, 394),
        _generateData('Avg Price', _averagePrice, 424),
        _generateData('Remaining', _remaining, 454),
        _generateData('Rate', _rate, 484),
        '<g style="transform:translate(25px, 514px)">',
        '<text x="12px" y="17px" font-family="\'Courier New\', monospace" font-size="10px" fill="white">',
        '<tspan fill="rgba(255,255,255,0.8)">* since start or last edit/withdraw</tspan>',
        '</text>',
        '</g>'
      )
    );
  }

  function _generateData(
    string memory _title,
    string memory _data,
    uint256 _yCoord
  ) private pure returns (string memory svg) {
    uint256 _strLength = bytes(_title).length + bytes(_data).length + 2;
    svg = string(
      abi.encodePacked(
        '<g style="transform:translate(29px, ',
        _yCoord.toString(),
        'px)">',
        '<rect width="',
        uint256(7 * (_strLength + 4)).toString(),
        'px" height="26px" rx="8px" ry="8px" fill="rgba(0,0,0,0.6)" />',
        '<text x="12px" y="17px" font-family="\'Courier New\', monospace" font-size="12px" fill="white">',
        '<tspan fill="rgba(255,255,255,0.6)">',
        _title,
        ': </tspan>',
        _data,
        '</text>',
        '</g>'
      )
    );
  }
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
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}