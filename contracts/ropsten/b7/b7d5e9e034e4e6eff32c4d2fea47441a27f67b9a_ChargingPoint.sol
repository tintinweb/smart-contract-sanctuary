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
 
contract ChargingPoint {
	address public owner; 
	uint256 public priceForTime;
	string public pointIdentifier;
	
	modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    event enablePoint (
		string pointIdentifier,
		uint256 time
	);

	event updateBalance (string pointIdentifier);
	event updatePrice  (string pointIdentifier);
	
    constructor(string _pointIdentifier,uint256 _priceForTime)
    public
    {
		owner= msg.sender;
		priceForTime=_priceForTime; 
		pointIdentifier=_pointIdentifier;
	}
		
	function () 
	public payable 
	{
	    	uint256 payment=msg.value;
			if (priceForTime!=0)
			{
    			uint chargeTime=SafeMath.div(payment, priceForTime);
    			emit enablePoint(pointIdentifier,chargeTime);
			}
	}  
	
	function takeMoney() 
	public payable onlyOwner
	{
			uint balance = address(this).balance;
			owner.transfer(balance);
			emit updateBalance(pointIdentifier);
	}

	function setPrice(uint256 _priceForTime) 
	public onlyOwner
	{
			priceForTime=_priceForTime;
			emit updatePrice(pointIdentifier);
	} 
	
    function setPointIdentifier(string _pointIdentifier) 
	public onlyOwner
	{
			pointIdentifier=_pointIdentifier;
	} 

}