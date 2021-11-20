// SPDX-License-Identifier: AGPL-3.0-or-later
/**
  ∩~~~~∩ 
  ξ ･×･ ξ 
  ξ　~　ξ 
  ξ　　 ξ 
  ξ　　 “~～~～〇 
  ξ　　　　　　 ξ 
  ξ ξ ξ~～~ξ ξ ξ 
　 ξ_ξξ_ξ　ξ_ξξ_ξ
Alpaca Fin Corporation
*/

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./IAlpacaVault.sol";
import "./IBookKeeper.sol";
import "./IWBNB.sol";
import "./IToken.sol";
import "./IManager.sol";
import "./IGenericTokenAdapter.sol";
import "./IFarmableTokenAdapter.sol";
import "./IStablecoinAdapter.sol";
import "./IStabilityFeeCollector.sol";
import "./IProxyRegistry.sol";
import "./IProxy.sol";
import "./SafeToken.sol";

/// ==============================
/// @notice WARNING: These functions meant to be used as a a library for a Proxy.
/// @notice DO NOT CALL ANY FUNCTION IN THIS CONTRACT DIRECTLY.
/// @notice Hence, it shouldn't has any state vairables. Some are unsafe if you call them directly.
/// ==============================

contract AlpacaStablecoinProxyActions {
  using SafeToken for address;

  uint256 internal constant RAY = 10**27;

  /// @dev Internal functions
  function _safeSub(uint256 _x, uint256 _y) internal pure returns (uint256 _z) {
    require((_z = _x - _y) <= _x, "sub-overflow");
  }

  function _safeToInt(uint256 _x) internal pure returns (int256 _y) {
    _y = int256(_x);
    require(_y >= 0, "int-overflow");
  }

  /// @notice Internal functions
  /// @dev Safe multiplication to prevent uint overflow
  function _safeMul(uint256 _x, uint256 _y) internal pure returns (uint256 _z) {
    require(_y == 0 || (_z = _x * _y) / _y == _x, "mul-overflow");
  }

  function _toRad(uint256 _wad) internal pure returns (uint256 _rad) {
    _rad = _safeMul(_wad, RAY);
  }

  function convertTo18(address _tokenAdapter, uint256 _amt) internal returns (uint256 _wad) {
    // For those collaterals that have less than 18 decimals precision we need to do the conversion before passing to adjustPosition function
    // Adapters will automatically handle the difference of precision
    _wad = _safeMul(_amt, 10**(18 - IGenericTokenAdapter(_tokenAdapter).decimals()));
  }

  function _getDrawDebtShare(
    address _bookKeeper,
    address _stabilityFeeCollector,
    address _positionAddress,
    bytes32 _collateralPoolId,
    uint256 _stablecoinAmount // [wad]
  ) internal returns (int256 _resultDebtShare) {
    // Updates stability fee rate
    uint256 _debtAccumulatedRate = IStabilityFeeCollector(_stabilityFeeCollector).collect(_collateralPoolId); // [ray]

    // Gets Alpaca Stablecoin balance of the positionAddress in the bookKeeper
    uint256 _positionStablecoinValue = IBookKeeper(_bookKeeper).stablecoin(_positionAddress); // [rad]

    // If there was already enough Alpaca Stablecoin in the bookKeeper balance, just exits it without adding more debt
    if (_positionStablecoinValue < _safeMul(_stablecoinAmount, RAY)) {
      // Calculates the needed resultDebtShare so together with the existing positionStablecoinValue in the bookKeeper is enough to exit stablecoinAmount of Alpaca Stablecoin tokens
      _resultDebtShare = _safeToInt(
        _safeSub(_safeMul(_stablecoinAmount, RAY), _positionStablecoinValue) / _debtAccumulatedRate
      );
      // This is neeeded due lack of precision. It might need to sum an extra resultDebtShare wei (for the given Alpaca Stablecoin stablecoinAmount)
      _resultDebtShare = _safeMul(uint256(_resultDebtShare), _debtAccumulatedRate) < _safeMul(_stablecoinAmount, RAY)
        ? _resultDebtShare + 1
        : _resultDebtShare;
    }
  }

  function _getWipeDebtShare(
    address _bookKeeper,
    uint256 _stablecoinValue, // [rad]
    address _positionAddress,
    bytes32 _collateralPoolId
  ) internal view returns (int256 _resultDebtShare) {
    // Gets actual rate from the bookKeeper
    uint256 _debtAccumulatedRate = ICollateralPoolConfig(IBookKeeper(_bookKeeper).collateralPoolConfig())
      .getDebtAccumulatedRate(_collateralPoolId); // [ray]

    // Gets actual debtShare value of the positionAddress
    (, uint256 _debtShare) = IBookKeeper(_bookKeeper).positions(_collateralPoolId, _positionAddress); // [wad]

    // Uses the whole stablecoin balance in the bookKeeper to reduce the debt
    _resultDebtShare = _safeToInt(_stablecoinValue / _debtAccumulatedRate); // [wad]

    // Checks the calculated resultDebtShare is not higher than positionAddress.art (total debt), otherwise uses its value
    _resultDebtShare = uint256(_resultDebtShare) <= _debtShare ? -_resultDebtShare : -_safeToInt(_debtShare); // [wad]
  }

  function _getWipeAllStablecoinAmount(
    address _bookKeeper,
    address _usr,
    address _positionAddress,
    bytes32 _collateralPoolId
  ) internal view returns (uint256 _requiredStablecoinAmount) {
    // Gets actual rate from the bookKeeper
    uint256 _debtAccumulatedRate = ICollateralPoolConfig(IBookKeeper(_bookKeeper).collateralPoolConfig())
      .getDebtAccumulatedRate(_collateralPoolId); // [ray]
    // Gets actual debtShare value of the positionAddress
    (, uint256 _debtShare) = IBookKeeper(_bookKeeper).positions(_collateralPoolId, _positionAddress); // [wad]
    // Gets actual stablecoin amount in the usr
    uint256 _stablecoinValue = IBookKeeper(_bookKeeper).stablecoin(_usr); // [rad]

    uint256 _requiredStablecoinValue = _safeSub(_safeMul(_debtShare, _debtAccumulatedRate), _stablecoinValue); // [rad]
    _requiredStablecoinAmount = _requiredStablecoinValue / RAY; // [wad] = [rad]/[ray]

    // If the value precision has some dust, it will need to request for 1 extra amount wei
    _requiredStablecoinAmount = _safeMul(_requiredStablecoinAmount, RAY) < _requiredStablecoinValue
      ? _requiredStablecoinAmount + 1
      : _requiredStablecoinAmount;
  }

  /// @notice Public functions
  /// @param _adapter The address of stablecoin adapter
  /// @param _positionAddress The address of the Position Handler
  /// @param _stablecoinAmount The amount in wad to be deposit to Stablecoin adapter [wad]
  /// @param _data The extra data for stable adapter context
  function stablecoinAdapterDeposit(
    address _adapter,
    address _positionAddress,
    uint256 _stablecoinAmount, // [wad]
    bytes calldata _data
  ) public {
    address _stablecoin = address(IStablecoinAdapter(_adapter).stablecoin());
    // Gets Alpaca Stablecoin from the user's wallet
    _stablecoin.safeTransferFrom(msg.sender, address(this), _stablecoinAmount);
    // Approves adapter to take the Alpaca Stablecoin amount
    _stablecoin.safeApprove(_adapter, _stablecoinAmount);
    // Deposits Alpaca Stablecoin into the bookKeeper
    IStablecoinAdapter(_adapter).deposit(_positionAddress, _stablecoinAmount, _data);
  }

  // Public functions
  function transfer(
    address _collateralToken,
    address _dst,
    uint256 _amt
  ) public {
    address(_collateralToken).safeTransfer(_dst, _amt);
  }

  function bnbAdapterDeposit(
    address _adapter,
    address _positionAddress,
    bytes calldata _data
  ) public payable {
    address _collateralToken = address(IGenericTokenAdapter(_adapter).collateralToken());
    // Wraps BNB into WBNB
    IWBNB(_collateralToken).deposit{ value: msg.value }();
    // Approves adapter to take the WBNB amount
    _collateralToken.safeApprove(address(_adapter), msg.value);
    // Deposits WBNB collateral into the bookKeeper
    IGenericTokenAdapter(_adapter).deposit(_positionAddress, msg.value, _data);
  }

  function tokenAdapterDeposit(
    address _adapter,
    address _positionAddress,
    uint256 _amount, // [wad]
    bool _transferFrom,
    bytes calldata _data
  ) public {
    address _collateralToken = address(IGenericTokenAdapter(_adapter).collateralToken());

    // Only executes for tokens that have approval/transferFrom implementation
    if (_transferFrom) {
      // Gets token from the user's wallet
      _collateralToken.safeTransferFrom(msg.sender, address(this), _amount);
      // Approves adapter to take the token amount
      _collateralToken.safeApprove(_adapter, _amount);
    }
    // Deposits token collateral into the bookKeeper
    IGenericTokenAdapter(_adapter).deposit(_positionAddress, _amount, _data);
  }

  function whitelist(address _bookKeeper, address _usr) external {
    IBookKeeper(_bookKeeper).whitelist(_usr);
  }

  function blacklist(address _bookKeeper, address _usr) external {
    IBookKeeper(_bookKeeper).blacklist(_usr);
  }

  function open(
    address _manager,
    bytes32 _collateralPoolId,
    address _usr
  ) public returns (uint256 _positionId) {
    _positionId = IManager(_manager).open(_collateralPoolId, _usr);
  }

  function transferOwnership(
    address _manager,
    uint256 _positionId,
    address _usr
  ) public {
    IManager(_manager).give(_positionId, _usr);
  }

  function transferOwnershipToProxy(
    address _proxyRegistry,
    address _manager,
    uint256 _positionId,
    address _dst
  ) external {
    // Gets actual proxy address
    address _proxy = IProxyRegistry(_proxyRegistry).proxies(_dst);
    // Checks if the proxy address already existed and dst address is still the owner
    if (_proxy == address(0) || IProxy(_proxy).owner() != _dst) {
      uint256 _codeSize;
      assembly {
        _codeSize := extcodesize(_dst)
      }
      // We want to avoid creating a proxy for a contract address that might not be able to handle proxies, then losing the CDP
      require(_codeSize == 0, "Dst-is-a-contract");
      // Creates the proxy for the dst address
      _proxy = IProxyRegistry(_proxyRegistry).build(_dst);
    }
    // Transfers position to the dst proxy
    transferOwnership(_manager, _positionId, _proxy);
  }

  /// @dev Allow/Disallow a user to manage the position
  /// @param _manager The PositionManager address
  /// @param _user The user address that msg.sender would like to allow to manage his position
  /// @param _ok The ok flag to allow/disallow
  function allowManagePosition(
    address _manager,
    uint256 _positionId,
    address _user,
    uint256 _ok
  ) external {
    IManager(_manager).allowManagePosition(_positionId, _user, _ok);
  }

  /// @dev Allow/Disallow a user to import/export position from/to msg.sender
  /// @param _manager The PositionManager address
  /// @param _user The user address that msg.sender would like to allow to import/export position from/to
  /// @param _ok The ok flag to allow/disallow
  function allowMigratePosition(
    address _manager,
    address _user,
    uint256 _ok
  ) external {
    IManager(_manager).allowMigratePosition(_user, _ok);
  }

  function moveCollateral(
    address _manager,
    uint256 _positionId,
    address _dst,
    uint256 _collateralAmount,
    address _adapter,
    bytes calldata _data
  ) public {
    IManager(_manager).moveCollateral(_positionId, _dst, _collateralAmount, _adapter, _data);
  }

  function moveStablecoin(
    address _manager,
    uint256 _positionId,
    address _dst,
    uint256 _stablecoinValue // [rad]
  ) public {
    IManager(_manager).moveStablecoin(_positionId, _dst, _stablecoinValue);
  }

  function adjustPosition(
    address _manager,
    uint256 _positionId,
    int256 _collateralValue,
    int256 _debtShare, // [wad]
    address _adapter,
    bytes calldata _data
  ) public {
    IManager(_manager).adjustPosition(_positionId, _collateralValue, _debtShare, _adapter, _data);
  }

  function exportPosition(
    address _manager,
    uint256 _positionId,
    address _destination
  ) external {
    IManager(_manager).exportPosition(_positionId, _destination);
  }

  function importPosition(
    address _manager,
    address _source,
    uint256 _positionId
  ) external {
    IManager(_manager).importPosition(_source, _positionId);
  }

  function movePosition(
    address _manager,
    uint256 _source,
    uint256 _destination
  ) external {
    IManager(_manager).movePosition(_source, _destination);
  }

  function bnbToIbBNB(
    address _vault,
    uint256 _amount // [wad]
  ) public payable returns (uint256) {
    SafeToken.safeApprove(address(IAlpacaVault(_vault).token()), address(_vault), _amount);
    uint256 _ibBNBBefore = _vault.balanceOf(address(this));
    IAlpacaVault(_vault).deposit{ value: msg.value }(msg.value);
    uint256 _ibBNBAfter = _vault.balanceOf(address(this));
    SafeToken.safeApprove(address(IAlpacaVault(_vault).token()), address(_vault), 0);
    uint256 _backIbBNB = _safeSub(_ibBNBAfter, _ibBNBBefore);
    address(_vault).safeTransfer(msg.sender, _backIbBNB);
    return _backIbBNB;
  }

  function ibBNBToBNB(
    address _vault,
    uint256 _amount // [wad]
  ) public payable {
    // user requires to approve the proxy wallet before calling this function
    address(_vault).safeTransferFrom(msg.sender, address(this), _amount);
    uint256 _bnbBefore = address(this).balance;
    IAlpacaVault(_vault).withdraw(_amount);
    uint256 _bnbAfter = address(this).balance;
    SafeToken.safeTransferETH(msg.sender, _safeSub(_bnbAfter, _bnbBefore));
  }

  function tokenToIbToken(
    address _vault,
    uint256 _amount // [wad]
  ) public returns (uint256) {
    // user requires to approve the proxy wallet before calling this function
    address(IAlpacaVault(_vault).token()).safeTransferFrom(msg.sender, address(this), _amount);
    SafeToken.safeApprove(address(IAlpacaVault(_vault).token()), address(_vault), _amount);
    uint256 _collateralTokenBefore = _vault.balanceOf(address(this));
    IAlpacaVault(_vault).deposit(_amount);
    uint256 _collateralTokenAfter = _vault.balanceOf(address(this));
    SafeToken.safeApprove(address(IAlpacaVault(_vault).token()), address(_vault), 0);
    uint256 _backCollateralToken = _safeSub(_collateralTokenAfter, _collateralTokenBefore);
    address(_vault).safeTransfer(msg.sender, _backCollateralToken);
    return _backCollateralToken;
  }

  function ibTokenToToken(
    address _vault,
    uint256 _amount // [wad]
  ) public {
    // user requires to approve the proxy wallet before calling this function
    address(_vault).safeTransferFrom(msg.sender, address(this), _amount);
    uint256 _baseTokenBefore = IAlpacaVault(_vault).token().balanceOf(address(this));
    IAlpacaVault(_vault).withdraw(_amount);
    uint256 _baseTokenAfter = IAlpacaVault(_vault).token().balanceOf(address(this));
    address(IAlpacaVault(_vault).token()).safeTransfer(msg.sender, _safeSub(_baseTokenAfter, _baseTokenBefore));
  }

  function lockBNB(
    address _manager,
    address _bnbAdapter,
    uint256 _positionId,
    bytes calldata _data
  ) public payable {
    address _positionAddress = IManager(_manager).positions(_positionId);
    // Receives BNB amount, converts it to WBNB and joins it into the bookKeeper
    bnbAdapterDeposit(_bnbAdapter, _positionAddress, _data);
    // Locks WBNB amount into the CDP
    adjustPosition(_manager, _positionId, _safeToInt(msg.value), 0, _bnbAdapter, _data);
  }

  function safeLockBNB(
    address _manager,
    address _bnbAdapter,
    uint256 _positionId,
    address _owner,
    bytes calldata _data
  ) external payable {
    require(IManager(_manager).owners(_positionId) == _owner, "!owner");
    lockBNB(_manager, _bnbAdapter, _positionId, _data);
  }

  function lockToken(
    address _manager,
    address _tokenAdapter,
    uint256 _positionId,
    uint256 _amount, // [in token decimal]
    bool _transferFrom,
    bytes calldata _data
  ) public {
    address _positionAddress = IManager(_manager).positions(_positionId);

    // Takes token amount from user's wallet and joins into the bookKeeper
    tokenAdapterDeposit(_tokenAdapter, _positionAddress, _amount, _transferFrom, _data);
    // Locks token amount into the position manager
    adjustPosition(_manager, _positionId, _safeToInt(convertTo18(_tokenAdapter, _amount)), 0, _tokenAdapter, _data);
  }

  function safeLockToken(
    address _manager,
    address _tokenAdapter,
    uint256 _positionId,
    uint256 _amount, // [wad]
    bool _transferFrom,
    address _owner,
    bytes calldata _data
  ) external {
    require(IManager(_manager).owners(_positionId) == _owner, "!owner");
    lockToken(_manager, _tokenAdapter, _positionId, _amount, _transferFrom, _data);
  }

  function unlockBNB(
    address _manager,
    address _bnbAdapter,
    uint256 _positionId,
    uint256 _amount, // [wad]
    bytes calldata _data
  ) external {
    // Unlocks WBNB amount from the CDP
    adjustPosition(_manager, _positionId, -_safeToInt(_amount), 0, _bnbAdapter, _data);
    // Moves the amount from the CDP positionAddress to proxy's address
    moveCollateral(_manager, _positionId, address(this), _amount, _bnbAdapter, _data);
    // Withdraws WBNB amount to proxy address as a token
    IGenericTokenAdapter(_bnbAdapter).withdraw(address(this), _amount, _data);
    // Converts WBNB to BNB
    IWBNB(address(IGenericTokenAdapter(_bnbAdapter).collateralToken())).withdraw(_amount);
    // Sends BNB back to the user's wallet
    SafeToken.safeTransferETH(msg.sender, _amount);
  }

  function unlockToken(
    address _manager,
    address _tokenAdapter,
    uint256 _positionId,
    uint256 _amount, // [in token decimal]
    bytes calldata _data
  ) external {
    // Try to decode user address for harvested rewards from calldata
    // if the user address is not passed, then send zero address to `harvest` and let it handle
    address _user = address(0);
    if (_data.length > 0) _user = abi.decode(_data, (address));
    uint256 _amountInWad = convertTo18(_tokenAdapter, _amount);
    // Unlocks token amount from the position
    adjustPosition(_manager, _positionId, -_safeToInt(_amountInWad), 0, _tokenAdapter, _data);
    // Moves the amount from the position to proxy's address
    moveCollateral(_manager, _positionId, address(this), _amountInWad, _tokenAdapter, _data);
    // Withdraws token amount to the user's wallet as a token
    IGenericTokenAdapter(_tokenAdapter).withdraw(msg.sender, _amount, _data);
  }

  function withdrawBNB(
    address _manager,
    address _bnbAdapter,
    uint256 _positionId,
    uint256 _amount, // [wad]
    bytes calldata _data
  ) external {
    // Moves the amount from the position to proxy's address
    moveCollateral(_manager, _positionId, address(this), _amount, _bnbAdapter, _data);

    // Withdraws WBNB amount to proxy address as a token
    IGenericTokenAdapter(_bnbAdapter).withdraw(address(this), _amount, _data);
    // Converts WBNB to BNB
    IWBNB(address(IGenericTokenAdapter(_bnbAdapter).collateralToken())).withdraw(_amount);
    // Sends BNB back to the user's wallet
    SafeToken.safeTransferETH(msg.sender, _amount);
  }

  function withdrawToken(
    address _manager,
    address _tokenAdapter,
    uint256 _positionId,
    uint256 _amount, // [in token decimal]
    bytes calldata _data
  ) external {
    // Moves the amount from the position to proxy's address
    moveCollateral(_manager, _positionId, address(this), convertTo18(_tokenAdapter, _amount), _tokenAdapter, _data);

    // Withdraws token amount to the user's wallet as a token
    IGenericTokenAdapter(_tokenAdapter).withdraw(msg.sender, _amount, _data);
  }

  function draw(
    address _manager,
    address _stabilityFeeCollector,
    address _tokenAdapter,
    address _stablecoinAdapter,
    uint256 _positionId,
    uint256 _amount, // [wad]
    bytes calldata _data
  ) external {
    address _positionAddress = IManager(_manager).positions(_positionId);
    address _bookKeeper = IManager(_manager).bookKeeper();
    bytes32 _collateralPoolId = IManager(_manager).collateralPools(_positionId);
    // Generates debt in the CDP
    adjustPosition(
      _manager,
      _positionId,
      0,
      _getDrawDebtShare(_bookKeeper, _stabilityFeeCollector, _positionAddress, _collateralPoolId, _amount),
      _tokenAdapter,
      _data
    );
    // Moves the Alpaca Stablecoin amount (balance in the bookKeeper in rad) to proxy's address
    moveStablecoin(_manager, _positionId, address(this), _toRad(_amount));
    // Allows adapter to access to proxy's Alpaca Stablecoin balance in the bookKeeper
    if (IBookKeeper(_bookKeeper).positionWhitelist(address(this), address(_stablecoinAdapter)) == 0) {
      IBookKeeper(_bookKeeper).whitelist(_stablecoinAdapter);
    }
    // Withdraws Alpaca Stablecoin to the user's wallet as a token
    IStablecoinAdapter(_stablecoinAdapter).withdraw(msg.sender, _amount, _data);
  }

  function wipe(
    address _manager,
    address _tokenAdapter,
    address _stablecoinAdapter,
    uint256 _positionId,
    uint256 _amount, // [wad]
    bytes calldata _data
  ) public {
    address _bookKeeper = IManager(_manager).bookKeeper();
    address _positionAddress = IManager(_manager).positions(_positionId);
    bytes32 _collateralPoolId = IManager(_manager).collateralPools(_positionId);

    address owner = IManager(_manager).owners(_positionId);
    if (owner == address(this) || IManager(_manager).ownerWhitelist(owner, _positionId, address(this)) == 1) {
      // Deposits Alpaca Stablecoin amount into the bookKeeper
      stablecoinAdapterDeposit(_stablecoinAdapter, _positionAddress, _amount, _data);
      // Paybacks debt to the CDP
      adjustPosition(
        _manager,
        _positionId,
        0,
        _getWipeDebtShare(
          _bookKeeper,
          IBookKeeper(_bookKeeper).stablecoin(_positionAddress),
          _positionAddress,
          _collateralPoolId
        ),
        _tokenAdapter,
        _data
      );
    } else {
      // Deposits Alpaca Stablecoin amount into the bookKeeper
      stablecoinAdapterDeposit(_stablecoinAdapter, address(this), _amount, _data);
      // Paybacks debt to the position
      int256 _wipeDebtShare = _getWipeDebtShare(_bookKeeper, _amount * RAY, _positionAddress, _collateralPoolId);
      IBookKeeper(_bookKeeper).adjustPosition(
        _collateralPoolId,
        _positionAddress,
        address(this),
        address(this),
        0,
        _wipeDebtShare
      );
    }
  }

  function safeWipe(
    address _manager,
    address _tokenAdapter,
    address _stablecoinAdapter,
    uint256 _positionId,
    uint256 _amount, // [wad]
    address _owner,
    bytes calldata _data
  ) external {
    require(IManager(_manager).owners(_positionId) == _owner, "!owner");
    wipe(_manager, _tokenAdapter, _stablecoinAdapter, _positionId, _amount, _data);
  }

  function wipeAll(
    address _manager,
    address _tokenAdapter,
    address _stablecoinAdapter,
    uint256 _positionId,
    bytes calldata _data
  ) public {
    address _bookKeeper = IManager(_manager).bookKeeper();
    address _positionAddress = IManager(_manager).positions(_positionId);
    bytes32 _collateralPoolId = IManager(_manager).collateralPools(_positionId);
    (, uint256 _debtShare) = IBookKeeper(_bookKeeper).positions(_collateralPoolId, _positionAddress); // [wad]

    address _owner = IManager(_manager).owners(_positionId);
    if (_owner == address(this) || IManager(_manager).ownerWhitelist(_owner, _positionId, address(this)) == 1) {
      // Deposits Alpaca Stablecoin amount into the bookKeeper
      stablecoinAdapterDeposit(
        _stablecoinAdapter,
        _positionAddress,
        _getWipeAllStablecoinAmount(_bookKeeper, _positionAddress, _positionAddress, _collateralPoolId),
        _data
      );
      // Paybacks debt to the CDP
      adjustPosition(_manager, _positionId, 0, -int256(_debtShare), _tokenAdapter, _data);
    } else {
      // Deposits Alpaca Stablecoin amount into the bookKeeper
      stablecoinAdapterDeposit(
        _stablecoinAdapter,
        address(this),
        _getWipeAllStablecoinAmount(_bookKeeper, address(this), _positionAddress, _collateralPoolId),
        _data
      );
      // Paybacks debt to the position
      IBookKeeper(_bookKeeper).adjustPosition(
        _collateralPoolId,
        _positionAddress,
        address(this),
        address(this),
        0,
        -int256(_debtShare)
      );
    }
  }

  function safeWipeAll(
    address _manager,
    address _tokenAdapter,
    address _stablecoinAdapter,
    uint256 _positionId,
    address _owner,
    bytes calldata _data
  ) external {
    require(IManager(_manager).owners(_positionId) == _owner, "!owner");
    wipeAll(_manager, _tokenAdapter, _stablecoinAdapter, _positionId, _data);
  }

  function lockBNBAndDraw(
    address _manager,
    address _stabilityFeeCollector,
    address _bnbAdapter,
    address _stablecoinAdapter,
    uint256 _positionId,
    uint256 _stablecoinAmount, // [wad]
    bytes calldata _data
  ) public payable {
    address _positionAddress = IManager(_manager).positions(_positionId);
    address _bookKeeper = IManager(_manager).bookKeeper();
    bytes32 _collateralPoolId = IManager(_manager).collateralPools(_positionId);
    // Receives BNB amount, converts it to WBNB and joins it into the bookKeeper
    bnbAdapterDeposit(_bnbAdapter, _positionAddress, _data);
    // Locks WBNB amount into the CDP and generates debt
    adjustPosition(
      _manager,
      _positionId,
      _safeToInt(msg.value),
      _getDrawDebtShare(_bookKeeper, _stabilityFeeCollector, _positionAddress, _collateralPoolId, _stablecoinAmount),
      _bnbAdapter,
      _data
    );
    // Moves the Alpaca Stablecoin amount (balance in the bookKeeper in rad) to proxy's address
    moveStablecoin(_manager, _positionId, address(this), _toRad(_stablecoinAmount));
    // Allows adapter to access to proxy's Alpaca Stablecoin balance in the bookKeeper
    if (IBookKeeper(_bookKeeper).positionWhitelist(address(this), address(_stablecoinAdapter)) == 0) {
      IBookKeeper(_bookKeeper).whitelist(_stablecoinAdapter);
    }
    // Withdraws Alpaca Stablecoin to the user's wallet as a token
    IStablecoinAdapter(_stablecoinAdapter).withdraw(msg.sender, _stablecoinAmount, _data);
  }

  /// @notice
  function openLockBNBAndDraw(
    address _manager,
    address _stabilityFeeCollector,
    address _bnbAdapter,
    address _stablecoinAdapter,
    bytes32 _collateralPoolId,
    uint256 _stablecoinAmount, // [wad]
    bytes calldata _data
  ) external payable returns (uint256 _positionId) {
    _positionId = open(_manager, _collateralPoolId, address(this));
    lockBNBAndDraw(
      _manager,
      _stabilityFeeCollector,
      _bnbAdapter,
      _stablecoinAdapter,
      _positionId,
      _stablecoinAmount,
      _data
    );
  }

  function lockTokenAndDraw(
    IManager _manager,
    address _stabilityFeeCollector,
    address _tokenAdapter,
    address _stablecoinAdapter,
    uint256 _positionId,
    uint256 _collateralAmount, // [in token decimal]
    uint256 _stablecoinAmount, // [wad]
    bool _transferFrom,
    bytes calldata _data
  ) public {
    bytes32 _collateralPoolId = _manager.collateralPools(_positionId);
    // Takes token amount from user's wallet and joins into the bookKeeper
    tokenAdapterDeposit(_tokenAdapter, _manager.positions(_positionId), _collateralAmount, _transferFrom, _data);
    // Locks token amount into the position and generates debt
    int256 _collateralAmountInWad = _safeToInt(convertTo18(_tokenAdapter, _collateralAmount));
    int256 _drawDebtShare = _getDrawDebtShare(
      _manager.bookKeeper(),
      _stabilityFeeCollector,
      _manager.positions(_positionId),
      _collateralPoolId,
      _stablecoinAmount
    ); // [wad]
    adjustPosition(address(_manager), _positionId, _collateralAmountInWad, _drawDebtShare, _tokenAdapter, _data);
    // Moves the Alpaca Stablecoin amount (balance in the bookKeeper in rad) to proxy's address
    moveStablecoin(address(_manager), _positionId, address(this), _toRad(_stablecoinAmount));
    // Allows adapter to access to proxy's Alpaca Stablecoin balance in the bookKeeper
    if (IBookKeeper(_manager.bookKeeper()).positionWhitelist(address(this), address(_stablecoinAdapter)) == 0) {
      IBookKeeper(_manager.bookKeeper()).whitelist(_stablecoinAdapter);
    }
    // Withdraws Alpaca Stablecoin to the user's wallet as a token
    IStablecoinAdapter(_stablecoinAdapter).withdraw(msg.sender, _stablecoinAmount, _data);
  }

  function openLockTokenAndDraw(
    address _manager,
    address _stabilityFeeCollector,
    address _tokenAdapter,
    address _stablecoinAdapter,
    bytes32 _collateralPoolId,
    uint256 _collateralAmount, // [in token decimal]
    uint256 _stablecoinAmount, // [wad]
    bool _transferFrom,
    bytes calldata _data
  ) public returns (uint256 _positionId) {
    _positionId = open(_manager, _collateralPoolId, address(this));
    lockTokenAndDraw(
      IManager(_manager),
      _stabilityFeeCollector,
      _tokenAdapter,
      _stablecoinAdapter,
      _positionId,
      _collateralAmount,
      _stablecoinAmount,
      _transferFrom,
      _data
    );
  }

  function convertAndLockToken(
    address _vault,
    address _manager,
    address _tokenAdapter,
    uint256 _positionId,
    uint256 _amount, // [wad]
    bool _transferFrom,
    bytes calldata _data
  ) external {
    uint256 _collateralAmount = tokenToIbToken(_vault, convertTo18(_tokenAdapter, _amount));
    lockToken(_manager, _tokenAdapter, _positionId, _collateralAmount, _transferFrom, _data);
  }

  function convertLockTokenAndDraw(
    address _vault,
    IManager _manager,
    address _stabilityFeeCollector,
    address _tokenAdapter,
    address _stablecoinAdapter,
    uint256 _positionId,
    uint256 _amount, // [in token decimal]
    uint256 _stablecoinAmount, // [wad]
    bool _transferFrom,
    bytes calldata _data
  ) external {
    uint256 _collateralAmount = tokenToIbToken(_vault, convertTo18(_tokenAdapter, _amount));
    lockTokenAndDraw(
      IManager(_manager),
      _stabilityFeeCollector,
      _tokenAdapter,
      _stablecoinAdapter,
      _positionId,
      _collateralAmount,
      _stablecoinAmount,
      _transferFrom,
      _data
    );
  }

  function convertBNBAndLockToken(
    address _vault,
    address _manager,
    address _tokenAdapter,
    uint256 _positionId,
    bool _transferFrom,
    bytes calldata _data
  ) external payable {
    uint256 _collateralAmount = bnbToIbBNB(_vault, msg.value);
    lockToken(_manager, _tokenAdapter, _positionId, _collateralAmount, _transferFrom, _data);
  }

  function convertBNBLockTokenAndDraw(
    address _vault,
    IManager _manager,
    address _stabilityFeeCollector,
    address _tokenAdapter,
    address _stablecoinAdapter,
    uint256 _positionId,
    uint256 _stablecoinAmount, // [wad]
    bool _transferFrom,
    bytes calldata _data
  ) external payable {
    uint256 _collateralAmount = bnbToIbBNB(_vault, msg.value);
    lockTokenAndDraw(
      IManager(_manager),
      _stabilityFeeCollector,
      _tokenAdapter,
      _stablecoinAdapter,
      _positionId,
      _collateralAmount,
      _stablecoinAmount,
      _transferFrom,
      _data
    );
  }

  function convertBNBOpenLockTokenAndDraw(
    address _vault,
    address _manager,
    address _stabilityFeeCollector,
    address _tokenAdapter,
    address _stablecoinAdapter,
    bytes32 _collateralPoolId,
    uint256 _stablecoinAmount, // [wad]
    bool _transferFrom,
    bytes calldata _data
  ) external payable returns (uint256 positionId) {
    uint256 _collateralAmount = bnbToIbBNB(_vault, msg.value);
    return
      openLockTokenAndDraw(
        _manager,
        _stabilityFeeCollector,
        _tokenAdapter,
        _stablecoinAdapter,
        _collateralPoolId,
        _collateralAmount,
        _stablecoinAmount,
        _transferFrom,
        _data
      );
  }

  function convertOpenLockTokenAndDraw(
    address _vault,
    address _manager,
    address _stabilityFeeCollector,
    address _tokenAdapter,
    address _stablecoinAdapter,
    bytes32 _collateralPoolId,
    uint256 _tokenAmount, // [in token decimal]
    uint256 _stablecoinAmount, // [wad]
    bool _transferFrom,
    bytes calldata _data
  ) external returns (uint256 positionId) {
    uint256 _collateralAmount = tokenToIbToken(_vault, convertTo18(_tokenAdapter, _tokenAmount));
    return
      openLockTokenAndDraw(
        _manager,
        _stabilityFeeCollector,
        _tokenAdapter,
        _stablecoinAdapter,
        _collateralPoolId,
        _collateralAmount,
        _stablecoinAmount,
        _transferFrom,
        _data
      );
  }

  function wipeAndUnlockBNB(
    address _manager,
    address _bnbAdapter,
    address _stablecoinAdapter,
    uint256 _positionId,
    uint256 _collateralAmount, // [wad]
    uint256 _stablecoinAmount, // [wad]
    bytes calldata _data
  ) external {
    address _positionAddress = IManager(_manager).positions(_positionId);
    // Deposits Alpaca Stablecoin amount into the bookKeeper
    stablecoinAdapterDeposit(_stablecoinAdapter, _positionAddress, _stablecoinAmount, _data);
    // Paybacks debt to the position and unlocks WBNB amount from it
    int256 _wipeDebtShare = _getWipeDebtShare(
      IManager(_manager).bookKeeper(),
      IBookKeeper(IManager(_manager).bookKeeper()).stablecoin(_positionAddress),
      _positionAddress,
      IManager(_manager).collateralPools(_positionId)
    ); // [wad]
    adjustPosition(_manager, _positionId, -_safeToInt(_collateralAmount), _wipeDebtShare, _bnbAdapter, _data);
    // Moves the amount from the position to proxy's address
    moveCollateral(_manager, _positionId, address(this), _collateralAmount, _bnbAdapter, _data);
    // Withdraws WBNB amount to proxy address as a token
    IGenericTokenAdapter(_bnbAdapter).withdraw(address(this), _collateralAmount, _data);
    // Converts WBNB to BNB
    IWBNB(address(IGenericTokenAdapter(_bnbAdapter).collateralToken())).withdraw(_collateralAmount);
    // Sends BNB back to the user's wallet
    SafeToken.safeTransferETH(msg.sender, _collateralAmount);
  }

  function wipeAllAndUnlockBNB(
    address _manager,
    address _bnbAdapter,
    address _stablecoinAdapter,
    uint256 _positionId,
    uint256 _collateralAmount, // [wad]
    bytes calldata _data
  ) external {
    address _bookKeeper = IManager(_manager).bookKeeper();
    address _positionAddress = IManager(_manager).positions(_positionId);
    bytes32 _collateralPoolId = IManager(_manager).collateralPools(_positionId);
    (, uint256 _debtShare) = IBookKeeper(_bookKeeper).positions(_collateralPoolId, _positionAddress); // [wad]

    // Deposits Alpaca Stablecoin amount into the bookKeeper
    stablecoinAdapterDeposit(
      _stablecoinAdapter,
      _positionAddress,
      _getWipeAllStablecoinAmount(_bookKeeper, _positionAddress, _positionAddress, _collateralPoolId),
      _data
    );
    // Paybacks debt to the CDP and unlocks WBNB amount from it
    adjustPosition(_manager, _positionId, -_safeToInt(_collateralAmount), -int256(_debtShare), _bnbAdapter, _data);
    // Moves the amount from the CDP positionAddress to proxy's address
    moveCollateral(_manager, _positionId, address(this), _collateralAmount, _bnbAdapter, _data);
    // Withdraws WBNB amount to proxy address as a token
    IGenericTokenAdapter(_bnbAdapter).withdraw(address(this), _collateralAmount, _data);
    // Converts WBNB to BNB
    IWBNB(address(IGenericTokenAdapter(_bnbAdapter).collateralToken())).withdraw(_collateralAmount);
    // Sends BNB back to the user's wallet
    SafeToken.safeTransferETH(msg.sender, _collateralAmount);
  }

  function wipeAndUnlockToken(
    address _manager,
    address _tokenAdapter,
    address _stablecoinAdapter,
    uint256 _positionId,
    uint256 _collateralAmount, // [in token decimal]
    uint256 _stablecoinAmount, // [wad]
    bytes calldata _data
  ) public {
    address _positionAddress = IManager(_manager).positions(_positionId);
    // Deposits Alpaca Stablecoin amount into the bookKeeper
    stablecoinAdapterDeposit(_stablecoinAdapter, _positionAddress, _stablecoinAmount, _data);
    uint256 _collateralAmountInWad = convertTo18(_tokenAdapter, _collateralAmount);
    // Paybacks debt to the CDP and unlocks token amount from it
    int256 _wipeDebtShare = _getWipeDebtShare(
      IManager(_manager).bookKeeper(),
      IBookKeeper(IManager(_manager).bookKeeper()).stablecoin(_positionAddress),
      _positionAddress,
      IManager(_manager).collateralPools(_positionId)
    );
    adjustPosition(_manager, _positionId, -_safeToInt(_collateralAmountInWad), _wipeDebtShare, _tokenAdapter, _data);
    // Moves the amount from the position to proxy's address
    moveCollateral(_manager, _positionId, address(this), _collateralAmountInWad, _tokenAdapter, _data);
    // Withdraws token amount to the user's wallet as a token
    IGenericTokenAdapter(_tokenAdapter).withdraw(msg.sender, _collateralAmount, _data);
  }

  function wipeUnlockIbBNBAndCovertToBNB(
    address _vault,
    address _manager,
    address _tokenAdapter,
    address _stablecoinAdapter,
    uint256 _positionId,
    uint256 _collateralAmount, // [wad]
    uint256 _stablecoinAmount, // [wad]
    bytes calldata _data
  ) external {
    wipeAndUnlockToken(
      _manager,
      _tokenAdapter,
      _stablecoinAdapter,
      _positionId,
      _collateralAmount,
      _stablecoinAmount,
      _data
    );
    ibBNBToBNB(_vault, _collateralAmount);
  }

  function wipeUnlockTokenAndConvert(
    address _vault,
    address _manager,
    address _tokenAdapter,
    address _stablecoinAdapter,
    uint256 _positionId,
    uint256 _collateralAmount, // [token decimal]
    uint256 _stablecoinAmount, // [wad]
    bytes calldata _data
  ) external {
    wipeAndUnlockToken(
      _manager,
      _tokenAdapter,
      _stablecoinAdapter,
      _positionId,
      _collateralAmount,
      _stablecoinAmount,
      _data
    );
    ibTokenToToken(_vault, convertTo18(_tokenAdapter, _collateralAmount));
  }

  function wipeAllAndUnlockToken(
    address _manager,
    address _tokenAdapter,
    address _stablecoinAdapter,
    uint256 _positionId,
    uint256 _collateralAmount, // [token decimal]
    bytes calldata _data
  ) public {
    address _bookKeeper = IManager(_manager).bookKeeper();
    address _positionAddress = IManager(_manager).positions(_positionId);
    bytes32 _collateralPoolId = IManager(_manager).collateralPools(_positionId);
    (, uint256 _debtShare) = IBookKeeper(_bookKeeper).positions(_collateralPoolId, _positionAddress);

    // Deposits Alpaca Stablecoin amount into the bookKeeper
    stablecoinAdapterDeposit(
      _stablecoinAdapter,
      _positionAddress,
      _getWipeAllStablecoinAmount(_bookKeeper, _positionAddress, _positionAddress, _collateralPoolId),
      _data
    );
    uint256 _collateralAmountInWad = convertTo18(_tokenAdapter, _collateralAmount);
    // Paybacks debt to the position and unlocks token amount from it
    adjustPosition(
      _manager,
      _positionId,
      -_safeToInt(_collateralAmountInWad),
      -int256(_debtShare),
      _tokenAdapter,
      _data
    );
    // Moves the amount from the position to proxy's address
    moveCollateral(_manager, _positionId, address(this), _collateralAmountInWad, _tokenAdapter, _data);
    // Withdraws token amount to the user's wallet as a token
    IGenericTokenAdapter(_tokenAdapter).withdraw(msg.sender, _collateralAmount, _data);
  }

  function wipeAllUnlockIbBNBAndConvertToBNB(
    address _vault,
    address _manager,
    address _tokenAdapter,
    address _stablecoinAdapter,
    uint256 _positionId,
    uint256 _collateralAmount, // [wad]
    bytes calldata _data
  ) external {
    wipeAllAndUnlockToken(_manager, _tokenAdapter, _stablecoinAdapter, _positionId, _collateralAmount, _data);
    ibBNBToBNB(_vault, _collateralAmount);
  }

  function wipeAllUnlockTokenAndConvert(
    address _vault,
    address _manager,
    address _tokenAdapter,
    address _stablecoinAdapter,
    uint256 _positionId,
    uint256 _collateralAmount, // [in token decimal]
    bytes calldata _data
  ) external {
    wipeAllAndUnlockToken(_manager, _tokenAdapter, _stablecoinAdapter, _positionId, _collateralAmount, _data);
    ibTokenToToken(_vault, convertTo18(_tokenAdapter, _collateralAmount));
  }

  function harvest(
    address _manager,
    address _tokenAdapter,
    uint256 _positionId,
    address _harvestToken
  ) external {
    address _positionAddress = IManager(_manager).positions(_positionId);
    IGenericTokenAdapter(_tokenAdapter).deposit(_positionAddress, 0, abi.encode());
    transfer(_harvestToken, msg.sender, _harvestToken.myBalance());
  }

  function harvestMultiple(
    address _manager,
    address[] memory _tokenAdapters,
    uint256[] memory _positionIds,
    address _harvestToken
  ) external {
    require(_tokenAdapters.length == _positionIds.length, "tokenAdapters and positionIds length mismatch");

    for (uint256 i = 0; i < _positionIds.length; i++) {
      address _positionAddress = IManager(_manager).positions(_positionIds[i]);
      IGenericTokenAdapter(_tokenAdapters[i]).deposit(_positionAddress, 0, abi.encode());
    }

    transfer(_harvestToken, msg.sender, _harvestToken.myBalance());
  }

  function redeemLockedCollateral(
    address _manager,
    uint256 _positionId,
    address _tokenAdapter,
    bytes calldata _data
  ) external {
    IManager(_manager).redeemLockedCollateral(_positionId, _tokenAdapter, address(this), _data);
  }
}