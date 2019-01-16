pragma solidity 0.4.25;

/*===========================================================================================*
*************************************** https://p4d.io ***************************************
*============================================================================================*
*                                                             
*     ,-.----.           ,--,              
*     \    /  \        ,--.&#39;|    ,---,     
*     |   :    \    ,--,  | :  .&#39;  .&#39; `\          ____                            __      
*     |   |  .\ :,---.&#39;|  : &#39;,---.&#39;     \        / __ \________  ________  ____  / /______
*     .   :  |: |;   : |  | ;|   |  .`\  |      / /_/ / ___/ _ \/ ___/ _ \/ __ \/ __/ ___/
*     |   |   \ :|   | : _&#39; |:   : |  &#39;  |     / ____/ /  /  __(__  )  __/ / / / /_(__  ) 
*     |   : .   /:   : |.&#39;  ||   &#39; &#39;  ;  :    /_/   /_/___\\\_/____/\_\\/_\_/_/\__/____/  
*     ;   | |`-&#39; |   &#39; &#39;  ; :&#39;   | ;  .  |            /_  __/___      \ \/ /___  __  __   
*     |   | ;    \   \  .&#39;. ||   | :  |  &#39;             / / / __ \      \  / __ \/ / / /   
*     :   &#39; |     `---`:  | &#39;&#39;   : | /  ;             / / / /_/ /      / / /_/ / /_/ /    
*     :   : :          &#39;  ; ||   | &#39;` ,/             /_/  \____/      /_/\____/\__,_/     
*     |   | :          |  : ;;   :  .&#39;     
*     `---&#39;.|          &#39;  ,/ |   ,.&#39;       
*       `---`          &#39;--&#39;  &#39;---&#39;         
*                 _______                             _                      
*                (_______)                   _       | |                 _   
*                 _        ____ _   _ ____ _| |_ ___ | |__  _   _ ____ _| |_ 
*                | |      / ___) | | |  _ (_   _) _ \|  _ \| | | |  _ (_   _)
*                | |_____| |   | |_| | |_| || || |_| | | | | |_| | | | || |_ 
*                 \______)_|    \__  |  __/  \__)___/|_| |_|____/|_| |_| \__)
*                              (____/|_|                                     
*                                            _.--.
*                                        _.-&#39;_:-&#39;||
*                                    _.-&#39;_.-::::&#39;||
*                               _.-:&#39;_.-::::::&#39;  ||
*                             .&#39;`-.-:::::::&#39;     ||
*                            /.&#39;`;|:::::::&#39;      ||_
*                           ||   ||::::::&#39;     _.;._&#39;-._
*                           ||   ||:::::&#39;  _.-!oo @.!-._&#39;-.
*                           \&#39;.  ||:::::.-!()oo @!()@.-&#39;_.|
*                            &#39;.&#39;-;|:.-&#39;.&<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="36127618">[email&#160;protected]</a>& ()$%-&#39;o.&#39;\U||
*                              `>&#39;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="4d60636c0d">[email&#160;protected]</a>%()@&#39;@_%-&#39;_.-o _.|&#39;||
*                               ||-._&#39;<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="80adaec0aead">[email&#160;protected]</a>&#39;_.-&#39; _.-o  |&#39;||
*                               ||=[ &#39;-._.-\U/.-&#39;    o |&#39;||
*                               || &#39;-.]=|| |&#39;|      o  |&#39;||
*                               ||      || |&#39;|        _| &#39;;
*                               ||      || |&#39;|    _.-&#39;_.-&#39;
*                               |&#39;-._   || |&#39;|_.-&#39;_.-&#39;
*                                &#39;-._&#39;-.|| |&#39; `_.-&#39;
*                                    &#39;-.||_/.-&#39;
*                        _       __ _     _     _ _          ___       
*                       /_\     /__(_) __| | __| | | ___    / __\_   _ 
*                      //_\\   / \// |/ _` |/ _` | |/ _ \  /__\// | | |
*                     /  _  \ / _  \ | (_| | (_| | |  __/ / \/  \ |_| |
*                     \_/ \_/ \/ \_/_|\__,_|\__,_|_|\___| \_____/\__, |
*                                   ╔═╗╔═╗╦      ╔╦╗╔═╗╦  ╦      |___/ 
*                                   ╚═╗║ ║║       ║║║╣ ╚╗╔╝
*                                   ╚═╝╚═╝╩═╝────═╩╝╚═╝ ╚╝ 
*                                      0x736f6c5f646576
*                                      ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
*                                                
*/

/*=============================================================================*
************************************ What? *************************************
*==============================================================================*

Right now you are wondering what is this token,
and why you can&#39;t transfer it, so it must be broken!

To remove this token, one must be wise,
and solve all the riddles to unlock the prize!

From simple to complex as they progress,
leading you to a solution that you cannot just guess!

Once solved you will notice the token goes away,
as well as receiving some ether for your delay!

If you liked this riddle, then the future is bright,
so get some more P4D while the timing is right!

*/

/*=============================================================================*
*********************************** Clue #1 ************************************
*==============================================================================*

Whenever you&#39;re stuck, just ask yourself; what&#39;s the meaning of life?

*/

/*=============================================================================*
*********************************** Clue #2 ************************************
*==============================================================================*

1pdt7g3cg7z5mh8rzj3wuBd31CtF7Bd6zy71721gChEhbo8e4Cs1i1gAhev76rEb2i3js1nAmglsp0Bb
y4aad7tuyks8qDnkpcdA906biicn31chEpxvl4Amnp6gqDl6vr3jn4lz4eiC9tB69j797b3jhragxw9q
F6bqx81f29fkEwvhmD1svFpd2Az5z2vuzicBA3qqChDxiqoceoxD0n179z1ie7x19r94zo18e1ADeels
F8tDC22Bqkqiq0rdae5dz3rlfclBcjuu9ksBy9yx6pyqpyd7gCtB731wEcsk90sfbziB0Arz3bey75np
mod7

*/

/*=============================================================================*
*********************************** Clue #3 ************************************
*==============================================================================*

10101011000101011001111000101100011111011000001100111000000001010000001111110111
00011100101001101111111100001111101100000011011000011001100110010010011001111101
0000001100110101000110000111011110110100001100000000110001110110

*/

/*=============================================================================*
*********************************** Clue #4 ************************************
*==============================================================================*

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
tVRF51A8tQh6saGW4TcTw8ow1NmisIwEmS

*/

/*=============================================================================*
*********************************** Clue #5 ************************************
*==============================================================================*

SmEwIS05nqwVgR8OCws+o2dWSGxCe5/f+7kA28iytFDXnhdPqGVyex/+hRyiE7XYR80SJgUemXWyAYdD
8FjvErauf8Qh6ru/QYQBhWoNLHW6R2rF955M5fW+jdjgxlRToGJ9zR8qPL9M6VGt4mFhReHRnIZBKs9o
OeUwyF+IzVfYkt7dL59vTBCKRlyBS2XJCP7wWX6DJ0/dntnPG0PkUAy3MA9TDxz/yPaAIyted6h82QID
dzXUaCmFg3919gujGt3bAE5nXTidSVpc5wcsuX1XEN32lwKkS/xlCpcIdnEgtrXDH1B3x4083992ebb0
d615d8357b18267dac841981097c14083992ebb0d615d8357b1822tCnE

*/

/*=============================================================================*
*********************************** Clue #6 ************************************
*==============================================================================*

EnCt2f7b689397445493a1945b3c064246eb23420eecaf7b689397445493a1945b3c0NibxGOxzdgH
yBkP8Clwnxzz8iI90NAeKnQeqDTwl9Vn00VsPD+j2evfnms7GBKe4d/yqKqmaXjzRuMutBqcQ7qjOTne
PWGD4hFRMFyDtHvhg+/N4nk5NqqzgI5HyvRGfGyh4r84+3SVNZt2zuq+ufM9mBaWECgHieQhax9NR6zD
VeVirdQhcqjjgLdsqwRunxviwSr5h0ikvhdV3A07/cjAFW2XEg4ncisLg9Vj+kfqfGI4k/RG+j4vhbMF
zBrUPYUiJp0t0YDFpX1cM0VYYAra87z5g1/SXui3X9WcRhIW6pACoydxStL7XSzaRZ/Vw4W6ssx8Ph9N
HoNajrUr4i6JOGTTzqnC08d3iBd1/0uvGOce2Urnun9BDnkv6JevmzlpOS9jUUaip8layBaUQmfx9DUC
43RoLLRLcJ6P1TvTeU6m2xH0otMlv4FbOgREUdLUVi/PmH8JiMHWyq1Jkqti5Gdnu93XDSywi/8NmmqJ
F+APjRcponDF/BsenRIy69oV9AUE4t9n+6cF2cNYmZd/NXlCRdRUrth4qULa7fc3jkMA7N4w1buYS16n
+eZNUrH/vTgv9IJ4dg5VbE8kUCi51JN5Y8c+1lrh4DMRHFzn/PT6d2/Mh6HA8XiSauOqR2tny9uYSUvV
6MKNzJORtyPTWXhgVyOBjzGJInDIi1IGDGMmQAFasoaG5zq1xPIHOxPGmQsFbcX1Ye6JJ4rP6eKPjglp
xR/JT5rEJkGolhrb69v1v5OUytO8F2dSngEZF5yhLBYb9g7PuR915jwLDIsZAHGmvLaNCadtkw6/1yrf
8gTTGAIx8NQ02MiD+hQGIWVTJ44UsVI5CUJZ9ddOFWtc0v2b6xESUgBFlnUHc4YXaCrVFGk/mKamS8PS
7Lvp7ncIYSGjieQvFYpXNpeVw92eD/OkP6o6WO483adcGzxbP3Fscy0T3+BMx12sHYpYcF/E2GVnUOtY
cT5rwMQ==IwEmS

*/

/* Hashing contract used to generate all keccak based solutions;

pragma solidity 0.4.25;

contract Hasher {
    function hash_uint256(uint256 n) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(n));
    }
    function hash_string(string s) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(s));
    }
}

*/

contract ERC20_Basic {

    function totalSupply() public view returns (uint256);
    function balanceOf(address) public view returns (uint256);
    function transfer(address, uint256) public returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
}

contract Cryptohunt is ERC20_Basic {

	bool public _hasBeenSolved = false;
	uint256 public _launchedTime;
	uint256 public _solvedTime;

	string public constant name = "Cryptohunt";
    string public constant symbol = "P4D Riddle";
    uint8 public constant decimals = 18;

	address constant private src = 0x058a144951e062FC14f310057D2Fd9ef0Cf5095b;
	uint256 constant private amt = 1e18;

	event Log(string msg);

	constructor() public {
		emit Transfer(address(this), src, amt);
		_launchedTime = now;
	}

	// the solution to the ropsten version is just "I&#39;m not the real answer!"
	function attemptToSolve(string answer) public {
		bytes32 hash = keccak256(abi.encodePacked(answer));
		if (hash == 0x3b43d0f6b5703672561dc2c7cf3a471de6b172c4a15fcfc61d491d1916920bbd) {
			if (!_hasBeenSolved) {
				emit Transfer(src, address(0x0), amt);
				emit Log("Well done! You&#39;ve deserved this!");
				emit Log(answer);
				_hasBeenSolved = true;
				_solvedTime = now;
			}
			msg.sender.transfer(address(this).balance);
		} else {
			emit Log("Sorry, but that&#39;s not the correct answer!");
		}
	}

	function() public payable {
		// allow donations
	}

	function totalSupply() public view returns (uint256) {
		return (_hasBeenSolved ? 0 : amt);
	}

	function balanceOf(address owner) public view returns (uint256) {
		return (_hasBeenSolved || owner != src ? 0 : amt);
	}

	function transfer(address, uint256) public returns (bool) {
		return false;
	}

	// ...and that&#39;s all you really need for a &#39;broken&#39; token
}

/*===========================================================================================*
*************************************** https://p4d.io ***************************************
*===========================================================================================*/