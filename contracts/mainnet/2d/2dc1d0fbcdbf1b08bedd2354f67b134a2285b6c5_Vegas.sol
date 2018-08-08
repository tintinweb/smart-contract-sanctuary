pragma solidity ^0.4.21;

// EtherVegas V3 
// Updates: time is now a hard reset and is based on the price you buy with minimum 
// Name feature introduced plus quotes [added to UI soon]
// Poker feature added, pays about ~4/25 of entire collected pot currently 
// can be claimed multiple times (by other users). Last poker winner gets 
// remaining pot when complete jackpot is paid out 

// HOST: ethlasvegas.surge.sh 
// Made by EtherGuy 
// Questions or suggestions? <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="b4d1c0dcd1c6d3c1cdf4d9d5ddd89ad7dbd9">[email&#160;protected]</a> 

contract RNG{
     uint256 secret = 0;
     
    // Thanks to TechnicalRise
    // Ban contracts
    modifier NoContract(){
        uint size;
        address addr = msg.sender;
        assembly { size := extcodesize(addr) }
        require(size == 0);
        _;
    }
    
    function RNG() public NoContract{
        secret = uint256(keccak256(block.coinbase));
    }
    
    function _giveRNG(uint256 modulo, uint256 secr) private view returns (uint256, uint256){
        uint256 seed1 = uint256(block.coinbase);
        uint256 seed3 = secr; 
        uint256 newsecr = (uint256(keccak256(seed1,seed3)));
        return (newsecr % modulo, newsecr);
    }
    

    function GiveRNG(uint256 max) internal NoContract returns (uint256){
        uint256 num;
        uint256 newsecret = secret;

        (num,newsecret) = _giveRNG(max, newsecret);
        secret=newsecret;
        return num; 
    }
    

}

contract Poker is RNG{
    // warning; number 0 is a non-existing card; means empty;

    uint8[5] public HouseCards;
    
    mapping(address => uint8[2]) public PlayerCards;
    mapping(address => uint256) public PlayerRound;
    
    uint256 public RoundNumber;
    
    uint8[6] public WinningHand; // tracks winning hand. ID 1 defines winning level (9=straight flush, 8=4 of a kind, etc) and other numbers 
    address  public PokerWinner;
    
    uint8[2] public WinningCards;
    // define the other cards which might play in defining the winner. 

    function GetCardNumber(uint8 rank, uint8 suit) public pure returns (uint8){
        if (rank==0){
            return 0;
        }
        
        return ((rank-1)*4+1)+suit;
    }
    
    function GetPlayerRound(address who) public view returns (uint256){
        return PlayerRound[who];
    }
    
    
    
    function GetCardInfo(uint8 n) public pure returns (uint8 rank, uint8 suit){
        if (n==0){
            return (0,0);
        }
        suit = (n-1)%4;
        rank = (n-1)/4+1;
    }
    
   // event pushifo(uint8, uint8, uint8,uint8,uint8);
    // resets game 
    function DrawHouse() internal{
        // Draw table cards 
        uint8 i;
        uint8 rank;
        uint8 suit;
        uint8 n;
        for (i=0; i<5; i++){
            rank = uint8(GiveRNG(13)+1);
            suit = uint8(GiveRNG(4));
            n = GetCardNumber(rank,suit);
            HouseCards[i]=n;
        }

        uint8[2] storage target = PlayerCards[address(this)];
        for (i=0; i<2; i++){
            rank = uint8(GiveRNG(13)+1);
            suit = uint8(GiveRNG(4));
            n = GetCardNumber(rank,suit);

            target[i]=n;

        }
        
        WinningHand = RankScore(address(this));
        WinningCards=[target[0],target[1]];
        PokerWinner= address(this);
    }
    
    event DrawnCards(address player, uint8 card1, uint8 card2);
    function DrawAddr() internal {
        uint8 tcard1;
        uint8 tcard2;
        for (uint8 i=0; i<2; i++){
            uint8 rank = uint8(GiveRNG(13)+1);
            uint8 suit = uint8(GiveRNG(4));
            uint8 n = GetCardNumber(rank,suit);
            
            if (i==0){
                tcard1=n;
            }
            else{
                tcard2=n;
            }

            PlayerCards[msg.sender][i]=n;

        }
        
        if (PlayerRound[msg.sender] != RoundNumber){
            PlayerRound[msg.sender] = RoundNumber;
        }
        emit DrawnCards(msg.sender,tcard1, tcard2);
    }
    
    function GetPlayerCards(address who) public view NoContract returns (uint8, uint8){
        uint8[2] memory target = PlayerCards[who];
        
        return (target[0], target[1]);
    }

    function GetWinCards() public view returns (uint8, uint8){
        return (WinningCards[0], WinningCards[1]);
    }
    
    
    
    // welp this is handy 
    struct Card{
        uint8 rank;
        uint8 suit;
    }
    
    // web 
  //  function HandWinsView(address checkhand) view returns (uint8){
    //    return HandWins(checkhand);
    //}
    
    
    function HandWins(address checkhand) internal returns (uint8){
        uint8 result = HandWinsView(checkhand);
        
        uint8[6] memory CurrScore = RankScore(checkhand);
            
        uint8[2] memory target = PlayerCards[checkhand];
        
        if (result == 1){
            WinningHand = CurrScore;
            WinningCards= [target[0],target[1]];
            PokerWinner=msg.sender;
            // clear cards 
            //PlayerCards[checkhand][0]=0;
            //PlayerCards[checkhand][1]=0;
        }
        return result;
    }
    
    // returns 0 if lose, 1 if win, 2 if equal 
    // if winner found immediately sets winner values 
    function HandWinsView(address checkhand) public view returns (uint8){ 
        if (PlayerRound[checkhand] != RoundNumber){
            return 0; // empty cards in new round. 
        }
        uint8[6] memory CurrentWinHand = WinningHand;
        
        uint8[6] memory CurrScore = RankScore(checkhand);
        
        
        uint8 ret = 2;
        if (CurrScore[0] > CurrentWinHand[0]){
 
            return 1;
        }
        else if (CurrScore[0] == CurrentWinHand[0]){
            for (uint i=1; i<=5; i++){
                if (CurrScore[i] >= CurrentWinHand[i]){
                    if (CurrScore[i] > CurrentWinHand[i]){

                        return 1;
                    }
                }
                else{
                    ret=0;
                    break;
                }
            }
        }
        else{
            ret=0;
        }
        // 2 is same hand. commented out in pay mode 
        // only winner gets pot. 
        return ret;
    }
    
    

    function RankScore(address checkhand) internal view returns (uint8[6] output){
      
        uint8[4] memory FlushTracker;
        uint8[14] memory CardTracker;
        
        uint8 rank;
        uint8 suit;
        
        Card[7] memory Cards;
        
        for (uint8 i=0; i<7; i++){
            if (i>=5){
                (rank,suit) = GetCardInfo(PlayerCards[checkhand][i-5]);
                FlushTracker[suit]++;
                CardTracker[rank]++;
                Cards[i] = Card(rank,suit);
            }
            else{
                (rank,suit) = GetCardInfo(HouseCards[i]);
                FlushTracker[suit]++;
                CardTracker[rank]++;
                Cards[i] = Card(rank,suit);
            }
        }
        
        uint8 straight = 0;
        // skip all zero&#39;s
        uint8[3] memory straight_startcard;
        for (uint8 startcard=13; i>=5; i--){
            if (CardTracker[startcard] >= 1){
                for (uint8 currcard=startcard-1; currcard>=(startcard-4); currcard--){
                    if (CardTracker[currcard] >= 1){
                        if (currcard == (startcard-4)){
                            // at end, straight 
                            straight_startcard[straight] = startcard;
                            straight++;
                        }
                    }
                    else{
                        break;
                    }
                }
            }
        }
        
        uint8 flush=0;

        for (i=0;i<=3;i++){
            if (FlushTracker[i]>=5){
                flush=i;
                break;
            }
        }
        
        // done init. 
        
        // straight flush? 
        
        
        
        if (flush>0 && straight>0){
            // someone has straight flush? 
            // level score 9 
            output[0] = 9;
            currcard=0;
            for (i=0; i<3; i++){
                startcard=straight_startcard[i];
                currcard=5; // track flush, num 5 is standard.    
                for (rank=0; i<7; i++){
                    if (Cards[i].suit == flush && Cards[i].rank <= startcard && Cards[i].rank>=(startcard-4)){
                        currcard--;
                        if (currcard==0){
                            break;
                        }
                    }
                }
                if (currcard==0){
                    // found straight flush high. 
                    output[1] = straight_startcard[i]; // save the high card 
                    break;
                }
            }
            
            return output; 
        }
        
        // high card 
        
        //reuse the rank variable to sum cards; 
        rank=0;
        for (i=13;i>=1;i--){
            rank = rank + CardTracker[i];
            if (CardTracker[i] >= 4){
                output[0] = 8; // high card 
                output[1] = i; // the type of card 
                return output;
            }
            if (rank >=4){
                break;
            }
        }
        
        // full house 
        
        rank=0; // track 3-kind 
        suit=0; // track 2-kind 
        startcard=0;
        currcard=0;
        
        for (i=13;i>=1;i--){
            if (rank == 0 && CardTracker[i] >= 3){
                rank = i;
            }
            else if(CardTracker[i] >= 2){
                if (suit == 0){
                    suit = CardTracker[i];
                }
                else{
                    // double nice 
                    if (startcard==0){
                        startcard=CardTracker[i];
                    }
                }
            }
        }
        
        if (rank != 0 && suit != 0){
            output[0] = 7;
            output[1] = rank; // full house tripple high 
            output[2] = suit; // full house tripple low 
            return output;
        }
        
        if (flush>0){
            // flush 
            output[0] = 6;
            output[1] = flush;
            return output;
            
        }
        
        if (straight>0){
            //straight 
            output[0] = 5;
            output[1] = straight_startcard[0];
            return output;
        }
        
        if (rank>0){
            // tripple 
            output[0]=4;
            output[1]=rank;
            currcard=2; // track index; 
            // get 2 highest cards 
            for (i=13;i>=1;i--){
                if (i != rank){
                    if (CardTracker[i] > 0){
                        // note at three of a kind we have no other doubles; all other ranks are different so no check > 1 
                        output[currcard] = i;
                        currcard++;
                        if(currcard==4){
                            return output;
                        }
                    }
                }
            }
        }
        
        if (suit > 0 && startcard > 0){
            // double pair 
            output[0] = 3;
            output[1] = suit;
            output[2] = startcard;
            // get highest card 
            for (i=13;i>=1;i--){
                if (i!=suit && i!=startcard && CardTracker[i]>0){
                    output[3]=i;
                    return output;
                }
            }
        }
        
        if (suit > 0){
            // pair 
            output[0]=2;
            output[1]=suit;
            currcard=2;
            // fill 3 other positions with high cards. 
            for (i=13;i>=1;i--){
                if (i!=suit && CardTracker[i]>0){
                    output[currcard]=i;
                    currcard++;
                    if(currcard==5){
                        return output;
                    }
                }   
            }
        }
        
        // welp you are here now, only have high card?
        // boring 
        output[0]=1;
        currcard=1;
        for (i=13;i>=1;i--){
            if (CardTracker[i]>0){
                output[currcard]=i;
                currcard++;
                if (currcard==6){
                    return output;
                }
            }
        }
    }
    
}

contract Vegas is Poker{
    address owner;
    address public feesend;
    
    
    uint256 public Timer;
    
    uint8 constant MAXPRICEPOWER = 40; // < 255
    
    address public JackpotWinner;
    
    uint16 public JackpotPayout = 8000; 
    uint16 public PokerPayout = 2000;
    uint16 public PreviousPayout = 6500;
    uint16 public Increase = 9700;
    uint16 public Tax = 500;
    uint16 public PotPayout = 8000;
    
    uint256 public BasePrice = (0.005 ether);
    
    uint256 public TotalPot;
    uint256 public PokerPayoutValue;
    
    // mainnet 
    uint256[9] TimeArray = [uint256(6 hours), uint256(3 hours), uint256(2 hours), uint256(1 hours), uint256(50 minutes), uint256(40 minutes), uint256(30 minutes), uint256(20 minutes), uint256(15 minutes)];
    // testnet 
    //uint256[3] TimeArray = [uint256(3 minutes), uint256(3 minutes), uint256(2 minutes)];
    
    struct Item{
        address Holder;
        uint8 PriceID;
    }
    
    Item[16] public Market;
    
    uint8 public MaxItems = 12; // max ID, is NOT index but actual max items to buy. 0 means really nothing, not 1 item 
    
    event ItemBought(uint256 Round, uint8 ID,  uint256 Price, address BoughtFrom, address NewOwner, uint256 NewTimer, uint256 NewJP, string Quote, string Name);
    // quotes here ? 
    event PokerPaid(uint256 Round, uint256 AmountWon, address Who, string Quote, string Name, uint8[6] WinHand);
    event JackpotPaid(uint256 Round, uint256 Amount,  address Who, string Quote, string Name);
    event NewRound();
    
    bool public EditMode;
    bool public SetEditMode;
    // dev functions 
    
    modifier OnlyOwner(){
        require(msg.sender == owner);
        _;
    }
    
    modifier GameClosed(){
        require (block.timestamp > Timer);
        _;
    }
    

    
    function Vegas() public{
        owner=msg.sender;
        feesend=0xC1086FA97549CEA7acF7C2a7Fa7820FD06F3e440;
        // withdraw also setups new game. 
        // pays out 0 eth of course to owner, no eth in contract. 
        Timer = 1; // makes sure withdrawal runs
        //Withdraw("Game init", "Admin");
    }
    
    // all contract calls are banned from buying 
    function Buy(uint8 ID, string Quote, string Name) public payable NoContract {
        require(ID < MaxItems);
        require(!EditMode);
        // get price 
        //uint8 pid = Market[ID].PriceID;
        uint256 price = GetPrice(Market[ID].PriceID);
        require(msg.value >= price);
        
        if (block.timestamp > Timer){
            if (Timer != 0){ // timer 0 means withdraw is gone; withdraw will throw on 0
                Withdraw("GameInit", "Admin");
                return;
            }
        }
        
        // return excess 
        if (msg.value > price){
            msg.sender.transfer(msg.value-price);
        }
        
        uint256 PayTax = (price * Tax)/10000;
        feesend.transfer(PayTax);
        uint256 Left = (price-PayTax);
        
        
        if (Market[ID].PriceID!=0){
            // unzero, move to previous owner
            uint256 pay = (Left*PreviousPayout)/10000;
            TotalPot = TotalPot + (Left-pay);
           // Left=Left-pay;
            Market[ID].Holder.transfer(pay);
        }
        else{
            TotalPot = TotalPot + Left;
        }
        
        // reset timer; 
        Timer = block.timestamp + GetTime(Market[ID].PriceID);
        //set jackpot winner 
        JackpotWinner = msg.sender;


        // give user new card; 
        
        emit ItemBought(RoundNumber,ID,  price,  Market[ID].Holder, msg.sender, Timer,  TotalPot,  Quote, Name);
        
        DrawAddr(); // give player cards
        
        // update price 
        Market[ID].PriceID++;
        //set holder 
        Market[ID].Holder=msg.sender;
    }
    
    function GetPrice(uint8 id) public view returns (uint256){
        uint256 p = BasePrice;
        if (id > 0){
            // max price baseprice * increase^20 is reasonable
            for (uint i=1; i<=id; i++){
                if (i==MAXPRICEPOWER){
                    break; // prevent overflow (not sure why someone would buy at increase^255)
                }
                p = (p * (10000 + Increase))/10000;
            }
        }
        
        return p;
    }
    
    function PayPoker(string Quote, string Name) public NoContract{
        uint8 wins = HandWins(msg.sender);
        if (wins>0){
            uint256 available_balance = (TotalPot*PotPayout)/10000;
            uint256 payment = sub ((available_balance * PokerPayout)/10000 , PokerPayoutValue);
            
            
            
            PokerPayoutValue = PokerPayoutValue + payment;
            if (wins==1){
                msg.sender.transfer(payment);
                emit PokerPaid(RoundNumber, payment, msg.sender,  Quote,  Name, WinningHand);
            }
            /*
            else if (wins==2){
                uint256 pval = payment/2;
                msg.sender.transfer(pval);
                PokerWinner.transfer(payment-pval);// saves 1 wei error 
                emit PokerPaid(RoundNumber, pval, msg.sender,  Quote,  Name, WinningHand);
                emit PokerPaid(RoundNumber, pval, msg.sender, "", "", WinningHand);
            }*/
        }
        else{
            // nice bluff mate 
            revert();
        }
    }
    
    function GetTime(uint8 id) public view returns (uint256){
        if (id >= TimeArray.length){
            return TimeArray[TimeArray.length-1];
        }
        else{
            return TimeArray[id];
        }
    }
    
    //function Call() public {
   //     DrawHouse();
   // }
    
    
    // pays winner. 
    // also sets up new game 
    // winner receives lots of eth compared to gas so a small payment to gas is reasonable.
    
    function Withdraw(string Quote, string Name) public NoContract {
        _withdraw(Quote,Name,false);
    }
    
    // in case there is a revert bug in the poker contract 
    // allows winner to get paid without calling poker. should never be called 
    // follows all normal rules of game .
    function WithdrawEmergency() public OnlyOwner{
        _withdraw("Emergency withdraw call","Admin",true);
    }
    function _withdraw(string Quote, string Name, bool Emergency) NoContract internal {
        // Setup cards for new game. 
        
        require(block.timestamp > Timer && Timer != 0);
        Timer=0; // prevent re-entrancy immediately. 
        
        // send from this.balance 
        uint256 available_balance = (TotalPot*PotPayout)/10000;
        uint256 bal = (available_balance * JackpotPayout)/10000;
        
                    
        JackpotWinner.transfer(bal);
        emit JackpotPaid(RoundNumber, bal,  JackpotWinner, Quote, Name);
        
        // pay the last poker winner remaining poker pot.
        bal = sub(sub(available_balance, bal),PokerPayoutValue);
        if (bal > 0 && PokerWinner != address(this)){
            // this only happens at start game,  some wei error 
            if (bal > address(this).balance){
                PokerWinner.transfer(address(this).balance);
            }
            else{
                PokerWinner.transfer(bal);     
            }
           
            emit PokerPaid(RoundNumber, bal, PokerWinner,  "Paid out left poker pot", "Dealer", WinningHand);
        }
        TotalPot = address(this).balance;
    
        // next poker pot starts at zero. 
        PokerPayoutValue= (TotalPot * PotPayout * PokerPayout)/(10000*10000);

        // reset price 

        for (uint i=0; i<MaxItems; i++){
            Market[i].PriceID=0;
        }
        
        if (!Emergency){
            DrawHouse();
        }
        RoundNumber++;
        // enable edit mode if set by dev.
        EditMode=SetEditMode;
        
        emit NewRound();
    }
    
    // dev edit functions below 
    
    
    function setEditModeBool(bool editmode) public OnlyOwner {
        // start edit mode closes the whole game. 
        SetEditMode=editmode;
        if (!editmode){
            // enable game round.
            EditMode=false;
        }
    }
    
    function emergencyDropEth() public payable{
        // any weird error might be solved by dropping eth (and no this is not even a scam, if contract needs a wei more, we send a wei, get funds out and fix contract)
    }
        
    function editTimer(uint8 ID, uint256 Time) public OnlyOwner GameClosed{
        TimeArray[ID] = Time;
    }
    
    function editBasePrice(uint256 NewBasePrice) public OnlyOwner GameClosed{
        BasePrice = NewBasePrice;  
    }
    
    function editMaxItems(uint8 NewMax) public OnlyOwner GameClosed{
        MaxItems = NewMax;
    }
    
    function editPayoutSetting(uint8 setting, uint16 newv) public OnlyOwner GameClosed{
        require(setting > 0);
        if (setting == 1){
            require(newv <= 10000);
            JackpotPayout = newv;
            PokerPayout = 10000-newv;
        }
        else if (setting == 2){
            require(newv <= 10000);
           
            PokerPayout = newv;
            JackpotPayout = 10000-newv;
        }
        else if (setting == 3){
            require (newv <= 10000);
            PreviousPayout = newv;
        }
        else if (setting == 4){
            require(newv <= 30000);
            Increase = newv;
        }
        else if (setting == 5){
            require(newv <=10000);
            PotPayout = newv;
        }
        else if (setting == 6){
            require(newv < 700);
            Tax = newv;
        }
        else{
            revert();
        }
    }
    
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}