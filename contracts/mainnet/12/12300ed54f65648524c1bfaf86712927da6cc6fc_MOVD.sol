/**
 *Submitted for verification at Etherscan.io on 2021-10-15
*/

// File: contracts/utils/SafeMath.sol


pragma solidity >=0.4.22 <0.9.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }

}

// File: contracts/token/IERC20.sol


pragma solidity >=0.4.22 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

}

// File: contracts/utils/Context.sol


pragma solidity >=0.4.22 <0.9.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: contracts/MOVD.sol


pragma solidity >=0.4.22 <0.9.0;





contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name_, string memory symbol_ ) {
        _decimals = 18;
        _symbol = symbol_;
        _name = name_;
        _totalSupply = 10 ** 9 * 1e18;

        // MOVE-TEAM
        _balances[address(0xdd20a5D3c5EE23F94Fd573ca5837B562a2D3C32D)] = 15 * 10 ** 7 * 1e18;
        emit Transfer(address(0), address(0xdd20a5D3c5EE23F94Fd573ca5837B562a2D3C32D), 15 * 10 ** 7 * 1e18 );

        // MOVE-TOKENSALES
        _balances[address(0x4aBB983dddFA282F97bF8289a978B3d658E5D5F8)] = 13 * 10 ** 7 * 1e18;
        emit Transfer(address(0), address(0x4aBB983dddFA282F97bF8289a978B3d658E5D5F8), 13 * 10 ** 7 * 1e18);

        // MOVE-PARTNERSHIPS
        _balances[address(0x9e70eD075A46e418E7963335Cf9Fde5Fc5C8eA58)] = 10 ** 8 * 1e18;
        emit Transfer(address(0), address(0x9e70eD075A46e418E7963335Cf9Fde5Fc5C8eA58), 10 ** 8 * 1e18);

        // MOVE-ECOSYSTEM
        _balances[address(0xF6C423BB72632f82027DB34615eC9c21de21b1C3)] = 12 * 10 ** 7 * 1e18;
        emit Transfer(address(0), address(0xF6C423BB72632f82027DB34615eC9c21de21b1C3), 12 * 10 ** 7 * 1e18);

        // MOVE-MINING
        _balances[address(0xa3F060Bc75881324F7f2919558797F61ea94AEDc)] = 5 * 10 ** 8 * 1e18;
        emit Transfer(address(0), address(0xa3F060Bc75881324F7f2919558797F61ea94AEDc), 5 * 10 ** 8 * 1e18);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    modifier onlyPayloadSize(uint size) {
      require(!(_msgData().length < size + 4));
      _;
    }

    function transfer(address recipient, uint256 amount) public virtual override onlyPayloadSize(2 * 32) returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override onlyPayloadSize(2 * 32) returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override onlyPayloadSize(3 * 32) returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual onlyPayloadSize(2 * 32) returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual onlyPayloadSize(2 * 32) returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

}

contract Ownable is Context {

  address public owner;
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() {
    owner = _msgSender();
  }

  modifier onlyOwner() {
    require(_msgSender() == owner);
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}


contract Pausable is Context, Ownable {
    event Paused(address account);
    event Unpaused(address account);
    bool private _paused = false;

    function paused() public view virtual returns (bool) {
      return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause() internal virtual onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


contract MOVD is Pausable, ERC20 {
  using SafeMath for uint256;

  constructor() 
  ERC20("MOVD Token", "MOVD"){}

  function transfer(address recipient, uint256 amount) public virtual override whenNotPaused onlyPayloadSize(2 * 32) returns (bool) {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public virtual override whenNotPaused onlyPayloadSize(3 * 32) returns (bool) {
    super.transferFrom(sender, recipient, amount);
    return true;
  }


  function pause() public {
    _pause();
  }

  function unpause() public {
    _unpause();
  }
}