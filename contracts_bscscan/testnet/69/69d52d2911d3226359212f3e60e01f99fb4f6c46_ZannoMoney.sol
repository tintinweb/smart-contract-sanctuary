/**
 *Submitted for verification at BscScan.com on 2021-12-25
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IERC20 {
// Shows the totalt amount of coins in cirkulation
function totalSupply() external view returns (uint256);

// Shows how many coins is owned by "account"
function balanceOf(address account) external view returns (uint256);

// Moves an amount of coins from one address to another
function transfer(address recipient, uint256 amount) external returns (bool);

// Shows how many coins an account can spend on behalf of the owner.
function allowance(address owner, address spender) external view returns (uint256);

// Gives an account the allowance to spend coins
function approve(address spender, uint256 amount) external returns (bool);

// Moves an amount of coins from one address to another using "allowance"
function transferFrom(
    address sender,
    address recipient,
    uint256 amount
) external returns (bool);

// Emits the transfer of coins from one address to another
event Transfer(address indexed from, address indexed to, uint256 value);

// Emits the allowance of a "spender" for the "owner"
event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
   function _msgSender() internal view virtual returns (address) {
     return msg.sender;
}
   function _msgData() internal view virtual returns (bytes calldata) {
      return msg.data;
    }
}

interface IERC20Metadata is IERC20 {

// Shows the name of your coin
function name() external view returns (string memory);

// Shows the symbol of your coin
function symbol() external view returns (string memory);

// Shows the decimals of your coin
function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    
// Setting the name and symbol for the coin
constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
    
// Shows the name of your coin.
function name() public view virtual override returns (string memory) {
        return _name;
    }
    
// Shows the symbol of your coin
function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
    
// Shows the number of decimals for your coin
function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    
// Total supply
function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }
    
// Balance of the "account"
function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    
// Show transfers between accounts
function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
// Show allowances
function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    
// Approve allowances
function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
// Updating the allowance.
function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }
    
// Approve and update allowance
function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    
// Decrease and update allowance
function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }
    
// Moves coins from sender to recipient
function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }
    
// Mint an amount of coins to "account"
function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }
    
// Destroys an amount of coins
function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }
    
// Set allowance
function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
// Hook that is called before any transfer of coins.
function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    
// Hook that is called after any transfer of coins.
function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

contract ZannoMoney is ERC20 {
    constructor() ERC20("ZannoMoney", "ZMO") {
        _mint(msg.sender, 100000 * 10 ** decimals());
    }
}