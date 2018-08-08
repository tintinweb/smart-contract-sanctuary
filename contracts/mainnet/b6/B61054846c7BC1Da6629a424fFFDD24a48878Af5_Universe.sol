pragma solidity ^0.4.20;

contract Universe{
    // Universe contract
    // It is possible to buy planets or other universe-objects from other accounts.
    // If an object has an owner, fees will be paid to that owner until no owner has been found.
    
    struct Item{
        uint256 id;
        string name;
        uint256 price;
        uint256 id_owner;
        address owner;
    }
    
   // bool TESTMODE = true;
    
  //  event pushuint(uint256 push);
 //   event pushstr(string str);
  //  event pusha(address addr);
    
    uint256[4] LevelLimits = [0.05 ether, 0.5 ether, 2 ether, 5 ether];
    uint256[5] devFee = [5,4,3,2,2];
    uint256[5] shareFee = [12,6,4,3,2];
    uint256[5] raisePrice = [100, 35, 25, 17, 15];
    
    
    mapping (uint256 => Item) public ItemList;
    uint256 public current_item_index=1;
    
    address owner;
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    function Universe() public{
        owner=msg.sender;
        AddItem("Sun", 1 finney, 0);
        AddItem("Mercury", 1 finney, 1);
        AddItem("Venus", 1 finney, 1);
        AddItem("Earth", 1 finney, 1);
        AddItem("Mars", 1 finney, 1);
        AddItem("Jupiter", 1 finney, 1);
        AddItem("Saturn", 1 finney, 1);
        AddItem("Uranus", 1 finney, 1);
        AddItem("Neptune", 1  finney, 1);
        AddItem("Pluto", 1 finney, 1);
        AddItem("Moon", 1 finney, 4);
    }
    
    function CheckItemExists(uint256 _id) internal returns (bool boolean){
        if (ItemList[_id].price == 0){
            return false;
        }
        return true;
    }

    
 //   function AddItem(string _name, uint256 _price, uint256 _id_owner) public {
    function AddItem(string _name, uint256 _price, uint256 _id_owner) public onlyOwner {
//if (TESTMODE){
//if (_price < (1 finney)){
  //              _price = (1 finney);
    //        }
//}
        //require(_id != 0);
        //require(_id == current_item_index);
        uint256 _id = current_item_index;

        require(_id_owner != _id);
        require(_id_owner < _id);

        require(_price >= (1 finney));
        require(_id_owner == 0 || CheckItemExists(_id_owner));
        require(CheckItemExists(_id) != true);
        
     //   uint256 current_id_owner = _id_owner;
        
     //   uint256[] mem_owner;
        
        //pushuint(mem_owner.length);
        
        /*while (current_id_owner != 0){
           
            mem_owner[mem_owner.length-1] = current_id_owner;
            current_id_owner = ItemList[current_id_owner].id_owner;
            
          
            for(uint256 c=0; c<mem_owner.length; c++){
               if(c != (mem_owner.length-1)){
                   if(mem_owner[c] == current_id_owner){
                        pushstr("false");
                        return;
                    }
                }
            }
            mem_owner.length += 1;
        }*/
        
        var NewItem = Item(_id, _name, _price, _id_owner, owner);
        ItemList[current_item_index] = NewItem;
        current_item_index++;
        
    }
    
    function ChangeItemOwnerID(uint256 _id, uint256 _new_owner) public onlyOwner {
        require(_new_owner != _id);
        require(_id <= (current_item_index-1));
        require(_id != 0);
        require(_new_owner != 0);
        require(_new_owner <= (current_item_index-1));
        require(ItemList[_id].id_owner == 0);
       
        uint256 current_id_owner = _new_owner;
        uint256[] mem_owner;   
        
         while (current_id_owner != 0){
           
            mem_owner[mem_owner.length-1] = current_id_owner;
            current_id_owner = ItemList[current_id_owner].id_owner;
            
          
            for(uint256 c=0; c<mem_owner.length; c++){
               if(c != (mem_owner.length-1)){
                   if(mem_owner[c] == current_id_owner || mem_owner[c] == _new_owner || mem_owner[c] == _id){
//pushstr("false");
                        return;
                    }
                }
            }
            mem_owner.length += 1;
        }  
        
        ItemList[_id].id_owner = _new_owner;
        
    }

    function DoDividend(uint256 _current_index, uint256 valueShareFee, uint256 id_owner) internal returns (uint256){
            uint256 pow = 0;
            uint256 totalShareFee = 0;
            uint256 current_index = _current_index;
            while (current_index != 0){
                pow = pow + 1;
                current_index = ItemList[current_index].id_owner;
            }
        
            uint256 total_sum = 0;
        
            for (uint256 c2=0; c2<pow; c2++){
                total_sum = total_sum + 2**c2;
            }
        
            if (total_sum != 0){
               // uint256 tot_value = 2**(pow-1);
        
                current_index = id_owner;
        
                while (current_index != 0){
                    uint256 amount = div(mul(valueShareFee, 2**(pow-1)), total_sum);
                    totalShareFee = add(amount, totalShareFee);
                    ItemList[current_index].owner.transfer(amount);
                //    pusha(ItemList[current_index].owner);
                 //   pushuint(amount);
                    
                    pow = sub(pow, 1);
                    current_index = ItemList[current_index].id_owner;
                }
            }
            else{
                ItemList[current_index].owner.transfer(valueShareFee);
            //    pusha(ItemList[current_index].owner);
             //   pushuint(valueShareFee);
                totalShareFee = valueShareFee;
            }
            return totalShareFee;
    }    
    
    function BuyItem(uint256 _id) public payable{
        require(_id > 0 && _id < current_item_index);
        var TheItem = ItemList[_id];
        require(TheItem.owner != msg.sender);
        require(msg.value >= TheItem.price);
    
        uint256 index=0;
        
        for (uint256 c=0; c<LevelLimits.length; c++){
            uint256 value = LevelLimits[c];
            if (TheItem.price < value){
                break;
            }
            index++;
        }
        
        uint256 valueShareFee = div(mul(TheItem.price, shareFee[index]), 100);
        uint256 totalShareFee = 0;
        uint256 valueDevFee = div(mul(TheItem.price, devFee[index]), 100);
        uint256 valueRaisePrice = div(mul(TheItem.price, 100 + raisePrice[index]), 100);
        
        uint256 current_index = TheItem.id_owner;
        
        if (current_index != 0){
            totalShareFee = DoDividend(current_index, valueShareFee, current_index);
        }
        
        owner.transfer(valueDevFee);
        
      //  pushstr("dev");
      //  pushuint(valueDevFee);
        
        
        uint256 totalToOwner = sub(sub(TheItem.price, valueDevFee), totalShareFee);
        
        uint256 totalBack = sub(sub(sub(msg.value, totalToOwner), valueDevFee), totalShareFee);
        
        if (totalBack > 0){
            msg.sender.transfer(totalBack);
        }
        
       // pushstr("owner transfer");
       // pushuint(totalToOwner);
        TheItem.owner.transfer(totalToOwner);
        
        TheItem.owner = msg.sender;
        TheItem.price = valueRaisePrice;
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