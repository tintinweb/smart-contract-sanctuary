// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./IERC20.sol";
import "./MinterRole.sol";


contract StakedRNBO is Context, IERC20, Ownable, MinterRole {
    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    address[] private _excluded;
    
    uint256 private constant _maxSupply = 33333333 * 10**18;
    
    uint256 private _totalSupply = 0;

    string private _name = 'Proof Of Staking Token';
    string private _symbol = 'stkRNBO';
    uint8 private _decimals = 18;

    constructor () public {
    }
    
    function mint(address _to,uint256 amount) public onlyMinter returns (bool){
        require(_totalSupply.add(amount) <= _maxSupply, "Error::MaxSupply:Max Supply Reached");
        _totalSupply = _totalSupply.add(amount);
        _balances[_to] = _balances[_to].add(amount);
        emit Transfer(msg.sender, _to, amount);
        return true;
    }
    
    function burn(address _from,uint256 amount) public onlyMinter returns (bool){
        require(_balances[_from].sub(amount) >= 0, "Error::Burn:Burning more than balance in account");
        require(_totalSupply.sub(amount) >= 0, "Error::Burn:Burning more than supply");
        _totalSupply = _totalSupply.sub(amount);
        _balances[_from] = _balances[_from].sub(amount);
        emit Transfer(_from, address(0), amount);
        return true;
    }
    
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public onlyOwner() override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public onlyOwner() override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);       
        emit Transfer(sender, recipient, amount);
    }


    function _getCurrentSupply() private view returns(uint256) {
        return _totalSupply;
    }
    
   function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }    
}