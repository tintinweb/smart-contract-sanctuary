/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT

interface IERC20 {
  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function decimals() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);
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
    require(_owner == _msgSender(), "Ow1");
    _;
  }
  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ow2");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b, "mul e0");
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "div e0");
    uint256 c = a / b;
    return c;
  }
}

contract Map is Ownable {
  using SafeMath for uint256;
  IERC20 private r_fee_token;
  IERC20 private r_usdt_token;
  IMdexPair private r_fee_pair;
  address private r_router_address;
  uint256 private r_tx_fee_rate;
  uint256 private r_tx_fee_type;
  address private r_tx_fee_address;


  struct token_info_item {
    address token_address;
    string name;
    string symbol;
    uint256 decimals;
    uint256 balance;
  }

  function getTokenInfo(IERC20 _token, address _user) public view returns (token_info_item memory token_info) {
    token_info.token_address = address(_token);
    token_info.name = _token.name();
    token_info.symbol = _token.symbol();
    token_info.decimals = _token.decimals();
    token_info.balance = _token.balanceOf(_user);
  }

  function set(IERC20 _fee_token, IERC20 _usdt_token, IMdexPair _fee_pair, address _router_address, uint256 _tx_fee_rate, uint256 _tx_fee_type, address _tx_fee_address) public onlyOwner {
    r_fee_token = _fee_token;
    r_usdt_token = _usdt_token;
    r_fee_pair = _fee_pair;
    r_router_address = _router_address;
    r_tx_fee_rate = _tx_fee_rate;
    r_tx_fee_type = _tx_fee_type;
    r_tx_fee_address = _tx_fee_address;
  }

  function setTxFeeRate(uint256 _tx_fee_rate) public onlyOwner {
    r_tx_fee_rate = _tx_fee_rate;
  }

  function setTxFeeType(uint256 _tx_fee_type) public onlyOwner {
    r_tx_fee_type = _tx_fee_type;
  }

  function getPrice() internal view returns (uint256) {
    if (address(r_fee_pair) == address(0)) {
      return 0;
    }
    address token0_new = IMdexPair(r_fee_pair).token0();
    address token1_new = IMdexPair(r_fee_pair).token1();
    (uint256 _reserve0,uint256  _reserve1,) = IMdexPair(r_fee_pair).getReserves();
    uint256 decimals0 = IERC20(token0_new).decimals();
    uint256 decimals1 = IERC20(token1_new).decimals();
    uint256 price1 = _reserve0.mul(10 ** 18).mul(10 ** decimals1).div(_reserve1).div(10 ** decimals0);
    uint256 price2 = _reserve1.mul(10 ** 18).mul(10 ** decimals0).div(_reserve0).div(10 ** decimals1);
    uint256 tx_price;
    if (token0_new == address(r_fee_token))
      tx_price = price1;
    else
      tx_price = price2;
    return tx_price;
  }

  function getFeeNum() public view returns (uint256 tx_price, uint256 tx_fee_rate, uint256 tx_fee_type, uint256 fee_token_decimals, uint256 usdt_token_decimals, IERC20 fee_token, IERC20 usdt_token, address tx_fee_address, address router_address) {
    tx_price = getPrice();
    tx_fee_rate = r_tx_fee_rate;
    tx_fee_type = r_tx_fee_type;
    fee_token_decimals = 18;
    usdt_token_decimals = 18;
    if (address(r_fee_token) != address(0)) {
      fee_token_decimals = r_fee_token.decimals();
    }
    if (address(r_usdt_token) != address(0)) {
      usdt_token_decimals = r_usdt_token.decimals();
    }
    fee_token = r_fee_token;
    usdt_token = r_usdt_token;
    tx_fee_address = r_tx_fee_address;
    router_address = r_router_address;
  }

}