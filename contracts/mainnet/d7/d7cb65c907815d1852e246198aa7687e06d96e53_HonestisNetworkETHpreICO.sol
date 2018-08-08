pragma solidity ^0.4.10;


// title Migration Agent interface
contract MigrationAgent {
    function migrateFrom(address _from, uint256 _value);
}

// title preICO honestis networkToken (H.N Token) - crowdfunding code for preICO honestis networkToken PreICO
contract HonestisNetworkETHpreICO {
    string public constant name = "preICO seed for Honestis.Network on ETH";
    string public constant symbol = "HNT";
    uint8 public constant decimals = 18;  // 18 decimal places, the same as ETC/ETH.

    uint256 public constant tokenCreationRate = 1000;
    // The funding cap in weis.
    uint256 public constant tokenCreationCap = 66200 ether * tokenCreationRate;
    uint256 public constant tokenCreationMinConversion = 1 ether * tokenCreationRate;
	uint256 public constant tokenSEEDcap = 2.3 * 125 * 1 ether * tokenCreationRate;
	uint256 public constant token3MstepCAP = tokenSEEDcap + 10000 * 1 ether * tokenCreationRate;
	uint256 public constant token10MstepCAP = token3MstepCAP + 22000 * 1 ether * tokenCreationRate;

  // weeks and hours in block distance on ETH
   uint256 public constant oneweek = 36000;
   uint256 public constant oneday = 5136;
    uint256 public constant onehour = 214;
	
    uint256 public fundingStartBlock = 3962754 + 4*onehour;
	//  weeks
    uint256 public fundingEndBlock = fundingStartBlock+14*oneweek;

	
    // The flag indicates if the H.N Token contract is in Funding state.
    bool public funding = true;
	bool public refundstate = false;
	bool public migratestate = false;
	
    // Receives ETH and its own H.N Token endowment.
    address public honestisFort = 0xF03e8E4cbb2865fCc5a02B61cFCCf86E9aE021b5;
	address public honestisFortbackup =0x13746D9489F7e56f6d2d8676086577297FC0B492;
    // Has control over token migration to next version of token.
    address public migrationMaster = 0x8585D5A25b1FA2A0E6c3BcfC098195bac9789BE2;

   
    // The current total token supply.
    uint256 totalTokens;
	uint256 bonusCreationRate;
    mapping (address => uint256) balances;
    mapping (address => uint256) balancesRAW;


	address public migrationAgent=0x8585D5A25b1FA2A0E6c3BcfC098195bac9789BE2;
    uint256 public totalMigrated;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Migrate(address indexed _from, address indexed _to, uint256 _value);
    event Refund(address indexed _from, uint256 _value);

    function HonestisNetworkETHpreICO() {

        if (honestisFort == 0) throw;
        if (migrationMaster == 0) throw;
        if (fundingEndBlock   <= fundingStartBlock) throw;

    }

    // notice Transfer `_value` H.N Token tokens from sender&#39;s account
    // `msg.sender` to provided account address `_to`.
    // notice This function is disabled during the funding.
    // dev Required state: Operational
    // param _to The address of the tokens recipient
    // param _value The amount of token to be transferred
    // return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool) {

// freez till end of crowdfunding + 2 about weeks
if ((msg.sender!=migrationMaster)&&(block.number < fundingEndBlock + 73000)) throw;

        var senderBalance = balances[msg.sender];
        if (senderBalance >= _value && _value > 0) {
            senderBalance -= _value;
            balances[msg.sender] = senderBalance;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }

    function totalSupply() external constant returns (uint256) {
        return totalTokens;
    }

    function balanceOf(address _owner) external constant returns (uint256) {
        return balances[_owner];
    }

	function() payable {
    if(funding){
   createHNtokens(msg.sender);
   }
}

     // Crowdfunding:

        function createHNtokens(address holder) payable {

        if (!funding) throw;
        if (block.number < fundingStartBlock) throw;
        if (block.number > fundingEndBlock) throw;

        // Do not allow creating 0 or more than the cap tokens.
        if (msg.value == 0) throw;
		// check the maximum token creation cap
        if (msg.value > (tokenCreationCap - totalTokens) / tokenCreationRate)
          throw;
		
		//bonus structure
		bonusCreationRate = tokenCreationRate;
		// early birds bonuses :
        if (totalTokens < tokenSEEDcap) bonusCreationRate = tokenCreationRate +500;
	
		//after preICO period
		if (block.number > (fundingStartBlock + 6*oneweek +2*oneday)) {
			bonusCreationRate = tokenCreationRate - 200;//min 800
		if	(totalTokens > token3MstepCAP){bonusCreationRate = tokenCreationRate - 300;}//min 500
		if	(totalTokens > token10MstepCAP){bonusCreationRate = tokenCreationRate - 250;} //min 250
		}
	//time bonuses
	// 1 block = 16-16.8 s
		if (block.number < (fundingStartBlock + 5*oneweek )){
		bonusCreationRate = bonusCreationRate + (fundingStartBlock+5*oneweek-block.number)/(5*oneweek)*800;
		}
		

	 var numTokensRAW = msg.value * tokenCreationRate;

        var numTokens = msg.value * bonusCreationRate;
        totalTokens += numTokens;

        // Assign new tokens to the sender
        balances[holder] += numTokens;
        balancesRAW[holder] += numTokensRAW;
        // Log token creation event
        Transfer(0, holder, numTokens);
		
		// Create additional H.N Token for the community and developers around 14%
        uint256 percentOfTotal = 14;
        uint256 additionalTokens = 	numTokens * percentOfTotal / (100);

        totalTokens += additionalTokens;

        balances[migrationMaster] += additionalTokens;
        Transfer(0, migrationMaster, additionalTokens);
	
	}

    function Partial23Transfer() external {
         honestisFort.transfer(this.balance - 1 ether);
    }
	
    function Partial23Send() external {
	      if (msg.sender != honestisFort) throw;
        honestisFort.send(this.balance - 1 ether);
	}
	function turnrefund() external {
	      if (msg.sender != honestisFort) throw;
	refundstate=!refundstate;
        }
    function turnmigrate() external {
	      if (msg.sender != migrationMaster) throw;
	migratestate=!migratestate;
}

    // notice Finalize crowdfunding clossing funding options
	
function finalizebackup() external {
        if (block.number <= fundingEndBlock+oneweek) throw;
        // Switch to Operational state. This is the only place this can happen.
        funding = false;		
        // Transfer ETH to the preICO honestis network Fort address.
        if (!honestisFortbackup.send(this.balance)) throw;
    }
    function migrate(uint256 _value) external {
        // Abort if not in Operational Migration state.
        if (migratestate) throw;


        // Validate input value.
        if (_value == 0) throw;
        if (_value > balances[msg.sender]) throw;

        balances[msg.sender] -= _value;
        totalTokens -= _value;
        totalMigrated += _value;
        MigrationAgent(migrationAgent).migrateFrom(msg.sender, _value);
        Migrate(msg.sender, migrationAgent, _value);
    }
	
function refundTRA() external {
        // Abort if not in Funding Failure state.
        if (!refundstate) throw;

        var HNTokenValue = balances[msg.sender];
        var HNTokenValueRAW = balancesRAW[msg.sender];
        if (HNTokenValueRAW == 0) throw;
        balancesRAW[msg.sender] = 0;
        totalTokens -= HNTokenValue;
        var ETHValue = HNTokenValueRAW / tokenCreationRate;
        Refund(msg.sender, ETHValue);
        msg.sender.transfer(ETHValue);
}

function preICOregulations() external returns(string wow) {
	return &#39;Regulations of preICO are present at website  honestis.network and by using this smartcontract you commit that you accept and will follow those rules&#39;;
}
}