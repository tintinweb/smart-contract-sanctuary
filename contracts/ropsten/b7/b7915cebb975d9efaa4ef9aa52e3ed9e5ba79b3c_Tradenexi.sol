pragma solidity ^0.4.25;


//   token smart contract for trade nex

//   This is a test contract for tradex coin
//		code is written by Muyiwa O. Samson
//		copy right : Muyiwa Samson
//  
//

contract Token {

    ///CORE FUNCTIONS; these are standard functions that enables any token to function as a token
    function totalSupply() constant returns (uint256 supply) {}										/// this function calls the total token supply in the contract

    function balanceOf(address _owner) constant returns (uint256 balance) {}						/// Function that is able to call all token balance of any specified contract address holding this token

    function transfer(address _to, uint256 _value) returns (bool success) {}						/// Function that enables token transfer

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}  	/// Function that impliments the transfer of tokens by token holders to other ERC20 COMPLIENT WALLETS 

    function approve(address _spender, uint256 _value) returns (bool success) {}

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}	/// Returns the values for token balances into contract record

    
	//CONTRACT EVENTS
	event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
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
    uint256 public totalSupply;
}

contract Tradenexi is StandardToken { 

   
    string public name;                   // Token Name
    uint8 public decimals;                // How many decimals to show. To be standard complicant keep it 18
    string public symbol;                 // An identifier: eg SBX, XPR etc..
    uint256 public exchangeRate;         // How many units of your coin can be bought by 1 ETH? unitsOneEthCanBuy now etherexchange
    address public icoWallet;           // Where should the raised ETH go?
    uint256 public endBlock;
    uint256 public startBlock;
    

	address public creator;
	
	bool public isFunding;

    // This is a constructor function 
    // which means the following function name has to match the contract name declared above
    function Tradenexi() {
        balances[msg.sender] = 1000000000000000000000000000;               // Give the creator all initial tokens. This is set to 1000 for example. If you want your initial tokens to be X and your decimal is 5, set this value to X * 1000000000000000000. (CHANGE THIS)
        totalSupply = 1000000000000000000000000000;                        // Update total supply (1000 for example) (CHANGE THIS)
        name = "Trade Nexi";                                   // Set the name for display purposes (CHANGE THIS)
        decimals = 18;                                               // Amount of decimals for display purposes (CHANGE THIS)
        symbol = "NEXI";                                             // Set the symbol for display purposes (CHANGE THIS)
        icoWallet = msg.sender;                                    // The owner of the contract gets ETH
		creator = msg.sender;
    }
	
	  
    function updateRate(uint256 rate) external {
        require(msg.sender==creator);
        require(isFunding);
        exchangeRate = rate;
		
	}
	
	
	
	function updateStartTime(uint256 StartTime) external {
        require(msg.sender==creator);
        startBlock = StartTime;
	}    

	
	function updateEndTime(uint256 endTime) external {
        require(msg.sender==creator);
        endBlock = endTime;
	}  		
   
	
	function ChangeicoWallet(address EthWallet) external {
        require(msg.sender==creator);
        icoWallet = EthWallet;
		
	}
	function changeCreator(address _creator) external {
        require(msg.sender==creator);
        creator = _creator;
    }
		

	function openSale() external {
		require(msg.sender==creator);
		isFunding = true;
    }
	
	function closeSale() external {
		require(msg.sender==creator);
		isFunding = false;
    }	
	
	
		
    function() payable {
        require(msg.value >= (1 ether/50));
        require(isFunding);
    	exchangeRate = 200000;                                      // Set the price of your token for the ICO (CHANGE THIS) $0.001 0.000002Ether
		uint256 amount = msg.value * exchangeRate;
		      
        balances[icoWallet] = balances[icoWallet] - amount;
        balances[msg.sender] = balances[msg.sender] + amount;

        Transfer(icoWallet, msg.sender, amount); // Broadcast a message to the blockchain

        //Transfer ether to fundsWallet
        icoWallet.transfer(msg.value);                               
    }
	

    /* Approves and then calls the receiving contract */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        //call the receiveApproval function on the contract you want to be notified. This crafts the function signature manually so one doesn&#39;t have to include a contract in here just for this.
        //receiveApproval(address _from, uint256 _value, address _tokenContract, bytes _extraData)
        //it is assumed that when does this that the call *should* succeed, otherwise one would use vanilla approve instead.
        if(!_spender.call(bytes4(bytes32(keccak256("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}