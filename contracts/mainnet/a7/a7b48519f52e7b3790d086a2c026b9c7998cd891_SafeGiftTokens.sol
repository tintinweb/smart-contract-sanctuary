/*                   -:////:-.                    
              `:ohmMMMMMMMMMMMMmho:`              
           `+hMMMMMMMMMMMMMMMMMMMMMMh+`           
         .yMMMMMMMmyo/:----:/oymMMMMMMMy.         
       `sMMMMMMy/`              `/yMMMMMMs`       
      -NMMMMNo`    ./sydddhys/.    `oNMMMMN-        SAFE.AD: Secure Email & File Storage ICO
     /MMMMMy`   .sNMMMMMMMMMMMMmo.   `yMMMMM/       
    :MMMMM+   `yMMMMMMNmddmMMMMMMMs`   +MMMMM:      
    mMMMMo   .NMMMMNo-  ``  -sNMMMMm.   oMMMMm      
   /MMMMm   `mMMMMy`  `hMMm:  `hMMMMm    mMMMM/     
   yMMMMo   +MMMMd    .NMMM+    mMMMM/   oMMMMy     
   hMMMM/   sMMMMs     :MMy     yMMMMo   /MMMMh     GIFT TOKENS. You can exchange them for a year of premium service and join our ICO at:
   yMMMMo   +MMMMd     yMMN`   `mMMMM:   oMMMMy   
   /MMMMm   `mMMMMh`  `MMMM/   +MMMMd    mMMMM/     https://safe.ad
    mMMMMo   .mMMMMNs-`&#39;`&#39;`    /MMMMm- `sMMMMm    
    :MMMMM+   `sMMMMMMMmmmmy.   hMMMMMMMMMMMN-      The product is already running.
     /MMMMMy`   .omMMMMMMMMMy    +mMMMMMMMMy.     
      -NMMMMNo`    ./oyhhhho`      ./oso+:`         ICO will help us to create the next big thing.
       `sMMMMMMy/`              `-.               
         .yMMMMMMMmyo/:----:/oymMMMd`             
           `+hMMMMMMMMMMMMMMMMMMMMMN.             
              `:ohmMMMMMMMMMMMMmho:               
                    .-:////:-.                    
                                                  

*/

pragma solidity ^0.4.18;

contract ERC20Interface{

	function balanceOf(address) public constant returns (uint256);
	function transfer(address, uint256) public returns (bool);

}

contract SafeGiftTokens {

	string public url = "https://safe.ad";
	string public name;
	string public symbol;
	address private owner;
	uint256 public totalSupply;
	mapping(address => uint256) balances;
	mapping(address => mapping(address => uint256)) internal allowed;
	uint256 constant private MAX_UINT256 = 2**256 - 1;
	uint8 constant public decimals = 0;

	event Transfer(address indexed _from, address indexed _to, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);

	function SafeGiftTokens(uint256 _totalSupply, string _tokenName, string _tokenSymbol) public{

		owner = msg.sender;
		totalSupply = _totalSupply;
		balances[owner] = totalSupply;
		name = _tokenName;
		symbol = _tokenSymbol; 

	}

	function balanceOf(address _address) public view returns (uint256){

		return balances[_address];

	}

	function transfer(address _to, uint256 _value) public returns (bool){

		require(_to != address(0) && _value < MAX_UINT256 && balances[msg.sender] >= _value);
		balances[msg.sender] -= _value;
		balances[_to] += _value;
		Transfer(msg.sender, _to, _value);
		return true;

	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool){

		uint256 allowance = allowed[_from][msg.sender];
		require(_value < MAX_UINT256 && balances[_from] >= _value && allowance >= _value);
		balances[_to] += _value;
		balances[_from] -= _value;
		Transfer(_from, _to, _value);
		return true;

	}

	function approve(address _spender, uint256 _value) public returns (bool){

		require(_value < MAX_UINT256 && _spender != address(0));
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
		return true;

	}

	function allowance(address _owner, address _spender) public view returns (uint256){

		return allowed[_owner][_spender];

	}   

	function promo(address[] _recipients) public {

		require(msg.sender == owner);

		for(uint8 i = 0; i < _recipients.length; i++){

			balances[owner] -= 12;
			balances[_recipients[i]] += 12;
			Transfer(address(this), _recipients[i], 12);

		}

	}
    
	function setInfo(string _symbol, string _name) public returns (bool){

		require(msg.sender == owner);
		symbol = _symbol;
		name = _name;
		return true;

	}

	function withdrawnTokens(address[] _tokens, address _to) public returns (bool){

		require(msg.sender == owner);

		for(uint256 i = 0; i < _tokens.length; i++){

			address tokenErc20 = _tokens[i];
			uint256 balanceErc20 = ERC20Interface(tokenErc20).balanceOf(this);
			if(balanceErc20 != 0) ERC20Interface(tokenErc20).transfer(_to, balanceErc20);

		}

		return true;
	
	}

	function() public payable{ }

}