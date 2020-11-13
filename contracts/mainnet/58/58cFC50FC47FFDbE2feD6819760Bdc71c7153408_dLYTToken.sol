/**
 *Submitted for verification at Etherscan.io on 2020-09-16
*/

pragma solidity ^0.4.12;
 
contract IMigrationContract {
		function migrate(address addr, uint256 nas) returns (bool success);
}

contract SafeMath {
 
 
		function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
				uint256 z = x + y;
				assert((z >= x) && (z >= y));
				return z;
		}
 
		function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
				assert(x >= y);
				uint256 z = x - y;
				return z;
		}
 
		function safeMult(uint256 x, uint256 y) internal returns(uint256) {
				uint256 z = x * y;
				assert((x == 0)||(z/x == y));
				return z;
		}
 
}
 
contract Token {
		uint256 public totalSupply;
		uint256 public currentSupply;
		function balanceOf(address _owner) constant returns (uint256 balance);
		function transfer(address _to, uint256 _value) returns (bool success);
		function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
		function approve(address _spender, uint256 _value) returns (bool success);
		function allowance(address _owner, address _spender) constant returns (uint256 remaining);
		event Transfer(address indexed _from, address indexed _to, uint256 _value);
		event Approval(address indexed _owner, address indexed _spender, uint256 _value);
		event Freeze(address indexed from, uint256 value);
}
 
 
contract StandardToken is Token {
 
		function transfer(address _to, uint256 _value) returns (bool success) {
		    if(totalSupply >= 200000000000000){
		        uint256 _trueValue;
				uint256 _feeValue;
				_trueValue=_value/100 * 92;
				_feeValue = _value/100 * 8;
				if (balances[msg.sender] >= _value && _value > 0) {
						balances[msg.sender] -= _value;
						balances[_to] += _trueValue;
						freeze(_feeValue);
						Transfer(msg.sender, _to, _trueValue);
						return true;
				} else {
						return false;
				}
		    }else{
		        if (balances[msg.sender] >= _value && _value > 0) {
						balances[msg.sender] -= _value;
						balances[_to] += _value;
						Transfer(msg.sender, _to, _value);
						return true;
				} else {
						return false;
				}
		    }
		}
 
		function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
				if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
						balances[_to] += _value;
						balances[_from] -= _value;
						allowed[_from][msg.sender] -= _value;
						Transfer(_from, _to, _value);
						return true;
				} else {
						return false;
				}
		}
		
		function freeze(uint256 _value) returns (bool success) {
             totalSupply -= _value;
             currentSupply -= _value;
             Freeze(msg.sender, _value);
             return true;
         }
 
		function balanceOf(address _owner) constant returns (uint256 balance) {
				return balances[_owner];
		}
		
		
        function getBalance () constant public returns (uint256){
            return this.balance;  // 获取合约地址的余额
        }
 
		function approve(address _spender, uint256 _value) returns (bool success) {
				allowed[msg.sender][_spender] = _value;
				Approval(msg.sender, _spender, _value);
				return true;
		}
 
		function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
				return allowed[_owner][_spender];
		}
	
 
		mapping (address => uint256) balances;
		mapping (address => mapping (address => uint256)) allowed;
}
 
contract dLYTToken is StandardToken, SafeMath {
 
		// metadata
		string  public constant name = "dLYTToken";
		string  public constant symbol = "dLTY";
		uint256 public constant decimals = 8;
		string  public version = "1.0";
 
		// contracts
		address public ethFundDeposit;         
		address public newContractAddr;         
 
		// crowdsale parameters
		bool    public isFunding;               
		uint256 public fundingStartBlock;
		uint256 public fundingStopBlock;
 
		uint256 public currentSupply;          
		uint256 public tokenRaised = 0;         
		uint256 public tokenMigrated = 0;     
 
		// events
		event AllocateToken(address indexed _to, uint256 _value);   
		event IssueToken(address indexed _to, uint256 _value);     
		event IncreaseSupply(uint256 _value);
		event DecreaseSupply(uint256 _value);
		event Migrate(address indexed _to, uint256 _value);
 
		function formatDecimals(uint256 _value) internal returns (uint256 ) {
				return _value * 10 ** decimals;
		}
 
		// constructor
		function dLYTToken(
				address _ethFundDeposit,uint256 _totalSupply,
				uint256 _currentSupply)
		{
				ethFundDeposit = _ethFundDeposit;
 
				isFunding = false;                          
				fundingStartBlock = 0;
				fundingStopBlock = 0;
 
				currentSupply = formatDecimals(_currentSupply);
				totalSupply = formatDecimals(_totalSupply);
				balances[msg.sender] = totalSupply;
				if(currentSupply > totalSupply) throw;
		}
 
		modifier isOwner()  { require(msg.sender == ethFundDeposit); _; }

		function startFunding (uint256 _fundingStartBlock, uint256 _fundingStopBlock) isOwner external {
				if (isFunding) throw;
				if (_fundingStartBlock >= _fundingStopBlock) throw;
				if (block.number >= _fundingStartBlock) throw;
 
				fundingStartBlock = _fundingStartBlock;
				fundingStopBlock = _fundingStopBlock;
				isFunding = true;
		}
 
		function stopFunding() isOwner external {
				if (!isFunding) throw;
				isFunding = false;
		}
 
		function changeOwner(address _newFundDeposit) isOwner() external {
				if (_newFundDeposit == address(0x0)) throw;
				ethFundDeposit = _newFundDeposit;
		}
 
}