/**
 *Submitted for verification at polygonscan.com on 2022-01-13
*/

pragma solidity ^ 0.6 .2;
interface IERC20 {
	function totalSupply() external view returns(uint256);
	function balanceOf(address account) external view returns(uint256);
	function transfer(address recipient, uint256 amount) external returns(bool);
	function allowance(address owner, address spender) external view returns(uint256);
	function approve(address spender, uint256 amount) external returns(bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
library SafeMath {
	function add(uint256 a, uint256 b) internal pure returns(uint256) {
		uint256 c = a + b;
		require(c >= a, "SafeMath: addition overflow");
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns(uint256) {
		return sub(a, b, "SafeMath: subtraction overflow");
	}

	function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
		require(b <= a, errorMessage);
		uint256 c = a - b;
		return c;
	}

	function mul(uint256 a, uint256 b) internal pure returns(uint256) {
		// benefit is lost if 'b' is also tested.
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		require(c / a == b, "SafeMath: multiplication overflow");
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns(uint256) {
		return div(a, b, "SafeMath: division by zero");
	}

	function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
		require(b > 0, errorMessage);
		uint256 c = a / b;
		return c;
	}

	function mod(uint256 a, uint256 b) internal pure returns(uint256) {
		return mod(a, b, "SafeMath: modulo by zero");
	}

	function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns(uint256) {
		require(b != 0, errorMessage);
		return a % b;
	}
}

abstract contract Context {
	function _msgSender() internal view virtual returns(address payable) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns(bytes memory) {
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
		return msg.data;
	}
}


contract Ownable is Context {
	address private _owner;
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	constructor() internal {
		address msgSender = _msgSender();
		_owner = msgSender;
		emit OwnershipTransferred(address(0), msgSender);
	}

	function owner() public view returns(address) {
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

  

pragma solidity ^ 0.6 .2;
contract BRIDGE is Ownable {
    using SafeMath
	for uint256;
    
    struct isi {
        address addr;
        uint256 ammn;
    }

    address KIND = 0xbd4373FB8954A0aF1f6fD55d92Ad2E22ADc328Ab;
     isi[] public list; 
     mapping(uint256 => address) public addr;
     mapping(uint256 => uint256) public amount;
    uint256 proceslength = 0;
     constructor()  
     public
    {  
    }

    function listlength() public view returns(uint256){
        return list.length;
    }
      function processlength() public view returns(uint256){
        return proceslength;
    }

     function swap(uint256 _amount) public  {
        IERC20(KIND).transferFrom(address(msg.sender),address(this),_amount);
        list.push(isi({addr:address(msg.sender),ammn:_amount}));
    }

      function deposit(uint256 _amount) public onlyOwner {
        IERC20(KIND).transferFrom(address(msg.sender),address(this),_amount); 
    }

      function withdraw(uint256 _amount) public onlyOwner {
        IERC20(KIND).transfer(address(msg.sender),_amount); 
    }
 
    function proses(uint256 _id,address _addr, uint256 _amount) public onlyOwner {
        if(IERC20(KIND).balanceOf(address(this))>=_amount){} else return;
        if(amount[_id] > 0) return;
        if(addr[_id] != address(0)) return;
        addr[_id] = _addr;
        amount[_id] = _amount;
        IERC20(KIND).transfer(_addr,_amount);
        proceslength++;
    }

    function cek(uint256 id,uint256 _amount) public view returns(bool) {
        if(IERC20(KIND).balanceOf(address(this))>=_amount){} else return false;
        if(amount[id] > 0) return false;
        if(addr[id] != address(0)) return false;
       return true;
    }
  
     
     

    }