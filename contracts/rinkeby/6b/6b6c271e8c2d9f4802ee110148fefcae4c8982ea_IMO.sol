/**
 *Submitted for verification at Etherscan.io on 2021-05-10
*/

pragma solidity 0.6.11;

// SPDX-License-Identifier: BSD-3-Clause

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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



contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
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

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
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

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}



abstract contract ERC20Burnable is Context, ERC20 {
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        uint256 decreasedAllowance = allowance(account, _msgSender()).sub(amount, "ERC20: burn amount exceeds allowance");

        _approve(account, _msgSender(), decreasedAllowance);
        _burn(account, amount);
    }
}

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }


  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}


contract IMO is ERC20Burnable, Ownable {
    constructor() public ERC20("IMO", "IMO") {
        _mint(_msgSender(), 20_000_000 * 10 ** 18);
    }
    
    // dex pair address on which to charge transfer fee
    address public pairAddress;
    
    // recipient of the transfer fee
    address public feeRecipientAddress;
    
    // ----------------------- token airdrop logic -----------------------
    // all token holders receive pro-rata share of the amount
    
    uint public constant POINT_MULTIPLIER = 1e18;
    mapping (address => uint) public lastDivPoints;
    mapping (address => uint) public divsBalance;
    uint public totalDivPoints;
    
    event Airdrop(uint amount);
    event Claim(address indexed account, uint amount);
    
    function divsOwing(address account) public view returns (uint) {
        uint newDivPoints = totalDivPoints.sub(lastDivPoints[account]);
        return balanceOf(account).mul(newDivPoints).div(POINT_MULTIPLIER);
    }
    
    function updateAccount(address account) private {
        uint owing = divsOwing(account);
        lastDivPoints[account] = totalDivPoints;
        if (owing > 0) {
            divsBalance[account] = divsBalance[account].add(owing);
        }
    }
    
    function airdrop(uint amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0!");
        require(this.transferFrom(_msgSender(), address(this), amount), "airdrop: transferFrom failed!");
        
        totalDivPoints = totalDivPoints.add(amount.mul(POINT_MULTIPLIER).div(totalSupply()));
        emit Airdrop(amount);
    }
    
    function claim() external {
        address beneficiary = _msgSender();
        updateAccount(beneficiary);
        uint amountToSend = divsBalance[beneficiary];
        require(amountToSend > 0, "No divs to claim!");
        divsBalance[beneficiary] = 0;
        require(this.transfer(beneficiary, amountToSend), "claim: transfer failed!");
        emit Claim(beneficiary, amountToSend);
    }
    
    // --------------------- end token airdrop logic ---------------------
    
    function setFeeRecipientAddress(address newFeeRecipientAddress) external onlyOwner {
        feeRecipientAddress = newFeeRecipientAddress;
    }
    
    function setPairAddress(address newPairAddress) external onlyOwner {
        require(pairAddress == address(0), "Pair address already set!");
        pairAddress = newPairAddress;
    }
    
    function burn(uint amount) public virtual override {
        updateAccount(_msgSender());
        super.burn(amount);
    }
    function burnFrom(address account, uint amount) public virtual override {
        updateAccount(account);
        super.burnFrom(account, amount);
    }
    function transfer(address recipient, uint amount) public virtual override returns (bool) {
        updateAccount(_msgSender());
        updateAccount(recipient);
        updateAccount(feeRecipientAddress);
        
        if (_msgSender() == pairAddress || recipient == pairAddress) {
            uint zeroPointOnePercent = amount.mul(10).div(10000);
            uint zeroPointThreePercent = amount.mul(30).div(10000);
            uint amountAfterFee = amount.sub(zeroPointOnePercent).sub(zeroPointThreePercent);
            
            burn(zeroPointOnePercent);
            require(super.transfer(feeRecipientAddress, zeroPointThreePercent), "transfer: fee transfer failed!");
            require(super.transfer(recipient, amountAfterFee), "transfer: transfer failed!");
            
            return true;
        } else {
            return super.transfer(recipient, amount);
        }
    }
    function transferFrom(address sender, address recipient, uint amount) public virtual override returns (bool) {
        updateAccount(sender);
        updateAccount(recipient);
        updateAccount(feeRecipientAddress);
        
        if (sender == pairAddress || recipient == pairAddress) {
            
            uint zeroPointOnePercent = amount.mul(10).div(10000);
            uint zeroPointThreePercent = amount.mul(30).div(10000);
            uint amountAfterFee = amount.sub(zeroPointOnePercent).sub(zeroPointThreePercent);
            
            burnFrom(sender, zeroPointOnePercent);
            require(super.transferFrom(sender, feeRecipientAddress, zeroPointThreePercent), "transferFrom: fee transfer failed!");
            require(super.transferFrom(sender, recipient, amountAfterFee), "transferFrom: transfer failed!");
            
            return true;
        } else {
            return super.transferFrom(sender, recipient, amount);
        }
    }
}