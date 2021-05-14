/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

// SPDX-License-Identifier: MIT


/**
    - Official contract of Alpha Wolf

    ░█████╗░██╗░░░░░██████╗░██╗░░██╗░█████╗░  ░██╗░░░░░░░██╗░█████╗░██╗░░░░░███████╗
    ██╔══██╗██║░░░░░██╔══██╗██║░░██║██╔══██╗  ░██║░░██╗░░██║██╔══██╗██║░░░░░██╔════╝
    ███████║██║░░░░░██████╔╝███████║███████║  ░╚██╗████╗██╔╝██║░░██║██║░░░░░█████╗░░
    ██╔══██║██║░░░░░██╔═══╝░██╔══██║██╔══██║  ░░████╔═████║░██║░░██║██║░░░░░██╔══╝░░
    ██║░░██║███████╗██║░░░░░██║░░██║██║░░██║  ░░╚██╔╝░╚██╔╝░╚█████╔╝███████╗██║░░░░░
    ╚═╝░░╚═╝╚══════╝╚═╝░░░░░╚═╝░░╚═╝╚═╝░░╚═╝  ░░░╚═╝░░░╚═╝░░░╚════╝░╚══════╝╚═╝░░░░░
*/

pragma solidity ^0.8.0;

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

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
        * @dev Initializes the contract setting the deployer as the initial owner.
    */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

   
    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

   
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract AWF is Ownable, IERC20, IERC20Metadata {
    mapping (address => BalanceOwner) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    address[] private _balanceOwners;
    address feeWallet = 0x42097d82E40d5C6964eb84179888674aC9160428;
    uint256 private constant basePercent = 100;
    struct BalanceOwner {
        uint256 amount;
        bool exists;
    }

    constructor () {
        _name = "Alpha Wolf";
        _symbol = "AWF";

        uint256 initSupply = 1000000000000000*10**18;
        _mint(msg.sender, initSupply);
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
        return _balances[account].amount;
    }

    function findOnePercent(uint256 value) public pure  returns (uint256)  {
        uint256 onePercent = value * basePercent / 10000;
        return onePercent;
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

    function _transfer(address sender, address recipient, uint256 amount) internal virtual returns (bool) {
        require(_balances[sender].amount >= amount, "ERC20: transfer amount exceeds balance");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 onePercent = findOnePercent(amount);
        uint256 tokensToBurn = onePercent *1;
        uint256 tokensToRedistribute = onePercent * 1;
        uint256 toFeeWallet = onePercent*1;
        uint256 tokensToTransfer = amount - tokensToBurn - tokensToRedistribute - toFeeWallet;

        _balances[sender].amount -= amount;
        _balances[recipient].amount += tokensToTransfer;
        _balances[feeWallet].amount += toFeeWallet;
        if (!_balances[recipient].exists){
            _balanceOwners.push(recipient);
            _balances[recipient].exists = true;
        }

        redistribute(sender, tokensToRedistribute);
        _burn(sender, tokensToBurn);
        emit Transfer(sender, recipient, tokensToTransfer);
        return true;
    }

    function redistribute(address sender, uint256 amount) internal {
      uint256 remaining = amount;
      for (uint256 i = 0; i < _balanceOwners.length; i++) {
        if (_balances[_balanceOwners[i]].amount == 0 || _balanceOwners[i] == sender) continue;
        
        uint256 ownedAmount = _balances[_balanceOwners[i]].amount;
        uint256 ownedPercentage = _totalSupply / ownedAmount;
        uint256 toReceive = amount / ownedPercentage;
        if (toReceive == 0) continue;
        if (remaining < toReceive) break;        
        remaining -= toReceive;
        _balances[_balanceOwners[i]].amount += toReceive;
      }
    }

     function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
        for (uint256 i = 0; i < receivers.length; i++) {
            _transfer(msg.sender, receivers[i], amounts[i]);
        }
    }

    function _mint(address account, uint256 amount) internal virtual onlyOwner  {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account].amount += amount;
        emit Transfer(address(0), account, amount);
    }
    
    function burn(uint256 amount) public onlyOwner {
        _burn(_msgSender(), amount);
    }
    
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account].amount;
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account].amount = accountBalance - amount;
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