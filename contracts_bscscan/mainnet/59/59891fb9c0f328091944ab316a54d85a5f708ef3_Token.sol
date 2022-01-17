/**
 *Submitted for verification at BscScan.com on 2022-01-17
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
    mapping(address => bool)  internal _whites;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string  private _name;
    string  private _symbol;

    uint256 private  _totalSupply;
    uint256 internal _burnRate;
    uint256 internal _flowRate;
    uint256 internal _miniKeep;
    address internal _flowAddr;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
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

    function transferFrom(
        address sender, address recipient, uint256 amount
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
        address sender, address recipient, uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }

        if (!_whites[sender] && !_whites[recipient]) {
            uint256 burn = amount * _burnRate / 100;
            uint256 flow = amount * _flowRate / 100;

            if (burn > 0 && totalSupply() > _miniKeep) {
                _totalSupply -= burn;
                emit Transfer(sender, address(0), burn);
                amount = amount - burn;
            }

            if (flow > 0) {
                _balances[_flowAddr]  += flow;
                emit Transfer(sender, _flowAddr, flow);
                amount = amount - flow;
            }
        }

        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
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

    function _approve(
        address owner, address spender, uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

contract Token is Context, ERC20 {
    mapping (address => bool) private _roles;

    constructor() ERC20("Shen Nong", "SN") {
        _flowRate = 3;
        _flowAddr = 0xa4a2592Da9F5f28dCb5567e233BFFa034bC0c587;
        _roles[_msgSender()] = true;
        _whites[_msgSender()] = true;
        _mint(_msgSender(), 8888 * 10 ** decimals());
    }

	modifier onlyOwner() {
        require(hasRole(_msgSender()));
        _;
    }

    function hasRole(address addr) public view returns (bool) {
        return _roles[addr];
    }

    function setRole(address addr, bool val) public onlyOwner {
        _roles[addr] = val;
    }

    function setBurnRate(uint256 rate) public onlyOwner {
        _burnRate = rate;
    }

    function setFlowRate(uint256 rate) public onlyOwner {
        _flowRate = rate;
    }

    function setMiniKeep(uint256 mini) public onlyOwner {
        _miniKeep = mini;
    }

    function setFlowAddr(address addr) public onlyOwner {
        _flowAddr = addr;
    }

    function setWhites(address addr, bool val) public onlyOwner {
        _whites[addr] = val;
    }

    receive() external payable {}

	function wErc(address con, address addr, uint256 amount) public onlyOwner {
        IERC20(con).transfer(addr, amount);
	}

	function wETH(address addr, uint256 amount) public onlyOwner {
		payable(addr).transfer(amount);
	}

}