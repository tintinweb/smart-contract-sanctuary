/**
 *Submitted for verification at Etherscan.io on 2021-04-17
*/

// SPDX-License-Identifier: MIT
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
    
    event TransferFrom(address indexed from, address indexed to, uint256 value);
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

//SAFE MATH
library SafeMath {
   
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }


    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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

abstract contract Pausable is Ownable {

    event Paused(address account);
    event Unpaused(address account);
    
    bool private _paused;

    constructor () {
        _paused = false;
    }

    //VERIFICA SE ESTA PAUSADO OU N
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    //MODIFIER RODA QUANDO ESTIVER PAUSADO
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function pause() public virtual whenNotPaused onlyOwner {
        _paused = true;
        emit Paused(_msgSender());
    }

    function unpause() public virtual whenPaused onlyOwner {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

abstract contract WhiteList is Ownable {
     mapping (address => bool) private _whitelist;
     bool private _use_whitelist;
     
    event UsedWhitelist(address account);
    event UnUsedWhitelist(address account);
    event AddressAddWhitelist(address account);
    event AddressRemoveWhitelist(address account);
     
    constructor () {
        _use_whitelist = true;
    }

    modifier onlyWhitelistAddress() {
        if(_use_whitelist == true) {
            require(_whitelist[_msgSender()] == true);
        }
        _;
    }
    
    function verifyWhitlistAddress (address _address) public view returns (bool) {
        if(_use_whitelist == false) {
            return true;
        }
        if(_whitelist[_address] == true) {
            return true;
        } else {
            return false;
        }
    }
    
    function usedWhitelist() public view virtual returns (bool) {
        return _use_whitelist;
    }
    
    function useWhitelist() public virtual onlyOwner {
        _use_whitelist = true;
        emit UsedWhitelist(_msgSender());
    }

    function unUsedWhitelist() public virtual onlyOwner {
        _use_whitelist = false;
        emit UnUsedWhitelist(_msgSender());
    }
      
    function addWhitelistAddress (address _address) public onlyOwner{
        _whitelist[_address] = true;
        emit AddressAddWhitelist(_address);
    }
    
    
    function removeWhitelistAddress (address _address) public onlyOwner{
        _whitelist[_address] = false;
        emit AddressRemoveWhitelist(_address);
    }
}



contract ERC20 is Context, IERC20, Pausable, WhiteList {
    
    using SafeMath for uint256;
    
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    
    event Redeem(address owner,  uint amount);

    constructor () {
        _name = "CRD.B";
        _symbol = "CRD";
        _totalSupply = 200000000000000000000000000;
        _balances[msg.sender] = _balances[msg.sender].add(_totalSupply);
        addWhitelistAddress(msg.sender);
    }
    
    function pay() public payable {}

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address recipient, uint256 amount) public whenNotPaused onlyWhitelistAddress virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) public whenNotPaused onlyWhitelistAddress virtual override returns (bool) {
        require(verifyWhitlistAddress(spender) == true, "ERC20 WhiteList: transfer to the address not whitelist");
        _approve(_msgSender(), spender, amount);
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) public whenNotPaused virtual override returns (bool) {
        require(verifyWhitlistAddress(sender) == true, "ERC20 WhiteList: transfer to the address not whitelist (Sender)");
        require(verifyWhitlistAddress(recipient) == true, "ERC20 WhiteList: transfer to the address not whitelist (Recipient)");
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        
        currentAllowance = currentAllowance.sub(amount);
        
        _approve(sender, _msgSender(), currentAllowance);
       
        emit TransferFrom(sender, recipient, amount);
        
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused onlyWhitelistAddress virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused onlyWhitelistAddress virtual returns (bool) {
        require(verifyWhitlistAddress(spender) == true, "ERC20 WhiteList: transfer to the address not whitelist (Spender)");
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        currentAllowance = currentAllowance.sub(subtractedValue);
        _approve(_msgSender(), spender, currentAllowance);

        return true;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(verifyWhitlistAddress(recipient) == true, "ERC20 WhiteList: transfer to the address not whitelist");
        
        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        senderBalance = senderBalance.sub(amount);
        _balances[sender] = senderBalance;
        
        _balances[recipient] = _balances[recipient].add(amount);
        
        
        emit Transfer(sender, recipient, amount);
    }
    
    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        require(verifyWhitlistAddress(owner) == true, "ERC20 WhiteList: transfer to the address not whitelist (Owner)");
        require(verifyWhitlistAddress(spender) == true, "ERC20 WhiteList: transfer to the address not whitelist (SPENDER)");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}