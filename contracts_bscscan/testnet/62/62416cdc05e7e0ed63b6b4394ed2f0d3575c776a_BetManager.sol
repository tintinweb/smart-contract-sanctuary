/**
 *Submitted for verification at BscScan.com on 2021-11-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract BetManager is Context, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) public balances;

  uint256 public roundNo = 1;
  uint256 public dimension = 3;
  uint256 public totalCells = dimension * dimension;
  uint256 public price = 1 * 10**16;  // 0.01 ETH

  mapping (address => uint8) public bets;
  address[] public betters;
  uint256 public totalBets = 0;
  uint256 public maxBets = 2 * totalCells - 1;
  uint8 public maxBetsPerAddress = 3;

  bool public stopped = false;
  bool private _processedPrize = false;

  uint256 public serviceFee = 10; // percentage
  uint256 private totalFees = 0;

  address public constant partner1 = 0x620dc94C842817d5d8b8207aa2DdE4f8C8b73415;
  address public constant partner2 = 0xD65F49a69652FBefF31DF87400b26Eb4C3f01B2c;

  uint256 public constant partner1Share = 50;  // partner1 50%
  uint256 public constant partner2Share = 50;  // partner2 50%

  event DimensionUpdated(uint256 _dimension);
  event PriceUpdated(uint256 _price);
  event MaxBetsPerAddressUpdated(uint8 _maxValue);
  event ServiceFeeUpdated(uint256 _newFee);

  event Started(uint256 indexed _roundNo);
  event Stopped(uint256 indexed _roundNo);
  event EmergencyStopped(uint256 indexed _roundNo);
  event Wins(uint256 indexed _roundNo, uint256 _totalWinners);

  modifier onlyStopped() {
    require(stopped == true, "Not stopped yet");
    _;
  }

  modifier onlyStarted() {
    require(stopped == false, "Not started yet");
    _;
  }

  function status() external view  returns (uint256, uint256, uint256, uint8, uint256, bool, uint256, uint256){
    return (dimension, totalCells, maxBets, maxBetsPerAddress, price, stopped, roundNo, totalBets);
  }

  function start() external onlyOwner() onlyStopped() {
    // reset all status before new round
    while(betters.length > 0) {
      bets[betters[betters.length - 1]] = 0;
      betters.pop();
    }
    totalBets = 0;

    roundNo ++;
    stopped = false;
    _processedPrize = false;
    emit Started(roundNo);
  }

  function bet() external payable onlyStarted() {
    require(msg.sender == tx.origin, "Only EOA");
    require(msg.value >= price, "Not sent enough ETH");
    require(bets[_msgSender()] < maxBetsPerAddress, "Not allowed bulk bets");

    uint256 remaining = msg.value - price;
    if (remaining > 0) {
      (bool success, ) = msg.sender.call{value: remaining}("");
      require(success);
    }

    if (bets[_msgSender()] == 0) {
      betters.push(_msgSender());
    }
    bets[_msgSender()] ++;
    totalBets ++;

    if (totalBets == maxBets) {
      stopped = true;
      emit Stopped(roundNo);
    }
  }

  function emergencyStop() external onlyOwner() onlyStarted() {
    uint8 _betTimes;
    stopped = true;

    // refund all betting amount
    for (uint256 index = 0; index < betters.length; index ++) {
      if (bets[betters[index]] == 0) {
        continue;
      }
      _betTimes = bets[betters[index]];
      bets[betters[index]] = 0;
      _widthdraw(betters[index], price * _betTimes);
    }

    emit EmergencyStopped(roundNo);
  }

  function setPrice(uint256 _price) external onlyOwner() onlyStopped() {
    require(_price > 0, "Price should not be 0");
    price = _price;
    emit PriceUpdated(price);
  }

  function setServiceFee(uint256 _fee) external onlyOwner() onlyStopped() {
    require(_fee > 0 && _fee < 50, "Invalid fee rate");
    serviceFee = _fee;

    emit ServiceFeeUpdated(serviceFee);
  }

  function setDimension(uint256 _dimension) external onlyOwner() onlyStopped() {
    require(_dimension >= 3 && _dimension < 200, "Dimension should be between 3 ~ 200");
    dimension = _dimension;
    totalCells = dimension * dimension;
    maxBets = 2 * totalCells - 1;
    emit DimensionUpdated(dimension);
  }

  function setMaxBetsPerAddress(uint8 _maxBetsPerAddress) external onlyOwner() onlyStopped() {
    require(_maxBetsPerAddress < totalCells >> 1, "Too large limit");
    maxBetsPerAddress = _maxBetsPerAddress;
    emit MaxBetsPerAddressUpdated(maxBetsPerAddress);
  }

  /**
    After game is over, sets the total winners, and based on that, it will deposit winners prize
   */
  function processFunds(uint256 _totalWinners, address[] calldata _winners) external onlyOwner() onlyStopped() {
    require(!_processedPrize, "Already done!");
    require(_totalWinners < totalCells, "Incorrect winners");
    require(_totalWinners == _winners.length, "Winners mismatch");

    uint256 roundBalance = price.mul(maxBets);
    if (_totalWinners > 0) {
      uint256 roundFee = roundBalance.mul(serviceFee).div(100);
      uint256 roundPrize = roundBalance.sub(roundFee);
      uint256 unitPrize = roundPrize.div(_totalWinners);

      for (uint256 i = 0; i < _totalWinners; i++) {
        require(bets[_winners[i]] > 0, "Invalid winner");
        bets[_winners[i]] --;
        balances[_winners[i]] += unitPrize;
      }
      totalFees += roundFee;
    } else {
      totalFees += roundBalance;
    }

    _processedPrize = true;
    emit Wins(roundNo, _totalWinners);
  }

  function _widthdraw(address _address, uint256 _amount) private {
    (bool success, ) = _address.call{value: _amount}("");
    require(success, "Transfer failed.");
  }

  /**
    It allows users to withdraw all their winning prize at once.
   */
  function withdraw() external {
    require(balances[_msgSender()] > 0, "No balance yet");
    uint256 _balance = balances[_msgSender()];
    balances[_msgSender()] = 0;
    _widthdraw(_msgSender(), _balance);
  }

  /**
    It allows owners to withdraw all their fees income at once.
   */
  function withdrawFees() external onlyOwner() {
    require(totalFees > 0, "No balance yet");

    uint256 _partner1 = totalFees.mul(partner1Share).div(100);
    uint256 _partner2 = totalFees.mul(partner2Share).div(100);

    _widthdraw(partner1, _partner1);
    _widthdraw(partner2, _partner2);

    totalFees = 0;
  }
}