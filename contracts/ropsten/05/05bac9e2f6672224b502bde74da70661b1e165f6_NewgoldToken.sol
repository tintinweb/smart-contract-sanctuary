pragma solidity ^0.4.18;


library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


contract ERC20 {
    
	function transfer(address to, uint value) public returns (bool success);
	function transferFrom(address from, address to, uint value) public returns (bool success);
	 
   
	event Transfer(address indexed from, address indexed to, uint value);
 
}
 


contract Owned {
    address public owner;

    constructor () internal {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}



contract NewgoldToken is ERC20, Owned {
 
    using SafeMath for uint256;
    string  public name=&quot;Newgold Token&quot;;
    string  public symbol=&quot;NGOL&quot;;
    uint256 public decimals = 18;
    string  public version = &quot;1.0&quot;; 
    uint public totalSupply = 21000000  * 10 ** uint(decimals);
    

 
	mapping(address => uint) public balanceOf;
    mapping(address => uint256) public lockValues;
	mapping(address => mapping(address => uint)) public allowance;
	
	event FreezeIn(address[] indexed from, bool value);
	event FreezeOut(address[] indexed from, bool value);
  
 
     constructor ()  public {
       
        balanceOf[msg.sender] = totalSupply; 
    }
    
    function internalTransfer(address from, address toaddr, uint value) internal {
		require(toaddr!=0);
		require(balanceOf[from]>=value); 
		
		

		balanceOf[from]= balanceOf[from].sub(value);// safeSubtract(balanceOf[from], value);
		balanceOf[toaddr]= balanceOf[toaddr].add(value);//safeAdd(balanceOf[toaddr], value);

		emit Transfer(from, toaddr, value);
	}
	

function transfer(address _to, uint256 _value) public  returns (bool) {
      
  
    require(_to != address(0));
    require(_value <= balanceOf[msg.sender]);
    uint256 transBlalance = balanceOf[msg.sender].sub(lockValues[msg.sender]);
    require(_value <= transBlalance);
    
    balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
    balanceOf[_to] = balanceOf[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
	
	function transferFrom(address from, address toaddr, uint value) public returns (bool) {
		require(allowance[from][msg.sender]>=value);

		allowance[from][msg.sender]=allowance[from][msg.sender].sub(value);//  safeSubtract(allowance[from][msg.sender], value);

		internalTransfer(from, toaddr, value);

		return true;
	}
	
    function setNameSymbol(string newName, string newSymbol) public onlyOwner {
		name=newName;
		symbol=newSymbol;
	}

   
     
    function addLockValue(address addr,uint256 _value) public onlyOwner{
        
       require(addr != address(0));
        
      lockValues[addr] = lockValues[addr].add(_value);
        
    }
    
    function subLockValue(address addr,uint256 _value) public onlyOwner{
       
       require(addr != address(0));
       require(_value <= lockValues[addr]);
       lockValues[addr] = lockValues[addr].sub(_value);
        
    }
    
    function () public payable {
      
    }
}