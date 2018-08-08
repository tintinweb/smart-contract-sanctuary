pragma solidity ^0.4.21;

contract ItemMarket{
	address public owner;

	// 500 / 10000 = 5%
	uint16 public devFee = 500;
	uint256 public ItemCreatePrice = 0.02 ether;

	event ItemCreated(uint256 id);
	event ItemBought(uint256 id);
	event ItemWon(uint256 id);

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

    	AddItem(600, 1500, 1 finney, 0, 3000, "Battery");


    	AddItem(600, 150, 4 finney, 0, 5000, "Twig");

    	AddItem(3600, 2000, 10 finney, 0, 4000, "Solar Panel");
    	AddItem(3600*24, 5000, 10 finney, 0, 5000, "Moon");
    	AddItem(3600*24*7, 7500, 50 finney, 0, 7000, "Ethereum");

    }

    function ChangeFee(uint16 _fee) public onlyOwner{
    	require(_fee <= 500);
    	devFee = _fee;
    }

    function ChangeItemPrice(uint256 _newPrice) public onlyOwner{
    	ItemCreatePrice = _newPrice;
    }

    function AddItem(uint32 timer, uint16 priceIncrease, uint256 minPrice, uint16 creatorFee, uint16 potFee, string name) public payable {
    	require (timer >= 300);
    	require (timer < 31622400);

    	require(priceIncrease <= 10000);
    	require(minPrice >= (1 finney) && minPrice <= (1 ether));
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
   			prevFee_used = 0;
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