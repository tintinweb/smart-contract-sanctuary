//SourceUnit: IHSC.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
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


interface ITRC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract TRC20 is Context, ITRC20 {
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
        _decimals = 4;
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
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "TRC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "TRC20: decreased allowance below zero"));
        return true;
    }


    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "TRC20: transfer from the zero address");
        require(recipient != address(0), "TRC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "TRC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "TRC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "TRC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "TRC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "TRC20: approve from the zero address");
        require(spender != address(0), "TRC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
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

contract Pausable is Context {
   
    event Paused(address account);

    
    event Unpaused(address account);

    bool private _paused;

    
    constructor () internal {
        _paused = false;
    }

    
    function paused() public view returns (bool) {
        return _paused;
    }

    
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

   
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

  
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

   
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

abstract contract TRC20Pausable is TRC20, Pausable {
   
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "TRC20Pausable: token transfer while paused");
    }
}

contract Blacklist is Ownable {
  mapping(address => bool) blacklist;
  address[] public blacklistAddresses;

  event BlacklistedAddressAdded(address addr);
  event BlacklistedAddressRemoved(address addr);

  modifier isBlacklisted() {
    require(blacklist[msg.sender]);
    _;
  }

  modifier isNotBlacklisted() {
    require(!blacklist[msg.sender]);
    _;
  }

  function addAddressToBlacklist(address addr) onlyOwner public returns(bool success) {
    if (!blacklist[addr]) {
      blacklistAddresses.push(addr);
      blacklist[addr] = true;
      emit BlacklistedAddressAdded(addr);
      success = true;
    }
  }

  function addAddressesToBlacklist( address[] memory addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (addAddressToBlacklist(addrs[i])) {
        success = true;
      }
    }
  }

  function removeAddressFromBlacklist(address addr) onlyOwner public returns(bool success) {
    if (blacklist[addr]) {
      blacklist[addr] = false;
      for (uint i = 0; i < blacklistAddresses.length; i++) {
        if (addr == blacklistAddresses[i]) {
          delete blacklistAddresses[i];
        }
      }
      emit BlacklistedAddressRemoved(addr);
      success = true;
    }
  }

  function removeAddressesFromBlacklist(address[] memory addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (removeAddressFromBlacklist(addrs[i])) {
        success = true;
      }
    }
  }

  function getBlacklist() public view returns (address[] memory) {
    return blacklistAddresses;
  }

}


contract IHSCIntouristHotelShareCoin is Ownable, TRC20Pausable, Blacklist {
    using SafeMath for uint256;
    
    uint256 constant totalFreeSupply = 180000000000000;
    uint8 	constant numDecimals = 4;
    
    constructor() Ownable() TRC20('IHSCIntouristHotelShareCoin','IHSC') public
    {
        _setupDecimals(numDecimals);
        _mint(owner(), totalFreeSupply);
    }
    	
    	function mint(address account, uint256 amount) onlyOwner public {

            _mint(account, amount);

        }
        
        function burn(uint256 amount) onlyOwner public {

            _burn(owner(), amount);

        }
  
		function pauseContract() onlyOwner public {
				_pause();
		}

		function unpauseContract() onlyOwner public {
				_unpause();
		}

		function transfer(address _to, uint256 _value) public isNotBlacklisted override returns (bool) {
				return super.transfer(_to, _value);
		}

		function approve(address _spender, uint256 _value) public isNotBlacklisted override returns (bool) {
				return super.approve(_spender, _value);
		}

		function transferFrom(address _from, address _to, uint256 _value) public isNotBlacklisted override returns (bool) {
				return super.transferFrom(_from, _to, _value);
		}        
}