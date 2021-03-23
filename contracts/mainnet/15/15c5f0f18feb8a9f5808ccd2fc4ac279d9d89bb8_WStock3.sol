// SPDX-License-Identifier: MIT

pragma solidity 0.7.3;

import "./SafeMath.sol";
import "./IERC20.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

contract WStock3 is ReentrancyGuard, Context, Ownable {
  using SafeMath for uint256;

  constructor (address _gasToken ,address _authAddress, address payable _holdingAddress, uint256 _feeRate, uint256 _acceptableTolerance, uint256 _reserve) {
    GAS_TOKEN = IERC20(_gasToken);
    authAddress = _authAddress;
    holdingAddress = _holdingAddress;
	  feeRate = _feeRate;
    acceptableTolerance = _acceptableTolerance;
    reserve = _reserve;
  }

  modifier onlyAuthorized() {
    require(authAddress == _msgSender(), "Unauthorized usage");
    _;
  }

  IERC20 private GAS_TOKEN;
  mapping(bytes32 => IERC20) public stocks;

  address private authAddress;
  address payable private holdingAddress;
  uint256 private feeRate;
  uint256 private acceptableTolerance;
  uint256 private reserve;
  uint256 public totalTrades;

  event Trade(uint256 indexed tradeId, address account, bytes32 ticker, bool isBuy, uint256 amount, uint256 total, uint256 fee);
  event Reload(uint256 indexed amount, uint256 timestamp);

  function buy(bytes32 ticker, uint256 amount, uint256 timestamp, uint8 v, bytes32 r, bytes32 s) public payable nonReentrant { // replaced total with msg.value
    require(amount > 0, "Must buy an amount of tokens");
    require(msg.value > 0, "total must be greater than zero");
    bytes32 hash = keccak256(abi.encode(_msgSender(), ticker, amount, msg.value, timestamp));
    address signer = ecrecover(hash, v, r, s);
    require(signer == authAddress, "Invalid signature");
    require(timestamp.add(acceptableTolerance) > block.timestamp, "Expired Order");
    require(address(stocks[ticker]) != address(0), "unsupported asset");
    uint256 fee = msg.value.mul(feeRate);
    require(fee <= GAS_TOKEN.balanceOf(_msgSender()), 'insufficient gas token balance');

    totalTrades++;
    emit Trade(totalTrades, _msgSender(), ticker, true, amount, msg.value, fee);
    stocks[ticker].mint(_msgSender(), amount);
    GAS_TOKEN.transferFrom(_msgSender(), holdingAddress, fee);
    if (address(this).balance >= reserve) {
      _safeTransfer(holdingAddress, msg.value);
    }
    else {
      emit Reload(reserve.sub(address(this).balance), block.timestamp);
    }
  }

  function sell(bytes32 ticker, uint256 amount, uint256 total, uint256 timestamp, uint8 v, bytes32 r, bytes32 s) public nonReentrant {
    require(amount > 0, "Must select an amount of tokens");
    require(total > 0, "total must be greater than zero");
    require(amount <= stocks[ticker].balanceOf(_msgSender()), "Cannot sell more than balance");
    bytes32 hash = keccak256(abi.encode(_msgSender(), ticker, amount, total, timestamp));
    address signer = ecrecover(hash, v, r, s);
    require(signer == authAddress, "Invalid signature");
    require(timestamp.add(acceptableTolerance) > block.timestamp, "Expired Order");
    require(total <= address(this).balance, "insufficient funds, try again later");
    require(address(stocks[ticker]) != address(0), "unsupported asset");
    uint256 fee = total.mul(feeRate);
    require(fee <= GAS_TOKEN.balanceOf(_msgSender()), 'insufficient gas token balance');

    totalTrades++;
    emit Trade(totalTrades, _msgSender(), ticker, false, amount, total, fee);
    stocks[ticker].transferFrom(_msgSender(), address(this), amount);
    stocks[ticker].burn(amount);
    GAS_TOKEN.transferFrom(_msgSender(), holdingAddress, fee);
    _safeTransfer(_msgSender(), total);
    if (address(this).balance < reserve) {
      emit Reload(reserve.sub(address(this).balance), block.timestamp);
    }
  }

  function addStock(bytes32 _ticker, IERC20 _asset) public onlyAuthorized {
    stocks[_ticker] = _asset;
  }

  function getReserve()  public view returns(uint256) {
    return reserve;
  }
  function setReserve(uint256 _reserve) public payable onlyAuthorized {
    reserve = _reserve;
  }

  function getAuthAddress() public view returns (address) {
    return authAddress;
  }
  function setAuthAddress(address payable _authAddress) public onlyAuthorized {
    authAddress = _authAddress;
  }

  function getFeeRate() public view returns (uint256) {
    return feeRate;
  }
  function setFeeRate(uint256 _feeRate) public onlyAuthorized {
    feeRate = _feeRate;
  }

  function getAcceptableTolerance()  public view returns(uint256) {
    return acceptableTolerance;
  }
  function setAcceptableTolerance(uint256 _acceptableTolerance) public onlyAuthorized {
    acceptableTolerance = _acceptableTolerance;
  }

  function _safeTransfer(address payable to, uint256 amount) internal {
    uint256 balance;
    balance = address(this).balance;
    if (amount > balance) {
        amount = balance;
    }
    Address.sendValue(to, amount);
  }

}