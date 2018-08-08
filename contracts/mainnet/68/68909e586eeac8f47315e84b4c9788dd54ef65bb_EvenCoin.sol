pragma solidity ^0.4.11;

/* taking ideas from FirstBlood token */
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


contract EvenCoin is SafeMath {

    // metadata
    string public constant name = "EvenCoin";
    string public constant symbol = "EVN";
    uint256 public constant decimals = 18;
    string public version = "1.0";

    // contracts
    address public founder;      // deposit address for ETH for EvenCoin
    // crowdsale parameters
    bool public isFinalized;              // switched to true in operational state
    bool public saleStarted; //switched to true during ICO
    uint public firstWeek;
    uint public secondWeek;
    uint public thirdWeek;
    uint256 public soldCoins;
    uint256 public totalGenesisAddresses;
    uint256 public currentGenesisAddresses;
    uint256 public initialSupplyPerAddress;
    uint256 public initialBlockCount;
    uint256 private minedBlocks;
    uint256 public rewardPerBlockPerAddress;
    uint256 private availableAmount;
    uint256 private availableBalance;
    uint256 private totalMaxAvailableAmount;
    uint256 public constant founderFund = 5 * (10**6) * 10**decimals;   // 12.5m EvenCoin reserved for Owners
    uint256 public constant preMinedFund = 10 * (10**6) * 10**decimals;   // 12.5m EvenCoin reserved for Promotion, Exchange etc.
    uint256 public tokenExchangeRate = 2000; //  EvenCoin tokens per 1 ETH
    mapping (address => uint256) balances;
    mapping (address => bool) public genesisAddress;


    // events
    event CreateEVN(address indexed _to, uint256 _value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // constructor
    function EvenCoin()
    {
      isFinalized = false;                   //controls pre through crowdsale state
      saleStarted = false;
      soldCoins = 0;
      founder = &#39;0x9e8De5BE5B046D2c85db22324260D624E0ddadF4&#39;;
      initialSupplyPerAddress = 21250 * 10**decimals;
      rewardPerBlockPerAddress = 898444106206663;
      totalGenesisAddresses = 4000;
      currentGenesisAddresses = 0;
      initialBlockCount = 0;
      balances[founder] = founderFund;    // Deposit tokens for Owners
      CreateEVN(founder, founderFund);  // logs Owners deposit



    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function currentEthBlock() constant returns (uint256 blockNumber)
    {
    	return block.number;
    }

    function currentBlock() constant returns (uint256 blockNumber)
    {
      if(initialBlockCount == 0){
        return 0;
      }
      else{
      return block.number - initialBlockCount;
    }
    }

    function setGenesisAddressArray(address[] _address) public returns (bool success)
    {
      if(initialBlockCount == 0) throw;
      uint256 tempGenesisAddresses = currentGenesisAddresses + _address.length;
      if (tempGenesisAddresses <= totalGenesisAddresses )
    	{
    		if (msg.sender == founder)
    		{
          currentGenesisAddresses = currentGenesisAddresses + _address.length;
    			for (uint i = 0; i < _address.length; i++)
    			{
    				balances[_address[i]] = initialSupplyPerAddress;
    				genesisAddress[_address[i]] = true;
    			}
    			return true;
    		}
    	}
    	return false;
    }

    function availableBalanceOf(address _address) constant returns (uint256 Balance)
    {
    	if (genesisAddress[_address])
    	{
    		minedBlocks = block.number - initialBlockCount;
        if(minedBlocks % 2 != 0){
          minedBlocks = minedBlocks - 1;
        }

    		if (minedBlocks >= 23652000) return balances[_address];
    		  availableAmount = rewardPerBlockPerAddress*minedBlocks;
    		  totalMaxAvailableAmount = initialSupplyPerAddress - availableAmount;
          availableBalance = balances[_address] - totalMaxAvailableAmount;
          return availableBalance;
    	}
    	else {
    		return balances[_address];
      }
    }

    function totalSupply() constant returns (uint256 totalSupply)
    {
      if (initialBlockCount != 0)
      {
      minedBlocks = block.number - initialBlockCount;
      if(minedBlocks % 2 != 0){
        minedBlocks = minedBlocks - 1;
      }
    	availableAmount = rewardPerBlockPerAddress*minedBlocks;
    }
    else{
      availableAmount = 0;
    }
    	return availableAmount*totalGenesisAddresses+founderFund+preMinedFund;
    }

    function maxTotalSupply() constant returns (uint256 maxSupply)
    {
    	return initialSupplyPerAddress*totalGenesisAddresses+founderFund+preMinedFund;
    }

    function transfer(address _to, uint256 _value)
    {
      if (genesisAddress[_to]) throw;

      if (balances[msg.sender] < _value) throw;

      if (balances[_to] + _value < balances[_to]) throw;

      if (genesisAddress[msg.sender])
      {
    	   minedBlocks = block.number - initialBlockCount;
         if(minedBlocks % 2 != 0){
           minedBlocks = minedBlocks - 1;
         }
    	    if (minedBlocks < 23652000)
    	     {
    		       availableAmount = rewardPerBlockPerAddress*minedBlocks;
    		       totalMaxAvailableAmount = initialSupplyPerAddress - availableAmount;
    		       availableBalance = balances[msg.sender] - totalMaxAvailableAmount;
    		       if (_value > availableBalance) throw;
    	     }
      }
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
      uint256 tokens = safeMult(msg.value, tokenExchangeRate); // check that we&#39;re not over totals
      uint256 checkedSupply = safeAdd(soldCoins, tokens);

      // return money if something goes wrong
      if (preMinedFund < checkedSupply) throw;  // odd fractions won&#39;t be found
      soldCoins = checkedSupply;
      //All good. start the transfer
      balances[msg.sender] += tokens;  // safeAdd not needed
      CreateEVN(msg.sender, tokens);  // logs token creation
    }

    /// EvenCoin Ends the funding period and sends the ETH home
    function finalize() external {
      if (isFinalized) throw;
      if (msg.sender != founder) throw; // locks finalize to the ultimate ETH owner
      if (soldCoins < preMinedFund){
        uint256 remainingTokens = safeSubtract(preMinedFund, soldCoins);
        uint256 checkedSupply = safeAdd(soldCoins, remainingTokens);
        if (preMinedFund < checkedSupply) throw;
        soldCoins = checkedSupply;
        balances[msg.sender] += remainingTokens;
        CreateEVN(msg.sender, remainingTokens);
      }
      // move to operational
      if(!founder.send(this.balance)) throw;
      isFinalized = true;  // send the eth to EvenCoin
      if (block.number % 2 != 0){
        initialBlockCount = safeAdd(block.number, 1);
      }
      else{
        initialBlockCount = block.number;
      }
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