/**
 *Submitted for verification at BscScan.com on 2021-07-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
contract Ownable is Context {
    address private _owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }
}

contract TESTAIRDROP is Context, IERC20, IERC20Metadata, Ownable {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    address payable _owner;
    
    //airdrop 
    uint256 airdropFromBlock;
    uint256 airdropEndBlock;
    uint256 airdropAmount;
    uint256 airdropMax;
    uint256 airdropCount;
    
    //sale 
    uint256 saleFromBlock;
    uint256 saleEndBlock;
    uint256 salePrice;
    uint256 saleMaxToken;
    uint256 saleCount = 0;
    uint256 saleMinPrice;
    uint256 saleTotalToken = 0;
    
    event Received(address sender, uint amount);
    
    constructor() {
        _name = "TESTAIRDROP";
        _symbol = "ADR";
        _totalSupply = 1000000000 * 10**18;
        _balances[_msgSender()] = _totalSupply;
        
        _owner = payable(msg.sender);
        
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    function getBalance() external view returns(uint) {
        return address(this).balance;
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
    function mint(address to, uint256 amount) public onlyOwner virtual returns (bool) {
        _mint(to, amount);
        return true;
    }
    function getAirdrop() public view returns(uint256 _airdropFromBlock, uint256 _airdropEndBlock, uint256 _airdropAmount, uint256 _airdropMax, uint256 _airdropCount) {
        return (airdropFromBlock, airdropEndBlock, airdropAmount, airdropMax, airdropCount);
    }
    function claimAirdrop() public virtual returns(bool) {
        require(airdropFromBlock <= block.number && block.number <= airdropEndBlock, "Airdrop Ended");
        require(airdropCount < airdropMax && airdropMax > 0, "Airdrop Ended");
        require(balanceOf(address(this)) > 0, "Airdrop Ended");
        airdropCount ++;
        _balances[address(this)] -= airdropAmount;
        _balances[msg.sender] += airdropAmount;
        emit Transfer(address(this), _msgSender(), airdropAmount);
        return true;
    }
    function startAirdrop(uint256 _airdropFromBlock, uint256 _airdropEndBlock, uint256 _airdropAmount, uint256 _airdropMax) public onlyOwner() {
        airdropFromBlock = _airdropFromBlock;
        airdropEndBlock = _airdropEndBlock;
        airdropAmount = _airdropAmount;
        airdropMax = _airdropMax;
        airdropCount = 0;
    }
    
    function getSale() public view returns(uint256 _saleFromBlock, uint256 _saleEndBlock, uint256 _salePrice, uint256 _saleTotalToken, uint256 _saleMaxToken, uint256 _saleMinAmount, uint256 _saleCount) {
        return (saleFromBlock, saleEndBlock, salePrice, saleTotalToken, saleMaxToken, saleMinPrice, saleCount);
    }
    
    function tokenSale() public payable virtual returns (bool) {
        uint256 _bnb = msg.value;
        require(saleFromBlock <= block.number && block.number <= saleEndBlock, "Private sale ende1");
        require(saleTotalToken < saleMaxToken, "Private sale ended");
        require(balanceOf(address(this)) > 0, "Private sale ended");
        require(_bnb >= saleMinPrice, "Sale min");

        uint256 _tokenSale = _bnb * salePrice / 10**18;
        saleCount ++;
        saleTotalToken += _tokenSale;
        _balances[address(this)] -= _tokenSale;
        _balances[msg.sender] += _tokenSale;
        emit Transfer(address(this), _msgSender(), _tokenSale);
        return true;
    }
    function startSale(uint256 _saleFromBlock, uint256 _saleEndBlock, uint256 _salePrice, uint256 _saleMaxToken, uint256 _saleMinPrice) public onlyOwner() {
        saleFromBlock = _saleFromBlock;
        saleEndBlock = _saleEndBlock;
        salePrice = _salePrice;
        saleMaxToken = _saleMaxToken;
        saleMinPrice = _saleMinPrice;
        saleTotalToken = 0;
        saleCount = 0;
      }
    function withdraw() public onlyOwner() {
        _owner.transfer(address(this).balance);
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
    function tokenContract() public view virtual returns (address) {
        return address(this);
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
    }
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
}