pragma solidity ^0.4.21;

// Updates since last contract 
// Price increase is now max 200% from 100% 
// min Price is now 1 szabo from 1 finney. This price is not recommended due to gas. 
// If you start a new game (amount in pot is 0, and timer hasn&#39;t started) then you will pay NO fees
// This means that you can always start a game without any risk. 
// If no one decides to buy, then you can pay out back, and you will get the pot, which is 100% of your payment back!!

// WARNING
// IF SITE GOES DOWN, THEN YOU CAN STILL KEEP PLAYING THE GAME 
// INSTRUCTIONS:
// GO TO REMIX.ETHEREUM.ORG, UPLOAD THIS CONTRACT, AND THEN LOAD THIS CONTRACT FROM ADDRESS 
// MAKE SURE YOU ARE CONNECTED WITH METAMASK TO MAINNET 
// NOW YOU CAN CALL FUNCTIONS 
// EX; CALL PAYOUT(ID) SO YOU CAN PAY OUT IF YOU WON A CARD. 
// NOTE: SITES WHICH HOST UI ARE NOT SUPPOSED TO GO DOWN

contract ItemMarket{
	address public owner;

	// 500 / 10000 = 5%
	uint16 public devFee = 500;
	uint256 public ItemCreatePrice = 0.02 ether;

    // note, on etherscan you can see these item calls
    // if you buy an item, the TX will call ItemCreated with the id it gets - which you can see on etherscan!
	event ItemCreated(uint256 id);
	event ItemBought(uint256 id);
	event ItemWon(uint256 id);
	//event ItemCreationError(string err);

	struct Item{
		uint32 timer;
		uint256 timestamp;
		uint16 priceIncrease;
		uint256 price;
		uint256 amount;
		uint256 minPrice;
		uint16 creatorFee;
		uint16 previousFee;
		uint16 potFee;

		address creator;
		address owner;
		string quote;
		string name;
	} 

	mapping (uint256 => Item) public Items;

	uint256 public next_item_index = 0;

    modifier onlyOwner(){
        if (msg.sender == owner){
            _;
        }
        else{
            revert();
        }
    }

    function ItemMarket() public{
    	owner = msg.sender;
    	// Add items 
       
    
        
    }
    
    uint8 IS_STARTED=0;
    
    function callOnce() public {
        require(msg.sender == owner);
        require(IS_STARTED==0);
        IS_STARTED = 1;
        AddItemExtra(600, 1500, 1 finney, 0, 3000, "Battery", msg.sender);
    	AddItemExtra(600, 150, 4 finney, 0, 5000, "Twig", msg.sender);
    	AddItemExtra(3600, 2000, 10 finney, 0, 4000, "Solar Panel", msg.sender);
    	AddItemExtra(3600*24, 5000, 10 finney, 0, 5000, "Moon", msg.sender);
    	AddItemExtra(3600*24*7, 7500, 50 finney, 0, 7000, "Ethereum", msg.sender);
    	
    	// Previous contract had items. Recreate those
    	
        AddItemExtra(2000, 10000, 1000000000000000, 500, 2000, "segfault&#39;s ego", 0xef764BAC8a438E7E498c2E5fcCf0f174c3E3F8dB);
        AddItemExtra(300, 10000, 10000000000000000, 500, 2500, "Hellina", 0x83c0Efc6d8B16D87BFe1335AB6BcAb3Ed3960285);
        AddItemExtra(600, 10000, 100000000000000000, 500, 2000, "nightman&#39;s gambit", 0x5C035Bb4Cb7dacbfeE076A5e61AA39a10da2E956);
        AddItemExtra(360000, 10000, 5000000000000000, 200, 1800, "BOHLISH", 0xC84c18A88789dBa5B0cA9C13973435BbcE7e961d);
        AddItemExtra(900, 2000, 20000000000000000, 1000, 2000, "Phil&#39;s labyrinth", 0x457dEA5F9c185419EA47ff80f896d98aadf1c727);
        AddItemExtra(420, 6899, 4200000000000000, 500, 4000, "69,420 (Nice)", 0x477cCD47d62a4929DD11651ab835E132c8eab3B8);
        next_item_index = next_item_index + 2; // this was an item I created. We skip this item. Item after this too, to check if != devs could create 
        // apparently people created wrong settings which got reverted by the add item function. it looked like system was wrong
        
        // tfw next item 
        // i didnt create this name lol 
        
        AddItemExtra(600, 10000, 5000000000000000, 2500, 7000, "HELLINA IS A RETARDED DEGENERATE GAMBLER AND A FUCKING FUD QUEEN", 0x26581d1983ced8955C170eB4d3222DCd3845a092);
        
        // created this, nice hot potato 
        
        AddItemExtra(1800, 9700, 2000000000000000, 0, 2500, "Hot Potato", msg.sender);
    }

    function ChangeFee(uint16 _fee) public onlyOwner{
    	require(_fee <= 500);
    	devFee = _fee;
    }

    function ChangeItemPrice(uint256 _newPrice) public onlyOwner{
    	ItemCreatePrice = _newPrice;
    }
    
    // INTERNAL EXTRA FUNCTION TO MOVE OVER OLD ITEMS 
    
    function AddItemExtra(uint32 timer, uint16 priceIncrease, uint256 minPrice, uint16 creatorFee, uint16 potFee, string name, address own) internal {
    	uint16 previousFee = 10000 - devFee - potFee - creatorFee;
    	var NewItem = Item(timer, 0, priceIncrease, minPrice, 0, minPrice, creatorFee, previousFee, potFee, own, address(0), "", name);

    	Items[next_item_index] = NewItem;

    	//emit ItemCreated(next_item_index);

    	next_item_index = add(next_item_index,1);
    }

    function AddItem(uint32 timer, uint16 priceIncrease, uint256 minPrice, uint16 creatorFee, uint16 potFee, string name) public payable {
    	require (timer >= 300);
    	require (timer < 31622400);

    	require(priceIncrease <= 20000);
    	require(minPrice >= (1 szabo) && minPrice <= (1 ether));
    	require(creatorFee <= 2500);
    	require(potFee <= 10000);
    	require(add(add(creatorFee, potFee), devFee) <= 10000);



    	if (msg.sender == owner){
    		require(creatorFee == 0);
    		if (msg.value > 0){
    			owner.transfer(msg.value);
    		}
    	}
    	else{
    		uint256 left = 0;
    		if (msg.value > ItemCreatePrice){
    			left = sub(msg.value, ItemCreatePrice);
    			msg.sender.transfer(left);
    		}
    		else{
    			if (msg.value < ItemCreatePrice){

    				revert();
    			}
    		}

    		owner.transfer(sub(msg.value, left));
    	}


        require (devFee + potFee + creatorFee <= 10000);
        
    	uint16 previousFee = 10000 - devFee - potFee - creatorFee;
    	var NewItem = Item(timer, 0, priceIncrease, minPrice, 0, minPrice, creatorFee, previousFee, potFee, msg.sender, address(0), "", name);

    	Items[next_item_index] = NewItem;

    	emit ItemCreated(next_item_index);

    	next_item_index = add(next_item_index,1);
    }

    function Payout(uint256 id) internal {
    	var UsedItem = Items[id];
    	uint256 Paid = UsedItem.amount;
    	UsedItem.amount = 0;

    	UsedItem.owner.transfer(Paid);

    	// reset game 
    	UsedItem.owner = address(0);
    	UsedItem.price = UsedItem.minPrice;
    	UsedItem.timestamp = 0;

    	emit ItemWon(id);

    }


    function TakePrize(uint256 id) public {
    	require(id < next_item_index);
    	var UsedItem = Items[id];
    	require(UsedItem.owner != address(0));
    	uint256 TimingTarget = add(UsedItem.timer, UsedItem.timestamp);

    	if (block.timestamp > TimingTarget){
    		Payout(id);
    		return;
    	}
    	else{
    		revert();
    	}
    }




    function BuyItem(uint256 id, string quote) public payable{
    	require(id < next_item_index);
    	var UsedItem = Items[id];


    	if (UsedItem.owner != address(0) && block.timestamp > (add(UsedItem.timestamp, UsedItem.timer))){
    		Payout(id);
    		if (msg.value > 0){
    			msg.sender.transfer(msg.value);
    		}
    		return;
    	}

    	require(msg.value >= UsedItem.price);
    	require(msg.sender != owner);
    	//require(msg.sender != UsedItem.creator); 
    	require(msg.sender != UsedItem.owner);

    	uint256 devFee_used = mul(UsedItem.price, devFee) / 10000;
    	uint256 creatorFee_used = mul(UsedItem.price, UsedItem.creatorFee) / 10000;
    	uint256 prevFee_used;

   		if (UsedItem.owner == address(0)){
   			// game not started. 
   			// NO FEES ARE PAID WHEN THE TIMER IS STARTS
   			// IF NO ONE START PLAYING GAME, then the person who bought first can get 100% of his ETH back!
   			prevFee_used = 0;
   			devFee_used = 0;
   			creatorFee_used = 0;
   		}
   		else{
   			prevFee_used = (mul(UsedItem.price, UsedItem.previousFee)) / 10000;
   			UsedItem.owner.transfer(prevFee_used);
   		}

   		if (creatorFee_used != 0){
   			UsedItem.creator.transfer(creatorFee_used);
   		}

   		if (devFee_used != 0){
   			owner.transfer(devFee_used);
   		}
   		
   		if (msg.value > UsedItem.price){
   		    msg.sender.transfer(sub(msg.value, UsedItem.price));
   		}

   		uint256 potFee_used = sub(sub(sub(UsedItem.price, devFee_used), creatorFee_used), prevFee_used);

   		UsedItem.amount = add(UsedItem.amount, potFee_used);
   		UsedItem.timestamp = block.timestamp;
   		UsedItem.owner = msg.sender;
   		UsedItem.quote = quote;
   		UsedItem.price = (UsedItem.price * (add(10000, UsedItem.priceIncrease)))/10000;

   		emit ItemBought(id);
    }
    
	function () payable public {
		// msg.value is the amount of Ether sent by the transaction.
		if (msg.value > 0) {
			msg.sender.transfer(msg.value);
		}
	}
	
	
	
	    
    // Not interesting, safe math functions
    
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