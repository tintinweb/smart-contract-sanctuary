// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "IERC20.sol";
import "IPriceOracle.sol";
import "SafeOwnable.sol";

interface IExternalOracle {
  function price(address _token) external view returns (uint);
}

contract OracleAggregator is IPriceOracle, SafeOwnable {

  address internal constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

  mapping (address => IExternalOracle) public oracles;

  event SetOracle(address indexed token, address indexed oracle);

  function setOracle(address _token, IExternalOracle _value) external onlyOwner {
    oracles[_token] = _value;
    emit SetOracle(_token, address(_value));
  }

  function tokenPrice(address _token) public view override returns(uint) {
    if (_token == WETH) { return 1e18; }
    return oracles[_token].price(_token);
  }

  // Not used in any code to save gas. But useful for external usage.
  function convertTokenValues(address _fromToken, address _toToken, uint _amount) external view override returns(uint) {
    uint priceFrom = tokenPrice(_fromToken) * 1e18 / 10 ** IERC20(_fromToken).decimals();
    uint priceTo   = tokenPrice(_toToken)   * 1e18 / 10 ** IERC20(_toToken).decimals();
    return _amount * priceFrom / priceTo;
  }

  function tokenSupported(address _token) external view override returns(bool) {
    if (_token == WETH) { return true; }
    return address(oracles[_token]) != address(0);
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.0;

interface IERC20 {
  function totalSupply() external view returns (uint);
  function balanceOf(address account) external view returns(uint);
  function transfer(address recipient, uint256 amount) external returns(bool);
  function allowance(address owner, address spender) external view returns(uint);
  function decimals() external view returns(uint8);
  function approve(address spender, uint amount) external returns(bool);
  function transferFrom(address sender, address recipient, uint amount) external returns(bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IPriceOracle {

  function tokenPrice(address _token) external view returns(uint);
  function tokenSupported(address _token) external view returns(bool);
  function convertTokenValues(address _fromToken, address _toToken, uint _amount) external view returns(uint);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "IOwnable.sol";

contract SafeOwnable is IOwnable {

  uint public constant RENOUNCE_TIMEOUT = 1 hours;

  address public override owner;
  address public pendingOwner;
  uint public renouncedAt;

  event OwnershipTransferInitiated(address indexed previousOwner, address indexed newOwner);
  event OwnershipTransferConfirmed(address indexed previousOwner, address indexed newOwner);

  constructor() {
    owner = msg.sender;
    emit OwnershipTransferConfirmed(address(0), msg.sender);
  }

  modifier onlyOwner() {
    require(isOwner(), "Ownable: caller is not the owner");
    _;
  }

  function isOwner() public view returns (bool) {
    return msg.sender == owner;
  }

  function transferOwnership(address _newOwner) external override onlyOwner {
    require(_newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferInitiated(owner, _newOwner);
    pendingOwner = _newOwner;
  }

  function acceptOwnership() external override {
    require(msg.sender == pendingOwner, "Ownable: caller is not pending owner");
    emit OwnershipTransferConfirmed(msg.sender, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }

  function initiateRenounceOwnership() external onlyOwner {
    require(renouncedAt == 0, "Ownable: already initiated");
    renouncedAt = block.timestamp;
  }

  function acceptRenounceOwnership() external onlyOwner {
    require(renouncedAt > 0, "Ownable: not initiated");
    require(block.timestamp - renouncedAt > RENOUNCE_TIMEOUT, "Ownable: too early");
    owner = address(0);
    pendingOwner = address(0);
    renouncedAt = 0;
  }

  function cancelRenounceOwnership() external onlyOwner {
    require(renouncedAt > 0, "Ownable: not initiated");
    renouncedAt = 0;
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IOwnable {
  function owner() external view returns(address);
  function transferOwnership(address _newOwner) external;
  function acceptOwnership() external;
}