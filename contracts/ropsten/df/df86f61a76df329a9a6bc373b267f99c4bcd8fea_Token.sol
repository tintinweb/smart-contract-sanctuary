pragma solidity ^0.4.18;


library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


// ERC20 
contract ERC20 {
    
	function transfer(address to, uint value) public returns (bool success);
	function transferFrom(address from, address to, uint value) public returns (bool success);
	 
   
	event Transfer(address indexed from, address indexed to, uint value);
 
}
 


// contract owned
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



//ArtZoneToken
contract Token is ERC20, Owned {
 
    using SafeMath for uint256;
    //metadata
    string  public name=&quot;FXF02&quot;;
    string  public symbol=&quot;FXF02&quot;;
    uint256 public decimals = 18;
    string  public version = &quot;1.0&quot;; 
    uint public totalSupply = 1000000000  * 10 ** uint(decimals);
    
	mapping(address=>bool) public freezeIn;
	mapping(address=>bool) public freezeOut;
 
	mapping(address => uint) public balanceOf;
    mapping(address => uint256) balances;
	mapping(address => mapping(address => uint)) public allowance;
	
	//event     
	event FreezeIn(address[] indexed from, bool value);
	event FreezeOut(address[] indexed from, bool value);
  
 
    //constructor
     constructor ()  public {
       
        balanceOf[msg.sender] = totalSupply; 
    }
    
    function internalTransfer(address from, address toaddr, uint value) internal {
		require(toaddr!=0);
		require(balanceOf[from]>=value); 
		
		require(!freezeIn[toaddr]);
		require(!freezeOut[from]);

		balanceOf[from]= balanceOf[from].sub(value);// safeSubtract(balanceOf[from], value);
		balanceOf[toaddr]= balanceOf[toaddr].add(value);//safeAdd(balanceOf[toaddr], value);

		//emit Transfer(from, toaddr, value);
	}
	
	//transfer to 
// 	function transfer(address toaddr, uint value) public returns (bool) {
// 		internalTransfer(msg.sender, toaddr, value);
// 		return true;
// 	}

function transfer(address _to, uint256 _value) public  returns (bool) {
      
  
    require(_to != address(0));
    require(_value <= balanceOf[msg.sender]);
    // SafeMath.sub will throw if there is not enough balance.
    balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
    balanceOf[_to] = balanceOf[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
	
	//transfer from
	function transferFrom(address from, address toaddr, uint value) public returns (bool) {
		require(allowance[from][msg.sender]>=value);

		allowance[from][msg.sender]=allowance[from][msg.sender].sub(value);//  safeSubtract(allowance[from][msg.sender], value);

		internalTransfer(from, toaddr, value);

		return true;
	}
	
    // reset name and symbol
    function setNameSymbol(string newName, string newSymbol) public onlyOwner {
		name=newName;
		symbol=newSymbol;
	}

    //Freeze In token
	function setFreezeIn(address[] addrs, bool value) public onlyOwner {
		for (uint i=0; i<addrs.length; i++) {
			freezeIn[addrs[i]]=value;
		}
	    //emit FreezeIn(addrs, value);
	}
	
    //Freeze Out token
	function setFreezeOut(address[] addrs, bool value) public onlyOwner {
		for (uint i=0; i<addrs.length; i++) {
			freezeOut[addrs[i]]=value;
		}
	//	emit FreezeOut(addrs, value);
	}
     
    
    
    // buy token
    function () public payable {
      
    }
}