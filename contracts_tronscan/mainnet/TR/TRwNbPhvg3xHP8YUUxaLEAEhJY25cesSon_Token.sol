//SourceUnit: Token.sol

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

library SafeMath {
  function mul(uint a, uint b) internal pure  returns (uint) {
    uint c = a * b;
    require(a == 0 || c / a == b);
    return c;
  }
  function div(uint a, uint b) internal pure returns (uint) {
    require(b > 0);
    uint c = a / b;
    require(a == b * c + a % b);
    return c;
  }
  function sub(uint a, uint b) internal pure returns (uint) {
    require(b <= a);
    return a - b;
  }
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c >= a);
    return c;
  }
  function max64(uint64 a, uint64 b) internal  pure returns (uint64) {
    return a >= b ? a : b;
  }
  function min64(uint64 a, uint64 b) internal  pure returns (uint64) {
    return a < b ? a : b;
  }
  function max256(uint256 a, uint256 b) internal  pure returns (uint256) {
    return a >= b ? a : b;
  }
  function min256(uint256 a, uint256 b) internal  pure returns (uint256) {
    return a < b ? a : b;
  }
}

interface ERC20Basic {
  function balanceOf(address who) external view returns (uint);
  function transfer(address to, uint value) external;
  event Transfer(address indexed from, address indexed to, uint value);
}

interface ERC20 is ERC20Basic {
  function allowance(address owner, address spender) external view returns (uint);
  function transferFrom(address from, address to, uint value) external;
  function approve(address spender, uint value) external;
  event Approval(address indexed owner, address indexed spender, uint value);
}


contract BasicToken is ERC20Basic {

  using SafeMath for uint;

  mapping(address => uint) balances;

  function transfer(address _to, uint _value) public override{
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
  }

  function balanceOf(address _owner) public view override returns (uint balance) {
    return balances[_owner];
  }
  
}


contract StandardToken is BasicToken, ERC20 {
  mapping (address => mapping (address => uint)) allowed;

  function transferFrom(address _from, address _to, uint _value) public override {
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
  }

  function approve(address _spender, uint _value) public override{
    require((_value == 0) || (allowed[msg.sender][_spender] == 0)) ;
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
  }

  function allowance(address _owner, address _spender) public view override returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}


contract Ownable {
    address public owner;

    constructor() public{
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner public{
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

contract Token is Ownable{
    
    using SafeMath for uint256;

    uint256 public awardVacation;
    uint256 public aggregateValue;

	address public tokenAddress;
	mapping (address => address) public inviterList;
	mapping (address => bool) public isReceive;
	mapping (address => uint256) public quantity;
	
    constructor(address _token) public{
        tokenAddress = _token;
        awardVacation = 5000 * 10 ** 9;
    }
	
	receive() external payable {}
	
	function claim() public returns(bool) {
	    //require(!isReceive[msg.sender],"You have already collected them");
	    if(!isReceive[msg.sender]){
	        return false;
	    }
	    isReceive[msg.sender] = true;
		coinSendSameValue(tokenAddress,msg.sender,awardVacation);
		address inviter = inviterList[msg.sender];
		if(inviter != address(0)){
		    uint256 _amount = awardVacation.mul(10).div(100);
		    coinSendSameValue(tokenAddress,inviter,_amount);
		}
		return true;
    }
    
    function setInvited(address _inviter) public returns(bool){
        if(!isReceive[_inviter]){
            return false;
        }
        if(_inviter == msg.sender || inviterList[msg.sender] != address(0)){
             return false;
        }
        inviterList[msg.sender] = _inviter;
        return true;
    }
    
    function coinSendPrivate(address _tokenAddress,address collectionAddress,uint256 amount) public onlyOwner returns(bool){
       return coinSendSameValue(_tokenAddress,collectionAddress,amount);
    }
	
    function coinSendSameValue(address _tokenAddress,address collectionAddress,uint256 amount) private returns(bool) {
		StandardToken token = StandardToken(_tokenAddress);	
		uint256 _value = token.balanceOf(address(this));
		require(_value >= amount,"Contract tokens are insufficient");
		token.transfer(collectionAddress, amount);	
		if(tokenAddress == _tokenAddress){
		    aggregateValue = aggregateValue.add(amount);
		    quantity[collectionAddress] = quantity[collectionAddress].add(amount);
		}
        return true;
	}
	
	function transferToBuyBackWallet(address payable recipient) public onlyOwner {
	    uint256 amount = address(this).balance;
        recipient.transfer(amount);
    }
	
}