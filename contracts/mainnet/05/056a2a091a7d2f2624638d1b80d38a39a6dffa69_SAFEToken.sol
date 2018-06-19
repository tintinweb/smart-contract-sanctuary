/*                   -:////:-.                    
              `:ohmMMMMMMMMMMMMmho:`              
           `+hMMMMMMMMMMMMMMMMMMMMMMh+`           
         .yMMMMMMMmyo/:----:/oymMMMMMMMy.         
       `sMMMMMMy/`              `/yMMMMMMs`       
      -NMMMMNo`    ./sydddhys/.    `oNMMMMN-        *** Secure Email & File Storage ***
     /MMMMMy`   .sNMMMMMMMMMMMMmo.   `yMMMMM/       
    :MMMMM+   `yMMMMMMNmddmMMMMMMMs`   +MMMMM:      https://safe.ad
    mMMMMo   .NMMMMNo-  ``  -sNMMMMm.   oMMMMm      
   /MMMMm   `mMMMMy`  `hMMm:  `hMMMMm    mMMMM/     
   yMMMMo   +MMMMd    .NMMM+    mMMMM/   oMMMMy     
   hMMMM/   sMMMMs     :MMy     yMMMMo   /MMMMh     
   yMMMMo   +MMMMd     yMMN`   `mMMMM:   oMMMMy   
   /MMMMm   `mMMMMh`  `MMMM/   +MMMMd    mMMMM/     
    mMMMMo   .mMMMMNs-`&#39;`&#39;`    /MMMMm- `sMMMMm    
    :MMMMM+   `sMMMMMMMmmmmy.   hMMMMMMMMMMMN-      
     /MMMMMy`   .omMMMMMMMMMy    +mMMMMMMMMy.     
      -NMMMMNo`    ./oyhhhho`      ./oso+:`       
       `sMMMMMMy/`              `-.               
         .yMMMMMMMmyo/:----:/oymMMMd`             
           `+hMMMMMMMMMMMMMMMMMMMMMN.             
              `:ohmMMMMMMMMMMMMmho:               
                    .-:////:-.                    
                                                  

*/

pragma solidity ^0.4.18;

/* SAFEToken contract v 1.0 */

contract ERC20Interface{

	function balanceOf(address) public constant returns (uint256);
	function transfer(address, uint256) public returns (bool);

}

contract SAFEToken{

	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	event MintingAgentChanged(address _addr, bool _state);
	event Mint(address indexed _to, uint256 _value);
	event MintFinished();
	event UpdatedTokenInformation(string _newName, string _newSymbol, uint8 _newDecimals);
	event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);
	event TransfersAreAllowed();
	event Error(address indexed _self, uint8 _errorCode);

	uint256 constant private MAX_UINT256 = 2**256 - 1;
	uint8 constant private ERROR_ZERO_ADDRESS = 1;
	uint8 constant private ERROR_INSUFICIENT_BALANCE = 2;
	uint8 constant private ERROR_INSUFICIENT_ALLOWENCE = 3;
	uint8 constant private ERROR_ARRAYS_LENGTH_DIFF = 4;
	uint8 constant private ERROR_INT_OVERFLOW = 5;
	uint8 constant private ERROR_UNAUTHORIZED = 6;
	uint8 constant private ERROR_TRANSFER_NOT_ALLOWED = 7;

	string public name;
	string public symbol;
	uint8 public decimals;
	bool public transfersSuspended = true;
	address owner;
	uint256 totalSupply_ = 0;
	bool mintingFinished = false;
	mapping(address => uint256) balances;
	mapping(address => mapping(address => uint256)) internal allowed;
	mapping(address => bool) mintAgents;

	modifier onlyOwner(){

		require(msg.sender == owner);
		_;

	}

	modifier onlyMintAgent(){

		require(mintAgents[msg.sender]);
		_;

	}

	modifier canMint(){

		require(!mintingFinished);
		_;

	}

	function SAFEToken(uint256 _totalSupply, string _name, string _symbol, uint8 _decimals) public{

		totalSupply_ = _totalSupply;
		owner = msg.sender;
		name = _name;
		symbol = _symbol;
		decimals = _decimals;
		balances[owner] = totalSupply_;

	}
    
	function totalSupply() public view returns (uint256){

		return totalSupply_;

	}

	function transfer(address _to, uint256 _value) public returns (bool){

		if(transfersSuspended) return isError(ERROR_TRANSFER_NOT_ALLOWED);
		if(_to == address(0)) return isError(ERROR_ZERO_ADDRESS);
		if(balances[msg.sender] < _value) return isError(ERROR_INSUFICIENT_BALANCE);
		balances[msg.sender] -= _value;
		balances[_to] += _value;
		Transfer(msg.sender, _to, _value);
		return true;

	}

	function balanceOf(address _owner) public view returns (uint256){

		return balances[_owner];

	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool){

		if(transfersSuspended) return isError(ERROR_TRANSFER_NOT_ALLOWED);
		uint256 allowance = allowed[_from][msg.sender];
		if(balances[_from] < _value) return isError(ERROR_INSUFICIENT_BALANCE);
		if(allowance < _value) return isError(ERROR_INSUFICIENT_ALLOWENCE);
		balances[_to] += _value;
		balances[_from] -= _value;
		if(allowance < MAX_UINT256) allowed[_from][msg.sender] -= _value;
		Transfer(_from, _to, _value);
		return true;

	}

	function approve(address _spender, uint256 _value) public returns (bool success){

		if(transfersSuspended) return isError(ERROR_TRANSFER_NOT_ALLOWED);
		if(_spender == address(0)) return isError(ERROR_ZERO_ADDRESS);
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;

	}

	function allowance(address _owner, address _spender) public view returns (uint256){

		return allowed[_owner][_spender];

	}

	function mint(address[] _receivers, uint256[] _values) public onlyMintAgent canMint returns (bool){

		if(_receivers.length != _values.length) return isError(ERROR_ARRAYS_LENGTH_DIFF);

		for(uint256 i = 0; i < _receivers.length; ++i){

			if(totalSupply_ + _values[i] < totalSupply_) return isError(ERROR_INT_OVERFLOW);
			totalSupply_ += _values[i];

		}
			
		for(i = 0; i < _receivers.length; ++i){

			balances[_receivers[i]] += _values[i];
			Mint(_receivers[i], _values[i]);
			Transfer(address(0), _receivers[i], _values[i]);

		}

		return true;

	}

	function setMintAgent(address _addr, bool _state) onlyOwner canMint public returns (bool){

		if(_addr == address(0)) return isError(ERROR_ZERO_ADDRESS);
		mintAgents[_addr] = _state;
		MintingAgentChanged(_addr, _state);
		return true;

	}

	function finishMinting() onlyOwner canMint public returns (bool){

		mintingFinished = true;
		MintFinished();
		return true;

	}

	function allowTransfers() onlyOwner public returns (bool){

		transfersSuspended = false;
		TransfersAreAllowed();
		return true;

	}

	function changeOwner(address _newOwner) public onlyOwner returns(bool){

		if(_newOwner == address(0)) return isError(ERROR_ZERO_ADDRESS);
		address prevOwner = owner;
		owner = _newOwner;
		OwnershipTransferred(prevOwner, owner);
		return true;

	}
    
	function setTokenInformation(string _name, string _symbol, uint8 _decimals) public onlyOwner returns (bool){

		name = _name;
		symbol = _symbol;
		decimals = _decimals;
		UpdatedTokenInformation(_name, _symbol, _decimals);
		return true;

	}

	function withdrawnTokens(address[] _tokens, address _to) public onlyOwner returns (bool){

		for(uint256 i = 0; i < _tokens.length; i++){

			address token = _tokens[i];
			uint256 balance = ERC20Interface(token).balanceOf(this);
			if(balance != 0) ERC20Interface(token).transfer(_to, balance);

		}

		return true;
	
	}

	function isError(uint8 _error) private returns (bool){

		Error(msg.sender, _error);
		return false;

	}

}