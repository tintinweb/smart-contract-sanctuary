pragma solidity ^0.4.21;

// welcome to EtherWild (EthWild)
// game which is a simple coin toss game, you have 50% chance to win.
// you always play against someone else. 
// there are two ways to play; the auto-way by just placing a bet (only one allowed)
// this is the standard way to play 
// if you place this bet and another one places the same bet, a match occurs and a game is played 
// Note: you are allowed to withdraw these bets. If all offers are cancelled 0 eth is in contract. 

// Offers: 
// You are allowed to create 16 offers in the game. Other people can find these offers and play with them
// This is doable if you do not like the suggested offers, or simply want to put on more games. 
// These are also cancellable. 
// If you play someone&#39;s offer and send to much, excess is returned. 

contract EtherWild{
    // GLOBAL SETTINGS //
    uint8 constant MaxOffersPerADDR = 16; // per definition MAX 32 offers due to uint8 size
    uint16 CFee = 500; // FEE / 10000 , only paid per PLAYED TX. Cancel / create offer is no fee, only paid after play
    uint16 HFeePart = 5000; // Part of creator fee -> helper /10000 -> 50%
    
    address Owner;
    address HelpOwner = 0x30B3E09d9A81D6B265A573edC7Cc4C4fBc0B0586;
    
    // SETTING BIT CONFIG: 
    // First two bits: Owner choice of offer. 0 means offer is closed (standard) to prevent double-withdrawals.
    // 1: blue / 2: red / 3: enemy choices. (This should not matter after infinite plays)

    // Third bit: Game also has it&#39;s neighbour available. If you create a simple game you are allowed 
    // to create an offer too so it is visible (for manual amounts of inputs)
    // This makes sure both items are cancelled if you decide to cancel one 
    // Note: two items are cancelled, but double withdrawal is not availabe ;)
    
    // Fourth bit: Max Offers are here 16, fourth bit not used. 
    // Fifth - Eight bit: ID of the offer in the offer market. Only available from SimpleGame, saves gas (no for loop necessary).


    struct SimpleGame{
        address Owner;   // Creator 
        uint8 setting;  // Setting 

    }
    
    struct OfferGame{
	    uint256 amount;    // fee. 
	    uint8 setting;     // 0-3
        bool SimpleGame; // Could have implemented above
    }
    
    // uint256 is wei paid: note only one offer is available per wei here. 
    mapping(uint256 => SimpleGame) public SimpleGameList;

    // address can store 16 offers. lookup is done via events, saves gas. 
    mapping(address => OfferGame[MaxOffersPerADDR]) public OfferGameList;
    

    // events for both to keep track 
    event SimpleGamePlayed(address creator, address target, bool blue, bool cwon, uint256 amount);
    event SimpleGameCreated(address creator, uint256 fee, uint8 setting);
    event SimpleGameCancelled(uint256 fee);
    
        // same events, ID added to allow cancel from UI 
    event OfferGameCreated(address creator, uint8 setting, uint256 amount, uint8 id);
    event OfferGameCancelled(address creator, uint8 id);
    event OfferGamePlayed(address creator, address target, bool blue, bool cwon, uint256 amount, uint8 id);
    
    // dont touch pls 
    modifier OnlyOwner(){
        if (msg.sender == Owner){
            _;
        }
        else{
            revert();
        }
    }
    
    function EtherWild() public{
        Owner = msg.sender;

    }
    
    // allows to change dev fee. max is 5%
    function SetDevFee(uint16 tfee) public OnlyOwner{
        require(tfee <= 500);
        CFee = tfee;
    }
    
    // allows to change helper fee. minimum is 10%, max 100%. 
    function SetHFee(uint16 hfee) public OnlyOwner {
        require(hfee <= 10000);
        require(hfee >= 1000);
        HFeePart = hfee;
    
    }
    

    // only used in UI. returns uint so you can see how much games you have uploaded. 
    function UserOffers(address who) public view returns(uint8){
        uint8 ids = 0;
        for (uint8 i=0; i<MaxOffersPerADDR; i++){
            if ((OfferGameList[who][i].setting & 3) == 0){
                ids++ ;
            }
        }
        return ids;
    }
    
    // lookups struct into offergamelist. only view. 
    function ViewOffer(address who, uint8 id) public view returns (uint256 amt, uint8 setting, bool sgame){
        var Game = OfferGameList[who][id];
        return (Game.amount, Game.setting,Game.SimpleGame);
    }
    
    // create a new offer with setting. note; setting has to be 1,2 or 3.
    // connected to msg.sender.
    function CreateOffer(uint8 setting) public payable{
        require(msg.value>0);
        require(setting>0);
        CreateOffer_internal(setting, false);
    }
    

    // internal function, necessary to keep track of simple game links 
    function CreateOffer_internal(uint8 setting, bool Sgame) internal returns (uint8 id){
        // find id. 
        require(setting <= 3);

        bool found = false;
        id = 0;
        // find available ID .
        for (uint8 i=0; i<MaxOffersPerADDR; i++){
            if (OfferGameList[msg.sender][i].setting == 0){
                id = i;
                found = true;
                break;
            }
        }
        // no place? reject tx. 
        // note: also simple tx can be released like this.
        require(found);
        OfferGameList[msg.sender][id] = OfferGame(msg.value, setting, Sgame);

        emit OfferGameCreated(msg.sender, setting, msg.value, id);
        // 
        return id;
    }
    
    // public cancel offer, intern necessary for simple link 
    // note: offer cancelled is msg.sender and ID is id (into that array of this address)
    function OfferCancel(uint8 id) public {
        OfferCancel_internal(id, false);
    }
    
    
    function OfferCancel_internal(uint8 id, bool skipSimple) internal {
        var game = OfferGameList[msg.sender][id];
        if (game.setting != 0){
            uint8 setting; 
            bool sgame; 
            uint8 _notn;
            (setting, sgame, _notn) = DataFromSetting(game.setting);
            // reset to 0. 
            game.setting = 0;
            
            emit OfferGameCancelled(msg.sender, id);
            
            // if simple game available cancel it. put true in so no recall to this funciton 
            // also true will prevent to withdraw twice. 
            if ((!skipSimple) && game.SimpleGame){
                CancelSimpleOffer_internal(game.amount,true);
            }
            
            // not from simple cancel? then withdraw. 
            if (!skipSimple){
                msg.sender.transfer(game.amount); // prevent send twice.
            }
        }
        else{
            return;
        }
    }
    
    // play offer game: target address, id, possible setting. 
    function OfferPlay(address target, uint8 id, uint8 setting) public payable {
        var Game = OfferGameList[target][id];
        require(Game.setting != 0);
        require(msg.value >= Game.amount);
        
        uint256 excess = msg.value - Game.amount;
        if (excess > 0){
            msg.sender.transfer(excess); // return too much. 
        }
        
        uint8 cset;
        bool sgame; 
        uint8 _id;
        
        (cset, sgame, id) = DataFromSetting(Game.setting);
        
        bool creatorChoosesBlue = GetSetting(Game.setting, setting);
        bool blue;
        bool creatorwins;
        (blue, creatorwins) = ProcessGame(target, msg.sender, creatorChoosesBlue, Game.amount);

        
        // announce played. 
        emit OfferGamePlayed(target, msg.sender, blue, creatorwins, Game.amount, id);
        // disable offer. 
        Game.setting = 0; // disable this offer. 
        
        // also sgame? then cancel this too to prevent another cancel on this one 
        // otherwise you can always make sure you never lose money. hrm.
        if(sgame){
            // cancel sgame -> true prevents withdraw.
            CancelSimpleOffer_internal(Game.amount, true);
        }
        
    }
    
    // same as offer cancel. 
    function CancelSimpleOffer_internal(uint256 fee, bool SkipOffer) internal {
        uint8 setting = SimpleGameList[fee].setting;
        if (setting == 0){
            return;
        }
        if (!(SimpleGameList[fee].Owner == msg.sender)){
            return;
        }
      
        
        bool offer;
        uint8 id;
        
        (setting, offer, id) = DataFromSetting(setting);
        SimpleGameList[fee].setting = 0; // set to zero, prevent recalling.
        // prevent recall if offer available; 
        // offer cancel with not withdraw. 
        if ((!SkipOffer) && offer){
            OfferCancel_internal(id, true);
        }
        

        // if first call then withdraw. 
       if (!SkipOffer){
            msg.sender.transfer(fee); // prevent send twice. 
       }
        
        emit SimpleGameCancelled( fee);
    }
    
    // false = first call for cancel offer, prevent withdraw twice 
    // withdraws fee to owner if he owns this one 
    function CancelSimpleOffer(uint256 fee) public {
        
       CancelSimpleOffer_internal(fee, false);
    }
    
    //returns if creator wants blue 
    // yeah this program has this logic behind it although not necessary. 
    function GetSetting(uint8 setting1, uint8 setting2) pure internal returns (bool creatorChoosesBlue){
        if (setting1 == 1){
            return true;
        }
        else if (setting1 == 2){
            return false;
        }
        else{
            if (setting2 == 1){
                return false;
            }
        }
        return true;
    }
    
    // play game with setting, and a bool if you also want to create offer on the side. 
    // (all done in one TX)
    function PlaySimpleGame(uint8 setting, bool WantInOffer) payable public {
        require(msg.value > 0);
        require(setting > 0); // do not create cancelled one, otherwise withdraw not possible. 

        var game = (SimpleGameList[msg.value]);
        uint8 id;
        if (game.setting != 0){
            // play game - NOT cancelled. 
            // >tfw msg.value is already correct lol no paybacks 
            require(game.Owner != msg.sender); // do not play against self, would send fee, unfair.
            
            // process logic
            uint8 cset; 
            bool ogame;
            id; 
            (cset, ogame, id) = DataFromSetting(game.setting);
            
            bool creatorChoosesBlue = GetSetting(cset, setting);
            bool blue;
            bool creatorwins;
            //actually play and pay in here. 
            (blue, creatorwins) = ProcessGame(game.Owner, msg.sender, creatorChoosesBlue, msg.value);
            emit SimpleGamePlayed(game.Owner, msg.sender, blue, creatorwins, msg.value);
            // delete , makes it unable to cancel 
            game.setting = 0;
            
            // cancel the offer 
            // is called second time: makes sure no withdraw happens. 
            if (ogame){
                OfferCancel_internal(id, true);
            }
        }
        else {
            // create a game ! 
            //require(setting != 0);
            id = 0;
            if (WantInOffer){
                // also create an offer. costs more gas 
                id = CreateOffer_internal(setting, true); // id is returned to track this when cancel. 
            }
            
            // convert setting. also checks for setting input <= 3; 
            // bit magic 
            
            setting = DataToSetting(setting, WantInOffer, id);
            
            // make game, push it in game , emit event 
            var myGame = SimpleGame(msg.sender, setting);
            SimpleGameList[msg.value] = myGame;
            emit SimpleGameCreated(msg.sender, msg.value, setting);
        }
    }
    
        // process game 
        // NOTE: ADRESSES are added to random to make sure we get different random results 
        // for every creator/target pair PER block
        // that should be sufficient, it would be weird if a block only creates same color all time. 
    function ProcessGame(address creator, address target, bool creatorWantsBlue, uint256 fee) internal returns (bool blue, bool cWon) {
        uint random = rand(1, creator);
        blue = (random==0);
      //  cWon = (creatorWantsBlue && (blue)) || (!creatorWantsBlue && (!blue)); >tfw retarded 
        cWon = (creatorWantsBlue == blue); // check if cwon via logic.
        if (cWon){
            creator.transfer(DoFee(fee*2)); // DoFee returns payment. 
        }
        else{
            target.transfer(DoFee(fee*2));
        }
    }
    // random function via blockhas and address addition, timestamp. 
    function rand(uint max, address other) constant internal returns (uint result){
        uint add = uint (msg.sender) + uint(other) + uint(block.timestamp);
        uint random_number = addmod(uint (block.blockhash(block.number-1)), add, uint (max + 1)) ;
        return random_number;   
    }
    
    
    
    // pay fee to owners
    // no safemath necessary, will always be fine due to control in limits of fees. 
    function DoFee(uint256 amt) internal returns (uint256 left){
        uint256 totalFee = (amt*CFee)/10000; // total fee paid 
        uint256 cFee = (totalFee*HFeePart)/10000; // helper fee paid 
        uint256 dFee = totalFee - cFee; //dev fee paid 
        
        Owner.transfer(dFee); // pay 
        HelpOwner.transfer(cFee);
        
        return amt-totalFee; // return excess to be paid 
    }
    //function SetFee(uint16) public OnlyOwner;
    //function SetHFee(uint16) public OnlyOwner;

    // helper 
    
    // converts settings to uint8 using multiple bits to store this data.
     function DataToSetting(uint8 setting, bool offer, uint8 id) pure internal returns (uint8 output){
        require(setting <= 3);

        if (!offer){
            return setting; // no id necessary.
        }
        require(id <= 15);
        uint8 out=setting;
        if (offer){
            out = out + 4; // enable bit 3;
        }
        // shift ID bits 4 bits to right so they are on bit 5 to 8
        uint8 conv_id = id << 4;
        // add bits 
        out = out + conv_id; 
        return out;
    }
    
    // from setting, 3 data to retrieve above.
    function DataFromSetting(uint8 n) pure internal returns(uint8 set, bool offer, uint8 id){
        // setting simpmly extract first 2 bits. 
        set = (n & 3); 
        // offer extract 3rd bit and convert it to bool (cannot shift and check due to ID), or might have used MOD 1 
        offer = (bool) ((n & 4)==4); 
        // shift n by 4 bits to extract id. throws away first 4 bits, nice.
        id = (n) >> 4;
        
    }
    
    
}