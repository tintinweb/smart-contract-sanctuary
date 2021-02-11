/**
 *Submitted for verification at Etherscan.io on 2021-02-10
*/

/**
 * 
 * Long Live Satoshi.
 * 
 * https://gaspay.io
 * 
 * https://t.me/GasPayDeFi
 * https://t.me/GasPayAnnouncements
 *
 * 
*/ 

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

contract GasPay is Ownable, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => Lock[]) _locks;

    uint256 private _totalSupply = 100000 ether;

    string private _name = "GasPay";
    string private _symbol = "$GASPAY";
    uint8 private _decimals = 18;

    uint256 private _percentFees = 6;

    event Deposit(address indexed depositor, uint256 depositAmount, uint256 timestamp, uint256 unlockTimestamp);

    struct Lock {
        uint256 lockAmount;
        uint256 unlockTime;
    }

    constructor() {
        _balances[owner()] = _totalSupply;
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

    function getContractBalance() public view returns (uint256) {
        return _balances[address(this)];
    }

    function getFeeAmount(uint256 amount) public view returns (uint256) {
        return amount.mul(_percentFees).div(100);
    }

    function getUnlockableAmount(address account) public view returns (uint256) {
        Lock[] memory locks = _locks[account];
        uint256 unlockableAmount = 0;

        for (uint i=0; i<locks.length; i++) {
            if (block.timestamp >= locks[i].unlockTime) {
                unlockableAmount = unlockableAmount.add(locks[i].lockAmount);
            }
        }
        
        return unlockableAmount;
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

    function lock(uint256 amount) public virtual {
        address user = _msgSender();
        uint256 lockAmount = amount;
        uint256 timestamp = block.timestamp;
        uint256 unlockTimestamp = timestamp.add(5 days);

        _depositForLock(user, lockAmount);

        Lock memory currentLock = Lock(
            {
                lockAmount: amount,
                unlockTime: unlockTimestamp
            }
        );

        _locks[user].push(currentLock);

        emit Deposit(user, lockAmount, timestamp, unlockTimestamp);
    }

    function unlock() public virtual {
        uint256 unlockableAmount = getUnlockableAmount(_msgSender());
        require(unlockableAmount > 0, "No unlockable Tokens");
                
        Lock[] storage locks = _locks[_msgSender()];
        uint256 withdrawAmount = 0;

        // loop just in case somehow the order gets messed up, would be possible with single assignment from index 0 too
        for (uint i=0; i<locks.length; i++) {
            if (block.timestamp >= locks[i].unlockTime) {
                withdrawAmount = withdrawAmount.add(locks[i].lockAmount);
                locks = _removeIndex(i, locks);
                break;
            }
        }

        _locks[_msgSender()] = locks;

        _withdrawFromLock(_msgSender(), withdrawAmount);
    }

    function _removeIndex(uint256 index, Lock[] storage array) internal virtual returns(Lock[] storage) {
        if (index >= array.length) {
            return array;
        }

        for (uint i=index; i<array.length-1; i++) {
            array[i] = array[i+1];
        }

        array.pop();

        return array;
    }

    function _depositForLock(address sender, uint256 amount) internal virtual {
        _balances[sender] = _balances[sender].sub(amount, "ERC20: lock amount exceeds balance");
        _balances[address(this)] = _balances[address(this)].add(amount);
        
        emit Transfer(sender, address(this), amount);
    }

    function _withdrawFromLock(address withdrawer, uint256 amount) internal virtual {
        _balances[address(this)] = _balances[address(this)].sub(amount);
        _balances[withdrawer] = _balances[withdrawer].add(amount);
        
        emit Transfer(address(this), withdrawer, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 transferFee = getFeeAmount(amount);
        uint256 amountAfterFee = amount.sub(transferFee);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amountAfterFee);

        _balances[owner()] = _balances[owner()].add(transferFee);

        emit Transfer(sender, recipient, amount);
        emit Transfer(sender, owner(), transferFee);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}