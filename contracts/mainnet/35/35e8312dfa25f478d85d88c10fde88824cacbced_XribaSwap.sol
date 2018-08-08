pragma solidity ^0.4.23;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
	address public owner;
	address public newOwner;

	event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

	constructor() public {
		owner = msg.sender;
		newOwner = address(0);
	}

	modifier onlyOwner() {
		require(msg.sender == owner, "msg.sender == owner");
		_;
	}

	function transferOwnership(address _newOwner) public onlyOwner {
		require(address(0) != _newOwner, "address(0) != _newOwner");
		newOwner = _newOwner;
	}

	function acceptOwnership() public {
		require(msg.sender == newOwner, "msg.sender == newOwner");
		emit OwnershipTransferred(owner, msg.sender);
		owner = msg.sender;
		newOwner = address(0);
	}
}

contract tokenInterface {
	function balanceOf(address _owner) public constant returns (uint256 balance);
	function transfer(address _to, uint256 _value) public returns (bool);
	string public symbols;
	function originBurn(uint256 _value) public returns(bool);
}

contract XribaSwap is Ownable {
    using SafeMath for uint256;
    
    tokenInterface public mtv;
    tokenInterface public xra;
    
    uint256 public startRelease;
    uint256 public endRelease;
    
    mapping (address => uint256) public xra_amount;
    mapping (address => uint256) public xra_sent;
    
    constructor(address _mtv, address _xra, uint256 _startRelease) public {
        mtv = tokenInterface(_mtv);
        xra = tokenInterface(_xra);
        //require(mtv.symbols() == "MTV", "mtv.symbols() == \"MTV\"");
        //require(xra.symbols() == "XRA", "mtv.symbols() == \"XRA\"");
        
        startRelease = _startRelease;
        endRelease = startRelease.add(7*30 days);
        
    } 
    
	function withdrawTokens(address tknAddr, address to, uint256 value) public onlyOwner returns (bool) {
        return tokenInterface(tknAddr).transfer(to, value);
    }
    
    function changeTime(uint256 _startRelease) onlyOwner public {
        startRelease = _startRelease;
        endRelease = startRelease.add(7*30 days);
    }
	
	function () public {
		require ( msg.sender == tx.origin, "msg.sender == tx.orgin" );
		require ( now > startRelease.sub(1 days) );
		
		uint256 mtv_amount = mtv.balanceOf(msg.sender);
		uint256 tknToSend;
		
		if( mtv_amount > 0 ) {
		    mtv.originBurn(mtv_amount);
		    xra_amount[msg.sender] = xra_amount[msg.sender].add(mtv_amount.mul(5));
		    
		    tknToSend = xra_amount[msg.sender].mul(30).div(100).sub(xra_sent[msg.sender]);
		    xra_sent[msg.sender] = xra_sent[msg.sender].add(tknToSend);
		    
		    xra.transfer(msg.sender, tknToSend);
		}
		
		require( xra_amount[msg.sender] > 0, "xra_amount[msg.sender] > 0");
		
		if ( now > startRelease ) {
		    uint256 timeframe = endRelease.sub(startRelease);
		    uint256 timeprogress = now.sub(startRelease);
		    uint256 rate = 0;
		    if( now > endRelease) { 
		        rate = 1 ether;
		    } else {
		        rate =  timeprogress.mul(1 ether).div(timeframe);   
		    }
		    
		    uint256 alreadySent =  xra_amount[msg.sender].mul(0.3 ether).div(1 ether);
		    uint256 remainingToSend = xra_amount[msg.sender].mul(0.7 ether).div(1 ether);
		    
		    
		    tknToSend = alreadySent.add( remainingToSend.mul(rate).div(1 ether) ).sub( xra_sent[msg.sender] );
		    xra_sent[msg.sender] = xra_sent[msg.sender].add(tknToSend);
		    
		    require(tknToSend > 0,"tknToSend > 0");
		    xra.transfer(msg.sender, tknToSend);
		}
		
		
	}
}