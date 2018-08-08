pragma solidity ^0.4.21;

/// ERC20 contract interface With ERC23/ERC223 Extensions
contract ERC20 {
    uint256 public totalSupply;

    // ERC223 and ERC20 functions and events
    function totalSupply() constant public returns (uint256 _supply);
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool ok);
    function name() constant public returns (string _name);
    function symbol() constant public returns (string _symbol);
    function decimals() constant public returns (uint8 _decimals);

    // ERC20 Event 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event FrozenFunds(address target, bool frozen);
	event Burn(address indexed from, uint256 value); 
}

/// Include SafeMath Lib
contract SafeMath {
    uint256 constant public MAX_UINT256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function safeAdd(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (x > MAX_UINT256 - y) revert();
        return x + y;
    }

    function safeSub(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (x < y) revert();
        return x - y;
    }

    function safeMul(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (y == 0) return 0;
        if (x > MAX_UINT256 / y) revert();
        return x * y;
    }
}

/// Contract that is working with ERC223 tokens
contract ContractReceiver {
	struct TKN {
        address sender;
        uint256 value;
        bytes data;
        bytes4 sig;
    }

    function tokenFallback(address _from, uint256 _value, bytes _data) public pure {
      TKN memory tkn;
      tkn.sender = _from;
      tkn.value = _value;
      tkn.data = _data;
      uint32 u = uint32(_data[3]) + (uint32(_data[2]) << 8) + (uint32(_data[1]) << 16) + (uint32(_data[0]) << 24);
      tkn.sig = bytes4(u);
    }
	
	function rewiewToken  () public pure returns (address, uint, bytes, bytes4) {
        TKN memory tkn;
        return (tkn.sender, tkn.value, tkn.data, tkn.sig);
    }
}

/// REALTHIUM inc.
contract TokenRHT is ERC20, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;
    bool public SC_locked = true;
    bool public tokenCreated = false;
	uint public DateCreateToken;

    mapping(address => uint256) balances;
    mapping(address => bool) public frozenAccount;
	mapping(address => bool) public SmartContract_Allowed;

    // Initialize
    // Constructor is called only once and can not be called again (Ethereum Solidity specification)
    function TokenRHT() public {
        // Security check in case EVM has future flaw or exploit to call constructor multiple times
        require(tokenCreated == false);

        owner = msg.sender;
        
		name = "REALTHIUM";
        symbol = "RHT";
        decimals = 5;
        totalSupply = 500000000 * 10 ** uint256(decimals);
        balances[owner] = totalSupply;
        emit Transfer(owner, owner, totalSupply);
		
        tokenCreated = true;

        // Final sanity check to ensure owner balance is greater than zero
        require(balances[owner] > 0);

		// Date Deploy Contract
		DateCreateToken = now;
    }
	
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

	// Function to create date token.
    function DateCreateToken() public view returns (uint256 _DateCreateToken) {
		return DateCreateToken;
	}
   	
    // Function to access name of token .
    function name() view public returns (string _name) {
		return name;
	}
	
    // Function to access symbol of token .
    function symbol() public view returns (string _symbol) {
		return symbol;
    }

    // Function to access decimals of token .
    function decimals() public view returns (uint8 _decimals) {	
		return decimals;
    }

    // Function to access total supply of tokens .
    function totalSupply() public view returns (uint256 _totalSupply) {
		return totalSupply;
	}
	
	// Get balance of the address provided
    function balanceOf(address _owner) constant public returns (uint256 balance) {
        return balances[_owner];
    }

	// Get Smart Contract of the address approved
    function SmartContract_Allowed(address _target) constant public returns (bool _sc_address_allowed) {
        return SmartContract_Allowed[_target];
    }

    // Added due to backwards compatibility reasons .
    function transfer(address _to, uint256 _value) public returns (bool success) {
        // Only allow transfer once Locked
        require(!SC_locked);
		require(!frozenAccount[msg.sender]);
		require(!frozenAccount[_to]);

        //standard function transfer similar to ERC20 transfer with no _data
        if (isContract(_to)) {
            return transferToContract(_to, _value);
        } 
        else {
            return transferToAddress(_to, _value);
        }
    }

	// assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length > 0);
    }

    // function that is called when transaction target is an address
    function transferToAddress(address _to, uint256 _value) private returns (bool success) {
        if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // function that is called when transaction target is a contract
    function transferToContract(address _to, uint256 _value) private returns (bool success) {
        require(SmartContract_Allowed[_to]);
		
		if (balanceOf(msg.sender) < _value) revert();
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

	// Function to activate Ether reception in the smart Contract address only by the Owner
    function () public payable { 
		if(msg.sender != owner) { revert(); }
    }

	// Creator/Owner change name and symbol
    function OWN_ChangeToken(string _name, string _symbol, uint8 _decimals) onlyOwner public {
		name = _name;
        symbol = _symbol;
		decimals = _decimals;
    }

	// Creator/Owner can Locked/Unlock smart contract
    function OWN_contractlocked(bool _locked) onlyOwner public {
        SC_locked = _locked;
    }
	
	// Destroy tokens amount from another account (Caution!!! the operation is destructive and you can not go back)
    function OWN_burnToken(address _from, uint256 _value)  onlyOwner public returns (bool success) {
        require(balances[_from] >= _value);
        balances[_from] -= _value;
        totalSupply -= _value;
        emit Burn(_from, _value);
        return true;
    }
	
	//Generate other tokens after starting the program
    function OWN_mintToken(uint256 mintedAmount) onlyOwner public {
        //aggiungo i decimali al valore che imposto
        balances[owner] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, owner, mintedAmount);
    }
	
	// Block / Unlock address handling tokens
    function OWN_freezeAddress(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
		
	// Function to destroy the smart contract
    function OWN_kill() onlyOwner public { 
		selfdestruct(owner); 
    }
	
	// Function Change Owner
	function OWN_transferOwnership(address newOwner) onlyOwner public {
        // function allowed only if the address is not smart contract
        if (!isContract(newOwner)) {	
			owner = newOwner;
		}
    }
	
	// Smart Contract approved
    function OWN_SmartContract_Allowed(address target, bool _allowed) onlyOwner public {
		// function allowed only for smart contract
        if (isContract(target)) {
			SmartContract_Allowed[target] = _allowed;
		}
    }

	// Distribution Token from Admin
	function OWN_DistributeTokenAdmin_Multi(address[] addresses, uint256 _value, bool freeze) onlyOwner public {
		for (uint i = 0; i < addresses.length; i++) {
			//Block / Unlock address handling tokens
			frozenAccount[addresses[i]] = freeze;
			emit FrozenFunds(addresses[i], freeze);
			
			if (isContract(addresses[i])) {
				transferToContract(addresses[i], _value);
			} 
			else {
				transferToAddress(addresses[i], _value);
			}
		}
	}
}