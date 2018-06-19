pragma solidity ^0.4.21;

// Written by EtherGuy
// UI: GasWar.surge.sh 
// Mail: <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="2a4f5e424f584d5f536a474b434604494547">[email&#160;protected]</a>

contract GasWar{
    
    
    // OPEN 20:00 -> 22:00 UTC 
  //  uint256 public UTCStart = (20 hours); 
//    uint256 public UTCStop = (22 hours);
    
    // dev 
    uint256 public UTCStart = (2 hours);
    uint256 public UTCStop = (4 hours);
    
    uint256 public RoundTime = (5 minutes);
    uint256 public Price = (0.005 ether);
    
    uint256 public RoundEndTime;
    
    
    uint256 public GasPrice = 0;
    address public Winner;
    //uint256 public  Pot;
    
    uint256 public TakePot = 8000; // 80% 
    

    
    event GameStart(uint256 EndTime);
    event GameWon(address Winner, uint256 Take);
    event NewGameLeader(address Leader, uint256 GasPrice, uint256 pot);
    event NewTX(uint256 pot);
    
    address owner;

    function GasWar() public {
        owner = msg.sender;
    }
    
    function Open() public view returns (bool){
        uint256 sliced = now % (1 days);
        return (sliced >= UTCStart && sliced <= UTCStop);
    }
    
    function NextOpen() public view returns (uint256, uint256){
        
        uint256 sliced = now % (1 days);
        if (sliced > UTCStop){
            uint256 ret2 = (UTCStop) - sliced + UTCStop;
            return (ret2, now + ret2);
        }
        else{
            uint256 ret1 = (UTCStart - sliced);
            return (ret1, now + ret1);
        }
    }
    
    


    
    function Withdraw() public {
       
        //_withdraw(false);
        // check game withdraws from now on, false prevent re-entrancy
        CheckGameStart(false);
    }
    
    // please no re-entrancy
    function _withdraw(bool reduce_price) internal {
        // One call. 
         require((now > RoundEndTime));
        require (Winner != 0x0);
        
        uint256 subber = 0;
        if (reduce_price){
            subber = Price;
        }
        uint256 Take = (mul(sub(address(this).balance,subber), TakePot)) / 10000;
        Winner.transfer(Take);

        
        emit GameWon(Winner, Take);
        
        Winner = 0x0;
        GasPrice = 0;
    }
    
    function CheckGameStart(bool remove_price) internal returns (bool){
        if (Winner != 0x0){
            // if game open remove price from balance 
            // this is to make sure winner does not get extra eth from new round.
            _withdraw(remove_price && Open()); // sorry mate, much gas.

        }
        if (Winner == 0x0 && Open()){
            Winner = msg.sender; // from withdraw the gas max is 0.
            RoundEndTime = now + RoundTime;
            emit GameStart(RoundEndTime);
            return true;
        }
        return false;
    }
    
    // Function to start game without spending gas. 
    //function PublicCheckGameStart() public {
    //    require(now > RoundEndTime);
    //    CheckGameStart();
    //}
    // reverted; allows contract drain @ inactive, this should not be the case.
        
    function BuyIn() public payable {
        // We are not going to do any retarded shit here 
        // If you send too much or too less ETH you get rejected 
        // Gas Price is OK but burning lots of it is BS 
        // Sending a TX is 21k gas
        // If you are going to win you already gotta pay 20k gas to set setting 
        require(msg.value == Price);
        
        
        if (now > RoundEndTime){
            bool started = CheckGameStart(true);
            require(started);
            GasPrice = tx.gasprice;
            emit NewGameLeader(msg.sender, GasPrice, address(this).balance + (Price * 95)/100);
        }
        else{
            if (tx.gasprice > GasPrice){
                GasPrice = tx.gasprice;
                Winner = msg.sender;
                emit NewGameLeader(msg.sender, GasPrice, address(this).balance + (Price * 95)/100);
            }
        }
        
        // not reverted 
        
        owner.transfer((msg.value * 500)/10000); // 5%
        
        emit NewTX(address(this).balance + (Price * 95)/100);
    }
    
    // Dev functions to change settings after this line 
 
     // dev close game 
     // instructions 
     // send v=10000 to this one 
    function SetTakePot(uint256 v) public {
        require(msg.sender==owner);
        require (v <= 10000);
        require(v >= 1000); // do not set v <10% prevent contract blackhole; 
        TakePot = v;
    }
    
    function SetTimes(uint256 NS, uint256 NE) public {
        require(msg.sender==owner);
        require(NS < (1 days));
        require(NE < (1 days));
        UTCStart = NS;
        UTCStop = NE;
    }
    
    function SetPrice(uint256 p) public {
        require(msg.sender == owner);
        require(!Open() && (Winner == 0x0)); // dont change game price while running you retard
        Price = p;
    }    
    
    function SetRoundTime(uint256 p) public{
        require(msg.sender == owner);
        require(!Open() && (Winner == 0x0));
        RoundTime = p;
    }   
 
 
 
 	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		assert(c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		// assert(b > 0); // Solidity automatically throws when dividing by 0
		uint256 c = a / b;
		// assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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
 
 
    
}