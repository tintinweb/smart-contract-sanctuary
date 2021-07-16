//SourceUnit: trx_plus.sol

pragma solidity >= 0.5.0;

contract TRX_PLUS{
  
  
	event Registration(string  member_name, string  sponcer_id,address indexed sender);
	event LevelUpgrade(string  member_name, string  current_level,string promoter,address indexed sender);
	event MatrixUpgrade(string  member_name, string  matrix,string  promoter,string payment_promoter,address indexed sender);
	
    using SafeMath for uint256;
    
     address public owner;
       constructor(address ownerAddress) public {
        owner = ownerAddress;  
    }
    
    function NewRegistration(string memory member_name, string memory sponcer_id,address payable[]  memory  _contributors, uint256[] memory _balances) public payable
	{
		uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
		emit Registration(member_name, sponcer_id,msg.sender);
	}

    function SendTRX(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }

    }
    
	function buyLevel(string memory member_name, string memory current_level,string memory promoter,address payable[]  memory  _contributors, uint256[] memory _balances) public payable
	{
		uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
		emit LevelUpgrade(member_name, current_level,promoter,msg.sender);
	}
	function buyMatrix(string memory member_name, string memory matrix,string memory promoter,string memory payment_promoter,address payable[]  memory  _contributors, uint256[] memory _balances) public payable
	{
		 uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
		emit MatrixUpgrade( member_name,  matrix, promoter,payment_promoter,msg.sender);
	
	}
	
 
    
  function withdrawLostTRXFromBalance(address payable _sender) public {
        require(msg.sender == owner, "onlyOwner");
        _sender.transfer(address(this).balance);
    }
	
}


/**     
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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