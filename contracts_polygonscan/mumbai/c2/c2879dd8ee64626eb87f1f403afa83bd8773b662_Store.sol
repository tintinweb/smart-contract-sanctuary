/**
 *Submitted for verification at polygonscan.com on 2021-12-04
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.2;

//import "hardhat/console.sol";

/* TODO: 
 *allow me to force refund
 allow purchases only from owners of ERC20 token, or ERC721 token
   option to disable purchases
 */

abstract contract ERC20 {
  function balanceOf(address a) public view virtual returns (uint256);  
}

contract Store {
  address admin_address;
  uint256 public totalEarned; //amount due to store owner
  uint256 public numOrders; //max order num
  uint32 public numProducts; //max products
  bool public purchasesDisabled;
  
  event ePurchased(uint256 oid);
  event eRefund(uint256 oid, uint256 amount);
  event eInProgress(uint256 oid);
  event eShipped(uint256 oid);
  
  struct ProductStruct {
    uint256 price;
  }

  struct AccessStruct {
    ERC20 econtract;
    uint256 minRequired;
    bool enabled;
  }
    
  ProductStruct[32] public products;
  AccessStruct[16] public accessProfiles;
  
  struct OrderStruct {
    uint32 state; //0 pending, 1 in progress, 2 filled, 3 refunded
    uint32 pid; //product id    
    uint256 boostAmount; //premium staked for order queue
    uint256 paidAmount; //amount paid for order
    address owner;
  }
  
  mapping(uint256 => OrderStruct) orders;

  modifier requireAdmin() {
    require(admin_address == msg.sender,"Requires admin privileges");
    _;
  }

  modifier requireOwner(uint256 oid) {
    if (oid >= numOrders) {
      revert("Order ID out of range");
    }
    
    require(msg.sender == orders[oid].owner,"Not owner of order");
    _;
  }

  modifier requireOwnerOrAdmin(uint256 oid) {
    if (oid >= numOrders) {
      revert("Order ID out of range");
    }
    
    require(msg.sender == orders[oid].owner ||
	    admin_address == msg.sender,"Not owner or admin");
    _;
  }

  constructor() {
    admin_address = msg.sender;    
  }

  function numOrdersByAddress(address a) public view returns (uint32) {
    uint32 n = 0;
    for (uint256 i = 0;i<numOrders;i++) {
      if (orders[i].owner == a) {
	n++;
      }
    }
    return n;
  }
  
  function orderByAddress(address a,uint32 j) public view returns(uint256) {
    if (j >= numOrdersByAddress(a)) {
      revert("Order index out of range");
    }
    
    uint32 n = 0;
    uint256 oid = 0;
    
    for (uint256 i = 0;i<numOrders;i++) {
      if (orders[i].owner == a) {
	if (j==n) {
	  oid = i;
	  break;
	}
	n++;
      }
    }
    return oid;
  }  
  
  function orderDetails(uint256 oid) public view returns (uint32 state, uint32 pid, uint256 boostAmount, uint256 paidAmount, address owner) {
    require(oid < numOrders,"Order id not in range");
    state = orders[oid].state;
    pid = orders[oid].pid;
    boostAmount = orders[oid].boostAmount;
    paidAmount = orders[oid].paidAmount;
    owner = orders[oid].owner;        
  }

  /* only allow access to addresses holding a minimum
     number of ERC20 or ERC721 token */
  function check_elligible(address a) public view returns (bool) {
    bool flag = true;
    for (uint256 i = 0;i<16;i++) {
      if (!accessProfiles[i].enabled) continue;
      if (accessProfiles[i].econtract.balanceOf(a) >=
	  accessProfiles[i].minRequired) {
	return true;
      } else {
	flag = false;
      }
    }
    return flag;
  }
  
  function purchase(uint32 pid) public payable returns(uint256) {
    require(pid < numProducts, "Invalid product id");
    require(!purchasesDisabled,"Purchases disabled");
    require(msg.value>=products[pid].price, "Must send minimum value to purchase!");
    if (!check_elligible(msg.sender)) {
      revert("Not elligible.");
    }
	    
    //send change if too much was sent
    if (msg.value > 0) {
      uint256 diff = msg.value - products[pid].price;
      if (diff > 0) {
	payable(msg.sender).transfer(diff);
      }
    }
    
    //create an order for address together with 'pid'
    orders[numOrders].paidAmount = products[pid].price;
    orders[numOrders].pid = pid;
    orders[numOrders].owner = msg.sender;    

    uint256 oid = numOrders;
    numOrders++;

    emit ePurchased(oid);
    
    return oid;
  }

  function refund(uint32 oid) public payable requireOwnerOrAdmin(oid) {
    require(orders[oid].state==0, "Order not in refundable state");

    //sets order state to refunded    
    orders[oid].state = 3; 

    // refund 95 percent of initial purchase price
    // as well as any premium payed for order queue
    
    uint256 amount_to_refund = orders[oid].paidAmount;
    if (msg.sender != admin_address) {
      // if admin is forcing refund, refund 100% rather than 95%
      amount_to_refund /= 100;
      amount_to_refund *= 95;
    }
    
    //keep 5% cancellation fee
    totalEarned += (orders[oid].paidAmount - amount_to_refund);
//    console.log("Keeping %d",totalEarned);

//    console.log("Refunding %d",amount_to_refund);    
    amount_to_refund += orders[oid].boostAmount;

//    console.log("Refunding total: %d",amount_to_refund);

    emit eRefund(oid,amount_to_refund);

    payable(orders[oid].owner).transfer(amount_to_refund);
  }

  //TODO make these into 1
  function boost(uint32 oid) public payable requireOwner(oid) {
    require(orders[oid].state==0, "Order must be in pending state");    
    //store ether in contract for order 'oid', to determine
    //place in queue
    orders[oid].boostAmount += msg.value;
  }

  function unboost(uint32 oid, uint256 amount) public payable requireOwner(oid) {
    require(orders[oid].state==0, "Order must be in pending state");
    require(amount <= orders[oid].boostAmount,"Limit exceeded");
    require(amount > 0,"Amount must be more than 0");
    
    orders[oid].boostAmount -= amount;
    payable(msg.sender).transfer(amount); //refund boosted amount
  }

  //check what address owns orderID  
  function ownerOf(uint256 oid) public view returns(address) {
    return orders[oid].owner;
  }

  //returns all orders numbers for a particular owner;
  function ordersByOwner(address a) public view returns (uint256[] memory) {
    uint256 [] memory q;

    uint256 num;
    for (uint256 i = 0;i<numOrders;i++) {
      if (orders[i].owner != a) continue;
      num++;
    }
    q = new uint256[](num);
    
    uint256 k = 0;
    for (uint256 i = 0;i<numOrders;i++) {
      if (orders[i].owner != a) continue;      
      q[k] = i;
      k++;
    }

    return q;
  }
  
  //return sorted by boost amount queue of pending orders
  function queue() public view returns (uint256[] memory) {
    uint256 [] memory q;
    
    uint256 numPending;
    for (uint256 i = 0;i<numOrders;i++) {
      if (orders[i].state != 0) continue;
      numPending++;
    }
    q = new uint256[](numPending);
    
    uint256 k = 0;
    for (uint256 i = 0;i<numOrders;i++) {
      if (orders[i].state != 0) continue;
      q[k] = i;
      k++;
    }
    
    //sort in place based on boost value

    if (numPending > 1) {
      bool flag;    
      do {
	flag = false;
	for (uint256 i = 0;i<numPending-1;i++) {
	  if (orders[q[i]].boostAmount < orders[q[i+1]].boostAmount) {
	    uint256 tmp = q[i];
	    q[i] = q[i+1];
	    q[i+1] = tmp;
	    flag = true;
	  }
	}
      } while (flag==true);
    }
    
    return q;
  }
  
  //get order ids and staked amounts for top 2 active queue positions
  function topQueue() public view returns(uint256 oid1, uint256 oid2, uint256 amount1, uint256 amount2) {
    uint256 m1 = 0; //largest boost
    uint256 m2 = 0;    
    uint256 mi1 = 0; // largest boost index
    uint256 mi2 = 0;    

    //if only 1 order, premium paid is 0
    if (numOrders >= 2) {
      for (uint256 i = 0;i<numOrders;i++) {
	if (orders[i].state != 0) continue;
      
	if (orders[i].boostAmount > m1) {
	  m2 = m1;
	  mi2 = mi1;
	  m1 = orders[i].boostAmount;
	  mi1 = i;
	} else if (orders[i].boostAmount > m2) {
	  m2 = orders[i].boostAmount;
	  mi2 = i;
	}
      }
    }
    
    oid1 = mi1;
    oid2 = mi2;
    amount1 = m1;
    amount2 = m2;
  }

  
  function setAccessProfileEnabled(uint32 oid, bool enabled) public requireAdmin {
    require(oid < 16,"Index out of range");
    accessProfiles[oid].enabled = enabled;
  }

  function setStoreEnabled(bool enabled) public requireAdmin {
    purchasesDisabled = !enabled;
  }

  function setAccessProfile(uint32 oid, address a, uint256 minRequired, bool enabled) public requireAdmin {
    accessProfiles[oid].econtract = ERC20(a);
    accessProfiles[oid].minRequired = minRequired;
    accessProfiles[oid].enabled = enabled;
  }
  
  //change an order to in progress, taking payment
  function setInProgress(uint32 oid) public requireAdmin {
    require(oid < numOrders,"Order ID out of range");
    require(orders[oid].state == 0, "Order not in pending state");

    //add amount paid plus differential boost amount to earned stack
    totalEarned += orders[oid].paidAmount;
//    console.log("Banking paid amount: %d",orders[oid].paidAmount);
    
    uint256 premium;
    (,,,premium) = topQueue();
    
    if (premium > orders[oid].boostAmount) {
      premium = orders[oid].boostAmount;
    }
//    console.log("Banking premium: %d",premium);
    totalEarned += premium;

    emit eInProgress(oid);
    
    orders[oid].state = 1;
  }
  
  function setShipped(uint32 oid) public requireAdmin {
    require(oid < numOrders,"Order ID out of range");
    require(orders[oid].state == 1, "Order not in in progress state");
    orders[oid].state = 2; //finalize order

    emit eShipped(oid);    
  }
  
  function setNumProducts(uint32 n) public requireAdmin {
    numProducts = n;
  }

  /* sets details of a product (currently only price is stored on-chain) */
  function setProduct(uint32 pid,uint256 price) public requireAdmin {
    require(pid<numProducts,"Product ID out of range");
    products[pid].price = price;
  }

  /* Shop owner can only withdraw from the stack 'totalEarned',
     which tracks the value of orders that have gone into the 'in progress' state */
  
  function withdraw(uint256 amount) public payable requireAdmin {
    require(amount <= totalEarned,"Earned limit exceeded");
    require(amount <= address(this).balance,"Insufficient funds to withdraw");
    totalEarned -= amount;
    payable(msg.sender).transfer(amount);
  }

  //in case of screw up, allow totalEarned to be adjusted,
  // but only DOWNWARD 
  function adjustTotalEarned(uint256 t) public requireAdmin {
    require (t < totalEarned,"Can only adjust down");
    totalEarned = t;
  }
  
  /* All showopner to make deposits in case of screw up to allow
     those in queue to refund themselves */
  
  function deposit() public payable requireAdmin {
  }
  
}