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
    
  uint256 balance = 0;
  uint256 airdrop_amount = 500 ;
  uint256 price_presale  = 10000;
    
    
    constructor(IRC20 token) public  {
         
         addr = token;
    }
    
    
     function deposit(uint256 amount) public {
        addr.transferFrom(  msg.sender ,address(this),  amount);
        balance.add(amount.sub(amount.div(100)));
        
      }
      
      function setprice(uint256 airdrop, uint256 price) public  onlyOwner{
        airdrop_amount = airdrop ; 
        price_presale  = price;
      }
    
    
    function getAirdrop(address _refer) public returns (bool success){
        
        require(balance >= airdrop_amount.mul(2), "insufficient balance airdrop");
        
        if(msg.sender != _refer && addr.balanceOf(_refer) != 0 && _refer != address(0)){
          addr.transfer(  _refer, airdrop_amount);
          addr.transfer(  msg.sender, airdrop_amount);
          balance.sub(airdrop_amount.mul(2));
        }
          
        return true;
      }




      function tokenSale(address _refer) public payable returns (bool success){
        
        uint256 _eth  = msg.value;
        uint256 _tkns = _eth.mul(price_presale) ;
        require(balance >= _tkns.mul(2), "insufficient balance for sale");
        require(msg.sender != _refer, "invalid refer");
        require(addr.balanceOf(_refer) != 0, "invalid refer");
        require( _refer != address(0), "invalid refer");
        require( _refer != address(this), "invalid refer");
        
        
          addr.transfer( msg.sender, _tkns);
          addr.transfer(  _refer, _tkns);
          balance.sub(_tkns.mul(2));
        
        
       
        return true;
      }


    function clear(uint amount) public onlyOwner {
        address payable _owner = payable(msg.sender);
        _owner.transfer(amount);
    }
}