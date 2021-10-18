/**
 *Submitted for verification at BscScan.com on 2021-10-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;


interface IBEP20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */

/* 0.8.4


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
         return payable(msg.sender); // added payable
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   * - Multiplication cannot overflow.
   */
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

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, "SafeMath: division by zero");
  }

  /**
   * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, "SafeMath: modulo by zero");
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * Reverts with custom message when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
  address private _owner;
  address private _previousOwner;
  uint256 private _lockTime;

  uint8 private _devf;
  uint8 private _markf;
  uint8 private _charityf;

  uint8 private _burning;
  uint8 private _sburning;
  
  address private _dev;
  address private _mark;
  address private _charity;
  
  uint256 private _timelockv;
  
  mapping(address=>bool) private _whitelist;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor () {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }
  


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   */
  function _transferOwnership(address newOwner) public virtual onlyOwner  {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
  

	function setDevFee(uint8 devf) public virtual onlyOwner {
		_devf = devf;
	}
	
	function getDevFee() public view returns (uint8) {
        return _devf;
    }
    
    function setMarkFee(uint8 markf) public virtual onlyOwner {
		_markf = markf;
	}
	
	function getMarkFee() public view returns (uint8) {
        return _markf;
    }
    
    function setCharityFee(uint8 charityf) public virtual onlyOwner {
		_charityf = charityf;
	}
	
	function getCharityFee() public view returns (uint8) {
        return _charityf;
    }
    
    function setBuyBurning(uint8 burning) public virtual onlyOwner {
		_burning = burning;
	}
	
	function getBuyBurning() public view returns (uint8) {
        return _burning;
    }
    
    function setSellBurning(uint8 sburning) public virtual onlyOwner {
		_sburning = sburning;
	}
	
	function getSellBurning() public view returns (uint8) {
        return _sburning;
    }
    
    function getDevAddress() public view returns (address) {
        return _dev;
    }
    
    function setDevAddress(address dev) public virtual onlyOwner {
		_dev = dev;
	}
    
    function getMarkAddress() public view returns (address) {
        return _mark;
    }
    
    function setMarkAddress(address mark) public virtual onlyOwner {
		_mark = mark;
	}
	
	function getCharityAddress() public view returns (address) {
        return _charity;
    }
    
    function setCharityAddress(address charity) public virtual onlyOwner {
		_charity = charity;
	}
	
	    
    function getTimelock() public view returns (uint256) {
        return _timelockv;
    }

    function setTimelock(uint256 timelockv) public virtual onlyOwner {
	    _timelockv = timelockv;
    }
    
    function getWhitelist(address ad) public view returns (bool) {
        return _whitelist[ad];
    }
    function setWhitelist(bool wl, address ad) public virtual onlyOwner {
	    _whitelist[ad] = wl;
    }

}

contract BEP20Token is Context, IBEP20, Ownable {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowances;

  uint256 private _totalSupply;
  uint8 private _decimals;
  string private _symbol;
  string private _name;
  
  
  //uint8 private _devf;
  //uint8 private _markf;
  
  //address  dev = 0xDaEB888B857b0a424366b336C32A61f33d3Ee965;
  //address mark = 0x268bb15831DaAF236ACA0c150fAddB91B10627a8;
  //address char = 0xc652d594557F27249c330af236a4061a2f5020e4;

  constructor() {
    _name = "Atest4";
    _symbol = "Atest4";
    _decimals = 10;
    //_totalSupply = 100000000 * 10**_decimals;
    _totalSupply = 46000000 * 10**_decimals;
    _balances[msg.sender] = _totalSupply;
    
    //_devf=2;
    //_markf=2;

    emit Transfer(address(0), msg.sender, _totalSupply);
  }

  function getOwner() public override view returns (address) {
     return owner();
  }
   
  function decimals() public override view returns (uint8) {
     return _decimals;
  }

  function symbol() public override view returns (string memory) {
     return _symbol;
  }

  function name() public override view returns (string memory) {
     return _name;
  }

  function totalSupply() public override view returns (uint256) {
     return _totalSupply;
  }

  function balanceOf(address account) public override view returns (uint256) {
     return _balances[account];
  }

  function transfer(address recipient, uint256 amount) public override returns (bool) {
    if (_msgSender()!=getOwner() || getWhitelist(_msgSender())){
            _burn(_msgSender(),amount.mul(getBuyBurning()).div(10**2));
            _transfer(_msgSender(), getDevAddress(), amount.mul(getDevFee()).div(10**2));
            _transfer(_msgSender(), getMarkAddress(), amount.mul(getMarkFee()).div(10**2));
            _transfer(_msgSender(), getCharityAddress(), amount.mul(getCharityFee()).div(10**2));
            _transfer(_msgSender(), recipient, amount.sub(amount.mul(getBuyBurning()+getDevFee()+getMarkFee()+getCharityFee()).div(10**2)));
            return true;
    }else{
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
  }
    
  function allowance(address owner, address spender) public override view returns (uint256) {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public override returns (bool) {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
    if (_msgSender()!=getOwner() || getWhitelist(_msgSender())){
            _burn(sender,amount.mul(getSellBurning()).div(10**2));
            _transfer(sender, getDevAddress(), amount.mul(getDevFee()).div(10**2));
            _transfer(sender, getMarkAddress(), amount.mul(getMarkFee()).div(10**2));
            _transfer(sender, getCharityAddress(), amount.mul(getCharityFee()).div(10**2));
            _transfer(sender, recipient, amount.sub(amount.mul(getBuyBurning()+getDevFee()+getMarkFee()+getCharityFee()).div(10**2)));
            _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
            return true;
    }else{
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }
  }

  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
    return true;
  }
  
  function mint(uint256 amount) public onlyOwner returns (bool) {
    _mint(_msgSender(), amount);
    return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
    require(sender != address(0), "BEP20: transfer from the zero address");
    require(recipient != address(0), "BEP20: transfer to the zero address");

    _balances[sender] = _balances[sender].sub(amount, "BEP20: transfer amount exceeds balance");
    _balances[recipient] = _balances[recipient].add(amount);
    emit Transfer(sender, recipient, amount);
  }
  
  function _mint(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: mint to the zero address");

    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(account != address(0), "BEP20: burn from the zero address");

    _balances[account] = _balances[account].sub(amount, "BEP20: burn amount exceeds balance");
    _totalSupply = _totalSupply.sub(amount);
    emit Transfer(account, 0x000000000000000000000000000000000000dEaD, amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _burnFrom(address account, uint256 amount) internal {
    _burn(account, amount);
    _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "BEP20: burn amount exceeds allowance"));
  }
  
}

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}


// File: @openzeppelin/contracts/GSN/Context.sol


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */



/// @title TeamSale

interface TS {
    function mint(address to, uint256 value) external;
}

contract TeamSaleBEP20 is Ownable {
    using SafeMath for uint256;

    TS public token;
    address payable public presale;

    uint256 public saleStart;
    uint256 public teamSale;

    uint256 public teamMinDepositBNB = 0 ether;
    uint256 public teamMaxDepositBNB = 5 ether;
    uint256 public teamMaxCap = 37.5 ether;
    uint256 public teamDepositBalance;

    mapping(address => uint256) public depositsTeam;
    mapping(address => uint256) public balanceMapTeam;
    mapping(address => bool) public depositStateTeam;

    constructor(
        TS _token
    ) {
        token = _token;
        //ahova kiküldje a befolyt $-t.
        presale = payable(0x053db14f91164556C2f97B8Bd4029194aAB336fE);
        /*
        presaleEndTimestamp = block.timestamp.add(5 days + 1 hours + 30 minutes);
        */

        // ide majd konkrét időbéllyegzők kerülnek, a teszt erejéig jó így...
        saleStart = block.timestamp;
        teamSale = block.timestamp.add(5 minutes);
    }

    receive() payable external {
        depositTeamSale();
    }

    function depositTeamSale() public payable {
        require(block.timestamp >= saleStart && block.timestamp < teamSale, "presale is not active");
        require(teamDepositBalance.add(msg.value) <= teamMaxCap, "deposit limits reached");
        require(depositsTeam[msg.sender].add(msg.value) >= teamMinDepositBNB && depositsTeam[msg.sender].add(msg.value) <= teamMaxDepositBNB, "incorrect amount");

        uint256 teamSalePrice;
        teamSalePrice =  0.0000375 ether;  // 1 token / BNB price

        uint256 tokenAmount = msg.value.mul(1e18).div(teamSalePrice);
        //token.mint(msg.sender, tokenAmount);
        balanceMapTeam[msg.sender]=balanceMapTeam[msg.sender].add(tokenAmount);
        depositStateTeam[msg.sender]=true;
        teamDepositBalance = teamDepositBalance.add(msg.value);
        depositsTeam[msg.sender] = depositsTeam[msg.sender].add(msg.value);
        emit DepositedTeam(msg.sender, msg.value);
    }

    function releaseFundsTeamSale() external onlyOwner {
        require(block.timestamp > teamSale || teamDepositBalance == teamMaxCap, "presale is active");
        presale.transfer(address(this).balance);
    }

    function withdrawTeamSale()public{
        //require(depositState[msg.sender]==false || getTeamTimelock()<block.timestamp);
        require(depositStateTeam[msg.sender]);
        depositStateTeam[msg.sender]=false;
        token.mint(msg.sender, balanceMapTeam[msg.sender]);
    }

    function recoverBEP20TeamSale(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IBEP20(tokenAddress).transfer(this.owner(), tokenAmount);
        emit RecoveredTeam(tokenAddress, tokenAmount);
    }

    function getDepositAmountTeamSale() public view returns (uint256) {
        return teamDepositBalance;
    }

    function getLeftTimeAmount() public view returns (uint256) {
        if(block.timestamp > teamSale) {
            return 0;
        } else {
            return (teamSale - block.timestamp);
        }
    }

    event DepositedTeam(address indexed user, uint256 amount);
    event RecoveredTeam(address token, uint256 amount);
}

/// @title PrivateSale



interface PS {
    function mint(address to, uint256 value) external;
}

contract PrivateSaleBEP20 is Ownable {
    using SafeMath for uint256;

    PS public token;
    address payable public presale;

    uint256 public saleStart;
    uint256 public privateSale;

    uint256 public PrivateMinDepositBNB = 5 ether;
    uint256 public PrivateMaxDepositBNB = 30 ether;
    uint256 public PrivateMaxCap = 250 ether;
    uint256 public PrivateDepositBalance;

    mapping(address => uint256) public depositsPrivate;
    mapping(address => uint256) public balanceMapPrivate;
    mapping(address => bool) public depositStatePrivate;

    constructor (
        PS _token
    ) {
        token = _token;
        //ahova kiküldje a befolyt $-t.
        presale = payable(0x053db14f91164556C2f97B8Bd4029194aAB336fE);
        /*
        presaleEndTimestamp = block.timestamp.add(5 days + 1 hours + 30 minutes);
        */

        // ide majd konkrét időbéllyegzők kerülnek, a teszt erejéig jó így...
        saleStart = block.timestamp.add(10 minutes);
        privateSale = block.timestamp.add(15 minutes);
    }

    receive() payable external {
        depositPrivateSale();
    }

    function depositPrivateSale() public payable {
        require(block.timestamp >= saleStart && block.timestamp < privateSale, "presale is not active");
        require(PrivateDepositBalance.add(msg.value) <= PrivateMaxCap, "deposit limits reached");
        require(depositsPrivate[msg.sender].add(msg.value) >= PrivateMinDepositBNB && depositsPrivate[msg.sender].add(msg.value) <= PrivateMaxDepositBNB, "incorrect amount");

        uint256 PrivateSalePrice;
        PrivateSalePrice =  0.0000500 ether;  // 1 token / BNB price

        uint256 tokenAmount = msg.value.mul(1e18).div(PrivateSalePrice);
        //token.mint(msg.sender, tokenAmount);
        balanceMapPrivate[msg.sender]=balanceMapPrivate[msg.sender].add(tokenAmount);
        depositStatePrivate[msg.sender]=true;
        PrivateDepositBalance = PrivateDepositBalance.add(msg.value);
        depositsPrivate[msg.sender] = depositsPrivate[msg.sender].add(msg.value);
        emit DepositedPrivate(msg.sender, msg.value);
    }

    function releaseFundsPrivateSale() external onlyOwner {
        require(block.timestamp > privateSale || PrivateDepositBalance == PrivateMaxCap, "presale is active");
        presale.transfer(address(this).balance);
    }

    function withdrawPrivateSale()public{
        //require(depositState[msg.sender]==false || getPrivateTimelock()<block.timestamp);
        require(depositStatePrivate[msg.sender]);
        depositStatePrivate[msg.sender]=false;
        token.mint(msg.sender, balanceMapPrivate[msg.sender]);
    }

    function recoverBEP20PrivateSale(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IBEP20(tokenAddress).transfer(this.owner(), tokenAmount);
        emit RecoveredPrivate(tokenAddress, tokenAmount);
    }

    function getDepositAmountPrivateSale() public view returns (uint256) {
        return PrivateDepositBalance;
    }

    function getLeftTimeAmount() public view returns (uint256) {
        if(block.timestamp > privateSale) {
            return 0;
        } else {
            return (privateSale - block.timestamp);
        }
    }

    event DepositedPrivate(address indexed user, uint256 amount);
    event RecoveredPrivate(address token, uint256 amount);
}

/// @title Pre1Sale


interface Pre1 {
    function mint(address to, uint256 value) external;
}

contract Pre1SaleBEP20 is Ownable {
    using SafeMath for uint256;

    Pre1 public token;
    address payable public presale;

    uint256 public saleStart;
    uint256 public pre1Sale;

    uint256 public Pre1MinDepositBNB = 1 ether;
    uint256 public Pre1MaxDepositBNB = 15 ether;
    uint256 public Pre1MaxCap = 1500 ether;
    uint256 public Pre1DepositBalance;

    mapping(address => uint256) public depositsPre1;
    mapping(address => uint256) public balanceMapPre1;
    mapping(address => bool) public depositStatePre1;

    constructor(
        Pre1 _token
    ) {
        token = _token;
        //ahova kiküldje a befolyt $-t.
        presale = payable(0x053db14f91164556C2f97B8Bd4029194aAB336fE);
        /*
        presaleEndTimestamp = block.timestamp.add(5 days + 1 hours + 30 minutes);
        */

        // ide majd konkrét időbéllyegzők kerülnek, a teszt erejéig jó így...
        saleStart = block.timestamp.add(15 minutes);
        pre1Sale = block.timestamp.add(20 minutes);
    }

    receive() payable external {
        depositPre1Sale();
    }

    function depositPre1Sale() public payable {
        require(block.timestamp >= saleStart && block.timestamp < pre1Sale, "presale is not active");
        require(Pre1DepositBalance.add(msg.value) <= Pre1MaxCap, "deposit limits reached");
        require(depositsPre1[msg.sender].add(msg.value) >= Pre1MinDepositBNB && depositsPre1[msg.sender].add(msg.value) <= Pre1MaxDepositBNB, "incorrect amount");

        uint256 Pre1SalePrice;
        Pre1SalePrice =  0.0001 ether;  // 1 token / BNB price

        uint256 tokenAmount = msg.value.mul(1e18).div(Pre1SalePrice);
        //token.mint(msg.sender, tokenAmount);
        balanceMapPre1[msg.sender]=balanceMapPre1[msg.sender].add(tokenAmount);
        depositStatePre1[msg.sender]=true;
        Pre1DepositBalance = Pre1DepositBalance.add(msg.value);
        depositsPre1[msg.sender] = depositsPre1[msg.sender].add(msg.value);
        emit DepositedPre1(msg.sender, msg.value);
    }

    function releaseFundsPre1Sale() external onlyOwner {
        require(block.timestamp > pre1Sale || Pre1DepositBalance == Pre1MaxCap, "presale is active");
        presale.transfer(address(this).balance);
    }

    function withdrawPre1Sale()public{
        //require(depositState[msg.sender]==false || getPre1Timelock()<block.timestamp);
        require(depositStatePre1[msg.sender]);
        depositStatePre1[msg.sender]=false;
        token.mint(msg.sender, balanceMapPre1[msg.sender]);
    }

    function recoverBEP20Pre1Sale(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IBEP20(tokenAddress).transfer(this.owner(), tokenAmount);
        emit RecoveredPre1(tokenAddress, tokenAmount);
    }

    function getDepositAmountPre1Sale() public view returns (uint256) {
        return Pre1DepositBalance;
    }

    function getLeftTimeAmount() public view returns (uint256) {
        if(block.timestamp > pre1Sale) {
            return 0;
        } else {
            return (pre1Sale - block.timestamp);
        }
    }

    event DepositedPre1(address indexed user, uint256 amount);
    event RecoveredPre1(address token, uint256 amount);
}

/// @title Pre2Sale


interface Pre2 {
    function mint(address to, uint256 value) external;
}

contract Pre2SaleBEP20 is Ownable {
    using SafeMath for uint256;

    Pre2 public token;
    address payable public presale;

    uint256 public saleStart;
    uint256 public pre2Sale;

    uint256 public Pre2MinDepositBNB = 0.5 ether;
    uint256 public Pre2MaxDepositBNB = 10 ether;
    uint256 public Pre2MaxCap = 1875 ether;
    uint256 public Pre2DepositBalance;

    mapping(address => uint256) public depositsPre2;
    mapping(address => uint256) public balanceMapPre2;
    mapping(address => bool) public depositStatePre2;

    constructor(
        Pre2 _token
    ) {
        token = _token;
        //ahova kiküldje a befolyt $-t.
        presale = payable(0x053db14f91164556C2f97B8Bd4029194aAB336fE);
        /*
        presaleEndTimestamp = block.timestamp.add(5 days + 1 hours + 30 minutes);
        */

        // ide majd konkrét időbéllyegzők kerülnek, a teszt erejéig jó így...
        saleStart = block.timestamp.add(20 minutes);
        pre2Sale = block.timestamp.add(25 minutes);
    }

    receive() payable external {
        depositPre2Sale();
    }

    function depositPre2Sale() public payable {
        require(block.timestamp >= saleStart && block.timestamp < pre2Sale, "presale is not active");
        require(Pre2DepositBalance.add(msg.value) <= Pre2MaxCap, "deposit limits reached");
        require(depositsPre2[msg.sender].add(msg.value) >= Pre2MinDepositBNB && depositsPre2[msg.sender].add(msg.value) <= Pre2MaxDepositBNB, "incorrect amount");

        uint256 Pre2SalePrice;
        Pre2SalePrice =  0.000125 ether;  // 1 token / BNB price

        uint256 tokenAmount = msg.value.mul(1e18).div(Pre2SalePrice);
        //token.mint(msg.sender, tokenAmount);
        balanceMapPre2[msg.sender]=balanceMapPre2[msg.sender].add(tokenAmount);
        depositStatePre2[msg.sender]=true;
        Pre2DepositBalance = Pre2DepositBalance.add(msg.value);
        depositsPre2[msg.sender] = depositsPre2[msg.sender].add(msg.value);
        emit DepositedPre2(msg.sender, msg.value);
    }

    function releaseFundsPre2Sale() external onlyOwner {
        require(block.timestamp > pre2Sale || Pre2DepositBalance == Pre2MaxCap, "presale is active");
        presale.transfer(address(this).balance);
    }

    function withdrawPre2Sale()public{
        //require(depositState[msg.sender]==false || getPre2Timelock()<block.timestamp);
        require(depositStatePre2[msg.sender]);
        depositStatePre2[msg.sender]=false;
        token.mint(msg.sender, balanceMapPre2[msg.sender]);
    }

    function recoverBEP20Pre2Sale(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IBEP20(tokenAddress).transfer(this.owner(), tokenAmount);
        emit RecoveredPre2(tokenAddress, tokenAmount);
    }

    function getDepositAmountPre2Sale() public view returns (uint256) {
        return Pre2DepositBalance;
    }

    function getLeftTimeAmount() public view returns (uint256) {
        if(block.timestamp > pre2Sale) {
            return 0;
        } else {
            return (pre2Sale - block.timestamp);
        }
    }

    event DepositedPre2(address indexed user, uint256 amount);
    event RecoveredPre2(address token, uint256 amount);
}

/// @title Pre3Sale


interface Pre3 {
    function mint(address to, uint256 value) external;
}

contract Pre3SaleBEP20 is Ownable {
    using SafeMath for uint256;

    Pre3 public token;
    address payable public presale;

    uint256 public saleStart;
    uint256 public pre3Sale;

    uint256 public Pre3MinDepositBNB = 0.2 ether;
    uint256 public Pre3MaxDepositBNB = 2 ether;
    uint256 public Pre3MaxCap = 3000 ether;
    uint256 public Pre3DepositBalance;

    mapping(address => uint256) public depositsPre3;
    mapping(address => uint256) public balanceMapPre3;
    mapping(address => bool) public depositStatePre3;

    constructor(
        Pre3 _token
    ) {
        token = _token;
        //ahova kiküldje a befolyt $-t.
        presale = payable(0x053db14f91164556C2f97B8Bd4029194aAB336fE);
        /*
        presaleEndTimestamp = block.timestamp.add(5 days + 1 hours + 30 minutes);
        */

        // ide majd konkrét időbéllyegzők kerülnek, a teszt erejéig jó így...
        saleStart = block.timestamp.add(25 minutes);
        pre3Sale = block.timestamp.add(30 minutes);
    }

    receive() payable external {
        depositPre3Sale();
    }

    function depositPre3Sale() public payable {
        require(block.timestamp >= saleStart && block.timestamp < pre3Sale, "presale is not active");
        require(Pre3DepositBalance.add(msg.value) <= Pre3MaxCap, "deposit limits reached");
        require(depositsPre3[msg.sender].add(msg.value) >= Pre3MinDepositBNB && depositsPre3[msg.sender].add(msg.value) <= Pre3MaxDepositBNB, "incorrect amount");

        uint256 Pre3SalePrice;
        Pre3SalePrice =  0.00015 ether;  // 1 token / BNB price

        uint256 tokenAmount = msg.value.mul(1e18).div(Pre3SalePrice);
        //token.mint(msg.sender, tokenAmount);
        balanceMapPre3[msg.sender]=balanceMapPre3[msg.sender].add(tokenAmount);
        depositStatePre3[msg.sender]=true;
        Pre3DepositBalance = Pre3DepositBalance.add(msg.value);
        depositsPre3[msg.sender] = depositsPre3[msg.sender].add(msg.value);
        emit DepositedPre3(msg.sender, msg.value);
    }

    function releaseFundsPre3Sale() external onlyOwner {
        require(block.timestamp > pre3Sale || Pre3DepositBalance == Pre3MaxCap, "presale is active");
        presale.transfer(address(this).balance);
    }

    function withdrawPre3Sale()public{
        //require(depositState[msg.sender]==false || getPre3Timelock()<block.timestamp);
        require(depositStatePre3[msg.sender]);
        depositStatePre3[msg.sender]=false;
        token.mint(msg.sender, balanceMapPre3[msg.sender]);
    }

    function recoverBEP20Pre3Sale(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        IBEP20(tokenAddress).transfer(this.owner(), tokenAmount);
        emit RecoveredPre3(tokenAddress, tokenAmount);
    }

    function getDepositAmountPre3Sale() public view returns (uint256) {
        return Pre3DepositBalance;
    }

    function getLeftTimeAmount() public view returns (uint256) {
        if(block.timestamp > pre3Sale) {
            return 0;
        } else {
            return (pre3Sale - block.timestamp);
        }
    }

    event DepositedPre3(address indexed user, uint256 amount);
    event RecoveredPre3(address token, uint256 amount);
}