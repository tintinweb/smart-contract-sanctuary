/**
 *Submitted for verification at BscScan.com on 2021-07-10
*/

/**
 *Submitted for verification at BscScan.com on 2021-06-28
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;

abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this;
    return msg.data;
  }
}

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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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



contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () internal {
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



/*
PandaStake:
30% first day
5% for last 6th day
*/

interface IPandaStake {
  function updateRXBalances(address account) external returns (uint256);
  function getTransferXFee(address account, uint256 remain) external returns (uint256, uint256);
  function addToRXBalance(address account, uint256 rAmount) external returns (uint256);
  function isHolder(address account) external view returns (bool);
  function removeFromHolders(address account) external;
}

contract PandaStake is IPandaStake, Context, Ownable {
  using SafeMath for uint256;

  // staking
  uint256 private constant XLEN = 36;
  uint256[36] private XFEE_DISTRIBUTION_PERCENT = [
  30,30,30,30,30,30,
  25,25,25,25,25,25,
  20,20,20,20,20,20,
  15,15,15,15,15,15,
  10,10,10,10,10,10,
  5,5,5,5,5,5];

  uint256 private constant INTERVAL = 1 seconds;
  mapping (address => mapping (uint256 => uint256)) private _rXBalances;
  address pandaHelpAddress;
  
  modifier onlyPandaHelp() {
    require(pandaHelpAddress == _msgSender(), "Caller is not the pandaHelp contract");
    _;  
  }

  constructor () public {
  }


  function setPandaHelpAddress(address newPandaHelp) public virtual onlyOwner {
    require(newPandaHelp != address(0), "Ownable: new PandaHelp is the zero address");
    emit OwnershipTransferred(pandaHelpAddress, newPandaHelp);
    pandaHelpAddress = newPandaHelp;
  }

    function isHolder(address account) external view override onlyPandaHelp() returns (bool) {
      return _rXBalances[account][XLEN] != 0;
    }
    
    function removeFromHolders(address account) external override onlyPandaHelp() {
        require(_rXBalances[account][XLEN] != 0);
        for (uint256 i = 0; i <= XLEN; i++) {
            _rXBalances[account][i] = 0;
        }
        
    }

  function getTransferXFee(address account, uint256 remain) external override onlyPandaHelp() returns (uint256, uint256) {
    uint256 rXFee;
    uint256 freeSum;
    uint256 offsetDelta = (now - _rXBalances[account][XLEN]).div(INTERVAL);

    // prevent case when left more periods then we hold in array
    if (offsetDelta > XLEN) {
      offsetDelta = XLEN;
    }

    for (uint256 i = XLEN - offsetDelta; i < XLEN ; i++) {
      if (remain != 0 && _rXBalances[account][i] != 0) {
        if (remain <= _rXBalances[account][i]) {
          freeSum = freeSum.add(_rXBalances[account][i] - remain);
          remain = 0;
        } else {
          remain = remain.sub(_rXBalances[account][i]);
        }
      } else {
        freeSum = freeSum.add(_rXBalances[account][i]);
      }
    }


    uint256 temp;
    // making offset of tokens in array
    for (uint256 i = XLEN; i > offsetDelta; i--) {
      temp = _rXBalances[account][i - offsetDelta - 1]; // 9 - 1 = 8
      if (remain != 0 && temp != 0) {
        if (remain <= temp) {
          rXFee = rXFee.add(remain.mul(XFEE_DISTRIBUTION_PERCENT[i-1]).div(100));
          temp = temp.sub(remain);
          remain = 0;
        } else {
          rXFee = rXFee.add(temp.mul(XFEE_DISTRIBUTION_PERCENT[i-1]).div(100));
          remain = remain.sub(temp);
          temp = 0;
        }
      }
      _rXBalances[account][i] = temp;
    }

    // setting zero to past
    for (uint256 i = 0; i < offsetDelta; i++) {
      _rXBalances[account][i] = 0;
    }

    if (offsetDelta > 0 ) {
      _rXBalances[account][XLEN] = now;
    }

    return (rXFee, freeSum);
  }

  function addToRXBalance(address account, uint256 rAmount) external override onlyPandaHelp() returns (uint256) {
    uint256 freeSum = updateRXBalances(account);
    _rXBalances[account][0] = _rXBalances[account][0].add(rAmount);
    return freeSum;
  }

  function updateRXBalances(address account) public override onlyPandaHelp() returns (uint256) {
    uint256 delta = now - _rXBalances[account][XLEN];
    uint256 offsetDelta = delta.div(INTERVAL);

    if (offsetDelta > 0) {
      // prevent case when left more periods then we hold in array
      if (offsetDelta > XLEN) {
        offsetDelta = XLEN;
      }

      // get sum of tokens free from extra fee
      uint256 freeSum;
      for (uint256 i = XLEN - offsetDelta; i <= XLEN-1; i++) {
        freeSum = freeSum.add(_rXBalances[account][i]);
      }

      // making offset of tokens in array
      for (uint256 i = XLEN-1; i >= offsetDelta; i--) {
        _rXBalances[account][i] = _rXBalances[account][i - offsetDelta];
      }

      // setting zero to past
      for (uint256 i = 0; i < offsetDelta; i++) {
        _rXBalances[account][i] = 0;
      }
      _rXBalances[account][XLEN] = now;
      return freeSum;
    }
    return 0;
  }
}