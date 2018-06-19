pragma solidity ^0.4.13;


contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

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
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
contract ICSTCrowSale is Ownable{
	using SafeMath for uint256;

	
	uint256 public totalFundingSupply;
	ERC20 public token;
	uint256 public startTime;
	uint256 public endTime;
	uint256 public airdropSupply;
	uint256 public rate;
	event Wasted(address to, uint256 value, uint256 date);
	function ICSTCrowSale(){
		rate = 0;
		startTime=0;
		endTime=0;
		airdropSupply = 0;
		totalFundingSupply = 0;
		token=ERC20(0xe6bc60a00b81c7f3cbc8f4ef3b0a6805b6851753);
	}

	function () payable external
	{
			require(now>startTime);
			require(now<=endTime);
			uint256 amount=0;
			processFunding(msg.sender,msg.value,rate);
			amount=msg.value.mul(rate);
			totalFundingSupply = totalFundingSupply.add(amount);
	}

    function withdrawCoinToOwner(uint256 _value) external
		onlyOwner
	{
		processFunding(msg.sender,_value,1);
	}
	//空投
    function airdrop(address [] _holders,uint256 paySize) external
    	onlyOwner 
	{
        uint256 count = _holders.length;
        assert(paySize.mul(count) <= token.balanceOf(this));
        for (uint256 i = 0; i < count; i++) {
			processFunding(_holders [i],paySize,1);
			airdropSupply = airdropSupply.add(paySize); 
        }
        Wasted(owner, airdropSupply, now);
    }
	function processFunding(address receiver,uint256 _value,uint256 _rate) internal
	{
		uint256 amount=_value.mul(_rate);
		require(amount<=token.balanceOf(this));
		if(!token.transfer(receiver,amount)){
			revert();
		}
	}

	
	function etherProceeds() external
		onlyOwner

	{
		if(!msg.sender.send(this.balance)) revert();
	}



	function init(uint256 _startTime,uint256 _endTime,uint _rate) external
		onlyOwner
	{
		startTime=_startTime;
		endTime=_endTime;
		rate=_rate;
	}

	function changeToken(address _tokenAddress) external
		onlyOwner
	{
		token = ERC20(_tokenAddress);
	}	
	  
}