pragma solidity ^0.4.21;
// Fucking kek that you read the source code 
// Warning this contract has an exit scam.

contract GameState{
    // Vote timer / Buy in round / Lowest gas round / Close time.
    uint256[3] RoundTimes = [(5 minutes), (20 minutes), (10 minutes)]; // 5 20 10
    uint256[3] NextRound = [1,2,0]; // Round flow order. 
    

    // Block external calls altering the game mode. 
//    modifier BlockExtern(){
 //       require(msg.sender==caller);
  //      _;
  //  }
    
    
    uint256 public CurrentGame = 0;
  ///  bool StartedGame = false;
    
    uint256 public Timestamp = 0;
    
    function Timer() internal view returns (bool){
        if (block.timestamp < Timestamp){
       //     StartedGame = false;
            return (true);
        }
        return false;
    }
    
    // FixTimer is only for immediate start rounds 
    // takes last timer and adds stuff to that 
    function Start() internal {
    
        Timestamp = block.timestamp + RoundTimes[CurrentGame];

       // StartedGame=true;
    }
    
    function Next(bool StartNow) internal {
        uint256 NextRoundBuffer = NextRound[CurrentGame];
        if (StartNow){
            //Start();
           // StartedGame = true; 
            Timestamp = Timestamp + RoundTimes[NextRoundBuffer];
        }
        else{
           // StartedGame = false;
        }
        CurrentGame = NextRoundBuffer;
    }
    
 //   function GameState() public {
  //      caller = msg.sender;
  //  }
    
    
    
    // returns bit number n from uint. 
    //function GetByte(uint256 bt, uint256 n) public returns (uint256){
    //    return ((bt >> n) & (1));
   // }
    


}

contract ServiceStation is GameState{
  
    uint256 public Votes = 0;
    uint256 public constant VotesNecessary = 6; // THIS CANNOT BE 1 
    uint256 public constant devFee = 500; // 5%
    
    address owner;
    // Fee address is a contract and is supposed to be used for future projects. 
    // You can buy a dividend card here, which gives you 10% of the development fee. 
    // If someone else buys it, the contract enforces you do make profit by transferring
    // (part of) the cost of the card to you. 
    // It will also pay out all dividends if someone buys the card
    // A withdraw function is also available to withdraw the dividends up to that point. 
    // The way to lose money with this card is if not enough dev fee enters the contract AND no one buys the card. 
    // You can buy it on https://etherguy.surge.sh (if this site is offline, contact me). (Or check contract address and run it in remix to manually buy.)
    address constant fee_address = 0x3323075B8D3c471631A004CcC5DAD0EEAbc5B4D1; 
    
    
    event NewVote(uint256 AllVotes);
    event VoteStarted();
    event ItemBought(uint256 ItemID, address OldOwner, address NewOwner, uint256 NewPrice, uint256 FlipAmount);
    event JackpotChange(uint256 HighJP, uint256 LowJP);
    event OutGassed(bool HighGame, uint256 NewGas, address WhoGassed, address NewGasser);
    event Paid(address Paid, uint256 Amount);
    
    
    modifier OnlyDev(){
        require(msg.sender==owner);
        _;
    }
    
    modifier OnlyState(uint256 id){
        require (CurrentGame == id);
        _;
    }
    
    // OR relation 
    modifier OnlyStateOR(uint256 id, uint256 id2){
        require (CurrentGame == id || CurrentGame == id2);
        _;
    }
    
    // Thanks to TechnicalRise
    // Ban contracts
    modifier NoContract(){
        uint size;
        address addr = msg.sender;
        assembly { size := extcodesize(addr) }
        require(size == 0);
        _;
    }
    
    function ServiceStation() public {
        owner = msg.sender;
    }
    
    // State 0 rules 
    // Simply vote. 
    
    function Vote() public NoContract OnlyStateOR(0,2) {
        bool StillOpen;
        if (CurrentGame == 2){
            StillOpen = Timer();
            if (StillOpen){
                revert(); // cannot vote yet. 
            }
            else{
                Next(false); // start in next lines.
            }
        }
        StillOpen = Timer();
        if (!StillOpen){
            emit VoteStarted();
            Start();
            Votes=0;
        }
        if ((Votes+1)>= VotesNecessary){
            GameStart();
        }
        else{
            Votes++;
        }
        emit NewVote(Votes);
    }
    
    function DevForceOpen() public NoContract OnlyState(0) OnlyDev {
        emit NewVote(VotesNecessary);
        Timestamp = now; // prevent that round immediately ends if votes were long ago. 
        GameStart();
    }
    
    // State 1 rules 
    // Pyramid scheme, buy in for 10% jackpot.
    
    function GameStart() internal OnlyState(0){
        RoundNumber++;
        Votes = 0;
        // pay latest persons if not yet paid. 
        Withdraw();
        Next(true);
        TotalPot = address(this).balance;
    }

    
    uint256 RoundNumber = 0;
    uint256 constant MaxItems = 11; // max id, so max items - 1 please here.
    uint256 constant StartPrice = (0.005 ether);
    uint256 constant PriceIncrease = 9750;
    uint256 constant PotPaidTotal = 8000;
    uint256 constant PotPaidHigh = 9000;
    uint256 constant PreviousPaid = 6500;
    uint256 public TotalPot;
    
    // This stores if you are in low jackpot, high jackpot
    // It uses numbers to keep track how much items you have. 
    mapping(address => bool) LowJackpot;
    mapping(address => uint256) HighJackpot;
    mapping(address => uint256) CurrentRound;
    
    address public LowJackpotHolder;
    address public HighJackpotHolder;
    
    uint256 CurrTimeHigh; 
    uint256 CurrTimeLow;
    
    uint256 public LowGasAmount;
    uint256 public HighGasAmount;
    
    
    struct Item{
        address holder;
        uint256 price;
    }
    
    mapping(uint256 => Item) Market;
    

    // read jackpots 
    function GetJackpots() public view returns (uint256, uint256){
        uint256 PotPaidRound = (TotalPot * PotPaidTotal)/10000;
        uint256 HighJP = (PotPaidRound * PotPaidHigh)/10000;
        uint256 LowJP = (PotPaidRound * (10000 - PotPaidHigh))/10000;
        return (HighJP, LowJP);
    }
    
    function GetItemInfo(uint256 ID) public view returns (uint256, address){
        Item memory targetItem = Market[ID];
        return (targetItem.price, targetItem.holder);
    }
    

    function BuyItem(uint256 ID) public payable NoContract OnlyState(1){
        require(ID <= MaxItems);
        bool StillOpen = Timer();
        if (!StillOpen){
            revert();
            //Next(); // move on to next at new timer; 
            //msg.sender.transfer(msg.value); // return amount. 
            //return; // cannot buy
        }
        uint256 price = Market[ID].price;
        if (price == 0){
            price = StartPrice;
        }
        require(msg.value >= price);
        // excess big goodbye back to owner.
        if (msg.value > price){
            msg.sender.transfer(msg.value-price);
        }
       
        
        // fee -> out 
        
        uint256 Fee = (price * (devFee))/10000;
        uint256 Left = price - Fee;
        
        // send fee to fee address which is a contract. you can buy a dividend card to claim 10% of these funds, see above at "address fee_address"
        fee_address.transfer(Fee);
        
        if (price != StartPrice){
            // pay previous. 
            address target = Market[ID].holder;
            uint256 payment = (price * PreviousPaid)/10000;
            target.transfer (payment);
            
            if (target != msg.sender){
                if (HighJackpot[target] >= 1){
                    // Keep track of how many high jackpot items we own. 
                    // Why? Because if someone else buys your thing you might have another card 
                    // Which still gives you right to do high jackpot. 
                    HighJackpot[target] = HighJackpot[target] - 1;
                }
            }

            //LowJackpotHolder = Market[ID].holder;
            TotalPot = TotalPot + Left - payment;
            
            emit ItemBought(ID, target, msg.sender, (price * (PriceIncrease + 10000))/10000, payment);
        }
        else{
            // Keep track of total pot because we gotta pay people from this later 
            // since people are paid immediately we cannot read this.balance because this decreases
            TotalPot = TotalPot + Left;
            emit ItemBought(ID, address(0x0), msg.sender, (price * (PriceIncrease + 10000))/10000, 0);
        }
        
        uint256 PotPaidRound = (TotalPot * PotPaidTotal)/10000;
        emit JackpotChange((PotPaidRound * PotPaidHigh)/10000, (PotPaidRound * (10000 - PotPaidHigh))/10000);
        
        
        
        // activate low pot. you can claim low pot if you are not in the high jackpot .
        LowJackpot[msg.sender] = true;
        
        // Update price 
        
        price = (price * (PriceIncrease + 10000))/10000;
        
        // 
        if (CurrentRound[msg.sender] != RoundNumber){
            // New round reset count 
            if (HighJackpot[msg.sender] != 1){
                HighJackpot[msg.sender] = 1;
            }
            CurrentRound[msg.sender] = RoundNumber;
            
        }
        else{
            HighJackpot[msg.sender] = HighJackpot[msg.sender] + 1;
        }

        Market[ID].holder = msg.sender;
        Market[ID].price = price;
    }
    
    
    
    
    // Round 2 least gas war 
    
    // returns: can play (bool), high jackpot (bool)
    function GetGameType(address targ) public view returns (bool, bool){
        if (CurrentRound[targ] != RoundNumber){
            // no buy in, reject playing jackpot game 
            return (false,false);
        }
        else{
            
            if (HighJackpot[targ] > 0){
                // play high jackpot 
                return (true, true);
            }
            else{
                if (LowJackpot[targ]){
                    // play low jackpot 
                    return (true, false);
                }
            }
            
            
        }
        // functions should not go here. 
        return (false, false);
    }
    
    
    
    // 
    function BurnGas() public NoContract OnlyStateOR(2,1) {
        bool StillOpen;
       if (CurrentGame == 1){
           StillOpen = Timer();
           if (!StillOpen){
               Next(true); // move to round 2. immediate start 
           }
           else{
               revert(); // gas burn closed. 
           }
       } 
       StillOpen = Timer();
       if (!StillOpen){
           Next(true);
           Withdraw();
           return;
       }
       bool CanPlay;
       bool IsPremium;
       (CanPlay, IsPremium) = GetGameType(msg.sender);
       require(CanPlay); 
       
       uint256 AllPot = (TotalPot * PotPaidTotal)/10000;
       uint256 PotTarget;
       

       
       uint256 timespent;
       uint256 payment;
       
       if (IsPremium){
           PotTarget = (AllPot * PotPaidHigh)/10000;
           if (HighGasAmount == 0 || tx.gasprice < HighGasAmount){
               if (HighGasAmount == 0){
                   emit OutGassed(true, tx.gasprice, address(0x0), msg.sender);
               }
               else{
                   timespent = now - CurrTimeHigh;
                   payment = (PotTarget * timespent) / RoundTimes[2]; // calculate payment and send 
                   HighJackpotHolder.transfer(payment);
                   emit OutGassed(true, tx.gasprice, HighJackpotHolder, msg.sender);
                   emit Paid(HighJackpotHolder, payment);
               }
               HighGasAmount = tx.gasprice;
               CurrTimeHigh = now;
               HighJackpotHolder = msg.sender;
           }
       }
       else{
           PotTarget = (AllPot * (10000 - PotPaidHigh)) / 10000;
           
            if (LowGasAmount == 0 || tx.gasprice < LowGasAmount){
               if (LowGasAmount == 0){
                    emit OutGassed(false, tx.gasprice, address(0x0), msg.sender);
               }
               else{
                   timespent = now - CurrTimeLow;
                   payment = (PotTarget * timespent) / RoundTimes[2]; // calculate payment and send 
                   LowJackpotHolder.transfer(payment);
                   emit OutGassed(false, tx.gasprice, LowJackpotHolder, msg.sender);
                   emit Paid(LowJackpotHolder, payment);
               }
               LowGasAmount = tx.gasprice;
               CurrTimeLow = now;
               LowJackpotHolder = msg.sender;
            }
       }
       
      
       
  
    }
    
    function Withdraw() public NoContract OnlyStateOR(0,2){
        bool gonext = false;
        if (CurrentGame == 2){
            bool StillOpen;
            StillOpen = Timer();
            if (!StillOpen){
                gonext = true;
            }
            else{
                revert(); // no cheats
            }
        }
        uint256 timespent;
        uint256 payment;
        uint256 AllPot = (TotalPot * PotPaidTotal)/10000;
        uint256 PotTarget;
        if (LowGasAmount != 0){
            PotTarget = (AllPot * (10000 - PotPaidHigh))/10000;
            timespent = Timestamp - CurrTimeLow;
            payment = (PotTarget * timespent) / RoundTimes[2]; // calculate payment and send 
            LowJackpotHolder.transfer(payment);     
            emit Paid(LowJackpotHolder, payment);
        }
        if (HighGasAmount != 0){
            PotTarget = (AllPot * PotPaidHigh)/10000;
            timespent = Timestamp - CurrTimeHigh;
            payment = (PotTarget * timespent) / RoundTimes[2]; // calculate payment and send 
            HighJackpotHolder.transfer(payment);
            emit Paid(HighJackpotHolder, payment);
        }
        // reset low gas high gas for next round 
        LowGasAmount = 0;
        HighGasAmount = 0;
        
        // reset market prices. 
        uint8 id; 
        for (id=0; id<MaxItems; id++){
            Market[id].price=0;
        }
        
        if (gonext){
            Next(true);
        }
    }
    
    

    
    // this is added in case something goes wrong 
    // the contract can be funded if any bugs happen when 
    // trying to transfer eth.
    function() payable{
        
    }
    
    
    
    
    
    
}