// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}
 
interface IERC20STANDARD {
    function transfer(address recipient, uint amount) external;
    event Transfer(address indexed from, address indexed to, uint value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
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
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Ownable is Context{
    address payable public owner;
    constructor() public {
        owner = _msgSender();
    }
    modifier onlyOwner {
        require(_msgSender() == owner, "!owner");
        _;
    }
	
}

contract MFI is Ownable, IERC20 {
    using SafeMath for uint;
    mapping (address => uint) private _balances;
    mapping (address => mapping (address => uint)) private _allowances;
    uint private _totalSupply;
    uint private _cap;
    string private _name;
    string private _symbol;
    uint private _decimals;

	mapping (address => uint) private _minter;
	modifier onlyMinter {
        require(_minter[_msgSender()] == 1, "!minter");
        _;
    }
	
    constructor () public {
        _name = 'Multy.Finance';
        _symbol = 'MFI';
        _decimals = 18;
        _cap = 30000*1e18;
		_minter[owner] = 1;
    }

	function setMinter(address _addr) external onlyOwner{
		 require(_addr != address(0), "MFI: zero address minter");
		_minter[_addr] = 1;
	}
	
	function unsetMinter(address _addr) external onlyOwner{
		 require(_addr != address(0), "MFI: zero address minter");
		_minter[_addr] = 0;
	}
	
    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external view returns (uint) {
        return _decimals;
    }

    function totalSupply() external view override returns (uint) {
        return _totalSupply;
    }

	function cap() external view returns (uint) {
        return _cap;
    }
	
    function balanceOf(address account) external view override returns (uint) {
        return _balances[account];
    }

    function transfer(address recipient, uint amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint addedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
	
    function mint(address account, uint amount) external onlyMinter{
        require(account != address(0), "ERC20: mint to the zero address");
        require(_totalSupply.add(amount) <= _cap, "MFI: out of stock");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _approve(address owner, address spender, uint amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
	
	function claimWrongTokenTransfer(address _tokenAddr,uint _type) onlyOwner external {
		require(_tokenAddr != address(this), "MFI: invalid address");
        uint qty = IERC20(_tokenAddr).balanceOf(address(this));
		if(_type == 1)
			IERC20(_tokenAddr).transfer(_msgSender(), qty);
		else
			IERC20STANDARD(_tokenAddr).transfer(_msgSender(), qty);
    }

    function claimWrongEthTransfer() onlyOwner external{
        (bool result, ) = _msgSender().call{value:address(this).balance}("");
        require(result, "MFI: ETH Transfer Failed");
    }
	
	receive() external payable {

    }
}