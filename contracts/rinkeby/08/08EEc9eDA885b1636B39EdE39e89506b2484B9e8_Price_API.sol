/**
 *Submitted for verification at Etherscan.io on 2021-05-30
*/

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
interface IERC20 {
  //  function totalSupply() external view returns (uint256);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function decimals() external view returns (uint256);

  //  function balanceOf(address account) external view returns (uint256);
  //
  //  function transfer(address recipient, uint256 amount) external returns (bool);
  //
  //  function allowance(address owner, address spender) external view returns (uint256);
  //
  //  function approve(address spender, uint256 amount) external returns (bool);
  //
  //  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  //
  //  event Transfer(address indexed from, address indexed to, uint256 value);
  //  event Approval(address indexed owner, address indexed spender, uint256 value);
}


interface IMdexPair {
  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}


abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this;
    return msg.data;
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

library Address {
  function isContract(address account) internal view returns (bool) {
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    assembly {codehash := extcodehash(account)}
    return (codehash != accountHash && codehash != 0x0);
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");
    (bool success,) = recipient.call{value : amount}("");
    require(success, "Address: unable to send value, recipient may have reverted");
  }

  function functionCall(address target, bytes memory data) internal returns (bytes memory) {
    return functionCall(target, data, "Address: low-level call failed");
  }

  function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
    return _functionCallWithValue(target, data, 0, errorMessage);
  }

  function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
    return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
  }

  function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
    require(address(this).balance >= value, "Address: insufficient balance for call");
    return _functionCallWithValue(target, data, value, errorMessage);
  }

  function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
    require(isContract(target), "Address: call to non-contract");
    (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
    if (success) {
      return returndata;
    } else {
      if (returndata.length > 0) {
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
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


contract Price_API is Ownable {
  using SafeMath for uint256;
  using Address for address;
  IERC20 public fee_token;
  IMdexPair public fee_pair;

  function setFeeToken(IERC20 _address) public onlyOwner {
    fee_token = _address;
  }

  function setFeePair(IMdexPair _address) public onlyOwner {
    fee_pair = _address;
  }


  function getFeeNum() public view returns (uint256 price,IERC20 fee_token2) {
    address token0_new = IMdexPair(fee_pair).token0();
    address token1_new = IMdexPair(fee_pair).token1();
    (uint256 _reserve0,uint256  _reserve1,) = IMdexPair(fee_pair).getReserves();
    uint256 decimals0 = IERC20(token0_new).decimals();
    uint256 decimals1 = IERC20(token1_new).decimals();
    uint256 price1 = _reserve0.mul(10 ** 18).mul(10 ** decimals1).div(_reserve1).div(10 ** decimals0);
    uint256 price2 = _reserve1.mul(10 ** 18).mul(10 ** decimals0).div(_reserve0).div(10 ** decimals1);
    fee_token2 = fee_token;
    if (token0_new == address(fee_token))
      price = price1;
    else
      price = price2;
  }
}