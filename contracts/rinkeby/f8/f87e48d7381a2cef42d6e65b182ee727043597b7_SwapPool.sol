/**
 *Submitted for verification at Etherscan.io on 2021-05-30
*/

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function decimals() external view returns (uint256);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

library SafeERC20 {
  using SafeMath for uint256;
  using Address for address;

  function safeTransfer(IERC20 token, address to, uint256 value) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
    _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }


  function safeApprove(IERC20 token, address spender, uint256 value) internal {
    require((value == 0) || (token.allowance(address(this), spender) == 0),
      "SafeERC20: approve from non-zero to non-zero allowance"
    );
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
    uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
    _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
  }

  function _callOptionalReturn(IERC20 token, bytes memory data) private {
    bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
    if (returndata.length > 0) {
      require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }
  }
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

interface Price_API {
  function getFeeNum() external view returns (uint256 price, IERC20 fee_token);
}


contract SwapPool is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;
  address public dev_addr; //开发账户
  address public fee_to; //交易费托管账户
  uint256 public fee_rate; //交易费率千分之1为1个单位
  uint256 public order_list_num;
  //  IERC20 public fee_token;
  //  IMdexPair public fee_pair;
  Price_API public price_api;

  struct decimals_list {
    uint256 decimals0;
    uint256 decimals1;
  }

  struct symbol_list {
    string symbol0;
    string symbol1;
  }


  struct amount_list {
    uint256 amount_all;  // 挂单总数量
    uint256 amount_ok; // 已成交
  }


  struct order_info {
    uint256 order_id; // 订单编号
    string order_md5; // 订单md5
    IERC20 token0;  // 挂单代币
    IERC20 token1; // 兑换代币
    uint256 amount;  // 挂单数量
    //     uint256 amount_all;  // 挂单总数量
    // 	uint256 amount_ok; // 已成交
    amount_list amount_list2;
    uint256 price;  // 挂单价格,需要除以1e18
    address order_address; // 挂单账号
    bool status; // 是否交易中
    //string name0; // token0的代币名称
    // string name1; // token1的代币名称
    string symbol0; // token0的代币符号
    string symbol1; // token1的代币符号
    uint256 time; // 挂单时间
    // uint256 decimals0;
    // uint256 decimals1;
    decimals_list decimals_list2;
  }

  struct swap_info {
    IERC20 token0;  // 挂单代币
    IERC20 token1; // 兑换代币
    string order_md5; // 订单编号
    address swap_address; // 挂单账号
    uint256 token0_amount;  // token0成交数量
    uint256 token1_amount;  // token1成交数量
    uint256 price; // 成交价格
    uint256 blockNumber; //成交区块时间戳
    uint256 time; // 成交时间
    decimals_list decimals_list2;
    symbol_list symbol_list2;
  }

  struct deposit_info {
    uint256 amount;
    uint256 time;
  }

  struct withdraw_info {
    uint256 amount;
    uint256 time;
  }

  constructor(address _fee_to, Price_API _price_api, uint256 _fee_rate, address usdt_token
  ) public {
    add_watcher(msg.sender);
    dev_addr = msg.sender;
    fee_to = _fee_to;
    price_api = _price_api;
    fee_rate = _fee_rate;
    addWhiteListForToken1(usdt_token);
  }

  mapping(string => order_info) public order_info_list; // 以order_md5为键存贮挂单信息
  mapping(uint256 => string) public order_list;  // 储存order_md5的数组
  mapping(string => bool) public order_list2;   // 储存挂单是否已存在
  mapping(address => string[]) public order_list_for_user; // 每个用户所有的挂单
  mapping(address => uint256) public order_list_len_for_user; // 每个用户所有的挂单总数
  mapping(string => swap_info[]) public swap_list;
  mapping(address => swap_info[]) public swap_list_for_user; // 每个用户所有的买单
  mapping(address => bool) public watcher_list;
  mapping(string => mapping(address => bool)) public whitelist_all;
  mapping(string => mapping(address => bool)) public blacklist_all;
  mapping(string => address[]) public white_blacklist_all;
  mapping(string => deposit_info[]) public deposit_info_list;
  mapping(string => withdraw_info[]) public withdraw_info_list;
  mapping(address => bool) public blacklist_token0; // 交易对token0黑名单
  mapping(address => bool) public blacklist_token1; // 交易对token1黑名单
  mapping(address => bool) public token0_list_status; // token0是否已存在
  mapping(uint256 => address) public token0_list; // token列表
  uint256 public token0_list_length; // 已添加token总数
  mapping(address => string[]) public token0_md5_list; // token列表

  mapping(address => bool) public whitelist_token1; // 交易对token1白名单


  function setDev(address _dev_addr) public onlyOwner {
    dev_addr = _dev_addr;
  }

  //  function setFeeToken(IERC20 _address) public onlyOwner {
  //    fee_token = _address;
  //  }


  //  function setFeePair(IMdexPair _address) public onlyOwner {
  //    fee_pair = _address;
  //  }

  function setPriceAPI(Price_API _price_api) public onlyOwner {
    price_api = _price_api;
  }

  function add_watcher(address _user) public onlyOwner() {
    watcher_list[_user] = true;
  }

  function setFeeTo(address _fee_to) public onlyOwner() {
    fee_to = _fee_to;
  }

  function setFeeRate(uint256 _fee_rate) public onlyOwner() {
    fee_rate = _fee_rate;
  }

  event AddOrder(string order_md5, uint256 order_list_num);
  event Deposit(address user, string order_md5, uint256 amount, address token_name);
  event Withdraw(address user, string order_md5, uint256 amount, address token_name);
  event addBlackListForToken0Event(address token0_address, string event_name);
  event addBlackListForToken1Event(address token1_address, string event_name);
  event RemoveBlackListForToken0Event(address token0_address, string event_name);
  event RemoveBlackListForToken1Event(address token1_address, string event_name);
  event addWhiteListForToken1Event(address token1_address, string event_name);
  event removeWhiteListForToken1Event(address token1_address, string event_name);


  function addBlackListForToken0(address _address) public onlyOwner {
    blacklist_token0[_address] = true;
    emit addBlackListForToken0Event(_address, 'addBlackListForToken0Event');
  }

  function addBlackListForToken1(address _address) public onlyOwner {
    blacklist_token1[_address] = true;
    emit addBlackListForToken1Event(_address, 'addBlackListForToken1Event');
  }

  function RemoveBlackListForToken0(address _address) public onlyOwner {
    blacklist_token0[_address] = false;
    emit RemoveBlackListForToken0Event(_address, 'RemoveBlackListForToken0Event');
  }

  function RemoveBlackListForToken1(address _address) public onlyOwner {
    blacklist_token1[_address] = false;
    emit RemoveBlackListForToken1Event(_address, 'RemoveBlackListForToken1Event');
  }

  function addWhiteListForToken1(address _address) public onlyOwner {
    whitelist_token1[_address] = true;
    emit addWhiteListForToken1Event(_address, 'addWhiteListForToken1Event');
  }

  function removeWhiteListForToken1(address _address) public onlyOwner {
    whitelist_token1[_address] = false;
    emit removeWhiteListForToken1Event(_address, 'removeWhiteListForToken1Event');
  }

  function add_order2(string memory _order_md5, IERC20 _token0, IERC20 _token1, uint256 _price, uint256 _time, uint256 _amount) public {
    require(blacklist_token0[address(_token0)] == false, "已被列入黑名单");
    require(blacklist_token1[address(_token1)] == false, "已被列入黑名单");
    require(whitelist_token1[address(_token1)] == true, "币种不在白名单之内");
    //address[] memory emptyAddressList;
    //address[] memory emptyAddressList2 = new address[](0);
    //string memory name0 = _token0.name();
    //string memory name1 = _token1.name();
    require(_amount > 0, "金额必须大于大于0");
    require(_token0.balanceOf(msg.sender) >= _amount, "用户账号余额不足以支付");
    require(order_list2[_order_md5] == false, "挂单已存在");
    IERC20(_token0).safeTransferFrom(msg.sender, address(this), _amount);
    string memory symbol0 = _token0.symbol();
    string memory symbol1 = _token1.symbol();
    uint256 decimals0 = _token0.decimals();
    uint256 decimals1 = _token1.decimals();
    order_list[order_list_num] = _order_md5;
    order_list2[_order_md5] = true;
    order_info_list[_order_md5] = order_info(order_list_num, _order_md5, _token0, _token1, _amount, amount_list(_amount, 0), _price, msg.sender, true, symbol0, symbol1, _time, decimals_list(decimals0, decimals1));
    emit AddOrder(_order_md5, order_list_num);
    order_list_for_user[msg.sender].push(_order_md5);
    emit Deposit(msg.sender, _order_md5, _amount, address(_token0));
    order_list_len_for_user[msg.sender] = order_list_len_for_user[msg.sender].add(1);
    deposit_info_list[_order_md5].push(deposit_info(_amount, _time));
    if (token0_list_status[address(_token0)] == false)
    {
      token0_list_status[address(_token0)] = true;
      token0_list[token0_list_length] = address(_token0);
      token0_list_length = token0_list_length.add(1);
    }
    token0_md5_list[address(_token0)].push(_order_md5);
    order_list_num = order_list_num.add(1);
  }


  function GetOrderListForToken(address _token0) public view returns (string[] memory token0_md5_array, uint256 num) {
    num = token0_md5_list[_token0].length;
    token0_md5_array = new string[](num);
    for (uint256 i = 0; i < num; i++)
    {
      token0_md5_array[i] = token0_md5_list[_token0][i];
    }
  }


  struct token_info {
    address token_address;
    string name;
    string symbol;
    uint256 decimals;
    uint256 balance;
  }

  function getTokenInfo(IERC20 _token, address _user) public view returns (token_info memory token_info2) {
    token_info2.token_address = address(_token);
    token_info2.name = IERC20(_token).name();
    token_info2.symbol = IERC20(_token).symbol();
    token_info2.decimals = IERC20(_token).decimals();
    token_info2.balance = IERC20(_token).balanceOf(_user);
  }

  function getTokenInfo2(address _token) public pure returns (token_info memory token_info3) {
    token_info3.token_address = _token;
    token_info3.name = 'Unknown';
    token_info3.symbol = 'Unknown';
    token_info3.decimals = 0;
    token_info3.balance = 0;
  }

  function setWhiteList(string memory _order_md5, address[] memory _white_list) public {
    require(order_info_list[_order_md5].order_address == msg.sender, "Only");
    for (uint256 i = 0; i < _white_list.length; i++)
    {
      whitelist_all[_order_md5][_white_list[i]] = true;
      white_blacklist_all[_order_md5].push(_white_list[i]);
    }
  }

  function setBlackList(string memory _order_md5, address[] memory _blacklist) public {
    require(order_info_list[_order_md5].order_address == msg.sender, "Only");
    for (uint256 i = 0; i < _blacklist.length; i++)
    {
      blacklist_all[_order_md5][_blacklist[i]] = true;
      white_blacklist_all[_order_md5].push(_blacklist[i]);
    }
  }

  function deposit(string memory _order_md5, uint256 _amount, uint256 _time) public {
    require(order_info_list[_order_md5].order_address == msg.sender, "必须是挂单者才能存入资金");
    require(_amount > 0, "金额必须大于大于0");
    require(order_info_list[_order_md5].token0.balanceOf(msg.sender) >= _amount, "用户账号余额不足以支付");
    order_info_list[_order_md5].token0.safeTransferFrom(msg.sender, address(this), _amount);
    order_info_list[_order_md5].amount = order_info_list[_order_md5].amount.add(_amount);
    //剩余挂单量
    order_info_list[_order_md5].amount_list2.amount_all = order_info_list[_order_md5].amount_list2.amount_all.add(_amount);
    //总挂单量
    emit Deposit(msg.sender, _order_md5, _amount, address(order_info_list[_order_md5].token0));
    deposit_info_list[_order_md5].push(deposit_info(_amount, _time));
  }


  function withdraw(string memory _order_md5, uint256 _amount, uint256 _time) public {
    require(order_info_list[_order_md5].order_address == msg.sender, "必须是挂单者才能提取资金");
    require(_amount > 0, "金额必须大于大于0");
    require(order_info_list[_order_md5].amount >= _amount, "提取金额不能超过可提取金额");
    order_info_list[_order_md5].token0.safeTransfer(msg.sender, _amount);
    order_info_list[_order_md5].amount = order_info_list[_order_md5].amount.sub(_amount);
    //剩余挂单量
    order_info_list[_order_md5].amount_list2.amount_all = order_info_list[_order_md5].amount_list2.amount_all.sub(_amount);
    withdraw_info_list[_order_md5].push(withdraw_info(_amount, _time));
    emit Withdraw(msg.sender, _order_md5, _amount, address(order_info_list[_order_md5].token0));
    //总挂单量
  }

  function exit(string memory _order_md5) public {
    require(order_info_list[_order_md5].order_address == msg.sender, "必须是挂单者才能提取所有资金");
    require(order_info_list[_order_md5].amount > 0, "提取金额不能超过可提取金额");
    order_info_list[_order_md5].token0.safeTransfer(msg.sender, order_info_list[_order_md5].amount);
    order_info_list[_order_md5].amount = 0;
  }

  event SwapInfo(bool is_blacklist, uint256 price, uint256 balanceOftoken1, uint256 amount, uint256 buy_num, uint256 buy_num_fee_to, uint256 buy_num_to_user);


  //  function getFeeNum() public view returns (uint256 price) {
  //    address token0_new = IMdexPair(fee_pair).token0();
  //    address token1_new = IMdexPair(fee_pair).token1();
  //    (uint256 _reserve0,uint256  _reserve1,) = IMdexPair(fee_pair).getReserves();
  //    uint256 decimals0 = IERC20(token0_new).decimals();
  //    uint256 decimals1 = IERC20(token1_new).decimals();
  //    uint256 price1 = _reserve0.mul(10 ** 18).mul(10 ** decimals1).div(_reserve1).div(10 ** decimals0);
  //    uint256 price2 = _reserve1.mul(10 ** 18).mul(10 ** decimals0).div(_reserve0).div(10 ** decimals1);
  //    if (token0_new == address(fee_token))
  //      price = price1;
  //    else
  //      price = price2;
  //  }


  function getFeeNum() public view returns (uint256 price, IERC20 fee_token) {
    (price, fee_token) = Price_API(price_api).getFeeNum();
  }

  function swapWithFeeToken(string memory _order_md5, uint256 _amount, uint256 _time) public {
    require(_amount > 0, "成交额不能为0");
    require(blacklist_all[_order_md5][msg.sender] == false, "兑换者不能在黑名单里面");
    require(order_info_list[_order_md5].price > 0, "挂单价格不能小于0");
    require(order_info_list[_order_md5].token1.balanceOf(msg.sender) >= _amount, "兑换者余额不足");
    uint256 decimals0 = order_info_list[_order_md5].decimals_list2.decimals0;
    uint256 decimals1 = order_info_list[_order_md5].decimals_list2.decimals1;
    uint256 swap_price = order_info_list[_order_md5].price;
    uint256 buy_num = _amount.mul(10 ** decimals0).mul(10 ** 18).div(swap_price).div(10 ** decimals1);
    {
      //防止堆栈错误
      (uint256 price,IERC20 fee_token) = Price_API(price_api).getFeeNum();
      uint256 fee_amount = _amount.mul(fee_rate).div(1e3);
      uint256 fee_token_decimals = IERC20(fee_token).decimals();
      uint256 fee_amount2 = fee_amount.mul(price).mul(10 ** fee_token_decimals).div(10 ** decimals1).div(10 ** 18);
      require(IERC20(fee_token).balanceOf(msg.sender) >= fee_amount2, "兑换者手续费不足");
      IERC20(fee_token).safeTransferFrom(msg.sender, fee_to, fee_amount2);
    }

    order_info_list[_order_md5].token0.safeTransfer(msg.sender, buy_num);
    order_info_list[_order_md5].token1.safeTransferFrom(msg.sender, order_info_list[_order_md5].order_address, _amount);
    order_info_list[_order_md5].amount = order_info_list[_order_md5].amount.sub(buy_num);
    order_info_list[_order_md5].amount_list2.amount_ok = order_info_list[_order_md5].amount_list2.amount_ok.add(buy_num);
    {
      //防止堆栈错误
      IERC20 token0 = order_info_list[_order_md5].token0;
      IERC20 token1 = order_info_list[_order_md5].token1;
      string memory symbol0 = order_info_list[_order_md5].symbol0;
      string memory symbol1 = order_info_list[_order_md5].symbol1;
      swap_info  memory swap_info_item = swap_info(token0, token1, _order_md5, msg.sender, buy_num, _amount, swap_price, block.number, _time, decimals_list(decimals0, decimals1), symbol_list(symbol0, symbol1));
      swap_list[_order_md5].push(swap_info_item);
      swap_list_for_user[msg.sender].push(swap_info_item);
    }
  }

  //  function swap(string memory _order_md5, uint256 _amount, uint256 _time) public {
  //    require(_amount > 0, "成交额不能为0");
  //    require(blacklist_all[_order_md5][msg.sender] == false, "兑换者不能在黑名单里面");
  //    require(order_info_list[_order_md5].price > 0, "挂单价格不能小于0");
  //    require(order_info_list[_order_md5].token1.balanceOf(msg.sender) > _amount, "兑换者余额不足");
  //    uint256 to_d2 = order_info_list[_order_md5].decimals_list2.decimals0;
  //    uint256 spend_d2 = order_info_list[_order_md5].decimals_list2.decimals1;
  //    uint256 buy_num = _amount.mul(10 ** to_d2).mul(10 ** 18).div(order_info_list[_order_md5].price).div(10 ** spend_d2);
  //    //结算代币价格和手续费
  //
  //
  //    uint256 buy_num_fee_to = buy_num.mul(fee_rate).div(1e3);
  //    uint256 buy_num_to_user = buy_num.sub(buy_num_fee_to);
  //    emit SwapInfo(blacklist_all[_order_md5][msg.sender], order_info_list[_order_md5].price, order_info_list[_order_md5].token1.balanceOf(msg.sender), _amount, buy_num, buy_num_fee_to, buy_num_to_user);
  //    require(order_info_list[_order_md5].amount >= buy_num, '库存不足');
  //    order_info_list[_order_md5].token0.safeTransfer(msg.sender, buy_num_to_user);
  //    if (buy_num_fee_to > 0)
  //    {
  //      order_info_list[_order_md5].token0.safeTransfer(fee_to, buy_num_fee_to);
  //    }
  //    uint256 to_num_fee_to = _amount.mul(fee_rate).div(1e3);
  //    uint256 to_num = _amount.sub(to_num_fee_to);
  //    order_info_list[_order_md5].token1.safeTransferFrom(msg.sender, order_info_list[_order_md5].order_address, to_num);
  //    if (to_num_fee_to > 0)
  //    {
  //      order_info_list[_order_md5].token1.safeTransferFrom(msg.sender, fee_to, to_num_fee_to);
  //    }
  //    order_info_list[_order_md5].amount = order_info_list[_order_md5].amount.sub(buy_num);
  //    // 剩余挂单量
  //    order_info_list[_order_md5].amount_list2.amount_ok = order_info_list[_order_md5].amount_list2.amount_ok.add(buy_num);
  //    swap_info  memory swap_info_item = swap_info(order_info_list[_order_md5].token0, order_info_list[_order_md5].token1, _order_md5, msg.sender, buy_num, _amount, order_info_list[_order_md5].price, block.number, _time, decimals_list(order_info_list[_order_md5].decimals_list2.decimals0, order_info_list[_order_md5].decimals_list2.decimals1), symbol_list(order_info_list[_order_md5].symbol0, order_info_list[_order_md5].symbol1));
  //    // 已成交量
  //    swap_list[_order_md5].push(swap_info_item);
  //    swap_list_for_user[msg.sender].push(swap_info_item);
  //  }


  //获取一个具体的交易
  function getSwapinfo(string memory _order_md5) public view returns (swap_info[] memory swap_info_list) {
    swap_info_list = swap_list[_order_md5];
  }


  //获取一个用户所有挂单
  function getOrderListForUser(address _user) public view returns (string[] memory order_info_list_for_user, uint256 order_info_list_num) {
    order_info_list_for_user = order_list_for_user[_user];
    order_info_list_num = order_info_list_for_user.length;
  }

  //获取一个所有交易
  function getSwapListForUser(address _user) public view returns (swap_info[] memory swap_info_list_for_user, uint256 swap_list_num) {
    swap_info_list_for_user = swap_list_for_user[_user];
    swap_list_num = swap_info_list_for_user.length;
  }

  function getDepositAndWithdraw(string memory _order_md5) public view returns (deposit_info[] memory deposit_info_list_for_user, uint256 deposit_info_num, withdraw_info[] memory withdraw_info_list_for_user, uint256 withdraw_info_num)
  {
    deposit_info_list_for_user = deposit_info_list[_order_md5];
    deposit_info_num = deposit_info_list_for_user.length;
    withdraw_info_list_for_user = withdraw_info_list[_order_md5];
    withdraw_info_num = withdraw_info_list_for_user.length;
  }


  function getOrderMd5List(uint256[] memory order_id_list) public view returns (string[] memory) {
    //动态数组需要预先定义为固定长度数组
    string[] memory return_order_md5_list = new string[](order_id_list.length);
    for (uint256 i = 0; i < order_id_list.length; i++)
    {
      return_order_md5_list[i] = order_list[order_id_list[i]];
    }
    return return_order_md5_list;
  }

}