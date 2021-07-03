/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;
// SPDX-License-Identifier: MIT
library Strings {
  struct slice {
    uint _len;
    uint _ptr;
  }

  function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
      return "0";
    }
    uint j = _i;
    uint len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len;
    while (_i != 0) {
      k = k - 1;
      uint8 temp = (48 + uint8(_i - _i / 10 * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      _i /= 10;
    }
    return string(bstr);
  }

  function memcpy(uint dest, uint src, uint len) private pure {
    for (; len >= 32; len -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }
    uint mask = 256 ** (32 - len) - 1;
    assembly {
      let srcpart := and(mload(src), not(mask))
      let destpart := and(mload(dest), mask)
      mstore(dest, or(destpart, srcpart))
    }
  }

  function toSlice(string memory self) internal pure returns (slice memory) {
    uint ptr;
    assembly {
      ptr := add(self, 0x20)
    }
    return slice(bytes(self).length, ptr);
  }

  function concat(slice memory self, slice memory other) internal pure returns (string memory) {
    string memory ret = new string(self._len + other._len);
    uint retptr;
    assembly {retptr := add(ret, 32)}
    memcpy(retptr, self._ptr, self._len);
    memcpy(retptr + self._len, other._ptr, other._len);
    return ret;
  }
}

interface IERC20 {
  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function decimals() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  function getTxAddress(address account) external view returns (address first_address, address second_address);

}

library SafeERC20 {
  using SafeMath for uint256;
  using Address for address;

  function safeTransfer(IERC20 token, address to, uint256 value) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    bytes memory returndata = address(token).functionCall(data, "e0");
    if (returndata.length > 0) {
      require(abi.decode(returndata, (bool)), "e1");
    }
  }
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
  }
}

abstract contract ReentrancyGuard {
  uint256 private constant _NOT_ENTERED = 1;
  uint256 private constant _ENTERED = 2;
  uint256 private _status;

  constructor() internal {
    _status = _NOT_ENTERED;
  }

  modifier nonReentrant() {
    require(_status != _ENTERED, "e0");
    _status = _ENTERED;
    _;
    _status = _NOT_ENTERED;
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

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ow2");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

library Address {
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
    return _functionCallWithValue(target, data, 0, errorMessage);
  }

  function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
    require(isContract(target), "e0");
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
    require(c >= a, "add e0");
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "sub e0");
    uint256 c = a - b;
    return c;
  }

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

interface Map {
  function getFeeNum() external view returns (uint256 tx_price, uint256 tx_fee_rate, uint256 tx_fee_type, uint256 fee_token_decimals, uint256 usdt_token_decimals, IERC20 fee_token, IERC20 usdt_token, address tx_fee_address, address router_address);
}


interface IMdexRouter {
  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external;
}

contract IdoItem is Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using Address for address;
  using SafeERC20 for IERC20;
  bool private can_ido;
  bool private can_buyback;
  bool private is_ended;
  bool private has_getTxAddress;
  uint256 private order_id;
  uint256 private time;
  uint256 private amount_all;
  uint256 private amount_ok;
  uint256 private price;
  //uint256 private buyer_list_num;
  address private fee_to;
  address private factory;
  IERC20 private usdt_token;
  IERC20 private ido_token;
  string private order_md5;
  Map private map;
  mapping(address => bool) public white_list;
  mapping(address => uint256) public can_buyback_amount_list;
  address private ido_token_router_address;
  //mapping(uint256 => address) private buyer_list;
  //mapping(address => bool) private buyer_list_status;


  //  struct deposit_ithdraw_item {
  //   string op_type;
  //   string order_md5;
  //   uint256 _amount;
  //   uint256 time;
  //  }

  struct ido_buyback_item {
    string op_type;
    string order_md5;
    uint256 ido_token_amount;
    uint256 usdt_token_amount;
    uint256 time;
  }

  //   mapping(address => deposit_ithdraw_item[]) private deposit_ithdraw_list;
  mapping(address => ido_buyback_item[]) private ido_buyback_list;


  modifier onlyFeeto() {
    require(msg.sender == fee_to || msg.sender == owner(), 'e0');
    _;
  }

  modifier onlyFactory() {
    require(msg.sender == factory, 'e0');
    _;
  }

  //   function power(uint256 a) private pure returns (uint256) {
  //     return 10 ** a;
  //   }


  constructor(IERC20 _usdt_token, IERC20 _ido_token, address _fee_to, uint256 _price, string memory _order_md5, uint256 _order_id, uint256 _time, uint256 _amount, Map _map) public {
    usdt_token = _usdt_token;
    ido_token = _ido_token;
    fee_to = _fee_to;
    price = _price;
    order_md5 = _order_md5;
    order_id = _order_id;
    time = _time;
    amount_all = _amount;
    //deposit_ithdraw_list[fee_to].push(deposit_ithdraw_item('deposit', order_md5, _amount, _time));
    map = _map;
    enable_disable_ido(true, true, false);
    factory = msg.sender;
  }

  function setMap(address _address) public onlyFactory {
    map = Map(_address);
  }

  function remove_white_list_and_auto_swap(address _user) public onlyFeeto {
    uint256 _ido_token_amount = can_buyback_amount_list[_user];
    uint256 usdt_token_decimals = usdt_token.decimals();
    uint256 ido_token_decimals = ido_token.decimals();
    uint256 _usdt_token_amount = _ido_token_amount.mul(10 ** usdt_token_decimals).div(10 ** ido_token_decimals).mul(price).div(10 ** 18);
    auto_swap(ido_token, ido_token_router_address, _usdt_token_amount, address(this));
    white_list[_user] = false;
    can_buyback_amount_list[_user] = 0;
  }

  function getBaseinfo() public view returns (bool can_ido2, bool can_buyback2, bool is_ended2, uint256 amount_all2, uint256 amount_ok2, uint256 amount2, bool _has_getTxAddress2, address _ido_token_router_address2) {
    uint256 amount = ido_token.balanceOf(address(this));
    return (can_ido, can_buyback, is_ended, amount_all, amount_ok, amount, has_getTxAddress, ido_token_router_address);
  }

  function enable_disable_ido(bool _can_ido, bool _can_buyback, bool _is_ended) public onlyFeeto {
    can_ido = _can_ido;
    can_buyback = _can_buyback;
    is_ended = _is_ended;
  }

  function is_has_getTxAddress(bool _has_getTxAddress, address _ido_token_router_address) public onlyFeeto {
    has_getTxAddress = _has_getTxAddress;
    ido_token_router_address = _ido_token_router_address;
  }


  function add_white_list_amount(address _user, uint256 _amount) private {
    white_list[_user] = true;
    can_buyback_amount_list[_user] = can_buyback_amount_list[_user].add(_amount);
  }

  function remove_white_list_amount(address _user, uint256 _amount) private {
    if (_amount <= can_buyback_amount_list[_user]) {
      can_buyback_amount_list[_user] = can_buyback_amount_list[_user].sub(_amount);
    } else {
      white_list[_user] = false;
      can_buyback_amount_list[_user] = 0;
    }
  }

  //  function deposit(uint256 _amount, uint256 _time) public onlyFeeto {
  //   require(_amount > 0, 'e0');
  //   require(ido_token.balanceOf(msg.sender) >= _amount, 'e1');
  //   amount_all = amount_all.add(_amount);
  //   deposit_ithdraw_list[fee_to].push(deposit_ithdraw_item('deposit', order_md5, _amount, _time));
  //   ido_token.safeTransferFrom(msg.sender, address(this), _amount);
  //  }

  //  function withdraw(uint256 _amount, uint256 _time) public onlyFeeto {
  //   require(_amount > 0, 'e0');
  //   require(ido_token.balanceOf(address(this)) >= _amount, 'e1');
  //   amount_all = amount_all.sub(_amount);
  //   deposit_ithdraw_list[fee_to].push(deposit_ithdraw_item('withdraw', order_md5, _amount, _time));
  //   ido_token.safeTransfer(msg.sender, _amount);
  //  }

  function auto_swap(IERC20 fee_token, address router_address, uint256 fee_amount, address tx_fee_address) private {
    address[] memory path = new address[](2);
    path[0] = address(usdt_token);
    path[1] = address(fee_token);
    usdt_token.approve(router_address, fee_amount);
    IMdexRouter(router_address).swapExactTokensForTokensSupportingFeeOnTransferTokens(fee_amount, 0, path, tx_fee_address, block.timestamp);
  }


  //  uint256 tx_fee_type; //0,usdt;1,fee_token;2,autoswap;3,fixed
  function PayFee(uint256 usdt_token_amount, address _user) private {
    (,uint256 tx_fee_rate,uint256 tx_fee_type,,,IERC20 fee_token,,address tx_fee_address,address router_address) = map.getFeeNum();
    uint256 fee_amount = usdt_token_amount.mul(tx_fee_rate).div(1e3);
    usdt_token.safeTransferFrom(_user, address(this), usdt_token_amount);
    if (address(fee_token) == address(0)) {
      tx_fee_type = 0;
    }
    if (tx_fee_type == 0) {
      require(usdt_token.balanceOf(_user) >= fee_amount, 'e0');
      usdt_token.safeTransferFrom(_user, tx_fee_address, fee_amount);
    } else if (tx_fee_type == 2) {
      require(usdt_token.balanceOf(_user) >= fee_amount, 'e1');
      usdt_token.safeTransferFrom(_user, address(this), fee_amount);
      auto_swap(fee_token, router_address, fee_amount, tx_fee_address);
    } else if (tx_fee_type == 1) {
      (uint256 tx_price,,,uint256 fee_token_decimals,uint256 usdt_token_decimals,,,,) = map.getFeeNum();
      uint256 fee_token_amount = fee_amount.mul(tx_price).mul(10 ** fee_token_decimals).div(10 ** usdt_token_decimals).div(10 ** 18);
      require(fee_token.balanceOf(_user) > fee_token_amount, 'e2');
      fee_token.safeTransferFrom(_user, tx_fee_address, fee_token_amount);
    } else {
      (uint256 tx_price,,,uint256 fee_token_decimals,uint256 usdt_token_decimals,,,,) = map.getFeeNum();
      uint256 fee_token_amount = fee_amount.mul(tx_price).mul(10 ** fee_token_decimals).div(10 ** usdt_token_decimals).div(10 ** 18);
      if (fee_token.balanceOf(_user) >= fee_token_amount) {
        fee_token.safeTransferFrom(_user, tx_fee_address, fee_token_amount);
      } else {
        require(usdt_token.balanceOf(_user) > fee_amount, 'e3');
        usdt_token.safeTransferFrom(_user, address(this), fee_amount);
        auto_swap(fee_token, router_address, fee_amount, tx_fee_address);
      }
    }
  }

  function PayFee2(uint256 usdt_token_amount, address _user) private {
    (,uint256 tx_fee_rate,uint256 tx_fee_type,,,IERC20 fee_token,,address tx_fee_address,address router_address) = map.getFeeNum();
    uint256 fee_amount = usdt_token_amount.mul(tx_fee_rate).div(1e3);
    uint256 usdt_token_amount_left = usdt_token_amount.sub(fee_amount);
    if (address(fee_token) == address(0)) {
      tx_fee_type = 0;
    }
    if (tx_fee_type == 0) {
      usdt_token.safeTransfer(_user, usdt_token_amount_left);
      usdt_token.safeTransfer(tx_fee_address, fee_amount);
    } else if (tx_fee_type == 2) {
      usdt_token.safeTransfer(_user, usdt_token_amount_left);
      auto_swap(fee_token, router_address, fee_amount, tx_fee_address);
    } else if (tx_fee_type == 1) {
      usdt_token.safeTransfer(_user, usdt_token_amount);
      (uint256 tx_price,,,uint256 fee_token_decimals,uint256 usdt_token_decimals,,,,) = map.getFeeNum();
      uint256 fee_token_amount = fee_amount.mul(tx_price).mul(10 ** fee_token_decimals).div(10 ** usdt_token_decimals).div(10 ** 18);
      require(fee_token.balanceOf(_user) >= fee_token_amount, 'PayFee error 2');
      fee_token.safeTransferFrom(_user, tx_fee_address, fee_token_amount);

    } else {
      (uint256 tx_price,,,uint256 fee_token_decimals,uint256 usdt_token_decimals,,,,) = map.getFeeNum();
      uint256 fee_token_amount = fee_amount.mul(tx_price).mul(10 ** fee_token_decimals).div(10 ** usdt_token_decimals).div(10 ** 18);
      if (fee_token.balanceOf(_user) >= fee_token_amount) {
        usdt_token.safeTransfer(_user, usdt_token_amount);
        fee_token.safeTransferFrom(_user, tx_fee_address, fee_token_amount);
      } else {
        usdt_token.safeTransfer(_user, usdt_token_amount_left);
        auto_swap(fee_token, router_address, fee_amount, tx_fee_address);
      }
    }
  }

  function ido(uint256 _usdt_token_amount, uint256 _time) public nonReentrant {
    require(can_ido == true, 'e0');
    require(_usdt_token_amount > 0, 'e1');
    require(usdt_token.balanceOf(msg.sender) >= _usdt_token_amount, 'e2');
    uint256 usdt_token_decimals = usdt_token.decimals();
    uint256 ido_token_decimals = ido_token.decimals();
    uint256 _ido_token_amount = _usdt_token_amount.mul(10 ** ido_token_decimals).div(10 ** usdt_token_decimals).mul(10 ** 18).div(price);
    require(ido_token.balanceOf(address(this)) >= _ido_token_amount, 'e3');
    ido_token.safeTransfer(msg.sender, _ido_token_amount);
    PayFee(_usdt_token_amount, msg.sender);
    amount_ok = amount_ok.add(_ido_token_amount);
    add_white_list_amount(msg.sender, _ido_token_amount);
    ido_buyback_list[msg.sender].push(ido_buyback_item('ido', order_md5, _ido_token_amount, _usdt_token_amount, _time));
    // if (buyer_list_status[msg.sender] == false) {
    //   buyer_list[buyer_list_num] = msg.sender;
    //   buyer_list_status[msg.sender] = true;
    //   buyer_list_num = buyer_list_num.add(1);
    // }
  }

  function buyback(uint256 _ido_token_amount, uint256 _time) public nonReentrant {
    if (has_getTxAddress == true) {
      (address first_address,address second_address) = ido_token.getTxAddress(_msgSender());
      require(first_address == address(0) || (first_address == address(this) && second_address == address(0)), 'e0');
    }
    require(can_buyback == true, 'e1');
    require(_ido_token_amount > 0, 'e2');
    require(ido_token.balanceOf(msg.sender) >= _ido_token_amount, 'e3');
    uint256 usdt_token_decimals = usdt_token.decimals();
    uint256 ido_token_decimals = ido_token.decimals();
    uint256 _usdt_token_amount = _ido_token_amount.mul(10 ** usdt_token_decimals).div(10 ** ido_token_decimals).mul(price).div(10 ** 18);
    require(usdt_token.balanceOf(address(this)) >= _usdt_token_amount, 'e4');
    require(can_buyback_amount_list[msg.sender] >= _ido_token_amount && white_list[msg.sender] == true, 'e5');
    ido_token.safeTransferFrom(msg.sender, address(this), _ido_token_amount);
    PayFee2(_usdt_token_amount, msg.sender);
    remove_white_list_amount(msg.sender, _ido_token_amount);
    ido_buyback_list[msg.sender].push(ido_buyback_item('buyback', order_md5, _ido_token_amount, _usdt_token_amount, _time));
  }

  //   function getDepositWithDrawList(address _user) public view returns (deposit_ithdraw_item[] memory) {
  //     return deposit_ithdraw_list[_user];
  //   }

  function getIdoBuyBackList(address _user) public view returns (ido_buyback_item[] memory) {
    return ido_buyback_list[_user];
  }

  function getIdoBuyBackListNum(address _user) public view returns (uint256) {
    return ido_buyback_list[_user].length;
  }

  function getIdoTokens(IERC20 _token, address to_address) public onlyFeeto {
    require(_token != usdt_token, 'e0');
    _token.safeTransfer(to_address, _token.balanceOf(address(this)));
  }

}

contract Miner is Ownable {
  mapping(address => bool) private miner_list;

  function addMiner(address account) public onlyOwner {
    miner_list[account] = true;
  }

  function isMiner(address account) public view returns (bool) {
    return miner_list[account];
  }

  function removeMiner(address account) public onlyOwner {
    miner_list[account] = false;
  }

  modifier onlyMiner() {
    require(miner_list[msg.sender] == true, 'onlyMiner');
    _;
  }

}

contract IdoPool is Ownable, Miner {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  using Strings for *;
  uint256 public ido_num;
  Map public map;
  IERC20 public fee_token;
  mapping(uint256 => IdoItem) private ido_list;
  mapping(uint256 => string) private base_info_list;
  mapping(uint256 => string) private ido_md5_list;
  mapping(string => uint256) public ido_md5_list2;
  mapping(string => bool) private ido_status_list;
  mapping(string => order_info_item) public order_md5_list;
  mapping(IERC20 => uint256[]) private token_order_id_list;
  mapping(uint256 => IERC20) private token_order_id_list2;
  mapping(address => uint256[]) private user_order_id_list;
  mapping(uint256 => address) private user_order_id_list2;
  mapping(address => mapping(IERC20 => uint256[])) private user_token_order_id_list;

  struct decimals_list_item {
    uint256 ido_token_decimals;
    uint256 usdt_token_decimals;
  }

  struct symbol_list_item {
    string ido_token_symbol;
    string usdt_token_symbol;
  }

  struct token_list_item {
    IERC20 ido_token;
    IERC20 usdt_token;
  }

  struct order_info_item {
    uint256 order_id;
    uint256 amount;
    uint256 price;
    uint256 time;
    address order_address;
    string order_md5;
    symbol_list_item symbol_list;
    token_list_item token_list;
    decimals_list_item decimals_list;
  }

  constructor() public {
    map = Map(0x021320e8AB2A49d070f50857599f7Ba0b1558671);
    (,,,,, fee_token,,,) = map.getFeeNum();
    addMiner(msg.sender);
  }

  event createIdoEvent(IERC20 _usdt_token, IERC20 _ido_token, address _fee_to, uint256 _price, string _order_md5, uint256 _order_id, uint256 _time, uint256 _amount, Map _map, IdoItem ido, address idopool, address creator);

  function createIdo(IERC20 usdt_token, IERC20 ido_token, address fee_to, uint256 price, string memory order_md5, uint256 ido_token_amount, uint256 time) public onlyMiner {
    require(ido_status_list[order_md5] == false, 'e0');
    require(ido_token_amount > 0, 'e1');
    require(ido_token.balanceOf(msg.sender) >= ido_token_amount, 'e2');
    (,,,,,,IERC20 usdt_token2,,) = map.getFeeNum();
    require(usdt_token2 == usdt_token, 'e3');
    IdoItem ido = new IdoItem(usdt_token, ido_token, fee_to, price, order_md5, ido_num, time, ido_token_amount, map);
    emit createIdoEvent(usdt_token, ido_token, fee_to, price, order_md5, ido_num, time, ido_token_amount, map, ido, address(this), _msgSender());
    ido_status_list[order_md5] = true;
    ido_list[ido_num] = ido;
    ido_md5_list[ido_num] = order_md5;
    ido_md5_list2[order_md5] = ido_num;
    ido_token.safeTransferFrom(msg.sender, address(ido), ido_token_amount);
    order_md5_list[order_md5] = order_info_item(ido_num, ido_token_amount, price, time, msg.sender, order_md5, symbol_list_item(ido_token.symbol(), usdt_token.symbol()), token_list_item(ido_token, usdt_token), decimals_list_item(ido_token.decimals(), usdt_token.decimals()));
    token_order_id_list[ido_token].push(ido_num);
    token_order_id_list2[ido_num] = ido_token;
    user_order_id_list[msg.sender].push(ido_num);
    user_order_id_list2[ido_num] = msg.sender;
    user_token_order_id_list[msg.sender][ido_token].push(ido_num);
    ido_num = ido_num.add(1);
  }

  function setBaseInfo(uint256 index, string memory _base_info) public onlyOwner {
    base_info_list[index] = _base_info;
  }

  function getIdoInfo(uint256 _index) public view returns (IdoItem ido, string memory order_md5, uint256 amount_all, uint256 amount_ok, uint256 amount, order_info_item memory order_info, bool can_ido, bool can_buyback, bool is_ended, string memory base_info, bool has_getTxAddress, address ido_token_router_address) {
    ido = ido_list[_index];
    order_md5 = ido_md5_list[_index];
    order_info = order_md5_list[order_md5];
    (can_ido, can_buyback, is_ended, amount_all,,,,) = ido.getBaseinfo();
    (,,,, amount_ok, amount, has_getTxAddress, ido_token_router_address) = ido.getBaseinfo();
    base_info = base_info_list[_index];
  }

  function getIdoInfoByOrderMd5(string memory _order_md5) public view returns (IdoItem ido, string memory order_md5, uint256 amount_all, uint256 amount_ok, uint256 amount, order_info_item memory order_info, bool can_ido, bool can_buyback, bool is_ended, string memory base_info, bool has_getTxAddress, address ido_token_router_address) {
    (ido, order_md5, amount_all, amount_ok,,,,,,,,) = getIdoInfo(ido_md5_list2[_order_md5]);
    (,,,, amount, order_info, can_ido, can_buyback, is_ended, base_info, has_getTxAddress, ido_token_router_address) = getIdoInfo(ido_md5_list2[_order_md5]);
  }

  function getIdoInfoByToken(IERC20 _token) public view returns (uint256[] memory id_list, uint256 id_list_num) {
    id_list = token_order_id_list[_token];
    id_list_num = id_list.length;
  }

  function getIdoInfoByNext(bool _is_ended) public view returns (string memory index_list, uint256 index_list_num) {
    for (uint256 i = 0; i < ido_num; i++) {
      IdoItem ido = ido_list[i];
      (,,bool is_ended,,,,,) = ido.getBaseinfo();
      if (is_ended == _is_ended) {
        index_list_num = index_list_num.add(1);
        index_list = (index_list.toSlice().concat("|".toSlice())).toSlice().concat(i.uint2str().toSlice());
      }
    }
  }

  function getIdoInfoByUser(address _user) public view returns (uint256[] memory id_list, uint256 id_list_num) {
    id_list = user_order_id_list[_user];
    id_list_num = id_list.length;
  }

  function getIdoInfoByUserByToken(address _user, IERC20 _token) public view returns (uint256[] memory id_list, uint256 id_list_num) {
    id_list = user_token_order_id_list[_user][_token];
    id_list_num = id_list.length;
  }

  function getidobuybackList(address _user) public view returns (string memory index_list, uint256 index_list_num) {
    for (uint256 i = 0; i < ido_num; i++) {
      IdoItem ido = ido_list[i];
      if (ido.getIdoBuyBackListNum(_user) > 0) {
        index_list_num = index_list_num.add(1);
        index_list = (index_list.toSlice().concat("|".toSlice())).toSlice().concat(i.uint2str().toSlice());
      }
    }
  }

  function getidobuybackListBytoken(address _user, IERC20 _token) public view returns (string memory index_list, uint256 index_list_num) {
    for (uint256 i = 0; i < ido_num; i++) {
      IdoItem ido = ido_list[i];
      if (ido.getIdoBuyBackListNum(_user) > 0 && token_order_id_list2[i] == _token) {
        index_list_num = index_list_num.add(1);
        index_list = (index_list.toSlice().concat("|".toSlice())).toSlice().concat(i.uint2str().toSlice());
      }
    }
  }

  function getidobuybackListByOrderMd5(address _user, string memory _order_md5) public view returns (uint256, bool) {
    uint256 index = ido_md5_list2[_order_md5];
    IdoItem ido = ido_list[index];
    if (ido.getIdoBuyBackListNum(_user) > 0) {
      return (index, true);
    }
    return (0, false);
  }

  function updateMap(address _address) public onlyOwner {
    (,,,,, fee_token,,,) = Map(_address).getFeeNum();
    for (uint256 i = 0; i < ido_num; i++) {
      IdoItem ido = ido_list[i];
      ido.setMap(_address);
    }
  }

  function changeOwner(IdoItem ido) public onlyOwner {
    ido.transferOwnership(_msgSender());
  }

  function set_ido(IdoItem ido, bool _can_ido, bool _can_buyback, bool _is_ended, bool _has_getTxAddress, address _ido_token_router_address) public onlyOwner {
    ido.enable_disable_ido(_can_ido, _can_buyback, _is_ended);
    ido.is_has_getTxAddress(_has_getTxAddress, _ido_token_router_address);
  }

}