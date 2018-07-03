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

// Continuous backing with ELIX

contract continuousBacking	{

// For events, creator and claimee are stored in the events themselves.
event CreatedReward(uint256 index,uint256 numAvailable);
event ClaimedReward(uint256 index,uint256 totalAmount,uint256 numUnitsDesired,uint256 hostCut,uint256 creatorCut,address backer);
event ModifiedNumAvailable(uint256 index,uint256 newNumAvailable);

address public ELIX_ADDRESS;
uint256 public MAX_HOST_PERCENT;
uint256 public HOST_CUT;
uint256 public MAX_NUM_AVAIL;

struct Reward 	{
    string title;
	address host;
	address creator;
	uint256 numTaken;
	uint256 numAvailable;
	uint256 spmPreventionAmt;
}

function continuousBacking() {
    MAX_HOST_PERCENT=100000000000000000000;
    HOST_CUT=5000000000000000000;
    ELIX_ADDRESS=0xc8C6A31A4A806d3710A7B38b7B296D2fABCCDBA8; 
    MAX_NUM_AVAIL=10000000;
}

Reward[] public rewards;

function defineReward(string title,address creator,uint256 numAvailable,uint256 minBacking) public	{
    address host=msg.sender;
    if (numAvailable>MAX_NUM_AVAIL) revert();
	Reward memory newReward=Reward(title,host,creator,0,numAvailable,minBacking);
	rewards.push(newReward);
	emit CreatedReward(rewards.length-1,numAvailable);
}

function backAtIndex(uint256 index,uint256 totalAmount,uint256 numUnitsDesired) public	{
        if (msg.sender==rewards[index].host || msg.sender==rewards[index].creator) revert();
        if (totalAmount<rewards[index].spmPreventionAmt) revert();
        if (totalAmount==0) revert();
        if (rewards[index].numTaken==rewards[index].numAvailable) revert();
        rewards[index].numTaken+=1;
        uint256 hostCut;
	    uint256 creatorCut;
        (hostCut, creatorCut) = returnHostAndCreatorCut(totalAmount);
        
        if (!token(ELIX_ADDRESS).transferFrom(msg.sender,rewards[index].host,hostCut)) revert(); 
        if (!token(ELIX_ADDRESS).transferFrom(msg.sender,rewards[index].creator,creatorCut)) revert(); 
        
        emit ClaimedReward(index,totalAmount,numUnitsDesired,hostCut,creatorCut,msg.sender);
}

function reviseNumAvailable(uint256 index,uint256 newNumAvailable) public	{
	if (newNumAvailable>MAX_NUM_AVAIL) revert();
	if (newNumAvailable<rewards[index].numTaken) revert();
	if (msg.sender==rewards[index].creator || msg.sender==rewards[index].host)	{
		rewards[index].numAvailable=newNumAvailable;
		emit ModifiedNumAvailable(index,newNumAvailable);
	}
}

function returnHostAndCreatorCut(uint256 totalAmount) private returns(uint256, uint256)	{
	uint256 hostCut = SafeMath.div( SafeMath.mul(totalAmount, HOST_CUT), MAX_HOST_PERCENT);
	uint256 creatorCut = SafeMath.sub(totalAmount, hostCut );
	return ( hostCut, creatorCut );
}

}

contract token	{
	function transferFrom(address _from,address _to,uint256 _amount) returns (bool success);
}