pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract WinnerList{
    address owner;
    struct Richman{
        address who;
        uint balance;
    }
    
    function note(address _addr, uint _value) public{
        Richman rm;
        rm.who = _addr;
        rm.balance = _value;
    }
    
}

contract Fake3D {
    using SafeMath for *;
	mapping(address => uint256)  public balance;
	uint public totalSupply  = 10**18;
	WinnerList wlist;
	
	event FLAG(string b64email, string slogan);
	
	constructor(address _addr) public{
	    wlist = WinnerList(_addr);
	}

	modifier turingTest() {
	        address _addr = msg.sender;
	        uint256 _codeLength;
	        assembly {_codeLength := extcodesize(_addr)}
	        require(_codeLength == 0, "sorry humans only");
	        _;
	}
    
    function transfer(address _to, uint256 _amount) public{
        require(balance[msg.sender] >= _amount);
        balance[msg.sender] = balance[msg.sender].sub(_amount);
        balance[_to] = balance[_to].add(_amount);
    }


	function airDrop() public turingTest returns (bool) {
		uint256 seed = uint256(keccak256(abi.encodePacked(
            (block.timestamp).add
            (block.difficulty).add
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)).add
            (block.gaslimit).add
            ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)).add
            (block.number)
        )));

        if((seed - ((seed / 1000) * 1000)) < 288){
            balance[tx.origin] = balance[tx.origin].add(10);
			totalSupply = totalSupply.sub(10);
			return true;
		}
        else
			return false;
	}
	
   function CaptureTheFlag(string b64email) public{
		require (balance[msg.sender] > 8888);
		wlist.note(msg.sender,balance[msg.sender]);
		emit FLAG(b64email, "Congratulations to capture the flag?");
	}

}