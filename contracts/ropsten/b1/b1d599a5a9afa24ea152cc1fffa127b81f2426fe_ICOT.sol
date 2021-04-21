/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

pragma solidity ^0.4.23;

library SafeMath {

function add(uint256 x, uint256 y) internal pure returns(uint256) {
uint256 z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }

    function sub(uint256 x, uint256 y) internal pure returns(uint256) {
      assert(x >= y);
      uint256 z = x - y;
      return z;
    }

    function mul(uint256 x, uint256 y) internal pure returns(uint256) {
      uint256 z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }

}
contract ERC20 {
	function totalSupply() public view returns (uint256);
	function maxTotalSupply() public view returns (uint256);
	// events
    event CreateICOT(address indexed _to, uint256 _value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

contract ICOT is ERC20 {

    using SafeMath for uint256;
    // metadata
    string public constant name = "ICOT";
    string public constant symbol = "ICOT";
    uint256 public constant decimals = 18;
    string public version = "1.0";

    // contracts
    address public founder;      // deposit address for ETH for ICOT
    // crowdsale parameters
    bool public isFinalized;              // switched to true in operational state
    bool public saleStarted; //switched to true during ICO
    uint public firstWeek;
    uint public secondWeek;
    uint public thirdWeek;
    uint256 public soldCoins;
    
  
    uint256 public constant founderFund = 5 * (10**6) * 10**decimals;   // 5M ICOT reserved for Owners
    uint256 public constant preMinedFund = 10 * (10**6) * 10**decimals;   // 10M ICOT reserved for Promotion, Exchange etc.
    uint256 public tokenExchangeRate = 2000; //  ICOT tokens per 1 ETH
    mapping (address => uint256) balances;
  

    // constructor
    function ICOT()
    {
      isFinalized = false;                   //controls pre through crowdsale state
      saleStarted = false;
      soldCoins = 0;
      founder = 0x6Be9ff4c8E54025D17A96bE74BbCBe3B2aa16E95;
     
      balances[founder] = founderFund;    // Deposit tokens for Owners
      CreateICOT(founder, founderFund);  // logs Owners deposit



    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    

    function totalSupply() constant returns (uint256 totalSupply)
    {
      	return founderFund+preMinedFund;
    }
	
	function maxTotalSupply() constant returns (uint256 maxSupply)
    {
    	return founderFund+preMinedFund;
    }

    function transfer(address _to, uint256 _value)
    {
      

      if (balances[msg.sender] < _value) throw;

      if (balances[_to] + _value < balances[_to]) throw;
 
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(msg.sender, _to, _value);
    }

    /// @dev Accepts ether and creates new EVN tokens.
    function () payable {
      //bool isPreSale = true;
      if (isFinalized) throw;
      if (!saleStarted) throw;
      if (msg.value == 0) throw;
      //change exchange rate based on duration
      if (now > firstWeek && now < secondWeek){
        tokenExchangeRate = 1500;
      }
      else if (now > secondWeek && now < thirdWeek){
        tokenExchangeRate = 1000;
      }
      else if (now > thirdWeek){
        tokenExchangeRate = 500;
      }
      //create tokens
      uint256 tokens = SafeMath.mul(msg.value, tokenExchangeRate); // check that we're not over totals
      uint256 checkedSupply = SafeMath.add(soldCoins, tokens);

      // return money if something goes wrong
      if (preMinedFund < checkedSupply) throw;  // odd fractions won't be found
      soldCoins = checkedSupply;
      //All good. start the transfer
      balances[msg.sender] += tokens;  // safeAdd not needed
      CreateICOT(msg.sender, tokens);  // logs token creation
    }

    /// ICOT Ends the funding period and sends the ETH home
    function finalize() external {
      if (isFinalized) throw;
      if (msg.sender != founder) throw; // locks finalize to the ultimate ETH owner
      if (soldCoins < preMinedFund){
        uint256 remainingTokens = SafeMath.sub(preMinedFund, soldCoins);
        uint256 checkedSupply = SafeMath.add(soldCoins, remainingTokens);
        if (preMinedFund < checkedSupply) throw;
        soldCoins = checkedSupply;
        balances[msg.sender] += remainingTokens;
        CreateICOT(msg.sender, remainingTokens);
      }
      // move to operational
      if(!founder.send(this.balance)) throw;
      isFinalized = true;  // send the eth to ICOT
      
    }

    function startSale() external {
      if(saleStarted) throw;
      if (msg.sender != founder) throw; // locks start sale to the ultimate ETH owner
      firstWeek = now + 1 weeks; //sets duration of first cutoff
      secondWeek = firstWeek + 1 weeks; //sets duration of second cutoff
      thirdWeek = secondWeek + 1 weeks; //sets duration of third cutoff
      saleStarted = true; //start the sale
    }


}