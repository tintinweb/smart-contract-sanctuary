pragma solidity ^0.4.17;

// import "./ConvertLib.sol";

// This is just a simple example of a coin-like contract.
// It is not standards compatible and cannot be expected to talk to other
// coin/token contracts. If you want to create a standards-compliant
// token, see: https://github.com/ConsenSys/Tokens. Cheers!

// contract MetaCoin {
// 	mapping (address => uint) balances;

// 	event Transfer(address indexed _from, address indexed _to, uint256 _value);

// 	function MetaCoin() public {
// 		balances[tx.origin] = 10000;
// 	}

// 	function sendCoin(address receiver, uint amount) public returns(bool sufficient) {
// 		if (balances[msg.sender] < amount) return false;
// 		balances[msg.sender] -= amount;
// 		balances[receiver] += amount;
// 		Transfer(msg.sender, receiver, amount);
// 		return true;
// 	}

// 	function getBalanceInEth(address addr) public view returns(uint){
// 		return ConvertLib.convert(getBalance(addr),2);
// 	}

// 	function getBalance(address addr) public view returns(uint) {
// 		return balances[addr];
// 	}
// }

contract ObsToken {
  mapping(address => uint256) balances;
  // string public constant NAME = "ObsToken";
  // string public constant SYMBOL = "OBT";
  string public symbol;
  string public  name;  
  uint256 totalSupply_;
  uint8 public decimals;
  event Transfer(address indexed from, address indexed to, uint256 value);

  constructor (uint256 INITIAL_SUPPLY, address _owner) public{
    symbol = "OBT";
    name = "ObsToken";
    totalSupply_ = INITIAL_SUPPLY;
    balances[_owner] = INITIAL_SUPPLY;
    decimals = 18 ;
    emit Transfer(0x0, _owner, INITIAL_SUPPLY);
  }

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    
    balances[msg.sender] = balances[msg.sender] - _value;
    balances[_to] = balances[_to] + _value;
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
}