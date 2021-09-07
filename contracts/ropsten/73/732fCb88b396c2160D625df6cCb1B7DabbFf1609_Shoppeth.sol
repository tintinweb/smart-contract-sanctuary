/**
 *Submitted for verification at Etherscan.io on 2021-09-07
*/

pragma solidity ^0.8.7;
//SPDX-License-Identifier: UNLICENSED

library DataTypes {
    
    struct ProductData {
        address product_address;
        address seller;
        string product_name;
        string img;
        string[] keywords;
        uint min_orders;
        uint max_orders;
        uint current_orders;
        uint cost;
        uint current_progress;
        ProgressState[] progress;
        // production_status represents an enum with 3 possible Satus: ORDERS_OPEN, ORDERS_CLOSED, ORDERS_CANCELLED. 
        string production_status;
        uint contract_created_date;
        uint order_close_date;
        uint promised_deadline;
        
        int[] user_item_data; //index 0: quantity, index 1: item_state (0: NOT_RECEIVED, -1: REFUNDED, 1: RECEIVED)
    }

    struct ProgressState {
        string title;
        uint timestamp;
    }
    
}

contract EventEmitter {
    event UserEvents(
         address indexed user_address
        );
    event ProductEvents();
    
    function emitUserEvents(address user_address) public {
        emit UserEvents(user_address);
    }
    
    
    function emitProductEvents() public {
        emit ProductEvents();
    }
}

contract Shoppeth {
    
    EventEmitter public eventEmitter = new EventEmitter();
    
    struct User {
        address addr;
        ProductItem[] cart; //if it is unchecked in the cart's FE, save it as negative number
        ProductItem[] orders; //orders checked out
        uint cart_length; //true length of cart
        address[] selling;
    }
    
    struct ProductItem {
        address addr;
        int64 quantity;
    }
    
    mapping(string => address[]) public keyword_db;
    mapping(address => User) public user_db; //User is a struct
    address[] public productContracts; // Just for checking, list of all products
    address public lastContractAddress;
    mapping(address => Product) public product_db;
    
    event ProductCreated(address seller_address, address prod_address); // Check naming convention

 // Contract Generator Function
 // When a Seller creates a Product Campaign, he has to deposit a certain amount of money equivalent to "twice" the cost price of his item
 function createProduct(
     string memory product_name, 
     string memory img,
     string[] memory keywords,
     uint min_orders,
     uint max_orders,
     uint order_close_date,
     uint promised_deadline
     ) public payable { //require(((msg.value / 1 ether) % 2 == 0) && (msg.value != 0), "Please enter an Even number! (i.e. Twice the cost price of your Product)"); 
            require(promised_deadline / 1 days >= order_close_date / 1 days, "Promised deadline cannot be before the order close date!");
            Product newProduct = new Product{value: msg.value}(
                msg.sender,
                product_name, 
             img,
             keywords,
             min_orders,
             max_orders,
             msg.value,
             order_close_date,
             promised_deadline,
             eventEmitter
            );

            address newProductAddress = address(newProduct);
            for (uint k = 0; k < keywords.length; k +=1) {
                 keyword_db[keywords[k]].push(newProductAddress);
            }
               
            productContracts.push(newProductAddress); // Just for checking, adds to a list of all products
            lastContractAddress = newProductAddress; // For checking
            product_db[newProductAddress] = newProduct;
            user_db[msg.sender].selling.push(newProductAddress);
            emit ProductCreated(msg.sender, newProductAddress);
            
            eventEmitter.emitUserEvents(msg.sender);
            eventEmitter.emitProductEvents();
 }
 
 function getProductCount() public view returns(uint productCount) { // For testing
        return productContracts.length;
    }
    
    function browseProducts(
     string memory keyword
 ) public view returns (DataTypes.ProductData[] memory) {
     
     DataTypes.ProductData[] memory browsed_products = new DataTypes.ProductData[](keyword_db[keyword].length);
     for (uint i = 0; i < keyword_db[keyword].length; i ++) {
         DataTypes.ProductData memory temp_data = product_db[keyword_db[keyword][i]].getData();
         // Only show products where status = "ORDERS_OPEN"
            browsed_products[i] = temp_data;
     }
     
     return browsed_products;
 }
 
    //update cart with array of product addresses for FE
    function updateCart(ProductItem [] memory cart_items) public {
        
        uint i = 0;
        for (i; i < cart_items.length; i += 1) {
            appendProductItems(
                user_db[msg.sender].cart,
                i,
                cart_items[i]
            );
        }
        // Also need to update cart_length to correct value
        user_db[msg.sender].cart_length = i + 1;
    }

    event OrderChanged (address buyer_address);
    event CartChanged (address buyer_address);
    
    function appendProductItems(
        ProductItem[] storage item_list,
        uint append_index,
        ProductItem memory item
    ) internal { //returns the true length of array
    
        //if added item index is outside item_list.length, push(),
        if ( append_index >= item_list.length) {
            item_list.push(item);
        }
        
        //otherwise override existing index,
        else {
            item_list[append_index] = item;
        }
     
        //also need to update real_length variable to correct value after calling this function
        //append_index ++ outside this function
    }

    function checkoutCart(ProductItem [] memory cart_items) public payable {
        uint fund = msg.value;
        
        //find new cart length
        uint new_cart_length = 0;
        for (uint i = 0; i < cart_items.length; i ++) {
            if (cart_items[i].quantity < 0) {
                new_cart_length ++;
            }
        }
        user_db[msg.sender].cart_length = new_cart_length;
        
        //action
        uint cart_length_counter = 0;
        
        for (uint i = 0; i < cart_items.length; i ++) {
            int64 quantity = cart_items[i].quantity;
            address addr = cart_items[i].addr;
            if (quantity > 0) {
                //add to orders
                uint payment = 2*product_db[addr].getData().cost*uint(int256(quantity));
                require(fund >= payment, "checkout amount not enough");
                fund -= payment;
                
                //confirm purchase
                product_db[addr].confirmPurchase{value: payment}(uint(int256(quantity)), msg.sender);
                user_db[msg.sender].orders.push(cart_items[i]);
            } else {
                //add back to cart
                appendProductItems(
                    user_db[msg.sender].cart,
                    cart_length_counter,
                    cart_items[i]
                );
               
                cart_length_counter ++;
            }
        }
        
        eventEmitter.emitProductEvents();
        eventEmitter.emitUserEvents(msg.sender);
    }


    function getCart() public view returns (DataTypes.ProductData[] memory) {
        User memory user_read_only = user_db[msg.sender];
        
        DataTypes.ProductData[] memory cart_products = new DataTypes.ProductData[](user_read_only.cart_length);
        for (uint i = 0; i < user_read_only.cart_length; i ++) {
            DataTypes.ProductData memory product = product_db[user_read_only.cart[i].addr].getData();
            product.user_item_data[0] = user_read_only.cart[i].quantity;
            cart_products[i] = product;
        }
        
        return cart_products;
    }
    
    function getOrders() public view returns (DataTypes.ProductData[] memory) {
        User memory user_read_only = user_db[msg.sender];
        
        DataTypes.ProductData[] memory ordered_products = new DataTypes.ProductData[](user_read_only.orders.length);
        for (uint i = 0; i < user_read_only.orders.length; i ++) {
            DataTypes.ProductData memory product = product_db[user_read_only.orders[i].addr].getData();
            product.user_item_data[0] = user_read_only.orders[i].quantity;
            product.user_item_data[1] = product_db[user_read_only.orders[i].addr].orders_not_received(msg.sender);
            ordered_products[i] = product;
        }
        
        return ordered_products;
    }
    

    function getSelling() public view returns (DataTypes.ProductData[] memory) {
        User memory user_read_only = user_db[msg.sender];
        
        DataTypes.ProductData[] memory selling = new DataTypes.ProductData[](user_read_only.selling.length);
        for (uint i = 0; i < user_read_only.selling.length; i ++) {
            DataTypes.ProductData memory product = product_db[user_read_only.selling[i]].getData();
            selling[i] = product;
        }
        
        return selling;
    }
}

contract Product {
    
    DataTypes.ProductData public data; //everytime this object changes need to emit event so FE can receive automatically
    mapping(address => int) public orders_not_received; //0 if delivered, x if ordered x quantity and have not received. We assume that if the buyer receives all his orders.
    EventEmitter eventEmitter;
    
    enum EscrowState { Created, Locked, Inactive }
    EscrowState public state;
    
    uint public value;
    uint public number_of_buyers;
    address[] public buyer;
    
    constructor(
        address seller_address,
        string memory product_name, 
     string memory img,
     string[] memory keywords,
     uint min_orders,
     uint max_orders,
     uint cost,
     uint order_close_date,
     uint promised_deadline,
     EventEmitter _eventEmitter
        ) payable {
            eventEmitter = _eventEmitter;
            
            // Initialising ProductData Details  
            data.product_address = address(this);
            data.seller = payable(seller_address);
            data.product_name = product_name;
            data.img = img;
            data.keywords = keywords;
            data.min_orders = min_orders;
         data.max_orders = max_orders;
         data.current_orders = 0;
         data.cost = cost / 2;
         // Default value that we set when a New Product Contract is created is "ORDERS_OPEN"
         data.production_status = "ORDERS_OPEN"; 
         
         //initialise user_item_data to have 2 slots
         data.user_item_data.push(0); // Quantity of item that msg.sender ordered
         data.user_item_data.push(0); // Status of the item (refunded or bought)
         
         // Initialising ProductionTimeline Details
         data.contract_created_date = block.timestamp;
         data.current_progress = 0;

        // uint order_close_date_2359 = order_close_date - (order_close_date % 86400) + 86340; //86400 is 24 hours, 86340 is 23 hours 59 minutes, 
        // uint promised_deadline_2359 = promised_deadline - (promised_deadline % 86400) + 86340;
         data.order_close_date = order_close_date;
         data.promised_deadline = promised_deadline;
         
            value = msg.value / 2;
            number_of_buyers = 0; // Initialise number_of_buyers to ZERO
            require((2 * value) == msg.value);
    }
    
    event StatusChanged (string production_status);
    event Aborted();
 event PurchaseConfirmed(address buyer_address);
 event ItemReceived();
    
    function getData() public view returns (DataTypes.ProductData memory) {
        return data;
    }
    
 // -----------------------------------------------------MAIN FUNCTIONS--------------------------------------------------------------
 
 /// Confirm the purchase as a buyer.
 /// Transaction has to include 2 * value ether.
 /// The ether will be locked until confirmReceived is called.
 function confirmPurchase(uint _quantity, address sender)
  public
  inState(EscrowState.Created)
  can_order() // Checks if Production_Status = "ORDERS_OPEN"
  check_payment(msg.value == (2 * value * _quantity))
  payable
 {
     if (sender == address(0)) {
         sender = msg.sender;
     }
     
     uint buyer_quantity = _quantity;
     // Check if buyer has not purchased the item before
     require(orders_not_received[sender] == 0, "You have already purchased this item before!");
     // Check to see if there is enough stock left before allowing buyer to purchase his desired amount
     if (data.max_orders - data.current_orders - buyer_quantity >= 0) {
         emit PurchaseConfirmed(sender);
      // Assume each unique buyer's address can only purchase once:
      buyer.push(sender); // Add buyer's address to buyer array
      number_of_buyers++; // Increse the number_of_buyers by 1
      orders_not_received[sender] = int256(buyer_quantity);
      data.current_orders += buyer_quantity;
     }
  
  // If stock has ran out, lock the escrow wallet with all buyers money.
  if (data.current_orders == data.max_orders) {
      state = EscrowState.Locked;
      data.production_status = "ORDERS_CLOSED";
      data.current_progress = 1;
  }
 }

 /// Confirm that you (the buyer) received the item.
 /// This will release the locked ether to both the buyer and the seller.
 function confirmReceived()
  public
  onlyBuyer
  inState(EscrowState.Locked)
  // It is important to check the status of buyers order because otherwise, the contracts called using send below can call in again here.
  can_confirm_received(msg.sender) 
 {
  emit ItemReceived();
  // Find the index of the current buyer
  uint index_of_buyer = 0;
  for (uint i = 0; i < buyer.length; i++) {
      if (keccak256(abi.encodePacked(buyer[i])) == keccak256(abi.encodePacked(msg.sender))) {
          index_of_buyer = i;
      }
  }
  // Find the quantity that the buyer bought, and set it to ZERO
  uint buyer_quantity = uint(orders_not_received[msg.sender]);
  //Assume buyer has received ALL items, then set to 0 to show it is received and not refunded
  orders_not_received[msg.sender] = 0; 
  // NOTE: This actually allows both the buyer and the seller to block the refund - the withdrawal pattern should be used.
  payable(buyer[index_of_buyer]).transfer(value * buyer_quantity);              // Transfer money from escrow wallet to buyer (1/4)
  if (address(this).balance == (value * data.current_orders + 2 * value)) {     // Only once all buyers have received their products
      payable(data.seller).transfer(address(this).balance);                     // Transfer money from escrow wallet to seller (3/4)
      state = EscrowState.Inactive;
  }
        eventEmitter.emitUserEvents(msg.sender);
 }
 
 /// Abort the purchase and refund the ether to all parties involved.
 /// Can only be called by the seller. Zheng Wen & Josh agree that this can be run at anytime of the product campaign.
 function abort()
  public
  onlySeller
 {
  emit Aborted();
  for (uint i = 0; i < buyer.length; i++) {
      // Refund the buyer if Seller decides to abort the product campaign
      if (orders_not_received[buyer[i]] > 0) {
          payable(buyer[i]).transfer(2 * value * uint(orders_not_received[buyer[i]])); //2 * is because need refund deposit as well
          if (orders_not_received[buyer[i]] != 0) {
              orders_not_received[buyer[i]] = -1; //set to -1 to show that order refunded
          }
          
      }
        }
        data.production_status = 'ORDERS_CANCELLED';
  state = EscrowState.Inactive;
        payable(data.seller).transfer(address(this).balance); // Transfer the remaining money from escrow wallet to seller
        eventEmitter.emitUserEvents(msg.sender);
     eventEmitter.emitProductEvents();
 }
 
 // -----------------------------------------------------TRIGGER FUNCTIONS--------------------------------------------------------------
    
    // (1) PromisedDeadlineFunction
        // Zheng Wen & Josh agree to change this TRIGGER to a FUNCTION that can be run buy "buyer" ONLY
        // -- Method called by an automatic hook when promised_deadline is met
        // ++ function can be called by any buyer instead, after the deadline is passed
    function onPromisedDeadline() 
        onlyBuyer 
        public {
        // Check when promised_deadline_date >= block.timestamp 
        require(block.timestamp / 1 days >= data.promised_deadline / 1 days, "Please wait till Promised Deadline before requesting for a refund!");
        for (uint i = 0; i < buyer.length; i++) {
      if (orders_not_received[buyer[i]] > 0) {
         // Refund the buyer if item not received by Promised Deadline
         payable(buyer[i]).transfer(2 * value * uint(orders_not_received[buyer[i]])); //2 * is because need refund deposit as well
         if (orders_not_received[buyer[i]] != 0) {
              orders_not_received[buyer[i]] = -1; //set to -1 to show that order refunded
          }
      }
        }
        payable(data.seller).transfer(address(this).balance);                         // Transfer the remaining money from escrow wallet to seller
        data.production_status = "ORDERS_ENDED";
        data.current_progress = data.progress.length + 2;
  state = EscrowState.Inactive;
     eventEmitter.emitProductEvents();
     eventEmitter.emitUserEvents(msg.sender);
    }
    
    // (2) checkProductionStatusFunction --> Replace OrderClosedTrigger
        // -- Possible implementaton 1: schedule on the frontend to run this function every few seconds
        // ++ Changed to, Seller can run this function anytime to see once if max orders have been reached, change production_status amd start production
    function checkProductionStatus() onlySeller public {
        // Condition: Need to check also the EscrewState if "Created" and not "Locked" or "Inactive"
        require(keccak256(abi.encodePacked(data.production_status)) != keccak256(abi.encodePacked('orders_cancelled')), "Orders cancelled as Seller has aborted the product campaign!");
        
        // Scenario 1: Current time < timeline.order_close_date BUT data.current_orders == data.max_orders
            // SETTLED IN comfirmPurchase() function
            
        // Scenario 2a: Current time >= timeline.order_close_date, but there is enough buyers, close the campaign and start production
        if (block.timestamp / 1 days >= data.order_close_date / 1 days) {
            if (data.current_orders >= data.min_orders) {
                state = EscrowState.Locked;
          data.production_status = "ORDERS_CLOSED";
          data.current_progress = 1;
                emit StatusChanged(data.production_status);             
            } else {
                
                // Scenario 2b: Not enough buyers by Order Close Date, close the campaign and refund the money to all parties 
                for (uint i = 0; i < buyer.length; i++) {
              if (orders_not_received[buyer[i]] > 0) {
                  // Refund the buyer if item not received by Promised Deadline
                  payable(buyer[i]).transfer(2 * value * uint(orders_not_received[buyer[i]])); //2 * is because need refund deposit as well
                  orders_not_received[buyer[i]] = 0; //set to 0
              }
                }
                payable(data.seller).transfer(address(this).balance);                         // Transfer the remaining money from escrow wallet to seller
          state = EscrowState.Inactive;
                data.production_status = "ORDERS_CANCELLED";
                emit StatusChanged(data.production_status);
            }
            
        eventEmitter.emitUserEvents(msg.sender);
     eventEmitter.emitProductEvents();
        } 
    }

    // ------------------------------------------------------MODIFIERS---------------------------------------------------------------
    
    modifier check_payment(bool _condition) {
        require(_condition, "Insufficient funds! Please pay TWICE the amount of your total product cost.");
        _;
    }
    
    modifier onlyBuyer() {
  // require(msg.sender == data.buyer);   -->     Implementation for a Single Buyer
  bool buyer_exists = false;
  for (uint i = 0; i < buyer.length; i++) {
      if (keccak256(abi.encodePacked(buyer[i])) == keccak256(abi.encodePacked(msg.sender))) {
          buyer_exists = true;
      }
  }
  require(buyer_exists);
  _;
 }

 modifier onlySeller() {
  require(msg.sender == data.seller);
  _;
 }

 modifier inState(EscrowState _state) {
  require(state == _state);
  _;
 }
 
 modifier can_order() {
     require(keccak256(abi.encodePacked(data.production_status)) == keccak256(abi.encodePacked("ORDERS_OPEN")));
        _;
    }
    
    modifier can_confirm_received(address buyer_address) {
        require(orders_not_received[buyer_address] != 0, "You have already confirmed items received or did not purchase this product!");
        _;
    }
    
    modifier can_update_progress() {
        require((data.current_progress > 0) && (data.current_progress < data.progress.length + 1) && 
            (keccak256(abi.encodePacked(data.production_status)) != keccak256(abi.encodePacked("ORDERS_CANCELLED"))), "Cannot make changes to progress!");
        _;
    }
    
    modifier can_add_progress() {
        require((data.current_progress < data.progress.length + 2) && 
            (keccak256(abi.encodePacked(data.production_status)) != keccak256(abi.encodePacked("ORDERS_CANCELLED"))), "Cannot add to progress!") ;
        _;
    }

    
    
    // -----------------------------------------------------PROGRESS BAR HANDLING -----------------------------------------------------

    function addProgress(string memory title, uint timestamp) public can_add_progress {
        require(keccak256(abi.encodePacked(title)) != keccak256(abi.encodePacked("")), "Status cannot be blank!");
        require((timestamp / 1 days >= data.order_close_date / 1 days) && (timestamp / 1 days <= data.promised_deadline / 1 days), "intermediate progress stage has to be between order_close_date & promised_deadline");
        DataTypes.ProgressState memory new_state = DataTypes.ProgressState(title, timestamp);
        data.progress.push(new_state);
        eventEmitter.emitUserEvents(msg.sender);
    }

    
    function setProgressDone() public can_update_progress onlySeller {
        if (block.timestamp / 1 days >= data.promised_deadline / 1 days) {
            data.progress[data.current_progress - 1].timestamp = data.promised_deadline;
        } else if (block.timestamp / 1 days <= data.order_close_date / 1 days) {
            data.progress[data.current_progress - 1].timestamp = data.order_close_date;
        } else {
            data.progress[data.current_progress - 1].timestamp = block.timestamp;
        }
        data.current_progress += 1;
        eventEmitter.emitUserEvents(msg.sender);
    }
}