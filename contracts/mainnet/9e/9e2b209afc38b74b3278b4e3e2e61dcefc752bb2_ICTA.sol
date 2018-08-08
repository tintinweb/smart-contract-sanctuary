pragma solidity ^0.4.13;

/*

  Copyright 2018 AICT Foundation.
  https://www.aict.io/

*/

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

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

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
    uint256 c = a / b;
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

contract ICTA is ERC20,Ownable{
	using SafeMath for uint256;
	string public constant name="ICTA";
	string public constant symbol="ICTA";
	string public constant version = "0";
	uint256 public constant decimals = 9;
	uint256 public constant MAX_SUPPLY=500000000*10**decimals;
	uint256 public airdropSupply;
    struct epoch  {
        uint256 lockEndTime;
        uint256 lockAmount;
    }

    mapping(address=>epoch[]) public lockEpochsMap;
    mapping(address => uint256) balances;
	mapping (address => mapping (address => uint256)) allowed;
	

	function ICTA()public{
		totalSupply = 500000000 ;
		airdropSupply = 0;
		totalSupply=MAX_SUPPLY;
		balances[msg.sender] = MAX_SUPPLY;
		Transfer(0x0, msg.sender, MAX_SUPPLY);
	}


	modifier notReachTotalSupply(uint256 _value,uint256 _rate){
		assert(MAX_SUPPLY>=totalSupply.add(_value.mul(_rate)));
		_;
	}

  	function transfer(address _to, uint256 _value) public  returns (bool)
 	{
		require(_to != address(0));

		epoch[] storage epochs = lockEpochsMap[msg.sender];
		uint256 needLockBalance = 0;
		for(uint256 i = 0;i<epochs.length;i++)
		{
			if( now < epochs[i].lockEndTime )
			{
				needLockBalance=needLockBalance.add(epochs[i].lockAmount);
			}
		}

		require(balances[msg.sender].sub(_value)>=needLockBalance);
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		Transfer(msg.sender, _to, _value);
		return true;
  	}

  	function balanceOf(address _owner) public constant returns (uint256 balance) 
  	{
		return balances[_owner];
  	}

  	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) 
  	{
		require(_to != address(0));

		epoch[] storage epochs = lockEpochsMap[_from];
		uint256 needLockBalance = 0;
		for(uint256 i = 0;i<epochs.length;i++)
		{

			if( now < epochs[i].lockEndTime )
			{
				needLockBalance = needLockBalance.add(epochs[i].lockAmount);
			}
		}

		require(balances[_from].sub(_value)>=needLockBalance);

		uint256 _allowance = allowed[_from][msg.sender];

		balances[_from] = balances[_from].sub(_value);
		balances[_to] = balances[_to].add(_value);
		allowed[_from][msg.sender] = _allowance.sub(_value);
		Transfer(_from, _to, _value);
		return true;
  	}

  	function approve(address _spender, uint256 _value) public returns (bool) 
  	{
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;
  	}

  	function allowance(address _owner, address _spender) public constant returns (uint256 remaining) 
  	{
		return allowed[_owner][_spender];
  	}

	function lockBalance(address user, uint256 lockAmount,uint256 lockEndTime) internal
	{
		 epoch[] storage epochs = lockEpochsMap[user];
		 epochs.push(epoch(lockEndTime,lockAmount));
	}

    function airdrop(address [] _holders,uint256 paySize) external
    	onlyOwner 
	{
		uint256 unfreezeAmount=paySize.div(5);
        uint256 count = _holders.length;
        assert(paySize.mul(count) <= balanceOf(msg.sender));
        for (uint256 i = 0; i < count; i++) {
            transfer(_holders [i], paySize);

            lockBalance(_holders [i],unfreezeAmount,now+10368000);

            lockBalance(_holders [i],unfreezeAmount,now+10368000+2592000);

            lockBalance(_holders [i],unfreezeAmount,now+10368000+2592000+2592000);

            lockBalance(_holders [i],unfreezeAmount,now+10368000+2592000+2592000+2592000);

            lockBalance(_holders [i],unfreezeAmount,now+10368000+2592000+2592000+2592000+2592000);
            
			airdropSupply = airdropSupply.add(paySize);
        }
    }

    function airdrop2(address [] _holders,uint256 paySize) external
    	onlyOwner 
	{
		uint256 unfreezeAmount=paySize.div(10);
        uint256 count = _holders.length;
        assert(paySize.mul(count) <= balanceOf(msg.sender));
        for (uint256 i = 0; i < count; i++) {
            transfer(_holders [i], paySize);

            lockBalance(_holders [i],unfreezeAmount,now+5184000);

            lockBalance(_holders [i],unfreezeAmount,now+5184000+2592000);

            lockBalance(_holders [i],unfreezeAmount,now+5184000+2592000+2592000);

            lockBalance(_holders [i],unfreezeAmount,now+5184000+2592000+2592000+2592000);

            lockBalance(_holders [i],unfreezeAmount,now+5184000+2592000+2592000+2592000+2592000);

            lockBalance(_holders [i],unfreezeAmount,now+5184000+2592000+2592000+2592000+2592000+2592000);

            lockBalance(_holders [i],unfreezeAmount,now+5184000+2592000+2592000+2592000+2592000+2592000+2592000);

            lockBalance(_holders [i],unfreezeAmount,now+5184000+2592000+2592000+2592000+2592000+2592000+2592000+2592000);

            lockBalance(_holders [i],unfreezeAmount,now+5184000+2592000+2592000+2592000+2592000+2592000+2592000+2592000+2592000);

            lockBalance(_holders [i],unfreezeAmount,now+5184000+2592000+2592000+2592000+2592000+2592000+2592000+2592000+2592000+2592000);
            
			airdropSupply = airdropSupply.add(paySize);
        }
    }    

    function burn(uint256 _value) public {
        require(_value > 0);

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
    }
	
}