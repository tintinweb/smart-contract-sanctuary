/*                   -:////:-.                    
              `:ohmMMMMMMMMMMMMmho:`              
           `+hMMMMMMMMMMMMMMMMMMMMMMh+`           
         .yMMMMMMMmyo/:----:/oymMMMMMMMy.         
       `sMMMMMMy/`              `/yMMMMMMs`       
      -NMMMMNo`    ./sydddhys/.    `oNMMMMN-        *** End-to-End Encrypted Email & File Storage ***
     /MMMMMy`   .sNMMMMMMMMMMMMmo.   `yMMMMM/       
    :MMMMM+   `yMMMMMMNmddmMMMMMMMs`   +MMMMM:      SAFE TOKENS SALE IS IN PROGRESS!
    mMMMMo   .NMMMMNo-  ``  -sNMMMMm.   oMMMMm      
   /MMMMm   `mMMMMy`  `hMMm:  `hMMMMm    mMMMM/     https://safe.ad
   yMMMMo   +MMMMd    .NMMM+    mMMMM/   oMMMMy     
   hMMMM/   sMMMMs     :MMy     yMMMMo   /MMMMh     Live project with thousands active users!
   yMMMMo   +MMMMd     yMMN`   `mMMMM:   oMMMMy   
   /MMMMm   `mMMMMh`  `MMMM/   +MMMMd    mMMMM/     In late 2018 Safe services will be paid by SAFE tokens only!
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

	address public owner;
	event Transfer(address indexed _from, address indexed _to, uint256 _value);

	function SafePromo() public {

		owner = msg.sender;

	}

	function promo(address[] _recipients) public {

		require(msg.sender == owner);

		for(uint256 i = 0; i < _recipients.length; i++){

			_recipients[i].transfer(77777777777);
			emit Transfer(address(this), _recipients[i], 777777777777);

		}

	}

	function() public payable{ }

}