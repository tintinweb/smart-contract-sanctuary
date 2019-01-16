pragma solidity ^0.4.25;

//기존 REDBLAKCTREE는 동일 가격의 주문을 처리할 수 없음
//이를 위해 동일가격 처리 방식을 넣었으며, 매수 매도의 처리방식도 달리하여 동일 가격의 주문 처리를 가능하게 하였음
//기존 RecBlackTree 라이브러리에서 독자적인 방식으로 직접 수정한 함수내역
//function find(Tree storage tree, uint value, bool isSell) public constant returns (uint32 parentId
//function placeAfter(Tree storage tree, uint32 parent, uint32 id, uint value, bool isSell) internal

contract RedBlackTree {

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
    
    function find(Tree storage tree, uint value, bool isSell) internal returns (uint32 parentId) 
    {
        uint32 id = tree.root;
        parentId = id;
        
        if (isSell)
        {
            while (id != 0)
            {
                if (value == tree.items[id].value)
                {
                    id = tree.items[id].right;
                    while (id != 0 && value == tree.items[id].value)
                    {
                        parentId = id;
                        id = tree.items[id].right;
                    }

                    break;
                }

                parentId = id;

                if (value > tree.items[id].value)
                {
                    id = tree.items[id].right;

                    if (id != 0)
                        parentId = id;

                    while (id != 0 && value == tree.items[id].value)
                    {
                        parentId = id;
                        id = tree.items[id].right;
                    }
                }
                else
                {
                    id = tree.items[id].left;

                    if (id != 0)
                        parentId = id;

                    while (id != 0 && value == tree.items[id].value)
                    {
                        parentId = id;
                        id = tree.items[id].right;
                    }
                }
            }
        }
        else
        {
            while (id != 0)
            {
                if (value == tree.items[id].value)
                {
                    id = tree.items[id].left;// .right;
                    while (id != 0 && value == tree.items[id].value)// tree.items.ContainsKey(id) && value == tree.items[id].value)
                    {
                        parentId = id;
                        id = tree.items[id].left;// .right;
                    }

                    break;
                }

                parentId = id;

                if (value > tree.items[id].value)
                {
                    id = tree.items[id].right;

                    if (id != 0)
                        parentId = id;

                    while (id != 0 && value == tree.items[id].value)
                    {
                        parentId = id;
                        id = tree.items[id].left;// .right;
                    }
                }
                else
                {
                    id = tree.items[id].left;

                    if (id != 0)
                        parentId = id;

                    while (id != 0 && value == tree.items[id].value)
                    {
                        parentId = id;
                        id = tree.items[id].left;// .right;
                    }
                }
            }
        }
        return parentId;
    }
    
    function placeAfterAsk(Tree storage tree, uint32 parent, uint32 id, uint value) internal
    {
        Item memory item;
        item.value = value;
        item.parent = parent;
        item.red = true;

        if (parent != 0) {
            Item storage itemParent = tree.items[parent];

            if (value == itemParent.value)
            {
                item.right = itemParent.right;

                if (item.right != 0)
                    tree.items[item.right].parent = id;

                if (parent != 0)
                    itemParent.right = id;
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
    
    function placeAfterBid(Tree storage tree, uint32 parent, uint32 id, uint value) internal
    {
        Item memory item;
        item.value = value;
        item.parent = parent;
        item.red = true;

        if (parent != 0) {
            Item storage itemParent = tree.items[parent];

            if (value == itemParent.value)
            {
                    item.left = itemParent.left;
    
                    if (item.left != 0)
                        tree.items[item.left].parent = id;
    
                    if (parent != 0)
                        itemParent.left = id;
                
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

    function grandparent(Tree storage tree, uint32 n) view private returns (uint32)
    {
        return tree.items[tree.items[n].parent].parent;
    }

    function uncle(Tree storage tree, uint32 n) view private returns (uint32)
    {
        uint32 g = grandparent(tree, n);
        if (g == 0)
            return 0;

        if (tree.items[n].parent == tree.items[g].left)
            return tree.items[g].right;

        return tree.items[g].left;
    }

    function sibling(Tree storage tree, uint32 n) view private returns (uint32)
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


contract DEXHIGH is RedBlackTree, SafeMath
{
    struct OpenOrder
    {
        uint32 orderN;
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
        openOrder.orderN += 1;
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

            if (id == openOrder.startId)
            {
                openOrder.startId = removeItem.next;
            }
    
            delete openOrder.id_orderList[id];
            openOrder.orderN -= 1;
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
        Tree pricesTreeBid;
        Tree pricesTreeAsk;
        uint32 bestBid;
        uint32 bestAsk;
    }

    mapping (address => mapping (address => Balance)) public balances;

    uint32 lastOrderId;
    mapping(uint32 => Order) orders;
    mapping(address => Pair) pairs;

    event Deposit(address indexed token, address indexed owner, uint amount);
    event Withdraw(address indexed token, address indexed owner, uint amount);
    
    //https://ethereum.stackexchange.com/questions/43459/what-are-limitations-of-event-arguments
    //If we increse it anymore the compilation error accurs: "Stack too deep" by Sandeep;
    //This should be fixed later
    event NewOrder(address indexed token, address indexed owner, uint32 id, bool isSell, uint price, uint64 timestamp);//, uint amount, uint64 timestamp);
    event NewAsk(address indexed token, uint price);
    event NewBid(address indexed token, uint price);
    event NewTrade(address indexed token, uint32 indexed bidId, uint32 indexed askId, bool isSell, uint price, uint amount, uint64 timestamp);

    modifier isToken(address token) {
        require(token != 0);
        _;
    }

    function DEXHIGH_V1() public {
    }
    
    
    function TestBalance(address token) public
    {
        balances[0][msg.sender].available = 1000000000000000000;
        balances[token][msg.sender].available = 1000000000000000000;
    }
    
    function TestOrder(address token) public
    {
        LimitOrder(token, true, 1, 10);
    }
    
    function TestOrder2(address token) public
    {
        LimitOrder(token, false, 1, 11);
    }
    
    function GetBidSeries(address token) public returns ( uint32[])
    {
        Pair pair = pairs[token];
        uint32 bestBid = pair.bestBid;
        uint32[] bidSeries;
        ListItem item = pair.orderbook[bestBid];
        
        if (bestBid != 0)
        {
            bidSeries.push(bestBid);
        }
        
        int i = 0;
        while (item.next != 0)
        {
            bidSeries.push(item.next);
            item = pair.orderbook[item.next];
            
            if (i++ > 10)
                break;
        }
        return bidSeries;
    }
    
    function GetSeries() public returns (uint32[])
    {
        uint32[] series;
        series.push(1);
        series.push(2);
        series.push(3);
        
        return series;
    }
    
    function GetAskSeries(address token) public constant returns ( uint32[])
    {
        Pair pair = pairs[token];
        uint32 bestBid = pair.bestAsk;
        uint32[] bidSeries;
        ListItem item = pair.orderbook[bestBid];
        
        if (bestBid != 0)
        {
            bidSeries.push(bestBid);
        }
        
        int i = 0;
        while (item.next != 0)
        {
            bidSeries.push(item.next);
            item = pair.orderbook[item.next];
            
            if (i++ > 10)
                break;
        }
        return bidSeries;
    }


    function LimitOrder(address token, bool isSell, uint amount, uint price) public returns (uint32)
    {
        Balance storage balance;
        
        if (isSell)
        {
            balance = balances[token][msg.sender];
            balance.available = SafeMath.safeSub(balance.available, amount);
            balance.reserved = SafeMath.safeAdd(balance.reserved, amount);
        }
        else
        {
            balance = balances[0][msg.sender];
            balance.available = SafeMath.safeSub(balance.available, SafeMath.safeMul(amount, price));
            balance.reserved = SafeMath.safeAdd(balance.reserved, SafeMath.safeMul(amount, price));
        }

        Order memory order;
        order.token = token;
        order.sell = isSell;
        order.owner = msg.sender;
        order.price = price;
        order.amount = amount;
        order.timestamp = uint64(now);

        uint32 newId = ++lastOrderId;
        emit NewOrder(token, msg.sender, newId, isSell, price, order.timestamp);

        Pair storage pair = pairs[token];
        matchOrder(token, pair, order, newId);

        if (order.amount != 0)
        {
            uint32 parentId;
            
            if (isSell)
                parentId = find(pair.pricesTreeAsk, price, isSell);//Find Parent
            else
                parentId = find(pair.pricesTreeBid, price, isSell);//Find Parent

            ListItem storage newItem;
            if (parentId != 0)
            {
                ListItem storage parent = pair.orderbook[parentId];

                if ((isSell == true && price >= orders[parentId].price) || (isSell == false && price <= orders[parentId].price))
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
                if (order.sell == true)
                {
                    pair.bestAsk = newId;
                    NewAsk(token, order.price);
                }
                else
                {
                    pair.bestBid = newId;
                    NewBid(token, order.price);
                }
            }
            orders[newId] = order;
            pair.orderbook[newId] = newItem;
            AddOpenOrder(newId);

            if (isSell)
                placeAfterAsk(pair.pricesTreeAsk, parentId, newId, price);
            else
                placeAfterBid(pair.pricesTreeBid, parentId, newId, price);
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
            
        while (currentOrderId != 0 && order.amount > 0 && ((order.sell && order.price <= orders[currentOrderId].price) || (!order.sell && order.price >= orders[currentOrderId].price)))
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
            ListItem memory item = excludeItem(pair, currentOrderId, matchingOrder.sell);
            RemoveOpenOrder(currentOrderId);
            currentOrderId = item.next;
        }

        if (order.sell)
        {
            if (pair.bestBid != currentOrderId)
            {
                pair.bestBid = currentOrderId;
                if (currentOrderId != 0)
                    NewBid(token, orders[currentOrderId].price);//, orders[currentOrderId].amount);
                else
                    NewBid(token, 0);
            }
        }
        else
        {
            if (pair.bestAsk != currentOrderId)
            {
                pair.bestAsk = currentOrderId;
                if (currentOrderId != 0)
                    NewAsk(token, orders[currentOrderId].price);//, orders[currentOrderId].amount);
                else
                    NewAsk(token, 0);
            }
        }
    }

    function depositETH() payable public
    {
        Balance storage balance = balances[0][msg.sender];
        balance.available = SafeMath.safeAdd(balance.available, msg.value);
        Deposit(0, msg.sender, msg.value);
    }

    function withdrawETH(uint amount) public
    {
        Balance storage balance = balances[0][msg.sender];
        balance.available = SafeMath.safeSub(balance.available, amount);
        require(msg.sender.call.value(amount)());
        Withdraw(0, msg.sender, amount);
    }

    function depositERC20(address token, uint amount) public
    {
        require(Token(token).transferFrom(msg.sender, this, amount));
        Balance storage balance = balances[token][msg.sender];
        balance.available = SafeMath.safeAdd(balance.available, amount);
        Deposit(token, msg.sender, amount);
    }
 
    function withdrawERC20(address token, uint amount) public
    {
        Balance storage balance = balances[token][msg.sender];
        balance.available = SafeMath.safeSub(balance.available, amount);
        require(Token(token).transfer(msg.sender, amount));
        Withdraw(token, msg.sender, amount);
    }
    
    function excludeItem(Pair storage pair, uint32 id, bool isSell) private returns (ListItem)
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
        
        if (isSell == true)
            remove(pair.pricesTreeAsk, id);
        else
            remove(pair.pricesTreeBid, id);
    
        delete pair.orderbook[id];
        delete orders[id];

        return removeItem;
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

        removeItem = excludeItem(pair, id, order.sell);
        
        RemoveOpenOrder(id);
        
        if (pair.bestBid == id)
        {
            pair.bestBid = removeItem.next;

            if (pair.bestBid != 0)
                emit NewBid(token, orders[pair.bestBid].price);
            else
                emit NewBid(token, 0);
        }
        else if (pair.bestAsk == id)
        {
            pair.bestAsk = removeItem.next;

            if (pair.bestAsk != 0)
                emit NewAsk(token, orders[pair.bestAsk].price);
            else
                emit NewAsk(token, 0);
        }
    }

    function getBalance(address token, address trader) public constant returns (uint available, uint reserved)
    {
        available = balances[token][trader].available;
        reserved = balances[token][trader].reserved;
    }
    
    function getBalanceETH(address trader) public constant returns (uint available, uint reserved)
    {
        available = balances[0][trader].available;
        reserved = balances[0][trader].reserved;
    }

    function getOrderBookInfo(address token) public constant returns (uint32 bestBid, uint32 bestAsk)
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
    
    function GetMyOrders() public constant returns (address[] memory _tokens, uint[] memory _amounts, uint[] memory _prices, bool[] memory _sells, uint64[] memory _timestamps)
    {
        OpenOrder storage openOrder = holder_OpenOrder[msg.sender];

        uint32 id = openOrder.startId;
        
        uint32 N = openOrder.orderN;
        
        _tokens = new address[](N);
        _amounts = new uint[](N);
        _prices = new uint[](N);
        _sells = new bool[](N);
        _timestamps = new uint64[](N);
        
        if (id != 0)
        {
            Order memory order;
            uint32 i = 0;
            while (id != 0)
            {
                order = orders[id];
                _tokens[i] = order.token;
                _amounts[i] = order.amount;
                _prices[i] = order.price;
                _sells[i] = order.sell;
                _timestamps[i] = order.timestamp;

                id = openOrder.id_orderList[id].next;
                i++;
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
    
    function GetHoga(Token token, uint hogaN) public constant returns (uint[] priceB, uint[] volumeB, uint[] priceA, uint[] volumeA)
    {
        priceB = new uint[](hogaN);
        volumeB = new uint[](hogaN);
        priceA = new uint[](hogaN);
        volumeA = new uint[](hogaN);

        Pair storage pair = pairs[token];

        Order memory order;
        uint32 i;
        uint32 n = 0;
        uint32 currentOrderId = pair.bestBid;
        uint volume = 0;
        uint price = 0;

        currentOrderId = pair.bestBid;
        n = 0;

        while (n < 10 && currentOrderId > 0)
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
            for (i = n + 1; i < 10; i++)
            {
                priceB[i] = GetDownTickPrice(priceB[i - 1]);
            }
        }

        currentOrderId = pair.bestAsk;
        n = 0;
        while (n < 10 && currentOrderId > 0)
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

            for (i = n + 1; i < 10; i++)
            {
                priceA[i] = GetUpTickPrice(priceA[i - 1]);
            }
        }
    }
}