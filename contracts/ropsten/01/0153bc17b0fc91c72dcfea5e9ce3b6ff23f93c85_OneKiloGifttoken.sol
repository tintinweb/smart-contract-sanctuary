pragma solidity ^0.4.24;

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); 
    uint256 c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;
    return c;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

library Roles {
    
  struct Role {
    mapping (address => bool) bearer;
  }
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));
    role.bearer[account] = true;
  }
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));
    role.bearer[account] = false;
  }
  function has(Role storage role, address account) internal view returns (bool) {
    require(account != address(0));
    return role.bearer[account];
  }
}

contract Ownable {

  address private _owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }
  function owner() public view returns(address) {
    return _owner;
  }
  modifier onlyOwner() {
    require(isOwner());
    _;
  }
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract ERC223ReceivingContract {

    function tokenFallback(address _from, uint256 _value, bytes _data) public;
}

interface IERC20 {
    
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  //event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  //ERC223
  function transfer(address to, uint256 value, bytes data) external returns (bool success);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is IERC20, Ownable {
    
  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;
  mapping (address => bool) public frozenAccount;
  event frozenFunds(address account, bool freeze);
  uint256 private _totalSupply;
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }
  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }
  function transfer(address to, uint256 value, bytes data) external returns (bool) {
    require(transfer(to, value));

   uint codeLength;

   assembly {
    // Retrieve the size of the code on target address, this needs assembly.
    codeLength := extcodesize(to)
  }

  if (codeLength > 0) {
    ERC223ReceivingContract receiver = ERC223ReceivingContract(to);
    receiver.tokenFallback(msg.sender, value, data);
    }
  return true;
  }
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }
  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= _allowed[from][msg.sender]);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));
    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
   require(!frozenAccount[msg.sender]);
  }
  function _mint(address account, uint256 value) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }
  function _burn(address account, uint256 value) internal {
    require(account != 0);
    require(value <= _balances[account]);
    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
    _burn(account, value);
  }
}

contract PauserRole {
    
  using Roles for Roles.Role;
  event PauserAdded(address indexed account);
  event PauserRemoved(address indexed account);
  Roles.Role private pausers;
  constructor() internal {
    _addPauser(msg.sender);
  }
  modifier onlyPauser() {
    require(isPauser(msg.sender));
    _;
  }
  function isPauser(address account) public view returns (bool) {
    return pausers.has(account);
  }
  function addPauser(address account) public onlyPauser {
    _addPauser(account);
  }
  function renouncePauser() public {
    _removePauser(msg.sender);
  }
  function _addPauser(address account) internal {
    pausers.add(account);
    emit PauserAdded(account);
  }
  function _removePauser(address account) internal {
    pausers.remove(account);
    emit PauserRemoved(account);
  }
}

contract Pausable is PauserRole {
    
  event Paused(address account);
  event Unpaused(address account);
  bool private _paused;
  constructor() internal {
    _paused = false;
  }
  function paused() public view returns(bool) {
    return _paused;
  }
  modifier whenNotPaused() {
    require(!_paused);
    _;
  }
  modifier whenPaused() {
    require(_paused);
    _;
  }
  function pause() public onlyPauser whenNotPaused {
    _paused = true;
    emit Paused(msg.sender);
  }
  function unpause() public onlyPauser whenPaused {
    _paused = false;
    emit Unpaused(msg.sender);
  }
}

contract MinterRole {
    
  using Roles for Roles.Role;
  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);
  Roles.Role private minters;
  constructor() internal {
    _addMinter(msg.sender);
  }
  modifier onlyMinter() {
    require(isMinter(msg.sender));
    _;
  }
  function isMinter(address account) public view returns (bool) {
    return minters.has(account);
  }
  function addMinter(address account) public onlyMinter {
    _addMinter(account);
  }
  function renounceMinter() public {
    _removeMinter(msg.sender);
  }
  function _addMinter(address account) internal {
    minters.add(account);
    emit MinterAdded(account);
  }
  function _removeMinter(address account) internal {
    minters.remove(account);
    emit MinterRemoved(account);
  }
}

contract ERC20Mintable is ERC20, MinterRole {

  uint256 private _maxSupply = 1000000000000000000000000001;
  uint256 private _totalSupply;
  function maxSupply() public view returns (uint256) {
    return _maxSupply;
  }
  function mint(address to, uint256 value) public onlyMinter returns (bool) {
    require(_maxSupply > totalSupply().add(value));
    _mint(to, value);
    return true;        
  }
}

contract ERC20Burnable is ERC20 {

  function burn(uint256 value) public {
    _burn(msg.sender, value);
  }
  function burnFrom(address from, uint256 value) public {
    _burnFrom(from, value);
  }
}

contract ERC20Pausable is ERC20, Pausable {

  function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
    return super.transfer(to, value);
  }
  function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
    return super.transferFrom(from, to, value);
  }
  function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
    return super.approve(spender, value);
  }
  function increaseAllowance(address spender, uint addedValue) public whenNotPaused returns (bool success) {
    return super.increaseAllowance(spender, addedValue);
  }
  function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseAllowance(spender, subtractedValue);
  }
}

library SafeERC20 {

  using SafeMath for uint256;
  function safeTransfer(IERC20 token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }
  function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
    require(token.transferFrom(from, to, value));
  }
  function safeApprove(IERC20 token, address spender, uint256 value) internal {
    require((value == 0) || (token.allowance(msg.sender, spender) == 0));
    require(token.approve(spender, value));
  }
  function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    require(token.approve(spender, newAllowance));
  }
  function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
    uint256 newAllowance = token.allowance(address(this), spender).sub(value);
    require(token.approve(spender, newAllowance));
  }
}

contract ERC20Frozen is ERC20 {
    
  function freezeAccount (address target, bool freeze) onlyOwner public {
    frozenAccount[target]=freeze;
    emit frozenFunds(target, freeze);
  }
}

contract OneKiloGifttoken is ERC20Mintable, ERC20Burnable, ERC20Pausable, ERC20Frozen {

  string public constant name = "OneKiloGifttoken";
  string public constant symbol = "1KG";
  uint8 public constant decimals = 18;
  uint256 public constant INITIAL_SUPPLY = 10000000 * (10 ** uint256(decimals));
  
  constructor() public {
    _mint(msg.sender, INITIAL_SUPPLY);
    
  }
}

/*
상품권 표준약관
제1조 (목적)
이 약관은 주식회사 칼랩 (이하 ‘발행자’라 함)이 발행한 상품권을 구매자 또는 구매자로부터 이전 받은 자(이하 ‘고객’ 이라 함)가 
사용함에 있어 고객과 발행자 또는 발행자와 가맹계약을 맺은 자 (이하, ‘가맹점’이라 함) 등 발행자가 지정한 
자(이하, ‘발행자 등’이라 함) 간에 준수할 사항을 규정한다. 
제2조 (상품권의 정의 등)
비정액(수시로 충전할 수 있는 형태를 뜻함. 이하 ‘충전형’이라 함) 또는 정액형 선불전자지급수단으로서 유효기간 내에 잔액 범위 
내에서 사용횟수에 제한없이 자유롭게 상품 등을 제공 받을 수 있는 상품권으로 정의한다.
제3조 (발행 등)
1 .발행자는 상품권의 발행 시 소요되는 제반비용 등을 부담한다.
2. 발행자 : 주식회사 칼랩
3. 구매수량 및 구매가격 : 정액형 전자 유형 상품권 단위당 1,000원
제4조 (상품권의 사용)
1 .고객이 유효기간 내에 상품권의 금액 또는 수량의 범위 내에서 물품 등의 제공을 요구하는 경우 발행자 등은 즉시 해당 물품을 
제공한다. 
2 .고객은 발행자 등에서 판매하는 물품 등에 대하여 가격할인기간을 포함하여 언제든지 상품권을 사용할 수 있다. 
3 .발행자가 발행한 상품권의 경우, 잔액 범위 내에서 사용 횟수에 제한 없이 사용가능하며 사용시 사용금액만큼 차감된다. 
제5조 (환불)
1.고객은 상품권의 구매일로부터 7일 이내에 구매액 전부를 환불 받을 수 있다. 
제6조 (소멸시효)
상품권 소멸시효는 없다.
제7조 (지급보증 등)
상품권 발행자는 상품권의 지급보증 또는 피해보상보험계약(이하 “지급보증 등”이라 함)을 한다. 
제8조 (발행자의 책임)
1. 상품권의 이용과 관련된 고객의 권리에 대한 최종적 책임은 발행자가 진다. 
2 데이터의 위조 또는 변조 등으로 고객에게 피해가 발생한 경우, 발행자는 고객의 피해에 대해서 손해를 배상한다. 
다만, 발행자가 사용자의 관리소홀 등의 책임을 입증하거나 천재지변 등 불가항력적인 사유로 인한 것임을 입증한 경우에는 
그러하지 아니하다. 
제9조 (분쟁해결)
이 약관과 관련하여 발행자 등과 고객 사이에 발생한 분쟁에 관한 소송은 서울중앙지방법원에 제기한다. 
제10조 (기타)
이 약관에 명시되지 않은 사항 또는 약관 해석상 다툼이 있는 경우에는 고객과 발행자 등의 합의 의하여 결정한다. 
다만, 합의가 이루어지지 않은 경우에는「약관의 규제에 관한 법률」등 관계법령 및 거래관행에 따른다. 

*/