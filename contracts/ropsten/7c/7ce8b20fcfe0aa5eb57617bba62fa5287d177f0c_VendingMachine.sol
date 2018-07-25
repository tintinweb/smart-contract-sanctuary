pragma solidity 0.4.24;

/* 
   DIMENSION SRL 
   www.dimension.it
*/

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}
 
contract VendingMachine {
    address public owner;
    uint256 public price;
		
	modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    event releaseProduct(
        bool status,
        uint product
    );
	
    event updateBalance();
    
    constructor() public {
        owner= msg.sender;
        price=100000000000000000; 
    }
 
    function setPrice(uint256 newPrice) onlyOwner public {
        price=newPrice;
    }
 
    function pickupProduct(uint product) public payable returns (bool) {
        uint256 payment=msg.value;
        if (payment >= price ){
            uint256 cashBack=SafeMath.sub(payment,price);
            if (cashBack>0)
            {
                msg.sender.transfer(cashBack);
            }
            emit releaseProduct(true,product);
            return true;
        } else {
            return false;
        }
    }
    
    function takeMoney() public onlyOwner payable returns (bool) {
        uint balance = address(this).balance;
        owner.transfer(balance);
		emit updateBalance();
        return true;       
    }
	
    function ownerKill() public payable onlyOwner {
        selfdestruct(owner);
    }
}