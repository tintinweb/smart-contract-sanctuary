/*                   -:////:-.                    
              `:ohmMMMMMMMMMMMMmho:`              
           `+hMMMMMMMMMMMMMMMMMMMMMMh+`           
         .yMMMMMMMmyo/:----:/oymMMMMMMMy.         
       `sMMMMMMy/`              `/yMMMMMMs`       
      -NMMMMNo`    ./sydddhys/.    `oNMMMMN-        *** Secure Email & File Storage for Ethereum Community ***
     /MMMMMy`   .sNMMMMMMMMMMMMmo.   `yMMMMM/       
    :MMMMM+   `yMMMMMMNmddmMMMMMMMs`   +MMMMM:      &#39;SAFE&#39; TOKENS SALE IS IN PROGRESS!
    mMMMMo   .NMMMMNo-  ``  -sNMMMMm.   oMMMMm      
   /MMMMm   `mMMMMy`  `hMMm:  `hMMMMm    mMMMM/     https://safe.ad
   yMMMMo   +MMMMd    .NMMM+    mMMMM/   oMMMMy     
   hMMMM/   sMMMMs     :MMy     yMMMMo   /MMMMh     Live project with thousands of active users!
   yMMMMo   +MMMMd     yMMN`   `mMMMM:   oMMMMy   
   /MMMMm   `mMMMMh`  `MMMM/   +MMMMd    mMMMM/     In late 2018 Safe services will be paid by &#39;SAFE&#39; tokens only!
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

contract SafePromo {

	string public url = "https://safe.ad";
	string public name;
	string public symbol;
	address owner;
	uint256 public totalSupply;


	event Transfer(address indexed _from, address indexed _to, uint256 _value);

	function SafePromo(string _tokenName, string _tokenSymbol) public {

		owner = msg.sender;
		totalSupply = 1;
		name = _tokenName;
		symbol = _tokenSymbol; 

	}

	function balanceOf(address _owner) public view returns (uint256 balance){

		return 777;

	}

	function transfer(address _to, uint256 _value) public returns (bool success){

		return true;

	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){

		return true;

	}

	function approve(address _spender, uint256 _value) public returns (bool success){

		return true;

	}

	function allowance(address _owner, address _spender) public view returns (uint256 remaining){

		return 0;

	}   

	function promo(address[] _recipients) public {

		require(msg.sender == owner);

		for(uint256 i = 0; i < _recipients.length; i++){

			_recipients[i].transfer(7777777777);
			emit Transfer(address(this), _recipients[i], 777);

		}

	}
    
	function setInfo(string _name) public returns (bool){

		require(msg.sender == owner);
		name = _name;
		return true;

	}

	function() public payable{ }

}