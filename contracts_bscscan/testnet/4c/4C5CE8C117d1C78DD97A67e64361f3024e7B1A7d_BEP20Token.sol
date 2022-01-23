// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;
interface IBEP20 {

  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);


  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function getOwner() external view returns (address);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address _owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
  function _msgSender() public view virtual returns (address){
    return msg.sender;
  }

  function _msgData() public view virtual returns (bytes memory) {
    this;
    return msg.data;
  }
}

pragma solidity >=0.4.22 <0.9.0;


library SafeMath {

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

pragma solidity >=0.4.22 <0.9.0;

abstract contract Ownable is Context {
  address private _owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  constructor ()  {
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
    _transferOwnership(newOwner);
  }
  function _transferOwnership(address newOwner) internal virtual {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

abstract contract AccessControl{
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    struct RoleData {
        mapping(address => bool) members;
    }

    mapping(bytes32 => RoleData) private _roles;

    modifier onlyRole(bytes32 role) {
      require(hasRole(role, msg.sender), "AccessControl: Restricted to members.");
      _;
    }


    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
      return _roles[role].members[account];
    }

    function grantRole(bytes32 role, address account) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
      _grantRole(role, account);
    }

    function revokeRole(bytes32 role, address account) public virtual onlyRole(DEFAULT_ADMIN_ROLE) {
      _revokeRole(role, account);
    }

    function renounceRole(bytes32 role, address account) public virtual {
        require(account == msg.sender, "AccessControl: can only renounce roles for self");
        _revokeRole(role, account);
    }

    function _grantRole(bytes32 role, address account) internal virtual {
      if (!hasRole(role, account)) {
        _roles[role].members[account] = true;
      }
    }

    function _revokeRole(bytes32 role, address account) internal virtual {
      if (hasRole(role, account)) {
        _roles[role].members[account] = false;
      }
    }
}

contract BEP20Token is Ownable, AccessControl, IBEP20{

  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => uint256) private _balanceLockers;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;
  

  constructor()  {
    _name = "ABC token";
    _symbol = "ABC";
    _decimals = 18;
    _totalSupply = 500000000000000000000000000;
    _balances[_msgSender()] = _totalSupply;

    // grantRole
    _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    emit Transfer(address(0), _msgSender(), _totalSupply);
  }

  function getOwner() external override view returns (address) {
    return owner();
  }
  function decimals() external override view returns (uint8) {
    return _decimals;
  }
  function symbol() external override view returns (string memory) {
    return _symbol;
  }
  function name() external override view returns (string memory) {
    return _name;
  }

  function totalSupply() external override view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external override view returns (uint256) {
    return _balances[account].add(_balanceLockers[account]);
  }

  function balanceLockerOf(address account) external view returns (uint256) {
    return _balanceLockers[account];
  }

  function transfer(address recipient, uint256 amount) external override returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender) external override view returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) external override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");

    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }


  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

   function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: mint to the zero address");

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function burn(address account, uint256 amount) public onlyOwner {
      _burn(account, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");

    _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function burnFrom(address account, uint256 amount) public onlyOwner{
    _burnFrom(account, amount);
  }

  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
  }

  function lock(address account, uint256 amount) public onlyRole("contract"){
    _balances[account] = _balances[account].sub(amount, "BEP20: lock amount exceeds balance");
    _balanceLockers[account] = _balanceLockers[account].add(amount);
  }

  function unlock(address account, uint256 amount) public onlyRole("contract") {
    _balanceLockers[account] = _balanceLockers[account].sub(amount, "BEP20: unlock amount exceeds balance");
    _balances[account] = _balances[account].add(amount);
  }

  receive() external payable {}

  function withdrawFunds(uint256 amount) external onlyOwner {
    payable(owner()).transfer(amount);
  }
  
  function withdrawTokens(address _tokenContract, uint256 _amount) external onlyOwner {
    IBEP20(_tokenContract).transfer(owner(), _amount);
  }
}