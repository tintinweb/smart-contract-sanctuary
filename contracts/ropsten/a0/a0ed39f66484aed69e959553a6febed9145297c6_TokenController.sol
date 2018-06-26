pragma solidity ^0.4.24;

// LeeSungCoin Made By PinkCherry - insanityskan@gmail.com
// LeeSungCoin Request Question - koreacoinsolution@gmail.com

library SafeMath
{
  	function mul(uint256 a, uint256 b) internal pure returns (uint256)
    {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);

		return c;
  	}

  	function div(uint256 a, uint256 b) internal pure returns (uint256)
	{
		uint256 c = a / b;

		return c;
  	}

  	function sub(uint256 a, uint256 b) internal pure returns (uint256)
	{
		assert(b <= a);

		return a - b;
  	}

  	function add(uint256 a, uint256 b) internal pure returns (uint256)
	{
		uint256 c = a + b;
		assert(c >= a);

		return c;
  	}
}


contract OwnerHelper
{
  	address public owner;

  	event OwnerTransferPropose(address indexed _from, address indexed _to);

  	modifier onlyOwner
	{
		require(msg.sender == owner);
		_;
  	}

  	constructor() public
	{
		owner = msg.sender;
  	}

  	function transferOwnership(address _to) onlyOwner public
	{
        require(_to != owner);
    	require(_to != address(0x0));
    	owner = _to;
    	emit OwnerTransferPropose(owner, _to);
  	}

}

contract Token {
    bytes32 public standard;
    bytes32 public name;
    bytes32 public symbol;
    uint256 public totalSupply;
    uint8 public decimals;
    bool public allowTransactions; 
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    function transfer(address _to, uint256 _value) public returns (bool success);
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}

contract TokenController is OwnerHelper
{
    using SafeMath for uint;
    
    // add by John
    struct poolInfo 
    {
        address contractAddr;
        address ownerWallet;
        uint cap;
        uint total;
        uint max;
        uint min;
        uint maxInvestPerPerson;
        uint fee;
        uint tokenPerEth;
        uint recvToken;
        address[] poolMembers;
    }
    mapping (uint => poolInfo) internal poolInfoData;                       
    mapping (address => mapping (address => uint)) internal poolNumbers;    // _poolOwner, _contract, _poolNum 
    mapping (uint => mapping (address => uint)) internal poolInvestData;    // _poolNum, _investor, _value
    mapping (address => uint) internal depositEth;                          // personal deposit data
    
    uint public poolNumber;
    uint public E18 = 10 ** 18;
    uint public safeShareFee = 5;

    constructor() public
    {
        poolNumber = 0;
    }
    
    function () payable public  
    {
        depositEth[msg.sender] = depositEth[msg.sender].add(msg.value);
    }
    
    function createPool(address _contract, uint _cap, uint _min, uint _max, uint _maxInvestPerPerson, uint _fee, uint _tokenPerEth) public
    {
        require(poolInfoData[poolNumber].cap == 0);
        
        poolInfoData[poolNumber].contractAddr = _contract;
        poolInfoData[poolNumber].ownerWallet = msg.sender;
        poolInfoData[poolNumber].cap = _cap * E18;
        poolInfoData[poolNumber].total = 0;
        poolInfoData[poolNumber].min = _min * E18;
        poolInfoData[poolNumber].max = _max * E18;
        poolInfoData[poolNumber].maxInvestPerPerson = _maxInvestPerPerson * E18;
        poolInfoData[poolNumber].fee = _fee;
        poolInfoData[poolNumber].tokenPerEth = _tokenPerEth;
        
        poolNumbers[msg.sender][_contract] = poolNumber;
        poolNumber = poolNumber + 1;
    }
    
    function joinToPool(uint _poolNum, uint _value) public
    {
        require(poolInfoData[_poolNum].cap >= poolInfoData[_poolNum].total.add(_value));
        require(poolInfoData[_poolNum].min <= _value && poolInfoData[_poolNum].max >= _value);
        require(poolInfoData[_poolNum].maxInvestPerPerson >= poolInvestData[_poolNum][msg.sender].add(_value));
        require(depositEth[msg.sender] >= _value);

        uint value = _value.mul(E18);
        poolInfoData[_poolNum].poolMembers.push(msg.sender);
        depositEth[msg.sender] = depositEth[msg.sender].sub(value);
        poolInvestData[_poolNum][msg.sender] = poolInvestData[_poolNum][msg.sender].add(value);
        poolInfoData[_poolNum].total = poolInfoData[_poolNum].total.add(value);
    }
    
    function receiveTokenFromContract(uint _poolNum) public
    {
        require(poolInfoData[_poolNum].ownerWallet == msg.sender);
        
        // payment of fee
        uint contractFee = poolInfoData[_poolNum].total.div(1000).mul(safeShareFee);
        uint poolOwnerFee = poolInfoData[_poolNum].total.div(1000).mul(poolInfoData[_poolNum].fee);
        poolInfoData[_poolNum].total = poolInfoData[_poolNum].total.sub(contractFee + poolOwnerFee);
        poolInfoData[_poolNum].ownerWallet.transfer(poolOwnerFee);
        owner.transfer(contractFee);
        
         // transfer Eth To Contract
        poolInfoData[_poolNum].contractAddr.transfer(poolInfoData[_poolNum].total);
        poolInfoData[_poolNum].recvToken = poolInfoData[_poolNum].total.mul(poolInfoData[_poolNum].tokenPerEth);
    }
    
    function multipleTokenDistribute(uint _poolNum) public
    {
        require(poolInfoData[_poolNum].ownerWallet == msg.sender);
        
        uint token;
        
        for(uint i = 0; i < poolInfoData[_poolNum].poolMembers.length ; i++)
        {
            token = poolInfoData[_poolNum].recvToken.mul(poolInvestData[_poolNum][poolInfoData[_poolNum].poolMembers[i]]).div(poolInfoData[_poolNum].total);
            Token(poolInfoData[_poolNum].contractAddr).transfer(poolInfoData[_poolNum].poolMembers[i], token);
        }
    }
    
    function showPoolNumber(address _poolOwner, address _contract) public view returns (uint)
    {
        return poolNumbers[_poolOwner][_contract];
    }
    
    function showPoolMembers(uint _poolNum) public view returns (address[])
    {
        return poolInfoData[_poolNum].poolMembers;
    }
    
    function showInvestEther(address _investor ,uint _poolNum) public view returns (uint)
    {
        return poolInvestData[_poolNum][_investor];
    }
    
    function showDepositEther(address _who) public view returns (uint)
    {
        return depositEth[_who];
    }
    
    function showPoolOwner(uint _poolNum) public view returns (address)
    {
        return poolInfoData[_poolNum].ownerWallet;
    }
    
    function showPoolContract(uint _poolNum) public view returns (address)
    {
        return poolInfoData[_poolNum].contractAddr;
    }
    
    function withDrawEther(uint _value) onlyOwner payable public
    {
        owner.transfer(_value);
    }
}