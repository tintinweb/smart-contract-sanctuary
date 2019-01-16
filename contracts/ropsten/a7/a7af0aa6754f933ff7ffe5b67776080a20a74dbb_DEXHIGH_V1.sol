pragma solidity ^0.4.18;

//기존 REDBLAKCTREE는 동일 가격의 주문을 처리할 수 없음
//이를 위해 동일가격 처리 방식을 넣었으며, 매수 매도의 처리방식도 달리하여 동일 가격의 주문 처리를 가능하게 하였음
//기존 RecBlackTree 라이브러리에서 독자적인 방식으로 직접 수정한 함수내역
//function find(Tree storage tree, uint value, bool isSell) public constant returns (uint32 parentId
//function placeAfter(Tree storage tree, uint32 parent, uint32 id, uint value, bool isSell) internal

library RedBlackTree {

    struct Item {
        bool red;
        uint32 parent;
        uint32 left;
        uint32 right;
        uint value;
    }

    struct Tree {
        uint32 root;
        mapping(uint32 => Item) items;
    }
    
    function find(Tree storage tree, uint value, bool isSell) public constant returns (uint32 parentId) {

        uint32 id = tree.root;
        parentId = id;

        if (id == 0)
            return;

        Item storage item = tree.items[id];

        if (isSell == true)
        {
            while (id != 0)
            {
                if (value == item.value)
                {
                    id = item.right;
                    while (id != 0 && value == item.value)
                    {
                        parentId = id;
                        id = item.right;
                    }
                    return;
                }
    
                parentId = id;
    
                if (value > item.value)
                {
                    id = item.right;
    
                    if (id != 0)
                        parentId = id;
    
                    while (id != 0 && value == item.value)
                    {
                        parentId = id;
                        id = item.right;
                    }
    
                }
                else
                {
                    id = item.left;
    
                    if (id != 0)
                        parentId = id;
    
                    while (id != 0 && value == item.value)
                    {
                        parentId = id;
                        id = item.right;
                    }
                }
            }
        }
        else
        {
            while (id != 0)
            {
            if (value == item.value)
            {
                id = item.left;
                while (id != 0 && value == item.value)
                {
                    parentId = id;
                    id = item.left;
                }
                return;
            }

            parentId = id;

            if (value > item.value)
            {
                id = item.right;

                if (id != 0)
                    parentId = id;

                while (id != 0 && value == item.value)
                {
                    parentId = id;
                    id = item.left;
                }

            }
            else
            {
                id = item.left;

                if (id != 0)
                    parentId = id;

                while (id != 0 && value == item.value)
                {
                    parentId = id;
                    id = item.left;
                }
            }
        }
        }
        return parentId;
    }
    
    function placeAfter(Tree storage tree, uint32 parent, uint32 id, uint value, bool isSell) internal
    {
        Item memory item;
        item.value = value;
        item.parent = parent;
        item.red = true;

        if (parent != 0) {
            Item storage itemParent = tree.items[parent];

            if (value == itemParent.value)
            {
                if (isSell == true)
                {
                    item.right = itemParent.right;
    
                    if (item.right != 0)
                        tree.items[item.right].parent = id;
    
                    if (parent != 0)
                        itemParent.right = id;
                }
                else
                {
                    item.left = itemParent.left;
    
                    if (item.left != 0)
                        tree.items[item.left].parent = id;
    
                    if (parent != 0)
                        itemParent.left = id;
                }
            }
            else if (value < itemParent.value)
            {
                itemParent.left = id;
            }
            else
            {
                itemParent.right = id;
            }
        }
        else
        {
            tree.root = id;
        }

        tree.items[id] = item;
        insert1(tree, id);
    }

    function insert1(Tree storage tree, uint32 n) private
    {
        uint32 p = tree.items[n].parent;
        if (p == 0)
        {
            tree.items[n].red = false;
        }
        else
        {
            if (tree.items[p].red)
            {
                uint32 g = grandparent(tree, n);
                uint32 u = uncle(tree, n);

                if (u != 0 && tree.items[u].red)
                {
                    tree.items[p].red = false;
                    tree.items[u].red = false;
                    tree.items[g].red = true;
                    insert1(tree, g);
                }
                else
                {
                    if ((n == tree.items[p].right) && (p == tree.items[g].left))
                    {
                        rotateLeft(tree, p);
                        n = tree.items[n].left;
                    }
                    else if ((n == tree.items[p].left) && (p == tree.items[g].right))
                    {
                        rotateRight(tree, p);
                        n = tree.items[n].right;
                    }

                    insert2(tree, n);
                }
            }
        }
    }

    function insert2(Tree storage tree, uint32 n) internal
    {
        uint32 p = tree.items[n].parent;
        uint32 g = grandparent(tree, n);

        tree.items[p].red = false;
        tree.items[g].red = true;

        if ((n == tree.items[p].left) && (p == tree.items[g].left))
        {
            rotateRight(tree, g);
        }
        else
        {
            rotateLeft(tree, g);
        }
    }

    function remove(Tree storage tree, uint32 n) internal {
        uint32 successor;
        uint32 nRight = tree.items[n].right;
        uint32 nLeft = tree.items[n].left;

        if (nRight != 0 && nLeft != 0)
        {
            successor = nRight;
            while (tree.items[successor].left != 0)
            {
                successor = tree.items[successor].left;
            }

            uint32 sParent = tree.items[successor].parent;

            if (sParent != n)
            {
                tree.items[sParent].left = tree.items[successor].right;
                tree.items[successor].right = nRight;
                tree.items[sParent].parent = successor;
            }

            tree.items[successor].left = nLeft;

            if (nLeft != 0)
            {
                tree.items[nLeft].parent = successor;
            }
        }
        else if (nRight != 0)
        {
            successor = nRight;
        }
        else
        {
            successor = nLeft;
        }
        
        uint32 p = tree.items[n].parent;

        if (successor != 0)
            tree.items[successor].parent = p;

        if (p != 0)
        {
            if (n == tree.items[p].left)
            {
                tree.items[p].left = successor;
            }
            else
            {
                tree.items[p].right = successor;
            }
        }
        else
        {
            tree.root = successor;
        }

        if (!tree.items[n].red && successor != 0)
        {
            if (tree.items[successor].red)
            {
                tree.items[successor].red = false;
            }
            else
            {
                delete1(tree, successor);
            }
        }

        delete tree.items[n];
        delete tree.items[0];
    }

    function delete1(Tree storage tree, uint32 n) private
    {
        uint32 p = tree.items[n].parent;

        if (p != 0) {
            uint32 s = sibling(tree, n);
            if (tree.items[s].red)
            {
                tree.items[p].red = true;
                tree.items[s].red = false;
                if (n == tree.items[p].left)
                {
                    rotateLeft(tree, p);
                }
                else
                {
                    rotateRight(tree, p);
                }
            }
            delete2(tree, n);
        }
    }

    function delete2(Tree storage tree, uint32 n) private
    {
        uint32 s = sibling(tree, n);
        uint32 p = tree.items[n].parent;
        uint32 sLeft = tree.items[s].left;
        uint32 sRight = tree.items[s].right;
        if (!tree.items[p].red && !tree.items[s].red && !tree.items[sLeft].red && !tree.items[sRight].red)
        {
            tree.items[s].red = true;
            delete1(tree, p);
        }
        else
        {
            if (tree.items[p].red && !tree.items[s].red && !tree.items[sLeft].red && !tree.items[sRight].red)
            {
                tree.items[s].red = true;
                tree.items[p].red = false;
            }
            else
            {
                if (!tree.items[s].red)
                {
                    if (n == tree.items[p].left && !tree.items[sRight].red && tree.items[sLeft].red)
                    {
                        tree.items[s].red = true;
                        tree.items[sLeft].red = false;
                        rotateRight(tree, s);
                    }
                    else if (n == tree.items[p].right && !tree.items[sLeft].red && tree.items[sRight].red)
                    {
                        tree.items[s].red = true;
                        tree.items[sRight].red = false;
                        rotateLeft(tree, s);
                    }
                }
                
                tree.items[s].red = tree.items[p].red;
                tree.items[p].red = false;

                if (n == tree.items[p].left)
                {
                    tree.items[sRight].red = false;
                    rotateLeft(tree, p);
                }
                else
                {
                    tree.items[sLeft].red = false;
                    rotateRight(tree, p);
                }
            }
        }
    }

    function grandparent(Tree storage tree, uint32 n) private returns (uint32)
    {
        return tree.items[tree.items[n].parent].parent;
    }

    function uncle(Tree storage tree, uint32 n) private returns (uint32)
    {
        uint32 g = grandparent(tree, n);
        if (g == 0)
            return 0;

        if (tree.items[n].parent == tree.items[g].left)
            return tree.items[g].right;

        return tree.items[g].left;
    }

    function sibling(Tree storage tree, uint32 n) private returns (uint32)
    {
        uint32 p = tree.items[n].parent;

        if (n == tree.items[p].left)
        {
            return tree.items[p].right;
        }
        else
        {
            return tree.items[p].left;
        }
    }

    function rotateRight(Tree storage tree, uint32 n) private
    {
        uint32 pivot = tree.items[n].left;
        uint32 p = tree.items[n].parent;
        tree.items[pivot].parent = p;

        if (p != 0)
        {
            if (tree.items[p].left == n)
            {
                tree.items[p].left = pivot;
            }
            else
            {
                tree.items[p].right = pivot;
            }
        }
        else
        {
            tree.root = pivot;
        }

        tree.items[n].left = tree.items[pivot].right;

        if (tree.items[pivot].right != 0)
        {
            tree.items[tree.items[pivot].right].parent = n;
        }

        tree.items[n].parent = pivot;
        tree.items[pivot].right = n;
    }

    function rotateLeft(Tree storage tree, uint32 n) private
    {
        uint32 pivot = tree.items[n].right;
        uint32 p = tree.items[n].parent;
        tree.items[pivot].parent = p;

        if (p != 0) {
            if (tree.items[p].left == n)
            {
                tree.items[p].left = pivot;
            }
            else
            {
                tree.items[p].right = pivot;
            }
        }
        else
        {
            tree.root = pivot;
        }

        tree.items[n].right = tree.items[pivot].left;

        if (tree.items[pivot].left != 0)
        {
            tree.items[tree.items[pivot].left].parent = n;
        }

        tree.items[n].parent = pivot;
        tree.items[pivot].left = n;
    }
}
library SafeMath2 {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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

contract SafeMath {
  function safeMul(uint a, uint b) pure public returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) pure public returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) pure public returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}

contract Token {
  /// @return total amount of tokens
  function totalSupply() constant public returns (uint256 supply) {}

  /// @param _owner The address from which the balance will be retrieved
  /// @return The balance
  function balanceOf(address _owner) constant public returns (uint256 balance) {}

  /// @notice send `_value` token to `_to` from `msg.sender`
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transfer(address _to, uint256 _value) public returns (bool success) {}

  /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
  /// @param _from The address of the sender
  /// @param _to The address of the recipient
  /// @param _value The amount of token to be transferred
  /// @return Whether the transfer was successful or not
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

  /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @param _value The amount of wei to be approved for transfer
  /// @return Whether the approval was successful or not
  function approve(address _spender, uint256 _value) returns (bool success) {}

  /// @param _owner The address of the account owning tokens
  /// @param _spender The address of the account able to transfer the tokens
  /// @return Amount of remaining tokens allowed to spent
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  uint public decimals;
  string public name;
}

contract StandardToken is Token {

  function transfer(address _to, uint256 _value) returns (bool success) {
    //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
    //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
    //Replace the if with this one instead.
    if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
    //if (balances[msg.sender] >= _value && _value > 0) {
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(msg.sender, _to, _value);
      return true;
    } else { return false; }
  }

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
    //same as above. Replace this line with the following if you want to protect against wrapping uints.
    if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
    //if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
      balances[_to] += _value;
      balances[_from] -= _value;
      allowed[_from][msg.sender] -= _value;
      Transfer(_from, _to, _value);
      return true;
    } else { return false; }
  }

  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint256 _value) returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  mapping(address => uint256) balances;

  mapping (address => mapping (address => uint256)) allowed;

  uint256 public totalSupply;
}

contract ReserveToken is StandardToken, SafeMath {
  address public minter;
  function ReserveToken() {
    minter = msg.sender;
  }
  function create(address account, uint amount) {
    if (msg.sender != minter) throw;
    balances[account] = safeAdd(balances[account], amount);
    totalSupply = safeAdd(totalSupply, amount);
  }
  function destroy(address account, uint amount) {
    if (msg.sender != minter) throw;
    if (balances[account] < amount) throw;
    balances[account] = safeSub(balances[account], amount);
    totalSupply = safeSub(totalSupply, amount);
  }
}

contract AccountLevels {
  //given a user, returns an account level
  //0 = regular user (pays take fee and make fee)
  //1 = market maker silver (pays take fee, no make fee, gets rebate)
  //2 = market maker gold (pays take fee, no make fee, gets entire counterparty&#39;s take fee as rebate)
  function accountLevel(address user) constant returns(uint) {}
}

contract AccountLevelsTest is AccountLevels {
  mapping (address => uint) public accountLevels;

  function setAccountLevel(address user, uint level) {
    accountLevels[user] = level;
  }

  function accountLevel(address user) constant returns(uint) {
    return accountLevels[user];
  }
}

contract DEXHIGH_V1
{
    using SafeMath2 for uint;
    using RedBlackTree for RedBlackTree.Tree;

    struct OpenOrder
    {
        uint32 startId;
        mapping (uint64 => ListItem) id_orderList;
    }
    
    mapping (address => OpenOrder) holder_OpenOrder;
    
    function AddOpenOrder(uint32 id) private
    {
        OpenOrder storage openOrder = holder_OpenOrder[msg.sender];
        ListItem listItem;
        if (id != 0)
        {
            if (openOrder.startId != 0)
            {
                listItem.next = openOrder.startId;
                openOrder.id_orderList[openOrder.startId].prev = id;
            }
            openOrder.startId = id;
        }
        openOrder.id_orderList[id] = listItem;
    }
    
    function RemoveOpenOrder(uint32 id)
    {
        OpenOrder storage openOrder = holder_OpenOrder[msg.sender];
        if (id != 0)
        {
            ListItem storage removeItem = openOrder.id_orderList[id];
            ListItem replaceItem;
            if (removeItem.next != 0)
            {
                replaceItem = openOrder.id_orderList[removeItem.next];
                replaceItem.prev = removeItem.prev;
            }
    
            if (removeItem.prev != 0)
            {
                replaceItem = openOrder.id_orderList[removeItem.prev];
                replaceItem.next = removeItem.next;
            }
    
            delete openOrder.id_orderList[id];
        }
    }
    
    struct Balance
    {
        uint reserved;
        uint available;
    }

    struct ListItem
    {
        uint32 prev;
        uint32 next;
    }

    struct Order
    {
        address owner;
        address token;
        uint amount;
        uint price;
        bool sell;
        uint64 timestamp;
    }

    struct Pair
    {
        mapping (uint64 => ListItem) orderbook;
        RedBlackTree.Tree pricesTree;
        uint32 bestBid;
        uint32 bestAsk;
    }

    mapping (address => mapping (address => Balance)) private balances;

    uint32 lastOrderId;
    mapping(uint32 => Order) orders;
    mapping(address => Pair) pairs;

    event Deposit(address indexed token, address indexed owner, uint amount);
    event Withdraw(address indexed token, address indexed owner, uint amount);
    
    //https://ethereum.stackexchange.com/questions/43459/what-are-limitations-of-event-arguments
    //If we increse it anymore the compilation error accurs: "Stack too deep" by Sandeep;
    //This should be fixed later
    event NewOrder(address indexed token, address indexed owner, uint32 id, bool isSell, uint price);//, uint amount, uint64 timestamp);
    event NewAsk(address indexed token, uint price);
    event NewBid(address indexed token, uint price);
    event NewTrade(address indexed token, uint32 indexed bidId, uint32 indexed askId, bool isSell, uint price, uint amount, uint64 timestamp);

    modifier isToken(address token) {
        require(token != 0);
        _;
    }

    function DEXHIGH_V1() public {
    }

    function depositETH() payable public
    {
        Balance storage balance = balances[0][msg.sender];
        balance.available = balance.available.add(msg.value);
        Deposit(0, msg.sender, msg.value);
    }

    function withdrawETH(uint amount) public
    {
        Balance storage balance = balances[0][msg.sender];
        balance.available = balance.available.sub(amount);
        require(msg.sender.call.value(amount)());
        Withdraw(0, msg.sender, amount);
    }

    function depositERC20(StandardToken token, uint amount) public
    {
        Balance storage balance = balances[token][msg.sender];
        token.transferFrom(msg.sender, this, amount);
        balance.available = balance.available.add(amount);
        Deposit(token, msg.sender, amount);
    }
 
    function withdrawERC20(StandardToken token, uint amount) public
    {
        Balance storage balance = balances[token][msg.sender];
        balance.available = balance.available.sub(amount);
        token.transfer(msg.sender, amount);
        Withdraw(token, msg.sender, amount);
    }
    
    function excludeItem(Pair storage pair, uint32 id) private returns (ListItem)
    {
        ListItem storage removeItem = pair.orderbook[id];
        ListItem storage replaceItem;
        if (removeItem.next != 0)
        {
            replaceItem = pair.orderbook[removeItem.next];
            replaceItem.prev = removeItem.prev;
        }

        if (removeItem.prev != 0)
        {
            replaceItem = pair.orderbook[removeItem.prev];
            replaceItem.next = removeItem.next;
        }
        
        pair.pricesTree.remove(id);
    
        delete pair.orderbook[id];
        delete orders[id];

        return removeItem;
    }
}/*

    function LimitOrder(address token, bool isSell, uint amount, uint price) public returns (uint32)
    {
        Balance storage balance = balances[0][msg.sender];
        
        if (isSell)
        {
            balance.available = balance.available.sub(amount);
            balance.reserved = balance.reserved.add(amount);
        }
        else
        {
            balance.available = balance.available.sub(amount.mul(price));
            balance.reserved = balance.reserved.add(amount.mul(price));
        }

        Order memory order;
        order.token = token;
        order.sell = isSell;
        order.owner = msg.sender;
        order.price = price;
        order.amount = amount;
        order.timestamp = uint64(now);

        uint32 newId = ++lastOrderId;
        NewOrder(token, msg.sender, newId, isSell, price);//, amount, order.timestamp);

        Pair storage pair = pairs[token];
        matchOrder(token, pair, order, newId);

        if (order.amount != 0)
        {
            uint32 parentId = pair.pricesTree.find(price, isSell);

            ListItem storage newItem;
            if (parentId != 0)
            {
                ListItem storage parent = pair.orderbook[parentId];

                if (price <= orders[parentId].price)
                {
                    newItem.prev = parentId;
                    newItem.next = parent.next;

                    parent.next = newId;
                }
                else
                {
                    newItem.prev = parent.prev;
                    newItem.next = parentId;

                    if (parent.prev != 0)
                    {
                        ListItem storage parentPrev = pair.orderbook[parent.prev];
                        parentPrev.next = newId;
                    }

                    parent.prev = newId;
                }
            }

            if (newItem.prev == 0)
            {
                pair.bestBid = newId;
                NewBid(token, order.price);
            }
            orders[newId] = order;
            pair.orderbook[newId] = newItem;
            AddOpenOrder(newId);

            pair.pricesTree.placeAfter(parentId, newId, price, isSell);
        }
        return newId;
    }

    function matchOrder(address token, Pair storage pair, Order order, uint32 id) private
    {
        uint32 currentOrderId;
        
        if (order.sell == true)
        {
            currentOrderId = pair.bestBid;
        }
        else
        {
            currentOrderId = pair.bestAsk;
        }
            
        while (currentOrderId != 0 && order.amount > 0 && order.price <= orders[currentOrderId].price)
        {
            Order memory matchingOrder = orders[currentOrderId];
            uint tradeAmount;

            if (matchingOrder.amount >= order.amount)
            {
                tradeAmount = order.amount;
                matchingOrder.amount -= order.amount;
                order.amount = 0;
            }
            else
            {
                tradeAmount = matchingOrder.amount;
                order.amount -= matchingOrder.amount;
                matchingOrder.amount = 0;
            }
            
            Balance storage balanceToken;
            Balance storage balanceETH;
            if (order.sell == true)
            {
                balanceToken = balances[token][order.owner];
                balanceETH = balances[0][order.owner];
    
                balanceToken.reserved -= tradeAmount;
                balanceToken.available += tradeAmount;
    
                balanceETH.reserved -= tradeAmount * matchingOrder.price;
                balanceETH.available += tradeAmount * matchingOrder.price;
            }
            else
            {
                balanceETH = balances[0][order.owner];
                balanceToken = balances[token][order.owner];
    
                balanceETH.reserved -= tradeAmount * order.price;
                balanceETH.available += tradeAmount * (order.price - matchingOrder.price);
                balanceToken.available += tradeAmount;
    
                Balance storage balanceETHCp = balances[0][matchingOrder.owner];
                Balance storage balanceTokenCp = balances[token][matchingOrder.owner];
    
                balanceTokenCp.reserved -= tradeAmount;
                balanceETHCp.available += tradeAmount * matchingOrder.price;
            }

            NewTrade(token, currentOrderId, id, order.sell, matchingOrder.price, tradeAmount, uint64(now));

            if (matchingOrder.amount != 0)
            {
                orders[currentOrderId] = matchingOrder;
                break;
            }

            //currentOrderId = pair.orderbook[id].prev;
            //excludeItem(pair, currentOrderId);
            ListItem memory item = excludeItem(pair, currentOrderId);
            RemoveOpenOrder(currentOrderId);
            currentOrderId = item.prev;
        }

        if (pair.bestBid != currentOrderId)
        {
            pair.bestBid = currentOrderId;

            if (currentOrderId != 0)
                NewBid(token, orders[currentOrderId].price);
            else
                NewBid(token, 0);
        }
    }

    function cancelOrder(address token, uint32 id) isToken(token) public
    {
        Order memory order = orders[id];
        require(order.owner == msg.sender);

        if (order.sell)
        {
            Balance storage balanceToken = balances[token][msg.sender];
            balanceToken.reserved -= order.amount;
            balanceToken.available += order.amount;
        }
        else
        {
            Balance storage balanceETH = balances[0][msg.sender];
            balanceETH.reserved -= order.amount * order.price;
            balanceETH.available += order.amount * order.price;
        }

        Pair storage pair = pairs[token];

        ListItem memory removeItem;

        removeItem = excludeItem(pair, id);
        
        RemoveOpenOrder(id);
        
        if (pair.bestBid == id)
        {
            pair.bestBid = removeItem.next;

            if (pair.bestBid != 0)
                NewBid(token, orders[pair.bestBid].price);
            else
                NewBid(token, 0);
        }
        else if (pair.bestAsk == id)
        {
            pair.bestAsk = removeItem.next;

            if (pair.bestAsk != 0)
                NewAsk(token, orders[pair.bestAsk].price);
            else
                NewAsk(token, 0);
        }
    }

    function getBalance(address token, address trader) public constant returns (uint available, uint reserved)
    {
        available = balances[token][trader].available;
        reserved = balances[token][trader].reserved;
    }

    function getOrderBookInfo(address token) public constant returns (uint32 firstOrder, uint32 bestBid, uint32 bestAsk, uint32 lastOrder)
    {
        Pair memory pair = pairs[token];
        bestBid = pair.bestBid;
        bestAsk = pair.bestAsk;
    }

    function getOrder(address token, uint32 id) public constant returns (uint price, bool sell, uint amount, uint32 next, uint32 prev)
    {
        Order memory order = orders[id];
        price = order.price;
        sell = order.sell;
        amount = order.amount;
        next = pairs[token].orderbook[id].next;
        prev = pairs[token].orderbook[id].prev;
    }
    
    function GetMyOrders() public constant returns (address[] tokens, uint[] amounts, uint[] prices, bool[] sells, uint64[] timestamps)
    {
        OpenOrder storage openOrder = holder_OpenOrder[msg.sender];

        uint32 id = openOrder.startId;
        ListItem item;
        
        if (id != 0)
        {
            Order order;
            uint32 i = 0;
            while (id != 0)
            {
                order = orders[id];
                tokens[i] = order.token;
                amounts[i] = order.amount;
                prices[i] = order.price;
                sells[i] = order.sell;
                timestamps[i] = order.timestamp;

                id = openOrder.id_orderList[id].next;
                i++;
            }
        }
    }
    
    function GetOrderBookScreen(address token, uint tickN) public constant returns (uint[] priceB, uint[] volumeB, uint[] priceA, uint[] volumeA)
    {
        Pair storage pair = pairs[token];

        Order storage order;
        uint32 i;
        uint32 n = 0;
        uint32 currentOrderId = pair.bestBid;
        uint volume = 0;
        uint price = 0;

        currentOrderId = pair.bestBid;
        n = 0;

        while (n < tickN && currentOrderId > 0)
        {
            order = orders[currentOrderId];

            if (currentOrderId == pair.bestBid)
            {
                price = order.price;
                volume = 0;
            }

            if (price == order.price)
                volume += order.amount;
            else
            {
                price = order.price;
                volume = order.amount;
                n++;
            }

            priceB[n] = price;
            volumeB[n] = volume;

            currentOrderId = pair.orderbook[currentOrderId].next;
        }

        if (pair.bestBid > 0)
        {
            for (i = n + 1; i < tickN; i++)
            {
                priceB[i] = GetDownTickPrice(priceB[i - 1]);
            }
        }

        currentOrderId = pair.bestAsk;
        n = 0;
        while (n < tickN && currentOrderId > 0)
        {
            order = orders[currentOrderId];

            if (currentOrderId == pair.bestAsk)
            {
                price = order.price;
                volume = 0;
            }

            if (price == order.price)
                volume += order.amount;
            else
            {
                price = order.price;
                volume = order.amount;
                n++;
            }

            priceA[n] = price;
            volumeA[n] = volume;

            currentOrderId = pair.orderbook[currentOrderId].next;
        }

        if (pair.bestBid > 0 || pair.bestAsk > 0)
        {
            if (pair.bestAsk == 0)
            {
                priceA[0] = GetUpTickPrice(priceB[0]);
            }

            for (i = n + 1; i < tickN; i++)
            {
                priceA[i] = GetUpTickPrice(priceA[i - 1]);
            }
        }
    }
    

    function GetFixedPrice(uint lPrice) public constant returns (uint)
    {
        return GetPriceByN(GetNbyPrice(lPrice));
    }

    function GetTickSize(uint lPrice) public constant returns (uint)
    {
        uint digit = 0;
        uint firstNum = 0;
        return GetTickSize(lPrice, digit, firstNum);
    }

    function GetTickSize(uint lPrice, uint digit, uint firstNum)  public constant returns (uint)
    {
        digit = 0;
        uint tickSize = 1;
        while (lPrice >= 10)
        {
            digit++;
            if (digit > 3) tickSize *= 10;
            lPrice /= 10;
        }

        firstNum = lPrice;

        if (firstNum >= 5 && digit >= 3)
            return tickSize * 5;
        else
            return tickSize;
    }

    function GetUpTickPrice(uint lPrice) public constant returns (uint)
    {
        lPrice = GetFixedPrice(lPrice);
        return lPrice + GetTickSize(lPrice);
    }

    function GetDownTickPrice(uint lPrice) public constant returns (uint)
    {
        uint temp = lPrice;
        lPrice = GetFixedPrice(lPrice);
        if (lPrice < temp)
            return lPrice;
        else
        {
            uint tickSize = GetTickSize(lPrice - 1);

            if (lPrice > tickSize)
            {
                return lPrice - tickSize;
            }
            else
            {
                return 1;
            }
        }
    }

    function GetNbyPrice(uint lPrice) public constant returns (uint)
    {
        uint lTickSize = 0;
        uint digit = 0;
        uint firstNum = 0;

        uint baseN = GetBaseN(lPrice, lTickSize, digit, firstNum);
        uint lBasePrice = GetBasePrice(digit, firstNum);
        return (uint)((lPrice - lBasePrice) / lTickSize) + baseN;
    }

    function GetBaseN(uint lPrice, uint lTickSize, uint digit, uint firstNum) private constant returns (uint)
    {
        uint N;
        lTickSize = GetTickSize(lPrice, digit, firstNum);

        if (digit >= 3)
        {
            N = 1000 + (digit - 3) * (4000 + 1000);

            if (firstNum >= 5)
                N += 4000;
        }
        else
            N = 0;

        return N;
    }

    function GetPriceByN(uint N) public constant returns(uint)
    {
        if (N > 1000)
        {
            uint i = 1000;
            uint price = i;
            uint tickSize = 1;
            while (true)
            {
                if (i + 4000 > N) break;
                price += 4000 * tickSize;
                tickSize *= 5;
                i += 4000;

                if (i + 1000 > N) break;
                price += 1000 * tickSize;
                tickSize *= 2;
                i += 1000;
            }
            return (N - i) * tickSize + price;

        }
        else
            return N;
    }

    function GetBasePrice(uint digit, uint firstNum) private constant returns(uint)
    {
        uint lBasePrice = 0;

        if (digit >= 3)
        {
            lBasePrice = 1;
            for (uint i = 0; i < digit; i++)
                lBasePrice *= 10;

            if (firstNum >= 5)
                lBasePrice *= 5;
        }

        return lBasePrice;
    }
}
/*
contract DEXHIGH is DEXHIGH_V1 {
  address public admin; //the admin address
  address public feeAccount; //the account that will receive fees
  address public accountLevelsAddr; //the address of the AccountLevels contract
  uint public feeMake; //percentage times (1 ether)
  uint public feeTake; //percentage times (1 ether)
  uint public feeRebate; //percentage times (1 ether)
  mapping (address => mapping (address => uint)) public tokens; //mapping of token addresses to mapping of account balances (token=0 means Ether)
  mapping (address => mapping (bytes32 => bool)) public orders; //mapping of user accounts to mapping of order hashes to booleans (true = submitted by user, equivalent to offchain signature)
  mapping (address => mapping (bytes32 => uint)) public orderFills; //mapping of user accounts to mapping of order hashes to uints (amount of order that has been filled)

  event eOrder(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user);
  event Cancel(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s);
  event Trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address get, address give);
  event Deposit(address token, address user, uint amount, uint balance);
  event Withdraw(address token, address user, uint amount, uint balance);

  function DEXHIGH(address admin_, address feeAccount_, address accountLevelsAddr_, uint feeMake_, uint feeTake_, uint feeRebate_) public {
    admin = admin_;
    feeAccount = feeAccount_;
    accountLevelsAddr = accountLevelsAddr_;
    feeMake = feeMake_;
    feeTake = feeTake_;
    feeRebate = feeRebate_;
  }

  function() public {
    revert();
  }

  function changeAdmin(address admin_) {
    if (msg.sender != admin) throw;
    admin = admin_;
  }

  function changeAccountLevelsAddr(address accountLevelsAddr_) {
    if (msg.sender != admin) throw;
    accountLevelsAddr = accountLevelsAddr_;
  }

  function changeFeeAccount(address feeAccount_) {
    if (msg.sender != admin) throw;
    feeAccount = feeAccount_;
  }

  function changeFeeMake(uint feeMake_) {
    if (msg.sender != admin) throw;
    if (feeMake_ > feeMake) throw;
    feeMake = feeMake_;
  }

  function changeFeeTake(uint feeTake_) {
    if (msg.sender != admin) throw;
    if (feeTake_ > feeTake || feeTake_ < feeRebate) throw;
    feeTake = feeTake_;
  }

  function changeFeeRebate(uint feeRebate_) {
    if (msg.sender != admin) throw;
    if (feeRebate_ < feeRebate || feeRebate_ > feeTake) throw;
    feeRebate = feeRebate_;
  }

  function deposit() payable {
      depositETH();
      Deposit(0, msg.sender, msg.value, tokens[0][msg.sender]);
  }

  function withdraw(uint amount) {
      withdrawETH(amount);
      Withdraw(0, msg.sender, amount, tokens[0][msg.sender]);
  }

  function depositToken(address token, uint amount) {
      depositERC20(StandardToken(token), amount);
      Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
  }

  function withdrawToken(address token, uint amount) {
      withdrawERC20(StandardToken(token), amount);
      Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
  }

  function balanceOf(address token, address user) constant returns (uint) {
      uint A;
      uint B;
      (A, B) = getBalance(token,user);
    return A;
  }

  function order(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce) {
      if (tokenGet != 0x0)
      {
          LimitOrder(tokenGive, false, amountGive, amountGet);
      }
      else
      {
          LimitOrder(tokenGet, true, amountGet, amountGive);
      }
      eOrder(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender);
  }

  function trade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount) {

    Trade(tokenGet, amount, tokenGive, amountGive * amount / amountGet, user, msg.sender);
  }

  function tradeBalances(address tokenGet, uint amountGet, address tokenGive, uint amountGive, address user, uint amount) private {
  }

  function testTrade(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s, uint amount, address sender) constant returns(bool) {
    if (!(
      tokens[tokenGet][sender] >= amount &&
      availableVolume(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, user, v, r, s) >= amount
    )) return false;
    return true;
  }

  function availableVolume(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) constant returns(uint) {
      uint A;
      uint B;
      (A, B) = getBalance(tokenGet,user);
    return A;
  }

  function amountFilled(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, address user, uint8 v, bytes32 r, bytes32 s) constant returns(uint) {
    bytes32 hash = sha256(this, tokenGet, amountGet, tokenGive, amountGive, expires, nonce);
    return orderFills[user][hash];
  }

  function cancelOrder(address tokenGet, uint amountGet, address tokenGive, uint amountGive, uint expires, uint nonce, uint8 v, bytes32 r, bytes32 s) public 
  {
      cancelOrder(tokenGet, uint32(nonce));
    Cancel(tokenGet, amountGet, tokenGive, amountGive, expires, nonce, msg.sender, v, r, s);
  }
}*/