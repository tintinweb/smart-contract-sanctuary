// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Pausable.sol";
import "./AccessControl.sol";
import "./SafeERC20.sol";

import "./Whitelist.sol";
import "./TokenAllocation.sol";

/// @custom:security-contact [email protected]
contract WhitelistSale is Pausable, AccessControl, Whitelist, TokenAllocation {
  using SafeERC20 for IERC20;

  event IGO(uint256 indexed timestamp);

  bytes32 public constant OPERATIONS_ROLE = keccak256("OPERATIONS_ROLE");

  IERC20 public immutable busd;
  uint256 public immutable mhtOnSale;
  uint256 public immutable mhtToBusd;
  uint256 public immutable minMhtAmount;
  uint256 public immutable maxMhtAmount;

  uint256 public mhtSold;

  constructor(
    address _mhtOwner,
    IERC20 _mht,
    IERC20 _busd,
    uint256 _mhtOnSale,
    uint256 _mhtToBusd,
    uint256 _minMhtAmount,
    uint256 _maxMhtAmount,
    uint256 _unlockAtIGOPercent,
    uint256 _cliffMonths,
    uint256 _vestingPeriodMonths
  )
    TokenAllocation(
      _mhtOwner,
      _mht,
      _unlockAtIGOPercent,
      _cliffMonths,
      _vestingPeriodMonths
    )
  {
    require(_busd != IERC20(address(0)), "zero busd");

    _setupRole(DEFAULT_ADMIN_ROLE, _mhtOwner);
    _setupRole(OPERATIONS_ROLE, _mhtOwner);

    busd = _busd;
    mhtOnSale = _mhtOnSale;
    mhtToBusd = _mhtToBusd;
    minMhtAmount = _minMhtAmount;
    maxMhtAmount = _maxMhtAmount;
  }

  function pause() public onlyRole(OPERATIONS_ROLE) {
    _pause();
  }

  function unpause() public onlyRole(OPERATIONS_ROLE) {
    _unpause();
  }

  function setIgoTimestamp(uint256 _igoTimestamp)
    public
    onlyRole(OPERATIONS_ROLE)
    whenNotPaused
  {
    _setIgoTimestamp(_igoTimestamp);
    emit IGO(_igoTimestamp);
  }

  function buy(uint256 _mhtAmount)
    public
    whenNotPaused
    beforeIGO
    whitelisted(msg.sender)
  {
    require(_mhtAmount >= minMhtAmount, "Sale: amount less than min");
    require(_mhtAmount <= maxMhtAmount, "Sale: amount greater than max");
    require(
      _getUserTotalTokens(msg.sender) + _mhtAmount <= maxMhtAmount,
      "Sale: total greater than max"
    );
    require(
      mhtSold + _mhtAmount <= mhtOnSale,
      "Sale: total MHT on sale reached"
    );

    mhtSold += _mhtAmount;

    uint256 busdAmount = (_mhtAmount * mhtToBusd) / 1e18;

    busd.safeTransferFrom(msg.sender, mhtOwner, busdAmount);
    _updateUserTokenAllocation(msg.sender, _mhtAmount);
  }

  function addToWhitelist(address[] memory _buyers)
    public
    onlyRole(OPERATIONS_ROLE)
    whenNotPaused
  {
    _addToWhitelist(_buyers);
  }

  function removeFromWhitelist(address[] memory _buyers)
    public
    onlyRole(OPERATIONS_ROLE)
    whenNotPaused
  {
    _removeFromWhitelist(_buyers);
  }
}