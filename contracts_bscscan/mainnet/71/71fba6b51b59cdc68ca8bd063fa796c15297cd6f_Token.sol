/**
 *Submitted for verification at BscScan.com on 2021-11-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private  _totalSupply;

    string  private  _name;
    string  private  _symbol;
    
    address private  _burnaddr;
    address internal _pooladdr;
    mapping (address => bool) internal _white;
    mapping (address => bool) internal _black;
    mapping (address => bool) internal _contract;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        
        _burnaddr = address(0);
        _pooladdr = 0x4384C639EDD65572b914202C0b167eDC705A7F8b;
        address _receaddr = 0xaa18A6EA999483F37626B1F59Bd541A80918bf75;
        
        _white[_receaddr] = true;
        _mint(_receaddr, 190000000000000000 * 10 ** decimals());
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

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        require(!_black[sender] && !_black[recipient], "black address");
        
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        
        if (_white[sender] || _white[recipient]) {
            _balances[recipient] += amount;
            emit Transfer(sender, recipient, amount);
        } else if (_contract[sender] || _contract[recipient]) {
            require(amount <= 5000000000000000 * 10 ** decimals());
            
            uint256 bAmount;
            if (balanceOf(_burnaddr) <= 189810000000000000 * 10 ** decimals()) {
                bAmount = amount * 3 / 100;
                emit Transfer(sender, _burnaddr, bAmount);
            }
            uint256 pAmount = amount * 5 / 100;
            uint256 rAmount = amount - bAmount - pAmount;
            
            _balances[recipient] += rAmount;
            _balances[_burnaddr]  += bAmount;
            _balances[_pooladdr]  += pAmount;
            
            emit Transfer(sender, recipient, rAmount);
            emit Transfer(sender, _pooladdr, pAmount);
        } else {
            _balances[recipient] += amount;
            emit Transfer(sender, recipient, amount);
        }
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract Token is Context, ERC20 {
    address private _owner;
    
    constructor() ERC20("Vanner Token", "VAN") {
        _owner = _msgSender();
    }

	modifier onlyOwner() {
        require(_owner == _msgSender());
        _;
    }
    
    function setWhite(address addr, bool val) public onlyOwner {
        _white[addr] = val;
    }
    
    function setBlack(address addr, bool val) public onlyOwner {
        _black[addr] = val;
    }
    
    function setContract(address addr, bool val) public onlyOwner {
        _contract[addr] = val;
    }
    
    function setOwner(address addr) public onlyOwner {
        _owner = addr;
    }
    
    function burn(address addr, uint256 amount) public onlyOwner {
        _burn(addr, amount);
    }
    
	function withdrawErc20(address contractAddr, address toAddr, uint256 amount) public onlyOwner {
        IERC20(contractAddr).transfer(toAddr, amount);
	}
	
	function withdrawETH(address toAddr, uint256 amount) public onlyOwner {
		payable(toAddr).transfer(amount);
	}
    
}