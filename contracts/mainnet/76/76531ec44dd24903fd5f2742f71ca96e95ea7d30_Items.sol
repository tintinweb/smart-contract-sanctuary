pragma solidity ^0.4.21;

contract Items{
    address owner;
    address helper = 0x690F34053ddC11bdFF95D44bdfEb6B0b83CBAb58;
    
    // Marketplace written by Etherguy and Poorguy
    
    // Change the below numbers to edit the development fee. 
    // This can also be done by calling SetDevFee and SetHFee 
    // Numbers are divided by 10000 to calcualte the cut 
    uint16 public DevFee = 500; // 500 / 10000 -> 5% 
    uint16 public HelperPortion = 5000; // 5000 / 10000 -> 50% (This is the cut taken from the total dev fee)
    
    // Increase in price 
    // 0 means that the price stays the same 
    // Again divide by 10000
    // 10000 means: 10000/10000 = 1, which means the new price = OldPrice * (1 + (10000/1000)) = OldPrice * (1+1) = 2*OldPrice 
    // Hence the price doubles.
    // This setting can be changed via SetPriceIncrease
    // The maximum setting is the uint16 max value 65535 which means an insane increase of more than 6.5x 
    uint16 public PriceIncrease = 2000;
    
    struct Item{
        address Owner;
        uint256 Price;
    }
    
    mapping(uint256 => Item) Market; 
    
    uint256 public NextItemID = 0;
    event ItemBought(address owner, uint256 id, uint256 newprice);
    
    function Items() public {
        owner = msg.sender;
        
        // Add initial items here to created directly by contract release. 
        
      //  AddMultipleItems(0.00666 ether, 3); // Create 3 items for 0.00666 ether basic price at start of contract.
      
      
      // INITIALIZE 17 items so we can transfer ownership ...
      AddMultipleItems(0.006666 ether, 36);
      
      
      // SETUP their data 
      Market[0].Owner = 0x874c6f81c14f01c0cb9006a98213803cd7af745f;
      Market[0].Price = 53280000000000000;
      Market[1].Owner = 0x874c6f81c14f01c0cb9006a98213803cd7af745f;
      Market[1].Price = 26640000000000000;
      Market[2].Owner = 0xb080b202b921d0d1fd804d0071615eb09e326aac;
      Market[2].Price = 854280000000000000;
      Market[3].Owner = 0x874c6f81c14f01c0cb9006a98213803cd7af745f;
      Market[3].Price = 26640000000000000;
      Market[4].Owner = 0xb080b202b921d0d1fd804d0071615eb09e326aac;
      Market[4].Price = 213120000000000000;
      Market[5].Owner = 0x874c6f81c14f01c0cb9006a98213803cd7af745f;
      Market[5].Price = 13320000000000000;
      Market[6].Owner = 0xd33614943bcaadb857a58ff7c36157f21643df36;
      Market[6].Price = 26640000000000000;
      Market[7].Owner = 0x874c6f81c14f01c0cb9006a98213803cd7af745f;
      Market[7].Price = 53280000000000000;
      Market[8].Owner = 0xd33614943bcaadb857a58ff7c36157f21643df36;
      Market[8].Price = 26640000000000000;
      Market[9].Owner = 0x874c6f81c14f01c0cb9006a98213803cd7af745f;
      Market[9].Price = 53280000000000000;
      Market[10].Owner = 0x0960069855bd812717e5a8f63c302b4e43bad89f;
      Market[10].Price = 13320000000000000;
      Market[11].Owner = 0xd3dead0690e4df17e4de54be642ca967ccf082b8;
      Market[11].Price = 13320000000000000;
      Market[12].Owner = 0xc34434842b9dc9cab4e4727298a166be765b4f32;
      Market[12].Price = 13320000000000000;
      Market[13].Owner = 0xc34434842b9dc9cab4e4727298a166be765b4f32;
      Market[13].Price = 13320000000000000;
      Market[14].Owner = 0x874c6f81c14f01c0cb9006a98213803cd7af745f;
      Market[14].Price = 53280000000000000;
      Market[15].Owner = 0xd33614943bcaadb857a58ff7c36157f21643df36;
      Market[15].Price = 26640000000000000;
      Market[16].Owner = 0x3130259deedb3052e24fad9d5e1f490cb8cccaa0;
      Market[16].Price = 13320000000000000;
      // Uncomment to add MORE ITEMS
     // AddMultipleItems(0.006666 ether, 17);
    }
    
    // web function, return item info 
    function ItemInfo(uint256 id) public view returns (uint256 ItemPrice, address CurrentOwner){
        return (Market[id].Price, Market[id].Owner);
    }
    
    // Add a single item. 
    function AddItem(uint256 price) public {
        require(price != 0); // Price 0 means item is not available. 
        require(msg.sender == owner);
        Item memory ItemToAdd = Item(0x0, price); // Set owner to 0x0 -> Recognized as owner
        Market[NextItemID] = ItemToAdd;
        NextItemID = add(NextItemID, 1); // This absolutely prevents overwriting items
    }
    
    // Add multiple items 
    // All for same price 
    // This saves sending 10 tickets to create 10 items. 
    function AddMultipleItems(uint256 price, uint8 howmuch) public {
        require(msg.sender == owner);
        require(price != 0);
        require(howmuch != 255); // this is to prevent an infinite for loop
        uint8 i=0;
        for (i; i<howmuch; i++){
            AddItem(price);
        }
    }
    

    function BuyItem(uint256 id) payable public{
        Item storage MyItem = Market[id];
        require(MyItem.Price != 0); // It is not possible to edit existing items.
        require(msg.value >= MyItem.Price); // Pay enough thanks .
        uint256 ValueLeft = DoDev(MyItem.Price);
        uint256 Excess = sub(msg.value, MyItem.Price);
        if (Excess > 0){
            msg.sender.transfer(Excess); // Pay back too much sent 
        }
        
        // Proceed buy 
        address target = MyItem.Owner;
        
        // Initial items are owned by owner. 
        if (target == 0x0){
            target = owner; 
        }
        
        target.transfer(ValueLeft);
        // set owner and price. 
        MyItem.Price = mul(MyItem.Price, (uint256(PriceIncrease) + uint256(10000)))/10000; // division 10000 to scale stuff right. No need SafeMath this only errors when DIV by 0.
        MyItem.Owner = msg.sender;
        emit ItemBought(msg.sender, id, MyItem.Price);
    }
    
    
    
    
    
    // Management stuff, not interesting after here .
    
    
    function DoDev(uint256 val) internal returns (uint256){
        uint256 tval = (mul(val, DevFee)) / 10000;
        uint256 hval = (mul(tval, HelperPortion)) / 10000;
        uint256 dval = sub(tval, hval); 
        
        owner.transfer(dval);
        helper.transfer(hval);
        return (sub(val,tval));
    }
    
    // allows to change dev fee. max is 6.5%
    function SetDevFee(uint16 tfee) public {
        require(msg.sender == owner);
        require(tfee <= 650);
        DevFee = tfee;
    }
    
    // allows to change helper fee. minimum is 10%, max 100%. 
    function SetHFee(uint16 hfee) public  {
        require(msg.sender == owner);
        require(hfee <= 10000);

        HelperPortion = hfee;
    
    }
    
    // allows to change helper fee. minimum is 10%, max 100%. 
    function SetPriceIncrease(uint16 increase) public  {
        require(msg.sender == owner);
        PriceIncrease = increase;
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