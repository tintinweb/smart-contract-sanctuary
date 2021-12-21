// SPDX-License-Identifier: UNLICENSED

// Copyright (c) WildCredit - All rights reserved
// https://twitter.com/WildCredit

import "IERC20.sol";
import "ILinkOracle.sol";
import "IPriceOracle.sol";
import "SafeOwnable.sol";

pragma solidity 0.8.6;

contract LinkPriceOracle is IPriceOracle, SafeOwnable {

  uint public MIN_ORACLE_FRESHNESS = 3 hours;

  mapping(address => ILinkOracle) public linkOracles;
  mapping(address => uint) private tokenPrices;

  event AddLinkOracle(address indexed token, address oracle);
  event RemoveLinkOracle(address indexed token);
  event PriceUpdate(address indexed token, uint amount);

  function addLinkOracle(address _token, ILinkOracle _linkOracle) external onlyOwner {
    require(_linkOracle.decimals() == 8, "LinkPriceOracle: non-usd pairs not allowed");
    linkOracles[_token] = _linkOracle;

    emit AddLinkOracle(_token, address(_linkOracle));
  }

  function removeLinkOracle(address _token) external onlyOwner {
    linkOracles[_token] = ILinkOracle(address(0));
    emit RemoveLinkOracle(_token);
  }

  function setTokenPrice(address _token, uint _value) external onlyOwner {
    tokenPrices[_token] = _value;
    emit PriceUpdate(_token, _value);
  }

  // _token price in USD with 18 decimals
  function tokenPrice(address _token) public view override returns(uint) {

    if (tokenPrices[_token] != 0) {
      return tokenPrices[_token];

    } else if (address(linkOracles[_token]) != address(0)) {

      (, int answer, , uint updatedAt, ) = linkOracles[_token].latestRoundData();
      uint result = uint(answer);
      uint timeElapsed = block.timestamp - updatedAt;
      require(result > 1, "LinkPriceOracle: invalid oracle value");
      require(timeElapsed <= MIN_ORACLE_FRESHNESS, "LinkPriceOracle: oracle is stale");

      return result * 1e10;

    } else {
      revert("LinkPriceOracle: token not supported");
    }
  }

  function convertTokenValues(address _fromToken, address _toToken, uint _amount) external view override returns(uint) {
    uint priceFrom = tokenPrice(_fromToken) * 1e18 / 10 ** IERC20(_fromToken).decimals();
    uint priceTo   = tokenPrice(_toToken)   * 1e18 / 10 ** IERC20(_toToken).decimals();
    return _amount * priceFrom / priceTo;
  }

  function tokenSupported(address _token) external view override returns(bool) {
    return (
      address(linkOracles[_token]) != address(0) ||
      tokenPrices[_token] != 0
    );
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

interface ILinkOracle {
  function decimals() external view returns(int256);

  function latestRoundData() external view returns (
    uint80  roundId,
    int256  answer,
    uint256 startedAt,
    uint256 updatedAt,
    uint80  answeredInRound
  );
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