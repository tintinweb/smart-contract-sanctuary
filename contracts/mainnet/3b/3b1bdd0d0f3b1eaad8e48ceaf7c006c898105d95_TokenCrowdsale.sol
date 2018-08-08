pragma solidity ^0.4.11;

/**
* @author Jefferson Davis
* Prether_ICO.sol creates the client&#39;s token for crowdsale and allows for subsequent token sales and minting of tokens
*   Crowdsale contracts edited from original contract code at https://www.ethereum.org/crowdsale#crowdfund-your-idea
*   Additional crowdsale contracts, functions, libraries from TenXCrowdSale contract and OpenZeppelin
*       at https://etherscan.io/address/0xd43d09ec1bc5e57c8f3d0c64020d403b04c7f783#code and https://github.com/OpenZeppelin/zeppelin-solidity/tree/master/contracts/token
*   Token contract edited from original contract code at https://www.ethereum.org/token
*   ERC20 interface and certain token functions adapted from https://github.com/ConsenSys/Tokens
**/

contract ERC20 {
	//Sets events and functions for ERC20 token
	event Approval(address indexed _owner, address indexed _spender, uint _value);
	event Transfer(address indexed _from, address indexed _to, uint _value);
	
    function allowance(address _owner, address _spender) constant returns (uint remaining);
	function approve(address _spender, uint _value) returns (bool success);
    function balanceOf(address _owner) constant returns (uint balance);
    function transfer(address _to, uint _value) returns (bool success);
    function transferFrom(address _from, address _to, uint _value) returns (bool success);
}


contract Owned {
	//Public variable
    address public owner;

	//Sets contract creator as the owner
    function Owned() {
        owner = msg.sender;
    }
	
	//Sets onlyOwner modifier for specified functions
    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

	//Allows for transfer of contract ownership
    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}


contract TokenWithMint is ERC20, Owned {
	//Public variables
	string public name; 
	string public symbol; 
	uint256 public decimals;  
    uint256 multiplier; 
	uint256 public totalSupply; 
	
	//Creates arrays for balances
    mapping (address => uint256) balance;
    mapping (address => mapping (address => uint256)) allowed;

    //Creates modifier to prevent short address attack
    modifier onlyPayloadSize(uint size) {
        if(msg.data.length < size + 4) throw;
        _;
    }

	//Constructor
	function TokenWithMint(string tokenName, string tokenSymbol, uint8 decimalUnits, uint256 decimalMultiplier) {
		name = tokenName; 
		symbol = tokenSymbol; 
		decimals = decimalUnits; 
        multiplier = decimalMultiplier; 
		totalSupply = 0;  
	}
	
	//Provides the remaining balance of approved tokens from function approve 
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

	//Allows for a certain amount of tokens to be spent on behalf of the account owner
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

	//Returns the account balance 
    function balanceOf(address _owner) constant returns (uint256 remainingBalance) {
        return balance[_owner];
    }

    //Allows contract owner to mint new tokens, prevents numerical overflow
	function mintToken(address target, uint256 mintedAmount) onlyOwner returns (bool success) {
		if ((totalSupply + mintedAmount) < totalSupply) {
			throw; 
		} else {
            uint256 addTokens = mintedAmount * multiplier; 
			balance[target] += addTokens;
			totalSupply += addTokens;
			Transfer(0, target, addTokens);
			return true; 
		}
	}

	//Sends tokens from sender&#39;s account
    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) returns (bool success) {
        if (balance[msg.sender] >= _value && balance[_to] + _value > balance[_to]) {
            balance[msg.sender] -= _value;
            balance[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { 
			return false; 
		}
    }
	
	//Transfers tokens from an approved account 
    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) returns (bool success) {
        if (balance[_from] >= _value && allowed[_from][msg.sender] >= _value && balance[_to] + _value > balance[_to]) {
            balance[_to] += _value;
            balance[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { 
			return false; 
		}
    }
}


library SafeMath {
    function add(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }  

    function div(uint256 a, uint256 b) internal returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }
  
    function mul(uint256 a, uint256 b) internal returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal returns (uint256) {
        assert(b <= a);
        return a - b;
    }
}


contract TokenCrowdsale is Owned, TokenWithMint {
    //Applies SafeMath library to uint256 operations 
    using SafeMath for uint256;

    //Public Variables
    address public multiSigWallet;                  
    bool crowdsaleClosed = true;                    //initializes as true, requires owner to turn on crowdsale
    string tokenName = "Prether"; 
    string tokenSymbol = "PTH"; 
    uint256 public amountRaised; 
    uint256 public deadline; 
    uint256 multiplier = 1; 
    uint256 public price;                           
    uint8 decimalUnits = 0;   
    

   	//Initializes the token
	function TokenCrowdsale() 
    	TokenWithMint(tokenName, tokenSymbol, decimalUnits, multiplier) {  
            multiSigWallet = msg.sender;          
    }

    //Fallback function creates tokens and sends to investor when crowdsale is open
    function () payable {
        require(!crowdsaleClosed && (now < deadline)); 
        address recipient = msg.sender; 
        amountRaised = amountRaised + msg.value; 
        uint256 tokens = msg.value.mul(getPrice()).mul(multiplier).div(1 ether);
        totalSupply = totalSupply.add(tokens);
        balance[recipient] = balance[recipient].add(tokens);
        require(multiSigWallet.send(msg.value)); 
        Transfer(0, recipient, tokens);
    }   

    //Returns the current price of the token for the crowdsale
    function getPrice() returns (uint256 result) {
        return price;
    }

    //Returns time remaining on crowdsale
    function getRemainingTime() constant returns (uint256) {
        return deadline; 
    }

    //Returns the current status of the crowdsale
    function getSaleStatus() constant returns (bool) {
        bool status = false; 
        if (crowdsaleClosed == false) {
            status = true; 
        }
        return status; 
    }

    //Sets the multisig wallet for a crowdsale
    function setMultiSigWallet(address wallet) onlyOwner returns (bool success) {
        multiSigWallet = wallet; 
        return true; 
    }

    //Sets the token price 
    function setPrice(uint256 newPriceperEther) onlyOwner returns (uint256) {
        if (newPriceperEther <= 0) throw;  //checks for valid inputs
        price = newPriceperEther; 
        return price; 
    }

    //Allows owner to start the crowdsale from the time of execution until a specified deadline
    function startSale(uint256 price, uint256 hoursToEnd) onlyOwner returns (bool success) {
        if ((hoursToEnd < 1 )) throw;     //checks for valid inputs 
        price = setPrice(price); 
        deadline = now + hoursToEnd * 1 hours; 
        crowdsaleClosed = false; 
        return true; 
    }

    //Allows owner to start an unlimited crowdsale with no deadline or funding goal
    function startUnlimitedSale(uint256 price) onlyOwner returns (bool success) {
        price = setPrice(price); 
        deadline = 9999999999;
        crowdsaleClosed = false; 
        return true; 
    }

    //Allows owner to stop the crowdsale immediately
    function stopSale() onlyOwner returns (bool success) {
        deadline = now; 
        crowdsaleClosed = true;
        return true; 
    }

}