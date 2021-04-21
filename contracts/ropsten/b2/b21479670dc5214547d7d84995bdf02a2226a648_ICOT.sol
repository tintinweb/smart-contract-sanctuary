/**
 *Submitted for verification at Etherscan.io on 2021-04-21
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
	function totalSupply()public view returns (uint total_Supply);
	function balanceOf(address who)public view returns (uint256);
	function allowance(address owner, address spender)public view returns (uint);
	function transferFrom(address from, address to, uint value)public returns (bool ok);
	function approve(address spender, uint value)public returns (bool ok);
	function transfer(address to, uint value)public returns (bool ok);
	// events
    event CreateICOT(address indexed _to, uint256 _value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed owner, address indexed spender, uint value);
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
	 mapping(address => mapping(address => uint)) allowed;
  

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

     function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    

    function totalSupply() public view returns (uint256 total_Supply) {
        total_Supply = founderFund+preMinedFund;
    }


    function transferFrom( address _from, address _to, uint256 _amount ) public returns (bool success) {
        require( _to != 0x0);
        require(balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount >= 0);
        balances[_from] = (balances[_from]).sub(_amount);
        allowed[_from][msg.sender] = (allowed[_from][msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        Transfer(_from, _to, _amount);
        return true;
    }
    
    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require( _spender != 0x0);
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
  
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        require( _owner != 0x0 && _spender !=0x0);
        return allowed[_owner][_spender];
    }

    // Transfer the balance from owner's account to another account
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require( _to != 0x0);
        require(balances[msg.sender] >= _amount && _amount >= 0);
        
        address _customerAddress = msg.sender;
        
        
        balances[msg.sender] = (balances[msg.sender]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        Transfer(msg.sender, _to, _amount);
        return true;
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