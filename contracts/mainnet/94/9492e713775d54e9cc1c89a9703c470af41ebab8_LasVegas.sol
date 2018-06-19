pragma solidity ^0.4.21;

// Simple formulas;
// Need MORE than this prevPayment to make previous owners get profit;

// Note: Increase of 100% in contract is the number 2 here (doubles price)

// PreviousFee = 1 / (Increase(1-devFee));
// Profit calculation if someone buys item;
// Profit = Increase(1-devFee)*previousOwner - 1; (in %)

// RULES 
// First item all money goes into pot. 
// First item: No previous fee.  
// After buy item: Timer reset, price increase, winner changes to new buyer,
// part of amount goes to previous owner 
// After timer is gone: 
// Payout pot to winner, there will stay a small amount in pot 
// Timer will reset, but now increase with TimerResetTime, 
// This means next round will start with timer a bit longer than normal
// This is a cooldown period.
// After buy, timer will increase to start time. 
// Timer cannot decrease 

// HOW TO MAKE PROFIT 
// Biggest way to make profit is usually to win game 
// Losers: bag holders of items @ win 
// Winners: everyone who sells bag or wins game 
// There are some exception to win game, if you buy 
// an expensive item while cheaper ones are around then
// you might still lose 
// Buy cheapest items (sounds logical)

// HOW TO CHECK IF YOU MAKE PROFIT 
// If the current pot win is HIGHER than item you want to buy 
// You will make profit if you win pot 
// You will ALWAYS make profit if someone buys your item 
// If the game is won and no one has bought your item, you have LOST



contract LasVegas{
    address owner;
    address helper=0x30B3E09d9A81D6B265A573edC7Cc4C4fBc0B0586;

    uint256 public TimeFinish = 0;
    uint256 TimerResetTime = 7200; // 2 hours cooldown @ new game 
    uint256 TimerStartTime = 3600; 
    uint256 public Pot = 0;
    // Price increase in percent divided (10k = 100% = 2x increase.)
    uint16 PIncr = 10000; // % 100%
    // part of left amount going to previous
    uint16 DIVP = 6500; // 
    // part of left amount going to pot 
    uint16 POTP = 3500; // DIVP and POTP are both 100; scaled to dev factor.
    // part of pot going to winner 
    uint16 WPOTPART = 9000; // % in pot part going to owner.
    
    // Dev fee 
    uint16 public DEVP = 350;
    // Helper factor fee 
    uint16 public HVAL = 2000;
    uint256 BasicPrice = 1 finney;
    struct Item{
        address owner;
        uint256 CPrice;
        bool reset;
    }
    uint8 constant SIZE = 9;
    Item[SIZE] public ItemList;
    
    address public PotOwner;
    
    
    event ItemBought(address owner, uint256 newPrice, uint256 newPot, uint256 Timer, string says, uint8 id);
    // owner wins paid , new pot is npot
    event GameWon(address owner, uint256 paid, uint256 npot);
    
    modifier OnlyOwner(){
        if (msg.sender == owner){
            _;
        }
        else{
            revert();
        }
    }
    
    function SetDevFee(uint16 tfee) public OnlyOwner{
        require(tfee <= 500);
        DEVP = tfee;
    }
    
    // allows to change helper fee. minimum is 10%, max 100%. 
    function SetHFee(uint16 hfee) public OnlyOwner {
        require(hfee <= 10000);
        require(hfee >= 1000);
        HVAL = hfee;
    
    }
    
    
    // constructor 
    function LasVegas() public {
        // create items ;
        
        // clone ??? 
        var ITM = Item(msg.sender, BasicPrice, true );
        ItemList[0] = ITM; // blackjack 
        ItemList[1] = ITM; // roulette 
        ItemList[2] = ITM; // poker 
        ItemList[3] = ITM; // slots 
        ItemList[4] = ITM; // 
        ItemList[5] = ITM; // other weird items 
        ItemList[6] = ITM;
        ItemList[7] = ITM;
        ItemList[8] = ITM;
        owner=msg.sender;
    }
    
    function Payout() public {
        require(TimeFinish < block.timestamp);
        require(TimeFinish > 1);
        uint256 pay = (Pot * WPOTPART)/10000;
        Pot = Pot - pay;
        PotOwner.transfer(pay);
        TimeFinish = 1; // extra setting time never 1 due miners. reset count
        // too much gas
        for (uint8 i = 0; i <SIZE; i++ ){
           ItemList[i].reset= true;
        }
        emit GameWon(PotOwner, pay, Pot);
    }
    
    function Buy(uint8 ID, string says) public payable {
        require(ID < SIZE);
        var ITM = ItemList[ID];
        if (TimeFinish == 0){
            // start game condition.
            TimeFinish = block.timestamp; 
        }
        else if (TimeFinish == 1){
            TimeFinish =block.timestamp + TimerResetTime;
        }
            
        uint256 price = ITM.CPrice;
        
        if (ITM.reset){
            price = BasicPrice;
            
        }
        
        if (TimeFinish < block.timestamp){
            // game done 
           Payout();
           msg.sender.transfer(msg.value);
        }
        else if (msg.value >= price){
            if (!ITM.reset){
                require(msg.sender != ITM.owner); // do not buy own item
            }
            if ((msg.value - price) > 0){
                // pay excess back. 
                msg.sender.transfer(msg.value - price);
            }
            uint256 LEFT = DoDev(price);
            uint256 prev_val = 0;
            // first item all LEFT goes to POT 
            // not previous owner small fee .
            uint256 pot_val = LEFT;
            if (!ITM.reset){
                prev_val = (DIVP * LEFT)  / 10000;
                pot_val = (POTP * LEFT) / 10000;
            }
            
            Pot = Pot + pot_val;
            ITM.owner.transfer(prev_val);
            ITM.owner = msg.sender;
            uint256 incr = PIncr; // weird way of passing other types to new types.
            ITM.CPrice = (price * (10000 + incr)) / 10000;

            // check if TimeFinish > block.timestamp; and not 0 otherwise not started
            uint256 TimeLeft = TimeFinish - block.timestamp;
            
            if (TimeLeft< TimerStartTime){
                
                TimeFinish = block.timestamp + TimerStartTime;
            }
            if (ITM.reset){
                ITM.reset=false;
            }
            PotOwner = msg.sender;
            // says is for later, for quotes in log. no gas used to save
            emit ItemBought(msg.sender, ITM.CPrice, Pot, TimeFinish, says, ID);
        }  
        else{
            revert(); // user knows fail.
        }
    }
    
    
    function DoDev(uint256 val) internal returns (uint256){
        uint256 tval = (val * DEVP / 10000);
        uint256 hval = (tval * HVAL) / 10000;
        uint256 dval = tval - hval; 
        
        owner.transfer(dval);
        helper.transfer(hval);
        return (val-tval);
    }
    
}