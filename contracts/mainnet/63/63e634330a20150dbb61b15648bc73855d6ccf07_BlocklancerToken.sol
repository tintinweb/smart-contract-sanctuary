//--------------------------------------------------------------//
//---------------------BLOCKLANCER TOKEN -----------------------//
//--------------------------------------------------------------//

pragma solidity ^0.4.8;

/// Migration Agent
/// allows us to migrate to a new contract should it be needed
/// makes blocklancer future proof
contract MigrationAgent {
    function migrateFrom(address _from, uint256 _value);
}

contract ERC20Interface {
     // Get the total token supply
     function totalSupply() constant returns (uint256 totalSupply);
  
     // Get the account balance of another account with address _owner
     function balanceOf(address _owner) constant returns (uint256 balance);
  
     // Send _value amount of tokens to address _to
     function transfer(address _to, uint256 _value) returns (bool success);
  
     // Send _value amount of tokens from address _from to address _to
     function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
  
     // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
     // If this function is called again it overwrites the current allowance with _value.
     // this function is required for some DEX functionality
     function approve(address _spender, uint256 _value) returns (bool success);
  
     // Returns the amount which _spender is still allowed to withdraw from _owner
     function allowance(address _owner, address _spender) constant returns (uint256 remaining);
  
     // Triggered when tokens are transferred.
     event Transfer(address indexed _from, address indexed _to, uint256 _value);
  
     // Triggered whenever approve(address _spender, uint256 _value) is called.
     event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/// Blocklancer Token (LNC) - crowdfunding code for Blocklancer Project
contract BlocklancerToken is ERC20Interface {
    string public constant name = "Lancer Token";
    string public constant symbol = "LNC";
    uint8 public constant decimals = 18;  // 18 decimal places, the same as ETH.
    
    mapping(address => mapping (address => uint256)) allowed;

    uint public fundingStart;

    // The flag indicates if the LNC contract is in Funding state.
    bool public funding = true;
    bool allowTransfer=false;

    // Receives ETH and its own LNC endowment.
    address public master;

    // The current total token supply.
    uint256 totalTokens;
    
    uint exchangeRate=20000;
	uint EarlyInvestorExchangeRate=25000;
	
	bool startRefund=false;

    mapping (address => uint256) balances;
    mapping (address => bool) initialInvestor;
    mapping (address => uint) lastTransferred;
    
    //needed to refund everyone should the ICO fail
    // needed because the price per LNC isn&#39;t linear
    mapping (address => uint256) balancesEther;

    //address of the contract that manages the migration
    //can only be changed by the creator
    address public migrationAgent;
    
    //total amount of token migrated
    //allows everyone to see the progress of the migration
    uint256 public totalMigrated;

    event Migrate(address indexed _from, address indexed _to, uint256 _value);
    event Refund(address indexed _from, uint256 _value);
    
    //total amount of participants in the ICO
    uint totalParticipants;

    function BlocklancerToken() {
        master = msg.sender;
        fundingStart = 1501977600;
        initialInvestor[0x32be343b94f860124dc4fee278fdcbd38c102d88]=true;initialInvestor[0x3106fe2245b376888d684bdcd83dfa9641a869ff]=true;initialInvestor[0x7f7c64c7b7f5a611e739b4da26659bf741414917]=true;initialInvestor[0x4b3b8e0c2c221e916a48e2e5f3718ae2bce51894]=true;initialInvestor[0x507c8fea802a0772eb5e001a8fba38f36fb9b66b]=true;initialInvestor[0x3c35b66dbaf1bc716f41759c7513a7af2f727ce0]=true;initialInvestor[0x7da3ff5dc152352dcffaf08d528e78f1efd4e9d1]=true;initialInvestor[0x404b688a1d9eb850be2527c5dd341561cfa84e11]=true;initialInvestor[0x80ad7165f29f97896a0b5758193879de34fd9712]=true;initialInvestor[0xd70837a61a322f69ba3742111216a7b97d61d3a7]=true;initialInvestor[0x5eefc4f295045ea11827f515c10d50829580cd31]=true;initialInvestor[0xc8c154d54e8d66073b23361cc74cf5d13efc4dc9]=true;initialInvestor[0x00b279438dff4bb6f37038b12704e31967955cb0]=true;initialInvestor[0xfff78f0db7995c7f2299d127d332aef95bc3e7b7]=true;initialInvestor[0xae631a37ad50bf03e8028d0ae8ba041c70ac4c70]=true;initialInvestor[0x4effca51ba840ae9563f5ac1aa794d1e5d3a3806]=true;initialInvestor[0x315a233620b8536d37a92d588aaf5eb050b50d84]=true;initialInvestor[0x1ebf9e3470f303f6a6ac43347e41877b0a5aaa39]=true;initialInvestor[0xbf022480bda3f6c839cd443397761d5e83f3c02b]=true;initialInvestor[0xe727ea5340256a5236287ee3074eea34d8483457]=true;initialInvestor[0x45ecfeea42fc525c0b29313d3de9089488ef71dc]=true;initialInvestor[0xe59e4aac45862796cb52434967cf72ea46474ff3]=true;initialInvestor[0x7c367c14a322404f9e332b68d7d661b46a5c93ea]=true;initialInvestor[0x08bea4ccc9c45e506d5bc5e638acaa13fa3e801c]=true;initialInvestor[0x5dfb4a015eb0c3477a99ba88b2ac60459c879674]=true;initialInvestor[0x771a2137708ca7e07e7b7c55e5ea666e88d7c0c8]=true;initialInvestor[0xcc8ab06eb5a14855fc8b90abcb6be2f34ee5cea1]=true;initialInvestor[0x0764d446d0701a9b52382f8984b9d270d266e02c]=true;initialInvestor[0x2d90b415a38e2e19cdd02ff3ad81a97af7cbf672]=true;initialInvestor[0x0d4266de516944a49c8109a4397d1fcf06fb7ed0]=true;initialInvestor[0x7a5159617df20008b4dbe06d645a1b0305406794]=true;initialInvestor[0xaf9e23965c09ebf5d313c669020b0e1757cbb92c]=true;initialInvestor[0x33d94224754c122baa1ebaf455d16a9c82f69c98]=true;initialInvestor[0x267be1c1d684f78cb4f6a176c4911b741e4ffdc0]=true;initialInvestor[0xf6ac7c81ca099e34421b7eff7c9e80c8f56b74ae]=true;initialInvestor[0xd85faf59e73225ef386b46a1b17c493019b23e1e]=true;initialInvestor[0x3833f8dbdbd6bdcb6a883ff209b869148965b364]=true;initialInvestor[0x7ed1e469fcb3ee19c0366d829e291451be638e59]=true;initialInvestor[0x6c1ddafafd55a53f80cb7f4c8c8f9a9f13f61d70]=true;initialInvestor[0x94ef531595ffe510f8dc92e0e07a987f57784338]=true;initialInvestor[0xcc54e4e2f425cc4e207344f9e0619c1e40f42f26]=true;initialInvestor[0x70ee7bfc1aeac50349c29475a11ed4c57961b387]=true;initialInvestor[0x89be0bd8b6007101c7da7170a6461580994221d0]=true;initialInvestor[0xa7802ba51ba87556263d84cfc235759b214ccf35]=true;initialInvestor[0xb6a34bd460f02241e80e031023ec20ce6fc310ae]=true;initialInvestor[0x07004b458b56fb152c06ad81fe1be30c8a8b2ea1]=true;initialInvestor[0xb6da110659ef762a381cf2d6f601eb19b5f5d51e]=true;initialInvestor[0x20abf65634219512c6c98a64614c43220ca2085b]=true;initialInvestor[0x3afd1483693fe606c0e58f580bd08ae9aba092fd]=true;initialInvestor[0x61e120b9ca6559961982d9bd1b1dbea7485b84d1]=true;initialInvestor[0x481525718f1536ca2d739aa7e68b94b5e1d5d2c2]=true;initialInvestor[0x8e129a434cde6f52838fad2d30d8b08f744abf48]=true;initialInvestor[0x13df035952316f5fb663c262064ee39e44aa6b43]=true;initialInvestor[0x03c6c82a1d6d13b2f92ed63a10b1b791ffaa1e02]=true;initialInvestor[0xb079a72c627d0a34b880aee0504b901cbce64568]=true;initialInvestor[0xbf27721ca05c983c902df12492620ab2a8b9db91]=true;initialInvestor[0x4ced2b7d27ac74b0ecb2440d9857ba6c6407149f]=true;initialInvestor[0x330c63a5b737b5542be108a74b3fef6272619585]=true;initialInvestor[0x266dccd07a275a6e72b6bc549f7c2ce9e082f13f]=true;initialInvestor[0xf4280bf77a043568e40da2b8068b11243082c944]=true;initialInvestor[0x67d2f0e2d642a87300781df25c45b00bccaf6983]=true;initialInvestor[0x9f658a6628864e94f9a1c53ba519f0ae37a8b4a5]=true;initialInvestor[0x498d256ee53d4d05269cfa1a80c3214e525076ca]=true;initialInvestor[0xa1beac79dda14bce1ee698fdee47e2f7f2fd1f0d]=true;initialInvestor[0xfeb063bd508b82043d6b4d5c51e1e42b44f39b33]=true;initialInvestor[0xfeb7a283e1dbf2d5d8e9ba64ab5e607a41213561]=true;initialInvestor[0xabedb3d632fddccd4e95957be4ee0daffbe6acdd]=true;initialInvestor[0x4d8a7cb44d317113c82f25a0174a637a8f012ebb]=true;initialInvestor[0xe922c94161d45bdd31433b3c7b912ad214d399ce]=true;initialInvestor[0x11f9ad6eb7e9e98349b8397c836c0e3e88455b0a]=true;initialInvestor[0xfc28b52160639167fa59f30232bd8d43fab681e6]=true;initialInvestor[0xaf8a6c54fc8fa59cfcbc631e56b3d5b22fa42b75]=true;initialInvestor[0xd3c0ebb99a5616f3647f16c2efb40b133b5b1e1c]=true;initialInvestor[0x877341abeac8f44ac69ba7c99b1d5d31ce7a11d7]=true;initialInvestor[0xb22f376f70f34c906a88a91f6999a0bd1a0f3c3d]=true;initialInvestor[0x2c99db3838d6af157c8d671291d560a013c6c01e]=true;initialInvestor[0xd0f38af6984f3f847f7f2fcd6ea27aa878257059]=true;initialInvestor[0x2a5da89176d5316782d7f1c9db74d209679ad9ce]=true;initialInvestor[0xc88eea647a570738e69ad3dd8975577df720318d]=true;initialInvestor[0xb32b18dfea9072047a368ec056a464b73618345a]=true;initialInvestor[0x945b9a00bffb201a5602ee661f2a4cc6e5285ca6]=true;initialInvestor[0x86957ac9a15f114c08296523569511c22e471266]=true;initialInvestor[0x007bfe6994536ec9e89505c7de8e9eb748d3cb27]=true;initialInvestor[0x6ad0f0f578115b6fafa73df45e9f1e9056b84459]=true;initialInvestor[0x621663b4b6580b70b74afaf989c707d533bbec91]=true;initialInvestor[0xdc86c0632e88de345fc2ac01608c63f2ed99605a]=true;initialInvestor[0x3d83bb077b2557ef5f361bf1a9e68d093d919b28]=true;initialInvestor[0x56307b37377f75f397d4936cf507baf0f4943ea5]=true;initialInvestor[0x555cbe849bf5e01db195a81ecec1e65329fff643]=true;initialInvestor[0x7398a2edb928a2e179f62bfb795f292254f6850e]=true;initialInvestor[0x30382b132f30c175bee2858353f3a2dd0d074c3a]=true;initialInvestor[0x5baeac0a0417a05733884852aa068b706967e790]=true;initialInvestor[0xcb12b8a675e652296a8134e70f128521e633b327]=true;initialInvestor[0xaa8c03e04b121511858d88be7a1b2f5a2d70f6ac]=true;initialInvestor[0x77529c0ea5381262db964da3d5f6e2cc92e9b48b]=true;initialInvestor[0x59e5fe8a9637702c6d597c5f1c4ebe3fba747371]=true;initialInvestor[0x296fe436ecc0ea6b7a195ded26451e77e1335108]=true;initialInvestor[0x41bacae05437a3fe126933e57002ae3f129aa079]=true;initialInvestor[0x6cd5b9b60d2bcf81af8e6ef5d750dc9a8f18bf45]=true;
    }
    
    //returns the total amount of participants in the ICO
    function getAmountofTotalParticipants() constant returns (uint){
        return totalParticipants;
    }

    /// allows to transfer token to another address
    function transfer(address _to, uint256 _value) returns (bool success) {
        // Don&#39;t allow in funding state
        if(funding) throw;
        if(!allowTransfer)throw;

        var senderBalance = balances[msg.sender];
        //only allow if the balance of the sender is more than he want&#39;s to send
        if (senderBalance >= _value && _value > 0) {
            //reduce the sender balance by the amount he sends
            senderBalance -= _value;
            balances[msg.sender] = senderBalance;
            
            //increase the balance of the receiver by the amount we reduced the balance of the sender
            balances[_to] += _value;
            
            //saves the last time someone sent LNc from this address
            //is needed for our Token Holder Tribunal
            //this ensures that everyone can only vote one time
            //otherwise it would be possible to send the LNC around and everyone votes again and again
            lastTransferred[msg.sender]=block.timestamp;
            Transfer(msg.sender, _to, _value);
            return true;
        }
        //transfer failed
        return false;
    }

    //returns the total amount of LNC in circulation
    //get displayed on the website whilst the crowd funding
    function totalSupply() constant returns (uint256 totalSupply) {
        return totalTokens;
    }
    
    //retruns the balance of the owner address
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
    
    //returns the amount anyone pledged into this contract
    function EtherBalanceOf(address _owner) constant returns (uint256) {
        return balancesEther[_owner];
    }
    
    //returns the amount anyone pledged into this contract
    function isInitialInvestor(address _owner) constant returns (bool) {
        return initialInvestor[_owner];
    }
    
    //time left before the crodsale begins
    function TimeLeftBeforeCrowdsale() external constant returns (uint256) {
        if(fundingStart>block.timestamp)
            return fundingStart-block.timestamp;
        else
            return 0;
    }

    // allows us to migrate to anew contract
    function migrate(uint256 _value) external {
        // can only be called if the funding ended
        if(funding) throw;
        
        //the migration agent address needs to be set
        if(migrationAgent == 0) throw;

        // must migrate more than nothing
        if(_value == 0) throw;
        
        //if the value is higher than the sender owns abort
        if(_value > balances[msg.sender]) throw;

        //reduce the balance of the owner
        balances[msg.sender] -= _value;
        
        //reduce the token left in the old contract
        totalTokens -= _value;
        totalMigrated += _value;
        
        //call the migration agent to complete the migration
        //credits the same amount of LNC in the new contract
        MigrationAgent(migrationAgent).migrateFrom(msg.sender, _value);
        Migrate(msg.sender, migrationAgent, _value);
    }

    //sets the address of the migration agent
    function setMigrationAgent(address _agent) external {
        //not possible in funding mode
        if(funding) throw;
        
        //only allow to set this once
        if(migrationAgent != 0) throw;
        
        //anly the owner can call this function
        if(msg.sender != master) throw;
        
        //set the migration agent
        migrationAgent = _agent;
    }
    
    function setExchangeRate(uint _exchangeRate){
        if(msg.sender!=master)throw;
        exchangeRate=_exchangeRate;
    }
    
    function setICORunning(bool r){
        if(msg.sender!=master)throw;
        funding=r;
    }
    
    function setTransfer(bool r){
        if(msg.sender!=master)throw;
        allowTransfer=r;
    }
	
	function addInitialInvestor(address invest){
		if(msg.sender!=master)throw;
		initialInvestor[invest]=true;
	}
	
	function addToken(address invest,uint256 value){
		if(msg.sender!=master)throw;
		balances[invest]+=value;
		totalTokens+=value;
	}
	
	function setEarlyInvestorExchangeRate(uint invest){
		if(msg.sender!=master)throw;
		EarlyInvestorExchangeRate=invest;
	}
	
	function setStartDate(uint time){
		if(msg.sender!=master)throw;
		fundingStart=time;
	}
	
	function setStartRefund(bool s){
		if(msg.sender!=master)throw;
		startRefund=s;
	}
    
    //return the current exchange rate -> LNC per Ether
    function getExchangeRate(address investorAddress) constant returns(uint){
		if(initialInvestor[investorAddress])
			return EarlyInvestorExchangeRate;
		else
			return exchangeRate;
    }
    
    //returns if the crowd sale is still open
    function ICOopen() constant returns(bool){
        if(!funding) return false;
        else if(block.timestamp < fundingStart) return false;
        else return true;
    }

    //when someone send ether to this contract
    function() payable external {
        //not possible if the funding has ended
        if(!funding) throw;
        
        //not possible before the funding started
        if(block.timestamp < fundingStart) throw;

        // Do not allow creating 0 or more than the cap tokens.
        if(msg.value == 0) throw;

        //calculate the amount of LNC the sender receives
        var numTokens = msg.value * getExchangeRate(msg.sender);
        totalTokens += numTokens;

        // increase the amount of token the sender holds
        balances[msg.sender] += numTokens;
        
        //increase the amount of ether the sender pledged into the contract
        balancesEther[msg.sender] += msg.value;
        
        //icrease the amount of people that sent ether to this contract
        totalParticipants+=1;

        // Log token creation
        Transfer(0, msg.sender, numTokens);
    }

    //called after the crodsale ended
    //needed to allow everyone to send their LNC around
    function finalize(uint percentOfTotal) external {
        if(msg.sender!=master)throw;
        if(funding)throw;

        // allows to tranfer token to another address
        // disables buying LNC
        funding = false;

        //send 12% of the token to the devs
        //10 % for the devs
        //2 % for the bounty participants
        uint256 additionalTokens = totalTokens * percentOfTotal / (100 - percentOfTotal);
        totalTokens += additionalTokens;
        balances[master] += additionalTokens;
        Transfer(0, master, additionalTokens);

        // Transfer ETH to the Blocklancer address.
        if (!master.send(this.balance)) throw;
    }
	
	//everyone needs to call this function should the minimum cap not be reached
    //refunds the sender
    function refund() external {
        if(!startRefund) throw;

        var gntValue = balances[msg.sender];
        var ethValue = balancesEther[msg.sender];
        if (gntValue == 0) throw;
        
        //set the amount of token the sender has to 0
        balances[msg.sender] = 0;
        
        //set the amount of ether the sender owns to 0
        balancesEther[msg.sender] = 0;
        totalTokens -= gntValue;

        Refund(msg.sender, ethValue);
        if (!msg.sender.send(ethValue)) throw;
    }
	
    // Send _value amount of tokens from address _from to address _to
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
     // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
     // fees in sub-currencies; the command should fail unless the _from account has
     // deliberately authorized the sender of the message via some mechanism; we propose
     // these standardized APIs for approval:
     function transferFrom(address _from,address _to,uint256 _amount) returns (bool success) {
         if(funding) throw;
         if(!allowTransfer)throw;
         if (balances[_from] >= _amount
             && allowed[_from][msg.sender] >= _amount
             && _amount > 0
             && balances[_to] + _amount > balances[_to]) {
             balances[_from] -= _amount;
             allowed[_from][msg.sender] -= _amount;
             balances[_to] += _amount;
             Transfer(_from, _to, _amount);
             return true;
         } else {
             return false;
         }
     }
  
     // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
     // If this function is called again it overwrites the current allowance with _value.
     function approve(address _spender, uint256 _amount) returns (bool success) {
         if(funding) throw;
         if(!allowTransfer)throw;
         allowed[msg.sender][_spender] = _amount;
         Approval(msg.sender, _spender, _amount);
         return true;
     }
  
     function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
         return allowed[_owner][_spender];
     }
}