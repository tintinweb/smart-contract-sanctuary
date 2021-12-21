/**
 *Submitted for verification at BscScan.com on 2021-12-21
*/

/**
 * Verificado por PACMEC.co fecha de lanzamiento 2022-01-01
 */
pragma solidity 0.5.16;

interface IPSC2 {
  function totalSupply() external view returns (uint256);
	
  function decimals() external view returns (uint256);
	
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

contract Context {
  constructor () internal { }
	
  function _msgSender() internal view returns (address payable) {
    return msg.sender;
  }
	
  function _msgData() internal view returns (bytes memory) {
    this;
    return msg.data;
  }
}

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: desbordamiento de la adición");
    return c;
  }
  
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: desbordamiento de resta");
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
    require(c / a == b, "SafeMath: desbordamiento de multiplicación");
    return c;
  }
  
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: división por cero");
  }
  
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;
    return c;
  }
  
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: módulo por cero");
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
    require(_owner == _msgSender(), "Ownable: la persona que llama no es el propietario");
    _;
  }
  
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }
  
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }
  
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: el nuevo propietario es la dirección cero");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract PSC2Token is Context, IPSC2, Ownable {
    string  public   version = "1.0.0";
    bool    public   mintActived;
    bool    public   buyActived;
    bool    public   sellActived;
    
    uint256 public   buyPrice  = 1548245;
    uint256 public   sellPrice = 1548745;
    
    using   SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private  _totalSupply;
    string  private  _symbol;
    string  private  _name;

    constructor(string memory name_, string memory symbol_, uint256 totalSupply_, uint256 developerReward_) public {
			mintActived = false;
			sellActived = true;
			buyActived = true;
			_name                    = name_;
			_symbol                  = symbol_;
			_totalSupply             = totalSupply_;
			_balances[address(this)] = _totalSupply;
			emit Transfer(address(0), address(this), _totalSupply);
			_transfer(address(this), msg.sender, developerReward_);
    }
    
    function getOwner() external view returns (address) {
			return owner();
    }
    
    function decimals() external view returns (uint256) {
			return 18;
    }
    
    function symbol() external view returns (string memory) {
			return _symbol;
    }
    
    function name() external view returns (string memory) {
			return _name;
    }
    
    function totalSupply() external view returns (uint256) {
			return _totalSupply;
    }
    
    function balanceOf(address account) external view returns (uint256) {
			return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) external returns (bool) {
			_transfer(_msgSender(), recipient, amount);
			return true;
    }
    
    function allowance(address owner, address spender) external view returns (uint256) {
			return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
			_approve(_msgSender(), spender, amount);
			return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
			_transfer(sender, recipient, amount);
			_approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "PSC2: el monto de la transferencia excede la asignación"));
			return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
			_approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
			return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
			_approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "PSC2: Disminución de la asignación por debajo de cero"));
			return true;
    }
    
    function mint(uint256 amount) public onlyOwner returns (bool) {
      _mint(_msgSender(), amount);
      return true;
    }

    function mintTo(address to, uint256 amount) public onlyOwner returns (bool) {
      _mint(to, amount);
      return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
			require(sender != address(0), "PSC2: transferencia desde la dirección cero");
			require(recipient != address(0), "PSC2: transferencia a la dirección cero");

			_balances[sender] = _balances[sender].sub(amount, "PSC2: el monto de la transferencia excede el saldo");
			_balances[recipient] = _balances[recipient].add(amount);
			emit Transfer(sender, recipient, amount);
    }
    
    function _mint(address account, uint256 amount) internal {
			require(mintActived);
			require(account != address(0), "PSC2: mint a la dirección cero");
			_totalSupply = _totalSupply.add(amount);
			_balances[account] = _balances[account].add(amount);
			emit Transfer(address(0), account, amount);
    }

    function burn(address from, uint256 amount) public onlyOwner returns (bool) {
			_burnFrom(from, amount);
			return true;
    }
    
    function _burn(address account, uint256 amount) internal {
			require(account != address(0), "PSC2: quemar desde la dirección cero");
			_balances[account] = _balances[account].sub(amount, "PSC2: la cantidad quemada excede el saldo");
			_totalSupply = _totalSupply.sub(amount);
			emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
			require(owner != address(0), "PSC2: aprobar desde la dirección cero");
			require(spender != address(0), "PSC2: aprobar a la dirección cero");

			_allowances[owner][spender] = amount;
			emit Approval(owner, spender, amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
			_burn(account, amount);
			_approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "PSC2: burn amount exceeds allowance"));
    }
    
    function donate() payable public returns (bool) {
			return true;
    }
    
    function buy() payable public returns (bool) {
			require(buyActived);
			uint256 amount = msg.value * buyPrice;
			if (this.balanceOf(address(this)) >= amount) _transfer(address(this), msg.sender, amount);
			else _mint(msg.sender, amount);
			return true;
    }

    function sell(uint256 amountSell) public returns (bool) {
			require(sellActived);
			address account = address(this);
			uint256 amount = amountSell / sellPrice;
			require(amount > 0);
			require(account.balance >= amount);
			_transfer(msg.sender, account, amountSell);
			msg.sender.transfer(amount);
			return true;
    }
    
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public onlyOwner returns (bool) {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
        return true;
    }
}