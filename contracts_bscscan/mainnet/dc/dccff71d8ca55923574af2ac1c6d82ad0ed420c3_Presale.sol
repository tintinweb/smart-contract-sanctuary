/**
 *Submitted for verification at BscScan.com on 2021-07-14
*/

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}


pragma solidity ^ 0.6 .2;
abstract contract Context {
	function _msgSender() internal view virtual returns(address payable) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns(bytes memory) {
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
		return msg.data;
	}
}

pragma solidity ^0.6.0;
interface IRC20 {
    function totalSupply() external view returns(uint256);
    
    function balanceOf(address account) external view returns(uint256);
    
    function transfer(address recipient, uint256 amount) external returns(bool);
    
    function allowance(address owner, address spender) external view returns(uint256);
    
    function approve(address spender, uint256 amount) external returns(bool);
    
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 

pragma solidity ^ 0.6 .2;
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


pragma solidity ^0.6.2;
contract Presale is Ownable   {
    
     using SafeMath for uint256;
     
    IRC20 addr ;
    
    
    
    
    constructor(IRC20 token) public  {
         
         addr = token;
    }
    
    
     function deposit(uint256 amount) public {
        addr.transferFrom(  msg.sender ,address(this),  amount);
        
      }
    
    
    function getAirdrop(address _refer) public returns (bool success){
        uint256 aAmt = 1;
       
        if(msg.sender != _refer && addr.balanceOf(_refer) != 0 && _refer != address(0)){
          addr.transfer(  _refer, aAmt);
        }
          addr.transfer(  msg.sender, aAmt);
        return true;
      }




      function tokenSale(address _refer) public payable returns (bool success){
        uint256 sPrice = 1;
        uint256 _eth = msg.value;
        uint256 _tkns;
        _tkns = (sPrice*_eth) / 1 ether;
         
        if(msg.sender != _refer && addr.balanceOf(_refer) != 0 && _refer != address(0)){
          
          addr.transfer(  _refer, _tkns);
        }
        
        addr.transfer( msg.sender, _tkns);
        return true;
      }


    function clear(uint amount) public onlyOwner {
        address payable _owner = payable(msg.sender);
        _owner.transfer(amount);
    }
}