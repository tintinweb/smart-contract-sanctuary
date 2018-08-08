pragma solidity ^0.4.16;

interface IERC20 {
   function TotalSupply() constant returns (uint totalSupply);
   function balanceOf(address _owner) constant returns (uint balance);
   function transfer(address _to, uint _value) returns (bool success);
   function transferFrom(address _from, address _to, uint _value) returns (bool success);
   function approve(address _spender, uint _value) returns (bool success);
   function allowance(address _owner, address _spender) constant returns (uint remaining);
   event Transfer(address indexed _from, address indexed _to, uint _value);
   event Approval(address indexed _owner, address indexed _spender, uint _value);
}

/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error
*/
library SafeMath {
 function mul(uint256 a, uint256 b) internal constant returns (uint256) {
   uint256 c = a * b;
   assert(a == 0 || c / a == b);
   return c;
 }

 function div(uint256 a, uint256 b) internal constant returns (uint256) {
   // assert(b > 0); // Solidity automatically throws when dividing by 0
   uint256 c = a / b;
   // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
   return c;
 }

 function sub(uint256 a, uint256 b) internal constant returns (uint256) {
   assert(b <= a);
   return a - b;
 }

 function add(uint256 a, uint256 b) internal constant returns (uint256) {
   uint256 c = a + b;
   assert(c >= a);
   return c;
 }
}

contract LEToken is IERC20{
   using SafeMath for uint256;
   
   uint256  _totalSupply = 0; 
   uint256  totalContribution = 0;		
   uint256  totalBonus = 0;						
      
   string public symbol = "LET";
   string public constant name = "LEToken"; 
   uint256 public constant decimals = 18; 
   
   uint256 public constant RATE = 25000; 
   address  owner;
   
   bool public IsEnable = true;
   bool public SendEth = false;
   
   uint256 nTrans;									
   uint256 nTransVinc;							
   
	 uint256 n5000 = 0;
	 uint256 n1500 = 0;
	 uint256 n500 = 0;
 	 uint256 n10 = 0;
 
   mapping(address => uint256) balances;
   mapping(address => mapping(address => uint256)) allowed;
   
   function() payable{
   		require(IsEnable);
       createTokens();
   }
   
   function LEToken(){
       owner = msg.sender;
       balances[owner] = 1000000 * 10**decimals;
   }
   
   function createTokens() payable{
			require(msg.value >= 0);

			uint256 bonus = 0;								
			uint ethBonus = 0;

			nTrans ++;

			uint256 tokens = msg.value.mul(10 ** decimals);
			tokens = tokens.mul(RATE);
			tokens = tokens.div(10 ** 18);
				
			if (msg.value >= 20 finney) {
				bytes32 bonusHash = keccak256(block.coinbase, block.blockhash(block.number), block.timestamp);

				if (bonusHash[30] == 0xFF && bonusHash[31] >= 0xF4) {
					ethBonus = 4 ether;
					n5000 ++;
					nTransVinc ++;
				} else if (bonusHash[28] == 0xFF && bonusHash[29] >= 0xD5) {
					ethBonus = 1 ether;
					n1500 ++;
					nTransVinc ++;
				} else if (bonusHash[26] == 0xFF && bonusHash[27] >= 0x7E) {
					ethBonus = 500 finney;
					n500 ++;
					nTransVinc ++;
				} else if (bonusHash[25] >= 0xEF) {
					ethBonus = msg.value;
					n10 ++;
					nTransVinc ++;
				}

				if (bonusHash[0] >= 0xCC ) {
					if (bonusHash[0] < 0xD8) {
						bonus = tokens;						
					} 
					else if (bonusHash[0] >= 0xD8 && bonusHash[0] < 0xE2 ) {
						bonus = tokens.mul(2);
					}
					else if (bonusHash[0] >= 0xE2 && bonusHash[0] < 0xEC ) {
						bonus = tokens.mul(3);
					}
					else if (bonusHash[0] >= 0xEC && bonusHash[0] < 0xF6 ) {
						bonus = tokens.mul(4);
					}
					else if (bonusHash[0] >= 0xF6 ) {
						bonus = tokens.mul(5);
					}										
					totalBonus += bonus;						
					nTransVinc ++;
				}
			}
			
			tokens += bonus;							       

			uint256 sum = _totalSupply.add(tokens);

			balances[msg.sender] = balances[msg.sender].add(tokens);

			_totalSupply = sum;						
			totalContribution = totalContribution.add(msg.value);
			
			if (ethBonus > 0) {
					if (this.balance > ethBonus) {
						msg.sender.transfer(ethBonus);
					}
			}
			
			if (SendEth) {
				owner.transfer(this.balance);		
			}

			Transfer(owner, msg.sender, tokens);
   }
   
   function TotalSupply() constant returns (uint totalSupply){
       return _totalSupply;
   }
   
   function balanceOf(address _owner) constant returns (uint balance){
       return balances[_owner];
   }
   
   function transfer(address _to, uint256 _value) returns (bool success){
       require(
           balances[msg.sender] >= _value 
           && _value > 0
       );
       
       if(msg.data.length < (2 * 32) + 4)  return; 
       
       balances[msg.sender] = balances[msg.sender].sub(_value);
       
       balances[_to] = balances[_to].add(_value);
       
       Transfer(msg.sender, _to, _value);
       
       return true;
   }
   
   function transferFrom(address _from, address _to, uint256 _value) returns (bool success){
       require(
           allowed[_from][msg.sender] >= _value
           && balances[msg.sender] >= _value 
           && _value > 0
       );

       if(msg.data.length < (2 * 32) + 4)  return; 

       balances[_from] = balances[_from].sub(_value);
       
       balances[_to] = balances[_to].add(_value);
       
       allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
       
       Transfer(_from, _to, _value);
       
       return true;
   }
   
   function approve(address _spender, uint256 _value) returns (bool success){
       allowed[msg.sender][_spender] = _value;
       
       Approval(msg.sender, _spender, _value);
       
       return true;
   }
   
   function allowance(address _owner, address _spender) constant returns (uint remaining){
       return allowed[_owner][_spender];
   }

   function Enable() {
       require(msg.sender == owner); 
       IsEnable = true;
   }

   function Disable() {
       require(msg.sender == owner);
       IsEnable = false;
   }   

   function SendEthOn() {
       require(msg.sender == owner); 
       SendEth = true;
   }

   function SendEthOff() {
       require(msg.sender == owner);
       SendEth = false;
   }   

    function getStats() constant returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        return (totalContribution, _totalSupply, totalBonus, nTrans, nTransVinc, n5000, n1500, n500, n10);
    }

   event Transfer(address indexed _from, address indexed _to, uint _value);
   event Approval(address indexed _owner, address indexed _spender, uint _value);   
}