pragma solidity ^0.4.21;
/// @author MinakoKojima (https://github.com/lychees)

contract OwnerableContract{
    
  address public owner;
  mapping (address => bool) public admins;
  
  /* Modifiers */
  modifier onlyOwner() {
    require(owner == msg.sender);
    _;
  }

  modifier onlyAdmins() {
    require(admins[msg.sender]);
    _;
  }    
  
  /* Owner */
  function setOwner (address _owner) onlyOwner() public {
    owner = _owner;
  }

  function addAdmin (address _admin) onlyOwner() public {
    admins[_admin] = true;
  }

  function removeAdmin (address _admin) onlyOwner() public {
    delete admins[_admin];
  }  
  
  /* Withdraw */
  function withdrawAll () onlyAdmins() public {
   msg.sender.transfer(address(this).balance);
  }

  function withdrawAmount (uint256 _amount) onlyAdmins() public {
    msg.sender.transfer(_amount);
  }  
}

contract SponsorToken is OwnerableContract{
  struct Order {
    address issuer;
    uint256 tokenId;

    // TODO maxint
    uint256 tip_balance_sum;
    uint256 tip_balance_holder_len;

    // queue, starts with 1
    address[] tip_balance_holder;
    // to queue id
    mapping (address => uint256) tipper_to_holder_id;
    // locked balance
    mapping (address => uint256) tip_balance;
    // withdrawable balance
    mapping (address => uint256) tip_reward_balance;
  }

  Order[] private orderBook;
  uint256 private orderBookSize;
  uint256 constant tip_balance_holder_head = 1;

  /* Util */
  function isContract(address addr) internal view returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) } // soliumdisableline
    return size > 0;
  }  

  constructor() public {
    owner = msg.sender;
    admins[owner] = true;    
  }

  /* ERC721 */
  function name() public pure returns (string _name) {
    return &quot;Sponsor Token&quot;;
  }
  
  /* Read */
  function isAdmin(address _admin) public view returns (bool _isAdmin) {
    return admins[_admin];
  }
  function totalOrder() public view returns (uint256 _totalOrder) {
    return orderBookSize;
  }
  // TODO complete order info
  function getOrder(uint256 _id) public view returns (address _issuer /*, uint256 _tokenId, uint256 _ponzi*/) {
    return (orderBook[_id].issuer /**/ );
  }
  
  // create Order
  function put(address _issuer, uint256 _tokenId) public {
    Issuer issuer = Issuer(_issuer);
    require(issuer.ownerOf(_tokenId) == msg.sender);
    address[] memory empty;
    if (orderBookSize == orderBook.length) {
      orderBook.push(Order(_issuer, _tokenId, 0/* tip_balance_sum */, 0/* tip_balance_holder_len */, empty));
    } else {
      orderBook[orderBookSize] = Order(_issuer, _tokenId, 0/* tip_balance_sum */, 0/* tip_balance_holder_len */, empty);
    }
    orderBookSize += 1;
  }

  function inTipperQueue(uint256 _id, address tipper) view private returns (bool inQueue) {
    require(_id < orderBookSize);
    return orderBook[_id].tipper_to_holder_id[tipper] >= tip_balance_holder_head;
  }
  function addToTipperQueue(uint256 _id, address tipper) private {
    require(_id < orderBookSize);
    orderBook[_id].tip_balance_holder_len ++;
    uint256 holder_id = orderBook[_id].tip_balance_holder_len;
    orderBook[_id].tipper_to_holder_id[tipper] = holder_id;
    orderBook[_id].tip_balance_holder[holder_id] = tipper;
  }
  
  function getTipperPercentage(uint256 _id, uint256 tipper_id) view private returns (uint256 percentage) {
    require(_id < orderBookSize);
    if (tipper_id > orderBook[_id].tip_balance_holder_len) {
      return 0;
    }
    address holder = orderBook[_id].tip_balance_holder[tipper_id];
    uint256 balance = orderBook[_id].tip_balance[holder];
    uint256 sum = orderBook[_id].tip_balance_sum;

    return balance / sum * 100;
  }
  function addTipBalance(uint256 _id, address tipper, uint256 amount) private {
    require(_id < orderBookSize);
    orderBook[_id].tip_balance[tipper] += amount;
    orderBook[_id].tip_balance_sum += amount;
    // add to queue if needed
    if (!inTipperQueue(_id, tipper)) {
      addToTipperQueue(_id, tipper);
    }
  }

  function withdrawTipBalance(uint256 _id, address tipper, uint256 amount) private {
    require(_id < orderBookSize);
    require(amount <= orderBook[_id].tip_balance[tipper]);
    orderBook[_id].tip_balance_sum -= amount;

    orderBook[_id].tip_balance[tipper] -= amount;
    orderBook[_id].tip_reward_balance[tipper] -= amount;
    // (?) remove from queue
  }

  // sponsor Order
  function sponsor(uint256 _id, address _referrer) public payable{
    require(_id < orderBookSize);
    require(!isContract(msg.sender));
    require(_referrer != msg.sender);
    
    // 3% cut off for Issuer
    uint256 tipValue = msg.value * 97 / 100;

    Issuer issuer = Issuer(orderBook[_id].issuer);
    issuer.ownerOf(orderBook[_id].tokenId).transfer(msg.value - tipValue);

    addTipBalance(_id, msg.sender, tipValue); 

    // there&#39;s referrer
    if (_referrer != address(0) && orderBook[_id].tip_balance[_referrer] != 0) {
      if (tipValue <= orderBook[_id].tip_balance[_referrer]) {
        withdrawTipBalance(_id, _referrer, tipValue);
        tipValue = 0;
      } else {
        tipValue -= orderBook[_id].tip_balance[_referrer];
        withdrawTipBalance(_id, _referrer, orderBook[_id].tip_balance[_referrer]);
      }      
    }

    uint256 id = tip_balance_holder_head;
    uint256 p = getTipperPercentage(_id, id);
    uint256 tipValueToShare = tipValue;
    while (tipValueToShare > 0) {
      while (p != 0) {
        uint256 maxWithdrawShare = tipValueToShare * p;
        address holder = orderBook[_id].tip_balance_holder[id];
        uint256 holderBalance = orderBook[_id].tip_balance[holder];

        if (maxWithdrawShare < holderBalance) {
          withdrawTipBalance(_id, holder, maxWithdrawShare);
          tipValue -= maxWithdrawShare;
        } else {
          withdrawTipBalance(_id, holder, holderBalance);
          tipValue -= holderBalance;
        }

        id ++;
        p = getTipperPercentage(_id, id);
      }
      tipValueToShare = tipValue;
    }
  }
}

interface Issuer {
  function transferFrom(address _from, address _to, uint256 _tokenId) external;  
  function transfer(address _to, uint256 _tokenId) external;
  function ownerOf (uint256 _tokenId) external view returns (address _owner);
}