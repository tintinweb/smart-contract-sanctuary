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
contract AgentWallet is Ownable{
	using SafeMath for uint256;

	
	uint256 public totalFundingSupply;
	ERC20 public token;
	string public walletName;
	uint256 public startTime;
	uint256 public endTime;
	uint256 public rate;
	function AgentWallet(){
		rate = 0;
		startTime=0;
		endTime=0;
		totalFundingSupply = 0;
		walletName="init";
		token=ERC20(0xb53ac311087965d9e085515efbe1380b2ca4de9a);
	}

	//funding, eth in
	function () payable external
	{
			require(now>startTime);
			require(now<=endTime);
			processFunding(msg.sender,msg.value,rate);
			uint256 amount=msg.value.mul(rate);
			totalFundingSupply = totalFundingSupply.add(amount);
	}

	//coin out
    function withdrawCoinToOwner(uint256 _value) external
		onlyOwner
	{
		processFunding(msg.sender,_value,1);
	}


	function processFunding(address receiver,uint256 _value,uint256 _rate) internal
	{
		uint256 amount=_value.mul(_rate);
		require(amount<=token.balanceOf(this));
		if(!token.transfer(receiver,amount)){
			revert();
		}
	}

	//eth out
	function etherProceeds() external
		onlyOwner

	{
		if(!msg.sender.send(this.balance)) revert();
	}



	function init(string _walletName,uint256 _startTime,uint256 _endTime,uint _rate) external
		onlyOwner
	{
		walletName=_walletName;
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